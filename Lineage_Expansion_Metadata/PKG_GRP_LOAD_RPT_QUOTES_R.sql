--------------------------------------------------------
--  DDL for Package Body PKG_GRP_LOAD_RPT_QUOTES_R
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ATOMIC"."PKG_GRP_LOAD_RPT_QUOTES_R" 
IS
/***********************************************************************
  Purpose:  This package body contains procedures which loads data into RPT_QUOTES_R

  Author     Date     Description
  ---------- -------- -------------------------------------------------
  Satya     13/03/24 Initial Creation
  VGireesh  03/04/24 Added Parallel to rebuild index fast  parallel 16 nologging
  Chandra   26/07/24 Added column D_QUOTE_CREATION_DATE Requested by Karthick
  Chandra   05/0/24 Disabled the Where Condition DIM_GRP_QUOTE_DIR_R.v_source_system_name_r = 'PACS' bcoz D_QUOTE_CREATION_DATE was not flowing
  Samba		18/02/26  Capturing the Target count for Audit COntrols when data is inserting into RPT table using Bulkload limit.
  Rose		06/03/26   Commenting prc_upd_del_data and adding PKG_GRP_COMMON_UTIL.
  awatkins   Jul-23-26 (workitem 524685)
                       Modifying to load data via partition exchange versus kill and fill.
                       Cleaned up the code in general to comply with standards.
                       Removed unused procs and replaced with standard utilities.  
  awatkins   AUG-12-26 (workitem HOTFIX - dummy record restoration)
                       after implementation it was discovered that the dummy record was necessary                       
 **********************************************************************/

 --Global Constants
  gd_sysdate              DATE := trunc(sysdate);
  gn_prior_month          NUMBER := to_number(to_char(add_months(trunc(gd_sysdate,'MM'),-1),'YYYYMM'));
  gn_current_month        NUMBER := to_number(to_char(gd_sysdate,'YYYYMM'));
  gn_sysdt_batchid        NUMBER := to_number(to_char(gd_sysdate,'YYYYMMDD'));
  gc_main_loadedby        VARCHAR2(200 CHAR):= 'PKG_GRP_LOAD_RPT_QUOTES_R.MAIN';
  gc_getcur_loadedby      VARCHAR2(200 CHAR):= 'PKG_GRP_LOAD_RPT_QUOTES_R.PRC_GET_CUR_DATA';
  gc_job_name             VARCHAR2(50 CHAR):= 'GRP_LOAD_RPT_QUOTES_R';
  gc_running_status       VARCHAR2(30):= 'Running';
  gc_error_status         VARCHAR2(30):= 'Error';
  gc_success_status       VARCHAR2(30):= 'Success';
  gc_source               VARCHAR2(30):= 'EDW';
  gc_target               VARCHAR2(30):= 'RPT';
  gc_main_entity          VARCHAR2(30):= 'RPT_QUOTES';

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
  gv_rpt_table_name       CONSTANT prcs_job_log_r.v_job_name_r%TYPE := 'RPT_QUOTES_R';
  gv_exg_table_name       CONSTANT prcs_job_log_r.v_job_name_r%TYPE := gv_rpt_table_name|| '_EXG';
  gv_schema_owner         CONSTANT prcs_job_log_r.v_job_name_r%TYPE := 'ATOMIC'; 
    --end 30-JUN-26: partition swap additions

/***********************************************************************
  Purpose:  dummy record creation

  Author     Date     Description
  ---------- -------- -------------------------------------------------
  awatkins   AUG-12-26 (workitem HOTFIX - dummy record restoration)
                       after implementation it was discovered that the dummy
                       record was necessary    

  ***********************************************************************/

  PROCEDURE prc_insert_dummy_rec IS
  BEGIN
    gv_trcmsg := '10.1 Entered into from prc_insert_dummy_rec';

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

    INSERT /*+ APPEND */ INTO atomic.rpt_quotes_r(
      v_last_modified_by_r,
      t_creation_date_r,
      v_created_by_r,
      t_last_modified_date_r,
      n_yearmonth_r,
      v_rpt_active_status_r,
      n_batch_id_r,
      n_quote_sk_r)
    VALUES(
      gc_main_loadedby,
      gd_sysdate,
      gc_main_loadedby,
      gd_sysdate,
      gn_current_month,
      'Y',
      gn_sysdt_batchid,
      - 1
    );

    COMMIT;

    gv_trcmsg := '10.2 Exit from prc_insert_dummy_rec';

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

  EXCEPTION
    WHEN OTHERS THEN
      gv_errmsg := substr(sqlerrm,1,4000);

		--START: 04-JUN-2025: NEW LOGGING MECHANISM CHANGES
      gv_trcmsg := '10.z Error in prc_insert_dummy_rec'|| gv_errmsg;

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
        p_log_util_called_by_r   => gc_main_loadedby
      );

      RAISE;  
      END prc_insert_dummy_rec;

/***********************************************************************
  Purpose:  Main procedure ultimately loads RPT_POSTED_SUSPENSE_R thru partition exchange

  Author     Date     Description
  ---------- -------- -------------------------------------------------
  Satya     13/03/24 Initial Creation
     Rose		 06/03/26   Commenting prc_upd_del_data and adding PKG_GRP_COMMON_UTIL.	 
  awatkins   Jul-23-26 (workitem 524685)
                       Modifying to load data via partition exchange versus kill and fill.
                       Cleaned up the code in general to comply with standards.

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

    --start 23-JUL-26: partition swap additions
    lv_partition_name := 'PART_'|| gv_rpt_table_name|| '_'|| gn_current_month;

    pkg_grp_common_util.prc_create_exchange_table_ddl(
      p_job_id          => gn_out_job_id,
      p_log_seq_num     => 4,
      p_main_table_name => gv_rpt_table_name,
      p_exg_table_name  => gv_exg_table_name,
      p_schema_name     => gv_schema_owner
    );

    pkg_grp_load_rpt_quotes_r.prc_get_cur_data;   

   --start 23-JUL-26: adding code for partition swapping and removing old
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
    FROM atomic.rpt_quotes_r
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

    --adding dummy record back because other objects need it
    --hotfix 8/12/2026
    prc_insert_dummy_rec;

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
  Satya     13/03/24 Initial Creation
  awatkins   Jul-23-26 (workitem 524685)
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

    --20260723 part of partition swap change
    --removed the old open select into ref cursor and replaced with
    --insert into exchange table;
    --also renamed the aliases to add meaning 

    INSERT /*+ APPEND PARALLEL(stg, 4) */ INTO rpt_quotes_r_exg stg (
      v_assigned_policy_number_r, 
      v_curr_quote_status_r, 
      v_line_of_business_r, 
      d_next_renewal_date_r, 
      d_quote_date_r, 
      v_quote_declined_ind_r, 
      d_quote_effective_date_r, 
      v_quote_number_r, 
      v_exchange_name_r, 
      v_version_status_r,
      d_rated_date_t, 
      v_num_lives_bucket_r, 
      n_version_number_r, 
      n_quote_sk_r, 
      v_last_modified_by_r, 
      t_creation_date_r, 
      v_created_by_r, 
      t_last_modified_date_r, 
      n_yearmonth_r, 
      v_rpt_active_status_r, 
      n_batch_id_r, 
      d_quote_creation_date)
    SELECT /*+ PARALLEL(4) */ 
      ins_quotes.v_policy_number_r          AS v_assigned_policy_number_r,
      ins_quotes.v_current_status_r         AS v_curr_quote_status_r,
      quote_dir.v_line_of_business_r        AS v_line_of_business_r,
      ins_quotes.d_calculated_expiry_date_r AS d_next_renewal_date_r,
      ins_quotes.d_rated_date_r             AS d_quote_date_r,
      CASE
        WHEN upper(ins_quotes.v_current_status_r)= 'DECLINEDQUOTE' 
        THEN 'Y'
        ELSE 'N'
      END AS v_current_status_r,
      quote_dir.t_original_quote_eff_date_r AS d_quote_effective_date_r,
      quote_dir.v_quote_number_r            AS v_quote_number_r,
      ins_quotes.v_memexchange_r            AS v_exchange_name_r,
      ins_quotes.v_current_status_r         AS v_version_status_r,
      ins_quotes.d_rated_date_r             AS d_rated_date_t,
      CASE
        WHEN ins_quotes.n_num_lives_r <= 50   
        THEN '<=50'
        WHEN ins_quotes.n_num_lives_r > 50 AND ins_quotes.n_num_lives_r < 100 
        THEN '50-99'
        WHEN ins_quotes.n_num_lives_r >= 100 AND ins_quotes.n_num_lives_r < 200 
        THEN '100-199'
        WHEN ins_quotes.n_num_lives_r >= 200 AND ins_quotes.n_num_lives_r < 300 
        THEN '200-299'
        WHEN ins_quotes.n_num_lives_r >= 300 AND ins_quotes.n_num_lives_r < 400 
        THEN '300-399'
        WHEN ins_quotes.n_num_lives_r >= 400 AND ins_quotes.n_num_lives_r < 500 
        THEN '400-499'
        WHEN ins_quotes.n_num_lives_r >= 500 AND ins_quotes.n_num_lives_r < 1000 
        THEN '500-999'
        WHEN ins_quotes.n_num_lives_r >= 1000 AND ins_quotes.n_num_lives_r < 2000 
        THEN '1,000-1,999'
        WHEN ins_quotes.n_num_lives_r >= 2000 AND ins_quotes.n_num_lives_r < 5000 
        THEN '2,000-4,999'
        WHEN ins_quotes.n_num_lives_r >= 5000 
        THEN '5,000=>' 
        ELSE 'Unknown'
      END AS v_num_lives_bucket_r,
      quote_dir.n_quote_version_number_r    AS n_version_number_r,
      quote_dir.n_quote_sk_r                AS n_quote_sk_r,
      gc_main_loadedby                      v_last_modified_by_r,
      systimestamp                          t_creation_date_r,
      gc_main_loadedby                      v_created_by_r,
      systimestamp                          t_last_modified_date_r,
      gn_current_month                      n_yearmonth_r,
      quote_dir.v_active_status_r           v_rpt_active_status_r,
      gn_sysdt_batchid                      n_batch_id_r,
      ins_quotes.d_quote_creation_date      AS d_quote_creation_date
    FROM atomic.dim_grp_quote_dir_r quote_dir
    INNER JOIN atomic.fct_insurance_quotes ins_quotes
    ON quote_dir.n_quote_sk_r = ins_quotes.n_quote_sk_r
    AND ins_quotes.n_version_number_r = quote_dir.n_quote_version_number_r
    WHERE quote_dir.v_active_status_r = 'Y'
    -- 05/08/24 removed
          --and quote_dir.v_source_system_name_r = 'PACS'
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

end pkg_grp_load_rpt_quotes_r;

/

  GRANT EXECUTE ON "ATOMIC"."PKG_GRP_LOAD_RPT_QUOTES_R" TO "EXT_EIS_RO";
  GRANT EXECUTE ON "ATOMIC"."PKG_GRP_LOAD_RPT_QUOTES_R" TO "ATOMIC_ALL_RO";
  GRANT DEBUG ON "ATOMIC"."PKG_GRP_LOAD_RPT_QUOTES_R" TO "ATOMIC_DEBUG";
