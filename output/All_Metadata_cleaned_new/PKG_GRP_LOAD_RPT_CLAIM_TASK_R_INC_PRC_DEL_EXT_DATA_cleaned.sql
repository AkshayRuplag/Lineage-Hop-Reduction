-- Cleaned for lineage: PKG_GRP_LOAD_RPT_CLAIM_TASK_R_INC_PRC_DEL_EXT_DATA

gv_trcmsg:='4.1 START: DELETE EXSISTING RECORDS '||chr(13);

DELETE  FROM RPT_CLAIM_TASK_R
            WHERE N_YEARMONTH_R = gn_current_month
              AND (N_CLAIM_SK_R
                 , N_CLAIM_COVERAGE_SK_R
                 , N_CLAIM_COVERAGE_GROUP_SK_R
                 , N_TASK_SEQUENCE_R
                 , N_SOURCE_VERSION_SEQ_NUMBER_R
                  ) IN
                  ( SELECT N_CLAIM_SK_R
                         , N_CLAIM_COVERAGE_SK_R
                         , N_CLAIM_COVERAGE_GROUP_SK_R
                         , N_TASK_SEQUENCE_R
                         , N_SOURCE_VERSION_SEQ_NUMBER_R
                      FROM RPT_CLAIM_TASK_R_DRQ_MV_SSL_INC
                     WHERE T_LAST_MODIFIED_DATE_R >= ( SELECT max(END_DATE)
                                                         FROM SSL_PACKAGE_MILESTONE_TABLE
                                                        WHERE JOB_NAME='PKG_GRP_LOAD_RPT_CLAIM_TASK_R_INC'
                                                     )
                  );

gv_trcmsg := '4.2 END: DELETE EXSISTING RECORDS .Total records deleted : '||ln_rec_cnt;

DELETE 
            FROM RPT_CLAIM_TASK_R T
           WHERE N_YEARMONTH_R = GN_CURRENT_MONTH
             AND (N_SOURCE_VERSION_SEQ_NUMBER_R
                , N_Claim_Sk_r
                , n_claim_coverage_sk_r
                , N_TASK_SEQUENCE_R) IN ( SELECT DISTINCT
                                                 NVL(A.N_SOURCE_VERSION_SEQ_NUMBER_R,-1)       AS N_SOURCE_VERSION_SEQ_NUMBER_R
                                               , NVL(a.N_Claim_Sk_r,-1)                        AS N_Claim_Sk_r
                                               , NVL(a.n_claim_coverage_sk_r,-1)               AS n_claim_coverage_sk_r
                                               , NVL(a.N_TASK_SEQUENCE_R,-1)                   AS N_TASK_SEQUENCE_R
                                            FROM ( SELECT 
                                                            a.n_claim_sk_r                     AS N_CLAIM_SK_R
                                                          , a.V_ASSIGNMENT_ID_R                AS V_ASSIGNMENT_ID_R
                                                          , a.V_s_CREATED_BY_R                 AS V_S_CREATED_BY_R
                                                          , trunc(a.D_DUE_DATE_R  )            AS D_DUE_DATE_R
                                                          , a.N_PRIORITY_R                     AS N_PRIORITY_R
                                                          , a.N_SOURCE_VERSION_SEQ_NUMBER_R    AS N_SOURCE_VERSION_SEQ_NUMBER_R
                                                          , c.v_examiner_login_id_r            AS V_EXAMINER_LOGIN_ID_R
                                                          , e.n_claim_coverage_sk_r            AS N_CLAIM_COVERAGE_SK_R
                                                          , e.v_claim_coverage_code_r          AS V_CLAIM_COVERAGE_CODE_R
                                                          , b.n_policy_sk_r                    AS N_POLICY_SK_R
                                                          , a.N_TASK_SEQUENCE_R                AS N_TASK_SEQUENCE_R
                                                          , a.V_CELL_WORKER_ID_R               AS V_CELL_WORKER_ID_R
                                                     FROM ATOMIC.FCT_GRP_PROCESS_CUSTOM_R A
                                                        , ATOMIC.DIM_GRP_CLAIM_DIR_R B
                                                        , ATOMIC.DIM_GRP_CLAIM_DETAIL_R C
                                                        , ATOMIC.DIM_GRP_CLAIM_COVERAGE_R E
                                                    WHERE A.n_claim_sk_r <> - 1
                                                      AND E.V_CHANGE_REASON_R = 'Physically Deleted'
                                                      AND GREATEST(  COALESCE(a.t_last_modified_date_r, TO_DATE('1900-01-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS'))
                                                                    ,COALESCE(b.t_last_modified_date_r, TO_DATE('1900-01-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS'))
                                                                    ,COALESCE(c.t_last_modified_date_r, TO_DATE('1900-01-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS'))
                                                                    ,COALESCE(e.t_last_modified_date_r, TO_DATE('1900-01-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS'))
                                                                   ) >= ( SELECT max(END_DATE)
                                                                          FROM SSL_PACKAGE_MILESTONE_TABLE
                                                                          WHERE JOB_NAME='PKG_GRP_LOAD_RPT_CLAIM_TASK_R_INC'
                                                                         )
                                                      AND a.N_CLAIM_SK_R=B.N_CLAIM_SK_R
                                                      AND (B.v_active_status_r = 'Y' OR B.v_active_status_r = 'N')
                                                      AND a.N_CLAIM_SK_R=c.N_CLAIM_SK_R  AND C.v_active_status_r = 'N'
                                                      AND a.N_CLAIM_SK_R=e.N_CLAIM_SK_R  AND e.v_active_status_r = 'N'
                                                 ) a
                                            LEFT JOIN ATOMIC.dim_employee_r  d
                                                   ON d.v_employee_login_id_r = a.v_examiner_login_id_r
                                                  AND nvl(upper(d.v_business_unit_r),'CLAIMS') = 'CLAIMS'
                                            LEFT OUTER JOIN ATOMIC.mvw_product_sk_lookup  mv1
                                                         ON a.v_claim_coverage_code_r = mv1.v_claim_coverage_code_r
                                                        AND a.n_claim_sk_r = mv1.n_claim_sk_r
                                            LEFT OUTER JOIN ATOMIC.dim_grp_product_r     pd1
                                                         ON mv1.n_product_sk_r = pd1.n_product_sk_r
                                            LEFT JOIN ATOMIC.dim_grp_claim_coverage_group_r f
                                                   ON f.n_claim_coverage_sk_r = a.n_claim_coverage_sk_r
                                                  AND f.v_active_status_r = 'N'
                                            LEFT OUTER JOIN ATOMIC.mvw_product_sk_lookup mv2
                                                         ON f.v_claim_coverage_code_r = mv2.v_claim_coverage_code_r
                                                        AND f.n_claim_sk_r = mv2.n_claim_sk_r
                                            LEFT OUTER JOIN ATOMIC.dim_grp_product_r pd2
                                                         ON mv2.n_product_sk_r = pd2.n_product_sk_r
                                            LEFT JOIN ATOMIC.dim_grp_policy_dir_r g
                                                   ON a.n_policy_sk_r = g.n_policy_sk_r
                                                  AND g.v_active_status_r = 'N'
                                            LEFT JOIN ATOMIC.fct_grp_policy_r  h
                                                   ON g.n_policy_sk_r = h.n_policy_sk_r
                                                  AND g.n_policy_version_number_r = h.n_version_number_r
                                                  AND g.n_source_system_key_r = h.n_source_system_key_r
                                            LEFT JOIN ATOMIC.DIM_GRP_SYSUSESO_R ON UPPER(dim_grp_sysuseso_r.v_login_id_r) = UPPER(A.v_assignment_id_r )
                                            LEFT JOIN ATOMIC.DIM_GRP_SYSUSESO_R ON UPPER(dim_grp_sysuseso_r.v_login_id_r) = UPPER(A.v_s_created_by_r  )
                                            LEFT JOIN Atomic.Dim_Grp_Sysuseso_R ON UPPER(dim_grp_sysuseso_r.v_login_id_r) = UPPER(A.v_cell_worker_id_r)
                                            );