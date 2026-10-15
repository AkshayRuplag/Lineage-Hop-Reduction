-- Cleaned for lineage: FCT_GRP_CLAIM_NOTE_R_DRQ_MV_SSL_INC

CREATE MATERIALIZED VIEW FCT_GRP_CLAIM_NOTE_R_DRQ_MV_SSL_INC AS
select DISTINCT
    fct_grp_claim_note_r.N_CLAIM_SK_R,
    fct_grp_claim_note_r.N_CLAIM_SUBSEQUENCE_NUMBER_R,
    NVL(fct_grp_claim_note_r.N_SEQ_R,9999999) as N_SEQ_R,
    fct_grp_claim_note_r.D_CREATED_DATE_R,
    fct_grp_claim_note_r.N_BATCH_ID_R,
    fct_grp_claim_note_r.t_last_modified_date_r
   ,dim_grp_claim_policy_detail_emp_mv_ssl.n_employee_sk_r        n_employee_sk_r
   ,dim_grp_claim_policy_detail_emp_mv_ssl.n_insrd_party_sk_r     n_insrd_party_sk_r
   ,DIM_GRP_CLAIM_POLICY_DETAIL_EMP_MV_SSL.N_CUST_PARTY_SK_R      N_CUST_PARTY_SK_R
   ,DIM_GRP_CLAIM_POLICY_DETAIL_EMP_MV_SSL.V_RPT_ACTIVE_STATUS_R  V_RPT_ACTIVE_STATUS_R
   ,dim_grp_claim_policy_detail_emp_mv_ssl.n_policy_sk_r          n_policy_sk_r
   ,dim_grp_sysuseso_r.v_description_r                            v_note_created_by_r
from atomic.fct_grp_claim_note_r fct_grp_claim_note_r
INNER JOIN atomic.dim_grp_claim_policy_detail_emp_mv_ssl DIM_GRP_CLAIM_POLICY_DETAIL_EMP_MV_SSL
    ON fct_grp_claim_note_r.n_claim_sk_r = dim_grp_claim_policy_detail_emp_mv_ssl.n_claim_sk_r
left join atomic.DIM_GRP_SYSUSESO_R on UPPER(FCT_GRP_CLAIM_NOTE_R.V_CREATED_BY_ID_R) = DIM_GRP_SYSUSESO_R.V_LOGIN_ID_R
where fct_grp_claim_note_r.N_CLAIM_SK_R <>-1;