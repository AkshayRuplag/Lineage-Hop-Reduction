-- Cleaned for lineage: FCT_CLAIM_PAYMENT_DETAIL_R_PMNT_MV_SSL

CREATE MATERIALIZED VIEW FCT_CLAIM_PAYMENT_DETAIL_R_PMNT_MV_SSL AS
SELECT  v_claim_number_r ,  N_CLAIM_COVERAGE_GROUP_SK_R,
    V_COV_GROUP_ID_R,
     
    MAX(
        CASE
            WHEN N_PAID_AMOUNT_R > 0 THEN
                d_paid_date_r
        END
    )                                last_payment_date,
	 min(d_paid_date_r) earliest_payment_date,
     max(D_SERVICE_PERIOD_TO_R) MOST_RECENT_SERVICE_PERIOD_TO_DATE,
     max(D_SERVICE_PERIOD_FROM_R) MOST_RECENT_SERVICE_PERIOD_FROM_DATE,
     min(D_SERVICE_PERIOD_TO_R)   EARLIEST_SERVICE_PERIOD_TO_DATE,
     min(D_SERVICE_PERIOD_FROM_R) EARLIEST_SERVICE_PERIOD_FROM_DATE
  FROM
    (SELECT   v_claim_number_r,
      d_paid_date_r,
      N_SOURCE_VERSION_SEQ_NUMBER_R,
      SUM(N_PAID_AMOUNT_R) N_PAID_AMOUNT_R,
      N_CLAIM_COVERAGE_GROUP_SK_R,
      V_COV_GROUP_ID_R,
     D_SERVICE_PERIOD_FROM_R,
      D_SERVICE_PERIOD_TO_R
    FROM fct_claim_payment_detail_r_MV_SSL
    WHERE V_CHECK_TYPE_R      <> 'OE'
    AND V_BENEFIT_GROUP_R NOT IN ('FIC', 'MED')
    GROUP BY v_claim_number_r,
      d_paid_date_r,
      N_SOURCE_VERSION_SEQ_NUMBER_R,
      N_CLAIM_COVERAGE_GROUP_SK_R,
      V_COV_GROUP_ID_R,
      D_SERVICE_PERIOD_FROM_R,
      D_SERVICE_PERIOD_TO_R
    
    HAVING SUM(N_PAID_AMOUNT_R) <>0 
    )
  GROUP BY v_claim_number_r,
    N_CLAIM_COVERAGE_GROUP_SK_R,
    V_COV_GROUP_ID_R;