"PROCEDURE PRC_GRP_LOAD_RPT_FCT_INCURRED_SUMMARY_R_INCR_LIFE_ADHOC (
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
	lc_job_name              	    VARCHAR2(100 CHAR) :=&apos;PRC_GRP_LOAD_RPT_FCT_INCURRED_SUMMARY_R_INCR_LIFE_ADHOC&apos;;
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


--Created this adhoc procedure to merge RPT_FCT_INCURRED_SUMMARY_R
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





lt_start_time_r:= SYSTIMESTAMP;

		lc_trcmsg:=&apos;2 Merging RPT_FCT_INCURRED_SUMMARY_R table based on batchid :-&gt;&apos;||LD_MIS_DATE_R;		

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
		N_TOTAL_CLAIM_INCURRED_BE_R,
		N_CURR_STAT_WV_DIRECT_AMT_R,
		N_CURR_FIELD_WV_DIRECT_AMT_R,
		N_CURR_GAAP_WV_DIRECT_AMT_R,
		N_CURR_BE_WV_DIRECT_AMT_R,
		N_CHG_STAT_WV_DIRECT_AMT_R,
		N_CHG_FIELD_WV_DIRECT_AMT_R,
		N_CHG_GAAP_WV_DIRECT_AMT_R,
		N_CHG_BE_WV_DIRECT_AMT_R,
		N_PRIOR_STAT_WV_DIRECT_AMT_R,
		N_PRIOR_FIELD_WV_DIRECT_AMT_R,
		N_PRIOR_GAAP_WV_DIRECT_AMT_R,
		N_PRIOR_BE_WV_DIRECT_AMT_R
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
				N_CURR_STAT_WV_DIRECT_AMT_R,
				N_CURR_FIELD_WV_DIRECT_AMT_R,
				N_CURR_GAAP_WV_DIRECT_AMT_R,
				N_CURR_BE_WV_DIRECT_AMT_R,
				N_CHG_STAT_WV_DIRECT_AMT_R,
				N_CHG_FIELD_WV_DIRECT_AMT_R,
				N_CHG_GAAP_WV_DIRECT_AMT_R,
				N_CHG_BE_WV_DIRECT_AMT_R,
				N_PRIOR_STAT_WV_DIRECT_AMT_R,
				N_PRIOR_FIELD_WV_DIRECT_AMT_R,
				N_PRIOR_GAAP_WV_DIRECT_AMT_R,
				N_PRIOR_BE_WV_DIRECT_AMT_R,
				NVL(N_LOSS_PAYMENT_AMT_R, 0) + NVL(N_CURR_GAAP_OS_DIRECT_AMT_R, 0) + NVL(N_CURR_GAAP_IBNR_DIRECT_AMT_R, 0) + NVL(N_CURR_GAAP_WV_DIRECT_AMT_R, 0) AS N_TOTAL_CLAIM_INCURRED_GAAP_R,
				NVL(N_LOSS_PAYMENT_AMT_R, 0) + NVL(N_CURR_STAT_OS_DIRECT_AMT_R, 0) + NVL(N_CURR_STAT_IBNR_DIRECT_AMT_R, 0) + NVL(N_CURR_STAT_WV_DIRECT_AMT_R, 0) AS N_TOTAL_CLAIM_INCURRED_STAT_R,
				NVL(N_LOSS_PAYMENT_AMT_R,0)  +NVL(N_CURR_FIELD_OS_DIRECT_AMT_R,0) + NVL(N_CURR_FIELD_IBNR_DIRECT_AMT_R,0) + NVL(N_CURR_FIELD_WV_DIRECT_AMT_R,0)  AS N_TOTAL_CLAIM_INCURRED_FIELD_R, 
				NVL(N_CURR_BE_OS_DIRECT_AMT_R, 0) + NVL(N_CURR_BE_WV_DIRECT_AMT_R, 0) AS N_CURR_BE_DIRECT_AMT_R,                           
				NVL(N_LOSS_PAYMENT_AMT_R,0)  + NVL(N_CURR_BE_OS_DIRECT_AMT_R,0)+ NVL(N_CURR_BE_IBNR_DIRECT_AMT_R,0) + NVL(N_CURR_BE_WV_DIRECT_AMT_R,0)           AS N_TOTAL_CLAIM_INCURRED_BE_R,
				ROW_NUMBER() OVER(PARTITION BY N_POLICY_SK_R,N_PARTY_SK_R,D_CYCLE_DATE_R,D_UW_DATE_R,V_COVERAGE_R ORDER BY N_POLICY_SK_R,N_PARTY_SK_R,D_CYCLE_DATE_R,D_UW_DATE_R,V_COVERAGE_R)rn

				FROM Atomic.FCT_INCURRED_SUMMARY_R where d_cycle_Date_r=LD_MIS_DATE_R
				)WHERE rn=1

) SRC
ON 
    (TGT.N_POLICY_SK_R = SRC.N_POLICY_SK_R
    AND TGT.N_CUST_PARTY_SK_R = SRC.N_PARTY_SK_R
    AND TGT.D_CYCLE_DATE_R = SRC.D_CYCLE_DATE_R
    AND TGT.D_UW_DATE_R = SRC.D_UW_DATE_R
    AND TGT.V_COVERAGE_R = SRC.V_COVERAGE_R
	AND TGT.D_CYCLE_DATE_R=LD_MIS_DATE_R)
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
		TGT.N_TOTAL_CLAIM_INCURRED_BE_R = SRC.N_TOTAL_CLAIM_INCURRED_BE_R,
		TGT.N_CURR_STAT_WV_DIRECT_AMT_R = SRC.N_CURR_STAT_WV_DIRECT_AMT_R,
		TGT.N_CURR_FIELD_WV_DIRECT_AMT_R = SRC.N_CURR_FIELD_WV_DIRECT_AMT_R,
		TGT.N_CURR_GAAP_WV_DIRECT_AMT_R = SRC.N_CURR_GAAP_WV_DIRECT_AMT_R,
		TGT.N_CURR_BE_WV_DIRECT_AMT_R = SRC.N_CURR_BE_WV_DIRECT_AMT_R,
		TGT.N_CHG_STAT_WV_DIRECT_AMT_R = SRC.N_CHG_STAT_WV_DIRECT_AMT_R,
		TGT.N_CHG_FIELD_WV_DIRECT_AMT_R = SRC.N_CHG_FIELD_WV_DIRECT_AMT_R,
		TGT.N_CHG_GAAP_WV_DIRECT_AMT_R = SRC.N_CHG_GAAP_WV_DIRECT_AMT_R,
		TGT.N_CHG_BE_WV_DIRECT_AMT_R = SRC.N_CHG_BE_WV_DIRECT_AMT_R,
		TGT.N_PRIOR_STAT_WV_DIRECT_AMT_R = SRC.N_PRIOR_STAT_WV_DIRECT_AMT_R,
		TGT.N_PRIOR_FIELD_WV_DIRECT_AMT_R = SRC.N_PRIOR_FIELD_WV_DIRECT_AMT_R,
		TGT.N_PRIOR_GAAP_WV_DIRECT_AMT_R = SRC.N_PRIOR_GAAP_WV_DIRECT_AMT_R,
		TGT.N_PRIOR_BE_WV_DIRECT_AMT_R = SRC.N_PRIOR_BE_WV_DIRECT_AMT_R
WHERE 
    TGT.N_POLICY_SK_R = SRC.N_POLICY_SK_R
    AND TGT.N_CUST_PARTY_SK_R = SRC.N_PARTY_SK_R
    AND TGT.D_CYCLE_DATE_R = SRC.D_CYCLE_DATE_R
    AND TGT.D_UW_DATE_R = SRC.D_UW_DATE_R
    AND TGT.V_COVERAGE_R = SRC.V_COVERAGE_R;


   lc_run_cnt:= SQL%ROWCOUNT;
    COMMIT;


	lc_count_type_r:= PKG_GRP_LOG_UTIL.gc_count_type_merge;

    lc_trcmsg:=&apos;2.1 Merged RPT_FCT_INCURRED_SUMMARY_R for D_CYCLE_DATE_R:-&gt;&apos;||LD_MIS_DATE_R||&apos;and Count&apos;||lc_run_cnt;


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