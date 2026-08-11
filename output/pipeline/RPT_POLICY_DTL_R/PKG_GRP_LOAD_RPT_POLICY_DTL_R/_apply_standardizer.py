"""
Apply STD-01..STD-11 (except STD-07, STD-08 which are deferred) to 02_optimized.sql
and write 03_standardized.sql.
"""
import os

BASE = os.path.dirname(__file__)
SRC = os.path.join(BASE, '02_optimized.sql')
DST = os.path.join(BASE, '03_standardized.sql')

with open(SRC, encoding='utf-8') as f:
    content = f.read()

changes = []
failures = []

def apply(label, old, new, count=1):
    global content
    found = content.count(old)
    if found == 0:
        failures.append(f'{label}: OLD TEXT NOT FOUND')
        return
    if count != -1 and found != count:
        failures.append(f'{label}: expected {count} occurrence(s), found {found}')
        return
    content = content.replace(old, new, count)
    changes.append(f'{label}: OK (replaced {min(count, found) if count != -1 else found}x)')

# ---------------------------------------------------------------------------
# STD-11: Update file header to Stage 3
# ---------------------------------------------------------------------------
apply(
    'STD-11',
    ("-- 02_optimized.sql - PKG_GRP_LOAD_RPT_POLICY_DTL_R\n"
     "-- Stage 2: PL/SQL Optimizer output (Mode A - post-merger scan)\n"
     "-- Date: 2026-08-04\n"
     "-- Applied: MGAP-1, OPP-02, OPP-03, OPP-04, OPP-05, OPP-06, OPP-07, OPP-08, OPP-12, OPP-14\n"
     "-- Deferred to Standardizer: OPP-11, OPP-13\n"
     "-- Not applied: OPP-01 (Cond.Safe), OPP-09, OPP-10 (Unsafe), OPP-15/16/17 (DBA)\n"
     "-- Source: 01_merged.sql"),
    ("-- 03_standardized.sql - PKG_GRP_LOAD_RPT_POLICY_DTL_R\n"
     "-- Stage 3: PL/SQL Standardize output\n"
     "-- Date: 2026-08-04\n"
     "-- Applied standards: STD-01, STD-02, STD-03, STD-04, STD-05, STD-06, STD-09, STD-10, STD-11\n"
     "-- Deferred: STD-07 (carrier NVL function), STD-08 (SELECT * inline views)\n"
     "-- Source: 02_optimized.sql"),
    count=1
)

# ---------------------------------------------------------------------------
# STD-10: Fix typo in cursor comment (Breave -> Bereave)
# ---------------------------------------------------------------------------
apply(
    'STD-10',
    "\t--Cursor to fetch Breave Description\n",
    "\t--Cursor to fetch Bereave Description\n",
    count=1
)

# ---------------------------------------------------------------------------
# STD-06a: Add AS to V_BEREAVEDATE_R alias
# ---------------------------------------------------------------------------
apply(
    'STD-06a (V_BEREAVEDATE_R)',
    "MAX(t4805277.v_override_description_r) V_BEREAVEDATE_R",
    "MAX(t4805277.v_override_description_r) AS V_BEREAVEDATE_R",
    count=1
)

# ---------------------------------------------------------------------------
# STD-06b: Add AS to v_agency_code_r alias
# ---------------------------------------------------------------------------
apply(
    'STD-06b (v_agency_code_r)',
    "WITHIN GROUP (ORDER BY agent.n_policy_sk_r,agent.n_reportmonth_r) v_agency_code_r,",
    "WITHIN GROUP (ORDER BY agent.n_policy_sk_r,agent.n_reportmonth_r) AS v_agency_code_r,",
    count=1
)

# ---------------------------------------------------------------------------
# STD-06c: Add AS to D_SUBMISSION_DATE_R alias
# ---------------------------------------------------------------------------
apply(
    'STD-06c (D_SUBMISSION_DATE_R)',
    "MAX(D_BUSINESS_EFF_START_DATE_R)D_SUBMISSION_DATE_R",
    "MAX(D_BUSINESS_EFF_START_DATE_R) AS D_SUBMISSION_DATE_R",
    count=1
)

# ---------------------------------------------------------------------------
# STD-06d: Add AS to v_line_of_business_r alias
# ---------------------------------------------------------------------------
apply(
    'STD-06d (v_line_of_business_r)',
    "v_policy_suffix_r v_line_of_business_r",
    "v_policy_suffix_r AS v_line_of_business_r",
    count=1
)

# ---------------------------------------------------------------------------
# STD-09: Replace INDEX BY BINARY_INTEGER with INDEX BY PLS_INTEGER
# 16 in PRC_UPD_COL_DETAILS + 1 in MAIN (being removed by STD-02)
# ---------------------------------------------------------------------------
bi_count = content.count("INDEX BY BINARY_INTEGER")
if bi_count != 17:
    failures.append(f'STD-09: expected 17 BINARY_INTEGER occurrences, found {bi_count}')
else:
    content = content.replace("INDEX BY BINARY_INTEGER", "INDEX BY PLS_INTEGER")
    changes.append(f'STD-09: OK (replaced {bi_count}x INDEX BY BINARY_INTEGER -> PLS_INTEGER)')

# ---------------------------------------------------------------------------
# STD-02: Remove 6 dead declarations from MAIN
# After STD-09, the MAIN TYPE declaration now reads PLS_INTEGER
# ---------------------------------------------------------------------------
apply(
    'STD-02 (6 dead MAIN decls)',
    (" TYPE lt_var_tbl_type IS TABLE OF RPT_POLICY_DTL_R%ROWTYPE INDEX BY PLS_INTEGER;\n"
     "      lt_var_tbl_type_rec lt_var_tbl_type;\n"
     "      lc_var_ref_cur \t\tSYS_REFCURSOR;\n"
     "      lt_insert_time\t    PRCS_JOB_LOG_MESSAGE_R.D_CREATION_DATE_R%TYPE  ;\n"
     "      lv_rpt_table \t\t    PRCS_JOB_LOG_R.CREATED_BY_R%TYPE \t\t\t    :='RPT_POLICY_DTL_R';\n"
     "\t  ln_loop_counter       PLS_INTEGER                          \t\t    := 1;\n"),
    "",
    count=1
)

# ---------------------------------------------------------------------------
# STD-05: Remove duplicate d_id_theft_date_r assignment
# ---------------------------------------------------------------------------
apply(
    'STD-05 (duplicate assignment)',
    "\t\t\t LT_VAR_UPD_TBL_THEFT_DT_TYP_REC(x).d_id_theft_date_r:=ld_theft_dt;\n",
    "",
    count=1
)

# ---------------------------------------------------------------------------
# STD-01: Remove duplicate EXCEPTION keyword
# ---------------------------------------------------------------------------
apply(
    'STD-01 (duplicate EXCEPTION)',
    ("\t\tEXCEPTION\n"
     "\t\tEXCEPTION WHEN OTHERS THEN                                              -- OPT-06: log instead of swallowing\n"),
    "\t\tEXCEPTION WHEN OTHERS THEN                                              -- OPT-06: log instead of swallowing\n",
    count=1
)

# ---------------------------------------------------------------------------
# STD-04: Add missing log call in theft-date WHEN OTHERS block
# ---------------------------------------------------------------------------
apply(
    'STD-04 (add logger call)',
    ("\t\t    gv_trcmsg := 'Error parsing theft date: ' || gv_errmsg;\n"
     "\t\t    -- non-fatal: continue processing remaining rows\n"),
    ("\t\t    gv_trcmsg := 'Error parsing theft date: ' || gv_errmsg;\n"
     "\t\t    PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(\n"
     "\t\t\t     p_job_id_r                    => gn_out_job_id\n"
     "\t\t\t    ,p_batch_id_r                  => gn_sysdt_batchid\n"
     "\t\t\t    ,p_message_type_r              => gv_message_type\n"
     "\t\t\t    ,p_code_location_r             => gv_upd_ind_cols_by\n"
     "\t\t\t    ,p_message_r                   => gv_trcmsg\n"
     "\t\t\t    ,p_count_type_r                => NULL\n"
     "\t\t\t    ,p_count_r                     => NULL\n"
     "\t\t\t    ,p_duration_r                  => NULL\n"
     "\t\t\t    ,p_created_by_r                => GV_JOB_NAME\n"
     "\t\t\t    ,out_prcs_job_log_message_id_r => gn_job_log_message_id\n"
     "\t\t\t);\n"
     "\t\t    -- non-fatal: continue processing remaining rows\n"),
    count=1
)

# ---------------------------------------------------------------------------
# STD-03: Fix wrong logger constant in PRC_UPD_COL_DETAILS EXCEPTION
# Use END PRC_UPD_COL_DETAILS as anchor to target L1685 not L2219
# ---------------------------------------------------------------------------
apply(
    'STD-03 (fix logger constant in PRC_UPD_COL_DETAILS)',
    ("                ,GV_dummyrec_loadedby\n"
     "              );\n"
     "        RAISE;\n"
     "  END PRC_UPD_COL_DETAILS;\n"),
    ("                ,gv_upd_ind_cols_by\n"
     "              );\n"
     "        RAISE;\n"
     "  END PRC_UPD_COL_DETAILS;\n"),
    count=1
)

# ---------------------------------------------------------------------------
# Write output
# ---------------------------------------------------------------------------
with open(DST, 'w', encoding='utf-8') as f:
    f.write(content)

print("=" * 60)
print("  03_standardized.sql — Transformation Report")
print("=" * 60)
print("\n  APPLIED:")
for c in changes:
    print(f"    ✓ {c}")
if failures:
    print("\n  FAILURES:")
    for fail in failures:
        print(f"    ✗ {fail}")
else:
    print("\n  No failures.")

line_count = content.count('\n')
src_lines = open(SRC, encoding='utf-8').read().count('\n')
print(f"\n  Source lines : {src_lines}")
print(f"  Output lines : {line_count}")
print(f"  Delta        : {line_count - src_lines:+d}")

# Verify no BINARY_INTEGER left (outside comments doesn't matter - all removed)
remaining_bi = content.count('BINARY_INTEGER')
print(f"\n  Remaining BINARY_INTEGER: {remaining_bi}")
remaining_dup_exc = content.count('\t\tEXCEPTION\n\t\tEXCEPTION')
print(f"  Remaining duplicate EXCEPTION: {remaining_dup_exc}")
print(f"\n  Output: {DST}")
