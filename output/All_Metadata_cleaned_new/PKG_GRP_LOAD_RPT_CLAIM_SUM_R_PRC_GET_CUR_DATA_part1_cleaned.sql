-- Cleaned for lineage: PKG_GRP_LOAD_RPT_CLAIM_SUM_R_PRC_GET_CUR_DATA (part 1/1)

INSERT  INTO RPT_CLAIM_SUM_R_EXG stg
    SELECT 
                    COALESCE(DGPR_1.n_product_sk_r, DGPR.n_product_sk_r, - 1)                             AS n_product_sk_r,
                    NVL(DER.n_employee_sk_r, - 1)                                                         AS n_employee_sk_r,
                    CAST(NULL AS NUMBER)                                                                  AS n_associated_wop_cnt_r,
                    NVL(FGWST.n_gross_benefit_r, FGWST_1.v_net_indicator_r)                               AS n_claim_gross_benefit_amount_r,
                    FGWST.n_rpt_net_benefit_r                                                             AS n_net_benefit_r,
                    CAST(NULL AS NUMBER)                                                                  AS n_claim_total_gross_amt_r,
                    CAST(NULL AS NUMBER)                                                                  AS n_claim_total_loss_amt_r,
                    CAST(NULL AS NUMBER)                                                                  AS n_claim_total_net_amt_r,
                    CAST(NULL AS NUMBER)                                                                  AS n_claim_total_tax_amt_r,
                    CAST(NULL AS NUMBER)                                                                  AS n_claim_total_paid_amt_r,
                    CAST(NULL AS NUMBER)                                                                  AS n_current_face_amount_r,
                    CAST(NULL AS NUMBER)                                                                  AS n_est_loss_amount_r,
                    CAST(NULL AS NUMBER)                                                                  AS n_most_recent_gross_amount_r,
                    CAST(NULL AS NUMBER)                                                                  AS n_most_recent_net_amt_r,
                    CAST(NULL AS NUMBER)                                                                  AS n_most_recent_tax_amt_r,
                    DGCCGR.n_reserve_amount_r                                                             AS n_original_face_amount_r,
                    DGCCR.n_reinsurance_pct_r                                                             AS n_reinsurance_value_r,
                    FCSIR.n_ss_dep_award_amount_r                                                         AS n_ss_dep_award_amount_r,
                    FCSIR.n_ss_est_monthly_benefit_r                                                      AS n_ss_est_monthly_benefit_r,
                    FCSIR.n_ss_primary_award_amount_r                                                     AS n_ss_primary_award_amount_r,
                    FCSIR.n_ss_hardship_ind_r                                                             AS n_ss_hardship_ind_r,
                    gv_main_loadedby                                                                      AS v_last_modified_by_r,
                    systimestamp                                                                          AS t_creation_date_r,
                    gv_main_loadedby                                                                      AS v_created_by_r,
                    systimestamp                                                                          AS t_last_modified_date_r,
                    gn_current_month                                                                      AS n_yearmonth_r,
                    DGCDR.v_active_status_r                                                               AS v_rpt_active_status_r,
                    gn_sysdt_batchid                                                                      AS n_batch_id_r,
                    - 1                                                                                   AS n_worksheet_sk_r,
                    NVL(FGPRMS.n_cust_party_sk_r, - 1)                                                    AS n_cust_party_sk_r,
                    NVL(DGCR.n_insrd_party_sk_r, - 1)                                                     AS n_insrd_party_sk_r,
                    NVL(DGCCGR.n_claim_coverage_group_sk_r, - 1)                                          AS n_claim_coverage_group_sk_r,
                    NVL(DGCCR.n_claim_coverage_sk_r, - 1)                                                 AS n_claim_coverage_sk_r,
                    NVL(DGCDR.n_claim_sk_r, - 1)                                                          AS n_claim_sk_r,
                    NVL(DGCDR.n_policy_sk_r, - 1)                                                         AS n_policy_sk_r,
                    CAST(NULL AS NUMBER)                                                                  AS n_claim_closed_date_sk_r,
                    CAST(NULL AS NUMBER)                                                                  AS n_loss_date_sk_r,
                    CAST(NULL AS NUMBER)                                                                  AS n_claim_received_date_sk_r,
                    CAST(NULL AS NUMBER)                                                                  AS n_policy_id_r,
                    DGCR.d_closure_date_r                                                                 AS d_closure_date_r,
                    DGCR.d_date_of_loss_r                                                                 AS d_date_of_loss_r,
                    DGBARM.received_date                                                                  AS d_received_date_r,
                    DGCDR.v_lob_type_r                                                                    AS v_lob_type_r,
                    DGCCGR.n_ws_released_amount_r                                                         AS n_ws_released_amount_r,
                    CAST(NULL AS NUMBER)                                                                  AS n_curr_best_estimate_reserve_r,
                    CAST(NULL AS NUMBER)                                                                  AS n_curr_gaap_reserve_r,
                    CAST(NULL AS NUMBER)                                                                  AS n_curr_stat_reserve_r,
                    CAST(NULL AS NUMBER)                                                                  AS n_curr_field_reserve_r,
                    CAST(NULL AS DATE)                                                                    AS d_most_recent_reserve_valuation_date_r,
                    CAST(NULL AS NUMBER)                                                                  AS n_claim_mtd_loss_amt_r,
                    CAST(NULL AS NUMBER)                                                                  AS n_claim_qtd_loss_amt_r,
                    CAST(NULL AS NUMBER)                                                                  AS n_claim_ytd_loss_amt_r,
                    CAST(NULL AS NUMBER)                                                                  AS n_current_reserve_r,
					gd_mis_date_be 						                                                  AS BE_AND_FIELD_MOST_RECENT_AS_OF_DATE
                FROM
                    ( SELECT n_claim_sk_r
                           , n_policy_sk_r
                           , v_lob_type_r
                           , v_claim_number_r
                           , v_active_status_r
                        FROM ATOMIC.DIM_GRP_CLAIM_DIR_R
                       WHERE v_active_status_r = 'Y'
                    )  DGCDR
                    LEFT JOIN ATOMIC.DIM_GRP_CLAIM_COVERAGE_R DGCCR
                           ON DGCDR.n_claim_sk_r = DGCCR.n_claim_sk_r
                          AND DGCCR.v_active_status_r = 'Y'
                    LEFT JOIN ATOMIC.DIM_GRP_CLAIM_COVERAGE_GROUP_R DGCCGR
                           ON DGCCR.n_claim_coverage_sk_r = DGCCGR.n_claim_coverage_sk_r
                          AND DGCCGR.v_active_status_r    = 'Y'
                    LEFT JOIN ATOMIC.DIM_GRP_POLICY_DIR_R DGPDR
                           ON DGCDR.n_policy_sk_r = DGPDR.n_policy_sk_r
                          AND DGPDR.v_active_status_r = 'Y'
                    LEFT JOIN ATOMIC.DIM_GRP_CLAIM_DETAIL_R  DGCR
                           ON DGCDR.n_claim_sk_r = DGCR.n_claim_sk_r
                          AND DGCR.v_active_status_r = 'Y'
                    LEFT JOIN ATOMIC.DIM_EMPLOYEE_R DER
                           ON DGCR.v_examiner_login_id_r = DER.v_employee_login_id_r
                          AND DER.v_business_unit_r = 'Claims'
                    LEFT JOIN ATOMIC.FCT_GRP_POLICY_R_MV_SSL FGPRMS
                           ON DGPDR.n_policy_sk_r = FGPRMS.n_policy_sk_r
                          AND DGPDR.n_policy_version_number_r = FGPRMS.n_version_number_r
                    LEFT JOIN ATOMIC.FCT_CLAIM_SOCIALSECURITY_INC_R FCSIR
                           ON DGCDR.n_claim_sk_r = FCSIR.n_claim_sk_r
                    LEFT JOIN ATOMIC.MVW_PRODUCT_SK_LOOKUP_MIN_MV_SSL MPSLMMS
                           ON MPSLMMS.n_claim_sk_r = DGCDR.n_claim_sk_r
                          AND MPSLMMS.v_claim_coverage_code_r = DGCCR.v_claim_coverage_code_r
                    LEFT JOIN ATOMIC.DIM_GRP_PRODUCT_R DGPR
                           ON MPSLMMS.n_product_sk_r = DGPR.n_product_sk_r
                    LEFT JOIN ATOMIC.MVW_PRODUCT_SK_LOOKUP_MIN_MV_SSL MPSLMMS_1
                           ON MPSLMMS_1.n_claim_sk_r = DGCDR.n_claim_sk_r
                          AND MPSLMMS_1.v_claim_coverage_code_r = DGCCGR.v_claim_coverage_code_r
                    LEFT JOIN ATOMIC.DIM_GRP_PRODUCT_R DGPR_1
                           ON DGPR_1.n_product_sk_r = MPSLMMS_1.n_product_sk_r
                    LEFT JOIN ATOMIC.FCT_GRP_WORKSHEET FGWST
                           ON FGWST.n_claim_sk_r = DGCDR.n_claim_sk_r
                          AND FGWST.n_claim_coverage_sk_r = DGCCR.n_claim_coverage_sk_r
                          AND FGWST.v_rpt_worksheet_indicator_r = 'Y'
                    LEFT JOIN ( SELECT n_claim_sk_r                                  AS n_claim_sk_r
                                     , n_claim_coverage_group_sk_r                   AS n_claim_coverage_group_sk_r
                                     , SUM(CAST(v_net_indicator_r AS NUMBER(20, 5))) AS v_net_indicator_r
                                     , v_source_system_name_r                        AS v_source_system_name_r
                                 FROM ATOMIC.FCT_GRP_WORKSHEET
                                WHERE v_source_system_name_r = 'CV'
                                GROUP BY n_claim_sk_r
                                       , n_claim_coverage_group_sk_r
                                       , v_source_system_name_r
                               ) FGWST_1
                           ON FGWST_1.n_claim_sk_r = DGCDR.n_claim_sk_r
                          AND FGWST_1.n_claim_coverage_group_sk_r = DGCCGR.n_claim_coverage_group_sk_r
                    LEFT JOIN ATOMIC.DIM_GRP_BUSOBJ_AUDIT_R_MAX_RCV_MV_SSL DGBARM
                           ON DGBARM.v_claim_number_r = DGCDR.v_claim_number_r;