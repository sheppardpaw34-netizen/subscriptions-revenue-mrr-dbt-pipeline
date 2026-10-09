with first_subscription_month as (
    select
        customer_id,
        min(date_month) as cohort_month
    from {{ ref('int_customer_mrr_by_months') }}
    where mrr_usd > 0
    group by 1
),

customer_monthly_activity as (
    select
        mrr.customer_id,
        f.cohort_month,
        mrr.date_month,

        {{ dbt.datediff('f.cohort_month', 'mrr.date_month', 'month') }} as cohort_age_month,
        mrr.mrr_usd
    from {{ ref('int_customer_mrr_by_months') }} mrr
    inner join first_subscription_month f
        on mrr.customer_id = f.customer_id
),

cohort_base as (
    select
        cohort_month,
        count(distinct customer_id) as initial_logo_count,
        sum(mrr_usd) as cohort_initial_mrr_usd
    from customer_monthly_activity
    where cohort_age_month = 0
    group by 1
),

cohort_activity as (
    select
        a.cohort_month,
        a.cohort_age_month,
        a.date_month,
        count(distinct case when a.mrr_usd > 0 then a.customer_id end) as active_logo_count,
        sum(a.mrr_usd) as cohort_mrr_usd
    from customer_monthly_activity a
    group by 1, 2, 3
)

select
    act.cohort_month,
    act.cohort_age_month,
    act.date_month,
    base.initial_logo_count,
    act.active_logo_count,
    base.cohort_initial_mrr_usd,
    act.cohort_mrr_usd,

    -- Executive Financial Ratios
    round(cast(act.active_logo_count as numeric) / nullif(base.initial_logo_count, 0) * 100, 2) as logo_retention_pct,
    round(cast(act.cohort_mrr_usd as numeric) / nullif(base.cohort_initial_mrr_usd, 0) * 100, 2) as net_revenue_retention_nrr_pct,
    round(100.0 - (cast(act.active_logo_count as numeric) / nullif(base.initial_logo_count, 0) * 100), 2) as cumulative_logo_churn_pct
from cohort_activity act
inner join cohort_base base
    on act.cohort_month = base.cohort_month
order by act.cohort_month desc, act.cohort_age_month asc
