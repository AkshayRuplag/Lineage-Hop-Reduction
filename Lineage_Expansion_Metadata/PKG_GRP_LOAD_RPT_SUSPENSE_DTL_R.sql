--------------------------------------------------------
--  DDL for Package Body PKG_GRP_LOAD_RPT_SUSPENSE_DTL_R
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ATOMIC"."PKG_GRP_LOAD_RPT_SUSPENSE_DTL_R" 
IS
/***********************************************************************
  Purpose:  This package body contains procedures which loads data into RPT_SUSPENSE_DTL_R

  Author     Date     Description
  ---------- -------- -------------------------------------------------
  VGireesh   10/11/23 Initial Creation
  VGireesh   31/07/24 Added filter where v_source_system_name_r='VUE') for DIM_GRP_BILLING_POL_BILLGRP_R
  Rose		 13/03/26 Commenting prc_upd_del_data and adding PKG_GRP_COMMON_UTIL.
  awatkins   JUL-13-26 (workitem 524656)
                       Modifying to load data via partition exchange versus kill and fill.
                       Changed joins to ansi standard and cleaned up the code in general to comply with standards.
                       Removed unused procs and replaced with standard utilities. 
                       Implemented audit controls.  

  ***********************************************************************/

 --Global Constants
  gd_sysdate              DATE := trunc(sysdate);
  gn_prior_month          NUMBER := to_number(to_char(add_months(trunc(gd_sysdate,'MM'),-1),'YYYYMM'));
  gn_current_month        NUMBER := to_number(to_char(gd_sysdate,'YYYYMM'));
  gn_sysdt_batchid        NUMBER := to_number(to_char(gd_sysdate,'YYYYMMDD'));
  gc_main_loadedby        VARCHAR2(200 CHAR):= 'PKG_GRP_LOAD_RPT_SUSPENSE_DTL_R.MAIN';
  gc_getcur_loadedby      VARCHAR2(200 CHAR):= 'PKG_GRP_LOAD_RPT_SUSPENSE_DTL_R.PRC_GET_CUR_DATA';
  gc_job_name             VARCHAR2(50 CHAR):= 'GRP_LOAD_RPT_SUSPENSE_DTL_R';
  gc_running_status       VARCHAR2(30):= 'Running';
  gc_error_status         VARCHAR2(30):= 'Error';
  gc_success_status       VARCHAR2(30):= 'Success';
  gc_source               VARCHAR2(30):= 'EDW';
  gc_target               VARCHAR2(30):= 'RPT';
  gc_main_entity          VARCHAR2(30):= 'RPT_SUSPENSE_DTL_R';

	--Global Variables
  gv_trcmsg               CLOB := 'Trace Message:->';
  gn_out_job_id           NUMBER;
  gv_errmsg               VARCHAR2(4000 CHAR);

	--START: 04-JUN-2025: NEW LOGGING MECHANISM CHANGES
  gc_message_type_r       prcs_job_log_message_r.v_message_type_r%TYPE := pkg_grp_log_util.gc_message_type_info;
  gc_count_type_r         prcs_job_log_message_r.v_count_type_r%TYPE := pkg_grp_log_util.gc_count_type_insert;
  gc_count_type_merge_r   prcs_job_log_message_r.v_count_type_r%TYPE := pkg_grp_log_util.gc_count_type_merge;  
  gn_run_cnt              prcs_job_log_message_r.n_count_r%TYPE := 0;

  gt_start_time_r         TIMESTAMP;
  gt_end_time_r           TIMESTAMP;
  gn_job_log_message_id_r NUMBER;

  gd_fic_mis_date         DATE;

  --END: 04-JUN-2025: NEW LOGGING MECHANISM CHANGES 

    --start 13-JUL-26: partition swap additions
  gv_rpt_table_name       CONSTANT prcs_job_log_r.v_job_name_r%TYPE := 'RPT_SUSPENSE_DTL_R';
  gv_exg_table_name       CONSTANT prcs_job_log_r.v_job_name_r%TYPE := gv_rpt_table_name|| '_EXG';
  gv_schema_owner         CONSTANT prcs_job_log_r.v_job_name_r%TYPE := 'ATOMIC'; 
    --end 13-JUL-26: partition swap additions


/***********************************************************************
  Purpose:  Main procedure ultimately loads RPT_SUSPENSE_DTL_R thru partition exchange

  Author     Date     Description
  ---------- -------- -------------------------------------------------
  VGireesh   10/11/23 Initial Creation
  Rose		 13/03/26 Commenting prc_upd_del_data and adding PKG_GRP_COMMON_UTIL.
  awatkins   JUL-13-26 (workitem 524656)
                       Modifying to load data via partition exchange versus kill and fill.
                       Cleaned up the code in general to comply with standards.
                       Removed unused procs and replaced with standard utilities. 
                       Implemented audit controls.  

  ***********************************************************************/
  PROCEDURE main
  IS
    ln_rec_cnt            NUMBER := 0;
    ld_fic_mis_date_2     DATE;
    ln_fisc_current_month NUMBER;
    lv_partition_name     VARCHAR2(200);

  BEGIN
    --Call Log Util pkg to Insert entry in PRCS_JOB_LOG_R
    pkg_grp_log_util.prc_insert_log(
      p_source               => gc_source,
      p_job_nm               => gc_job_name,
      p_job_status           => gc_running_status,
      p_err_msg              => NULL,
      p_trc_msg              => NULL,
      p_n_batch_id           => gn_sysdt_batchid,
      p_log_util_called_by_r => gc_main_loadedby,
      out_job_id             => gn_out_job_id
    );

    gv_trcmsg := '1. Entered into main.';

      --START: NEW LOGGING MECHANISM CHANGES
    pkg_grp_log_util.prc_ins_prcs_job_log_message_r(
      p_job_id_r                    => gn_out_job_id,
      p_batch_id_r                  => gn_sysdt_batchid,
      p_message_type_r              => gc_message_type_r,
      p_code_location_r             => gc_main_loadedby,
      p_message_r                   => gv_trcmsg,
      p_count_type_r                => NULL,
      p_count_r                     => NULL,
      p_duration_r                  => NULL,
      p_created_by_r                => gc_job_name,
      out_prcs_job_log_message_id_r => gn_job_log_message_id_r
    );            
    --END: NEW LOGGING MECHANISM CHANGES

	--Common Utility Proc to get month end+2 date and month. Ex: If month end is 29-Aug-2025 then ln_fisc_current_month will be 202509
    pkg_grp_common_util.prc_fisc_month_calc(
      p_out_job_id          => gn_out_job_id,
      p_log_seq_num         => 2,
      ld_fic_mis_date_2     => ld_fic_mis_date_2,
      ln_fisc_current_month => ln_fisc_current_month
    );

    gd_fic_mis_date := ld_fic_mis_date_2;
    --29-Aug-2024 changes

		--Common Utility Proc to determine current and prior month ; Checks for month end logic and daily load logic as well 
    pkg_grp_common_util.prc_get_current_prior_month(
      p_out_job_id         => gn_out_job_id,
      p_log_seq_num        => 3,
      p_fic_mis_date       => ld_fic_mis_date_2,
      p_fisc_current_month => ln_fisc_current_month,
      p_current_month      => gn_current_month,
      p_prior_month        => gn_prior_month
    );

    --start 30-JUN-26: partition swap additions
    lv_partition_name := 'PART_'|| gv_rpt_table_name|| '_'|| gn_current_month;

    pkg_grp_common_util.prc_create_exchange_table_ddl(
      p_job_id          => gn_out_job_id,
      p_log_seq_num     => 4,
      p_main_table_name => gv_rpt_table_name,
      p_exg_table_name  => gv_exg_table_name,
      p_schema_name     => gv_schema_owner
    );

    pkg_grp_load_rpt_suspense_dtl_r.prc_get_cur_data;

   --start 13-JUL-26: adding code for partition swapping and removing old
    --no longer kill and fill logic 

    pkg_grp_common_util.prc_partition_exchange(
      p_job_id          => gn_out_job_id,
      p_log_seq_num     => 6,
      p_main_table_name => gv_rpt_table_name,
      p_exg_table_name  => gv_exg_table_name,
      p_partition_name  => lv_partition_name,
      p_schema_name     => gv_schema_owner
    );        

    gv_trcmsg := '7. Rebuild Local Index prc_rebuild_index_partitions from Common Util for Partition: '|| gn_current_month;
    gt_start_time_r := systimestamp;

    pkg_grp_log_util.prc_ins_prcs_job_log_message_r(
      p_job_id_r                    => gn_out_job_id,
      p_batch_id_r                  => gn_sysdt_batchid,
      p_message_type_r              => gc_message_type_r,
      p_code_location_r             => gc_main_loadedby,
      p_message_r                   => gv_trcmsg,
      p_count_type_r                => NULL,
      p_count_r                     => NULL,
      p_duration_r                  => NULL,
      p_created_by_r                => gc_job_name,
      out_prcs_job_log_message_id_r => gn_job_log_message_id_r
    );            

    pkg_grp_common_util.prc_rebuild_index_partitions(
      p_table_name      => gv_rpt_table_name,
      p_parallel_degree => 8,
      p_partition_name  => lv_partition_name,
      p_out_job_id      => gn_out_job_id,
      p_log_seq_num     => 7
    );

    gv_trcmsg := '7.z Completed Procedure prc_rebuild_indexes call from main';

    --START: NEW LOGGING MECHANISM CHANGES
    pkg_grp_log_util.prc_ins_prcs_job_log_message_r(
      p_job_id_r                    => gn_out_job_id,
      p_batch_id_r                  => gn_sysdt_batchid,
      p_message_type_r              => gc_message_type_r,
      p_code_location_r             => gc_main_loadedby,
      p_message_r                   => gv_trcmsg,
      p_count_type_r                => NULL,
      p_count_r                     => NULL,
      p_duration_r                  => NULL,
      p_created_by_r                => gc_job_name,
      out_prcs_job_log_message_id_r => gn_job_log_message_id_r
    );        
    --END: NEW LOGGING MECHANISM CHANGES

		gv_trcmsg:='9.0 Calling Audit control Process';
    gt_start_time_r := systimestamp;    

    SELECT COUNT(1)
    INTO ln_rec_cnt
    FROM atomic.rpt_suspense_dtl_r
    WHERE n_yearmonth_r = gn_current_month;

    PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
     (
      p_job_id_r                    => gn_out_job_id,
      p_batch_id_r                  => gn_sysdt_batchid,
      p_message_type_r              => gc_message_type_r,
      p_code_location_r             => gc_main_loadedby,
      p_message_r                   => gv_trcmsg,
      p_count_type_r                => 'AUDIT_TARGET_COUNT',
      p_count_r                     => ln_rec_cnt,
      p_duration_r                  => NULL,
      p_created_by_r                => GC_JOB_NAME,
      out_prcs_job_log_message_id_r => gn_job_log_message_id_r
    );	

		PRC_GRP_AUDIT_CONTROL_PROCESS (
      p_source_system     => gc_source,
      p_main_entity       => gc_main_entity,
      p_source_layer_name => gc_source,
      p_target_layer_name => gc_target);

		gv_trcmsg:='9.1 Post Audit Control Procedure';
    gt_end_time_r := systimestamp;

		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
		 (
			p_job_id_r                    => gn_out_job_id,
			p_batch_id_r                  => gn_sysdt_batchid,
			p_message_type_r              => gc_message_type_r,
			p_code_location_r             => gc_main_loadedby,
			p_message_r                   => gv_trcmsg,
			p_count_type_r                => NULL,
			p_count_r                     => NULL,
			p_duration_r                  => fnc_grp_time_duration(gt_start_time_r,gt_end_time_r),
			p_created_by_r                => GC_JOB_NAME,
			out_prcs_job_log_message_id_r => gn_job_log_message_id_r
		);

    gv_trcmsg := '1.z Exit from main';
    pkg_grp_log_util.prc_ins_prcs_job_log_message_r(
      p_job_id_r                    => gn_out_job_id,
      p_batch_id_r                  => gn_sysdt_batchid,
      p_message_type_r              => gc_message_type_r,
      p_code_location_r             => gc_main_loadedby,
      p_message_r                   => gv_trcmsg,
      p_count_type_r                => NULL,
      p_count_r                     => NULL,
      p_duration_r                  => NULL,
      p_created_by_r                => gc_job_name,
      out_prcs_job_log_message_id_r => gn_job_log_message_id_r
    );            

    pkg_grp_log_util.prc_update_log(
      p_job_id               => gn_out_job_id,
      p_job_status           => gc_success_status,
      p_err_msg              => gv_errmsg,
      p_trc_msg              => gv_trcmsg,
      p_log_util_called_by_r => gc_main_loadedby
    );

  EXCEPTION
    WHEN OTHERS THEN
      gv_errmsg := substr(sqlerrm,1,4000);
      gv_trcmsg := '1. Error in main'|| gv_errmsg;

		--START: 04-JUN-2025: NEW LOGGING MECHANISM CHANGES
      pkg_grp_log_util.prc_update_log_message_r(
        n_prcs_job_log_message_id_r => gn_job_log_message_id_r,
        p_err_msg                   => gv_trcmsg
      );
		--END: 04-JUN-2025: NEW LOGGING MECHANISM CHANGES

      pkg_grp_log_util.prc_update_log(
        p_job_id                => gn_out_job_id,
        p_job_status            => gc_error_status,
        p_err_msg               => gv_errmsg,
        p_trc_msg               => gv_trcmsg,
        p_log_util_called_by_r  => gc_main_loadedby
      );

      RAISE;
  END main;

/*************************************************************************************************************************************
  Purpose:   prc_get_cur_data procedures inserts data to reporting exchange table
  Author     Date     	Description
  ---------- -------- 	-------------------------------------------------
  VGireesh   10/11/23 Initial Creation
  awatkins   JUL-13-26 (workitem 524656)
                       Modifying to load data via partition exchange versus kill and fill.
                       Changed joins to ansi standard and cleaned up the code in general to comply with standards.

*************************************************************************************************************************************/     
  PROCEDURE prc_get_cur_data AS
  BEGIN
    gv_trcmsg := '5.1 Entered into prc_get_cur_data ';

         --START: NEW LOGGING MECHANISM CHANGES
    pkg_grp_log_util.prc_ins_prcs_job_log_message_r(
      p_job_id_r                    => gn_out_job_id,
      p_batch_id_r                  => gn_sysdt_batchid,
      p_message_type_r              => gc_message_type_r,
      p_code_location_r             => gc_getcur_loadedby,
      p_message_r                   => gv_trcmsg,
      p_count_type_r                => NULL,
      p_count_r                     => NULL,
      p_duration_r                  => NULL,
      p_created_by_r                => gc_job_name,
      out_prcs_job_log_message_id_r => gn_job_log_message_id_r
    );               
    --END: NEW LOGGING MECHANISM CHANGES

    EXECUTE IMMEDIATE 'ALTER SESSION ENABLE PARALLEL DML';
    gv_trcmsg := '5.2 - Data load starts for _EXG table for Partition Exchange';
    gt_start_time_r := systimestamp; 

    pkg_grp_log_util.prc_ins_prcs_job_log_message_r(
      p_job_id_r                    => gn_out_job_id,
      p_batch_id_r                  => gn_sysdt_batchid,
      p_message_type_r              => gc_message_type_r,
      p_code_location_r             => gc_getcur_loadedby,
      p_message_r                   => gv_trcmsg,
      p_count_type_r                => NULL,
      p_count_r                     => NULL,
      p_duration_r                  => NULL,
      p_created_by_r                => gc_job_name,
      out_prcs_job_log_message_id_r => gn_job_log_message_id_r
    );               

    --20260713 part of partition swap change
    --removed the old open select into ref cursor and replaced with
    --insert into exchange table;
    --also renamed the aliases to add meaning 

    INSERT /*+ APPEND PARALLEL(stg, 4) */ INTO RPT_suspense_dtl_R_exg stg
    SELECT /*+ PARALLEL(4) */ 
      plcy_suspns.d_delete_date_r        AS d_posted_date_r,
      plcy_suspns.d_due_date_r           AS d_suspense_due_date_r,
      plcy_suspns.d_insert_date_r        AS d_suspense_insert_date_r,
      CAST(NULL AS NUMBER)               AS n_most_recent_premium_amount_r,
      plcy_suspns.d_transaction_date_r   AS d_suspense_date_r,
      (sysdate - plcy_suspns.d_transaction_date_r)   AS n_days_in_suspense_r,
      plcy_suspns.n_amount_r             AS n_suspense_amount_r,
      plcy.n_cust_party_sk_r             AS n_cust_party_sk_r,
      CASE
        WHEN plcy_suspns.n_is_cash_error_r = '1' 
        THEN 'Yes'
        ELSE 'No'
      END                                   AS v_cash_error_ind_r,
      billgrp.n_policy_billgroup_sk_r       AS n_billgroup_sk_r,
      plcy_dir.n_policy_sk_r                 AS n_policy_sk_r,
      plcy_suspns.n_src_policy_billgroup_id_r   AS n_src_policy_billgroup_id_r,
      plcy_suspns.n_src_policy_id_r             AS n_src_policy_id_r,
      plcy_suspns.n_src_suspense_premium_id_r   AS n_suspense_premium_id_r,
      plcy_suspns.v_description_r               AS v_suspense_description_r,
      nvl(sec_user.v_full_name_r,plcy_suspns.v_suspense_operator_r) AS v_suspense_operator_fullname_r,
      plcy_suspns.v_suspense_operator_r         AS v_suspense_operator_r,
      plcy_suspns.v_user_name_r                 AS v_suspense_operator_username_r,
      gc_main_loadedby                AS v_last_modified_by_r,
    	gd_sysdate                      AS t_creation_date_r,
    	gc_main_loadedby                AS v_created_by_r,
    	gd_sysdate                      AS t_last_modified_date_r,
    	gn_current_month                AS n_yearmonth_r,
    	'Y'                             AS v_rpt_active_status_r,
    	gn_sysdt_batchid                AS n_batch_id_r
    FROM atomic.fct_billing_policy_suspense_r plcy_suspns
    INNER JOIN atomic.dim_grp_policy_dir_r plcy_dir
    ON plcy_suspns.n_policy_sk_r = plcy_dir.n_policy_sk_r
    INNER JOIN atomic.dim_sec_user_r sec_user
    ON upper(nvl(plcy_suspns.v_update_by_r,plcy_suspns.v_insert_by_r))= upper(sec_user.v_login_r)
    INNER JOIN atomic.dim_grp_billing_pol_billgrp_r billgrp
    ON billgrp.n_policy_billgroup_id_r = plcy_suspns.n_src_policy_billgroup_id_r
    AND billgrp.v_source_system_name_r = 'VUE'
    AND billgrp.v_active_status_r = 'Y'
    INNER JOIN atomic.fct_grp_policy_r plcy
    ON plcy_dir.n_policy_sk_r = plcy.n_policy_sk_r
    AND plcy_dir.n_policy_version_number_r = plcy.n_version_number_r
    AND plcy_dir.n_source_system_key_r = plcy.n_source_system_key_r
    AND plcy_dir.v_active_status_r = 'Y'
    --13-JUL-26
    --this "f" entity serves no purpose to the query but to filter
    --data, so it was eliminated and an IN filter was added to the where
    --clause.  Super confusing what this is trying to accomplish.
    --I think it can be done with windowing clauses but served nothing
    --to the output.
    --INNER JOIN (
    --  SELECT SUM(t1996431.n_amount_paid_r),
    --         t1996431.n_src_policy_billgroup_id_r
    --  FROM atomic.fct_billing_policy_premium_r t1996431
    --  INNER JOIN (
    --    SELECT n_src_policy_billgroup_id_r,
    --           MAX(d_due_date_r)d_max_due_date_r
    --    FROM atomic.fct_billing_policy_premium_r
    --    GROUP BY n_src_policy_billgroup_id_r
    --    ) t1995378
    --  ON t1995378.n_src_policy_billgroup_id_r = t1996431.n_src_policy_billgroup_id_r
    --  AND t1996431.d_due_date_r = t1995378.d_max_due_date_r
    --  INNER JOIN (
    --    SELECT n_src_premium_payment_id_r,
    --           MAX(nvl(n_src_net_premium_id_r,1))n_max_net_premium_id_r
    --    FROM atomic.fct_billing_policy_premium_r
    --    GROUP BY n_src_premium_payment_id_r
    --    ) t1997343
    --  ON t1996431.n_src_premium_payment_id_r = t1997343.n_src_premium_payment_id_r
    --  AND t1997343.n_max_net_premium_id_r = nvl(t1996431.n_src_net_premium_id_r,1)
    --  GROUP BY t1996431.n_src_policy_billgroup_id_r
    --  ) f
    --ON plcy_suspns.n_src_policy_billgroup_id_r = f.n_src_policy_billgroup_id_r
    WHERE plcy_suspns.d_delete_date_r IS NULL
    AND plcy_suspns.n_src_policy_billgroup_id_r IN (
      SELECT n_src_policy_billgroup_id_r
      FROM atomic.fct_billing_policy_premium_r);

    gn_run_cnt := SQL%rowcount;
    COMMIT;

        --end 13-JUL-26: partition swap additions

    gv_trcmsg := '5.2 Completion of insertion';
    gt_end_time_r := systimestamp;

    pkg_grp_log_util.prc_ins_prcs_job_log_message_r(
      p_job_id_r                    => gn_out_job_id,
      p_batch_id_r                  => gn_sysdt_batchid,
      p_message_type_r              => gc_message_type_r,
      p_code_location_r             => gc_getcur_loadedby,
      p_message_r                   => gv_trcmsg,
      p_count_type_r                => gc_count_type_r,
      p_count_r                     => gn_run_cnt,
      p_duration_r                  => fnc_grp_time_duration(gt_start_time_r,gt_end_time_r),
      p_created_by_r                => gc_job_name,
      out_prcs_job_log_message_id_r => gn_job_log_message_id_r
    );	       
    --END: NEW LOGGING MECHANISM CHANGES

    EXECUTE IMMEDIATE 'ALTER SESSION DISABLE PARALLEL DML';
    gv_trcmsg := '5.3 exit from prc_get_cur_data';

    pkg_grp_log_util.prc_ins_prcs_job_log_message_r(
      p_job_id_r                    => gn_out_job_id,
      p_batch_id_r                  => gn_sysdt_batchid,
      p_message_type_r              => gc_message_type_r,
      p_code_location_r             => gc_getcur_loadedby,
      p_message_r                   => gv_trcmsg,
      p_count_type_r                => NULL,
      p_count_r                     => NULL,
      p_duration_r                  => NULL,
      p_created_by_r                => gc_job_name,
      out_prcs_job_log_message_id_r => gn_job_log_message_id_r
    );            	  

        --end 30-JUN-26: partition swap additions

  EXCEPTION
    WHEN OTHERS THEN
      gv_errmsg := substr(sqlerrm,1,4000);

		--START: 04-JUN-2025: NEW LOGGING MECHANISM CHANGES
      gv_trcmsg := '5.z Error in prc_get_cur_data'|| gv_errmsg;

      pkg_grp_log_util.prc_update_log_message_r(
        n_prcs_job_log_message_id_r => gn_job_log_message_id_r,
        p_err_msg                   => gv_trcmsg
      );
		--END: 04-JUN-2025: NEW LOGGING MECHANISM CHANGES

      pkg_grp_log_util.prc_update_log(
        p_job_id                 => gn_out_job_id,
        p_job_status             => gc_error_status,
        p_err_msg                => gv_errmsg,
        p_trc_msg                => gv_trcmsg,
        p_log_util_called_by_r   => gc_getcur_loadedby
      );

      RAISE;
  END prc_get_cur_data;

END PKG_GRP_LOAD_RPT_SUSPENSE_DTL_R;

/

  GRANT EXECUTE ON "ATOMIC"."PKG_GRP_LOAD_RPT_SUSPENSE_DTL_R" TO "ATOMIC_ALL_RO";
  GRANT EXECUTE ON "ATOMIC"."PKG_GRP_LOAD_RPT_SUSPENSE_DTL_R" TO "EXT_EIS_RO";
  GRANT DEBUG ON "ATOMIC"."PKG_GRP_LOAD_RPT_SUSPENSE_DTL_R" TO "ATOMIC_DEBUG";
