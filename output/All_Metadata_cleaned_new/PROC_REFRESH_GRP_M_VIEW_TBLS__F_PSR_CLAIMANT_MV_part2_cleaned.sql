-- Cleaned for lineage: PROC_REFRESH_GRP_M_VIEW_TBLS__F_PSR_CLAIMANT_MV (part 2/3)

INSERT
			INTO F_PSR_CLAIMANT_MV_TBL
			  (
				POLICY_SKEY,
				CLAIM_SKEY,
				AS_OF_DATE,
				POLICY_PREFIX,
				POLICY_SUFFIX,
				CLAIM_IDENTIFER,
				CLAIM_NUMBER,
				CLAIMANT_NAME,
				CLAIMANT_GENDER,
				CLAIMANT_DOB,
				CLAIMANT_AGE,
				CLAIMANT_HIERDATE,
				CLAIM_COMPANY_NAME,
				CLAIM_COMPANY_CODE,
				LOCATION_NAME,
				LOCATION_NUMBER,
				LOCATION_ID,
				SITUS_STATE,
				INSURED_STATE,
				CLAIMANT_ADDRESS1,
				CLAIMANT_ADDRESS2,
				CLAIMANT_ADDRESS3,
				CLAIMANT_CITY,
				CLAIMANT_ZIPCODE,
				CERTIFICATE_NUMBER,
				CLAIMANT_SALARY,
				CLAIMANT_SALARY_INDICATOR
				,CLIENT_NAME 
			  )
			  SELECT
distinct
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
    d_grp_policy_dir_r_policy.v_policy_prefix_r                                                             AS policy_prefix,
    d_grp_policy_dir_r_policy.v_policy_suffix_r                                                             AS policy_suffix,
    nvl(d_grp_claim_coverage_group_r_claims.v_claim_identifier_r, d_grp_claim_dir_r_claim.v_claim_number_r) AS claim_identifer,
    d_grp_claim_dir_r_claim.v_claim_number_r                                                                AS claim_number,
    concat(concat(d_grp_party_r_claims.v_individual_last_name_r, ', '),
           d_grp_party_r_claims.v_individual_first_name_r)                                                  AS claimant_name,
    d_grp_party_r_claims.v_gender_r                                                                         AS claimant_gender,
    d_grp_party_r_claims.d_birth_date_r                                                                     AS claimant_dob,
    floor(months_between((
        SELECT
            MAX(fic_mis_date_r)
        FROM
            dim_grp_policy_dir_r
        WHERE
            v_source_system_name_r = 'PACS'
    ),
                         d_grp_party_r_claims.d_birth_date_r) / 12)                                                   AS claimant_age
                         ,
    d_grp_claim_event_r_claim.d_hire_date_r                                                                 AS claimant_hierdate,
    d_grp_carrier_r_party.v_carrier_name_r                                                                  AS claim_company_name,
    d_grp_claim_dir_r_claim.V_COMPANY_R                                                                    AS claim_company_code,
    dim_grp_claim_detail_subgroup_lookup.v_subgroup_name_r                                                  AS location_name,
    concat(concat(concat(d_grp_policy_dir_r_policy.v_policy_prefix_r, d_grp_policy_dir_r_policy.v_policy_suffix_r),
                  '-'),
           d_grp_claim_detail_r_claim.v_subgroup_id_r)                                                      AS location_number,
    dim_grp_claim_detail_subgroup_lookup.v_subgroup_id_r                                                    AS location_id,
    fct_grp_party_address_r_customer.v_state_name_r                                                                  AS situs_state,
    CASE
        WHEN upper(f_grp_party_address_r_claimant.v_party_type_r) = 'INSURED'
             AND upper(f_grp_party_address_r_claimant.v_address_type_r) = 'MAIN' THEN
            case when d_ref_state_claimant.v_state_name_r = 'BRITISH COLUMBIA' then 'British Columbia'
            else d_ref_state_claimant.v_state_name_r
            end
        ELSE
            NULL
    END                                                                                                     AS insured_state,
    CASE
        WHEN upper(f_grp_party_address_r_claimant.v_party_type_r) = 'INSURED'
             AND upper(f_grp_party_address_r_claimant.v_address_type_r) = 'MAIN' THEN
            d_grp_address_dir_r_claimant.v_addressline1_r
        ELSE
            NULL
    END                                                                                                     AS claimant_address1,
    CASE
        WHEN upper(f_grp_party_address_r_claimant.v_party_type_r) = 'INSURED'
             AND upper(f_grp_party_address_r_claimant.v_address_type_r) = 'MAIN' THEN
            d_grp_address_dir_r_claimant.v_addressline2_r
        ELSE
            NULL
    END                                                                                                     AS claimant_address2,
    CASE
        WHEN upper(f_grp_party_address_r_claimant.v_party_type_r) = 'INSURED'
             AND upper(f_grp_party_address_r_claimant.v_address_type_r) = 'MAIN' THEN
            d_grp_address_dir_r_claimant.v_addressline3_r
        ELSE
            NULL
    END                                                                                                     AS claimant_address3,
    CASE
        WHEN upper(f_grp_party_address_r_claimant.v_party_type_r) = 'INSURED'
             AND upper(f_grp_party_address_r_claimant.v_address_type_r) = 'MAIN' THEN
            d_grp_address_dir_r_claimant.v_city_r
        ELSE
            NULL
    END                                                                                                     AS claimant_city,
    CASE
        WHEN upper(f_grp_party_address_r_claimant.v_party_type_r) = 'INSURED'
             AND upper(f_grp_party_address_r_claimant.v_address_type_r) = 'MAIN' THEN
            f_grp_party_address_r_claimant.v_postal_zip_r
        ELSE
            NULL
    END                                                                                                     AS claimant_zipcode,
        CASE
        WHEN f_grp_policy_r_policy.v_line_of_business_r IN('SC')
             OR f_grp_policy_r_policy.v_class_of_business_r IN('PVG', 'PGL', 'IWP', 'ORL', 'ORDINARY LIFE',
                                                               'MML', 'LTY', 'IDL', 'END', 'CVD')
             OR f_grp_policy_r_policy.v_class_of_business_r LIKE '%GROUP LTD CONV%'
             OR f_grp_policy_r_policy.v_class_of_business_r LIKE '%CTD%'
             OR f_grp_policy_r_policy.v_class_of_business_r LIKE '%VOLUNTARY LTD CONV%'
             OR f_grp_policy_r_policy.v_class_of_business_r LIKE '%DUAL ENDOW%'
             OR f_grp_policy_r_policy.v_class_of_business_r LIKE '%DUAL INDUS%'
             OR f_grp_policy_r_policy.v_class_of_business_r LIKE '%LOTTER%'
             OR f_grp_policy_r_policy.v_class_of_business_r LIKE 'MASS MARKET%' THEN
            TRIM(BOTH ' ' FROM substr(d_grp_claim_detail_r_claim.v_policy_number_r, 1, 10))
        WHEN d_grp_party_r_claims.v_individual_or_org_ind_r = 'I' THEN
            enc_dec.decrypt(d_grp_party_r_claims.v_tax_number_r)
        ELSE
                NULL
        END                        AS certificate_number,
    d_grp_claim_event_r_claim.n_basic_insured_salary_r                                                      AS claimant_salary,
    d_grp_claim_event_r_claim.v_basic_insured_salary_ind_r                                                  AS claimant_salary_indicator
    , case  when d_grp_party_r_party.V_PARTY_TYPE_R = 'CUSTOMER' then case  when d_grp_party_r_party.V_INDIVIDUAL_OR_ORG_IND_R = 'O' then d_grp_party_r_party.V_INDIVIDUAL_LAST_NAME_R when d_grp_party_r_party.V_INDIVIDUAL_OR_ORG_IND_R = 'I' then concat(concat(d_grp_party_r_party.V_INDIVIDUAL_FIRST_NAME_R, ' '), d_grp_party_r_party.V_INDIVIDUAL_LAST_NAME_R) else NULL end  else NULL end  as Client_Name
FROM
         dim_grp_policy_dir_r d_grp_policy_dir_r_policy
    INNER JOIN fct_grp_policy_r                     f_grp_policy_r_policy
             ON d_grp_policy_dir_r_policy.n_policy_sk_r = f_grp_policy_r_policy.n_policy_sk_r
                                                         AND d_grp_policy_dir_r_policy.n_policy_version_number_r = f_grp_policy_r_policy.n_version_number_r
    LEFT OUTER JOIN dim_grp_party_dir_r                  d_grp_party_dir_r_party
             ON f_grp_policy_r_policy.n_cust_party_sk_r = d_grp_party_dir_r_party.n_party_sk_r
                                                                   AND d_grp_party_dir_r_party.v_active_status_r = 'Y'
    LEFT OUTER JOIN dim_grp_claim_dir_r                  d_grp_claim_dir_r_claim
             ON d_grp_policy_dir_r_policy.n_policy_sk_r = d_grp_claim_dir_r_claim.n_policy_sk_r
                                                                   AND d_grp_claim_dir_r_claim.v_active_status_r = 'Y'
    LEFT OUTER JOIN dim_grp_claim_detail_r               d_grp_claim_detail_r_claim
             ON d_grp_claim_detail_r_claim.n_claim_sk_r = d_grp_claim_dir_r_claim.n_claim_sk_r
                                                                         AND d_grp_claim_detail_r_claim.v_active_status_r = 'Y'
    LEFT OUTER JOIN dim_grp_claim_detail_subgroup_lookup dim_grp_claim_detail_subgroup_lookup ON d_grp_claim_detail_r_claim.v_claim_number_r = dim_grp_claim_detail_subgroup_lookup.v_claim_number_r
    LEFT OUTER JOIN dim_grp_claim_coverage_max_vw        d_grp_claim_coverage_r_claims
             ON d_grp_claim_detail_r_claim.n_claim_sk_r = d_grp_claim_coverage_r_claims.n_claim_sk_r
                                                                                   AND d_grp_claim_coverage_r_claims.v_active_status_r = 'Y'
    LEFT OUTER JOIN dim_grp_claim_coverage_group_r       d_grp_claim_coverage_group_r_claims
             ON d_grp_claim_coverage_group_r_claims.n_claim_coverage_sk_r = d_grp_claim_coverage_r_claims.n_claim_coverage_sk_r
                                                                                          AND d_grp_claim_coverage_group_r_claims.v_active_status_r = 'Y'
    LEFT OUTER JOIN dim_grp_claim_event_r                d_grp_claim_event_r_claim
             ON d_grp_claim_detail_r_claim.n_claim_event_sk_r = d_grp_claim_event_r_claim.n_claim_event_sk_r
                                                                       AND d_grp_claim_event_r_claim.v_active_status_r = 'Y'
    LEFT OUTER JOIN dim_grp_party_r                      d_grp_party_r_claims
             ON d_grp_claim_detail_r_claim.n_insrd_party_sk_r = d_grp_party_r_claims.n_party_sk_r
                                                            AND d_grp_party_r_claims.v_active_status_r = 'Y'
    LEFT OUTER JOIN fct_grp_party_main_address_vw        f_grp_party_address_r_claimant
             ON d_grp_party_r_claims.n_party_sk_r = f_grp_party_address_r_claimant.n_party_sk_r
                                                                                    AND d_grp_party_r_claims.n_source_version_number_r = f_grp_party_address_r_claimant.n_source_version_number_r
    LEFT OUTER JOIN dim_grp_address_dir_r                d_grp_address_dir_r_claimant
             ON d_grp_address_dir_r_claimant.n_address_sk_r = f_grp_party_address_r_claimant.n_address_sk_r
                                                                          AND d_grp_address_dir_r_claimant.v_active_status_r = 'Y'
    LEFT OUTER JOIN ref_state                            d_ref_state_claimant
             ON d_ref_state_claimant.n_state_sk_r = d_grp_address_dir_r_claimant.n_state_sk_r
                                                      AND d_ref_state_claimant.v_active_status_r = 'Y'
    LEFT OUTER JOIN dim_grp_party_r                      d_grp_party_r_party
             ON d_grp_party_dir_r_party.n_party_sk_r = d_grp_party_r_party.n_party_sk_r
                                                           AND d_grp_party_dir_r_party.n_source_version_number_r = d_grp_party_r_party.n_source_version_number_r
                                                           AND d_grp_party_r_party.v_active_status_r = 'Y'
    LEFT OUTER JOIN fct_grp_party_address_r              fct_grp_party_address_r_customer ON d_grp_party_dir_r_party.n_party_sk_r = fct_grp_party_address_r_customer.n_party_sk_r
                                                                       AND d_grp_party_dir_r_party.n_source_version_number_r = fct_grp_party_address_r_customer.n_source_version_number_r
                                                                       AND upper(fct_grp_party_address_r_customer.v_location_id_r) = 'SITUS'
                                                                       AND upper(fct_grp_party_address_r_customer.v_address_type_r) = 'MAIN'
    LEFT OUTER JOIN dim_grp_customer_r                   d_grp_customer_r_party
             ON d_grp_party_dir_r_party.n_party_sk_r = d_grp_customer_r_party.n_cust_party_sk_r
                                                                 AND d_grp_party_dir_r_party.n_source_version_number_r = d_grp_customer_r_party.n_party_version_number_r
                                                                 and d_grp_customer_r_party.v_active_status_r = 'Y'
    LEFT OUTER JOIN dim_grp_carrier_r                    d_grp_carrier_r_party
             ON d_grp_customer_r_party.n_carrier_sk_r = d_grp_carrier_r_party.n_carrier_sk_r
                                                               AND d_grp_carrier_r_party.v_active_status_r = 'Y'
WHERE   
    d_grp_policy_dir_r_policy.v_active_status_r = 'Y';