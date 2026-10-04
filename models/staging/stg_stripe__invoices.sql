with source as (
    select * from {{ source('stripe', 'invoices') }}
),

renamed as (
    select
        cast(invoice_id as string) as invoice_id,
        cast(subscription_id as string) as subscription_id,
        cast(customer_id as string) as customer_id,
        cast(status as string) as invoice_status,
        lower(trim(cast(customer_email as string))) as customer_email,
        cast(subtotal_cents as numeric) / 100.0 as subtotal_amount_local,
        cast(amount_due_cents as numeric) / 100.0 as amount_due_local,
        cast(amount_paid_cents as numeric) / 100.0 as amount_paid_local,
        upper(trim(cast(currency as string))) as currency_code,
        {{ dbt_date.from_unixtimestamp("created_at") }} as created_at_utc,
        {{ dbt_date.from_unixtimestamp("due_date") }} as due_date_utc,
        {{ dbt_date.from_unixtimestamp("paid_at_utc") }} as paid_at_utc
    from source
)

select * from renamed