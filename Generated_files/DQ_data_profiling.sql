-- Data profiling and analysis queries for BANKING_DQ_DB.RAW schema
-- Co-authored with CoCo

-- ============================================================================
-- STEP 1: DATA PROFILING - BANKING_DQ_DB.RAW
-- ============================================================================

-- 1.1 List all tables in the schema
SHOW TABLES IN BANKING_DQ_DB.RAW;

-- 1.2 Get column metadata for all tables
SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE, IS_NULLABLE, COLUMN_DEFAULT, ORDINAL_POSITION
FROM BANKING_DQ_DB.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'RAW'
ORDER BY TABLE_NAME, ORDINAL_POSITION;

-- ============================================================================
-- TABLE: BRANCHES
-- Purpose: Reference/dimension table for bank branches
-- Primary Key: BRANCH_ID
-- Foreign Keys: None (root table)
-- Important Columns: IFSC_CODE (format validation), IS_ACTIVE (status)
-- Date Columns: CREATED_AT
-- Categorical Columns: CITY, STATE, IS_ACTIVE
-- Quality Focus: IFSC format, NULL branch names, uniqueness
-- ============================================================================

-- 1.3a BRANCHES - Row count and basic stats
SELECT 
    'BRANCHES' AS TABLE_NAME,
    COUNT(*) AS ROW_COUNT,
    COUNT(DISTINCT BRANCH_ID) AS DISTINCT_BRANCH_IDS,
    COUNT(*) - COUNT(BRANCH_NAME) AS NULL_BRANCH_NAMES,
    COUNT(*) - COUNT(IFSC_CODE) AS NULL_IFSC_CODES,
    COUNT(DISTINCT CITY) AS DISTINCT_CITIES,
    COUNT(DISTINCT STATE) AS DISTINCT_STATES
FROM BANKING_DQ_DB.RAW.BRANCHES;

-- 1.3b BRANCHES - IFSC code format validation (expected: 4 letters + 7 alphanumeric)
SELECT BRANCH_ID, IFSC_CODE, 
    CASE WHEN IFSC_CODE RLIKE '^[A-Z]{4}[0-9]{7}$' THEN 'VALID' ELSE 'INVALID' END AS IFSC_VALIDITY
FROM BANKING_DQ_DB.RAW.BRANCHES;

-- 1.3c BRANCHES - NULL analysis
SELECT 
    COUNT(*) - COUNT(BRANCH_ID) AS NULL_BRANCH_ID,
    COUNT(*) - COUNT(BRANCH_NAME) AS NULL_BRANCH_NAME,
    COUNT(*) - COUNT(CITY) AS NULL_CITY,
    COUNT(*) - COUNT(STATE) AS NULL_STATE,
    COUNT(*) - COUNT(IFSC_CODE) AS NULL_IFSC_CODE,
    COUNT(*) - COUNT(IS_ACTIVE) AS NULL_IS_ACTIVE,
    COUNT(*) - COUNT(CREATED_AT) AS NULL_CREATED_AT
FROM BANKING_DQ_DB.RAW.BRANCHES;

-- ============================================================================
-- TABLE: CUSTOMERS
-- Purpose: Customer master data with KYC and risk information
-- Primary Key: CUSTOMER_ID
-- Foreign Keys: BRANCH_ID → BRANCHES.BRANCH_ID
-- Important Numeric Columns: None
-- Date Columns: DATE_OF_BIRTH, CREATED_AT
-- Categorical Columns: KYC_STATUS, RISK_CATEGORY
-- Quality Focus: Email format, phone length, DOB validity, KYC values, FK integrity
-- ============================================================================

-- 1.4a CUSTOMERS - Row count and basic stats
SELECT 
    'CUSTOMERS' AS TABLE_NAME,
    COUNT(*) AS ROW_COUNT,
    COUNT(DISTINCT CUSTOMER_ID) AS DISTINCT_CUSTOMER_IDS,
    COUNT(DISTINCT BRANCH_ID) AS DISTINCT_BRANCH_IDS,
    COUNT(DISTINCT KYC_STATUS) AS DISTINCT_KYC_STATUSES,
    COUNT(DISTINCT RISK_CATEGORY) AS DISTINCT_RISK_CATEGORIES
FROM BANKING_DQ_DB.RAW.CUSTOMERS;

-- 1.4b CUSTOMERS - Email format validation
SELECT CUSTOMER_ID, EMAIL,
    CASE WHEN EMAIL RLIKE '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$' THEN 'VALID' ELSE 'INVALID' END AS EMAIL_VALIDITY
FROM BANKING_DQ_DB.RAW.CUSTOMERS;

-- 1.4c CUSTOMERS - Phone number validation (expected 10 digits)
SELECT CUSTOMER_ID, PHONE,
    CASE WHEN PHONE RLIKE '^[0-9]{10}$' THEN 'VALID' ELSE 'INVALID' END AS PHONE_VALIDITY
FROM BANKING_DQ_DB.RAW.CUSTOMERS;

-- 1.4d CUSTOMERS - Date of birth validation (not in future, age > 18)
SELECT CUSTOMER_ID, DATE_OF_BIRTH,
    CASE 
        WHEN DATE_OF_BIRTH > CURRENT_DATE() THEN 'FUTURE_DOB'
        WHEN DATEDIFF('YEAR', DATE_OF_BIRTH, CURRENT_DATE()) < 18 THEN 'UNDERAGE'
        ELSE 'VALID'
    END AS DOB_VALIDITY
FROM BANKING_DQ_DB.RAW.CUSTOMERS;

-- 1.4e CUSTOMERS - KYC status distribution
SELECT KYC_STATUS, COUNT(*) AS CNT
FROM BANKING_DQ_DB.RAW.CUSTOMERS
GROUP BY KYC_STATUS;

-- 1.4f CUSTOMERS - Referential integrity check (BRANCH_ID)
SELECT C.CUSTOMER_ID, C.BRANCH_ID
FROM BANKING_DQ_DB.RAW.CUSTOMERS C
LEFT JOIN BANKING_DQ_DB.RAW.BRANCHES B ON C.BRANCH_ID = B.BRANCH_ID
WHERE B.BRANCH_ID IS NULL;

-- ============================================================================
-- TABLE: ACCOUNTS
-- Purpose: Bank accounts linked to customers and branches
-- Primary Key: ACCOUNT_ID
-- Foreign Keys: CUSTOMER_ID → CUSTOMERS.CUSTOMER_ID, BRANCH_ID → BRANCHES.BRANCH_ID
-- Important Numeric Columns: BALANCE
-- Date Columns: OPEN_DATE, CREATED_AT
-- Categorical Columns: ACCOUNT_TYPE, ACCOUNT_STATUS, CURRENCY
-- Quality Focus: Negative balance, FK integrity, valid status/type, currency consistency
-- ============================================================================

-- 1.5a ACCOUNTS - Row count and basic stats
SELECT 
    'ACCOUNTS' AS TABLE_NAME,
    COUNT(*) AS ROW_COUNT,
    COUNT(DISTINCT ACCOUNT_ID) AS DISTINCT_ACCOUNT_IDS,
    COUNT(DISTINCT CUSTOMER_ID) AS DISTINCT_CUSTOMER_IDS,
    MIN(BALANCE) AS MIN_BALANCE,
    MAX(BALANCE) AS MAX_BALANCE,
    AVG(BALANCE) AS AVG_BALANCE,
    COUNT(CASE WHEN BALANCE < 0 THEN 1 END) AS NEGATIVE_BALANCE_COUNT
FROM BANKING_DQ_DB.RAW.ACCOUNTS;

-- 1.5b ACCOUNTS - Account type and status distribution
SELECT ACCOUNT_TYPE, ACCOUNT_STATUS, COUNT(*) AS CNT
FROM BANKING_DQ_DB.RAW.ACCOUNTS
GROUP BY ACCOUNT_TYPE, ACCOUNT_STATUS;

-- 1.5c ACCOUNTS - Currency distribution (expect all INR for domestic bank)
SELECT CURRENCY, COUNT(*) AS CNT
FROM BANKING_DQ_DB.RAW.ACCOUNTS
GROUP BY CURRENCY;

-- 1.5d ACCOUNTS - Referential integrity check (CUSTOMER_ID)
SELECT A.ACCOUNT_ID, A.CUSTOMER_ID
FROM BANKING_DQ_DB.RAW.ACCOUNTS A
LEFT JOIN BANKING_DQ_DB.RAW.CUSTOMERS C ON A.CUSTOMER_ID = C.CUSTOMER_ID
WHERE C.CUSTOMER_ID IS NULL;

-- 1.5e ACCOUNTS - Referential integrity check (BRANCH_ID)
SELECT A.ACCOUNT_ID, A.BRANCH_ID
FROM BANKING_DQ_DB.RAW.ACCOUNTS A
LEFT JOIN BANKING_DQ_DB.RAW.BRANCHES B ON A.BRANCH_ID = B.BRANCH_ID
WHERE B.BRANCH_ID IS NULL;

-- ============================================================================
-- TABLE: TRANSACTIONS
-- Purpose: Financial transaction records
-- Primary Key: TRANSACTION_ID
-- Foreign Keys: ACCOUNT_ID → ACCOUNTS.ACCOUNT_ID
-- Important Numeric Columns: AMOUNT
-- Date Columns: TRANSACTION_DATE, CREATED_AT
-- Categorical Columns: TRANSACTION_TYPE, CHANNEL, MERCHANT_CATEGORY, TRANSACTION_STATUS
-- Quality Focus: Negative amounts, FK integrity, valid types/status, future dates
-- ============================================================================

-- 1.6a TRANSACTIONS - Row count and basic stats
SELECT 
    'TRANSACTIONS' AS TABLE_NAME,
    COUNT(*) AS ROW_COUNT,
    COUNT(DISTINCT TRANSACTION_ID) AS DISTINCT_TXN_IDS,
    COUNT(DISTINCT ACCOUNT_ID) AS DISTINCT_ACCOUNT_IDS,
    MIN(AMOUNT) AS MIN_AMOUNT,
    MAX(AMOUNT) AS MAX_AMOUNT,
    AVG(AMOUNT) AS AVG_AMOUNT,
    COUNT(CASE WHEN AMOUNT < 0 THEN 1 END) AS NEGATIVE_AMOUNT_COUNT
FROM BANKING_DQ_DB.RAW.TRANSACTIONS;

-- 1.6b TRANSACTIONS - Type and status distribution
SELECT TRANSACTION_TYPE, TRANSACTION_STATUS, COUNT(*) AS CNT
FROM BANKING_DQ_DB.RAW.TRANSACTIONS
GROUP BY TRANSACTION_TYPE, TRANSACTION_STATUS;

-- 1.6c TRANSACTIONS - Channel distribution
SELECT CHANNEL, COUNT(*) AS CNT
FROM BANKING_DQ_DB.RAW.TRANSACTIONS
GROUP BY CHANNEL;

-- 1.6d TRANSACTIONS - Referential integrity check (ACCOUNT_ID)
SELECT T.TRANSACTION_ID, T.ACCOUNT_ID
FROM BANKING_DQ_DB.RAW.TRANSACTIONS T
LEFT JOIN BANKING_DQ_DB.RAW.ACCOUNTS A ON T.ACCOUNT_ID = A.ACCOUNT_ID
WHERE A.ACCOUNT_ID IS NULL;

-- 1.6e TRANSACTIONS - Future date check
SELECT TRANSACTION_ID, TRANSACTION_DATE
FROM BANKING_DQ_DB.RAW.TRANSACTIONS
WHERE TRANSACTION_DATE > CURRENT_TIMESTAMP();

-- ============================================================================
-- TABLE: LOAN_APPLICATIONS
-- Purpose: Loan application records with approval workflow
-- Primary Key: APPLICATION_ID
-- Foreign Keys: CUSTOMER_ID → CUSTOMERS.CUSTOMER_ID, BRANCH_ID → BRANCHES.BRANCH_ID
-- Important Numeric Columns: REQUESTED_AMOUNT, APPROVED_AMOUNT, CREDIT_SCORE
-- Date Columns: APPLICATION_DATE, CREATED_AT
-- Categorical Columns: LOAN_TYPE, APPLICATION_STATUS
-- Quality Focus: Approved > Requested, zero amounts, FK integrity, future dates, credit score range
-- ============================================================================

-- 1.7a LOAN_APPLICATIONS - Row count and basic stats
SELECT 
    'LOAN_APPLICATIONS' AS TABLE_NAME,
    COUNT(*) AS ROW_COUNT,
    COUNT(DISTINCT APPLICATION_ID) AS DISTINCT_APP_IDS,
    MIN(REQUESTED_AMOUNT) AS MIN_REQUESTED,
    MAX(REQUESTED_AMOUNT) AS MAX_REQUESTED,
    MIN(CREDIT_SCORE) AS MIN_CREDIT_SCORE,
    MAX(CREDIT_SCORE) AS MAX_CREDIT_SCORE,
    COUNT(CASE WHEN REQUESTED_AMOUNT = 0 THEN 1 END) AS ZERO_AMOUNT_COUNT,
    COUNT(CASE WHEN APPROVED_AMOUNT > REQUESTED_AMOUNT THEN 1 END) AS APPROVED_GT_REQUESTED
FROM BANKING_DQ_DB.RAW.LOAN_APPLICATIONS;

-- 1.7b LOAN_APPLICATIONS - Status distribution
SELECT APPLICATION_STATUS, COUNT(*) AS CNT
FROM BANKING_DQ_DB.RAW.LOAN_APPLICATIONS
GROUP BY APPLICATION_STATUS;

-- 1.7c LOAN_APPLICATIONS - Loan type distribution
SELECT LOAN_TYPE, COUNT(*) AS CNT
FROM BANKING_DQ_DB.RAW.LOAN_APPLICATIONS
GROUP BY LOAN_TYPE;

-- 1.7d LOAN_APPLICATIONS - Credit score range validation (300-850)
SELECT APPLICATION_ID, CREDIT_SCORE,
    CASE 
        WHEN CREDIT_SCORE < 300 THEN 'TOO_LOW'
        WHEN CREDIT_SCORE > 850 THEN 'TOO_HIGH'
        ELSE 'VALID'
    END AS SCORE_VALIDITY
FROM BANKING_DQ_DB.RAW.LOAN_APPLICATIONS;

-- 1.7e LOAN_APPLICATIONS - Future application date check
SELECT APPLICATION_ID, APPLICATION_DATE
FROM BANKING_DQ_DB.RAW.LOAN_APPLICATIONS
WHERE APPLICATION_DATE > CURRENT_DATE();

-- 1.7f LOAN_APPLICATIONS - Referential integrity (CUSTOMER_ID)
SELECT L.APPLICATION_ID, L.CUSTOMER_ID
FROM BANKING_DQ_DB.RAW.LOAN_APPLICATIONS L
LEFT JOIN BANKING_DQ_DB.RAW.CUSTOMERS C ON L.CUSTOMER_ID = C.CUSTOMER_ID
WHERE C.CUSTOMER_ID IS NULL;

-- 1.7g LOAN_APPLICATIONS - Referential integrity (BRANCH_ID)
SELECT L.APPLICATION_ID, L.BRANCH_ID
FROM BANKING_DQ_DB.RAW.LOAN_APPLICATIONS L
LEFT JOIN BANKING_DQ_DB.RAW.BRANCHES B ON L.BRANCH_ID = B.BRANCH_ID
WHERE B.BRANCH_ID IS NULL;

-- ============================================================================
-- SUMMARY: DATA PROFILING FINDINGS
-- ============================================================================
-- 
-- TABLE           | PK              | FKs                        | KEY ISSUES FOUND
-- ----------------+-----------------+----------------------------+----------------------------------
-- BRANCHES        | BRANCH_ID       | None                       | Invalid IFSC (B006), NULL name (B007)
-- CUSTOMERS       | CUSTOMER_ID     | BRANCH_ID→BRANCHES         | Invalid email (C006), short phone (C007), 
--                 |                 |                            | future DOB (C008), invalid KYC (C009), 
--                 |                 |                            | orphan FK (C010→B999)
-- ACCOUNTS        | ACCOUNT_ID      | CUSTOMER_ID→CUSTOMERS,     | Negative balance (A008), orphan FK 
--                 |                 | BRANCH_ID→BRANCHES          | (A009→C999, A010→B999), inconsistent currency
-- TRANSACTIONS    | TRANSACTION_ID  | ACCOUNT_ID→ACCOUNTS        | Negative amount (T008), orphan FK (T009→A999),
--                 |                 |                            | invalid type/status (T010)
-- LOAN_APPLICATIONS| APPLICATION_ID | CUSTOMER_ID→CUSTOMERS,     | Zero amount (L006), approved>requested (L007),
--                 |                 | BRANCH_ID→BRANCHES          | orphan FKs (L008, L009), future date (L010),
--                 |                 |                            | credit score out of range (L010)
-- ============================================================================
