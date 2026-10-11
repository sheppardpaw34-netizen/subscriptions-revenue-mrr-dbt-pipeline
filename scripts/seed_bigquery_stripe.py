import os
import random
from datetime import datetime, timedelta, timezone
import duckdb
import pandas as pd

random.seed(42)

NUM_CUSTOMERS = 1000
START_DATE = datetime(2024, 1, 1, tzinfo=timezone.utc)
END_DATE = datetime(2026, 9, 30, tzinfo=timezone.utc)

PLANS = [
    {"plan_id": "plan_starter", "amount_cents": 2900, "currency": "usd"},
    {"plan_id": "plan_pro", "amount_cents": 9900, "currency": "usd"},
    {"plan_id": "plan_enterprise", "amount_cents": 29900, "currency": "usd"},
]

TIMEZONES = ["UTC", "America/New_York", "Europe/London"]


def generate_stripe_data():
  customers = []
  subscriptions = []
  invoices = []

  evt_counter = 1
  inv_counter = 1
  total_days = (END_DATE - START_DATE).days

  for i in range(1, NUM_CUSTOMERS + 1):
    cust_id = f"cus_{i:04d}"
    sub_id = f"sub_{i:04d}"
    email = f"user_{i:04d}@saas_client.com"

    # Signup spread
    created_days = random.randint(0, total_days - 90)
    created_dt = START_DATE + timedelta(days=created_days)

    customers.append({
        "customer_id": cust_id,
        "email": email,
        "created_at_utc": int(created_dt.timestamp()),
        "currency": "usd",
        "timezone": random.choice(TIMEZONES),
    })

    current_plan = random.choice(PLANS)
    curr_dt = created_dt

    # 1. Subscription Created Event
    subscriptions.append({
        "event_id": f"evt_{evt_counter:06d}",
        "event_type": "customer.subscription.created",
        "event_timestamp": int(curr_dt.timestamp()),
        "subscription_id": sub_id,
        "customer_id": cust_id,
        "plan_id": current_plan["plan_id"],
        "plan_interval": "month",
        "plan_amount_cents": current_plan["amount_cents"],
        "currency": current_plan["currency"],
        "status": "active",
    })
    evt_counter += 1

   # Lifecycle simulation (Guaranteed monthly billing parity)
    while curr_dt <= END_DATE:
        amt = current_plan["amount_cents"]
        invoices.append({
            "invoice_id": f"in_{inv_counter:06d}",
            "subscription_id": sub_id,
            "customer_id": cust_id,
            "customer_email": email,
            "status": "paid",
            "plan_interval": "month",
            "subtotal_cents": amt,
            "amount_due_cents": amt,
            "amount_paid_cents": amt,
            "currency": current_plan["currency"],
            "created_at": int(curr_dt.timestamp()),
            "due_date": int((curr_dt + timedelta(days=7)).timestamp()),
            "paid_at_utc": int((curr_dt + timedelta(days=1)).timestamp()),
        })
        inv_counter += 1
        curr_dt += timedelta(days=30)


  return (
      pd.DataFrame(customers),
      pd.DataFrame(subscriptions),
      pd.DataFrame(invoices),
  )


if __name__ == "__main__":
  print("Generating clean, synchronized Stripe mock data...")
  df_cust, df_subs, df_inv = generate_stripe_data()

  conn = duckdb.connect("my_db.duckdb")
  conn.execute("CREATE SCHEMA IF NOT EXISTS raw_stripe;")

  conn.execute("DROP TABLE IF EXISTS raw_stripe.stg_stripe_customers;")
  conn.execute("DROP TABLE IF EXISTS raw_stripe.stg_stripe_subscriptions;")
  conn.execute("DROP TABLE IF EXISTS raw_stripe.stg_stripe_invoices;")

  conn.execute(
      "CREATE OR REPLACE TABLE raw_stripe.customers AS SELECT * FROM df_cust"
  )
  conn.execute(
      "CREATE OR REPLACE TABLE raw_stripe.subscription_events AS SELECT *"
      " FROM df_subs"
  )
  conn.execute(
      "CREATE OR REPLACE TABLE raw_stripe.invoices AS SELECT * FROM df_inv"
  )

  print("Clean data loaded into raw_stripe successfully!")
  conn.close()