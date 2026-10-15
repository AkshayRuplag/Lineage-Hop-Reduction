-- Cleaned for lineage: PROC_REFRESH_GRP_M_VIEW_TBLS__F_PSR_CLAIM_MV_1 (part 2/3)

INSERT
			INTO F_PSR_CLAIM_MV_1_TBL
			  (
				POLICY_SKEY                       ,
              CLAIM_SKEY                        ,
              ADMINISTERED_BY                   ,
              AS_OF_DATE                        ,
              CLAIM_IDENTIFIER                  ,
              POLICY_PREFIX                     ,
              POLICY_SUFFIX                     ,
              WORKSHEET_END_DATE                ,
              WORKSHEET_START_DATE              ,
              CLAIM_CLOSED_DATE                 ,
              CLAIM_GROSS_BENEFIT_AMOUNT        ,
              CLAIM_MOST_RECENT_ACTIVITY_DATE   ,
              CLAIM_NET_BENEFIT_AMOUNT          ,
              CLAIM_NUMBER                      ,
              CLAIM_RECEIVED_DATE               ,
              CLAIM_TAXABLE_BENEFIT_PERCENTAGE  ,
              DURATION_INDICATOR                ,
              DURATION_PERIOD                   ,
              ELLIMINATION_PERIOD               ,
              LOSS_DATE                         ,
              OCCUPATION_CODE                   ,
              OCCUPATION_DECRIPTION             ,
              PLAN_DURATION_DATE                ,
              MODIFIED_RTW_DATE                 ,
              RETURN_TO_WORK_DATE               ,
              COVERAGE_TYPE                     ,
              CLAIM_CLASS_ID                    ,
              DISABILITY_START_DATE             ,
              PRIVACY_INDICATOR
			  ,CURRENT_RESERVE 
			  ,Policy_effective_date 
			  )SELECT
            d_grp_policy_dir_r_policy.n_policy_sk_r                  AS policy_skey,
            d_grp_claim_dir_r_claim.n_claim_sk_r                     AS claim_skey,
                  f_grp_policy_r_policy.V_ADMINISTERED_BY_R as administered_by  ,
            (
                SELECT
                    MAX(fic_mis_date_r)
                FROM
                    dim_grp_policy_dir_r
                WHERE
                    v_source_system_name_r = 'PACS'
            )                                                        AS as_of_date,
           d_grp_claim_coverage_group_r_claims.v_claim_identifier_r  AS claim_identifier,
            d_grp_policy_dir_r_policy.v_policy_prefix_r              AS policy_prefix,
            d_grp_policy_dir_r_policy.v_policy_suffix_r              AS policy_suffix,
            MAX(
                CASE
                    WHEN nvl(f_grp_worksheet_claims_coveragegroup.v_rpt_worksheet_indicator_r, 'Y') = 'Y'
                         AND d_grp_claim_dir_r_claim.v_lob_type_r IN('LIFE', 'NONS', 'WOP') THEN
                        f_grp_worksheet_claims_coveragegroup.d_worksheet_end_date_r
                END
            )                                                        AS worksheet_end_date,
            MAX(
                CASE
                    WHEN nvl(f_grp_worksheet_claims_coveragegroup.v_rpt_worksheet_indicator_r, 'Y') = 'Y'
                         AND d_grp_claim_dir_r_claim.v_lob_type_r IN('LIFE', 'NONS', 'WOP') THEN
                        f_grp_worksheet_claims_coveragegroup.d_worksheet_start_date_r
                END
            )                                                        AS worksheet_start_date,
            CASE
                WHEN d_grp_claim_dir_r_claim.v_lob_type_r IN ( 'LIFE', 'NONS', 'WOP' ) THEN
                    d_grp_claim_coverage_group_r_claims.d_date_closed_r
            END                                                      AS claim_closed_date,
            SUM(
                CASE
                    WHEN f_grp_worksheet_claims_coveragegroup.v_rpt_worksheet_indicator_r = 'Y' THEN
                        f_grp_worksheet_claims_coveragegroup.n_gross_benefit_r
                    ELSE
                        0
                END
            )                                                        AS claim_gross_benefit_amount,
            CAST(TO_DATE(substr(f_grp_transactions_r_claims.v_dc_timestamp_r, 1, 8),
                'YYYYMMDD') AS DATE)                                 AS claim_most_recent_activity_date,
            SUM(
                CASE
                    WHEN f_grp_worksheet_claims_coveragegroup.v_rpt_worksheet_indicator_r = 'Y' THEN
                        f_grp_worksheet_claims_coveragegroup.n_rpt_net_benefit_r
                    ELSE
                        0
                END
            )                                                        AS claim_net_benefit_amount,
            d_grp_claim_dir_r_claim.v_claim_number_r                 AS claim_number,
            d_grp_busobj_audit_r.received_date                       AS claim_received_date,
            MAX(
                CASE
                    WHEN f_grp_worksheet_claims_coveragegroup.v_rpt_worksheet_indicator_r = 'Y' THEN
                        f_grp_worksheet_claims_coveragegroup.n_taxable_override_pct_r
                    ELSE
                        NULL
                END
            )                                                        AS claim_taxable_benefit_percentage,
            CASE
                WHEN d_grp_claim_dir_r_claim.v_lob_type_r IN ( 'LTD', 'LTD-Small', 'VLT', 'VPL' ) THEN
                    'M'
                WHEN d_grp_claim_dir_r_claim.v_lob_type_r IN ( 'DBL', 'STD', 'STD-Small', 'VPS' ) THEN
                    'W'
                WHEN NOT d_grp_claim_eligibility_r_claims.n_waiver_termination_age_r IS NULL THEN
                    'A'
                ELSE
                    NULL
            END                                                      AS duration_indicator,
            max(CASE
                    WHEN d_grp_claim_dir_r_claim.v_lob_type_r                     IN ('STD','VPS' )
                    THEN case when d_grp_claim_eligibility_r_claims.v_benefit_duration_r is not null
                    then d_grp_claim_eligibility_r_claims.v_benefit_duration_r
                    ELSE To_Char(ROUND(((d_grp_claim_eligibility_r_claims.d_plan_dur_date_r - d_grp_party_r_claims.D_BIRTH_DATE_R + 1) /365.25)*12,0 ))
                    END
                    WHEN d_grp_claim_dir_r_claim.v_lob_type_r                     IN ('LTD','VPL' )
                    THEN CASE when  f_grp_worksheet_claims_coveragegroup.D_BENEFIT_START_R is not null
                    THEN to_char(ROUND((d_grp_claim_eligibility_r_claims.d_plan_dur_date_r - f_grp_worksheet_claims_coveragegroup.d_benefit_start_r + 1) / 30.45, 0))
                    ELSE to_char(ROUND(((d_grp_claim_eligibility_r_claims.d_plan_dur_date_r - d_grp_party_r_claims.D_BIRTH_DATE_R ) /365.25)*12,0 ))
                    END
                    WHEN d_grp_claim_dir_r_claim.v_lob_type_r                     IN ( 'WOP' )
                                THEN to_char(d_grp_claim_eligibility_r_claims.n_waiver_termination_age_r)
                    WHEN d_grp_claim_dir_r_claim.v_lob_type_r                     IN ( 'NONS' )
                    THEN case when d_grp_claim_eligibility_r_claims.n_elim_period_r is null then
                    To_char(lpad(ROUND(((d_grp_claim_eligibility_r_claims.d_plan_dur_date_r - d_grp_claim_detail_r_claim.d_date_of_loss_r) / 365.25) * 12), 3, '0'))
                    else To_char(lpad(ROUND(((d_grp_claim_eligibility_r_claims.d_plan_dur_date_r- (d_grp_claim_detail_r_claim.d_date_of_loss_r+d_grp_claim_eligibility_r_claims.n_elim_period_r))         / 365.25) * 12), 3, '0'))
                    end
              ELSE NULL END        )                            AS duration_period,
            CASE
                WHEN d_grp_claim_eligibility_r_claims.n_elim_period_r <> ''
                     OR d_grp_claim_eligibility_r_claims.n_elim_period_r <> 0 THEN
                    d_grp_claim_eligibility_r_claims.n_elim_period_r
                WHEN
                    CASE d_grp_claim_event_dir_r_claim.v_event_cause_r
                        WHEN 'ACCIDENT'                        THEN
                            'A6'
                        WHEN 'ACCIDENT - AVIATION'             THEN
                            'A3'
                        WHEN 'ACCIDENT- AVIATION'              THEN
                            'A3'
                        WHEN 'ACCIDENT - OCCUPATIONAL'         THEN
                            'A1'
                        WHEN 'ACCIDENT- OCCUPATIONAL'          THEN
                            'A1'
                        WHEN 'ACCIDENT- OTHER'                 THEN
                            'A6'
                        WHEN 'ACCIDENT - OTHER'                THEN
                            'A6'
                        WHEN 'ACCIDENT - SPORTS'               THEN
                            'A4'
                        WHEN 'ACCIDENT- SPORTS'                THEN
                            'A4'
                        WHEN 'ADOPTION'                        THEN
                            'AE'
                        WHEN 'ALCOHOL'                         THEN
                            'AC'
                        WHEN 'ASSAULT'                         THEN
                            'A5'
                        WHEN 'BONDING'                         THEN
                            'AE'
                        WHEN 'COMMONDISASTER'                  THEN
                            '31'
                        WHEN 'COMMON DISASTER'                 THEN
                            '31'
                        WHEN 'DRUGS'                           THEN
                            'AD'
                        WHEN 'FOSTER'                          THEN
                            'AE'
                        WHEN 'MATERNITY'                       THEN
                            'AE'
                        WHEN 'MENTAL'                          THEN
                            'AA'
                        WHEN 'MISSING INSURED / DISAPPEARANCE' THEN
                            '33'
                        WHEN 'MOTOR VEHICLE'                   THEN
                            'A2'
                        WHEN 'MOTORCYCLE'                      THEN
                            'A2'
                        WHEN 'NERVOUS'                         THEN
                            'AB'
                        WHEN 'SICKNESS'                        THEN
                            'AE'
                        WHEN 'SUICIDE'                         THEN
                            'SU'
                        WHEN 'UNKNOWN / UNDETERMINED'          THEN
                            'UN'
                        WHEN 'UNKNOWN / UNDETER '              THEN
                            'UN'
                        WHEN 'WAR / TERRORISM'                 THEN
                            '40'
                        WHEN 'WELLNESS'                        THEN
                            'WL'
                        ELSE
                            'UN'
                    END
                IN ( 'A1', 'A2', 'A3', 'A4', 'A5',
                     'A6' ) THEN
                    d_grp_claim_eligibility_r_claims.n_elim_period_acc_r
                ELSE
                    d_grp_claim_eligibility_r_claims.n_elim_period_sick_r
            END                                                      AS ellimination_period,
            CASE
                WHEN d_grp_policy_dir_r_policy.v_policy_prefix_r = 'VAI' THEN
                    d_grp_claim_detail_r_claim.d_date_of_event_r
                ELSE
                    d_grp_claim_detail_r_claim.d_date_of_loss_r
            END                                                      AS loss_date,
            d_grp_eeoc_r.v_code_r                                    AS occupation_code,
            d_grp_eeoc_r.v_description_r                             AS occupation_decription,
            d_grp_claim_eligibility_r_claims.d_plan_dur_date_r       AS plan_duration_date,
            d_grp_claim_detail_r_claim.d_return_to_mod_wkdt_r        AS modified_rtw_date,
            d_grp_claim_detail_r_claim.d_return_to_work_date_r       AS return_to_work_date,
            CASE
                WHEN d_grp_product_r_claims_disability.v_coverage_type_code_r = '1' THEN
                    'LTD'
                WHEN d_grp_product_r_claims_disability.v_coverage_type_code_r = '2' THEN
                    'STD'
                WHEN d_grp_product_r_claims_disability.v_coverage_type_code_r IN ( '1', '2' ) THEN
                    'Disability (LTD )'
                WHEN d_grp_product_r_claims_life.v_coverage_type_code_r = '3'       THEN
                    'Life'
                WHEN d_grp_product_r_claims_life.v_coverage_category_r = 'Life - Annuity'
                     AND d_grp_product_r_claims_life.v_coverage_type_code_r = '3' THEN
                    'Life - Annuity'
                WHEN d_grp_product_r_claims_life.v_coverage_category_r = 'Life - Non-Annuity'
                     AND d_grp_product_r_claims_life.v_coverage_type_code_r = '3' THEN
                    'Life - Non-Annuity'
                WHEN d_grp_product_r_claims_life.v_coverage_type_code_r = '3'
                     AND NOT ( d_grp_product_r_claims_life.v_coverage_code_r LIKE '%WP%'
                               OR d_grp_product_r_claims_life.v_coverage_code_r LIKE 'GAN%'
                               OR d_grp_product_r_claims_life.v_coverage_code_r LIKE 'CD%' ) THEN
                    'Group Life'
            END                                                      AS coverage_type,
            Max(CASE
                WHEN d_grp_claim_dir_r_claim.v_lob_type_r IN ( 'LIFE', 'NONS', 'WOP' ) THEN
                    d_grp_claim_coverage_group_r_claims.v_class_id_r
                ELSE
                    d_grp_claim_coverage_r_claims.v_class_id_r
            END    )                                                  AS claim_class_id,
            CASE
                WHEN d_grp_policy_dir_r_policy.v_orig_lob_r = 'VAI' THEN
                    d_grp_claim_event_dir_r_claim.d_date_of_event_r +
                    CASE
                        WHEN d_grp_claim_eligibility_r_claims.n_elim_period_r <> ''
                             OR d_grp_claim_eligibility_r_claims.n_elim_period_r <> 0 THEN
                                d_grp_claim_eligibility_r_claims.n_elim_period_r
                        ELSE
                            0
                    END
                ELSE
                    d_grp_claim_event_dir_r_claim.d_date_of_event_r
            END                                                      AS disability_start_date,
            d_grp_claim_dir_r_claim.V_PRIVACY_INDICATOR_R as PRIVACY_INDICATOR
			,(d_grp_claim_coverage_group_r_claims.N_RESERVE_AMOUNT_R - d_grp_claim_coverage_group_r_claims.N_WS_RELEASED_AMOUNT_R) CURRENT_RESERVE
			,d_grp_policy_dir_r_policy.T_POLICY_EFFECTIVE_DATE_R 
        FROM
            (
                (
                    (
                             dim_grp_policy_dir_r d_grp_policy_dir_r_policy
                        INNER JOIN dim_grp_claim_dir_r            d_grp_claim_dir_r_claim ON d_grp_policy_dir_r_policy.n_policy_sk_r = d_grp_claim_dir_r_claim.n_policy_sk_r
                                 left outer join     (
                SELECT
                    *
                FROM
                    fct_grp_transactions_r
                WHERE
                    n_claim_sk_r <> - 1
            )                              f_grp_transactions_r_claims
                  on f_grp_transactions_r_claims.n_claim_sk_r = d_grp_claim_dir_r_claim.n_claim_sk_r
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
                        LEFT OUTER JOIN (
                            SELECT
                                *
                            FROM
                                fct_grp_worksheet
                            WHERE
                                v_rpt_worksheet_indicator_r = 'Y'
                        )                              f_grp_worksheet_claims_coveragegroup
                   ON d_grp_claim_dir_r_claim.n_claim_sk_r = f_grp_worksheet_claims_coveragegroup.n_claim_sk_r
                    )
                    INNER JOIN dim_grp_claim_detail_r         d_grp_claim_detail_r_claim
                   ON d_grp_claim_detail_r_claim.n_claim_sk_r = d_grp_claim_dir_r_claim.n_claim_sk_r
                )
                LEFT OUTER JOIN dim_grp_party_r                d_grp_party_r_claims
                   ON d_grp_claim_detail_r_claim.n_insrd_party_sk_r = d_grp_party_r_claims.n_party_sk_r
            ),
            fct_grp_policy_r               f_grp_policy_r_policy
                  ,
        ( (
                (
                    (
                        (
                            (
                                dim_grp_claim_coverage_r       d_grp_claim_coverage_r_claims
                                LEFT OUTER JOIN (
                                    dim_grp_claim_coverage_group_r d_grp_claim_coverage_group_r_claims
                                    LEFT OUTER JOIN mvw_product_sk_lookup_tbl      vw_product_sk_lookup_for_life
                   ON d_grp_claim_coverage_group_r_claims.n_claim_sk_r = vw_product_sk_lookup_for_life.n_claim_sk_r
                                                                                                               AND d_grp_claim_coverage_group_r_claims.v_claim_coverage_code_r = vw_product_sk_lookup_for_life.v_claim_coverage_code_r
                                ) ON d_grp_claim_coverage_group_r_claims.n_claim_coverage_sk_r = d_grp_claim_coverage_r_claims.n_claim_coverage_sk_r
                            )
                            LEFT OUTER JOIN dim_grp_product_r              d_grp_product_r_claims_life
                   ON d_grp_product_r_claims_life.n_product_sk_r = vw_product_sk_lookup_for_life.n_product_sk_r
                        )
                        LEFT OUTER JOIN mvw_product_sk_lookup_tbl      vw_product_sk_lookup_for_disablity
                   ON d_grp_claim_coverage_r_claims.n_claim_sk_r = vw_product_sk_lookup_for_disablity.n_claim_sk_r
                                                                                                        AND d_grp_claim_coverage_r_claims.v_claim_coverage_code_r = vw_product_sk_lookup_for_disablity.v_claim_coverage_code_r
                    )
                    LEFT OUTER JOIN dim_grp_product_r              d_grp_product_r_claims_disability
                   ON vw_product_sk_lookup_for_disablity.n_product_sk_r = d_grp_product_r_claims_disability.n_product_sk_r
                )
                LEFT OUTER JOIN dim_grp_claim_eligibility_r    d_grp_claim_eligibility_r_claims
                   ON d_grp_claim_eligibility_r_claims.n_claim_coverage_sk_r = CASE
                                                                                                                      WHEN
                                                                                                                      d_grp_claim_eligibility_r_claims.n_claim_coverage_sk_r <> - 1
                                                                                                                      THEN
                                                                                                                         d_grp_claim_coverage_r_claims.n_claim_coverage_sk_r
                                                                                                                            ELSE
                                                                                                                            - 1
                                                                                                                          END
                                                                                                AND d_grp_claim_eligibility_r_claims.n_claim_sk_r = d_grp_claim_coverage_r_claims.n_claim_sk_r
            ) )
            , dim_grp_claim_event_r          d_grp_claim_event_r_claim
            LEFT OUTER JOIN dim_grp_eeoc_r                 d_grp_eeoc_r ON d_grp_claim_event_r_claim.v_eeoc_code_r = d_grp_eeoc_r.v_code_r,
            dim_grp_claim_event_dir_r      d_grp_claim_event_dir_r_claim
        WHERE
            ( d_grp_claim_coverage_r_claims.n_claim_sk_r = d_grp_claim_detail_r_claim.n_claim_sk_r )
            AND ( d_grp_policy_dir_r_policy.n_policy_sk_r = f_grp_policy_r_policy.n_policy_sk_r
                  AND d_grp_policy_dir_r_policy.n_policy_version_number_r = f_grp_policy_r_policy.n_version_number_r
                  AND d_grp_claim_detail_r_claim.n_claim_event_sk_r = d_grp_claim_event_r_claim.n_claim_event_sk_r
                  AND d_grp_claim_detail_r_claim.n_claim_event_sk_r = d_grp_claim_event_r_claim.n_claim_event_sk_r
                  AND d_grp_claim_event_r_claim.n_claim_event_sk_r = d_grp_claim_event_dir_r_claim.n_claim_event_sk_r
                  AND d_grp_policy_dir_r_policy.v_active_status_r = 'Y'
                  AND nvl(d_grp_claim_eligibility_r_claims.v_active_status_r, 'Y') = 'Y'
                  AND nvl(d_grp_claim_coverage_group_r_claims.v_active_status_r, 'Y') = 'Y'
                  AND d_grp_claim_coverage_r_claims.v_active_status_r = 'Y'
                  AND d_grp_claim_detail_r_claim.v_active_status_r = 'Y'
                  AND d_grp_claim_dir_r_claim.v_active_status_r = 'Y'
                  AND d_grp_claim_event_r_claim.v_active_status_r = 'Y'
                  AND d_grp_claim_event_dir_r_claim.v_active_status_r = 'Y'
                  AND nvl(d_grp_eeoc_r.v_active_status_r, 'Y') = 'Y'
                  AND d_grp_claim_dir_r_claim.v_lob_type_r IN ( 'LIFE', 'NONS', 'WOP' )
				  and  case when d_grp_claim_dir_r_claim.v_source_system_name_r = 'PACS'
                  then d_grp_claim_coverage_group_r_claims.n_cov_grp_id_r else 1 end is not null
                   )
        GROUP BY
            d_grp_policy_dir_r_policy.n_policy_sk_r,
            d_grp_claim_dir_r_claim.n_claim_sk_r,
            f_grp_policy_r_policy.V_ADMINISTERED_BY_R ,
            d_grp_claim_coverage_group_r_claims.v_claim_identifier_r,
            d_grp_policy_dir_r_policy.v_policy_prefix_r,
            d_grp_policy_dir_r_policy.v_policy_suffix_r,
            CASE
                WHEN d_grp_claim_dir_r_claim.v_lob_type_r IN ( 'LIFE', 'NONS', 'WOP' ) THEN
                        d_grp_claim_coverage_group_r_claims.d_date_closed_r
            END,
            CAST(TO_DATE(substr(f_grp_transactions_r_claims.v_dc_timestamp_r, 1, 8),
                'YYYYMMDD') AS DATE),
            d_grp_claim_dir_r_claim.v_claim_number_r,
            d_grp_busobj_audit_r.received_date,
            CASE
                    WHEN d_grp_claim_dir_r_claim.v_lob_type_r IN ( 'LTD', 'LTD-Small', 'VLT', 'VPL' ) THEN
                        'M'
                    WHEN d_grp_claim_dir_r_claim.v_lob_type_r IN ( 'DBL', 'STD', 'STD-Small', 'VPS' ) THEN
                        'W'
                    WHEN NOT d_grp_claim_eligibility_r_claims.n_waiver_termination_age_r IS NULL THEN
                        'A'
                    ELSE
                        NULL
            END,
            CASE
                    WHEN d_grp_claim_eligibility_r_claims.n_elim_period_r <> ''
                         OR d_grp_claim_eligibility_r_claims.n_elim_period_r <> 0 THEN
                        d_grp_claim_eligibility_r_claims.n_elim_period_r
                    WHEN
                        CASE d_grp_claim_event_dir_r_claim.v_event_cause_r
                            WHEN 'ACCIDENT'                        THEN
                                'A6'
                            WHEN 'ACCIDENT - AVIATION'             THEN
                                'A3'
                            WHEN 'ACCIDENT- AVIATION'              THEN
                                'A3'
                            WHEN 'ACCIDENT - OCCUPATIONAL'         THEN
                                'A1'
                            WHEN 'ACCIDENT- OCCUPATIONAL'          THEN
                                'A1'
                            WHEN 'ACCIDENT- OTHER'                 THEN
                                'A6'
                            WHEN 'ACCIDENT - OTHER'                THEN
                                'A6'
                            WHEN 'ACCIDENT - SPORTS'               THEN
                                'A4'
                            WHEN 'ACCIDENT- SPORTS'                THEN
                                'A4'
                            WHEN 'ADOPTION'                        THEN
                                'AE'
                            WHEN 'ALCOHOL'                         THEN
                                'AC'
                            WHEN 'ASSAULT'                         THEN
                                'A5'
                            WHEN 'BONDING'                         THEN
                                'AE'
                            WHEN 'COMMONDISASTER'                  THEN
                                '31'
                            WHEN 'COMMON DISASTER'                 THEN
                                '31'
                            WHEN 'DRUGS'                           THEN
                                'AD'
                            WHEN 'FOSTER'                          THEN
                                'AE'
                            WHEN 'MATERNITY'                       THEN
                                'AE'
                            WHEN 'MENTAL'                          THEN
                                'AA'
                            WHEN 'MISSING INSURED / DISAPPEARANCE' THEN
                                '33'
                            WHEN 'MOTOR VEHICLE'                   THEN
                                'A2'
                            WHEN 'MOTORCYCLE'                      THEN
                                'A2'
                            WHEN 'NERVOUS'                         THEN
                                'AB'
                            WHEN 'SICKNESS'                        THEN
                                'AE'
                            WHEN 'SUICIDE'                         THEN
                                'SU'
                            WHEN 'UNKNOWN / UNDETERMINED'          THEN
                                'UN'
                            WHEN 'UNKNOWN / UNDETER '              THEN
                                'UN'
                            WHEN 'WAR / TERRORISM'                 THEN
                                '40'
                            WHEN 'WELLNESS'                        THEN
                                'WL'
                            ELSE
                                'UN'
                        END
                    IN ( 'A1', 'A2', 'A3', 'A4', 'A5',
                         'A6' ) THEN
                        d_grp_claim_eligibility_r_claims.n_elim_period_acc_r
                    ELSE
                        d_grp_claim_eligibility_r_claims.n_elim_period_sick_r
            END,
            CASE
                WHEN d_grp_policy_dir_r_policy.v_policy_prefix_r = 'VAI' THEN
                        d_grp_claim_detail_r_claim.d_date_of_event_r
                ELSE
                    d_grp_claim_detail_r_claim.d_date_of_loss_r
            END,
            d_grp_eeoc_r.v_code_r,
            d_grp_eeoc_r.v_description_r,
            d_grp_claim_eligibility_r_claims.d_plan_dur_date_r,
            d_grp_claim_detail_r_claim.d_return_to_mod_wkdt_r,
            d_grp_claim_detail_r_claim.d_return_to_work_date_r,
            d_grp_claim_dir_r_claim.V_PRIVACY_INDICATOR_R,
            CASE
                    WHEN d_grp_product_r_claims_disability.v_coverage_type_code_r = '1' THEN
                        'LTD'
                    WHEN d_grp_product_r_claims_disability.v_coverage_type_code_r = '2' THEN
                        'STD'
                    WHEN d_grp_product_r_claims_disability.v_coverage_type_code_r IN ( '1', '2' ) THEN
                        'Disability (LTD )'
                    WHEN d_grp_product_r_claims_life.v_coverage_type_code_r = '3'       THEN
                        'Life'
                    WHEN d_grp_product_r_claims_life.v_coverage_category_r = 'Life - Annuity'
                         AND d_grp_product_r_claims_life.v_coverage_type_code_r = '3' THEN
                        'Life - Annuity'
                    WHEN d_grp_product_r_claims_life.v_coverage_category_r = 'Life - Non-Annuity'
                         AND d_grp_product_r_claims_life.v_coverage_type_code_r = '3' THEN
                        'Life - Non-Annuity'
                    WHEN d_grp_product_r_claims_life.v_coverage_type_code_r = '3'
                         AND NOT ( d_grp_product_r_claims_life.v_coverage_code_r LIKE '%WP%'
                                   OR d_grp_product_r_claims_life.v_coverage_code_r LIKE 'GAN%'
                                   OR d_grp_product_r_claims_life.v_coverage_code_r LIKE 'CD%' ) THEN
                        'Group Life'
            END,
            CASE
                WHEN d_grp_policy_dir_r_policy.v_orig_lob_r = 'VAI' THEN
                        d_grp_claim_event_dir_r_claim.d_date_of_event_r +
                        CASE
                            WHEN d_grp_claim_eligibility_r_claims.n_elim_period_r <> ''
                                 OR d_grp_claim_eligibility_r_claims.n_elim_period_r <> 0 THEN
                                    d_grp_claim_eligibility_r_claims.n_elim_period_r
                            ELSE
                                0
                        END
                ELSE
                    d_grp_claim_event_dir_r_claim.d_date_of_event_r
            END
            ,(d_grp_claim_coverage_group_r_claims.N_RESERVE_AMOUNT_R - d_grp_claim_coverage_group_r_claims.N_WS_RELEASED_AMOUNT_R)
			,d_grp_policy_dir_r_policy.T_POLICY_EFFECTIVE_DATE_R 
        union
        SELECT
            d_grp_policy_dir_r_policy.n_policy_sk_r                  AS policy_skey,
            d_grp_claim_dir_r_claim.n_claim_sk_r                     AS claim_skey,
                  f_grp_policy_r_policy.V_ADMINISTERED_BY_R as administered_by ,
            (
                SELECT
                    MAX(fic_mis_date_r)
                FROM
                    dim_grp_policy_dir_r
                WHERE
                    v_source_system_name_r = 'PACS'
            )                                                        AS as_of_date,
            d_grp_claim_dir_r_claim.v_claim_number_r AS claim_identifier,
            d_grp_policy_dir_r_policy.v_policy_prefix_r              AS policy_prefix,
            d_grp_policy_dir_r_policy.v_policy_suffix_r              AS policy_suffix,
            MAX(
                CASE
                    WHEN nvl(f_grp_worksheet_claims_coveragegroup.v_rpt_worksheet_indicator_r, 'Y') = 'Y'
                         AND d_grp_claim_dir_r_claim.v_lob_type_r IN('LTD', 'STD', 'VPL', 'VPS') THEN
                        f_grp_worksheet_claims_coveragegroup.d_worksheet_end_date_r
                END
            )                                                        AS worksheet_end_date,
            MAX(
                CASE
                    WHEN nvl(f_grp_worksheet_claims_coveragegroup.v_rpt_worksheet_indicator_r, 'Y') = 'Y'
                         AND d_grp_claim_dir_r_claim.v_lob_type_r IN('LTD', 'STD', 'VPL', 'VPS') THEN
                        f_grp_worksheet_claims_coveragegroup.d_worksheet_start_date_r
                END
            )                                                        AS worksheet_start_date,
            CASE
                WHEN d_grp_claim_dir_r_claim.v_lob_type_r IN ( 'LTD', 'STD', 'VPL', 'VPS' ) THEN
                    d_grp_claim_detail_r_claim.d_closure_date_r
            END                                                      AS claim_closed_date,
            MAX(
                CASE
                    WHEN f_grp_worksheet_claims_coveragegroup.v_rpt_worksheet_indicator_r = 'Y' THEN
                        f_grp_worksheet_claims_coveragegroup.n_gross_benefit_r
                    ELSE
                        0
                END
            )                                                        AS claim_gross_benefit_amount,
            CAST(TO_DATE(substr(f_grp_transactions_r_claims.v_dc_timestamp_r, 1, 8),
                'YYYYMMDD') AS DATE)                                 AS claim_most_recent_activity_date,
            MAX(
                CASE
                    WHEN f_grp_worksheet_claims_coveragegroup.v_rpt_worksheet_indicator_r = 'Y' THEN
                        f_grp_worksheet_claims_coveragegroup.n_rpt_net_benefit_r
                    ELSE
                        0
                END
            )                                                        AS claim_net_benefit_amount,
            d_grp_claim_dir_r_claim.v_claim_number_r                 AS claim_number,
            d_grp_busobj_audit_r.received_date                       AS claim_received_date,
            MAX(
                CASE
                    WHEN f_grp_worksheet_claims_coveragegroup.v_rpt_worksheet_indicator_r = 'Y' THEN
                        f_grp_worksheet_claims_coveragegroup.n_taxable_override_pct_r
                    ELSE
                        NULL
                END
            )                                                        AS claim_taxable_benefit_percentage,
            CASE
                WHEN d_grp_claim_dir_r_claim.v_lob_type_r IN ( 'LTD', 'LTD-Small', 'VLT', 'VPL' ) THEN
                    'M'
                WHEN d_grp_claim_dir_r_claim.v_lob_type_r IN ( 'DBL', 'STD', 'STD-Small', 'VPS' ) THEN
                    'W'
                WHEN NOT d_grp_claim_eligibility_r_claims.n_waiver_termination_age_r IS NULL THEN
                    'A'
                ELSE
                    NULL
            END                                                      AS duration_indicator,
            CASE
                WHEN d_grp_claim_dir_r_claim.v_lob_type_r                     IN ('STD','VPS' )
                THEN case when d_grp_claim_eligibility_r_claims.v_benefit_duration_r is not null
                then d_grp_claim_eligibility_r_claims.v_benefit_duration_r
                ELSE To_Char(ROUND(((d_grp_claim_eligibility_r_claims.d_plan_dur_date_r - d_grp_party_r_claims.D_BIRTH_DATE_R + 1) /365.25)*12,0 ))
                END
                WHEN d_grp_claim_dir_r_claim.v_lob_type_r                     IN ('LTD','VPL' )
                THEN CASE when  f_grp_worksheet_claims_coveragegroup.D_BENEFIT_START_R is not null
                THEN to_char(ROUND((d_grp_claim_eligibility_r_claims.d_plan_dur_date_r - f_grp_worksheet_claims_coveragegroup.d_benefit_start_r + 1) / 30.45, 0))
                ELSE to_char(ROUND(((d_grp_claim_eligibility_r_claims.d_plan_dur_date_r - d_grp_party_r_claims.D_BIRTH_DATE_R ) /365.25)*12,0 ))
                END
                WHEN d_grp_claim_dir_r_claim.v_lob_type_r                     IN ( 'WOP' )
                            THEN to_char(d_grp_claim_eligibility_r_claims.n_waiver_termination_age_r)
                WHEN d_grp_claim_dir_r_claim.v_lob_type_r                     IN ( 'NONS' )
                THEN case when d_grp_claim_eligibility_r_claims.n_elim_period_r is null then
                To_char(lpad(ROUND(((d_grp_claim_eligibility_r_claims.d_plan_dur_date_r - d_grp_claim_detail_r_claim.d_date_of_loss_r) / 365.25) * 12), 3, '0'))
                else To_char(lpad(ROUND(((d_grp_claim_eligibility_r_claims.d_plan_dur_date_r- (d_grp_claim_detail_r_claim.d_date_of_loss_r+d_grp_claim_eligibility_r_claims.n_elim_period_r))         / 365.25) * 12), 3, '0'))
                end
            ELSE NULL END AS duration_period,
            CASE
                WHEN d_grp_claim_eligibility_r_claims.n_elim_period_r <> ''
                     OR d_grp_claim_eligibility_r_claims.n_elim_period_r <> 0 THEN
                    d_grp_claim_eligibility_r_claims.n_elim_period_r
                WHEN
                    CASE d_grp_claim_event_dir_r_claim.v_event_cause_r
                        WHEN 'ACCIDENT'                        THEN
                            'A6'
                        WHEN 'ACCIDENT - AVIATION'             THEN
                            'A3'
                        WHEN 'ACCIDENT- AVIATION'              THEN
                            'A3'
                        WHEN 'ACCIDENT - OCCUPATIONAL'         THEN
                            'A1'
                        WHEN 'ACCIDENT- OCCUPATIONAL'          THEN
                            'A1'
                        WHEN 'ACCIDENT- OTHER'                 THEN
                            'A6'
                        WHEN 'ACCIDENT - OTHER'                THEN
                            'A6'
                        WHEN 'ACCIDENT - SPORTS'               THEN
                            'A4'
                        WHEN 'ACCIDENT- SPORTS'                THEN
                            'A4'
                        WHEN 'ADOPTION'                        THEN
                            'AE'
                        WHEN 'ALCOHOL'                         THEN
                            'AC'
                        WHEN 'ASSAULT'                         THEN
                            'A5'
                        WHEN 'BONDING'                         THEN
                            'AE'
                        WHEN 'COMMONDISASTER'                  THEN
                            '31'
                        WHEN 'COMMON DISASTER'                 THEN
                            '31'
                        WHEN 'DRUGS'                           THEN
                            'AD'
                        WHEN 'FOSTER'                          THEN
                            'AE'
                        WHEN 'MATERNITY'                       THEN
                            'AE'
                        WHEN 'MENTAL'                          THEN
                            'AA'
                        WHEN 'MISSING INSURED / DISAPPEARANCE' THEN
                            '33'
                        WHEN 'MOTOR VEHICLE'                   THEN
                            'A2'
                        WHEN 'MOTORCYCLE'                      THEN
                            'A2'
                        WHEN 'NERVOUS'                         THEN
                            'AB'
                        WHEN 'SICKNESS'                        THEN
                            'AE'
                        WHEN 'SUICIDE'                         THEN
                            'SU'
                        WHEN 'UNKNOWN / UNDETERMINED'          THEN
                            'UN'
                        WHEN 'UNKNOWN / UNDETER '              THEN
                            'UN'
                        WHEN 'WAR / TERRORISM'                 THEN
                            '40'
                        WHEN 'WELLNESS'                        THEN
                            'WL'
                        ELSE
                            'UN'
                    END
                IN ( 'A1', 'A2', 'A3', 'A4', 'A5',
                     'A6' ) THEN
                    d_grp_claim_eligibility_r_claims.n_elim_period_acc_r
                ELSE
                    d_grp_claim_eligibility_r_claims.n_elim_period_sick_r
            END                                                      AS ellimination_period,
            CASE
                WHEN d_grp_policy_dir_r_policy.v_policy_prefix_r = 'VAI' THEN
                    d_grp_claim_detail_r_claim.d_date_of_event_r
                ELSE
                    d_grp_claim_detail_r_claim.d_date_of_loss_r
            END                                                      AS loss_date,
            d_grp_eeoc_r.v_code_r                                    AS occupation_code,
            d_grp_eeoc_r.v_description_r                             AS occupation_decription,
            d_grp_claim_eligibility_r_claims.d_plan_dur_date_r       AS plan_duration_date,
            d_grp_claim_detail_r_claim.d_return_to_mod_wkdt_r        AS modified_rtw_date,
            d_grp_claim_detail_r_claim.d_return_to_work_date_r       AS return_to_work_date,
           max( CASE
                WHEN d_grp_product_r_claims_disability.v_coverage_type_code_r = '1' THEN
                    'LTD'
                WHEN d_grp_product_r_claims_disability.v_coverage_type_code_r = '2' THEN
                    'STD'
                WHEN d_grp_product_r_claims_disability.v_coverage_type_code_r IN ( '1', '2' ) THEN
                    'Disability (LTD )'
                WHEN d_grp_product_r_claims_life.v_coverage_type_code_r = '3'       THEN
                    'Life'
                WHEN d_grp_product_r_claims_life.v_coverage_category_r = 'Life - Annuity'
                     AND d_grp_product_r_claims_life.v_coverage_type_code_r = '3' THEN
                    'Life - Annuity'
                WHEN d_grp_product_r_claims_life.v_coverage_category_r = 'Life - Non-Annuity'
                     AND d_grp_product_r_claims_life.v_coverage_type_code_r = '3' THEN
                    'Life - Non-Annuity'
                WHEN d_grp_product_r_claims_life.v_coverage_type_code_r = '3'
                     AND NOT ( d_grp_product_r_claims_life.v_coverage_code_r LIKE '%WP%'
                               OR d_grp_product_r_claims_life.v_coverage_code_r LIKE 'GAN%'
                               OR d_grp_product_r_claims_life.v_coverage_code_r LIKE 'CD%' ) THEN
                    'Group Life'
            END       )                                               AS coverage_type,
          max(  CASE
                WHEN d_grp_claim_dir_r_claim.v_lob_type_r IN ( 'LIFE', 'NONS', 'WOP' ) THEN
                    d_grp_claim_coverage_group_r_claims.v_class_id_r
                ELSE
                    d_grp_claim_coverage_r_claims.v_class_id_r
            END             )                                         AS claim_class_id,
                    d_grp_claim_detail_r_claim.d_date_of_loss_r + CASE
                WHEN d_grp_claim_eligibility_r_claims.n_elim_period_r <> ''
                     OR d_grp_claim_eligibility_r_claims.n_elim_period_r <> 0 THEN
                    d_grp_claim_eligibility_r_claims.n_elim_period_r
                WHEN
                    CASE d_grp_claim_event_dir_r_claim.v_event_cause_r
                        WHEN 'ACCIDENT'                        THEN
                            'A6'
                        WHEN 'ACCIDENT - AVIATION'             THEN
                            'A3'
                        WHEN 'ACCIDENT- AVIATION'              THEN
                            'A3'
                        WHEN 'ACCIDENT - OCCUPATIONAL'         THEN
                            'A1'
                        WHEN 'ACCIDENT- OCCUPATIONAL'          THEN
                            'A1'
                        WHEN 'ACCIDENT- OTHER'                 THEN
                            'A6'
                        WHEN 'ACCIDENT - OTHER'                THEN
                            'A6'
                        WHEN 'ACCIDENT - SPORTS'               THEN
                            'A4'
                        WHEN 'ACCIDENT- SPORTS'                THEN
                            'A4'
                        WHEN 'ADOPTION'                        THEN
                            'AE'
                        WHEN 'ALCOHOL'                         THEN
                            'AC'
                        WHEN 'ASSAULT'                         THEN
                            'A5'
                        WHEN 'BONDING'                         THEN
                            'AE'
                        WHEN 'COMMONDISASTER'                  THEN
                            '31'
                        WHEN 'COMMON DISASTER'                 THEN
                            '31'
                        WHEN 'DRUGS'                           THEN
                            'AD'
                        WHEN 'FOSTER'                          THEN
                            'AE'
                        WHEN 'MATERNITY'                       THEN
                            'AE'
                        WHEN 'MENTAL'                          THEN
                            'AA'
                        WHEN 'MISSING INSURED / DISAPPEARANCE' THEN
                            '33'
                        WHEN 'MOTOR VEHICLE'                   THEN
                            'A2'
                        WHEN 'MOTORCYCLE'                      THEN
                            'A2'
                        WHEN 'NERVOUS'                         THEN
                            'AB'
                        WHEN 'SICKNESS'                        THEN
                            'AE'
                        WHEN 'SUICIDE'                         THEN
                            'SU'
                        WHEN 'UNKNOWN / UNDETERMINED'          THEN
                            'UN'
                        WHEN 'UNKNOWN / UNDETER '              THEN
                            'UN'
                        WHEN 'WAR / TERRORISM'                 THEN
                            '40'
                        WHEN 'WELLNESS'                        THEN
                            'WL'
                        ELSE
                            'UN'
                    END
                IN ( 'A1', 'A2', 'A3', 'A4', 'A5',
                     'A6' ) THEN
                    d_grp_claim_eligibility_r_claims.n_elim_period_acc_r
                ELSE
                    d_grp_claim_eligibility_r_claims.n_elim_period_sick_r
            END
               AS disability_start_date,
            d_grp_claim_dir_r_claim.V_PRIVACY_INDICATOR_R as PRIVACY_INDICATOR
            ,NULL CURRENT_RESERVE
			,d_grp_policy_dir_r_policy.T_POLICY_EFFECTIVE_DATE_R 
		FROM
            (
                (
                    (
                             dim_grp_policy_dir_r d_grp_policy_dir_r_policy
                        INNER JOIN dim_grp_claim_dir_r            d_grp_claim_dir_r_claim ON d_grp_policy_dir_r_policy.n_policy_sk_r = d_grp_claim_dir_r_claim.n_policy_sk_r
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
                        LEFT OUTER JOIN (
                            SELECT
                                *
                            FROM
                                fct_grp_worksheet
                            WHERE
                                v_rpt_worksheet_indicator_r = 'Y'
                        )                              f_grp_worksheet_claims_coveragegroup
                   ON d_grp_claim_dir_r_claim.n_claim_sk_r = f_grp_worksheet_claims_coveragegroup.n_claim_sk_r
                    )
                    INNER JOIN dim_grp_claim_detail_r         d_grp_claim_detail_r_claim
                   ON d_grp_claim_detail_r_claim.n_claim_sk_r = d_grp_claim_dir_r_claim.n_claim_sk_r
                )
                LEFT OUTER JOIN dim_grp_party_r                d_grp_party_r_claims
                   ON d_grp_claim_detail_r_claim.n_insrd_party_sk_r = d_grp_party_r_claims.n_party_sk_r
            ),
            fct_grp_policy_r               f_grp_policy_r_policy
                  ,
            (
                SELECT
                    *
                FROM
                    fct_grp_transactions_r
                WHERE
                    n_claim_sk_r <> - 1
            )                              f_grp_transactions_r_claims
                  , ( (
                (
                    (
                        (
                            (
                                dim_grp_claim_coverage_r       d_grp_claim_coverage_r_claims
                                LEFT OUTER JOIN (
                                    dim_grp_claim_coverage_group_r d_grp_claim_coverage_group_r_claims
                                    LEFT OUTER JOIN mvw_product_sk_lookup_tbl      vw_product_sk_lookup_for_life
                   ON d_grp_claim_coverage_group_r_claims.n_claim_sk_r = vw_product_sk_lookup_for_life.n_claim_sk_r
                                                                                                               AND d_grp_claim_coverage_group_r_claims.v_claim_coverage_code_r = vw_product_sk_lookup_for_life.v_claim_coverage_code_r
                                ) ON d_grp_claim_coverage_group_r_claims.n_claim_coverage_sk_r = d_grp_claim_coverage_r_claims.n_claim_coverage_sk_r
                            )
                            LEFT OUTER JOIN dim_grp_product_r              d_grp_product_r_claims_life
                   ON d_grp_product_r_claims_life.n_product_sk_r = vw_product_sk_lookup_for_life.n_product_sk_r
                        )
                        LEFT OUTER JOIN mvw_product_sk_lookup_tbl      vw_product_sk_lookup_for_disablity
                   ON d_grp_claim_coverage_r_claims.n_claim_sk_r = vw_product_sk_lookup_for_disablity.n_claim_sk_r
                                                                                                        AND d_grp_claim_coverage_r_claims.v_claim_coverage_code_r = vw_product_sk_lookup_for_disablity.v_claim_coverage_code_r
                    )
                    LEFT OUTER JOIN dim_grp_product_r              d_grp_product_r_claims_disability
                   ON vw_product_sk_lookup_for_disablity.n_product_sk_r = d_grp_product_r_claims_disability.n_product_sk_r
                )
                LEFT OUTER JOIN dim_grp_claim_eligibility_r    d_grp_claim_eligibility_r_claims
                   ON d_grp_claim_eligibility_r_claims.n_claim_coverage_sk_r = CASE
                                                                                                                                                               WHEN
                                                                                                                                                               d_grp_claim_eligibility_r_claims.n_claim_coverage_sk_r <> - 1
                                                                                                                                                               THEN
                                                                                                                                                                   d_grp_claim_coverage_r_claims.n_claim_coverage_sk_r
                                                                                                                                                               ELSE
                                                                                                                                                                   - 1
                                                                                                                                                           END
                                                                                                AND d_grp_claim_eligibility_r_claims.n_claim_sk_r = d_grp_claim_coverage_r_claims.n_claim_sk_r
            ) )
            , dim_grp_claim_event_r          d_grp_claim_event_r_claim
            LEFT OUTER JOIN dim_grp_eeoc_r                 d_grp_eeoc_r ON d_grp_claim_event_r_claim.v_eeoc_code_r = d_grp_eeoc_r.v_code_r,
            dim_grp_claim_event_dir_r      d_grp_claim_event_dir_r_claim
        WHERE
            ( d_grp_claim_coverage_r_claims.n_claim_sk_r = d_grp_claim_detail_r_claim.n_claim_sk_r )
            AND ( d_grp_policy_dir_r_policy.n_policy_sk_r = f_grp_policy_r_policy.n_policy_sk_r
                  AND d_grp_policy_dir_r_policy.n_policy_version_number_r = f_grp_policy_r_policy.n_version_number_r
                  AND d_grp_claim_detail_r_claim.n_claim_event_sk_r = d_grp_claim_event_r_claim.n_claim_event_sk_r
                  AND d_grp_claim_dir_r_claim.n_claim_sk_r = f_grp_transactions_r_claims.n_claim_sk_r
                  AND d_grp_claim_detail_r_claim.n_claim_event_sk_r = d_grp_claim_event_r_claim.n_claim_event_sk_r
                  AND d_grp_claim_event_r_claim.n_claim_event_sk_r = d_grp_claim_event_dir_r_claim.n_claim_event_sk_r
                  AND d_grp_policy_dir_r_policy.v_active_status_r = 'Y'
                  AND nvl(d_grp_claim_eligibility_r_claims.v_active_status_r, 'Y') = 'Y'
                  AND nvl(d_grp_claim_coverage_group_r_claims.v_active_status_r, 'Y') = 'Y'
                  AND d_grp_claim_coverage_r_claims.v_active_status_r = 'Y'
                  AND d_grp_claim_detail_r_claim.v_active_status_r = 'Y'
                  AND d_grp_claim_dir_r_claim.v_active_status_r = 'Y'
                  AND d_grp_claim_event_r_claim.v_active_status_r = 'Y'
                  AND d_grp_claim_event_dir_r_claim.v_active_status_r = 'Y'
                  AND nvl(d_grp_eeoc_r.v_active_status_r, 'Y') = 'Y'
                  AND d_grp_claim_dir_r_claim.v_lob_type_r IN ( 'LTD', 'STD', 'VPL', 'VPS' )
                   )
        GROUP BY
            d_grp_policy_dir_r_policy.n_policy_sk_r,
            d_grp_claim_dir_r_claim.n_claim_sk_r,
            d_grp_claim_dir_r_claim.v_claim_number_r , 
            d_grp_policy_dir_r_policy.v_policy_prefix_r,
            d_grp_policy_dir_r_policy.v_policy_suffix_r,
            f_grp_policy_r_policy.V_ADMINISTERED_BY_R ,
            CASE
                WHEN d_grp_claim_dir_r_claim.v_lob_type_r IN ( 'LTD', 'STD', 'VPL', 'VPS' ) THEN
                        d_grp_claim_detail_r_claim.d_closure_date_r
            END,
            CAST(TO_DATE(substr(f_grp_transactions_r_claims.v_dc_timestamp_r, 1, 8),
                'YYYYMMDD') AS DATE),
            d_grp_claim_dir_r_claim.v_claim_number_r,
            d_grp_busobj_audit_r.received_date,
            CASE
                    WHEN d_grp_claim_dir_r_claim.v_lob_type_r IN ( 'LTD', 'LTD-Small', 'VLT', 'VPL' ) THEN
                        'M'
                    WHEN d_grp_claim_dir_r_claim.v_lob_type_r IN ( 'DBL', 'STD', 'STD-Small', 'VPS' ) THEN
                        'W'
                    WHEN NOT d_grp_claim_eligibility_r_claims.n_waiver_termination_age_r IS NULL THEN
                        'A'
                    ELSE
                        NULL
            END,
            CASE
                WHEN d_grp_claim_dir_r_claim.v_lob_type_r                     IN ('STD','VPS' )
                THEN case when d_grp_claim_eligibility_r_claims.v_benefit_duration_r is not null
                then d_grp_claim_eligibility_r_claims.v_benefit_duration_r
                ELSE To_Char(ROUND(((d_grp_claim_eligibility_r_claims.d_plan_dur_date_r - d_grp_party_r_claims.D_BIRTH_DATE_R + 1) /365.25)*12,0 ))
                END
                WHEN d_grp_claim_dir_r_claim.v_lob_type_r                     IN ('LTD','VPL' )
                THEN CASE when  f_grp_worksheet_claims_coveragegroup.D_BENEFIT_START_R is not null
                THEN to_char(ROUND((d_grp_claim_eligibility_r_claims.d_plan_dur_date_r - f_grp_worksheet_claims_coveragegroup.d_benefit_start_r + 1) / 30.45, 0))
                ELSE to_char(ROUND(((d_grp_claim_eligibility_r_claims.d_plan_dur_date_r - d_grp_party_r_claims.D_BIRTH_DATE_R ) /365.25)*12,0 ))
                END
                WHEN d_grp_claim_dir_r_claim.v_lob_type_r                     IN ( 'WOP' )
                            THEN to_char(d_grp_claim_eligibility_r_claims.n_waiver_termination_age_r)
                WHEN d_grp_claim_dir_r_claim.v_lob_type_r                     IN ( 'NONS' )
                THEN case when d_grp_claim_eligibility_r_claims.n_elim_period_r is null then
                To_char(lpad(ROUND(((d_grp_claim_eligibility_r_claims.d_plan_dur_date_r - d_grp_claim_detail_r_claim.d_date_of_loss_r) / 365.25) * 12), 3, '0'))
                else To_char(lpad(ROUND(((d_grp_claim_eligibility_r_claims.d_plan_dur_date_r- (d_grp_claim_detail_r_claim.d_date_of_loss_r+d_grp_claim_eligibility_r_claims.n_elim_period_r))         / 365.25) * 12), 3, '0'))
                end
              ELSE NULL END,
            CASE
                    WHEN d_grp_claim_eligibility_r_claims.n_elim_period_r <> ''
                         OR d_grp_claim_eligibility_r_claims.n_elim_period_r <> 0 THEN
                        d_grp_claim_eligibility_r_claims.n_elim_period_r
                    WHEN
                        CASE d_grp_claim_event_dir_r_claim.v_event_cause_r
                            WHEN 'ACCIDENT'                        THEN
                                'A6'
                            WHEN 'ACCIDENT - AVIATION'             THEN
                                'A3'
                            WHEN 'ACCIDENT- AVIATION'              THEN
                                'A3'
                            WHEN 'ACCIDENT - OCCUPATIONAL'         THEN
                                'A1'
                            WHEN 'ACCIDENT- OCCUPATIONAL'          THEN
                                'A1'
                            WHEN 'ACCIDENT- OTHER'                 THEN
                                'A6'
                            WHEN 'ACCIDENT - OTHER'                THEN
                                'A6'
                            WHEN 'ACCIDENT - SPORTS'               THEN
                                'A4'
                            WHEN 'ACCIDENT- SPORTS'                THEN
                                'A4'
                            WHEN 'ADOPTION'                        THEN
                                'AE'
                            WHEN 'ALCOHOL'                         THEN
                                'AC'
                            WHEN 'ASSAULT'                         THEN
                                'A5'
                            WHEN 'BONDING'                         THEN
                                'AE'
                            WHEN 'COMMONDISASTER'                  THEN
                                '31'
                            WHEN 'COMMON DISASTER'                 THEN
                                '31'
                            WHEN 'DRUGS'                           THEN
                                'AD'
                            WHEN 'FOSTER'                          THEN
                                'AE'
                            WHEN 'MATERNITY'                       THEN
                                'AE'
                            WHEN 'MENTAL'                          THEN
                                'AA'
                            WHEN 'MISSING INSURED / DISAPPEARANCE' THEN
                                '33'
                            WHEN 'MOTOR VEHICLE'                   THEN
                                'A2'
                            WHEN 'MOTORCYCLE'                      THEN
                                'A2'
                            WHEN 'NERVOUS'                         THEN
                                'AB'
                            WHEN 'SICKNESS'                        THEN
                                'AE'
                            WHEN 'SUICIDE'                         THEN
                                'SU'
                            WHEN 'UNKNOWN / UNDETERMINED'          THEN
                                'UN'
                            WHEN 'UNKNOWN / UNDETER '              THEN
                                'UN'
                            WHEN 'WAR / TERRORISM'                 THEN
                                '40'
                            WHEN 'WELLNESS'                        THEN
                                'WL'
                            ELSE
                                'UN'
                        END
                    IN ( 'A1', 'A2', 'A3', 'A4', 'A5',
                         'A6' ) THEN
                        d_grp_claim_eligibility_r_claims.n_elim_period_acc_r
                    ELSE
                        d_grp_claim_eligibility_r_claims.n_elim_period_sick_r
            END,
            CASE
                WHEN d_grp_policy_dir_r_policy.v_policy_prefix_r = 'VAI' THEN
                        d_grp_claim_detail_r_claim.d_date_of_event_r
                ELSE
                    d_grp_claim_detail_r_claim.d_date_of_loss_r
            END,
            d_grp_eeoc_r.v_code_r,
            d_grp_eeoc_r.v_description_r,
            d_grp_claim_eligibility_r_claims.d_plan_dur_date_r,
            d_grp_claim_detail_r_claim.d_return_to_mod_wkdt_r,
            d_grp_claim_detail_r_claim.d_return_to_work_date_r,
            d_grp_claim_dir_r_claim.V_PRIVACY_INDICATOR_R,
                d_grp_claim_detail_r_claim.d_date_of_loss_r + CASE
                WHEN d_grp_claim_eligibility_r_claims.n_elim_period_r <> ''
                     OR d_grp_claim_eligibility_r_claims.n_elim_period_r <> 0 THEN
                    d_grp_claim_eligibility_r_claims.n_elim_period_r
                WHEN
                    CASE d_grp_claim_event_dir_r_claim.v_event_cause_r
                        WHEN 'ACCIDENT'                        THEN
                            'A6'
                        WHEN 'ACCIDENT - AVIATION'             THEN
                            'A3'
                        WHEN 'ACCIDENT- AVIATION'              THEN
                            'A3'
                        WHEN 'ACCIDENT - OCCUPATIONAL'         THEN
                            'A1'
                        WHEN 'ACCIDENT- OCCUPATIONAL'          THEN
                            'A1'
                        WHEN 'ACCIDENT- OTHER'                 THEN
                            'A6'
                        WHEN 'ACCIDENT - OTHER'                THEN
                            'A6'
                        WHEN 'ACCIDENT - SPORTS'               THEN
                            'A4'
                        WHEN 'ACCIDENT- SPORTS'                THEN
                            'A4'
                        WHEN 'ADOPTION'                        THEN
                            'AE'
                        WHEN 'ALCOHOL'                         THEN
                            'AC'
                        WHEN 'ASSAULT'                         THEN
                            'A5'
                        WHEN 'BONDING'                         THEN
                            'AE'
                        WHEN 'COMMONDISASTER'                  THEN
                            '31'
                        WHEN 'COMMON DISASTER'                 THEN
                            '31'
                        WHEN 'DRUGS'                           THEN
                            'AD'
                        WHEN 'FOSTER'                          THEN
                            'AE'
                        WHEN 'MATERNITY'                       THEN
                            'AE'
                        WHEN 'MENTAL'                          THEN
                            'AA'
                        WHEN 'MISSING INSURED / DISAPPEARANCE' THEN
                            '33'
                        WHEN 'MOTOR VEHICLE'                   THEN
                            'A2'
                        WHEN 'MOTORCYCLE'                      THEN
                            'A2'
                        WHEN 'NERVOUS'                         THEN
                            'AB'
                        WHEN 'SICKNESS'                        THEN
                            'AE'
                        WHEN 'SUICIDE'                         THEN
                            'SU'
                        WHEN 'UNKNOWN / UNDETERMINED'          THEN
                            'UN'
                        WHEN 'UNKNOWN / UNDETER '              THEN
                            'UN'
                        WHEN 'WAR / TERRORISM'                 THEN
                            '40'
                        WHEN 'WELLNESS'                        THEN
                            'WL'
                        ELSE
                            'UN'
                    END
                IN ( 'A1', 'A2', 'A3', 'A4', 'A5',
                     'A6' ) THEN
                    d_grp_claim_eligibility_r_claims.n_elim_period_acc_r
                ELSE
                    d_grp_claim_eligibility_r_claims.n_elim_period_sick_r
            END
			,d_grp_policy_dir_r_policy.T_POLICY_EFFECTIVE_DATE_R;