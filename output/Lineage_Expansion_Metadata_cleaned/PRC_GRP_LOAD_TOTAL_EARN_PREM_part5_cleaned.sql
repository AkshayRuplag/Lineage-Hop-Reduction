-- Cleaned for lineage: PRC_GRP_LOAD_TOTAL_EARN_PREM (part 5/6)

Insert into table FCT_RPT_EARN_FINAL_DUE_PREM_TEMP';

INSERT  INTO fct_rpt_earn_final_due_prem_temp
                SELECT
                    *
                FROM
                    fct_rpt_earn_prior_due_prem_temp cb
                WHERE
                    (
                        CASE
                            WHEN cb.v_policy_prefix_r <> 'SR'
                                 AND NOT EXISTS (
                                SELECT
                                    *
                                FROM
                                    fct_rpt_earn_prior_due_prem_temp b
                                WHERE
                                        b.d_cycle_date_r = cb.d_cycle_date_r
                                    AND b.due_premium <> 0
                                    AND b.n_policy_billgroup_id_r = cb.n_policy_billgroup_id_r
                                    AND b.d_due_date_r >= add_months(last_day(trunc(b.d_cycle_date_r - 10)), premium_mode * - 12)
                            ) THEN
                                cb.d_due_date_r
                            ELSE
                                cb.d_cycle_date_r
                        END
                    ) > add_months(last_day(trunc(cb.d_cycle_date_r - 10)), premium_mode * - 12);

DELETE FROM fct_rpt_earn_final_due_prem_temp a
            WHERE
                    d_cycle_date_r = (
                        SELECT
                            d_calendar_date_r
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
                            date_rank = 1
                    )
                AND EXISTS (
                    SELECT
                        *
                    FROM
                        fct_rpt_earn_final_due_prem_temp b
                    WHERE
                            d_cycle_date_r = (
                                SELECT
                                    d_calendar_date_r
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
                                    date_rank = 1
                            )
                        AND a.n_policy_sk_r = b.n_policy_sk_r
                        AND a.n_policy_billgroup_id_r = b.n_policy_billgroup_id_r
                        AND a.v_coveragecode_r <> b.v_coveragecode_r
                        AND a.last_due_date_r < b.last_due_date_r
                        AND a.last_due_date_r < add_months(d_cycle_date_r, - 12)
                );

DELETE FROM fct_rpt_earn_final_due_prem_temp a
            WHERE
                    v_coveragecode_r = 2410
                AND EXISTS (
                    SELECT
                        *
                    FROM
                        fct_rpt_earn_final_due_prem_temp b
                    WHERE
                            v_coveragecode_r = 2400
                        AND a.d_cycle_date_r = b.d_cycle_date_r
                        AND a.n_policy_sk_r = b.n_policy_sk_r
                        AND a.last_due_date_r < b.last_due_date_r
                        AND a.n_policy_billgroup_id_r = b.n_policy_billgroup_id_r
                        AND a.due_premium <> b.due_premium
                );

DELETE FROM fct_rpt_earn_final_due_prem_temp a
            WHERE
                    v_coveragecode_r = 2400
                AND EXISTS (
                    SELECT
                        *
                    FROM
                        fct_rpt_earn_final_due_prem_temp b
                    WHERE
                            v_coveragecode_r = 2410
                        AND a.d_cycle_date_r = b.d_cycle_date_r
                        AND a.n_policy_sk_r = b.n_policy_sk_r
                        AND a.last_due_date_r < b.last_due_date_r
                        AND a.n_policy_billgroup_id_r = b.n_policy_billgroup_id_r
                        AND a.due_premium <> b.due_premium
                );

DELETE FROM fct_rpt_earn_final_due_prem_temp a
            WHERE
                    d_cycle_date_r = (
                        SELECT
                            d_calendar_date_r
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
                            date_rank = 1
                    )
                AND a.v_policy_number_r IN ( 'GL008003', 'GL014442', 'GL018310', 'GL018362', 'GL033052',
                                             'GL096018', 'GL096021', 'GL096026', 'GL096052', 'GL096092',
                                             'GL096900', 'GL096902', 'GL128761', 'GL130144', 'GL130561',
                                             'GL132894', 'GL142738', 'GL144888', 'GL350001', 'GL350002',
                                             'GL350004' );

Insert into tbl FCT_RPT_EARN_PREMIUM_SUMMARY_R_INCR';