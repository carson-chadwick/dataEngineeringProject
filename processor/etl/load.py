# etl/load.py
import os
import time
import tempfile

def upload_dataframe_to_stage(df, label, stage_name, run_time, file_format="csv"):
    """
    Step 1: The 'PUT' Operation.
    Converts a Pandas DataFrame into a physical file and uploads it to 
    a Snowflake internal stage.
    """
    from utils.connections import get_snowflake_connection

    # Generate a unique filename using the label (e.g., 'orders') and timestamp
    filename = f"{label}_{run_time.strftime('%Y%m%d_%H%M%S')}.{file_format}"
    
    # tempfile ensures we don't leave junk files on our local disk/container
    with tempfile.TemporaryDirectory() as tmpdir:
        file_path = os.path.join(tmpdir, filename)

        # Write the dataframe to the temporary local path
        if file_format == "csv":
            df.to_csv(file_path, index=False, na_rep='')
        elif file_format == "json":
            # lines=True creates 'JSON Lines' format, which Snowflake prefers for ingestion
            df.to_json(file_path, orient="records", lines=True)
        else:
            raise ValueError("Unsupported file format for Snowflake upload.")

        print(f"Uploading {filename} to Snowflake stage {stage_name}")

        SNOWFLAKE_SCHEMA=os.getenv("SNOWFLAKE_SCHEMA")

        conn = get_snowflake_connection()
        cs = conn.cursor()
        try:
            # Ensure the landing zone exists before uploading
            cs.execute(f"CREATE SCHEMA IF NOT EXISTS {SNOWFLAKE_SCHEMA};")
            cs.execute(f"CREATE STAGE IF NOT EXISTS {stage_name};")
            
            # PUT moves the file from local storage to the Snowflake cloud stage
            cs.execute(f"PUT file://{file_path} @{stage_name}/ OVERWRITE = TRUE")
        finally:
            cs.close()
            conn.close()


def copy_stage_to_table(stage_name, table_name, file_format="CSV", connection=None):
    """
    Step 2: The 'COPY INTO' Operation.
    Moves data from the Snowflake stage into the final destination table.
    """
    start_time = time.time()
    metrics = {
        "rows_copied": 0, 
        "rows_skipped": 0, 
        "execution_time_sec": 0, 
        "status": "success", 
        "error_message": None
    }

    try:
        cs = connection.cursor()
        
        # SQL for structured CSV data
        if file_format.upper() == "CSV":
            sql = f"""
                COPY INTO {table_name}
                FROM @{stage_name}/
                FILE_FORMAT = (TYPE = 'CSV' SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"')
                ON_ERROR = 'CONTINUE' -- Skip bad rows but keep loading the rest
            """
        # SQL for semi-structured JSON data (loads into a VARIANT column)
        else:
            sql = f"""
                COPY INTO {table_name}
                FROM (SELECT $1 FROM @{stage_name}/)
                FILE_FORMAT = (TYPE = 'JSON')
                ON_ERROR = 'CONTINUE'
            """
            
        cs.execute(sql)
        results = cs.fetchall()

        # Parse Snowflake's response to track performance and data quality
        for row in results:
            # Snowflake result index 3: rows_loaded | index 4: input_lines
            loaded = int(row[3]) if len(row) > 3 else 0
            skipped = int(row[4]) if len(row) > 4 else 0
            metrics["rows_copied"] += loaded
            metrics["rows_skipped"] += (skipped - loaded) if skipped > loaded else 0

    except Exception as e:
        metrics["status"] = "error"
        metrics["error_message"] = str(e)
    finally:
        metrics["execution_time_sec"] = round(time.time() - start_time, 2)
        if cs:
            cs.close()

    return metrics


def clean_stage(stage_name, connection=None):
    """
    Step 3: Housekeeping.
    Removes files from the stage after they are safely inside the table.
    Prevents re-loading the same data in future runs.
    """
    start_time = time.time()
    metrics = {
        "files_removed": 0,
        "execution_time_sec": 0,
        "status": "success",
        "error_message": None
    }

    try:
        cs = connection.cursor()
        # REMOVE deletes the staged files in the cloud
        cs.execute(f"REMOVE @{stage_name}/;")
        results = cs.fetchall()
        
        # Count how many files were successfully deleted
        metrics["files_removed"] = len(results)

    except Exception as e:
        metrics["status"] = "error"
        metrics["error_message"] = str(e)
    finally:
        metrics["execution_time_sec"] = round(time.time() - start_time, 2)
        if cs:
            cs.close()

    return metrics