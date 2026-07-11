# Skill: Snowflake Data Quality Framework using CoCo

## Project Goal

Build an enterprise grade end-to-end **Data Quality Framework in Snowflake** that can monitor all important tables across selected schemas, apply data quality rules, log rule execution results, detect anomalies, generate data quality scores and provide a Streamlit dashboard for detailed visualization.

This framework should use **Snowflake Data Metric Functions (DMFs)**, custom validation logic, anomaly detection and orchestration. Snowflake CoCo /data-quality Skill should help generate the SQL, recommend monitors, create reusable framework objects, and support root cause analysis.

---

## Step wise Approach

Read all the steps and perform them sequentially. Confirm before moving to next step. 

Note: Create all scripts in workspace {Data_quality_framework_with_Snowflake_CoCo}

1. DQ_data_profiling.sql: To store all profiling and analysis sqls for source dataset from Step 1
2. DQ_Proposed_Rules.sql: To store all recommended rules and custom functions.
3. DQ_Rules.sql : Stores all the system/ custom DMFs created and rules creation for all tables.
4. DQ_Framework_Config.sql : To store ddls and loading scripts for DQ framework tables.
5. DQ_Orchestration.sql :To store orchestration related scripts for procedures and tasks
6. DQ_cleanup.sql : To store all cleanup sqls to drop/remove all resources after completion.

---

## Step 1: Understand the Current Data Model

I want to build an enterprise-style Data Quality Framework in Snowflake. Please inspect and understand the following databases, schemas, and tables:

### Source Databases, Schemas, and Tables to Monitor (Banking Dataset)

**Database:**
BANKING_DQ_DB

**Schema:**
RAW

**Tables:**
- BRANCHES
- CUSTOMERS
- ACCOUNTS
- TRANSACTIONS
- LOAN_APPLICATIONS

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

And, store all profiling queries and details in DQ_data_profiling.sql file

---

## Step 2: Recommend Data Quality Monitors

Based on the tables in BANKING_DQ_DB.RAW schema, recommend the most useful Snowflake Data Metric Functions and custom data quality rules.
Create both Technical and Business Data Quality Rules across all data quality dimensions for each table.

Rank each rule as HIGH, MEDIUM, or LOW priority based on business impact.
Return output in a tabular manner.

And, store all rules recommendation in DQ_Proposed_Rules.sql file

---

## Step 3: Create and Attach Data Quality Rules

Create all recommended Data Metric Functions and attach them to the tables mentioned in step 1.
And, store all rules and scripts defined in DQ_Rules.sql file

---

## Step 4: Create a Data Quality Framework

- Create a separate schema <BANKING_DQ_DB.DQ_MONITORING> for storing Data Quality Framework related tables and functions.

Create metadata and logging tables:
1. DQ_RULE_CONFIG
- Purpose: Store all data quality rules.
- Columns: 
    - RULE_ID
    - RULE_NAME
    - RULE_TYPE
    - FREQUENCY
    - CRITICALITY
    - DB_NAME (DATABSE.SCHEMA of table)
    - TABLE_NM
    - COLUMN_NM
    - RULE_DESCRIPTION
    - RULE_SQL
    - THRESHOLD_VALUE
    - RULE_DIMENSION (eg: accuracy, completeness)-Keep in json just in case two dimensions encapsulates to one dq rule.
    - IS_ACTIVE
   - CREATED_AT
   - UPDATED_AT

2. DQ_RUN_CONTROL
- Purpose: Track each execution run.
- Columns:
   - RUN_ID
   - RULE_ID
   - RUN_START_TIME
   - RUN_END_TIME
   - RULE_EXEC_RESULT
   - RULE_OUTPUT_VALUE
   - RUN_STATUS
   - TRIGGERED_BY
   - ERROR_MESSAGE
   - CREATED_AT
   - UPDATED_AT

3. DQ_RULE_RESULTS
- Purpose: Store rule-level execution results.
- Columns should include:
   - RESULT_ID
   - RUN_ID
   - RULE_ID
   - DB_NAME (DATABSE.SCHEMA of table)
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

4. DQ_ERROR_RECORDS
- Purpose: Store detailed failed records or sample failed records.
- Columns should include:
   - ERROR_ID
   - RUN_ID
   - RULE_ID
   - DB_NAME (DATABSE.SCHEMA of table)
   - TABLE_NAME
   - ERROR_RECORD_VARIANT
   - ERROR_REASON
   - CREATED_AT

5. DQ_ANOMALY_RESULTS
- Purpose: Store anomaly detection results.
- Columns should include:
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

And, load rules in the DQ_RULE_CONFIG table.
And, store all data quality framework related ddls and scripts in DQ_Framework_Config.sql file

---

## Step 5: Create a stored procedure for orchestration of DQ framework

- Create stored procedure to orchestrate the run of DQ framework which includes rules execution and logging.
- Use resultset and $$ for the stored procedure approach.
And, store the stored procedure definition and declaration in DQ_Orchestration.sql

---
## Step 6: Test Run

- Run the framework through orchestration stored procedure and show the execution summary.

---

## Step 7: Create Streamlit Dashboard in Snowflake

Create an enterprise grade Streamlit app in Snowflake workspace for the Data Quality Framework visualization for all tables for which we applied data quality rules.
Create the file as a streamlit app inside its own .streamlit folder and with other .yml files.

Dashboard name:
DQ_MONITORING_DASHBOARD

Dashboard requirements:

1. Top KPI cards:
   - Overall health score
   - Total monitored tables
   - Total active rules
   - Passed rules
   - Failed rules
   - Critical failures
   - Active anomalies

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
   - Tabs for Overview, Rule Results, Anomalies, Coverage
   - Use charts that are easy to explain in a video

Generate complete Streamlit Python code using streamlit in Snowflake and do not deploy the app. I want to only run and visualize.

---

## Step 8: Cleanup Script

Create a cleanup script to drop all objects created in this setup.
Do not execute anything but store all scripts in a DQ_cleanup.sql file