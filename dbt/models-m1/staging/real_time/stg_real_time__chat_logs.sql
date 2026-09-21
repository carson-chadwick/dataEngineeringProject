-- Purpose: This staging model cleans and structures real-time customer support chat logs.
-- Role: It fits into the project by providing visibility into customer satisfaction and support performance from the real-time data stream.

with raw_chats as (
    -- Retrieve raw chat logs from the real-time source
    select * from {{ source('real_time_source', 'chat_logs_raw') }}
)

-- Extract and cast fields from the raw JSON variant into a structured format
select
    raw:_id::string as chat_id,
    raw:customer_id::int as customer_id,
    raw:sales_order_id::varchar as sales_order_id,
    raw:product_id::int as product_id,
    raw:chat_start_time::timestamp_tz as chat_start_at,
    raw:chat_completion_time::timestamp_tz as chat_completed_at,
    raw:order_date::timestamp_tz as order_at,
    -- Convert unix timestamp to standard timestamp format
    to_timestamp_tz(raw:last_modified::int, 3) as last_modified_at,
    raw:ticket_channel::string as ticket_channel,
    raw:ticket_type::string as ticket_type,
    raw:ticket_priority::string as ticket_priority,
    raw:ticket_status::string as ticket_status,
    raw:ticket_subject::string as ticket_subject,
    raw:ticket_description::string as ticket_description,
    raw:resolution::string as resolution,
    raw:customer_satisfaction_rating::int as csat_score
from raw_chats