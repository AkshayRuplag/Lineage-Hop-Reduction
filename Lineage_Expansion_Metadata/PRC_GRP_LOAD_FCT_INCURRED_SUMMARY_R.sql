--------------------------------------------------------
--  DDL for Procedure PRC_GRP_LOAD_FCT_INCURRED_SUMMARY_R
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "ATOMIC"."PRC_GRP_LOAD_FCT_INCURRED_SUMMARY_R" 
AS
/*
--27-Nov-2023 : Changed Fisc Month ENd to Fisc Month End +1
--28-dEC-2023 : cHANGED TO_DATE(d_cycle_date_r)=TO_DATE(ld_fic_mis_date) TO TO_DATE(d_cycle_date_r)=TO_DATE(ld_fic_mis_date)-1
--29-Oct-2024 : As requested by Gisha and Erica the given SELECT queries which populates below temp tables has been added and the existing logic has been commented
                 TMP_FCT_CLAIM_PAYMENT_DETAIL_R
                 TMP_FCT_LG_RESERVE_DETAILS_R
                 TMP_FCT_RPT_ACT_PLR_SUMMARY_R
                 TMP_FCT_RPT_ANN_PREM_SUMMARY_R
                 TMP_FCT_RPT_CLAIM_SUMMARY_R
                 TMP_FCT_RPT_PREMIUM_SUMMARY_R
--29-Oct-2024 : In the insert of TMP_FCT_RPT_ANN_PREM_SUMMARY_R	under the select query below changes happened - Mereen		
                --FAPS.N_COVERAGE_LIVES_R AS N_CURR_NUMBER_OF_LIVES_R,     --Erica changes
                FAPS.N_YTD_CURR_POLICY_LIVES_R AS N_CURR_NUMBER_OF_LIVES_R,--Erica changes
				In the insert of FCT_INCURRED_SUMMARY_R	under the select query below changes happened - Mereen
                --sum(N_GROSS_LIVES_R) AS N_CURR_NUMBER_OF_LIVES_R        --Erica changes
                sum(N_CURR_NUMBER_OF_LIVES_R) AS N_CURR_NUMBER_OF_LIVES_R --Erica changes

--05-Nov-2024 : Introduced new column N_CURR_OPEN_FIELD_OS_DIRECT_AMT_R in TMP_FCT_RPT_CLAIM_SUMMARY_R
--06-Nov-2024 : As per Mereen changed below join from policy number to policy sk in TMP_FCT_RPT_PREMIUM_SUMMARY_R
                --ON FRS.v_policy_number_r=pol_dir.v_policy_number_r--06-Nov-24 changes
                ON FRS.n_policy_sk_r=pol_dir.n_policy_sk_r          --06-Nov-24 changes

Old
---
7.	FCT_LG_RESERVE_DETAILS_R 
  a.	fiscal month end +1 day schedule
  b.	Truncates current year data in temp tables and loads current year data in temp tables and then inserts data into final table based on WHERE d_cycle_date_r = current fiscal month end date
  c. Dependent EDW Tables and tidal jobs

     FCT_RPT_ACT_PLR_SUMMARY_R 
     FCT_RPT_ANN_PREM_SUMMARY_R 
     FCT_RPT_CLAIM_SUMMARY_R 
     mvw_product_sk_lookup 
     FCT_RPT_PREMIUM_SUMMARY_R 
     fct_grp_policy_r 
     dim_grp_claim_dir_r 
     dim_grp_claim_detail_r 
     FCT_LG_RESERVE_DETAILS_R 
     DIM_TIME_R
     dim_grp_policy_dir_r 
     DIM_GRP_PRODUCT_R 
     DIM_GRP_party_dir_r 
	 FCT_CLAIM_PAYMENT_DETAIL_R -View

     EDP_EDW_GRP_LOAD_FCT_RPT_ACT_PLR_SUMMARY_R
     EDP_EDW_GRP_LOAD_FCT_RPT_ANN_PREM_SUMMARY_R
     EDP_EDW_GRP_PACS_LOAD_FCT_RPT_CLAIM_SUMMARY_R_INCR
     EDP_EDW_GRP_LOAD_TOTAL_EARN_PREM_FCT_RPT_PREMIUM_SUMMARY_R
     EDP_EDW_GRP_LOAD_FCT_LG_RESERVE_DETAILS_R
     EDP_EDW_GRP_MV_REFRESH_MVW_PRODUCT_SK_LOOKUP
     EDP_ODI_EDW_GRP_PACS_LOAD_FCT_GRP_POLICY_R
     EDP_ODI_EDW_GRP_VUE_LOAD_VUE_FCT_GRP_POLICY_R
     EDP_ODI_EDW_EIS_SHINKA_LOAD_FCT_GRP_POLICY_R
     EDP_ODI_EDW_GRP_PACS_LOAD_DIM_GRP_CLAIM_DIR_R
     EDP_ODI_EDW_CV_SHINKA_LOAD_DIM_GRP_CLAIM_DIR_R
     EDP_ODI_EDW_GRP_PACS_LOAD_DIM_GRP_CLAIM_DETAIL_R
     EDP_ODI_EDW_CV_SHINKA_LOAD_DIM_GRP_CLAIM_DETAIL_R
     EDP_ODI_EDW_GRP_STACS_LOAD_DIM_GRP_POLICY_DIR_R
     EDP_ODI_EDW_GRP_PACS_LOAD_DIM_GRP_POLICY_DIR_R
     EDP_ODI_EDW_GRP_VUE_LOAD_DIM_GRP_POLICY_DIR_R
     EDP_ODI_EDW_CV_SHINKA_LOAD_DIM_GRP_POLICY_DIR_R
     EDP_ODI_EDW_EIS_SHINKA_LOAD_DIM_GRP_POLICY_DIR_R
     EDP_ODI_EDW_GRP_STACS_LOAD_DIM_GRP_PARTY_DIR_R
     EDP_ODI_EDW_GRP_PACS_LOAD_DIM_GRP_PARTY_DIR_R
     EDP_ODI_EDW_GRP_VUE_LOAD_DIM_GRP_PARTY_DIR_R
     EDP_ODI_EDW_CV_SHINKA_LOAD_DIM_GRP_PARTY_DIR_R
     EDP_ODI_EDW_EIS_SHINKA_LOAD_DIM_GRP_PARTY_DIR_R
	 EDP_EDW_GRP_PACS_LOAD_FCT_BENEFIT_PAYMENT_DETAIL_R_OFFSET1
	 EDP_EDW_GRP_PACS_LOAD_FCT_BENEFIT_PAYMENT_DETAIL_R_OFFSET2
	 EDP_EDW_GRP_PACS_LOAD_FCT_BENEFIT_PAYMENT_DETAIL_R_OFFSET3
	 EDP_EDW_PACS_LOAD_FCT_CLAIM_PAYMENT_DETAIL_R_ADJUSTMENT
	 EDP_EDW_PACS_LOAD_FCT_CLAIM_PAYMENT_DETAIL_R_DISBURSEMENT
	 EDP_EDW_PACS_LOAD_FCT_CLAIM_PAYMENT_DETAIL_R_EXPENSE
	 EDP_EDW_GRP_MV_REFRESH_FCT_BENEFIT_PAYMENT_DETAIL_OFFSET_MV_TBL
	 EDP_ODI_EDW_GRP_PACS_LOAD_FCT_CLAIM_PAYMENT_DETAIL_R_BENEFIT_PAYMENT
	 EDP_ODI_EDW_GRP_PACS_LOAD_FCT_CLAIM_PAYMENT_DETAIL_R_GROSS_BENEFIT
*/
--lc_bkp_tbl_str  VARCHAR2(10):=TO_CHAR(SYSDATE,'MMDDSS');
lc_sqlcode      VARCHAR2(300);
LC_SQLERRM       VARCHAR2(4000);
ld_sysdate      DATE:=SYSDATE;
lt_systimestamp TIMESTAMP:=ld_sysdate;
lc_trcmsg       VARCHAR2(4000):='Trace Message:->';
ln_start_time   NUMBER;
ld_fic_mis_date DATE;
LC_DAY          VARCHAR2(30);
ln_n_batch_id_r number:=to_number(to_char(ld_sysdate,'YYYYMMDD'));
--ln_curr_month   number:=TO_NUMBER(to_char(SYSDATE -1,'YYYYMM'));
ln_curr_year   number:=TO_NUMBER(to_char(ld_sysdate,'YYYY'));
LN_CNT         number:=0;
BEGIN
   lc_trcmsg:=lc_trcmsg||chr(13)||'Entered into Procedure PRC_GRP_LOAD_FCT_INCURRED_SUMMARY_R';
   /*lc_trcmsg:=lc_trcmsg||chr(13)||'2 Get Day';
   SELECT TO_CHAR(SYSDATE,'DAY')
      INTO LC_DAY
      FROM DUAL;
   lc_trcmsg:=lc_trcmsg||chr(13)||'2.1 Day is:->'||LC_DAY;*/

  -- lc_trcmsg:=lc_trcmsg||chr(13)||'a. Get Fiscal Month End Date +1 ';
   lc_trcmsg:=lc_trcmsg||chr(13)||'a. Get Fiscal Month End Date  ';
      --SELECT D_CALENDAR_DATE_R +1 INTO ld_fic_mis_date
      --SELECT D_CALENDAR_DATE_R  INTO ld_fic_mis_date--27-Nov-2023 changes
SELECT D_CALENDAR_DATE_R + 1  INTO ld_fic_mis_date--27-Nov-2023 changes
      FROM atomic.DIM_TIME_R D
      WHERE  V_END_OF_FISCAL_MONTH_IND_R = 'Y'
      and to_char(d_calendar_date_r,'YYYYMM')=to_char(LD_sysdate,'YYYYMM');
   --lc_trcmsg:=lc_trcmsg||chr(13)||'a.1 Fiscal Month End Date +1 is :->'||ld_fic_mis_date;
   lc_trcmsg:=lc_trcmsg||chr(13)||'a.1 Fiscal Month End Date is :->'||ld_fic_mis_date;


   IF TO_DATE(ld_fic_mis_date) = TO_DATE(ld_sysdate)  --to load data on next day of Fiscal Month (Ex:the fiscal month end for May 2023 is 26-MAY-23 so we should load this on 27-MAY-23)
   --OR TRIM(LC_DAY)='SATURDAY'-- or to load data on Saturday
   THEN




        lc_trcmsg:=lc_trcmsg||chr(13)||'1.Truncate tbl TMP_FCT_CLAIM_PAYMENT_DETAIL_R';
        execute immediate 'TRUNCATE TABLE ATOMIC.TMP_FCT_CLAIM_PAYMENT_DETAIL_R purge snapshot log';
        lc_trcmsg:=lc_trcmsg||chr(13)||'1.1 Truncated tbl TMP_FCT_CLAIM_PAYMENT_DETAIL_R';
        lc_trcmsg:=lc_trcmsg||chr(13)||'2.Truncate tbl TMP_FCT_LG_RESERVE_DETAILS_R';
        execute immediate 'TRUNCATE TABLE ATOMIC.TMP_FCT_LG_RESERVE_DETAILS_R   purge snapshot log';
        lc_trcmsg:=lc_trcmsg||chr(13)||'2.1 Truncated tbl TMP_FCT_LG_RESERVE_DETAILS_R';
        lc_trcmsg:=lc_trcmsg||chr(13)||'3.Truncate tbl TMP_FCT_RPT_ACT_PLR_SUMMARY_R';
        execute immediate 'TRUNCATE TABLE ATOMIC.TMP_FCT_RPT_ACT_PLR_SUMMARY_R  purge snapshot log';
        lc_trcmsg:=lc_trcmsg||chr(13)||'3.1 Truncated tbl TMP_FCT_RPT_ACT_PLR_SUMMARY_R';
        lc_trcmsg:=lc_trcmsg||chr(13)||'4.Truncate tbl TMP_FCT_RPT_ANN_PREM_SUMMARY_R';
        execute immediate 'TRUNCATE TABLE ATOMIC.TMP_FCT_RPT_ANN_PREM_SUMMARY_R purge snapshot log';
        lc_trcmsg:=lc_trcmsg||chr(13)||'4.1 Truncated tbl TMP_FCT_RPT_ANN_PREM_SUMMARY_R';
        lc_trcmsg:=lc_trcmsg||chr(13)||'5.Truncate tbl TMP_FCT_RPT_CLAIM_SUMMARY_R';
        execute immediate 'TRUNCATE TABLE ATOMIC.TMP_FCT_RPT_CLAIM_SUMMARY_R    purge snapshot log';
        lc_trcmsg:=lc_trcmsg||chr(13)||'5.1. Truncated tbl TMP_FCT_RPT_CLAIM_SUMMARY_R';
        lc_trcmsg:=lc_trcmsg||chr(13)||'6.Truncate tbl TMP_FCT_RPT_PREMIUM_SUMMARY_R';
        execute immediate 'TRUNCATE TABLE ATOMIC.TMP_FCT_RPT_PREMIUM_SUMMARY_R  purge snapshot log';
        lc_trcmsg:=lc_trcmsg||chr(13)||'6.1 Truncated tbl TMP_FCT_RPT_PREMIUM_SUMMARY_R';

        lc_trcmsg:=lc_trcmsg||chr(13)||'7. Insert into table TMP_FCT_CLAIM_PAYMENT_DETAIL_R';

        ln_start_time:=DBMS_UTILITY.GET_TIME;
        --29-Oct-2024 change starts
		/*INSERT   INTO  atomic.tmp_FCT_CLAIM_PAYMENT_DETAIL_R
              WITH fct_grp_policy_r_table AS
        (
        select distinct n_version_number_r,N_POLICY_SK_R,n_cust_party_sk_r from  ATOMIC.fct_grp_policy_r 
        --where n_policy_sk_r = '177247'
        ),
        BASE AS
        (
        --select SYSDATE AS D_AS_OF_DATE_R, a.d_calendar_date_r as D_CYCLE_DATE_R,pd.N_POLICY_SK_R, nvl(FP.n_cust_party_sk_r,-1) AS n_party_sk_r,
        select ld_sysdate AS D_AS_OF_DATE_R, a.d_calendar_date_r as D_CYCLE_DATE_R,pd.N_POLICY_SK_R, nvl(FP.n_cust_party_sk_r,-1) AS n_party_sk_r,
        pd.v_policy_prefix_r, pd.v_policy_suffix_r, trunc(CD.D_DATE_OF_LOSS_R,'MM') AS D_UW_DATE_R, dp.V_BASIC_PRODUCT_LINE_CODE_R AS V_COVERAGE_R,
        EXTRACT(MONTH FROM cd.D_DATE_OF_LOSS_R) as D_UW_DATE_MONTH_R, EXTRACT(YEAR FROM cd.D_DATE_OF_LOSS_R) as D_UW_DATE_YEAR_R,
        round(sum((case when c.v_check_number_r is not null then CASE WHEN (c.V_BENEFIT_CODE_R in ('FIC','MED') and v_record_type_r = 'Benefit Payment')
        then -1* nvl(c.N_PAID_CLAIM_BENEFITS_R,0) when (c.V_BENEFIT_group_R in ('FIC','MED') and v_record_type_r = 'Adjustment')
        then  nvl(c.N_PAID_CLAIM_BENEFITS_R,0) when V_BENEFIT_GROUP_R in ('098', '097', '099', '297',  '298') then 0
        when v_record_type_r in ('Adjustment') then (case when v_benefit_group_r is not null then nvl(c.N_PAID_CLAIM_BENEFITS_R,0)else 0 end)
        when  v_record_type_r in ('Redirect') then nvl(c.N_PAID_AMOUNT_R,0)
        when V_BENEFIT_CODE_R is null then 0
        Else nvl(c.N_PAID_CLAIM_BENEFITS_R,0) end
        else 0 end) ),2)  AS LOSS_AMOUNT

        from
           (select a.d_calendar_date_r, N_FISCAL_MONTH_R, n_fiscal_year_r
           from atomic.DIM_TIME_R a
           where  a.V_END_OF_FISCAL_MONTH_IND_R = 'Y')a,
           atomic.dim_time_r b,
           atomic.FCT_CLAIM_PAYMENT_DETAIL_R  c,
           (select cd.v_claim_number_r, cd.n_claim_sk_r,
              cd.v_active_status_r,cd.n_policy_sk_r,
               case when cd.v_claim_number_r like '%VAI%'
               and cd.V_SOURCE_SYSTEM_NAME_R = 'PACS'
               then d.d_date_of_event_r else cd.d_date_of_loss_r end d_date_of_loss_r
                from  atomic.dim_grp_claim_dir_r  cd , dim_grp_claim_detail_r  d
              where cd.n_claim_sk_r = d.n_claim_sk_r
              and cd.v_active_status_r = 'Y'
              and d.v_active_status_r = 'Y')cd,
           atomic.dim_grp_policy_dir_r  pd,
           atomic.DIM_GRP_PRODUCT_R  dp,
           fct_grp_policy_r_table fp,
           mvw_product_sk_lookup  mv
           where
           b.D_Calendar_date_r = c.D_PAID_DATE_R
           and  a.n_fiscal_month_r = b.n_fiscal_month_r
           and a.n_fiscal_year_r = b.n_Fiscal_year_r
           --and pd.n_policy_sk_r = '177247'
           -- and c.V_RECORD_TYPE_R = 'Benefit Payment'
           and c.v_claim_number_r = cd.v_claim_number_r
           and cd.n_policy_sk_r = pd.n_policy_sk_r
           and pd.v_active_status_r = 'Y'
           and cd.v_active_status_r = 'Y'
           and FP.n_policy_sk_r= pd.n_policy_sk_r
           and fp.n_version_number_r=pd.n_policy_version_number_r
           and extract(year from a.d_calendar_date_r)=LN_CURR_YEAR--2023
           and mv.v_claim_number_r = cd.v_claim_number_r
           and mv.n_claim_sk_r = cd.n_claim_sk_r
           and mv.v_claim_coverage_code_r = c.v_coverage_code_r
            and dp.V_BASIC_PRODUCT_LINE_CODE_R is not null
           and mv.N_PRODUCT_SK_R=dp.N_PRODUCT_SK_R
           group by  a.d_calendar_date_r, pd.N_POLICY_SK_R,FP.n_cust_party_sk_r, pd.v_policy_prefix_r, pd.v_policy_suffix_r,dp.V_BASIC_PRODUCT_LINE_CODE_R,
           CD.D_DATE_OF_LOSS_R,
           EXTRACT(MONTH FROM cd.D_DATE_OF_LOSS_R), EXTRACT(YEAR FROM cd.D_DATE_OF_LOSS_R)
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
        */
        INSERT /*+APPEND_VALUES*/ INTO  atomic.tmp_FCT_CLAIM_PAYMENT_DETAIL_R 
              WITH fct_grp_policy_r_table AS
        (
        select distinct n_version_number_r,N_POLICY_SK_R,n_cust_party_sk_r from  ATOMIC.fct_grp_policy_r 
        --where n_policy_sk_r = '177247'
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
           --and pd.n_policy_sk_r = '177247'
           -- and c.V_RECORD_TYPE_R = 'Benefit Payment'
           and c.v_claim_number_r = cd.v_claim_number_r
           and cd.n_policy_sk_r = pd.n_policy_sk_r
           and pd.v_active_status_r = 'Y'
           and cd.v_active_status_r = 'Y'
           and FP.n_policy_sk_r= pd.n_policy_sk_r
           and fp.n_version_number_r=pd.n_policy_version_number_r
           --and extract(year from a.d_calendar_date_r)=2023--Gireesh changes
           and extract(year from a.d_calendar_date_r)=LN_CURR_YEAR--Gireesh changes
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
		--29-Oct-2024 change ends
		commit;
        lc_trcmsg:=lc_trcmsg||chr(13)||'7.1 Inserted into table TMP_FCT_CLAIM_PAYMENT_DETAIL_R:->'||(DBMS_UTILITY.GET_TIME-ln_start_time)||' Seconds';
        ln_cnt:=0;
		lc_trcmsg:=lc_trcmsg||chr(13)||'7.2 Get Number of records Inserted in TMP_FCT_CLAIM_PAYMENT_DETAIL_R';
		SELECT COUNT(1) INTO  ln_cnt FROM ATOMIC.TMP_FCT_CLAIM_PAYMENT_DETAIL_R ;
		lc_trcmsg:=lc_trcmsg||chr(13)||'7.3 Number of records Inserted in TMP_FCT_CLAIM_PAYMENT_DETAIL_R:->'||ln_cnt;

        lc_trcmsg:=lc_trcmsg||chr(13)||'8. Insert into table TMP_FCT_LG_RESERVE_DETAILS_R';
        --
        ln_start_time:=DBMS_UTILITY.GET_TIME;
        --29-Oct-2024 change STARTS
		/*INSERT  INTO  atomic.tmp_FCT_LG_RESERVE_DETAILS_R
        select
        --SYSDATE AS D_AS_OF_DATE_R,
        ld_sysdate AS D_AS_OF_DATE_R,
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
        --CASE WHEN LG.v_reserve_type_ind_r ='I' AND SYSDATE <=DIM_TIME_R.D_CALENDAR_DATE_R THEN LG.n_chg_reserve_direct__gaap__r ELSE 0 END AS N_CUM_GAAP_IBNR_DIRECT_AMT_R,
        CASE WHEN LG.v_reserve_type_ind_r ='I' AND ld_sysdate <=DIM_TIME_R.D_CALENDAR_DATE_R THEN LG.n_chg_reserve_direct__gaap__r ELSE 0 END AS N_CUM_GAAP_IBNR_DIRECT_AMT_R,
        CASE WHEN LG.v_reserve_type_ind_r ='I' THEN NVL(LG.n_reserve_direct__stat__r,0) - NVL(LG.n_chg_reserve_direct__stat__r,0) ELSE 0 END AS N_PRIOR_STAT_IBNR_DIRECT_AMT_R,
        CASE WHEN LG.v_reserve_type_ind_r ='I' THEN NVL(LG.n_chg_reserve_direct__stat__r,0) ELSE 0 END AS  N_CHG_STAT_IBNR_DIRECT_AMT_R,
        --CASE WHEN LG.v_reserve_type_ind_r ='I' AND SYSDATE <=DIM_TIME_R.D_CALENDAR_DATE_R THEN LG.n_chg_reserve_direct__stat__r ELSE 0 END AS N_CUM_STAT_IBNR_DIRECT_AMT_R,
        CASE WHEN LG.v_reserve_type_ind_r ='I' AND ld_sysdate <=DIM_TIME_R.D_CALENDAR_DATE_R THEN LG.n_chg_reserve_direct__stat__r ELSE 0 END AS N_CUM_STAT_IBNR_DIRECT_AMT_R,
        CASE WHEN LG.v_reserve_type_ind_r ='P'THEN NVL(LG.n_reserve_direct_best_estmt_r,0) - NVL(LG.n_chg_rsrv_direct_best_estmt_r,0) ELSE 0 END AS N_PRIOR_BE_IBNR_DIRECT_AMT_R,
        CASE WHEN LG.v_reserve_type_ind_r ='P'THEN NVL(LG.n_chg_rsrv_direct_best_estmt_r,0) ELSE 0 END AS N_CHG_BE_IBNR_DIRECT_AMT_R ,
        CASE WHEN LG.v_reserve_type_ind_r ='P'THEN NVL(LG.n_reserve_direct__field__r,0) - NVL(LG.n_chg_reserve_direct__field__r,0) ELSE  0 END AS N_PRIOR_FIELD_IBNR_DIR_AMT_R,
        CASE WHEN LG.v_reserve_type_ind_r ='P'THEN NVL(LG.n_chg_reserve_direct__field__r,0) ELSE  0 END AS  N_CHG_FIELD_IBNR_DIRECT_AMT_R
        FROM ATOMIC.FCT_LG_RESERVE_DETAILS_R  LG
        LEFT OUTER JOIN ATOMIC.DIM_TIME_R
        ON  EXTRACT(YEAR FROM to_date(LG.d_reserve_valuation_date_r,'DD-MON-YY')) = DIM_TIME_R.N_YEAR_R
        AND EXTRACT (MONTH FROM to_date(LG.d_reserve_valuation_date_r,'DD-MON-YY')) = DIM_TIME_R.N_MONTH_R
        AND DIM_TIME_R.V_END_OF_FISCAL_MONTH_IND_R = 'Y'
        LEFT JOIN ( SELECT * FROM ATOMIC.DIM_GRP_PRODUCT_R  where V_BASIC_PRODUCT_LINE_CODE_R is not null) product
        ON LG.V_COVERAGE_CODE_R=product.V_COVERAGE_CODE_R
        LEFT OUTER JOIN (select n_policy_version_number_r,n_policy_sk_r, v_policy_prefix_r,v_policy_suffix_r from ATOMIC.dim_grp_policy_dir_r 
        where v_active_status_r ='Y' ) gpd
        on gpd.n_policy_sk_r = LG.N_POLICY_SK_R
        LEFT OUTER JOIN (select distinct n_version_number_r,N_POLICY_SK_R,n_cust_party_sk_r from  ATOMIC.fct_grp_policy_r ) policy
        on policy.n_version_number_r = gpd.n_policy_version_number_r and policy.N_POLICY_SK_R = LG.N_POLICY_SK_R
        WHERE EXTRACT(YEAR FROM to_date(LG.d_reserve_valuation_date_r,'DD-MON-YY'))=ln_curr_year;--2023;
        */
		INSERT /*+APPEND_VALUES*/ INTO  atomic.tmp_FCT_LG_RESERVE_DETAILS_R
		select distinct /*+PARALLEL(4)*/
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
		--LEFT JOIN ( SELECT * FROM ATOMIC.DIM_GRP_PRODUCT_R   where V_BASIC_PRODUCT_LINE_CODE_R is not null) product
		--ON LG.V_COVERAGE_CODE_R = product.V_COVERAGE_CODE_R
		LEFT OUTER JOIN (select n_policy_version_number_r,n_policy_sk_r, v_policy_prefix_r,v_policy_suffix_r from ATOMIC.dim_grp_policy_dir_r    
		where v_active_status_r ='Y' ) gpd
		on gpd.n_policy_sk_r = LG.N_POLICY_SK_R
		LEFT OUTER JOIN (select distinct n_version_number_r,N_POLICY_SK_R,n_cust_party_sk_r from  ATOMIC.fct_grp_policy_r  ) policy
		on policy.n_version_number_r = gpd.n_policy_version_number_r and policy.N_POLICY_SK_R = LG.N_POLICY_SK_R
		--WHERE EXTRACT(YEAR FROM to_date(LG.d_reserve_valuation_date_r,'DD-MON-YY'))=2023;--Gireesh changes
		--WHERE EXTRACT(YEAR FROM to_date(LG.d_reserve_valuation_date_r,'DD-MON-YY'))=LN_CURR_YEAR --Gireesh changes
		WHERE LG.d_reserve_valuation_date_r = to_date(ld_fic_mis_date)-1 --Srinith Changes
        --and  LG.V_COVERAGE_CODE_R is not null

		UNION ALL

		select distinct /*+PARALLEL(4)*/
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
		--ON CASE WHEN gpd.v_policy_prefix_r  = 'VCI' THEN 'VCI' WHEN gpd.v_policy_prefix_r='VAI' THEN 'VAI' ELSE LG.V_COVERAGE_CODE_R end = product.V_BASIC_PRODUCT_LINE_CODE_R
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
		--WHERE EXTRACT(YEAR FROM to_date(LG.d_reserve_valuation_date_r,'DD-MON-YY'))=2023;--Gireesh changes
		--WHERE EXTRACT(YEAR FROM to_date(LG.d_reserve_valuation_date_r,'DD-MON-YY'))=LN_CURR_YEAR; --Gireesh changes
		WHERE LG.d_reserve_valuation_date_r = to_date(ld_fic_mis_date)-1; --Srinith Changes
        --and  LG.V_COVERAGE_CODE_R is not null; --LG.v_reserve_type_ind_r in ('P','I') and
		--29-Oct-2024 changes ends				
		commit;

        lc_trcmsg:=lc_trcmsg||chr(13)||'8.1 Inserted into table TMP_FCT_LG_RESERVE_DETAILS_R:->'||(DBMS_UTILITY.GET_TIME-ln_start_time)||' Seconds';
        ln_cnt:=0;
		lc_trcmsg:=lc_trcmsg||chr(13)||'8.2 Get Number of records Inserted in TMP_FCT_LG_RESERVE_DETAILS_R';
		SELECT COUNT(1) INTO  ln_cnt FROM ATOMIC.TMP_FCT_LG_RESERVE_DETAILS_R   ;
		lc_trcmsg:=lc_trcmsg||chr(13)||'8.3 Number of records Inserted in TMP_FCT_LG_RESERVE_DETAILS_R:->'||ln_cnt;

        lc_trcmsg:=lc_trcmsg||chr(13)||'9. Insert into table TMP_FCT_RPT_ACT_PLR_SUMMARY_R';
        ln_start_time:=DBMS_UTILITY.GET_TIME;
		--29-Oct-2024 changes starts
        /*
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
        FROM ATOMIC.FCT_RPT_ACT_PLR_SUMMARY_R  FACS
        WHERE  N_party_sk_r <> -1
        --AND (EXTRACT(YEAR FROM to_date(D_CYCLE_DATE_R,'DD-MON-YY')) in (2020, 2021)) --and EXTRACT(MONTH FROM to_date(D_CYCLE_DATE_R,'DD-MON-YY')) =6
        --or
        --EXTRACT(YEAR FROM to_date(D_CYCLE_DATE_R,'DD-MON-YY'))= 2020 and EXTRACT(MONTH FROM to_date(D_CYCLE_DATE_R,'DD-MON-YY')) =12)
        --and FACS.n_policy_sk_r = 98
        )
        --select * from FCT_RPT_ACT_PLR_SUMMARY_R_TABLE);
        ,
        FCT_RPT_ACT_PLR_SUMMARY_R_TABLE_1 AS
        (
        SELECT * from FCT_RPT_ACT_PLR_SUMMARY_R_TABLE
        ),
        FCT_RPT_ACT_PLR_SUMMARY_R_TABLE_CALC AS
        (
        SELECT
        --SYSDATE AS D_AS_OF_DATE_R,
        ld_sysdate AS D_AS_OF_DATE_R,
        FACS.D_CYCLE_DATE_R  AS D_CYCLE_DATE_R_START,
        --NVL(FCT_RPT_ACT_PLR_SUMMARY_R_TABLE_1.D_CYCLE_DATE_R,FACS.D_CYCLE_DATE_R+1) AS D_CYCLE_DATE_R_END,
        --NVL(FCT_RPT_ACT_PLR_SUMMARY_R_TABLE_1.D_CYCLE_DATE_R,sysdate) AS D_CYCLE_DATE_R_END,
        NVL(FCT_RPT_ACT_PLR_SUMMARY_R_TABLE_1.D_CYCLE_DATE_R,ld_sysdate) AS D_CYCLE_DATE_R_END,
        FACS.N_POLICY_SK_R,
        nvl(FACS.N_party_sk_r,-1) as N_party_sk_r,
        pol_dir.v_policy_prefix_r,
        pol_dir.v_policy_suffix_r,
        --'' AS D_UW_DATE_R,
        --'' AS V_COVERAGE_R,
        FACS.N_CURR_PLR_R,
        FACS.N_SOLD_ANNUALIZED_PREM_R AS N_SOLD_ANNUALIZED_PREM_R
        FROM FCT_RPT_ACT_PLR_SUMMARY_R_TABLE FACS
        LEFT JOIN (SELECT * FROM ATOMIC.dim_grp_policy_dir_r  WHERE v_active_status_r='Y') pol_dir
        ON FACS.N_POLICY_SK_R=pol_dir.N_POLICY_SK_R
        LEFT JOIN FCT_RPT_ACT_PLR_SUMMARY_R_TABLE_1
        ON FACS.N_POLICY_SK_R = FCT_RPT_ACT_PLR_SUMMARY_R_TABLE_1.N_POLICY_SK_R
        AND FACS.N_party_sk_r = FCT_RPT_ACT_PLR_SUMMARY_R_TABLE_1.N_party_sk_r
        AND FACS.RK + 1 = FCT_RPT_ACT_PLR_SUMMARY_R_TABLE_1.RK
        --where FACS.n_policy_sk_r = 5
        )
        --select * from FCT_RPT_ACT_PLR_SUMMARY_R_TABLE_CALC);
        ----/
        ----SELECT * FROM FCT_RPT_ACT_PLR_SUMMARY_R_TABLE_CALC
        ----order by N_POLICY_SK_R, N_party_sk_r,D_CYCLE_DATE_R_START) A;
        ----/




        SELECT DIM_TIME_R.D_CALENDAR_DATE_R AS D_CYCLE_DATE_R,trunc(DIM_TIME_R.D_CALENDAR_DATE_R, 'mm') AS d_uw_date_r, FCT_RPT_ACT_PLR_SUMMARY_R_TABLE_CALC.*
        FROM FCT_RPT_ACT_PLR_SUMMARY_R_TABLE_CALC, DIM_TIME_R
        ----/left join (select max(DIM_TIME_R.D_CALENDAR_DATE_R)D_CYCLE_DATE_R_START,c.D_CYCLE_DATE_R cycle_date
        ----from FCT_RPT_ACT_PLR_SUMMARY_R_TABLE_CALC C
        ----group by c.D_CYCLE_DATE_R)max_start
        ----on max_start.D_CYCLE_DATE_R_START = FCT_RPT_ACT_PLR_SUMMARY_R_TABLE_CALC.D_CYCLE_DATE_R_START and
        ----max_start.D_CYCLE_DATE_R = FCT_RPT_ACT_PLR_SUMMARY_R_TABLE_CALC.D_CYCLE_DATE_R
		----/
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
        where (EXTRACT(YEAR FROM to_date(D_CYCLE_DATE_R,'DD-MON-YY'))= LN_CURR_YEAR--2023
	    )
        --and months_between( D_CYCLE_DATE_R,D_CYCLE_DATE_R_START) <= 6
        order by D_CYCLE_DATE_R;*/
        INSERT /*+APPEND_VALUES*/ INTO  ATOMIC.tmp_FCT_RPT_ACT_PLR_SUMMARY_R 

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
        --AND (EXTRACT(YEAR FROM to_date(D_CYCLE_DATE_R,'DD-MON-YY')) in (2020, 2021)) --and EXTRACT(MONTH FROM to_date(D_CYCLE_DATE_R,'DD-MON-YY')) =6
        --or 
        --EXTRACT(YEAR FROM to_date(D_CYCLE_DATE_R,'DD-MON-YY'))= 2020 and EXTRACT(MONTH FROM to_date(D_CYCLE_DATE_R,'DD-MON-YY')) =12)
        --and FACS.n_policy_sk_r = 98
        )
        --select * from FCT_RPT_ACT_PLR_SUMMARY_R_TABLE);
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
        --NVL(FCT_RPT_ACT_PLR_SUMMARY_R_TABLE_1.D_CYCLE_DATE_R,FACS.D_CYCLE_DATE_R+1) AS D_CYCLE_DATE_R_END,
        NVL(FCT_RPT_ACT_PLR_SUMMARY_R_TABLE_1.D_CYCLE_DATE_R,LD_sysdate) AS D_CYCLE_DATE_R_END,
        FACS.N_POLICY_SK_R,
        nvl(FACS.N_party_sk_r,-1) as N_party_sk_r,
        pol_dir.v_policy_prefix_r,
        pol_dir.v_policy_suffix_r,
        --'' AS D_UW_DATE_R,
        --'' AS V_COVERAGE_R,
        FACS.N_CURR_PLR_R,
        FACS.N_SOLD_ANNUALIZED_PREM_R AS N_SOLD_ANNUALIZED_PREM_R
        FROM FCT_RPT_ACT_PLR_SUMMARY_R_TABLE FACS
        LEFT JOIN (SELECT * FROM ATOMIC.dim_grp_policy_dir_r   WHERE v_active_status_r='Y') pol_dir
        ON FACS.N_POLICY_SK_R=pol_dir.N_POLICY_SK_R
        LEFT JOIN FCT_RPT_ACT_PLR_SUMMARY_R_TABLE_1
        ON FACS.N_POLICY_SK_R = FCT_RPT_ACT_PLR_SUMMARY_R_TABLE_1.N_POLICY_SK_R
        AND FACS.N_party_sk_r = FCT_RPT_ACT_PLR_SUMMARY_R_TABLE_1.N_party_sk_r
        AND FACS.RK + 1 = FCT_RPT_ACT_PLR_SUMMARY_R_TABLE_1.RK
        --where FACS.n_policy_sk_r = 5
        )
        --select * from FCT_RPT_ACT_PLR_SUMMARY_R_TABLE_CALC);
        /*
        SELECT * FROM FCT_RPT_ACT_PLR_SUMMARY_R_TABLE_CALC  
        order by N_POLICY_SK_R, N_party_sk_r,D_CYCLE_DATE_R_START) A;
        */
        SELECT DIM_TIME_R.D_CALENDAR_DATE_R AS D_CYCLE_DATE_R,trunc(DIM_TIME_R.D_CALENDAR_DATE_R, 'mm') AS d_uw_date_r, FCT_RPT_ACT_PLR_SUMMARY_R_TABLE_CALC.* 
        FROM FCT_RPT_ACT_PLR_SUMMARY_R_TABLE_CALC, DIM_TIME_R
        /*left join (select max(DIM_TIME_R.D_CALENDAR_DATE_R)D_CYCLE_DATE_R_START,c.D_CYCLE_DATE_R cycle_date 
        from FCT_RPT_ACT_PLR_SUMMARY_R_TABLE_CALC C 
        group by c.D_CYCLE_DATE_R)max_start
        on max_start.D_CYCLE_DATE_R_START = FCT_RPT_ACT_PLR_SUMMARY_R_TABLE_CALC.D_CYCLE_DATE_R_START and 
        max_start.D_CYCLE_DATE_R = FCT_RPT_ACT_PLR_SUMMARY_R_TABLE_CALC.D_CYCLE_DATE_R*/
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
        --where (EXTRACT(YEAR FROM to_date(D_CYCLE_DATE_R,'DD-MON-YY'))= 2023)       --Gireesh changes
        where (EXTRACT(YEAR FROM to_date(D_CYCLE_DATE_R,'DD-MON-YY'))= LN_CURR_YEAR) --Gireesh changes
        --and months_between( D_CYCLE_DATE_R,D_CYCLE_DATE_R_START) <= 6
        order by D_CYCLE_DATE_R;
		--29-Oct-2024 changes ENDS        
		commit;

		lc_trcmsg:=lc_trcmsg||chr(13)||'9.1 Inserted into tbl TMP_FCT_RPT_ACT_PLR_SUMMARY_R:->'||(DBMS_UTILITY.GET_TIME-ln_start_time)||' Seconds';
        ln_cnt:=0;
		lc_trcmsg:=lc_trcmsg||chr(13)||'9.2 Get Number of records Inserted in TMP_FCT_RPT_ACT_PLR_SUMMARY_R';
		SELECT COUNT(1) INTO  ln_cnt FROM ATOMIC.TMP_FCT_RPT_ACT_PLR_SUMMARY_R  ;
		lc_trcmsg:=lc_trcmsg||chr(13)||'9.3 Number of records Inserted in TMP_FCT_RPT_ACT_PLR_SUMMARY_R:->'||ln_cnt;

        lc_trcmsg:=lc_trcmsg||chr(13)||'10. Insert into tbl TMP_FCT_RPT_ANN_PREM_SUMMARY_R';
        ln_start_time:=DBMS_UTILITY.GET_TIME;
        --29-Oct-2024 changes starts
        /*INSERT INTO  ATOMIC.tmp_FCT_RPT_ANN_PREM_SUMMARY_R
        SELECT
        --SYSDATE AS D_AS_OF_DATE_R,
        ld_sysdate AS D_AS_OF_DATE_R,
        DIM_TIME_R.D_CALENDAR_DATE_R AS D_CYCLE_DATE_R,
        FAPS.N_POLICY_SK_R,
        pol_dir.v_policy_prefix_r,
        pol_dir.v_policy_suffix_r,
        nvl(FP.N_CUST_PARTY_SK_R,-1) AS N_party_sk_r,
        trunc(FAPS.D_DUE_DATE_R,'MM') AS D_UW_DATE_R,
        product.V_BASIC_PRODUCT_LINE_CODE_R AS V_COVERAGE_R,
        FAPS.N_ANNUALIZED_PREMIUM_R AS N_CURR_ANNUALIZED_PREMIUM_R,
        FAPS.N_COVERAGE_LIVES_R AS N_CURR_NUMBER_OF_LIVES_R,
        FAPS.N_GROSS_LIVES_R AS N_GROSS_LIVES_R
        FROM ATOMIC.FCT_RPT_ANN_PREM_SUMMARY_R  FAPS
        LEFT OUTER JOIN ATOMIC.DIM_TIME_R
        ON  EXTRACT(YEAR FROM to_date(FAPS.D_CYCLE_DATE_R,'DD-MON-YY')) = DIM_TIME_R.N_YEAR_R
        AND EXTRACT (MONTH FROM to_date(FAPS.D_CYCLE_DATE_R,'DD-MON-YY')) = DIM_TIME_R.N_MONTH_R
        AND DIM_TIME_R.V_END_OF_FISCAL_MONTH_IND_R = 'Y'
        LEFT JOIN ( SELECT * FROM ATOMIC.DIM_GRP_PRODUCT_R  where V_BASIC_PRODUCT_LINE_CODE_R is not null) product
        ON FAPS.V_COVERAGE_CODE_R=product.V_COVERAGE_CODE_R
        LEFT JOIN (SELECT * FROM ATOMIC.dim_grp_policy_dir_r  WHERE v_active_status_r='Y' ) pol_dir
        ON FAPS.N_POLICY_SK_R=pol_dir.N_POLICY_SK_R
        LEFT JOIN (select distinct n_version_number_r,N_POLICY_SK_R,n_cust_party_sk_r from  ATOMIC.fct_grp_policy_r ) FP
        ON FP.n_policy_sk_r= FAPS.n_policy_sk_r
        AND FP.n_version_number_r=pol_dir.n_policy_version_number_r
        WHERE
        ---EXTRACT(YEAR FROM SYSDATE) >= DIM_TIME_R.N_YEAR_R AND EXTRACT(MONTH FROM SYSDATE) >= DIM_TIME_R.N_MONTH_R AND  -------pls check
        FAPS.D_DUE_DATE_R IS NOT NULL
        And EXTRACT(YEAR FROM to_date(D_CYCLE_DATE_R,'DD-MON-YY'))=LN_CURR_YEAR--2023
        AND FAPS.N_POLICY_SK_R <> -1;
        */
        INSERT /*+APPEND_VALUES*/  INTO  ATOMIC.tmp_FCT_RPT_ANN_PREM_SUMMARY_R 
        SELECT
        --SYSDATE AS D_AS_OF_DATE_R, --Gireesh changes
        LD_SYSDATE AS D_AS_OF_DATE_R,--Gireesh changes
        DIM_TIME_R.D_CALENDAR_DATE_R AS D_CYCLE_DATE_R,
        FAPS.N_POLICY_SK_R,
        pol_dir.v_policy_prefix_r,
        pol_dir.v_policy_suffix_r,
        nvl(FP.N_CUST_PARTY_SK_R,-1) AS N_party_sk_r,
        trunc(FAPS.D_DUE_DATE_R,'MM') AS D_UW_DATE_R,
        product.V_BASIC_PRODUCT_LINE_CODE_R AS V_COVERAGE_R,
        FAPS.N_ANNUALIZED_PREMIUM_R AS N_CURR_ANNUALIZED_PREMIUM_R,
        --FAPS.N_COVERAGE_LIVES_R AS N_CURR_NUMBER_OF_LIVES_R,     --Erica changes
        FAPS.N_YTD_CURR_POLICY_LIVES_R AS N_CURR_NUMBER_OF_LIVES_R,--Erica changes
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
        ---EXTRACT(YEAR FROM SYSDATE) >= DIM_TIME_R.N_YEAR_R AND EXTRACT(MONTH FROM SYSDATE) >= DIM_TIME_R.N_MONTH_R AND  -------pls check
        FAPS.D_DUE_DATE_R IS NOT NULL
        --And EXTRACT(YEAR FROM to_date(D_CYCLE_DATE_R,'DD-MON-YY'))=2023--Gireesh Changes
        --And EXTRACT(YEAR FROM to_date(D_CYCLE_DATE_R,'DD-MON-YY'))=LN_CURR_YEAR  --Gireesh Changes
		And FAPS.D_CYCLE_DATE_R=to_date(ld_fic_mis_date)-1 --Srinith Changes
        AND FAPS.N_POLICY_SK_R <> -1;
		--29-Oct-2024 changs ends
		commit;
        lc_trcmsg:=lc_trcmsg||chr(13)||'10.1 Inserted into tbl TMP_FCT_RPT_ANN_PREM_SUMMARY_R:->'||(DBMS_UTILITY.GET_TIME-ln_start_time)||' Seconds';
        ln_cnt:=0;
		lc_trcmsg:=lc_trcmsg||chr(13)||'10.2 Get Number of records Inserted in TMP_FCT_RPT_ANN_PREM_SUMMARY_R';
		SELECT COUNT(1) INTO  ln_cnt FROM ATOMIC.TMP_FCT_RPT_ANN_PREM_SUMMARY_R ;
		lc_trcmsg:=lc_trcmsg||chr(13)||'10.3 Number of records Inserted in TMP_FCT_RPT_ANN_PREM_SUMMARY_R:->'||ln_cnt;

        lc_trcmsg:=lc_trcmsg||chr(13)||'11. Insert into tbl TMP_FCT_RPT_CLAIM_SUMMARY_R';
        ln_start_time:=DBMS_UTILITY.GET_TIME;
		--29-Oct-2024 changs starts
        /*INSERT INTO ATOMIC.TMP_FCT_RPT_CLAIM_SUMMARY_R
        select
        --SYSDATE AS D_AS_OF_DATE_R,
        ld_sysdate AS D_AS_OF_DATE_R,
        FCS.D_CYCLE_DATE_R,
        nvl(claim.n_policy_sk_r, FCS.n_policy_sk_r),
        nvl(fp.n_cust_party_sk_r,FP2.n_cust_party_sk_r) AS n_party_sk_r,
        trunc(NVL(claim.d_date_of_loss_r,FCS.D_CYCLE_DATE_R),'MM') AS d_uw_date_r,
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
        (power(1.04, (EXTRACT(YEAR FROM to_date(FCS.D_CYCLE_DATE_R,'DD-MON-YY')) - EXTRACT(YEAR FROM to_date(NVL(claim.d_date_of_loss_r,FCS.D_CYCLE_DATE_R),'DD-MON-YY')) )))
        AS N_CURR_GAAP_PV_DIRECT_AMT_R,
        ----/N_Curr_GAAP_Reserve_Direct_R * 1.04 ^ ((year(cycle_date) - year (d_date_of_loss_r)) /
        FCS.N_Curr_Stat_Reserve_Direct_R *
        (power(1.04, (EXTRACT(YEAR FROM to_date(FCS.D_CYCLE_DATE_R,'DD-MON-YY')) - EXTRACT(YEAR FROM to_date(NVL(claim.d_date_of_loss_r,FCS.D_CYCLE_DATE_R),'DD-MON-YY')) )))
        AS N_CURR_STAT_PV_DIRECT_AMT_R,
		----/ N_Curr_Stat_Reserve_Direct_R,N_Curr_Stat_Reserve_Direct_R * 1.04 ^ ((year(cycle_date) - year (d_date_of_loss_r)) /
        FCS.N_CURR_BE_RESERVE_DIRECT_AMT_R *
        (power(1.04, (EXTRACT(YEAR FROM to_date(FCS.D_CYCLE_DATE_R,'DD-MON-YY')) - EXTRACT(YEAR FROM to_date(NVL(claim.d_date_of_loss_r,FCS.D_CYCLE_DATE_R),'DD-MON-YY')) )))
        AS N_CURR_BE_PV_DIRECT_AMT_R,
		--/N_CURR_BE_RESERVE_DIRECT_AMT_R * 1.04 ^ ((year(cycle_date) - year (d_date_of_loss_r))/
        (case when FCS.V_COVERAGE_GROUP_ID_R <> 'DF' then FCS.N_TOTAL_CLAIM_COUNT_R else 0 end) AS N_CURR_CLAIM_COUNT_R,
        (case when FCS.V_COVERAGE_GROUP_ID_R <> 'DF' then (FCS.N_CHG_Approved_CLAIM_COUNT_R + FCS.N_CHG_PENDING_CLAIM_COUNT_R) else 0 end) AS N_CURR_APPROVED_CLAIM_COUNT_R,
        (case when FCS.V_COVERAGE_GROUP_ID_R <> 'DF' then FCS.N_CHG_Closed_CLAIM_COUNT_R else 0 end) AS N_CURR_DENIED_CLAIM_COUNT_R
        from  ATOMIC.FCT_RPT_CLAIM_SUMMARY_R  FCS
        LEFT JOIN (select c.V_CLAIM_NUMBER_R,case when c.v_claim_number_r like '%VAI%'
           and c.V_SOURCE_SYSTEM_NAME_R = 'PACS' then d.d_date_of_event_r
           else c.d_date_of_loss_r end d_date_of_loss_r , n_policy_sk_r, c.n_claim_sk_r
           from ATOMIC.dim_grp_claim_dir_r  c
        left join dim_grp_claim_detail_r  d on c.n_claim_sk_r = d.n_claim_sk_r and d.v_active_status_r = 'Y'
        where c.v_active_status_r='Y') claim
        on FCS.V_CLAIM_NUMBER_R=claim.V_CLAIM_NUMBER_R
        left join (select mvw_product_sk_lookup .*,DIM_GRP_PRODUCT_R.V_BASIC_PRODUCT_LINE_CODE_R from atomic.mvw_product_sk_lookup , ATOMIC.DIM_GRP_PRODUCT_R 
           where mvw_product_sk_lookup.n_product_sk_r =   DIM_GRP_PRODUCT_R.n_product_sk_r    )product_mv
        on  product_mv.v_claim_number_r = fcs.v_claim_number_r
           and product_mv.n_claim_sk_r = claim.n_claim_sk_r
           and product_mv.v_claim_coverage_code_r = fcs.v_coverage_code_r
        LEFT JOIN ( select * from ATOMIC.DIM_GRP_PRODUCT_R  where V_BASIC_PRODUCT_LINE_CODE_R is not null) product
        ON FCS.V_COVERAGE_CODE_R=product.V_COVERAGE_CODE_R
        LEFT JOIN (SELECT * FROM ATOMIC.dim_grp_policy_dir_r  WHERE v_active_status_r='Y' ) pol_dir
        ON claim.N_POLICY_SK_R=pol_dir.N_POLICY_SK_R
        LEFT JOIN (SELECT * FROM ATOMIC.dim_grp_policy_dir_r  WHERE v_active_status_r='Y' ) pol_dir2
        ON FCS.N_POLICY_SK_R=pol_dir2.N_POLICY_SK_R
        LEFT JOIN (select distinct n_version_number_r,N_POLICY_SK_R,n_cust_party_sk_r from  ATOMIC.fct_grp_policy_r ) FP
        ON FP.n_policy_sk_r= claim.n_policy_sk_r
        AND FP.n_version_number_r=pol_dir.n_policy_version_number_r
        LEFT JOIN (select distinct n_version_number_r,N_POLICY_SK_R,n_cust_party_sk_r from  ATOMIC.fct_grp_policy_r ) FP2
        ON FP2.n_policy_sk_r= FCS.n_policy_sk_r
        AND FP2.n_version_number_r=pol_dir2.n_policy_version_number_r
        where EXTRACT(YEAR FROM FCS.D_CYCLE_DATE_R)=LN_CURR_YEAR--2023
        and FCS.V_POLICY_NUMBER_R is not null;------------------------------------------Pls check
		*/
		INSERT /*+APPEND_VALUES*/ INTO ATOMIC.tmp_FCT_RPT_CLAIM_SUMMARY_R
		select 
		--SYSDATE AS D_AS_OF_DATE_R, --Gireesh changes
		LD_SYSDATE AS D_AS_OF_DATE_R,--Gireesh changes
		FCS.D_CYCLE_DATE_R,
		nvl(claim.n_policy_sk_r, FCS.n_policy_sk_r),
		nvl(fp.n_cust_party_sk_r,FP2.n_cust_party_sk_r) AS n_party_sk_r,
		trunc(NVL(claim.d_date_of_loss_r,FCS.D_CYCLE_DATE_R),'MM') AS d_uw_date_r,
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
		(power(1.04, (EXTRACT(YEAR FROM to_date(FCS.D_CYCLE_DATE_R,'DD-MON-YY')) - EXTRACT(YEAR FROM to_date(NVL(claim.d_date_of_loss_r,FCS.D_CYCLE_DATE_R),'DD-MON-YY')) )))
		AS N_CURR_GAAP_PV_DIRECT_AMT_R,
		/*N_Curr_GAAP_Reserve_Direct_R * 1.04 ^ ((year(cycle_date) - year (d_date_of_loss_r)) */
		FCS.N_Curr_Stat_Reserve_Direct_R *
		(power(1.04, (EXTRACT(YEAR FROM to_date(FCS.D_CYCLE_DATE_R,'DD-MON-YY')) - EXTRACT(YEAR FROM to_date(NVL(claim.d_date_of_loss_r,FCS.D_CYCLE_DATE_R),'DD-MON-YY')) )))
		AS N_CURR_STAT_PV_DIRECT_AMT_R,/* N_Curr_Stat_Reserve_Direct_R,N_Curr_Stat_Reserve_Direct_R * 1.04 ^ ((year(cycle_date) - year (d_date_of_loss_r)) */
		FCS.N_CURR_BE_RESERVE_DIRECT_AMT_R * 
		(power(1.04, (EXTRACT(YEAR FROM to_date(FCS.D_CYCLE_DATE_R,'DD-MON-YY')) - EXTRACT(YEAR FROM to_date(NVL(claim.d_date_of_loss_r,FCS.D_CYCLE_DATE_R),'DD-MON-YY')) )))
		AS N_CURR_BE_PV_DIRECT_AMT_R,/*N_CURR_BE_RESERVE_DIRECT_AMT_R * 1.04 ^ ((year(cycle_date) - year (d_date_of_loss_r))*/
		(case when FCS.V_COVERAGE_GROUP_ID_R <> 'DF' then FCS.N_TOTAL_CLAIM_COUNT_R else 0 end) AS N_CURR_CLAIM_COUNT_R,
		(case when FCS.V_COVERAGE_GROUP_ID_R <> 'DF' then (FCS.N_CHG_Approved_CLAIM_COUNT_R + FCS.N_CHG_PENDING_CLAIM_COUNT_R) else 0 end) AS N_CURR_APPROVED_CLAIM_COUNT_R,
		(case when FCS.V_COVERAGE_GROUP_ID_R <> 'DF' then FCS.N_CHG_Closed_CLAIM_COUNT_R else 0 end) AS N_CURR_DENIED_CLAIM_COUNT_R
		,(Case when FCS.v_claim_status_reason_code_r < '60' then FCS.N_CURR_FIELD_RES_DIRECT_AMT_R ELSE 0 end) as N_CURR_OPEN_FIELD_OS_DIRECT_AMT_R,--05-Nov-24 changes
		--FCS.N_CHG_STAT_WV_NET_AMT_R as N_CHG_STAT_WV_NET_AMT_R,FCS.N_CHG_GAAP_WV_NET_AMT_R as N_CHG_GAAP_WV_NET_AMT_R,
		product.V_PRODUCT_LINE_R as V_PRODUCT_LINE_R,
		product.V_PRODUCT_SUB_LINE_CODE_R as V_PRODUCT_SUB_LINE_CODE_R, 
		FCS.N_CHG_GAAP_OS_DIRECT_AMT_R * (NVL(cp.N_TOTAL_REINSURANCE_PCT_R,0)/100) as N_CHG_GAAP_OS_CEDED_AMT_R,
		FCS.N_CHG_STAT_OS_DIRECT_AMT_R * (NVL(cp.N_TOTAL_REINSURANCE_PCT_R,0)/100) as N_CHG_STAT_OS_CEDED_AMT_R 
		from  ATOMIC.FCT_RPT_CLAIM_SUMMARY_R   FCS
		LEFT JOIN (select distinct V_CLAIM_NUMBER_R,n_claim_sk_r,N_TOTAL_REINSURANCE_PCT_R,rank() over(partition by n_claim_sk_r order by n_batch_id_r desc)rnk from ATOMIC.FCT_CLAIM_PAYMENT_DETAIL_R) cp
		on FCS.V_CLAIM_NUMBER_R = cp.V_CLAIM_NUMBER_R and FCS.n_claim_sk_r =cp.n_claim_sk_r and rnk=1
		LEFT JOIN (select c.V_CLAIM_NUMBER_R,case when c.v_claim_number_r like '%VAI%' 
		   and c.V_SOURCE_SYSTEM_NAME_R = 'PACS' then d.d_date_of_event_r 
		   else c.d_date_of_loss_r end d_date_of_loss_r , n_policy_sk_r, c.n_claim_sk_r
		   from ATOMIC.dim_grp_claim_dir_r   c 
		left join dim_grp_claim_detail_r   d on c.n_claim_sk_r = d.n_claim_sk_r and d.v_active_status_r = 'Y'
		where c.v_active_status_r='Y') claim
		on FCS.V_CLAIM_NUMBER_R=claim.V_CLAIM_NUMBER_R
		left join (select mvw_product_sk_lookup.*,DIM_GRP_PRODUCT_R.V_BASIC_PRODUCT_LINE_CODE_R from atomic.mvw_product_sk_lookup  mvw_product_sk_lookup, ATOMIC.DIM_GRP_PRODUCT_R DIM_GRP_PRODUCT_R
		   where mvw_product_sk_lookup.n_product_sk_r =   DIM_GRP_PRODUCT_R.n_product_sk_r    )product_mv
		on  product_mv.v_claim_number_r = fcs.v_claim_number_r
		   and product_mv.n_claim_sk_r = claim.n_claim_sk_r
		   and product_mv.v_claim_coverage_code_r = fcs.v_coverage_code_r
		LEFT JOIN ( select * from ATOMIC.DIM_GRP_PRODUCT_R) product
		ON FCS.n_product_sk_r=product.n_product_sk_r
		LEFT JOIN (SELECT * FROM ATOMIC.dim_grp_policy_dir_r   WHERE v_active_status_r='Y' ) pol_dir
		ON claim.N_POLICY_SK_R=pol_dir.N_POLICY_SK_R
		LEFT JOIN (SELECT * FROM ATOMIC.dim_grp_policy_dir_r   WHERE v_active_status_r='Y' ) pol_dir2
		ON FCS.N_POLICY_SK_R=pol_dir2.N_POLICY_SK_R
		LEFT JOIN (select distinct n_version_number_r,N_POLICY_SK_R,n_cust_party_sk_r from  ATOMIC.fct_grp_policy_r  ) FP
		ON FP.n_policy_sk_r= claim.n_policy_sk_r
		AND FP.n_version_number_r=pol_dir.n_policy_version_number_r
		LEFT JOIN (select distinct n_version_number_r,N_POLICY_SK_R,n_cust_party_sk_r from  ATOMIC.fct_grp_policy_r  ) FP2
		ON FP2.n_policy_sk_r= FCS.n_policy_sk_r
		AND FP2.n_version_number_r=pol_dir2.n_policy_version_number_r
		--where EXTRACT(YEAR FROM FCS.D_CYCLE_DATE_R)=2023      --
		--where EXTRACT(YEAR FROM FCS.D_CYCLE_DATE_R)=LN_CURR_YEAR--
		where FCS.D_CYCLE_DATE_R=to_date(ld_fic_mis_date)-1 --Srinith Changes
		and FCS.V_POLICY_NUMBER_R is not null;------------------------------------------Pls check
		--29-Oct-2024 changs ends
        commit;
        lc_trcmsg:=lc_trcmsg||chr(13)||'11.1 Inserted into tbl TMP_FCT_RPT_CLAIM_SUMMARY_R:->'||(DBMS_UTILITY.GET_TIME-ln_start_time)||' Seconds';
        ln_cnt:=0;
		lc_trcmsg:=lc_trcmsg||chr(13)||'11.2 Get Number of records Inserted in TMP_FCT_RPT_CLAIM_SUMMARY_R';
		SELECT COUNT(1) INTO  ln_cnt FROM ATOMIC.TMP_FCT_RPT_CLAIM_SUMMARY_R ;
		lc_trcmsg:=lc_trcmsg||chr(13)||'11.3 Number of records Inserted in TMP_FCT_RPT_CLAIM_SUMMARY_R:->'||ln_cnt;

        lc_trcmsg:=lc_trcmsg||chr(13)||'12. Insert into tbl TMP_FCT_RPT_PREMIUM_SUMMARY_R';
        ln_start_time:=DBMS_UTILITY.GET_TIME;
		--29-Oct-2024 changs starts
        /*INSERT  INTO ATOMIC.tmp_FCT_RPT_PREMIUM_SUMMARY_R
        select
        --DISTINCT --/removed distinct and added grouping /
        --SYSDATE AS D_AS_OF_DATE_R,
        ld_sysdate AS D_AS_OF_DATE_R,
        DIM_TIME_R.D_CALENDAR_DATE_R AS D_CYCLE_DATE_R,
        pol_dir.n_policy_sk_r,
        nvl(FP.n_cust_party_sk_r,-1) AS n_party_sk_r,
        trunc(FRS.D_DUE_DATE_R,'MM') AS d_uw_date_r,
        product.V_BASIC_PRODUCT_LINE_CODE_R AS V_COVERAGE_R,--/DIM_PRODUCT_R.V_BASIC_PRODUCT_LINE_CODE_R For FCT_RPT_PREMIUM_SUMMARY_R  - look up based on V_COVERAGE_CODE_R/
        pol_dir.v_policy_prefix_r,
        pol_dir.v_policy_suffix_r,
        party.n_customer_number_r AS n_customer_number_r,--/Use the N_CUST_PARTY_SK_R (aka N_PARTY_SK_R - refer to business rule for N_PARTY_SK_R) to look up V_CUSTOMER_NUMBER_R in DIM_GRP_customer_r/
        sum(FRS.n_earned_prem_amt_r),
        sum(FRS.N_COLLECTED_PREMIUM_AMT_R) AS N_COLL_PREM_AMT_R,
        sum(FRS.N_CHG_DUE_PREM_AMT_R) AS N_CHG_DUE_PREM_AMT_R,
        sum(FRS.N_WRITTEN_PREM_AMT_R) AS N_WRITTEN_PREM_AMT_R,
        sum(FRS.N_CHG_PREM_UNEARNED_AMT_R) AS N_CHG_PREM_UNEARNED_AMT_R,
        sum(FRS.N_CONSTANT_EARNED_PREM_AMT_R) AS N_CONST_EARNED_PREM_AMT_R
        from ATOMIC.FCT_RPT_PREMIUM_SUMMARY_R  FRS
        LEFT JOIN ATOMIC.DIM_TIME_R
        ON  EXTRACT(YEAR FROM to_date(FRS.D_CYCLE_DATE_R,'DD-MON-YY')) = DIM_TIME_R.N_YEAR_R
        AND EXTRACT (MONTH FROM to_date(FRS.D_CYCLE_DATE_R,'DD-MON-YY')) = DIM_TIME_R.N_MONTH_R
        AND DIM_TIME_R.V_END_OF_FISCAL_MONTH_IND_R = 'Y'
        LEFT JOIN ( SELECT * FROM ATOMIC.DIM_GRP_PRODUCT_R  where V_BASIC_PRODUCT_LINE_CODE_R is not null) product
        ON FRS.V_COVERAGE_CODE_R=product.V_COVERAGE_CODE_R
        LEFT JOIN (SELECT * FROM ATOMIC.dim_grp_policy_dir_r  WHERE v_active_status_r='Y') pol_dir
        ON FRS.v_policy_number_r=pol_dir.v_policy_number_r
        JOIN (select distinct n_version_number_r,N_POLICY_SK_R,n_cust_party_sk_r from  ATOMIC.fct_grp_policy_r ) FP
        ON FP.n_policy_sk_r= pol_dir.n_policy_sk_r
        AND FP.n_version_number_r=pol_dir.n_policy_version_number_r
        LEFT JOIN (select n_customer_number_r,n_party_sk_r from ATOMIC.DIM_GRP_party_dir_r  where v_active_status_r='Y' and v_party_type_r='CUSTOMER') party
        ON party.n_party_sk_r=FP.n_cust_party_sk_r
        WHERE FRS.D_DUE_DATE_R is not null---------------------------------pls check------------------------
        and EXTRACT(YEAR FROM FRS.D_CYCLE_DATE_R)=LN_CURR_YEAR--2023
        group by
        --SYSDATE,
        ld_sysdate,
        DIM_TIME_R.D_CALENDAR_DATE_R ,
        pol_dir.n_policy_sk_r,
        nvl(FP.n_cust_party_sk_r,-1),
        trunc(FRS.D_DUE_DATE_R,'MM') ,
        product.V_BASIC_PRODUCT_LINE_CODE_R ,--/DIM_PRODUCT_R.V_BASIC_PRODUCT_LINE_CODE_R For FCT_RPT_PREMIUM_SUMMARY_R  - look up based on V_COVERAGE_CODE_R/
        pol_dir.v_policy_prefix_r,
        pol_dir.v_policy_suffix_r,
        party.n_customer_number_r ;
		*/
        INSERT /*+APPEND_VALUES*/ INTO ATOMIC.TMP_FCT_RPT_PREMIUM_SUMMARY_R
        select  /*+PARALLEL(4)/
        --DISTINCT /*removed distinct and added grouping */
        --SYSDATE AS D_AS_OF_DATE_R, --Gireesh changes
        LD_SYSDATE AS D_AS_OF_DATE_R,--Gireesh changes
        DIM_TIME_R.D_CALENDAR_DATE_R AS D_CYCLE_DATE_R,
        pol_dir.n_policy_sk_r,
        nvl(FP.n_cust_party_sk_r,-1) AS n_party_sk_r,
        trunc(FRS.D_DUE_DATE_R,'MM') AS d_uw_date_r,
        product.V_BASIC_PRODUCT_LINE_CODE_R AS V_COVERAGE_R,/*DIM_PRODUCT_R.V_BASIC_PRODUCT_LINE_CODE_R For FCT_RPT_PREMIUM_SUMMARY_R  - look up based on V_COVERAGE_CODE_R*/
        pol_dir.v_policy_prefix_r,
        pol_dir.v_policy_suffix_r,
        party.n_customer_number_r AS n_customer_number_r,/*Use the N_CUST_PARTY_SK_R (aka N_PARTY_SK_R - refer to business rule for N_PARTY_SK_R) to look up V_CUSTOMER_NUMBER_R in DIM_GRP_customer_r*/
        sum(FRS.n_earned_prem_amt_r),
        sum(FRS.N_COLLECTED_PREMIUM_AMT_R) AS N_COLL_PREM_AMT_R,
        sum(FRS.N_CHG_DUE_PREM_AMT_R) AS N_CHG_DUE_PREM_AMT_R,
        sum(FRS.N_WRITTEN_PREM_AMT_R) AS N_WRITTEN_PREM_AMT_R,
        sum(FRS.N_CHG_PREM_UNEARNED_AMT_R) AS N_CHG_PREM_UNEARNED_AMT_R,
        sum(FRS.N_CONSTANT_EARNED_PREM_AMT_R) AS N_CONST_EARNED_PREM_AMT_R,
		sum(FRS.N_WRITTEN_PREM_CEDED_AMT_R) as N_WRITTEN_PREM_CEDED_AMT_R,
		sum(FRS.N_WRITTEN_PREM_NET_AMT_R) as N_WRITTEN_PREM_NET_AMT_R,
		sum(FRS.N_CHG_PREM_UNEARNED_NET_AMT_R) as N_CHG_PREM_UNEARNED_NET_AMT_R,
		sum(FRS.N_EARNED_PREM_NET_AMT_R) as N_EARNED_PREM_NET_AMT_R,
		sum(FRS.N_TOTAL_REINS_PREM_PCT_R) as N_REINSURANCE_PCT_R,
		product.V_PRODUCT_LINE_R as V_PRODUCT_LINE_R,
		product.V_PRODUCT_SUB_LINE_CODE_R as V_PRODUCT_SUB_LINE_CODE_R
        from ATOMIC.FCT_RPT_PREMIUM_SUMMARY_R FRS
        LEFT JOIN ATOMIC.DIM_TIME_R
        ON  EXTRACT(YEAR FROM to_date(FRS.D_CYCLE_DATE_R,'DD-MON-YY')) = DIM_TIME_R.N_YEAR_R
        AND EXTRACT (MONTH FROM to_date(FRS.D_CYCLE_DATE_R,'DD-MON-YY')) = DIM_TIME_R.N_MONTH_R
        AND DIM_TIME_R.V_END_OF_FISCAL_MONTH_IND_R = 'Y'
        LEFT JOIN ( SELECT * FROM ATOMIC.DIM_GRP_PRODUCT_R   where V_BASIC_PRODUCT_LINE_CODE_R is not null) product
        ON FRS.V_COVERAGE_CODE_R=product.V_COVERAGE_CODE_R
        LEFT JOIN (SELECT * FROM ATOMIC.dim_grp_policy_dir_r   WHERE v_active_status_r='Y') pol_dir
        --ON FRS.v_policy_number_r=pol_dir.v_policy_number_r--06-Nov-24 changes
        ON FRS.n_policy_sk_r=pol_dir.n_policy_sk_r          --06-Nov-24 changes
        JOIN (select distinct n_version_number_r,N_POLICY_SK_R,n_cust_party_sk_r from  ATOMIC.fct_grp_policy_r  ) FP
        ON FP.n_policy_sk_r= pol_dir.n_policy_sk_r
        AND FP.n_version_number_r=pol_dir.n_policy_version_number_r
        LEFT JOIN (select n_customer_number_r,n_party_sk_r from ATOMIC.DIM_GRP_party_dir_r   where v_active_status_r='Y' and v_party_type_r='CUSTOMER') party
        ON party.n_party_sk_r=FP.n_cust_party_sk_r
        WHERE FRS.D_DUE_DATE_R is not null---------------------------------pls check------------------------
        --and EXTRACT(YEAR FROM FRS.D_CYCLE_DATE_R)=2023      --Gireesh changes
        --and EXTRACT(YEAR FROM FRS.D_CYCLE_DATE_R)=LN_CURR_YEAR--Gireesh changes
		and FRS.D_CYCLE_DATE_R=to_date(ld_fic_mis_date)-1 --Srinith Changes
        group by 
        --SYSDATE, --Gireesh changes
		LD_SYSDATE,--Gireesh changes
        DIM_TIME_R.D_CALENDAR_DATE_R ,
        pol_dir.n_policy_sk_r,
        nvl(FP.n_cust_party_sk_r,-1),
        trunc(FRS.D_DUE_DATE_R,'MM') ,
        product.V_BASIC_PRODUCT_LINE_CODE_R ,/*DIM_PRODUCT_R.V_BASIC_PRODUCT_LINE_CODE_R For FCT_RPT_PREMIUM_SUMMARY_R  - look up based on V_COVERAGE_CODE_R*/
        pol_dir.v_policy_prefix_r,
        pol_dir.v_policy_suffix_r,
        party.n_customer_number_r,
        product.V_PRODUCT_LINE_R,
        product.V_PRODUCT_SUB_LINE_CODE_R
		;
		--29-Oct-2024 changs ends		
        COMMIT;
        lc_trcmsg:=lc_trcmsg||chr(13)||'12.1 Inserted into table TMP_FCT_RPT_PREMIUM_SUMMARY_R:->'||(DBMS_UTILITY.GET_TIME-ln_start_time)||' Seconds';
        ln_cnt:=0;
		lc_trcmsg:=lc_trcmsg||chr(13)||'12.2 Get Number of records Inserted in TMP_FCT_RPT_PREMIUM_SUMMARY_R';
		SELECT COUNT(1) INTO  ln_cnt FROM ATOMIC.TMP_FCT_RPT_PREMIUM_SUMMARY_R  ;
		lc_trcmsg:=lc_trcmsg||chr(13)||'12.3 Number of records Inserted in TMP_FCT_RPT_PREMIUM_SUMMARY_R:->'||ln_cnt;

        lc_trcmsg:=lc_trcmsg||chr(13)||'13 Insert into table FCT_INCURRED_SUMMARY_R';
        ln_start_time:=DBMS_UTILITY.GET_TIME;
        INSERT /*+APPEND_VALUES*/ INTO  ATOMIC.FCT_INCURRED_SUMMARY_R
        (d_as_of_date_r,d_cycle_date_r,n_policy_sk_r,n_party_sk_r,d_uw_date_r,v_coverage_r,v_policy_prefix_r,v_policy_suffix_r,n_customer_number_r,n_earned_prem_amt_r,
        N_COLL_PREM_AMT_R,
        N_CHG_DUE_PREM_AMT_R,N_WRITTEN_PREM_AMT_R,N_CHG_PREM_UNEARNED_AMT_R,N_CONST_EARNED_PREM_AMT_R,N_CONSTANT_PREM_IND_R,
        n_curr_be_ibnr_direct_amt_r,n_curr_field_ibnr_direct_amt_r,n_curr_gaap_ibnr_direct_amt_r,n_curr_stat_ibnr_direct_amt_r,N_PRIOR_GAAP_IBNR_DIRECT_AMT_R,
        N_CHG_GAAP_IBNR_DIRECT_AMT_R,
        N_CUM_GAAP_IBNR_DIRECT_AMT_R,N_PRIOR_STAT_IBNR_DIRECT_AMT_R,N_CHG_STAT_IBNR_DIRECT_AMT_R,N_CUM_STAT_IBNR_DIRECT_AMT_R,N_PRIOR_BE_IBNR_DIRECT_AMT_R,
        N_CHG_BE_IBNR_DIRECT_AMT_R,N_PRIOR_FIELD_IBNR_DIR_AMT_R,
        N_CHG_FIELD_IBNR_DIRECT_AMT_R,
        N_CURR_GAAP_OS_DIRECT_AMT_R,N_CURR_STAT_OS_DIRECT_AMT_R,N_CURR_FIELD_OS_DIRECT_AMT_R,
        N_CURR_STAT_WV_DIRECT_AMT_R,N_CURR_GAAP_WV_DIRECT_AMT_R,N_CURR_BE_WV_DIRECT_AMT_R,N_CURR_FIELD_WV_DIRECT_AMT_R,N_PRIOR_GAAP_OS_DIRECT_AMT_R,N_CHG_GAAP_OS_DIRECT_AMT_R,
        N_PRIOR_STAT_OS_DIRECT_AMT_R,
        N_CHG_STAT_OS_DIRECT_AMT_R,N_PRIOR_BE_OS_DIRECT_AMT_R,N_CHG_BE_OS_DIRECT_AMT_R,N_CURR_BE_OS_DIRECT_AMT_R,N_PRIOR_FIELD_OS_DIRECT_AMT_R,N_CHG_FIELD_OS_DIRECT_AMT_R,
        N_PRIOR_GAAP_WV_DIRECT_AMT_R,
        N_CHG_GAAP_WV_DIRECT_AMT_R,N_PRIOR_STAT_WV_DIRECT_AMT_R,N_CHG_STAT_WV_DIRECT_AMT_R,N_PRIOR_BE_WV_DIRECT_AMT_R,N_CHG_BE_WV_DIRECT_AMT_R,N_PRIOR_FIELD_WV_DIRECT_AMT_R,
        N_CHG_FIELD_WV_DIRECT_AMT_R,N_CURR_GAAP_PV_DIRECT_AMT_R,N_CURR_STAT_PV_DIRECT_AMT_R,N_CURR_BE_PV_DIRECT_AMT_R,N_CURR_CLAIM_COUNT_R,N_CURR_APPROVED_CLAIM_COUNT_R,
        N_CURR_DENIED_CLAIM_COUNT_R,
        n_loss_payment_amt_r,
        N_CURR_ANNUALIZED_PREMIUM_R,N_CURR_NUMBER_OF_LIVES_R,N_CURR_PLR_R,N_SOLD_ANNUALIZED_PREM_R,
        N_CLAIM_SK_R,N_CLAIM_COVERAGE_SK_R,N_QUOTE_SK_R,F_PHYSICAL_DELETE_R,FIC_MIS_DATE_R,N_BATCH_ID_R,N_LOAD_RUN_ID_R,T_CREATION_DATE_R,
        T_EVENT_TIMESTAMP_R,T_LAST_MODIFIED_DATE_R,V_CHANGE_REASON_R,V_CREATED_BY_R,V_LAST_MODIFIED_BY_R,N_SEQUENCE_NUMBER_R
		,N_CURR_OPEN_FIELD_OS_DIRECT_AMT_R,--05-Nov-2024 changes
		N_WRITTEN_PREM_CEDED_AMT_R,
		N_WRITTEN_PREM_NET_AMT_R,
		N_CHG_PREM_UNEARNED_NET_AMT_R,
		N_EARNED_PREM_NET_AMT_R,
		N_REINSURANCE_PCT_R,
		V_PRODUCT_LINE_R,
		N_CHG_STAT_WV_NET_AMT_R,
        N_CHG_GAAP_WV_NET_AMT_R,
		N_CHG_GAAP_IBNR_CEDED_AMT_R,
		N_CHG_STAT_IBNR_CEDED_AMT_R,
        N_LOSS_PAYMENT_CEDED_AMT_R,
		N_CHG_GAAP_OS_CEDED_AMT_R,
		N_CHG_STAT_OS_CEDED_AMT_R)
        WITH FRS AS (
        select d_as_of_date_r,d_cycle_date_r,n_policy_sk_r,n_party_sk_r,d_uw_date_r,v_coverage_r,v_policy_prefix_r,v_policy_suffix_r,n_customer_number_r,
        sum(n_earned_prem_amt_r) AS n_earned_prem_amt_r,sum(N_COLL_PREM_AMT_R) AS N_COLL_PREM_AMT_R,SUM(N_CHG_DUE_PREM_AMT_R) AS N_CHG_DUE_PREM_AMT_R,
        SUM(N_WRITTEN_PREM_AMT_R) AS N_WRITTEN_PREM_AMT_R,
        SUM(N_CHG_PREM_UNEARNED_AMT_R) AS N_CHG_PREM_UNEARNED_AMT_R,SUM(N_CONST_EARNED_PREM_AMT_R) AS N_CONST_EARNED_PREM_AMT_R,
		SUM(N_WRITTEN_PREM_CEDED_AMT_R) AS N_WRITTEN_PREM_CEDED_AMT_R,
		SUM(N_WRITTEN_PREM_NET_AMT_R) AS N_WRITTEN_PREM_NET_AMT_R,
		SUM(N_CHG_PREM_UNEARNED_NET_AMT_R) AS N_CHG_PREM_UNEARNED_NET_AMT_R,
		SUM(N_EARNED_PREM_NET_AMT_R) AS N_EARNED_PREM_NET_AMT_R,
        SUM(N_REINSURANCE_PCT_R) AS N_REINSURANCE_PCT_R,
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
		END V_PRODUCT_LINE_R,V_PRODUCT_SUB_LINE_CODE_R
        from ATOMIC.tmp_FCT_RPT_PREMIUM_SUMMARY_R
        WHERE d_cycle_date_r=TO_DATE(ld_fic_mis_date)-1--d_cycle_date_r in ('29-AUG-23')
        group by d_as_of_date_r,d_cycle_date_r,n_policy_sk_r,n_party_sk_r,d_uw_date_r,v_coverage_r,v_policy_prefix_r,v_policy_suffix_r,n_customer_number_r,
		V_PRODUCT_LINE_R,
		V_PRODUCT_SUB_LINE_CODE_R),
        LGRD AS(
        select d_as_of_date_r,d_cycle_date_r,n_policy_sk_r,v_policy_suffix_r,v_policy_prefix_r,n_party_sk_r,d_uw_date_r,v_coverage_r,sum(n_curr_be_ibnr_direct_amt_r) AS n_curr_be_ibnr_direct_amt_r,
        sum(n_curr_field_ibnr_direct_amt_r) AS n_curr_field_ibnr_direct_amt_r,sum(n_curr_gaap_ibnr_direct_amt_r) AS n_curr_gaap_ibnr_direct_amt_r,
        sum(n_curr_stat_ibnr_direct_amt_r) AS n_curr_stat_ibnr_direct_amt_r,sum(N_PRIOR_GAAP_IBNR_DIRECT_AMT_R) AS N_PRIOR_GAAP_IBNR_DIRECT_AMT_R,
        sum(N_CHG_GAAP_IBNR_DIRECT_AMT_R) AS N_CHG_GAAP_IBNR_DIRECT_AMT_R,sum(N_CUM_GAAP_IBNR_DIRECT_AMT_R) AS N_CUM_GAAP_IBNR_DIRECT_AMT_R,
        sum(N_PRIOR_STAT_IBNR_DIRECT_AMT_R) AS N_PRIOR_STAT_IBNR_DIRECT_AMT_R,
        sum(N_CHG_STAT_IBNR_DIRECT_AMT_R) AS N_CHG_STAT_IBNR_DIRECT_AMT_R,sum(N_CUM_STAT_IBNR_DIRECT_AMT_R) AS N_CUM_STAT_IBNR_DIRECT_AMT_R,
        sum(N_PRIOR_BE_IBNR_DIRECT_AMT_R) AS N_PRIOR_BE_IBNR_DIRECT_AMT_R,
        sum(N_CHG_BE_IBNR_DIRECT_AMT_R) AS N_CHG_BE_IBNR_DIRECT_AMT_R, sum(N_PRIOR_FIELD_IBNR_DIR_AMT_R) AS N_PRIOR_FIELD_IBNR_DIR_AMT_R,
        sum(N_CHG_FIELD_IBNR_DIRECT_AMT_R) AS N_CHG_FIELD_IBNR_DIRECT_AMT_R,
		SUM(N_CHG_STAT_WV_NET_AMT_R) AS N_CHG_STAT_WV_NET_AMT_R,
        SUM(N_CHG_GAAP_WV_NET_AMT_R) AS N_CHG_GAAP_WV_NET_AMT_R,
		SUM(N_CHG_GAAP_IBNR_CEDED_AMT_R) as N_CHG_GAAP_IBNR_CEDED_AMT_R,
		SUM(N_CHG_STAT_IBNR_CEDED_AMT_R) as N_CHG_STAT_IBNR_CEDED_AMT_R,
		V_PRODUCT_LINE_R 
		from atomic.tmp_fct_lg_reserve_details_r
        --WHERE EXTRACT(YEAR FROM to_date(d_cycle_date_r,'DD-MON-YY'))=2017
        WHERE d_cycle_date_r=TO_DATE(ld_fic_mis_date)-1--d_cycle_date_r in ('29-AUG-23')
        group by d_as_of_date_r,d_cycle_date_r,n_policy_sk_r,v_policy_suffix_r,v_policy_prefix_r,n_party_sk_r,d_uw_date_r,v_coverage_R,V_PRODUCT_LINE_R),
        FCS AS(
        select d_as_of_date_r,d_cycle_date_r,n_policy_sk_r,n_party_sk_r,d_uw_date_r,v_coverage_r,v_policy_prefix_r,v_policy_suffix_r,
        sum(N_CURR_GAAP_OS_DIRECT_AMT_R) AS N_CURR_GAAP_OS_DIRECT_AMT_R,sum(N_CURR_STAT_OS_DIRECT_AMT_R) AS N_CURR_STAT_OS_DIRECT_AMT_R,
        sum(N_CURR_FIELD_OS_DIRECT_AMT_R) AS N_CURR_FIELD_OS_DIRECT_AMT_R,
        sum(N_CURR_STAT_WV_DIRECT_AMT_R) AS N_CURR_STAT_WV_DIRECT_AMT_R, sum(N_CURR_GAAP_WV_DIRECT_AMT_R) AS N_CURR_GAAP_WV_DIRECT_AMT_R,
        sum(N_CURR_BE_WV_DIRECT_AMT_R) AS N_CURR_BE_WV_DIRECT_AMT_R,sum(N_CURR_FIELD_WV_DIRECT_AMT_R) AS N_CURR_FIELD_WV_DIRECT_AMT_R,
        sum(N_PRIOR_GAAP_OS_DIRECT_AMT_R) AS N_PRIOR_GAAP_OS_DIRECT_AMT_R,sum(N_CHG_GAAP_OS_DIRECT_AMT_R) AS N_CHG_GAAP_OS_DIRECT_AMT_R,
        sum(N_PRIOR_STAT_OS_DIRECT_AMT_R) AS N_PRIOR_STAT_OS_DIRECT_AMT_R,
        sum(N_CHG_STAT_OS_DIRECT_AMT_R) AS N_CHG_STAT_OS_DIRECT_AMT_R, sum(N_PRIOR_BE_OS_DIRECT_AMT_R) AS N_PRIOR_BE_OS_DIRECT_AMT_R,
        sum(N_CHG_BE_OS_DIRECT_AMT_R) AS N_CHG_BE_OS_DIRECT_AMT_R,
        sum(N_CURR_BE_OS_DIRECT_AMT_R) AS N_CURR_BE_OS_DIRECT_AMT_R,sum(N_PRIOR_FIELD_OS_DIRECT_AMT_R) AS N_PRIOR_FIELD_OS_DIRECT_AMT_R,
        sum(N_CHG_FIELD_OS_DIRECT_AMT_R) AS N_CHG_FIELD_OS_DIRECT_AMT_R,
        sum(N_PRIOR_GAAP_WV_DIRECT_AMT_R) AS N_PRIOR_GAAP_WV_DIRECT_AMT_R,sum(N_CHG_GAAP_WV_DIRECT_AMT_R) AS N_CHG_GAAP_WV_DIRECT_AMT_R,
        sum(N_PRIOR_STAT_WV_DIRECT_AMT_R) AS N_PRIOR_STAT_WV_DIRECT_AMT_R,
        sum(N_CHG_STAT_WV_DIRECT_AMT_R) AS N_CHG_STAT_WV_DIRECT_AMT_R,sum(N_PRIOR_BE_WV_DIRECT_AMT_R) AS N_PRIOR_BE_WV_DIRECT_AMT_R,
        sum(N_CHG_BE_WV_DIRECT_AMT_R) AS N_CHG_BE_WV_DIRECT_AMT_R,
        sum(N_PRIOR_FIELD_WV_DIRECT_AMT_R) AS N_PRIOR_FIELD_WV_DIRECT_AMT_R,sum(N_CHG_FIELD_WV_DIRECT_AMT_R) AS N_CHG_FIELD_WV_DIRECT_AMT_R,
        sum(N_CURR_GAAP_PV_DIRECT_AMT_R) AS N_CURR_GAAP_PV_DIRECT_AMT_R,
        sum(N_CURR_STAT_PV_DIRECT_AMT_R) AS N_CURR_STAT_PV_DIRECT_AMT_R,sum(N_CURR_BE_PV_DIRECT_AMT_R) AS N_CURR_BE_PV_DIRECT_AMT_R,
        sum(N_CURR_CLAIM_COUNT_R) AS N_CURR_CLAIM_COUNT_R,
        sum(N_CURR_APPROVED_CLAIM_COUNT_R) AS N_CURR_APPROVED_CLAIM_COUNT_R,sum(N_CURR_DENIED_CLAIM_COUNT_R) AS N_CURR_DENIED_CLAIM_COUNT_R
		,SUM(N_CURR_OPEN_FIELD_OS_DIRECT_AMT_R) AS N_CURR_OPEN_FIELD_OS_DIRECT_AMT_R,--05-Nov-24 changes
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
		END V_PRODUCT_LINE_R,V_PRODUCT_SUB_LINE_CODE_R,
		SUM(N_CHG_GAAP_OS_CEDED_AMT_R) AS N_CHG_GAAP_OS_CEDED_AMT_R,
		SUM(N_CHG_STAT_OS_CEDED_AMT_R) AS N_CHG_STAT_OS_CEDED_AMT_R 
		from ATOMIC.TMP_fct_rpt_claim_summary_r
        --WHERE EXTRACT(YEAR FROM to_date(d_cycle_date_r,'DD-MON-YY'))=2017
        WHERE d_cycle_date_r=TO_DATE(ld_fic_mis_date)-1--d_cycle_date_r in ('29-AUG-23')
        group by d_as_of_date_r,d_cycle_date_r,n_policy_sk_r,n_party_sk_r,d_uw_date_r,v_coverage_r, v_policy_prefix_r,v_policy_suffix_r,
		V_PRODUCT_LINE_R,V_PRODUCT_SUB_LINE_CODE_R),
        FCPD AS (
        select d_as_of_date_r, d_cycle_date_r,d_uw_date_r,n_policy_sk_r,n_party_sk_r,v_policy_prefix_r,v_policy_suffix_r,v_coverage_r,D_UW_DATE_MONTH_R, D_UW_DATE_YEAR_R, SUM(loss_amount) AS n_loss_payment_amt_r,SUM(N_LOSS_PAYMENT_CEDED_AMT_R) AS N_LOSS_PAYMENT_CEDED_AMT_R
        From atomic.tmp_FCT_CLAIM_PAYMENT_DETAIL_R
        WHERE d_cycle_date_r=TO_DATE(ld_fic_mis_date)-1--d_cycle_date_r in ('29-AUG-23')
        --WHERE EXTRACT(YEAR FROM to_date(d_cycle_date_r,'DD-MON-YY'))=2017
        group by d_as_of_date_r, d_cycle_date_r,d_uw_date_r,n_policy_sk_r,n_party_sk_r,v_policy_prefix_r,v_policy_suffix_r,v_coverage_r,D_UW_DATE_MONTH_R, D_UW_DATE_YEAR_R
        ),
        FAPS AS(
        select d_as_of_date_r,d_cycle_date_r,n_policy_sk_r,v_policy_prefix_r,v_policy_suffix_r,n_party_sk_r,d_uw_date_r,v_coverage_r,sum(N_CURR_ANNUALIZED_PREMIUM_R) AS N_CURR_ANNUALIZED_PREMIUM_R,
        --sum(N_GROSS_LIVES_R) AS N_CURR_NUMBER_OF_LIVES_R        --Erica changes
        sum(N_CURR_NUMBER_OF_LIVES_R) AS N_CURR_NUMBER_OF_LIVES_R, --Erica changes,
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
		END V_PRODUCT_LINE_R,V_PRODUCT_SUB_LINE_CODE_R 
        FROM ATOMIC.tmp_FCT_RPT_ANN_PREM_SUMMARY_R
        WHERE d_cycle_date_r=TO_DATE(ld_fic_mis_date)-1--d_cycle_date_r in ('29-AUG-23')
        --WHERE EXTRACT(YEAR FROM to_date(d_cycle_date_r,'DD-MON-YY'))=2017
        group by d_as_of_date_r,d_cycle_date_r,n_policy_sk_r,v_policy_suffix_r,v_policy_prefix_r,n_party_sk_r,d_uw_date_r,v_coverage_r,V_PRODUCT_LINE_R,V_PRODUCT_SUB_LINE_CODE_R
        ),
        FACS AS (select d_cycle_date_r,d_as_of_date_r,d_uw_date_r, D_CYCLE_DATE_R_START, D_CYCLE_DATE_R_END, n_policy_sk_r,v_policy_prefix_r,v_policy_suffix_r,n_party_sk_r,N_CURR_PLR_R, N_SOLD_ANNUALIZED_PREM_R
        FROM ATOMIC.tmp_FCT_RPT_ACT_PLR_SUMMARY_R
        WHERE d_cycle_date_r=TO_DATE(ld_fic_mis_date)-1--d_cycle_date_r in ('29-AUG-23')
        --WHERE EXTRACT(YEAR FROM to_date(D_CYCLE_DATE_R_START,'DD-MON-YY'))=2017
        ),
        CURRENT_BASE AS
        (
        SELECT DISTINCT
        coalesce(FRS.d_as_of_date_r,FCS.d_as_of_date_r,LGRD.d_as_of_date_r,FAPS.d_as_of_date_r,FACS.d_as_of_date_r, FCPD.d_as_of_date_r) AS d_as_of_date_r,
        coalesce(FRS.d_cycle_date_r,FCS.d_cycle_date_r,LGRD.d_cycle_date_r,FAPS.d_cycle_date_r,FACS.d_cycle_date_r,FCPD.d_cycle_date_r) AS d_cycle_date_r,
        coalesce(FRS.n_policy_sk_r,FCS.n_policy_sk_r,LGRD.n_policy_sk_r,FAPS.n_policy_sk_r,FACS.n_policy_sk_r,FCPD.n_policy_sk_r) AS n_policy_sk_r,
        nvl(coalesce(FRS.n_party_sk_r,FCS.n_party_sk_r,LGRD.n_party_sk_r,FAPS.n_party_sk_r,FACS.n_party_sk_r,FCPD.n_party_sk_r),-1) AS n_party_sk_r,
        coalesce(FRS.d_uw_date_r,FCS.d_uw_date_r,LGRD.d_uw_date_r,FAPS.d_uw_date_r,FACS.d_uw_date_r, FCPD.d_uw_date_r) AS d_uw_date_r,
        coalesce(FRS.v_coverage_r,FCS.v_coverage_r,LGRD.v_coverage_r,FAPS.v_coverage_r, FCPD.v_coverage_r, FRS.v_policy_prefix_r,FCS.v_policy_prefix_r,LGRD.v_policy_prefix_r, FAPS.v_policy_prefix_r, FACS.v_policy_prefix_r,FCPD.v_policy_prefix_r) AS v_coverage_r,
        coalesce(FRS.v_policy_prefix_r,FCS.v_policy_prefix_r,LGRD.v_policy_prefix_r, FAPS.v_policy_prefix_r, FACS.v_policy_prefix_r,FCPD.v_policy_prefix_r) AS v_policy_prefix_r,
        coalesce(FRS.v_policy_suffix_r,FCS.v_policy_suffix_r, LGRD.v_policy_suffix_r, FAPS.v_policy_suffix_r,FACS.v_policy_suffix_r,FCPD.v_policy_suffix_r) As v_policy_suffix_r,
        party.n_customer_number_r,FRS.n_earned_prem_amt_r,FRS.N_COLL_PREM_AMT_R,FRS.N_CHG_DUE_PREM_AMT_R,FRS.N_WRITTEN_PREM_AMT_R,FRS.N_CHG_PREM_UNEARNED_AMT_R,
        FRS.N_CONST_EARNED_PREM_AMT_R,CASE WHEN FRS.N_EARNED_PREM_AMT_R = FRS.N_CONST_EARNED_PREM_AMT_R THEN '0' ELSE '1' END AS N_CONSTANT_PREM_IND_R,
        LGRD.n_curr_be_ibnr_direct_amt_r,LGRD.n_curr_field_ibnr_direct_amt_r,LGRD.n_curr_gaap_ibnr_direct_amt_r,LGRD.n_curr_stat_ibnr_direct_amt_r,
        LGRD.N_PRIOR_GAAP_IBNR_DIRECT_AMT_R,LGRD.N_CHG_GAAP_IBNR_DIRECT_AMT_R,LGRD.N_CUM_GAAP_IBNR_DIRECT_AMT_R,LGRD.N_PRIOR_STAT_IBNR_DIRECT_AMT_R,
        LGRD.N_CHG_STAT_IBNR_DIRECT_AMT_R,LGRD.N_CUM_STAT_IBNR_DIRECT_AMT_R,LGRD.N_PRIOR_BE_IBNR_DIRECT_AMT_R,LGRD.N_CHG_BE_IBNR_DIRECT_AMT_R,
        LGRD.N_PRIOR_FIELD_IBNR_DIR_AMT_R,LGRD.N_CHG_FIELD_IBNR_DIRECT_AMT_R,FCS.N_CURR_GAAP_OS_DIRECT_AMT_R,FCS.N_CURR_STAT_OS_DIRECT_AMT_R,FCS.N_CURR_FIELD_OS_DIRECT_AMT_R,
        FCS.N_CURR_STAT_WV_DIRECT_AMT_R,FCS.N_CURR_GAAP_WV_DIRECT_AMT_R,FCS.N_CURR_BE_WV_DIRECT_AMT_R,FCS.N_CURR_FIELD_WV_DIRECT_AMT_R,FCS.N_PRIOR_GAAP_OS_DIRECT_AMT_R,
        FCS.N_CHG_GAAP_OS_DIRECT_AMT_R,FCS.N_PRIOR_STAT_OS_DIRECT_AMT_R,FCS.N_CHG_STAT_OS_DIRECT_AMT_R,FCS.N_PRIOR_BE_OS_DIRECT_AMT_R, FCS.N_CHG_BE_OS_DIRECT_AMT_R,
        FCS.N_CURR_BE_OS_DIRECT_AMT_R,FCS.N_PRIOR_FIELD_OS_DIRECT_AMT_R,FCS.N_CHG_FIELD_OS_DIRECT_AMT_R,FCS.N_PRIOR_GAAP_WV_DIRECT_AMT_R,FCS.N_CHG_GAAP_WV_DIRECT_AMT_R,
        FCS.N_PRIOR_STAT_WV_DIRECT_AMT_R,FCS.N_CHG_STAT_WV_DIRECT_AMT_R,FCS.N_PRIOR_BE_WV_DIRECT_AMT_R,FCS.N_CHG_BE_WV_DIRECT_AMT_R,FCS.N_PRIOR_FIELD_WV_DIRECT_AMT_R ,
        FCS.N_CHG_FIELD_WV_DIRECT_AMT_R ,FCS.N_CURR_GAAP_PV_DIRECT_AMT_R,FCS.N_CURR_STAT_PV_DIRECT_AMT_R,FCS.N_CURR_BE_PV_DIRECT_AMT_R,FCS.N_CURR_CLAIM_COUNT_R,
        FCS.N_CURR_APPROVED_CLAIM_COUNT_R,FCS.N_CURR_DENIED_CLAIM_COUNT_R
		,FCS.N_CURR_OPEN_FIELD_OS_DIRECT_AMT_R,--05-Nov-24 changes
		N_WRITTEN_PREM_CEDED_AMT_R,
		N_WRITTEN_PREM_NET_AMT_R,
		N_CHG_PREM_UNEARNED_NET_AMT_R,
		N_EARNED_PREM_NET_AMT_R,
		FRS.N_REINSURANCE_PCT_R as N_REINSURANCE_PCT_R,
		coalesce(FRS.V_PRODUCT_LINE_R,FCS.V_PRODUCT_LINE_R,FAPS.V_PRODUCT_LINE_R,LGRD.V_PRODUCT_LINE_R) AS V_PRODUCT_LINE_R,
		LGRD.N_CHG_STAT_WV_NET_AMT_R,
		LGRD.N_CHG_GAAP_WV_NET_AMT_R
		,
		LGRD.N_CHG_GAAP_IBNR_CEDED_AMT_R,
		LGRD.N_CHG_STAT_IBNR_CEDED_AMT_R,
        FCPD.n_loss_payment_amt_r,
		FCPD.N_LOSS_PAYMENT_CEDED_AMT_R,
		FCS.N_CHG_GAAP_OS_CEDED_AMT_R,
		FCS.N_CHG_STAT_OS_CEDED_AMT_R,
        FAPS.N_CURR_ANNUALIZED_PREMIUM_R,FAPS.N_CURR_NUMBER_OF_LIVES_R,FACS.N_CURR_PLR_R,FACS.N_SOLD_ANNUALIZED_PREM_R,
        -1 AS N_CLAIM_SK_R ,
        -1 AS N_CLAIM_COVERAGE_SK_R,
        -1 AS N_QUOTE_SK_R  ,
        ' ' AS F_PHYSICAL_DELETE_R ,
        --SYSDATE AS FIC_MIS_DATE_R ,
        ld_sysdate AS FIC_MIS_DATE_R ,
        --to_char(SYSDATE ,'YYYYMMDD') AS N_BATCH_ID_R ,
        ln_n_batch_id_r AS N_BATCH_ID_R ,
        '-1' AS N_LOAD_RUN_ID_R,
        LT_SYSTIMESTAMP  AS T_CREATION_DATE_R ,
        '' AS T_EVENT_TIMESTAMP_R,
        LT_SYSTIMESTAMP  AS T_LAST_MODIFIED_DATE_R,
        ' ' AS V_CHANGE_REASON_R,
        'PRC_GRP_LOAD_FCT_INCURRED_SUMMARY_R' AS V_CREATED_BY_R,
        'PRC_GRP_LOAD_FCT_INCURRED_SUMMARY_R' AS V_LAST_MODIFIED_BY_R
        FROM FRS
        FULL JOIN FCS
        ON  FRS.V_COVERAGE_R=FCS.V_COVERAGE_R AND  FRS.n_policy_sk_r=FCS.n_policy_sk_r AND FRS.n_party_sk_r=FCS.n_party_sk_r AND FRS.D_UW_DATE_R=FCS.D_UW_DATE_R
        AND  FRS.D_CYCLE_DATE_R=FCS.D_CYCLE_DATE_R
        FULL JOIN LGRD
        ON coalesce(FRS.V_COVERAGE_R,FCS.V_COVERAGE_R)=LGRD.V_COVERAGE_R AND  coalesce(FRS.n_policy_sk_r,FCS.n_policy_sk_r)=LGRD.n_policy_sk_r AND coalesce(FRS.n_party_sk_r,FCS.n_party_sk_r)=LGRD.n_party_sk_r AND coalesce(FRS.D_UW_DATE_R,FCS.D_UW_DATE_R) =LGRD.D_UW_DATE_R
        AND  coalesce(FRS.D_CYCLE_DATE_R,FCS.D_CYCLE_DATE_R) =LGRD.D_CYCLE_DATE_R
        FULL JOIN FAPS
        ON  coalesce(FRS.V_COVERAGE_R,FCS.V_COVERAGE_R, LGRD.V_COVERAGE_R )=FAPS.V_COVERAGE_R AND coalesce(FRS.n_policy_sk_r,FCS.n_policy_sk_r, LGRD.n_policy_sk_r)=FAPS.n_policy_sk_r AND coalesce(FRS.n_party_sk_r,FCS.n_party_sk_r, LGRD.n_party_sk_r)=FAPS.n_party_sk_r AND coalesce(FRS.D_UW_DATE_R,FCS.D_UW_DATE_R, LGRD.D_UW_DATE_R )=FAPS.D_UW_DATE_R
        AND  coalesce(FRS.D_CYCLE_DATE_R,FCS.D_CYCLE_DATE_R, LGRD.D_CYCLE_DATE_R)=FAPS.D_CYCLE_DATE_R
        FULL JOIN FACS
        ON  coalesce(FRS.n_policy_sk_r,FCS.n_policy_sk_r, LGRD.n_policy_sk_r, FAPS.n_policy_sk_r)=FACS.n_policy_sk_r AND
        coalesce(FRS.n_party_sk_r,FCS.n_party_sk_r, LGRD.n_party_sk_r, FAPS.n_party_sk_r)=FACS.n_party_sk_r AND
        coalesce(FRS.D_CYCLE_DATE_R,FCS.D_CYCLE_DATE_R, LGRD.D_CYCLE_DATE_R, FAPS.D_CYCLE_DATE_R) = FACS.D_CYCLE_DATE_R AND
        coalesce(FRS.d_uw_date_r,FCS.d_uw_date_r, LGRD.d_uw_date_r, FAPS.d_uw_date_r) = FACS.d_uw_date_r
        FULL JOIN FCPD
        ON   coalesce(FRS.n_policy_sk_r,FCS.n_policy_sk_r,LGRD.n_policy_sk_r,FAPS.n_policy_sk_r,FACS.n_policy_sk_r)=FCPD.n_policy_sk_r  AND
        coalesce(FRS.d_cycle_date_r,FCS.d_cycle_date_r,LGRD.d_cycle_date_r,FAPS.d_cycle_date_r)=FCPD.D_CYCLE_DATE_R AND
        coalesce(FRS.d_uw_date_r,FCS.d_uw_date_r,LGRD.d_uw_date_r,FAPS.d_uw_date_r) = FCPD.d_uw_date_r AND
        coalesce(FRS.V_COVERAGE_R,FCS.V_COVERAGE_R, LGRD.V_COVERAGE_R, FAPS.V_COVERAGE_R )= FCPD.V_COVERAGE_R
        LEFT JOIN (select n_customer_number_r,n_party_sk_r from ATOMIC.DIM_GRP_party_dir_r   where v_active_status_r='Y' and v_party_type_r='CUSTOMER') party
        on party.n_party_sk_r = nvl(coalesce(FRS.n_party_sk_r,FCS.n_party_sk_r,LGRD.n_party_sk_r,FAPS.n_party_sk_r,FACS.n_party_sk_r),-1)

        )
        SELECT
        d_as_of_date_r,d_cycle_date_r,n_policy_sk_r,n_party_sk_r,d_uw_date_r,v_coverage_r,v_policy_prefix_r,v_policy_suffix_r,n_customer_number_r,n_earned_prem_amt_r,
        N_COLL_PREM_AMT_R,
        N_CHG_DUE_PREM_AMT_R,N_WRITTEN_PREM_AMT_R,N_CHG_PREM_UNEARNED_AMT_R,N_CONST_EARNED_PREM_AMT_R,N_CONSTANT_PREM_IND_R,
        n_curr_be_ibnr_direct_amt_r,n_curr_field_ibnr_direct_amt_r,n_curr_gaap_ibnr_direct_amt_r,n_curr_stat_ibnr_direct_amt_r,N_PRIOR_GAAP_IBNR_DIRECT_AMT_R,
        N_CHG_GAAP_IBNR_DIRECT_AMT_R,
        N_CUM_GAAP_IBNR_DIRECT_AMT_R,N_PRIOR_STAT_IBNR_DIRECT_AMT_R,N_CHG_STAT_IBNR_DIRECT_AMT_R,N_CUM_STAT_IBNR_DIRECT_AMT_R,N_PRIOR_BE_IBNR_DIRECT_AMT_R,
        N_CHG_BE_IBNR_DIRECT_AMT_R,N_PRIOR_FIELD_IBNR_DIR_AMT_R,
        N_CHG_FIELD_IBNR_DIRECT_AMT_R,
        N_CURR_GAAP_OS_DIRECT_AMT_R,N_CURR_STAT_OS_DIRECT_AMT_R,N_CURR_FIELD_OS_DIRECT_AMT_R,
        N_CURR_STAT_WV_DIRECT_AMT_R,N_CURR_GAAP_WV_DIRECT_AMT_R,N_CURR_BE_WV_DIRECT_AMT_R,N_CURR_FIELD_WV_DIRECT_AMT_R,
		N_PRIOR_GAAP_OS_DIRECT_AMT_R,
		N_CHG_GAAP_OS_DIRECT_AMT_R,
        N_PRIOR_STAT_OS_DIRECT_AMT_R,
        N_CHG_STAT_OS_DIRECT_AMT_R,N_PRIOR_BE_OS_DIRECT_AMT_R,N_CHG_BE_OS_DIRECT_AMT_R,N_CURR_BE_OS_DIRECT_AMT_R,N_PRIOR_FIELD_OS_DIRECT_AMT_R,N_CHG_FIELD_OS_DIRECT_AMT_R,
        N_PRIOR_GAAP_WV_DIRECT_AMT_R,
        N_CHG_GAAP_WV_DIRECT_AMT_R,N_PRIOR_STAT_WV_DIRECT_AMT_R,N_CHG_STAT_WV_DIRECT_AMT_R,N_PRIOR_BE_WV_DIRECT_AMT_R,N_CHG_BE_WV_DIRECT_AMT_R,N_PRIOR_FIELD_WV_DIRECT_AMT_R,
        N_CHG_FIELD_WV_DIRECT_AMT_R,N_CURR_GAAP_PV_DIRECT_AMT_R,N_CURR_STAT_PV_DIRECT_AMT_R,N_CURR_BE_PV_DIRECT_AMT_R,N_CURR_CLAIM_COUNT_R,N_CURR_APPROVED_CLAIM_COUNT_R,
        N_CURR_DENIED_CLAIM_COUNT_R,
        n_loss_payment_amt_r,
        N_CURR_ANNUALIZED_PREMIUM_R,N_CURR_NUMBER_OF_LIVES_R,
        CASE WHEN EXTRACT(MONTH FROM d_cycle_date_r) = EXTRACT(MONTH FROM d_uw_date_r) AND EXTRACT(YEAR FROM d_cycle_date_r) = EXTRACT(YEAR FROM d_uw_date_r) THEN N_CURR_PLR_R ELSE NULL END AS N_CURR_PLR_R,
        CASE WHEN EXTRACT(MONTH FROM d_cycle_date_r) = EXTRACT(MONTH FROM d_uw_date_r) AND EXTRACT(YEAR FROM d_cycle_date_r) = EXTRACT(YEAR FROM d_uw_date_r) THEN N_SOLD_ANNUALIZED_PREM_R ELSE NULL END AS N_SOLD_ANNUALIZED_PREM_R,
        N_CLAIM_SK_R,N_CLAIM_COVERAGE_SK_R,N_QUOTE_SK_R,F_PHYSICAL_DELETE_R,FIC_MIS_DATE_R,N_BATCH_ID_R,N_LOAD_RUN_ID_R,T_CREATION_DATE_R,
        T_EVENT_TIMESTAMP_R,T_LAST_MODIFIED_DATE_R,V_CHANGE_REASON_R,V_CREATED_BY_R,V_LAST_MODIFIED_BY_R,
        ROWNUM AS N_SEQUENCE_NUMBER_R
		,N_CURR_OPEN_FIELD_OS_DIRECT_AMT_R,--05-Nov-24 changes	
		N_WRITTEN_PREM_CEDED_AMT_R,
        N_WRITTEN_PREM_NET_AMT_R,
        N_CHG_PREM_UNEARNED_NET_AMT_R,
        N_EARNED_PREM_NET_AMT_R,
        N_REINSURANCE_PCT_R,
        V_PRODUCT_LINE_R,
        N_CHG_STAT_WV_NET_AMT_R,
		N_CHG_GAAP_WV_NET_AMT_R,
		N_CHG_GAAP_IBNR_CEDED_AMT_R,
		N_CHG_STAT_IBNR_CEDED_AMT_R,
		N_LOSS_PAYMENT_CEDED_AMT_R,
		N_CHG_GAAP_OS_CEDED_AMT_R,
		N_CHG_STAT_OS_CEDED_AMT_R 
        FROM CURRENT_BASE
        Where v_policy_prefix_r not in ('ADA','BCD','BCL','BCM','BCS','BEC','BEM','BES','FML','GGL','MSF','SLC','SLF','SLM','VF');
        commit;
        lc_trcmsg:=lc_trcmsg||chr(13)||'13.1 Inserted into table FCT_INCURRED_SUMMARY_R:->'||(DBMS_UTILITY.GET_TIME-ln_start_time)||' Seconds';
        ln_cnt:=0;
		lc_trcmsg:=lc_trcmsg||chr(13)||'13.1 Get Number of records Inserted in FCT_INCURRED_SUMMARY_R';
		SELECT COUNT(1) INTO  ln_cnt FROM ATOMIC.FCT_INCURRED_SUMMARY_R WHERE TRUNC(T_CREATION_DATE_R)=TRUNC(LD_SYSDATE) ;
		lc_trcmsg:=lc_trcmsg||chr(13)||'13.2 Number of records Inserted in FCT_INCURRED_SUMMARY_R:->'||ln_cnt;

    ELSE
	  lc_trcmsg:=lc_trcmsg||chr(13)||'14. The current date is NOT Fiscal Month End Date , So data will not be loaded';



    END IF;

	lc_trcmsg:=lc_trcmsg||chr(13)||'15. Insert trace message into the table PRCS_GRP_TBL_LOAD_DEBUG_TRC';
    INSERT INTO ATOMIC.PRCS_GRP_TBL_LOAD_DEBUG_TRC(V_JOB_NAME_R
                                                   ,V_PKG_PRC_NAME_R
                                                   ,N_SK_R
                                                   ,V_NUMBER_R
                                                   ,V_TRC_MSG_R
                                                   ,N_BATCH_ID_R
                                                   ,v_created_by_r
                                                   ,V_LAST_MODIFIED_BY_R
                                                  )
    										VALUES('GRP_LOAD_FCT_INCURRED_SUMMARY_R'
    										      ,'PRC_GRP_LOAD_FCT_INCURRED_SUMMARY_R'
    											  ,NULL
    											  ,NULL
    											  ,lc_trcmsg
    											  ,ln_N_BATCH_ID_R
    											  ,'PRC_GRP_LOAD_FCT_INCURRED_SUMMARY_R'
    											  ,'PRC_GRP_LOAD_FCT_INCURRED_SUMMARY_R'
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
										VALUES('GRP_LOAD_FCT_INCURRED_SUMMARY_R'
										      ,'PRC_GRP_LOAD_FCT_INCURRED_SUMMARY_R'
											  ,NULL
											  ,NULL
											  ,'When others raised in PRC_GRP_LOAD_FCT_INCURRED_SUMMARY_R :->'||lc_trcmsg||LC_SQLCODE||'->'||LC_SQLERRM
											  ,ln_N_BATCH_ID_R
											  ,'PRC_GRP_LOAD_FCT_INCURRED_SUMMARY_R'
											  ,'PRC_GRP_LOAD_FCT_INCURRED_SUMMARY_R'
										);

commit;
raise_application_error(-20001,'Others-Error in PRC_GRP_LOAD_FCT_INCURRED_SUMMARY_R:->'||LC_SQLERRM);

END PRC_GRP_LOAD_FCT_INCURRED_SUMMARY_R;

/

  GRANT EXECUTE ON "ATOMIC"."PRC_GRP_LOAD_FCT_INCURRED_SUMMARY_R" TO "EXT_EIS_RO";
  GRANT EXECUTE ON "ATOMIC"."PRC_GRP_LOAD_FCT_INCURRED_SUMMARY_R" TO "ATOMIC_ALL_RO";
  GRANT EXECUTE ON "ATOMIC"."PRC_GRP_LOAD_FCT_INCURRED_SUMMARY_R" TO "EXT_DIGITAL_RO";
  GRANT DEBUG ON "ATOMIC"."PRC_GRP_LOAD_FCT_INCURRED_SUMMARY_R" TO "ATOMIC_DEBUG";
