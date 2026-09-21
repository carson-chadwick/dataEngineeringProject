-- Purpose: This intermediate model flattens the JSON-formatted order details into individual line items.
-- Role: It fits into the project by transforming semi-structured e-commerce data into a relational format for granular product-level analysis.

with

sales_orders as (
    -- Retrieve staged sales orders containing nested order details
    select 
        sales_order_id,
        order_date,
        customer_id,
        order_details
    from {{ ref('stg_ecom__sales_orders') }}

),

line_items_flattened as (
    -- Flatten the order_details JSON array into individual rows per line item
    select
        so.sales_order_id                           as sales_order_id,
        so.customer_id                              as customer_id,
        so.order_date                               as order_date,
        item.value:SalesOrderDetailID::string       as sales_order_detail_id,
        item.value:CarrierTrackingNumber::string    as carrier_tracking_number,
        item.value:OrderQty::int                    as order_qty,
        item.value:ProductID::string                as product_id,
        item.value:SpecialOfferID::int              as special_offer_id,
        item.value:UnitPrice::decimal(19,4)         as unit_price,
        item.value:UnitPriceDiscount::decimal(19,4) as unit_price_discount,
        item.value:LineTotal::decimal(19,4)         as line_total,
        item.value:ModifiedDate::timestamp          as line_item_modified_date

    from sales_orders so,
         lateral flatten(input => so.order_details) item

)

-- Output the flattened line item data
select * from line_items_flattened