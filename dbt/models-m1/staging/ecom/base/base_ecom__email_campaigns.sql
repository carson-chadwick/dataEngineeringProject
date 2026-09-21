-- Purpose: This base model extracts raw legacy email campaign data from JSON.
-- Role: It fits into the project by providing the initial layer of structure for historical marketing events.

with

intentional_test_failure as (
    -- Mock data used for testing business rules (e.g., single conversion check)
    select 
        parse_json('{
            "event_id": "this-is-a-fake-event-id",
            "event_type": "conversion", 
            "order_id": 44330
        }') as RAW

),

source as (
    -- Retrieve raw JSON campaign events
    select * from {{ source('ecom_source', 'email_campaign_raw') }}

),

renamed as (
    -- Extract and cast fields from the raw JSON variant
    select
        raw:campaign_id::string     as campaign_id,
        raw:event_id::string        as event_id,
        TO_TIMESTAMP(
            raw:event_date::string, 
            'DD-Mon-YYYY HH12.MI AM'
            )                       as event_date,
        raw:event_type::string      as event_type,
        raw:customer_id::string     as customer_id,
        raw:order_id::string        as order_id,
        raw:product_id::string      as product_id
    from source

)

-- Output structured base campaign events
select * from renamed
