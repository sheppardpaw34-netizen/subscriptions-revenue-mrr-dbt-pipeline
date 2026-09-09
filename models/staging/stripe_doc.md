{% docs stripe_mrr_amount %}
### Monthly Recurring Revenue (MRR) Component
Normalization unit-level pricing into total normalized monthly revenue.

* **Formula** `(unit_amount / 100.00) * quantity`
* **currency** USD 
* **Usage** Serves as a base metrics for ACV (`MRR * 12`), MRR Waterfalls, and GRR/NRR cohort calculation downstream.
{% enddocs %}

{% docs stripe_is_active %}
### Operational Activity Flag 
Indicate whether a subscription is currently generating revenue. Used downstream for SCD type 2 state snapshooting and churn identification.
{% enddocs %}