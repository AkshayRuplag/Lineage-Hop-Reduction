-- Cleaned for lineage: PRC_GRP_LOAD_FCT_INCURRED_SUMMARY_R (part 2/4)

INSERT  INTO  atomic.tmp_FCT_LG_RESERVE_DETAILS_R
		select distinct 
		LD_SYSDATE AS D_AS_OF_DATE_R,
		DIM_TIME_R.D_CALENDAR_DATE_R AS D_CYCLE_DATE_R,
		LG.N_POLICY_SK_R as N_POLICY_SK_R,
		nvl(policy.N_CUST_PARTY_SK_R,-1) as N_PARTY_SK_R,
		gpd.v_policy_prefix_r,
		gpd.v_policy_suffix_r,
		trunc(LG.D_RESERVE_VALUATION_DATE_R,'MM') AS D_UW_DATE_R,
		coalesce(product.V_BASIC_PRODUCT_LINE_CODE_R, gpd.v_policy_prefix_r) AS V_COVERAGE_R,
		LG.v_reserve_type_ind_r AS V_RESERVE_TYPE_IND_R,										  
		LG.n_chg_reserve_direct__gaap__r AS N_CHG_RESERVE_DIRECT__GAAP__R,
		CASE WHEN LG.v_reserve_type_ind_r ='P'THEN NVL(LG.n_reserve_direct_best_estmt_r,0) ELSE 0 END AS N_CURR_BE_IBNR_DIRECT_AMT_R,
		CASE WHEN LG.v_reserve_type_ind_r ='P'THEN NVL(LG.n_reserve_direct__field__r,0) ELSE 0 END AS N_CURR_FIELD_IBNR_DIRECT_AMT_R,
		CASE WHEN LG.v_reserve_type_ind_r ='I' THEN NVL(LG.n_reserve_direct__gaap__r,0)  ELSE 0 END AS N_CURR_GAAP_IBNR_DIRECT_AMT_R,
		CASE WHEN LG.v_reserve_type_ind_r ='I' THEN NVL(LG.n_reserve_direct__stat__r,0) ELSE 0 END AS N_CURR_STAT_IBNR_DIRECT_AMT_R,
		LG.n_chg_reserve_direct__field__r AS n_chg_reserve_direct__field__r,
		CASE WHEN LG.v_reserve_type_ind_r ='I' THEN NVL(LG.n_reserve_direct__gaap__r,0) - NVL(LG.n_chg_reserve_direct__gaap__r,0) ELSE 0 END AS N_PRIOR_GAAP_IBNR_DIRECT_AMT_R,
		CASE WHEN LG.v_reserve_type_ind_r ='I' THEN NVL(LG.n_chg_reserve_direct__gaap__r,0)  ELSE 0 END AS N_CHG_GAAP_IBNR_DIRECT_AMT_R,
		CASE WHEN LG.v_reserve_type_ind_r ='I' AND LD_SYSDATE <=DIM_TIME_R.D_CALENDAR_DATE_R THEN LG.n_chg_reserve_direct__gaap__r ELSE 0 END AS N_CUM_GAAP_IBNR_DIRECT_AMT_R,
		CASE WHEN LG.v_reserve_type_ind_r ='I' THEN NVL(LG.n_reserve_direct__stat__r,0) - NVL(LG.n_chg_reserve_direct__stat__r,0) ELSE 0 END AS N_PRIOR_STAT_IBNR_DIRECT_AMT_R,
		CASE WHEN LG.v_reserve_type_ind_r ='I' THEN NVL(LG.n_chg_reserve_direct__stat__r,0) ELSE 0 END AS  N_CHG_STAT_IBNR_DIRECT_AMT_R,
		CASE WHEN LG.v_reserve_type_ind_r ='I' AND LD_SYSDATE <=DIM_TIME_R.D_CALENDAR_DATE_R THEN LG.n_chg_reserve_direct__stat__r ELSE 0 END AS N_CUM_STAT_IBNR_DIRECT_AMT_R,
		CASE WHEN LG.v_reserve_type_ind_r ='P'THEN NVL(LG.n_reserve_direct_best_estmt_r,0) - NVL(LG.n_chg_rsrv_direct_best_estmt_r,0) ELSE 0 END AS N_PRIOR_BE_IBNR_DIRECT_AMT_R,
		CASE WHEN LG.v_reserve_type_ind_r ='P'THEN NVL(LG.n_chg_rsrv_direct_best_estmt_r,0) ELSE 0 END AS N_CHG_BE_IBNR_DIRECT_AMT_R,
		CASE WHEN LG.v_reserve_type_ind_r ='P'THEN NVL(LG.n_reserve_direct__field__r,0) - NVL(LG.n_chg_reserve_direct__field__r,0) ELSE  0 END AS N_PRIOR_FIELD_IBNR_DIR_AMT_R,
		CASE WHEN LG.v_reserve_type_ind_r ='P'THEN NVL(LG.n_chg_reserve_direct__field__r,0) ELSE  0 END AS  N_CHG_FIELD_IBNR_DIRECT_AMT_R,
		CASE WHEN LG.v_reserve_type_ind_r ='W'THEN NVL(LG.N_CHG_RESERVE_DIRECT__GAAP__R,0) ELSE  0 END AS  N_CHG_GAAP_WV_NET_AMT_R,
        CASE WHEN LG.v_reserve_type_ind_r ='W'THEN NVL(LG.N_CHG_RESERVE_DIRECT__STAT__R,0) ELSE  0 END AS  N_CHG_STAT_WV_NET_AMT_R,
		CASE WHEN LG.v_reserve_type_ind_r ='I' THEN NVL(LG.N_CHG_RESERVE_CEDED__STAT__R,0) ELSE 0 END AS N_CHG_STAT_IBNR_CEDED_AMT_R,
		CASE WHEN LG.v_reserve_type_ind_r ='I' THEN NVL(LG.N_CHG_RESERVE_CEDED__GAAP__R,0)  ELSE 0 END 	as N_CHG_GAAP_IBNR_CEDED_AMT_R,
		CASE WHEN V_PRODUCT_LINE_R = 'Group Life' THEN V_PRODUCT_LINE_R 
		WHEN V_PRODUCT_LINE_R = 'LTD' AND V_PRODUCT_SUB_LINE_CODE_R <> 'IDR' THEN V_PRODUCT_LINE_R
		WHEN V_PRODUCT_LINE_R = 'LTD' AND V_PRODUCT_SUB_LINE_CODE_R = 'IDR' THEN V_PRODUCT_SUB_LINE_CODE_R
		WHEN V_PRODUCT_LINE_R like 'Other A%H' AND V_PRODUCT_SUB_LINE_CODE_R LIKE '%STD%' THEN 'STD'
		WHEN V_PRODUCT_LINE_R like 'Other A%H' AND V_PRODUCT_SUB_LINE_CODE_R = 'SR' THEN V_PRODUCT_SUB_LINE_CODE_R
		WHEN V_PRODUCT_LINE_R like 'Other A%H' AND V_PRODUCT_SUB_LINE_CODE_R = 'VAR' THEN V_PRODUCT_SUB_LINE_CODE_R
		WHEN V_PRODUCT_LINE_R like 'Other A%H' AND V_PRODUCT_SUB_LINE_CODE_R = 'Pools' THEN V_PRODUCT_SUB_LINE_CODE_R
		WHEN V_PRODUCT_LINE_R like 'Other A%H' AND V_PRODUCT_SUB_LINE_CODE_R = 'Dental' THEN V_PRODUCT_SUB_LINE_CODE_R
		WHEN V_PRODUCT_LINE_R like 'Other A%H' AND V_PRODUCT_SUB_LINE_CODE_R = 'LESA' THEN V_PRODUCT_SUB_LINE_CODE_R  
		WHEN V_PRODUCT_LINE_R like 'Other A%H' AND V_PRODUCT_SUB_LINE_CODE_R = 'Mini-Med' THEN V_PRODUCT_SUB_LINE_CODE_R
		WHEN V_PRODUCT_LINE_R like 'Other A%H' AND V_PRODUCT_SUB_LINE_CODE_R = 'AdvantEdge' THEN V_PRODUCT_SUB_LINE_CODE_R
		WHEN V_PRODUCT_LINE_R like 'Other A%H' AND V_PRODUCT_SUB_LINE_CODE_R = 'VAI/VCI' THEN V_PRODUCT_SUB_LINE_CODE_R
		WHEN V_PRODUCT_LINE_R like 'Other A%H' AND V_PRODUCT_SUB_LINE_CODE_R = 'Stop Loss' THEN V_PRODUCT_SUB_LINE_CODE_R       
		ELSE V_PRODUCT_LINE_R                                                  
		END V_PRODUCT_LINE_R 
		FROM (select * from ATOMIC.FCT_LG_RESERVE_DETAILS_R where v_reserve_type_ind_r not in ('I', 'P')) LG
		LEFT OUTER JOIN ATOMIC.DIM_TIME_R
		ON  EXTRACT(YEAR FROM to_date(LG.d_reserve_valuation_date_r,'DD-MON-YY')) = DIM_TIME_R.N_YEAR_R
		AND EXTRACT (MONTH FROM to_date(LG.d_reserve_valuation_date_r,'DD-MON-YY')) = DIM_TIME_R.N_MONTH_R
		AND DIM_TIME_R.V_END_OF_FISCAL_MONTH_IND_R = 'Y'
		LEFT JOIN (select v_claim_coverage_code_r, n_product_sk_r, n_claim_sk_r from atomic.mvw_product_sk_lookup) mv on mv.v_claim_coverage_code_r = LG.v_coverage_code_r and mv.n_claim_sk_r = LG.n_claim_sk_r
		LEFT JOIN atomic.dim_grp_product_r product on product.n_product_sk_r = mv.n_product_sk_r
		LEFT OUTER JOIN (select n_policy_version_number_r,n_policy_sk_r, v_policy_prefix_r,v_policy_suffix_r from ATOMIC.dim_grp_policy_dir_r    
		where v_active_status_r ='Y' ) gpd
		on gpd.n_policy_sk_r = LG.N_POLICY_SK_R
		LEFT OUTER JOIN (select distinct n_version_number_r,N_POLICY_SK_R,n_cust_party_sk_r from  ATOMIC.fct_grp_policy_r  ) policy
		on policy.n_version_number_r = gpd.n_policy_version_number_r and policy.N_POLICY_SK_R = LG.N_POLICY_SK_R
		WHERE LG.d_reserve_valuation_date_r = to_date(ld_fic_mis_date)-1 
		UNION ALL
		select distinct 
		LD_SYSDATE AS D_AS_OF_DATE_R,
		DIM_TIME_R.D_CALENDAR_DATE_R AS D_CYCLE_DATE_R,
		LG.N_POLICY_SK_R as N_POLICY_SK_R,
		nvl(policy.N_CUST_PARTY_SK_R,-1) as N_PARTY_SK_R,
		gpd.v_policy_prefix_r,
		gpd.v_policy_suffix_r,
		trunc(LG.D_RESERVE_VALUATION_DATE_R,'MM') AS D_UW_DATE_R,
		coalesce(product.V_BASIC_PRODUCT_LINE_CODE_R, gpd.v_policy_prefix_r) AS V_COVERAGE_R,
		LG.v_reserve_type_ind_r AS V_RESERVE_TYPE_IND_R,
		LG.n_chg_reserve_direct__gaap__r AS N_CHG_RESERVE_DIRECT__GAAP__R,
		CASE WHEN LG.v_reserve_type_ind_r ='P'THEN NVL(LG.n_reserve_direct_best_estmt_r,0) ELSE 0 END AS N_CURR_BE_IBNR_DIRECT_AMT_R,
		CASE WHEN LG.v_reserve_type_ind_r ='P'THEN NVL(LG.n_reserve_direct__field__r,0) ELSE 0 END AS N_CURR_FIELD_IBNR_DIRECT_AMT_R,
		CASE WHEN LG.v_reserve_type_ind_r ='I' THEN NVL(LG.n_reserve_direct__gaap__r,0)  ELSE 0 END AS N_CURR_GAAP_IBNR_DIRECT_AMT_R,
		CASE WHEN LG.v_reserve_type_ind_r ='I' THEN NVL(LG.n_reserve_direct__stat__r,0) ELSE 0 END AS N_CURR_STAT_IBNR_DIRECT_AMT_R,
		LG.n_chg_reserve_direct__field__r AS n_chg_reserve_direct__field__r,
		CASE WHEN LG.v_reserve_type_ind_r ='I' THEN NVL(LG.n_reserve_direct__gaap__r,0) - NVL(LG.n_chg_reserve_direct__gaap__r,0) ELSE 0 END AS N_PRIOR_GAAP_IBNR_DIRECT_AMT_R,
		CASE WHEN LG.v_reserve_type_ind_r ='I' THEN NVL(LG.n_chg_reserve_direct__gaap__r,0)  ELSE 0 END AS N_CHG_GAAP_IBNR_DIRECT_AMT_R,
		CASE WHEN LG.v_reserve_type_ind_r ='I' AND LD_SYSDATE <=DIM_TIME_R.D_CALENDAR_DATE_R THEN LG.n_chg_reserve_direct__gaap__r ELSE 0 END AS N_CUM_GAAP_IBNR_DIRECT_AMT_R,
		CASE WHEN LG.v_reserve_type_ind_r ='I' THEN NVL(LG.n_reserve_direct__stat__r,0) - NVL(LG.n_chg_reserve_direct__stat__r,0) ELSE 0 END AS N_PRIOR_STAT_IBNR_DIRECT_AMT_R,
		CASE WHEN LG.v_reserve_type_ind_r ='I' THEN NVL(LG.n_chg_reserve_direct__stat__r,0) ELSE 0 END AS  N_CHG_STAT_IBNR_DIRECT_AMT_R,
		CASE WHEN LG.v_reserve_type_ind_r ='I' AND LD_SYSDATE <=DIM_TIME_R.D_CALENDAR_DATE_R THEN LG.n_chg_reserve_direct__stat__r ELSE 0 END AS N_CUM_STAT_IBNR_DIRECT_AMT_R,
		CASE WHEN LG.v_reserve_type_ind_r ='P'THEN NVL(LG.n_reserve_direct_best_estmt_r,0) - NVL(LG.n_chg_rsrv_direct_best_estmt_r,0) ELSE 0 END AS N_PRIOR_BE_IBNR_DIRECT_AMT_R,
		CASE WHEN LG.v_reserve_type_ind_r ='P'THEN NVL(LG.n_chg_rsrv_direct_best_estmt_r,0) ELSE 0 END AS N_CHG_BE_IBNR_DIRECT_AMT_R,
		CASE WHEN LG.v_reserve_type_ind_r ='P'THEN NVL(LG.n_reserve_direct__field__r,0) - NVL(LG.n_chg_reserve_direct__field__r,0) ELSE  0 END AS N_PRIOR_FIELD_IBNR_DIR_AMT_R,
		CASE WHEN LG.v_reserve_type_ind_r ='P'THEN NVL(LG.n_chg_reserve_direct__field__r,0) ELSE  0 END AS  N_CHG_FIELD_IBNR_DIRECT_AMT_R,
		CASE WHEN LG.v_reserve_type_ind_r ='W'THEN NVL(LG.N_CHG_RESERVE_DIRECT__GAAP__R,0) ELSE  0 END AS  N_CHG_GAAP_WV_NET_AMT_R,
        CASE WHEN LG.v_reserve_type_ind_r ='W'THEN NVL(LG.N_CHG_RESERVE_DIRECT__STAT__R,0) ELSE  0 END AS  N_CHG_STAT_WV_NET_AMT_R,
		CASE WHEN LG.v_reserve_type_ind_r ='I' THEN NVL(LG.N_CHG_RESERVE_CEDED__STAT__R,0) ELSE 0 END AS N_CHG_STAT_IBNR_CEDED_AMT_R,
		CASE WHEN LG.v_reserve_type_ind_r ='I' THEN NVL(LG.N_CHG_RESERVE_CEDED__GAAP__R,0)  ELSE 0 END 	as N_CHG_GAAP_IBNR_CEDED_AMT_R,
		CASE WHEN V_PRODUCT_LINE_R = 'Group Life' THEN V_PRODUCT_LINE_R 
		WHEN V_PRODUCT_LINE_R = 'LTD' AND V_PRODUCT_SUB_LINE_CODE_R <> 'IDR' THEN V_PRODUCT_LINE_R
		WHEN V_PRODUCT_LINE_R = 'LTD' AND V_PRODUCT_SUB_LINE_CODE_R = 'IDR' THEN V_PRODUCT_SUB_LINE_CODE_R
		WHEN V_PRODUCT_LINE_R like 'Other A%H' AND V_PRODUCT_SUB_LINE_CODE_R LIKE '%STD%' THEN 'STD'
		WHEN V_PRODUCT_LINE_R like 'Other A%H' AND V_PRODUCT_SUB_LINE_CODE_R = 'SR' THEN V_PRODUCT_SUB_LINE_CODE_R
		WHEN V_PRODUCT_LINE_R like 'Other A%H' AND V_PRODUCT_SUB_LINE_CODE_R = 'VAR' THEN V_PRODUCT_SUB_LINE_CODE_R
		WHEN V_PRODUCT_LINE_R like 'Other A%H' AND V_PRODUCT_SUB_LINE_CODE_R = 'Pools' THEN V_PRODUCT_SUB_LINE_CODE_R
		WHEN V_PRODUCT_LINE_R like 'Other A%H' AND V_PRODUCT_SUB_LINE_CODE_R = 'Dental' THEN V_PRODUCT_SUB_LINE_CODE_R
		WHEN V_PRODUCT_LINE_R like 'Other A%H' AND V_PRODUCT_SUB_LINE_CODE_R = 'LESA' THEN V_PRODUCT_SUB_LINE_CODE_R  
		WHEN V_PRODUCT_LINE_R like 'Other A%H' AND V_PRODUCT_SUB_LINE_CODE_R = 'Mini-Med' THEN V_PRODUCT_SUB_LINE_CODE_R
		WHEN V_PRODUCT_LINE_R like 'Other A%H' AND V_PRODUCT_SUB_LINE_CODE_R = 'AdvantEdge' THEN V_PRODUCT_SUB_LINE_CODE_R
		WHEN V_PRODUCT_LINE_R like 'Other A%H' AND V_PRODUCT_SUB_LINE_CODE_R = 'VAI/VCI' THEN V_PRODUCT_SUB_LINE_CODE_R
		WHEN V_PRODUCT_LINE_R like 'Other A%H' AND V_PRODUCT_SUB_LINE_CODE_R = 'Stop Loss' THEN V_PRODUCT_SUB_LINE_CODE_R       
		ELSE V_PRODUCT_LINE_R                                                  
		END V_PRODUCT_LINE_R 
		FROM(select * from ATOMIC.FCT_LG_RESERVE_DETAILS_R where v_reserve_type_ind_r in ('I', 'P')) LG
		LEFT OUTER JOIN ATOMIC.DIM_TIME_R
		ON  EXTRACT(YEAR FROM to_date(LG.d_reserve_valuation_date_r,'DD-MON-YY')) = DIM_TIME_R.N_YEAR_R
		AND EXTRACT (MONTH FROM to_date(LG.d_reserve_valuation_date_r,'DD-MON-YY')) = DIM_TIME_R.N_MONTH_R
		AND DIM_TIME_R.V_END_OF_FISCAL_MONTH_IND_R = 'Y'
		LEFT OUTER JOIN (select n_policy_version_number_r,n_policy_sk_r, v_policy_prefix_r,v_policy_suffix_r from ATOMIC.dim_grp_policy_dir_r    
		where v_active_status_r ='Y' ) gpd
		on gpd.n_policy_sk_r = LG.N_POLICY_SK_R
		LEFT JOIN ( SELECT * FROM ATOMIC.DIM_GRP_PRODUCT_R   where V_BASIC_PRODUCT_LINE_CODE_R is not null and V_PRODUCT_LINE_R <> 'Unknown') product
		ON CASE 
			WHEN LG.v_reserve_type_ind_r = 'I'
				THEN (
						CASE 
							WHEN gpd.v_policy_prefix_r = 'VCI'
								THEN 'VCI'
							WHEN gpd.v_policy_prefix_r = 'VAI'
								THEN 'VAI'
							ELSE LG.V_COVERAGE_CODE_R
							END
						)
			WHEN LG.v_reserve_type_ind_r = 'P'
				THEN LG.V_COVERAGE_CODE_R
			END = (
			CASE 
				WHEN LG.v_reserve_type_ind_r = 'I'
					THEN product.V_BASIC_PRODUCT_LINE_CODE_R
				ELSE product.V_COVERAGE_CODE_R
				END
			)
		LEFT OUTER JOIN (select distinct n_version_number_r,N_POLICY_SK_R,n_cust_party_sk_r from  ATOMIC.fct_grp_policy_r  ) policy
		on policy.n_version_number_r = gpd.n_policy_version_number_r and policy.N_POLICY_SK_R = LG.N_POLICY_SK_R
		WHERE LG.d_reserve_valuation_date_r = to_date(ld_fic_mis_date)-1;