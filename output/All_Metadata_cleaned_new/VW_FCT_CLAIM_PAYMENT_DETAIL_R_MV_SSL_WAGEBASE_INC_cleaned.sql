-- Cleaned for lineage: VW_FCT_CLAIM_PAYMENT_DETAIL_R_MV_SSL_WAGEBASE_INC

CREATE MATERIALIZED VIEW VW_FCT_CLAIM_PAYMENT_DETAIL_R_MV_SSL_WAGEBASE_INC AS
select  sum(CASE  WHEN fct_claim_payment_detail_r.v_benefit_group_r NOT IN ('098', '097', '099', '200', '297', '298', 'FIC', 'MED')
       AND fct_claim_payment_detail_r.n_paid_amount_r <> 0
                 
       AND fct_claim_payment_detail_r.v_check_type_r <> 'OE'
                 
       THEN fct_claim_payment_detail_r.n_paid_amount_r
                 
                 ELSE
                    0
                 
                 END               ) over (partition by D_SERVICE_PERIOD_FROM_R,D_SERVICE_PERIOD_TO_R, D_SERVICE_PERIOD_TO_R, V_CHECK_NUMBER_R, n_claiM_sk_r) 
				 N_CHECK_TAXABLE_BENEFIT_R,
       
        sum(CASE  WHEN fct_claim_payment_detail_r.v_benefit_group_r NOT IN ('098', '097', '099', '200', '297', '298', 'FIC', 'MED')
       AND fct_claim_payment_detail_r.n_paid_amount_r <> 0
                 
       AND fct_claim_payment_detail_r.v_check_type_r <> 'OE'
                 
       THEN fct_claim_payment_detail_r.n_paid_amount_r
                 
                 ELSE
                    0
                 
                 END               ) over (partition by D_SERVICE_PERIOD_FROM_R,D_SERVICE_PERIOD_TO_R, D_SERVICE_PERIOD_TO_R, V_CHECK_NUMBER_R, n_claiM_sk_r)*
      
      (select case  when nvl(N_TAXABLE_OVERRIDE_PCT_R , 0) = 0 then 100 else N_TAXABLE_OVERRIDE_PCT_R end  / 100 from  fct_grp_worksheet_mv_ssl fct_grp_worksheet where 
      
	  fct_grp_worksheet.n_claim_sk_r = fct_claim_payment_detail_r.n_claim_sk_r
      and fct_grp_worksheet.n_batch_id_r=(select max(w.n_batch_id_r) from fct_grp_worksheet w where w.n_claim_sk_r = fct_grp_worksheet.n_claim_sk_r)
      
      )N_CHECK_WAGE_BASE_R,
       D_SERVICE_PERIOD_FROM_R,D_SERVICE_PERIOD_TO_R, V_BENEFIT_CODE_R, V_CHECK_NUMBER_R, V_CLAIM_NUMBER_R,N_CLAIM_SK_R, d_check_date_r, d_paid_date_r


from VW_FCT_CLAIM_PAYMENT_DETAIL_R_MV_SSL_INC  fct_claim_payment_detail_r;