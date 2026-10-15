-- Cleaned for lineage: PKG_GRP_LOAD_RPT_FCT_RPT_CLAIM_SUMMARY_R_HIST_PRC_GET_CUR_DATA (part 1/1)

-- REF CURSOR lineage (OPEN ... FOR SELECT -> INSERT INTO RPT_FCT_RPT_CLAIM_SUMMARY_R_HIST)
INSERT INTO RPT_FCT_RPT_CLAIM_SUMMARY_R_HIST
SELECT 
				t3332218.n_claim_sk_r,
				t3332218.n_product_sk_r,
				t3332218.n_party_sk_r,
				t3332218.n_policy_sk_r,
				t3332218.n_no_of_payments_r,
				t3332218.n_no_of_checks_r,
				t3332218.n_no_of_void_payments_r,
				t3332218.n_no_of_void_checks_r,
				t3332218.n_total_claim_count_r,
				t3332218.n_chg_total_claim_count_r,
				t3332218.n_reopen_claim_count_r,
				t3332218.n_chg_reopen_claim_count_r,
				t3332218.n_pending_claim_count_r,
				t3332218.n_chg_pending_claim_count_r,
				t3332218.n_approved_claim_count_r,
				t3332218.n_chg_approved_claim_count_r,
				t3332218.n_closed_claim_count_r,
				t3332218.n_chg_closed_claim_count_r,
				t3332218.n_gaap_os_reserve_count_r,
				t3332218.n_chg_gaap_os_reserve_count_r,
				t3332218.n_gaap_wv_reserve_count_r,
				t3332218.n_chg_gaap_wv_reserve_count_r,
				t3332218.n_stat_os_reserve_count_r,
				t3332218.n_chg_stat_os_reserve_count_r,
				t3332218.n_stat_wv_reserve_count_r,
				t3332218.n_chg_stat_wv_reserve_count_r,
				t3332218.n_payment_direct_amt_r,
				t3332218.n_loss_payment_direct_amt_r,
				t3332218.n_wage_base_r,
				t3332218.n_taxable_benefits_r,
				t3332218.n_non_taxable_benefits_r,
				t3332218.n_fit_r,
				t3332218.n_sit_r,
				t3332218.n_fica_r,
				t3332218.n_medicare_tax_r,
				t3332218.n_fica_wage_base_r,
				t3332218.n_medicare_wage_base_r,
				t3332218.n_employer_fica_r,
				t3332218.n_employer_medicare_tax_r,
				t3332218.n_emp_fica_wage_base_r,
				t3332218.n_emp_medicare_wage_base_r,
				t3332218.n_futa_r,
				t3332218.n_payment_taxable_benefits_r,
				t3332218.n_payment_nontaxable_ben_r,
				t3332218.n_prior_gaap_reserve_direct_r,
				t3332218.n_chg_gaap_os_direct_amt_r,
				t3332218.n_curr_gaap_reserve_direct_r,
				t3332218.n_prior_stat_reserve_direct_r,
				t3332218.n_chg_stat_os_direct_amt_r,
				t3332218.n_curr_stat_reserve_direct_r,
				t3332218.n_prior_gaap_wv_direct_amt_r,
				t3332218.n_chg_gaap_wv_direct_amt_r,
				t3332218.n_curr_gaap_wv_direct_amt_r,
				t3332218.n_prior_stat_wv_direct_amt_r,
				t3332218.n_chg_stat_wv_direct_amt_r,
				t3332218.n_curr_stat_wv_direct_amt_r,
				t3332218.n_prior_be_direct_amt_r,
				t3332218.n_chg_be_reserve_direct_amt_r,
				t3332218.n_curr_be_reserve_direct_amt_r,
				t3332218.n_prior_field_res_direct_amt_r,
				t3332218.n_chg_field_res_direct_amt_r,
				t3332218.n_curr_field_res_direct_amt_r,
				t3332218.n_chg_be_reserve_ceded_amt_r,
				t3332218.n_chg_be_reserve_net_amt_r,
				t3332218.n_chg_field_res_net_amt_r,
				t3332218.n_curr_be_reserve_ceded_amt_r,
				t3332218.n_curr_be_reserve_net_amt_r,
				t3332218.n_curr_field_res_ceded_amt_r,
				t3332218.n_curr_field_res_net_amt_r,
				t3332218.n_init_clm_decision_days_r,
				t3332218.n_init_avg_clm_decision_days_r,
				t3332218.v_claim_decision_ind_r,
				t3332218.d_claim_decision_date_r,
				t3332218.d_first_payment_from_date_r,
				t3332218.d_last_payment_to_date_r,
				t3332218.d_first_payment_date_r,
				t3332218.d_last_payment_date_r,
				t3332218.n_new_claim_receipts_r,
				t3332218.n_denied_claims_r,
				t3332218.n_new_appeal_receipts_r,
				t3332218.n_claims_settled_r,
				t3332218.n_claims_with_overpayments_r,
				t3332218.n_claims_bridged_std_to_ltd_r,
				t3332218.n_clms_w_clinical_engagement_r,
				t3332218.n_ltd_approved_clms_own_occ_r,
				t3332218.n_ltd_apprved_ownocc_fulldur_r,
				t3332218.n_ltd_approved_clms_any_occ_r,
				t3332218.v_ltd_any_occ_group_r,
				t3332218.n_ltd_approved_pas_claims_r,
				t3332218.v_ss_pursue_indicated_r,
				t3332218.n_claims_referred_ss_vendor_r,
				t3332218.n_primary_ss_awards_counts_r,
				t3332218.n_primary_ss_awards_total_r,
				t3332218.n_dependent_ss_awards_counts_r,
				t3332218.n_dependent_ss_awards_total_r,
				t3332218.n_settlements_offered_r,
				t3332218.n_settlement_offers_declined_r,
				t3332218.n_overpayment_balance_r,
				t3332218.n_overpayments_recovered_r,
				t3332218.n_initial_closure_r,
				t3332218.v_paid_and_closed_r,
				t3332218.d_decision_made_date_r,
				t3332218.n_aged_pending_claims_r,
				t3332218.n_avg_tasks_completed_day_r,
				t3332218.n_claim_touches_per_day_r,
				t3332218.n_avg_task_aging_r,
				t3332218.n_production_balance_ratio_r,
				t3332218.n_no_of_extensions_per_claim_r,
				t3332218.n_avg_days_claim_decision_r,
				t3332218.n_avg_days_rec_clm_decision_r,

(  (CASE  WHEN V_CLAIM_DECISION_IND_R = 'Y' and UPPER(
					CASE
					 WHEN t3332146.v_product_sub_line_code_r  NOT IN ('SR', 'VAR', 'Group Life') THEN t3332218.V_CLAIM_ACTIVITY_DETAIL_R
					 WHEN t3332146.v_product_sub_line_code_r  IN ('SR', 'VAR', 'Group Life') AND t3332218.v_coverage_code_r IN ('WP', 'WPS', 'IWP', 'BWP') THEN t3332218.V_CLAIM_ACTIVITY_DETAIL_R
					 ELSE t3332218.V_CLAIM_DECISION_TYPE_R
					END
					) LIKE  'APPROVED%'
					THEN N_APPROVED_CLAIM_COUNT_R + N_CLOSED_CLAIM_COUNT_R
					ELSE 0 END
					)+
					(CASE WHEN t3332218.V_CLAIM_DECISION_IND_R = 'Y'
					AND NOT UPPER(
								CASE
									WHEN t3332146.v_product_sub_line_code_r  NOT IN ('SR', 'VAR', 'Group Life') THEN t3332218.V_CLAIM_ACTIVITY_DETAIL_R
									WHEN t3332146.v_product_sub_line_code_r  IN ('SR', 'VAR', 'Group Life') AND t3332218.v_coverage_code_r IN ('WP', 'WPS', 'IWP', 'BWP') THEN t3332218.V_CLAIM_ACTIVITY_DETAIL_R
									ELSE t3332218.V_CLAIM_DECISION_TYPE_R
								END
								) LIKE  'APPROVED%'
					THEN t3332218.N_APPROVED_CLAIM_COUNT_R + t3332218.N_CLOSED_CLAIM_COUNT_R
					ELSE 0
					END
					)
				)
				
				 as N_Initial_Approval_Rate_R,
				t3332218.n_approval_rate_by_plan_ep_r,
				t3332218.n_initial_closure_rate_r,
				
				((t3332218.N_PENDING_CLAIM_COUNT_R - t3332218.N_CHG_PENDING_CLAIM_COUNT_R) +
				(t3332218.N_APPROVED_CLAIM_COUNT_R - t3332218.N_CHG_APPROVED_CLAIM_COUNT_R))          AS N_Closure_Rate_R,
				
				t3332218.n_closure_rate_ownocc_period_r,
				t3332218.n_closure_rate_anyocc_period_r,
				t3332218.n_reopen_rate_r,
				t3332218.n_appeal_rate_r,
				t3332218.n_any_occ_approval_rate_r,
				t3332218.n_pas_acceptance_rate_stat35_r,
				t3332218.n_actual_duration_r,
				t3332218.n_duration_by_plan_ep_r,
				t3332218.n_avg_payment_amt_r,
				t3332218.n_avg_caseloads_r,
				t3332218.n_actual_to_expected_r,
				t3332218.n_ltd_claim_settlement_rate_r,
				t3332218.n_overpayment_recov_success_r,
				t3332218.n_ss_vendor_placement_rate_r,
				t3332218.n_ss_vendor_award_rate_r,
				t3332218.n_ss_claims_by_appeal_level_r,
				t3332218.n_sscompassionallow_apprvals_r,
				t3332218.n_nonss_represented_claims_r,
				t3332218.n_pension_eligible_claims_r,
				t3332218.n_pension_claims_no_offset_r,
				t3332218.n_init_approval_rt_clinical_r,
				t3332218.n_init_app_rt_wo_clinical_r,
				t3332218.n_closure_rate_with_clinical_r,
				t3332218.n_closure_rate_wo_clinical_r,
				t3332218.v_initial_clinical_indicator_r,
				t3332218.v_current_clinical_indicator_r,
				t3332218.n_claims_rtw_w_intervention_r,
				t3332218.n_claims_rtw_wo_intervention_r,
				t3332218.n_partial_rtw_w_accomodation_r,
				t3332218.n_part_time_rtw_claims_r,
				t3332218.n_no_of_vocational_touches_r,
				t3332218.n_number_of_clinical_touches_r,
				t3332218.n_segmentation_results_r,
				t3332218.n_claims_reviewed_for_fwa_r,
				t3332218.n_claims_identified_for_fwa_r,
				t3332218.n_quality_review_score_r,
				t3332218.v_elimination_period_group_r,
				t3332218.v_claim_activity_type_r,
				t3332218.v_claim_activity_group_r,
				t3332218.v_claim_activity_detail_r,
				t3332218.n_claim_age_r,
				t3332218.v_reinsurance_indicator_r,
				t3332218.n_entry_error_count_r,
				t3332218.n_new_claim_error_r,
				t3332218.n_new_claim_count_adjusted_r,
				t3332218.n_entry_error_adjusted_r,
				t3332218.n_batch_id_r,
				t3332218.n_load_run_id_r,
				t3332218.n_sequence_number_r,
				t3332218.t_creation_date_r,
				t3332218.t_event_timestamp_r,
				t3332218.t_last_modified_date_r,
				t3332218.v_created_by_r,
				t3332218.v_last_modified_by_r,

t3332275.v_source_system_name_r,
				t3332218.v_subject_area_type_r,
				t3332218.n_version_number_r,
				t3332218.f_physical_delete_r,
				t3332218.v_change_reason_r,
				t3332218.d_cycle_date_r,
				t3332218.n_quote_sk_r,
				t3332218.v_decision_made_r,
				t3332218.v_tier_num_r,
				t3332218.v_tier_description_r,
				t3332218.v_accommodations_needed_r,
				t3332218.v_recovery_expectations_r,
				t3332275.v_wfam_r        as v_wfam_code_r,   
				t3332218.d_potential_resolution_date_r,
				t3332218.v_tax_number_r,
				t3332218.v_policy_number_r,
				t3332218.v_reinloss001_use_r,
				t3332218.n_chg_act_os_ceded_amt_r,
				t3332218.n_chg_act_os_net_amt_r,
				t3332218.n_chg_field_os_ceded_amt_r,
				t3332218.n_chg_field_os_net_amt_r,
				t3332218.n_chg_gaap_os_ceded_amt_r,
				t3332218.n_chg_gaap_os_net_amt_r,
				t3332218.n_chg_gaap_wv_ceded_amt_r,
				t3332218.n_chg_gaap_wv_net_amt_r,
				t3332218.n_chg_stat_os_ceded_amt_r,
				t3332218.n_chg_stat_os_net_amt_r,
				t3332218.n_chg_stat_wv_ceded_amt_r,
				t3332218.n_chg_stat_wv_net_amt_r,
				t3332218.n_curr_act_os_ceded_amt_r,
				t3332218.n_curr_act_os_net_amt_r,
				t3332218.n_curr_field_os_ceded_amt_r,
				t3332218.n_curr_field_os_net_amt_r,
				t3332218.n_curr_gaap_os_ceded_amt_r,
				t3332218.n_curr_gaap_os_net_amt_r,
				t3332218.n_curr_gaap_wv_ceded_amt_r,
				t3332218.n_curr_gaap_wv_net_amt_r,
				t3332218.n_curr_stat_os_ceded_amt_r,
				t3332218.n_curr_stat_os_net_amt_r,
				t3332218.n_curr_stat_wv_ceded_amt_r,
				t3332218.n_curr_stat_wv_net_amt_r,
				t3332218.n_loss_payment_ceded_amt_r,
				t3332218.n_loss_payment_net_amt_r,
				t3332218.n_payment_ceded_amt_r,
				t3332218.n_payment_net_amt_r,
				t3332218.n_primary_reins_loss_pct_r,
				t3332218.v_primary_reinsurer_r,
				t3332218.n_redirect_payment_ceded_amt_r,
				t3332218.n_redirect_payment_net_amt_r,
				t3332218.n_reserve_net_benefit_r,
				t3332218.n_sec_reins_loss_pct_r,
				t3332218.v_secondary_reinsurer_r,
				t3332218.n_ternary_reins_loss_pct_r,
				t3332218.v_ternary_reinsurer_r,
				t3332218.n_total_reins_loss_pct_r,
				
				t3332218.v_coverage_group_id_r,
				
				t3332218.n_claim_coverage_group_sk_r,
				t3332218.n_claim_coverage_sk_r,
				t3332218.v_clinical_voc_engagement_r,
				
				t3332218.n_chg_field_res_ceded_amt_r,
				t3332218.n_cycle_date_key_r,
				t3332218.d_received_date_r,
				t3332275.v_claim_coverage_code_r,
				
				t3332218.v_claim_status_reason_code_r,
				t3332218.v_reason_code_r,
				t3332218.n_insrd_party_sk_r,
				t3332218.n_employee_sk_r,
				t3332218.n_yearmonth_r,
				t3332218.v_rpt_active_status_r,
				
				CASE WHEN V_CLAIM_DECISION_IND_R = 'Y'
				THEN (NVL(D_CLAIM_DECISION_DATE_R, SYSDATE) - D_CLAIM_RECEIVED_DATE_R ) ELSE 0 END
				AS N_Avg_Claim_Decision_Days_R,
				
				t3332218.n_claim_approach_dur_r,
				t3332218.n_claim_approach_exp_resolution_r,
				t3332218.n_duration_remaining_r,
				t3332146.v_product_sub_line_code_r,
				t3332164.v_employee_full_name_r,
				t3332275.d_claim_closed_date_r,
				t3332275.v_claim_identifier_r,
				t3332275.n_curr_benefit_period_days_r,
				t3332275.n_total_benefit_period_days_r,
				t3332275.v_claim_status_desc_r,
				t3332218.v_prior_claim_status_code_r,
				t3332275.v_tier_r,
				t3332164.v_supervisor_full_name_r,
				t3332164.v_director_full_name_r,
				t3332256.d_policy_effective_date_r,
				trunc(t3332256.d_policy_effective_date_r)         d_trunc_pol_eff_date_r,
				nvl(t3332164.v_director_full_name_r, 'UNKNOWN')   v_director_full_name_adj_r,
				nvl(t3332164.v_supervisor_full_name_r, 'UNKNOWN') v_supervisor_full_name_adj_r,
				
				t3332275.v_tier_adj_r,                                           
				
				t3332275.d_trunc_claim_closed_date_r,                                           
				t3332275.v_curr_claim_status_code_r,
				t3332146.v_coverage_type_code_r,
				t3332146.v_coverage_type_r,
				t3332275.v_privacy_indicator_r,
				t3332164.v_business_unit_r,
				t3332177.v_ieb_type_r,
				t3332146.v_basic_product_line_desc_r,
				t3332146.v_basic_product_line_code_r,
				t3332256.fic_mis_date_r,
				t3332256.v_orig_lob_r,
				t3332275.d_any_occ_start_date_r,
				t3332275.d_claim_received_date_r,

CASE    WHEN t3332256.v_carrier_name_r = 'Reliance Standard Life Insurance Company'             THEN  'RSL'
						WHEN t3332256.v_carrier_name_r = 'First Reliance Standard Life Insurance Company'       THEN  'FRSLIC'
					else t3332256.v_carrier_name_r
					END AS v_short_name_r,
				
				t3332162.n_claims_year_r,
				concat(concat(
					CASE
						WHEN rtrim(to_char(t3332218.d_cycle_date_r, 'Mon')) = 'Jan' THEN
							'January'
						WHEN rtrim(to_char(t3332218.d_cycle_date_r, 'Mon')) = 'Feb' THEN
							'February'
						WHEN rtrim(to_char(t3332218.d_cycle_date_r, 'Mon')) = 'Mar' THEN
							'March'
						WHEN rtrim(to_char(t3332218.d_cycle_date_r, 'Mon')) = 'Apr' THEN
							'April'
						WHEN rtrim(to_char(t3332218.d_cycle_date_r, 'Mon')) = 'May' THEN
							'May'
						WHEN rtrim(to_char(t3332218.d_cycle_date_r, 'Mon')) = 'Jun' THEN
							'June'
						WHEN rtrim(to_char(t3332218.d_cycle_date_r, 'Mon')) = 'Jul' THEN
							'July'
						WHEN rtrim(to_char(t3332218.d_cycle_date_r, 'Mon')) = 'Aug' THEN
							'August'
						WHEN rtrim(to_char(t3332218.d_cycle_date_r, 'Mon')) = 'Sep' THEN
							'September'
						WHEN rtrim(to_char(t3332218.d_cycle_date_r, 'Mon')) = 'Oct' THEN
							'October'
						WHEN rtrim(to_char(t3332218.d_cycle_date_r, 'Mon')) = 'Nov' THEN
							'November'
						WHEN rtrim(to_char(t3332218.d_cycle_date_r, 'Mon')) = 'Dec' THEN
							'December'
						ELSE
							rtrim(to_char(t3332218.d_cycle_date_r, 'Mon'))
					END,
					' '),
					   CAST(TO_NUMBER(to_char(t3332218.d_cycle_date_r, 'yyyy'),
			  '9999') AS VARCHAR(10)))                          AS claim_month1,
				concat(concat(CAST(rtrim(to_char(t3332218.d_cycle_date_r, 'Mon')) AS VARCHAR(10)),
							  ' '),
					   CAST(TO_NUMBER(to_char(t3332218.d_cycle_date_r, 'yyyy'),
			  '9999') AS VARCHAR(10)))                          AS claim_month2,
				TO_NUMBER(to_char(t3332218.d_cycle_date_r, 'yyyy'),
						  '9999') * 100 + TO_NUMBER(to_char(t3332218.d_cycle_date_r, 'MM'),
			  '99')                                             AS claim_month3,
				t3332162.N_BUSS_DAYS_IN_MONTH_R
				
				,t3332275.V_LEAVE_REASON_R                V_PFL_LEAVE_REASON_R
				,t3332275.V_MANDATED_FAMILY_MEMBER_R      V_PFL_FAMILY_MEMBER_RELATIONSHIP_R
				,t3332275.V_PFL_LEAVE_TYPE_R
				,t3332256.V_POLICY_PREFIX_R
				,t3332256.V_POLICY_SUFFIX_R
				,t3332275.V_CLAIM_COVERAGE_DESC_R
				,t3332275.N_BASIC_INSURED_SALARY_R
				,t3332275.V_BASIC_INSURED_SALARY_IND_R
				,t3332275.D_CLAIM_STATUS_EFF_DATE_R
				,t3332275.V_APPEAL_IND_R
				,t3332275.V_APPEAL_RESULT_STATUS_CODE_R
				,t3332275.D_APPEAL_RESULT_STATUS_CODE_EFF_DATE_R

,CAST(TO_CHAR(t3332218.D_CYCLE_DATE_R, 'Mon') || ' ' || TO_CHAR(t3332218.D_CYCLE_DATE_R, 'YYYY') AS VARCHAR2(15))                     AS V_cycle_Month_R,
				 EXTRACT(YEAR FROM t3332218.D_CYCLE_DATE_R) * 100 + EXTRACT(MONTH FROM t3332218.D_CYCLE_DATE_R)                                       AS N_Month_Sort_R,

(CASE  WHEN t3332218.V_CLAIM_DECISION_IND_R = 'Y' AND
					 UPPER(
						 CASE
							 WHEN t3332146.v_product_sub_line_code_r  NOT IN ('SR', 'VAR', 'Group Life') THEN t3332218.V_CLAIM_ACTIVITY_DETAIL_R
							 WHEN t3332146.v_product_sub_line_code_r  IN ('SR', 'VAR', 'Group Life')
							AND t3332218.v_coverage_code_r IN ('WP', 'WPS', 'IWP', 'BWP') THEN t3332218.V_CLAIM_ACTIVITY_DETAIL_R
							 ELSE t3332218.V_CLAIM_DECISION_TYPE_R
						 END
						 ) LIKE 'APPROVED%'
						 THEN N_APPROVED_CLAIM_COUNT_R + N_CLOSED_CLAIM_COUNT_R
					 ELSE 0
					END
					)
				 
				 AS N_Initial_Approval_Count_R,

(CASE WHEN t3332218.V_CLAIM_DECISION_IND_R = 'Y'
					AND NOT
					
					UPPER(
						CASE
						   WHEN t3332146.v_product_sub_line_code_r  NOT IN ('SR', 'VAR', 'Group Life') THEN t3332218.V_CLAIM_ACTIVITY_DETAIL_R
						   WHEN t3332146.v_product_sub_line_code_r  IN ('SR', 'VAR', 'Group Life')
						   AND t3332218.v_coverage_code_r IN ('WP', 'WPS', 'IWP', 'BWP') THEN t3332218.V_CLAIM_ACTIVITY_DETAIL_R
						   ELSE t3332218.V_CLAIM_DECISION_TYPE_R
						END
						) LIKE 'APPROVED%'
					 THEN t3332218.N_APPROVED_CLAIM_COUNT_R + t3332218.N_CLOSED_CLAIM_COUNT_R
					ELSE 0
					END
				 )
				 
				 AS N_Initial_Denial_Count_R,
				 CASE
				 WHEN UPPER(t3332218.V_CLAIM_ACTIVITY_GROUP_R) = 'OPEN'
				 AND UPPER(t3332218.V_CLAIM_ACTIVITY_DETAIL_R) = 'REOPENED'
				 THEN t3332218.N_TOTAL_CLAIM_COUNT_R
				 ELSE 0
				 END                                                                                                                                  AS N_Reopened_Claim_Count_R,
				 CASE
				 WHEN UPPER(t3332218.V_CLAIM_ACTIVITY_GROUP_R) = 'OPEN'
				 AND UPPER(t3332218.V_CLAIM_ACTIVITY_DETAIL_R) = 'REOPENED'
				 THEN t3332218.N_TOTAL_CLAIM_COUNT_R
				 ELSE 0  end                                                                                                                         as N_Reopened_Rate_R,
				 CASE WHEN N_CHG_CLOSED_CLAIM_COUNT_R > 0 AND N_TOTAL_BENEFIT_PERIOD_DAYS_R <> 0 AND  N_TOTAL_BENEFIT_PERIOD_DAYS_R IS NOT NULL
				 THEN t3332275.N_TOTAL_BENEFIT_PERIOD_DAYS_R else 0 end                                                                              as N_Average_Closed_Claim_Duration_Days_R,
				 t3332218.n_loss_payment_direct_amt_r/t3332162.N_BUSS_DAYS_IN_MONTH_R                                                                    as N_Average_Amount_Paid_Per_Business_Days_R,
				 t3332218.N_LOSS_PAYMENT_DIRECT_AMT_R / t3332162.N_BUSS_DAYS_IN_MONTH_R                                                                  AS N_Average_Amount_Paid_Per_Payment,
				 
				 case when  t3332275.V_CURR_CLAIM_STATUS_CODE_R = '63' then N_CHG_CLOSED_CLAIM_COUNT_R else 0 end                                             as N_PERCENT_APPROVED_IN_ANY_OCC_R,
				 CASE WHEN V_CLAIM_DECISION_IND_R = 'Y'
				 THEN N_APPROVED_CLAIM_COUNT_R + N_CLOSED_CLAIM_COUNT_R ELSE 0 END                                                                   AS N_Avg_Claim_Decision_Days_Den_R,
				 CASE WHEN N_CHG_CLOSED_CLAIM_COUNT_R > 0 AND N_TOTAL_BENEFIT_PERIOD_DAYS_R <> 0 AND  N_TOTAL_BENEFIT_PERIOD_DAYS_R IS NOT NULL
				 then t3332218.N_TOTAL_CLAIM_COUNT_R else 0 end                                                                                      as N_Average_Closed_Claim_Duration_Days_Deno_R,

CASE WHEN (case when  (select  N_FISCAL_YEAR_R||lpad(N_FISCAL_MONTH_R,2,0)from dim_time_r where
				 d_calendar_date_r =  t3332275.D_ANY_OCC_START_DATE_R) = t3332275.n_yearmonth_r THEN 1 ELSE 0 END) =1   AND
				 (t3332218.N_APPROVED_CLAIM_COUNT_R-t3332218.N_CHG_APPROVED_CLAIM_COUNT_R)>0
				then N_TOTAL_CLAIM_COUNT_R else 0 end                                                                                               as N_PERCENT_APPROVED_IN_ANY_OCC_R_DEN,

t3332275.V_SALES_CLAIM_STATUS_DESC_R,

t3332218.V_CLAIM_DECISION_TYPE_R

,t3332218.N_ORIGINAL_FACE_AMOUNT_R
				
			  FROM
				atomic.rpt_client_dtl_r            t3332177 ,
				
				(SELECT 
				   rpt_claim_dtl_r.n_yearmonth_r,
				   rpt_claim_dtl_r.n_claim_sk_r,
				   rpt_claim_dtl_r.n_claim_coverage_sk_r,
				   rpt_claim_dtl_r.n_claim_coverage_group_sk_r,
				   rpt_claim_dtl_r.v_source_system_name_r,
				   rpt_claim_dtl_r.v_claim_coverage_code_r,
				   rpt_claim_dtl_r.d_claim_closed_date_r,
				   rpt_claim_dtl_r.v_claim_identifier_r,
				   rpt_claim_dtl_r.n_curr_benefit_period_days_r,
				   rpt_claim_dtl_r.n_total_benefit_period_days_r,
				   rpt_claim_dtl_r.v_claim_status_desc_r,
				   rpt_claim_dtl_r.v_prior_claim_status_code_r,
				   rpt_claim_dtl_r.v_tier_r,
				   nvl(rpt_claim_dtl_r.v_tier_r, 'TIER 0')                  v_tier_adj_r,
				   trunc(rpt_claim_dtl_r.d_claim_closed_date_r)             d_trunc_claim_closed_date_r,
				   rpt_claim_dtl_r.v_curr_claim_status_code_r,
				   rpt_claim_dtl_r.v_privacy_indicator_r,
				   rpt_claim_dtl_r.d_any_occ_start_date_r,
				   rpt_claim_dtl_r.d_claim_received_date_r,
				   
				   CAST (NULL AS VARCHAR2(300 CHAR)) V_LEAVE_REASON_R                  ,
				   CAST (NULL AS VARCHAR2(300 CHAR)) V_MANDATED_FAMILY_MEMBER_R        ,
				   CAST (NULL AS VARCHAR2(300 CHAR)) V_PFL_LEAVE_TYPE_R ,
				   CAST (NULL AS VARCHAR2(300 CHAR)) V_CLAIM_COVERAGE_DESC_R,
				   CAST (NULL AS VARCHAR2(300 CHAR)) N_BASIC_INSURED_SALARY_R     ,
				   CAST (NULL AS VARCHAR2(300 CHAR)) V_BASIC_INSURED_SALARY_IND_R  ,
				   CAST (NULL AS VARCHAR2(300 CHAR)) D_CLAIM_STATUS_EFF_DATE_R,
				   CAST (NULL AS VARCHAR2(300 CHAR)) V_APPEAL_IND_R,
				   CAST (NULL AS VARCHAR2(300 CHAR)) V_APPEAL_RESULT_STATUS_CODE_R,
				   CAST (NULL AS VARCHAR2(300 CHAR)) D_APPEAL_RESULT_STATUS_CODE_EFF_DATE_R,

rpt_claim_dtl_r.V_SALES_CLAIM_STATUS_DESC_R,
					
				   rpt_claim_dtl_r.v_wfam_r

FROM 
					 atomic.rpt_claim_dtl_r
				  
				  WHERE n_yearmonth_r =GN_CURRENT_MONTH
				  GROUP BY  rpt_claim_dtl_r.n_yearmonth_r,
				   rpt_claim_dtl_r.n_claim_sk_r,
				   rpt_claim_dtl_r.n_claim_coverage_sk_r,
				   rpt_claim_dtl_r.n_claim_coverage_group_sk_r,
				   rpt_claim_dtl_r.v_source_system_name_r,
				   rpt_claim_dtl_r.v_claim_coverage_code_r,
				   rpt_claim_dtl_r.d_claim_closed_date_r,
				   rpt_claim_dtl_r.v_claim_identifier_r,
				   rpt_claim_dtl_r.n_curr_benefit_period_days_r,
				   rpt_claim_dtl_r.n_total_benefit_period_days_r,
				   rpt_claim_dtl_r.v_claim_status_desc_r,
				   rpt_claim_dtl_r.v_prior_claim_status_code_r,
				   rpt_claim_dtl_r.v_tier_r,
				   nvl(rpt_claim_dtl_r.v_tier_r, 'TIER 0')       ,
				   trunc(rpt_claim_dtl_r.d_claim_closed_date_r)  ,
				   rpt_claim_dtl_r.v_curr_claim_status_code_r,
				   rpt_claim_dtl_r.v_privacy_indicator_r,
				   rpt_claim_dtl_r.d_any_occ_start_date_r,
				   rpt_claim_dtl_r.d_claim_received_date_r,
				   rpt_claim_dtl_r.V_SALES_CLAIM_STATUS_DESC_R,
				   rpt_claim_dtl_r.v_wfam_r
				  
				) 
				 t3332275 ,
				atomic.rpt_policy_dtl_r            t3332256 ,
				atomic.rpt_grp_product_r           t3332146 ,
				atomic.rpt_employee_r              t3332164 ,
				atomic.rpt_fct_rpt_claim_summary_r t3332218 ,
				(
					SELECT
						n_claims_month_r,
						n_claims_year_r,
						COUNT(d_calendar_date_r) N_BUSS_DAYS_IN_MONTH_R  
					FROM
						dim_time_r
					WHERE
							v_business_day_ind_r = 'Y'
				
				AND d_calendar_date_r < TO_DATE(sysdate)
					GROUP BY
						n_claims_month_r,
						n_claims_year_r
				)                           t3332162
		 WHERE
			( t3332177.n_cust_party_sk_r = t3332218.n_party_sk_r
			  AND t3332162.n_claims_month_r = TO_NUMBER(to_char(t3332218.d_cycle_date_r, 'MM'),
				  '99')
			  AND t3332162.n_claims_year_r = TO_NUMBER(to_char(t3332218.d_cycle_date_r, 'yyyy'),
				  '9999')
			  AND t3332218.n_policy_sk_r = t3332256.n_policy_sk_r
			  AND t3332146.n_product_sk_r = t3332218.n_product_sk_r
			  
			  AND t3332164.n_employee_sk_r = t3332218.n_employee_sk_r
			  AND t3332218.n_claim_coverage_group_sk_r = t3332275.n_claim_coverage_group_sk_r
			  AND t3332218.n_claim_coverage_sk_r = t3332275.n_claim_coverage_sk_r
			  AND t3332218.n_claim_sk_r = t3332275.n_claim_sk_r

AND nvl(upper(t3332164.v_business_unit_r),'CLAIMS') = 'CLAIMS'
			  AND t3332146.n_yearmonth_r = GN_CURRENT_MONTH
			  AND t3332256.n_yearmonth_r = GN_CURRENT_MONTH
			  AND t3332177.n_yearmonth_r = GN_CURRENT_MONTH
			  and t3332218.n_yearmonth_r = GN_CURRENT_MONTH
			  and t3332164.n_yearmonth_r = GN_CURRENT_MONTH

);