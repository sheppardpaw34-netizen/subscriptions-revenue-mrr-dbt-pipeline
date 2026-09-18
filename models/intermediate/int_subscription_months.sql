with subscription_periods as (
    select * from {{ ref('int_subscription_periods') }}
),

subscription_months as (
    select
        sp.subscription_id,
        sp.customer_id,
        sp.plan_id,
        sp.subscription_status,
        cast(
            {% if target.type == 'duckdb' %}
                dm.date_month
            {% else %}
                date_month
            {% endif %}
        as date) as date_month
    from subscription_periods as sp
    {% if target.type == 'duckdb' %}
    cross join generate_series(
        date_trunc('month', cast(sp.start_date as date)),
        date_trunc('month', cast(sp.end_date as date) + interval '1 month'),
        interval '1 month'
    ) as dm(date_month)
    {% else %}
    cross join unnest(
        generate_date_array(
            date_trunc(sp.start_date, month),
            date_trunc(date_add(sp.end_date, interval 1 month), month),
            interval 1 month
        )
    ) as date_month
    {% endif %}
),

monthly_invoices as (
    select
        subscription_id,
        date_trunc(
            {% if target.type == 'duckdb' %}
                'month', cast(created_at_utc as date)
            {% else %}
                date(created_at_utc), month
            {% endif %}
        ) as date_month,
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