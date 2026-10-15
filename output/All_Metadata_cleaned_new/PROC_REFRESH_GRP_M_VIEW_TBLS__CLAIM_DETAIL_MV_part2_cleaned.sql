-- Cleaned for lineage: PROC_REFRESH_GRP_M_VIEW_TBLS__CLAIM_DETAIL_MV (part 2/3)

INSERT  INTO CLAIM_DETAIL_MV_TBL (
		 V_CLAIM_NUMBER_R
		,N_CLAIM_SK_R
		,V_SOURCE_SYSTEM_NAME_R
		,N_POLICY_SK_R
		,V_LOB_TYPE_R
		,D_DATE_OF_CONTRACT_R
		,V_COMPANY_R
		,N_SOURCE_SYSTEM_KEY_R
		,V_PRIVACY_INDICATOR_R
		,V_CLAIM_IDENTIFIER_R
		,V_CLAIM_STATUS_CODE_R
		,V_REASON_CODE_R
		,V_COV_GRP_CODE_R
		,V_ACTIVE_STATUS_R_COVGRP
		,D_AGE_REDUCTION_DATE_R
		,V_CLASS_ID_R_COVGRP
		,D_DATE_CLOSED_R
		,V_CLAIM_COVERAGE_CODE_R_COVGRP
		,V_CLAIM_COVERAGE_CODE_R
		,N_RESERVE_AMOUNT_R
		,N_WS_RELEASED_AMOUNT_R
		,N_COV_GRP_ID_R
		,N_BATCH_ID_R
		,N_CLAIM_COVERAGE_GROUP_SK_R
		,V_ACTIVE_STATUS_R_COV
		,V_CLASS_ID_R_COV_R
		,V_COVERAGE_STATUS_R
		,N_REINSURANCE_AMOUNT_R
		,N_REINSURANCE_PCT_R
		,V_CLAIM_COVERAGE_CODE_R_COV
		,N_CLAIM_COVERAGE_SK_R
		,V_EXAMINER_LOGIN_ID_R
		,V_EXAMINER_DESC_R
		,D_CLOSURE_DATE_R
		,V_CLAIM_STATUS_REASON_CODE_R
		,V_EXERTION_LEVEL_R
		,D_DATE_OF_EVENT_R
		,D_DATE_OF_LOSS_R
		,D_RETURN_TO_MOD_WKDT_R
		,V_CHILD_GENDER_R
		,D_PFL_DOB_R
		,V_MANDATED_FAMILY_MEMBER_R
		,V_LEAVE_REASON_R
		,D_PFL_DOP_R
		,D_RETURN_TO_WORK_DATE_R
		,N_INSRD_PARTY_SK_R
		,N_PRODUCT_SK_R
		,RANK
		,N_CLAIM_CVRG_SEQUENCE_NUMBER_R
		,D_DIAGNOSIS_DURATION_DATE_R
		,N_DIAGNOSIS_DURATION_PERIOD_R
		,V_DIAGNOSIS_CODE_R
		,V_DIAGNOSIS_DESC_R
		,N_PRIMARY_IND_R
		,N_DIAGNOSIS_TYPE_CODE_R
		,V_ORIGINAL_DIAG_LOOKUP_R
		,V_NEW_DIAG_LOOKUP_R
		,D_ANYOCC_DATE_R
		,D_ANYOCC_START_DATE_R
		,V_BENEFIT_DURATION_R
		,V_BENEFIT_DURATION_OTHER_R
		,V_DISABILITY_DATE_STATUS_R
		,N_ELIM_PERIOD_R
		,N_ELIM_PERIOD_ACC_R
		,V_ELIM_PERIOD_IND_R
		,N_ELIM_PERIOD_SICK_R
		,D_PLAN_DUR_DATE_R
		,D_WAIVER_TERMINATION_DATE_R
		,N_WAIVER_TERMINATION_AGE_R
		,N_BENEFIT_AMOUNT_R
		,V_BENEFIT_FREQUENCY_R
		,N_BENEFIT_PERCENT_R
		,D_BENEFIT_START_R
		,N_COLA_ACCUM_VALUE_R
		,N_COLA_BENEFIT_R
		,N_GROSS_BENEFIT_R
		,N_MINIMUM_BENEFIT_R
		,N_MAX_BENEFIT_R
		,N_SPEC_BENEFIT_ADJUST_R
		,N_RPT_NET_BENEFIT_R
		,V_DC_TIMESTAMP_R
		,V_BUSINESS_OBJECT_ID_R
		,V_SUBGROUP_ID_R
		,V_CORRESPONDENT_NAME_R
		,V_SUBGROUP_NAME_R
		,V_SUBGROUP_ADDRESSLINE1_R
		,V_SUBGROUP_ADDRESSLINE2_R
		,V_SUBGROUP_POSTALZIP_R
		,V_SUBGROUP_PROVSTATE_R
		,V_SUBGROUP_CITY_R
		,D_RECEIVED_DATE_R
		,D_HIRE_DATE_R
		,V_EEOC_CODE_R
		,N_BASIC_INSURED_SALARY_R
		,V_BASIC_INSURED_SALARY_IND_R
		,V_DESCRIPTION_R
		,N_SS_DEP_AWARD_AMOUNT_R
		,D_SS_DEP_AWARD_EFF_DATE_R
		,D_SS_DEP_TERM_DATE_R
		,V_SS_DEP_AWARD_TYPE_R
		,V_SS_DEP_PURSUE_FLAG_R
		,V_SS_DEPENDENT_STATUS_R
		,D_CHANGE_DATE_R
		,D_SS_CLOSED_TERM_DATE_R
		,D_SS_PRIMARY_EFF_DATE_R
		,N_SS_PRIMARY_AWARD_AMOUNT_R
		,V_SS_PRIMARY_AWARD_TYPE_R
		,N_SS_EST_MONTHLY_BENEFIT_R
		,V_SS_PURSUE_FLAG_R
		,V_SS_REJECT_REASON_R
		,V_SS_STATUS_DESCRIPTION_R
		,V_CURR_PRIMARY_DIAG_CODE_R
		,V_CURR_PRIMARY_DIAG_CAT_DESC_R
		,V_CURR_PRIMARY_DIAG_DESC_R
		,V_PRIOR_PRIMARY_DIAG_CODE_R
		,V_PRIOR_PRIMARY_DIAG_DESC_R
		,D_PRIMARY_DIAG_EFF_DATE_R
		,V_PRIMARY_DIAG_ACTIVE_STATUS_R
		,N_CURR_ELIMINATION_PERIOD_R
		,N_PRIOR_ELIMINATION_PERIOD_R
		,D_ELIMINATION_EFF_DATE_R
		,V_CURR_CLAIM_CAUSE_OF_EVENT_R
		,V_PRIOR_CLAIM_CAUSE_OF_EVENT_R
		,V_CURR_DURATION_R
		,V_CURR_DURATION_IND_R
		,V_PRIOR_DURATION_R
		,V_PRIOR_DURATION_IND_R
		,D_DURATION_EFF_DATE_R
		,D_CURR_LOSS_DATE_R
		,D_PRIOR_LOSS_DATE_R
		,D_LOSS_DATE_EFF_DATE_R
		,N_CURR_GROSS_BEN_AMT_R
		,N_PRIOR_GROSS_BEN_AMT_R
		,D_GROSS_BEN_EFF_DATE_R
		,N_CURR_CHECK_NET_BEN_AMT_R
		,N_PRIOR_CHECK_NET_BEN_AMT_R
		,D_CHECK_NET_BEN_EFF_DATE_R
		,V_CURR_CLAIM_STATUS_CODE_R
		,V_PRIOR_CLAIM_STATUS_CODE_R
		,D_CLAIM_STATUS_CODE_EFF_DATE_R
		,V_CURR_CLAIM_CLOSURE_CODE_R
		,V_PRIOR_CLAIM_CLOSURE_CODE_R
		,D_LAST_IN_STATUS_46_DATE_R
		,N_PRIOR_STATUS_BATCH_R
		,N_CLAIM_EVENT_SK_R
		,N_MODAL_AMOUNT_R
		,N_SS_HARDSHIP_IND_R
		)
        SELECT DISTINCT
            *
        FROM
            (
                SELECT
                    a.v_claim_number_r,
                    a.n_claim_sk_r,
                    a.v_source_system_name_r,
                    a.n_policy_sk_r,
                    a.v_lob_type_r,
                    a.d_date_of_contract_r,
                    a.v_company_r,
                    a.n_source_system_key_r,
                    a.v_privacy_indicator_r,
                    nvl(c.v_claim_identifier_r, a.v_claim_number_r) v_claim_identifier_r,
                    c.v_reason_code_r                               claim_status_code,
                    c.v_reason_code_r,
                    c.v_cov_grp_code_r,
                    c.v_active_status_r                             v_active_status_r_covgrp,
                    c.d_age_reduction_date_r,
                    c.v_class_id_r                                  v_class_id_r_covgrp,
                    c.d_date_closed_r,
                    c.v_claim_coverage_code_r                       v_claim_coverage_code_r_covgrp,
                    c.v_claim_coverage_code_r                       v_claim_coverage_code_r,
                    c.n_reserve_amount_r,
                    c.n_ws_released_amount_r,
                    c.n_cov_grp_id_r,
                    c.n_batch_id_r,
                    c.n_claim_coverage_group_sk_r,
                    b.v_active_status_r                             v_active_status_r_cov,
                    b.v_class_id_r                                  v_class_id_r_cov,
                    b.v_coverage_status_r,
                    b.n_reinsurance_amount_r,
                    b.n_reinsurance_pct_r,
                    b.v_claim_coverage_code_r                       v_claim_coverage_code_r_cov,
                    b.n_claim_coverage_sk_r,
                    d.v_examiner_login_id_r,
                    d.v_examiner_desc_r,
                    d.d_closure_date_r,
                    d.v_claim_status_reason_code_r,
                    d.v_exertion_level_r,
                    d.d_date_of_event_r,
                    d.d_date_of_loss_r,
                    d.d_return_to_mod_wkdt_r,
                    d.v_child_gender_r,
                    d.d_pfl_dob_r,
                    d.v_mandated_family_member_r,
                    d.v_leave_reason_r,
                    d.d_pfl_dop_r,
                    d.d_return_to_work_date_r,
                    d.n_insrd_party_sk_r,
                    e.n_product_sk_r,
                    RANK()
                    OVER(PARTITION BY b.n_claim_sk_r
                         ORDER BY
                             nvl(b.n_claim_cvrg_sequence_number_r, 0) DESC
                    )                                               rank,
                    b.n_claim_cvrg_sequence_number_r,
                    f.d_diagnosis_duration_date_r,
                    f.n_diagnosis_duration_period_r,
                    f.v_diagnosis_code_r,
                    f.v_diagnosis_desc_r,
                    f.n_primary_ind_r,
                    f.n_diagnosis_type_code_r,
                    f.original_diag_lookup,
                    f.new_diag_lookup,
                    g.d_anyocc_date_r,
                    g.d_anyocc_start_date_r,
                    g.v_benefit_duration_r,
                    g.v_benefit_duration_other_r,
                    g.v_disability_date_status_r,
                    g.n_elim_period_r,
                    g.n_elim_period_acc_r,
                    g.v_elim_period_ind_r,
                    g.n_elim_period_sick_r,
                    g.d_plan_dur_date_r,
                    g.d_waiver_termination_date_r,
                    g.n_waiver_termination_age_r,
                    h.n_benefit_amount_r,
                    h.v_benefit_frequency_r,
                    h.n_benefit_percent_r,
                    h.d_benefit_start_r,
                    h.n_cola_accum_value_r,
                    h.n_cola_benefit_r,
                    h.n_gross_benefit_r,
                    h.n_minimum_benefit_r,
                    h.n_max_benefit_r,
                    h.n_spec_benefit_adjust_r,
                    h.n_rpt_net_benefit_r,
                    j.v_dc_timestamp_r,
                    j.v_business_object_id_r,
                    k.v_subgroup_id_r,
                    k.v_correspondent_name_r,
                    k.v_subgroup_name_r,
                    k.v_subgroup_addressline1_r,
                    k.v_subgroup_addressline2_r,
                    k.v_subgroup_postalzip_r,
                    k.v_subgroup_provstate_r,
                    k.v_subgroup_city_r,
                    l.received_date,
                    m.d_hire_date_r,
                    m.v_eeoc_code_r,
                    m.n_basic_insured_salary_r,
                    m.v_basic_insured_salary_ind_r,
                    n.v_description_r,
                    o.n_ss_dep_award_amount_r,
                    o.d_ss_dep_award_eff_date_r,
                    o.d_ss_dep_term_date_r,
                    o.v_ss_dep_award_type_r,
                    o.v_ss_dep_pursue_flag_r,
                    o.v_ss_dependent_status_r,
                    o.d_change_date_r,
                    o.d_ss_closed_term_date_r,
                    o.d_ss_primary_eff_date_r,
                    o.n_ss_primary_award_amount_r,
                    o.v_ss_primary_award_type_r,
                    o.n_ss_est_monthly_benefit_r,
                    o.v_ss_pursue_flag_r,
                    o.v_ss_reject_reason_r,
                    o.v_ss_status_description_r,
                    p.v_curr_primary_diag_code_r,
                    p.v_curr_primary_diag_cat_desc_r,
                    p.v_curr_primary_diag_desc_r,
                    p.v_prior_primary_diag_code_r,
                    p.v_prior_primary_diag_desc_r,
                    p.d_primary_diag_eff_date_r,
                    p.v_primary_diag_active_status_r,
                    p.n_curr_elimination_period_r,
                    p.n_prior_elimination_period_r,
                    p.d_elimination_eff_date_r,
                    p.v_curr_claim_cause_of_event_r,
                    p.v_prior_claim_cause_of_event_r,
                    p.v_curr_duration_r,
                    p.v_curr_duration_ind_r,
                    p.v_prior_duration_r,
                    p.v_prior_duration_ind_r,
                    p.d_duration_eff_date_r,
                    p.d_curr_loss_date_r,
                    p.d_prior_loss_date_r,
                    p.d_loss_date_eff_date_r,
                    p.n_curr_gross_ben_amt_r,
                    p.n_prior_gross_ben_amt_r,
                    p.d_gross_ben_eff_date_r,
                    p.n_curr_check_net_ben_amt_r,
                    p.n_prior_check_net_ben_amt_r,
                    p.d_check_net_ben_eff_date_r,
                    p.v_curr_claim_status_code_r,
                    p.v_prior_claim_status_code_r,
                    p.d_claim_status_code_eff_date_r,
                    p.v_curr_claim_closure_code_r,
                    p.v_prior_claim_closure_code_r,
                    p.d_last_in_status_46_date_r,
                    p.n_batch_id_r                                  prior_status_batch,
                    m.n_claim_event_sk_r,
                    h.n_modal_amount_r,
					    o.N_SS_HARDSHIP_IND_R
                FROM
                         dim_grp_claim_dir_r a
                    INNER JOIN dim_grp_claim_detail_r               d ON a.n_claim_sk_r = d.n_claim_sk_r
                    INNER JOIN dim_grp_claim_coverage_r             b ON a.n_claim_sk_r = b.n_claim_sk_r
                    LEFT JOIN dim_grp_claim_coverage_group_r       c ON b.n_claim_coverage_sk_r = c.n_claim_coverage_sk_r
                                                                  AND c.v_active_status_r = 'Y'
                    LEFT OUTER JOIN mvw_product_sk_lookup                e ON a.n_claim_sk_r = e.n_claim_sk_r
                                                               AND c.v_claim_coverage_code_r = e.v_claim_coverage_code_r
                    LEFT JOIN dim_grp_medical_diagnosis_r          f ON f.n_claim_sk_r = a.n_claim_sk_r
                                                               AND TRIM(f.v_active_status_r) = 'Y'
                                                               AND TRIM(f.n_primary_ind_r) = '1'
                    LEFT JOIN dim_grp_claim_eligibility_r          g ON g.n_claim_coverage_sk_r = CASE
                                                                                                 WHEN g.n_claim_coverage_sk_r <> - 1 THEN
                                                                                                     b.n_claim_coverage_sk_r
                                                                                                 ELSE
                                                                                                     - 1
                                                                                             END
                                                               AND g.n_claim_sk_r = a.n_claim_sk_r
                                                               AND g.v_active_status_r = 'Y'
                    LEFT JOIN fct_grp_worksheet                    h ON c.n_claim_coverage_group_sk_r = h.n_claim_coverage_group_sk_r
                                                     AND h.n_claim_sk_r = a.n_claim_sk_r
                                                     AND h.v_rpt_worksheet_indicator_r = 'Y' 
                    LEFT JOIN (
                        SELECT
                            *
                        FROM
                            fct_grp_transactions_r
                        WHERE
                            n_claim_sk_r <> - 1
                    )                                    j ON j.n_claim_sk_r = a.n_claim_sk_r
                    LEFT JOIN dim_grp_claim_detail_subgroup_lookup k ON k.v_claim_number_r = a.v_claim_number_r
                    LEFT OUTER JOIN (
                        SELECT
                            ba.v_claim_number_r,
                            MAX(nvl(ba.d_received_date_r,
                                    TO_DATE(substr(ba.v_claim_number_r, 1, 10),
                                            'YYYY-MM-DD'))) AS received_date
                        FROM
                            dim_grp_busobj_audit_r ba
                        WHERE
                                ba.v_active_status_r = 'Y'
                            AND ba.v_claim_number_r NOT IN ( '-LIFE-01', '-LTD-01', '-STD-01', '-VPS-01', '-WOP-01' )
                        GROUP BY
                            ba.v_claim_number_r
                    )                                    l ON a.v_claim_number_r = l.v_claim_number_r
                    LEFT JOIN dim_grp_claim_event_r                m ON m.n_claim_event_sk_r = d.n_claim_event_sk_r
                                                         AND m.v_active_status_r = 'Y'
                    LEFT JOIN dim_grp_eeoc_r                       n ON n.v_code_r = m.v_eeoc_code_r
                    LEFT JOIN fct_claim_socialsecurity_inc_r       o ON o.n_claim_sk_r = a.n_claim_sk_r
                    LEFT JOIN vw_dim_grp_claim_prior_status_r      p ON p.v_coverage_group_code_r = c.v_coverage_code_r
                                                                   AND p.n_cov_grp_id_r = c.n_cov_grp_id_r
                                                                   AND p.n_claim_sk_r = a.n_claim_sk_r
                WHERE
                        a.v_active_status_r = 'Y'
                    AND a.v_lob_type_r IN ( 'LIFE', 'NONS', 'WOP' )
                    AND b.v_active_status_r = 'Y'
                    AND d.v_active_status_r = 'Y'
                UNION
                SELECT
                    a.v_claim_number_r,
                    a.n_claim_sk_r,
                    a.v_source_system_name_r,
                    a.n_policy_sk_r,
                    a.v_lob_type_r,
                    a.d_date_of_contract_r,
                    a.v_company_r,
                    a.n_source_system_key_r,
                    a.v_privacy_indicator_r,
                    nvl(c.v_claim_identifier_r, a.v_claim_number_r) v_claim_identifier_r,
                    CASE
                        WHEN d.v_claim_status_reason_code_r IS NULL THEN
                                CASE
                                    WHEN upper(b.v_coverage_status_r) = 'PENDING'  THEN
                                        '22'
                                    WHEN upper(b.v_coverage_status_r) = 'APPROVED' THEN
                                        '32'
                                    WHEN upper(b.v_coverage_status_r) = 'CLOSED'   THEN
                                        '60'
                                    ELSE
                                        d.v_claim_status_reason_code_r
                                END
                        ELSE
                            d.v_claim_status_reason_code_r
                    END                                             AS claim_status_code,
                    c.v_reason_code_r,
                    c.v_cov_grp_code_r,
                    c.v_active_status_r                             v_active_status_r_covgrp,
                    c.d_age_reduction_date_r,
                    c.v_class_id_r                                  v_class_id_r_covgrp,
                    c.d_date_closed_r,
                    c.v_claim_coverage_code_r                       v_claim_coverage_code_r_covgrp,
                    b.v_claim_coverage_code_r                       v_claim_coverage_code_r,
                    c.n_reserve_amount_r,
                    c.n_ws_released_amount_r,
                    c.n_cov_grp_id_r,
                    c.n_batch_id_r,
                    c.n_claim_coverage_group_sk_r,
                    b.v_active_status_r                             v_active_status_r_cov,
                    b.v_class_id_r                                  v_class_id_r_cov,
                    b.v_coverage_status_r,
                    b.n_reinsurance_amount_r,
                    b.n_reinsurance_pct_r,
                    b.v_claim_coverage_code_r                       v_claim_coverage_code_r_cov,
                    b.n_claim_coverage_sk_r,
                    d.v_examiner_login_id_r,
                    d.v_examiner_desc_r,
                    d.d_closure_date_r,
                    d.v_claim_status_reason_code_r,
                    d.v_exertion_level_r,
                    d.d_date_of_event_r,
                    d.d_date_of_loss_r,
                    d.d_return_to_mod_wkdt_r,
                    d.v_child_gender_r,
                    d.d_pfl_dob_r,
                    d.v_mandated_family_member_r,
                    d.v_leave_reason_r,
                    d.d_pfl_dop_r,
                    d.d_return_to_work_date_r,
                    d.n_insrd_party_sk_r,
                    e.n_product_sk_r,
                    RANK()
                    OVER(PARTITION BY b.n_claim_sk_r
                         ORDER BY
                             nvl(b.n_claim_cvrg_sequence_number_r, 0) DESC
                    )                                               rank,
                    b.n_claim_cvrg_sequence_number_r,
                    f.d_diagnosis_duration_date_r,
                    f.n_diagnosis_duration_period_r,
                    f.v_diagnosis_code_r,
                    f.v_diagnosis_desc_r,
                    f.n_primary_ind_r,
                    f.n_diagnosis_type_code_r,
                    f.original_diag_lookup,
                    f.new_diag_lookup,
                    g.d_anyocc_date_r,
                    g.d_anyocc_start_date_r,
                    g.v_benefit_duration_r,
                    g.v_benefit_duration_other_r,
                    g.v_disability_date_status_r,
                    g.n_elim_period_r,
                    g.n_elim_period_acc_r,
                    g.v_elim_period_ind_r,
                    g.n_elim_period_sick_r,
                    g.d_plan_dur_date_r,
                    g.d_waiver_termination_date_r,
                    g.n_waiver_termination_age_r,
                    i.n_benefit_amount_r,
                    i.v_benefit_frequency_r,
                    i.n_benefit_percent_r,
                    i.d_benefit_start_r,
                    i.n_cola_accum_value_r,
                    i.n_cola_benefit_r,
                    i.n_gross_benefit_r,
                    i.n_minimum_benefit_r,
                    i.n_max_benefit_r,
                    i.n_spec_benefit_adjust_r,
                    i.n_rpt_net_benefit_r,
                    j.v_dc_timestamp_r,
                    j.v_business_object_id_r,
                    k.v_subgroup_id_r,
                    k.v_correspondent_name_r,
                    k.v_subgroup_name_r,
                    k.v_subgroup_addressline1_r,
                    k.v_subgroup_addressline2_r,
                    k.v_subgroup_postalzip_r,
                    k.v_subgroup_provstate_r,
                    k.v_subgroup_city_r,
                    l.received_date,
                    m.d_hire_date_r,
                    m.v_eeoc_code_r,
                    m.n_basic_insured_salary_r,
                    m.v_basic_insured_salary_ind_r,
                    n.v_description_r,
                    o.n_ss_dep_award_amount_r,
                    o.d_ss_dep_award_eff_date_r,
                    o.d_ss_dep_term_date_r,
                    o.v_ss_dep_award_type_r,
                    o.v_ss_dep_pursue_flag_r,
                    o.v_ss_dependent_status_r,
                    o.d_change_date_r,
                    o.d_ss_closed_term_date_r,
                    o.d_ss_primary_eff_date_r,
                    o.n_ss_primary_award_amount_r,
                    o.v_ss_primary_award_type_r,
                    o.n_ss_est_monthly_benefit_r,
                    o.v_ss_pursue_flag_r,
                    o.v_ss_reject_reason_r,
                    o.v_ss_status_description_r,
                    p.v_curr_primary_diag_code_r,
                    p.v_curr_primary_diag_cat_desc_r,
                    p.v_curr_primary_diag_desc_r,
                    p.v_prior_primary_diag_code_r,
                    p.v_prior_primary_diag_desc_r,
                    p.d_primary_diag_eff_date_r,
                    p.v_primary_diag_active_status_r,
                    p.n_curr_elimination_period_r,
                    p.n_prior_elimination_period_r,
                    p.d_elimination_eff_date_r,
                    p.v_curr_claim_cause_of_event_r,
                    p.v_prior_claim_cause_of_event_r,
                    p.v_curr_duration_r,
                    p.v_curr_duration_ind_r,
                    p.v_prior_duration_r,
                    p.v_prior_duration_ind_r,
                    p.d_duration_eff_date_r,
                    p.d_curr_loss_date_r,
                    p.d_prior_loss_date_r,
                    p.d_loss_date_eff_date_r,
                    p.n_curr_gross_ben_amt_r,
                    p.n_prior_gross_ben_amt_r,
                    p.d_gross_ben_eff_date_r,
                    p.n_curr_check_net_ben_amt_r,
                    p.n_prior_check_net_ben_amt_r,
                    p.d_check_net_ben_eff_date_r,
                    p.v_curr_claim_status_code_r,
                    p.v_prior_claim_status_code_r,
                    p.d_claim_status_code_eff_date_r,
                    p.v_curr_claim_closure_code_r,
                    p.v_prior_claim_closure_code_r,
                    p.d_last_in_status_46_date_r,
                    p.n_batch_id_r                                  prior_status_batch,
                     m.n_claim_event_sk_r,
                      i.n_modal_amount_r,
					    o.N_SS_HARDSHIP_IND_R
                FROM
                         dim_grp_claim_dir_r a
                    INNER JOIN dim_grp_claim_detail_r               d ON a.n_claim_sk_r = d.n_claim_sk_r
                    INNER JOIN dim_grp_claim_coverage_r             b ON a.n_claim_sk_r = b.n_claim_sk_r
                    LEFT JOIN dim_grp_claim_coverage_group_r       c ON b.n_claim_coverage_sk_r = c.n_claim_coverage_sk_r
                                                                  AND c.v_active_status_r = 'Y'
                    LEFT OUTER JOIN (
                        SELECT
                            MIN(n_product_sk_r) n_product_sk_r,
                            n_claim_sk_r,
                            v_claim_coverage_code_r
                        FROM
                            mvw_product_sk_lookup
                        GROUP BY
                            n_claim_sk_r,
                            v_claim_coverage_code_r
                    )                                    e ON a.n_claim_sk_r = e.n_claim_sk_r
                           AND b.v_claim_coverage_code_r = e.v_claim_coverage_code_r
                    LEFT JOIN dim_grp_medical_diagnosis_r          f ON f.n_claim_sk_r = a.n_claim_sk_r
                                                               AND TRIM(f.v_active_status_r) = 'Y'
                                                               AND TRIM(f.n_primary_ind_r) = '1'
                    LEFT JOIN dim_grp_claim_eligibility_r          g ON g.n_claim_coverage_sk_r = CASE
                                                                                                 WHEN g.n_claim_coverage_sk_r <> - 1 THEN
                                                                                                     b.n_claim_coverage_sk_r
                                                                                                 ELSE
                                                                                                     - 1
                                                                                             END
                                                               AND g.n_claim_sk_r = a.n_claim_sk_r
                                                               AND g.v_active_status_r = 'Y'
                    LEFT JOIN fct_grp_worksheet                    i ON i.n_claim_coverage_sk_r = b.n_claim_coverage_sk_r
                                                     AND i.n_claim_sk_r = a.n_claim_sk_r
                                                     AND i.v_rpt_worksheet_indicator_r = 'Y'
                    LEFT JOIN (
                        SELECT
                            *
                        FROM
                            fct_grp_transactions_r
                        WHERE
                            n_claim_sk_r <> - 1
                    )                                    j ON j.n_claim_sk_r = a.n_claim_sk_r
                    LEFT JOIN dim_grp_claim_detail_subgroup_lookup k ON k.v_claim_number_r = a.v_claim_number_r
                    LEFT OUTER JOIN (
                        SELECT
                            ba.v_claim_number_r,
                            MAX(nvl(ba.d_received_date_r,
                                    TO_DATE(substr(ba.v_claim_number_r, 1, 10),
                                            'YYYY-MM-DD'))) AS received_date
                        FROM
                            dim_grp_busobj_audit_r ba
                        WHERE
                                ba.v_active_status_r = 'Y'
                            AND ba.v_claim_number_r NOT IN ( '-LIFE-01', '-LTD-01', '-STD-01', '-VPS-01', '-WOP-01' )
                        GROUP BY
                            ba.v_claim_number_r
                    )                                    l ON a.v_claim_number_r = l.v_claim_number_r
                    LEFT JOIN dim_grp_claim_event_r                m ON m.n_claim_event_sk_r = d.n_claim_event_sk_r
                                                         AND m.v_active_status_r = 'Y'
                    LEFT JOIN dim_grp_eeoc_r                       n ON n.v_code_r = m.v_eeoc_code_r
                    LEFT JOIN fct_claim_socialsecurity_inc_r       o ON o.n_claim_sk_r = a.n_claim_sk_r
                    LEFT JOIN vw_dim_grp_claim_prior_status_r      p ON p.n_claim_sk_r = a.n_claim_sk_r
                                                                   AND p.v_coverage_code_r = b.v_claim_coverage_code_r
                                                                   AND p.n_claim_coverage_sk_r = b.n_claim_coverage_sk_r
                WHERE
                        a.v_active_status_r = 'Y'
                    AND a.v_lob_type_r IN ( 'LTD', 'STD', 'VPL', 'VPS' )
                    AND b.v_active_status_r = 'Y'
                    AND d.v_active_status_r = 'Y'
            )
        WHERE
                CASE
                    WHEN rank <> 1 THEN
                        n_claim_cvrg_sequence_number_r
                    ELSE
                        1
                END
            IS NOT NULL;