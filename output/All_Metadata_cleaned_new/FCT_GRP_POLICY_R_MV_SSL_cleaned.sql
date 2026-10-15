-- Cleaned for lineage: FCT_GRP_POLICY_R_MV_SSL

CREATE MATERIALIZED VIEW FCT_GRP_POLICY_R_MV_SSL AS
SELECT    max(n_cust_party_sk_r) n_cust_party_sk_r, n_policy_sk_r, n_version_number_r
           from  fct_grp_policy_r group by n_policy_sk_r,n_version_number_r;