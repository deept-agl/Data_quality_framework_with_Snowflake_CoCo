# Enterprise Data Quality Monitoring Dashboard for BANKING_DQ_DB
# Co-authored with CoCo

import os
import streamlit as st
import pandas as pd
import altair as alt

st.set_page_config(
    page_title="DQ Monitoring Dashboard",
    page_icon=":material/shield:",
    layout="wide",
)

conn = st.connection("snowflake", ttl=os.getenv("SNOWFLAKE_CONNECTION_TTL"))


@st.cache_data(ttl=60)
def load_rule_results():
    return conn.query("""
        SELECT RESULT_ID, RUN_ID, RULE_ID, DB_NAME, TABLE_NAME, COLUMN_NAME,
               RULE_NAME, RULE_TYPE, EXPECTED_VALUE, ACTUAL_VALUE,
               FAILED_RECORD_COUNT, TOTAL_RECORD_COUNT, PASS_PERCENTAGE,
               RESULT_STATUS, SEVERITY, EXECUTED_AT
        FROM BANKING_DQ_DB.DQ_MONITORING.DQ_RULE_RESULTS
        ORDER BY EXECUTED_AT DESC
    """)


@st.cache_data(ttl=60)
def load_rule_config():
    return conn.query("""
        SELECT RULE_ID, RULE_NAME, RULE_TYPE, CRITICALITY, DB_NAME, TABLE_NM,
               COLUMN_NM, RULE_DESCRIPTION, IS_ACTIVE
        FROM BANKING_DQ_DB.DQ_MONITORING.DQ_RULE_CONFIG
    """)


@st.cache_data(ttl=60)
def load_anomaly_results():
    return conn.query("""
        SELECT ANOMALY_ID, RUN_ID, DATABASE_NAME, SCHEMA_NAME, TABLE_NAME,
               METRIC_NAME, CURRENT_VALUE, PREVIOUS_VALUE, BASELINE_AVG,
               BASELINE_STDDEV, ANOMALY_STATUS, ANOMALY_REASON, DETECTED_AT
        FROM BANKING_DQ_DB.DQ_MONITORING.DQ_ANOMALY_RESULTS
        ORDER BY DETECTED_AT DESC
    """)


@st.cache_data(ttl=60)
def load_error_records():
    return conn.query("""
        SELECT ERROR_ID, RUN_ID, RULE_ID, DB_NAME, TABLE_NAME,
               ERROR_RECORD_VARIANT, ERROR_REASON, CREATED_AT
        FROM BANKING_DQ_DB.DQ_MONITORING.DQ_ERROR_RECORDS
        ORDER BY CREATED_AT DESC
    """)


@st.cache_data(ttl=60)
def load_run_history():
    return conn.query("""
        SELECT RUN_ID, 
               MIN(RUN_START_TIME) AS RUN_TIME,
               COUNT(*) AS TOTAL_RULES,
               SUM(CASE WHEN RULE_EXEC_RESULT = 'PASSED' THEN 1 ELSE 0 END) AS PASSED,
               SUM(CASE WHEN RULE_EXEC_RESULT = 'FAILED' THEN 1 ELSE 0 END) AS FAILED,
               TRIGGERED_BY
        FROM BANKING_DQ_DB.DQ_MONITORING.DQ_RUN_CONTROL
        GROUP BY RUN_ID, TRIGGERED_BY
        ORDER BY RUN_TIME DESC
    """)


# Load data
df_results = load_rule_results()
df_config = load_rule_config()
df_anomalies = load_anomaly_results()
df_errors = load_error_records()
df_runs = load_run_history()

# Sidebar
with st.sidebar:
    st.markdown("### :material/shield: DQ Framework")
    st.caption("BANKING_DQ_DB.DQ_MONITORING")

    if st.button(":material/refresh: Refresh data", use_container_width=True):
        load_rule_results.clear()
        load_rule_config.clear()
        load_anomaly_results.clear()
        load_error_records.clear()
        load_run_history.clear()
        st.rerun()

    st.markdown("---")
    st.markdown("**Filters**")

    tables = sorted(df_results["TABLE_NAME"].unique().tolist()) if len(df_results) > 0 else []
    selected_tables = st.multiselect("Table", tables, default=tables)

    rule_types = sorted(df_results["RULE_TYPE"].unique().tolist()) if len(df_results) > 0 else []
    selected_rule_types = st.multiselect("Rule type", rule_types, default=rule_types)

    severities = sorted(df_results["SEVERITY"].unique().tolist()) if len(df_results) > 0 else []
    selected_severities = st.multiselect("Severity", severities, default=severities)

    selected_status = st.segmented_control("Status", ["All", "Passed", "Failed"], default="All")

# Apply filters
if len(df_results) > 0:
    mask = (
        (df_results["TABLE_NAME"].isin(selected_tables)) &
        (df_results["RULE_TYPE"].isin(selected_rule_types)) &
        (df_results["SEVERITY"].isin(selected_severities))
    )
    if selected_status == "Passed":
        mask = mask & (df_results["RESULT_STATUS"] == "PASSED")
    elif selected_status == "Failed":
        mask = mask & (df_results["RESULT_STATUS"] == "FAILED")
    df_filtered = df_results[mask]
else:
    df_filtered = df_results

# Get latest run
if len(df_filtered) > 0:
    latest_run = df_filtered["RUN_ID"].iloc[0]
    df_latest = df_filtered[df_filtered["RUN_ID"] == latest_run]
else:
    df_latest = df_filtered

# Header
st.markdown("## :material/monitoring: Data quality monitoring")

# TABS
tab_overview, tab_results, tab_anomalies, tab_coverage = st.tabs(
    [
        ":material/dashboard: Overview",
        ":material/rule: Rule results",
        ":material/warning: Anomalies",
        ":material/verified: Coverage",
    ]
)

# Color palette
COLOR_PASS = "#2ecc71"
COLOR_FAIL = "#e74c3c"
COLOR_WARN = "#f39c12"
COLOR_INFO = "#3498db"
COLOR_PALETTE = ["#2ecc71", "#e74c3c", "#f39c12", "#3498db", "#9b59b6"]

# ===== TAB 1: OVERVIEW =====
with tab_overview:
    if len(df_latest) > 0:
        total_rules = len(df_latest)
        passed = len(df_latest[df_latest["RESULT_STATUS"] == "PASSED"])
        failed = len(df_latest[df_latest["RESULT_STATUS"] == "FAILED"])
        health_score = round((passed / total_rules) * 100, 1) if total_rules > 0 else 0
        monitored_tables = df_latest["TABLE_NAME"].nunique()
        critical_failures = len(
            df_latest[(df_latest["RESULT_STATUS"] == "FAILED") & (df_latest["SEVERITY"] == "HIGH")]
        )
        active_anomalies = len(df_anomalies) if len(df_anomalies) > 0 else 0

        # Health badge
        if health_score >= 90:
            health_delta = "Healthy"
        elif health_score >= 70:
            health_delta = "Needs attention"
        else:
            health_delta = "Critical"

        # KPI Cards Row
        with st.container(horizontal=True):
            st.metric("Health score", f"{health_score}%", health_delta, border=True)
            st.metric("Tables monitored", monitored_tables, border=True)
            st.metric("Total rules", total_rules, border=True)
            st.metric("Passed", passed, f"+{passed}", delta_color="normal", border=True)
            st.metric("Failed", failed, f"-{failed}", delta_color="inverse", border=True)
            st.metric("Critical failures", critical_failures, border=True)
            st.metric("Anomalies", active_anomalies, border=True)

        # Charts Row 1: Pass/Fail Donut + Table Health
        col1, col2 = st.columns(2)

        with col1:
            with st.container(border=True):
                st.markdown("**Rule pass/fail distribution**")
                donut_data = pd.DataFrame({
                    "Status": ["Passed", "Failed"],
                    "Count": [passed, failed],
                    "Color": [COLOR_PASS, COLOR_FAIL]
                })
                donut = alt.Chart(donut_data).mark_arc(innerRadius=60, outerRadius=100).encode(
                    theta=alt.Theta("Count:Q"),
                    color=alt.Color("Status:N", scale=alt.Scale(
                        domain=["Passed", "Failed"],
                        range=[COLOR_PASS, COLOR_FAIL]
                    ), legend=alt.Legend(orient="bottom")),
                    tooltip=["Status", "Count"]
                ).properties(height=280)
                st.altair_chart(donut)

        with col2:
            with st.container(border=True):
                st.markdown("**Table health scores**")
                table_health = df_latest.groupby("TABLE_NAME").apply(
                    lambda x: round((x["RESULT_STATUS"] == "PASSED").sum() / len(x) * 100, 1)
                ).reset_index(name="Health %")

                bars = alt.Chart(table_health).mark_bar(cornerRadiusEnd=4).encode(
                    x=alt.X("Health %:Q", scale=alt.Scale(domain=[0, 100]), title="Health %"),
                    y=alt.Y("TABLE_NAME:N", sort="-x", title=None),
                    color=alt.condition(
                        alt.datum["Health %"] >= 80,
                        alt.value(COLOR_PASS),
                        alt.value(COLOR_FAIL)
                    ),
                    tooltip=["TABLE_NAME", "Health %"]
                ).properties(height=280)
                st.altair_chart(bars)

        # Charts Row 2: Failures by Severity + Rule Type
        col3, col4 = st.columns(2)

        failed_df = df_latest[df_latest["RESULT_STATUS"] == "FAILED"]

        with col3:
            with st.container(border=True):
                st.markdown("**Failures by severity**")
                if len(failed_df) > 0:
                    sev_data = failed_df["SEVERITY"].value_counts().reset_index()
                    sev_data.columns = ["Severity", "Count"]
                    sev_chart = alt.Chart(sev_data).mark_bar(cornerRadiusEnd=4).encode(
                        x=alt.X("Severity:N", sort="-y", axis=alt.Axis(labelAngle=0)),
                        y=alt.Y("Count:Q"),
                        color=alt.Color("Severity:N", scale=alt.Scale(
                            domain=["HIGH", "MEDIUM", "LOW"],
                            range=[COLOR_FAIL, COLOR_WARN, COLOR_INFO]
                        ), legend=None),
                        tooltip=["Severity", "Count"]
                    ).properties(height=250)
                    st.altair_chart(sev_chart)
                else:
                    st.success("No failures detected!", icon=":material/check_circle:")

        with col4:
            with st.container(border=True):
                st.markdown("**Failures by rule type**")
                if len(failed_df) > 0:
                    type_data = failed_df["RULE_TYPE"].value_counts().reset_index()
                    type_data.columns = ["Rule Type", "Count"]
                    type_chart = alt.Chart(type_data).mark_arc(innerRadius=50, outerRadius=90).encode(
                        theta=alt.Theta("Count:Q"),
                        color=alt.Color("Rule Type:N", scale=alt.Scale(range=COLOR_PALETTE),
                                        legend=alt.Legend(orient="bottom")),
                        tooltip=["Rule Type", "Count"]
                    ).properties(height=250)
                    st.altair_chart(type_chart)
                else:
                    st.success("No failures detected!", icon=":material/check_circle:")

        # Charts Row 3: Top failing tables + columns
        col5, col6 = st.columns(2)

        with col5:
            with st.container(border=True):
                st.markdown("**Top failing tables**")
                if len(failed_df) > 0:
                    top_tables = failed_df.groupby("TABLE_NAME").size().reset_index(name="Failures")
                    top_tables = top_tables.sort_values("Failures", ascending=False)
                    t_chart = alt.Chart(top_tables).mark_bar(cornerRadiusEnd=4, color=COLOR_FAIL).encode(
                        x=alt.X("Failures:Q"),
                        y=alt.Y("TABLE_NAME:N", sort="-x", title=None),
                        tooltip=["TABLE_NAME", "Failures"]
                    ).properties(height=220)
                    st.altair_chart(t_chart)

        with col6:
            with st.container(border=True):
                st.markdown("**Top failing columns**")
                if len(failed_df) > 0:
                    col_data = failed_df[failed_df["COLUMN_NAME"].notna()]
                    if len(col_data) > 0:
                        top_cols = col_data.groupby("COLUMN_NAME").size().reset_index(name="Failures")
                        top_cols = top_cols.sort_values("Failures", ascending=False).head(10)
                        c_chart = alt.Chart(top_cols).mark_bar(cornerRadiusEnd=4, color=COLOR_WARN).encode(
                            x=alt.X("Failures:Q"),
                            y=alt.Y("COLUMN_NAME:N", sort="-x", title=None),
                            tooltip=["COLUMN_NAME", "Failures"]
                        ).properties(height=220)
                        st.altair_chart(c_chart)

        # Run History Trend
        if len(df_runs) > 1:
            with st.container(border=True):
                st.markdown("**Health score trend across runs**")
                df_runs_plot = df_runs.copy()
                df_runs_plot["HEALTH_PCT"] = round(
                    df_runs_plot["PASSED"] / df_runs_plot["TOTAL_RULES"] * 100, 1
                )
                trend = alt.Chart(df_runs_plot).mark_area(
                    line=True, opacity=0.3, color=COLOR_PASS
                ).encode(
                    x=alt.X("RUN_TIME:T", title="Run time"),
                    y=alt.Y("HEALTH_PCT:Q", title="Health %", scale=alt.Scale(domain=[0, 100])),
                    tooltip=["RUN_TIME:T", "HEALTH_PCT:Q", "PASSED:Q", "FAILED:Q"]
                ).properties(height=200)

                rule_line = alt.Chart(pd.DataFrame({"y": [80]})).mark_rule(
                    strokeDash=[4, 4], color=COLOR_WARN
                ).encode(y="y:Q")

                st.altair_chart(trend + rule_line)
    else:
        st.warning("No data available. Run the DQ framework first.", icon=":material/info:")

# ===== TAB 2: RULE RESULTS =====
with tab_results:
    if len(df_filtered) > 0:
        st.markdown("### Detailed rule results")

        with st.container(horizontal=True):
            st.metric("Executions", len(df_filtered), border=True)
            st.metric("Unique rules", df_filtered["RULE_ID"].nunique(), border=True)
            avg_pass = df_filtered["PASS_PERCENTAGE"].mean()
            st.metric("Avg pass %", f"{avg_pass:.1f}%", border=True)

        # Results dataframe with progress bars
        display_df = df_filtered[[
            "TABLE_NAME", "COLUMN_NAME", "RULE_NAME", "RULE_TYPE",
            "RESULT_STATUS", "SEVERITY", "ACTUAL_VALUE", "TOTAL_RECORD_COUNT",
            "PASS_PERCENTAGE", "EXECUTED_AT"
        ]].copy()

        st.dataframe(
            display_df.sort_values(["RESULT_STATUS", "SEVERITY"], ascending=[True, True]),
            column_config={
                "PASS_PERCENTAGE": st.column_config.ProgressColumn(
                    "Pass %", min_value=0, max_value=100, format="%.1f%%"
                ),
                "ACTUAL_VALUE": st.column_config.NumberColumn("Failures", format="%d"),
                "TOTAL_RECORD_COUNT": st.column_config.NumberColumn("Total rows", format="%d"),
                "EXECUTED_AT": st.column_config.DatetimeColumn("Executed", format="MMM DD, HH:mm"),
            },
            hide_index=True,
        )

        # Drill-down
        st.markdown("### :material/search: Table drill-down")
        selected_table = st.selectbox("Select a table", tables, index=0)

        if selected_table:
            table_data = df_latest[df_latest["TABLE_NAME"] == selected_table]

            if len(table_data) > 0:
                t_passed = len(table_data[table_data["RESULT_STATUS"] == "PASSED"])
                t_failed = len(table_data[table_data["RESULT_STATUS"] == "FAILED"])
                t_total = len(table_data)
                t_health = round((t_passed / t_total) * 100, 1) if t_total > 0 else 0

                with st.container(horizontal=True):
                    st.metric("Table health", f"{t_health}%", border=True)
                    st.metric("Passed", t_passed, border=True)
                    st.metric("Failed", t_failed, border=True)

                # Failed rules detail
                table_failed = table_data[table_data["RESULT_STATUS"] == "FAILED"]
                if len(table_failed) > 0:
                    st.markdown("**:material/error: Failed rules**")
                    st.dataframe(
                        table_failed[["RULE_NAME", "COLUMN_NAME", "SEVERITY", "ACTUAL_VALUE", "PASS_PERCENTAGE"]],
                        column_config={
                            "PASS_PERCENTAGE": st.column_config.ProgressColumn(
                                "Pass %", min_value=0, max_value=100, format="%.1f%%"
                            ),
                            "ACTUAL_VALUE": st.column_config.NumberColumn("Failures", format="%d"),
                        },
                        hide_index=True,
                    )
                else:
                    st.success("All rules passing for this table!", icon=":material/check_circle:")

                # Error records
                if len(df_errors) > 0:
                    table_errors = df_errors[df_errors["TABLE_NAME"] == selected_table]
                    if len(table_errors) > 0:
                        with st.expander(":material/bug_report: Sample error records", expanded=False):
                            st.dataframe(
                                table_errors[["RULE_ID", "ERROR_REASON", "ERROR_RECORD_VARIANT"]].head(10),
                                hide_index=True,
                            )

                # Recommendations
                if len(table_failed) > 0:
                    with st.expander(":material/lightbulb: Recommended fixes", expanded=True):
                        for _, row in table_failed.iterrows():
                            col_name = row["COLUMN_NAME"] if pd.notna(row["COLUMN_NAME"]) else "N/A"
                            st.markdown(
                                f"- **{row['RULE_NAME']}** — `{col_name}` — "
                                f"{int(row['ACTUAL_VALUE'])} violation(s). "
                                f"Investigate and correct records in `{selected_table}`."
                            )
    else:
        st.warning("No results match the current filters.", icon=":material/filter_list:")

# ===== TAB 3: ANOMALIES =====
with tab_anomalies:
    st.markdown("### :material/warning: Anomaly detection")

    if len(df_anomalies) > 0:
        detected = len(df_anomalies[df_anomalies["ANOMALY_STATUS"] == "ANOMALY_DETECTED"])
        new_fail = len(df_anomalies[df_anomalies["ANOMALY_STATUS"] == "NEW_FAILURE"])

        with st.container(horizontal=True):
            st.metric("Total anomalies", len(df_anomalies), border=True)
            st.metric("Statistical anomalies", detected, border=True)
            st.metric("New failures", new_fail, border=True)

        # Anomaly by status chart
        with st.container(border=True):
            st.markdown("**Anomaly distribution**")
            anom_status = df_anomalies["ANOMALY_STATUS"].value_counts().reset_index()
            anom_status.columns = ["Status", "Count"]
            anom_chart = alt.Chart(anom_status).mark_bar(cornerRadiusEnd=4).encode(
                x=alt.X("Status:N", axis=alt.Axis(labelAngle=0)),
                y=alt.Y("Count:Q"),
                color=alt.Color("Status:N", scale=alt.Scale(
                    domain=["ANOMALY_DETECTED", "NEW_FAILURE"],
                    range=[COLOR_FAIL, COLOR_WARN]
                ), legend=None),
                tooltip=["Status", "Count"]
            ).properties(height=200)
            st.altair_chart(anom_chart)

        # Anomaly details table
        st.markdown("**Anomaly details**")
        st.dataframe(
            df_anomalies[[
                "TABLE_NAME", "METRIC_NAME", "CURRENT_VALUE", "PREVIOUS_VALUE",
                "BASELINE_AVG", "ANOMALY_STATUS", "ANOMALY_REASON", "DETECTED_AT"
            ]],
            column_config={
                "CURRENT_VALUE": st.column_config.NumberColumn("Current", format="%d"),
                "PREVIOUS_VALUE": st.column_config.NumberColumn("Previous", format="%d"),
                "BASELINE_AVG": st.column_config.NumberColumn("Baseline avg", format="%.2f"),
                "DETECTED_AT": st.column_config.DatetimeColumn("Detected", format="MMM DD, HH:mm"),
            },
            hide_index=True,
        )
    else:
        st.info(
            "No anomalies detected yet. Anomalies are flagged after 2+ runs "
            "establish a baseline (2-sigma deviation model).",
            icon=":material/info:",
        )

# ===== TAB 4: COVERAGE =====
with tab_coverage:
    st.markdown("### :material/verified: Rule coverage")

    if len(df_config) > 0:
        total_active = len(df_config[df_config["IS_ACTIVE"] == True])
        tables_covered = df_config["TABLE_NM"].nunique()

        with st.container(horizontal=True):
            st.metric("Total rules", len(df_config), border=True)
            st.metric("Active rules", total_active, border=True)
            st.metric("Tables covered", tables_covered, border=True)

        # Coverage charts
        col1, col2 = st.columns(2)

        with col1:
            with st.container(border=True):
                st.markdown("**Rules per table**")
                rules_per_table = df_config.groupby("TABLE_NM").size().reset_index(name="Rules")
                rpt_chart = alt.Chart(rules_per_table).mark_bar(cornerRadiusEnd=4, color=COLOR_INFO).encode(
                    x=alt.X("Rules:Q"),
                    y=alt.Y("TABLE_NM:N", sort="-x", title=None),
                    tooltip=["TABLE_NM", "Rules"]
                ).properties(height=220)
                st.altair_chart(rpt_chart)

        with col2:
            with st.container(border=True):
                st.markdown("**Rules by criticality**")
                crit_data = df_config["CRITICALITY"].value_counts().reset_index()
                crit_data.columns = ["Criticality", "Count"]
                crit_chart = alt.Chart(crit_data).mark_arc(innerRadius=50, outerRadius=90).encode(
                    theta=alt.Theta("Count:Q"),
                    color=alt.Color("Criticality:N", scale=alt.Scale(
                        domain=["HIGH", "MEDIUM", "LOW"],
                        range=[COLOR_FAIL, COLOR_WARN, COLOR_INFO]
                    ), legend=alt.Legend(orient="bottom")),
                    tooltip=["Criticality", "Count"]
                ).properties(height=220)
                st.altair_chart(crit_chart)

        # Heatmap: Rules x Table x Type
        with st.container(border=True):
            st.markdown("**Coverage heatmap (table vs rule type)**")
            heat_data = df_config.groupby(["TABLE_NM", "RULE_TYPE"]).size().reset_index(name="Count")
            heatmap = alt.Chart(heat_data).mark_rect(cornerRadius=4).encode(
                x=alt.X("RULE_TYPE:N", title="Rule type", axis=alt.Axis(labelAngle=0)),
                y=alt.Y("TABLE_NM:N", title=None),
                color=alt.Color("Count:Q", scale=alt.Scale(scheme="blues"), title="Rules"),
                tooltip=["TABLE_NM", "RULE_TYPE", "Count"]
            ).properties(height=220)
            st.altair_chart(heatmap)

        # Full config table
        st.markdown("**All configured rules**")
        st.dataframe(
            df_config[["RULE_ID", "RULE_NAME", "RULE_TYPE", "CRITICALITY", "TABLE_NM", "COLUMN_NM", "IS_ACTIVE"]],
            column_config={
                "IS_ACTIVE": st.column_config.CheckboxColumn("Active"),
            },
            hide_index=True,
        )
    else:
        st.warning("No rules configured yet.", icon=":material/info:")

# Footer
st.caption("Data Quality Monitoring Dashboard | BANKING_DQ_DB | Powered by Snowflake")
