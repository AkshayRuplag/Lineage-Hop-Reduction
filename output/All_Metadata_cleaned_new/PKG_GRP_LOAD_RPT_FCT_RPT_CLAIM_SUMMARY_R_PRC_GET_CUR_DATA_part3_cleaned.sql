-- Cleaned for lineage: PKG_GRP_LOAD_RPT_FCT_RPT_CLAIM_SUMMARY_R_PRC_GET_CUR_DATA (part 3/3)

-- Lineage: Cursor CUR_UPD_CLAIM_ATTR (target inferred from procedure)
select
			ROWID ROW_ID
			,n_claim_sk_r
			,n_claim_coverage_sk_r
			,n_claim_coverage_group_sk_r
			,d_claim_decision_date_r
			,v_claim_decision_ind_r
			,v_claim_activity_detail_r
			,d_potential_resolution_date_r
		,PKG_GRP_LOAD_RPT_FCT_RPT_CLAIM_SUMMARY_R.get_n_avg_claim_decision_days_r(
										n_claim_sk_r
									   ,n_claim_coverage_sk_r
									   ,n_claim_coverage_group_sk_r
									   ,d_claim_decision_date_r
									   ,v_claim_decision_ind_r
									   ,gn_current_month
									   ) n_avg_claim_decision_days_r
		,PKG_GRP_LOAD_RPT_FCT_RPT_CLAIM_SUMMARY_R.get_n_claim_approach_dur_r
								   (n_claim_sk_r
								   ,n_claim_coverage_sk_r
								   ,n_claim_coverage_group_sk_r
								   ,v_claim_activity_detail_r
								   ,gd_pacs_as_of_date_r
								   ,gn_current_month
								   ) n_claim_approach_dur_r
		,PKG_GRP_LOAD_RPT_FCT_RPT_CLAIM_SUMMARY_R.get_n_claim_approach_exp_resolution_r
										   (n_claim_sk_r
										   ,n_claim_coverage_sk_r
										   ,n_claim_coverage_group_sk_r
										   ,d_potential_resolution_date_r
										   ,v_claim_activity_detail_r
										   ,gd_pacs_as_of_date_r
										   ,gn_current_month
										   ) n_claim_approach_exp_resolution_r
		,PKG_GRP_LOAD_RPT_FCT_RPT_CLAIM_SUMMARY_R.get_n_duration_remaining_r
									 (n_claim_sk_r
								   ,n_claim_coverage_sk_r
								   ,n_claim_coverage_group_sk_r
								   ,gd_pacs_as_of_date_r
								   ,gn_current_month
								   ) n_duration_remaining_r
		from RPT_FCT_RPT_CLAIM_SUMMARY_R
		where n_yearmonth_r=gn_current_month;