with timeline as (
    select * from {{ ref('int_stripe__subscription_timelines') }}
),

calendar_months as (
    select * from {{ ref('stg_utilities__date_spine') }}
),

subscription_monthly_fanout as (
    select
        c.date_month,
        t.subscription_id,
        t.customer_id,
        t.plan_id,
        t.plan_interval,
        t.currency_code,
        t.subscription_status,
        case
            when t.plan_interval = 'year' then t.plan_amount_local / 12.0
            when t.plan_interval = 'week' then t.plan_amount_local * 4.3333
            when t.plan_interval = 'day' then t.plan_amount_local * 30.0
            else t.plan_amount_local
        end as mrr_local
    from calendar_months as c
    inner join timeline as t
        on
            c.date_month >= cast({{ dbt.date_trunc('month', 't.valid_from') }} as date)
            and (
                c.date_month <= cast({{ dbt.date_trunc('month', 't.valid_to') }} as date)
                or (
                    c.date_month = cast({{ dbt.date_trunc('month', 't.valid_to') }} as date)
                    and cast(t.valid_to as date) > c.date_month
                )
                or t.valid_to is null
            )
),


deduplicated_subscription_mrr as (
    select
        date_month,
        subscription_id,
        max(customer_id) as customer_id,
        max(plan_id) as plan_id,
        max(plan_interval) as plan_interval,
        max(currency_code) as currency_code,
        max(subscription_status) as subscription_status,
        max(mrr_local) as mrr_local
    from subscription_monthly_fanout
    group by 1, 2
)

select * from deduplicated_subscription_mrr
