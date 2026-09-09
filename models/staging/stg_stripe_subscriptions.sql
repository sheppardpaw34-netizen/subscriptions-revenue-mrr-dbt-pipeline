with source as (
    select * from {{ source('stripe', 'subscriptions') }}
),

renamed as (
    select
        cast(id as string) as subscription_id,
        cast(customer_id as string) as customer_id,
        cast(plan_id as string) as plan_id,
        cast(status as string) as subscription_status,
        cast(quantity as int64) as quantity,
        cast(unit_amount / 100.0 as numeric) as unit_price_usd,
        cast((unit_amount / 100.0) * quantity as numeric) as mrr_amount,
        cast(((unit_amount / 100.0) * quantity) * 12 as numeric) as arr_amount,
        {{ convert_timezone('created') }} as started_at_utc,
        {{ convert_timezone('canceled_at') }} as canceled_at_utc,

        case 
            when status = 'active' then true 
            else false 
        end as is_active

    from source
)

select * from renamed