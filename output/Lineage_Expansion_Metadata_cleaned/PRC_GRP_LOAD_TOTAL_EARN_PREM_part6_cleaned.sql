-- Cleaned for lineage: PRC_GRP_LOAD_TOTAL_EARN_PREM (part 6/6)

INSERT  INTO fct_rpt_earn_premium_summary_r_incr
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
                                date_rank < 4
                        ), due_date_filter AS (
                            SELECT
                                (
                                    SELECT
                                        to_date(to_char(d_calendar_date_r, 'mmyy'), 'MMYY')
                                    FROM
                                        batch_date
                                    WHERE
                                        date_rank = 3
                                ) due_date_filter,
                                (
                                    SELECT
                                        d_calendar_date_r
                                    FROM
                                        batch_date
                                    WHERE
                                        date_rank = 1
                                ) cycle_date
                            FROM
                                dual
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
                                        atomic.fct_billing_policy_premium_r_table.v_source_system_name_r AS v_source_system_name_r,
                                        atomic.fct_billing_policy_premium_r_table.d_sr_statement_date_r  AS d_sr_statement_date_r,
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
                                        (
                                            SELECT
                                                batch_date.d_calendar_date_r
                                            FROM
                                                batch_date
                                            WHERE
                                                date_rank = 1
                                        )                                                                AS n_batch_id_r,
                                        (
                                            SELECT
                                                batch_date.d_calendar_date_r
                                            FROM
                                                batch_date
                                            WHERE
                                                date_rank = 2
                                        )                                                                AS prior_n_batch_id_r,
                                        atomic.fct_billing_policy_premium_r_table.n_policy_sk_r,
                                        atomic.fct_billing_policy_premium_r_table.n_src_premium_payment_id_r,
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
                                                 trunc(bp.d_record_start_date_r) <= (
                                                    SELECT
                                                        batch_date.d_calendar_date_r
                                                    FROM
                                                        batch_date
                                                    WHERE
                                                        date_rank = 1
                                                )
                                                AND trunc(bp.d_record_end_date_r) > (
                                                    SELECT
                                                        batch_date.d_calendar_date_r
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
                        ), collected_premium_table_pre AS (
                            SELECT DISTINCT
                                d_sr_statement_date_r, 
                                v_source_system_name_r,
                                n_batch_id_r,
                                prior_n_batch_id_r,
                                n_policy_sk_r,
                                v_policy_number_r,
                                v_policy_prefix_r,
                                v_policy_suffix_r,
                                v_coveragecode_r,
                                v_customer_bill_group_number_r,
                                d_due_date_r,
                                v_short_name_r,
                                d_transaction_date_r,
                                n_premium_type_r,
                                n_months_paid_r,
                                v_premium_mode1_r,
                                premium_mode,
                                n_amount_paid_r,
                                n_src_premium_payment_id_r
                            FROM
                                current_base_table
                        ), collected_premium_table1 AS (
                            SELECT
                                c.v_source_system_name_r,
                                c.n_batch_id_r,
                                c.prior_n_batch_id_r,
                                c.n_policy_sk_r,
                                c.v_policy_number_r,
                                c.v_policy_prefix_r,
                                c.v_policy_suffix_r,
                                c.v_coveragecode_r,
                                c.v_customer_bill_group_number_r,
                                c.d_due_date_r,
                                c.v_short_name_r,
                                c.d_transaction_date_r,
                                c.v_premium_mode1_r,
                                c.premium_mode,
                                SUM(
                                    CASE
                                        WHEN to_char(d_transaction_date_r, 'MMYYYY') = to_char(n_batch_id_r, 'MMYYYY')
                                             AND ss.v_tpa_indicator_r = 1
                                             AND d_sr_statement_date_r IS NULL THEN
                                            round(n_amount_paid_r, 2)
                                        WHEN ss.v_tpa_indicator_r = 0
                                             AND to_char(d_transaction_date_r, 'MMYYYY') = to_char(n_batch_id_r, 'MMYYYY') THEN
                                            round(c.n_amount_paid_r, 2)
                                        ELSE
                                            0.00
                                    END
                                ) AS collected_premium, 
                                SUM(
                                    CASE
                                        WHEN n_premium_type_r = 314 THEN
                                            0
                                        WHEN add_months(d_due_date_r,
                                                        CASE
                                                            WHEN substr(v_policy_number_r, 1, 2) = 'SR' THEN
                                                                n_months_paid_r
                                                            ELSE
                                                                premium_mode
                                                        END
                                        ) < trunc(add_months((
                                            SELECT
                                                batch_date.d_calendar_date_r
                                            FROM
                                                batch_date
                                            WHERE
                                                date_rank = 1
                                        ), 1), 'mm') - 1       THEN
                                            0
                                        WHEN d_due_date_r > trunc(add_months((
                                            SELECT
                                                batch_date.d_calendar_date_r
                                            FROM
                                                batch_date
                                            WHERE
                                                date_rank = 1
                                        ), 1), 'mm') - 1       THEN
                                            round(n_amount_paid_r, 2)
                                        ELSE
                                            CASE
                                                    WHEN EXTRACT(DAY FROM d_due_date_r) = 1   THEN
                                                        round(n_amount_paid_r, 2) -(trunc(((round(n_amount_paid_r, 2) /
                                                                                            CASE
                                                                                                WHEN substr(v_policy_number_r, 1, 2) =
                                                                                                'SR' THEN
                                                                                                        CASE
                                                                                                            WHEN n_months_paid_r = 0 THEN
                                                                                                                1
                                                                                                            ELSE
                                                                                                                n_months_paid_r
                                                                                                        END
                                                                                                ELSE
                                                                                                    premium_mode
                                                                                            END
                                                        ) * round(months_between(n_batch_id_r, d_due_date_r))), 2))
                                                    WHEN EXTRACT(DAY FROM d_due_date_r) >= 28 THEN
                                                        round(n_amount_paid_r, 2) -(trunc(((round(n_amount_paid_r, 2) /
                                                                                            CASE
                                                                                                WHEN substr(v_policy_number_r, 1, 2) =
                                                                                                'SR' THEN
                                                                                                        CASE
                                                                                                            WHEN n_months_paid_r = 0 THEN
                                                                                                                1
                                                                                                            ELSE
                                                                                                                n_months_paid_r
                                                                                                        END
                                                                                                ELSE
                                                                                                    premium_mode
                                                                                            END
                                                        ) * round(months_between(to_date(trunc(add_months((
                                                            SELECT
                                                                batch_date.d_calendar_date_r
                                                            FROM
                                                                batch_date
                                                            WHERE
                                                                date_rank = 1
                                                        ), 1), 'mm') - 1), d_due_date_r))), 2))
                                                    ELSE
                                                        round(n_amount_paid_r, 2) -(trunc(((round(n_amount_paid_r, 2) /
                                                                                            CASE
                                                                                                WHEN substr(v_policy_number_r, 1, 2) =
                                                                                                'SR' THEN
                                                                                                        CASE
                                                                                                            WHEN n_months_paid_r = 0 THEN
                                                                                                                1
                                                                                                            ELSE
                                                                                                                n_months_paid_r
                                                                                                        END
                                                                                                ELSE
                                                                                                    premium_mode
                                                                                            END
                                                        ) * floor(months_between(to_date(trunc(add_months((
                                                            SELECT
                                                                batch_date.d_calendar_date_r
                                                            FROM
                                                                batch_date
                                                            WHERE
                                                                date_rank = 1
                                                        ), 1), 'mm') - 1), to_date(to_char(d_due_date_r, 'MM/YYYY'), 'MM/YYYY')) + 1)),
                                                        2) - trunc(((round(n_amount_paid_r, 2) /
                                                                                                                                                  CASE
                                                                                                                                                      WHEN
                                                                                                                                                      n_months_paid_r =
                                                                                                                                                      0
                                                                                                                                                      THEN
                                                                                                                                                          1
                                                                                                                                                      ELSE
                                                                                                                                                          n_months_paid_r
                                                                                                                                                  END
                                                        ) / 30) *(trunc(d_due_date_r) - to_date(to_char(d_due_date_r, 'mmyy'), 'MMYY')),
                                                        2))
                                            END
                                    END
                                ) AS unearned_premium
                            FROM
                                     collected_premium_table_pre c
                                INNER JOIN dim_source_system_r ss ON c.v_source_system_name_r = ss.v_source_system_code_r
                            GROUP BY
                                c.v_source_system_name_r,
                                c.n_batch_id_r,
                                c.prior_n_batch_id_r,
                                c.n_policy_sk_r,
                                c.v_policy_number_r,
                                c.v_policy_prefix_r,
                                c.v_policy_suffix_r,
                                c.v_coveragecode_r,
                                c.v_customer_bill_group_number_r,
                                c.d_due_date_r,
                                c.v_short_name_r, 
                                c.d_transaction_date_r,
                                c.v_premium_mode1_r,
                                c.premium_mode
                        ), collected_premium_table AS (
                            SELECT DISTINCT
                                v_source_system_name_r,
                                n_batch_id_r,
                                prior_n_batch_id_r,
                                n_policy_sk_r,
                                v_policy_number_r,
                                v_coveragecode_r,
                                v_customer_bill_group_number_r,
                                d_due_date_r,
                                v_short_name_r,
                                SUM(collected_premium) collected_premium,
                                SUM(unearned_premium)  unearned_premium
                            FROM
                                collected_premium_table1
                            WHERE
                                    collected_premium_table1.d_transaction_date_r <= (
                                        SELECT
                                            batch_date.d_calendar_date_r
                                        FROM
                                            batch_date
                                        WHERE
                                            date_rank = 1
                                    )
                                AND ( collected_premium_table1.d_transaction_date_r > (
                                    SELECT
                                        batch_date.d_calendar_date_r
                                    FROM
                                        batch_date
                                    WHERE
                                        date_rank = 2
                                )
                                      OR ( ( unearned_premium <> 0 )
                                           OR NOT ( coalesce(collected_premium, 0) = 0
                                                    AND coalesce(unearned_premium, 0) = 0
                                                    AND trunc(d_transaction_date_r) < (
                                    SELECT
                                        batch_date.d_calendar_date_r
                                    FROM
                                        batch_date
                                    WHERE
                                        date_rank = 2
                                ) ) ) )
                            GROUP BY
                                v_source_system_name_r,
                                n_batch_id_r, 
                                prior_n_batch_id_r,
                                n_policy_sk_r,
                                v_policy_number_r,
                                v_coveragecode_r,
                                v_customer_bill_group_number_r,
                                d_due_date_r,
                                v_short_name_r
                        ), prior_base_collected AS (
                            SELECT DISTINCT
							    v_source_system_name_r,
                                v_policy_number_r,
                                (
                                    SELECT
                                        batch_date.d_calendar_date_r
                                    FROM
                                        batch_date
                                    WHERE
                                        date_rank = 2
                                )                                          AS prior_cycle_date,
                                v_coverage_code_r,
                                d_due_date_r                               AS d_due_date_r,
                                v_customer_bill_group_number_r,
                                v_short_name_r,
                                n_policy_sk_r,
                                nvl(eu.n_collected_premium_amt_r, 0)       AS n_collected_premium_amt_r,
                                nvl(n_collected_premium_unearned_amt_r, 0) AS n_collected_premium_unearned_amt_r
                            FROM
                                fct_rpt_earn_premium_summary_prior_r eu
                            WHERE
                                    d_cycle_date_r = (
                                        SELECT
                                            batch_date.d_calendar_date_r
                                        FROM
                                            batch_date
                                        WHERE
                                            date_rank = 2
                                    )
                                AND ( eu.n_collected_premium_amt_r != 0
                                      OR n_collected_premium_unearned_amt_r != 0 )
                        ), prior_change_collected AS (
                            SELECT DISTINCT
                                coalesce(cb.v_source_system_name_r,eu.v_source_system_name_r)                                                  AS v_source_system_name_r, 
                                nvl(prior_n_batch_id_r, prior_cycle_date)                                      AS d_prior_cycle_date,
                                coalesce(cb.v_policy_number_r, eu.v_policy_number_r)                           AS v_policy_number_r,
                                coalesce(cb.v_customer_bill_group_number_r, eu.v_customer_bill_group_number_r) AS v_customer_bill_group_number_r,
                                coalesce(cb.v_coveragecode_r, eu.v_coverage_code_r)                            AS v_coverage_code_r,
                                coalesce(cb.d_due_date_r, eu.d_due_date_r)                                     AS d_due_date_r,
                                coalesce(cb.v_short_name_r, eu.v_short_name_r)                                 AS v_short_name_r,
                                coalesce(cb.n_policy_sk_r, eu.n_policy_sk_r)                                   AS n_policy_sk_r,
                                nvl(cb.collected_premium, 0)                                                   AS current_n_collected_premium_amt_r,
                                nvl(cb.unearned_premium, 0)                                                    AS current_n_collected_premium_unearned_amt_r,
                                nvl(eu.n_collected_premium_amt_r, 0)                                           AS n_prior_collected_premium_amt_r,
                                nvl(eu.n_collected_premium_unearned_amt_r, 0)                                  AS n_prior_collected_premium_unearned_amt_r,
                                nvl(cb.collected_premium, 0) - nvl(eu.n_collected_premium_amt_r, 0)            AS n_mtd_chg_collected_premium_amt_r,
                                nvl(cb.unearned_premium, 0) - nvl(eu.n_collected_premium_unearned_amt_r, 0)    AS n_mtd_collected_premium_unearned_amt_r
                            FROM
                                collected_premium_table cb
                                FULL JOIN prior_base_collected    eu ON eu.prior_cycle_date = cb.prior_n_batch_id_r
								                                     AND eu.v_source_system_name_r = cb.v_source_system_name_r
                                                                     AND eu.v_policy_number_r = cb.v_policy_number_r
                                                                     AND eu.v_customer_bill_group_number_r = cb.v_customer_bill_group_number_r
                                                                     AND eu.v_coverage_code_r = cb.v_coveragecode_r
                                                                     AND eu.d_due_date_r = cb.d_due_date_r
                        ), final_collected_table1 AS (
                            SELECT DISTINCT
                                collected_premium_table.v_source_system_name_r AS v_source_system_name_r,	
                                (
                                    SELECT
                                        batch_date.d_calendar_date_r
                                    FROM
                                        batch_date
                                    WHERE
                                        date_rank = 1
                                )                                              d_cycle_date_r,
                                d_prior_cycle_date                             d_prior_cycle_date_r,
                                collected_premium_table.d_due_date_r,
                                collected_premium_table.n_policy_sk_r,
                                collected_premium_table.v_policy_number_r,
                                collected_premium_table.v_customer_bill_group_number_r,
                                collected_premium_table.v_short_name_r,
                                collected_premium_table.v_coverage_code_r      AS v_coverage_code_r,
                                current_n_collected_premium_amt_r,
                                current_n_collected_premium_unearned_amt_r,
                                n_prior_collected_premium_amt_r,
                                n_prior_collected_premium_unearned_amt_r,
                                n_mtd_chg_collected_premium_amt_r,
                                n_mtd_collected_premium_unearned_amt_r
                            FROM
                                prior_change_collected collected_premium_table
                        ), final_collected_table AS (
                            SELECT
                                collected_premium_table.v_source_system_name_r,  
                                d_cycle_date_r,
                                d_prior_cycle_date_r,
                                collected_premium_table.d_due_date_r,
                                collected_premium_table.n_policy_sk_r,
                                collected_premium_table.v_policy_number_r,
                                collected_premium_table.v_customer_bill_group_number_r,
                                collected_premium_table.v_short_name_r,
                                collected_premium_table.v_coverage_code_r       AS v_coverage_code_r,
                                SUM(current_n_collected_premium_amt_r)          n_collected_premium_amt_r,
                                SUM(current_n_collected_premium_unearned_amt_r) n_collected_premium_unearned_amt_r,
                                SUM(n_prior_collected_premium_amt_r)            n_prior_collected_premium_amt_r,
                                SUM(n_prior_collected_premium_unearned_amt_r)   n_prior_collected_premium_unearned_amt_r,
                                SUM(n_mtd_chg_collected_premium_amt_r)          n_mtd_chg_collected_premium_amt_r,
                                SUM(n_mtd_collected_premium_unearned_amt_r)     n_mtd_collected_premium_unearned_amt_r
                            FROM
                                final_collected_table1 collected_premium_table
                            GROUP BY
                                collected_premium_table.v_source_system_name_r,	
                                d_cycle_date_r,
                                d_prior_cycle_date_r,
                                collected_premium_table.d_due_date_r,
                                collected_premium_table.n_policy_sk_r,
                                collected_premium_table.v_policy_number_r,
                                collected_premium_table.v_customer_bill_group_number_r,
                                collected_premium_table.v_short_name_r,
                                collected_premium_table.v_coverage_code_r
                        ), dim_grp_billing_pol_billgrp_r_due AS (
                            SELECT DISTINCT
                                p.v_policy_number_r,
                                (
                                    SELECT
                                        batch_date.d_calendar_date_r
                                    FROM
                                        batch_date
                                    WHERE
                                        date_rank = 1
                                )   AS cycle_date,
                                (
                                    SELECT
                                        batch_date.d_calendar_date_r
                                    FROM
                                        batch_date
                                    WHERE
                                        date_rank = 2
                                )   AS prior_n_batch_id_r,
                                pd.n_create_bill_r,
                                bp.*,
                                p.v_policy_prefix_r,
                                p.v_policy_suffix_r,
                                pd.n_carrier_id_r,
                                dim_grp_carrier_r.v_short_name_r,
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
                                LEFT JOIN atomic.dim_grp_policy_dir_r p                    ON p.n_policy_sk_r = bp.n_policy_sk_r
                                                                                           AND p.v_active_status_r = 'Y'
                                LEFT OUTER JOIN (
                                    SELECT
                                        n_carrier_id_r,
                                        v_short_name_r
                                    FROM
                                        atomic.dim_grp_carrier_r
                                    WHERE
                                        v_source_system_name_r = 'VUE'
                                )                                            dim_grp_carrier_r ON pd.n_carrier_id_r = dim_grp_carrier_r.
                                n_carrier_id_r 
                            WHERE
                                bp.v_active_status_r = 'Y'
                        ), max_due_date AS (
                            SELECT
                                MAX(d_due_date_r) d_due_date_r,
                                n_policy_billgroup_id_r,
                                n_policy_sk_r
                            FROM
                                (
                                    SELECT
                                        d_due_date_r,
                                        SUM(n_amount_paid_r) amountpaid,
                                        v_policy_number_r,
                                        n_policy_billgroup_id_r,
                                        p1.n_policy_sk_r,
                                        n_customer_billgroup_id_r
                                    FROM
                                             fct_billing_policy_premium_r_table p1
                                        INNER JOIN atomic.dim_source_system_r        b 
                                         ON p1.v_source_system_name_r = b.v_source_system_code_r
                                        INNER JOIN dim_grp_billing_pol_billgrp_r_due pb ON p1.n_policy_sk_r = pb.n_policy_sk_r
                                                                                        AND p1.n_src_policy_billgroup_id_r = pb.n_policy_billgroup_id_r
                                    WHERE
                                        ( nvl(upper(v_user_name_r), 'NA') <> 'SUSPENSE ADJUSTMENT' )  
                                        AND d_transaction_date_r < cycle_date + 1
                                        AND ( ( b.v_tpa_indicator_r = 0
                                                AND n_premium_type_r IN ( 313, 344 ) )
                                              OR ( b.v_tpa_indicator_r = 1
                                                   AND n_premium_type_r IN ( 313, 314, 344 ) ) ) 
                                    GROUP BY
                                        v_policy_number_r,
                                        n_policy_billgroup_id_r,
                                        p1.n_policy_sk_r,
                                        n_customer_billgroup_id_r,
                                        d_due_date_r
                                    HAVING
                                        SUM(n_amount_paid_r) > 0
                                ) p1
                            GROUP BY
                                n_policy_billgroup_id_r,
                                n_policy_sk_r
                        ), due_premium_base AS (
                            SELECT DISTINCT
                                pbd.cycle_date            d_cycle_date_r,
                                prior_n_batch_id_r,
                                pb.v_policy_number_r
                                ,
                                CASE
                                    WHEN pbd.v_tpa_indicator_r = 0 THEN
                                        pbd.duedate
                                    WHEN pbd.v_tpa_indicator_r = 1 THEN
                                        p1.d_due_date_r
                                END                       d_due_date_r     
                                ,
                                p1.v_coveragecode_r       v_coveragecode_r,
                                pb.v_short_name_r,
                                pb.premium_mode
                                ,
                                p1.v_billgroupnumber_r    AS v_customer_bill_group_number_r,
                                pb.v_policy_prefix_r,
                                pb.v_policy_suffix_r,
                                (
                                    SELECT
                                        nvl(round(SUM(DISTINCT pt1.n_amount_paid_r), 2), 0)
                                    FROM
                                        fct_billing_policy_premium_r_table pt1
                                    WHERE
                                            pt1.n_src_policy_billgroup_id_r = pbd.n_policy_billgroup_id_r
                                        AND pt1.n_policy_sk_r = pbd.n_policy_sk_r
                                        AND pt1.v_coveragecode_r = pc.v_coverage_code_r
                                        AND pt1.d_due_date_r = md.d_due_date_r
                                        AND d_transaction_date_r < pbd.cycle_date + 1
                                        AND ( ( pbd.v_tpa_indicator_r = 0
                                                AND pt1.n_premium_type_r IN ( 313, 344 ) )
                                              OR ( pbd.v_tpa_indicator_r = 1 
                                               ) )			
                                )                         amountpaid,
                                (
                                    SELECT
                                        nvl(round(SUM(n_amount_due_r), 2), 0)
                                    FROM
                                        fct_billing_policy_premium_r_table pt2
                                    WHERE
                                            pt2.n_src_policy_billgroup_id_r = pbd.n_policy_billgroup_id_r
                                        AND pt2.n_policy_sk_r = pbd.n_policy_sk_r
                                        AND pt2.v_coveragecode_r = pc.v_coverage_code_r
                                        AND pt2.d_due_date_r = md.d_due_date_r
                                        AND pt2.n_amount_due_r <> 0
                                        AND trunc(pt2.d_sr_statement_date_r, 'MM') < trunc(to_date(pbd.cycle_date, 'dd-mon-yy'), 'MM') 
                                )                         AS amountdue		
                                ,
                                nvl(pbd.monthspaid, 0)    AS monthspaid
                                ,
                                d_transaction_date_r
                                ,
                                p1.n_policy_sk_r,
                                pbd.n_policy_billgroup_id_r,
                                pb.n_carrier_id_r
                                ,
                                p1.v_source_system_name_r AS v_source_system_r
                            FROM
                                fct_rpt_earn_due_prem_temp2 pbd
                                INNER JOIN max_due_date md    ON md.n_policy_billgroup_id_r = pbd.n_policy_billgroup_id_r
                                                              AND md.n_policy_sk_r = pbd.n_policy_sk_r
                                INNER JOIN fct_billing_policy_premium_r_table p1 ON p1.n_policy_sk_r = pbd.n_policy_sk_r
                                                                                 AND p1.n_src_policy_billgroup_id_r = pbd.n_policy_billgroup_id_r
                                INNER JOIN dim_grp_product_r                  pc ON p1.v_coveragecode_r = pc.v_coverage_code_r
                                INNER JOIN dim_grp_billing_pol_billgrp_r_due  pb ON p1.n_policy_sk_r = pb.n_policy_sk_r
                                                                                 AND p1.n_src_policy_billgroup_id_r = pb.n_policy_billgroup_id_r
                        ), due_premium_table AS (
                            SELECT
                                c.*,
                                (
                                    CASE
                                        WHEN ( d.v_tpa_indicator_r = 1
                                               AND amountdue <> 0 ) THEN
                                            nvl(round(amountdue, 2), 0)
                                        WHEN ( d.v_tpa_indicator_r = 0 ) THEN
                                            nvl(round(amountpaid, 2), 0)
                                        ELSE
                                            0
                                    END
                                )   AS due_premium, 
                                CASE
                                    WHEN add_months(d_due_date_r, monthspaid) < d_cycle_date_r THEN
                                        round(amountpaid, 2)
                                    WHEN d_due_date_r > d_cycle_date_r                         THEN
                                        0
                                    ELSE
                                        CASE
                                                WHEN to_char(d_due_date_r, 'DD') = '01' THEN
                                                    trunc(((round(amountpaid, 2) / monthspaid) * round(months_between(d_cycle_date_r,
                                                    d_due_date_r))), 2)
                                                WHEN to_char(d_due_date_r, 'DD') >= 28  THEN 
                                                    trunc(((round(amountpaid, 2) / monthspaid) * round(months_between(d_cycle_date_r,
                                                    d_due_date_r))), 2)
                                                ELSE
                                                    trunc(((round(amountpaid, 2) / monthspaid) * floor(months_between(d_cycle_date_r +
                                                    1, to_date(to_char(d_due_date_r, 'MM/YYYY'), 'MM/YYYY')))), 4) - trunc(((round(amountpaid,
                                                    2) / monthspaid) / 30) *(trunc(d_due_date_r) - to_date(to_char(d_due_date_r, 'mmyy'),
                                                    'MMYY')), 2)
                                        END
                                END AS earnedpremium
                            FROM
                                     due_premium_base c
                                INNER JOIN atomic.dim_source_system_r d 
                                 ON c.v_source_system_r = d.v_source_system_code_r
                        ), due_premium_table_final AS (
                            SELECT
                                v_source_system_name_r,	
                                d_cycle_date_r,
                                prior_n_batch_id_r,
                                v_policy_number_r,
                                d_due_date_r,
                                v_coveragecode_r,
                                v_short_name_r,
                                v_customer_bill_group_number_r,
                                v_policy_prefix_r,
                                v_policy_suffix_r,
                                n_policy_sk_r,
                                n_carrier_id_r,
                                SUM(nvl(due_premium, 0))      AS due_premium,
                                SUM(nvl(earnedpremium, 0))    AS earnedpremium,
                                SUM(nvl(unearned_premium, 0)) AS unearned_premium
                            FROM
                                fct_rpt_earn_final_due_prem_temp
                            GROUP BY
                                v_source_system_name_r,	
                                d_cycle_date_r,
                                prior_n_batch_id_r,
                                v_policy_number_r,
                                d_due_date_r,
                                v_coveragecode_r,
                                v_short_name_r,
                                v_customer_bill_group_number_r,
                                v_policy_prefix_r,
                                v_policy_suffix_r,
                                n_policy_sk_r,
                                n_policy_billgroup_id_r,
                                n_carrier_id_r
                        ), prior_base_due AS (
                            SELECT DISTINCT
                                eu.v_source_system_name_r,	
                                v_policy_number_r,
                                aa.d_calendar_date_r                        AS d_cycle_date_r,
                                bb.d_calendar_date_r                        AS prior_cycle_date,
                                v_coverage_code_r,
                                d_due_date_r                                AS d_due_date_r,
                                v_customer_bill_group_number_r,
                                v_short_name_r,
                                n_policy_sk_r,
                                SUM(nvl(eu.n_due_prem_amt_r_all, 0))        AS n_due_prem_amt_r_all,
                                SUM(nvl(eu.n_due_prem_unearned_amt_all, 0)) AS n_due_prem_unearned_amt_all,
                                SUM(nvl(eu.n_due_prem_amt_r, 0))            AS n_due_prem_amt_r,
                                SUM(nvl(eu.n_due_prem_unearned_amt, 0))     AS n_due_prem_unearned_amt,
                                SUM(nvl(eu.n_prem_unearned_amt, 0))         AS n_prem_unearned_amt,
                                SUM(nvl(eu.n_prem_unearned_amt_all, 0))     AS n_prem_unearned_amt_all
                            FROM
                                     fct_rpt_earn_premium_summary_prior_r eu
                                INNER JOIN (
                                    SELECT
                                        d_calendar_date_r
                                    FROM
                                        batch_date
                                    WHERE
                                        date_rank = 1
                                ) aa ON 1 = 1
                                INNER JOIN (
                                    SELECT
                                        d_calendar_date_r
                                    FROM
                                        batch_date
                                    WHERE
                                        date_rank = 2
                                ) bb ON 1 = 1
                            WHERE
                                    d_cycle_date_r = (
                                        SELECT
                                            batch_date.d_calendar_date_r
                                        FROM
                                            batch_date
                                        WHERE
                                            date_rank = 2
                                    )
                                AND ( n_due_prem_amt_r_all <> 0
                                      OR n_due_prem_unearned_amt_all <> 0
                                      OR n_prem_unearned_amt_all <> 0 )
                            GROUP BY
                                v_source_system_name_r,	
                                v_policy_number_r,
                                aa.d_calendar_date_r,
                                bb.d_calendar_date_r,
                                v_coverage_code_r,
                                d_due_date_r,
                                v_customer_bill_group_number_r,
                                v_short_name_r,
                                n_policy_sk_r
                        ), final_due_table AS (
                            SELECT DISTINCT
                                coalesce(cb.v_source_system_name_r, eu.v_source_system_name_r)                 AS v_source_system_name_r,	
                                coalesce(cb.d_cycle_date_r, eu.d_cycle_date_r)                                 AS d_cycle_date_r,
                                nvl(cb.prior_n_batch_id_r, eu.prior_cycle_date)                                AS d_prior_cycle_date_r,
                                coalesce(cb.v_policy_number_r, eu.v_policy_number_r)                           AS v_policy_number_r,
                                coalesce(cb.v_customer_bill_group_number_r, eu.v_customer_bill_group_number_r) AS v_customer_bill_group_number_r,
                                coalesce(cb.v_coveragecode_r, eu.v_coverage_code_r)                            AS v_coverage_code_r,
                                coalesce(cb.d_due_date_r, eu.d_due_date_r)                                     AS d_due_date_r,
                                coalesce(cb.v_short_name_r, eu.v_short_name_r)                                 AS v_short_name_r,
                                coalesce(cb.n_policy_sk_r, eu.n_policy_sk_r)                                   AS n_policy_sk_r,
                                nvl(cb.due_premium, 0)                                                         AS n_due_prem_amt_r,
                                nvl(cb.unearned_premium, 0)                                                    AS n_due_prem_unearned_amt,
                                nvl(eu.n_due_prem_amt_r, 0)                                                    AS prior_n_due_prem_amt_r,
                                nvl(eu.n_due_prem_amt_r_all, 0)                                                AS prior_n_due_prem_amt_r_all,
                                nvl(eu.n_due_prem_unearned_amt, 0)                                             AS prior_n_due_prem_unearned_amt,
                                nvl(eu.n_due_prem_unearned_amt_all, 0)                                         AS prior_n_due_prem_unearned_amt_all,
                                nvl((
                                    CASE
                                        WHEN cb.d_due_date_r >= due_date_filter.due_date_filter THEN
                                            nvl(cb.due_premium, 0)
                                        ELSE
                                            0
                                    END
                                ), 0) - nvl(eu.n_due_prem_amt_r, 0)                                            AS n_mtd_chg_due_premium_amt_r,
                                nvl(cb.due_premium, 0) - nvl(eu.n_due_prem_amt_r_all, 0)                       AS n_mtd_chg_due_premium_amt_r_all,
                                nvl((
                                    CASE
                                        WHEN cb.d_due_date_r >= due_date_filter.due_date_filter THEN
                                            nvl(cb.unearned_premium, 0)
                                        ELSE
                                            0
                                    END
                                ), 0) - nvl(eu.n_due_prem_unearned_amt, 0)                                     AS n_mtd_chg_due_premium_unearned_amt_r,
                                nvl(cb.unearned_premium, 0) - nvl(eu.n_due_prem_unearned_amt_all, 0)           AS n_mtd_chg_due_premium_unearned_amt_r_all,
                                nvl(n_prem_unearned_amt, 0)                                                    AS n_prior_prem_unearned_amt_r,
                                nvl(n_prem_unearned_amt_all, 0)                                                AS n_prior_prem_unearned_amt_r_all
                            FROM
                                due_premium_table_final cb
                                FULL JOIN prior_base_due eu    ON eu.prior_cycle_date = cb.prior_n_batch_id_r
                                                               AND eu.v_policy_number_r = cb.v_policy_number_r
                                                               AND cb.v_customer_bill_group_number_r = eu.v_customer_bill_group_number_r
                                                               AND eu.v_coverage_code_r = cb.v_coveragecode_r
                                                               AND eu.d_due_date_r = cb.d_due_date_r
                                LEFT JOIN due_date_filter   ON cb.d_cycle_date_r = due_date_filter.cycle_date
                        ), constant_earned_prem_amt_table AS (
                            SELECT
                                MIN(d_cycle_date_r)                                                                  AS starting_cycle_date,
                                MAX(d_cycle_date_r)                                                                  AS ending_cycle_date,
                                fct_rpt_rate_history_r.v_policy_prefix_r || fct_rpt_rate_history_r.v_policy_suffix_r AS v_policy_number_r,
                                v_coverage_code_r,
                                SUM(n_current_premium_r * n_current_analysis_rate_r) / SUM(n_current_premium_r)      AS last_apc_premium_weight
                            FROM
                                atomic.fct_rpt_rate_history_r
                            WHERE
                                    v_curr_rate_staging_excl_r >= '9000'
                                AND v_rate_key_chg_effect_type_r = 'Rate Change'
                            GROUP BY
                                fct_rpt_rate_history_r.v_policy_prefix_r || fct_rpt_rate_history_r.v_policy_suffix_r,
                                v_coverage_code_r
                        ),;