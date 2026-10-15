-- Cleaned for lineage: PRC_GRP_LOAD_FCT_LG_RESERVE_DETAILS_R (part 2/3)

insert   into atomic.FCT_LG_RESERVE_DETAILS_R_INCR
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
		ld_SYSDATE FIC_MIS_DATE_R,
		to_char(ld_SYSDATE ,'YYYYMMDD') N_BATCH_ID_R,
		rownum as N_SEQUENCE_NUMBER_R,
		lt_systimestamp as T_CREATION_DATE_R,
		lt_systimestamp as T_LAST_MODIFIED_DATE_R,
		'PRC_GRP_LOAD_FCT_LG_RESERVE_DETAILS_R' as V_CREATED_BY_R,
		'PRC_GRP_LOAD_FCT_LG_RESERVE_DETAILS_R' as V_LAST_MODIFIED_BY_R,
		v_claim_identifier_r,
		V_cov_grp_id_r
		from
		(
		 SELECT 
		 td1.calendar_date as D_RESERVE_VALUATION_DATE_R 
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
		,cf.curr_stat_reserve_direct_amt AS n_reserve_direct__field__r	
		,rf.CHG_FIELD_RESERVE_DIRECT_AMT AS n_chg_reserve_direct__field__r
		,rf.GAAP_RESERVE_DIRECT_UNADJ_AMT AS n_unadjustd_rsrv_direct_gaap_r
		,rf.STAT_RESERVE_DIRECT_UNADJ_AMT AS n_unadjustd_rsrv_direct_stat_r
		,(case when cd.PACS_LOB_CODE = 'MAL' then cd.PACS_LOB_CODE||cd.POLICY_SUFFIX else cd.policy_num end) V_POLICY_NUMBER_R
		,cl.claim_num as v_claim_number_r
		,td1.calendar_date as D_CYCLE_DATE_R 
		,pd.COVERAGE_CODE AS V_COVERAGE_CODE_R 
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
		,rdm.claim_fact@report.rsli.com cf    
		where cd.customer_key = rf.customer_key
		and td1.date_key = rf.reserve_valuation_date_key
		and td1.date_key = rf.reserve_valuation_date_key
		and cl.claim_key = rf.claim_key
		and pd.product_key = rf.product_key
		and rf.claim_key = cf.claim_key(+)	
		AND TO_NUMBER(to_char(td1.calendar_date,'YYYYMM')) =ln_curr_month
		and rf.RESERVE_TYPE_IND <> 'I'
		) a Left Join (select   
		                N_POLICY_SK_R, V_POLICY_NUMBER_R from DIM_GRP_POLICY_DIR_R WHERE  v_active_status_r ='Y'
						group by N_POLICY_SK_R, V_POLICY_NUMBER_R
						) Dim_grp_policy_dir_r on a.V_POLICY_NUMBER_R = Dim_grp_policy_dir_r.V_POLICY_NUMBER_R
			Left Join (select   max(N_CLAIM_SK_R) N_CLAIM_SK_R, V_CLAIM_NUMBER_R from DIM_GRP_CLAIM_DIR_R WHERE  v_active_status_r ='Y' group by V_CLAIM_NUMBER_R) dim_grp_claim_dir_r on a.V_CLAIM_NUMBER_R = dim_grp_claim_dir_r.V_CLAIM_NUMBER_R
		union
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
		ld_sysdate FIC_MIS_DATE_R,
		to_char(ld_sysdate ,'YYYYMMDD') N_BATCH_ID_R,
		rownum as N_SEQUENCE_NUMBER_R,
		lt_systimestamp as T_CREATION_DATE_R,
		lt_systimestamp as T_LAST_MODIFIED_DATE_R,
		'PRC_GRP_LOAD_FCT_LG_RESERVE_DETAILS_R' as V_CREATED_BY_R,
		'PRC_GRP_LOAD_FCT_LG_RESERVE_DETAILS_R' as V_LAST_MODIFIED_BY_R,
		v_claim_identifier_r,
		V_cov_grp_id_r
		from
		(
		 SELECT 
		 td1.calendar_date as D_RESERVE_VALUATION_DATE_R 
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
		,(case when cd.PACS_LOB_CODE = 'MAL' then cd.PACS_LOB_CODE||cd.POLICY_SUFFIX else cd.policy_num end) V_POLICY_NUMBER_R
		,'Unknown' as v_claim_number_r
		,td1.calendar_date as D_CYCLE_DATE_R 
		,pd.COVERAGE_CODE AS V_COVERAGE_CODE_R 
		,sum(rf.GAAP_IBNR_CEDED_AMT) AS N_GAAP_IBNR_CEDED_R
		,sum(rf.STAT_IBNR_CEDED_AMT) AS N_STAT_IBNR_CEDED_R
		,cast (null as VARCHAR(100))v_claim_identifier_r,
		cast (null as VARCHAR(100)) V_cov_grp_id_r
		  FROM rdm.PERF_IBNR_RESERVE_FACT@report.rsli.com RF
		  INNER JOIN rdm.PRODUCT_DIM@report.rsli.com PD on ( pd.product_key = rf.product_key )
		  INNER JOIN rdm.CUSTOMER_DIM@report.rsli.com CD on ( cd.customer_key = rf.customer_key )
		  inner join rdm.TIME_DIM@report.rsli.com td1 on ( td1.date_key  = rf.cycle_date_key )
		  AND TO_NUMBER(to_char(td1.calendar_date,'YYYYMM')) =ln_curr_month
		  group by (case when cd.PACS_LOB_CODE = 'MAL' then cd.PACS_LOB_CODE||cd.POLICY_SUFFIX else cd.policy_num end), pd.coverage_code, td1.calendar_date, 'I' ,'Unknown'
		) a Left Join (select   
		               N_POLICY_SK_R, V_POLICY_NUMBER_R
		               from DIM_GRP_POLICY_DIR_R WHERE  v_active_status_r ='Y'
					   group by N_POLICY_SK_R, V_POLICY_NUMBER_R) Dim_grp_policy_dir_r on a.V_POLICY_NUMBER_R = Dim_grp_policy_dir_r.V_POLICY_NUMBER_R
		union
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
		ld_sysdate FIC_MIS_DATE_R,
		to_char(ld_sysdate ,'YYYYMMDD') N_BATCH_ID_R,
		rownum as N_SEQUENCE_NUMBER_R,
		lt_systimestamp as T_CREATION_DATE_R,
		lt_systimestamp as T_LAST_MODIFIED_DATE_R,
		'PRC_GRP_LOAD_FCT_LG_RESERVE_DETAILS_R' as V_CREATED_BY_R,
		'PRC_GRP_LOAD_FCT_LG_RESERVE_DETAILS_R' as V_LAST_MODIFIED_BY_R,
		v_claim_identifier_r,
		V_cov_grp_id_r
		from (
		 SELECT 
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
		,(case when cd2.PACS_LOB_CODE = 'MAL' then cd2.PACS_LOB_CODE||cd2.POLICY_SUFFIX else cd2.policy_num end) V_POLICY_NUMBER_R
		,'Unknown' as v_claim_number_r
		,td2.calendar_date as D_CYCLE_DATE_R 
		,pd.COVERAGE_CODE AS V_COVERAGE_CODE_R 
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
			AND TO_NUMBER(to_char(td2.calendar_date,'YYYYMM')) =ln_curr_month
			group by td2.calendar_date,(case when cd2.PACS_LOB_CODE = 'MAL' then cd2.PACS_LOB_CODE||cd2.POLICY_SUFFIX else cd2.policy_num end),
			pd.COVERAGE_CODE,'P' ,'Unknown'
			)a
			 Left Join (select   
			            N_POLICY_SK_R, V_POLICY_NUMBER_R from DIM_GRP_POLICY_DIR_R WHERE  v_active_status_r ='Y'
						group by N_POLICY_SK_R, V_POLICY_NUMBER_R
						) Dim_grp_policy_dir_r on a.V_POLICY_NUMBER_R = Dim_grp_policy_dir_r.V_POLICY_NUMBER_R;