

  CREATE MATERIALIZED VIEW "ATOMIC"."DIM_GRP_MEDICAL_DIAGNOSIS_R_MV_SSL" ("N_CLAIM_SK_R", "ADDITIONAL_DESC", "PRIMARY_DESC", "ADDITIONAL_DIAG_CODE", "PRIMARY_DIAG_CODE", "V_PRI_DIAG_CATEGORY_CODE_R", "ADD_DIAG_CATEGORY_CODE", "V_PRI_DIAG_CATEGORY_DESC_R", "ADD_DIAG_CATEGORY_DESC", "DIAGNOSIS_TYPE_CODE")
  SEGMENT CREATION IMMEDIATE
  ORGANIZATION HEAP PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "OFS_OIDF_DATA_3"
  BUILD IMMEDIATE
  USING INDEX
  REFRESH FORCE ON DEMAND
  USING DEFAULT LOCAL ROLLBACK SEGMENT
  USING ENFORCED CONSTRAINTS DISABLE ON QUERY COMPUTATION DISABLE QUERY REWRITE
  AS SELECT  n_claim_sk_r,
LISTAGG(case when n_primary_ind_r = 0 then nvl(V_DIAG_CODE_DESC_R,v_diagnosis_desc_r) else '' end, '; ') WITHIN GROUP (ORDER BY n_claim_sk_r) as  additional_desc,
LISTAGG(case when n_primary_ind_r = 1 then nvl(V_DIAG_CODE_DESC_R,v_diagnosis_desc_r) else '' end, '; ') WITHIN GROUP (ORDER BY n_claim_sk_r) as  Primary_desc,
LISTAGG(case when n_primary_ind_r = 0 then V_DIAGNOSIS_CODE_R else '' end, '; ') WITHIN GROUP (ORDER BY n_claim_sk_r) as  additional_diag_code,
LISTAGG(case when n_primary_ind_r = 1 then V_DIAGNOSIS_CODE_R else '' end, '; ') WITHIN GROUP (ORDER BY n_claim_sk_r) as  primary_diag_code,
LISTAGG(case when n_primary_ind_r = 1 then DIM_DIAGNOSIS_CODE_R.V_DIAG_CATEGORY_CODE_R else '' end, '; ') WITHIN GROUP (ORDER BY n_claim_sk_r) as  V_PRI_DIAG_CATEGORY_CODE_R,
LISTAGG(case when n_primary_ind_r = 0 then DIM_DIAGNOSIS_CODE_R.V_DIAG_CATEGORY_CODE_R else '' end, '; ') WITHIN GROUP (ORDER BY n_claim_sk_r) as  add_diag_category_code,
LISTAGG(case when n_primary_ind_r = 1 then DIM_DIAGNOSIS_CATEGORY_R.V_DIAG_CATEGORY_DESC_R else '' end, '; ') WITHIN GROUP (ORDER BY n_claim_sk_r) as  V_PRI_DIAG_CATEGORY_DESC_R,
LISTAGG(case when n_primary_ind_r = 0 then DIM_DIAGNOSIS_CATEGORY_R.V_DIAG_CATEGORY_DESC_R else '' end, '; ') WITHIN GROUP (ORDER BY n_claim_sk_r) as  add_diag_category_desc,
max(case when n_primary_ind_r = 1  then N_DIAGNOSIS_TYPE_CODE_R else 0 end) as  diagnosis_type_code
FROM
dim_grp_medical_diagnosis_r dim_grp_medical_diagnosis_r
left join DIM_DIAGNOSIS_CODE_R DIM_DIAGNOSIS_CODE_R
on dim_grp_medical_diagnosis_r.V_DIAGNOSIS_CODE_R = DIM_DIAGNOSIS_CODE_R.V_DIAG_CODE_R
--and DIM_DIAGNOSIS_CODE_R.v_active_status_r = 'Y'
left join DIM_DIAGNOSIS_CATEGORY_R DIM_DIAGNOSIS_CATEGORY_R
on DIM_DIAGNOSIS_CODE_R.V_DIAG_CATEGORY_CODE_R = DIM_DIAGNOSIS_CATEGORY_R.V_DIAG_CATEGORY_CODE_R
--and DIM_DIAGNOSIS_CATEGORY_R.v_active_status_r = 'Y'
WHERE
dim_grp_medical_diagnosis_r.v_active_status_r = 'Y'
and n_claim_sk_r<>-1
GROUP BY
n_claim_sk_r

