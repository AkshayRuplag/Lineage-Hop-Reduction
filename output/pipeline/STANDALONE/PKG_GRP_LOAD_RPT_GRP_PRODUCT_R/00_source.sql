

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ATOMIC"."PKG_GRP_LOAD_RPT_GRP_PRODUCT_R"
IS
/***********************************************************************
  Purpose:  This package body contains procedures which loads data into RPT_GRP_PRODUCT_R
  Used DB Objects : DIM_GRP_PRODUCT_R
                    RPT_GRP_PRODUCT_R
  Author     Date     Description
  ---------- -------- -------------------------------------------------
  VGireesh   10/11/23 Initial Creation
  VGireesh   18/01/24 Added procedure prc_rebuild_indexes
  VGireesh   22/01/24 Added v_coverage_type_r
  VGireesh   23/01/24 Closed REF Cursor
  VGireesh   26/02/24 for month end  that the tables start loading data in the next month partition
                      Ex: March data on February 29th (as of 2.28).
                          27th is Feb Fisc Month End    202402  should be truncate and load in 202402 partition
                          28th is feb Fisc Month End +1 202402  should be truncate and load in 202402 partition
                          29th is Feb Fisc Month End +2 202403  should inactive records against the partition 202402 and load data in 202403 partition
  VGireesh   03/04/24 Added Parallel to rebuild index fast  parallel 16 nologging
  Joe        17/02/26 Audit Control Code as part of reconcilation between EDW and RPT.
  Rose		 06/03/26 Commenting prc_upd_del_data and adding PKG_GRP_COMMON_UTIL.
  Samba      07/05/26 Kill/Fill Changes: User Story - 514603
						- All code changes are marked with Kill/Fill start and end comment blocks.
						- Code changes ensure continuous data availability in reports, replacing the current truncate-and-load approach, which is not partition-exchange based.
						- Retaining old code base of bulk collect load; which can be used when this Package to be converted to incremental processing

  ***********************************************************************/

--Global Constants
gc_rpt_table_name      	VARCHAR2(50)      	:='RPT_GRP_PRODUCT_R';
gd_fic_mis_date          DATE;
gc_rebuild_idx_degree	PLS_INTEGER      	:=8;
--Start: kill/fill additions
gv_rpt_table_name   CONSTANT PRCS_JOB_LOG_R.V_JOB_NAME_R%TYPE := 'RPT_GRP_PRODUCT_R';
gv_exg_table_name   CONSTANT PRCS_JOB_LOG_R.V_JOB_NAME_R%TYPE :=  gv_rpt_table_name||'_EXG';
gv_schema_owner     CONSTANT PRCS_JOB_LOG_R.V_JOB_NAME_R%TYPE := 'ATOMIC';
gt_start_time_r		TIMESTAMP;
gt_end_time_r		TIMESTAMP;
gn_run_cnt 			NUMBER;

--End: kill/fill additions

--Procedure to update prior month active flag and current month partition
PROCEDURE prc_upd_del_data
IS
ln_sqlrowcnt      NUMBER;
ln_cnt            NUMBER;
ld_first_day_date DATE;
--26-Feb-2024 changes starts
ln_fisc_current_month NUMBER;
ln_fisc_prior_month   NUMBER;
ld_fic_mis_date_2     DATE;
--26-Feb-2024 changes ends
BEGIN
    gc_trcmsg:=gc_trcmsg||'3.1 Entered into in prc_upd_del_data'||chr(13);
    /*--26-Feb-2024 changes commented starts
	gc_trcmsg:=gc_trcmsg||'3.2 Get First Day Date of the current month'||chr(13);
	--Get First Day Date of the current month
    SELECT TRUNC(gd_sysdate, 'MONTH') INTO ld_first_day_date
    FROM dual;
    gc_trcmsg:=gc_trcmsg||'3.3 First Day Date of the current month is:->'||ld_first_day_date||chr(13);
	--If First Day date of current month is sysdate then delete all the data as reload is going to happen for Current , Prior and past 6 history months data
    IF TRUNC(ld_first_day_date) =TRUNC(gd_sysdate) THEN
	    --Today is first day of the current month hence Updating v_rpt_active_status_r=N against the records loaded in prior month
   	    gc_trcmsg:=gc_trcmsg||'3.4 Today is first day of the current month hence Updating v_rpt_active_status_r=N against the records loaded in prior month'||CHR(13);
        UPDATE RPT_GRP_PRODUCT_R
	       SET v_rpt_active_status_r='N'
		      ,v_last_modified_by_r=gc_updby
			  ,t_last_modified_date_r=gd_sysdate
	    WHERE n_yearmonth_r = gn_prior_month;
	    ln_sqlrowcnt:=SQL%ROWCOUNT;
	    COMMIT;
   	    gc_trcmsg:=gc_trcmsg||'3.5  Updated v_rpt_active_status_r=N against the records loaded in prior month :->'||ln_sqlrowcnt||chr(13);
	ELSE
	    --Since sysdate is not first day of the current month hence data loaded in Current Month needs to be deleted but prior months data should not be touched
	    gc_trcmsg:=gc_trcmsg||'3.6 Today is not first day of the current month hence Calling procedure prc_trunc_partition to truncate current month partition from main'||chr(13);
        prc_trunc_partition;
	    gc_trcmsg:=gc_trcmsg||'3.7 Completed procedure prc_trunc_partition call from main'||chr(13);
	END IF;*/
  --26-Feb-2024 changes starts
  --Fetch Fisc Month End +2 and Fisc Current Month
  SELECT --D_CALENDAR_DATE_R,D_CALENDAR_DATE_R +1
    D_CALENDAR_DATE_R                  +2 ,
    to_number(TO_CHAR(last_day(sysdate)+1,'YYYYMM'))
  INTO ld_fic_mis_date_2 ,
    ln_fisc_current_month
  FROM atomic.DIM_TIME_R D
  WHERE V_END_OF_FISCAL_MONTH_IND_R      = 'Y'
  AND TO_CHAR(D_CALENDAR_DATE_R,'YYYYMM')=TO_CHAR(sysdate,'YYYYMM');
  gc_trcmsg                             :=gc_trcmsg||'3.2 Fisc Month End +2 Day Date of the current month is:->'||ld_fic_mis_date_2||chr(13);
  gc_trcmsg                             :=gc_trcmsg||'3.3 Fisc Current Month of the current month is:->'||ln_fisc_current_month||chr(13);
  IF TRUNC(ld_fic_mis_date_2)            =TRUNC(sysdate) THEN
    ln_fisc_prior_month                 :=to_number(TO_CHAR(ld_fic_mis_date_2,'YYYYMM'));
    gc_trcmsg                           :=gc_trcmsg||'3.3.1 Fisc Prior Month of the current month is:->'||ln_fisc_prior_month||chr(13);
    gc_trcmsg                           :=gc_trcmsg||'3.4 Today Fisc Month End +2 '||ld_fic_mis_date_2||' hence Updating v_rpt_active_status_r=N against the records loaded in prior fisc month which is :->'||ln_fisc_prior_month||CHR(13);
    UPDATE RPT_GRP_PRODUCT_R
	   SET v_rpt_active_status_r='N'
          ,v_last_modified_by_r=gc_updby
    	  ,t_last_modified_date_r=gd_sysdate
	WHERE n_yearmonth_r = ln_fisc_prior_month;
    ln_sqlrowcnt            :=SQL%ROWCOUNT;
    COMMIT;
    gc_trcmsg       :=gc_trcmsg||'3.5  Updated v_rpt_active_status_r=N against the records loaded in Fisc prior month :->'||ln_fisc_prior_month||' records '||ln_sqlrowcnt||chr(13);
    gc_trcmsg       :=gc_trcmsg||'3.6 Set gn_current_month to  ln_fisc_current_month ';
    gn_current_month:=ln_fisc_current_month;
    gc_trcmsg       :=gc_trcmsg||'3.7 now current month is :->'|| gn_current_month ;
  ELSE
    --If Sysdate is greater than to Fisc Month End +2 and less than last day of the present month then Current Month is next fisc month
	--Ex: if sysdate is  28-MAR-24 which is also Fisc Month end +2 and leass than current month end date 31-MAR-24 then current month 202403 becomes next fisc month which is 202404
	--partition 202404 should be truncated and reloaded
	IF TRUNC(sysdate)>trunc(ld_fic_mis_date_2) and  TRUNC(sysdate)<= trunc(last_day(sysdate)) then
       gc_trcmsg       :=gc_trcmsg||'3.8 Set gn_current_month to  ln_fisc_current_month ';
       gn_current_month:=ln_fisc_current_month;
       gc_trcmsg       :=gc_trcmsg||'3.9 now current month is :->'|| gn_current_month ;
	ELSE
       gc_trcmsg       :=gc_trcmsg||'3.9.1 now current month is :->'|| gn_current_month ;
	END IF;
	--Since sysdate is not fisc month end +2 hence data loaded in Current Month needs to be deleted but prior months data should not be touched
    gc_trcmsg:=gc_trcmsg||'3.10 Today is not fisc month end +2 of the current month hence Calling procedure prc_trunc_partition to truncate current month partition from main'||chr(13);
    prc_trunc_partition;
    gc_trcmsg:=gc_trcmsg||'3.11 Completed procedure prc_trunc_partition call from main'||chr(13);
  END IF;
  --26-Feb-2024 changes ends
	gc_trcmsg:=gc_trcmsg||'3.12 Exit from in prc_upd_del_data'||chr(13);
EXCEPTION
WHEN OTHERS THEN
    gc_errmsg:=SUBSTR(SQLERRM,1,4000);
	gc_trcmsg:=gc_trcmsg||'3.z Error in prc_upd_del_data'||chr(13)||gc_errmsg;
    pkg_grp_log_util.prc_update_log
      (
        gn_out_job_id                 --p_job_id
        ,gc_error_status              --p_job_status
        ,gc_errmsg                    --p_err_msg
        ,gc_trcmsg||chr(13)||gc_errmsg--p_trc_msg
        ,gc_updby                     --p_log_util_called_by_r
      );
    RAISE;

END prc_upd_del_data;
--Procedure to truncate the YEARMONTH partition
PROCEDURE prc_trunc_partition
AS
lc_tbl VARCHAR2(30):='RPT_GRP_PRODUCT_R';
LC_REBUILD_INDEX  varchar2(300);
BEGIN
   gc_trcmsg:=gc_trcmsg||'3.7.1 Entered into prc_trunc_partition :->'||'ALTER TABLE '||lc_tbl||' TRUNCATE PARTITION '||'PART_'||lc_tbl||'_'||gn_current_month||CHR(13);
   execute immediate 'ALTER TABLE '||lc_tbl||' TRUNCATE PARTITION '||'PART_'||lc_tbl||'_'||gn_current_month;
   gc_trcmsg:=gc_trcmsg||'3.7.2 Truncate Partition completed'||chr(13);
  gc_trcmsg:=gc_trcmsg||'3.7.3 Rebuild Unusable PK Index starts'||chr(13);
  FOR I IN
  (SELECT 'ALTER INDEX '
    ||INDEX_NAME
    ||' REBUILD  parallel 16 nologging' REBUILD_INDEX
  FROM ALL_INDEXES
  WHERE TABLE_NAME ='RPT_GRP_PRODUCT_R'
  AND INDEX_NAME LIKE 'PK_%'
  AND STATUS='UNUSABLE'
  )
  LOOP
    LC_REBUILD_INDEX:=I.REBUILD_INDEX;
    EXECUTE IMMEDIATE LC_REBUILD_INDEX;
  END LOOP;
  GC_TRCMSG:=GC_TRCMSG||'3.7.4 Rebuild Unusable PK Index ends'||CHR(13);
  GC_TRCMSG:=GC_TRCMSG||'3.7.z Exit from prc_trunc_partition'||CHR(13);
EXCEPTION
WHEN OTHERS THEN
    gc_errmsg :=SUBSTR(SQLERRM,1,4000);
    gc_trcmsg:=gc_trcmsg||'2.z Error in prc_trunc_partition'||chr(13);
    pkg_grp_log_util.prc_update_log
      (
        gn_out_job_id                 --p_job_id
        ,gc_error_status              --p_job_status
        ,gc_errmsg                    --p_err_msg
        ,gc_trcmsg||chr(13)||gc_errmsg--p_trc_msg
        ,gc_truncpartby               --p_log_util_called_by_r
      );
    RAISE;
END prc_trunc_partition;

--Main procedures calls other procedure to load data in RPT_CLEINT_DTL_R
PROCEDURE main
/***********************************************************************
  Purpose:  This procedure controls the overall process and calls the child
            procedures needed

  Author     Date     Description
  ---------- -------- ----------------------------------------------------------
  Samba		 08-May-2026	Kill/Fill: Added Partition Exchange to address reporitng data availability
*******************************************************************************/
IS
-- Start : comented Kill/Fill Changes 5th May 2026
/*VAR_REF_CUR SYS_REFCURSOR;
TYPE var_tbl_type IS TABLE OF RPT_GRP_PRODUCT_R%ROWTYPE INDEX BY BINARY_INTEGER;
lt_var_tbl_typ var_tbl_type;*/
-- End : comented Kill/Fill Changes 5th May 2026

ln_rec_cnt NUMBER:=0;
lc_main_entity  varchar(20) := 'GRP_PRODUCT';
ld_fic_mis_date_2 DATE;
ln_fisc_current_month NUMBER;
lc_partitioned varchar(10);
lc_index_name  varchar(30);
BEGIN
    --Call Log Util pkg to Insert entry in PRCS_JOB_LOG_R
	pkg_grp_log_util.prc_insert_log
                       ( p_source              => gc_source
					    ,p_job_nm              => gc_job_name
                        ,p_job_status          => gc_running_status
                        ,p_err_msg             => null
                        ,p_trc_msg             => null
                        ,p_n_batch_id          => gn_sysdt_batchid
                        ,p_log_util_called_by_r=> gc_main_loadedby
						,out_job_id            => gn_out_job_id
						);
    gc_trcmsg:=gc_trcmsg||'1. Entered into main'||chr(13);
    gc_trcmsg:=gc_trcmsg||'gn_current_month     :->'||gn_current_month||chr(13);
    gc_trcmsg:=gc_trcmsg||'gn_prior_month       :->'||gn_prior_month||chr(13);

	--gc_trcmsg:=gc_trcmsg||'1.c gn_prior2prior_month :->'||gn_prior2prior_month||chr(13);
	/*gc_trcmsg:=gc_trcmsg||'3. Call procedure prc_upd_del_data from main'||chr(13);
    PKG_GRP_LOAD_RPT_GRP_PRODUCT_R.prc_upd_del_data;
    gc_trcmsg:=gc_trcmsg||'3.z Completed Procedure prc_upd_del_data call from main'||chr(13);*/

	/*Common Utility Proc to get month end+2 date and month. Ex: If month end is 29-Aug-2025 then ln_fisc_current_month will be 202509*/
		PKG_GRP_COMMON_UTIL.prc_fisc_month_calc
		(
			p_out_job_id            =>	gn_out_job_id,
			p_Log_seq_num           =>	2,
			ld_fic_mis_date_2       =>	ld_fic_mis_date_2,
			ln_fisc_current_month   =>	ln_fisc_current_month

		);

		gd_fic_mis_date := ld_fic_mis_date_2;--29-Aug-2024 changes

		/*Common Utility Proc to determine current and prior month ; Checks for month end logic and daily load logic as well */
		PKG_GRP_COMMON_UTIL.PRC_GET_CURRENT_PRIOR_MONTH
		(
			p_out_job_id            =>	gn_out_job_id,
			p_Log_seq_num           =>	3,
			P_fic_mis_date       	=>	ld_fic_mis_date_2,
			P_fisc_current_month    =>	ln_fisc_current_month,
			p_current_month         =>	gn_current_month,
			p_prior_month           =>	gn_prior_month
		);

	-- Start: commented as part of Kill/Fill Process : 5th May 2026 : Commenting this part
	/*	PKG_GRP_COMMON_UTIL.prc_trunc_partition
		(
			p_out_job_id    	=>	gn_out_job_id,
			p_Log_seq_num   	=>	4,
			p_rpt_table     	=>	gc_rpt_table_name,
			p_idx_num       	=>	gc_rebuild_idx_degree,
			p_current_month     =>	gn_current_month
		);


		SELECT partitioned, index_name
			INTO   lc_partitioned, lc_index_name
			FROM   all_indexes
			WHERE  table_name = gc_rpt_table_name
			  AND INDEX_NAME LIKE 'PK_%';

			IF lc_partitioned = 'YES' THEN
				EXECUTE IMMEDIATE
					'ALTER INDEX ' || lc_index_name ||
					' REBUILD PARTITION PART_' || gc_rpt_table_name || '_' ||gn_current_month ||
					' PARALLEL 8 NOLOGGING';

			END IF;	*/
	-- End: commented as part of Kill/Fill Process : 5th May 2026 : Commenting this part

	-- Start: As part of Kill/Fill Process : 5th May 2026 : Added New
	-- Call common Utility Package to create a exchange table if its not present else create new exg table with NoLogging
	PKG_GRP_COMMON_UTIL.PRC_CREATE_EXCHANGE_TABLE_DDL
		(
			p_job_id            	=> gn_out_job_id,
			p_log_seq_num           => 4,
			p_main_table_name       => gv_rpt_table_name,
			p_exg_table_name        => gv_exg_table_name,
			p_schema_name           => gv_schema_owner
		);
	-- End: As part of Kill/Fill Process : 5th May 2026 : Added New

	---Call prc_get_cur_data to get the latest data and perform ref_cursor assignment.
	PKG_GRP_LOAD_RPT_GRP_PRODUCT_R.prc_get_cur_data; /* Added as part of Kill/Fill Process : 5th May 2026 	 */

    -- Start: commented as part of Kill/Fill Process : 5th May 2026 ZONE
	/*gc_trcmsg:=gc_trcmsg||'4. Call prc_get_cur_data to get ref_cursor '||chr(13);
    PKG_GRP_LOAD_RPT_GRP_PRODUCT_R.prc_get_cur_data (var_ref_cur);
    gc_trcmsg:=gc_trcmsg||'4.z Completed Call Procedure prc_get_cur_data to get ref_cursor'||chr(13);
    gc_trcmsg:=gc_trcmsg||'5 data load starts '||chr(13);
	ln_rec_cnt:=0;
    LOOP
	lt_var_tbl_typ.DELETE;
    FETCH var_ref_cur BULK COLLECT INTO  lt_var_tbl_typ LIMIT gn_bulk_coll_cnt;
     FORALL x in lt_var_tbl_typ.First..lt_var_tbl_typ.Last
     INSERT /*+APPEND_VALUES*/ /* INTO RPT_GRP_PRODUCT_R VALUES lt_var_tbl_typ(x) ;
	 ln_rec_cnt:=ln_rec_cnt+lt_var_tbl_typ.COUNT;
	 COMMIT;
     EXIT WHEN var_ref_cur%NOTFOUND;
    END LOOP;
    CLOSE var_ref_cur;--23-Jan-2024 Changes
	 /*Audit Control Code*/
  --gn_target_count :=ln_rec_cnt;
   /*Audit Control Code*/
   -- gc_trcmsg:=gc_trcmsg||'5.z Data Loaded '||ln_rec_cnt||' records '||chr(13);
 	--gc_trcmsg:=gc_trcmsg||'6. Call procedure prc_insert_dummy_rec from main'||chr(13);
   -- PKG_GRP_LOAD_RPT_GRP_PRODUCT_R.prc_insert_dummy_rec;
   -- gc_trcmsg:=gc_trcmsg||'6.z Completed Procedure prc_insert_dummy_rec call from main'||chr(13);
 	--gc_trcmsg:=gc_trcmsg||'7. Call procedure unusable prc_rebuild_indexes from main'||chr(13);

	-- Start : Kill/Fill Changes 5th May 2026 	: Added New
	-- Partition Exchange Common Utility Called to Move data from Exg table to the Main table Current month Partition
	PKG_GRP_COMMON_UTIL.PRC_PARTITION_EXCHANGE
	(
		p_job_id            	=> gn_out_job_id,
		p_log_seq_num           => 6,
		p_main_table_name       => gv_rpt_table_name,
		p_exg_table_name        => gv_exg_table_name,
		p_partition_name        => 'PART_'|| gv_rpt_table_name ||'_'||gn_current_month,
		p_schema_name           => gv_schema_owner
	);


    PKG_GRP_LOAD_RPT_GRP_PRODUCT_R.prc_rebuild_indexes;

    gc_trcmsg:=gc_trcmsg||'7.z Completed Procedure unusable prc_rebuild_indexes call from main'||chr(13);
 	--gc_trcmsg:=gc_trcmsg||'8. Gather RPT_GRP_PRODUCT_R table stats from main'||chr(13);
    --DBMS_STATS.GATHER_TABLE_STATS('ATOMIC','RPT_GRP_PRODUCT_R');
    --gc_trcmsg:=gc_trcmsg||'8.z Completed Gather RPT_GRP_PRODUCT_R table stats from main'||chr(13);

				/*Audit Control Code*/

    gv_trcmsg :='8. :Audit Control Procedure execution as Part of reconcilation between EDW and RPT';
        --gn_target_count :=22311;

	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
            (    p_job_id_r                    => gn_out_job_id
				,p_batch_id_r                  => gn_sysdt_batchid
				,p_message_type_r              => gv_message_type
				,p_code_location_r             => gc_main_loadedby
				,p_message_r                   => gv_trcmsg
				,p_count_type_r                => 'Control Procedure'
				,p_count_r                     => NULL
				,p_duration_r                  => NULL
				,p_created_by_r                => gc_job_name
                ,out_prcs_job_log_message_id_r => gn_job_log_message_id
				);

	PRC_GRP_AUDIT_CONTROL_PROCESS(gc_source,lc_main_entity,gc_source,gc_target);

     /*Audit Control Code*/
    gc_trcmsg:=gc_trcmsg||'1.z Exit from main'||chr(13);
    pkg_grp_log_util.prc_update_log
      (
        gn_out_job_id                   --p_job_id
        ,gc_success_status              --p_job_status
        ,gc_errmsg                      --p_err_msg
        ,gc_trcmsg                      --p_trc_msg
        ,gc_main_loadedby               --p_log_util_called_by_r
      );
    COMMIT;
EXCEPTION
WHEN OTHERS THEN
    gc_errmsg :=SUBSTR(SQLERRM,1,4000);
    gc_trcmsg:=gc_trcmsg||'1. Error in main'||chr(13);
    pkg_grp_log_util.prc_update_log
      (
        gn_out_job_id                   --p_job_id
        ,gc_error_status                --p_job_status
        ,gc_errmsg                       --p_err_msg
        ,gc_trcmsg||chr(13)||gc_errmsg  --p_trc_msg
        ,gc_main_loadedby               --p_log_util_called_by_r
      );
    RAISE;
END main;

--Procedure to perform ref cursor assignment
PROCEDURE prc_get_cur_data
       --(p_out_cursor OUT SYS_REFCURSOR) -- -- Kill/Fill Changes 5th May 2026
AS
v_sql    VARCHAR2(4000 CHAR);
BEGIN
    -- Start : Kill/Fill Changes 5th May 2026
	gv_trcmsg := '5.1 - Entered into prc_get_cur_data ';
	gt_start_time_r := SYSTIMESTAMP;

	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
				( p_job_id_r                    => gn_out_job_id
				 ,p_batch_id_r                  => gn_sysdt_batchid
				 ,p_message_type_r              => gv_message_type
				 ,p_code_location_r             => gc_main_loadedby
				 ,p_message_r                   => gv_trcmsg
				 ,p_count_type_r                => NULL
				 ,p_count_r                     => NULL
				 ,p_duration_r                  => NULL
				 ,p_created_by_r                => gc_job_name
				 ,out_prcs_job_log_message_id_r => gn_job_log_message_id
				);


	EXECUTE IMMEDIATE 'ALTER SESSION ENABLE PARALLEL DML';

	--Open/Assign SELECT stmnt
     --   OPEN p_out_cursor FOR
	-- End : Kill/Fill Changes 5th May 2026 : Commented following

	-- Start : Kill/Fill Changes 5th May 2026: Added following
    INSERT /*+ APPEND PARALLEL(stg, 8) */ INTO RPT_GRP_PRODUCT_R_EXG stg
	SELECT /*+ PARALLEL(8) */
	-- End : Kill/Fill Changes 5th May 2026: Added following

		 N_PRODUCT_SK_R
		,V_PRODUCT_LINE_R
		,V_PRODUCT_LINE_DESC_R
		,V_PRODUCT_SUB_LINE_CODE_R
		,V_PRODUCT_SUB_LINE_DESC_R
		,V_BASIC_PRODUCT_LINE_CODE_R
		,V_BASIC_PRODUCT_LINE_DESC_R
		,V_COVERAGE_TYPE_CODE_R
		,V_COVERAGE_TYPE_DESC_R
		,V_COVERAGE_CATEGORY_R
		,V_COVERAGE_CODE_R
		,V_COVERAGE_DESC_R
        ,gd_sysdate                           FIC_MIS_DATE_R
        ,gn_sysdt_batchid                     N_BATCH_ID_R
		,N_SEQUENCE_NUMBER_R
        ,gd_sysdate                           T_CREATION_DATE_R
        ,gd_sysdate                           T_EVENT_TIMESTAMP_R
        ,gd_sysdate                           T_LAST_MODIFIED_DATE_R
        ,gc_main_loadedby                     V_CREATED_BY_R
        ,gc_main_loadedby                     V_LAST_MODIFIED_BY_R
		,V_SOURCE_SYSTEM_NAME_R
		,V_SUBJECT_AREA_TYPE_R
		,N_VERSION_NUMBER_R
		,D_RECORD_START_DATE_R
		,D_RECORD_END_DATE_R
		,F_PHYSICAL_DELETE_R
		,V_CHANGE_REASON_R
		,V_ACTIVE_STATUS_R
		,N_CLAIM_SK_R
		,N_POLICY_SK_R
		,N_PARTY_SK_R
		,N_QUOTE_SK_R
		,V_PRIVACY_INDICATOR_R
        ,gn_current_month                     N_YEARMONTH_R
        ,'Y'                                 V_RPT_ACTIVE_STATUS_R
        ,cast(null as varchar2(100)) V_COVERAGE_TYPE_IND_R--26-dec-2023 changes
		--22-Jan-2024 changes ends
		,(CASE
        WHEN V_COVERAGE_TYPE_CODE_R = '1' THEN
            'LTD'
        WHEN V_COVERAGE_TYPE_CODE_R = '2' THEN
            'STD'
        WHEN V_COVERAGE_TYPE_CODE_R  = '3' THEN
            'Life'
        end) V_COVERAGE_TYPE_R
		--22-Jan-2024 changes ends
        from atomic.DIM_GRP_PRODUCT_R;

    -- Start : Kill/Fill Changes 5th May 2026: Commented following

	gn_run_cnt := SQL%ROWCOUNT;

	COMMIT;

	EXECUTE IMMEDIATE 'ALTER SESSION DISABLE PARALLEL DML';

	gv_trcmsg       := '5.2 - Exit from prc_get_cur_data - Rows Loaded :->'||gn_run_cnt;
	gt_end_time_r 	:= SYSTIMESTAMP;

	/*START: NEW LOGGING MECHANISM CHANGES*/
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
				( p_job_id_r                    => gn_out_job_id
				 ,p_batch_id_r                  => gn_sysdt_batchid
				 ,p_message_type_r              => gv_message_type
				 ,p_code_location_r             => gc_main_loadedby
				 ,p_message_r                   => gv_trcmsg
				 ,p_count_type_r                => 'AUDIT_TARGET_COUNT'
				 ,p_count_r                     => gn_run_cnt
				 ,p_duration_r                  => FNC_GRP_TIME_DURATION(gt_start_time_r,gt_end_time_r)
				 ,p_created_by_r                => gc_job_name
				 ,out_prcs_job_log_message_id_r => gn_job_log_message_id
				);
	-- End : Kill/Fill Changes 5th May 2026

EXCEPTION
WHEN OTHERS THEN
    gc_errmsg :=SUBSTR(SQLERRM,1,4000);
    gc_trcmsg:=gc_trcmsg||'4.z Error in prc_get_cur_data'||chr(13);
    pkg_grp_log_util.prc_update_log
          (
            gn_out_job_id                   --p_job_id
            ,gc_error_status                --p_job_status
            ,gc_errmsg                      --p_err_msg
            ,gc_trcmsg||chr(13)||gc_errmsg  --p_trc_msg
            ,gc_getcur_loadedby             --p_log_util_called_by_r
          );
    RAISE;
END prc_get_cur_data;

--Procedure to insert dummy record in the table RPT_GRP_PRODUCT_R
PROCEDURE prc_insert_dummy_rec
IS
BEGIN
    gc_trcmsg:=gc_trcmsg||'6.1 Entered into from prc_insert_dummy_rec'||chr(13);
     INSERT /*+APPEND*/ INTO  RPT_GRP_PRODUCT_R
		   (
		    v_last_modified_by_r
           ,t_creation_date_r
           ,v_created_by_r
           ,t_last_modified_date_r
           ,n_yearmonth_r
           ,v_rpt_active_status_r
           ,n_batch_id_r
		   ,N_PARTY_SK_R
		   ,N_QUOTE_SK_R
		   ,FIC_MIS_DATE_R
		   ,T_EVENT_TIMESTAMP_R
		   ,n_sequence_number_r
		   ,N_PRODUCT_SK_R
		   )
    VALUES(gc_main_loadedby
		  ,gd_sysdate
		  ,gc_main_loadedby
		  ,gd_sysdate
		  ,gn_current_month
		  ,'Y'
		  ,gn_sysdt_batchid
          ,-1
          ,-1
         ,gd_sysdate
         ,gd_sysdate
		 ,-1
		 ,-1
		 );
    COMMIT;

    gc_trcmsg:=gc_trcmsg||'6.2 Exit from prc_insert_dummy_rec'||chr(13);
EXCEPTION
WHEN OTHERS THEN
    gc_errmsg :=SUBSTR(SQLERRM,1,4000);
    gc_trcmsg:=gc_trcmsg||'6.z Error in prc_insert_dummy_rec'||chr(13);
    pkg_grp_log_util.prc_update_log
          (
            gn_out_job_id                   --p_job_id
            ,gc_error_status                --p_job_status
            ,gc_errmsg                      --p_err_msg
            ,gc_trcmsg||chr(13)||gc_errmsg  --p_trc_msg
            ,gc_dummyrec_loadedby             --p_log_util_called_by_r
          );
    RAISE;
END prc_insert_dummy_rec;


--Procedure to rebuild indexes RPT_GRP_PRODUCT_R
PROCEDURE prc_rebuild_indexes
IS
LC_REBUILD_INDEX  VARCHAR2(300);
BEGIN
   gc_trcmsg:=gc_trcmsg||'7.a Entered into prc_rebuild_indexes'||chr(13);
  FOR I IN ( select
    'ALTER INDEX '||INDEX_NAME||' REBUILD  parallel 16 nologging' REBUILD_INDEX
    from ALL_INDEXES  where TABLE_NAME ='RPT_GRP_PRODUCT_R'
	AND INDEX_NAME NOT LIKE 'PK_%'
	AND INDEX_NAME NOT LIKE 'FK_%'
	AND STATUS='UNUSABLE'
	)
  LOOP
    LC_REBUILD_INDEX:=I.REBUILD_INDEX;
    EXECUTE IMMEDIATE LC_REBUILD_INDEX;
  END LOOP;
   gc_trcmsg:=gc_trcmsg||'7.z Exit from prc_rebuild_indexes'||chr(13);
EXCEPTION
WHEN OTHERS THEN
    gc_errmsg :=SUBSTR(SQLERRM,1,4000);
    gc_trcmsg:=gc_trcmsg||'7.z Error in prc_rebuild_indexes'||chr(13);
    pkg_grp_log_util.prc_update_log
          (
            gn_out_job_id                   --p_job_id
            ,gc_error_status                --p_job_status
            ,gc_errmsg                      --p_err_msg
            ,gc_trcmsg||chr(13)||gc_errmsg  --p_trc_msg
            ,gc_rebuildindexes             --p_log_util_called_by_r
          );
    RAISE;
END prc_rebuild_indexes;
END PKG_GRP_LOAD_RPT_GRP_PRODUCT_R;

