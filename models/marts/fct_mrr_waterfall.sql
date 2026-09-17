with subscription_months as (
    select * from {{ ref('int_subscription_months') }}
),

customer_months as (
    select
        customer_id,
        date_month,
        sum(mrr_amount) as mrr_amount
    from subscription_months
    group by 1, 2
),

mrr_with_lag as (
    select
        customer_id,
        date_month,
        mrr_amount,
        lag(mrr_amount, 1, 0.0) over (
            partition by customer_id
            order by date_month
        ) as previous_mrr_amount
    from customer_months
),

mrr_movements as (
    select
        customer_id,
        date_month,
        coalesce(mrr_amount, 0.0) as mrr_amount,
        coalesce(previous_mrr_amount, 0.0) as previous_mrr_amount,
        (coalesce(mrr_amount, 0.0) - coalesce(previous_mrr_amount, 0.0)) as mrr_change,
        case
            when coalesce(previous_mrr_amount, 0.0) = 0 and coalesce(mrr_amount, 0.0) > 0 then 'new'
            when coalesce(previous_mrr_amount, 0.0) > 0 and coalesce(mrr_amount, 0.0) = 0 then 'churn'
            when coalesce(mrr_amount, 0.0) > coalesce(previous_mrr_amount, 0.0) then 'expansion'
            when coalesce(mrr_amount, 0.0) < coalesce(previous_mrr_amount, 0.0) then 'contraction'
            else 'retained'
        end as movement_type
    from mrr_with_lag
)

select * from mrr_movements