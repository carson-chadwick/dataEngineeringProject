-- Purpose: This staging model prepares raw inventory data from the legacy AdventureWorks database.
-- Role: It fits into the project by providing current stock levels and storage locations for product availability analysis.

with

source as (
    -- Import raw inventory data from the source database
    select * from {{ source('adventure_db', 'inventory_prod_db') }}

),

renamed as (
    -- Map raw inventory fields to standardized naming conventions
    select
        productid::string   as product_id,
        locationid          as location_id,
        shelf               as shelf,
        bin                 as bin,
        quantity            as quantity
    from source

)

-- Final selection of cleaned inventory data
select * from renamed