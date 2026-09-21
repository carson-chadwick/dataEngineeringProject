-- Purpose: This data quality test ensures that inventory quantities are never negative.
-- Role: It fits into the project by validating the integrity of the legacy AdventureWorks inventory data.

-- The test fails if any rows are returned (i.e., if any product has a negative quantity)
select
    quantity
from
    {{ ref('stg_adventure_db__inventory') }}
where
    quantity < 0
