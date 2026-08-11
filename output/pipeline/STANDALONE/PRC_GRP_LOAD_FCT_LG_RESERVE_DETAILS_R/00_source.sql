

  CREATE OR REPLACE EDITIONABLE PROCEDURE "ATOMIC"."PRC_GRP_LOAD_FCT_LG_RESERVE_DETAILS_R"
AS
/*4.	FCT_LG_RESERVE_DETAILS_R
  a.	fiscal month end and weekly on saturdays schedules
  b.	Delete current month data which has been loaded on Saturdays of the current month and reload again
  c. Dependent EDW Tables and tidal jobs
   dim_grp_policy_dir_r
   --EDP_ODI_EDW_GRP_VUE_LOAD_DIM_GRP_POLICY_DIR_R
   --EDP_ODI_EDW_GRP_PACS_LOAD_DIM_GRP_POLICY_DIR_R
   --EDP_ODI_EDW_GRP_STACS_LOAD_DIM_GRP_POLICY_DIR_R
   --EDP_ODI_EDW_EIS_SHINKA_LOAD_DIM_GRP_POLICY_DIR_R

   dim_grp_claim_dir_r
   --EDP_ODI_EDW_GRP_PACS_LOAD_DIM_GRP_CLAIM_DIR_R
   --EDP_ODI_EDW_CV_SHINKA_LOAD_DIM_GRP_CLAIM_DIR_R

Called by Tidal shell script :- edw_grp_load_fct_lg_reserve_details_r.sh

*/
lc_bkp_tbl_str  VARCHAR2(10):=TO_CHAR(SYSDATE,'MMDDSS');
lc_sqlcode      VARCHAR2(300);
LC_SQLERRM       VARCHAR2(4000);
ld_sysdate      DATE:=SYSDATE;
lt_systimestamp TIMESTAMP:=SYSDATE;
lc_trcmsg       VARCHAR2(4000):='Trace Message:->';
ln_start_time   NUMBER;
ld_fic_mis_date DATE;
LC_DAY          VARCHAR2(30);
ln_n_batch_id_r number:=to_number(to_char(sysdate,'YYYYMMDD'));
ln_curr_month   number:=TO_NUMBER(to_char(SYSDATE -1,'YYYYMM'));
BEGIN
  --TAKE BKP
  lc_trcmsg:=lc_trcmsg||chr(13)||'1. Entered into Procedure PRC_GRP_LOAD_FCT_LG_RESERVE_DETAILS_R';
  lc_trcmsg:=lc_trcmsg||chr(13)||'2 Get Day';
  SELECT TO_CHAR(SYSDATE,'DAY')
     INTO LC_DAY
     FROM DUAL;
  lc_trcmsg:=lc_trcmsg||chr(13)||'2.1 Day is:->'||LC_DAY;

  lc_trcmsg:=lc_trcmsg||chr(13)||'3. Get Fiscal Month End Date +1 ';
     SELECT D_CALENDAR_DATE_R +1 INTO ld_fic_mis_date
     FROM DIM_TIME_R D
     WHERE  V_END_OF_FISCAL_MONTH_IND_R = 'Y'
     and to_char(d_calendar_date_r,'YYYYMM')=to_char(sysdate,'YYYYMM');
  lc_trcmsg:=lc_trcmsg||chr(13)||'3.1 Fiscal Month End Date +1 is :->'||ld_fic_mis_date;

   IF TO_DATE(ld_fic_mis_date) = TO_DATE(ld_sysdate)  --to load data on next day of Fiscal Month (Ex:the fiscal month end for May 2023 is 26-MAY-23 so we should load this on 27-MAY-23)
   OR TRIM(LC_DAY)='SATURDAY'-- or to load data on Saturday
   THEN
      /*BEGIN
        EXECUTE IMMEDIATE 'CREATE TABLE ATOMIC.FCT_LG_RESERVE_DETAILS_R_BKP_'||lc_bkp_tbl_str||' as select * from ATOMIC.FCT_LG_RESERVE_DETAILS_R';
      	lc_trcmsg:=lc_trcmsg||chr(13)||'4. Bkp Table Created FCT_LG_RESERVE_DETAILS_R_BKP_'||lc_bkp_tbl_str;
      EXCEPTION
      WHEN OTHERS THEN
        LC_SQLERRM:=SUBSTR(SQLERRM,1,4000);
	    lc_trcmsg:=lc_trcmsg||chr(13)||'4.1. '||LC_SQLERRM;
      END;*/
      lc_trcmsg:=lc_trcmsg||chr(13)||'5. Delete the records from the table FCT_LG_RESERVE_DETAILS_R where n_report_month_r = '||ln_curr_month;

      delete /*+PARALLEL(4)*/ from  FCT_LG_RESERVE_DETAILS_R_INCR where TO_CHAR(D_RESERVE_VALUATION_DATE_R,'YYYYMM')=to_char(ln_curr_month);--TO_NUMBER(to_char(SYSDATE -1,'YYYYMM'));
      commit;
      lc_trcmsg:=lc_trcmsg||chr(13)||'5.1 Deleted the records from the table FCT_LG_RESERVE_DETAILS_R_INCR where TO_CHAR(D_RESERVE_VALUATION_DATE_R,YYYYMM) = '||ln_curr_month;
      ln_start_time:=DBMS_UTILITY.GET_TIME;
      lc_trcmsg:=lc_trcmsg||chr(13)||'6. Insert into the table FCT_LG_RESERVE_DETAILS_R_INCR:->'||ln_start_time||' Seconds';
		insert  /*+APPEND*/ into atomic.FCT_LG_RESERVE_DETAILS_R_INCR
		(
		v_reserve_type_ind_r,
		n_reserve_direct__gaap__r,
		n_chg_reserve_direct__gaap__r,
		n_reserve_direct__stat__r,
		n_chg_reserve_direct__stat__r,
		n_original_reserve_r,
		n_current_reserve_r,
		n_gross_benefit_r,
		n_net_benefit_r,
		n_check_net_benefit_r,
		n_financial_net_benefit_r,
		n_reserve_direct_best_estmt_r,
		n_chg_rsrv_direct_best_estmt_r,
		n_best_estimate_net_benefit_r,
		v_pricing_ssdi_estimated_ind_r,
		v_best_estmt_reserve_model_r,
		n_reserve_direct__field__r,
		--n_reserve_ceded__field__r,
		-- n_reserve_net__field__r,
		n_chg_reserve_direct__field__r,
		n_unadjustd_rsrv_direct_gaap_r,
		n_unadjustd_rsrv_direct_stat_r,
		D_RESERVE_VALUATION_DATE_R,
		V_COVERAGE_CODE_R,
		N_GAAP_IBNR_CEDED_R,
		N_STAT_IBNR_CEDED_R,
		v_policy_number_r,
		v_claim_number_r,
		N_POLICY_SK_R,
		n_claim_sk_r,
		FIC_MIS_DATE_R,
		N_BATCH_ID_R,
		N_SEQUENCE_NUMBER_R,
		T_CREATION_DATE_R,
		T_LAST_MODIFIED_DATE_R,
		V_CREATED_BY_R,
		V_LAST_MODIFIED_BY_R,
		v_claim_identifier_r,
		V_cov_grp_id_r
		)
		select
		v_reserve_type_ind_r,
		n_reserve_direct__gaap__r,
		n_chg_reserve_direct__gaap__r,
		n_reserve_direct__stat__r,
		n_chg_reserve_direct__stat__r,
		n_original_reserve_r,
		n_current_reserve_r,
		n_gross_benefit_r,
		n_net_benefit_r,
		n_check_net_benefit_r,
		n_financial_net_benefit_r,
		n_reserve_direct_best_estmt_r,
		n_chg_rsrv_direct_best_estmt_r,
		n_best_estimate_net_benefit_r,
		v_pricing_ssdi_estimated_ind_r,
		v_best_estmt_reserve_model_r,
		n_reserve_direct__field__r,
		-- n_reserve_ceded__field__r,     -- they are not present
		-- n_reserve_net__field__r,    -- they are not present
		n_chg_reserve_direct__field__r,
		n_unadjustd_rsrv_direct_gaap_r,
		n_unadjustd_rsrv_direct_stat_r,
		D_RESERVE_VALUATION_DATE_R,
		V_COVERAGE_CODE_R,
		N_GAAP_IBNR_CEDED_R,
		N_STAT_IBNR_CEDED_R,
		a.v_policy_number_r,
		a.v_claim_number_r,
		NVL(Dim_grp_policy_dir_r.N_POLICY_SK_R,-1) as N_POLICY_SK_R,
		NVL(Dim_grp_claim_dir_r.N_claim_SK_R,-1) as n_claim_sk_r,
		--Gireesh changes starts
		--to_date('20101231','YYYYMMDD') FIC_MIS_DATE_R,
		ld_SYSDATE FIC_MIS_DATE_R,--PASS SYSDATE,
		--,201012310000 N_BATCH_ID_R--PASS SYSDATE,
		to_char(ld_SYSDATE ,'YYYYMMDD') N_BATCH_ID_R,
		--Gireesh changes ends
		rownum as N_SEQUENCE_NUMBER_R,
		lt_systimestamp as T_CREATION_DATE_R,
		lt_systimestamp as T_LAST_MODIFIED_DATE_R,
		'PRC_GRP_LOAD_FCT_LG_RESERVE_DETAILS_R' as V_CREATED_BY_R,
		'PRC_GRP_LOAD_FCT_LG_RESERVE_DETAILS_R' as V_LAST_MODIFIED_BY_R,
		v_claim_identifier_r,
		V_cov_grp_id_r
		from
		(
		 SELECT /*+PARALLEL(4)*/
		 td1.calendar_date as D_RESERVE_VALUATION_DATE_R -- RESERVE_VALUATION_DATE_KEY use calendar date from time dim
		,rf.RESERVE_TYPE_IND as v_reserve_type_ind_r
		,rf.GAAP_RESERVE_DIRECT_AMT as n_reserve_direct__gaap__r
		,rf.CHG_GAAP_RESERVE_DIRECT_AMT AS n_chg_reserve_direct__gaap__r
		,rf.STAT_RESERVE_DIRECT_AMT AS n_reserve_direct__stat__r
		,rf.CHG_STAT_RESERVE_DIRECT_AMT AS n_chg_reserve_direct__stat__r
		,rf.ORIGINAL_RESERVE_AMT AS n_original_reserve_r
		,rf.CURRENT_RESERVE_AMT AS n_current_reserve_r
		,rf.GROSS_BENEFIT_AMT AS n_gross_benefit_r
		,rf.NET_BENEFIT_AMT AS n_net_benefit_r
		,rf.CHECK_NET_BENEFIT_AMT AS n_check_net_benefit_r
		,rf.FIN_RESERVE_NET_BENEFIT_AMT AS n_financial_net_benefit_r
		,rf.ACT_RESERVE_DIRECT_AMT AS n_reserve_direct_best_estmt_r
		,rf.CHG_ACT_RESERVE_DIRECT_AMT AS n_chg_rsrv_direct_best_estmt_r
		,rf.ACT_NET_BENEFIT as n_best_estimate_net_benefit_r
		,rf.ACT_SSDI_ESTIMATED_IND AS v_pricing_ssdi_estimated_ind_r
		,rf.ACT_RESERVE_MODEL AS v_best_estmt_reserve_model_r
		--,rf.FIELD_RESERVE_DIRECT_AMT AS n_reserve_direct__field__r
		,cf.curr_stat_reserve_direct_amt AS n_reserve_direct__field__r	---09-AUG-2024 Changes
		,rf.CHG_FIELD_RESERVE_DIRECT_AMT AS n_chg_reserve_direct__field__r
		,rf.GAAP_RESERVE_DIRECT_UNADJ_AMT AS n_unadjustd_rsrv_direct_gaap_r
		,rf.STAT_RESERVE_DIRECT_UNADJ_AMT AS n_unadjustd_rsrv_direct_stat_r
		--,cd.policy_num as V_POLICY_NUMBER_R --(n_policy_sk_r)
		,(case when cd.PACS_LOB_CODE = 'MAL' then cd.PACS_LOB_CODE||cd.POLICY_SUFFIX else cd.policy_num end) V_POLICY_NUMBER_R
		,cl.claim_num as v_claim_number_r
		,td1.calendar_date as D_CYCLE_DATE_R -- N_BATCH_ID_R  -- CYCLE_DATE
		,pd.COVERAGE_CODE AS V_COVERAGE_CODE_R --- GET FROM PRODUCT DIM
		,(CASE WHEN RF.RESERVE_TYPE_IND = 'I' THEN RF.GAAP_RESERVE_CEDED_AMT end) AS N_GAAP_IBNR_CEDED_R
		,(CASE WHEN RF.RESERVE_TYPE_IND = 'I' THEN  RF.STAT_RESERVE_CEDED_AMT end) AS N_STAT_IBNR_CEDED_R
		,cl.claim_num||case when COVERAGE_GROUP_CODE in ('DF', 'UN') then null else '-'||COVERAGE_GROUP_CODE end
		v_claim_identifier_r
		,cl.COVERAGE_GROUP_CODE V_cov_grp_id_r
		FROM RDM.Reserve_fact@report.rsli.com rf
		,rdm.customer_dim@report.rsli.com cd
		,rdm.time_dim@report.rsli.com td1
		,rdm.claim_dim@report.rsli.com cl
		,rdm.product_dim@report.rsli.com pd
		,rdm.claim_fact@report.rsli.com cf    ---09-AUG-2024 Changes
		where cd.customer_key = rf.customer_key
		and td1.date_key = rf.reserve_valuation_date_key
		and td1.date_key = rf.reserve_valuation_date_key
		and cl.claim_key = rf.claim_key
		and pd.product_key = rf.product_key
		and rf.claim_key = cf.claim_key(+)	---09-AUG-2024 Changes
		AND TO_NUMBER(to_char(td1.calendar_date,'YYYYMM')) =ln_curr_month--TO_NUMBER(to_char(SYSDATE -1,'YYYYMM')) --ADDED
		and rf.RESERVE_TYPE_IND <> 'I'
		) a Left Join (select /*+PARALLEL(4)*/  --distinct
		                N_POLICY_SK_R, V_POLICY_NUMBER_R from DIM_GRP_POLICY_DIR_R WHERE  v_active_status_r ='Y'
						group by N_POLICY_SK_R, V_POLICY_NUMBER_R
						) Dim_grp_policy_dir_r on a.V_POLICY_NUMBER_R = Dim_grp_policy_dir_r.V_POLICY_NUMBER_R
			Left Join (select /*+PARALLEL(4)*/  max(N_CLAIM_SK_R) N_CLAIM_SK_R, V_CLAIM_NUMBER_R from DIM_GRP_CLAIM_DIR_R WHERE  v_active_status_r ='Y' group by V_CLAIM_NUMBER_R) dim_grp_claim_dir_r on a.V_CLAIM_NUMBER_R = dim_grp_claim_dir_r.V_CLAIM_NUMBER_R
		union

		select /*+PARALLEL(4)*/
		v_reserve_type_ind_r,
		n_reserve_direct__gaap__r,
		n_chg_reserve_direct__gaap__r,
		n_reserve_direct__stat__r,
		n_chg_reserve_direct__stat__r,
		n_original_reserve_r,
		n_current_reserve_r,
		n_gross_benefit_r,
		n_net_benefit_r,
		n_check_net_benefit_r,
		n_financial_net_benefit_r,
		n_reserve_direct_best_estmt_r,
		n_chg_rsrv_direct_best_estmt_r,
		n_best_estimate_net_benefit_r,
		v_pricing_ssdi_estimated_ind_r,
		v_best_estmt_reserve_model_r,
		n_reserve_direct__field__r,
		-- n_reserve_ceded__field__r,     -- they are not present
		-- n_reserve_net__field__r,    -- they are not present
		n_chg_reserve_direct__field__r,
		n_unadjustd_rsrv_direct_gaap_r,
		n_unadjustd_rsrv_direct_stat_r,
		D_RESERVE_VALUATION_DATE_R,
		V_COVERAGE_CODE_R,
		N_GAAP_IBNR_CEDED_R,
		N_STAT_IBNR_CEDED_R,
		a.v_policy_number_r,
		v_claim_number_r,
		NVL(Dim_grp_policy_dir_r.N_POLICY_SK_R,-1) as N_POLICY_SK_R,
		-1 as n_claim_sk_r,
		--Gireesh changes starts
		--to_date('20101231','YYYYMMDD') FIC_MIS_DATE_R,
		ld_sysdate FIC_MIS_DATE_R,--PASS SYSDATE,
		--,201012310000 N_BATCH_ID_R--PASS SYSDATE,
		to_char(ld_sysdate ,'YYYYMMDD') N_BATCH_ID_R,
		--Gireesh changes ends
		rownum as N_SEQUENCE_NUMBER_R,
		lt_systimestamp as T_CREATION_DATE_R,
		lt_systimestamp as T_LAST_MODIFIED_DATE_R,
		'PRC_GRP_LOAD_FCT_LG_RESERVE_DETAILS_R' as V_CREATED_BY_R,
		'PRC_GRP_LOAD_FCT_LG_RESERVE_DETAILS_R' as V_LAST_MODIFIED_BY_R,
		v_claim_identifier_r,
		V_cov_grp_id_r
		from
		(
		 SELECT /*+PARALLEL(4)*/
		 td1.calendar_date as D_RESERVE_VALUATION_DATE_R -- RESERVE_VALUATION_DATE_KEY use calendar date from time dim
		,'I' as v_reserve_type_ind_r
		,SUM(rf.GAAP_IBNR_DIRECT_AMT) as n_reserve_direct__gaap__r
		,SUM(rf.CHG_GAAP_IBNR_DIRECT_AMT) AS n_chg_reserve_direct__gaap__r
		,SUM(rf.STAT_IBNR_DIRECT_AMT) AS n_reserve_direct__stat__r
		,SUM(rf.CHG_STAT_IBNR_DIRECT_AMT) AS n_chg_reserve_direct__stat__r
		,cast (null as int) AS n_original_reserve_r
		,cast (null as int) AS n_current_reserve_r
		,cast (null as int) AS n_gross_benefit_r
		,cast (null as int) AS n_net_benefit_r
		,cast (null as int) AS n_check_net_benefit_r
		,cast (null as int) AS n_financial_net_benefit_r
		,cast (null as int)  AS n_reserve_direct_best_estmt_r
		,cast (null as int)  AS n_chg_rsrv_direct_best_estmt_r
		,cast (null as int) as n_best_estimate_net_benefit_r
		,cast (null as VARCHAR(100))  AS v_pricing_ssdi_estimated_ind_r
		,cast (null as VARCHAR(100)) AS v_best_estmt_reserve_model_r
		,cast (null as int)  AS n_reserve_direct__field__r
		,cast (null as int)  AS n_chg_reserve_direct__field__r
		,cast (null as int) AS n_unadjustd_rsrv_direct_gaap_r
		,cast (null as int) AS n_unadjustd_rsrv_direct_stat_r
		--,cd.policy_num as V_POLICY_NUMBER_R --(n_policy_sk_r)
		,(case when cd.PACS_LOB_CODE = 'MAL' then cd.PACS_LOB_CODE||cd.POLICY_SUFFIX else cd.policy_num end) V_POLICY_NUMBER_R
		,'Unknown' as v_claim_number_r
		,td1.calendar_date as D_CYCLE_DATE_R -- N_BATCH_ID_R  -- CYCLE_DATE
		,pd.COVERAGE_CODE AS V_COVERAGE_CODE_R --- GET FROM PRODUCT DIM
		,sum(rf.GAAP_IBNR_CEDED_AMT) AS N_GAAP_IBNR_CEDED_R
		,sum(rf.STAT_IBNR_CEDED_AMT) AS N_STAT_IBNR_CEDED_R
		,cast (null as VARCHAR(100))v_claim_identifier_r,
		cast (null as VARCHAR(100)) V_cov_grp_id_r
		  FROM rdm.PERF_IBNR_RESERVE_FACT@report.rsli.com RF
		  INNER JOIN rdm.PRODUCT_DIM@report.rsli.com PD on ( pd.product_key = rf.product_key )
		  INNER JOIN rdm.CUSTOMER_DIM@report.rsli.com CD on ( cd.customer_key = rf.customer_key )
		  inner join rdm.TIME_DIM@report.rsli.com td1 on ( td1.date_key  = rf.cycle_date_key )
		  AND TO_NUMBER(to_char(td1.calendar_date,'YYYYMM')) =ln_curr_month--TO_NUMBER(to_char(SYSDATE -1,'YYYYMM')) --ADDED
		 -- where td1.d_calendar_date_R = '24-FEB-23'
		  group by (case when cd.PACS_LOB_CODE = 'MAL' then cd.PACS_LOB_CODE||cd.POLICY_SUFFIX else cd.policy_num end), pd.coverage_code, td1.calendar_date, 'I' ,'Unknown'
		) a Left Join (select /*+PARALLEL(4)*/  --distinct
		               N_POLICY_SK_R, V_POLICY_NUMBER_R
		               from DIM_GRP_POLICY_DIR_R WHERE  v_active_status_r ='Y'
					   group by N_POLICY_SK_R, V_POLICY_NUMBER_R) Dim_grp_policy_dir_r on a.V_POLICY_NUMBER_R = Dim_grp_policy_dir_r.V_POLICY_NUMBER_R

		union

		 select /*+PARALLEL(4)*/
		v_reserve_type_ind_r,
		n_reserve_direct__gaap__r,
		n_chg_reserve_direct__gaap__r,
		n_reserve_direct__stat__r,
		n_chg_reserve_direct__stat__r,
		n_original_reserve_r,
		n_current_reserve_r,
		n_gross_benefit_r,
		n_net_benefit_r,
		n_check_net_benefit_r,
		n_financial_net_benefit_r,
		n_reserve_direct_best_estmt_r,
		n_chg_rsrv_direct_best_estmt_r,
		n_best_estimate_net_benefit_r,
		v_pricing_ssdi_estimated_ind_r,
		v_best_estmt_reserve_model_r,
		n_reserve_direct__field__r,
		-- n_reserve_ceded__field__r,     -- they are not present
		-- n_reserve_net__field__r,    -- they are not present
		n_chg_reserve_direct__field__r,
		n_unadjustd_rsrv_direct_gaap_r,
		n_unadjustd_rsrv_direct_stat_r,
		D_RESERVE_VALUATION_DATE_R,
		V_COVERAGE_CODE_R,
		N_GAAP_IBNR_CEDED_R,
		N_STAT_IBNR_CEDED_R,
		a.v_policy_number_r,
		v_claim_number_r,
		NVL(Dim_grp_policy_dir_r.N_POLICY_SK_R,-1) as N_POLICY_SK_R,
		-1 as n_claim_sk_r,
		--Gireesh changes starts
		--to_date('20101231','YYYYMMDD') FIC_MIS_DATE_R,
		ld_sysdate FIC_MIS_DATE_R,--PASS SYSDATE,
		--,201012310000 N_BATCH_ID_R--PASS SYSDATE,
		to_char(ld_sysdate ,'YYYYMMDD') N_BATCH_ID_R,
		--Gireesh changes ends
		rownum as N_SEQUENCE_NUMBER_R,
		lt_systimestamp as T_CREATION_DATE_R,
		lt_systimestamp as T_LAST_MODIFIED_DATE_R,
		'PRC_GRP_LOAD_FCT_LG_RESERVE_DETAILS_R' as V_CREATED_BY_R,
		'PRC_GRP_LOAD_FCT_LG_RESERVE_DETAILS_R' as V_LAST_MODIFIED_BY_R,
		v_claim_identifier_r,
		V_cov_grp_id_r
		from (

		 SELECT /*+PARALLEL(4)*/
		 td2.calendar_date as D_RESERVE_VALUATION_DATE_R
		,'P' as v_reserve_type_ind_r
		,cast (null as int)  as n_reserve_direct__gaap__r
		,cast (null as int)  AS n_chg_reserve_direct__gaap__r
		,cast (null as int)  AS n_reserve_direct__stat__r
		,cast (null as int)  AS n_chg_reserve_direct__stat__r
		,cast (null as int) AS n_original_reserve_r
		,cast (null as int)  AS n_current_reserve_r
		,cast (null as int)  AS n_gross_benefit_r
		,cast (null as int)  AS n_net_benefit_r
		,cast (null as int)  AS n_check_net_benefit_r
		,cast (null as int) AS n_financial_net_benefit_r
		,sum(CASE WHEN CD2.policy_prefix in ( 'GL', 'GGL', 'VG', 'SR', 'VAR' ) THEN PAPF.PREMIUM * 0.15
							 WHEN CD2.policy_prefix in ( 'G', 'DBL' ,'VPS', 'MAL', 'CTL') THEN  PAPF.PREMIUM  * 0.25
							 WHEN CD2.policy_prefix in ( 'LTD', 'VLT','VPL'  ) THEN ( ( NVL(CD2.POLICY_ELIMINATION_PERIOD,0) + 60) / 365 ) * PAPF.PREMIUM* 0.80
							 WHEN (CD2.policy_prefix = 'VIP' AND pd.BASIC_PRODUCT_LINE_CODE = 'STD') THEN PAPF.PREMIUM  * 0.25
							 WHEN ( CD2.policy_prefix = 'VIP' AND pd.BASIC_PRODUCT_LINE_CODE  = 'LTD') THEN ( ( NVL(CD2.POLICY_ELIMINATION_PERIOD,0) + 60) / 365 ) * PAPF.PREMIUM  * 0.80
							 END ) AS n_reserve_direct_best_estmt_r
		,cast (null as int)  AS n_chg_rsrv_direct_best_estmt_r
		,cast (null as int)  as n_best_estimate_net_benefit_r
		,cast (null as VARCHAR(100))  AS v_pricing_ssdi_estimated_ind_r
		,cast (null as VARCHAR(100)) AS v_best_estmt_reserve_model_r
		,sum(CASE WHEN CD2.policy_prefix in ( 'GL', 'GGL', 'VG', 'SR', 'VAR' ) THEN PAPF.PREMIUM * 0.15
							 WHEN CD2.policy_prefix in ( 'G', 'DBL' ,'VPS', 'MAL', 'CTL') THEN  PAPF.PREMIUM  * 0.25
							 WHEN CD2.policy_prefix in ( 'LTD', 'VLT','VPL'  ) THEN ( ( NVL(CD2.POLICY_ELIMINATION_PERIOD,0) + 60) / 365 ) * PAPF.PREMIUM* 0.80
							 WHEN (CD2.policy_prefix = 'VIP' AND pd.BASIC_PRODUCT_LINE_CODE = 'STD') THEN PAPF.PREMIUM  * 0.25
							 WHEN ( CD2.policy_prefix = 'VIP' AND pd.BASIC_PRODUCT_LINE_CODE  = 'LTD') THEN ( ( NVL(CD2.POLICY_ELIMINATION_PERIOD,0) + 60) / 365 ) * PAPF.PREMIUM  * 0.80
							 END )  AS n_reserve_direct__field__r
		,cast (null as int)  AS n_chg_reserve_direct__field__r
		,cast (null as int)  AS n_unadjustd_rsrv_direct_gaap_r
		,cast (null as int)  AS n_unadjustd_rsrv_direct_stat_r
		--,cd.policy_num as V_POLICY_NUMBER_R --(n_policy_sk_r)
		,(case when cd2.PACS_LOB_CODE = 'MAL' then cd2.PACS_LOB_CODE||cd2.POLICY_SUFFIX else cd2.policy_num end) V_POLICY_NUMBER_R
		,'Unknown' as v_claim_number_r
		,td2.calendar_date as D_CYCLE_DATE_R -- N_BATCH_ID_R  -- CYCLE_DATE
		,pd.COVERAGE_CODE AS V_COVERAGE_CODE_R --- GET FROM PRODUCT DIM
		,cast (null as int) AS N_GAAP_IBNR_CEDED_R
		,cast (null as int) AS N_STAT_IBNR_CEDED_R
		,cast (null as VARCHAR(100)) as v_claim_identifier_r
		,cast (null as VARCHAR(100)) as V_cov_grp_id_r
		FROM  RDM.PERF_ANNUALIZED_PREMIUM_FACT@REPORT.RSLI.COM PAPF
			  inner JOIN
			  RDM.TIME_DIM@REPORT.RSLI.COM TD2
			  ON PAPF.CYCLE_DATE_KEY = TD2.DATE_KEY
			LEFT OUTER JOIN
			  RDM.CUSTOMER_DIM@REPORT.RSLI.COM CD2
			  ON PAPF.CUSTOMER_KEY = CD2.CUSTOMER_KEY
			LEFT OUTER JOIN
			  RDM.PRODUCT_DIM@REPORT.RSLI.COM PD
			  ON PAPF.PRODUCT_KEY = PD.PRODUCT_KEY
			--  where td2.calendar_date = '24-FEB-23'
			AND TO_NUMBER(to_char(td2.calendar_date,'YYYYMM')) =ln_curr_month--TO_NUMBER(to_char(SYSDATE -1,'YYYYMM')) --ADDED
			--  and cd2.policy_num = 'LTD133188'
			group by td2.calendar_date,(case when cd2.PACS_LOB_CODE = 'MAL' then cd2.PACS_LOB_CODE||cd2.POLICY_SUFFIX else cd2.policy_num end),
			pd.COVERAGE_CODE,'P' ,'Unknown'
			)a
			 Left Join (select /*+PARALLEL(4)*/  --distinct
			            N_POLICY_SK_R, V_POLICY_NUMBER_R from DIM_GRP_POLICY_DIR_R WHERE  v_active_status_r ='Y'
						group by N_POLICY_SK_R, V_POLICY_NUMBER_R
						) Dim_grp_policy_dir_r on a.V_POLICY_NUMBER_R = Dim_grp_policy_dir_r.V_POLICY_NUMBER_R;

      commit;
      lc_trcmsg:=lc_trcmsg||chr(13)||'6.1. Inserted data into the table FCT_LG_RESERVE_DETAILS_R_INCR:->'||(DBMS_UTILITY.GET_TIME-ln_start_time)||' Seconds';
	ELSE
	  lc_trcmsg:=lc_trcmsg||chr(13)||'6.2. The current date/day is neither Fiscal Month End Date +1 nor Saturday , So data will not be loaded';
    END IF;
	lc_trcmsg:=lc_trcmsg||chr(13)||'7. Insert trace message into the table PRCS_GRP_TBL_LOAD_DEBUG_TRC';
    INSERT INTO ATOMIC.PRCS_GRP_TBL_LOAD_DEBUG_TRC(V_JOB_NAME_R
                                                   ,V_PKG_PRC_NAME_R
                                                   ,N_SK_R
                                                   ,V_NUMBER_R
                                                   ,V_TRC_MSG_R
                                                   ,N_BATCH_ID_R
                                                   ,v_created_by_r
                                                   ,V_LAST_MODIFIED_BY_R
                                                  )
    										VALUES('GRP_LOAD_FCT_LG_RESERVE_DETAILS_R'
    										      ,'PRC_GRP_LOAD_FCT_LG_RESERVE_DETAILS_R'
    											  ,NULL
    											  ,NULL
    											  ,lc_trcmsg
    											  ,ln_N_BATCH_ID_R
    											  ,'PRC_GRP_LOAD_FCT_LG_RESERVE_DETAILS_R'
    											  ,'PRC_GRP_LOAD_FCT_LG_RESERVE_DETAILS_R'
    										);

    commit;

EXCEPTION
WHEN OTHERS THEN
LC_SQLCODE:=SQLCODE;
LC_SQLERRM:=SUBSTR(SQLERRM,1,4000);
--OUT_LOAD_STATUS:=LC_SQLCODE||'-'||LC_SQLERRM;
--GC_TRC_MSG:='Final Error Message:->'||LC_SQLCODE||'-'||LC_SQLERRM;
INSERT INTO ATOMIC.PRCS_GRP_TBL_LOAD_DEBUG_TRC(V_JOB_NAME_R
                                               ,V_PKG_PRC_NAME_R
                                               ,N_SK_R
                                               ,V_NUMBER_R
                                               ,V_TRC_MSG_R
                                               ,N_BATCH_ID_R
                                               ,v_created_by_r
                                               ,V_LAST_MODIFIED_BY_R
                                              )
										VALUES('GRP_LOAD_FCT_LG_RESERVE_DETAILS_R'
										      ,'PRC_GRP_LOAD_FCT_LG_RESERVE_DETAILS_R'
											  ,NULL
											  ,NULL
											  ,'When others raised in PRC_GRP_LOAD_FCT_LG_RESERVE_DETAILS_R :->'||lc_trcmsg||LC_SQLCODE||'->'||LC_SQLERRM
											  ,ln_N_BATCH_ID_R
											  ,'PRC_GRP_LOAD_FCT_LG_RESERVE_DETAILS_R'
											  ,'PRC_GRP_LOAD_FCT_LG_RESERVE_DETAILS_R'
										);

commit;
raise_application_error(-20001,'Others-Error in PRC_GRP_LOAD_FCT_LG_RESERVE_DETAILS_R:->'||LC_SQLERRM);

END PRC_GRP_LOAD_FCT_LG_RESERVE_DETAILS_R;

