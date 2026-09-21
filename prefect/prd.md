# Product Requirements Document: Web Analytics Prefect Flow
"I am working on Milestone 2 of a Data Engineering project. I have provided a PRD below. Please implement the web_analytics_flow.py file using Prefect 2.0. Follow the 'Loading Strategy' strictly, as Snowflake internal stages are required. Use httpx or requests for the API calls with a retry strategy for 429 and 5xx errors.".

## 1. Problem Statement

_What problem are we solving? Why does this matter for the Adventure Works data platform?_
Adventure Works has no visibility into customer browsing behavior on its website. Web analytics data (page views, clicks, add-to-cart events, purchases) exists in a REST API but is not integrated into the data warehouse. Connecting this data to existing customer and product dimensions will allow analysts to link browsing patterns to purchasing behavior.

---

## 2. Desired Outcome

_What does "done" look like? Be specific._

A Prefect 2.0 flow that runs on a configurable schedule, pulls clickstream events from the web analytics REST API, cleans and validates the data, stages it in Snowflake, loads it into RAW_EXT.web_analytics_raw, logs summary statistics on each run, and cleans up staged files after a successful load. The flow must connect to Snowflake using environment variables found in .env.docker or .env.dev and be deployable via the Docker Compose services already defined in compose.yml.

The flow should be implemented as a Prefect 2.0 flow with discrete @task functions in the following order:

Fetch events from the API (with retry logic)
Clean and validate — cast types, drop nulls on required fields, deduplicate, rename timestamp → event_timestamp
Write cleaned data to a temp CSV with header row
PUT CSV to Snowflake internal stage @WEB_ANALYTICS_STAGE
COPY INTO RAW_EXT.web_analytics_raw from stage with SKIP_HEADER=1
REMOVE staged files after successful COPY
Log records fetched, records after cleaning, and records loaded
The implementation file is prefect/flows/web_analytics_flow.py, which is currently nearly empty. Do not modify existing Milestone 1 flows, dbt models, or non-Prefect services in compose.yml.

Provided are the configurations found in the compose.yml:
  prefect-server:
    image: prefecthq/prefect:2-latest
    container_name: prefect-server
    ports:
      - "4200:4200"
    environment:
      - PREFECT_SERVER_API_HOST=0.0.0.0
      - PREFECT_API_URL=http://prefect-server:4200/api
    command: ["prefect", "server", "start"]
    healthcheck:
      test: ["CMD", "python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:4200/api/health')"]
      interval: 15s
      timeout: 10s
      retries: 5
      start_period: 30s
    restart: on-failure

  prefect-worker:
    image: prefecthq/prefect:2-latest
    container_name: prefect-worker
    environment:
      - PREFECT_API_URL=http://prefect-server:4200/api
    command: ["prefect", "worker", "start", "-n", "is566-worker", "--pool", "is566-pool", "--type", "process"]
    depends_on:
      prefect-server:
        condition: service_healthy
    restart: on-failure

  web-analytics-flow:
    build: ./prefect
    container_name: web-analytics-flow
    env_file:
      - .env
    environment:
      - PREFECT_API_URL=http://prefect-server:4200/api
      - PYTHONUNBUFFERED=1
    depends_on:
      prefect-server:
        condition: service_healthy
    restart: on-failure

---

## 3. Acceptance Criteria

_How will we know this works? List specific, testable criteria._

- Flow successfully connects to the API and retrieves data
Data is type-cast correctly: event_timestamp as TIMESTAMP_NTZ, customer_id and product_id as INT, all other fields as VARCHAR
- Null values in required fields ( customer_id , product_id , session_id , event_timestamp) cause the row to be dropped — not the flow to fail
- Exact duplicate records are deduplicated before loading
Empty API response (zero events) is handled gracefully — flow exits cleanly without attempting a load
- Data lands in RAW_EXT.web_analytics_raw with correct column names and types
- Flow handles API errors (timeouts, 429 rate limits, 5xx server errors) with retries and exponential backoff
- Staged CSV files are removed from @WEB_ANALYTICS_STAGE after successful COPY
- Flow logs summary statistics: records fetched, records after cleaning, records loaded
- Flow runs end-to-end without manual intervention on the configured schedule


---

## 4. Technical Constraints

_What must the solution adhere to? These are non-negotiable._

- **Orchestration framework:** Prefect 2.0+
- **Target warehouse:** Snowflake (credentials via environment variables)
- **Loading pattern:** Upload to internal stage, then COPY INTO raw table
- **Containerization:** Must run in Docker, integrated with existing Docker Compose
- **Error handling:** Must include logging and graceful failure (no silent drops)
- **Scheduling:** Configurable interval via environment variable
- **Snowflake syntax** Use Snowflake-native patterns (e.g. PUT, COPY INTO, REMOVE) — do not use PostgreSQL patterns


---

## 5. Data Schema

_What does the data look like? Document the expected fields._

### API Response Schema (Expected)
API_BASE_URL=https://is566-web-analytics-api.fly.dev
_Discover the API schema by exploring the documentation endpoints at your API base URL:_
- _`/docs` — Interactive Swagger UI_
Data Characteristics
customer_id: Integer (range 11,000–30,118). Joins with stg_adventure_db__customers.
product_id: Integer (range 707–999). Joins with stg_adventure_db__products.
event_type: One of page_view, click, add_to_cart, purchase.
timestamp: ISO 8601 UTC. Covers the window from since to now (defaults to last 60 minutes).
session_id: Unique per browsing session. One customer may have multiple sessions.
- _`/agent-docs` — Agent-friendly markdown description_
# Adventure Works Web Analytics API — Agent Reference

## Endpoint

```
GET {API_BASE_URL}/analytics/clickstream
GET {API_BASE_URL}/analytics/clickstream?since=2026-03-22T14:00:00Z
```

Returns a JSON **array** of clickstream event objects.

## Query Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| since | string (ISO 8601) | 60 minutes ago | Only return events after this timestamp. Use for incremental extraction. |

The number of events scales with the time window: ~50 events per 60 minutes.
A 5-minute window returns ~4 events; a 30-minute window returns ~25.

## Response Schema

Each object in the array has these fields:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| customer_id | int | Yes | Adventure Works customer ID (range 11000–30118). Joins with Snowflake table stg_adventure_db__customers via customer_id. |
| product_id | int | Yes | Adventure Works product ID (range 707–999). Joins with stg_adventure_db__products via product_id. |
| session_id | string | Yes | Unique browsing session ID (format: "sess_" + 12 hex chars). |
| page_url | string | Yes | URL of the page viewed. |
| event_type | string | Yes | One of: "page_view", "click", "add_to_cart", "purchase". |
| timestamp | string | Yes | ISO 8601 UTC datetime (e.g., "2026-03-22T14:30:45.123456Z"). Falls within the requested window. |

## Example Response

```json
[
  {
    "customer_id": 29825,
    "product_id": 776,
    "session_id": "sess_a1b2c3d4e5f6",
    "page_url": "https://adventure-works.com/product/776",
    "event_type": "page_view",
    "timestamp": "2026-03-22T14:30:45.123456Z"
  }
]
```

## Example Python Code (Incremental)

```python
import requests
import os
from datetime import datetime, timezone

api_url = os.getenv("API_BASE_URL", "http://localhost:8000")

# First call: no since parameter, gets last 60 minutes
response = requests.get(f"{api_url}/analytics/clickstream", timeout=30)
response.raise_for_status()
events = response.json()

# Track the latest timestamp for next call
last_timestamp = max(e["timestamp"] for e in events) if events else None

# Subsequent calls: pass since to get only new events
response = requests.get(
    f"{api_url}/analytics/clickstream",
    params={"since": last_timestamp},
    timeout=30,
)
new_events = response.json()
print(f"Received {len(new_events)} new events")
```

## Error Handling

- **HTTP 200**: Success. Body is a JSON array.
- **HTTP 422**: Invalid query parameter (count out of range).
- **HTTP 429**: Rate limited (unlikely but handle with Retry-After header).
- **HTTP 5xx**: Server error. Retry with exponential backoff.

Always check `response.raise_for_status()` and wrap in try/except.

## Snowflake Target Table

The data should be loaded into this Snowflake raw table:

```sql
CREATE TABLE IF NOT EXISTS RAW_EXT.web_analytics_raw (
    customer_id     INT          NOT NULL,
    product_id      INT          NOT NULL,
    session_id      VARCHAR(255) NOT NULL,
    page_url        VARCHAR(1000),
    event_type      VARCHAR(50),
    event_timestamp TIMESTAMP_NTZ NOT NULL,
    _loaded_at      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    _file_name      VARCHAR(255)
);
```

**Column mapping from API → Snowflake:**
- `customer_id` → `customer_id` (INT)
- `product_id` → `product_id` (INT)
- `session_id` → `session_id` (VARCHAR)
- `page_url` → `page_url` (VARCHAR)
- `event_type` → `event_type` (VARCHAR)
- `timestamp` → `event_timestamp` (TIMESTAMP_NTZ, rename required)
- (auto) → `_loaded_at` (DEFAULT)
- (auto) → `_file_name` (set during COPY INTO)

## Loading Strategy

1. Write cleaned DataFrame to CSV with header row
2. PUT the CSV file to Snowflake internal stage `@WEB_ANALYTICS_STAGE`
3. COPY INTO `RAW_EXT.web_analytics_raw` FROM `@WEB_ANALYTICS_STAGE` with `FILE_FORMAT = (TYPE='CSV', SKIP_HEADER=1)`
4. REMOVE staged files after successful COPY

## Data Quality Notes

- Some events may have `customer_id` values that don't exist in the customer dimension (foreign key test may catch these).
- `event_type` should always be one of the four valid values; the API guarantees this.
- Timestamps are always recent (within last 60 minutes). Source freshness checks should use `event_timestamp` with a 2-4 hour threshold.


- _`/example` — A single example event to inspect_
{"customer_id":12705,"product_id":925,"session_id":"sess_d260559def51","page_url":"https://adventure-works.com/category/components","event_type":"click","timestamp":"2026-04-09T15:23:48.195606Z"}

### Target Table Schema (Snowflake)

Event Schema
Field	Type	Description
customer_id	int	Adventure Works customer ID (11,000 – 30,118)
product_id	int	Adventure Works product ID (707 – 999)
session_id	string	Unique browsing session (sess_ + 12 hex chars)
page_url	string	URL of the page the customer interacted with
event_type	string	One of: page_view, click, add_to_cart, purchase
timestamp	string	ISO 8601 UTC datetime

---

## 6. Testing Requirements

_How should the agent test its work?_

- [ ] Unit test: Flow functions handle empty API response
- [ ] Unit test: Data cleaning handles null customer_id gracefully
- [ ] Unit test: Deduplication removes exact duplicates
- [ ] Integration test: Flow connects to API and retrieves at least one batch
- [ ] Integration test: Data lands in Snowflake raw table with correct types
- [ ] Syntax check: Make sure the flow imports cleanly: cd prefect
uv run python -c "from flows.web_analytics_flow import web_analytics_flow; print('Import OK')"
- [ ] Run the flow directly to test against the live API: uv run python -m flows.web_analytics_flow
- [ ] Docker run check: docker compose up --build -d prefect-server prefect-worker web-analytics-flow
docker compose logs -f web-analytics-flow
- [ ] Verify in Snowflake: SELECT COUNT(*), MIN(event_timestamp), MAX(event_timestamp) FROM RAW_EXT.web_analytics_raw;
---

## 7. Out of Scope

_What should the agent NOT build? Set boundaries._

- "Do not build the dbt models for this data. That will be done separately."
- "Do not modify existing dbt models or sources."
- "Do not build a dashboard for this data."

---

## 8. Questions and Assumptions

- The internal stage @WEB_ANALYTICS_STAGE and raw table already exist in Snowflake before the flow runs, created manually from prefect/snowflake_objects.sql
- The API guarantees event_type is always one of the four valid values — no filtering needed in the flow
- Some customer_id values may not exist in the customer dimension; this is expected and will be caught by dbt relationship tests downstream, not by this flow
- The cleaned data should be stored as parsed fields in the target table, not as raw JSON
