-- Purpose: This intermediate model enriches web clickstream events with customer demographic and geographic data.
-- Role: It fits into the project by joining m2 web analytics with m1 customer profiles to enable behavioral analysis by segment.

with web_events as (
    -- Retrieve staged web analytics events
    select * from {{ ref('stg_web_analytics') }}

),

customers as (
    -- Retrieve legacy customer profiles from m1
    select * from {{ ref('stg_adventure_db__customers') }}

),

enriched as (
    -- Join web events with customers to add names, emails, and regional details
    select
        -- Web Event Attributes
        e.session_id,
        e.customer_id,
        e.product_id,
        e.page_url,
        e.event_type,
        e.event_at,
        
        -- Customer Attributes (Enrichment)
        c.full_name as customer_full_name,
        c.email_address,
        c.city,
        c.state_province,
        c.country_region,
        c.account_number,
        c.territory_id,

        -- Metadata for auditing
        e.dbt_loaded_at as stg_loaded_at,
        sysdate() as int_loaded_at

    from web_events as e
    -- Keeps all web events and ads customers where there is a match
    left join customers as c
        -- Cast web customer_id to string to match the customer dimension's key
        on e.customer_id::string = c.customer_id

)

-- Output the enriched clickstream dataset
select * from enriched