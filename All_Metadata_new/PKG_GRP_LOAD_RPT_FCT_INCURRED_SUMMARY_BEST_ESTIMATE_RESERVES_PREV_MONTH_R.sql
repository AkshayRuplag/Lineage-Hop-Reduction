"PACKAGE PKG_GRP_LOAD_RPT_FCT_INCURRED_SUMMARY_BEST_ESTIMATE_RESERVES_PREV_MONTH_R AS
--29-Aug-2025: Created package to merge RPT_FCT_INCURRED_SUMMARY_R for previous month


--Global Constants
    gd_sysdate DATE := trunc(sysdate);
    gn_current_month NUMBER := to_number(to_char(
                                                gd_sysdate,
                                                &apos;YYYYMM&apos;
                                         ));
    gn_sysdt_batchid NUMBER := to_number(to_char(
                                                gd_sysdate,
                                                &apos;YYYYMMDD&apos;
                                         ));
    gc_main_loadedby VARCHAR2(100 CHAR) := &apos;PKG_GRP_LOAD_RPT_FCT_INCURRED_SUMMARY_BEST_ESTIMATE_RESERVES_PREV_MONTH_R.MAIN&apos;;
    gc_job_name VARCHAR2(100 CHAR) := &apos;GRP_LOAD_RPT_FCT_INCURRED_SUMMARY_BEST_ESTIMATE_RESERVES_PREV_MONTH_R&apos;;
    gc_running_status VARCHAR2(30) := &apos;Running&apos;;
    gc_error_status VARCHAR2(30) := &apos;Error&apos;;
    gc_success_status VARCHAR2(30) := &apos;Success&apos;;
    gc_source VARCHAR2(30) := &apos;EDW&apos;;
--Global Variables
    gn_out_job_id NUMBER;
    gc_errmsg VARCHAR2(4000 CHAR);
	gc_trcmsg                       CLOB               :=&apos;Trace Message:-&gt;&apos;;
	gd_mis_cycle_date_r DATE; 
--main procedure
	PROCEDURE Main;
--Procedure to merge RPT_FCT_INCURRED_SUMMARY_R table	
    PROCEDURE PRC_GRP_LOAD_RPT_FCT_INCURRED_SUMMARY_BEST_ESTIMATE_RESERVES_PREV_MONTH_R;


END PKG_GRP_LOAD_RPT_FCT_INCURRED_SUMMARY_BEST_ESTIMATE_RESERVES_PREV_MONTH_R;PACKAGE BODY PKG_GRP_LOAD_RPT_FCT_INCURRED_SUMMARY_BEST_ESTIMATE_RESERVES_PREV_MONTH_R AS
/***********************************************************************
  Purpose:  This package body contains procedures which merge data into RPT_FCT_INCURRED_SUMMARY_R


  Author           Date     Description
  ---------- -------- -------------------------------------------------
  Anantha Jothi   28/08/25 Initial Creation

  ***********************************************************************/
--main procedure
  PROCEDURE MAIN is

  BEGIN

	pkg_grp_log_util.prc_insert_log
                       ( p_source              =&gt; gc_source
					    ,p_job_nm              =&gt; gc_job_name
                        ,p_job_status          =&gt; gc_running_status
                        ,p_err_msg             =&gt; null
                        ,p_trc_msg             =&gt; null
                        ,p_n_batch_id          =&gt; gn_sysdt_batchid
                        ,p_log_util_called_by_r=&gt; gc_main_loadedby
						,out_job_id            =&gt; gn_out_job_id
						);

	gc_trcmsg:=&apos;1. Entered into main&apos;;

	gc_trcmsg:=&apos;1.1 Call utility package function to get gd_mis_cycle_date_r&apos;;

	gd_mis_cycle_date_r := PKG_GRP_RESERVE_UTIL.get_cycle_date_best_estimate_r;  

	gc_trcmsg:=&apos;1.2 Completed package PKG_GRP_RESERVE_UTIL&apos;;

	gc_trcmsg:=&apos;1.3 Call Procedure PRC_GRP_LOAD_RPT_FCT_INCURRED_SUMMARY_BEST_ESTIMATE_RESERVES_PREV_MONTH_R&apos;;	
	PKG_GRP_LOAD_RPT_FCT_INCURRED_SUMMARY_BEST_ESTIMATE_RESERVES_PREV_MONTH_R.PRC_GRP_LOAD_RPT_FCT_INCURRED_SUMMARY_BEST_ESTIMATE_RESERVES_PREV_MONTH_R;

  gc_trcmsg:=&apos;1.1 Completed Procedure PRC_GRP_LOAD_RPT_FCT_INCURRED_SUMMARY_BEST_ESTIMATE_RESERVES_PREV_MONTH_R&apos;;




	gc_trcmsg:=&apos;1.5 Exit from main&apos;;
  pkg_grp_log_util.prc_update_log ( gn_out_job_id --p_job_id
  ,gc_success_status                              --p_job_status
  ,gc_errmsg                                      --p_err_msg
  ,gc_trcmsg                                      --p_trc_msg
  ,gc_main_loadedby                               --p_log_util_called_by_r
  );
EXCEPTION
WHEN OTHERS THEN
  gc_errmsg :=SUBSTR(SQLERRM,1,4000);
  gc_trcmsg :=gc_trcmsg||&apos;1. Error in main&apos;||chr(13);
  pkg_grp_log_util.prc_update_log ( gn_out_job_id --p_job_id
  ,gc_error_status                                --p_job_status
  ,gc_errmsg                                      --p_err_msg
  ,gc_trcmsg||chr(13)||gc_errmsg                  --p_trc_msg
  ,gc_main_loadedby                               --p_log_util_called_by_r
  );
  RAISE;
END main;

--Procedure to merge RPT_FCT_INCURRED_SUMMARY_R table for previous month  
  PROCEDURE PRC_GRP_LOAD_RPT_FCT_INCURRED_SUMMARY_BEST_ESTIMATE_RESERVES_PREV_MONTH_R IS

	lv_message_type_r             	PRCS_JOB_LOG_MESSAGE_R.v_message_type_r%TYPE    := PKG_GRP_LOG_UTIL.gc_message_type_info;
	ln_job_log_message_id_r         NUMBER;
	lt_start_time_r 	TIMESTAMP;
	lt_end_time_r 		TIMESTAMP;
	lc_run_cnt          PRCS_JOB_LOG_MESSAGE_R.N_COUNT_R%TYPE 	 		:=0;
	lc_count_type_r 	PRCS_JOB_LOG_MESSAGE_R.v_count_type_r%TYPE      := PKG_GRP_LOG_UTIL.gc_count_type_insert;
	lc_duration_r       PRCS_JOB_LOG_MESSAGE_R.T_DURATION_R%TYPE 		:=0;
BEGIN

	pkg_grp_log_util.prc_insert_log
                       ( p_source              =&gt; gc_source
					    ,p_job_nm              =&gt; gc_job_name
                        ,p_job_status          =&gt; gc_running_status
                        ,p_err_msg             =&gt; null
                        ,p_trc_msg             =&gt; null
                        ,p_n_batch_id          =&gt; gn_sysdt_batchid
                        ,p_log_util_called_by_r=&gt; gc_main_loadedby
						,out_job_id            =&gt; gn_out_job_id
						);




		lt_start_time_r:= SYSTIMESTAMP;

		gc_trcmsg:=&apos;1 Entered into prc_merge_data for RPT_fct_incurred_summary_r table with Fct_Incurred_Summary_R for D_CYCLE_DATE_R:-&gt;&apos;||gd_mis_cycle_date_r;		

		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
						p_job_id_r                    	=&gt; gn_out_job_id,
						p_batch_id_r                  	=&gt; gn_sysdt_batchid,
						p_message_type_r              	=&gt; lv_message_type_r,
						p_code_location_r             	=&gt; gc_main_loadedby,
						p_message_r                   	=&gt; gc_trcmsg,
						p_count_type_r                	=&gt; NULL,
						p_count_r                     	=&gt; NULL,
						p_duration_r                  	=&gt; NULL,
						p_created_by_r                	=&gt; gc_job_name,
						out_prcs_job_log_message_id_r 	=&gt; ln_job_log_message_id_r
						);

MERGE INTO  ATOMIC.RPT_FCT_INCURRED_SUMMARY_R TGT
USING (
    SELECT 
        N_POLICY_SK_R,
        N_PARTY_SK_R,
        D_CYCLE_DATE_R,
        D_UW_DATE_R,
        V_COVERAGE_R,
		N_CURR_GAAP_OS_DIRECT_AMT_R,
		N_CURR_GAAP_PV_DIRECT_AMT_R,
		N_CHG_GAAP_OS_DIRECT_AMT_R,
		N_CHG_GAAP_OS_CEDED_AMT_R,
		N_CURR_STAT_OS_DIRECT_AMT_R,
		N_CURR_STAT_PV_DIRECT_AMT_R,
		N_CURR_FIELD_OS_DIRECT_AMT_R,		
		N_CURR_BE_OS_DIRECT_AMT_R,
		N_CURR_BE_PV_DIRECT_AMT_R,
		N_CHG_STAT_OS_DIRECT_AMT_R,
		N_CHG_STAT_OS_CEDED_AMT_R,
		N_CHG_BE_OS_DIRECT_AMT_R,
		N_PRIOR_GAAP_OS_DIRECT_AMT_R,
		N_PRIOR_STAT_OS_DIRECT_AMT_R,
		N_PRIOR_FIELD_OS_DIRECT_AMT_R,
		N_PRIOR_BE_OS_DIRECT_AMT_R,
		N_TOTAL_CLAIM_INCURRED_GAAP_R,
		N_TOTAL_CLAIM_INCURRED_STAT_R,
		N_TOTAL_CLAIM_INCURRED_FIELD_R,
		N_CURR_BE_DIRECT_AMT_R,
		N_TOTAL_CLAIM_INCURRED_BE_R
    FROM (
			SELECT 
				N_POLICY_SK_R,
				N_PARTY_SK_R,
				D_CYCLE_DATE_R,
				D_UW_DATE_R,
				V_COVERAGE_R,
				N_CURR_GAAP_OS_DIRECT_AMT_R,
				N_CURR_GAAP_PV_DIRECT_AMT_R,
				N_CHG_GAAP_OS_DIRECT_AMT_R,
				N_CHG_GAAP_OS_CEDED_AMT_R,
				N_CURR_STAT_OS_DIRECT_AMT_R,
				N_CURR_STAT_PV_DIRECT_AMT_R,
				NVL(N_CURR_FIELD_OS_DIRECT_AMT_R, 0) + NVL(N_CURR_FIELD_WV_DIRECT_AMT_R, 0) AS N_CURR_FIELD_OS_DIRECT_AMT_R,
				N_CURR_BE_OS_DIRECT_AMT_R,
				N_CURR_BE_PV_DIRECT_AMT_R,
				N_CHG_STAT_OS_DIRECT_AMT_R,
				N_CHG_STAT_OS_CEDED_AMT_R,
				N_CHG_BE_OS_DIRECT_AMT_R,
				N_PRIOR_GAAP_OS_DIRECT_AMT_R,
				N_PRIOR_STAT_OS_DIRECT_AMT_R,
				N_PRIOR_FIELD_OS_DIRECT_AMT_R,
				N_PRIOR_BE_OS_DIRECT_AMT_R,
				NVL(N_LOSS_PAYMENT_AMT_R, 0) + NVL(N_CURR_GAAP_OS_DIRECT_AMT_R, 0) + NVL(N_CURR_GAAP_IBNR_DIRECT_AMT_R, 0) + NVL(N_CURR_GAAP_WV_DIRECT_AMT_R, 0) AS N_TOTAL_CLAIM_INCURRED_GAAP_R,
				NVL(N_LOSS_PAYMENT_AMT_R, 0) + NVL(N_CURR_STAT_OS_DIRECT_AMT_R, 0) + NVL(N_CURR_STAT_IBNR_DIRECT_AMT_R, 0) + NVL(N_CURR_STAT_WV_DIRECT_AMT_R, 0) AS N_TOTAL_CLAIM_INCURRED_STAT_R,
				NVL(N_LOSS_PAYMENT_AMT_R,0)  +NVL(N_CURR_FIELD_OS_DIRECT_AMT_R,0) + NVL(N_CURR_FIELD_IBNR_DIRECT_AMT_R,0) + NVL(N_CURR_FIELD_WV_DIRECT_AMT_R,0)  AS N_TOTAL_CLAIM_INCURRED_FIELD_R, 
				NVL(N_CURR_BE_OS_DIRECT_AMT_R, 0) + NVL(N_CURR_BE_WV_DIRECT_AMT_R, 0) AS N_CURR_BE_DIRECT_AMT_R,                           
				NVL(N_LOSS_PAYMENT_AMT_R,0)  + NVL(N_CURR_BE_OS_DIRECT_AMT_R,0)+ NVL(N_CURR_BE_IBNR_DIRECT_AMT_R,0) + NVL(N_CURR_BE_WV_DIRECT_AMT_R,0)           AS N_TOTAL_CLAIM_INCURRED_BE_R,
				ROW_NUMBER() OVER(PARTITION BY N_POLICY_SK_R,N_PARTY_SK_R,D_CYCLE_DATE_R,D_UW_DATE_R,V_COVERAGE_R ORDER BY N_POLICY_SK_R,N_PARTY_SK_R,D_CYCLE_DATE_R,D_UW_DATE_R,V_COVERAGE_R)rn

				FROM Atomic.FCT_INCURRED_SUMMARY_R where d_cycle_Date_r=gd_mis_cycle_date_r
				)WHERE rn=1

) SRC
ON 
    (TGT.N_POLICY_SK_R = SRC.N_POLICY_SK_R
    AND TGT.N_CUST_PARTY_SK_R = SRC.N_PARTY_SK_R
    AND TGT.D_CYCLE_DATE_R = SRC.D_CYCLE_DATE_R
    AND TGT.D_UW_DATE_R = SRC.D_UW_DATE_R
    AND TGT.V_COVERAGE_R = SRC.V_COVERAGE_R
	AND TGT.D_CYCLE_DATE_R=gd_mis_cycle_date_r)
WHEN MATCHED THEN 
    UPDATE SET  
		TGT.N_CURR_GAAP_OS_DIRECT_AMT_R = SRC.N_CURR_GAAP_OS_DIRECT_AMT_R,
		TGT.N_CURR_GAAP_PV_DIRECT_AMT_R = SRC.N_CURR_GAAP_PV_DIRECT_AMT_R,
		TGT.N_CHG_GAAP_OS_DIRECT_AMT_R = SRC.N_CHG_GAAP_OS_DIRECT_AMT_R,
		TGT.N_CHG_GAAP_OS_CEDED_AMT_R = SRC.N_CHG_GAAP_OS_CEDED_AMT_R,
		TGT.N_CURR_STAT_OS_DIRECT_AMT_R = SRC.N_CURR_STAT_OS_DIRECT_AMT_R,
		TGT.N_CURR_STAT_PV_DIRECT_AMT_R = SRC.N_CURR_STAT_PV_DIRECT_AMT_R,
		TGT.N_CURR_FIELD_OS_DIRECT_AMT_R = SRC.N_CURR_FIELD_OS_DIRECT_AMT_R,
		TGT.N_CURR_BE_OS_DIRECT_AMT_R = SRC.N_CURR_BE_OS_DIRECT_AMT_R,
		TGT.N_CURR_BE_PV_DIRECT_AMT_R = SRC.N_CURR_BE_PV_DIRECT_AMT_R,
		TGT.N_CHG_STAT_OS_DIRECT_AMT_R = SRC.N_CHG_STAT_OS_DIRECT_AMT_R,
		TGT.N_CHG_STAT_OS_CEDED_AMT_R = SRC.N_CHG_STAT_OS_CEDED_AMT_R,
		TGT.N_CHG_BE_OS_DIRECT_AMT_R = SRC.N_CHG_BE_OS_DIRECT_AMT_R,
		TGT.N_PRIOR_GAAP_OS_DIRECT_AMT_R = SRC.N_PRIOR_GAAP_OS_DIRECT_AMT_R,
		TGT.N_PRIOR_STAT_OS_DIRECT_AMT_R = SRC.N_PRIOR_STAT_OS_DIRECT_AMT_R,
		TGT.N_PRIOR_FIELD_OS_DIRECT_AMT_R = SRC.N_PRIOR_FIELD_OS_DIRECT_AMT_R,
		TGT.N_PRIOR_BE_OS_DIRECT_AMT_R = SRC.N_PRIOR_BE_OS_DIRECT_AMT_R,
		TGT.N_TOTAL_CLAIM_INCURRED_GAAP_R = SRC.N_TOTAL_CLAIM_INCURRED_GAAP_R,
		TGT.N_TOTAL_CLAIM_INCURRED_STAT_R = SRC.N_TOTAL_CLAIM_INCURRED_STAT_R,
		TGT.N_TOTAL_CLAIM_INCURRED_FIELD_R = SRC.N_TOTAL_CLAIM_INCURRED_FIELD_R,
		TGT.N_CURR_BE_DIRECT_AMT_R = SRC.N_CURR_BE_DIRECT_AMT_R,
		TGT.N_TOTAL_CLAIM_INCURRED_BE_R = SRC.N_TOTAL_CLAIM_INCURRED_BE_R
WHERE 
    TGT.N_POLICY_SK_R = SRC.N_POLICY_SK_R
    AND TGT.N_CUST_PARTY_SK_R = SRC.N_PARTY_SK_R
    AND TGT.D_CYCLE_DATE_R = SRC.D_CYCLE_DATE_R
    AND TGT.D_UW_DATE_R = SRC.D_UW_DATE_R
    AND TGT.V_COVERAGE_R = SRC.V_COVERAGE_R;


   lc_run_cnt:= SQL%ROWCOUNT;
    COMMIT;

	lc_count_type_r:= PKG_GRP_LOG_UTIL.gc_count_type_merge;

    gc_trcmsg:=&apos;1.1 Exit from in prc_merge_data - Rows Merged :-&gt;&apos;||lc_run_cnt;


	lt_end_time_r:= SYSTIMESTAMP;
    lc_duration_r := EXTRACT(SECOND FROM (lt_end_time_r - lt_start_time_r)) +
                     EXTRACT(MINUTE FROM (lt_end_time_r - lt_start_time_r)) * 60 +
                     EXTRACT(HOUR FROM (lt_end_time_r - lt_start_time_r)) * 3600;	


	 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
	 (
		p_job_id_r                    =&gt; gn_out_job_id,
		p_batch_id_r                  =&gt; gn_sysdt_batchid,
		p_message_type_r              =&gt; lv_message_type_r,
		p_code_location_r             =&gt; gc_main_loadedby,
		p_message_r                   =&gt; gc_trcmsg,
		p_count_type_r                =&gt; lc_count_type_r,
		p_count_r                     =&gt; lc_run_cnt,
		p_duration_r                  =&gt; lc_duration_r,
		p_created_by_r                =&gt; gc_job_name,
		out_prcs_job_log_message_id_r =&gt; ln_job_log_message_id_r
	);	

	gc_trcmsg:=&apos;2 Capturing Audit Controls for Reserves Best Estimate Fct_Incurred_Summary_R to RPT_FCT_INCURRED_SUMMARY_R&apos; ;
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
	 (
		p_job_id_r                    =&gt; gn_out_job_id,
		p_batch_id_r                  =&gt; gn_sysdt_batchid,
		p_message_type_r              =&gt; lv_message_type_r,
		p_code_location_r             =&gt; gc_main_loadedby,
		p_message_r                   =&gt; gc_trcmsg,
		p_count_type_r                =&gt; NULL,
		p_count_r                     =&gt; NULL,
		p_duration_r                  =&gt; NULL,
		p_created_by_r                =&gt; gc_job_name,
		out_prcs_job_log_message_id_r =&gt; ln_job_log_message_id_r
	);	

	PRC_GRP_AUDIT_CONTROL_PROCESS (&apos;EDW&apos;,&apos;RESERVES_BESTESTIMATE&apos;,&apos;FCT&apos;,&apos;RPT&apos;);

	pkg_grp_log_util.prc_update_log(
      						gn_out_job_id                   --p_job_id
							,gc_success_status              --p_job_status
							,gc_errmsg                      --p_err_msg
							,gc_trcmsg                      --p_trc_msg
							,gc_main_loadedby               --p_log_util_called_by_r
							);

	pkg_grp_log_util.prc_update_log(
      						gn_out_job_id                   --p_job_id
							,gc_success_status              --p_job_status
							,gc_errmsg                      --p_err_msg
							,gc_trcmsg                      --p_trc_msg
							,gc_main_loadedby               --p_log_util_called_by_r
							);


EXCEPTION
WHEN OTHERS THEN

	IF gc_errmsg IS NULL THEN	
		gc_errmsg :=SUBSTR(SQLERRM,1,4000);
	    gc_trcmsg :=&apos;1.z Error in main - &apos;||gc_errmsg;
	END IF;



    pkg_grp_log_util.prc_update_log_message_r
			( 
			n_prcs_job_log_message_id_r =&gt; ln_job_log_message_id_r,
			p_err_msg 					=&gt; gc_trcmsg 
				);


	pkg_grp_log_util.prc_update_log
      (
        gn_out_job_id                   	--p_job_id
        ,gc_error_status                	--p_job_status
        ,gc_errmsg                       	--p_err_msg
        ,gc_trcmsg					     	--p_trc_msg
        ,gc_main_loadedby               	--p_log_util_called_by_r
      );
    RAISE;

END PRC_GRP_LOAD_RPT_FCT_INCURRED_SUMMARY_BEST_ESTIMATE_RESERVES_PREV_MONTH_R;

END PKG_GRP_LOAD_RPT_FCT_INCURRED_SUMMARY_BEST_ESTIMATE_RESERVES_PREV_MONTH_R;"