-- Purpose: This staging model consolidates and deduplicates email campaign events from multiple sources.
-- Role: It fits into the project by providing a clean, unified marketing event stream for conversion analysis.
-- Base models represent 'formatting for integration' — getting source data into the shape that staging models expect
-- This is the 'reverse lateral flatten' mentioned in the instructions: you're aggregating order_details rows back into an array per order

with

duped as (
    -- Combine legacy campaign events
    select 
        event_id,
        campaign_id,
        event_date::timestamp_ntz as event_date, 
        event_type,
        customer_id,
        order_id
    from {{ ref('base_ecom__email_campaigns') }}

    union all

    -- Combine new marketing campaign events
    select 
        event_id,
        campaign_id,
        event_date::timestamp_ntz as event_date, 
        event_type,
        customer_id,
        order_id
    from {{ ref('base_ecom__email_mktg_new') }}

),

deduped as (
    -- Remove duplicate events based on event_id, keeping the earliest occurrence
    select 
        * 
    from duped
    QUALIFY ROW_NUMBER() OVER (PARTITION BY event_id ORDER BY event_date) = 1

),

ranked_rows AS (
    -- Rank events to identify the latest conversion event per order
    SELECT *,
            ROW_NUMBER() OVER (PARTITION BY order_id, event_type ORDER BY event_date DESC) AS rn
    FROM deduped

),

ranked_deduped as (
    -- Filter to keep only the most recent event of each type per order
    SELECT *
    FROM ranked_rows
    WHERE rn = 1 
),

final as (
    -- Final transformation: parse campaign metadata and flag conversions
    select
        event_id,
        campaign_id,
        -- Extract campaign components from the delimited ID string
        split_part(campaign_id, '~', 1) as customer_segment,
        split_part(campaign_id, '~', 2) as product_category,
        split_part(campaign_id, '~', 3) as ad_strategy,
        event_date,
        event_type,
        customer_id,
        order_id::VARCHAR as order_id,
        case 
            when order_id is null then 0 else 1
        end as is_converted
    from ranked_deduped
)

-- Output the unified campaign event data
select * from final
