

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ATOMIC"."PKG_GRP_LOAD_RPT_FCT_RPT_CLAIM_SUMMARY_R_HIST"
IS
/***********************************************************************
  Purpose:  This package body contains procedures which loads data into RPT_FCT_RPT_CLAIM_SUMMARY_R
  Dependent SSL tables : rpt_client_dtl_r
                  rpt_claim_dtl_r
                  rpt_policy_dtl_r
                  rpt_grp_product_r
                  rpt_employee_r
                  rpt_fct_rpt_claim_summary_r
  Used DB Objects:DIM_TIME_R
  Author     Date     Description
  ---------- -------- -------------------------------------------------
  VGireesh   10/11/23 Initial Creation
  VGireesh   03/04/24 Added Parallel to rebuild index fast  parallel 16 nologging
  VGireesh   05/04/24 SOURCE SYSTEM COLUMN REMAPPED CLAIM_DTL
  VGireesh   19/06/24 Added DISTINCT for RPT_CLAIM_DTL_R
  Chandra    21/06/24 Added New Cols V_PFL_LEAVE_REASON_R, V_PFL_FAMILY_MEMBER_RELATIONSHIP_R, V_PFL_LEAVE_TYPE_R, v_policy_prefix_r, v_policy_suffix_r,
                      V_CLAIM_COVERAGE_DESC_R, N_BASIC_INSURED_SALARY_R,V_BASIC_INSURED_SALARY_IND_R, D_CLAIM_STATUS_EFF_DATE_R, V_APPEAL_IND_R, V_APPEAL_RESULT_STATUS_CODE_R, D_APPEAL_RESULT_STATUS_CODE_EFF_DATE_R
  Chandra    18/07/24 Updated Logic for N_Initial_Approval_Rate_R,N_Avg_Claim_Decision_Days_R,N_Closure_Rate_R
                      Added Columns V_Cycle_Month_R,N_Month_Sort_R,N_Initial_Approval_Count_R,N_Initial_Denial_Count_R,N_Reopened_Claim_Count_R,N_Reopened_Rate_R,N_Average_Closed_Claim_Duration_Days_R
                      N_Average_Amount_Paid_Per_Business_Days_R,N_Average_Amount_Paid_Per_Payment_R,N_Percent_Approved_in_Any_Occ_R,N_Avg_Claim_Decision_Days_Den_R,
                      N_Average_Closed_Claim_Duration_Days_Deno_R
  Chandra    25/07/24 Logic change for v_short_name_r Asked by Mereen
  Chandra    26/07/24 Added Column N_PERCENT_APPROVED_IN_ANY_OCC_R_DEN Reuested by BKC
  Chandra    05/08/24 Added Column V_SALES_CLAIM_STATUS_DESC_R requested by Gisha
  Chandra    09/08/24 Mapping change from t3332218.v_wfam_code_r to t3332275.v_wfam_r Requested by Mereen
  Chandra    13/08/24 Changed mapping for t3332275.v_prior_claim_status_code_r to t3332218.v_prior_claim_status_code_r
  Chandra    28/08/24 Added V_CLAIM_DECISION_TYPE_R Column
  Chandra    02/09/24 Added N_ORIGINAL_FACE_AMOUNT_R  Coulmn
  Gireesh    28/10/24 Changes in the below columns logic requested by Mahesh G and Gisha
                      N_INITIAL_APPROVAL_COUNT_R
					  N_INITIAL_DENIAL_COUNT_R
                      N_INITIAL_APPROVAL_RATE_R
  Gireesh    28/10/24 For perofrmance improvement changed DISTINCT to GROUP BY and passed gn_current_month directly to the SSL tables instead of yearmonth joins
  Shiva	     08/08/25 Commented Global Index and Added Local Index Rebuild call.
  Samba		 10/02/26  Capturing the Target count for Audit COntrols when data is inserting into RPT table using Bulkload limit.
  ***********************************************************************/
	--Global Constants
	gd_sysdate               DATE              := TRUNC(SYSDATE);
	gn_prior_month           NUMBER            := TO_NUMBER(TO_CHAR(ADD_MONTHS(TRUNC(gd_sysdate, 'MM'), -1),'YYYYMM'));
	gn_current_month         NUMBER            := TO_NUMBER(TO_CHAR(gd_sysdate,'YYYYMM'));
	gn_sysdt_batchid         NUMBER            := TO_NUMBER(TO_CHAR(gd_sysdate,'YYYYMMDD'));
	gc_main_loadedby         VARCHAR2(200 CHAR):='PKG_GRP_LOAD_RPT_FCT_RPT_CLAIM_SUMMARY_R_HIST.MAIN'      ;
	gc_updby                 VARCHAR2(200 CHAR):='PKG_GRP_LOAD_RPT_FCT_RPT_CLAIM_SUMMARY_R_HIST.PRC_UPD_DEL_DATA';
	gc_getcur_loadedby       VARCHAR2(200 CHAR):='PKG_GRP_LOAD_RPT_FCT_RPT_CLAIM_SUMMARY_R_HIST.PRC_GET_CUR_DATA';
	gc_truncpartby           VARCHAR2(200 CHAR):='PKG_GRP_LOAD_RPT_FCT_RPT_CLAIM_SUMMARY_R_HIST.PRC_TRUNC_PARTITION';
	gc_rebuildindexes           VARCHAR2(200 CHAR):='PKG_GRP_LOAD_RPT_FCT_RPT_CLAIM_SUMMARY_R_HIST.PRC_REBUILD_INDEXES';
	gc_trcmsg                CLOB              :='Trace Message:->';
	gc_job_name              VARCHAR2(50 CHAR) :='GRP_LOAD_RPT_FCT_RPT_CLAIM_SUMMARY_R_HIST';
	gn_bulk_coll_cnt         NUMBER            :=50000;
	gc_running_status        VARCHAR2(30)      :='Running';
	gc_error_status          VARCHAR2(30)      :='Error';
	gc_success_status        VARCHAR2(30)      :='Success';
	gc_source                VARCHAR2(30)      :='EDW';
	gc_target                VARCHAR2(30)      :='RPT';
	gc_main_entity           VARCHAR2(30)      :='CLAIM_SUMMARY_HIST';
	--Global Variables
	gn_out_job_id            NUMBER;
	gc_errmsg                VARCHAR2(4000 CHAR);
	gd_pacs_batch_asof_dt    DATE;

	/*START: 04-JUN-2025: NEW LOGGING MECHANISM CHANGES*/
	gc_message_type_r 	PRCS_JOB_LOG_MESSAGE_R.v_message_type_r%TYPE    := PKG_GRP_LOG_UTIL.gc_message_type_info;
	gc_count_type_r 	PRCS_JOB_LOG_MESSAGE_R.v_count_type_r%TYPE      := PKG_GRP_LOG_UTIL.gc_count_type_insert;

	gn_run_cnt          PRCS_JOB_LOG_MESSAGE_R.N_COUNT_R%TYPE 	 		:=0;
	gn_loop_counter_r   PRCS_JOB_LOG_MESSAGE_R.N_COUNT_R%TYPE 			:=0;
	gt_start_time_r 	TIMESTAMP;
	gt_end_time_r 		TIMESTAMP;
	gn_job_log_message_id_r  NUMBER;
	gn_error_line VARCHAR2(20);
	gd_fic_mis_date          DATE;
	gc_rpt_table_name      	VARCHAR2(50)      	:='RPT_FCT_RPT_CLAIM_SUMMARY_R_HIST';
	gc_rebuild_idx_degree	PLS_INTEGER      	:=8;
	/*END: 04-JUN-2025: NEW LOGGING MECHANISM CHANGES */
	--Procedure to update prior month active flag and current month partition

	--Main procedures calls other procedure to load data in RPT_CLEINT_DTL_R
	PROCEDURE main
	IS
		VAR_REF_CUR SYS_REFCURSOR;
		TYPE var_tbl_type IS TABLE OF RPT_FCT_RPT_CLAIM_SUMMARY_R_HIST%ROWTYPE INDEX BY BINARY_INTEGER;
		lt_var_tbl_typ var_tbl_type;
		ln_rec_cnt NUMBER:=0;
		ln_start_time NUMBER;
		ld_fic_mis_date_2 DATE;
		ln_fisc_current_month NUMBER;
	BEGIN
		--Call Log Util pkg to Insert entry in PRCS_JOB_LOG_R
		pkg_grp_log_util.prc_insert_log
						   ( p_source              => gc_source
							,p_job_nm              => gc_job_name
							,p_job_status          => gc_running_status
							,p_err_msg             => null
							,p_trc_msg             => null
							,p_n_batch_id          => gn_sysdt_batchid
							,p_log_util_called_by_r=> gc_main_loadedby
							,out_job_id            => gn_out_job_id
							);

		/*START: 04-JUN-2025: NEW LOGGING MECHANISM CHANGES*/
		 gc_trcmsg:='1. Entered into main. ';
		 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
		 (
			p_job_id_r                    => gn_out_job_id,
			p_batch_id_r                  => gn_sysdt_batchid,
			p_message_type_r              => gc_message_type_r,
			p_code_location_r             => gc_main_loadedby,
			p_message_r                   => gc_trcmsg,
			p_count_type_r                => NULL,
			p_count_r                     => NULL,
			p_duration_r                  => NULL,
			p_created_by_r                => GC_JOB_NAME,
			out_prcs_job_log_message_id_r => gn_job_log_message_id_r
		);
		/*END: 04-JUN-2025: NEW LOGGING MECHANISM CHANGES*/

		/*Common Utility Proc to get month end+2 date and month. Ex: If month end is 29-Aug-2025 then ln_fisc_current_month will be 202509*/
		PKG_GRP_COMMON_UTIL.prc_fisc_month_calc
		(
			p_out_job_id            =>	gn_out_job_id,
			p_Log_seq_num           =>	2,
			ld_fic_mis_date_2       =>	ld_fic_mis_date_2,
			ln_fisc_current_month   =>	ln_fisc_current_month

		);

		gd_fic_mis_date := ld_fic_mis_date_2;--29-Aug-2024 changes

		/*Common Utility Proc to determine current and prior month ; Checks for month end logic and daily load logic as well */
		PKG_GRP_COMMON_UTIL.PRC_GET_CURRENT_PRIOR_MONTH
		(
			p_out_job_id            =>	gn_out_job_id,
			p_Log_seq_num           =>	3,
			P_fic_mis_date       	=>	ld_fic_mis_date_2,
			P_fisc_current_month    =>	ln_fisc_current_month,
			p_current_month         =>	gn_current_month,
			p_prior_month           =>	gn_prior_month
		);
		PKG_GRP_COMMON_UTIL.prc_trunc_partition
		(
			p_out_job_id    	=>	gn_out_job_id,
			p_Log_seq_num   	=>	4,
			p_rpt_table     	=>	gc_rpt_table_name,
			p_idx_num       	=>	gc_rebuild_idx_degree,
			p_current_month     =>	gn_current_month
		);
		gc_trcmsg:=gc_trcmsg||'5. Call prc_get_cur_data to get ref_cursor '||chr(13);
		PKG_GRP_LOAD_RPT_FCT_RPT_CLAIM_SUMMARY_R_HIST.prc_get_cur_data (var_ref_cur);


		gt_start_time_r:= SYSTIMESTAMP;

		/*START: 04-JUN-2025: NEW LOGGING MECHANISM CHANGES*/
			gc_trcmsg    :='6 Data load starts '||chr(13);
			 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
			 (
				p_job_id_r                    => gn_out_job_id,
				p_batch_id_r                  => gn_sysdt_batchid,
				p_message_type_r              => gc_message_type_r,
				p_code_location_r             => gc_main_loadedby,
				p_message_r                   => gc_trcmsg,
				p_count_type_r                => NULL,
				p_count_r                     => NULL,
				p_duration_r                  => NULL,
				p_created_by_r                => GC_JOB_NAME,
				out_prcs_job_log_message_id_r => gn_job_log_message_id_r
			);


		gn_loop_counter_r := 1; -- Initialize loop counter
		gc_count_type_r:=PKG_GRP_LOG_UTIL.gc_count_type_insert;
		/*END: 04-JUN-2025: NEW LOGGING MECHANISM CHANGES*/

		ln_rec_cnt:=0;
		ln_start_time:=dbms_utility.get_time;
		LOOP
			lt_var_tbl_typ.DELETE;
			FETCH var_ref_cur BULK COLLECT INTO  lt_var_tbl_typ LIMIT gn_bulk_coll_cnt;

			gt_start_time_r := SYSTIMESTAMP; -- Start timing before the insert

			 FORALL x in lt_var_tbl_typ.First..lt_var_tbl_typ.Last
			 INSERT INTO RPT_FCT_RPT_CLAIM_SUMMARY_R_HIST VALUES lt_var_tbl_typ(x) ;
			 ln_rec_cnt:=ln_rec_cnt+lt_var_tbl_typ.COUNT;
			 COMMIT;

			gt_end_time_r := SYSTIMESTAMP; -- End timing after the insert
			gc_trcmsg := '6.a data load: Bulk Set-'|| gn_loop_counter_r ||': '||LN_REC_CNT||' records loaded' ;
			PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
			(
				p_job_id_r => gn_out_job_id,
				p_batch_id_r => gn_sysdt_batchid,
				p_message_type_r => gc_message_type_r,
				p_code_location_r => gc_main_loadedby,
				p_message_r => gc_trcmsg,
				p_count_type_r => gc_count_type_r,
				p_count_r => gn_bulk_coll_cnt,
				p_duration_r => FNC_GRP_TIME_DURATION(gt_start_time_r,gt_end_time_r),
				p_created_by_r => GC_JOB_NAME,
				out_prcs_job_log_message_id_r => gn_job_log_message_id_r
			);
			gn_loop_counter_r:= gn_loop_counter_r + 1;

		EXIT WHEN var_ref_cur%NOTFOUND;
		END LOOP;
		CLOSE var_ref_cur;--23-Jan-2024 Changes
		gc_trcmsg:=gc_trcmsg||'6.b Data Loaded '||ln_rec_cnt||' records in '||((dbms_utility.get_time - ln_start_time)/100)|| ' seconds'||chr(13);

	  /*START: 04-JUN-2025: NEW LOGGING MECHANISM CHANGES*/

		gt_end_time_r:= SYSTIMESTAMP;

			 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
			 (
				p_job_id_r                    => gn_out_job_id,
				p_batch_id_r                  => gn_sysdt_batchid,
				p_message_type_r              => gc_message_type_r,
				p_code_location_r             => gc_main_loadedby,
				p_message_r                   => gc_trcmsg,
				p_count_type_r                => gc_count_type_r,
				p_count_r                     => ln_rec_cnt,
				p_duration_r                  => FNC_GRP_TIME_DURATION(gt_start_time_r,gt_end_time_r),
				p_created_by_r                => GC_JOB_NAME,
				out_prcs_job_log_message_id_r => gn_job_log_message_id_r
			);
		/*END: 04-JUN-2025: NEW LOGGING MECHANISM CHANGES*/

		gc_trcmsg:='6.c Target count for Audit control Process';

		/*START: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
			 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
			 (
				p_job_id_r                    => gn_out_job_id,
				p_batch_id_r                  => gn_sysdt_batchid,
				p_message_type_r              => gc_message_type_r,
				p_code_location_r             => gc_main_loadedby,
				p_message_r                   => gc_trcmsg,
				p_count_type_r                => 'AUDIT_TARGET_COUNT',
				p_count_r                     => ln_rec_cnt,
				p_duration_r                  => NULL,
				p_created_by_r                => GC_JOB_NAME,
				out_prcs_job_log_message_id_r => gn_job_log_message_id_r
			);

		ln_start_time:=dbms_utility.get_time;

	  /*START: 04-JUN-2025: NEW LOGGING MECHANISM CHANGES*/
		gc_trcmsg    :='7. Rebuild Local Index prc_rebuild_index_partitions from Common Util for Partition: '||gn_current_month;
		gt_start_time_r:=SYSTIMESTAMP;
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
		 (
			p_job_id_r                    => gn_out_job_id,
			p_batch_id_r                  => gn_sysdt_batchid,
			p_message_type_r              => gc_message_type_r,
			p_code_location_r             => gc_main_loadedby,
			p_message_r                   => gc_trcmsg,
			p_count_type_r                => NULL,
			p_count_r                     => NULL,
			p_duration_r                  => NULL,
			p_created_by_r                => GC_JOB_NAME,
			out_prcs_job_log_message_id_r => gn_job_log_message_id_r
		);
		/*END: 04-JUN-2025: NEW LOGGING MECHANISM CHANGES*/

		-- 8th Aug 2025: Commenting Globale Rebuild Index
		-- prc_rebuild_indexes;

		--8th Aug 2025: Added Local Index Rebuild
		PKG_GRP_COMMON_UTIL.prc_rebuild_index_partitions
		(
			p_table_name   		  		  => 'RPT_FCT_RPT_CLAIM_SUMMARY_R_HIST',
			p_parallel_degree   		  => 8,
			p_partition_name  		  	  => 'PART_RPT_FCT_RPT_CLAIM_SUMMARY_R_HIST_'||gn_current_month,
			p_out_job_id              	  => gn_out_job_id,
			p_Log_seq_num             	  => 8
		);


	  /*START: 04-JUN-2025: NEW LOGGING MECHANISM CHANGES*/
		gc_trcmsg:='8 Completed Procedure unusable prc_rebuild_indexes call from main '||chr(13);
		gt_end_time_r:= SYSTIMESTAMP;

		 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
		 (
			p_job_id_r                    => gn_out_job_id,
			p_batch_id_r                  => gn_sysdt_batchid,
			p_message_type_r              => gc_message_type_r,
			p_code_location_r             => gc_main_loadedby,
			p_message_r                   => gc_trcmsg,
			p_count_type_r                => NULL,
			p_count_r                     => NULL,
			p_duration_r                  => FNC_GRP_TIME_DURATION(gt_start_time_r,gt_end_time_r),
			p_created_by_r                => GC_JOB_NAME,
			out_prcs_job_log_message_id_r => gn_job_log_message_id_r
		);
		/*END: 04-JUN-2025: NEW LOGGING MECHANISM CHANGES*/

		gc_trcmsg:='9 Calling Audit Control Procedure';

		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
		 (
			p_job_id_r                    => gn_out_job_id,
			p_batch_id_r                  => gn_sysdt_batchid,
			p_message_type_r              => gc_message_type_r,
			p_code_location_r             => gc_main_loadedby,
			p_message_r                   => gc_trcmsg,
			p_count_type_r                => NULL,
			p_count_r                     => NULL,
			p_duration_r                  => NULL,
			p_created_by_r                => GC_JOB_NAME,
			out_prcs_job_log_message_id_r => gn_job_log_message_id_r
		);

	PRC_GRP_AUDIT_CONTROL_PROCESS(gc_source,gc_main_entity,gc_source,gc_target);

	gc_trcmsg:='9 Exit from main'||chr(13);

		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
		 (
			p_job_id_r                    => gn_out_job_id,
			p_batch_id_r                  => gn_sysdt_batchid,
			p_message_type_r              => gc_message_type_r,
			p_code_location_r             => gc_main_loadedby,
			p_message_r                   => gc_trcmsg,
			p_count_type_r                => NULL,
			p_count_r                     => NULL,
			p_duration_r                  => NULL,
			p_created_by_r                => GC_JOB_NAME,
			out_prcs_job_log_message_id_r => gn_job_log_message_id_r
		);


		pkg_grp_log_util.prc_update_log
		  (
			p_job_id => gn_out_job_id
			,p_job_status => gc_success_status
			,p_err_msg => gc_errmsg
			,p_trc_msg => gc_trcmsg
			,p_log_util_called_by_r => gc_main_loadedby
		  );

	EXCEPTION
	WHEN OTHERS THEN
		gc_errmsg :=SUBSTR(SQLERRM,1,4000);
		gc_trcmsg:='1. Error in main'||chr(13);

		/*START: 04-JUN-2025: NEW LOGGING MECHANISM CHANGES*/
			pkg_grp_log_util.prc_update_log_message_r
			(
			n_prcs_job_log_message_id_r => gn_job_log_message_id_r,
			p_err_msg => gc_trcmsg
			);
		/*END: 04-JUN-2025: NEW LOGGING MECHANISM CHANGES*/

		pkg_grp_log_util.prc_update_log
		  (
			gn_out_job_id                   --p_job_id
			,gc_error_status                --p_job_status
			,gc_errmsg                      --p_err_msg
			,gc_errmsg  					--p_trc_msg
			,gc_main_loadedby               --p_log_util_called_by_r
		  );
		RAISE;
	END main;

	--Procedure to perform ref cursor assignment
	PROCEDURE prc_get_cur_data(
		p_out_cursor OUT SYS_REFCURSOR
		)
	AS
	BEGIN

		 /*START: 04-JUN-2025: NEW LOGGING MECHANISM CHANGES*/
			gc_trcmsg:='5.1 Entered into prc_get_cur_data '||chr(13);
			gt_start_time_r:= SYSTIMESTAMP;

			 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
			 (
				p_job_id_r                    => gn_out_job_id,
				p_batch_id_r                  => gn_sysdt_batchid,
				p_message_type_r              => gc_message_type_r,
				p_code_location_r             => gc_getcur_loadedby,
				p_message_r                   => gc_trcmsg,
				p_count_type_r                => NULL,
				p_count_r                     => NULL,
				p_duration_r                  => NULL,
				p_created_by_r                => GC_JOB_NAME,
				out_prcs_job_log_message_id_r => gn_job_log_message_id_r
			);
		/*END: 04-JUN-2025: NEW LOGGING MECHANISM CHANGES*/
		   --Open/Assign SELECT stmnt
			OPEN p_out_cursor FOR
			SELECT /*+PARALLEL(4)*/
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
				--18/07/24 changes start
				--case  when t3332218.V_CLAIM_DECISION_IND_R = 'Y' then 1 else 0 end                    as N_Initial_Approval_Rate_R,
				--18/07/24 changes End
				--28/10/24 changes starts
				/*((case  when V_CLAIM_DECISION_IND_R = 'Y' and upper(V_CLAIM_ACTIVITY_DETAIL_R) like 'APPROVED%'
				 then N_APPROVED_CLAIM_COUNT_R + N_CLOSED_CLAIM_COUNT_R
				 else 0 end)+(CASE WHEN t3332218.V_CLAIM_DECISION_IND_R = 'Y'
				 AND NOT UPPER(t3332218.V_CLAIM_ACTIVITY_DETAIL_R) LIKE 'APPROVED%'
				 THEN t3332218.N_APPROVED_CLAIM_COUNT_R + t3332218.N_CLOSED_CLAIM_COUNT_R
				 ELSE 0
				 END 	))*/
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
				--28/10/24 changes Ends
				 as N_Initial_Approval_Rate_R,
				t3332218.n_approval_rate_by_plan_ep_r,
				t3332218.n_initial_closure_rate_r,
				--18/07/24 Changes Start
				((t3332218.N_PENDING_CLAIM_COUNT_R - t3332218.N_CHG_PENDING_CLAIM_COUNT_R) +
				(t3332218.N_APPROVED_CLAIM_COUNT_R - t3332218.N_CHG_APPROVED_CLAIM_COUNT_R))          AS N_Closure_Rate_R,
				--18/07/24 Changes End
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
				--t3332218.FIC_MIS_DATE_R,
				--t3332218.v_source_system_name_r,--05-Apr-2024 changes
				t3332275.v_source_system_name_r,--05-Apr-2024 changes
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
				t3332275.v_wfam_r        as v_wfam_code_r,   ----09/08/24 Mapping change from t3332218.v_wfam_code_r to t3332275.v_wfam_r Requested by Mereen
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
				--t3332218.V_PRIVACY_INDICATOR_R,
				t3332218.v_coverage_group_id_r,
				--t3332218.V_CLAIM_IDENTIFIER_R,
				t3332218.n_claim_coverage_group_sk_r,
				t3332218.n_claim_coverage_sk_r,
				t3332218.v_clinical_voc_engagement_r,
				--t3332218.V_COVERAGE_TYPE_CODE_R,
				t3332218.n_chg_field_res_ceded_amt_r,
				t3332218.n_cycle_date_key_r,
				t3332218.d_received_date_r,
				t3332275.v_claim_coverage_code_r,--26-Mar-2024 changes
				--t3332218.v_claim_coverage_code_r,--26-Mar-2024 changes
				t3332218.v_claim_status_reason_code_r,
				t3332218.v_reason_code_r,
				t3332218.n_insrd_party_sk_r,
				t3332218.n_employee_sk_r,
				t3332218.n_yearmonth_r,
				t3332218.v_rpt_active_status_r,
				--18/07/24 Changes Start
				CASE WHEN V_CLAIM_DECISION_IND_R = 'Y'
				THEN (NVL(D_CLAIM_DECISION_DATE_R, SYSDATE) - D_CLAIM_RECEIVED_DATE_R ) ELSE 0 END
				AS N_Avg_Claim_Decision_Days_R,
				--18/07/24 Changes End
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
				--nvl(t3332275.v_tier_r, 'TIER 0')                  v_tier_adj_r,--19-Jun-2024 changes
				t3332275.v_tier_adj_r,                                           --19-Jun-2024 changes
				--trunc(t3332275.d_claim_closed_date_r)             d_trunc_claim_closed_date_r,--19-Jun-2024 changes
				t3332275.d_trunc_claim_closed_date_r,                                           --19-Jun-2024 changes
				t3332275.v_curr_claim_status_code_r,
				t3332146.v_coverage_type_code_r,--
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
			   -- t3332177.v_short_name_r,
			   --25/07/24 changes start
				CASE    WHEN t3332256.v_carrier_name_r = 'Reliance Standard Life Insurance Company'             THEN  'RSL'
						WHEN t3332256.v_carrier_name_r = 'First Reliance Standard Life Insurance Company'       THEN  'FRSLIC'
					else t3332256.v_carrier_name_r
					END AS v_short_name_r,
				--25/07/24 changes end
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
				--21/06/24 changes start
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
				--21/06/24 changes end
				--18/07/24 changes start
				--,CONCAT(TO_CHAR(t3332218.D_CYCLE_DATE_R, 'Month'),CAST(EXTRACT(YEAR FROM t3332218.D_CYCLE_DATE_R) AS VARCHAR(15)))                    AS V_cycle_Month_R,
				,CAST(TO_CHAR(t3332218.D_CYCLE_DATE_R, 'Mon') || ' ' || TO_CHAR(t3332218.D_CYCLE_DATE_R, 'YYYY') AS VARCHAR2(15))                     AS V_cycle_Month_R,
				 EXTRACT(YEAR FROM t3332218.D_CYCLE_DATE_R) * 100 + EXTRACT(MONTH FROM t3332218.D_CYCLE_DATE_R)                                       AS N_Month_Sort_R,
				 --28/10/24 changes starts
				 /*case  when V_CLAIM_DECISION_IND_R = 'Y' and upper(V_CLAIM_ACTIVITY_DETAIL_R) like 'APPROVED%'
				 then N_APPROVED_CLAIM_COUNT_R + N_CLOSED_CLAIM_COUNT_R
				 else 0 end*/
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
				 --28/10/24 changes ends
				 AS N_Initial_Approval_Count_R,
				 --28/10/24 changes starts
				 /*
				 CASE WHEN t3332218.V_CLAIM_DECISION_IND_R = 'Y'
				 AND NOT UPPER(t3332218.V_CLAIM_ACTIVITY_DETAIL_R) LIKE 'APPROVED%'
				 THEN t3332218.N_APPROVED_CLAIM_COUNT_R + t3332218.N_CLOSED_CLAIM_COUNT_R
				 ELSE 0
				 END*/
				 (CASE WHEN t3332218.V_CLAIM_DECISION_IND_R = 'Y'
					AND NOT
					--Change: Based on Product Line, take either Claim Activity Detail or Claim Decision Type
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
				 --28/10/24 changes ends
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
				 --case when t3332256.FIC_MIS_DATE_R >t3332275.D_ANY_OCC_START_DATE_R then t3332218.N_APPROVED_CLAIM_COUNT_R ELSE 0 END                AS N_Percent_Approved_in_Any_Occ_R,
				 case when  t3332275.V_CURR_CLAIM_STATUS_CODE_R = '63' then N_CHG_CLOSED_CLAIM_COUNT_R else 0 end                                             as N_PERCENT_APPROVED_IN_ANY_OCC_R,
				 CASE WHEN V_CLAIM_DECISION_IND_R = 'Y'
				 THEN N_APPROVED_CLAIM_COUNT_R + N_CLOSED_CLAIM_COUNT_R ELSE 0 END                                                                   AS N_Avg_Claim_Decision_Days_Den_R,
				 CASE WHEN N_CHG_CLOSED_CLAIM_COUNT_R > 0 AND N_TOTAL_BENEFIT_PERIOD_DAYS_R <> 0 AND  N_TOTAL_BENEFIT_PERIOD_DAYS_R IS NOT NULL
				 then t3332218.N_TOTAL_CLAIM_COUNT_R else 0 end                                                                                      as N_Average_Closed_Claim_Duration_Days_Deno_R,
				 --18/07/24 changes End
				 --,t3332256.V_ADMINISTERED_BY_R AS V_POLICY_SHORTNAME_R
				 --26/07/24 Changes Start
				 CASE WHEN (case when  (select  N_FISCAL_YEAR_R||lpad(N_FISCAL_MONTH_R,2,0)from dim_time_r where
				 d_calendar_date_r =  t3332275.D_ANY_OCC_START_DATE_R) = t3332275.n_yearmonth_r THEN 1 ELSE 0 END) =1   AND
				 (t3332218.N_APPROVED_CLAIM_COUNT_R-t3332218.N_CHG_APPROVED_CLAIM_COUNT_R)>0
				then N_TOTAL_CLAIM_COUNT_R else 0 end                                                                                               as N_PERCENT_APPROVED_IN_ANY_OCC_R_DEN,
				 --26/07/24 Changes End
				--05/08/24 Changes Start
				t3332275.V_SALES_CLAIM_STATUS_DESC_R,
				--05/08/24 Changes End
				--28/08/24 changes start
				 t3332218.V_CLAIM_DECISION_TYPE_R
				 --28/08/24 changes End
				--02/09/24 Changes start
				,t3332218.N_ORIGINAL_FACE_AMOUNT_R
				--02/09/24 Changes start
			  FROM
				atomic.rpt_client_dtl_r            t3332177 /* D_RPT_CLIENT_DTL */,
				--19-jUN-2024 CHANGES STARTS
				(SELECT --DISTINCT --28/10/24 changes
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
				   --21/06/24 Changes Start
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
				   --21/06/24 Changes End
				   --05/08/24 Changes Start
				   rpt_claim_dtl_r.V_SALES_CLAIM_STATUS_DESC_R,
					--05/08/24 Changes End
				   rpt_claim_dtl_r.v_wfam_r

				  FROM --19-jUN-2024 CHANGES ENDS
					 atomic.rpt_claim_dtl_r
				  --28/10/24 Changes starts
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
				  --28/10/24 Changes ends
				) --19-jUN-2024 CHANGES
				 t3332275 /* D_RPT_CLAIM_DTL */,
				atomic.rpt_policy_dtl_r            t3332256 /* D_RPT_POLICY_DTL */,--new col-->policy shortname based desc
				atomic.rpt_grp_product_r           t3332146 /* D_GRP_PRODUCT */,
				atomic.rpt_employee_r              t3332164 /* D_EMPLOYEE */,
				atomic.rpt_fct_rpt_claim_summary_r t3332218 /* F_RPT_CLAIM_SUMMARY */,
				(
					SELECT
						n_claims_month_r,
						n_claims_year_r,
						COUNT(d_calendar_date_r) N_BUSS_DAYS_IN_MONTH_R  --earlier N_BUSS_DAYS_IN_MONTH_R was buss_days_in_month changed to N_BUSS_DAYS_IN_MONTH_R as per @Mereen Request
					FROM
						dim_time_r
					WHERE
							v_business_day_ind_r = 'Y'
				--AND d_calendar_date_r <= TO_DATE(sysdate, 'MM/DD/YYYY') -- pass as of date
				AND d_calendar_date_r < TO_DATE(sysdate)--, 'MM/DD/YYYY') -- pass as of date
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
			  --AND t3332146.n_yearmonth_r = t3332218.n_yearmonth_r-- pass max date from claim dtl); --28/10/24 changes
			  AND t3332164.n_employee_sk_r = t3332218.n_employee_sk_r
			  AND t3332218.n_claim_coverage_group_sk_r = t3332275.n_claim_coverage_group_sk_r
			  AND t3332218.n_claim_coverage_sk_r = t3332275.n_claim_coverage_sk_r
			  AND t3332218.n_claim_sk_r = t3332275.n_claim_sk_r
			  --28/10/24 changes starts
			  /*
			  AND t3332256.n_yearmonth_r = t3332218.n_yearmonth_r-- pass max date from claim dtl);
			  AND t3332177.n_yearmonth_r  =t3332218.n_yearmonth_r  -- pass max date from claim dtl-- pass max date from claim dtl
			  AND nvl(upper(t3332164.v_business_unit_r),
					  'CLAIMS') = 'CLAIMS'
			  AND t3332164.n_yearmonth_r = t3332218.n_yearmonth_r-- pass max date from claim dtl);
			  AND t3332275.n_yearmonth_r = t3332218.n_yearmonth_r-- pass max date from claim dtl);
			  */
			  AND nvl(upper(t3332164.v_business_unit_r),'CLAIMS') = 'CLAIMS'
			  AND t3332146.n_yearmonth_r = GN_CURRENT_MONTH
			  AND t3332256.n_yearmonth_r = GN_CURRENT_MONTH
			  AND t3332177.n_yearmonth_r = GN_CURRENT_MONTH
			  and t3332218.n_yearmonth_r = GN_CURRENT_MONTH
			  and t3332164.n_yearmonth_r = GN_CURRENT_MONTH
			  --and t3332275.n_yearmonth_r =GN_CURRENT_MONTH
			  --28/10/24 changes ends
			 --and t3332218.d_cycle_date_r = '27-DEC-23'
			  )
			  ;
		gn_run_cnt:= SQL%ROWCOUNT;
		gc_count_type_r:=PKG_GRP_LOG_UTIL.gc_count_type_insert;

		/*START: 04-JUN-2025: NEW LOGGING MECHANISM CHANGES*/
		gc_trcmsg := '5.2 Exit from prc_get_cur_data'||chr(13);
		gt_end_time_r:= SYSTIMESTAMP;

		 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
		 (
			p_job_id_r                    => gn_out_job_id,
			p_batch_id_r                  => gn_sysdt_batchid,
			p_message_type_r              => gc_message_type_r,
			p_code_location_r             => gc_getcur_loadedby,
			p_message_r                   => gc_trcmsg,
			p_count_type_r                => gc_count_type_r,
			p_count_r                     => gn_run_cnt,
			p_duration_r                  => FNC_GRP_TIME_DURATION(gt_start_time_r,gt_end_time_r),
			p_created_by_r                => GC_JOB_NAME,
			out_prcs_job_log_message_id_r => gn_job_log_message_id_r
		);
		/*END: 04-JUN-2025: NEW LOGGING MECHANISM CHANGES*/

	EXCEPTION
	WHEN OTHERS THEN
		gc_errmsg :=SUBSTR(SQLERRM,1,4000);

		/*START: 04-JUN-2025: NEW LOGGING MECHANISM CHANGES*/
			gc_trcmsg :='5.z Error in prc_get_cur_data'||chr(13);
			pkg_grp_log_util.prc_update_log_message_r
			(
			n_prcs_job_log_message_id_r => gn_job_log_message_id_r,
			p_err_msg => gc_trcmsg
			);
		/*END: 04-JUN-2025: NEW LOGGING MECHANISM CHANGES*/

		pkg_grp_log_util.prc_update_log
			  (
				gn_out_job_id                   --p_job_id
				,gc_error_status                --p_job_status
				,gc_errmsg                      --p_err_msg
				,gc_trcmsg||chr(13)||gc_errmsg  --p_trc_msg
				,gc_getcur_loadedby             --p_log_util_called_by_r
			  );
		RAISE;
	END prc_get_cur_data;

	--Procedure to rebuild indexes RPT_FCT_RPT_CLAIM_SUMMARY_R_HIST
	PROCEDURE prc_rebuild_indexes
	IS
	LC_REBUILD_INDEX  VARCHAR2(300);
	BEGIN
	   gc_trcmsg:=gc_trcmsg||'7.a Entered into prc_rebuild_indexes'||chr(13);
	  FOR I IN ( select
		'ALTER INDEX '||INDEX_NAME||' REBUILD  parallel 8 nologging' REBUILD_INDEX
		from ALL_INDEXES  where TABLE_NAME ='RPT_FCT_RPT_CLAIM_SUMMARY_R_HIST'
		AND INDEX_NAME NOT LIKE 'PK_%'
		AND INDEX_NAME NOT LIKE 'FK_%'
		AND STATUS='UNUSABLE'
		)
	  LOOP
		LC_REBUILD_INDEX:=I.REBUILD_INDEX;
		EXECUTE IMMEDIATE LC_REBUILD_INDEX;
	  END LOOP;
	   gc_trcmsg:=gc_trcmsg||'7.z Exit from prc_rebuild_indexes'||chr(13);
	EXCEPTION
	WHEN OTHERS THEN
		gc_errmsg :=SUBSTR(SQLERRM,1,4000);
		gc_trcmsg:='7.z Error in prc_rebuild_indexes'||chr(13);

		  /*START: 04-JUN-2025: NEW LOGGING MECHANISM CHANGES*/
			pkg_grp_log_util.prc_update_log_message_r
		(
			n_prcs_job_log_message_id_r => gn_job_log_message_id_r,
			p_err_msg => gc_trcmsg
		);
		/*END: 04-JUN-2025: NEW LOGGING MECHANISM CHANGES*/

		pkg_grp_log_util.prc_update_log
			  (
				gn_out_job_id                   --p_job_id
				,gc_error_status                --p_job_status
				,gc_errmsg                      --p_err_msg
				,gc_trcmsg||chr(13)||gc_errmsg  --p_trc_msg
				,gc_rebuildindexes             --p_log_util_called_by_r
			  );
		RAISE;
	END prc_rebuild_indexes;

end PKG_GRP_LOAD_RPT_FCT_RPT_CLAIM_SUMMARY_R_HIST;

