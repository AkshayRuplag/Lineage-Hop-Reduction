

  CREATE MATERIALIZED VIEW "ATOMIC"."FCT_GRP_CLAIM_NOTE_R_DRQ_MV_SSL_INC" ("N_CLAIM_SK_R", "N_CLAIM_SUBSEQUENCE_NUMBER_R", "N_SEQ_R", "D_CREATED_DATE_R", "N_BATCH_ID_R", "T_LAST_MODIFIED_DATE_R", "N_EMPLOYEE_SK_R", "N_INSRD_PARTY_SK_R", "N_CUST_PARTY_SK_R", "V_RPT_ACTIVE_STATUS_R", "N_POLICY_SK_R", "V_NOTE_CREATED_BY_R")
  SEGMENT CREATION IMMEDIATE
  ORGANIZATION HEAP PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255
 NOCOMPRESS NOLOGGING
  STORAGE(INITIAL 65536 NEXT 8388608 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "OFS_OIDF_DATA_3"
  PARALLEL (DEGREE 4 INSTANCES DEFAULT)
  BUILD IMMEDIATE
  USING INDEX
  REFRESH FORCE ON DEMAND
  USING DEFAULT LOCAL ROLLBACK SEGMENT
  USING ENFORCED CONSTRAINTS DISABLE ON QUERY COMPUTATION DISABLE QUERY REWRITE
  AS select DISTINCT
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
where fct_grp_claim_note_r.N_CLAIM_SK_R <>-1

