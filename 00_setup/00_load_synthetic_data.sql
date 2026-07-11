-- ==========================================================
-- Banking Synthetic Dataset Loading Script
-- Purpose: Base dataset + later anomaly batch for Snowflake DQ demo
-- ==========================================================

-- ----------------------------------------------------------
-- 1. DATABASE AND SCHEMA SETUP
-- ----------------------------------------------------------
CREATE DATABASE IF NOT EXISTS BANKING_DQ_DB;
CREATE SCHEMA IF NOT EXISTS BANKING_DQ_DB.RAW;

USE DATABASE BANKING_DQ_DB;
USE SCHEMA RAW;

-- ----------------------------------------------------------
-- 2. CLEANUP FOR RE-RUN
-- ----------------------------------------------------------
DROP TABLE IF EXISTS TRANSACTIONS;
DROP TABLE IF EXISTS LOAN_APPLICATIONS;
DROP TABLE IF EXISTS ACCOUNTS;
DROP TABLE IF EXISTS CUSTOMERS;
DROP TABLE IF EXISTS BRANCHES;

-- ----------------------------------------------------------
-- 3. TABLE CREATION
-- ----------------------------------------------------------
CREATE OR REPLACE TABLE BRANCHES (
    BRANCH_ID          STRING,
    BRANCH_NAME        STRING,
    CITY               STRING,
    STATE              STRING,
    IFSC_CODE          STRING,
    IS_ACTIVE          BOOLEAN,
    CREATED_AT         TIMESTAMP_NTZ
);

CREATE OR REPLACE TABLE CUSTOMERS (
    CUSTOMER_ID        STRING,
    FIRST_NAME         STRING,
    LAST_NAME          STRING,
    EMAIL              STRING,
    PHONE              STRING,
    DATE_OF_BIRTH      DATE,
    KYC_STATUS         STRING,
    RISK_CATEGORY      STRING,
    BRANCH_ID          STRING,
    CREATED_AT         TIMESTAMP_NTZ
);

CREATE OR REPLACE TABLE ACCOUNTS (
    ACCOUNT_ID         STRING,
    CUSTOMER_ID        STRING,
    BRANCH_ID          STRING,
    ACCOUNT_TYPE       STRING,
    ACCOUNT_STATUS     STRING,
    OPEN_DATE          DATE,
    BALANCE            NUMBER(18,2),
    CURRENCY           STRING,
    CREATED_AT         TIMESTAMP_NTZ
);

CREATE OR REPLACE TABLE TRANSACTIONS (
    TRANSACTION_ID     STRING,
    ACCOUNT_ID         STRING,
    TRANSACTION_DATE   TIMESTAMP_NTZ,
    TRANSACTION_TYPE   STRING,
    AMOUNT             NUMBER(18,2),
    CHANNEL            STRING,
    MERCHANT_CATEGORY  STRING,
    TRANSACTION_STATUS STRING,
    CREATED_AT         TIMESTAMP_NTZ
);

CREATE OR REPLACE TABLE LOAN_APPLICATIONS (
    APPLICATION_ID     STRING,
    CUSTOMER_ID        STRING,
    BRANCH_ID          STRING,
    LOAN_TYPE          STRING,
    APPLICATION_DATE   DATE,
    REQUESTED_AMOUNT   NUMBER(18,2),
    APPROVED_AMOUNT    NUMBER(18,2),
    APPLICATION_STATUS STRING,
    CREDIT_SCORE       NUMBER(5,0),
    CREATED_AT         TIMESTAMP_NTZ
);

-- ==========================================================
-- SET 1: BASELINE DATA LOAD
-- Run this now.
-- This contains mostly good records with a few obvious quality issues
-- so the first DQ dashboard has something to show.
-- ==========================================================

-- ----------------------------------------------------------
-- 4. INSERT SET 1: BRANCHES
-- ----------------------------------------------------------
INSERT INTO BRANCHES VALUES
('B001', 'MG Road Branch', 'Bengaluru', 'Karnataka', 'BKID0001001', TRUE,  '2026-07-01 09:00:00'),
('B002', 'Cyber City Branch', 'Gurugram',  'Haryana',   'BKID0001002', TRUE,  '2026-07-01 09:05:00'),
('B003', 'Andheri East Branch', 'Mumbai', 'Maharashtra','BKID0001003', TRUE,  '2026-07-01 09:10:00'),
('B004', 'Salt Lake Branch', 'Kolkata',   'West Bengal','BKID0001004', TRUE,  '2026-07-01 09:15:00'),
('B005', 'Adyar Branch', 'Chennai',       'Tamil Nadu', 'BKID0001005', TRUE,  '2026-07-01 09:20:00'),
('B006', 'Invalid IFSC Branch', 'Pune',   'Maharashtra','BADIFSC',     TRUE,  '2026-07-01 09:25:00'), -- DQ issue: invalid IFSC format
('B007', NULL, 'Hyderabad',               'Telangana',  'BKID0001007', TRUE,  '2026-07-01 09:30:00'); -- DQ issue: missing branch name

-- ----------------------------------------------------------
-- 5. INSERT SET 1: CUSTOMERS
-- ----------------------------------------------------------
INSERT INTO CUSTOMERS VALUES
('C001', 'Aarav',   'Sharma',  'aarav.sharma@example.com',   '9876543210', '1991-04-12', 'VERIFIED', 'LOW',    'B001', '2026-07-01 10:00:00'),
('C002', 'Meera',   'Iyer',    'meera.iyer@example.com',     '9876543211', '1988-09-23', 'VERIFIED', 'LOW',    'B005', '2026-07-01 10:05:00'),
('C003', 'Kabir',   'Khan',    'kabir.khan@example.com',     '9876543212', '1995-02-18', 'PENDING',  'MEDIUM', 'B002', '2026-07-01 10:10:00'),
('C004', 'Ananya',  'Rao',     'ananya.rao@example.com',     '9876543213', '1990-11-05', 'VERIFIED', 'LOW',    'B003', '2026-07-01 10:15:00'),
('C005', 'Rohan',   'Mehta',   'rohan.mehta@example.com',    '9876543214', '1985-07-15', 'VERIFIED', 'HIGH',   'B004', '2026-07-01 10:20:00'),
('C006', 'Neha',    'Gupta',   'neha.gupta.example.com',     '9876543215', '1992-01-30', 'VERIFIED', 'LOW',    'B001', '2026-07-01 10:25:00'), -- DQ issue: invalid email
('C007', 'Vikram',  'Singh',   'vikram.singh@example.com',   '12345',      '1987-03-14', 'VERIFIED', 'MEDIUM', 'B002', '2026-07-01 10:30:00'), -- DQ issue: invalid phone
('C008', 'Priya',   'Nair',    'priya.nair@example.com',     '9876543217', '2030-06-01', 'VERIFIED', 'LOW',    'B005', '2026-07-01 10:35:00'), -- DQ issue: future DOB
('C009', 'Ishaan',  'Kapoor',  'ishaan.kapoor@example.com',  '9876543218', '1993-12-09', 'DONE',     'LOW',    'B003', '2026-07-01 10:40:00'), -- DQ issue: invalid KYC status
('C010', 'Sara',    'Thomas',  'sara.thomas@example.com',    '9876543219', '1994-05-27', 'VERIFIED', 'LOW',    'B999', '2026-07-01 10:45:00'); -- DQ issue: invalid branch reference

-- ----------------------------------------------------------
-- 6. INSERT SET 1: ACCOUNTS
-- ----------------------------------------------------------
INSERT INTO ACCOUNTS VALUES
('A001', 'C001', 'B001', 'SAVINGS', 'ACTIVE',  '2024-01-10',  52000.00, 'INR', '2026-07-01 11:00:00'),
('A002', 'C002', 'B005', 'CURRENT', 'ACTIVE',  '2023-08-19', 135000.50, 'INR', '2026-07-01 11:05:00'),
('A003', 'C003', 'B002', 'SAVINGS', 'ACTIVE',  '2025-02-11',  18500.00, 'INR', '2026-07-01 11:10:00'),
('A004', 'C004', 'B003', 'SAVINGS', 'DORMANT', '2022-06-07',   7500.25, 'INR', '2026-07-01 11:15:00'),
('A005', 'C005', 'B004', 'CURRENT', 'ACTIVE',  '2021-03-25', 250000.00, 'INR', '2026-07-01 11:20:00'),
('A006', 'C006', 'B001', 'SAVINGS', 'ACTIVE',  '2024-12-01',  32000.00, 'INR', '2026-07-01 11:25:00'),
('A007', 'C007', 'B002', 'SAVINGS', 'CLOSED',  '2023-05-16',      0.00, 'INR', '2026-07-01 11:30:00'),
('A008', 'C008', 'B005', 'SAVINGS', 'ACTIVE',  '2025-09-09', -1500.00, 'INR', '2026-07-01 11:35:00'), -- DQ issue: negative balance for savings
('A009', 'C999', 'B003', 'SAVINGS', 'ACTIVE',  '2024-04-12',  23000.00, 'INR', '2026-07-01 11:40:00'), -- DQ issue: invalid customer reference
('A010', 'C010', 'B999', 'LOAN',    'ACTIVE',  '2024-10-21',  10000.00, 'USD', '2026-07-01 11:45:00'); -- DQ issue: invalid account type/currency/branch

-- ----------------------------------------------------------
-- 7. INSERT SET 1: TRANSACTIONS
-- ----------------------------------------------------------
INSERT INTO TRANSACTIONS VALUES
('T001', 'A001', '2026-07-01 09:10:00', 'DEBIT',  1200.00, 'UPI',     'GROCERY',   'SUCCESS', '2026-07-01 12:00:00'),
('T002', 'A001', '2026-07-01 11:30:00', 'CREDIT', 5000.00, 'NEFT',    'SALARY',    'SUCCESS', '2026-07-01 12:05:00'),
('T003', 'A002', '2026-07-01 14:15:00', 'DEBIT',  2500.00, 'CARD',    'SHOPPING',  'SUCCESS', '2026-07-01 12:10:00'),
('T004', 'A003', '2026-07-02 10:00:00', 'DEBIT',   650.00, 'UPI',     'FOOD',      'SUCCESS', '2026-07-02 12:00:00'),
('T005', 'A004', '2026-07-02 12:45:00', 'CREDIT', 7000.00, 'IMPS',    'TRANSFER',  'SUCCESS', '2026-07-02 12:05:00'),
('T006', 'A005', '2026-07-02 16:20:00', 'DEBIT',  9900.00, 'ATM',     'CASH',      'SUCCESS', '2026-07-02 12:10:00'),
('T007', 'A006', '2026-07-03 09:40:00', 'DEBIT',   899.00, 'UPI',     'BILLS',     'SUCCESS', '2026-07-03 12:00:00'),
('T008', 'A008', '2026-07-03 10:10:00', 'DEBIT',   -50.00, 'UPI',     'FOOD',      'SUCCESS', '2026-07-03 12:05:00'), -- DQ issue: negative transaction amount
('T009', 'A999', '2026-07-03 11:05:00', 'DEBIT',  1500.00, 'CARD',    'FUEL',      'SUCCESS', '2026-07-03 12:10:00'), -- DQ issue: invalid account reference
('T010', 'A010', '2026-07-04 13:00:00', 'PAYMENT', 4500.00, 'CHEQUE', 'SHOPPING',  'DONE',    '2026-07-04 12:00:00'), -- DQ issue: invalid transaction type/status/channel
('T011', 'A002', '2026-07-04 15:30:00', 'DEBIT',  7500.00, 'CARD',    'TRAVEL',    'SUCCESS', '2026-07-04 12:05:00'),
('T012', 'A003', '2026-07-05 09:15:00', 'CREDIT', 2000.00, 'UPI',     'TRANSFER',  'FAILED',  '2026-07-05 12:00:00');

-- ----------------------------------------------------------
-- 8. INSERT SET 1: LOAN_APPLICATIONS
-- ----------------------------------------------------------
INSERT INTO LOAN_APPLICATIONS VALUES
('L001', 'C001', 'B001', 'HOME',     '2026-06-10', 3500000.00, 3000000.00, 'APPROVED', 760, '2026-07-01 13:00:00'),
('L002', 'C002', 'B005', 'CAR',      '2026-06-12',  800000.00,  700000.00, 'APPROVED', 725, '2026-07-01 13:05:00'),
('L003', 'C003', 'B002', 'PERSONAL', '2026-06-15',  300000.00,       NULL, 'PENDING',  680, '2026-07-01 13:10:00'),
('L004', 'C004', 'B003', 'EDUCATION','2026-06-18', 1200000.00,       NULL, 'REJECTED', 610, '2026-07-01 13:15:00'),
('L005', 'C005', 'B004', 'HOME',     '2026-06-21', 5000000.00, 4500000.00, 'APPROVED', 790, '2026-07-01 13:20:00'),
('L006', 'C006', 'B001', 'PERSONAL', '2026-06-23',       0.00,       NULL, 'PENDING',  700, '2026-07-01 13:25:00'), -- DQ issue: requested amount <= 0
('L007', 'C007', 'B002', 'CAR',      '2026-06-24',  600000.00,  700000.00, 'APPROVED', 710, '2026-07-01 13:30:00'), -- DQ issue: approved > requested
('L008', 'C999', 'B003', 'HOME',     '2026-06-25', 4000000.00,       NULL, 'PENDING',  750, '2026-07-01 13:35:00'), -- DQ issue: invalid customer reference
('L009', 'C008', 'B999', 'BUSINESS', '2026-06-26', 2000000.00,       NULL, 'PENDING',  720, '2026-07-01 13:40:00'), -- DQ issue: invalid branch reference
('L010', 'C009', 'B003', 'PERSONAL', '2026-08-01',  250000.00,       NULL, 'PENDING',  900, '2026-07-01 13:45:00'); -- DQ issue: future application date / suspicious credit score upper boundary

-- ==========================================================
-- SET 2: LATER ANOMALY LOAD
-- Do NOT run this in the first time.
-- Run later after baseline DQ framework is working.
-- This batch intentionally creates volume spikes, duplicates,
-- nulls, invalid references, distribution changes and outliers.
-- ==========================================================

-- ----------------------------------------------------------
-- 9. INSERT SET 2: BRANCHES
-- ----------------------------------------------------------
-- Run later:
/*
INSERT INTO BRANCHES VALUES
('B008', 'Whitefield Digital Branch', 'Bengaluru', 'Karnataka', 'BKID0001008', TRUE,  '2026-07-08 09:00:00'),
('B009', 'Noida Sector 62 Branch',    'Noida',     'Uttar Pradesh', 'BKID0001009', TRUE, '2026-07-08 09:05:00'),
('B009', 'Duplicate Noida Branch',    'Noida',     'Uttar Pradesh', 'BKID0001009', TRUE, '2026-07-08 09:10:00'), -- DQ issue: duplicate branch id
('B010', 'Inactive Unknown Branch',   NULL,        NULL,            'BKID0001010', FALSE,'2026-07-08 09:15:00'); -- DQ issue: missing city/state
*/

-- ----------------------------------------------------------
-- 10. INSERT SET 2: CUSTOMERS
-- ----------------------------------------------------------
-- Run later:
/*
INSERT INTO CUSTOMERS VALUES
('C011', 'Dev',     'Malhotra', 'dev.malhotra@example.com', '9876500011', '1996-03-12', 'VERIFIED', 'LOW',    'B008', '2026-07-08 10:00:00'),
('C012', 'Tara',    'Sen',      'tara.sen@example.com',     '9876500012', '1998-08-19', 'VERIFIED', 'LOW',    'B009', '2026-07-08 10:05:00'),
('C013', 'Mohan',   'Das',      NULL,                       '9876500013', '1975-04-01', 'PENDING',  'HIGH',   'B009', '2026-07-08 10:10:00'), -- DQ issue: null email
('C014', 'Ritika',  'Bose',     'ritika.bose@example.com',   NULL,         '1992-10-11', 'VERIFIED', 'MEDIUM', 'B010', '2026-07-08 10:15:00'), -- DQ issue: null phone
('C015', 'Ayaan',   'Verma',    'ayaan.verma@example.com',   '9876500015', '2012-01-01', 'VERIFIED', 'LOW',    'B008', '2026-07-08 10:20:00'), -- DQ issue: customer likely under 18
('C016', 'Fraud',   'Spike',    'fraud.spike@example.com',   '9876500016', '1980-05-05', 'VERIFIED', 'CRITICAL','B008','2026-07-08 10:25:00'), -- DQ issue: invalid risk category
('C016', 'Fraud',   'Spike2',   'fraud.spike2@example.com',  '9876500017', '1980-05-05', 'VERIFIED', 'HIGH',   'B008', '2026-07-08 10:30:00'); -- DQ issue: duplicate customer id
*/

-- ----------------------------------------------------------
-- 11. INSERT SET 2: ACCOUNTS
-- ----------------------------------------------------------
-- Run later:
/*
INSERT INTO ACCOUNTS VALUES
('A011', 'C011', 'B008', 'SAVINGS', 'ACTIVE',  '2026-07-08',     25000.00, 'INR', '2026-07-08 11:00:00'),
('A012', 'C012', 'B009', 'CURRENT', 'ACTIVE',  '2026-07-08',    125000.00, 'INR', '2026-07-08 11:05:00'),
('A013', 'C013', 'B009', 'SAVINGS', 'ACTIVE',  '2026-07-08',      5000.00, 'INR', '2026-07-08 11:10:00'),
('A014', 'C014', 'B010', 'SAVINGS', 'ACTIVE',  '2026-07-08',      1000.00, 'INR', '2026-07-08 11:15:00'),
('A015', 'C015', 'B008', 'SAVINGS', 'ACTIVE',  '2026-07-08',       500.00, 'INR', '2026-07-08 11:20:00'),
('A016', 'C016', 'B008', 'SAVINGS', 'ACTIVE',  '2026-07-08', 999999999.00, 'INR', '2026-07-08 11:25:00'), -- DQ/anomaly: extreme balance outlier
('A017', 'C017', 'B008', 'CURRENT', 'ACTIVE',  '2026-07-08',     20000.00, 'INR', '2026-07-08 11:30:00'), -- DQ issue: missing customer reference
('A018', 'C012', 'B009', 'SAVINGS', 'UNKNOWN', '2026-07-08',      7000.00, 'INR', '2026-07-08 11:35:00'); -- DQ issue: invalid account status
*/

-- ----------------------------------------------------------
-- 12. INSERT SET 2: TRANSACTIONS
-- ----------------------------------------------------------
-- Run later:
/*
INSERT INTO TRANSACTIONS VALUES
('T013', 'A011', '2026-07-08 09:00:00', 'DEBIT',     1000.00, 'UPI',     'FOOD',     'SUCCESS', '2026-07-08 12:00:00'),
('T014', 'A011', '2026-07-08 09:05:00', 'DEBIT',     1200.00, 'UPI',     'FOOD',     'SUCCESS', '2026-07-08 12:01:00'),
('T015', 'A011', '2026-07-08 09:10:00', 'DEBIT',     1100.00, 'UPI',     'FOOD',     'SUCCESS', '2026-07-08 12:02:00'),
('T016', 'A011', '2026-07-08 09:15:00', 'DEBIT',     1300.00, 'UPI',     'FOOD',     'SUCCESS', '2026-07-08 12:03:00'),
('T017', 'A011', '2026-07-08 09:20:00', 'DEBIT',     1400.00, 'UPI',     'FOOD',     'SUCCESS', '2026-07-08 12:04:00'),
('T018', 'A012', '2026-07-08 10:00:00', 'DEBIT',   500000.00, 'CARD',    'JEWELLERY','SUCCESS', '2026-07-08 12:05:00'), -- anomaly: high amount
('T019', 'A012', '2026-07-08 10:10:00', 'DEBIT',   750000.00, 'CARD',    'TRAVEL',   'SUCCESS', '2026-07-08 12:06:00'), -- anomaly: high amount
('T020', 'A013', '2026-07-08 11:00:00', 'CREDIT', 2000000.00, 'NEFT',    'TRANSFER', 'SUCCESS', '2026-07-08 12:07:00'), -- anomaly: credit spike
('T020', 'A013', '2026-07-08 11:00:00', 'CREDIT', 2000000.00, 'NEFT',    'TRANSFER', 'SUCCESS', '2026-07-08 12:08:00'), -- DQ issue: duplicate transaction id
('T021', 'A999', '2026-07-08 11:30:00', 'DEBIT',     9000.00, 'ATM',     'CASH',     'SUCCESS', '2026-07-08 12:09:00'), -- DQ issue: invalid account reference
('T022', 'A014', '2026-07-09 12:00:00', 'DEBIT',        NULL, 'UPI',     'BILLS',    'SUCCESS', '2026-07-08 12:10:00'), -- DQ issue: null amount
('T023', 'A015', '2026-07-10 13:00:00', 'DEBIT',       50.00, NULL,      'FOOD',     'SUCCESS', '2026-07-08 12:11:00'), -- DQ issue: null channel
('T024', 'A016', '2026-07-11 14:00:00', 'DEBIT', 10000000.00, 'CARD',    'UNKNOWN',  'SUCCESS', '2026-07-08 12:12:00'); -- anomaly: extreme amount / invalid merchant category
*/

-- ----------------------------------------------------------
-- 13. INSERT SET 2: LOAN_APPLICATIONS
-- ----------------------------------------------------------
-- Run later:
/*
INSERT INTO LOAN_APPLICATIONS VALUES
('L011', 'C011', 'B008', 'PERSONAL', '2026-07-08',  250000.00,       NULL, 'PENDING',  690, '2026-07-08 13:00:00'),
('L012', 'C012', 'B009', 'HOME',     '2026-07-08', 7000000.00, 6500000.00, 'APPROVED', 805, '2026-07-08 13:05:00'),
('L013', 'C013', 'B009', 'CAR',      '2026-07-08',  900000.00,       NULL, 'PENDING',  650, '2026-07-08 13:10:00'),
('L014', 'C014', 'B010', 'PERSONAL', '2026-07-08',  400000.00,  500000.00, 'APPROVED', 710, '2026-07-08 13:15:00'), -- DQ issue: approved > requested
('L015', 'C999', 'B008', 'HOME',     '2026-07-08', 9000000.00,       NULL, 'PENDING',  780, '2026-07-08 13:20:00'), -- DQ issue: invalid customer reference
('L016', 'C015', 'B008', 'BUSINESS', '2026-07-08', 1000000.00,       NULL, 'PENDING',  720, '2026-07-08 13:25:00'), -- DQ issue: invalid loan type
('L017', 'C016', 'B008', 'PERSONAL', '2026-07-08', 9999999.00,       NULL, 'PENDING',  300, '2026-07-08 13:30:00'), -- anomaly: high amount / low score
('L017', 'C016', 'B008', 'PERSONAL', '2026-07-08', 9999999.00,       NULL, 'PENDING',  300, '2026-07-08 13:35:00'); -- DQ issue: duplicate application id
*/

-- ----------------------------------------------------------
-- 14. QUICK VALIDATION QUERIES
-- ----------------------------------------------------------
SELECT 'BRANCHES' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM BRANCHES
UNION ALL SELECT 'CUSTOMERS', COUNT(*) FROM CUSTOMERS
UNION ALL SELECT 'ACCOUNTS', COUNT(*) FROM ACCOUNTS
UNION ALL SELECT 'TRANSACTIONS', COUNT(*) FROM TRANSACTIONS
UNION ALL SELECT 'LOAN_APPLICATIONS', COUNT(*) FROM LOAN_APPLICATIONS;
