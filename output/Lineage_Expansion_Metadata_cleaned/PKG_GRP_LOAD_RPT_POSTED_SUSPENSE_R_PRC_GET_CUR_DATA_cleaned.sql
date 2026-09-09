-- Cleaned for lineage: PKG_GRP_LOAD_RPT_POSTED_SUSPENSE_R_PRC_GET_CUR_DATA

INSERT  INTO RPT_POSTED_SUSPENSE_R_exg stg
    SELECT  
      suspense_posted.d_delete_date_r AS d_posted_date_r,
      suspense_posted.d_due_date_r AS d_due_date_r,
      suspense_posted.d_insert_date_r AS d_insert_date_r,
      suspense_posted.d_transaction_date_r AS d_transaction_date_r,
      CAST(NULL AS NUMBER) AS n_posted_suspense_process_days_r,
      suspense_posted.n_amount_r AS n_posted_suspense_amount_r,
      plcy.n_cust_party_sk_r AS n_cust_party_sk_r,
      pol_billgrp.n_policy_billgroup_sk_r AS n_billgroup_sk_r,
      plcy_dir.n_policy_sk_r AS n_policy_sk_r,
      suspense_posted.n_src_policy_billgroup_id_r AS n_src_policy_billgroup_id_r,
      suspense_posted.n_src_policy_id_r AS n_src_policy_id_r,
      suspense_posted.n_src_suspense_premium_id_r AS n_posted_suspense_premium_id_r,
      suspense_posted.v_billgroup_number_r AS v_billgroup_number_r,
      suspense_posted.v_carrier_r AS v_carrier_r,
      suspense_posted.v_change_reason_r AS v_change_reason_r,
      suspense_posted.v_created_by_r AS v_pos_created_by_r,
      suspense_posted.v_delete_by_r AS v_delete_by_r,
      suspense_posted.v_description_r AS v_posted_suspense_description_r,
      CASE 
        WHEN instr(upper(sec_user.v_full_name_r),'ONLINE')> 0
          OR instr(upper(sec_user.v_full_name_r),'BILLING')> 0
          OR instr(upper(sec_user.v_full_name_r),'OBS')> 0 
        THEN 'Online Billing'
        ELSE 
          CASE
            WHEN sec_user.v_full_name_r IS NOT NULL 
            THEN sec_user.v_full_name_r
          END
      END AS v_posted_suspense_operator_fullname_r,
      suspense_posted.v_insert_by_r AS v_insert_by_r,
      suspense_posted.v_last_modified_by_r AS v_pos_last_modified_by_r,
      suspense_posted.v_suspense_operator_r AS v_posted_suspense_operator_r,
      suspense_posted.v_update_by_r AS v_update_by_r,
      suspense_posted.v_user_name_r AS v_user_name_r,
      gc_main_loadedby v_last_modified_by_r,
      gd_sysdate t_creation_date_r,
      gc_main_loadedby v_created_by_r,
      gd_sysdate t_last_modified_date_r,
      gn_current_month n_yearmonth_r,
      'Y' v_rpt_active_status_r,
      gn_sysdt_batchid n_batch_id_r
    FROM atomic.fct_billing_policy_suspense_r_posted suspense_posted
    INNER JOIN atomic.dim_grp_policy_dir_r plcy_dir
    ON suspense_posted.n_policy_sk_r = plcy_dir.n_policy_sk_r
    INNER JOIN atomic.dim_sec_user_r sec_user
    ON UPPER(suspense_posted.v_delete_by_r) = UPPER(sec_user.v_login_r)
    INNER JOIN atomic.dim_grp_billing_pol_billgrp_r pol_billgrp
    ON pol_billgrp.v_source_system_name_r = 'VUE'
    AND pol_billgrp.n_policy_billgroup_id_r = suspense_posted.n_src_policy_billgroup_id_r
    AND pol_billgrp.v_active_status_r = 'Y'
    INNER JOIN atomic.fct_grp_policy_r plcy
    ON plcy_dir.n_policy_sk_r = plcy.n_policy_sk_r
       AND plcy_dir.n_policy_version_number_r = plcy.n_version_number_r
       AND plcy_dir.n_source_system_key_r = plcy.n_source_system_key_r
    WHERE plcy_dir.v_active_status_r = 'Y';