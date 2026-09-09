--------------------------------------------------------
--  DDL for Package Body PKG_GRP_LOAD_RPT_COMMISSIONS_R
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ATOMIC"."PKG_GRP_LOAD_RPT_COMMISSIONS_R" 
IS
/**************************************************************************************************************
  Purpose:  This package body contains procedures which loads data into RPT_COMMISSIONS_R
  Used DB tables :DIM_GRP_ADDRESS_DIR_R,DIM_GRP_PARTY_R,ref_state
  Author     Date     Description
  ---------- -------- -------------------------------------------------
  Chandra   22/08/24 Initial Creation
  Suresh    28/01/25 Add Column V_SALES_PLAN_DESC_R
  Suresh    29/01/2025 AND COMM_SUMM.N_POLICY_SK_R = PLCY_LKP.N_POLICY_SK_R  --29-01-2025 ADDED and comment template_name_r condition
  Suresh    06/02/2025 Condition added if V_SALES_PLAN_DESC_R is null .
  Suresh    12/02/2025 Condition added for V_SALES_PLAN_DESC_R .
  Suresh    18/02/2025 Condition added for V_SALES_PLAN_DESC_R .
  Beneshya  27/10/2025 Added logic change to V_SALES_PLAN_DESC_R as part of group producer compesation summary report
  Rose		12/03/26   Commenting prc_upd_del_data and adding PKG_GRP_COMMON_UTIL.	
  Samba		12/05/26   Kill/Fill Changes: User Story - 514610
					 	- All code changes are marked with Kill/Fill start and end comment blocks.
					 	- Code changes ensure continuous data availability in reports, replacing the current truncate-and-load approach, which is not partition-exchange based.	
					 	- Retaining old code base of bulk collect load; which can be used when this Package to be converted to incremental processing
  Madhurima 05/06/26   Adding V_DATA_SOURCE_NAME_R field to capture the data ingestion source name. User Story - 522358
  **************************************************************************************************************/
		--Global Constants
		gv_main_loadedby         CONSTANT PRCS_JOB_LOG_MESSAGE_R.V_CODE_LOCATION_R%TYPE				 := 'PKG_GRP_LOAD_RPT_COMMISSIONS_R.MAIN';
		gv_updby                 CONSTANT PRCS_JOB_LOG_MESSAGE_R.V_CODE_LOCATION_R%TYPE				 := 'PKG_GRP_LOAD_RPT_COMMISSIONS_R.PRC_UPD_DEL_DATA';				    
		gv_getcur_loadedby       CONSTANT PRCS_JOB_LOG_MESSAGE_R.V_CODE_LOCATION_R%TYPE				 := 'PKG_GRP_LOAD_RPT_COMMISSIONS_R.PRC_GET_CUR_DATA';				    
		gv_truncpartby           CONSTANT PRCS_JOB_LOG_MESSAGE_R.V_CODE_LOCATION_R%TYPE				 := 'PKG_GRP_LOAD_RPT_COMMISSIONS_R.PRC_TRUNC_PARTITION';			        
		gv_rebuildindexes        CONSTANT PRCS_JOB_LOG_MESSAGE_R.V_CODE_LOCATION_R%TYPE				 := 'PKG_GRP_LOAD_RPT_COMMISSIONS_R.PRC_REBUILD_INDEXES';			        
        gv_upd_ind_cols_by       CONSTANT PRCS_JOB_LOG_MESSAGE_R.V_CODE_LOCATION_R%TYPE				 := 'PKG_GRP_LOAD_RPT_COMMISSIONS_R.PRC_UPD_COLS';                        
		gv_job_name              CONSTANT PRCS_JOB_LOG_R.V_JOB_NAME_R%TYPE							 := 'GRP_LOAD_RPT_COMMISSIONS_R';	
        gv_dummyrec_loadedby     CONSTANT PRCS_JOB_LOG_MESSAGE_R.V_CODE_LOCATION_R%TYPE				 := 'PKG_GRP_LOAD_RPT_COMMISSIONS_R.PRC_INSERT_DUMMY_REC';
		gv_running_status        CONSTANT PRCS_JOB_LOG_R.V_JOB_STATUS_R%TYPE  						 := 'Running';
		gv_error_status          CONSTANT PRCS_JOB_LOG_R.V_JOB_STATUS_R%TYPE    					 := 'Error';
		gv_success_status        CONSTANT PRCS_JOB_LOG_R.V_JOB_STATUS_R%TYPE  						 := 'Success';
		gv_source                CONSTANT PRCS_JOB_LOG_R.V_JOB_STATUS_R%TYPE 						 := 'EDW';		
		gv_yes_ind               CONSTANT DIM_GRP_POLICY_DIR_R.v_active_status_r%TYPE				 := 'Y';
		gv_source_syst			 CONSTANT DIM_GRP_BILLING_POL_BILLGRP_R.v_source_system_name_r%TYPE	 := 'VUE';
		gv_message_type 	     CONSTANT PRCS_JOB_LOG_MESSAGE_R.v_message_type_r%TYPE  			 := PKG_GRP_LOG_UTIL.gc_message_type_info;
		gv_count_type    	     CONSTANT PRCS_JOB_LOG_MESSAGE_R.v_count_type_r%TYPE    			 := PKG_GRP_LOG_UTIL.gc_count_type_insert;
        gv_count_type_upd	     CONSTANT PRCS_JOB_LOG_MESSAGE_R.v_count_type_r%TYPE    			 := PKG_GRP_LOG_UTIL.gc_count_type_update;
        gn_run_cnt               PRCS_JOB_LOG_MESSAGE_R.N_COUNT_R%TYPE 	 				             := 0;		
		gv_trcmsg                PRCS_JOB_LOG_MESSAGE_R.V_MESSAGE_R%TYPE;			
		gt_start_time   	     PRCS_JOB_LOG_MESSAGE_R.D_CREATION_DATE_R %TYPE;
        gt_start_time_inside_lp  PRCS_JOB_LOG_MESSAGE_R.D_CREATION_DATE_R %TYPE;
		gt_end_time 		     PRCS_JOB_LOG_MESSAGE_R.D_CREATION_DATE_R %TYPE;
		gn_job_log_message_id    PRCS_JOB_LOG_MESSAGE_R.N_COUNT_R%TYPE;	
		gn_error_line            PRCS_JOB_LOG_MESSAGE_R.v_message_type_r%TYPE;
		gv_errmsg                PRCS_JOB_LOG_MESSAGE_R.V_MESSAGE_R%TYPE;
		gc_rpt_table_name      	VARCHAR2(50)      	:='RPT_COMMISSIONS_R';
		gd_fic_mis_date          DATE;
		gc_rebuild_idx_degree	PLS_INTEGER      	:=8;
		--Start: kill/fill additions
		gv_rpt_table_name        CONSTANT PRCS_JOB_LOG_R.V_JOB_NAME_R%TYPE	 := 'RPT_COMMISSIONS_R';	
		gv_exg_table_name        CONSTANT PRCS_JOB_LOG_R.V_JOB_NAME_R%TYPE	 := gv_rpt_table_name||'_EXG';	
		gv_schema_owner        	 CONSTANT PRCS_JOB_LOG_R.V_JOB_NAME_R%TYPE	 := 'ATOMIC';
		--End: kill/fill additions

PROCEDURE prc_upd_del_data
IS
/**************************************************************************************************************
  Purpose:  Procedure to update prior month active flag and current month partition

	Author		Date     	Description
	---------	-------- 	-------------------------------------------------
	Chandra		22/08/24	Initial Creation
***************************************************************************************************************/   
ln_sqlrowcnt      NUMBER;
ln_cnt            NUMBER;
ld_first_day_date DATE;
ln_fisc_current_month NUMBER;
ln_fisc_prior_month   NUMBER;
ld_fic_mis_date_2     DATE;
BEGIN
    gv_trcmsg:='3.1 Entered into in prc_upd_del_data'||chr(13);
	gt_start_time:= SYSTIMESTAMP;

	/*START: NEW LOGGING MECHANISM CHANGES*/       
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
			(
			 p_job_id_r                    => gn_out_job_id				
			,p_batch_id_r                  => gn_sysdt_batchid			
			,p_message_type_r              => gv_message_type			
			,p_code_location_r             => gv_main_loadedby			
			,p_message_r                   => gv_trcmsg					
			,p_count_type_r                => NULL						
			,p_count_r                     => NULL						
			,p_duration_r                  => NULL						
			,p_created_by_r                => GV_JOB_NAME				
			,out_prcs_job_log_message_id_r => gn_job_log_message_id		
			);	
    /*END: NEW LOGGING MECHANISM CHANGES*/	

	--Fetch Fisc Month End +2 and Fisc Current Month
	SELECT 
	D_CALENDAR_DATE_R                  +2 ,
	to_number(TO_CHAR(last_day(sysdate)+1,'YYYYMM'))
	INTO ld_fic_mis_date_2 ,
	ln_fisc_current_month
	FROM DIM_TIME_R D
	WHERE V_END_OF_FISCAL_MONTH_IND_R      = 'Y'
	AND TO_CHAR(D_CALENDAR_DATE_R,'YYYYMM')=TO_CHAR(sysdate,'YYYYMM');

	gv_trcmsg:='3.2 Fisc Month End +2 Day Date of the current month is:->'||ld_fic_mis_date_2||chr(13);
	gt_start_time:= SYSTIMESTAMP;

	/*START: NEW LOGGING MECHANISM CHANGES*/       
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
			(
			p_job_id_r                    => gn_out_job_id                                           
			,p_batch_id_r                  => gn_sysdt_batchid                                    
			,p_message_type_r              => gv_message_type                                    
			,p_code_location_r             => gv_main_loadedby                                  
			,p_message_r                   => gv_trcmsg          
			,p_count_type_r                => NULL                             
			,p_count_r                     => NULL                                         
			,p_duration_r                  => NULL                                         
			,p_created_by_r                => GV_JOB_NAME        
			,out_prcs_job_log_message_id_r => gn_job_log_message_id                       
			);            
	/*END: NEW LOGGING MECHANISM CHANGES*/


	gv_trcmsg:='3.3 Fisc Current Month of the current month is:->'||ln_fisc_current_month||chr(13);
	gt_start_time:= SYSTIMESTAMP;

	/*START: NEW LOGGING MECHANISM CHANGES*/       
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
			(
			p_job_id_r                    => gn_out_job_id                                           
			,p_batch_id_r                  => gn_sysdt_batchid                                    
			,p_message_type_r              => gv_message_type                                    
			,p_code_location_r             => gv_main_loadedby                                  
			,p_message_r                   => gv_trcmsg                                                                 
			,p_count_type_r                => NULL                                                                           
			,p_count_r                     => NULL                                                                                      
			,p_duration_r                  => NULL                                                                                      
			,p_created_by_r                => GV_JOB_NAME                                                       
			,out_prcs_job_log_message_id_r => gn_job_log_message_id                       
			);  
	/*END: NEW LOGGING MECHANISM CHANGES*/			

	IF TRUNC(ld_fic_mis_date_2) = TRUNC(sysdate) THEN
		ln_fisc_prior_month:=to_number(TO_CHAR(ld_fic_mis_date_2,'YYYYMM'));
		gv_trcmsg:='3.3.1 Fisc Prior Month of the current month is:->'||ln_fisc_prior_month||chr(13);
		gt_start_time:= SYSTIMESTAMP;

		/*START: NEW LOGGING MECHANISM CHANGES*/       
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
				(
				p_job_id_r                    => gn_out_job_id                                           
				,p_batch_id_r                  => gn_sysdt_batchid                                    
				,p_message_type_r              => gv_message_type                                    
				,p_code_location_r             => gv_main_loadedby                                  
				,p_message_r                   => gv_trcmsg                                                                 
				,p_count_type_r                => NULL                                                                           
				,p_count_r                     => NULL                                                                                      
				,p_duration_r                  => NULL                                                                                      
				,p_created_by_r                => GV_JOB_NAME                                                       
				,out_prcs_job_log_message_id_r => gn_job_log_message_id                       
				); 
		/*END: NEW LOGGING MECHANISM CHANGES*/			
		gv_trcmsg:='3.4 Today Fisc Month End +2 '||ld_fic_mis_date_2||' hence Updating v_rpt_active_status_r=N against the records loaded in prior fisc month which is :->'||ln_fisc_prior_month||CHR(13);
		 gt_start_time:= SYSTIMESTAMP;

		/*START: NEW LOGGING MECHANISM CHANGES*/       
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
				(
				p_job_id_r                    => gn_out_job_id                                           
				,p_batch_id_r                  => gn_sysdt_batchid                                    
				,p_message_type_r              => gv_message_type                                    
				,p_code_location_r             => gv_main_loadedby                                  
				,p_message_r                   => gv_trcmsg                                                                 
				,p_count_type_r                => NULL                                                                           
				,p_count_r                     => NULL                                                                                      
				,p_duration_r                  => NULL                                                                                      
				,p_created_by_r                => GV_JOB_NAME                                                       
				,out_prcs_job_log_message_id_r => gn_job_log_message_id                       
				);  
		/*END: NEW LOGGING MECHANISM CHANGES*/

		UPDATE RPT_COMMISSIONS_R 
		   SET v_rpt_active_status_r='N'
			  ,v_last_modified_by_r=gc_updby
			  ,t_last_modified_date_r=gd_sysdate
		WHERE n_yearmonth_r = ln_fisc_prior_month;
		ln_sqlrowcnt:=SQL%ROWCOUNT;
		COMMIT;

		gv_trcmsg:='3.5  Updated v_rpt_active_status_r=N against the records loaded in Fisc prior month :->'||ln_fisc_prior_month||' records '||ln_sqlrowcnt||chr(13);
		gt_start_time:= SYSTIMESTAMP;

		/*START: NEW LOGGING MECHANISM CHANGES*/       
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
				(
				p_job_id_r                    => gn_out_job_id                                           
				,p_batch_id_r                  => gn_sysdt_batchid                                    
				,p_message_type_r              => gv_message_type                                    
				,p_code_location_r             => gv_main_loadedby                                  
				,p_message_r                   => gv_trcmsg                                                                 
				,p_count_type_r                => NULL                                                                           
				,p_count_r                     => NULL                                                                                      
				,p_duration_r                  => NULL                                                                                      
				,p_created_by_r                => GV_JOB_NAME                                                       
				,out_prcs_job_log_message_id_r => gn_job_log_message_id                       
				);            
		/*END: NEW LOGGING MECHANISM CHANGES*/
		gv_trcmsg       :='3.6 Set gn_current_month to  ln_fisc_current_month ';
		gn_current_month:=ln_fisc_current_month;
		gv_trcmsg       :='3.7 now current month is :->'|| gn_current_month ;
		 gt_start_time:= SYSTIMESTAMP;

		/*START: NEW LOGGING MECHANISM CHANGES*/       
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
				(
				p_job_id_r                    => gn_out_job_id                                           
				,p_batch_id_r                  => gn_sysdt_batchid                                    
				,p_message_type_r              => gv_message_type                                    
				,p_code_location_r             => gv_main_loadedby                                  
				,p_message_r                   => gv_trcmsg                                                                 
				,p_count_type_r                => NULL                                                                           
				,p_count_r                     => NULL                                                                                      
				,p_duration_r                  => NULL                                                                                      
				,p_created_by_r                => GV_JOB_NAME                                                       
				,out_prcs_job_log_message_id_r => gn_job_log_message_id                       
				);            
		/*END: NEW LOGGING MECHANISM CHANGES*/     
	ELSE
		--If Sysdate is greater than to Fisc Month End +2 and less than last day of the present month then Current Month is next fisc month 
		--Ex: if sysdate is  28-MAR-24 which is also Fisc Month end +2 and leass than current month end date 31-MAR-24 then current month 202403 becomes next fisc month which is 202404
		--partition 202404 should be truncated and reloaded
		IF TRUNC(sysdate)>trunc(ld_fic_mis_date_2) and  TRUNC(sysdate)<= trunc(last_day(sysdate)) THEN
			gv_trcmsg       :='3.8 Set gn_current_month to  ln_fisc_current_month ';
			gn_current_month:=ln_fisc_current_month;
			gt_start_time:= SYSTIMESTAMP;

			/*START: NEW LOGGING MECHANISM CHANGES*/       
			PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
					(
					p_job_id_r                    => gn_out_job_id                                           
					,p_batch_id_r                  => gn_sysdt_batchid                                    
					,p_message_type_r              => gv_message_type                                    
					,p_code_location_r             => gv_main_loadedby                                  
					,p_message_r                   => gv_trcmsg                                                                 
					,p_count_type_r                => NULL                                                                           
					,p_count_r                     => NULL                                                                                      
					,p_duration_r                  => NULL                                                                                      
					,p_created_by_r                => GV_JOB_NAME                                                       
					,out_prcs_job_log_message_id_r => gn_job_log_message_id                       
					);            
			/*END: NEW LOGGING MECHANISM CHANGES*/  

			gv_trcmsg:='3.9 now current month is :->'|| gn_current_month ;
			gt_start_time:= SYSTIMESTAMP;

			/*START: NEW LOGGING MECHANISM CHANGES*/       
			PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
					(
					p_job_id_r                    => gn_out_job_id                                           
					,p_batch_id_r                  => gn_sysdt_batchid                                    
					,p_message_type_r              => gv_message_type                                    
					,p_code_location_r             => gv_main_loadedby                                  
					,p_message_r                   => gv_trcmsg                                                                 
					,p_count_type_r                => NULL                                                                           
					,p_count_r                     => NULL                                                                                      
					,p_duration_r                  => NULL                                                                                      
					,p_created_by_r                => GV_JOB_NAME                                                       
					,out_prcs_job_log_message_id_r => gn_job_log_message_id                       
					);            
			/*END: NEW LOGGING MECHANISM CHANGES*/     

		ELSE
			gv_trcmsg:='3.9.1 now current month is :->'|| gn_current_month ;	
			gt_start_time:= SYSTIMESTAMP;

			/*START: NEW LOGGING MECHANISM CHANGES*/       
			PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
					(
					p_job_id_r                    => gn_out_job_id                                           
					,p_batch_id_r                  => gn_sysdt_batchid                                    
					,p_message_type_r              => gv_message_type                                    
					,p_code_location_r             => gv_main_loadedby                                  
					,p_message_r                   => gv_trcmsg                                                                 
					,p_count_type_r                => NULL                                                                           
					,p_count_r                     => NULL                                                                                      
					,p_duration_r                  => NULL                                                                                      
					,p_created_by_r                => GV_JOB_NAME                                                       
					,out_prcs_job_log_message_id_r => gn_job_log_message_id                       
					);            
			/*END: NEW LOGGING MECHANISM CHANGES*/     
		END IF;
		--Since sysdate is not fisc month end +2 hence data loaded in Current Month needs to be deleted but prior months data should not be touched
		gv_trcmsg:='3.10 Today is not fisc month end +2 of the current month hence Calling procedure prc_trunc_partition to truncate current month partition from main'||chr(13);
		gt_start_time:= SYSTIMESTAMP;

		/*START: NEW LOGGING MECHANISM CHANGES*/       
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
				(
				p_job_id_r                    => gn_out_job_id                                           
				,p_batch_id_r                  => gn_sysdt_batchid                                    
				,p_message_type_r              => gv_message_type                                    
				,p_code_location_r             => gv_main_loadedby                                  
				,p_message_r                   => gv_trcmsg                                                                 
				,p_count_type_r                => NULL                                                                           
				,p_count_r                     => NULL                                                                                      
				,p_duration_r                  => NULL                                                                                      
				,p_created_by_r                => GV_JOB_NAME                                                       
				,out_prcs_job_log_message_id_r => gn_job_log_message_id                       
				);            
		/*END: NEW LOGGING MECHANISM CHANGES*/         
		prc_trunc_partition;
		gv_trcmsg:='3.11 Completed procedure prc_trunc_partition call from main'||chr(13);
		gt_start_time:= SYSTIMESTAMP;

		/*START: NEW LOGGING MECHANISM CHANGES*/       
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
				(
				p_job_id_r                    => gn_out_job_id                                           
				,p_batch_id_r                  => gn_sysdt_batchid                                    
				,p_message_type_r              => gv_message_type                                    
				,p_code_location_r             => gv_main_loadedby                                  
				,p_message_r                   => gv_trcmsg                                                                 
				,p_count_type_r                => NULL                                                                           
				,p_count_r                     => NULL                                                                                      
				,p_duration_r                  => NULL                                                                                      
				,p_created_by_r                => GV_JOB_NAME                                                       
				,out_prcs_job_log_message_id_r => gn_job_log_message_id                       
				);            
		/*END: NEW LOGGING MECHANISM CHANGES*/
	END IF;

	gv_trcmsg:='3.12 Exit from in prc_upd_del_data'||chr(13); 
	gt_start_time:= SYSTIMESTAMP;

	/*START: NEW LOGGING MECHANISM CHANGES*/       
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
			(
			p_job_id_r                    => gn_out_job_id                                           
			,p_batch_id_r                  => gn_sysdt_batchid                                    
			,p_message_type_r              => gv_message_type                                    
			,p_code_location_r             => gv_main_loadedby                                  
			,p_message_r                   => gv_trcmsg                                                                 
			,p_count_type_r                => NULL                                                                           
			,p_count_r                     => NULL                                                                                      
			,p_duration_r                  => NULL                                                                                      
			,p_created_by_r                => GV_JOB_NAME                                                       
			,out_prcs_job_log_message_id_r => gn_job_log_message_id                       
			);            
	/*END: NEW LOGGING MECHANISM CHANGES*/     	
EXCEPTION
WHEN OTHERS THEN
    gc_errmsg:=SUBSTR(SQLERRM,1,4000);
	gv_trcmsg:='3.z Error in prc_upd_del_data'||chr(13)||gc_errmsg;
	 pkg_grp_log_util.prc_update_log_message_r
		( 
        n_prcs_job_log_message_id_r => GN_JOB_LOG_MESSAGE_ID,
        p_err_msg => gv_trcmsg 
		);
    /*END: NEW LOGGING MECHANISM CHANGES*/

    pkg_grp_log_util.prc_update_log
          (
			p_job_id => gn_out_job_id, 
			p_job_status => GV_ERROR_STATUS, 
			p_err_msg => GV_ERRMSG, 
			p_trc_msg => chr(13) || GV_ERRMSG, 
			p_log_util_called_by_r => GV_getcur_loadedby 
          );	

    RAISE;

END prc_upd_del_data;

PROCEDURE prc_trunc_partition
AS
/**************************************************************************************************************
  Purpose:  Procedure to truncate the YEARMONTH partition

	Author		Date     	Description
	---------	-------- 	-------------------------------------------------
	Chandra		22/08/24	Initial Creation
***************************************************************************************************************/   
lc_tbl VARCHAR2(30):='RPT_COMMISSIONS_R';
LC_REBUILD_INDEX  varchar2(300);
BEGIN
	gv_trcmsg:='3.7.1 Entered into prc_trunc_partition :->'||'ALTER TABLE '||lc_tbl||' TRUNCATE PARTITION '||'PART_'||lc_tbl||'_'||gn_current_month||CHR(13);
    gt_start_time:= SYSTIMESTAMP;

	/*START: NEW LOGGING MECHANISM CHANGES*/       
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
			(
			p_job_id_r                    => gn_out_job_id                                           
			,p_batch_id_r                  => gn_sysdt_batchid                                    
			,p_message_type_r              => gv_message_type                                    
			,p_code_location_r             => gv_main_loadedby                                  
			,p_message_r                   => gv_trcmsg                                                                 
			,p_count_type_r                => NULL                                                                           
			,p_count_r                     => NULL                                                                                      
			,p_duration_r                  => NULL                                                                                      
			,p_created_by_r                => GV_JOB_NAME                                                       
			,out_prcs_job_log_message_id_r => gn_job_log_message_id                       
			);            
	/*END: NEW LOGGING MECHANISM CHANGES*/
	--Truncating partition for the current month
	execute immediate 'ALTER TABLE '||lc_tbl||' TRUNCATE PARTITION '||'PART_'||lc_tbl||'_'||gn_current_month;
	gv_trcmsg:='3.7.2 Truncate Partition completed'||chr(13);
	gt_start_time:= SYSTIMESTAMP;

	/*START: NEW LOGGING MECHANISM CHANGES*/       
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
			(
			p_job_id_r                    => gn_out_job_id                                           
			,p_batch_id_r                  => gn_sysdt_batchid                                    
			,p_message_type_r              => gv_message_type                                    
			,p_code_location_r             => gv_main_loadedby                                  
			,p_message_r                   => gv_trcmsg                                                                 
			,p_count_type_r                => NULL                                                                           
			,p_count_r                     => NULL                                                                                      
			,p_duration_r                  => NULL                                                                                      
			,p_created_by_r                => GV_JOB_NAME                                                       
			,out_prcs_job_log_message_id_r => gn_job_log_message_id                       
			);            
	/*END: NEW LOGGING MECHANISM CHANGES*/                                   
	gv_trcmsg:='3.7.3 Rebuild Unusable PK Index starts'||chr(13);
	gt_start_time:= SYSTIMESTAMP;

	/*START: NEW LOGGING MECHANISM CHANGES*/       
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
			(
			p_job_id_r                    => gn_out_job_id                                           
			,p_batch_id_r                  => gn_sysdt_batchid                                    
			,p_message_type_r              => gv_message_type                                    
			,p_code_location_r             => gv_main_loadedby                                  
			,p_message_r                   => gv_trcmsg                                                                 
			,p_count_type_r                => NULL                                                                           
			,p_count_r                     => NULL                                                                                      
			,p_duration_r                  => NULL                                                                                      
			,p_created_by_r                => GV_JOB_NAME                                                       
			,out_prcs_job_log_message_id_r => gn_job_log_message_id                       
			);   
	/*END: NEW LOGGING MECHANISM CHANGES*/ 
	--Rebuilding Indexes 
	FOR I IN
		(SELECT 'ALTER INDEX '
		||INDEX_NAME
		||' REBUILD  parallel 16 nologging' REBUILD_INDEX
		FROM ALL_INDEXES
		WHERE TABLE_NAME ='RPT_COMMISSIONS_R'
		AND INDEX_NAME LIKE 'PK_%'
		AND STATUS='UNUSABLE'
		)
	LOOP
		LC_REBUILD_INDEX:=I.REBUILD_INDEX;
		EXECUTE IMMEDIATE LC_REBUILD_INDEX;
	END LOOP;
	gv_trcmsg:='3.7.4 Rebuild Unusable PK Index ends'||CHR(13);
	gt_start_time:= SYSTIMESTAMP;

	/*START: NEW LOGGING MECHANISM CHANGES*/       
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
			(
			p_job_id_r                    => gn_out_job_id                                           
			,p_batch_id_r                  => gn_sysdt_batchid                                    
			,p_message_type_r              => gv_message_type                                    
			,p_code_location_r             => gv_main_loadedby                                 
			,p_message_r                   => gv_trcmsg                                                                 
			,p_count_type_r                => NULL                                                                          
			,p_count_r                     => NULL                                                                                     
			,p_duration_r                  => NULL                                                                                     
			,p_created_by_r                => GV_JOB_NAME                                                       
			,out_prcs_job_log_message_id_r => gn_job_log_message_id                       
			);
	/*END: NEW LOGGING MECHANISM CHANGES*/
	gv_trcmsg:='3.7.z Exit from prc_trunc_partition'||CHR(13);
	gt_start_time:= SYSTIMESTAMP;

	/*START: NEW LOGGING MECHANISM CHANGES*/       
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
			(
			p_job_id_r                    => gn_out_job_id                                           
			,p_batch_id_r                  => gn_sysdt_batchid                                    
			,p_message_type_r              => gv_message_type                                    
			,p_code_location_r             => gv_main_loadedby                                 
			,p_message_r                   => gv_trcmsg                                                                 
			,p_count_type_r                => NULL                                                                          
			,p_count_r                     => NULL                                                                                     
			,p_duration_r                  => NULL                                                                                     
			,p_created_by_r                => GV_JOB_NAME                                                       
			,out_prcs_job_log_message_id_r => gn_job_log_message_id                       
			);
	/*END: NEW LOGGING MECHANISM CHANGES*/
EXCEPTION
WHEN OTHERS THEN
    gc_errmsg :=SUBSTR(SQLERRM,1,4000);
    gv_trcmsg:='2.z Error in prc_trunc_partition'||chr(13);
	/*START: NEW LOGGING MECHANISM CHANGES*/    
    pkg_grp_log_util.prc_update_log_message_r
			   (   n_prcs_job_log_message_id_r  => gn_job_log_message_id
				  ,p_err_msg                    => gv_trcmsg
			   );
    /*END: NEW LOGGING MECHANISM CHANGES*/  

    pkg_grp_log_util.prc_update_log
			  (   p_job_id  					=> gn_out_job_id					
				 ,p_job_status					=> gv_error_status 					               
				 ,p_err_msg						=> gv_errmsg 						                   
				 ,p_trc_msg						=> gv_trcmsg												 
				 ,p_log_util_called_by_r		=> gv_main_loadedby   				         
			  );

    RAISE;
END prc_trunc_partition;

PROCEDURE main
IS
/**************************************************************************************************************
  Purpose:  Main procedures calls other procedure to load data into RPT_COMMISSIONS_R

	Author		Date     	Description
	---------	-------- 	-------------------------------------------------
	Chandra		22/08/24	Initial Creation
***************************************************************************************************************/   
	ln_rec_cnt NUMBER:=0;
	ld_fic_mis_date_2 DATE;
	ln_fisc_current_month NUMBER;
BEGIN
    --Call Log Util pkg to Insert entry in PRCS_JOB_LOG_R
	pkg_grp_log_util.prc_insert_log
		   ( 
			p_source              => gc_source                 
			,p_job_nm              => gc_job_name                   
			,p_job_status          => gc_running_status         
			,p_err_msg             => null                      
			,p_trc_msg             => null                      
			,p_n_batch_id          => gn_sysdt_batchid          
			,p_log_util_called_by_r=> gc_main_loadedby          
			,out_job_id            => gn_out_job_id             
			);
    gv_trcmsg:='1. Entered into main'||chr(13);
	gt_start_time:= SYSTIMESTAMP;

	/*START: NEW LOGGING MECHANISM CHANGES*/       
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
			(
			p_job_id_r                    => gn_out_job_id                                           
			,p_batch_id_r                  => gn_sysdt_batchid                                    
			,p_message_type_r              => gv_message_type                                    
			,p_code_location_r             => gv_main_loadedby                                 
			,p_message_r                   => gv_trcmsg                                                                 
			,p_count_type_r                => NULL                                                                          
			,p_count_r                     => NULL                                                                                     
			,p_duration_r                  => NULL                                                                                     
			,p_created_by_r                => GV_JOB_NAME                                                       
			,out_prcs_job_log_message_id_r => gn_job_log_message_id                       
			);            
	/*END: NEW LOGGING MECHANISM CHANGES*/
    gv_trcmsg:='gn_current_month     :->'||gn_current_month||chr(13);
	gt_start_time:= SYSTIMESTAMP;

	/*START: NEW LOGGING MECHANISM CHANGES*/       
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
			(
			p_job_id_r                    => gn_out_job_id                                           
			,p_batch_id_r                  => gn_sysdt_batchid                                    
			,p_message_type_r              => gv_message_type                                    
			,p_code_location_r             => gv_main_loadedby                                  
			,p_message_r                   => gv_trcmsg                                                                 
			,p_count_type_r                => NULL                                                                           
			,p_count_r                     => NULL                                                                                      
			,p_duration_r                  => NULL                                                                                      
			,p_created_by_r                => GV_JOB_NAME                                                       
			,out_prcs_job_log_message_id_r => gn_job_log_message_id                       
			);            
	/*END: NEW LOGGING MECHANISM CHANGES*/ 
    gv_trcmsg:='gn_prior_month       :->'||gn_prior_month||chr(13);
	gt_start_time:= SYSTIMESTAMP;

	/*START: NEW LOGGING MECHANISM CHANGES*/       
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
			(
			p_job_id_r                    => gn_out_job_id                                           
			,p_batch_id_r                  => gn_sysdt_batchid                                    
			,p_message_type_r              => gv_message_type                                    
			,p_code_location_r             => gv_main_loadedby                                  
			,p_message_r                   => gv_trcmsg                                                                 
			,p_count_type_r                => NULL                                                                           
			,p_count_r                     => NULL                                                                                      
			,p_duration_r                  => NULL                                                                                      
			,p_created_by_r                => GV_JOB_NAME                                                       
			,out_prcs_job_log_message_id_r => gn_job_log_message_id                       
			);            
	/*END: NEW LOGGING MECHANISM CHANGES*/ 

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

	PKG_GRP_LOAD_RPT_COMMISSIONS_R.prc_get_cur_data;

	-- End : Kill/Fill Changes 12th May 2026 	: Added New 

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

 	gv_trcmsg:='7. Call procedure to unusable prc_rebuild_indexes from main'||chr(13);
	gt_start_time:= SYSTIMESTAMP;

	/*START: NEW LOGGING MECHANISM CHANGES*/       
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
			(
			p_job_id_r                    => gn_out_job_id                                           
			,p_batch_id_r                  => gn_sysdt_batchid                                    
			,p_message_type_r              => gv_message_type                                    
			,p_code_location_r             => gv_main_loadedby                                 
			,p_message_r                   => gv_trcmsg                                                                 
			,p_count_type_r                => NULL                                                                          
			,p_count_r                     => NULL                                                                                     
			,p_duration_r                  => NULL                                                                                     
			,p_created_by_r                => GV_JOB_NAME                                                       
			,out_prcs_job_log_message_id_r => gn_job_log_message_id                       
			);            
	/*END: NEW LOGGING MECHANISM CHANGES*/
    PKG_GRP_LOAD_RPT_COMMISSIONS_R.prc_rebuild_indexes;

    gv_trcmsg:='7.z Completed Procedure unusable prc_rebuild_indexes call from main'||chr(13);
	gt_start_time:= SYSTIMESTAMP;

	/*START: NEW LOGGING MECHANISM CHANGES*/       
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
			(
			p_job_id_r                    => gn_out_job_id                                           
			,p_batch_id_r                  => gn_sysdt_batchid                                    
			,p_message_type_r              => gv_message_type                                    
			,p_code_location_r             => gv_main_loadedby                                 
			,p_message_r                   => gv_trcmsg                                                                 
			,p_count_type_r                => NULL                                                                          
			,p_count_r                     => NULL                                                                                     
			,p_duration_r                  => NULL                                                                                     
			,p_created_by_r                => GV_JOB_NAME                                                       
			,out_prcs_job_log_message_id_r => gn_job_log_message_id                       
			);            
	/*END: NEW LOGGING MECHANISM CHANGES*/

 	--gv_trcmsg:='8. Gather RPT_COMMISSIONS_R table stats from main'||chr(13);
    --DBMS_STATS.GATHER_TABLE_STATS('ATOMIC','RPT_COMMISSIONS_R');
    --gv_trcmsg:='8.z Completed Gather RPT_COMMISSIONS_R table stats from main'||chr(13);

    gv_trcmsg:='1.z Exit from main'||chr(13);
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
            (	 p_job_id_r                    => gn_out_job_id						
				,p_batch_id_r                  => gn_sysdt_batchid					
				,p_message_type_r              => gv_message_type					
				,p_code_location_r             => gv_main_loadedby					
				,p_message_r                   => gv_trcmsg							
				,p_count_type_r                => NULL								
				,p_count_r                     => NULL								
				,p_duration_r                  => NULL								
				,p_created_by_r                => Gv_JOB_NAME						
				,out_prcs_job_log_message_id_r => gn_job_log_message_id				
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/     

    pkg_grp_log_util.prc_update_log
		(   p_job_id  					=> gn_out_job_id					
		 ,p_job_status					=> gv_success_status 				              
		 ,p_err_msg						=> gv_errmsg   						                   
		 ,p_trc_msg						=> gv_trcmsg						 					 
		 ,p_log_util_called_by_r		=> gv_main_loadedby  				            
		);
    COMMIT;
EXCEPTION
WHEN OTHERS THEN
    gc_errmsg :=SUBSTR(SQLERRM,1,4000);
    gv_trcmsg:='1. Error in main'||chr(13);
	/*START: NEW LOGGING MECHANISM CHANGES*/    
    pkg_grp_log_util.prc_update_log_message_r
			   (   n_prcs_job_log_message_id_r  => gn_job_log_message_id
				  ,p_err_msg                    => gv_trcmsg
					   );
    /*END: NEW LOGGING MECHANISM CHANGES*/

    pkg_grp_log_util.prc_update_log
			  (   p_job_id  					=> gn_out_job_id					
				 ,p_job_status					=> gv_error_status 					                
				 ,p_err_msg						=> gv_errmsg 						                    
				 ,p_trc_msg						=> gv_trcmsg												 
				 ,p_log_util_called_by_r		=> gv_main_loadedby   				          
			  );
    RAISE;
END main;

PROCEDURE prc_get_cur_data
/**************************************************************************************************************
  Purpose:  Procedure to perform ref cursor assignment

	Author		Date     	Description
	---------	-------- 	-------------------------------------------------
	Chandra		22/08/24	Initial Creation
	Samba		12/05/26	(p_out_cursor OUT SYS_REFCURSOR) commented as part of Kill Fill process
	Madhurima	05/06/26	V_DATA_SOURCE_NAME_R- Added this field in the Target table as part of Project Crown
***************************************************************************************************************/    
AS
BEGIN
	gv_trcmsg:='5.1 Entered into prc_get_cur_data ';
	gt_start_time:= SYSTIMESTAMP;

	/*START: NEW LOGGING MECHANISM CHANGES*/       
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
			(
			p_job_id_r                    => gn_out_job_id                                           
			,p_batch_id_r                  => gn_sysdt_batchid                                    
			,p_message_type_r              => gv_message_type                                    
			,p_code_location_r             => gv_main_loadedby                                 
			,p_message_r                   => gv_trcmsg                                                                 
			,p_count_type_r                => NULL                                                                          
			,p_count_r                     => NULL                                                                                     
			,p_duration_r                  => NULL                                                                                     
			,p_created_by_r                => GV_JOB_NAME                                                       
			,out_prcs_job_log_message_id_r => gn_job_log_message_id                       
			);   
	/*END: NEW LOGGING MECHANISM CHANGES*/   

	-- Start : Kill/Fill Changes 12th May 2026
	EXECUTE IMMEDIATE 'ALTER SESSION ENABLE PARALLEL DML'; 
	-- End : Kill/Fill Changes 12th May 2026

	gv_trcmsg := '5.2 - Data load starts for _EXG table for Partition Exchange';
	/*NEW LOGGING MECHANISM CHANGES*/	
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
			( p_job_id_r                    => gn_out_job_id				
			,p_batch_id_r                  => gn_sysdt_batchid				
			,p_message_type_r              => gv_message_type				
			,p_code_location_r             => gv_main_loadedby			
			,p_message_r                   => gv_trcmsg					
			,p_count_type_r                => NULL							
			,p_count_r                     => NULL							
			,p_duration_r                  => NULL							
			,p_created_by_r                => gv_job_name					
			,out_prcs_job_log_message_id_r => gn_job_log_message_id	
			);	

	-- Start : Kill/Fill Changes 12th May 2026: Commented following 
	-- Open/Assign SELECT stmnt
	-- OPEN p_out_cursor FOR

	INSERT /*+ APPEND PARALLEL(stg, 8) */ INTO RPT_COMMISSIONS_R_EXG stg    
	SELECT /*+ PARALLEL(8) */  
		CAST(NULL AS NUMBER) AS N_BILLGROUP_SK_R
		,comm_summ.N_POLICY_SK_R          as  N_POLICY_SK_R
		,comm_summ.N_AGENT_SK_R          as   N_AGENT_SK_R
		,comm_summ.N_CUST_PARTY_SK_R      as  N_CUST_PARTY_SK_R
		,comm_summ.V_TEMPLATE_NAME_R          as  V_TEMPLATE_NAME_R
		,comm_summ.D_COMMISSION_DATE_R          as D_COMMISSION_DATE_R
		,comm_summ.D_DUE_DATE_R          as  D_DUE_DATE_R
		,comm_summ.D_PAID_TO_DATE_R          as  D_PAID_TO_DATE_R
		,comm_summ.V_COMMISSION_TYPE_R          as  V_COMMISSION_TYPE_R
		,comm_summ.N_COMMISSION_AMOUNT_R          as  N_COMMISSION_AMOUNT_R
		,comm_summ.V_COMMISSION_STATUS_R          as V_COMMISSION_STATUS_R
		,gc_main_loadedby                        V_LAST_MODIFIED_BY_R  
		,gd_sysdate                           T_CREATION_DATE_R     
		,gc_main_loadedby                     V_CREATED_BY_R 
		,gd_sysdate                           T_LAST_MODIFIED_DATE_R
		,'Y'                                  V_RPT_ACTIVE_STATUS_R 
		,gn_sysdt_batchid                     N_BATCH_ID_R		  
		,gn_current_month                     N_YEARMONTH_R 
		-- 21-01-2025 Add column Start 
		-- 12-02-2025 changes start
		--,nvl(stg.V_SALES_PLAN_DESC_R,stg1.V_SALES_PLAN_DESC_R)        as V_SALES_PLAN_DESC_R    --06-02-2025 nvl added 
		, case 
		when nvl(comm_summ.v_commission_type_r,'-') in ('A','O') 
		THEN 
		--SUBSTR(comm_summ.V_TEMPLATE_NAME_R, INSTR(comm_summ.V_TEMPLATE_NAME_R, '-') + 1, INSTR(comm_summ.V_TEMPLATE_NAME_R, '%') - INSTR(comm_summ.V_TEMPLATE_NAME_R, '-')) ||' Flat' -- 18-02-2025 ||' Flat' added  
		NVL(REGEXP_SUBSTR(comm_summ.V_TEMPLATE_NAME_R,'\d*\.?\d+'),0)|| '% Flat' -- 19-02-2025 added this line and comment previous
		when plcy_lkp.V_TEMPLATE_NAME_R like 'PCH%' then SUBSTR(comm_summ.V_TEMPLATE_NAME_R, INSTR(comm_summ.V_TEMPLATE_NAME_R, '-') + 1, 2) || '% First Year, ' || SUBSTR(comm_summ.V_TEMPLATE_NAME_R, INSTR(comm_summ.V_TEMPLATE_NAME_R, '-') + 3, 2) || '% Renewal (Heaped)'---27/10/2025 Changes		   
		ELSE NVL(stg.v_sales_plan_desc_r,STG1.v_sales_plan_desc_r) END as V_SALES_PLAN_DESC_R  -- 18-02-2025 nvl added
		-- 12-02-2025 changes end
		-- 21-01-2025 Add column End
		,comm_summ.v_data_source_name_r AS v_data_source_name_r --<Project Crown Changes 25-05-2026>
	FROM fct_agent_commission_summary  comm_summ
	--28-01-2025 addition start
	left join
		(
		select 
			n_agent_sk_r
			,V_TEMPLATE_NAME_R
			,N_last_rate_r 
			,N_POLICY_SK_R
		from fct_grp_agent_policy_r_lookup  
		group by 
			n_agent_sk_r
			,V_TEMPLATE_NAME_R
			,N_last_rate_r
			,N_POLICY_SK_R
		) plcy_lkp
	on comm_summ.N_AGENT_SK_R = plcy_lkp.N_AGENT_SK_R
	AND COMM_SUMM.N_POLICY_SK_R = PLCY_LKP.N_POLICY_SK_R  --29-01-2025 ADDED 
	--          and comm_summ.V_TEMPLATE_NAME_R = plcy_lkp.v_template_name_r_1 --29-01-2025 Commneted 
	left join   
		(SELECT 
			N_PLAN_CODE_R 
			, N_RATE_R 
			, V_SALES_PLAN_DESC_R 
			, Row_number() over( partition by N_PLAN_CODE_R ,N_RATE_R order by N_PLAN_CODE_R ,N_RATE_R ) RANK_RW
		FROM ATOMIC.STG_PLAN_DETAIL
		) STG
	ON  STG.N_PLAN_CODE_R = plcy_lkp.V_TEMPLATE_NAME_R
	AND STG.N_RATE_R      = plcy_lkp.N_LAST_RATE_R
	and stg.RANK_RW       = 1    
	--28-01-2025 addition  end
	--06-02-2025 addition start
	left join   
		(SELECT 
			N_PLAN_CODE_R 
			, N_RATE_R 
			, V_SALES_PLAN_DESC_R 
			, Row_number() over( partition by N_PLAN_CODE_R  order by N_PLAN_CODE_R ) RANK_RW
		FROM ATOMIC.STG_PLAN_DETAIL
		) STG1
	ON  STG1.N_PLAN_CODE_R = plcy_lkp.V_TEMPLATE_NAME_R
	and stg1.RANK_RW       = 1
	-- 06-02-2025 addition end
	--fetch first 203 rows only
	;

	gn_run_cnt      := SQL%ROWCOUNT;
	COMMIT;

	-- Start : Kill/Fill Changes 12th May 2026: Commented following 
	EXECUTE IMMEDIATE 'ALTER SESSION DISABLE PARALLEL DML';
	-- End : Kill/Fill Changes 12th May 2026 

    gv_trcmsg:='5.3 Data load to _EXG table successful and Exit from prc_get_cur_data';
	gt_end_time:= SYSTIMESTAMP;

	/*START: NEW LOGGING MECHANISM CHANGES*/       
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
			(
			p_job_id_r                    => gn_out_job_id                                           
			,p_batch_id_r                  => gn_sysdt_batchid                                    
			,p_message_type_r              => gv_message_type                                    
			,p_code_location_r             => gv_main_loadedby                                 
			,p_message_r                   => gv_trcmsg                                                                 
			,p_count_type_r                => NULL                                                                          
			,p_count_r                     => gn_run_cnt                                                                                     
			,p_duration_r                  => FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)                                                                                     
			,p_created_by_r                => GV_JOB_NAME                                                       
			,out_prcs_job_log_message_id_r => gn_job_log_message_id                       
			);            
	/*END: NEW LOGGING MECHANISM CHANGES*/
EXCEPTION
WHEN OTHERS THEN
    gc_errmsg :=SUBSTR(SQLERRM,1,4000);
    gv_trcmsg:='4.z Error in prc_get_cur_data'||chr(13);
	/*START: NEW LOGGING MECHANISM CHANGES*/
        pkg_grp_log_util.prc_update_log_message_r
		( 
        n_prcs_job_log_message_id_r => GN_JOB_LOG_MESSAGE_ID,
        p_err_msg => gv_trcmsg 
		);
    /*END: NEW LOGGING MECHANISM CHANGES*/

    pkg_grp_log_util.prc_update_log
          (
			p_job_id => gn_out_job_id, 
			p_job_status => GV_ERROR_STATUS, 
			p_err_msg => GV_ERRMSG, 
			p_trc_msg => chr(13) || GV_ERRMSG, 
			p_log_util_called_by_r => GV_getcur_loadedby 
          );				 

    RAISE;
END prc_get_cur_data;

PROCEDURE prc_rebuild_indexes
IS 
/**************************************************************************************************************
  Purpose:  Procedure to rebuild indexes RPT_COMMISSIONS_R

  Author     Date     Description
  ---------- -------- -------------------------------------------------
  Chandra   22/08/24 Initial Creation
  **************************************************************************************************************/                 
LC_REBUILD_INDEX  VARCHAR2(300);
BEGIN
	gv_trcmsg:='7.a Entered into prc_rebuild_indexes'||chr(13); 
	gt_start_time:= SYSTIMESTAMP;

	/*START: NEW LOGGING MECHANISM CHANGES*/       
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
			(
			p_job_id_r                    => gn_out_job_id                                           
			,p_batch_id_r                  => gn_sysdt_batchid                                    
			,p_message_type_r              => gv_message_type                                    
			,p_code_location_r             => gv_main_loadedby                                 
			,p_message_r                   => gv_trcmsg                                                                 
			,p_count_type_r                => NULL                                                                          
			,p_count_r                     => NULL                                                                                     
			,p_duration_r                  => NULL                                                                                     
			,p_created_by_r                => GV_JOB_NAME                                                       
			,out_prcs_job_log_message_id_r => gn_job_log_message_id                       
			);            
	/*END: NEW LOGGING MECHANISM CHANGES*/
	FOR I IN 
		( select 
			'ALTER INDEX '||INDEX_NAME||' REBUILD parallel 16 nologging' REBUILD_INDEX 
		from ALL_INDEXES  where TABLE_NAME ='RPT_COMMISSIONS_R'
		AND INDEX_NAME NOT LIKE 'PK_%'
		AND INDEX_NAME NOT LIKE 'FK_%'
		AND STATUS='UNUSABLE'
		)
	LOOP	
		LC_REBUILD_INDEX:=I.REBUILD_INDEX;
		EXECUTE IMMEDIATE LC_REBUILD_INDEX;
	END LOOP;
	gv_trcmsg:='7.z Exit from prc_rebuild_indexes'||chr(13); 
	gt_start_time:= SYSTIMESTAMP;

	/*START: NEW LOGGING MECHANISM CHANGES*/       
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
			(
			p_job_id_r                    => gn_out_job_id                                           
			,p_batch_id_r                  => gn_sysdt_batchid                                    
			,p_message_type_r              => gv_message_type                                    
			,p_code_location_r             => gv_main_loadedby                                 
			,p_message_r                   => gv_trcmsg                                                                 
			,p_count_type_r                => NULL                                                                          
			,p_count_r                     => NULL                                                                                     
			,p_duration_r                  => NULL                                                                                     
			,p_created_by_r                => GV_JOB_NAME                                                       
			,out_prcs_job_log_message_id_r => gn_job_log_message_id                       
			);            
	/*END: NEW LOGGING MECHANISM CHANGES*/
EXCEPTION
WHEN OTHERS THEN
    gc_errmsg :=SUBSTR(SQLERRM,1,4000);
    gv_trcmsg:='7.z Error in prc_rebuild_indexes'||chr(13);
	/*START: NEW LOGGING MECHANISM CHANGES*/
        pkg_grp_log_util.prc_update_log_message_r
		( 
        n_prcs_job_log_message_id_r => GN_JOB_LOG_MESSAGE_ID,
        p_err_msg => gv_trcmsg 
		);
    /*END: NEW LOGGING MECHANISM CHANGES*/

    pkg_grp_log_util.prc_update_log
          (
			p_job_id => gn_out_job_id, 
			p_job_status => GV_ERROR_STATUS, 
			p_err_msg => GV_ERRMSG, 
			p_trc_msg => chr(13) || GV_ERRMSG, 
			p_log_util_called_by_r => GV_getcur_loadedby 
          );

    RAISE;
END prc_rebuild_indexes;

END PKG_GRP_LOAD_RPT_COMMISSIONS_R;

/

  GRANT DEBUG ON "ATOMIC"."PKG_GRP_LOAD_RPT_COMMISSIONS_R" TO "ATOMIC_DEBUG";
  GRANT EXECUTE ON "ATOMIC"."PKG_GRP_LOAD_RPT_COMMISSIONS_R" TO "ATOMIC_ALL_RO";
