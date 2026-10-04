with source as (
    select * from {{ source('stripe', 'subscription_events') }}
),

renamed as (
    select
        cast(event_id as string) as event_id,
        cast(subscription_id as string) as subscription_id,
        cast(customer_id as string) as customer_id,
        cast(event_type as string) as event_type,
        cast(plan_id as string) as plan_id,
        cast(plan_interval as string) as plan_interval,
        cast(plan_amount_cents as numeric) / 100.0 as plan_amount_local,
        upper(trim(cast(currency as string))) as currency_code,
        cast(status as string) as subscription_status,
        {{ dbt_date.from_unixtimestamp("event_timestamp") }} as event_timestamp_utc,
        cast({{ dbt_date.from_unixtimestamp("event_timestamp") }} as date) as event_timestamp_date
    from source
)

select * from renamed