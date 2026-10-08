with filtered_deltas as (
    select * from {{ref('int_stripe__subscription_events_deltas')}}
),

subscription_window as (
    select 
        event_id,
        customer_id,
        subscription_id,
        plan_id,
        plan_interval,
        plan_amount_local,
        currency_code,
        event_type,
        subscription_status,
        event_timestamp_utc as valid_from,
        lead(event_timestamp_utc) over (
            partition by subscription_id 
            order by event_timestamp_utc asc, event_id asc
        ) as valid_to
    from filtered_deltas
)

select 
    {{ dbt_utils.generate_surrogate_key(['subscription_id', 'valid_from']) }} as timeline_id,
    event_id,
    customer_id,
    subscription_id,
    plan_id,
    plan_interval,
    plan_amount_local,
    currency_code,
    event_type,
    subscription_status,
    valid_from,
    valid_to,
    case when valid_to is null then true else false end as is_current_state
from subscription_window