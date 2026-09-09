-- Cleaned for lineage: PRC_GRP_LOAD_TOTAL_EARN_PREM (part 3/6)

INSERT INTO fct_rpt_earn_due_prem_temp2 (
                            v_source_system_name_r,
                            cycle_date,
                            n_policy_sk_r,
                            n_customer_billgroup_id_r,
                            n_policy_billgroup_id_r,
                            duedate,
                            monthspaid,
                            lastpaiddue,
                            v_tpa_indicator_r
                        ) 
                            SELECT
                                i.v_source_system_name_r,
                                i.cycle_date,
                                i.n_policy_sk_r,
                                i.n_customer_billgroup_id_r,
                                i.n_policy_billgroup_id_r,
                                v_due_date,
                                i.monthspaid,
                                add_months(i.premiumdue, i.monthspaid * - 1),
                                i.v_tpa_indicator_r 
                            FROM
                                dual
                            WHERE
                                    v_due_date <= last_day(trunc(i.cycle_date) - 10)
                                AND ( i.bgtermdate IS NULL
                                      OR v_due_date < i.bgtermdate )
                                AND ( ( i.poltermdate IS NULL
                                        OR v_due_date < i.poltermdate ) );

INSERT INTO fct_rpt_earn_due_prem_temp2 (
                        v_source_system_name_r,
                        cycle_date,
                        n_policy_sk_r,
                        n_customer_billgroup_id_r,
                        n_policy_billgroup_id_r,
                        duedate,
                        monthspaid,
                        lastpaiddue,
                        v_tpa_indicator_r
                    )
                        SELECT
                            i.v_source_system_name_r,
                            i.cycle_date,
                            i.n_policy_sk_r,
                            i.n_customer_billgroup_id_r,
                            i.n_policy_billgroup_id_r,
                            i.premiumdue AS v_due_date,
                            i.monthspaid,
                            add_months(i.premiumdue, i.monthspaid * - 1),
                            i.v_tpa_indicator_r
                        FROM
                            dual;

Insert into tbl FCT_RPT_EARN_PRIOR_DUE_PREM_TEMP';