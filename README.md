## 📊 Business Intelligence & Semantic Layer (MetricFlow + Lightdash)

This repository enforces **BI-as-Code** by defining business metrics centrally in dbt MetricFlow (`mertic.yml`) and exposing them to Lightdash for headless querying.

### 1. Key Business Metrics Exposed
* **Gross New MRR**: Sum of new subscription monthly recurring revenue.
* **Expansion & Contraction MRR**: Net expansion or downgrade deltas across active accounts.
* **Net Revenue Retention (NRR)**: Benchmark tracking revenue expansion against churned/contracted revenue.

### 2. Local BI Query Execution (Lightdash CLI)
Engineers can compile and validate metric definitions locally using the Lightdash and MetricFlow CLI toolchains:

```bash
# Validate local dbt semantic models against Lightdash project specs
lightdash compile

# Query semantic metrics directly from BigQuery via MetricFlow CLI
mf query --metrics net_revenue_retention,gross_revenue_retention --group-by fct_mrr_cohort_metrics__date_month