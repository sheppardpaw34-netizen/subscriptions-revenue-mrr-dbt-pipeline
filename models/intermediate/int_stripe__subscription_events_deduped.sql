with source as (
    select * from {{ref('stg_stripe__subscription_events')}}
),

deduplicated as (
    select 
        event_id,
        customer_id,
        subscription_id,
        event_type,
        plan_id,
        plan_interval,
        plan_amount_local,
        currency_code,
        subscription_status,
        event_timestamp_utc,
        event_timestamp_date,
        row_number() over (
            partition by subscription_id, event_timestamp_utc
            order by event_id desc
        ) as row_num
    from source
)

select 
    event_id,
    customer_id,
    subscription_id,
    event_type,
    plan_id,
    plan_interval,
    plan_amount_local,
    currency_code,
    subscription_status,
    event_timestamp_utc,
    event_timestamp_date
from deduplicated
where row_num = 1 