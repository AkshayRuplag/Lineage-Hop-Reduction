-- Cleaned for lineage: PRC_GRP_LOAD_FCT_INCURRED_SUMMARY_R (part 1/4)

Insert into table TMP_FCT_CLAIM_PAYMENT_DETAIL_R';

INSERT  INTO  atomic.tmp_FCT_CLAIM_PAYMENT_DETAIL_R 
              WITH fct_grp_policy_r_table AS
        (
        select distinct n_version_number_r,N_POLICY_SK_R,n_cust_party_sk_r from  ATOMIC.fct_grp_policy_r 
        ),
        BASE AS
        (
        select LD_SYSDATE AS D_AS_OF_DATE_R, a.d_calendar_date_r as D_CYCLE_DATE_R,pd.N_POLICY_SK_R, nvl(FP.n_cust_party_sk_r,-1) AS n_party_sk_r,  
        pd.v_policy_prefix_r, pd.v_policy_suffix_r, trunc(CD.D_DATE_OF_LOSS_R,'MM') AS D_UW_DATE_R, dp.V_BASIC_PRODUCT_LINE_CODE_R AS V_COVERAGE_R,
        EXTRACT(MONTH FROM cd.D_DATE_OF_LOSS_R) as D_UW_DATE_MONTH_R, EXTRACT(YEAR FROM cd.D_DATE_OF_LOSS_R) as D_UW_DATE_YEAR_R, 
        round(sum((case when c.v_check_number_r is not null then CASE WHEN (c.V_BENEFIT_CODE_R in ('FIC','MED') and v_record_type_r = 'Benefit Payment') 
        then -1* nvl(c.N_PAID_CLAIM_BENEFITS_R,0) when (c.V_BENEFIT_group_R in ('FIC','MED') and v_record_type_r = 'Adjustment')
        then  nvl(c.N_PAID_CLAIM_BENEFITS_R,0) when V_BENEFIT_GROUP_R in ('098', '097', '099', '297',  '298') then 0 
        when v_record_type_r in ('Adjustment') then (case when v_benefit_group_r is not null then nvl(c.N_PAID_CLAIM_BENEFITS_R,0)else 0 end) 
        when  v_record_type_r in ('Redirect') then nvl(c.N_PAID_AMOUNT_R,0)
        when V_BENEFIT_CODE_R is null then 0 
        Else nvl(c.N_PAID_CLAIM_BENEFITS_R,0) end 
        else 0 end) ),2)  AS LOSS_AMOUNT,c.N_TOTAL_REINSURANCE_PCT_R as N_TOTAL_REINSURANCE_PCT_R 
        from 
           (select a.d_calendar_date_r, N_FISCAL_MONTH_R, n_fiscal_year_r  
           from atomic.DIM_TIME_R a
           where  a.V_END_OF_FISCAL_MONTH_IND_R = 'Y')a, 
           atomic.dim_time_r b, 
           atomic.FCT_CLAIM_PAYMENT_DETAIL_R   c,
           (select cd.v_claim_number_r, cd.n_claim_sk_r, 
              cd.v_active_status_r,cd.n_policy_sk_r,
               case when cd.v_claim_number_r like '%VAI%' 
               and cd.V_SOURCE_SYSTEM_NAME_R = 'PACS' 
               then d.d_date_of_event_r else cd.d_date_of_loss_r end d_date_of_loss_r
                from  atomic.dim_grp_claim_dir_r   cd , dim_grp_claim_detail_r   d
              where cd.n_claim_sk_r = d.n_claim_sk_r
              and cd.v_active_status_r = 'Y'
              and d.v_active_status_r = 'Y')cd, 
           atomic.dim_grp_policy_dir_r   pd, 
           atomic.DIM_GRP_PRODUCT_R   dp, 
           fct_grp_policy_r_table fp,
           mvw_product_sk_lookup   mv
           where 
           b.D_Calendar_date_r = c.D_PAID_DATE_R
           and  a.n_fiscal_month_r = b.n_fiscal_month_r
           and a.n_fiscal_year_r = b.n_Fiscal_year_r
           and c.v_claim_number_r = cd.v_claim_number_r
           and cd.n_policy_sk_r = pd.n_policy_sk_r
           and pd.v_active_status_r = 'Y'
           and cd.v_active_status_r = 'Y'
           and FP.n_policy_sk_r= pd.n_policy_sk_r
           and fp.n_version_number_r=pd.n_policy_version_number_r
           and extract(year from a.d_calendar_date_r)=LN_CURR_YEAR
           and mv.v_claim_number_r = cd.v_claim_number_r
           and mv.n_claim_sk_r = cd.n_claim_sk_r
           and mv.v_claim_coverage_code_r = c.v_coverage_code_r
            and dp.V_BASIC_PRODUCT_LINE_CODE_R is not null
           and mv.N_PRODUCT_SK_R=dp.N_PRODUCT_SK_R
           group by  a.d_calendar_date_r, pd.N_POLICY_SK_R,FP.n_cust_party_sk_r, pd.v_policy_prefix_r, pd.v_policy_suffix_r,dp.V_BASIC_PRODUCT_LINE_CODE_R, 
           CD.D_DATE_OF_LOSS_R, 
           EXTRACT(MONTH FROM cd.D_DATE_OF_LOSS_R), EXTRACT(YEAR FROM cd.D_DATE_OF_LOSS_R),c.N_TOTAL_REINSURANCE_PCT_R
        )       
        SELECT 
        D_AS_OF_DATE_R
        ,D_CYCLE_DATE_R
        ,N_POLICY_SK_R
        ,n_party_sk_r
        ,V_POLICY_PREFIX_R
        ,V_POLICY_SUFFIX_R
        ,D_UW_DATE_R
        ,V_COVERAGE_R
        ,D_UW_DATE_MONTH_R
        ,D_UW_DATE_YEAR_R
        ,SUM(LOSS_AMOUNT) AS LOSS_AMOUNT 
		,SUM(LOSS_AMOUNT * (NVL(N_TOTAL_REINSURANCE_PCT_R,0)/100)) as N_LOSS_PAYMENT_CEDED_AMT_R
        FROM BASE 
        GROUP BY D_AS_OF_DATE_R
        ,D_CYCLE_DATE_R
        ,N_POLICY_SK_R
        ,n_party_sk_r
        ,V_POLICY_PREFIX_R
        ,V_POLICY_SUFFIX_R
        ,D_UW_DATE_R
        ,V_COVERAGE_R
        ,D_UW_DATE_MONTH_R
        ,D_UW_DATE_YEAR_R;

Insert into table TMP_FCT_LG_RESERVE_DETAILS_R';