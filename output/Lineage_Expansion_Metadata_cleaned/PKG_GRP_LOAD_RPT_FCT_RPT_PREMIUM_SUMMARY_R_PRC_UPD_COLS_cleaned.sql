-- Cleaned for lineage: PKG_GRP_LOAD_RPT_FCT_RPT_PREMIUM_SUMMARY_R_PRC_UPD_COLS

MERGE INTO atomic.rpt_fct_rpt_premium_summary_r rpt_prem_summ
    USING (
      SELECT d_due_date_r,
             n_src_policy_billgroup_id_r,
             n_src_coverage_id_r,
             n_policy_sk_r,
             v_customer_bill_group_number_r,
             v_coveragecode_r,
             d_cycle_date_r,
             SUM(n_lives_r)     n_lives_r,
             SUM(n_lives_adj_r) n_lives_adj_r
      FROM(
      SELECT d_transaction_date_r,
                  d_due_date_r,
                  n_src_policy_billgroup_id_r,
                  n_src_coverage_id_r,
                  n_policy_sk_r,
                  v_customer_bill_group_number_r,
                  v_coveragecode_r,
                  d_cycle_date_r,
                  n_lives_r,
                  n_lives_adj_r
           FROM atomic.fct_billing_policy_premium_r_table_pollives_mv_ssl
           WHERE to_number(to_char(d_cycle_date_r,'YYYYMM'))= ln_yearmonth_r)
      GROUP BY d_due_date_r,
               n_src_policy_billgroup_id_r,
               n_src_coverage_id_r,
               n_policy_sk_r,
               v_customer_bill_group_number_r,
               v_coveragecode_r,
               d_cycle_date_r
      ) upd_lives    
    ON (rpt_prem_summ.d_cycle_date_r = upd_lives.d_cycle_date_r
      AND rpt_prem_summ.n_policy_sk_r = upd_lives.n_policy_sk_r
      AND rpt_prem_summ.v_customer_bill_group_number_r = upd_lives.v_customer_bill_group_number_r
      AND rpt_prem_summ.v_coverage_code_r = upd_lives.v_coveragecode_r
      AND rpt_prem_summ.d_due_date_r = upd_lives.d_due_date_r
      AND rpt_prem_summ.n_yearmonth_r = ln_yearmonth_r)
    WHEN MATCHED THEN UPDATE
    SET rpt_prem_summ.n_collected_lives_r = upd_lives.n_lives_adj_r
    WHERE rpt_prem_summ.n_yearmonth_r = ln_yearmonth_r;