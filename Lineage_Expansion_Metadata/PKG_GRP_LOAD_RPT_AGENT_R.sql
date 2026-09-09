--------------------------------------------------------
--  DDL for Package Body PKG_GRP_LOAD_RPT_AGENT_R
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ATOMIC"."PKG_GRP_LOAD_RPT_AGENT_R" 
IS
  /***********************************************************************
  Purpose:  This package body contains procedures which loads data into RPT_AGENT_R
  Dependent SSL tables : RPT_AGENT_R
  Used DB Objects:DIM_GRP_AGENT_DIRECTORY_R
                  DIM_GRP_AGENT_R
                  FCT_GRP_PARTY_ADDRESS_R
                  stg_premier_producer_r
  Author     Date     Description
  ---------- -------- -------------------------------------------------
  VGireesh 28/02/24 Initial Creation
  VGireesh 03/04/24 Added Parallel to rebuild index fast
  Chandra  21/06/24 Added v_agent_msa_code_r,v_agent_msa_name_r
  VGireesh 24/07/24 Added procedure to insert dummy record
  Chandra  05/08/24 Logic change for DIM_GRP_AGENT_R Join
  Vgireesh 06/08/24 Logic changed for FCT_GRP_PARTY_ADDRESS_R .. used rnk function as temporary fix till the issue resolved in FCT_GRP_PARTY_ADDRESS_R
                      Post fix RNK function need to be removed
  Samba	18/02/26  Capturing the Target count for Audit COntrols when data is inserting into RPT table using Bulkload limit.
  Rose	10/03/26  Commenting prc_upd_del_data and adding PKG_GRP_COMMON_UTIL.
  Samba	12/05/26  Kill/Fill Changes: User Story - 514606
					 	- All code changes are marked with Kill/Fill start and end comment blocks.
					 	- Code changes ensure continuous data availability in reports, replacing the current truncate-and-load approach, which is not partition-exchange based.	
					 	- Retaining old code base of bulk collect load; which can be used when this Package to be converted to incremental processing
  ***********************************************************************/
--Global Constants
gc_rpt_table_name      	VARCHAR2(50)      	:='RPT_AGENT_R';
gd_fic_mis_date         DATE;
gc_rebuild_idx_degree	PLS_INTEGER      	:=8;

--Start: kill/fill additions
gv_rpt_table_name        CONSTANT PRCS_JOB_LOG_R.V_JOB_NAME_R%TYPE	 := 'RPT_AGENT_R';	
gv_exg_table_name        CONSTANT PRCS_JOB_LOG_R.V_JOB_NAME_R%TYPE	 := gv_rpt_table_name||'_EXG';	
gv_schema_owner        	 CONSTANT PRCS_JOB_LOG_R.V_JOB_NAME_R%TYPE	 := 'ATOMIC';
gt_start_time			 TIMESTAMP;
gt_end_time			 	 TIMESTAMP;
gn_run_cnt				 NUMBER;
--End: kill/fill additions


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
    UPDATE RPT_AGENT_R
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
  LC_TBL           VARCHAR2(30):='RPT_AGENT_R';
  LC_REBUILD_INDEX VARCHAR2(300);
BEGIN
  GC_TRCMSG:=GC_TRCMSG||'3.7.1 Entered into prc_trunc_partition :->'||'ALTER TABLE '||LC_TBL||' TRUNCATE PARTITION '||'PART_'||LC_TBL||'_'||GN_CURRENT_MONTH||CHR(13);
  EXECUTE immediate 'ALTER TABLE '||lc_tbl||' TRUNCATE PARTITION '||'PART_'||lc_tbl||'_'||gn_current_month;
  gc_trcmsg:=gc_trcmsg||'3.7.2 Exit from prc_trunc_partition'||CHR(13);
  gc_trcmsg:=gc_trcmsg||'3.7.3 Rebuild Unusable PK Index starts'||chr(13);
  FOR I IN
  (SELECT 'ALTER INDEX '
    ||INDEX_NAME
    ||' REBUILD parallel 16 nologging' REBUILD_INDEX
  FROM ALL_INDEXES
  WHERE TABLE_NAME ='RPT_AGENT_R'
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
 --Start: Commenting for kill/fill 
  /* VAR_REF_CUR SYS_REFCURSOR;
	TYPE var_tbl_type
	IS
  TABLE OF RPT_AGENT_R%ROWTYPE INDEX BY BINARY_INTEGER;
  lt_var_tbl_typ var_tbl_type;*/
  --End: Commenting for kill/fill 

  ln_rec_cnt    NUMBER:=0;
  ln_start_time NUMBER;
  lc_trcmsg  varchar(150);
  ld_fic_mis_date_2 DATE;
  ln_fisc_current_month NUMBER;
BEGIN
  --Call Log Util pkg to Insert entry in PRCS_JOB_LOG_R
  pkg_grp_log_util.prc_insert_log ( 
						 p_source 				=> gc_source 
						,p_job_nm 				=> gc_job_name 
						,p_job_status 			=> gc_running_status 
						,p_err_msg 				=> NULL 
						,p_trc_msg 				=> NULL 
						,p_n_batch_id 			=> gn_sysdt_batchid 
						,p_log_util_called_by_r	=> gc_main_loadedby 
						,out_job_id 			=> gn_out_job_id 
					);
  gc_trcmsg:=gc_trcmsg||'1. Entered into main'||chr(13);
  gc_trcmsg:=gc_trcmsg||'gn_current_month     :->'||gn_current_month||chr(13);
  gc_trcmsg:=gc_trcmsg||'gn_prior_month       :->'||gn_prior_month||chr(13);
  --gc_trcmsg:=gc_trcmsg||'1.c gn_prior2prior_month :->'||gn_prior2prior_month||chr(13);
  /*gc_trcmsg:=gc_trcmsg||'3. Call procedure prc_upd_del_data from main'||chr(13);
  PKG_GRP_LOAD_RPT_AGENT_R.prc_upd_del_data;
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

	-- Start : Kill/Fill Changes 12th May 2026 	: Added New 
	PKG_GRP_COMMON_UTIL.PRC_CREATE_EXCHANGE_TABLE_DDL
		(
			p_job_id            	=> gn_out_job_id, 
			p_log_seq_num           => 4, 
			p_main_table_name       => gv_rpt_table_name,
			p_exg_table_name        => gv_exg_table_name,
			p_schema_name           => gv_schema_owner
		);

	PKG_GRP_LOAD_RPT_AGENT_R.prc_get_cur_data;

	-- End : Kill/Fill Changes 12th May 2026 	: Added New 


	/*	PKG_GRP_COMMON_UTIL.prc_trunc_partition 
		(
			p_out_job_id    	=>	gn_out_job_id,
			p_Log_seq_num   	=>	4,
			p_rpt_table     	=>	gc_rpt_table_name,  
			p_idx_num       	=>	gc_rebuild_idx_degree,
			p_current_month     =>	gn_current_month
		); 

  gc_trcmsg:=gc_trcmsg||'4. Call prc_get_cur_data to get ref_cursor '||chr(13);
  PKG_GRP_LOAD_RPT_AGENT_R.prc_get_cur_data (var_ref_cur);
  gc_trcmsg    :=gc_trcmsg||'4.z Completed Call Procedure prc_get_cur_data to get ref_cursor'||chr(13);
  ln_start_time:=dbms_utility.get_time;
  gc_trcmsg    :=gc_trcmsg||'5 data load starts '||ln_start_time||chr(13);
  ln_rec_cnt   :=0;
  LOOP
    lt_var_tbl_typ.DELETE;
    FETCH var_ref_cur BULK COLLECT INTO lt_var_tbl_typ LIMIT gn_bulk_coll_cnt;
    FORALL X IN LT_VAR_TBL_TYP.first..LT_VAR_TBL_TYP.last
    INSERT /*+APPEND_VALUES*/
    /*INTO RPT_AGENT_R VALUES lt_var_tbl_typ
      (x
      ) ;
    LN_REC_CNT:=LN_REC_CNT+LT_VAR_TBL_TYP.COUNT;
    COMMIT;
    EXIT
  WHEN var_ref_cur%NOTFOUND;
  END LOOP;
  gc_trcmsg:=gc_trcmsg||'5.z Data Loaded '||ln_rec_cnt||' records '||((dbms_utility.get_time - ln_start_time)/100)||chr(13);


	lc_trcmsg:='1. Target count for Audit control Process';


			 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
			 (
				p_job_id_r                    => gn_out_job_id,
				p_batch_id_r                  => gn_sysdt_batchid,
				p_message_type_r              => gc_message_type_r,
				p_code_location_r             => gc_main_loadedby,
				p_message_r                   => lc_trcmsg,
				p_count_type_r                => 'Control Procedure',
				p_count_r                     => ln_rec_cnt,
				p_duration_r                  => NULL,
				p_created_by_r                => GC_JOB_NAME,
				out_prcs_job_log_message_id_r => gn_job_log_message_id_r
			);	

	ln_start_time:=dbms_utility.get_time;*/

	-- Start : Kill/Fill Changes 12th May 2026 	: Added New 
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
	-- End : Kill/Fill Changes 12th May 2026 	: Added New 


  PKG_GRP_LOAD_RPT_AGENT_R.prc_rebuild_indexes;

  gc_trcmsg:=gc_trcmsg||'7.z Completed Procedure unusable prc_rebuild_indexes call from main '||((dbms_utility.get_time - ln_start_time)/100)||chr(13);
  ln_start_time:=dbms_utility.get_time;
  gc_trcmsg    :=gc_trcmsg||'8. Gather RPT_AGENT_R table stats from main '||ln_start_time||chr(13);

  DBMS_STATS.GATHER_TABLE_STATS('ATOMIC','RPT_AGENT_R');

  gc_trcmsg:=gc_trcmsg||'8.z Completed Gather RPT_AGENT_R table stats from main '||((dbms_utility.get_time - ln_start_time)/100)||chr(13);
  --24-Jul-2024 changes starts
  /*gc_trcmsg:=gc_trcmsg||'9. Call procedure prc_insert_dummy_rec from main'||chr(13);
  PKG_GRP_LOAD_RPT_AGENT_R.prc_insert_dummy_rec;
  gc_trcmsg:=gc_trcmsg||'9.z Completed Procedure prc_insert_dummy_rec call from main'||chr(13);
  --24-Jul-2024 changes ends*/

  lc_trcmsg:='8. Calling Audit Control Procedure';

		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
		 (
			p_job_id_r                    => gn_out_job_id,
			p_batch_id_r                  => gn_sysdt_batchid,
			p_message_type_r              => gc_message_type_r,
			p_code_location_r             => gc_main_loadedby,
			p_message_r                   => lc_trcmsg,
			p_count_type_r                => 'Control Procedure',
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
	--(p_out_cursor OUT SYS_REFCURSOR)--- Commented as part of Kill Fill Process
AS
BEGIN
  gc_trcmsg := '5.1 - Entered into prc_get_cur_data ';
	gt_start_time := SYSTIMESTAMP;

	/*NEW LOGGING MECHANISM CHANGES*/	
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
				( p_job_id_r                    => gn_out_job_id				
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


	-- Start : Kill/Fill Changes 12th May 2026
		EXECUTE IMMEDIATE 'ALTER SESSION ENABLE PARALLEL DML'; 
	-- End : Kill/Fill Changes 5th May 2026

	gc_trcmsg := '5.2 - Data load starts for _EXG table for Partition Exchange';
  		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
				( p_job_id_r                    => gn_out_job_id				
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


  -- Kill/Fill Changes 12th May 2026: Commented following 
    --Open/Assign SELECT stmnt
  --OPEN p_out_cursor FOR
    -- SQL for RPT_AGENT_R

  -- Start : Kill/Fill Changes 12th May 2026: Added following 
  INSERT /*+ APPEND PARALLEL(stg, 8) */ INTO RPT_AGENT_R_EXG stg    
  SELECT /*+ PARALLEL(8) */ 
  SUBSTR(C.V_AGENT_NUMBER_R,1, 6) AS V_AGENCY_code_R,
    C.V_FULL_NAME_R               AS V_AGENCY_NAME_R,
    adr.V_ADDRESSLINE1_R          AS V_AGENT_ADDRESS_1_R,
    adr.V_ADDRESSLINE2_R          AS V_AGENT_ADDRESS_2_R,
    adr.V_ADDRESSLINE3_R          AS V_AGENT_ADDRESS_3_R,
    adr.V_CITY_R                  AS V_AGENT_CITY_R ,
    C.V_AGENT_NUMBER_R            AS V_AGENT_CODE_R,
    c.V_CORPORATION_TYPE_R        AS V_AGENT_CORPORATION_TYPE_R,
    c.V_DOB_R                     AS D_AGENT_DATE_OF_BIRTH_R,
    c.D_DATE_OF_DEATH_R           AS D_AGENT_DATE_OF_DEATH_R,
    c.V_FIRST_NAME_R              AS V_AGENT_FIRST_NAME_R,
    c.V_GENDER_TEXT_R             AS V_AGENT_GENDER_R,
    c.V_LAST_NAME_R               AS V_AGENT_LAST_NAME_R,
    c.V_MIDDLE_NAME_R             AS V_AGENT_MIDDLE_NAME_R,
    c.V_FULL_NAME_R               AS V_AGENT_NAME_R,
    c.V_NPN_R                     AS V_AGENT_NPN_R,
    c.V_FIELD_OFFICE_NAME_R       AS V_AGENT_RSO_NAME_R,
    adr.V_STATE_NAME_R            AS V_AGENT_STATE_R,
    c.V_STATUS_R                  AS V_AGENT_STATUS_R,
    c.V_REASON_R                  AS V_AGENT_STATUS_REASON_R,
    c.V_SSN_R                     AS V_AGENT_TIN_R,
    adr.V_POSTAL_ZIP_R            AS V_AGENT_ZIP_CODE_R,
    c.D_BUSINESS_FROM_R           AS D_AGENT_BUSINESS_FROM_R,
    c.F_BUSINESS_TYPE_R           AS V_BUSINESS_TYPE_R,
    c.N_IS_AGENCY_R               AS N_IS_AGENCY_R,
    B.N_PARTY_SK_R                AS N_AGENT_PARTY_SK_R ,
    B.N_AGENT_SK_R                AS N_AGENT_SK_R ,
    PD.V_BROKER_DESC_R            AS V_PRODUCER_NAME_R,
    gc_getcur_loadedby            AS V_LAST_MODIFIED_BY_R,                              
    gd_sysdate                    AS T_CREATION_DATE_R,                                 
    gc_getcur_loadedby            AS V_CREATED_BY_R,                                    
    gd_sysdate                    AS T_LAST_MODIFIED_DATE_R,                            
    'Y'                           AS V_RPT_ACTIVE_STATUS_R,                             
    gn_sysdt_batchid              AS N_BATCH_ID_R,                                      
    gn_current_month              AS N_REPORTMONTH_R  ,
    --21-06-24 Changes Start
    T1011891.V_MSA_R            as v_agent_msa_code_r,
    T1011891.V_MSA_NAME_R       as v_agent_msa_name_r
    --21-06-24 Changes Start    
  FROM 
  /* 18-11-2025 CHANGES START FOR BLANK ADDRESS ISSUE */
  (SELECT CASE WHEN DMGD1.N_PARTY_SK_R <> -1 THEN DMGD1.N_PARTY_SK_R
                     ELSE NVL((SELECT N_PARTY_SK_R FROM (SELECT N_PARTY_SK_r,ROW_NUMBER() OVER (PARTITION BY N_AGENT_SK_r ORDER BY T_EVENT_TIMESTAMP_R DESC ,N_BATCH_ID_R DESC) AS rn
                                                     FROM DIM_GRP_AGENT_DIRECTORY_R DMGD 
													 WHERE DMGD.V_AGENT_NUMBER_R = DMGD1.V_AGENT_NUMBER_R AND V_ACTIVE_STATUS_R='N' 
													 AND N_PARTY_SK_R<>-1) 
                           WHERE RN =1),-1) END N_PARTY_SK_r,
					  DMGD1.N_AGENT_SK_R,
					  DMGD1.V_ACTIVE_STATUS_R
              FROM DIM_GRP_AGENT_DIRECTORY_R DMGD1 
			  WHERE V_ACTIVE_STATUS_R = 'Y' AND N_PARTY_SK_R IS NOT NULL) B 
     /*(SELECT * FROM  --24-Jul-2024 changes
      DIM_GRP_AGENT_DIRECTORY_R 
	  WHERE V_ACTIVE_STATUS_R = 'Y') --24-Jul-2024 changes 
	  B	 */ 
	  /* 18-11-2025 CHANGES END BLANK ADDRESS ISSUE */
--05/08/24 Changes start      
  /* LEFT JOIN
    (SELECT *
    FROM DIM_GRP_AGENT_R d
    WHERE 
	d.V_ACTIVE_STATUS_R = 'Y' AND --24-Jul-2024 changes
	T_CREATION_DATE_R =
      (SELECT MAX(T_CREATION_DATE_R)
      FROM DIM_GRP_AGENT_R z
      WHERE z.n_agent_sk_r = d.n_agent_sk_r
      )
    ) C*/
     LEFT JOIN
    (SELECT *
    FROM DIM_GRP_AGENT_R d
    WHERE  	d.V_ACTIVE_STATUS_R = 'Y' AND --24-Jul-2024 changes
	trunc(T_EVENT_TIMESTAMP_R) =
      (SELECT MAX(trunc(T_EVENT_TIMESTAMP_R))
      FROM DIM_GRP_AGENT_R z
      WHERE z.n_agent_sk_r = d.n_agent_sk_r
      )
    ) C

  ON B.N_AGENT_SK_R       = C.N_AGENT_SK_R
  --05/08/24 Changes End      
  --AND C.V_ACTIVE_STATUS_R = 'Y'--24-Jul-2024 changes
  LEFT JOIN
    (
	--06/08/2024 changes starts
	/*SELECT DISTINCT V_ADDRESSLINE1_R,
      V_ADDRESSLINE2_R,
      V_ADDRESSLINE3_R,
      V_CITY_R ,
      V_STATE_NAME_R,
      V_POSTAL_ZIP_R,
      n_party_sk_r,
      N_PRIMARY_LOCATION_R
    FROM FCT_GRP_PARTY_ADDRESS_R
    WHERE V_SOURCE_SYSTEM_NAME_R = 'APS'
    AND N_PRIMARY_LOCATION_R     = '1'
    AND n_party_sk_r            <> -1
    AND D_DELETE_DATE_R         IS NULL
	*/
    SELECT * FROM 
    (SELECT DISTINCT V_ADDRESSLINE1_R,
          V_ADDRESSLINE2_R,
          V_ADDRESSLINE3_R,
          V_CITY_R ,
          V_STATE_NAME_R,
          V_POSTAL_ZIP_R,
          n_party_sk_r,
          N_PRIMARY_LOCATION_R
    	  ,       rank() over (partition by n_party_sk_r order by V_ADDRESSLINE1_R,
          V_ADDRESSLINE2_R,
          V_ADDRESSLINE3_R,
          V_CITY_R ,
          V_STATE_NAME_R,
          V_POSTAL_ZIP_R,
          N_PARTY_SK_R,
          N_PRIMARY_LOCATION_R desc) as rnk
        FROM FCT_GRP_PARTY_ADDRESS_R
        WHERE V_SOURCE_SYSTEM_NAME_R = 'APS'
        AND N_PRIMARY_LOCATION_R     = '1'
        AND n_party_sk_r            <> -1
        AND D_DELETE_DATE_R         IS NULL
    	  and T_EVENT_TIMESTAMP_R=
        (select max(T_EVENT_TIMESTAMP_R) from FCT_GRP_PARTY_ADDRESS_R fgpar2
        WHERE fgpar2.V_SOURCE_SYSTEM_NAME_R = 'APS'
        AND fgpar2.N_PRIMARY_LOCATION_R     = '1'
        AND fgpar2.n_party_sk_r            <> -1
        AND fgpar2.D_DELETE_DATE_R         IS NULL
        AND FGPAR2.N_PARTY_SK_R=     FCT_GRP_PARTY_ADDRESS_R.N_PARTY_SK_R
       )
       )where rnk=1
	   	--06/08/2024 changes ends
    )adr
  ON adr.n_party_sk_r = b.n_party_sk_r
  LEFT JOIN stg_premier_producer_r pp
  ON pp.V_AGENCY_CODE_R = SUBSTR(C.V_AGENT_NUMBER_R,1, 6)
  LEFT JOIN stg_premier_producer_desc_r pd
  ON PP.V_BROKER_NAME_R     = PD.V_BROKER_NAME_R
  left outer join STG_CMSA_R T1011891 /* D_CMSA_INSURED */  
  On T1011891.v_zip_code_r = substr(adr.V_POSTAL_ZIP_R , 1 , 5)
  --WHERE B.V_ACTIVE_STATUS_R = 'Y' ----24-Jul-2024 changes
  --fetch first 201 rows only
  ;

  gn_run_cnt      := SQL%ROWCOUNT;
 COMMIT;

 -- Start : Kill/Fill Changes 12th May 2026: Commented following 

	EXECUTE IMMEDIATE 'ALTER SESSION DISABLE PARALLEL DML';
	-- End : Kill/Fill Changes 12th May 2026 

	gt_end_time := SYSTIMESTAMP;
	gc_trcmsg:='5.3 Data Load Completed for _EXG Table';

		/*START: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
			 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
			 (
				p_job_id_r                    => gn_out_job_id,
				p_batch_id_r                  => gn_sysdt_batchid,
				p_message_type_r              => gc_message_type_r,
				p_code_location_r             => gc_main_loadedby,
				p_message_r                   => gc_trcmsg,
				p_count_type_r                => 'AUDIT_TARGET_COUNT',
				p_count_r                     => gn_run_cnt,
				p_duration_r                  => FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time),
				p_created_by_r                => GC_JOB_NAME,
				out_prcs_job_log_message_id_r => gn_job_log_message_id_r
			);	

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
--Procedure to rebuild indexes RPT_AGENT_R
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
    WHERE TABLE_NAME ='RPT_AGENT_R'
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
  gc_trcmsg :=gc_trcmsg||'7.z Error in prc_rebuild_indexes'||chr(13);
  pkg_grp_log_util.prc_update_log ( gn_out_job_id --p_job_id
  ,gc_error_status                                --p_job_status
  ,gc_errmsg                                      --p_err_msg
  ,gc_trcmsg||chr(13)||gc_errmsg                  --p_trc_msg
  ,gc_rebuildindexes                              --p_log_util_called_by_r
  );
  RAISE;
END prc_rebuild_indexes;
--24-Jul-2024 changes starts
--Procedure to insert dummy record in the table RPT_AGENT_R
PROCEDURE prc_insert_dummy_rec
IS
BEGIN
    gc_trcmsg:=gc_trcmsg||'6.1 Entered into from prc_insert_dummy_rec'||chr(13);
     INSERT /*+APPEND_VALUES*/ INTO  RPT_AGENT_R
		   ( 
		    v_last_modified_by_r  
           ,t_creation_date_r     
           ,v_created_by_r        
           ,t_last_modified_date_r
           ,N_REPORTMONTH_R
           ,v_rpt_active_status_r
           ,n_batch_id_r
		   ,N_AGENT_SK_R
		   ,N_AGENT_PARTY_SK_R
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
--24-Jul-2024 changes ends
END PKG_GRP_LOAD_RPT_AGENT_R;

/

  GRANT EXECUTE ON "ATOMIC"."PKG_GRP_LOAD_RPT_AGENT_R" TO "ATOMIC_ALL_RO";
  GRANT EXECUTE ON "ATOMIC"."PKG_GRP_LOAD_RPT_AGENT_R" TO "EXT_EIS_RO";
  GRANT DEBUG ON "ATOMIC"."PKG_GRP_LOAD_RPT_AGENT_R" TO "ATOMIC_DEBUG";
