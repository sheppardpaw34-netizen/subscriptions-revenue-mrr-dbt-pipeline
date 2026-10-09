with subscription_mrr as (
    select * from {{ ref('int_subscription_mrr_by_months') }}
),

customers as (
    select * from {{ ref('stg_stripe__customers') }}
),

fx_rates as (
    select
        cast(fx_date as date) as fx_date,
        cast(fx_to_usd as numeric) as fx_to_usd,
        upper(trim(currency_code)) as currency_code
    from {{ ref('fx_rates') }}
),

joined_fx as (
    select
        s.date_month,
        s.customer_id,
        s.subscription_id,
        s.subscription_status,
        s.currency_code,
        s.mrr_local,
        coalesce(fx.fx_to_usd, 1.0) as fx_to_usd,
        round(s.mrr_local * coalesce(fx.fx_to_usd, 1.0), 2) as mrr_usd
    from subscription_mrr s
    left join fx_rates fx
        on s.currency_code = fx.currency_code
        and s.date_month = fx.fx_date
),

customer_monthly_mrr as (
    select
        j.date_month,
        j.customer_id,
        c.customer_email,
        c.created_at_utc,
        date_trunc('month', c.created_at_utc) as cohort_month,
        sum(j.mrr_local) as mrr_local,
        sum(j.mrr_usd) as mrr_usd,
        count(distinct j.subscription_id) as active_subscriptions_count
    from joined_fx j
    left join customers c
        on j.customer_id = c.customer_id
    where j.subscription_status in ('active', 'past_due', 'trialing')
    group by
        j.date_month,
        j.customer_id,
        c.customer_email,
        c.created_at_utc
)

select * from customer_monthly_mrr