--------------------------------------------------------
--  DDL for Package Body PKG_GRP_LOAD_RPT_BILLGROUP_R
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ATOMIC"."PKG_GRP_LOAD_RPT_BILLGROUP_R" IS
  /***********************************************************************
  Purpose:  This package body contains procedures which loads data into RPT_BILLGROUP_R
  Dependent SSL tables : RPT_BILLGROUP_R
  Used DB Objects:DIM_GRP_BILLING_POL_BILLGRP_R
  DIM_GRP_CUSTOMER_BILL_GROUP_R
  FCT_GRP_BILLING_POLICY_DTL_R
  DIM_GRP_ADDRESS_DIR_R
  fct_grp_policy_r_pbc_team_lookup
  Author     Date     Description
  ---------- -------- -------------------------------------------------
  VGireesh   10/11/23 Initial Creation
  VGireesh   22/02/24 Enabled rebuilding indexes
  VGireesh   26/02/24 for month end  that the tables start loading data in the next month partition
  Ex: March data on February 29th (as of 2.28).
  27th is Feb Fisc Month End    202402  should be truncate and load in 202402 partition
  28th is feb Fisc Month End +1 202402  should be truncate and load in 202402 partition
  29th is Feb Fisc Month End +2 202403  should inactive records against the partition 202402 and load data in 202403 partition
  VGireesh   03/04/24 Added Parallel to rebuild index fast
  Chandra    21/06/24 Added V_PBC_TEAM_NAME_Rs
                            V_PBC_SUB_TEAM_R
  Chandra    01/07/24 Mapping added for V_PBC_TEAM_NAME_R,V_PBC_SUB_TEAM_R
  Chandra    02/08/24 Added filter SELECT * FROM DIM_GRP_BILLING_POL_BILLGRP_R WHERE V_SOURCE_SYSTEM_NAME_R = 'VUE'
  Chandra    03/08/24 Added filter select * from DIM_GRP_CUSTOMER_BILL_GROUP_R WHERE V_SOURCE_SYSTEM_NAME_R = 'VUE' and v_active_status_r = 'Y'
  Gireesh    21/10/24 1.	In the join to address directory, update to use customer bill group instead and filter on VUE source
                      LEFT JOIN DIM_GRP_ADDRESS_DIR_R
                      ON DIM_GRP_CUSTOMER_BILL_GROUP_R.N_ADDRESS_SK_R = DIM_GRP_ADDRESS_DIR_R.N_ADDRESS_SK_R
                      AND DIM_GRP_ADDRESS_DIR_R.D_DELETE_DATE_R      IS NULL
                      And DIM_GRP_ADDRESS_DIR_R.v_source_system_name_r = ‘VUE’
                      AND DIM_GRP_ADDRESS_DIR_R.N_ADDRESS_SK_R NOT   IN

                      2.	V_BILLGROUP_CITY_R, V_BILLGROUP_STATE_R, V_BILLGROUP_POSTAL_ZIP_R already exist. Need to add the below fields to RPT_BILLGROUP_R
                      a.	V_ADDRESSLINE1_R as V_BILLGROUP_ADDRESSLINE1_R
                      b.	V_ADDRESSLINE2_R AS V_BILLGROUP_ADDRESSLINE2_R
                      c.	V_ADDRESSLINE3_R AS V_BILLGROUP_ADDRESSLINE3_R
  Suresh     20/02/25 Added Column V_SOURCE_SYSTEM_NAME_R 
  Shreeja 05/03/2025 Added MGIS filter   
  Samba		18/02/26  Capturing the Target count for Audit COntrols when data is inserting into RPT table using Bulkload limit.
  Rose		13/03/26  Commenting prc_upd_del_data and adding PKG_GRP_COMMON_UTIL.
  Samba		12/05/26   Kill/Fill Changes: User Story - 514606
					 	- All code changes are marked with Kill/Fill start and end comment blocks.
					 	- Code changes ensure continuous data availability in reports, replacing the current truncate-and-load approach, which is not partition-exchange based.	
					 	- Retaining old code base of bulk collect load; which can be used when this Package to be converted to incremental processing

  Kavinissha  23/05/2026  Added Not in filters to include TPA Source systems User Story: 461423

  Kavinissha   27/07/2026  Indentation fixes User Story : 461423
  ***********************************************************************/
--Global Constants
    gc_rpt_table_name     VARCHAR2(50) := 'RPT_BILLGROUP_R';
    gd_fic_mis_date       DATE;
    gc_rebuild_idx_degree PLS_INTEGER := 8;
	gd_sysdate DATE := trunc(sysdate);
    gn_prior_month NUMBER := to_number(to_char(add_months(trunc(gd_sysdate, 'MM'), -1), 'YYYYMM'));
    gn_current_month NUMBER := to_number(to_char(gd_sysdate, 'YYYYMM'));
    gn_sysdt_batchid NUMBER := to_number(to_char(gd_sysdate, 'YYYYMMDD'));
    gc_main_loadedby VARCHAR2(100 CHAR) := 'PKG_GRP_LOAD_RPT_BILLGROUP_R.MAIN';
    gc_updby VARCHAR2(100 CHAR) := 'PKG_GRP_LOAD_RPT_BILLGROUP_R.PRC_UPD_DEL_DATA';
    gc_getcur_loadedby VARCHAR2(100 CHAR) := 'PKG_GRP_LOAD_RPT_BILLGROUP_R.PRC_GET_CUR_DATA';
    gc_truncpartby VARCHAR2(100 CHAR) := 'PKG_GRP_LOAD_RPT_BILLGROUP_R.PRC_TRUNC_PARTITION';
    gc_rebuildindexes VARCHAR2(100 CHAR) := 'PKG_GRP_LOAD_RPT_BILLGROUP_R.PRC_REBUILD_INDEXES';
    gc_trcmsg CLOB := 'Trace Message:->';
    gc_job_name VARCHAR2(50 CHAR) := 'GRP_LOAD_RPT_BILLGROUP_R';
    gn_bulk_coll_cnt NUMBER := 10000;
    gc_running_status VARCHAR2(30) := 'Running';
    gc_error_status VARCHAR2(30) := 'Error';
    gc_success_status VARCHAR2(30) := 'Success';
    gc_source VARCHAR2(30) := 'EDW';
    gc_target VARCHAR2(30) := 'RPT';
    gc_main_entity VARCHAR2(30) := 'BILLGROUP';
    gc_message_type_r VARCHAR2(30) := 'Info';
    gn_job_log_message_id_r NUMBER;
--Global Variables
    gn_out_job_id NUMBER;
    gc_errmsg VARCHAR2(4000 CHAR);

--Start: kill/fill additions
    gv_rpt_table_name     CONSTANT prcs_job_log_r.v_job_name_r%TYPE := 'RPT_BILLGROUP_R';
    gv_exg_table_name     CONSTANT prcs_job_log_r.v_job_name_r%TYPE := gv_rpt_table_name || '_EXG';
    gv_schema_owner       CONSTANT prcs_job_log_r.v_job_name_r%TYPE := 'ATOMIC';
    gt_start_time         TIMESTAMP;
    gt_end_time           TIMESTAMP;
    gn_run_cnt            NUMBER;
--End: kill/fill additions
--Procedure declaration for ref cursor assignment
    PROCEDURE prc_get_cur_data;
		--(p_out_cursor OUT SYS_REFCURSOR); -- commented as part of Kill Fill process 12 may'26
--Procedure declaration for updating prior month active flag and current month partition in the table RPT_BILLGROUP_R
    PROCEDURE prc_upd_del_data;
--Procedure declaration for truncating the YEARMONTH partition in the table RPT_BILLGROUP_R
    PROCEDURE prc_trunc_partition;
--Procedure to rebuild indexes RPT_BILLGROUP_R
    PROCEDURE prc_rebuild_indexes;


    PROCEDURE prc_upd_del_data IS
/***********************************************************************
    Purpose:  Procedure to update prior month active flag and current month partition

    Author     Date     Description
  ---------- -------- -------------------------------------------------
    VGireesh   10/11/23 Initial Creation
*******************************************************************************/
        ln_sqlrowcnt          NUMBER;
        ln_cnt                NUMBER;
        ld_first_day_date     DATE;
       --26-Feb-2024 changes starts
        ln_fisc_current_month NUMBER;
        ln_fisc_prior_month   NUMBER;
        ld_fic_mis_date_2     DATE;
        --26-Feb-2024 changes ends
    BEGIN
        gc_trcmsg := gc_trcmsg
                     || '3.1 Entered into in prc_upd_del_data'
                     || chr(13);

        SELECT --D_CALENDAR_DATE_R,D_CALENDAR_DATE_R +1
            d_calendar_date_r + 2,
            to_number(to_char(last_day(sysdate) + 1, 'YYYYMM'))
        INTO
            ld_fic_mis_date_2,
            ln_fisc_current_month
        FROM
            dim_time_r d
        WHERE
                v_end_of_fiscal_month_ind_r = 'Y'
            AND to_char(d_calendar_date_r, 'YYYYMM') = to_char(sysdate, 'YYYYMM');

        gc_trcmsg := gc_trcmsg
                     || '3.2 Fisc Month End +2 Day Date of the current month is:->'
                     || ld_fic_mis_date_2
                     || chr(13);
        gc_trcmsg := gc_trcmsg
                     || '3.3 Fisc Current Month of the current month is:->'
                     || ln_fisc_current_month
                     || chr(13);
        IF trunc(ld_fic_mis_date_2) = trunc(sysdate) THEN
            ln_fisc_prior_month := to_number(to_char(ld_fic_mis_date_2, 'YYYYMM'));
            gc_trcmsg := gc_trcmsg
                         || '3.3.1 Fisc Prior Month of the current month is:->'
                         || ln_fisc_prior_month
                         || chr(13);
            gc_trcmsg := gc_trcmsg
                         || '3.4 Today Fisc Month End +2 '
                         || ld_fic_mis_date_2
                         || ' hence Updating v_rpt_active_status_r=N against the records loaded in prior fisc month which is :->'
                         || ln_fisc_prior_month
                         || chr(13);

            UPDATE rpt_billgroup_r
            SET
                v_rpt_active_status_r = 'N',
                v_last_modified_by_r = gc_updby,
                t_last_modified_date_r = gd_sysdate
            WHERE
                n_reportmonth_r = ln_fisc_prior_month;

            ln_sqlrowcnt := SQL%rowcount;
            COMMIT;
            gc_trcmsg := gc_trcmsg
                         || '3.5  Updated v_rpt_active_status_r=N against the records loaded in Fisc prior month :->'
                         || ln_fisc_prior_month
                         || ' records '
                         || ln_sqlrowcnt
                         || chr(13);

            gc_trcmsg := gc_trcmsg || '3.6 Set gn_current_month to  ln_fisc_current_month ';
            gn_current_month := ln_fisc_current_month;
            gc_trcmsg := gc_trcmsg
                         || '3.7 now current month is :->'
                         || gn_current_month;
        ELSE
    --If Sysdate is greater than to Fisc Month End +2 and less than last day of the present month then Current Month is next fisc month
	--Ex: if sysdate is  28-MAR-24 which is also Fisc Month end +2 and leass than current month end date 31-MAR-24 then current month 202403 becomes next fisc month which is 202404
	--partition 202404 should be truncated and reloaded
            IF
                trunc(sysdate) > trunc(ld_fic_mis_date_2)
                AND trunc(sysdate) <= trunc(last_day(sysdate))
            THEN
                gc_trcmsg := gc_trcmsg || '3.8 Set gn_current_month to  ln_fisc_current_month ';
                gn_current_month := ln_fisc_current_month;
                gc_trcmsg := gc_trcmsg
                             || '3.9 now current month is :->'
                             || gn_current_month;
            ELSE
                gc_trcmsg := gc_trcmsg
                             || '3.9.1 now current month is :->'
                             || gn_current_month;
            END IF;
	--Since sysdate is not fisc month end +2 hence data loaded in Current Month needs to be deleted but prior months data should not be touched
            gc_trcmsg := gc_trcmsg
                         || '3.10 Today is not fisc month end +2 of the current month hence Calling procedure prc_trunc_partition to truncate current month partition from main'
                         || chr(13);
            prc_trunc_partition;
            gc_trcmsg := gc_trcmsg
                         || '3.11 Completed procedure prc_trunc_partition call from main'
                         || chr(13);
        END IF;
  --26-Feb-2024 changes ends
        gc_trcmsg := gc_trcmsg
                     || '3.12 Exit from in prc_upd_del_data'
                     || chr(13);
    EXCEPTION
        WHEN OTHERS THEN
            gc_errmsg := substr(sqlerrm, 1, 4000);
            gc_trcmsg := gc_trcmsg
                         || '3.z Error in prc_upd_del_data'
                         || chr(13)
                         || gc_errmsg;
            pkg_grp_log_util.prc_update_log(gn_out_job_id --p_job_id
            , gc_error_status                                --p_job_status
            , gc_errmsg                                      --p_err_msg
            , gc_trcmsg
                                                                                       || chr(13)
                                                                                       || gc_errmsg                  --p_trc_msg
                                                                                       , gc_updby                                       --p_log_util_called_by_r
                                                                                       );

            RAISE;
    END prc_upd_del_data;

    PROCEDURE prc_trunc_partition AS
/***********************************************************************
    Purpose:  Procedure to truncate the YEARMONTH partition


    Author     Date     Description
  ---------- -------- -------------------------------------------------
    VGireesh   10/11/23 Initial Creation
*******************************************************************************/

        lc_tbl           VARCHAR2(30) := 'RPT_BILLGROUP_R';
        lc_rebuild_index VARCHAR2(300);
    BEGIN
        gc_trcmsg := gc_trcmsg
                     || '3.7.1 Entered into prc_trunc_partition :->'
                     || 'ALTER TABLE '
                     || lc_tbl
                     || ' TRUNCATE PARTITION '
                     || 'PART_'
                     || lc_tbl
                     || '_'
                     || gn_current_month
                     || chr(13);

        EXECUTE IMMEDIATE 'ALTER TABLE '
                          || lc_tbl
                          || ' TRUNCATE PARTITION '
                          || 'PART_'
                          || lc_tbl
                          || '_'
                          || gn_current_month;

        gc_trcmsg := gc_trcmsg
                     || '3.7.2 Truncate partition completed'
                     || chr(13);
        gc_trcmsg := gc_trcmsg
                     || '3.7.3 Rebuild PK Index starts'
                     || chr(13);
        FOR i IN (
            SELECT
                'ALTER INDEX '
                || index_name
                || ' REBUILD parallel 16 nologging' rebuild_index
            FROM
                all_indexes
            WHERE
                    table_name = 'RPT_BILLGROUP_R'
                AND index_name LIKE 'PK_%'
                AND status = 'UNUSABLE'
        ) LOOP
            lc_rebuild_index := i.rebuild_index;
            EXECUTE IMMEDIATE lc_rebuild_index;
        END LOOP;

        gc_trcmsg := gc_trcmsg
                     || '3.7.z Exit from prc_trunc_partition'
                     || chr(13);
    EXCEPTION
        WHEN OTHERS THEN
            gc_errmsg := substr(sqlerrm, 1, 4000);
            gc_trcmsg := gc_trcmsg
                         || '2.z Error in prc_trunc_partition'
                         || chr(13);
            pkg_grp_log_util.prc_update_log(gn_out_job_id    --p_job_id
            , gc_error_status                                --p_job_status
            , gc_errmsg                                      --p_err_msg
            , gc_trcmsg   || chr(13)   || gc_errmsg          --p_trc_msg        
            , gc_truncpartby                                 --p_log_util_called_by_r                                                                          
             );                                                                          

            RAISE;
    END prc_trunc_partition;

    PROCEDURE main IS
	/***********************************************************************
    Purpose:  Main procedure call to load data in RPT_BILLGROUP_R

    Author     Date     Description
  ---------- -------- -------------------------------------------------
   VGireesh   10/11/23 Initial Creation
*******************************************************************************/

  --Start: Commenting for kill/fill 
  /* VAR_REF_CUR SYS_REFCURSOR;  
	TYPE var_tbl_type*/
	--IS

  /*TABLE OF RPT_BILLGROUP_R%ROWTYPE INDEX BY BINARY_INTEGER;
  lt_var_tbl_typ var_tbl_type;*/
  --End: Commenting for kill/fill 

        ln_rec_cnt            NUMBER := 0;
        ln_start_time         NUMBER;
        lc_trcmsg             VARCHAR(150);
        ld_fic_mis_date_2     DATE;
        ln_fisc_current_month NUMBER;
    BEGIN
  --Call Log Util pkg to Insert entry in PRCS_JOB_LOG_R
        pkg_grp_log_util.prc_insert_log
			(
				p_source               => gc_source,
				p_job_nm               => gc_job_name,
				p_job_status           => gc_running_status,
				p_err_msg              => NULL,
				p_trc_msg              => NULL,
				p_n_batch_id           => gn_sysdt_batchid,
				p_log_util_called_by_r => gc_main_loadedby,
				out_job_id             => gn_out_job_id
			);

        gc_trcmsg := gc_trcmsg
                     || '1. Entered into main'
                     || chr(13);
        gc_trcmsg := gc_trcmsg
                     || 'gn_current_month     :->'
                     || gn_current_month
                     || chr(13);
        gc_trcmsg := gc_trcmsg
                     || 'gn_prior_month       :->'
                     || gn_prior_month
                     || chr(13);

	/*Common Utility Proc to get month end+2 date and month. Ex: If month end is 29-Aug-2025 then ln_fisc_current_month will be 202509*/
        pkg_grp_common_util.prc_fisc_month_calc
			(
				p_out_job_id          => gn_out_job_id,
				p_log_seq_num         => 2,
				ld_fic_mis_date_2     => ld_fic_mis_date_2,
				ln_fisc_current_month => ln_fisc_current_month
			);

        gd_fic_mis_date := ld_fic_mis_date_2;--29-Aug-2024 changes

		/*Common Utility Proc to determine current and prior month ; Checks for month end logic and daily load logic as well */
        pkg_grp_common_util.prc_get_current_prior_month
			(
				p_out_job_id          => gn_out_job_id,
				p_log_seq_num         => 3,
				p_fic_mis_date        => ld_fic_mis_date_2,
				p_fisc_current_month  => ln_fisc_current_month,
				p_current_month       => gn_current_month,
				p_prior_month         => gn_prior_month
			);		

	-- Start : Kill/Fill Changes 12th May 2026 	: Added New 
        pkg_grp_common_util.prc_create_exchange_table_ddl
			(
				p_job_id          => gn_out_job_id,
				p_log_seq_num     => 4,
				p_main_table_name => gv_rpt_table_name,
				p_exg_table_name  => gv_exg_table_name,
				p_schema_name     => gv_schema_owner
			);

        pkg_grp_load_rpt_billgroup_r.prc_get_cur_data;

	--Start: Commenting for kill/fill 
	/*PKG_GRP_COMMON_UTIL.prc_trunc_partition 
		(
			p_out_job_id    	=>	gn_out_job_id,
			p_Log_seq_num   	=>	4,
			p_rpt_table     	=>	gc_rpt_table_name,  
			p_idx_num       	=>	gc_rebuild_idx_degree,
			p_current_month     =>	gn_current_month
		);  

  gc_trcmsg:=gc_trcmsg||'4. Call prc_get_cur_data to get ref_cursor '||chr(13);
  PKG_GRP_LOAD_RPT_BILLGROUP_R.prc_get_cur_data (var_ref_cur);
  gc_trcmsg    :=gc_trcmsg||'4.z Completed Call Procedure prc_get_cur_data to get ref_cursor'||chr(13);
  ln_start_time:=dbms_utility.get_time;
  gc_trcmsg    :=gc_trcmsg||'5 data load starts '||ln_start_time||chr(13);
  ln_rec_cnt   :=0;
  LOOP
    lt_var_tbl_typ.DELETE;
    FETCH var_ref_cur BULK COLLECT INTO lt_var_tbl_typ LIMIT gn_bulk_coll_cnt;
    FORALL X IN LT_VAR_TBL_TYP.first..LT_VAR_TBL_TYP.last
    INSERT /*+APPEND_VALUES*/
    /*INTO RPT_BILLGROUP_R VALUES lt_var_tbl_typ
      (x
      ) ;
    LN_REC_CNT:=LN_REC_CNT+LT_VAR_TBL_TYP.COUNT;
    COMMIT;
    EXIT
  WHEN var_ref_cur%NOTFOUND;
  END LOOP;*/
  --End: Commenting for kill/fill 

  --gc_trcmsg:=gc_trcmsg||'5.z Data Loaded '||ln_rec_cnt||' records '||((dbms_utility.get_time - ln_start_time)/100)||chr(13);

	-- Start : Kill/Fill Changes 12th May 2026 	: Added New 
	-- Partition Exchange Common Utility Called to Move data from Exg table to the Main table Current month Partition
        pkg_grp_common_util.prc_partition_exchange(
                   p_job_id          => gn_out_job_id,
                   p_log_seq_num     => 6,
                   p_main_table_name => gv_rpt_table_name,
                   p_exg_table_name  => gv_exg_table_name,
                   p_partition_name  => 'PART_' || gv_rpt_table_name || '_' || gn_current_month,
                   p_schema_name     => gv_schema_owner
);

  --22-Feb-2024 changes starts
        ln_start_time := dbms_utility.get_time;
        gc_trcmsg := gc_trcmsg
                     || '7. Call procedure unusable prc_rebuild_indexes from main '
                     || ln_start_time
                     || chr(13);
        pkg_grp_load_rpt_billgroup_r.prc_rebuild_indexes;
        gc_trcmsg := gc_trcmsg
                     || '7.z Completed Procedure unusable prc_rebuild_indexes call from main '
                     || ( ( dbms_utility.get_time - ln_start_time ) / 100 )
                     || chr(13);
  --22-Feb-2024 changes ends
        ln_start_time := dbms_utility.get_time;
        gc_trcmsg := gc_trcmsg
                     || '8. Gather RPT_BILLGROUP_R table stats from main '
                     || ln_start_time
                     || chr(13);
        dbms_stats.gather_table_stats('ATOMIC', 'RPT_BILLGROUP_R');
        gc_trcmsg := gc_trcmsg
                     || '8.z Completed Gather RPT_BILLGROUP_R table stats from main '
                     || ( ( dbms_utility.get_time - ln_start_time ) / 100 )
                     || chr(13);

        lc_trcmsg := '5. Calling Audit Control Procedure';
        pkg_grp_log_util.prc_ins_prcs_job_log_message_r
				(
					p_job_id_r                    => gn_out_job_id,
					p_batch_id_r                  => gn_sysdt_batchid,
					p_message_type_r              => gc_message_type_r,
					p_code_location_r             => gc_main_loadedby,
					p_message_r                   => lc_trcmsg,
					p_count_type_r                => 'Control Procedure',
					p_count_r                     => NULL,
					p_duration_r                  => NULL,
					p_created_by_r                => gc_job_name,
					out_prcs_job_log_message_id_r => gn_job_log_message_id_r
				);

        prc_grp_audit_control_process(gc_source, gc_main_entity, gc_source, gc_target);
        gc_trcmsg := gc_trcmsg
                     || '1.z Exit from main'
                     || chr(13);
        pkg_grp_log_util.prc_update_log(gn_out_job_id --p_job_id
        , gc_success_status                              --p_job_status
        , gc_errmsg                                      --p_err_msg
        , gc_trcmsg                                      --p_trc_msg
        , gc_main_loadedby                               --p_log_util_called_by_r
        );
    EXCEPTION
        WHEN OTHERS THEN
            gc_errmsg := substr(sqlerrm, 1, 4000);
            gc_trcmsg := gc_trcmsg
                         || '1. Error in main'
                         || chr(13);
            pkg_grp_log_util.prc_update_log(gn_out_job_id --p_job_id
            , gc_error_status                             --p_job_status
            , gc_errmsg                                   --p_err_msg
            , gc_trcmsg || chr(13) || gc_errmsg           --p_trc_msg     
            , gc_main_loadedby                            --p_log_util_called_by_r                                                                           
            );                                                                                            

            RAISE;
    END main;

    PROCEDURE prc_get_cur_data

/***********************************************************************
    Purpose:  Procedure to perform ref cursor assignment

    Author     Date     Description
  ---------- -------- -------------------------------------------------
    VGireesh   10/11/23 Initial Creation
*******************************************************************************/

  ---( p_out_cursor OUT SYS_REFCURSOR ) --Commenting for kill/fill 
     AS
    BEGIN
        gc_trcmsg := '5.1 - Entered into prc_get_cur_data ';
        gt_start_time := systimestamp;

	/*NEW LOGGING MECHANISM CHANGES*/
        pkg_grp_log_util.prc_ins_prcs_job_log_message_r
			(
				p_job_id_r                    => gn_out_job_id,
				p_batch_id_r                  => gn_sysdt_batchid,
				p_message_type_r              => gc_message_type_r,
				p_code_location_r             => gc_main_loadedby,
				p_message_r                   => gc_trcmsg,
				p_count_type_r                => NULL,
				p_count_r                     => NULL,
				p_duration_r                  => NULL,
				p_created_by_r                => gc_job_name,
				out_prcs_job_log_message_id_r => gn_job_log_message_id_r
			);


	-- Start : Kill/Fill Changes 12th May 2026
        EXECUTE IMMEDIATE 'ALTER SESSION ENABLE PARALLEL DML'; 
	-- End : Kill/Fill Changes 5th May 2026

    -- Start : Kill/Fill Changes 12th May 2026: Commented following 
    --Open/Assign SELECT stmnt
    --OPEN p_out_cursor FOR
    -- End : Kill/Fill Changes 12th May 2026 : Commented following 

        gc_trcmsg := '5.2 - Data load starts for _EXG table for Partition Exchange';
     /*NEW LOGGING MECHANISM CHANGES*/
       pkg_grp_log_util.prc_ins_prcs_job_log_message_r
			(
				p_job_id_r                    => gn_out_job_id,
				p_batch_id_r                  => gn_sysdt_batchid,
				p_message_type_r              => gc_message_type_r,
				p_code_location_r             => gc_main_loadedby,
				p_message_r                   => gc_trcmsg,
				p_count_type_r                => NULL,
				p_count_r                     => NULL,
				p_duration_r                  => NULL,
				p_created_by_r                => gc_job_name,
				out_prcs_job_log_message_id_r => gn_job_log_message_id_r
			);	
        -- Start : Kill/Fill Changes 5th May 2026: Added following 
        INSERT /*+ APPEND PARALLEL(stg, 8) */ INTO rpt_billgroup_r_exg stg
            SELECT /*+ PARALLEL(8) */ DISTINCT
                dim_grp_billing_pol_billgrp_r.d_billed_to_r                  d_billed_to_r,
                dim_grp_billing_pol_billgrp_r.v_bill_category_value_r        v_billing_category_r,
                dim_grp_billing_pol_billgrp_r.v_billtype_value_r             v_billing_option_r,
                dim_grp_address_dir_r.v_city_r                               v_billgroup_city_r,
                dim_grp_billing_pol_billgrp_r.d_delete_date_r                d_billgroup_delete_date_r,
                dim_grp_billing_pol_billgrp_r.d_effective_date_r             d_billgroup_effective_date_r,
                dim_grp_billing_pol_billgrp_r.v_insert_by_r                  v_billgroup_insert_by_r,
                dim_grp_billing_pol_billgrp_r.d_record_insert_date_r         d_billgroup_insert_date_r,
                dim_grp_customer_bill_group_r.v_bill_group_description_r     v_billgroup_description_r,
                dim_grp_customer_bill_group_r.v_customer_bill_group_number_r v_customer_billgroup_number_r,
                dim_grp_billing_pol_billgrp_r.d_paid_to_r                    d_paid_to_r,
                dim_grp_billing_pol_billgrp_r.d_record_end_date_r            d_record_end_date_r,
                dim_grp_billing_pol_billgrp_r.d_record_start_date_r          d_record_start_date_r,
                dim_grp_customer_bill_group_r.v_state_name_r                 v_billgroup_state_r,
                dim_grp_billing_pol_billgrp_r.v_bill_group_status_r          v_billgroup_status_r
		        --,DIM_GRP_CUSTOMER_BILL_GROUP_R.V_CUSTOMER_BILL_GROUP_NUMBER_R
		        --,DIM_GRP_BILLING_POL_BILLGRP_R.V_BILL_GROUP_STATUS_R
                ,
                CAST((
                    CASE
                        WHEN dim_grp_billing_pol_billgrp_r.v_bill_group_status_r = 'Terminated' THEN
                            dim_grp_billing_pol_billgrp_r.d_status_date_r
                    END
                ) AS DATE)                                                   d_billgroup_status_date_r,
                CAST((
                    CASE
                        WHEN dim_grp_billing_pol_billgrp_r.v_bill_group_status_r = 'Terminated' THEN
                            NULL
			     /*(THEN DIM_GRP_BILLING_POL_BILLGRP_R.V_STATUS_REASON_R*/
                        ELSE
                            NULL
                    END
                ) AS DATE)                                                   v_billgroup_termination_date_r,
                dim_grp_billing_pol_billgrp_r.v_update_by_r                  v_billgroup_update_by_r,
                dim_grp_billing_pol_billgrp_r.d_update_date_r                d_billgroup_update_date_r,
                dim_grp_address_dir_r.v_postal_zip_r                         v_billgroup_postal_zip_r,
                dim_grp_billing_pol_billgrp_r.v_premium_mode1_r              v_billgroup_premium_mode_r,
                dim_grp_billing_pol_billgrp_r.v_billing_on_hold_ind_r        v_billing_on_hold_ind_r,
                nvl(fct_grp_billing_policy_dtl_r.v_state_r, ' ')             v_state_r,
                dim_grp_billing_pol_billgrp_r.n_grace_period_r               n_grace_period_r,
                (
                    CASE
                        WHEN dim_grp_billing_pol_billgrp_r.d_paid_to_r = dim_grp_billing_pol_billgrp_r.d_effective_date_r THEN
                            'Y'
                        ELSE
                            'N'
                    END
                )                                                            v_billgroup_payment_status_r,
                dim_grp_billing_pol_billgrp_r.n_policy_billgroup_id_r        n_policy_billgroup_id_r,
                dim_grp_billing_pol_billgrp_r.n_policy_billgroup_sk_r        n_billgroup_sk_r
		        --,to_number(TO_CHAR(sysdate,'YYYYMM')) N_REPORTMONTH_R        --26-Feb-2024 changes
                ,
                gn_current_month                                             n_reportmonth_r --26-Feb-2024 changes
                ,
                gc_getcur_loadedby                                           v_last_modified_by_r,
                gd_sysdate                                                   t_creation_date_r,
                gc_getcur_loadedby                                           v_created_by_r,
                gd_sysdate                                                   t_last_modified_date_r,
                'Y'                                                          v_rpt_active_status_r,
                to_number(to_char(gd_sysdate, 'YYYYMMDD'))                   n_batch_id_r,
		        --1-JULY-24 Changes Start
                CASE
                    WHEN dim_grp_billing_pol_billgrp_r.v_bill_group_status_r = 'Terminated'
                         AND dim_grp_billing_pol_billgrp_r.d_paid_to_r >= CASE
                                                                              WHEN dim_grp_billing_pol_billgrp_r.v_bill_group_status_r =
                                                                              'Terminated' THEN
                                                                                  dim_grp_billing_pol_billgrp_r.d_status_date_r
                                                                              ELSE
                                                                                  TO_DATE('9999-12-31', 'YYYY-MM-DD')
                                                                          END THEN
                        'Team R'
                    ELSE
                        fct_grp_policy_r_pbc_team_lookup.v_pbc_team_name_r
                END                                                          AS v_pbc_team_name_r,
                CASE
                    WHEN dim_grp_billing_pol_billgrp_r.v_bill_group_status_r = 'Terminated'
                         AND dim_grp_billing_pol_billgrp_r.d_paid_to_r >= CASE
                                                                              WHEN dim_grp_billing_pol_billgrp_r.v_bill_group_status_r =
                                                                              'Terminated' THEN
                                                                                  dim_grp_billing_pol_billgrp_r.d_status_date_r
                                                                              ELSE
                                                                                  TO_DATE('9999-12-31', 'YYYY-MM-DD')
                                                                          END THEN
                        'FER'
                    ELSE
                        fct_grp_policy_r_pbc_team_lookup.v_pbc_sub_team_r
                END                                                          AS v_pbc_sub_team_r
			     --1-JULY-24 Changes end
		        --21/10/24 Changes starts
                ,
                dim_grp_address_dir_r.v_addressline1_r                       AS v_billgroup_addressline1_r,
                dim_grp_address_dir_r.v_addressline2_r                       AS v_billgroup_addressline2_r,
                dim_grp_address_dir_r.v_addressline3_r                       AS v_billgroup_addressline3_r
		       --21/10/24 Changes starts
		        -- , 'VUE'                                V_SOURCE_SYSTEM_NAME_R  -- 20-02-2025 added
                ,dim_grp_billing_pol_billgrp_r.v_source_system_name_r --05/03/2025 Added
		       --05/03/25 changes to add mgis filter

            FROM
                (
                    SELECT
                        *
                    FROM
                        dim_grp_billing_pol_billgrp_r
                    WHERE
                        v_source_system_name_r <> 'APS'
                ) dim_grp_billing_pol_billgrp_r   
                --23/05/2026 Added Not in filters to include TPA Source systems
                LEFT JOIN (
                    SELECT
                        *
                    FROM
                        dim_grp_customer_bill_group_r
                    WHERE
                        --v_source_system_name_r IN ( 'VUE', 'MGIS' )
						v_source_system_name_r NOT IN ( 'APS', 'EIS' )
					 --23/05/2026 Added Not in filters to include TPA Source systems
                       AND v_active_status_r = 'Y'
                ) dim_grp_customer_bill_group_r ON dim_grp_customer_bill_group_r.v_active_status_r = 'Y'
                                                   AND dim_grp_billing_pol_billgrp_r.n_customer_billgroup_id_r = dim_grp_customer_bill_group_r.
                                                   n_customer_billgroup_id_r
                INNER JOIN fct_grp_billing_policy_dtl_r ON fct_grp_billing_policy_dtl_r.n_policy_sk_r = dim_grp_billing_pol_billgrp_r.
                n_policy_sk_r
                INNER JOIN dim_grp_policy_dir_r ON dim_grp_policy_dir_r.n_policy_sk_r = dim_grp_billing_pol_billgrp_r.n_policy_sk_r
                LEFT JOIN fct_grp_policy_r_pbc_team_lookup ON dim_grp_policy_dir_r.n_policy_sk_r = fct_grp_policy_r_pbc_team_lookup.n_policy_sk_r
                                                              AND dim_grp_policy_dir_r.n_policy_version_number_r = fct_grp_policy_r_pbc_team_lookup.
                                                              n_version_number_r
                 --LEFT JOIN DIM_GRP_ADDRESS_DIR_R--21/10/24 CHANGES
                LEFT JOIN (
                --21/10/24 CHANGES AND 05/03/25 changes to add mgis filter
                    SELECT
                        *
                    FROM
                        dim_grp_address_dir_r
                    WHERE
                        v_source_system_name_r NOT IN ( 'PACS', 'APS' )
                ) dim_grp_address_dir_r
                 --23/05/2026 Added Not in filters to include TPA Source systems

                 --  ON DIM_GRP_BILLING_POL_BILLGRP_R.N_ADDRESS_SK_R = DIM_GRP_ADDRESS_DIR_R.N_ADDRESS_SK_R --21/10/24 CHANGES
                 ON dim_grp_customer_bill_group_r.n_address_sk_r = dim_grp_address_dir_r.n_address_sk_r
                                           AND dim_grp_address_dir_r.d_delete_date_r IS NULL
                                           AND dim_grp_address_dir_r.n_address_sk_r NOT IN ( 963289, 680889, 739949, 776519, 705641,
                                                                                             773335, 659988, 746983 )
                                           AND dim_grp_address_dir_r.v_active_status_r = 'Y'
            WHERE
                    dim_grp_billing_pol_billgrp_r.v_active_status_r = 'Y'
                AND dim_grp_policy_dir_r.v_active_status_r = 'Y'--232612
                AND dim_grp_billing_pol_billgrp_r.d_delete_date_r IS NULL 
                ;

        gn_run_cnt := SQL%rowcount;
        COMMIT;

        -- Start : Kill/Fill Changes 12th May 2026: Commented following 

        EXECUTE IMMEDIATE 'ALTER SESSION DISABLE PARALLEL DML';
	-- End : Kill/Fill Changes 12th May 2026 

        gt_end_time := systimestamp;
        gc_trcmsg := '5.3 Data Load Completed for _EXG Table';

		/*START: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
        pkg_grp_log_util.prc_ins_prcs_job_log_message_r
			(
				p_job_id_r                    => gn_out_job_id,
				p_batch_id_r                  => gn_sysdt_batchid,
				p_message_type_r              => gc_message_type_r,
				p_code_location_r             => gc_main_loadedby,
				p_message_r                   => gc_trcmsg,
				p_count_type_r                => 'AUDIT_TARGET_COUNT',
				p_count_r                     => gn_run_cnt,
				p_duration_r                  => fnc_grp_time_duration(gt_start_time,gt_end_time),
				p_created_by_r                => gc_job_name,
				out_prcs_job_log_message_id_r => gn_job_log_message_id_r
			);

    EXCEPTION
        WHEN OTHERS THEN
            gc_errmsg := substr(sqlerrm, 1, 4000);
            gc_trcmsg := gc_trcmsg
                         || '4.z Error in prc_get_cur_data'
                         || chr(13);
            pkg_grp_log_util.prc_update_log

			   (gn_out_job_id --p_job_id
               , gc_error_status                                --p_job_status
               , gc_errmsg                                      --p_err_msg
               , gc_trcmsg || chr(13) || gc_errmsg              --p_trc_msg
               , gc_getcur_loadedby                             --p_log_util_called_by_r                                                                       
               );

            RAISE;
    END prc_get_cur_data;

    PROCEDURE prc_rebuild_indexes IS

/***********************************************************************
    Purpose:  Procedure to rebuild indexes RPT_BILLGROUP_R

    Author     Date     Description
  ---------- -------- -------------------------------------------------
    VGireesh   10/11/23 Initial Creation
*******************************************************************************/

        lc_rebuild_index VARCHAR2(300);
    BEGIN
        gc_trcmsg := gc_trcmsg
                     || '7.a Entered into prc_rebuild_indexes'
                     || chr(13);
        FOR i IN (
            SELECT
                'ALTER INDEX '
                || index_name
                || ' REBUILD parallel 16 nologging' rebuild_index
            FROM
                all_indexes
            WHERE
                    table_name = 'RPT_BILLGROUP_R'
                AND index_name NOT LIKE 'PK_%'
                AND index_name NOT LIKE 'FK_%'
                AND status = 'UNUSABLE'
        ) LOOP
            lc_rebuild_index := i.rebuild_index;
            EXECUTE IMMEDIATE lc_rebuild_index;
        END LOOP;

        gc_trcmsg := gc_trcmsg
                     || '7.z Exit from prc_rebuild_indexes'
                     || chr(13);
    EXCEPTION
        WHEN OTHERS THEN
            gc_errmsg := substr(sqlerrm, 1, 4000);
            gc_trcmsg := gc_trcmsg || '7.z Error in prc_rebuild_indexes' || chr(13);


            pkg_grp_log_util.prc_update_log(gn_out_job_id --p_job_id
            , gc_error_status                                --p_job_status
            , gc_errmsg                                      --p_err_msg
            , gc_trcmsg     || chr(13) || gc_errmsg          --p_trc_msg 
			, gc_rebuildindexes                              --p_log_util_called_by_r
			);




            RAISE;
    END prc_rebuild_indexes;

END pkg_grp_load_rpt_billgroup_r;

/

  GRANT EXECUTE ON "ATOMIC"."PKG_GRP_LOAD_RPT_BILLGROUP_R" TO "ATOMIC_ALL_RO";
  GRANT EXECUTE ON "ATOMIC"."PKG_GRP_LOAD_RPT_BILLGROUP_R" TO "EXT_EIS_RO";
  GRANT DEBUG ON "ATOMIC"."PKG_GRP_LOAD_RPT_BILLGROUP_R" TO "ATOMIC_DEBUG";
