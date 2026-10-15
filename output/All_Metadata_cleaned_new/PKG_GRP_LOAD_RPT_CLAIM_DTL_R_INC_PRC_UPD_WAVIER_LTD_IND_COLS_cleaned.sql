-- Cleaned for lineage: PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC_PRC_UPD_WAVIER_LTD_IND_COLS

gc_trcmsg := gc_trcmsg || '1.2 update Ltd ind from prc_upd_wavier_ltd_ind_cols ' || ln_start_time || CHR(13);

FORALL X IN 1 .. lt_var_upd_tbl_ltd_ind_typ.COUNT
            UPDATE RPT_CLAIM_DTL_R
            SET v_has_associated_ltd_ind_r = lt_var_upd_tbl_ltd_ind_typ(X).v_has_associated_waiver_ind_r
            WHERE n_claim_sk_r = lt_var_upd_tbl_ltd_ind_typ(X).n_claim_sk_r
              AND n_claim_coverage_sk_r = lt_var_upd_tbl_ltd_ind_typ(X).n_claim_coverage_sk_r
              AND n_claim_coverage_group_sk_r = lt_var_upd_tbl_ltd_ind_typ(X).n_claim_coverage_group_sk_r
              AND n_yearmonth_r = gn_current_month;

gc_trcmsg := gc_trcmsg || '1.z Update Ltd completed from prc_upd_wavier_ltd_ind_cols ' || ((dbms_utility.get_time - ln_start_time) / 100) || CHR(13);

gc_trcmsg := gc_trcmsg || '2.1 update Wavier ind from prc_upd_wavier_ltd_ind_cols ' || ln_start_time || CHR(13);

FORALL X IN 1 .. lt_var_upd_tbl_wavier_ind_typ.COUNT
            UPDATE RPT_CLAIM_DTL_R
            SET v_has_associated_waiver_ind_r = lt_var_upd_tbl_wavier_ind_typ(X).v_has_associated_ltd_ind_r
            WHERE n_claim_sk_r = lt_var_upd_tbl_wavier_ind_typ(X).n_claim_sk_r
              AND n_claim_coverage_sk_r = lt_var_upd_tbl_wavier_ind_typ(X).n_claim_coverage_sk_r
              AND n_claim_coverage_group_sk_r = lt_var_upd_tbl_wavier_ind_typ(X).n_claim_coverage_group_sk_r
              AND n_yearmonth_r = gn_current_month;

gc_trcmsg := gc_trcmsg || '2.z Update waiver completed from prc_upd_wavier_ltd_ind_cols ' || ((dbms_utility.get_time - ln_start_time) / 100) || CHR(13);

-- Lineage: Cursor CUR_UPD_LTD_IND -> UPDATE LTD
-- Source query:
SELECT
            n_ltd_claim_sk_r                n_claim_sk_r,
            n_ltd_claim_coverage_sk_r       n_claim_coverage_sk_r,
            n_ltd_claim_coverage_group_sk_r n_claim_coverage_group_sk_r,
            v_ltd_claim_number_r            v_claim_number_r,
            v_ltd_claim_identifier_r        v_claim_identifier_r,
            'Y'                             v_has_associated_waiver_ind_r,
            NULL                            v_has_associated_ltd_ind_r
        FROM
            atomic.rpt_associated_claims_mv_ssl
        GROUP BY n_ltd_claim_sk_r
               , n_ltd_claim_coverage_sk_r
               , n_ltd_claim_coverage_group_sk_r
               , v_ltd_claim_number_r
               , v_ltd_claim_identifier_r;

-- Lineage: Cursor CUR_UPD_WAVIER_IND -> UPDATE LTD
-- Source query:
SELECT
            n_wop_claim_sk_r                n_claim_sk_r,
            n_wop_claim_coverage_sk_r       n_claim_coverage_sk_r,
            n_wop_claim_coverage_group_sk_r n_claim_coverage_group_sk_r,
            v_wop_claim_number_r            v_claim_number_r,
            v_wop_claim_identifier_r        v_claim_identifier_r,
            NULL                            v_has_associated_waiver_ind_r,
            'Y'                             v_has_associated_ltd_ind_r
        FROM
            atomic.rpt_associated_claims_mv_ssl
        GROUP BY n_wop_claim_sk_r
               , n_wop_claim_coverage_sk_r
               , n_wop_claim_coverage_group_sk_r
               , v_wop_claim_number_r
               , v_wop_claim_identifier_r;