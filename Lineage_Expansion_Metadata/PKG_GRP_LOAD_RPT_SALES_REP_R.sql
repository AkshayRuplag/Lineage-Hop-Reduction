--------------------------------------------------------
--  DDL for Package Body PKG_GRP_LOAD_RPT_SALES_REP_R
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ATOMIC"."PKG_GRP_LOAD_RPT_SALES_REP_R" 
IS
/***********************************************************************
  Purpose:  This package body contains procedures which loads data into RPT_SALES_REP_R
  Used tables:FCT_INSURANCE_QUOTES
			  DIM_GRP_QUOTE_DIR_R
  Author     Date     Description
  ---------- -------- -------------------------------------------------
  Satya 13/03/24 Initial Creation
   Joe  17/02/26 Audit Control Code as part of reconcilation between EDW and RPT.
   Rose	09/03/26 Commenting prc_upd_del_data and adding PKG_GRP_COMMON_UTIL.
  Samba	12/05/26 Kill/Fill Changes: User Story - 514607
					 - All code changes are marked with Kill/Fill start and end comment blocks.
					 - Code changes ensure continuous data availability in reports, replacing the current truncate-and-load approach, which is not partition-exchange based.	
					 - Retaining old code base of bulk collect load; which can be used when this Package to be converted to incremental processing
 **********************************************************************/

--Global Constants
gc_rpt_table_name      	VARCHAR2(50)      	:='RPT_SALES_REP_R';
gd_fic_mis_date          DATE;
gc_rebuild_idx_degree	PLS_INTEGER      	:=8;
--Start: kill/fill additions
gv_rpt_table_name        CONSTANT PRCS_JOB_LOG_R.V_JOB_NAME_R%TYPE	 := 'RPT_SALES_REP_R';	
gv_exg_table_name        CONSTANT PRCS_JOB_LOG_R.V_JOB_NAME_R%TYPE	 := gv_rpt_table_name||'_EXG';	
gv_schema_owner        	 CONSTANT PRCS_JOB_LOG_R.V_JOB_NAME_R%TYPE	 := 'ATOMIC';
gt_start_time			 TIMESTAMP;
gt_end_time			 	 TIMESTAMP;
gn_run_cnt				 NUMBER;
--End: kill/fill additions

--Procedure to update prior month active flag and current month partition
PROCEDURE prc_upd_del_data
IS
ln_sqlrowcnt      NUMBER;
ln_cnt            NUMBER;
ld_first_day_date DATE;
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
  FROM atomic.DIM_TIME_R D
  WHERE V_END_OF_FISCAL_MONTH_IND_R      = 'Y'
  AND TO_CHAR(D_CALENDAR_DATE_R,'YYYYMM')=TO_CHAR(sysdate,'YYYYMM');
  gc_trcmsg                             :=gc_trcmsg||'3.2 Fisc Month End +2 Day Date of the current month is:->'||ld_fic_mis_date_2||chr(13);
  gc_trcmsg                             :=gc_trcmsg||'3.3 Fisc Current Month of the current month is:->'||ln_fisc_current_month||chr(13);
  IF TRUNC(ld_fic_mis_date_2)            =TRUNC(sysdate) THEN
    ln_fisc_prior_month                 :=to_number(TO_CHAR(ld_fic_mis_date_2,'YYYYMM'));
    gc_trcmsg                           :=gc_trcmsg||'3.3.1 Fisc Prior Month of the current month is:->'||ln_fisc_prior_month||chr(13);
    gc_trcmsg                           :=gc_trcmsg||'3.4 Today Fisc Month End +2 '||ld_fic_mis_date_2||' hence Updating v_rpt_active_status_r=N against the records loaded in prior fisc month which is :->'||ln_fisc_prior_month||CHR(13);
    UPDATE RPT_SALES_REP_R
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
lc_tbl VARCHAR2(30):='RPT_SALES_REP_R';
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
--Main procedures calls other procedure to load data in RPT_SALES_REP_R
PROCEDURE main
IS
 --Start: Commenting for kill/fill 
 /*VAR_REF_CUR SYS_REFCURSOR;
TYPE var_tbl_type IS TABLE OF RPT_SALES_REP_R%ROWTYPE INDEX BY BINARY_INTEGER;
lt_var_tbl_typ var_tbl_type;*/
--End: Commenting for kill/fill

ln_rec_cnt NUMBER:=0;
ln_start_time NUMBER;
lc_main_entity varchar(30):='SALES_REPRESENTATIVE';
ld_fic_mis_date_2 DATE;
ln_fisc_current_month NUMBER;
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
    PKG_GRP_LOAD_RPT_SALES_REP_R.prc_upd_del_data;
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

	PKG_GRP_LOAD_RPT_SALES_REP_R.prc_get_cur_data;
	-- End : Kill/Fill Changes 12th May 2026 	: Added New 

	/*PKG_GRP_COMMON_UTIL.prc_trunc_partition 
		(
			p_out_job_id    	=>	gn_out_job_id,
			p_Log_seq_num   	=>	4,
			p_rpt_table     	=>	gc_rpt_table_name,  
			p_idx_num       	=>	gc_rebuild_idx_degree,
			p_current_month     =>	gn_current_month
		);

    gc_trcmsg:=gc_trcmsg||'4. Call prc_get_cur_data to get ref_cursor '||chr(13);
    PKG_GRP_LOAD_RPT_SALES_REP_R.prc_get_cur_data (var_ref_cur);
    gc_trcmsg:=gc_trcmsg||'4.z Completed Call Procedure prc_get_cur_data to get ref_cursor'||chr(13);
    gc_trcmsg:=gc_trcmsg||'5 data load starts '||chr(13);
	ln_rec_cnt:=0;
	ln_start_time:=dbms_utility.get_time;

    LOOP
	lt_var_tbl_typ.DELETE;
    FETCH var_ref_cur BULK COLLECT INTO  lt_var_tbl_typ LIMIT gn_bulk_coll_cnt;
     FORALL x in lt_var_tbl_typ.First..lt_var_tbl_typ.Last
     INSERT /*+APPEND_VALUES*/ /*INTO RPT_SALES_REP_R VALUES lt_var_tbl_typ(x) ;
	 ln_rec_cnt:=ln_rec_cnt+lt_var_tbl_typ.COUNT;
	 COMMIT;
     EXIT WHEN var_ref_cur%NOTFOUND;
    END LOOP;
	CLOSE var_ref_cur;

 /*Audit Control Code*/  
  --gn_target_count :=ln_rec_cnt;
   /*Audit Control Code*/

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

   /* gc_trcmsg:=gc_trcmsg||'5.z Data Loaded '||ln_rec_cnt||' records in '||((dbms_utility.get_time - ln_start_time)/100)|| ' seconds'||chr(13);
 	gc_trcmsg:=gc_trcmsg||'6. Call procedure prc_insert_dummy_rec from main'||chr(13);
    PKG_GRP_LOAD_RPT_SALES_REP_R.prc_insert_dummy_rec;
    gc_trcmsg:=gc_trcmsg||'6.z Completed Procedure prc_insert_dummy_rec call from main'||chr(13);
 	gc_trcmsg:=gc_trcmsg||'8. Call procedure unusable prc_rebuild_indexes from main'||chr(13);
	ln_start_time:=dbms_utility.get_time;*/

    PKG_GRP_LOAD_RPT_SALES_REP_R.prc_rebuild_indexes;

    gc_trcmsg:=gc_trcmsg||'8.z Completed Procedure unusable prc_rebuild_indexes call from main'||((dbms_utility.get_time - ln_start_time)/100)||chr(13);

	--gc_trcmsg:=gc_trcmsg||'9. Gather RPT_SALES_REP_R table stats from main'||chr(13);
	--ln_start_time:=dbms_utility.get_time;
    --DBMS_STATS.GATHER_TABLE_STATS('ATOMIC','RPT_SALES_REP_R');
    --gc_trcmsg:=gc_trcmsg||'9.z Completed Gather RPT_SALES_REP_R table stats from main'||((dbms_utility.get_time - ln_start_time)/100)||chr(13);
		/*Audit Control Code*/   

	gv_trcmsg :='7: Audit Control Code as Part of reconcilation between EDW and RPT';
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
	--(p_out_cursor OUT SYS_REFCURSOR) -- commented as part of Kill Fill process
AS
BEGIN
       gv_trcmsg := '5.1 - Entered into prc_get_cur_data ';
		gt_start_time := SYSTIMESTAMP;

	/*NEW LOGGING MECHANISM CHANGES*/	
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


	-- Start : Kill/Fill Changes 12th May 2026
		EXECUTE IMMEDIATE 'ALTER SESSION ENABLE PARALLEL DML'; 
	-- End : Kill/Fill Changes 12th May 2026

	gc_trcmsg := '5.2 - Data load starts for _EXG table for Partition Exchange';
	/*NEW LOGGING MECHANISM CHANGES*/	
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
				( p_job_id_r                    => gn_out_job_id				
				 ,p_batch_id_r                  => gn_sysdt_batchid				
				 ,p_message_type_r              => gv_message_type				
				 ,p_code_location_r             => gc_main_loadedby			
				 ,p_message_r                   => gc_trcmsg					
				 ,p_count_type_r                => NULL							
				 ,p_count_r                     => NULL							
				 ,p_duration_r                  => NULL							
				 ,p_created_by_r                => gc_job_name					
				 ,out_prcs_job_log_message_id_r => gn_job_log_message_id		
				);	
		-- Start : Kill/Fill Changes 12th May 2026: Commented following 
	   --Open/Assign SELECT stmnt
       -- OPEN p_out_cursor FOR
	   -- End : Kill/Fill Changes 12th May 2026 : Commented following 

	   INSERT /*+ APPEND PARALLEL(stg, 8) */ INTO RPT_SALES_REP_R_EXG stg  
       SELECT /*+ PARALLEL(8) */ 
			(CASE  WHEN FCT_SALES_REP_SHARE.v_sales_rep_sequence_r = 'P' THEN DIM_GRP_SALES_REPRESENTATIVE_R.N_EMPLOYEE_ID_R END) AS V_PRIMARY_SALES_REP_EMPLOYEE_ID_R
			,(CASE  WHEN FCT_SALES_REP_SHARE.V_SALES_REP_SEQUENCE_R = 'P' THEN DIM_GRP_SALES_REPRESENTATIVE_R.V_FIRST_NAME_R || ' ' ||DIM_GRP_SALES_REPRESENTATIVE_R.V_MIDDLE_NAME_R || ' ' || DIM_GRP_SALES_REPRESENTATIVE_R.V_LAST_NAME_R END) AS V_PRIMARY_SALES_REP_NAME_R
			,(CASE  WHEN FCT_SALES_REP_SHARE.v_sales_rep_sequence_r = 'P' THEN DIM_GRP_SALES_REPRESENTATIVE_R.V_REGIONAL_OFFICE_NAME_R END) AS V_PRIMARY_SALES_REP_rso_R
			,DIM_GRP_SALES_REPRESENTATIVE_R.D_RECORD_START_DATE_R AS D_SALES_REP_EFF_DATE_R
			,FCT_SALES_REP_SHARE.N_SALES_REP_SHARE_R AS N_SALES_REP_SHARE_PCT_R
			,(CASE  WHEN FCT_SALES_REP_SHARE.v_sales_rep_sequence_r = 'S' THEN DIM_GRP_SALES_REPRESENTATIVE_R.N_EMPLOYEE_ID_R END ) AS V_SECONDARY_SALES_REP_EMPLOYEE_ID_R
			,(CASE  WHEN FCT_SALES_REP_SHARE.V_SALES_REP_SEQUENCE_R = 'S' THEN DIM_GRP_SALES_REPRESENTATIVE_R.V_FIRST_NAME_R || ' ' ||DIM_GRP_SALES_REPRESENTATIVE_R.V_MIDDLE_NAME_R || ' ' || DIM_GRP_SALES_REPRESENTATIVE_R.V_LAST_NAME_R END) AS V_SECONDARY_SALES_REP_NAME_R
			,(CASE  WHEN FCT_SALES_REP_SHARE.v_sales_rep_sequence_r = 'S' THEN DIM_GRP_SALES_REPRESENTATIVE_R.V_REGIONAL_OFFICE_NAME_R END) AS V_secondary_SALES_REP_rso_R
			,(CASE  WHEN FCT_SALES_REP_SHARE.v_sales_rep_sequence_r = 'S' THEN FCT_SALES_REP_SHARE.N_SALES_REP_SHARE_R END) AS n_secondary_sales_rep_share_pct_r
			,(CASE  WHEN FCT_SALES_REP_SHARE.v_sales_rep_sequence_r = 'T' THEN DIM_GRP_SALES_REPRESENTATIVE_R.N_EMPLOYEE_ID_R END) AS V_tertiary_SALES_REP_EMPLOYEE_ID_R
			,(CASE  WHEN FCT_SALES_REP_SHARE.V_SALES_REP_SEQUENCE_R = 'T' THEN DIM_GRP_SALES_REPRESENTATIVE_R.V_FIRST_NAME_R || ' ' ||DIM_GRP_SALES_REPRESENTATIVE_R.V_MIDDLE_NAME_R || ' ' || DIM_GRP_SALES_REPRESENTATIVE_R.V_LAST_NAME_R END) AS V_tertiary_SALES_REP_NAME_R
			,(CASE  WHEN FCT_SALES_REP_SHARE.v_sales_rep_sequence_r = 'T' THEN DIM_GRP_SALES_REPRESENTATIVE_R.V_REGIONAL_OFFICE_NAME_R END) AS V_tertiary_SALES_REP_rso_R
			,(CASE  WHEN FCT_SALES_REP_SHARE.v_sales_rep_sequence_r = 'T' THEN FCT_SALES_REP_SHARE.N_SALES_REP_SHARE_R END) AS n_tertiary_sales_rep_share_pct_r
			,FCT_SALES_REP_SHARE.N_SALES_REPRESENTATIVE_SK_R AS N_SALES_REPRESENTATIVE_SK_R
			,dim_grp_policy_dir_r.n_policy_sk_r AS n_policy_sk_r
			,gc_main_loadedby                                              v_last_modified_by_r
			,gd_sysdate                                                    t_creation_date_r
			,gc_main_loadedby                                              v_created_by_r
			,gd_sysdate                                                    t_last_modified_date_r
			,GN_CURRENT_MONTH                                              N_YEARMONTH_R
			,'Y'                        								   v_rpt_active_status_r
			,gn_sysdt_batchid                                              n_batch_id_r
			,V_SALES_REP_NUMBER_R                                          --14/10/24 REQUESTED BY MAGESH FOR GMS EXTRACT
			from  atomic.FCT_SALES_REP_SHARE
			left outer join atomic.DIM_GRP_SALES_REPRESENTATIVE_R
			On FCT_SALES_REP_SHARE.N_SALES_REPRESENTATIVE_SK_R = DIM_GRP_SALES_REPRESENTATIVE_R.N_SALES_REPRESENTATIVE_SK_R
			and DIM_GRP_SALES_REPRESENTATIVE_R.v_active_status_r = 'Y'
			---policy prefix changes starts
			/*left outer join  VW_DIM_GRP_POLICY_DIR_R_POLICY_PREFIX_BRIDGE_MV BRIDGE
			on FCT_SALES_REP_SHARE.V_POLICY_NUMBER_R = BRIDGE.OLD_V_POLICY_NUMBER_R*/ --requested by gisha to comment
			and FCT_SALES_REP_SHARE.D_SALES_REP_END_DATE_R is null
			LEFT OUTER JOIN atomic.dim_grp_policy_dir_r
			on dim_grp_policy_dir_r.V_ACTIVE_STATUS_R = 'Y'
			--AND BRIDGE.V_POLICY_NUMBER_R = dim_grp_policy_dir_r.V_POLICY_NUMBER_R	--requested by gisha to comment
            AND FCT_SALES_REP_SHARE.V_POLICY_NUMBER_R = dim_grp_policy_dir_r.V_POLICY_NUMBER_R
			/*left outer join dim_grp_policy_dir_r
			on FCT_SALES_REP_SHARE.v_policy_number_r = dim_grp_policy_dir_r.v_policy_number_r
			and dim_grp_policy_dir_r.v_active_status_r = 'Y'*/---policy prefix changes ends
			and FCT_SALES_REP_SHARE.D_SALES_REP_END_DATE_R IS NULL
			where FCT_SALES_REP_SHARE.V_SALES_REP_SEQUENCE_R<>'Z' 
			--fetch first 130 rows ONLY
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
				p_message_type_r              => gv_message_type,
				p_code_location_r             => gc_main_loadedby,
				p_message_r                   => gc_trcmsg,
				p_count_type_r                => 'AUDIT_TARGET_COUNT',
				p_count_r                     => gn_run_cnt,
				p_duration_r                  => FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time),
				p_created_by_r                => GC_JOB_NAME,
				out_prcs_job_log_message_id_r => gn_job_log_message_id
			);	
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

--Procedure to insert dummy record in the table RPT_SALES_REP_R
PROCEDURE prc_insert_dummy_rec
IS
BEGIN
    gc_trcmsg:=gc_trcmsg||'6.1 Entered into from prc_insert_dummy_rec'||chr(13);
     INSERT /*+APPEND_VALUES*/ INTO  RPT_SALES_REP_R
		   (
		    v_last_modified_by_r
           ,t_creation_date_r
           ,v_created_by_r
           ,t_last_modified_date_r
           ,n_yearmonth_r
           ,v_rpt_active_status_r
           ,n_batch_id_r
           ,N_SALES_REPRESENTATIVE_SK_R
		   ,n_policy_sk_r
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
--Procedure to rebuild indexes RPT_SALES_REP_R
PROCEDURE prc_rebuild_indexes
IS
LC_REBUILD_INDEX  VARCHAR2(300);
BEGIN
   gc_trcmsg:=gc_trcmsg||'7.a Entered into prc_rebuild_indexes'||chr(13);
  FOR I IN ( select
    'ALTER INDEX '||INDEX_NAME||' REBUILD  parallel 16 nologging' REBUILD_INDEX
    from ALL_INDEXES  where TABLE_NAME ='RPT_SALES_REP_R'
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

end PKG_GRP_LOAD_RPT_SALES_REP_R;

/

  GRANT EXECUTE ON "ATOMIC"."PKG_GRP_LOAD_RPT_SALES_REP_R" TO "ATOMIC_ALL_RO";
  GRANT EXECUTE ON "ATOMIC"."PKG_GRP_LOAD_RPT_SALES_REP_R" TO "EXT_EIS_RO";
  GRANT DEBUG ON "ATOMIC"."PKG_GRP_LOAD_RPT_SALES_REP_R" TO "ATOMIC_DEBUG";
