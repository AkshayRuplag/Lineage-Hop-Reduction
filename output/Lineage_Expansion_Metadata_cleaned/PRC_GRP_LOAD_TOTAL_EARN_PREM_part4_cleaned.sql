-- Cleaned for lineage: PRC_GRP_LOAD_TOTAL_EARN_PREM (part 4/6)

INSERT  INTO fct_rpt_earn_prior_due_prem_temp
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
                                pd.n_policy_id_r,
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
                                INNER JOIN atomic.stg_fct_grp_billing_policy_dtl_r_incr_prior pd ON bp.n_policy_sk_r = pd.n_policy_sk_r
                                LEFT JOIN atomic.dim_grp_policy_dir_r p                          ON p.n_policy_sk_r = bp.n_policy_sk_r
                                                                                                 AND p.v_active_status_r = 'Y'
                                LEFT OUTER JOIN (
                                    SELECT
                                        n_carrier_id_r,
                                        v_short_name_r
                                    FROM
                                        atomic.dim_grp_carrier_r
                                    WHERE
                                        v_source_system_name_r = 'VUE'
                                )                                                  dim_grp_carrier_r ON pd.n_carrier_id_r = dim_grp_carrier_r.
                                n_carrier_id_r 
                            WHERE
                                bp.v_active_status_r = 'Y'
                        ), max_due_date AS (
                            SELECT
                                MAX(d_due_date_r) d_due_date_r,
                                n_policy_billgroup_id_r,
                                n_policy_sk_r,
                                v_coveragecode_r,
                                n_src_coverage_id_r
                            FROM
                                (
                                    SELECT
                                        d_due_date_r,
                                        SUM(n_amount_paid_r) amountpaid,
                                        v_policy_number_r,
                                        n_policy_billgroup_id_r,
                                        p1.n_policy_sk_r,
                                        v_coveragecode_r,
                                        n_src_coverage_id_r
                                    FROM
                                             fct_billing_policy_premium_r_table p1
                                        INNER JOIN atomic.dim_source_system_r        b 
                                         ON p1.v_source_system_name_r = b.v_source_system_code_r
                                        INNER JOIN dim_grp_billing_pol_billgrp_r_due pb ON p1.n_policy_sk_r = pb.n_policy_sk_r
                                                                                        AND p1.n_src_policy_billgroup_id_r = pb.n_policy_billgroup_id_r
                                    WHERE
                                        ( nvl(upper(v_user_name_r), 'NA') <> 'SUSPENSE ADJUSTMENT' )  
                                        AND d_transaction_date_r < ld_fic_mis_date 
                                        AND ( ( b.v_tpa_indicator_r = 0
                                                AND n_premium_type_r IN ( 313, 344 ) )
                                              OR ( b.v_tpa_indicator_r = 1 
                                               ) ) 
                                    GROUP BY
                                        v_policy_number_r,
                                        n_policy_billgroup_id_r,
                                        p1.n_policy_sk_r,
                                        n_customer_billgroup_id_r,
                                        d_due_date_r,
                                        v_coveragecode_r,
                                        n_src_coverage_id_r
                                    HAVING
                                        SUM(n_amount_paid_r) > 0
                                )
                            GROUP BY
                                n_policy_billgroup_id_r,
                                n_policy_sk_r,
                                v_coveragecode_r,
                                n_src_coverage_id_r
                        ), due_premium_base AS (
                            SELECT DISTINCT
                                p1.v_source_system_name_r AS v_source_system_name_r	
                                ,
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
                                md.d_due_date_r           last_due_date_r,
                                pb.premium_mode
                                ,
                                p1.v_billgroupnumber_r    AS v_customer_bill_group_number_r,
                                pb.v_policy_prefix_r,
                                pb.v_policy_suffix_r,
                                (
                                    SELECT
                                        nvl(round(SUM(pt1.n_amount_paid_r), 2), 0)
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
                                        AND pt2.n_amount_paid_r = 0
                                        AND pt2.n_amount_due_r <> 0
                                        AND trunc(pt2.d_sr_statement_date_r, 'MM') < trunc(to_date(pbd.cycle_date, 'dd-mon-yy'), 'MM') 
                                )                         AS amountdue 
                                ,
                                nvl(pbd.monthspaid, 0)    AS monthspaid
                                ,
                                p1.n_policy_sk_r,
                                pbd.n_policy_billgroup_id_r,
                                pb.n_carrier_id_r
                                ,
                                p1.v_source_system_name_r AS v_source_system_r 
                            FROM
                                     fct_rpt_earn_due_prem_temp2 pbd
                                INNER JOIN fct_billing_policy_premium_r_table p1 ON p1.n_policy_sk_r = pbd.n_policy_sk_r
                                                                                    AND p1.n_src_policy_billgroup_id_r = pbd.n_policy_billgroup_id_r
                                INNER JOIN max_due_date                       md ON md.n_policy_billgroup_id_r = pbd.n_policy_billgroup_id_r
                                                              AND md.n_policy_sk_r = pbd.n_policy_sk_r
                                                              AND ( md.v_coveragecode_r = p1.v_coveragecode_r )
                                INNER JOIN dim_grp_product_r                  pc ON p1.v_coveragecode_r = pc.v_coverage_code_r
                                INNER JOIN dim_grp_billing_pol_billgrp_r_due  pb ON p1.n_policy_sk_r = pb.n_policy_sk_r
                                                                                   AND p1.n_src_policy_billgroup_id_r = pb.n_policy_billgroup_id_r
                        ), due_premium_table AS (
                            SELECT
                                c.*,
                                floor(months_between(to_date(add_months(trunc((
                                    SELECT
                                        batch_date.d_calendar_date_r
                                    FROM
                                        batch_date
                                    WHERE
                                        date_rank = 1
                                )), 1)), to_date(to_char(d_due_date_r, 'MM/YYYY'), 'MM/YYYY')))                                                              parameter_1,
                                trunc(((round(amountpaid, 2) / monthspaid) * floor(months_between(to_date(add_months(trunc((
                                    SELECT
                                        batch_date.d_calendar_date_r
                                    FROM
                                        batch_date
                                    WHERE
                                        date_rank = 1
                                )), 1)), to_date(to_char(d_due_date_r, 'MM/YYYY'), 'MM/YYYY')))), 4)                                                         parameter_2,
                                ( trunc(d_due_date_r) - to_date(to_char(last_due_date_r, 'mmyy'), 'MMYY') )                                                  parameter_3,
                                trunc(((round(amountpaid, 2) / monthspaid) / 30) *(trunc(d_due_date_r) - to_date(to_char(d_due_date_r,
                                'mmyy'), 'MMYY')), 2) parameter_4,	   
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
                                )                                                                                                                            AS
                                due_premium, 
                                CASE
                                    WHEN add_months(d_due_date_r, monthspaid) < d_cycle_date_r THEN
                                        round(amountpaid, 2)
                                    WHEN d_due_date_r > d_cycle_date_r                         THEN
                                        0
                                    ELSE
                                        CASE
                                                WHEN to_char(d_due_date_r, 'DD') = '01' THEN
                                                    trunc(((round(amountpaid, 2) / monthspaid) * round(months_between(last_day(trunc(
                                                    d_cycle_date_r - 10)) + 1, d_due_date_r))), 2)
                                                WHEN to_char(d_due_date_r, 'DD') >= 28  THEN 
                                                    trunc(((round(amountpaid, 2) / monthspaid) * round(months_between(last_day(trunc(
                                                    d_cycle_date_r - 10)) + 1, d_due_date_r))), 2)
                                                ELSE
                                                    trunc(((round(amountpaid, 2) / monthspaid) * floor(months_between(last_day(trunc(
                                                    d_cycle_date_r - 10)) + 1, to_date(to_char(d_due_date_r, 'MM/YYYY'), 'MM/YYYY')))),
                                                    4) - trunc(((round(amountpaid, 2) / monthspaid) / 30) *(trunc(d_due_date_r) - to_date(
                                                    to_char(d_due_date_r, 'mmyy'), 'MMYY')), 2)
                                        END
                                END                                                                                                                          AS
                                earnedpremium
                            FROM
                                     due_premium_base c
                                INNER JOIN atomic.dim_source_system_r d ON c.v_source_system_r = d.v_source_system_code_r
                        ), due_premium_table_final AS (
                            SELECT 
                             DISTINCT
                                d.d_cycle_date_r,
                                d.prior_n_batch_id_r,
                                d.v_policy_number_r,
                                d.d_due_date_r,
                                d.v_coveragecode_r,
                                d.v_short_name_r,
                                d.last_due_date_r,
                                d.premium_mode,
                                d.v_customer_bill_group_number_r,
                                d.v_policy_prefix_r,
                                d.v_policy_suffix_r,
                                d.amountpaid,
                                d.monthspaid,
                                d.n_policy_sk_r,
                                d.n_policy_billgroup_id_r,
                                d.n_carrier_id_r,
                                d.due_premium,
                                d.earnedpremium,
                                CASE
                                    WHEN ss.v_tpa_indicator_r = 1 THEN
                                        0
                                    ELSE
                                        due_premium - earnedpremium
                                END AS unearned_premium, 
                                d.v_source_system_name_r  
                            FROM
                                     due_premium_table d
                                INNER JOIN dim_source_system_r ss ON d.v_source_system_name_r = ss.v_source_system_code_r
                        )
                        SELECT
                            *
                        FROM
                            due_premium_table_final
                    );