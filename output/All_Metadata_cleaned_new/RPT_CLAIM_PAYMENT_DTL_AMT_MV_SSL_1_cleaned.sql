-- Cleaned for lineage: RPT_CLAIM_PAYMENT_DTL_AMT_MV_SSL_1

CREATE MATERIALIZED VIEW RPT_CLAIM_PAYMENT_DTL_AMT_MV_SSL_1 AS
SELECT
    RPT_CLAIM_PAYEMNT_DTL_R_MV_SSL.n_paid_amount_r          n_claim_total_gross_amt_r,
    RPT_CLAIM_PAYEMNT_DTL_R_MV_SSL.n_claim_paid_loss_amount_r n_claim_total_loss_amt_r,
    RPT_CLAIM_PAYEMNT_DTL_R_MV_SSL.n_claim_paid_net_amount_r  n_claim_total_net_amt_r,
    RPT_CLAIM_PAYEMNT_DTL_R_MV_SSL.n_taxable_benefit_amount_r n_claim_total_tax_amt_r,
    
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
    
    
WHERE RPT_CLAIM_PAYEMNT_R_MV_SSL.n_payment_sk_r = RPT_CLAIM_PAYEMNT_DTL_R_MV_SSL.n_payment_sk_r
AND RPT_CLAIM_PAYEMNT_R_MV_SSL.N_YEARMONTH_R=(select max(p.n_yearmonth_r) from rpt_grp_product_r p);