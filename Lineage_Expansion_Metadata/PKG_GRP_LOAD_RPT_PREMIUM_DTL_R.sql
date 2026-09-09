--------------------------------------------------------
--  DDL for Package Body PKG_GRP_LOAD_RPT_PREMIUM_DTL_R
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ATOMIC"."PKG_GRP_LOAD_RPT_PREMIUM_DTL_R" 
IS
/***********************************************************************
  Purpose:  This package body contains procedures which loads data into RPT_PREMIUM_DTL_R
  Author     	Date     		Description
  ---------- 	-------- 		-------------------------------------------------
  VGireesh   	10/11/23 		Initial Creation
  VGireesh   	22/02/24 		Enabled rebuilding indexes
  VGireesh   	26/02/24 		for month end  that the tables start loading data in the next month partition
								Ex: March data on February 29th (as of 2.28).
									27th is Feb Fisc Month End    202402  should be truncate and load in 202402 partition
									28th is feb Fisc Month End +1 202402  should be truncate and load in 202402 partition
									29th is Feb Fisc Month End +2 202403  should inactive records against the partition 202402 and load data in 202403 partition
  VGireesh   	03/04/24 		Added Parallel to rebuild index fast  parallel 16 nologging and Commented prc_get_cur_data, added the CURSOR in the main
  VGireesh   	20/07/24 		Query has been reframed to reduce the load time  it took 278 mins to load 63177297 records
  VGireesh   	31/07/24 		Added filter where v_source_system_name_r='VUE') for DIM_GRP_BILLING_POL_BILLGRP_R
  VGireesh   	12/08/24 		Introduced RPT_PREMIUM_DTL_R_DRQ_MV_SSL for performnace issues before this the job was taking  200 mins max mins 300
  VGireesh   	26/08/24 		on 25th and 26th aug took 198 mins , now temp fix increased parallelsim from 4 to 8 in the driving query to see the performance improvement
  VGireesh   	29/08/24 		Due to performance issue Converted Daily insert into MERGE thiCommented truncate partition call in the procedure prc_upd_del_data and introduced prc_merge_data and called in main and commented parallel hint
  Shiva   		22-Aug-2025 	Added Coding Standarization
  awatkins   Jul-6-26 (workitem 524649)
                       Cleaned up / Reworked to match new pattern for partition swapping.      
  ***********************************************************************/

	--Global Constants
	gd_sysdate             	DATE              	:= TRUNC(SYSDATE);
	gn_prior_month         	NUMBER            	:= TO_NUMBER(TO_CHAR(ADD_MONTHS(TRUNC(gd_sysdate, 'MM'), -1),'YYYYMM'));
	gn_current_month       	NUMBER            	:= TO_NUMBER(TO_CHAR(gd_sysdate,'YYYYMM'));
	gn_sysdt_batchid       	NUMBER            	:= TO_NUMBER(TO_CHAR(gd_sysdate,'YYYYMMDD'));
	gc_main_loadedby       	VARCHAR2(100 CHAR)	:='PKG_GRP_LOAD_RPT_PREMIUM_DTL_R.MAIN'      ;
  gc_getcur_loadedby      VARCHAR2(100 CHAR)  :='PKG_GRP_LOAD_RPT_PREMIUM_DTL_R.PRC_GET_CUR_DATA';

	gv_trcmsg              	CLOB              	:='Trace Message:->';
	gc_job_name            	VARCHAR2(50 CHAR) 	:='GRP_LOAD_RPT_PREMIUM_DTL_R';

	gc_running_status      	VARCHAR2(30)      	:='Running';
	gc_error_status        	VARCHAR2(30)      	:='Error';
	gc_success_status      	VARCHAR2(30)      	:='Success';
	gc_source              	VARCHAR2(30)      	:='EDW';

  gc_main_entity          VARCHAR2(30)        := 'RPT_PREMIUM_DTL_R';  


	--Global Variables
	gn_out_job_id            NUMBER;
	gv_errmsg                VARCHAR2(4000 CHAR);
	gn_job_log_message_id_r  NUMBER;
	gd_fic_mis_date          DATE;--29-Aug-2024 changes

	/* Start: New logging mechanism added: 20-May-2025*/
	gc_message_type_r 	PRCS_JOB_LOG_MESSAGE_R.v_message_type_r%TYPE    := PKG_GRP_LOG_UTIL.gc_message_type_info;
	gc_count_type_r 	  PRCS_JOB_LOG_MESSAGE_R.v_count_type_r%TYPE      := PKG_GRP_LOG_UTIL.gc_count_type_insert;
	gc_duration_r       PRCS_JOB_LOG_MESSAGE_R.T_DURATION_R%TYPE 		:=0;
	gc_run_cnt          PRCS_JOB_LOG_MESSAGE_R.N_COUNT_R%TYPE 	 		:=0;
	gc_loop_counter_r   PRCS_JOB_LOG_MESSAGE_R.N_COUNT_R%TYPE 			:=0;
	gt_start_time_r 	  TIMESTAMP;
	gt_end_time_r 		  TIMESTAMP;
	gn_target_count     number;
	gn_target_sum1      number;
	gn_target_sum2      number;
	gc_target           varchar2(30) :='RPT';
	/* End: New logging mechanism added: 20-May-2025*/

    --start 6-JUL-26: partition swap additions
  gv_rpt_table_name       CONSTANT prcs_job_log_r.v_job_name_r%TYPE := 'RPT_PREMIUM_DTL_R';
  gv_exg_table_name       CONSTANT prcs_job_log_r.v_job_name_r%TYPE := gv_rpt_table_name|| '_EXG';
  gv_schema_owner         CONSTANT prcs_job_log_r.v_job_name_r%TYPE := 'ATOMIC'; 
    --end 6-JUL-26: partition swap additions

/**************************************************************************************
  Purpose:  Main procedures calls other procedure to load data in RPT_PREMIUM_DTL_R
  Author     	Date     		Description
  ---------- 	-------- 		-------------------------------------------------
  Shiva   	 	23-Aug-2025 	Added Coding Standarization
  awatkins    01-Jul-26     Cleaned up the pattern for kill and fill

  *************************************************************************************/
  PROCEDURE main
  IS
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

    -- Call Proc to load data based to RPT table
    pkg_grp_load_rpt_premium_dtl_r.prc_get_cur_data;

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

    /*Audit Control Code*/   

    gv_trcmsg:='9. Audit Control Code as Part of reconcilation between EDW and RPT  ';
    gt_start_time_r := systimestamp;

    SELECT sum(N_PREMIUM_DUE_AMOUNT_R),
      sum(N_PREMIUM_PAID_AMOUNT_R) 
    INTO gn_target_sum1,
      gn_target_sum2 
    FROM atomic.RPT_PREMIUM_DTL_R_EXG;

    gn_target_count :=gc_run_cnt;
	  /*Audit Control Code*/  

    PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
     (
		  p_job_id_r                    => gn_out_job_id,
		  p_batch_id_r                  => gn_sysdt_batchid,
		  p_message_type_r              => gc_message_type_r,
		  p_code_location_r             => gc_main_loadedby,
		  p_message_r                   => gv_trcmsg,
		  p_count_type_r                => 'AUDIT_TARGET_COUNT',
		  p_count_r                     => gn_target_count,
		  p_duration_r                  => NULL,
		  p_created_by_r                => GC_JOB_NAME,
		  out_prcs_job_log_message_id_r => gn_job_log_message_id_r
     );	

    PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
     (
		  p_job_id_r                    => gn_out_job_id,
		  p_batch_id_r                  => gn_sysdt_batchid,
		  p_message_type_r              => gc_message_type_r,
		  p_code_location_r             => gc_main_loadedby,
		  p_message_r                   => gv_trcmsg,
		  p_count_type_r                => 'AUDIT_TARGET_SUM1',
		  p_count_r                     => gn_target_sum1,
		  p_duration_r                  => NULL,
		  p_created_by_r                => GC_JOB_NAME,
		  out_prcs_job_log_message_id_r => gn_job_log_message_id_r
     );	

    PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
     (
		  p_job_id_r                    => gn_out_job_id,
		  p_batch_id_r                  => gn_sysdt_batchid,
		  p_message_type_r              => gc_message_type_r,
		  p_code_location_r             => gc_main_loadedby,
		  p_message_r                   => gv_trcmsg,
		  p_count_type_r                => 'AUDIT_TARGET_SUM2',
		  p_count_r                     => gn_target_sum2,
		  p_duration_r                  => NULL,
		  p_created_by_r                => GC_JOB_NAME,
		  out_prcs_job_log_message_id_r => gn_job_log_message_id_r
     );	

    PRC_GRP_AUDIT_CONTROL_PROCESS (
      p_source_system     => gc_source,
      p_main_entity       => GC_JOB_NAME,
      p_source_layer_name => gc_source,
      p_target_layer_name => gc_target);
     /*Audit Control Code*/   

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

	--29-Aug-2024 changes ends
    gv_trcmsg:='1.z Exit from main';

	/* Start: New logging mechanism added: 20-May-2025*/			
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
		 (
			p_job_id_r                    => gn_out_job_id,
			p_batch_id_r                  => gn_sysdt_batchid,
			p_message_type_r              => gc_message_type_r,
			p_code_location_r             => gc_main_loadedby,
			p_message_r                   => gv_trcmsg,
			p_count_type_r                => NULL,
			p_count_r                     => NULL,
			p_duration_r                  => NULL,
			p_created_by_r                => GC_JOB_NAME,
			out_prcs_job_log_message_id_r => gn_job_log_message_id_r
		 );	
	/* End: New logging mechanism added: 20-May-2025*/	

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

  --29-Aug-2024 changes starts
/**************************************************************************************
  Purpose:  Procedure to MERGE the data other than Fisc Month ENd +2nd day
  Author     	Date     		Description
  ---------- 	-------- 		-------------------------------------------------
  Shiva   	 	23-Aug-2025 	Added Coding Standarization
   Joe        09/02/2026   Audit Control Code as part of reconcilation between EDW and RPT.
  awatkins   Jul-6-26 (workitem 524649)
                       Reworked to match new pattern.
  *************************************************************************************/
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

    INSERT /*+ APPEND PARALLEL(stg, 4) */ INTO RPT_PREMIUM_DTL_R_EXG stg  
    SELECT /*+ PARALLEL(src, 4) */
        GN_CURRENT_MONTH                         	AS N_REPORTMONTH_R--26-FEB-2024 CHANGES
       ,n_Inforce_Number_of_Lives_R                	AS N_INFORCE_NUMBER_OF_LIVES_R            
       ,n_Most_Recent_Posted_Number_of_Lives_R     	AS N_MOST_RECENT_POSTED_NUMBER_OF_LIVES_R 
       ,N_Most_Recent_Premium_Posted_Amount_R      	AS N_MOST_RECENT_PREMIUM_POSTED_AMOUNT_R
       ,N_Policy_Billgroup_ID_R                    	AS N_POLICY_BILLGROUP_ID_R
       ,n_Premium_Due_Amount_R                     	AS N_PREMIUM_DUE_AMOUNT_R
       ,n_Premium_Number_of_Lives_R                	AS N_PREMIUM_NUMBER_OF_LIVES_R
       ,n_Premium_Paid_Amount_R                    	AS N_PREMIUM_PAID_AMOUNT_R
       ,n_Premium_Policy_Invoice_ID_R              	AS N_PREMIUM_POLICY_INVOICE_ID_R
       ,n_Premium_Volume_R                         	AS N_PREMIUM_VOLUME_R
       ,n_Premium_Class_ID_R                       	AS N_PREMIUM_CLASS_ID_R
       ,n_Premium_Coverage_ID_R                    	AS N_PREMIUM_COVERAGE_ID_R
       ,n_Net_Premium_ID_R                         	AS N_NET_PREMIUM_ID_R
       ,N_BILLGROUP_SK_R                           	AS N_BILLGROUP_SK_R
       ,N_POLICY_SK_R                              	AS N_POLICY_SK_R
       ,n_cust_party_sk_r                          	AS N_CUST_PARTY_SK_R
       ,N_PRODUCT_SK_R                             	AS N_PRODUCT_SK_R
       ,N_PREMIUM_PAYMENT_ID_R                     	AS N_PREMIUM_PAYMENT_ID_R
       ,gc_getcur_loadedby                          AS V_LAST_MODIFIED_BY_R
       ,systimestamp                                AS T_CREATION_DATE_R
       ,gc_getcur_loadedby                          AS V_CREATED_BY_R
       ,systimestamp                                AS T_LAST_MODIFIED_DATE_R
       ,'Y'                                         AS V_RPT_ACTIVE_STATUS_R
       ,GN_SYSDT_BATCHID                         	AS N_BATCH_ID_R
       ,V_SOURCE_SYSTEM_NAME_R						AS V_SOURCE_SYSTEM_NAME_R
    FROM ATOMIC.RPT_PREMIUM_DTL_R_DRQ_MV_SSL src;

    gc_run_cnt:= SQL%ROWCOUNT;
    COMMIT;

	/* Start: New logging mechanism added: 20-May-2025*/	
    gv_trcmsg := '5.2 Completion of insertion';
    gt_end_time_r := systimestamp;

    pkg_grp_log_util.prc_ins_prcs_job_log_message_r(
      p_job_id_r                    => gn_out_job_id,
      p_batch_id_r                  => gn_sysdt_batchid,
      p_message_type_r              => gc_message_type_r,
      p_code_location_r             => gc_getcur_loadedby,
      p_message_r                   => gv_trcmsg,
      p_count_type_r                => gc_count_type_r,
      p_count_r                     => gc_run_cnt,
      p_duration_r                  => fnc_grp_time_duration(gt_start_time_r,gt_end_time_r),
      p_created_by_r                => gc_job_name,
      out_prcs_job_log_message_id_r => gn_job_log_message_id_r
    );	       	
	/* End: New logging mechanism added: 20-May-2025*/

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

END PKG_GRP_LOAD_RPT_PREMIUM_DTL_R;

/

  GRANT EXECUTE ON "ATOMIC"."PKG_GRP_LOAD_RPT_PREMIUM_DTL_R" TO "ATOMIC_ALL_RO";
  GRANT EXECUTE ON "ATOMIC"."PKG_GRP_LOAD_RPT_PREMIUM_DTL_R" TO "EXT_EIS_RO";
  GRANT DEBUG ON "ATOMIC"."PKG_GRP_LOAD_RPT_PREMIUM_DTL_R" TO "ATOMIC_DEBUG";
