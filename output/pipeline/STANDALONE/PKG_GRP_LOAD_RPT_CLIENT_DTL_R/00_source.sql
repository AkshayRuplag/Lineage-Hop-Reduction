

  CREATE OR REPLACE EDITIONABLE PACKAGE "ATOMIC"."PKG_GRP_LOAD_RPT_CLIENT_DTL_R"
/*******************************************************************************
  Purpose:  This package controls the processing to load the data to
            RPT_CLIENT_DTL_R

  Author     Date     Description
  ---------- -------- ----------------------------------------------------------

  Samba      05/09/26 Commented  cursor out parameter in prc_get_cur_data as part of Kill/Fill Process
		User Story - 514602
*******************************************************************************/
IS
--Global Constants
gd_sysdate               DATE              := TRUNC(SYSDATE);
gn_prior_month           NUMBER            := TO_NUMBER(TO_CHAR(ADD_MONTHS(TRUNC(gd_sysdate, 'MM'), -1),'YYYYMM'));
gn_current_month         NUMBER            := TO_NUMBER(TO_CHAR(gd_sysdate,'YYYYMM'));
gn_sysdt_batchid         NUMBER            := TO_NUMBER(TO_CHAR(gd_sysdate,'YYYYMMDD'));
gc_main_loadedby         VARCHAR2(100 CHAR):='PKG_GRP_LOAD_RPT_CLIENT_DTL_R.MAIN'      ;
gc_updby                 VARCHAR2(100 CHAR):='PKG_GRP_LOAD_RPT_CLIENT_DTL_R.PRC_UPD_DEL_DATA';
gc_getcur_loadedby       VARCHAR2(100 CHAR):='PKG_GRP_LOAD_RPT_CLIENT_DTL_R.PRC_GET_CUR_DATA';
gc_truncpartby           VARCHAR2(100 CHAR):='PKG_GRP_LOAD_RPT_CLIENT_DTL_R.PRC_TRUNC_PARTITION';
gc_rebuildindexes           VARCHAR2(100 CHAR):='PKG_GRP_LOAD_RPT_CLIENT_DTL_R.PRC_REBUILD_INDEXES';
gc_trcmsg                CLOB              :='Trace Message:->';
gc_job_name              VARCHAR2(50 CHAR) :='GRP_LOAD_RPT_CLIENT_DTL_R';
gn_bulk_coll_cnt         NUMBER            :=10000;
gc_running_status        VARCHAR2(30)      :='Running';
gc_error_status          VARCHAR2(30)      :='Error';
gc_success_status        VARCHAR2(30)      :='Success';
gc_source                VARCHAR2(30)      :='EDW';
--Global Variables
gn_out_job_id            NUMBER;
gc_errmsg                VARCHAR2(4000 CHAR);
 gn_target_count          number;
gc_target                varchar2(30) :='RPT';
gv_message_type 	     CONSTANT PRCS_JOB_LOG_MESSAGE_R.v_message_type_r%TYPE  			 := PKG_GRP_LOG_UTIL.gc_message_type_info;
gv_trcmsg                PRCS_JOB_LOG_MESSAGE_R.V_MESSAGE_R%TYPE;
gn_job_log_message_id    PRCS_JOB_LOG_MESSAGE_R.N_COUNT_R%TYPE;
--main procedure
PROCEDURE main;
--Procedure declaration for ref cursor assignment
PROCEDURE prc_get_cur_data;
--(p_out_cursor OUT SYS_REFCURSOR); commented as part of Kill/Fill process  09 May'2026
--Procedure declaration for updating prior month active flag and current month partition in the table RPT_CLIENT_DTL_R
PROCEDURE prc_upd_del_data;
--Procedure declaration for truncating the YEARMONTH partition in the table RPT_CLIENT_DTL_R
PROCEDURE prc_trunc_partition;
--Procedure to create dummy record in the table RPT_CLIENT_DTL_R
PROCEDURE prc_insert_dummy_rec;
--Procedure to rebuild indexes RPT_CLIENT_DTL_R
PROCEDURE prc_rebuild_indexes;
END PKG_GRP_LOAD_RPT_CLIENT_DTL_R;
/
CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ATOMIC"."PKG_GRP_LOAD_RPT_CLIENT_DTL_R"
IS
/***********************************************************************
  Purpose:  This package body contains procedures which loads data into RPT_CLIENT_DTL_R
  Used DB Objects :dim_grp_party_dir_r
                   dim_grp_party_r
                   dim_grp_customer_r
                   dim_grp_carrier_r
                   dim_grp_field_office_r
                   fct_grp_party_address_r

  Author     Date     Description
  ---------- -------- -------------------------------------------------
  VGireesh   10/11/23 Initial Creation
  VGireesh   04/01/24 Gather table stats added
  VGireesh   18/01/24 Added procedure prc_rebuild_indexes
  VGireesh   23/01/24 Closed REF Cursor
  VGireesh   20/02/24 Added below columns
                      V_REGIONAL_AVP_NAME_R
                      V_REGIONAL_VP_GROUP_R
                      V_REGIONAL_VP_NAME_R
                      V_REGIONAL_VP_TITLE_R
                      V_RSO_CODE_R
                      V_RSO_LOCATION_CODE_R
                      V_RSO_NAME_R
                      V_RSO_NUMBER_R
                      V_RSO_REGION_NAME_R
                      V_RSO_REGION_SHORT_NAME_R
  VGireesh   26/02/24 for month end  that the tables start loading data in the next month partition
                      Ex: March data on February 29th (as of 2.28).
                          27th is Feb Fisc Month End    202402  should be truncate and load in 202402 partition
                          28th is feb Fisc Month End +1 202402  should be truncate and load in 202402 partition
                          29th is Feb Fisc Month End +2 202403  should inactive records against the partition 202402 and load data in 202403 partition
  VGireesh   19/03/24 Added column v_employer_tax_id_r and als mapping has been added for the below columns
                      V_REGIONAL_AVP_NAME_R,V_REGIONAL_VP_GROUP_R,V_REGIONAL_VP_NAME_R,V_REGIONAL_VP_TITLE_R,V_RSO_CODE_R,V_RSO_LOCATION_CODE_R,V_RSO_NAME_R,V_RSO_NUMBER_R
                      and added logic to alter unusable PK index
  VGireesh   03/04/24 Added Parallel to rebuild index fast  parallel 16 nologging

  Chandra    20/06/24 Added Distinct in Select Query because For single version number we r having multiple records due to which Our SSL Table RPT_CLIENT_DTL_R failing.
  Chandra    21/06/24 Added v_customer_msa_code_r,v_customer_msa_name_r
  Joe        17/02/26  Audit Control Code as part of reconcilation between EDW and RPT.
  Rose		 10/03/26   Commenting prc_upd_del_data and adding PKG_GRP_COMMON_UTIL.
  Samba      09/05/26 Kill/Fill Changes: User Story - 514602
						- All code changes are marked with Kill/Fill start and end comment blocks.
						- Code changes ensure continuous data availability in reports, replacing the current truncate-and-load approach, which is not partition-exchange based.
						- Retaining old code base of bulk collect load; which can be used when this Package to be converted to incremental processing

  ***********************************************************************/

--Global Constants
gc_rpt_table_name      	VARCHAR2(50)      	:='RPT_CLIENT_DTL_R';
gd_fic_mis_date         DATE;
gc_rebuild_idx_degree	PLS_INTEGER      	:=8;
gv_rpt_table_name   	CONSTANT PRCS_JOB_LOG_R.V_JOB_NAME_R%TYPE := 'RPT_CLIENT_DTL_R';
gv_exg_table_name   	CONSTANT PRCS_JOB_LOG_R.V_JOB_NAME_R%TYPE :=  gv_rpt_table_name||'_EXG';
gv_schema_owner     	CONSTANT PRCS_JOB_LOG_R.V_JOB_NAME_R%TYPE := 'ATOMIC';
gt_start_time_r			TIMESTAMP;
gt_end_time_r			TIMESTAMP;
gn_run_cnt 				NUMBER;

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
    /*gc_trcmsg:=gc_trcmsg||'3.2 Get First Day Date of the current month'||chr(13);
	--Get First Day Date of the current month
    SELECT TRUNC(gd_sysdate, 'MONTH') INTO ld_first_day_date
    FROM dual;
    gc_trcmsg:=gc_trcmsg||'3.3 First Day Date of the current month is:->'||ld_first_day_date||chr(13);
	--If First Day date of current month is sysdate then delete all the data as reload is going to happen for Current , Prior and past 6 history months data
    IF TRUNC(ld_first_day_date) =TRUNC(gd_sysdate) THEN
	    --Today is first day of the current month hence Updating v_rpt_active_status_r=N against the records loaded in prior month
   	    gc_trcmsg:=gc_trcmsg||'3.4 Today is first day of the current month hence Updating v_rpt_active_status_r=N against the records loaded in prior month'||CHR(13);
        UPDATE rpt_client_dtl_r
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
    UPDATE rpt_client_dtl_r
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
lc_tbl VARCHAR2(30):='RPT_CLIENT_DTL_R';
LC_REBUILD_INDEX varchar2(300);
BEGIN
   gc_trcmsg:=gc_trcmsg||'3.7.1 Entered into prc_trunc_partition :->'||'ALTER TABLE '||lc_tbl||' TRUNCATE PARTITION '||'PART_'||lc_tbl||'_'||gn_current_month||CHR(13);
   execute immediate 'ALTER TABLE '||lc_tbl||' TRUNCATE PARTITION '||'PART_'||lc_tbl||'_'||gn_current_month;
  gc_trcmsg:=gc_trcmsg||'3.7.2 Truncate Partition completed'||chr(13);
  gc_trcmsg:=gc_trcmsg||'3.7.3 Rebuild Unusable PK Index starts'||chr(13);
  FOR I IN
  (SELECT 'ALTER INDEX '
    ||INDEX_NAME
    ||' REBUILD parallel 16 nologging' REBUILD_INDEX
  FROM ALL_INDEXES
  WHERE TABLE_NAME ='RPT_CLIENT_DTL_R'
  --AND INDEX_NAME LIKE 'PK_%'
  AND STATUS='UNUSABLE'
  )
  LOOP
    LC_REBUILD_INDEX:=I.REBUILD_INDEX;
    EXECUTE IMMEDIATE LC_REBUILD_INDEX;
  END LOOP;
  GC_TRCMSG:=GC_TRCMSG||'3.7.4 Rebuild Unusable PK Index ends'||CHR(13);
  gc_trcmsg:=gc_trcmsg||'3.7.z Exit from prc_trunc_partition'||CHR(13);
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
IS
VAR_REF_CUR SYS_REFCURSOR;
TYPE var_tbl_type IS TABLE OF RPT_CLIENT_DTL_R%ROWTYPE INDEX BY BINARY_INTEGER;
lt_var_tbl_typ var_tbl_type;
ln_rec_cnt NUMBER:=0;
lc_main_entity  VARCHAR(20):= 'CLIENT_DTL';
ld_fic_mis_date_2 DATE;
ln_fisc_current_month NUMBER;
lc_partitioned varchar(10); -- Kill fill process commenting
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
    PKG_GRP_LOAD_RPT_CLIENT_DTL_R.prc_upd_del_data;
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
	/*PKG_GRP_COMMON_UTIL.prc_trunc_partition
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

			END IF;*/

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

 	--gc_trcmsg:=gc_trcmsg||'3.A. Call procedure prc_rebuild_indexes after truncating partition from main'||chr(13);
    --PKG_GRP_LOAD_RPT_CLIENT_DTL_R.prc_rebuild_indexes;
    --gc_trcmsg:=gc_trcmsg||'3.A.z Completed Procedure prc_rebuild_indexes after truncating partition call from main'||chr(13);

	---Call prc_get_cur_data to get the latest data and perform ref_cursor assignment.
	PKG_GRP_LOAD_RPT_CLIENT_DTL_R.prc_get_cur_data; /* Added as part of Kill/Fill Process : 5th May 2026 	 */

	-- Start: commented as part of Kill/Fill Process : 5th May 2026 ZONE
	/*gc_trcmsg:=gc_trcmsg||'4. Call prc_get_cur_data to get ref_cursor '||chr(13);
    PKG_GRP_LOAD_RPT_CLIENT_DTL_R.prc_get_cur_data (var_ref_cur);
    gc_trcmsg:=gc_trcmsg||'4.z Completed Call Procedure prc_get_cur_data to get ref_cursor'||chr(13);
    gc_trcmsg:=gc_trcmsg||'5 data load starts '||chr(13);
	ln_rec_cnt:=0;
    LOOP
	lt_var_tbl_typ.DELETE;
    FETCH var_ref_cur BULK COLLECT INTO  lt_var_tbl_typ LIMIT gn_bulk_coll_cnt;
     FORALL x in lt_var_tbl_typ.First..lt_var_tbl_typ.Last
     INSERT /*+APPEND_VALUES*/ /*INTO RPT_CLIENT_DTL_R VALUES lt_var_tbl_typ(x) ;
	 ln_rec_cnt:=ln_rec_cnt+lt_var_tbl_typ.COUNT;
	 COMMIT;
     EXIT WHEN var_ref_cur%NOTFOUND;
    END LOOP;
    CLOSE var_ref_cur;--23-Jan-2024 Changes
	 /*Audit Control Code*/
   -- gn_target_count :=ln_rec_cnt;
   /*Audit Control Code*/


    /*gc_trcmsg:=gc_trcmsg||'5.z Data Loaded '||ln_rec_cnt||' records '||chr(13);
 	gc_trcmsg:=gc_trcmsg||'6. Call procedure prc_insert_dummy_rec from main'||chr(13);
    PKG_GRP_LOAD_RPT_CLIENT_DTL_R.prc_insert_dummy_rec;
    gc_trcmsg:=gc_trcmsg||'6.z Completed Procedure prc_insert_dummy_rec call from main'||chr(13);
 	gc_trcmsg:=gc_trcmsg||'7. Call procedure unusable prc_rebuild_indexes from main'||chr(13);*/
    -- End: commented as part of Kill/Fill Process : 5th May 2026 : Commenting this part

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

	PKG_GRP_LOAD_RPT_CLIENT_DTL_R.prc_rebuild_indexes;

    gc_trcmsg:=gc_trcmsg||'7.z Completed Procedure unusable prc_rebuild_indexes call from main'||chr(13);
 	--gc_trcmsg:=gc_trcmsg||'8. Gather RPT_CLIENT_DTL_R table stats from main'||chr(13);
    --DBMS_STATS.GATHER_TABLE_STATS('ATOMIC','RPT_CLIENT_DTL_R');
    --gc_trcmsg:=gc_trcmsg||'8.z Completed Gather RPT_CLIENT_DTL_R table stats from main'||chr(13);

	/*Audit Control Code*/

	gv_trcmsg :='8. Audit Control Procedure execution as Part of reconcilation between EDW and RPT';
        --gn_target_count :=22311;

	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
            (    p_job_id_r                    => gn_out_job_id
				,p_batch_id_r                  => gn_sysdt_batchid
				,p_message_type_r              => gv_message_type
				,p_code_location_r             => gc_main_loadedby
				,p_message_r                   => gv_trcmsg
				,p_count_type_r                => 'Control Procedure'
				,p_count_r                     => gn_target_count
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
		--(p_out_cursor OUT SYS_REFCURSOR)  Commented as part of Kill/Fill process 09 May'26
AS
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

	   --Open/Assign SELECT stmnt   Commented as part of Kill/Fill process 09 May'26
       -- OPEN p_out_cursor FOR		Commented as part of Kill/Fill process 09 May'26

	INSERT /*+ APPEND PARALLEL(stg, 8) */ INTO RPT_CLIENT_DTL_R_EXG stg
		SELECT
		--20-06-24 CHANGE start
		DISTINCT
		--20-06-24 CHANGE END
		dim_grp_carrier_r.v_short_name_r                                              v_short_name_r
		,dim_grp_carrier_r.v_carrier_name_r                                           v_carrier_name_r
		,dim_grp_carrier_r.v_source_system_name_r                                     v_carrier_source_system_name_r
		,dim_grp_carrier_r.v_company_code_r                                           v_company_code_r
		,dim_grp_customer_r.v_active_status_r                                         v_active_status_r
		,dim_grp_customer_r.v_customer_number_r                                       v_customer_number_r
		,Case when dim_grp_customer_r.n_national_account_indicator_r = 1
		  THEN 1 else 0 end                                                           n_national_account_indicator_r
		,dim_grp_field_office_r.v_field_office_name_r                                 v_field_office_name_r
		,dim_grp_party_dir_r.v_party_type_r                                           v_party_dir_party_type_r
		,dim_grp_party_dir_r.v_source_system_name_r                                   v_party_dir_source_system_name_r
		,dim_grp_party_dir_r.v_rso_abbrev_r                                           v_rso_abbrev_r
		,dim_grp_party_r.v_primary_email_address_r                                    v_primary_email_address_r
		,/*select distinct case  when upper(T1655484.V_POSITION_TYPE_R) not in ('TERMINATE') and upper(T1655577.V_DESCRIPTION_R) = 'CORRESPONDENT' then concat(concat(T1656493.V_INDIVIDUAL_FIRST_NAME_R, ' '), T1656493.V_INDIVIDUAL_LAST_NAME_R) end  as c1
          from
               (
                    DIM_GRP_PARTY_R T1656493 -- D_GRP_PARTY_R_Party --  left outer join DIM_GRP_ENTITYPOSITIONS_R T1655484 -- D_GRP_ENTITYPOSITIONS_R_Client
					--  On T1655484.N_PARTY_SK_R = T1656493.N_PARTY_SK_R and T1655484.N_VERSION_NUMBER_R = T1656493.N_SOURCE_VERSION_NUMBER_R) left outer join DIM_GRP_CORRESPONDENT_R T1655577 -- D_GRP_CORRESPONDENT_R_Client --
					On T1655577.N_CUST_PARTY_SK_R = T1656493.N_PARTY_SK_R and T1655577.N_VERSION_NUMBER_R = T1656493.N_SOURCE_VERSION_NUMBER_R

          T1656493 =  DIM_GRP_PARTY_R
                    T1655577 = DIM_GRP_CORRESPONDENT_R
          T1655484 =  DIM_GRP_ENTITYPOSITIONS_R
          */
        CAST(NULL AS VARCHAR2(100))                                            v_client_correspondent_name_r--temp fix
		  ,dim_grp_party_r.v_individual_or_org_ind_r                                  v_individual_or_org_ind_r
		  /*
		  CASE WHEN dim_grp_party_r.v_individual_or_org_ind_r = 'O'
		  THEN dim_grp_party_r.v_individual_last_name_r
		  WHEN dim_grp_party_r.v_individual_or_org_ind_r = 'I'
		  THEN dim_grp_party_r.v_individual_first_name_r || ' ' || dim_grp_party_r.v_individual_last_name_r
		  ELSE  NULL
		  END                                                                        v_individual_last_name_r
		  */ --old logic
		,CASE
         WHEN dim_grp_party_r.v_individual_or_org_ind_r = 'O'
         THEN TRIM(dim_grp_party_r.v_individual_last_name_r)
         WHEN dim_grp_party_r.v_individual_or_org_ind_r = 'I'
         THEN TRIM(dim_grp_party_r.v_individual_first_name_r || ' ' || dim_grp_party_r.v_individual_last_name_r)
         ELSE NULL
         END AS v_individual_last_name_r
		 ,CASE  WHEN dim_grp_party_r.v_individual_or_org_ind_r = 'O'
		 THEN dim_grp_party_r.v_master_customer_name_r
         ELSE NULL
		 END                                                                         v_master_customer_name_r
		,dim_grp_party_r.v_master_customer_num_r                                     v_master_customer_num_r
		,dim_grp_party_r.v_party_type_r                                              v_party_type_r
		,dim_grp_party_r.v_source_system_name_r                                      v_source_system_name_r
		,dim_grp_party_r.v_sic_codes_r                                               v_sic_codes_r
		,dim_grp_party_dir_r.n_party_sk_r                                            n_cust_party_sk_r
		,fct_grp_party_address_r_main.v_address_type_r                               v_address_type_r
		,fct_grp_party_address_r_main.v_party_type_r                                 v_party_address_party_type_r
		,fct_grp_party_address_r_main.v_addressline1_r                               v_addressline1_r
		,fct_grp_party_address_r_main.v_addressline2_r                               v_addressline2_r
		,fct_grp_party_address_r_main.v_city_r                                       v_city_r
		,fct_grp_party_address_r_main.v_country_r                                    v_country_r
		,fct_grp_party_address_r_main.v_state_name_r                                 v_client_state_main_r
		,fct_grp_party_address_r_main.v_postal_zip_r                                 v_client_zip_code_r
		,fct_grp_party_address_r_situs.v_state_name_r                                v_situs_state_r
		,fct_grp_party_address_r_main.v_location_id_r                                v_location_id_r--use " Main: filter - might need to add separate for situs - TBD
		,fct_grp_party_address_r_main.n_primary_location_r                           n_primary_location_r
		,dim_grp_party_r.v_sic_category_r                                            v_sic_category_r
		,dim_grp_party_r.v_sic_desc_r                                                v_sic_desc_r
		,dim_grp_customer_r.v_id_code_r                                              v_client_id_r
		--,OV_FCT_GRP_PARTY_ADD_CUST_STATE.v_state_name_r                            V_MASTER_CUSTOMER_STATE_R
		,CAST(NULL AS VARCHAR2(100))                                                      v_master_customer_state_r --Populate null temporarily
		--,OV_NSOCONTACT_R.V_NSO_DESCRIPTION_R                                       V_NSO_CONTACT_NAME_R
		--,CAST(NULL AS VARCHAR2(100))                                                      v_nso_contact_name_r      --Populate null temporarily - required column is not in PROD.
		,OV_NSOCONTACT_R.V_NSO_DESCRIPTION_R                                       V_NSO_CONTACT_NAME_R
		,fct_grp_party_address_r_situs.v_addressline1_r                              v_situs_address_line1_r
		,fct_grp_party_address_r_situs.v_addressline2_r                              v_situs_address_line2_r
        ,fct_grp_party_address_r_situs.v_city_r                                      v_situs_city_r
		,fct_grp_party_address_r_situs.v_postal_zip_r                                v_situs_zip_code_r
		,dim_grp_party_r.v_ieb_ind_r                                                 v_ieb_type_r
		,gc_main_loadedby                                                            v_last_modified_by_r
		--,n_sequence_number_r
		,gd_sysdate                                                                  t_creation_date_r
		,gc_main_loadedby                                                            v_created_by_r
		,gd_sysdate                                                                  t_last_modified_date_r
		,gn_current_month                                                            n_yearmonth_r
		,dim_grp_party_dir_r.v_active_status_r                                       v_rpt_active_status_r
		,gn_sysdt_batchid                                                            n_batch_id_r
        --20-Feb-2024 changes starts
		,stg_rso_to_region_r.v_regional_avp_name_r                                   v_regional_avp_name_r        --19-mar-2024 changes
		,stg_rso_to_region_r.v_regional_vp_group_r                                   v_regional_vp_group_r        --19-mar-2024 changes
		,stg_rso_to_region_r.v_regional_vp_name_r                                    v_regional_vp_name_r         --19-mar-2024 changes
		,stg_rso_to_region_r.v_regional_vp_title_r                                   v_regional_vp_title_r        --19-mar-2024 changes
		,dim_grp_field_office_r.v_code_r                                             v_rso_code_r                 --19-mar-2024 changes
		,dim_grp_field_office_r.v_rsl_location_code_r                                v_rso_location_code_r        --19-mar-2024 changes
		,dim_grp_field_office_r.v_field_office_name_r                                v_rso_name_r                 --19-mar-2024 changes
		,dim_grp_field_office_r.v_regional_office_number_r                           v_rso_number_r               --19-mar-2024 changes
		,stg_rso_to_region_r.v_region_name_r                                         v_rso_region_name_r          --19-mar-2024 changes
		,stg_rso_to_region_r.v_region_short_name_r                                   v_rso_region_short_name_r    --19-mar-2024 changes
        --20-Feb-2024 changes ends
		,(case  when dim_grp_customer_r.V_SSN_FEIN_INDICATOR_R = 'FEIN'
		  then LPAD(dim_grp_customer_r.N_FEDERAL_EMPLOYER_NO_R, 9, '0')
		  else null
		  end
		  )                                                                          V_EMPLOYER_TAX_ID_R --19-Mar-2024 changes
		  --21-06-24-changes start
		  ,T1011891.V_MSA_R                                           v_customer_msa_code_r
		  ,T1011891.V_MSA_NAME_R                                        v_customer_msa_name_r
		  		  --21-06-24-changes end
		FROM
		atomic.dim_grp_party_dir_r  dim_grp_party_dir_r
		INNER JOIN atomic.dim_grp_party_r  dim_grp_party_r
		ON dim_grp_party_dir_r.n_party_sk_r = dim_grp_party_r.n_party_sk_r
		AND dim_grp_party_dir_r.n_source_version_number_r = dim_grp_party_r.n_source_version_number_r
		INNER JOIN atomic.dim_grp_customer_r  dim_grp_customer_r
		ON dim_grp_customer_r.n_cust_party_sk_r = dim_grp_party_dir_r.n_party_sk_r
		LEFT JOIN atomic.dim_grp_carrier_r  dim_grp_carrier_r
		ON dim_grp_carrier_r.n_carrier_sk_r = dim_grp_customer_r.n_carrier_sk_r
		AND dim_grp_carrier_r.v_active_status_r = 'Y'
		LEFT JOIN atomic.dim_grp_field_office_r  dim_grp_field_office_r
		ON dim_grp_field_office_r.v_code_r = dim_grp_party_dir_r.v_rso_abbrev_r
		AND dim_grp_field_office_r.v_active_status_r = 'Y'
		LEFT JOIN (SELECT *
					 FROM atomic.fct_grp_party_address_r
					WHERE v_location_id_r = 'MAIN'
					  AND v_party_type_r = 'CUSTOMER'
				  ) fct_grp_party_address_r_main
		ON fct_grp_party_address_r_main.n_party_sk_r = dim_grp_party_dir_r.n_party_sk_r
		AND fct_grp_party_address_r_main.n_source_version_number_r = dim_grp_party_dir_r.n_source_version_number_r
        --19-Mar-2024 changes starts
		left join atomic.stg_rso_to_region_r
        on stg_rso_to_region_r.v_rsl_loc_code_r = dim_grp_field_office_r.v_rsl_location_code_r
        and  dim_grp_field_office_r.v_active_status_r = 'Y'
        --19-Mar-2024 changes ends
		LEFT JOIN (SELECT *
					 FROM atomic.fct_grp_party_address_r  z
					WHERE z.v_location_id_r = 'Situs'
					  AND z.v_party_type_r = 'CUSTOMER'
					  AND z.n_source_version_seq_number_r = (SELECT MAX(N_SOURCE_VERSION_SEQ_NUMBER_R)
															   FROM atomic.fct_grp_party_address_r  y
															  WHERE z.n_party_sk_r = y.n_party_sk_r
																AND y.V_LOCATION_ID_R = 'Situs'
																AND y.V_PARTY_TYPE_R = 'CUSTOMER'
																AND z.N_SOURCE_VERSION_NUMBER_R = y.N_SOURCE_VERSION_NUMBER_R)
															) fct_grp_party_address_r_situs
		ON fct_grp_party_address_r_situs.n_party_sk_r = dim_grp_party_dir_r.n_party_sk_r
		AND fct_grp_party_address_r_situs.n_source_version_number_r = dim_grp_party_dir_r.n_source_version_number_r
		left outer join atomic.STG_CMSA_R  T1011891 /* D_CMSA_INSURED */  On T1011891.v_zip_code_r = substr(fct_grp_party_address_r_situs.V_POSTAL_ZIP_R , 1 , 5)
		LEFT JOIN (Select * from ATOMIC.DIM_GRP_NSOCONTACT_R  A where  A.V_ACTIVE_STATUS_R = 'Y'
		and n_source_version_seq_number_r = (select max(n_source_version_seq_number_r)
		from ATOMIC.DIM_GRP_NSOCONTACT_R  B where B.V_ACTIVE_STATUS_R = 'Y'
		and  A.N_CUST_PARTY_SK_R = B.N_CUST_PARTY_SK_R and A.N_VERSION_NUMBER_R = B.N_VERSION_NUMBER_R )) OV_NSOCONTACT_R
        ON dim_grp_party_dir_r.n_party_sk_r = OV_NSOCONTACT_R.N_CUST_PARTY_SK_R
        AND dim_grp_party_dir_r.n_source_version_number_r = OV_NSOCONTACT_R.N_VERSION_NUMBER_R
		and OV_NSOCONTACT_R.V_ACTIVE_STATUS_R = 'Y'
		WHERE dim_grp_party_dir_r.v_active_status_r = 'Y'
		AND dim_grp_party_r.v_active_status_r = 'Y'
		AND dim_grp_customer_r.v_active_status_r = 'Y'
		AND dim_grp_party_dir_r.v_party_type_r = 'CUSTOMER'
		AND dim_grp_party_dir_r.v_source_system_name_r = 'PACS'
		--fetch first 2000 rows ONLY
		;

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

--Procedure to insert dummy record in the table RPT_CLIENT_DTL_R
PROCEDURE prc_insert_dummy_rec
IS
BEGIN
    gc_trcmsg:=gc_trcmsg||'6.1 Entered into from prc_insert_dummy_rec'||chr(13);
     INSERT /*+APPEND*/ INTO  RPT_CLIENT_DTL_R
		   (
		    v_last_modified_by_r
           ,t_creation_date_r
           ,v_created_by_r
           ,t_last_modified_date_r
           ,n_yearmonth_r
           ,v_rpt_active_status_r
           ,n_batch_id_r
		   ,n_cust_party_sk_r
		   )
    VALUES(gc_main_loadedby
		  ,gd_sysdate
		  ,gc_main_loadedby
		  ,gd_sysdate
		  ,gn_current_month
		  ,'Y'
		  ,gn_sysdt_batchid
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
            ,gc_getcur_loadedby             --p_log_util_called_by_r
          );
    RAISE;
END prc_insert_dummy_rec;

--Procedure to rebuild indexes RPT_CLIENT_DTL_R
PROCEDURE prc_rebuild_indexes
IS
LC_REBUILD_INDEX  VARCHAR2(300);
BEGIN
   gc_trcmsg:=gc_trcmsg||'7.a Entered into prc_rebuild_indexes'||chr(13);
  FOR I IN ( select
    'ALTER INDEX '||INDEX_NAME||' REBUILD parallel 16 nologging' REBUILD_INDEX
    from ALL_INDEXES  where TABLE_NAME ='RPT_CLIENT_DTL_R'
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

END PKG_GRP_LOAD_RPT_CLIENT_DTL_R;
/



  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ATOMIC"."PKG_GRP_LOAD_RPT_CLIENT_DTL_R"
IS
/***********************************************************************
  Purpose:  This package body contains procedures which loads data into RPT_CLIENT_DTL_R
  Used DB Objects :dim_grp_party_dir_r
                   dim_grp_party_r
                   dim_grp_customer_r
                   dim_grp_carrier_r
                   dim_grp_field_office_r
                   fct_grp_party_address_r

  Author     Date     Description
  ---------- -------- -------------------------------------------------
  VGireesh   10/11/23 Initial Creation
  VGireesh   04/01/24 Gather table stats added
  VGireesh   18/01/24 Added procedure prc_rebuild_indexes
  VGireesh   23/01/24 Closed REF Cursor
  VGireesh   20/02/24 Added below columns
                      V_REGIONAL_AVP_NAME_R
                      V_REGIONAL_VP_GROUP_R
                      V_REGIONAL_VP_NAME_R
                      V_REGIONAL_VP_TITLE_R
                      V_RSO_CODE_R
                      V_RSO_LOCATION_CODE_R
                      V_RSO_NAME_R
                      V_RSO_NUMBER_R
                      V_RSO_REGION_NAME_R
                      V_RSO_REGION_SHORT_NAME_R
  VGireesh   26/02/24 for month end  that the tables start loading data in the next month partition
                      Ex: March data on February 29th (as of 2.28).
                          27th is Feb Fisc Month End    202402  should be truncate and load in 202402 partition
                          28th is feb Fisc Month End +1 202402  should be truncate and load in 202402 partition
                          29th is Feb Fisc Month End +2 202403  should inactive records against the partition 202402 and load data in 202403 partition
  VGireesh   19/03/24 Added column v_employer_tax_id_r and als mapping has been added for the below columns
                      V_REGIONAL_AVP_NAME_R,V_REGIONAL_VP_GROUP_R,V_REGIONAL_VP_NAME_R,V_REGIONAL_VP_TITLE_R,V_RSO_CODE_R,V_RSO_LOCATION_CODE_R,V_RSO_NAME_R,V_RSO_NUMBER_R
                      and added logic to alter unusable PK index
  VGireesh   03/04/24 Added Parallel to rebuild index fast  parallel 16 nologging

  Chandra    20/06/24 Added Distinct in Select Query because For single version number we r having multiple records due to which Our SSL Table RPT_CLIENT_DTL_R failing.
  Chandra    21/06/24 Added v_customer_msa_code_r,v_customer_msa_name_r
  Joe        17/02/26  Audit Control Code as part of reconcilation between EDW and RPT.
  Rose		 10/03/26   Commenting prc_upd_del_data and adding PKG_GRP_COMMON_UTIL.
  Samba      09/05/26 Kill/Fill Changes: User Story - 514602
						- All code changes are marked with Kill/Fill start and end comment blocks.
						- Code changes ensure continuous data availability in reports, replacing the current truncate-and-load approach, which is not partition-exchange based.
						- Retaining old code base of bulk collect load; which can be used when this Package to be converted to incremental processing

  ***********************************************************************/

--Global Constants
gc_rpt_table_name      	VARCHAR2(50)      	:='RPT_CLIENT_DTL_R';
gd_fic_mis_date         DATE;
gc_rebuild_idx_degree	PLS_INTEGER      	:=8;
gv_rpt_table_name   	CONSTANT PRCS_JOB_LOG_R.V_JOB_NAME_R%TYPE := 'RPT_CLIENT_DTL_R';
gv_exg_table_name   	CONSTANT PRCS_JOB_LOG_R.V_JOB_NAME_R%TYPE :=  gv_rpt_table_name||'_EXG';
gv_schema_owner     	CONSTANT PRCS_JOB_LOG_R.V_JOB_NAME_R%TYPE := 'ATOMIC';
gt_start_time_r			TIMESTAMP;
gt_end_time_r			TIMESTAMP;
gn_run_cnt 				NUMBER;

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
    /*gc_trcmsg:=gc_trcmsg||'3.2 Get First Day Date of the current month'||chr(13);
	--Get First Day Date of the current month
    SELECT TRUNC(gd_sysdate, 'MONTH') INTO ld_first_day_date
    FROM dual;
    gc_trcmsg:=gc_trcmsg||'3.3 First Day Date of the current month is:->'||ld_first_day_date||chr(13);
	--If First Day date of current month is sysdate then delete all the data as reload is going to happen for Current , Prior and past 6 history months data
    IF TRUNC(ld_first_day_date) =TRUNC(gd_sysdate) THEN
	    --Today is first day of the current month hence Updating v_rpt_active_status_r=N against the records loaded in prior month
   	    gc_trcmsg:=gc_trcmsg||'3.4 Today is first day of the current month hence Updating v_rpt_active_status_r=N against the records loaded in prior month'||CHR(13);
        UPDATE rpt_client_dtl_r
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
    UPDATE rpt_client_dtl_r
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
lc_tbl VARCHAR2(30):='RPT_CLIENT_DTL_R';
LC_REBUILD_INDEX varchar2(300);
BEGIN
   gc_trcmsg:=gc_trcmsg||'3.7.1 Entered into prc_trunc_partition :->'||'ALTER TABLE '||lc_tbl||' TRUNCATE PARTITION '||'PART_'||lc_tbl||'_'||gn_current_month||CHR(13);
   execute immediate 'ALTER TABLE '||lc_tbl||' TRUNCATE PARTITION '||'PART_'||lc_tbl||'_'||gn_current_month;
  gc_trcmsg:=gc_trcmsg||'3.7.2 Truncate Partition completed'||chr(13);
  gc_trcmsg:=gc_trcmsg||'3.7.3 Rebuild Unusable PK Index starts'||chr(13);
  FOR I IN
  (SELECT 'ALTER INDEX '
    ||INDEX_NAME
    ||' REBUILD parallel 16 nologging' REBUILD_INDEX
  FROM ALL_INDEXES
  WHERE TABLE_NAME ='RPT_CLIENT_DTL_R'
  --AND INDEX_NAME LIKE 'PK_%'
  AND STATUS='UNUSABLE'
  )
  LOOP
    LC_REBUILD_INDEX:=I.REBUILD_INDEX;
    EXECUTE IMMEDIATE LC_REBUILD_INDEX;
  END LOOP;
  GC_TRCMSG:=GC_TRCMSG||'3.7.4 Rebuild Unusable PK Index ends'||CHR(13);
  gc_trcmsg:=gc_trcmsg||'3.7.z Exit from prc_trunc_partition'||CHR(13);
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
IS
VAR_REF_CUR SYS_REFCURSOR;
TYPE var_tbl_type IS TABLE OF RPT_CLIENT_DTL_R%ROWTYPE INDEX BY BINARY_INTEGER;
lt_var_tbl_typ var_tbl_type;
ln_rec_cnt NUMBER:=0;
lc_main_entity  VARCHAR(20):= 'CLIENT_DTL';
ld_fic_mis_date_2 DATE;
ln_fisc_current_month NUMBER;
lc_partitioned varchar(10); -- Kill fill process commenting
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
    PKG_GRP_LOAD_RPT_CLIENT_DTL_R.prc_upd_del_data;
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
	/*PKG_GRP_COMMON_UTIL.prc_trunc_partition
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

			END IF;*/

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

 	--gc_trcmsg:=gc_trcmsg||'3.A. Call procedure prc_rebuild_indexes after truncating partition from main'||chr(13);
    --PKG_GRP_LOAD_RPT_CLIENT_DTL_R.prc_rebuild_indexes;
    --gc_trcmsg:=gc_trcmsg||'3.A.z Completed Procedure prc_rebuild_indexes after truncating partition call from main'||chr(13);

	---Call prc_get_cur_data to get the latest data and perform ref_cursor assignment.
	PKG_GRP_LOAD_RPT_CLIENT_DTL_R.prc_get_cur_data; /* Added as part of Kill/Fill Process : 5th May 2026 	 */

	-- Start: commented as part of Kill/Fill Process : 5th May 2026 ZONE
	/*gc_trcmsg:=gc_trcmsg||'4. Call prc_get_cur_data to get ref_cursor '||chr(13);
    PKG_GRP_LOAD_RPT_CLIENT_DTL_R.prc_get_cur_data (var_ref_cur);
    gc_trcmsg:=gc_trcmsg||'4.z Completed Call Procedure prc_get_cur_data to get ref_cursor'||chr(13);
    gc_trcmsg:=gc_trcmsg||'5 data load starts '||chr(13);
	ln_rec_cnt:=0;
    LOOP
	lt_var_tbl_typ.DELETE;
    FETCH var_ref_cur BULK COLLECT INTO  lt_var_tbl_typ LIMIT gn_bulk_coll_cnt;
     FORALL x in lt_var_tbl_typ.First..lt_var_tbl_typ.Last
     INSERT /*+APPEND_VALUES*/ /*INTO RPT_CLIENT_DTL_R VALUES lt_var_tbl_typ(x) ;
	 ln_rec_cnt:=ln_rec_cnt+lt_var_tbl_typ.COUNT;
	 COMMIT;
     EXIT WHEN var_ref_cur%NOTFOUND;
    END LOOP;
    CLOSE var_ref_cur;--23-Jan-2024 Changes
	 /*Audit Control Code*/
   -- gn_target_count :=ln_rec_cnt;
   /*Audit Control Code*/


    /*gc_trcmsg:=gc_trcmsg||'5.z Data Loaded '||ln_rec_cnt||' records '||chr(13);
 	gc_trcmsg:=gc_trcmsg||'6. Call procedure prc_insert_dummy_rec from main'||chr(13);
    PKG_GRP_LOAD_RPT_CLIENT_DTL_R.prc_insert_dummy_rec;
    gc_trcmsg:=gc_trcmsg||'6.z Completed Procedure prc_insert_dummy_rec call from main'||chr(13);
 	gc_trcmsg:=gc_trcmsg||'7. Call procedure unusable prc_rebuild_indexes from main'||chr(13);*/
    -- End: commented as part of Kill/Fill Process : 5th May 2026 : Commenting this part

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

	PKG_GRP_LOAD_RPT_CLIENT_DTL_R.prc_rebuild_indexes;

    gc_trcmsg:=gc_trcmsg||'7.z Completed Procedure unusable prc_rebuild_indexes call from main'||chr(13);
 	--gc_trcmsg:=gc_trcmsg||'8. Gather RPT_CLIENT_DTL_R table stats from main'||chr(13);
    --DBMS_STATS.GATHER_TABLE_STATS('ATOMIC','RPT_CLIENT_DTL_R');
    --gc_trcmsg:=gc_trcmsg||'8.z Completed Gather RPT_CLIENT_DTL_R table stats from main'||chr(13);

	/*Audit Control Code*/

	gv_trcmsg :='8. Audit Control Procedure execution as Part of reconcilation between EDW and RPT';
        --gn_target_count :=22311;

	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
            (    p_job_id_r                    => gn_out_job_id
				,p_batch_id_r                  => gn_sysdt_batchid
				,p_message_type_r              => gv_message_type
				,p_code_location_r             => gc_main_loadedby
				,p_message_r                   => gv_trcmsg
				,p_count_type_r                => 'Control Procedure'
				,p_count_r                     => gn_target_count
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
		--(p_out_cursor OUT SYS_REFCURSOR)  Commented as part of Kill/Fill process 09 May'26
AS
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

	   --Open/Assign SELECT stmnt   Commented as part of Kill/Fill process 09 May'26
       -- OPEN p_out_cursor FOR		Commented as part of Kill/Fill process 09 May'26

	INSERT /*+ APPEND PARALLEL(stg, 8) */ INTO RPT_CLIENT_DTL_R_EXG stg
		SELECT
		--20-06-24 CHANGE start
		DISTINCT
		--20-06-24 CHANGE END
		dim_grp_carrier_r.v_short_name_r                                              v_short_name_r
		,dim_grp_carrier_r.v_carrier_name_r                                           v_carrier_name_r
		,dim_grp_carrier_r.v_source_system_name_r                                     v_carrier_source_system_name_r
		,dim_grp_carrier_r.v_company_code_r                                           v_company_code_r
		,dim_grp_customer_r.v_active_status_r                                         v_active_status_r
		,dim_grp_customer_r.v_customer_number_r                                       v_customer_number_r
		,Case when dim_grp_customer_r.n_national_account_indicator_r = 1
		  THEN 1 else 0 end                                                           n_national_account_indicator_r
		,dim_grp_field_office_r.v_field_office_name_r                                 v_field_office_name_r
		,dim_grp_party_dir_r.v_party_type_r                                           v_party_dir_party_type_r
		,dim_grp_party_dir_r.v_source_system_name_r                                   v_party_dir_source_system_name_r
		,dim_grp_party_dir_r.v_rso_abbrev_r                                           v_rso_abbrev_r
		,dim_grp_party_r.v_primary_email_address_r                                    v_primary_email_address_r
		,/*select distinct case  when upper(T1655484.V_POSITION_TYPE_R) not in ('TERMINATE') and upper(T1655577.V_DESCRIPTION_R) = 'CORRESPONDENT' then concat(concat(T1656493.V_INDIVIDUAL_FIRST_NAME_R, ' '), T1656493.V_INDIVIDUAL_LAST_NAME_R) end  as c1
          from
               (
                    DIM_GRP_PARTY_R T1656493 -- D_GRP_PARTY_R_Party --  left outer join DIM_GRP_ENTITYPOSITIONS_R T1655484 -- D_GRP_ENTITYPOSITIONS_R_Client
					--  On T1655484.N_PARTY_SK_R = T1656493.N_PARTY_SK_R and T1655484.N_VERSION_NUMBER_R = T1656493.N_SOURCE_VERSION_NUMBER_R) left outer join DIM_GRP_CORRESPONDENT_R T1655577 -- D_GRP_CORRESPONDENT_R_Client --
					On T1655577.N_CUST_PARTY_SK_R = T1656493.N_PARTY_SK_R and T1655577.N_VERSION_NUMBER_R = T1656493.N_SOURCE_VERSION_NUMBER_R

          T1656493 =  DIM_GRP_PARTY_R
                    T1655577 = DIM_GRP_CORRESPONDENT_R
          T1655484 =  DIM_GRP_ENTITYPOSITIONS_R
          */
        CAST(NULL AS VARCHAR2(100))                                            v_client_correspondent_name_r--temp fix
		  ,dim_grp_party_r.v_individual_or_org_ind_r                                  v_individual_or_org_ind_r
		  /*
		  CASE WHEN dim_grp_party_r.v_individual_or_org_ind_r = 'O'
		  THEN dim_grp_party_r.v_individual_last_name_r
		  WHEN dim_grp_party_r.v_individual_or_org_ind_r = 'I'
		  THEN dim_grp_party_r.v_individual_first_name_r || ' ' || dim_grp_party_r.v_individual_last_name_r
		  ELSE  NULL
		  END                                                                        v_individual_last_name_r
		  */ --old logic
		,CASE
         WHEN dim_grp_party_r.v_individual_or_org_ind_r = 'O'
         THEN TRIM(dim_grp_party_r.v_individual_last_name_r)
         WHEN dim_grp_party_r.v_individual_or_org_ind_r = 'I'
         THEN TRIM(dim_grp_party_r.v_individual_first_name_r || ' ' || dim_grp_party_r.v_individual_last_name_r)
         ELSE NULL
         END AS v_individual_last_name_r
		 ,CASE  WHEN dim_grp_party_r.v_individual_or_org_ind_r = 'O'
		 THEN dim_grp_party_r.v_master_customer_name_r
         ELSE NULL
		 END                                                                         v_master_customer_name_r
		,dim_grp_party_r.v_master_customer_num_r                                     v_master_customer_num_r
		,dim_grp_party_r.v_party_type_r                                              v_party_type_r
		,dim_grp_party_r.v_source_system_name_r                                      v_source_system_name_r
		,dim_grp_party_r.v_sic_codes_r                                               v_sic_codes_r
		,dim_grp_party_dir_r.n_party_sk_r                                            n_cust_party_sk_r
		,fct_grp_party_address_r_main.v_address_type_r                               v_address_type_r
		,fct_grp_party_address_r_main.v_party_type_r                                 v_party_address_party_type_r
		,fct_grp_party_address_r_main.v_addressline1_r                               v_addressline1_r
		,fct_grp_party_address_r_main.v_addressline2_r                               v_addressline2_r
		,fct_grp_party_address_r_main.v_city_r                                       v_city_r
		,fct_grp_party_address_r_main.v_country_r                                    v_country_r
		,fct_grp_party_address_r_main.v_state_name_r                                 v_client_state_main_r
		,fct_grp_party_address_r_main.v_postal_zip_r                                 v_client_zip_code_r
		,fct_grp_party_address_r_situs.v_state_name_r                                v_situs_state_r
		,fct_grp_party_address_r_main.v_location_id_r                                v_location_id_r--use " Main: filter - might need to add separate for situs - TBD
		,fct_grp_party_address_r_main.n_primary_location_r                           n_primary_location_r
		,dim_grp_party_r.v_sic_category_r                                            v_sic_category_r
		,dim_grp_party_r.v_sic_desc_r                                                v_sic_desc_r
		,dim_grp_customer_r.v_id_code_r                                              v_client_id_r
		--,OV_FCT_GRP_PARTY_ADD_CUST_STATE.v_state_name_r                            V_MASTER_CUSTOMER_STATE_R
		,CAST(NULL AS VARCHAR2(100))                                                      v_master_customer_state_r --Populate null temporarily
		--,OV_NSOCONTACT_R.V_NSO_DESCRIPTION_R                                       V_NSO_CONTACT_NAME_R
		--,CAST(NULL AS VARCHAR2(100))                                                      v_nso_contact_name_r      --Populate null temporarily - required column is not in PROD.
		,OV_NSOCONTACT_R.V_NSO_DESCRIPTION_R                                       V_NSO_CONTACT_NAME_R
		,fct_grp_party_address_r_situs.v_addressline1_r                              v_situs_address_line1_r
		,fct_grp_party_address_r_situs.v_addressline2_r                              v_situs_address_line2_r
        ,fct_grp_party_address_r_situs.v_city_r                                      v_situs_city_r
		,fct_grp_party_address_r_situs.v_postal_zip_r                                v_situs_zip_code_r
		,dim_grp_party_r.v_ieb_ind_r                                                 v_ieb_type_r
		,gc_main_loadedby                                                            v_last_modified_by_r
		--,n_sequence_number_r
		,gd_sysdate                                                                  t_creation_date_r
		,gc_main_loadedby                                                            v_created_by_r
		,gd_sysdate                                                                  t_last_modified_date_r
		,gn_current_month                                                            n_yearmonth_r
		,dim_grp_party_dir_r.v_active_status_r                                       v_rpt_active_status_r
		,gn_sysdt_batchid                                                            n_batch_id_r
        --20-Feb-2024 changes starts
		,stg_rso_to_region_r.v_regional_avp_name_r                                   v_regional_avp_name_r        --19-mar-2024 changes
		,stg_rso_to_region_r.v_regional_vp_group_r                                   v_regional_vp_group_r        --19-mar-2024 changes
		,stg_rso_to_region_r.v_regional_vp_name_r                                    v_regional_vp_name_r         --19-mar-2024 changes
		,stg_rso_to_region_r.v_regional_vp_title_r                                   v_regional_vp_title_r        --19-mar-2024 changes
		,dim_grp_field_office_r.v_code_r                                             v_rso_code_r                 --19-mar-2024 changes
		,dim_grp_field_office_r.v_rsl_location_code_r                                v_rso_location_code_r        --19-mar-2024 changes
		,dim_grp_field_office_r.v_field_office_name_r                                v_rso_name_r                 --19-mar-2024 changes
		,dim_grp_field_office_r.v_regional_office_number_r                           v_rso_number_r               --19-mar-2024 changes
		,stg_rso_to_region_r.v_region_name_r                                         v_rso_region_name_r          --19-mar-2024 changes
		,stg_rso_to_region_r.v_region_short_name_r                                   v_rso_region_short_name_r    --19-mar-2024 changes
        --20-Feb-2024 changes ends
		,(case  when dim_grp_customer_r.V_SSN_FEIN_INDICATOR_R = 'FEIN'
		  then LPAD(dim_grp_customer_r.N_FEDERAL_EMPLOYER_NO_R, 9, '0')
		  else null
		  end
		  )                                                                          V_EMPLOYER_TAX_ID_R --19-Mar-2024 changes
		  --21-06-24-changes start
		  ,T1011891.V_MSA_R                                           v_customer_msa_code_r
		  ,T1011891.V_MSA_NAME_R                                        v_customer_msa_name_r
		  		  --21-06-24-changes end
		FROM
		atomic.dim_grp_party_dir_r  dim_grp_party_dir_r
		INNER JOIN atomic.dim_grp_party_r  dim_grp_party_r
		ON dim_grp_party_dir_r.n_party_sk_r = dim_grp_party_r.n_party_sk_r
		AND dim_grp_party_dir_r.n_source_version_number_r = dim_grp_party_r.n_source_version_number_r
		INNER JOIN atomic.dim_grp_customer_r  dim_grp_customer_r
		ON dim_grp_customer_r.n_cust_party_sk_r = dim_grp_party_dir_r.n_party_sk_r
		LEFT JOIN atomic.dim_grp_carrier_r  dim_grp_carrier_r
		ON dim_grp_carrier_r.n_carrier_sk_r = dim_grp_customer_r.n_carrier_sk_r
		AND dim_grp_carrier_r.v_active_status_r = 'Y'
		LEFT JOIN atomic.dim_grp_field_office_r  dim_grp_field_office_r
		ON dim_grp_field_office_r.v_code_r = dim_grp_party_dir_r.v_rso_abbrev_r
		AND dim_grp_field_office_r.v_active_status_r = 'Y'
		LEFT JOIN (SELECT *
					 FROM atomic.fct_grp_party_address_r
					WHERE v_location_id_r = 'MAIN'
					  AND v_party_type_r = 'CUSTOMER'
				  ) fct_grp_party_address_r_main
		ON fct_grp_party_address_r_main.n_party_sk_r = dim_grp_party_dir_r.n_party_sk_r
		AND fct_grp_party_address_r_main.n_source_version_number_r = dim_grp_party_dir_r.n_source_version_number_r
        --19-Mar-2024 changes starts
		left join atomic.stg_rso_to_region_r
        on stg_rso_to_region_r.v_rsl_loc_code_r = dim_grp_field_office_r.v_rsl_location_code_r
        and  dim_grp_field_office_r.v_active_status_r = 'Y'
        --19-Mar-2024 changes ends
		LEFT JOIN (SELECT *
					 FROM atomic.fct_grp_party_address_r  z
					WHERE z.v_location_id_r = 'Situs'
					  AND z.v_party_type_r = 'CUSTOMER'
					  AND z.n_source_version_seq_number_r = (SELECT MAX(N_SOURCE_VERSION_SEQ_NUMBER_R)
															   FROM atomic.fct_grp_party_address_r  y
															  WHERE z.n_party_sk_r = y.n_party_sk_r
																AND y.V_LOCATION_ID_R = 'Situs'
																AND y.V_PARTY_TYPE_R = 'CUSTOMER'
																AND z.N_SOURCE_VERSION_NUMBER_R = y.N_SOURCE_VERSION_NUMBER_R)
															) fct_grp_party_address_r_situs
		ON fct_grp_party_address_r_situs.n_party_sk_r = dim_grp_party_dir_r.n_party_sk_r
		AND fct_grp_party_address_r_situs.n_source_version_number_r = dim_grp_party_dir_r.n_source_version_number_r
		left outer join atomic.STG_CMSA_R  T1011891 /* D_CMSA_INSURED */  On T1011891.v_zip_code_r = substr(fct_grp_party_address_r_situs.V_POSTAL_ZIP_R , 1 , 5)
		LEFT JOIN (Select * from ATOMIC.DIM_GRP_NSOCONTACT_R  A where  A.V_ACTIVE_STATUS_R = 'Y'
		and n_source_version_seq_number_r = (select max(n_source_version_seq_number_r)
		from ATOMIC.DIM_GRP_NSOCONTACT_R  B where B.V_ACTIVE_STATUS_R = 'Y'
		and  A.N_CUST_PARTY_SK_R = B.N_CUST_PARTY_SK_R and A.N_VERSION_NUMBER_R = B.N_VERSION_NUMBER_R )) OV_NSOCONTACT_R
        ON dim_grp_party_dir_r.n_party_sk_r = OV_NSOCONTACT_R.N_CUST_PARTY_SK_R
        AND dim_grp_party_dir_r.n_source_version_number_r = OV_NSOCONTACT_R.N_VERSION_NUMBER_R
		and OV_NSOCONTACT_R.V_ACTIVE_STATUS_R = 'Y'
		WHERE dim_grp_party_dir_r.v_active_status_r = 'Y'
		AND dim_grp_party_r.v_active_status_r = 'Y'
		AND dim_grp_customer_r.v_active_status_r = 'Y'
		AND dim_grp_party_dir_r.v_party_type_r = 'CUSTOMER'
		AND dim_grp_party_dir_r.v_source_system_name_r = 'PACS'
		--fetch first 2000 rows ONLY
		;

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

--Procedure to insert dummy record in the table RPT_CLIENT_DTL_R
PROCEDURE prc_insert_dummy_rec
IS
BEGIN
    gc_trcmsg:=gc_trcmsg||'6.1 Entered into from prc_insert_dummy_rec'||chr(13);
     INSERT /*+APPEND*/ INTO  RPT_CLIENT_DTL_R
		   (
		    v_last_modified_by_r
           ,t_creation_date_r
           ,v_created_by_r
           ,t_last_modified_date_r
           ,n_yearmonth_r
           ,v_rpt_active_status_r
           ,n_batch_id_r
		   ,n_cust_party_sk_r
		   )
    VALUES(gc_main_loadedby
		  ,gd_sysdate
		  ,gc_main_loadedby
		  ,gd_sysdate
		  ,gn_current_month
		  ,'Y'
		  ,gn_sysdt_batchid
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
            ,gc_getcur_loadedby             --p_log_util_called_by_r
          );
    RAISE;
END prc_insert_dummy_rec;

--Procedure to rebuild indexes RPT_CLIENT_DTL_R
PROCEDURE prc_rebuild_indexes
IS
LC_REBUILD_INDEX  VARCHAR2(300);
BEGIN
   gc_trcmsg:=gc_trcmsg||'7.a Entered into prc_rebuild_indexes'||chr(13);
  FOR I IN ( select
    'ALTER INDEX '||INDEX_NAME||' REBUILD parallel 16 nologging' REBUILD_INDEX
    from ALL_INDEXES  where TABLE_NAME ='RPT_CLIENT_DTL_R'
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

END PKG_GRP_LOAD_RPT_CLIENT_DTL_R;
/

