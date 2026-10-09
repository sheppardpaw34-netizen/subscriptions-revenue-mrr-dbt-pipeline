with monthly_waterfall_aggregates as (
    select
        date_month,
        sum(new_mrr_usd) as total_new_mrr,
        sum(expansion_mrr_usd) as total_expansion_mrr,
        sum(reactivation_mrr_usd) as total_reactivation_mrr,
        sum(abs(contraction_mrr_usd)) as total_contraction_mrr,
        sum(abs(churn_mrr_usd)) as total_churn_mrr
    from {{ ref('marts_mrr_waterfalls') }}
    group by 1
)

select
    date_month,
    total_new_mrr,
    total_expansion_mrr,
    total_reactivation_mrr,
    total_contraction_mrr,
    total_churn_mrr,

    -- Inflow & Outflow totals
    (total_new_mrr + total_expansion_mrr + total_reactivation_mrr) as total_gross_additions_mrr,
    (total_contraction_mrr + total_churn_mrr) as total_gross_losses_mrr,

    -- SaaS Quick Ratio Calculation
    round(
        cast(total_new_mrr + total_expansion_mrr + total_reactivation_mrr as numeric)
        / nullif(cast(total_contraction_mrr + total_churn_mrr as numeric), 0),
        2
    ) as saas_quick_ratio
from monthly_waterfall_aggregates
order by date_month desc
