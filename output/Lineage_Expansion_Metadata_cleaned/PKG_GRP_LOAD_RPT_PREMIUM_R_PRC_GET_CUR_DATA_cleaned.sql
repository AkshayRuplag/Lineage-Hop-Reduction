-- Cleaned for lineage: PKG_GRP_LOAD_RPT_PREMIUM_R_PRC_GET_CUR_DATA

INSERT  INTO rpt_premium_r_exg stg
        SELECT 
            gn_current_month                     AS n_reportmonth_r,
            v_billing_premium_mode_r             AS v_billing_premium_mode_r,
            v_max_due_date_flag_r                AS v_max_due_date_flag_r,
            v_operator_id_r                      AS v_operator_id_r,
            v_premium_coverage_code_r            AS v_premium_coverage_code_r,
            v_premium_coverage_description_r     AS v_premium_coverage_description_r,
            d_premium_due_date_r                 AS d_premium_due_date_r,
            n_premium_month_paid_r               AS n_premium_month_paid_r,
            v_premium_net_gross_indicator_r      AS v_premium_net_gross_indicator_r,
            d_premium_paid_to_date_r             AS d_premium_paid_to_date_r,
            n_premium_payment_id_r               AS n_premium_payment_id_r,
            v_premium_payment_method_r           AS v_premium_payment_method_r,
            v_premium_payment_premium_type_r     AS v_premium_payment_premium_type_r,
            v_premium_product_line_r             AS v_premium_product_line_r,
            v_premium_product_line_description_r AS v_premium_product_line_description_r,
            v_premium_sub_line_code_r            AS v_premium_sub_line_code_r,
            d_premium_transaction_date_r         AS d_premium_transaction_date_r,
            v_product_line_code_r                AS v_product_line_code_r,
            gc_getcur_loadedby                   AS v_last_modified_by_r,
            systimestamp                         AS t_creation_date_r,
            gc_getcur_loadedby                   AS v_created_by_r,
            systimestamp                         AS t_last_modified_date_r,
            'Y'                                  AS v_rpt_active_status_r,
            gn_sysdt_batchid                     AS n_batch_id_r,
            d_premium_max_due_date_r             AS d_premium_max_due_date_r,
            n_months_paid_r                      AS n_months_paid_r,
            v_source_system_name_r               AS v_source_system_name_r,
            d_premium_src_transaction_date_r     AS d_premium_src_transaction_date_r	 
        FROM
            atomic.rpt_premium_r_drq_mv_ssl src;