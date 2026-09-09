with source as (
    select * from {{ source('stripe','customers') }}
),

renamed as (
    select
        cast(id as string) as customer_id,
        cast(email as string) as customer_email,
        {{ convert_timezone('created') }} as created_at_utc,
        cast(currency as string) as currency,
        cast(timezone as string) as customer_timezone
    from source
)

select * from renamed
