-- Cleaned for lineage: PKG_GRP_LOAD_RPT_SUSPENSE_DTL_R_PRC_GET_CUR_DATA

INSERT  INTO RPT_suspense_dtl_R_exg stg
    SELECT  
      plcy_suspns.d_delete_date_r        AS d_posted_date_r,
      plcy_suspns.d_due_date_r           AS d_suspense_due_date_r,
      plcy_suspns.d_insert_date_r        AS d_suspense_insert_date_r,
      CAST(NULL AS NUMBER)               AS n_most_recent_premium_amount_r,
      plcy_suspns.d_transaction_date_r   AS d_suspense_date_r,
      (sysdate - plcy_suspns.d_transaction_date_r)   AS n_days_in_suspense_r,
      plcy_suspns.n_amount_r             AS n_suspense_amount_r,
      plcy.n_cust_party_sk_r             AS n_cust_party_sk_r,
      CASE
        WHEN plcy_suspns.n_is_cash_error_r = '1' 
        THEN 'Yes'
        ELSE 'No'
      END                                   AS v_cash_error_ind_r,
      billgrp.n_policy_billgroup_sk_r       AS n_billgroup_sk_r,
      plcy_dir.n_policy_sk_r                 AS n_policy_sk_r,
      plcy_suspns.n_src_policy_billgroup_id_r   AS n_src_policy_billgroup_id_r,
      plcy_suspns.n_src_policy_id_r             AS n_src_policy_id_r,
      plcy_suspns.n_src_suspense_premium_id_r   AS n_suspense_premium_id_r,
      plcy_suspns.v_description_r               AS v_suspense_description_r,
      nvl(sec_user.v_full_name_r,plcy_suspns.v_suspense_operator_r) AS v_suspense_operator_fullname_r,
      plcy_suspns.v_suspense_operator_r         AS v_suspense_operator_r,
      plcy_suspns.v_user_name_r                 AS v_suspense_operator_username_r,
      gc_main_loadedby                AS v_last_modified_by_r,
    	gd_sysdate                      AS t_creation_date_r,
    	gc_main_loadedby                AS v_created_by_r,
    	gd_sysdate                      AS t_last_modified_date_r,
    	gn_current_month                AS n_yearmonth_r,
    	'Y'                             AS v_rpt_active_status_r,
    	gn_sysdt_batchid                AS n_batch_id_r
    FROM atomic.fct_billing_policy_suspense_r plcy_suspns
    INNER JOIN atomic.dim_grp_policy_dir_r plcy_dir
    ON plcy_suspns.n_policy_sk_r = plcy_dir.n_policy_sk_r
    INNER JOIN atomic.dim_sec_user_r sec_user
    ON upper(nvl(plcy_suspns.v_update_by_r,plcy_suspns.v_insert_by_r))= upper(sec_user.v_login_r)
    INNER JOIN atomic.dim_grp_billing_pol_billgrp_r billgrp
    ON billgrp.n_policy_billgroup_id_r = plcy_suspns.n_src_policy_billgroup_id_r
    AND billgrp.v_source_system_name_r = 'VUE'
    AND billgrp.v_active_status_r = 'Y'
    INNER JOIN atomic.fct_grp_policy_r plcy
    ON plcy_dir.n_policy_sk_r = plcy.n_policy_sk_r
    AND plcy_dir.n_policy_version_number_r = plcy.n_version_number_r
    AND plcy_dir.n_source_system_key_r = plcy.n_source_system_key_r
    AND plcy_dir.v_active_status_r = 'Y'
    WHERE plcy_suspns.d_delete_date_r IS NULL
    AND plcy_suspns.n_src_policy_billgroup_id_r IN (
      SELECT n_src_policy_billgroup_id_r
      FROM atomic.fct_billing_policy_premium_r);