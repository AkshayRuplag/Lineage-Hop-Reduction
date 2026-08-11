

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ATOMIC"."PKG_GRP_LOAD_RPT_WORKSHEET_DTL_R"
IS
/***********************************************************************
  Purpose:  This package body contains procedures which loads data into RPT_WORKSHEET_DTL_R
  Used DB objects : RPT_WORKSHEET_DTL_R,FCT_GRP_WORKSHEET,SEQ_RPT_WORKSHEET_DTL_R,
  Author     Date     Description
  ---------- -------- -------------------------------------------------
  VGireesh   10/11/23 Initial Creation
  VGireesh   18/01/24 Added procedure prc_rebuild_indexes
  VGireesh   23/01/24 Closed REF Cursor
  VGireesh   26/02/24 for month end  that the tables start loading data in the next month partition
                      Ex: March data on February 29th (as of 2.28).
                          27th is Feb Fisc Month End    202402  should be truncate and load in 202402 partition
                          28th is feb Fisc Month End +1 202402  should be truncate and load in 202402 partition
                          29th is Feb Fisc Month End +2 202403  should inactive records against the partition 202402 and load data in 202403 partition
  VGireesh   03/04/24 Added Parallel to rebuild index fast  parallel 16 nologging
  Rose		 10/03/26   Commenting prc_upd_del_data and adding PKG_GRP_COMMON_UTIL.
  ***********************************************************************/

--Global Constants
gc_rpt_table_name      	VARCHAR2(50)      	:='RPT_WORKSHEET_DTL_R';
gd_fic_mis_date          DATE;
gc_rebuild_idx_degree	PLS_INTEGER      	:=8;

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
        UPDATE RPT_WORKSHEET_DTL_R
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
  FROM DIM_TIME_R D
  WHERE V_END_OF_FISCAL_MONTH_IND_R      = 'Y'
  AND TO_CHAR(D_CALENDAR_DATE_R,'YYYYMM')=TO_CHAR(sysdate,'YYYYMM');
  gc_trcmsg                             :=gc_trcmsg||'3.2 Fisc Month End +2 Day Date of the current month is:->'||ld_fic_mis_date_2||chr(13);
  gc_trcmsg                             :=gc_trcmsg||'3.3 Fisc Current Month of the current month is:->'||ln_fisc_current_month||chr(13);
  IF TRUNC(ld_fic_mis_date_2)            =TRUNC(sysdate) THEN
    ln_fisc_prior_month                 :=to_number(TO_CHAR(ld_fic_mis_date_2,'YYYYMM'));
    gc_trcmsg                           :=gc_trcmsg||'3.3.1 Fisc Prior Month of the current month is:->'||ln_fisc_prior_month||chr(13);
    gc_trcmsg                           :=gc_trcmsg||'3.4 Today Fisc Month End +2 '||ld_fic_mis_date_2||' hence Updating v_rpt_active_status_r=N against the records loaded in prior fisc month which is :->'||ln_fisc_prior_month||CHR(13);
    UPDATE RPT_WORKSHEET_DTL_R
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
lc_tbl VARCHAR2(30):='RPT_WORKSHEET_DTL_R';
lc_rebuild_index VARCHAR2(300);
BEGIN
   gc_trcmsg:=gc_trcmsg||'3.7.1 Entered into prc_trunc_partition :->'||'ALTER TABLE '||lc_tbl||' TRUNCATE PARTITION '||'PART_'||lc_tbl||'_'||gn_current_month||CHR(13);
   execute immediate 'ALTER TABLE '||lc_tbl||' TRUNCATE PARTITION '||'PART_'||lc_tbl||'_'||gn_current_month;
   gc_trcmsg:=gc_trcmsg||'3.7.2 Truncate Partition completed'||chr(13);
   gc_trcmsg:=gc_trcmsg||'3.7.3 Rebuild PK Index starts'||chr(13);
  FOR I IN ( select
    'ALTER INDEX '||INDEX_NAME||' REBUILD  parallel 16 nologging' REBUILD_INDEX
    from ALL_INDEXES  where TABLE_NAME ='RPT_SALES_REP_R'
	and INDEX_NAME  like 'PK_%'
	AND STATUS='UNUSABLE'
	)
  LOOP
    LC_REBUILD_INDEX:=I.REBUILD_INDEX;
    EXECUTE IMMEDIATE LC_REBUILD_INDEX;
  end LOOP;
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
IS
VAR_REF_CUR SYS_REFCURSOR;
TYPE var_tbl_type IS TABLE OF RPT_WORKSHEET_DTL_R%ROWTYPE INDEX BY BINARY_INTEGER;
lt_var_tbl_typ var_tbl_type;
ln_rec_cnt NUMBER:=0;
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
    PKG_GRP_LOAD_RPT_WORKSHEET_DTL_R.prc_upd_del_data;
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

			PKG_GRP_COMMON_UTIL.prc_trunc_partition
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

				END IF;

    gc_trcmsg:=gc_trcmsg||'4. Call prc_get_cur_data to get ref_cursor '||chr(13);
    PKG_GRP_LOAD_RPT_WORKSHEET_DTL_R.prc_get_cur_data (var_ref_cur);
    gc_trcmsg:=gc_trcmsg||'4.z Completed Call Procedure prc_get_cur_data to get ref_cursor'||chr(13);
    gc_trcmsg:=gc_trcmsg||'5 data load starts '||chr(13);
	ln_rec_cnt:=0;
    LOOP
	lt_var_tbl_typ.DELETE;
    FETCH var_ref_cur BULK COLLECT INTO  lt_var_tbl_typ LIMIT gn_bulk_coll_cnt;
     FORALL x in lt_var_tbl_typ.First..lt_var_tbl_typ.Last
     INSERT /*+APPEND_VALUES*/ INTO RPT_WORKSHEET_DTL_R VALUES lt_var_tbl_typ(x) ;
	 ln_rec_cnt:=ln_rec_cnt+lt_var_tbl_typ.COUNT;
	 COMMIT;
     EXIT WHEN var_ref_cur%NOTFOUND;
    END LOOP;
    CLOSE var_ref_cur;--23-Jan-2024 Changes
    gc_trcmsg:=gc_trcmsg||'5.z Data Loaded '||ln_rec_cnt||' records '||chr(13);
 	gc_trcmsg:=gc_trcmsg||'6. Call procedure prc_insert_dummy_rec from main'||chr(13);
    PKG_GRP_LOAD_RPT_WORKSHEET_DTL_R.prc_insert_dummy_rec;
    gc_trcmsg:=gc_trcmsg||'6.z Completed Procedure prc_insert_dummy_rec call from main'||chr(13);
 	gc_trcmsg:=gc_trcmsg||'7. Call procedure unusable prc_rebuild_indexes from main'||chr(13);
    PKG_GRP_LOAD_RPT_WORKSHEET_DTL_R.prc_rebuild_indexes;
    gc_trcmsg:=gc_trcmsg||'7.z Completed Procedure unusable prc_rebuild_indexes call from main'||chr(13);
 	--gc_trcmsg:=gc_trcmsg||'8. Gather RPT_WORKSHEET_DTL_R table stats from main'||chr(13);
    --DBMS_STATS.GATHER_TABLE_STATS('ATOMIC','RPT_WORKSHEET_DTL_R');
    --gc_trcmsg:=gc_trcmsg||'8.z Completed Gather RPT_WORKSHEET_DTL_R table stats from main'||chr(13);
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
PROCEDURE prc_get_cur_data(
    p_out_cursor OUT SYS_REFCURSOR
	)
AS
BEGIN
       gc_trcmsg:=gc_trcmsg||'4.1 Entered into prc_get_cur_data '||chr(13);
	   --Open/Assign SELECT stmnt
        OPEN p_out_cursor FOR
        select
          SEQ_RPT_WORKSHEET_DTL_R.NEXTVAL                            N_WORKSHEET_SK_R  --FCT_GRP_WORKSHEET	n/a Derive sequence number
         ,FCT_GRP_WORKSHEET.N_GROSS_BENEFIT_R                        N_GROSS_BENEFIT_R
         ,FCT_GRP_WORKSHEET.N_RPT_NET_BENEFIT_R                      N_WS_NET_BENEFIT_R
         ,FCT_GRP_WORKSHEET.V_RPT_WORKSHEET_INDICATOR_R              V_WORKSHEET_INDICATOR_R
         ,FCT_GRP_WORKSHEET.N_VERSION_R                              N_WORKSHEET_NUMBER_R
         ,TO_DATE(SUBSTR(FCT_GRP_WORKSHEET.D_START_DATE_R,1,9))      D_WORKSHEET_START_DATE_R
         ,FCT_GRP_WORKSHEET.V_WORKSHEET_STATUS_R                     V_WORKSHEET_STATUS_R
         ,FCT_GRP_WORKSHEET.N_WORKSHEET_SEQ_NBR_OBJECTNM_R           N_WORKSHEET_SEQ_NBR_OBJECTNM_R
         ,TO_DATE(SUBSTR(FCT_GRP_WORKSHEET.D_END_DATE_R,1,9))        D_WORKSHEET_END_DATE_R
 		,gc_main_loadedby                                            v_last_modified_by_r
		--,n_sequence_number_r
		,gd_sysdate                                                  t_creation_date_r
		,gc_main_loadedby                                            v_created_by_r
		,gd_sysdate                                                  t_last_modified_date_r
		,gn_current_month                                            n_yearmonth_r
		,'Y'                                                         v_rpt_active_status_r
		,gn_sysdt_batchid                                            n_batch_id_r
		,n_worksheet_src_sys_key_r                                   n_worksheet_src_sys_key_r
       from FCT_GRP_WORKSHEET FCT_GRP_WORKSHEET
        where FCT_GRP_WORKSHEET.V_RPT_WORKSHEET_INDICATOR_R = 'Y';
    gc_trcmsg:=gc_trcmsg||'4.2 Exit from prc_get_cur_data'||chr(13);
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

--Procedure to insert dummy record in the table RPT_WORKSHEET_DTL_R
PROCEDURE prc_insert_dummy_rec
IS
BEGIN
    gc_trcmsg:=gc_trcmsg||'6.1 Entered into from prc_insert_dummy_rec'||chr(13);
     INSERT /*+APPEND*/ INTO  RPT_WORKSHEET_DTL_R
		   (
		    v_last_modified_by_r
           ,t_creation_date_r
           ,v_created_by_r
           ,t_last_modified_date_r
           ,n_yearmonth_r
           ,v_rpt_active_status_r
           ,n_batch_id_r
		   ,n_worksheet_sk_r
		   )
    VALUES(gc_main_loadedby
		  ,gd_sysdate
		  ,gc_main_loadedby
		  ,gd_sysdate
		  ,gn_current_month
		  ,'Y'
		  ,gn_sysdt_batchid
          ,-1           --N_WORKSHEET_SK_R
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

--Procedure to rebuild indexes RPT_WORKSHEET_DTL_R
PROCEDURE prc_rebuild_indexes
IS
LC_REBUILD_INDEX  VARCHAR2(300);
BEGIN
   gc_trcmsg:=gc_trcmsg||'7.a Entered into prc_rebuild_indexes'||chr(13);
  FOR I IN ( select
    'ALTER INDEX '||INDEX_NAME||' REBUILD  parallel 16 nologging' REBUILD_INDEX
    from ALL_INDEXES  where TABLE_NAME ='RPT_WORKSHEET_DTL_R'
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
end PKG_GRP_LOAD_RPT_WORKSHEET_DTL_R;

