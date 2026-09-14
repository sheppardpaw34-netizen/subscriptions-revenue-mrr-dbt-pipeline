with subscriptions as (
    select * from {{ref('stg_stripe_subscriptions')}}
),

subscription_periods as (
    select
        subscription_id,
        customer_id,
        plan_id,
        subscription_status,
        mrr_amount,
        date(started_at_utc) as start_date,
        coalesce(date(canceled_at_utc), current_date()) as end_date
    from subscriptions
)

select * from subscription_periods