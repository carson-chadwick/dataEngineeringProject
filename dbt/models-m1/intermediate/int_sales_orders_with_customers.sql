-- Purpose: This intermediate model enriches sales orders with customer demographic information.
-- Role: It fits into the project by bridging the e-commerce sales data with the legacy AdventureWorks customer data for unified reporting.

with sales_orders as (
    -- Unified sales order model
    select * from {{ ref('stg_ecom__sales_orders') }}
),

customers as (
    -- Legacy customer data from AdventureWorks
    select * from {{ ref('stg_adventure_db__customers') }}
),

final as (
    -- Join sales with customers to add names and regional details
    select
        s.sales_order_id,
        s.order_date,
        -- Truncate date for daily trend visualization
        date_trunc('day', s.order_date) as order_day,
        s.total_due,
        s.comment,
        c.customer_id,
        c.full_name,
        -- Normalized regional field
        c.country_region as country
    from sales_orders s
    inner join customers c 
        -- Cast IDs to VARCHAR to ensure compatibility during join
        on s.customer_id::VARCHAR = c.customer_id::VARCHAR
)

-- Output enriched sales order data
select * from final