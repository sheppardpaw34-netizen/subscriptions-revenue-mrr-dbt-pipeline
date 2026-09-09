import io
import json
import random
from datetime import datetime, timedelta, timezone
from google.cloud import bigquery
from google.oauth2 import service_account

# 1. Authenticate using Service Account
KEY_PATH = "bigquery-key.json"
credentials = service_account.Credentials.from_service_account_file(KEY_PATH)
client = bigquery.Client(credentials=credentials, project=credentials.project_id)

DATASET_ID = f"{client.project}.raw_stripe"

# Ensure raw_stripe dataset exists
dataset = bigquery.Dataset(DATASET_ID)
dataset.location = "US"
client.create_dataset(dataset, exists_ok=True)

# 2. Synthetic Data Generators
PLANS = [
    {"id": "plan_starter", "amount": 2900},    # $29/mo
    {"id": "plan_pro", "amount": 9900},        # $99/mo
    {"id": "plan_enterprise", "amount": 29900} # $299/mo
]

TIMEZONES = ["UTC", "America/New_York", "Europe/London", "Asia/Tokyo"]

def generate_stripe_data(num_customers=1000):
    customers = []
    subscriptions = []
    invoices = []
    
    start_time = datetime(2023, 1, 1)
    now_utc = datetime.now(timezone.utc).replace(tzinfo=None)
    
    for i in range(1, num_customers + 1):
        cust_id = f"cus_{i:012x}"
        created_at = start_time + timedelta(days=random.randint(0, 1000))
        
        # Customer entity
        customers.append({
            "id": cust_id,
            "email": f"client_{i}_{random.randint(100,999)}@saas-org.com",
            "created": created_at.strftime("%Y-%m-%d %H:%M:%S UTC"),
            "currency": "usd",
            "timezone": random.choice(TIMEZONES)
        })
        
        # Subscription entity
        plan = random.choice(PLANS)
        sub_id = f"sub_{i:012x}"
        quantity = random.randint(1, 5)
        
        # 30% churn rate simulation
        is_canceled = random.random() < 0.30
        canceled_at = None
        if is_canceled:
            canceled_at_dt = created_at + timedelta(days=random.randint(30, 365))
            canceled_at = canceled_at_dt.strftime("%Y-%m-%d %H:%M:%S UTC")
            status = "canceled"
        else:
            status = "active"
            
        subscriptions.append({
            "id": sub_id,
            "customer_id": cust_id,
            "plan_id": plan["id"],
            "status": status,
            "quantity": quantity,
            "unit_amount": plan["amount"],
            "created": created_at.strftime("%Y-%m-%d %H:%M:%S UTC"),
            "canceled_at": canceled_at
        })
        
        # Invoice entities (Recurring Monthly Billing)
        sub_end_dt = datetime.strptime(canceled_at, "%Y-%m-%d %H:%M:%S UTC") if canceled_at else created_at + timedelta(days=365)
        current_inv_dt = created_at
        inv_count = 1
        
        while current_inv_dt <= sub_end_dt and current_inv_dt <= now_utc:
            inv_id = f"in_{i:06x}_{inv_count:04x}"
            inv_status = "paid"
            
            # 5% failed payment rate (Dunning / Uncollected Debt)
            if random.random() < 0.05:
                inv_status = "open" if random.random() < 0.5 else "uncollectible"
                
            amount_due = plan["amount"] * quantity
            amount_paid = amount_due if inv_status == "paid" else 0
            paid_at = (current_inv_dt + timedelta(hours=2)).strftime("%Y-%m-%d %H:%M:%S UTC") if inv_status == "paid" else None
            
            invoices.append({
                "id": inv_id,
                "customer_id": cust_id,
                "subscription_id": sub_id,
                "status": inv_status,
                "amount_due": amount_due,
                "amount_paid": amount_paid,
                "currency": "usd",
                "created": current_inv_dt.strftime("%Y-%m-%d %H:%M:%S UTC"),
                "paid_at": paid_at
            })
            
            current_inv_dt += timedelta(days=30)
            inv_count += 1

    return customers, subscriptions, invoices

# 3. Load Data to BigQuery
def load_table(table_name, data):
    table_ref = f"{DATASET_ID}.{table_name}"
    job_config = bigquery.LoadJobConfig(
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
        source_format=bigquery.SourceFormat.NEWLINE_DELIMITED_JSON,
        autodetect=True
    )
    
    json_data = "\n".join([json.dumps(row) for row in data])
    job = client.load_table_from_file(
        file_obj=io.BytesIO(json_data.encode("utf-8")),
        destination=table_ref,
        job_config=job_config
    )
    job.result()
    print(f"Loaded {len(data)} rows into {table_ref}")

if __name__ == "__main__":
    print("Generating synthetic Stripe B2B data (Customers, Subscriptions, Invoices)...")
    customers, subscriptions, invoices = generate_stripe_data(1000)
    
    load_table("customers", customers)
    load_table("subscriptions", subscriptions)
    load_table("invoices", invoices)
    print("All datasets successfully loaded into BigQuery!")