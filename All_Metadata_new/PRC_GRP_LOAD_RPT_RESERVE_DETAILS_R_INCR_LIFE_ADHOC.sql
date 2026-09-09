"PROCEDURE PRC_GRP_LOAD_RPT_RESERVE_DETAILS_R_INCR_LIFE_ADHOC (
    P_BATCH_ID_R IN NUMBER
) AS
    V_SYS_DATE          VARCHAR2(15) := TO_CHAR(SYSDATE, &apos;YYYYMMDDHHMISS&apos;);
    LD_MIS_DATE_R       DATE;
	LD_MIS_DATE_PREV_R  DATE;
    --LN_REP_MON_R        VARCHAR2(8);
    LC_TRCMSG           VARCHAR2(4000) := &apos;TRACE MESSAGE:-&gt;&apos;;
    --LN_BATCH_ID_R       NUMBER := TO_NUMBER(TO_CHAR(P_BATCH_ID_R,&apos;YYYYMMDD&apos;));
    LN_BATCH_ID_R       NUMBER := P_BATCH_ID_R;
    --LN_BATCH_ID_R_1      NUMBER := P_BATCH_ID_R;
	lc_source                       VARCHAR2(30)       :=&apos;EDW&apos;;
	lc_job_name              	    VARCHAR2(100 CHAR) :=&apos;PRC_GRP_LOAD_RPT_RESERVE_DETAILS_R_INCR_LIFE_ADHOC&apos;;
	lc_running_status               VARCHAR2(30)       :=&apos;Running&apos;;
	lc_error_status          		VARCHAR2(30)       :=&apos;Error&apos;;
	lc_success_status        		VARCHAR2(30)       :=&apos;Success&apos;;
	ln_sysdt_batchid                NUMBER             := TO_NUMBER(TO_CHAR(sysdate,&apos;YYYYMMDD&apos;));
	--gc_main_loadedby              VARCHAR2(100 CHAR) :=&apos;PKG_GRP_MONTH_END_LOAD.MAIN&apos;;
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
	LD_LIFE_VALUATION_DATE 	 		DATE;


--Created this adhoc procedure to load rpt_reserve_detail
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

	LC_TRCMSG:= &apos;2. Deleting data from rpt_reserve_detail for V_RESERVE_TYPE_IND_R L and W:-&gt;&apos;;

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



	DELETE FROM ATOMIC.RPT_RESERVE_DETAILS_R WHERE V_RESERVE_TYPE_IND_R IN (&apos;L&apos;,&apos;W&apos;) AND D_RESERVE_VALUATION_DATE_R= LD_MIS_DATE_R;
lc_run_cnt:= SQL%ROWCOUNT;	
	COMMIT;



	lc_count_type_r:= PKG_GRP_LOG_UTIL.gc_count_type_delete;
	LC_TRCMSG:= &apos;2.1 Deleted L and W Record from RPT_RESERVE_DETAILS_R for D_RESERVE_VALUATION_DATE_R:-&gt;&apos;||LD_MIS_DATE_R||&apos;and Count&apos;||lc_run_cnt;


		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
	 (
		p_job_id_r                    =&gt; ln_out_job_id,
		p_batch_id_r                  =&gt; ln_sysdt_batchid,
		p_message_type_r              =&gt; lv_message_type_r,
		p_code_location_r             =&gt; lc_main_loadedby,
		p_message_r                   =&gt; lc_trcmsg,
		p_count_type_r                =&gt; lc_count_type_r,
		p_count_r                     =&gt; lc_run_cnt,
		p_duration_r                  =&gt; NULL,
		p_created_by_r                =&gt; lc_job_name,
		out_prcs_job_log_message_id_r =&gt; ln_job_log_message_id_r
	);



lt_start_time_r:= SYSTIMESTAMP;

		lc_trcmsg:=&apos;3.1 Inserting L and W record into RPT_RESERVE_DETAILS_R for D_RESERVE_VALUATION_DATE_R:-&gt;&apos;||LD_MIS_DATE_R;

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

INSERT INTO ATOMIC.RPT_RESERVE_DETAILS_R(
	  N_BEST_ESTIMATE_NET_BENEFIT_R
     ,N_RESERVE_DIRECT_BEST_ESTMT_R
     ,V_BEST_ESTMT_RESERVE_MODEL_R
     ,N_CHG_RSRV_DIRECT_BEST_ESTMT_R
     ,N_CHG_RESERVE_DIRECT_FIELD_R
     ,N_CHG_RESERVE_DIRECT_GAAP_R
     ,N_CHG_RESERVE_DIRECT_STAT_R
     ,N_CHECK_NET_BENEFIT_R
     ,N_CURRENT_RESERVE_R
     ,N_RESERVE_DIRECT_FIELD_R
     ,N_FINANCIAL_NET_BENEFIT_R
     ,N_RESERVE_DIRECT_GAAP_R
     ,N_GROSS_BENEFIT_R
     ,N_NET_BENEFIT_R
     ,N_ORIGINAL_RESERVE_R
     ,N_PRIOR_RESERVE_DIRECT_BEST_ESTMT_R
     ,N_PRIOR_RESERVE_DIRECT_FIELD_R
     ,N_PRIOR_RESERVE_DIRECT_GAAP_R
     ,N_PRIOR_RESERVE_DIRECT_STAT_R
     ,V_RESERVE_TYPE_IND_R
     ,D_RESERVE_VALUATION_DATE_R
     ,N_RESERVE_DIRECT_STAT_R
     ,n_unadjustd_rsrv_direct_gaap_r
     ,N_UNADJUSTD_RSRV_DIRECT_STAT_R
     ,n_claim_sk_r
     ,N_CUST_PARTY_SK_R
     ,n_policy_sk_r
     ,n_claim_coverage_sk_r
     ,N_CLAIM_COVERAGE_GROUP_Sk_R
     ,N_PRODUCT_SK_R
     ,V_LAST_MODIFIED_BY_R
     ,T_CREATION_DATE_R
     ,V_CREATED_BY_R
     ,T_LAST_MODIFIED_DATE_R
     ,V_RPT_ACTIVE_STATUS_R
     ,N_BATCH_ID_R
     ,N_REPORTMONTH_R 
     ,V_PRIMARY_REINSURER_R
     ,V_SECONDARY_REINSURER_R
     ,V_TERNARY_REINSURER_R
     ,N_PRIMARY_REINSURER_REINS_SHARE_PCT_R
     ,N_SECONDARY_REINSURER_REINS_SHARE_PCT_R
     ,N_TERNARY_REINSURER_REINS_SHARE_PCT_R
     ,N_PRIMARY_REINSURER_REINSURANCE_PCT_R
     ,N_SECONDARY_REINSURER_REINSURANCE_PCT_R
     , N_TERNARY_REINSURER_REINSURANCE_PCT_R
     , N_TOTAL_REINSURANCE_PCT_R
     , N_RESERVE_DIRECT_BEST_ESTMT_CEDED_R
     , N_CHG_RSRV_DIRECT_BEST_ESTMT_CEDED_R
     , N_CHG_RESERVE_DIRECT_FIELD_CEDED_R
     , N_CHG_RESERVE_DIRECT_GAAP_CEDED_R
     , N_CHG_RESERVE_DIRECT_STAT_CEDED_R
     , N_CURRENT_RESERVE_CEDED_R
     , N_RESERVE_DIRECT_FIELD_CEDED_R
     , N_RESERVE_DIRECT_GAAP_CEDED_R
     , N_ORIGINAL_RESERVE_CEDED_R
     , N_PRIOR_RESERVE_DIRECT_BEST_ESTMT_CEDED_R
     , N_PRIOR_RESERVE_DIRECT_FIELD_CEDED_R
     , N_PRIOR_RESERVE_DIRECT_GAAP_CEDED_R
     , N_PRIOR_RESERVE_DIRECT_STAT_CEDED_R
     , N_RESERVE_DIRECT_STAT_CEDED_R
     , N_RESERVE_DIRECT_BEST_ESTMT_NET_R
     , N_CHG_RSRV_DIRECT_BEST_ESTMT_NET_R
     , N_CHG_RESERVE_DIRECT_FIELD_NET_R
     , N_CHG_RESERVE_DIRECT_GAAP_NET_R
     , N_CHG_RESERVE_DIRECT_STAT_NET_R
     , N_CURRENT_RESERVE_NET_R
     , N_RESERVE_DIRECT_FIELD_NET_R
     , N_RESERVE_DIRECT_GAAP_NET_R 
     , N_ORIGINAL_RESERVE_NET_R
     , N_PRIOR_RESERVE_DIRECT_BEST_ESTMT_NET_R
     , N_PRIOR_RESERVE_DIRECT_FIELD_NET_R
     , N_PRIOR_RESERVE_DIRECT_GAAP_NET_R
     , N_PRIOR_RESERVE_DIRECT_STAT_NET_R
     , N_RESERVE_DIRECT_STAT_NET_R 
	 , N_INSRD_PARTY_SK_R
     , N_EMPLOYEE_SK_R 
	 , N_RESERVE_CEDED_GAAP_R
	 , N_RESERVE_CEDED_STAT_R
	)
	SELECT  distinct
      A.N_BEST_ESTIMATE_NET_BENEFIT_R
     ,A.N_RESERVE_DIRECT_BEST_ESTMT_R
     ,A.V_BEST_ESTMT_RESERVE_MODEL_R
     ,A.N_CHG_RSRV_DIRECT_BEST_ESTMT_R
     ,A.N_CHG_RESERVE_DIRECT__FIELD__R
     ,A.N_CHG_RESERVE_DIRECT__GAAP__R
     ,A.N_CHG_RESERVE_DIRECT__STAT__R
     ,A.N_CHECK_NET_BENEFIT_R
     ,A.N_CURRENT_RESERVE_R
     ,A.N_RESERVE_DIRECT__FIELD__R
     ,A.N_FINANCIAL_NET_BENEFIT_R
     ,A.N_RESERVE_DIRECT__GAAP__R
     ,A.N_GROSS_BENEFIT_R
     ,A.N_NET_BENEFIT_R
     ,A.N_ORIGINAL_RESERVE_R
     ,(A.N_RESERVE_DIRECT_BEST_ESTMT_R - A.N_CHG_RSRV_DIRECT_BEST_ESTMT_R) N_PRIOR_RESERVE_DIRECT_BEST_ESTMT_R
     ,(A.N_RESERVE_DIRECT__FIELD__R    - A.N_CHG_RESERVE_DIRECT__FIELD__R)    N_PRIOR_RESERVE_DIRECT_FIELD_R
     ,(A.N_RESERVE_DIRECT__GAAP__R     - A.N_CHG_RESERVE_DIRECT__GAAP__R)      N_PRIOR_RESERVE_DIRECT_GAAP_R
     ,(A.N_RESERVE_DIRECT__STAT__R     - A.N_CHG_RESERVE_DIRECT__STAT__R)      N_PRIOR_RESERVE_DIRECT_STAT_R
     ,A.V_RESERVE_TYPE_IND_R
     ,A.D_RESERVE_VALUATION_DATE_R
     ,A.N_RESERVE_DIRECT__STAT__R
     ,a.n_unadjustd_rsrv_direct_gaap_r
     ,A.N_UNADJUSTD_RSRV_DIRECT_STAT_R
     ,a.n_claim_sk_r
     ,nvl(e.N_CUST_PARTY_SK_R,-1) N_CUST_PARTY_SK_R--TEMP
     ,a.n_policy_sk_r
     ,nvl(b.n_claim_coverage_sk_r,-1) n_claim_coverage_sk_r
     ,nvl(B.N_CLAIM_COVERAGE_GROUP_Sk_R,-1) N_CLAIM_COVERAGE_GROUP_Sk_R
     ,c.N_PRODUCT_SK_R
     ,&apos;PKG_GRP_LOAD_RPT_RESERVE_DETAILS_R.PRC_GET_CUR_DATA&apos; as V_LAST_MODIFIED_BY_R
     ,sysdate T_CREATION_DATE_R
     ,&apos;PKG_GRP_LOAD_RPT_RESERVE_DETAILS_R.PRC_GET_CUR_DATA&apos; as V_CREATED_BY_R
     ,sysdate T_LAST_MODIFIED_DATE_R
     ,&apos;N&apos; V_RPT_ACTIVE_STATUS_R
     ,to_number(TO_CHAR(sysdate,&apos;YYYYMMDD&apos;)) N_BATCH_ID_R
     --,to_number(TO_CHAR(D_RESERVE_VALUATION_DATE_R,&apos;YYYYMM&apos;))                       N_REPORTMONTH_R --26-Feb-2024 changes
     ,to_number(TO_CHAR(a.D_RESERVE_VALUATION_DATE_R,&apos;YYYYMM&apos;)) as           N_REPORTMONTH_R --26-Feb-2024 changes
     --21-06-2024 Changes Start
     ,A.V_PRIMARY_REINSURER_R
     ,A.V_SECONDARY_REINSURER_R
     ,A.V_TERNARY_REINSURER_R
     ,A.N_PRIMARY_REINSURER_REINS_SHARE_PCT_R
     ,A.N_SECONDARY_REINSURER_REINS_SHARE_PCT_R
     ,A.N_TERNARY_REINSURER_REINS_SHARE_PCT_R
     ,A.N_PRIMARY_REINSURER_REINSURANCE_PCT_R
     ,A.N_SECONDARY_REINSURER_REINSURANCE_PCT_R
     ,A.N_TERNARY_REINSURER_REINSURANCE_PCT_R
     ,A.N_TOTAL_REINSURANCE_PCT_R
     --21-06-2024 Changes End
     --13/8/24 CHANGES STARTS
     ,(A.N_RESERVE_DIRECT_BEST_ESTMT_R  * A.N_TOTAL_REINSURANCE_PCT_R                                   )     N_RESERVE_DIRECT_BEST_ESTMT_CEDED_R
     ,(A.N_CHG_RSRV_DIRECT_BEST_ESTMT_R * A.N_TOTAL_REINSURANCE_PCT_R                                   )     N_CHG_RSRV_DIRECT_BEST_ESTMT_CEDED_R
     ,(A.N_CHG_RESERVE_DIRECT__FIELD__R * A.N_TOTAL_REINSURANCE_PCT_R                                   )     N_CHG_RESERVE_DIRECT_FIELD_CEDED_R
     ,(A.N_CHG_RESERVE_DIRECT__GAAP__R  * A.N_TOTAL_REINSURANCE_PCT_R                                   )     N_CHG_RESERVE_DIRECT_GAAP_CEDED_R
     ,(A.N_CHG_RESERVE_DIRECT__STAT__R  * A.N_TOTAL_REINSURANCE_PCT_R                                   )     N_CHG_RESERVE_DIRECT_STAT_CEDED_R
     ,(A.N_CURRENT_RESERVE_R            * A.N_TOTAL_REINSURANCE_PCT_R                                   )     N_CURRENT_RESERVE_CEDED_R
     ,(A.N_RESERVE_DIRECT__FIELD__R     * A.N_TOTAL_REINSURANCE_PCT_R                                   )     N_RESERVE_DIRECT_FIELD_CEDED_R
     ,(A.N_RESERVE_DIRECT__GAAP__R      * A.N_TOTAL_REINSURANCE_PCT_R                                   )     N_RESERVE_DIRECT_GAAP_CEDED_R
     ,(A.N_ORIGINAL_RESERVE_R           * A.N_TOTAL_REINSURANCE_PCT_R                                   )     N_ORIGINAL_RESERVE_CEDED_R
     ,((A.N_RESERVE_DIRECT_BEST_ESTMT_R - A.N_CHG_RSRV_DIRECT_BEST_ESTMT_R) * A.N_TOTAL_REINSURANCE_PCT_R )     N_PRIOR_RESERVE_DIRECT_BEST_ESTMT_CEDED_R
     ,((A.N_RESERVE_DIRECT__FIELD__R - A.N_CHG_RESERVE_DIRECT__FIELD__R) * A.N_TOTAL_REINSURANCE_PCT_R    )     N_PRIOR_RESERVE_DIRECT_FIELD_CEDED_R
     ,((A.N_RESERVE_DIRECT__GAAP__R - A.N_CHG_RESERVE_DIRECT__GAAP__R) * A.N_TOTAL_REINSURANCE_PCT_R      )     N_PRIOR_RESERVE_DIRECT_GAAP_CEDED_R
     ,((A.N_RESERVE_DIRECT__STAT__R - A.N_CHG_RESERVE_DIRECT__STAT__R) * A.N_TOTAL_REINSURANCE_PCT_R      )     N_PRIOR_RESERVE_DIRECT_STAT_CEDED_R
     ,(A.N_RESERVE_DIRECT__STAT__R * A.N_TOTAL_REINSURANCE_PCT_R                                        )     N_RESERVE_DIRECT_STAT_CEDED_R
     ,(A.N_RESERVE_DIRECT_BEST_ESTMT_R - (A.N_RESERVE_DIRECT_BEST_ESTMT_R * A.N_TOTAL_REINSURANCE_PCT_R)  )     N_RESERVE_DIRECT_BEST_ESTMT_NET_R
     ,(A.N_CHG_RSRV_DIRECT_BEST_ESTMT_R - (A.N_CHG_RSRV_DIRECT_BEST_ESTMT_R * A.N_TOTAL_REINSURANCE_PCT_R))     N_CHG_RSRV_DIRECT_BEST_ESTMT_NET_R
     ,(A.N_CHG_RESERVE_DIRECT__FIELD__R - (A.N_CHG_RESERVE_DIRECT__FIELD__R * A.N_TOTAL_REINSURANCE_PCT_R))     N_CHG_RESERVE_DIRECT_FIELD_NET_R
     ,(A.N_CHG_RESERVE_DIRECT__GAAP__R - (A.N_CHG_RESERVE_DIRECT__GAAP__R * A.N_TOTAL_REINSURANCE_PCT_R)  )     N_CHG_RESERVE_DIRECT_GAAP_NET_R
     ,(A.N_CHG_RESERVE_DIRECT__STAT__R - (A.N_CHG_RESERVE_DIRECT__STAT__R * A.N_TOTAL_REINSURANCE_PCT_R)  )     N_CHG_RESERVE_DIRECT_STAT_NET_R
     ,(A.N_CURRENT_RESERVE_R - (A.N_CURRENT_RESERVE_R * A.N_TOTAL_REINSURANCE_PCT_R)                      )     N_CURRENT_RESERVE_NET_R
     ,(A.N_RESERVE_DIRECT__FIELD__R - (A.N_RESERVE_DIRECT__FIELD__R * A.N_TOTAL_REINSURANCE_PCT_R)        )     N_RESERVE_DIRECT_FIELD_NET_R
     ,(A.N_RESERVE_DIRECT__GAAP__R - (A.N_RESERVE_DIRECT__GAAP__R * (NVL(A.N_TOTAL_REINSURANCE_PCT_R,0)/100))          )     N_RESERVE_DIRECT_GAAP_NET_R -- 24-01-2025 Replace A.N_TOTAL_REINSURANCE_PCT_R to A.N_TOTAL_REINSURANCE_PCT_R/100
     ,(A.N_ORIGINAL_RESERVE_R - (A.N_ORIGINAL_RESERVE_R * A.N_TOTAL_REINSURANCE_PCT_R)                    )     N_ORIGINAL_RESERVE_NET_R
     ,((A.N_RESERVE_DIRECT_BEST_ESTMT_R - A.N_CHG_RSRV_DIRECT_BEST_ESTMT_R) - ((A.N_RESERVE_DIRECT_BEST_ESTMT_R - A.N_CHG_RSRV_DIRECT_BEST_ESTMT_R) * A.N_TOTAL_REINSURANCE_PCT_R))  
      N_PRIOR_RESERVE_DIRECT_BEST_ESTMT_NET_R
     ,((A.N_RESERVE_DIRECT__FIELD__R - A.N_CHG_RESERVE_DIRECT__FIELD__R) - ((A.N_RESERVE_DIRECT__FIELD__R - A.N_CHG_RESERVE_DIRECT__FIELD__R) * A.N_TOTAL_REINSURANCE_PCT_R))       
      N_PRIOR_RESERVE_DIRECT_FIELD_NET_R
     ,((A.N_RESERVE_DIRECT__GAAP__R - A.N_CHG_RESERVE_DIRECT__GAAP__R) - ((A.N_RESERVE_DIRECT__GAAP__R - A.N_CHG_RESERVE_DIRECT__GAAP__R) * A.N_TOTAL_REINSURANCE_PCT_R))           
      N_PRIOR_RESERVE_DIRECT_GAAP_NET_R
     ,((A.N_RESERVE_DIRECT__STAT__R - A.N_CHG_RESERVE_DIRECT__STAT__R) - ((A.N_RESERVE_DIRECT__STAT__R - A.N_CHG_RESERVE_DIRECT__STAT__R) * A.N_TOTAL_REINSURANCE_PCT_R))           
      N_PRIOR_RESERVE_DIRECT_STAT_NET_R
     ,(A.N_RESERVE_DIRECT__STAT__R - (A.N_RESERVE_DIRECT__STAT__R * (NVL(A.N_TOTAL_REINSURANCE_PCT_R,0) /100))                   )                                                            
      N_RESERVE_DIRECT_STAT_NET_R  -- 24-01-2025 -- Replace (A.N_TOTAL_REINSURANCE_PCT_R ) to (A.N_TOTAL_REINSURANCE_PCT_R /100)
     --13/8/24 CHANGES ENDS
	 ,NVL(DIM_GRP_CLAIM_DETAIL_R.N_INSRD_PARTY_SK_R,-1)     N_INSRD_PARTY_SK_R--03/10/24 changes
     ,dim_employee_r.N_EMPLOYEE_SK_R  N_EMPLOYEE_SK_R -- 24-01-2025  AdDED ONE COLUMN 
	 ,A.N_RESERVE_CEDED__GAAP__R N_RESERVE_CEDED_GAAP_R
	 ,A.N_RESERVE_CEDED__STAT__R N_RESERVE_CEDED_STAT_R
     FROM ATOMIC.FCT_LG_RESERVE_DETAILS_R A
     left join ATOMIC.RPT_CLAIM_DTL_R  b
     on a.v_claim_identifier_r = b.v_claim_identifier_r
     --and b.V_RPT_ACTIVE_STATUS_R = &apos;Y&apos;
     and B.N_YEARMONTH_R = LD_MIS_CYCLE_MONTH_R
     left join atomic.mvw_product_sk_lookup  c 
     on c.n_claim_sk_r = b.n_claim_sk_r
     and c.v_claim_coverage_code_r = b.v_claim_coverage_code_r
     left join atomic.dim_grp_policy_dir_r  d
     on a.n_policy_Sk_r = d.n_policy_sk_r
     and d.v_active_status_r = &apos;Y&apos;
     left join atomic.fct_grp_policy_r  e
     on d.n_policy_sk_r = e.n_policy_sk_r
     and d.n_policy_version_number_r = e.n_version_number_r
     --03/10/24 changes starts
	 left join atomic.dim_grp_claim_detail_r  dim_grp_claim_detail_r 
        on b.N_claim_sk_r = dim_grp_claim_detail_r.n_claim_sk_r
        and dim_grp_claim_detail_r.v_active_status_r = &apos;Y&apos;
     --03/10/24 changes ends
      -- 24-01-25 change start
     left join atomic.dim_employee_r  dim_employee_r
      on dim_grp_claim_detail_r.V_EXAMINER_LOGIN_ID_R = dim_employee_r.V_EMPLOYEE_LOGIN_ID_R
      AND dim_employee_r.V_BUSINESS_UNIT_R = &apos;Claims&apos;
     -- 24-01-25 change end
     where a.V_RESERVE_TYPE_IND_R in(&apos;L&apos;,&apos;W&apos;)
     and a.n_claim_sk_r &lt;&gt; -1 AND a.D_RESERVE_VALUATION_DATE_R= LD_MIS_DATE_R;

lc_run_cnt:= SQL%ROWCOUNT;

COMMIT;
	lc_count_type_r:= PKG_GRP_LOG_UTIL.gc_count_type_insert;

    lc_trcmsg:=&apos;3.2 Inserted L and W record into RPT_RESERVE_DETAILS_R for D_RESERVE_VALUATION_DATE_R:-&gt;&apos;||LD_MIS_DATE_R||&apos;and Count&apos;||lc_run_cnt;


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

lc_trcmsg:=&apos;3.3 Capturing Audit Controls for Reserves WAIVER&apos; ;

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

	PRC_GRP_AUDIT_CONTROL_PROCESS (&apos;EDW&apos;,&apos;RESERVES_WAIVER&apos;,&apos;FCT&apos;,&apos;RPT&apos;);

	lc_trcmsg:=&apos;3.4 Capturing Audit Controls for Reserves LTD&apos; ;
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

	PRC_GRP_AUDIT_CONTROL_PROCESS (&apos;EDW&apos;,&apos;RESERVES_LTD&apos;,&apos;FCT&apos;,&apos;RPT&apos;);	


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