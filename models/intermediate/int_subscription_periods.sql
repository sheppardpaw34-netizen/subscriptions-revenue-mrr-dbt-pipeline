with subscriptions as (
    select * from {{ ref('stg_stripe_subscriptions') }}
),

customers as (
    select * from {{ ref('stg_stripe_customers') }}
),

invoices as (
    select * from {{ ref('stg_stripe_invoices') }}
),

subscription_periods as (
    select
        s.subscription_id,
        s.customer_id,
        s.plan_id,
        s.subscription_status,
        s.mrr_amount,
        date(s.started_at_utc) as start_date,
        coalesce(date(s.canceled_at_utc), current_date()) as end_date
    from subscriptions s
    left join customers c 
        on s.customer_id = c.customer_id
    left join invoices i 
        on s.subscription_id = i.subscription_id
)

select * from subscription_periods