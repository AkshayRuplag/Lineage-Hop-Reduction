-- Cleaned for lineage: RPT_CLAIM_TASK_R_DRQ_MV_SSL_INC

CREATE MATERIALIZED VIEW RPT_CLAIM_TASK_R_DRQ_MV_SSL_INC AS
SELECT DISTINCT
    NVL(A.N_SOURCE_VERSION_SEQ_NUMBER_R,-1)  N_SOURCE_VERSION_SEQ_NUMBER_R,
    NVL(a.N_Claim_Sk_r,-1)                          AS N_Claim_Sk_r	         ,
    NVL(a.n_claim_coverage_sk_r,-1)               AS n_claim_coverage_sk_r	 ,
    NVL(f.n_claim_coverage_group_sk_r,-1)   AS n_claim_coverage_group_sk_r	 ,
    a.t_last_modified_date_r,
    nvl(a.N_TASK_SEQUENCE_R,-1) as N_TASK_SEQUENCE_R
    FROM
	     (
            SELECT    
                    a.n_claim_sk_r,
                    a.V_ASSIGNMENT_ID_R      AS V_ASSIGNMENT_ID_R	,
                    a.V_s_CREATED_BY_R       AS V_s_CREATED_BY_R	,
                    trunc(a.D_DUE_DATE_R  )                      AS D_DUE_DATE_R	    ,
                    a.N_PRIORITY_R                        AS N_PRIORITY_R	              ,
                    a.N_SOURCE_VERSION_SEQ_NUMBER_R       AS N_SOURCE_VERSION_SEQ_NUMBER_R
                    ,c.v_examiner_login_id_r
                    ,e.n_claim_coverage_sk_r
                    ,e.v_claim_coverage_code_r
                    ,b.n_policy_sk_r
                    
                     ,GREATEST(
                              COALESCE(a.t_last_modified_date_r, TO_DATE('1900-01-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS'))
                             ,COALESCE(b.t_last_modified_date_r, TO_DATE('1900-01-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS'))
                             ,COALESCE(c.t_last_modified_date_r, TO_DATE('1900-01-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS'))
                             ,COALESCE(e.t_last_modified_date_r, TO_DATE('1900-01-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS'))
                             ) as t_last_modified_date_r
                    ,a.N_TASK_SEQUENCE_R
                    ,a.V_CELL_WORKER_ID_R     AS V_CELL_WORKER_ID_R
            FROM ATOMIC.fct_grp_process_custom_r A
                ,ATOMIC.dim_grp_claim_dir_r B
                ,ATOMIC.dim_grp_claim_detail_r C
                ,ATOMIC.dim_grp_claim_coverage_r e
            WHERE    A.n_claim_sk_r <> - 1
              AND a.N_CLAIM_SK_R=B.N_CLAIM_SK_R  AND B.v_active_status_r = 'Y'
              AND a.N_CLAIM_SK_R=c.N_CLAIM_SK_R  AND C.v_active_status_r = 'Y'
              AND a.N_CLAIM_SK_R=e.N_CLAIM_SK_R  AND e.v_active_status_r = 'Y'
        ) a
        LEFT JOIN ATOMIC.dim_employee_r    d ON d.v_employee_login_id_r = a.v_examiner_login_id_r
                                      AND nvl(upper(d.v_business_unit_r),
                                              'CLAIMS') = 'CLAIMS'
        LEFT OUTER JOIN ATOMIC.mvw_product_sk_lookup     mv1
           
		                                                        
             ON a.v_claim_coverage_code_r = mv1.v_claim_coverage_code_r
                                                     AND a.n_claim_sk_r = mv1.n_claim_sk_r
        LEFT OUTER JOIN ATOMIC.dim_grp_product_r     pd1
             ON mv1.n_product_sk_r = pd1.n_product_sk_r
        
        LEFT JOIN ATOMIC.dim_grp_claim_coverage_group_r f ON f.n_claim_coverage_sk_r = a.n_claim_coverage_sk_r
        AND f.v_active_status_r = 'Y'
        LEFT OUTER JOIN ATOMIC.mvw_product_sk_lookup          mv2
             ON f.v_claim_coverage_code_r = mv2.v_claim_coverage_code_r
                                                     AND f.n_claim_sk_r = mv2.n_claim_sk_r
        LEFT OUTER JOIN ATOMIC.dim_grp_product_r              pd2
             ON mv2.n_product_sk_r = pd2.n_product_sk_r
        
        LEFT JOIN ATOMIC.dim_grp_policy_dir_r           g ON a.n_policy_sk_r = g.n_policy_sk_r
                                            AND g.v_active_status_r = 'Y'
        LEFT JOIN ATOMIC.fct_grp_policy_r               h ON g.n_policy_sk_r = h.n_policy_sk_r
                                        AND g.n_policy_version_number_r = h.n_version_number_r
                                        AND g.n_source_system_key_r = h.n_source_system_key_r
        Left join ATOMIC.DIM_GRP_SYSUSESO_R on upper(DIM_GRP_SYSUSESO_R.V_LOGIN_ID_R) = UPPER(a.V_ASSIGNMENT_ID_R )
        Left join ATOMIC.DIM_GRP_SYSUSESO_R on upper(DIM_GRP_SYSUSESO_R.V_LOGIN_ID_R) = UPPER(a.V_S_CREATED_BY_R  )
        Left join ATOMIC.DIM_GRP_SYSUSESO_R on upper(DIM_GRP_SYSUSESO_R.V_LOGIN_ID_R) = UPPER(a.V_CELL_WORKER_ID_r);