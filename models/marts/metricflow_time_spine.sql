{{ config(materialized='table') }}

with days as (
    select date_day
    from unnest(
        generate_date_array(
            cast('2020-01-01' as date),
            cast('2030-12-31' as date),
            interval 1 day
        )
    ) as date_day
)

select cast(date_day as date) as date_day
from days