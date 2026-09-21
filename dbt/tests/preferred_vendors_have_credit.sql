-- Purpose: This business rule test verifies that all preferred vendors maintain a minimum credit rating.
-- Role: It fits into the project by ensuring that procurement logic only considers financially stable preferred suppliers.

-- The test fails if any preferred vendor has a credit rating below 1
select
    *
from
    {{ ref('stg_adventure_db__vendors') }}
where
    preferred_vendor_status = true
and
    credit_rating < 1
