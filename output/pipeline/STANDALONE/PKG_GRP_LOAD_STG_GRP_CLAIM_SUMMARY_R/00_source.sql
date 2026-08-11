

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ATOMIC"."PKG_GRP_LOAD_STG_GRP_CLAIM_SUMMARY_R"
IS
PROCEDURE prc_debug_trace(p_msg IN VARCHAR2,p_debug_flag IN VARCHAR2)
IS
BEGIN
    IF NVL(p_debug_flag,'N') ='Y' THEN
	   gc_trc_msg:=gc_trc_msg||p_msg||CHR(10);
	END IF;
EXCEPTION
when OTHERS then
NULL;
END PRC_DEBUG_TRACE;
PROCEDURE prc_debug_exec_time(p_msg IN VARCHAR2,p_debug_flag IN VARCHAR2,p_start_time IN NUMBER)
IS
BEGIN
    IF NVL(p_debug_flag,'N') ='Y' THEN
	   gc_trc_msg:=gc_trc_msg||CHR(10)||p_msg||'->>'||((dbms_utility.get_time - p_start_time)/100 || ' Seconds');
	END IF;
EXCEPTION
WHEN OTHERS THEN
NULL;
END PRC_DEBUG_EXEC_TIME;

function GET_MAXRESERVAL_DATE_R(P_D_cycle_date_r in DATE) return date--24-Nov-2021 changes
is
LD_MAXRESERVAL_DATE_R DATE;
BEGIN
SELECT
     MAX(flrd2.d_reserve_valuation_date_r) INTO LD_MAXRESERVAL_DATE_R
     FROM atomic.fct_lg_reserve_details_r flrd2
     WHERE --flrd2.n_claim_sk_r = p_n_claim_sk_r
           --flrd2.v_claim_number_r = lv_claim_number_r  --Commented on 05-Aug-2022
           --AND flrd2.v_reserve_type_ind_r =p_v_reserve_type_ind_r
           --AND
      flrd2.d_reserve_valuation_date_r <= P_D_cycle_date_r--ATOMIC.PKG_GRP_LOAD_STG_GRP_CLAIM_SUMMARY_R.get_d_cycle_date_r(p_n_batch_id_r)
	;
RETURN LD_MAXRESERVAL_DATE_R;
EXCEPTION
WHEN OTHERS THEN
  --DBMS_OUTPUT.PUT_LINE('Error Occured in GET_MAXRESERVAL_DATE_R :->'||SQLERRM);
--  prc_debug_trace('GET_MAXRESERVAL_DATE_R:->'||SQLERRM||CHR(13),gc_debug_flag);
  return null;
end GET_MAXRESERVAL_DATE_R;


function GET_D_CYCLE_DATE_R(P_N_BATCH_ID_R in number) return date--24-Nov-2021 changes
is
ld_calendar_date_r ATOMIC.DIM_TIME_R.D_CALENDAR_DATE_R%TYPE;
BEGIN
select
 D_CALENDAR_DATE_R into ld_calendar_date_r from
(SELECT  D_CALENDAR_DATE_R, RANK() OVER (ORDER BY D_CALENDAR_DATE_R DESC) DATE_RANK from ATOMIC.DIM_TIME_R
where
--V_END_OF_FISCAL_MONTH_IND_R = 'Y' and D_CALENDAR_DATE_R < ADD_MONTHS(TO_DATE(SUBSTR(P_N_BATCH_ID_R, 1, 8), 'YYYYMMDD'),1)
V_END_OF_FISCAL_MONTH_IND_R = 'Y' and D_CALENDAR_DATE_R < ADD_MONTHS(TO_DATE(SUBSTR(P_N_BATCH_ID_R, 1, 6), 'YYYYMM'),1)
--need added for Incre testing 06-Jun-2022 since we are passing batchid as 202204 Apr-2022
)
where DATE_RANK =1
;
return ld_calendar_date_r;
EXCEPTION
WHEN OTHERS THEN
  --DBMS_OUTPUT.PUT_LINE('Error Occured in GET_D_CYCLE_DATE_R :->'||SQLERRM);
--  prc_debug_trace('GET_D_CYCLE_DATE_R:->'||SQLERRM||CHR(13),gc_debug_flag);
  return null;
end GET_D_CYCLE_DATE_R;

FUNCTION get_prior_fiscal_date(p_n_batch_id_r IN NUMBER) RETURN DATE
IS
ld_d_calendar_date_r dim_time_r.d_calendar_date_r%type;
ln_prior_fiscal_month NUMBER;
BEGIN
SELECT
    MAX(d_calendar_date_r)
    INTO ld_d_calendar_date_r
    FROM atomic.dim_time_r
   WHERE --TO_CHAR(d_calendar_date_r,'YYYYMMDD') < SUBSTR(p_n_batch_id_r,1,8)
     D_CALENDAR_DATE_R < to_date(SUBSTR(p_n_batch_id_r ,1,8),'yyyymmdd')
     AND v_end_of_fiscal_month_ind_r = 'Y';
 -- atomic.PKG_GRP_LOAD_STG_GRP_CLAIM_SUMMARY_R.prc_debug_trace('get_prior_fiscal_date:->'||ld_d_calendar_date_r||CHR(13),gc_debug_flag);
return ld_d_calendar_date_r;
EXCEPTION
WHEN OTHERS THEN
  --DBMS_OUTPUT.PUT_LINE('Error Occured in ATOMIC.PKG_GRP_LOAD_STG_GRP_CLAIM_SUMMARY_R.get_prior_fiscal_month :->'||SQLERRM);
 -- atomic.PKG_GRP_LOAD_STG_GRP_CLAIM_SUMMARY_R.prc_debug_trace('get_prior_fiscal_date:->'||SQLERRM||CHR(13),gc_debug_flag);
  RETURN NULL;
END get_prior_fiscal_date;

FUNCTION get_current_fiscal_date (p_n_batch_id_r IN NUMBER) RETURN DATE
IS
ld_d_calendar_date_r    DATE;
ln_fiscal_year_r        atomic.dim_time_r.n_fiscal_year_r%TYPE;
LN_FISCAL_MONTH_R       ATOMIC.DIM_TIME_R.N_FISCAL_MONTH_R%type;
Lc_FISCAL_MONTH_R VARCHAR2(30);
CURSOR cur_fisc_year_month
IS
  SELECT
    n_fiscal_month_r
	,n_fiscal_year_r
    FROM atomic.dim_time_r --;ORDER BY D_CALENDAR_DATE_R DESC;
   WHERE --TO_NUMBER(TO_CHAR(d_calendar_date_r,'YYYYMMDD')) = TO_NUMBER(TO_CHAR(SYSDATE,'YYYYMMDD'))
   d_calendar_date_r = trunc(SYSDATE);

BEGIN
/*Join to dim_time_r based on today's date = D_CALENDAR_DATE_R to get the N_FISCAL_MONTH_R and N_FISCAL_YEAR_R
Then look up where V_END_OF_FISCAL_MONTH_IND_R = 'Y' for that N_FISCAL_MONTH_R and N_FISCAL_YEAR_R*/
  if TO_CHAR(SUBSTR(P_N_BATCH_ID_R,1,6)) = TO_CHAR(sysdate,'YYYYMM') then
  OPEN cur_fisc_year_month;
  FETCH cur_fisc_year_month INTO ln_fiscal_month_r,ln_fiscal_year_r;
  close CUR_FISC_YEAR_MONTH;
  SELECT
    MAX(d_calendar_date_r)
    INTO ld_d_calendar_date_r
    from ATOMIC.DIM_TIME_R
   where n_fiscal_month_r||n_fiscal_year_r=ln_fiscal_month_r||ln_fiscal_year_r
     AND v_end_of_fiscal_month_ind_r = 'Y';
  else
  Lc_FISCAL_MONTH_R:= (SUBSTR(P_N_BATCH_ID_R,5,2));
  ln_fiscal_year_r:=TO_NUMBER(SUBSTR(P_N_BATCH_ID_R,1,4));
  SELECT
    max(D_CALENDAR_DATE_R)
    INTO ld_d_calendar_date_r
    from ATOMIC.DIM_TIME_R
   where
   (n_fiscal_month_r||n_fiscal_year_r)=LTRIM(lc_fiscal_month_r||ln_fiscal_year_r,0)
     and V_END_OF_FISCAL_MONTH_IND_R = 'Y';
  END IF;

  --atomic.PKG_GRP_LOAD_STG_GRP_CLAIM_SUMMARY_R.prc_debug_trace('get_current_fiscal_date:->'||ld_d_calendar_date_r||CHR(13),gc_debug_flag);

return ld_d_calendar_date_r;
EXCEPTION
WHEN OTHERS THEN
  --DBMS_OUTPUT.PUT_LINE('Error Occured in ATOMIC.PKG_GRP_LOAD_STG_GRP_CLAIM_SUMMARY_R.get_current_fiscal_month :->'||SQLERRM);
  --atomic.PKG_GRP_LOAD_STG_GRP_CLAIM_SUMMARY_R.prc_debug_trace('get_current_fiscal_date:->'||SQLERRM||CHR(13),gc_debug_flag);
  RETURN NULL;
END get_current_fiscal_date;

FUNCTION get_v_claim_number_r(p_n_claim_sk_r IN NUMBER) RETURN VARCHAR2
IS
lc_v_claim_number_r atomic.dim_grp_claim_dir_r.v_claim_number_r%TYPE;
BEGIN
  SELECT
     v_claim_number_r
	INTO lc_v_claim_number_r
    FROM atomic.dim_grp_claim_dir_r
   WHERE N_CLAIM_SK_R=P_N_CLAIM_SK_R
     AND V_ACTIVE_STATUS_R ='Y';--added on 01-Oct-2021
--GROUP BY v_claim_number_r;  --added on 29-Jun-2022
  --atomic.PKG_GRP_LOAD_STG_GRP_CLAIM_SUMMARY_R.prc_debug_trace('get_v_claim_number_r:->'||lc_v_claim_number_r||CHR(13),gc_debug_flag);

return lc_v_claim_number_r;
EXCEPTION
WHEN OTHERS THEN
  --DBMS_OUTPUT.PUT_LINE('Error Occured in ATOMIC.PKG_GRP_LOAD_STG_GRP_CLAIM_SUMMARY_R.get_v_claim_number_r :->'||SQLERRM);
  --atomic.PKG_GRP_LOAD_STG_GRP_CLAIM_SUMMARY_R.prc_debug_trace('get_v_claim_number_r:->'||SQLERRM||CHR(13),gc_debug_flag);
  RETURN NULL;
END get_v_claim_number_r;

FUNCTION get_n_curr_gaap_reserve_dire_r(
   -- p_n_claim_sk_r         IN NUMBER,
    p_v_reserve_type_ind_r IN VARCHAR2,
   -- p_n_batch_id_r         IN NUMBER,
   -- p_v_claim_number_r VARCHAR2,
--Added below parameter on 21st March
p_v_claim_identifier_r in VARCHAR2,
p_d_maxreserval_date_r in date)
  RETURN NUMBER
IS
  ln_n_reserve_direct__gaap__r atomic.fct_lg_reserve_details_r.n_reserve_direct__gaap__r%TYPE;
BEGIN
  select
    SUM(flrd1.n_reserve_direct__gaap__r)
  INTO ln_n_reserve_direct__gaap__r
  FROM atomic.FCT_LG_RESERVE_DETAILS_R flrd1
  WHERE --flrd1.n_claim_sk_r = p_n_claim_sk_r
    --flrd1.v_claim_number_r             = lv_claim_number_r
 FLRD1.V_RESERVE_TYPE_IND_R       = P_V_RESERVE_TYPE_IND_R
AND   flrd1.d_reserve_valuation_date_r = p_d_maxreserval_date_r
  and   flrd1.v_claim_identifier_r=p_v_claim_identifier_r
  and flrd1.V_CLAIM_IDENTIFIER_R is not null;
  RETURN ln_n_reserve_direct__gaap__r;
EXCEPTION
WHEN OTHERS THEN
  RETURN NULL;
END get_n_curr_gaap_reserve_dire_r;
FUNCTION get_n_curr_gaap_reserve_dire_r(p_n_claim_sk_r IN NUMBER,p_v_reserve_type_ind_r IN VARCHAR2,p_n_batch_id_r IN NUMBER
,P_D_cycle_date_r DATE
,P_V_claim_number_r VARCHAR2
) RETURN NUMBER
IS
ln_n_reserve_direct__gaap__r atomic.fct_lg_reserve_details_r.n_reserve_direct__gaap__r%TYPE;
--lv_claim_number_r            VARCHAR2(1000);
lv_claim_number_r VARCHAR2(100):=P_V_claim_number_r;
BEGIN
--lv_claim_number_r :=ATOMIC.PKG_GRP_LOAD_STG_GRP_CLAIM_SUMMARY_R.get_v_claim_number_r(p_n_claim_sk_r);
  --atomic.PKG_GRP_LOAD_STG_GRP_CLAIM_SUMMARY_R.prc_debug_trace('get_n_curr_gaap_reserve_dire_r1:->'||lv_claim_number_r||CHR(13),gc_debug_flag);


SELECT
  SUM(flrd1.n_reserve_direct__gaap__r)
  INTO ln_n_reserve_direct__gaap__r
  FROM atomic.fct_lg_reserve_details_r flrd1
 WHERE --flrd1.n_claim_sk_r = p_n_claim_sk_r
   flrd1.v_claim_number_r = lv_claim_number_r
   AND flrd1.d_reserve_valuation_date_r = GD_MAXRESERVAL_DATE_R
   AND flrd1.v_reserve_type_ind_r = p_v_reserve_type_ind_r

    ;
  --atomic.PKG_GRP_LOAD_STG_GRP_CLAIM_SUMMARY_R.prc_debug_trace('get_n_curr_gaap_reserve_dire_r:->'||ln_n_reserve_direct__gaap__r||CHR(13),gc_debug_flag);

return ln_n_reserve_direct__gaap__r;
EXCEPTION
WHEN OTHERS THEN
  --DBMS_OUTPUT.PUT_LINE('Error Occured in ATOMIC.PKG_GRP_LOAD_STG_GRP_CLAIM_SUMMARY_R.get_n_curr_gaap_reserve_dire_r :->'||SQLERRM);
  --atomic.PKG_GRP_LOAD_STG_GRP_CLAIM_SUMMARY_R.prc_debug_trace('get_n_curr_gaap_reserve_dire_r:->'||SQLERRM||CHR(13),gc_debug_flag);
  RETURN NULL;
END get_n_curr_gaap_reserve_dire_r;
FUNCTION get_n_chg_gaap_os_direct_amt_r(
  --  p_n_claim_sk_r         IN NUMBER,
    p_v_reserve_type_ind_r IN VARCHAR2,
   -- p_n_batch_id_r         IN NUMBER,
   -- p_v_claim_number_r VARCHAR2,
   --Added below parameter on 21st March
p_v_claim_identifier_r in VARCHAR2,
p_d_maxreserval_date_r in date)
  RETURN NUMBER
  --FUNCTION get_n_chg_gaap_os_direct_amt_r(p_n_claim_sk_r IN NUMBER,p_v_reserve_type_ind_r IN VARCHAR2,p_n_batch_id_r IN NUMBER,p_claim_identifier_r IN VARCHAR2) RETURN NUMBER
IS
  ln_n_chg_reserve_direct_gaap_r atomic.fct_lg_reserve_details_r.n_chg_reserve_direct__gaap__r%TYPE;
 -- lv_claim_number_r VARCHAR2(1000) := p_v_claim_number_r;
BEGIN
  --lv_claim_number_r :=ATOMIC.pkg_grp_load_fct_rpt_claim_summary_r_incr_hpc_2.get_v_claim_number_r(p_n_claim_sk_r);
  --atomic.pkg_grp_load_fct_rpt_claim_summary_r_incr_hpc_2.prc_debug_trace('get_n_chg_gaap_os_direct_amt_r1:->'||lv_claim_number_r||CHR(13),gc_debug_flag);


  SELECT
      SUM(flrd.n_chg_reserve_direct__gaap__r)
   -- N_RESERVE_DIRECT__GAAP__R
  INTO ln_n_chg_reserve_direct_gaap_r
  FROM atomic.FCT_LG_RESERVE_DETAILS_R flrd
  --atomic.dim_grp_claim_coverage_r t357788,
    --atomic.dim_grp_claim_coverage_group_r t357774,

   ---- atomic.dim_grp_claim_dir_r dgcdr
  WHERE
    --T357788.n_claim_sk_r = flrd.n_claim_sk_r--18-Aug
   -- t357788.n_claim_sk_r            = dgcdr.n_claim_sk_r--18-Aug
 -- AND t357774.n_claim_coverage_sk_r = t357788.n_claim_coverage_sk_r
   FLRD.V_RESERVE_TYPE_IND_R     = P_V_RESERVE_TYPE_IND_R
   AND  flrd.v_claim_identifier_r=p_v_claim_identifier_r --Added below filter on 21st March
    --AND flrd.n_claim_sk_r = p_n_claim_sk_r
 -- AND dgcdr.v_claim_number_r = flrd.v_claim_number_r--18-Aug
 -- AND dgcdr.v_claim_number_r = lv_claim_number_r    --18-Aug
    --AND flrd.v_claim_number_r = lv_claim_number_r--18-Aug
  AND flrd.d_reserve_valuation_date_r = p_d_maxreserval_date_r
  --AND t357788.v_active_status_r       = 'Y'--added on 01-Oct-2021
 -- AND t357774.v_active_status_r       = 'Y'--added on 01-Oct-2021
  --AND dgcdr.v_active_status_r         = 'Y'--added on 01-Oct-2021
    --AND T357774.V_CLAIM_IDENTIFIER_R = p_claim_identifier_r
    AND flrd.v_claim_identifier_r IS NOT NULL
    ;
  --atomic.pkg_grp_load_fct_rpt_claim_summary_r_incr_hpc_2.prc_debug_trace('get_n_chg_gaap_os_direct_amt_r:->'||ln_n_chg_reserve_direct_gaap_r||CHR(13),gc_debug_flag);
  RETURN ln_n_chg_reserve_direct_gaap_r;
EXCEPTION
WHEN OTHERS THEN
  --DBMS_OUTPUT.PUT_LINE('Error Occured in ATOMIC.pkg_grp_load_fct_rpt_claim_summary_r_incr_hpc_2.get_n_chg_gaap_os_direct_amt_r :->'||SQLERRM);
  --atomic.pkg_grp_load_fct_rpt_claim_summary_r_incr_hpc_2.prc_debug_trace('get_n_chg_gaap_os_direct_amt_r:->'||SQLERRM||CHR(13),gc_debug_flag);
  RETURN NULL;
END get_n_chg_gaap_os_direct_amt_r;
/*FUNCTION get_n_chg_gaap_os_direct_amt_r(p_n_claim_sk_r IN NUMBER,p_v_reserve_type_ind_r IN VARCHAR2,p_n_batch_id_r IN NUMBER
,P_D_cycle_date_r       in DATE
,P_V_claim_number_r     in VARCHAR2
) RETURN NUMBER
IS
ln_n_chg_reserve_direct_gaap_r atomic.fct_lg_reserve_details_r.n_chg_reserve_direct__gaap__r%TYPE;
--lv_claim_number_r            VARCHAR2(1000);
lv_claim_number_r            VARCHAR2(100):=P_V_claim_number_r;
BEGIN
--lv_claim_number_r :=ATOMIC.PKG_GRP_LOAD_STG_GRP_CLAIM_SUMMARY_R.get_v_claim_number_r(p_n_claim_sk_r);
  --atomic.PKG_GRP_LOAD_STG_GRP_CLAIM_SUMMARY_R.prc_debug_trace('get_n_chg_gaap_os_direct_amt_r1:->'||lv_claim_number_r||CHR(13),gc_debug_flag);

SELECT
  SUM(flrd.n_chg_reserve_direct__gaap__r)
  INTO ln_n_chg_reserve_direct_gaap_r
FROM atomic.fct_lg_reserve_details_r flrd
  JOIN atomic.dim_grp_claim_dir_r dgcdr
	ON flrd.v_claim_number_r = dgcdr.v_claim_number_r
  JOIN atomic.dim_grp_claim_coverage_r  T357788
	ON T357788.n_claim_sk_r = dgcdr.n_claim_sk_r
  JOIN atomic.dim_grp_claim_coverage_group_r T357774
	ON T357788.n_claim_coverage_sk_r = T357774.n_claim_coverage_sk_r AND T357788.v_active_status_r = T357774.v_active_status_r
 WHERE flrd.v_claim_number_r = lv_claim_number_r --'2016-08-09-0568-STD-01'
    AND flrd.d_reserve_valuation_date_r = GD_MAXRESERVAL_DATE_R ---to_date( '27-OCT-22','dd-mon-yy');
    AND flrd.v_reserve_type_ind_r = p_v_reserve_type_ind_r --'L'
    AND dgcdr.v_active_status_r = 'Y'
    ;

--SELECT
/*  SUM(flrd.n_chg_reserve_direct__gaap__r)
  INTO ln_n_chg_reserve_direct_gaap_r
  FROM atomic.dim_grp_claim_coverage_r  T357788
      ,atomic.dim_grp_claim_coverage_group_r T357774
	  ,atomic.fct_lg_reserve_details_r flrd
 	  ,atomic.dim_grp_claim_dir_r dgcdr
 WHERE
   --T357788.n_claim_sk_r = flrd.n_claim_sk_r--18-Aug
   T357788.n_claim_sk_r = dgcdr.n_claim_sk_r--18-Aug
   AND T357774.n_claim_coverage_sk_r = T357788.n_claim_coverage_sk_r
   AND flrd.v_reserve_type_ind_r =p_v_reserve_type_ind_r
   --AND flrd.n_claim_sk_r = p_n_claim_sk_r
   AND dgcdr.v_claim_number_r = flrd.v_claim_number_r--18-Aug
   AND T357788.v_active_status_r='Y'--added on 01-Oct-2021
   AND T357774.v_active_status_r='Y'--added on 01-Oct-2021
   AND DGCDR.V_ACTIVE_STATUS_R='Y'--added on 01-Oct-2021
   AND dgcdr.v_claim_number_r = lv_claim_number_r--18-Aug
   --AND flrd.v_claim_number_r = lv_claim_number_r--18-Aug
   AND flrd.d_reserve_valuation_date_r= GD_MAXRESERVAL_DATE_R

  --atomic.PKG_GRP_LOAD_STG_GRP_CLAIM_SUMMARY_R.prc_debug_trace('get_n_chg_gaap_os_direct_amt_r:->'||ln_n_chg_reserve_direct_gaap_r||CHR(13),gc_debug_flag);

return ln_n_chg_reserve_direct_gaap_r;
EXCEPTION
WHEN OTHERS THEN
  --DBMS_OUTPUT.PUT_LINE('Error Occured in ATOMIC.PKG_GRP_LOAD_STG_GRP_CLAIM_SUMMARY_R.get_n_chg_gaap_os_direct_amt_r :->'||SQLERRM);
--  atomic.PKG_GRP_LOAD_STG_GRP_CLAIM_SUMMARY_R.prc_debug_trace('get_n_chg_gaap_os_direct_amt_r:->'||SQLERRM||CHR(13),gc_debug_flag);
  RETURN NULL;
END get_n_chg_gaap_os_direct_amt_r;*/

FUNCTION get_d_last_payment_date_r(p_n_claim_sk_r IN NUMBER) RETURN DATE
IS

/*CURSOR cur_1
IS
SELECT MAX(d_disburse_date_r)
  FROM atomic.fct_claim_disbursement_r
 WHERE N_CLAIM_SK_R= P_N_CLAIM_SK_R
   and upper(trim(v_pay_status_r)) <> 'REVERSAL';*/

ld_date DATE;
BEGIN
/*MAX(FCT_CLAIM_DISBURSEMENT_R.D_DISBURSE_DATE_R) where FCT_CLAIM_DISBURSEMENT_R.V_PAY_STATUS <> 'REVERSAL'
 */
  --24-Jun Changes
  /*OPEN cur_1;
  FETCH cur_1 INTO ld_date;
  CLOSE cur_1;*/
  select D_PAID_DATE_R INTO ld_date
  FROM FCT_CLAIM_PAYMENT_DETAIL_R_MV2
  where N_CLAIM_SK_R=P_N_CLAIM_SK_R
  GROUP BY D_PAID_DATE_R;

return ld_date;
EXCEPTION
WHEN OTHERS THEN
  RETURN NULL;
END get_d_last_payment_date_r;

FUNCTION GET_V_REASON_FLAG_R(P_V_reason_code_r VARCHAR2
,P_v_claim_status_reason_code_r VARCHAR2
,P_N_CLAIM_SK_R NUMBER
,P_V_CLAIM_NUMBER_R VARCHAR2
,P_D_PRIOR_FISCAL_DATE DATE
,P_D_CURR_FISCAL_DATE DATE
,P_BATCH_ID_R NUMBER
,P_T_EVENT_TIMESTAMP_R_1 TIMESTAMP
,P_T_EVENT_TIMESTAMP_R_2 TIMESTAMP
,P_d_last_payment_date_r DATE
,P_D_cycle_date_r date
,P_N_CURR_GAAP_RESERVE_DIRE_R NUMBER
,P_N_CHG_GAAP_OS_DIRECT_AMT_R NUMBER
) RETURN VARCHAR2 IS

LV_REASON_FLAG_R VARCHAR2(10);
BEGIN
SELECT
    CASE
        WHEN (( NVL(P_V_reason_code_r, P_v_claim_status_reason_code_r) <= '59' )
        OR ( NVL(P_V_reason_code_r, P_v_claim_status_reason_code_r)     > '59'
        AND NVL(P_T_EVENT_TIMESTAMP_R_1, P_T_EVENT_TIMESTAMP_R_2 ) BETWEEN P_D_PRIOR_FISCAL_DATE AND P_D_CURR_FISCAL_DATE/*ATOMIC.PKG_GRP_LOAD_STG_GRP_CLAIM_SUMMARY_R.get_prior_fiscal_date(P_BATCH_ID_R) AND ATOMIC.PKG_GRP_LOAD_STG_GRP_CLAIM_SUMMARY_R.get_current_fiscal_date(P_BATCH_ID_R)*/)
        OR ( NVL(P_V_reason_code_r, P_v_claim_status_reason_code_r)                                                                  > '59'
        AND P_d_last_payment_date_r>=
		--AND ATOMIC.PKG_GRP_LOAD_STG_GRP_CLAIM_SUMMARY_R.get_d_last_payment_date_r(P_N_CLAIM_SK_R)                              >=
		--ATOMIC.PKG_GRP_LOAD_STG_GRP_CLAIM_SUMMARY_R.get_prior_fiscal_date(P_BATCH_ID_R)
		P_D_PRIOR_FISCAL_DATE
		)
        OR ( NVL(P_V_REASON_CODE_R, P_V_CLAIM_STATUS_REASON_CODE_R)                                                                  > '59'
        --AND NVL(ATOMIC.PKG_GRP_LOAD_STG_GRP_CLAIM_SUMMARY_R.GET_N_CURR_GAAP_RESERVE_DIRE_R(P_N_CLAIM_SK_R,'L',P_BATCH_ID_R,P_D_CYCLE_DATE_R,P_V_CLAIM_NUMBER_R),0) <> 0
        AND NVL(P_N_CURR_GAAP_RESERVE_DIRE_R ,0) <> 0
        )
        OR ( NVL(P_V_REASON_CODE_R, P_V_CLAIM_STATUS_REASON_CODE_R)                                                                  > '59'
        --AND (ATOMIC.PKG_GRP_LOAD_STG_GRP_CLAIM_SUMMARY_R.GET_N_CHG_GAAP_OS_DIRECT_AMT_R(P_N_CLAIM_SK_R,'L',P_BATCH_ID_R,P_D_CYCLE_DATE_R,P_V_CLAIM_NUMBER_R))      <> 0
        AND (P_N_CHG_GAAP_OS_DIRECT_AMT_R)      <> 0
        )
        )
        THEN 'Y'
        ELSE 'N'
      END AS V_REASON_FLAG_R into LV_REASON_FLAG_R
	  FROM DUAL;
RETURN LV_REASON_FLAG_R;
exception
WHEN OTHERS THEN
RETURN NULL;
END GET_V_REASON_FLAG_R;

PROCEDURE PRC_LOAD_STG_GRP_CLAIM_SUMMARY_R
    (P_BATCH_ID_R IN NUMBER)AS
  N_MAX_SERIAL_NUM_R NUMBER;
  V_SQLCODE          VARCHAR2(100);
  V_SQLERRM          VARCHAR2(500);
  --GD_PRIOR_FISCAL_DATE DATE:=ATOMIC.PKG_GRP_LOAD_STG_GRP_CLAIM_SUMMARY_R.GET_PRIOR_FISCAL_DATE(P_BATCH_ID_R);
  --GD_CURR_FISCAL_DATE DATE:=ATOMIC.PKG_GRP_LOAD_STG_GRP_CLAIM_SUMMARY_R.GET_CURRENT_FISCAL_DATE(P_BATCH_ID_R);
  --GD_CYCLE_DATE_R DATE:=ATOMIC.PKG_GRP_LOAD_STG_GRP_CLAIM_SUMMARY_R.GET_D_CYCLE_DATE_R(P_BATCH_ID_R);
  --GD_MAXRESERVAL_DATE_R DATE:=ATOMIC.PKG_GRP_LOAD_STG_GRP_CLAIM_SUMMARY_R.GET_MAXRESERVAL_DATE_R(GD_CYCLE_DATE_R);
  ln_bulk_limit_r NUMBER:=1000;

  LN_START_TIME NUMBER;
  ln_iteration number;
  l_start number;
  lv_message_type_r  PRCS_JOB_LOG_MESSAGE_R.v_message_type_r%TYPE:= PKG_GRP_LOG_UTIL.gc_message_type_info;
--LN_CURR_GAAP_RESERVE_DIRE_R NUMBER;
--LN_CHG_GAAP_OS_DIRECT_AMT_R NUMBER;

BEGIN


	gc_main_loadedby :='PKG_GRP_LOAD_STG_GRP_CLAIM_SUMMARY_R.PRC_LOAD_STG_GRP_CLAIM_SUMMARY_R';

    pkg_grp_log_util.prc_insert_log
                       ( p_source              			=> gc_source
					    ,p_job_nm              			=> gc_job_name
                        ,p_job_status          			=> gc_running_status
                        ,p_err_msg             			=> null
                        ,p_trc_msg             			=> null
                        ,p_n_batch_id          			=> gn_sysdt_batchid
                        ,p_log_util_called_by_r			=> gc_main_loadedby
						,out_job_id            			=> gn_out_job_id
						);

		gc_trcmsg:='1. Entered into PRC_LOAD_STG_GRP_CLAIM_SUMMARY_R ';
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
						p_job_id_r            			=> gn_out_job_id,
						p_batch_id_r                  	=> gn_sysdt_batchid,
						p_message_type_r              	=> lv_message_type_r,
						p_code_location_r             	=> gc_main_loadedby,
						p_message_r                   	=> gc_trcmsg,
						p_count_type_r                	=> NULL,
						p_count_r                     	=> NULL,
						p_duration_r                  	=> NULL,
						p_created_by_r                	=> GC_JOB_NAME,
						out_prcs_job_log_message_id_r 	=> gn_job_log_message_id_r
						);
  l_start := DBMS_UTILITY.get_time;

  SELECT SEQ_FCT_PROC_EXEC_STATUS_LOG_R.NEXTVAL
  INTO N_MAX_SERIAL_NUM_R
  FROM DUAL;
  INSERT
  INTO FCT_PROC_EXEC_STATUS_LOG_R
    (
      N_BATCH_ID_R,
      N_MIS_DATE_SKEY_R,
      N_LOAD_RUN_ID_R,
      V_STATUS_R,
      T_EXECUTION_TIMESTAMP_R,
      V_USER_R,
      V_PLSQL_BLOCK_NAME_R,
      N_SERIAL_NUM_R
    )
    VALUES
    (
      99999999,--LN_BATCH_ID_R,--99999999,
      TO_CHAR(sysdate,'yyyymmdd'),
      1,
      'Started',
      SYSTIMESTAMP,
      USER,
      'PRC_LOAD_STG_GRP_CLAIM_SUMMARY_R',
      N_MAX_SERIAL_NUM_R
    );
  COMMIT;

  	gc_trcmsg:='2. Completed Inserting records into FCT_PROC_EXEC_STATUS_LOG_R';
    PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
						p_job_id_r            			=> gn_out_job_id,
						p_batch_id_r                  	=> gn_sysdt_batchid,
						p_message_type_r              	=> lv_message_type_r,
						p_code_location_r             	=> gc_main_loadedby,
						p_message_r                   	=> gc_trcmsg,
						p_count_type_r                	=> NULL,
						p_count_r                     	=> NULL,
						p_duration_r                  	=> NULL,
						p_created_by_r                	=> GC_JOB_NAME,
						out_prcs_job_log_message_id_r 	=> gn_job_log_message_id_r
						);


  	gc_trcmsg:='3. Started truncating table STG_GRP_CLAIM_SUMMARY_R';
    PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
						p_job_id_r            			=> gn_out_job_id,
						p_batch_id_r                  	=> gn_sysdt_batchid,
						p_message_type_r              	=> lv_message_type_r,
						p_code_location_r             	=> gc_main_loadedby,
						p_message_r                   	=> gc_trcmsg,
						p_count_type_r                	=> NULL,
						p_count_r                     	=> NULL,
						p_duration_r                  	=> NULL,
						p_created_by_r                	=> GC_JOB_NAME,
						out_prcs_job_log_message_id_r 	=> gn_job_log_message_id_r
						);
  EXECUTE immediate 'TRUNCATE TABLE STG_GRP_CLAIM_SUMMARY_R PURGE SNAPSHOT LOG';

  	gc_trcmsg:='4. Completed truncating table STG_GRP_CLAIM_SUMMARY_R';
    PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
						p_job_id_r            			=> gn_out_job_id,
						p_batch_id_r                  	=> gn_sysdt_batchid,
						p_message_type_r              	=> lv_message_type_r,
						p_code_location_r             	=> gc_main_loadedby,
						p_message_r                   	=> gc_trcmsg,
						p_count_type_r                	=> NULL,
						p_count_r                     	=> NULL,
						p_duration_r                  	=> NULL,
						p_created_by_r                	=> GC_JOB_NAME,
						out_prcs_job_log_message_id_r 	=> gn_job_log_message_id_r
						);
	gc_trcmsg:='5. Started Inserting records into table STG_GRP_CLAIM_SUMMARY_R';
    PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
						p_job_id_r            			=> gn_out_job_id,
						p_batch_id_r                  	=> gn_sysdt_batchid,
						p_message_type_r              	=> lv_message_type_r,
						p_code_location_r             	=> gc_main_loadedby,
						p_message_r                   	=> gc_trcmsg,
						p_count_type_r                	=> NULL,
						p_count_r                     	=> NULL,
						p_duration_r                  	=> NULL,
						p_created_by_r                	=> GC_JOB_NAME,
						out_prcs_job_log_message_id_r 	=> gn_job_log_message_id_r
						);

                            INSERT INTO ATOMIC.STG_GRP_CLAIM_SUMMARY_R(
                                            N_CLAIM_SK_R,
                                            V_CLAIM_STATUS_REASON_CODE_R,
                                            V_REASON_CODE_R,
                                            V_REASON_FLAG_R,
                                            V_CLAIM_IDENTIFIER_R,
                                            N_CLAIM_COVERAGE_GROUP_SK_R,
                                            N_CLAIM_COVERAGE_SK_R,
                                            N_POLICY_SK_R,
                                            V_CLAIM_COVERAGE_CODE_R,
                                            V_POLICY_NUMBER_R,
                                            V_CLAIM_NUMBER_R,
                                            D_PRIOR_FISCAL_DATE,
                                            D_CURR_FISCAL_DATE,
                                            D_CYCLE_DATE_R,
                                            N_BATCH_ID_R,
                                            D_MAXRESERVAL_DATE_R,
                                            D_LAST_PAYMENT_DATE_R,
                                            N_CURR_GAAP_RESERVE_DIRECT_R,
                                            N_CHG_GAAP_OS_DIRECT_AMT_R,
                                            V_SS_PURSUE_INDICATED_R,
                                            N_CLAIMS_BRIDGED_STD_TO_LTD_R, --added 7/3/24
                                            N_TIER_NUM_R,  --added 7/3/24
                                            V_ACCOMMODATIONS_NEEDED_R, --added 8/3/24
                                            V_CLINICAL_VOC_ENGAGEMENT_R, --added 8/3/24
                                            V_RECOVERY_EXPECTATIONS_R, --added 8/3/24
                                            N_OVERPAYMENT_BALANCE_R, --added 8/3/24
                                            N_LTD_APPROVED_CLMS_ANY_OCC_R, --added 8/3/24
                                            N_LTD_APPROVED_CLMS_OWN_OCC_R, --added 8/3/24
                                            N_LTD_APPRVED_OWNOCC_FULLDUR_R, --added 8/3/24
                                            V_LTD_ANY_OCC_GROUP_R, --added 8/3/24
                                            V_POLICY_PREFIX_R, --added 25/3/24
                                            V_POLICY_SUFFIX_R, --added 25/3/24
                                            V_WFAM_CODE_R, --added 25/3/24
                                            D_POTENTIAL_RESOLUTION_DATE_R, --added 25/3/24
                                            V_TIER_DESCRIPTION_R, --added 25/3/24
                                            V_COVERAGE_TYPE_CODE_R,   --added 25/3/24
                                            N_WAGE_BASE_R, --all added 27/3/24
                                            N_PAYMENT_TAXABLE_BENEFITS_R,
                                            N_PAYMENT_NONTAXABLE_BEN_R,
                                            N_NON_TAXABLE_BENEFITS_R,
                                            N_MEDICARE_WAGE_BASE_R,
                                            N_EMP_MEDICARE_WAGE_BASE_R,
                                            N_EMP_FICA_WAGE_BASE_R,
                                            N_TAXABLE_BENEFITS_R,
                                            N_SIT_R,
                                            N_PAYMENT_DIRECT_AMT_R,
                                            N_MEDICARE_TAX_R,
                                            N_FUTA_R,
                                            N_FIT_R,
                                            N_FICA_WAGE_BASE_R,
                                            N_FICA_R,
                                            N_EMPLOYER_MEDICARE_TAX_R,
                                            N_EMPLOYER_FICA_R,
                                            D_LAST_PAYMENT_TO_DATE_R,
                                            D_FIRST_PAYMENT_FROM_DATE_R,
                                            N_CURR_STAT_WV_DIRECT_AMT_R,
                                            N_CURR_GAAP_WV_DIRECT_AMT_R,
                                            N_CHG_STAT_WV_DIRECT_AMT_R,
                                            N_CHG_GAAP_WV_DIRECT_AMT_R,
                                            D_FIRST_PAYMENT_DATE_R,
                                            N_NO_OF_VOID_CHECKS_R,
                                            N_NO_OF_VOID_PAYMENTS_R,
                                            N_CURR_STAT_RESERVE_DIRECT_R,
                                            N_CURR_FIELD_RES_DIRECT_AMT_R,
                                            N_CURR_BE_RESERVE_DIRECT_AMT_R,
                                            N_CHG_STAT_OS_DIRECT_AMT_R,
                                            N_CHG_FIELD_RES_DIRECT_AMT_R,
                                            N_CHG_BE_RESERVE_DIRECT_AMT_R ,
                                            D_RECEIVED_DATE_R,
                                            N_CUST_PARTY_SK_R,
                                            D_CLOSURE_DATE_R
                                            )
                                        SELECT
                                            N_CLAIM_SK_R,
                                            V_CLAIM_STATUS_REASON_CODE_R,
                                            V_REASON_CODE_R,
                                            V_REASON_FLAG_R,
                                            V_CLAIM_IDENTIFIER_R,
                                            N_CLAIM_COVERAGE_GROUP_SK_R,
                                            N_CLAIM_COVERAGE_SK_R,
                                            N_POLICY_SK_R,
                                            V_CLAIM_COVERAGE_CODE_R,
                                            V_POLICY_NUMBER_R,
                                            V_CLAIM_NUMBER_R,
                                            D_PRIOR_FISCAL_DATE,
                                            D_CURR_FISCAL_DATE,
                                            D_CYCLE_DATE_R,
                                            P_BATCH_ID_R,
                                            D_MAXRESERVAL_DATE_R,
                                            D_PAYMENT_LAST_DATE_R                   AS  D_LAST_PAYMENT_DATE_R,
                                            N_CURR_GAAP_RESERVE_DIRECT_R,
                                            N_CHG_GAAP_OS_DIRECT_AMT_R,
                                            V_SS_PURSUE_INDICATED_R,
                                            CASE
                                                WHEN V_CLAIMS_BRIDGED_STD_TO_LTD_R = 'Has LTD' THEN 1
                                                ELSE 0
                                            END                                     AS  N_CLAIMS_BRIDGED_STD_TO_LTD_R,
                                            N_TIER_NUM_R,
                                            V_ACCOMMODATIONS_NEEDED_R,
                                            V_CLINICAL_VOC_ENGAGEMENT_R,
                                            V_RECOVERY_EXPECTATIONS_R,
                                            N_OVERPAYMENT_BALANCE_R,
                                            N_LTD_APPROVED_CLMS_ANY_OCC_R,
                                            N_LTD_APPROVED_CLMS_OWN_OCC_R,
                                            N_LTD_APPRVED_OWNOCC_FULLDUR_R,
                                            V_LTD_ANY_OCC_GROUP_R,
                                            V_POLICY_PREFIX_R,
                                            V_POLICY_SUFFIX_R,
                                            V_WFAM_CODE_R,
                                            D_POTENTIAL_RESOLUTION_DATE_R,
                                            V_TIER_DESCRIPTION_R,
                                            V_COVERAGE_TYPE_CODE_R,
                                            N_WAGE_BASE_R,
                                            N_PAYMENT_TAXABLE_BENEFITS_R,
                                            N_PAYMENT_NONTAXABLE_BEN_R,
                                            N_NON_TAXABLE_BENEFITS_R,
                                            N_MEDICARE_WAGE_BASE_R,
                                            N_EMP_MEDICARE_WAGE_BASE_R,
                                            N_EMP_FICA_WAGE_BASE_R,
                                            N_TAXABLE_BENEFITS_R,
                                            N_SIT_R,
                                            N_PAYMENT_DIRECT_AMT_R,
                                            N_MEDICARE_TAX_R,
                                            N_FUTA_R,
                                            N_FIT_R,
                                            N_FICA_WAGE_BASE_R,
                                            N_FICA_R,
                                            N_EMPLOYER_MEDICARE_TAX_R,
                                            N_EMPLOYER_FICA_R,
                                            D_LAST_PAYMENT_TO_DATE_R,
                                            D_FIRST_PAYMENT_FROM_DATE_R,
                                            N_CURR_STAT_WV_DIRECT_AMT_R,
                                            N_CURR_GAAP_WV_DIRECT_AMT_R,
                                            N_CHG_STAT_WV_DIRECT_AMT_R,
                                            N_CHG_GAAP_WV_DIRECT_AMT_R,
                                            D_FIRST_PAYMENT_DATE_R,
                                            N_NO_OF_VOID_CHECKS_R,
                                            N_NO_OF_VOID_PAYMENTS_R,
                                            N_CURR_STAT_RESERVE_DIRECT_R,
                                            N_CURR_FIELD_RES_DIRECT_AMT_R,
                                            N_CURR_BE_RESERVE_DIRECT_AMT_R,
                                            N_CHG_STAT_OS_DIRECT_AMT_R,
                                            N_CHG_FIELD_RES_DIRECT_AMT_R,
                                            N_CHG_BE_RESERVE_DIRECT_AMT_R,
                                            D_RECEIVED_DATE_R,
                                            N_CUST_PARTY_SK_R,
                                            D_CLOSURE_DATE_R
                                        FROM(
                                            SELECT
                                                SGCSRT1.N_CLAIM_SK_R,
                                                SGCSRT1.V_CLAIM_STATUS_REASON_CODE_R,
                                                SGCSRT1.V_REASON_CODE_R,
                                                SGCSRT2.V_REASON_FLAG_R,
                                                SGCSRT1.V_CLAIM_IDENTIFIER_R,
                                                SGCSRT1.N_CLAIM_COVERAGE_GROUP_SK_R,
                                                SGCSRT1.N_CLAIM_COVERAGE_SK_R,
                                                SGCSRT1.N_POLICY_SK_R,
                                                SGCSRT1.V_CLAIM_COVERAGE_CODE_R,
                                                SGCSRT1.V_POLICY_NUMBER_R,
                                                SGCSRT1.V_CLAIM_NUMBER_R,
                                                SGCSRT2.D_PRIOR_FISCAL_DATE,
                                                SGCSRT2.D_CURR_FISCAL_DATE,
                                                SGCSRT2.D_CYCLE_DATE_R,
                                                SGCSRT2.D_MAXRESERVAL_DATE_R,
                                                SGCSRT2.D_PAYMENT_LAST_DATE_R,
                                                SGCSRT2.N_CURR_GAAP_RESERVE_DIRECT_R,
                                                SGCSRT2.N_CHG_GAAP_OS_DIRECT_AMT_R,
                                                SGCSRT1.V_SS_PURSUE_INDICATED_R,
                                                SGCSRT1.V_CLAIMS_BRIDGED_STD_TO_LTD_R,
                                                SGCSRT1.N_TIER_NUM_R,
                                                SGCSRT1.V_ACCOMMODATIONS_NEEDED_R,
                                                SGCSRT1.V_CLINICAL_VOC_ENGAGEMENT_R,
                                                SGCSRT1.V_RECOVERY_EXPECTATIONS_R,
                                                SGCSRT1.N_OVERPAYMENT_BALANCE_R,
                                                SGCSRT1.N_LTD_APPROVED_CLMS_ANY_OCC_R,
                                                SGCSRT1.N_LTD_APPROVED_CLMS_OWN_OCC_R,
                                                SGCSRT1.N_LTD_APPRVED_OWNOCC_FULLDUR_R,
                                                SGCSRT1.V_LTD_ANY_OCC_GROUP_R,
                                                SGCSRT1.V_POLICY_PREFIX_R,
                                                SGCSRT1.V_POLICY_SUFFIX_R,
                                                SGCSRT1.V_WFAM_CODE_R,
                                                SGCSRT1.D_POTENTIAL_RESOLUTION_DATE_R,
                                                SGCSRT1.V_TIER_DESCRIPTION_R,
                                                SGCSRT1.V_COVERAGE_TYPE_CODE_R,
                                                SGCSRT3.N_WAGE_BASE_R,
                                                SGCSRT3.N_PAYMENT_TAXABLE_BENEFITS_R,
                                                SGCSRT3.N_PAYMENT_NONTAXABLE_BEN_R,
                                                SGCSRT3.N_NON_TAXABLE_BENEFITS_R,
                                                SGCSRT3.N_MEDICARE_WAGE_BASE_R,
                                                SGCSRT3.N_EMP_MEDICARE_WAGE_BASE_R,
                                                SGCSRT3.N_EMP_FICA_WAGE_BASE_R,
                                                SGCSRT3.N_TAXABLE_BENEFITS_R,
                                                SGCSRT3.N_SIT_R,
                                                SGCSRT3.N_PAYMENT_DIRECT_AMT_R,
                                                SGCSRT3.N_MEDICARE_TAX_R,
                                                SGCSRT3.N_FUTA_R,
                                                SGCSRT3.N_FIT_R,
                                                SGCSRT3.N_FICA_WAGE_BASE_R,
                                                SGCSRT3.N_FICA_R,
                                                SGCSRT3.N_EMPLOYER_MEDICARE_TAX_R,
                                                SGCSRT3.N_EMPLOYER_FICA_R,
                                                SGCSRT3.D_LAST_PAYMENT_TO_DATE_R,
                                                SGCSRT3.D_FIRST_PAYMENT_FROM_DATE_R,
                                                SGCSRT3.N_CURR_STAT_WV_DIRECT_AMT_R,
                                                SGCSRT3.N_CURR_GAAP_WV_DIRECT_AMT_R,
                                                SGCSRT3.N_CHG_STAT_WV_DIRECT_AMT_R,
                                                SGCSRT3.N_CHG_GAAP_WV_DIRECT_AMT_R,
                                                SGCSRT3.D_FIRST_PAYMENT_DATE_R,
                                                SGCSRT3.N_NO_OF_VOID_CHECKS_R,
                                                SGCSRT3.N_NO_OF_VOID_PAYMENTS_R,
                                                SGCSRT2.N_CURR_STAT_RESERVE_DIRECT_R,
                                                SGCSRT2.N_CURR_FIELD_RES_DIRECT_AMT_R,
                                                SGCSRT2.N_CURR_BE_RESERVE_DIRECT_AMT_R,
                                                SGCSRT2.N_CHG_STAT_OS_DIRECT_AMT_R,
                                                SGCSRT2.N_CHG_FIELD_RES_DIRECT_AMT_R,
                                                SGCSRT2.N_CHG_BE_RESERVE_DIRECT_AMT_R,
                                                SGCSRT1.D_RECEIVED_DATE_R,
                                                SGCSRT1.N_CUST_PARTY_SK_R,
                                                SGCSRT1.D_CLOSURE_DATE_R
                                            FROM
                                                STG_GRP_CLAIM_SUMMARY_COVRG_TIER_R SGCSRT1
                                            LEFT JOIN
                                                STG_GRP_CLAIM_SUMMARY_RESERVE_AMTS_R SGCSRT2
                                            ON
                                                SGCSRT2.N_CLAIM_SK_R = SGCSRT1.N_CLAIM_SK_R
                                                AND SGCSRT2.N_CLAIM_COVERAGE_SK_R = SGCSRT1.N_CLAIM_COVERAGE_SK_R
                                                and SGCSRT2.N_CLAIM_COVERAGE_GROUP_SK_R = SGCSRT2.N_CLAIM_COVERAGE_GROUP_SK_R
                                                --AND SGCSRT2.N_POLICY_SK_R = SGCSRT1.N_POLICY_SK_R---Changed
                                                AND SGCSRT1.V_CLAIM_IDENTIFIER_R = SGCSRT2.V_CLAIM_IDENTIFIER_R
                                            LEFT JOIN
                                                STG_GRP_CLAIM_SUMMARY_PAYMENT_DETAILS_R SGCSRT3
                                            ON
                                                SGCSRT3.N_CLAIM_SK_R = SGCSRT1.N_CLAIM_SK_R
                                                AND SGCSRT3.N_CLAIM_COVERAGE_SK_R = SGCSRT1.N_CLAIM_COVERAGE_SK_R
                                                AND SGCSRT3.N_CLAIM_COVERAGE_GROUP_SK_R = SGCSRT2.N_CLAIM_COVERAGE_GROUP_SK_R
                                                AND SGCSRT3.V_CLAIM_IDENTIFIER_R= SGCSRT2.V_CLAIM_IDENTIFIER_R
                                        );
                                        COMMIT;

	gc_trcmsg:='6. Completed Inserting records into table STG_GRP_CLAIM_SUMMARY_R';
    PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
						p_job_id_r            			=> gn_out_job_id,
						p_batch_id_r                  	=> gn_sysdt_batchid,
						p_message_type_r              	=> lv_message_type_r,
						p_code_location_r             	=> gc_main_loadedby,
						p_message_r                   	=> gc_trcmsg,
						p_count_type_r                	=> NULL,
						p_count_r                     	=> NULL,
						p_duration_r                  	=> NULL,
						p_created_by_r                	=> GC_JOB_NAME,
						out_prcs_job_log_message_id_r 	=> gn_job_log_message_id_r
						);
   UPDATE FCT_PROC_EXEC_STATUS_LOG_R
   SET V_STATUS_R = 'Successful'
      ,T_EXECUTION_END_TIMESTAMP_R = SYSTIMESTAMP
--      ,v_trace_message_r = gC_TRC_MSG                     --*** PL/SQL: ORA-00904: V_TRACE_MESSAGE_R: invalid identifier
   WHERE N_SERIAL_NUM_R = N_MAX_SERIAL_NUM_R;
   COMMIT;

   	gc_trcmsg:='7. Updated  table FCT_PROC_EXEC_STATUS_LOG_R setting V_STATUS_R as Successful ';
    PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
						p_job_id_r            			=> gn_out_job_id,
						p_batch_id_r                  	=> gn_sysdt_batchid,
						p_message_type_r              	=> lv_message_type_r,
						p_code_location_r             	=> gc_main_loadedby,
						p_message_r                   	=> gc_trcmsg,
						p_count_type_r                	=> NULL,
						p_count_r                     	=> NULL,
						p_duration_r                  	=> NULL,
						p_created_by_r                	=> GC_JOB_NAME,
						out_prcs_job_log_message_id_r 	=> gn_job_log_message_id_r
						);

		gc_trcmsg:='1. Exit from PRC_LOAD_STG_GRP_CLAIM_SUMMARY_R ';
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
						p_job_id_r            			=> gn_out_job_id,
						p_batch_id_r                  	=> gn_sysdt_batchid,
						p_message_type_r              	=> lv_message_type_r,
						p_code_location_r             	=> gc_main_loadedby,
						p_message_r                   	=> gc_trcmsg,
						p_count_type_r                	=> NULL,
						p_count_r                     	=> NULL,
						p_duration_r                  	=> NULL,
						p_created_by_r                	=> GC_JOB_NAME,
						out_prcs_job_log_message_id_r 	=> gn_job_log_message_id_r
						);

			pkg_grp_log_util.prc_update_log(
      						gn_out_job_id                   --p_job_id
							,gc_success_status              --p_job_status
							,gc_errmsg                      --p_err_msg
							,gc_trcmsg                      --p_trc_msg
							,gc_main_loadedby               --p_log_util_called_by_r
							);
   --DBMS_OUTPUT.put_line('Total duration : ' || (DBMS_UTILITY.get_time - l_start)/100 || ' Seconds');
EXCEPTION
WHEN OTHERS THEN
  V_SQLCODE := SQLCODE;
  V_SQLERRM := SUBSTR(SYS.STANDARD.SQLERRM,1,500);
     --***###   ******************  FIX & UNCOMMENT:    PL/SQL: ORA-00904: V_TRACE_MESSAGE_R: invalid identifier
  UPDATE FCT_PROC_EXEC_STATUS_LOG_R
  SET V_STATUS_R                = 'Failed',
    T_EXECUTION_END_TIMESTAMP_R = systimestamp,
    V_ERROR_CODE_R              = V_SQLCODE
    ,V_ERROR_DESC_R =V_SQLERRM
--    ,v_trace_message_r=gC_TRC_MSG||V_SQLERRM                        --*** PL/SQL: ORA-00904: V_TRACE_MESSAGE_R: invalid identifier
  WHERE N_SERIAL_NUM_R          = N_MAX_SERIAL_NUM_R;
  COMMIT;
--DBMS_OUTPUT.put_line('Errored : ' || (DBMS_UTILITY.get_time - l_start)/100 ||'sqlerr: '||SQLERRM);


	gc_trcmsg:='Updated  table FCT_PROC_EXEC_STATUS_LOG_R setting V_STATUS_R as Failed ';
    PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
						p_job_id_r            			=> gn_out_job_id,
						p_batch_id_r                  	=> gn_sysdt_batchid,
						p_message_type_r              	=> lv_message_type_r,
						p_code_location_r             	=> gc_main_loadedby,
						p_message_r                   	=> gc_trcmsg,
						p_count_type_r                	=> NULL,
						p_count_r                     	=> NULL,
						p_duration_r                  	=> NULL,
						p_created_by_r                	=> GC_JOB_NAME,
						out_prcs_job_log_message_id_r 	=> gn_job_log_message_id_r
						);


	gc_errmsg :=SUBSTR(SQLERRM,1,4000);
    gc_trcmsg:='1.z Error in PRC_LOAD_STG_GRP_CLAIM_SUMMARY_R: '||gc_errmsg;

         /*START: NEW LOGGING MECHANISM CHANGES*/
    pkg_grp_log_util.prc_update_log_message_r
			(
			n_prcs_job_log_message_id_r => gn_job_log_message_id_r,
			p_err_msg 					=> gc_trcmsg
				);
	     /*END: NEW LOGGING MECHANISM CHANGES*/

	pkg_grp_log_util.prc_update_log
      (
        gn_out_job_id                   	--p_job_id
        ,gc_error_status                	--p_job_status
        ,gc_errmsg                       	--p_err_msg
        ,gc_trcmsg					     	--p_trc_msg
        ,gc_main_loadedby               	--p_log_util_called_by_r
    );


RAISE_APPLICATION_ERROR(-20001,'Error in PKG_GRP_LOAD_STG_GRP_CLAIM_SUMMARY_R.PRC_LOAD_STG_GRP_CLAIM_SUMMARY_R:->
Error Code:'||SQLCODE||',Error message:'||V_SQLERRM);
END PRC_LOAD_STG_GRP_CLAIM_SUMMARY_R;

end PKG_GRP_LOAD_STG_GRP_CLAIM_SUMMARY_R;

