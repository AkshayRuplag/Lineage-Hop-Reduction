# Execution Plan — PKG_GRP_LOAD_RPT_FCT_RPT_CLAIM_SUMMARY_R

**Generated:** 2026-08-10
**Status:** ✅ Approved — 2026-08-11
**RPT:** RPT_CLAIM_DTL_R  |  **Impl Rank:** 7  |  **Tier:** 2  |  **Scope:** GLOBAL
**Planner analysis:** 3 recs, 3 stage-steps, 2 informational cross-package impacts (no code-edit work items)

---

## Recommendations in Scope

| Rec ID | Phase | Category | Risk | Review Status | Validator Comments |
|--------|-------|----------|------|----------------|---------------------|
| M-0027 | 1 — Foundation | O. Hybrid Naming Convention Violation | MEDIUM | ✅ Consider | Naming only — "Only for naming standards not for hop reduction." |
| M-0067 | 3 — Consolidation | P. Post-Load Cursor UPDATE — Fold into INSERT | MEDIUM | ✅ Consider | ⚠️ "Need more analysis and make sure data count is not getting changed after adding this logic directly on insert block." |
| M-0086 | 3 — Consolidation | N. Circular Update Chain (Post-Load Self-Reference) | HIGH | ✅ Consider | ⚠️ "Parser clarification is required... Impact analysis and performance validation should be completed before implementation." Also: "we are updating this table based on 3 cursor using 3 tables (claim_sum, claim_dtl, dim_grp_claim_coverage_group)." |

### ⚠️ Validator Caution Summary
- **M-0067** — Reviewer flags this needs more analysis; row-count parity must be validated after folding the cursor logic into the INSERT.
- **M-0086** — HIGH risk. Reviewer notes clarification is needed on exactly which columns are derived via the 3 downstream passes (the `cur_upd_claim_attr` cursor + 2 post-load MERGE statements against `RPT_CLAIM_DTL_R`/`RPT_CLAIM_SUM_R`, and 1 MERGE against `DIM_GRP_CLAIM_COVERAGE_GROUP_R`). Full impact analysis and performance validation required before implementation. The Merger will pause and ask for explicit confirmation on this rec.

Step 0 (pending cross-impacts): **NONE** — `pending_cross_impacts` is empty in the registry and in `decisions.md`.

---

## Compound Pattern Detected

**M-0067 + M-0086 — same-target compound.** Both target `RPT_FCT_RPT_CLAIM_SUMMARY_R` via the same job (`EDP_GRP_EDW_LOAD_RPT_FCT_RPT_CLAIM_SUMMARY_R-24`) and the same code path (the post-load `cur_upd_claim_attr` cursor in `PROCEDURE main`). The registry itself carries an explicit overlap note on M-0086:

> "[OVERLAP NOTE] Hop savings credited to primary rec M-0067 ... Implement together; do not count savings twice."

These must be applied as **one combined INSERT-time fold**, not two separate passes:
1. Fold the 4 derived columns (`n_avg_claim_decision_days_r`, `n_claim_approach_dur_r`, `n_claim_approach_exp_resolution_r`, `n_duration_remaining_r`) into the `prc_get_cur_data` SELECT (M-0067), **and**
2. When computing them, join to the underlying source data the same way the `RPT_CLAIM_DTL_R`-derived functions do today — evaluate whether the already-joined `d` alias (`rpt_claim_dtl_r` active-status rows, already joined in `prc_get_cur_data`) is sufficient, since it is itself the object flagged as the circular lagged-cycle dependency in M-0086.

No separate step is planned for M-0086 — the Merger applies it together with M-0067 inside Step 2.

**Naming vs. functional dependency:** M-0027 renames `FCT_RPT_CLAIM_SUMMARY_R` (the source table read via `from FCT_RPT_CLAIM_SUMMARY_R a` inside `prc_get_cur_data`). This is a **different table** from `RPT_FCT_RPT_CLAIM_SUMMARY_R` (the target of M-0067/M-0086), so there is no direct functional collision — but standard phase ordering still applies: Phase 1 (naming) executes before Phase 3 (consolidation).

---

## Global Impact — FCT_RPT_CLAIM_SUMMARY_R (M-0027, appears in 3 RPTs)

Home RPT: RPT_CLAIM_DTL_R
Also used by: RPT_FCT_RPT_CLAIM_SUMMARY_R, RPT_FCT_RPT_CLAIM_SUMMARY_R_HIST

| Consumer | Source | Reference type |
|----------|--------|-----------------|
| PKG_GRP_LOAD_RPT_FCT_RPT_CLAIM_SUMMARY_R (this package, `prc_get_cur_data`) | sql_objects_called | FROM clause |
| PRC_GRP_LOAD_FCT_RPT_CLAIM_SUMMARY_INTERMEDIATE_MV_TBL | sql_objects_called | FROM clause |
| PRC_GRP_LOAD_FCT_RPT_CLAIM_SUMMARY_INTERMEDIATE_MV_TBL2 | sql_objects_called | FROM clause |
| PRC_GRP_LOAD_FCT_RPT_CLAIM_SUMMARY_R_DATA_INCR | sql_objects_called | FROM clause |
| PRC_LOAD_CLAIM_SUMMARY_INTERMEDIATE_MV_TBL | sql_objects_called | FROM clause |

`gap_consumers`: none. `cascade_chain`: none. Proposed rename: `FCT_RPT_CLAIM_SUMMARY_R` → `STG_CLAIM_SUMMARY_R`.

Rec comments restrict this to **naming only** — no hop-reduction/elimination is in scope for M-0027 in this pass.

## Global Impact — RPT_FCT_RPT_CLAIM_SUMMARY_R (M-0067 / M-0086, appears in 3 RPTs)

Home RPT: RPT_CLAIM_DTL_R
Also used by: RPT_FCT_RPT_CLAIM_SUMMARY_R, RPT_FCT_RPT_CLAIM_SUMMARY_R_HIST

Unlike M-0027, these recs carry no `gap_consumers`/`cascade_chain` entries in the registry — the GLOBAL scope here reflects **shared data-flow consumption**, not a rename/elimination. Two informational impacts were found by direct lineage lookup (no code-edit work item is required for either — see notes):

| Consuming object | Relationship | Note |
|---|---|---|
| `PKG_GRP_LOAD_RPT_FCT_RPT_CLAIM_SUMMARY_R_HIST` (RPT_FCT_RPT_CLAIM_SUMMARY_R_HIST pipeline) | Reads `RPT_FCT_RPT_CLAIM_SUMMARY_R` as a source table | Downstream HIST load will inherit whatever values the folded derived columns produce — validate row-for-row parity on the 4 derived columns after the fold, no code change needed there. |
| `PKG_GRP_LOAD_RPT_CLAIM_DTL_R` (home package of `RPT_CLAIM_DTL_R`) | **Circular partner** — its load reads `RPT_FCT_RPT_CLAIM_SUMMARY_R` (per M-0086), while this package reads `RPT_CLAIM_DTL_R` back | ⚠️ Coordinate the M-0086 change with whoever owns `PKG_GRP_LOAD_RPT_CLAIM_DTL_R` before implementing — no source edit needed in that package, but the lagged-cycle assumption must be understood by both sides. **Note:** `PKG_GRP_LOAD_RPT_CLAIM_DTL_R` has no pipeline folder yet (not yet scaffolded/planned) — flag this for whoever plans that package next. |

---

## Data Profile — PKG_GRP_LOAD_RPT_FCT_RPT_CLAIM_SUMMARY_R

| Table | Role | Rows | Size (MB) | Indexes | Has Unique? |
|-------|------|-----:|----------:|--------:|:-----------:|
| RPT_FCT_RPT_CLAIM_SUMMARY_R | TARGET (M-0067/M-0086) | 6,855,789 | 1,554,696.06 | 11 | No |
| FCT_RPT_CLAIM_SUMMARY_R | SOURCE (read in `prc_get_cur_data`) / rename target (M-0027) | 15,499,917 | 15,382,080.00 | 11 | Yes |
| RPT_CLAIM_DTL_R | SOURCE (functions, `d` join, Merge1/Merge2) | 57,283,968 | 23,942,245.13 | 18 | No |
| DIM_GRP_CLAIM_COVERAGE_GROUP_R | SOURCE (Merge3) | 17,976,068 | 284,043.38 | 11 | Yes |

**Risk annotations from data profile:**
- ⚠️ **Large tables (>10 GB):** `RPT_FCT_RPT_CLAIM_SUMMARY_R` (~1.5 TB), `FCT_RPT_CLAIM_SUMMARY_R` (~15 TB), `RPT_CLAIM_DTL_R` (~24 TB) — validate undo/temp space before running the folded INSERT/MERGE passes.
- ⚠️ `RPT_FCT_RPT_CLAIM_SUMMARY_R` has **no unique index** — the M-0067/M-0086 fold relies on the same claim keys already used by `RPT_CLAIM_DTL_R_IDX1` (`N_CLAIM_COVERAGE_GROUP_SK_R, N_CLAIM_COVERAGE_SK_R, N_CLAIM_SK_R`), which IS present and covers the join predicate — but add an explicit validation step confirming the plan uses this index (non-unique, so duplicate-key behavior must be checked).
- `RPT_CLAIM_DTL_R` (57.3M rows) and `DIM_GRP_CLAIM_COVERAGE_GROUP_R` (18.0M rows) are both >5M-row join sources — confirmed both have composite indexes covering the actual join keys used (`RPT_CLAIM_DTL_R_IDX1`, `DIM_GRP_CLAIM_COVERAGE_GROUP_R_IDX2`).
- `FCT_RPT_CLAIM_SUMMARY_R` (15.5M rows, the M-0027 rename target) — since M-0027 is naming-only in this pass, no `APPEND`/parallel hint changes are needed for it now; flag for future hop-reduction pass if that scope is reopened.

**Validation checklist (added to plan from data profile + validator comments):**
- [ ] Row-count parity check on `RPT_FCT_RPT_CLAIM_SUMMARY_R` before/after the M-0067/M-0086 fold (per reviewer request).
- [ ] Confirm the folded derived-column logic produces identical values to the current `get_n_avg_claim_decision_days_r` / `get_n_claim_approach_dur_r` / `get_n_claim_approach_exp_resolution_r` / `get_n_duration_remaining_r` functions across 3 consecutive cycles.
- [ ] Confirm undо/temp tablespace sizing given the multi-TB target/source tables.
- [ ] Validate `RPT_FCT_RPT_CLAIM_SUMMARY_R_HIST` load still matches expected values after the fold (informational cross-package impact).
- [ ] Coordinate with the `RPT_CLAIM_DTL_R` load owner on the circular-chain assumption before finalizing M-0086 (no code change there, but shared understanding required).

---

## Execution Steps

### Step 0 — Apply Pending Cross-Impacts
NONE. `pending_cross_impacts` is empty for this package.

### Step 1 — Stage 1: Merger (all registry recs) `[Phases 1–4 combined]`
- **Recs:** M-0027, M-0067, M-0086
- **Agent:** PL/SQL Merger
- **Action:** Apply in phase order:
  1. Phase 1 — M-0027: rename `FCT_RPT_CLAIM_SUMMARY_R` → `STG_CLAIM_SUMMARY_R` (naming only, no hop reduction) in `prc_get_cur_data`'s FROM clause and any other reference in this script.
  2. Phase 3 (combined) — M-0067 + M-0086: fold the 4 derived columns into the `prc_get_cur_data` INSERT SELECT, removing the `cur_upd_claim_attr` cursor/FORALL UPDATE block from `main`, while addressing the circular-chain concern per M-0086's guidance. **Merger must pause and get explicit confirmation before applying this step, per the ⚠️ caution flags above.**
- **Compounds:** M-0067 + M-0086 (see Compound Pattern Detected above).
- **Data Profile:** Target `RPT_FCT_RPT_CLAIM_SUMMARY_R` — 6.86M rows / 1,554,696 MB / 11 indexes (no unique index).
- ⚠️ **GLOBAL:** M-0027 rename affects 5 consumer scripts (see Global Impact table above); M-0067/M-0086 affect data flowing into `RPT_FCT_RPT_CLAIM_SUMMARY_R_HIST` and share a circular dependency with `PKG_GRP_LOAD_RPT_CLAIM_DTL_R`.
- ⚠️ Large tables — validate undo/temp space (see Data Profile section).
- → Produces: `01_merged.sql`

### Step 2 — Stage 2: Optimizer (discovery scan) `[Mode A — post-merger]`
- **Agent:** PL/SQL Optimizer
- **Input:** `01_merged.sql`
- **Action:** Scan for NEW optimization opportunities not covered by the 3 registry recs above (e.g. the repeated 3x package spec/body block noticed in `00_source.sql`, the 3 sequential MERGE statements in `main`, logging-call density).
- → Produces: `02_optimizer_report.md` + `02_optimized.sql` (if changes approved)

### Step 3 — Stage 3: Standardizer `[always last]`
- **Agent:** PL/SQL Standardize
- → Produces: `03_standardized.sql`

---

## Cross-Package Impact Plan

No code-edit cross-package work items are required for this package's recs:
- M-0027's 5 consumers only reference `FCT_RPT_CLAIM_SUMMARY_R` by name in FROM clauses within scripts that are **outside this package** (`PRC_GRP_LOAD_FCT_RPT_CLAIM_SUMMARY_INTERMEDIATE_MV_TBL(2)`, `PRC_GRP_LOAD_FCT_RPT_CLAIM_SUMMARY_R_DATA_INCR`, `PRC_LOAD_CLAIM_SUMMARY_INTERMEDIATE_MV_TBL`) — since M-0027 is scoped **naming-only** and the rename must be coordinated globally, choose an option below.
- M-0067/M-0086 require no source edits elsewhere — only monitoring/validation in the HIST package and coordination with the `RPT_CLAIM_DTL_R` owner (see Global Impact table).

Review options for the M-0027 rename's 5 consumers:
```
  cross-impacts A    — apply the FCT_RPT_CLAIM_SUMMARY_R → STG_CLAIM_SUMMARY_R rename to all 5 consumer scripts now
  cross-impacts B    — register as pending cross-impacts (each consumer applies it when its own package is next planned)
  cross-impacts C    — document only, no automated propagation
```

---

## DBA Actions (flagged, not automated)
- Rename `FCT_RPT_CLAIM_SUMMARY_R` → `STG_CLAIM_SUMMARY_R` (DDL rename + synonym/grant review) once all 5 consumer scripts are updated.
- Review undo/temp tablespace sizing before running the folded INSERT/MERGE passes against the multi-TB tables listed in the Data Profile.
- No DDL changes required for M-0067/M-0086 (logic-only change inside the package).

---

## Summary Metrics

| Metric | Value |
|--------|-------|
| Recs in scope | 3 |
| Execution steps | 3 (Merger → Optimizer → Standardizer) |
| Compound recs | 1 (M-0067 + M-0086) |
| Cross-package code-edit work items | 0 |
| Informational cross-package impacts | 2 (HIST package, RPT_CLAIM_DTL_R circular partner) |
| Hop savings (registry) | M-0027: 1 hop / 1.9 min; M-0067: 2 hops / 11.2 min; M-0086: 0 (credited to M-0067) |

---

## Approval

```
Review options:
  approve            — approve full plan and begin execution
  revise step N       — request change to a specific step
  cross-impacts A     — apply M-0027 rename to all 5 consumer scripts now
  cross-impacts B     — register M-0027 rename as pending cross-impacts
  cross-impacts C     — document only
  abort               — cancel, no changes made
```

## Stage Log

| Stage | Date | Decision | Notes |
|-------|------|----------|-------|
| Plan generated | 2026-08-10 | — | Initial plan created by Planner |
| Plan approved | 2026-08-11 | approve | Developer approved full plan; proceeding to Stage 1 (Merger) |
