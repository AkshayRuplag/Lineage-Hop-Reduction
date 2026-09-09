--------------------------------------------------------
--  DDL for Package Body PKG_GRP_LOAD_FCT_AGENT_COMMISSION_SUMMARY
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ATOMIC"."PKG_GRP_LOAD_FCT_AGENT_COMMISSION_SUMMARY" AS
/* *********************************************************************************************************************************
* Type -            PLSQL Package body
* Name -            PKG_GRP_LOAD_FCT_AGENT_COMMISSION_SUMMARY
* Owner -           ATOMIC
* Description -     This package has the PLSLQ procedures' declarations, used to populate the Group tables, called by ODI wrappers.
* Created on -      16-Sep-2021
* Created by -      Chanakya
* Dependent Tables - DIM_GRP_POLICY_DIR_R,FCT_GRP_BILLING_POLICY_DTL_R,DIM_GRP_PARTY_R,DIM_GRP_PARTY_DIR_R,DIM_EOI_APPLICATION_R,DIM_EOI_APPLICATION_HISTORY_R,DIM_EOI_APP_COVERAG_DECISION_R,DIM_GRP_APPLICATIONPOLICIES_R,DIM_EOI_TRANSACTION_R
------------------------------------------------------------------------------------------------------------------------------------
* Change log :
* 16-Sep-2021: This package loads daily/history data into  PKG_GRP_LOAD_FCT_AGENT_COMMISSION_SUMMARY table.
* 23-Sep-2022: Since this fct is truncate load hence added Execute immediate to truncate the table
* 14-Aug-2024: Added four Fields as part of 5500 changes (N_POLICY_BILLGROUP_SK_R,N_AGENT_SK_R,N_YEARMONTH_R,N_CUST_PARTY_SK_R)
* 07-OCT-2024: (PART OF 5500 CHANGES) REPLACED INSERT DATE WITH TRANSACTION DATE IN 1ST AND LAST UNION,ADDED PRIMARY AGENT ID OR PERSON ID = V_AGENT_ID_R in joining condition of M commission type 		union(i.e 2nd and 3rd union) and filter condition as DONOT PAY IN 1 in 2nd union(m commission type 1st union),added extra union same as M commission type union and change filter condition as DONOT PAY IN (17,23,25,27) in 3rd union(m commission type 2nd union)
* 07-MAY-2026:  Karthick  user story 514433 - UAT: 5500 Tax Reports - MGIS Version. Added the DONOTPAY CODE = 25 as void
* 05-Jun-2026:  Madhurima   Adding V_DATA_SOURCE_NAME_R field to capture the data ingestion source name. User Story - 522358
*********************************************************************************************************************************** */

    PROCEDURE prc_grp_load_fct_agent_commission_summary (
        in_batch_id_r        IN NUMBER,
        in_max_load_run_id_r IN NUMBER,
        out_load_status      OUT VARCHAR2
    ) IS
	/**************************************************************************************************************
	  Purpose:  This Procedure is to insert into table FCT_AGENT_COMMISSION_SUMMARY

		Author		Date     	Description
		---------	-------- 	-------------------------------------------------
		Chanakya	16/09/21	Initial Creation
		Madhurima	05/06/26	Adding V_DATA_SOURCE_NAME_R field to capture the data ingestion source name. User Story - 522358
	***************************************************************************************************************/  

        ln_n_batch_id_r         NUMBER := in_batch_id_r;
		--LN_N_BATCH_ID_R        NUMBER := TO_NUMBER(TO_CHAR(SYSDATE,'YYYYMMDD'));
        ln_n_load_run_id_r      NUMBER := in_max_load_run_id_r;
        ln_max_seq_numer_r      NUMBER;
        lc_sqlcode              VARCHAR2(4000);
        lc_sqlerrm              VARCHAR2(4000);
        lt_systimestamp         TIMESTAMP := systimestamp;
        ln_bulk_limit_r         NUMBER;
        ln_yearmonth            NUMBER := fnc_grp_get_ssl_yearmonth(sysdate);
        ld_sysdate              DATE := sysdate;
        gn_out_job_id           NUMBER;
        gc_trcmsg               CLOB := 'Trace Message:->';
        gd_sysdate              DATE := trunc(sysdate) - 1;
        gn_sysdt_batchid        NUMBER := to_number(to_char(gd_sysdate, 'YYYYMMDD'));
        gc_message_type_r       prcs_job_log_message_r.v_message_type_r%TYPE := pkg_grp_log_util.gc_message_type_info;
        gc_count_type_r         prcs_job_log_message_r.v_count_type_r%TYPE := pkg_grp_log_util.gc_count_type_insert;
        gc_main_loadedby        VARCHAR2(200 CHAR) := 'PKG_GRP_LOAD_FCT_AGENT_COMMISSION_SUMMARY.PRC_GRP_LOAD_FCT_AGENT_COMMISSION_SUMMARY';
        gn_job_log_message_id_r NUMBER;
        gc_job_name             VARCHAR2(50 CHAR) := 'GRP_LOAD_FCT_AGENT_COMMISSION_SUMMARY';

        CURSOR cur_v_debug_flag_r IS
        SELECT
            v_debug_flag_r,
            n_bulk_limit_r
        FROM
            prcs_grp_dataingestion_param_r
        WHERE
            v_job_name_r = 'GRP_LOAD_FCT_AGENT_COMMISSION_SUMMARY';--<Change to corresponding reporting table name after GRP_LOAD_>

        CURSOR cur_max_n_sequence_number_r IS
        SELECT
            nvl(MAX(n_sequence_number_r), 0)
        FROM
            fct_agent_commission_summary;--<Change the corresponding reporting table name>

    BEGIN
        gc_trcmsg := '1. Initialized cursor to load data into GRP_LOAD_FCT_AGENT_COMMISSION_SUMMARY and changed corresponding reporting table after load. ';

		/*START: NEW LOGGING MECHANISM CHANGES*/       
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
				(
				p_job_id_r                     => gn_out_job_id                                           
				,p_batch_id_r                  => gn_sysdt_batchid                                    
				,p_message_type_r              => gc_message_type_r                                    
				,p_code_location_r             => gc_main_loadedby                                 
				,p_message_r                   => gc_trcmsg                                                                 
				,p_count_type_r                => NULL                                                                          
				,p_count_r                     => NULL                                                                                     
				,p_duration_r                  => NULL                                                                                     
				,p_created_by_r                => gc_job_name                                                       
				,out_prcs_job_log_message_id_r => gn_job_log_message_id_r                       
				);            
		/*END: NEW LOGGING MECHANISM CHANGES*/

        IF ln_n_batch_id_r IS NULL THEN
            out_load_status := 'a) BatchID(IN_BATCH_ID) is null hence terminating the program';
            raise_application_error(-20001, 'a) BatchID(IN_BATCH_ID) is null hence terminating the program');
            gc_trcmsg := '1.1. Program terminated due to null BatchID. ';

			/*START: NEW LOGGING MECHANISM CHANGES*/       
			PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
					(
					p_job_id_r                     => gn_out_job_id                                           
					,p_batch_id_r                  => gn_sysdt_batchid                                    
					,p_message_type_r              => gc_message_type_r                                    
					,p_code_location_r             => gc_main_loadedby                                 
					,p_message_r                   => gc_trcmsg                                                                 
					,p_count_type_r                => NULL                                                                          
					,p_count_r                     => NULL                                                                                     
					,p_duration_r                  => NULL                                                                                     
					,p_created_by_r                => gc_job_name                                                       
					,out_prcs_job_log_message_id_r => gn_job_log_message_id_r                       
					);            
			/*END: NEW LOGGING MECHANISM CHANGES*/

        END IF;

        IF ln_n_load_run_id_r IS NULL THEN
            out_load_status := 'b) BatchID(IN_BATCH_ID) is null hence terminating the program';
            raise_application_error(-20001, 'b) BatchID(IN_BATCH_ID) is null hence terminating the program');
            gc_trcmsg := '1.2. Program terminated due to null load run ID. ';          
			/*START: NEW LOGGING MECHANISM CHANGES*/       
			PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
					(
					p_job_id_r                     => gn_out_job_id                                           
					,p_batch_id_r                  => gn_sysdt_batchid                                    
					,p_message_type_r              => gc_message_type_r                                    
					,p_code_location_r             => gc_main_loadedby                                 
					,p_message_r                   => gc_trcmsg                                                                 
					,p_count_type_r                => NULL                                                                          
					,p_count_r                     => NULL                                                                                     
					,p_duration_r                  => NULL                                                                                     
					,p_created_by_r                => gc_job_name                                                       
					,out_prcs_job_log_message_id_r => gn_job_log_message_id_r                       
					);            
			/*END: NEW LOGGING MECHANISM CHANGES*/

        END IF;

        gc_trcmsg := '2.1. Fetch data from Cursor cur_v_debug_flag_r ';
		/*START: NEW LOGGING MECHANISM CHANGES*/       
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
				(
				p_job_id_r                     => gn_out_job_id                                           
				,p_batch_id_r                  => gn_sysdt_batchid                                    
				,p_message_type_r              => gc_message_type_r                                    
				,p_code_location_r             => gc_main_loadedby                                 
				,p_message_r                   => gc_trcmsg                                                                 
				,p_count_type_r                => NULL                                                                          
				,p_count_r                     => NULL                                                                                     
				,p_duration_r                  => NULL                                                                                     
				,p_created_by_r                => gc_job_name                                                       
				,out_prcs_job_log_message_id_r => gn_job_log_message_id_r                       
				);            
		/*END: NEW LOGGING MECHANISM CHANGES*/

        OPEN cur_v_debug_flag_r;
        FETCH cur_v_debug_flag_r INTO
            gc_debug_flag,
            ln_bulk_limit_r;
        CLOSE cur_v_debug_flag_r;
        gc_trcmsg := '2.2. Data Fetch from Cursor cur_v_debug_flag_r complete. ';
		/*START: NEW LOGGING MECHANISM CHANGES*/       
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
				(
				p_job_id_r                     => gn_out_job_id                                           
				,p_batch_id_r                  => gn_sysdt_batchid                                    
				,p_message_type_r              => gc_message_type_r                                    
				,p_code_location_r             => gc_main_loadedby                                 
				,p_message_r                   => gc_trcmsg                                                                 
				,p_count_type_r                => NULL                                                                          
				,p_count_r                     => NULL                                                                                     
				,p_duration_r                  => NULL                                                                                     
				,p_created_by_r                => gc_job_name                                                       
				,out_prcs_job_log_message_id_r => gn_job_log_message_id_r                       
				);            
		/*END: NEW LOGGING MECHANISM CHANGES*/

        IF ln_bulk_limit_r IS NULL THEN
            ln_bulk_limit_r := 500;
        END IF;
        gc_trcmsg := '3.1. Fetch data from Cursor cur_max_n_sequence_number_r ';
        /*START: NEW LOGGING MECHANISM CHANGES*/       
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
				(
				p_job_id_r                     => gn_out_job_id                                           
				,p_batch_id_r                  => gn_sysdt_batchid                                    
				,p_message_type_r              => gc_message_type_r                                    
				,p_code_location_r             => gc_main_loadedby                                 
				,p_message_r                   => gc_trcmsg                                                                 
				,p_count_type_r                => NULL                                                                          
				,p_count_r                     => NULL                                                                                     
				,p_duration_r                  => NULL                                                                                     
				,p_created_by_r                => gc_job_name                                                       
				,out_prcs_job_log_message_id_r => gn_job_log_message_id_r                       
				);            
		/*END: NEW LOGGING MECHANISM CHANGES*/
        OPEN cur_max_n_sequence_number_r;
        FETCH cur_max_n_sequence_number_r INTO ln_max_seq_numer_r;
        CLOSE cur_max_n_sequence_number_r;
        gc_trcmsg := '3.2. Data Fetch from Cursor cur_max_n_sequence_number_r complete. ';
		/*START: NEW LOGGING MECHANISM CHANGES*/       
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
				(
				p_job_id_r                     => gn_out_job_id                                           
				,p_batch_id_r                  => gn_sysdt_batchid                                    
				,p_message_type_r              => gc_message_type_r                                    
				,p_code_location_r             => gc_main_loadedby                                 
				,p_message_r                   => gc_trcmsg                                                                 
				,p_count_type_r                => NULL                                                                          
				,p_count_r                     => NULL                                                                                     
				,p_duration_r                  => NULL                                                                                     
				,p_created_by_r                => gc_job_name                                                       
				,out_prcs_job_log_message_id_r => gn_job_log_message_id_r                       
				);            
		/*END: NEW LOGGING MECHANISM CHANGES*/

        gc_trcmsg := '4. Truncate and load table FCT_AGENT_COMMISSION_SUMMARY ';
		/*START: NEW LOGGING MECHANISM CHANGES*/       
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
				(
				p_job_id_r                     => gn_out_job_id                                           
				,p_batch_id_r                  => gn_sysdt_batchid                                    
				,p_message_type_r              => gc_message_type_r                                    
				,p_code_location_r             => gc_main_loadedby                                 
				,p_message_r                   => gc_trcmsg                                                                 
				,p_count_type_r                => NULL                                                                          
				,p_count_r                     => NULL                                                                                     
				,p_duration_r                  => NULL                                                                                     
				,p_created_by_r                => gc_job_name                                                       
				,out_prcs_job_log_message_id_r => gn_job_log_message_id_r                       
				);            
		/*END: NEW LOGGING MECHANISM CHANGES*/

        EXECUTE IMMEDIATE 'TRUNCATE TABLE ATOMIC.FCT_AGENT_COMMISSION_SUMMARY PURGE SNAPSHOT LOG';
        SAVEPOINT sp1;
        BEGIN
        --<08-06-2026: Added v_data_source_name_r in the Fct table>
        --<Change the corresponding reporting table name nd columns from that reporting table>
            INSERT INTO fct_agent_commission_summary (
                v_commission_status_r,
                v_policy_number_r,
                v_bill_group_number_r,
                v_agent_code_r,
                v_template_name_r,
                d_commission_date_r,
                d_due_date_r,
                d_paid_to_date_r,
                v_sales_rep_employee_number_r,
                v_agent_license_r,
                v_commission_type_r,
                n_commission_amount_r,
                fic_mis_date_r,
                n_batch_id_r,
                n_sequence_number_r,
                t_creation_date_r,
                t_event_timestamp_r,
                t_last_modified_date_r,
                v_created_by_r,
                v_last_modified_by_r,
                n_load_run_id_r,
                v_source_system_name_r,
                v_subject_area_type_r,
                n_version_number_r,
                f_physical_delete_r,
                v_change_reason_r,
                n_claim_sk_r,
                n_policy_sk_r,
                n_party_sk_r,
                n_quote_sk_r,
                n_policy_billgroup_sk_r,
                n_agent_sk_r,
                n_yearmonth_r,
                n_cust_party_sk_r,
                v_data_source_name_r --<Project Crown Changes 05-06-2026>
            )
                SELECT /*+enable_parallel_dml parallel(8)*/
                    v_commission_status_r,
                    final_tab.v_policy_number_r,
                    c.v_customer_bill_group_number_r,
                    v_agent_code_r,
                    v_template_name_r,
					--D_INSERT_DATE_R,
                    d_commission_date_r,--07-10-24-5500
                    d_due_date_r,
                    d_paid_to_date_r,
                    NULL                                                                AS v_sales_rep_employee_number_r,
                    v_agent_license_r,
                    v_commission_type_r,
                    n_commission_amount_r,
                    ld_sysdate                                                          AS fic_mis_date_r,
                    ln_n_batch_id_r                                                     AS n_batch_id_r,
                    ( ln_max_seq_numer_r + ROWNUM )                                     AS n_sequence_number_r,
                    lt_systimestamp                                                     AS t_creation_date_r,
                    lt_systimestamp                                                     AS t_event_timestamp_r,
                    lt_systimestamp                                                     AS t_last_modified_date_r,
                    'ODI'                                                               AS v_created_by_r,
                    'ODI'                                                               AS v_last_modified_by_r,
                    ln_n_load_run_id_r                                                  AS n_load_run_id_r,
                    tab_policy_sk.v_source_system_name_r                                AS v_source_system_name_r,
                    'ODI'                                                               AS v_subject_area_type_r,
                    1                                                                   AS n_version_number_r,
                    NULL                                                                AS f_physical_delete_r,
                    NULL                                                                AS v_change_reason_r,
                    - 1                                                                 AS n_claim_sk_r,
                    (
                        CASE
                            WHEN tab_policy_sk.n_policy_sk_r IS NULL THEN
                                - 1
                            ELSE
                                tab_policy_sk.n_policy_sk_r
                        END
                    )                                                                   AS n_policy_sk_r,
                    - 1                                                                 AS n_party_sk_r,
                    - 1                                                                 AS n_quote_sk_r,
                    nvl(nvl(b.n_policy_billgroup_sk_r, d.n_policy_billgroup_sk_r), - 1) AS n_policy_billgroup_sk_r,
                    nvl(n_agent_sk_r, - 1)                                              AS n_agent_sk_r,
                    ln_yearmonth                                                        AS n_yearmonth_r,
                    nvl(f.n_cust_party_sk_r, - 1)                                       AS n_cust_party_sk_r,
                    final_tab.v_data_source_name_r                                      AS v_data_source_name_r --<Project Crown Changes 05-06-2026>
                FROM
                    (
                        SELECT
                            p.v_policy_number_r          AS v_policy_number_r,
							--'' AS V_CUSTOMER_BILL_GROUP_NUMBER_R,
                            tab3.v_agent_number_r        AS v_agent_code_r,
                            tab4.v_template_name_r,
							--TAB5.D_INSERT_DATE_R,
							--TAB5.D_TRANSACTION_DATE_R, --07-10-24-5500
                            tab5.d_insert_date_r         d_commission_date_r,
                            tab5.d_prev_paid_to_date_r   AS d_due_date_r,
                            CAST('' AS DATE)             AS d_paid_to_date_r,
                            ''                           v_agent_license_r,
                            (
                                CASE
                                    WHEN substr(tab4.v_template_name_r, 3, 1) = 'A' THEN
                                        'A'
                                    WHEN substr(tab4.v_template_name_r, 3, 1) = 'O' THEN
                                        'O'
                                    WHEN substr(tab4.v_template_name_r, 2, 1) IN ( 'H', 'C' ) THEN
                                        'C'
                                    WHEN substr(tab4.v_template_name_r, 3, 1) = 'W' THEN
                                        NULL
                                    ELSE
                                        'M'
                                END
                            )                            AS v_commission_type_r,
                            tab5.n_commission_r          AS n_commission_amount_r,
                            (
                                CASE
                                    WHEN tab5.n_do_not_pay_r = 0  THEN
                                        'Open'
                                    WHEN tab5.n_do_not_pay_r = 1  THEN
                                        'Paid'
                                    WHEN tab5.n_do_not_pay_r IN ( 2, 3, 9, 12, 51,
                                                                  59, 99, 61 ) THEN
                                        'Pending'
                                    WHEN tab5.n_do_not_pay_r = 7  THEN
                                        'Terminated and not vested'
                                    WHEN tab5.n_do_not_pay_r = 52 THEN
                                        'No check/Non-monetary bonus'
                                    WHEN tab5.n_do_not_pay_r IN ( 17, 25, 18, 23 ) ----Added the DONOTAY CODE = 25 as void. Added the DONOTAY CODE = 25 as void.
                                     THEN
                                        'Void and Close Liability'
                                    WHEN tab5.n_do_not_pay_r IN ( 30 ) -- add 30
                                     THEN
                                        'Void and Replace'
                                    WHEN tab5.n_do_not_pay_r IN ( 35, 36, 37, 38 ) THEN
                                        'Void and Open Liability'
                                    WHEN tab5.n_do_not_pay_r = 29 THEN
                                        'Paid'
                                    ELSE
                                        'Other'
                                END
                            )                            AS v_commission_status_r,
                            tab5.n_statement_detail_id_r AS id,
                            tab5.n_policy_billgroup_id_r AS n_policy_billgroup_id_r,
                            tab4.n_agent_sk_r            AS n_agent_sk_r,
                            tab5.v_source_system_name_r  AS v_data_source_name_r --<Project Crown Changes 05-06-2026>
                        FROM
                                 (
                                SELECT
                                    *
                                FROM
                                    dim_grp_statement_detail_r
                                WHERE
                                    v_active_status_r = 'Y'
                            ) tab5
                            INNER JOIN (
                                SELECT
                                    *
                                FROM
                                    dim_grp_statement_r
                                WHERE
                                    v_active_status_r = 'Y'
                            ) s ON tab5.n_statement_id_r = s.n_statement_id_r and tab5.v_source_system_name_r = s.v_source_system_name_r
                            INNER JOIN (
                                SELECT
                                    *
                                FROM
                                    dim_grp_agent_r
                                WHERE
                                    v_active_status_r = 'Y'
                            ) tab3 ON s.n_entity_id_r = tab3.v_agent_id_r
                                      AND s.n_entity_type_id_r = 500
                            INNER JOIN (
                                SELECT
                                    *
                                FROM
                                    dim_grp_policy_dir_r
                                WHERE
                                    v_active_status_r = 'Y'
                            ) p ON tab5.n_policy_sk_r = p.n_policy_sk_r
                            LEFT JOIN (
                                SELECT
                                    *
                                FROM
                                    dim_grp_agent_contract_tmplt_r
                                WHERE
                                    v_active_status_r = 'Y'
                            ) tab4 ON tab5.n_template_id_r = tab4.n_contract_template_id_r
                                      AND tab5.n_policy_sk_r = tab4.n_policy_sk_r
                                      AND tab3.n_agent_sk_r = tab4.n_agent_sk_r
                        WHERE
                            substr(tab4.v_template_name_r, 3, 1) <> 'W'
                        UNION
                        SELECT
                            p.v_policy_number_r        v_policy_number_r,
							--  '' V_BILL_GROUP_NUMBER_R,
                            ag.v_agent_number_r        v_agent_code_r,
                            a.v_bonus_template_name_r  v_template_name_r,
							--a.D_STATEMENT_DATE_R D_COMMISSION_DATE_R,
                            a.d_record_start_date_r    d_commission_date_r,
                            CAST('' AS DATE)           d_due_date_r,
                            CAST('' AS DATE)           d_paid_to_date_r,
                            ''                         v_agent_license_r,
                            'M'                        v_commission_type_r,
                            (
                                CASE
                                    WHEN a.n_do_not_pay_r IN ( 17, 25, 18, 23, 35,
                                                               36, 37, 38 ) ----Added the DONOTAY CODE = 25 as void. Added the DONOTAY CODE = 25 as void.
                                                                THEN
                                        ( a.n_commission_r * - 1 )
                                    ELSE
                                        a.n_commission_r
                                END
                            )                          AS n_commission_amount_r,
                            CASE
                                WHEN a.n_do_not_pay_r = 0  THEN
                                    'Open'
                                WHEN a.n_do_not_pay_r = 1  THEN
                                    'Paid'
                                WHEN a.n_do_not_pay_r IN ( 2, 3, 9, 12, 51,
                                                           59, 99, 61 ) THEN
                                    'Pending'
                                WHEN a.n_do_not_pay_r = 7  THEN
                                    'Terminated and not vested'
                                WHEN a.n_do_not_pay_r = 52 THEN
                                    'No check/Non-monetary bonus'
                                WHEN a.n_do_not_pay_r IN ( 17, 25, 18, 23 ) ----Added the DONOTAY CODE = 25 as void. Added the DONOTAY CODE = 25 as void.
                                 THEN
                                    'Void and Close Liability'
                                WHEN a.n_do_not_pay_r IN ( 35, 36, 37, 38 ) THEN
                                    'Void and Open Liability'
                                WHEN a.n_do_not_pay_r = 29 THEN
                                    'Paid'
                                ELSE
                                    'Other'
                            END                        v_commission_status_r,
                            1                          AS id,
                            sd.n_policy_billgroup_id_r AS n_policy_billgroup_id_r,
                            ag.n_agent_sk_r            AS n_agent_sk_r,
                            'APS'                      AS v_data_source_name_r --<Project Crown Changes 05-06-2026>
                        FROM
                                 (
                                SELECT
                                    *
                                FROM
                                    dim_grp_person_maca_stmt_r
                                WHERE
                                    v_active_status_r = 'Y'
                            ) a
                            INNER JOIN (
                                SELECT
                                    *
                                FROM
                                    atomic.dim_grp_agent_r
                                WHERE
                                    v_active_status_r = 'Y'
                            ) ag
							--on a.V_AGENT_ID_R = ag.V_AGENT_ID_R
                             ON CASE 

										--WHEN a.N_IS_MULTIPLE_YTD_R = 1 THEN a.N_PERSON_ID_R 
                                        WHEN a.n_is_multiple_ytd_r = 1 THEN
                                            a.v_agent_id_r --17-10-2024

                                        ELSE
                                            to_char(a.n_primary_agent_id_r)
                                    END = ag.v_agent_id_r  --07-10-24-5500						 
                            INNER JOIN (
                                SELECT
                                    *
                                FROM
                                    dim_grp_policy_dir_r
                                WHERE
                                    v_active_status_r = 'Y'
                            ) p ON a.n_policy_sk_r = p.n_policy_sk_r
                            LEFT JOIN (
                                SELECT DISTINCT
                                    n_policy_sk_r,
                                    n_policy_billgroup_id_r
                                FROM
                                    (
                                        SELECT
                                            n_policy_sk_r,
                                            n_policy_billgroup_id_r,
                                            RANK()
                                            OVER(PARTITION BY n_policy_sk_r
                                                 ORDER BY
                                                     d_insert_date_r ASC, n_policy_billgroup_id_r ASC
                                            ) rnk
                                        FROM
                                            dim_grp_statement_detail_r
                                        WHERE
                                                v_active_status_r = 'Y'
                                            AND n_policy_billgroup_id_r IS NOT NULL
                                    )
                                WHERE
                                    rnk = 1
                            ) sd ON a.n_policy_sk_r = sd.n_policy_sk_r 
							--left join (select * from dim_grp_statement_detail_r where V_ACTIVE_STATUS_R = 'Y') sd
							--on a.N_POLICY_SK_R = sd.N_POLICY_SK_R and a.N_STATEMENT_ID_R=sd.N_STATEMENT_ID_R																				 
                        WHERE
                            a.n_do_not_pay_r IN ( 1 )--07-10-24-5500			

                        UNION   --07-10-24-5500
                        SELECT
                            p.v_policy_number_r        v_policy_number_r,
							-- '' V_BILL_GROUP_NUMBER_R,
                            ag.v_agent_number_r        v_agent_code_r,
                            a.v_bonus_template_name_r  v_template_name_r,
							--a.D_STATEMENT_DATE_R D_COMMISSION_DATE_R,
                            a.d_record_start_date_r    d_commission_date_r,
                            CAST('' AS DATE)           d_due_date_r,
                            CAST('' AS DATE)           d_paid_to_date_r,
                            ''                         v_agent_license_r,
                            'M'                        v_commission_type_r,
                            (
                                CASE
                                    WHEN a.n_do_not_pay_r IN ( 17, 25, 18, 23, 35,
                                                               36, 37, 38 ) ----Added the DONOTAY CODE = 25 as void. Added the DONOTAY CODE = 25 as void.
                                                                THEN
                                        ( a.n_commission_r * - 1 )
                                    ELSE
                                        a.n_commission_r
                                END
                            )                          AS n_commission_amount_r,
                            CASE
                                WHEN a.n_do_not_pay_r = 0  THEN
                                    'Open'
                                WHEN a.n_do_not_pay_r = 1  THEN
                                    'Paid'
                                WHEN a.n_do_not_pay_r IN ( 2, 3, 9, 12, 51,
                                                           59, 99, 61 ) THEN
                                    'Pending'
                                WHEN a.n_do_not_pay_r = 7  THEN
                                    'Terminated and not vested'
                                WHEN a.n_do_not_pay_r = 52 THEN
                                    'No check/Non-monetary bonus'
                                WHEN a.n_do_not_pay_r IN ( 17, 25, 18, 23 ) ----Added the DONOTAY CODE = 25 as void. Added the DONOTAY CODE = 25 as void.
                                 THEN
                                    'Void and Close Liability'
                                WHEN a.n_do_not_pay_r IN ( 35, 36, 37, 38 ) THEN
                                    'Void and Open Liability'
                                WHEN a.n_do_not_pay_r = 29 THEN
                                    'Paid'
                                ELSE
                                    'Other'
                            END                        v_commission_status_r,
                            1                          AS id,
                            sd.n_policy_billgroup_id_r AS n_policy_billgroup_id_r,
                            ag.n_agent_sk_r            AS n_agent_sk_r,
                            'APS'                      AS v_data_source_name_r --<Project Crown Changes 05-06-2026>
                        FROM
                                 (
                                SELECT
                                    *
                                FROM
                                    dim_grp_person_maca_stmt_r
                                WHERE
                                    v_active_status_r = 'Y'
                            ) a
                            INNER JOIN (
                                SELECT
                                    *
                                FROM
                                    atomic.dim_grp_agent_r
                                WHERE
                                    v_active_status_r = 'Y'
                            ) ag
							--on a.V_AGENT_ID_R = ag.V_AGENT_ID_R
                             ON CASE 

										--WHEN a.N_IS_MULTIPLE_YTD_R = 1 THEN a.N_PERSON_ID_R--17-10-2024
                                        WHEN a.n_is_multiple_ytd_r = 1 THEN
                                            a.v_agent_id_r
                                        ELSE
                                            to_char(a.n_primary_agent_id_r)
                                    END = ag.v_agent_id_r  --07-10-24-5500						 
                            INNER JOIN (
                                SELECT
                                    *
                                FROM
                                    dim_grp_policy_dir_r
                                WHERE
                                    v_active_status_r = 'Y'
                            ) p ON a.n_policy_sk_r = p.n_policy_sk_r
                            LEFT JOIN (
                                SELECT DISTINCT
                                    n_policy_sk_r,
                                    n_policy_billgroup_id_r
                                FROM
                                    (
                                        SELECT
                                            n_policy_sk_r,
                                            n_policy_billgroup_id_r,
                                            RANK()
                                            OVER(PARTITION BY n_policy_sk_r
                                                 ORDER BY
                                                     d_insert_date_r ASC, n_policy_billgroup_id_r ASC
                                            ) rnk
                                        FROM
                                            dim_grp_statement_detail_r
                                        WHERE
                                                v_active_status_r = 'Y'
                                            AND n_policy_billgroup_id_r IS NOT NULL
                                    )
                                WHERE
                                    rnk = 1
                            ) sd ON a.n_policy_sk_r = sd.n_policy_sk_r 
							--left join (select * from dim_grp_statement_detail_r where V_ACTIVE_STATUS_R = 'Y') sd
							--on a.N_POLICY_SK_R = sd.N_POLICY_SK_R and a.N_STATEMENT_ID_R=sd.N_STATEMENT_ID_R                          
                        WHERE
                            a.n_do_not_pay_r IN ( 17, 23, 25, 27 )
                        UNION
                        SELECT
                            p.v_policy_number_r                                           AS v_policy_number_r,
							--'' AS V_CUSTOMER_BILL_GROUP_NUMBER_R,
                            tab3.v_agent_number_r                                         AS v_agent_code_r,
                            ''                                                            AS v_template_name_r,
                            tab5.d_insert_date_r                                          d_commission_date_r,
							--TAB5.D_TRANSACTION_DATE_R,--07-10-24-5500
                            tab5.d_prev_paid_to_date_r                                    AS d_due_date_r,
                            CAST('' AS DATE)                                              AS d_paid_to_date_r,
                            ''                                                            v_agent_license_r,
                            'CA'                                                          AS v_commission_type_r,
                            tab5.n_commission_r                                           AS n_commission_amount_r,
                            (
                                CASE
                                    WHEN tab5.n_do_not_pay_r = 0  THEN
                                        'Open'
                                    WHEN tab5.n_do_not_pay_r = 1  THEN
                                        'Paid'
                                    WHEN tab5.n_do_not_pay_r IN ( 2, 3, 9, 12, 51,
                                                                  59, 99, 61 ) THEN
                                        'Pending'
                                    WHEN tab5.n_do_not_pay_r = 7  THEN
                                        'Terminated and not vested'
                                    WHEN tab5.n_do_not_pay_r = 52 THEN
                                        'No check/Non-monetary bonus'
                                    WHEN tab5.n_do_not_pay_r IN ( 17, 25, 18, 23 ) ----Added the DONOTAY CODE = 25 as void. Added the DONOTAY CODE = 25 as void.
                                     THEN
                                        'Void and Close Liability'
                                    WHEN tab5.n_do_not_pay_r IN ( 30 ) -- add 30
                                     THEN
                                        'Void and Replace'
                                    WHEN tab5.n_do_not_pay_r IN ( 35, 36, 37, 38 ) THEN
                                        'Void and Open Liability'
                                    WHEN tab5.n_do_not_pay_r = 29 THEN
                                        'Paid'
                                    ELSE
                                        'Other'
                                END
                            )                                                             AS v_commission_status_r,
                            tab5.n_statement_detail_id_r                                  AS id,
                            nvl(tab5.n_policy_billgroup_id_r, sd.n_policy_billgroup_id_r) AS n_policy_billgroup_id_r,
                            tab3.n_agent_sk_r                                             AS n_agent_sk_r,
                            tab5.v_source_system_name_r                                   AS v_data_source_name_r --<Project Crown Changes 05-06-2026>
                        FROM
                                 (
                                SELECT
                                    *
                                FROM
                                    dim_grp_statement_detail_r
                                WHERE
                                        v_active_status_r = 'Y'
                                    AND n_which_payment_r = 2
                                    AND n_do_not_pay_r = 1
                            ) tab5
                            INNER JOIN (
                                SELECT
                                    *
                                FROM
                                    dim_grp_statement_r
                                WHERE
                                        v_active_status_r = 'Y'
                                    AND n_entity_type_id_r = 500
                            ) s ON tab5.n_statement_id_r = s.n_statement_id_r 
                                and tab5.v_source_system_name_r = s.v_source_system_name_r
                            INNER JOIN (
                                SELECT
                                    *
                                FROM
                                    dim_grp_agent_r
                                WHERE
                                    v_active_status_r = 'Y'
                            ) tab3 ON s.n_entity_id_r = tab3.v_agent_id_r
                                      AND s.n_entity_type_id_r = 500
                            INNER JOIN (
                                SELECT
                                    *
                                FROM
                                    dim_grp_policy_dir_r
                                WHERE
                                    v_active_status_r = 'Y'
                            ) p ON tab5.n_policy_sk_r = p.n_policy_sk_r
                            LEFT JOIN (
                                SELECT DISTINCT
                                    n_policy_sk_r,
                                    n_policy_billgroup_id_r
                                FROM
                                    (
                                        SELECT
                                            n_policy_sk_r,
                                            n_policy_billgroup_id_r,
                                            RANK()
                                            OVER(PARTITION BY n_policy_sk_r
                                                 ORDER BY
                                                     d_insert_date_r ASC, n_policy_billgroup_id_r ASC
                                            ) rnk
                                        FROM
                                            dim_grp_statement_detail_r
                                        WHERE
                                                v_active_status_r = 'Y'
                                            AND n_policy_billgroup_id_r IS NOT NULL
                                    )
                                WHERE
                                    rnk = 1
                            ) sd ON tab5.n_policy_sk_r = sd.n_policy_sk_r
                    )                final_tab
                    LEFT OUTER JOIN (
                        SELECT
                            v_policy_number_r,
                            n_policy_sk_r,
                            n_policy_version_number_r,
                            n_source_system_key_r,
                            v_source_system_name_r,
                            v_orig_policy_number_r
                        FROM
                            dim_grp_policy_dir_r
                        WHERE
                            v_active_status_r = 'Y'
                        GROUP BY
                            v_policy_number_r,
                            n_policy_sk_r,
                            n_policy_version_number_r,
                            n_source_system_key_r,
                            v_source_system_name_r,
                            v_orig_policy_number_r
                    )                tab_policy_sk ON final_tab.v_policy_number_r = tab_policy_sk.v_policy_number_r
                    LEFT JOIN fct_grp_policy_r f ON tab_policy_sk.n_policy_sk_r = f.n_policy_sk_r
                                                    AND tab_policy_sk.n_policy_version_number_r = f.n_version_number_r
                                                    AND tab_policy_sk.n_source_system_key_r = f.n_source_system_key_r
                    LEFT JOIN (
                        SELECT
                            *
                        FROM
                            dim_grp_billing_pol_billgrp_r
                        WHERE
                                v_active_status_r = 'Y'
                            AND v_source_system_name_r in ('APS','MGIS','DDAZ')
                    )                b ON tab_policy_sk.v_policy_number_r = b.v_policy_id_r
                           AND final_tab.n_policy_billgroup_id_r = b.n_policy_billgroup_id_r
                    LEFT JOIN (
                        SELECT
                            *
                        FROM
                            dim_grp_billing_pol_billgrp_r
                        WHERE
                                v_active_status_r = 'Y'
                            AND v_source_system_name_r in ('APS','MGIS','DDAZ')
                    )                d ON final_tab.n_policy_billgroup_id_r = d.n_policy_billgroup_id_r
                           AND tab_policy_sk.v_orig_policy_number_r = d.v_policy_id_r
                    LEFT JOIN (
                        SELECT
                            *
                        FROM
                            dim_grp_customer_bill_group_r
                        WHERE
                                v_active_status_r = 'Y'
                            AND v_source_system_name_r in ('APS','MGIS','DDAZ')
                    )                c ON nvl(b.n_customer_billgroup_id_r, d.n_customer_billgroup_id_r) = c.n_customer_billgroup_id_r;

        EXCEPTION
            WHEN OTHERS THEN
                lc_sqlcode := sqlcode;
                lc_sqlerrm := substr(sqlerrm, 1, 4000);
                out_load_status := '1)Error occured while loading data into FCT_AGENT_COMMISSION_SUMMARY:-'
                                   || lc_sqlcode
                                   || '-'
                                   || lc_sqlerrm;
                ROLLBACK TO SAVEPOINT sp1;
                gc_trc_msg := '1)Error occured while loading data into FCT_AGENT_COMMISSION_SUMMARY:-'
                              || lc_sqlcode
                              || '-'
                              || lc_sqlerrm;
                IF gc_debug_flag = 'Y' THEN
                    gc_trc_msg := gc_trc_msg
                                  || 'Final Exception Error:->'
                                  || substr(sqlerrm, 1, 4000);
                    gc_trcmsg := '4. Error occured while loading data into FCT_AGENT_COMMISSION_SUMMARY';
                    /*START: NEW LOGGING MECHANISM CHANGES*/       
					PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
							(
							p_job_id_r                     => gn_out_job_id                                           
							,p_batch_id_r                  => gn_sysdt_batchid                                    
							,p_message_type_r              => gc_message_type_r                                    
							,p_code_location_r             => gc_main_loadedby                                 
							,p_message_r                   => gc_trcmsg                                                                 
							,p_count_type_r                => NULL                                                                          
							,p_count_r                     => NULL                                                                                     
							,p_duration_r                  => NULL                                                                                     
							,p_created_by_r                => gc_job_name                                                       
							,out_prcs_job_log_message_id_r => gn_job_log_message_id_r                       
							);            
					/*END: NEW LOGGING MECHANISM CHANGES*/

                    INSERT INTO prcs_grp_tbl_load_debug_trc (
                        v_job_name_r,
                        v_pkg_prc_name_r,
                        n_sk_r,
                        v_number_r,
                        v_trc_msg_r,
                        n_batch_id_r,
                        v_created_by_r,
                        v_last_modified_by_r
                    ) VALUES (
                        'GRP_LOAD_FCT_AGENT_COMMISSION_SUMMARY' --<Chagne to corresponding reporting table after GRP_LOAD_)
                        ,
                        'PKG_GRP_LOAD_FCT_AGENT_COMMISSION_SUMMARY.PRC_GRP_LOAD_FCT_AGENT_COMMISSION_SUMMARY'--<Change package and procedure name corresponding ro reporting fact>
                        ,
                        NULL,
                        NULL,
                        gc_trc_msg,
                        ln_n_batch_id_r,
                        'ODI',
                        'ODI'
                    );

                    COMMIT;
                END IF;

                raise_application_error(-20001, '1) issue while inserting data into EOI History fact :-'
                                                || lc_sqlcode
                                                || '-'
                                                || lc_sqlerrm);
        END;

        gc_trcmsg := '5. Issue while inserting data into EOI History fact';
		/*START: NEW LOGGING MECHANISM CHANGES*/       
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
				(
				p_job_id_r                     => gn_out_job_id                                           
				,p_batch_id_r                  => gn_sysdt_batchid                                    
				,p_message_type_r              => gc_message_type_r                                    
				,p_code_location_r             => gc_main_loadedby                                 
				,p_message_r                   => gc_trcmsg                                                                 
				,p_count_type_r                => NULL                                                                          
				,p_count_r                     => NULL                                                                                     
				,p_duration_r                  => NULL                                                                                     
				,p_created_by_r                => gc_job_name                                                       
				,out_prcs_job_log_message_id_r => gn_job_log_message_id_r                       
				);            
		/*END: NEW LOGGING MECHANISM CHANGES*/

        COMMIT;
        out_load_status := 'SUCCESS';
        gc_trcmsg := '6. OUT_LOAD_STATUS=SUCCESS';
		/*START: NEW LOGGING MECHANISM CHANGES*/       
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
				(
				p_job_id_r                     => gn_out_job_id                                           
				,p_batch_id_r                  => gn_sysdt_batchid                                    
				,p_message_type_r              => gc_message_type_r                                    
				,p_code_location_r             => gc_main_loadedby                                 
				,p_message_r                   => gc_trcmsg                                                                 
				,p_count_type_r                => NULL                                                                          
				,p_count_r                     => NULL                                                                                     
				,p_duration_r                  => NULL                                                                                     
				,p_created_by_r                => gc_job_name                                                       
				,out_prcs_job_log_message_id_r => gn_job_log_message_id_r                       
				);            
		/*END: NEW LOGGING MECHANISM CHANGES*/

    EXCEPTION
        WHEN OTHERS THEN
            lc_sqlcode := sqlcode;
            lc_sqlerrm := substr(sqlerrm, 1, 4000);
            out_load_status := lc_sqlcode
                               || '-'
                               || lc_sqlerrm;
            gc_trc_msg := 'Final Error Message:->'
                          || lc_sqlcode
                          || '-'
                          || lc_sqlerrm;
            IF gc_debug_flag = 'Y' THEN
                INSERT INTO prcs_grp_tbl_load_debug_trc (
                    v_job_name_r,
                    v_pkg_prc_name_r,
                    n_sk_r,
                    v_number_r,
                    v_trc_msg_r,
                    n_batch_id_r,
                    v_created_by_r,
                    v_last_modified_by_r
                ) VALUES (
                    'GRP_LOAD_FCT_AGENT_COMMISSION_SUMMARY' --<Chagne to corresponding reporting table after GRP_LOAD_)
                    ,
                    'PKG_GRP_LOAD_FCT_AGENT_COMMISSION_SUMMARY.PRC_GRP_LOAD_FCT_AGENT_COMMISSION_SUMMARY'--<Change package and procedure name corresponding ro reporting fact>
                    ,
                    NULL,
                    NULL,
                    gc_trc_msg,
                    ln_n_batch_id_r,
                    'ODI',
                    'ODI'
                );

                COMMIT;
            END IF;

    END prc_grp_load_fct_agent_commission_summary;

END pkg_grp_load_fct_agent_commission_summary;

/

  GRANT EXECUTE ON "ATOMIC"."PKG_GRP_LOAD_FCT_AGENT_COMMISSION_SUMMARY" TO "ATOMIC_ALL_RW";
  GRANT DEBUG ON "ATOMIC"."PKG_GRP_LOAD_FCT_AGENT_COMMISSION_SUMMARY" TO "ATOMIC_ALL_RW";
  GRANT EXECUTE ON "ATOMIC"."PKG_GRP_LOAD_FCT_AGENT_COMMISSION_SUMMARY" TO "ODI_WORK_SCHEMA";
  GRANT DEBUG ON "ATOMIC"."PKG_GRP_LOAD_FCT_AGENT_COMMISSION_SUMMARY" TO "ODI_WORK_SCHEMA";
  GRANT EXECUTE ON "ATOMIC"."PKG_GRP_LOAD_FCT_AGENT_COMMISSION_SUMMARY" TO "EXT_EIS_RO";
  GRANT EXECUTE ON "ATOMIC"."PKG_GRP_LOAD_FCT_AGENT_COMMISSION_SUMMARY" TO "ATOMIC_ALL_RO";
  GRANT EXECUTE ON "ATOMIC"."PKG_GRP_LOAD_FCT_AGENT_COMMISSION_SUMMARY" TO "EXT_DIGITAL_RO";
  GRANT DEBUG ON "ATOMIC"."PKG_GRP_LOAD_FCT_AGENT_COMMISSION_SUMMARY" TO "ATOMIC_DEBUG";
