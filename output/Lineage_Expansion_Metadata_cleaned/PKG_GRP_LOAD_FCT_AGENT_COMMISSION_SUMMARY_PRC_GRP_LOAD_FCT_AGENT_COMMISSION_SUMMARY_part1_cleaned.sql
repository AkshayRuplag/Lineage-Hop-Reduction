-- Cleaned for lineage: PKG_GRP_LOAD_FCT_AGENT_COMMISSION_SUMMARY_PRC_GRP_LOAD_FCT_AGENT_COMMISSION_SUMMARY (part 1/2)

INSERT INTO fct_agent_commission_summary (
                v_commission_status_r,
                v_policy_number_r,
                v_bill_group_number_r,
                v_agent_code_r,
                v_template_name_r,
                d_commission_date_r,
                d_due_date_r,
                d_paid_to_date_r,
                v_sales_rep_employee_number_r,
                v_agent_license_r,
                v_commission_type_r,
                n_commission_amount_r,
                fic_mis_date_r,
                n_batch_id_r,
                n_sequence_number_r,
                t_creation_date_r,
                t_event_timestamp_r,
                t_last_modified_date_r,
                v_created_by_r,
                v_last_modified_by_r,
                n_load_run_id_r,
                v_source_system_name_r,
                v_subject_area_type_r,
                n_version_number_r,
                f_physical_delete_r,
                v_change_reason_r,
                n_claim_sk_r,
                n_policy_sk_r,
                n_party_sk_r,
                n_quote_sk_r,
                n_policy_billgroup_sk_r,
                n_agent_sk_r,
                n_yearmonth_r,
                n_cust_party_sk_r,
                v_data_source_name_r 
            )
                SELECT 
                    v_commission_status_r,
                    final_tab.v_policy_number_r,
                    c.v_customer_bill_group_number_r,
                    v_agent_code_r,
                    v_template_name_r,
                    d_commission_date_r,
                    d_due_date_r,
                    d_paid_to_date_r,
                    NULL                                                                AS v_sales_rep_employee_number_r,
                    v_agent_license_r,
                    v_commission_type_r,
                    n_commission_amount_r,
                    ld_sysdate                                                          AS fic_mis_date_r,
                    ln_n_batch_id_r                                                     AS n_batch_id_r,
                    ( ln_max_seq_numer_r + ROWNUM )                                     AS n_sequence_number_r,
                    lt_systimestamp                                                     AS t_creation_date_r,
                    lt_systimestamp                                                     AS t_event_timestamp_r,
                    lt_systimestamp                                                     AS t_last_modified_date_r,
                    'ODI'                                                               AS v_created_by_r,
                    'ODI'                                                               AS v_last_modified_by_r,
                    ln_n_load_run_id_r                                                  AS n_load_run_id_r,
                    tab_policy_sk.v_source_system_name_r                                AS v_source_system_name_r,
                    'ODI'                                                               AS v_subject_area_type_r,
                    1                                                                   AS n_version_number_r,
                    NULL                                                                AS f_physical_delete_r,
                    NULL                                                                AS v_change_reason_r,
                    - 1                                                                 AS n_claim_sk_r,
                    (
                        CASE
                            WHEN tab_policy_sk.n_policy_sk_r IS NULL THEN
                                - 1
                            ELSE
                                tab_policy_sk.n_policy_sk_r
                        END
                    )                                                                   AS n_policy_sk_r,
                    - 1                                                                 AS n_party_sk_r,
                    - 1                                                                 AS n_quote_sk_r,
                    nvl(nvl(b.n_policy_billgroup_sk_r, d.n_policy_billgroup_sk_r), - 1) AS n_policy_billgroup_sk_r,
                    nvl(n_agent_sk_r, - 1)                                              AS n_agent_sk_r,
                    ln_yearmonth                                                        AS n_yearmonth_r,
                    nvl(f.n_cust_party_sk_r, - 1)                                       AS n_cust_party_sk_r,
                    final_tab.v_data_source_name_r                                      AS v_data_source_name_r 
                FROM
                    (
                        SELECT
                            p.v_policy_number_r          AS v_policy_number_r,
                            tab3.v_agent_number_r        AS v_agent_code_r,
                            tab4.v_template_name_r,
                            tab5.d_insert_date_r         d_commission_date_r,
                            tab5.d_prev_paid_to_date_r   AS d_due_date_r,
                            CAST('' AS DATE)             AS d_paid_to_date_r,
                            ''                           v_agent_license_r,
                            (
                                CASE
                                    WHEN substr(tab4.v_template_name_r, 3, 1) = 'A' THEN
                                        'A'
                                    WHEN substr(tab4.v_template_name_r, 3, 1) = 'O' THEN
                                        'O'
                                    WHEN substr(tab4.v_template_name_r, 2, 1) IN ( 'H', 'C' ) THEN
                                        'C'
                                    WHEN substr(tab4.v_template_name_r, 3, 1) = 'W' THEN
                                        NULL
                                    ELSE
                                        'M'
                                END
                            )                            AS v_commission_type_r,
                            tab5.n_commission_r          AS n_commission_amount_r,
                            (
                                CASE
                                    WHEN tab5.n_do_not_pay_r = 0  THEN
                                        'Open'
                                    WHEN tab5.n_do_not_pay_r = 1  THEN
                                        'Paid'
                                    WHEN tab5.n_do_not_pay_r IN ( 2, 3, 9, 12, 51,
                                                                  59, 99, 61 ) THEN
                                        'Pending'
                                    WHEN tab5.n_do_not_pay_r = 7  THEN
                                        'Terminated and not vested'
                                    WHEN tab5.n_do_not_pay_r = 52 THEN
                                        'No check/Non-monetary bonus'
                                    WHEN tab5.n_do_not_pay_r IN ( 17, 25, 18, 23 ) 
                                     THEN
                                        'Void and Close Liability'
                                    WHEN tab5.n_do_not_pay_r IN ( 30 ) 
                                     THEN
                                        'Void and Replace'
                                    WHEN tab5.n_do_not_pay_r IN ( 35, 36, 37, 38 ) THEN
                                        'Void and Open Liability'
                                    WHEN tab5.n_do_not_pay_r = 29 THEN
                                        'Paid'
                                    ELSE
                                        'Other'
                                END
                            )                            AS v_commission_status_r,
                            tab5.n_statement_detail_id_r AS id,
                            tab5.n_policy_billgroup_id_r AS n_policy_billgroup_id_r,
                            tab4.n_agent_sk_r            AS n_agent_sk_r,
                            tab5.v_source_system_name_r  AS v_data_source_name_r 
                        FROM
                                 (
                                SELECT
                                    *
                                FROM
                                    dim_grp_statement_detail_r
                                WHERE
                                    v_active_status_r = 'Y'
                            ) tab5
                            INNER JOIN (
                                SELECT
                                    *
                                FROM
                                    dim_grp_statement_r
                                WHERE
                                    v_active_status_r = 'Y'
                            ) s ON tab5.n_statement_id_r = s.n_statement_id_r and tab5.v_source_system_name_r = s.v_source_system_name_r
                            INNER JOIN (
                                SELECT
                                    *
                                FROM
                                    dim_grp_agent_r
                                WHERE
                                    v_active_status_r = 'Y'
                            ) tab3 ON s.n_entity_id_r = tab3.v_agent_id_r
                                      AND s.n_entity_type_id_r = 500
                            INNER JOIN (
                                SELECT
                                    *
                                FROM
                                    dim_grp_policy_dir_r
                                WHERE
                                    v_active_status_r = 'Y'
                            ) p ON tab5.n_policy_sk_r = p.n_policy_sk_r
                            LEFT JOIN (
                                SELECT
                                    *
                                FROM
                                    dim_grp_agent_contract_tmplt_r
                                WHERE
                                    v_active_status_r = 'Y'
                            ) tab4 ON tab5.n_template_id_r = tab4.n_contract_template_id_r
                                      AND tab5.n_policy_sk_r = tab4.n_policy_sk_r
                                      AND tab3.n_agent_sk_r = tab4.n_agent_sk_r
                        WHERE
                            substr(tab4.v_template_name_r, 3, 1) <> 'W'
                        UNION
                        SELECT
                            p.v_policy_number_r        v_policy_number_r,
                            ag.v_agent_number_r        v_agent_code_r,
                            a.v_bonus_template_name_r  v_template_name_r,
                            a.d_record_start_date_r    d_commission_date_r,
                            CAST('' AS DATE)           d_due_date_r,
                            CAST('' AS DATE)           d_paid_to_date_r,
                            ''                         v_agent_license_r,
                            'M'                        v_commission_type_r,
                            (
                                CASE
                                    WHEN a.n_do_not_pay_r IN ( 17, 25, 18, 23, 35,
                                                               36, 37, 38 ) 
                                                                THEN
                                        ( a.n_commission_r * - 1 )
                                    ELSE
                                        a.n_commission_r
                                END
                            )                          AS n_commission_amount_r,
                            CASE
                                WHEN a.n_do_not_pay_r = 0  THEN
                                    'Open'
                                WHEN a.n_do_not_pay_r = 1  THEN
                                    'Paid'
                                WHEN a.n_do_not_pay_r IN ( 2, 3, 9, 12, 51,
                                                           59, 99, 61 ) THEN
                                    'Pending'
                                WHEN a.n_do_not_pay_r = 7  THEN
                                    'Terminated and not vested'
                                WHEN a.n_do_not_pay_r = 52 THEN
                                    'No check/Non-monetary bonus'
                                WHEN a.n_do_not_pay_r IN ( 17, 25, 18, 23 ) 
                                 THEN
                                    'Void and Close Liability'
                                WHEN a.n_do_not_pay_r IN ( 35, 36, 37, 38 ) THEN
                                    'Void and Open Liability'
                                WHEN a.n_do_not_pay_r = 29 THEN
                                    'Paid'
                                ELSE
                                    'Other'
                            END                        v_commission_status_r,
                            1                          AS id,
                            sd.n_policy_billgroup_id_r AS n_policy_billgroup_id_r,
                            ag.n_agent_sk_r            AS n_agent_sk_r,
                            'APS'                      AS v_data_source_name_r 
                        FROM
                                 (
                                SELECT
                                    *
                                FROM
                                    dim_grp_person_maca_stmt_r
                                WHERE
                                    v_active_status_r = 'Y'
                            ) a
                            INNER JOIN (
                                SELECT
                                    *
                                FROM
                                    atomic.dim_grp_agent_r
                                WHERE
                                    v_active_status_r = 'Y'
                            ) ag
                             ON CASE 
                                        WHEN a.n_is_multiple_ytd_r = 1 THEN
                                            a.v_agent_id_r 
                                        ELSE
                                            to_char(a.n_primary_agent_id_r)
                                    END = ag.v_agent_id_r  
                            INNER JOIN (
                                SELECT
                                    *
                                FROM
                                    dim_grp_policy_dir_r
                                WHERE
                                    v_active_status_r = 'Y'
                            ) p ON a.n_policy_sk_r = p.n_policy_sk_r
                            LEFT JOIN (
                                SELECT DISTINCT
                                    n_policy_sk_r,
                                    n_policy_billgroup_id_r
                                FROM
                                    (
                                        SELECT
                                            n_policy_sk_r,
                                            n_policy_billgroup_id_r,
                                            RANK()
                                            OVER(PARTITION BY n_policy_sk_r
                                                 ORDER BY
                                                     d_insert_date_r ASC, n_policy_billgroup_id_r ASC
                                            ) rnk
                                        FROM
                                            dim_grp_statement_detail_r
                                        WHERE
                                                v_active_status_r = 'Y'
                                            AND n_policy_billgroup_id_r IS NOT NULL
                                    )
                                WHERE
                                    rnk = 1
                            ) sd ON a.n_policy_sk_r = sd.n_policy_sk_r 
                        WHERE
                            a.n_do_not_pay_r IN ( 1 )
                        UNION   
                        SELECT
                            p.v_policy_number_r        v_policy_number_r,
                            ag.v_agent_number_r        v_agent_code_r,
                            a.v_bonus_template_name_r  v_template_name_r,
                            a.d_record_start_date_r    d_commission_date_r,
                            CAST('' AS DATE)           d_due_date_r,
                            CAST('' AS DATE)           d_paid_to_date_r,
                            ''                         v_agent_license_r,
                            'M'                        v_commission_type_r,
                            (
                                CASE
                                    WHEN a.n_do_not_pay_r IN ( 17, 25, 18, 23, 35,
                                                               36, 37, 38 ) 
                                                                THEN
                                        ( a.n_commission_r * - 1 )
                                    ELSE
                                        a.n_commission_r
                                END
                            )                          AS n_commission_amount_r,
                            CASE
                                WHEN a.n_do_not_pay_r = 0  THEN
                                    'Open'
                                WHEN a.n_do_not_pay_r = 1  THEN
                                    'Paid'
                                WHEN a.n_do_not_pay_r IN ( 2, 3, 9, 12, 51,
                                                           59, 99, 61 ) THEN
                                    'Pending'
                                WHEN a.n_do_not_pay_r = 7  THEN
                                    'Terminated and not vested'
                                WHEN a.n_do_not_pay_r = 52 THEN
                                    'No check/Non-monetary bonus'
                                WHEN a.n_do_not_pay_r IN ( 17, 25, 18, 23 ) 
                                 THEN
                                    'Void and Close Liability'
                                WHEN a.n_do_not_pay_r IN ( 35, 36, 37, 38 ) THEN
                                    'Void and Open Liability'
                                WHEN a.n_do_not_pay_r = 29 THEN
                                    'Paid'
                                ELSE
                                    'Other'
                            END                        v_commission_status_r,
                            1                          AS id,
                            sd.n_policy_billgroup_id_r AS n_policy_billgroup_id_r,
                            ag.n_agent_sk_r            AS n_agent_sk_r,
                            'APS'                      AS v_data_source_name_r 
                        FROM
                                 (
                                SELECT
                                    *
                                FROM
                                    dim_grp_person_maca_stmt_r
                                WHERE
                                    v_active_status_r = 'Y'
                            ) a
                            INNER JOIN (
                                SELECT
                                    *
                                FROM
                                    atomic.dim_grp_agent_r
                                WHERE
                                    v_active_status_r = 'Y'
                            ) ag
                             ON CASE 
                                        WHEN a.n_is_multiple_ytd_r = 1 THEN
                                            a.v_agent_id_r
                                        ELSE
                                            to_char(a.n_primary_agent_id_r)
                                    END = ag.v_agent_id_r  
                            INNER JOIN (
                                SELECT
                                    *
                                FROM
                                    dim_grp_policy_dir_r
                                WHERE
                                    v_active_status_r = 'Y'
                            ) p ON a.n_policy_sk_r = p.n_policy_sk_r
                            LEFT JOIN (
                                SELECT DISTINCT
                                    n_policy_sk_r,
                                    n_policy_billgroup_id_r
                                FROM
                                    (
                                        SELECT
                                            n_policy_sk_r,
                                            n_policy_billgroup_id_r,
                                            RANK()
                                            OVER(PARTITION BY n_policy_sk_r
                                                 ORDER BY
                                                     d_insert_date_r ASC, n_policy_billgroup_id_r ASC
                                            ) rnk
                                        FROM
                                            dim_grp_statement_detail_r
                                        WHERE
                                                v_active_status_r = 'Y'
                                            AND n_policy_billgroup_id_r IS NOT NULL
                                    )
                                WHERE
                                    rnk = 1
                            ) sd ON a.n_policy_sk_r = sd.n_policy_sk_r 
                        WHERE
                            a.n_do_not_pay_r IN ( 17, 23, 25, 27 )
                        UNION
                        SELECT
                            p.v_policy_number_r                                           AS v_policy_number_r,
                            tab3.v_agent_number_r                                         AS v_agent_code_r,
                            ''                                                            AS v_template_name_r,
                            tab5.d_insert_date_r                                          d_commission_date_r,
                            tab5.d_prev_paid_to_date_r                                    AS d_due_date_r,
                            CAST('' AS DATE)                                              AS d_paid_to_date_r,
                            ''                                                            v_agent_license_r,
                            'CA'                                                          AS v_commission_type_r,
                            tab5.n_commission_r                                           AS n_commission_amount_r,
                            (
                                CASE
                                    WHEN tab5.n_do_not_pay_r = 0  THEN
                                        'Open'
                                    WHEN tab5.n_do_not_pay_r = 1  THEN
                                        'Paid'
                                    WHEN tab5.n_do_not_pay_r IN ( 2, 3, 9, 12, 51,
                                                                  59, 99, 61 ) THEN
                                        'Pending'
                                    WHEN tab5.n_do_not_pay_r = 7  THEN
                                        'Terminated and not vested'
                                    WHEN tab5.n_do_not_pay_r = 52 THEN
                                        'No check/Non-monetary bonus'
                                    WHEN tab5.n_do_not_pay_r IN ( 17, 25, 18, 23 ) 
                                     THEN
                                        'Void and Close Liability'
                                    WHEN tab5.n_do_not_pay_r IN ( 30 ) 
                                     THEN
                                        'Void and Replace'
                                    WHEN tab5.n_do_not_pay_r IN ( 35, 36, 37, 38 ) THEN
                                        'Void and Open Liability'
                                    WHEN tab5.n_do_not_pay_r = 29 THEN
                                        'Paid'
                                    ELSE
                                        'Other'
                                END
                            )                                                             AS v_commission_status_r,
                            tab5.n_statement_detail_id_r                                  AS id,
                            nvl(tab5.n_policy_billgroup_id_r, sd.n_policy_billgroup_id_r) AS n_policy_billgroup_id_r,
                            tab3.n_agent_sk_r                                             AS n_agent_sk_r,
                            tab5.v_source_system_name_r                                   AS v_data_source_name_r 
                        FROM
                                 (
                                SELECT
                                    *
                                FROM
                                    dim_grp_statement_detail_r
                                WHERE
                                        v_active_status_r = 'Y'
                                    AND n_which_payment_r = 2
                                    AND n_do_not_pay_r = 1
                            ) tab5
                            INNER JOIN (
                                SELECT
                                    *
                                FROM
                                    dim_grp_statement_r
                                WHERE
                                        v_active_status_r = 'Y'
                                    AND n_entity_type_id_r = 500
                            ) s ON tab5.n_statement_id_r = s.n_statement_id_r 
                                and tab5.v_source_system_name_r = s.v_source_system_name_r
                            INNER JOIN (
                                SELECT
                                    *
                                FROM
                                    dim_grp_agent_r
                                WHERE
                                    v_active_status_r = 'Y'
                            ) tab3 ON s.n_entity_id_r = tab3.v_agent_id_r
                                      AND s.n_entity_type_id_r = 500
                            INNER JOIN (
                                SELECT
                                    *
                                FROM
                                    dim_grp_policy_dir_r
                                WHERE
                                    v_active_status_r = 'Y'
                            ) p ON tab5.n_policy_sk_r = p.n_policy_sk_r
                            LEFT JOIN (
                                SELECT DISTINCT
                                    n_policy_sk_r,
                                    n_policy_billgroup_id_r
                                FROM
                                    (
                                        SELECT
                                            n_policy_sk_r,
                                            n_policy_billgroup_id_r,
                                            RANK()
                                            OVER(PARTITION BY n_policy_sk_r
                                                 ORDER BY
                                                     d_insert_date_r ASC, n_policy_billgroup_id_r ASC
                                            ) rnk
                                        FROM
                                            dim_grp_statement_detail_r
                                        WHERE
                                                v_active_status_r = 'Y'
                                            AND n_policy_billgroup_id_r IS NOT NULL
                                    )
                                WHERE
                                    rnk = 1
                            ) sd ON tab5.n_policy_sk_r = sd.n_policy_sk_r
                    )                final_tab
                    LEFT OUTER JOIN (
                        SELECT
                            v_policy_number_r,
                            n_policy_sk_r,
                            n_policy_version_number_r,
                            n_source_system_key_r,
                            v_source_system_name_r,
                            v_orig_policy_number_r
                        FROM
                            dim_grp_policy_dir_r
                        WHERE
                            v_active_status_r = 'Y'
                        GROUP BY
                            v_policy_number_r,
                            n_policy_sk_r,
                            n_policy_version_number_r,
                            n_source_system_key_r,
                            v_source_system_name_r,
                            v_orig_policy_number_r
                    )                tab_policy_sk ON final_tab.v_policy_number_r = tab_policy_sk.v_policy_number_r
                    LEFT JOIN fct_grp_policy_r f ON tab_policy_sk.n_policy_sk_r = f.n_policy_sk_r
                                                    AND tab_policy_sk.n_policy_version_number_r = f.n_version_number_r
                                                    AND tab_policy_sk.n_source_system_key_r = f.n_source_system_key_r
                    LEFT JOIN (
                        SELECT
                            *
                        FROM
                            dim_grp_billing_pol_billgrp_r
                        WHERE
                                v_active_status_r = 'Y'
                            AND v_source_system_name_r in ('APS','MGIS','DDAZ')
                    )                b ON tab_policy_sk.v_policy_number_r = b.v_policy_id_r
                           AND final_tab.n_policy_billgroup_id_r = b.n_policy_billgroup_id_r
                    LEFT JOIN (
                        SELECT
                            *
                        FROM
                            dim_grp_billing_pol_billgrp_r
                        WHERE
                                v_active_status_r = 'Y'
                            AND v_source_system_name_r in ('APS','MGIS','DDAZ')
                    )                d ON final_tab.n_policy_billgroup_id_r = d.n_policy_billgroup_id_r
                           AND tab_policy_sk.v_orig_policy_number_r = d.v_policy_id_r
                    LEFT JOIN (
                        SELECT
                            *
                        FROM
                            dim_grp_customer_bill_group_r
                        WHERE
                                v_active_status_r = 'Y'
                            AND v_source_system_name_r in ('APS','MGIS','DDAZ')
                    )                c ON nvl(b.n_customer_billgroup_id_r, d.n_customer_billgroup_id_r) = c.n_customer_billgroup_id_r;