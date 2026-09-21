import os
import tempfile
import pandas as pd
import requests
from datetime import datetime, timezone
from prefect import flow, task, get_run_logger
from snowflake.connector import connect
from typing import Optional, List, Dict
from dotenv import load_dotenv
from processor.utils import watermark
if not os.getenv("SNOWFLAKE_ACCOUNT"):
    # Try the path for local execution
    load_dotenv("../.env.dev")
print(f"DEBUG: SNOWFLAKE_ACCOUNT is {os.getenv('SNOWFLAKE_ACCOUNT')}")

if os.getenv("SNOWFLAKE_ACCOUNT") is None:
    raise ValueError("Failed to load environment variables. Check the path to .env.dev")

# Environment Variables
API_BASE_URL = os.getenv("API_BASE_URL", "https://is566-web-analytics-api.fly.dev")
SNOWFLAKE_USER = os.getenv("SNOWFLAKE_USER")
SNOWFLAKE_PASSWORD = os.getenv("SNOWFLAKE_PASSWORD")
SNOWFLAKE_ACCOUNT = os.getenv("SNOWFLAKE_ACCOUNT")
SNOWFLAKE_WAREHOUSE = os.getenv("SNOWFLAKE_WAREHOUSE")
SNOWFLAKE_DATABASE = os.getenv("SNOWFLAKE_DATABASE")
SNOWFLAKE_SCHEMA = os.getenv("SNOWFLAKE_SCHEMA", "RAW_EXT")
SNOWFLAKE_ROLE = os.getenv("SNOWFLAKE_ROLE", "ACCOUNTADMIN")

def get_snowflake_connection():
    return connect(
        user=SNOWFLAKE_USER,
        password=SNOWFLAKE_PASSWORD,
        account=SNOWFLAKE_ACCOUNT,
        warehouse=SNOWFLAKE_WAREHOUSE,
        database=SNOWFLAKE_DATABASE,
        schema=SNOWFLAKE_SCHEMA,
        role=SNOWFLAKE_ROLE,
    )

@task(retries=3, retry_delay_seconds=10)
def get_watermark() -> Optional[str]:
    logger = get_run_logger()
    query = "SELECT MAX(event_timestamp) FROM RAW_EXT.web_analytics_raw"
    
    try:
        with get_snowflake_connection() as conn:
            with conn.cursor() as cur:
                cur.execute(query)
                result = cur.fetchone()
                
                if result and result[0]:
                    latest_ts = result[0]
                    
                    # If it's a datetime object (standard for Snowflake connector), format to ISO
                    if isinstance(latest_ts, datetime):
                        if latest_ts.tzinfo is None:
                            latest_ts = latest_ts.replace(tzinfo=timezone.utc)
                        formatted_watermark = latest_ts.isoformat().replace("+00:00", "Z")
                    else:
                        formatted_watermark = str(latest_ts)

                    logger.info(f"Watermark retrieved from Snowflake: {formatted_watermark}")
                    return formatted_watermark
                    
    except Exception as e:
        logger.error(f"Failed to retrieve watermark from Snowflake: {e}")
        return None

    logger.info("No existing data found in Snowflake. Starting with default window.")
    return None

@task(retries=3, retry_delay_seconds=[10, 30, 60])
def fetch_api_data(since: Optional[str]) -> List[Dict]:
    logger = get_run_logger()
    url = f"{API_BASE_URL}/analytics/clickstream"
    params = {"since": since} if since else {}
    
    try:
        logger.info(f"Fetching data from {url} with params {params}")
        response = requests.get(url, params=params, timeout=30)
        response.raise_for_status()
        events = response.json()
        logger.info(f"Successfully fetched {len(events)} events from API") # Milestone requirement: Log counts
        return events
    except requests.exceptions.RequestException as e:
        logger.error(f"API Request Failed: {e}")
        raise # Still raise it so Prefect knows the task failed

@task
def transform_data(events: List[Dict]) -> Optional[pd.DataFrame]:
    """Clean and validate the clickstream data."""
    logger = get_run_logger()
    if not events:
        logger.info("No events to transform.")
        return None
    
    df = pd.DataFrame(events)
    initial_count = len(df)
    
    # 1. Rename timestamp to event_timestamp
    df = df.rename(columns={"timestamp": "event_timestamp"})
    
    # 2. Cast types
    try:
        df["customer_id"] = pd.to_numeric(df["customer_id"], errors="coerce")
        df["product_id"] = pd.to_numeric(df["product_id"], errors="coerce")
        df["event_timestamp"] = pd.to_datetime(df["event_timestamp"])
    except Exception as e:
        logger.warning(f"Error during type casting: {e}")
    
    # 3. Drop nulls on required fields
    required_fields = ["customer_id", "product_id", "session_id", "event_timestamp"]
    df = df.dropna(subset=required_fields)
    
    # Ensure IDs are integers after dropping NaNs
    df["customer_id"] = df["customer_id"].astype(int)
    df["product_id"] = df["product_id"].astype(int)
    
    # 4. Deduplicate
    df = df.drop_duplicates()
    
    final_count = len(df)
    logger.info(f"Transformation complete: {initial_count} -> {final_count} records")
    
    if final_count == 0:
        return None
        
    return df

@task
def load_to_snowflake(df: pd.DataFrame):
    """Stage and load data into Snowflake."""
    logger = get_run_logger()
    
    # 1. Create temp file
    # We use delete=False because we need the file to exist for the Snowflake PUT command
    with tempfile.NamedTemporaryFile(mode="w", suffix=".csv", delete=False, newline="") as tmp:
        temp_file_path = tmp.name
        df.to_csv(temp_file_path, index=False, header=True)
    
    # 2. Fix the path for Windows compatibility
    # Snowflake PUT requires forward slashes or escaped backslashes
    snowflake_ready_path = temp_file_path.replace("\\", "/")
    file_name = os.path.basename(temp_file_path)
    
    try:
        with get_snowflake_connection() as conn:
            with conn.cursor() as cur:
                # 3. PUT CSV to Snowflake internal stage
                put_cmd = f"PUT 'file://{snowflake_ready_path}' @RAW_EXT.WEB_ANALYTICS_STAGE AUTO_COMPRESS=TRUE"
                logger.info(f"Executing PUT: {put_cmd}")
                cur.execute(put_cmd)
                
                # 4. COPY INTO raw table
                # Note: Snowflake adds .gz automatically. 
                # We use the filename directly in the FILES clause.
                copy_cmd = f"""
                COPY INTO RAW_EXT.web_analytics_raw
                (customer_id, product_id, session_id, page_url, event_type, event_timestamp, _file_name)
                FROM (
                    SELECT $1, $2, $3, $4, $5, $6, metadata$filename
                    FROM @RAW_EXT.WEB_ANALYTICS_STAGE
                )
                FILE_FORMAT = (TYPE = 'CSV' SKIP_HEADER = 1)
                FILES = ('{file_name}.gz')
                """
                logger.info("Executing COPY INTO command")
                cur.execute(copy_cmd)
                
                copy_results = cur.fetchone() 
                rows_loaded = copy_results[3] if copy_results else 0
                logger.info(f"COPY INTO success: {rows_loaded} rows added to web_analytics_raw") 

                # 5. REMOVE staged file to keep the stage clean
                remove_cmd = f"REMOVE @RAW_EXT.WEB_ANALYTICS_STAGE/{file_name}.gz"
                logger.info("Executing REMOVE command")
                cur.execute(remove_cmd)
                
                logger.info("Successfully loaded data into Snowflake")
                
    except Exception as e:
        logger.error(f"Snowflake Load Error: {e}")
        raise e
    finally:
        # 6. Cleanup local temp file
        if os.path.exists(temp_file_path):
            os.remove(temp_file_path)
            logger.info("Local temp file removed.")

@flow(name="Web Analytics Pipeline")
def web_analytics_flow():
    """Main flow for web analytics data ingestion."""
    logger = get_run_logger()
    
    # 1. Get watermark
    watermark = get_watermark()
    
    # 2. Fetch data
    events = fetch_api_data(since=watermark)
    
    if not events:
        logger.info("No new events found. Exiting flow.")
        return
    
    # 3. Transform
    df = transform_data(events)
    
    if df is None or df.empty:
        logger.info("No valid records after transformation. Exiting flow.")
        return
    
    # 4. Load
    load_to_snowflake(df)
    
    logger.info(f"Flow completed successfully. Processed {len(df)} records.")

if __name__ == "__main__":
    web_analytics_flow()
