"PACKAGE PKG_GRP_LOAD_FCT_INCURRED_SUMMARY_BEST_ESTIMATE_RESERVES_PREV_MONTH_R AS
--29-Aug-2025: Created package to merge FCT_INCURRED_SUMMARY_R for previous month


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
    gc_main_loadedby VARCHAR2(100 CHAR) := &apos;PKG_GRP_LOAD_FCT_INCURRED_SUMMARY_BEST_ESTIMATE_RESERVES_PREV_MONTH_R.MAIN&apos;;
    gc_job_name VARCHAR2(100 CHAR) := &apos;GRP_LOAD_FCT_INCURRED_SUMMARY_BEST_ESTIMATE_RESERVES_PREV_MONTH_R&apos;;
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
--Procedure to load TMP_FCT_RPT_CLAIM_SUMMARY_PREV_R table for Previous month
    PROCEDURE PRC_GRP_LOAD_TMP_FCT_RPT_CLAIM_SUMMARY_PREV_R;
--Procedure to merge FCT_INCURRED_SUMMARY_R table for Previous month	
	PROCEDURE PRC_GRP_LOAD_FCT_INCURRED_SUMMARY_BEST_ESTIMATE_RESERVES_PREV_MONTH_R;


END PKG_GRP_LOAD_FCT_INCURRED_SUMMARY_BEST_ESTIMATE_RESERVES_PREV_MONTH_R;PACKAGE BODY PKG_GRP_LOAD_FCT_INCURRED_SUMMARY_BEST_ESTIMATE_RESERVES_PREV_MONTH_R AS
/***********************************************************************
  Purpose:  This package body contains procedures which Merge data into FCT_INCURRED_SUMMARY_R


  Author           Date     Description
  ---------- -------- -------------------------------------------------
  Anantha Jothi   28/08/25 Initial Creation

  ***********************************************************************/

  --Main Procedure
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

	gc_trcmsg:=&apos;1.3 Call Procedure PRC_GRP_LOAD_TMP_FCT_RPT_CLAIM_SUMMARY_PREV_R&apos;;	
	PKG_GRP_LOAD_FCT_INCURRED_SUMMARY_BEST_ESTIMATE_RESERVES_PREV_MONTH_R.PRC_GRP_LOAD_TMP_FCT_RPT_CLAIM_SUMMARY_PREV_R;

  gc_trcmsg:=&apos;1.4 Completed Procedure PRC_GRP_LOAD_TMP_FCT_RPT_CLAIM_SUMMARY_PREV_R&apos;;

  gc_trcmsg:=&apos;1.5 Call Procedure PRC_GRP_LOAD_FCT_INCURRED_SUMMARY_BEST_ESTIMATE_RESERVES_PREV_MONTH_R&apos;;	
	PKG_GRP_LOAD_FCT_INCURRED_SUMMARY_BEST_ESTIMATE_RESERVES_PREV_MONTH_R.PRC_GRP_LOAD_FCT_INCURRED_SUMMARY_BEST_ESTIMATE_RESERVES_PREV_MONTH_R;

  gc_trcmsg:=&apos;1.6 Completed Procedure PRC_GRP_LOAD_FCT_INCURRED_SUMMARY_BEST_ESTIMATE_RESERVES_PREV_MONTH_R&apos;;



	gc_trcmsg:=&apos;1.7 Exit from main&apos;;
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

--Procedure to load TMP_FCT_RPT_CLAIM_SUMMARY_PREV_R table for Previous month
  PROCEDURE PRC_GRP_LOAD_TMP_FCT_RPT_CLAIM_SUMMARY_PREV_R IS

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



execute immediate &apos;TRUNCATE TABLE ATOMIC.TMP_FCT_RPT_CLAIM_SUMMARY_PREV_R&apos;;

lc_run_cnt:= SQL%ROWCOUNT;
    COMMIT;

    gc_trcmsg:=&apos;1 Truncated TMP_FCT_RPT_CLAIM_SUMMARY_PREV_R table :-&gt;&apos;||lc_run_cnt;

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


lt_start_time_r:= SYSTIMESTAMP;

		gc_trcmsg:=&apos;2.Inserting data into tmp_FCT_RPT_CLAIM_SUMMARY_PREV_R&apos;;		

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

INSERT  INTO ATOMIC.tmp_FCT_RPT_CLAIM_SUMMARY_PREV_R
		select 
		gd_SYSDATE AS D_AS_OF_DATE_R,
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
		   from ATOMIC.dim_grp_claim_dir_r   c 
		left join dim_grp_claim_detail_r   d on c.n_claim_sk_r = d.n_claim_sk_r and d.v_active_status_r = &apos;Y&apos;
		where c.v_active_status_r=&apos;Y&apos;) claim
		on FCS.V_CLAIM_NUMBER_R=claim.V_CLAIM_NUMBER_R
		left join (select mvw_product_sk_lookup.*,DIM_GRP_PRODUCT_R.V_BASIC_PRODUCT_LINE_CODE_R from atomic.mvw_product_sk_lookup  mvw_product_sk_lookup, ATOMIC.DIM_GRP_PRODUCT_R DIM_GRP_PRODUCT_R
		   where mvw_product_sk_lookup.n_product_sk_r =   DIM_GRP_PRODUCT_R.n_product_sk_r    )product_mv
		on  product_mv.v_claim_number_r = fcs.v_claim_number_r
		   and product_mv.n_claim_sk_r = claim.n_claim_sk_r
		   and product_mv.v_claim_coverage_code_r = fcs.v_coverage_code_r
		LEFT JOIN ( select * from ATOMIC.DIM_GRP_PRODUCT_R) product
		ON FCS.n_product_sk_r=product.n_product_sk_r
		LEFT JOIN (SELECT * FROM ATOMIC.dim_grp_policy_dir_r   WHERE v_active_status_r=&apos;Y&apos; ) pol_dir
		ON claim.N_POLICY_SK_R=pol_dir.N_POLICY_SK_R
		LEFT JOIN (SELECT * FROM ATOMIC.dim_grp_policy_dir_r   WHERE v_active_status_r=&apos;Y&apos; ) pol_dir2
		ON FCS.N_POLICY_SK_R=pol_dir2.N_POLICY_SK_R
		LEFT JOIN (select distinct n_version_number_r,N_POLICY_SK_R,n_cust_party_sk_r from  ATOMIC.fct_grp_policy_r  ) FP
		ON FP.n_policy_sk_r= claim.n_policy_sk_r
		AND FP.n_version_number_r=pol_dir.n_policy_version_number_r
		LEFT JOIN (select distinct n_version_number_r,N_POLICY_SK_R,n_cust_party_sk_r from  ATOMIC.fct_grp_policy_r  ) FP2
		ON FP2.n_policy_sk_r= FCS.n_policy_sk_r
		AND FP2.n_version_number_r=pol_dir2.n_policy_version_number_r

		where  FCS.D_CYCLE_DATE_R =  gd_mis_cycle_date_r
		and FCS.V_POLICY_NUMBER_R is not null;


		lc_run_cnt:= SQL%ROWCOUNT;
    COMMIT;

	lc_count_type_r:= PKG_GRP_LOG_UTIL.gc_count_type_insert;

    gc_trcmsg:=&apos;2.1 Inserted records and cycle_date :-&gt;&apos;||lc_run_cnt||gd_mis_cycle_date_r;


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

	END PRC_GRP_LOAD_TMP_FCT_RPT_CLAIM_SUMMARY_PREV_R;

--Procedure to merge FCT_INCURRED_SUMMARY_R table for Previous month	

PROCEDURE PRC_GRP_LOAD_FCT_INCURRED_SUMMARY_BEST_ESTIMATE_RESERVES_PREV_MONTH_R IS

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

		gc_trcmsg:=&apos;1.Entered into prc_merge_data for fct_incurred_summary_r table for previous month&apos;;		

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
		N_PRIOR_BE_OS_DIRECT_AMT_R
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
			sum(N_PRIOR_BE_OS_DIRECT_AMT_R) as N_PRIOR_BE_OS_DIRECT_AMT_R
            FROM  Atomic.tmp_FCT_RPT_CLAIM_SUMMARY_PREV_R WHERE TO_DATE(D_CYCLE_DATE_R,&apos;DD-MON-YY&apos;) = TO_DATE(gd_mis_cycle_date_r,&apos;DD-MON-YY&apos;)
			group by D_CYCLE_DATE_R, N_POLICY_SK_R, N_PARTY_SK_R,v_policy_prefix_r,v_policy_suffix_r,D_UW_DATE_R,V_COVERAGE_R

)) SRC             
ON  
      (TGT.d_cycle_date_r = SRC.d_cycle_date_r
       AND TGT.n_policy_sk_r  = SRC.n_policy_sk_r
       AND TGT.n_party_sk_r   = SRC.n_party_sk_r
       AND TGT.d_uw_date_r    = SRC.d_uw_date_r
       AND TGT.v_coverage_r   = SRC.v_coverage_r
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
		TGT.N_PRIOR_BE_OS_DIRECT_AMT_R = SRC.N_PRIOR_BE_OS_DIRECT_AMT_R
WHERE TGT.d_cycle_date_r = SRC.d_cycle_date_r
AND TGT.n_policy_sk_r  = SRC.n_policy_sk_r
AND TGT.n_party_sk_r   = SRC.n_party_sk_r
AND TGT.d_uw_date_r    = SRC.d_uw_date_r
AND TGT.v_coverage_r   = SRC.v_coverage_r;

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

END PRC_GRP_LOAD_FCT_INCURRED_SUMMARY_BEST_ESTIMATE_RESERVES_PREV_MONTH_R;

END PKG_GRP_LOAD_FCT_INCURRED_SUMMARY_BEST_ESTIMATE_RESERVES_PREV_MONTH_R;"