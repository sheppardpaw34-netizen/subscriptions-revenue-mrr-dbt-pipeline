with date_series as (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2020-01-01' as date)",
        end_date="cast('2026-12-31' as date)"
    ) }}
)

select
    cast(date_day as date) as date_day,
    cast({{ dbt.date_trunc('month', 'date_day') }} as date) as date_month,
    cast({{ dbt.date_trunc('year', 'date_day') }} as date) as date_year
from date_series
