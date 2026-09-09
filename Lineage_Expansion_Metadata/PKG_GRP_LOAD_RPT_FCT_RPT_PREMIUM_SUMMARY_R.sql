--------------------------------------------------------
--  DDL for Package Body PKG_GRP_LOAD_RPT_FCT_RPT_PREMIUM_SUMMARY_R
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ATOMIC"."PKG_GRP_LOAD_RPT_FCT_RPT_PREMIUM_SUMMARY_R" IS
/***********************************************************************
  Purpose:  This package body contains procedures which loads data into RPT_FCT_RPT_PREMIUM_SUMMARY_R
  Author     Date     Description
  ---------- -------- -------------------------------------------------
  Satya     15/03/24 Initial Creation
  VGireesh   03/04/24 Added Parallel to rebuild index fast  parallel 16 nologging
--31-Jul-2024 Added filter where v_source_system_name_r='VUE') for DIM_GRP_BILLING_POL_BILLGRP_R
--13-Aug-2024 Added below columns
              N_CHG_DUE_PREM_AMT_CEDED_R
              N_CHG_DUE_PREM_UNEARNED_AMT_CEDED_R
              N_CHG_PREM_UNEARNED_AMT_CEDED_R
              N_COLLECTED_PREMIUM_AMT_CEDED_R
              N_DUE_PREM_AMT_CEDED_R
              N_DUE_PREM_UNEARNED_Amt_CEDED_R
              N_EARNED_PREM_AMT_CEDED_R
              N_CONSTANT_EARNED_PREM_AMT_CEDED_R
              N_PRIOR_DUE_PREM_AMT_CEDED_R
              N_PRIOR_DUEPREM_UNEARNED_AMT_CEDED_R
              N_PREM_UNEARNED_AMT_CEDED_R
              N_WRITTEN_PREM_AMT_CEDED_R
              V_PRIMARY_REINSURER_R
              V_SECONDARY_REINSURER_R
              V_TERNARY_REINSURER_R
              N_PRIMARY_REINSURER_REINS_SHARE_PCT_R
              N_PRIMARY_REINSURER_REINSURANCE_PCT_R
              N_SECONDARY_REINSURER_REINS_SHARE_PCT_R
              N_SECONDARY_REINSURER_REINSURANCE_PCT_R
              N_TERNARY_REINSURER_REINS_SHARE_PCT_R
              N_TERNARY_REINSURER_REINSURANCE_PCT_R
              N_TOTAL_REINSURANCE_PCT_R
              N_CHG_DUE_PREM_AMT_NET_R
              N_CHG_DUE_PREM_UNEARNED_AMT_NET_R
              N_CHG_PREM_UNEARNED_AMT_NET_R
              N_COLLECTED_PREMIUM_AMT_NET_R
              N_DUE_PREM_AMT_NET_R
              N_DUE_PREM_UNEARNED_Amt_NET_R
              N_EARNED_PREM_AMT_NET_R
              N_CONSTANT_EARNED_PREM_AMT_NET_R
              N_PRIOR_DUE_PREM_AMT_NET_R
              N_PRIOR_DUEPREM_UNEARNED_AMT_NET_R
              N_PREM_UNEARNED_AMT_NET_R
              N_WRITTEN_PREM_AMT_NET_R
  VGireesh 23-Aug-2024 added  to_number(to_char(D_CYCLE_DATE_R,'YYYYMM')) =gn_current_month) fct_rpt_premium_summary_r
  VGireesh 11-Nov-2024 As per the Gisha's request below are the changes
			           (SELECT * FROM  --11-Nov-2024 changes
			           dim_grp_billing_pol_billgrp_r
			           WHERE dim_grp_billing_pol_billgrp_r.v_source_system_name_r='VUE' --11-Nov-2024 changes
			           ) dim_grp_billing_pol_billgrp_r --11-Nov-2024 changes
  VGireesh 13-Nov-2024 Introduced new column  ,cast(null as number) N_COLLECTED_LIVES_R  and update procedure prc_upd_cols
  VGireesh 20-Nov-2024 Cusrosr logic chage for N_COLLECTED_LIVES_R in procedure prc_upd_cols
  Shreeja 10-Mar-2024 V_SOURCE_SYSTEM_NAME_R column added with MGIS data
  Kavinissha 19-Mar-2026 Project Crown Changes and coding standardisation User Story : 461423
  Kavinissha 19-Jun-2026 Project Crown Changes to add column n_prior_prem_unearned_amt_r User Story : 461423
  awatkins   Jul-27-26 (workitem 524657)
                       Modifying to load data via partition exchange versus kill and fill.
                       Cleaned up the code in general to comply with standards.
                       Removed unused procs and replaced with standard utilities. 
  awatkins   Aug-11-26 (workitem 524657)
                      Post deployment, learned that PROCEDURE prc_upd_cols was called 
                      separately from a TIDAL job.  So restoring its functionality.
 **********************************************************************/

 --Global Constants
  gd_sysdate              DATE := trunc(sysdate);
  gn_prior_month          NUMBER := to_number(to_char(add_months(trunc(gd_sysdate,'MM'),-1),'YYYYMM'));
  gn_current_month        NUMBER := to_number(to_char(gd_sysdate,'YYYYMM'));
  gn_sysdt_batchid        NUMBER := to_number(to_char(gd_sysdate,'YYYYMMDD'));
  gc_main_loadedby        VARCHAR2(200 CHAR):= 'PKG_GRP_LOAD_RPT_FCT_RPT_PREMIUM_SUMMARY_R.MAIN';
  gc_getcur_loadedby      VARCHAR2(200 CHAR):= 'PKG_GRP_LOAD_RPT_FCT_RPT_PREMIUM_SUMMARY_R.PRC_GET_CUR_DATA';
  gc_job_name             VARCHAR2(50 CHAR):= 'GRP_LOAD_RPT_FCT_RPT_PREMIUM_SUMMARY_R';
    gc_upd_cols              VARCHAR2(100 CHAR):='PKG_GRP_LOAD_RPT_FCT_RPT_PREMIUM_SUMMARY_R.PRC_UPD_COLS';--13-Nov-2024 changes  
  gc_running_status       VARCHAR2(30):= 'Running';
  gc_error_status         VARCHAR2(30):= 'Error';
  gc_success_status       VARCHAR2(30):= 'Success';
  gc_source               VARCHAR2(30):= 'EDW';
  gc_target               VARCHAR2(30):= 'RPT';
  gc_main_entity          VARCHAR2(30):= 'PREMIUM_SUMMARY';

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

    --start 27-JUL-26: partition swap additions
  gv_rpt_table_name       CONSTANT prcs_job_log_r.v_job_name_r%TYPE := 'RPT_FCT_RPT_PREMIUM_SUMMARY_R';
  gv_exg_table_name       CONSTANT prcs_job_log_r.v_job_name_r%TYPE := gv_rpt_table_name|| '_EXG';
  gv_schema_owner         CONSTANT prcs_job_log_r.v_job_name_r%TYPE := 'ATOMIC'; 
    --end 27-JUL-26: partition swap additions


/***********************************************************************
  Purpose:  Main procedure ultimately loads RPT_FCT_RPT_PREMIUM_SUMMARY_R thru partition exchange

  Author     Date     Description
  ---------- -------- -------------------------------------------------
  Satya     15/03/24 Initial Creation
  awatkins   Jul-27-26 (workitem 524657)
                       Modifying to load data via partition exchange versus kill and fill.
                       Cleaned up the code in general to comply with standards.
                       Removed unused procs and replaced with standard utilities. 

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

    --start 27-JUL-26: partition swap additions
    lv_partition_name := 'PART_'|| gv_rpt_table_name|| '_'|| gn_current_month;

    pkg_grp_common_util.prc_create_exchange_table_ddl(
      p_job_id          => gn_out_job_id,
      p_log_seq_num     => 4,
      p_main_table_name => gv_rpt_table_name,
      p_exg_table_name  => gv_exg_table_name,
      p_schema_name     => gv_schema_owner
    );

    pkg_grp_load_rpt_fct_rpt_premium_summary_r.prc_get_cur_data;   

   --start 27-JUL-26: adding code for partition swapping and removing old
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
    FROM atomic.rpt_fct_rpt_premium_summary_r
    WHERE n_yearmonth_r = gn_current_month;

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
  Satya     15/03/24 Initial Creation
  awatkins   Jul-27-26 (workitem 524657)
                       Modifying to load data via partition exchange versus kill and fill.
                       Cleaned up the code in general to comply with standards.

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

    --20260727 part of partition swap change
    --removed the old open select into ref cursor and replaced with
    --insert into exchange table;
    --also renamed the aliases to add meaning 

    INSERT /*+ APPEND */ INTO rpt_fct_rpt_premium_summary_r_exg (
      d_due_date_r, 
      d_cycle_date_r, 
      n_policy_sk_r, 
      n_billgroup_sk_r, 
      n_product_sk_r, 
      n_chg_due_prem_amt_r, 
      n_chg_due_prem_unearned_amt_r, 
      n_chg_prem_unearned_amt_r, 
      n_collected_premium_amt_r, 
      n_due_prem_amt_r, 
      n_due_prem_unearned_amt, 
      n_earned_prem_amt_r, 
      n_constant_earned_prem_amt_r, 
      n_prior_due_prem_amt_r, 
      n_prior_dueprem_unearned_amt_r, 
      n_prem_unearned_amt, 
      n_written_prem_amt_r, 
      v_coverage_code_r, 
      v_policy_number_r, 
      v_customer_bill_group_number_r, 
      v_last_modified_by_r, 
      t_creation_date_r, 
      v_created_by_r, 
      t_last_modified_date_r, 
      n_yearmonth_r, 
      v_rpt_active_status_r, 
      n_batch_id_r, 
      n_cust_party_sk_r, 
      n_chg_due_prem_amt_ceded_r, 
      n_chg_due_prem_unearned_amt_ceded_r, 
      n_chg_prem_unearned_amt_ceded_r, 
      n_collected_premium_amt_ceded_r, 
      n_due_prem_amt_ceded_r, 
      n_due_prem_unearned_amt_ceded_r, 
      n_earned_prem_amt_ceded_r, 
      n_constant_earned_prem_amt_ceded_r, 
      n_prior_due_prem_amt_ceded_r, 
      n_prior_dueprem_unearned_amt_ceded_r, 
      n_prem_unearned_amt_ceded_r, 
      n_written_prem_amt_ceded_r, 
      v_primary_reinsurer_r, 
      v_secondary_reinsurer_r, 
      v_ternary_reinsurer_r, 
      n_primary_reinsurer_reins_share_pct_r, 
      n_primary_reinsurer_reinsurance_pct_r, 
      n_secondary_reinsurer_reins_share_pct_r, 
      n_secondary_reinsurer_reinsurance_pct_r, 
      n_ternary_reinsurer_reins_share_pct_r, 
      n_ternary_reinsurer_reinsurance_pct_r, 
      n_total_reins_prem_pct_r, 
      n_chg_due_prem_amt_net_r, 
      n_chg_due_prem_unearned_amt_net_r, 
      n_chg_prem_unearned_amt_net_r, 
      n_collected_premium_amt_net_r, 
      n_due_prem_amt_net_r, 
      n_due_prem_unearned_amt_net_r, 
      n_earned_prem_amt_net_r, 
      n_constant_earned_prem_amt_net_r, 
      n_prior_due_prem_amt_net_r, 
      n_prior_dueprem_unearned_amt_net_r, 
      n_prem_unearned_amt_net_r, 
      n_written_prem_amt_net_r, 
      n_collected_lives_r, 
      v_source_system_name_r, 
      n_prior_prem_unearned_amt_r)
    SELECT /*+ PARALLEL(4) */ 
      rpt_prem_summ.d_due_date_r                             d_due_date_r,
      rpt_prem_summ.d_cycle_date_r                           d_cycle_date_r,
      plcy_info.n_policy_sk_r                                n_policy_sk_r,
      nvl(n_policy_billgroup_sk_r,- 1)                       n_billgroup_sk_r,
      prod.n_product_sk_r                                    n_product_sk_r,
      rpt_prem_summ.n_chg_due_prem_amt_r                     n_chg_due_prem_amt_r,
      rpt_prem_summ.n_chg_due_prem_unearned_amt_r            n_chg_due_prem_unearned_amt_r,
      rpt_prem_summ.n_chg_prem_unearned_amt_r                n_chg_prem_unearned_amt_r,
      rpt_prem_summ.n_collected_premium_amt_r                n_collected_premium_amt_r,
      rpt_prem_summ.n_due_prem_amt_r                         n_due_prem_amt_r,
      rpt_prem_summ.n_due_prem_unearned_amt                  n_due_prem_unearned_amt,
      rpt_prem_summ.n_earned_prem_amt_r                      n_earned_prem_amt_r,
      rpt_prem_summ.n_constant_earned_prem_amt_r             n_constant_earned_prem_amt_r,
      rpt_prem_summ.n_prior_due_prem_amt_r                   n_prior_due_prem_amt_r,
      rpt_prem_summ.n_prior_dueprem_unearned_amt_r           n_prior_dueprem_unearned_amt_r,
      rpt_prem_summ.n_prem_unearned_amt                      n_prem_unearned_amt,
      rpt_prem_summ.n_written_prem_amt_r                     n_written_prem_amt_r,
      rpt_prem_summ.v_coverage_code_r                        v_coverage_code_r,
      rpt_prem_summ.v_policy_number_r                        v_policy_number_r,
      rpt_prem_summ.v_customer_bill_group_number_r           v_customer_bill_group_number_r,
      gc_main_loadedby                                       v_last_modified_by_r,
      systimestamp                                           t_creation_date_r,
      gc_main_loadedby                                       v_created_by_r,
      systimestamp                                           t_last_modified_date_r,
      gn_current_month                                       n_yearmonth_r,
      'Y'                                                    v_rpt_active_status_r,
      gn_sysdt_batchid                                       n_batch_id_r,
      plcy_info.n_cust_party_sk_r                            n_cust_party_sk_r,
      --13-Aug-2024 changes starts
      (rpt_prem_summ.n_chg_due_prem_amt_r * rpt_prem_summ.n_total_reins_prem_pct_r)          n_chg_due_prem_amt_ceded_r,
      (rpt_prem_summ.n_chg_due_prem_unearned_amt_r * rpt_prem_summ.n_total_reins_prem_pct_r) n_chg_due_prem_unearned_amt_ceded_r,
      (rpt_prem_summ.n_chg_prem_unearned_amt_r * rpt_prem_summ.n_total_reins_prem_pct_r)     n_chg_prem_unearned_amt_ceded_r,
      (rpt_prem_summ.n_collected_premium_amt_r * rpt_prem_summ.n_total_reins_prem_pct_r)     n_collected_premium_amt_ceded_r,
      (rpt_prem_summ.n_due_prem_amt_r * rpt_prem_summ.n_total_reins_prem_pct_r)              n_due_prem_amt_ceded_r,
      (rpt_prem_summ.n_due_prem_unearned_amt * rpt_prem_summ.n_total_reins_prem_pct_r)       n_due_prem_unearned_amt_ceded_r,
      (rpt_prem_summ.n_earned_prem_amt_r * rpt_prem_summ.n_total_reins_prem_pct_r)           n_earned_prem_amt_ceded_r,
      (rpt_prem_summ.n_constant_earned_prem_amt_r * rpt_prem_summ.n_total_reins_prem_pct_r)  n_constant_earned_prem_amt_ceded_r,
      (rpt_prem_summ.n_prior_due_prem_amt_r * rpt_prem_summ.n_total_reins_prem_pct_r)        n_prior_due_prem_amt_ceded_r,
      (rpt_prem_summ.n_prior_dueprem_unearned_amt_r * rpt_prem_summ.n_total_reins_prem_pct_r) n_prior_dueprem_unearned_amt_ceded_r,
      (rpt_prem_summ.n_prem_unearned_amt * rpt_prem_summ.n_total_reins_prem_pct_r)           n_prem_unearned_amt_ceded_r,
      (rpt_prem_summ.n_written_prem_amt_r * rpt_prem_summ.n_total_reins_prem_pct_r)          n_written_prem_amt_ceded_r,
      rpt_prem_summ.v_primary_reinsurer_r                  v_primary_reinsurer_r,
      rpt_prem_summ.v_secondary_reinsurer_r                v_secondary_reinsurer_r,
      rpt_prem_summ.v_ternary_reinsurer_r                  v_ternary_reinsurer_r,
      CAST(NULL AS NUMBER)                                 n_primary_reinsurer_reins_share_pct_r,
      rpt_prem_summ.n_primary_reins_prem_pct_r             n_primary_reinsurer_reinsurance_pct_r,
      CAST(NULL AS NUMBER)                                 n_secondary_reinsurer_reins_share_pct_r,
      rpt_prem_summ.n_sec_reins_prem_pct_r                 n_secondary_reinsurer_reinsurance_pct_r,
      CAST(NULL AS NUMBER)                                 n_ternary_reinsurer_reins_share_pct_r,
      rpt_prem_summ.n_ternary_reins_prem_pct_r             n_ternary_reinsurer_reinsurance_pct_r,
      rpt_prem_summ.n_total_reins_prem_pct_r               n_total_reins_prem_pct_r,
      (rpt_prem_summ.n_chg_due_prem_amt_r -
        (rpt_prem_summ.n_chg_due_prem_amt_r * rpt_prem_summ.n_total_reins_prem_pct_r))          n_chg_due_prem_amt_net_r,
      (rpt_prem_summ.n_chg_due_prem_unearned_amt_r -
        (rpt_prem_summ.n_chg_due_prem_unearned_amt_r * rpt_prem_summ.n_total_reins_prem_pct_r)) n_chg_due_prem_unearned_amt_net_r,
      (rpt_prem_summ.n_chg_prem_unearned_amt_r -
        (rpt_prem_summ.n_chg_prem_unearned_amt_r * rpt_prem_summ.n_total_reins_prem_pct_r))     n_chg_prem_unearned_amt_net_r,
      (rpt_prem_summ.n_collected_premium_amt_r -
        (rpt_prem_summ.n_collected_premium_amt_r * rpt_prem_summ.n_total_reins_prem_pct_r))     n_collected_premium_amt_net_r,
      (rpt_prem_summ.n_due_prem_amt_r -
        (rpt_prem_summ.n_due_prem_amt_r * rpt_prem_summ.n_total_reins_prem_pct_r))              n_due_prem_amt_net_r,
      (rpt_prem_summ.n_due_prem_unearned_amt -
        (rpt_prem_summ.n_due_prem_unearned_amt * rpt_prem_summ.n_total_reins_prem_pct_r))       n_due_prem_unearned_amt_net_r,
      (rpt_prem_summ.n_earned_prem_amt_r -
        (rpt_prem_summ.n_earned_prem_amt_r * rpt_prem_summ.n_total_reins_prem_pct_r))           n_earned_prem_amt_net_r,
      (rpt_prem_summ.n_constant_earned_prem_amt_r -
        (rpt_prem_summ.n_constant_earned_prem_amt_r * rpt_prem_summ.n_total_reins_prem_pct_r))  n_constant_earned_prem_amt_net_r,
      (rpt_prem_summ.n_prior_due_prem_amt_r -
        (rpt_prem_summ.n_prior_due_prem_amt_r * rpt_prem_summ.n_total_reins_prem_pct_r))        n_prior_due_prem_amt_net_r,
      (rpt_prem_summ.n_prior_dueprem_unearned_amt_r -
        (rpt_prem_summ.n_prior_dueprem_unearned_amt_r *rpt_prem_summ.n_total_reins_prem_pct_r)) n_prior_dueprem_unearned_amt_net_r,
      (rpt_prem_summ.n_prem_unearned_amt -
        (rpt_prem_summ.n_prem_unearned_amt * rpt_prem_summ.n_total_reins_prem_pct_r))           n_prem_unearned_amt_net_r,
      (rpt_prem_summ.n_written_prem_amt_r -
        (rpt_prem_summ.n_written_prem_amt_r * rpt_prem_summ.n_total_reins_prem_pct_r))          n_written_prem_amt_net_r,
                                     --13-Aug-2024 changes ends
      CAST(NULL AS NUMBER)                            n_collected_lives_r,
        --13-Nov-2024 changes
      rpt_prem_summ.v_source_system_name_r            v_source_system_name_r,
         --10 mar 25 added
      rpt_prem_summ.n_prior_prem_unearned_amt_r       n_prior_prem_unearned_amt_r
         --19-JUN-2026 Project Crown changes
    FROM (
      SELECT *
      FROM atomic.fct_rpt_premium_summary_r
          --20260727 performance improvement versus to-charring cycle date to use index if one exists
      WHERE d_cycle_date_r >= trunc(to_date(gn_current_month,'YYYYMM'),'MM')
      AND d_cycle_date_r < trunc(add_months(to_date(gn_current_month,'YYYYMM'),1),'MM')
      ) rpt_prem_summ
         --23-Aug-2024 changes
    INNER JOIN atomic.dim_source_system_r ss
    ON rpt_prem_summ.v_source_system_name_r = ss.v_source_system_code_r
    INNER JOIN (
      SELECT plcy_dir.n_policy_sk_r,
             plcy.n_cust_party_sk_r,
             plcy_dir.v_policy_number_r
      FROM atomic.dim_grp_policy_dir_r plcy_dir,
           atomic.fct_grp_policy_r     plcy
      WHERE plcy_dir.v_active_status_r = 'Y'
      AND plcy_dir.n_policy_sk_r             = plcy.n_policy_sk_r
      AND plcy_dir.n_policy_version_number_r = plcy.n_version_number_r
      AND plcy_dir.n_source_system_key_r     = plcy.n_source_system_key_r
      GROUP BY plcy_dir.n_policy_sk_r,
               plcy.n_cust_party_sk_r,
               plcy_dir.v_policy_number_r
      ) plcy_info
    ON rpt_prem_summ.v_policy_number_r = plcy_info.v_policy_number_r
    LEFT OUTER JOIN atomic.dim_grp_product_r prod
    ON rpt_prem_summ.v_coverage_code_r = prod.v_coverage_code_r
    LEFT OUTER JOIN (
      SELECT pol_billgrp.n_policy_sk_r,
             bill_group.v_customer_bill_group_number_r,
             MAX(pol_billgrp.n_policy_billgroup_sk_r)n_policy_billgroup_sk_r,
             pol_billgrp.v_source_system_name_r
      FROM (
        SELECT *
        FROM atomic.dim_grp_billing_pol_billgrp_r
--        WHERE v_source_system_name_r in ('VUE','MGIS')) 
        WHERE dim_grp_billing_pol_billgrp_r.v_source_system_name_r <> 'APS' --19-Mar-2026 Crown Changes
        ) pol_billgrp
          --11-Nov-2024 changes
      LEFT OUTER JOIN (
        SELECT *
        FROM atomic.dim_grp_customer_bill_group_r
        --WHERE v_source_system_name_r in ('VUE','MGIS')
        WHERE v_source_system_name_r NOT IN ( 'APS', 'EIS' )--19-Mar-2026 Crown Changes
        ) bill_group
      ON bill_group.v_active_status_r = 'Y'
      AND pol_billgrp.n_customer_billgroup_id_r = bill_group.n_customer_billgroup_id_r
      WHERE pol_billgrp.v_active_status_r = 'Y'
      GROUP BY pol_billgrp.n_policy_sk_r,
               bill_group.v_customer_bill_group_number_r,
               pol_billgrp.v_source_system_name_r
        ) bg
    ON bg.n_policy_sk_r = rpt_prem_summ.n_policy_sk_r
    AND bg.v_source_system_name_r = rpt_prem_summ.v_source_system_name_r
    AND (
      CASE
        WHEN ss.v_tpa_indicator_r = 0 
        THEN bg.v_customer_bill_group_number_r
        ELSE '1'
      END
      )=(
      CASE
        WHEN ss.v_tpa_indicator_r = 0 
        THEN rpt_prem_summ.v_customer_bill_group_number_r
        ELSE '1'
      END
      )
         --19-Mar-2026 Crown Changes  
    ;

    gn_run_cnt := SQL%rowcount;
    COMMIT;

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

/***********************************************************************
  Purpose:  updates columns on RPT_FCT_RPT_PREMIUM_SUMMARY_R; cannot
            included in insert because dependency based.

  Author     Date     Description
  ---------- -------- -------------------------------------------------
  VGireesh 13-Nov-2024 Introduced new column  ,cast(null as number) N_COLLECTED_LIVES_R  and update procedure prc_upd_cols
  VGireesh 20-Nov-2024 Cusrosr logic chage for N_COLLECTED_LIVES_R in procedure prc_upd_cols
  awatkins   Jul-27-26 (workitem 524657)
                       Proc was removed. (deployed to prod 8/10)
  awatkins   Aug-11-26 (workitem 524657)
                      Post deployment, learned that PROCEDURE prc_upd_cols was called 
                      separately from a TIDAL job.  So restoring its functionality.                       

  ***********************************************************************/  
  PROCEDURE prc_upd_cols
  IS
    ln_yearmonth_r NUMBER:= fnc_grp_get_ssl_yearmonth(sysdate);

  BEGIN

    pkg_grp_log_util.prc_insert_log(
      p_source               => gc_source,
      p_job_nm               => gc_job_name||'_PRC_UPD_COLS',
      p_job_status           => gc_running_status,
      p_err_msg              => NULL,
      p_trc_msg              => NULL,
      p_n_batch_id           => gn_sysdt_batchid,
      p_log_util_called_by_r => gc_upd_cols,
      out_job_id             => gn_out_job_id
    );

    gv_trcmsg := '1. Entered into PRC_UPD_COLS';
    gt_start_time_r := systimestamp;     

      --START: NEW LOGGING MECHANISM CHANGES
    pkg_grp_log_util.prc_ins_prcs_job_log_message_r(
      p_job_id_r                    => gn_out_job_id,
      p_batch_id_r                  => gn_sysdt_batchid,
      p_message_type_r              => gc_message_type_r,
      p_code_location_r             => gc_upd_cols,
      p_message_r                   => gv_trcmsg,
      p_count_type_r                => NULL,
      p_count_r                     => NULL,
      p_duration_r                  => NULL,
      p_created_by_r                => gc_job_name||'_PRC_UPD_COLS',
      out_prcs_job_log_message_id_r => gn_job_log_message_id_r
    );   

    MERGE INTO atomic.rpt_fct_rpt_premium_summary_r rpt_prem_summ
    USING (
      SELECT d_due_date_r,
             n_src_policy_billgroup_id_r,
             n_src_coverage_id_r,
             n_policy_sk_r,
             v_customer_bill_group_number_r,
             v_coveragecode_r,
             d_cycle_date_r,
             SUM(n_lives_r)     n_lives_r,
             SUM(n_lives_adj_r) n_lives_adj_r
      FROM(
        --20-Nov-2024 changes ends
      SELECT d_transaction_date_r,
                  d_due_date_r,
                  n_src_policy_billgroup_id_r,
                  n_src_coverage_id_r,
                  n_policy_sk_r,
                  v_customer_bill_group_number_r,
                  v_coveragecode_r,
                  d_cycle_date_r,
                  n_lives_r,
                  n_lives_adj_r
            --from FCT_BILLING_POLICY_PREMIUM_R_TABLE_POLLIVES_HIST_MV_SSL
           FROM atomic.fct_billing_policy_premium_r_table_pollives_mv_ssl
           WHERE to_number(to_char(d_cycle_date_r,'YYYYMM'))= ln_yearmonth_r)
        --20-Nov-2024 changes starts
      GROUP BY d_due_date_r,
               n_src_policy_billgroup_id_r,
               n_src_coverage_id_r,
               n_policy_sk_r,
               v_customer_bill_group_number_r,
               v_coveragecode_r,
               d_cycle_date_r
        --20-Nov-2024 changes ends
      ) upd_lives    
    ON (rpt_prem_summ.d_cycle_date_r = upd_lives.d_cycle_date_r
      AND rpt_prem_summ.n_policy_sk_r = upd_lives.n_policy_sk_r
      AND rpt_prem_summ.v_customer_bill_group_number_r = upd_lives.v_customer_bill_group_number_r
      AND rpt_prem_summ.v_coverage_code_r = upd_lives.v_coveragecode_r
      AND rpt_prem_summ.d_due_date_r = upd_lives.d_due_date_r
      AND rpt_prem_summ.n_yearmonth_r = ln_yearmonth_r)
    WHEN MATCHED THEN UPDATE
    SET rpt_prem_summ.n_collected_lives_r = upd_lives.n_lives_adj_r
    WHERE rpt_prem_summ.n_yearmonth_r = ln_yearmonth_r;

    gn_run_cnt := SQL%rowcount;
    COMMIT;

    gv_trcmsg := '2.z Collected Lives completed from PRC_UPD_COLS; exiting';
    gt_end_time_r := systimestamp;

		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
		 (
			p_job_id_r                    => gn_out_job_id,
			p_batch_id_r                  => gn_sysdt_batchid,
			p_message_type_r              => gc_message_type_r,
			p_code_location_r             => gc_upd_cols,
			p_message_r                   => gv_trcmsg,
			p_count_type_r                => gc_count_type_merge_r,
			p_count_r                     => gn_run_cnt,
			p_duration_r                  => fnc_grp_time_duration(gt_start_time_r,gt_end_time_r),
			p_created_by_r                => gc_job_name||'_PRC_UPD_COLS',
			out_prcs_job_log_message_id_r => gn_job_log_message_id_r
		);  

    pkg_grp_log_util.prc_update_log(
      p_job_id               => gn_out_job_id,
      p_job_status           => gc_success_status,
      p_err_msg              => gv_errmsg,
      p_trc_msg              => gv_trcmsg,
      p_log_util_called_by_r => gc_upd_cols
    );

  EXCEPTION
    WHEN OTHERS THEN
      gv_errmsg := substr(sqlerrm,1,4000);
      gv_trcmsg := '1.z Error in PRC_UPD_COLS ' || gv_errmsg;

		--START: 04-JUN-2025: NEW LOGGING MECHANISM CHANGES
      pkg_grp_log_util.prc_update_log_message_r(
        n_prcs_job_log_message_id_r => gn_job_log_message_id_r,
        p_err_msg                   => gv_trcmsg
      );

      pkg_grp_log_util.prc_update_log(
        p_job_id                => gn_out_job_id,
        p_job_status            => gc_error_status,
        p_err_msg               => gv_errmsg,
        p_trc_msg               => gv_trcmsg,
        p_log_util_called_by_r  => gc_upd_cols
      );

      RAISE;
  END PRC_UPD_COLS;


END pkg_grp_load_rpt_fct_rpt_premium_summary_r;

/

  GRANT EXECUTE ON "ATOMIC"."PKG_GRP_LOAD_RPT_FCT_RPT_PREMIUM_SUMMARY_R" TO "ATOMIC_ALL_RO";
  GRANT EXECUTE ON "ATOMIC"."PKG_GRP_LOAD_RPT_FCT_RPT_PREMIUM_SUMMARY_R" TO "EXT_EIS_RO";
  GRANT DEBUG ON "ATOMIC"."PKG_GRP_LOAD_RPT_FCT_RPT_PREMIUM_SUMMARY_R" TO "ATOMIC_DEBUG";
