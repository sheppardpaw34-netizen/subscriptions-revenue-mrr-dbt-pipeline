### Models Included
* **`fct_mrr_movements.sql`**: Primary fact mart capturing month-over-month account state transitions, MRR delta changes, and categorical classifications.
* **`metricflow_time_spine.sql`**: Daily time spine model generating standard date granularity required for MetricFlow semantic aggregations.

---

## 3. Core Business Logic & MRR Movement Taxonomy

MRR transitions are calculated at the monthly grain using SQL window functions (`LAG()`) on `mrr_amount` partitioned by `subscription_id`:

| Movement Type | Business Condition | Financial Impact |
| :--- | :--- | :--- |
| **`new`** | `previous_mrr IS NULL` or `0` and `current_mrr > 0` | Revenue expansion (+MRR) |
| **`expansion`** | `current_mrr > previous_mrr` | Account expansion (+MRR) |
| **`contraction`** | `current_mrr < previous_mrr` and `current_mrr > 0` | Account contraction (-MRR) |
| **`churn`** | `previous_mrr > 0` and `current_mrr = 0` | Account loss (-MRR) |
| **`retained`** | `current_mrr = previous_mrr` | Preserved baseline MRR |

---

## 4. Semantic Layer (MetricFlow Specs)

Defined metrics exposed to downstream BI tools:
* **`gross_new_mrr`**: Sum of `total_mrr_change` filtered on `movement_type = 'new'`.
* **`expansion_mrr`**: Sum of `total_mrr_change` filtered on `movement_type = 'expansion'`.
* **`contraction_mrr`**: Sum of `total_mrr_change` filtered on `movement_type = 'contraction'`.
* **`churned_mrr`**: Sum of `total_mrr_change` filtered on `movement_type = 'churn'`.
* **`retained_mrr`**: Sum of `ending_mrr` filtered on `movement_type = 'retained'`.

---

## 5. Quality Assertions & Testing

All models enforce the following schema-level assertions before production deployment:
* **Unique & Non-Null Composite Constraints**: `subscription_id` + `date_month` composite keys.
* **Domain Accepted Values**: Strict validation enforcing allowed values `['new', 'expansion', 'contraction', 'churn', 'retained']` on `movement_type`.