# Pipeline Decisions — PROC_REFRESH_GRP_M_VIEW_TBLS

**Type:** STANDALONE — no specific hop-reduction recommendation.
Candidate for:
- **Optimization pass** (agent scans for PL/SQL signals: cursors, pass-through UPDATEs, hardcoded values, GTTs, etc.)
- **Standardization pass** (PL/SQL coding standards review)

## Stage Log

| Stage | Date | Decision | Notes |
|-------|------|----------|-------|
