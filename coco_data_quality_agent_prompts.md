# CoCo Prompts for Simple Snowflake Data Quality Framework

This file is only for prompting Snowflake CoCo / Cortex Data Quality skill.
The synthetic banking dataset is already created separately using:

```text
banking_synthetic_dataset_loading.sql
```

## Target Dataset

Database:

```sql
BANKING_DQ_DB
```

Source schema:

```sql
RAW
```

Tables:

```text
BRANCHES
CUSTOMERS
ACCOUNTS
TRANSACTIONS
LOAN_APPLICATIONS
```

Required DQ framework schema:

```sql
BANKING_DQ_DB.DQ
```

## Version 1 Scope

Keep the framework simple. Do not create circuit breakers, complex RCA views, advanced incident workflows, or too many monitoring layers.

Build only:

1. Rule configuration table
2. Rule execution result table
3. Failed record detail table
4. Stored procedure to execute active rules
5. Snowflake task to orchestrate the checks
6. Simple anomaly checks for row count and transaction amount spikes
7. Streamlit dashboard to visualize DQ results

---

# Prompt 1: Recommend Required Rules Only

```text
I have a Snowflake banking dataset in BANKING_DQ_DB.RAW with these tables:

1. BRANCHES
2. CUSTOMERS
3. ACCOUNTS
4. TRANSACTIONS
5. LOAN_APPLICATIONS

Please recommend a simple and practical set of data quality rules for these tables.

Focus only on rules required for a version 1 data quality framework:
- Not null checks
- Uniqueness checks
- Accepted value checks
- Basic format checks
- Range checks
- Referential integrity checks
- Simple business rule checks
- Simple anomaly checks for row count and amount spikes

Do not include advanced RCA, circuit breakers, SLA alerts, or complex incident management yet.

Return the output as a table with:
- table_name
- column_name
- rule_name
- rule_type
- rule_description
- severity
- suggested_threshold
- example_sql_condition
```

---

# Prompt 2: Create DQ Metadata Tables

```text
Create Snowflake SQL for a simple data quality framework in BANKING_DQ_DB.DQ.

Create only these tables:

1. DQ_RULE_CONFIG
   Stores each DQ rule and whether it is active.

2. DQ_RUN_SUMMARY
   Stores one row per rule execution with pass/fail status, checked record count, failed record count, quality score, execution timestamp and error message.

3. DQ_FAILED_RECORDS
   Stores failed record samples with table name, rule name, primary key value, failed column, failed value, failure reason and run id.

4. DQ_ANOMALY_BASELINE
   Stores baseline metrics such as row count per table and average transaction amount so that later loads can be compared.

Keep the table design simple and easy to understand.
Use BANKING_DQ_DB.DQ schema.
```

---

# Prompt 3: Insert Rule Configuration

```text
Generate INSERT statements for BANKING_DQ_DB.DQ.DQ_RULE_CONFIG for the banking tables in BANKING_DQ_DB.RAW.

Create practical rules for:

BRANCHES:
- BRANCH_ID not null
- BRANCH_ID unique
- BRANCH_NAME not null
- IFSC_CODE format check
- IS_ACTIVE not null

CUSTOMERS:
- CUSTOMER_ID not null
- CUSTOMER_ID unique
- EMAIL not null
- EMAIL format check
- PHONE format check for 10 digits
- DATE_OF_BIRTH should not be in the future
- Customer should be at least 18 years old
- KYC_STATUS accepted values: VERIFIED, PENDING, REJECTED
- RISK_CATEGORY accepted values: LOW, MEDIUM, HIGH
- BRANCH_ID should exist in BRANCHES

ACCOUNTS:
- ACCOUNT_ID not null
- ACCOUNT_ID unique
- CUSTOMER_ID should exist in CUSTOMERS
- BRANCH_ID should exist in BRANCHES
- ACCOUNT_TYPE accepted values: SAVINGS, CURRENT
- ACCOUNT_STATUS accepted values: ACTIVE, DORMANT, CLOSED
- BALANCE should not be negative for SAVINGS accounts
- CURRENCY should be INR

TRANSACTIONS:
- TRANSACTION_ID not null
- TRANSACTION_ID unique
- ACCOUNT_ID should exist in ACCOUNTS
- TRANSACTION_DATE not null
- TRANSACTION_TYPE accepted values: DEBIT, CREDIT
- AMOUNT should be greater than 0
- CHANNEL accepted values: UPI, NEFT, IMPS, CARD, ATM
- TRANSACTION_STATUS accepted values: SUCCESS, FAILED, PENDING
- AMOUNT anomaly check for unusually high transaction amount

LOAN_APPLICATIONS:
- APPLICATION_ID not null
- APPLICATION_ID unique
- CUSTOMER_ID should exist in CUSTOMERS
- BRANCH_ID should exist in BRANCHES
- LOAN_TYPE accepted values: HOME, CAR, PERSONAL, EDUCATION
- REQUESTED_AMOUNT should be greater than 0
- APPROVED_AMOUNT should not be greater than REQUESTED_AMOUNT
- APPLICATION_STATUS accepted values: APPROVED, REJECTED, PENDING
- CREDIT_SCORE should be between 300 and 850
- APPLICATION_DATE should not be in the future

Keep the SQL readable. Each rule should include rule_type, severity, active flag, table name, column name, rule SQL or condition, and rule description.
```

---

# Prompt 4: Create Rule Execution Stored Procedure

```text
Create a Snowflake stored procedure in BANKING_DQ_DB.DQ called RUN_DQ_CHECKS.

The procedure should:

1. Read active rules from BANKING_DQ_DB.DQ.DQ_RULE_CONFIG.
2. Execute each rule against tables in BANKING_DQ_DB.RAW.
3. Insert execution status into BANKING_DQ_DB.DQ.DQ_RUN_SUMMARY.
4. Insert failed record samples into BANKING_DQ_DB.DQ.DQ_FAILED_RECORDS.
5. Calculate quality score as:
   ((checked_record_count - failed_record_count) / checked_record_count) * 100
6. Mark status as PASS if failed_record_count = 0, otherwise FAIL.
7. Handle errors gracefully and log error message in DQ_RUN_SUMMARY.

Keep the procedure simple and easy to explain in a YouTube demo.
Use SQL or JavaScript stored procedure, whichever is easier and reliable in Snowflake.
```

---

# Prompt 5: Create Simple Anomaly Baseline and Anomaly Checks

```text
Create SQL for simple anomaly detection in the same DQ framework.

I need:

1. A procedure to capture baseline metrics in BANKING_DQ_DB.DQ.DQ_ANOMALY_BASELINE.
2. Baseline metrics should include:
   - Row count per table
   - Average transaction amount for TRANSACTIONS
   - Maximum transaction amount for TRANSACTIONS
   - Number of transactions per day
   - Average requested loan amount for LOAN_APPLICATIONS

3. Add anomaly rules that can detect later changes after I load the second insert batch:
   - Sudden row count spike
   - Sudden transaction amount spike
   - Sudden increase in failed records
   - Duplicate ID spike

Keep the anomaly logic simple, threshold-based, and easy to visualize.
For example:
- Current row count > baseline row count * 1.5
- Current average transaction amount > baseline average * 2
- Current max transaction amount > baseline max * 3
```

---

# Prompt 6: Create Snowflake Task Orchestration

```text
Create Snowflake SQL to orchestrate the DQ framework.

I need a simple Snowflake TASK that runs BANKING_DQ_DB.DQ.RUN_DQ_CHECKS on a schedule.

Requirements:
- Use a warehouse variable or placeholder warehouse name.
- Run every 15 minutes for demo purpose.
- Include SQL to suspend and resume the task.
- Include SQL to manually execute the stored procedure.
- Keep it simple.

Do not add alerts or circuit breakers yet.
```

---

# Prompt 7: Create Streamlit Dashboard

```text
Create a Streamlit in Snowflake app for BANKING_DQ_DB.DQ data quality monitoring.

The dashboard should read from:
- BANKING_DQ_DB.DQ.DQ_RUN_SUMMARY
- BANKING_DQ_DB.DQ.DQ_FAILED_RECORDS
- BANKING_DQ_DB.DQ.DQ_RULE_CONFIG
- BANKING_DQ_DB.DQ.DQ_ANOMALY_BASELINE

The dashboard should include:

1. Header: Banking Data Quality Dashboard
2. KPI cards:
   - Overall quality score
   - Total rules executed
   - Passed rules
   - Failed rules
   - Failed records
3. Filters:
   - Run date
   - Table name
   - Rule type
   - Severity
4. Charts:
   - Quality score trend over time
   - Failed rules by table
   - Failed records by rule type
   - Pass vs fail count
   - Top 10 failing rules
5. Detail tables:
   - Latest rule execution summary
   - Failed record samples
6. Simple anomaly section:
   - Show row count spikes
   - Show amount spikes

Keep the UI simple, clean and beginner-friendly.
Use Snowflake Streamlit compatible Python code.
```

---

# Prompt 8: Create Explanation Script for Demo

```text
Create a simple step-by-step explanation script for this data quality framework demo.

The flow is:

1. Create synthetic banking tables and load baseline data.
2. Show that the data intentionally contains a few quality issues.
3. Use CoCo to recommend required DQ rules.
4. Create DQ rule configuration and logging tables.
5. Execute the DQ stored procedure.
6. Review pass/fail results and failed record details.
7. Create Snowflake Task for orchestration.
8. Load second insert batch with anomalies.
9. Run checks again.
10. Show Streamlit dashboard with quality score, failed rules, failed records and anomaly patterns.

Keep the language simple and suitable for a YouTube project walkthrough.
```
