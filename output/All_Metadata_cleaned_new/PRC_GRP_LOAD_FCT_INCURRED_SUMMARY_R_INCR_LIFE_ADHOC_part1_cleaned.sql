-- Cleaned for lineage: PRC_GRP_LOAD_FCT_INCURRED_SUMMARY_R_INCR_LIFE_ADHOC (part 1/2)

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
		FCS.N_Curr_Stat_Reserve_Direct_R *
		(power(1.04, (EXTRACT(YEAR FROM to_date(FCS.D_CYCLE_DATE_R,&apos;DD-MON-YY&apos;)) - EXTRACT(YEAR FROM to_date(NVL(claim.d_date_of_loss_r,FCS.D_CYCLE_DATE_R),&apos;DD-MON-YY&apos;)) )))
		AS N_CURR_STAT_PV_DIRECT_AMT_R,
		FCS.N_CURR_BE_RESERVE_DIRECT_AMT_R * 
		(power(1.04, (EXTRACT(YEAR FROM to_date(FCS.D_CYCLE_DATE_R,&apos;DD-MON-YY&apos;)) - EXTRACT(YEAR FROM to_date(NVL(claim.d_date_of_loss_r,FCS.D_CYCLE_DATE_R),&apos;DD-MON-YY&apos;)) )))
		AS N_CURR_BE_PV_DIRECT_AMT_R,
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