

  CREATE MATERIALIZED VIEW "ATOMIC"."RPT_CLAIM_PAYMENT_DTL_AMT_MV_SSL" ("N_CLAIM_TOTAL_GROSS_AMT_R", "N_CLAIM_TOTAL_LOSS_AMT_R", "N_CLAIM_TOTAL_NET_AMT_R", "N_CLAIM_TOTAL_TAX_AMT_R", "N_CLAIM_MTD_LOSS_AMT_R", "N_CLAIM_QTD_LOSS_AMT_R", "N_CLAIM_YTD_LOSS_AMT_R", "N_CLAIM_COVERAGE_GROUP_SK_R", "N_CLAIM_COVERAGE_SK_R", "N_CLAIM_SK_R", "N_YEARMONTH_R")
  SEGMENT CREATION IMMEDIATE
  ORGANIZATION HEAP PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
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
    SUM(RPT_CLAIM_PAYMENT_DTL_AMT_MV_SSL_1.n_claim_total_gross_amt_r)        n_claim_total_gross_amt_r,
    SUM(RPT_CLAIM_PAYMENT_DTL_AMT_MV_SSL_1.n_claim_total_loss_amt_r) n_claim_total_loss_amt_r,
    SUM(RPT_CLAIM_PAYMENT_DTL_AMT_MV_SSL_1.n_claim_total_net_amt_r)  n_claim_total_net_amt_r,
    SUM(RPT_CLAIM_PAYMENT_DTL_AMT_MV_SSL_1.n_claim_total_tax_amt_r) n_claim_total_tax_amt_r,
    SUM(
        CASE
            WHEN t2.n_fiscal_year_r = t.n_fiscal_year_r
                 AND t2.n_fiscal_month_r = t.n_fiscal_month_r THEN
                RPT_CLAIM_PAYMENT_DTL_AMT_MV_SSL_1.n_claim_total_loss_amt_r
            ELSE
                0
        END
    )                                                       n_claim_mtd_loss_amt_r,
    SUM(
        CASE
            WHEN t2.n_fiscal_year_r = t.n_fiscal_year_r
                 AND t2.n_fiscal_quarter_r = t.n_fiscal_quarter_r THEN
                RPT_CLAIM_PAYMENT_DTL_AMT_MV_SSL_1.n_claim_total_loss_amt_r
            ELSE
                0
        END
    )                                                       n_claim_qtd_loss_amt_r,
    SUM(
        CASE
            WHEN t2.n_fiscal_year_r = t.n_fiscal_year_r THEN
                RPT_CLAIM_PAYMENT_DTL_AMT_MV_SSL_1.n_claim_total_loss_amt_r
            ELSE
                0
        END
    )                                                       n_claim_ytd_loss_amt_r,
    RPT_CLAIM_PAYMENT_DTL_AMT_MV_SSL_1.n_claim_coverage_group_sk_r,
    RPT_CLAIM_PAYMENT_DTL_AMT_MV_SSL_1.n_claim_coverage_sk_r,
    RPT_CLAIM_PAYMENT_DTL_AMT_MV_SSL_1.n_claim_sk_r,
    RPT_CLAIM_PAYMENT_DTL_AMT_MV_SSL_1.n_yearmonth_r
    --RPT_CLAIM_PAYMENT_DTL_AMT_MV_SSL_1.d_paid_date_r,
    --RPT_CLAIM_PAYMENT_DTL_AMT_MV_SSL_1.n_d_paid_date_sk_r
FROM
    RPT_CLAIM_PAYMENT_DTL_AMT_MV_SSL_1,
  --  RPT_CLAIM_PAYEMNT_R_MV_SSL
    dim_time_r t,
    (select n_fiscal_quarter_r ,N_FISCAL_YEAR_R,N_FISCAL_MONTH_R,concat(N_FISCAL_YEAR_R,lpad(N_FISCAL_MONTH_R,2,'0'))
    as N_YEARMONTH_R_1 from dim_time_r  where V_END_OF_FISCAL_MONTH_IND_R='Y') t2
WHERE --RPT_CLAIM_PAYEMNT_R_MV_SSL.n_payment_sk_r = RPT_CLAIM_PAYMENT_DTL_AMT_MV_SSL_1.n_payment_sk_r
       -- RPT_CLAIM_PAYMENT_DTL_AMT_MV_SSL_1.n_yearmonth_r = (SELECT MAX(RCPDR1.N_YEARMONTH_R) FROM RPT_CLAIM_PAYMENT_DTL_AMT_MV_SSL_1 RCPDR1)
    --AND RPT_CLAIM_PAYMENT_DTL_AMT_MV_SSL_1.n_yearmonth_r = RPT_CLAIM_PAYEMNT_R_MV_SSL.n_yearmonth_r
   -- AND RPT_CLAIM_PAYMENT_DTL_AMT_MV_SSL_1.n_payment_sk_r = RPT_CLAIM_PAYEMNT_R_MV_SSL.n_payment_sk_r
 /*  EXISTS (
        SELECT 1
        FROM RPT_CLAIM_PAYEMNT_R_MV_SSL RPT_CLAIM_PAYEMNT_R_MV_SSL
        WHERE RPT_CLAIM_PAYEMNT_R_MV_SSL.n_payment_sk_r = RPT_CLAIM_PAYMENT_DTL_AMT_MV_SSL_1.n_payment_sk_r
    )*/
        --    and  RPT_CLAIM_PAYMENT_DTL_AMT_MV_SSL_1.N_CLAIM_SK_R  =  RPT_CLAIM_PAYEMNT_R_MV_SSL.N_CLAIM_SK_R
    --AND RPT_CLAIM_PAYEMNT_R_MV_SSL.n_yearmonth_r = '202410'
         -- AND RPT_CLAIM_PAYEMNT_R_MV_SSL.d_paid_date_r = t.d_calendar_date_r
		           RPT_CLAIM_PAYMENT_DTL_AMT_MV_SSL_1.n_d_paid_date_sk_r = t.N_DATE_SK_R
    --AND RPT_CLAIM_PAYMENT_DTL_AMT_MV_SSL_1.n_claim_sk_r = 642468
        -- AND RPT_CLAIM_PAYMENT_DTL_AMT_MV_SSL_1.n_batch_id_r-1 = t2.n_date_sk_r
        --AND RPT_CLAIM_PAYMENT_DTL_AMT_MV_SSL_1.N_BATCH_ID_R_1 = t2.n_date_sk_r --old LOGICAL_READS_PER_CALLOGICAL_READS_PER_SESSION
		AND RPT_CLAIM_PAYMENT_DTL_AMT_MV_SSL_1.n_yearmonth_r = t2.N_YEARMONTH_R_1
GROUP BY
    RPT_CLAIM_PAYMENT_DTL_AMT_MV_SSL_1.n_claim_coverage_group_sk_r,
    RPT_CLAIM_PAYMENT_DTL_AMT_MV_SSL_1.n_claim_coverage_sk_r,
    RPT_CLAIM_PAYMENT_DTL_AMT_MV_SSL_1.n_claim_sk_r,
    RPT_CLAIM_PAYMENT_DTL_AMT_MV_SSL_1.n_yearmonth_r
    --RPT_CLAIM_PAYMENT_DTL_AMT_MV_SSL_1.d_paid_date_r,
    --RPT_CLAIM_PAYMENT_DTL_AMT_MV_SSL_1.n_d_paid_date_sk_r ;

