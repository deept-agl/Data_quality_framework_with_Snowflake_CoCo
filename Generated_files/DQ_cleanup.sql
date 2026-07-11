-- Cleanup script to drop all DQ framework objects created during this setup
-- Co-authored with CoCo

-- ============================================================================
-- STEP 8: CLEANUP - DROP ALL RESOURCES
-- ============================================================================
-- WARNING: This script will permanently remove all DQ framework objects.
-- DO NOT execute unless you want to completely tear down the framework.
-- ============================================================================

-- ============================================================================
-- 1. Remove DMF associations from tables (must be done before dropping DMFs)
-- ============================================================================

-- BRANCHES: Remove all DMFs
ALTER TABLE BANKING_DQ_DB.RAW.BRANCHES
  DROP DATA METRIC FUNCTION
    SNOWFLAKE.CORE.NULL_COUNT ON (BRANCH_ID),
    SNOWFLAKE.CORE.NULL_COUNT ON (BRANCH_NAME),
    SNOWFLAKE.CORE.NULL_COUNT ON (IFSC_CODE),
    SNOWFLAKE.CORE.DUPLICATE_COUNT ON (BRANCH_ID),
    SNOWFLAKE.CORE.DUPLICATE_COUNT ON (IFSC_CODE),
    SNOWFLAKE.CORE.ROW_COUNT ON (),
    BANKING_DQ_DB.RAW.DQ_IFSC_FORMAT_CHECK ON (IFSC_CODE);

-- CUSTOMERS: Remove all DMFs
ALTER TABLE BANKING_DQ_DB.RAW.CUSTOMERS
  DROP DATA METRIC FUNCTION
    SNOWFLAKE.CORE.NULL_COUNT ON (CUSTOMER_ID),
    SNOWFLAKE.CORE.NULL_COUNT ON (FIRST_NAME),
    SNOWFLAKE.CORE.NULL_COUNT ON (EMAIL),
    SNOWFLAKE.CORE.DUPLICATE_COUNT ON (CUSTOMER_ID),
    SNOWFLAKE.CORE.DUPLICATE_COUNT ON (EMAIL),
    SNOWFLAKE.CORE.ROW_COUNT ON (),
    BANKING_DQ_DB.RAW.DQ_EMAIL_FORMAT_CHECK ON (EMAIL),
    BANKING_DQ_DB.RAW.DQ_PHONE_FORMAT_CHECK ON (PHONE),
    BANKING_DQ_DB.RAW.DQ_FUTURE_DATE_CHECK ON (DATE_OF_BIRTH);

-- ACCOUNTS: Remove all DMFs
ALTER TABLE BANKING_DQ_DB.RAW.ACCOUNTS
  DROP DATA METRIC FUNCTION
    SNOWFLAKE.CORE.NULL_COUNT ON (ACCOUNT_ID),
    SNOWFLAKE.CORE.NULL_COUNT ON (CUSTOMER_ID),
    SNOWFLAKE.CORE.NULL_COUNT ON (BALANCE),
    SNOWFLAKE.CORE.DUPLICATE_COUNT ON (ACCOUNT_ID),
    SNOWFLAKE.CORE.ROW_COUNT ON (),
    BANKING_DQ_DB.RAW.DQ_NON_NEGATIVE_BALANCE_CHECK ON (BALANCE);

-- TRANSACTIONS: Remove all DMFs
ALTER TABLE BANKING_DQ_DB.RAW.TRANSACTIONS
  DROP DATA METRIC FUNCTION
    SNOWFLAKE.CORE.NULL_COUNT ON (TRANSACTION_ID),
    SNOWFLAKE.CORE.NULL_COUNT ON (ACCOUNT_ID),
    SNOWFLAKE.CORE.NULL_COUNT ON (AMOUNT),
    SNOWFLAKE.CORE.DUPLICATE_COUNT ON (TRANSACTION_ID),
    SNOWFLAKE.CORE.ROW_COUNT ON (),
    BANKING_DQ_DB.RAW.DQ_POSITIVE_AMOUNT_CHECK ON (AMOUNT);

-- LOAN_APPLICATIONS: Remove all DMFs
ALTER TABLE BANKING_DQ_DB.RAW.LOAN_APPLICATIONS
  DROP DATA METRIC FUNCTION
    SNOWFLAKE.CORE.NULL_COUNT ON (APPLICATION_ID),
    SNOWFLAKE.CORE.NULL_COUNT ON (CUSTOMER_ID),
    SNOWFLAKE.CORE.NULL_COUNT ON (REQUESTED_AMOUNT),
    SNOWFLAKE.CORE.DUPLICATE_COUNT ON (APPLICATION_ID),
    SNOWFLAKE.CORE.ROW_COUNT ON (),
    BANKING_DQ_DB.RAW.DQ_POSITIVE_AMOUNT_CHECK ON (REQUESTED_AMOUNT),
    BANKING_DQ_DB.RAW.DQ_CREDIT_SCORE_RANGE_CHECK ON (CREDIT_SCORE),
    BANKING_DQ_DB.RAW.DQ_FUTURE_DATE_CHECK ON (APPLICATION_DATE),
    BANKING_DQ_DB.RAW.DQ_APPROVED_LTE_REQUESTED ON (APPROVED_AMOUNT, REQUESTED_AMOUNT);

-- ============================================================================
-- 2. Drop custom Data Metric Functions
-- ============================================================================

DROP DATA METRIC FUNCTION IF EXISTS BANKING_DQ_DB.RAW.DQ_EMAIL_FORMAT_CHECK(TABLE(VARCHAR));
DROP DATA METRIC FUNCTION IF EXISTS BANKING_DQ_DB.RAW.DQ_PHONE_FORMAT_CHECK(TABLE(VARCHAR));
DROP DATA METRIC FUNCTION IF EXISTS BANKING_DQ_DB.RAW.DQ_IFSC_FORMAT_CHECK(TABLE(VARCHAR));
DROP DATA METRIC FUNCTION IF EXISTS BANKING_DQ_DB.RAW.DQ_POSITIVE_AMOUNT_CHECK(TABLE(NUMBER));
DROP DATA METRIC FUNCTION IF EXISTS BANKING_DQ_DB.RAW.DQ_NON_NEGATIVE_BALANCE_CHECK(TABLE(NUMBER));
DROP DATA METRIC FUNCTION IF EXISTS BANKING_DQ_DB.RAW.DQ_CREDIT_SCORE_RANGE_CHECK(TABLE(NUMBER));
DROP DATA METRIC FUNCTION IF EXISTS BANKING_DQ_DB.RAW.DQ_FUTURE_DATE_CHECK(TABLE(DATE));
DROP DATA METRIC FUNCTION IF EXISTS BANKING_DQ_DB.RAW.DQ_APPROVED_LTE_REQUESTED(TABLE(NUMBER, NUMBER));

-- ============================================================================
-- 3. Drop stored procedure
-- ============================================================================

DROP PROCEDURE IF EXISTS BANKING_DQ_DB.DQ_MONITORING.SP_RUN_DQ_FRAMEWORK(VARCHAR);

-- ============================================================================
-- 4. Drop DQ Monitoring framework tables
-- ============================================================================

DROP TABLE IF EXISTS BANKING_DQ_DB.DQ_MONITORING.DQ_RULE_CONFIG;
DROP TABLE IF EXISTS BANKING_DQ_DB.DQ_MONITORING.DQ_RUN_CONTROL;
DROP TABLE IF EXISTS BANKING_DQ_DB.DQ_MONITORING.DQ_RULE_RESULTS;
DROP TABLE IF EXISTS BANKING_DQ_DB.DQ_MONITORING.DQ_ERROR_RECORDS;
DROP TABLE IF EXISTS BANKING_DQ_DB.DQ_MONITORING.DQ_ANOMALY_RESULTS;

-- ============================================================================
-- 5. Drop DQ Monitoring schema
-- ============================================================================

DROP SCHEMA IF EXISTS BANKING_DQ_DB.DQ_MONITORING;

-- ============================================================================
-- 6. Drop source tables and schema (optional - uncomment if needed)
-- ============================================================================

-- DROP TABLE IF EXISTS BANKING_DQ_DB.RAW.BRANCHES;
-- DROP TABLE IF EXISTS BANKING_DQ_DB.RAW.CUSTOMERS;
-- DROP TABLE IF EXISTS BANKING_DQ_DB.RAW.ACCOUNTS;
-- DROP TABLE IF EXISTS BANKING_DQ_DB.RAW.TRANSACTIONS;
-- DROP TABLE IF EXISTS BANKING_DQ_DB.RAW.LOAN_APPLICATIONS;
-- DROP SCHEMA IF EXISTS BANKING_DQ_DB.RAW;

-- ============================================================================
-- 7. Drop database (optional - uncomment if needed)
-- ============================================================================

-- DROP DATABASE IF EXISTS BANKING_DQ_DB;

-- ============================================================================
-- CLEANUP COMPLETE
-- ============================================================================
-- Objects removed:
--   - 37 DMF associations (across 5 tables)
--   - 8 custom Data Metric Functions
--   - 1 stored procedure (SP_RUN_DQ_FRAMEWORK)
--   - 5 framework tables (DQ_RULE_CONFIG, DQ_RUN_CONTROL, DQ_RULE_RESULTS,
--                          DQ_ERROR_RECORDS, DQ_ANOMALY_RESULTS)
--   - 1 schema (DQ_MONITORING)
--   - Source tables and database are commented out (manual opt-in)
-- ============================================================================
