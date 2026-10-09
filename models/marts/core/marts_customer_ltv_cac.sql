with customer_timeline as (
    select
        customer_id,
        min(date_month) as first_active_month,
        max(case when mrr_usd > 0 then date_month end) as last_active_month,
        count(distinct case when mrr_usd > 0 then date_month end) as total_active_months,
        sum(mrr_usd) as lifetime_revenue_usd,
        max(mrr_usd) as peak_mrr_usd,

        -- Current active state check
        max(date_month) = max(case when mrr_usd > 0 then date_month end) as is_currently_active
    from {{ ref('int_customer_mrr_by_months') }}
    group by 1
)

select
    customer_id,
    first_active_month,
    last_active_month,
    total_active_months as tenure_in_months,
    lifetime_revenue_usd as cumulative_ltv_usd,
    peak_mrr_usd,

    -- Average Revenue Per Account (ARPA)
    round(cast(lifetime_revenue_usd as numeric) / nullif(total_active_months, 0), 2)
        as customer_arpa_usd,

    case
        when is_currently_active then 'ACTIVE'
        else 'CHURNED'
    end as account_status
from customer_timeline
order by cumulative_ltv_usd desc
