# -*- coding: utf-8 -*-
"""
PL/SQL Merger — PKG_GRP_LOAD_RPT_POLICY_DTL_R
Applies: M-0028, M-0031+M-0058+M-0073+M-0074 (compound), M-0053a, M-0053b
Date: 2026-08-04
"""
import re, sys, os

base = r"C:\Users\HM295EJ\OneDrive - EY\Desktop\RSLI-DataLineage\RSLI-DataLineage-VDI\output\pipeline\RPT_POLICY_DTL_R\PKG_GRP_LOAD_RPT_POLICY_DTL_R"
src_path = os.path.join(base, "00_source.sql")
out_path = os.path.join(base, "01_merged.sql")

with open(src_path, 'r', encoding='utf-8') as f:
    raw = f.read()

# Normalise to LF for processing
content = raw.replace('\r\n', '\n').replace('\r', '\n')
orig_lines = content.count('\n') + 1
print(f"Source loaded: {orig_lines} lines")

ok_list  = []
fail_list = []

def do_replace(txt, old, new, tag):
    n = txt.count(old)
    if n == 0:
        fail_list.append(f"FAIL [{tag}]: not found")
        return txt
    if n > 1:
        fail_list.append(f"WARN [{tag}]: {n} occurrences — replacing first only")
        result = txt.replace(old, new, 1)
    else:
        result = txt.replace(old, new)
    ok_list.append(f"OK   [{tag}]  ({n} occurrence(s))")
    return result

def do_regex(txt, pattern, repl, tag, flags=re.DOTALL):
    m = re.search(pattern, txt, flags)
    if not m:
        fail_list.append(f"FAIL [{tag}]: regex not matched")
        return txt
    result = re.sub(pattern, repl, txt, count=1, flags=flags)
    ok_list.append(f"OK   [{tag}]  (span {m.start()}-{m.end()}, {m.end()-m.start()} chars)")
    return result

def insert_before_group_by(txt, coverage_snippet, tag):
    """Find coverage_snippet, then insert GTT_ADD before the next GROUP BY."""
    pos = txt.find(coverage_snippet)
    if pos < 0:
        fail_list.append(f"FAIL [{tag}]: snippet not found: {coverage_snippet[:50]!r}")
        return txt
    eol = txt.find('\n', pos)
    if eol < 0:
        fail_list.append(f"FAIL [{tag}]: no EOL after snippet")
        return txt
    gb = txt.find('GROUP BY', eol)
    if gb < 0:
        fail_list.append(f"FAIL [{tag}]: no GROUP BY after snippet")
        return txt
    result = txt[:eol] + GTT_ADD + txt[eol:]
    ok_list.append(f"OK   [{tag}]")
    return result

# GTT conditions to add to each cursor
GTT_ADD = (
    "\n   AND t4804933.v_active_status_r = 'Y'"
    "\n   AND t4804933.N_PLAN_DESIGN_SRC_VERSION_NO_R = ("
    "\n           SELECT T4817886.N_POLICY_VERSION_NUMBER_R"
    "\n             FROM DIM_GRP_POLICY_DIR_R T4817886"
    "\n            WHERE T4817886.N_POLICY_SK_R = t4804933.N_POLICY_SK_R"
    "\n              AND T4817886.v_active_status_r = 'Y'"
    "\n              AND EXISTS (SELECT 1 FROM RPT_POLICY_DTL_R RPT"
    "\n                           WHERE RPT.N_POLICY_SK_R = T4817886.N_POLICY_SK_R"
    "\n                             AND RPT.N_YEARMONTH_R = gn_current_month))"
)

# ===========================================================================
# CHANGE 1 — M-0028
# ===========================================================================
content = do_replace(
    content,
    'FROM fct_rpt_cross_sell_summary_r frcssr',
    'FROM stg_cross_sell_summary_r frcssr  -- M-0028: renamed table',
    'M-0028/cross-sell-rename'
)

# ===========================================================================
# CHANGE 2a — Delete prc_load_data_dim_gtt procedure body
# ===========================================================================
content = do_regex(
    content,
    (r'--Procedure prc_load_data_dim_gtt loads coverage codes data into Global Temporary table\n'
     r'PROCEDURE prc_load_data_dim_gtt\n.*?END prc_load_data_dim_gtt;\n'),
    '-- M-0031+M-0058+M-0073+M-0074 (compound): prc_load_data_dim_gtt removed'
     ' — 8 GTT cursors rewritten to query DIM_PLAN_DESIGN_DIRECTORY_R directly\n',
    'M-0031/delete-proc-body'
)

# ===========================================================================
# CHANGE 2b — Delete the 9.3 / 9.4 call-block in PRC_UPD_COL_DETAILS
# ===========================================================================
content = do_regex(
    content,
    (r"    /\*START:NEW LOGGING MECHANISM CHANGES\*/\n"
     r"\tgv_trcmsg:='9\.3 Start: Call Procedure prc_load_data_dim_gtt'.*?"
     r"gv_trcmsg :='9\.4 End: Called Procedure prc_load_data_dim_gtt'.*?"
     r"/\*END: NEW LOGGING MECHANISM CHANGES\*/\n\n"),
    "\t-- M-0031+M-0058+M-0073+M-0074 (compound): prc_load_data_dim_gtt call removed\n\n",
    'M-0031/delete-call-block-9.3-9.4'
)

# ===========================================================================
# CHANGE 2c-i — Replace GTT table name in all 8 cursors
# ===========================================================================
GTT_OLD = 'dim_plan_design_directory_r_gtt t4804933'
GTT_NEW = 'DIM_PLAN_DESIGN_DIRECTORY_R t4804933  -- M-0031: GTT eliminated'
n_gtt = content.count(GTT_OLD)
if n_gtt == 8:
    content = content.replace(GTT_OLD, GTT_NEW)
    ok_list.append(f"OK   [M-0031/gtt-table-name]  (8 occurrences replaced)")
elif n_gtt == 0:
    fail_list.append(f"FAIL [M-0031/gtt-table-name]: not found — was proc already deleted?")
else:
    fail_list.append(f"WARN [M-0031/gtt-table-name]: expected 8, found {n_gtt} — replacing all")
    content = content.replace(GTT_OLD, GTT_NEW)

# ===========================================================================
# CHANGE 2c-ii — Add GTT WHERE conditions to each cursor before its GROUP BY
# ===========================================================================
# cur_upd_theft_ind_col  (IDTHEFT)
content = insert_before_group_by(content, "AND t4804933.v_coverage_code_r = 'IDTHEFT'",        'M-0031/cur_theft_ind_col')
# cur_upd_theft_dt_col   (IDTHEFTEFFDATE — last cond is IS NOT NULL on t4805277)
content = insert_before_group_by(content, "AND t4805277.v_override_description_r IS NOT NULL", 'M-0031/cur_theft_dt_col')
# cur_upd_prs_strs_ind_r (PSINDICATOR)
content = insert_before_group_by(content, "AND t4804933.v_coverage_code_r = 'PSINDICATOR'",    'M-0031/cur_prs_strs_ind_r')
# cur_upd_elimperiod_col (ELIMPERIOD)
content = insert_before_group_by(content, "AND t4804933.v_coverage_code_r = 'ELIMPERIOD'",     'M-0031/cur_elimperiod_col')
# cur_upd_eap_desc_col   (EAIND, EAP)
content = insert_before_group_by(content, "AND t4804933.v_coverage_code_r IN ('EAIND', 'EAP')", 'M-0031/cur_eap_desc_col')
# cur_upd_bereave_desc_col (BEREAVE — must NOT match BEREAVEDATE)
content = insert_before_group_by(content, "AND t4804933.v_coverage_code_r ='BEREAVE'\n",       'M-0031/cur_bereave_desc_col')
# cur_upd_eap_eff_date_col (EAP_EFF_DATE)
content = insert_before_group_by(content, "AND t4804933.v_coverage_code_r ='EAP_EFF_DATE'",    'M-0031/cur_eap_eff_date_col')
# cur_upd_bereavedate_col  (BEREAVEDATE)
content = insert_before_group_by(content, "AND t4804933.v_coverage_code_r ='BEREAVEDATE'",     'M-0031/cur_bereavedate_col')

# ===========================================================================
# CHANGE 3a — M-0053a: Replace LOB group CASE with REF table lookup
# ===========================================================================
lob_pattern = (
    r"     , CASE\n\t       WHEN v_policy_prefix_r IN \('STD','TDB','TDI','DBL', 'VPS', 'ASW', 'MAL', 'CTL', 'ORL', 'COL'\)"
    r".*?AS v_line_of_business_group_r"
)
lob_repl = (
    "     , lob_map.TARGET_LABEL"
    "                                                              "
    "AS v_line_of_business_group_r"
    "  -- M-0053: CASE replaced with REF_LINE_OF_BUSINESS_GROUP_MAP lookup"
)
content = do_regex(content, lob_pattern, lob_repl, 'M-0053a/lob-case-replace')

# Add LEFT JOIN after atomic.dim_grp_udfield_r and before WHERE
content = do_regex(
    content,
    r'(\t    , atomic\.dim_grp_udfield_r  dim_grp_udfield_r\n)(\tWHERE)',
    (r'\1'
     r'     LEFT JOIN REF_LINE_OF_BUSINESS_GROUP_MAP lob_map\n'
     r'            ON lob_map.SOURCE_CODE = dim_grp_policy_dir_r.v_policy_prefix_r\n'
     r'\2'),
    'M-0053a/add-left-join-from-clause'
)

# ===========================================================================
# CHANGE 3b — M-0053b deferred comment before v_policy_case_size_r CASE
# ===========================================================================
content = do_regex(
    content,
    r'(AS v_bill_option_r\n)(\s+, CASE\n\s+WHEN fct_grp_policy_r\.v_smartchoice_ind_r)',
    ('\1'
     '     -- M-0053: deferred — range-based + smartchoice_ind_r flag override'
     ' requires analyst review before REF table conversion\n'
     '\2'),
    'M-0053b/deferred-comment'
)

# ===========================================================================
# Prepend header and write output
# ===========================================================================
HEADER = """\
-- =============================================================================
-- 01_merged.sql \u2014 PKG_GRP_LOAD_RPT_POLICY_DTL_R
-- Stage 1: PL/SQL Merger output
-- Date: 2026-08-04
-- Recs applied: M-0028, M-0031, M-0053 (partial), M-0058, M-0073, M-0074
-- Compound: M-0031+M-0058+M-0073+M-0074 (indivisible GTT elimination)
-- Deferred: M-0053b (v_policy_case_size_r \u2014 analyst review pending)
-- Source: 00_source.sql
-- =============================================================================
"""

final = HEADER + content
out_lines = final.count('\n') + 1

with open(out_path, 'w', encoding='utf-8', newline='') as f:
    f.write(final)

# ===========================================================================
# Report
# ===========================================================================
print(f"\nOutput: {out_path}")
print(f"Lines: source={orig_lines}  output={out_lines}  delta={out_lines - orig_lines}")
print(f"\n--- RESULTS ---")
for r in ok_list:
    print(f"  {r}")
if fail_list:
    print()
    for r in fail_list:
        print(f"  {r}")
    sys.exit(1)
else:
    print(f"\nAll {len(ok_list)} changes applied successfully.")
