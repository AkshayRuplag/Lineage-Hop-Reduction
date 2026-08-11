# Pipeline Decisions — PKG_GRP_LOAD_RPT_CLAIM_SUM_R

**RPT:** RPT_CLAIM_PAYMENT_DTL_R  |  **Rank:** 3  |  **Tier:** 1  |  **Scope:** GLOBAL

## Recommendations

- M-0004 | E. MV Shared Across RPTs (No Blind Elimination) | ✅ Consider
- M-0101 | E. MV Indicator-Chain Elimination Candidate | ✅ Consider
- M-0102 | E. MV Indicator-Chain Elimination Candidate | ✅ Consider

### ⚠️ PENDING CROSS-IMPACT — Must apply before own recs
Source: PKG_GRP_LOAD_RPT_CLAIM_PAYMENT_DTL_R / M-0004
Type: inline
Change: Replace direct JOIN to FCT_GRP_POLICY_R_MV_SSL (line 242) with an inlined CTE reproducing the MV's own definition: SELECT MAX(n_cust_party_sk_r) n_cust_party_sk_r, n_policy_sk_r, n_version_number_r FROM fct_grp_policy_r GROUP BY n_policy_sk_r, n_version_number_r.
Action: Run `@PL/SQL Planner PKG_GRP_LOAD_RPT_CLAIM_SUM_R` — Step 0 will apply this automatically.
Registered: 2026-08-06 (registry `pending_cross_impacts` updated)

## Stage Log

| Stage | Date | Decision | Notes |
|-------|------|----------|-------|
