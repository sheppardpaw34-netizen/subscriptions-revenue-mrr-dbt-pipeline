with subscription_mrr as (
    select * from {{ ref('int_subscription_mrr_by_months')}}
),

customer_monthly_mrr as (
    select 
        date_month,
        customer_id,
        sum(mrr_local) as mrr_local,
        count(distinct subscription_id) as active_subscription_count,
    from subscription_mrr
    where subscription_status in ('active','past-due','trailing')
    group by 
        date_month,
        customer_id
)

select * from customer_monthly_mrr
