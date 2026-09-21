-- Purpose: This base model aggregates real-time sales order details into a nested structure.
-- Role: It fits into the project by transforming the flat real-time source schema into a nested format that matches the legacy e-commerce models.

with orders as (
    -- Retrieve high-level order headers
    select * from {{ source('real_time_source', 'orders_raw') }}
),

details as (
    -- Retrieve granular order line items
    select * from {{ source('real_time_source', 'order_details_raw') }}
),

nested_details as (
    -- Aggregate line items into a JSON array per order to mirror legacy data structures
    select
        sales_order_id,
        array_agg(object_construct(
            'product_id', product_id,
            'quantity', order_qty,
            'unit_price', unit_price
        )) as order_details 
    from details
    group by 1
)

-- Join headers with their nested details for a complete order view
select
    o.sales_order_id,
    o.customer_id,
    o.order_date,
    o.last_modified,
    n.order_details
from orders o
left join nested_details n on o.sales_order_id = n.sales_order_id