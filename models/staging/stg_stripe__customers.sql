with source as (
    select * from {{ source('stripe','customers') }}
),

renamed as (
    select
        cast(customer_id as string) as customer_id,
        lower(trim(cast(email as string))) as customer_email,
        upper(trim(cast(currency as string))) as billing_currency,
        cast(timezone as string) as customer_timezone,
        {{ dbt_date.from_unixtimestamp("created_at_utc") }} as created_at_utc
    from source
)


select * from renamed
