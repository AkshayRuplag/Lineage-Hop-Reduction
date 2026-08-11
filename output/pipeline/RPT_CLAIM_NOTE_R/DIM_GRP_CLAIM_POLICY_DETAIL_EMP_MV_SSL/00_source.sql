

  CREATE MATERIALIZED VIEW "ATOMIC"."DIM_GRP_CLAIM_POLICY_DETAIL_EMP_MV_SSL" ("N_CLAIM_SK_R", "V_RPT_ACTIVE_STATUS_R", "N_POLICY_SK_R", "N_INSRD_PARTY_SK_R", "N_CUST_PARTY_SK_R", "N_EMPLOYEE_SK_R")
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
  AS SELECT     dim_grp_claim_dir_r.n_claim_sk_r
           ,dim_grp_claim_dir_r.v_active_status_r                  v_rpt_active_status_r
		   ,NVL(dim_grp_policy_dir_r.n_policy_sk_r,-1)              n_policy_sk_r         -- TEMP FIX TO PASS -1 AS IT WAS PART OF PK
           --,dim_grp_sysuseso_r.v_description_r                      v_note_created_by_r
           ,NVL(dim_grp_claim_detail_r.n_insrd_party_sk_r,-1)       n_insrd_party_sk_r-- TEMP FIX TO PASS -1 AS IT WAS PART OF PK
           ,NVL(fct_grp_policy_r.n_cust_party_sk_r,-1)              n_cust_party_sk_r -- TEMP FIX TO PASS -1 AS IT WAS PART OF PK
		   ,NVL(dim_employee_r.n_employee_sk_r,-1)                  n_employee_sk_r
FROM  DIM_GRP_CLAIM_DIR_R dim_grp_claim_dir_r
    --ON fct_grp_claim_note_r.n_claim_sk_r = dim_grp_claim_dir_r.n_claim_sk_r
    LEFT JOIN dim_grp_policy_dir_r dim_grp_policy_dir_r
    ON dim_grp_claim_dir_r.n_policy_sk_r = dim_grp_policy_dir_r.n_policy_sk_r
    AND dim_grp_policy_dir_r.v_active_status_r = 'Y'
    LEFT JOIN dim_grp_claim_detail_r dim_grp_claim_detail_r
    ON dim_grp_claim_dir_r.n_claim_sk_r = dim_grp_claim_detail_r.n_claim_sk_r
    AND dim_grp_claim_detail_r.v_active_status_r = 'Y'
    LEFT JOIN dim_employee_r dim_employee_r
    ON dim_grp_claim_detail_r.v_examiner_login_id_r = dim_employee_r.v_employee_login_id_r
    AND dim_employee_r.v_business_unit_r = 'Claims'
    LEFT JOIN /*(select * max(n_cust_party_sk_r)n_cust_party_sk_r, n_policy_sk_r, n_version_number_r
                 from  fct_grp_policy_r
    		  group by n_policy_sk_r,n_version_number_r
			  FROM FCT_GRP_POLICY_R_MV_SSL
    		  )*/ FCT_GRP_POLICY_R_MV_SSL  fct_grp_policy_r
    ON dim_grp_policy_dir_r.n_policy_sk_r = fct_grp_policy_r.n_policy_sk_r
    AND dim_grp_policy_dir_r.n_policy_version_number_r = FCT_GRP_POLICY_R.n_version_number_r
    where dim_grp_claim_dir_r.v_active_status_r = 'Y'--19-Mar-2024 changes
	--left join dim_grp_sysuseso_r on upper(fct_grp_claim_note_r. v_created_by_id_r) = dim_grp_sysuseso_r. V_LOGIN_ID_R
GROUP BY dim_grp_claim_dir_r.n_claim_sk_r
         ,dim_grp_claim_dir_r.v_active_status_r
         ,NVL(dim_grp_policy_dir_r.n_policy_sk_r,-1)
         --,dim_grp_sysuseso_r.v_description_r
         ,NVL(dim_grp_claim_detail_r.n_insrd_party_sk_r,-1)
         ,NVL(fct_grp_policy_r.n_cust_party_sk_r,-1)
         ,NVL(dim_employee_r.n_employee_sk_r,-1)

