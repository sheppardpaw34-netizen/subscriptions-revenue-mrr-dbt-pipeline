import os
import random
from datetime import datetime, timedelta, timezone
import duckdb

from google.cloud import bigquery
import pandas as pd

random.seed(42)

NUM_CUSTOMERS = 1000
START_DATE = datetime(2024, 1, 1, tzinfo=timezone.utc)
END_DATE = datetime(2026, 9, 30, tzinfo=timezone.utc)

PLANS = [
    # Monthly Plans
    {
        "plan_id": "plan_starter_monthly",
        "interval": "month",
        "amount_cents": 2900,
        "currency": "usd",
    },
    {
        "plan_id": "plan_pro_monthly",
        "interval": "month",
        "amount_cents": 9900,
        "currency": "usd",
    },
    {
        "plan_id": "plan_enterprise_monthly",
        "interval": "month",
        "amount_cents": 29900,
        "currency": "usd",
    },
    # Yearly Plans
    {
        "plan_id": "plan_starter_yearly",
        "interval": "year",
        "amount_cents": 29000,
        "currency": "usd",
    },
    {
        "plan_id": "plan_pro_yearly",
        "interval": "year",
        "amount_cents": 99000,
        "currency": "usd",
    },
    {
        "plan_id": "plan_enterprise_yearly",
        "interval": "year",
        "amount_cents": 299000,
        "currency": "usd",
    },
    # Currency Noise
    {
        "plan_id": "plan_pro_monthly_eur",
        "interval": "month",
        "amount_cents": 9200,
        "currency": "eur",
    },
]

TIMEZONES = ["UTC", "America/New_York", "Europe/London", "Asia/Tokyo"]


def generate_stripe_normalized_data():
  customers = []
  subscriptions = []
  invoices = []

  evt_counter = 1
  inv_counter = 1

  total_days = (END_DATE - START_DATE).days

  for i in range(1, NUM_CUSTOMERS + 1):
    cust_id = f"cus_{i:04d}"
    sub_id = f"sub_{i:04d}"
    tz = random.choice(TIMEZONES)
    email = f"user_{i:04d}@saas_client.com"

    # Spread customer signups across 2024-2026
    created_days = random.randint(0, max(1, total_days - 60))
    created_dt = START_DATE + timedelta(
        days=created_days, seconds=random.randint(0, 86400)
    )
    created_unix = int(created_dt.timestamp())

    # 1. Customers Table (Raw Stripe stores epoch integers)
    customers.append({
        "customer_id": cust_id,
        "email": email,
        "created_at_utc": created_unix,
        "currency": "usd",
        "timezone": tz,
    })

    # 2. Subscriptions & Events setup
    current_plan = random.choice(PLANS)
    curr_dt = created_dt

    # Initial Created Event
    subscriptions.append({
        "event_id": f"evt_{evt_counter:06d}",
        "event_type": "customer.subscription.created",
        "event_timestamp": int(curr_dt.timestamp()),
        "subscription_id": sub_id,
        "customer_id": cust_id,
        "plan_id": current_plan["plan_id"],
        "plan_interval": current_plan["interval"],
        "plan_amount_cents": current_plan["amount_cents"],
        "currency": current_plan["currency"],
        "status": "active",
    })
    evt_counter += 1

    # Exact-Second Webhook Duplicate Noise (15% chance)
    if random.random() < 0.15:
      subscriptions.append({
          "event_id": f"evt_{evt_counter:06d}_dup",
          "event_type": "customer.subscription.created",
          "event_timestamp": int(curr_dt.timestamp()),
          "subscription_id": sub_id,
          "customer_id": cust_id,
          "plan_id": current_plan["plan_id"],
          "plan_interval": current_plan["interval"],
          "plan_amount_cents": current_plan["amount_cents"],
          "currency": current_plan["currency"],
          "status": "active",
      })
      evt_counter += 1

    # Generate Recurring Invoices & Events over lifetime
    is_active = True
    while is_active and curr_dt <= END_DATE:
      # Build Complete Invoice Entry matching real Stripe payload
      subtotal = current_plan["amount_cents"]
      due_dt = curr_dt + timedelta(days=7)
      paid_dt = curr_dt + timedelta(
          hours=random.randint(1, 48)
      )  # Paid within 2 days

      invoices.append({
          "invoice_id": f"in_{inv_counter:06d}",
          "subscription_id": sub_id,
          "customer_id": cust_id,
          "customer_email": email,
          "status": "paid",
          "plan_interval": current_plan["interval"],
          "subtotal_cents": subtotal,
          "amount_due_cents": subtotal,
          "amount_paid_cents": subtotal,
          "currency": current_plan["currency"],
          "created_at": int(curr_dt.timestamp()),
          "due_date": int(due_dt.timestamp()),
          "paid_at_utc": int(paid_dt.timestamp()),
      })
      inv_counter += 1

      # Advance step based on interval
      step_days = 365 if current_plan["interval"] == "year" else 30
      curr_dt += timedelta(days=step_days, seconds=random.randint(0, 3600))

      if curr_dt > END_DATE:
        break

      rand_val = random.random()

      # Plan Upgrade / Downgrade (10% chance)
      if rand_val < 0.10:
        new_plan = random.choice(
            [p for p in PLANS if p["plan_id"] != current_plan["plan_id"]]
        )
        current_plan = new_plan
        subscriptions.append({
            "event_id": f"evt_{evt_counter:06d}",
            "event_type": "customer.subscription.updated",
            "event_timestamp": int(curr_dt.timestamp()),
            "subscription_id": sub_id,
            "customer_id": cust_id,
            "plan_id": current_plan["plan_id"],
            "plan_interval": current_plan["interval"],
            "plan_amount_cents": current_plan["amount_cents"],
            "currency": current_plan["currency"],
            "status": "active",
        })
        evt_counter += 1

      # Churn (20% chance)
      elif rand_val < 0.30:
        subscriptions.append({
            "event_id": f"evt_{evt_counter:06d}",
            "event_type": "customer.subscription.deleted",
            "event_timestamp": int(curr_dt.timestamp()),
            "subscription_id": sub_id,
            "customer_id": cust_id,
            "plan_id": current_plan["plan_id"],
            "plan_interval": current_plan["interval"],
            "plan_amount_cents": 0,
            "currency": current_plan["currency"],
            "status": "canceled",
        })
        evt_counter += 1
        is_active = False

  df_customers = pd.DataFrame(customers)
  df_subscriptions = pd.DataFrame(subscriptions)
  df_invoices = pd.DataFrame(invoices)

  return df_customers, df_subscriptions, df_invoices


def seed_to_warehouses(df_customers, df_subscriptions, df_invoices):
  print("Generated 3-Year Dataset (2024-2026):")
  print(f" - Customers: {len(df_customers)}")
  print(f" - Subscription Webhooks/Events: {len(df_subscriptions)}")
  print(f" - Invoices: {len(df_invoices)}")

  # 1. Seed MotherDuck / Local DuckDB
  print("\n[1/2] Ingesting normalized raw tables into MotherDuck ('my_db')...")
  con = duckdb.connect("md:my_db")
  con.execute("CREATE SCHEMA IF NOT EXISTS raw_stripe;")
  con.execute(
      "CREATE OR REPLACE TABLE raw_stripe.customers AS SELECT * FROM"
      " df_customers;"
  )
  con.execute(
      "CREATE OR REPLACE TABLE raw_stripe.subscription_events AS SELECT * FROM"
      " df_subscriptions;"
  )
  con.execute(
      "CREATE OR REPLACE TABLE raw_stripe.invoices AS SELECT * FROM df_invoices;"
  )
  con.close()
  print(
      "✓ Loaded `raw_stripe.customers`, `subscription_events`, `invoices` into"
      " MotherDuck."
  )

  # 2. Seed Google BigQuery
  print(
      "\n[2/2] Ingesting normalized raw tables into BigQuery"
      " ('saas-analytical-pipeline')..."
  )
  bq_client = bigquery.Client(project="saas-analytical-pipeline")
  dataset_ref = bigquery.DatasetReference(
      "saas-analytical-pipeline", "raw_stripe"
  )

  job_config = bigquery.LoadJobConfig(
      write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE
  )

  bq_client.load_table_from_dataframe(
      df_customers, dataset_ref.table("customers"), job_config=job_config
  ).result()
  bq_client.load_table_from_dataframe(
      df_subscriptions,
      dataset_ref.table("subscription_events"),
      job_config=job_config,
  ).result()
  bq_client.load_table_from_dataframe(
      df_invoices, dataset_ref.table("invoices"), job_config=job_config
  ).result()

  print(
      "✓ Loaded `raw_stripe.customers`, `subscription_events`, `invoices` into"
      " BigQuery."
  )


if __name__ == "__main__":
  df_cust, df_sub, df_inv = generate_stripe_normalized_data()
  seed_to_warehouses(df_cust, df_sub, df_inv)