"PACKAGE PKG_GRP_LOAD_RPT_RESERVE_DETAILS_BEST_ESTIMATE_RESERVES_PREV_MONTH_R AS
--16-Sep-2025: Created package to merge RPT_RESERVE_DETAILS_R for previous month


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
    gc_main_loadedby VARCHAR2(100 CHAR) := &apos;PKG_GRP_LOAD_RPT_RESERVE_DETAILS_BEST_ESTIMATE_RESERVES_PREV_MONTH_R.MAIN&apos;;
    gc_job_name VARCHAR2(100 CHAR) := &apos;GRP_LOAD_RPT_RESERVE_DETAILS_BEST_ESTIMATE_RESERVES_PREV_MONTH_R&apos;;
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
--Procedure to merge RPT_RESERVE_DETAILS_R table for Previous month 	
    PROCEDURE PRC_GRP_LOAD_RPT_RESERVE_DETAILS_BEST_ESTIMATE_RESERVES_PREV_MONTH_R;


END PKG_GRP_LOAD_RPT_RESERVE_DETAILS_BEST_ESTIMATE_RESERVES_PREV_MONTH_R;PACKAGE BODY PKG_GRP_LOAD_RPT_RESERVE_DETAILS_BEST_ESTIMATE_RESERVES_PREV_MONTH_R AS
/***********************************************************************
  Purpose:  This package body contains procedures which merge data into RPT_RESERVE_DETAILS_R


  Author           Date     Description
  ---------- -------- -------------------------------------------------
  Anantha Jothi   16/09/25 Initial Creation
  Anantha Jothi   24/09/25 Added Max function for all columns 
  Anantha Jothi   07/11/25 Added Insert when not matched
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

	gc_trcmsg:=&apos;1.1 Call utility package function to get gd_mis_cycle_date_r&apos;;

	gd_mis_cycle_date_r := PKG_GRP_RESERVE_UTIL.get_cycle_date_best_estimate_r;  

	gc_trcmsg:=&apos;1.2 Completed package PKG_GRP_RESERVE_UTIL&apos;;

	gc_trcmsg:=&apos;1.3 Call Procedure PRC_GRP_LOAD_RPT_RESERVE_DETAILS_BEST_ESTIMATE_RESERVES_PREV_MONTH_R&apos;;	
	PKG_GRP_LOAD_RPT_RESERVE_DETAILS_BEST_ESTIMATE_RESERVES_PREV_MONTH_R.PRC_GRP_LOAD_RPT_RESERVE_DETAILS_BEST_ESTIMATE_RESERVES_PREV_MONTH_R;

  gc_trcmsg:=&apos;1.4 Completed Procedure PRC_GRP_LOAD_RPT_RESERVE_DETAILS_BEST_ESTIMATE_RESERVES_PREV_MONTH_R&apos;;




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


--Procedure to merge RPT_RESERVE_DETAILS_R table for Previous month  
  PROCEDURE PRC_GRP_LOAD_RPT_RESERVE_DETAILS_BEST_ESTIMATE_RESERVES_PREV_MONTH_R IS

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

	Update Atomic.RPT_RESERVE_DETAILS_R set 
			 N_GROSS_BENEFIT_R = NULL
		,N_CHECK_NET_BENEFIT_R = NULL
		,N_RESERVE_DIRECT_BEST_ESTMT_R = NULL
		,N_PRIOR_RESERVE_DIRECT_BEST_ESTMT_R = NULL
		,N_RESERVE_DIRECT_BEST_ESTMT_CEDED_R = NULL
		,N_PRIOR_RESERVE_DIRECT_BEST_ESTMT_CEDED_R = NULL
		,N_RESERVE_DIRECT_BEST_ESTMT_NET_R = NULL
		,N_PRIOR_RESERVE_DIRECT_BEST_ESTMT_NET_R = NULL
		,N_CHG_RSRV_DIRECT_BEST_ESTMT_R = NULL
		,N_CHG_RSRV_DIRECT_BEST_ESTMT_CEDED_R = NULL
		,N_CHG_RSRV_DIRECT_BEST_ESTMT_NET_R = NULL
		,N_BEST_ESTIMATE_NET_BENEFIT_R = NULL
		,V_BEST_ESTMT_RESERVE_MODEL_R = NULL
		,N_RESERVE_DIRECT_FIELD_R = NULL
		,N_PRIOR_RESERVE_DIRECT_FIELD_R = NULL
		,N_RESERVE_DIRECT_FIELD_CEDED_R = NULL
		,N_PRIOR_RESERVE_DIRECT_FIELD_CEDED_R = NULL
		,N_RESERVE_DIRECT_FIELD_NET_R = NULL
		,N_PRIOR_RESERVE_DIRECT_FIELD_NET_R = NULL
		,N_CHG_RESERVE_DIRECT_FIELD_R = NULL
		,N_CHG_RESERVE_DIRECT_FIELD_CEDED_R = NULL
		,N_CHG_RESERVE_DIRECT_FIELD_NET_R = NULL
		where V_RESERVE_TYPE_IND_R not in ( &apos;I&apos;, &apos;P&apos;) and n_claim_sk_r &lt;&gt; -1 AND D_RESERVE_VALUATION_DATE_R = gd_mis_cycle_date_r;

lc_run_cnt:= SQL%ROWCOUNT;
COMMIT;


		lc_count_type_r:= PKG_GRP_LOG_UTIL.gc_count_type_update;
		gC_TRCMSG:= &apos;1 Updated data in RPT_RESERVE_DETAILS_R record count and Cycle_Date :-&gt;&apos;||lc_run_cnt||&apos;-&apos;||gd_mis_cycle_date_r;


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

		gc_trcmsg:=&apos;2 Entered into prc to merge data for RPT_RESERVE_DETAILS_R table for previous month :-&gt;&apos;||gd_mis_cycle_date_r;		

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
	MERGE INTO  ATOMIC.RPT_RESERVE_DETAILS_R TGT
USING (
    SELECT 

		 N_GROSS_BENEFIT_R
		,N_CHECK_NET_BENEFIT_R
		,N_RESERVE_DIRECT_BEST_ESTMT_R
		,N_PRIOR_RESERVE_DIRECT_BEST_ESTMT_R
		,N_RESERVE_DIRECT_BEST_ESTMT_CEDED_R
		,N_PRIOR_RESERVE_DIRECT_BEST_ESTMT_CEDED_R
		,N_RESERVE_DIRECT_BEST_ESTMT_NET_R
		,N_PRIOR_RESERVE_DIRECT_BEST_ESTMT_NET_R
		,N_CHG_RSRV_DIRECT_BEST_ESTMT_R
		,N_CHG_RSRV_DIRECT_BEST_ESTMT_CEDED_R
		,N_CHG_RSRV_DIRECT_BEST_ESTMT_NET_R
		,N_BEST_ESTIMATE_NET_BENEFIT_R
		,V_BEST_ESTMT_RESERVE_MODEL_R
		,N_RESERVE_DIRECT_FIELD_R
		,N_PRIOR_RESERVE_DIRECT_FIELD_R
		,N_RESERVE_DIRECT_FIELD_CEDED_R
		,N_PRIOR_RESERVE_DIRECT_FIELD_CEDED_R
		,N_RESERVE_DIRECT_FIELD_NET_R
		,N_PRIOR_RESERVE_DIRECT_FIELD_NET_R
		,N_CHG_RESERVE_DIRECT_FIELD_R
		,N_CHG_RESERVE_DIRECT_FIELD_CEDED_R
		,N_CHG_RESERVE_DIRECT_FIELD_NET_R
		--,V_COVERAGE_CODE_R
		--,V_CLAIM_IDENTIFIER_R
		,n_claim_sk_r
		,N_CUST_PARTY_SK_R
		,n_policy_sk_r
		,n_claim_coverage_sk_r
		,N_CLAIM_COVERAGE_GROUP_Sk_R
		,N_PRODUCT_SK_R
		,D_RESERVE_VALUATION_DATE_R
		,V_RESERVE_TYPE_IND_R
		,N_INSRD_PARTY_SK_R
		,N_EMPLOYEE_SK_R
		,V_PRIMARY_REINSURER_R
	    ,V_SECONDARY_REINSURER_R
	    ,V_TERNARY_REINSURER_R
	    ,N_PRIMARY_REINSURER_REINS_SHARE_PCT_R
	    ,N_SECONDARY_REINSURER_REINS_SHARE_PCT_R
	    ,N_TERNARY_REINSURER_REINS_SHARE_PCT_R
	    ,N_PRIMARY_REINSURER_REINSURANCE_PCT_R
	    ,N_SECONDARY_REINSURER_REINSURANCE_PCT_R
	    ,N_TERNARY_REINSURER_REINSURANCE_PCT_R
	    ,N_TOTAL_REINSURANCE_PCT_R

	FROM(

			SELECT  distinct

				 MAX(A.N_GROSS_BENEFIT_R) AS N_GROSS_BENEFIT_R
				,MAX(A.N_CHECK_NET_BENEFIT_R) AS N_CHECK_NET_BENEFIT_R
				,MAX(NVL(A.N_RESERVE_DIRECT_BEST_ESTMT_R,A.N_RESERVE_DIRECT__GAAP__R)) AS N_RESERVE_DIRECT_BEST_ESTMT_R
				,MAX((A.N_RESERVE_DIRECT_BEST_ESTMT_R - A.N_CHG_RSRV_DIRECT_BEST_ESTMT_R)) AS N_PRIOR_RESERVE_DIRECT_BEST_ESTMT_R
				,MAX((A.N_RESERVE_DIRECT_BEST_ESTMT_R  * A.N_TOTAL_REINSURANCE_PCT_R)) AS     N_RESERVE_DIRECT_BEST_ESTMT_CEDED_R
				,MAX(((A.N_RESERVE_DIRECT_BEST_ESTMT_R - A.N_CHG_RSRV_DIRECT_BEST_ESTMT_R) * A.N_TOTAL_REINSURANCE_PCT_R)) AS    N_PRIOR_RESERVE_DIRECT_BEST_ESTMT_CEDED_R
				,MAX((A.N_RESERVE_DIRECT_BEST_ESTMT_R - (A.N_RESERVE_DIRECT_BEST_ESTMT_R * A.N_TOTAL_REINSURANCE_PCT_R))) AS     N_RESERVE_DIRECT_BEST_ESTMT_NET_R 
				,MAX(((A.N_RESERVE_DIRECT_BEST_ESTMT_R - A.N_CHG_RSRV_DIRECT_BEST_ESTMT_R) - ((A.N_RESERVE_DIRECT_BEST_ESTMT_R - A.N_CHG_RSRV_DIRECT_BEST_ESTMT_R) * A.N_TOTAL_REINSURANCE_PCT_R)) ) AS  N_PRIOR_RESERVE_DIRECT_BEST_ESTMT_NET_R
				,MAX(A.N_CHG_RSRV_DIRECT_BEST_ESTMT_R) AS N_CHG_RSRV_DIRECT_BEST_ESTMT_R
				,MAX((A.N_CHG_RSRV_DIRECT_BEST_ESTMT_R * A.N_TOTAL_REINSURANCE_PCT_R)) AS   N_CHG_RSRV_DIRECT_BEST_ESTMT_CEDED_R
				,MAX((A.N_CHG_RSRV_DIRECT_BEST_ESTMT_R - (A.N_CHG_RSRV_DIRECT_BEST_ESTMT_R * A.N_TOTAL_REINSURANCE_PCT_R)) ) AS    N_CHG_RSRV_DIRECT_BEST_ESTMT_NET_R
				,MAX(A.N_BEST_ESTIMATE_NET_BENEFIT_R) AS N_BEST_ESTIMATE_NET_BENEFIT_R
				,MAX(A.V_BEST_ESTMT_RESERVE_MODEL_R) AS V_BEST_ESTMT_RESERVE_MODEL_R
				,MAX(A.N_RESERVE_DIRECT__FIELD__R) AS N_RESERVE_DIRECT_FIELD_R
				,MAX((A.N_RESERVE_DIRECT__FIELD__R    - A.N_CHG_RESERVE_DIRECT__FIELD__R)) AS N_PRIOR_RESERVE_DIRECT_FIELD_R
				,MAX((A.N_RESERVE_DIRECT__FIELD__R     * A.N_TOTAL_REINSURANCE_PCT_R)) AS    N_RESERVE_DIRECT_FIELD_CEDED_R
				,MAX(((A.N_RESERVE_DIRECT__FIELD__R - A.N_CHG_RESERVE_DIRECT__FIELD__R) * A.N_TOTAL_REINSURANCE_PCT_R))  AS   N_PRIOR_RESERVE_DIRECT_FIELD_CEDED_R
				,MAX(A.N_RESERVE_DIRECT__FIELD__R - (A.N_RESERVE_DIRECT__FIELD__R * A.N_TOTAL_REINSURANCE_PCT_R))  AS N_RESERVE_DIRECT_FIELD_NET_R
				,MAX(((A.N_RESERVE_DIRECT__FIELD__R - A.N_CHG_RESERVE_DIRECT__FIELD__R) - ((A.N_RESERVE_DIRECT__FIELD__R - A.N_CHG_RESERVE_DIRECT__FIELD__R) * A.N_TOTAL_REINSURANCE_PCT_R))) AS N_PRIOR_RESERVE_DIRECT_FIELD_NET_R
				,MAX(A.N_CHG_RESERVE_DIRECT__FIELD__R) as N_CHG_RESERVE_DIRECT_FIELD_R
				,MAX((A.N_CHG_RESERVE_DIRECT__FIELD__R * A.N_TOTAL_REINSURANCE_PCT_R) ) AS    N_CHG_RESERVE_DIRECT_FIELD_CEDED_R
				,MAX((A.N_CHG_RESERVE_DIRECT__FIELD__R - (A.N_CHG_RESERVE_DIRECT__FIELD__R * A.N_TOTAL_REINSURANCE_PCT_R)) ) AS    N_CHG_RESERVE_DIRECT_FIELD_NET_R
				--,V_COVERAGE_CODE_R
				--,a.V_CLAIM_IDENTIFIER_R									
				,A.D_RESERVE_VALUATION_DATE_R
				,a.N_POLICY_SK_R
				,a.N_CLAIM_SK_R
				,A.V_RESERVE_TYPE_IND_R
				,nvl(e.N_CUST_PARTY_SK_R,-1) N_CUST_PARTY_SK_R				
				,nvl(b.n_claim_coverage_sk_r,-1) n_claim_coverage_sk_r
				,nvl(B.N_CLAIM_COVERAGE_GROUP_Sk_R,-1) N_CLAIM_COVERAGE_GROUP_Sk_R
				,c.N_PRODUCT_SK_R
				,NVL(DIM_GRP_CLAIM_DETAIL_R.N_INSRD_PARTY_SK_R,-1)     N_INSRD_PARTY_SK_R
				,dim_employee_r.N_EMPLOYEE_SK_R  N_EMPLOYEE_SK_R
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
				FROM ATOMIC.FCT_LG_RESERVE_DETAILS_R A
				left join ATOMIC.rpt_claim_dtl_r b
				on a.v_claim_identifier_r = b.v_claim_identifier_r
				and B.N_YEARMONTH_R = to_number(TO_CHAR(D_RESERVE_VALUATION_DATE_R,&apos;YYYYMM&apos;))
				left join mvw_product_sk_lookup c 
				on c.n_claim_sk_r = b.n_claim_sk_r
				and c.v_claim_coverage_code_r = b.v_claim_coverage_code_r
				left join ATOMIC.dim_grp_policy_dir_r d
				on a.n_policy_Sk_r = d.n_policy_sk_r
				and d.v_active_status_r = &apos;Y&apos;
				left join ATOMIC.fct_grp_policy_r e
				on d.n_policy_sk_r = e.n_policy_sk_r
				and d.n_policy_version_number_r = e.n_version_number_r
				left join ATOMIC.dim_grp_claim_detail_r dim_grp_claim_detail_r 
					on b.N_claim_sk_r = dim_grp_claim_detail_r.n_claim_sk_r
					and dim_grp_claim_detail_r.v_active_status_r = &apos;Y&apos;
				left join ATOMIC.dim_employee_r dim_employee_r
				on dim_grp_claim_detail_r.V_EXAMINER_LOGIN_ID_R = dim_employee_r.V_EMPLOYEE_LOGIN_ID_R
				AND dim_employee_r.V_BUSINESS_UNIT_R = &apos;Claims&apos;
				where a.V_RESERVE_TYPE_IND_R not in ( &apos;I&apos;, &apos;P&apos;)
				and a.n_claim_sk_r &lt;&gt; -1
				and D_RESERVE_VALUATION_DATE_R=gd_mis_cycle_date_r
				GROUP BY A.D_RESERVE_VALUATION_DATE_R
				,a.N_POLICY_SK_R
				,a.N_CLAIM_SK_R
				,A.V_RESERVE_TYPE_IND_R
				,nvl(e.N_CUST_PARTY_SK_R,-1) 				
				,nvl(b.n_claim_coverage_sk_r,-1) 
				,nvl(B.N_CLAIM_COVERAGE_GROUP_Sk_R,-1) 
				,c.N_PRODUCT_SK_R
				,NVL(DIM_GRP_CLAIM_DETAIL_R.N_INSRD_PARTY_SK_R,-1)     
				,dim_employee_r.N_EMPLOYEE_SK_R  
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


		))SRC



ON 
    (TGT.N_POLICY_SK_R = SRC.N_POLICY_SK_R
	AND TGT.V_RESERVE_TYPE_IND_R= SRC.V_RESERVE_TYPE_IND_R
	AND TGT.D_RESERVE_VALUATION_DATE_R= SRC.D_RESERVE_VALUATION_DATE_R
	AND TGT.n_claim_sk_r=SRC.n_claim_sk_r
    AND TGT.N_CUST_PARTY_SK_R = SRC.N_CUST_PARTY_SK_R
	AND TGT.n_claim_coverage_sk_r = SRC.n_claim_coverage_sk_r
	AND TGT.n_claim_coverage_group_sk_r = SRC.n_claim_coverage_group_sk_r)	

WHEN MATCHED THEN 
    UPDATE SET  
		 TGT.N_GROSS_BENEFIT_R = SRC.N_GROSS_BENEFIT_R
		,TGT.N_CHECK_NET_BENEFIT_R = SRC.N_CHECK_NET_BENEFIT_R
		,TGT.N_RESERVE_DIRECT_BEST_ESTMT_R = SRC.N_RESERVE_DIRECT_BEST_ESTMT_R
		,TGT.N_PRIOR_RESERVE_DIRECT_BEST_ESTMT_R = SRC.N_PRIOR_RESERVE_DIRECT_BEST_ESTMT_R
		,TGT.N_RESERVE_DIRECT_BEST_ESTMT_CEDED_R = SRC.N_RESERVE_DIRECT_BEST_ESTMT_CEDED_R
		,TGT.N_PRIOR_RESERVE_DIRECT_BEST_ESTMT_CEDED_R = SRC.N_PRIOR_RESERVE_DIRECT_BEST_ESTMT_CEDED_R
		,TGT.N_RESERVE_DIRECT_BEST_ESTMT_NET_R = SRC.N_RESERVE_DIRECT_BEST_ESTMT_NET_R
		,TGT.N_PRIOR_RESERVE_DIRECT_BEST_ESTMT_NET_R = SRC.N_PRIOR_RESERVE_DIRECT_BEST_ESTMT_NET_R
		,TGT.N_CHG_RSRV_DIRECT_BEST_ESTMT_R = SRC.N_CHG_RSRV_DIRECT_BEST_ESTMT_R
		,TGT.N_CHG_RSRV_DIRECT_BEST_ESTMT_CEDED_R = SRC.N_CHG_RSRV_DIRECT_BEST_ESTMT_CEDED_R
		,TGT.N_CHG_RSRV_DIRECT_BEST_ESTMT_NET_R = SRC.N_CHG_RSRV_DIRECT_BEST_ESTMT_NET_R
		,TGT.N_BEST_ESTIMATE_NET_BENEFIT_R = SRC.N_BEST_ESTIMATE_NET_BENEFIT_R
		,TGT.V_BEST_ESTMT_RESERVE_MODEL_R = SRC.V_BEST_ESTMT_RESERVE_MODEL_R
		,TGT.N_RESERVE_DIRECT_FIELD_R = SRC.N_RESERVE_DIRECT_FIELD_R
		,TGT.N_PRIOR_RESERVE_DIRECT_FIELD_R = SRC.N_PRIOR_RESERVE_DIRECT_FIELD_R
		,TGT.N_RESERVE_DIRECT_FIELD_CEDED_R = SRC.N_RESERVE_DIRECT_FIELD_CEDED_R
		,TGT.N_PRIOR_RESERVE_DIRECT_FIELD_CEDED_R = SRC.N_PRIOR_RESERVE_DIRECT_FIELD_CEDED_R
		,TGT.N_RESERVE_DIRECT_FIELD_NET_R = SRC.N_RESERVE_DIRECT_FIELD_NET_R
		,TGT.N_PRIOR_RESERVE_DIRECT_FIELD_NET_R = SRC.N_PRIOR_RESERVE_DIRECT_FIELD_NET_R
		,TGT.N_CHG_RESERVE_DIRECT_FIELD_R = SRC.N_CHG_RESERVE_DIRECT_FIELD_R
		,TGT.N_CHG_RESERVE_DIRECT_FIELD_CEDED_R = SRC.N_CHG_RESERVE_DIRECT_FIELD_CEDED_R
		,TGT.N_CHG_RESERVE_DIRECT_FIELD_NET_R = SRC.N_CHG_RESERVE_DIRECT_FIELD_NET_R


WHERE TGT.N_POLICY_SK_R = SRC.N_POLICY_SK_R
	AND TGT.V_RESERVE_TYPE_IND_R= SRC.V_RESERVE_TYPE_IND_R
	AND TGT.D_RESERVE_VALUATION_DATE_R= SRC.D_RESERVE_VALUATION_DATE_R
	AND TGT.n_claim_sk_r = SRC.n_claim_sk_r
    AND TGT.N_CUST_PARTY_SK_R = SRC.N_CUST_PARTY_SK_R
	AND TGT.n_claim_coverage_sk_r = SRC.n_claim_coverage_sk_r
	AND TGT.n_claim_coverage_group_sk_r = SRC.n_claim_coverage_group_sk_r

WHEN NOT MATCHED THEN
	INSERT (N_GROSS_BENEFIT_R,N_CHECK_NET_BENEFIT_R,N_RESERVE_DIRECT_BEST_ESTMT_R,N_PRIOR_RESERVE_DIRECT_BEST_ESTMT_R,N_RESERVE_DIRECT_BEST_ESTMT_CEDED_R
,N_PRIOR_RESERVE_DIRECT_BEST_ESTMT_CEDED_R,N_RESERVE_DIRECT_BEST_ESTMT_NET_R,N_PRIOR_RESERVE_DIRECT_BEST_ESTMT_NET_R,N_CHG_RSRV_DIRECT_BEST_ESTMT_R
,N_CHG_RSRV_DIRECT_BEST_ESTMT_CEDED_R,N_CHG_RSRV_DIRECT_BEST_ESTMT_NET_R,N_BEST_ESTIMATE_NET_BENEFIT_R,V_BEST_ESTMT_RESERVE_MODEL_R
,N_RESERVE_DIRECT_FIELD_R,N_PRIOR_RESERVE_DIRECT_FIELD_R,N_RESERVE_DIRECT_FIELD_CEDED_R,N_PRIOR_RESERVE_DIRECT_FIELD_CEDED_R,N_RESERVE_DIRECT_FIELD_NET_R
,N_PRIOR_RESERVE_DIRECT_FIELD_NET_R,N_CHG_RESERVE_DIRECT_FIELD_R,N_CHG_RESERVE_DIRECT_FIELD_CEDED_R,N_CHG_RESERVE_DIRECT_FIELD_NET_R,n_claim_sk_r
,N_CUST_PARTY_SK_R,n_policy_sk_r,n_claim_coverage_sk_r,N_CLAIM_COVERAGE_GROUP_Sk_R,N_PRODUCT_SK_R,D_RESERVE_VALUATION_DATE_R,V_RESERVE_TYPE_IND_R
,V_LAST_MODIFIED_BY_R,T_CREATION_DATE_R,V_CREATED_BY_R,T_LAST_MODIFIED_DATE_R,V_RPT_ACTIVE_STATUS_R,N_BATCH_ID_R,N_REPORTMONTH_R,V_PRIMARY_REINSURER_R
,V_SECONDARY_REINSURER_R,V_TERNARY_REINSURER_R,N_PRIMARY_REINSURER_REINS_SHARE_PCT_R,N_SECONDARY_REINSURER_REINS_SHARE_PCT_R,
N_TERNARY_REINSURER_REINS_SHARE_PCT_R,N_PRIMARY_REINSURER_REINSURANCE_PCT_R,N_SECONDARY_REINSURER_REINSURANCE_PCT_R
,N_TERNARY_REINSURER_REINSURANCE_PCT_R,N_TOTAL_REINSURANCE_PCT_R,N_INSRD_PARTY_SK_R,N_EMPLOYEE_SK_R)

	VALUES (SRC.N_GROSS_BENEFIT_R,SRC.N_CHECK_NET_BENEFIT_R,SRC.N_RESERVE_DIRECT_BEST_ESTMT_R,SRC.N_PRIOR_RESERVE_DIRECT_BEST_ESTMT_R
,SRC.N_RESERVE_DIRECT_BEST_ESTMT_CEDED_R,SRC.N_PRIOR_RESERVE_DIRECT_BEST_ESTMT_CEDED_R,SRC.N_RESERVE_DIRECT_BEST_ESTMT_NET_R
,SRC.N_PRIOR_RESERVE_DIRECT_BEST_ESTMT_NET_R,SRC.N_CHG_RSRV_DIRECT_BEST_ESTMT_R,SRC.N_CHG_RSRV_DIRECT_BEST_ESTMT_CEDED_R
,SRC.N_CHG_RSRV_DIRECT_BEST_ESTMT_NET_R,SRC.N_BEST_ESTIMATE_NET_BENEFIT_R,SRC.V_BEST_ESTMT_RESERVE_MODEL_R,SRC.N_RESERVE_DIRECT_FIELD_R
,SRC.N_PRIOR_RESERVE_DIRECT_FIELD_R,SRC.N_RESERVE_DIRECT_FIELD_CEDED_R,SRC.N_PRIOR_RESERVE_DIRECT_FIELD_CEDED_R,SRC.N_RESERVE_DIRECT_FIELD_NET_R
,SRC.N_PRIOR_RESERVE_DIRECT_FIELD_NET_R,SRC.N_CHG_RESERVE_DIRECT_FIELD_R,SRC.N_CHG_RESERVE_DIRECT_FIELD_CEDED_R,SRC.N_CHG_RESERVE_DIRECT_FIELD_NET_R
,SRC.n_claim_sk_r,SRC.N_CUST_PARTY_SK_R,SRC.n_policy_sk_r,SRC.n_claim_coverage_sk_r,SRC.N_CLAIM_COVERAGE_GROUP_Sk_R,SRC.N_PRODUCT_SK_R
,SRC.D_RESERVE_VALUATION_DATE_R,SRC.V_RESERVE_TYPE_IND_R,&apos;PKG_GRP_LOAD_RPT_RESERVE_DETAILS_R.PRC_GET_CUR_DATA&apos;,SYSTIMESTAMP,&apos;PKG_GRP_LOAD_RPT_RESERVE_DETAILS_R.PRC_GET_CUR_DATA&apos;,SYSTIMESTAMP,&apos;Y&apos;,to_number(TO_CHAR(sysdate,&apos;YYYYMMDD&apos;)),to_number(TO_CHAR(SRC.D_RESERVE_VALUATION_DATE_R,&apos;YYYYMM&apos;)),SRC.V_PRIMARY_REINSURER_R
,SRC.V_SECONDARY_REINSURER_R,SRC.V_TERNARY_REINSURER_R,SRC.N_PRIMARY_REINSURER_REINS_SHARE_PCT_R,SRC.N_SECONDARY_REINSURER_REINS_SHARE_PCT_R,
SRC.N_TERNARY_REINSURER_REINS_SHARE_PCT_R,SRC.N_PRIMARY_REINSURER_REINSURANCE_PCT_R,SRC.N_SECONDARY_REINSURER_REINSURANCE_PCT_R
,SRC.N_TERNARY_REINSURER_REINSURANCE_PCT_R,SRC.N_TOTAL_REINSURANCE_PCT_R,SRC.N_INSRD_PARTY_SK_R,SRC.N_EMPLOYEE_SK_R);




  lc_run_cnt:= SQL%ROWCOUNT;
    COMMIT;

	lc_count_type_r:= PKG_GRP_LOG_UTIL.gc_count_type_merge;

    gc_trcmsg:=&apos;2.1 Rows Merged count and Cycle_Date:-&gt;&apos;||lc_run_cnt||&apos;-&apos;||gd_mis_cycle_date_r;


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

	gc_trcmsg:=&apos;2.2 Capturing Audit Controls for Reserves Best Estimate Fact2RPT&apos; ;
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

	PRC_GRP_AUDIT_CONTROL_PROCESS (&apos;EDW&apos;,&apos;RESERVES_BEST_ESTIMATE&apos;,&apos;FCT&apos;,&apos;RPT&apos;);	

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

END PRC_GRP_LOAD_RPT_RESERVE_DETAILS_BEST_ESTIMATE_RESERVES_PREV_MONTH_R;

END PKG_GRP_LOAD_RPT_RESERVE_DETAILS_BEST_ESTIMATE_RESERVES_PREV_MONTH_R;"