-- Purpose: This staging model parses raw, semi-structured purchase order data.
-- Role: It fits into the project by transforming JSON-based procurement data into a relational format and enriching it with shipping methods.
-- Base models represent 'formatting for integration' — getting source data into the shape that staging models expect
-- This is the 'reverse lateral flatten' mentioned in the instructions: you're aggregating order_details rows back into an array per order

with

source as (
    -- Retrieve raw purchase order data from the source
    select * from {{ source('ecom_source', 'purchase_order_raw') }}

),

ship_methods as (
    -- Reference data for shipping methods
    select * from {{ ref('ship_method') }}
),

renamed as (
    -- Extract fields from the raw JSON variant and join with ship methods
    select
        s.raw:EmployeeID::integer                          as employee_id,
        s.raw:Freight::float                               as freight,
        s.raw:OrderDate::timestamp                         as order_date,
        s.raw:OrderDetails::variant                        as order_details,
        s.raw:OrderDetails.DueDate::date                   as due_date,
        s.raw:OrderDetails.LineTotal::float                as line_total,
        s.raw:OrderDetails.OrderQty::number                as order_qty,
        s.raw:OrderDetails.ProductID::string               as product_id,
        s.raw:OrderDetails.PurchaseOrderDetailID::string   as purchase_order_detail_id,
        s.raw:OrderDetails.ReceivedQty::number             as received_qty,
        s.raw:OrderDetails.RejectedQty::number             as rejected_qty,
        s.raw:OrderDetails.StockedQty::number              as stocked_qty,
        s.raw:OrderDetails.UnitPrice::float                as unit_price,
        s.raw:PurchaseOrderID::string                      as purchase_order_id,
        s.raw:RevisionNumber::number                       as revision_number,
        s.raw:ShipDate::timestamp                          as ship_date,
        h.name                                             as shipping_method,
        s.raw:Status::number                               as status,
        s.raw:SubTotal::float                              as subtotal,
        s.raw:TaxAmt::float                                as tax_amt,
        s.raw:TotalDue::float                              as total_due,
        s.raw:VendorID::string                             as vendor_id
    from source s
    left join ship_methods h
    on s.raw:ShipMethodID::number = h.ship_method_id

)

-- Output cleaned purchase order data
select * from renamed
