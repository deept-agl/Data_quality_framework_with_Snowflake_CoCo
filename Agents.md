# Snowflake Data Quality Framework using CoCo Data Quality Skill

## Project Goal

Build an end-to-end **Data Quality Framework in Snowflake** that can monitor all important tables across selected schemas, apply data quality rules, log rule execution results, detect anomalies, generate data quality scores, raise alerts, and provide a Streamlit dashboard for detailed visualization.

This framework should use **Snowflake Data Metric Functions (DMFs)**, custom validation logic, anomaly detection, alerting, and orchestration. Snowflake CoCo Data Quality Skill should help generate the SQL, recommend monitors, create reusable framework objects, and support root cause analysis.

---

## Databases, Schemas, and Tables to Monitor

### 1. Incident Management Project

**Database:** `CORTEX_DEMO_DB`  
**Schema:** `DWH_SCHEMA`

Tables:

- `APP_DIM`
- `DATE_DIM`
- `INCIDENT_FACT`
- `OWNER_DIM`
- `PRIORITY_DIM`
- `STATUS_DIM`

### 2. Blinkit Support Project

**Database:** `BLINKIT_SUPPORT_DB`

#### Schema: `RETAIL_DWH`

Tables:

- `DIM_CUSTOMER`
- `DIM_DATE`
- `DIM_PRODUCT`
- `FACT_ORDERS`
- `FACT_ORDER_ITEMS`

#### Schema: `RETAIL_RAW`

Tables:

- `BLINKIT_CUSTOMERS`
- `BLINKIT_ORDERS`
- `BLINKIT_ORDER_ITEMS`
- `BLINKIT_PRODUCTS`

---

# How to Use This Document

Copy each prompt one by one into **Snowflake CoCo** using the **Data Quality Skill**.

The prompts are organized in a practical implementation sequence:

1. Understand and profile the schemas
2. Recommend data quality rules
3. Create framework metadata tables
4. Create standard and custom DMFs
5. Attach DMFs to all tables
6. Create execution logs and result tables
7. Add anomaly detection
8. Create health scoring logic
9. Create alerts and circuit breakers
10. Create orchestration tasks
11. Create Streamlit dashboard
12. Generate final validation and documentation

---

# Prompt 1: Understand the Current Data Model

```text
I want to build an enterprise-style Data Quality Framework in Snowflake.

Please inspect and understand the following databases, schemas, and tables:

1. Database: CORTEX_DEMO_DB
   Schema: DWH_SCHEMA
   Tables:
   - APP_DIM
   - DATE_DIM
   - INCIDENT_FACT
   - OWNER_DIM
   - PRIORITY_DIM
   - STATUS_DIM

2. Database: BLINKIT_SUPPORT_DB
   Schema: RETAIL_DWH
   Tables:
   - DIM_CUSTOMER
   - DIM_DATE
   - DIM_PRODUCT
   - FACT_ORDERS
   - FACT_ORDER_ITEMS

3. Database: BLINKIT_SUPPORT_DB
   Schema: RETAIL_RAW
   Tables:
   - BLINKIT_CUSTOMERS
   - BLINKIT_ORDERS
   - BLINKIT_ORDER_ITEMS
   - BLINKIT_PRODUCTS

For each table, analyze the column names, data types, likely primary keys, foreign keys, date columns, status columns, amount columns, category columns, and important business columns.

Return a table-wise data profiling summary with:
- Table name
- Table purpose
- Key columns
- Candidate primary key
- Candidate foreign keys
- Important numeric columns
- Important date/timestamp columns
- Important categorical columns
- Recommended quality focus areas
```

---

# Prompt 2: Recommend Data Quality Monitors

```text
Based on the tables listed below, recommend the most useful Snowflake Data Metric Functions and custom data quality rules.

Tables to monitor:

CORTEX_DEMO_DB.DWH_SCHEMA:
- APP_DIM
- DATE_DIM
- INCIDENT_FACT
- OWNER_DIM
- PRIORITY_DIM
- STATUS_DIM

BLINKIT_SUPPORT_DB.RETAIL_DWH:
- DIM_CUSTOMER
- DIM_DATE
- DIM_PRODUCT
- FACT_ORDERS
- FACT_ORDER_ITEMS

BLINKIT_SUPPORT_DB.RETAIL_RAW:
- BLINKIT_CUSTOMERS
- BLINKIT_ORDERS
- BLINKIT_ORDER_ITEMS
- BLINKIT_PRODUCTS

For each table, recommend rules under these categories:

1. Completeness checks
   - Null checks on mandatory columns
   - Missing values in business-critical fields

2. Uniqueness checks
   - Duplicate primary keys
   - Duplicate business identifiers

3. Referential integrity checks
   - Fact to dimension relationship checks
   - Orphan records

4. Freshness checks
   - Latest data load timestamp
   - Expected update frequency

5. Volume checks
   - Row count change compared to previous run
   - Unexpected drops or spikes

6. Validity checks
   - Accepted values for status/category columns
   - Email/phone/date format checks where applicable

7. Accuracy and range checks
   - Amount should not be negative
   - Quantity should be greater than zero
   - SLA or duration values should be logical

8. Cross-column checks
   - End date should not be before start date
   - Resolved date should not be before created date
   - Order total should match item level totals where possible

Rank each rule as HIGH, MEDIUM, or LOW priority based on business impact.

Return output in this format:
- Database
- Schema
- Table
- Column(s)
- Rule name
- Rule description
- Rule type
- Suggested DMF or custom SQL
- Priority
- Failure impact
```

---

# Prompt 3: Create a Separate Data Quality Framework Schema

```text
Create a reusable Snowflake Data Quality Framework schema.

Please generate SQL to create the following:

Database:
- Use existing database if suitable, or recommend a new database named DQ_FRAMEWORK_DB

Schema:
- DQ_FRAMEWORK_DB.DQ_MONITORING

Create metadata and logging tables:

1. DQ_TABLE_CONFIG
   Purpose: Store the list of tables to monitor.
   Columns should include:
   - CONFIG_ID
   - DATABASE_NAME
   - SCHEMA_NAME
   - TABLE_NAME
   - TABLE_TYPE
   - BUSINESS_DOMAIN
   - CRITICALITY_LEVEL
   - IS_ACTIVE
   - CREATED_AT
   - UPDATED_AT

2. DQ_RULE_CONFIG
   Purpose: Store all data quality rules.
   Columns should include:
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
   Purpose: Track each execution run.
   Columns should include:
   - RUN_ID
   - RUN_START_TIME
   - RUN_END_TIME
   - RUN_STATUS
   - TRIGGERED_BY
   - ERROR_MESSAGE

4. DQ_RULE_RESULTS
   Purpose: Store rule-level execution results.
   Columns should include:
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
   Purpose: Store detailed failed records or sample failed records.
   Columns should include:
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
   Purpose: Store table-level and schema-level health scores.
   Columns should include:
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
   Purpose: Store anomaly detection results.
   Columns should include:
   - ANOMALY_ID
   - RUN_ID
   - DATABASE_NAME
   - SCHEMA_NAME
   - TABLE_NAME
   - METRIC_NAME
   - CURRENT_VALUE
   - PREVIOUS_VALUE
   - BASELINE_AVG
   - BASELINE_STDDEV
   - ANOMALY_STATUS
   - ANOMALY_REASON
   - DETECTED_AT

Generate complete Snowflake SQL DDL for these objects using best practices.
```

---

# Prompt 4: Insert Table Configuration Metadata

```text
Generate SQL insert statements for DQ_FRAMEWORK_DB.DQ_MONITORING.DQ_TABLE_CONFIG for the following tables:

CORTEX_DEMO_DB.DWH_SCHEMA:
- APP_DIM
- DATE_DIM
- INCIDENT_FACT
- OWNER_DIM
- PRIORITY_DIM
- STATUS_DIM

BLINKIT_SUPPORT_DB.RETAIL_DWH:
- DIM_CUSTOMER
- DIM_DATE
- DIM_PRODUCT
- FACT_ORDERS
- FACT_ORDER_ITEMS

BLINKIT_SUPPORT_DB.RETAIL_RAW:
- BLINKIT_CUSTOMERS
- BLINKIT_ORDERS
- BLINKIT_ORDER_ITEMS
- BLINKIT_PRODUCTS

Use these business domains:
- Incident Management for CORTEX_DEMO_DB tables
- Retail Support Analytics for BLINKIT_SUPPORT_DB.RETAIL_DWH tables
- Retail Raw Ingestion for BLINKIT_SUPPORT_DB.RETAIL_RAW tables

Use criticality levels:
- HIGH for all fact tables and raw transaction tables
- MEDIUM for dimension tables
- LOW for DATE_DIM / DIM_DATE if suitable

Return clean insert SQL.
```

---

# Prompt 5: Create Standard Data Quality Rules

```text
Generate SQL insert statements for DQ_RULE_CONFIG for common data quality rules across all monitored tables.

Rules required:

1. Row count check for every table
   - Rule type: VOLUME
   - Failure if row count = 0
   - Severity: CRITICAL

2. Freshness check for tables having date/timestamp/load columns
   - Rule type: FRESHNESS
   - Failure if data is older than expected threshold
   - Severity: HIGH

3. Primary key null check
   - Rule type: COMPLETENESS
   - Failure if primary key column has null values
   - Severity: CRITICAL

4. Primary key uniqueness check
   - Rule type: UNIQUENESS
   - Failure if duplicate primary keys exist
   - Severity: CRITICAL

5. Mandatory business column null checks
   - Rule type: COMPLETENESS
   - Severity: HIGH or MEDIUM

6. Accepted value checks for status/category columns
   - Rule type: VALIDITY
   - Severity: HIGH

7. Numeric range checks
   - Rule type: ACCURACY
   - Amount columns should be >= 0
   - Quantity columns should be > 0
   - Duration/SLA columns should be >= 0

8. Cross-column date checks
   - Rule type: CONSISTENCY
   - Resolved/closed/end date should not be before created/start date

Use the actual columns available in the tables. If exact column names are unclear, first inspect table metadata from INFORMATION_SCHEMA and then generate rules.

Each rule should have:
- Rule name
- Rule type
- Rule description
- Column name where applicable
- Rule SQL returning failed record count or metric value
- Threshold value
- Severity
- Active flag
```

---

# Prompt 6: Create Custom Data Metric Functions

```text
Create custom Snowflake Data Metric Functions for my Data Quality Framework.

Please generate custom DMFs for these use cases:

1. Null percentage check
   Input: table and column
   Output: percentage of null records

2. Duplicate count check
   Input: table and key column
   Output: duplicate record count

3. Accepted values check
   Input: table, column, allowed values
   Output: invalid record count

4. Numeric range check
   Input: table, column, min value, max value
   Output: invalid record count

5. Date order validation
   Input: table, start date column, end date column
   Output: records where end date is earlier than start date

6. Referential integrity check
   Input: child table, parent table, child key, parent key
   Output: orphan record count

7. Email format validation, if email columns exist
   Input: table and email column
   Output: invalid email count

8. Phone format validation, if phone columns exist
   Input: table and phone column
   Output: invalid phone count

Return Snowflake SQL code to create these custom DMFs or equivalent reusable SQL procedures if DMFs cannot support dynamic table/column parameters directly.

Also explain how each DMF should be attached to the relevant tables.
```

---

# Prompt 7: Attach DMFs to All Tables

```text
Using Snowflake Data Metric Functions, generate SQL to attach relevant DMFs to the monitored tables listed below.

Tables:

CORTEX_DEMO_DB.DWH_SCHEMA:
- APP_DIM
- DATE_DIM
- INCIDENT_FACT
- OWNER_DIM
- PRIORITY_DIM
- STATUS_DIM

BLINKIT_SUPPORT_DB.RETAIL_DWH:
- DIM_CUSTOMER
- DIM_DATE
- DIM_PRODUCT
- FACT_ORDERS
- FACT_ORDER_ITEMS

BLINKIT_SUPPORT_DB.RETAIL_RAW:
- BLINKIT_CUSTOMERS
- BLINKIT_ORDERS
- BLINKIT_ORDER_ITEMS
- BLINKIT_PRODUCTS

Attach rules for:
- Row count
- Freshness
- Null checks
- Duplicate checks
- Accepted values
- Referential integrity
- Range checks
- Cross-column checks

Also generate SQL to set the DMF schedule, preferably daily or hourly depending on table criticality.

Use this scheduling logic:
- HIGH critical tables: hourly
- MEDIUM critical tables: daily
- LOW critical tables: daily

Return complete SQL scripts with comments.
```

---

# Prompt 8: Create Ad-Hoc Assessment Procedure

```text
Create a stored procedure named DQ_FRAMEWORK_DB.DQ_MONITORING.RUN_ADHOC_DQ_ASSESSMENT.

Purpose:
Run a one-time data quality assessment for a given database, schema, and table without requiring DMF setup.

Input parameters:
- DATABASE_NAME
- SCHEMA_NAME
- TABLE_NAME

The procedure should:
1. Inspect the table columns from INFORMATION_SCHEMA.
2. Identify possible key columns, date columns, numeric columns, status/category columns, email/phone columns.
3. Run basic checks:
   - Row count
   - Null count by column
   - Duplicate count for candidate keys
   - Distinct count by categorical columns
   - Min/max for numeric columns
   - Min/max for date columns
   - Freshness check if date/load timestamp column exists
4. Insert results into DQ_RULE_RESULTS.
5. Insert summary into DQ_HEALTH_SCORE.
6. Return a readable summary.

Generate the complete Snowflake SQL or Snowpark Python stored procedure code.
```

---

# Prompt 9: Create Framework Execution Procedure

```text
Create a main stored procedure named DQ_FRAMEWORK_DB.DQ_MONITORING.RUN_DQ_FRAMEWORK.

Purpose:
Execute all active rules from DQ_RULE_CONFIG for all active tables from DQ_TABLE_CONFIG.

The procedure should:
1. Create a new RUN_ID in DQ_RUN_CONTROL.
2. Loop through all active rules.
3. Execute each rule SQL dynamically.
4. Capture actual value, failed record count, total record count, pass percentage, and status.
5. Insert one row per rule into DQ_RULE_RESULTS.
6. Insert sample failed records into DQ_ERROR_RECORDS where applicable.
7. Calculate table-level health score.
8. Calculate schema-level health score.
9. Insert results into DQ_HEALTH_SCORE.
10. Update DQ_RUN_CONTROL as SUCCESS or FAILED.
11. Return final run summary.

Use these result statuses:
- PASSED
- WARNING
- FAILED
- CRITICAL_FAILED

Use these health score bands:
- 95 to 100: EXCELLENT
- 85 to 94: GOOD
- 70 to 84: NEEDS_ATTENTION
- Below 70: POOR

Generate production-ready Snowflake SQL or Snowpark Python stored procedure code.
```

---

# Prompt 10: Add Anomaly Detection

```text
Create anomaly detection logic for my Snowflake Data Quality Framework.

The anomaly detection should monitor:
1. Row count changes
2. Failed record count changes
3. Pass percentage drops
4. Freshness delays
5. Health score drops
6. Sudden increase in null percentage
7. Sudden increase in duplicate count

Use historical data from:
- DQ_RULE_RESULTS
- DQ_HEALTH_SCORE

Create a stored procedure named DQ_FRAMEWORK_DB.DQ_MONITORING.DETECT_DQ_ANOMALIES.

The procedure should:
1. Compare current run metrics with previous runs.
2. Calculate baseline average and standard deviation using last 7 or last 30 runs.
3. Flag anomalies when current value is outside acceptable threshold.
4. Insert anomaly records into DQ_ANOMALY_RESULTS.
5. Return a summary of detected anomalies.

Use simple explainable logic first, such as:
- Row count change > 30 percent compared to baseline
- Health score drop > 10 points compared to previous run
- Failed records increase > 50 percent compared to baseline
- Freshness delay beyond threshold

Generate complete SQL or Snowpark Python procedure code.
```

---

# Prompt 11: Create Root Cause Analysis Views

```text
Create analytical views for root cause analysis on top of the Data Quality Framework tables.

Create the following views:

1. VW_DQ_LATEST_RUN_SUMMARY
   Shows latest run status, total rules, passed rules, failed rules, warning rules, critical failures, and overall health score.

2. VW_DQ_TABLE_HEALTH_LATEST
   Shows latest table-level health score for each monitored table.

3. VW_DQ_SCHEMA_HEALTH_TREND
   Shows schema-level health score trend over time.

4. VW_DQ_RULE_FAILURE_TREND
   Shows rule-level failure trend over time.

5. VW_DQ_TOP_FAILING_TABLES
   Shows tables with the highest number of failed rules.

6. VW_DQ_TOP_FAILING_COLUMNS
   Shows columns with the highest number of failures.

7. VW_DQ_ANOMALY_SUMMARY
   Shows latest anomaly results by table and metric.

8. VW_DQ_COVERAGE_GAPS
   Shows tables that do not have any active rules configured.

9. VW_DQ_RULE_SEVERITY_SUMMARY
   Shows failures grouped by severity.

10. VW_DQ_INCIDENT_INVESTIGATION
   Combines health score, rule results, and anomaly results to help identify why quality dropped.

Generate complete SQL view definitions.
```

---

# Prompt 12: Create SLA Alerts

```text
Create Snowflake ALERT objects for the Data Quality Framework.

Alerts required:

1. Overall health score alert
   Trigger when any schema or table health score is below 85.

2. Critical rule failure alert
   Trigger when any rule with severity CRITICAL fails.

3. Freshness SLA alert
   Trigger when freshness check fails for any HIGH criticality table.

4. Row count anomaly alert
   Trigger when row count anomaly is detected.

5. Repeated failure alert
   Trigger when the same rule fails for 3 consecutive runs.

Each alert should query the DQ framework tables and either:
- Insert alert records into a DQ_ALERT_LOG table, or
- Send notification using Snowflake notification integration if available.

First create a DQ_ALERT_LOG table with:
- ALERT_ID
- ALERT_NAME
- ALERT_TYPE
- DATABASE_NAME
- SCHEMA_NAME
- TABLE_NAME
- RULE_NAME
- SEVERITY
- ALERT_MESSAGE
- ALERT_STATUS
- CREATED_AT

Then generate Snowflake ALERT SQL for each alert.
```

---

# Prompt 13: Create Circuit Breaker Logic

```text
Create circuit breaker logic for the Data Quality Framework.

Purpose:
If a critical data quality rule fails, the downstream pipeline should be stopped or marked as blocked.

Create a table named DQ_PIPELINE_CONTROL with:
- PIPELINE_NAME
- DATABASE_NAME
- SCHEMA_NAME
- TABLE_NAME
- IS_BLOCKED
- BLOCK_REASON
- BLOCKED_AT
- UNBLOCKED_AT
- LAST_RUN_ID

Create a stored procedure named CHECK_DQ_CIRCUIT_BREAKER.

The procedure should:
1. Check latest DQ_RULE_RESULTS.
2. Identify CRITICAL_FAILED rules.
3. Mark related table or pipeline as blocked in DQ_PIPELINE_CONTROL.
4. Return a clear message showing which pipelines are blocked.

Also generate sample SQL that a downstream pipeline can use before execution:
- If table/pipeline is blocked, stop execution.
- If not blocked, continue execution.
```

---

# Prompt 14: Create Orchestration with Snowflake Tasks

```text
Create Snowflake Tasks to orchestrate the complete Data Quality Framework.

The orchestration should follow this flow:

1. TASK_RUN_DQ_FRAMEWORK
   Calls RUN_DQ_FRAMEWORK.

2. TASK_DETECT_DQ_ANOMALIES
   Runs after TASK_RUN_DQ_FRAMEWORK.
   Calls DETECT_DQ_ANOMALIES.

3. TASK_CHECK_DQ_CIRCUIT_BREAKER
   Runs after anomaly detection.
   Calls CHECK_DQ_CIRCUIT_BREAKER.

4. TASK_REFRESH_DQ_DASHBOARD_TABLES
   Optional task to refresh summary tables or materialized dashboard tables.

Schedule:
- Run every 1 hour for HIGH criticality tables.
- Run daily for full framework execution.

Create the tasks using a dedicated warehouse named DQ_MONITORING_WH.

Generate SQL for:
- Warehouse creation
- Task creation
- Task dependency setup
- Resume tasks
- Check task history
- Suspend tasks if needed
```

---

# Prompt 15: Create Streamlit Dashboard in Snowflake

```text
Create a Streamlit in Snowflake dashboard for the Data Quality Framework.

Dashboard name:
DQ_MONITORING_DASHBOARD

Data source tables/views:
- DQ_RULE_RESULTS
- DQ_HEALTH_SCORE
- DQ_ANOMALY_RESULTS
- DQ_ALERT_LOG
- VW_DQ_LATEST_RUN_SUMMARY
- VW_DQ_TABLE_HEALTH_LATEST
- VW_DQ_SCHEMA_HEALTH_TREND
- VW_DQ_RULE_FAILURE_TREND
- VW_DQ_TOP_FAILING_TABLES
- VW_DQ_TOP_FAILING_COLUMNS
- VW_DQ_ANOMALY_SUMMARY
- VW_DQ_COVERAGE_GAPS

Dashboard requirements:

1. Top KPI cards:
   - Overall health score
   - Total monitored tables
   - Total active rules
   - Passed rules
   - Failed rules
   - Critical failures
   - Active anomalies
   - Open alerts

2. Filters:
   - Database
   - Schema
   - Table
   - Rule type
   - Severity
   - Date range

3. Charts:
   - Health score trend over time
   - Table-wise latest health score
   - Rule pass/fail distribution
   - Failures by severity
   - Failures by rule type
   - Top failing tables
   - Top failing columns
   - Anomaly trend
   - Row count trend
   - Freshness trend

4. Detailed tables:
   - Latest failed rules
   - Error sample records
   - Anomaly details
   - Alert log
   - Coverage gaps

5. Drill-down section:
   When a user selects a table, show:
   - Table health trend
   - Failed rules for that table
   - Failed columns
   - Recent anomalies
   - Sample error records
   - Recommended fixes

6. Use clean UI layout:
   - Wide layout
   - Tabs for Overview, Rule Results, Anomalies, Alerts, Coverage, Drill Down
   - Use charts that are easy to explain in a demo video

Generate complete Streamlit Python code using Snowpark session inside Snowflake.
```

---

# Prompt 16: Create Dashboard Summary Tables

```text
Create dashboard-ready summary tables for better Streamlit performance.

Create these tables:

1. DQ_DASHBOARD_KPI_SUMMARY
2. DQ_DASHBOARD_HEALTH_TREND
3. DQ_DASHBOARD_RULE_FAILURE_SUMMARY
4. DQ_DASHBOARD_TABLE_SCORE_SUMMARY
5. DQ_DASHBOARD_ANOMALY_SUMMARY
6. DQ_DASHBOARD_ALERT_SUMMARY

Create a stored procedure named REFRESH_DQ_DASHBOARD_SUMMARY.

The procedure should refresh these tables from the base DQ framework tables and views.

Generate SQL for:
- Table creation
- Refresh procedure
- Optional task to refresh after every DQ run
```

---

# Prompt 17: Create Data Quality Score Calculation Logic

```text
Create a robust data quality health score calculation logic.

The health score should consider:

1. Rule result status
   - Passed rule: full score
   - Warning rule: partial score
   - Failed rule: zero score
   - Critical failed rule: strong penalty

2. Rule severity weight
   - CRITICAL: highest weight
   - HIGH: high weight
   - MEDIUM: medium weight
   - LOW: low weight

3. Rule type weight
   - Completeness, uniqueness, referential integrity, and freshness should have higher impact
   - Low-impact profiling rules should have lower impact

4. Table criticality
   - HIGH criticality tables should impact schema score more
   - MEDIUM and LOW criticality tables should have lower weight

Generate SQL logic to calculate:
- Rule-level weighted score
- Table-level health score
- Schema-level health score
- Database-level health score
- Overall platform health score

Store the output in DQ_HEALTH_SCORE.
```

---

# Prompt 18: Create Table Comparison Feature

```text
Add a table comparison feature to the Data Quality Framework.

Use cases:
- Compare raw vs transformed tables
- Compare dev vs prod tables
- Compare pre-load vs post-load tables
- Compare source vs target tables

Create a stored procedure named COMPARE_TABLES.

Input parameters:
- SOURCE_DATABASE
- SOURCE_SCHEMA
- SOURCE_TABLE
- TARGET_DATABASE
- TARGET_SCHEMA
- TARGET_TABLE
- KEY_COLUMNS

The procedure should compare:
1. Row counts
2. Column counts
3. Schema differences
4. Missing columns
5. Extra columns
6. Data type mismatches
7. Duplicate keys
8. Missing keys in source or target
9. Distribution changes for important numeric columns
10. Sample mismatched records

Create a result table named DQ_TABLE_COMPARISON_RESULTS.

Generate complete SQL or Snowpark Python procedure code.
```

---

# Prompt 19: Create Coverage Gap Analysis

```text
Create coverage gap analysis for the Data Quality Framework.

The analysis should identify:
1. Tables with no rules configured
2. Tables with rules configured but no recent execution
3. Columns with no checks
4. Critical tables without freshness checks
5. Fact tables without referential integrity checks
6. Tables with noisy monitors that fail too often
7. Tables with silent monitors that never fail and may not be useful
8. Cost-heavy DMFs or rules

Create a view named VW_DQ_COVERAGE_AND_MONITOR_EFFECTIVENESS.

Also generate recommendations for each gap.

Return SQL and explanation.
```

---

# Prompt 20: Generate Final End-to-End Deployment Script

```text
Now generate a final end-to-end deployment script for the complete Snowflake Data Quality Framework.

The deployment script should include:

1. Warehouse creation
2. Database and schema creation
3. Metadata table creation
4. Logging table creation
5. Alert log and pipeline control table creation
6. Table configuration inserts
7. Rule configuration inserts
8. Custom DMFs or reusable procedures
9. Main execution procedure
10. Anomaly detection procedure
11. Circuit breaker procedure
12. Dashboard summary refresh procedure
13. Analytical views
14. Alerts
15. Tasks and orchestration
16. Streamlit dashboard creation instructions
17. Validation queries
18. Demo queries

Make the script clean, commented, and executable in Snowflake worksheet step by step.
```

---

# Prompt 21: Generate Demo Script for Video Explanation

```text
Create a simple video explanation script for this Snowflake Data Quality Framework project.

The explanation should be beginner-friendly and sequential.

Cover:
1. What problem this project solves
2. Why data quality monitoring is important
3. Which tables are monitored
4. How rules are configured
5. How DMFs and custom checks work
6. How results are logged
7. How anomaly detection works
8. How health score is calculated
9. How alerts and circuit breakers work
10. How Snowflake Tasks orchestrate the framework
11. How the Streamlit dashboard helps users monitor quality
12. What makes this project useful for real enterprises

Keep the tone simple, clear, and professional.
```

---

# Recommended Framework Architecture

```text
Source / Warehouse Tables
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
Snowflake Alerts + Circuit Breaker
        |
        v
Snowflake Tasks Orchestration
        |
        v
Streamlit DQ Monitoring Dashboard
```

---

# Suggested Dashboard Tabs

## 1. Overview

Shows overall quality posture:

- Overall health score
- Total monitored tables
- Total rules
- Passed / failed rules
- Active anomalies
- Open alerts

## 2. Table Health

Shows table-wise health:

- Latest health score by table
- Health score trend
- Critical tables with quality issues

## 3. Rule Results

Shows rule-level results:

- Rule name
- Rule type
- Table
- Column
- Actual value
- Expected value
- Status
- Severity

## 4. Anomalies

Shows unusual patterns:

- Row count spikes/drops
- Failure spikes
- Freshness delays
- Health score drops

## 5. Alerts

Shows SLA and quality alerts:

- Alert type
- Severity
- Table
- Message
- Status
- Created time

## 6. Coverage Gaps

Shows monitoring gaps:

- Tables without rules
- Critical tables without freshness checks
- Fact tables without RI checks
- Columns without coverage

## 7. Drill Down

Detailed investigation by table:

- Failed checks
- Failed columns
- Error samples
- Root cause indicators
- Suggested fixes

---

# Suggested Data Quality Rules by Project

## Incident Management Tables

### `INCIDENT_FACT`

Recommended checks:

- Incident ID should not be null
- Incident ID should be unique
- App key should exist in `APP_DIM`
- Owner key should exist in `OWNER_DIM`
- Priority key should exist in `PRIORITY_DIM`
- Status key should exist in `STATUS_DIM`
- Created date should exist in `DATE_DIM`
- Resolved date should not be before created date
- Downtime should not be negative
- Resolution hours should not be negative
- SLA breached flag should have accepted values
- Row count should not suddenly drop or spike
- Freshness should be within expected SLA

### Dimension Tables

Recommended checks:

- Dimension key should not be null
- Dimension key should be unique
- Business name columns should not be null
- Status/category values should be valid
- Row count should be greater than zero

---

## Blinkit Retail DWH Tables

### `FACT_ORDERS`

Recommended checks:

- Order ID should not be null
- Order ID should be unique
- Customer key should exist in `DIM_CUSTOMER`
- Order date key should exist in `DIM_DATE`
- Order amount should not be negative
- Order status should be within accepted values
- Order date should not be in the future unless allowed
- Row count should not drop unexpectedly
- Freshness should meet SLA

### `FACT_ORDER_ITEMS`

Recommended checks:

- Order item ID should not be null
- Order item ID should be unique
- Order ID should exist in `FACT_ORDERS`
- Product key should exist in `DIM_PRODUCT`
- Quantity should be greater than zero
- Item price should not be negative
- Item amount should match quantity multiplied by price where applicable
- Duplicate order-product combinations should be reviewed

### Dimension Tables

Recommended checks:

- Customer/product/date keys should not be null
- Customer/product/date keys should be unique
- Product price should not be negative
- Customer contact fields should follow valid format if available
- Category/status values should be accepted

---

## Blinkit Raw Tables

Recommended checks:

- Raw table row count should be greater than zero
- Raw ingestion should be fresh
- Source IDs should not be null
- Duplicate source IDs should be detected
- Mandatory fields should not be null
- Date columns should have valid values
- Amount and quantity columns should be within valid range
- Raw to DWH record counts should be comparable

---

# Final Notes

This framework should be built incrementally:

1. Start with metadata tables and basic rules.
2. Add row count, null, duplicate, and freshness checks first.
3. Add referential integrity and business validations next.
4. Add anomaly detection after historical results are available.
5. Add alerts and circuit breakers after confidence in rules is established.
6. Add Streamlit dashboard for visualization and demo.
7. Tune thresholds based on real results.

