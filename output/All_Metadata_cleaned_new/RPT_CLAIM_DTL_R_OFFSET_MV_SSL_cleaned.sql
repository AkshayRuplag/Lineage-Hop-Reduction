-- Cleaned for lineage: RPT_CLAIM_DTL_R_OFFSET_MV_SSL

CREATE MATERIALIZED VIEW RPT_CLAIM_DTL_R_OFFSET_MV_SSL AS
SELECT
                  T425786.N_CLAIM_SK_R,
                  T425786.n_claim_coverage_group_sk_r,
                      max(  case  WHEN T425786.v_benefit_code_r = '188' THEN
               'Y'
            ELSE
                NULL
        END)as work_incentive_excess_offset_indicator_188,

    SUM(
       CASE
            WHEN T425786.v_benefit_code_r = '088' THEN
                T425786.n_paid_amount_r
                else 0
        END
    )                                                                                                       AS rehabilitation_offset_amount_088
    ,
    SUM(
        CASE
            WHEN T425786.v_benefit_code_r = '083' THEN
                T425786.n_paid_amount_r
                else 0
        END
   )                                                                                                       AS workers_compensation_offset_amount_083
  ,
    SUM(
        CASE
          WHEN T425786.v_benefit_code_r IN('087', '08B', '090', '091', '186',
                                                                '188') THEN
                T425786.n_paid_amount_r
                else 0
        END
    )                                                                                                       AS other_offset_amounts,
    MAX(
        CASE
            WHEN T425786.v_benefit_code_r = '088' THEN
               'Y'
            ELSE
                null
        END
    )                                                                                                       AS rehabilitation_offset_indicator_088
                  
                FROM vw_fct_claim_payment_detail_r_MV_ssl T425786

                GROUP BY
          T425786.n_claim_coverage_group_sk_r,
                  T425786.n_claim_sk_r;