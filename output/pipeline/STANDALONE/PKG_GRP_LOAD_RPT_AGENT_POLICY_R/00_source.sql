

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ATOMIC"."PKG_GRP_LOAD_RPT_AGENT_POLICY_R"
IS
  /***********************************************************************
  Purpose:  This package body contains procedures which loads data into RPT_AGENT_POLICY_R
  Dependent SSL tables : RPT_AGENT_POLICY_R
  Used DB Objects:
					DIM_GRP_POLICY_DIR_R
					FCT_GRP_AGENT_POLICY_R_LOOKUP
					DIM_GRP_AGENT_R
					FCT_GRP_PARTY_ADDRESS_R
					STG_PREMIER_PRODUCER_DESC_R
					DIM_GRP_AGENT_DIRECTORY_R
  Author     Date     Description
  ---------- -------- -------------------------------------------------
  VGireesh   28/02/24 Initial Creation
  VGireesh   03/04/24 Added Parallel to rebuild index fast
  Chandra    08/08/24 Logic change for DIM_GRP_AGENT_R join
  Chandra    11/12/24 Added column V_TEMPLATE_NAME_R
  Suresh     15/01/25 Added column N_LAST_RATE_R
  Suresh     21/01/25 Added column V_SALES_PLAN_DESC_R
  Suresh     06/02/25 Added one more joins condition to handle nvl V_SALES_PLAN_DESC_R
  Suresh     20/06/25 Add logic to remove duplicates records from table FCT_GRP_PARTY_ADDRESS_R line 430. as per bug no 411275
  Samba		 18/02/26 Capturing the Target count for Audit COntrols when data is inserting into RPT table using Bulkload limit.
  Rose	     10/03/26 Commenting prc_upd_del_data and adding PKG_GRP_COMMON_UTIL.
  ***********************************************************************/
--Global Constants
gc_rpt_table_name      	VARCHAR2(50)      	:='RPT_AGENT_POLICY_R';
gd_fic_mis_date          DATE;
gc_rebuild_idx_degree	PLS_INTEGER      	:=8;

  --Procedure to update prior month active flag and current month partition
PROCEDURE prc_upd_del_data
IS
  LN_SQLROWCNT      NUMBER;
  LN_CNT            NUMBER;
  ln_fisc_current_month NUMBER;
  ln_fisc_prior_month   NUMBER;
  ld_fic_mis_date_2     DATE;
BEGIN
  gc_trcmsg:=gc_trcmsg||'3.1 Entered into in prc_upd_del_data'||chr(13);
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
    UPDATE RPT_AGENT_POLICY_R
    SET v_rpt_active_status_r='N' ,
      v_last_modified_by_r   =gc_updby ,
      t_last_modified_date_r =gd_sysdate
    WHERE n_reportmonth_r    = ln_fisc_prior_month;
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
  gc_trcmsg:=gc_trcmsg||'3.12 Exit from in prc_upd_del_data'||chr(13);
EXCEPTION
WHEN OTHERS THEN
  gc_errmsg:=SUBSTR(SQLERRM,1,4000);
  gc_trcmsg:=gc_trcmsg||'3.z Error in prc_upd_del_data'||chr(13)||gc_errmsg;
  pkg_grp_log_util.prc_update_log ( gn_out_job_id --p_job_id
  ,gc_error_status                                --p_job_status
  ,gc_errmsg                                      --p_err_msg
  ,gc_trcmsg||chr(13)||gc_errmsg                  --p_trc_msg
  ,gc_updby                                       --p_log_util_called_by_r
  );
  RAISE;
END prc_upd_del_data;
--Procedure to truncate the YEARMONTH partition
PROCEDURE prc_trunc_partition
AS
  LC_TBL           VARCHAR2(30):='RPT_AGENT_POLICY_R';
  LC_REBUILD_INDEX VARCHAR2(300);
BEGIN
  GC_TRCMSG:=GC_TRCMSG||'3.7.1 Entered into prc_trunc_partition :->'||'ALTER TABLE '||LC_TBL||' TRUNCATE PARTITION '||'PART_'||LC_TBL||'_'||GN_CURRENT_MONTH||CHR(13);
  EXECUTE immediate 'ALTER TABLE '||lc_tbl||' TRUNCATE PARTITION '||'PART_'||lc_tbl||'_'||gn_current_month;
  gc_trcmsg:=gc_trcmsg||'3.7.2 Truncate partition completed'||chr(13);
  gc_trcmsg:=gc_trcmsg||'3.7.3 Rebuild PK Index starts'||chr(13);
  FOR I IN
  (SELECT 'ALTER INDEX '
    ||INDEX_NAME
    ||' REBUILD parallel 16 nologging' REBUILD_INDEX
  FROM ALL_INDEXES
  WHERE TABLE_NAME ='RPT_AGENT_POLICY_R'
  AND INDEX_NAME LIKE 'PK_%'
  AND STATUS='UNUSABLE'
  )
  LOOP
    LC_REBUILD_INDEX:=I.REBUILD_INDEX;
    EXECUTE IMMEDIATE LC_REBUILD_INDEX;
  END LOOP;
  gc_trcmsg:=gc_trcmsg||'3.7.z Exit from prc_trunc_partition'||CHR(13);
EXCEPTION
WHEN OTHERS THEN
  gc_errmsg :=SUBSTR(SQLERRM,1,4000);
  gc_trcmsg :=gc_trcmsg||'2.z Error in prc_trunc_partition'||chr(13);
  pkg_grp_log_util.prc_update_log ( gn_out_job_id --p_job_id
  ,gc_error_status                                --p_job_status
  ,gc_errmsg                                      --p_err_msg
  ,gc_trcmsg||chr(13)||gc_errmsg                  --p_trc_msg
  ,gc_truncpartby                                 --p_log_util_called_by_r
  );
  RAISE;
END prc_trunc_partition;
--Main procedures calls other procedure to load data in RPT_CLEINT_DTL_R
PROCEDURE main
IS
  VAR_REF_CUR SYS_REFCURSOR;
TYPE var_tbl_type
IS
  TABLE OF RPT_AGENT_POLICY_R%ROWTYPE INDEX BY BINARY_INTEGER;
  lt_var_tbl_typ var_tbl_type;
  ln_rec_cnt    NUMBER:=0;
  ln_start_time NUMBER;
  lc_trcmsg  varchar(150);
  ld_fic_mis_date_2 DATE;
  ln_fisc_current_month NUMBER;
BEGIN
  --Call Log Util pkg to Insert entry in PRCS_JOB_LOG_R
  pkg_grp_log_util.prc_insert_log ( p_source => gc_source ,p_job_nm => gc_job_name ,p_job_status => gc_running_status ,p_err_msg => NULL ,p_trc_msg => NULL ,p_n_batch_id => gn_sysdt_batchid ,p_log_util_called_by_r=> gc_main_loadedby ,out_job_id => gn_out_job_id );
  gc_trcmsg:=gc_trcmsg||'1. Entered into main'||chr(13);
  gc_trcmsg:=gc_trcmsg||'gn_current_month     :->'||gn_current_month||chr(13);
  gc_trcmsg:=gc_trcmsg||'gn_prior_month       :->'||gn_prior_month||chr(13);
  --gc_trcmsg:=gc_trcmsg||'1.c gn_prior2prior_month :->'||gn_prior2prior_month||chr(13);
  /*gc_trcmsg:=gc_trcmsg||'3. Call procedure prc_upd_del_data from main'||chr(13);
  PKG_GRP_LOAD_RPT_AGENT_POLICY_R.prc_upd_del_data;
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

  gc_trcmsg:=gc_trcmsg||'4. Call prc_get_cur_data to get ref_cursor '||chr(13);
  PKG_GRP_LOAD_RPT_AGENT_POLICY_R.prc_get_cur_data (var_ref_cur);
  gc_trcmsg    :=gc_trcmsg||'4.z Completed Call Procedure prc_get_cur_data to get ref_cursor'||chr(13);
  ln_start_time:=dbms_utility.get_time;
  gc_trcmsg    :=gc_trcmsg||'5 data load starts '||ln_start_time||chr(13);
  ln_rec_cnt   :=0;
  LOOP
    lt_var_tbl_typ.DELETE;
    FETCH var_ref_cur BULK COLLECT INTO lt_var_tbl_typ LIMIT gn_bulk_coll_cnt;
    FORALL X IN LT_VAR_TBL_TYP.first..LT_VAR_TBL_TYP.last
    INSERT /*+APPEND_VALUES*/
    INTO RPT_AGENT_POLICY_R VALUES lt_var_tbl_typ
      (x
      ) ;
    LN_REC_CNT:=LN_REC_CNT+LT_VAR_TBL_TYP.COUNT;
    COMMIT;
    EXIT
  WHEN var_ref_cur%NOTFOUND;
  END LOOP;
  gc_trcmsg:=gc_trcmsg||'5.z Data Loaded '||ln_rec_cnt||' records '||((dbms_utility.get_time - ln_start_time)/100)||chr(13);

  	lc_trcmsg:='1. Target count for Audit control Process';

		/*START: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
			 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
			 (
				p_job_id_r                    => gn_out_job_id,
				p_batch_id_r                  => gn_sysdt_batchid,
				p_message_type_r              => gc_message_type_r,
				p_code_location_r             => gc_main_loadedby,
				p_message_r                   => lc_trcmsg,
				p_count_type_r                => 'AUDIT_TARGET_COUNT',
				p_count_r                     => ln_rec_cnt,
				p_duration_r                  => NULL,
				p_created_by_r                => GC_JOB_NAME,
				out_prcs_job_log_message_id_r => gn_job_log_message_id_r
			);


  ln_start_time:=dbms_utility.get_time;
  gc_trcmsg    :=gc_trcmsg||'7. Call procedure unusable prc_rebuild_indexes from main '||ln_start_time||chr(13);
  PKG_GRP_LOAD_RPT_AGENT_POLICY_R.prc_rebuild_indexes;
  gc_trcmsg:=gc_trcmsg||'7.z Completed Procedure unusable prc_rebuild_indexes call from main '||((dbms_utility.get_time - ln_start_time)/100)||chr(13);
  ln_start_time:=dbms_utility.get_time;
  gc_trcmsg    :=gc_trcmsg||'8. Gather RPT_AGENT_POLICY_R table stats from main '||ln_start_time||chr(13);
  DBMS_STATS.GATHER_TABLE_STATS('ATOMIC','RPT_AGENT_POLICY_R');
  gc_trcmsg:=gc_trcmsg||'8.z Completed Gather RPT_AGENT_POLICY_R table stats from main '||((dbms_utility.get_time - ln_start_time)/100)||chr(13);

  lc_trcmsg:='2. Calling Audit Control Procedure';

		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
		 (
			p_job_id_r                    => gn_out_job_id,
			p_batch_id_r                  => gn_sysdt_batchid,
			p_message_type_r              => gc_message_type_r,
			p_code_location_r             => gc_main_loadedby,
			p_message_r                   => lc_trcmsg,
			p_count_type_r                => NULL,
			p_count_r                     => NULL,
			p_duration_r                  => NULL,
			p_created_by_r                => GC_JOB_NAME,
			out_prcs_job_log_message_id_r => gn_job_log_message_id_r
		);

	PRC_GRP_AUDIT_CONTROL_PROCESS(gc_source,gc_main_entity,gc_source,gc_target);

  gc_trcmsg:=gc_trcmsg||'1.z Exit from main'||chr(13);
  pkg_grp_log_util.prc_update_log ( gn_out_job_id --p_job_id
  ,gc_success_status                              --p_job_status
  ,gc_errmsg                                      --p_err_msg
  ,gc_trcmsg                                      --p_trc_msg
  ,gc_main_loadedby                               --p_log_util_called_by_r
  );
EXCEPTION
WHEN OTHERS THEN
  gc_errmsg :=SUBSTR(SQLERRM,1,4000);
  gc_trcmsg :=gc_trcmsg||'1. Error in main'||chr(13);
  pkg_grp_log_util.prc_update_log ( gn_out_job_id --p_job_id
  ,gc_error_status                                --p_job_status
  ,gc_errmsg                                      --p_err_msg
  ,gc_trcmsg||chr(13)||gc_errmsg                  --p_trc_msg
  ,gc_main_loadedby                               --p_log_util_called_by_r
  );
  RAISE;
END main;
--Procedure to perform ref cursor assignment
PROCEDURE prc_get_cur_data
  (
    p_out_cursor OUT SYS_REFCURSOR
  )
AS
BEGIN
  gc_trcmsg:=gc_trcmsg||'4.1 Entered into prc_get_cur_data '||chr(13);
  --Open/Assign SELECT stmnt
  OPEN p_out_cursor FOR
    -- SQL for RPT_RATES_R
-- SQL for RPT_AGENT_POLICY_R
   SELECT
     -- ADDED
     C.V_FULL_NAME_R V_AGENCY_NAME_R,
     SUBSTR(C.V_AGENT_NUMBER_R,1, 6) V_AGENCY_code_R,
     C.V_FULL_NAME_R V_AGENT_NAME_R,    -- FOR NOW SAME AS #1
     C.V_AGENT_NUMBER_R V_AGENT_CODE_R, -- SAME AS 2 BUT WITHOUT SUBSTRING
     NVL(agent_share.N_RPT_SPLIT_PERCENTAGE_R,1) N_AGENT_SHARE_R,
     agent_share.D_START_DATE_R D_AGENT_SHARE_START_DATE_R,
     agent_share.D_END_DATE_R D_AGENT_SHARE_TERM_DATE_R,
     CASE
       WHEN agent_share.N_RPT_PRIMARY_INDICATOR_R = 'P'
       THEN adr.V_ADDRESSLINE1_R
     END V_PRIMARY_AGENT_ADDRESS_1_R,
     CASE
       WHEN agent_share.N_RPT_PRIMARY_INDICATOR_R = 'P'
       THEN adr.V_ADDRESSLINE2_R
     END V_PRIMARY_AGENT_ADDRESS_2_R,
     CASE
       WHEN agent_share.N_RPT_PRIMARY_INDICATOR_R = 'P'
       THEN adr.v_city_r
     END V_PRIMARY_AGENT_CITY_R,
     CASE
       WHEN agent_share.N_RPT_PRIMARY_INDICATOR_R = 'P'
       THEN C.V_AGENT_NUMBER_R
     END V_PRIMARY_AGENT_CODE_R,
     CASE
       WHEN agent_share.N_RPT_PRIMARY_INDICATOR_R = 'P'
       THEN C.V_FULL_NAME_R
       WHEN agent_share.n_agent_sk_r IS NULL
       THEN 'Unknown'
     END V_PRIMARY_AGENT_NAME_R,
     CASE
       WHEN agent_share.N_RPT_PRIMARY_INDICATOR_R = 'P'
       THEN agent_share.N_RPT_SPLIT_PERCENTAGE_R
       WHEN agent_share.n_agent_sk_r IS NULL
       THEN 1
     END N_PRIMARY_AGENT_SHARE_R,
     CASE
       WHEN agent_share.N_RPT_PRIMARY_INDICATOR_R = 'P'
       THEN adr.V_STATE_NAME_R
     END V_PRIMARY_AGENT_STATE_R,
     CASE
       WHEN agent_share.N_RPT_PRIMARY_INDICATOR_R = 'P'
       THEN adr.V_POSTAL_ZIP_R
     END V_PRIMARY_AGENT_ZIP_R,
     agent_share.N_RPT_PRIMARY_INDICATOR_R AS V_PRIMARY_AGENT_IND_R,
     adr.N_PRIMARY_LOCATION_R              AS V_PRIMARY_LOCATION_R ,
     pd.V_BROKER_DESC_R V_PREMIER_PRODUCER_NAME_R,
     CASE
       WHEN agent_share.N_RPT_PRIMARY_INDICATOR_R                                                                                                            = 'S'
       AND rank() over(partition BY agent_share2.N_POLICY_SK_R, agent_share2. N_RPT_PRIMARY_INDICATOR_R order by agent_share2.N_RPT_SPLIT_PERCENTAGE_R DESC) =1
       THEN adr.V_ADDRESSLINE1_R
     END V_SECONDARY_AGENT_ADDRESS_1_R,
     CASE
       WHEN agent_share.N_RPT_PRIMARY_INDICATOR_R                                                                                                            = 'S'
       AND rank() over(partition BY agent_share2.N_POLICY_SK_R, agent_share2. N_RPT_PRIMARY_INDICATOR_R order by agent_share2.N_RPT_SPLIT_PERCENTAGE_R DESC) =1
       THEN adr.V_ADDRESSLINE2_R
     END V_SECONDARY_AGENT_ADDRESS_2_R,
     CASE
       WHEN agent_share.N_RPT_PRIMARY_INDICATOR_R                                                                                                            = 'S'
       AND rank() over(partition BY agent_share2.N_POLICY_SK_R, agent_share2. N_RPT_PRIMARY_INDICATOR_R order by agent_share2.N_RPT_SPLIT_PERCENTAGE_R DESC) =1
       THEN adr.v_city_r
     END V_SECONDARY_AGENT_CITY_R,
     CASE
       WHEN agent_share.N_RPT_PRIMARY_INDICATOR_R                                                                                                           = 'S'
       AND rank() over(partition BY agent_share2.N_POLICY_SK_R, agent_share2.N_RPT_PRIMARY_INDICATOR_R order by agent_share2.N_RPT_SPLIT_PERCENTAGE_R DESC) =1
       THEN C.V_FULL_NAME_R
     END V_SECONDARY_AGENT_NAME_R,
     CASE
       WHEN agent_share2.N_RPT_PRIMARY_INDICATOR_R                                                                                                          = 'S'
       AND rank() over(partition BY agent_share2.N_POLICY_SK_R, agent_share2.N_RPT_PRIMARY_INDICATOR_R order by agent_share2.N_RPT_SPLIT_PERCENTAGE_R DESC) =1
       THEN agent_share2.N_RPT_SPLIT_PERCENTAGE_R
     END N_SECONDARY_AGENT_SHARE_R,
     CASE
       WHEN agent_share.N_RPT_PRIMARY_INDICATOR_R                                                                                                            = 'S'
       AND rank() over(partition BY agent_share2.N_POLICY_SK_R, agent_share2. N_RPT_PRIMARY_INDICATOR_R order by agent_share2.N_RPT_SPLIT_PERCENTAGE_R DESC) =1
       THEN adr.V_STATE_NAME_R
     END V_SECONDARY_AGENT_STATE_R,
     CASE
       WHEN agent_share.N_RPT_PRIMARY_INDICATOR_R                                                                                                            = 'S'
       AND rank() over(partition BY agent_share2.N_POLICY_SK_R, agent_share2. N_RPT_PRIMARY_INDICATOR_R order by agent_share2.N_RPT_SPLIT_PERCENTAGE_R DESC) =1
       THEN adr.V_POSTAL_ZIP_R
     END V_SECONDARY_AGENT_ZIP_R,
     CASE
       WHEN agent_share.N_RPT_PRIMARY_INDICATOR_R                                                                                                            = 'S'
       AND rank() over(partition BY agent_share2.N_POLICY_SK_R, agent_share2. N_RPT_PRIMARY_INDICATOR_R order by agent_share2.N_RPT_SPLIT_PERCENTAGE_R DESC) =1
       THEN C.V_AGENT_NUMBER_R
     END V_SECONDARY_AGENT_CODE_R,
     CASE
       WHEN agent_share.N_RPT_PRIMARY_INDICATOR_R                                                                                                           = 'S'
       AND rank() over(partition BY agent_share2.N_POLICY_SK_R, agent_share2.N_RPT_PRIMARY_INDICATOR_R order by agent_share2.N_RPT_SPLIT_PERCENTAGE_R DESC) =2
       THEN adr.V_ADDRESSLINE1_R
     END V_TERTIARY_AGENT_ADDRESS_1_R,
     CASE
       WHEN agent_share.N_RPT_PRIMARY_INDICATOR_R                                                                                                           = 'S'
       AND rank() over(partition BY agent_share2.N_POLICY_SK_R, agent_share2.N_RPT_PRIMARY_INDICATOR_R order by agent_share2.N_RPT_SPLIT_PERCENTAGE_R DESC) =2
       THEN adr.V_ADDRESSLINE2_R
     END V_TERTIARY_AGENT_ADDRESS_2_R,
     CASE
       WHEN agent_share.N_RPT_PRIMARY_INDICATOR_R                                                                                                           = 'S'
       AND rank() over(partition BY agent_share2.N_POLICY_SK_R, agent_share2.N_RPT_PRIMARY_INDICATOR_R order by agent_share2.N_RPT_SPLIT_PERCENTAGE_R DESC) =2
       THEN adr.v_city_r
     END V_TERTIARY_AGENT_CITY_R,
     CASE
       WHEN agent_share.N_RPT_PRIMARY_INDICATOR_R                                                                                                           = 'S'
       AND rank() over(partition BY agent_share2.N_POLICY_SK_R, agent_share2.N_RPT_PRIMARY_INDICATOR_R order by agent_share2.N_RPT_SPLIT_PERCENTAGE_R DESC) =2
       THEN C.V_AGENT_NUMBER_R
     END V_TERTIARY_AGENT_CODE_R,
     CASE
       WHEN agent_share.N_RPT_PRIMARY_INDICATOR_R                                                                                                           = 'S'
       AND rank() over(partition BY agent_share2.N_POLICY_SK_R, agent_share2.N_RPT_PRIMARY_INDICATOR_R order by agent_share2.N_RPT_SPLIT_PERCENTAGE_R DESC) =2
       THEN C.V_FULL_NAME_R
     END V_TERTIARY_AGENT_NAME_R,
     CASE
       WHEN agent_share.N_RPT_PRIMARY_INDICATOR_R                                                                                                           = 'S'
       AND rank() over(partition BY agent_share2.N_POLICY_SK_R, agent_share2.N_RPT_PRIMARY_INDICATOR_R order by agent_share2.N_RPT_SPLIT_PERCENTAGE_R DESC) =2
       THEN agent_share.N_RPT_SPLIT_PERCENTAGE_R
     END N_TERTIARY_AGENT_SHARE_R,
     CASE
       WHEN agent_share.N_RPT_PRIMARY_INDICATOR_R                                                                                                           = 'S'
       AND rank() over(partition BY agent_share2.N_POLICY_SK_R, agent_share2.N_RPT_PRIMARY_INDICATOR_R order by agent_share2.N_RPT_SPLIT_PERCENTAGE_R DESC) =2
       THEN adr.V_STATE_NAME_R
     END V_TERTIARY_AGENT_STATE_R,
     CASE
       WHEN agent_share.N_RPT_PRIMARY_INDICATOR_R                                                                                                           = 'S'
       AND rank() over(partition BY agent_share2.N_POLICY_SK_R, agent_share2.N_RPT_PRIMARY_INDICATOR_R order by agent_share2.N_RPT_SPLIT_PERCENTAGE_R DESC) =2
       THEN adr.V_POSTAL_ZIP_R
     END V_TERTIARY_AGENT_ZIP_R,
     a.N_POLICY_SK_R,
     NVL(AGENT_SHARE.N_AGENT_SK_R,-1) AS N_AGENT_SK_R,
     --ADDED
     /*agent_share.N_RPT_SORT_ORDER_R,
     case when agent_share.N_RPT_PRIMARY_INDICATOR_R = 'S'and rank()  over(partition by agent_share2.N_POLICY_SK_R, agent_share2.N_RPT_PRIMARY_INDICATOR_R order by agent_share2.N_RPT_SPLIT_PERCENTAGE_R desc) >2  then agent_share.N_RPT_SPLIT_PERCENTAGE_R  END N_other_AGENT_SHARE_R
     */
         gc_getcur_loadedby             AS V_LAST_MODIFIED_BY_R,
         gd_sysdate                     AS T_CREATION_DATE_R,
         gc_getcur_loadedby             AS V_CREATED_BY_R,
         gd_sysdate                     AS T_LAST_MODIFIED_DATE_R,
         'Y'                            AS V_RPT_ACTIVE_STATUS_R,
         gn_sysdt_batchid               AS N_BATCH_ID_R,
         gn_current_month               AS N_REPORTMONTH_R,
		 agent_share.V_TEMPLATE_NAME_R  AS N_PLAN_CODE_R,
		 agent_share.N_LAST_RATE_R      as N_LAST_RATE_R,
         -- 21-01-2025 Add column Start
         NVL(stg.V_SALES_PLAN_DESC_R,stg1.V_SALES_PLAN_DESC_R)        as V_SALES_PLAN_DESC_R,      --06-02-2025 nvl added
         -- 21-01-2025 Add column End
         --28-01-2024 Add column Start
         CALCULATE_EST_COMM_FUNC(
    AGNT_P.D_POLICY_EFFECTIVE_DATE_R,
    ANN_PREM.N_ANNUALIZED_PREMIUM_R,
    agent_share.V_TEMPLATE_NAME_R,
    agent_share.N_LAST_RATE_R)  AS N_ESTIMATED_COMMISSION_R
         --28-01-2024 Add column End
   FROM dim_grp_policy_dir_r a
   LEFT JOIN
     (SELECT N_POLICY_SK_R,
       n_agent_sk_r,
       N_RPT_PRIMARY_INDICATOR_R,
       SUM(NVL(N_RPT_SPLIT_PERCENTAGE_R,0))N_RPT_SPLIT_PERCENTAGE_R,
       MIN(D_START_DATE_R) D_START_DATE_R,
       MAX(N_RPT_SORT_ORDER_R)N_RPT_SORT_ORDER_R,
       MAX(D_END_DATE_R) D_END_DATE_R,
	   v_template_name_r ,
	   N_LAST_RATE_R
     FROM fct_grp_agent_policy_r_lookup
     WHERE n_policy_sk_r <>-1
     GROUP BY N_POLICY_SK_R,
       n_agent_sk_r,
       N_RPT_PRIMARY_INDICATOR_R,
	   v_template_name_r ,
	   N_LAST_RATE_R
     ) agent_share
   ON a.n_policy_sk_r = agent_share.n_policy_sk_r
   LEFT JOIN
     (SELECT N_POLICY_SK_R,
       n_agent_sk_r,
       N_RPT_PRIMARY_INDICATOR_R,
       SUM(NVL(N_RPT_SPLIT_PERCENTAGE_R,0))N_RPT_SPLIT_PERCENTAGE_R,
       MIN(D_START_DATE_R) D_START_DATE_R,
       MAX(N_RPT_SORT_ORDER_R)N_RPT_SORT_ORDER_R,
       MAX(D_END_DATE_R) D_END_DATE_R,
	   v_template_name_r
     FROM fct_grp_agent_policy_r_lookup
     WHERE n_policy_sk_r          <>-1
     AND N_RPT_PRIMARY_INDICATOR_R ='S'
     GROUP BY N_POLICY_SK_R,
       n_agent_sk_r,
       N_RPT_PRIMARY_INDICATOR_R,
	   v_template_name_r
     ) agent_share2
   ON agent_share.N_POLICY_SK_R              =agent_share2.N_POLICY_SK_R
   AND agent_share.n_agent_sk_r              =agent_share2.n_agent_sk_r
   AND agent_share.N_RPT_SORT_ORDER_R        =agent_share2.N_RPT_SORT_ORDER_R
   AND agent_share.N_RPT_PRIMARY_INDICATOR_R = agent_share2.N_RPT_PRIMARY_INDICATOR_R
   /* 18-11-2025 CHANGES START FOR BLANK ADDRESS ISSUE*/
   LEFT JOIN (SELECT CASE WHEN DMGD1.N_PARTY_SK_R <> -1 THEN DMGD1.N_PARTY_SK_R
                     ELSE NVL((SELECT N_PARTY_SK_R FROM (SELECT N_PARTY_SK_r,ROW_NUMBER() OVER (PARTITION BY N_AGENT_SK_r ORDER BY T_EVENT_TIMESTAMP_R DESC ,N_BATCH_ID_R DESC) AS rn
                                                     FROM DIM_GRP_AGENT_DIRECTORY_R DMGD
													 WHERE DMGD.V_AGENT_NUMBER_R = DMGD1.V_AGENT_NUMBER_R AND V_ACTIVE_STATUS_R='N'
													 AND N_PARTY_SK_R<>-1)
                           WHERE RN =1),-1) END N_PARTY_SK_r,
					  DMGD1.N_AGENT_SK_R,
					  DMGD1.V_ACTIVE_STATUS_R
              FROM DIM_GRP_AGENT_DIRECTORY_R DMGD1
			  WHERE V_ACTIVE_STATUS_R = 'Y')B
			  --DIM_GRP_AGENT_DIRECTORY_R B
    /* 18-11-2025 CHANGES END FOR BLANK ADDRESS ISSUE */
   ON AGENT_SHARE.N_AGENT_SK_R = B.N_AGENT_SK_R
   AND B.V_ACTIVE_STATUS_R     = 'Y'
   LEFT JOIN
--08/08/24 Changes Start
    /* (SELECT *
     FROM DIM_GRP_AGENT_R d
     WHERE T_CREATION_DATE_R =
       (SELECT MAX(T_CREATION_DATE_R)
       FROM DIM_GRP_AGENT_R z
       WHERE z.n_agent_sk_r = d.n_agent_sk_r
       )
     ) C*/
	 (SELECT *
    FROM DIM_GRP_AGENT_R d
    WHERE  	d.V_ACTIVE_STATUS_R = 'Y' AND --24-Jul-2024 changes
	trunc(T_EVENT_TIMESTAMP_R) =
      (SELECT MAX(trunc(T_EVENT_TIMESTAMP_R))
      FROM DIM_GRP_AGENT_R z
      WHERE z.n_agent_sk_r = d.n_agent_sk_r
       )
     ) C
--08/08/24 Changes Start
	ON B.N_AGENT_SK_R       = C.N_AGENT_SK_R
   LEFT JOIN
     (SELECT DISTINCT V_ADDRESSLINE1_R,
       V_ADDRESSLINE2_R,
       V_CITY_R ,
       V_STATE_NAME_R,
       V_POSTAL_ZIP_R,
       n_party_sk_r,
       N_PRIMARY_LOCATION_R
    , Row_number () over( partition by n_party_sk_r ORDER BY N_BATCH_ID_R DESC) RECNT_RCD  -- 19-06-2025 Added to remove dublicates records
     FROM FCT_GRP_PARTY_ADDRESS_R
     WHERE V_SOURCE_SYSTEM_NAME_R = 'APS'
     AND N_PRIMARY_LOCATION_R     = '1'
     AND n_party_sk_r            <> -1
     AND D_DELETE_DATE_R         IS NULL
     )adr
   ON adr.n_party_sk_r = b.n_party_sk_r
   and adr.RECNT_RCD = 1  -- 19-06-2025 Added to remove dublicates records
   LEFT JOIN stg_premier_producer_r pp
   ON pp.V_AGENCY_CODE_R = SUBSTR(C.V_AGENT_NUMBER_R,1, 6)
   LEFT JOIN stg_premier_producer_desc_r pd
   ON PP.V_BROKER_NAME_R     = PD.V_BROKER_NAME_R
   -- 21-01-2025 Changes Start --
    LEFT JOIN
   (SELECT N_PLAN_CODE_R
         , N_RATE_R
         , V_SALES_PLAN_DESC_R
         , Row_number() over( partition by N_PLAN_CODE_R ,N_RATE_R order by N_PLAN_CODE_R ,N_RATE_R ) RANK_RW
    FROM ATOMIC.STG_PLAN_DETAIL) STG
   ON  STG.N_PLAN_CODE_R = agent_share.V_TEMPLATE_NAME_R
   AND STG.N_RATE_R      = agent_share.N_LAST_RATE_R
   and stg.RANK_RW       = 1
   -- 21-01-2025 Changes End.--
   -- 22-01-2025 Changes Start.--
   LEFT JOIN (SELECT N_POLICY_SK_R , D_POLICY_EFFECTIVE_DATE_R
                   , ROW_NUMBER() OVER(PARTITION BY D_POLICY_EFFECTIVE_DATE_R ORDER BY D_POLICY_EFFECTIVE_DATE_R) AGNT_RANK_RW
               FROM rpt_policy_dtl_r t1
              ) AGNT_P
    on AGNT_P.N_POLICY_SK_R = agent_share.n_policy_sk_r
    AND AGNT_P.AGNT_RANK_RW = 1
   LEFT JOIN (SELECT T1.N_POLICY_SK_R N_POLICY_SK_R
                   , T1.N_AGENT_SK_R N_AGENT_SK_R
                   , sum(N_ANNUALIZED_PREMIUM_R) N_ANNUALIZED_PREMIUM_R
                FROM RPT_FCT_RPT_ANN_PREM_SUMMARY_R T1
                WHERE N_REPORTMONTH_R = (SELECT MAX(N_REPORTMONTH_R) FROM RPT_FCT_RPT_ANN_PREM_SUMMARY_R T2
                                          WHERE T2.N_POLICY_SK_R = T1.N_POLICY_SK_R
                                            AND N_AGENT_SK_R = T1.N_AGENT_SK_R)
                GROUP BY T1.N_POLICY_SK_R,T1.N_AGENT_SK_R ,T1.N_REPORTMONTH_R) ANN_PREM
  on ANN_PREM.N_POLICY_SK_R = agent_share.n_policy_sk_r
  AND ANN_PREM.N_AGENT_SK_R = agent_share.n_agent_sk_r
  -- 28-01-2025 Changes End.--
  --06-02-2025 addition start
    left join   (SELECT N_PLAN_CODE_R
         , N_RATE_R
         , V_SALES_PLAN_DESC_R
         , Row_number() over( partition by N_PLAN_CODE_R  order by N_PLAN_CODE_R ) RANK_RW
    FROM ATOMIC.STG_PLAN_DETAIL) STG1
   ON  STG1.N_PLAN_CODE_R = agent_share.V_TEMPLATE_NAME_R
   and stg1.RANK_RW       = 1
    -- 06-02-2025 addition end
   WHERE a.v_active_status_r = 'Y';
  gc_trcmsg                                            :=gc_trcmsg||'4.2 Exit from prc_get_cur_data'||chr(13);
EXCEPTION
WHEN OTHERS THEN
  gc_errmsg :=SUBSTR(SQLERRM,1,4000);
  gc_trcmsg :=gc_trcmsg||'4.z Error in prc_get_cur_data'||chr(13);
  pkg_grp_log_util.prc_update_log ( gn_out_job_id --p_job_id
  ,gc_error_status                                --p_job_status
  ,gc_errmsg                                      --p_err_msg
  ,gc_trcmsg||chr(13)||gc_errmsg                  --p_trc_msg
  ,gc_getcur_loadedby                             --p_log_util_called_by_r
  );
  RAISE;
END prc_get_cur_data;
--Procedure to rebuild indexes RPT_AGENT_POLICY_R
PROCEDURE prc_rebuild_indexes
IS
  LC_REBUILD_INDEX VARCHAR2(300);
BEGIN
  gc_trcmsg:=gc_trcmsg||'7.a Entered into prc_rebuild_indexes'||chr(13);
  FOR I IN
  (SELECT 'ALTER INDEX '
      ||INDEX_NAME
      ||' REBUILD parallel 16 nologging' REBUILD_INDEX
    FROM ALL_INDEXES
    WHERE TABLE_NAME ='RPT_AGENT_POLICY_R'
    AND INDEX_NAME NOT LIKE 'PK_%'
    AND INDEX_NAME NOT LIKE 'FK_%'
    AND status='UNUSABLE'
  )
  LOOP
    LC_REBUILD_INDEX:=I.REBUILD_INDEX;
    EXECUTE IMMEDIATE LC_REBUILD_INDEX;
  END LOOP;
  gc_trcmsg:=gc_trcmsg||'7.z Exit from prc_rebuild_indexes'||chr(13);
EXCEPTION
WHEN OTHERS THEN
  gc_errmsg :=SUBSTR(SQLERRM,1,4000);
  gc_trcmsg :=gc_trcmsg||'7.z Error in prc_rebuild_indexes'||chr(13);
  pkg_grp_log_util.prc_update_log ( gn_out_job_id --p_job_id
  ,gc_error_status                                --p_job_status
  ,gc_errmsg                                      --p_err_msg
  ,gc_trcmsg||chr(13)||gc_errmsg                  --p_trc_msg
  ,gc_rebuildindexes                              --p_log_util_called_by_r
  );
  RAISE;
END prc_rebuild_indexes;
END PKG_GRP_LOAD_RPT_AGENT_POLICY_R;

