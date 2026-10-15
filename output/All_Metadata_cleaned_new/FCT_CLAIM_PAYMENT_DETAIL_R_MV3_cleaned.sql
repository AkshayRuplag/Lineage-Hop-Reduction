-- Cleaned for lineage: FCT_CLAIM_PAYMENT_DETAIL_R_MV3

CREATE MATERIALIZED VIEW FCT_CLAIM_PAYMENT_DETAIL_R_MV3 AS
SELECT
    
        upper(TRIM(a.v_claim_number_r))          v_claim_number_r,
        CASE
            WHEN a.v_cov_group_id_r IS NULL THEN
                upper(TRIM(a.v_claim_number_r))
            ELSE
                upper(TRIM(a.v_claim_number_r
                           || '-'
                           || lpad(a.v_cov_group_id_r, 2, 0)))
        END                                      AS v_claim_identifier_r,
    
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
    
        d_paid_date_r,
        v_check_number_r,
        v_payment_status_r,
        n_fiscal_month_r,
        n_fiscal_year_r,
        v_record_type_r,
    
        v_benefit_code_r,
   
        v_benefit_group_r;