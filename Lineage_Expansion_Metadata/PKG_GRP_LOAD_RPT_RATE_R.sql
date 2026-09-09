--------------------------------------------------------
--  DDL for Package Body PKG_GRP_LOAD_RPT_RATE_R
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ATOMIC"."PKG_GRP_LOAD_RPT_RATE_R" 
IS
  /***********************************************************************
  Purpose:  This package body contains procedures which loads data into RPT_RATE_R
  Author     Date     Description
  ---------- -------- -------------------------------------------------
  VGireesh   28/02/24 Initial Creation
  VGireesh   03/04/24 Added Parallel to rebuild index fast  parallel 16 nologging
  VGireesh   31/07/24 Added filter where v_source_system_name_r='VUE') for DIM_GRP_BILLING_POL_BILLGRP_R
  VGireesh   03/10/24 Applied replace to remove multiple spaces on the column V_RPT_CURRENT_RATE_R
  Rose		 12/03/26 Commenting prc_upd_del_data and adding PKG_GRP_COMMON_UTIL.
  awatkins   Jul-8-26 (workitem 524652)
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
  gc_main_loadedby        VARCHAR2(200 CHAR):= 'PKG_GRP_LOAD_RPT_RATE_R.MAIN';
  gc_getcur_loadedby      VARCHAR2(200 CHAR):= 'PKG_GRP_LOAD_RPT_RATE_R.PRC_GET_CUR_DATA';
  gc_job_name             VARCHAR2(50 CHAR):= 'GRP_LOAD_RPT_RATE_R';
  gc_running_status       VARCHAR2(30):= 'Running';
  gc_error_status         VARCHAR2(30):= 'Error';
  gc_success_status       VARCHAR2(30):= 'Success';
  gc_source               VARCHAR2(30):= 'EDW';
  gc_target               VARCHAR2(30):= 'RPT';
  gc_main_entity          VARCHAR2(30):= 'RPT_RATE_R';

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

    --start 8-JUL-26: partition swap additions
  gv_rpt_table_name       CONSTANT prcs_job_log_r.v_job_name_r%TYPE := 'RPT_RATE_R';
  gv_exg_table_name       CONSTANT prcs_job_log_r.v_job_name_r%TYPE := gv_rpt_table_name|| '_EXG';
  gv_schema_owner         CONSTANT prcs_job_log_r.v_job_name_r%TYPE := 'ATOMIC'; 
    --end 8-JUL-26: partition swap additions

/***********************************************************************
  Purpose:  Main procedure ultimately loads RPT_POSTED_SUSPENSE_R thru partition exchange

  Author     Date     Description
  ---------- -------- -------------------------------------------------
  VGireesh   28/02/24 Initial Creation
  awatkins   Jul-8-26 (workitem 524652)
                       Modifying to load data via partition exchange versus kill and fill.
                       Cleaned up the code in general to comply with standards.
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

    pkg_grp_load_rpt_rate_r.prc_get_cur_data;   

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
    FROM atomic.rpt_rate_r
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
  Purpose:   prc_get_cur_data procedures inserts data to reporting exchange table
  Author     Date     	Description
  ---------- -------- 	-------------------------------------------------
  VGireesh   10/11/23 Initial Creation
  awatkins   Jul-8-26 (workitem 524652)
                       Modifying to load data via partition exchange versus kill and fill.
                       Changed joins to ansi standard and cleaned up the code in general to comply with standards.

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

    --start 15-JUN-26: partition swap additions
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

    --20260708 part of partition swap change
    --removed the old open select into ref cursor and replaced with
    --insert into exchange table;
    --also renamed the aliases to add meaning 

    INSERT /*+ APPEND PARALLEL(stg, 4) */ INTO atomic.rpt_rate_r_exg stg
    SELECT /*+ PARALLEL */
      billgrp.n_policy_billgroup_sk_r n_billgroup_sk_r,
      plcy_dir.v_policy_prefix_r,
      plcy_dir.v_policy_suffix_r,
      plcy_dir.n_policy_sk_r,
      product.v_basic_product_line_desc_r,
      product.n_product_sk_r,
      product.v_product_sub_line_code_r,
       replace(
         replace(
           replace(
     --03/10/24 changes
             MIN(
     --20250609 - 409946 - JC:  Removed so all records will be displayed
               CASE
                 WHEN product.v_product_sub_line_code_r = 'SR'
                 THEN 'N/A'
                 WHEN 
                   CASE
                     WHEN rate_sts.n_is_composite_r = 1 
                     THEN prem_rate.n_ec_rate_r
                     ELSE NULL
                   END IS NULL 
                 THEN 'Step Rates'
                 WHEN product.v_product_line_r = 'LTD'
                 THEN concat(concat('$ ',CAST(
                   CASE
                     WHEN rate_sts.n_is_composite_r = 1 
                     THEN prem_rate.n_ec_rate_r
                     ELSE NULL
                   END AS CHARACTER(30))),' (per $100 of Covered Payroll)')
                 WHEN product.v_product_sub_line_code_r = 'STD'
                 THEN concat(concat('$ ',CAST(
                   CASE
                     WHEN rate_sts.n_is_composite_r = 1 
                     THEN prem_rate.n_ec_rate_r
                     ELSE NULL
                   END AS CHARACTER(30))),' (per $10 of Benefit)')
                 WHEN product.v_basic_product_line_code_r = 'Dependent Life' 
                 THEN concat(concat('$ ',CAST(
                   CASE
                     WHEN rate_sts.n_is_composite_r = 1 
                     THEN prem_rate.n_ec_rate_r
                     ELSE NULL
                   END AS CHARACTER(30))),' (per Unit)')
                 ELSE concat(concat('$ ',CAST(
                   CASE
                     WHEN rate_sts.n_is_composite_r = 1 
                     THEN prem_rate.n_ec_rate_r
                     ELSE NULL
                   END AS CHARACTER(30))),' (per $1000 of Volume)')
                 END)
     --20250609 - 409946 - JC:  Removed so all records will be displayed
                 ,'  ','')
    --03/10/24 changes
                 ,' (','('),'(',' (') AS v_rpt_current_rate_r,
    --03/10/24 changes
      plcy.n_cust_party_sk_r,
      gc_getcur_loadedby              AS v_last_modified_by_r,
      gd_sysdate                      AS t_creation_date_r,
      gc_getcur_loadedby              AS v_created_by_r,
      gd_sysdate                      AS t_last_modified_date_r,
      'Y'                             AS v_rpt_active_status_r,
      gn_sysdt_batchid                AS n_batch_id_r,
      gn_current_month                AS n_reportmonth_r
    FROM atomic.dim_grp_billing_policy_covrg_r bill_plcy_cvrg
    INNER JOIN atomic.dim_coverage_r coverage
    ON bill_plcy_cvrg.n_coverage_id_r = coverage.n_coverage_id_r
    AND coverage.v_active_status_r = 'Y'
    INNER JOIN atomic.dim_grp_product_r product
    ON coverage.v_code_r = product.v_coverage_code_r
    AND product.v_active_status_r = 'Y'
    INNER JOIN atomic.fct_billing_policy_premium_r plcy_prem
    ON bill_plcy_cvrg.n_policy_coverage_id_r = plcy_prem.n_src_coverage_id_r
    INNER JOIN atomic.dim_grp_billing_pol_billgrp_r billgrp
    --31/07/24 changes
    ON billgrp.n_policy_billgroup_id_r = plcy_prem.n_src_policy_billgroup_id_r
    AND billgrp.n_policy_sk_r = plcy_prem.n_policy_sk_r
    AND billgrp.v_source_system_name_r = 'VUE'
    AND billgrp.v_active_status_r = 'Y'
    INNER JOIN atomic.dim_grp_policy_dir_r plcy_dir
    ON plcy_dir.n_policy_sk_r = billgrp.n_policy_sk_r
    AND plcy_dir.v_active_status_r = 'Y'
    LEFT OUTER JOIN atomic.fct_grp_policy_r plcy
    ON plcy_dir.n_policy_sk_r = plcy.n_policy_sk_r
    AND plcy_dir.n_policy_version_number_r = plcy.n_version_number_r
    INNER JOIN atomic.dim_grp_customer_bill_group_r cust_bill_grp
    ON cust_bill_grp.n_customer_billgroup_id_r = billgrp.n_customer_billgroup_id_r
    AND cust_bill_grp.v_active_status_r = 'Y'
    INNER JOIN atomic.dim_bill_plan bill_plan
    ON plcy_prem.n_src_class_id_r = bill_plan.v_bill_plan_code
    AND bill_plan.v_active_status_r = 'Y'
    INNER JOIN atomic.dim_grp_bill_prem_ratestatus_r rate_sts
    ON bill_plan.n_policy_plan_sk_r = rate_sts.n_policy_plan_sk_r
    AND(rate_sts.n_status_id_r = 192
     OR rate_sts.d_status_date_r > current_date)--Ian added
    AND rate_sts.d_effective_date_r <= current_date--Ian added
    AND rate_sts.v_active_status_r = 'Y'
    INNER JOIN atomic.dim_grp_billng_premium_rate_r  prem_rate
    ON prem_rate.n_rate_status_id_r = rate_sts.n_rate_status_id_r
    AND prem_rate.v_active_status_r = 'Y'
    WHERE bill_plcy_cvrg.v_active_status_r = 'Y'
    GROUP BY plcy_dir.v_policy_prefix_r,
      product.v_basic_product_line_desc_r,
      product.v_product_sub_line_code_r,
      plcy_dir.v_policy_suffix_r,
      product.n_product_sk_r,
      plcy_dir.n_policy_sk_r,
      billgrp.n_policy_billgroup_sk_r,
      plcy.n_cust_party_sk_r;

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

      gv_trcmsg := '5.z Error in prc_get_cur_data'|| gv_errmsg;

      pkg_grp_log_util.prc_update_log_message_r(
        n_prcs_job_log_message_id_r => gn_job_log_message_id_r,
        p_err_msg                   => gv_trcmsg
      );

      pkg_grp_log_util.prc_update_log(
        p_job_id                 => gn_out_job_id,
        p_job_status             => gc_error_status,
        p_err_msg                => gv_errmsg,
        p_trc_msg                => gv_trcmsg,
        p_log_util_called_by_r   => gc_getcur_loadedby
      );

      RAISE;
  END prc_get_cur_data;

END PKG_GRP_LOAD_RPT_RATE_R;

/

  GRANT EXECUTE ON "ATOMIC"."PKG_GRP_LOAD_RPT_RATE_R" TO "ATOMIC_ALL_RO";
  GRANT EXECUTE ON "ATOMIC"."PKG_GRP_LOAD_RPT_RATE_R" TO "EXT_EIS_RO";
  GRANT DEBUG ON "ATOMIC"."PKG_GRP_LOAD_RPT_RATE_R" TO "ATOMIC_DEBUG";
