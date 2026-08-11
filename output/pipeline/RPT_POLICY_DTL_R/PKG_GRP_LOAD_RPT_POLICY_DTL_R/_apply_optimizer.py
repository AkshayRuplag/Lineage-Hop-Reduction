"""
Apply PL/SQL Optimizer changes to 01_merged.sql -> 02_optimized.sql
All changes applied bottom-to-top (highest line first) so indices stay stable.
Applied: MGAP-1, OPP-02, OPP-03, OPP-04, OPP-05, OPP-06, OPP-07, OPP-08, OPP-12, OPP-14
"""
import os

BASE = os.path.dirname(os.path.abspath(__file__))
SRC  = os.path.join(BASE, "01_merged.sql")
DST  = os.path.join(BASE, "02_optimized.sql")

with open(SRC, encoding="utf-8") as f:
    lines = f.readlines()

orig_count = len(lines)
applied = []

def idx(one_based):
    return one_based - 1

# OPP-05 (line 2041) -- highest
i = idx(2041)
assert "DISTINCT" in lines[i].upper(), f"OPP-05 at {i+1}: {lines[i]!r}"
lines[i] = lines[i].replace("SELECT  DISTINCT N_POLICY_SK_R,",
    "SELECT  N_POLICY_SK_R,  -- OPT-05: DISTINCT removed - redundant with GROUP BY")
applied.append("OPP-05")

# OPP-02 (lines 2049-2058)
s, e = idx(2049), idx(2058)
assert "(SELECT *" in lines[s], f"OPP-02 start {s+1}: {lines[s]!r}"
assert "FCT_GRP_BILLING_POLICY_DTL_R" in lines[e], f"OPP-02 end {e+1}: {lines[e]!r}"
lines[s:e+1] = [
    "\t    ,(SELECT *                                                          -- OPT-02: ROW_NUMBER() replaces per-row correlated MAX subquery\n",
    "\t\t    FROM (SELECT a.*,\n",
    "\t\t                 ROW_NUMBER() OVER (PARTITION BY a.N_POLICY_SK_R\n",
    "\t\t                                       ORDER BY a.T_EVENT_TIMESTAMP_R DESC) AS rn\n",
    "\t\t            FROM ATOMIC.FCT_GRP_BILLING_POLICY_DTL_R a\n",
    "\t\t           WHERE a.D_DELETE_DATE_R IS NULL\n",
    "\t\t             AND a.N_POLICY_ID_R NOT IN (68215,64819))\n",
    "\t\t   WHERE rn = 1\n",
    "          ) FCT_GRP_BILLING_POLICY_DTL_R\n",
]
applied.append("OPP-02")

# MGAP-1 (lines 1781-1782)
i = idx(1781)
assert "\x01" in lines[i], f"MGAP-1 line 1781 missing x01: {lines[i]!r}"
assert lines[i+1].startswith("\x02"), f"MGAP-1 line 1782 missing x02: {lines[i+1]!r}"
lines[i:i+2] = [
    "\t\t, TO_CHAR(fct_grp_billing_policy_dtl_r.n_billing_option_value_r)                           AS v_bill_option_r\n",
    "-- M-0053: deferred - range-based + smartchoice_ind_r flag override requires analyst review before REF table conversion\n",
    "\t\t, CASE\n",
    "\t\t     WHEN fct_grp_policy_r.v_smartchoice_ind_r = 'Y'\n",
]
applied.append("MGAP-1")

# OPP-14 (line 1500)
i = idx(1500)
assert "LIMIT 10000" in lines[i], f"OPP-14 at {i+1}: {lines[i]!r}"
lines[i] = lines[i].replace("LIMIT 10000", "LIMIT gn_bulk_coll_cnt  -- OPT-14: LIMIT constant -> gn_bulk_coll_cnt")
applied.append("OPP-14")

# OPP-06 (lines 1003-1004)
i = idx(1003)
assert "WHEN OTHERS THEN" in lines[i].upper(), f"OPP-06 at {i+1}: {lines[i]!r}"
assert "NULL" in lines[i+1].upper(), f"OPP-06 NULL at {i+2}: {lines[i+1]!r}"
lines[i:i+2] = [
    "\t\tEXCEPTION WHEN OTHERS THEN                                              -- OPT-06: log error instead of silently swallowing\n",
    "\t\t    gv_errmsg := SUBSTR(SQLERRM, 1, 4000);\n",
    "\t\t    gv_trcmsg := 'Error parsing theft date: ' || gv_errmsg;\n",
    "\t\t    -- non-fatal: continue processing remaining rows\n",
]
applied.append("OPP-06")

# OPP-07 (lines 998-1000)
i = idx(998)
assert "SELECT TO_DATE" in lines[i], f"OPP-07 at {i+1}: {lines[i]!r}"
assert "INTO ld_theft_dt" in lines[i+1], f"OPP-07 INTO at {i+2}: {lines[i+1]!r}"
assert "FROM DUAL" in lines[i+2].upper(), f"OPP-07 DUAL at {i+3}: {lines[i+2]!r}"
lines[i:i+3] = [
    "\t\t   ld_theft_dt := TO_DATE(LT_VAR_UPD_TBL_THEFT_DT_TYP_REC(x).v_override_description_r, 'MM/DD/YYYY');  -- OPT-07: direct assignment replaces SELECT FROM DUAL\n",
    "\t\t   LT_VAR_UPD_TBL_THEFT_DT_TYP_REC(x).d_id_theft_date_r := ld_theft_dt;\n",
]
applied.append("OPP-07")

# OPP-08 (line 772)
i = idx(772)
assert "END LOOP" in lines[i].upper(), f"OPP-08 END LOOP at {i+1}: {lines[i]!r}"
lines.insert(i+1, "\tCLOSE cur_upd_client_dtls;  -- OPT-08: cursor was left open\n")
applied.append("OPP-08")

# OPP-04 (lines 720-724)
s, e = idx(720), idx(724)
assert "EXISTS" in lines[s], f"OPP-04 EXISTS at {s+1}: {lines[s]!r}"
assert ")" in lines[e] and "policy" not in lines[e].lower(), f"OPP-04 end at {e+1}: {lines[e]!r}"
lines[s:e+1] = ["\t  -- OPT-04: redundant EXISTS(RPT_POLICY_DTL_R) removed - join to b already enforces this filter\n"]
applied.append("OPP-04")

# OPP-03 (line 718)
i = idx(718)
assert "TO_CHAR(a.D_CYCLE_DATE_R, 'YYYYMM') = gn_current_month" in lines[i], f"OPP-03 at {i+1}: {lines[i]!r}"
lines[i:i+1] = [
    "\t  AND a.D_CYCLE_DATE_R >= TRUNC(TO_DATE(TO_CHAR(gn_current_month), 'YYYYMM'), 'MM')  -- OPT-03: sargable range replaces TO_CHAR on column\n",
    "\t  AND a.D_CYCLE_DATE_R <  ADD_MONTHS(TRUNC(TO_DATE(TO_CHAR(gn_current_month), 'YYYYMM'), 'MM'), 1)\n",
]
applied.append("OPP-03")

# OPP-12 (lines 671-672)
i_where = idx(671)
i_order = idx(672)
assert "WHERE V_VERSION_TYPE_R in('RENEWAL', 'NEWBUS')" in lines[i_where], f"OPP-12 WHERE at {i_where+1}: {lines[i_where]!r}"
assert "order by N_TXN_VERSION_NUMBER_R" in lines[i_order].lower(), f"OPP-12 ORDER BY at {i_order+1}: {lines[i_order]!r}"
lines[i_where] = "\t\t     WHERE V_VERSION_TYPE_R IN ('RENEWAL', 'NEWBUS')  -- OPT-12: ORDER BY removed from inline view (no guaranteed ordering)\n"
lines[i_order] = ""
applied.append("OPP-12")

# HEADER (lines 1-9)
s, e = idx(1), idx(9)
assert lines[s].startswith("-- ===="), f"Header start: {lines[s]!r}"
assert lines[e].startswith("-- ===="), f"Header end: {lines[e]!r}"
lines[s:e+1] = [
    "-- =============================================================================\n",
    "-- 02_optimized.sql - PKG_GRP_LOAD_RPT_POLICY_DTL_R\n",
    "-- Stage 2: PL/SQL Optimizer output (Mode A - post-merger scan)\n",
    "-- Date: 2026-08-04\n",
    "-- Applied: MGAP-1, OPP-02, OPP-03, OPP-04, OPP-05, OPP-06, OPP-07, OPP-08, OPP-12, OPP-14\n",
    "-- Deferred to Standardizer: OPP-11, OPP-13\n",
    "-- Not applied: OPP-01 (Cond.Safe), OPP-09, OPP-10 (Unsafe), OPP-15/16/17 (DBA)\n",
    "-- Source: 01_merged.sql\n",
    "-- =============================================================================\n",
]
applied.append("HEADER")

with open(DST, "w", encoding="utf-8") as f:
    f.writelines(lines)

new_count = len(lines)
print(f"Input lines : {orig_count}")
print(f"Output lines: {new_count}")
print(f"Line delta  : {new_count - orig_count:+d}")
print(f"Applied ({len(applied)}): {', '.join(applied)}")
print(f"Written to  : {DST}")
