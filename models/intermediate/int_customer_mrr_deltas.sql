with customer_mrr as (
    select * from {{ ref('int_customer_mrr_by_months')}}
),

lagged_customer_mrr as (
    select 
        date_month,
        customer_id,
        mrr_local,
        lag(mrr_local,1,0.0) over (
            partition by customer_id
            order by date_month asc
        ) as prev_mrr_local,
        lag(date_month) over (
            partition by customer_id
            order by date_month asc
        ) as prev_date_month
    from customer_mrr
)

select 
    date_month,
    customer_id,
    mrr_local,
    prev_mrr_local,
    mrr_local - prev_mrr_local as mrr_change,
    case
        when prev_date_month is null 
        then true 
        else false 
    end as is_first_month
from lagged_customer_mrr
