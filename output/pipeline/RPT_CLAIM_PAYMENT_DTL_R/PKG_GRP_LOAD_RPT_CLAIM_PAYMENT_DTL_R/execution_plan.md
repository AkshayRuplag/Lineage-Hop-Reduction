# Execution Plan — PKG_GRP_LOAD_RPT_CLAIM_PAYMENT_DTL_R

**Generated:** 2026-08-04
**Status:** ⏳ Awaiting approval
**RPT:** RPT_CLAIM_PAYMENT_DTL_R  |  **Rank:** 3  |  **Tier:** 1  |  **Scope:** GLOBAL
**Source:** `00_source.sql` (no later stage file present)

---

## Recommendations in Scope

| Rec ID | Phase | Category | Risk | Hop Savings | Review Status |
|--------|-------|----------|------|-------------|----------------|
| M-0004 | 0 — Decisions & Constraints | E. MV Shared Across RPTs (No Blind Elimination) | MEDIUM | 0 (0.0 min) | ✅ Consider |

This package has exactly **one** registry recommendation. There are no naming (O), pass-through (B),
GTT (O), cursor-fold (P), circular-update (N), OFFSET (C), or hardcoded-mapping (Q) recs in scope.

---

## Step 0 — Apply Pending Cross-Impacts

`pending_cross_impacts` for this package is empty in the registry.

**NONE.**

---

## Compound Pattern Detection

No GTT+cursor compound, no naming→functional dependency chain, and no other rec present to
combine with M-0004. **No compounds detected** — single-rec package.

---

## Global Scope Analysis — M-0004

`FCT_GRP_POLICY_R_MV_SSL` is a materialized view:

```sql
CREATE MATERIALIZED VIEW ATOMIC.FCT_GRP_POLICY_R_MV_SSL
  ("N_CUST_PARTY_SK_R", "N_POLICY_SK_R", "N_VERSION_NUMBER_R")
  ...
  AS SELECT MAX(n_cust_party_sk_r) n_cust_party_sk_r, n_policy_sk_r, n_version_number_r
     FROM fct_grp_policy_r
     GROUP BY n_policy_sk_r, n_version_number_r
```

Refreshed by Tidal job `EDP_GRP_EDW_MV_REFRESH_FCT_GRP_POLICY_R_MV_SSL-6`.

**Master rec `appears_in_rpts` (6 RPTs, informational/global lineage scope):**
RPT_CLAIM_DTL_R, RPT_CLAIM_PAYMENT_DTL_R, RPT_CLAIM_SUM_R, RPT_DICS_CLAIMS_DETAIL_OAC_R,
RPT_FCT_RPT_CLAIM_SUMMARY_R, RPT_FCT_RPT_CLAIM_SUMMARY_R_HIST.

**Concrete SQL consumers registered for THIS rec instance (from `sql_objects_called` / `affected_jobs`):**

| Package | Job | Location in file | Already has own M-0004 entry? |
|---------|-----|-------------------|-------------------------------|
| PKG_GRP_LOAD_RPT_CLAIM_PAYMENT_DTL_R (this package) | EDP_GRP_EDW_LOAD_RPT_CLAIM_PAYMENT_DTL_R-21 | `prc_get_cur_data`, subquery `FG_POL` joined on `ATOMIC.FCT_GRP_POLICY_R_MV_SSL` | — |
| PKG_GRP_LOAD_RPT_CLAIM_SUM_R (sibling, same RPT folder) | EDP_GRP_EDW_LOAD_RPT_CLAIM_SUM_R-22 | `PRC_GET_CUR_DATA` / `PRC_UPD_COLS` | ✅ Yes — its own registry entry already carries M-0004 independently |

The other 4 RPTs listed in `appears_in_rpts` have **no concrete SQL-object reference registered**
against this rec instance (no package entry with M-0004 exists outside this RPT folder as of
2026-08-04) — they are lineage-level associations only, not actionable consumers in this plan.

**Conclusion:** No new `pending_cross_impacts` need to be registered. `PKG_GRP_LOAD_RPT_CLAIM_SUM_R`
already owns its own copy of M-0004 and will inline the MV independently when it is planned/merged.
The recommendation's own text stages this as "WAVE 1: RPT_CLAIM_SUM_R, WAVE 2: RPT_CLAIM_PAYMENT_DTL_R"
for production rollout/parity validation — this is a **rollout sequencing note**, not a code
dependency; the two inline edits are structurally independent.

**Important:** Inlining the MV reference in this package's SQL does **not** drop the MV or its
refresh job. The MV must stay live until all real consumers (including `PKG_GRP_LOAD_RPT_CLAIM_SUM_R`
and any consumers in the other 4 RPTs, if later confirmed) have migrated. Decommissioning the MV
itself is a separate, later DBA action — out of scope for this package's plan.

---

## Step 1 — Stage 1: Merger (all registry recs) `[Phase 0 only — single rec]`

- **Recs:** M-0004
- **Agent:** PL/SQL Merger
- **Risk:** MEDIUM
- **Input:** `00_source.sql`
- **Output:** `01_merged.sql`
- **Action:** In `prc_get_cur_data`, replace the subquery
  `(SELECT N_CUST_PARTY_SK_R, N_POLICY_SK_R, N_VERSION_NUMBER_R FROM ATOMIC.FCT_GRP_POLICY_R_MV_SSL) FG_POL`
  with an inlined CTE/subquery computing the same aggregate directly from `FCT_GRP_POLICY_R`:
  `SELECT MAX(n_cust_party_sk_r) n_cust_party_sk_r, n_policy_sk_r, n_version_number_r FROM ATOMIC.fct_grp_policy_r GROUP BY n_policy_sk_r, n_version_number_r`.
  Join conditions (`DG_POL_DIR.n_policy_sk_r = FG_POL.n_policy_sk_r`,
  `DG_POL_DIR.N_POLICY_VERSION_NUMBER_R = FG_POL.N_VERSION_NUMBER_R`) remain unchanged.
- **DBA actions:** None required by this step. Do **not** drop `FCT_GRP_POLICY_R_MV_SSL` or remove
  its Tidal refresh job — it is still consumed by `PKG_GRP_LOAD_RPT_CLAIM_SUM_R` and possibly other
  RPTs.
- ⚠️ **GLOBAL:** hop_savings = 0, est_min_saved = 0.0 — this rec yields no measurable pipeline
  savings in isolation. Value is only realized once *all* consumers migrate and the MV is
  decommissioned (a separate future initiative). Developer should confirm this is still worth
  doing now vs. deferring.

## Step 2 — Stage 2: Optimizer (discovery scan) `[Mode A — post-merger]`

- **Agent:** PL/SQL Optimizer
- **Input:** `01_merged.sql`
- **Action:** Scan for NEW optimization opportunities not covered by M-0004 (this package has a
  large procedural body — `prc_get_cur_data`, `prc_insert_dummy_rec`, `main` — with commented-out
  legacy bulk-collect/FORALL code and Kill/Fill partition-exchange logic worth reviewing).
- **Output:** `02_optimizer_report.md` (+ `02_optimized.sql` if changes approved)

## Step 3 — Stage 3: Standardizer `[always last]`

- **Agent:** PL/SQL Standardize
- **Input:** best available file from Steps 1–2
- **Output:** `03_standardized.sql`

---

## Cross-Package Impact Plan

| Affected Package | Impact | Recommended Option |
|-------------------|--------|---------------------|
| PKG_GRP_LOAD_RPT_CLAIM_SUM_R | Same MV reference, same rec (M-0004) already independently registered | **C — Document only.** No pending_cross_impact needed; it will self-apply when planned. |

Options:
- **A** — apply now (not needed here; sibling package already self-tracks the rec)
- **B** — register as pending (not needed; not a dependency, just parallel rollout)
- **C** — document only ← **recommended**

---

## DBA Actions (flagged, not automated)

- **Deferred, not part of this plan:** once `PKG_GRP_LOAD_RPT_CLAIM_SUM_R` and any other real
  consumers have migrated off `FCT_GRP_POLICY_R_MV_SSL`, drop the MV and remove Tidal job
  `EDP_GRP_EDW_MV_REFRESH_FCT_GRP_POLICY_R_MV_SSL-6` plus its scheduler dependency edges.

---

## Summary Metrics

| Metric | Value |
|--------|-------|
| Recs in scope | 1 (M-0004) |
| Steps | 3 |
| Hop savings (this package) | 0 (0.0 min) |
| Cross-package items | 1 (informational only — no action required) |

---

## Approval

| Option | Command |
|--------|---------|
| Approve full plan | `approve` |
| Revise a step | `revise step N` |
| Cross-impacts option | `cross-impacts C` (recommended; A/B available but not needed) |
| Abort | `abort` |

---

## Stage Log

| Stage | Date | Decision | Notes |
|-------|------|----------|-------|
| Plan generated | 2026-08-04 | — | Initial plan created by PL/SQL Planner |
