-- Purpose: This intermediate model attributes sales orders to specific marketing campaigns.
-- Role: It fits into the project by joining sales data with campaign conversion events, enabling ROI analysis for marketing efforts.

with

sales_orders as (
    -- Retrieve all staged sales orders
    select * from {{ ref('stg_ecom__sales_orders') }}
),

campaign_events as (
    -- Filter email campaign events specifically for conversions
    select * from {{ ref('stg_ecom__email_campaigns') }}
    where event_type = 'conversion'
),

campaign_join as (
    -- Left join sales orders with campaign events to identify campaign-driven sales
    select
        so.*,
        ce.campaign_id,
        ce.customer_segment,
        ce.product_category,
        ce.ad_strategy,
        case 
            when ce.campaign_id is not null then 1 else 0
        end as is_campaign_conversion
    from sales_orders so
    left join campaign_events ce
        on so.sales_order_id::VARCHAR = ce.order_id::VARCHAR
)

-- Final dataset of sales orders enriched with campaign metadata
select * from campaign_join