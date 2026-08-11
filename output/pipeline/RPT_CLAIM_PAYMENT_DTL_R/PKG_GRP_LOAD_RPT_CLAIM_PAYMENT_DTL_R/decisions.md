# Pipeline Decisions — PKG_GRP_LOAD_RPT_CLAIM_PAYMENT_DTL_R

**RPT:** RPT_CLAIM_PAYMENT_DTL_R  |  **Rank:** 3  |  **Tier:** 1  |  **Scope:** GLOBAL

## Recommendations

- M-0004 | E. MV Shared Across RPTs (No Blind Elimination) | ✅ Consider

### Cross-Impact Handling — M-0004
Decision: **Option B — register as pending** (developer choice, 2026-08-06).
Registered pending cross-impacts for M-0004 in:
- PKG_GRP_LOAD_RPT_CLAIM_SUM_R (registry `pending_cross_impacts` updated ✅)
- PKG_GRP_LOAD_RPT_CLAIM_DTL_R (decisions.md only — registry update blocked by duplicate-content ambiguity, see its decisions.md)
- PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC (decisions.md only — same registry limitation)
- DIM_GRP_CLAIM_POLICY_DETAIL_EMP_MV_SSL — informational coordination note only (no code change needed until M-0105 is planned)

## Stage Log

| Stage | Date | Decision | Notes |
|-------|------|----------|-------|
| Cross-impacts | 2026-08-06 | Option B selected | Registered as pending in 3 consumer packages (see above) |
| 01_merged | 2026-08-06 | Applied registry rec | M-0004 (E-MV inline): LEFT JOIN subquery source at 00_source.sql#L334-337 changed from `ATOMIC.FCT_GRP_POLICY_R_MV_SSL` to an inlined CTE-equivalent (`MAX(N_CUST_PARTY_SK_R) ... FROM ATOMIC.FCT_GRP_POLICY_R GROUP BY N_POLICY_SK_R, N_VERSION_NUMBER_R`) reproducing the MV's verified definition. MV itself, Tidal refresh job, and `dbms_mview.refresh` calls left untouched — deferred until all 4 global consumers migrate (see Global Impact section in execution_plan.md). Validator comment: ⚠️ "A detailed impact analysis is required to validate that there are no direct dependencies on the MV before proceeding with its removal." — this change does not remove the MV, only its reference in this package, so the caution does not block this local step. |
| 02_optimized | 2026-08-06 | Applied OPP-2, OPP-3; deferred OPP-1; DBA-only OPP-4 | See "Optimizer Disposition" section below for full detail. `02_optimized.sql` written from `01_merged.sql` + OPP-2 + OPP-3. |
| 03_standardized | 2026-08-06 | Applied #1, #3, #5; skipped #2, #4, #6, #7, #8 | See "Standardization Disposition" section below for full detail. `03_standardized.sql` written from `02_optimized.sql` + fixes #1, #3, #5. `02_optimized.sql` left unmodified. |

## Optimizer Disposition (02_optimizer_report.md)

| ID | Priority | Disposition | Detail |
|----|----------|-------------|--------|
| OPP-1 | HIGH | ⏸ Flagged / Deferred | Dead `prc_insert_dummy_rec` call + wrong-target-table risk under Kill/Fill. Requires business/BI confirmation on whether the "-1" placeholder row is still consumed downstream before any code change (re-enable vs. remove) can be made safely either direction. No code change applied. Owner: package owner / BI team. |
| OPP-2 | LOW | ✅ Applied | Removed 8 unused variables orphaned by the Kill/Fill comment-out: package globals `gn_error_line`, `gn_loop_counter_r`, `gt_start_time_insd_lp`; `main` locals `lt_insert_time`, `lv_rpt_table`, `ln_loop_counter`, `ln_rec_cnt`, `ln_idx_num`. Confirmed via full-file scan that none are referenced outside the commented-out legacy bulk-collect/truncate-partition blocks. |
| OPP-3 | LOW | ✅ Applied | `prc_get_cur_data`: replaced the two identical `SELECT N_PRODUCT_SK_R, N_CLAIM_SK_R, V_CLAIM_COVERAGE_CODE_R FROM ATOMIC.MVW_PRODUCT_SK_LOOKUP_MIN_MV_SSL` derived-table wrappers (`MV_PRD_LKP`, `MV_PRD_LKI`) with direct `LEFT JOIN ATOMIC.MVW_PRODUCT_SK_LOOKUP_MIN_MV_SSL <alias>`. The two joins were kept **separate** (not merged) since `MV_PRD_LKP` keys off `DIGCOV.v_claim_coverage_code_r` and `MV_PRD_LKI` keys off `DGC_COV_GRP.v_claim_coverage_code_r` — different join predicates. Cosmetic/readability only; no plan change expected. |
| OPP-4 | MEDIUM | 🛠 DBA-only / No code change | `MVW_PRODUCT_SK_LOOKUP_MIN_MV_SSL` missing entirely from Table_Info/Index_Allobject metadata. DBA to profile row count/size/indexes and confirm a supporting index on `(N_CLAIM_SK_R, V_CLAIM_COVERAGE_CODE_R)`. Tracked as a registry/DBA action item — no SQL was or will be generated for this. |

## Standardization Disposition (coding-standards audit of 02_optimized.sql)

| # | Violation | Disposition | Detail |
|---|-----------|-------------|--------|
| 1 | Missing `AS` keyword on table/subquery/column aliases | ✅ Applied | Added `AS` before all 12 table/subquery aliases in `prc_get_cur_data`'s main SELECT (`FCPD`, `DIGCD`, `DIGCOV`, `DGC_COV_GRP`, `DG_POL_DIR`, `DG_CL_DTL`, `DIM_EMP`, `FG_POL`, `MV_PRD_LKP`, `DG_PRD_J`, `MV_PRD_LKI`, `dim_grp_product_r_l`), plus the one column alias missing it (`MAX(N_CUST_PARTY_SK_R) AS N_CUST_PARTY_SK_R` in the inlined `FG_POL` subquery). All output column aliases already used `AS`. |
| 2 | `RAISE_APPLICATION_ERROR` usage change | ⏭ Skipped | Needs owner sign-off before changing error-raising behavior. No code change. |
| 3 | Capture `SQLCODE` alongside `SQLERRM` in exception blocks | ✅ Applied | In all 3 `WHEN OTHERS` blocks (`prc_get_cur_data`, `prc_insert_dummy_rec`, `main`), changed `gv_errmsg := SUBSTR(SQLERRM,1,4000);` to `gv_errmsg := 'SQLCODE: '||SQLCODE||' - '||SUBSTR(SQLERRM,1,4000);` so both the error code and message are captured in the logged text. |
| 4 | Specific exception handlers (e.g. `NO_DATA_FOUND`, `TOO_MANY_ROWS`) | ⏭ Skipped | Developer determined this does not apply to the current logic. No code change. |
| 5 | Stale `--fetch first 253 rows only` comment | ✅ Applied | Removed the leftover comment line after the final `LEFT JOIN` in `prc_get_cur_data`'s main SELECT. |
| 6 | Legacy commented-out code (Kill/Fill bulk-collect blocks) | ⏭ Skipped | Intentionally retained per package header note — reusable if the package reverts to incremental processing. No code change. |
| 7 | Variable naming convention | ⏭ Skipped | Low value/risk; developer chose not to rename in this pass. No code change. |
| 8 | Indentation / line length | ⏭ Skipped | Cosmetic, high-diff; developer chose not to reformat. No code change. |

`02_optimized.sql` was left byte-identical to its pre-standardization state; all approved fixes were applied only to `03_standardized.sql`.
