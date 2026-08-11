

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ATOMIC"."PKG_GRP_LOAD_RPT_CLAIM_NOTE_R_INC"
IS
/***********************************************************************
  Purpose:  This package body contains procedures which loads data into RPT_CLAIM_NOTE_R

  Author     Date     Description
  ---------- -------- -------------------------------------------------
  VGireesh   10/11/23 Initial Creation
  VGireesh   04/01/24 Gather table stats added
  VGireesh   05/01/24 Added Privacy Indicator
  VGireesh   18/01/24 Added procedure prc_rebuild_indexes
  VGireesh   19/01/24 Added N_POLICY_ID_R
  VGireesh   23/01/24 Closed REF Cursor
  VGireesh   26/01/24 Added v_note_created_by_r,V_PRIVACY_INDICATOR_R derivations
  VGireesh   20/02/24 Added N_CLAIM_NOTE_CREATED_TIME_R,V_MOST_RECENT_NOTE_IND_R
  VGireesh   26/02/24 for month end  that the tables start loading data in the next month partition
                      Ex: March data on February 29th (as of 2.28).
                          27th is Feb Fisc Month End    202402  should be truncate and load in 202402 partition
                          28th is feb Fisc Month End +1 202402  should be truncate and load in 202402 partition
                          29th is Feb Fisc Month End +2 202403  should inactive records against the partition 202402 and load data in 202403 partition
  VGireesh   04/03/24 Added logic to update D_NOTE_MONTH_START_DATE_R and D_NOTE_MONTH_END_DATE_R and enabled v_note_data_r
  VGireesh   13/03/24 in the driving query where clause moved the joins to DIM_GRP_CLAIM_POLICY_DETAIL_EMP_MV_SSL
  VGireesh   03/04/24 Added Parallel to rebuild index fast  parallel 16 nologging, FCT_GRP_CLAIM_NOTE_R_DRQ_MV_SSL has been added as driving table
  VGireesh   11/06/24 Update logic of update D_NOTE_MONTH_START_DATE_R and D_NOTE_MONTH_END_DATE_R has been commented and from the driving query fetching the values.
  Chandra    26/06/24 Added V_TIER_R Column.
  Samba	     21/05/25  Commented update flag = 'N' for Month End+2 Load.
                       Also commented the part which copies the Current Month to Next Month Partition
  Samba	     26/05/25  Added new logging Mechanism


  Suresh     27/08/25 Standardization of Code
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
Joe        06/02/2026   Audit Control Code as part of reconcilation between EDW and RPT.
  ***********************************************************************/

  --Global Constants
		gd_sysdate               CONSTANT DATE           											 := TRUNC(SYSDATE);
		gn_prior_month           PRCS_JOB_LOG_MESSAGE_R.N_COUNT_R%TYPE 					             := TO_NUMBER(TO_CHAR(ADD_MONTHS(TRUNC(gd_sysdate,'MM'),-1),'YYYYMM'));
		gn_current_month         PRCS_JOB_LOG_MESSAGE_R.N_COUNT_R%TYPE 					             := TO_NUMBER(TO_CHAR(gd_sysdate,'YYYYMM'));
		gn_sysdt_batchid         CONSTANT PRCS_JOB_LOG_MESSAGE_R.N_COUNT_R%TYPE 					 := TO_NUMBER(TO_CHAR(gd_sysdate,'YYYYMMDD'));
		gv_main_loadedby         CONSTANT PRCS_JOB_LOG_MESSAGE_R.V_CODE_LOCATION_R%TYPE				 := 'PKG_GRP_LOAD_RPT_CLAIM_NOTE_R_INC.MAIN';
		gv_updby                 CONSTANT PRCS_JOB_LOG_MESSAGE_R.V_CODE_LOCATION_R%TYPE				 := 'PKG_GRP_LOAD_RPT_CLAIM_NOTE_R_INC.PRC_UPD_DEL_DATA';
		gv_getcur_loadedby       CONSTANT PRCS_JOB_LOG_MESSAGE_R.V_CODE_LOCATION_R%TYPE				 := 'PKG_GRP_LOAD_RPT_CLAIM_NOTE_R_INC.PRC_GET_CUR_DATA';
		gv_truncpartby           CONSTANT PRCS_JOB_LOG_MESSAGE_R.V_CODE_LOCATION_R%TYPE				 := 'PKG_GRP_LOAD_RPT_CLAIM_NOTE_R_INC.PRC_TRUNC_PARTITION';
		gv_rebuildindexes        CONSTANT PRCS_JOB_LOG_MESSAGE_R.V_CODE_LOCATION_R%TYPE				 := 'PKG_GRP_LOAD_RPT_CLAIM_NOTE_R_INC.PRC_REBUILD_INDEXES';
		gv_job_name              CONSTANT PRCS_JOB_LOG_R.V_JOB_NAME_R%TYPE							 := 'GRP_LOAD_RPT_CLAIM_NOTE_R_INC';
		gv_running_status        CONSTANT PRCS_JOB_LOG_R.V_JOB_STATUS_R%TYPE  						 := 'Running';
		gv_error_status          CONSTANT PRCS_JOB_LOG_R.V_JOB_STATUS_R%TYPE    					 := 'Error';
		gv_success_status        CONSTANT PRCS_JOB_LOG_R.V_JOB_STATUS_R%TYPE  						 := 'Success';
		gv_source                CONSTANT PRCS_JOB_LOG_R.V_JOB_STATUS_R%TYPE 						 := 'EDW';
		gv_yes_ind               CONSTANT DIM_GRP_POLICY_DIR_R.v_active_status_r%TYPE				 := 'Y';
        gv_no_ind                CONSTANT DIM_GRP_POLICY_DIR_R.v_active_status_r%TYPE				 := 'N';
		gv_source_syst			 CONSTANT DIM_GRP_BILLING_POL_BILLGRP_R.v_source_system_name_r%TYPE	 := 'VUE';
		gv_message_type 	     CONSTANT PRCS_JOB_LOG_MESSAGE_R.v_message_type_r%TYPE  			 := PKG_GRP_LOG_UTIL.gc_message_type_info;
		gv_count_type    	     CONSTANT PRCS_JOB_LOG_MESSAGE_R.v_count_type_r%TYPE    			 := PKG_GRP_LOG_UTIL.gc_count_type_insert;
        gv_count_type_delete     CONSTANT PRCS_JOB_LOG_MESSAGE_R.v_count_type_r%TYPE    			 := PKG_GRP_LOG_UTIL.gc_count_type_delete;
		gn_bulk_coll_cnt         CONSTANT PLS_INTEGER				                            	 := 10000;
        gn_run_cnt               PRCS_JOB_LOG_MESSAGE_R.N_COUNT_R%TYPE 	 				             := 0;
		gv_trcmsg                PRCS_JOB_LOG_MESSAGE_R.V_MESSAGE_R%TYPE;
		gt_start_time   	     PRCS_JOB_LOG_MESSAGE_R.D_CREATION_DATE_R %TYPE;
		gt_end_time 		     PRCS_JOB_LOG_MESSAGE_R.D_CREATION_DATE_R %TYPE;
		gn_job_log_message_id    PRCS_JOB_LOG_MESSAGE_R.N_COUNT_R%TYPE;
		gn_error_line            PRCS_JOB_LOG_MESSAGE_R.v_message_type_r%TYPE;
		gn_out_job_id            PRCS_JOB_LOG_MESSAGE_R.N_JOB_ID_R%TYPE;
		gv_errmsg                PRCS_JOB_LOG_MESSAGE_R.V_MESSAGE_R%TYPE;
		gn_target_count          number;
		gc_source                varchar2(30) :='EDW';
		gc_target                varchar2(30) :='RPT';

PROCEDURE prc_del_ext_data
IS
  /***********************************************************************
  Purpose:  This procedure delete the dubplicates records that going to load.

  Author     Date     Description
  ---------- -------- ----------------------------------------------------------
  Suresh     27/08/25 Developed first Version
*******************************************************************************/
   ln_rec_cnt    PLS_INTEGER := 0;
   LN_SQLROWCNT  PLS_INTEGER := 0;
BEGIN
	ln_sqlrowcnt := 0;
    /*START: NEW LOGGING MECHANISM CHANGES*/
	gt_start_time:= SYSTIMESTAMP;

    gv_trcmsg:='6.1 START: DELETE EXSISTING RECORDS ';

    PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
                    (p_job_id_r                    => gn_out_job_id
                    ,p_batch_id_r                  => gn_sysdt_batchid
                    ,p_message_type_r              => gv_message_type
                    ,p_code_location_r             => gv_main_loadedby
                    ,p_message_r                   => gv_trcmsg
                    ,p_count_type_r                => gv_count_type_delete
                    ,p_count_r                     => NULL
                    ,p_duration_r                  => NULL
                    ,p_created_by_r                => Gv_JOB_NAME
                    ,out_prcs_job_log_message_id_r => gn_job_log_message_id
                    );

/*END: NEW LOGGING MECHANISM CHANGES*/
 -- Perf Tuning Code
  	DELETE /*+PARALLEL(4)*/
	  FROM RPT_CLAIM_NOTE_R T
	 WHERE EXISTS ( SELECT 1
					  FROM (SELECT DISTINCT
								   N_CLAIM_SK_R
								 , N_CLAIM_SUBSEQUENCE_NUMBER_R
								 , N_SEQ_R
								 , D_CREATED_DATE_R
								 , N_BATCH_ID_R
							  FROM FCT_GRP_CLAIM_NOTE_R_DRQ_MV_SSL_INC
							 WHERE T_LAST_MODIFIED_DATE_R >=(SELECT max(END_DATE)
															   FROM SSL_PACKAGE_MILESTONE_TABLE
															  WHERE JOB_NAME='PKG_GRP_LOAD_RPT_CLAIM_NOTE_R_INC'
															)
						    ) S
					  WHERE S.N_CLAIM_SK_R                  =   T.N_CLAIM_SK_R
					    AND S.N_CLAIM_SUBSEQUENCE_NUMBER_R  =   T.N_CLAIM_SUBSEQUENCE_NUMBER_R
					    AND S.N_SEQ_R                       =   T.N_SEQ_R
					    AND S.D_CREATED_DATE_R              =   T.D_NOTE_CREATED_DATE_R
					    AND S.N_BATCH_ID_R                  =   T.N_BATCH_ID_R_NOTE
					    AND T.N_YEARMONTH_R = gn_current_month
				     );

      ln_sqlrowcnt := SQL%ROWCOUNT;
  commit;

    gv_trcmsg:='6.2 END: DELETE EXSISTING RECORDS .Total records deleted : '||ln_sqlrowcnt;

    gt_end_time := SYSTIMESTAMP;
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
            (    p_job_id_r                    => gn_out_job_id
				,p_batch_id_r                  => gn_sysdt_batchid
				,p_message_type_r              => gv_message_type
				,p_code_location_r             => gv_main_loadedby
				,p_message_r                   => gv_trcmsg
				,p_count_type_r                => gv_count_type_delete
				,p_count_r                     => ln_sqlrowcnt
				,p_duration_r                  => FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
				,p_created_by_r                => GV_JOB_NAME
                ,out_prcs_job_log_message_id_r => gn_job_log_message_id
				);

    ln_sqlrowcnt := 0;

	gt_start_time:= SYSTIMESTAMP;

    gv_trcmsg:='6.3 START: DELETE ACTIVE=N AND PHYSICAL DELETE ';

    PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
                    (p_job_id_r                    => gn_out_job_id
                    ,p_batch_id_r                  => gn_sysdt_batchid
                    ,p_message_type_r              => gv_message_type
                    ,p_code_location_r             => gv_main_loadedby
                    ,p_message_r                   => gv_trcmsg
                    ,p_count_type_r                => gv_count_type_delete
                    ,p_count_r                     => NULL
                    ,p_duration_r                  => NULL
                    ,p_created_by_r                => Gv_JOB_NAME
                    ,out_prcs_job_log_message_id_r => gn_job_log_message_id
                    );

 -- Perf Tuning Code
  DELETE /*+PARALLEL(4)*/
    FROM RPT_CLAIM_NOTE_R T
	WHERE n_claim_sk_r in ( SELECT n_claim_sk_r
	                          FROM ATOMIC.DIM_GRP_CLAIM_DIR_R
                             WHERE n_claim_sk_r IN (SELECT n_claim_sk_r
													  FROM (SELECT n_claim_sk_r
													             , v_active_status_r
																 , COUNT(1) CNT
															  FROM ATOMIC.DIM_GRP_CLAIM_DIR_R A
															 WHERE n_claim_sk_r > -1
														  GROUP BY n_claim_sk_r
														         , v_active_status_r
													) T GROUP BY n_claim_sk_r
												  HAVING COUNT(1) =1
                           )
							   AND (v_active_status_r='N'
                               AND V_CHANGE_REASON_R = 'Physically Deleted'
								   )
							   AND t_last_modified_date_r>= (SELECT max(END_DATE)
															  FROM SSL_PACKAGE_MILESTONE_TABLE
															 WHERE JOB_NAME='PKG_GRP_LOAD_RPT_CLAIM_NOTE_R_INC'
														     )
						  GROUP BY n_claim_sk_r
						 )
      AND T.N_YEARMONTH_R = gn_current_month;

      ln_sqlrowcnt := SQL%ROWCOUNT;

  commit;

  gv_trcmsg:='6.4 END: DELETE ACTIVE=N AND PHYSICAL DELETE '||ln_sqlrowcnt;

    gt_end_time := SYSTIMESTAMP;
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
            (    p_job_id_r                    => gn_out_job_id
				,p_batch_id_r                  => gn_sysdt_batchid
				,p_message_type_r              => gv_message_type
				,p_code_location_r             => gv_main_loadedby
				,p_message_r                   => gv_trcmsg
				,p_count_type_r                => gv_count_type_delete
				,p_count_r                     => ln_sqlrowcnt
				,p_duration_r                  => FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
				,p_created_by_r                => GV_JOB_NAME
                ,out_prcs_job_log_message_id_r => gn_job_log_message_id
				);

EXCEPTION
WHEN OTHERS THEN

    gv_errmsg :=SUBSTR(SQLERRM,1,4000);
    gv_trcmsg:='6.Z Error in prc_del_ext_data '||gv_errmsg;

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

END prc_del_ext_data;

--Main procedures calls other procedure to load data in RPT_CLAIM_NOTE_R
PROCEDURE main
/***********************************************************************
  Purpose:  This procedure controls the overall process and calls the child
            procedures needed

  Author     Date     Description
  ---------- -------- ----------------------------------------------------------
  VGireesh   10/11/23 Developed first Version
  Suresh     27/08/25 Standardization of Code
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
*******************************************************************************/

IS
        lv_rpt_table 		  PRCS_JOB_LOG_R.CREATED_BY_R%TYPE 			        := 'RPT_CLAIM_NOTE_R';
        ln_rec_cnt            PLS_INTEGER	                                    := 0 ;
        ln_ROW_CNT            PLS_INTEGER	                                    := 0 ;
        ln_idx_num			  PLS_INTEGER									    := 8;

        ld_fic_mis_date_2     DATE;
        ln_fisc_current_month NUMBER;

BEGIN
   -- SET JOB TO IN-PROGRESS
    UPDATE SSL_PACKAGE_MILESTONE_TABLE SET
        JOB_TIMESTAMP   = CURRENT_TIMESTAMP,
        JOB_STATUS      = 'IN-PROGRESS'
    WHERE JOB_NAME='PKG_GRP_LOAD_RPT_CLAIM_NOTE_R_INC';
    COMMIT;

    --Call Log Util pkg to Insert entry in PRCS_JOB_LOG_R
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

	gv_trcmsg :='2. Set PLSQL_OPTIMIZER_LEVEL to 3 - main.';
	gt_start_time:= SYSTIMESTAMP;
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

	execute immediate 'ALTER SESSION SET PLSQL_OPTIMIZE_LEVEL=3';

	gv_trcmsg:='3 Completed Set PLSQL_OPTIMIZER_LEVEL to 3 - main';
    gt_end_time := SYSTIMESTAMP; -- End timing after the insert

    /*START: NEW LOGGING MECHANISM CHANGES*/
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
            (    p_job_id_r                    => gn_out_job_id
				,p_batch_id_r                  => gn_sysdt_batchid
				,p_message_type_r              => gv_message_type
				,p_code_location_r             => gv_main_loadedby
				,p_message_r                   => gv_trcmsg
				,p_count_type_r                => NULL
				,p_count_r                     => NULL
				,p_duration_r                  => FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
				,p_created_by_r                => GV_JOB_NAME
                ,out_prcs_job_log_message_id_r => gn_job_log_message_id
				);
    /*END: NEW LOGGING MECHANISM CHANGES*/

	--    PKG_GRP_LOAD_RPT_CLAIM_NOTE_R_INC.prc_upd_del_data;  -- Suresh

	 /*Common Utility Proc to get month end+2 date and month. Ex: If month end is 29-Aug-2025 then ln_fisc_current_month will be 202509*/
	PKG_GRP_COMMON_UTIL.prc_fisc_month_calc
	(
		p_out_job_id            =>	gn_out_job_id,
        p_Log_seq_num           =>	4,
		ln_fisc_current_month   =>	ln_fisc_current_month,
		ld_fic_mis_date_2       =>	ld_fic_mis_date_2
	);

	/*Common Utility Proc to determine current and prior month ; Checks for month end logic and daily load logic as well */
	PKG_GRP_COMMON_UTIL.PRC_GET_CURRENT_PRIOR_MONTH
	(
		p_out_job_id            =>	gn_out_job_id,
		p_Log_seq_num           =>	5,
		P_fic_mis_date       	=>	ld_fic_mis_date_2,
		P_fisc_current_month    =>	ln_fisc_current_month,
		p_current_month         =>	gn_current_month,
		p_prior_month           =>	gn_prior_month
	);
    /* To delete exiting records and physical data.*/
    prc_del_ext_data;

	/*START: NEW LOGGING MECHANISM CHANGES*/
        gv_trcmsg :='7. Data Load Starts ';
       ln_rec_cnt :=0;
	gt_start_time := SYSTIMESTAMP;

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

 INSERT INTO RPT_CLAIM_NOTE_R
	  SELECT /*+PARALLEL(4)*/
			 fct_grp_claim_note_r.d_change_date_r            AS d_note_change_date_r
		   , fct_grp_claim_note_r.v_note_content_r           AS v_note_content_r
		   , fct_grp_claim_note_r.v_created_by_id_r          AS v_created_by_id_r
		   , A.v_note_created_by_r                           AS v_note_created_by_r
		   , fct_grp_claim_note_r.d_created_date_r           AS d_note_created_date_r
		   , FCT_GRP_CLAIM_NOTE_R.V_CURRENT_STATUS_R         AS V_CURRENT_STATUS_R
		   , TO_CHAR(DBMS_LOB.SUBSTR(SUBSTR(fct_grp_claim_note_r.v_note_data_r,1,4000),2000,1))
		                                                     AS v_note_data_r
		   , fct_grp_claim_note_r.v_description_r            AS v_note_description_r
		   , fct_grp_claim_note_r.n_is_financial_r           AS n_is_financial_r
		   , fct_grp_claim_note_r.v_note_kind_r              AS v_note_kind_r
		   , fct_grp_claim_note_r.n_is_legal_r               AS n_is_legal_r
		   , fct_grp_claim_note_r.n_is_medical_r             AS n_is_medical_r
		   , ( SELECT MAX(td2.d_calendar_date_r)
				 FROM ATOMIC.dim_time_r td
				    , ATOMIC.dim_time_r td2
				WHERE td.d_calendar_date_r = fct_grp_claim_note_r.d_created_date_r
				  AND td.N_CLAIMS_YEAR_R   = td2.N_CLAIMS_YEAR_R
				  AND td.N_CLAIMS_MONTH_R  = td2.N_CLAIMS_MONTH_R
			 )                                               AS D_NOTE_MONTH_END_DATE_R
		   , (SELECT MIN(td2.d_calendar_date_r)
				FROM ATOMIC.dim_time_r td
				   , ATOMIC.dim_time_r td2
				WHERE td.d_calendar_date_r = fct_grp_claim_note_r.d_created_date_r
				  AND td.N_CLAIMS_YEAR_R   = td2.N_CLAIMS_YEAR_R
				  AND td.N_CLAIMS_MONTH_R  = td2.N_CLAIMS_MONTH_R
			  )                                              AS D_NOTE_MONTH_START_DATE_R
		   , fct_grp_claim_note_r.v_note_data_rtf_r          AS v_note_data_rtf_r
		   , fct_grp_claim_note_r.v_note_security_type_r     AS v_note_security_type_r
		   , fct_grp_claim_note_r.v_note_status_r            AS v_note_status_r
		   , fct_grp_claim_note_r.v_subject_r                AS v_subject_r
		   , fct_grp_claim_note_r.v_note_type_r              AS v_note_type_r
		   , A.n_employee_sk_r                               AS n_employee_sk_r
		   , -1                                              AS n_product_sk_r
		   , fct_grp_claim_note_r.n_claim_sk_r               AS n_claim_sk_r
		   , A.n_insrd_party_sk_r                            AS n_insrd_party_sk_r
		   , A.n_cust_party_sk_r                             AS n_cust_party_sk_r
		   , gv_main_loadedby                                AS v_last_modified_by_r
		   , systimestamp                                    AS t_creation_date_r
		   , gv_main_loadedby                                AS v_created_by_r
		   , systimestamp                                    AS t_last_modified_date_r
		   , GN_CURRENT_MONTH                                AS N_YEARMONTH_R
		   , A.v_rpt_active_status_r                         AS v_rpt_active_status_r
		   , gn_sysdt_batchid                                AS n_batch_id_r
		   , A.n_policy_sk_r                                 AS n_policy_sk_r
		   , -1												 AS N_CLAIM_COVERAGE_GROUP_SK_R -- TEMP FIX TO PASS -1 AS IT WAS PART OF PK
		   , -1  											 AS N_CLAIM_COVERAGE_SK_R -- TEMP FIX TO PASS -1 AS IT WAS PART OF PK
		   , fct_grp_claim_note_r.v_privacy_indicator_r      AS V_PRIVACY_INDICATOR_R
		   , cast(null as number)                            AS N_POLICY_ID_R
		   , fct_grp_claim_note_r.N_CREATED_ITIME_R          AS N_CLAIM_NOTE_CREATED_TIME_R
		   , CASE
				 WHEN (fct_grp_claim_note_r.D_CREATED_DATE_R
				    || fct_grp_claim_note_r.N_CREATED_ITIME_R
					  ) = recent_notes .most_recent_note_date
				 THEN 'Y'
				 ELSE 'N'
			  END                                            AS V_MOST_RECENT_NOTE_IND_R
			, fct_grp_claim_note_r.V_TIER_R                  AS V_TIER_R
			, A.N_CLAIM_SUBSEQUENCE_NUMBER_R				 AS N_CLAIM_SUBSEQUENCE_NUMBER_R
			, A.N_SEQ_R                                      AS N_SEQ_R
			, A.N_BATCH_ID_R                                 AS N_BATCH_ID_R_NOTE
			, A.T_LAST_MODIFIED_DATE_R                       AS T_LAST_MODIFIED_DATE_R_NOTE

		FROM FCT_GRP_CLAIM_NOTE_R_DRQ_MV_SSL_INC A
		JOIN ATOMIC.fct_grp_claim_note_r fct_grp_claim_note_r
		  ON fct_grp_claim_note_r.N_CLAIM_SK_R = A.N_CLAIM_SK_R
		 AND fct_grp_claim_note_r.N_CLAIM_SUBSEQUENCE_NUMBER_R = A.N_CLAIM_SUBSEQUENCE_NUMBER_R
		 AND NVL(fct_grp_claim_note_r.N_SEQ_R,9999999) = A.N_SEQ_R
		 AND fct_grp_claim_note_r.D_CREATED_DATE_R =A.D_CREATED_DATE_R
	     AND fct_grp_claim_note_r.N_BATCH_ID_R =A.N_BATCH_ID_R
		--AND fct_grp_claim_note_r.t_last_modified_date_r =A.t_last_modified_date_r
	  	 AND fct_grp_claim_note_r.N_CLAIM_SK_R>-1
		 AND A.t_last_modified_date_r >= (SELECT max(END_DATE)
											FROM SSL_PACKAGE_MILESTONE_TABLE
							               WHERE JOB_NAME = 'PKG_GRP_LOAD_RPT_CLAIM_NOTE_R_INC'
						                  )
		 LEFT JOIN (SELECT A.n_claim_sk_r
		                 , MAX(A.D_CREATED_DATE_R || A.N_CREATED_ITIME_R) AS most_recent_note_date
				      FROM ATOMIC.fct_grp_claim_note_r A
				  GROUP BY  A.n_claim_sk_r
			        ) recent_notes
			    ON recent_notes.n_claim_sk_r = fct_grp_claim_note_r.n_claim_sk_r ;
          ln_rec_cnt := SQL%ROWCOUNT;
COMMIT;
    gn_target_count := ln_rec_cnt;

	gv_trcmsg :='8 : Completed : Data Loaded '||ln_rec_cnt||' records ';

    /*START: NEW LOGGING MECHANISM CHANGES*/
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
    /*END: NEW LOGGING MECHANISM CHANGES*/


gv_trcmsg:='9. Rebuild Local Index prc_rebuild_index_partitions from Common Util for Partition: '||gn_current_month;
    gt_start_time :=SYSTIMESTAMP;
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
	 (
		p_job_id_r                    => gn_out_job_id,
		p_batch_id_r                  => gn_sysdt_batchid,
		p_message_type_r              => gv_message_type,
		p_code_location_r             => gv_rebuildindexes,
		p_message_r                   => gv_trcmsg,
		p_count_type_r                => NULL,
		p_count_r                     => NULL,
		p_duration_r                  => NULL,
		p_created_by_r                => GV_JOB_NAME,
		out_prcs_job_log_message_id_r => gn_job_log_message_id
	);
    --22-08-2025 : Added Local Index Rebuild
	PKG_GRP_COMMON_UTIL.prc_rebuild_index_partitions
	(
		p_table_name   		  		  => 'RPT_CLAIM_NOTE_R',
		p_parallel_degree   		  => 8,
		p_partition_name  		  	  => 'PART_RPT_CLAIM_NOTE_R_'||gn_current_month,
		p_out_job_id              	  => gn_out_job_id,
		p_Log_seq_num             	  => 9
	);

    /*START: NEW LOGGING MECHANISM CHANGES*/
        gv_trcmsg:='10 Completed Rebuild Local Index prc_rebuild_index_partitions from Common Util for Partition: '||gn_current_month;
        gt_end_time := SYSTIMESTAMP;
        PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
                (    p_job_id_r                    => gn_out_job_id
                    ,p_batch_id_r                  => gn_sysdt_batchid
                    ,p_message_type_r              => gv_message_type
                    ,p_code_location_r             => gv_rebuildindexes
                    ,p_message_r                   => gv_trcmsg
                    ,p_count_type_r                => gv_count_type
                    ,p_count_r                     => null
                    ,p_duration_r                  => FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
                    ,p_created_by_r                => GV_JOB_NAME
                    ,out_prcs_job_log_message_id_r => gn_job_log_message_id
                    );
        /*END: NEW LOGGING MECHANISM CHANGES*/

		/*Audit Control Code*/

gv_trcmsg :='11 :Audit Control Code as Part of reconcilation between EDW and RPT';
        --gn_target_count :=22311;
	gt_end_time := SYSTIMESTAMP;
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
            (    p_job_id_r                    => gn_out_job_id
				,p_batch_id_r                  => gn_sysdt_batchid
				,p_message_type_r              => gv_message_type
				,p_code_location_r             => gv_main_loadedby
				,p_message_r                   => gv_trcmsg
				,p_count_type_r                => 'AUDIT_TARGET_COUNT'
				,p_count_r                     => gn_target_count
				,p_duration_r                  => FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
				,p_created_by_r                => GV_JOB_NAME
                ,out_prcs_job_log_message_id_r => gn_job_log_message_id
				);

PRC_GRP_AUDIT_CONTROL_PROCESS(gc_source,gv_job_name,gc_source,gc_target);
     /*Audit Control Code*/

-- Mark the job as complete
    UPDATE SSL_PACKAGE_MILESTONE_TABLE SET
        JOB_TIMESTAMP   = CURRENT_TIMESTAMP,
        JOB_STATUS      = 'SUCCESS',
        START_DATE      = END_DATE,
        END_DATE        = (SELECT MAX(T_LAST_MODIFIED_DATE_R) FROM FCT_GRP_CLAIM_NOTE_R_DRQ_MV_SSL_INC)
    WHERE JOB_NAME='PKG_GRP_LOAD_RPT_CLAIM_NOTE_R_INC';
    COMMIT;

/*START: NEW LOGGING MECHANISM CHANGES*/
	gv_trcmsg:= '12. - Exit from main';
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
END main;

end PKG_GRP_LOAD_RPT_CLAIM_NOTE_R_INC;

