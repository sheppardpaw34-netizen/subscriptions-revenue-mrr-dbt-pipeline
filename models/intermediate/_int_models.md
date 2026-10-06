{% docs int_stripe_subscription_events_deduped %}
Deduplicates raw Stripe subscription webhooks. Employs `QUALIFY ROW_NUMBER() OVER (PARTITION BY subscription_id, event_id ORDER BY event_timestamp DESC)` to resolve payload race conditions and duplicate webhook retries.
{% enddocs %}

{% docs int_stripe_subscription_events_deltas %}
Removes no-op state updates where consecutive webhook triggers contain identical plan amounts and subscription statuses. Uses `LAG()` windowing to retain only genuine revenue or status state transitions.
{% enddocs %}

{% docs int_stripe_subscription_events_timelines %}
Transforms point-in-time subscription events into contiguous `valid_from` and `valid_to` time intervals using `LEAD(event_timestamp)`. If a subscription is currently active, `valid_to` remains `NULL`.
{% enddocs %}

{% docs int_subscription_mrr_by_months %}
Joins continuous subscription timeline windows against the monthly calendar date spine (`stg_utilities__date_spine`). Generates continuous monthly snapshot records for all active subscriptions across their lifecycle.
{% enddocs %}

{% docs int_customer_mrr_by_month %}
Rolls up subscription-level monthly fanouts to the **Account/Customer level** (`customer_id + date_month`). Groups multi-subscription accounts into a single total MRR figure per month.
{% enddocs %}

{% docs int_customer_mrr_deltas %}
Calculates month-over-month MRR deltas per customer using `LAG(mrr_local, 1, 0.0)`. Outputs `prev_mrr_local`, `mrr_local`, `mrr_change`, and `is_first_month` flags to prepare data for final waterfall classification in the Marts layer.
{% enddocs %}