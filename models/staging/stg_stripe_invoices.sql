with source as (
    select * from {{ source('stripe', 'invoices') }}
),

renamed as (
    select
        cast(id as string) as invoice_id,
        cast(customer_id as string) as customer_id,
        cast(subscription_id as string) as subscription_id,
        cast(status as string) as invoice_status,

        -- Pricing Normalization
        cast(amount_due / 100.0 as numeric) as amount_due_usd,
        cast(amount_paid / 100.0 as numeric) as amount_paid_usd,

        -- Time Boundaries
        {{ convert_timezone('created') }} as created_at_utc,
        {{ convert_timezone('paid_at') }} as paid_at_utc,
        case 
            when status = 'paid' then true 
            else false 
        end as is_paid

    from source
)

select * from renamed