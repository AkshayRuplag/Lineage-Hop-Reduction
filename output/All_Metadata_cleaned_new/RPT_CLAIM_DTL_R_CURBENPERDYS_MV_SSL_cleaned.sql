-- Cleaned for lineage: RPT_CLAIM_DTL_R_CURBENPERDYS_MV_SSL

CREATE MATERIALIZED VIEW RPT_CLAIM_DTL_R_CURBENPERDYS_MV_SSL AS
SELECT
V_CLAIM_NUMBER_R,
SUM(CURR) n_curr_benefit_period_days_r
FROM (select 
  d_paid_date_r,v_claim_number_r,V_PAYMENT_STATUS_R,D_SERVICE_PERIOD_FROM_R,D_SERVICE_PERIOD_TO_R

,case when V_PAYMENT_STATUS_R <> 'VOID' then (D_SERVICE_PERIOD_TO_R-D_SERVICE_PERIOD_FROM_R) else -1*(D_SERVICE_PERIOD_TO_R-D_SERVICE_PERIOD_FROM_R) end as Curr
from fct_claim_payment_detail_r_mv_ssl fct_claim_payment_detail_r
where 
(D_PAID_DATE_R) <= ((select to_date(to_char(D_EDS_CYCLEDATE_R,'dd-mon-yyyy'))
from PRCS_GRP_DATE_PARAM_R
where V_PROCESS_NAME_R ='PACS_BATCH_ID'))
And (D_PAID_DATE_R) >
(select (max(D_CALENDAR_DATE_R)) from Dim_time_r where  V_END_OF_FISCAL_MONTH_IND_R = 'Y' and
D_CALENDAR_DATE_R< (select to_date(to_char(D_EDS_CYCLEDATE_R,'dd-mon-yyyy'))
from PRCS_GRP_DATE_PARAM_R
where V_PROCESS_NAME_R ='PACS_BATCH_ID')) 
GROUP BY D_PAID_DATE_R,V_CLAIM_NUMBER_R,V_PAYMENT_STATUS_R,D_SERVICE_PERIOD_FROM_R,D_SERVICE_PERIOD_TO_R) A
GROUP BY V_CLAIM_NUMBER_R;