create or replace PACKAGE BODY PKG_GRP_LOAD_RPT_CLAIMANT_DTL_R_INC
/***********************************************************************
  Purpose:  This package body contains procedures which loads data into RPT_CLAIMANT_DTL_R

  Author     Date     Description
  ---------- -------- -------------------------------------------------
  VGireesh   10/11/23 Initial Creation
  VGireesh   04/01/24 Gather table stats added
  VGireesh   05/01/24 Added Privacy Indicator
  VGireesh   17/01/24 Added update script for n_claimant_age_r
  VGireesh   19/01/24 Added encrypt,decrypt for tax columns
  VGireesh   23/01/24 Closed REF Cursor
  VGireesh   26/01/24 modify privacy indicator logic to take the max timestamp – more details in the notes below for this table
                      query has been converted to MV DIM_GRP_CLAIM_DETAIL_R_MV_SSL
  VGireesh   26/02/24 for month end  that the tables start loading data in the next month partition 
                      Ex: March data on February 29th (as of 2.28). 
                          27th is Feb Fisc Month End    202402  should be truncate and load in 202402 partition
                          28th is feb Fisc Month End +1 202402  should be truncate and load in 202402 partition
                          29th is Feb Fisc Month End +2 202403  should inactive records against the partition 202402 and load data in 202403 partition 
  VGireesh   03/04/24 Added Parallel to rebuild index fast  parallel 16 nologging
  Chandra    21/06/24 Added v_cert_number_encoded_r 
  Chandra    29/08/24 Added V_INDIVIDUAL_MIDDLE_NAME_R
  Shiva		 12/01/25 Change the code to bring only incremental records 
						1. Proc - prc_get_cur_data, prc_trunc_partition, prc_rebuild_indexes and function fn_get_pacs_batch_asof_dt is no longer required.
						2. Only Main and prc_upd_del_data are used to load the data.
						3. A New MView is created for the incremental load activity : DIM_GRP_CLAIM_DETAIL_R_MV_SSL_INC
  Rose		21/05/25  Commented Insert to RPT_CLAIMANT_DTL_R and update flag = 'N' for Month End+2 Load.
  Rose		26/05/25  Adding new Logging Mechanism.
  Shashi    22/07/25  Physical delete section comment under delete logic
  Suresh    26/08/25 Standardization of Code
  Aswathi   19/08/25 adding column V_CLAIMANT_SSN_R_PRICING
						1. Variable Naming Convention:
							-- [scope][type]_[name]
							-- Scope: g = global, l = local
							-- Types: v = VARCHAR2, n = NUMBER, t = TIMESTAMP
							-- Examples: gv_name, ln_count, lt_created
							-- Use global vars (g_) only if shared across procedures.
							-- Prefer local vars (l_) for within a procedure.
							-- Keep names clear and concise.
						2. Using %TYPE for Variable declaration for all the Variables
						3. Using CONSTANT Key word if values do not change. 
						4. Using PLS_INTEGER for all integer values
						5. Indentation of Code
						6. Do not use "_R" for the Variables declared within the Package
Samba      02-02-2026  Added logging to capture the target count for Control Audits
  ***********************************************************************/
IS

--Global Constants
		gd_sysdate               CONSTANT DATE           											 := TRUNC(SYSDATE);
		gn_prior_month           PRCS_JOB_LOG_MESSAGE_R.N_COUNT_R%TYPE           					 := TO_NUMBER(TO_CHAR(ADD_MONTHS(TRUNC(gd_sysdate,'MM'),-1),'YYYYMM')); 
		gn_current_month         PRCS_JOB_LOG_MESSAGE_R.N_COUNT_R%TYPE 					             := TO_NUMBER(TO_CHAR(gd_sysdate,'YYYYMM'));							
		gn_sysdt_batchid         CONSTANT PRCS_JOB_LOG_MESSAGE_R.N_COUNT_R%TYPE 					 := TO_NUMBER(TO_CHAR(gd_sysdate,'YYYYMMDD'));							
		gv_main_loadedby         CONSTANT PRCS_JOB_LOG_MESSAGE_R.V_CODE_LOCATION_R%TYPE				 := 'PKG_GRP_LOAD_RPT_CLAIMANT_DTL_R_INC.MAIN';					     		
		gv_updby                 CONSTANT PRCS_JOB_LOG_MESSAGE_R.V_CODE_LOCATION_R%TYPE				 := 'PKG_GRP_LOAD_RPT_CLAIMANT_DTL_R_INC.PRC_UPD_DEL_DATA';		     		
		gv_getcur_loadedby       CONSTANT PRCS_JOB_LOG_MESSAGE_R.V_CODE_LOCATION_R%TYPE				 := 'PKG_GRP_LOAD_RPT_CLAIMANT_DTL_R_INC.PRC_GET_CUR_DATA';		     		
		gv_truncpartby           CONSTANT PRCS_JOB_LOG_MESSAGE_R.V_CODE_LOCATION_R%TYPE				 := 'PKG_GRP_LOAD_RPT_CLAIMANT_DTL_R_INC.PRC_TRUNC_PARTITION';	     		
		gv_rebuildindexes        CONSTANT PRCS_JOB_LOG_MESSAGE_R.V_CODE_LOCATION_R%TYPE				 := 'PKG_GRP_LOAD_RPT_CLAIMANT_DTL_R_INC.PRC_REBUILD_INDEXES';	     		
		gv_job_name              CONSTANT PRCS_JOB_LOG_R.V_JOB_NAME_R%TYPE							 := 'GRP_LOAD_RPT_CLAIMANT_DTL_R';							     		
		gv_running_status        CONSTANT PRCS_JOB_LOG_R.V_JOB_STATUS_R%TYPE  						 := 'Running';															
		gv_error_status          CONSTANT PRCS_JOB_LOG_R.V_JOB_STATUS_R%TYPE    					 := 'Error';															
		gv_success_status        CONSTANT PRCS_JOB_LOG_R.V_JOB_STATUS_R%TYPE  						 := 'Success';															
		gv_source                CONSTANT PRCS_JOB_LOG_R.V_JOB_STATUS_R%TYPE 						 := 'EDW';
		gv_target                CONSTANT PRCS_JOB_LOG_R.V_JOB_STATUS_R%TYPE 						 := 'RPT';	
		gv_main_entity           CONSTANT PRCS_JOB_LOG_MESSAGE_R.V_CODE_LOCATION_R%TYPE				 := 'CLAIMANT_DTL';
		gv_yes_ind               CONSTANT DIM_GRP_POLICY_DIR_R.v_active_status_r%TYPE				 := 'Y';
        gv_no_ind                CONSTANT DIM_GRP_POLICY_DIR_R.v_active_status_r%TYPE				 := 'N';
		gv_source_syst			 CONSTANT DIM_GRP_BILLING_POL_BILLGRP_R.v_source_system_name_r%TYPE	 := 'VUE';
		gv_message_type 	     CONSTANT PRCS_JOB_LOG_MESSAGE_R.v_message_type_r%TYPE  			 := PKG_GRP_LOG_UTIL.gc_message_type_info;
		gv_count_type    	     CONSTANT PRCS_JOB_LOG_MESSAGE_R.v_count_type_r%TYPE    			 := PKG_GRP_LOG_UTIL.gc_count_type_insert;
        gv_count_type_delete     CONSTANT PRCS_JOB_LOG_MESSAGE_R.v_count_type_r%TYPE    			 := PKG_GRP_LOG_UTIL.gc_count_type_delete;  
		gn_bulk_coll_cnt         CONSTANT PLS_INTEGER				                            	 := 10000;
        gn_run_cnt               PRCS_JOB_LOG_MESSAGE_R.N_COUNT_R%TYPE 	 				             := 0;		
		gv_trcmsg                PRCS_JOB_LOG_MESSAGE_R.V_MESSAGE_R%TYPE;			
		gt_start_time   	     PRCS_JOB_LOG_MESSAGE_R.D_CREATION_DATE_R %TYPE;					 																		
		gt_end_time 		     PRCS_JOB_LOG_MESSAGE_R.D_CREATION_DATE_R %TYPE;					 																		
		gn_job_log_message_id    PRCS_JOB_LOG_MESSAGE_R.N_COUNT_R%TYPE;								 																		
		gn_error_line            PRCS_JOB_LOG_MESSAGE_R.v_message_type_r%TYPE;						 																		
		gn_out_job_id            PRCS_JOB_LOG_MESSAGE_R.N_JOB_ID_R%TYPE;																									
		gv_errmsg                PRCS_JOB_LOG_MESSAGE_R.V_MESSAGE_R%TYPE;

        -- Local Variables
        gv_asofdtby              CONSTANT PRCS_JOB_LOG_MESSAGE_R.V_CODE_LOCATION_R%TYPE              :='PKG_GRP_LOAD_RPT_CLAIMANT_DTL_R_INC.FN_GET_PACS_BATCH_ASOF_DT';	        
        gd_pacs_batch_asof_dt    DATE;


FUNCTION FN_GET_PACS_BATCH_ASOF_DT RETURN DATE
IS
  ld_date DATE;
BEGIN

   SELECT d_eds_cycledate_r
     INTO ld_date
     FROM PRCS_GRP_DATE_PARAM_R where V_PROCESS_NAME_R='PACS_BATCH_ID';
   RETURN ld_date;
EXCEPTION
WHEN OTHERS THEN
    gv_errmsg :=SUBSTR(SQLERRM,1,4000);
    gv_trcmsg:='a.z Error in fn_get_pacs_batch_asof_dt '||gv_errmsg;

    pkg_grp_log_util.prc_update_log
			  (   p_job_id  					=> gn_out_job_id				
				 ,p_job_status					=> gv_error_status 				                
				 ,p_err_msg						=> gv_errmsg 					                    
				 ,p_trc_msg						=> gv_trcmsg											 
				 ,p_log_util_called_by_r		=> gv_asofdtby       			          
			  );

    RAISE;

END;

PROCEDURE prc_del_ext_data
IS
  /***********************************************************************
  Purpose:  This procedure delete the dubplicates records that going to load.

  Author     Date     Description
  ---------- -------- ----------------------------------------------------------
  Suresh     26/08/25 Developed first Version
*******************************************************************************/
   ln_rec_cnt PLS_INTEGER := 0;
BEGIN

    /*START: NEW LOGGING MECHANISM CHANGES*/
    gt_start_time:= SYSTIMESTAMP;

    gv_trcmsg:='4.1 START: DELETE EXSISTING RECORDS ';

    PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
                    (p_job_id_r                    => gn_out_job_id						
                    ,p_batch_id_r                  => gn_sysdt_batchid					
                    ,p_message_type_r              => gv_message_type					
                    ,p_code_location_r             => gv_main_loadedby					
                    ,p_message_r                   => gv_trcmsg							
                    ,p_count_type_r                => gv_count_type_delete								
                    ,p_count_r                     => NULL								
                    ,p_duration_r                  => NULL								
                    ,p_created_by_r                => Gv_JOB_NAME						
                    ,out_prcs_job_log_message_id_r => gn_job_log_message_id				
                    );  

        DELETE FROM RPT_CLAIMANT_DTL_R T 
         WHERE EXISTS 
                   (SELECT 1 
                      FROM ( SELECT DISTINCT n_insrd_party_sk_r 
                               FROM DIM_GRP_CLAIM_DETAIL_R_MV_SSL_INC 
                              WHERE  t_last_modified_date_r >= (SELECT max(END_DATE) 
                                                                FROM SSL_PACKAGE_MILESTONE_TABLE 
                                                                WHERE JOB_NAME='PKG_GRP_LOAD_RPT_CLAIMANT_DTL_R_INC'
                                                                )
                                AND n_insrd_party_sk_r>-1
                     UNION
                     SELECT n_party_sk_r 
                       FROM DIM_GRP_PARTY_R 
                      WHERE  n_party_sk_r IN ( SELECT n_party_sk_r 
                                                 FROM (SELECT n_party_sk_r,v_active_status_r,COUNT(1) CNT
                                                         FROM  DIM_GRP_PARTY_R A 
                                                        WHERE n_party_sk_r>-1
                                                     GROUP BY n_party_sk_r,v_active_status_r 
                                                      ) T 
                                                GROUP BY n_party_sk_r HAVING COUNT(1)=1    
                                              ) 
                         AND (v_active_status_r='N' 
                             --AND V_CHANGE_REASON_R = 'Physically Deleted'   --Commented by SP on 22/07/2025
                             )
                         AND  t_last_modified_date_r>= ( SELECT max(END_DATE) 
                                                           FROM SSL_PACKAGE_MILESTONE_TABLE 
                                                          WHERE JOB_NAME='PKG_GRP_LOAD_RPT_CLAIMANT_DTL_R_INC'
                                                       )
                         GROUP BY n_party_sk_r

                               ) S 
          WHERE S.n_insrd_party_sk_r=T.n_insrd_party_sk_r
            AND T.N_YEARMONTH_R = gn_current_month
        );

          ln_rec_cnt := SQL%ROWCOUNT;

          COMMIT;

    gv_trcmsg:='4.2 END: DELETE EXSISTING RECORDS .Total records deleted : '||ln_rec_cnt;

    gt_end_time := SYSTIMESTAMP;
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
            (    p_job_id_r                    => gn_out_job_id										   
				,p_batch_id_r                  => gn_sysdt_batchid							        
				,p_message_type_r              => gv_message_type								    
				,p_code_location_r             => gv_main_loadedby								    
				,p_message_r                   => gv_trcmsg										    
				,p_count_type_r                => gv_count_type_delete									    
				,p_count_r                     => ln_rec_cnt								        
				,p_duration_r                  => FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)  
				,p_created_by_r                => GV_JOB_NAME									    
                ,out_prcs_job_log_message_id_r => gn_job_log_message_id						        
				);
EXCEPTION
WHEN OTHERS THEN

    gv_errmsg :=SUBSTR(SQLERRM,1,4000);
    gv_trcmsg:='4.Z Error in prc_upd_del_data '||gv_errmsg;

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

END prc_del_ext_data;                

--Main procedures calls other procedure to load data in RPT_CLEINT_DTL_R
PROCEDURE MAIN
/***********************************************************************
  Purpose:  This procedure controls the overall process and calls the child
            procedures needed

  Author     Date     Description
  ---------- -------- ----------------------------------------------------------
  VGireesh   10/11/23 Developed first Version
  Suresh     26/08/25 Standardization of Code
						1. Main uses following Procedures and functions which are called from the package PKG_GRP_COMMON_UTIL 
								1. PRC_UPD_DEL_DATA updates the Prior Month active status to 'N' and also does the Truncate Partition
								2. PRC_REBUILD_INDEXES to rebuild indexes after they were disabled for performance improvement
								3. FNC_GRP_TIME_DURATION, this functions calculates the duration between start & end time of a step
								   and returns the Number of seconds.
						2. Main uses following functions which are called from the package PKG_GRP_LOG_UTIL
								1. PRC_INSTERT_LOG, This procedure creates log entry in the log table with status In-Progress.
								2. PRC_UPDATE_LOG, This procedure updates the log entry in the log table with the following status 
											Success - Upon successful completion 
											Error - If encounters any error
								3. prc_ins_prcs_job_log_message_r provides the standard process to Insert the Process Job Log Message record								
						3. standardizing the Local Variables used - For the standardizing steps refer the master comment block from Package Body
						4. Declare all the Local variables
*******************************************************************************/

IS
        lv_rpt_table 		PRCS_JOB_LOG_R.CREATED_BY_R%TYPE 			    := 'RPT_CLAIMANT_DTL_R';
        ln_rec_cnt          PLS_INTEGER	                                    := 0 ;        
        ln_ROW_CNT          PLS_INTEGER	                                    := 0 ;
        ln_idx_num			PLS_INTEGER									    := 8;

        ld_fic_mis_date_2     DATE;
        ln_fisc_current_month NUMBER;

BEGIN
      --Call Log Util pkg to Insert entry in PRCS_JOB_LOG_R
	--For more details how this procedure is being used, refer the Main Procedure comment block.
	pkg_grp_log_util.PRC_INSERT_LOG
					( p_source              		=> gv_source				
					 ,p_job_nm               		=> gv_job_name				
					 ,p_job_status           		=> gv_running_status		
					 ,p_err_msg              		=> NULL						
					 ,p_trc_msg              		=> NULL						
					 ,p_n_batch_id           		=> gn_sysdt_batchid			
					 ,p_log_util_called_by_r 		=> gv_main_loadedby			
					 ,out_job_id             		=> gn_out_job_id			
					);

	gv_trcmsg:='1. Entered into Main';
    /*START: NEW LOGGING MECHANISM CHANGES*/	   
	 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
				   ( p_job_id_r                  	=> gn_out_job_id			
					,p_batch_id_r               	=> gn_sysdt_batchid			
					,p_message_type_r            	=> gv_message_type			
					,p_code_location_r            	=> gv_main_loadedby			
					,p_message_r                  	=> gv_trcmsg				
					,p_count_type_r               	=> NULL						
					,p_count_r                    	=> NULL						
					,p_duration_r                 	=> NULL						
					,p_created_by_r               	=> GV_JOB_NAME				
					,out_prcs_job_log_message_id_r	=> gn_job_log_message_id	
					);	
    /*END: NEW LOGGING MECHANISM CHANGES*/  

    -- SET JOB TO IN-PROGRESS
    UPDATE SSL_PACKAGE_MILESTONE_TABLE SET 
        JOB_TIMESTAMP   = CURRENT_TIMESTAMP,
        JOB_STATUS      = 'IN-PROGRESS'
    WHERE JOB_NAME='PKG_GRP_LOAD_RPT_CLAIMANT_DTL_R_INC';
    COMMIT;

    gv_trcmsg :='1.2 Call fn_get_pacs_batch_asof_dt to get PACS batch date';
	gt_start_time:= SYSTIMESTAMP;
	/*START: NEW LOGGING MECHANISM CHANGES*/	   
	 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
				   ( p_job_id_r                  	=> gn_out_job_id		
					,p_batch_id_r               	=> gn_sysdt_batchid		
					,p_message_type_r            	=> gv_message_type		
					,p_code_location_r            	=> gv_main_loadedby		
					,p_message_r                  	=> gv_trcmsg			
					,p_count_type_r               	=> NULL					
					,p_count_r                    	=> NULL					
					,p_duration_r                 	=> NULL					
					,p_created_by_r               	=> GV_JOB_NAME			
					,out_prcs_job_log_message_id_r	=> gn_job_log_message_id
					);	

    gd_pacs_batch_asof_dt:=fn_get_pacs_batch_asof_dt;

    gv_trcmsg:='1.3 Completed Call fn_get_pacs_batch_asof_dt and fetched PACS batch date:->'||gd_pacs_batch_asof_dt;
    gt_end_time := SYSTIMESTAMP; -- End timing after the insert

    /*START: NEW LOGGING MECHANISM CHANGES*/   
	gt_end_time := SYSTIMESTAMP;
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
            (    p_job_id_r                    => gn_out_job_id										   
				,p_batch_id_r                  => gn_sysdt_batchid							        
				,p_message_type_r              => gv_message_type								    
				,p_code_location_r             => gv_main_loadedby								    
				,p_message_r                   => gv_trcmsg										    
				,p_count_type_r                => gv_count_type									    
				,p_count_r                     => ln_rec_cnt								        
				,p_duration_r                  => FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)  
				,p_created_by_r                => GV_JOB_NAME									    
                ,out_prcs_job_log_message_id_r => gn_job_log_message_id						        
				);	
    /*END: NEW LOGGING MECHANISM CHANGES*/ 

     ---2. Call procedure prc_upd_del_data to update active status to N for the records in Fisc prior month
    ---Also, Truncate the current Partion month data if any data present already.
   /*
    PKG_GRP_COMMON_UTIL.prc_upd_del_data
					( p_out_job_id	 				=> gn_out_job_id			
					 ,p_rpt_table 					=> lv_rpt_table				
					 ,p_upd_flag 					=> gv_no_ind				
					 ,p_idx_num						=> ln_idx_num				
					 ,p_log_seq_num					=> 2						
					 ,p_idx_unusable				=> NULL						
					 );
     */
      /*Common Utility Proc to get month end+2 date and month. Ex: If month end is 29-Aug-2025 then ln_fisc_current_month will be 202509*/
	PKG_GRP_COMMON_UTIL.prc_fisc_month_calc 
	(
		p_out_job_id            =>	gn_out_job_id,
        p_Log_seq_num           =>	2,
		ln_fisc_current_month   =>	ln_fisc_current_month,
		ld_fic_mis_date_2       =>	ld_fic_mis_date_2
	);

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

    ---3. Call local procedure prc_del_ext_data to delete exiting records that need to be inserted 
    prc_del_ext_data;

   /*START: NEW LOGGING MECHANISM CHANGES*/
    gv_trcmsg:='5. Data Load starts ';

	gt_start_time:= SYSTIMESTAMP;

    PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
				   ( p_job_id_r                  	=> gn_out_job_id		
					,p_batch_id_r               	=> gn_sysdt_batchid		
					,p_message_type_r            	=> gv_message_type		
					,p_code_location_r            	=> gv_main_loadedby		
					,p_message_r                  	=> gv_trcmsg			
					,p_count_type_r               	=> NULL					
					,p_count_r                    	=> NULL					
					,p_duration_r                 	=> NULL					
					,p_created_by_r               	=> GV_JOB_NAME			
					,out_prcs_job_log_message_id_r	=> gn_job_log_message_id
					);

 	INSERT  INTO RPT_CLAIMANT_DTL_R
                SELECT 
                     DGP.n_party_sk_r                                                                 AS n_insrd_party_sk_r
                    ,CASE 
						 WHEN DGP.v_tax_number_r IS NOT NULL 
						 THEN enc_dec.decrypt(DGP.v_tax_number_r) 
						 ELSE NULL 
					 END     			                                                              AS v_tax_number_r    
                    ,CASE 
						 WHEN FGPA.v_addressline1_r IS NOT NULL 
						 THEN FGPA.v_addressline1_r 
						 ELSE FGPA_C.v_addressline1_r 
                     END                                                                              AS v_claimant_address_line1_r
                    ,CASE 
						 WHEN FGPA.v_addressline2_r IS NOT NULL 
						 THEN FGPA.v_addressline2_r
						 ELSE FGPA_C.v_addressline2_r 
                     END                                                                              AS v_claimant_address_line2_r
                    ,CASE 
						 WHEN FGPA.v_addressline3_r IS NOT NULL 
						 THEN FGPA.v_addressline3_r
						 ELSE FGPA_C.v_addressline3_r 
                     END                                                                              AS v_claimant_address_line3_r
                    ,TRUNC( months_between( gd_pacs_batch_asof_dt , DGP.d_birth_date_r) / 12) 		  AS  n_claimant_age_r 
                    ,CASE 
						 WHEN FGPA.v_city_r IS NOT NULL 
						 THEN FGPA.v_city_r
						 ELSE FGPA_C.v_city_r 
                     END                                                                              AS v_claimant_city_r
                    ,DGP.d_birth_date_r                                                               AS d_birth_date_r
                    ,DGP.v_day_area_code_r || DGP.v_day_phone_r || DGP.v_day_extension_r              AS v_claimant_day_phone_r
                    ,DGP.v_primary_email_address_r                                                    AS v_primary_email_address_r
                    ,DGP.v_employee_num_r                                                             AS v_employee_num_r
                    ,DGP.v_individual_first_name_r                                                    AS v_individual_first_name_r
                    ,DGP.v_gender_r                                                                   AS v_gender_r
                    ,CAST(NULL AS DATE)                                                               AS d_hire_date_r 
                    ,DGP.v_individual_last_name_r                                                     AS v_individual_last_name_r
                    ,CASE 
                     WHEN FGPA_G.v_addressline1_r IS NOT NULL 
                     THEN FGPA_G.v_addressline1_r
                     ELSE FGPA_C.v_addressline1_r
                     END                                                                              AS v_addressline1_r
                    ,CASE 
                     WHEN FGPA_G.v_addressline2_r IS NOT NULL 
                     THEN FGPA_G.v_addressline2_r
                     ELSE FGPA_C.v_addressline2_r 
                     END                                                                              AS v_addressline2_r
                    ,CASE WHEN FGPA_G.v_city_r IS NOT NULL 
                     THEN FGPA_G.v_city_r
                     ELSE FGPA_C.v_city_r 
                     END                                                                              AS v_city_r
                    ,CASE 
                     WHEN FGPA_G.v_state_name_r IS NOT NULL 
                     THEN FGPA_G.v_state_name_r
                     ELSE FGPA_C.v_state_name_r 
                     END                                                                              AS v_state_name_r
                    ,CASE 
                     WHEN FGPA_G.v_postal_zip_r IS NOT NULL 
                     THEN FGPA_G.v_postal_zip_r
                     ELSE FGPA_C.v_postal_zip_r 
                     END                                                                              AS v_postal_zip_r
                    ,DGP.v_night_area_code_r ||DGP.v_night_phone_r || DGP.v_night_extension_r         AS v_claimant_night_phone_r
                    ,CAST(NULL AS NUMBER)                                                             AS n_basic_insured_salary_r   
                    ,CAST(NULL AS VARCHAR2(100))                                                      AS v_basic_insured_salary_ind_r
                    ,CASE 
                     WHEN FGPA.v_state_name_r IS NOT NULL 
                     THEN FGPA.v_state_name_r
                     ELSE FGPA_C.v_state_name_r 
                     END                                                                              AS  v_claimant_state_r
                    ,CASE 
                     WHEN FGPA.v_postal_zip_r IS NOT NULL 
                     THEN FGPA.v_postal_zip_r
                     ELSE FGPA_C.v_postal_zip_r 
                     END                                                                              AS v_claimant_zip_code_r
                    ,CASE 
                     WHEN FGPA.v_country_r IS NOT NULL 
                     THEN FGPA.v_country_r
                     ELSE FGPA_C.v_country_r 
                     END                                                                              AS v_country_r
                    ,CASE 
                     WHEN FGPA_G.v_country_r IS NOT NULL 
                     THEN FGPA_G.v_country_r
                     ELSE FGPA_C.v_country_r 
                     END                                                                              AS v_claimant_mailing_country_r
                    ,CASE 
                     WHEN FGPA.v_party_type_r IS NOT NULL 
                     THEN FGPA.v_party_type_r
                     ELSE FGPA_C.v_party_type_r 
                     END                                                                              AS v_party_address_party_type_r
                    ,CASE 
                     WHEN FGPA.v_address_type_r IS NOT NULL 
                     THEN FGPA.v_address_type_r
                     ELSE FGPA_C.v_address_type_r 
                     END                                                                              AS v_address_type_r
                    ,DGP.v_party_type_r                                                               AS v_party_type_r
                    ,DGP.v_source_system_name_r                                                       AS v_source_system_name_r
                    ,CASE 
                     WHEN DGP.v_tax_number_r IS NOT NULL 
                     THEN enc_dec.decrypt(DGP.v_tax_number_r) 
                     ELSE NULL 
                     END                                                                              AS v_claimant_ssn_r                   
                    ,CASE 
                     WHEN DGP.v_tax_number_r IS NOT NULL 
                     THEN enc_dec.decrypt(DGP.v_tax_number_r) 
                     ELSE NULL END                                                                    AS v_claimant_certificate_number_r    
                    ,CASE 
                     WHEN FGPA.v_location_id_r IS NOT NULL 
                     THEN FGPA.v_location_id_r 
                     ELSE FGPA_C.v_location_id_r 
                     END                                                                              AS v_location_id_r
                    ,gv_main_loadedby                                                                 AS v_last_modified_by_r
                    ,gd_sysdate                                                                       AS t_creation_date_r
                    ,gv_main_loadedby                                                                 AS v_created_by_r
                    ,gd_sysdate                                                                       AS t_last_modified_date_r
                    ,GN_CURRENT_MONTH                                                                 AS N_YEARMONTH_R
                    ,DGP.v_active_status_r                                                            AS v_rpt_active_status_r
                    ,gn_sysdt_batchid                                                                 AS n_batch_id_r
                    ,DGCDRMS.v_privacy_indicator_r                                                    AS v_privacy_indicator_r
                    ,DGP.v_tax_number_r                                                               AS v_tax_number_enc_r
                    ,ora_hash(ENC_DEC.DECRYPT(DGP.V_TAX_NUMBER_R),4294967295,4131)                    AS v_cert_number_encoded_r 
                    ,DGP.V_INDIVIDUAL_MIDDLE_NAME_R                                                   AS V_INDIVIDUAL_MIDDLE_NAME_R
					,enc_dec.encrypt(CASE 
                     WHEN DGP.v_tax_number_r IS NOT NULL 
                     THEN enc_dec.decrypt(DGP.v_tax_number_r) 
                     ELSE NULL 
                     END)                                                                             AS v_claimant_ssn_r_pricing
                FROM ( SELECT n_insrd_party_sk_r
                            , v_privacy_indicator_r 
                         FROM DIM_GRP_CLAIM_DETAIL_R_MV_SSL_INC 
                        WHERE t_last_modified_date_r >= (SELECT max(END_DATE) 
                                                           FROM SSL_PACKAGE_MILESTONE_TABLE 
                                                      	  WHERE JOB_NAME='PKG_GRP_LOAD_RPT_CLAIMANT_DTL_R_INC'
														   )
						) DGCDRMS
           INNER JOIN ATOMIC.DIM_GRP_PARTY_R DGP 
                   ON DGCDRMS.n_insrd_party_sk_r = DGP.n_party_sk_r
                  AND DGP.v_active_status_r = 'Y'
            LEFT JOIN (SELECT  * 
                        FROM FCT_GRP_PARTY_ADDRESS_R 
                       WHERE v_location_id_r = 'MAIN'
                         AND n_address_sk_r>-1 
                      ) FGPA 
                   ON FGPA.n_party_sk_r = DGP.n_party_sk_r
                  AND FGPA.N_SOURCE_VERSION_NUMBER_R = DGP.N_SOURCE_VERSION_NUMBER_R
            LEFT JOIN (SELECT  * 
                         FROM FCT_GRP_PARTY_ADDRESS_R 
                        WHERE V_LOCATION_ID_R = 'MAILING'
                          AND n_address_sk_r>-1 
                       ) FGPA_G 
                   ON FGPA_G.n_party_sk_r = DGP.n_party_sk_r
                  AND FGPA_G.N_SOURCE_VERSION_NUMBER_R = DGP.N_SOURCE_VERSION_NUMBER_R
            LEFT JOIN (SELECT  * 
                         FROM ATOMIC.FCT_GRP_PARTY_ADDRESS_R 
                        WHERE  v_source_system_name_r = 'CV'
                          AND n_party_sk_r<> -1
                      ) FGPA_C 
                   ON FGPA_C.n_party_sk_r = DGP.n_party_sk_r 
                WHERE DGCDRMS.n_insrd_party_sk_r>-1;
		ln_rec_cnt := SQL%ROWCOUNT;
COMMIT;

    gv_trcmsg :='5.1: Data Loaded '||ln_rec_cnt||' records ';

    /*START: NEW LOGGING MECHANISM CHANGES*/   
	gt_end_time := SYSTIMESTAMP;
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
            (    p_job_id_r                    => gn_out_job_id										   
				,p_batch_id_r                  => gn_sysdt_batchid							        
				,p_message_type_r              => gv_message_type								    
				,p_code_location_r             => gv_main_loadedby								    
				,p_message_r                   => gv_trcmsg										    
				,p_count_type_r                => gv_count_type									    
				,p_count_r                     => ln_rec_cnt								        
				,p_duration_r                  => FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)  
				,p_created_by_r                => GV_JOB_NAME									    
                ,out_prcs_job_log_message_id_r => gn_job_log_message_id						        
				);	
    /*END: NEW LOGGING MECHANISM CHANGES*/	

	/*START: NEW LOGGING MECHANISM CHANGES*/	
	gv_trcmsg:='5.2 START: UPDATE CLAIMANT AGE COLUMN ';
	gt_start_time:= SYSTIMESTAMP;
	 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
				   ( p_job_id_r                  	=> gn_out_job_id		
					,p_batch_id_r               	=> gn_sysdt_batchid		
					,p_message_type_r            	=> gv_message_type		
					,p_code_location_r            	=> gv_main_loadedby		
					,p_message_r                  	=> gv_trcmsg			
					,p_count_type_r               	=> NULL					
					,p_count_r                    	=> NULL					
					,p_duration_r                 	=> NULL					
					,p_created_by_r               	=> GV_JOB_NAME			
					,out_prcs_job_log_message_id_r	=> gn_job_log_message_id
					);	
	/*END: NEW LOGGING MECHANISM CHANGES*/

	    gv_trcmsg :='5.3: To capture the Target Count for Audit Controls ';

    /*START: NEW LOGGING MECHANISM CHANGES*/   

	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
            (    p_job_id_r                    => gn_out_job_id										   
				,p_batch_id_r                  => gn_sysdt_batchid							        
				,p_message_type_r              => gv_message_type								    
				,p_code_location_r             => gv_main_loadedby								    
				,p_message_r                   => gv_trcmsg										    
				,p_count_type_r                => 'AUDIT_TARGET_COUNT'									    
				,p_count_r                     => ln_rec_cnt								        
				,p_duration_r                  => NULL 
				,p_created_by_r                => GV_JOB_NAME									    
                ,out_prcs_job_log_message_id_r => gn_job_log_message_id						        
				);
    MERGE  INTO RPT_CLAIMANT_DTL_R M
    USING (
        SELECT D_BIRTH_DATE_R, 
               ROUND(MONTHS_BETWEEN(dt_v.d_eds_cycledate_r, t.D_BIRTH_DATE_R) / 12) AS n_claimant_age_r
        FROM (
            SELECT D_BIRTH_DATE_R FROM RPT_CLAIMANT_DTL_R
            WHERE n_yearmonth_r = GN_CURRENT_MONTH
            GROUP BY D_BIRTH_DATE_R

        ) t
        INNER JOIN (
            SELECT  d_eds_cycledate_r FROM prcs_grp_date_param_r WHERE V_PROCESS_NAME_R = 'PACS_BATCH_ID'
        ) dt_v ON 1=1
    ) C
    ON (M.D_BIRTH_DATE_R = C.D_BIRTH_DATE_R AND M.n_yearmonth_r = GN_CURRENT_MONTH)
    WHEN MATCHED THEN
        UPDATE SET M.n_claimant_age_r = C.n_claimant_age_r;

	ln_rec_cnt:= SQL%ROWCOUNT;
    commit;

	/*START: NEW LOGGING MECHANISM CHANGES*/	

	 /*START: NEW LOGGING MECHANISM CHANGES*/   
    gv_trcmsg:='5.3 END: UPDATE CLAIMANT AGE COLUMN ';
	gt_end_time := SYSTIMESTAMP;
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
            (    p_job_id_r                    => gn_out_job_id										   
				,p_batch_id_r                  => gn_sysdt_batchid							        
				,p_message_type_r              => gv_message_type								    
				,p_code_location_r             => gv_main_loadedby								    
				,p_message_r                   => gv_trcmsg										    
				,p_count_type_r                => gv_count_type									    
				,p_count_r                     => ln_rec_cnt								        
				,p_duration_r                  => FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)  
				,p_created_by_r                => GV_JOB_NAME									    
                ,out_prcs_job_log_message_id_r => gn_job_log_message_id						        
				);	
    /*END: NEW LOGGING MECHANISM CHANGES*/	

	gv_trcmsg:='5.4. Calling Audit Control Procedure';

		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
		 (
			p_job_id_r                    => gn_out_job_id,
			p_batch_id_r                  => gn_sysdt_batchid,
			p_message_type_r              => gv_message_type,
			p_code_location_r             => gv_main_loadedby,
			p_message_r                   => gv_trcmsg,
			p_count_type_r                => NULL,
			p_count_r                     => NULL,
			p_duration_r                  => NULL,
			p_created_by_r                => GV_JOB_NAME,
			out_prcs_job_log_message_id_r => gn_job_log_message_id
		);

		PRC_GRP_AUDIT_CONTROL_PROCESS(gv_source,gv_main_entity,gv_source,gv_target);
-- Mark the job as complete
    UPDATE SSL_PACKAGE_MILESTONE_TABLE SET 
        JOB_TIMESTAMP   = CURRENT_TIMESTAMP,
        JOB_STATUS      = 'SUCCESS',
        START_DATE      = END_DATE,
        END_DATE        = (SELECT MAX(T_LAST_MODIFIED_DATE_R) FROM DIM_GRP_CLAIM_DETAIL_R_MV_SSL_INC)
    WHERE JOB_NAME='PKG_GRP_LOAD_RPT_CLAIMANT_DTL_R_INC';
    COMMIT;

 /*START: NEW LOGGING MECHANISM CHANGES*/   
	gv_trcmsg:= '6. - Exit from main';
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
EXCEPTION
WHEN OTHERS THEN

	gv_errmsg :=SUBSTR(SQLERRM,1,4000);
    gv_trcmsg:='1.Z Error in main: '||gv_errmsg;

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
END MAIN;

END PKG_GRP_LOAD_RPT_CLAIMANT_DTL_R_INC;