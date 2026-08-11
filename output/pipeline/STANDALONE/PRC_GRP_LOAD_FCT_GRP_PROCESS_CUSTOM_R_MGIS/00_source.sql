

  CREATE OR REPLACE EDITIONABLE PROCEDURE "ATOMIC"."PRC_GRP_LOAD_FCT_GRP_PROCESS_CUSTOM_R_MGIS"

AS
--Global Constants
gd_sysdate               DATE               := TRUNC(SYSDATE);
gc_source                VARCHAR2(30)       :='EDW';
gc_job_name              VARCHAR2(50 CHAR)  :='PRC_GRP_LOAD_FCT_GRP_PROCESS_CUSTOM_R_MGIS';
gn_sysdt_batchid         NUMBER             := TO_NUMBER(TO_CHAR(gd_sysdate,'YYYYMMDD'));
gc_trcmsg                CLOB               :='Trace Message:->';
gc_error_status          VARCHAR2(30)       :='Error';
gc_success_status        VARCHAR2(30)       :='Success';
gc_running_status        VARCHAR2(30)       :='Running';
gc_errmsg                VARCHAR2(4000 CHAR);
gn_out_job_id            NUMBER;
gn_job_log_message_id_r  NUMBER;
gc_main_loadedby VARCHAR2(100 CHAR);
lv_message_type_r  PRCS_JOB_LOG_MESSAGE_R.v_message_type_r%TYPE:= PKG_GRP_LOG_UTIL.gc_message_type_info;
BEGIN

        gc_main_loadedby :='PRC_GRP_LOAD_FCT_GRP_PROCESS_CUSTOM_R_MGIS';

        pkg_grp_log_util.prc_insert_log
                       ( p_source              			=> gc_source
					    ,p_job_nm              			=> gc_job_name
                        ,p_job_status          			=> gc_running_status
                        ,p_err_msg             			=> null
                        ,p_trc_msg             			=> null
                        ,p_n_batch_id          			=> gn_sysdt_batchid
                        ,p_log_util_called_by_r			=> gc_main_loadedby
						,out_job_id            			=> gn_out_job_id
						);

		gc_trcmsg:='1. Entered into PRC_GRP_LOAD_FCT_GRP_PROCESS_CUSTOM_R_MGIS ';



		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
						p_job_id_r            			=> gn_out_job_id,
						p_batch_id_r                  	=> gn_sysdt_batchid,
						p_message_type_r              	=> lv_message_type_r,
						p_code_location_r             	=> gc_main_loadedby,
						p_message_r                   	=> gc_trcmsg,
						p_count_type_r                	=> NULL,
						p_count_r                     	=> NULL,
						p_duration_r                  	=> NULL,
						p_created_by_r                	=> GC_JOB_NAME,
						out_prcs_job_log_message_id_r 	=> gn_job_log_message_id_r
						);

		gc_trcmsg:='2. Started Merging into FCT_GRP_PROCESS_CUSTOM_R ';
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
						p_job_id_r            			=> gn_out_job_id,
						p_batch_id_r                  	=> gn_sysdt_batchid,
						p_message_type_r              	=> lv_message_type_r,
						p_code_location_r             	=> gc_main_loadedby,
						p_message_r                   	=> gc_trcmsg,
						p_count_type_r                	=> NULL,
						p_count_r                     	=> NULL,
						p_duration_r                  	=> NULL,
						p_created_by_r                	=> GC_JOB_NAME,
						out_prcs_job_log_message_id_r 	=> gn_job_log_message_id_r
						);
MERGE /*+APPEND*/ INTO ATOMIC.FCT_GRP_PROCESS_CUSTOM_R d
 USING (SELECT  distinct N_POLICY_SK_R, v_distribution_channel_r FROM ATOMIC.fct_grp_policy_r where v_distribution_channel_r like '%MGIS%'  ) s
ON ( d.N_POLICY_SK_R=s.N_POLICY_SK_R
   )
WHEN MATCHED THEN
  UPDATE SET
D.v_distribution_channel_r=S.v_distribution_channel_r
WHERE
 d.N_POLICY_SK_R=s.N_POLICY_SK_R;

commit;

		gc_trcmsg:='3. Completed Merging into FCT_GRP_PROCESS_CUSTOM_R ';
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
						p_job_id_r            			=> gn_out_job_id,
						p_batch_id_r                  	=> gn_sysdt_batchid,
						p_message_type_r              	=> lv_message_type_r,
						p_code_location_r             	=> gc_main_loadedby,
						p_message_r                   	=> gc_trcmsg,
						p_count_type_r                	=> NULL,
						p_count_r                     	=> NULL,
						p_duration_r                  	=> NULL,
						p_created_by_r                	=> GC_JOB_NAME,
						out_prcs_job_log_message_id_r 	=> gn_job_log_message_id_r
						);

		gc_trcmsg:='1. Exit from PRC_GRP_LOAD_FCT_GRP_PROCESS_CUSTOM_R_MGIS ';
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
						p_job_id_r            			=> gn_out_job_id,
						p_batch_id_r                  	=> gn_sysdt_batchid,
						p_message_type_r              	=> lv_message_type_r,
						p_code_location_r             	=> gc_main_loadedby,
						p_message_r                   	=> gc_trcmsg,
						p_count_type_r                	=> NULL,
						p_count_r                     	=> NULL,
						p_duration_r                  	=> NULL,
						p_created_by_r                	=> GC_JOB_NAME,
						out_prcs_job_log_message_id_r 	=> gn_job_log_message_id_r
						);

			pkg_grp_log_util.prc_update_log(
      						gn_out_job_id                   --p_job_id
							,gc_success_status              --p_job_status
							,gc_errmsg                      --p_err_msg
							,gc_trcmsg                      --p_trc_msg
							,gc_main_loadedby               --p_log_util_called_by_r
							);

EXCEPTION
WHEN OTHERS THEN



gc_errmsg :=SUBSTR(SQLERRM,1,4000);
    gc_trcmsg:='1.z Error in PRC_GRP_LOAD_FCT_GRP_PROCESS_CUSTOM_R_MGIS: '||gc_errmsg;

         /*START: NEW LOGGING MECHANISM CHANGES*/
    pkg_grp_log_util.prc_update_log_message_r
			(
			n_prcs_job_log_message_id_r => gn_job_log_message_id_r,
			p_err_msg 					=> gc_trcmsg
				);
	     /*END: NEW LOGGING MECHANISM CHANGES*/

	pkg_grp_log_util.prc_update_log
      (
        gn_out_job_id                   	--p_job_id
        ,gc_error_status                	--p_job_status
        ,gc_errmsg                       	--p_err_msg
        ,gc_trcmsg					     	--p_trc_msg
        ,gc_main_loadedby               	--p_log_util_called_by_r
    );


  	RAISE_APPLICATION_ERROR(-20001,'Error in PRC_GRP_LOAD_FCT_GRP_PROCESS_CUSTOM_R_MGIS:->
    Error Code:'||SQLCODE||',Error message:'||SQLERRM);

END;

