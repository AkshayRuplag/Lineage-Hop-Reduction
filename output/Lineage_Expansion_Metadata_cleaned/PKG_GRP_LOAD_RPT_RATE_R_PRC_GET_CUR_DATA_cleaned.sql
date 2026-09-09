-- Cleaned for lineage: PKG_GRP_LOAD_RPT_RATE_R_PRC_GET_CUR_DATA

INSERT  INTO atomic.rpt_rate_r_exg stg
    SELECT 
      billgrp.n_policy_billgroup_sk_r n_billgroup_sk_r,
      plcy_dir.v_policy_prefix_r,
      plcy_dir.v_policy_suffix_r,
      plcy_dir.n_policy_sk_r,
      product.v_basic_product_line_desc_r,
      product.n_product_sk_r,
      product.v_product_sub_line_code_r,
       replace(
         replace(
           replace(
             MIN(
               CASE
                 WHEN product.v_product_sub_line_code_r = 'SR'
                 THEN 'N/A'
                 WHEN 
                   CASE
                     WHEN rate_sts.n_is_composite_r = 1 
                     THEN prem_rate.n_ec_rate_r
                     ELSE NULL
                   END IS NULL 
                 THEN 'Step Rates'
                 WHEN product.v_product_line_r = 'LTD'
                 THEN concat(concat('$ ',CAST(
                   CASE
                     WHEN rate_sts.n_is_composite_r = 1 
                     THEN prem_rate.n_ec_rate_r
                     ELSE NULL
                   END AS CHARACTER(30))),' (per $100 of Covered Payroll)')
                 WHEN product.v_product_sub_line_code_r = 'STD'
                 THEN concat(concat('$ ',CAST(
                   CASE
                     WHEN rate_sts.n_is_composite_r = 1 
                     THEN prem_rate.n_ec_rate_r
                     ELSE NULL
                   END AS CHARACTER(30))),' (per $10 of Benefit)')
                 WHEN product.v_basic_product_line_code_r = 'Dependent Life' 
                 THEN concat(concat('$ ',CAST(
                   CASE
                     WHEN rate_sts.n_is_composite_r = 1 
                     THEN prem_rate.n_ec_rate_r
                     ELSE NULL
                   END AS CHARACTER(30))),' (per Unit)')
                 ELSE concat(concat('$ ',CAST(
                   CASE
                     WHEN rate_sts.n_is_composite_r = 1 
                     THEN prem_rate.n_ec_rate_r
                     ELSE NULL
                   END AS CHARACTER(30))),' (per $1000 of Volume)')
                 END)
                 ,'  ','')
                 ,' (','('),'(',' (') AS v_rpt_current_rate_r,
      plcy.n_cust_party_sk_r,
      gc_getcur_loadedby              AS v_last_modified_by_r,
      gd_sysdate                      AS t_creation_date_r,
      gc_getcur_loadedby              AS v_created_by_r,
      gd_sysdate                      AS t_last_modified_date_r,
      'Y'                             AS v_rpt_active_status_r,
      gn_sysdt_batchid                AS n_batch_id_r,
      gn_current_month                AS n_reportmonth_r
    FROM atomic.dim_grp_billing_policy_covrg_r bill_plcy_cvrg
    INNER JOIN atomic.dim_coverage_r coverage
    ON bill_plcy_cvrg.n_coverage_id_r = coverage.n_coverage_id_r
    AND coverage.v_active_status_r = 'Y'
    INNER JOIN atomic.dim_grp_product_r product
    ON coverage.v_code_r = product.v_coverage_code_r
    AND product.v_active_status_r = 'Y'
    INNER JOIN atomic.fct_billing_policy_premium_r plcy_prem
    ON bill_plcy_cvrg.n_policy_coverage_id_r = plcy_prem.n_src_coverage_id_r
    INNER JOIN atomic.dim_grp_billing_pol_billgrp_r billgrp
    ON billgrp.n_policy_billgroup_id_r = plcy_prem.n_src_policy_billgroup_id_r
    AND billgrp.n_policy_sk_r = plcy_prem.n_policy_sk_r
    AND billgrp.v_source_system_name_r = 'VUE'
    AND billgrp.v_active_status_r = 'Y'
    INNER JOIN atomic.dim_grp_policy_dir_r plcy_dir
    ON plcy_dir.n_policy_sk_r = billgrp.n_policy_sk_r
    AND plcy_dir.v_active_status_r = 'Y'
    LEFT OUTER JOIN atomic.fct_grp_policy_r plcy
    ON plcy_dir.n_policy_sk_r = plcy.n_policy_sk_r
    AND plcy_dir.n_policy_version_number_r = plcy.n_version_number_r
    INNER JOIN atomic.dim_grp_customer_bill_group_r cust_bill_grp
    ON cust_bill_grp.n_customer_billgroup_id_r = billgrp.n_customer_billgroup_id_r
    AND cust_bill_grp.v_active_status_r = 'Y'
    INNER JOIN atomic.dim_bill_plan bill_plan
    ON plcy_prem.n_src_class_id_r = bill_plan.v_bill_plan_code
    AND bill_plan.v_active_status_r = 'Y'
    INNER JOIN atomic.dim_grp_bill_prem_ratestatus_r rate_sts
    ON bill_plan.n_policy_plan_sk_r = rate_sts.n_policy_plan_sk_r
    AND(rate_sts.n_status_id_r = 192
     OR rate_sts.d_status_date_r > current_date)
    AND rate_sts.d_effective_date_r <= current_date
    AND rate_sts.v_active_status_r = 'Y'
    INNER JOIN atomic.dim_grp_billng_premium_rate_r  prem_rate
    ON prem_rate.n_rate_status_id_r = rate_sts.n_rate_status_id_r
    AND prem_rate.v_active_status_r = 'Y'
    WHERE bill_plcy_cvrg.v_active_status_r = 'Y'
    GROUP BY plcy_dir.v_policy_prefix_r,
      product.v_basic_product_line_desc_r,
      product.v_product_sub_line_code_r,
      plcy_dir.v_policy_suffix_r,
      product.n_product_sk_r,
      plcy_dir.n_policy_sk_r,
      billgrp.n_policy_billgroup_sk_r,
      plcy.n_cust_party_sk_r;