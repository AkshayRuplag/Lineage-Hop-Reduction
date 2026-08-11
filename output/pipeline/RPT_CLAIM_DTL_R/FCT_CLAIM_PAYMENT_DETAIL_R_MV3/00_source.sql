

  CREATE MATERIALIZED VIEW "ATOMIC"."FCT_CLAIM_PAYMENT_DETAIL_R_MV3" ("V_CLAIM_NUMBER_R", "V_CLAIM_IDENTIFIER_R", "D_SERVICE_PERIOD_FROM_R", "V_CHECK_NUMBER_R", "V_PAYMENT_STATUS_R", "N_FISCAL_MONTH_R", "N_FISCAL_YEAR_R", "V_RECORD_TYPE_R", "N_PAID_AMOUNT_R", "V_BENEFIT_CODE_R", "N_PAID_CLAIM_BENEFITS_R", "V_BENEFIT_GROUP_R")
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
    --/*+PARALLEL(4)*/
        upper(TRIM(a.v_claim_number_r))          v_claim_number_r,
        CASE
            WHEN a.v_cov_group_id_r IS NULL THEN
                upper(TRIM(a.v_claim_number_r))
            ELSE
                upper(TRIM(a.v_claim_number_r
                           || '-'
                           || lpad(a.v_cov_group_id_r, 2, 0)))
        END                                      AS v_claim_identifier_r,
    -- D_SERVICE_PERIOD_FROM_R,
        d_paid_date_r                            d_service_period_from_r,
        v_check_number_r,
        v_payment_status_r,
        n_fiscal_month_r,
        n_fiscal_year_r,
        v_record_type_r,
        sum(n_paid_amount_r),
        v_benefit_code_r,
       sum( n_paid_claim_benefits_r),
        v_benefit_group_r
    FROM
        FCT_CLAIM_PAYMENT_DETAIL_R  a
        LEFT JOIN dim_time_r                     t ON a.d_paid_date_r = t.d_calendar_date_r
    GROUP BY
        upper(TRIM(a.v_claim_number_r)),
        CASE
            WHEN a.v_cov_group_id_r IS NULL THEN
                    upper(TRIM(a.v_claim_number_r))
            ELSE
                upper(TRIM(a.v_claim_number_r
                           || '-'
                           || lpad(a.v_cov_group_id_r, 2, 0)))
        END,
    -- D_SERVICE_PERIOD_FROM_R,
        d_paid_date_r,
        v_check_number_r,
        v_payment_status_r,
        n_fiscal_month_r,
        n_fiscal_year_r,
        v_record_type_r,
    --   n_paid_amount_r,
        v_benefit_code_r,
   --     n_paid_claim_benefits_r,
        v_benefit_group_r

