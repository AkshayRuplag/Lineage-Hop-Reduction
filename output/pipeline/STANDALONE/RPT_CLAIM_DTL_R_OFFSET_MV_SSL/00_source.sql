

  CREATE MATERIALIZED VIEW "ATOMIC"."RPT_CLAIM_DTL_R_OFFSET_MV_SSL" ("N_CLAIM_SK_R", "N_CLAIM_COVERAGE_GROUP_SK_R", "WORK_INCENTIVE_EXCESS_OFFSET_INDICATOR_188", "REHABILITATION_OFFSET_AMOUNT_088", "WORKERS_COMPENSATION_OFFSET_AMOUNT_083", "OTHER_OFFSET_AMOUNTS", "REHABILITATION_OFFSET_INDICATOR_088")
  SEGMENT CREATION IMMEDIATE
  ORGANIZATION HEAP PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "OFS_OIDF_DATA_3"
  BUILD IMMEDIATE
  USING INDEX
  REFRESH FORCE ON DEMAND
  USING DEFAULT LOCAL ROLLBACK SEGMENT
  USING ENFORCED CONSTRAINTS DISABLE ON QUERY COMPUTATION DISABLE QUERY REWRITE
  AS SELECT
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
                  -- SUM(T425786.N_PAID_AMOUNT_R) AS CLAIM_TOTAL_PAID_AMOUNT
                FROM vw_fct_claim_payment_detail_r_MV_ssl T425786

                GROUP BY
          T425786.n_claim_coverage_group_sk_r,
                  T425786.n_claim_sk_r

