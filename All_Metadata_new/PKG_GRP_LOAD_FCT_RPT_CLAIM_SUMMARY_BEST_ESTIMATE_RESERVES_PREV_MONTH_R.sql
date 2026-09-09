"PACKAGE PKG_GRP_LOAD_FCT_RPT_CLAIM_SUMMARY_BEST_ESTIMATE_RESERVES_PREV_MONTH_R AS
--29-Aug-2025: Created package to merge FCT_RPT_CLAIM_SUMMARY_R for previous month


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
    gc_main_loadedby VARCHAR2(100 CHAR) := &apos;PKG_GRP_LOAD_FCT_RPT_CLAIM_SUMMARY_BEST_ESTIMATE_RESERVES_PREV_MONTH_R.MAIN&apos;;
    gc_job_name VARCHAR2(100 CHAR) := &apos;GRP_LOAD_FCT_RPT_CLAIM_SUMMARY_BEST_ESTIMATE_RESERVES_PREV_MONTH_R&apos;;
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
--Procedure to merge FCT_RPT_CLAIM_SUMMARY_R table for Previous month 	
    PROCEDURE PRC_GRP_LOAD_FCT_RPT_CLAIM_SUMMARY_BEST_ESTIMATE_RESERVES_PREV_MONTH_R;


END PKG_GRP_LOAD_FCT_RPT_CLAIM_SUMMARY_BEST_ESTIMATE_RESERVES_PREV_MONTH_R;PACKAGE BODY PKG_GRP_LOAD_FCT_RPT_CLAIM_SUMMARY_BEST_ESTIMATE_RESERVES_PREV_MONTH_R AS
/***********************************************************************
  Purpose:  This package body contains procedures which loads data into FCT_RPT_CLAIM_SUMMARY_R


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

	gc_trcmsg:=&apos;1.3 Call Procedure PRC_GRP_LOAD_FCT_RPT_CLAIM_SUMMARY_BEST_ESTIMATE_RESERVES_PREV_MONTH_R&apos;;	
	PKG_GRP_LOAD_FCT_RPT_CLAIM_SUMMARY_BEST_ESTIMATE_RESERVES_PREV_MONTH_R.PRC_GRP_LOAD_FCT_RPT_CLAIM_SUMMARY_BEST_ESTIMATE_RESERVES_PREV_MONTH_R;

  gc_trcmsg:=&apos;1.4 Completed Procedure PRC_GRP_LOAD_FCT_RPT_CLAIM_SUMMARY_BEST_ESTIMATE_RESERVES_PREV_MONTH_R&apos;;




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


--Procedure to merge FCT_RPT_CLAIM_SUMMARY_R table for Previous month  
  PROCEDURE PRC_GRP_LOAD_FCT_RPT_CLAIM_SUMMARY_BEST_ESTIMATE_RESERVES_PREV_MONTH_R IS

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

		gc_trcmsg:=&apos;1.Entered into prc_merge_data for FCT_RPT_CLAIM_SUMMARY_R table  for previous month :-&gt;&apos;||gd_mis_cycle_date_r;		

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
	MERGE INTO ATOMIC.FCT_RPT_CLAIM_SUMMARY_R TGT
USING (
SELECT
		D_RESERVE_VALUATION_DATE_R,
        V_CLAIM_IDENTIFIER_R,
        N_CURR_GAAP_RESERVE_DIRECT_R,
        N_CHG_GAAP_OS_DIRECT_AMT_R,
        N_CURR_STAT_RESERVE_DIRECT_R,
        N_CURR_FIELD_RES_DIRECT_AMT_R,
        N_CURR_BE_RESERVE_DIRECT_AMT_R,
		N_CHG_STAT_OS_DIRECT_AMT_R,
		N_CHG_FIELD_RES_DIRECT_AMT_R,
		N_CHG_BE_RESERVE_DIRECT_AMT_R,
		(N_CURR_GAAP_RESERVE_DIRECT_R - N_CHG_GAAP_OS_DIRECT_AMT_R)	AS	n_prior_gaap_reserve_direct_r,
		(N_CURR_STAT_RESERVE_DIRECT_R - N_CHG_STAT_OS_DIRECT_AMT_R)	AS	n_prior_stat_reserve_direct_r,
		(n_curr_field_res_direct_amt_r - N_CHG_FIELD_RES_DIRECT_AMT_R) 	AS 	n_prior_field_res_direct_amt_r,
		(n_curr_be_reserve_direct_amt_r - N_CHG_BE_RESERVE_DIRECT_AMT_R) AS	 n_prior_be_direct_amt_r

	FROM(

			SELECT 										
			V_CLAIM_IDENTIFIER_R,									
			D_RESERVE_VALUATION_DATE_R,									
			SUM(N_RESERVE_DIRECT__GAAP__R) 		AS 	N_CURR_GAAP_RESERVE_DIRECT_R,
			SUM(N_CHG_RESERVE_DIRECT__GAAP__R)	AS 	N_CHG_GAAP_OS_DIRECT_AMT_R,	
			MAX(N_RESERVE_DIRECT__STAT__R) 		AS 	N_CURR_STAT_RESERVE_DIRECT_R,
			MAX(N_RESERVE_DIRECT__FIELD__R)		AS 	N_CURR_FIELD_RES_DIRECT_AMT_R,
			MAX(N_RESERVE_DIRECT_BEST_ESTMT_R)	AS	N_CURR_BE_RESERVE_DIRECT_AMT_R,	
			MAX(N_CHG_RESERVE_DIRECT__STAT__R)	AS 	N_CHG_STAT_OS_DIRECT_AMT_R,	
			MAX(N_CHG_RESERVE_DIRECT__FIELD__R)	AS	N_CHG_FIELD_RES_DIRECT_AMT_R,	
			MAX(N_CHG_RSRV_DIRECT_BEST_ESTMT_R)	AS	N_CHG_BE_RESERVE_DIRECT_AMT_R


			FROM ATOMIC.FCT_LG_RESERVE_DETAILS_R 									
			WHERE V_RESERVE_TYPE_IND_R = &apos;L&apos; AND D_RESERVE_VALUATION_DATE_R = gd_mis_cycle_date_r									
	        AND V_CLAIM_IDENTIFIER_R IS NOT NULL									
			GROUP BY V_CLAIM_IDENTIFIER_R,D_RESERVE_VALUATION_DATE_R
))SRC
ON  
      (TGT.d_cycle_date_r = SRC.D_RESERVE_VALUATION_DATE_R
       AND TGT.V_CLAIM_IDENTIFIER_R  = SRC.V_CLAIM_IDENTIFIER_R)
WHEN MATCHED THEN 
    UPDATE SET  
		TGT.N_CURR_GAAP_RESERVE_DIRECT_R = SRC.N_CURR_GAAP_RESERVE_DIRECT_R, 
		TGT.N_CHG_GAAP_OS_DIRECT_AMT_R = SRC.N_CHG_GAAP_OS_DIRECT_AMT_R, 
		TGT.N_CURR_STAT_RESERVE_DIRECT_R = SRC.N_CURR_STAT_RESERVE_DIRECT_R, 
		TGT.N_CURR_FIELD_RES_DIRECT_AMT_R = SRC.N_CURR_FIELD_RES_DIRECT_AMT_R, 
		TGT.N_CURR_BE_RESERVE_DIRECT_AMT_R = SRC.N_CURR_BE_RESERVE_DIRECT_AMT_R, 
		TGT.N_CHG_STAT_OS_DIRECT_AMT_R = SRC.N_CHG_STAT_OS_DIRECT_AMT_R, 
		TGT.N_CHG_FIELD_RES_DIRECT_AMT_R = SRC.N_CHG_FIELD_RES_DIRECT_AMT_R, 
		TGT.N_CHG_BE_RESERVE_DIRECT_AMT_R = SRC.N_CHG_BE_RESERVE_DIRECT_AMT_R, 
		TGT.n_prior_gaap_reserve_direct_r = SRC.n_prior_gaap_reserve_direct_r, 
		TGT.n_prior_stat_reserve_direct_r = SRC.n_prior_stat_reserve_direct_r,
		TGT.n_prior_field_res_direct_amt_r = SRC.n_prior_field_res_direct_amt_r,
		TGT.n_prior_be_direct_amt_r = SRC.n_prior_be_direct_amt_r;



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

END PRC_GRP_LOAD_FCT_RPT_CLAIM_SUMMARY_BEST_ESTIMATE_RESERVES_PREV_MONTH_R;

END PKG_GRP_LOAD_FCT_RPT_CLAIM_SUMMARY_BEST_ESTIMATE_RESERVES_PREV_MONTH_R;"