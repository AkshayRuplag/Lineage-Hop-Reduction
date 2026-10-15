-- Cleaned for lineage: MVW_PRODUCT_SK_LOOKUP_MIN_MV_SSL

CREATE MATERIALIZED VIEW MVW_PRODUCT_SK_LOOKUP_MIN_MV_SSL AS
SELECT   min(n_product_sk_r) n_product_sk_r, n_claim_sk_r,v_claim_coverage_code_r
           from mvw_product_sk_lookup group by n_claim_sk_r,v_claim_coverage_code_r;