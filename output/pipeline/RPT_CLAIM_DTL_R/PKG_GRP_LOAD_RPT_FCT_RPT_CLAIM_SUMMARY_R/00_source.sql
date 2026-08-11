

  CREATE OR REPLACE EDITIONABLE PACKAGE "ATOMIC"."PKG_GRP_LOAD_RPT_FCT_RPT_CLAIM_SUMMARY_R"
IS
/***********************************************************************
  Purpose:  This package body contains procedures which loads data into RPT_FCT_RPT_CLAIM_SUMMARY_R
  Dependent SSL tables : FCT_RPT_CLAIM_SUMMARY_R,RPT_CLAIM_DTL_R,RPT_CLAIM_SUM_R

  Used DB Objects:FCT_RPT_CLAIM_SUMMARY_R
                  RPT_CLAIM_DTL_R
                  RPT_CLAIM_SUM_R


  Author     Date     Description
  ---------- -------- -------------------------------------------------
  VGireesh   10/11/23 Initial Creation
  VGireesh   09/02/24 Added below functions
                      get_pacs_as_of_date_r
					  get_n_avg_claim_decision_days_r
					  get_n_claim_approach_dur_r
					  get_n_claim_approach_exp_resolution_r
					  get_n_duration_remaining_r
***********************************************************************/


--main procedure
PROCEDURE main;
--Procedure declaration for ref cursor assignment
PROCEDURE prc_get_cur_data(
    p_out_cursor OUT SYS_REFCURSOR);
--09-feb-2024 changes starts
--Function to get Pacs as of date
FUNCTION get_pacs_as_of_date_r
RETURN DATE;
--Function to get n_avg_claim_decission_days_r
FUNCTION get_n_avg_claim_decision_days_r(
                                    p_n_claim_sk_r IN NUMBER
                                   ,p_n_claim_coverage_sk_r IN NUMBER
                                   ,p_n_claim_coverage_group_sk_r IN NUMBER
                                   ,p_d_claim_decision_date_r IN DATE
								   ,p_v_claim_decision_ind_r IN VARCHAR2
                                   ,p_n_yearmonth_r IN NUMBER
								   )
RETURN NUMBER;
--Function to get n_claim_approach_dur_r
FUNCTION get_n_claim_approach_dur_r(p_n_claim_sk_r IN NUMBER
                                   ,p_n_claim_coverage_sk_r IN NUMBER
                                   ,p_n_claim_coverage_group_sk_r IN NUMBER
								   ,p_v_claim_activity_detail_r IN VARCHAR2
								   ,p_d_pacs_as_of_date_r   IN DATE
                                   ,p_n_yearmonth_r IN NUMBER
								   )
RETURN NUMBER;
--Function to get n_claim_approach_exp_resolution_r
FUNCTION get_n_claim_approach_exp_resolution_r(p_n_claim_sk_r IN NUMBER
                                   ,p_n_claim_coverage_sk_r IN NUMBER
                                   ,p_n_claim_coverage_group_sk_r IN NUMBER
                                   ,p_d_potential_resolution_date_r IN DATE
								   ,p_v_claim_activity_detail_r IN VARCHAR2
								   ,p_d_pacs_as_of_date_r   IN DATE
                                   ,p_n_yearmonth_r IN NUMBER
								   )
RETURN NUMBER;
--Function to get n_duration_remaining_r
FUNCTION get_n_duration_remaining_r(p_n_claim_sk_r IN NUMBER
                                   ,p_n_claim_coverage_sk_r IN NUMBER
                                   ,p_n_claim_coverage_group_sk_r IN NUMBER
								   ,p_d_pacs_as_of_date_r   IN DATE
                                   ,p_n_yearmonth_r IN NUMBER
								   )
RETURN NUMBER;

--09-feb-2024 changes ends

END PKG_GRP_LOAD_RPT_FCT_RPT_CLAIM_SUMMARY_R;
/
CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ATOMIC"."PKG_GRP_LOAD_RPT_FCT_RPT_CLAIM_SUMMARY_R"
IS
/***********************************************************************
  Purpose:  This package body contains procedures which loads data into RPT_FCT_RPT_CLAIM_SUMMARY_R
  Dependent SSL tables : RPT_CLAIM_DTL_R,RPT_CLAIM_SUM_R,RPT_FCT_RPT_CLAIM_SUMMARY_R
   Used DB Objects:FCT_RPT_CLAIM_SUMMARY_R



  Author     Date     Description
  ---------- -------- -------------------------------------------------
  VGireesh   10/11/23 Initial Creation
  VGireesh   01/02/24 Commented out gather stats and indexes build procedure
  VGireesh   09/02/24 Added below columns
                      N_AVG_CLAIM_DECISION_DAYS_R
                      N_CLAIM_APPROACH_DUR_R
                      N_CLAIM_APPROACH_EXP_RESOLUTION_R
                      N_DURATION_REMAINING_R
  VGireesh   09/02/24 Added below functions to populate above columns in the seperate block
                      get_pacs_as_of_date_r
					  get_n_avg_claim_decision_days_r
					  get_n_claim_approach_dur_r
					  get_n_claim_approach_exp_resolution_r
					  get_n_duration_remaining_r
  VGireesh   22/02/24 enabled rebuilding indexes
  VGireesh   26/02/24 Changed date condition in the functions
  VGireesh   26/02/24 for month end  that the tables start loading data in the next month partition
                      Ex: March data on February 29th (as of 2.28).
                          27th is Feb Fisc Month End    202402  should be truncate and load in 202402 partition
                          28th is feb Fisc Month End +1 202402  should be truncate and load in 202402 partition
                          29th is Feb Fisc Month End +2 202403  should inactive records against the partition 202402 and load data in 202403 partition
  VGireesh   03/04/24 Added Parallel to rebuild index fast  parallel 16 nologging
  VGireesh   12/04/24 Added 2 more MERGE statements as requested by Erica for DF
  Chandra    12/08/23 Added 5 New column and Join condition.
  Chandra    28/08/24 Added V_CLAIM_DECISION_TYPE_R Column
  Chandra    02/09/24 Added N_ORIGINAL_FACE_AMOUNT_R  Coulmn
  Chandra    17/09/24 Logic change of a.D_POTENTIAL_RESOLUTION_DATE_R  to d.D_PRD_R AS  D_POTENTIAL_RESOLUTION_DATE_R and
                      d.N_TIER_NUM_R AS V_TIER_NUM_R
                     ,d.V_TIER_DESCRIPTION_R
  Rose		 21/05/25  Commented update flag = 'N' for Month End+2 Load.
					   Added Truncate for Month End+2 Load
  Rose		 22/05/25  Added new logging Mechanism
  Shiva		 08/08/25  Commented Global Index, Added Local Index Rebuild
  Samba		 10/02/26  Capturing the Target count for Audit COntrols when data is inserting into RPT table using Bulkload limit.
  ***********************************************************************/
	--Global Constants
	gd_sysdate               DATE              := TRUNC(SYSDATE);
	gn_prior_month           NUMBER            := TO_NUMBER(TO_CHAR(ADD_MONTHS(TRUNC(gd_sysdate, 'MM'), -1),'YYYYMM'));
	gn_current_month         NUMBER            := TO_NUMBER(TO_CHAR(gd_sysdate,'YYYYMM'));
	gn_sysdt_batchid         NUMBER            := TO_NUMBER(TO_CHAR(gd_sysdate,'YYYYMMDD'));
	gc_main_loadedby         VARCHAR2(100 CHAR):='PKG_GRP_LOAD_RPT_FCT_RPT_CLAIM_SUMMARY_R.MAIN'      ;
	gc_updby                 VARCHAR2(100 CHAR):='PKG_GRP_LOAD_RPT_FCT_RPT_CLAIM_SUMMARY_R.PRC_UPD_DEL_DATA';
	gc_getcur_loadedby       VARCHAR2(100 CHAR):='PKG_GRP_LOAD_RPT_FCT_RPT_CLAIM_SUMMARY_R.PRC_GET_CUR_DATA';
	gc_truncpartby           VARCHAR2(100 CHAR):='PKG_GRP_LOAD_RPT_FCT_RPT_CLAIM_SUMMARY_R.PRC_TRUNC_PARTITION';
	gc_rebuildindexes           VARCHAR2(100 CHAR):='PKG_GRP_LOAD_RPT_FCT_RPT_CLAIM_SUMMARY_R.PRC_REBUILD_INDEXES';
	gc_trcmsg                CLOB              :='Trace Message:->';
	gc_job_name              VARCHAR2(50 CHAR) :='GRP_LOAD_RPT_FCT_RPT_CLAIM_SUMMARY_R';
	gn_bulk_coll_cnt         NUMBER            :=10000;
	gc_running_status        VARCHAR2(30)      :='Running';
	gc_error_status          VARCHAR2(30)      :='Error';
	gc_success_status        VARCHAR2(30)      :='Success';
	gc_source                VARCHAR2(30)      :='EDW';
	gc_target                VARCHAR2(30)      :='RPT';
	gc_main_entity			 VARCHAR2(30)      :='CLAIM_SUMMARY';
	--Global Variables
	gn_out_job_id            NUMBER;
	gc_errmsg                VARCHAR2(4000 CHAR);
	gd_pacs_as_of_date_r     DATE;--09-feb-2024 changes

	/*START: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
	gc_message_type_r 	PRCS_JOB_LOG_MESSAGE_R.v_message_type_r%TYPE    := PKG_GRP_LOG_UTIL.gc_message_type_info;
	gc_count_type_r 	PRCS_JOB_LOG_MESSAGE_R.v_count_type_r%TYPE      := PKG_GRP_LOG_UTIL.gc_count_type_insert;
	gc_duration_r       PRCS_JOB_LOG_MESSAGE_R.T_DURATION_R%TYPE 		:=0;
	gn_run_cnt          PRCS_JOB_LOG_MESSAGE_R.N_COUNT_R%TYPE 	 		:=0;
	gn_loop_counter_r   PRCS_JOB_LOG_MESSAGE_R.N_COUNT_R%TYPE 			:=0;
	gt_start_time_r 	TIMESTAMP;
	gt_end_time_r 		TIMESTAMP;
	gn_job_log_message_id_r  NUMBER;
	gn_error_line VARCHAR2(20);
	gc_rpt_table_name      	VARCHAR2(30)      	:='RPT_FCT_RPT_CLAIM_SUMMARY_R';
	gc_rebuild_idx_degree	PLS_INTEGER      	:=8;
	gd_fic_mis_date          DATE;--29-Aug-2024 changes
	/*END: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/

	--Function to get Pacs as of date
	FUNCTION get_pacs_as_of_date_r
	RETURN DATE
	IS
		ld_date DATE;
	BEGIN
		select to_date(to_char(D_EDS_CYCLEDATE_R,'dd-mon-yyyy')) INTO ld_date
		from PRCS_GRP_DATE_PARAM_R
		where V_PROCESS_NAME_R ='PACS_BATCH_ID';
		RETURN ld_date;
	EXCEPTION
		WHEN OTHERS THEN
		RETURN NULL;
	END get_pacs_as_of_date_r
	;
	--Function to get n_avg_claim_decission_days_r
	FUNCTION get_n_avg_claim_decision_days_r(p_n_claim_sk_r IN NUMBER
									   ,p_n_claim_coverage_sk_r IN NUMBER
									   ,p_n_claim_coverage_group_sk_r IN NUMBER
									   ,p_d_claim_decision_date_r IN DATE
									   ,p_v_claim_decision_ind_r IN VARCHAR2
									   ,p_n_yearmonth_r IN NUMBER
									   )
	RETURN NUMBER
	IS
		ln_num NUMBER;
	BEGIN

		SELECT
		(CASE
		 WHEN NVL(p_v_claim_decision_ind_r,'X@') ='Y'
		 THEN (p_d_claim_decision_date_r-RPT_CLAIM_DTL_R.D_CLAIM_RECEIVED_DATE_R)
		 ELSE
		 0
		END
		) into ln_num
		FROM RPT_CLAIM_DTL_R
		WHERE n_claim_sk_r=p_n_claim_sk_r
		  AND n_claim_coverage_sk_r=p_n_claim_coverage_sk_r
		  AND n_claim_coverage_group_sk_r=p_n_claim_coverage_group_sk_r
		  AND n_yearmonth_r=p_n_yearmonth_r;

		RETURN ln_num;
	EXCEPTION
		WHEN OTHERS THEN
		RETURN NULL;
	END get_n_avg_claim_decision_days_r
	;

	--Function to get n_claim_approach_dur_r
	FUNCTION get_n_claim_approach_dur_r(p_n_claim_sk_r IN NUMBER
									   ,p_n_claim_coverage_sk_r IN NUMBER
									   ,p_n_claim_coverage_group_sk_r IN NUMBER
									   ,p_v_claim_activity_detail_r IN VARCHAR2
									   ,p_d_pacs_as_of_date_r   IN DATE
									   ,p_n_yearmonth_r IN NUMBER
									   )
	RETURN NUMBER
	IS
		ln_num NUMBER;
	BEGIN
		SELECT
		--(CASE WHEN (NVL(p_d_pacs_as_of_date_r,gd_pacs_as_of_date_r)- RPT_CLAIM_DTL_R.D_PLAN_DUR_DATE_R)<=180  AND--24-Feb-2024 changes
		(CASE WHEN (RPT_CLAIM_DTL_R.D_PLAN_DUR_DATE_R-NVL(p_d_pacs_as_of_date_r,gd_pacs_as_of_date_r) )<=180  AND--24-Feb-2024 changes
		RPT_CLAIM_DTL_R.V_CLAIM_STATUS_CODE_R < '60' AND
		NVL(P_V_CLAIM_ACTIVITY_DETAIL_R,'X@') <>'Resisted'
		THEN 1 ELSE 0 END) into ln_num
		FROM RPT_CLAIM_DTL_R
		WHERE n_claim_sk_r=p_n_claim_sk_r
		  AND n_claim_coverage_sk_r=p_n_claim_coverage_sk_r
		  AND n_claim_coverage_group_sk_r=p_n_claim_coverage_group_sk_r
		  AND n_yearmonth_r=p_n_yearmonth_r;
		RETURN NVL(ln_num,0);
	EXCEPTION
		WHEN OTHERS THEN
		RETURN NULL;
	END get_n_claim_approach_dur_r
	;
	--Function to get n_claim_approach_exp_resolution_r
	FUNCTION get_n_claim_approach_exp_resolution_r(p_n_claim_sk_r IN NUMBER
									   ,p_n_claim_coverage_sk_r IN NUMBER
									   ,p_n_claim_coverage_group_sk_r IN NUMBER
									   ,p_d_potential_resolution_date_r IN DATE
									   ,p_v_claim_activity_detail_r IN VARCHAR2
									   ,p_d_pacs_as_of_date_r   IN DATE
									   ,p_n_yearmonth_r IN NUMBER
									   )
	RETURN NUMBER
	IS
		ln_num NUMBER;
	BEGIN
		SELECT
		--(CASE WHEN (NVL(p_d_pacs_as_of_date_r,gd_pacs_as_of_date_r)- P_D_POTENTIAL_RESOLUTION_DATE_R)<=180  AND --24-Feb-2024 changes
		(CASE WHEN (P_D_POTENTIAL_RESOLUTION_DATE_R - NVL(p_d_pacs_as_of_date_r,gd_pacs_as_of_date_r) )<=180  AND--24-Feb-2024 changes
		RPT_CLAIM_DTL_R.V_CLAIM_STATUS_CODE_R< '60'  AND
		NVL(P_V_CLAIM_ACTIVITY_DETAIL_R,'X@') NOT IN ('Resisted', 'Pending')
		THEN 1 ELSE 0 END) into ln_num
		FROM RPT_CLAIM_DTL_R
		WHERE n_claim_sk_r=p_n_claim_sk_r
		  AND n_claim_coverage_sk_r=p_n_claim_coverage_sk_r
		  AND n_claim_coverage_group_sk_r=p_n_claim_coverage_group_sk_r
		  AND n_yearmonth_r=p_n_yearmonth_r;
		RETURN NVL(ln_num,0);
	EXCEPTION
		WHEN OTHERS THEN
		RETURN NULL;
	END get_n_claim_approach_exp_resolution_r
	;
	--Function to get n_duration_remaining_r
	FUNCTION get_n_duration_remaining_r(p_n_claim_sk_r IN NUMBER
									   ,p_n_claim_coverage_sk_r IN NUMBER
									   ,p_n_claim_coverage_group_sk_r IN NUMBER
									   ,p_d_pacs_as_of_date_r   IN DATE
									   ,p_n_yearmonth_r IN NUMBER
									   )
	RETURN NUMBER
	IS
		ld_date DATE;
	BEGIN
		SELECT MAX(d_plan_dur_date_r) INTO ld_date
		FROM RPT_CLAIM_DTL_R
		WHERE n_claim_sk_r=p_n_claim_sk_r
		  AND n_claim_coverage_sk_r=p_n_claim_coverage_sk_r
		  AND n_claim_coverage_group_sk_r=p_n_claim_coverage_group_sk_r
		  AND n_yearmonth_r=p_n_yearmonth_r;
		RETURN NVL((ld_date-NVL(p_d_pacs_as_of_date_r,gd_pacs_as_of_date_r)),0);
	EXCEPTION
		WHEN OTHERS THEN
		RETURN NULL;
	END get_n_duration_remaining_r
	;
	--Main procedures calls other procedure to load data in RPT_CLEINT_DTL_R
	PROCEDURE main
	IS
		VAR_REF_CUR SYS_REFCURSOR;
		TYPE var_tbl_type IS TABLE OF RPT_FCT_RPT_CLAIM_SUMMARY_R%ROWTYPE INDEX BY BINARY_INTEGER;
		lt_var_tbl_typ var_tbl_type;
		ln_rec_cnt NUMBER:=0;
		--14-Jan-2024 changes starts
		ln_start_time NUMBER:=0;
		CURSOR cur_upd_claim_attr
		IS
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
		TYPE var_upd_claim_attr_tbl_type IS TABLE OF cur_upd_claim_attr%ROWTYPE INDEX BY BINARY_INTEGER;
		lt_upd_claim_attr_tbl_typ var_upd_claim_attr_tbl_type;
		--14-Jan-2024 changes ends
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

		/*START: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
		 gc_trcmsg:='1. Entered into main. '||'gn_current_month:->'||gn_current_month|| ' - gn_prior_month:->'||gn_prior_month;
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
		/*END: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/

		gc_trcmsg:='2. get gd_pacs_as_of_date_r '||chr(13);

		/*START: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
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
		/*END: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/

		gd_pacs_as_of_date_r:=PKG_GRP_LOAD_RPT_FCT_RPT_CLAIM_SUMMARY_R.get_pacs_as_of_date_r;
		gc_trcmsg:='2.z get gd_pacs_as_of_date_r completed '||gd_pacs_as_of_date_r||chr(13);

		/*START: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
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
		/*END: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
		gc_trcmsg:='3. Call procedure prc_upd_del_data from main'||chr(13);
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
		gc_trcmsg:='5. Call prc_get_cur_data to get ref_cursor '||chr(13);
		PKG_GRP_LOAD_RPT_FCT_RPT_CLAIM_SUMMARY_R.prc_get_cur_data (var_ref_cur);

		ln_start_time:=dbms_utility.get_time;--22-Feb-2024 changes
		gc_trcmsg:='6 data load starts '||chr(13);
		gt_start_time_r:= SYSTIMESTAMP;

		/*START: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
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
		/*END: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/

		gn_loop_counter_r := 1; -- Initialize loop counter
		gc_count_type_r:=PKG_GRP_LOG_UTIL.gc_count_type_insert;

		ln_rec_cnt:=0;
		LOOP
			lt_var_tbl_typ.DELETE;
			FETCH var_ref_cur BULK COLLECT INTO  lt_var_tbl_typ LIMIT gn_bulk_coll_cnt;

			gt_start_time_r := SYSTIMESTAMP; -- Start timing before the insert

			 FORALL X in LT_VAR_TBL_TYP.first..LT_VAR_TBL_TYP.last
			 INSERT /*+APPEND_VALUES*/ INTO RPT_FCT_RPT_CLAIM_SUMMARY_R VALUES lt_var_tbl_typ(x) ;
			 LN_REC_CNT:=LN_REC_CNT+LT_VAR_TBL_TYP.COUNT;
			commit;

			gt_end_time_r := SYSTIMESTAMP; -- End timing after the insert
			gc_trcmsg := '6.1 data load: Bulk Set-'|| gn_loop_counter_r ||': '||LN_REC_CNT||' records loaded' ;
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

		ln_start_time:=dbms_utility.get_time;--22-Feb-2024 changes
		gc_trcmsg:='6.2 Data Loaded '||ln_rec_cnt||' records '||chr(13);

		/*START: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
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
		/*END: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/


		gc_trcmsg:='6.2.1 Target count for Audit control Process';

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

		gc_trcmsg:='6.3 Merge into RPT_FCT_RPT_CLAIM_SUMMARY_R table from main '||chr(13);
		gt_start_time_r:= SYSTIMESTAMP;
		/*START: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
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
		/*END: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/

		MERGE /*+PARALLEL(4)*/ INTO rpt_fct_rpt_claim_summary_r TAB1
			USING (SELECT /*+PARALLEL(4)*/ V_CLAIM_IDENTIFIER_R, max(a.n_claim_sk_r) n_claim_sk_r , max(B.N_PRODUCT_SK_R) N_PRODUCT_SK_R, MAX(B.N_cuST_PARTY_SK_R) N_PARTY_SK_R, MAX(B.N_POLICY_SK_R) N_POLICY_SK_R,
			MAX(B.N_INSRD_PARTY_SK_R)N_INSRD_PARTY_SK_R, MAX(B.N_EMPLOYEE_SK_R) N_EMPLOYEE_SK_R,MAX(B.N_ORIGINAL_FACE_AMOUNT_R) N_ORIGINAL_FACE_AMOUNT_R
			from rpt_claim_dtl_r a, rpt_claim_sum_r b
		where a.n_claim_sk_r = b.n_claim_sk_r
		and a.n_claim_coverage_sk_r = b.n_claim_coverage_sk_r
		and a.n_claim_coverage_group_sk_r = b.n_claim_coverage_group_sk_r
		and a.n_yearmonth_r=gn_current_month--Added by Gireesh on 18-Jan-2024
		and b.n_yearmonth_r=gn_current_month--Added by Gireesh on 18-Jan-2024
		group by V_CLAIM_IDENTIFIER_R) TAB2
			ON (TAB1.V_CLAIM_IDENTIFIER_R = TAB2.V_CLAIM_IDENTIFIER_R)
		  WHEN MATCHED THEN
			UPDATE SET TAB1.n_claim_sk_r = TAB2.n_claim_sk_r,
			TAB1.N_PRODUCT_SK_R = TAB2.N_PRODUCT_SK_R,
			TAB1.N_PARTY_SK_R = TAB2.N_PARTY_SK_R,
			TAB1.N_POLICY_SK_R = TAB2.N_POLICY_SK_R,
			TAB1.N_INSRD_PARTY_SK_R = TAB2.N_INSRD_PARTY_SK_R,
			TAB1.N_EMPLOYEE_SK_R = TAB2.N_EMPLOYEE_SK_R,
			--02/09/24 Changes start
			TAB1.N_ORIGINAL_FACE_AMOUNT_R = TAB2.N_ORIGINAL_FACE_AMOUNT_R
			--02/09/24 Changes End
			 WHERE
				--TAB1.D_CYCLE_DATE_R = (SELECT /*+PARALLEL(4)*/ MAX(D_CYCLE_DATE_R) FROM rpt_fct_rpt_claim_summary_r_tmp) ;
				 TO_CHAR(TAB1.D_CYCLE_DATE_R,'YYYYMM')=GN_CURRENT_MONTH;

			gn_run_cnt:= SQL%ROWCOUNT;
			COMMIT;

		GC_TRCMSG:='6.4 Merge into RPT_FCT_RPT_CLAIM_SUMMARY_R table from main completed';
		--14-Jan-2024 changes starts
		ln_start_time:=dbms_utility.get_time;--22-Feb-2024 changes

		gc_count_type_r:=PKG_GRP_LOG_UTIL.gc_count_type_merge;

		/*START: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
		gt_end_time_r:= SYSTIMESTAMP;

		 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
		 (
			p_job_id_r                    => gn_out_job_id,
			p_batch_id_r                  => gn_sysdt_batchid,
			p_message_type_r              => gc_message_type_r,
			p_code_location_r             => gc_main_loadedby,
			p_message_r                   => gc_trcmsg,
			p_count_type_r                => gc_count_type_r,
			p_count_r                     => gn_run_cnt,
			p_duration_r                  => FNC_GRP_TIME_DURATION(gt_start_time_r,gt_end_time_r),
			p_created_by_r                => GC_JOB_NAME,
			out_prcs_job_log_message_id_r => gn_job_log_message_id_r
		);
		/*END: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/

		gc_trcmsg:='6.5 Update Claim Attributes from main ';

			gt_start_time_r:= SYSTIMESTAMP;
		/*START: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
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
		/*END: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/

		gn_loop_counter_r := 1; -- Initialize loop counter
		gc_count_type_r:=PKG_GRP_LOG_UTIL.gc_count_type_update;

		ln_rec_cnt:=0;

		OPEN  cur_upd_claim_attr ;
			LOOP
				lt_upd_claim_attr_tbl_typ.DELETE;
				FETCH cur_upd_claim_attr bulk collect into  lt_upd_claim_attr_tbl_typ limit GN_BULK_COLL_CNT;

				gt_start_time_r := SYSTIMESTAMP; -- Start timing before the update

				FORALL X in lt_upd_claim_attr_tbl_typ.first..lt_upd_claim_attr_tbl_typ.last
				UPDATE RPT_FCT_RPT_CLAIM_SUMMARY_R
				  set n_avg_claim_decision_days_r     =lt_upd_claim_attr_tbl_typ(X).n_avg_claim_decision_days_r
				  , n_claim_approach_dur_r           =lt_upd_claim_attr_tbl_typ(X).n_claim_approach_dur_r
				  , n_claim_approach_exp_resolution_r=lt_upd_claim_attr_tbl_typ(X).n_claim_approach_exp_resolution_r
				  , n_duration_remaining_r           =lt_upd_claim_attr_tbl_typ(X).n_duration_remaining_r
				where rowid=lt_upd_claim_attr_tbl_typ(X).row_id;

				LN_REC_CNT:=LN_REC_CNT+LT_VAR_TBL_TYP.COUNT;
				 commit;
				 /* Start - New logging changes*/
				gt_end_time_r := SYSTIMESTAMP; -- End timing after the insert
				gc_trcmsg := '6.6 data update: Bulk Set-'|| gn_loop_counter_r ||': '||LN_REC_CNT||' records Updated' ;
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

				 /* End - New logging changes*/

				 EXIT WHEN cur_upd_claim_attr%NOTFOUND;
			END LOOP;

		CLOSE cur_upd_claim_attr;

		gc_trcmsg:='7. Update Claim Attributes completed from main ';

		/*START: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
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
		/*END: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/

		--14-Jan-2024 changes ends
		--22-Feb-2024 changes starts
		ln_start_time:=dbms_utility.get_time;
		gc_trcmsg:='8. Rebuild Local Index prc_rebuild_index_partitions from Common Util for Partition: '||gn_current_month;

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

		--PKG_GRP_LOAD_RPT_FCT_RPT_CLAIM_SUMMARY_R.prc_rebuild_indexes; -- 8th Aug: Removed Global Index Rebuild


		--8th Aug: Added Local Index Rebuild
		PKG_GRP_COMMON_UTIL.prc_rebuild_index_partitions
		(
			p_table_name   		  		  => 'RPT_FCT_RPT_CLAIM_SUMMARY_R',
			p_parallel_degree   		  => 8,
			p_partition_name  		  	  => 'PART_RPT_FCT_RPT_CLAIM_SUMMARY_R_'||gn_current_month,
			p_out_job_id              	  => gn_out_job_id,
			p_Log_seq_num             	  => 8
		);

		gc_trcmsg:='8.z Completed Rebuild Local Index prc_rebuild_index_partitions from Common Util for Partition: '||gn_current_month;

		/*START: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
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
		/*END: 20-MAY-2025: NEW LOGGING MECHANISM CHANGES*/

		--12-Apr-2024 changes starts
		ln_start_time:=dbms_utility.get_time;
		gc_trcmsg:='9. Execute Merge1 from main starts ';
		gt_start_time_r:= SYSTIMESTAMP;
		/*START: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
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
		/*END: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/

		MERGE /*+PARALLEL(4)*/ INTO rpt_fct_rpt_claim_summary_r TAB1
			USING (SELECT /*+PARALLEL(4)*/ V_CLAIM_IDENTIFIER_R, max(a.n_claim_sk_r) n_claim_sk_r , max(B.N_PRODUCT_SK_R) N_PRODUCT_SK_R, MAX(B.N_cuST_PARTY_SK_R) N_PARTY_SK_R, MAX(B.N_POLICY_SK_R) N_POLICY_SK_R,
			MAX(B.N_INSRD_PARTY_SK_R)N_INSRD_PARTY_SK_R, MAX(B.N_EMPLOYEE_SK_R) N_EMPLOYEE_SK_R, max(a.n_claim_coverage_sk_r)n_claim_coverage_sk_r,max(a.n_claim_coverage_group_sk_r)n_claim_coverage_group_sk_r
			from rpt_claim_dtl_r a, rpt_claim_sum_r b
		where
			a.n_yearmonth_r=gn_current_month
		and b.n_yearmonth_r=gn_current_month
		and a.n_claim_coverage_group_sk_r = b.n_claim_coverage_group_sk_r
		and a.n_claim_coverage_sk_r = b.n_claim_coverage_sk_r
		and a.n_claim_sk_r = b.n_claim_sk_r
		group by V_CLAIM_IDENTIFIER_R) TAB2
			ON (substr(TAB1.V_CLAIM_IDENTIFIER_R,0,length(TAB1.V_CLAIM_IDENTIFIER_R)-3) = TAB2.V_CLAIM_IDENTIFIER_R)
		  WHEN MATCHED THEN
			UPDATE SET TAB1.n_claim_sk_r = TAB2.n_claim_sk_r,
			TAB1.N_PRODUCT_SK_R = TAB2.N_PRODUCT_SK_R,
			TAB1.N_PARTY_SK_R = TAB2.N_PARTY_SK_R,
			TAB1.N_POLICY_SK_R = TAB2.N_POLICY_SK_R,
			TAB1.N_INSRD_PARTY_SK_R = TAB2.N_INSRD_PARTY_SK_R,
			TAB1.N_EMPLOYEE_SK_R = TAB2.N_EMPLOYEE_SK_R,
			TAB1.n_claim_coverage_sk_r = TAB2.n_claim_coverage_sk_r,
			TAB1.n_claim_coverage_group_sk_r =TAB2.n_claim_coverage_group_sk_r
			where tab1.n_yearmonth_r=gn_current_month
			and tab1.V_COVERAGE_GROUP_ID_R = 'DF';

		gn_run_cnt:= SQL%ROWCOUNT;
		commit;

		gc_trcmsg:='9.z  Execution of Merge1 from main completed ';
		gc_count_type_r:=PKG_GRP_LOG_UTIL.gc_count_type_merge;

		/*START: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
		gt_end_time_r:= SYSTIMESTAMP;

		 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
		 (
			p_job_id_r                    => gn_out_job_id,
			p_batch_id_r                  => gn_sysdt_batchid,
			p_message_type_r              => gc_message_type_r,
			p_code_location_r             => gc_main_loadedby,
			p_message_r                   => gc_trcmsg,
			p_count_type_r                => gc_count_type_r,
			p_count_r                     => gn_run_cnt,
			p_duration_r                  => FNC_GRP_TIME_DURATION(gt_start_time_r,gt_end_time_r),
			p_created_by_r                => GC_JOB_NAME,
			out_prcs_job_log_message_id_r => gn_job_log_message_id_r
		);
		/*END: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/

		gc_trcmsg:='10. Execute Merge2 from main starts ';
		gt_start_time_r:= SYSTIMESTAMP;
		/*START: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
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
		/*END: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/

		MERGE /*+PARALLEL(4)*/ INTO rpt_fct_rpt_claim_summary_r TAB1
		USING (select n_claim_coverage_group_sk_r from (select
			   case when N_CLAIM_CVRG_GRP_SRC_SYS_KEY_R is null
			   then
			   case when
			   rank() over(partition by n_claim_sk_r order by nvl(N_CLAIM_CVRG_GRP_SRC_SYS_KEY_R,0) desc) = 1
			   then 1
			   else 0 end
			   else 1 end DF_CVG, c.v_claim_number_r, c.v_claim_identifier_r, c.N_CLAIM_CVRG_GRP_SRC_SYS_KEY_R, c.n_claim_coverage_group_sk_r
			   from  atomic.DIM_GRP_CLAIM_COVERAGE_GROUP_R c
			   where V_ACTIVE_STATUS_R = 'Y') where DF_CVG = 0) TAB2
		ON (TAB1.n_claim_coverage_group_sk_r = TAB2.n_claim_coverage_group_sk_r)
		WHEN MATCHED THEN
		UPDATE SET TAB1.n_claim_sk_r = -1,
				  TAB1.n_claim_coverage_sk_r = -1
		where tab1.n_yearmonth_r=gn_current_month
		and tab1.V_COVERAGE_GROUP_ID_R = 'DF';

		gn_run_cnt:= SQL%ROWCOUNT;
		commit;

		gc_trcmsg:='10.1  Execution of Merge2 from main completed ';
		--12-Apr-2024 change ends

		gc_count_type_r:=PKG_GRP_LOG_UTIL.gc_count_type_merge;

		/*START: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
		gt_end_time_r:= SYSTIMESTAMP;

		 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
		 (
			p_job_id_r                    => gn_out_job_id,
			p_batch_id_r                  => gn_sysdt_batchid,
			p_message_type_r              => gc_message_type_r,
			p_code_location_r             => gc_main_loadedby,
			p_message_r                   => gc_trcmsg,
			p_count_type_r                => gc_count_type_r,
			p_count_r                     => gn_run_cnt,
			p_duration_r                  => FNC_GRP_TIME_DURATION(gt_start_time_r,gt_end_time_r),
			p_created_by_r                => GC_JOB_NAME,
			out_prcs_job_log_message_id_r => gn_job_log_message_id_r
		);
		/*END: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/

	gc_trcmsg:='11. Calling Audit Control Procedure';

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

	PRC_GRP_AUDIT_CONTROL_PROCESS(gc_source,gc_main_entity,gc_source, gc_target);

	 --01-Feb-2024 changes
		gc_trcmsg:='1.z Exit from main'||chr(13);

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
		/*START: 20-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
			pkg_grp_log_util.prc_update_log_message_r
		(
			n_prcs_job_log_message_id_r => gn_job_log_message_id_r,
			p_err_msg => gc_trcmsg
		);
		/*END: 20-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
		pkg_grp_log_util.prc_update_log
		  (
			gn_out_job_id                   --p_job_id
			,gc_error_status                --p_job_status
			,gc_errmsg                       --p_err_msg
			,gc_trcmsg||chr(13)||gc_errmsg  --p_trc_msg
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
		   gc_trcmsg:='5 Entered into prc_get_cur_data '||chr(13);

		   /*START: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
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
			/*END: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/

		   --Open/Assign SELECT stmnt
			open P_OUT_CURSOR for
			select
			 a.N_CLAIM_SK_R
			,a.N_PRODUCT_SK_R
			,a.N_PARTY_SK_R

			,a.N_POLICY_SK_R
			,a.N_NO_OF_PAYMENTS_R
			,a.N_NO_OF_CHECKS_R
			,a.N_NO_OF_VOID_PAYMENTS_R
			,a.N_NO_OF_VOID_CHECKS_R
			,a.N_TOTAL_CLAIM_COUNT_R
			,a.N_CHG_TOTAL_CLAIM_COUNT_R
			,a.N_REOPEN_CLAIM_COUNT_R
			,a.N_CHG_REOPEN_CLAIM_COUNT_R
			,a.N_PENDING_CLAIM_COUNT_R
			,a.N_CHG_PENDING_CLAIM_COUNT_R
			,a.N_APPROVED_CLAIM_COUNT_R
			,a.N_CHG_APPROVED_CLAIM_COUNT_R
			,a.N_CLOSED_CLAIM_COUNT_R
			,a.N_CHG_CLOSED_CLAIM_COUNT_R
			,a.N_GAAP_OS_RESERVE_COUNT_R
			,a.N_CHG_GAAP_OS_RESERVE_COUNT_R
			,a.N_GAAP_WV_RESERVE_COUNT_R
			,a.N_CHG_GAAP_WV_RESERVE_COUNT_R
			,a.N_STAT_OS_RESERVE_COUNT_R
			,a.N_CHG_STAT_OS_RESERVE_COUNT_R
			,a.N_STAT_WV_RESERVE_COUNT_R
			,a.N_CHG_STAT_WV_RESERVE_COUNT_R
			,a.N_PAYMENT_DIRECT_AMT_R
			,a.N_LOSS_PAYMENT_DIRECT_AMT_R
			,a.N_WAGE_BASE_R
			,a.N_TAXABLE_BENEFITS_R
			,a.N_NON_TAXABLE_BENEFITS_R
			,a.N_FIT_R
			,a.N_SIT_R
			,a.N_FICA_R
			,a.N_MEDICARE_TAX_R
			,a.N_FICA_WAGE_BASE_R
			,a.N_MEDICARE_WAGE_BASE_R
			,a.N_EMPLOYER_FICA_R
			,a.N_EMPLOYER_MEDICARE_TAX_R
			,a.N_EMP_FICA_WAGE_BASE_R
			,a.N_EMP_MEDICARE_WAGE_BASE_R
			,a.N_FUTA_R
			,a.N_PAYMENT_TAXABLE_BENEFITS_R
			,a.N_PAYMENT_NONTAXABLE_BEN_R
			,a.N_PRIOR_GAAP_RESERVE_DIRECT_R
			,a.N_CHG_GAAP_OS_DIRECT_AMT_R
			,a.N_CURR_GAAP_RESERVE_DIRECT_R
			,a.N_PRIOR_STAT_RESERVE_DIRECT_R
			,a.N_CHG_STAT_OS_DIRECT_AMT_R
			,a.N_CURR_STAT_RESERVE_DIRECT_R
			,a.N_PRIOR_GAAP_WV_DIRECT_AMT_R
			,a.N_CHG_GAAP_WV_DIRECT_AMT_R
			,a.N_CURR_GAAP_WV_DIRECT_AMT_R
			,a.N_PRIOR_STAT_WV_DIRECT_AMT_R
			,a.N_CHG_STAT_WV_DIRECT_AMT_R
			,a.N_CURR_STAT_WV_DIRECT_AMT_R
			,a.N_PRIOR_BE_DIRECT_AMT_R
			,a.N_CHG_BE_RESERVE_DIRECT_AMT_R
			,a.N_CURR_BE_RESERVE_DIRECT_AMT_R
			,a.N_PRIOR_FIELD_RES_DIRECT_AMT_R
			,a.N_CHG_FIELD_RES_DIRECT_AMT_R
			,a.N_CURR_FIELD_RES_DIRECT_AMT_R
			,a.N_CHG_BE_RESERVE_CEDED_AMT_R
			,a.N_CHG_BE_RESERVE_NET_AMT_R
			,a.N_CHG_FIELD_RES_NET_AMT_R
			,a.N_CURR_BE_RESERVE_CEDED_AMT_R
			,a.N_CURR_BE_RESERVE_NET_AMT_R
			,a.N_CURR_FIELD_RES_CEDED_AMT_R
			,a.N_CURR_FIELD_RES_NET_AMT_R
			,a.N_INIT_CLM_DECISION_DAYS_R
			,a.N_INIT_AVG_CLM_DECISION_DAYS_R
			,a.V_CLAIM_DECISION_IND_R
			,a.D_CLAIM_DECISION_DATE_R
			,a.D_FIRST_PAYMENT_FROM_DATE_R
			,a.D_LAST_PAYMENT_TO_DATE_R
			,a.D_FIRST_PAYMENT_DATE_R
			,a.D_LAST_PAYMENT_DATE_R
			,a.N_NEW_CLAIM_RECEIPTS_R
			,a.N_DENIED_CLAIMS_R
			,a.N_NEW_APPEAL_RECEIPTS_R
			,a.N_CLAIMS_SETTLED_R
			,a.N_CLAIMS_WITH_OVERPAYMENTS_R
			,a.N_CLAIMS_BRIDGED_STD_TO_LTD_R
			,a.N_CLMS_W_CLINICAL_ENGAGEMENT_R
			,a.N_LTD_APPROVED_CLMS_OWN_OCC_R
			,a.N_LTD_APPRVED_OWNOCC_FULLDUR_R
			,a.N_LTD_APPROVED_CLMS_ANY_OCC_R
			,a.V_LTD_ANY_OCC_GROUP_R
			,a.N_LTD_APPROVED_PAS_CLAIMS_R
			,a.V_SS_PURSUE_INDICATED_R
			,a.N_CLAIMS_REFERRED_SS_VENDOR_R
			,a.N_PRIMARY_SS_AWARDS_COUNTS_R
			,a.N_PRIMARY_SS_AWARDS_TOTAL_R
			,a.N_DEPENDENT_SS_AWARDS_COUNTS_R
			,a.N_DEPENDENT_SS_AWARDS_TOTAL_R
			,a.N_SETTLEMENTS_OFFERED_R
			,a.N_SETTLEMENT_OFFERS_DECLINED_R
			,a.N_OVERPAYMENT_BALANCE_R
			,a.N_OVERPAYMENTS_RECOVERED_R
			,a.N_INITIAL_CLOSURE_R
			,a.V_PAID_AND_CLOSED_R
			,a.D_DECISION_MADE_DATE_R
			,a.N_AGED_PENDING_CLAIMS_R
			,a.N_AVG_TASKS_COMPLETED_DAY_R
			,a.N_CLAIM_TOUCHES_PER_DAY_R
			,a.N_AVG_TASK_AGING_R
			,a.N_PRODUCTION_BALANCE_RATIO_R
			,a.N_NO_OF_EXTENSIONS_PER_CLAIM_R
			,a.N_AVG_DAYS_CLAIM_DECISION_R
			,a.N_AVG_DAYS_REC_CLM_DECISION_R
			,a.N_INITIAL_APPROVAL_RATE_R
			,a.N_APPROVAL_RATE_BY_PLAN_EP_R
			,a.N_INITIAL_CLOSURE_RATE_R
			,a.N_CLOSURE_RATE_R
			,a.N_CLOSURE_RATE_OWNOCC_PERIOD_R
			,a.N_CLOSURE_RATE_ANYOCC_PERIOD_R
			,a.N_REOPEN_RATE_R
			,a.N_APPEAL_RATE_R
			,a.N_ANY_OCC_APPROVAL_RATE_R
			,a.N_PAS_ACCEPTANCE_RATE_STAT35_R
			,a.N_ACTUAL_DURATION_R
			,a.N_DURATION_BY_PLAN_EP_R
			,a.N_AVG_PAYMENT_AMT_R
			,a.N_AVG_CASELOADS_R
			,a.N_ACTUAL_TO_EXPECTED_R
			,a.N_LTD_CLAIM_SETTLEMENT_RATE_R
			,a.N_OVERPAYMENT_RECOV_SUCCESS_R
			,a.N_SS_VENDOR_PLACEMENT_RATE_R
			,a.N_SS_VENDOR_AWARD_RATE_R
			,a.N_SS_CLAIMS_BY_APPEAL_LEVEL_R
			,a.N_SSCOMPASSIONALLOW_APPRVALS_R
			,a.N_NONSS_REPRESENTED_CLAIMS_R
			,a.N_PENSION_ELIGIBLE_CLAIMS_R
			,a.N_PENSION_CLAIMS_NO_OFFSET_R
			,a.N_INIT_APPROVAL_RT_CLINICAL_R
			,a.N_INIT_APP_RT_WO_CLINICAL_R
			,a.N_CLOSURE_RATE_WITH_CLINICAL_R
			,a.N_CLOSURE_RATE_WO_CLINICAL_R
			,a.V_INITIAL_CLINICAL_INDICATOR_R
			,a.V_CURRENT_CLINICAL_INDICATOR_R
			,a.N_CLAIMS_RTW_W_INTERVENTION_R
			,a.N_CLAIMS_RTW_WO_INTERVENTION_R
			,a.N_PARTIAL_RTW_W_ACCOMODATION_R
			,a.N_PART_TIME_RTW_CLAIMS_R
			,a.N_NO_OF_VOCATIONAL_TOUCHES_R
			,CAST(NULL AS NUMBER) N__OF_CLINICAL_TOUCHES_R
			,a.N_SEGMENTATION_RESULTS_R
			,a.N_CLAIMS_REVIEWED_FOR_FWA_R
			,a.N_CLAIMS_IDENTIFIED_FOR_FWA_R
			,a.N_QUALITY_REVIEW_SCORE_R
			,a.V_ELIMINATION_PERIOD_GROUP_R
			,a.V_CLAIM_ACTIVITY_TYPE_R
			,a.V_CLAIM_ACTIVITY_GROUP_R
			,a.V_CLAIM_ACTIVITY_DETAIL_R
			,a.N_CLAIM_AGE_R
			,a.V_REINSURANCE_INDICATOR_R
			,a.N_ENTRY_ERROR_COUNT_R
			,a.N_NEW_CLAIM_ERROR_R
			,a.N_NEW_CLAIM_COUNT_ADJUSTED_R
			,a.N_ENTRY_ERROR_ADJUSTED_R
			,a.N_BATCH_ID_R
			,a.N_LOAD_RUN_ID_R
			,CAST(NULL AS NUMBER) N_SEQUENCE__R
			,systimestamp T_CREATION_DATE_R
			,a.T_EVENT_TIMESTAMP_R
			,systimestamp T_LAST_MODIFIED_DATE_R
			,gc_getcur_loadedby V_CREATED_BY_R
			,gc_getcur_loadedby V_LAST_MODIFIED_BY_R
			,a.FIC_MIS_DATE_R
			,a.V_SOURCE_SYSTEM_NAME_R
			,a.V_SUBJECT_AREA_TYPE_R
			,CAST(NULL AS NUMBER) N_VERSION__R
			,a.F_PHYSICAL_DELETE_R
			,a.V_CHANGE_REASON_R
			,a.D_CYCLE_DATE_R
			,a.N_QUOTE_SK_R
			,a.D_FIRST_OPEN_STATUS_EFF_DATE_R
			,a.V_DECISION_MADE_R
			,CAST(NULL AS VARCHAR2(100)) V_CLAIM__R
			,a.V_COVERAGE_CODE_R
			,a.V_POLICY_PREFIX_R
			,a.V_POLICY_SUFFIX_R
			,CAST(NULL AS NUMBER) N_CUSTOMER__R
			--17/09/24 changes start
			--,a.V_TIER_NUM_R
			--,a.V_TIER_DESCRIPTION_R
			,d.N_TIER_NUM_R AS V_TIER_NUM_R
			,d.V_TIER_DESCRIPTION_R
			--17/09/24 changes start
			,a.V_ACCOMMODATIONS_NEEDED_R
			,a.V_RECOVERY_EXPECTATIONS_R
			,a.V_WFAM_CODE_R
			--17/09/24 changes start
			-- ,a.D_POTENTIAL_RESOLUTION_DATE_R
			,d.D_PRD_R AS D_POTENTIAL_RESOLUTION_DATE_R
			--17/09/24 changes start
			,CAST(NULL AS VARCHAR2(100)) V_TAX__R
			,CAST(NULL AS VARCHAR2(100)) V_POLICY__R
			,a.V_REINLOSS001_USE_R
			,a.V_PRODUCT_SUB_LINE_CODE_R
			,a.N_CHG_ACT_OS_CEDED_AMT_R
			,a.N_CHG_ACT_OS_NET_AMT_R
			,a.N_CHG_FIELD_OS_CEDED_AMT_R
			,a.N_CHG_FIELD_OS_NET_AMT_R
			,a.N_CHG_GAAP_OS_CEDED_AMT_R
			,a.N_CHG_GAAP_OS_NET_AMT_R
			,a.N_CHG_GAAP_WV_CEDED_AMT_R
			,a.N_CHG_GAAP_WV_NET_AMT_R
			,a.N_CHG_STAT_OS_CEDED_AMT_R
			,a.N_CHG_STAT_OS_NET_AMT_R
			,a.N_CHG_STAT_WV_CEDED_AMT_R
			,a.N_CHG_STAT_WV_NET_AMT_R
			,a.N_CURR_ACT_OS_CEDED_AMT_R
			,a.N_CURR_ACT_OS_NET_AMT_R
			,a.N_CURR_FIELD_OS_CEDED_AMT_R
			,a.N_CURR_FIELD_OS_NET_AMT_R
			,a.N_CURR_GAAP_OS_CEDED_AMT_R
			,a.N_CURR_GAAP_OS_NET_AMT_R
			,a.N_CURR_GAAP_WV_CEDED_AMT_R
			,a.N_CURR_GAAP_WV_NET_AMT_R
			,a.N_CURR_STAT_OS_CEDED_AMT_R
			,a.N_CURR_STAT_OS_NET_AMT_R
			,a.N_CURR_STAT_WV_CEDED_AMT_R
			,a.N_CURR_STAT_WV_NET_AMT_R
			,a.N_LOSS_PAYMENT_CEDED_AMT_R
			,a.N_LOSS_PAYMENT_NET_AMT_R
			,a.N_PAYMENT_CEDED_AMT_R
			,a.N_PAYMENT_NET_AMT_R
			,a.N_PRIMARY_REINS_LOSS_PCT_R
			,a.V_PRIMARY_REINSURER_R
			,a.N_REDIRECT_PAYMENT_CEDED_AMT_R
			,a.N_REDIRECT_PAYMENT_NET_AMT_R
			,a.N_RESERVE_NET_BENEFIT_R
			,a.N_SEC_REINS_LOSS_PCT_R
			,a.V_SECONDARY_REINSURER_R
			,a.N_TERNARY_REINS_LOSS_PCT_R
			,a.V_TERNARY_REINSURER_R
			,a.N_TOTAL_REINS_LOSS_PCT_R
			,a.V_PRIVACY_INDICATOR_R
			,a.V_COVERAGE_GROUP_ID_R
			,a.V_CLAIM_IDENTIFIER_R
			,a.N_CLAIM_COVERAGE_GROUP_SK_R
			,a.N_CLAIM_COVERAGE_SK_R
			,a.V_CLINICAL_VOC_ENGAGEMENT_R
			,a.V_COVERAGE_TYPE_CODE_R
			,a.N_CHG_FIELD_RES_CEDED_AMT_R
			,a.N_CYCLE_DATE_KEY_R
			,a.D_RECEIVED_DATE_R
			,a.V_CLAIM_COVERAGE_CODE_R
			,a.V_CLAIM_STATUS_REASON_CODE_R
			,a.V_REASON_CODE_R
			,CAST(NULL AS NUMBER) N_INSRD_PARTY_SK_R
			,CAST(NULL AS NUMBER) N_EMPLOYEE_SK_R
			,GN_CURRENT_MONTH     N_YEARMONTH_R
			,'Y'                  V_RPT_ACTIVE_STATUS_R
			--09-Feb-2024 changes starts
			,CAST(NULL AS NUMBER)   N_AVG_CLAIM_decision_DAYS_R
			,CAST(NULL AS NUMBER)   N_CLAIM_APPROACH_DUR_R
			,CAST(NULL AS NUMBER)   N_CLAIM_APPROACH_EXP_RESOLUTION_R
			,CAST(NULL AS NUMBER)   N_DURATION_REMAINING_R
			--09-Feb-2024 changes ends
			--12-Aug-2024 changes starts
			,b.V_PROJECTED_DURATION_R
			,b.V_PROJECTED_OUTCOME_R
			,b.N_RECOMMENDED_TIER_R
			,c.N_REFERRAL_SCORE_R
			,case when  (select  N_FISCAL_YEAR_R||lpad(N_FISCAL_MONTH_R,2,0)from dim_time_r where
			d_calendar_date_r =  to_char(D_CLAIM_STATUS_EFF_DATE_R)) = GN_CURRENT_MONTH THEN d.v_prior_claim_status_code_r
			ELSE d.V_CURR_CLAIM_STATUS_CODE_R END as V_PRIOR_CLAIM_STATUS_CODE_R ,
			--12-Aug-2024 changes End
			--28/08/24 changes start
			a.V_CLAIM_DECISION_TYPE_R
			--28/08/24 changes End
			--02/09/24 Changes start
			,CAST(NULL AS NUMBER) N_ORIGINAL_FACE_AMOUNT_R
			--02/09/24 Changes start
			from FCT_RPT_CLAIM_SUMMARY_R a
			--12/08/2024 changes starts
			left outer join STG_EIQ_OWN_OCC_R b on a.v_claim_identifier_r = b.V_CLAIM_ID_R
			left outer join STG_EIQ_CLAIM_REFERRAL_R c on a.v_claim_identifier_r = c.V_CLAIM_ID_R
			left outer join  (select * from rpt_claim_dtl_r where v_rpt_active_status_r = 'Y') d on a.n_claim_coverage_group_sk_r = d.n_claim_coverage_group_sk_r
			AND a.n_claim_coverage_sk_r = d.n_claim_coverage_sk_r
			AND a.n_claim_sk_r = d.n_claim_sk_r
			--12/08/2024 changes End
			WHERE TO_CHAR(D_CYCLE_DATE_R,'YYYYMM')=GN_CURRENT_MONTH;

		gn_run_cnt:= SQL%ROWCOUNT;

		gc_trcmsg:='4.2 Exit from prc_get_cur_data'||chr(13);

		gc_count_type_r:=PKG_GRP_LOG_UTIL.gc_count_type_insert;

		/*START: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
		gt_end_time_r:= SYSTIMESTAMP;

		 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
		 (
			p_job_id_r                    => gn_out_job_id,
			p_batch_id_r                  => gn_sysdt_batchid,
			p_message_type_r              => gc_message_type_r,
			p_code_location_r             => gc_getcur_loadedby,
			p_message_r                   => gc_trcmsg,
			p_count_type_r                => gc_count_type_r,
			p_count_r                     => NULL,
			p_duration_r                  => FNC_GRP_TIME_DURATION(gt_start_time_r,gt_end_time_r),
			p_created_by_r                => GC_JOB_NAME,
			out_prcs_job_log_message_id_r => gn_job_log_message_id_r
		);
	/*END: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
	EXCEPTION
	WHEN OTHERS THEN
		gc_errmsg :=SUBSTR(SQLERRM,1,4000);
		gc_trcmsg:='4.z Error in prc_get_cur_data'||chr(13);

		 /*START: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
			pkg_grp_log_util.prc_update_log_message_r
		(
			n_prcs_job_log_message_id_r => gn_job_log_message_id_r,
			p_err_msg => gc_trcmsg
		);
		/*END: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/

		pkg_grp_log_util.prc_update_log
		(
			p_job_id => gn_out_job_id,
			p_job_status => gc_error_status,
			p_err_msg => gc_errmsg,
			p_trc_msg => chr(13) || gc_errmsg,
			p_log_util_called_by_r => gc_getcur_loadedby
		);
		RAISE;
	END prc_get_cur_data;

	--Procedure to rebuild indexes RPT_FCT_RPT_CLAIM_SUMMARY_R
	PROCEDURE prc_rebuild_indexes
	IS
	LC_REBUILD_INDEX  VARCHAR2(300);
	BEGIN
		gc_trcmsg:='8.a Entered into prc_rebuild_indexes'||chr(13);
		FOR I IN ( select
			'ALTER INDEX '||INDEX_NAME||' REBUILD  parallel 8 nologging' REBUILD_INDEX
			from ALL_INDEXES  where TABLE_NAME ='RPT_FCT_RPT_CLAIM_SUMMARY_R'
			AND INDEX_NAME NOT LIKE 'PK_%'
			AND INDEX_NAME NOT LIKE 'FK_%'
			AND STATUS='UNUSABLE'
			)
		LOOP
			LC_REBUILD_INDEX:=I.REBUILD_INDEX;
			EXECUTE IMMEDIATE LC_REBUILD_INDEX;
		END LOOP;
		gc_trcmsg:='8.z Exit from prc_rebuild_indexes'||chr(13);
	EXCEPTION
	WHEN OTHERS THEN
		gc_errmsg :=SUBSTR(SQLERRM,1,4000);
		gc_trcmsg:='8.z Error in prc_rebuild_indexes'||chr(13);

		/*START: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
			pkg_grp_log_util.prc_update_log_message_r
		(
			n_prcs_job_log_message_id_r => gn_job_log_message_id_r,
			p_err_msg => gc_trcmsg
		);
		/*END: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/

		pkg_grp_log_util.prc_update_log
			  (
				p_job_id => gn_out_job_id,
				p_job_status => gc_error_status,
				p_err_msg => gc_errmsg,
				p_trc_msg => chr(13) || gc_errmsg,
				p_log_util_called_by_r => gc_updby
			  );
		RAISE;
	END prc_rebuild_indexes;
END PKG_GRP_LOAD_RPT_FCT_RPT_CLAIM_SUMMARY_R;
/



  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ATOMIC"."PKG_GRP_LOAD_RPT_FCT_RPT_CLAIM_SUMMARY_R"
IS
/***********************************************************************
  Purpose:  This package body contains procedures which loads data into RPT_FCT_RPT_CLAIM_SUMMARY_R
  Dependent SSL tables : RPT_CLAIM_DTL_R,RPT_CLAIM_SUM_R,RPT_FCT_RPT_CLAIM_SUMMARY_R
   Used DB Objects:FCT_RPT_CLAIM_SUMMARY_R



  Author     Date     Description
  ---------- -------- -------------------------------------------------
  VGireesh   10/11/23 Initial Creation
  VGireesh   01/02/24 Commented out gather stats and indexes build procedure
  VGireesh   09/02/24 Added below columns
                      N_AVG_CLAIM_DECISION_DAYS_R
                      N_CLAIM_APPROACH_DUR_R
                      N_CLAIM_APPROACH_EXP_RESOLUTION_R
                      N_DURATION_REMAINING_R
  VGireesh   09/02/24 Added below functions to populate above columns in the seperate block
                      get_pacs_as_of_date_r
					  get_n_avg_claim_decision_days_r
					  get_n_claim_approach_dur_r
					  get_n_claim_approach_exp_resolution_r
					  get_n_duration_remaining_r
  VGireesh   22/02/24 enabled rebuilding indexes
  VGireesh   26/02/24 Changed date condition in the functions
  VGireesh   26/02/24 for month end  that the tables start loading data in the next month partition
                      Ex: March data on February 29th (as of 2.28).
                          27th is Feb Fisc Month End    202402  should be truncate and load in 202402 partition
                          28th is feb Fisc Month End +1 202402  should be truncate and load in 202402 partition
                          29th is Feb Fisc Month End +2 202403  should inactive records against the partition 202402 and load data in 202403 partition
  VGireesh   03/04/24 Added Parallel to rebuild index fast  parallel 16 nologging
  VGireesh   12/04/24 Added 2 more MERGE statements as requested by Erica for DF
  Chandra    12/08/23 Added 5 New column and Join condition.
  Chandra    28/08/24 Added V_CLAIM_DECISION_TYPE_R Column
  Chandra    02/09/24 Added N_ORIGINAL_FACE_AMOUNT_R  Coulmn
  Chandra    17/09/24 Logic change of a.D_POTENTIAL_RESOLUTION_DATE_R  to d.D_PRD_R AS  D_POTENTIAL_RESOLUTION_DATE_R and
                      d.N_TIER_NUM_R AS V_TIER_NUM_R
                     ,d.V_TIER_DESCRIPTION_R
  Rose		 21/05/25  Commented update flag = 'N' for Month End+2 Load.
					   Added Truncate for Month End+2 Load
  Rose		 22/05/25  Added new logging Mechanism
  Shiva		 08/08/25  Commented Global Index, Added Local Index Rebuild
  Samba		 10/02/26  Capturing the Target count for Audit COntrols when data is inserting into RPT table using Bulkload limit.
  ***********************************************************************/
	--Global Constants
	gd_sysdate               DATE              := TRUNC(SYSDATE);
	gn_prior_month           NUMBER            := TO_NUMBER(TO_CHAR(ADD_MONTHS(TRUNC(gd_sysdate, 'MM'), -1),'YYYYMM'));
	gn_current_month         NUMBER            := TO_NUMBER(TO_CHAR(gd_sysdate,'YYYYMM'));
	gn_sysdt_batchid         NUMBER            := TO_NUMBER(TO_CHAR(gd_sysdate,'YYYYMMDD'));
	gc_main_loadedby         VARCHAR2(100 CHAR):='PKG_GRP_LOAD_RPT_FCT_RPT_CLAIM_SUMMARY_R.MAIN'      ;
	gc_updby                 VARCHAR2(100 CHAR):='PKG_GRP_LOAD_RPT_FCT_RPT_CLAIM_SUMMARY_R.PRC_UPD_DEL_DATA';
	gc_getcur_loadedby       VARCHAR2(100 CHAR):='PKG_GRP_LOAD_RPT_FCT_RPT_CLAIM_SUMMARY_R.PRC_GET_CUR_DATA';
	gc_truncpartby           VARCHAR2(100 CHAR):='PKG_GRP_LOAD_RPT_FCT_RPT_CLAIM_SUMMARY_R.PRC_TRUNC_PARTITION';
	gc_rebuildindexes           VARCHAR2(100 CHAR):='PKG_GRP_LOAD_RPT_FCT_RPT_CLAIM_SUMMARY_R.PRC_REBUILD_INDEXES';
	gc_trcmsg                CLOB              :='Trace Message:->';
	gc_job_name              VARCHAR2(50 CHAR) :='GRP_LOAD_RPT_FCT_RPT_CLAIM_SUMMARY_R';
	gn_bulk_coll_cnt         NUMBER            :=10000;
	gc_running_status        VARCHAR2(30)      :='Running';
	gc_error_status          VARCHAR2(30)      :='Error';
	gc_success_status        VARCHAR2(30)      :='Success';
	gc_source                VARCHAR2(30)      :='EDW';
	gc_target                VARCHAR2(30)      :='RPT';
	gc_main_entity			 VARCHAR2(30)      :='CLAIM_SUMMARY';
	--Global Variables
	gn_out_job_id            NUMBER;
	gc_errmsg                VARCHAR2(4000 CHAR);
	gd_pacs_as_of_date_r     DATE;--09-feb-2024 changes

	/*START: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
	gc_message_type_r 	PRCS_JOB_LOG_MESSAGE_R.v_message_type_r%TYPE    := PKG_GRP_LOG_UTIL.gc_message_type_info;
	gc_count_type_r 	PRCS_JOB_LOG_MESSAGE_R.v_count_type_r%TYPE      := PKG_GRP_LOG_UTIL.gc_count_type_insert;
	gc_duration_r       PRCS_JOB_LOG_MESSAGE_R.T_DURATION_R%TYPE 		:=0;
	gn_run_cnt          PRCS_JOB_LOG_MESSAGE_R.N_COUNT_R%TYPE 	 		:=0;
	gn_loop_counter_r   PRCS_JOB_LOG_MESSAGE_R.N_COUNT_R%TYPE 			:=0;
	gt_start_time_r 	TIMESTAMP;
	gt_end_time_r 		TIMESTAMP;
	gn_job_log_message_id_r  NUMBER;
	gn_error_line VARCHAR2(20);
	gc_rpt_table_name      	VARCHAR2(30)      	:='RPT_FCT_RPT_CLAIM_SUMMARY_R';
	gc_rebuild_idx_degree	PLS_INTEGER      	:=8;
	gd_fic_mis_date          DATE;--29-Aug-2024 changes
	/*END: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/

	--Function to get Pacs as of date
	FUNCTION get_pacs_as_of_date_r
	RETURN DATE
	IS
		ld_date DATE;
	BEGIN
		select to_date(to_char(D_EDS_CYCLEDATE_R,'dd-mon-yyyy')) INTO ld_date
		from PRCS_GRP_DATE_PARAM_R
		where V_PROCESS_NAME_R ='PACS_BATCH_ID';
		RETURN ld_date;
	EXCEPTION
		WHEN OTHERS THEN
		RETURN NULL;
	END get_pacs_as_of_date_r
	;
	--Function to get n_avg_claim_decission_days_r
	FUNCTION get_n_avg_claim_decision_days_r(p_n_claim_sk_r IN NUMBER
									   ,p_n_claim_coverage_sk_r IN NUMBER
									   ,p_n_claim_coverage_group_sk_r IN NUMBER
									   ,p_d_claim_decision_date_r IN DATE
									   ,p_v_claim_decision_ind_r IN VARCHAR2
									   ,p_n_yearmonth_r IN NUMBER
									   )
	RETURN NUMBER
	IS
		ln_num NUMBER;
	BEGIN

		SELECT
		(CASE
		 WHEN NVL(p_v_claim_decision_ind_r,'X@') ='Y'
		 THEN (p_d_claim_decision_date_r-RPT_CLAIM_DTL_R.D_CLAIM_RECEIVED_DATE_R)
		 ELSE
		 0
		END
		) into ln_num
		FROM RPT_CLAIM_DTL_R
		WHERE n_claim_sk_r=p_n_claim_sk_r
		  AND n_claim_coverage_sk_r=p_n_claim_coverage_sk_r
		  AND n_claim_coverage_group_sk_r=p_n_claim_coverage_group_sk_r
		  AND n_yearmonth_r=p_n_yearmonth_r;

		RETURN ln_num;
	EXCEPTION
		WHEN OTHERS THEN
		RETURN NULL;
	END get_n_avg_claim_decision_days_r
	;

	--Function to get n_claim_approach_dur_r
	FUNCTION get_n_claim_approach_dur_r(p_n_claim_sk_r IN NUMBER
									   ,p_n_claim_coverage_sk_r IN NUMBER
									   ,p_n_claim_coverage_group_sk_r IN NUMBER
									   ,p_v_claim_activity_detail_r IN VARCHAR2
									   ,p_d_pacs_as_of_date_r   IN DATE
									   ,p_n_yearmonth_r IN NUMBER
									   )
	RETURN NUMBER
	IS
		ln_num NUMBER;
	BEGIN
		SELECT
		--(CASE WHEN (NVL(p_d_pacs_as_of_date_r,gd_pacs_as_of_date_r)- RPT_CLAIM_DTL_R.D_PLAN_DUR_DATE_R)<=180  AND--24-Feb-2024 changes
		(CASE WHEN (RPT_CLAIM_DTL_R.D_PLAN_DUR_DATE_R-NVL(p_d_pacs_as_of_date_r,gd_pacs_as_of_date_r) )<=180  AND--24-Feb-2024 changes
		RPT_CLAIM_DTL_R.V_CLAIM_STATUS_CODE_R < '60' AND
		NVL(P_V_CLAIM_ACTIVITY_DETAIL_R,'X@') <>'Resisted'
		THEN 1 ELSE 0 END) into ln_num
		FROM RPT_CLAIM_DTL_R
		WHERE n_claim_sk_r=p_n_claim_sk_r
		  AND n_claim_coverage_sk_r=p_n_claim_coverage_sk_r
		  AND n_claim_coverage_group_sk_r=p_n_claim_coverage_group_sk_r
		  AND n_yearmonth_r=p_n_yearmonth_r;
		RETURN NVL(ln_num,0);
	EXCEPTION
		WHEN OTHERS THEN
		RETURN NULL;
	END get_n_claim_approach_dur_r
	;
	--Function to get n_claim_approach_exp_resolution_r
	FUNCTION get_n_claim_approach_exp_resolution_r(p_n_claim_sk_r IN NUMBER
									   ,p_n_claim_coverage_sk_r IN NUMBER
									   ,p_n_claim_coverage_group_sk_r IN NUMBER
									   ,p_d_potential_resolution_date_r IN DATE
									   ,p_v_claim_activity_detail_r IN VARCHAR2
									   ,p_d_pacs_as_of_date_r   IN DATE
									   ,p_n_yearmonth_r IN NUMBER
									   )
	RETURN NUMBER
	IS
		ln_num NUMBER;
	BEGIN
		SELECT
		--(CASE WHEN (NVL(p_d_pacs_as_of_date_r,gd_pacs_as_of_date_r)- P_D_POTENTIAL_RESOLUTION_DATE_R)<=180  AND --24-Feb-2024 changes
		(CASE WHEN (P_D_POTENTIAL_RESOLUTION_DATE_R - NVL(p_d_pacs_as_of_date_r,gd_pacs_as_of_date_r) )<=180  AND--24-Feb-2024 changes
		RPT_CLAIM_DTL_R.V_CLAIM_STATUS_CODE_R< '60'  AND
		NVL(P_V_CLAIM_ACTIVITY_DETAIL_R,'X@') NOT IN ('Resisted', 'Pending')
		THEN 1 ELSE 0 END) into ln_num
		FROM RPT_CLAIM_DTL_R
		WHERE n_claim_sk_r=p_n_claim_sk_r
		  AND n_claim_coverage_sk_r=p_n_claim_coverage_sk_r
		  AND n_claim_coverage_group_sk_r=p_n_claim_coverage_group_sk_r
		  AND n_yearmonth_r=p_n_yearmonth_r;
		RETURN NVL(ln_num,0);
	EXCEPTION
		WHEN OTHERS THEN
		RETURN NULL;
	END get_n_claim_approach_exp_resolution_r
	;
	--Function to get n_duration_remaining_r
	FUNCTION get_n_duration_remaining_r(p_n_claim_sk_r IN NUMBER
									   ,p_n_claim_coverage_sk_r IN NUMBER
									   ,p_n_claim_coverage_group_sk_r IN NUMBER
									   ,p_d_pacs_as_of_date_r   IN DATE
									   ,p_n_yearmonth_r IN NUMBER
									   )
	RETURN NUMBER
	IS
		ld_date DATE;
	BEGIN
		SELECT MAX(d_plan_dur_date_r) INTO ld_date
		FROM RPT_CLAIM_DTL_R
		WHERE n_claim_sk_r=p_n_claim_sk_r
		  AND n_claim_coverage_sk_r=p_n_claim_coverage_sk_r
		  AND n_claim_coverage_group_sk_r=p_n_claim_coverage_group_sk_r
		  AND n_yearmonth_r=p_n_yearmonth_r;
		RETURN NVL((ld_date-NVL(p_d_pacs_as_of_date_r,gd_pacs_as_of_date_r)),0);
	EXCEPTION
		WHEN OTHERS THEN
		RETURN NULL;
	END get_n_duration_remaining_r
	;
	--Main procedures calls other procedure to load data in RPT_CLEINT_DTL_R
	PROCEDURE main
	IS
		VAR_REF_CUR SYS_REFCURSOR;
		TYPE var_tbl_type IS TABLE OF RPT_FCT_RPT_CLAIM_SUMMARY_R%ROWTYPE INDEX BY BINARY_INTEGER;
		lt_var_tbl_typ var_tbl_type;
		ln_rec_cnt NUMBER:=0;
		--14-Jan-2024 changes starts
		ln_start_time NUMBER:=0;
		CURSOR cur_upd_claim_attr
		IS
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
		TYPE var_upd_claim_attr_tbl_type IS TABLE OF cur_upd_claim_attr%ROWTYPE INDEX BY BINARY_INTEGER;
		lt_upd_claim_attr_tbl_typ var_upd_claim_attr_tbl_type;
		--14-Jan-2024 changes ends
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

		/*START: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
		 gc_trcmsg:='1. Entered into main. '||'gn_current_month:->'||gn_current_month|| ' - gn_prior_month:->'||gn_prior_month;
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
		/*END: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/

		gc_trcmsg:='2. get gd_pacs_as_of_date_r '||chr(13);

		/*START: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
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
		/*END: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/

		gd_pacs_as_of_date_r:=PKG_GRP_LOAD_RPT_FCT_RPT_CLAIM_SUMMARY_R.get_pacs_as_of_date_r;
		gc_trcmsg:='2.z get gd_pacs_as_of_date_r completed '||gd_pacs_as_of_date_r||chr(13);

		/*START: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
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
		/*END: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
		gc_trcmsg:='3. Call procedure prc_upd_del_data from main'||chr(13);
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
		gc_trcmsg:='5. Call prc_get_cur_data to get ref_cursor '||chr(13);
		PKG_GRP_LOAD_RPT_FCT_RPT_CLAIM_SUMMARY_R.prc_get_cur_data (var_ref_cur);

		ln_start_time:=dbms_utility.get_time;--22-Feb-2024 changes
		gc_trcmsg:='6 data load starts '||chr(13);
		gt_start_time_r:= SYSTIMESTAMP;

		/*START: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
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
		/*END: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/

		gn_loop_counter_r := 1; -- Initialize loop counter
		gc_count_type_r:=PKG_GRP_LOG_UTIL.gc_count_type_insert;

		ln_rec_cnt:=0;
		LOOP
			lt_var_tbl_typ.DELETE;
			FETCH var_ref_cur BULK COLLECT INTO  lt_var_tbl_typ LIMIT gn_bulk_coll_cnt;

			gt_start_time_r := SYSTIMESTAMP; -- Start timing before the insert

			 FORALL X in LT_VAR_TBL_TYP.first..LT_VAR_TBL_TYP.last
			 INSERT /*+APPEND_VALUES*/ INTO RPT_FCT_RPT_CLAIM_SUMMARY_R VALUES lt_var_tbl_typ(x) ;
			 LN_REC_CNT:=LN_REC_CNT+LT_VAR_TBL_TYP.COUNT;
			commit;

			gt_end_time_r := SYSTIMESTAMP; -- End timing after the insert
			gc_trcmsg := '6.1 data load: Bulk Set-'|| gn_loop_counter_r ||': '||LN_REC_CNT||' records loaded' ;
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

		ln_start_time:=dbms_utility.get_time;--22-Feb-2024 changes
		gc_trcmsg:='6.2 Data Loaded '||ln_rec_cnt||' records '||chr(13);

		/*START: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
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
		/*END: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/


		gc_trcmsg:='6.2.1 Target count for Audit control Process';

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

		gc_trcmsg:='6.3 Merge into RPT_FCT_RPT_CLAIM_SUMMARY_R table from main '||chr(13);
		gt_start_time_r:= SYSTIMESTAMP;
		/*START: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
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
		/*END: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/

		MERGE /*+PARALLEL(4)*/ INTO rpt_fct_rpt_claim_summary_r TAB1
			USING (SELECT /*+PARALLEL(4)*/ V_CLAIM_IDENTIFIER_R, max(a.n_claim_sk_r) n_claim_sk_r , max(B.N_PRODUCT_SK_R) N_PRODUCT_SK_R, MAX(B.N_cuST_PARTY_SK_R) N_PARTY_SK_R, MAX(B.N_POLICY_SK_R) N_POLICY_SK_R,
			MAX(B.N_INSRD_PARTY_SK_R)N_INSRD_PARTY_SK_R, MAX(B.N_EMPLOYEE_SK_R) N_EMPLOYEE_SK_R,MAX(B.N_ORIGINAL_FACE_AMOUNT_R) N_ORIGINAL_FACE_AMOUNT_R
			from rpt_claim_dtl_r a, rpt_claim_sum_r b
		where a.n_claim_sk_r = b.n_claim_sk_r
		and a.n_claim_coverage_sk_r = b.n_claim_coverage_sk_r
		and a.n_claim_coverage_group_sk_r = b.n_claim_coverage_group_sk_r
		and a.n_yearmonth_r=gn_current_month--Added by Gireesh on 18-Jan-2024
		and b.n_yearmonth_r=gn_current_month--Added by Gireesh on 18-Jan-2024
		group by V_CLAIM_IDENTIFIER_R) TAB2
			ON (TAB1.V_CLAIM_IDENTIFIER_R = TAB2.V_CLAIM_IDENTIFIER_R)
		  WHEN MATCHED THEN
			UPDATE SET TAB1.n_claim_sk_r = TAB2.n_claim_sk_r,
			TAB1.N_PRODUCT_SK_R = TAB2.N_PRODUCT_SK_R,
			TAB1.N_PARTY_SK_R = TAB2.N_PARTY_SK_R,
			TAB1.N_POLICY_SK_R = TAB2.N_POLICY_SK_R,
			TAB1.N_INSRD_PARTY_SK_R = TAB2.N_INSRD_PARTY_SK_R,
			TAB1.N_EMPLOYEE_SK_R = TAB2.N_EMPLOYEE_SK_R,
			--02/09/24 Changes start
			TAB1.N_ORIGINAL_FACE_AMOUNT_R = TAB2.N_ORIGINAL_FACE_AMOUNT_R
			--02/09/24 Changes End
			 WHERE
				--TAB1.D_CYCLE_DATE_R = (SELECT /*+PARALLEL(4)*/ MAX(D_CYCLE_DATE_R) FROM rpt_fct_rpt_claim_summary_r_tmp) ;
				 TO_CHAR(TAB1.D_CYCLE_DATE_R,'YYYYMM')=GN_CURRENT_MONTH;

			gn_run_cnt:= SQL%ROWCOUNT;
			COMMIT;

		GC_TRCMSG:='6.4 Merge into RPT_FCT_RPT_CLAIM_SUMMARY_R table from main completed';
		--14-Jan-2024 changes starts
		ln_start_time:=dbms_utility.get_time;--22-Feb-2024 changes

		gc_count_type_r:=PKG_GRP_LOG_UTIL.gc_count_type_merge;

		/*START: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
		gt_end_time_r:= SYSTIMESTAMP;

		 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
		 (
			p_job_id_r                    => gn_out_job_id,
			p_batch_id_r                  => gn_sysdt_batchid,
			p_message_type_r              => gc_message_type_r,
			p_code_location_r             => gc_main_loadedby,
			p_message_r                   => gc_trcmsg,
			p_count_type_r                => gc_count_type_r,
			p_count_r                     => gn_run_cnt,
			p_duration_r                  => FNC_GRP_TIME_DURATION(gt_start_time_r,gt_end_time_r),
			p_created_by_r                => GC_JOB_NAME,
			out_prcs_job_log_message_id_r => gn_job_log_message_id_r
		);
		/*END: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/

		gc_trcmsg:='6.5 Update Claim Attributes from main ';

			gt_start_time_r:= SYSTIMESTAMP;
		/*START: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
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
		/*END: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/

		gn_loop_counter_r := 1; -- Initialize loop counter
		gc_count_type_r:=PKG_GRP_LOG_UTIL.gc_count_type_update;

		ln_rec_cnt:=0;

		OPEN  cur_upd_claim_attr ;
			LOOP
				lt_upd_claim_attr_tbl_typ.DELETE;
				FETCH cur_upd_claim_attr bulk collect into  lt_upd_claim_attr_tbl_typ limit GN_BULK_COLL_CNT;

				gt_start_time_r := SYSTIMESTAMP; -- Start timing before the update

				FORALL X in lt_upd_claim_attr_tbl_typ.first..lt_upd_claim_attr_tbl_typ.last
				UPDATE RPT_FCT_RPT_CLAIM_SUMMARY_R
				  set n_avg_claim_decision_days_r     =lt_upd_claim_attr_tbl_typ(X).n_avg_claim_decision_days_r
				  , n_claim_approach_dur_r           =lt_upd_claim_attr_tbl_typ(X).n_claim_approach_dur_r
				  , n_claim_approach_exp_resolution_r=lt_upd_claim_attr_tbl_typ(X).n_claim_approach_exp_resolution_r
				  , n_duration_remaining_r           =lt_upd_claim_attr_tbl_typ(X).n_duration_remaining_r
				where rowid=lt_upd_claim_attr_tbl_typ(X).row_id;

				LN_REC_CNT:=LN_REC_CNT+LT_VAR_TBL_TYP.COUNT;
				 commit;
				 /* Start - New logging changes*/
				gt_end_time_r := SYSTIMESTAMP; -- End timing after the insert
				gc_trcmsg := '6.6 data update: Bulk Set-'|| gn_loop_counter_r ||': '||LN_REC_CNT||' records Updated' ;
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

				 /* End - New logging changes*/

				 EXIT WHEN cur_upd_claim_attr%NOTFOUND;
			END LOOP;

		CLOSE cur_upd_claim_attr;

		gc_trcmsg:='7. Update Claim Attributes completed from main ';

		/*START: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
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
		/*END: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/

		--14-Jan-2024 changes ends
		--22-Feb-2024 changes starts
		ln_start_time:=dbms_utility.get_time;
		gc_trcmsg:='8. Rebuild Local Index prc_rebuild_index_partitions from Common Util for Partition: '||gn_current_month;

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

		--PKG_GRP_LOAD_RPT_FCT_RPT_CLAIM_SUMMARY_R.prc_rebuild_indexes; -- 8th Aug: Removed Global Index Rebuild


		--8th Aug: Added Local Index Rebuild
		PKG_GRP_COMMON_UTIL.prc_rebuild_index_partitions
		(
			p_table_name   		  		  => 'RPT_FCT_RPT_CLAIM_SUMMARY_R',
			p_parallel_degree   		  => 8,
			p_partition_name  		  	  => 'PART_RPT_FCT_RPT_CLAIM_SUMMARY_R_'||gn_current_month,
			p_out_job_id              	  => gn_out_job_id,
			p_Log_seq_num             	  => 8
		);

		gc_trcmsg:='8.z Completed Rebuild Local Index prc_rebuild_index_partitions from Common Util for Partition: '||gn_current_month;

		/*START: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
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
		/*END: 20-MAY-2025: NEW LOGGING MECHANISM CHANGES*/

		--12-Apr-2024 changes starts
		ln_start_time:=dbms_utility.get_time;
		gc_trcmsg:='9. Execute Merge1 from main starts ';
		gt_start_time_r:= SYSTIMESTAMP;
		/*START: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
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
		/*END: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/

		MERGE /*+PARALLEL(4)*/ INTO rpt_fct_rpt_claim_summary_r TAB1
			USING (SELECT /*+PARALLEL(4)*/ V_CLAIM_IDENTIFIER_R, max(a.n_claim_sk_r) n_claim_sk_r , max(B.N_PRODUCT_SK_R) N_PRODUCT_SK_R, MAX(B.N_cuST_PARTY_SK_R) N_PARTY_SK_R, MAX(B.N_POLICY_SK_R) N_POLICY_SK_R,
			MAX(B.N_INSRD_PARTY_SK_R)N_INSRD_PARTY_SK_R, MAX(B.N_EMPLOYEE_SK_R) N_EMPLOYEE_SK_R, max(a.n_claim_coverage_sk_r)n_claim_coverage_sk_r,max(a.n_claim_coverage_group_sk_r)n_claim_coverage_group_sk_r
			from rpt_claim_dtl_r a, rpt_claim_sum_r b
		where
			a.n_yearmonth_r=gn_current_month
		and b.n_yearmonth_r=gn_current_month
		and a.n_claim_coverage_group_sk_r = b.n_claim_coverage_group_sk_r
		and a.n_claim_coverage_sk_r = b.n_claim_coverage_sk_r
		and a.n_claim_sk_r = b.n_claim_sk_r
		group by V_CLAIM_IDENTIFIER_R) TAB2
			ON (substr(TAB1.V_CLAIM_IDENTIFIER_R,0,length(TAB1.V_CLAIM_IDENTIFIER_R)-3) = TAB2.V_CLAIM_IDENTIFIER_R)
		  WHEN MATCHED THEN
			UPDATE SET TAB1.n_claim_sk_r = TAB2.n_claim_sk_r,
			TAB1.N_PRODUCT_SK_R = TAB2.N_PRODUCT_SK_R,
			TAB1.N_PARTY_SK_R = TAB2.N_PARTY_SK_R,
			TAB1.N_POLICY_SK_R = TAB2.N_POLICY_SK_R,
			TAB1.N_INSRD_PARTY_SK_R = TAB2.N_INSRD_PARTY_SK_R,
			TAB1.N_EMPLOYEE_SK_R = TAB2.N_EMPLOYEE_SK_R,
			TAB1.n_claim_coverage_sk_r = TAB2.n_claim_coverage_sk_r,
			TAB1.n_claim_coverage_group_sk_r =TAB2.n_claim_coverage_group_sk_r
			where tab1.n_yearmonth_r=gn_current_month
			and tab1.V_COVERAGE_GROUP_ID_R = 'DF';

		gn_run_cnt:= SQL%ROWCOUNT;
		commit;

		gc_trcmsg:='9.z  Execution of Merge1 from main completed ';
		gc_count_type_r:=PKG_GRP_LOG_UTIL.gc_count_type_merge;

		/*START: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
		gt_end_time_r:= SYSTIMESTAMP;

		 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
		 (
			p_job_id_r                    => gn_out_job_id,
			p_batch_id_r                  => gn_sysdt_batchid,
			p_message_type_r              => gc_message_type_r,
			p_code_location_r             => gc_main_loadedby,
			p_message_r                   => gc_trcmsg,
			p_count_type_r                => gc_count_type_r,
			p_count_r                     => gn_run_cnt,
			p_duration_r                  => FNC_GRP_TIME_DURATION(gt_start_time_r,gt_end_time_r),
			p_created_by_r                => GC_JOB_NAME,
			out_prcs_job_log_message_id_r => gn_job_log_message_id_r
		);
		/*END: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/

		gc_trcmsg:='10. Execute Merge2 from main starts ';
		gt_start_time_r:= SYSTIMESTAMP;
		/*START: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
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
		/*END: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/

		MERGE /*+PARALLEL(4)*/ INTO rpt_fct_rpt_claim_summary_r TAB1
		USING (select n_claim_coverage_group_sk_r from (select
			   case when N_CLAIM_CVRG_GRP_SRC_SYS_KEY_R is null
			   then
			   case when
			   rank() over(partition by n_claim_sk_r order by nvl(N_CLAIM_CVRG_GRP_SRC_SYS_KEY_R,0) desc) = 1
			   then 1
			   else 0 end
			   else 1 end DF_CVG, c.v_claim_number_r, c.v_claim_identifier_r, c.N_CLAIM_CVRG_GRP_SRC_SYS_KEY_R, c.n_claim_coverage_group_sk_r
			   from  atomic.DIM_GRP_CLAIM_COVERAGE_GROUP_R c
			   where V_ACTIVE_STATUS_R = 'Y') where DF_CVG = 0) TAB2
		ON (TAB1.n_claim_coverage_group_sk_r = TAB2.n_claim_coverage_group_sk_r)
		WHEN MATCHED THEN
		UPDATE SET TAB1.n_claim_sk_r = -1,
				  TAB1.n_claim_coverage_sk_r = -1
		where tab1.n_yearmonth_r=gn_current_month
		and tab1.V_COVERAGE_GROUP_ID_R = 'DF';

		gn_run_cnt:= SQL%ROWCOUNT;
		commit;

		gc_trcmsg:='10.1  Execution of Merge2 from main completed ';
		--12-Apr-2024 change ends

		gc_count_type_r:=PKG_GRP_LOG_UTIL.gc_count_type_merge;

		/*START: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
		gt_end_time_r:= SYSTIMESTAMP;

		 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
		 (
			p_job_id_r                    => gn_out_job_id,
			p_batch_id_r                  => gn_sysdt_batchid,
			p_message_type_r              => gc_message_type_r,
			p_code_location_r             => gc_main_loadedby,
			p_message_r                   => gc_trcmsg,
			p_count_type_r                => gc_count_type_r,
			p_count_r                     => gn_run_cnt,
			p_duration_r                  => FNC_GRP_TIME_DURATION(gt_start_time_r,gt_end_time_r),
			p_created_by_r                => GC_JOB_NAME,
			out_prcs_job_log_message_id_r => gn_job_log_message_id_r
		);
		/*END: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/

	gc_trcmsg:='11. Calling Audit Control Procedure';

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

	PRC_GRP_AUDIT_CONTROL_PROCESS(gc_source,gc_main_entity,gc_source, gc_target);

	 --01-Feb-2024 changes
		gc_trcmsg:='1.z Exit from main'||chr(13);

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
		/*START: 20-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
			pkg_grp_log_util.prc_update_log_message_r
		(
			n_prcs_job_log_message_id_r => gn_job_log_message_id_r,
			p_err_msg => gc_trcmsg
		);
		/*END: 20-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
		pkg_grp_log_util.prc_update_log
		  (
			gn_out_job_id                   --p_job_id
			,gc_error_status                --p_job_status
			,gc_errmsg                       --p_err_msg
			,gc_trcmsg||chr(13)||gc_errmsg  --p_trc_msg
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
		   gc_trcmsg:='5 Entered into prc_get_cur_data '||chr(13);

		   /*START: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
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
			/*END: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/

		   --Open/Assign SELECT stmnt
			open P_OUT_CURSOR for
			select
			 a.N_CLAIM_SK_R
			,a.N_PRODUCT_SK_R
			,a.N_PARTY_SK_R
			,a.N_POLICY_SK_R
			,a.N_NO_OF_PAYMENTS_R
			,a.N_NO_OF_CHECKS_R
			,a.N_NO_OF_VOID_PAYMENTS_R
			,a.N_NO_OF_VOID_CHECKS_R
			,a.N_TOTAL_CLAIM_COUNT_R
			,a.N_CHG_TOTAL_CLAIM_COUNT_R
			,a.N_REOPEN_CLAIM_COUNT_R
			,a.N_CHG_REOPEN_CLAIM_COUNT_R
			,a.N_PENDING_CLAIM_COUNT_R
			,a.N_CHG_PENDING_CLAIM_COUNT_R
			,a.N_APPROVED_CLAIM_COUNT_R
			,a.N_CHG_APPROVED_CLAIM_COUNT_R
			,a.N_CLOSED_CLAIM_COUNT_R
			,a.N_CHG_CLOSED_CLAIM_COUNT_R
			,a.N_GAAP_OS_RESERVE_COUNT_R
			,a.N_CHG_GAAP_OS_RESERVE_COUNT_R
			,a.N_GAAP_WV_RESERVE_COUNT_R
			,a.N_CHG_GAAP_WV_RESERVE_COUNT_R
			,a.N_STAT_OS_RESERVE_COUNT_R
			,a.N_CHG_STAT_OS_RESERVE_COUNT_R
			,a.N_STAT_WV_RESERVE_COUNT_R
			,a.N_CHG_STAT_WV_RESERVE_COUNT_R
			,a.N_PAYMENT_DIRECT_AMT_R
			,a.N_LOSS_PAYMENT_DIRECT_AMT_R
			,a.N_WAGE_BASE_R
			,a.N_TAXABLE_BENEFITS_R
			,a.N_NON_TAXABLE_BENEFITS_R
			,a.N_FIT_R
			,a.N_SIT_R
			,a.N_FICA_R
			,a.N_MEDICARE_TAX_R
			,a.N_FICA_WAGE_BASE_R
			,a.N_MEDICARE_WAGE_BASE_R
			,a.N_EMPLOYER_FICA_R
			,a.N_EMPLOYER_MEDICARE_TAX_R
			,a.N_EMP_FICA_WAGE_BASE_R
			,a.N_EMP_MEDICARE_WAGE_BASE_R
			,a.N_FUTA_R
			,a.N_PAYMENT_TAXABLE_BENEFITS_R
			,a.N_PAYMENT_NONTAXABLE_BEN_R
			,a.N_PRIOR_GAAP_RESERVE_DIRECT_R
			,a.N_CHG_GAAP_OS_DIRECT_AMT_R
			,a.N_CURR_GAAP_RESERVE_DIRECT_R
			,a.N_PRIOR_STAT_RESERVE_DIRECT_R
			,a.N_CHG_STAT_OS_DIRECT_AMT_R
			,a.N_CURR_STAT_RESERVE_DIRECT_R
			,a.N_PRIOR_GAAP_WV_DIRECT_AMT_R
			,a.N_CHG_GAAP_WV_DIRECT_AMT_R
			,a.N_CURR_GAAP_WV_DIRECT_AMT_R
			,a.N_PRIOR_STAT_WV_DIRECT_AMT_R
			,a.N_CHG_STAT_WV_DIRECT_AMT_R
			,a.N_CURR_STAT_WV_DIRECT_AMT_R
			,a.N_PRIOR_BE_DIRECT_AMT_R
			,a.N_CHG_BE_RESERVE_DIRECT_AMT_R
			,a.N_CURR_BE_RESERVE_DIRECT_AMT_R
			,a.N_PRIOR_FIELD_RES_DIRECT_AMT_R
			,a.N_CHG_FIELD_RES_DIRECT_AMT_R
			,a.N_CURR_FIELD_RES_DIRECT_AMT_R
			,a.N_CHG_BE_RESERVE_CEDED_AMT_R
			,a.N_CHG_BE_RESERVE_NET_AMT_R
			,a.N_CHG_FIELD_RES_NET_AMT_R
			,a.N_CURR_BE_RESERVE_CEDED_AMT_R
			,a.N_CURR_BE_RESERVE_NET_AMT_R
			,a.N_CURR_FIELD_RES_CEDED_AMT_R
			,a.N_CURR_FIELD_RES_NET_AMT_R
			,a.N_INIT_CLM_DECISION_DAYS_R
			,a.N_INIT_AVG_CLM_DECISION_DAYS_R
			,a.V_CLAIM_DECISION_IND_R
			,a.D_CLAIM_DECISION_DATE_R
			,a.D_FIRST_PAYMENT_FROM_DATE_R
			,a.D_LAST_PAYMENT_TO_DATE_R
			,a.D_FIRST_PAYMENT_DATE_R
			,a.D_LAST_PAYMENT_DATE_R

			,a.N_NEW_CLAIM_RECEIPTS_R
			,a.N_DENIED_CLAIMS_R
			,a.N_NEW_APPEAL_RECEIPTS_R
			,a.N_CLAIMS_SETTLED_R
			,a.N_CLAIMS_WITH_OVERPAYMENTS_R
			,a.N_CLAIMS_BRIDGED_STD_TO_LTD_R
			,a.N_CLMS_W_CLINICAL_ENGAGEMENT_R
			,a.N_LTD_APPROVED_CLMS_OWN_OCC_R
			,a.N_LTD_APPRVED_OWNOCC_FULLDUR_R
			,a.N_LTD_APPROVED_CLMS_ANY_OCC_R
			,a.V_LTD_ANY_OCC_GROUP_R
			,a.N_LTD_APPROVED_PAS_CLAIMS_R
			,a.V_SS_PURSUE_INDICATED_R
			,a.N_CLAIMS_REFERRED_SS_VENDOR_R
			,a.N_PRIMARY_SS_AWARDS_COUNTS_R
			,a.N_PRIMARY_SS_AWARDS_TOTAL_R
			,a.N_DEPENDENT_SS_AWARDS_COUNTS_R
			,a.N_DEPENDENT_SS_AWARDS_TOTAL_R
			,a.N_SETTLEMENTS_OFFERED_R
			,a.N_SETTLEMENT_OFFERS_DECLINED_R
			,a.N_OVERPAYMENT_BALANCE_R
			,a.N_OVERPAYMENTS_RECOVERED_R
			,a.N_INITIAL_CLOSURE_R
			,a.V_PAID_AND_CLOSED_R
			,a.D_DECISION_MADE_DATE_R
			,a.N_AGED_PENDING_CLAIMS_R
			,a.N_AVG_TASKS_COMPLETED_DAY_R
			,a.N_CLAIM_TOUCHES_PER_DAY_R
			,a.N_AVG_TASK_AGING_R
			,a.N_PRODUCTION_BALANCE_RATIO_R
			,a.N_NO_OF_EXTENSIONS_PER_CLAIM_R
			,a.N_AVG_DAYS_CLAIM_DECISION_R
			,a.N_AVG_DAYS_REC_CLM_DECISION_R
			,a.N_INITIAL_APPROVAL_RATE_R
			,a.N_APPROVAL_RATE_BY_PLAN_EP_R
			,a.N_INITIAL_CLOSURE_RATE_R
			,a.N_CLOSURE_RATE_R
			,a.N_CLOSURE_RATE_OWNOCC_PERIOD_R
			,a.N_CLOSURE_RATE_ANYOCC_PERIOD_R
			,a.N_REOPEN_RATE_R
			,a.N_APPEAL_RATE_R
			,a.N_ANY_OCC_APPROVAL_RATE_R
			,a.N_PAS_ACCEPTANCE_RATE_STAT35_R
			,a.N_ACTUAL_DURATION_R
			,a.N_DURATION_BY_PLAN_EP_R
			,a.N_AVG_PAYMENT_AMT_R
			,a.N_AVG_CASELOADS_R
			,a.N_ACTUAL_TO_EXPECTED_R
			,a.N_LTD_CLAIM_SETTLEMENT_RATE_R
			,a.N_OVERPAYMENT_RECOV_SUCCESS_R
			,a.N_SS_VENDOR_PLACEMENT_RATE_R
			,a.N_SS_VENDOR_AWARD_RATE_R
			,a.N_SS_CLAIMS_BY_APPEAL_LEVEL_R
			,a.N_SSCOMPASSIONALLOW_APPRVALS_R
			,a.N_NONSS_REPRESENTED_CLAIMS_R
			,a.N_PENSION_ELIGIBLE_CLAIMS_R
			,a.N_PENSION_CLAIMS_NO_OFFSET_R
			,a.N_INIT_APPROVAL_RT_CLINICAL_R
			,a.N_INIT_APP_RT_WO_CLINICAL_R
			,a.N_CLOSURE_RATE_WITH_CLINICAL_R
			,a.N_CLOSURE_RATE_WO_CLINICAL_R
			,a.V_INITIAL_CLINICAL_INDICATOR_R
			,a.V_CURRENT_CLINICAL_INDICATOR_R
			,a.N_CLAIMS_RTW_W_INTERVENTION_R
			,a.N_CLAIMS_RTW_WO_INTERVENTION_R
			,a.N_PARTIAL_RTW_W_ACCOMODATION_R
			,a.N_PART_TIME_RTW_CLAIMS_R
			,a.N_NO_OF_VOCATIONAL_TOUCHES_R
			,CAST(NULL AS NUMBER) N__OF_CLINICAL_TOUCHES_R
			,a.N_SEGMENTATION_RESULTS_R
			,a.N_CLAIMS_REVIEWED_FOR_FWA_R
			,a.N_CLAIMS_IDENTIFIED_FOR_FWA_R
			,a.N_QUALITY_REVIEW_SCORE_R
			,a.V_ELIMINATION_PERIOD_GROUP_R
			,a.V_CLAIM_ACTIVITY_TYPE_R
			,a.V_CLAIM_ACTIVITY_GROUP_R
			,a.V_CLAIM_ACTIVITY_DETAIL_R
			,a.N_CLAIM_AGE_R
			,a.V_REINSURANCE_INDICATOR_R
			,a.N_ENTRY_ERROR_COUNT_R
			,a.N_NEW_CLAIM_ERROR_R
			,a.N_NEW_CLAIM_COUNT_ADJUSTED_R
			,a.N_ENTRY_ERROR_ADJUSTED_R
			,a.N_BATCH_ID_R
			,a.N_LOAD_RUN_ID_R
			,CAST(NULL AS NUMBER) N_SEQUENCE__R
			,systimestamp T_CREATION_DATE_R
			,a.T_EVENT_TIMESTAMP_R
			,systimestamp T_LAST_MODIFIED_DATE_R
			,gc_getcur_loadedby V_CREATED_BY_R
			,gc_getcur_loadedby V_LAST_MODIFIED_BY_R
			,a.FIC_MIS_DATE_R
			,a.V_SOURCE_SYSTEM_NAME_R
			,a.V_SUBJECT_AREA_TYPE_R
			,CAST(NULL AS NUMBER) N_VERSION__R
			,a.F_PHYSICAL_DELETE_R
			,a.V_CHANGE_REASON_R
			,a.D_CYCLE_DATE_R
			,a.N_QUOTE_SK_R
			,a.D_FIRST_OPEN_STATUS_EFF_DATE_R
			,a.V_DECISION_MADE_R
			,CAST(NULL AS VARCHAR2(100)) V_CLAIM__R
			,a.V_COVERAGE_CODE_R
			,a.V_POLICY_PREFIX_R
			,a.V_POLICY_SUFFIX_R
			,CAST(NULL AS NUMBER) N_CUSTOMER__R
			--17/09/24 changes start
			--,a.V_TIER_NUM_R
			--,a.V_TIER_DESCRIPTION_R
			,d.N_TIER_NUM_R AS V_TIER_NUM_R
			,d.V_TIER_DESCRIPTION_R
			--17/09/24 changes start
			,a.V_ACCOMMODATIONS_NEEDED_R
			,a.V_RECOVERY_EXPECTATIONS_R
			,a.V_WFAM_CODE_R
			--17/09/24 changes start
			-- ,a.D_POTENTIAL_RESOLUTION_DATE_R
			,d.D_PRD_R AS D_POTENTIAL_RESOLUTION_DATE_R
			--17/09/24 changes start
			,CAST(NULL AS VARCHAR2(100)) V_TAX__R
			,CAST(NULL AS VARCHAR2(100)) V_POLICY__R
			,a.V_REINLOSS001_USE_R
			,a.V_PRODUCT_SUB_LINE_CODE_R
			,a.N_CHG_ACT_OS_CEDED_AMT_R
			,a.N_CHG_ACT_OS_NET_AMT_R
			,a.N_CHG_FIELD_OS_CEDED_AMT_R
			,a.N_CHG_FIELD_OS_NET_AMT_R
			,a.N_CHG_GAAP_OS_CEDED_AMT_R
			,a.N_CHG_GAAP_OS_NET_AMT_R
			,a.N_CHG_GAAP_WV_CEDED_AMT_R
			,a.N_CHG_GAAP_WV_NET_AMT_R
			,a.N_CHG_STAT_OS_CEDED_AMT_R
			,a.N_CHG_STAT_OS_NET_AMT_R
			,a.N_CHG_STAT_WV_CEDED_AMT_R
			,a.N_CHG_STAT_WV_NET_AMT_R
			,a.N_CURR_ACT_OS_CEDED_AMT_R
			,a.N_CURR_ACT_OS_NET_AMT_R
			,a.N_CURR_FIELD_OS_CEDED_AMT_R
			,a.N_CURR_FIELD_OS_NET_AMT_R
			,a.N_CURR_GAAP_OS_CEDED_AMT_R
			,a.N_CURR_GAAP_OS_NET_AMT_R
			,a.N_CURR_GAAP_WV_CEDED_AMT_R
			,a.N_CURR_GAAP_WV_NET_AMT_R
			,a.N_CURR_STAT_OS_CEDED_AMT_R
			,a.N_CURR_STAT_OS_NET_AMT_R
			,a.N_CURR_STAT_WV_CEDED_AMT_R
			,a.N_CURR_STAT_WV_NET_AMT_R
			,a.N_LOSS_PAYMENT_CEDED_AMT_R
			,a.N_LOSS_PAYMENT_NET_AMT_R
			,a.N_PAYMENT_CEDED_AMT_R
			,a.N_PAYMENT_NET_AMT_R
			,a.N_PRIMARY_REINS_LOSS_PCT_R
			,a.V_PRIMARY_REINSURER_R
			,a.N_REDIRECT_PAYMENT_CEDED_AMT_R
			,a.N_REDIRECT_PAYMENT_NET_AMT_R
			,a.N_RESERVE_NET_BENEFIT_R
			,a.N_SEC_REINS_LOSS_PCT_R
			,a.V_SECONDARY_REINSURER_R
			,a.N_TERNARY_REINS_LOSS_PCT_R
			,a.V_TERNARY_REINSURER_R
			,a.N_TOTAL_REINS_LOSS_PCT_R
			,a.V_PRIVACY_INDICATOR_R
			,a.V_COVERAGE_GROUP_ID_R
			,a.V_CLAIM_IDENTIFIER_R
			,a.N_CLAIM_COVERAGE_GROUP_SK_R
			,a.N_CLAIM_COVERAGE_SK_R
			,a.V_CLINICAL_VOC_ENGAGEMENT_R
			,a.V_COVERAGE_TYPE_CODE_R
			,a.N_CHG_FIELD_RES_CEDED_AMT_R
			,a.N_CYCLE_DATE_KEY_R
			,a.D_RECEIVED_DATE_R
			,a.V_CLAIM_COVERAGE_CODE_R
			,a.V_CLAIM_STATUS_REASON_CODE_R
			,a.V_REASON_CODE_R
			,CAST(NULL AS NUMBER) N_INSRD_PARTY_SK_R
			,CAST(NULL AS NUMBER) N_EMPLOYEE_SK_R
			,GN_CURRENT_MONTH     N_YEARMONTH_R
			,'Y'                  V_RPT_ACTIVE_STATUS_R
			--09-Feb-2024 changes starts
			,CAST(NULL AS NUMBER)   N_AVG_CLAIM_decision_DAYS_R
			,CAST(NULL AS NUMBER)   N_CLAIM_APPROACH_DUR_R
			,CAST(NULL AS NUMBER)   N_CLAIM_APPROACH_EXP_RESOLUTION_R
			,CAST(NULL AS NUMBER)   N_DURATION_REMAINING_R
			--09-Feb-2024 changes ends
			--12-Aug-2024 changes starts
			,b.V_PROJECTED_DURATION_R
			,b.V_PROJECTED_OUTCOME_R
			,b.N_RECOMMENDED_TIER_R
			,c.N_REFERRAL_SCORE_R
			,case when  (select  N_FISCAL_YEAR_R||lpad(N_FISCAL_MONTH_R,2,0)from dim_time_r where
			d_calendar_date_r =  to_char(D_CLAIM_STATUS_EFF_DATE_R)) = GN_CURRENT_MONTH THEN d.v_prior_claim_status_code_r
			ELSE d.V_CURR_CLAIM_STATUS_CODE_R END as V_PRIOR_CLAIM_STATUS_CODE_R ,
			--12-Aug-2024 changes End
			--28/08/24 changes start
			a.V_CLAIM_DECISION_TYPE_R
			--28/08/24 changes End
			--02/09/24 Changes start
			,CAST(NULL AS NUMBER) N_ORIGINAL_FACE_AMOUNT_R
			--02/09/24 Changes start
			from FCT_RPT_CLAIM_SUMMARY_R a
			--12/08/2024 changes starts
			left outer join STG_EIQ_OWN_OCC_R b on a.v_claim_identifier_r = b.V_CLAIM_ID_R
			left outer join STG_EIQ_CLAIM_REFERRAL_R c on a.v_claim_identifier_r = c.V_CLAIM_ID_R
			left outer join  (select * from rpt_claim_dtl_r where v_rpt_active_status_r = 'Y') d on a.n_claim_coverage_group_sk_r = d.n_claim_coverage_group_sk_r
			AND a.n_claim_coverage_sk_r = d.n_claim_coverage_sk_r
			AND a.n_claim_sk_r = d.n_claim_sk_r
			--12/08/2024 changes End
			WHERE TO_CHAR(D_CYCLE_DATE_R,'YYYYMM')=GN_CURRENT_MONTH;

		gn_run_cnt:= SQL%ROWCOUNT;

		gc_trcmsg:='4.2 Exit from prc_get_cur_data'||chr(13);

		gc_count_type_r:=PKG_GRP_LOG_UTIL.gc_count_type_insert;

		/*START: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
		gt_end_time_r:= SYSTIMESTAMP;

		 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
		 (
			p_job_id_r                    => gn_out_job_id,
			p_batch_id_r                  => gn_sysdt_batchid,
			p_message_type_r              => gc_message_type_r,
			p_code_location_r             => gc_getcur_loadedby,
			p_message_r                   => gc_trcmsg,
			p_count_type_r                => gc_count_type_r,
			p_count_r                     => NULL,
			p_duration_r                  => FNC_GRP_TIME_DURATION(gt_start_time_r,gt_end_time_r),
			p_created_by_r                => GC_JOB_NAME,
			out_prcs_job_log_message_id_r => gn_job_log_message_id_r
		);
	/*END: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
	EXCEPTION
	WHEN OTHERS THEN
		gc_errmsg :=SUBSTR(SQLERRM,1,4000);
		gc_trcmsg:='4.z Error in prc_get_cur_data'||chr(13);

		 /*START: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
			pkg_grp_log_util.prc_update_log_message_r
		(
			n_prcs_job_log_message_id_r => gn_job_log_message_id_r,
			p_err_msg => gc_trcmsg
		);
		/*END: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/

		pkg_grp_log_util.prc_update_log
		(
			p_job_id => gn_out_job_id,
			p_job_status => gc_error_status,
			p_err_msg => gc_errmsg,
			p_trc_msg => chr(13) || gc_errmsg,
			p_log_util_called_by_r => gc_getcur_loadedby
		);
		RAISE;
	END prc_get_cur_data;

	--Procedure to rebuild indexes RPT_FCT_RPT_CLAIM_SUMMARY_R
	PROCEDURE prc_rebuild_indexes
	IS
	LC_REBUILD_INDEX  VARCHAR2(300);
	BEGIN
		gc_trcmsg:='8.a Entered into prc_rebuild_indexes'||chr(13);
		FOR I IN ( select
			'ALTER INDEX '||INDEX_NAME||' REBUILD  parallel 8 nologging' REBUILD_INDEX
			from ALL_INDEXES  where TABLE_NAME ='RPT_FCT_RPT_CLAIM_SUMMARY_R'
			AND INDEX_NAME NOT LIKE 'PK_%'
			AND INDEX_NAME NOT LIKE 'FK_%'
			AND STATUS='UNUSABLE'
			)
		LOOP
			LC_REBUILD_INDEX:=I.REBUILD_INDEX;
			EXECUTE IMMEDIATE LC_REBUILD_INDEX;
		END LOOP;
		gc_trcmsg:='8.z Exit from prc_rebuild_indexes'||chr(13);
	EXCEPTION
	WHEN OTHERS THEN
		gc_errmsg :=SUBSTR(SQLERRM,1,4000);
		gc_trcmsg:='8.z Error in prc_rebuild_indexes'||chr(13);

		/*START: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
			pkg_grp_log_util.prc_update_log_message_r
		(
			n_prcs_job_log_message_id_r => gn_job_log_message_id_r,
			p_err_msg => gc_trcmsg
		);
		/*END: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/

		pkg_grp_log_util.prc_update_log
			  (
				p_job_id => gn_out_job_id,
				p_job_status => gc_error_status,
				p_err_msg => gc_errmsg,
				p_trc_msg => chr(13) || gc_errmsg,
				p_log_util_called_by_r => gc_updby
			  );
		RAISE;
	END prc_rebuild_indexes;
END PKG_GRP_LOAD_RPT_FCT_RPT_CLAIM_SUMMARY_R;
/

