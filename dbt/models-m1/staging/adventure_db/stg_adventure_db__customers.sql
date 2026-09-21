-- Purpose: This staging model cleans and renames raw customer data from the legacy AdventureWorks database.
-- Role: It fits into the project by providing a standardized customer base used for enrichment in downstream intermediate models.

with

source as (
    -- Import raw customer data from the source database
    select * from {{ source('adventure_db', 'customer_prod_db') }}

),

renamed as (
    -- Standardize column names and cast data types for consistency
    select
        customerid::string         as customer_id,
        firstname                  as first_name,
        middlename                 as middle_name,
        lastname                   as last_name,
        fullname                   as full_name,
        emailaddress               as email_address,
        addressline1               as address_line_1,
        addressline2               as address_line_2,
        city                       as city,
        stateprovince              as state_province,
        countryregion              as country_region,
        postalcode                 as postal_code,
        accountnumber              as account_number,
        territoryid::string        as territory_id,
        modifieddate               as modified_date
    from source

)

-- Final selection of cleaned customer data
select * from renamed