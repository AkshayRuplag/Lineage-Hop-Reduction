-- Cleaned for lineage: RPT_CLAIM_PAYMENT_DTL_AMT_MV_SSL

CREATE MATERIALIZED VIEW RPT_CLAIM_PAYMENT_DTL_AMT_MV_SSL AS
SELECT
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
    
    
FROM
    RPT_CLAIM_PAYMENT_DTL_AMT_MV_SSL_1,
  
    dim_time_r t,
    (select n_fiscal_quarter_r ,N_FISCAL_YEAR_R,N_FISCAL_MONTH_R,concat(N_FISCAL_YEAR_R,lpad(N_FISCAL_MONTH_R,2,'0'))
    as N_YEARMONTH_R_1 from dim_time_r  where V_END_OF_FISCAL_MONTH_IND_R='Y') t2
WHERE 
       
    
   
 
        
    
         
		           RPT_CLAIM_PAYMENT_DTL_AMT_MV_SSL_1.n_d_paid_date_sk_r = t.N_DATE_SK_R
    
        
        
		AND RPT_CLAIM_PAYMENT_DTL_AMT_MV_SSL_1.n_yearmonth_r = t2.N_YEARMONTH_R_1
GROUP BY
    RPT_CLAIM_PAYMENT_DTL_AMT_MV_SSL_1.n_claim_coverage_group_sk_r,
    RPT_CLAIM_PAYMENT_DTL_AMT_MV_SSL_1.n_claim_coverage_sk_r,
    RPT_CLAIM_PAYMENT_DTL_AMT_MV_SSL_1.n_claim_sk_r,
    RPT_CLAIM_PAYMENT_DTL_AMT_MV_SSL_1.n_yearmonth_r;