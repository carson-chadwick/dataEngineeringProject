-- Purpose: This smoke test verifies that the web analytics ingestion pipeline is successfully delivering data.
-- Role: It fits into the project by ensuring a minimum baseline volume of data exists in Snowflake, indicating the Prefect flow is healthy.

{#
    The test fails (returns a row) if the total row count in the 
    stg_web_analytics model is less than 50.
#}

select 1
from (
    -- Count all records in the staged web analytics model
    select count(*) as row_count
    from {{ ref('stg_web_analytics') }}
) counts
-- Fail condition: volume is below the expected minimum threshold
where counts.row_count < 50
