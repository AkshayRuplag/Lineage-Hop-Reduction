-- Cleaned for lineage: PKG_GRP_LOAD_RPT_BILLGROUP_R_PRC_GET_CUR_DATA (part 2/2)

INSERT /*+ APPEND PARALLEL(stg, 8) */ INTO rpt_billgroup_r_exg stg
            SELECT /*+ PARALLEL(8) */ DISTINCT
                dim_grp_billing_pol_billgrp_r.d_billed_to_r                  d_billed_to_r,
                dim_grp_billing_pol_billgrp_r.v_bill_category_value_r        v_billing_category_r,
                dim_grp_billing_pol_billgrp_r.v_billtype_value_r             v_billing_option_r,
                dim_grp_address_dir_r.v_city_r                               v_billgroup_city_r,
                dim_grp_billing_pol_billgrp_r.d_delete_date_r                d_billgroup_delete_date_r,
                dim_grp_billing_pol_billgrp_r.d_effective_date_r             d_billgroup_effective_date_r,
                dim_grp_billing_pol_billgrp_r.v_insert_by_r                  v_billgroup_insert_by_r,
                dim_grp_billing_pol_billgrp_r.d_record_insert_date_r         d_billgroup_insert_date_r,
                dim_grp_customer_bill_group_r.v_bill_group_description_r     v_billgroup_description_r,
                dim_grp_customer_bill_group_r.v_customer_bill_group_number_r v_customer_billgroup_number_r,
                dim_grp_billing_pol_billgrp_r.d_paid_to_r                    d_paid_to_r,
                dim_grp_billing_pol_billgrp_r.d_record_end_date_r            d_record_end_date_r,
                dim_grp_billing_pol_billgrp_r.d_record_start_date_r          d_record_start_date_r,
                dim_grp_customer_bill_group_r.v_state_name_r                 v_billgroup_state_r,
                dim_grp_billing_pol_billgrp_r.v_bill_group_status_r          v_billgroup_status_r
                ,
                CAST((
                    CASE
                        WHEN dim_grp_billing_pol_billgrp_r.v_bill_group_status_r = 'Terminated' THEN
                            dim_grp_billing_pol_billgrp_r.d_status_date_r
                    END
                ) AS DATE)                                                   d_billgroup_status_date_r,
                CAST((
                    CASE
                        WHEN dim_grp_billing_pol_billgrp_r.v_bill_group_status_r = 'Terminated' THEN
                            NULL
			     /*(THEN DIM_GRP_BILLING_POL_BILLGRP_R.V_STATUS_REASON_R*/
                        ELSE
                            NULL
                    END
                ) AS DATE)                                                   v_billgroup_termination_date_r,
                dim_grp_billing_pol_billgrp_r.v_update_by_r                  v_billgroup_update_by_r,
                dim_grp_billing_pol_billgrp_r.d_update_date_r                d_billgroup_update_date_r,
                dim_grp_address_dir_r.v_postal_zip_r                         v_billgroup_postal_zip_r,
                dim_grp_billing_pol_billgrp_r.v_premium_mode1_r              v_billgroup_premium_mode_r,
                dim_grp_billing_pol_billgrp_r.v_billing_on_hold_ind_r        v_billing_on_hold_ind_r,
                nvl(fct_grp_billing_policy_dtl_r.v_state_r, ' ')             v_state_r,
                dim_grp_billing_pol_billgrp_r.n_grace_period_r               n_grace_period_r,
                (
                    CASE
                        WHEN dim_grp_billing_pol_billgrp_r.d_paid_to_r = dim_grp_billing_pol_billgrp_r.d_effective_date_r THEN
                            'Y'
                        ELSE
                            'N'
                    END
                )                                                            v_billgroup_payment_status_r,
                dim_grp_billing_pol_billgrp_r.n_policy_billgroup_id_r        n_policy_billgroup_id_r,
                dim_grp_billing_pol_billgrp_r.n_policy_billgroup_sk_r        n_billgroup_sk_r
                ,
                gn_current_month                                             n_reportmonth_r 
                ,
                gc_getcur_loadedby                                           v_last_modified_by_r,
                gd_sysdate                                                   t_creation_date_r,
                gc_getcur_loadedby                                           v_created_by_r,
                gd_sysdate                                                   t_last_modified_date_r,
                'Y'                                                          v_rpt_active_status_r,
                to_number(to_char(gd_sysdate, 'YYYYMMDD'))                   n_batch_id_r,
                CASE
                    WHEN dim_grp_billing_pol_billgrp_r.v_bill_group_status_r = 'Terminated'
                         AND dim_grp_billing_pol_billgrp_r.d_paid_to_r >= CASE
                                                                              WHEN dim_grp_billing_pol_billgrp_r.v_bill_group_status_r =
                                                                              'Terminated' THEN
                                                                                  dim_grp_billing_pol_billgrp_r.d_status_date_r
                                                                              ELSE
                                                                                  TO_DATE('9999-12-31', 'YYYY-MM-DD')
                                                                          END THEN
                        'Team R'
                    ELSE
                        fct_grp_policy_r_pbc_team_lookup.v_pbc_team_name_r
                END                                                          AS v_pbc_team_name_r,
                CASE
                    WHEN dim_grp_billing_pol_billgrp_r.v_bill_group_status_r = 'Terminated'
                         AND dim_grp_billing_pol_billgrp_r.d_paid_to_r >= CASE
                                                                              WHEN dim_grp_billing_pol_billgrp_r.v_bill_group_status_r =
                                                                              'Terminated' THEN
                                                                                  dim_grp_billing_pol_billgrp_r.d_status_date_r
                                                                              ELSE
                                                                                  TO_DATE('9999-12-31', 'YYYY-MM-DD')
                                                                          END THEN
                        'FER'
                    ELSE
                        fct_grp_policy_r_pbc_team_lookup.v_pbc_sub_team_r
                END                                                          AS v_pbc_sub_team_r
                ,
                dim_grp_address_dir_r.v_addressline1_r                       AS v_billgroup_addressline1_r,
                dim_grp_address_dir_r.v_addressline2_r                       AS v_billgroup_addressline2_r,
                dim_grp_address_dir_r.v_addressline3_r                       AS v_billgroup_addressline3_r
                ,dim_grp_billing_pol_billgrp_r.v_source_system_name_r 
            FROM
                (
                    SELECT
                        *
                    FROM
                        dim_grp_billing_pol_billgrp_r
                    WHERE
                        v_source_system_name_r <> 'APS'
                ) dim_grp_billing_pol_billgrp_r   
                LEFT JOIN (
                    SELECT
                        *
                    FROM
                        dim_grp_customer_bill_group_r
                    WHERE
						v_source_system_name_r NOT IN ( 'APS', 'EIS' )
                       AND v_active_status_r = 'Y'
                ) dim_grp_customer_bill_group_r ON dim_grp_customer_bill_group_r.v_active_status_r = 'Y'
                                                   AND dim_grp_billing_pol_billgrp_r.n_customer_billgroup_id_r = dim_grp_customer_bill_group_r.
                                                   n_customer_billgroup_id_r
                INNER JOIN fct_grp_billing_policy_dtl_r ON fct_grp_billing_policy_dtl_r.n_policy_sk_r = dim_grp_billing_pol_billgrp_r.
                n_policy_sk_r
                INNER JOIN dim_grp_policy_dir_r ON dim_grp_policy_dir_r.n_policy_sk_r = dim_grp_billing_pol_billgrp_r.n_policy_sk_r
                LEFT JOIN fct_grp_policy_r_pbc_team_lookup ON dim_grp_policy_dir_r.n_policy_sk_r = fct_grp_policy_r_pbc_team_lookup.n_policy_sk_r
                                                              AND dim_grp_policy_dir_r.n_policy_version_number_r = fct_grp_policy_r_pbc_team_lookup.
                                                              n_version_number_r
                LEFT JOIN (
                    SELECT
                        *
                    FROM
                        dim_grp_address_dir_r
                    WHERE
                        v_source_system_name_r NOT IN ( 'PACS', 'APS' )
                ) dim_grp_address_dir_r
                 ON dim_grp_customer_bill_group_r.n_address_sk_r = dim_grp_address_dir_r.n_address_sk_r
                                           AND dim_grp_address_dir_r.d_delete_date_r IS NULL
                                           AND dim_grp_address_dir_r.n_address_sk_r NOT IN ( 963289, 680889, 739949, 776519, 705641,
                                                                                             773335, 659988, 746983 )
                                           AND dim_grp_address_dir_r.v_active_status_r = 'Y'
            WHERE
                    dim_grp_billing_pol_billgrp_r.v_active_status_r = 'Y'
                AND dim_grp_policy_dir_r.v_active_status_r = 'Y'
                AND dim_grp_billing_pol_billgrp_r.d_delete_date_r IS NULL 
                ;
        gn_run_cnt := SQL%rowcount;
        COMMIT;
        EXECUTE IMMEDIATE 'ALTER SESSION DISABLE PARALLEL DML';
        gt_end_time := systimestamp;
        gc_trcmsg := '5.3 Data Load Completed for _EXG Table';
		/*START: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
        pkg_grp_log_util.prc_ins_prcs_job_log_message_r
			(
				p_job_id_r                    => gn_out_job_id,
				p_batch_id_r                  => gn_sysdt_batchid,
				p_message_type_r              => gc_message_type_r,
				p_code_location_r             => gc_main_loadedby,
				p_message_r                   => gc_trcmsg,
				p_count_type_r                => 'AUDIT_TARGET_COUNT',
				p_count_r                     => gn_run_cnt,
				p_duration_r                  => fnc_grp_time_duration(gt_start_time,gt_end_time),
				p_created_by_r                => gc_job_name,
				out_prcs_job_log_message_id_r => gn_job_log_message_id_r
			);
    END prc_get_cur_data;