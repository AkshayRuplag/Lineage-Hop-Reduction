"PROCEDURE PRC_GRP_LOAD_FCT_RPT_CLAIM_SUMMARY_R_INCR_LIFE_ADHOC (
    P_BATCH_ID_R IN NUMBER
) AS
    V_SYS_DATE          VARCHAR2(15) := TO_CHAR(SYSDATE, &apos;YYYYMMDDHHMISS&apos;);
    LD_MIS_DATE_R       DATE;
    --LN_REP_MON_R        VARCHAR2(8);
    LC_TRCMSG           VARCHAR2(4000) := &apos;TRACE MESSAGE:-&gt;&apos;;
    --LN_BATCH_ID_R       NUMBER := TO_NUMBER(TO_CHAR(P_BATCH_ID_R,&apos;YYYYMMDD&apos;));
    LN_BATCH_ID_R       NUMBER := P_BATCH_ID_R;
    --LN_BATCH_ID_R_1      NUMBER := P_BATCH_ID_R;
	lc_source                       VARCHAR2(30)       :=&apos;EDW&apos;;
	lc_job_name              	    VARCHAR2(100 CHAR) :=&apos;PRC_GRP_LOAD_FCT_RPT_CLAIM_SUMMARY_R_INCR_LIFE_ADHOC&apos;;
	lc_running_status               VARCHAR2(30)       :=&apos;Running&apos;;
	lc_error_status          		VARCHAR2(30)       :=&apos;Error&apos;;
	lc_success_status        		VARCHAR2(30)       :=&apos;Success&apos;;
	ln_sysdt_batchid                NUMBER             := TO_NUMBER(TO_CHAR(sysdate,&apos;YYYYMMDD&apos;));
	--lc_main_loadedby              VARCHAR2(100 CHAR) :=&apos;PKG_GRP_MONTH_END_LOAD.MAIN&apos;;
	lc_main_loadedby                VARCHAR2(100 CHAR) :=NULL;
	ln_out_job_id                   NUMBER;
	--lc_trcmsg                       CLOB               :=&apos;Trace Message:-&gt;&apos;;
	lv_message_type_r             	PRCS_JOB_LOG_MESSAGE_R.v_message_type_r%TYPE    := PKG_GRP_LOG_UTIL.gc_message_type_info;
	ln_job_log_message_id_r         NUMBER;
	ld_sysdate DATE := SYSDATE;
	lc_errmsg                		VARCHAR2(4000 CHAR);
	lt_start_time_r 				TIMESTAMP;
	lt_end_time_r 					TIMESTAMP;
	lc_run_cnt          			PRCS_JOB_LOG_MESSAGE_R.N_COUNT_R%TYPE 	 		:=0;
	lc_count_type_r 				PRCS_JOB_LOG_MESSAGE_R.v_count_type_r%TYPE      := PKG_GRP_LOG_UTIL.gc_count_type_insert;
	lc_duration_r       			PRCS_JOB_LOG_MESSAGE_R.T_DURATION_R%TYPE 		:=0;
	LD_LIFE_VALUATION_DATE          DATE;


--Created this adhoc procedure to merge FCT_RPT_CLAIM_SUMMARY_R
BEGIN


pkg_grp_log_util.prc_insert_log
                       ( p_source              =&gt; lc_source
					    ,p_job_nm              =&gt; lc_job_name
                        ,p_job_status          =&gt; lc_running_status
                        ,p_err_msg             =&gt; null
                        ,p_trc_msg             =&gt; null
                        ,p_n_batch_id          =&gt; ln_sysdt_batchid
                        ,p_log_util_called_by_r=&gt; lc_main_loadedby
						,out_job_id            =&gt; ln_out_job_id
						);					

		lc_trcmsg:=&apos;1.Getting CYCLE_DATE from batch_id&apos;;

		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
						p_job_id_r                    	=&gt; ln_out_job_id,
						p_batch_id_r                  	=&gt; ln_sysdt_batchid,
						p_message_type_r              	=&gt; lv_message_type_r,
						p_code_location_r             	=&gt; lc_main_loadedby,
						p_message_r                   	=&gt; lc_trcmsg,
						p_count_type_r                	=&gt; NULL,
						p_count_r                     	=&gt; NULL,
						p_duration_r                  	=&gt; NULL,
						p_created_by_r                	=&gt; lc_job_name,
						out_prcs_job_log_message_id_r 	=&gt; ln_job_log_message_id_r
						);	


IF SUBSTR(LN_BATCH_ID_R,1,6)= TO_NUMBER(TO_CHAR(sysdate,&apos;YYYYMM&apos;))

THEN
   SELECT MAX(TO_DATE(D_VALUATION_DATE_R , &apos;DD-MON-YY&apos;)) INTO LD_LIFE_VALUATION_DATE
	 FROM Atomic.STG_LIFE_RESERVES_R;

		lc_trcmsg:=&apos;1.1  LD_LIFE_VALUATION_DATE is :-&gt;&apos;||LD_LIFE_VALUATION_DATE;

		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
						p_job_id_r                    	=&gt; ln_out_job_id,
						p_batch_id_r                  	=&gt; ln_sysdt_batchid,
						p_message_type_r              	=&gt; lv_message_type_r,
						p_code_location_r             	=&gt; lc_main_loadedby,
						p_message_r                   	=&gt; lc_trcmsg,
						p_count_type_r                	=&gt; NULL,
						p_count_r                     	=&gt; NULL,
						p_duration_r                  	=&gt; NULL,
						p_created_by_r                	=&gt; lc_job_name,
						out_prcs_job_log_message_id_r 	=&gt; ln_job_log_message_id_r
						);


		SELECT
        D_CALENDAR_DATE_R    INTO LD_MIS_DATE_R
    FROM
        ATOMIC.DIM_TIME_R
    WHERE
         V_END_OF_FISCAL_MONTH_IND_R=&apos;Y&apos;
        AND EXTRACT(MONTH FROM D_CALENDAR_DATE_R) = EXTRACT(MONTH FROM LD_LIFE_VALUATION_DATE)
        AND EXTRACT(YEAR FROM D_CALENDAR_DATE_R) = EXTRACT(YEAR FROM LD_LIFE_VALUATION_DATE);


		lc_trcmsg:=&apos;1.2 CYCLE_DATE LD_MIS_DATE_R is :-&gt;&apos;||LD_MIS_DATE_R;

		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
						p_job_id_r                    	=&gt; ln_out_job_id,
						p_batch_id_r                  	=&gt; ln_sysdt_batchid,
						p_message_type_r              	=&gt; lv_message_type_r,
						p_code_location_r             	=&gt; lc_main_loadedby,
						p_message_r                   	=&gt; lc_trcmsg,
						p_count_type_r                	=&gt; NULL,
						p_count_r                     	=&gt; NULL,
						p_duration_r                  	=&gt; NULL,
						p_created_by_r                	=&gt; lc_job_name,
						out_prcs_job_log_message_id_r 	=&gt; ln_job_log_message_id_r
						);

ELSE

   SELECT
        D_CALENDAR_DATE_R    INTO LD_MIS_DATE_R
    FROM
        ATOMIC.DIM_TIME_R
    WHERE
		N_MONTH_R=CASE WHEN SUBSTR(ln_batch_id_r,5,2)  LIKE &apos;0%&apos; THEN SUBSTR(ln_batch_id_r,6,1) ELSE SUBSTR(ln_batch_id_r,5,2)END  
		AND N_YEAR_R=SUBSTR(ln_batch_id_r,1,4)  AND  V_END_OF_FISCAL_MONTH_IND_R=&apos;Y&apos;;

		lc_trcmsg:=&apos;1.1 CYCLE_DATE LD_MIS_DATE_R is :-&gt;&apos;||LD_MIS_DATE_R;

		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
						p_job_id_r                    	=&gt; ln_out_job_id,
						p_batch_id_r                  	=&gt; ln_sysdt_batchid,
						p_message_type_r              	=&gt; lv_message_type_r,
						p_code_location_r             	=&gt; lc_main_loadedby,
						p_message_r                   	=&gt; lc_trcmsg,
						p_count_type_r                	=&gt; NULL,
						p_count_r                     	=&gt; NULL,
						p_duration_r                  	=&gt; NULL,
						p_created_by_r                	=&gt; lc_job_name,
						out_prcs_job_log_message_id_r 	=&gt; ln_job_log_message_id_r
						);

END IF;



lt_start_time_r:= SYSTIMESTAMP;

		lc_trcmsg:=&apos;2 Merging L Indicator FCT_RPT_CLAIM_SUMMARY_R table based on batchid :-&gt;&apos;||LD_MIS_DATE_R;		

		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
						p_job_id_r                    	=&gt; ln_out_job_id,
						p_batch_id_r                  	=&gt; ln_sysdt_batchid,
						p_message_type_r              	=&gt; lv_message_type_r,
						p_code_location_r             	=&gt; lc_main_loadedby,
						p_message_r                   	=&gt; lc_trcmsg,
						p_count_type_r                	=&gt; NULL,
						p_count_r                     	=&gt; NULL,
						p_duration_r                  	=&gt; NULL,
						p_created_by_r                	=&gt; lc_job_name,
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
			WHERE V_RESERVE_TYPE_IND_R = &apos;L&apos; AND D_RESERVE_VALUATION_DATE_R = LD_MIS_DATE_R									
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

    lc_trcmsg:=&apos;2.1 Merged L Indicator FCT_RPT_CLAIM_SUMMARY_R for D_CYCLE_DATE_R:-&gt;&apos;||LD_MIS_DATE_R||&apos;and Count&apos;||lc_run_cnt;


	lt_end_time_r:= SYSTIMESTAMP;
    lc_duration_r := EXTRACT(SECOND FROM (lt_end_time_r - lt_start_time_r)) +
                     EXTRACT(MINUTE FROM (lt_end_time_r - lt_start_time_r)) * 60 +
                     EXTRACT(HOUR FROM (lt_end_time_r - lt_start_time_r)) * 3600;	


	 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
	 (
		p_job_id_r                    =&gt; ln_out_job_id,
		p_batch_id_r                  =&gt; ln_sysdt_batchid,
		p_message_type_r              =&gt; lv_message_type_r,
		p_code_location_r             =&gt; lc_main_loadedby,
		p_message_r                   =&gt; lc_trcmsg,
		p_count_type_r                =&gt; lc_count_type_r,
		p_count_r                     =&gt; lc_run_cnt,
		p_duration_r                  =&gt; lc_duration_r,
		p_created_by_r                =&gt; lc_job_name,
		out_prcs_job_log_message_id_r =&gt; ln_job_log_message_id_r
	);	

lt_start_time_r:= SYSTIMESTAMP;

		lc_trcmsg:=&apos;3 Merging W Indicator FCT_RPT_CLAIM_SUMMARY_R table based on batchid :-&gt;&apos;||LD_MIS_DATE_R;		

		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
						p_job_id_r                    	=&gt; ln_out_job_id,
						p_batch_id_r                  	=&gt; ln_sysdt_batchid,
						p_message_type_r              	=&gt; lv_message_type_r,
						p_code_location_r             	=&gt; lc_main_loadedby,
						p_message_r                   	=&gt; lc_trcmsg,
						p_count_type_r                	=&gt; NULL,
						p_count_r                     	=&gt; NULL,
						p_duration_r                  	=&gt; NULL,
						p_created_by_r                	=&gt; lc_job_name,
						out_prcs_job_log_message_id_r 	=&gt; ln_job_log_message_id_r
						);

	MERGE INTO ATOMIC.FCT_RPT_CLAIM_SUMMARY_R TGT
USING (
SELECT
		D_RESERVE_VALUATION_DATE_R,
        V_CLAIM_IDENTIFIER_R,
		V_COVERAGE_CODE_R,
		N_CURR_STAT_WV_DIRECT_AMT_R,
		N_CURR_GAAP_WV_DIRECT_AMT_R,
		N_CHG_STAT_WV_DIRECT_AMT_R,
		N_CHG_GAAP_WV_DIRECT_AMT_R,
		(n_curr_stat_wv_direct_amt_r - n_chg_stat_wv_direct_amt_r) AS  n_prior_stat_wv_direct_amt_r,
		(n_curr_gaap_wv_direct_amt_r - n_chg_gaap_wv_direct_amt_r) AS n_prior_gaap_wv_direct_amt_r


	FROM(

			SELECT 
				V_CLAIM_IDENTIFIER_R,
				D_RESERVE_VALUATION_DATE_R,
				V_COVERAGE_CODE_R, 
				MAX(N_RESERVE_DIRECT__STAT__R) 									AS 			N_CURR_STAT_WV_DIRECT_AMT_R,
				MAX(N_RESERVE_DIRECT__GAAP__R)									AS 			N_CURR_GAAP_WV_DIRECT_AMT_R,
				MAX(N_CHG_RESERVE_DIRECT__STAT__R)								AS 			N_CHG_STAT_WV_DIRECT_AMT_R,
				MAX(N_CHG_RESERVE_DIRECT__GAAP__R)								AS			N_CHG_GAAP_WV_DIRECT_AMT_R
			FROM 	
				ATOMIC.FCT_LG_RESERVE_DETAILS_R 
			WHERE 
				V_RESERVE_TYPE_IND_R = &apos;W&apos;
				AND D_RESERVE_VALUATION_DATE_R = LD_MIS_DATE_R
				AND V_CLAIM_IDENTIFIER_R IS NOT NULL	
			GROUP BY 
				V_CLAIM_IDENTIFIER_R,D_RESERVE_VALUATION_DATE_R,
				V_COVERAGE_CODE_R
))SRC
ON  
      (TGT.d_cycle_date_r = SRC.D_RESERVE_VALUATION_DATE_R
       AND TGT.V_CLAIM_IDENTIFIER_R  = SRC.V_CLAIM_IDENTIFIER_R
	   AND TGT.V_COVERAGE_CODE_R = SRC.V_COVERAGE_CODE_R)
WHEN MATCHED THEN 
    UPDATE SET  
		TGT.N_CURR_STAT_WV_DIRECT_AMT_R = SRC.N_CURR_STAT_WV_DIRECT_AMT_R, 
		TGT.N_CURR_GAAP_WV_DIRECT_AMT_R = SRC.N_CURR_GAAP_WV_DIRECT_AMT_R, 
		TGT.N_CHG_STAT_WV_DIRECT_AMT_R = SRC.N_CHG_STAT_WV_DIRECT_AMT_R, 
		TGT.N_CHG_GAAP_WV_DIRECT_AMT_R = SRC.N_CHG_GAAP_WV_DIRECT_AMT_R, 
		TGT.n_prior_stat_wv_direct_amt_r = SRC.n_prior_stat_wv_direct_amt_r, 
		TGT.n_prior_gaap_wv_direct_amt_r = SRC.n_prior_gaap_wv_direct_amt_r;



  lc_run_cnt:= SQL%ROWCOUNT;
    COMMIT;

	lc_count_type_r:= PKG_GRP_LOG_UTIL.gc_count_type_merge;

    lc_trcmsg:=&apos;3.1 Merged W Indicator FCT_RPT_CLAIM_SUMMARY_R for D_CYCLE_DATE_R:-&gt;&apos;||LD_MIS_DATE_R||&apos;and Count&apos;||lc_run_cnt;


	lt_end_time_r:= SYSTIMESTAMP;
    lc_duration_r := EXTRACT(SECOND FROM (lt_end_time_r - lt_start_time_r)) +
                     EXTRACT(MINUTE FROM (lt_end_time_r - lt_start_time_r)) * 60 +
                     EXTRACT(HOUR FROM (lt_end_time_r - lt_start_time_r)) * 3600;	


	 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
	 (
		p_job_id_r                    =&gt; ln_out_job_id,
		p_batch_id_r                  =&gt; ln_sysdt_batchid,
		p_message_type_r              =&gt; lv_message_type_r,
		p_code_location_r             =&gt; lc_main_loadedby,
		p_message_r                   =&gt; lc_trcmsg,
		p_count_type_r                =&gt; lc_count_type_r,
		p_count_r                     =&gt; lc_run_cnt,
		p_duration_r                  =&gt; lc_duration_r,
		p_created_by_r                =&gt; lc_job_name,
		out_prcs_job_log_message_id_r =&gt; ln_job_log_message_id_r
	);	

pkg_grp_log_util.prc_update_log(
      						ln_out_job_id                   --p_job_id
							,lc_success_status              --p_job_status
							,lc_errmsg                      --p_err_msg
							,lc_trcmsg                      --p_trc_msg
							,lc_main_loadedby               --p_log_util_called_by_r
							);
EXCEPTION
WHEN OTHERS THEN

	IF lc_errmsg IS NULL THEN	
		lc_errmsg :=SUBSTR(SQLERRM,1,4000);
	    lc_trcmsg :=&apos;1.z Error in main - &apos;||lc_errmsg;
	END IF;


   /*START: NEW LOGGING MECHANISM CHANGES*/    
    pkg_grp_log_util.prc_update_log_message_r
			( 
			n_prcs_job_log_message_id_r =&gt; ln_job_log_message_id_r,
			p_err_msg 					=&gt; lc_trcmsg 
				);
    /*END: NEW LOGGING MECHANISM CHANGES*/     

	pkg_grp_log_util.prc_update_log
      (
        ln_out_job_id                   	--p_job_id
        ,lc_error_status                	--p_job_status
        ,lc_errmsg                       	--p_err_msg
        ,lc_trcmsg					     	--p_trc_msg
        ,lc_main_loadedby               	--p_log_util_called_by_r
      );
    RAISE;

END ;"