--------------------------------------------------------
--  DDL for Package Body PKG_GRP_LOAD_RPT_FCT_INCURRED_SUMMARY_R
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ATOMIC"."PKG_GRP_LOAD_RPT_FCT_INCURRED_SUMMARY_R" 
IS
  /***********************************************************************
  Purpose:  This package body contains procedures which loads data into RPT_FCT_INCURRED_SUMMARY_R

  Author     Date     Description
  ---------- -------- -------------------------------------------------
  VGireesh   28/02/24 Initial Creation
  VGireesh   29-Mar-2024 Fisc Month changes
  VGireesh   03/04/24 Added Parallel to rebuild index fast  parallel 16 nologging
  AnanthaJothi 1/13/2026 Added N_CHG_GAAP_OS_DIRECT_AMT_R,N_CHG_GAAP_OS_CEDED_AMT_R,N_CHG_STAT_OS_CEDED_AMT_R,V_PRODUCT_LINE_R, 
                         N_REINSURANCE_PCT_R,N_CHG_STAT_IBNR_CEDED_AMT_R,N_CHG_GAAP_IBNR_CEDED_AMT_R
  Rose		 06/03/26   Commenting prc_upd_del_data and adding PKG_GRP_COMMON_UTIL.
  awatkins   Jul-22-26 (workitem 524663)
                       Modifying to load data via partition exchange versus kill and fill.
                       cleaned up the code in general to comply with standards.
                       Removed unused procs and replaced with standard utilities. 
                       Implemented audit controls.      
  ***********************************************************************/

 --Global Constants
  gd_sysdate              DATE := trunc(sysdate);
  gn_prior_month          NUMBER := to_number(to_char(add_months(trunc(gd_sysdate,'MM'),-1),'YYYYMM'));
  gn_current_month        NUMBER := to_number(to_char(gd_sysdate,'YYYYMM'));
  gn_sysdt_batchid        NUMBER := to_number(to_char(gd_sysdate,'YYYYMMDD'));
  gc_main_loadedby        VARCHAR2(200 CHAR):= 'PKG_GRP_LOAD_RPT_FCT_INCURRED_SUMMARY_R.MAIN';
  gc_getcur_loadedby      VARCHAR2(200 CHAR):= 'PKG_GRP_LOAD_RPT_FCT_INCURRED_SUMMARY_R.PRC_GET_CUR_DATA';
  gc_job_name             VARCHAR2(50 CHAR):= 'GRP_LOAD_RPT_FCT_INCURRED_SUMMARY_R';
  gc_running_status       VARCHAR2(30):= 'Running';
  gc_error_status         VARCHAR2(30):= 'Error';
  gc_success_status       VARCHAR2(30):= 'Success';
  gc_source               VARCHAR2(30):= 'EDW';
  gc_target               VARCHAR2(30):= 'RPT';
  gc_main_entity          VARCHAR2(30):= 'FCT_INCURRED_SUMMARY';

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

    --start 30-JUN-26: partition swap additions
  gv_rpt_table_name       CONSTANT prcs_job_log_r.v_job_name_r%TYPE := 'RPT_FCT_INCURRED_SUMMARY_R';
  gv_exg_table_name       CONSTANT prcs_job_log_r.v_job_name_r%TYPE := gv_rpt_table_name|| '_EXG';
  gv_schema_owner         CONSTANT prcs_job_log_r.v_job_name_r%TYPE := 'ATOMIC'; 
    --end 30-JUN-26: partition swap additions


/***********************************************************************
  Purpose:  Main procedure ultimately loads RPT_FCT_INCURRED_SUMMARY_R thru partition exchange

  Author     Date     Description
  ---------- -------- -------------------------------------------------
  VGireesh   10/11/23 Initial Creation
     Rose		 06/03/26   Commenting prc_upd_del_data and adding PKG_GRP_COMMON_UTIL.	 
  awatkins   Jul-22-26 (workitem 524663)
                       Modifying to load data via partition exchange versus kill and fill.
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

    --start 22-JUL-26: partition swap additions
    lv_partition_name := 'PART_'|| gv_rpt_table_name|| '_'|| gn_current_month;

    pkg_grp_common_util.prc_create_exchange_table_ddl(
      p_job_id          => gn_out_job_id,
      p_log_seq_num     => 4,
      p_main_table_name => gv_rpt_table_name,
      p_exg_table_name  => gv_exg_table_name,
      p_schema_name     => gv_schema_owner
    );

    prc_get_cur_data;   

   --start 22-JUL-26: adding code for partition swapping and removing old
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
    FROM atomic.rpt_fct_incurred_summary_r
    WHERE n_reportmonth_r = gn_current_month;

    pkg_grp_log_util.prc_ins_prcs_job_log_message_r
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

		prc_grp_audit_control_process (
      p_source_system     => gc_source,
      p_main_entity       => gc_main_entity,
      p_source_layer_name => gc_source,
      p_target_layer_name => gc_target);

		gv_trcmsg:='9.1 Post Audit Control Procedure';
    gt_end_time_r := systimestamp;

		pkg_grp_log_util.prc_ins_prcs_job_log_message_r
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
  awatkins   Jul-22-26 (workitem 524663)
                       Modifying to load data via partition exchange versus kill and fill.
                       cleaned up the code in general to comply with standards.

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

    --20260722 part of partition swap change
    --removed the old open select into ref cursor and replaced with
    --insert into exchange table;

    INSERT /*+ APPEND PARALLEL(stg, 4) */ INTO rpt_fct_incurred_summary_r_exg stg (
      n_chg_be_ibnr_direct_amt_r, 
      n_chg_be_os_direct_amt_r, 
      n_chg_be_wv_direct_amt_r, 
      n_chg_due_prem_amt_r, 
      n_chg_field_ibnr_direct_amt_r, 
      n_chg_field_wv_direct_amt_r, 
      n_chg_gaap_ibnr_direct_amt_r, 
      n_chg_gaap_wv_direct_amt_r, 
      n_chg_stat_ibnr_direct_amt_r, 
      n_chg_stat_os_direct_amt_r, 
      n_chg_stat_wv_direct_amt_r, 
      n_chg_prem_unearned_amt_r, 
      n_coll_prem_amt_r, 
      n_const_earned_prem_amt_r, 
      v_coverage_r, 
      n_cum_gaap_ibnr_direct_amt_r, 
      n_cum_stat_ibnr_direct_amt_r, 
      n_curr_annualized_premium_r, 
      n_curr_approved_claim_count_r, 
      n_curr_be_ibnr_direct_amt_r, 
      n_curr_be_direct_amt_r, 
      n_curr_be_os_direct_amt_r, 
      n_curr_be_pv_direct_amt_r, 
      n_curr_be_wv_direct_amt_r, 
      n_curr_claim_count_r, 
      n_curr_denied_claim_count_r, 
      n_curr_field_ibnr_direct_amt_r, 
      n_curr_field_os_direct_amt_r, 
      n_curr_field_wv_direct_amt_r, 
      n_curr_gaap_ibnr_direct_amt_r, 
      n_curr_gaap_os_direct_amt_r, 
      n_curr_gaap_pv_direct_amt_r, 
      n_curr_gaap_wv_direct_amt_r, 
      n_curr_number_of_lives_r, 
      n_curr_plr_r, 
      n_curr_stat_ibnr_direct_amt_r, 
      n_curr_stat_os_direct_amt_r, 
      n_curr_stat_pv_direct_amt_r, 
      n_curr_stat_wv_direct_amt_r, 
      n_earned_prem_amt_r, 
      d_cycle_date_r, 
      d_uw_date_r, 
      n_loss_payment_amt_r, 
      n_prior_be_ibnr_direct_amt_r, 
      n_prior_be_os_direct_amt_r, 
      n_prior_be_wv_direct_amt_r, 
      n_prior_field_ibnr_dir_amt_r, 
      n_prior_field_os_direct_amt_r, 
      n_prior_field_wv_direct_amt_r, 
      n_prior_gaap_ibnr_direct_amt_r, 
      n_prior_gaap_os_direct_amt_r, 
      n_prior_gaap_wv_direct_amt_r, 
      n_prior_stat_ibnr_direct_amt_r, 
      n_prior_stat_os_direct_amt_r, 
      n_prior_stat_wv_direct_amt_r, 
      n_sold_annualized_prem_r, 
      n_total_claim_incurred_be_r, 
      n_total_claim_incurred_field_r, 
      n_total_claim_incurred_gaap_r, 
      n_total_claim_incurred_stat_r, 
      n_written_prem_amt_r, 
      n_cust_party_sk_r, 
      n_policy_sk_r, 
      v_last_modified_by_r, 
      t_creation_date_r, 
      v_created_by_r, 
      t_last_modified_date_r, 
      v_rpt_active_status_r, 
      n_batch_id_r, 
      n_reportmonth_r, 
      n_chg_gaap_os_direct_amt_r, 
      n_chg_gaap_os_ceded_amt_r, 
      n_chg_stat_os_ceded_amt_r, 
      v_product_line_r, 
      n_reinsurance_pct_r, 
      n_chg_stat_ibnr_ceded_amt_r, 
      n_chg_gaap_ibnr_ceded_amt_r, 
      n_chg_gaap_wv_net_amt_r, 
      n_chg_prem_unearned_net_amt_r, 
      n_chg_stat_wv_net_amt_r, 
      n_earned_prem_net_amt_r, 
      n_loss_payment_ceded_amt_r, 
      n_written_prem_ceded_amt_r, 
      n_written_prem_net_amt_r)
    SELECT /*+ PARALLEL(4) */ 
      f_inc_summ.n_chg_be_ibnr_direct_amt_r     AS n_chg_be_ibnr_direct_amt_r,
      f_inc_summ.n_chg_be_os_direct_amt_r       AS n_chg_be_os_direct_amt_r,
      f_inc_summ.n_chg_be_wv_direct_amt_r       AS n_chg_be_wv_direct_amt_r,
      f_inc_summ.n_chg_due_prem_amt_r           AS n_chg_due_prem_amt_r,
      f_inc_summ.n_chg_field_ibnr_direct_amt_r  AS n_chg_field_ibnr_direct_amt_r,
      f_inc_summ.n_chg_field_wv_direct_amt_r    AS n_chg_field_wv_direct_amt_r,
      f_inc_summ.n_chg_gaap_ibnr_direct_amt_r   AS n_chg_gaap_ibnr_direct_amt_r,
      f_inc_summ.n_chg_gaap_wv_direct_amt_r     AS n_chg_gaap_wv_direct_amt_r,
      f_inc_summ.n_chg_stat_ibnr_direct_amt_r   AS n_chg_stat_ibnr_direct_amt_r,
      f_inc_summ.n_chg_stat_os_direct_amt_r     AS n_chg_stat_os_direct_amt_r,
      f_inc_summ.n_chg_stat_wv_direct_amt_r     AS n_chg_stat_wv_direct_amt_r,
      f_inc_summ.n_chg_prem_unearned_amt_r      AS n_chg_prem_unearned_amt_r,
      f_inc_summ.n_coll_prem_amt_r              AS n_coll_prem_amt_r,
      nvl(f_inc_summ.n_const_earned_prem_amt_r,0) AS n_const_earned_prem_amt_r,
      f_inc_summ.v_coverage_r                   AS v_coverage_r,
      f_inc_summ.n_cum_gaap_ibnr_direct_amt_r   AS n_cum_gaap_ibnr_direct_amt_r,
      f_inc_summ.n_cum_stat_ibnr_direct_amt_r   AS n_cum_stat_ibnr_direct_amt_r,
      f_inc_summ.n_curr_annualized_premium_r    AS n_curr_annualized_premium_r,
      f_inc_summ.n_curr_approved_claim_count_r  AS n_curr_approved_claim_count_r,
      f_inc_summ.n_curr_be_ibnr_direct_amt_r    AS n_curr_be_ibnr_direct_amt_r,
      nvl(f_inc_summ.n_curr_be_os_direct_amt_r,0) + 
        nvl(f_inc_summ.n_curr_be_wv_direct_amt_r,0) AS n_curr_be_direct_amt_r,
      f_inc_summ.n_curr_be_os_direct_amt_r      AS n_curr_be_os_direct_amt_r,
      f_inc_summ.n_curr_be_pv_direct_amt_r      AS n_curr_be_pv_direct_amt_r,
      f_inc_summ.n_curr_be_wv_direct_amt_r      AS n_curr_be_wv_direct_amt_r,
      f_inc_summ.n_curr_claim_count_r           AS n_curr_claim_count_r,
      f_inc_summ.n_curr_denied_claim_count_r    AS n_curr_denied_claim_count_r,
      f_inc_summ.n_curr_field_ibnr_direct_amt_r AS n_curr_field_ibnr_direct_amt_r,
      nvl(f_inc_summ.n_curr_field_os_direct_amt_r,0) + 
        nvl(f_inc_summ.n_curr_field_wv_direct_amt_r,0) AS n_curr_field_os_direct_amt_r,
      f_inc_summ.n_curr_field_wv_direct_amt_r   AS n_curr_field_wv_direct_amt_r,
      nvl(f_inc_summ.n_curr_gaap_ibnr_direct_amt_r,0) AS n_curr_gaap_ibnr_direct_amt_r,
      f_inc_summ.n_curr_gaap_os_direct_amt_r    AS n_curr_gaap_os_direct_amt_r,
      f_inc_summ.n_curr_gaap_pv_direct_amt_r    AS n_curr_gaap_pv_direct_amt_r,
      f_inc_summ.n_curr_gaap_wv_direct_amt_r    AS n_curr_gaap_wv_direct_amt_r,
      f_inc_summ.n_curr_number_of_lives_r       AS n_curr_number_of_lives_r,
      f_inc_summ.n_curr_plr_r                   AS n_curr_plr_r,
      f_inc_summ.n_curr_stat_ibnr_direct_amt_r  AS n_curr_stat_ibnr_direct_amt_r,
      f_inc_summ.n_curr_stat_os_direct_amt_r    AS n_curr_stat_os_direct_amt_r,
      f_inc_summ.n_curr_stat_pv_direct_amt_r    AS n_curr_stat_pv_direct_amt_r,
      f_inc_summ.n_curr_stat_wv_direct_amt_r    AS n_curr_stat_wv_direct_amt_r,
      nvl(f_inc_summ.n_earned_prem_amt_r,0)     AS n_earned_prem_amt_r,
      f_inc_summ.d_cycle_date_r                 AS d_cycle_date_r,
      f_inc_summ.d_uw_date_r                    AS d_uw_date_r,
      nvl(f_inc_summ.n_loss_payment_amt_r,0)    AS n_loss_payment_amt_r,
      f_inc_summ.n_prior_be_ibnr_direct_amt_r   AS n_prior_be_ibnr_direct_amt_r,
      f_inc_summ.n_prior_be_os_direct_amt_r     AS n_prior_be_os_direct_amt_r,
      f_inc_summ.n_prior_be_wv_direct_amt_r     AS n_prior_be_wv_direct_amt_r,
      f_inc_summ.n_prior_field_ibnr_dir_amt_r   AS n_prior_field_ibnr_dir_amt_r,
      f_inc_summ.n_prior_field_os_direct_amt_r  AS n_prior_field_os_direct_amt_r,
      f_inc_summ.n_prior_field_wv_direct_amt_r  AS n_prior_field_wv_direct_amt_r,
      f_inc_summ.n_prior_gaap_ibnr_direct_amt_r AS n_prior_gaap_ibnr_direct_amt_r,
      f_inc_summ.n_prior_gaap_os_direct_amt_r   AS n_prior_gaap_os_direct_amt_r,
      f_inc_summ.n_prior_gaap_wv_direct_amt_r   AS n_prior_gaap_wv_direct_amt_r,
      f_inc_summ.n_prior_stat_ibnr_direct_amt_r AS n_prior_stat_ibnr_direct_amt_r,
      f_inc_summ.n_prior_stat_os_direct_amt_r   AS n_prior_stat_os_direct_amt_r,
      f_inc_summ.n_prior_stat_wv_direct_amt_r   AS n_prior_stat_wv_direct_amt_r,
      f_inc_summ.n_sold_annualized_prem_r       AS n_sold_annualized_prem_r,
      nvl(f_inc_summ.n_loss_payment_amt_r,0) + 
        nvl(f_inc_summ.n_curr_be_os_direct_amt_r,0) + 
          nvl(f_inc_summ.n_curr_be_ibnr_direct_amt_r,0) + 
            nvl(f_inc_summ.n_curr_be_wv_direct_amt_r,0) AS n_total_claim_incurred_be_r,
      nvl(f_inc_summ.n_loss_payment_amt_r,0) + 
        nvl(f_inc_summ.n_curr_field_os_direct_amt_r,0) + 
          nvl(f_inc_summ.n_curr_field_ibnr_direct_amt_r,0) + 
            nvl(f_inc_summ.n_curr_field_wv_direct_amt_r,0) AS n_total_claim_incurred_field_r,
           nvl(f_inc_summ.n_loss_payment_amt_r,0) + 
             nvl(f_inc_summ.n_curr_gaap_os_direct_amt_r,0) + 
               nvl(f_inc_summ.n_curr_gaap_ibnr_direct_amt_r,0) + 
                 nvl(f_inc_summ.n_curr_gaap_wv_direct_amt_r,0) AS n_total_claim_incurred_gaap_r,
           nvl(f_inc_summ.n_loss_payment_amt_r,0) + 
             nvl(f_inc_summ.n_curr_stat_os_direct_amt_r,0) + 
               nvl(f_inc_summ.n_curr_stat_ibnr_direct_amt_r,0) + 
                 nvl(f_inc_summ.n_curr_stat_wv_direct_amt_r,0) AS n_total_claim_incurred_stat_r,
      f_inc_summ.n_written_prem_amt_r           AS n_written_prem_amt_r,
      f_inc_summ.n_party_sk_r                   AS n_cust_party_sk_r,
      f_inc_summ.n_policy_sk_r                  AS n_policy_sk_r,
      gc_getcur_loadedby                        AS v_last_modified_by_r,
      systimestamp                                AS t_creation_date_r,
      gc_getcur_loadedby                        AS v_created_by_r,
      systimestamp                                AS t_last_modified_date_r,
      'Y'                                       AS v_rpt_active_status_r,
      gn_sysdt_batchid                          AS n_batch_id_r,
      gn_current_month                          AS n_reportmonth_r,
      f_inc_summ.n_chg_gaap_os_direct_amt_r     AS n_chg_gaap_os_direct_amt_r,
      f_inc_summ.n_chg_gaap_os_ceded_amt_r      AS n_chg_gaap_os_ceded_amt_r,
      f_inc_summ.n_chg_stat_os_ceded_amt_r      AS n_chg_stat_os_ceded_amt_r,
      f_inc_summ.v_product_line_r               AS v_product_line_r,
      f_inc_summ.n_reinsurance_pct_r            AS n_reinsurance_pct_r,
      f_inc_summ.n_chg_stat_ibnr_ceded_amt_r    AS n_chg_stat_ibnr_ceded_amt_r,
      f_inc_summ.n_chg_gaap_ibnr_ceded_amt_r    AS n_chg_gaap_ibnr_ceded_amt_r,
      f_inc_summ.n_chg_gaap_wv_net_amt_r        AS n_chg_gaap_wv_net_amt_r,
      f_inc_summ.n_chg_prem_unearned_net_amt_r  AS n_chg_prem_unearned_net_amt_r,
      f_inc_summ.n_chg_stat_wv_net_amt_r        AS n_chg_stat_wv_net_amt_r,
      f_inc_summ.n_earned_prem_net_amt_r        AS n_earned_prem_net_amt_r,
      f_inc_summ.n_loss_payment_ceded_amt_r     AS n_loss_payment_ceded_amt_r,
      f_inc_summ.n_written_prem_ceded_amt_r     AS n_written_prem_ceded_amt_r,
      f_inc_summ.n_written_prem_net_amt_r       AS n_written_prem_net_amt_r
    FROM atomic.fct_incurred_summary_r f_inc_summ
    --WHERE TO_NUMBER(TO_CHAR(D_CYCLE_DATE_R,'YYYYMM'))=gn_current_month;
        --so that the index can be used
        --20260722 perfomance optimization
    WHERE f_inc_summ.d_cycle_date_r >= trunc(to_date(gn_current_month,'YYYYMM'),'MM')
    AND f_inc_summ.d_cycle_date_r < trunc(add_months(to_date(gn_current_month,'YYYYMM'),1),'MM');


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

END PKG_GRP_LOAD_RPT_FCT_INCURRED_SUMMARY_R;

/

  GRANT EXECUTE ON "ATOMIC"."PKG_GRP_LOAD_RPT_FCT_INCURRED_SUMMARY_R" TO "ATOMIC_ALL_RO";
  GRANT EXECUTE ON "ATOMIC"."PKG_GRP_LOAD_RPT_FCT_INCURRED_SUMMARY_R" TO "EXT_EIS_RO";
  GRANT DEBUG ON "ATOMIC"."PKG_GRP_LOAD_RPT_FCT_INCURRED_SUMMARY_R" TO "ATOMIC_DEBUG";
