/*
===============================================================================
TEST: tests/assert_mrr_balance_matches.sql
ROLE: Financial Reciprocity Integrity Test
ASSERTION: current_mrr (mrr_amount) - previous_mrr (previous_mrr_amount) = mrr_change
RETURNS: Fails if any customer subscription month returns a non-zero variance.
===============================================================================
*/

with waterfall as (

    select * from {{ ref('fct_mrr_waterfall') }}

),

reconciliation as (

    select
        date_month,
        subscription_id,
        customer_id,
        movement_type,
        previous_mrr_amount,
        mrr_amount as current_mrr_amount,
        mrr_change,
        -- Calculated variance delta: (Current MRR - Previous MRR) should equal mrr_change
        abs(
            (mrr_amount - coalesce(previous_mrr_amount, 0)) - mrr_change
        ) as variance_delta
    from waterfall

)

-- dbt tests pass when 0 rows are returned.
select *
from reconciliation
where variance_delta > 0.01