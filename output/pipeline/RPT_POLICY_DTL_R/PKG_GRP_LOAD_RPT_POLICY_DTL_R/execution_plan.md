# Execution Plan — PKG_GRP_LOAD_RPT_POLICY_DTL_R

**Generated:** 2026-08-06 (regenerated)  
**Planner analysis:** 6 recs · 3 stages · 1 cross-package package  
**Status:** ✅ Code stages Completed — 2026-08-04  |  📋 Plan documentation regenerated — 2026-08-06  
**RPT:** RPT_POLICY_DTL_R  |  **Rank:** 2  |  **Tier:** 1  |  **Scope:** GLOBAL

> **⚠️ REGENERATED 2026-08-06** — Stages 1–3 (Merger → Optimizer → Standardizer) were already executed
> and completed on 2026-08-04 (`01_merged.sql`, `02_optimized.sql`, `03_standardized.sql` all exist and are
> valid). **This regeneration does NOT re-run those stages.** It refreshes the planning documentation with
> deeper source-verified analysis and surfaces two outstanding gaps:
> 1. **Cursor-count correction** — registry description for M-0058 says "~4" post-load cursor UPDATE passes.
>    Live source (`00_source.sql`) confirms **18 active `FETCH ... BULK COLLECT` cursors** (8 GTT-dependent,
>    10 non-GTT) plus **1 dead/commented-out cursor** (`cur_upd_v_plan_duration_r`, lines ~880–890 — entirely
>    inside a `/* ... */` block, disabled 11-Jul-2025). This does not change what was already merged (the
>    Merger evidently already scoped to the 8 GTT-dependent cursors correctly), but corrects the record for
>    future reviewers and flags the dead cursor as a cleanup candidate.
> 2. **New performance risk identified** — see [Data Profile](#data-profile) below: the compound fix moved the
>    coverage-code filter from the (small, pre-filtered) GTT directly onto `DIM_PLAN_DESIGN_DIRECTORY_R`
>    (340.5M rows, size 2,007,601.88 MB, only **1 non-unique index**, not covering `v_coverage_code_r` /
>    `v_active_status_r`). This is now evaluated 8× (once per former GTT-dependent cursor) instead of once
>    against the GTT. **Recommend DBA/perf review of `01_merged.sql` before/along with production deployment.**
> 3. **Unresolved cross-impact** — M-0028's rename (`FCT_RPT_CROSS_SELL_SUMMARY_R` → `STG_CROSS_SELL_SUMMARY_R`)
>    was never actually registered in `PKG_GRP_LOAD_FCT_RPT_CROSS_SELL_SUMMARY_R`'s `pending_cross_impacts`
>    (verified against `pipeline_registry.json` — still `[]`). Previous plan recommended Option B but Phase 5
>    was never executed. **Needs a decision this session.**
>
> Prior regeneration note (2026-07-31, preserved for history): Corrected all registry recs to route through
> the **Merger** (Stage 1) per pipeline architecture; documented M-0053 branch-count and smartchoice_ind
> override corrections.

---

## Recommendations In Scope

| Rec ID | Phase | Category | Agent (Merger sub) | Risk | hop_savings | Review Status |
|--------|-------|----------|--------------------|------|-------------|---------------|
| M-0028 | 1 — Foundation | O. Hybrid Naming Convention Violation | inline | HIGH | 1 (cross-pkg) | ✅ Consider |
| M-0031 | 2 — Quick Wins | O. GTT Intra-Procedure Staging — CTE/direct-join | inline | LOW | 1 (40.6 min) | ✅ Consider |
| M-0053 | 2 — Quick Wins | Q. Hardcoded Value Mapping — Externalize to Lookup Table | Merger-Q | LOW | 0 | ✅ Consider |
| M-0058 | 3 — Consolidation | P. Post-Load Cursor UPDATE — Fold into INSERT | Merger-P | MEDIUM | 0 (overlap→M-0031) | ✅ Consider |
| M-0073 | 3 — Consolidation | N. Circular Update Chain (GTT→RPT) | Merger-Circular | HIGH | 0 (overlap→M-0031) | ✅ Consider |
| M-0074 | 3 — Consolidation | N. Circular Update Chain (RPT→GTT) | Merger-Circular | HIGH | 1 (40.6 min) | ✅ Consider |

---

## Data Profile

Source: `packages.PKG_GRP_LOAD_RPT_POLICY_DTL_R.table_metadata` (registry).

| Table | Role | Rows | Size (MB) | Indexes | Has Unique? |
|-------|------|-----:|----------:|--------:|:-----------:|
| RPT_POLICY_DTL_R | TARGET / SOURCE (self-ref, 3904 cols) | 7,047,578 | 609,451.00 | 11 | Yes |
| FCT_RPT_CROSS_SELL_SUMMARY_R | TARGET / SOURCE | 9,717,827 | 55,800.00 | 2 | Yes |
| DIM_PLAN_DESIGN_DIRECTORY_R_GTT | TARGET / SOURCE (GTT) | 0 | 0.00 | 3 | **No** |
| RPT_POLICY_DTL_R_EXG | TARGET | 0 | 7.63 | 0 | **No** |
| DIM_PLAN_DESIGN_DIRECTORY_R | SOURCE (join, cursor fold) | 340,544,794 | 2,007,601.88 | 1 | **No** |
| FCT_PLAN_DESIGN_SUMMARY_R | SOURCE (join, cursor fold) | 337,780,035 | 1,265,920.00 | 3 | Yes |
| DIM_GRP_PARTY_R | SOURCE | 23,827,790 | 472,184.38 | 12 | Yes |
| FCT_GRP_TRANSACTIONS_R | SOURCE | 18,148,668 | 228,977.25 | 8 | Yes |
| DIM_GRP_POLICY_DIR_R | SOURCE | 3,498,426 | 24,480.00 | 12 | Yes |
| FCT_GRP_POLICY_R | SOURCE | 1,766,148 | 259,541.75 | 8 | Yes |
| FCT_GRP_BILLING_POLICY_DTL_R | SOURCE | 266,568 | 3,906.00 | 4 | Yes |
| DIM_GRP_UDFIELD_R | SOURCE | 228,228 | 4,132.50 | 2 | Yes |
| FCT_GRP_POLICY_R_UW_NEEDED | SOURCE | *not in Table_Info* | — | 0 | No |
| STG_PERF_AMERITAS_RENEWAL_INFO | SOURCE | 280 | 4.50 | 0 | No |

**Summary:** target rows 16,765,405 · source rows 742,826,062 · target size 665,258.63 MB · source size
4,931,994.76 MB · 4 target tables · 13 source tables · 16 target indexes · 66 source indexes ·
meta coverage 15/17 tables.

**Risk annotations (per Planner Phase 2F rules):**

| Condition | Table(s) | Impact |
|-----------|----------|--------|
| Target size_mb > 10,000 (>10 GB) | `RPT_POLICY_DTL_R` (609.5 GB), `FCT_RPT_CROSS_SELL_SUMMARY_R` (54.5 GB) | ⚠️ Validate undo/temp space before running Stage 1 output in production |
| `has_unique_index = false` on target | `DIM_PLAN_DESIGN_DIRECTORY_R_GTT` | Directly relevant to M-0058/M-0073/M-0074 (all target this GTT) — fold JOIN predicates rely on non-unique indexes only |
| Source row_count > 5M, no supporting index on filter columns | `DIM_PLAN_DESIGN_DIRECTORY_R` (340.5M rows, single non-unique index on `N_POLICY_SK_R, N_PLAN_DESIGN_SRC_VERSION_NO_R, N_PLAN_DESIGN_SK_R` — **does not cover** `v_coverage_code_r` / `v_active_status_r`) | ⚠️ **HIGH** — the M-0031 compound rewrite pushes the coverage-code filter directly onto this 340M-row/2TB table, evaluated once per each of the 8 former GTT-dependent cursors (8× instead of once against the small pre-filtered GTT). Recommend a functional/composite index on `(v_active_status_r, v_coverage_code_r, n_policy_sk_r)` or confirm partition pruning covers this before/at production deployment. |
| `index_count = 0` on target | `RPT_POLICY_DTL_R_EXG` | Not touched by current recs — informational only |

These annotations apply to `01_merged.sql`, which already reflects the compound rewrite. Recommend adding the
`DIM_PLAN_DESIGN_DIRECTORY_R` index review to the deployment validation checklist even though code changes
are complete.

---

## Step 0 — Pending Cross-Impacts

**NONE** — `pending_cross_impacts` is empty. No pre-work required.

---

## Compound Detection

### Compound A — GTT + Circular + Cursor fold (M-0031 + M-0058 + M-0073 + M-0074)

All four recs target the same root cause: the `DIM_PLAN_DESIGN_DIRECTORY_R_GTT` staging pattern.
Confirmed against live source SQL (00_source.sql):

**GTT population (prc_load_data_dim_gtt, lines 215–311):**
```sql
INSERT INTO DIM_PLAN_DESIGN_DIRECTORY_R_GTT
  SELECT T4804933.N_PLAN_DESIGN_SK_R, T4804933.V_COVERAGE_CODE_R, T4804933.N_POLICY_SK_R
    FROM DIM_PLAN_DESIGN_DIRECTORY_R T4804933
   WHERE T4804933.v_active_status_r = 'Y'
     AND T4804933.v_coverage_code_r IN ('IDTHEFT','IDTHEFTEFFDATE','PSINDICATOR','ELIMPERIOD',...)
     AND EXISTS (SELECT 1 FROM DIM_GRP_POLICY_DIR_R T4817886
                  WHERE T4817886.N_POLICY_SK_R = T4804933.N_POLICY_SK_R
                    AND EXISTS (SELECT 1 FROM RPT_POLICY_DTL_R RPT   -- ← circular (M-0073/M-0074)
                                 WHERE RPT.N_POLICY_SK_R = T4817886.N_POLICY_SK_R
                                   AND RPT.N_YEARMONTH_R = gn_current_month));
```

**GTT-dependent cursors confirmed (8 total, lines 381–482):**

| Cursor | Coverage code | Source line |
|--------|--------------|-------------|
| `cur_upd_theft_ind_col` | `IDTHEFT` | ~381 |
| `cur_upd_theft_dt_col` | `IDTHEFTEFFDATE` | ~396 |
| `cur_upd_prs_strs_ind_r` | `PSINDICATOR` | ~412 |
| `cur_upd_elimperiod_col` | `ELIMPERIOD` | ~425 |
| `cur_upd_eap_desc_col` | `EAIND`, `EAP` | ~440 |
| `cur_upd_bereave_desc_col` | `BEREAVE` | ~455 |
| `cur_upd_eap_eff_date_col` | `EAP_EFF_DATE` | ~469 |
| `cur_upd_bereavedate_col` | `BEREAVEDATE` | ~482 |

**Why they are indivisible:**
Eliminating `prc_load_data_dim_gtt` dissolves the circular dependency (the `EXISTS(RPT_POLICY_DTL_R)` filter moves into each cursor's WHERE clause directly against `DIM_PLAN_DESIGN_DIRECTORY_R`). This simultaneously eliminates the GTT write hop (M-0031), the cursor update loops (M-0058), and both circular chains (M-0073/M-0074). The Merger handles all four recs in a single compound pass. **M-0058, M-0073, M-0074 are fully absorbed by M-0031.**

**Non-GTT cursors — NOT part of compound (remain as-is for Optimizer to discover):**

| Cursor | Source table |
|--------|-------------|
| `cur_upd_client_dtls` | `DIM_GRP_PARTY_R` |
| `cur_upd_uw_dtls` | `FCT_GRP_POLICY_R_UW_NEEDED` |
| `cur_upd_cross_sell_col` | `FCT_RPT_CROSS_SELL_SUMMARY_R` ← renamed by M-0028 (line 509) |
| `cur_upd_nxtrenewaldt_col` | `FCT_GRP_POLICY_R` / DIM tables |
| `cur_upd_d_rate_guar_r_col` | `STG_PERF_AMERITAS_RENEWAL_INFO` |
| `cur_upd_option_col` | `RPT_POLICY_DTL_R` (self) |
| `cur_upd_agencycode_cols` | `RPT_AGENT_POLICY_R` |
| `cur_upd_submission_dt` | `DIM_GRP_WRKFLW_ACTIVITY_DTLS_R` |
| `cur_upd_nxtrenewaleffdt_col` | `FCT_GRP_POLICY_R` / DIM tables |
| `cur_upd_inforceindicator_cols` | `FCT_RPT_ANN_PREM_SUMMARY_R` |

**Additional notes confirmed on regeneration (2026-08-06):**
- `cur_upd_option_col`, `cur_upd_agencycode_cols`, `cur_upd_submission_dt`, `cur_upd_nxtrenewaleffdt_col` all
  carry an `EXISTS (... RPT_POLICY_DTL_R ... n_yearmonth_r = gn_current_month)` self-scoping filter (same
  batch-scoping pattern as `cur_upd_cross_sell_col`). This is a defensive "restrict to current load batch"
  pattern, not the cross-cycle GTT-derived circularity M-0074 addresses — no action needed, informational only.
- `cur_upd_option_col` also has an **intra-procedure sequential dependency**: it derives `V_OPTION_R` /
  `D_OPTION_EFF_DATE_R` from `V_EAP_EFF_DATE_R`, `V_BEREAVEDATE_R`, `V_BEREAVE_DESC_R`, `V_EAP_DESC_R` —
  columns populated by 4 earlier cursors in the same procedure. If Optimizer/future consolidation reorders
  cursors, this ordering constraint must be preserved.
- `cur_upd_v_plan_duration_r` (was listed as a 19th `FETCH`) is **dead code** — fully commented out
  (`/* ... */`, disabled 11-Jul-2025). Recommend removal in a future cleanup pass; not part of this plan's scope.

### Naming dependency (M-0028 → cur_upd_cross_sell_col)

M-0028 renames `FCT_RPT_CROSS_SELL_SUMMARY_R` → `STG_CROSS_SELL_SUMMARY_R`. The cursor `cur_upd_cross_sell_col` (line 509) references `fct_rpt_cross_sell_summary_r`. Phase 1 (M-0028) must execute before Phase 3 compound. Merger handles this via phase ordering.

### Live source corrections to M-0053 (Q. Hardcoded)

Registry states `v_line_of_business_group_r` = 8 branches. **Live source (lines 1805–1819) shows 7 WHEN branches** (no ELSE clause, implicit NULL for unmatched prefixes):

| Branch | Prefix codes | Target value |
|--------|-------------|--------------|
| 1 | STD, TDB, TDI, DBL, VPS, ASW, MAL, CTL, ORL, COL | `'Weekly Income'` |
| 2 | VLT, LTD, VPL, VIP, ASL, FML, MSF | `'LTD'` |
| 3 | VG | `'VGTL'` |
| 4 | GL, GGL, SPG | `'Group Life'` |
| 5 | SR, VAR, VAI, VCI, VHI | `'Personal Accident'` |
| 6 | DEN, VIS | `'Dental/Vision'` |
| 7 | BCD, BCL, BCM, BCS, BSC | `'Basic Care'` |

**→ REF_LINE_OF_BUSINESS_GROUP_MAP is straightforward (equality lookup on v_policy_prefix_r).**

`v_policy_case_size_r` (9 branches, lines 1835–1867): First branch is `v_smartchoice_ind_r = 'Y'` (a string flag, not a numeric range). REF table design requires a special `IS_SMARTCHOICE` flag column or a two-step lookup. **Deferred pending analyst sign-off on REF table design.** Merger will flag this block for review, not convert it automatically.

---

## Global Scope Analysis (M-0028)

M-0028 is GLOBAL (`rpt_count = 6`). SQL grep confirms **2 actual SQL consumers**:

| Package | Role | Impact |
|---------|------|--------|
| `PKG_GRP_LOAD_FCT_RPT_CROSS_SELL_SUMMARY_R` | Writer (INSERT/DELETE/UPDATE) | 20+ references — heavy |
| `PKG_GRP_LOAD_RPT_POLICY_DTL_R` (this package) | Reader — `cur_upd_cross_sell_col` line 509 | 1 reference |

The other 4 `appears_in_rpts` entries are downstream data consumers — they do NOT contain direct SQL references to the table. `PKG_GRP_LOAD_FCT_RPT_CROSS_SELL_SUMMARY_R` also carries M-0028 in its own registry entry (Tier 1, Rank 2, same deployment window). Its `pending_cross_impacts` is currently `[]` — the cross-impact must be registered or applied as part of this session.

---

## Execution Stages

---

### Stage 1 — PL/SQL Merger (all registry recs · phases 1–3)

| Field | Value |
|-------|-------|
| **Recs** | M-0028 · M-0031 · M-0053 · M-0058 · M-0073 · M-0074 |
| **Agent** | PL/SQL Merger |
| **Input** | `00_source.sql` |
| **Output** | `01_merged.sql` + `REF_LINE_OF_BUSINESS_GROUP_MAP_DDL.sql` + `decisions.md` updated |

**Phase 1 — M-0028 (naming, applied first):**
- In `cur_upd_cross_sell_col` (line 509): replace `FROM fct_rpt_cross_sell_summary_r frcssr` → `FROM stg_cross_sell_summary_r frcssr`
- ⚠️ GLOBAL: `PKG_GRP_LOAD_FCT_RPT_CROSS_SELL_SUMMARY_R` requires coordinated rename (20+ refs). See [Cross-Package Impact Plan](#cross-package-impact-plan).
- DBA: `ALTER TABLE ATOMIC.FCT_RPT_CROSS_SELL_SUMMARY_R RENAME TO STG_CROSS_SELL_SUMMARY_R` (coordinate with sibling package deployment)

**Phase 2a — M-0031 / compound M-0031+M-0058+M-0073+M-0074 (indivisible):**
- **(a)** Remove `prc_load_data_dim_gtt` procedure body (lines 215–311)
- **(b)** Remove call `prc_load_data_dim_gtt;` and surrounding logging blocks (lines 810–843)
- **(c)** For each of 8 GTT-dependent cursors: replace `dim_plan_design_directory_r_gtt t4804933` with `DIM_PLAN_DESIGN_DIRECTORY_R t4804933` + restore filter conditions:
  ```sql
  WHERE t4804933.v_active_status_r = 'Y'
    AND t4804933.v_coverage_code_r = '<coverage_code_for_this_cursor>'
    AND EXISTS (SELECT 1
                  FROM DIM_GRP_POLICY_DIR_R t4817886
                 WHERE t4817886.N_POLICY_SK_R = t4804933.N_POLICY_SK_R
                   AND t4804933.N_PLAN_DESIGN_SRC_VERSION_NO_R = t4817886.N_POLICY_VERSION_NUMBER_R
                   AND t4817886.v_active_status_r = 'Y'
                   AND EXISTS (SELECT 1 FROM RPT_POLICY_DTL_R RPT
                                WHERE RPT.N_POLICY_SK_R = t4817886.N_POLICY_SK_R
                                  AND RPT.N_YEARMONTH_R = gn_current_month))
  ```
- **Result**: GTT write/read cycle eliminated; circular dependency (M-0073/M-0074) dissolved at source; 8 BULK COLLECT/FORALL UPDATE loops converted to direct base-table cursor queries (M-0058 absorbed)
- DBA: `DROP TABLE DIM_PLAN_DESIGN_DIRECTORY_R_GTT` — DBA to confirm zero other consumers before executing

**Phase 2b — M-0053 (Merger-Q):**
- **(a) v_line_of_business_group_r** — 7 WHEN branches (corrected from registry's 8): generate `REF_LINE_OF_BUSINESS_GROUP_MAP_DDL.sql` + replace inline CASE with:
  ```sql
  LEFT JOIN REF_LINE_OF_BUSINESS_GROUP_MAP lob_map
         ON lob_map.SOURCE_CODE = dim_grp_policy_dir_r.v_policy_prefix_r
  ```
  Reference `lob_map.TARGET_LABEL` in SELECT.
- **(b) v_policy_case_size_r** — 9 branches including `v_smartchoice_ind_r = 'Y'` override: **Merger flags this block for human review**; does NOT convert automatically. Records in decisions.md as: "M-0053 / v_policy_case_size_r: deferred — range-based + smartchoice_ind_r flag override requires analyst sign-off on REF table design."

**No Phase 4 recs** — no Tidal/MV notes needed.

---

### Stage 2 — PL/SQL Optimizer (Mode A — post-merger discovery scan)

| Field | Value |
|-------|-------|
| **Agent** | PL/SQL Optimizer |
| **Mode** | A — post-merger scan (loads context from registry + decisions.md to skip already-handled patterns) |
| **Input** | `01_merged.sql` |
| **Output** | `02_optimizer_report.md` · `02_optimized.sql` (only if changes approved) |

The 10 non-GTT cursors (`cur_upd_client_dtls`, `cur_upd_uw_dtls`, `cur_upd_cross_sell_col`, etc.) remain in `01_merged.sql` as candidates for Optimizer-discovered cursor consolidation. The Optimizer will scan for:
- BULK COLLECT without LIMIT
- Cursors that could share source datasets
- SQL anti-patterns in the large main INSERT (late filters, scalar subqueries)
- Dead code / bare WHEN OTHERS blocks

---

### Stage 3 — PL/SQL Standardize

| Field | Value |
|-------|-------|
| **Agent** | PL/SQL Standardize |
| **Input** | Best available: `02_optimized.sql` → `01_merged.sql` → `00_source.sql` |
| **Output** | `03_standardized.sql` ✅ DEPLOY THIS FILE |

---

## Cross-Package Impact Plan

**Source rec:** M-0028 — table rename `FCT_RPT_CROSS_SELL_SUMMARY_R` → `STG_CROSS_SELL_SUMMARY_R`

| # | Package | Pipeline folder | Current stage | Impact |
|---|---------|----------------|---------------|--------|
| 1 | `PKG_GRP_LOAD_FCT_RPT_CROSS_SELL_SUMMARY_R` | `RPT_POLICY_DTL_R/PKG_GRP_LOAD_FCT_RPT_CROSS_SELL_SUMMARY_R/` | raw | 20+ SQL refs — INSERT INTO, DELETE FROM, UPDATE, FROM, log messages |

> **Note:** This package is Tier 1/Rank 2 (same tier as current package). Both must compile with the new table name in the same deployment window. It also carries M-0028 in its own registry entry — the rename is part of its own Stage 1 when its pipeline runs. Its `pending_cross_impacts` is currently `[]` and must be updated.

**Please choose one option:**

| Option | Action |
|--------|--------|
| **A** | Apply rename to `PKG_GRP_LOAD_FCT_RPT_CROSS_SELL_SUMMARY_R` NOW in this session |
| **B** | Register as pending cross-impact (applied automatically when that package is planned) — **recommended** |
| **C** | Document only — developer handles manually |

---

## DBA Actions Summary

| Step | Action | When |
|------|--------|------|
| Stage 1 / Phase 1 | `ALTER TABLE ATOMIC.FCT_RPT_CROSS_SELL_SUMMARY_R RENAME TO STG_CROSS_SELL_SUMMARY_R;` | Before deployment — coordinate with PKG_GRP_LOAD_FCT_RPT_CROSS_SELL_SUMMARY_R |
| Stage 1 / Phase 2a | `DROP TABLE DIM_PLAN_DESIGN_DIRECTORY_R_GTT;` | After Stage 1 validated — DBA confirms zero other consumers first |
| Stage 1 / Phase 2b (a) | `CREATE TABLE REF_LINE_OF_BUSINESS_GROUP_MAP (SOURCE_CODE VARCHAR2(10), TARGET_LABEL VARCHAR2(50), DESCRIPTION VARCHAR2(200), EFFECTIVE_DT DATE)` + populate 7 mappings | Before Stage 1 deployment |
| Stage 1 / Phase 2b (b) | `CREATE TABLE REF_POLICY_CASE_SIZE_MAP (...)` | Pending analyst review of range + smartchoice_ind design |

---

## Summary

| Metric | Value |
|--------|-------|
| Total recs | 6 |
| Stages | 3 (Merger → Optimizer → Standardizer) |
| Compound step | M-0031 + M-0058 + M-0073 + M-0074 (indivisible in Stage 1) |
| Cross-package packages | 1 (`PKG_GRP_LOAD_FCT_RPT_CROSS_SELL_SUMMARY_R`) |
| Hop savings (this pkg) | 2 (1 × GTT elimination + 1 × M-0074 circular break) |
| Extra write passes eliminated | GTT populate pass + 8 separate FORALL UPDATE scans → 0 |
| DBA actions | 2 required · 1 pending analyst review · 1 deferred |
| Live-source corrections | v_line_of_business_group_r: 7 branches (not 8); v_policy_case_size_r: smartchoice_ind override noted |
| Cursor-count correction (2026-08-06) | 18 active cursors confirmed (8 GTT + 10 non-GTT), not registry's "~4"; 1 dead/commented cursor found (`cur_upd_v_plan_duration_r`) |
| New risk flagged (2026-08-06) | `DIM_PLAN_DESIGN_DIRECTORY_R` (340.5M rows, 1 non-unique index not covering the coverage-code filter) now scanned 8× directly in `01_merged.sql` — recommend index review before/at deployment |
| **Key correction vs previous plan** | All recs routed to **Merger** (Stage 1). Previous plan incorrectly used Optimizer for all recs. |

---

## Approval

**Code stages 1–3 are already complete (2026-08-04) — do not re-run them.** This regeneration only
requires a decision on the outstanding cross-impact registration and (optionally) the new perf-risk note.

**Review options — please reply with one of:**

| Command | Action |
|---------|--------|
| `register cross-impact` / `cross-impacts B` | Register M-0028 rename as pending cross-impact in `PKG_GRP_LOAD_FCT_RPT_CROSS_SELL_SUMMARY_R` (recommended — closes the outstanding gap) |
| `cross-impacts A` | Apply rename to `PKG_GRP_LOAD_FCT_RPT_CROSS_SELL_SUMMARY_R` now instead |
| `cross-impacts C` | Document only — no registry change |
| `accept plan` | Acknowledge the regenerated documentation as-is, no further action this session |
| `re-run stage 1` | Explicitly force Merger to re-run from `00_source.sql` (⚠️ overwrites existing `01_merged.sql`/`02_optimized.sql`/`03_standardized.sql` — only if you believe the applied fix itself is wrong) |
| `abort` | Cancel — no changes made |

---

## Stage Log

| Event | Date | By | Notes |
|-------|------|----|-------|
| Plan generated | 2026-07-31 | PL/SQL Planner | 6 recs, 3 stages, 1 cross-package |
| Plan regenerated | 2026-07-31 | PL/SQL Planner | Corrected agent routing (all recs → Merger Stage 1); live-source corrections to M-0053 branch count and smartchoice_ind override |
| Approval | 2026-08-04 | Developer | Full plan approved — Stage 1 → 2 → 3 |
| Stage 1 — Merger | 2026-08-04 | PL/SQL Merger | ⚠️ STUCK — Merger invocation stalled mid-execution. Awaiting resolution. |
| Stage 1 — Merger restart | 2026-08-04 | PL/SQL Planner | Restarting Merger fresh — all 6 recs, compound M-0031+M-0058+M-0073+M-0074 passed |
| Stage 1 — Merger | 2026-08-04 | PL/SQL Merger | ✅ Complete — 01_merged.sql written (2,756→2,692 lines, −138 removed +90 added). M-0053b deferred. REF_LINE_OF_BUSINESS_GROUP_MAP_DDL.sql created. |
| Stage 2 — Optimizer | 2026-08-04 | PL/SQL Optimizer | ✅ Complete — MGAP-1 fixed + OPP-02,03,04,05,06,07,08,12,14 applied. OPP-14 semicolon patched. 02_optimized.sql written. |
| Stage 3 — Standardize | 2026-08-04 | PL/SQL Standardize | ✅ Complete — 9/11 violations fixed (2 CRITICAL compile errors resolved). 03_standardized.sql written. STD-07/08 deferred. |
| Pipeline complete | 2026-08-04 | PL/SQL Planner | ✅ All 3 stages done. Deploy 03_standardized.sql. Cross-impact M-0028 → PKG_GRP_LOAD_FCT_RPT_CROSS_SELL_SUMMARY_R still pending (Option B recommended). |
| Plan regenerated (documentation-only) | 2026-08-06 | PL/SQL Planner | Re-verified all 6 recs and compound detection against live `00_source.sql`. Added Data Profile (Phase 2F). Corrected cursor count to 18 active (not registry's "~4"); found 1 dead cursor (`cur_upd_v_plan_duration_r`). Flagged new perf risk: `DIM_PLAN_DESIGN_DIRECTORY_R` (340.5M rows) now scanned 8× without a supporting index on the coverage-code filter. Confirmed via direct registry read that M-0028's cross-impact was never registered on `PKG_GRP_LOAD_FCT_RPT_CROSS_SELL_SUMMARY_R` (`pending_cross_impacts` still `[]`) — outstanding decision required. Stages 1–3 NOT re-run. |
