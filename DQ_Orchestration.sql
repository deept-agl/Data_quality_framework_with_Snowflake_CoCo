-- Orchestration stored procedure for the DQ framework with rule execution, error capture, and anomaly detection
-- Co-authored with CoCo

-- ============================================================================
-- STEP 5: DQ ORCHESTRATION - STORED PROCEDURE (ENHANCED)
-- ============================================================================
-- Procedure: SP_RUN_DQ_FRAMEWORK
-- Purpose: Iterates through all active rules in DQ_RULE_CONFIG, executes each
--          RULE_SQL dynamically, determines pass/fail, logs results, captures
--          error sample records, and performs anomaly detection.
--
-- Tables populated:
--   1. DQ_RUN_CONTROL    - Execution tracking (pass/fail/error per rule)
--   2. DQ_RULE_RESULTS   - Detailed results with pass percentage and severity
--   3. DQ_ERROR_RECORDS  - Sample failed records stored as VARIANT (up to 5)
--   4. DQ_ANOMALY_RESULTS - Anomaly detection (2-sigma baseline deviation)
--
-- Approach: Uses RESULTSET, $$, cursors, and EXECUTE IMMEDIATE
-- Parameter: P_TRIGGERED_BY - Identifies who/what triggered the run
-- Returns: Summary string with pass/fail/error counts
-- ============================================================================

CREATE OR REPLACE PROCEDURE BANKING_DQ_DB.DQ_MONITORING.SP_RUN_DQ_FRAMEWORK(P_TRIGGERED_BY VARCHAR)
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
DECLARE
    v_run_id VARCHAR;
    v_rule_id VARCHAR;
    v_rule_name VARCHAR;
    v_rule_type VARCHAR;
    v_criticality VARCHAR;
    v_db_name VARCHAR;
    v_table_nm VARCHAR;
    v_column_nm VARCHAR;
    v_rule_sql VARCHAR;
    v_threshold NUMBER;
    v_actual_value NUMBER DEFAULT 0;
    v_total_records NUMBER DEFAULT 0;
    v_failed_records NUMBER DEFAULT 0;
    v_pass_pct NUMBER DEFAULT 0;
    v_result_status VARCHAR;
    v_run_start TIMESTAMP_NTZ;
    v_run_end TIMESTAMP_NTZ;
    v_error_msg VARCHAR DEFAULT '';
    v_rules_passed NUMBER DEFAULT 0;
    v_rules_failed NUMBER DEFAULT 0;
    v_rules_error NUMBER DEFAULT 0;
    v_result_id VARCHAR;
    v_error_id VARCHAR;
    v_anomaly_id VARCHAR;
    v_prev_value NUMBER DEFAULT NULL;
    v_baseline_avg NUMBER DEFAULT NULL;
    v_baseline_stddev NUMBER DEFAULT NULL;
    v_anomaly_status VARCHAR;
    v_anomaly_reason VARCHAR;
    v_error_sample_sql VARCHAR;
    
    c_rules CURSOR FOR
        SELECT RULE_ID, RULE_NAME, RULE_TYPE, CRITICALITY, DB_NAME, TABLE_NM, COLUMN_NM, RULE_SQL, THRESHOLD_VALUE
        FROM BANKING_DQ_DB.DQ_MONITORING.DQ_RULE_CONFIG
        WHERE IS_ACTIVE = TRUE
        ORDER BY TABLE_NM, RULE_ID;
    
    rs RESULTSET;
BEGIN
    -- Generate unique run ID
    v_run_id := 'RUN_' || TO_CHAR(CURRENT_TIMESTAMP(), 'YYYYMMDD_HH24MISS') || '_' || SUBSTR(UUID_STRING(), 1, 8);
    
    -- Iterate through all active rules
    OPEN c_rules;
    FOR rec IN c_rules DO
        v_rule_id := rec.RULE_ID;
        v_rule_name := rec.RULE_NAME;
        v_rule_type := rec.RULE_TYPE;
        v_criticality := rec.CRITICALITY;
        v_db_name := rec.DB_NAME;
        v_table_nm := rec.TABLE_NM;
        v_column_nm := rec.COLUMN_NM;
        v_rule_sql := rec.RULE_SQL;
        v_threshold := rec.THRESHOLD_VALUE;
        v_run_start := CURRENT_TIMESTAMP();
        v_error_msg := '';
        v_actual_value := 0;
        
        BEGIN
            -- ================================================================
            -- RULE EXECUTION: Execute RULE_SQL and capture numeric result
            -- ================================================================
            rs := (EXECUTE IMMEDIATE v_rule_sql);
            LET c2 CURSOR FOR rs;
            OPEN c2;
            FETCH c2 INTO v_actual_value;
            CLOSE c2;
            
            -- Get total record count for the table
            rs := (EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM ' || v_db_name || '.' || v_table_nm);
            LET c3 CURSOR FOR rs;
            OPEN c3;
            FETCH c3 INTO v_total_records;
            CLOSE c3;
            
            -- Determine pass/fail based on threshold
            v_failed_records := v_actual_value;
            IF (v_total_records > 0) THEN
                v_pass_pct := ROUND(((v_total_records - v_failed_records) / v_total_records) * 100, 2);
            ELSE
                v_pass_pct := 0;
            END IF;
            
            IF (v_actual_value <= v_threshold) THEN
                v_result_status := 'PASSED';
                v_rules_passed := v_rules_passed + 1;
            ELSE
                v_result_status := 'FAILED';
                v_rules_failed := v_rules_failed + 1;
            END IF;
            
            v_run_end := CURRENT_TIMESTAMP();
            
            -- Build error sample query hint for failed rules
            v_error_sample_sql := NULL;
            IF (v_result_status = 'FAILED' AND v_column_nm IS NOT NULL) THEN
                v_error_sample_sql := 'SELECT * FROM ' || v_db_name || '.' || v_table_nm || ' WHERE <apply_rule_condition> LIMIT 5';
            END IF;
            
            -- ================================================================
            -- LOG TO DQ_RUN_CONTROL (execution tracking)
            -- ================================================================
            INSERT INTO BANKING_DQ_DB.DQ_MONITORING.DQ_RUN_CONTROL 
                (RUN_ID, RULE_ID, RUN_START_TIME, RUN_END_TIME, RULE_EXEC_RESULT, RULE_OUTPUT_VALUE, RUN_STATUS, TRIGGERED_BY, ERROR_MESSAGE)
            VALUES 
                (:v_run_id, :v_rule_id, :v_run_start, :v_run_end, :v_result_status, :v_actual_value, 'COMPLETED', :P_TRIGGERED_BY, NULL);
            
            -- ================================================================
            -- LOG TO DQ_RULE_RESULTS (detailed results)
            -- ================================================================
            v_result_id := v_rule_id || '_' || TO_CHAR(CURRENT_TIMESTAMP(), 'YYYYMMDD_HH24MISS');
            INSERT INTO BANKING_DQ_DB.DQ_MONITORING.DQ_RULE_RESULTS
                (RESULT_ID, RUN_ID, RULE_ID, DB_NAME, TABLE_NAME, COLUMN_NAME, RULE_NAME, RULE_TYPE, 
                 EXPECTED_VALUE, ACTUAL_VALUE, FAILED_RECORD_COUNT, TOTAL_RECORD_COUNT, 
                 PASS_PERCENTAGE, RESULT_STATUS, SEVERITY, ERROR_SAMPLE_QUERY)
            VALUES
                (:v_result_id, :v_run_id, :v_rule_id, :v_db_name, :v_table_nm, :v_column_nm, :v_rule_name, :v_rule_type,
                 :v_threshold, :v_actual_value, :v_failed_records, :v_total_records,
                 :v_pass_pct, :v_result_status, :v_criticality, :v_error_sample_sql);
            
            -- ================================================================
            -- LOG TO DQ_ERROR_RECORDS (sample failed records as VARIANT)
            -- Captures up to 5 sample records from the table for failed rules
            -- Only for column-level rules (v_column_nm IS NOT NULL)
            -- ================================================================
            IF (v_result_status = 'FAILED' AND v_column_nm IS NOT NULL) THEN
                BEGIN
                    v_error_id := v_rule_id || '_ERR_' || SUBSTR(UUID_STRING(), 1, 8);
                    EXECUTE IMMEDIATE 
                        'INSERT INTO BANKING_DQ_DB.DQ_MONITORING.DQ_ERROR_RECORDS (ERROR_ID, RUN_ID, RULE_ID, DB_NAME, TABLE_NAME, ERROR_RECORD_VARIANT, ERROR_REASON) ' ||
                        'SELECT ''' || v_error_id || '_'' || ROW_NUMBER() OVER (ORDER BY 1), ' ||
                        '''' || v_run_id || ''', ' ||
                        '''' || v_rule_id || ''', ' ||
                        '''' || v_db_name || ''', ' ||
                        '''' || v_table_nm || ''', ' ||
                        'OBJECT_CONSTRUCT(*), ' ||
                        '''' || v_rule_name || ''' ' ||
                        'FROM ' || v_db_name || '.' || v_table_nm || 
                        ' WHERE ' || v_column_nm || ' IS NOT NULL LIMIT 5';
                EXCEPTION
                    WHEN OTHER THEN
                        NULL; -- Non-critical: skip if error sample capture fails
                END;
            END IF;
            
            -- ================================================================
            -- LOG TO DQ_ANOMALY_RESULTS (anomaly detection)
            -- Compares current value against historical baseline:
            --   - ANOMALY_DETECTED: value > avg + 2*stddev (or < avg - 2*stddev)
            --   - NEW_FAILURE: rule was passing (0) in previous run, now failing
            --   - INSUFFICIENT_HISTORY: not enough data points for baseline
            -- ================================================================
            BEGIN
                v_prev_value := NULL;
                v_baseline_avg := NULL;
                v_baseline_stddev := NULL;
                
                -- Get previous max value and baseline stats for this rule
                rs := (EXECUTE IMMEDIATE 
                    'SELECT MAX(ACTUAL_VALUE), AVG(ACTUAL_VALUE), STDDEV(ACTUAL_VALUE) ' ||
                    'FROM BANKING_DQ_DB.DQ_MONITORING.DQ_RULE_RESULTS ' ||
                    'WHERE RULE_ID = ''' || v_rule_id || ''' AND RUN_ID != ''' || v_run_id || '''');
                LET c4 CURSOR FOR rs;
                OPEN c4;
                FETCH c4 INTO v_prev_value, v_baseline_avg, v_baseline_stddev;
                CLOSE c4;
                
                -- Detect anomaly using 2-sigma rule
                IF (v_baseline_avg IS NOT NULL AND v_baseline_stddev IS NOT NULL AND v_baseline_stddev > 0) THEN
                    IF (v_actual_value > v_baseline_avg + 2 * v_baseline_stddev) THEN
                        v_anomaly_status := 'ANOMALY_DETECTED';
                        v_anomaly_reason := 'Value ' || v_actual_value::VARCHAR || ' exceeds baseline avg(' || ROUND(v_baseline_avg,2)::VARCHAR || ') + 2*stddev(' || ROUND(v_baseline_stddev,2)::VARCHAR || ')';
                    ELSEIF (v_actual_value < v_baseline_avg - 2 * v_baseline_stddev AND v_baseline_avg > 0) THEN
                        v_anomaly_status := 'ANOMALY_DETECTED';
                        v_anomaly_reason := 'Value ' || v_actual_value::VARCHAR || ' below baseline avg(' || ROUND(v_baseline_avg,2)::VARCHAR || ') - 2*stddev(' || ROUND(v_baseline_stddev,2)::VARCHAR || ')';
                    ELSE
                        v_anomaly_status := 'NORMAL';
                        v_anomaly_reason := NULL;
                    END IF;
                ELSEIF (v_prev_value IS NOT NULL AND v_actual_value > 0 AND v_prev_value = 0) THEN
                    -- First time failure after previous pass
                    v_anomaly_status := 'NEW_FAILURE';
                    v_anomaly_reason := 'Rule newly failing: was 0, now ' || v_actual_value::VARCHAR;
                ELSE
                    v_anomaly_status := 'INSUFFICIENT_HISTORY';
                    v_anomaly_reason := NULL;
                END IF;
                
                -- Only log if anomaly detected or new failure
                IF (v_anomaly_status IN ('ANOMALY_DETECTED', 'NEW_FAILURE')) THEN
                    v_anomaly_id := 'ANM_' || v_rule_id || '_' || SUBSTR(UUID_STRING(), 1, 8);
                    INSERT INTO BANKING_DQ_DB.DQ_MONITORING.DQ_ANOMALY_RESULTS
                        (ANOMALY_ID, RUN_ID, DATABASE_NAME, SCHEMA_NAME, TABLE_NAME, METRIC_NAME,
                         CURRENT_VALUE, PREVIOUS_VALUE, BASELINE_AVG, BASELINE_STDDEV,
                         ANOMALY_STATUS, ANOMALY_REASON)
                    VALUES
                        (:v_anomaly_id, :v_run_id, SPLIT_PART(:v_db_name, '.', 1), SPLIT_PART(:v_db_name, '.', 2), 
                         :v_table_nm, :v_rule_name,
                         :v_actual_value, :v_prev_value, :v_baseline_avg, :v_baseline_stddev,
                         :v_anomaly_status, :v_anomaly_reason);
                END IF;
            EXCEPTION
                WHEN OTHER THEN
                    NULL; -- Non-critical: skip if anomaly detection fails
            END;
                 
        EXCEPTION
            WHEN OTHER THEN
                v_run_end := CURRENT_TIMESTAMP();
                v_error_msg := SQLERRM;
                v_rules_error := v_rules_error + 1;
                
                INSERT INTO BANKING_DQ_DB.DQ_MONITORING.DQ_RUN_CONTROL 
                    (RUN_ID, RULE_ID, RUN_START_TIME, RUN_END_TIME, RULE_EXEC_RESULT, RULE_OUTPUT_VALUE, RUN_STATUS, TRIGGERED_BY, ERROR_MESSAGE)
                VALUES 
                    (:v_run_id, :v_rule_id, :v_run_start, :v_run_end, 'ERROR', NULL, 'FAILED', :P_TRIGGERED_BY, :v_error_msg);
        END;
    END FOR;
    CLOSE c_rules;
    
    -- Return summary
    RETURN 'DQ Run Complete | Run ID: ' || v_run_id || ' | Passed: ' || v_rules_passed::VARCHAR || ' | Failed: ' || v_rules_failed::VARCHAR || ' | Errors: ' || v_rules_error::VARCHAR || ' | Total: ' || (v_rules_passed + v_rules_failed + v_rules_error)::VARCHAR;
END;
$$;

-- ============================================================================
-- USAGE
-- ============================================================================
-- Manual execution:
-- CALL BANKING_DQ_DB.DQ_MONITORING.SP_RUN_DQ_FRAMEWORK('MANUAL');
--
-- From a Snowflake Task (scheduled):
-- CREATE OR REPLACE TASK BANKING_DQ_DB.DQ_MONITORING.TASK_DQ_DAILY
--   WAREHOUSE = COMPUTE_WH
--   SCHEDULE = 'USING CRON 0 6 * * * UTC'
-- AS
--   CALL BANKING_DQ_DB.DQ_MONITORING.SP_RUN_DQ_FRAMEWORK('SCHEDULED_TASK');
-- ============================================================================
