

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ATOMIC"."PKG_GRP_LOAD_RPT_CLAIM_SUM_R"
/***********************************************************************
  Purpose:  This package body contains procedures which loads data into RPT_CLAIM_SUM_R

  Author     	Date     	Description
  ---------- 	-------- 	-------------------------------------------------
  VGireesh   	10/11/23 	Initial Creation
  VGireesh   	17/01/24 	Duplicates issue did changes on claim_dir_r where clause
  VGireesh   	17/01/24 	Added blocks to update date sk's and n_current_face_amount_r after the load
  VGireesh   	18/01/24 	Product SK mapping change and enabled below functions
								i.	N_CLAIM_TOTAL_LOSS_AMT_R
								ii.	N_CLAIM_TOTAL_PAID_AMT_R
								iii.	N_CLAIM_TOTAL_GROSS_AMT_R
								iv.	N_CLAIM_TOTAL_NET_AMT_R
  VGireesh   	23/01/24 	Closed REF Cursor
  VGireesh   	29/01/24 	Added logic to update below columns using MV RPT_CLAIM_PAYMENT_DTL_AMT_MV_SSL
							n_claim_total_gross_amt_r
							N_CLAIM_TOTAL_LOSS_AMT_R
							N_CLAIM_TOTAL_PAID_AMT_R
							N_CLAIM_TOTAL_NET_AMT_R
							N_MOST_RECENT_NET_AMT_R
							N_CLAIM_TOTAL_TAX_AMT_R
  VGireesh   	22/02/24 	Added columns
							N_CURR_BEST_ESTIMATE_RESERVE_R
							N_CURR_GAAP_RESERVE_R
							N_CURR_STAT_RESERVE_R
							N_CURR_FIELD_RESERVE_R
							D_MOST_RECENT_RESERVE_VALUATION_DATE_R
  VGireesh   	26/02/24 	for month end  that the tables start loading data in the next month partition
							Ex: March data on February 29th (as of 2.28).
							27th is Feb Fisc Month End    202402  should be truncate and load in 202402 partition
							28th is feb Fisc Month End +1 202402  should be truncate and load in 202402 partition
							29th is Feb Fisc Month End +2 202403  should inactive records against the partition 202402 and load data in 202403 partition
  VGireesh   	04/03/24 		Populated columns
									N_CURR_BEST_ESTIMATE_RESERVE_R
									N_CURR_GAAP_RESERVE_R
									N_CURR_STAT_RESERVE_R
									N_CURR_FIELD_RESERVE_R
									D_MOST_RECENT_RESERVE_VALUATION_DATE_R
  VGireesh   	29/03/24 		added bloc to make unusable PK index to usable
  VGireesh   	03/04/24 		Added Parallel to rebuild index fast  parallel 16 nologging
  Chandra    	29/07/24 		Introduced RPT_POLICY_DTL_R_CLASSOFBUS_MV_SSL in The Cursor cur_upd_data due to Performance issue.
  VGireesh   	13/09/24 		Moved updates to another procedure prc_upd_cols
  VGireesh   	19/09/24 		Some updates which are not required for now has been commented in procedure prc_upd_cols
  VGireesh   	02/10/24 		Disabled yearmonth in the cursor CURSOR cur_reserveamt
								to fetch the latest reserve valuation date regardless of whether or not it’s the current month.
								Ex:Even though we’re loading 202410 in rpt_claim_sum_r, we don’t have the October data in the reserves table yet, so we should be loading September still.
  Chandra    	04/11/24 		Added N_CLAIM_MTD_LOSS_AMT_R,N_CLAIM_QTD_LOSS_AMT_R,N_CLAIM_YTD_LOSS_AMT_R Cols
  Beneshya	 	16/12/24 		Changed logic for N_CLAIM_GROSS_BENEFIT_AMOUNT_R column as part of webportal changes
 AnanthaJothi 	19/05/25 		Added N_CURRENT_RESERVE_R Column- Task 401492
  Samba		 	21/05/25  		Commented update flag = 'N' for Month End+2 Load.
								Added Truncate for Month End+2 Load
  Samba		 	26/05/25  		Added new logging Mechanism
  Suresh     	02/09/25 		Standardization of Code
									1. Variable Naming Convention:
										-- [scope][type]_[name]
										-- Scope: g = global, l = local
										-- Types: v = VARCHAR2, n = NUMBER, t = TIMESTAMP
										-- Examples: gv_name, ln_count, lt_created
										-- Use global vars (g_) only if shared across procedures.
										-- Prefer local vars (l_) for within a procedure.
										-- Keep names clear and concise.
									2. Using %TYPE for Variable declaration for all the Variables
									3. Using CONSTANT Key word if values do not change.
									4. Using PLS_INTEGER for all integer values
									5. Indentation of Code
									6. Do not use "_R" for the Variables declared within the Package
Anantha Jothi 	22/12/2025 		Added BE_AND_FIELD_MOST_RECENT_AS_OF_DATE field-444040

Shiva			07/05/2026		Kill/Fill Changes: User Story - 514601
								- All code changes are marked with Kill/Fill start and end comment blocks.
								- Code changes ensure continuous data availability in reports, replacing the current truncate-and-load approach, which is not partition-exchange based.
								- Retaining old code base of bulk collect load; which can be used when this Package to be converted to incremental processing

***********************************************************************/
IS
        --Global Constants
		gd_sysdate               CONSTANT DATE           											 := TRUNC(SYSDATE);
		gn_prior_month           PRCS_JOB_LOG_MESSAGE_R.N_COUNT_R%TYPE 					             := TO_NUMBER(TO_CHAR(ADD_MONTHS(TRUNC(gd_sysdate,'MM'),-1),'YYYYMM'));
		gn_current_month         PRCS_JOB_LOG_MESSAGE_R.N_COUNT_R%TYPE 					             := TO_NUMBER(TO_CHAR(gd_sysdate,'YYYYMM'));
		gn_sysdt_batchid         CONSTANT PRCS_JOB_LOG_MESSAGE_R.N_COUNT_R%TYPE 					 := TO_NUMBER(TO_CHAR(gd_sysdate,'YYYYMMDD'));
		gv_main_loadedby         CONSTANT PRCS_JOB_LOG_MESSAGE_R.V_CODE_LOCATION_R%TYPE				 := 'PKG_GRP_LOAD_RPT_CLAIM_SUM_R.MAIN';
		gv_updby                 CONSTANT PRCS_JOB_LOG_MESSAGE_R.V_CODE_LOCATION_R%TYPE				 := 'PKG_GRP_LOAD_RPT_CLAIM_SUM_R.PRC_UPD_DEL_DATA';
		gv_getcur_loadedby       CONSTANT PRCS_JOB_LOG_MESSAGE_R.V_CODE_LOCATION_R%TYPE				 := 'PKG_GRP_LOAD_RPT_CLAIM_SUM_R.PRC_GET_CUR_DATA';
		gv_truncpartby           CONSTANT PRCS_JOB_LOG_MESSAGE_R.V_CODE_LOCATION_R%TYPE				 := 'PKG_GRP_LOAD_RPT_CLAIM_SUM_R.PRC_TRUNC_PARTITION';
		gv_rebuildindexes        CONSTANT PRCS_JOB_LOG_MESSAGE_R.V_CODE_LOCATION_R%TYPE				 := 'PKG_GRP_LOAD_RPT_CLAIM_SUM_R.PRC_REBUILD_INDEXES';
        gv_upd_ind_cols_by       CONSTANT PRCS_JOB_LOG_MESSAGE_R.V_CODE_LOCATION_R%TYPE				 := 'PKG_GRP_LOAD_RPT_CLAIM_SUM_R.PRC_UPD_COLS';
		gv_job_name              CONSTANT PRCS_JOB_LOG_R.V_JOB_NAME_R%TYPE							 := 'GRP_LOAD_RPT_CLAIM_SUM_R';
		gv_running_status        CONSTANT PRCS_JOB_LOG_R.V_JOB_STATUS_R%TYPE  						 := 'Running';
		gv_error_status          CONSTANT PRCS_JOB_LOG_R.V_JOB_STATUS_R%TYPE    					 := 'Error';
		gv_success_status        CONSTANT PRCS_JOB_LOG_R.V_JOB_STATUS_R%TYPE  						 := 'Success';
		gv_source                CONSTANT PRCS_JOB_LOG_R.V_JOB_STATUS_R%TYPE 						 := 'EDW';
		gv_yes_ind               CONSTANT DIM_GRP_POLICY_DIR_R.v_active_status_r%TYPE				 := 'Y';
		gv_source_syst			 CONSTANT DIM_GRP_BILLING_POL_BILLGRP_R.v_source_system_name_r%TYPE	 := 'VUE';
		gv_message_type 	     CONSTANT PRCS_JOB_LOG_MESSAGE_R.v_message_type_r%TYPE  			 := PKG_GRP_LOG_UTIL.gc_message_type_info;
		gv_count_type    	     CONSTANT PRCS_JOB_LOG_MESSAGE_R.v_count_type_r%TYPE    			 := PKG_GRP_LOG_UTIL.gc_count_type_insert;
        gv_count_type_upd  	     CONSTANT PRCS_JOB_LOG_MESSAGE_R.v_count_type_r%TYPE    			 := PKG_GRP_LOG_UTIL.gc_count_type_update;
		gn_bulk_coll_cnt         CONSTANT PLS_INTEGER				                            	 := 100000;
        gn_run_cnt               PRCS_JOB_LOG_MESSAGE_R.N_COUNT_R%TYPE 	 				             := 0;
		gv_trcmsg                PRCS_JOB_LOG_MESSAGE_R.V_MESSAGE_R%TYPE;
		gt_start_time   	     PRCS_JOB_LOG_MESSAGE_R.D_CREATION_DATE_R %TYPE;
        gt_start_time_insd_lp    PRCS_JOB_LOG_MESSAGE_R.D_CREATION_DATE_R %TYPE;
		gt_end_time 		     PRCS_JOB_LOG_MESSAGE_R.D_CREATION_DATE_R %TYPE;
		gn_job_log_message_id    PRCS_JOB_LOG_MESSAGE_R.N_COUNT_R%TYPE;
		gn_error_line            PRCS_JOB_LOG_MESSAGE_R.v_message_type_r%TYPE;
		gn_out_job_id            PRCS_JOB_LOG_MESSAGE_R.N_JOB_ID_R%TYPE;
		gv_errmsg                PRCS_JOB_LOG_MESSAGE_R.V_MESSAGE_R%TYPE;
		gd_mis_date_be 			 DATE 																:= PKG_GRP_RESERVE_UTIL.get_valuation_date_best_estimate_r;
		--Start: kill/fill additions
		gv_rpt_table_name        CONSTANT PRCS_JOB_LOG_R.V_JOB_NAME_R%TYPE							 := 'RPT_CLAIM_SUM_R';
		gv_exg_table_name        CONSTANT PRCS_JOB_LOG_R.V_JOB_NAME_R%TYPE							 := gv_rpt_table_name||'_EXG';
		gv_schema_owner        	 CONSTANT PRCS_JOB_LOG_R.V_JOB_NAME_R%TYPE							 := 'ATOMIC';
		--End: kill/fill additions

PROCEDURE prc_get_cur_data -- PROCEDURE prc_get_cur_data( p_out_cursor OUT SYS_REFCURSOR ) -- Kill/Fill Changes 5th May 2026
/**************************************************************************************
  Purpose:  Procedure is used to get the latest data and perform ref_cursor assignment.

  Usage:	This procedure accepts one output parameters,output Variables: p_out_cursor: Used to perform ref cursor assignment

---------- -------- -------------------------------------------------
  VGireesh   10/11/23 		Developed first Version
  Suresh     25/08/25 		Standardization of Code
  Shiva		 07/05/2026		Kill/Fill: Added Partition Exchange to address reporitng data availability
*******************************************************************************/
AS
BEGIN

	gv_trcmsg := '5 - Entered into prc_get_cur_data ';
	gt_start_time := SYSTIMESTAMP;

	/*START: NEW LOGGING MECHANISM CHANGES*/
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
				( p_job_id_r                    => gn_out_job_id
				 ,p_batch_id_r                  => gn_sysdt_batchid
				 ,p_message_type_r              => gv_message_type
				 ,p_code_location_r             => gv_getcur_loadedby
				 ,p_message_r                   => gv_trcmsg
				 ,p_count_type_r                => NULL
				 ,p_count_r                     => NULL
				 ,p_duration_r                  => NULL
				 ,p_created_by_r                => gv_job_name
				 ,out_prcs_job_log_message_id_r => gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/

	-- Start : Kill/Fill Changes 5th May 2026
		EXECUTE IMMEDIATE 'ALTER SESSION ENABLE PARALLEL DML';
	-- End : Kill/Fill Changes 5th May 2026

	-- Start : Kill/Fill Changes 5th May 2026: Commented following
	--Open/Assign SELECT stmnt
      /*  OPEN P_OUT_CURSOR
            FOR
             SELECT */ /*+PARALLEL(4)*/
	-- End : Kill/Fill Changes 5th May 2026 : Commented following

	-- Start : Kill/Fill Changes 5th May 2026: Added following
    INSERT /*+ APPEND PARALLEL(stg, 8) */ INTO RPT_CLAIM_SUM_R_EXG stg
    SELECT /*+ PARALLEL(8) */
	-- End : Kill/Fill Changes 5th May 2026: Added following
                    COALESCE(DGPR_1.n_product_sk_r, DGPR.n_product_sk_r, - 1)                             AS n_product_sk_r,
                    NVL(DER.n_employee_sk_r, - 1)                                                         AS n_employee_sk_r,
                    CAST(NULL AS NUMBER)                                                                  AS n_associated_wop_cnt_r,
                    NVL(FGWST.n_gross_benefit_r, FGWST_1.v_net_indicator_r)                               AS n_claim_gross_benefit_amount_r,
                    FGWST.n_rpt_net_benefit_r                                                             AS n_net_benefit_r,
                    CAST(NULL AS NUMBER)                                                                  AS n_claim_total_gross_amt_r,
                    CAST(NULL AS NUMBER)                                                                  AS n_claim_total_loss_amt_r,
                    CAST(NULL AS NUMBER)                                                                  AS n_claim_total_net_amt_r,
                    CAST(NULL AS NUMBER)                                                                  AS n_claim_total_tax_amt_r,
                    CAST(NULL AS NUMBER)                                                                  AS n_claim_total_paid_amt_r,
                    CAST(NULL AS NUMBER)                                                                  AS n_current_face_amount_r,
                    CAST(NULL AS NUMBER)                                                                  AS n_est_loss_amount_r,
                    CAST(NULL AS NUMBER)                                                                  AS n_most_recent_gross_amount_r,
                    CAST(NULL AS NUMBER)                                                                  AS n_most_recent_net_amt_r,
                    CAST(NULL AS NUMBER)                                                                  AS n_most_recent_tax_amt_r,
                    DGCCGR.n_reserve_amount_r                                                             AS n_original_face_amount_r,
                    DGCCR.n_reinsurance_pct_r                                                             AS n_reinsurance_value_r,
                    FCSIR.n_ss_dep_award_amount_r                                                         AS n_ss_dep_award_amount_r,
                    FCSIR.n_ss_est_monthly_benefit_r                                                      AS n_ss_est_monthly_benefit_r,
                    FCSIR.n_ss_primary_award_amount_r                                                     AS n_ss_primary_award_amount_r,
                    FCSIR.n_ss_hardship_ind_r                                                             AS n_ss_hardship_ind_r,
                    gv_main_loadedby                                                                      AS v_last_modified_by_r,
                    systimestamp                                                                          AS t_creation_date_r,
                    gv_main_loadedby                                                                      AS v_created_by_r,
                    systimestamp                                                                          AS t_last_modified_date_r,
                    gn_current_month                                                                      AS n_yearmonth_r,
                    DGCDR.v_active_status_r                                                               AS v_rpt_active_status_r,
                    gn_sysdt_batchid                                                                      AS n_batch_id_r,
                    - 1                                                                                   AS n_worksheet_sk_r,
                    NVL(FGPRMS.n_cust_party_sk_r, - 1)                                                    AS n_cust_party_sk_r,
                    NVL(DGCR.n_insrd_party_sk_r, - 1)                                                     AS n_insrd_party_sk_r,
                    NVL(DGCCGR.n_claim_coverage_group_sk_r, - 1)                                          AS n_claim_coverage_group_sk_r,
                    NVL(DGCCR.n_claim_coverage_sk_r, - 1)                                                 AS n_claim_coverage_sk_r,
                    NVL(DGCDR.n_claim_sk_r, - 1)                                                          AS n_claim_sk_r,
                    NVL(DGCDR.n_policy_sk_r, - 1)                                                         AS n_policy_sk_r,
                    CAST(NULL AS NUMBER)                                                                  AS n_claim_closed_date_sk_r,
                    CAST(NULL AS NUMBER)                                                                  AS n_loss_date_sk_r,
                    CAST(NULL AS NUMBER)                                                                  AS n_claim_received_date_sk_r,
                    CAST(NULL AS NUMBER)                                                                  AS n_policy_id_r,
                    DGCR.d_closure_date_r                                                                 AS d_closure_date_r,
                    DGCR.d_date_of_loss_r                                                                 AS d_date_of_loss_r,
                    DGBARM.received_date                                                                  AS d_received_date_r,
                    DGCDR.v_lob_type_r                                                                    AS v_lob_type_r,
                    DGCCGR.n_ws_released_amount_r                                                         AS n_ws_released_amount_r,
                    CAST(NULL AS NUMBER)                                                                  AS n_curr_best_estimate_reserve_r,
                    CAST(NULL AS NUMBER)                                                                  AS n_curr_gaap_reserve_r,
                    CAST(NULL AS NUMBER)                                                                  AS n_curr_stat_reserve_r,
                    CAST(NULL AS NUMBER)                                                                  AS n_curr_field_reserve_r,
                    CAST(NULL AS DATE)                                                                    AS d_most_recent_reserve_valuation_date_r,
                    CAST(NULL AS NUMBER)                                                                  AS n_claim_mtd_loss_amt_r,
                    CAST(NULL AS NUMBER)                                                                  AS n_claim_qtd_loss_amt_r,
                    CAST(NULL AS NUMBER)                                                                  AS n_claim_ytd_loss_amt_r,
                    CAST(NULL AS NUMBER)                                                                  AS n_current_reserve_r,
					gd_mis_date_be 						                                                  AS BE_AND_FIELD_MOST_RECENT_AS_OF_DATE
                FROM
                    ( SELECT n_claim_sk_r
                           , n_policy_sk_r
                           , v_lob_type_r
                           , v_claim_number_r
                           , v_active_status_r
                        FROM ATOMIC.DIM_GRP_CLAIM_DIR_R
                       WHERE v_active_status_r = 'Y'
                    )  DGCDR
                    LEFT JOIN ATOMIC.DIM_GRP_CLAIM_COVERAGE_R DGCCR
                           ON DGCDR.n_claim_sk_r = DGCCR.n_claim_sk_r
                          AND DGCCR.v_active_status_r = 'Y'
                    LEFT JOIN ATOMIC.DIM_GRP_CLAIM_COVERAGE_GROUP_R DGCCGR
                           ON DGCCR.n_claim_coverage_sk_r = DGCCGR.n_claim_coverage_sk_r
                          AND DGCCGR.v_active_status_r    = 'Y'
                    LEFT JOIN ATOMIC.DIM_GRP_POLICY_DIR_R DGPDR
                           ON DGCDR.n_policy_sk_r = DGPDR.n_policy_sk_r
                          AND DGPDR.v_active_status_r = 'Y'
                    LEFT JOIN ATOMIC.DIM_GRP_CLAIM_DETAIL_R  DGCR
                           ON DGCDR.n_claim_sk_r = DGCR.n_claim_sk_r
                          AND DGCR.v_active_status_r = 'Y'
                    LEFT JOIN ATOMIC.DIM_EMPLOYEE_R DER
                           ON DGCR.v_examiner_login_id_r = DER.v_employee_login_id_r
                          AND DER.v_business_unit_r = 'Claims'
                    LEFT JOIN ATOMIC.FCT_GRP_POLICY_R_MV_SSL FGPRMS
                           ON DGPDR.n_policy_sk_r = FGPRMS.n_policy_sk_r
                          AND DGPDR.n_policy_version_number_r = FGPRMS.n_version_number_r
                    LEFT JOIN ATOMIC.FCT_CLAIM_SOCIALSECURITY_INC_R FCSIR
                           ON DGCDR.n_claim_sk_r = FCSIR.n_claim_sk_r
                    LEFT JOIN ATOMIC.MVW_PRODUCT_SK_LOOKUP_MIN_MV_SSL MPSLMMS
                           ON MPSLMMS.n_claim_sk_r = DGCDR.n_claim_sk_r
                          AND MPSLMMS.v_claim_coverage_code_r = DGCCR.v_claim_coverage_code_r
                    LEFT JOIN ATOMIC.DIM_GRP_PRODUCT_R DGPR
                           ON MPSLMMS.n_product_sk_r = DGPR.n_product_sk_r
                    LEFT JOIN ATOMIC.MVW_PRODUCT_SK_LOOKUP_MIN_MV_SSL MPSLMMS_1
                           ON MPSLMMS_1.n_claim_sk_r = DGCDR.n_claim_sk_r
                          AND MPSLMMS_1.v_claim_coverage_code_r = DGCCGR.v_claim_coverage_code_r
                    LEFT JOIN ATOMIC.DIM_GRP_PRODUCT_R DGPR_1
                           ON DGPR_1.n_product_sk_r = MPSLMMS_1.n_product_sk_r
                    LEFT JOIN ATOMIC.FCT_GRP_WORKSHEET FGWST
                           ON FGWST.n_claim_sk_r = DGCDR.n_claim_sk_r
                          AND FGWST.n_claim_coverage_sk_r = DGCCR.n_claim_coverage_sk_r
                          AND FGWST.v_rpt_worksheet_indicator_r = 'Y'
                    LEFT JOIN ( SELECT n_claim_sk_r                                  AS n_claim_sk_r
                                     , n_claim_coverage_group_sk_r                   AS n_claim_coverage_group_sk_r
                                     , SUM(CAST(v_net_indicator_r AS NUMBER(20, 5))) AS v_net_indicator_r
                                     , v_source_system_name_r                        AS v_source_system_name_r
                                 FROM ATOMIC.FCT_GRP_WORKSHEET
                                WHERE v_source_system_name_r = 'CV'
                                GROUP BY n_claim_sk_r
                                       , n_claim_coverage_group_sk_r
                                       , v_source_system_name_r
                               ) FGWST_1
                           ON FGWST_1.n_claim_sk_r = DGCDR.n_claim_sk_r
                          AND FGWST_1.n_claim_coverage_group_sk_r = DGCCGR.n_claim_coverage_group_sk_r
                    LEFT JOIN ATOMIC.DIM_GRP_BUSOBJ_AUDIT_R_MAX_RCV_MV_SSL DGBARM
                           ON DGBARM.v_claim_number_r = DGCDR.v_claim_number_r
						  -- fetch first 10 rows only
						   ;

    gn_run_cnt      := SQL%ROWCOUNT;

	-- Start : Kill/Fill Changes 5th May 2026: Commented following
	COMMIT;
	EXECUTE IMMEDIATE 'ALTER SESSION DISABLE PARALLEL DML';
	-- End : Kill/Fill Changes 5th May 2026

	gv_trcmsg       := '5.z - Exit from prc_get_cur_data - Rows Loaded :->'||gn_run_cnt;
	gt_end_time 	:= SYSTIMESTAMP;

	/*START: NEW LOGGING MECHANISM CHANGES*/
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
				( p_job_id_r                    => gn_out_job_id
				 ,p_batch_id_r                  => gn_sysdt_batchid
				 ,p_message_type_r              => gv_message_type
				 ,p_code_location_r             => gv_getcur_loadedby
				 ,p_message_r                   => gv_trcmsg
				 ,p_count_type_r                => gv_count_type
				 ,p_count_r                     => gn_run_cnt
				 ,p_duration_r                  => FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
				 ,p_created_by_r                => GV_JOB_NAME
				 ,out_prcs_job_log_message_id_r => gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/


EXCEPTION
WHEN OTHERS THEN
    gv_errmsg :=SUBSTR(SQLERRM,1,4000);
    gv_trcmsg:='5.z - Error in prc_get_cur_data: '||gv_errmsg;

	/*START: NEW LOGGING MECHANISM CHANGES*/
    pkg_grp_log_util.prc_update_log_message_r
			   (   n_prcs_job_log_message_id_r  => gn_job_log_message_id
				  ,p_err_msg                    => gv_trcmsg
					   );
    /*END: NEW LOGGING MECHANISM CHANGES*/

    pkg_grp_log_util.prc_update_log
			  (   p_job_id  					=> gn_out_job_id
				 ,p_job_status					=> gv_error_status
				 ,p_err_msg						=> gv_errmsg
				 ,p_trc_msg						=> gv_trcmsg
				 ,p_log_util_called_by_r		=> gv_getcur_loadedby
			  );
    RAISE;
END prc_get_cur_data;

PROCEDURE MAIN
/***********************************************************************
  Purpose:  This procedure controls the overall process and calls the child
            procedures needed

  Author     Date     Description
  ---------- -------- ----------------------------------------------------------
  VGireesh   10/11/23 	Developed first Version
  Suresh     25/08/25 	Standardization of Code
							1. Main uses following Procedures and functions which are called from the package PKG_GRP_COMMON_UTIL
								1. PRC_UPD_DEL_DATA updates the Prior Month active status to 'N' and also does the Truncate Partition
								2. PRC_REBUILD_INDEXES to rebuild indexes after they were disabled for performance improvement
								3. FNC_GRP_TIME_DURATION, this functions calculates the duration between start & end time of a step
								   and returns the Number of seconds.
							2. Main uses following functions which are called from the package PKG_GRP_LOG_UTIL
								1. PRC_INSTERT_LOG, This procedure creates log entry in the log table with status In-Progress.
								2. PRC_UPDATE_LOG, This procedure updates the log entry in the log table with the following status
											Success - Upon successful completion
											Error - If encounters any error
								3. prc_ins_prcs_job_log_message_r provides the standard process to Insert the Process Job Log Message record
							3. standardizing the Local Variables used - For the standardizing steps refer the master comment block from Package Body
							4. Declare all the Local variables

  Shiva		 08-May-2026	Kill/Fill: Added Partition Exchange to address reporitng data availability
*******************************************************************************/
IS

        TYPE lt_var_tbl_type IS TABLE OF RPT_CLAIM_SUM_R%ROWTYPE INDEX BY BINARY_INTEGER;
		lt_var_tbl_type_rec lt_var_tbl_type;
		lc_var_ref_cur 		SYS_REFCURSOR;
        lt_insert_time	    PRCS_JOB_LOG_MESSAGE_R.D_CREATION_DATE_R %TYPE  ;
        lv_rpt_table 		PRCS_JOB_LOG_R.CREATED_BY_R%TYPE 			    :='RPT_CLAIM_SUM_R';
		ln_loop_counter     PLS_INTEGER                          		    := 1;
		ln_rec_cnt 			PLS_INTEGER									    := 0;
		ln_idx_num			PLS_INTEGER									    := 8;
        ld_fic_mis_date_2 DATE;
        ln_fisc_current_month NUMBER;
BEGIN

	--Call Log Util pkg to Insert entry in PRCS_JOB_LOG_R
	--For more details how this procedure is being used, refer the Main Procedure comment block.
	pkg_grp_log_util.PRC_INSERT_LOG
					( p_source              		=> gv_source
					 ,p_job_nm               		=> gv_job_name
					 ,p_job_status           		=> gv_running_status
					 ,p_err_msg              		=> NULL
					 ,p_trc_msg              		=> NULL
					 ,p_n_batch_id           		=> gn_sysdt_batchid
					 ,p_log_util_called_by_r 		=> gv_main_loadedby
					 ,out_job_id             		=> gn_out_job_id
					);

	gv_trcmsg:='1. Entered into Main';
    /*START: NEW LOGGING MECHANISM CHANGES*/
	 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
				   ( p_job_id_r                  	=> gn_out_job_id
					,p_batch_id_r               	=> gn_sysdt_batchid
					,p_message_type_r            	=> gv_message_type
					,p_code_location_r            	=> gv_main_loadedby
					,p_message_r                  	=> gv_trcmsg
					,p_count_type_r               	=> NULL
					,p_count_r                    	=> NULL
					,p_duration_r                 	=> NULL
					,p_created_by_r               	=> GV_JOB_NAME
					,out_prcs_job_log_message_id_r	=> gn_job_log_message_id
					);
    /*END: NEW LOGGING MECHANISM CHANGES*/

    ---2. Call procedure prc_upd_del_data to update active status to N for the records in Fisc prior month
  /*  ---Also, Truncate the current Partion month data if any data present already.
    PKG_GRP_COMMON_UTIL.prc_upd_del_data
					( p_out_job_id	 				=> gn_out_job_id
					 ,p_rpt_table 					=> lv_rpt_table
					 ,p_upd_flag 					=> gv_yes_ind
					 ,p_idx_num						=> ln_idx_num
					 ,p_log_seq_num					=> 2
					 ,p_idx_unusable				=> NULL
					 );
                     */
   /*Common Utility Proc to get month end+2 date and month. Ex: If month end is 29-Aug-2025 then ln_fisc_current_month will be 202509*/
	PKG_GRP_COMMON_UTIL.prc_fisc_month_calc
	(
		p_out_job_id            =>	gn_out_job_id,
        p_Log_seq_num           =>	2,
		ln_fisc_current_month   =>	ln_fisc_current_month,
		ld_fic_mis_date_2       =>	ld_fic_mis_date_2
	);

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

 -- Start: commented as part of Kill/Fill Process : 5th May 2026 : Commenting this part
    /*Common Utility Proc to truncate partition */
	/*PKG_GRP_COMMON_UTIL.prc_trunc_partition
	(
		p_out_job_id    	=>	gn_out_job_id,
		p_Log_seq_num   	=>	4,
		p_rpt_table     	=>	lv_rpt_table,  --gc_rpt_table_name  to lv_rpt_table
		p_idx_num       	=>	ln_idx_num ,   --gc_rebuild_idx_degree to ln_idx_num
		p_current_month     =>	gn_current_month
	);*/
-- End: commented as part of Kill/Fill Process : 5th May 2026 : Commenting this part

 -- Start: commented as part of Kill/Fill Process : 5th May 2026 : Added New
	-- Call common Utility Package to create a exchange table if its not present else create new exg table with NoLogging

	/*EXECUTE IMMEDIATE 'DROP TABLE RPT_CLAIM_SUM_R_EXG CASCADE CONSTRAINTS';
	EXECUTE IMMEDIATE 'CREATE TABLE RPT_CLAIM_SUM_R_EXG FOR EXCHANGE WITH TABLE RPT_CLAIM_SUM_R';
	EXECUTE IMMEDIATE 'ALTER TABLE RPT_CLAIM_SUM_R_EXG ADD CONSTRAINT PK_8899_EXG PRIMARY KEY (N_YEARMONTH_R, N_CLAIM_COVERAGE_GROUP_SK_R, N_CLAIM_COVERAGE_SK_R, N_CLAIM_SK_R, N_POLICY_SK_R, N_WORKSHEET_SK_R, N_CUST_PARTY_SK_R, N_INSRD_PARTY_SK_R, N_EMPLOYEE_SK_R, N_PRODUCT_SK_R) DISABLE';
	EXECUTE IMMEDIATE 'ALTER TABLE RPT_CLAIM_SUM_R_EXG ADD CONSTRAINT R_7620_EXG FOREIGN KEY (N_YEARMONTH_R, N_WORKSHEET_SK_R) REFERENCES ATOMIC.RPT_WORKSHEET_DTL_R (N_YEARMONTH_R, N_WORKSHEET_SK_R) DISABLE'	;
	EXECUTE IMMEDIATE 'ALTER TABLE RPT_CLAIM_SUM_R_EXG ADD CONSTRAINT R_7624_EXG FOREIGN KEY (N_YEARMONTH_R, N_CUST_PARTY_SK_R, N_POLICY_SK_R) REFERENCES ATOMIC.RPT_POLICY_DTL_R (N_YEARMONTH_R, N_CUST_PARTY_SK_R, N_POLICY_SK_R) ON DELETE SET NULL DISABLE'	;
	*/
	PKG_GRP_COMMON_UTIL.PRC_CREATE_EXCHANGE_TABLE_DDL
		(
			p_job_id            	=> gn_out_job_id,
			p_log_seq_num           => 5,
			p_main_table_name       => gv_rpt_table_name,
			p_exg_table_name        => gv_exg_table_name,
			p_schema_name           => gv_schema_owner
		);
-- End: commented as part of Kill/Fill Process : 5th May 2026 : Added New

   ---4. Call prc_get_cur_data to get the latest data and perform ref_cursor assignment.
	prc_get_cur_data; 						/* Added as part of Kill/Fill Process : 5th May 2026 	 */

-- Start: commented as part of Kill/Fill Process : 5th May 2026
/*	prc_get_cur_data (lc_var_ref_cur); 	-- commented as part of Kill/Fill Process : 5th May 2026

    gv_trcmsg:='6.Start Data Load.';

	gt_start_time:= SYSTIMESTAMP;

	--START: NEW LOGGING MECHANISM CHANGES
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
					(
					 p_job_id_r                    => gn_out_job_id
					,p_batch_id_r                  => gn_sysdt_batchid
					,p_message_type_r              => gv_message_type
					,p_code_location_r             => gv_main_loadedby
					,p_message_r                   => gv_trcmsg
					,p_count_type_r                => NULL
					,p_count_r                     => NULL
					,p_duration_r                  => NULL
					,p_created_by_r                => GV_JOB_NAME
					,out_prcs_job_log_message_id_r => gn_job_log_message_id
					);
    --END: NEW LOGGING MECHANISM CHANGES

        LOOP
	      lt_var_tbl_type_rec.DELETE;

        FETCH lc_var_ref_cur
			  bulk collect
              into lt_var_tbl_type_rec
             limit GN_BULK_COLL_CNT;
             lt_insert_time  := systimestamp ;
             FOR i IN 1..lt_var_tbl_type_rec.COUNT
            LOOP
                lt_var_tbl_type_rec(i).t_creation_date_r := lt_insert_time ; -- Assign unique timestamp to each record
                lt_insert_time :=lt_insert_time + interval '0.000001' SECOND;
            END LOOP;

		gt_start_time_insd_lp := SYSTIMESTAMP; -- Start timing before the insert
      FORALL X in lt_var_tbl_type_rec.first..lt_var_tbl_type_rec.last
			INSERT */ /*+APPEND_VALUES*/ /* INTO RPT_CLAIM_SUM_R VALUES lt_var_tbl_type_rec(x) ;
			commit;

		gt_end_time := SYSTIMESTAMP; -- End timing after the insert
		ln_rec_cnt  := ln_rec_cnt + lt_var_tbl_type_rec.COUNT;
		gv_trcmsg   := '6.1: Data loaded: Bulk Set - '|| ln_loop_counter || ': ' || ln_rec_cnt || ' records loaded' ;

		-- START: NEW LOGGING MECHANISM CHANGES
	    PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
			   ( p_job_id_r 					=> gn_out_job_id
				,p_batch_id_r					=> gn_sysdt_batchid
				,p_message_type_r 				=> gv_message_type
				,p_code_location_r 				=> gv_main_loadedby
				,p_message_r 					=> gv_trcmsg
				,p_count_type_r 				=> gv_count_type
				,p_count_r 						=> ln_rec_cnt
				,p_duration_r 					=> FNC_GRP_TIME_DURATION(gt_start_time_insd_lp,gt_end_time)
				,p_created_by_r 				=> Gv_JOB_NAME
				,out_prcs_job_log_message_id_r	=> gn_job_log_message_id
				);
		--END: NEW LOGGING MECHANISM CHANGES

		ln_loop_counter := ln_loop_counter + 1;
      EXIT WHEN lc_var_ref_cur%NOTFOUND;
     END LOOP;
	CLOSE lc_var_ref_cur;

	gv_trcmsg :='6.2:Completed Data Loaded.Total '||ln_rec_cnt||' records.';

     --START: NEW LOGGING MECHANISM CHANGES
        gt_end_time := SYSTIMESTAMP;
        PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
                (    p_job_id_r                    => gn_out_job_id
                    ,p_batch_id_r                  => gn_sysdt_batchid
                    ,p_message_type_r              => gv_message_type
                    ,p_code_location_r             => gv_main_loadedby
                    ,p_message_r                   => gv_trcmsg
                    ,p_count_type_r                => gv_count_type
                    ,p_count_r                     => ln_rec_cnt
                    ,p_duration_r                  => FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
                    ,p_created_by_r                => GV_JOB_NAME
                    ,out_prcs_job_log_message_id_r => gn_job_log_message_id
                    );
        --END: NEW LOGGING MECHANISM CHANGES

	*/
-- End: commented as part of Kill/Fill Process : 5th May 2026

	-- Start : Kill/Fill Changes 5th May 2026 	: Added New
	-- Partition Exchange Common Utility Called to Move data from Exg table to the Main table Current month Partition
	PKG_GRP_COMMON_UTIL.PRC_PARTITION_EXCHANGE
	(
		p_job_id            	=> gn_out_job_id,
		p_log_seq_num           => 6,
		p_main_table_name       => gv_rpt_table_name,
		p_exg_table_name        => gv_exg_table_name,
		p_partition_name        => 'PART_'|| gv_rpt_table_name ||'_'||gn_current_month,
		p_schema_name           => gv_schema_owner
	);



	-- Rebuild Index for the Partition, post partition Exchange
	PKG_GRP_COMMON_UTIL.prc_rebuild_index_partitions
	(
		p_table_name   		  		  => gv_rpt_table_name,
		p_parallel_degree   		  => 8,
		p_partition_name  		  	  => 'PART_'|| gv_rpt_table_name ||'_'||gn_current_month,
		p_out_job_id              	  => gn_out_job_id,
		p_Log_seq_num             	  => 7
	);

	-- End : Kill/Fill Changes 5th May 2026 : Added New


/* Added by Ishita */
/* Month-end conditional TABLE stats for ATOMIC.RPT_CLAIM_SUM_R (NO index stats) */
DECLARE
  lc_batch_id        VARCHAR2(40);
  ld_fic_mis_date    DATE;
  lc_batch_id_date   DATE;
  ln_stats_degree PLS_INTEGER := 8;
BEGIN
  /* 1st action: Select BatchId */
  SELECT v_batch_id_r
    INTO lc_batch_id
    FROM atomic.prcs_grp_date_param_r
   WHERE v_process_name_r = 'PACS_BATCH_ID';
  /* 2nd action: Get fiscal month-end (+1) date for the BatchId month */
  SELECT d_calendar_date_r + 1
    INTO ld_fic_mis_date
    FROM atomic.dim_time_r d
   WHERE v_end_of_fiscal_month_ind_r = 'Y'
     AND TO_CHAR(d_calendar_date_r, 'YYYYMM') =
         TO_CHAR(TO_DATE(SUBSTR(lc_batch_id, 1, 8), 'YYYYMMDD'), 'YYYYMM');
  /* Batch date (+1) to align with month-end+1 gating */
  lc_batch_id_date := TO_DATE(SUBSTR(lc_batch_id, 1, 8), 'YYYYMMDD') + 1;
  /* 3rd action: If fiscal month end equals current BatchId date, run TABLE stats */
  IF TRUNC(ld_fic_mis_date) = TRUNC(lc_batch_id_date) THEN
     gv_trcmsg := 'Month-end detected. Running TABLE stats (no index stats) for ATOMIC.RPT_CLAIM_SUM_R. BatchId='||lc_batch_id;
     PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
        p_job_id_r         => gn_out_job_id,
        p_batch_id_r       => gn_sysdt_batchid,
        p_message_type_r   => gv_message_type,
        p_code_location_r  => gv_upd_ind_cols_by,
        p_message_r        => gv_trcmsg,
        p_count_type_r     => NULL,
        p_count_r          => NULL,
        p_duration_r       => NULL,
        p_created_by_r     => gv_job_name,
        out_prcs_job_log_message_id_r => gn_job_log_message_id
     );
     /* 4th action: Gather TABLE stats ONLY (cascade=>FALSE prevents index stats) */
     DBMS_STATS.GATHER_TABLE_STATS(
        ownname          => 'ATOMIC',
        tabname          => 'RPT_CLAIM_SUM_R',
        estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE,
        method_opt       => 'FOR ALL COLUMNS SIZE AUTO',
        degree           => ln_stats_degree,
        granularity      => 'GLOBAL',
        cascade          => FALSE,
        no_invalidate    => DBMS_STATS.AUTO_INVALIDATE
     );
     gv_trcmsg := 'Completed TABLE stats (no index stats) for ATOMIC.RPT_CLAIM_SUM_R';
     PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
        p_job_id_r         => gn_out_job_id,
        p_batch_id_r       => gn_sysdt_batchid,
        p_message_type_r   => gv_message_type,
        p_code_location_r  => gv_upd_ind_cols_by,
        p_message_r        => gv_trcmsg,
        p_count_type_r     => NULL,
        p_count_r          => NULL,
        p_duration_r       => NULL,
        p_created_by_r     => gv_job_name,
        out_prcs_job_log_message_id_r => gn_job_log_message_id
     );
  ELSE
     gv_trcmsg := 'Not month-end. Skipping TABLE stats for ATOMIC.RPT_CLAIM_SUM_R. MonthEndDate='||
                  TO_CHAR(ld_fic_mis_date,'YYYY-MM-DD')||', BatchDate='||TO_CHAR(lc_batch_id_date,'YYYY-MM-DD');
     PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
        p_job_id_r         => gn_out_job_id,
        p_batch_id_r       => gn_sysdt_batchid,
        p_message_type_r   => gv_message_type,
        p_code_location_r  => gv_upd_ind_cols_by,
        p_message_r        => gv_trcmsg,
        p_count_type_r     => NULL,
        p_count_r          => NULL,
        p_duration_r       => NULL,
        p_created_by_r     => gv_job_name,
        out_prcs_job_log_message_id_r => gn_job_log_message_id
     );
  END IF;
EXCEPTION
  WHEN OTHERS THEN
     gv_trcmsg := 'FAILED month-end TABLE stats for ATOMIC.RPT_CLAIM_SUM_R: '||SUBSTR(SQLERRM,1,4000);
     PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
        p_job_id_r         => gn_out_job_id,
        p_batch_id_r       => gn_sysdt_batchid,
        p_message_type_r   => gv_message_type,
        p_code_location_r  => gv_upd_ind_cols_by,
        p_message_r        => gv_trcmsg,
        p_count_type_r     => NULL,
        p_count_r          => NULL,
        p_duration_r       => NULL,
        p_created_by_r     => gv_job_name,
        out_prcs_job_log_message_id_r => gn_job_log_message_id
     );
     RAISE; -- fail fast
END;
		/*START: NEW LOGGING MECHANISM CHANGES*/
	gv_trcmsg:= '10. - Exit from main';
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
            (	 p_job_id_r                    => gn_out_job_id
				,p_batch_id_r                  => gn_sysdt_batchid
				,p_message_type_r              => gv_message_type
				,p_code_location_r             => gv_main_loadedby
				,p_message_r                   => gv_trcmsg
				,p_count_type_r                => NULL
				,p_count_r                     => NULL
				,p_duration_r                  => NULL
				,p_created_by_r                => Gv_JOB_NAME
				,out_prcs_job_log_message_id_r => gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/

    pkg_grp_log_util.prc_update_log
			  (   p_job_id  					=> gn_out_job_id
				 ,p_job_status					=> gv_success_status
				 ,p_err_msg						=> gv_errmsg
				 ,p_trc_msg						=> gv_trcmsg
				 ,p_log_util_called_by_r		=> gv_main_loadedby
			  );

EXCEPTION
WHEN OTHERS THEN

	gv_errmsg :=SUBSTR(SQLERRM,1,4000);
    gv_trcmsg:='1.Z Error in main: '||gv_errmsg;

	/*START: NEW LOGGING MECHANISM CHANGES*/
    pkg_grp_log_util.prc_update_log_message_r
			   (   n_prcs_job_log_message_id_r  => gn_job_log_message_id
				  ,p_err_msg                    => gv_trcmsg
					   );
    /*END: NEW LOGGING MECHANISM CHANGES*/

    pkg_grp_log_util.prc_update_log
			  (   p_job_id  					=> gn_out_job_id
				 ,p_job_status					=> gv_error_status
				 ,p_err_msg						=> gv_errmsg
				 ,p_trc_msg						=> gv_trcmsg
				 ,p_log_util_called_by_r		=> gv_main_loadedby
			  );

    RAISE;
END MAIN;

PROCEDURE prc_upd_cols
IS

CURSOR cur_upd_data
 IS
  SELECT /*+PARALLEL(4)*/
	     RPT_CLAIM_SUM_R.ROWID                     AS ROW_ID
	   , RPT_CLAIM_SUM_R.n_policy_sk_r             AS N_POLICY_SK_R
	   , NVL(RPT_CLAIM_SUM_R.v_lob_type_r ,'@')    AS V_LOB_TYPE_R
	   , RPT_CLAIM_SUM_R.N_ORIGINAL_FACE_AMOUNT_R  AS N_RESERVE_AMOUNT_R
	   , RPT_CLAIM_SUM_R.n_ws_released_amount_r    AS N_WS_RELEASED_AMOUNT_R
	   , (RPT_CLAIM_SUM_R.N_ORIGINAL_FACE_AMOUNT_R
        - RPT_CLAIM_SUM_R.N_WS_RELEASED_AMOUNT_R
          )                                        AS N_LIFE_WOP_AMT_R
	   , CAST(NULL AS NUMBER)                      AS N_CURRENT_FACE_AMOUNT_R
	--29/07/24 Changes starts
	   ,(SELECT /*+PARALLEL(4)*/
                V_CLASS_OF_BUSINESS_R
		   FROM RPT_POLICY_DTL_R_CLASSOFBUS_MV_SSL rpt_policy_dtl_r
		  WHERE RPT_POLICY_DTL_R.N_POLICY_SK_R = RPT_CLAIM_SUM_R.N_POLICY_SK_R
	   GROUP BY V_CLASS_OF_BUSINESS_R
	    )                                          AS V_CLASS_OF_BUSINESS_R
	--29/07/24 Changes End
	FROM RPT_CLAIM_SUM_R
   WHERE N_YEARMONTH_R=GN_CURRENT_MONTH ;

  TYPE var_upd_tbl_type3 IS TABLE OF cur_upd_data%ROWTYPE INDEX BY BINARY_INTEGER;
  lt_var_upd_tbl_typ3 var_upd_tbl_type3;

--29-Jan-2024 changes starts
CURSOR cur_get_amt
 IS
	SELECT N_CLAIM_TOTAL_GROSS_AMT_R
		 , N_CLAIM_TOTAL_LOSS_AMT_R
		 , N_CLAIM_TOTAL_NET_AMT_R
		 , N_CLAIM_TOTAL_TAX_AMT_R
		 , N_CLAIM_COVERAGE_GROUP_SK_R
		 , N_CLAIM_COVERAGE_SK_R
		 , N_CLAIM_SK_R
		 , N_YEARMONTH_R
		 --04/11/24 Changes start
		 , N_CLAIM_MTD_LOSS_AMT_R
		 , N_CLAIM_QTD_LOSS_AMT_R
		 , N_CLAIM_YTD_LOSS_AMT_R
		 --04/11/24 Changes start
	 FROM RPT_CLAIM_PAYMENT_DTL_AMT_MV_SSL			A
	WHERE N_YEARMONTH_R = GN_CURRENT_MONTH
	--19-Sep-2024 changes starts
      AND EXISTS(SELECT 1
                   FROM RPT_CLAIM_SUM_R
                  WHERE RPT_CLAIM_SUM_R.N_CLAIM_COVERAGE_GROUP_SK_R = A.N_CLAIM_COVERAGE_GROUP_SK_R
                    AND RPT_CLAIM_SUM_R.N_CLAIM_COVERAGE_SK_R       =A.N_CLAIM_COVERAGE_SK_R
                    AND RPT_CLAIM_SUM_R.N_CLAIM_SK_R                = A.N_CLAIM_SK_R
                    AND RPT_CLAIM_SUM_R.N_YEARMONTH_R               =GN_CURRENT_MONTH
              );
--19-Sep-2024 changes ends

TYPE var_upd_tbl_amt_type IS TABLE OF cur_get_amt%ROWTYPE INDEX BY BINARY_INTEGER;
lt_var_upd_tbl_amt_typ var_upd_tbl_amt_type;
--29-Jan-2024 changes ends
--04-Mar-2023 changes starts
CURSOR cur_reserveamt
  IS
	select N_CLAIM_SK_R                       AS N_CLAIM_SK_R
	     , N_CLAIM_COVERAGE_SK_R              AS N_CLAIM_COVERAGE_SK_R
		 , N_CLAIM_COVERAGE_GROUP_SK_R        AS N_CLAIM_COVERAGE_GROUP_SK_R
		 , sum(N_RESERVE_DIRECT_BEST_ESTMT_R) AS N_CURR_BEST_ESTIMATE_RESERVE_R
	     , sum(N_RESERVE_DIRECT_GAAP_R)       AS N_CURR_GAAP_RESERVE_R
	     , sum(N_RESERVE_DIRECT_STAT_R)       AS N_CURR_STAT_RESERVE_R
	     , sum(N_RESERVE_DIRECT_FIELD_R)      AS N_CURR_FIELD_RESERVE_R
	     , D_RESERVE_VALUATION_DATE_R         AS D_MOST_RECENT_RESERVE_VALUATION_DATE_R
	--,n_reportmonth_r--02-Oct-2024 changes
	     , N_CURRENT_RESERVE_R                AS N_CURRENT_RESERVE_R --19 May 25 Changes
	  from RPT_RESERVE_DETAILS_R a
     where a.D_RESERVE_VALUATION_DATE_R =
     	(select max(b.D_RESERVE_VALUATION_DATE_R)
     	   from RPT_RESERVE_DETAILS_R b
     	  where a.n_claim_sk_r = b.n_claim_sk_r
     	    and a.n_claim_coverage_sk_r = b.n_claim_coverage_sk_r
     	    and a.n_claim_coverage_group_sk_r = b.n_claim_coverage_group_sk_r
     	  --and b.n_reportmonth_r=GN_CURRENT_MONTH--02-Oct-2024 changes--(select max(c.n_reportmonth_r) from RPT_RESERVE_DETAILS_R c)
     	)
	--19-Sep-2024 changes starts
	   AND EXISTS(SELECT 1
					FROM RPT_CLAIM_SUM_R
				   WHERE RPT_CLAIM_SUM_R.N_CLAIM_COVERAGE_GROUP_SK_R = A.N_CLAIM_COVERAGE_GROUP_SK_R
				     AND RPT_CLAIM_SUM_R.N_CLAIM_COVERAGE_SK_R       = A.N_CLAIM_COVERAGE_SK_R
					 AND RPT_CLAIM_SUM_R.N_CLAIM_SK_R                = A.N_CLAIM_SK_R
					 AND RPT_CLAIM_SUM_R.N_YEARMONTH_R               = GN_CURRENT_MONTH
				  )
	--and a.n_reportmonth_r=GN_CURRENT_MONTH--02-Oct-2024 changes--(select max(d.n_reportmonth_r) from RPT_RESERVE_DETAILS_R d)
	--19-Sep-2024 changes ends
	  group by n_claim_sk_r, n_claim_coverage_sk_r, n_claim_coverage_group_sk_r,d_reserve_valuation_date_r,n_reportmonth_r,N_CURRENT_RESERVE_R
	;

	TYPE var_upd_tbl_reserveamt_type IS TABLE OF cur_reserveamt%ROWTYPE INDEX BY BINARY_INTEGER;
	lt_var_upd_tbl_reserveamt_typ var_upd_tbl_reserveamt_type;

BEGIN
   --For more details how this procedure is being used, refer the Main Procedure comment block.
	pkg_grp_log_util.PRC_INSERT_LOG
					( p_source              		=> gv_source
					 ,p_job_nm               		=> gv_job_name
					 ,p_job_status           		=> gv_running_status
					 ,p_err_msg              		=> NULL
					 ,p_trc_msg              		=> NULL
					 ,p_n_batch_id           		=> gn_sysdt_batchid
					 ,p_log_util_called_by_r 		=> gv_main_loadedby
					 ,out_job_id             		=> gn_out_job_id
					);

    gn_current_month := FNC_GRP_GET_SSL_YEARMONTH(SYSDATE);

	gv_trcmsg := '1 :Entered into from prc_upd_cols.';
	gt_start_time := SYSTIMESTAMP;


	/*START: NEW LOGGING MECHANISM CHANGES*/
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
				( p_job_id_r                    => gn_out_job_id
				 ,p_batch_id_r                  => gn_sysdt_batchid
				 ,p_message_type_r              => gv_message_type
				 ,p_code_location_r             => gv_upd_ind_cols_by
				 ,p_message_r                   => gv_trcmsg
				 ,p_count_type_r                => NULL
				 ,p_count_r                     => NULL
				 ,p_duration_r                  => NULL
				 ,p_created_by_r                => gv_job_name
				 ,out_prcs_job_log_message_id_r => gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/

	gv_trcmsg := '1.1 :Update Amount columns from main.';
	gt_start_time := SYSTIMESTAMP;
       gn_run_cnt := 0 ;

	/*START: NEW LOGGING MECHANISM CHANGES*/
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
				( p_job_id_r                    => gn_out_job_id
				 ,p_batch_id_r                  => gn_sysdt_batchid
				 ,p_message_type_r              => gv_message_type
				 ,p_code_location_r             => gv_upd_ind_cols_by
				 ,p_message_r                   => gv_trcmsg
				 ,p_count_type_r                => NULL
				 ,p_count_r                     => NULL
				 ,p_duration_r                  => NULL
				 ,p_created_by_r                => gv_job_name
				 ,out_prcs_job_log_message_id_r => gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/

    OPEN  cur_get_amt ;
	LOOP
	lt_var_upd_tbl_amt_typ.DELETE;
    FETCH cur_get_amt bulk collect into  lt_var_upd_tbl_amt_typ limit gn_bulk_coll_cnt;
    FORALL X in lt_var_upd_tbl_amt_typ.first..lt_var_upd_tbl_amt_typ.last
    UPDATE   rpt_claim_sum_r
      set
        n_claim_total_gross_amt_r= lt_var_upd_tbl_amt_typ(X).n_claim_total_gross_amt_r
       ,n_claim_total_loss_amt_r = lt_var_upd_tbl_amt_typ(X).n_claim_total_loss_amt_r
       ,n_claim_total_paid_amt_r = lt_var_upd_tbl_amt_typ(X).n_claim_total_loss_amt_r
       ,n_claim_total_net_amt_r  = lt_var_upd_tbl_amt_typ(X).n_claim_total_net_amt_r
       ,n_most_recent_net_amt_r  = lt_var_upd_tbl_amt_typ(X).n_claim_total_net_amt_r
       ,n_claim_total_tax_amt_r  = lt_var_upd_tbl_amt_typ(X).n_claim_total_tax_amt_r
	   --04/11/24 Changes start
	   ,N_CLAIM_MTD_LOSS_AMT_R   = lt_var_upd_tbl_amt_typ(X).N_CLAIM_MTD_LOSS_AMT_R
	   ,N_CLAIM_QTD_LOSS_AMT_R   =  lt_var_upd_tbl_amt_typ(X).N_CLAIM_QTD_LOSS_AMT_R
	   ,N_CLAIM_YTD_LOSS_AMT_R   =  lt_var_upd_tbl_amt_typ(X).N_CLAIM_YTD_LOSS_AMT_R
       --04/11/24 Changes End
    where
	    rpt_claim_sum_r.n_claim_coverage_group_sk_r=lt_var_upd_tbl_amt_typ(X).n_claim_coverage_group_sk_r
    and rpt_claim_sum_r.n_claim_coverage_sk_r      =lt_var_upd_tbl_amt_typ(X).n_claim_coverage_sk_r
    and rpt_claim_sum_r.n_claim_sk_r               =lt_var_upd_tbl_amt_typ(X).n_claim_sk_r
    and rpt_claim_sum_r.n_yearmonth_r              =gn_current_month;

	 gn_run_cnt := SQL%ROWCOUNT;
     commit;
     EXIT WHEN cur_get_amt%NOTFOUND;
    END LOOP;
	CLOSE cur_get_amt;

	gv_trcmsg       := '1.2 - Completed Updating Amount columns from main';
	gt_end_time 	:= SYSTIMESTAMP;

	/*START: NEW LOGGING MECHANISM CHANGES*/
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
				( p_job_id_r                    => gn_out_job_id
				 ,p_batch_id_r                  => gn_sysdt_batchid
				 ,p_message_type_r              => gv_message_type
				 ,p_code_location_r             => gv_upd_ind_cols_by
				 ,p_message_r                   => gv_trcmsg
				 ,p_count_type_r                => gv_count_type_upd
				 ,p_count_r                     => gn_run_cnt
				 ,p_duration_r                  => FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
				 ,p_created_by_r                => GV_JOB_NAME
				 ,out_prcs_job_log_message_id_r => gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/

	gv_trcmsg := '1.3 : Update Reserve Amount columns from main.';
	gt_start_time := SYSTIMESTAMP;
       gn_run_cnt := 0 ;

	/*START: NEW LOGGING MECHANISM CHANGES*/
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
				( p_job_id_r                    => gn_out_job_id
				 ,p_batch_id_r                  => gn_sysdt_batchid
				 ,p_message_type_r              => gv_message_type
				 ,p_code_location_r             => gv_upd_ind_cols_by
				 ,p_message_r                   => gv_trcmsg
				 ,p_count_type_r                => NULL
				 ,p_count_r                     => NULL
				 ,p_duration_r                  => NULL
				 ,p_created_by_r                => gv_job_name
				 ,out_prcs_job_log_message_id_r => gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/

    OPEN  cur_reserveamt ;
	LOOP
	lt_var_upd_tbl_reserveamt_typ.DELETE;
    FETCH cur_reserveamt bulk collect into  lt_var_upd_tbl_reserveamt_typ limit gn_bulk_coll_cnt;
    FORALL X in lt_var_upd_tbl_reserveamt_typ.first..lt_var_upd_tbl_reserveamt_typ.last
    UPDATE   rpt_claim_sum_r
      set
        n_curr_best_estimate_reserve_r        = lt_var_upd_tbl_reserveamt_typ(X).n_curr_best_estimate_reserve_r
       ,n_curr_gaap_reserve_r                 = lt_var_upd_tbl_reserveamt_typ(X).n_curr_gaap_reserve_r
       ,n_curr_stat_reserve_r                 = lt_var_upd_tbl_reserveamt_typ(X).n_curr_stat_reserve_r
       ,n_curr_field_reserve_r                = lt_var_upd_tbl_reserveamt_typ(X).n_curr_field_reserve_r
       ,d_most_recent_reserve_valuation_date_r= lt_var_upd_tbl_reserveamt_typ(X).d_most_recent_reserve_valuation_date_r
	   ,N_CURRENT_RESERVE_R                = lt_var_upd_tbl_reserveamt_typ(X).N_CURRENT_RESERVE_R --19 May 25 Changes
    where
	    rpt_claim_sum_r.n_claim_coverage_group_sk_r=lt_var_upd_tbl_reserveamt_typ(X).n_claim_coverage_group_sk_r
    and rpt_claim_sum_r.n_claim_coverage_sk_r      =lt_var_upd_tbl_reserveamt_typ(X).n_claim_coverage_sk_r
    and rpt_claim_sum_r.n_claim_sk_r               =lt_var_upd_tbl_reserveamt_typ(X).n_claim_sk_r
    and rpt_claim_sum_r.n_yearmonth_r              =gn_current_month;

	gn_run_cnt := SQL%ROWCOUNT;

     commit;
     EXIT WHEN cur_reserveamt%NOTFOUND;
    END LOOP;
	CLOSE cur_reserveamt;

	gv_trcmsg       := '1.4 - Completed Updating Reserve Amount columns from main.';
	gt_end_time 	:= SYSTIMESTAMP;

	/*START: NEW LOGGING MECHANISM CHANGES*/
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
				( p_job_id_r                    => gn_out_job_id
				 ,p_batch_id_r                  => gn_sysdt_batchid
				 ,p_message_type_r              => gv_message_type
				 ,p_code_location_r             => gv_upd_ind_cols_by
				 ,p_message_r                   => gv_trcmsg
				 ,p_count_type_r                => gv_count_type_upd
				 ,p_count_r                     => gn_run_cnt
				 ,p_duration_r                  => FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
				 ,p_created_by_r                => GV_JOB_NAME
				 ,out_prcs_job_log_message_id_r => gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/

	gv_trcmsg := '1.5 : Refresh of RPT_POLICY_DTL_R_CLASSOFBUS_MV_SSL Starts from Main.';
	gt_start_time := SYSTIMESTAMP;

	/*START: NEW LOGGING MECHANISM CHANGES*/
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
				( p_job_id_r                    => gn_out_job_id
				 ,p_batch_id_r                  => gn_sysdt_batchid
				 ,p_message_type_r              => gv_message_type
				 ,p_code_location_r             => gv_upd_ind_cols_by
				 ,p_message_r                   => gv_trcmsg
				 ,p_count_type_r                => NULL
				 ,p_count_r                     => NULL
				 ,p_duration_r                  => NULL
				 ,p_created_by_r                => gv_job_name
				 ,out_prcs_job_log_message_id_r => gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/
	execute immediate 'TRUNCATE TABLE RPT_POLICY_DTL_R_CLASSOFBUS_MV_SSL PURGE SNAPSHOT LOG';
    dbms_mview.refresh('RPT_POLICY_DTL_R_CLASSOFBUS_MV_SSL', method => 'C', atomic_refresh => FALSE ,PARALLELISM => 4);

	gv_trcmsg       := '1.6 - Refresh of RPT_POLICY_DTL_R_CLASSOFBUS_MV_SSL Ends from Main.';
	gt_end_time 	:= SYSTIMESTAMP;

	/*START: NEW LOGGING MECHANISM CHANGES*/

		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
				( p_job_id_r                    => gn_out_job_id
				 ,p_batch_id_r                  => gn_sysdt_batchid
				 ,p_message_type_r              => gv_message_type
				 ,p_code_location_r             => gv_upd_ind_cols_by
				 ,p_message_r                   => gv_trcmsg
				 ,p_count_type_r                => NULL
				 ,p_count_r                     => NULL
				 ,p_duration_r                  => FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
				 ,p_created_by_r                => GV_JOB_NAME
				 ,out_prcs_job_log_message_id_r => gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/

	gv_trcmsg := '1.7 : Update Current Face Amt starts from main.';
	gt_start_time := SYSTIMESTAMP;
       gn_run_cnt := 0 ;

	/*START: NEW LOGGING MECHANISM CHANGES*/
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
				( p_job_id_r                    => gn_out_job_id
				 ,p_batch_id_r                  => gn_sysdt_batchid
				 ,p_message_type_r              => gv_message_type
				 ,p_code_location_r             => gv_upd_ind_cols_by
				 ,p_message_r                   => gv_trcmsg
				 ,p_count_type_r                => NULL
				 ,p_count_r                     => NULL
				 ,p_duration_r                  => NULL
				 ,p_created_by_r                => gv_job_name
				 ,out_prcs_job_log_message_id_r => gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/

    OPEN  cur_upd_data ;
	LOOP
	lt_var_upd_tbl_typ3.DELETE;
    FETCH cur_upd_data bulk collect into  lt_var_upd_tbl_typ3 limit 100000;
	IF lt_var_upd_tbl_typ3.COUNT > 0 THEN --02-oCT-2024 CHANGES
	FOR I IN lt_var_upd_tbl_typ3.first..lt_var_upd_tbl_typ3.last
	LOOP
	    IF lt_var_upd_tbl_typ3(i).v_lob_type_r in ('LIFE', 'WOP') THEN
	       lt_var_upd_tbl_typ3(i).n_current_face_amount_r:=lt_var_upd_tbl_typ3(i).n_life_wop_amt_r;
	    ELSIF lt_var_upd_tbl_typ3(i).v_lob_type_r = 'NONS' THEN
	        IF lt_var_upd_tbl_typ3(i).v_class_of_business_r IS NOT NULL THEN --19-Sep-2024 changes
			    --IF  NVL(lt_var_upd_tbl_typ3(i).v_class_of_business_r,'x@') in ('ASG', 'END', 'IDL', 'IWP', 'LTY', 'MML', 'ORL', 'PGL', 'PVG') THEN --19-Sep-2024 changes
			    IF  lt_var_upd_tbl_typ3(i).v_class_of_business_r in ('ASG', 'END', 'IDL', 'IWP', 'LTY', 'MML', 'ORL', 'PGL', 'PVG') THEN--19-Sep-2024 changes
	                lt_var_upd_tbl_typ3(i).n_current_face_amount_r:=lt_var_upd_tbl_typ3(i).n_life_wop_amt_r;
	    	    --ELSIF NVL(lt_var_upd_tbl_typ3(i).v_class_of_business_r,'x@') in ('SR', 'VAR', 'WOP') THEN--19-Sep-2024 changes
	    	    ELSIF lt_var_upd_tbl_typ3(i).v_class_of_business_r in ('SR', 'VAR', 'WOP') THEN--19-Sep-2024 changes
                    lt_var_upd_tbl_typ3(i).n_current_face_amount_r:=lt_var_upd_tbl_typ3(i).n_reserve_amount_r;
				END IF;--19-Sep-2024 changes
	    	ELSE
	    	    lt_var_upd_tbl_typ3(i).n_current_face_amount_r:=0;
	    	END IF;
	    ELSE
	         lt_var_upd_tbl_typ3(i).n_current_face_amount_r:=0;
        END IF;
	END LOOP;
    FORALL X in lt_var_upd_tbl_typ3.first..lt_var_upd_tbl_typ3.last
    UPDATE   RPT_CLAIM_SUM_R
      set
	  n_current_face_amount_r=lt_var_upd_tbl_typ3(X).n_current_face_amount_r
	  where rowid=lt_var_upd_tbl_typ3(X).row_id
	    AND n_yearmonth_r=gn_current_month;

        gn_run_cnt := SQL%ROWCOUNT;

     commit;
	 END IF;--02-oCT-2024 CHANGES
     EXIT WHEN cur_upd_data%NOTFOUND;
    END LOOP;
	CLOSE cur_upd_data;

	gv_trcmsg       := '1.8 - Update Current Face Amt Completed .';
	gt_end_time 	:= SYSTIMESTAMP;

	/*START: NEW LOGGING MECHANISM CHANGES*/
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
				( p_job_id_r                    => gn_out_job_id
				 ,p_batch_id_r                  => gn_sysdt_batchid
				 ,p_message_type_r              => gv_message_type
				 ,p_code_location_r             => gv_upd_ind_cols_by
				 ,p_message_r                   => gv_trcmsg
				 ,p_count_type_r                => gv_count_type_upd
				 ,p_count_r                     => gn_run_cnt
				 ,p_duration_r                  => FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
				 ,p_created_by_r                => GV_JOB_NAME
				 ,out_prcs_job_log_message_id_r => gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/

	gv_trcmsg := '1.9 : Exit from prc_upd_cols.';
	gt_start_time := SYSTIMESTAMP;

	/*START: NEW LOGGING MECHANISM CHANGES*/
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
				( p_job_id_r                    => gn_out_job_id
				 ,p_batch_id_r                  => gn_sysdt_batchid
				 ,p_message_type_r              => gv_message_type
				 ,p_code_location_r             => gv_upd_ind_cols_by
				 ,p_message_r                   => gv_trcmsg
				 ,p_count_type_r                => NULL
				 ,p_count_r                     => NULL
				 ,p_duration_r                  => NULL
				 ,p_created_by_r                => gv_job_name
				 ,out_prcs_job_log_message_id_r => gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/

    pkg_grp_log_util.prc_update_log
			  (   p_job_id  					=> gn_out_job_id
				 ,p_job_status					=> gv_success_status
				 ,p_err_msg						=> gv_errmsg
				 ,p_trc_msg						=> gv_trcmsg
				 ,p_log_util_called_by_r		=> gv_main_loadedby
			  );

EXCEPTION
WHEN OTHERS THEN

    gv_errmsg :=SUBSTR(SQLERRM,1,4000);
    gv_trcmsg:='1.z - Error in prc_upd_cols. '||gv_errmsg;

	/*START: NEW LOGGING MECHANISM CHANGES*/
    pkg_grp_log_util.prc_update_log_message_r
			   (   n_prcs_job_log_message_id_r  => gn_job_log_message_id
				  ,p_err_msg                    => gv_trcmsg
					   );
    /*END: NEW LOGGING MECHANISM CHANGES*/

    pkg_grp_log_util.prc_update_log
			  (   p_job_id  					=> gn_out_job_id
				 ,p_job_status					=> gv_error_status
				 ,p_err_msg						=> gv_errmsg
				 ,p_trc_msg						=> gv_trcmsg
				 ,p_log_util_called_by_r		=> gv_upd_ind_cols_by
			  );
    RAISE;

END prc_upd_cols;

END PKG_GRP_LOAD_RPT_CLAIM_SUM_R;

