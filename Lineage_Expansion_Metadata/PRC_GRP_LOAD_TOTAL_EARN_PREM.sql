--------------------------------------------------------
--  DDL for Procedure PRC_GRP_LOAD_TOTAL_EARN_PREM
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "ATOMIC"."PRC_GRP_LOAD_TOTAL_EARN_PREM" --(P_N_BATCH_ID_R IN NUMBER)
 AS

/*1.	Should follow same schedule as Ann_Prem (fiscal month end, and weekly on SATURDAYs)
Prerequisite Loads:
------------------
 DIM_GRP_PRODUCT_R
 FCT_GRP_POLICY_R
 DIM_GRP_BILLING_POL_BILLGRP_R
 DIM_GRP_CARRIER_R
 STG_FCT_GRP_BILLING_POLICY_DTL_R_INCR      -- 30th AUgust vuew batchid
 STG_FCT_GRP_BILLING_POLICY_DTL_R_INCR_PRIOR-- It should have July 27th Data --
 DIM_GRP_POLICY_DIR_R
 DIM_TIME_R
 FCT_BILLING_POLICY_PREMIUM_R_TABLE
 FCT_RPT_RATE_HISTORY_R
 FCT_RPT_PREMIUM_SUMMARY_R

 --Below tables will be loading as part of this procedure
 FCT_RPT_EARN_PREMIUM_SUMMARY_PRIOR_R_BKP--Create table dynamically
 FCT_RPT_EARN_PREMIUM_SUMMARY_PRIOR_R--Truncate and Insert
 FCT_RPT_EARN_DUE_PREM_TEMP1       --Truncate and Insert
 FCT_RPT_EARN_DUE_PREM_TEMP2       --Truncate and Insert
 FCT_RPT_EARN_PRIOR_DUE_PREM_TEMP  --Truncate and Insert
 FCT_RPT_EARN_FINAL_DUE_PREM_TEMP  --Truncate and Insert
 FCT_RPT_EARN_PREMIUM_SUMMARY_R_INCR--Truncate and Insert
 FCT_RPT_EARN_PREMIUM_SUMMARY_R--Delete and Insert
 FCT_RPT_PREMIUM_SUMMARY_R--Delete and Insert

 exec dbms_stats.gather_table_stats('ATOMIC','DIM_GRP_PRODUCT_R');
 exec dbms_stats.gather_table_stats('ATOMIC','FCT_GRP_POLICY_R');
 exec dbms_stats.gather_table_stats('ATOMIC','DIM_GRP_BILLING_POL_BILLGRP_R');
 exec dbms_stats.gather_table_stats('ATOMIC','STG_FCT_GRP_BILLING_POLICY_DTL_R_INCR');
 exec dbms_stats.gather_table_stats('ATOMIC','DIM_GRP_CARRIER_R');
 exec dbms_stats.gather_table_stats('ATOMIC','STG_FCT_GRP_BILLING_POLICY_DTL_R_INCR_PRIOR');
 exec dbms_stats.gather_table_stats('ATOMIC','DIM_GRP_POLICY_DIR_R');
 exec dbms_stats.gather_table_stats('ATOMIC','DIM_TIME_R');
 exec dbms_stats.gather_table_stats('ATOMIC','FCT_BILLING_POLICY_PREMIUM_R_TABLE');
 exec dbms_stats.gather_table_stats('ATOMIC','FCT_RPT_RATE_HISTORY_R');
 exec dbms_stats.gather_table_stats('ATOMIC','FCT_RPT_PREMIUM_SUMMARY_R');
 exec dbms_stats.gather_table_stats('ATOMIC','FCT_RPT_EARN_PREMIUM_SUMMARY_PRIOR_R');
 exec dbms_stats.gather_table_stats('ATOMIC','FCT_RPT_EARN_DUE_PREM_TEMP1');
 exec dbms_stats.gather_table_stats('ATOMIC','FCT_RPT_EARN_DUE_PREM_TEMP2');
 exec dbms_stats.gather_table_stats('ATOMIC','FCT_RPT_EARN_PRIOR_DUE_PREM_TEMP');
 exec dbms_stats.gather_table_stats('ATOMIC','FCT_RPT_EARN_FINAL_DUE_PREM_TEMP');
 exec dbms_stats.gather_table_stats('ATOMIC','FCT_RPT_EARN_PREMIUM_SUMMARY_R_INCR');
 exec dbms_stats.gather_table_stats('ATOMIC','FCT_RPT_EARN_PREMIUM_SUMMARY_R');

August      	    FCT_RPT_EARN_PREMIUM_SUMMARY_PRIOR_R	July Data
First Sat-Sep	    FCT_RPT_EARN_PREMIUM_SUMMARY_PRIOR_R	Truncate and insert data from FCT_RPT_EARN_PREMIUM_SUMMARY_R_INCR which contains August data
Second Sat-Sep	    FCT_RPT_EARN_PREMIUM_SUMMARY_PRIOR_R	No Change - still it should have aguts data
Third Sat	        FCT_RPT_EARN_PREMIUM_SUMMARY_PRIOR_R	No Change - still it should have aguts data
Fourth Sat	        FCT_RPT_EARN_PREMIUM_SUMMARY_PRIOR_R	No Change - still it should have aguts data
Fiscal Month End	FCT_RPT_EARN_PREMIUM_SUMMARY_PRIOR_R	No Change - still it should have aguts data
First Sat-Oct	    FCT_RPT_EARN_PREMIUM_SUMMARY_PRIOR_R	Sep Data

create table FCT_RPT_EARN_PREMIUM_SUMMARY_PRIOR_R select * from FCT_RPT_EARN_PREMIUM_SUMMARY_R where d_cycle_date_r=27-Jul-2023(jul cycle date)

*/
    n_counter                      NUMBER;
    v_due_date                     DATE;
    validation_var                 NUMBER;
--LN_N_BATCH_ID_R NUMBER :=P_N_BATCH_ID_R;
    ln_n_batch_id_r                NUMBER;
    lc_step                        VARCHAR2(4000) := 'Step->';
    lc_sqlcode                     VARCHAR2(4000);
    lc_sqlerrm                     VARCHAR2(4000);
    ld_sysdate                     DATE := sysdate;
    ln_prir_tbl                    NUMBER := 0;
    ln_time                        PLS_INTEGER;
    ln_start_time                  PLS_INTEGER;
    ln_max_seq_num1_r              NUMBER := 0;
    ld_fic_mis_date                dim_time_r.d_calendar_date_r%TYPE;
    lc_day                         VARCHAR2(30);
--11-Sep-2023 changes starts
    ld_first_saturday              DATE;
    custom_exception EXCEPTION;
    PRAGMA exception_init ( custom_exception, -20001 );
    lc_trun_tot_earn_prem_priortbl VARCHAR2(3) := 'N';
    ln_prior_rec_cnt               NUMBER := 0;
    gv_running_status              CONSTANT VARCHAR2(10) := 'Running';
    gv_error_status                CONSTANT VARCHAR2(10) := 'Error';
    gv_success_status              CONSTANT VARCHAR2(10) := 'Success';
    gv_source                      CONSTANT VARCHAR2(10) := 'Info';
    gv_job_name                    CONSTANT VARCHAR2(200 CHAR) := 'PRC_GRP_LOAD_TOTAL_EARN_PREM';
    gv_main_loadedby               CONSTANT VARCHAR2(100 CHAR) := 'EDW';
    gv_message_type_r              CONSTANT VARCHAR2(100 CHAR) := 'Premium calculations';
    gn_run_cnt                     NUMBER := 0;
    gd_sysdate                     DATE := trunc(sysdate);
    gn_sysdt_batchid               NUMBER := to_number(to_char(gd_sysdate, 'YYYYMMDD'));
    gn_out_job_id                  NUMBER;
    gn_job_log_message_id_r        NUMBER;
    gn_error_line                  VARCHAR2(20);
    gv_errmsg                      VARCHAR2(4000 CHAR);
    gv_trcmsg                      CLOB;
    gt_start_time                  TIMESTAMP;
    gt_end_time                    TIMESTAMP;
--11-Sep-2023 changes ends

BEGIN
    ln_start_time := dbms_utility.get_time;

/*	SELECT CASE WHEN ld_fic_mis>=TRUNC(SYSDATE) THEN ld_fic_mis
    ELSE (SELECT D_CALENDAR_DATE_R +1 AS ld_fic_mis
    FROM Atomic.DIM_TIME_R D
    WHERE  V_END_OF_FISCAL_MONTH_IND_R = 'Y'
    and to_char(d_calendar_date_r,'YYYYMM')=to_char(sysdate+14,'YYYYMM')) END INTO ld_fic_mis_date 
    FROM (SELECT D_CALENDAR_DATE_R +1 AS ld_fic_mis
    FROM Atomic.DIM_TIME_R D
    WHERE  V_END_OF_FISCAL_MONTH_IND_R = 'Y'
    and to_char(d_calendar_date_r,'YYYYMM')=to_char(sysdate,'YYYYMM') ) ; 

	SELECT TO_NUMBER((MAX(N_DATE_SK_R) + 1) || '0000')
    INTO LN_N_BATCH_ID_R
    FROM DIM_TIME_R
    WHERE TO_CHAR(D_CALENDAR_DATE_R) = TO_CHAR(ld_fic_mis_date);

*/ 

    -- New Logging Mechanism added which will contained detailed information about code execution	2026-05-21 Project Crown changes to add logging
    pkg_grp_log_util.prc_insert_log
			(
				p_source               => gv_source,
				p_job_nm               => gv_job_name,
				p_job_status           => gv_running_status,
				p_err_msg              => NULL,
				p_trc_msg              => NULL,
				p_n_batch_id           => gn_sysdt_batchid,
				p_log_util_called_by_r => gv_main_loadedby,
				out_job_id             => gn_out_job_id
			);

    gv_trcmsg := '1.Entered into Procedure PRC_GRP_LOAD_TOTAL_EARN_PREM.';
    pkg_grp_log_util.prc_ins_prcs_job_log_message_r
			(
				p_job_id_r                  => gn_out_job_id,
				p_batch_id_r                => gn_sysdt_batchid,
				p_message_type_r            => gv_message_type_r,
				p_code_location_r           => gv_main_loadedby,
				p_message_r                 => gv_trcmsg,
				p_count_type_r              => NULL,
				p_count_r                   => NULL,
				p_duration_r                => NULL,
				p_created_by_r              => gv_job_name,
				out_prcs_job_log_message_id_r => gn_job_log_message_id_r
			);

    SELECT
        d_calendar_date_r + 1,
        to_number((n_date_sk_r + 1)
                  || '0000')	--23-Jan-2023 changes
    INTO
        ld_fic_mis_date,
        ln_n_batch_id_r	--23-Jan-2023 changes
    FROM
        dim_time_r d
    WHERE
            v_end_of_fiscal_month_ind_r = 'Y'
        AND to_char(d_calendar_date_r, 'YYYYMM') = to_char(sysdate, 'YYYYMM');

    lc_step := lc_step
               || chr(13)
               || ' ld_fic_mis_date:->'
               || ld_fic_mis_date;
    SELECT
        to_char(sysdate, 'DAY')
    INTO lc_day
    FROM
        dual;

	--2026-05-21   Project Crown changes to add logging
    gv_trcmsg := '2. Fetched BatchID:->' || ln_n_batch_id_r;
    pkg_grp_log_util.prc_ins_prcs_job_log_message_r
			(
				p_job_id_r                    => gn_out_job_id,
				p_batch_id_r                  => gn_sysdt_batchid,
				p_message_type_r              => gv_message_type_r,
				p_code_location_r             => gv_main_loadedby,
				p_message_r                   => gv_trcmsg,
				p_count_type_r                => NULL,
				p_count_r                     => NULL,
				p_duration_r                  => NULL,
				p_created_by_r                => gv_job_name,
				out_prcs_job_log_message_id_r => gn_job_log_message_id_r
			);

    gv_trcmsg := '3.Check today is first SATURDAY of the month or not ';
    pkg_grp_log_util.prc_ins_prcs_job_log_message_r
			(
				p_job_id_r                    => gn_out_job_id,
				p_batch_id_r                  => gn_sysdt_batchid,
				p_message_type_r              => gv_message_type_r,
				p_code_location_r             => gv_main_loadedby,
				p_message_r                   => gv_trcmsg,
				p_count_type_r                => NULL,
				p_count_r                     => NULL,
				p_duration_r                  => NULL,
				p_created_by_r                => gv_job_name,
				out_prcs_job_log_message_id_r => gn_job_log_message_id_r
			);

    -- 2026-05-21 Project Crown changes to add logging	

    IF  ln_n_batch_id_r IS NOT NULL
        AND length(ln_n_batch_id_r) = 12
        AND lc_day IS NOT NULL
        AND ( to_date(ld_fic_mis_date) = to_date(ld_sysdate) --to load data on next day of Fiscal Month (Ex:the fiscal month end for May 2023 is 26-MAY-23 so we should load this on 27-MAY-23)
         OR trim(lc_day) = 'SATURDAY'-- or to load data on SATURDAY
         )
    THEN
       --11-Sep-2023 changes starts

        SELECT
            trunc(next_day(trunc(sysdate, 'MM') - 1, 'SATURDAY'))
        INTO ld_first_saturday
        FROM
            dual;

        IF ld_first_saturday = trunc(ld_sysdate) THEN
            lc_trun_tot_earn_prem_priortbl := 'Y';

			-- 21-05-2026 Project Crown changes to add logging

            gv_trcmsg := '3.1 Today is first SATURDAY of the month,So truncate the FCT_RPT_EARN_PREMIUM_SUMMARY_PRIOR_R table and insert data from FCT_RPT_EARN_PREMIUM_SUMMARY_R_INCR which contains priormonth data';
            pkg_grp_log_util.prc_ins_prcs_job_log_message_r
					(
						p_job_id_r                    => gn_out_job_id,
						p_batch_id_r                  => gn_sysdt_batchid,
						p_message_type_r              => gv_message_type_r,
						p_code_location_r             => gv_main_loadedby,
						p_message_r                   => gv_trcmsg,
						p_count_type_r                => NULL,
						p_count_r                     => NULL,
						p_duration_r                  => NULL,
						p_created_by_r                => gv_job_name,
						out_prcs_job_log_message_id_r => gn_job_log_message_id_r
					);

        ELSE
            lc_trun_tot_earn_prem_priortbl := 'N';

			-- 21-05-2026 Project Crown changes to add logging

            gv_trcmsg := '3.2 Today is NOT first SATURDAY of the month,hence not truncating the table FCT_RPT_EARN_PREMIUM_SUMMARY_PRIOR_R';
            pkg_grp_log_util.prc_ins_prcs_job_log_message_r
					(
							p_job_id_r                    => gn_out_job_id,
							p_batch_id_r                  => gn_sysdt_batchid,
							p_message_type_r              => gv_message_type_r,
							p_code_location_r             => gv_main_loadedby,
							p_message_r                   => gv_trcmsg,
							p_count_type_r                => NULL,
							p_count_r                     => NULL,
							p_duration_r                  => NULL,
							p_created_by_r                => gv_job_name,
							out_prcs_job_log_message_id_r => gn_job_log_message_id_r
					);

        END IF;

        IF lc_trun_tot_earn_prem_priortbl = 'Y' THEN

	   --11-Sep-2023 changes ends

            -- 21-05-2026 Project Crown changes to add logging

            gv_trcmsg := '4.Check today tbl FCT_RPT_EARN_PREMIUM_SUMMARY_PRIOR_R created or not,incase of rerunning the job it should not drop the bkp table which is created in the first run';
            pkg_grp_log_util.prc_ins_prcs_job_log_message_r
					(
						p_job_id_r                    => gn_out_job_id,
						p_batch_id_r                  => gn_sysdt_batchid,
						p_message_type_r              => gv_message_type_r,
						p_code_location_r             => gv_main_loadedby,
						p_message_r                   => gv_trcmsg,
						p_count_type_r                => NULL,
						p_count_r                     => NULL,
						p_duration_r                  => NULL,
						p_created_by_r                => gv_job_name,
						out_prcs_job_log_message_id_r => gn_job_log_message_id_r
					);

            SELECT
                COUNT(1)
            INTO ln_prir_tbl
            FROM
                all_objects
            WHERE
                    object_name = 'FCT_RPT_EARN_PREMIUM_SUMMARY_PRIOR_R_BKP'
                AND object_type = 'TABLE'
                AND owner = 'ATOMIC'
                AND trunc(created) = trunc(ld_sysdate)--TRUNC(sysdate)
                ;

			-- 21-05-2026 Project Crown changes to add logging

            gv_trcmsg := '5.tbl FCT_RPT_EARN_PREMIUM_SUMMARY_PRIOR_R_BKP LN_PRIR_TBL';
            pkg_grp_log_util.prc_ins_prcs_job_log_message_r
					(
						p_job_id_r                    => gn_out_job_id,
						p_batch_id_r                  => gn_sysdt_batchid,
						p_message_type_r              => gv_message_type_r,
						p_code_location_r             => gv_main_loadedby,
						p_message_r                   => gv_trcmsg,
						p_count_type_r                => NULL,
						p_count_r                     => NULL,
						p_duration_r                  => NULL,
						p_created_by_r                => gv_job_name,
						out_prcs_job_log_message_id_r => gn_job_log_message_id_r
					);

            IF ln_prir_tbl = 0 THEN
                gt_start_time := systimestamp;
                gv_trcmsg := '5.1.Drop tbl FCT_RPT_EARN_PREMIUM_SUMMARY_PRIOR_R_BKP';
                pkg_grp_log_util.prc_ins_prcs_job_log_message_r
					(
							p_job_id_r                    => gn_out_job_id,
							p_batch_id_r                  => gn_sysdt_batchid,
							p_message_type_r              => gv_message_type_r,
							p_code_location_r             => gv_main_loadedby,
							p_message_r                   => gv_trcmsg,
							p_count_type_r                => NULL,
							p_count_r                     => NULL,
							p_duration_r                  => NULL,
							p_created_by_r                => gv_job_name,
							out_prcs_job_log_message_id_r => gn_job_log_message_id_r
					);

                BEGIN
                    EXECUTE IMMEDIATE 'drop table FCT_RPT_EARN_PREMIUM_SUMMARY_PRIOR_R_BKP';
                EXCEPTION
                    WHEN OTHERS THEN
                        NULL;
                END;

				-- 21-05-2026 Project Crown changes to add logging

                gt_end_time := systimestamp;
                gv_trcmsg := '5.2.Drop tbl FCT_RPT_EARN_PREMIUM_SUMMARY_PRIOR_R_BKP';
                pkg_grp_log_util.prc_ins_prcs_job_log_message_r
					(
						p_job_id_r                    => gn_out_job_id,
						p_batch_id_r                  => gn_sysdt_batchid,
						p_message_type_r              => gv_message_type_r,
						p_code_location_r             => gv_main_loadedby,
						p_message_r                   => gv_trcmsg,
						p_count_type_r                => 'Insert',
						p_count_r                     => gn_run_cnt,
						p_duration_r                  => fnc_grp_time_duration(gt_start_time,gt_end_time),
						p_created_by_r                => gv_job_name,
						out_prcs_job_log_message_id_r => gn_job_log_message_id_r
					);

                gt_start_time := systimestamp;
                gv_trcmsg := '5.3.Create tbl FCT_RPT_EARN_PREMIUM_SUMMARY_PRIOR_R_BKP';
                pkg_grp_log_util.prc_ins_prcs_job_log_message_r
					(
						p_job_id_r                    => gn_out_job_id,
						p_batch_id_r                  => gn_sysdt_batchid,
						p_message_type_r              => gv_message_type_r,
						p_code_location_r             => gv_main_loadedby,
						p_message_r                   => gv_trcmsg,
						p_count_type_r                => NULL,
						p_count_r                     => NULL,
						p_duration_r                  => NULL,
						p_created_by_r                => gv_job_name,
						out_prcs_job_log_message_id_r => gn_job_log_message_id_r
					);

                EXECUTE IMMEDIATE 'create table FCT_RPT_EARN_PREMIUM_SUMMARY_PRIOR_R_BKP as select * from FCT_RPT_EARN_PREMIUM_SUMMARY_R_INCR';


				-- 21-05-2026 Project Crown changes to add logging

                gt_end_time := systimestamp;
                gv_trcmsg := '5.4. Created tbl FCT_RPT_EARN_PREMIUM_SUMMARY_PRIOR_R_BKP';
                pkg_grp_log_util.prc_ins_prcs_job_log_message_r
					(
						p_job_id_r                    => gn_out_job_id,
						p_batch_id_r                  => gn_sysdt_batchid,
						p_message_type_r              => gv_message_type_r,
						p_code_location_r             => gv_main_loadedby,
						p_message_r                   => gv_trcmsg,
						p_count_type_r                => 'Insert',
						p_count_r                     => gn_run_cnt,
						p_duration_r                  => fnc_grp_time_duration(gt_start_time,gt_end_time),
						p_created_by_r                => gv_job_name,
						out_prcs_job_log_message_id_r => gn_job_log_message_id_r
					);

            END IF;

            -- 21-05-2026 Project Crown changes to add logging

            gt_start_time := systimestamp;
            gv_trcmsg := '5.5.Truncate tbl FCT_RPT_EARN_PREMIUM_SUMMARY_PRIOR_R';
            pkg_grp_log_util.prc_ins_prcs_job_log_message_r
					(
						p_job_id_r                    => gn_out_job_id,
						p_batch_id_r                  => gn_sysdt_batchid,
						p_message_type_r              => gv_message_type_r,
						p_code_location_r             => gv_main_loadedby,
						p_message_r                   => gv_trcmsg,
						p_count_type_r                => NULL,
						p_count_r                     => NULL,
						p_duration_r                  => NULL,
						p_created_by_r                => gv_job_name,
						out_prcs_job_log_message_id_r => gn_job_log_message_id_r
					);

            EXECUTE IMMEDIATE 'Truncate table FCT_RPT_EARN_PREMIUM_SUMMARY_PRIOR_R';
            gt_end_time := systimestamp;
            gv_trcmsg := '5.6.Truncated tbl FCT_RPT_EARN_PREMIUM_SUMMARY_PRIOR_R';
            pkg_grp_log_util.prc_ins_prcs_job_log_message_r
					(
						p_job_id_r                    => gn_out_job_id,
						p_batch_id_r                  => gn_sysdt_batchid,
						p_message_type_r              => gv_message_type_r,
						p_code_location_r             => gv_main_loadedby,
						p_message_r                   => gv_trcmsg,
						p_count_type_r                => 'Insert',
						p_count_r                     => gn_run_cnt,
						p_duration_r                  => fnc_grp_time_duration(gt_start_time,gt_end_time ),
						p_created_by_r                => gv_job_name,
						out_prcs_job_log_message_id_r => gn_job_log_message_id_r
					);


			-- 21-05-2026 Project Crown changes to add logging											   

            gt_start_time := systimestamp;
            gv_trcmsg := '5.7.Insert into tbl FCT_RPT_EARN_PREMIUM_SUMMARY_PRIOR_R from FCT_RPT_EARN_PREMIUM_SUMMARY_PRIOR_R_BKP';
            pkg_grp_log_util.prc_ins_prcs_job_log_message_r
					(
						p_job_id_r                    => gn_out_job_id,
						p_batch_id_r                  => gn_sysdt_batchid,
						p_message_type_r              => gv_message_type_r,
						p_code_location_r             => gv_main_loadedby,
						p_message_r                   => gv_trcmsg,
						p_count_type_r                => NULL,
						p_count_r                     => NULL,
						p_duration_r                  => NULL,
						p_created_by_r                => gv_job_name,
						out_prcs_job_log_message_id_r => gn_job_log_message_id_r
					);

            EXECUTE IMMEDIATE 'INSERT /*+APPEND_VALUES*/ INTO FCT_RPT_EARN_PREMIUM_SUMMARY_PRIOR_R  select * from FCT_RPT_EARN_PREMIUM_SUMMARY_PRIOR_R_BKP';


			-- 21-05-2026 Project Crown changes to add logging

            gt_end_time := systimestamp;
            gv_trcmsg := '5.8.Inserted into tbl FCT_RPT_EARN_PREMIUM_SUMMARY_PRIOR_R from FCT_RPT_EARN_PREMIUM_SUMMARY_PRIOR_R_BKP';
            pkg_grp_log_util.prc_ins_prcs_job_log_message_r
					(
						p_job_id_r                    => gn_out_job_id,
						p_batch_id_r                  => gn_sysdt_batchid,
						p_message_type_r              => gv_message_type_r,
						p_code_location_r             => gv_main_loadedby,
						p_message_r                   => gv_trcmsg,
						p_count_type_r                => 'Insert',
						p_count_r                     => gn_run_cnt,
						p_duration_r                  => fnc_grp_time_duration(gt_start_time,gt_end_time),
						p_created_by_r                => gv_job_name,
						out_prcs_job_log_message_id_r => gn_job_log_message_id_r
					);  

	    --11-Sep-2023 changes starts
            COMMIT;
        END IF;--IF lc_trun_tot_earn_prem_priortbl = 'Y' THEN

        gv_trcmsg := '6.Chk prev month '
                     || to_char(trunc(sysdate, 'MONTH') - 1, 'YYYYMM')
                     || ' data is there in the tbl FCT_RPT_EARN_PREMIUM_SUMMARY_PRIOR_R or not ';

        pkg_grp_log_util.prc_ins_prcs_job_log_message_r
				(
					p_job_id_r                    => gn_out_job_id,
					p_batch_id_r                  => gn_sysdt_batchid,
					p_message_type_r              => gv_message_type_r,
					p_code_location_r             => gv_main_loadedby,
					p_message_r                   => gv_trcmsg,
					p_count_type_r                => NULL,
					p_count_r                     => NULL,
					p_duration_r                  => NULL,
					p_created_by_r                => gv_job_name,
					out_prcs_job_log_message_id_r => gn_job_log_message_id_r
				);

        SELECT
            COUNT(1)
        INTO ln_prior_rec_cnt
        FROM
            fct_rpt_earn_premium_summary_prior_r
        WHERE
            to_char(d_cycle_date_r, 'YYYYMM') = (
                SELECT
                    to_char(trunc(sysdate, 'MONTH') - 1, 'YYYYMM')
                FROM
                    dual
            );

        IF ln_prior_rec_cnt <> 0 THEN
            gv_trcmsg := '6.1 Chk prev month '
                         || to_char(trunc(sysdate, 'MONTH') - 1, 'YYYYMM')
                         || ' data is there in the tbl FCT_RPT_EARN_PREMIUM_SUMMARY_PRIOR_R '
                         || ln_prior_rec_cnt
                         || ' Records,hence proceeding with next steps';

           pkg_grp_log_util.prc_ins_prcs_job_log_message_r
				(
					p_job_id_r                    => gn_out_job_id,
					p_batch_id_r                  => gn_sysdt_batchid,
					p_message_type_r              => gv_message_type_r,
					p_code_location_r             => gv_main_loadedby,
					p_message_r                   => gv_trcmsg,
					p_count_type_r                => NULL,
					p_count_r                     => NULL,
					p_duration_r                  => NULL,
					p_created_by_r                => gv_job_name,
					out_prcs_job_log_message_id_r => gn_job_log_message_id_r
				);   			   


		--11-Sep-2023 changes ends

            EXECUTE IMMEDIATE 'truncate TABLE FCT_RPT_EARN_DUE_PREM_TEMP1 purge snapshot log';


			-- 21-05-2026 Project Crown changes to add logging

            gv_trcmsg := '6.3 Truncated tbl FCT_RPT_EARN_DUE_PREM_TEMP1';
            pkg_grp_log_util.prc_ins_prcs_job_log_message_r
				(
					p_job_id_r                    => gn_out_job_id,
					p_batch_id_r                  => gn_sysdt_batchid,
					p_message_type_r              => gv_message_type_r,
					p_code_location_r             => gv_main_loadedby,
					p_message_r                   => gv_trcmsg,
					p_count_type_r                => NULL,
					p_count_r                     => NULL,
					p_duration_r                  => NULL,
					p_created_by_r                => gv_job_name,
					out_prcs_job_log_message_id_r => gn_job_log_message_id_r
				);

            gv_trcmsg := '6.4 Truncate tbl FCT_RPT_EARN_DUE_PREM_TEMP2';
            pkg_grp_log_util.prc_ins_prcs_job_log_message_r
				(
					p_job_id_r                    => gn_out_job_id,
					p_batch_id_r                  => gn_sysdt_batchid,
					p_message_type_r              => gv_message_type_r,
					p_code_location_r             => gv_main_loadedby,
					p_message_r                   => gv_trcmsg,
					p_count_type_r                => NULL,
					p_count_r                     => NULL,
					p_duration_r                  => NULL,
					p_created_by_r                => gv_job_name,
					out_prcs_job_log_message_id_r => gn_job_log_message_id_r
				);

            EXECUTE IMMEDIATE 'truncate TABLE FCT_RPT_EARN_DUE_PREM_TEMP2 purge snapshot log';


			-- 21-05-2026 Project Crown changes to add logging

            gv_trcmsg := '6.3 Truncated tbl FCT_RPT_EARN_DUE_PREM_TEMP2';
            pkg_grp_log_util.prc_ins_prcs_job_log_message_r
				(
					p_job_id_r                    => gn_out_job_id,
					p_batch_id_r                  => gn_sysdt_batchid,
					p_message_type_r              => gv_message_type_r,
					p_code_location_r             => gv_main_loadedby,
					p_message_r                   => gv_trcmsg,
					p_count_type_r                => NULL,
					p_count_r                     => NULL,
					p_duration_r                  => NULL,
					p_created_by_r                => gv_job_name,
					out_prcs_job_log_message_id_r => gn_job_log_message_id_r
				);

            gt_start_time := systimestamp;
            gv_trcmsg := '7.Insert tbl FCT_RPT_EARN_DUE_PREM_TEMP1';
            pkg_grp_log_util.prc_ins_prcs_job_log_message_r
				(
					p_job_id_r                    => gn_out_job_id,
					p_batch_id_r                  => gn_sysdt_batchid,
					p_message_type_r              => gv_message_type_r,
					p_code_location_r             => gv_main_loadedby,
					p_message_r                   => gv_trcmsg,
					p_count_type_r                => NULL,
					p_count_r                     => NULL,
					p_duration_r                  => NULL,
					p_created_by_r                => gv_job_name,
					out_prcs_job_log_message_id_r => gn_job_log_message_id_r
				);

            INSERT /*+APPEND_VALUES*/ INTO fct_rpt_earn_due_prem_temp1 --as
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
                                        END                                                              AS filter_values,	--19-Mar-2026 Crown Changes																					 
                                        atomic.fct_billing_policy_premium_r_table.v_source_system_name_r AS v_source_system_name_r,	--25-Mar-2026 Crown Changes																			 
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
                                         -- <> 'Terminated'
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
                                         --INNER JOIN atomic.STG_FCT_GRP_BILLING_POLICY_DTL_R_INCR ON atomic.FCT_BILLING_POLICY_PREMIUM_R_TABLE.N_SRC_POLICY_ID_R = STG_FCT_GRP_BILLING_POLICY_DTL_R_INCR.N_POLICY_ID_R  --changed now
                                        LEFT OUTER JOIN atomic.stg_fct_grp_billing_policy_dtl_r_incr ON atomic.fct_billing_policy_premium_r_table.
                                        n_src_policy_id_r = stg_fct_grp_billing_policy_dtl_r_incr.n_policy_id_r  --changed now	--19-Mar-2026 Crown Changes																																													   
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
			                                --BP.v_source_system_name_r='VUE' and --31-Jul-2024 changes
                                                    bp.v_source_system_name_r <> 'APS'
                                                AND --19-Mar-2026 Crown Changes
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
										 --v_source_system_name_r = 'VUE'
                                ) bp --19-Mar-2026 Crown Changes
                                INNER JOIN atomic.stg_fct_grp_billing_policy_dtl_r_incr pd ON bp.n_policy_sk_r = pd.n_policy_sk_r
                                LEFT JOIN atomic.dim_grp_policy_dir_r                  p ON p.n_policy_sk_r = bp.n_policy_sk_r
                                                                           AND p.v_active_status_r = 'Y'

                            --where BP.v_active_status_r = 'Y'
                            WHERE
                                    trunc(bp.d_record_start_date_r) <= (
                                        SELECT
                                            trunc(batch_date.d_calendar_date_r)
                                        FROM
                                            batch_date
                                        WHERE
                                            date_rank = 1
                                    ) --26-APR-23
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

            COMMIT;
			-- 21-05-2026 Project Crown changes to add logging

            gt_end_time := systimestamp;
            gv_trcmsg := '7.1.Inserted into tbl FCT_RPT_EARN_DUE_PREM_TEMP1';
            pkg_grp_log_util.prc_ins_prcs_job_log_message_r
					(
						p_job_id_r                    => gn_out_job_id,
						p_batch_id_r                  => gn_sysdt_batchid,
						p_message_type_r              => gv_message_type_r,
						p_code_location_r             => gv_main_loadedby,
						p_message_r                   => gv_trcmsg,
						p_count_type_r                => 'Insert',
						p_count_r                     => gn_run_cnt,
						p_duration_r                  => fnc_grp_time_duration(gt_start_time,gt_end_time),
						p_created_by_r                => gv_job_name,
						out_prcs_job_log_message_id_r => gn_job_log_message_id_r
					);

            gt_start_time := systimestamp;
            gv_trcmsg := '8.Load data into tbl FCT_RPT_EARN_DUE_PREM_TEMP2';
            pkg_grp_log_util.prc_ins_prcs_job_log_message_r
					(
						p_job_id_r                    => gn_out_job_id,
						p_batch_id_r                  => gn_sysdt_batchid,
						p_message_type_r              => gv_message_type_r,
						p_code_location_r             => gv_main_loadedby,
						p_message_r                   => gv_trcmsg,
						p_count_type_r                => NULL,
						p_count_r                     => NULL,
						p_duration_r                  => NULL,
						p_created_by_r                => gv_job_name,
						out_prcs_job_log_message_id_r => gn_job_log_message_id_r
					);

            FOR i IN (
                SELECT
                    a.*,
                    b.v_tpa_indicator_r
                FROM
                         fct_rpt_earn_due_prem_temp1 a
                    INNER JOIN atomic.dim_source_system_r b ON a.v_source_system_name_r = b.v_source_system_code_r
            ) --25-Mar-2026 Crown Changes
             LOOP
                IF i.v_tpa_indicator_r = 0 THEN
                    n_counter := 0;
                    v_due_date := i.premiumdue;
			--19-Mar-2026 Crown Changes 
                    WHILE ( n_counter < i.count ) LOOP
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
                        ) --25-Mar-2026 Crown Changes

                            SELECT
                                i.v_source_system_name_r,
                                i.cycle_date,
                                i.n_policy_sk_r,
                                i.n_customer_billgroup_id_r,
                                i.n_policy_billgroup_id_r,
                                v_due_date,
                                i.monthspaid,
                                add_months(i.premiumdue, i.monthspaid * - 1),
                                i.v_tpa_indicator_r --25-Mar-2026 Crown Changes

                            FROM
                                dual
                            WHERE
                                    v_due_date <= last_day(trunc(i.cycle_date) - 10)
                                AND ( i.bgtermdate IS NULL
                                      OR v_due_date < i.bgtermdate )
                                AND ( ( i.poltermdate IS NULL
                                        OR v_due_date < i.poltermdate ) );

                        v_due_date := add_months(v_due_date, i.monthspaid);
                        n_counter := n_counter + 1;
                    END LOOP;

                ELSIF i.v_tpa_indicator_r = 1 THEN --25-Mar-2026 Crown Changes
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

                END IF;
            END LOOP;

            -- 21-05-2026 Project Crown changes to add logging

            gt_end_time := systimestamp;
            gv_trcmsg := '8.2.Loaded data into tbl FCT_RPT_EARN_DUE_PREM_TEMP2';
            pkg_grp_log_util.prc_ins_prcs_job_log_message_r
				(
					p_job_id_r                    => gn_out_job_id,
					p_batch_id_r                  => gn_sysdt_batchid,
					p_message_type_r              => gv_message_type_r,
					p_code_location_r             => gv_main_loadedby,
					p_message_r                   => gv_trcmsg,
					p_count_type_r                => 'Insert',
					p_count_r                     => gn_run_cnt,
					p_duration_r                  => fnc_grp_time_duration(gt_start_time,gt_end_time),
					p_created_by_r                => gv_job_name,
					out_prcs_job_log_message_id_r => gn_job_log_message_id_r
				);

            COMMIT;
            gv_trcmsg := '9.Truncate tbl FCT_RPT_EARN_PRIOR_DUE_PREM_TEMP';
            pkg_grp_log_util.prc_ins_prcs_job_log_message_r
				(
					p_job_id_r                    => gn_out_job_id,
					p_batch_id_r                  => gn_sysdt_batchid,
					p_message_type_r              => gv_message_type_r,
					p_code_location_r             => gv_main_loadedby,
					p_message_r                   => gv_trcmsg,
					p_count_type_r                => NULL,
					p_count_r                     => NULL,
					p_duration_r                  => NULL,
					p_created_by_r                => gv_job_name,
					out_prcs_job_log_message_id_r => gn_job_log_message_id_r
				);

            EXECUTE IMMEDIATE 'truncate TABLE FCT_RPT_EARN_PRIOR_DUE_PREM_TEMP purge snapshot log';

			-- 21-05-2026 Project Crown changes to add logging

            gv_trcmsg := '9.1.Truncated tbl FCT_RPT_EARN_PRIOR_DUE_PREM_TEMP';
            pkg_grp_log_util.prc_ins_prcs_job_log_message_r
				(
					p_job_id_r                    => gn_out_job_id,
					p_batch_id_r                  => gn_sysdt_batchid,
					p_message_type_r              => gv_message_type_r,
					p_code_location_r             => gv_main_loadedby,
					p_message_r                   => gv_trcmsg,
					p_count_type_r                => NULL,
					p_count_r                     => NULL,
					p_duration_r                  => NULL,
					p_created_by_r                => gv_job_name,
					out_prcs_job_log_message_id_r => gn_job_log_message_id_r
				);

            gt_start_time := systimestamp;
            gv_trcmsg := '9.2.Insert into tbl FCT_RPT_EARN_PRIOR_DUE_PREM_TEMP';
            pkg_grp_log_util.prc_ins_prcs_job_log_message_r
				(
					p_job_id_r                    => gn_out_job_id,
					p_batch_id_r                  => gn_sysdt_batchid,
					p_message_type_r              => gv_message_type_r,
					p_code_location_r             => gv_main_loadedby,
					p_message_r                   => gv_trcmsg,
					p_count_type_r                => NULL,
					p_count_r                     => NULL,
					p_duration_r                  => NULL,
					p_created_by_r                => gv_job_name,
					out_prcs_job_log_message_id_r => gn_job_log_message_id_r
				);

            INSERT /*+APPEND_VALUES*/ INTO fct_rpt_earn_prior_due_prem_temp
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
                                ) bp--19-Mar-2026 Crown Changes
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
                                n_carrier_id_r -- no extra record
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
                                       --D_DUE_DATE_R,N_AMOUNT_PAID_R AmountPaid, V_POLICY_NUMBER_R, N_POLICY_BILLGROUP_ID_R, p1.N_POLICY_SK_R, N_CUSTOMER_BILLGROUP_ID_R
                                    FROM
                                             fct_billing_policy_premium_r_table p1
                                        INNER JOIN atomic.dim_source_system_r        b --25-Mar-2026 Crown Changes
                                         ON p1.v_source_system_name_r = b.v_source_system_code_r
                                        INNER JOIN dim_grp_billing_pol_billgrp_r_due pb ON p1.n_policy_sk_r = pb.n_policy_sk_r
                                                                                        AND p1.n_src_policy_billgroup_id_r = pb.n_policy_billgroup_id_r
                                        --and p1.N_SRC_POLICY_ID_R = pb.N_POLICY_ID_R
                                    WHERE
					                    --p1.V_SOURCE_SYSTEM_NAME_R !='MGIS' AND  --05022025 
                                        ( nvl(upper(v_user_name_r), 'NA') <> 'SUSPENSE ADJUSTMENT' )  -- added by lg - 2/23/2010 to not include this automated entry in annualized premium decisions
                                        --and D_TRANSACTION_DATE_R < D_PAID_TO_R
                                        --AND D_TRANSACTION_DATE_R < add_months(trunc((SELECT BATCH_DATE.D_CALENDAR_DATE_R FROM BATCH_DATE WHERE DATE_RANK= 1)),1)--23-Dec-2023 changes
                                        AND d_transaction_date_r < ld_fic_mis_date --23-Dec-2023 changes
                                        --and N_PREMIUM_TYPE_R IN (313, 344)
                                        AND ( ( b.v_tpa_indicator_r = 0
                                                AND n_premium_type_r IN ( 313, 344 ) )
                                              OR ( b.v_tpa_indicator_r = 1 
                                        --and N_PREMIUM_TYPE_R IN (313,314, 344)
                                               ) ) --25-Mar-2026 Crown Changes
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
                                p1.v_source_system_name_r AS v_source_system_name_r	--19-Mar-2026 Crown Changes							 
                                ,
                                pbd.cycle_date            d_cycle_date_r,
                                prior_n_batch_id_r,
                                pb.v_policy_number_r
                                --,PBD.DUEDATE D_DUE_DATE_R
                                ,
                                CASE
                                    WHEN pbd.v_tpa_indicator_r = 0 THEN
                                        pbd.duedate
                                    WHEN pbd.v_tpa_indicator_r = 1 THEN
                                        p1.d_due_date_r
                                END                       d_due_date_r --25-Mar-2026 Crown Changes	
                                ,
                                p1.v_coveragecode_r       v_coveragecode_r,
                                pb.v_short_name_r,
                                md.d_due_date_r           last_due_date_r,
                                pb.premium_mode
                         --    ,PBD.N_POLICY_BILLGROUP_ID_R
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
                                       --AND N_PREMIUM_TYPE_R IN ( 313, 344)
                                        AND ( ( pbd.v_tpa_indicator_r = 0
                                                AND pt1.n_premium_type_r IN ( 313, 344 ) )
                                              OR ( pbd.v_tpa_indicator_r = 1 
                                        --and PT1.N_PREMIUM_TYPE_R IN (313,314, 344)
                                               ) ) --25-Mar-2026 Crown Changes																																										
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
                                        --AND PT2.d_due_date_r between (PT2.D_SR_STATEMENT_DATE_R - 90) and PT2.D_SR_STATEMENT_DATE_R
                                        --AND LAST_DAY(PT2.D_SR_STATEMENT_DATE_R) = LAST_DAY(ADD_MONTHS(TO_DATE(pbd.CYCLE_DATE,'dd-mon-yy'),-1)) 
                                        AND trunc(pt2.d_sr_statement_date_r, 'MM') < trunc(to_date(pbd.cycle_date, 'dd-mon-yy'), 'MM') --17-Apr-2026 Crown Changes
                                )                         AS amountdue --25-Mar-2026 Crown Changes							  						  
                                ,
                                nvl(pbd.monthspaid, 0)    AS monthspaid
                               -- ,NULL
                               --, P.STATE
                               --,P1.V_USER_NAME_R CUSTOMERNAME
                               --,SUBSTR(CBG.BILLGROUPNUMBER,1,2) SUB
                               --, SUBSTR(CBG.BILLGROUPNUMBER,3) BILLGROUP
                                ,
                                p1.n_policy_sk_r,
                                pbd.n_policy_billgroup_id_r,
                                pb.n_carrier_id_r
                                --, --(select D_DUE_DATE_R from Max_due_date, FCT_RPT_EARN_DUE_PREM_TEMP1 where Max_due_date.D_DUE_DATE_R = PBD.DUEDATE and Max_due_date.N_POLICY_BILLGROUP_ID_R = FCT_RPT_EARN_DUE_PREM_TEMP1.N_POLICY_BILLGROUP_ID_R
                               --and Max_due_date.N_POLICY_SK_R = PBD.N_POLICY_SK_R)
                               --MD.D_DUE_DATE_R
                                ,
                                p1.v_source_system_name_r AS v_source_system_r --25-Mar-2026 Crown Changes													
                            FROM
                                     fct_rpt_earn_due_prem_temp2 pbd

                                 -- and MD.D_DUE_DATE_R = PBD.DUEDATE
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
                                --NVL(ROUND(AmountPaid,2),0) as DUE_PREMIUM, -- ADD THE DUE_DATE FILTERS
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
                                due_premium, --25-Mar-2026 Crown Changes
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
                                                WHEN to_char(d_due_date_r, 'DD') >= 28  THEN --TO_CHAR(DUEDATE,'DD') >= '31' OR TO_CHAR(DUEDATE,'DD') = '30' THEN
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
                            -- SEPARATE WITH CLAUSE
                            FROM
                                     due_premium_base c
                                INNER JOIN atomic.dim_source_system_r d ON c.v_source_system_r = d.v_source_system_code_r
                        ), due_premium_table_final AS (
                            SELECT --D.*
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
                                --D.D_TRANSACTION_DATE_R,
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
                                END AS unearned_premium, --18-05-2026 Crown Changes
                                --due_premium - earnedpremium AS unearned_premium,
                                d.v_source_system_name_r  --19-Mar-2026 Crown Changes						
                            FROM
                                     due_premium_table d
                                INNER JOIN dim_source_system_r ss ON d.v_source_system_name_r = ss.v_source_system_code_r
                        )
                        SELECT
                            *
                        FROM
                            due_premium_table_final
                    );

            gt_end_time := systimestamp;

			-- 21-05-2026 Project Crown changes to add logging

            gv_trcmsg := '9.3.Inserted into table FCT_RPT_EARN_PRIOR_DUE_PREM_TEMP';
            pkg_grp_log_util.prc_ins_prcs_job_log_message_r
					(
						p_job_id_r                    => gn_out_job_id,
						p_batch_id_r                  => gn_sysdt_batchid,
						p_message_type_r              => gv_message_type_r,
						p_code_location_r             => gv_main_loadedby,
						p_message_r                   => gv_trcmsg,
						p_count_type_r                => 'Insert',
						p_count_r                     => gn_run_cnt,
						p_duration_r                  => fnc_grp_time_duration(gt_start_time,gt_end_time),
						p_created_by_r                => gv_job_name,
						out_prcs_job_log_message_id_r => gn_job_log_message_id_r
					);

            gv_trcmsg := '10.Truncate table FCT_RPT_EARN_FINAL_DUE_PREM_TEMP';
            pkg_grp_log_util.prc_ins_prcs_job_log_message_r
					(
						p_job_id_r                    => gn_out_job_id,
						p_batch_id_r                  => gn_sysdt_batchid,
						p_message_type_r              => gv_message_type_r,
						p_code_location_r             => gv_main_loadedby,
						p_message_r                   => gv_trcmsg,
						p_count_type_r                => NULL,
						p_count_r                     => NULL,
						p_duration_r                  => NULL,
						p_created_by_r                => gv_job_name,
						out_prcs_job_log_message_id_r => gn_job_log_message_id_r
					);

            EXECUTE IMMEDIATE 'truncate table FCT_RPT_EARN_FINAL_DUE_PREM_TEMP purge snapshot log';
            gv_trcmsg := '10.1.Truncated table FCT_RPT_EARN_FINAL_DUE_PREM_TEMP';
            pkg_grp_log_util.prc_ins_prcs_job_log_message_r
					(
						p_job_id_r                    => gn_out_job_id,
						p_batch_id_r                  => gn_sysdt_batchid,
						p_message_type_r              => gv_message_type_r,
						p_code_location_r             => gv_main_loadedby,
						p_message_r                   => gv_trcmsg,
						p_count_type_r                => NULL,
						p_count_r                     => NULL,
						p_duration_r                  => NULL,
						p_created_by_r                => gv_job_name,
						out_prcs_job_log_message_id_r => gn_job_log_message_id_r
					);


		    -- 21-05-2026 Project Crown changes to add logging

            gt_start_time := systimestamp;
            gv_trcmsg := '10.2.Insert into table FCT_RPT_EARN_FINAL_DUE_PREM_TEMP';
            pkg_grp_log_util.prc_ins_prcs_job_log_message_r
				(
					p_job_id_r                    => gn_out_job_id,
					p_batch_id_r                  => gn_sysdt_batchid,
					p_message_type_r              => gv_message_type_r,
					p_code_location_r             => gv_main_loadedby,
					p_message_r                   => gv_trcmsg,
					p_count_type_r                => NULL,
					p_count_r                     => NULL,
					p_duration_r                  => NULL,
					p_created_by_r                => gv_job_name,
					out_prcs_job_log_message_id_r => gn_job_log_message_id_r
				);

            INSERT /*+APPEND_VALUES*/ INTO fct_rpt_earn_final_due_prem_temp
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
                                      --and cb.V_POLICY_PREFIX_R <> 'SR'
                                      --and (b.N_DUE_PREM_AMT_R <> 0 or b.N_DUE_PREM_UNEARNED_AMT <> 0  or b.N_DUE_PREM_UNEARNED_AMT <> 0)
                                    AND b.due_premium <> 0
                                    AND b.n_policy_billgroup_id_r = cb.n_policy_billgroup_id_r
                                   --AND b.V_CUSTOMER_BILL_GROUP_NUMBER_R = DTP.V_CUSTOMER_BILL_GROUP_NUMBER_R
                                    AND b.d_due_date_r >= add_months(last_day(trunc(b.d_cycle_date_r - 10)), premium_mode * - 12)
                            ) THEN
                                cb.d_due_date_r
                            ELSE
                                cb.d_cycle_date_r
                        END
                    ) > add_months(last_day(trunc(cb.d_cycle_date_r - 10)), premium_mode * - 12);

            COMMIT;

			-- 21-05-2026 Project Crown changes to add logging

            gt_end_time := systimestamp;
            gv_trcmsg := '10.3.Inserted into tbl FCT_RPT_EARN_FINAL_DUE_PREM_TEMP';
            pkg_grp_log_util.prc_ins_prcs_job_log_message_r
					(
						p_job_id_r                    => gn_out_job_id,
						p_batch_id_r                  => gn_sysdt_batchid,
						p_message_type_r              => gv_message_type_r,
						p_code_location_r             => gv_main_loadedby,
						p_message_r                   => gv_trcmsg,
						p_count_type_r                => 'Insert',
						p_count_r                     => gn_run_cnt,
						p_duration_r                  => fnc_grp_time_duration(gt_start_time,gt_end_time),
						p_created_by_r                => gv_job_name,
						out_prcs_job_log_message_id_r => gn_job_log_message_id_r
					);

            gt_start_time := systimestamp;
            gv_trcmsg := '11.Delete1 from tbl FCT_RPT_EARN_FINAL_DUE_PREM_TEMP';
            pkg_grp_log_util.prc_ins_prcs_job_log_message_r
					(
						p_job_id_r                    => gn_out_job_id,
						p_batch_id_r                  => gn_sysdt_batchid,
						p_message_type_r              => gv_message_type_r,
						p_code_location_r             => gv_main_loadedby,
						p_message_r                   => gv_trcmsg,
						p_count_type_r                => NULL,
						p_count_r                     => NULL,
						p_duration_r                  => NULL,
						p_created_by_r                => gv_job_name,
						out_prcs_job_log_message_id_r => gn_job_log_message_id_r
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

            COMMIT;

			-- 21-05-2026 Project Crown changes to add logging

            gt_end_time := systimestamp;
            gv_trcmsg := '11.1.Delete1 Completed from tbl FCT_RPT_EARN_FINAL_DUE_PREM_TEMP';
            pkg_grp_log_util.prc_ins_prcs_job_log_message_r
				(
					p_job_id_r                    => gn_out_job_id,
					p_batch_id_r                  => gn_sysdt_batchid,
					p_message_type_r              => gv_message_type_r,
					p_code_location_r             => gv_main_loadedby,
					p_message_r                   => gv_trcmsg,
					p_count_type_r                => 'Insert',
					p_count_r                     => gn_run_cnt,
					p_duration_r                  => fnc_grp_time_duration(gt_start_time,gt_end_time),
					p_created_by_r                => gv_job_name,
					out_prcs_job_log_message_id_r => gn_job_log_message_id_r
				);

            gt_start_time := systimestamp;
            gv_trcmsg := '11.2.Delete2 from tbl FCT_RPT_EARN_FINAL_DUE_PREM_TEMP';
            pkg_grp_log_util.prc_ins_prcs_job_log_message_r
				(
					p_job_id_r                    => gn_out_job_id,
					p_batch_id_r                  => gn_sysdt_batchid,
					p_message_type_r              => gv_message_type_r,
					p_code_location_r             => gv_main_loadedby,
					p_message_r                   => gv_trcmsg,
					p_count_type_r                => NULL,
					p_count_r                     => NULL,
					p_duration_r                  => NULL,
					p_created_by_r                => gv_job_name,
					out_prcs_job_log_message_id_r => gn_job_log_message_id_r
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
                ); --KEEP A NOTE OF THIS
            COMMIT;
            lc_step := lc_step
                       || chr(13)
                       || '12.1 Delete2 completed from table FCT_RPT_EARN_FINAL_DUE_PREM_TEMP'
                       || '->'
                       || ( dbms_utility.get_time - ln_time ) / 100;

         	--lc_step:=lc_step||chr(13)||'13 Delete3 from tbl FCT_RPT_EARN_FINAL_DUE_PREM_TEMP';--04-Nov-24 changes
            ln_time := dbms_utility.get_time;
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

            COMMIT;

			-- 21-05-2026 Project Crown changes to add logging

            gt_end_time := systimestamp;
            gv_trcmsg := '11.3.Delete2 Completed from tbl FCT_RPT_EARN_FINAL_DUE_PREM_TEMP';
            pkg_grp_log_util.prc_ins_prcs_job_log_message_r
				(
					p_job_id_r                    => gn_out_job_id,
					p_batch_id_r                  => gn_sysdt_batchid,
					p_message_type_r              => gv_message_type_r,
					p_code_location_r             => gv_main_loadedby,
					p_message_r                   => gv_trcmsg,
					p_count_type_r                => 'Insert',
					p_count_r                     => gn_run_cnt,
					p_duration_r                  => fnc_grp_time_duration(gt_start_time,gt_end_time),
					p_created_by_r                => gv_job_name,
					out_prcs_job_log_message_id_r => gn_job_log_message_id_r
				);

            gt_start_time := systimestamp;
            gv_trcmsg := '11.4.Delete3 from tbl FCT_RPT_EARN_FINAL_DUE_PREM_TEMP';
            pkg_grp_log_util.prc_ins_prcs_job_log_message_r
				(
					p_job_id_r                    => gn_out_job_id,
					p_batch_id_r                  => gn_sysdt_batchid,
					p_message_type_r              => gv_message_type_r,
					p_code_location_r             => gv_main_loadedby,
					p_message_r                   => gv_trcmsg,
					p_count_type_r                => NULL,
					p_count_r                     => NULL,
					p_duration_r                  => NULL,
					p_created_by_r                => gv_job_name,
					out_prcs_job_log_message_id_r => gn_job_log_message_id_r
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

            COMMIT;

			-- 21-05-2026 Project Crown changes to add logging  

            gt_end_time := systimestamp;
            gv_trcmsg := '11.7.Delete4 Completed from tbl FCT_RPT_EARN_FINAL_DUE_PREM_TEMP';
            pkg_grp_log_util.prc_ins_prcs_job_log_message_r
					(
						p_job_id_r                    => gn_out_job_id,
						p_batch_id_r                  => gn_sysdt_batchid,
						p_message_type_r              => gv_message_type_r,
						p_code_location_r             => gv_main_loadedby,
						p_message_r                   => gv_trcmsg,
						p_count_type_r                => 'Insert',
						p_count_r                     => gn_run_cnt,
						p_duration_r                  => fnc_grp_time_duration(gt_start_time,gt_end_time),
						p_created_by_r                => gv_job_name,
						out_prcs_job_log_message_id_r => gn_job_log_message_id_r
					);

            gv_trcmsg := '12.Truncate tbl FCT_RPT_EARN_PREMIUM_SUMMARY_R_INCR';
            pkg_grp_log_util.prc_ins_prcs_job_log_message_r
					(
						p_job_id_r                    => gn_out_job_id,
						p_batch_id_r                  => gn_sysdt_batchid,
						p_message_type_r              => gv_message_type_r,
						p_code_location_r             => gv_main_loadedby,
						p_message_r                   => gv_trcmsg,
						p_count_type_r                => NULL,
						p_count_r                     => NULL,
						p_duration_r                  => NULL,
						p_created_by_r                => gv_job_name,
						out_prcs_job_log_message_id_r => gn_job_log_message_id_r
					);

            EXECUTE IMMEDIATE 'truncate table FCT_RPT_EARN_PREMIUM_SUMMARY_R_INCR purge snapshot log';

			-- 21-05-2026 Project Crown changes to add logging

            gv_trcmsg := '12.1.Truncated tbl FCT_RPT_EARN_PREMIUM_SUMMARY_R_INCR';
            pkg_grp_log_util.prc_ins_prcs_job_log_message_r
					(
						p_job_id_r                    => gn_out_job_id,
						p_batch_id_r                  => gn_sysdt_batchid,
						p_message_type_r              => gv_message_type_r,
						p_code_location_r             => gv_main_loadedby,
						p_message_r                   => gv_trcmsg,
						p_count_type_r                => NULL,
						p_count_r                     => NULL,
						p_duration_r                  => NULL,
						p_created_by_r                => gv_job_name,
						out_prcs_job_log_message_id_r => gn_job_log_message_id_r
					);

            gt_start_time := systimestamp;
            gv_trcmsg := '12.2.Insert into tbl FCT_RPT_EARN_PREMIUM_SUMMARY_R_INCR';
            pkg_grp_log_util.prc_ins_prcs_job_log_message_r
					(
						p_job_id_r                    => gn_out_job_id,
						p_batch_id_r                  => gn_sysdt_batchid,
						p_message_type_r              => gv_message_type_r,
						p_code_location_r             => gv_main_loadedby,
						p_message_r                   => gv_trcmsg,
						p_count_type_r                => NULL,
						p_count_r                     => NULL,
						p_duration_r                  => NULL,
						p_created_by_r                => gv_job_name,
						out_prcs_job_log_message_id_r => gn_job_log_message_id_r
					);

            INSERT /*+APPEND_VALUES*/ INTO fct_rpt_earn_premium_summary_r_incr
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
                                        END                                                              AS filter_values,	--19-Mar-2026 Crown Changes																			   							  
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
                                        -- <> 'Terminated'
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
                                        --INNER JOIN ATOMIC.STG_FCT_GRP_BILLING_POLICY_DTL_R_INCR ON ATOMIC.FCT_BILLING_POLICY_PREMIUM_R_TABLE.N_SRC_POLICY_ID_R = STG_FCT_GRP_BILLING_POLICY_DTL_R_INCR.N_POLICY_ID_R  --changed now
                                        LEFT OUTER JOIN atomic.stg_fct_grp_billing_policy_dtl_r_incr ON atomic.fct_billing_policy_premium_r_table.
                                        n_src_policy_id_r = stg_fct_grp_billing_policy_dtl_r_incr.n_policy_id_r  --19-Mar-2026 Crown Changes																																																 
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
				                            --bp.v_source_system_name_r='VUE' and --31-Jul-2024 changes
                                                    bp.v_source_system_name_r <> 'APS'
                                                AND --19-Mar-2026 Crown Changes
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
                                filter_values = 1		--19-Mar-2026 Crown Changes		 

                        ), collected_premium_table_pre AS (
                            SELECT DISTINCT
                                d_sr_statement_date_r, --18-05-2026 Project Crown Changes	
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
                                /*SUM(
                                    CASE
                                        WHEN to_char(d_transaction_date_r, 'MMYYYY') = to_char(n_batch_id_r, 'MMYYYY') THEN
                                            round(c.n_amount_paid_r, 2)
                                        ELSE
                                            0.00
                                    END
                                ) AS collected_premium,*/
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
                                ) AS collected_premium, --18-05-2026 Project Crown Changes
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
                                c.v_short_name_r, --19-Mar-2026 Crown Changes
                                c.d_transaction_date_r,
                                c.v_premium_mode1_r,
                                c.premium_mode
                                --AND C.D_DUE_DATE_R = m.D_DUE_DATE_R1
                        ), collected_premium_table AS (
                            SELECT DISTINCT
                                v_source_system_name_r,
                                n_batch_id_r,
                                prior_n_batch_id_r,
                               --D_TRANSACTION_DATE_R,
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
                                n_batch_id_r, --19-Mar-2026 Crown Changes
                                prior_n_batch_id_r,
                                --D_TRANSACTION_DATE_R,
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
                                --nvl(EU.N_COLLECTED_PREMIUM_UNEARNED_AMT_R,0) AS N_COLLECTED_PREMIUM_UNEARNED_AMT_R
                            FROM
                                fct_rpt_earn_premium_summary_prior_r eu
                                --where RECORDTYPE in ('C', 'U')
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
                               /*(
			                    SELECT BATCH_DATE.D_CALENDAR_DATE_R FROM BATCH_DATE WHERE DATE_RANK= 1)  AS D_current_cycle_date,*/--03-Nov-2023 changes
                                coalesce(cb.v_source_system_name_r,eu.v_source_system_name_r)                                                  AS v_source_system_name_r, --19-Mar-2026 Crown Changes													 
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
                                 --D_current_cycle_date D_CYCLE_DATE_R,--03-Nov-2023 changes
                                collected_premium_table.v_source_system_name_r AS v_source_system_name_r,	--19-Mar-2026 Crown Changes	
                                (
                                    SELECT
                                        batch_date.d_calendar_date_r
                                    FROM
                                        batch_date
                                    WHERE
                                        date_rank = 1
                                )                                              d_cycle_date_r,--03-Nov-2023 changes
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
                                collected_premium_table.v_source_system_name_r,  --19-Mar-2026 Crown Changes	   
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
                                collected_premium_table.v_source_system_name_r,	--19-Mar-2026 Crown Changes											
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
										--v_source_system_name_r <> 'VUE'
                                ) bp --19-Mar-2026 Crown Changes
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
                                n_carrier_id_r -- no extra record
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
                                        --D_DUE_DATE_R,N_AMOUNT_PAID_R AmountPaid, V_POLICY_NUMBER_R, N_POLICY_BILLGROUP_ID_R, p1.N_POLICY_SK_R, N_CUSTOMER_BILLGROUP_ID_R
                                    FROM
                                             fct_billing_policy_premium_r_table p1
                                        INNER JOIN atomic.dim_source_system_r        b --25-Mar-2026 Crown Changes
                                         ON p1.v_source_system_name_r = b.v_source_system_code_r
                                        INNER JOIN dim_grp_billing_pol_billgrp_r_due pb ON p1.n_policy_sk_r = pb.n_policy_sk_r
                                                                                        AND p1.n_src_policy_billgroup_id_r = pb.n_policy_billgroup_id_r
                                    WHERE
                                        ( nvl(upper(v_user_name_r), 'NA') <> 'SUSPENSE ADJUSTMENT' )  -- added by lg - 2/23/2010 to not include this automated entry in annualized premium decisions
                                        --  and D_TRANSACTION_DATE_R < D_PAID_TO_R
                                        AND d_transaction_date_r < cycle_date + 1
                                      --AND N_PREMIUM_TYPE_R IN (313, 344)
                                        AND ( ( b.v_tpa_indicator_r = 0
                                                AND n_premium_type_r IN ( 313, 344 ) )
                                              OR ( b.v_tpa_indicator_r = 1
                                                   AND n_premium_type_r IN ( 313, 314, 344 ) ) ) --25-Mar-2026 Crown Changes
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
                             --,PBD.DUEDATE D_DUE_DATE_R
                                ,
                                CASE
                                    WHEN pbd.v_tpa_indicator_r = 0 THEN
                                        pbd.duedate
                                    WHEN pbd.v_tpa_indicator_r = 1 THEN
                                        p1.d_due_date_r
                                END                       d_due_date_r     --25-Mar-2026 Crown Changes                        
                                ,
                                p1.v_coveragecode_r       v_coveragecode_r,
                                pb.v_short_name_r,
                                pb.premium_mode
                                --    ,PBD.N_POLICY_BILLGROUP_ID_R
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
                                       --AND N_PREMIUM_TYPE_R IN ( 313, 344)
                                        AND ( ( pbd.v_tpa_indicator_r = 0
                                                AND pt1.n_premium_type_r IN ( 313, 344 ) )
                                              OR ( pbd.v_tpa_indicator_r = 1 
                                         --and PT1.N_PREMIUM_TYPE_R IN (313,314, 344)
                                               ) )			--25-Mar-2026 Crown Changes																																									   

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
                                        --N_AMOUNT_PAID_R = 0 and  
                                        AND pt2.n_amount_due_r <> 0
                                        --AND PT2.d_due_date_r between(PT2.D_SR_STATEMENT_DATE_R - 90) and PT2.D_SR_STATEMENT_DATE_R
                                        --AND LAST_DAY(PT2.D_SR_STATEMENT_DATE_R) = LAST_DAY(ADD_MONTHS(TO_DATE(pbd.CYCLE_DATE,'dd-mon-yy'),-1)) 
                                        AND trunc(pt2.d_sr_statement_date_r, 'MM') < trunc(to_date(pbd.cycle_date, 'dd-mon-yy'), 'MM') --17-Apr-2026 Crown Changes
                                )                         AS amountdue		--25-Mar-2026 Crown Changes										  
                                ,
                                nvl(pbd.monthspaid, 0)    AS monthspaid
                                -- ,NULL
                                ,
                                d_transaction_date_r
                                --, P.STATE
                                --,P1.V_USER_NAME_R CUSTOMERNAME
                                --,SUBSTR(CBG.BILLGROUPNUMBER,1,2) SUB
                                --, SUBSTR(CBG.BILLGROUPNUMBER,3) BILLGROUP
                                ,
                                p1.n_policy_sk_r,
                                pbd.n_policy_billgroup_id_r,
                                pb.n_carrier_id_r
                                --, --(select D_DUE_DATE_R from Max_due_date, FCT_RPT_EARN_DUE_PREM_TEMP1 where Max_due_date.D_DUE_DATE_R = PBD.DUEDATE and Max_due_date.N_POLICY_BILLGROUP_ID_R = FCT_RPT_EARN_DUE_PREM_TEMP1.N_POLICY_BILLGROUP_ID_R
                                --and Max_due_date.N_POLICY_SK_R = PBD.N_POLICY_SK_R)
                                --MD.D_DUE_DATE_R
                                ,
                                p1.v_source_system_name_r AS v_source_system_r
                            FROM
                                fct_rpt_earn_due_prem_temp2 pbd
                                INNER JOIN max_due_date md    ON md.n_policy_billgroup_id_r = pbd.n_policy_billgroup_id_r
                                                              AND md.n_policy_sk_r = pbd.n_policy_sk_r
                                 -- and MD.D_DUE_DATE_R = PBD.DUEDATE
                                INNER JOIN fct_billing_policy_premium_r_table p1 ON p1.n_policy_sk_r = pbd.n_policy_sk_r
                                                                                 AND p1.n_src_policy_billgroup_id_r = pbd.n_policy_billgroup_id_r
                                INNER JOIN dim_grp_product_r                  pc ON p1.v_coveragecode_r = pc.v_coverage_code_r
                                INNER JOIN dim_grp_billing_pol_billgrp_r_due  pb ON p1.n_policy_sk_r = pb.n_policy_sk_r
                                                                                 AND p1.n_src_policy_billgroup_id_r = pb.n_policy_billgroup_id_r
                                --where P1.V_COVERAGECODE_R = 3410
                        ), due_premium_table AS (
                            SELECT
                                c.*,
                                 --			 NVL(ROUND(AmountPaid,2),0) as DUE_PREMIUM, -- ADD THE DUE_DATE FILTERS
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
                                )   AS due_premium, --25-Mar-2026 Crown Changes
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
                                                WHEN to_char(d_due_date_r, 'DD') >= 28  THEN --TO_CHAR(DUEDATE,'DD') >= '31' OR TO_CHAR(DUEDATE,'DD') = '30' THEN
                                                    trunc(((round(amountpaid, 2) / monthspaid) * round(months_between(d_cycle_date_r,
                                                    d_due_date_r))), 2)
                                                ELSE
                                                    trunc(((round(amountpaid, 2) / monthspaid) * floor(months_between(d_cycle_date_r +
                                                    1, to_date(to_char(d_due_date_r, 'MM/YYYY'), 'MM/YYYY')))), 4) - trunc(((round(amountpaid,
                                                    2) / monthspaid) / 30) *(trunc(d_due_date_r) - to_date(to_char(d_due_date_r, 'mmyy'),
                                                    'MMYY')), 2)
                                        END
                                END AS earnedpremium
                               -- SEPARATE WITH CLAUSE
                            FROM
                                     due_premium_base c
                                INNER JOIN atomic.dim_source_system_r d --25-Mar-2026 Crown Changes
                                 ON c.v_source_system_r = d.v_source_system_code_r
                        ), due_premium_table_final AS (
                            SELECT
                                v_source_system_name_r,	--19-Mar-2026 Crown Changes					
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
                                v_source_system_name_r,	--19-Mar-2026 Crown Changes					
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
                                eu.v_source_system_name_r,	--19-Mar-2026 Crown Changes					   
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
                                v_source_system_name_r,	--19-Mar-2026 Crown Changes					
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
                                coalesce(cb.v_source_system_name_r, eu.v_source_system_name_r)                 AS v_source_system_name_r,	--19-Mar-2026 Crown Changes																					 
                                coalesce(cb.d_cycle_date_r, eu.d_cycle_date_r)                                 AS d_cycle_date_r,
                                nvl(cb.prior_n_batch_id_r, eu.prior_cycle_date)                                AS d_prior_cycle_date_r,
                                coalesce(cb.v_policy_number_r, eu.v_policy_number_r)                           AS v_policy_number_r,
                                coalesce(cb.v_customer_bill_group_number_r, eu.v_customer_bill_group_number_r) AS v_customer_bill_group_number_r,
                                coalesce(cb.v_coveragecode_r, eu.v_coverage_code_r)                            AS v_coverage_code_r,
                                coalesce(cb.d_due_date_r, eu.d_due_date_r)                                     AS d_due_date_r,
                               --D_TRANSACTION_DATE_R,
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
                        ),
             /*CONSTANT_EARNED_PREM_AMT_TABLE AS
             (
             SELECT
                 LAST_APC_PREMIUM_WEIGHT,
                 FCT_RPT_RATE_HISTORY_TABLE.V_POLICY_PREFIX_R || FCT_RPT_RATE_HISTORY_TABLE.V_POLICY_SUFFIX_R AS V_POLICY_NUMBER_R,
                 V_COVERAGE_CODE_R
                 FROM
                 DISTINCT_CURRENT_BASE_TABLE
                 LEFT OUTER JOIN
                 FCT_RPT_RATE_HISTORY_TABLE
                 ON DISTINCT_CURRENT_BASE_TABLE.V_POLICY_NUMBER_R = FCT_RPT_RATE_HISTORY_TABLE.V_POLICY_PREFIX_R || FCT_RPT_RATE_HISTORY_TABLE.V_POLICY_SUFFIX_R
                 AND DISTINCT_CURRENT_BASE_TABLE.V_COVERAGECODE_R = FCT_RPT_RATE_HISTORY_TABLE.V_COVERAGE_CODE_R
                 AND DISTINCT_CURRENT_BASE_TABLE.N_BATCH_ID_R BETWEEN FCT_RPT_RATE_HISTORY_TABLE.STARTING_CYCLE_DATE AND FCT_RPT_RATE_HISTORY_TABLE.ENDING_CYCLE_DATE
             )*/

             /*FINAL_DUE_TABLE AS
             (
             SELECT
             DUE_PREMIUM_TABLE_Final.D_CYCLE_DATE_R AS D_CYCLE_DATE_R,
             DUE_PREMIUM_TABLE_Final.N_POLICY_SK_R,
             DUE_PREMIUM_TABLE_Final.V_POLICY_NUMBER_R,
             DUE_PREMIUM_TABLE_Final.V_POLICY_PREFIX_R,
             DUE_PREMIUM_TABLE_Final.V_POLICY_SUFFIX_R,
             DUE_PREMIUM_TABLE_Final.V_CUSTOMER_BILL_GROUP_NUMBER_R,
             DUE_PREMIUM_TABLE_Final.V_SHORT_NAME_R,
             DUE_PREMIUM_TABLE_Final.V_COVERAGECODE_R AS V_COVERAGE_CODE_R,
             DUE_PREMIUM_TABLE_Final.D_DUE_DATE_R as D_DUE_DATE_R,
             DUE_PREMIUM_TABLE_Final.DUE_PREMIUM AS N_DUE_PREM_AMT_R,
             DUE_PREMIUM_TABLE_Final.UNEARNED_PREMIUM AS N_DUE_PREM_UNEARNED_AMT

             --'D' as RECORDTYPE
             FROM
              DUE_PREMIUM_TABLE_Final

             /*DUE_PREMIUM_TABLE_Final.D_TRANSACTION_DATE_R <= (SELECT BATCH_DATE.D_CALENDAR_DATE_R FROM BATCH_DATE WHERE DATE_RANK = 1)
             and (DUE_PREMIUM_TABLE_Final.D_TRANSACTION_DATE_R > (SELECT BATCH_DATE.D_CALENDAR_DATE_R FROM BATCH_DATE WHERE DATE_RANK = 2) OR
             (UNEARNED_PREMIUM <> 0 OR NOT (DUE_PREMIUM = 0 AND UNEARNED_PREMIUM = 0 AND D_TRANSACTION_DATE_R < (SELECT BATCH_DATE.D_CALENDAR_DATE_R FROM BATCH_DATE WHERE DATE_RANK = 2))))
             )*/ final_table AS (
                            SELECT DISTINCT
                                coalesce(fc.v_source_system_name_r, fd.v_source_system_name_r)                                                                                                                                                                                                                               AS
                                v_source_system_name_r, --19-Mar-2026 Crown Changes
                                coalesce(fc.d_cycle_date_r, fd.d_cycle_date_r)                                                                                                                                                                                                                                               AS
                                d_cycle_date_r,
                                coalesce(fc.d_due_date_r, fd.d_due_date_r)                                                                                                                                                                                                                                                   AS
                                d_due_date_r,
                                coalesce(fc.n_policy_sk_r, fd.n_policy_sk_r)                                                                                                                                                                                                                                                 AS
                                n_policy_sk_r,
                                coalesce(fc.v_policy_number_r, fd.v_policy_number_r)                                                                                                                                                                                                                                         AS
                                v_policy_number_r,
                                coalesce(fc.v_customer_bill_group_number_r, fd.v_customer_bill_group_number_r)                                                                                                                                                                                                               AS
                                v_customer_bill_group_number_r,
                                coalesce(fc.v_short_name_r, fd.v_short_name_r)                                                                                                                                                                                                                                               AS
                                v_short_name_r,
                                coalesce(fc.v_coverage_code_r, fd.v_coverage_code_r)                                                                                                                                                                                                                                         AS
                                v_coverage_code_r,
                               --FC.RECORDTYPE||FD.RECORDTYPE AS RECORDTYPE,
                                nvl(fc.n_collected_premium_amt_r, 0)                                                                                                                                                                                                                                                         AS
                                n_collected_premium_amt_r,--July load
                                nvl(fc.n_collected_premium_unearned_amt_r, 0)                                                                                                                                                                                                                                                AS
                                n_collected_premium_unearned_amt_r,--July load
                                (
                                    CASE
                                        WHEN fd.d_due_date_r >= due_date_filter.due_date_filter THEN
                                            nvl(fd.n_due_prem_amt_r, 0)
                                        ELSE
                                            0
                                    END
                                )                                                                                                                                                                                                                                                                                            AS
                                n_due_prem_amt_r, --July load
                                (
                                    CASE
                                        WHEN fd.d_due_date_r >= due_date_filter.due_date_filter THEN
                                            nvl(fd.n_due_prem_unearned_amt, 0)
                                        ELSE
                                            0
                                    END
                                )                                                                                                                                                                                                                                                                                            AS
                                n_due_prem_unearned_amt, --July load
                                ( nvl(fc.n_collected_premium_unearned_amt_r, 0) + nvl((
                                    CASE
                                        WHEN fd.d_due_date_r >= due_date_filter.due_date_filter THEN
                                            nvl(fd.n_due_prem_unearned_amt, 0)
                                        ELSE
                                            0
                                    END
                                ), 0) )                                                                                                                                                                                                                                                                                      AS
                                n_prem_unearned_amt,
                                ( nvl(fc.n_collected_premium_amt_r, 0) + nvl(n_mtd_chg_due_premium_amt_r, 0) )                                                                                                                                                                                                               AS
                                n_written_prem_amt_r, -- check for non
                                ( nvl(fc.n_collected_premium_amt_r, 0) + nvl(n_mtd_chg_due_premium_amt_r, 0) ) - ( ( nvl(fc.n_collected_premium_unearned_amt_r,
                                0) + (
                                    CASE
                                        WHEN fd.d_due_date_r >= due_date_filter.due_date_filter THEN
                                            nvl(fd.n_due_prem_unearned_amt, 0)
                                        ELSE
                                            0
                                    END
                                ) ) - ( ( nvl(fc.n_prior_collected_premium_unearned_amt_r, 0) + nvl(fd.prior_n_due_prem_unearned_amt,
                                0) ) ) )                                                                                                                                                                               n_earned_prem_amt_r,
                                coalesce(fc.d_prior_cycle_date_r, fd.d_prior_cycle_date_r)                                                                                                                                                                                                                                   AS
                                d_prior_cycle_date_r,
                                nvl(n_prior_collected_premium_amt_r, 0)                                                                                                                                                                                                                                                      AS
                                n_prior_collected_premium_amt_r,
                                nvl(n_prior_collected_premium_unearned_amt_r, 0)                                                                                                                                                                                                                                             AS
                                n_prior_collected_premium_unearned_amt_r,
                                nvl(n_mtd_chg_collected_premium_amt_r, 0)                                                                                                                                                                                                                                                    AS
                                n_mtd_chg_collected_premium_amt_r,
                                nvl(n_mtd_collected_premium_unearned_amt_r, 0)                                                                                                                                                                                                                                               AS
                                n_mtd_collected_premium_unearned_amt_r,
                                nvl(prior_n_due_prem_amt_r, 0)                                                                                                                                                                                                                                                               AS
                                n_prior_due_prem_amt_r,
                                nvl(prior_n_due_prem_unearned_amt, 0)                                                                                                                                                                                                                                                        AS
                                n_prior_dueprem_unearned_amt_r,
                                nvl(n_prior_prem_unearned_amt_r, 0)                                                                                                                                                                                                                                                          AS
                                n_prior_prem_unearned_amt_r, --calculate the logic
                                nvl(n_mtd_chg_due_premium_amt_r, 0)                                                                                                                                                                                                                                                          AS
                                n_chg_due_prem_amt_r,
                                nvl(n_mtd_chg_due_premium_unearned_amt_r, 0)                                                                                                                                                                                                                                                 AS
                                n_chg_due_prem_unearned_amt_r,
                                ( ( nvl(fc.n_collected_premium_unearned_amt_r, 0) + nvl((
                                    CASE
                                        WHEN fd.d_due_date_r >= due_date_filter.due_date_filter THEN
                                            nvl(fd.n_due_prem_unearned_amt, 0)
                                        ELSE
                                            0
                                    END
                                ), 0) ) - nvl(n_prior_prem_unearned_amt_r, 0) )                                                                                                                                                                                                                                              AS
                                n_chg_prem_unearned_amt_r, --calculate the logic
                                ' '                                                                                                                                                                                                                                                                                          v_reinsurer_r,
                                ' '                                                                                                                                                                                                                                                                                          v_reinsurance_indicator_r,
                                0                                                                                                                                                                                                                                                                                            n_reinsurance_pct_r,
                                nvl(fd.n_due_prem_amt_r, 0)                                                                                                                                                                                                                                                                  AS
                                n_due_prem_amt_r_all,
                                nvl(fd.n_due_prem_unearned_amt, 0)                                                                                                                                                                                                                                                           AS
                                n_due_prem_unearned_amt_all,
                                ( nvl(fc.n_collected_premium_unearned_amt_r, 0) + nvl(fd.n_due_prem_unearned_amt, 0) )                                                                                                                                                                                                       AS
                                n_prem_unearned_amt_all,
                                nvl(prior_n_due_prem_amt_r_all, 0)                                                                                                                                                                                                                                                           n_prior_due_prem_amt_r_all,
                                nvl(prior_n_due_prem_unearned_amt_all, 0)                                                                                                                                                                                                                                                    n_prior_dueprem_unearned_amt_r_all,
                                nvl(n_prior_prem_unearned_amt_r_all, 0)                                                                                                                                                                                                                                                      AS
                                n_prior_prem_unearned_amt_r_all,
                                ( nvl(fc.n_collected_premium_amt_r, 0) + nvl(n_mtd_chg_due_premium_amt_r_all, 0) ) - ( ( nvl(fc.n_collected_premium_unearned_amt_r,
                                0) + nvl(fd.n_due_prem_unearned_amt, 0) ) - ( ( nvl(fc.n_prior_collected_premium_unearned_amt_r, 0) +
                                nvl(fd.prior_n_due_prem_unearned_amt_all, 0) ) ) ) n_earned_prem_amt_r_all,
                                nvl(n_mtd_chg_due_premium_amt_r_all, 0)                                                                                                                                                                                                                                                      n_chg_due_prem_amt_r_all,
                                nvl(n_mtd_chg_due_premium_unearned_amt_r_all, 0)                                                                                                                                                                                                                                             n_chg_due_prem_unearned_amt_r_all,
                                ( ( nvl(fc.n_collected_premium_unearned_amt_r, 0) + nvl(fd.n_due_prem_unearned_amt, 0) ) - n_prior_prem_unearned_amt_r_all )                                                                                                                                                                 AS
                                n_chg_prem_unearned_amt_r_all
                            FROM
                                final_collected_table fc
                                FULL OUTER JOIN final_due_table       fd ON fc.v_source_system_name_r = fd.v_source_system_name_r	--19-Mar-2026 Crown Changes													 
                                                                      AND fc.d_cycle_date_r = fd.d_cycle_date_r
                                                                      AND fc.v_policy_number_r = fd.v_policy_number_r
                                                                      AND fd.v_customer_bill_group_number_r = fc.v_customer_bill_group_number_r
                                                                      AND fc.v_coverage_code_r = fd.v_coverage_code_r
                                                                      AND fc.d_due_date_r = fd.d_due_date_r
                                LEFT JOIN due_date_filter ON fd.d_cycle_date_r = due_date_filter.cycle_date
                        )
                        SELECT DISTINCT
                            ft.d_cycle_date_r,
                            d_due_date_r,
                            n_policy_sk_r,
                            ft.v_policy_number_r,
                            v_customer_bill_group_number_r,
                            v_short_name_r,
                            ft.v_coverage_code_r,
                            n_collected_premium_amt_r,
                            n_collected_premium_unearned_amt_r,
                            n_due_prem_amt_r,
                            n_due_prem_unearned_amt,
                            n_prem_unearned_amt,
                            n_written_prem_amt_r,
                            n_earned_prem_amt_r,
                            d_prior_cycle_date_r,
                            n_prior_collected_premium_amt_r,
                            n_prior_collected_premium_unearned_amt_r,
                            n_mtd_chg_collected_premium_amt_r,
                            n_mtd_collected_premium_unearned_amt_r,
                            n_prior_due_prem_amt_r,
                            n_prior_dueprem_unearned_amt_r,
                            n_prior_prem_unearned_amt_r,
                            n_chg_due_prem_amt_r,
                            n_chg_due_prem_unearned_amt_r,
                            n_chg_prem_unearned_amt_r,
                            ( nvl(constant_earned_prem_amt_table.last_apc_premium_weight, 1) * n_earned_prem_amt_r ) AS n_constant_earned_prem_amt_r,
                            v_reinsurer_r,
                            v_reinsurance_indicator_r,
                            n_reinsurance_pct_r,
                            n_due_prem_amt_r_all,
                            n_due_prem_unearned_amt_all,
                            n_prem_unearned_amt_all,
                            n_prior_due_prem_amt_r_all,
                            n_prior_dueprem_unearned_amt_r_all,
                            n_prior_prem_unearned_amt_r_all,
                            n_earned_prem_amt_r_all,
                            n_chg_due_prem_amt_r_all,
                            n_chg_due_prem_unearned_amt_r_all,
                            n_chg_prem_unearned_amt_r_all,
                            ld_sysdate                                                                               AS fic_mis_date_r,
                            --,'ODI' as V_SOURCE_SYSTEM_NAME_R
                            v_source_system_name_r                                                                   AS v_source_system_name_r	--19-Mar-2026 Crown Changes							   
                            --,'EDW' as V_SOURCE_SYSTEM_NAME_R
                            --,'ODI' as V_SUBJECT_AREA_TYPE_R
                            ,
                            'EDW'                                                                                    AS v_subject_area_type_r,
                            1                                                                                        AS n_version_number_r,
                            ' '                                                                                      AS f_physical_delete_r,
                            ' '                                                                                      AS v_change_reason_r,
                            - 1                                                                                      AS n_claim_sk_r,
                            - 1                                                                                      AS n_party_sk_r,
                            - 1                                                                                      AS n_quote_sk_r,
                            - 1                                                                                      AS n_load_run_id_r,
                            - 1                                                                                      AS n_sequence_number_r,
                            ld_sysdate                                                                               AS t_creation_date_r,
                            ld_sysdate                                                                               AS t_event_timestamp_r,
                            ld_sysdate                                                                               AS t_last_modified_date_r,
                            'PRC_GRP_LOAD_TOTAL_EARN_PREM'                                                           AS v_created_by_r,
                            'PRC_GRP_LOAD_TOTAL_EARN_PREM'                                                           AS v_last_modified_by_r,
                            ' '                                                                                      AS v_privacy_indicator_r,
                            ' '                                                                                      AS v_customer_number_r,
                            ld_sysdate                                                                               AS n_batch_id_r
                        FROM
                            final_table ft
                            LEFT OUTER JOIN constant_earned_prem_amt_table ON ft.v_policy_number_r = constant_earned_prem_amt_table.v_policy_number_r
                                                                              AND ft.v_coverage_code_r = constant_earned_prem_amt_table.
                                                                              v_coverage_code_r
                                                                              AND ft.d_cycle_date_r BETWEEN constant_earned_prem_amt_table.
                                                                              starting_cycle_date AND constant_earned_prem_amt_table.
                                                                              ending_cycle_date
                    );	--PreProd Atomic 19C	3/31/23 1:18 PM	SQL	1	304.274
            COMMIT;

			-- 21-05-2026 Project Crown changes to add logging
            gt_end_time := systimestamp;
            gv_trcmsg := '12.3.Inserted into tbl FCT_RPT_EARN_PREMIUM_SUMMARY_R_INCR';
            pkg_grp_log_util.prc_ins_prcs_job_log_message_r
					(
						p_job_id_r                    => gn_out_job_id,
						p_batch_id_r                  => gn_sysdt_batchid,
						p_message_type_r              => gv_message_type_r,
						p_code_location_r             => gv_main_loadedby,
						p_message_r                   => gv_trcmsg,
						p_count_type_r                => 'Insert',
						p_count_r                     => gn_run_cnt,
						p_duration_r                  => fnc_grp_time_duration(gt_start_time,gt_end_time),
						p_created_by_r                => gv_job_name,
						out_prcs_job_log_message_id_r => gn_job_log_message_id_r
					);  

            /*2.	After loading FCT_RPT_EARN_PREMIUM_SUMMARY_R_INCR, need to add 2 additional steps:
            a.	Insert into FCT_RPT_EARN_PREMIUM_SUMMARY_R
            i.	Delete from FCT_RPT_EARN_PREMIUM_SUMMARY_R where d_cycle_date_r = (select max(d_cycle_date_r) from FCT_RPT_EARN_PREMIUM_SUMMARY_R_INCR)
            ii.	 Insert into FCT_RPT_EARN_PREMIUM_SUMMARY_R select * from FCT_RPT_EARN_PREMIUM_SUMMARY_R_INCR
            b.	Insert into Fct_rpt_premium_summary_r
            i.	Delete from Fct_rpt_premium_summary_r where d_cycle_date_r = (select max(d_cycle_date_r) from FCT_RPT_EARN_PREMIUM_SUMMARY_R_INCR)
            ii.	Attached insert script that I have used in past Ã¢â‚¬â€œ may need to add/adjust batch id, etc.
            */

            DELETE FROM fct_rpt_earn_premium_summary_r
            WHERE
                    d_cycle_date_r = (
                        SELECT
                            MAX(a.d_cycle_date_r)
                        FROM
                            fct_rpt_earn_premium_summary_r_incr a
                        WHERE
                            nvl(a.v_created_by_r, '@') = 'PRC_GRP_LOAD_TOTAL_EARN_PREM'--04-Nov-24 changes
                    )
                AND nvl(v_created_by_r, '@') = 'PRC_GRP_LOAD_TOTAL_EARN_PREM'--04-Nov-24 changes
                ;

            COMMIT;

			-- 21-05-2026 Project Crown changes to add logging

            gt_end_time := systimestamp;
            gv_trcmsg := '13.1.Deleted MAX(cycle_date) Data from FCT_RPT_EARN_PREMIUM_SUMMARY_R';
            pkg_grp_log_util.prc_ins_prcs_job_log_message_r
					(
						p_job_id_r                    => gn_out_job_id,
						p_batch_id_r                  => gn_sysdt_batchid,
						p_message_type_r              => gv_message_type_r,
						p_code_location_r             => gv_main_loadedby,
						p_message_r                   => gv_trcmsg,
						p_count_type_r                => 'Insert',
						p_count_r                     => gn_run_cnt,
						p_duration_r                  => fnc_grp_time_duration(gt_start_time,gt_end_time),
						p_created_by_r                => gv_job_name,
						out_prcs_job_log_message_id_r => gn_job_log_message_id_r
					);

            gt_start_time := systimestamp;
            gv_trcmsg := '13.2.Delete Data from FCT_RPT_EARN_PREMIUM_SUMMARY_R from FCT_RPT_EARN_PREMIUM_SUMMARY_R_INCR which has been loaded in the last run but did not get deleted with MAX(cycle_date),incase of rerun';
            pkg_grp_log_util.prc_ins_prcs_job_log_message_r
					(
						p_job_id_r                    => gn_out_job_id,
						p_batch_id_r                  => gn_sysdt_batchid,
						p_message_type_r              => gv_message_type_r,
						p_code_location_r             => gv_main_loadedby,
						p_message_r                   => gv_trcmsg,
						p_count_type_r                => NULL,
						p_count_r                     => NULL,
						p_duration_r                  => NULL,
						p_created_by_r                => gv_job_name,
						out_prcs_job_log_message_id_r => gn_job_log_message_id_r
					);

            DELETE FROM fct_rpt_earn_premium_summary_r
            WHERE
                    nvl(v_created_by_r, '@') = 'PRC_GRP_LOAD_TOTAL_EARN_PREM'
                AND trunc(t_creation_date_r) = trunc(ld_sysdate);
			--04-Nov-24 changes
            COMMIT;

			-- 21-05-2026 Project Crown changes to add logging
            gt_end_time := systimestamp;
            gv_trcmsg := '13.3.Deleted Data from FCT_RPT_EARN_PREMIUM_SUMMARY_R from FCT_RPT_EARN_PREMIUM_SUMMARY_R_INCR which has been loaded in the last run but did not get deleted with MAX(cycle_date),incase of rerun';
            pkg_grp_log_util.prc_ins_prcs_job_log_message_r
					(
						p_job_id_r                    => gn_out_job_id,
						p_batch_id_r                  => gn_sysdt_batchid,
						p_message_type_r              => gv_message_type_r,
						p_code_location_r             => gv_main_loadedby,
						p_message_r                   => gv_trcmsg,
						p_count_type_r                => 'Insert',
						p_count_r                     => gn_run_cnt,
						p_duration_r                  => fnc_grp_time_duration(gt_start_time,gt_end_time),
						p_created_by_r                => gv_job_name,
						out_prcs_job_log_message_id_r => gn_job_log_message_id_r
					);


            gt_start_time := systimestamp;
            gv_trcmsg := '13.4.Insert into tbl FCT_RPT_EARN_PREMIUM_SUMMARY_R from FCT_RPT_EARN_PREMIUM_SUMMARY_R_INCR';
            pkg_grp_log_util.prc_ins_prcs_job_log_message_r
					(
						p_job_id_r                    => gn_out_job_id,
						p_batch_id_r                  => gn_sysdt_batchid,
						p_message_type_r              => gv_message_type_r,
						p_code_location_r             => gv_main_loadedby,
						p_message_r                   => gv_trcmsg,
						p_count_type_r                => NULL,
						p_count_r                     => NULL,
						p_duration_r                  => NULL,
						p_created_by_r                => gv_job_name,
						out_prcs_job_log_message_id_r => gn_job_log_message_id_r
					);

            INSERT /*+APPEND_VALUES*/ INTO fct_rpt_earn_premium_summary_r
                SELECT
                    *
                FROM
                    fct_rpt_earn_premium_summary_r_incr
                WHERE
                    nvl(v_created_by_r, '@') = 'PRC_GRP_LOAD_TOTAL_EARN_PREM'--04-Nov-24 changes
                    ;

            COMMIT;

			-- 21-05-2026 Project Crown changes to add logging
            gt_end_time := systimestamp;
            gv_trcmsg := '13.5.Inserted into tbl FCT_RPT_EARN_PREMIUM_SUMMARY_R from FCT_RPT_EARN_PREMIUM_SUMMARY';
            pkg_grp_log_util.prc_ins_prcs_job_log_message_r
					(
						p_job_id_r                    => gn_out_job_id,
						p_batch_id_r                  => gn_sysdt_batchid,
						p_message_type_r              => gv_message_type_r,
						p_code_location_r             => gv_main_loadedby,
						p_message_r                   => gv_trcmsg,
						p_count_type_r                => 'Insert',
						p_count_r                     => gn_run_cnt,
						p_duration_r                  => fnc_grp_time_duration(gt_start_time,gt_end_time),
						p_created_by_r                => gv_job_name,
						out_prcs_job_log_message_id_r => gn_job_log_message_id_r
					);

            gt_start_time := systimestamp;
            gv_trcmsg := '14.Delete MAX(cycle_date) Data from Fct_rpt_premium_summary_r';
            pkg_grp_log_util.prc_ins_prcs_job_log_message_r
					(
						p_job_id_r                    => gn_out_job_id,
						p_batch_id_r                  => gn_sysdt_batchid,
						p_message_type_r              => gv_message_type_r,
						p_code_location_r             => gv_main_loadedby,
						p_message_r                   => gv_trcmsg,
						p_count_type_r                => NULL,
						p_count_r                     => NULL,
						p_duration_r                  => NULL,
						p_created_by_r                => gv_job_name,
						out_prcs_job_log_message_id_r => gn_job_log_message_id_r
					);

            DELETE /*+PARALLEL(4)*/ FROM fct_rpt_premium_summary_r
            WHERE
                    d_cycle_date_r = (
                        SELECT
                            MAX(a.d_cycle_date_r)
                        FROM
                            fct_rpt_earn_premium_summary_r_incr a
                        WHERE
                            nvl(a.v_created_by_r, '@') = 'PRC_GRP_LOAD_TOTAL_EARN_PREM'--04-Nov-24 changes			                                                                
                    )
                AND nvl(v_created_by_r, '@') = 'PRC_GRP_LOAD_TOTAL_EARN_PREM';--04-Nov-24 changes
            COMMIT;

			-- 21-05-2026 Project Crown changes to add logging
            gt_end_time := systimestamp;
            gv_trcmsg := '14.1.Deleted MAX(cycle_date) Data from Fct_rpt_premium_summary_r';
            pkg_grp_log_util.prc_ins_prcs_job_log_message_r
					(
						p_job_id_r                    => gn_out_job_id,
						p_batch_id_r                  => gn_sysdt_batchid,
						p_message_type_r              => gv_message_type_r,
						p_code_location_r             => gv_main_loadedby,
						p_message_r                   => gv_trcmsg,
						p_count_type_r                => 'Insert',
						p_count_r                     => gn_run_cnt,
						p_duration_r                  => fnc_grp_time_duration(gt_start_time,gt_end_time),
						p_created_by_r                => gv_job_name,
						out_prcs_job_log_message_id_r => gn_job_log_message_id_r
					);

            gt_start_time := systimestamp;
            gv_trcmsg := '14.2.Delete Data from Fct_rpt_premium_summary_r which has been loaded in the last run but did not get deleted with MAX(cycle_date),incase of rerun';
            pkg_grp_log_util.prc_ins_prcs_job_log_message_r
					(
						p_job_id_r                    => gn_out_job_id,
						p_batch_id_r                  => gn_sysdt_batchid,
						p_message_type_r              => gv_message_type_r,
						p_code_location_r             => gv_main_loadedby,
						p_message_r                   => gv_trcmsg,
						p_count_type_r                => NULL,
						p_count_r                     => NULL,
						p_duration_r                  => NULL,
						p_created_by_r                => gv_job_name,
						out_prcs_job_log_message_id_r => gn_job_log_message_id_r
					);

            DELETE /*+PARALLEL(4)*/ FROM fct_rpt_premium_summary_r
            WHERE
                    nvl(v_created_by_r, '@') = 'PRC_GRP_LOAD_TOTAL_EARN_PREM'
                AND trunc(t_creation_date_r) = trunc(ld_sysdate);
			--04-Nov-24 changes
            COMMIT;


			-- 21-05-2026 Project Crown changes to add logging
            gt_end_time := systimestamp;
            gv_trcmsg := '14.3.Deleted Data from Fct_rpt_premium_summary_r which has been loaded in the last run but did not get deleted with MAX(cycle_date),incase of rerun';
            pkg_grp_log_util.prc_ins_prcs_job_log_message_r
				(
					p_job_id_r                    => gn_out_job_id,
					p_batch_id_r                  => gn_sysdt_batchid,
					p_message_type_r              => gv_message_type_r,
					p_code_location_r             => gv_main_loadedby,
					p_message_r                   => gv_trcmsg,
					p_count_type_r                => 'Insert',
					p_count_r                     => gn_run_cnt,
					p_duration_r                  => fnc_grp_time_duration(gt_start_time,gt_end_time),
					p_created_by_r                => gv_job_name,
					out_prcs_job_log_message_id_r => gn_job_log_message_id_r
				);

            gt_start_time := systimestamp;
            gv_trcmsg := '14.4.Select MAX(Seq_No)from Fct_rpt_premium_summary_r';
            pkg_grp_log_util.prc_ins_prcs_job_log_message_r
				(
					p_job_id_r                    => gn_out_job_id,
					p_batch_id_r                  => gn_sysdt_batchid,
					p_message_type_r              => gv_message_type_r,
					p_code_location_r             => gv_main_loadedby,
					p_message_r                   => gv_trcmsg,
					p_count_type_r                => NULL,
					p_count_r                     => NULL,
					p_duration_r                  => NULL,
					p_created_by_r                => gv_job_name,
					out_prcs_job_log_message_id_r => gn_job_log_message_id_r
				);

            SELECT /*+PARALLEL(4)*/
                MAX(n_sequence_number_r)
            INTO ln_max_seq_num1_r
            FROM
                fct_rpt_premium_summary_r;


			-- 21-05-2026 Project Crown changes to add logging

            gt_end_time := systimestamp;
            gv_trcmsg := '14.5.Selected MAX(Seq_No)from Fct_rpt_premium_summary_r';
            pkg_grp_log_util.prc_ins_prcs_job_log_message_r
					(
						p_job_id_r                    => gn_out_job_id,
						p_batch_id_r                  => gn_sysdt_batchid,
						p_message_type_r              => gv_message_type_r,
						p_code_location_r             => gv_main_loadedby,
						p_message_r                   => gv_trcmsg,
						p_count_type_r                => 'Insert',
						p_count_r                     => gn_run_cnt,
						p_duration_r                  => fnc_grp_time_duration(gt_start_time,gt_end_time),
						p_created_by_r                => gv_job_name,
						out_prcs_job_log_message_id_r => gn_job_log_message_id_r
					);

            gt_start_time := systimestamp;
            gv_trcmsg := '14.6.Insert into tbl fct_rpt_premium_summary_r from FCT_RPT_EARN_PREMIUM_SUMMARY_R_INCR';
            pkg_grp_log_util.prc_ins_prcs_job_log_message_r
					(
						p_job_id_r                    => gn_out_job_id,
						p_batch_id_r                  => gn_sysdt_batchid,
						p_message_type_r              => gv_message_type_r,
						p_code_location_r             => gv_main_loadedby,
						p_message_r                   => gv_trcmsg,
						p_count_type_r                => NULL,
						p_count_r                     => NULL,
						p_duration_r                  => NULL,
						p_created_by_r                => gv_job_name,
						out_prcs_job_log_message_id_r => gn_job_log_message_id_r
					);

            INSERT /*+APPEND_VALUES*/ INTO fct_rpt_premium_summary_r (
                n_batch_id_r,
                v_policy_number_r,
                v_customer_bill_group_number_r,
                v_short_name_r,
                v_coverage_code_r,
                n_collected_premium_amt_r,
                n_due_prem_amt_r,
                n_due_prem_unearned_amt,
                n_prem_unearned_amt,
                n_written_prem_amt_r,
                n_earned_prem_amt_r,
                d_prior_cycle_date_r,
                n_prior_due_prem_amt_r,
                n_prior_dueprem_unearned_amt_r,
                n_prior_prem_unearned_amt_r,
                n_chg_due_prem_amt_r,
                n_chg_due_prem_unearned_amt_r,
                n_chg_prem_unearned_amt_r,
                n_constant_earned_prem_amt_r,
                n_load_run_id_r,
                n_sequence_number_r,
                t_creation_date_r,
                t_event_timestamp_r,
                t_last_modified_date_r,
                v_created_by_r,
                v_last_modified_by_r,
                d_cycle_date_r,
                d_due_date_r,
                v_reinsurance_indicator_r,
                fic_mis_date_r,
                v_source_system_name_r,
                v_subject_area_type_r,
                n_version_number_r,
                f_physical_delete_r,
                v_change_reason_r,
                n_policy_sk_r,
                n_claim_sk_r,
                n_party_sk_r,
                n_quote_sk_r,
                n_prior_due_prem_amt_fin_r,
                n_chg_due_prem_amt_fin_r,
                n_due_prem_amt_fin_r,
                n_prior_dueprem_unearned_fin_r,
                n_chg_dueprem_unearned_fin_r,
                n_due_prem_unearned_amt_fin_r,
                v_customer_number_r,
                v_policy_prefix_r,
                v_policy_suffix_r,
                n_coll_prem_net_amt_r,
                n_due_prem_net_amt_r,
                n_due_prem_unearned_net_amt_r,
                n_prem_unearned_net_amt_r,
                n_written_prem_net_amt_r,
                n_earned_prem_net_amt_r,
                n_chg_due_prem_net_amt_r,
                n_chg_due_prm_unrnd_net_amt_r,
                n_chg_prem_unearned_net_amt_r,
                n_coll_prem_ceded_amt_r,
                n_due_prem_ceded_amt_r,
                n_due_prem_unearned_ceded_amt_r,
                n_prem_unearned_ceded_amt_r,
                n_written_prem_ceded_amt_r,
                n_earned_prem_ceded_amt_r,
                n_chg_due_prem_ceded_amt_r,
                n_chg_due_prm_unrnd_ceded_amt_r,
                n_chg_prem_unearned_ceded_amt_r,
                n_total_reins_prem_pct_r,
                n_primary_reins_prem_pct_r,
                n_sec_reins_prem_pct_r,
                n_ternary_reins_prem_pct_r,
                v_primary_reinsurer_r,
                v_secondary_reinsurer_r,
                v_ternary_reinsurer_r,
                v_privacy_indicator_r,
                n_collected_premium_unearned_amt_r,
                n_prior_collected_premium_amt_r,
                n_prior_collected_premium_unearned_amt_r,
                n_mtd_chg_collected_premium_amt_r,
                n_mtd_collected_premium_unearned_amt_r,
                n_due_prem_amt_r_all,
                n_due_prem_unearned_amt_all,
                n_prem_unearned_amt_all,
                n_prior_due_prem_amt_r_all,
                n_prior_dueprem_unearned_amt_r_all,
                n_prior_prem_unearned_amt_r_all,
                n_earned_prem_amt_r_all,
                n_chg_due_prem_amt_r_all,
                n_chg_due_prem_unearned_amt_r_all,
                n_chg_prem_unearned_amt_r_all
            )
                SELECT
                    ln_n_batch_id_r                    n_batch_id_r,
                    v_policy_number_r,
                    v_customer_bill_group_number_r,
                    v_short_name_r,
                    v_coverage_code_r,
                    n_collected_premium_amt_r,
                    n_due_prem_amt_r,
                    n_due_prem_unearned_amt,
                    n_prem_unearned_amt,
                    n_written_prem_amt_r,
                    n_earned_prem_amt_r,
                    d_prior_cycle_date_r,
                    n_prior_due_prem_amt_r,
                    n_prior_dueprem_unearned_amt_r,
                    n_prior_prem_unearned_amt_r,
                    n_chg_due_prem_amt_r,
                    n_chg_due_prem_unearned_amt_r,
                    n_chg_prem_unearned_amt_r,
                    n_constant_earned_prem_amt_r,
                    n_load_run_id_r,
                    nvl(ln_max_seq_num1_r, 0) + ROWNUM AS n_sequence_number_r,
                    t_creation_date_r,
                    t_event_timestamp_r,
                    t_last_modified_date_r,
                    v_created_by_r,
                    v_last_modified_by_r,
                    d_cycle_date_r,
                    d_due_date_r,
                    v_reinsurance_indicator_r,
                    fic_mis_date_r,
                    v_source_system_name_r,
                    v_subject_area_type_r,
                    n_version_number_r,
                    f_physical_delete_r,
                    v_change_reason_r,
                    n_policy_sk_r,
                    n_claim_sk_r,
                    n_party_sk_r,
                    n_quote_sk_r,
                    0                                  n_prior_due_prem_amt_fin_r,
                    0                                  n_chg_due_prem_amt_fin_r,
                    0                                  n_due_prem_amt_fin_r,
                    0                                  n_prior_dueprem_unearned_fin_r,
                    0                                  n_chg_dueprem_unearned_fin_r,
                    0                                  n_due_prem_unearned_amt_fin_r,
                    v_customer_number_r,
                    ' '                                v_policy_prefix_r,
                    ' '                                v_policy_suffix_r,
                    0                                  n_coll_prem_net_amt_r,
                    0                                  n_due_prem_net_amt_r,
                    0                                  n_due_prem_unearned_net_amt_r,
                    0                                  n_prem_unearned_net_amt_r,
                    0                                  n_written_prem_net_amt_r,
                    0                                  n_earned_prem_net_amt_r,
                    0                                  n_chg_due_prem_net_amt_r,
                    0                                  n_chg_due_prm_unrnd_net_amt_r,
                    0                                  n_chg_prem_unearned_net_amt_r,
                    0                                  n_coll_prem_ceded_amt_r,
                    0                                  n_due_prem_ceded_amt_r,
                    0                                  n_due_prem_unearned_ceded_amt_r,
                    0                                  n_prem_unearned_ceded_amt_r,
                    0                                  n_written_prem_ceded_amt_r,
                    0                                  n_earned_prem_ceded_amt_r,
                    0                                  n_chg_due_prem_ceded_amt_r,
                    0                                  n_chg_due_prm_unrnd_ceded_amt_r,
                    0                                  n_chg_prem_unearned_ceded_amt_r,
                    0                                  n_total_reins_prem_pct_r,
                    1                                  n_primary_reins_prem_pct_r,
                    0                                  n_sec_reins_prem_pct_r,
                    0                                  n_ternary_reins_prem_pct_r,
                    'N/A'                              v_primary_reinsurer_r,
                    'NA'                               v_secondary_reinsurer_r,
                    'NA'                               v_ternary_reinsurer_r,
                    'N/A'                              v_privacy_indicator_r,
                    n_collected_premium_unearned_amt_r,
                    n_prior_collected_premium_amt_r,
                    n_prior_collected_premium_unearned_amt_r,
                    n_mtd_chg_collected_premium_amt_r,
                    n_mtd_collected_premium_unearned_amt_r,
                    n_due_prem_amt_r_all,
                    n_due_prem_unearned_amt_all,
                    n_prem_unearned_amt_all,
                    n_prior_due_prem_amt_r_all,
                    n_prior_dueprem_unearned_amt_r_all,
                    n_prior_prem_unearned_amt_r_all,
                    n_earned_prem_amt_r_all,
                    n_chg_due_prem_amt_r_all,
                    n_chg_due_prem_unearned_amt_r_all,
                    n_chg_prem_unearned_amt_r_all
                FROM
                    fct_rpt_earn_premium_summary_r_incr
                WHERE
                    nvl(v_created_by_r, '@') = 'PRC_GRP_LOAD_TOTAL_EARN_PREM'--04-Nov-24 changes
                    ;

            COMMIT;

			-- 21-05-2026 Project Crown changes to add logging

            gt_end_time := systimestamp;
            gv_trcmsg := '14.7.Inserted into tbl Fct_rpt_premium_summary_r from FCT_RPT_EARN_PREMIUM_SUMMARY';
            pkg_grp_log_util.prc_ins_prcs_job_log_message_r
				(
					p_job_id_r                    => gn_out_job_id,
					p_batch_id_r                  => gn_sysdt_batchid,
					p_message_type_r              => gv_message_type_r,
					p_code_location_r             => gv_main_loadedby,
					p_message_r                   => gv_trcmsg,
					p_count_type_r                => 'Insert',
					p_count_r                     => gn_run_cnt,
					p_duration_r                  => fnc_grp_time_duration(gt_start_time,gt_end_time),
					p_created_by_r                => gv_job_name,
					out_prcs_job_log_message_id_r => gn_job_log_message_id_r
				);  

		--11-Sep-2023 changes starts
        ELSE

		    -- 21-05-2026 Project Crown changes to add logging
            gv_trcmsg := '6.1.2.Previous month '
                         || to_char(trunc(sysdate, 'MONTH') - 1, 'YYYYMM')
                         || ' data is NOT there in the tbl FCT_RPT_EARN_PREMIUM_SUMMARY_PRIOR_R '
                         || ln_prior_rec_cnt
                         || ' Records,hence terminating the job..please check the issue';

            pkg_grp_log_util.prc_ins_prcs_job_log_message_r
					(
						p_job_id_r                    => gn_out_job_id,
						p_batch_id_r                  => gn_sysdt_batchid,
						p_message_type_r              => gv_message_type_r,
						p_code_location_r             => gv_main_loadedby,
						p_message_r                   => gv_trcmsg,
						p_count_type_r                => NULL,
						p_count_r                     => NULL,
						p_duration_r                  => NULL,
						p_created_by_r                => gv_job_name,
						out_prcs_job_log_message_id_r => gn_job_log_message_id_r
					);

            RAISE custom_exception;
        END IF;--IF ln_prior_rec_cnt <> 0 THEN
		--11-Sep-2023 changes ends

        -- Block 3 Ends
    ELSE

	    -- 21-05-2026 Project Crown changes to add logging
        gv_trcmsg := 'Today is neither Fisc Month End Date +1 nor SATURDAY hence not loadig the data ';
    pkg_grp_log_util.prc_ins_prcs_job_log_message_r
				(
					p_job_id_r                    => gn_out_job_id,
					p_batch_id_r                  => gn_sysdt_batchid,
					p_message_type_r              => gv_message_type_r,
					p_code_location_r             => gv_main_loadedby,
					p_message_r                   => gv_trcmsg,
					p_count_type_r                => NULL,
					p_count_r                     => NULL,
					p_duration_r                  => NULL,
					p_created_by_r                => gv_job_name,
					out_prcs_job_log_message_id_r => gn_job_log_message_id_r
				);

    END IF;

	-- 21-05-2026 Project Crown changes to add logging
    gv_trcmsg := 'Update Success Log into PRCS_JOB_LOG_R';
    pkg_grp_log_util.prc_ins_prcs_job_log_message_r
				(
					p_job_id_r                    => gn_out_job_id,
					p_batch_id_r                  => gn_sysdt_batchid,
					p_message_type_r              => gv_message_type_r,
					p_code_location_r             => gv_main_loadedby,
					p_message_r                   => gv_trcmsg,
					p_count_type_r                => NULL,
					p_count_r                     => NULL,
					p_duration_r                  => NULL,
					p_created_by_r                => gv_job_name,
					out_prcs_job_log_message_id_r => gn_job_log_message_id_r
				);

    pkg_grp_log_util.prc_update_log(gn_out_job_id                   --p_job_id

    , gv_success_status               --p_job_status

    , gv_errmsg                       --p_err_msg

    , gv_trcmsg                       --p_trc_msg

    , gv_main_loadedby                --p_log_util_called_by_r

    );
    COMMIT;
EXCEPTION
    WHEN custom_exception THEN
	    -- 21-05-2026 Project Crown changes to add logging
        gv_trcmsg := 'Custom Exception Error in PRC_GRP_LOAD_TOTAL_EARN_PREM';
        pkg_grp_log_util.prc_ins_prcs_job_log_message_r
				(
					p_job_id_r                    => gn_out_job_id,
					p_batch_id_r                  => gn_sysdt_batchid,
					p_message_type_r              => gv_message_type_r,
					p_code_location_r             => gv_main_loadedby,
					p_message_r                   => gv_trcmsg,
					p_count_type_r                => NULL,
					p_count_r                     => NULL,
					p_duration_r                  => NULL,
					p_created_by_r                => gv_job_name,
					out_prcs_job_log_message_id_r => gn_job_log_message_id_r
				);

        COMMIT;
        raise_application_error(-20001, 'Custom Exception Error in PRC_GRP_LOAD_TOTAL_EARN_PREM:->' || lc_sqlerrm);
    WHEN OTHERS THEN


	    -- 21-05-2026 Project Crown changes to add logging
        gv_errmsg := substr(sqlerrm, 1, 4000);
        gv_trcmsg := '1. Error in PRC_LOAD_AND_EXCHANGE_PARTITIONS: ' || gv_errmsg;

    /*START: NEW LOGGING MECHANISM CHANGES*/
        pkg_grp_log_util.prc_update_log_message_r(n_prcs_job_log_message_id_r => gn_job_log_message_id_r, p_err_msg => gv_trcmsg);
        gv_trcmsg := 'Insert Error log into table';
        pkg_grp_log_util.prc_ins_prcs_job_log_message_r
				(
					p_job_id_r                    => gn_out_job_id,
					p_batch_id_r                  => gn_sysdt_batchid,
					p_message_type_r              => gv_message_type_r,
					p_code_location_r             => gv_main_loadedby,
					p_message_r                   => gv_trcmsg,
					p_count_type_r                => NULL,
					p_count_r                     => NULL,
					p_duration_r                  => NULL,
					p_created_by_r                => gv_job_name,
					out_prcs_job_log_message_id_r => gn_job_log_message_id_r
				);

        COMMIT;
--V_START_TIME := ATOMIC.LOG_TIME(V_START_TIME, '1.Capture PRC_GRP_LOAD_TOTAL_EARN_PREM-'||LN_N_BATCH_ID_R,V_CYCLE_DATE);
        raise_application_error(-20001, 'Error in PRC_GRP_LOAD_TOTAL_EARN_PREM:->' || lc_sqlerrm);
--RAISE;
END prc_grp_load_total_earn_prem;

/

  GRANT EXECUTE ON "ATOMIC"."PRC_GRP_LOAD_TOTAL_EARN_PREM" TO "EXT_EIS_RO";
  GRANT EXECUTE ON "ATOMIC"."PRC_GRP_LOAD_TOTAL_EARN_PREM" TO "ATOMIC_ALL_RO";
  GRANT EXECUTE ON "ATOMIC"."PRC_GRP_LOAD_TOTAL_EARN_PREM" TO "EXT_DIGITAL_RO";
  GRANT DEBUG ON "ATOMIC"."PRC_GRP_LOAD_TOTAL_EARN_PREM" TO "ATOMIC_DEBUG";
