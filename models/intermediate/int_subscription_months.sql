with subscription_periods as (
    select * from {{ ref('int_subscription_periods') }}
),

subscription_months as (
    select
        sp.subscription_id,
        sp.customer_id,
        sp.plan_id,
        sp.subscription_status,
        date_month
    from subscription_periods as sp
    cross join unnest(
        generate_date_array(
            date_trunc(sp.start_date, month),
            date_trunc(date_add(sp.end_date, interval 1 month), month),
            interval 1 month
        )
    ) as date_month
),

monthly_invoices as (
    select
        subscription_id,
        date_trunc(date(created_at_utc), month) as date_month,
        sum(amount_due_usd / 100.0) as invoice_mrr
    from {{ ref('stg_stripe_invoices') }}
    where invoice_status = 'paid'
    group by 1, 2
)

select
    sm.subscription_id,
    sm.customer_id,
    sm.plan_id,
    sm.subscription_status,
    sm.date_month,
    coalesce(inv.invoice_mrr, 0.0) as mrr_amount
from subscription_months as sm
left join monthly_invoices as inv
    on sm.subscription_id = inv.subscription_id
   and sm.date_month = inv.date_month