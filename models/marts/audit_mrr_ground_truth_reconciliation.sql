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
        sum(coalesce(inv.amount_paid_local, 0.0) * coalesce(fx.fx_to_usd, 1.0))
            as raw_cash_invoiced_usd
    from {{ ref('stg_stripe__invoices') }} as inv
    left join fx_rates as fx
        on
            cast({{ dbt.date_trunc('month', 'inv.created_at_utc') }} as date) = fx.date_month
            and lower(inv.currency_code) = fx.currency_code
    group by 1
),

pipeline_mrr as (
    select
        date_month,
        sum(mrr_usd) as pipeline_mrr_usd
    from {{ ref('int_customer_mrr_by_months') }}
    group by 1
),

reconciliation_ledger as (
    select
        cast(coalesce(inv.date_month, mrr.date_month) as date) as date_month,
        coalesce(inv.raw_cash_invoiced_usd, 0) as raw_cash_invoiced_usd,
        coalesce(mrr.pipeline_mrr_usd, 0) as pipeline_mrr_usd,

        round(coalesce(inv.raw_cash_invoiced_usd, 0) - coalesce(mrr.pipeline_mrr_usd, 0), 2)
            as cash_vs_mrr_drift_usd,

        round(
            sum(coalesce(inv.raw_cash_invoiced_usd, 0) - coalesce(mrr.pipeline_mrr_usd, 0)) over (
                order by cast(coalesce(inv.date_month, mrr.date_month) as date)
                rows between unbounded preceding and current row
            ), 2
        ) as cumulative_cash_mrr_variance_usd
    from stripe_invoices as inv
    full outer join pipeline_mrr as mrr
        on inv.date_month = mrr.date_month
)

select
    date_month,
    raw_cash_invoiced_usd,
    pipeline_mrr_usd,
    cash_vs_mrr_drift_usd,
    cumulative_cash_mrr_variance_usd,
    case
        when
            raw_cash_invoiced_usd = 0 and pipeline_mrr_usd > 0
            then 'ACTIVE_RECURRING_REVENUE_RECOGNITION'
        when cash_vs_mrr_drift_usd > 0 then 'UPFRONT_CASH_COLLECTION_SURGE'
        when abs(cash_vs_mrr_drift_usd) <= 5000.00 then 'BALANCED_MONTHLY_CADENCE'
        else 'EXPLAINED_ACCRUAL_TIMING_DRIFT'
    end as audit_status
from reconciliation_ledger
order by date_month desc
