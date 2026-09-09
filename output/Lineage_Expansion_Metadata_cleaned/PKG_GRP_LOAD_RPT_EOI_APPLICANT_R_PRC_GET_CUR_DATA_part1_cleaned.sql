-- Cleaned for lineage: PKG_GRP_LOAD_RPT_EOI_APPLICANT_R_PRC_GET_CUR_DATA (part 1/1)

INSERT  INTO rpt_eoi_applicant_r_exg stg
      SELECT   
        CAST(NULL AS VARCHAR2(300))       v_applicant_child_first_name_r,
        appl_dtl_insured.d_dob_r              d_applicant_date_of_birth_r,
        appl_dtl_insured.v_first_name_r       v_applicant_first_name_r,
        appl_dtl_insured.v_last_name_r        v_applicant_last_name_r,
        insured.v_member_number_r             v_applicant_member_number_r,
        sysdate - appl_dtl_spouse.d_dob_r     v_applicant_spouse_age_r,
        appl_dtl_spouse.d_dob_r               d_applicant_spouse_date_of_birth_r,
        appl_dtl_spouse.v_first_name_r        v_applicant_spouse_first_name_r,
        appl_dtl_spouse.v_last_name_r         v_applicant_spouse_last_name_r,
        MAX('XXX-XX-' || substr(appl_dtl_insured.v_ssn_r,length(appl_dtl_insured.v_ssn_r)- 3,4))
          AS v_applicant_ssn_r,
        app_cov_dcsn.v_entity_type_r          v_application_entity_type_r,
        eoi_app_hist.d_insert_date_r          d_application_entry_date_r,
        eoi_app.n_application_id_r            n_application_id_r,
        eoi_app.v_queue_r                     v_application_queue_name_r,
        eoi_app.d_received_date_r             d_application_received_date_r,
        eoi_app.v_source_r                    v_application_source_r,
        eoi_trans.v_transaction_description_r v_application_status_r,
        eoi_app.n_s_status_id_r               n_application_status_id_r,
        eoi_app_hist.v_code_r                 v_application_transaction_code_r,
        CASE
          WHEN deah.n_application_id_r IS NULL 
          THEN 'Y'
          ELSE 'N'
        END v_auto_approved_indicator_r,
        MAX(
          CASE
            WHEN app_cov_dcsn.v_entity_type_r = 'CHILD' 
            THEN app_cov_dcsn.d_gi_effective_date_r
          END
          ) d_child_gi_effective_date_r,
        MAX(
          CASE
            WHEN app_cov_dcsn.v_entity_type_r = 'INSURED' 
            THEN app_cov_dcsn.d_excess_effective_date_r
          END
          ) d_employee_excess_effective_date_r,
        MAX(
          CASE
            WHEN app_cov_dcsn.v_entity_type_r = 'INSURED' 
            THEN app_cov_dcsn.d_gi_effective_date_r
          END
          ) d_employee_gi_effective_date_r,
        eoi_app_hist.v_insert_by_r            v_eoi_processor_id_r,
        CAST(NULL AS DATE)                     d_excess_effective_date_r,
        MAX(
          CASE
            WHEN app_cov_dcsn.v_entity_type_r = 'SPOUSE' 
            THEN app_cov_dcsn.v_excess_status_r
          END
          ) v_spouse_excess_status_r,
        MAX(
          CASE
            WHEN app_cov_dcsn.v_entity_type_r = 'INSURED' 
            THEN app_cov_dcsn.v_excess_status_r
          END
          ) v_employee_excess_status_r,
        MAX(
          CASE
            WHEN app_cov_dcsn.v_entity_type_r = 'CHILD' 
            THEN app_cov_dcsn.v_excess_status_r
          END
          ) v_child_excess_status_r,
        CASE
          WHEN NOT app_cov_dcsn.v_excess_status_r IS NULL 
          THEN concat('Excess ',app_cov_dcsn.v_excess_status_r)
          ELSE app_cov_dcsn.v_excess_status_r
        END AS v_excess_status_r,
        app_cov_dcsn.d_gi_effective_date_r    AS d_gi_effective_date_r,
        MAX(
          CASE
            WHEN app_cov_dcsn.v_entity_type_r = 'INSURED' 
            THEN app_cov_dcsn.v_gi_status_r
          END
          ) v_employee_gi_status_r,
        MAX(
          CASE
            WHEN app_cov_dcsn.v_entity_type_r = 'SPOUSE' 
            THEN app_cov_dcsn.v_gi_status_r
          END
          ) v_spouse_gi_status_r,
        MAX(
          CASE
            WHEN app_cov_dcsn.v_entity_type_r = 'CHILD' 
            THEN app_cov_dcsn.v_gi_status_r
          END
          ) v_child_gi_status_r,
          app_cov_dcsn.v_gi_status_r            v_gi_status_r,
          eoi_trans.v_hidden_ind_r              v_hidden_indicator_r,
          eoi_app.n_s_insured_id_r              n_insured_id_r,
          insured.v_member_number_r             v_insured_member_number_r,
          app_cov_dcsn.f_is_waived_r            v_is_waived_flag_r,
          eoi_app_hist.d_update_date_r          d_most_recent_action_date_r,
          eoi_app_hist.v_description_r          v_most_recent_action_description_r,
          eoi_app_hist.n_application_history_sk_r,
          plcy_dir.v_policy_number_r,
          plcy_dir.v_policy_prefix_r            v_policy_prefix_r,
          eoi_app_hist.v_queue_name_r           v_queue_name_r,
          MAX(
            CASE
              WHEN app_cov_dcsn.v_entity_type_r = 'CHILD' 
              THEN app_cov_dcsn.d_excess_effective_date_r
            END
            ) d_child_excess_effective_date_r,
          MAX(
            CASE
              WHEN app_cov_dcsn.v_entity_type_r = 'SPOUSE' 
              THEN app_cov_dcsn.d_excess_effective_date_r
            END
            ) d_spouse_excess_effective_date_r,
          MAX(
            CASE
              WHEN app_cov_dcsn.v_entity_type_r = 'SPOUSE' 
              THEN app_cov_dcsn.d_gi_effective_date_r
            END
            ) d_spouse_gi_effective_date_r,
          plcy_dir.n_policy_sk_r,
          eoi_app.v_is_wet_signature_required_r v_wet_signature_required_indicator_r,
          gc_main_loadedby                     v_last_modified_by_r,
          gd_sysdate                           t_creation_date_r,
          gc_main_loadedby                     v_created_by_r,
          gd_sysdate                           t_last_modified_date_r,
          gn_current_month                     n_yearmonth_r,
          'Y'                                   v_rpt_active_status_r,
          gn_sysdt_batchid                     n_batch_id_r,
          eoi_trans.v_web_description_r         v_web_description_r,
          eoi_app.v_insert_by_r,
          eoi_app_hist.v_source_system_name_r,
          eoi_app_hist.t_event_timestamp_r,
          CASE
            WHEN eoi_app_hist.d_insert_date_r IS NULL 
            THEN eoi_app_hist.t_event_timestamp_r
            ELSE to_timestamp(trunc(eoi_app_hist.d_insert_date_r)|| 
              substr(to_char(eoi_app_hist.t_event_timestamp_r),10))
          END t_event_timestamp_r_app_his,
          plcy_dir.v_policy_suffix_r,
          plcy.n_cust_party_sk_r,
          plcy.v_carrier_name_r,
          (
            SELECT  
              v_client_name_r
            FROM(
              SELECT d.v_individual_first_name_r || ' ' || d.v_individual_last_name_r AS v_client_name_r,
               d.n_party_sk_r,
               ROW_NUMBER() OVER(PARTITION BY d.n_party_sk_r
                            ORDER BY d.t_event_timestamp_r DESC,
                                     n_sequence_number_r DESC) rnk
              FROM dim_grp_party_r d
              WHERE d.n_party_sk_r = plcy.n_cust_party_sk_r
               )
            WHERE rnk = 1) v_client_name_r,
          eoi_trans.v_highlight_ind_r,
          CAST(NULL AS VARCHAR2(300))            v_applicant_child_last_name_r,
          CAST(NULL AS DATE)                     d_most_recent_action_date1_r,
          CAST(NULL AS VARCHAR2(300))            v_most_recent_action_description1_r,
          app_cov_dcsn.n_gi_requested_r         n_gi_requested_r,
          app_cov_dcsn.n_approved_gi_r          n_approved_gi_r,
          app_cov_dcsn.n_excess_requested_r     n_excess_requested_r,
          app_cov_dcsn.n_excess_amount_r        n_excess_amount_r,
          appl_dtl_insured.d_doh_r              d_applicant_date_of_hire_r
      FROM atomic.dim_eoi_application_history_r eoi_app_hist
      INNER JOIN atomic.dim_grp_applicationpolicies_r  app_policies
      ON app_policies.n_application_id_r = eoi_app_hist.n_application_id_r
      AND app_policies.v_active_status_r = 'Y'
      INNER JOIN atomic.dim_eoi_application_r eoi_app
      ON eoi_app.n_application_sk_r = eoi_app_hist.n_application_sk_r
      AND eoi_app.v_active_status_r = 'Y'
      INNER JOIN atomic.dim_eoi_transaction_r eoi_trans
      ON eoi_trans.v_transaction_code_r = eoi_app_hist.v_code_r
      AND eoi_trans.v_active_status_r = 'Y'
      INNER JOIN atomic.dim_eoi_applicant_detail_r appl_dtl_insured
      ON appl_dtl_insured.n_application_sk_r = eoi_app.n_application_sk_r
      AND appl_dtl_insured.v_active_status_r = 'Y'
      AND appl_dtl_insured.d_delete_date_r IS NULL
      AND(appl_dtl_insured.v_entity_type_r = 'INSURED'
        OR appl_dtl_insured.v_source_system_name_r = 'STACS')
      INNER JOIN atomic.dim_insured_r insured
      ON insured.n_s_insured_id_r = eoi_app.n_s_insured_id_r
      AND insured.v_active_status_r = 'Y'
      LEFT OUTER JOIN atomic.dim_eoi_applicant_detail_r appl_dtl_spouse
      ON appl_dtl_spouse.n_application_sk_r = eoi_app.n_application_sk_r
      AND appl_dtl_spouse.v_active_status_r = 'Y'
      AND appl_dtl_spouse.d_delete_date_r IS NULL
      AND appl_dtl_spouse.v_entity_type_r = 'SPOUSE'
      OUTER APPLY(
        SELECT deah.n_application_id_r
        FROM atomic.dim_eoi_application_history_r deah
        WHERE deah.n_application_id_r = eoi_app.n_application_id_r
        AND deah.v_code_r <> 'APP'
        AND deah.v_insert_by_r NOT IN('VGEOI Automation Process','NIGHT JOB')
        AND deah.v_active_status_r = 'Y'
        GROUP BY deah.n_application_id_r
        ) deah
      INNER JOIN atomic.dim_grp_policy_dir_r plcy_dir
      ON plcy_dir.n_policy_sk_r = app_policies.n_policy_sk_r
      AND plcy_dir.v_active_status_r = 'Y'
      LEFT OUTER JOIN atomic.dim_eoi_app_coverag_decision_r app_cov_dcsn
      ON app_cov_dcsn.n_s_application_policy_id_r = app_policies.n_application_policy_id_r
      AND app_cov_dcsn.v_active_status_r = 'Y'
      AND nvl(app_cov_dcsn.f_is_waived_r,'0')<> '1'
      LEFT OUTER JOIN atomic.fct_grp_policy_r plcy
      ON plcy.n_policy_sk_r = plcy_dir.n_policy_sk_r
      AND plcy.n_source_system_key_r = plcy_dir.n_source_system_key_r
      AND plcy.n_version_number_r = plcy_dir.n_policy_version_number_r
      WHERE eoi_app_hist.v_active_status_r = 'Y'
      AND eoi_app_hist.v_queue_name_r <> 'Trashcan'
      AND appl_dtl_insured.n_party_sk_r IN (
        SELECT party.n_party_sk_r 
        FROM atomic.dim_grp_party_r party
        WHERE v_active_status_r = 'Y')
      GROUP BY 
        CAST(NULL AS VARCHAR2(300)),
        appl_dtl_insured.d_dob_r,
        appl_dtl_insured.v_first_name_r,
        appl_dtl_insured.v_last_name_r,
        sysdate - appl_dtl_spouse.d_dob_r,
        appl_dtl_spouse.d_dob_r,
        appl_dtl_spouse.v_first_name_r,
        appl_dtl_spouse.v_last_name_r,
        app_cov_dcsn.v_entity_type_r,
        eoi_app_hist.d_insert_date_r,
        eoi_app.n_application_id_r,
        eoi_app.v_queue_r,
        eoi_app.d_received_date_r,
        eoi_app.v_source_r,
        eoi_trans.v_transaction_description_r,
        eoi_app.n_s_status_id_r,
        eoi_app_hist.v_code_r,
        CASE
          WHEN deah.n_application_id_r IS NULL 
          THEN 'Y'
          ELSE 'N'
        END,
        eoi_app_hist.v_insert_by_r,
        eoi_trans.v_hidden_ind_r,
        eoi_app.n_s_insured_id_r,
        app_cov_dcsn.f_is_waived_r,
        eoi_app_hist.d_update_date_r,
        eoi_app_hist.v_description_r,
        eoi_app_hist.v_queue_name_r,
        eoi_app.v_is_wet_signature_required_r,
        gc_main_loadedby,
        gd_sysdate,
        gc_main_loadedby,
        gd_sysdate,
        gn_current_month,
        'Y',
        gn_sysdt_batchid,
        plcy_dir.v_policy_number_r,
        plcy_dir.n_policy_sk_r,
        eoi_app_hist.n_application_history_sk_r,
        insured.v_member_number_r,
        plcy_dir.v_policy_prefix_r,
        eoi_trans.v_web_description_r,
        eoi_app.v_insert_by_r,
        eoi_app_hist.v_source_system_name_r,
        eoi_app_hist.t_event_timestamp_r,
        eoi_app.t_event_timestamp_r,
        app_cov_dcsn.v_excess_status_r,
        app_cov_dcsn.d_gi_effective_date_r,
        app_cov_dcsn.v_gi_status_r,
        plcy_dir.v_policy_suffix_r,
        plcy.n_cust_party_sk_r,
        plcy.v_carrier_name_r,
        eoi_trans.v_highlight_ind_r,
        app_cov_dcsn.n_gi_requested_r,
        app_cov_dcsn.n_approved_gi_r,
        app_cov_dcsn.n_excess_requested_r,
        app_cov_dcsn.n_excess_amount_r,
        appl_dtl_insured.d_doh_r;