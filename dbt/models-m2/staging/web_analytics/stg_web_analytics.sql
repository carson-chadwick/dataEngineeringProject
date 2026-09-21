-- Purpose: This staging model cleans and normalizes raw web clickstream events.
-- Role: It fits into the project by transforming raw ingestion data into a standardized format for behavioral analysis in m2.

with source as (
    -- Retrieve raw web analytics data from the source
    select * from {{ source('web_analytics_source', 'web_analytics_raw') }}

),

renamed as (
    -- Standardize field names and normalize timestamps to UTC for consistency
    select
        customer_id::int as customer_id,
        product_id::int as product_id,
        session_id::varchar as session_id,
        page_url::varchar as page_url,
        event_type::varchar as event_type,
        
        -- Explicit timezone normalization to UTC
        convert_timezone('UTC', event_timestamp::timestamp_ntz) as event_at,
        convert_timezone('UTC', _loaded_at::timestamp_ntz) as ingested_at,
        
        _file_name as source_file_name

    from source

),

final as (
    -- Add dbt-specific metadata for auditing and lineage tracking
    select
        *,
        -- Record when this specific transformation was run
        sysdate() as dbt_loaded_at
    from renamed

)

-- Output cleaned web analytics data
select * from final