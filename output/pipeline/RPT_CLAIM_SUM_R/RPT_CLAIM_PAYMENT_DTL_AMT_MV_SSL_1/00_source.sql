

  CREATE MATERIALIZED VIEW "ATOMIC"."RPT_CLAIM_PAYMENT_DTL_AMT_MV_SSL_1" ("N_CLAIM_TOTAL_GROSS_AMT_R", "N_CLAIM_TOTAL_LOSS_AMT_R", "N_CLAIM_TOTAL_NET_AMT_R", "N_CLAIM_TOTAL_TAX_AMT_R", "N_CLAIM_COVERAGE_GROUP_SK_R", "N_CLAIM_COVERAGE_SK_R", "N_CLAIM_SK_R", "N_YEARMONTH_R", "D_PAID_DATE_R", "N_D_PAID_DATE_SK_R", "N_BATCH_ID_R_1")
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
  AS SELECT
    RPT_CLAIM_PAYEMNT_DTL_R_MV_SSL.n_paid_amount_r          n_claim_total_gross_amt_r,
    RPT_CLAIM_PAYEMNT_DTL_R_MV_SSL.n_claim_paid_loss_amount_r n_claim_total_loss_amt_r,
    RPT_CLAIM_PAYEMNT_DTL_R_MV_SSL.n_claim_paid_net_amount_r  n_claim_total_net_amt_r,
    RPT_CLAIM_PAYEMNT_DTL_R_MV_SSL.n_taxable_benefit_amount_r n_claim_total_tax_amt_r,
    /*SUM(
        CASE
            WHEN t2.n_fiscal_year_r = t.n_fiscal_year_r
                 AND t2.n_fiscal_month_r = t.n_fiscal_month_r THEN
                RPT_CLAIM_PAYEMNT_DTL_R_MV_SSL.n_claim_paid_loss_amount_r
            ELSE
                0
        END
    )                                                       n_claim_mtd_loss_amt_r,
    SUM(
        CASE
            WHEN t2.n_fiscal_year_r = t.n_fiscal_year_r
                 AND t2.n_fiscal_quarter_r = t.n_fiscal_quarter_r THEN
                RPT_CLAIM_PAYEMNT_DTL_R_MV_SSL.n_claim_paid_loss_amount_r
            ELSE
                0
        END
    )                                                       n_claim_qtd_loss_amt_r,
    SUM(
        CASE
            WHEN t2.n_fiscal_year_r = t.n_fiscal_year_r THEN
                RPT_CLAIM_PAYEMNT_DTL_R_MV_SSL.n_claim_paid_loss_amount_r
            ELSE
                0
        END
    )                                                       n_claim_ytd_loss_amt_r,*/
    RPT_CLAIM_PAYEMNT_DTL_R_MV_SSL.n_claim_coverage_group_sk_r,
    RPT_CLAIM_PAYEMNT_DTL_R_MV_SSL.n_claim_coverage_sk_r,
    RPT_CLAIM_PAYEMNT_DTL_R_MV_SSL.n_claim_sk_r,
    RPT_CLAIM_PAYEMNT_DTL_R_MV_SSL.n_yearmonth_r,
    RPT_CLAIM_PAYEMNT_R_MV_SSL.d_paid_date_r,
    TO_NUMBER(TO_CHAR(RPT_CLAIM_PAYEMNT_R_MV_SSL.d_paid_date_r , 'YYYYMMDD')) as n_d_paid_date_sk_r,
    RPT_CLAIM_PAYEMNT_DTL_R_MV_SSL.N_BATCH_ID_R_1
FROM
    RPT_CLAIM_PAYEMNT_DTL_R_MV_SSL,
    RPT_CLAIM_PAYMENT_R RPT_CLAIM_PAYEMNT_R_MV_SSL
    --dim_time_r t,
    --dim_time_r t2
WHERE RPT_CLAIM_PAYEMNT_R_MV_SSL.n_payment_sk_r = RPT_CLAIM_PAYEMNT_DTL_R_MV_SSL.n_payment_sk_r
AND RPT_CLAIM_PAYEMNT_R_MV_SSL.N_YEARMONTH_R=(select max(p.n_yearmonth_r) from rpt_grp_product_r p)
       -- RPT_CLAIM_PAYEMNT_DTL_R_MV_SSL.n_yearmonth_r = (SELECT MAX(RCPDR1.N_YEARMONTH_R) FROM RPT_CLAIM_PAYEMNT_DTL_R_MV_SSL RCPDR1)
    --AND RPT_CLAIM_PAYEMNT_DTL_R_MV_SSL.n_yearmonth_r = RPT_CLAIM_PAYEMNT_R_MV_SSL.n_yearmonth_r
   -- AND RPT_CLAIM_PAYEMNT_DTL_R_MV_SSL.n_payment_sk_r = RPT_CLAIM_PAYEMNT_R_MV_SSL.n_payment_sk_r
 /*  EXISTS (
        SELECT 1
        FROM RPT_CLAIM_PAYEMNT_R_MV_SSL RPT_CLAIM_PAYEMNT_R_MV_SSL
        WHERE RPT_CLAIM_PAYEMNT_R_MV_SSL.n_payment_sk_r = RPT_CLAIM_PAYEMNT_DTL_R_MV_SSL.n_payment_sk_r
    )*/
        --    and  RPT_CLAIM_PAYEMNT_DTL_R_MV_SSL.N_CLAIM_SK_R  =  RPT_CLAIM_PAYEMNT_R_MV_SSL.N_CLAIM_SK_R
    --AND RPT_CLAIM_PAYEMNT_R_MV_SSL.n_yearmonth_r = '202410'
         -- AND RPT_CLAIM_PAYEMNT_R_MV_SSL.d_paid_date_r = t.d_calendar_date_r
    --AND RPT_CLAIM_PAYEMNT_DTL_R_MV_SSL.n_claim_sk_r = 642468
        -- AND RPT_CLAIM_PAYEMNT_DTL_R_MV_SSL.n_batch_id_r-1 = t2.n_date_sk_r
    --    AND RPT_CLAIM_PAYEMNT_DTL_R_MV_SSL.N_BATCH_ID_R_1 = t2.n_date_sk_r
/*GROUP BY
    RPT_CLAIM_PAYEMNT_DTL_R_MV_SSL.n_claim_coverage_group_sk_r,
    RPT_CLAIM_PAYEMNT_DTL_R_MV_SSL.n_claim_coverage_sk_r,
    RPT_CLAIM_PAYEMNT_DTL_R_MV_SSL.n_claim_sk_r,
    RPT_CLAIM_PAYEMNT_DTL_R_MV_SSL.n_yearmonth_r,
    RPT_CLAIM_PAYEMNT_R_MV_SSL.d_paid_date_r,
    TO_NUMBER(TO_CHAR(RPT_CLAIM_PAYEMNT_R_MV_SSL.d_paid_date_r , 'YYYYMMDD'))*/

