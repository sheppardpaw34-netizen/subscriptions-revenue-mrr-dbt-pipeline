import json
import duckdb

# Read the raw JSON key file content
with open("bigquery-key.json", "r") as f:
    key_content = f.read()

con = duckdb.connect("md:")

con.execute("INSTALL bigquery FROM community;")
con.execute("LOAD bigquery;")

# Pass the JSON string content using f-string parameterization
con.execute(f"""
    CREATE SECRET IF NOT EXISTS bq_auth (
        TYPE BIGQUERY,
        SERVICE_ACCOUNT_JSON '{key_content}'
    );
""")

con.execute("ATTACH 'project=saas-analytical-pipeline' AS bq (TYPE BIGQUERY);")

con.execute("""
    CREATE OR REPLACE TABLE my_db.fct_mrr_waterfall AS 
    SELECT * FROM bq.prod_marts_marts.fct_mrr_waterfall;
""")

print("Successfully synced BigQuery fct_mrr_waterfall into MotherDuck!")