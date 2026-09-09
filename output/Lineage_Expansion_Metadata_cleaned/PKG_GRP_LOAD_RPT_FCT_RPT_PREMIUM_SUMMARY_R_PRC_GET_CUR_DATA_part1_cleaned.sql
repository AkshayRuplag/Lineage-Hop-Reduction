-- Cleaned for lineage: PKG_GRP_LOAD_RPT_FCT_RPT_PREMIUM_SUMMARY_R_PRC_GET_CUR_DATA (part 1/1)

INSERT  INTO rpt_fct_rpt_premium_summary_r_exg (
      d_due_date_r, 
      d_cycle_date_r, 
      n_policy_sk_r, 
      n_billgroup_sk_r, 
      n_product_sk_r, 
      n_chg_due_prem_amt_r, 
      n_chg_due_prem_unearned_amt_r, 
      n_chg_prem_unearned_amt_r, 
      n_collected_premium_amt_r, 
      n_due_prem_amt_r, 
      n_due_prem_unearned_amt, 
      n_earned_prem_amt_r, 
      n_constant_earned_prem_amt_r, 
      n_prior_due_prem_amt_r, 
      n_prior_dueprem_unearned_amt_r, 
      n_prem_unearned_amt, 
      n_written_prem_amt_r, 
      v_coverage_code_r, 
      v_policy_number_r, 
      v_customer_bill_group_number_r, 
      v_last_modified_by_r, 
      t_creation_date_r, 
      v_created_by_r, 
      t_last_modified_date_r, 
      n_yearmonth_r, 
      v_rpt_active_status_r, 
      n_batch_id_r, 
      n_cust_party_sk_r, 
      n_chg_due_prem_amt_ceded_r, 
      n_chg_due_prem_unearned_amt_ceded_r, 
      n_chg_prem_unearned_amt_ceded_r, 
      n_collected_premium_amt_ceded_r, 
      n_due_prem_amt_ceded_r, 
      n_due_prem_unearned_amt_ceded_r, 
      n_earned_prem_amt_ceded_r, 
      n_constant_earned_prem_amt_ceded_r, 
      n_prior_due_prem_amt_ceded_r, 
      n_prior_dueprem_unearned_amt_ceded_r, 
      n_prem_unearned_amt_ceded_r, 
      n_written_prem_amt_ceded_r, 
      v_primary_reinsurer_r, 
      v_secondary_reinsurer_r, 
      v_ternary_reinsurer_r, 
      n_primary_reinsurer_reins_share_pct_r, 
      n_primary_reinsurer_reinsurance_pct_r, 
      n_secondary_reinsurer_reins_share_pct_r, 
      n_secondary_reinsurer_reinsurance_pct_r, 
      n_ternary_reinsurer_reins_share_pct_r, 
      n_ternary_reinsurer_reinsurance_pct_r, 
      n_total_reins_prem_pct_r, 
      n_chg_due_prem_amt_net_r, 
      n_chg_due_prem_unearned_amt_net_r, 
      n_chg_prem_unearned_amt_net_r, 
      n_collected_premium_amt_net_r, 
      n_due_prem_amt_net_r, 
      n_due_prem_unearned_amt_net_r, 
      n_earned_prem_amt_net_r, 
      n_constant_earned_prem_amt_net_r, 
      n_prior_due_prem_amt_net_r, 
      n_prior_dueprem_unearned_amt_net_r, 
      n_prem_unearned_amt_net_r, 
      n_written_prem_amt_net_r, 
      n_collected_lives_r, 
      v_source_system_name_r, 
      n_prior_prem_unearned_amt_r)
    SELECT  
      rpt_prem_summ.d_due_date_r                             d_due_date_r,
      rpt_prem_summ.d_cycle_date_r                           d_cycle_date_r,
      plcy_info.n_policy_sk_r                                n_policy_sk_r,
      nvl(n_policy_billgroup_sk_r,- 1)                       n_billgroup_sk_r,
      prod.n_product_sk_r                                    n_product_sk_r,
      rpt_prem_summ.n_chg_due_prem_amt_r                     n_chg_due_prem_amt_r,
      rpt_prem_summ.n_chg_due_prem_unearned_amt_r            n_chg_due_prem_unearned_amt_r,
      rpt_prem_summ.n_chg_prem_unearned_amt_r                n_chg_prem_unearned_amt_r,
      rpt_prem_summ.n_collected_premium_amt_r                n_collected_premium_amt_r,
      rpt_prem_summ.n_due_prem_amt_r                         n_due_prem_amt_r,
      rpt_prem_summ.n_due_prem_unearned_amt                  n_due_prem_unearned_amt,
      rpt_prem_summ.n_earned_prem_amt_r                      n_earned_prem_amt_r,
      rpt_prem_summ.n_constant_earned_prem_amt_r             n_constant_earned_prem_amt_r,
      rpt_prem_summ.n_prior_due_prem_amt_r                   n_prior_due_prem_amt_r,
      rpt_prem_summ.n_prior_dueprem_unearned_amt_r           n_prior_dueprem_unearned_amt_r,
      rpt_prem_summ.n_prem_unearned_amt                      n_prem_unearned_amt,
      rpt_prem_summ.n_written_prem_amt_r                     n_written_prem_amt_r,
      rpt_prem_summ.v_coverage_code_r                        v_coverage_code_r,
      rpt_prem_summ.v_policy_number_r                        v_policy_number_r,
      rpt_prem_summ.v_customer_bill_group_number_r           v_customer_bill_group_number_r,
      gc_main_loadedby                                       v_last_modified_by_r,
      systimestamp                                           t_creation_date_r,
      gc_main_loadedby                                       v_created_by_r,
      systimestamp                                           t_last_modified_date_r,
      gn_current_month                                       n_yearmonth_r,
      'Y'                                                    v_rpt_active_status_r,
      gn_sysdt_batchid                                       n_batch_id_r,
      plcy_info.n_cust_party_sk_r                            n_cust_party_sk_r,
      (rpt_prem_summ.n_chg_due_prem_amt_r * rpt_prem_summ.n_total_reins_prem_pct_r)          n_chg_due_prem_amt_ceded_r,
      (rpt_prem_summ.n_chg_due_prem_unearned_amt_r * rpt_prem_summ.n_total_reins_prem_pct_r) n_chg_due_prem_unearned_amt_ceded_r,
      (rpt_prem_summ.n_chg_prem_unearned_amt_r * rpt_prem_summ.n_total_reins_prem_pct_r)     n_chg_prem_unearned_amt_ceded_r,
      (rpt_prem_summ.n_collected_premium_amt_r * rpt_prem_summ.n_total_reins_prem_pct_r)     n_collected_premium_amt_ceded_r,
      (rpt_prem_summ.n_due_prem_amt_r * rpt_prem_summ.n_total_reins_prem_pct_r)              n_due_prem_amt_ceded_r,
      (rpt_prem_summ.n_due_prem_unearned_amt * rpt_prem_summ.n_total_reins_prem_pct_r)       n_due_prem_unearned_amt_ceded_r,
      (rpt_prem_summ.n_earned_prem_amt_r * rpt_prem_summ.n_total_reins_prem_pct_r)           n_earned_prem_amt_ceded_r,
      (rpt_prem_summ.n_constant_earned_prem_amt_r * rpt_prem_summ.n_total_reins_prem_pct_r)  n_constant_earned_prem_amt_ceded_r,
      (rpt_prem_summ.n_prior_due_prem_amt_r * rpt_prem_summ.n_total_reins_prem_pct_r)        n_prior_due_prem_amt_ceded_r,
      (rpt_prem_summ.n_prior_dueprem_unearned_amt_r * rpt_prem_summ.n_total_reins_prem_pct_r) n_prior_dueprem_unearned_amt_ceded_r,
      (rpt_prem_summ.n_prem_unearned_amt * rpt_prem_summ.n_total_reins_prem_pct_r)           n_prem_unearned_amt_ceded_r,
      (rpt_prem_summ.n_written_prem_amt_r * rpt_prem_summ.n_total_reins_prem_pct_r)          n_written_prem_amt_ceded_r,
      rpt_prem_summ.v_primary_reinsurer_r                  v_primary_reinsurer_r,
      rpt_prem_summ.v_secondary_reinsurer_r                v_secondary_reinsurer_r,
      rpt_prem_summ.v_ternary_reinsurer_r                  v_ternary_reinsurer_r,
      CAST(NULL AS NUMBER)                                 n_primary_reinsurer_reins_share_pct_r,
      rpt_prem_summ.n_primary_reins_prem_pct_r             n_primary_reinsurer_reinsurance_pct_r,
      CAST(NULL AS NUMBER)                                 n_secondary_reinsurer_reins_share_pct_r,
      rpt_prem_summ.n_sec_reins_prem_pct_r                 n_secondary_reinsurer_reinsurance_pct_r,
      CAST(NULL AS NUMBER)                                 n_ternary_reinsurer_reins_share_pct_r,
      rpt_prem_summ.n_ternary_reins_prem_pct_r             n_ternary_reinsurer_reinsurance_pct_r,
      rpt_prem_summ.n_total_reins_prem_pct_r               n_total_reins_prem_pct_r,
      (rpt_prem_summ.n_chg_due_prem_amt_r -
        (rpt_prem_summ.n_chg_due_prem_amt_r * rpt_prem_summ.n_total_reins_prem_pct_r))          n_chg_due_prem_amt_net_r,
      (rpt_prem_summ.n_chg_due_prem_unearned_amt_r -
        (rpt_prem_summ.n_chg_due_prem_unearned_amt_r * rpt_prem_summ.n_total_reins_prem_pct_r)) n_chg_due_prem_unearned_amt_net_r,
      (rpt_prem_summ.n_chg_prem_unearned_amt_r -
        (rpt_prem_summ.n_chg_prem_unearned_amt_r * rpt_prem_summ.n_total_reins_prem_pct_r))     n_chg_prem_unearned_amt_net_r,
      (rpt_prem_summ.n_collected_premium_amt_r -
        (rpt_prem_summ.n_collected_premium_amt_r * rpt_prem_summ.n_total_reins_prem_pct_r))     n_collected_premium_amt_net_r,
      (rpt_prem_summ.n_due_prem_amt_r -
        (rpt_prem_summ.n_due_prem_amt_r * rpt_prem_summ.n_total_reins_prem_pct_r))              n_due_prem_amt_net_r,
      (rpt_prem_summ.n_due_prem_unearned_amt -
        (rpt_prem_summ.n_due_prem_unearned_amt * rpt_prem_summ.n_total_reins_prem_pct_r))       n_due_prem_unearned_amt_net_r,
      (rpt_prem_summ.n_earned_prem_amt_r -
        (rpt_prem_summ.n_earned_prem_amt_r * rpt_prem_summ.n_total_reins_prem_pct_r))           n_earned_prem_amt_net_r,
      (rpt_prem_summ.n_constant_earned_prem_amt_r -
        (rpt_prem_summ.n_constant_earned_prem_amt_r * rpt_prem_summ.n_total_reins_prem_pct_r))  n_constant_earned_prem_amt_net_r,
      (rpt_prem_summ.n_prior_due_prem_amt_r -
        (rpt_prem_summ.n_prior_due_prem_amt_r * rpt_prem_summ.n_total_reins_prem_pct_r))        n_prior_due_prem_amt_net_r,
      (rpt_prem_summ.n_prior_dueprem_unearned_amt_r -
        (rpt_prem_summ.n_prior_dueprem_unearned_amt_r *rpt_prem_summ.n_total_reins_prem_pct_r)) n_prior_dueprem_unearned_amt_net_r,
      (rpt_prem_summ.n_prem_unearned_amt -
        (rpt_prem_summ.n_prem_unearned_amt * rpt_prem_summ.n_total_reins_prem_pct_r))           n_prem_unearned_amt_net_r,
      (rpt_prem_summ.n_written_prem_amt_r -
        (rpt_prem_summ.n_written_prem_amt_r * rpt_prem_summ.n_total_reins_prem_pct_r))          n_written_prem_amt_net_r,
      CAST(NULL AS NUMBER)                            n_collected_lives_r,
      rpt_prem_summ.v_source_system_name_r            v_source_system_name_r,
      rpt_prem_summ.n_prior_prem_unearned_amt_r       n_prior_prem_unearned_amt_r
    FROM (
      SELECT *
      FROM atomic.fct_rpt_premium_summary_r
      WHERE d_cycle_date_r >= trunc(to_date(gn_current_month,'YYYYMM'),'MM')
      AND d_cycle_date_r < trunc(add_months(to_date(gn_current_month,'YYYYMM'),1),'MM')
      ) rpt_prem_summ
    INNER JOIN atomic.dim_source_system_r ss
    ON rpt_prem_summ.v_source_system_name_r = ss.v_source_system_code_r
    INNER JOIN (
      SELECT plcy_dir.n_policy_sk_r,
             plcy.n_cust_party_sk_r,
             plcy_dir.v_policy_number_r
      FROM atomic.dim_grp_policy_dir_r plcy_dir,
           atomic.fct_grp_policy_r     plcy
      WHERE plcy_dir.v_active_status_r = 'Y'
      AND plcy_dir.n_policy_sk_r             = plcy.n_policy_sk_r
      AND plcy_dir.n_policy_version_number_r = plcy.n_version_number_r
      AND plcy_dir.n_source_system_key_r     = plcy.n_source_system_key_r
      GROUP BY plcy_dir.n_policy_sk_r,
               plcy.n_cust_party_sk_r,
               plcy_dir.v_policy_number_r
      ) plcy_info
    ON rpt_prem_summ.v_policy_number_r = plcy_info.v_policy_number_r
    LEFT OUTER JOIN atomic.dim_grp_product_r prod
    ON rpt_prem_summ.v_coverage_code_r = prod.v_coverage_code_r
    LEFT OUTER JOIN (
      SELECT pol_billgrp.n_policy_sk_r,
             bill_group.v_customer_bill_group_number_r,
             MAX(pol_billgrp.n_policy_billgroup_sk_r)n_policy_billgroup_sk_r,
             pol_billgrp.v_source_system_name_r
      FROM (
        SELECT *
        FROM atomic.dim_grp_billing_pol_billgrp_r
        WHERE dim_grp_billing_pol_billgrp_r.v_source_system_name_r <> 'APS' 
        ) pol_billgrp
      LEFT OUTER JOIN (
        SELECT *
        FROM atomic.dim_grp_customer_bill_group_r
        WHERE v_source_system_name_r NOT IN ( 'APS', 'EIS' )
        ) bill_group
      ON bill_group.v_active_status_r = 'Y'
      AND pol_billgrp.n_customer_billgroup_id_r = bill_group.n_customer_billgroup_id_r
      WHERE pol_billgrp.v_active_status_r = 'Y'
      GROUP BY pol_billgrp.n_policy_sk_r,
               bill_group.v_customer_bill_group_number_r,
               pol_billgrp.v_source_system_name_r
        ) bg
    ON bg.n_policy_sk_r = rpt_prem_summ.n_policy_sk_r
    AND bg.v_source_system_name_r = rpt_prem_summ.v_source_system_name_r
    AND (
      CASE
        WHEN ss.v_tpa_indicator_r = 0 
        THEN bg.v_customer_bill_group_number_r
        ELSE '1'
      END
      )=(
      CASE
        WHEN ss.v_tpa_indicator_r = 0 
        THEN rpt_prem_summ.v_customer_bill_group_number_r
        ELSE '1'
      END
      );