--------------------------------------------------------
--  DDL for Package Body PKG_GRP_LOAD_RPT_PREMIUM_R
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ATOMIC"."PKG_GRP_LOAD_RPT_PREMIUM_R" 
/***********************************************************************
  Purpose:  This package body contains procedures which loads data into RPT_PREMIUM_R

  Author     Date     Description
  ---------- -------- -------------------------------------------------
  VGireesh   10/11/23 Initial Creation
  VGireesh   22/02/24 Enabled rebuilding indexes
  VGireesh   26/02/24 for month end  that the tables start loading data in the next month partition
                      Ex: March data on February 29th (as of 2.28).
                          27th is Feb Fisc Month End    202402  should be truncate and load in 202402 partition
                          28th is feb Fisc Month End +1 202402  should be truncate and load in 202402 partition
                          29th is Feb Fisc Month End +2 202403  should inactive records against the partition 202402 and load data in 202403 partition
  VGireesh   19/03/24 remapped column V_Premium_Coverage_Description_R
  VGireesh   03/04/24 Added Parallel to rebuild index fast  parallel 16 nologging and Commented prc_get_cur_data
  Chandra    19/07/24 Added Where condition DIM_GRP_BILLING_POL_BILLGRP_R.v_source_system_name_r='VUE'  as Requested by Gisha
  VGireesh   31/07/24 Added filter where v_source_system_name_r='VUE') for DIM_GRP_BILLING_POL_BILLGRP_R
  VGireesh   29/08/24 Due to performance issue Converted Daily insert into MERGE thiCommented truncate partition call in the procedure 
					  prc_upd_del_data and introduced prc_merge_data and called in main and commented parallel hint
  Chandra    20/09/24 Added Cloumn D_PREMIUM_MAX_DUE_DATE_R
  Gireesh    16/10/24 Added Column N_MONTHS_PAID_R
  Samba 	 09/10/25 Changed the procedure MERGE functionality to Exchange partition
					  Added full data load using DRQ_MV
					  COnverting Global2Local index
					  Coding standardization

  Kavinissha 15/04/26  Added New Column called D_Premium_Src_Transaction_Date_R for MGIS 5500 Report
                      User Story : 507211
  awatkins   Jul-7-26 (workitem 524650)
                       Cleaned up the code in general to comply with standards.
                       Updated the pattern for partition exchange.                      
***********************************************************************/ 
IS

  gd_sysdate              DATE := trunc(sysdate);
  gn_prior_month          NUMBER := to_number(to_char(add_months(trunc(gd_sysdate, 'MM'), -1), 'YYYYMM'));
  gn_current_month        NUMBER := to_number(to_char(gd_sysdate, 'YYYYMM'));
  gn_sysdt_batchid        NUMBER := to_number(to_char(gd_sysdate, 'YYYYMMDD'));
  gc_main_loadedby        VARCHAR2(100 CHAR) := 'PKG_GRP_LOAD_RPT_PREMIUM_R.MAIN';
  gc_getcur_loadedby      VARCHAR2(100 CHAR) := 'PKG_GRP_LOAD_RPT_PREMIUM_R.PRC_GET_CUR_DATA';

  gv_trcmsg               CLOB := 'Trace Message:->';
  gc_job_name             VARCHAR2(50 CHAR) := 'GRP_LOAD_RPT_PREMIUM_R';

  gc_running_status       VARCHAR2(30) := 'Running';
  gc_error_status         VARCHAR2(30) := 'Error';
  gc_success_status       VARCHAR2(30) := 'Success';
  gc_source               VARCHAR2(30) := 'EDW';
  gc_target               VARCHAR2(30) := 'RPT';
  gc_main_entity          VARCHAR2(30):= 'PREMIUM_R';    
  gn_out_job_id           NUMBER;
  gv_errmsg               VARCHAR2(4000 CHAR);
  gd_fic_mis_date         DATE;

  gc_message_type_r       prcs_job_log_message_r.v_message_type_r%TYPE := pkg_grp_log_util.gc_message_type_info;
  gc_count_type_r         prcs_job_log_message_r.v_count_type_r%TYPE := pkg_grp_log_util.gc_count_type_insert;

  gn_run_cnt              prcs_job_log_message_r.n_count_r%TYPE := 0;

  gt_start_time_r         TIMESTAMP;
  gt_end_time_r           TIMESTAMP;
  gn_job_log_message_id_r NUMBER;
  gn_target_count         NUMBER;

    --start 07-JUL-26: partition swap additions
  gv_rpt_table_name       CONSTANT prcs_job_log_r.v_job_name_r%TYPE := 'RPT_PREMIUM_R';
  gv_exg_table_name       CONSTANT prcs_job_log_r.v_job_name_r%TYPE := gv_rpt_table_name|| '_EXG';
  gv_schema_owner         CONSTANT prcs_job_log_r.v_job_name_r%TYPE := 'ATOMIC'; 
    --end 07-JUL-26: partition swap additions  



/***********************************************************************
  Purpose:  This Main procedure calls other procedure to load data in RPT_PREMIUM_R
---------- -------- -------------------------------------------------
   VGireesh   10/11/23  Initial Creation
   Samba	  09/09/25  Code standrdization.
  awatkins   Jul-7-26 (workitem 524650)
                       Cleaned up the code in general to comply with standards.
                       Updated the pattern for partition exchange.          
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

    pkg_grp_load_rpt_premium_r.prc_get_cur_data;   

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
    FROM atomic.rpt_premium_r
    WHERE N_REPORTMONTH_R = gn_current_month;

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

/***********************************************************************
  Purpose:  This Procedure to MERGE the data other than Fisc Month ENd +2nd day.
---------- -------- -------------------------------------------------
   VGireesh   10/11/23  Initial Creation
   Samba	  09/09/25  Developed first Version.
   Joe        17/02/26  Audit Control Code as part of reconcilation between EDW and RPT.
  awatkins   Jul-7-26 (workitem 524650)
                       Cleaned up the code in general to comply with standards.
                       Updated the pattern for partition exchange.           
***********************************************************************/
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

    INSERT /*+ APPEND PARALLEL(stg, 4) */ INTO rpt_premium_r_exg stg
        SELECT /*+ PARALLEL(src, 4) */
            gn_current_month                     AS n_reportmonth_r,
            v_billing_premium_mode_r             AS v_billing_premium_mode_r,
            v_max_due_date_flag_r                AS v_max_due_date_flag_r,
            v_operator_id_r                      AS v_operator_id_r,
            v_premium_coverage_code_r            AS v_premium_coverage_code_r,
            v_premium_coverage_description_r     AS v_premium_coverage_description_r,
            d_premium_due_date_r                 AS d_premium_due_date_r,
            n_premium_month_paid_r               AS n_premium_month_paid_r,
            v_premium_net_gross_indicator_r      AS v_premium_net_gross_indicator_r,
            d_premium_paid_to_date_r             AS d_premium_paid_to_date_r,
            n_premium_payment_id_r               AS n_premium_payment_id_r,
            v_premium_payment_method_r           AS v_premium_payment_method_r,
            v_premium_payment_premium_type_r     AS v_premium_payment_premium_type_r,
            v_premium_product_line_r             AS v_premium_product_line_r,
            v_premium_product_line_description_r AS v_premium_product_line_description_r,
            v_premium_sub_line_code_r            AS v_premium_sub_line_code_r,
            d_premium_transaction_date_r         AS d_premium_transaction_date_r,
            v_product_line_code_r                AS v_product_line_code_r,
            gc_getcur_loadedby                   AS v_last_modified_by_r,
            systimestamp                         AS t_creation_date_r,
            gc_getcur_loadedby                   AS v_created_by_r,
            systimestamp                         AS t_last_modified_date_r,
            'Y'                                  AS v_rpt_active_status_r,
            gn_sysdt_batchid                     AS n_batch_id_r,
            d_premium_max_due_date_r             AS d_premium_max_due_date_r,
            n_months_paid_r                      AS n_months_paid_r,
            v_source_system_name_r               AS v_source_system_name_r,
            d_premium_src_transaction_date_r     AS d_premium_src_transaction_date_r	 -- Added New Column for MGIS 5500 Report --2026-04-15
        FROM
            atomic.rpt_premium_r_drq_mv_ssl src;

    gn_run_cnt := SQL%rowcount;
    COMMIT;

        --end 30-JUN-26: partition swap additions

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

END pkg_grp_load_rpt_premium_r;

/

  GRANT EXECUTE ON "ATOMIC"."PKG_GRP_LOAD_RPT_PREMIUM_R" TO "ATOMIC_ALL_RO";
  GRANT EXECUTE ON "ATOMIC"."PKG_GRP_LOAD_RPT_PREMIUM_R" TO "EXT_EIS_RO";
  GRANT DEBUG ON "ATOMIC"."PKG_GRP_LOAD_RPT_PREMIUM_R" TO "ATOMIC_DEBUG";
