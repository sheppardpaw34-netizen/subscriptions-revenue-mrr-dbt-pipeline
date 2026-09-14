with subscription_periods as (
    select * from {{ref('int_subscription_periods')}}
),

subscription_months as (
    select
        sp.subscription_id,
        sp.customer_id,
        sp.plan_id,
        sp.subscription_status,
        sp.mrr_amount,
        date_month
    from subscription_periods as sp
    cross join unnest(
        generate_date_array(
            date_trunc(sp.start_date, month),
            date_trunc(sp.end_date, month),
            interval 1 month
        )
    ) as date_month
)

select * from subscription_months