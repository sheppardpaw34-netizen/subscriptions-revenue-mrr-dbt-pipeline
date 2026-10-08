with subscription_mrr as (
    select * from {{ ref('int_subscription_mrr_by_months') }}
),

fx_rates as (
    select
        upper(trim(currency_code)) as currency_code,
        cast(fx_date as date) as fx_date,
        cast(fx_to_usd as numeric) as fx_to_usd
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
        date_month,
        customer_id,
        sum(mrr_local) as mrr_local,
        sum(mrr_usd) as mrr_usd,
        count(distinct subscription_id) as active_subscriptions_count
    from joined_fx
    where subscription_status in ('active', 'past_due', 'trialing')
    group by 
        date_month,
        customer_id
)

select * from customer_monthly_mrr