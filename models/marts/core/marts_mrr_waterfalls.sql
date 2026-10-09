with customer_monthly_mrr as (
    select
        customer_id,
        date_month,
        mrr_usd,
        lag(mrr_usd, 1, 0.0) over (
            partition by customer_id
            order by date_month
        ) as prior_month_mrr_usd
    from {{ ref('int_customer_mrr_by_months') }}
),

waterfall_classified as (
    select
        customer_id,
        date_month,
        mrr_usd as current_mrr_usd,
        prior_month_mrr_usd,
        (mrr_usd - prior_month_mrr_usd) as mrr_delta_usd,
        case
            when
                prior_month_mrr_usd = 0 and mrr_usd > 0
                and not exists (
                    select 1 from customer_monthly_mrr as prev
                    where
                        prev.customer_id = customer_monthly_mrr.customer_id
                        and prev.date_month < customer_monthly_mrr.date_month
                        and prev.mrr_usd > 0
                ) then 'NEW_BOOKING'
            when prior_month_mrr_usd = 0 and mrr_usd > 0 then 'REACTIVATION'
            when mrr_usd = 0 and prior_month_mrr_usd > 0 then 'CHURN'
            when mrr_usd > prior_month_mrr_usd then 'EXPANSION'
            when mrr_usd < prior_month_mrr_usd and mrr_usd > 0 then 'CONTRACTION'
            else 'RETAINED'
        end as mrr_category
    from customer_monthly_mrr
)

select
    customer_id,
    date_month,
    prior_month_mrr_usd,
    current_mrr_usd,
    mrr_delta_usd,
    mrr_category,
    case when mrr_category = 'NEW_BOOKING' then mrr_delta_usd else 0 end as new_mrr_usd,
    case when mrr_category = 'EXPANSION' then mrr_delta_usd else 0 end as expansion_mrr_usd,
    case when mrr_category = 'CONTRACTION' then abs(mrr_delta_usd) else 0 end
        as contraction_mrr_usd,
    case when mrr_category = 'CHURN' then abs(prior_month_mrr_usd) else 0 end as churn_mrr_usd,
    case when mrr_category = 'REACTIVATION' then mrr_delta_usd else 0 end as reactivation_mrr_usd
from waterfall_classified
