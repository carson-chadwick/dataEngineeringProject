-- Purpose: This integrity test confirms that active products do not have a sell end date.
-- Role: It fits into the project by ensuring the product catalog correctly reflects currently available items.

-- The test fails if any product in the staging model has a non-null sell_end_date
select
    sell_end_date
from
    {{ ref('stg_adventure_db__products') }}
where
    sell_end_date is not null
