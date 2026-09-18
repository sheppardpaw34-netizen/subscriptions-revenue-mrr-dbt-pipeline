with mrr_movements as (
    select * from {{ ref('fct_mrr_waterfall') }}
),

customer_cohorts as (
    select
        customer_id,
        min(date_month) as cohort_month
    from mrr_movements
    where movement_type = 'new'
    group by 1
),

activity_months as (
    select
        m.customer_id,
        c.cohort_month,
        m.date_month as activity_month,
        {% if target.type == 'duckdb' %}
            date_diff('month', cast(c.cohort_month as date), cast(m.date_month as date))
        {% else %}
            date_diff(m.date_month, c.cohort_month, month)
        {% endif %} as month_number,
        m.mrr_amount
    from mrr_movements as m
    inner join customer_cohorts as c
        on m.customer_id = c.customer_id
    where m.mrr_amount > 0
)

select
    cohort_month,
    activity_month,
    month_number,
    count(distinct customer_id) as active_customers,
    sum(mrr_amount) as cohort_mrr
from activity_months
group by 1, 2, 3