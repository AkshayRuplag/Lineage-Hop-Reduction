# Pipeline Decisions — PKG_GRP_LOAD_RPT_POLICY_DTL_R

**RPT:** RPT_POLICY_DTL_R  |  **Rank:** 2  |  **Tier:** 1  |  **Scope:** GLOBAL

## Recommendations

- M-0028 | O. Hybrid Naming Convention Violation | ✅ Consider
- M-0031 | O. GTT Intra-Procedure Staging — Evaluate CTE Replacement | ✅ Consider
- M-0053 | Q. Hardcoded Value Mapping — Externalize to Lookup Table | ✅ Consider
- M-0058 | P. Post-Load Cursor UPDATE — Fold into INSERT | ✅ Consider
- M-0073 | N. Circular Update Chain (Post-Load Self-Reference) | ✅ Consider
- M-0074 | N. Circular Update Chain (Post-Load Self-Reference) | ✅ Consider

## Stage Log

| Stage | Date | Decision | Notes |
|-------|------|----------|-------|
| Stage 1 — Merger | 2026-08-04 | PL/SQL Merger | ✅ Complete — M-0028, M-0031+M-0058+M-0073+M-0074 (compound), M-0053a applied. M-0053b (v_policy_case_size_r) deferred — analyst review pending. Output: 01_merged.sql |
| Stage 2 — Optimizer | 2026-08-04 | PL/SQL Optimizer | ✅ Complete — MGAP-1 fixed + OPP-02,03,04,05,06,07,08,12,14 applied. OPP-14 semicolon patched by Planner. 02_optimized.sql written. OPP-01 deferred. OPP-10 blocked (unsafe). |
| Stage 3 — Standardize | 2026-08-04 | PL/SQL Standardize | ✅ Complete — 9 violations fixed (2 CRITICAL compile errors, 2 HIGH, 3 MED, 2 LOW). STD-07/08 deferred. 03_standardized.sql written. |

## Stage 2 Optimizer Decisions (Mode A)

### Applied
- MGAP-1: Fixed broken `v_policy_case_size_r` CASE / restored `v_bill_option_r` (Merger comment misplacement)
- OPP-02: `FCT_GRP_BILLING_POLICY_DTL_R` scalar subquery → `ROW_NUMBER()`
- OPP-03: Non-sargable `TO_CHAR(D_CYCLE_DATE_R)` filter → sargable range predicate
- OPP-04: Redundant `EXISTS(RPT_POLICY_DTL_R)` removed from `cur_upd_inforceindicator_cols`
- OPP-05: `SELECT DISTINCT` removed from `POLICY_DIR_EFF_DATE` inline view (redundant with GROUP BY)
- OPP-06: `WHEN OTHERS THEN NULL` → log + non-fatal continue in theft-date parse block
- OPP-07: `SELECT TO_DATE FROM DUAL` inside loop → direct PL/SQL assignment
- OPP-08: Added `CLOSE cur_upd_client_dtls`
- OPP-12: Removed ORDER BY from `ft2` inline view in `cur_upd_nxtrenewaleffdt_col`
- OPP-14: `LIMIT 10000` → `LIMIT gn_bulk_coll_cnt` in `cur_upd_agencycode_cols` (semicolon fix by Planner)

### Deferred to Standardizer
- OPP-11: Dead variables cleanup
- OPP-13: Repeated NVL carrier-name expression

### Not applied
- OPP-01: Cursor consolidation — Conditionally Safe; pending Optimizer-Cursor sub-agent
- OPP-09: Current-month filter for `STG_PERF_AMERITAS_RENEWAL_INFO` — needs analysis
- OPP-10: `FCT_GRP_TRANSACTIONS_R` double-scan — Unsafe; needs execution plan evidence
- OPP-15/16/17: DBA index candidates — flagged, no code change

### DBA actions flagged
- OPP-15: Consider index on `FCT_RPT_ANN_PREM_SUMMARY_R(D_CYCLE_DATE_R, N_POLICY_SK_R)`
- OPP-16: Consider index on `DIM_GRP_WRKFLW_ACTIVITY_DTLS_R(V_ACTION_DESCRIPTION_R, V_ACTIVE_STATUS_R)`
- OPP-17: Verify `STG_CROSS_SELL_SUMMARY_R(N_POLICY_SK_R, N_YEARMONTH_R)` index exists after M-0028 rename

## Stage 1 Merger Decisions

### M-0028
- Table rename `FCT_RPT_CROSS_SELL_SUMMARY_R` → `STG_CROSS_SELL_SUMMARY_R` applied in `cur_upd_cross_sell_col` (line 509 of source).
- GLOBAL: cross-impact pending on PKG_GRP_LOAD_FCT_RPT_CROSS_SELL_SUMMARY_R — awaiting cross-impacts decision (A/B/C).

### M-0031 + M-0058 + M-0073 + M-0074 (compound)
- `prc_load_data_dim_gtt` procedure body removed (source lines 215–311; ~97 lines deleted).
- Call block and 9.3/9.4 logging in `PRC_UPD_COL_DETAILS` removed (source lines 810–851; ~41 lines deleted).
- 8 GTT-dependent cursors rewritten to query `DIM_PLAN_DESIGN_DIRECTORY_R` directly with restored `EXISTS(RPT_POLICY_DTL_R)` filter:
  - cur_upd_theft_ind_col (IDTHEFT)
  - cur_upd_theft_dt_col (IDTHEFTEFFDATE)
  - cur_upd_prs_strs_ind_r (PSINDICATOR)
  - cur_upd_elimperiod_col (ELIMPERIOD)
  - cur_upd_eap_desc_col (EAIND, EAP)
  - cur_upd_bereave_desc_col (BEREAVE)
  - cur_upd_eap_eff_date_col (EAP_EFF_DATE)
  - cur_upd_bereavedate_col (BEREAVEDATE)
- Circular dependency (M-0073/M-0074) dissolved at source.
- DBA action pending: `DROP TABLE DIM_PLAN_DESIGN_DIRECTORY_R_GTT` — confirm zero other consumers first.

### M-0053
- v_line_of_business_group_r (7 branches): CASE replaced with `REF_LINE_OF_BUSINESS_GROUP_MAP` LEFT JOIN. DDL file written: `REF_LINE_OF_BUSINESS_GROUP_MAP_DDL.sql`.
- v_policy_case_size_r (9 branches): **DEFERRED** — first WHEN branch uses `v_smartchoice_ind_r = 'Y'` flag override (not pure range); REF table design requires analyst sign-off. Comment added in SQL.

---

## Stage 3 Standardizer Decisions

### Applied (STD-01, STD-02, STD-03, STD-04, STD-05, STD-06, STD-09, STD-10, STD-11)
- STD-01: Removed duplicate EXCEPTION keyword in theft-date block (compile error fix)
- STD-02: Removed 6 dead declarations from MAIN (OPP-11 dead code)
- STD-03: Fixed logger constant in PRC_UPD_COL_DETAILS EXCEPTION (GV_dummyrec_loadedby → gv_upd_ind_cols_by)
- STD-04: Added missing PKG_GRP_LOG_UTIL log call in theft-date WHEN OTHERS block
- STD-05: Removed duplicate d_id_theft_date_r assignment
- STD-06: Added missing AS keyword to 4 column aliases
- STD-09: Changed 17 collection TYPE declarations from INDEX BY BINARY_INTEGER → PLS_INTEGER
- STD-10: Fixed typo in cursor comment (Breave → Bereave)
- STD-11: Updated file header to Stage 3

### Deferred
- STD-07: Carrier NVL CASE repeated 5× — extract to private function (developer deferred; low deployment risk)
- STD-08: SELECT * in 2 inline views — enumerate columns explicitly (developer deferred; high change risk)

### Standards report
- 2 CRITICAL violations fixed (package now compiles)
- 2 HIGH violations fixed
- 3 MEDIUM violations fixed (of 4; STD-07 STD-08 deferred)
- 3 LOW violations fixed
- Final compliance: 9/11 violations resolved
- File: 03_standardized.sql ✅ DEPLOY THIS FILE
