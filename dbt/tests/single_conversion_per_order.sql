-- Purpose: This marketing attribution test ensures that each order is linked to at most one conversion event.
-- Role: It fits into the project by preventing over-counting of campaign conversions in marketing performance reports.

with conversion_events as (
    -- Filter for conversion-type events in the campaign stream
    select
        event_type,
        order_id
    from {{ ref('stg_ecom__email_campaigns') }}
    where event_type = 'conversion'

),

count_per_order as (
    -- Group events by order_id to detect multiple conversions
    select
        order_id,
        count(*) as event_count
    from conversion_events
    group by order_id

)

-- The test fails if any order has more than one conversion event
select * from count_per_order where event_count > 1
