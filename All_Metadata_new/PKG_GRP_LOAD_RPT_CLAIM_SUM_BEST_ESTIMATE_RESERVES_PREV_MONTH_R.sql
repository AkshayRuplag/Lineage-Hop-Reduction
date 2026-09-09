"PACKAGE PKG_GRP_LOAD_RPT_CLAIM_SUM_BEST_ESTIMATE_RESERVES_PREV_MONTH_R AS
--16-Sep-2025: Created package to merge RPT_CLAIM_SUM_R for previous month


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
    gc_main_loadedby VARCHAR2(100 CHAR) := &apos;PKG_GRP_LOAD_RPT_CLAIM_SUM_BEST_ESTIMATE_RESERVES_PREV_MONTH_R.MAIN&apos;;
    gc_job_name VARCHAR2(100 CHAR) := &apos;GRP_LOAD_RPT_CLAIM_SUM_BEST_ESTIMATE_RESERVES_PREV_MONTH_R&apos;;
    gc_running_status VARCHAR2(30) := &apos;Running&apos;;
    gc_error_status VARCHAR2(30) := &apos;Error&apos;;
    gc_success_status VARCHAR2(30) := &apos;Success&apos;;
    gc_source VARCHAR2(30) := &apos;EDW&apos;;
--Global Variables
    gn_out_job_id NUMBER;
    gc_errmsg VARCHAR2(4000 CHAR);
	gc_trcmsg                       CLOB               :=&apos;Trace Message:-&gt;&apos;;
	gd_mis_date_be_r DATE;
	gd_mis_cycle_date_r DATE; 
--main procedure
	PROCEDURE Main;
--Procedure to load RPT_CLAIM_SUM_R table for previous month	
	PROCEDURE PRC_GRP_LOAD_RPT_CLAIM_SUM_BEST_ESTIMATE_RESERVES_PREV_MONTH_R;


END PKG_GRP_LOAD_RPT_CLAIM_SUM_BEST_ESTIMATE_RESERVES_PREV_MONTH_R;PACKAGE BODY PKG_GRP_LOAD_RPT_CLAIM_SUM_BEST_ESTIMATE_RESERVES_PREV_MONTH_R AS
/***********************************************************************
  Purpose:  This package body contains procedures which load data into RPT_CLAIM_SUM_R Table


  Author           Date     Description
  ---------- -------- -------------------------------------------------
  Anantha Jothi   16/09/25 Initial Creation
  Anantha Jothi/Samba   30/03/26 Audit Controls Implementation
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

	gc_trcmsg:=&apos;1.1 Call package function to get gd_mis_date_be_r&apos;;

	gd_mis_date_be_r := PKG_GRP_RESERVE_UTIL.get_valuation_date_best_estimate_r; 

	gc_trcmsg:=&apos;1.2 Call package function to get gd_mis_cycle_date_r&apos;;

	gd_mis_cycle_date_r := PKG_GRP_RESERVE_UTIL.get_cycle_date_best_estimate_r;  


  gc_trcmsg:=&apos;1.4 Call Procedure PRC_GRP_LOAD_RPT_CLAIM_SUM_BEST_ESTIMATE_RESERVES_PREV_MONTH_R&apos;;	
	PKG_GRP_LOAD_RPT_CLAIM_SUM_BEST_ESTIMATE_RESERVES_PREV_MONTH_R.PRC_GRP_LOAD_RPT_CLAIM_SUM_BEST_ESTIMATE_RESERVES_PREV_MONTH_R;

  gc_trcmsg:=&apos;1.5 Completed Procedure PRC_GRP_LOAD_RPT_CLAIM_SUM_BEST_ESTIMATE_RESERVES_PREV_MONTH_R&apos;;



	gc_trcmsg:=&apos;1.6 Exit from main&apos;;
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



--Procedure to load RPT_CLAIM_SUM_R table for previous month	
PROCEDURE PRC_GRP_LOAD_RPT_CLAIM_SUM_BEST_ESTIMATE_RESERVES_PREV_MONTH_R IS

	lv_message_type_r             	PRCS_JOB_LOG_MESSAGE_R.v_message_type_r%TYPE    := PKG_GRP_LOG_UTIL.gc_message_type_info;
	ln_job_log_message_id_r         NUMBER;
	lt_start_time_r 	TIMESTAMP;
	lt_end_time_r 		TIMESTAMP;
	lc_run_cnt          PRCS_JOB_LOG_MESSAGE_R.N_COUNT_R%TYPE 	 		:=0;
	lc_count_type_r 	PRCS_JOB_LOG_MESSAGE_R.v_count_type_r%TYPE      := PKG_GRP_LOG_UTIL.gc_count_type_insert;
	lc_duration_r       PRCS_JOB_LOG_MESSAGE_R.T_DURATION_R%TYPE 		:=0;
	LD_MIS_CYCLE_MONTH_R number;

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



	LD_MIS_CYCLE_MONTH_R:= to_number(to_char(gd_mis_cycle_date_r,&apos;YYYYMM&apos;));

		gc_trcmsg:=&apos;1 D_CYCLE_DATE_R in YYYYMM from stg_best_estimate_reserves_r:-&gt;&apos;||LD_MIS_CYCLE_MONTH_R;

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

Update Atomic.RPT_CLAIM_SUM_R set BE_AND_FIELD_MOST_RECENT_AS_OF_DATE=gd_mis_date_be_r,N_CURR_BEST_ESTIMATE_RESERVE_R=0,N_CURR_FIELD_RESERVE_R=0 where N_YEARMONTH_R = LD_MIS_CYCLE_MONTH_R;

lc_run_cnt:= SQL%ROWCOUNT;
COMMIT;


		lc_count_type_r:= PKG_GRP_LOG_UTIL.gc_count_type_update;
		gC_TRCMSG:= &apos;1 Updated data in RPT_CLAIM_SUM_R record count and yearmonth :-&gt;&apos;||lc_run_cnt||&apos;-&apos;||LD_MIS_CYCLE_MONTH_R;


		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
	 (
		p_job_id_r                    =&gt; gn_out_job_id,
		p_batch_id_r                  =&gt; gn_sysdt_batchid,
		p_message_type_r              =&gt; lv_message_type_r,
		p_code_location_r             =&gt; gc_main_loadedby,
		p_message_r                   =&gt; gc_trcmsg,
		p_count_type_r                =&gt; lc_count_type_r,
		p_count_r                     =&gt; lc_run_cnt,
		p_duration_r                  =&gt; NULL,
		p_created_by_r                =&gt; gc_job_name,
		out_prcs_job_log_message_id_r =&gt; ln_job_log_message_id_r
	);

	lt_start_time_r:= SYSTIMESTAMP;

		gc_trcmsg:=&apos;2 Merging the data to RPT_CLAIM_SUM_R table for previous month&apos;;		

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



MERGE  INTO ATOMIC.RPT_CLAIM_SUM_R TGT
USING 
		(select N_CLAIM_SK_R                  AS N_CLAIM_SK_R
	     ,N_CLAIM_COVERAGE_SK_R              AS N_CLAIM_COVERAGE_SK_R
		 ,N_CLAIM_COVERAGE_GROUP_SK_R        AS N_CLAIM_COVERAGE_GROUP_SK_R
		 ,sum(N_RESERVE_DIRECT_BEST_ESTMT_R) AS N_CURR_BEST_ESTIMATE_RESERVE_R
	     ,sum(N_RESERVE_DIRECT_FIELD_R)      AS N_CURR_FIELD_RESERVE_R
		 ,n_reportmonth_r
	  from ATOMIC.RPT_RESERVE_DETAILS_R a
     where a.D_RESERVE_VALUATION_DATE_R =gd_mis_cycle_date_r
	   AND EXISTS(SELECT 1
					FROM ATOMIC.RPT_CLAIM_SUM_R
				   WHERE RPT_CLAIM_SUM_R.N_CLAIM_COVERAGE_GROUP_SK_R = A.N_CLAIM_COVERAGE_GROUP_SK_R
				     AND RPT_CLAIM_SUM_R.N_CLAIM_COVERAGE_SK_R       = A.N_CLAIM_COVERAGE_SK_R
					 AND RPT_CLAIM_SUM_R.N_CLAIM_SK_R                = A.N_CLAIM_SK_R
					 AND RPT_CLAIM_SUM_R.N_YEARMONTH_R               = LD_MIS_CYCLE_MONTH_R
				  )
	  group by n_claim_sk_r, n_claim_coverage_sk_r, n_claim_coverage_group_sk_r,n_reportmonth_r

		) SRC
		ON (SRC.N_CLAIM_COVERAGE_GROUP_SK_R    =  TGT.N_CLAIM_COVERAGE_GROUP_SK_R
			AND SRC.n_claim_coverage_sk_r      =  TGT.n_claim_coverage_sk_r      
			AND SRC.n_claim_sk_r               =  TGT.n_claim_sk_r               
			AND SRC.n_reportmonth_r            =  TGT.N_YEARMONTH_R)
WHEN MATCHED THEN
	UPDATE SET   TGT.N_CURR_BEST_ESTIMATE_RESERVE_R         = SRC.N_CURR_BEST_ESTIMATE_RESERVE_R                  
				,TGT.N_CURR_FIELD_RESERVE_R                 = SRC.N_CURR_FIELD_RESERVE_R 
				--,TGT.BE_AND_FIELD_MOST_RECENT_AS_OF_DATE 	= LD_MIS_DATE_BE_R
	WHERE 
			SRC.n_claim_coverage_group_sk_r    =TGT.n_claim_coverage_group_sk_r
			and SRC.n_claim_coverage_sk_r      =TGT.n_claim_coverage_sk_r      
			and SRC.n_claim_sk_r               =TGT.n_claim_sk_r               
			AND SRC.n_reportmonth_r            =TGT.N_YEARMONTH_R;

lc_run_cnt:= SQL%ROWCOUNT;
    COMMIT;

	lc_count_type_r:= PKG_GRP_LOG_UTIL.gc_count_type_merge;

    gc_trcmsg:=&apos;2.1 Merged record count and reportmonth :-&gt;&apos;||lc_run_cnt||&apos;-&apos;||LD_MIS_CYCLE_MONTH_R;


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

	gc_trcmsg:=&apos;2.2 Capturing Audit Controls for Reserves Best Estimate RPT_Reserves to RPT_CLAIM_SUM&apos; ;
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

	PRC_GRP_AUDIT_CONTROL_PROCESS (&apos;EDW&apos;,&apos;RESERVES_BEST_ESTIMATE&apos;,&apos;RPT&apos;,&apos;RPT&apos;);

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

END PRC_GRP_LOAD_RPT_CLAIM_SUM_BEST_ESTIMATE_RESERVES_PREV_MONTH_R;

END PKG_GRP_LOAD_RPT_CLAIM_SUM_BEST_ESTIMATE_RESERVES_PREV_MONTH_R;"