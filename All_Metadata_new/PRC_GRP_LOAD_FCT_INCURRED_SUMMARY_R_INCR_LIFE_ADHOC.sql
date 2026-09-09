"PROCEDURE PRC_GRP_LOAD_FCT_INCURRED_SUMMARY_R_INCR_LIFE_ADHOC (
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
	lc_job_name              	    VARCHAR2(100 CHAR) :=&apos;PRC_GRP_LOAD_FCT_INCURRED_SUMMARY_R_INCR_LIFE_ADHOC&apos;;
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


--Created this adhoc procedure to merge FCT_INCURRED_SUMMARY_R
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


execute immediate &apos;TRUNCATE TABLE ATOMIC.TMP_FCT_RPT_CLAIM_SUMMARY_PREV_R&apos;;

lc_run_cnt:= SQL%ROWCOUNT;
    COMMIT;

    lc_trcmsg:=&apos;2 Truncated TMP_FCT_RPT_CLAIM_SUMMARY_PREV_R table :-&gt;&apos;||lc_run_cnt;

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

		lc_trcmsg:=&apos;3 Inserting data into tmp_FCT_RPT_CLAIM_SUMMARY_PREV_R&apos;;		

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

INSERT  INTO ATOMIC.tmp_FCT_RPT_CLAIM_SUMMARY_PREV_R
		select 
		SYSDATE AS D_AS_OF_DATE_R,
		FCS.D_CYCLE_DATE_R,
		nvl(claim.n_policy_sk_r, FCS.n_policy_sk_r),
		nvl(fp.n_cust_party_sk_r,FP2.n_cust_party_sk_r) AS n_party_sk_r,
		trunc(NVL(claim.d_date_of_loss_r,FCS.D_CYCLE_DATE_R),&apos;MM&apos;) AS d_uw_date_r,
		nvl(product_mv.V_BASIC_PRODUCT_LINE_CODE_R, product.V_BASIC_PRODUCT_LINE_CODE_R) AS v_coverage_r,
		nvl(pol_dir.v_policy_prefix_r, pol_dir2.v_policy_prefix_r),
		nvl(pol_dir.v_policy_suffix_r, pol_dir2.v_policy_suffix_r),
		FCS.N_Curr_GAAP_Reserve_Direct_R AS N_CURR_GAAP_OS_DIRECT_AMT_R,
		FCS.N_Curr_Stat_Reserve_Direct_R AS N_CURR_STAT_OS_DIRECT_AMT_R,
		FCS.N_CURR_FIELD_RES_DIRECT_AMT_R AS N_CURR_FIELD_OS_DIRECT_AMT_R,
		FCS.N_CURR_STAT_WV_DIRECT_AMT_R AS N_CURR_STAT_WV_DIRECT_AMT_R, 
		FCS.N_CURR_GAAP_WV_DIRECT_AMT_R AS N_CURR_GAAP_WV_DIRECT_AMT_R, 
		FCS.N_CURR_GAAP_WV_DIRECT_AMT_R AS N_CURR_BE_WV_DIRECT_AMT_R,
		FCS.N_CURR_STAT_WV_DIRECT_AMT_R AS N_CURR_FIELD_WV_DIRECT_AMT_R,
		FCS.N_Prior_GAAP_Reserve_Direct_R AS N_PRIOR_GAAP_OS_DIRECT_AMT_R,
		FCS.N_CHG_GAAP_OS_DIRECT_AMT_R AS N_CHG_GAAP_OS_DIRECT_AMT_R,
		FCS.N_Prior_Stat_Reserve_Direct_R AS N_PRIOR_STAT_OS_DIRECT_AMT_R,
		FCS.N_CHG_STAT_OS_DIRECT_AMT_R AS N_CHG_STAT_OS_DIRECT_AMT_R, 
		FCS.N_PRIOR_BE_DIRECT_AMT_R AS N_PRIOR_BE_OS_DIRECT_AMT_R,
		FCS.N_CHG_BE_RESERVE_DIRECT_AMT_R AS N_CHG_BE_OS_DIRECT_AMT_R,
		FCS.N_CURR_BE_RESERVE_DIRECT_AMT_R AS N_CURR_BE_OS_DIRECT_AMT_R,
		FCS.N_PRIOR_FIELD_RES_DIRECT_AMT_R AS N_PRIOR_FIELD_OS_DIRECT_AMT_R,
		FCS.N_CHG_FIELD_RES_DIRECT_AMT_R AS N_CHG_FIELD_OS_DIRECT_AMT_R,
		FCS.N_PRIOR_GAAP_WV_DIRECT_AMT_R AS N_PRIOR_GAAP_WV_DIRECT_AMT_R,
		FCS.N_CHG_GAAP_WV_DIRECT_AMT_R AS N_CHG_GAAP_WV_DIRECT_AMT_R,
		FCS.N_PRIOR_STAT_WV_DIRECT_AMT_R AS N_PRIOR_STAT_WV_DIRECT_AMT_R,
		FCS.N_CHG_STAT_WV_DIRECT_AMT_R AS N_CHG_STAT_WV_DIRECT_AMT_R,
		FCS.N_PRIOR_GAAP_WV_DIRECT_AMT_R AS N_PRIOR_BE_WV_DIRECT_AMT_R,
		FCS.N_CHG_GAAP_WV_DIRECT_AMT_R AS N_CHG_BE_WV_DIRECT_AMT_R,
		FCS.N_PRIOR_STAT_WV_DIRECT_AMT_R AS N_PRIOR_FIELD_WV_DIRECT_AMT_R,
		FCS.N_CHG_STAT_WV_DIRECT_AMT_R AS N_CHG_FIELD_WV_DIRECT_AMT_R,
		FCS.N_Curr_GAAP_Reserve_Direct_R  *
		(power(1.04, (EXTRACT(YEAR FROM to_date(FCS.D_CYCLE_DATE_R,&apos;DD-MON-YY&apos;)) - EXTRACT(YEAR FROM to_date(NVL(claim.d_date_of_loss_r,FCS.D_CYCLE_DATE_R),&apos;DD-MON-YY&apos;)) )))
		AS N_CURR_GAAP_PV_DIRECT_AMT_R,
		/*N_Curr_GAAP_Reserve_Direct_R * 1.04 ^ ((year(cycle_date) - year (d_date_of_loss_r)) */
		FCS.N_Curr_Stat_Reserve_Direct_R *
		(power(1.04, (EXTRACT(YEAR FROM to_date(FCS.D_CYCLE_DATE_R,&apos;DD-MON-YY&apos;)) - EXTRACT(YEAR FROM to_date(NVL(claim.d_date_of_loss_r,FCS.D_CYCLE_DATE_R),&apos;DD-MON-YY&apos;)) )))
		AS N_CURR_STAT_PV_DIRECT_AMT_R,/* N_Curr_Stat_Reserve_Direct_R,N_Curr_Stat_Reserve_Direct_R * 1.04 ^ ((year(cycle_date) - year (d_date_of_loss_r)) */
		FCS.N_CURR_BE_RESERVE_DIRECT_AMT_R * 
		(power(1.04, (EXTRACT(YEAR FROM to_date(FCS.D_CYCLE_DATE_R,&apos;DD-MON-YY&apos;)) - EXTRACT(YEAR FROM to_date(NVL(claim.d_date_of_loss_r,FCS.D_CYCLE_DATE_R),&apos;DD-MON-YY&apos;)) )))
		AS N_CURR_BE_PV_DIRECT_AMT_R,/*N_CURR_BE_RESERVE_DIRECT_AMT_R * 1.04 ^ ((year(cycle_date) - year (d_date_of_loss_r))*/
		(case when FCS.V_COVERAGE_GROUP_ID_R &lt;&gt; &apos;DF&apos; then FCS.N_TOTAL_CLAIM_COUNT_R else 0 end) AS N_CURR_CLAIM_COUNT_R,
		(case when FCS.V_COVERAGE_GROUP_ID_R &lt;&gt; &apos;DF&apos; then (FCS.N_CHG_Approved_CLAIM_COUNT_R + FCS.N_CHG_PENDING_CLAIM_COUNT_R) else 0 end) AS N_CURR_APPROVED_CLAIM_COUNT_R,
		(case when FCS.V_COVERAGE_GROUP_ID_R &lt;&gt; &apos;DF&apos; then FCS.N_CHG_Closed_CLAIM_COUNT_R else 0 end) AS N_CURR_DENIED_CLAIM_COUNT_R
		,(Case when FCS.v_claim_status_reason_code_r &lt; &apos;60&apos; then FCS.N_CURR_FIELD_RES_DIRECT_AMT_R ELSE 0 end) as N_CURR_OPEN_FIELD_OS_DIRECT_AMT_R,
		product.V_PRODUCT_LINE_R as V_PRODUCT_LINE_R,
		product.V_PRODUCT_SUB_LINE_CODE_R as V_PRODUCT_SUB_LINE_CODE_R, 
		FCS.N_CHG_GAAP_OS_DIRECT_AMT_R * (NVL(cp.N_TOTAL_REINSURANCE_PCT_R,0)/100) as N_CHG_GAAP_OS_CEDED_AMT_R,
		FCS.N_CHG_STAT_OS_DIRECT_AMT_R * (NVL(cp.N_TOTAL_REINSURANCE_PCT_R,0)/100) as N_CHG_STAT_OS_CEDED_AMT_R 
		from  ATOMIC.FCT_RPT_CLAIM_SUMMARY_R   FCS
		LEFT JOIN (select distinct V_CLAIM_NUMBER_R,n_claim_sk_r,N_TOTAL_REINSURANCE_PCT_R,rank() over(partition by n_claim_sk_r order by n_batch_id_r desc)rnk from ATOMIC.FCT_CLAIM_PAYMENT_DETAIL_R) cp
		on FCS.V_CLAIM_NUMBER_R = cp.V_CLAIM_NUMBER_R and FCS.n_claim_sk_r =cp.n_claim_sk_r and rnk=1
		LEFT JOIN (select c.V_CLAIM_NUMBER_R,case when c.v_claim_number_r like &apos;%VAI%&apos; 
		   and c.V_SOURCE_SYSTEM_NAME_R = &apos;PACS&apos; then d.d_date_of_event_r 
		   else c.d_date_of_loss_r end d_date_of_loss_r , n_policy_sk_r, c.n_claim_sk_r
		   from ATOMIC.dim_grp_claim_dir_r  c 
		left join dim_grp_claim_detail_r  d on c.n_claim_sk_r = d.n_claim_sk_r and d.v_active_status_r = &apos;Y&apos;
		where c.v_active_status_r=&apos;Y&apos;) claim
		on FCS.V_CLAIM_NUMBER_R=claim.V_CLAIM_NUMBER_R
		left join (select mvw_product_sk_lookup.*,DIM_GRP_PRODUCT_R.V_BASIC_PRODUCT_LINE_CODE_R from atomic.mvw_product_sk_lookup mvw_product_sk_lookup, ATOMIC.DIM_GRP_PRODUCT_R DIM_GRP_PRODUCT_R
		   where mvw_product_sk_lookup.n_product_sk_r =   DIM_GRP_PRODUCT_R.n_product_sk_r    )product_mv
		on  product_mv.v_claim_number_r = fcs.v_claim_number_r
		   and product_mv.n_claim_sk_r = claim.n_claim_sk_r
		   and product_mv.v_claim_coverage_code_r = fcs.v_coverage_code_r
		LEFT JOIN ( select * from ATOMIC.DIM_GRP_PRODUCT_R) product
		ON FCS.n_product_sk_r=product.n_product_sk_r
		LEFT JOIN (SELECT * FROM ATOMIC.dim_grp_policy_dir_r  WHERE v_active_status_r=&apos;Y&apos; ) pol_dir
		ON claim.N_POLICY_SK_R=pol_dir.N_POLICY_SK_R
		LEFT JOIN (SELECT * FROM ATOMIC.dim_grp_policy_dir_r  WHERE v_active_status_r=&apos;Y&apos; ) pol_dir2
		ON FCS.N_POLICY_SK_R=pol_dir2.N_POLICY_SK_R
		LEFT JOIN (select distinct n_version_number_r,N_POLICY_SK_R,n_cust_party_sk_r from  ATOMIC.fct_grp_policy_r ) FP
		ON FP.n_policy_sk_r= claim.n_policy_sk_r
		AND FP.n_version_number_r=pol_dir.n_policy_version_number_r
		LEFT JOIN (select distinct n_version_number_r,N_POLICY_SK_R,n_cust_party_sk_r from  ATOMIC.fct_grp_policy_r ) FP2
		ON FP2.n_policy_sk_r= FCS.n_policy_sk_r
		AND FP2.n_version_number_r=pol_dir2.n_policy_version_number_r

		where  FCS.D_CYCLE_DATE_R =  LD_MIS_DATE_R
		and FCS.V_POLICY_NUMBER_R is not null;


		lc_run_cnt:= SQL%ROWCOUNT;
    COMMIT;

	lc_count_type_r:= PKG_GRP_LOG_UTIL.gc_count_type_insert;

    lc_trcmsg:=&apos;3.1 Inserted records Count :-&gt;&apos;||lc_run_cnt||&apos;and CYCLE_DATE&apos;||LD_MIS_DATE_R;


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

		lc_trcmsg:=&apos;4 Merging fct_incurred_summary_r table&apos;;		

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



MERGE INTO ATOMIC.FCT_INCURRED_SUMMARY_R TGT
USING (
    SELECT
		D_CYCLE_DATE_R,
        N_POLICY_SK_R,
        N_PARTY_SK_R,
        v_policy_prefix_r,
        v_policy_suffix_r,
        D_UW_DATE_R,
        V_COVERAGE_R,
        N_CURR_GAAP_OS_DIRECT_AMT_R,
		N_CURR_GAAP_PV_DIRECT_AMT_R,
		N_CHG_GAAP_OS_DIRECT_AMT_R,
		N_CHG_GAAP_OS_CEDED_AMT_R,
		N_CURR_STAT_OS_DIRECT_AMT_R,
		N_CURR_STAT_PV_DIRECT_AMT_R,
		NVL(N_CURR_FIELD_OS_DIRECT_AMT_R,N_CURR_STAT_OS_DIRECT_AMT_R) AS N_CURR_FIELD_OS_DIRECT_AMT_R,
		N_CURR_OPEN_FIELD_OS_DIRECT_AMT_R,
		N_CURR_BE_OS_DIRECT_AMT_R,
		N_CURR_BE_PV_DIRECT_AMT_R,
		N_CHG_STAT_OS_DIRECT_AMT_R,
		N_CHG_STAT_OS_CEDED_AMT_R,
		N_CHG_FIELD_OS_DIRECT_AMT_R,
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
		N_PRIOR_BE_WV_DIRECT_AMT_R
    FROM(
			SELECT
			D_CYCLE_DATE_R,
			N_POLICY_SK_R,
			N_PARTY_SK_R,
			v_policy_prefix_r,
			v_policy_suffix_r,
			D_UW_DATE_R,
			V_COVERAGE_R,
			sum(N_CURR_GAAP_OS_DIRECT_AMT_R) AS N_CURR_GAAP_OS_DIRECT_AMT_R,
			sum(N_CURR_GAAP_PV_DIRECT_AMT_R) as N_CURR_GAAP_PV_DIRECT_AMT_R,
			sum(N_CHG_GAAP_OS_DIRECT_AMT_R)as N_CHG_GAAP_OS_DIRECT_AMT_R,
			sum(N_CHG_GAAP_OS_CEDED_AMT_R) as N_CHG_GAAP_OS_CEDED_AMT_R,
			sum(N_CURR_STAT_OS_DIRECT_AMT_R) as N_CURR_STAT_OS_DIRECT_AMT_R,
			sum(N_CURR_STAT_PV_DIRECT_AMT_R) as N_CURR_STAT_PV_DIRECT_AMT_R,
			sum(N_CURR_FIELD_OS_DIRECT_AMT_R) as N_CURR_FIELD_OS_DIRECT_AMT_R,
			sum(N_CURR_OPEN_FIELD_OS_DIRECT_AMT_R) as N_CURR_OPEN_FIELD_OS_DIRECT_AMT_R,
			sum(N_CURR_BE_OS_DIRECT_AMT_R) as N_CURR_BE_OS_DIRECT_AMT_R,
			sum(N_CURR_BE_PV_DIRECT_AMT_R) as N_CURR_BE_PV_DIRECT_AMT_R,
			sum(N_CHG_STAT_OS_DIRECT_AMT_R) as N_CHG_STAT_OS_DIRECT_AMT_R,
			sum(N_CHG_STAT_OS_CEDED_AMT_R) as N_CHG_STAT_OS_CEDED_AMT_R,
			sum(N_CHG_FIELD_OS_DIRECT_AMT_R) as N_CHG_FIELD_OS_DIRECT_AMT_R,
			sum(N_CHG_BE_OS_DIRECT_AMT_R) as N_CHG_BE_OS_DIRECT_AMT_R,
			sum(N_PRIOR_GAAP_OS_DIRECT_AMT_R) as N_PRIOR_GAAP_OS_DIRECT_AMT_R,
			sum(N_PRIOR_STAT_OS_DIRECT_AMT_R) as N_PRIOR_STAT_OS_DIRECT_AMT_R,
			sum(N_PRIOR_FIELD_OS_DIRECT_AMT_R) as N_PRIOR_FIELD_OS_DIRECT_AMT_R,
			sum(N_PRIOR_BE_OS_DIRECT_AMT_R) as N_PRIOR_BE_OS_DIRECT_AMT_R,
			sum(N_CURR_STAT_WV_DIRECT_AMT_R) as N_CURR_STAT_WV_DIRECT_AMT_R,
			sum(N_CURR_FIELD_WV_DIRECT_AMT_R) as N_CURR_FIELD_WV_DIRECT_AMT_R,
			sum(N_CURR_GAAP_WV_DIRECT_AMT_R) as N_CURR_GAAP_WV_DIRECT_AMT_R,
			sum(N_CURR_BE_WV_DIRECT_AMT_R) as N_CURR_BE_WV_DIRECT_AMT_R,
			sum(N_CHG_STAT_WV_DIRECT_AMT_R) as N_CHG_STAT_WV_DIRECT_AMT_R,
			sum(N_CHG_STAT_WV_DIRECT_AMT_R) AS N_CHG_FIELD_WV_DIRECT_AMT_R,
			sum(N_CHG_GAAP_WV_DIRECT_AMT_R) as N_CHG_GAAP_WV_DIRECT_AMT_R,
			sum(N_CHG_GAAP_WV_DIRECT_AMT_R) AS N_CHG_BE_WV_DIRECT_AMT_R,
			sum(N_PRIOR_STAT_WV_DIRECT_AMT_R) as N_PRIOR_STAT_WV_DIRECT_AMT_R,
			sum(N_PRIOR_STAT_WV_DIRECT_AMT_R) AS N_PRIOR_FIELD_WV_DIRECT_AMT_R,
			sum(N_PRIOR_GAAP_WV_DIRECT_AMT_R) as N_PRIOR_GAAP_WV_DIRECT_AMT_R,
			sum(N_PRIOR_GAAP_WV_DIRECT_AMT_R) AS N_PRIOR_BE_WV_DIRECT_AMT_R
            FROM  Atomic.tmp_FCT_RPT_CLAIM_SUMMARY_PREV_R WHERE TO_DATE(D_CYCLE_DATE_R,&apos;DD-MON-YY&apos;) = TO_DATE(LD_MIS_DATE_R,&apos;DD-MON-YY&apos;)
			group by D_CYCLE_DATE_R, N_POLICY_SK_R, N_PARTY_SK_R,v_policy_prefix_r,v_policy_suffix_r,D_UW_DATE_R,V_COVERAGE_R

)) SRC             
ON  
      (TGT.d_cycle_date_r = SRC.d_cycle_date_r
       AND TGT.n_policy_sk_r  = SRC.n_policy_sk_r
       AND TGT.n_party_sk_r   = SRC.n_party_sk_r
       AND TGT.d_uw_date_r    = SRC.d_uw_date_r
       AND TGT.v_coverage_r   = SRC.v_coverage_r
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
		TGT.N_CURR_OPEN_FIELD_OS_DIRECT_AMT_R = SRC.N_CURR_OPEN_FIELD_OS_DIRECT_AMT_R,
		TGT.N_CURR_BE_OS_DIRECT_AMT_R = SRC.N_CURR_BE_OS_DIRECT_AMT_R,
		TGT.N_CURR_BE_PV_DIRECT_AMT_R = SRC.N_CURR_BE_PV_DIRECT_AMT_R,
		TGT.N_CHG_STAT_OS_DIRECT_AMT_R = SRC.N_CHG_STAT_OS_DIRECT_AMT_R,
		TGT.N_CHG_STAT_OS_CEDED_AMT_R = SRC.N_CHG_STAT_OS_CEDED_AMT_R,
		TGT.N_CHG_FIELD_OS_DIRECT_AMT_R = SRC.N_CHG_FIELD_OS_DIRECT_AMT_R,
		TGT.N_CHG_BE_OS_DIRECT_AMT_R = SRC.N_CHG_BE_OS_DIRECT_AMT_R,
		TGT.N_PRIOR_GAAP_OS_DIRECT_AMT_R = SRC.N_PRIOR_GAAP_OS_DIRECT_AMT_R,
		TGT.N_PRIOR_STAT_OS_DIRECT_AMT_R = SRC.N_PRIOR_STAT_OS_DIRECT_AMT_R,
		TGT.N_PRIOR_FIELD_OS_DIRECT_AMT_R = SRC.N_PRIOR_FIELD_OS_DIRECT_AMT_R,
		TGT.N_PRIOR_BE_OS_DIRECT_AMT_R = SRC.N_PRIOR_BE_OS_DIRECT_AMT_R,
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
WHERE TGT.d_cycle_date_r = SRC.d_cycle_date_r
AND TGT.n_policy_sk_r  = SRC.n_policy_sk_r
AND TGT.n_party_sk_r   = SRC.n_party_sk_r
AND TGT.d_uw_date_r    = SRC.d_uw_date_r
AND TGT.v_coverage_r   = SRC.v_coverage_r;

 lc_run_cnt:= SQL%ROWCOUNT;
    COMMIT;

	lc_count_type_r:= PKG_GRP_LOG_UTIL.gc_count_type_merge;

    lc_trcmsg:=&apos;4.1 Merged FCT_INCURRED_SUMMARY_R for D_CYCLE_DATE_R:-&gt;&apos;||LD_MIS_DATE_R||&apos;and Count&apos;||lc_run_cnt;


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