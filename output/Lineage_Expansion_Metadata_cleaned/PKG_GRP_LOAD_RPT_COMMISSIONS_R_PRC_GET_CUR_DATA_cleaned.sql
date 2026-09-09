-- Cleaned for lineage: PKG_GRP_LOAD_RPT_COMMISSIONS_R_PRC_GET_CUR_DATA

INSERT  INTO RPT_COMMISSIONS_R_EXG stg    
	SELECT   
		CAST(NULL AS NUMBER) AS N_BILLGROUP_SK_R
		,comm_summ.N_POLICY_SK_R          as  N_POLICY_SK_R
		,comm_summ.N_AGENT_SK_R          as   N_AGENT_SK_R
		,comm_summ.N_CUST_PARTY_SK_R      as  N_CUST_PARTY_SK_R
		,comm_summ.V_TEMPLATE_NAME_R          as  V_TEMPLATE_NAME_R
		,comm_summ.D_COMMISSION_DATE_R          as D_COMMISSION_DATE_R
		,comm_summ.D_DUE_DATE_R          as  D_DUE_DATE_R
		,comm_summ.D_PAID_TO_DATE_R          as  D_PAID_TO_DATE_R
		,comm_summ.V_COMMISSION_TYPE_R          as  V_COMMISSION_TYPE_R
		,comm_summ.N_COMMISSION_AMOUNT_R          as  N_COMMISSION_AMOUNT_R
		,comm_summ.V_COMMISSION_STATUS_R          as V_COMMISSION_STATUS_R
		,gc_main_loadedby                        V_LAST_MODIFIED_BY_R  
		,gd_sysdate                           T_CREATION_DATE_R     
		,gc_main_loadedby                     V_CREATED_BY_R 
		,gd_sysdate                           T_LAST_MODIFIED_DATE_R
		,'Y'                                  V_RPT_ACTIVE_STATUS_R 
		,gn_sysdt_batchid                     N_BATCH_ID_R		  
		,gn_current_month                     N_YEARMONTH_R 
		, case 
		when nvl(comm_summ.v_commission_type_r,'-') in ('A','O') 
		THEN 
		NVL(REGEXP_SUBSTR(comm_summ.V_TEMPLATE_NAME_R,'\d*\.?\d+'),0)|| '% Flat' 
		when plcy_lkp.V_TEMPLATE_NAME_R like 'PCH%' then SUBSTR(comm_summ.V_TEMPLATE_NAME_R, INSTR(comm_summ.V_TEMPLATE_NAME_R, '-') + 1, 2) || '% First Year, ' || SUBSTR(comm_summ.V_TEMPLATE_NAME_R, INSTR(comm_summ.V_TEMPLATE_NAME_R, '-') + 3, 2) || '% Renewal (Heaped)'
		ELSE NVL(stg.v_sales_plan_desc_r,STG1.v_sales_plan_desc_r) END as V_SALES_PLAN_DESC_R  
		,comm_summ.v_data_source_name_r AS v_data_source_name_r 
	FROM fct_agent_commission_summary  comm_summ
	left join
		(
		select 
			n_agent_sk_r
			,V_TEMPLATE_NAME_R
			,N_last_rate_r 
			,N_POLICY_SK_R
		from fct_grp_agent_policy_r_lookup  
		group by 
			n_agent_sk_r
			,V_TEMPLATE_NAME_R
			,N_last_rate_r
			,N_POLICY_SK_R
		) plcy_lkp
	on comm_summ.N_AGENT_SK_R = plcy_lkp.N_AGENT_SK_R
	AND COMM_SUMM.N_POLICY_SK_R = PLCY_LKP.N_POLICY_SK_R  
	left join   
		(SELECT 
			N_PLAN_CODE_R 
			, N_RATE_R 
			, V_SALES_PLAN_DESC_R 
			, Row_number() over( partition by N_PLAN_CODE_R ,N_RATE_R order by N_PLAN_CODE_R ,N_RATE_R ) RANK_RW
		FROM ATOMIC.STG_PLAN_DETAIL
		) STG
	ON  STG.N_PLAN_CODE_R = plcy_lkp.V_TEMPLATE_NAME_R
	AND STG.N_RATE_R      = plcy_lkp.N_LAST_RATE_R
	and stg.RANK_RW       = 1    
	left join   
		(SELECT 
			N_PLAN_CODE_R 
			, N_RATE_R 
			, V_SALES_PLAN_DESC_R 
			, Row_number() over( partition by N_PLAN_CODE_R  order by N_PLAN_CODE_R ) RANK_RW
		FROM ATOMIC.STG_PLAN_DETAIL
		) STG1
	ON  STG1.N_PLAN_CODE_R = plcy_lkp.V_TEMPLATE_NAME_R
	and stg1.RANK_RW       = 1;