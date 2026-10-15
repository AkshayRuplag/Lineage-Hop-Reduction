-- Cleaned for lineage: PROC_REFRESH_GRP_M_VIEW_TBLS__F_PSR_CLAIM_MV_3 (part 2/3)

INSERT
			INTO F_PSR_CLAIM_MV_3_TBL
			(
				POLICY_SKEY                                      ,
	CLAIM_SKEY                                       ,
	AS_OF_DATE                                       ,
	CLAIM_IDENTIFIER                                 ,
	ANN_PREMIUM_CYCLE_DATE                           ,
	PRIMARY_DIAGNOSIS_CODE                           ,
	PRIMARY_DIAGNOSIS_CODE_DESCRIPTION               ,
	PRIMARY_DIAGNOSIS_CATEGORY_DESCRIPTION           ,
	PRIMARY_DIAGNOSIS_CATEGORY                       ,
	ADDITIONAL_DIAGNOSIS_CODE_DESCRIPTION            ,
	ADDITIONAL_DIAGNOSIS_CODE                        ,
	ADDITIONAL_DIAGNOSIS_CATEGORY_DESCRIPTION        ,
	ADDITIONAL_DIAGNOSIS_CATEGORY                    ,
	CLAIM_AGE                                        ,
	CLAIM_COUNT                                      ,
	SOCIAL_SECURITY_PRIMARY_AWARD_AMOUNT             ,
	SOCIAL_SECURITY_PRIMARY_AWARD_STATUS             ,
	SOCIAL_SECURITY_PRIMARY_AWARD_TYPE               ,
	SOCIAL_SECURITY_PRIMARY_AWARD_EFFECTIVE_DATE     ,
	SOCIAL_SECURITY_PRIMARY_AWARD_TERMINATION_DATE   ,
	SOCIAL_SECURITY_DEPENDENT_AWARD_AMOUNT           ,
	SOCIAL_SECURITY_DEPENDENT_AWARD_STATUS           ,
	SOCIAL_SECURITY_DEPENDENT_AWARD_TYPE             ,
	SOCIAL_SECURITY_DEPENDENT_AWARD_EFFECTIVE_DATE   ,
	SOCIAL_SECURITY_DEPENDENT_AWARD_TERMINATION_DATE
				)
	SELECT
    d_grp_policy_dir_r_policy.n_policy_sk_r                                                                 AS policy_skey,
    d_grp_claim_dir_r_claim.n_claim_sk_r                                                                    AS claim_skey,
    (
        SELECT
            MAX(fic_mis_date_r)
        FROM
            dim_grp_policy_dir_r
        WHERE
            v_source_system_name_r = 'PACS'
    )                                                                                                       AS as_of_date,
    D_GRP_CLAIM_DIR_R_Claim.v_claim_number_r AS claim_identifier,
   cast (null  AS date) as ann_premium_cycle_date
    ,
    d_grp_medical_diagnosis_r_claims.v_diagnosis_code_r                                                     AS primary_diagnosis_code
    ,
    d_grp_medical_diagnosis_r_claims.v_diagnosis_desc_r                                                     AS primary_diagnosis_code_description
    ,
    d_diagnosis_category_r.v_diag_category_desc_r                                                           AS primary_diagnosis_category_description
    ,
    d_diagnosis_code_r.v_diag_category_code_r                                                               AS primary_diagnosis_category
    ,
    LISTAGG(DISTINCT D_GRP_MEDICAL_DIAGNOSIS_R_Claims_Additional.v_diagnosis_desc_r, '; ')                            AS additional_diagnosis_code_description
    ,
    LISTAGG(DISTINCT D_GRP_MEDICAL_DIAGNOSIS_R_Claims_Additional.v_diagnosis_code_r, '; ')                            AS additional_diagnosis_code
    ,
    LISTAGG(DISTINCT d_diagnosis_category_r_additional.v_diag_category_desc_r, '; ')                        AS additional_diagnosis_category_description
    ,
    LISTAGG(DISTINCT d_diagnosis_category_r_additional.v_diag_category_code_r, '; ')                        AS additional_diagnosis_category
    ,
            case when
            d_grp_claim_detail_r_claim.d_closure_date_r
    is null then null else trunc(         
            d_grp_claim_detail_r_claim.d_closure_date_r
    -     d_grp_busobj_audit_r.received_date          ) end    AS Claim_Age,
			1 
              AS Claim_Count,
			  F_CLAIM_SOCIALSECURITY_INC_R_Claims.N_SS_PRIMARY_AWARD_AMOUNT_R AS Social_Security_Primary_Award_Amount,
			  F_CLAIM_SOCIALSECURITY_INC_R_Claims.V_SS_STATUS_DESCRIPTION_R   AS Social_Security_Primary_Award_Status,
			  F_CLAIM_SOCIALSECURITY_INC_R_Claims.V_SS_PRIMARY_AWARD_TYPE_R   AS Social_Security_Primary_Award_Type,
			  F_CLAIM_SOCIALSECURITY_INC_R_Claims.D_SS_PRIMARY_EFF_DATE_R     AS Social_Security_Primary_Award_Effective_Date,
			  F_CLAIM_SOCIALSECURITY_INC_R_Claims.D_SS_CLOSED_TERM_DATE_R     AS Social_Security_Primary_Award_Termination_Date,
			  F_CLAIM_SOCIALSECURITY_INC_R_Claims.N_SS_DEP_AWARD_AMOUNT_R     AS Social_Security_Dependent_Award_Amount,
			  F_CLAIM_SOCIALSECURITY_INC_R_Claims.V_SS_DEPENDENT_STATUS_R     AS Social_Security_Dependent_Award_Status,
			  F_CLAIM_SOCIALSECURITY_INC_R_Claims.V_SS_DEP_AWARD_TYPE_R       AS Social_Security_Dependent_Award_Type,
			  F_CLAIM_SOCIALSECURITY_INC_R_Claims.D_SS_DEP_AWARD_EFF_DATE_R   AS Social_Security_Dependent_Award_Effective_Date,
			  F_CLAIM_SOCIALSECURITY_INC_R_Claims.D_SS_DEP_TERM_DATE_R        AS Social_Security_Dependent_Award_Termination_Date
		FROM
			  DIM_GRP_POLICY_DIR_R D_GRP_POLICY_DIR_R_Policy 
			  inner join DIM_GRP_CLAIM_DIR_R D_GRP_CLAIM_DIR_R_Claim   
              on D_GRP_POLICY_DIR_R_Policy.N_POLICY_SK_R = D_GRP_CLAIM_DIR_R_Claim.N_POLICY_SK_R
              AND D_GRP_CLAIM_DIR_R_Claim.V_ACTIVE_STATUS_R         = 'Y'
               LEFT OUTER JOIN (
                    SELECT
                        v_claim_number_r,
                        MAX(nvl(t374156.d_received_date_r,
                                TO_DATE(substr(t374156.v_claim_number_r, 1, 10),
                                        'YYYY-MM-DD'))) AS received_date
                    FROM
                        dim_grp_busobj_audit_r t374156
                    WHERE
                            v_active_status_r = 'Y'
                        AND v_claim_number_r NOT IN ( '-LIFE-01', '-LTD-01', '-STD-01', '-VPS-01', '-WOP-01' )
                    GROUP BY
                        v_claim_number_r
                )                              d_grp_busobj_audit_r ON d_grp_claim_dir_r_claim.v_claim_number_r = d_grp_busobj_audit_r.v_claim_number_r
			  inner join DIM_GRP_CLAIM_DETAIL_R D_GRP_CLAIM_DETAIL_R_Claim 
              on D_GRP_CLAIM_DETAIL_R_Claim.N_CLAIM_SK_R = D_GRP_CLAIM_DIR_R_Claim.N_CLAIM_SK_R and D_GRP_CLAIM_DETAIL_R_Claim.V_ACTIVE_STATUS_R = 'Y'
			  inner join DIM_GRP_CLAIM_COVERAGE_R D_GRP_CLAIM_COVERAGE_R_Claims  
              on D_GRP_CLAIM_DIR_R_Claim.N_CLAIM_SK_R = D_GRP_CLAIM_COVERAGE_R_Claims.N_CLAIM_SK_R and D_GRP_CLAIM_COVERAGE_R_Claims.V_ACTIVE_STATUS_R = 'Y'
			  left outer join MVW_PRODUCT_SK_LOOKUP T439745 
              On D_GRP_CLAIM_COVERAGE_R_Claims.N_CLAIM_SK_R = T439745.N_CLAIM_SK_R and D_GRP_CLAIM_COVERAGE_R_Claims.V_CLAIM_COVERAGE_CODE_R = T439745.V_CLAIM_COVERAGE_CODE_R
			  LEFT OUTER JOIN DIM_GRP_PRODUCT_R D_GRP_PRODUCT_R_Claims_Disability  
              On D_GRP_PRODUCT_R_Claims_Disability.N_PRODUCT_SK_R = T439745.N_PRODUCT_SK_R and D_GRP_PRODUCT_R_Claims_Disability.V_ACTIVE_STATUS_R = 'Y'
			  inner join DIM_GRP_CLAIM_COVERAGE_GROUP_R D_GRP_CLAIM_COVERAGE_GROUP_R_Claims 
              on D_GRP_CLAIM_COVERAGE_GROUP_R_Claims.N_CLAIM_COVERAGE_SK_R = D_GRP_CLAIM_COVERAGE_R_Claims.N_CLAIM_COVERAGE_SK_R
              and D_GRP_CLAIM_COVERAGE_GROUP_R_Claims.V_ACTIVE_STATUS_R = 'Y'
			left outer join DIM_GRP_MEDICAL_DIAGNOSIS_R D_GRP_MEDICAL_DIAGNOSIS_R_Claims  
            on  D_GRP_CLAIM_DIR_R_Claim.N_CLAIM_SK_R              = D_GRP_MEDICAL_DIAGNOSIS_R_Claims.N_CLAIM_SK_R
            AND D_GRP_MEDICAL_DIAGNOSIS_R_Claims.N_PRIMARY_IND_R           = 1
            AND D_GRP_MEDICAL_DIAGNOSIS_R_Claims.V_ACTIVE_STATUS_R         = 'Y'
			left outer join DIM_DIAGNOSIS_CODE_R D_DIAGNOSIS_CODE_R  
            on D_GRP_MEDICAL_DIAGNOSIS_R_Claims.V_DIAGNOSIS_CODE_R        = D_DIAGNOSIS_CODE_R.V_DIAG_CODE_R
			left outer join DIM_DIAGNOSIS_CATEGORY_R D_DIAGNOSIS_CATEGORY_R  
            on D_DIAGNOSIS_CODE_R.V_DIAG_CATEGORY_CODE_R    = D_DIAGNOSIS_CATEGORY_R.V_DIAG_CATEGORY_CODE_R
			left outer join DIM_GRP_MEDICAL_DIAGNOSIS_R D_GRP_MEDICAL_DIAGNOSIS_R_Claims_Additional  
            on D_GRP_CLAIM_DIR_R_Claim.N_CLAIM_SK_R = D_GRP_MEDICAL_DIAGNOSIS_R_Claims_Additional.N_CLAIM_SK_R
            AND D_GRP_MEDICAL_DIAGNOSIS_R_Claims_Additional.N_PRIMARY_IND_R = 0 AND D_GRP_MEDICAL_DIAGNOSIS_R_Claims_Additional.V_ACTIVE_STATUS_R ='Y'
			left outer join DIM_DIAGNOSIS_CODE_R D_DIAGNOSIS_CODE_R_Additional  
            on D_DIAGNOSIS_CODE_R_Additional.V_DIAG_CODE_R = D_GRP_MEDICAL_DIAGNOSIS_R_Claims_Additional.V_DIAGNOSIS_CODE_R
			left outer join DIM_DIAGNOSIS_CATEGORY_R D_DIAGNOSIS_CATEGORY_R_Additional  
            on D_DIAGNOSIS_CATEGORY_R_Additional.V_DIAG_CATEGORY_CODE_R    = D_DIAGNOSIS_CODE_R_Additional.V_DIAG_CATEGORY_CODE_R
			left outer join FCT_CLAIM_SOCIALSECURITY_INC_R F_CLAIM_SOCIALSECURITY_INC_R_Claims  
            on D_GRP_CLAIM_DIR_R_Claim.N_CLAIM_SK_R = F_CLAIM_SOCIALSECURITY_INC_R_Claims.N_CLAIM_SK_R
            and F_CLAIM_SOCIALSECURITY_INC_R_Claims.n_claim_sk_r <> -1
WHERE
        1 = 1
    AND d_grp_policy_dir_r_policy.v_active_status_r = 'Y'
and D_GRP_CLAIM_DIR_R_Claim.v_lob_type_r in ('LTD', 'STD', 'VPL', 'VPS')
GROUP BY
    d_grp_policy_dir_r_policy.n_policy_sk_r,
    d_grp_claim_dir_r_claim.n_claim_sk_r,
   D_GRP_CLAIM_DIR_R_Claim.v_claim_number_r,
    d_grp_medical_diagnosis_r_claims.v_diagnosis_code_r,
    d_grp_medical_diagnosis_r_claims.v_diagnosis_desc_r,
    d_diagnosis_category_r.v_diag_category_desc_r,
    d_diagnosis_code_r.v_diag_category_code_r,
       case when
            d_grp_claim_detail_r_claim.d_closure_date_r
    is null then null else trunc(         
            d_grp_claim_detail_r_claim.d_closure_date_r
    -     d_grp_busobj_audit_r.received_date          ) end ,
    f_claim_socialsecurity_inc_r_claims.n_ss_primary_award_amount_r,
    f_claim_socialsecurity_inc_r_claims.v_ss_status_description_r,
    f_claim_socialsecurity_inc_r_claims.v_ss_primary_award_type_r,
    f_claim_socialsecurity_inc_r_claims.d_ss_primary_eff_date_r,
    f_claim_socialsecurity_inc_r_claims.d_ss_closed_term_date_r,
    f_claim_socialsecurity_inc_r_claims.n_ss_dep_award_amount_r,
    f_claim_socialsecurity_inc_r_claims.v_ss_dependent_status_r,
    f_claim_socialsecurity_inc_r_claims.v_ss_dep_award_type_r,
    f_claim_socialsecurity_inc_r_claims.d_ss_dep_award_eff_date_r,
    f_claim_socialsecurity_inc_r_claims.d_ss_dep_term_date_r
    union
    SELECT
    d_grp_policy_dir_r_policy.n_policy_sk_r                                                                 AS policy_skey,
    d_grp_claim_dir_r_claim.n_claim_sk_r                                                                    AS claim_skey,
    (
        SELECT
            MAX(fic_mis_date_r)
        FROM
            dim_grp_policy_dir_r
        WHERE
            v_source_system_name_r = 'PACS'
    )                                                                                                       AS as_of_date,
    d_grp_claim_coverage_group_r_claims.v_claim_identifier_r AS claim_identifier,
   cast (null  AS date)  AS ann_premium_cycle_date
    ,
    d_grp_medical_diagnosis_r_claims.v_diagnosis_code_r                                                     AS primary_diagnosis_code
    ,
    d_grp_medical_diagnosis_r_claims.v_diagnosis_desc_r                                                     AS primary_diagnosis_code_description
    ,
    d_diagnosis_category_r.v_diag_category_desc_r                                                           AS primary_diagnosis_category_description
    ,
    d_diagnosis_code_r.v_diag_category_code_r                                                               AS primary_diagnosis_category
    ,
    LISTAGG(DISTINCT D_GRP_MEDICAL_DIAGNOSIS_R_Claims_Additional.v_diagnosis_desc_r, '; ')                            AS additional_diagnosis_code_description
    ,
    LISTAGG(DISTINCT D_GRP_MEDICAL_DIAGNOSIS_R_Claims_Additional.v_diagnosis_code_r, '; ')                            AS additional_diagnosis_code
    ,
    LISTAGG(DISTINCT d_diagnosis_category_r_additional.v_diag_category_desc_r, '; ')                        AS additional_diagnosis_category_description
    ,
    LISTAGG(DISTINCT d_diagnosis_category_r_additional.v_diag_category_code_r, '; ')                        AS additional_diagnosis_category
    ,
            case when
            D_GRP_CLAIM_COVERAGE_GROUP_R_Claims.d_date_closed_r
    is null then null else trunc(         
            D_GRP_CLAIM_COVERAGE_GROUP_R_Claims.d_date_closed_r
    -     d_grp_busobj_audit_r.received_date          ) end    AS Claim_Age,
            1 
              AS Claim_Count,
              F_CLAIM_SOCIALSECURITY_INC_R_Claims.N_SS_PRIMARY_AWARD_AMOUNT_R AS Social_Security_Primary_Award_Amount,
              F_CLAIM_SOCIALSECURITY_INC_R_Claims.V_SS_STATUS_DESCRIPTION_R   AS Social_Security_Primary_Award_Status,
              F_CLAIM_SOCIALSECURITY_INC_R_Claims.V_SS_PRIMARY_AWARD_TYPE_R   AS Social_Security_Primary_Award_Type,
              F_CLAIM_SOCIALSECURITY_INC_R_Claims.D_SS_PRIMARY_EFF_DATE_R     AS Social_Security_Primary_Award_Effective_Date,
              F_CLAIM_SOCIALSECURITY_INC_R_Claims.D_SS_CLOSED_TERM_DATE_R     AS Social_Security_Primary_Award_Termination_Date,
              F_CLAIM_SOCIALSECURITY_INC_R_Claims.N_SS_DEP_AWARD_AMOUNT_R     AS Social_Security_Dependent_Award_Amount,
              F_CLAIM_SOCIALSECURITY_INC_R_Claims.V_SS_DEPENDENT_STATUS_R     AS Social_Security_Dependent_Award_Status,
              F_CLAIM_SOCIALSECURITY_INC_R_Claims.V_SS_DEP_AWARD_TYPE_R       AS Social_Security_Dependent_Award_Type,
              F_CLAIM_SOCIALSECURITY_INC_R_Claims.D_SS_DEP_AWARD_EFF_DATE_R   AS Social_Security_Dependent_Award_Effective_Date,
              F_CLAIM_SOCIALSECURITY_INC_R_Claims.D_SS_DEP_TERM_DATE_R        AS Social_Security_Dependent_Award_Termination_Date
        FROM
              DIM_GRP_POLICY_DIR_R D_GRP_POLICY_DIR_R_Policy 
              inner join DIM_GRP_CLAIM_DIR_R D_GRP_CLAIM_DIR_R_Claim   
              on D_GRP_POLICY_DIR_R_Policy.N_POLICY_SK_R = D_GRP_CLAIM_DIR_R_Claim.N_POLICY_SK_R
              AND D_GRP_CLAIM_DIR_R_Claim.V_ACTIVE_STATUS_R         = 'Y'
               LEFT OUTER JOIN (
                    SELECT
                        v_claim_number_r,
                        MAX(nvl(t374156.d_received_date_r,
                                TO_DATE(substr(t374156.v_claim_number_r, 1, 10),
                                        'YYYY-MM-DD'))) AS received_date
                    FROM
                        dim_grp_busobj_audit_r t374156
                    WHERE
                            v_active_status_r = 'Y'
                        AND v_claim_number_r NOT IN ( '-LIFE-01', '-LTD-01', '-STD-01', '-VPS-01', '-WOP-01' )
                    GROUP BY
                        v_claim_number_r
                )                              d_grp_busobj_audit_r ON d_grp_claim_dir_r_claim.v_claim_number_r = d_grp_busobj_audit_r.v_claim_number_r
              inner join DIM_GRP_CLAIM_DETAIL_R D_GRP_CLAIM_DETAIL_R_Claim 
              on D_GRP_CLAIM_DETAIL_R_Claim.N_CLAIM_SK_R = D_GRP_CLAIM_DIR_R_Claim.N_CLAIM_SK_R and D_GRP_CLAIM_DETAIL_R_Claim.V_ACTIVE_STATUS_R = 'Y'
              inner join DIM_GRP_CLAIM_COVERAGE_R D_GRP_CLAIM_COVERAGE_R_Claims  
              on D_GRP_CLAIM_DIR_R_Claim.N_CLAIM_SK_R = D_GRP_CLAIM_COVERAGE_R_Claims.N_CLAIM_SK_R and D_GRP_CLAIM_COVERAGE_R_Claims.V_ACTIVE_STATUS_R = 'Y'
              left outer join MVW_PRODUCT_SK_LOOKUP T439745 
              On D_GRP_CLAIM_COVERAGE_R_Claims.N_CLAIM_SK_R = T439745.N_CLAIM_SK_R and D_GRP_CLAIM_COVERAGE_R_Claims.V_CLAIM_COVERAGE_CODE_R = T439745.V_CLAIM_COVERAGE_CODE_R
              LEFT OUTER JOIN DIM_GRP_PRODUCT_R D_GRP_PRODUCT_R_Claims_Disability  
              On D_GRP_PRODUCT_R_Claims_Disability.N_PRODUCT_SK_R = T439745.N_PRODUCT_SK_R and D_GRP_PRODUCT_R_Claims_Disability.V_ACTIVE_STATUS_R = 'Y'
              inner join DIM_GRP_CLAIM_COVERAGE_GROUP_R D_GRP_CLAIM_COVERAGE_GROUP_R_Claims 
              on D_GRP_CLAIM_COVERAGE_GROUP_R_Claims.N_CLAIM_COVERAGE_SK_R = D_GRP_CLAIM_COVERAGE_R_Claims.N_CLAIM_COVERAGE_SK_R
              and D_GRP_CLAIM_COVERAGE_GROUP_R_Claims.V_ACTIVE_STATUS_R = 'Y'
              left outer join MVW_PRODUCT_SK_LOOKUP T439747 
              On D_GRP_CLAIM_COVERAGE_GROUP_R_Claims.N_CLAIM_SK_R = T439747.N_CLAIM_SK_R and D_GRP_CLAIM_COVERAGE_GROUP_R_Claims.V_CLAIM_COVERAGE_CODE_R = T439747.V_CLAIM_COVERAGE_CODE_R
              LEFT OUTER JOIN DIM_GRP_PRODUCT_R D_GRP_PRODUCT_R_Claims_Life  
              On D_GRP_PRODUCT_R_Claims_Life.N_PRODUCT_SK_R = T439747.N_PRODUCT_SK_R and D_GRP_PRODUCT_R_Claims_Life.V_ACTIVE_STATUS_R = 'Y'
            left outer join DIM_GRP_MEDICAL_DIAGNOSIS_R D_GRP_MEDICAL_DIAGNOSIS_R_Claims  
            on  D_GRP_CLAIM_DIR_R_Claim.N_CLAIM_SK_R              = D_GRP_MEDICAL_DIAGNOSIS_R_Claims.N_CLAIM_SK_R
            AND D_GRP_MEDICAL_DIAGNOSIS_R_Claims.N_PRIMARY_IND_R           = 1
            AND D_GRP_MEDICAL_DIAGNOSIS_R_Claims.V_ACTIVE_STATUS_R         = 'Y'
            left outer join DIM_DIAGNOSIS_CODE_R D_DIAGNOSIS_CODE_R  
            on D_GRP_MEDICAL_DIAGNOSIS_R_Claims.V_DIAGNOSIS_CODE_R        = D_DIAGNOSIS_CODE_R.V_DIAG_CODE_R
            left outer join DIM_DIAGNOSIS_CATEGORY_R D_DIAGNOSIS_CATEGORY_R  
            on D_DIAGNOSIS_CODE_R.V_DIAG_CATEGORY_CODE_R    = D_DIAGNOSIS_CATEGORY_R.V_DIAG_CATEGORY_CODE_R
            left outer join DIM_GRP_MEDICAL_DIAGNOSIS_R D_GRP_MEDICAL_DIAGNOSIS_R_Claims_Additional  
            on D_GRP_CLAIM_DIR_R_Claim.N_CLAIM_SK_R = D_GRP_MEDICAL_DIAGNOSIS_R_Claims_Additional.N_CLAIM_SK_R
            AND D_GRP_MEDICAL_DIAGNOSIS_R_Claims_Additional.N_PRIMARY_IND_R = 0 AND D_GRP_MEDICAL_DIAGNOSIS_R_Claims_Additional.V_ACTIVE_STATUS_R ='Y'
            left outer join DIM_DIAGNOSIS_CODE_R D_DIAGNOSIS_CODE_R_Additional  
            on D_DIAGNOSIS_CODE_R_Additional.V_DIAG_CODE_R = D_GRP_MEDICAL_DIAGNOSIS_R_Claims_Additional.V_DIAGNOSIS_CODE_R
            left outer join DIM_DIAGNOSIS_CATEGORY_R D_DIAGNOSIS_CATEGORY_R_Additional  
            on D_DIAGNOSIS_CATEGORY_R_Additional.V_DIAG_CATEGORY_CODE_R    = D_DIAGNOSIS_CODE_R_Additional.V_DIAG_CATEGORY_CODE_R
            left outer join FCT_CLAIM_SOCIALSECURITY_INC_R F_CLAIM_SOCIALSECURITY_INC_R_Claims  
            on D_GRP_CLAIM_DIR_R_Claim.N_CLAIM_SK_R = F_CLAIM_SOCIALSECURITY_INC_R_Claims.N_CLAIM_SK_R
WHERE
        1 = 1
    AND d_grp_policy_dir_r_policy.v_active_status_r = 'Y'
and D_GRP_CLAIM_DIR_R_Claim.v_lob_type_r in ('LIFE', 'NONS', 'WOP')
GROUP BY
    d_grp_policy_dir_r_policy.n_policy_sk_r,
    d_grp_claim_dir_r_claim.n_claim_sk_r,
   d_grp_claim_coverage_group_r_claims.v_claim_identifier_r,
    d_grp_medical_diagnosis_r_claims.v_diagnosis_code_r,
    d_grp_medical_diagnosis_r_claims.v_diagnosis_desc_r,
    d_diagnosis_category_r.v_diag_category_desc_r,
    d_diagnosis_code_r.v_diag_category_code_r,
       case when
            D_GRP_CLAIM_COVERAGE_GROUP_R_Claims.d_date_closed_r
    is null then null else trunc(         
            D_GRP_CLAIM_COVERAGE_GROUP_R_Claims.d_date_closed_r
    -     d_grp_busobj_audit_r.received_date          ) end ,
    f_claim_socialsecurity_inc_r_claims.n_ss_primary_award_amount_r,
    f_claim_socialsecurity_inc_r_claims.v_ss_status_description_r,
    f_claim_socialsecurity_inc_r_claims.v_ss_primary_award_type_r,
    f_claim_socialsecurity_inc_r_claims.d_ss_primary_eff_date_r,
    f_claim_socialsecurity_inc_r_claims.d_ss_closed_term_date_r,
    f_claim_socialsecurity_inc_r_claims.n_ss_dep_award_amount_r,
    f_claim_socialsecurity_inc_r_claims.v_ss_dependent_status_r,
    f_claim_socialsecurity_inc_r_claims.v_ss_dep_award_type_r,
    f_claim_socialsecurity_inc_r_claims.d_ss_dep_award_eff_date_r,
    f_claim_socialsecurity_inc_r_claims.d_ss_dep_term_date_r;