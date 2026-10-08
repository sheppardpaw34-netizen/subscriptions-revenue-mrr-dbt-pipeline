with timeline as (
    select * from {{ ref('int_stripe__subscription_timelines')}}
),

calender_months as (
    select * from {{ ref('stg_utilities__date_spine')}}
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
        end as mrr_local,
        t.valid_from,
        t.valid_to
    from calender_months c
    inner join timeline t 
    on c.date_month >= date_trunc('month', cast(t.valid_from as date))
        and (
    c.date_month <= date_trunc('month', cast(t.valid_to as date))
    or t.valid_to is null
)

)

select * from subscription_monthly_fanout