with subscriptions as (
    select * from {{ ref('stg_stripe_subscriptions') }}
),

customers as (
    select * from {{ ref('stg_stripe_customers') }}
)

select
    s.subscription_id,
    s.customer_id,
    s.plan_id,
    s.subscription_status,
    s.mrr_amount,
    date(s.started_at_utc) as start_date,
    coalesce(date(s.canceled_at_utc), current_date()) as end_date,
    date(s.canceled_at_utc) as canceled_date
from subscriptions s
left join customers c
    on s.customer_id = c.customer_id