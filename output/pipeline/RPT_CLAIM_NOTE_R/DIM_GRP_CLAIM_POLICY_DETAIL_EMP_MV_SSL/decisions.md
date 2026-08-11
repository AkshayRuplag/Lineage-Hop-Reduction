# Pipeline Decisions — DIM_GRP_CLAIM_POLICY_DETAIL_EMP_MV_SSL

**RPT:** RPT_CLAIM_NOTE_R  |  **Rank:** 1  |  **Tier:** 1  |  **Scope:** GLOBAL

## Recommendations

- M-0105 | E. MV Elimination Candidate | ✅ Consider

### ℹ️ Coordination note (informational — no code change required yet)
Source: PKG_GRP_LOAD_RPT_CLAIM_PAYMENT_DTL_R / M-0004
This MV is a gap-consumer of `FCT_GRP_POLICY_R_MV_SSL` (M-0004) AND is itself targeted for elimination under this package's own M-0105. M-0004's plan only migrates M-0004's 4 known consumers off the MV — it does NOT drop `FCT_GRP_POLICY_R_MV_SSL` yet, so no change is needed here now.
When M-0105 is planned, its inlined replacement logic (moving into `FCT_GRP_CLAIM_NOTE_R_DRQ_MV_SSL_INC`) should reference `FCT_GRP_POLICY_R` directly (the M-0004 CTE pattern: `SELECT MAX(n_cust_party_sk_r) ... FROM fct_grp_policy_r GROUP BY n_policy_sk_r, n_version_number_r`) rather than the MV, in case `FCT_GRP_POLICY_R_MV_SSL` is dropped first.
Do not drop `FCT_GRP_POLICY_R_MV_SSL` until M-0105 has also migrated off it.
Registered: 2026-08-06

## Stage Log

| Stage | Date | Decision | Notes |
|-------|------|----------|-------|
