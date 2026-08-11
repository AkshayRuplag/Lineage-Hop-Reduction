
  CREATE MATERIALIZED VIEW "ATOMIC"."VW_FCT_CLAIM_PAYMENT_DETAIL_R_MV_SSL_WAGEBASE_INC" ("N_CHECK_TAXABLE_BENEFIT_R", "N_CHECK_WAGE_BASE_R", "D_SERVICE_PERIOD_FROM_R", "D_SERVICE_PERIOD_TO_R", "V_BENEFIT_CODE_R", "V_CHECK_NUMBER_R", "V_CLAIM_NUMBER_R", "N_CLAIM_SK_R", "D_CHECK_DATE_R", "D_PAID_DATE_R")
  SEGMENT CREATION IMMEDIATE
  ORGANIZATION HEAP PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 8388608 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "OFS_OIDF_DATA_3" 
  PARALLEL 
  BUILD IMMEDIATE
  USING INDEX 
  REFRESH FORCE ON DEMAND
  USING DEFAULT LOCAL ROLLBACK SEGMENT
  USING ENFORCED CONSTRAINTS DISABLE ON QUERY COMPUTATION DISABLE QUERY REWRITE
  AS select  sum(CASE  WHEN fct_claim_payment_detail_r.v_benefit_group_r NOT IN ('098', '097', '099', '200', '297', '298', 'FIC', 'MED')
       AND fct_claim_payment_detail_r.n_paid_amount_r <> 0
                 --01-Jul-2024 changes starts
       AND fct_claim_payment_detail_r.v_check_type_r <> 'OE'
                 --01-Jul-2024 changes ends     
       THEN fct_claim_payment_detail_r.n_paid_amount_r
                 --01-Jul-2024 changes starts
                 ELSE
                    0
                 --01-Jul-2024 changes ends     
                 END               ) over (partition by D_SERVICE_PERIOD_FROM_R,D_SERVICE_PERIOD_TO_R, D_SERVICE_PERIOD_TO_R, V_CHECK_NUMBER_R, n_claiM_sk_r) --check_taxable_benefit,
				 N_CHECK_TAXABLE_BENEFIT_R,
       
        sum(CASE  WHEN fct_claim_payment_detail_r.v_benefit_group_r NOT IN ('098', '097', '099', '200', '297', '298', 'FIC', 'MED')
       AND fct_claim_payment_detail_r.n_paid_amount_r <> 0
                 --01-Jul-2024 changes starts
       AND fct_claim_payment_detail_r.v_check_type_r <> 'OE'
                 --01-Jul-2024 changes ends     
       THEN fct_claim_payment_detail_r.n_paid_amount_r
                 --01-Jul-2024 changes starts
                 ELSE
                    0
                 --01-Jul-2024 changes ends     
                 END               ) over (partition by D_SERVICE_PERIOD_FROM_R,D_SERVICE_PERIOD_TO_R, D_SERVICE_PERIOD_TO_R, V_CHECK_NUMBER_R, n_claiM_sk_r)*
      --(select case  when nvl(N_TAXABLE_OVERRIDE_PCT_R , 0) = 0 then 100 else N_TAXABLE_OVERRIDE_PCT_R end  / 100 from  fct_grp_worksheet where V_RPT_WORKSHEET_INDICATOR_R = 'Y'
      (select case  when nvl(N_TAXABLE_OVERRIDE_PCT_R , 0) = 0 then 100 else N_TAXABLE_OVERRIDE_PCT_R end  / 100 from  fct_grp_worksheet_mv_ssl fct_grp_worksheet where --V_RPT_WORKSHEET_INDICATOR_R = 'Y'
      --and 
	  fct_grp_worksheet.n_claim_sk_r = fct_claim_payment_detail_r.n_claim_sk_r
      and fct_grp_worksheet.n_batch_id_r=(select max(w.n_batch_id_r) from fct_grp_worksheet w where w.n_claim_sk_r = fct_grp_worksheet.n_claim_sk_r)
      --)check_wage_base,
      )N_CHECK_WAGE_BASE_R,
       D_SERVICE_PERIOD_FROM_R,D_SERVICE_PERIOD_TO_R, V_BENEFIT_CODE_R, V_CHECK_NUMBER_R, V_CLAIM_NUMBER_R,N_CLAIM_SK_R, d_check_date_r, d_paid_date_r


from VW_FCT_CLAIM_PAYMENT_DETAIL_R_MV_SSL_INC  fct_claim_payment_detail_r;

  CREATE INDEX "ATOMIC"."VW_FCT_CLAIM_PAYMENT_DETAIL_R_MV_SSL_WAGEBASE_INC_IDX2" ON "ATOMIC"."VW_FCT_CLAIM_PAYMENT_DETAIL_R_MV_SSL_WAGEBASE_INC" ("D_SERVICE_PERIOD_FROM_R", "D_SERVICE_PERIOD_TO_R", "V_BENEFIT_CODE_R", "V_CHECK_NUMBER_R", "V_CLAIM_NUMBER_R", "N_CLAIM_SK_R", "D_CHECK_DATE_R", "D_PAID_DATE_R") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "OFS_OIDF_DATA_3" ;
  CREATE INDEX "ATOMIC"."VW_FCT_CLAIM_PAYMENT_DETAIL_R_MV_SSL_WAGEBASE_INC_IDX1" ON "ATOMIC"."VW_FCT_CLAIM_PAYMENT_DETAIL_R_MV_SSL_WAGEBASE_INC" ("N_CLAIM_SK_R") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "OFS_OIDF_DATA_3" ;

   COMMENT ON MATERIALIZED VIEW "ATOMIC"."VW_FCT_CLAIM_PAYMENT_DETAIL_R_MV_SSL_WAGEBASE_INC"  IS 'snapshot table for snapshot ATOMIC.VW_FCT_CLAIM_PAYMENT_DETAIL_R_MV_SSL_WAGEBASE_INC';


  GRANT SELECT ON "ATOMIC"."VW_FCT_CLAIM_PAYMENT_DETAIL_R_MV_SSL_WAGEBASE_INC" TO "ATOMIC_ALL_RO";
  GRANT SELECT ON "ATOMIC"."VW_FCT_CLAIM_PAYMENT_DETAIL_R_MV_SSL_WAGEBASE_INC" TO "ATOMIC_DEBUG";
