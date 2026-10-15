-- Cleaned for lineage: RPT_CLAIM_DTL_R_TOTBENPERDYS_MV_SSL

CREATE MATERIALIZED VIEW RPT_CLAIM_DTL_R_TOTBENPERDYS_MV_SSL AS
SELECT v_claim_number_r, SUM(Differ) as n_total_benefit_period_days_r FROM (
select 
  
  v_claim_number_r,D_SERVICE_PERIOD_FROM_R,D_SERVICE_PERIOD_TO_R,
D_SERVICE_PERIOD_TO_R-D_SERVICE_PERIOD_FROM_R as Differ

from fct_claim_payment_detail_r_mv_ssl fct_claim_payment_detail_r
where

(D_PAID_DATE_R) <= (select to_date(to_char(D_EDS_CYCLEDATE_R,'dd-mon-yyyy'))
from PRCS_GRP_DATE_PARAM_R
where V_PROCESS_NAME_R ='PACS_BATCH_ID')
GROUP BY
V_CLAIM_NUMBER_R,D_SERVICE_PERIOD_FROM_R,D_SERVICE_PERIOD_TO_R)
GROUP BY v_claim_number_r;