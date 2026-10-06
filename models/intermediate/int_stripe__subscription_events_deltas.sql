with deduplicated_events as (
    select * from {{ ref('int_stripe__subscription_events_deduped')}}
    ),

lagged_events as (
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
        lag(subscription_status) over (
            partition by subscription_id
            order by event_timestamp_utc asc, event_id asc
        ) as prev_subscription_status,
        lag(plan_amount_local) over (
            partition by subscription_id
            order by event_timestamp_utc asc, event_id asc
        ) as prev_plan_amount_local
    from deduplicated_events
),

filtered_deltas as (
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
    from lagged_events
    where prev_subscription_status is null
    or subscription_status != prev_subscription_status
    or plan_amount_local != prev_plan_amount_local
) 

select * from filtered_deltas