with subscription_months as(
    select * from {{ref('int_subscription_months')}}
),

mrr_with_lag as (
    select
        subscription_id,
        customer_id,
        plan_name,
        date_month,
        mrr_amount,
        lag(mrr_amount, 1, 0.0) over (
            partition by subscription_id
            order by date_month
        ) as previous_mrr_amount
    from subscription_months
),

mrr_movements as (
    select
        subscription_id,
        customer_id,
        plan_name,
        date_month,
        mrr_amount,
        previous_mrr_amount,
        (mrr_amount - previous_mrr_amount) as mrr_change,
        case
            when previous_mrr_amount = 0 and mrr_amount > 0 then 'new'
            when mrr_amount > previous_mrr_amount and previous_mrr_amount > 0 then 'expansion'
            when mrr_amount < previous_mrr_amount and mrr_amount > 0 then 'contraction'
            when mrr_amount = 0 and previous_mrr_amount > 0 then 'churn' 
            else 'retained'
        end as movement_type
    from mrr_with_lag
)

select * from mrr_movements