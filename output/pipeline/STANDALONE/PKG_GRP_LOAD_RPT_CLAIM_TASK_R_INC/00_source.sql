

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ATOMIC"."PKG_GRP_LOAD_RPT_CLAIM_TASK_R_INC"
IS
/***********************************************************************
  Purpose:  This package body contains procedures which loads data into RPT_CLAIM_TASK_R
  Dependent SSL tables :

  Author     Date     Description
  ---------- -------- -------------------------------------------------
  VGireesh   10/11/23 Initial Creation
  Chandra    21/06/24 Added V_IS_DAYS_ELAPSED_R, N_DAYS_FROM_DUE_DATE_R, N_TURNAROUND_TIME_R, V_TASK_ASSIGNED_BY_NAME_R, V_TASK_CREATED_BY_NAME_R, V_TASK_CELLWORKER_NAME_R
  Samba		 21/05/25  Commented update flag = 'N' for Month End+2 Load.
                       Also commented the part which copies the Current Month to Next Month Partition
  Samba		 26/05/25  Added new logging Mechanism
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
 Joe        09/02/26  Audit Control Code as part of reconcilation between EDW and RPT.
  ***********************************************************************/

  --Global Constants
		gd_sysdate               CONSTANT DATE           											 := TRUNC(SYSDATE);
		gn_prior_month           PRCS_JOB_LOG_MESSAGE_R.N_COUNT_R%TYPE 					             := TO_NUMBER(TO_CHAR(ADD_MONTHS(TRUNC(gd_sysdate,'MM'),-1),'YYYYMM'));
		gn_current_month         PRCS_JOB_LOG_MESSAGE_R.N_COUNT_R%TYPE 					             := TO_NUMBER(TO_CHAR(gd_sysdate,'YYYYMM'));
		gn_sysdt_batchid         CONSTANT PRCS_JOB_LOG_MESSAGE_R.N_COUNT_R%TYPE 					 := TO_NUMBER(TO_CHAR(gd_sysdate,'YYYYMMDD'));
		gv_main_loadedby         CONSTANT PRCS_JOB_LOG_MESSAGE_R.V_CODE_LOCATION_R%TYPE				 := 'PKG_GRP_LOAD_RPT_CLAIM_TASK_R_INC.MAIN';
		gv_updby                 CONSTANT PRCS_JOB_LOG_MESSAGE_R.V_CODE_LOCATION_R%TYPE				 := 'PKG_GRP_LOAD_RPT_CLAIM_TASK_R_INC.PRC_UPD_DEL_DATA';
		gv_getcur_loadedby       CONSTANT PRCS_JOB_LOG_MESSAGE_R.V_CODE_LOCATION_R%TYPE				 := 'PKG_GRP_LOAD_RPT_CLAIM_TASK_R_INC.PRC_GET_CUR_DATA';
		gv_truncpartby           CONSTANT PRCS_JOB_LOG_MESSAGE_R.V_CODE_LOCATION_R%TYPE				 := 'PKG_GRP_LOAD_RPT_CLAIM_TASK_R_INC.PRC_TRUNC_PARTITION';
		gv_rebuildindexes        CONSTANT PRCS_JOB_LOG_MESSAGE_R.V_CODE_LOCATION_R%TYPE				 := 'PKG_GRP_LOAD_RPT_CLAIM_TASK_R_INC.PRC_REBUILD_INDEXES';
		gv_job_name              CONSTANT PRCS_JOB_LOG_R.V_JOB_NAME_R%TYPE							 := 'GRP_LOAD_RPT_CLAIM_TASK_R_INC';
		gv_running_status        CONSTANT PRCS_JOB_LOG_R.V_JOB_STATUS_R%TYPE  						 :='Running';
		gv_error_status          CONSTANT PRCS_JOB_LOG_R.V_JOB_STATUS_R%TYPE    					 :='Error';
		gv_success_status        CONSTANT PRCS_JOB_LOG_R.V_JOB_STATUS_R%TYPE  						 :='Success';
		gv_source                CONSTANT PRCS_JOB_LOG_R.V_JOB_STATUS_R%TYPE 						 :='EDW';
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

  PROCEDURE PRC_DEL_EXT_DATA
  IS
      /***********************************************************************
      Purpose:  This procedure delete the records that going to load.

      Author     Date     Description
      ---------- -------- ----------------------------------------------------------
      Suresh     27/08/25 Developed first Version
    *******************************************************************************/
       ln_rec_cnt PLS_INTEGER := 0;
    BEGIN

        gt_start_time:= SYSTIMESTAMP;

        gv_trcmsg:='4.1 START: DELETE EXSISTING RECORDS '||chr(13);

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

           ln_rec_cnt := 0;

           EXECUTE IMMEDIATE 'ALTER SESSION ENABLE PARALLEL DML';

           DELETE /*+ PARALLEL(4) */ FROM RPT_CLAIM_TASK_R
            WHERE N_YEARMONTH_R = gn_current_month
              AND (N_CLAIM_SK_R
                 , N_CLAIM_COVERAGE_SK_R
                 , N_CLAIM_COVERAGE_GROUP_SK_R
                 , N_TASK_SEQUENCE_R
                 , N_SOURCE_VERSION_SEQ_NUMBER_R
                  ) IN
                  ( SELECT N_CLAIM_SK_R
                         , N_CLAIM_COVERAGE_SK_R
                         , N_CLAIM_COVERAGE_GROUP_SK_R
                         , N_TASK_SEQUENCE_R
                         , N_SOURCE_VERSION_SEQ_NUMBER_R
                      FROM RPT_CLAIM_TASK_R_DRQ_MV_SSL_INC
                     WHERE T_LAST_MODIFIED_DATE_R >= ( SELECT max(END_DATE)
                                                         FROM SSL_PACKAGE_MILESTONE_TABLE
                                                        WHERE JOB_NAME='PKG_GRP_LOAD_RPT_CLAIM_TASK_R_INC'
                                                     )
                  );

          ln_rec_cnt := SQL%ROWCOUNT;

          commit;

        gv_trcmsg := '4.2 END: DELETE EXSISTING RECORDS .Total records deleted : '||ln_rec_cnt;

        gt_end_time := SYSTIMESTAMP;

        PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
                (    p_job_id_r                    => gn_out_job_id
                    ,p_batch_id_r                  => gn_sysdt_batchid
                    ,p_message_type_r              => gv_message_type
                    ,p_code_location_r             => gv_main_loadedby
                    ,p_message_r                   => gv_trcmsg
                    ,p_count_type_r                => gv_count_type_delete
                    ,p_count_r                     => ln_rec_cnt
                    ,p_duration_r                  => FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
                    ,p_created_by_r                => GV_JOB_NAME
                    ,out_prcs_job_log_message_id_r => gn_job_log_message_id
                    );

        gt_start_time := SYSTIMESTAMP;

        gv_trcmsg :='4.3 - START: DELETING PHYSICAL RECORDS '||chr(13);

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
          ln_rec_cnt := 0;



          DELETE /*+ PARALLEL(4) */
            FROM RPT_CLAIM_TASK_R T
           WHERE N_YEARMONTH_R = GN_CURRENT_MONTH
             AND (N_SOURCE_VERSION_SEQ_NUMBER_R
                , N_Claim_Sk_r
                , n_claim_coverage_sk_r
                , N_TASK_SEQUENCE_R) IN ( SELECT DISTINCT
                                                 NVL(A.N_SOURCE_VERSION_SEQ_NUMBER_R,-1)       AS N_SOURCE_VERSION_SEQ_NUMBER_R
                                               , NVL(a.N_Claim_Sk_r,-1)                        AS N_Claim_Sk_r
                                               , NVL(a.n_claim_coverage_sk_r,-1)               AS n_claim_coverage_sk_r
                                               , NVL(a.N_TASK_SEQUENCE_R,-1)                   AS N_TASK_SEQUENCE_R
                                            FROM ( SELECT /*+PARALLEL(4)*/
                                                            a.n_claim_sk_r                     AS N_CLAIM_SK_R
                                                          , a.V_ASSIGNMENT_ID_R                AS V_ASSIGNMENT_ID_R
                                                          , a.V_s_CREATED_BY_R                 AS V_S_CREATED_BY_R
                                                          , trunc(a.D_DUE_DATE_R  )            AS D_DUE_DATE_R
                                                          , a.N_PRIORITY_R                     AS N_PRIORITY_R
                                                          , a.N_SOURCE_VERSION_SEQ_NUMBER_R    AS N_SOURCE_VERSION_SEQ_NUMBER_R
                                                          , c.v_examiner_login_id_r            AS V_EXAMINER_LOGIN_ID_R
                                                          , e.n_claim_coverage_sk_r            AS N_CLAIM_COVERAGE_SK_R
                                                          , e.v_claim_coverage_code_r          AS V_CLAIM_COVERAGE_CODE_R
                                                          , b.n_policy_sk_r                    AS N_POLICY_SK_R
                                                          , a.N_TASK_SEQUENCE_R                AS N_TASK_SEQUENCE_R
                                                          , a.V_CELL_WORKER_ID_R               AS V_CELL_WORKER_ID_R
                                                     FROM ATOMIC.FCT_GRP_PROCESS_CUSTOM_R A
                                                        , ATOMIC.DIM_GRP_CLAIM_DIR_R B
                                                        , ATOMIC.DIM_GRP_CLAIM_DETAIL_R C
                                                        , ATOMIC.DIM_GRP_CLAIM_COVERAGE_R E
                                                    WHERE A.n_claim_sk_r <> - 1
                                                      AND E.V_CHANGE_REASON_R = 'Physically Deleted'
                                                      AND GREATEST(  COALESCE(a.t_last_modified_date_r, TO_DATE('1900-01-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS'))
                                                                    ,COALESCE(b.t_last_modified_date_r, TO_DATE('1900-01-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS'))
                                                                    ,COALESCE(c.t_last_modified_date_r, TO_DATE('1900-01-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS'))
                                                                    ,COALESCE(e.t_last_modified_date_r, TO_DATE('1900-01-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS'))
                                                                   ) >= ( SELECT max(END_DATE)
                                                                          FROM SSL_PACKAGE_MILESTONE_TABLE
                                                                          WHERE JOB_NAME='PKG_GRP_LOAD_RPT_CLAIM_TASK_R_INC'
                                                                         )
                                                      AND a.N_CLAIM_SK_R=B.N_CLAIM_SK_R
                                                      AND (B.v_active_status_r = 'Y' OR B.v_active_status_r = 'N')
                                                      AND a.N_CLAIM_SK_R=c.N_CLAIM_SK_R  AND C.v_active_status_r = 'N'
                                                      AND a.N_CLAIM_SK_R=e.N_CLAIM_SK_R  AND e.v_active_status_r = 'N'
                                                 ) a
                                            LEFT JOIN ATOMIC.dim_employee_r  d
                                                   ON d.v_employee_login_id_r = a.v_examiner_login_id_r
                                                  AND nvl(upper(d.v_business_unit_r),'CLAIMS') = 'CLAIMS'
                                            LEFT OUTER JOIN ATOMIC.mvw_product_sk_lookup  mv1
                                                         ON a.v_claim_coverage_code_r = mv1.v_claim_coverage_code_r
                                                        AND a.n_claim_sk_r = mv1.n_claim_sk_r
                                            LEFT OUTER JOIN ATOMIC.dim_grp_product_r     pd1
                                                         ON mv1.n_product_sk_r = pd1.n_product_sk_r
                                            LEFT JOIN ATOMIC.dim_grp_claim_coverage_group_r f
                                                   ON f.n_claim_coverage_sk_r = a.n_claim_coverage_sk_r
                                                  AND f.v_active_status_r = 'N'
                                            LEFT OUTER JOIN ATOMIC.mvw_product_sk_lookup mv2
                                                         ON f.v_claim_coverage_code_r = mv2.v_claim_coverage_code_r
                                                        AND f.n_claim_sk_r = mv2.n_claim_sk_r
                                            LEFT OUTER JOIN ATOMIC.dim_grp_product_r pd2
                                                         ON mv2.n_product_sk_r = pd2.n_product_sk_r
                                            LEFT JOIN ATOMIC.dim_grp_policy_dir_r g
                                                   ON a.n_policy_sk_r = g.n_policy_sk_r
                                                  AND g.v_active_status_r = 'N'
                                            LEFT JOIN ATOMIC.fct_grp_policy_r  h
                                                   ON g.n_policy_sk_r = h.n_policy_sk_r
                                                  AND g.n_policy_version_number_r = h.n_version_number_r
                                                  AND g.n_source_system_key_r = h.n_source_system_key_r
                                            LEFT JOIN ATOMIC.DIM_GRP_SYSUSESO_R ON UPPER(dim_grp_sysuseso_r.v_login_id_r) = UPPER(A.v_assignment_id_r )
                                            LEFT JOIN ATOMIC.DIM_GRP_SYSUSESO_R ON UPPER(dim_grp_sysuseso_r.v_login_id_r) = UPPER(A.v_s_created_by_r  )
                                            LEFT JOIN Atomic.Dim_Grp_Sysuseso_R ON UPPER(dim_grp_sysuseso_r.v_login_id_r) = UPPER(A.v_cell_worker_id_r)
                                            );

          ln_rec_cnt := SQL%ROWCOUNT;

          commit;

		EXECUTE IMMEDIATE 'ALTER SESSION DISABLE PARALLEL DML';

          gv_trcmsg := '4.4 END: DELETING PHYSICAL RECORDS .Total records deleted : '||ln_rec_cnt;

          gt_end_time := SYSTIMESTAMP;

          PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
                (    p_job_id_r                    => gn_out_job_id
                    ,p_batch_id_r                  => gn_sysdt_batchid
                    ,p_message_type_r              => gv_message_type
                    ,p_code_location_r             => gv_main_loadedby
                    ,p_message_r                   => gv_trcmsg
                    ,p_count_type_r                => gv_count_type_delete
                    ,p_count_r                     => ln_rec_cnt
                    ,p_duration_r                  => FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
                    ,p_created_by_r                => GV_JOB_NAME
                    ,out_prcs_job_log_message_id_r => gn_job_log_message_id
                    );

    EXCEPTION
            WHEN OTHERS THEN

        gv_errmsg :=SUBSTR(SQLERRM,1,4000);
        gv_trcmsg:='4.Z Error in prc_upd_del_data '||gv_errmsg;

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

    END PRC_DEL_EXT_DATA;

--Main procedures calls other procedure to load data in RPT_CLEINT_DTL_R
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
      lv_rpt_table 		    PRCS_JOB_LOG_R.CREATED_BY_R%TYPE                := 'RPT_CLAIM_TASK_R';
        ln_rec_cnt          PLS_INTEGER	                                    := 0 ;
        ln_ROW_CNT          PLS_INTEGER	                                    := 0 ;
        ln_idx_num			PLS_INTEGER									    := 8 ;

        ld_fic_mis_date_2 DATE;
        ln_fisc_current_month NUMBER;

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

        -- SET JOB TO IN-PROGRESS
        UPDATE SSL_PACKAGE_MILESTONE_TABLE SET
            JOB_TIMESTAMP   = CURRENT_TIMESTAMP,
            JOB_STATUS      = 'IN-PROGRESS'
        WHERE JOB_NAME='PKG_GRP_LOAD_RPT_CLAIM_TASK_R_INC';
        COMMIT;

     ---2. Call procedure prc_upd_del_data to update active status to N for the records in Fisc prior month
    ---Also, Truncate the current Partion month data if any data present already.
  /*  PKG_GRP_COMMON_UTIL.prc_upd_del_data
					( p_out_job_id	 				=> gn_out_job_id
					 ,p_rpt_table 					=> lv_rpt_table
					 ,p_upd_flag 					=> gv_no_ind
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

    ---3. Call local procedure prc_del_ext_data to delete exiting records .
    prc_del_ext_data;

   /*START: NEW LOGGING MECHANISM CHANGES*/
    gv_trcmsg:='5. Data Load starts ';

	gt_start_time:= SYSTIMESTAMP;

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

    ln_rec_cnt := 0;
/*END: NEW LOGGING MECHANISM CHANGES*/
    INSERT /* + APPEND */ INTO RPT_CLAIM_TASK_R
         select /*+ PARALLEL(4) */ DISTINCT
          a.V_ASSIGNMENT_ID_R                             AS  V_ASSIGNMENT_ID_R
        , a.V_ASSIGN_TYPE_R                               AS  V_ASSIGN_TYPE_R
        , a.N_AUTO_EXPIRE_R                               AS  N_AUTO_EXPIRE_R
        , a.V_CELL_WORKER_ID_R                            AS  V_CELL_WORKER_ID_R
        , a.d_active_date_r                               AS  d_active_date_r
        , a.n_active_time_r                               AS  n_active_time_r
        , a.d_change_date_r                               AS  d_change_date_r
        , a.d_completed_date_r                            AS  d_completed_date_r
        , a.n_completed_time_r                            AS  n_completed_time_r
        , a.V_s_CREATED_BY_R                              AS  V_s_CREATED_BY_R
        , a.d_created_date_r                              AS  d_created_date_r
        , a.n_created_time_r                              AS  n_created_time_r
        , a.V_CURRENT_STATUS_R                            AS  V_CURRENT_STATUS_R
        , a.V_DESCRIPTION_R                               AS  V_DESCRIPTION_R
        , a.D_DUE_DATE_R                                  AS  D_DUE_DATE_R
        , a.n_due_time_r                                  AS  n_due_time_r
        , a.V_TASK_ID_R                                   AS  V_TASK_ID_R
        , a.V_TASK_INST_DETAILS_R                         AS  V_TASK_INST_DETAILS_R
        , a.V_TASK_METHOD_R                               AS  V_TASK_METHOD_R
        , a.N_PRIORITY_R                                  AS  N_PRIORITY_R
        , a.N_SOURCE_VERSION_SEQ_NUMBER_R                 AS  N_SOURCE_VERSION_SEQ_NUMBER_R
        , a.V_TASK_STATUS_R                               AS  V_TASK_STATUS_R
        , a.N_SYSTEM_ASSIGNED_R                           AS  N_SYSTEM_ASSIGNED_R
        , a.V_TASK_TYPE_R                                 AS  V_TASK_TYPE_R
        , a.D_WARNING_DATE_R                              AS  D_WARNING_DATE_R
        , a.n_warning_time_r                              AS  n_warning_time_r
        , a.V_RECORD_TYPE_R                               AS  V_RECORD_TYPE_R
        , a.n_employee_sk_r                               AS  n_employee_sk_r
        , a.N_Claim_Sk_r                                  AS  N_Claim_Sk_r
        , a.n_claim_coverage_sk_r                         AS  n_claim_coverage_sk_r
        , a.n_claim_coverage_group_sk_r                   AS  n_claim_coverage_group_sk_r
        , a.N_POLICY_SK_R                                 AS  N_POLICY_SK_R
        , a.N_CUST_PARTY_SK_R                             AS  N_CUST_PARTY_SK_R
        , a.n_product_sk_r                                AS  n_product_sk_r
        , gv_main_loadedby                                AS  v_last_modified_by_r
        , SYSTIMESTAMP                                    AS  t_creation_date_r
        , gv_main_loadedby                                AS  v_created_by_r
        , SYSTIMESTAMP                                    AS  t_last_modified_date_r
        , gn_current_month                                AS  n_yearmonth_r
        , 'Y'                                             AS  v_rpt_active_status_r
        , gn_sysdt_batchid                                AS  n_batch_id_r
        , a.V_IS_DAYS_ELAPSED_R                           AS  V_IS_DAYS_ELAPSED_R
        , a.N_DAYS_FROM_DUE_DATE_R                        AS  N_DAYS_FROM_DUE_DATE_R
        , a.N_TURNAROUND_TIME_R                           AS  N_TURNAROUND_TIME_R
        , a.V_TASK_ASSIGNED_BY_NAME_R                     AS  V_TASK_ASSIGNED_BY_NAME_R
        , a.V_TASK_CREATED_BY_NAME_R                      AS  V_TASK_CREATED_BY_NAME_R
        , a.V_TASK_CELLWORKER_NAME_R                      AS  V_TASK_CELLWORKER_NAME_R
        , a.N_TASK_SEQUENCE_R                             AS  N_TASK_SEQUENCE_R
 from (SELECT
          a.V_ASSIGNMENT_ID_R                             AS  V_ASSIGNMENT_ID_R
        , a.V_ASSIGN_TYPE_R                               AS  V_ASSIGN_TYPE_R
        , a.N_AUTO_EXPIRE_R                               AS  N_AUTO_EXPIRE_R
        , a.V_CELL_WORKER_ID_R                            AS  V_CELL_WORKER_ID_R
        , a.D_ACTIVE_DATE_R                               AS  D_ACTIVE_DATE_R
        , a.N_ACTIVE_TIME_R                               AS  N_ACTIVE_TIME_R
        , a.D_CHANGE_DATE_R                               AS  D_CHANGE_DATE_R
        , a.D_COMPLETED_DATE_R                            AS  D_COMPLETED_DATE_R
        , a.N_COMPLETED_TIME_R                            AS  N_COMPLETED_TIME_R
        , a.V_s_CREATED_BY_R                              AS  V_s_CREATED_BY_R
        , a.D_CREATED_DATE_R                              AS  D_CREATED_DATE_R
        , a.N_CREATED_TIME_R                              AS  N_CREATED_TIME_R
        , a.V_CURRENT_STATUS_R                            AS  V_CURRENT_STATUS_R
        , a.V_DESCRIPTION_R                               AS  V_DESCRIPTION_R
        , a.D_DUE_DATE_R                                  AS  D_DUE_DATE_R
        , a.N_DUE_TIME_R                                  AS  N_DUE_TIME_R
        , a.V_TASK_ID_R                                   AS  V_TASK_ID_R
        , a.V_TASK_INST_DETAILS_R                         AS  V_TASK_INST_DETAILS_R
        , a.V_TASK_METHOD_R                               AS  V_TASK_METHOD_R
        , a.N_PRIORITY_R                                  AS  N_PRIORITY_R
        , a.N_SOURCE_VERSION_SEQ_NUMBER_R                 AS  N_SOURCE_VERSION_SEQ_NUMBER_R
        , a.V_TASK_STATUS_R                               AS  V_TASK_STATUS_R
        , a.N_SYSTEM_ASSIGNED_R                           AS  N_SYSTEM_ASSIGNED_R
        , a.V_TASK_TYPE_R                                 AS  V_TASK_TYPE_R
        , a.D_WARNING_DATE_R                              AS  D_WARNING_DATE_R
        , a.N_WARNING_TIME_R                              AS  N_WARNING_TIME_R
        , a.V_RECORD_TYPE_R                               AS  V_RECORD_TYPE_R
        , d.n_employee_sk_r                               AS  n_employee_sk_r
        , a.N_Claim_Sk_r 					              AS  N_Claim_Sk_r
        , a.n_claim_coverage_sk_r 						  AS  n_claim_coverage_sk_r
        , f.n_claim_coverage_group_sk_r 				  AS  n_claim_coverage_group_sk_r
        , g.N_POLICY_SK_R                                 AS  N_POLICY_SK_R
        , h.N_CUST_PARTY_SK_R                             AS  N_CUST_PARTY_SK_R
        , NVL(pd2.n_product_sk_r , pd1.n_product_sk_r)    AS  n_product_sk_r
        , CASE
             WHEN a.v_task_status_r = 'OPEN'
             THEN 'Days Elapsed'
             ELSE ''
          END                                              AS V_IS_DAYS_ELAPSED_R
        , CASE
             WHEN a.v_task_status_r IN ( 'FORWARD' )
               OR a.v_task_status_r    = 'OPEN'
              AND a.d_due_date_r      < SYSDATE
             THEN ( SYSDATE - TRUNC(a.d_due_date_r) )
          END                                             AS N_DAYS_FROM_DUE_DATE_R
        , CASE
            WHEN a.v_task_status_r = 'COMPLETE'
            THEN ( TRUNC(a.d_completed_date_r)
                 - TRUNC(a.d_created_date_r) )
          END                                             AS  N_TURNAROUND_TIME_R
        , DIM_GRP_SYSUSESO_R.V_DESCRIPTION_R              AS V_TASK_ASSIGNED_BY_NAME_R
        , DIM_GRP_SYSUSESO_R.V_DESCRIPTION_R              AS V_TASK_CREATED_BY_NAME_R
        , DIM_GRP_SYSUSESO_R.V_DESCRIPTION_R              AS V_TASK_CELLWORKER_NAME_R
        , a.t_last_modified_date_r                        AS t_last_modified_date_r
        , a.N_TASK_SEQUENCE_R                             AS N_TASK_SEQUENCE_R
    FROM (  SELECT  /*+PARALLEL(4)*/
                    a.n_claim_sk_r                        AS N_Claim_Sk_R
                 ,  a.V_ASSIGNMENT_ID_R                   AS V_ASSIGNMENT_ID_R
                 ,  a.V_ASSIGN_TYPE_R                     AS V_ASSIGN_TYPE_R
                 ,  a.N_AUTO_EXPIRE_R                     AS N_AUTO_EXPIRE_R
                 ,  a.V_CELL_WORKER_ID_R                  AS V_CELL_WORKER_ID_R
                 ,  trunc(a.d_active_date_r)              AS D_ACTIVE_DATE_R
                 ,  CASE
                    WHEN a.n_active_time_r IS NULL
                    THEN ''
                    ELSE
                        TO_CHAR(TRUNC(a.n_active_time_r / 3600), 'FM00') || ':' ||
                        TO_CHAR(TRUNC(MOD(a.n_active_time_r, 3600) / 60), 'FM00') || ':' ||
                        TO_CHAR(MOD(a.n_active_time_r, 60), 'FM00')
                    END                                   AS N_ACTIVE_TIME_R
                 ,  trunc(a.d_change_date_r)              AS D_CHANGE_DATE_R
                 ,  trunc(a.d_completed_date_r)           AS D_COMPLETED_DATE_R
                 ,  CASE
                       WHEN a.n_completed_time_r IS NULL
                       THEN ''
                    ELSE
                        to_char(trunc(a.n_completed_time_r / 3600),'FM00') ||':' ||
                        to_char(trunc(mod(a.n_completed_time_r, 3600) / 60),'FM00')  || ':' ||
                        to_char(mod(a.n_completed_time_r, 60), 'FM00')
                     END                                  AS N_COMPLETED_TIME_R
                 ,  a.V_s_CREATED_BY_R                    AS V_s_CREATED_BY_R
                 ,  trunc(a.d_created_date_r)             AS D_CREATED_DATE_R
                 ,  CASE
                    WHEN a.n_created_time_r IS NULL THEN ''
                    ELSE
                        TO_CHAR(TRUNC(a.n_created_time_r / 3600), 'FM00') || ':' ||
                        TO_CHAR(TRUNC(MOD(a.n_created_time_r, 3600) / 60), 'FM00') || ':' ||
                        TO_CHAR(MOD(a.n_created_time_r, 60), 'FM00')
                    END                                   AS N_CREATED_TIME_R
                 ,  a.V_CURRENT_STATUS_R                  AS V_CURRENT_STATUS_R
                 ,  a.V_DESCRIPTION_R                     AS V_DESCRIPTION_R
                 ,  trunc(a.D_DUE_DATE_R  )               AS D_DUE_DATE_R
                 ,  CASE
                    WHEN a.n_due_time_r IS NULL THEN  ''
                    ELSE
                        TO_CHAR(TRUNC(a.n_due_time_r / 3600), 'FM00') || ':' ||
                        TO_CHAR(TRUNC(MOD(a.n_due_time_r, 3600) / 60), 'FM00') || ':' ||
                        TO_CHAR(MOD(a.n_due_time_r, 60), 'FM00')
                    END                                   AS N_DUE_TIME_R
                 ,  a.V_TASK_ID_R                         AS V_TASK_ID_R
                 ,  a.V_TASK_INST_DETAILS_R               AS V_TASK_INST_DETAILS_R
                 ,  a.V_TASK_METHOD_R                     AS V_TASK_METHOD_R
                 ,  a.N_PRIORITY_R                        AS N_PRIORITY_R
                 ,  a.N_SOURCE_VERSION_SEQ_NUMBER_R       AS N_SOURCE_VERSION_SEQ_NUMBER_R
                 ,  a.V_TASK_STATUS_R                     AS V_TASK_STATUS_R
                 ,  a.N_SYSTEM_ASSIGNED_R                 AS N_SYSTEM_ASSIGNED_R
                 ,  a.V_TASK_TYPE_R                       AS V_TASK_TYPE_R
                 ,  trunc(a.D_WARNING_DATE_R)             AS D_WARNING_DATE_R
                 ,  CASE
                    WHEN a.n_warning_time_r IS NULL THEN ''
                    ELSE
                        TO_CHAR(TRUNC(a.n_warning_time_r / 3600), 'FM00') || ':' ||
                        TO_CHAR(TRUNC(MOD(a.n_warning_time_r, 3600) / 60), 'FM00') || ':' ||
                        TO_CHAR(MOD(a.n_warning_time_r, 60), 'FM00')
                    END                                   AS N_WARNING_TIME_R
                 ,  a.RECORD_TYPE AS V_RECORD_TYPE_R
                 ,  c.v_examiner_login_id_r
                 ,  e.n_claim_coverage_sk_r
                 ,  e.v_claim_coverage_code_r
                 ,  b.n_policy_sk_r
                 ,  GREATEST( COALESCE(a.t_last_modified_date_r, TO_DATE('1900-01-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS'))
                            , COALESCE(b.t_last_modified_date_r, TO_DATE('1900-01-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS'))
                            , COALESCE(c.t_last_modified_date_r, TO_DATE('1900-01-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS'))
                            , COALESCE(e.t_last_modified_date_r, TO_DATE('1900-01-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS'))
                             )                            AS t_last_modified_date_r
                 ,  a.N_TASK_SEQUENCE_R                   AS N_TASK_SEQUENCE_R
            FROM ATOMIC.fct_grp_process_custom_r A
                ,ATOMIC.dim_grp_claim_dir_r B
                ,ATOMIC.dim_grp_claim_detail_r C
                ,ATOMIC.dim_grp_claim_coverage_r E
            WHERE a.n_claim_sk_r <> - 1
              AND a.N_CLAIM_SK_R=B.N_CLAIM_SK_R
              AND B.v_active_status_r = 'Y'
              AND a.N_CLAIM_SK_R=c.N_CLAIM_SK_R
              AND c.v_active_status_r = 'Y'
              AND a.N_CLAIM_SK_R=e.N_CLAIM_SK_R
              AND e.v_active_status_r = 'Y'
        ) a
        LEFT JOIN ATOMIC.dim_employee_r d
               ON d.v_employee_login_id_r = a.v_examiner_login_id_r
              AND nvl(upper(d.v_business_unit_r),'CLAIMS') = 'CLAIMS'
        LEFT OUTER JOIN ATOMIC.mvw_product_sk_lookup mv1
                     ON a.v_claim_coverage_code_r = mv1.v_claim_coverage_code_r
                    AND a.n_claim_sk_r = mv1.n_claim_sk_r
        LEFT OUTER JOIN ATOMIC.dim_grp_product_r  pd1
                     ON mv1.n_product_sk_r = pd1.n_product_sk_r
        LEFT JOIN ATOMIC.dim_grp_claim_coverage_group_r f
               ON f.n_claim_coverage_sk_r = a.n_claim_coverage_sk_r
              AND f.v_active_status_r = 'Y'
        LEFT OUTER JOIN ATOMIC.mvw_product_sk_lookup mv2
                     ON f.v_claim_coverage_code_r = mv2.v_claim_coverage_code_r
                    AND f.n_claim_sk_r = mv2.n_claim_sk_r
        LEFT OUTER JOIN ATOMIC.dim_grp_product_r pd2
                     ON mv2.n_product_sk_r = pd2.n_product_sk_r
        LEFT JOIN ATOMIC.dim_grp_policy_dir_r g
               ON a.n_policy_sk_r = g.n_policy_sk_r
              AND g.v_active_status_r = 'Y'
        LEFT JOIN ATOMIC.fct_grp_policy_r h
               ON g.n_policy_sk_r = h.n_policy_sk_r
              AND g.n_policy_version_number_r = h.n_version_number_r
              AND g.n_source_system_key_r = h.n_source_system_key_r
        LEFT JOIN ATOMIC.DIM_GRP_SYSUSESO_R ON UPPER(DIM_GRP_SYSUSESO_R.V_LOGIN_ID_R) = UPPER(A.V_ASSIGNMENT_ID_R )
        LEFT JOIN ATOMIC.DIM_GRP_SYSUSESO_R ON UPPER(DIM_GRP_SYSUSESO_R.V_LOGIN_ID_R) = UPPER(A.V_S_CREATED_BY_R  )
        LEFT JOIN atomic.dim_grp_sysuseso_r ON UPPER(dim_grp_sysuseso_r.v_login_id_r) = UPPER(A.v_cell_worker_id_r)) A
        WHERE a.t_last_modified_date_r >= ( SELECT max(END_DATE)
                                              FROM SSL_PACKAGE_MILESTONE_TABLE
                                             WHERE JOB_NAME='PKG_GRP_LOAD_RPT_CLAIM_TASK_R_INC'
                                           );
  ln_rec_cnt := SQL%ROWCOUNT;

  COMMIT;
   /*Audit Control Code*/
  gn_target_count :=ln_rec_cnt;
   /*Audit Control Code*/
    gv_trcmsg :='5.1:Completed : Data Loaded '||ln_rec_cnt||' records ';

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
    ---6. call procedure prc_rebuild_indexes to rebuild indexes after they were disabled to improve insert performance.
        gv_trcmsg :='6 Rebuild Local Index prc_rebuild_index_partitions from Common Util for Partition: '||gn_current_month;
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

    --22-08-2025: Added Local Index Rebuild
	PKG_GRP_COMMON_UTIL.prc_rebuild_index_partitions
	(
		p_table_name   		  		  => 'RPT_CLAIM_TASK_R',
		p_parallel_degree   		  => 8,
		p_partition_name  		  	  => 'PART_RPT_CLAIM_TASK_R_'||gn_current_month,
		p_out_job_id              	  => gn_out_job_id,
		p_Log_seq_num             	  => 7
	);

        gv_trcmsg:='8 Completed Rebuild Local Index prc_rebuild_index_partitions from Common Util for Partition: '||gn_current_month;
	/*START: NEW LOGGING MECHANISM CHANGES*/
        gt_end_time := SYSTIMESTAMP;
        PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
                (    p_job_id_r                    => gn_out_job_id
                    ,p_batch_id_r                  => gn_sysdt_batchid
                    ,p_message_type_r              => gv_message_type
                    ,p_code_location_r             => gv_rebuildindexes
                    ,p_message_r                   => gv_trcmsg
                    ,p_count_type_r                => NULL
                    ,p_count_r                     => null
                    ,p_duration_r                  => FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
                    ,p_created_by_r                => GV_JOB_NAME
                    ,out_prcs_job_log_message_id_r => gn_job_log_message_id
                    );
        /*END: NEW LOGGING MECHANISM CHANGES*/

				/*Audit Control Code*/

gv_trcmsg :='9 :Audit Control Code as Part of reconcilation between EDW and RPT';
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

     UPDATE SSL_PACKAGE_MILESTONE_TABLE SET
        JOB_TIMESTAMP   = CURRENT_TIMESTAMP,
        JOB_STATUS      = 'SUCCESS',
        START_DATE      = END_DATE,
        END_DATE        = (SELECT MAX(T_LAST_MODIFIED_DATE_R) FROM fct_grp_process_custom_r)
    WHERE JOB_NAME='PKG_GRP_LOAD_RPT_CLAIM_TASK_R_INC';
    COMMIT;

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
END main;

END PKG_GRP_LOAD_RPT_CLAIM_TASK_R_INC;

