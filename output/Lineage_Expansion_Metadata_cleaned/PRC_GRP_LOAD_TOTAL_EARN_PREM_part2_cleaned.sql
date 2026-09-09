-- Cleaned for lineage: PRC_GRP_LOAD_TOTAL_EARN_PREM (part 2/6)

INSERT  INTO fct_rpt_earn_due_prem_temp1 
                SELECT
                    *
                FROM
                    (
                        WITH batch_date AS (
                            SELECT
                                *
                            FROM
                                (
                                    SELECT
                                        d_calendar_date_r,
                                        RANK()
                                        OVER(
                                            ORDER BY
                                                d_calendar_date_r DESC
                                        ) date_rank
                                    FROM
                                        atomic.dim_time_r
                                    WHERE
                                            v_end_of_fiscal_month_ind_r = 'Y'
                                        AND d_calendar_date_r < ( to_date(substr(ln_n_batch_id_r, 1, 8), 'YYYYMMDD') )
                                )
                            WHERE
                                date_rank < 3
                        ), fct_grp_policy_table AS (
                            SELECT
                                atomic.fct_grp_policy_r.n_policy_sk_r
                            FROM
                                atomic.fct_grp_policy_r
                            GROUP BY
                                atomic.fct_grp_policy_r.n_policy_sk_r
                        ), current_base_table AS (
                            SELECT
                                *
                            FROM
                                (
                                    SELECT
                                        (
                                            SELECT
                                                batch_date.d_calendar_date_r
                                            FROM
                                                batch_date
                                            WHERE
                                                date_rank = 1
                                        )                                                                AS n_batch_id_r,
                                        CASE
                                            WHEN ss.v_tpa_indicator_r = 0
                                                 AND stg_fct_grp_billing_policy_dtl_r_incr.n_policy_id_r IS NOT NULL THEN
                                                1
                                            WHEN ss.v_tpa_indicator_r = 1
                                                 AND stg_fct_grp_billing_policy_dtl_r_incr.n_policy_id_r IS NULL THEN
                                                1
                                            ELSE
                                                0
                                        END                                                              AS filter_values,	
                                        atomic.fct_billing_policy_premium_r_table.v_source_system_name_r AS v_source_system_name_r,	
                                        atomic.fct_billing_policy_premium_r_table.n_policy_sk_r,
                                        dim_grp_policy_dir_r.v_policy_number_r,
                                        dim_grp_policy_dir_r.v_policy_prefix_r,
                                        dim_grp_policy_dir_r.v_policy_suffix_r,
                                        atomic.fct_billing_policy_premium_r_table.v_coveragecode_r,
                                        atomic.fct_billing_policy_premium_r_table.v_billgroupnumber_r    AS v_customer_bill_group_number_r,
                                        atomic.fct_billing_policy_premium_r_table.d_due_date_r,
                                        dim_grp_carrier_r.v_short_name_r,
                                        atomic.fct_billing_policy_premium_r_table.d_transaction_date_r,
                                        atomic.fct_billing_policy_premium_r_table.n_amount_paid_r        AS n_amount_paid_r,
                                        atomic.fct_billing_policy_premium_r_table.n_premium_type_r,
                                        atomic.fct_billing_policy_premium_r_table.n_months_paid_r,
                                        dim_grp_billing_pol_billgrp_r_table.v_premium_mode1_r,
                                        atomic.dim_grp_product_r.v_product_line_r,
                                        atomic.dim_grp_product_r.v_product_sub_line_code_r               AS v_product_sub_line_r,
                                        dim_grp_billing_pol_billgrp_r_table.v_bill_group_status_r,
                                        stg_fct_grp_billing_policy_dtl_r_incr.v_policy_status_r,
                                        stg_fct_grp_billing_policy_dtl_r_incr.n_create_bill_r,
                                        dim_grp_billing_pol_billgrp_r_table.d_status_date_r              AS bill_group_status_date,
                                        stg_fct_grp_billing_policy_dtl_r_incr.d_status_date_r            AS policy_status_date,
                                        dim_grp_billing_pol_billgrp_r_table.d_paid_to_r,
                                        dim_grp_billing_pol_billgrp_r_table.d_billed_to_r,
                                        CASE
                                            WHEN stg_fct_grp_billing_policy_dtl_r_incr.v_policy_status_r = 'Terminated' THEN
                                                stg_fct_grp_billing_policy_dtl_r_incr.d_status_date_r
                                            ELSE
                                                NULL
                                        END                                                              poltermdate,
                                        CASE
                                            WHEN dim_grp_billing_pol_billgrp_r_table.v_bill_group_status_r = 'Terminated' THEN
                                                dim_grp_billing_pol_billgrp_r_table.d_status_date_r
                                            ELSE
                                                NULL
                                        END                                                              bgtermdate,
                                        CASE
                                            WHEN upper(dim_grp_billing_pol_billgrp_r_table.v_premium_mode1_r) = 'MONTHLY'                  THEN
                                                1
                                            WHEN upper(dim_grp_billing_pol_billgrp_r_table.v_premium_mode1_r) = 'QUARTERLY'                THEN
                                                3
                                            WHEN upper(dim_grp_billing_pol_billgrp_r_table.v_premium_mode1_r) = 'SEMIANNUALLY'             THEN
                                                6
                                            WHEN upper(dim_grp_billing_pol_billgrp_r_table.v_premium_mode1_r) = 'NINTHLY'                  THEN
                                                9
                                            WHEN upper(dim_grp_billing_pol_billgrp_r_table.v_premium_mode1_r) = 'TENTHLY'                  THEN
                                                10
                                            WHEN upper(dim_grp_billing_pol_billgrp_r_table.v_premium_mode1_r) = 'ANNUALLY'                 THEN
                                                12
                                            WHEN upper(dim_grp_billing_pol_billgrp_r_table.v_premium_mode1_r) = '3 YEARS PRE-PAID'         THEN
                                                36
                                            WHEN upper(dim_grp_billing_pol_billgrp_r_table.v_premium_mode1_r) = '3 YEARS WITH INSTALLMENT' THEN
                                                36
                                            WHEN upper(dim_grp_billing_pol_billgrp_r_table.v_premium_mode1_r) = '5 YEARS PRE-PAID'         THEN
                                                60
                                            WHEN upper(dim_grp_billing_pol_billgrp_r_table.v_premium_mode1_r) = '5 YEARS WITH INSATLLMENT' THEN
                                                60
                                        END                                                              AS premium_mode,
                                        dim_grp_carrier_r.v_short_name_r
                                        || dim_grp_policy_dir_r.v_policy_number_r
                                        || atomic.fct_billing_policy_premium_r_table.v_billgroupnumber_r
                                        || atomic.fct_billing_policy_premium_r_table.v_coveragecode_r
                                        || atomic.fct_billing_policy_premium_r_table.n_premium_type_r
                                        || atomic.fct_billing_policy_premium_r_table.n_months_paid_r
                                        || dim_grp_billing_pol_billgrp_r_table.v_premium_mode1_r
                                        || atomic.fct_billing_policy_premium_r_table.d_due_date_r        AS basekeys
                                    FROM
                                             atomic.fct_billing_policy_premium_r_table
                                        INNER JOIN dim_source_system_r ss ON fct_billing_policy_premium_r_table.v_source_system_name_r =
                                        ss.v_source_system_code_r
                                        LEFT OUTER JOIN (
                                            SELECT
                                                *
                                            FROM
                                                atomic.dim_grp_policy_dir_r
                                            WHERE
                                                v_active_status_r = 'Y'
                                        )                   dim_grp_policy_dir_r ON atomic.fct_billing_policy_premium_r_table.n_policy_sk_r =
                                        dim_grp_policy_dir_r.n_policy_sk_r
                                        LEFT OUTER JOIN atomic.stg_fct_grp_billing_policy_dtl_r_incr ON atomic.fct_billing_policy_premium_r_table.
                                        n_src_policy_id_r = stg_fct_grp_billing_policy_dtl_r_incr.n_policy_id_r  
                                        LEFT OUTER JOIN (
                                            SELECT
                                                n_carrier_id_r,
                                                v_short_name_r
                                            FROM
                                                atomic.dim_grp_carrier_r
                                            WHERE
                                                v_source_system_name_r = 'VUE'
                                        )                   dim_grp_carrier_r ON stg_fct_grp_billing_policy_dtl_r_incr.n_carrier_id_r =
                                        dim_grp_carrier_r.n_carrier_id_r  
                                        LEFT OUTER JOIN (
                                            SELECT
                                                *
                                            FROM
                                                atomic.dim_grp_billing_pol_billgrp_r bp
                                            WHERE 
                                                    bp.v_source_system_name_r <> 'APS'
                                                AND 
                                                 bp.d_record_start_date_r <= (
                                                    SELECT
                                                        trunc(batch_date.d_calendar_date_r)
                                                    FROM
                                                        batch_date
                                                    WHERE
                                                        date_rank = 1
                                                )
                                                AND bp.d_record_end_date_r > (
                                                    SELECT
                                                        trunc(batch_date.d_calendar_date_r)
                                                    FROM
                                                        batch_date
                                                    WHERE
                                                        date_rank = 1
                                                )
                                        )                   dim_grp_billing_pol_billgrp_r_table ON dim_grp_billing_pol_billgrp_r_table.
                                        n_policy_billgroup_id_r = fct_billing_policy_premium_r_table.n_src_policy_billgroup_id_r
                                        LEFT OUTER JOIN atomic.dim_grp_product_r ON atomic.fct_billing_policy_premium_r_table.v_coveragecode_r =
                                        atomic.dim_grp_product_r.v_coverage_code_r
                                )
                            WHERE
                                filter_values = 1
                        ), dim_grp_billing_pol_billgrp_r_due AS (
                            SELECT
                                p.v_policy_number_r,
                                (
                                    SELECT
                                        batch_date.d_calendar_date_r
                                    FROM
                                        batch_date
                                    WHERE
                                        date_rank = 1
                                )   AS cycle_date,
                                pd.n_create_bill_r,
                                bp.*,
                                CASE
                                    WHEN upper(bp.v_premium_mode1_r) = 'MONTHLY'                  THEN
                                        1
                                    WHEN upper(bp.v_premium_mode1_r) = 'QUARTERLY'                THEN
                                        3
                                    WHEN upper(bp.v_premium_mode1_r) = 'SEMIANNUALLY'             THEN
                                        6
                                    WHEN upper(bp.v_premium_mode1_r) = 'NINTHLY'                  THEN
                                        9
                                    WHEN upper(bp.v_premium_mode1_r) = 'TENTHLY'                  THEN
                                        10
                                    WHEN upper(bp.v_premium_mode1_r) = 'ANNUALLY'                 THEN
                                        12
                                    WHEN upper(bp.v_premium_mode1_r) = '3 YEARS PRE-PAID'         THEN
                                        36
                                    WHEN upper(bp.v_premium_mode1_r) = '3 YEARS WITH INSTALLMENT' THEN
                                        36
                                    WHEN upper(bp.v_premium_mode1_r) = '5 YEARS PRE-PAID'         THEN
                                        60
                                    WHEN upper(bp.v_premium_mode1_r) = '5 YEARS WITH INSATLLMENT' THEN
                                        60
                                END AS premium_mode,
                                CASE
                                    WHEN pd.v_policy_status_r = 'Terminated' THEN
                                        pd.d_status_date_r
                                    ELSE
                                        NULL
                                END poltermdate,
                                CASE
                                    WHEN bp.v_bill_group_status_r = 'Terminated' THEN
                                        bp.d_status_date_r
                                    ELSE
                                        NULL
                                END bgtermdate
                            FROM
                                     (
                                    SELECT
                                        *
                                    FROM
                                        atomic.dim_grp_billing_pol_billgrp_r
                                    WHERE
                                        v_source_system_name_r <> 'APS'
                                ) bp 
                                INNER JOIN atomic.stg_fct_grp_billing_policy_dtl_r_incr pd ON bp.n_policy_sk_r = pd.n_policy_sk_r
                                LEFT JOIN atomic.dim_grp_policy_dir_r                  p ON p.n_policy_sk_r = bp.n_policy_sk_r
                                                                           AND p.v_active_status_r = 'Y'
                            WHERE
                                    trunc(bp.d_record_start_date_r) <= (
                                        SELECT
                                            trunc(batch_date.d_calendar_date_r)
                                        FROM
                                            batch_date
                                        WHERE
                                            date_rank = 1
                                    ) 
                                AND trunc(bp.d_record_end_date_r) > (
                                    SELECT
                                        trunc(batch_date.d_calendar_date_r)
                                    FROM
                                        batch_date
                                    WHERE
                                        date_rank = 1
                                )
                                AND ( bp.d_delete_date_r IS NULL
                                      OR trunc(bp.d_delete_date_r) > (
                                    SELECT
                                        trunc(batch_date.d_calendar_date_r)
                                    FROM
                                        batch_date
                                    WHERE
                                        date_rank = 1
                                ) )
                        ), due_query_base AS (
                            SELECT
                                cycle_date,
                                pb.n_policy_sk_r,
                                pb.n_customer_billgroup_id_r,
                                pb.n_policy_billgroup_id_r,
                                pb.d_paid_to_r,
                                pb.d_billed_to_r,
                                pb.premium_mode  monthspaid,
                                (
                                    SELECT
                                        months_between((
                                            CASE
                                                WHEN pb.v_policy_number_r LIKE 'SR%' THEN
                                                    last_day(trunc(cycle_date) - 10)
                                                WHEN nvl(pb.n_create_bill_r, 0) = 0 THEN
                                                    last_day(trunc(cycle_date) - 10)
                                                ELSE
                                                    pb.d_billed_to_r
                                            END
                                        ), add_months(MAX(d_due_date_r), premium_mode))
                                    FROM
                                        (
                                            SELECT
                                                d_due_date_r,
                                                SUM(round(p.n_amount_paid_r, 2)),
                                                p.n_policy_sk_r,
                                                p.n_src_policy_billgroup_id_r
                                            FROM
                                                fct_billing_policy_premium_r_table p
                                            WHERE
                                                    d_transaction_date_r <= last_day(trunc(cycle_date) - 10)
                                                AND n_premium_type_r IN ( 313, 344 )
                                            GROUP BY
                                                p.n_policy_sk_r,
                                                p.n_src_policy_billgroup_id_r,
                                                p.d_due_date_r
                                            HAVING
                                                SUM(p.n_amount_paid_r) > 0
                                        ) p1
                                    WHERE
                                            p1.n_policy_sk_r = pb.n_policy_sk_r
                                        AND p1.n_src_policy_billgroup_id_r = pb.n_policy_billgroup_id_r
                                ) / premium_mode count,
                                (
                                    SELECT
                                        add_months(MAX(d_due_date_r), premium_mode)
                                    FROM
                                        (
                                            SELECT
                                                d_due_date_r,
                                                SUM(round(p.n_amount_paid_r, 2)),
                                                n_policy_sk_r,
                                                n_src_policy_billgroup_id_r
                                            FROM
                                                fct_billing_policy_premium_r_table p
                                            WHERE
                                                    d_transaction_date_r <= last_day(trunc(cycle_date) - 10)
                                                AND n_premium_type_r IN ( 313, 344 )
                                            GROUP BY
                                                p.n_policy_sk_r,
                                                p.n_src_policy_billgroup_id_r,
                                                p.d_due_date_r
                                            HAVING
                                                SUM(p.n_amount_paid_r) > 0
                                        ) p1
                                    WHERE
                                            p1.n_policy_sk_r = pb.n_policy_sk_r
                                        AND p1.n_src_policy_billgroup_id_r = pb.n_policy_billgroup_id_r
                                )                premiumdue,
                                pb.poltermdate,
                                pb.bgtermdate,
                                pb.v_source_system_name_r
                            FROM
                                dim_grp_billing_pol_billgrp_r_due pb
                            WHERE
                                pb.d_billed_to_r IS NOT NULL
                                AND pb.d_paid_to_r IS NOT NULL
                        )
                        SELECT
                            *
                        FROM
                            due_query_base
                    );