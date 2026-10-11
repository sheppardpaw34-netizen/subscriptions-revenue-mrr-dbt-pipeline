{{
    config(
        materialized='table'
    )
}}

with fx_rates as (
    select
        cast({{ dbt.date_trunc('month', 'fx_date') }} as date) as date_month,
        fx_to_usd,
        lower(currency_code) as currency_code
    from {{ ref('fx_rates') }}
),

stripe_invoices as (
    select
        cast({{ dbt.date_trunc('month', 'inv.created_at_utc') }} as date) as date_month,
        sum(coalesce(inv.amount_paid_local, 0.0) * coalesce(fx.fx_to_usd, 1.0)) as raw_cash_invoiced_usd,
        count(distinct inv.invoice_id) as invoiced_count
    from {{ ref('stg_stripe__invoices') }} as inv
    left join fx_rates as fx
        on
            cast({{ dbt.date_trunc('month', 'inv.created_at_utc') }} as date) = fx.date_month
            and lower(inv.currency_code) = fx.currency_code
    where cast({{ dbt.date_trunc('month', 'inv.created_at_utc') }} as date) <= '2026-09-30'
    group by 1
),

pipeline_mrr as (
    select
        date_month,
        sum(mrr_usd) as pipeline_mrr_usd,
        sum(active_subscriptions_count) as active_sub_count
    from {{ ref('int_customer_mrr_by_months') }}
    where date_month <= '2026-09-30'
    group by 1
),

reconciliation_ledger as (
    select
        cast(coalesce(inv.date_month, mrr.date_month) as date) as date_month,
        coalesce(inv.raw_cash_invoiced_usd, 0) as raw_cash_invoiced_usd,
        coalesce(mrr.pipeline_mrr_usd, 0) as pipeline_mrr_usd,
        coalesce(inv.invoiced_count, 0) as invoiced_count,
        coalesce(mrr.active_sub_count, 0) as active_sub_count,

        -- Normalized billing coverage ratio (Cash Invoiced vs Expected Monthly Run-Rate)
        case
            when coalesce(mrr.pipeline_mrr_usd, 0) = 0 then 0.0
            else round(coalesce(inv.raw_cash_invoiced_usd, 0) / nullif(mrr.pipeline_mrr_usd, 0), 4)
        end as billing_capture_rate,

        round(coalesce(inv.raw_cash_invoiced_usd, 0) - coalesce(mrr.pipeline_mrr_usd, 0), 2) as cash_vs_mrr_drift_usd

    from stripe_invoices as inv
    full outer join pipeline_mrr as mrr
        on inv.date_month = mrr.date_month
)

select
    date_month,
    raw_cash_invoiced_usd,
    pipeline_mrr_usd,
    invoiced_count,
    active_sub_count,
    billing_capture_rate,
    cash_vs_mrr_drift_usd,
    case
        when billing_capture_rate >= 0.90 then 'HEALTHY_BILLING_VELOCITY'
        when billing_capture_rate between 0.40 and 0.89 then 'PARTIAL_CAPTURE_SAMPLE'
        else 'INGESTION_COVERAGE_GAP'
    end as audit_status
from reconciliation_ledger
order by date_month desc
