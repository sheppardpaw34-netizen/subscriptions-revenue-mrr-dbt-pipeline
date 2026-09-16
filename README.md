## 📊 Business Intelligence & Semantic Layer (MetricFlow + Lightdash)

This repository enforces **BI-as-Code** by defining business metrics centrally in dbt MetricFlow (`mertic.yml`) and exposing them to Lightdash for headless querying.

### 1. Key Business Metrics Exposed
* **Gross New MRR**: Sum of new subscription monthly recurring revenue.
* **Expansion & Contraction MRR**: Net expansion or downgrade deltas across active accounts.
* **Net Revenue Retention (NRR)**: Benchmark tracking revenue expansion against churned/contracted revenue.

## 📊 Business Intelligence & Semantic Layer (Lightdash)

This repository follows **BI-as-Code** principles. Metrics and semantic definitions configured in dbt are automatically synced and version-controlled with Lightdash.

### MRR Movement Waterfall Chart
Below is the compiled Lightdash visualization generated from `fct_mrr_waterfall`:

![MRR Movement Waterfall](assets/lightdash_chart.png)

### Sync & Deploy Commands
```bash
# Export saved Lightdash charts to local code repository
lightdash download

# Compile project lightdash metadata locally
lightdash compile