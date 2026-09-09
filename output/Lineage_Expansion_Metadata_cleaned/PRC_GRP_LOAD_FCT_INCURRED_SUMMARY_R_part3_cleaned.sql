-- Cleaned for lineage: PRC_GRP_LOAD_FCT_INCURRED_SUMMARY_R (part 3/4)

Insert into table TMP_FCT_RPT_ACT_PLR_SUMMARY_R';

INSERT  INTO  ATOMIC.tmp_FCT_RPT_ACT_PLR_SUMMARY_R 
        Select  * from (
        WITH FCT_RPT_ACT_PLR_SUMMARY_R_TABLE AS
        (
        SELECT DISTINCT
        D_CYCLE_DATE_R,
        N_POLICY_SK_R,
        N_party_sk_r,
        N_Permissable_LR_R AS N_CURR_PLR_R,
        N_SOLD_ANNUALIZED_PREM_R AS N_SOLD_ANNUALIZED_PREM_R,
        DENSE_RANK() OVER ( PARTITION BY N_POLICY_SK_R, N_party_sk_r ORDER BY D_CYCLE_DATE_R) RK
        FROM ATOMIC.FCT_RPT_ACT_PLR_SUMMARY_R   FACS
        WHERE  N_party_sk_r <> -1
        )
        ,
        FCT_RPT_ACT_PLR_SUMMARY_R_TABLE_1 AS
        (
        SELECT * from FCT_RPT_ACT_PLR_SUMMARY_R_TABLE
        ),
        FCT_RPT_ACT_PLR_SUMMARY_R_TABLE_CALC AS
        (
        SELECT
        LD_SYSDATE AS D_AS_OF_DATE_R,
        FACS.D_CYCLE_DATE_R  AS D_CYCLE_DATE_R_START,
        NVL(FCT_RPT_ACT_PLR_SUMMARY_R_TABLE_1.D_CYCLE_DATE_R,LD_sysdate) AS D_CYCLE_DATE_R_END,
        FACS.N_POLICY_SK_R,
        nvl(FACS.N_party_sk_r,-1) as N_party_sk_r,
        pol_dir.v_policy_prefix_r,
        pol_dir.v_policy_suffix_r,
        FACS.N_CURR_PLR_R,
        FACS.N_SOLD_ANNUALIZED_PREM_R AS N_SOLD_ANNUALIZED_PREM_R
        FROM FCT_RPT_ACT_PLR_SUMMARY_R_TABLE FACS
        LEFT JOIN (SELECT * FROM ATOMIC.dim_grp_policy_dir_r   WHERE v_active_status_r='Y') pol_dir
        ON FACS.N_POLICY_SK_R=pol_dir.N_POLICY_SK_R
        LEFT JOIN FCT_RPT_ACT_PLR_SUMMARY_R_TABLE_1
        ON FACS.N_POLICY_SK_R = FCT_RPT_ACT_PLR_SUMMARY_R_TABLE_1.N_POLICY_SK_R
        AND FACS.N_party_sk_r = FCT_RPT_ACT_PLR_SUMMARY_R_TABLE_1.N_party_sk_r
        AND FACS.RK + 1 = FCT_RPT_ACT_PLR_SUMMARY_R_TABLE_1.RK
        )
        SELECT DIM_TIME_R.D_CALENDAR_DATE_R AS D_CYCLE_DATE_R,trunc(DIM_TIME_R.D_CALENDAR_DATE_R, 'mm') AS d_uw_date_r, FCT_RPT_ACT_PLR_SUMMARY_R_TABLE_CALC.* 
        FROM FCT_RPT_ACT_PLR_SUMMARY_R_TABLE_CALC, DIM_TIME_R
        Where D_CALENDAR_DATE_R >= D_CYCLE_DATE_R_START and  D_CALENDAR_DATE_R < D_CYCLE_DATE_R_END AND DIM_TIME_R.V_END_OF_FISCAL_MONTH_IND_R = 'Y'
        and D_CYCLE_DATE_R_START = (select max(D_CYCLE_DATE_R_START) from (SELECT t.D_CALENDAR_DATE_R ,c.D_CYCLE_DATE_R_START
        FROM FCT_RPT_ACT_PLR_SUMMARY_R_TABLE_CALC c, DIM_TIME_R t
        Where t.D_CALENDAR_DATE_R >= c.D_CYCLE_DATE_R_START
        and  t.D_CALENDAR_DATE_R < c.D_CYCLE_DATE_R_END
        AND t.V_END_OF_FISCAL_MONTH_IND_R = 'Y'
        and t.D_CALENDAR_DATE_R = DIM_TIME_R.D_CALENDAR_DATE_R))
        and D_CYCLE_DATE_R_END = (select min(D_CYCLE_DATE_R_END) from (SELECT t.D_CALENDAR_DATE_R ,c.D_CYCLE_DATE_R_END
        FROM FCT_RPT_ACT_PLR_SUMMARY_R_TABLE_CALC c, DIM_TIME_R t
        Where t.D_CALENDAR_DATE_R >= c.D_CYCLE_DATE_R_START
        and  t.D_CALENDAR_DATE_R < c.D_CYCLE_DATE_R_END
        AND t.V_END_OF_FISCAL_MONTH_IND_R = 'Y'
        and t.D_CALENDAR_DATE_R = DIM_TIME_R.D_CALENDAR_DATE_R)
        )
        order by N_POLICY_SK_R, N_party_sk_r,D_CYCLE_DATE_R_START) A
        where (EXTRACT(YEAR FROM to_date(D_CYCLE_DATE_R,'DD-MON-YY'))= LN_CURR_YEAR) 
        order by D_CYCLE_DATE_R;

Insert into tbl TMP_FCT_RPT_ANN_PREM_SUMMARY_R';

INSERT   INTO  ATOMIC.tmp_FCT_RPT_ANN_PREM_SUMMARY_R 
        SELECT
        LD_SYSDATE AS D_AS_OF_DATE_R,
        DIM_TIME_R.D_CALENDAR_DATE_R AS D_CYCLE_DATE_R,
        FAPS.N_POLICY_SK_R,
        pol_dir.v_policy_prefix_r,
        pol_dir.v_policy_suffix_r,
        nvl(FP.N_CUST_PARTY_SK_R,-1) AS N_party_sk_r,
        trunc(FAPS.D_DUE_DATE_R,'MM') AS D_UW_DATE_R,
        product.V_BASIC_PRODUCT_LINE_CODE_R AS V_COVERAGE_R,
        FAPS.N_ANNUALIZED_PREMIUM_R AS N_CURR_ANNUALIZED_PREMIUM_R,
        FAPS.N_YTD_CURR_POLICY_LIVES_R AS N_CURR_NUMBER_OF_LIVES_R,
        FAPS.N_GROSS_LIVES_R AS N_GROSS_LIVES_R,
		product.V_PRODUCT_LINE_R as V_PRODUCT_LINE_R,
		product.V_PRODUCT_SUB_LINE_CODE_R as V_PRODUCT_SUB_LINE_CODE_R
        FROM ATOMIC.FCT_RPT_ANN_PREM_SUMMARY_R   FAPS
        LEFT OUTER JOIN ATOMIC.DIM_TIME_R
        ON  EXTRACT(YEAR FROM to_date(FAPS.D_CYCLE_DATE_R,'DD-MON-YY')) = DIM_TIME_R.N_YEAR_R
        AND EXTRACT (MONTH FROM to_date(FAPS.D_CYCLE_DATE_R,'DD-MON-YY')) = DIM_TIME_R.N_MONTH_R
        AND DIM_TIME_R.V_END_OF_FISCAL_MONTH_IND_R = 'Y'
        LEFT JOIN ( SELECT * FROM ATOMIC.DIM_GRP_PRODUCT_R   where V_BASIC_PRODUCT_LINE_CODE_R is not null) product
        ON FAPS.V_COVERAGE_CODE_R=product.V_COVERAGE_CODE_R
        LEFT JOIN (SELECT * FROM ATOMIC.dim_grp_policy_dir_r   WHERE v_active_status_r='Y' ) pol_dir
        ON FAPS.N_POLICY_SK_R=pol_dir.N_POLICY_SK_R
        LEFT JOIN (select distinct n_version_number_r,N_POLICY_SK_R,n_cust_party_sk_r from  ATOMIC.fct_grp_policy_r  ) FP
        ON FP.n_policy_sk_r= FAPS.n_policy_sk_r
        AND FP.n_version_number_r=pol_dir.n_policy_version_number_r
        WHERE 
        FAPS.D_DUE_DATE_R IS NOT NULL
		And FAPS.D_CYCLE_DATE_R=to_date(ld_fic_mis_date)-1 
        AND FAPS.N_POLICY_SK_R <> -1;

Insert into tbl TMP_FCT_RPT_CLAIM_SUMMARY_R';