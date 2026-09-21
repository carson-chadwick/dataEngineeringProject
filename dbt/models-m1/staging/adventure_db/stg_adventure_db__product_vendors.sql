-- Purpose: This staging model manages the relationship between products and their vendors.
-- Role: It fits into the project by enriching supplier data with human-readable measurement units for supply chain reporting.

with

source as (
    -- Import raw product-vendor mapping data
    select * from {{ source('adventure_db', 'product_vendor_prod_db') }}

),
measures as (
    -- Import reference data for unit measures
    select * from {{ ref('measures') }}
),

renamed as (
    -- Join raw data with measures and standardize column names
    select
        s.productid::string         as product_id,
        s.vendorid::string          as vendor_id,
        s.averageleadtime           as average_lead_time,
        s.standardprice             as standard_price,
        s.lastreceiptcost           as last_receipt_cost,
        s.lastreceiptdate           as last_receipt_date,
        s.minorderqty               as min_order_qty,
        s.maxorderqty               as max_order_qty,
        s.onorderqty                as on_order_qty,
        m.measure_name              as measurement,
        s.modifieddate              as modified_date                      
    from source s
    left join measures m
    on s.unitmeasurecode = m.measure_code

)

-- Final selection of enriched product-vendor data
select * from renamed