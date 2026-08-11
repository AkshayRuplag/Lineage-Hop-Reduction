

  CREATE OR REPLACE EDITIONABLE PROCEDURE "ATOMIC"."PRC_GRP_LOAD_FCT_RPT_CLAIM_SUMMARY_R_DATA_INCR"
(
    P_N_BATCH_ID_R 		in number,
    P_LOAD_RUN_ID  		in number,
    P_OUT_LOAD_STATUS 	out varchar2
)
AS
	/********************************************************************************/
	/* Procedure		: 	PRC_GRP_LOAD_FCT_RPT_CLAIM_SUMMARY_R_INCR			  	*/
	/*																				*/
	/* Author(s)		: 	Mahesh G 												*/
	/*						Beneshya Shatto											*/
	/*						Abhishek Das											*/
	/*						Muthu Jeyadarmar										*/
	/*																				*/
	/* Purpose			: 	Load the aggregated FACT table FCT_RPT_CLAIM_SUMMARY_R	*/
	/*						which is primarily used by Claims KPI reports			*/
	/*																				*/
	/* Source table(s)	:	1) STG_GRP_CLAIM_SUMMARY_R 								*/
	/*						2) DIM_GRP_CLAIM_COVERAGE_GROUP_R 						*/
	/*						3) DIM_GRP_CLAIM_COVERAGE_R								*/
	/*						4) DIM_GRP_POLICY_DIR_R									*/
	/*						5) FCT_GRP_POLICY_R										*/
	/*																				*/
	/* Target table(s) 	:	FCT_RPT_CLAIM_SUMMARY_R									*/
	/*																				*/
	/********************************************************************************/
	/* Changelog																	*/
	/********************************************************************************/
	/*																				*/
	/* Date 				Description												*/
	/* ---------------------------------------------------------------------------- */
	/* 06/06/2023			Initial procedure creation								*/
	/* 06/27/2024 			Remove products with 'Unknown' product line				*/
	/* 07/01/2024			Add filters for Reopened Claims in CHG_TOTAL_CLAIM		*/
	/* 08/01/2024			Added V_CLAIM_DECISION_TYPE_R for Dashboard reports 	*/
	/* 09/01/2024			Added first closed to accomodate Reopened claims in 	*/
	/*						CHG_TOTAL_CLAIM COUNT (Only claims that were 			*/
	/*						closed and then opened are to be excluded)				*/
	/* 10/07/2024			Filter out 91, 92 status codes or "Error" activity  	*/
	/*						in N_CHG_TOTAL_CLAIM_COUNT_R							*/
	/* 10/14/2024			Migration to PROD				 						*/
	/* 11/07/2025			VB KPI : CLOSED CLAIM CHANGES							*/
	/********************************************************************************/


    lc_debug_flag             VARCHAR2(1) 	:= 'N';
    ln_func_start_time        NUMBER 		:= 0;
    ln_func_exec_time         NUMBER 		:= 0;
    ln_proc_start_time        NUMBER 		:= 0;
    ln_proc_exec_time         NUMBER 		:= 0;
    ln_insert_debug_limit     NUMBER 		:= 25000;
    ld_cycle_date             DATE;
    ld_prior_cycle_date       DATE;
	ld_d_calendar_date_r      DATE;
    ln_prior_fiscal_month     NUMBER;
    ln_current_fiscal_month   NUMBER;
    LC_USER         VARCHAR2(4000) 	 		:= 'ODI';
    LN_REC          NUMBER 			 		:= 0;
    LN_BULK_LIMIT_R NUMBER;

	--Global Constants
    gd_sysdate               DATE               := TRUNC(SYSDATE);
    gc_source                VARCHAR2(30)       :='EDW';
    gc_job_name              VARCHAR2(50 CHAR)  :='PRC_GRP_LOAD_FCT_RPT_CLAIM_SUMMARY_R_DATA_INCR';
    gn_sysdt_batchid         NUMBER             := TO_NUMBER(TO_CHAR(gd_sysdate,'YYYYMMDD'));
    gc_trcmsg                CLOB               :='Trace Message:->';
    gc_error_status          VARCHAR2(30)       :='Error';
    gc_success_status        VARCHAR2(30)       :='Success';
    gc_running_status        VARCHAR2(30)       :='Running';
    gc_errmsg                VARCHAR2(4000 CHAR);
    gn_out_job_id            NUMBER;
    gn_job_log_message_id_r  NUMBER;
    gc_main_loadedby VARCHAR2(100 CHAR);
    lv_message_type_r  PRCS_JOB_LOG_MESSAGE_R.v_message_type_r%TYPE:= PKG_GRP_LOG_UTIL.gc_message_type_info;
BEGIN
	/********************************************************************************/
	/* 	First collect the current fiscal month-end date and the prior fiscal 		*/
	/*	month-end dates, based on the passed batch ID.								*/
	/********************************************************************************/
gc_main_loadedby :='PRC_GRP_LOAD_FCT_RPT_CLAIM_SUMMARY_R_DATA_INCR';

        pkg_grp_log_util.prc_insert_log
                       ( p_source              			=> gc_source
					    ,p_job_nm              			=> gc_job_name
                        ,p_job_status          			=> gc_running_status
                        ,p_err_msg             			=> null
                        ,p_trc_msg             			=> null
                        ,p_n_batch_id          			=> gn_sysdt_batchid
                        ,p_log_util_called_by_r			=> gc_main_loadedby
						,out_job_id            			=> gn_out_job_id
						);

		gc_trcmsg:='1. Entered into PRC_GRP_LOAD_FCT_RPT_CLAIM_SUMMARY_R_DATA_INCR ';
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
						p_job_id_r            			=> gn_out_job_id,
						p_batch_id_r                  	=> gn_sysdt_batchid,
						p_message_type_r              	=> lv_message_type_r,
						p_code_location_r             	=> gc_main_loadedby,
						p_message_r                   	=> gc_trcmsg,
						p_count_type_r                	=> NULL,
						p_count_r                     	=> NULL,
						p_duration_r                  	=> NULL,
						p_created_by_r                	=> GC_JOB_NAME,
						out_prcs_job_log_message_id_r 	=> gn_job_log_message_id_r
						);
	SELECT
		DTR.D_CALENDAR_DATE_R
    INTO
		LD_CYCLE_DATE
    FROM
    (
        SELECT
            N_FISCAL_MONTH_R,
            N_FISCAL_YEAR_R
        FROM
            ATOMIC.DIM_TIME_R
        WHERE
            D_CALENDAR_DATE_R = TO_DATE(SUBSTR(P_N_BATCH_ID_R, 1, 8), 'YYYYMMDD')
    ) DTR_CURR
    JOIN
		ATOMIC.DIM_TIME_R DTR
    ON
		DTR.V_END_OF_FISCAL_MONTH_IND_R = 'Y'
		AND DTR.N_FISCAL_MONTH_R = DTR_CURR.N_FISCAL_MONTH_R
		AND DTR.N_FISCAL_YEAR_R = DTR_CURR.N_FISCAL_YEAR_R;

	/*	PRIOR CYCLE */

	SELECT
        MAX(DTR.D_CALENDAR_DATE_R)
    INTO
        LD_PRIOR_CYCLE_DATE
    FROM
    (
        SELECT
            N_FISCAL_MONTH_R,
            N_FISCAL_YEAR_R
        FROM
            ATOMIC.DIM_TIME_R
        WHERE
            D_CALENDAR_DATE_R < TO_DATE(SUBSTR(P_N_BATCH_ID_R, 1, 8), 'YYYYMMDD')
            AND V_END_OF_FISCAL_MONTH_IND_R = 'Y'
    ) DTR_PRIOR
    JOIN
		ATOMIC.DIM_TIME_R DTR
    ON
        DTR.V_END_OF_FISCAL_MONTH_IND_R = 'Y'
        AND DTR.N_FISCAL_MONTH_R = DTR_PRIOR.N_FISCAL_MONTH_R
        AND DTR.N_FISCAL_YEAR_R = DTR_PRIOR.N_FISCAL_YEAR_R;


	/*  NUMBER FORMAT */
	SELECT
		MAX(D_CALENDAR_DATE_R)
    INTO
		LD_D_CALENDAR_DATE_R
	FROM
		ATOMIC.DIM_TIME_R
    WHERE
		TO_CHAR(D_CALENDAR_DATE_R,'YYYYMMDD') < SUBSTR(P_N_BATCH_ID_R,1,8)
		AND V_END_OF_FISCAL_MONTH_IND_R = 'Y';

	/* Populate in YYYYMM format */
	LN_PRIOR_FISCAL_MONTH := TO_NUMBER(TO_CHAR(LD_PRIOR_CYCLE_DATE,'YYYYMM'));
    LN_CURRENT_FISCAL_MONTH := TO_NUMBER(TO_CHAR(LD_CYCLE_DATE,'YYYYMM'));


		gc_trcmsg:='2. Started Deleting Data from  FCT_RPT_CLAIM_SUMMARY_R ';
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
						p_job_id_r            			=> gn_out_job_id,
						p_batch_id_r                  	=> gn_sysdt_batchid,
						p_message_type_r              	=> lv_message_type_r,
						p_code_location_r             	=> gc_main_loadedby,
						p_message_r                   	=> gc_trcmsg,
						p_count_type_r                	=> NULL,
						p_count_r                     	=> NULL,
						p_duration_r                  	=> NULL,
						p_created_by_r                	=> GC_JOB_NAME,
						out_prcs_job_log_message_id_r 	=> gn_job_log_message_id_r
						);
	/* Truncate the existing data for the CURRENT cycle month before loading data AS OF DATE */
    EXECUTE IMMEDIATE 'DELETE FROM ATOMIC.FCT_RPT_CLAIM_SUMMARY_R WHERE D_CYCLE_DATE_R=:ld_cycle_date_r' using LD_CYCLE_DATE;

		gc_trcmsg:='3. Completed Deleting Data from  FCT_RPT_CLAIM_SUMMARY_R ';
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
						p_job_id_r            			=> gn_out_job_id,
						p_batch_id_r                  	=> gn_sysdt_batchid,
						p_message_type_r              	=> lv_message_type_r,
						p_code_location_r             	=> gc_main_loadedby,
						p_message_r                   	=> gc_trcmsg,
						p_count_type_r                	=> NULL,
						p_count_r                     	=> NULL,
						p_duration_r                  	=> NULL,
						p_created_by_r                	=> GC_JOB_NAME,
						out_prcs_job_log_message_id_r 	=> gn_job_log_message_id_r
						);


		gc_trcmsg:='4. Started Inserting  Data into  FCT_RPT_CLAIM_SUMMARY_R ';
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
						p_job_id_r            			=> gn_out_job_id,
						p_batch_id_r                  	=> gn_sysdt_batchid,
						p_message_type_r              	=> lv_message_type_r,
						p_code_location_r             	=> gc_main_loadedby,
						p_message_r                   	=> gc_trcmsg,
						p_count_type_r                	=> NULL,
						p_count_r                     	=> NULL,
						p_duration_r                  	=> NULL,
						p_created_by_r                	=> GC_JOB_NAME,
						out_prcs_job_log_message_id_r 	=> gn_job_log_message_id_r
						);
    /* Insert the values to the table for the CURRENT cycle month AS OF DATE */
	INSERT /*+APPEND*/ INTO ATOMIC.FCT_RPT_CLAIM_SUMMARY_R
	(
		n_claim_sk_r,
		n_party_sk_r,
		n_policy_sk_r,
		n_product_sk_r,
		n_approved_claim_count_r,
		n_chg_approved_claim_count_r,
		n_chg_closed_claim_count_r,
		n_chg_pending_claim_count_r,
		n_chg_reopen_claim_count_r,
		n_chg_total_claim_count_r,
		n_closed_claim_count_r,
		n_pending_claim_count_r,
		n_reopen_claim_count_r,
		n_total_claim_count_r,
		v_claim_activity_detail_r,
		v_claim_activity_group_r,
		v_claim_activity_type_r,
		v_claim_decision_ind_r,
		d_claim_decision_date_r,
		n_init_clm_decision_days_r,
		n_loss_payment_direct_amt_r,
		n_no_of_checks_r,
		n_no_of_payments_r,
		n_chg_gaap_os_direct_amt_r,
		n_curr_gaap_reserve_direct_r,
		d_cycle_date_r,
		n_claim_age_r,
		n_batch_id_r,
		n_load_run_id_r,
		n_sequence_number_r,
		t_creation_date_r,
		t_event_timestamp_r,
		t_last_modified_date_r,
		v_created_by_r,
		v_last_modified_by_r,
		fic_mis_date_r,
		v_source_system_name_r,
		f_physical_delete_r,
		v_claim_identifier_r,
		n_claim_coverage_group_sk_r,
		n_claim_coverage_sk_r,
		d_received_date_r,
		v_coverage_code_r,
		v_policy_number_r,
		v_claim_number_r,
		v_claim_coverage_code_r,
		v_claim_status_reason_code_r,
		v_reason_code_r,
		v_wfam_code_r,
		v_tier_description_r,
		v_tier_num_r,
		n_initial_approval_rate_r,
		n_initial_closure_r,
		n_init_avg_clm_decision_days_r,
		n_claims_with_overpayments_r,
		v_paid_and_closed_r,
		n_entry_error_count_r,
		v_elimination_period_group_r,
		n_prior_stat_wv_direct_amt_r,
		n_prior_stat_reserve_direct_r,
		n_prior_gaap_wv_direct_amt_r,
		n_prior_gaap_reserve_direct_r,
		n_prior_field_res_direct_amt_r,
		n_prior_be_direct_amt_r,
		n_stat_wv_reserve_count_r,
		n_stat_os_reserve_count_r,
		n_gaap_wv_reserve_count_r,
		n_gaap_os_reserve_count_r,
		n_chg_stat_wv_reserve_count_r,
		n_chg_stat_os_reserve_count_r,
		n_chg_gaap_wv_reserve_count_r,
		n_chg_gaap_os_reserve_count_r,
		d_potential_resolution_date_r,
		n_claims_bridged_std_to_ltd_r,
		v_ss_pursue_indicated_r,
		v_accommodations_needed_r,
		n_overpayment_balance_r,
		n_ltd_approved_clms_any_occ_r,
		n_ltd_approved_clms_own_occ_r,
		n_ltd_apprved_ownocc_fulldur_r,
		v_ltd_any_occ_group_r,
		v_recovery_expectations_r,
		v_clinical_voc_engagement_r,
		v_policy_prefix_r,
		v_policy_suffix_r,
		v_coverage_type_code_r,
		n_wage_base_r,
		n_payment_taxable_benefits_r,
		n_payment_nontaxable_ben_r,
		n_non_taxable_benefits_r,
		n_medicare_wage_base_r,
		n_emp_medicare_wage_base_r,
		n_emp_fica_wage_base_r,
		n_taxable_benefits_r,
		n_sit_r,
		n_payment_direct_amt_r,
		n_medicare_tax_r,
		n_futa_r,
		n_fit_r,
		n_fica_wage_base_r,
		n_fica_r,
		n_employer_medicare_tax_r,
		n_employer_fica_r,
		d_last_payment_to_date_r,
		d_first_payment_from_date_r,
		n_curr_stat_wv_direct_amt_r,
		n_curr_gaap_wv_direct_amt_r,
		n_chg_stat_wv_direct_amt_r,
		n_chg_gaap_wv_direct_amt_r,
		d_first_payment_date_r,
		n_no_of_void_checks_r,
		n_no_of_void_payments_r,
		n_curr_stat_reserve_direct_r,
		n_curr_field_res_direct_amt_r,
		n_curr_be_reserve_direct_amt_r,
		n_chg_stat_os_direct_amt_r,
		n_chg_field_res_direct_amt_r,
		n_chg_be_reserve_direct_amt_r,
		v_claim_decision_type_r
	)
	SELECT /*+PARALLEL(8)*/
		n_claim_sk_r,
		NVL(n_party_sk_r, -1),
		n_policy_sk_r,
		n_product_sk_r,
		n_approved_claim_count_r,
		n_chg_approved_claim_count_r,
		n_chg_closed_claim_count_r,
		n_chg_pending_claim_count_r,
		n_chg_reopen_claim_count_r,
		n_chg_total_claim_count_r,
		n_closed_claim_count_r,
		n_pending_claim_count_r,
		n_reopen_claim_count_r,
		n_total_claim_count_r,
		v_claim_activity_detail_r,
		v_claim_activity_group_r,
		v_claim_activity_type_r,
		v_claim_decision_ind_r,
		d_claim_decision_date_r,
		n_init_clm_decision_days_r,
		n_loss_payment_direct_amt_r,
		n_no_of_checks_r,
		n_no_of_payments_r,
		n_chg_gaap_os_direct_amt_r,
		n_curr_gaap_reserve_direct_r,
		d_cycle_date_r,
		n_claim_age_r,
		n_batch_id_r,
		n_load_run_id_r,
		n_sequence_number_r,
		t_creation_date_r,
		t_event_timestamp_r,
		t_last_modified_date_r,
		v_created_by_r,
		v_last_modified_by_r,
		fic_mis_date_r,
		v_source_system_name_r,
		f_physical_delete_r,
		v_claim_identifier_r,
		n_claim_coverage_group_sk_r,
		n_claim_coverage_sk_r,
		d_received_date_r,
		v_coverage_code_r,
		v_policy_number_r,
		v_claim_number_r,
		v_claim_coverage_code_r,
		v_claim_status_reason_code_r,
		v_reason_code_r,
		v_wfam_code_r,
		v_tier_description_r,
		n_tier_num_r,
		n_initial_approval_rate_r,
		n_initial_closure_r,
		n_init_avg_clm_decision_days_r,
		n_claims_with_overpayments_r,
		CAST(NULL AS VARCHAR(2)) AS v_paid_and_closed_r,
		n_entry_error_count_r,
		CAST(NULL AS VARCHAR(5)) AS v_elimination_period_group_r,
		n_prior_stat_wv_direct_amt_r,
		n_prior_stat_reserve_direct_r,
		n_prior_gaap_wv_direct_amt_r,
		n_prior_gaap_reserve_direct_r,
		n_prior_field_res_direct_amt_r,
		n_prior_be_direct_amt_r,
		n_stat_wv_reserve_count_r,
		n_stat_os_reserve_count_r,
		n_gaap_wv_reserve_count_r,
		n_gaap_os_reserve_count_r,
		n_chg_stat_wv_reserve_count_r,
		n_chg_stat_os_reserve_count_r,
		n_chg_gaap_wv_reserve_count_r,
		n_chg_gaap_os_reserve_count_r,
		d_potential_resolution_date_r,
		n_claims_bridged_std_to_ltd_r,
		v_ss_pursue_indicated_r,
		v_accommodations_needed_r,
		n_overpayment_balance_r,
		n_ltd_approved_clms_any_occ_r,
		n_ltd_approved_clms_own_occ_r,
		n_ltd_apprved_ownocc_fulldur_r,
		v_ltd_any_occ_group_r,
		v_recovery_expectations_r,
		v_clinical_voc_engagement_r,
		v_policy_prefix_r,
		v_policy_suffix_r,
		v_coverage_type_code_r,
		n_wage_base_r,
		n_payment_taxable_benefits_r,
		n_payment_nontaxable_ben_r,
		n_non_taxable_benefits_r,
		n_medicare_wage_base_r,
		n_emp_medicare_wage_base_r,
		n_emp_fica_wage_base_r,
		n_taxable_benefits_r,
		n_sit_r,
		n_payment_direct_amt_r,
		n_medicare_tax_r,
		n_futa_r,
		n_fit_r,
		n_fica_wage_base_r,
		n_fica_r,
		n_employer_medicare_tax_r,
		n_employer_fica_r,
		d_last_payment_to_date_r,
		d_first_payment_from_date_r,
		n_curr_stat_wv_direct_amt_r,
		n_curr_gaap_wv_direct_amt_r,
		n_chg_stat_wv_direct_amt_r,
		n_chg_gaap_wv_direct_amt_r,
		d_first_payment_date_r,
		n_no_of_void_checks_r,
		n_no_of_void_payments_r,
		n_curr_stat_reserve_direct_r,
		n_curr_field_res_direct_amt_r,
		n_curr_be_reserve_direct_amt_r,
		n_chg_stat_os_direct_amt_r,
		n_chg_field_res_direct_amt_r,
		n_chg_be_reserve_direct_amt_r,
		v_claim_decision_type_r
    FROM
	(
		SELECT
			sgcs_s4.*,
			(NVL(sgcs_s4.n_prior_n_reopen_claim_cnt_r, 0) - NVL(sgcs_s4.n_reopen_claim_count_r, 0))				AS			n_chg_reopen_claim_count_r,
			CASE
				WHEN NVL(sgcs_s4.v_claim_decision_ind_r, 'N') = 'Y' AND sgcs_s4.v_claim_activity_detail_r LIKE 'Approved%'
					THEN (NVL(n_closed_claim_count_r, 0) + NVL(n_approved_claim_count_r, 0))
				WHEN NVL(sgcs_s4.v_claim_decision_ind_r, 'N') = 'Y' AND sgcs_s4.v_claim_activity_detail_r NOT LIKE 'Approved%'
					THEN 0
				ELSE 0
			END 																								AS			n_initial_approval_rate_r,
			CASE
				WHEN NVL(sgcs_s4.v_claim_decision_ind_r, 'N') = 'Y' AND sgcs_s4.v_claim_activity_detail_r NOT LIKE 'Approved%'
					THEN (NVL(sgcs_s4.n_closed_claim_count_r, 0) + NVL(sgcs_s4.n_approved_claim_count_r, 0))
				ELSE 0
			END 																								AS			n_initial_closure_r,
			(
				sgcs_s4.n_init_clm_decision_days_r /
				NULLIF((CASE
					WHEN
						upper(sgcs_s4.v_claim_decision_ind_r) = 'Y'
							THEN (sgcs_s4.n_closed_claim_count_r + sgcs_s4.n_approved_claim_count_r)
					END
				), 0)
			) 																									AS 			n_init_avg_clm_decision_days_r,
			CASE
				WHEN NVL(sgcs_s4.n_overpayment_balance_r, 0) <> 0
					THEN 1
				ELSE 0
			END 																								AS 			n_claims_with_overpayments_r,
			CASE
				WHEN UPPER(sgcs_s4.v_claim_activity_detail_r) = 'ERROR'
					THEN 1
				ELSE 0
			END 																								AS 			n_entry_error_count_r,
			CASE
				WHEN
					upper(nvl(sgcs_s4.v_claim_decision_ind_r, 'N')) = 'N' then 'No Decision Made'
				WHEN
					upper(nvl(sgcs_s4.v_claim_decision_ind_r, 'N')) = 'Y' and sgcs_s4.v_decision_activity_detail_r like 'Approved%' then 'Approved'
				WHEN
					upper(nvl(sgcs_s4.v_claim_decision_ind_r, 'N')) = 'Y' then 'Denied'
			END 																								AS			v_claim_decision_type_r
		FROM (
			SELECT
				sgcs_s3.*,
				(trunc(sgcs_s3.d_claim_decision_date_r) - trunc(sgcs_s3.d_received_date_r)) 					AS 			n_init_clm_decision_days_r,
				(
					CASE
						WHEN (trunc(ld_prior_cycle_date) < trunc(sgcs_s3.d_claim_decision_date_r) and trunc(sgcs_s3.d_claim_decision_date_r) <= trunc(ld_cycle_date))
							THEN 'Y'
						ELSE 'N'
					END
				) 																								AS			v_claim_decision_ind_r,
				CASE
					WHEN UPPER(nvl(sgcs_s3.v_claim_activity_group_r, '@')) = 'OPEN' and upper(NVL(sgcs_s3.v_claim_activity_detail_r, '@')) = 'REOPENED'
						THEN n_total_claim_count_r
				END    																							AS  		n_reopen_claim_count_r,
 			/* Decision Activity Detail for the Claim Decision Type calculation */
			CASE
				WHEN sgcs_s3.V_PRODUCT_SUB_LINE_CODE_R NOT IN ( 'SR', 'VAR', 'Group Life' )
					THEN sgcs_s3.v_claim_activity_detail_r
                WHEN sgcs_s3.V_PRODUCT_SUB_LINE_CODE_R IN ( 'SR', 'VAR', 'Group Life' ) and SGCS_S3.V_COVERAGE_CODE_R IN ( 'WP', 'IWP', 'WPS', 'BWP' )
					THEN sgcs_s3.v_claim_activity_detail_r
				WHEN trunc(sgcs_s3.d_claim_decision_date_r) = trunc(sgcs_s3.t_first_open_status_eff_date) then 'Approved'
                WHEN trunc(sgcs_s3.d_claim_decision_date_r) = trunc(sgcs_s3.t_first_closed_status_eff_date) then 'Denied'
            END																									AS			v_decision_activity_detail_r
			FROM
			(
				SELECT
					sgcs_s2.*,
					(
						CASE
							WHEN UPPER(NVL(sgcs_s2.v_claim_activity_group_r,'@')) = 'OPEN'
								THEN 1
							ELSE 0
						END
					) 																							AS			n_approved_claim_count_r ,
                    CASE
						WHEN sgcs_s2.v_claim_activity_detail_r = 'Error'
							THEN 0 -- added to remove 91,92
						ELSE
						(
							CASE
								WHEN UPPER(NVL(sgcs_s2.v_claim_activity_group_r, '@')) = 'CLOSED'
									THEN 1
								ELSE 0
							END
						)
					END																							AS			n_closed_claim_count_r,
					(
						CASE
							WHEN UPPER(TRIM(NVL(sgcs_s2.v_claim_activity_group_r, '@'))) IN ( 'RESISTED', 'PENDING' )
								THEN 1
							ELSE 0
						END
					) 																							AS			n_pending_claim_count_r,
					(
						CASE
							WHEN sgcs_s2.v_claim_activity_group_r IS NOT NULL
								THEN 1
							ELSE 0
						END
					) 																							AS 			n_total_claim_count_r ,
                    (
						CASE
							WHEN sgcs_s2.cnt_v_claim_identifier_r IS NULL
								THEN 'New'
						ELSE
							(
								CASE
									WHEN sgcs_s2.prior_v_claim_activity_det_r = sgcs_s2.v_claim_activity_detail_r THEN 'Existing No Change'
									WHEN sgcs_s2.prior_v_claim_activity_det_r <> sgcs_s2.v_claim_activity_detail_r THEN 'Existing With Change' END
							)
						END
					) 																							AS 			v_claim_activity_type_r
				FROM
				(
					SELECT
						sgcsmv1.prior_fiscal_month,
						sgcsmv1.current_fiscal_month,
						sgcsmv1.d_cycle_date_r,
						sgcsmv1.n_batch_id_r,
						sgcsmv1.n_load_run_id_r,
						sgcsmv1.n_sequence_number_r,
						sgcsmv1.v_source_system_name_r,
						sgcsmv1.f_physical_delete_r,
						sgcsmv1.t_creation_date_r,
						sgcsmv1.t_event_timestamp_r,
						sgcsmv1.t_last_modified_date_r,
						sgcsmv1.v_created_by_r,
						sgcsmv1.v_last_modified_by_r,
						sgcsmv1.fic_mis_date_r,
						sgcsmv1.v_claim_status_reason_code_r,
						sgcsmv1.v_reason_code_r,
						sgcsmv1.n_policy_sk_r,
						sgcsmv1.v_claim_number_r,
						sgcsmv1.v_claim_coverage_code_r,
						sgcsmv1.n_claim_coverage_group_sk_r,
						sgcsmv1.v_claim_identifier_r,
						sgcsmv1.v_policy_number_r,
						sgcsmv1.n_claim_coverage_sk_r,
						sgcsmv1.n_product_sk_r,
						sgcsmv1.v_coverage_code_r,
						sgcsmv1.n_chg_gaap_os_direct_amt_r,
						sgcsmv1.n_curr_gaap_reserve_direct_r,
						sgcsmv1.n_party_sk_r,
						sgcsmv1.n_total_no_of_payments_r,
						sgcsmv1.n_no_of_payments_r,
						sgcsmv1.n_no_of_checks_r,
						sgcsmv1.n_prior_stat_wv_direct_amt_r,
						sgcsmv1.n_prior_stat_reserve_direct_r,
						sgcsmv1.n_prior_gaap_wv_direct_amt_r,
						sgcsmv1.n_prior_gaap_reserve_direct_r,
						sgcsmv1.n_prior_field_res_direct_amt_r,
						sgcsmv1.n_prior_be_direct_amt_r,
						sgcsmv1.n_stat_wv_reserve_count_r,
						sgcsmv1.n_stat_os_reserve_count_r,
						sgcsmv1.n_gaap_wv_reserve_count_r,
						sgcsmv1.n_gaap_os_reserve_count_r,
						sgcsmv1.n_chg_stat_wv_reserve_count_r,
						sgcsmv1.n_chg_stat_os_reserve_count_r,
						sgcsmv1.n_chg_gaap_wv_reserve_count_r,
						sgcsmv1.n_chg_gaap_os_reserve_count_r,
						sgcsmv1.n_claim_sk_r,
						sgcsmv1.n_tier_num_r,
						sgcsmv1.v_wfam_code_r,
						sgcsmv1.v_tier_description_r,
						sgcsmv1.d_potential_resolution_date_r,
						sgcsmv1.n_claims_bridged_std_to_ltd_r,
						sgcsmv1.v_ss_pursue_indicated_r,
						sgcsmv1.v_accommodations_needed_r,
						sgcsmv1.n_overpayment_balance_r,
						sgcsmv1.n_ltd_approved_clms_any_occ_r,
						sgcsmv1.n_ltd_approved_clms_own_occ_r,
						sgcsmv1.n_ltd_apprved_ownocc_fulldur_r,
						sgcsmv1.v_ltd_any_occ_group_r,
						sgcsmv1.v_recovery_expectations_r,
						sgcsmv1.v_clinical_voc_engagement_r,
						sgcsmv1.v_policy_prefix_r,
						sgcsmv1.v_policy_suffix_r,
						sgcsmv1.v_coverage_type_code_r,
						sgcsmv1.v_coverage_type_code_r1,
						sgcsmv1.n_wage_base_r,
						sgcsmv1.n_payment_taxable_benefits_r,
						sgcsmv1.n_payment_nontaxable_ben_r,
						sgcsmv1.n_non_taxable_benefits_r,
						sgcsmv1.n_medicare_wage_base_r,
						sgcsmv1.n_emp_medicare_wage_base_r,
						sgcsmv1.n_emp_fica_wage_base_r,
						sgcsmv1.n_taxable_benefits_r,
						sgcsmv1.n_sit_r,
						sgcsmv1.n_payment_direct_amt_r,
						sgcsmv1.n_medicare_tax_r,
						sgcsmv1.n_futa_r,
						sgcsmv1.n_fit_r,
						sgcsmv1.n_fica_wage_base_r,
						sgcsmv1.n_fica_r,
						sgcsmv1.n_employer_medicare_tax_r,
						sgcsmv1.n_employer_fica_r,
						sgcsmv1.d_last_payment_to_date_r,
						sgcsmv1.d_first_payment_from_date_r,
						sgcsmv1.n_curr_stat_wv_direct_amt_r,
						sgcsmv1.n_curr_gaap_wv_direct_amt_r,
						sgcsmv1.n_chg_stat_wv_direct_amt_r,
						sgcsmv1.n_chg_gaap_wv_direct_amt_r,
						sgcsmv1.d_first_payment_date_r,
						sgcsmv1.n_no_of_void_checks_r,
						sgcsmv1.n_no_of_void_payments_r,
						sgcsmv1.n_curr_stat_reserve_direct_r,
						sgcsmv1.n_curr_field_res_direct_amt_r,
						sgcsmv1.n_curr_be_reserve_direct_amt_r,
						sgcsmv1.n_chg_stat_os_direct_amt_r,
						sgcsmv1.n_chg_field_res_direct_amt_r,
						sgcsmv1.n_chg_be_reserve_direct_amt_r,
						sgcsmv1.d_service_period_from_r,
						sgcsmv1.d_received_date_r,
						sgcsmv1.v_claim_activity_group_r,
						/* The Claim Activity Detail should be 'Error' or the status code should be either 91 or 92 to ignore the claim in the count */
						CASE
							WHEN (v_claim_activity_detail_r IN ('Error') OR NVL(sgcsmv1.v_reason_code_r, sgcsmv1.v_claim_status_reason_code_r) IN ('91', '92'))
								THEN  0
							WHEN
								sgcsmv1.v_claim_activity_group_r = 'Open' AND NVL(sgcsmv1.prior_v_claim_acti_group_r, 'Closed') NOT IN ('Open')
								AND NVL(sgcsmv1.prior_v_claim_activity_det_r, '@') NOT IN ('Resisted')
								AND TRUNC(NVL(sgcsmv1.d_first_closed_date, to_date('31-DEC-2999'))) <= TRUNC(ld_prior_cycle_date)
								THEN 0
						ELSE
							(CASE WHEN sgcsmv1.v_claim_activity_group_r IS NOT NULL THEN 1 ELSE 0 END) - (CASE WHEN sgcsmv1.prior_v_claim_acti_group_r IS NULL THEN 0 ELSE 1 END)
						END 																					AS 			n_chg_total_claim_count_r,
						(
							CASE WHEN UPPER(NVL(sgcsmv1.v_claim_activity_group_r, '@')) = 'OPEN' THEN 1 ELSE 0 END) - (CASE WHEN UPPER(NVL(sgcsmv1.prior_v_claim_acti_group_r, '@')) = 'OPEN' THEN 1 ELSE 0
							END
						) 																						AS 			n_chg_approved_claim_count_r,
					CASE
						WHEN sgcsmv1.v_claim_activity_detail_r = 'Error' THEN 0 /* Do not count 91 & 92 status claims */
					ELSE
                    ((CASE WHEN UPPER(NVL(sgcsmv1.v_claim_activity_group_r, '@')) = 'CLOSED' THEN 1 ELSE 0 END) - (CASE WHEN UPPER(NVL(sgcsmv1.prior_v_claim_acti_group_r, '@')) = 'CLOSED' THEN 1 ELSE 0 END)
					 + -- VB KPI: CLOSED CLAIM
					 (CASE WHEN UPPER(NVL(sgcsmv1.V_CLOSED_CLAIM_DECISION_TYPE_R, '@')) = 'CLOSED' THEN 1 ELSE 0 END) - (CASE WHEN UPPER(NVL(sgcsmv1.V_PRIOR_CLOSED_CLAIM_DECISION_TYPE_R, '@')) = 'CLOSED' THEN 1 ELSE 0 END))-- VB KPI: CLOSED CLAIM
					END																							AS			n_chg_closed_claim_count_r,
					(
						CASE WHEN UPPER(NVL(sgcsmv1.v_claim_activity_group_r, '@')) IN ( 'RESISTED', 'PENDING' ) THEN 1 ELSE 0 END) - (CASE WHEN UPPER(NVL(sgcsmv1.prior_v_claim_acti_group_r, '@')) IN ( 'RESISTED', 'PENDING' ) THEN 1 ELSE 0
						END
					) 																							AS			n_chg_pending_claim_count_r,
					sgcsmv1.n_claim_age_r,
					CASE WHEN
						sgcsmv1.v_claim_activity_group_r = 'Open' and nvl(sgcsmv1.prior_v_claim_acti_group_r, 'Closed') not in ('Open') and nvl(sgcsmv1.prior_v_claim_activity_det_r, '@') NOT IN ('Resisted')
						AND TRUNC(NVL(sgcsmv1.d_first_closed_date, to_date('31-DEC-2999'))) <= trunc(ld_prior_cycle_date)
						THEN 'Reopened'
					ELSE
						sgcsmv1.v_claim_activity_detail_r
					END     																					AS			v_claim_activity_detail_r,
					sgcsmv1.d_claim_decision_date_r,
					sgcsmv1.prior_v_claim_activity_det_r,
					sgcsmv1.d_closure_date_r,
					sgcsmv1.n_prior_n_reopen_claim_cnt_r,
					sgcsmv1.t_first_open_status_eff_date,
					sgcsmv1.t_first_closed_status_eff_date,
					sgcsmv1.n_loss_payment_direct_amt_r,
					sgcsmv1.prior_v_claim_acti_group_r,
                    sgcsmv1.cnt_v_claim_identifier_r 															AS 			cnt_v_claim_identifier_r,
                    /* Added below for Decision Activity Detail */
					sgcsmv1.v_product_sub_line_code_r,
					sgcsmv1.v_product_line_r,
                    sgcsmv1.d_first_closed_date
					FROM
					(

						SELECT
							ln_prior_fiscal_month 																AS			prior_fiscal_month,
							ln_current_fiscal_month 															AS			current_fiscal_month,
							ld_cycle_date 																		AS			d_cycle_date_r,
							p_n_batch_id_r 																		AS			n_batch_id_r,
							1 																					AS			n_load_run_id_r,
							ROWNUM 																				AS			n_sequence_number_r,
							CASE
								WHEN (sgcsmv.v_claim_identifier_r LIKE 'V_I%' OR sgcsmv.v_claim_identifier_r LIKE 'BC%')
                                    THEN 'CV'
								ELSE 'PACS'
							END             																	AS          v_source_system_name_r,
						CAST(NULL AS VARCHAR2(1)) 																AS 			f_physical_delete_r,
						SYSDATE  																				AS			t_creation_date_r,
						SYSDATE  																				AS			t_event_timestamp_r,
						SYSDATE  																				AS			t_last_modified_date_r,
						LC_USER 																				AS			v_created_by_r,
						LC_USER 																				AS			v_last_modified_by_r,
						TRUNC(SYSTIMESTAMP) 																	AS			fic_mis_date_r,
						sgcsmv.v_claim_status_reason_code_r,
						sgcsmv.v_reason_code_r,
						T357774.v_reason_code_r 																AS 			v_reason_code_r1,
						T357774.n_reserve_amount_r,
						sgcsmv.n_policy_sk_r 																	AS			n_policy_sk_r,
						sgcsmv.v_claim_number_r 																AS			v_claim_number_r,
						sgcsmv.v_claim_coverage_code_r 															AS			v_claim_coverage_code_r,
						sgcsmv.n_claim_coverage_group_sk_r 														AS			n_claim_coverage_group_sk_r,
						sgcsmv.v_claim_identifier_r 															AS			v_claim_identifier_r,
						sgcsmv.v_policy_number_r 																AS			v_policy_number_r,
						sgcsmv.n_claim_coverage_sk_r,
						sgcsmv.n_product_sk_r,
						sgcsmv.v_coverage_code_r,
						sgcsmv.n_chg_gaap_os_direct_amt_r 														AS			n_chg_gaap_os_direct_amt_r,
						sgcsmv.n_curr_gaap_reserve_direct_r 													AS			n_curr_gaap_reserve_direct_r,
						sgcsmv.d_received_date_r 																AS			d_received_date_r,
						sgcsmv.n_cust_party_sk_r 																AS			n_party_sk_r,
						sgcsmv.n_total_no_of_payments_r,
						sgcsmv.n_no_of_payments_r,
						sgcsmv.n_no_of_checks_r,
                        /* Additional columns */
                        frcsimv.n_prior_n_reopen_claim_cnt_r,
						/* For Decision Date */
                        frcsimv.dd_claim_first_open_stat_eff_date 												AS 			t_first_open_status_eff_date,
                        frcsimv.dd_claim_first_closed_stat_eff_date 											AS 			t_first_closed_status_eff_date,
                        trunc(frcsimv.t_first_closed_status_eff_date) 											AS 			d_first_closed_date,
                        frcsimv.n_loss_payment_direct_amt_r,
						CASE WHEN sgcsmv.v_coverage_type_code_r in ('3') AND
						      NVL(sgcsmv.v_reason_code_r, sgcsmv.v_claim_status_reason_code_r) LIKE '73' AND --VB KPI: CLOSED CLAIM
		                     sgcsmv.v_policy_prefix_r in ('VAI', 'VCI', 'VHI') AND  UPPER(rcsi.V_CLAIM_STATUS_R) = 'APPROVED' --VB KPI: CLOSED CLAIM
			             THEN 'Closed' --VB KPI: CLOSED CLAIM
						 ELSE 'NA' END AS V_CLOSED_CLAIM_DECISION_TYPE_R,	 --VB KPI: CLOSED CLAIM
                        (
							CASE
								WHEN sgcsmv.v_coverage_type_code_r = '3' AND (T357774.v_reason_code_r) > '59' AND UPPER(rcsi.V_CLAIM_STATUS_R) <> 'APPROVED'
								AND sgcsmv.v_policy_prefix_r in ('VAI', 'VCI', 'VHI')---08-10-25 changes
									THEN 'Closed'
								WHEN sgcsmv.v_coverage_type_code_r = '3' AND (T357774.v_reason_code_r) > '59' and sgcsmv.v_policy_prefix_r not in ('VAI', 'VCI', 'VHI')---08-10-25 changes
									THEN 'Closed'
								WHEN sgcsmv.v_coverage_type_code_r IN ('1', '2') AND NVL(sgcsmv.v_reason_code_r, sgcsmv.v_claim_status_reason_code_r) > '59'
									THEN 'Closed'
								WHEN sgcsmv.v_coverage_type_code_r IN ('1', '2') AND NVL(sgcsmv.v_reason_code_r, sgcsmv.v_claim_status_reason_code_r) = '51'
									THEN 'Closed'
                                /* Adding condition to check if the policy is a Voluntary Benefits policy (Nov 2024) */
								WHEN ((sgcsmv.v_coverage_type_code_r in ('1', '2') AND NVL(sgcsmv.v_reason_code_r, sgcsmv.v_claim_status_reason_code_r) LIKE '3%')
                                    OR (sgcsmv.v_coverage_type_code_r in ('3') AND NVL(sgcsmv.v_reason_code_r, sgcsmv.v_claim_status_reason_code_r) LIKE '3%' AND
                                        sgcsmv.v_policy_prefix_r in ('VAI', 'VCI', 'VHI'))
								OR (sgcsmv.v_coverage_type_code_r in ('3') AND NVL(sgcsmv.v_reason_code_r, sgcsmv.v_claim_status_reason_code_r) LIKE '73' AND
                                        sgcsmv.v_policy_prefix_r in ('VAI', 'VCI', 'VHI') AND UPPER(rcsi.V_CLAIM_STATUS_R) = 'APPROVED'))
									THEN 'Open'
								WHEN sgcsmv.v_coverage_type_code_r IN ('1', '2') AND NVL(sgcsmv.v_reason_code_r, sgcsmv.v_claim_status_reason_code_r) = '41'
									THEN 'Open'
								WHEN sgcsmv.v_coverage_type_code_r IN ( '1', '2' ) AND NVL(sgcsmv.v_reason_code_r, sgcsmv.v_claim_status_reason_code_r) = '42'
									THEN 'Closed'
								WHEN sgcsmv.v_coverage_type_code_r = '3' AND sgcsmv.v_coverage_code_r IN ('WP', 'IWP', 'WPS', 'BWP') AND T357774.v_reason_code_r = '33'
									THEN 'Open'
								WHEN sgcsmv.v_coverage_type_code_r  = '3' AND sgcsmv.v_coverage_code_r NOT IN ( 'WP', 'IWP', 'WPS', 'BWP' ) AND (T357774.v_reason_code_r) < '60'
									AND T357774.n_reserve_amount_r > '0'
									THEN 'Open'
								WHEN sgcsmv.v_coverage_type_code_r = '3' AND T357774.v_reason_code_r like '5%'
									THEN 'Resisted'
								WHEN sgcsmv.v_coverage_type_code_r in ('1', '2') AND NVL(sgcsmv.v_reason_code_r, sgcsmv.v_claim_status_reason_code_r) like '5%'
									THEN 'Resisted'
								ELSE
									'Pending'
							END
						)																						AS			v_claim_activity_group_r,
						(sgcsmv.n_curr_stat_wv_direct_amt_r - sgcsmv.n_chg_stat_wv_direct_amt_r) 				AS 			n_prior_stat_wv_direct_amt_r,
						(sgcsmv.n_curr_stat_reserve_direct_r - sgcsmv.n_chg_stat_os_direct_amt_r)				AS			n_prior_stat_reserve_direct_r,
						(sgcsmv.n_curr_gaap_wv_direct_amt_r - sgcsmv.n_chg_gaap_wv_direct_amt_r)				AS			n_prior_gaap_wv_direct_amt_r,
						(sgcsmv.n_curr_gaap_reserve_direct_r - sgcsmv.n_chg_gaap_os_direct_amt_r)				AS			n_prior_gaap_reserve_direct_r,
						(sgcsmv.n_curr_field_res_direct_amt_r - sgcsmv.n_chg_field_res_direct_amt_r) 			AS 			n_prior_field_res_direct_amt_r,
						(sgcsmv.n_curr_be_reserve_direct_amt_r - sgcsmv.n_chg_be_reserve_direct_amt_r) 			AS			n_prior_be_direct_amt_r,
						CASE
							WHEN sgcsmv.n_curr_stat_wv_direct_amt_r <> 0
								THEN 1
							ELSE 0
						END 																					AS 			n_stat_wv_reserve_count_r,
						CASE
							WHEN sgcsmv.n_curr_stat_reserve_direct_r  <> 0
								THEN 1
							ELSE 0
						END 																					AS 			n_stat_os_reserve_count_r,
						CASE
							WHEN sgcsmv.n_curr_gaap_wv_direct_amt_r <> 0
								THEN 1
							ELSE 0
						END 																					AS 			n_gaap_wv_reserve_count_r,
						case
							when sgcsmv.n_curr_gaap_reserve_direct_r <> 0
								then 1
							else 0
						end 																					AS 			n_gaap_os_reserve_count_r,
						case
							when sgcsmv.n_chg_stat_wv_direct_amt_r <> 0
								then 1
							else 0
						end 																					AS 			n_chg_stat_wv_reserve_count_r,
						case
							when sgcsmv.n_chg_stat_os_direct_amt_r <> 0
								then 1
							else 0
						end 																					AS 			n_chg_stat_os_reserve_count_r,
						case
							when sgcsmv.n_chg_gaap_wv_direct_amt_r <> 0
								then 1
							else 0
						end 																					AS 			n_chg_gaap_wv_reserve_count_r,
						case
							when sgcsmv.n_chg_gaap_os_direct_amt_r <> 0
								then 1
							else 0
						end 																					AS 			n_chg_gaap_os_reserve_count_r,
						sgcsmv.n_claim_sk_r,
						sgcsmv.n_tier_num_r,
						sgcsmv.v_wfam_code_r,
						sgcsmv.v_tier_description_r,
						sgcsmv.d_potential_resolution_date_r,
						sgcsmv.n_claims_bridged_std_to_ltd_r,
						sgcsmv.v_ss_pursue_indicated_r,
						sgcsmv.v_accommodations_needed_r,
						sgcsmv.n_overpayment_balance_r,
						sgcsmv.n_ltd_approved_clms_any_occ_r,
						sgcsmv.n_ltd_approved_clms_own_occ_r,
						sgcsmv.n_ltd_apprved_ownocc_fulldur_r,
						sgcsmv.v_ltd_any_occ_group_r,
						sgcsmv.v_recovery_expectations_r,
						sgcsmv.v_clinical_voc_engagement_r,
						sgcsmv.v_policy_prefix_r,
						sgcsmv.v_policy_suffix_r,
						sgcsmv.v_coverage_type_code_r,
						sgcsmv.v_coverage_type_code_r 															AS 			V_COVERAGE_TYPE_CODE_R1,
						sgcsmv.n_wage_base_r,
						sgcsmv.n_payment_taxable_benefits_r,
						sgcsmv.n_payment_nontaxable_ben_r,
						sgcsmv.n_non_taxable_benefits_r,
						sgcsmv.n_medicare_wage_base_r,
						sgcsmv.n_emp_medicare_wage_base_r,
						sgcsmv.n_emp_fica_wage_base_r,
						sgcsmv.n_taxable_benefits_r,
						sgcsmv.n_sit_r,
						sgcsmv.n_payment_direct_amt_r,
						sgcsmv.n_medicare_tax_r,
						sgcsmv.n_futa_r,
						sgcsmv.n_fit_r,
						sgcsmv.n_fica_wage_base_r,
						sgcsmv.n_fica_r,
						sgcsmv.n_employer_medicare_tax_r,
						sgcsmv.n_employer_fica_r,
						sgcsmv.d_last_payment_to_date_r,
						sgcsmv.d_first_payment_from_date_r,
						sgcsmv.n_curr_stat_wv_direct_amt_r,
						sgcsmv.n_curr_gaap_wv_direct_amt_r,
						sgcsmv.n_chg_stat_wv_direct_amt_r,
						sgcsmv.n_chg_gaap_wv_direct_amt_r,
						sgcsmv.d_first_payment_date_r,
						sgcsmv.n_no_of_void_checks_r,
						sgcsmv.n_no_of_void_payments_r,
						sgcsmv.n_curr_stat_reserve_direct_r,
						sgcsmv.n_curr_field_res_direct_amt_r,
						sgcsmv.n_curr_be_reserve_direct_amt_r,
						sgcsmv.n_chg_stat_os_direct_amt_r,
						sgcsmv.n_chg_field_res_direct_amt_r,
						sgcsmv.n_chg_be_reserve_direct_amt_r,
						sgcsmv.d_service_period_from_r,
						sgcsmv.d_closure_date_r,
						rcsi.prior_v_claim_activity_det_r,
						rcsi.d_claim_decision_date_r,
						rcsi.v_claim_activity_detail_r,
						rcsi.n_claim_age_r,
						rcsi.cnt_v_claim_identifier_r,
						rcsi.prior_v_claim_acti_group_r,
						rcsi.V_PRIOR_CLOSED_CLAIM_DECISION_TYPE_R, -- VB KPI: CLOSED CLAIM
                        sgcsmv.v_product_sub_line_code_r,
						sgcsmv.v_product_line_r
					FROM (

						SELECT
							cdtl.n_claim_sk_r,
							cdtl.v_claim_status_reason_code_r,
							cdtl.v_reason_code_r,
							cdtl.n_policy_sk_r 																		AS			n_policy_sk_r,
							cdtl.v_claim_number_r 																	AS			v_claim_number_r,
							cdtl.v_claim_coverage_code_r 															AS			v_claim_coverage_code_r,
							cdtl.n_claim_coverage_group_sk_r 														AS			n_claim_coverage_group_sk_r,
							cdtl.v_claim_identifier_r 																AS			v_claim_identifier_r,
							cdtl.n_chg_gaap_os_direct_amt_r 														AS			n_chg_gaap_os_direct_amt_r,
							cdtl.n_curr_gaap_reserve_direct_r 														AS			n_curr_gaap_reserve_direct_r,
							cdtl.n_tier_num_r 																		AS			n_tier_num_r,
							cdtl.v_wfam_code_r 																		AS			v_wfam_code_r,
							cdtl.v_tier_description_r 																AS			v_tier_description_r,
							cdtl.d_potential_resolution_date_r  													AS			d_potential_resolution_date_r,
							cdtl.v_policy_number_r 																	AS			v_policy_number_r,
							cdtl.n_claim_coverage_sk_r,
							cdtl.n_claims_bridged_std_to_ltd_r 														AS			n_claims_bridged_std_to_ltd_r,
							cdtl.v_ss_pursue_indicated_r,
							cdtl.v_accommodations_needed_r,
							NVL(cdtl.n_overpayment_balance_r, 0)                   									AS 			n_overpayment_balance_r,
							CASE WHEN
                                cdtl.n_ltd_approved_clms_any_occ_r = 'Y' THEN 1
                                ELSE 0
                            END                                                     								AS  		n_ltd_approved_clms_any_occ_r,
							CASE WHEN
                                cdtl.n_ltd_approved_clms_own_occ_r = 'Y' THEN 1
                                ELSE 0
                            END                                                     								AS 			n_ltd_approved_clms_own_occ_r,
							CASE WHEN
                                CDTL.n_ltd_apprved_ownocc_fulldur_r = 'Y' THEN 1
                                ELSE 0
                            END                                                     								AS 			n_ltd_apprved_ownocc_fulldur_r,
							cdtl.v_ltd_any_occ_group_r,
							cdtl.v_recovery_expectations_r,
							cdtl.v_clinical_voc_engagement_r,
							cdtl.v_policy_prefix_r,
							cdtl.v_policy_suffix_r,
							cdtl.v_coverage_type_code_r,
                            /* ADDITIONAL COLUMNS JUNE 2024 */
							cdtl.d_received_date_r,
                            cdtl.d_closure_date_r,
							cdtl.n_wage_base_r,
							cdtl.n_payment_taxable_benefits_r,
							cdtl.n_payment_nontaxable_ben_r,
							cdtl.n_non_taxable_benefits_r,
							cdtl.n_medicare_wage_base_r,
							cdtl.n_emp_medicare_wage_base_r,
							cdtl.n_emp_fica_wage_base_r,
							cdtl.n_taxable_benefits_r,
							cdtl.n_sit_r,
							cdtl.n_payment_direct_amt_r,
							cdtl.n_medicare_tax_r,
							cdtl.n_futa_r,
							cdtl.n_fit_r,
							cdtl.n_fica_wage_base_r,
							cdtl.n_fica_r,
							cdtl.n_employer_medicare_tax_r,
							cdtl.n_employer_fica_r,
							cdtl.d_last_payment_to_date_r,
							cdtl.d_first_payment_from_date_r,
							cdtl.n_curr_stat_wv_direct_amt_r,
							cdtl.n_curr_gaap_wv_direct_amt_r,
							cdtl.n_chg_stat_wv_direct_amt_r,
							cdtl.n_chg_gaap_wv_direct_amt_r,
							cdtl.d_first_payment_date_r,
							cdtl.n_no_of_void_checks_r,
							cdtl.n_no_of_void_payments_r,
							cdtl.n_curr_stat_reserve_direct_r,
							cdtl.n_curr_field_res_direct_amt_r,
							cdtl.n_curr_be_reserve_direct_amt_r,
							cdtl.n_chg_stat_os_direct_amt_r,
							cdtl.n_chg_field_res_direct_amt_r,
							cdtl.n_chg_be_reserve_direct_amt_r,
							p.n_product_sk_r,
							NVL(DIM_GRP_PRODUCT_R.V_COVERAGE_CODE_R, '-1') 											AS 			v_coverage_code_r,
							CS.n_total_no_of_payments_r,

							CS.n_no_of_payments_r,
							CS.n_no_of_checks_r,
							CS.d_service_period_from_r,
							FP.n_cust_party_sk_r,
							dim_grp_product_r.v_product_sub_line_code_r,
							dim_grp_product_r.v_product_line_r
						FROM
							ATOMIC.stg_grp_claim_summary_r cdtl
						LEFT JOIN
                            (
                                SELECT
									NVL(dp.n_product_sk_r, -1) 		AS		n_product_sk_r,
									dp.v_claim_identifier_r,
									dp.rn
                                FROM
									ATOMIC.dim_grp_claim_product_mv dp
                                JOIN
                                (
                                    select
										v_claim_identifier_r,
										min(rn) AS RN
									from
										ATOMIC.dim_grp_claim_product_mv
                                    where
										n_product_sk_r IS NOT NULL
                                    group by
										v_claim_identifier_r
                                ) MN
                                ON
									dp.v_claim_identifier_r = mn.v_claim_identifier_r
									and DP.RN = MN.RN
						) p
						ON
							p.v_claim_identifier_r = cdtl.v_claim_identifier_r
						LEFT JOIN
							ATOMIC.dim_grp_product_r
						ON
							dim_grp_product_r.n_product_sk_r = p.n_product_sk_r
							AND dim_grp_product_r.v_active_status_r = 'Y'
						LEFT JOIN
							ATOMIC.claim_summary_intermediate_mv_tbl CS
						ON
							cdtl.v_claim_identifier_r = cs.v_claim_identifier_r
						LEFT JOIN
							(
								SELECT
									N_POLICY_SK_R,
									N_VERSION_NUMBER_R,
									N_CUST_PARTY_SK_R
								FROM
									ATOMIC.FCT_GRP_POLICY_R
						) fp


						ON
							cdtl.n_policy_sk_r  = fp.n_policy_sk_r
						LEFT JOIN
							(
								SELECT
									N_POLICY_SK_R,
									N_POLICY_VERSION_NUMBER_R

								FROM
									ATOMIC.DIM_GRP_POLICY_DIR_R
								WHERE
								V_ACTIVE_STATUS_R = 'Y'
						) dp
						ON
							fp.n_policy_sk_r  = dp.n_policy_sk_r
							AND FP.n_version_number_r = dp.n_policy_version_number_r
						WHERE
							NVL(cdtl.v_reason_flag_r, 'N') = 'Y'
							AND cdtl.v_claim_identifier_r IS NOT NULL
						GROUP BY
							cdtl.n_claim_sk_r,
							cdtl.v_claim_status_reason_code_r,
							cdtl.v_reason_code_r,
							cdtl.n_policy_sk_r,
							cdtl.v_claim_number_r,
							cdtl.v_claim_coverage_code_r,
							cdtl.n_claim_coverage_group_sk_r,
							cdtl.v_claim_identifier_r,
							cdtl.n_chg_gaap_os_direct_amt_r,
							cdtl.n_curr_gaap_reserve_direct_r,
							cdtl.v_policy_number_r,
							cdtl.n_claim_coverage_sk_r,
							p.n_product_sk_r,
							dim_grp_product_r.v_coverage_code_r,
							cdtl.n_tier_num_r,
							cdtl.v_wfam_code_r,
							cdtl.v_tier_description_r,
							cdtl.d_potential_resolution_date_r,
							cdtl.n_claims_bridged_std_to_ltd_r,
							cdtl.v_ss_pursue_indicated_r,
							cdtl.v_accommodations_needed_r,
							cdtl.n_overpayment_balance_r,
							cdtl.n_ltd_approved_clms_any_occ_r,
							cdtl.n_ltd_approved_clms_own_occ_r,
							cdtl.n_ltd_apprved_ownocc_fulldur_r,
							cdtl.v_ltd_any_occ_group_r,
							cdtl.v_recovery_expectations_r,
							cdtl.v_clinical_voc_engagement_r,
							cdtl.v_policy_prefix_r,
							cdtl.v_policy_suffix_r,
							cdtl.v_coverage_type_code_r,
							cdtl.n_wage_base_r,
							cdtl.n_payment_taxable_benefits_r,
							cdtl.n_payment_nontaxable_ben_r,
							cdtl.n_non_taxable_benefits_r,
							cdtl.n_medicare_wage_base_r,
							cdtl.n_emp_medicare_wage_base_r,
							cdtl.n_emp_fica_wage_base_r,
							cdtl.n_taxable_benefits_r,
							cdtl.n_sit_r,
							cdtl.n_payment_direct_amt_r,
							cdtl.n_medicare_tax_r,
							cdtl.n_futa_r,
							cdtl.n_fit_r,
							cdtl.n_fica_wage_base_r,
							cdtl.n_fica_r,
							cdtl.n_employer_medicare_tax_r,
							cdtl.n_employer_fica_r,
							cdtl.d_last_payment_to_date_r,
							cdtl.d_first_payment_from_date_r,
							cdtl.n_curr_stat_wv_direct_amt_r,
							cdtl.n_curr_gaap_wv_direct_amt_r,
							cdtl.n_chg_stat_wv_direct_amt_r,
							cdtl.n_chg_gaap_wv_direct_amt_r,
							cdtl.d_first_payment_date_r,
							cdtl.n_no_of_void_checks_r,
							cdtl.n_no_of_void_payments_r,
							cdtl.n_curr_stat_reserve_direct_r,
							cdtl.n_curr_field_res_direct_amt_r,
							cdtl.n_curr_be_reserve_direct_amt_r,
							cdtl.n_chg_stat_os_direct_amt_r,
							cdtl.n_chg_field_res_direct_amt_r,
							cdtl.n_chg_be_reserve_direct_amt_r,
							cs.n_total_no_of_payments_r,
							cs.n_no_of_payments_r,
							cs.n_no_of_checks_r,
							cs.d_service_period_from_r,
							fp.n_cust_party_sk_r,
                            cdtl.d_received_date_r,
                            cdtl.d_closure_date_r,
                            dim_grp_product_r.v_product_sub_line_code_r,
							dim_grp_product_r.v_product_line_r
						) sgcsmv
                        /* Join with intermediate tables */
                        LEFT JOIN
                            ATOMIC.fct_rpt_claim_summary_intermediate_mv_tbl frcsimv
                        on
                            frcsimv.v_claim_identifier_r = sgcsmv.v_claim_identifier_r
   						LEFT JOIN
							ATOMIC.fct_rpt_claim_summary_intermediate_mv_tbl2 rcsi
						ON
							rcsi.v_claim_identifier_r = sgcsmv.v_claim_identifier_r
                        /* Rearrange the order of joins to accomodate claims that have a valid Coverage Group (July 2024) */
						LEFT JOIN (
                                SELECT
                                    N_CLAIM_COVERAGE_SK_R,
                                    N_CLAIM_COVERAGE_GROUP_SK_R,
                                    N_CLAIM_SK_R,
                                    V_CLAIM_IDENTIFIER_R,
                                    V_CLAIM_COVERAGE_CODE_R,
                                    V_REASON_CODE_R,
                                    N_RESERVE_AMOUNT_R
                                FROM
                                (
                                    SELECT
                                        N_CLAIM_COVERAGE_SK_R,
                                        N_CLAIM_COVERAGE_GROUP_SK_R,
                                        N_CLAIM_SK_R,
                                        V_CLAIM_IDENTIFIER_R,
                                        V_CLAIM_COVERAGE_CODE_R,
                                        V_REASON_CODE_R,
                                        N_RESERVE_AMOUNT_R,
                                        CASE
                                            WHEN N_CLAIM_CVRG_GRP_SRC_SYS_KEY_R IS NULL
                                                THEN CASE
                                                    WHEN RANK() OVER (PARTITION BY n_claim_sk_r ORDER BY N_CLAIM_CVRG_GRP_SRC_SYS_KEY_R DESC NULLS LAST, N_CLAIM_CVRG_SEQUENCE_NUMBER_R DESC NULLS LAST) = 1
                                                        THEN 1
                                                    ELSE 0
                                                END
                                            ELSE 1
                                        END 	AS 		DF_CVG
                                    FROM
                                        ATOMIC.DIM_GRP_CLAIM_COVERAGE_GROUP_R
                                    WHERE
                                        V_ACTIVE_STATUS_R = 'Y'
                                        AND N_CLAIM_SK_R <> -1
                                ) WHERE DF_CVG = 1
						) T357774
							ON T357774.V_CLAIM_IDENTIFIER_R =  SGCSMV.V_CLAIM_IDENTIFIER_R
							AND T357774.N_CLAIM_COVERAGE_GROUP_SK_R = SGCSMV.N_CLAIM_COVERAGE_GROUP_SK_R
                        /* Moved below as the join with Coverage should be based on the active Coverage Group (July 2024) */
						LEFT JOIN
						(
							SELECT
								*
							FROM (
								SELECT
									N_CLAIM_SK_R,
									N_CLAIM_COVERAGE_SK_R,
									V_CLAIM_COVERAGE_CODE_R,
									RANK() OVER (PARTITION BY T357788.N_CLAIM_SK_R ORDER BY T357788.N_CLAIM_CVRG_SEQUENCE_NUMBER_R DESC NULLS LAST) AS RNK
								FROM
									ATOMIC.DIM_GRP_CLAIM_COVERAGE_R T357788
								WHERE
									T357788.V_ACTIVE_STATUS_R= 'Y'
									AND T357788.N_CLAIM_SK_R <> -1
							)
							WHERE RNK = 1
						) T357788
							ON t357788.n_claim_sk_r =  sgcsmv.n_claim_sk_r
                            AND t357788.n_claim_coverage_sk_r = t357774.n_claim_coverage_sk_r
					)sgcsmv1
				) sgcs_s2
			) sgcs_s3
		)  sgcs_s4
	);
	COMMIT;

		gc_trcmsg:='5. Completed Inserting  Data into  FCT_RPT_CLAIM_SUMMARY_R ';
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
						p_job_id_r            			=> gn_out_job_id,
						p_batch_id_r                  	=> gn_sysdt_batchid,
						p_message_type_r              	=> lv_message_type_r,
						p_code_location_r             	=> gc_main_loadedby,
						p_message_r                   	=> gc_trcmsg,
						p_count_type_r                	=> NULL,
						p_count_r                     	=> NULL,
						p_duration_r                  	=> NULL,
						p_created_by_r                	=> GC_JOB_NAME,
						out_prcs_job_log_message_id_r 	=> gn_job_log_message_id_r
						);

gc_trcmsg:='1. Exit from PRC_GRP_LOAD_FCT_RPT_CLAIM_SUMMARY_R_DATA_INCR ';
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
						p_job_id_r            			=> gn_out_job_id,
						p_batch_id_r                  	=> gn_sysdt_batchid,
						p_message_type_r              	=> lv_message_type_r,
						p_code_location_r             	=> gc_main_loadedby,
						p_message_r                   	=> gc_trcmsg,
						p_count_type_r                	=> NULL,
						p_count_r                     	=> NULL,
						p_duration_r                  	=> NULL,
						p_created_by_r                	=> GC_JOB_NAME,
						out_prcs_job_log_message_id_r 	=> gn_job_log_message_id_r
						);

			pkg_grp_log_util.prc_update_log(
      						gn_out_job_id                   --p_job_id
							,gc_success_status              --p_job_status
							,gc_errmsg                      --p_err_msg
							,gc_trcmsg                      --p_trc_msg
							,gc_main_loadedby               --p_log_util_called_by_r
							);
    IF NVL(P_OUT_LOAD_STATUS, '@X') <> 'ERROR'
		THEN P_OUT_LOAD_STATUS := 'SUCCESS';
    END IF;

    EXCEPTION
		WHEN OTHERS THEN
			ROLLBACK;
		P_OUT_LOAD_STATUS := SUBSTR(SQLERRM, 1, 4000);

gc_errmsg :=SUBSTR(SQLERRM,1,4000);
gc_trcmsg:='1.z Error in PRC_GRP_LOAD_FCT_RPT_CLAIM_SUMMARY_R_DATA_INCR: '||gc_errmsg;

         /*START: NEW LOGGING MECHANISM CHANGES*/
    pkg_grp_log_util.prc_update_log_message_r
			(
			n_prcs_job_log_message_id_r => gn_job_log_message_id_r,
			p_err_msg 					=> gc_trcmsg
				);
	     /*END: NEW LOGGING MECHANISM CHANGES*/

	pkg_grp_log_util.prc_update_log
      (
        gn_out_job_id                   	--p_job_id
        ,gc_error_status                	--p_job_status
        ,gc_errmsg                       	--p_err_msg
        ,gc_trcmsg					     	--p_trc_msg
        ,gc_main_loadedby               	--p_log_util_called_by_r
    );

  	RAISE_APPLICATION_ERROR(-20001,'Error in PRC_GRP_LOAD_FCT_RPT_CLAIM_SUMMARY_R_DATA_INCR:->
    Error Code:'||SQLCODE||',Error message:'||SQLERRM);
END PRC_GRP_LOAD_FCT_RPT_CLAIM_SUMMARY_R_DATA_INCR;

