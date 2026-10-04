## Staging Transformations & Field Normalization

### 1. Unix Epoch to UTC Timestamp Conversion
- **Problem:** Stripe raw payloads store temporal attributes (`created_at`, `due_date`, `paid_at`, `event_timestamp`) as Unix epoch timestamps in integer format (`BIGINT`).
- **Standardization:** Converted all raw epoch integers to standard UTC `TIMESTAMP` and `DATE` objects using `{{ dbt_date.from_unixtimestamp(...) }}` for cross-engine compatibility across DuckDB and BigQuery.
- **Naming Convention:** Appended `_utc` to all timestamp attributes (e.g., `created_at_utc`, `event_timestamp_utc`) and `_date` to calendar date truncations (e.g., `event_timestamp_date`).

### 2. Monetary Units Normalization (Cents to Standard Currency)
- **Problem:** Stripe stores raw financial transactions (`subtotal_cents`, `amount_due_cents`, `amount_paid_cents`, `plan_amount_cents`) as integer cents to avoid floating-point rounding errors.
- **Standardization:** Cast integer cents to `NUMERIC` and divided by `100.0` to convert values into standard decimal currency units (e.g., `1050` cents becomes `10.50`).
- **Naming Convention:** Renamed transformed financial fields with `_local` suffixes (e.g., `subtotal_amount_local`, `plan_amount_local`) to preserve distinction prior to intermediate multi-currency FX conversions.

### 3. String Sanitization & ISO Formatting
- **Email Normalization:** Lowercased and trimmed customer email addresses (`lower(trim(cast(email as string)))`) to guarantee clean downstream entity resolution.
- **Currency ISO Codes:** Upper-cased string values for currency attributes (`upper(trim(cast(currency as string)))`) to enforce standardized ISO 4217 uppercase formatting (e.g., `USD`, `EUR`).
- **Identifier Consistency:** Explicitly cast all primary keys, foreign keys, and status strings to standard string types (`string`/`varchar`).## Staging Transformations & Field Normalization

### 1. Unix Epoch to UTC Timestamp Conversion
- **Problem:** Stripe raw payloads store temporal attributes (`created_at`, `due_date`, `paid_at`, `event_timestamp`) as Unix epoch timestamps in integer format (`BIGINT`).
- **Standardization:** Converted all raw epoch integers to standard UTC `TIMESTAMP` and `DATE` objects using `{{ dbt_date.from_unixtimestamp(...) }}` for cross-engine compatibility across DuckDB and BigQuery.
- **Naming Convention:** Appended `_utc` to all timestamp attributes (e.g., `created_at_utc`, `event_timestamp_utc`) and `_date` to calendar date truncations (e.g., `event_timestamp_date`).

### 2. Monetary Units Normalization (Cents to Standard Currency)
- **Problem:** Stripe stores raw financial transactions (`subtotal_cents`, `amount_due_cents`, `amount_paid_cents`, `plan_amount_cents`) as integer cents to avoid floating-point rounding errors.
- **Standardization:** Cast integer cents to `NUMERIC` and divided by `100.0` to convert values into standard decimal currency units (e.g., `1050` cents becomes `10.50`).
- **Naming Convention:** Renamed transformed financial fields with `_local` suffixes (e.g., `subtotal_amount_local`, `plan_amount_local`) to preserve distinction prior to intermediate multi-currency FX conversions.

### 3. String Sanitization & ISO Formatting
- **Email Normalization:** Lowercased and trimmed customer email addresses (`lower(trim(cast(email as string)))`) to guarantee clean downstream entity resolution.
- **Currency ISO Codes:** Upper-cased string values for currency attributes (`upper(trim(cast(currency as string)))`) to enforce standardized ISO 4217 uppercase formatting (e.g., `USD`, `EUR`).
- **Identifier Consistency:** Explicitly cast all primary keys, foreign keys, and status strings to standard string types (`string`/`varchar`)