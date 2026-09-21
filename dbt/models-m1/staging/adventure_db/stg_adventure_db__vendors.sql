-- Purpose: This staging model prepares raw vendor data for downstream analysis.
-- Role: It fits into the project by providing supplier metadata, including credit ratings and preferred status for procurement models.

with

source as (
    -- Import raw vendor data from the source database
    select * from {{ source('adventure_db', 'vendor_prod_db') }}

),

renamed as (
    -- Standardize column names for vendor attributes
    select
        vendorid::string                 as vendor_id,
        accountnumber                    as account_number,
        name                             as name,
        creditrating                     as credit_rating,
        preferredvendorstatus            as preferred_vendor_status,
        activeflag                       as active_flag,
        purchasingwebserviceurl          as purchasing_webservice_url,
        modifieddate                     as modified_date
    from source

)

-- Final selection of cleaned vendor data
select * from renamed