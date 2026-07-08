# Snowflake Data Quality Framework using CoCo Data Quality Skill

## Goal

Build a simple and practical **Data Quality Framework in Snowflake** for a banking dataset.

Framework should focus only on what is required:

1. Profile a small banking dataset
2. Recommend useful data quality rules
3. Store rules in configuration tables
4. Execute rules through a reusable stored procedure
5. Log rule results and failed records
6. Detect simple anomalies after a second data load
7. Orchestrate the framework using Snowflake Tasks
8. Build a Streamlit dashboard to visualize data quality results

---

## Dataset 

Use the banking dataset present in

**Database:** `BANKING_DQ_DB`  
**Schema:** `BANKING_RAW`

Tables:

- `CUSTOMERS`
- `BRANCHES`
- `ACCOUNTS`
- `TRANSACTIONS`
- `LOAN_APPLICATIONS`.

---

## Banking Table Purpose

### 1. `CUSTOMERS`

Stores customer profile information.

Important checks:

- Customer ID should not be null
- Customer ID should be unique
- Customer name should not be null
- Email format should be valid
- Phone number format should be valid
- Date of birth should not be in the future
- KYC status should contain accepted values only

---

### 2. `BRANCHES`

Stores bank branch details.

Important checks:

- Branch ID should not be null
- Branch ID should be unique
- Branch name should not be null
- City should not be null
- Branch status should contain accepted values only

---

### 3. `ACCOUNTS`

Stores bank account information.

Important checks:

- Account ID should not be null
- Account ID should be unique
- Customer ID should exist in `CUSTOMERS`
- Branch ID should exist in `BRANCHES`
- Account type should contain accepted values only
- Account status should contain accepted values only
- Balance should not be negative unless overdraft is allowed
- Open date should not be in the future

---

### 4. `TRANSACTIONS`

Stores account transaction activity.

Important checks:

- Transaction ID should not be null
- Transaction ID should be unique
- Account ID should exist in `ACCOUNTS`
- Transaction amount should be greater than zero
- Transaction type should contain accepted values only
- Transaction status should contain accepted values only
- Transaction date should not be in the future
- Row count should not suddenly drop or spike after the second load

---

### 5. `LOAN_APPLICATIONS`

Stores loan application details.

Important checks:

- Loan application ID should not be null
- Loan application ID should be unique
- Customer ID should exist in `CUSTOMERS`
- Requested loan amount should be greater than zero
- Credit score should be between 300 and 900
- Loan status should contain accepted values only
- Approved amount should not be greater than requested amount
- Application date should not be in the future

---

# How to Use This Document

Copy each prompt one by one into **Snowflake CoCo** using the **Data Quality Skill**.

----

# Prompt 1: Understand and Profile the Banking Dataset

```text
I want to build a simple Data Quality Framework in Snowflake for a banking dataset.

Please inspect and understand the following database, schema, and tables:

Database: BANKING_DQ_DB
Schema: BANKING_RAW
Tables:
- CUSTOMERS
- BRANCHES
- ACCOUNTS
- TRANSACTIONS
- LOAN_APPLICATIONS

For each table, analyze:
- Column names
- Data types
- Likely primary key
- Likely foreign keys
- Mandatory columns
- Date columns
- Numeric amount columns
- Status/category columns
- Columns suitable for null checks
- Columns suitable for duplicate checks
- Columns suitable for accepted value checks
- Columns suitable for range checks
- Columns suitable for referential integrity checks

Return a table-wise profiling summary in this format:
- Table name
- Table purpose
- Key columns
- Candidate primary key
- Candidate foreign keys
- Important numeric columns
- Important date/timestamp columns
- Important categorical columns
- Recommended quality checks
```

---

# Prompt 2: Recommend Data Quality Rules

```text
Based on the banking tables below, recommend data quality rules.

Database: BANKING_DQ_DB
Schema: BANKING_RAW
Tables:
- CUSTOMERS
- BRANCHES
- ACCOUNTS
- TRANSACTIONS
- LOAN_APPLICATIONS

Recommend rules under these categories only:

1. Row count checks
   - Table should not be empty

2. Completeness checks
   - Mandatory columns should not contain null values

3. Uniqueness checks
   - Primary key columns should be unique

4. Referential integrity checks
   - ACCOUNTS.CUSTOMER_ID should exist in CUSTOMERS.CUSTOMER_ID
   - ACCOUNTS.BRANCH_ID should exist in BRANCHES.BRANCH_ID
   - TRANSACTIONS.ACCOUNT_ID should exist in ACCOUNTS.ACCOUNT_ID
   - LOAN_APPLICATIONS.CUSTOMER_ID should exist in CUSTOMERS.CUSTOMER_ID

5. Accepted value checks
   - Status and category columns should contain only expected values

6. Numeric range checks
   - Amounts should be valid
   - Credit score should be in valid range
   - Transaction amount should be greater than zero

7. Date checks
   - Future dates should be flagged where not allowed

8. Cross-column checks
   - Approved amount should not be greater than requested loan amount

9. Simple anomaly checks
   - Row count spike/drop after later data loads
   - Failed record count spike after later data loads
   - Health score drop after later data loads

Rank each rule as CRITICAL, HIGH, MEDIUM, or LOW.

Return output in this format:
- Table name
- Column name
- Rule name
- Rule type
- Rule description
- Suggested SQL logic
- Severity
- Expected failure condition
```

---

# Prompt 3: Create Data Quality Framework Tables

```text
Create a reusable Snowflake Data Quality Framework.

Create the following database and schema:

Database: DQ_FRAMEWORK_DB
Schema: DQ_MONITORING

Create these tables only:

1. DQ_RULE_MASTER
Purpose: Stores all the rule's SQL

1. DQ_TABLE_CONFIG
Purpose: Store the list of tables to monitor.
Columns:
- CONFIG_ID
- DATABASE_NAME
- SCHEMA_NAME
- TABLE_NAME
- BUSINESS_DOMAIN
- CRITICALITY_LEVEL
- IS_ACTIVE
- CREATED_AT
- UPDATED_AT

2. DQ_RULE_CONFIG
Purpose: Store all active data quality rules.
Columns:
- RULE_ID
- CONFIG_ID
- RULE_NAME
- RULE_TYPE
- RULE_DESCRIPTION
- COLUMN_NAME
- RULE_SQL
- THRESHOLD_VALUE
- SEVERITY
- IS_ACTIVE
- CREATED_AT
- UPDATED_AT

3. DQ_RUN_CONTROL
Purpose: Track each data quality framework run.
Columns:
- RUN_ID
- RUN_START_TIME
- RUN_END_TIME
- RUN_STATUS
- TRIGGERED_BY
- ERROR_MESSAGE

4. DQ_RULE_RESULTS
Purpose: Store one result per rule execution.
Columns:
- RESULT_ID
- RUN_ID
- RULE_ID
- DATABASE_NAME
- SCHEMA_NAME
- TABLE_NAME
- COLUMN_NAME
- RULE_NAME
- RULE_TYPE
- EXPECTED_VALUE
- ACTUAL_VALUE
- FAILED_RECORD_COUNT
- TOTAL_RECORD_COUNT
- PASS_PERCENTAGE
- RESULT_STATUS
- SEVERITY
- ERROR_SAMPLE_QUERY
- EXECUTED_AT

5. DQ_ERROR_RECORDS
Purpose: Store sample failed records for investigation.
Columns:
- ERROR_ID
- RUN_ID
- RULE_ID
- DATABASE_NAME
- SCHEMA_NAME
- TABLE_NAME
- ERROR_RECORD_VARIANT
- ERROR_REASON
- CREATED_AT

6. DQ_HEALTH_SCORE
Purpose: Store table-level health scores per run.
Columns:
- SCORE_ID
- RUN_ID
- DATABASE_NAME
- SCHEMA_NAME
- TABLE_NAME
- TOTAL_RULES
- PASSED_RULES
- FAILED_RULES
- WARNING_RULES
- CRITICAL_RULES
- HEALTH_SCORE
- HEALTH_STATUS
- CALCULATED_AT

7. DQ_ANOMALY_RESULTS
Purpose: Store simple anomaly detection results.
Columns:
- ANOMALY_ID
- RUN_ID
- DATABASE_NAME
- SCHEMA_NAME
- TABLE_NAME
- METRIC_NAME
- CURRENT_VALUE
- PREVIOUS_VALUE
- BASELINE_AVG
- ANOMALY_STATUS
- ANOMALY_REASON
- DETECTED_AT

Generate complete Snowflake SQL DDL for these objects.
Keep it simple, readable, and executable in a Snowflake worksheet.
```

---

# Prompt 4: Insert Table Configuration for Banking Tables

```text
Generate SQL insert statements for DQ_FRAMEWORK_DB.DQ_MONITORING.DQ_TABLE_CONFIG for the following banking tables:

Database: BANKING_DQ_DB
Schema: BANKING_RAW
Tables:
- CUSTOMERS
- BRANCHES
- ACCOUNTS
- TRANSACTIONS
- LOAN_APPLICATIONS

Use business domain: Banking

Use criticality levels:
- HIGH for TRANSACTIONS and ACCOUNTS
- MEDIUM for CUSTOMERS and LOAN_APPLICATIONS
- LOW for BRANCHES

Set IS_ACTIVE = TRUE for all tables.

Return clean Snowflake insert SQL.
```

---

# Prompt 5: Insert Version 1 Rule Configuration

```text
Generate SQL insert statements for DQ_FRAMEWORK_DB.DQ_MONITORING.DQ_RULE_CONFIG for the banking dataset.

Use the configured tables from DQ_TABLE_CONFIG.

Create rules for these checks:

CUSTOMERS:
- CUSTOMER_ID is not null
- CUSTOMER_ID is unique
- FULL_NAME is not null
- EMAIL format is valid
- PHONE_NUMBER format is valid
- DATE_OF_BIRTH is not in the future
- KYC_STATUS contains only expected values: VERIFIED, PENDING, REJECTED

BRANCHES:
- BRANCH_ID is not null
- BRANCH_ID is unique
- BRANCH_NAME is not null
- CITY is not null
- BRANCH_STATUS contains only expected values: ACTIVE, INACTIVE

ACCOUNTS:
- ACCOUNT_ID is not null
- ACCOUNT_ID is unique
- CUSTOMER_ID is not null
- CUSTOMER_ID exists in CUSTOMERS
- BRANCH_ID exists in BRANCHES
- ACCOUNT_TYPE contains only expected values: SAVINGS, CURRENT, SALARY, LOAN
- ACCOUNT_STATUS contains only expected values: ACTIVE, DORMANT, CLOSED, FROZEN
- BALANCE is not negative
- OPEN_DATE is not in the future

TRANSACTIONS:
- TRANSACTION_ID is not null
- TRANSACTION_ID is unique
- ACCOUNT_ID is not null
- ACCOUNT_ID exists in ACCOUNTS
- TRANSACTION_AMOUNT is greater than 0
- TRANSACTION_TYPE contains only expected values: CREDIT, DEBIT, TRANSFER, ATM, UPI, CARD
- TRANSACTION_STATUS contains only expected values: SUCCESS, FAILED, PENDING, REVERSED
- TRANSACTION_DATE is not in the future

LOAN_APPLICATIONS:
- LOAN_APPLICATION_ID is not null
- LOAN_APPLICATION_ID is unique
- CUSTOMER_ID is not null
- CUSTOMER_ID exists in CUSTOMERS
- LOAN_TYPE contains only expected values: HOME, PERSONAL, AUTO, EDUCATION, BUSINESS
- REQUESTED_AMOUNT is greater than 0
- APPROVED_AMOUNT is not negative
- APPROVED_AMOUNT should not be greater than REQUESTED_AMOUNT
- CREDIT_SCORE should be between 300 and 900
- APPLICATION_STATUS contains only expected values: SUBMITTED, UNDER_REVIEW, APPROVED, REJECTED, DISBURSED
- APPLICATION_DATE is not in the future

Each RULE_SQL should return failed record count.

Each rule should include:
- Rule name
- Rule type
- Rule description
- Column name
- Rule SQL
- Threshold value
- Severity
- Active flag

Use simple SQL that can be executed dynamically by a stored procedure.
```

---

# Prompt 6: Create Main Rule Execution Procedure

```text
Create a Snowflake stored procedure named DQ_FRAMEWORK_DB.DQ_MONITORING.RUN_DQ_FRAMEWORK.

Purpose:
Execute all active data quality rules from DQ_RULE_CONFIG for all active banking tables from DQ_TABLE_CONFIG.

The procedure should:

1. Create a new RUN_ID in DQ_RUN_CONTROL.
2. Read all active rules from DQ_RULE_CONFIG.
3. Execute each RULE_SQL dynamically.
4. Capture the failed record count.
5. Capture total record count for the table.
6. Calculate pass percentage.
7. Assign result status:
   - PASSED if failed record count = 0
   - FAILED if failed record count > 0
   - CRITICAL_FAILED if failed record count > 0 and severity = CRITICAL
8. Insert one row per rule into DQ_RULE_RESULTS.
9. Insert up to 5 sample failed records into DQ_ERROR_RECORDS if possible.
10. Calculate table-level health score after all rules are executed.
11. Insert table-level score into DQ_HEALTH_SCORE.
12. Update DQ_RUN_CONTROL as SUCCESS or FAILED.
13. Return a readable run summary.

Use simple health score logic:
- Health score = passed rules / total rules * 100

Use health score bands:
- 95 to 100: EXCELLENT
- 85 to 94: GOOD
- 70 to 84: NEEDS_ATTENTION
- Below 70: POOR

Generate complete Snowflake SQL or Snowpark Python stored procedure code.
Keep the procedure simple and easy to explain in a demo video.
```

---

# Prompt 7: Create Simple Anomaly Detection Procedure

```text
Create a simple anomaly detection procedure named DQ_FRAMEWORK_DB.DQ_MONITORING.DETECT_DQ_ANOMALIES.

Purpose:
Detect anomalies after multiple data quality runs are available.

Use historical data from:
- DQ_RULE_RESULTS
- DQ_HEALTH_SCORE

Detect only these Version 1 anomalies:

1. Row count change anomaly
   - Current row count changed by more than 30% compared to previous run

2. Failed record count anomaly
   - Current failed record count increased by more than 50% compared to previous run for the same rule

3. Health score drop anomaly
   - Current table health score dropped by more than 10 points compared to previous run

The procedure should:
1. Find the latest run.
2. Compare latest run with the previous run.
3. Insert detected anomalies into DQ_ANOMALY_RESULTS.
4. Return a summary of detected anomalies.

Keep the logic simple and explainable.
Generate complete Snowflake SQL or Snowpark Python procedure code.
```

---

# Prompt 8: Create Orchestration using Snowflake Tasks

```text
Create Snowflake Tasks to orchestrate Version 1 of the Data Quality Framework.

Create a dedicated warehouse:
- DQ_MONITORING_WH

Create these tasks:

1. TASK_RUN_DQ_FRAMEWORK
   - Calls DQ_FRAMEWORK_DB.DQ_MONITORING.RUN_DQ_FRAMEWORK
   - Runs daily for Version 1

2. TASK_DETECT_DQ_ANOMALIES
   - Runs after TASK_RUN_DQ_FRAMEWORK
   - Calls DQ_FRAMEWORK_DB.DQ_MONITORING.DETECT_DQ_ANOMALIES

Generate SQL for:
- Warehouse creation
- Task creation
- Task dependency setup
- Resume tasks
- Suspend tasks
- Check task history

Keep the orchestration simple.
Do not create alert tasks or circuit breaker tasks in Version 1.
```

---

# Prompt 9: Create Dashboard Views for Streamlit

```text
Create simple dashboard views for the Version 1 Data Quality Framework.

Create these views in DQ_FRAMEWORK_DB.DQ_MONITORING:

1. VW_DQ_LATEST_RUN_SUMMARY
Shows latest run status, total rules, passed rules, failed rules, critical failures, and average health score.

2. VW_DQ_TABLE_HEALTH_LATEST
Shows latest health score for each monitored table.

3. VW_DQ_HEALTH_SCORE_TREND
Shows table health score trend across runs.

4. VW_DQ_RULE_RESULTS_LATEST
Shows latest rule-level results.

5. VW_DQ_FAILURES_BY_RULE_TYPE
Shows failed rules grouped by rule type.

6. VW_DQ_FAILURES_BY_SEVERITY
Shows failed rules grouped by severity.

7. VW_DQ_TOP_FAILING_TABLES
Shows tables with the highest failed rule count.

8. VW_DQ_ANOMALY_SUMMARY
Shows latest anomaly results.

Generate complete SQL view definitions.
Keep the views simple and useful for Streamlit charts.
```

---

# Prompt 10: Create Streamlit Dashboard in Snowflake

```text
Create a Streamlit in Snowflake dashboard for Version 1 of the Data Quality Framework.

Dashboard name:
DQ_MONITORING_DASHBOARD

Use these tables/views:
- DQ_RULE_RESULTS
- DQ_ERROR_RECORDS
- DQ_HEALTH_SCORE
- DQ_ANOMALY_RESULTS
- VW_DQ_LATEST_RUN_SUMMARY
- VW_DQ_TABLE_HEALTH_LATEST
- VW_DQ_HEALTH_SCORE_TREND
- VW_DQ_RULE_RESULTS_LATEST
- VW_DQ_FAILURES_BY_RULE_TYPE
- VW_DQ_FAILURES_BY_SEVERITY
- VW_DQ_TOP_FAILING_TABLES
- VW_DQ_ANOMALY_SUMMARY

Dashboard requirements:

1. Top KPI cards:
   - Latest run status
   - Overall health score
   - Total monitored tables
   - Total rules
   - Passed rules
   - Failed rules
   - Critical failures
   - Active anomalies

2. Filters:
   - Table name
   - Rule type
   - Severity
   - Result status
   - Run date

3. Charts:
   - Health score trend over time
   - Latest health score by table
   - Passed vs failed rule distribution
   - Failures by rule type
   - Failures by severity
   - Top failing tables
   - Anomalies by table

4. Detailed tables:
   - Latest failed rules
   - Sample failed records
   - Anomaly details

5. Drill-down section:
   When a user selects a table, show:
   - Table health trend
   - Failed rules for that table
   - Failed columns
   - Sample error records
   - Recent anomalies

Use a clean and simple UI:
- Wide layout
- Tabs: Overview, Rule Results, Anomalies, Failed Records, Drill Down
- Use Snowpark session inside Snowflake
- Use Plotly or Streamlit native charts

Generate complete Streamlit Python code.
Keep it beginner-friendly and easy to explain in a YouTube demo.
```

---

# Prompt 11: Generate Final Version 1 Deployment Script

```text
Now generate a final end-to-end deployment script for Version 1 of the Snowflake Data Quality Framework.

The deployment script should include:

1. Warehouse creation
2. Database and schema creation
3. Metadata table creation
4. Result and error table creation
5. Table configuration inserts
6. Rule configuration inserts
7. Main rule execution procedure
8. Simple anomaly detection procedure
9. Dashboard views
10. Snowflake Tasks for orchestration
11. Validation queries
12. Demo execution steps

Do not include:
- Circuit breaker logic
- Complex RCA views
- Alerts
- Advanced DMF cost analysis
- Prompt scoring
- Table comparison

Make the script clean, commented, and executable step by step in a Snowflake worksheet.
```

---

# Prompt 12: Generate Simple Demo Explanation Script

```text
Create a simple video explanation script for Version 1 of this Snowflake Data Quality Framework project.

The explanation should be beginner-friendly and sequential.

Cover:

1. What problem this project solves
2. What banking dataset we are using
3. Why synthetic errors were added
4. How table configuration works
5. How rule configuration works
6. How the framework executes rules dynamically
7. How results are logged
8. How failed records are captured
9. How health score is calculated
10. How second data load helps detect anomalies
11. How Snowflake Tasks orchestrate the framework
12. How Streamlit dashboard helps monitor quality
13. What can be added later in Version 2

Keep the tone simple, clear, and professional.
Avoid very advanced terminology.
```

---

# Recommended Version 1 Architecture

```text
Synthetic Banking Tables
        |
        v
DQ_TABLE_CONFIG + DQ_RULE_CONFIG
        |
        v
RUN_DQ_FRAMEWORK Procedure
        |
        +--> DQ_RULE_RESULTS
        +--> DQ_ERROR_RECORDS
        +--> DQ_HEALTH_SCORE
        |
        v
DETECT_DQ_ANOMALIES Procedure
        |
        v
DQ_ANOMALY_RESULTS
        |
        v
Snowflake Tasks
        |
        v
Streamlit DQ Monitoring Dashboard
```

---

# Suggested Dashboard Tabs

## 1. Overview

Shows the overall data quality posture:

- Latest run status
- Overall health score
- Total monitored tables
- Total rules
- Passed rules
- Failed rules
- Critical failures
- Active anomalies

## 2. Rule Results

Shows rule-level results:

- Rule name
- Rule type
- Table name
- Column name
- Failed record count
- Pass percentage
- Result status
- Severity

## 3. Anomalies

Shows unusual changes after the second data load:

- Row count spikes or drops
- Failed record count spikes
- Health score drops

## 4. Failed Records

Shows sample failed records:

- Table name
- Rule name
- Error reason
- Failed record sample
- Created timestamp

## 5. Drill Down

Allows table-level investigation:

- Table health trend
- Failed checks
- Failed columns
- Sample failed records
- Recent anomalies

---

# Version 2 Ideas for Later

After Version 1 is working, add advanced features step by step:

- Snowflake DMFs
- SLA alerts
- Email or notification integration
- Circuit breaker logic
- Root cause analysis views
- Coverage gap analysis
- Table comparison
- Dev vs prod comparison
- Prompt quality checks
- Rule recommendation automation
- Cost monitoring for DQ checks

---

# Final Note

Keep Version 1 simple.

First make sure the framework can:

1. Run rules
2. Log results
3. Show failures
4. Calculate health score
5. Detect anomalies after the second data load
6. Display everything clearly in Streamlit

Once this is working end to end, Version 2 can add enterprise-grade enhancements.
