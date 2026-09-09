"PROCEDURE PRC_GRP_LOAD_RPT_CLAIM_SUM_R_INCR_LIFE_ADHOC (
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
	lc_job_name              	    VARCHAR2(100 CHAR) :=&apos;PRC_GRP_LOAD_RPT_CLAIM_SUM_R_INCR_LIFE_ADHOC&apos;;
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
	LD_MIS_CYCLE_MONTH_R			NUMBER;
	LD_LIFE_VALUATION_DATE			DATE;


--Created this adhoc procedure to merge RPT_CLAIM_SUM_R
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

LD_MIS_CYCLE_MONTH_R:= to_number(to_char(LD_MIS_DATE_R,&apos;YYYYMM&apos;));

		lc_trcmsg:=&apos;1.3 D_CYCLE_DATE_R in YYYYMM :-&gt;&apos;||LD_MIS_CYCLE_MONTH_R;

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




		LD_MIS_CYCLE_MONTH_R:= to_number(to_char(LD_MIS_DATE_R,&apos;YYYYMM&apos;));

		lc_trcmsg:=&apos;1.2 D_CYCLE_DATE_R in YYYYMM :-&gt;&apos;||LD_MIS_CYCLE_MONTH_R;

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

		lc_trcmsg:=&apos;2 Merging RPT_CLAIM_SUM_R table based on batchid :-&gt;&apos;||LD_MIS_DATE_R;		

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


MERGE  INTO ATOMIC.RPT_CLAIM_SUM_R TGT
USING (
	SELECT n_claim_sk_r
		,n_claim_coverage_sk_r
		,n_claim_coverage_group_sk_r
		,sum(nvl(N_RESERVE_DIRECT_BEST_ESTMT_R, 0)) N_CURR_BEST_ESTIMATE_RESERVE_R
		,sum(nvl(N_RESERVE_DIRECT_GAAP_R, 0)) N_CURR_GAAP_RESERVE_R
		,sum(nvl(N_RESERVE_DIRECT_STAT_R, 0)) N_CURR_STAT_RESERVE_R
		,sum(nvl(N_RESERVE_DIRECT_FIELD_R, 0)) N_CURR_FIELD_RESERVE_R
		,D_RESERVE_VALUATION_DATE_R D_MOST_RECENT_RESERVE_VALUATION_DATE_R
		,n_reportmonth_r
		,sum(nvl(N_CURRENT_RESERVE_R, 0)) N_CURRENT_RESERVE_R
	FROM ATOMIC.RPT_RESERVE_DETAILS_R A
	WHERE a.D_RESERVE_VALUATION_DATE_R = LD_MIS_DATE_R
		AND n_reportmonth_r = LD_MIS_CYCLE_MONTH_R 
		--and v_reserve_type_ind_r=&apos;L&apos;
		AND EXISTS (
			SELECT 1
			FROM atomic.RPT_CLAIM_SUM_R
			WHERE RPT_CLAIM_SUM_R.N_CLAIM_COVERAGE_GROUP_SK_R = A.N_CLAIM_COVERAGE_GROUP_SK_R
				AND RPT_CLAIM_SUM_R.N_CLAIM_COVERAGE_SK_R = A.N_CLAIM_COVERAGE_SK_R
				AND RPT_CLAIM_SUM_R.N_CLAIM_SK_R = A.N_CLAIM_SK_R
				AND RPT_CLAIM_SUM_R.N_YEARMONTH_R = LD_MIS_CYCLE_MONTH_R
			)
	GROUP BY n_claim_sk_r
		,n_claim_coverage_sk_r
		,n_claim_coverage_group_sk_r
		,d_reserve_valuation_date_r
		,n_reportmonth_r
	) SRC
	ON (
			SRC.N_CLAIM_COVERAGE_GROUP_SK_R = TGT.N_CLAIM_COVERAGE_GROUP_SK_R
			AND SRC.n_claim_coverage_sk_r = TGT.n_claim_coverage_sk_r
			AND SRC.n_claim_sk_r = TGT.n_claim_sk_r
			AND SRC.n_reportmonth_r = TGT.N_YEARMONTH_R
			--AND SRC.N_CURR_GAAP_RESERVE_R IS NOT NULL
			)
WHEN MATCHED
	THEN
		UPDATE
		SET TGT.N_CURR_BEST_ESTIMATE_RESERVE_R = SRC.N_CURR_BEST_ESTIMATE_RESERVE_R
			,TGT.N_CURR_GAAP_RESERVE_R = SRC.N_CURR_GAAP_RESERVE_R
			,TGT.N_CURR_STAT_RESERVE_R = SRC.N_CURR_STAT_RESERVE_R
			,TGT.N_CURR_FIELD_RESERVE_R = SRC.N_CURR_FIELD_RESERVE_R
			,TGT.d_most_recent_reserve_valuation_date_r = SRC.d_most_recent_reserve_valuation_date_r
			,TGT.N_CURRENT_RESERVE_R = SRC.N_CURRENT_RESERVE_R
		WHERE SRC.n_claim_coverage_group_sk_r = TGT.n_claim_coverage_group_sk_r
			AND SRC.n_claim_coverage_sk_r = TGT.n_claim_coverage_sk_r
			AND SRC.n_claim_sk_r = TGT.n_claim_sk_r
			AND SRC.n_reportmonth_r = TGT.N_YEARMONTH_R;

   lc_run_cnt:= SQL%ROWCOUNT;
    COMMIT;


	lc_count_type_r:= PKG_GRP_LOG_UTIL.gc_count_type_merge;

    lc_trcmsg:=&apos;2.1 Merged RPT_CLAIM_SUM_R for N_YEARMONTH_R:-&gt;&apos;||LD_MIS_CYCLE_MONTH_R||&apos;and Count&apos;||lc_run_cnt;


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

	lc_trcmsg:=&apos;2.2 Capturing Audit Controls for Reserves RPT_Reserves to RPT_CLAIM_SUM&apos; ;
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
	 (
		p_job_id_r                    =&gt; ln_out_job_id,
		p_batch_id_r                  =&gt; ln_sysdt_batchid,
		p_message_type_r              =&gt; lv_message_type_r,
		p_code_location_r             =&gt; lc_main_loadedby,
		p_message_r                   =&gt; lc_trcmsg,
		p_count_type_r                =&gt; NULL,
		p_count_r                     =&gt; NULL,
		p_duration_r                  =&gt; NULL,
		p_created_by_r                =&gt; lc_job_name,
		out_prcs_job_log_message_id_r =&gt; ln_job_log_message_id_r
	);	

	PRC_GRP_AUDIT_CONTROL_PROCESS (&apos;EDW&apos;,&apos;RESERVES_GAAP_STAT&apos;,&apos;RPT&apos;,&apos;RPT&apos;);

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