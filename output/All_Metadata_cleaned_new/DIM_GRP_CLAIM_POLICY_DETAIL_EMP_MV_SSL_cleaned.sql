-- Cleaned for lineage: DIM_GRP_CLAIM_POLICY_DETAIL_EMP_MV_SSL

CREATE MATERIALIZED VIEW DIM_GRP_CLAIM_POLICY_DETAIL_EMP_MV_SSL AS
SELECT     dim_grp_claim_dir_r.n_claim_sk_r
           ,dim_grp_claim_dir_r.v_active_status_r                  v_rpt_active_status_r
		   ,NVL(dim_grp_policy_dir_r.n_policy_sk_r,-1)              n_policy_sk_r         
           
           ,NVL(dim_grp_claim_detail_r.n_insrd_party_sk_r,-1)       n_insrd_party_sk_r
           ,NVL(fct_grp_policy_r.n_cust_party_sk_r,-1)              n_cust_party_sk_r 
		   ,NVL(dim_employee_r.n_employee_sk_r,-1)                  n_employee_sk_r
FROM  DIM_GRP_CLAIM_DIR_R dim_grp_claim_dir_r
    
    LEFT JOIN dim_grp_policy_dir_r dim_grp_policy_dir_r
    ON dim_grp_claim_dir_r.n_policy_sk_r = dim_grp_policy_dir_r.n_policy_sk_r
    AND dim_grp_policy_dir_r.v_active_status_r = 'Y'
    LEFT JOIN dim_grp_claim_detail_r dim_grp_claim_detail_r
    ON dim_grp_claim_dir_r.n_claim_sk_r = dim_grp_claim_detail_r.n_claim_sk_r
    AND dim_grp_claim_detail_r.v_active_status_r = 'Y'
    LEFT JOIN dim_employee_r dim_employee_r
    ON dim_grp_claim_detail_r.v_examiner_login_id_r = dim_employee_r.v_employee_login_id_r
    AND dim_employee_r.v_business_unit_r = 'Claims'
    LEFT JOIN  FCT_GRP_POLICY_R_MV_SSL  fct_grp_policy_r
    ON dim_grp_policy_dir_r.n_policy_sk_r = fct_grp_policy_r.n_policy_sk_r
    AND dim_grp_policy_dir_r.n_policy_version_number_r = FCT_GRP_POLICY_R.n_version_number_r
    where dim_grp_claim_dir_r.v_active_status_r = 'Y'
	
GROUP BY dim_grp_claim_dir_r.n_claim_sk_r
         ,dim_grp_claim_dir_r.v_active_status_r
         ,NVL(dim_grp_policy_dir_r.n_policy_sk_r,-1)
         
         ,NVL(dim_grp_claim_detail_r.n_insrd_party_sk_r,-1)
         ,NVL(fct_grp_policy_r.n_cust_party_sk_r,-1)
         ,NVL(dim_employee_r.n_employee_sk_r,-1);