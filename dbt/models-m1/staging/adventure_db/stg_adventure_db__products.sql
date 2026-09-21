-- Purpose: This staging model cleans and filters the legacy product catalog.
-- Role: It fits into the project by providing a clean list of active products, enriched with standardized unit measurements.

with

source as (
    -- Import raw product data, filtering for items currently available for sale
    select * from {{ source('adventure_db', 'product_prod_db') }}
    where sellenddate is null

),
measures as (
    -- Import reference data for unit measures (size, weight)
    select * from {{ ref('measures') }}
),

renamed as (
    -- Map product attributes and join with measurements for clarity
    select
        s.productid::string    as product_id,
        s.productname          as product_name,
        s.productnumber        as product_number,
        s.color                as color,
        s.standardcost         as standard_cost,
        s.listprice            as list_price,
        s.size                 as size,
        sm.measure_name        as size_measure,
        s.weight               as weight,
        wm.measure_name        as weight_measure,
        s.productline          as product_line,
        s.class                as class,
        s.style                as style,
        s.productcategory      as product_category,
        s.productsubcategory   as product_subcategory,
        s.productmodel         as product_model,
        s.sellstartdate        as sell_start_date,
        s.sellenddate          as sell_end_date,
        s.discontinueddate     as discontinued_date,
        s.modifieddate         as modified_date          
    from source s
    left join measures sm
    on s.sizeunitmeasure = sm.measure_code
    left join measures wm
    on s.weightunitmeasure = wm.measure_code

)

-- Final selection of cleaned product catalog
select * from renamed