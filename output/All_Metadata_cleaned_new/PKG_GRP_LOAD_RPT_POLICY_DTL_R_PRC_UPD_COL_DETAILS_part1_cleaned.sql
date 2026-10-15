-- Cleaned for lineage: PKG_GRP_LOAD_RPT_POLICY_DTL_R_PRC_UPD_COL_DETAILS (part 1/4)

BEGIN
	gv_trcmsg:='9.1 Update v_client_name_r starts from main ';

UPDATE rpt_policy_dtl_r
           SET v_client_name_r = lt_var_upd_tbl_client_typ_rec(X).v_client_name_r
         WHERE n_cust_party_sk_r = lt_var_upd_tbl_client_typ_rec(X).n_cust_party_sk_r
           AND n_yearmonth_r = gn_current_month;

gv_trcmsg :='9.2 Update v_client_name_r Completed from main';

gv_trcmsg:='9.5 Update v_prs_strs_ind_r Start from main';

UPDATE RPT_POLICY_DTL_R
	  SET v_prs_strs_ind_r= lt_var_upd_prs_strs_indp_rec(X).v_prs_strs_ind_r
	WHERE n_policy_sk_r=lt_var_upd_prs_strs_indp_rec(X).n_policy_sk_r
	  AND n_yearmonth_r=gn_current_month;

gv_trcmsg:='9.6 Update v_prs_strs_ind_r Completed from main';

gv_trcmsg:='9.7 Update D_UW_CYCLE_DATE_R,D_UW_LAST_UPDATE_DATE_R and few other columns Start from main';

UPDATE RPT_POLICY_DTL_R
	  SET D_UW_CYCLE_DATE_R= lt_var_upd_tbl_uw_typ_rec(X).D_UW_CYCLE_DATE_R,
		  D_UW_LAST_UPDATE_DATE_R= lt_var_upd_tbl_uw_typ_rec(X).D_UW_LAST_UPDATE_DATE_R
		  ,D_UW_NEXT_RENEWAL_DATE_R          = lt_var_upd_tbl_uw_typ_rec(X).D_UW_NEXT_RENEWAL_DATE_R
		  ,V_UW_NEEDED_UNDERWRITER_NAME_R    = lt_var_upd_tbl_uw_typ_rec(X).V_UW_NEEDED_UNDERWRITER_NAME_R
		  ,V_UW_NEEDED_COMMENTS_R            = lt_var_upd_tbl_uw_typ_rec(X).V_UW_NEEDED_COMMENTS_R
		  ,N_UW_NEEDED_PERCENT_R             = lt_var_upd_tbl_uw_typ_rec(X).N_UW_NEEDED_PERCENT_R
		  ,V_UW_NEEDED_RENEWAL_STATUS_R      = lt_var_upd_tbl_uw_typ_rec(X).V_UW_NEEDED_RENEWAL_STATUS_R
		  ,N_UW_REQUESTED_PERCENT_R          = lt_var_upd_tbl_uw_typ_rec(X).N_UW_REQUESTED_PERCENT_R
		  ,V_UW_TRK_NEEDED_UW_NAME_R         = lt_var_upd_tbl_uw_typ_rec(X).V_UW_TRK_NEEDED_UW_NAME_R
		  ,V_UW_TRK_NEEDED_COMMENTS_R        = lt_var_upd_tbl_uw_typ_rec(X).V_UW_TRK_NEEDED_COMMENTS_R
		  ,N_UW_TRK_NEEDED_PERCENT_R         = lt_var_upd_tbl_uw_typ_rec(X).N_UW_TRK_NEEDED_PERCENT_R
		  ,V_UW_TRK_NEEDED_RENEW_STATUS_R    = lt_var_upd_tbl_uw_typ_rec(X).V_UW_TRK_NEEDED_RENEW_STATUS_R
		  ,N_UW_TRK_REQUESTED_PERCENT_R      = lt_var_upd_tbl_uw_typ_rec(X).N_UW_TRK_REQUESTED_PERCENT_R
	WHERE n_policy_sk_r=lt_var_upd_tbl_uw_typ_rec(X).n_policy_sk_r
	  AND N_YEARMONTH_R=gn_current_month;

gv_trcmsg:='9.8 Update D_UW_CYCLE_DATE_R,D_UW_LAST_UPDATE_DATE_R and few other columns Completed from main';

gv_trcmsg:='9.9 Update V_ID_THEFT_IND_R Start from main';

UPDATE RPT_POLICY_DTL_R
	  SET V_ID_THEFT_IND_R      = lt_var_upd_tbl_theft_ind_typ_rec(X).V_ID_THEFT_IND_R
	WHERE n_policy_sk_r=lt_var_upd_tbl_theft_ind_typ_rec(X).n_policy_sk_r
	  AND N_YEARMONTH_R=gn_current_month;

gv_trcmsg:='9.10 Update V_ID_THEFT_IND_R Completed from main';

gv_trcmsg:='9.11 Update D_ID_THEFT_DATE_R Start from main';

UPDATE RPT_POLICY_DTL_R
	  SET D_ID_THEFT_DATE_R = LT_VAR_UPD_TBL_THEFT_DT_TYP_REC(X).d_id_theft_date_r
	WHERE n_policy_sk_r     = LT_VAR_UPD_TBL_THEFT_DT_TYP_REC(X).n_policy_sk_r
	  AND N_YEARMONTH_R=gn_current_month;

gv_trcmsg:='9.12 Update D_ID_THEFT_DATE_R Completed from main';

gv_trcmsg:='9.13 START: UPDATE N_ANY_OCC_DAYS_REMAINING_R COLUMN';

UPDATE RPT_POLICY_DTL_R
	    SET V_ELIM_PERIOD_R   = lt_var_upd_tbl_elimperiod_typ_rec(X).V_ELIM_PERIOD_R
	  WHERE n_policy_sk_r     = lt_var_upd_tbl_elimperiod_typ_rec(X).n_policy_sk_r
	    AND N_YEARMONTH_R=gn_current_month;

gv_trcmsg:='9.14 Update V_ELIM_PERIOD_R Completed from main ';

gv_trcmsg:='9.15 Update Cross Sell cols Start from main';

UPDATE RPT_POLICY_DTL_R
	  SET  v_cross_sell_indicator_r       = lt_var_upd_tbl_cross_sell_typ(X).v_cross_sell_indicator_r
		  ,v_6mnth_cross_sell_indicator_r = lt_var_upd_tbl_cross_sell_typ(X).v_6mnth_cross_sell_indicator_r
		  ,v_any_lob_cross_sell_r         = lt_var_upd_tbl_cross_sell_typ(X).v_any_lob_cross_sell_r
	      ,v_ltd_cross_sell_r             = lt_var_upd_tbl_cross_sell_typ(X).v_ltd_cross_sell_r
	      ,v_std_cross_sell_r             = lt_var_upd_tbl_cross_sell_typ(X).v_std_cross_sell_r
	      ,v_life_cross_sell_r            = lt_var_upd_tbl_cross_sell_typ(X).v_life_cross_sell_r
	      ,v_basic_life_cross_sell_r      = lt_var_upd_tbl_cross_sell_typ(X).v_basic_life_cross_sell_r
	      ,v_supp_life_cross_sell_r       = lt_var_upd_tbl_cross_sell_typ(X).v_supp_life_cross_sell_r
	      ,v_dep_life_cross_sell_r        = lt_var_upd_tbl_cross_sell_typ(X).v_dep_life_cross_sell_r
	      ,v_add_cross_sell_r             = lt_var_upd_tbl_cross_sell_typ(X).v_add_cross_sell_r
	      ,v_sr_cross_sell_r              = lt_var_upd_tbl_cross_sell_typ(X).v_sr_cross_sell_r
	      ,v_var_cross_sell_r             = lt_var_upd_tbl_cross_sell_typ(X).v_var_cross_sell_r
	      ,v_vai_cross_sell_r             = lt_var_upd_tbl_cross_sell_typ(X).v_vai_cross_sell_r
	      ,v_vci_cross_sell_r             = lt_var_upd_tbl_cross_sell_typ(X).v_vci_cross_sell_r
	      ,n_total_product_lines_r        = lt_var_upd_tbl_cross_sell_typ(X).n_total_product_lines_r
	WHERE n_policy_sk_r     = lt_var_upd_tbl_cross_sell_typ(X).n_policy_sk_r
	  AND n_yearmonth_r=gn_current_month;

gv_trcmsg:='9.16 Update upd_cross_sell_col Completed from main';

gv_trcmsg:='9.17 Update v_eap_desc_r Start from main';

UPDATE RPT_POLICY_DTL_R
	    SET v_eap_desc_r   = lt_var_upd_tbl_eap_desc_typ_rec(X).v_eap_desc_r
		,V_COVERAGE_CODE_R  = lt_var_upd_tbl_eap_desc_typ_rec(X).V_COVERAGE_CODE_R
	  WHERE n_policy_sk_r     = lt_var_upd_tbl_eap_desc_typ_rec(X).n_policy_sk_r
	    AND N_YEARMONTH_R=gn_current_month;

gv_trcmsg:='9.18 Update v_eap_desc_r Completed from main';

gv_trcmsg:='9.19 Update V_BEREAVE_DESC_R Start from main';

UPDATE RPT_POLICY_DTL_R
	    SET V_BEREAVE_DESC_R   = lt_var_upd_tbl_bereave_desc_typ_rec(X).V_BEREAVE_DESC_R
	  WHERE n_policy_sk_r     = lt_var_upd_tbl_bereave_desc_typ_rec(X).n_policy_sk_r
	    AND N_YEARMONTH_R=gn_current_month;

gv_trcmsg:='9.20 Update V_BEREAVE_DESC_R Completed from main';

gv_trcmsg:='9.21 Update V_EAP_EFF_DATE_R Start from main ';

UPDATE RPT_POLICY_DTL_R
	    SET V_EAP_EFF_DATE_R   = lt_var_upd_tbl_eap_eff_date_typ_rec(X).V_EAP_EFF_DATE_R
	  WHERE n_policy_sk_r     = lt_var_upd_tbl_eap_eff_date_typ_rec(X).n_policy_sk_r
	    AND N_YEARMONTH_R=gn_current_month;

gv_trcmsg:='9.22 Update V_EAP_EFF_DATE_R Completed from main';

gv_trcmsg:='9.23 Update V_BEREAVEDATE_R Start from main ';

UPDATE RPT_POLICY_DTL_R
	    SET V_BEREAVEDATE_R   = lt_var_upd_tbl_bereavedate_typ_rec(X).V_BEREAVEDATE_R
	  WHERE n_policy_sk_r     = lt_var_upd_tbl_bereavedate_typ_rec(X).n_policy_sk_r
	    AND N_YEARMONTH_R=gn_current_month;

gv_trcmsg:='9.24 Update V_BEREAVEDATE_R Completed from main';

gv_trcmsg:='9.25 Update D_NEXT_RENEWAL_DATE_R Start from main ';

UPDATE RPT_POLICY_DTL_R
        SET D_NEXT_RENEWAL_DATE_R = lt_var_upd_tbl_nxtrenewaldt_typ_rec(X).D_NEXT_RENEWAL_DATE_R
        WHERE n_policy_sk_r = lt_var_upd_tbl_nxtrenewaldt_typ_rec(X).n_policy_sk_r
          AND N_YEARMONTH_R = gn_current_month;

gv_trcmsg:='9.26 Update D_NEXT_RENEWAL_DATE_R Completed from main';

gv_trcmsg:='9.27 Update d_rate_guar_r Start from main ';

UPDATE RPT_POLICY_DTL_R
	    SET d_rate_guar_r   = lt_var_upd_tbl_d_rate_guar_r_typ_rec(X).d_rate_guar_r
	  WHERE n_policy_sk_r     = lt_var_upd_tbl_d_rate_guar_r_typ_rec(X).n_policy_sk_r
	    AND N_YEARMONTH_R=gn_current_month;

gv_trcmsg:='9.28 Update d_rate_guar_r Completed from main';

gv_trcmsg:='9.29 Update option cols Start from main ';

UPDATE RPT_POLICY_DTL_R
	    SET d_option_eff_date_r   = lt_var_upd_tbl_option_typ_rec(X).d_option_eff_date_r
	      , v_option_r            = lt_var_upd_tbl_option_typ_rec(X).v_option_r
	      , n_new_option_rate_r   = lt_var_upd_tbl_option_typ_rec(X).n_new_option_rate_r
	  WHERE rowid     = lt_var_upd_tbl_option_typ_rec(X).row_id
	    AND N_YEARMONTH_R=gn_current_month;

gv_trcmsg:='9.30 Update option cols Completed from main';

gv_trcmsg:='9.31 Update v_agency_code_r Start from main ';

FORALL X IN 1 .. lt_var_upd_tbl_agencycode_typ_rec.COUNT
        UPDATE rpt_policy_dtl_r
           SET v_agency_code_r = lt_var_upd_tbl_agencycode_typ_rec(X).v_agency_code_r
         WHERE n_policy_sk_r = lt_var_upd_tbl_agencycode_typ_rec(X).n_policy_sk_r
           AND n_yearmonth_r = gn_current_month;

gv_trcmsg:='9.32 Update v_agency_code_r  Completed from main';

gv_trcmsg:='9.33 Update D_SUBMISSION_DATE_R Start from main ';

UPDATE RPT_POLICY_DTL_R
        SET D_SUBMISSION_DATE_R = lt_var_upd_tbl_submissiondt_typ_rec(X).D_SUBMISSION_DATE_R
        WHERE n_policy_sk_r = lt_var_upd_tbl_submissiondt_typ_rec(X).n_policy_sk_r
          AND N_YEARMONTH_R = gn_current_month;

gv_trcmsg:='9.34 Update D_SUBMISSION_DATE_R  Completed from main';

gv_trcmsg:='9.35 Update D_NEXT_RENEWAL_EFFECTIVE_DATE_R Start from main ';

UPDATE RPT_POLICY_DTL_R
        SET D_NEXT_RENEWAL_EFFECTIVE_DATE_R = lt_var_upd_tbl_nxtrenewaleffdt_typ_rec(X).D_NEXT_RENEWAL_EFFECTIVE_DATE_R
        WHERE n_policy_sk_r = lt_var_upd_tbl_nxtrenewaleffdt_typ_rec(X).n_policy_sk_r
          AND N_YEARMONTH_R = gn_current_month;

gv_trcmsg:='9.36 Update D_NEXT_RENEWAL_EFFECTIVE_DATE_R  Completed from main';

gv_trcmsg:='9.37 Update V_POLICY_INFORCE_INDICATOR_R Start from main ';