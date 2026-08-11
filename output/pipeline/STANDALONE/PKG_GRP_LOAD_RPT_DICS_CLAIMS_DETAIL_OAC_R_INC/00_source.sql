

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ATOMIC"."PKG_GRP_LOAD_RPT_DICS_CLAIMS_DETAIL_OAC_R_INC"
IS
  /***********************************************************************
  Purpose:  This package body contains procedures which loads data into RPT_DICS_CLAIMS_DETAIL_OAC_R
  Dependent SSL tables : rpt_client_dtl_r
                         rpt_claimant_dtl_r
                         rpt_claim_dtl_r
                         rpt_policy_dtl_r
                         rpt_claim_payment_r
                         rpt_claim_payment_dtl_r
  Used DB Objects:DIM_TIME_R
  Author     Date     Description
  ---------- -------- -------------------------------------------------
  VGireesh   15-Jul-2024 Initial Creation
  VGireesh   21-Jul-2024 Added Alter PLSQL optimizer at Session level as job is taking 94 mins for the completion
  VGireesh   20-Aug-2024 Changed optimizer level to 2 as the load still taking 84 mins to see the performance
  VGireesh   22-Aug-2024 Changed optimizer level to 1 as there is no much improvement with 2 it took min 80 and max 86 mins
                         and changed PARALLEL hint from 4 to 8
  Chandra    08-Oct-2024 Added column V_RSL_EIN_IND_R,V_PRIVACY_INDICATOR_R
  Beneshya   17-Oct-2024 Changed the logic for taxable and non_taxable benefit as part of the enhancement suggested
  Chandra    23-Oct-2024 Changed the logic for taxable benefit requested by Ganesan
  Chandra    18-Dec-2024 Changed the logic for v_claim_status_reason_code_r
  Suresh     17-01-2025  Create synonyms and append data in table PKG_GRP_LOAD_RPT_DICS_CLAIMS_DETAIL_OAC_R_TEMP
  Suresh     21-01-2025  Added on condition in data  p_out_cursor cursor (and not  (t3332275.V_SOURCE_SYSTEM_NAME_R='CV' and T3332155.V_RECORD_TYPE_R = 'Gross Benefit'))
  Suresh     29-01-2025  Replace condition t3332275.n_claim_taxable_benefit_pct_r  AS cs_2,  with      case when t3332275.v_source_system_name_r = 'CV' then 100 else t3332275.n_claim_taxable_benefit_pct_r end AS cs_2,
  Suresh     03-02-2025  Add column  , -- 03/02/2025 Changes start
                             CASE WHEN NVL(t3332275.V_CLAIM_COVERAGE_CODE_R,'-')  = 'PFL' THEN 'Y'
                              ELSE 'N'
                              END
                            -- 03/02/2025 Changes end as suggested by erica
   Rose 	22-06-2025  Adding new logging mechanism.
						Updated Parallel to rebuild index from parallel 16 to parallel 8 nologging.
						Commented update flag = 'N' for Month End+2 Load.
 Gayatri	 26/08/25  Commented Global Index, Added Local Index Rebuild
 Ananthan   31-12-2025  Added Column V_CLAIMANT_EMPLOYEE_NUMBER_R and mapped to V_EMPLOYEE_NUM_R from RPT_CLAIMANT_DTL_R
 Ananthan   14-01-2026  Modified the logic of TAXABLE_BENEFITS_, non_taxable_benefits and cs_2 (Taxable Percentage)
  ***********************************************************************/
  --Procedure to update prior month active flag and current month partition
PROCEDURE prc_upd_del_data
IS
  LN_SQLROWCNT      NUMBER;
  LN_CNT            NUMBER;
  ln_fisc_current_month NUMBER;
  ln_fisc_prior_month   NUMBER;
  ld_fic_mis_date_2     DATE;
BEGIN
  gc_trcmsg:='3.1 Entered into in prc_upd_del_data'||chr(13);

  	/*START: 28-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
	 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
	 (
		p_job_id_r                    => gn_out_job_id,
		p_batch_id_r                  => gn_sysdt_batchid,
		p_message_type_r              => gc_message_type_r,
		p_code_location_r             => gc_updby,
		p_message_r                   => gc_trcmsg,
		p_count_type_r                => NULL,
		p_count_r                     => NULL,
		p_duration_r                  => NULL,
		p_created_by_r                => GC_JOB_NAME,
		out_prcs_job_log_message_id_r => gn_job_log_message_id_r
	);

	/*END: 28-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
  --Fetch Fisc Month End +2 and Fisc Current Month
  SELECT --D_CALENDAR_DATE_R,D_CALENDAR_DATE_R +1
    D_CALENDAR_DATE_R                  +2 ,
    to_number(TO_CHAR(last_day(sysdate)+1,'YYYYMM'))
  INTO ld_fic_mis_date_2 ,
    ln_fisc_current_month
  FROM ATOMIC.DIM_TIME_R D
  WHERE V_END_OF_FISCAL_MONTH_IND_R      = 'Y'
  AND TO_CHAR(D_CALENDAR_DATE_R,'YYYYMM')=TO_CHAR(sysdate,'YYYYMM');
  gc_trcmsg                             :=gc_trcmsg||'3.2 Fisc Month End +2 Day Date of the current month is:->'||ld_fic_mis_date_2||chr(13);
  gc_trcmsg                             :=gc_trcmsg||'3.3 Fisc Current Month of the current month is:->'||ln_fisc_current_month||chr(13);

   /*START: 29-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
  gc_trcmsg:='3.2 Fisc Month End +2 Day Date of the current month:'||ld_fic_mis_date_2 ;
   PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
	 (
		p_job_id_r                    => gn_out_job_id,
		p_batch_id_r                  => gn_sysdt_batchid,
		p_message_type_r              => gc_message_type_r,
		p_code_location_r             => gc_updby,
		p_message_r                   => gc_trcmsg,
		p_count_type_r                => NULL,
		p_count_r                     => NULL,
		p_duration_r                  => NULL,
		p_created_by_r                => GC_JOB_NAME,
		out_prcs_job_log_message_id_r => gn_job_log_message_id_r
	);
	/*END: 29-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
  IF TRUNC(ld_fic_mis_date_2)            =TRUNC(sysdate) THEN
    ln_fisc_prior_month                 :=to_number(TO_CHAR(ld_fic_mis_date_2,'YYYYMM'));
    gc_trcmsg                           :=gc_trcmsg||'3.3.1 Fisc Prior Month of the current month is:->'||ln_fisc_prior_month||chr(13);
    gc_trcmsg                           :=gc_trcmsg||'3.4 Today Fisc Month End +2 '||ld_fic_mis_date_2||' hence Updating v_rpt_active_status_r=N against the records loaded in prior fisc month which is :->'||ln_fisc_prior_month||CHR(13);
   /* UPDATE RPT_DICS_CLAIMS_DETAIL_OAC_R
    SET v_rpt_active_status_r='N' ,
      v_last_modified_by_r   =gc_updby ,
      t_last_modified_date_r =gd_sysdate
    WHERE n_yearmonth_r    = ln_fisc_prior_month;
    ln_sqlrowcnt            :=SQL%ROWCOUNT;
    COMMIT;*/
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

	/*START: 29-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
	gc_trcmsg:='3.4 Today is not fisc month end +2 of the current month hence Calling procedure prc_trunc_partition to truncate current month partition from main'||chr(13);
   PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
	 (
		p_job_id_r                    => gn_out_job_id,
		p_batch_id_r                  => gn_sysdt_batchid,
		p_message_type_r              => gc_message_type_r,
		p_code_location_r             => gc_updby,
		p_message_r                   => gc_trcmsg,
		p_count_type_r                => NULL,
		p_count_r                     => NULL,
		p_duration_r                  => NULL,
		p_created_by_r                => GC_JOB_NAME,
		out_prcs_job_log_message_id_r => gn_job_log_message_id_r
	);
	gt_start_time_r:= SYSTIMESTAMP;
	/*END: 29-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
    prc_trunc_partition;
    gc_trcmsg:=gc_trcmsg||'3.11 Completed procedure prc_trunc_partition call from main'||chr(13);

	/*START: 29-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
	gt_end_time_r:= SYSTIMESTAMP;

	gc_duration_r := EXTRACT(SECOND FROM (gt_end_time_r - gt_start_time_r)) +
				 EXTRACT(MINUTE FROM (gt_end_time_r - gt_start_time_r)) * 60 +
				 EXTRACT(HOUR FROM (gt_end_time_r - gt_start_time_r)) * 3600;

	gc_trcmsg:='3.5 Completed procedure prc_trunc_partition call from main'||chr(13);
   PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
	 (
		p_job_id_r                    => gn_out_job_id,
		p_batch_id_r                  => gn_sysdt_batchid,
		p_message_type_r              => gc_message_type_r,
		p_code_location_r             => gc_updby,
		p_message_r                   => gc_trcmsg,
		p_count_type_r                => NULL,
		p_count_r                     => NULL,
		p_duration_r                  => gc_duration_r,
		p_created_by_r                => GC_JOB_NAME,
		out_prcs_job_log_message_id_r => gn_job_log_message_id_r
	);
	/*END: 29-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
  END IF;
  gc_trcmsg:=gc_trcmsg||'3.12 Exit from in prc_upd_del_data'||chr(13);

  /*START: 29-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
	gc_trcmsg:='3.6 Exit from in prc_upd_del_data'||chr(13);
   PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
	 (
		p_job_id_r                    => gn_out_job_id,
		p_batch_id_r                  => gn_sysdt_batchid,
		p_message_type_r              => gc_message_type_r,
		p_code_location_r             => gc_updby,
		p_message_r                   => gc_trcmsg,
		p_count_type_r                => NULL,
		p_count_r                     => NULL,
		p_duration_r                  => NULL,
		p_created_by_r                => GC_JOB_NAME,
		out_prcs_job_log_message_id_r => gn_job_log_message_id_r
	);
	/*END: 29-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
EXCEPTION
WHEN OTHERS THEN
  gc_errmsg:=SUBSTR(SQLERRM,1,4000);
  gc_trcmsg:='3.z Error in prc_upd_del_data'||chr(13)||gc_errmsg;

  	/*START: 29-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
    pkg_grp_log_util.prc_update_log_message_r
    (
        n_prcs_job_log_message_id_r => gn_job_log_message_id_r,
        p_err_msg => gc_trcmsg
    );
	/*END: 29-MAY-2025: NEW LOGGING MECHANISM CHANGES*/

    pkg_grp_log_util.prc_update_log
    (
        p_job_id => gn_out_job_id,
        p_job_status => gc_error_status,
        p_err_msg => gc_errmsg,
        p_trc_msg => chr(13) || gc_errmsg,
        p_log_util_called_by_r => gc_updby
    );

  RAISE;
END prc_upd_del_data;
--Procedure to truncate the YEARMONTH partition
PROCEDURE prc_trunc_partition
AS
  LC_TBL           VARCHAR2(30):='RPT_DICS_CLAIMS_DETAIL_OAC_R';
  LC_REBUILD_INDEX VARCHAR2(300);
BEGIN
  GC_TRCMSG:=GC_TRCMSG||'3.7.1 Entered into prc_trunc_partition :->'||'ALTER TABLE '||LC_TBL||' TRUNCATE PARTITION '||'PART_'||LC_TBL||'_'||GN_CURRENT_MONTH||CHR(13);
  -- 17-01-2025 START CHANGES

   INSERT INTO SSL_PACKAGE_LOG_TABLE(job_name,process_name, start_date, end_date)
   VALUES ('PKG_GRP_LOAD_RPT_DICS_CLAIMS_DETAIL_OAC_R_INC','START: TEMP_TABLE PARTITION SWAPPING:',SYSDATE,NULL);
   COMMIT;

  EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM SYN_RPT_DICS_CLAIMS_DETAIL_OAC_R FOR RPT_DICS_CLAIMS_DETAIL_OAC_R_TEMP';

  INSERT INTO SSL_PACKAGE_LOG_TABLE(job_name,process_name, start_date, end_date)
     VALUES ('PKG_GRP_LOAD_RPT_DICS_CLAIMS_DETAIL_OAC_R_INC','END: TEMP_TABLE PARTITION SWAPPING:', NULL,SYSDATE);
     COMMIT;

  -- 17-01-2025 END CHANGES
  EXECUTE immediate 'ALTER TABLE '||lc_tbl||' TRUNCATE PARTITION '||'PART_'||lc_tbl||'_'||gn_current_month;
  gc_trcmsg:=gc_trcmsg||'3.7.2 Exit from prc_trunc_partition'||CHR(13);
  gc_trcmsg:=gc_trcmsg||'3.7.3 Rebuild Unusable PK Index starts'||chr(13);
  FOR I IN
  (SELECT 'ALTER INDEX '
    ||INDEX_NAME
    ||' REBUILD parallel 8 nologging' REBUILD_INDEX
  FROM ALL_INDEXES
  WHERE TABLE_NAME ='RPT_DICS_CLAIMS_DETAIL_OAC_R'
  AND INDEX_NAME LIKE 'PK_%'
  AND STATUS='UNUSABLE'
  )
  LOOP
    LC_REBUILD_INDEX:=I.REBUILD_INDEX;
    EXECUTE IMMEDIATE LC_REBUILD_INDEX;
  END LOOP;
  gc_trcmsg:=gc_trcmsg||'3.7.4 Rebuild Unusable PK Index ends'||chr(13);
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
  LC_TBL           VARCHAR2(30):='RPT_DICS_CLAIMS_DETAIL_OAC_R';
TYPE var_tbl_type
IS
  TABLE OF RPT_DICS_CLAIMS_DETAIL_OAC_R%ROWTYPE INDEX BY BINARY_INTEGER;
  lt_var_tbl_typ var_tbl_type;
TYPE var_tbl_type_temp
IS
  TABLE OF RPT_DICS_CLAIMS_DETAIL_OAC_R_TEMP%ROWTYPE INDEX BY BINARY_INTEGER;
  lt_var_tbl_typ_temp var_tbl_type_temp;
  ln_rec_cnt    NUMBER:=0;
  ln_start_time NUMBER;
  LC_REBUILD_INDEX_TEMP_TBL VARCHAR2(5000):= '-';
BEGIN
  --Call Log Util pkg to Insert entry in PRCS_JOB_LOG_R
  pkg_grp_log_util.prc_insert_log ( p_source => gc_source ,p_job_nm => gc_job_name ,p_job_status => gc_running_status ,p_err_msg => NULL ,p_trc_msg => NULL ,p_n_batch_id => gn_sysdt_batchid ,p_log_util_called_by_r=> gc_main_loadedby ,out_job_id => gn_out_job_id );
  gc_trcmsg:=gc_trcmsg||'1. Entered into main'||chr(13);

  	/*START: 29-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
	 gc_trcmsg:='1. Entered into main. '||'gn_current_month:->'||gn_current_month|| ' - gn_prior_month:->'||gn_prior_month;
	 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
	 (
		p_job_id_r                    => gn_out_job_id,
		p_batch_id_r                  => gn_sysdt_batchid,
		p_message_type_r              => gc_message_type_r,
		p_code_location_r             => gc_main_loadedby,
		p_message_r                   => gc_trcmsg,
		p_count_type_r                => NULL,
		p_count_r                     => NULL,
		p_duration_r                  => NULL,
		p_created_by_r                => GC_JOB_NAME,
		out_prcs_job_log_message_id_r => gn_job_log_message_id_r
	);
	/*END: 29-MAY-2025: NEW LOGGING MECHANISM CHANGES*/

  --21-Jul-2024 changes starts
  gc_trcmsg:='1.1 Set PLSQL_OPTIMIZER_LEVEL to 1 - main'||chr(13);

   /*START: 29-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
	 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
	 (
		p_job_id_r                    => gn_out_job_id,
		p_batch_id_r                  => gn_sysdt_batchid,
		p_message_type_r              => gc_message_type_r,
		p_code_location_r             => gc_main_loadedby,
		p_message_r                   => gc_trcmsg,
		p_count_type_r                => NULL,
		p_count_r                     => NULL,
		p_duration_r                  => NULL,
		p_created_by_r                => GC_JOB_NAME,
		out_prcs_job_log_message_id_r => gn_job_log_message_id_r
	);
	/*END: 29-MAY-2025: NEW LOGGING MECHANISM CHANGES*/

  execute immediate 'ALTER SESSION SET PLSQL_OPTIMIZE_LEVEL=1';
  gc_trcmsg:='1.z Completed Set PLSQL_OPTIMIZER_LEVEL to 1 - main'||chr(13);

    /*START: 29-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
	 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
	 (
		p_job_id_r                    => gn_out_job_id,
		p_batch_id_r                  => gn_sysdt_batchid,
		p_message_type_r              => gc_message_type_r,
		p_code_location_r             => gc_main_loadedby,
		p_message_r                   => gc_trcmsg,
		p_count_type_r                => NULL,
		p_count_r                     => NULL,
		p_duration_r                  => NULL,
		p_created_by_r                => GC_JOB_NAME,
		out_prcs_job_log_message_id_r => gn_job_log_message_id_r
	);
	/*END: 29-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
  --21-Jul-2024 changes ends
  gc_trcmsg:=gc_trcmsg||'gn_current_month     :->'||gn_current_month||chr(13);
  gc_trcmsg:=gc_trcmsg||'gn_prior_month       :->'||gn_prior_month||chr(13);
  --gc_trcmsg:=gc_trcmsg||'1.c gn_prior2prior_month :->'||gn_prior2prior_month||chr(13);
  PKG_GRP_LOAD_RPT_DICS_CLAIMS_DETAIL_OAC_R_INC.PRC_TEMP_TABLE_DATA_LOAD;

  gc_trcmsg:='3. Call procedure prc_upd_del_data from main'||chr(13);

  PKG_GRP_LOAD_RPT_DICS_CLAIMS_DETAIL_OAC_R_INC.prc_upd_del_data;
  gc_trcmsg:=gc_trcmsg||'3.z Completed Procedure prc_upd_del_data call from main'||chr(13);
  gc_trcmsg:=gc_trcmsg||'4. Call prc_get_cur_data to get ref_cursor '||chr(13);
  --PKG_GRP_LOAD_RPT_DICS_CLAIMS_DETAIL_OAC_R.prc_get_cur_data (var_ref_cur);
  --PKG_GRP_LOAD_RPT_DICS_CLAIMS_DETAIL_OAC_R_INC.PRC_TEMP_TABLE_DATA_LOAD;
  gc_trcmsg    :=gc_trcmsg||'4.z Completed Call Procedure prc_get_cur_data to get ref_cursor'||chr(13);
  ln_start_time:=dbms_utility.get_time;

  gc_trcmsg    :=gc_trcmsg||'5 data load starts '||ln_start_time||chr(13);
  ln_rec_cnt   :=0;

   INSERT INTO SSL_PACKAGE_LOG_TABLE(job_name,process_name, start_date, end_date)
   VALUES ('PKG_GRP_LOAD_RPT_DICS_CLAIMS_DETAIL_OAC_R_INC','START: PARTITION EXCHANGE:',SYSDATE,NULL);
   COMMIT;
  /*START: 29-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
	gc_trcmsg:='4.1 START: PARTITION EXCHANGE '||chr(13);
	gt_start_time_r := SYSTIMESTAMP;
	gc_count_type_r:= PKG_GRP_LOG_UTIL.gc_count_type_insert;

	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
			 (
				p_job_id_r                    => gn_out_job_id,
				p_batch_id_r                  => gn_sysdt_batchid,
				p_message_type_r              => gc_message_type_r,
				p_code_location_r             => gc_main_loadedby,
				p_message_r                   => gc_trcmsg,
				p_count_type_r                => NULL,
				p_count_r                     => NULL,
				p_duration_r                  => NULL,
				p_created_by_r                => GC_JOB_NAME,
				out_prcs_job_log_message_id_r => gn_job_log_message_id_r
			);
	/*START: 29-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
  EXECUTE IMMEDIATE 'ALTER TABLE RPT_DICS_CLAIMS_DETAIL_OAC_R EXCHANGE PARTITION PART_'||lc_tbl||'_'||gn_current_month || '   --PART_RPT_DICS_CLAIMS_DETAIL_OAC_R_202503
  WITH TABLE RPT_DICS_CLAIMS_DETAIL_OAC_R_TEMP';

   INSERT INTO SSL_PACKAGE_LOG_TABLE(job_name,process_name, start_date, end_date)
     VALUES ('PKG_GRP_LOAD_RPT_DICS_CLAIMS_DETAIL_OAC_R_INC','END: PARTITION EXCHANGE:', NULL,SYSDATE);
     COMMIT;

	/*START: 29-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
	 gt_end_time_r := SYSTIMESTAMP;
	 gc_duration_r := EXTRACT(SECOND FROM (gt_end_time_r - gt_start_time_r)) +
							 EXTRACT(MINUTE FROM (gt_end_time_r - gt_start_time_r)) * 60 +
							 EXTRACT(HOUR FROM (gt_end_time_r - gt_start_time_r)) * 3600;
	gc_trcmsg:='4.z END: PARTITION EXCHANGE '||chr(13);
		 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
		 (
			p_job_id_r                    => gn_out_job_id,
			p_batch_id_r                  => gn_sysdt_batchid,
			p_message_type_r              => gc_message_type_r,
			p_code_location_r             => gc_main_loadedby,
			p_message_r                   => gc_trcmsg,
			p_count_type_r                => NULL,
			p_count_r                     => NULL,
			p_duration_r                  => gc_duration_r,
			p_created_by_r                => GC_JOB_NAME,
			out_prcs_job_log_message_id_r => gn_job_log_message_id_r
		);
	/*END: 29-MAY-2025: NEW LOGGING MECHANISM CHANGES*/

	  /*START: 29-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
	gc_trcmsg:='5.1 START: MAIN_TABLE PARTITION SWAPPING '||chr(13);
	gt_start_time_r := SYSTIMESTAMP;
	gc_count_type_r:= PKG_GRP_LOG_UTIL.gc_count_type_insert;

	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
			 (
				p_job_id_r                    => gn_out_job_id,
				p_batch_id_r                  => gn_sysdt_batchid,
				p_message_type_r              => gc_message_type_r,
				p_code_location_r             => gc_main_loadedby,
				p_message_r                   => gc_trcmsg,
				p_count_type_r                => NULL,
				p_count_r                     => NULL,
				p_duration_r                  => NULL,
				p_created_by_r                => GC_JOB_NAME,
				out_prcs_job_log_message_id_r => gn_job_log_message_id_r
			);
	/*START: 29-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
 INSERT INTO SSL_PACKAGE_LOG_TABLE(job_name,process_name, start_date, end_date)
   VALUES ('PKG_GRP_LOAD_RPT_DICS_CLAIMS_DETAIL_OAC_R_INC','START: MAIN_TABLE PARTITION SWAPPING:',SYSDATE,NULL);
   COMMIT;

  EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM SYN_RPT_DICS_CLAIMS_DETAIL_OAC_R FOR RPT_DICS_CLAIMS_DETAIL_OAC_R';

  INSERT INTO SSL_PACKAGE_LOG_TABLE(job_name,process_name, start_date, end_date)
     VALUES ('PKG_GRP_LOAD_RPT_DICS_CLAIMS_DETAIL_OAC_R_INC','END: MAIN_TABLE PARTITION SWAPPING:', NULL,SYSDATE);
     COMMIT;

	/*START: 29-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
	 gt_end_time_r := SYSTIMESTAMP;
	 gc_duration_r := EXTRACT(SECOND FROM (gt_end_time_r - gt_start_time_r)) +
							 EXTRACT(MINUTE FROM (gt_end_time_r - gt_start_time_r)) * 60 +
							 EXTRACT(HOUR FROM (gt_end_time_r - gt_start_time_r)) * 3600;
	gc_trcmsg:='5.z END: MAIN_TABLE PARTITION SWAPPING '||chr(13);
		 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
		 (
			p_job_id_r                    => gn_out_job_id,
			p_batch_id_r                  => gn_sysdt_batchid,
			p_message_type_r              => gc_message_type_r,
			p_code_location_r             => gc_main_loadedby,
			p_message_r                   => gc_trcmsg,
			p_count_type_r                => gc_count_type_r,
			p_count_r                     => NULL,
			p_duration_r                  => gc_duration_r,
			p_created_by_r                => GC_JOB_NAME,
			out_prcs_job_log_message_id_r => gn_job_log_message_id_r
		);
	/*END: 29-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
  --LOOP
   -- lt_var_tbl_typ.DELETE;
    --FETCH var_ref_cur BULK COLLECT INTO lt_var_tbl_typ LIMIT gn_bulk_coll_cnt;
    --FORALL X IN LT_VAR_TBL_TYP.first..LT_VAR_TBL_TYP.last
    --INSERT /*+APPEND_VALUES*/
    --INTO RPT_DICS_CLAIMS_DETAIL_OAC_R VALUES lt_var_tbl_typ
      --(x
      --) ;
    --LN_REC_CNT:=LN_REC_CNT+LT_VAR_TBL_TYP.COUNT; */
   -- COMMIT;
   -- EXIT
 -- WHEN var_ref_cur%NOTFOUND;
  --END LOOP;
  gc_trcmsg:=gc_trcmsg||'5.z Data Loaded '||ln_rec_cnt||' records '||((dbms_utility.get_time - ln_start_time)/100)||chr(13);
  ln_start_time:=dbms_utility.get_time;
  gc_trcmsg    :=gc_trcmsg||'7. Call procedure unusable prc_rebuild_indexes from main '||ln_start_time||chr(13);

   	gc_trcmsg:='6. Call procedure unusable prc_rebuild_indexes from main '||chr(13);
	gt_start_time_r:=SYSTIMESTAMP;
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
		 (
			p_job_id_r                    => gn_out_job_id,
			p_batch_id_r                  => gn_sysdt_batchid,
			p_message_type_r              => gc_message_type_r,
			p_code_location_r             => gc_main_loadedby,
			p_message_r                   => gc_trcmsg,
			p_count_type_r                => NULL,
			p_count_r                     => NULL,
			p_duration_r                  => NULL,
			p_created_by_r                => GC_JOB_NAME,
			out_prcs_job_log_message_id_r => gn_job_log_message_id_r
		);

  --PKG_GRP_LOAD_RPT_DICS_CLAIMS_DETAIL_OAC_R_INC.prc_rebuild_indexes;
  		ln_start_time:=dbms_utility.get_time;
		gc_trcmsg:='8. Rebuild Local Index prc_rebuild_index_partitions from Common Util for Partition: '||gn_current_month;

		gt_start_time_r:=SYSTIMESTAMP;
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
		 (
			p_job_id_r                    => gn_out_job_id,
			p_batch_id_r                  => gn_sysdt_batchid,
			p_message_type_r              => gc_message_type_r,
			p_code_location_r             => gc_main_loadedby,
			p_message_r                   => gc_trcmsg,
			p_count_type_r                => NULL,
			p_count_r                     => NULL,
			p_duration_r                  => NULL,
			p_created_by_r                => GC_JOB_NAME,
			out_prcs_job_log_message_id_r => gn_job_log_message_id_r
		);

		--26th Aug: Added Local Index Rebuild
		PKG_GRP_COMMON_UTIL.prc_rebuild_index_partitions
		(
			p_table_name   		  		  => 'RPT_DICS_CLAIMS_DETAIL_OAC_R',
			p_parallel_degree   		  => 8,
			p_partition_name  		  	  => 'PART_RPT_DICS_CLAIMS_DETAIL_OAC_R_'||gn_current_month,
			p_out_job_id              	  => gn_out_job_id,
			p_Log_seq_num             	  => 8
		);

  gc_trcmsg:=gc_trcmsg||'7.z Completed Procedure unusable prc_rebuild_indexes call from main '||((dbms_utility.get_time - ln_start_time)/100)||chr(13);
  /*START: 29-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
  gc_trcmsg:='6.z Completed Procedure unusable prc_rebuild_indexes call from main ';
  	gt_end_time_r:= SYSTIMESTAMP;
		gc_duration_r := EXTRACT(SECOND FROM (gt_end_time_r - gt_start_time_r)) +
						 EXTRACT(MINUTE FROM (gt_end_time_r - gt_start_time_r)) * 60 +
						 EXTRACT(HOUR FROM (gt_end_time_r - gt_start_time_r)) * 3600;

			 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
			 (
				p_job_id_r                    => gn_out_job_id,
				p_batch_id_r                  => gn_sysdt_batchid,
				p_message_type_r              => gc_message_type_r,
				p_code_location_r             => gc_main_loadedby,
				p_message_r                   => gc_trcmsg,
				p_count_type_r                => NULL,
				p_count_r                     => NULL,
				p_duration_r                  => gc_duration_r,
				p_created_by_r                => GC_JOB_NAME,
				out_prcs_job_log_message_id_r => gn_job_log_message_id_r
			);
	/*END: 29-MAY-2025: NEW LOGGING MECHANISM CHANGES*/

  ln_start_time:=dbms_utility.get_time;
  gc_trcmsg    :=gc_trcmsg||'8. Gather RPT_DICS_CLAIMS_DETAIL_OAC_R table stats from main '||ln_start_time||chr(13);
  --DBMS_STATS.GATHER_TABLE_STATS('ATOMIC','RPT_DICS_CLAIMS_DETAIL_OAC_R');
  gc_trcmsg:=gc_trcmsg||'8.z Completed Gather RPT_DICS_CLAIMS_DETAIL_OAC_R table stats from main '||((dbms_utility.get_time - ln_start_time)/100)||chr(13);
  -- 17-01-2025 START CHANGES
 /* EXECUTE IMMEDIATE 'TRUNCATE TABLE RPT_DICS_CLAIMS_DETAIL_OAC_R_TEMP';
  gc_trcmsg:=gc_trcmsg||'8.z.1 Exit from trunc table.'||CHR(13);
  EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM SYN_RPT_DICS_CLAIMS_DETAIL_OAC_R FOR RPT_DICS_CLAIMS_DETAIL_OAC_R';
  gc_trcmsg:=gc_trcmsg||'8.z.2 Created synonysm for main table'||CHR(13);
  gc_trcmsg:=gc_trcmsg||'8.z.3. Call prc_get_cur_data to get ref_cursor '||chr(13);
  PKG_GRP_LOAD_RPT_DICS_CLAIMS_DETAIL_OAC_R.prc_get_cur_data (var_ref_cur);
  gc_trcmsg    :=gc_trcmsg||'8.z.4 Completed Call Procedure prc_get_cur_data to get ref_cursor'||chr(13);
  ln_start_time:=dbms_utility.get_time;
  gc_trcmsg    :=gc_trcmsg||'8.z.5 data load starts '||ln_start_time||chr(13);
  ln_rec_cnt   :=0;
  LOOP
    lt_var_tbl_typ_temp.DELETE;
    FETCH var_ref_cur BULK COLLECT INTO lt_var_tbl_typ_temp LIMIT gn_bulk_coll_cnt;
    FORALL X IN lt_var_tbl_typ_temp.first..lt_var_tbl_typ_temp.last */
    --INSERT /*+APPEND_VALUES*/
 /*   INTO RPT_DICS_CLAIMS_DETAIL_OAC_R_TEMP VALUES lt_var_tbl_typ_temp
      (x
      ) ;
    LN_REC_CNT:=LN_REC_CNT+lt_var_tbl_typ_temp.COUNT;
    COMMIT;
    EXIT
  WHEN var_ref_cur%NOTFOUND;
  END LOOP; */
  gc_trcmsg:=gc_trcmsg||'8.z.6 Data Loaded '||ln_rec_cnt||' records '||((dbms_utility.get_time - ln_start_time)/100)||chr(13);
  gc_trcmsg:=gc_trcmsg||'8.z.7 Data populated in temp table'||CHR(13);
  gc_trcmsg:=gc_trcmsg||'8.z.8 Temp Table Rebuild Unusable PK Index starts'||chr(13);

 /* FOR I IN
  (SELECT 'ALTER INDEX '
    ||INDEX_NAME
    ||' REBUILD parallel 16 nologging' REBUILD_INDEX
  FROM ALL_INDEXES
  WHERE TABLE_NAME ='RPT_DICS_CLAIMS_DETAIL_OAC_R_TEMP'
  AND INDEX_NAME LIKE 'PK_%'
  AND STATUS='UNUSABLE'
  )
  LOOP
    LC_REBUILD_INDEX_TEMP_TBL := I.REBUILD_INDEX;
    EXECUTE IMMEDIATE LC_REBUILD_INDEX_TEMP_TBL;
  END LOOP; */
  gc_trcmsg:=gc_trcmsg||'8.z.9 Temp Table Rebuild Unusable PK Index end'||chr(13);
  -- 17-01-2025 END CHANGES
  gc_trcmsg:='1.z Exit from main'||chr(13);

	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
		 (
			p_job_id_r                    => gn_out_job_id,
			p_batch_id_r                  => gn_sysdt_batchid,
			p_message_type_r              => gc_message_type_r,
			p_code_location_r             => gc_main_loadedby,
			p_message_r                   => gc_trcmsg,
			p_count_type_r                => NULL,
			p_count_r                     => NULL,
			p_duration_r                  => NULL,
			p_created_by_r                => GC_JOB_NAME,
			out_prcs_job_log_message_id_r => gn_job_log_message_id_r
		);
    pkg_grp_log_util.prc_update_log
    (
        p_job_id => gn_out_job_id,
        p_job_status => gc_success_status,
        p_err_msg => gc_errmsg,
        p_trc_msg => chr(13) || gc_errmsg,
        p_log_util_called_by_r => gc_main_loadedby
    );
EXCEPTION
WHEN OTHERS THEN
  gc_errmsg :=SUBSTR(SQLERRM,1,4000);
  gc_trcmsg :='1. Error in main'||chr(13);

	/*START: 29-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
        pkg_grp_log_util.prc_update_log_message_r
    (
        n_prcs_job_log_message_id_r => gn_job_log_message_id_r,
        p_err_msg => gc_trcmsg
    );
    /*END: 29-MAY-2025: NEW LOGGING MECHANISM CHANGES*/

  pkg_grp_log_util.prc_update_log ( gn_out_job_id --p_job_id
  ,gc_error_status                                --p_job_status
  ,gc_errmsg                                      --p_err_msg
  ,gc_trcmsg||chr(13)||gc_errmsg                  --p_trc_msg
  ,gc_main_loadedby                               --p_log_util_called_by_r
  );
  RAISE;
END main;
--Procedure to perform ref cursor assignment


PROCEDURE PRC_TEMP_TABLE_DATA_LOAD
AS
 ln_fisc_current_month NUMBER;
  ln_fisc_prior_month   NUMBER;
  ld_fic_mis_date_2     DATE;
  gc_trcmsg                CLOB              :='Trace Message:->';
  LN_SQLROWCNT      NUMBER;
  N_EXISTS NUMBER;

BEGIN

	/*START: 29-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
	gc_trcmsg:='2. Entered into PRC_TEMP_TABLE_DATA_LOAD'||chr(13);
	 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
	 (
		p_job_id_r                    => gn_out_job_id,
		p_batch_id_r                  => gn_sysdt_batchid,
		p_message_type_r              => gc_message_type_r,
		p_code_location_r             => gc_tmp_table_data_load,
		p_message_r                   => gc_trcmsg,
		p_count_type_r                => NULL,
		p_count_r                     => NULL,
		p_duration_r                  => NULL,
		p_created_by_r                => GC_JOB_NAME,
		out_prcs_job_log_message_id_r => gn_job_log_message_id_r
	);
	/*END: 29-MAY-2025: NEW LOGGING MECHANISM CHANGES*/

SELECT  D_CALENDAR_DATE_R +2 ,
  to_number(TO_CHAR(last_day(sysdate)+1,'YYYYMM')) INTO ld_fic_mis_date_2 ,ln_fisc_current_month
  FROM ATOMIC.DIM_TIME_R D
  WHERE V_END_OF_FISCAL_MONTH_IND_R      = 'Y'
  AND TO_CHAR(D_CALENDAR_DATE_R,'YYYYMM')=TO_CHAR(sysdate,'YYYYMM');

   IF TRUNC(ld_fic_mis_date_2)            =TRUNC(sysdate) THEN
    ln_fisc_prior_month                 :=to_number(TO_CHAR(ld_fic_mis_date_2,'YYYYMM'));
    gc_trcmsg                           :=gc_trcmsg||'3.3.1 Fisc Prior Month of the current month is:->'||ln_fisc_prior_month||chr(13);
    gc_trcmsg                           :=gc_trcmsg||'3.4 Today Fisc Month End +2 '||ld_fic_mis_date_2||' hence Updating v_rpt_active_status_r=N against the records loaded in prior fisc month which is :->'||ln_fisc_prior_month||CHR(13);

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
    gc_trcmsg:=gc_trcmsg||'3.11 Completed procedure prc_trunc_partition call from main'||chr(13);
  END IF;

INSERT INTO SSL_PACKAGE_LOG_TABLE(job_name,process_name, start_date, end_date)
    VALUES ('PKG_GRP_LOAD_RPT_DICS_CLAIMS_DETAIL_OAC_R_INC','START: TRUNC LOAD TEMP TABLE:', SYSDATE, NULL);
    COMMIT;
/*START: 29-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
	gc_trcmsg:= '2.1 START: TRUNC LOAD TEMP TABLE: RPT_DICS_CLAIMS_DETAIL_OAC_R_TEMP';
	gt_start_time_r:=SYSTIMESTAMP;
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
	 (
		p_job_id_r                    => gn_out_job_id,
		p_batch_id_r                  => gn_sysdt_batchid,
		p_message_type_r              => gc_message_type_r,
		p_code_location_r             => gc_tmp_table_data_load,
		p_message_r                   => gc_trcmsg,
		p_count_type_r                => NULL,
		p_count_r                     => NULL,
		p_duration_r                  => NULL,
		p_created_by_r                => GC_JOB_NAME,
		out_prcs_job_log_message_id_r => gn_job_log_message_id_r
	);

/*START: 29-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
SELECT COUNT(1) INTO N_EXISTS FROM USER_TABLES WHERE TABLE_NAME ='RPT_DICS_CLAIMS_DETAIL_OAC_R_TEMP';

  IF N_EXISTS<>0 THEN
   EXECUTE IMMEDIATE 'TRUNCATE TABLE RPT_DICS_CLAIMS_DETAIL_OAC_R_TEMP';
  ELSE
   EXECUTE IMMEDIATE 'CREATE TABLE RPT_DICS_CLAIMS_DETAIL_OAC_R_TEMP AS SELECT * FROM RPT_DICS_CLAIMS_DETAIL_OAC_R WHERE 1=2';
  END IF;

 ln_sqlrowcnt := 0;

--EXECUTE IMMEDIATE 'TRUNCATE TABLE RPT_DICS_CLAIMS_DETAIL_OAC_R_TEMP';
EXECUTE IMMEDIATE 'INSERT /*+ APPEND */ INTO RPT_DICS_CLAIMS_DETAIL_OAC_R_TEMP
(
SELECT /*+PARALLEL(4)*/
        ''Claim Department''                                                          AS claims_dept,
        ''P. O. Box 8330''                                                            AS claims_dept_addr1,
        ''Philadelphia, Pennsylvania  19101-8330''                                    AS claims_dept_addr2,
        t3332256.v_policy_number_r                                                  AS policy_number,
        t3332256.v_policy_number_r
        || ''-''
        || t3332275.v_subgroup_id_r                                                  AS policy_subid,
        CASE
            WHEN upper(t3332275.v_correspondent_name_r) LIKE ''ATTN:%'' THEN
                t3332275.v_correspondent_name_r
            ELSE
                ''Attn:'' || t3332275.v_correspondent_name_r
        END                                                                         AS correspondent_name,
        t3332177.v_field_office_name_r                                              AS rso,
        t3332177.v_rso_number_r                                                     AS rso_num,
        t3332275.v_subgroup_name_r                                                  AS group_name,
        t3332177.v_situs_address_line1_r                                            AS v_subgroup_addressline1_r,
        t3332177.v_situs_address_line2_r                                            AS v_subgroup_addressline2_r,
        t3332177.v_situs_city_r                                                     AS v_subgroup_city_r,
        t3332177.v_situs_state_r                                                    AS v_subgroup_provstate_r,
        t3332177.v_situs_zip_code_r                                                 AS v_subgroup_postalzip_r,
        t3332155.v_benefit_code_r                                                   AS v_benefit_code_r,
         CASE WHEN t3332155.v_benefit_code_r=''FIT'' THEN ''FEDERAL INCOME TAX'' ELSE
        t3332155.v_benefit_description_r  end                                       AS v_benefit_description_r,
		(case when t3332155.V_ACH_PAYMENT_IND_R=''Y''
			    THEN ''AC''||t3332155.V_CHECK_NUMBER_R
               else t3332155.V_CHECK_NUMBER_R end
		)	                                                                        AS check_number,
        ( t3332239.n_paid_amount_r )                                                  AS paid_amount,
        t3332275.v_claim_number_r,
        t3332275.n_claim_sk_r,
        t3332155.d_service_period_from_r,
        t3332155.d_service_period_to_r,
        t3332155.d_paid_date_r                                                      AS paid_date,
        t3332239.n_taxable_benefit_amount_r * (t3332275.N_CLAIM_TAXABLE_BENEFIT_PCT_R / 100) as TAXABLE_BENEFITS_,
		SUM (CASE WHEN t3332239.V_BENEFIT_CODE_R NOT IN (''098'', ''097'', ''099'', ''200'', ''297'', ''298'', ''FIC'', ''MED'')
		THEN  t3332239.n_taxable_benefit_amount_r * ( 1 - ( (case when t3332275.v_source_system_name_r = ''CV'' then t3332275.N_CLAIM_TAXABLE_BENEFIT_PCT_R ELSE t3332239.n_taxable_benefit_percentage_r END)/ 100 )) ELSE 0 END )  non_taxable_benefits,
       case when t3332275.v_source_system_name_r = ''CV'' and  t3332239.V_BENEFIT_CODE_R = ''FIT'' then  nvl(t3332239.n_paid_amount_r,0) else  t3332239.n_federal_income_tax_amount_r    end AS fit,
        t3332239.n_state_income_tax_amount_r                                        AS sit,
        t3332239.n_social_security_tax_amount_r                                     AS ss_tax,
        t3332239.n_medicare_tax_amount_r                                            AS medicare_tax,
        t3332239.N_STATE_UNEMPLOYMENT_TAX_AMOUNT_R                                        AS suta_pa_only,
        t3332239.N_SOCIAL_SECURITY_WAGE_BASE_AMOUNT_R                                    AS ss_wage_base,
        t3332239.N_MEDICARE_WAGE_BASE_AMOUNT_R                                            AS medicare_wage_base,
        t3332254.v_claimant_address_line1_r                                         AS v_addressline1_r,
        t3332254.v_claimant_address_line2_r                                         AS v_addressline2_r,
        t3332254.v_claimant_address_line3_r                                         AS v_addressline3_r,
        t3332254.v_claimant_city_r                                                  AS v_city_r,
        t3332254.v_individual_first_name_r
        || '' ''
        || t3332254.v_individual_last_name_r                                         AS insured_name,
         CASE WHEN t3332254.V_SOURCE_SYSTEM_NAME_R=''CV'' then v_claimant_ssn_r
         ELSE
        substr(t3332254.v_claimant_ssn_r, 1, 3)
        || ''-''
        || substr(t3332254.v_claimant_ssn_r, 4, 2)
        || ''-''
        || substr(t3332254.v_claimant_ssn_r, 6, 4) end                                    AS ssn,
        t3332254.v_claimant_state_r                                                 AS v_state_name_r,
        t3332254.v_claimant_zip_code_r                                              AS v_postal_zip_r,
		CASE WHEN t3332275.V_CLAIM_STATUS_CODE_R >= ''60'' THEN ''CLOSED'' ELSE ''OPEN'' END v_claim_status_reason_code_r,
        --case when t3332275.v_source_system_name_r = ''CV'' then 100 else t3332275.n_claim_taxable_benefit_pct_r end AS cs_2,
        -- 29-01-2025 changes end
		t3332275.n_claim_taxable_benefit_pct_r AS cs_2,
        t3332275.d_loss_date_r                                                      AS d_date_of_loss_r,
        t3332177.n_yearmonth_r                                                      AS client_yearmonth,
        t3332275.n_yearmonth_r                                                      AS claim_detail_yearmonth,
        t3332256.n_yearmonth_r                                                      AS policy_detail_yearmonth,
        t3332155.n_yearmonth_r                                                      AS claim_payment_yearmonth,
        t3332239.n_yearmonth_r                                                      AS payment_detail_yearmonth,
		to_number(to_char(t3332155.d_paid_date_r, ''YYYYMM''))                        AS paid_date_r_yearmonth,
		to_number(to_char(t3332155.d_paid_date_r, ''YYYY''))                          AS paid_date_r_year,
		to_number(to_char(t3332155.d_paid_date_r, ''MM''))                            AS paid_date_r_month,
		DIM_TIME_R.N_DATE_SK_R PAID_DATE_SK
		,DIM_TIME_R.N_QUARTER_R PAID_DATE_QTR
		,DECODE(t3332275.v_claim_company_r,''RSL'',''001'',''RSLT'',''003'',''FRSLIC'',''005'',t3332275.v_claim_company_r)||'' - ''||
         case when t3332275.v_claim_company_r=''RSL'' then ''Reliance Standard Life Insurance Company''
         when t3332275.v_claim_company_r=''FRSLIC'' then ''First Reliance Standard Life Insurance Company''
         when t3332275.v_claim_company_r=''RSLT'' then ''Reliance Standard Life Insurance Company of Texas''
         else t3332275.v_claim_company_r end as Company_Name
		 ,t3332275.v_coverage_type_code_r  COVERAGE_TYPE
         ,''PKG_GRP_LOAD_RPT_DICS_CLAIMS_DETAIL_OAC_R.PRC_GET_CUR_DATA''       AS   V_LAST_MODIFIED_BY_R
         , systimestamp  AS   T_CREATION_DATE_R
		 ,''PKG_GRP_LOAD_RPT_DICS_CLAIMS_DETAIL_OAC_R.PRC_GET_CUR_DATA''       AS   V_CREATED_BY_R
		 ,systimestamp              AS   T_LAST_MODIFIED_DATE_R
		 ,' || gn_current_month || '   AS  N_YEARMONTH_R
		 ,''Y''                              V_RPT_ACTIVE_STATUS_R
         ,TO_NUMBER(TO_CHAR(TRUNC(SYSDATE),''YYYYMMDD''))       AS    N_BATCH_ID_R
		 ,CASE WHEN t3332256.V_RSL_EIN_IND_R = ''X'' THEN ''X''
        WHEN t3332256.V_RSL_EIN_IND_R = ''Y'' THEN ''Y''
        ELSE ''N''
        END     AS  V_RSL_EIN_IND_R
		,t3332275.v_privacy_indicator_r AS V_PRIVACY_INDICATOR_R
        , CASE WHEN NVL(t3332275.V_CLAIM_COVERAGE_CODE_R,''-'')  = ''PFL'' THEN ''Y''
          ELSE ''N''
          END AS V_PFL_INDICATOR
		,t3332254.V_EMPLOYEE_NUM_R AS V_CLAIMANT_EMPLOYEE_NUMBER_R
    FROM
        ATOMIC.rpt_client_dtl_r         t3332177 ,
        ATOMIC.rpt_claimant_dtl_r       t3332254 ,
        ATOMIC.rpt_claim_dtl_r          t3332275 ,
        ATOMIC.rpt_policy_dtl_r         t3332256 ,
        ATOMIC.rpt_claim_payment_r      t3332155 ,
        ATOMIC.rpt_claim_payment_dtl_r  t3332239
        ,ATOMIC.DIM_TIME_R

    WHERE
          t3332177.n_cust_party_sk_r = t3332239.n_cust_party_sk_r
          AND t3332177.n_yearmonth_r = t3332239.n_yearmonth_r
          AND t3332239.n_policy_sk_r = t3332256.n_policy_sk_r
          AND t3332239.n_insrd_party_sk_r = t3332254.n_insrd_party_sk_r
          AND t3332239.n_yearmonth_r = t3332254.n_yearmonth_r
          AND t3332155.n_payment_sk_r = t3332239.n_payment_sk_r
          AND t3332155.n_yearmonth_r = t3332239.n_yearmonth_r
          AND t3332239.n_claim_coverage_group_sk_r = t3332275.n_claim_coverage_group_sk_r
          AND t3332239.n_claim_coverage_sk_r = t3332275.n_claim_coverage_sk_r
          AND t3332239.n_claim_sk_r = t3332275.n_claim_sk_r
          AND t3332239.n_yearmonth_r = t3332256.n_yearmonth_r
          AND t3332239.n_yearmonth_r = t3332275.n_yearmonth_r
		  and t3332155.d_paid_date_r = DIM_TIME_R.D_CALENDAR_DATE_R
		  --AND T3332256.v_orig_lob_r in (''LTD'',''VPL'',''VPS'',''STD'')
		  		  		  		  		  AND (
NVL(t3332275.V_COVERAGE_TYPE_CODE_R,''X'') IN (''LTD'',''STD'')

OR

NVL(T3332256.V_ORIG_LOB_R,''X'') IN (SELECT V_COVERAGE_CODE_R FROM ATOMIC.DIM_GRP_PRODUCT_R WHERE NVL(V_COVERAGE_TYPE_CODE_R,''X'') IN (''1'',''2''))
)
		  AND t3332155.V_CHECK_TYPE_R <> ''OE''
          AND to_number(to_char(t3332155.d_paid_date_r, ''YYYY'')) >= to_number(to_char(add_months(trunc(sysdate, ''YYYY''), - 12 * 6),''YYYY''))
		  AND t3332275.n_yearmonth_r = ' || gn_current_month || '
		  and not  (t3332275.V_SOURCE_SYSTEM_NAME_R=''CV'' and T3332155.V_RECORD_TYPE_R = ''Gross Benefit'')
	GROUP BY
        t3332256.v_policy_number_r                                                  ,
        t3332256.v_policy_number_r
        || ''-''
        || t3332275.v_subgroup_id_r                                                 ,
        CASE
            WHEN upper(t3332275.v_correspondent_name_r) LIKE ''ATTN:%'' THEN
                t3332275.v_correspondent_name_r
            ELSE
                ''Attn:'' || t3332275.v_correspondent_name_r
        END                                                                         ,
        t3332177.v_field_office_name_r                                              ,
        t3332177.v_rso_number_r                                                     ,
        t3332275.v_subgroup_name_r                                                  ,
        t3332177.v_situs_address_line1_r                                            ,
        t3332177.v_situs_address_line2_r                                            ,
        t3332177.v_situs_city_r                                                     ,
        t3332177.v_situs_state_r                                                    ,
        t3332177.v_situs_zip_code_r                                                 ,
        t3332155.v_benefit_code_r                                                   ,
         CASE WHEN t3332155.v_benefit_code_r=''FIT'' THEN ''FEDERAL INCOME TAX'' ELSE
        t3332155.v_benefit_description_r  end                                        ,
		(case when t3332155.V_ACH_PAYMENT_IND_R=''Y''
			    THEN ''AC''||t3332155.V_CHECK_NUMBER_R
               else t3332155.V_CHECK_NUMBER_R end
		)	                                                                       ,
        ( t3332239.n_paid_amount_r )                                                 ,
        t3332275.v_claim_number_r,
        t3332275.n_claim_sk_r,
        t3332155.d_service_period_from_r,
        t3332155.d_service_period_to_r,
        t3332155.d_paid_date_r                                                      ,
        case when t3332275.v_source_system_name_r = ''CV'' and  t3332239.V_BENEFIT_CODE_R = ''FIT'' then  nvl(t3332239.n_paid_amount_r,0) else  t3332239.n_federal_income_tax_amount_r end,
        t3332239.n_state_income_tax_amount_r                                        ,
        t3332239.n_social_security_tax_amount_r                                     ,
        t3332239.n_medicare_tax_amount_r                                            ,
        t3332239.N_STATE_UNEMPLOYMENT_TAX_AMOUNT_R                                        ,
        t3332239.N_SOCIAL_SECURITY_WAGE_BASE_AMOUNT_R                                   ,
        t3332239.N_MEDICARE_WAGE_BASE_AMOUNT_R                                            ,
        t3332254.v_claimant_address_line1_r                                          ,
        t3332254.v_claimant_address_line2_r                                          ,
        t3332254.v_claimant_address_line3_r                                          ,
        t3332254.v_claimant_city_r                                                   ,
        t3332254.v_individual_first_name_r
        || '' ''
        || t3332254.v_individual_last_name_r                                         ,
         CASE WHEN t3332254.V_SOURCE_SYSTEM_NAME_R=''CV'' then v_claimant_ssn_r
         ELSE
        substr(t3332254.v_claimant_ssn_r, 1, 3)
        || ''-''
        || substr(t3332254.v_claimant_ssn_r, 4, 2)
        || ''-''
        || substr(t3332254.v_claimant_ssn_r, 6, 4)  end                             ,
        t3332254.v_claimant_state_r                                                 ,
        t3332254.v_claimant_zip_code_r                                              ,
        t3332275.v_claim_status_desc_r                                               ,
	    t3332275.n_claim_taxable_benefit_pct_r,
        t3332275.d_loss_date_r                                                       ,
        t3332177.n_yearmonth_r                                                       ,
        t3332275.n_yearmonth_r                                                       ,
        t3332256.n_yearmonth_r                                                       ,
        t3332155.n_yearmonth_r                                                       ,
        t3332239.n_yearmonth_r                                                       ,
		to_number(to_char(t3332155.d_paid_date_r, ''YYYYMM''))                         ,
		to_number(to_char(t3332155.d_paid_date_r, ''YYYY''))                           ,
		to_number(to_char(t3332155.d_paid_date_r, ''MM''))                             ,
		DIM_TIME_R.N_DATE_SK_R
		,DIM_TIME_R.N_QUARTER_R
		,DECODE(t3332275.v_claim_company_r,''RSL'',''001'',''RSLT'',''003'',''FRSLIC'',''005'',t3332275.v_claim_company_r)||'' - ''||
         case when t3332275.v_claim_company_r=''RSL'' then ''Reliance Standard Life Insurance Company''
         when t3332275.v_claim_company_r=''FRSLIC'' then ''First Reliance Standard Life Insurance Company''
         when t3332275.v_claim_company_r=''RSLT'' then ''Reliance Standard Life Insurance Company of Texas''
         else t3332275.v_claim_company_r end
		 ,t3332275.v_coverage_type_code_r
		 ,CASE WHEN t3332256.V_RSL_EIN_IND_R = ''X'' THEN ''X''
        WHEN t3332256.V_RSL_EIN_IND_R = ''Y'' THEN ''Y''
        ELSE ''N''
        END
		,t3332275.v_privacy_indicator_r
        ,t3332239.n_taxable_benefit_amount_r * (t3332275.N_CLAIM_TAXABLE_BENEFIT_PCT_R / 100)
        ,t3332275.V_CLAIM_STATUS_CODE_R
        ,
         CASE WHEN NVL(t3332275.V_CLAIM_COVERAGE_CODE_R,''-'')  = ''PFL'' THEN ''Y''
          ELSE ''N''
          END
		,t3332254.V_EMPLOYEE_NUM_R
        )';
         ln_sqlrowcnt := SQL%ROWCOUNT;
        COMMIT;

     INSERT INTO SSL_PACKAGE_LOG_TABLE(job_name,process_name, start_date, end_date,SOURCE_TABLE_COUNT)
     VALUES ('PKG_GRP_LOAD_RPT_DICS_CLAIMS_DETAIL_OAC_R_INC','END: TRUNC-LOAD TEMP TABLE:',  NULL,SYSDATE,ln_sqlrowcnt);
     COMMIT;

	/*START: 29-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
	gc_trcmsg:='2.2 END: TRUNC-LOAD TEMP TABLE: RPT_DICS_CLAIMS_DETAIL_OAC_R_TEMP';
	gt_end_time_r:= SYSTIMESTAMP;
	gc_duration_r := EXTRACT(SECOND FROM (gt_end_time_r - gt_start_time_r)) +
					 EXTRACT(MINUTE FROM (gt_end_time_r - gt_start_time_r)) * 60 +
					 EXTRACT(HOUR FROM (gt_end_time_r - gt_start_time_r)) * 3600;

	 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
	 (
		p_job_id_r                    => gn_out_job_id,
		p_batch_id_r                  => gn_sysdt_batchid,
		p_message_type_r              => gc_message_type_r,
		p_code_location_r             => gc_tmp_table_data_load,
		p_message_r                   => gc_trcmsg,
		p_count_type_r                => gc_count_type_r,
		p_count_r                     => ln_sqlrowcnt,
		p_duration_r                  => gc_duration_r,
		p_created_by_r                => GC_JOB_NAME,
		out_prcs_job_log_message_id_r => gn_job_log_message_id_r
	);

	gc_trcmsg:='2.z Exit from PRC_TEMP_TABLE_DATA_LOAD'||chr(13);
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
	 (
		p_job_id_r                    => gn_out_job_id,
		p_batch_id_r                  => gn_sysdt_batchid,
		p_message_type_r              => gc_message_type_r,
		p_code_location_r             => gc_tmp_table_data_load,
		p_message_r                   => gc_trcmsg,
		p_count_type_r                => NULL,
		p_count_r                     => NULL,
		p_duration_r                  => NULL,
		p_created_by_r                => GC_JOB_NAME,
		out_prcs_job_log_message_id_r => gn_job_log_message_id_r
	);

	/*END: 29-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
EXCEPTION
WHEN OTHERS THEN
  gc_errmsg :=SUBSTR(SQLERRM,1,4000);
  gc_trcmsg :='2.z Error in PRC_TEMP_TABLE_DATA_LOAD'||chr(13);

  	/*START: 29-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
        pkg_grp_log_util.prc_update_log_message_r
    (
        n_prcs_job_log_message_id_r => gn_job_log_message_id_r,
        p_err_msg => gc_trcmsg
    );
    /*END: 29-MAY-2025: NEW LOGGING MECHANISM CHANGES*/

  pkg_grp_log_util.prc_update_log ( p_job_id => gn_out_job_id
  ,p_job_status => gc_error_status
  ,p_err_msg => gc_errmsg
  ,p_trc_msg => chr(13)||gc_errmsg
  ,p_log_util_called_by_r => gc_tmp_table_data_load
  );
  RAISE;
END PRC_TEMP_TABLE_DATA_LOAD;


PROCEDURE prc_get_cur_data
  (
    p_out_cursor OUT SYS_REFCURSOR
  )
AS
BEGIN


  gc_trcmsg:=gc_trcmsg||'4.1 Entered into prc_get_cur_data '||chr(13);
  --Open/Assign SELECT stmnt
  OPEN p_out_cursor FOR
    -- SQL for RPT_DICS_CLAIMS_DETAIL_OAC_R
  SELECT /*+PARALLEL(8)*/
        'Claim Department'                                                          AS claims_dept,
        'P. O. Box 8330'                                                            AS claims_dept_addr1,
        'Philadelphia, Pennsylvania  19101-8330'                                    AS claims_dept_addr2,
        t3332256.v_policy_number_r                                                  AS policy_number,
        t3332256.v_policy_number_r
        || '-'
        || t3332275.v_subgroup_id_r                                                  AS policy_subid,
        CASE
            WHEN upper(t3332275.v_correspondent_name_r) LIKE 'ATTN:%' THEN
                t3332275.v_correspondent_name_r
            ELSE
                'Attn:' || t3332275.v_correspondent_name_r
        END                                                                         AS correspondent_name,
        t3332177.v_field_office_name_r                                              AS rso,
        t3332177.v_rso_number_r                                                     AS rso_num,
        t3332275.v_subgroup_name_r                                                  AS group_name,
        t3332177.v_situs_address_line1_r                                            AS v_subgroup_addressline1_r,
        t3332177.v_situs_address_line2_r                                            AS v_subgroup_addressline2_r,
        t3332177.v_situs_city_r                                                     AS v_subgroup_city_r,
        t3332177.v_situs_state_r                                                    AS v_subgroup_provstate_r,
        t3332177.v_situs_zip_code_r                                                 AS v_subgroup_postalzip_r,
        t3332155.v_benefit_code_r                                                   AS v_benefit_code_r,
        -- Add Case condition on 20-01-2025 -- CASE WHEN t3332155.v_benefit_code_r='FIT' THEN 'FEDERAL INCOME TAX' ELSE
         CASE WHEN t3332155.v_benefit_code_r='FIT' THEN 'FEDERAL INCOME TAX' ELSE
        t3332155.v_benefit_description_r  end                                       AS v_benefit_description_r,
        --t3332155.v_check_number_r,
		(case when t3332155.V_ACH_PAYMENT_IND_R='Y'
			    THEN 'AC'||t3332155.V_CHECK_NUMBER_R
               else t3332155.V_CHECK_NUMBER_R end
		)	                                                                        AS check_number,
        ( t3332239.n_paid_amount_r )                                                  AS paid_amount,
        t3332275.v_claim_number_r,
        t3332275.n_claim_sk_r,
        t3332155.d_service_period_from_r,
        t3332155.d_service_period_to_r,
        t3332155.d_paid_date_r                                                      AS paid_date,
       -- ( t3332239.n_taxable_benefit_amount_r )                                       AS taxable_benefits_,
        --(( t3332239.n_taxable_benefit_amount_r * t3332239.n_taxable_benefit_percentage_r)/100)  AS taxable_benefits_,
        --( t3332239.n_paid_amount_r ) - ( t3332239.n_taxable_benefit_amount_r )            AS non_taxable_benefits,
		/*17-10-24 Changes Starts*/--suggested as an enhancement
		--SUM (CASE WHEN t3332239.V_BENEFIT_CODE_R NOT IN ('098', '097', '099', '200', '297', '298', 'FIC', 'MED')
		--THEN t3332239.n_taxable_benefit_amount_r * ( t3332239.n_taxable_benefit_percentage_r / 100 ) ELSE 0 END ) TAXABLE_BENEFITS_,
		--t3332239.n_taxable_benefit_amount_r * (t3332275.N_CLAIM_TAXABLE_BENEFIT_PCT_R/100) as TAXABLE_BENEFITS_,  --23-Oct-24 Changes -- --23-01-2025 commneted
        /*t3332239.n_taxable_benefit_amount_r * (case when t3332275.v_source_system_name_r = 'CV' then 100 else t3332275.N_CLAIM_TAXABLE_BENEFIT_PCT_R end /100)as TAXABLE_BENEFITS_,*/ --23-01-2025 added
		t3332239.n_taxable_benefit_amount_r * (t3332275.N_CLAIM_TAXABLE_BENEFIT_PCT_R / 100) as TAXABLE_BENEFITS_,--14-Jan-2026: Added by Ananthan
		/*SUM (CASE WHEN t3332239.V_BENEFIT_CODE_R NOT IN ('098', '097', '099', '200', '297', '298', 'FIC', 'MED')
		THEN  t3332239.n_taxable_benefit_amount_r * ( 1 - ( t3332239.n_taxable_benefit_percentage_r/ 100 )) ELSE 0 END )  non_taxable_benefits,*/
		/*17-10-24 Changes Ends*/
		SUM (CASE WHEN t3332239.V_BENEFIT_CODE_R NOT IN ('098', '097', '099', '200', '297', '298', 'FIC', 'MED')
		THEN  t3332239.n_taxable_benefit_amount_r * ( 1 - ( (case when t3332275.v_source_system_name_r = 'CV' then t3332275.N_CLAIM_TAXABLE_BENEFIT_PCT_R ELSE t3332239.n_taxable_benefit_percentage_r END)/ 100 )) ELSE 0 END )  non_taxable_benefits,--14-Jan-2026: Added by Ananthan
       -- t3332239.n_federal_income_tax_amount_r                                      AS fit,  --23-01-2025 Commented
       case when t3332275.v_source_system_name_r = 'CV' and  t3332239.V_BENEFIT_CODE_R = 'FIT' then  nvl(t3332239.n_paid_amount_r,0) else  t3332239.n_federal_income_tax_amount_r    end AS fit,   --23-01-2025 added
        t3332239.n_state_income_tax_amount_r                                        AS sit,
        t3332239.n_social_security_tax_amount_r                                     AS ss_tax,
        t3332239.n_medicare_tax_amount_r                                            AS medicare_tax,
        /*(
            CASE
                WHEN t3332155.v_benefit_code_r IN ( '097' ) THEN
                    t3332239.n_paid_amount_r
                ELSE
                    0
            END
        )*/t3332239.N_STATE_UNEMPLOYMENT_TAX_AMOUNT_R                                        AS suta_pa_only,
        /*(
            CASE
                WHEN t3332155.v_benefit_code_r IN ( '098' ) THEN
                    t3332239.n_social_security_wage_base_amount_r
                ELSE
                    0
            END
        )*/t3332239.N_SOCIAL_SECURITY_WAGE_BASE_AMOUNT_R                                    AS ss_wage_base,
        /*(
            CASE
                WHEN t3332155.v_benefit_code_r IN ( '298' ) THEN
                    t3332239.n_medicare_wage_base_amount_r
                ELSE
                    0
            END
        )*/t3332239.N_MEDICARE_WAGE_BASE_AMOUNT_R                                            AS medicare_wage_base,
        t3332254.v_claimant_address_line1_r                                         AS v_addressline1_r,
        t3332254.v_claimant_address_line2_r                                         AS v_addressline2_r,
        t3332254.v_claimant_address_line3_r                                         AS v_addressline3_r,
        t3332254.v_claimant_city_r                                                  AS v_city_r,
        t3332254.v_individual_first_name_r
        || ' '
        || t3332254.v_individual_last_name_r                                         AS insured_name,
        --Add case stetement 20-10-2025 Start --CASZE WHEN t3332254.V_SOURCE_SYSTEM_NAME_R='CV' then v_claimant_ssn_r ELSE
         CASE WHEN t3332254.V_SOURCE_SYSTEM_NAME_R='CV' then v_claimant_ssn_r
         ELSE
         --Add case stetement 20-10-2025 End
        substr(t3332254.v_claimant_ssn_r, 1, 3)
        || '-'
        || substr(t3332254.v_claimant_ssn_r, 4, 2)
        || '-'
        || substr(t3332254.v_claimant_ssn_r, 6, 4) end                                    AS ssn,
        t3332254.v_claimant_state_r                                                 AS v_state_name_r,
        t3332254.v_claimant_zip_code_r                                              AS v_postal_zip_r,
		/* t3332275.v_claim_status_desc_r                                              AS v_claim_status_reason_code_r,*/ --old logic
		CASE WHEN t3332275.V_CLAIM_STATUS_CODE_R >= '60' THEN 'CLOSED' ELSE 'OPEN' END v_claim_status_reason_code_r,
	   -- 29-01-2025 changes start
    --	t3332275.n_claim_taxable_benefit_pct_r                                      AS cs_2,
        /*case when t3332275.v_source_system_name_r = 'CV' then 100 else t3332275.n_claim_taxable_benefit_pct_r end AS cs_2,*/
        -- 29-01-2025 changes end
		t3332275.n_claim_taxable_benefit_pct_r AS cs_2,--14-Jan-2026: Added by Ananthan
        t3332275.d_loss_date_r                                                      AS d_date_of_loss_r,
        t3332177.n_yearmonth_r                                                      AS client_yearmonth,
        t3332275.n_yearmonth_r                                                      AS claim_detail_yearmonth,
        t3332256.n_yearmonth_r                                                      AS policy_detail_yearmonth,
        t3332155.n_yearmonth_r                                                      AS claim_payment_yearmonth,
        t3332239.n_yearmonth_r                                                      AS payment_detail_yearmonth,
		to_number(to_char(t3332155.d_paid_date_r, 'YYYYMM'))                        AS paid_date_r_yearmonth,
		to_number(to_char(t3332155.d_paid_date_r, 'YYYY'))                          AS paid_date_r_year,
		to_number(to_char(t3332155.d_paid_date_r, 'MM'))                            AS paid_date_r_month--,
		--(select N_DATE_SK_R from dim_time_r d where D_CALENDAR_DATE_R = t3332155.d_paid_date_r) AS PAID_DATE_SK
		--(select N_QUARTER_R from dim_time_r d where D_CALENDAR_DATE_R = t3332155.d_paid_date_r) AS PAID_DATE_QTR
		,DIM_TIME_R.N_DATE_SK_R PAID_DATE_SK
		,DIM_TIME_R.N_QUARTER_R PAID_DATE_QTR
		,DECODE(t3332275.v_claim_company_r,'RSL','001','RSLT','003','FRSLIC','005',t3332275.v_claim_company_r)||' - '||
         case when t3332275.v_claim_company_r='RSL' then 'Reliance Standard Life Insurance Company'
         when t3332275.v_claim_company_r='FRSLIC' then 'First Reliance Standard Life Insurance Company'
         when t3332275.v_claim_company_r='RSLT' then 'Reliance Standard Life Insurance Company of Texas'
         else t3332275.v_claim_company_r end as Company_Name
		 ,t3332275.v_coverage_type_code_r  COVERAGE_TYPE
		 ,gc_getcur_loadedby               V_LAST_MODIFIED_BY_R
		 ,gd_sysdate                       T_CREATION_DATE_R
		 ,gc_getcur_loadedby               V_CREATED_BY_R
		 ,gd_sysdate                       T_LAST_MODIFIED_DATE_R
		 ,gn_current_month                 N_YEARMONTH_R
		 ,'Y'                              V_RPT_ACTIVE_STATUS_R
		 ,gn_sysdt_batchid                 N_BATCH_ID_R
		 --08/10/2024 CHANGES START
		 ,CASE WHEN t3332256.V_RSL_EIN_IND_R = 'X' THEN 'X'
        WHEN t3332256.V_RSL_EIN_IND_R = 'Y' THEN 'Y'
        ELSE 'N'
        END     AS  V_RSL_EIN_IND_R
		,t3332275.v_privacy_indicator_r AS V_PRIVACY_INDICATOR_R
        --08/10/2024 CHANGES END
        -- 03/02/2025 Changes start
        , CASE WHEN NVL(t3332275.V_CLAIM_COVERAGE_CODE_R,'-')  = 'PFL' THEN 'Y'
          ELSE 'N'
          END AS V_PFL_INDICATOR
        -- 03/02/2025 Changes end
		,t3332254.V_EMPLOYEE_NUM_R AS V_CLAIMANT_EMPLOYEE_NUMBER_R /*31/12/2025 - Added by Ananthan as part of DevOps Bug 475507*/
    FROM
        rpt_client_dtl_r         t3332177 /* D_RPT_CLIENT_DTL */,
        rpt_claimant_dtl_r       t3332254 /* D_RPT_CLAIMANT_DTL */,
        rpt_claim_dtl_r          t3332275 /* D_RPT_CLAIM_DTL */,
        rpt_policy_dtl_r         t3332256 /* D_RPT_POLICY_DTL */,
        rpt_claim_payment_r      t3332155 /* D_RPT_CLAIM_PAYMENT */,
        rpt_claim_payment_dtl_r  t3332239 /* F_RPT_CLAIM_PAYMENT_DTL_R */
        ,DIM_TIME_R

    WHERE
          t3332177.n_cust_party_sk_r = t3332239.n_cust_party_sk_r
          AND t3332177.n_yearmonth_r = t3332239.n_yearmonth_r
          AND t3332239.n_policy_sk_r = t3332256.n_policy_sk_r
          AND t3332239.n_insrd_party_sk_r = t3332254.n_insrd_party_sk_r
          AND t3332239.n_yearmonth_r = t3332254.n_yearmonth_r
          AND t3332155.n_payment_sk_r = t3332239.n_payment_sk_r
          AND t3332155.n_yearmonth_r = t3332239.n_yearmonth_r
          AND t3332239.n_claim_coverage_group_sk_r = t3332275.n_claim_coverage_group_sk_r
          AND t3332239.n_claim_coverage_sk_r = t3332275.n_claim_coverage_sk_r
          AND t3332239.n_claim_sk_r = t3332275.n_claim_sk_r
          AND t3332239.n_yearmonth_r = t3332256.n_yearmonth_r
          AND t3332239.n_yearmonth_r = t3332275.n_yearmonth_r
		  and t3332155.d_paid_date_r = DIM_TIME_R.D_CALENDAR_DATE_R
          --and T3332155.D_PAID_DATE_R between '01-JAN-18' and '26-MAY-24'
		  --AND T3332256.v_orig_lob_r in ('LTD','VPL','VPS','STD')
		  		  AND (
NVL(t3332275.V_COVERAGE_TYPE_CODE_R,'X') IN ('LTD','STD')

OR

NVL(T3332256.V_ORIG_LOB_R,'X') IN (SELECT V_COVERAGE_CODE_R FROM ATOMIC.DIM_GRP_PRODUCT_R WHERE NVL(V_COVERAGE_TYPE_CODE_R,'X') IN ('1','2'))
)
		  AND t3332155.V_CHECK_TYPE_R <> 'OE'
          AND to_number(to_char(t3332155.d_paid_date_r, 'YYYY')) >= to_number(to_char(add_months(trunc(sysdate, 'YYYY'), - 12 * 6),'YYYY'))
		  AND t3332275.n_yearmonth_r = gn_current_month
		  -- 21-01-2025 Changes Start
		  and not  (t3332275.V_SOURCE_SYSTEM_NAME_R='CV' and T3332155.V_RECORD_TYPE_R = 'Gross Benefit')
		  -- 21-01-2025 Changes Start
	GROUP BY
		'Claim Department'                                                          ,
        'P. O. Box 8330'                                                            ,
        'Philadelphia, Pennsylvania  19101-8330'                                    ,
        t3332256.v_policy_number_r                                                  ,
        t3332256.v_policy_number_r
        || '-'
        || t3332275.v_subgroup_id_r                                                 ,
        CASE
            WHEN upper(t3332275.v_correspondent_name_r) LIKE 'ATTN:%' THEN
                t3332275.v_correspondent_name_r
            ELSE
                'Attn:' || t3332275.v_correspondent_name_r
        END                                                                         ,
        t3332177.v_field_office_name_r                                              ,
        t3332177.v_rso_number_r                                                     ,
        t3332275.v_subgroup_name_r                                                  ,
        t3332177.v_situs_address_line1_r                                            ,
        t3332177.v_situs_address_line2_r                                            ,
        t3332177.v_situs_city_r                                                     ,
        t3332177.v_situs_state_r                                                    ,
        t3332177.v_situs_zip_code_r                                                 ,
        t3332155.v_benefit_code_r                                                   ,
        -- Add Case condition on 20-01-2025 -- CASE WHEN t3332155.v_benefit_code_r='FIT' THEN 'FEDERAL INCOME TAX' ELSE
         CASE WHEN t3332155.v_benefit_code_r='FIT' THEN 'FEDERAL INCOME TAX' ELSE
        t3332155.v_benefit_description_r  end                                        ,
        --t3332155.v_check_number_r,
		(case when t3332155.V_ACH_PAYMENT_IND_R='Y'
			    THEN 'AC'||t3332155.V_CHECK_NUMBER_R
               else t3332155.V_CHECK_NUMBER_R end
		)	                                                                       ,
        ( t3332239.n_paid_amount_r )                                                 ,
        t3332275.v_claim_number_r,
        t3332275.n_claim_sk_r,
        t3332155.d_service_period_from_r,
        t3332155.d_service_period_to_r,
        t3332155.d_paid_date_r                                                      ,
       -- ( t3332239.n_taxable_benefit_amount_r )                                       AS taxable_benefits_,
        --(( t3332239.n_taxable_benefit_amount_r * t3332239.n_taxable_benefit_percentage_r)/100)  AS taxable_benefits_,
        --( t3332239.n_paid_amount_r ) - ( t3332239.n_taxable_benefit_amount_r )            AS non_taxable_benefits,
      --  t3332239.n_federal_income_tax_amount_r                                      ,  --23-01-2025
        case when t3332275.v_source_system_name_r = 'CV' and  t3332239.V_BENEFIT_CODE_R = 'FIT' then  nvl(t3332239.n_paid_amount_r,0) else  t3332239.n_federal_income_tax_amount_r end,
        t3332239.n_state_income_tax_amount_r                                        ,
        t3332239.n_social_security_tax_amount_r                                     ,
        t3332239.n_medicare_tax_amount_r                                            ,
        /*(
            CASE
                WHEN t3332155.v_benefit_code_r IN ( '097' ) THEN
                    t3332239.n_paid_amount_r
                ELSE
                    0
            END
        )*/t3332239.N_STATE_UNEMPLOYMENT_TAX_AMOUNT_R                                        ,
        /*(
            CASE
                WHEN t3332155.v_benefit_code_r IN ( '098' ) THEN
                    t3332239.n_social_security_wage_base_amount_r
                ELSE
                    0
            END
        )*/t3332239.N_SOCIAL_SECURITY_WAGE_BASE_AMOUNT_R                                   ,
        /*(
            CASE
                WHEN t3332155.v_benefit_code_r IN ( '298' ) THEN
                    t3332239.n_medicare_wage_base_amount_r
                ELSE
                    0
            END
        )*/t3332239.N_MEDICARE_WAGE_BASE_AMOUNT_R                                            ,
        t3332254.v_claimant_address_line1_r                                          ,
        t3332254.v_claimant_address_line2_r                                          ,
        t3332254.v_claimant_address_line3_r                                          ,
        t3332254.v_claimant_city_r                                                   ,
        t3332254.v_individual_first_name_r
        || ' '
        || t3332254.v_individual_last_name_r                                         ,
        --Add case stetement 20-10-2025 Start --CASE WHEN t3332254.V_SOURCE_SYSTEM_NAME_R='CV' then v_claimant_ssn_r ELSE
         CASE WHEN t3332254.V_SOURCE_SYSTEM_NAME_R='CV' then v_claimant_ssn_r
         ELSE
         --Add case stetement 20-10-2025 End
        substr(t3332254.v_claimant_ssn_r, 1, 3)
        || '-'
        || substr(t3332254.v_claimant_ssn_r, 4, 2)
        || '-'
        || substr(t3332254.v_claimant_ssn_r, 6, 4)  end                             ,
        t3332254.v_claimant_state_r                                                 ,
        t3332254.v_claimant_zip_code_r                                              ,
        t3332275.v_claim_status_desc_r                                               ,
      --  t3332275.n_claim_taxable_benefit_pct_r                                       ,
	    /*case when t3332275.v_source_system_name_r = 'CV' then 100 else t3332275.n_claim_taxable_benefit_pct_r end, */
		t3332275.n_claim_taxable_benefit_pct_r,--14-Jan-2026: Added by Ananthan
        t3332275.d_loss_date_r                                                       ,
        t3332177.n_yearmonth_r                                                       ,
        t3332275.n_yearmonth_r                                                       ,
        t3332256.n_yearmonth_r                                                       ,
        t3332155.n_yearmonth_r                                                       ,
        t3332239.n_yearmonth_r                                                       ,
		to_number(to_char(t3332155.d_paid_date_r, 'YYYYMM'))                         ,
		to_number(to_char(t3332155.d_paid_date_r, 'YYYY'))                           ,
		to_number(to_char(t3332155.d_paid_date_r, 'MM'))                             --,
		--(select N_DATE_SK_R from dim_time_r d where D_CALENDAR_DATE_R = t3332155.d_paid_date_r) AS PAID_DATE_SK
		--(select N_QUARTER_R from dim_time_r d where D_CALENDAR_DATE_R = t3332155.d_paid_date_r) AS PAID_DATE_QTR
		,DIM_TIME_R.N_DATE_SK_R
		,DIM_TIME_R.N_QUARTER_R
		,DECODE(t3332275.v_claim_company_r,'RSL','001','RSLT','003','FRSLIC','005',t3332275.v_claim_company_r)||' - '||
         case when t3332275.v_claim_company_r='RSL' then 'Reliance Standard Life Insurance Company'
         when t3332275.v_claim_company_r='FRSLIC' then 'First Reliance Standard Life Insurance Company'
         when t3332275.v_claim_company_r='RSLT' then 'Reliance Standard Life Insurance Company of Texas'
         else t3332275.v_claim_company_r end
		 ,t3332275.v_coverage_type_code_r
		 ,gc_getcur_loadedby
		 ,gd_sysdate
		 ,gc_getcur_loadedby
		 ,gd_sysdate
		 ,gn_current_month
		 ,'Y'
		 ,gn_sysdt_batchid
		 --08/10/2024 CHANGES START
		 ,CASE WHEN t3332256.V_RSL_EIN_IND_R = 'X' THEN 'X'
        WHEN t3332256.V_RSL_EIN_IND_R = 'Y' THEN 'Y'
        ELSE 'N'
        END
		,t3332275.v_privacy_indicator_r
		--,t3332239.n_taxable_benefit_amount_r * (t3332275.N_CLAIM_TAXABLE_BENEFIT_PCT_R/100)
        /*, t3332239.n_taxable_benefit_amount_r * (case when t3332275.v_source_system_name_r = 'CV' then 100 else t3332275.N_CLAIM_TAXABLE_BENEFIT_PCT_R end /100)*/
		,t3332239.n_taxable_benefit_amount_r * (t3332275.N_CLAIM_TAXABLE_BENEFIT_PCT_R / 100)--14-Jan-2026: Added by Ananthan
        ,t3332275.V_CLAIM_STATUS_CODE_R
        , -- 03/02/2025 Changes start
         CASE WHEN NVL(t3332275.V_CLAIM_COVERAGE_CODE_R,'-')  = 'PFL' THEN 'Y'
          ELSE 'N'
          END
        -- 03/02/2025 Changes end
        ,t3332254.V_EMPLOYEE_NUM_R /*31/12/2025 - Added by Ananthan as part of DevOps Bug 475507*/
		;



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
--Procedure to rebuild indexes RPT_DICS_CLAIMS_DETAIL_OAC_R
PROCEDURE prc_rebuild_indexes
IS
  LC_REBUILD_INDEX VARCHAR2(300);
BEGIN
  gc_trcmsg:=gc_trcmsg||'7.a Entered into prc_rebuild_indexes'||chr(13);

  INSERT INTO SSL_PACKAGE_LOG_TABLE(job_name,process_name, start_date, end_date)
   VALUES ('PKG_GRP_LOAD_RPT_DICS_CLAIMS_DETAIL_OAC_R_INC','START: REBUILD_UNUSABLE INDEX:',SYSDATE,NULL);
   COMMIT;

  FOR I IN
  (SELECT 'ALTER INDEX '
      ||INDEX_NAME
      ||' REBUILD parallel 8 nologging' REBUILD_INDEX
    FROM ALL_INDEXES
    WHERE TABLE_NAME ='RPT_DICS_CLAIMS_DETAIL_OAC_R'
    AND INDEX_NAME NOT LIKE 'PK_%'
    AND INDEX_NAME NOT LIKE 'FK_%'
	AND STATUS='UNUSABLE'
  )
  LOOP
    LC_REBUILD_INDEX:=I.REBUILD_INDEX;
    EXECUTE IMMEDIATE LC_REBUILD_INDEX;
  END LOOP;

   INSERT INTO SSL_PACKAGE_LOG_TABLE(job_name,process_name, start_date, end_date)
   VALUES ('PKG_GRP_LOAD_RPT_DICS_CLAIMS_DETAIL_OAC_R_INC','END: REBUILD_UNUSABLE INDEX:',NULL,SYSDATE);
   COMMIT;

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
END PKG_GRP_LOAD_RPT_DICS_CLAIMS_DETAIL_OAC_R_INC;

