with date_spine as (
    {{ dbt_utils.date_spine(
        datepart='month',
        start_date="cast('2020-01-01' as date)",
        end_date="cast(date_add(current_date(), interval 48 month) as date)"
    )}}
)

select 
    cast(date_month as date) as date_month
from date_spine