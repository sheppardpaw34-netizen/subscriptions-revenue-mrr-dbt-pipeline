/*
===============================================================================
ANALYSIS: analyses/saas_executive_mrr_performance.sql
PURPOSE: Aggregates monthly MRR waterfall movements to evaluate high-level 
         SaaS growth metrics, Net Revenue Retention (NRR), and Gross Revenue 
         Retention (GRR) for executive reporting.
===============================================================================
*/

with mrr_waterfall as (
    select * from {{ ref('fct_mrr_waterfall') }}
),

monthly_summary as (
    select
        date_trunc('month', date_month) as snapshot_month,
        
        -- Starting & Ending Baseline
        sum(previous_mrr_amount) as total_starting_mrr,
        sum(mrr_amount) as total_ending_mrr,
        
        -- Movement Components
        sum(case when lower(movement_type) = 'new' then mrr_change else 0 end) as gross_new_mrr,
        sum(case when lower(movement_type) = 'expansion' then mrr_change else 0 end) as expansion_mrr,
        sum(case when lower(movement_type) = 'contraction' then abs(mrr_change) else 0 end) as contraction_mrr,
        sum(case when lower(movement_type) = 'churn' then abs(mrr_change) else 0 end) as churn_mrr

    from mrr_waterfall
    group by 1
)

select
    snapshot_month,
    total_starting_mrr,
    gross_new_mrr,
    expansion_mrr,
    contraction_mrr,
    churn_mrr,
    total_ending_mrr,
    
    -- Net MRR Change
    (gross_new_mrr + expansion_mrr - contraction_mrr - churn_mrr) as net_mrr_change,
    
    -- Financial Efficiency Benchmarks (%)
    round(
        (total_starting_mrr + expansion_mrr - contraction_mrr - churn_mrr) 
        / nullif(total_starting_mrr, 0) * 100, 2
    ) as net_revenue_retention_nrr_pct,
    
    round(
        (total_starting_mrr - contraction_mrr - churn_mrr) 
        / nullif(total_starting_mrr, 0) * 100, 2
    ) as gross_revenue_retention_grr_pct

from monthly_summary
order by snapshot_month desc;