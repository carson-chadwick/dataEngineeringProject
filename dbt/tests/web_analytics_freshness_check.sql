-- Purpose: This custom freshness test monitors the latency of the web analytics ingestion pipeline.
-- Role: It fits into the project by alerting stakeholders if storefront clickstream data is stale (older than 24 hours).

{#
    The test fails (returns a row) if the most recent event_at
    is more than 24 hours behind the current system time.
#}

with latest_event as (
    -- Find the most recent event timestamp in the staged web analytics model
    select 
        max(event_at) as most_recent_timestamp
    from {{ ref('stg_web_analytics') }}
)

-- The test query: returns a row only when the data is considered stale
select 
    most_recent_timestamp
from latest_event
-- Comparison: current time vs latest record; fail if gap exceeds 24 hours
where datediff('hour', most_recent_timestamp, current_timestamp()) > 24
