# Pipeline Decisions — PKG_GRP_LOAD_RPT_CLAIM_DTL_R

**RPT:** RPT_DICS_CLAIMS_DETAIL_OAC_R  |  **Rank:** 5  |  **Tier:** 2  |  **Scope:** GLOBAL

## Recommendations

- M-0088 | E. MV Indicator-Chain Elimination Candidate | ✅ Consider
- M-0090 | E. MV Indicator-Chain Elimination Candidate | ✅ Consider
- M-0098 | E. MV Indicator-Chain Elimination Candidate | ✅ Consider
- M-0101 | E. MV Indicator-Chain Elimination Candidate | ✅ Consider
- M-0102 | E. MV Indicator-Chain Elimination Candidate | ✅ Consider
- M-0108 | E. MV Indicator-Chain Elimination Candidate | ✅ Consider
- M-0122 | E. MV Elimination Candidate | ✅ Consider

### ⚠️ PENDING CROSS-IMPACT — Must apply before own recs
Source: PKG_GRP_LOAD_RPT_CLAIM_PAYMENT_DTL_R / M-0004
Type: inline
Change: Replace consumer subquery referencing FCT_GRP_POLICY_R_MV_SSL (line 1643 — the equivalent CTE is already commented out just above it) with an inlined CTE: SELECT MAX(n_cust_party_sk_r) n_cust_party_sk_r, n_policy_sk_r, n_version_number_r FROM fct_grp_policy_r GROUP BY n_policy_sk_r, n_version_number_r. This package also owns an embedded `dbms_mview.refresh('FCT_GRP_POLICY_R_MV_SSL', ...)` call at lines 1937-1939 — do NOT remove it yet; only remove once ALL 4 consumers (this pkg, PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC, PKG_GRP_LOAD_RPT_CLAIM_SUM_R, PKG_GRP_LOAD_RPT_CLAIM_PAYMENT_DTL_R) have migrated and the MV is approved for drop.
Action: Run `@PL/SQL Planner PKG_GRP_LOAD_RPT_CLAIM_DTL_R` — Step 0 will apply this.
Registered: 2026-08-06
⚠️ **Registry note:** could not be auto-written to `pipeline_registry.json`'s `pending_cross_impacts` array — the M-0091/M-0092/M-0101/M-0102 rec blocks surrounding this package's entry are byte-identical duplicates shared with `PKG_GRP_LOAD_RPT_CLAIMANT_DTL_R_INC`, making a safe unique text match impractical by hand. Apply the registry update via a JSON-aware script, or treat this decisions.md entry as the authoritative pending record until then.

## Stage Log

| Stage | Date | Decision | Notes |
|-------|------|----------|-------|
