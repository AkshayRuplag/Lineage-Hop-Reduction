# PL/SQL Optimization Opportunity Report — PKG_GRP_LOAD_RPT_CLAIM_PAYMENT_DTL_R
Generated: 2026-08-06
Mode: A — Post-Merger scan
Input file: 01_merged.sql

## Already Handled by Merger

| Category | Recs Applied | What was done | Validator Comments |
|----------|-------------|----------------|---------------------|
| E. MV Shared Across RPTs (No Blind Elimination) | M-0004 | Subquery source in the `FG_POL` LEFT JOIN (00_source.sql#L334-337) rewritten from `ATOMIC.FCT_GRP_POLICY_R_MV_SSL` to an inlined `MAX(N_CUST_PARTY_SK_R) ... GROUP BY N_POLICY_SK_R, N_VERSION_NUMBER_R FROM ATOMIC.FCT_GRP_POLICY_R`, reproducing the MV's verified definition. MV, Tidal refresh job, and other consumers left untouched (global migration deferred — tracked in execution_plan.md). | ⚠️ "A detailed impact analysis is required to validate that there are no direct dependencies on the MV before proceeding with its removal." — does not block this local, non-destructive step. |

The discovery scan below flags REMAINING opportunities only — it does not re-flag M-0004, the MV/Tidal decommission, or the embedded `dbms_mview.refresh()` calls in other packages (all tracked in execution_plan.md / decisions.md as deferred/pending).

## Index Profile (from registry — Table_Info.xlsx + Index_Allobject.xlsx)

| Table | Role | Rows | Size (MB) | Indexes | Indexed Columns (join-relevant) |
|-------|-----:|-----:|----------:|--------:|----------------------------------|
| RPT_CLAIM_PAYMENT_DTL_R | TARGET | 1,143,436,954 | 18,826,575.25 | 12 | N_CLAIM_SK_R, N_PAYMENT_SK_R+N_YEARMONTH_R, N_CLAIM_COVERAGE_GROUP_SK_R, N_CLAIM_COVERAGE_SK_R, N_CUST_PARTY_SK_R, N_POLICY_SK_R, N_PRODUCT_SK_R, N_INSRD_PARTY_SK_R (all NONUNIQUE — no unique index / no PK) |
| RPT_CLAIM_PAYMENT_DTL_R_EXG | TARGET (staging) | 0 | 739,536.25 | 0 | none (staging table, PK/FK added disabled via `PRC_CREATE_EXCHANGE_TABLE_DDL`) |
| VW_FCT_CLAIM_PAYMENT_DETAIL_R_MV_SSL_INC | SOURCE (view, FCPD) | 39,577,128 | 1,858,736.0 | 5 | N_CLAIM_SK_R (+coverage/group composite), N_PAYEE_PARTY_SK_R |
| DIM_GRP_CLAIM_DIR_R | SOURCE (DIGCD) | 2,450,021 | 14,311.5 | 9 | N_CLAIM_SK_R (IDX2), N_POLICY_SK_R (IDX1), V_ACTIVE_STATUS_R (IDX4) |
| DIM_GRP_CLAIM_COVERAGE_R | SOURCE (DIGCOV) | 17,952,232 | 251,226.0 | 7 | N_CLAIM_COVERAGE_SK_R (IDX2), V_ACTIVE_STATUS_R (IDX3), V_CLAIM_COVERAGE_CODE_R (IDX5) |
| DIM_GRP_CLAIM_COVERAGE_GROUP_R | SOURCE (DGC_COV_GRP) | 17,976,068 | 284,043.38 | 11 | N_CLAIM_COVERAGE_GROUP_SK_R (IDX2), V_ACTIVE_STATUS_R (IDX9), V_CLAIM_COVERAGE_CODE_R (IDX3) |
| DIM_GRP_POLICY_DIR_R | SOURCE (DG_POL_DIR) | 3,498,426 | 24,480.0 | 12 | N_POLICY_SK_R (IDX1), V_ACTIVE_STATUS_R (IDX7), (N_POLICY_SK_R, N_POLICY_VERSION_NUMBER_R) composite (CMP_IDX1) |
| DIM_GRP_CLAIM_DETAIL_R | SOURCE (DG_CL_DTL) | 20,318,025 | 1,531,949.75 | 8 | N_CLAIM_SK_R (IDX4), V_ACTIVE_STATUS_R (IDX5), V_EXAMINER_LOGIN_ID_R (IDX3) |
| DIM_EMPLOYEE_R | SOURCE (DIM_EMP) | 2,301 | 105.13 | 4 | V_EMPLOYEE_LOGIN_ID_R (IDX1), V_BUSINESS_UNIT_R (IDX8) |
| FCT_GRP_POLICY_R | SOURCE (M-0004 inline) | 1,766,148 | 259,541.75 | 8 | (N_POLICY_SK_R, N_VERSION_NUMBER_R) composite (CMP_IDX2) — matches inlined GROUP BY |
| DIM_GRP_PRODUCT_R | SOURCE (DG_PRD_J / dim_grp_product_r_l) | 332 | 4.13 | 6 | N_PRODUCT_SK_R (IDX4) |
| **MVW_PRODUCT_SK_LOOKUP_MIN_MV_SSL** | SOURCE (MV_PRD_LKP / MV_PRD_LKI) | **unknown — absent from Table_Info/Index_Allobject entirely** | unknown | unknown | joined twice on N_CLAIM_SK_R + V_CLAIM_COVERAGE_CODE_R — **unverified**, see OPP-4 |

All join keys used against the tracked dimension tables above already have supporting (mostly NONUNIQUE) indexes. The only real index-coverage gap is `MVW_PRODUCT_SK_LOOKUP_MIN_MV_SSL`, which has zero metadata in the registry (see OPP-4).

## 1. Script Classification

```
Script Type       : Package Body (mid Kill/Fill migration — truncate/insert being replaced by staging + partition exchange)
Primary Opt Area  : Mixed — PL/SQL orchestration (main) + one large SQL INSERT…SELECT (prc_get_cur_data)
Risk Level        : MEDIUM
Reason            : Target table is 1.14B rows / ~18.4 TB (GLOBAL scope); most of the package is stable,
                     but the Kill/Fill rewrite left one call site disabled that may be a functional gap (OPP-1).
```

## 2. Executive Summary

- Total opportunities found: 4
- High priority issues: 1 (OPP-1 — disabled dummy-record insert, possible Kill/Fill migration gap)
- Main performance risk: none material found beyond what's already tracked (M-0004); all tracked join keys are index-backed
- Main consolidation opportunity (remaining cursors): Not Applicable — no active cursors remain in this package (bulk-collect cursor path is fully commented out under Kill/Fill)
- Index candidates (new gaps only, not already-indexed columns): 1 (OPP-4 — MVW_PRODUCT_SK_LOOKUP_MIN_MV_SSL, completely unverified)
- Items needing execution-plan evidence: 0 (no plan-dependent recommendations; OPP-1 needs a business/data confirmation, not a plan)

## 3. Optimization Opportunities

| ID | Priority | Area | Sub-Type | Object/Block | Current Pattern | Issue | Recommended Direction | Safety | Evidence Level | Risk | Validation Needed |
|----|----------|------|----------|---------------|------------------|-------|------------------------|--------|-----------------|------|--------------------|
| OPP-1 | HIGH | PL/SQL | Dead Code / Kill-Fill Migration Gap | `main` → call to `prc_insert_dummy_rec` (call site line 654); procedure body lines 416-512 | Call `--prc_insert_dummy_rec;` is commented out inside the Kill/Fill legacy block; the procedure still does `INSERT /*+APPEND*/ INTO RPT_CLAIM_PAYMENT_DTL_R` (main table, not `_EXG`) with all-`-1` placeholder keys | The "-1 unknown member" placeholder row is no longer inserted by this load. If downstream joins/reports expect that row to exist per cycle, this is a silent regression from the Kill/Fill rewrite. Even if re-enabled as-is, it targets the wrong table for the new partition-exchange design (direct main-table insert would be lost/conflict when the EXG partition is exchanged in) | Confirm with the package owner/BI team whether a per-load "-1" placeholder row is still required downstream. If **yes**: rewrite to insert into `RPT_CLAIM_PAYMENT_DTL_R_EXG` instead and re-enable the call before the partition-exchange step. If **no**: remove the dead procedure and its commented call site | Unsafe | Low — needs confirmation of downstream dependency | HIGH | Check consumers of RPT_CLAIM_PAYMENT_DTL_R for logic keyed on N_CLAIM_SK_R = -1 (or similar); compare pre/post Kill/Fill row counts for the dummy key |
| OPP-2 | LOW | PL/SQL | Unused Variables | Package globals: `gn_error_line`, `gn_loop_counter_r`, `gt_start_time_insd_lp`; `main` locals: `lt_insert_time`, `ln_loop_counter`, `ln_rec_cnt`, `ln_idx_num`, `lv_rpt_table` | Declared but `gn_error_line` is never referenced anywhere; the rest are referenced only inside the commented-out legacy bulk-collect / truncate-partition blocks | Dead declarations left over from the Kill/Fill comment-out of the old bulk-collect load path | Remove — but only if the team confirms the legacy bulk-collect path (explicitly retained per the header note: *"Retaining old code base of bulk collect load; which can be used when this Package to be converted to incremental processing"*) will not be reactivated. Otherwise leave in place | Conditionally Safe | High — usage confirmed via full-file scan (verified comment boundaries) | LOW | Confirm with package owner whether the commented bulk-collect fallback is still a live contingency |
| OPP-3 | LOW | SQL | Duplicate Lookup Subquery | `prc_get_cur_data` → `MV_PRD_LKP` / `MV_PRD_LKI` derived tables | Two derived tables with an identical unfiltered `SELECT N_PRODUCT_SK_R, N_CLAIM_SK_R, V_CLAIM_COVERAGE_CODE_R FROM ATOMIC.MVW_PRODUCT_SK_LOOKUP_MIN_MV_SSL`, joined via two different key paths (through DIGCOV vs DGC_COV_GRP) | Same lookup text duplicated verbatim; a future column change must be made twice. The two joins can't be merged (different join predicates), so no material plan change is expected | Join directly to `ATOMIC.MVW_PRODUCT_SK_LOOKUP_MIN_MV_SSL` twice under different aliases (drop the redundant derived-table wrapper), or factor the column list into one named subquery referenced by both joins | Safe | Medium — cosmetic; no execution-plan evidence gathered | LOW | Standard row-count parity check after rewrite |
| OPP-4 | MEDIUM | Index Candidate | Missing Table Metadata / Unverified Index Coverage | `MVW_PRODUCT_SK_LOOKUP_MIN_MV_SSL` (joined twice in `prc_get_cur_data` on N_CLAIM_SK_R + V_CLAIM_COVERAGE_CODE_R) | Table is completely absent from the registry's Table_Info/Index_Allobject metadata — unlike every other of the 17 source tables (which appear at least as null placeholders when unmatched) | Cannot confirm the join columns are indexed; this lookup feeds two join paths into the 1.14B-row `RPT_CLAIM_PAYMENT_DTL_R` load | DBA to profile `MVW_PRODUCT_SK_LOOKUP_MIN_MV_SSL` (row count/size/existing indexes) and confirm a supporting index on (N_CLAIM_SK_R, V_CLAIM_COVERAGE_CODE_R); add one if missing | Candidate (DBA action — no DDL generated) | Low — no metadata available at all | MEDIUM | DBA index/row-count profiling before prioritizing new index creation |

## 4. Top Recommendations

1. **OPP-1** — Resolve before the next Kill/Fill promotion: confirm whether the dummy "-1" row is still required, and if so, fix its target table to `_EXG`. This is the only finding with real production-risk potential.
2. **OPP-4** — Get `MVW_PRODUCT_SK_LOOKUP_MIN_MV_SSL` profiled by DBA; it's the single blind spot in an otherwise fully index-verified query.
3. **OPP-2 / OPP-3** — Low-risk housekeeping; safe to defer or bundle into the Standardizer pass.

## 5. Evidence Required Before Applying

- OPP-1: Confirmation from package owner / BI team on whether the `-1` placeholder row is consumed downstream (query/report dependency check).
- OPP-4: DBA-run row-count and index inventory for `MVW_PRODUCT_SK_LOOKUP_MIN_MV_SSL` (not currently in Table_Info.xlsx / Index_Allobject.xlsx extracts).

## 6. Approval

Apply which opportunities? (all / none / OPP-2,OPP-3 / skip)

Note: OPP-1 requires a business decision and cannot be safely auto-applied either way (re-enabling with the old target table would be wrong; deleting could remove a still-needed placeholder row) — it will be logged to `decisions.md` as a flagged gap regardless of what is chosen for OPP-2/OPP-3. OPP-4 is DBA-only and never produces a code change.

## 7. Final Disposition (2026-08-06)

| ID | Decision | Output |
|----|----------|--------|
| OPP-1 | ⏸ Flagged / Deferred — needs business/BI confirmation on the "-1" placeholder row before either re-enabling (retarget to `_EXG`) or removing `prc_insert_dummy_rec` | No code change. Logged in `decisions.md`. |
| OPP-2 | ✅ Applied | 8 unused variables removed (3 package globals, 5 `main` locals) — see diff in `decisions.md`. |
| OPP-3 | ✅ Applied | `MV_PRD_LKP` / `MV_PRD_LKI` derived-table wrappers replaced with direct joins to `ATOMIC.MVW_PRODUCT_SK_LOOKUP_MIN_MV_SSL`; kept as two separate joins (different join keys: DIGCOV vs DGC_COV_GRP) — not merged. |
| OPP-4 | 🛠 DBA-only | No code change. Tracked as a DBA index-profiling action in `decisions.md`. |

**Output file:** `02_optimized.sql` written (OPP-2 + OPP-3 applied on top of `01_merged.sql`).
**Next agent:** PL/SQL Standardizer.
