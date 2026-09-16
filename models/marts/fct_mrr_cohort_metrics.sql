with monthly_mrr as (
    select
        date_month,
        sum(case when movement_type = 'retained' then mrr_amount else 0 end) as retained_mrr,
        sum(case when movement_type = 'expansion' then mrr_change else 0 end) as expansion_mrr,
        sum(case when movement_type = 'contraction' then abs(mrr_change) else 0 end) as contraction_mrr,
        sum(case when movement_type = 'churn' then abs(mrr_change) else 0 end) as churn_mrr,
        sum(mrr_amount) as total_ending_mrr
    from {{ ref('fct_mrr_waterfall') }}
    group by 1
),

retention_rates as (
    select
        date_month,
        total_ending_mrr,
        lag(total_ending_mrr) over (order by date_month) as starting_mrr,
        -- NRR = (Starting MRR + Expansion - Contraction - Churn) / Starting MRR
        safe_divide(
            (lag(total_ending_mrr) over (order by date_month) + expansion_mrr - contraction_mrr - churn_mrr),
            lag(total_ending_mrr) over (order by date_month)
        ) * 100 as nrr_percentage,
        -- GRR = (Starting MRR - Contraction - Churn) / Starting MRR (capped at 100%)
        safe_divide(
            (lag(total_ending_mrr) over (order by date_month) - contraction_mrr - churn_mrr),
            lag(total_ending_mrr) over (order by date_month)
        ) * 100 as grr_percentage
    from monthly_mrr
)

select * from retention_rates