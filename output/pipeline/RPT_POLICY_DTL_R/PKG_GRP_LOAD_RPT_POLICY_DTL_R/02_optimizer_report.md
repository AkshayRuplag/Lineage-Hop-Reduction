# PL/SQL Optimization Opportunity Report — PKG_GRP_LOAD_RPT_POLICY_DTL_R
Generated: 2026-08-04  
Mode: **A — Post-Merger scan**  
Input file: `01_merged.sql`  
Registry recs already applied by Merger: M-0028, M-0031+M-0058+M-0073+M-0074 (compound), M-0053a  
Deferred by Merger: M-0053b (v_policy_case_size_r — analyst review pending)

---

## ⚠️ BLOCKING DEFECT — Merger Gap (Fix Required Before Proceeding)

> The Merger introduced a **syntax defect** and a **missing column** in `01_merged.sql` while inserting the M-0053b deferral comment.  
> The merged file **will not compile** as-is. This must be corrected before optimizations are applied.

### MGAP-1 — Broken `v_policy_case_size_r` CASE + Dropped `v_bill_option_r` Column

| Field | Value |
|-------|-------|
| File | `01_merged.sql`, lines 1780–1801 |
| Source reference | `00_source.sql`, lines 1846–1867 |
| Severity | **CRITICAL — syntax error, compile failure** |

**Root cause:**  
When the M-0053b deferral comment was injected, the Merger replaced two lines in the source:
1. The `, TO_CHAR(fct_grp_billing_policy_dtl_r.n_billing_option_value_r)  AS v_bill_option_r` alias (dropping the `AS v_bill_option_r` tail and the column from the SELECT list).
2. The `, CASE\n     WHEN fct_grp_policy_r.v_smartchoice_ind_r` opening of the next CASE expression (dropping `CASE WHEN fct_grp_policy_r.v_smartchoice_ind_r`).

**Source (correct):**
```sql
, TO_CHAR(fct_grp_billing_policy_dtl_r.n_billing_option_value_r)      AS v_bill_option_r
, CASE
     WHEN fct_grp_policy_r.v_smartchoice_ind_r = 'Y'
     THEN 'Smart Choice'
     ...
   END AS v_policy_case_size_r
```

**Merged (defective):**
```sql
, TO_CHAR(fct_grp_billing_policy_dtl_r.n_billing_option_value_r)      -- M-0053: deferred ...
 = 'Y'
     THEN 'Smart Choice'
     ...
   END AS v_policy_case_size_r
```

**Required fix:**
```sql
, TO_CHAR(fct_grp_billing_policy_dtl_r.n_billing_option_value_r)      AS v_bill_option_r
  -- M-0053b: DEFERRED — v_policy_case_size_r first WHEN uses v_smartchoice_ind_r = 'Y' flag
  -- override (not pure range); REF table design requires analyst sign-off before conversion.
, CASE
     WHEN fct_grp_policy_r.v_smartchoice_ind_r = 'Y'
     THEN 'Smart Choice'
     WHEN fct_grp_policy_r.n_policy_lives_r < 100
     THEN '<100'
     ...
   END AS v_policy_case_size_r
```

---

## Already Handled by Merger

| Category | Rec Applied | What Was Done |
|----------|-------------|---------------|
| O. Hybrid Naming | M-0028 | `FCT_RPT_CROSS_SELL_SUMMARY_R` → `STG_CROSS_SELL_SUMMARY_R` in `cur_upd_cross_sell_col` |
| O. GTT Elimination | M-0031 | `DIM_PLAN_DESIGN_DIRECTORY_R_GTT` eliminated; `prc_load_data_dim_gtt` procedure removed |
| P. Post-Load Cursor UPDATE | M-0058 | 8 GTT-dependent cursors rewritten to query `DIM_PLAN_DESIGN_DIRECTORY_R` directly |
| N. Circular Dependency | M-0073+M-0074 | Circular update chain dissolved; GTT load/call block removed |
| Q. Hardcoded Mapping | M-0053a | `v_line_of_business_group_r` CASE (7 branches) → `REF_LINE_OF_BUSINESS_GROUP_MAP` LEFT JOIN |
| Q. Hardcoded Mapping | M-0053b | `v_policy_case_size_r` — **DEFERRED** (analyst review); comment added in SQL |

The discovery scan flags **REMAINING** opportunities only. The patterns above are not re-raised.

---

## 1. Script Classification

| Field | Value |
|-------|-------|
| Script Type | Package Body |
| Primary Opt Area | Mixed: SQL query (INSERT SELECT) + PL/SQL procedural (18 UPDATE cursors) |
| Risk Level | MEDIUM |
| Reason | Multiple large-table scans with correlated subqueries, repeated table accesses across 8 similar cursors, and one blocking syntax defect |

---

## 2. Executive Summary

| Metric | Value |
|--------|-------|
| Blocking defect (Merger Gap) | **1 — must fix before compile** |
| Total new opportunities found | **14** |
| High priority | 3 (OPP-01, OPP-02, OPP-03) |
| Medium priority | 6 (OPP-04 through OPP-09) |
| Low priority | 5 (OPP-10 through OPP-14) |
| Safe to apply directly | 8 (OPP-02, OPP-03, OPP-04, OPP-05, OPP-06, OPP-07, OPP-08, OPP-12) |
| Conditionally Safe | 3 (OPP-09, OPP-11, OPP-13) |
| Cursor Consolidation (delegate to Optimizer-Cursor) | 1 group of 8 cursors (OPP-01) |
| Unsafe (evidence required) | 1 (OPP-10 — needs execution plan) |
| Index candidates (DBA action, no DDL) | 3 (OPP-15, OPP-16, OPP-17) |
| Main performance risk | Correlated scalar subquery in `FCT_GRP_BILLING_POLICY_DTL_R` inline view (executes once per billing row) |
| Main consolidation opportunity | 8 `DIM_PLAN_DESIGN_DIRECTORY_R` cursors sharing identical source/join/version filter |

---

## 3. Optimization Opportunities

| ID | Priority | Area | Sub-Type | Object / Block | Current Pattern | Issue | Recommended Direction | Safety | Evidence Level | Risk | Validation Needed |
|----|----------|------|----------|----------------|-----------------|-------|----------------------|--------|----------------|------|-------------------|
| OPP-01 | High | Cursor Consolidation | 8-cursor same-source consolidation | `PRC_UPD_COL_DETAILS`: cur_upd_theft_ind_col, cur_upd_theft_dt_col, cur_upd_prs_strs_ind_r, cur_upd_elimperiod_col, cur_upd_eap_desc_col, cur_upd_bereave_desc_col, cur_upd_eap_eff_date_col, cur_upd_bereavedate_col | 8 separate cursors each scan `FCT_PLAN_DESIGN_SUMMARY_R` + `DIM_PLAN_DESIGN_DIRECTORY_R` with identical join/filter/scalar-subquery, differing only by `v_coverage_code_r` value | 8 full scans of large tables + 8 × correlated scalar subquery executing per row | Consolidate into 1 pass with conditional `MAX(CASE WHEN v_coverage_code_r = '...')` aggregation; convert correlated scalar subquery to `JOIN DIM_GRP_POLICY_DIR_R`; separate Group B (eap_desc + bereave_desc, dual GROUP BY) if needed | Conditionally Safe | Code only | HIGH | (a) eap_desc/bereave_desc cursors group by COVERAGE_CODE_R — split into Group A (6 cursors) and Group B (2 cursors); (b) theft_dt date-parse PL/SQL loop must be preserved |
| OPP-02 | High | SQL | Correlated scalar subquery → ROW_NUMBER | `prc_get_cur_data` — `FCT_GRP_BILLING_POLICY_DTL_R` inline view | `WHERE a.T_EVENT_TIMESTAMP_R = (SELECT MAX(T_EVENT_TIMESTAMP_R) FROM FCT_GRP_BILLING_POLICY_DTL_R B WHERE A.N_POLICY_SK_R = B.N_POLICY_SK_R ...)` | Correlated scalar subquery executes once per row of `FCT_GRP_BILLING_POLICY_DTL_R`; for N policies = N subquery executions | Replace with `ROW_NUMBER() OVER (PARTITION BY N_POLICY_SK_R ORDER BY T_EVENT_TIMESTAMP_R DESC)` and filter `RNK = 1` | Safe | Code only | MEDIUM | Confirm `D_DELETE_DATE_R IS NULL` filters are preserved in both the outer and inner SELECT |
| OPP-03 | High | SQL | Non-sargable predicate | `cur_upd_inforceindicator_cols` | `TO_CHAR(a.D_CYCLE_DATE_R, 'YYYYMM') = gn_current_month` | `TO_CHAR` applied to date column prevents index usage on `FCT_RPT_ANN_PREM_SUMMARY_R.D_CYCLE_DATE_R`; additionally `gn_current_month` is NUMBER so implicit VARCHAR2→NUMBER conversion occurs | Replace with sargable range: `a.D_CYCLE_DATE_R >= TRUNC(gd_sysdate,'MM') AND a.D_CYCLE_DATE_R < ADD_MONTHS(TRUNC(gd_sysdate,'MM'), 1)` | Safe | Code only | LOW | Verify `D_CYCLE_DATE_R` data type is `DATE` (not VARCHAR2); confirm the range correctly covers the current month's cycle dates |
| OPP-04 | Medium | SQL | Redundant EXISTS | `cur_upd_inforceindicator_cols` | `FROM (...) a, RPT_POLICY_DTL_R b WHERE a.n_policy_sk_r = b.n_policy_sk_r AND b.n_yearmonth_r = gn_current_month AND EXISTS (SELECT 1 FROM rpt_policy_dtl_r policy WHERE policy.n_policy_sk_r = a.n_policy_sk_r AND policy.n_yearmonth_r = gn_current_month)` | The `EXISTS (SELECT 1 FROM rpt_policy_dtl_r ...)` is identical to the already-present `JOIN rpt_policy_dtl_r b` — Oracle must evaluate both; the EXISTS adds a redundant semi-join step | Remove the trailing `AND EXISTS (SELECT 1 FROM rpt_policy_dtl_r policy ...)` block entirely | Safe | Code only | NONE | Confirm the `b` join and the EXISTS reference the same table and same partition filter |
| OPP-05 | Medium | SQL | DISTINCT+GROUP BY redundancy | `prc_get_cur_data` — `POLICY_DIR_EFF_DATE` inline view | `SELECT DISTINCT N_POLICY_SK_R, V_POLICY_NUMBER_R, MIN(CASE...) ... FROM DIM_GRP_POLICY_DIR_R GROUP BY N_POLICY_SK_R, V_POLICY_NUMBER_R` | `DISTINCT` is always redundant on a `GROUP BY` result (GROUP BY already deduplicates); adds an unnecessary sort/hash pass | Remove the `DISTINCT` keyword; leave `GROUP BY` intact | Safe | Code only | NONE | None |
| OPP-06 | Medium | PL/SQL | Bare WHEN OTHERS THEN NULL | `PRC_UPD_COL_DETAILS` — `cur_upd_theft_dt_col` loop inner block | `EXCEPTION WHEN OTHERS THEN NULL;` inside date-parse block | Silently swallows all errors; if `v_override_description_r` contains a non-parseable date string the row is silently updated with NULL and no trace is logged | Replace with: `EXCEPTION WHEN OTHERS THEN ld_theft_dt := NULL; -- unexpected format: log if needed` or at minimum log `SQLERRM` to `gv_errmsg` | Safe | Code only | LOW | Confirm that silent NULL-substitution for unparseable dates is the intended business rule |
| OPP-07 | Medium | PL/SQL | SELECT FROM DUAL inside loop (context switch) | `PRC_UPD_COL_DETAILS` — `cur_upd_theft_dt_col` loop | `SELECT TO_DATE(LT_VAR_UPD_TBL_THEFT_DT_TYP_REC(x).v_override_description_r,'MM/DD/YYYY') INTO ld_theft_dt FROM DUAL;` inside a `FOR x IN ... LOOP` | Each iteration issues a SQL context switch to the SQL engine for a trivial `SELECT FROM DUAL`; with `gn_bulk_coll_cnt = 50,000` this is up to 50,000 context switches per batch | Replace with direct PL/SQL assignment: `ld_theft_dt := TO_DATE(LT_VAR_UPD_TBL_THEFT_DT_TYP_REC(x).v_override_description_r, 'MM/DD/YYYY');` inside the exception block | Safe | Code only | NONE | None — PL/SQL `TO_DATE` raises the same exceptions as the SQL engine version |
| OPP-08 | Medium | PL/SQL | Missing cursor CLOSE | `PRC_UPD_COL_DETAILS` — `cur_upd_client_dtls` loop | `OPEN cur_upd_client_dtls; LOOP ... EXIT WHEN cur_upd_client_dtls%NOTFOUND; END LOOP;` — no `CLOSE cur_upd_client_dtls;` | All other 17 cursors in the procedure are explicitly closed; only `cur_upd_client_dtls` is missing its `CLOSE`. While the cursor auto-closes when the procedure ends, explicit closure is required for consistency and in case the procedure is refactored to loop or retry | Add `CLOSE cur_upd_client_dtls;` after the loop | Safe | Code only | LOW | None |
| OPP-09 | Medium | SQL | Missing EXISTS/join filter on staging table | `cur_upd_d_rate_guar_r_col` | `SELECT d_rate_guar_r, n_policy_sk_r FROM stg_perf_ameritas_renewal_info GROUP BY d_rate_guar_r, n_policy_sk_r` — no predicate restricting to current month's policies | All rows in `STG_PERF_AMERITAS_RENEWAL_INFO` are fetched and materialized in the collection, even for policy SKs that have no matching row in `RPT_POLICY_DTL_R` for the current month; the UPDATE WHERE clause discards non-matching rows but the fetch wasted I/O | Add: `AND EXISTS (SELECT 1 FROM RPT_POLICY_DTL_R rpt WHERE rpt.n_policy_sk_r = stg_perf_ameritas_renewal_info.n_policy_sk_r AND rpt.n_yearmonth_r = gn_current_month)` | Conditionally Safe | Code only | LOW | Confirm `STG_PERF_AMERITAS_RENEWAL_INFO` has `N_POLICY_SK_R` with the same datatype as `RPT_POLICY_DTL_R.N_POLICY_SK_R`; confirm no business reason to update non-active-month policies |
| OPP-10 | Medium | SQL | Dual scan of FCT_GRP_TRANSACTIONS_R | `cur_upd_nxtrenewaldt_col` | `FROM fct_grp_policy_r, dim_grp_policy_dir_r, fct_grp_transactions_r ft WHERE EXISTS (SELECT 1 FROM fct_grp_transactions_r fgtr WHERE ... AND fgtr.V_BUS_OBJ_STATUS_R = 'ACTIVE')` | `fct_grp_transactions_r` is scanned twice: once as `ft` (no STATUS filter) and once in the EXISTS as `fgtr` (STATUS = ACTIVE); the `ft` join multiplies rows for non-ACTIVE versions before the EXISTS filters them, potentially causing row multiplication and inflating the RANK() denominator | Evaluate merging the `ft` join with the ACTIVE filter — add `AND ft.V_BUS_OBJ_STATUS_R = 'ACTIVE'` to the `ft` join conditions, then remove the separate EXISTS | Unsafe — Evidence Required | Execution plan + row-count check required | MEDIUM | Execute EXPLAIN PLAN; verify row counts before and after adding STATUS filter to `ft`; confirm no downstream GROUP BY or RANK behavior changes |
| OPP-11 | Low | PL/SQL | Dead commented-out variables in MAIN | `MAIN` procedure IS block | `lc_var_ref_cur SYS_REFCURSOR`, `lt_var_tbl_type IS TABLE OF RPT_POLICY_DTL_R%ROWTYPE`, `lt_var_tbl_type_rec`, `lt_insert_time`, `ln_loop_counter` — all declared but used only in the kill/fill commented LOOP block | Kill/Fill changes commented out the original BULK COLLECT insert loop, leaving 5 variables declared but unreferenced in active code | Remove the 5 dead declarations (or retain them in a comment block marked "kill/fill: retained for incremental conversion") | Conditionally Safe | Code only | LOW | Confirm the commented LOOP block is truly deprecated and will not be re-enabled; if it may be re-enabled, keep declarations but annotate clearly |
| OPP-12 | Low | SQL | ORDER BY inside inline view (no functional effect) | `cur_upd_nxtrenewaleffdt_col` — `ft2` inline view | `(SELECT ... FROM fct_grp_transactions_r WHERE V_VERSION_TYPE_R IN ('RENEWAL','NEWBUS') ORDER BY N_TXN_VERSION_NUMBER_R DESC) ft2` | Oracle ignores `ORDER BY` inside an inline view without `ROWNUM`/`FETCH FIRST`; the outer query uses `MAX(ft2.d_effective_r)` so the ORDER BY has zero effect and adds a misleading sort hint to the optimizer | Remove the `ORDER BY N_TXN_VERSION_NUMBER_R DESC` from the ft2 inline view | Safe | Code only | NONE | None |
| OPP-13 | Low | Alternative Design | Repeated complex expression (5 occurrences) | `prc_get_cur_data` — `V_CARRIER_NAME_TAX_R` CASE expression | The `NVL(fct_grp_policy_r.v_carrier_name_r, CASE WHEN v_administered_by_r = 'RSL' THEN '...' WHEN v_administered_by_r = 'FRSLIC' THEN '...' ELSE NULL END)` expression is repeated verbatim 5 times within the `V_CARRIER_NAME_TAX_R` CASE block | Each repetition is an independent NVL+CASE evaluation; no risk of wrong results but adds verbosity, maintenance risk, and limits optimizer reuse | Factor into a `CROSS APPLY` or compute once in an additional inline view or CTE | Conditionally Safe | Code only | LOW | Verify carrier name CASE logic is identical in all 5 occurrences before factoring |
| OPP-14 | Low | PL/SQL | Inconsistent BULK COLLECT LIMIT | `PRC_UPD_COL_DETAILS` — `cur_upd_agencycode_cols` loop | `FETCH cur_upd_agencycode_cols BULK COLLECT INTO lt_var_upd_tbl_agencycode_typ_rec LIMIT 10000` | Hard-coded `10000` while all other cursors use the global constant `gn_bulk_coll_cnt = 50000`; results in 5× more round-trips for the agency code cursor; also bypasses the global tuning knob | Change `LIMIT 10000` to `LIMIT gn_bulk_coll_cnt` | Safe | Code only | NONE | None |

---

## Index Candidates (DBA Actions — No DDL Generated)

| ID | Priority | Table | Proposed Index Columns | Driving Query | Expected Benefit | Status |
|----|----------|-------|----------------------|---------------|-----------------|--------|
| OPP-15 | High | `FCT_RPT_ANN_PREM_SUMMARY_R` | `(D_CYCLE_DATE_R, N_POLICY_SK_R)` | `cur_upd_inforceindicator_cols` GROUP BY after OPP-03 fix | Enables partition pruning / range scan after predicate is made sargable (OPP-03) | Candidate — confirm selectivity and existing indexes |
| OPP-16 | Medium | `DIM_GRP_WRKFLW_ACTIVITY_DTLS_R` | `(V_ACTION_DESCRIPTION_R, V_ACTIVE_STATUS_R, N_POLICY_SK_R, D_BUSINESS_EFF_START_DATE_R)` | `cur_upd_submission_dt` — filter on ACTION_DESCRIPTION_R = 'SOLDQUOTE', ACTIVE_STATUS_R = 'Y', EXISTS on N_POLICY_SK_R | Index-only access for the MAX(D_BUSINESS_EFF_START_DATE_R) aggregation | Candidate — DBA action |
| OPP-17 | Low | `STG_CROSS_SELL_SUMMARY_R` | `(N_POLICY_SK_R, N_YEARMONTH_R)` | `cur_upd_cross_sell_col` join key + filter | After M-0028 rename, verify that the index from `FCT_RPT_CROSS_SELL_SUMMARY_R` was carried forward; if not, create it | Candidate — verify index exists post-rename |

---

## 4. Top Recommendations

1. **Fix MGAP-1 immediately** (blocking syntax defect before any code changes).
2. **OPP-02** (correlated scalar subquery → ROW_NUMBER in billing inline view) — highest single-query performance gain; Safe; directly applyable.
3. **OPP-01** (8-cursor DIM_PLAN_DESIGN_DIRECTORY_R consolidation) — highest overall I/O reduction; delegate to PL/SQL Optimizer-Cursor; approach: Group A (6 simple cursors) → single conditional-aggregation pass; Group B (eap_desc + bereave_desc) → separate pass.
4. **OPP-03 + OPP-04** together (non-sargable + redundant EXISTS in `cur_upd_inforceindicator_cols`) — both are Safe and in the same cursor; apply in one edit.
5. **OPP-06 + OPP-07** together (bare WHEN OTHERS + SELECT FROM DUAL in same loop) — apply in one edit; significant improvement to the theft_dt date-parse block.
6. **OPP-08** (missing CLOSE for cur_upd_client_dtls) — trivial one-line fix; apply immediately.
7. **OPP-05 + OPP-12 + OPP-14** — all trivial Safe changes; batch in one edit.

---

## 5. Evidence Required Before Applying

| OPP | Evidence Needed | How to Obtain |
|-----|----------------|---------------|
| OPP-01 | Confirm Group A cursors produce exactly 1 row per N_POLICY_SK_R after consolidation; verify `IDTHEFTEFFDATE` NULL filter semantics; validate that the date-parse step for theft_dt still works correctly post-consolidation | Run both old and consolidated SQL against a dev snapshot; compare UPDATE counts and sample values |
| OPP-10 | Execution plan for `cur_upd_nxtrenewaldt_col`; row count of `fct_grp_transactions_r ft` join before/after adding STATUS filter | `EXPLAIN PLAN FOR SELECT ...` plus `SELECT COUNT(*)` diff |
| OPP-09 | Confirm `STG_PERF_AMERITAS_RENEWAL_INFO.N_POLICY_SK_R` datatype matches RPT; confirm no multi-month policies in staging table | `DESC STG_PERF_AMERITAS_RENEWAL_INFO` |
| OPP-13 | Verify all 5 carrier_name NVL expressions are semantically identical before factoring | Manual diff of the 5 occurrences in the CASE block |

---

## 6. Approval

```
Optimizer scan complete for `PKG_GRP_LOAD_RPT_POLICY_DTL_R`.

BLOCKING DEFECT (must fix regardless of approval):
  MGAP-1 [Merger Gap]  — Broken v_policy_case_size_r CASE + dropped v_bill_option_r column

Ready to apply (Safe / Conditionally Safe):
  OPP-02 [Safe]               — Correlated scalar subquery → ROW_NUMBER in billing inline view
  OPP-03 [Safe]               — Non-sargable TO_CHAR on D_CYCLE_DATE_R → sargable range
  OPP-04 [Safe]               — Remove redundant EXISTS in cur_upd_inforceindicator_cols
  OPP-05 [Safe]               — Remove DISTINCT from POLICY_DIR_EFF_DATE GROUP BY inline view
  OPP-06 [Safe]               — Replace bare WHEN OTHERS THEN NULL in theft_dt block
  OPP-07 [Safe]               — SELECT FROM DUAL → direct PL/SQL assignment in theft_dt loop
  OPP-08 [Safe]               — Add CLOSE cur_upd_client_dtls after loop
  OPP-09 [Conditionally Safe] — Add EXISTS filter to cur_upd_d_rate_guar_r_col
  OPP-11 [Conditionally Safe] — Remove/annotate dead variables in MAIN
  OPP-12 [Safe]               — Remove ORDER BY from ft2 inline view
  OPP-13 [Conditionally Safe] — Factor repeated carrier_name NVL expression
  OPP-14 [Safe]               — Change LIMIT 10000 → LIMIT gn_bulk_coll_cnt

Delegate to PL/SQL Optimizer-Cursor:
  OPP-01 [Conditionally Safe] — 8-cursor DIM_PLAN_DESIGN_DIRECTORY_R consolidation

Deferred / DBA actions (no code change):
  OPP-10 [Unsafe]             — Dual FCT_GRP_TRANSACTIONS_R scan in cur_upd_nxtrenewaldt_col (evidence required)
  OPP-15 [Candidate]          — Index on FCT_RPT_ANN_PREM_SUMMARY_R (DBA action)
  OPP-16 [Candidate]          — Index on DIM_GRP_WRKFLW_ACTIVITY_DTLS_R (DBA action)
  OPP-17 [Candidate]          — Verify index on STG_CROSS_SELL_SUMMARY_R (DBA action)

Which opportunities to apply?
(all / none / MGAP-1,OPP-02,OPP-03 / skip)
```
