import duckdb
import pandas as pd
from seed_bigquery_stripe import generate_stripe_data

print("Connecting to local dev.duckdb...")
con = duckdb.connect("dev.duckdb")

print("Creating raw_stripe schema...")
con.execute("CREATE SCHEMA IF NOT EXISTS raw_stripe;")

print("Generating synthetic Stripe B2B data...")
customers, subscriptions, invoices = generate_stripe_data()

# Convert Python lists to DataFrames so DuckDB can query them
df_customers = pd.DataFrame(customers)
df_subscriptions = pd.DataFrame(subscriptions)
df_invoices = pd.DataFrame(invoices)

print("Writing tables into dev.duckdb...")
con.execute("CREATE OR REPLACE TABLE raw_stripe.customers AS SELECT * FROM df_customers")
con.execute("CREATE OR REPLACE TABLE raw_stripe.subscriptions AS SELECT * FROM df_subscriptions")
con.execute("CREATE OR REPLACE TABLE raw_stripe.invoices AS SELECT * FROM df_invoices")

print("SUCCESS: Local dev.duckdb populated with raw_stripe tables!")