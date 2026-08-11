create or replace PACKAGE BODY pkg_grp_load_difw AS

    PROCEDURE main 
	(
        p_v_job_name_r            IN  VARCHAR2,
        p_source_system           IN  VARCHAR2,
      p_grp_sourcetype           IN  VARCHAR2 --FCT_SINGLE_SRC,FCT_MULTI_SRC,DIM_SINGLE_SRC,DIM_MULTI_SRC ,DELETE,FCT_SINGLE_INS,FCT_MULTI_INS
    ) IS

      -- lc_errmsg        VARCHAR2(4000);
      --lc_errcd         VARCHAR2(30);
      --lc_trackmsg      VARCHAR2(4000);
      lc_batch_id      VARCHAR2(40);
      lc_rerun_check   NUMBER;
      lc_src_sqlcmd_where_clause     VARCHAR2(4000);
      lc_srctbl_where_clause     VARCHAR2(4000);
      lc_tgttbl_where_clause     VARCHAR2(4000);
      lc_VAR_GRP_DIFW_SRC_TBL_NM VARCHAR2(300);
      lc_VAR_GRP_DIFW_tgt_TBL_NM VARCHAR2(300);
      lc_jobname   VARCHAR2(300);
      ln_recon_cnt Number;

    BEGIN

        gc_trcmsg:=gc_trcmsg||'1. Entered into MAIN'||chr(13);
        gc_updby:='main';

        IF 
            p_source_system IS NULL 
            or p_v_job_name_r is null 
            or p_grp_sourcetype is null
        THEN
            gc_trcmsg:=gc_trcmsg||'1.a Param Source System/Job Name Sys/Group Source Type is NULL '||chr(13);
        ELSE
            gc_trcmsg:=gc_trcmsg||'1.a Param Source System :>'||p_source_system||' Job Name :->'||p_v_job_name_r||' Group Source Type :->'||p_grp_sourcetype||chr(13);	
        END IF;
        --dbms_output.put_line(gc_trcmsg);

        IF p_grp_sourcetype not in ('FCT_SINGLE_SRC','FCT_MULTI_SRC','DIM_SINGLE_SRC','DIM_MULTI_SRC','DELETE','FCT_SINGLE_INS','FCT_MULTI_INS') 
        THEN
            gc_errmsg:=SUBSTR(SQLERRM,1,4000);
            gc_trcmsg:=gc_trcmsg||'1.b Invalid p_grp_sourcetype param value and hence terminating - ' || p_grp_sourcetype||chr(13)||gc_errmsg;
            RAISE_APPLICATION_ERROR(-20000, 'Invalid p_grp_sourcetype param value and hence terminating - ' || p_grp_sourcetype);

        END IF;

        gc_grp_sourcetype:=   p_grp_sourcetype;  

        IF INSTR(gc_grp_sourcetype, 'MULTI')>0 
        THEN
            lc_jobname :=p_source_system||'_'||p_v_job_name_r;

        ELSIF INSTR(gc_grp_sourcetype, 'SINGLE')  > 0 OR INSTR(gc_grp_sourcetype, 'DELETE')>0
        THEN
             lc_jobname :=p_v_job_name_r;

        END IF;

        gc_trcmsg:=gc_trcmsg||'1.c Job Name is  - ' || lc_jobname||chr(13);
        --dbms_output.put_line('lc_jobname is ->  '||gc_job_name);
        gc_trcmsg:=GC_TRCMSG||'2.0 Call get_batch_id from MAIN'||CHR(13);
        gn_batchid:=pkg_grp_load_difw.get_batch_id(p_source_system);
        gc_trcmsg:=gc_trcmsg||'2.z Called get_batch_id  MAIN :->BatchID is :->'||gn_batchid||chr(13);

        GC_TRCMSG:=GC_TRCMSG||'3.0 Call get_reruncheck_cnt from MAIN'||CHR(13);
        dbms_output.put_line(gc_trcmsg);
        lc_rerun_check:=pkg_grp_load_difw.get_reruncheck_cnt(lc_jobname,gn_batchid);

        dbms_output.put_line(lc_rerun_check);
        gc_trcmsg:=gc_trcmsg||'3.z Called get_reruncheck_cnt  MAIN :->Rerunchk Cnt is :->'||lc_rerun_check||chr(13);
        dbms_output.put_line(gc_trcmsg);

        IF lc_rerun_check > 0    
        THEN
            gc_errmsg:=SUBSTR(SQLERRM,1,4000);
            gc_trcmsg:=gc_trcmsg||'3.z Run detected for the batch and hence terminating ' || gn_batchid||chr(13)||gc_errmsg;
            pkg_grp_log_util.prc_update_log
            (
            gn_out_job_id                 --p_job_id
            ,gc_error_status              --p_job_status
            ,gc_errmsg                    --p_err_msg
            ,gc_trcmsg||chr(13)||gc_errmsg--p_trc_msg
            ,gc_updby                     --p_log_util_called_by_r
            );

            RAISE_APPLICATION_ERROR(-20000, 'Run detected for the batch and hence terminating ' || gn_batchid);

        END IF;

        --Entry to PRCS_JOB_LOG_R ;
        pkg_grp_log_util.prc_insert_log(p_source               => p_source_system, 
                                            p_job_nm               => lc_jobname,
                                            p_job_status           => gc_running_status,
                                            p_err_msg              => NULL,
                                            p_trc_msg              => gc_trcmsg,
                                            p_n_batch_id           => gn_batchid,
                                            p_log_util_called_by_r => gc_main_loadedby,
                                            out_job_id             => gn_out_job_id
                                            );

        lc_var_grp_difw_src_tbl_nm:=pkg_grp_load_difw.get_src_table_name(lc_jobname);

        gc_trcmsg:=gc_trcmsg||'4.z Called get_src_table_name  MAIN :->src table name is :->'||lc_var_grp_difw_src_tbl_nm||chr(13);
        --dbms_output.put_line(gc_trcmsg);

        gc_trcmsg:=GC_TRCMSG||'5.0 Call get_tgt_table_name from MAIN'||CHR(13);
        --dbms_output.put_line(gc_trcmsg);

        lc_var_grp_difw_tgt_tbl_nm:=pkg_grp_load_difw.get_tgt_table_name(lc_jobname);

        gc_trcmsg:=gc_trcmsg||'5.z Called get_tgt_table_name  MAIN :->tgt table name is :->'||lc_var_grp_difw_tgt_tbl_nm||chr(13);
        --dbms_output.put_line(gc_trcmsg);
        IF INSTR(gc_grp_sourcetype, 'INS')  > 0
        THEN
            gc_trcmsg:=GC_TRCMSG||'6.0 Call get_source_sql_cmd from MAIN'||CHR(13);
            --dbms_output.put_line(gc_trcmsg);
            lc_src_sqlcmd_where_clause:=pkg_grp_load_difw.get_source_sql_cmd(lc_jobname);        
            gc_trcmsg:=gc_trcmsg||'6.z Called source_sql_cmd  MAIN :->lc_src_sqlcmd_where_clause is :->'||lc_src_sqlcmd_where_clause||chr(13);
            --dbms_output.put_line(gc_trcmsg);

            IF INSTR(gc_grp_sourcetype, 'MULTI')  > 0
            THEN
                gc_trcmsg:=GC_TRCMSG||'7.0 Call where_source_system from MAIN'||CHR(13);
                dbms_output.put_line(gc_trcmsg);
                lc_srctbl_where_clause:=pkg_grp_load_difw.get_multisrcsys_where_source_system(lc_jobname);

                gc_trcmsg:=gc_trcmsg||'7.z Called where_source_system  MAIN :->where_source_system is :->'||lc_srctbl_where_clause||chr(13);
                dbms_output.put_line(gc_trcmsg);

                pkg_grp_load_difw.get_multisrcsys_insert(p_v_job_name_r,p_source_system,lc_srctbl_where_clause,lc_src_sqlcmd_where_clause,lc_var_grp_difw_src_tbl_nm,lc_var_grp_difw_tgt_tbl_nm);
                gc_trcmsg:=gc_trcmsg||'7.z Called get_multisrcsys_insert  '||chr(13);
                dbms_output.put_line(gc_trcmsg);

                gc_trcmsg:=GC_TRCMSG||'8.0 Call get_recon_cnt from MAIN'||CHR(13);
                --dbms_output.put_line(gc_trcmsg);
                ln_recon_cnt:=pkg_grp_load_difw.get_recon_cnt (gn_batchid,p_source_system,lc_var_grp_difw_src_tbl_nm,lc_var_grp_difw_tgt_tbl_nm);
                GC_TRCMSG   :=GC_TRCMSG||'8.Z Call get_recon_cnt from MAIN ln_recon_cnt:'||ln_recon_cnt||CHR(13);

                --dbms_output.put_line(gc_trcmsg);
                --Check the recon count;
                IF ln_recon_cnt != 0 
                THEN
                    gc_errmsg      :=SUBSTR(SQLERRM,1,4000);
                    gc_trcmsg      :=gc_trcmsg||'9.z There is mismatch between Staging and Dimension table record counts , Please verify ' ||chr(13)||gc_errmsg;
                    pkg_grp_log_util.prc_update_log ( gn_out_job_id --p_job_id
                    ,gc_error_status                                --p_job_status
                    ,gc_errmsg                                      --p_err_msg
                    ,gc_trcmsg||chr(13)||gc_errmsg                  --p_trc_msg
                    ,gc_updby                                       --p_log_util_called_by_r
                    );
                    RAISE_APPLICATION_ERROR(-20000, 'There is mismatch between Staging and Dimension table record counts  for batch id :'||gn_batchid||', Please verify' );
                END IF;

                gc_trcmsg:=GC_TRCMSG||'10.0 Call tbl_rec_count_jobwise_multisrc from MAIN'||CHR(50);
                --dbms_output.put_line(gc_trcmsg);

                pkg_grp_load_difw.prc_recon(p_v_job_name_r,p_source_system,gn_batchid,lc_var_grp_difw_tgt_tbl_nm,lc_VAR_GRP_DIFW_SRC_TBL_NM);
                gc_trcmsg:=GC_TRCMSG||'10.Z Called tbl_rec_count_jobwise_multisrc from MAIN'||CHR(50);
                --dbms_output.put_line(gc_trcmsg);
            ELSE 

                pkg_grp_load_difw.get_multisrcsys_insert(p_v_job_name_r,p_source_system,lc_srctbl_where_clause,lc_src_sqlcmd_where_clause,lc_var_grp_difw_src_tbl_nm,lc_var_grp_difw_tgt_tbl_nm);
                gc_trcmsg:=gc_trcmsg||'7.z Called get_multisrcsys_merge  '||chr(13);
                dbms_output.put_line(gc_trcmsg);

                gc_trcmsg:=GC_TRCMSG||'8.0 Call get_recon_cnt from MAIN'||CHR(13);
                --dbms_output.put_line(gc_trcmsg);
               ln_recon_cnt:=pkg_grp_load_difw.get_singlesrc_recon_cnt (gn_batchid,p_source_system,lc_var_grp_difw_src_tbl_nm,lc_var_grp_difw_tgt_tbl_nm);
                GC_TRCMSG   :=GC_TRCMSG||'8.Z Call get_recon_cnt from MAIN ln_recon_cnt:'||ln_recon_cnt||CHR(13);

                IF ln_recon_cnt != 0 
                THEN
                    gc_errmsg      :=SUBSTR(SQLERRM,1,4000);
                    gc_trcmsg      :=gc_trcmsg||'3.z There is mismatch between Staging and Dimension table record counts , Please verify ' ||chr(13)||gc_errmsg;
                    pkg_grp_log_util.prc_update_log ( gn_out_job_id --p_job_id
                        ,gc_error_status                                --p_job_status
                        ,gc_errmsg                                      --p_err_msg
                        ,gc_trcmsg||chr(13)||gc_errmsg                  --p_trc_msg
                        ,gc_updby                                       --p_log_util_called_by_r
                    );
                    RAISE_APPLICATION_ERROR(-20000, 'There is mismatch between Staging and Dimension table record counts  for batch id :'||gn_batchid||', Please verify' );
                END IF;

                gc_trcmsg:=GC_TRCMSG||'9.0 Call tbl_rec_count_jobwise from MAIN'||CHR(50);
                --dbms_output.put_line(gc_trcmsg);
                dbms_output.put_line('TEST');
                pkg_grp_load_difw.tbl_rec_count_jobwise
                (p_v_job_name_r,p_source_system,gn_batchid,lc_VAR_GRP_DIFW_tgt_TBL_NM,lc_VAR_GRP_DIFW_SRC_TBL_NM);
                GC_TRCMSG:=GC_TRCMSG||'9.Z Called tbl_rec_count_jobwise from MAIN'||CHR(50);

            END IF;

            --Entry to prcs log after the succssful completion
            pkg_grp_log_util.prc_update_log
            (
                gn_out_job_id                   --p_job_id               
                ,gc_success_status              --p_job_status           
                ,gc_errmsg                      --p_err_msg              
                ,gc_trcmsg                      --p_trc_msg              
                ,gc_main_loadedby               --p_log_util_called_by_r 
            );
            gc_trcmsg := gc_trcmsg
            || '4.z Called procedure prc_update_log'
            || chr(13);

        ELSIF INSTR(gc_grp_sourcetype, 'MULTI')  > 0
        THEN
            gc_trcmsg:=GC_TRCMSG||'6.0 Call where_source_system from MAIN'||CHR(13);
            lc_srctbl_where_clause:=pkg_grp_load_difw.get_multisrcsys_where_source_system(lc_jobname);

            gc_trcmsg:=gc_trcmsg||'6.z Called where_source_system  MAIN :->where_source_system is :->'||lc_srctbl_where_clause||chr(13);
            --dbms_output.put_line(gc_trcmsg);

            gc_trcmsg:=GC_TRCMSG||'7.0 Call where_tgt_system from MAIN'||CHR(13);
            --dbms_output.put_line(gc_trcmsg);

            lc_tgttbl_where_clause:=pkg_grp_load_difw.get_multisrcsys_where_tgt_system(lc_jobname);

            gc_trcmsg:=gc_trcmsg||'7.z Called where_tgt_system  MAIN :->where_tgt_system is :->'||lc_tgttbl_where_clause||chr(13);
            --dbms_output.put_line(gc_trcmsg);

            gc_trcmsg:=GC_TRCMSG||'8.0 Call get_multisrcsys_merge from MAIN'||CHR(13);
            --dbms_output.put_line(gc_trcmsg);

            pkg_grp_load_difw.get_multisrcsys_merge (p_v_job_name_r,p_source_system,lc_srctbl_where_clause,lc_tgttbl_where_clause,lc_var_grp_difw_src_tbl_nm,lc_var_grp_difw_tgt_tbl_nm);
            gc_trcmsg:=gc_trcmsg||'8.z Called get_multisrcsys_merge  '||chr(13);
            --dbms_output.put_line(gc_trcmsg);

           GC_TRCMSG:=GC_TRCMSG||'9.0 Call get_recon_cnt from MAIN'||CHR(13);
            --dbms_output.put_line(gc_trcmsg);

            ln_recon_cnt:=pkg_grp_load_difw.get_recon_cnt (gn_batchid,p_source_system,lc_var_grp_difw_src_tbl_nm,lc_var_grp_difw_tgt_tbl_nm);

            GC_TRCMSG   :=GC_TRCMSG||'9.Z Call get_recon_cnt from MAIN ln_recon_cnt:'||ln_recon_cnt||CHR(13);
            --dbms_output.put_line(gc_trcmsg);
             --Check the recon count;
            IF ln_recon_cnt != 0 
                THEN
                    gc_errmsg      :=SUBSTR(SQLERRM,1,4000);
                    gc_trcmsg      :=gc_trcmsg||'9.z There is mismatch between Staging and Dimension table record counts , Please verify ' ||chr(13)||gc_errmsg;
                    pkg_grp_log_util.prc_update_log ( gn_out_job_id --p_job_id
                    ,gc_error_status                                --p_job_status
                    ,gc_errmsg                                      --p_err_msg
                    ,gc_trcmsg||chr(13)||gc_errmsg                  --p_trc_msg
                    ,gc_updby                                       --p_log_util_called_by_r
                    );
                    RAISE_APPLICATION_ERROR(-20000, 'There is mismatch between Staging and Dimension table record counts  for batch id :'||gn_batchid||', Please verify' );
            END IF;

			IF p_v_job_name_r NOT IN ('GRP_LOAD_FCT_CLAIM_PAYMENT_DETAIL_BENEFIT_PAYMENT_R',						    	  'GRP_LOAD_FCT_CLAIM_PAYMENT_DETAIL_GROSS_BENEFIT_R',
								'SHINKA_LOAD_FCT_CLAIM_PAYMENT_DETAIL_BENEFIT_PAYMENT_R','SHINKA_LOAD_FCT_CLAIM_PAYMENT_DETAIL_GROSS_BENEFIT_R')
			THEN

				gc_trcmsg:=GC_TRCMSG||'10.0 Call tbl_rec_count_jobwise_multisrc from MAIN'||CHR(50);
				--dbms_output.put_line(gc_trcmsg);

				pkg_grp_load_difw.prc_recon(p_v_job_name_r,p_source_system,gn_batchid,lc_var_grp_difw_tgt_tbl_nm,lc_VAR_GRP_DIFW_SRC_TBL_NM);
				--gc_trcmsg:=GC_TRCMSG||'10.Z Called tbl_rec_count_jobwise_multisrc from MAIN'||CHR(50);
			END IF;
            --pkg_grp_load_difw.tbl_rec_count_jobwise(p_v_job_name_r,p_source_system,gn_batchid,lc_VAR_GRP_DIFW_tgt_TBL_NM,lc_VAR_GRP_DIFW_SRC_TBL_NM);
            --dbms_output.put_line(gc_trcmsg);
            --Entry to prcs log after the succssful completion
            pkg_grp_log_util.prc_update_log ( gn_out_job_id --p_job_id
                ,gc_success_status                              --p_job_status
                ,gc_errmsg                                      --p_err_msg
                ,gc_trcmsg                                      --p_trc_msg
                ,gc_main_loadedby                               --p_log_util_called_by_r
            );
            gc_trcmsg := gc_trcmsg || '11.z Called procedure prc_update_log' || chr(13);
        ELSE
         --Inside else block check hanlding SINGLE SRC and Delete coniditons

            IF INSTR(gc_grp_sourcetype, 'SINGLE')  > 0
            THEN

                gc_trcmsg:=GC_TRCMSG||'6.0 Call get_singlesrcsys_merge1 from MAIN'||CHR(13);
                dbms_output.put_line(gc_trcmsg);
                --pkg_grp_load_difw.get_singlesrcsys_merge1(p_v_job_name_r,lc_VAR_GRP_DIFW_tgt_TBL_NM);
                gc_trcmsg:=gc_trcmsg||'7.z Called get_singlesrcsys_merge1  MAIN :->singlesrcsys_merge'||chr(13);

                pkg_grp_load_difw.get_singlesrcsys_merge1 (p_v_job_name_r,lc_VAR_GRP_DIFW_tgt_TBL_NM);
                gc_trcmsg:=gc_trcmsg||'7.z Called get_singlesrcsys_merge1  MAIN :->singlesrcsys_merge'||chr(13);
                dbms_output.put_line(gc_trcmsg);
            ELSIF INSTR(gc_grp_sourcetype, 'DELETE')  > 0
            THEN
                gc_trcmsg:=GC_TRCMSG||'6.0 Call get_delete_load from MAIN'||CHR(13);
                --dbms_output.put_line(gc_trcmsg);
                pkg_grp_load_difw.get_delete_load(p_v_job_name_r,lc_VAR_GRP_DIFW_tgt_TBL_NM);
                GC_TRCMSG:=GC_TRCMSG||'6.z Called get_delete_load from MAIN'||CHR(13);
                --dbms_output.put_line(gc_trcmsg);
            END IF;

			IF p_v_job_name_r NOT LIKE ('%DIM_GRP_POLICY_DIR_R%')
			THEN
				gc_trcmsg:=GC_TRCMSG||'7.0 Call get_singlesrc_recon_cnt from MAIN'||CHR(13);
				--dbms_output.put_line(gc_trcmsg);

				ln_recon_cnt:=pkg_grp_load_difw.get_singlesrc_recon_cnt (gn_batchid,p_source_system,lc_var_grp_difw_src_tbl_nm,lc_var_grp_difw_tgt_tbl_nm);

				GC_TRCMSG   :=GC_TRCMSG||'7.Z Call get_recon_cnt from MAIN ln_recon_cnt:'||ln_recon_cnt||CHR(13);
				--dbms_output.put_line(gc_trcmsg);

				IF ln_recon_cnt != 0 
				THEN
					gc_errmsg      :=SUBSTR(SQLERRM,1,4000);
					gc_trcmsg      :=gc_trcmsg||'8.z There is mismatch between Staging and Dimension table record counts , Please verify ' ||chr(13)||gc_errmsg;
					pkg_grp_log_util.prc_update_log ( gn_out_job_id --p_job_id
					,gc_error_status                                --p_job_status
					,gc_errmsg                                      --p_err_msg
					,gc_trcmsg||chr(13)||gc_errmsg                  --p_trc_msg
					,gc_updby                                       --p_log_util_called_by_r
					);
					RAISE_APPLICATION_ERROR(-20000, 'There is mismatch between Staging and Dimension table record counts  for batch id :'||gn_batchid||', Please verify' );
				END IF;
			END IF;
            gc_trcmsg:=GC_TRCMSG||'8.0 Call tbl_rec_count_jobwise from MAIN'||CHR(50);
            --dbms_output.put_line(gc_trcmsg);
            dbms_output.put_line('TEST');
            pkg_grp_load_difw.tbl_rec_count_jobwise
            (p_v_job_name_r,p_source_system,gn_batchid,lc_VAR_GRP_DIFW_tgt_TBL_NM,lc_VAR_GRP_DIFW_SRC_TBL_NM);
            GC_TRCMSG:=GC_TRCMSG||'8.Z Called tbl_rec_count_jobwise from MAIN'||CHR(50);
            --dbms_output.put_line(gc_trcmsg);
            --Entry to prcs log after the succssful completion
            pkg_grp_log_util.prc_update_log
            (
                gn_out_job_id                   --p_job_id               
                ,gc_success_status              --p_job_status           
                ,gc_errmsg                      --p_err_msg              
                ,gc_trcmsg                      --p_trc_msg              
                ,gc_main_loadedby               --p_log_util_called_by_r 
            );
            gc_trcmsg := gc_trcmsg
            || '4.z Called procedure prc_update_log'
            || chr(13);

        END IF;
        EXCEPTION
        WHEN OTHERS THEN
            gc_errmsg:=SUBSTR(SQLERRM,1,4000);
            gc_trcmsg:=gc_trcmsg||'Error in MAIN PROC'||chr(13)||gc_errmsg;
            pkg_grp_log_util.prc_update_log
              (
                gn_out_job_id                 --p_job_id
                ,gc_error_status              --p_job_status
                ,gc_errmsg                    --p_err_msg
                ,gc_trcmsg||chr(13)||gc_errmsg--p_trc_msg
                ,gc_updby                     --p_log_util_called_by_r
              );
            RAISE;

    END MAIN;
-----BEGIN MULTI FUCNTIONS & PROCS------
----Function to get the Source where clause
FUNCTION get_multisrcsys_where_source_system(p_job_name IN VARCHAR2) RETURN VARCHAR2
IS
  lc_char VARCHAR2(4000);
BEGIN
  gc_trcmsg:=gc_trcmsg||'4.1 Entered into get_multisrcsys_where_source_system'||chr(13);
  gc_updby:= 'get_multisrcsys_where_source_system';
  SELECT   V_WHERE_SOURCE_SYSTEM_R 

  INTO lc_char
  FROM ATOMIC.PRCS_GRP_DATAINGESTION_PARAM_R
  WHERE F_ENABLE_FLAG_R        ='Y'
  AND NVL(V_PARAM_NAME_R,'@~') = p_job_name;
  gc_trcmsg:=gc_trcmsg||'4.z Exit from get_multisrcsys_where_source_system'||chr(13);
  RETURN lc_char;
EXCEPTION
WHEN OTHERS THEN
  gc_errmsg:=SUBSTR(SQLERRM,1,4000);
  gc_trcmsg:=gc_trcmsg||'4.z Error in get_multisrcsys_where_source_system'||chr(13)||gc_errmsg;
  pkg_grp_log_util.prc_update_log ( gn_out_job_id --p_job_id
  ,gc_error_status                                --p_job_status
  ,gc_errmsg                                      --p_err_msg
  ,gc_trcmsg||chr(13)||gc_errmsg                  --p_trc_msg
  ,gc_updby                                       --p_log_util_called_by_r
  );
  RAISE;
END get_multisrcsys_where_source_system;
----Function to get the target where clause
  FUNCTION get_multisrcsys_where_tgt_system(
      p_job_name IN VARCHAR2)
    RETURN VARCHAR2
IS
  lc_char VARCHAR2(4000);
BEGIN
  gc_trcmsg:=gc_trcmsg||'5.1 Entered into get_multisrcsys_where_tgt_system'||chr(13);
    gc_updby:=  'get_multisrcsys_where_tgt_system';
  SELECT V_TGT_TBL_WHERE_CLAUSE_R 

  INTO lc_char
  FROM ATOMIC.PRCS_GRP_DATAINGESTION_PARAM_R
  WHERE F_ENABLE_FLAG_R        ='Y'
  AND NVL(V_PARAM_NAME_R,'@~') = p_job_name;
  gc_trcmsg:=gc_trcmsg||'5.z Exit from get_multisrcsys_where_tgt_system'||chr(13);
  RETURN lc_char;
EXCEPTION
WHEN OTHERS THEN
  gc_errmsg:=SUBSTR(SQLERRM,1,4000);
  gc_trcmsg:=gc_trcmsg||'5.z Error in get_multisrcsys_where_tgt_system'||chr(13)||gc_errmsg;
  pkg_grp_log_util.prc_update_log ( gn_out_job_id --p_job_id
  ,gc_error_status                                --p_job_status
  ,gc_errmsg                                      --p_err_msg
  ,gc_trcmsg||chr(13)||gc_errmsg                  --p_trc_msg
  ,gc_updby                                       --p_log_util_called_by_r
  );
  RAISE;
END get_multisrcsys_where_tgt_system;

--Function to get the get_source_sql_cmd
FUNCTION get_source_sql_cmd(
      p_job_name IN VARCHAR2)
    RETURN VARCHAR2
IS
  lc_char VARCHAR2(4000);
BEGIN
  gc_trcmsg:=gc_trcmsg||'5.1 Entered into get_source_sql_cmd'||chr(13);
   gc_updby:=  'get_source_sql_cmd';
  SELECT  v_source_sql_cmd_r
    INTO lc_char
  FROM ATOMIC.PRCS_GRP_DATAINGESTION_PARAM_R
  WHERE F_ENABLE_FLAG_R        ='Y'
  AND NVL(V_PARAM_NAME_R,'@~') = p_job_name;
  gc_trcmsg:=gc_trcmsg||'5.z Exit from get_source_sql_cmd'||chr(13);
  RETURN lc_char;
EXCEPTION
WHEN OTHERS THEN
  gc_errmsg:=SUBSTR(SQLERRM,1,4000);
  gc_trcmsg:=gc_trcmsg||'5.z Error in get_source_sql_cmd'||chr(13)||gc_errmsg;
  pkg_grp_log_util.prc_update_log ( gn_out_job_id --p_job_id
  ,gc_error_status                                --p_job_status
  ,gc_errmsg                                      --p_err_msg
  ,gc_trcmsg||chr(13)||gc_errmsg                  --p_trc_msg
  ,gc_updby                                       --p_log_util_called_by_r
  );
  RAISE;
END get_source_sql_cmd;


--Function to get the multi source  source table name
 FUNCTION get_src_table_name(
      p_job_name  IN VARCHAR2 )
    RETURN VARCHAR2
IS
  lc_char VARCHAR2(4000);

BEGIN

  gc_trcmsg:=gc_trcmsg||'6.1 Entered into get_src_table_name'||chr(13);
   gc_updby:=  'get_src_table_name';
  SELECT REGEXP_SUBSTR(V_PARAM_VALUE_R, '[^~ ]+', 1, 1)
  INTO lc_char
  FROM ATOMIC.PRCS_GRP_DATAINGESTION_PARAM_R
  WHERE F_ENABLE_FLAG_R        ='Y'
  AND NVL(V_PARAM_NAME_R,'@~') = p_job_name;
  gc_trcmsg:=gc_trcmsg||'6.z Exit from get_src_table_name'||chr(13);
  RETURN lc_char;
EXCEPTION
WHEN OTHERS THEN
  gc_errmsg:=SUBSTR(SQLERRM,1,4000);
  gc_trcmsg:=gc_trcmsg||'2.z Error in get_src_table_name'||chr(13)||gc_errmsg;
  pkg_grp_log_util.prc_update_log ( gn_out_job_id --p_job_id
  ,gc_error_status                                --p_job_status
  ,gc_errmsg                                      --p_err_msg
  ,gc_trcmsg||chr(13)||gc_errmsg                  --p_trc_msg
  ,gc_updby                                       --p_log_util_called_by_r
  );
  RAISE;
END get_src_table_name;
--Function to get the multi source  target table name
  FUNCTION get_tgt_table_name(
      p_job_name  IN VARCHAR2)
    RETURN VARCHAR2
IS
  lc_char VARCHAR2(4000);

BEGIN
  gc_trcmsg:=gc_trcmsg||'7.1 Entered into get_tgt_table_name'||chr(13);
   gc_updby:=  'get_tgt_table_name';
  SELECT REGEXP_SUBSTR(V_PARAM_VALUE_R, '[^~ ]+', 1, 2)
  INTO lc_char
  FROM ATOMIC.PRCS_GRP_DATAINGESTION_PARAM_R
  WHERE F_ENABLE_FLAG_R        ='Y'
  AND NVL(V_PARAM_NAME_R,'@~') = p_job_name;
  RETURN lc_char;
EXCEPTION
WHEN OTHERS THEN
  gc_errmsg:=SUBSTR(SQLERRM,1,4000);
  gc_trcmsg:=gc_trcmsg||'2.z Error in get_tgt_table_name'||chr(13)||gc_errmsg;
  pkg_grp_log_util.prc_update_log ( gn_out_job_id --p_job_id
  ,gc_error_status                                --p_job_status
  ,gc_errmsg                                      --p_err_msg
  ,gc_trcmsg||chr(13)||gc_errmsg                  --p_trc_msg
  ,gc_updby                                       --p_log_util_called_by_r
  );
  RAISE;
END get_tgt_table_name;
PROCEDURE get_multisrcsys_merge(
    p_v_job_name_r        IN VARCHAR2,
    p_source_system       IN VARCHAR2,
    p_srctbl_where_clause IN VARCHAR2,
    p_tgttbl_where_clause IN VARCHAR2,
    p_src_tbl_name        IN VARCHAR2,
    p_tgt_tbl_name        IN VARCHAR2)
IS
  lc_merge1 CLOB;
  lc_merge2 CLOB;
  lc_merge3 CLOB;
  lc_merge4 CLOB;
  lc_merge_final CLOB;
  ln_row_cnt NUMBER;
BEGIN
 gc_updby:=  'get_multisrcsys_merge';
  SELECT V_ADD_ON_MERGE1_R
  INTO lc_merge1
  FROM ATOMIC.PRCS_GRP_DATAINGESTION_PARAM_R
  WHERE V_PARAM_NAME_R = p_source_system
    ||'_'
    ||p_v_job_name_r;
  dbms_output.put_line('lc_merge1 :->'||lc_merge1);

  SELECT V_ADD_ON_MERGE2_R
  INTO lc_merge2
  FROM ATOMIC.PRCS_GRP_DATAINGESTION_PARAM_R
  WHERE V_PARAM_NAME_R = p_source_system
    ||'_'
    ||p_v_job_name_r;
  dbms_output.put_line('lc_merge2 :->'||lc_merge2);

  SELECT V_ADD_ON_MERGE3_R
  INTO lc_merge3
  FROM ATOMIC.PRCS_GRP_DATAINGESTION_PARAM_R
  WHERE V_PARAM_NAME_R = p_source_system
    ||'_'
    ||p_v_job_name_r;
  dbms_output.put_line('lc_merge3 :->'||lc_merge3);
    IF INSTR(gc_grp_sourcetype, 'DIM')  > 0
    THEN
      SELECT REPLACE('INSERT '
        ||INS
        ||CHR(10)
        ||'VALUES '
        ||VAL,',)',')')
      INTO lc_merge4
      FROM
        (SELECT '('
          ||TRIM((XMLAGG(XMLELEMENT(A,'D.'
          ||COLUMN_NAME
          ||',')
        ORDER BY COLUMN_ID).EXTRACT('//text()')).getclobval())
          ||gc_auditcols_DIM
          ||')' INS,
          '('
          ||TRIM((XMLAGG(XMLELEMENT(A,'S.'
          ||COLUMN_NAME
          ||',')
        ORDER BY COLUMN_ID).EXTRACT('//text()')).getclobval())
          ||gc_auditcol_values_DIM
          ||')' VAL
        FROM ALL_TAB_COLUMNS
        WHERE TABLE_NAME     = p_tgt_tbl_name
        AND owner            ='ATOMIC'
        AND COLUMN_NAME NOT IN ('T_CREATION_DATE_R','V_CREATED_BY_R','T_LAST_MODIFIED_DATE_R','V_LAST_MODIFIED_BY_R','N_LOAD_RUN_ID_R','N_SEQUENCE_NUMBER_R')
        );
    ELSE
         SELECT REPLACE('INSERT '
        ||INS
        ||CHR(10)
        ||'VALUES '
        ||VAL,',)',')')
      INTO lc_merge4
      FROM
        (SELECT '('
          ||TRIM((XMLAGG(XMLELEMENT(A,'D.'
          ||COLUMN_NAME
          ||',')
        ORDER BY COLUMN_ID).EXTRACT('//text()')).getclobval())
          ||gc_auditcols_FACT
          ||')' INS,
          '('
          ||TRIM((XMLAGG(XMLELEMENT(A,'S.'
          ||COLUMN_NAME
          ||',')
        ORDER BY COLUMN_ID).EXTRACT('//text()')).getclobval())
          ||gc_auditcol_values_FACT
          ||')' VAL
        FROM ALL_TAB_COLUMNS
        WHERE TABLE_NAME     = p_tgt_tbl_name
        AND owner            ='ATOMIC'
        AND COLUMN_NAME NOT IN ('T_CREATION_DATE_R','V_CREATED_BY_R','T_LAST_MODIFIED_DATE_R','V_LAST_MODIFIED_BY_R','N_LOAD_RUN_ID_R')
        );
    END IF;
      dbms_output.put_line('lc_merge4 :->'||lc_merge4);

	  -- Start of changes as part of Project crown for user story 514594
      DBMS_OUTPUT.ENABLE(buffer_size => NULL); -- To avoid buffer overflow limit for print statments (08/05/2026) 
	  -- End of changes as pat of Project crown for user story 514594


  lc_merge_final :=lc_merge1||' '|| p_srctbl_where_clause||''''|| p_source_system ||''''||lc_merge2||' ' ||lc_merge3||' '||lc_merge4;

  dbms_output.put_line('lc_merge_final :->'||lc_merge_final);

  EXECUTE IMMEDIATE lc_merge_final;
  COMMIT;
  -- Get the number of rows affected
  ln_row_cnt := SQL%ROWCOUNT;
  -- Output the number of rows affected
  DBMS_OUTPUT.PUT_LINE('Number of rows affected: ' || ln_row_cnt);
  --Exception is missing - valni will update
    EXCEPTION
    WHEN OTHERS THEN
    gc_errmsg:=SUBSTR(SQLERRM,1,4000);
    gc_trcmsg:=gc_trcmsg||'9.z Error in get_multisrcsys_merge'||chr(13)||gc_errmsg;
    pkg_grp_log_util.prc_update_log ( gn_out_job_id --p_job_id
    ,gc_error_status                                --p_job_status
    ,gc_errmsg                                      --p_err_msg
    ,gc_trcmsg||chr(13)||gc_errmsg                  --p_trc_msg
    ,gc_updby                                       --p_log_util_called_by_r
    );
    RAISE;
END get_multisrcsys_merge;
  FUNCTION get_recon_cnt(
      gn_batchid      IN NUMBER,
      p_source_system IN VARCHAR2,
      p_src_tbl_name  IN VARCHAR2,
      p_tgt_tbl_name  IN VARCHAR2
	 )
 RETURN NUMBER
IS
  ln_num NUMBER;
BEGIN
  gc_trcmsg:=gc_trcmsg||'9.1 Entered into get_recon_cnt'||chr(13);
   gc_updby:=  'get_recon_cnt';
 IF p_tgt_tbl_name = 'FCT_POLICY_COMMISSION_DETAILS' THEN
    EXECUTE IMMEDIATE '
      SELECT COUNT(1) FROM    
      (     
        SELECT COUNT(1) REC_CNT     
        FROM ATOMIC."' || p_src_tbl_name || '"     
        WHERE N_BATCH_ID_R = :batch_id         
        AND  V_DATA_SOURCE_CODE = :source_system     
        MINUS     
        SELECT COUNT(1) REC_CNT     
        FROM "' || p_tgt_tbl_name || '"     
        WHERE N_BATCH_ID_R = :batch_id     
        AND  V_DATA_SOURCE_CODE = :source_system    
      )'
    INTO ln_num
    USING gn_batchid, p_source_system, gn_batchid, p_source_system;
  ELSE
    EXECUTE IMMEDIATE '
      SELECT COUNT(1) FROM    
      (     
        SELECT COUNT(1) REC_CNT     
        FROM ATOMIC."' || p_src_tbl_name || '"     
        WHERE N_BATCH_ID_R = :batch_id         
        AND V_SOURCE_SYSTEM_NAME_R = :source_system     
        MINUS     
        SELECT COUNT(1) REC_CNT     
        FROM "' || p_tgt_tbl_name || '"     
        WHERE N_BATCH_ID_R = :batch_id     
        AND V_SOURCE_SYSTEM_NAME_R = :source_system    
      )'
    INTO ln_num
    USING gn_batchid, p_source_system, gn_batchid, p_source_system;
  END IF;    
  -- Output the result
  DBMS_OUTPUT.PUT_LINE('Number of records: ' || ln_num);
  gc_trcmsg:=gc_trcmsg||'9.z Exit from get_recon_cnt'||chr(13);
  RETURN ln_num;
EXCEPTION
WHEN OTHERS THEN
  gc_errmsg:=SUBSTR(SQLERRM,1,4000);
  gc_trcmsg:=gc_trcmsg||'9.z Error in get_recon_cnt'||chr(13)||gc_errmsg;
  pkg_grp_log_util.prc_update_log ( gn_out_job_id --p_job_id
  ,gc_error_status                                --p_job_status
  ,gc_errmsg                                      --p_err_msg
  ,gc_trcmsg||chr(13)||gc_errmsg                  --p_trc_msg
  ,gc_updby                                       --p_log_util_called_by_r
  );
  RAISE;
END get_recon_cnt;
PROCEDURE prc_recon(
    p_v_job_name_r            IN VARCHAR2,
    p_source_system           IN VARCHAR2,
    p_batchid                 IN NUMBER,
    P_VAR_GRP_DIFW_tgt_TBL_NM IN VARCHAR2,
    P_VAR_GRP_DIFW_SRC_TBL_NM IN VARCHAR2)
IS
  lc_char                              VARCHAR2(4000);
  ln_VAR_GRP_EDW_LOAD_RUN_ID_R         NUMBER;
  lc_VAR_GRP_DEBUG_FLAG_R              VARCHAR2(4000);
  lc_VAR_GRP_ET_SRC_TABLE_NM           VARCHAR2(4000);
  lc_V_JOB_NAME_R                      VARCHAR2(4000);
  lc_V_ET_TABLE_NAME_R                 VARCHAR2(4000);
  lc_V_EDW_TABLE_NAME_R                VARCHAR2(4000);
  lc_V_SELECT_QUERY_R                  CLOB;
  lc_V_WHERE_SOURCE_SYSTEM_R           VARCHAR2(4000);
  lc_V_GROUP_BY_R                      VARCHAR2(4000);
  lc_V_SOURCE_SYSTEM_R                 VARCHAR2(4000);
  lc_V_PARENT_SOURCE_SYSTEM_R          VARCHAR2(4000);
  lc_V_SRCTBL_PARALLEL_DEGREE_R        VARCHAR2(4000);
  lc_V_LOAD_TYPE_R                     VARCHAR2(4000);
  lc_V_LATEST_ADW_RUNAUDIT_R           VARCHAR2(4000);
  LN_PRCS_GRP_EDW_TBL_RECCNT_QUERIES_R NUMBER;
  LC_OUT_LOAD_STATUS                   VARCHAR2(4000);
  LC_VAR_GRP_DIFW_tgt_TBL_NM           VARCHAR2(4000):=P_VAR_GRP_DIFW_tgt_TBL_NM;
  lc_VAR_GRP_DIFW_SRC_TBL_NM           VARCHAR2(4000):=p_VAR_GRP_DIFW_SRC_TBL_NM;
  LC_V_SRC_SYSTEM_NM                   VARCHAR2(4000);
BEGIN
  gc_trcmsg:=gc_trcmsg||'10.1 Entered into prc_recon'||chr(13);
   gc_updby:=  'prc_recon';
  --dbms_output.put_line(gc_trcmsg);
  SELECT TO_NUMBER(TO_CHAR(SYSDATE,'YYYYMMDD'))
  INTO ln_VAR_GRP_EDW_LOAD_RUN_ID_R
  FROM DUAL;
  gc_trcmsg:='10.2 Print ln_VAR_GRP_EDW_LOAD_RUN_ID_R:'||ln_VAR_GRP_EDW_LOAD_RUN_ID_R||chr(13);
  --dbms_output.put_line(gc_trcmsg);
  --getting the lc_VAR_GRP_DEBUG_FLAG_R value
  SELECT NVL(V_DEBUG_FLAG_R,'N')
  INTO lc_VAR_GRP_DEBUG_FLAG_R
  FROM ATOMIC.prcs_grp_dataingestion_param_r
  WHERE F_ENABLE_FLAG_R        ='Y'
  AND NVL(V_PARAM_NAME_R,'@~') = p_source_system
    ||'_'
    ||p_v_job_name_r;
  gc_trcmsg:='10.3 Print lc_VAR_GRP_DEBUG_FLAG_R:'||lc_VAR_GRP_DEBUG_FLAG_R||chr(13);
  --dbms_output.put_line(gc_trcmsg);
  SELECT V_ET_TABLE_NAME_R
  INTO lc_VAR_GRP_ET_SRC_TABLE_NM
  FROM ATOMIC.prcs_grp_dataingestion_param_r
  WHERE F_ENABLE_FLAG_R         ='Y'
  AND V_TBL_REC_CNT_RECON_FLAG_R='Y'
  AND NVL(V_PARAM_NAME_R,'@~')  = p_source_system
    ||'_'
    ||p_v_job_name_r
  GROUP BY V_ET_TABLE_NAME_R;
  gc_trcmsg:='10.4 Print lc_VAR_GRP_ET_SRC_TABLE_NM:'||lc_VAR_GRP_ET_SRC_TABLE_NM||chr(13);
  --dbms_output.put_line(gc_trcmsg);
  gc_trcmsg:='10.5 performing delete PRCS_GRP_EDW_TBL_RECCNT_QUERIES_R'||chr(13);
  --dbms_output.put_line(gc_trcmsg);
  DELETE
  FROM ATOMIC.PRCS_GRP_EDW_TBL_RECCNT_QUERIES_R
  WHERE V_PARENT_SOURCE_SYSTEM_R= CASE WHEN p_source_system='STACS' THEN 'GEN_REF' ELSE p_source_system END
  AND v_edw_table_name_r        = lc_VAR_GRP_DIFW_tgt_TBL_NM;
  COMMIT;
  gc_trcmsg:='10.6 SELECT TO V_COLUMNS'||p_source_system||lc_VAR_GRP_DIFW_tgt_TBL_NM||chr(13);
  --dbms_output.put_line(gc_trcmsg);
  SELECT V_JOB_NAME_R,
    V_ET_TABLE_NAME_R,
    V_EDW_TABLE_NAME_R,
    V_SELECT_QUERY_R,
    V_WHERE_SOURCE_SYSTEM_R,
    V_GROUP_BY_R,
    V_SOURCE_SYSTEM_R,
    V_PARENT_SOURCE_SYSTEM_R,
    V_SRCTBL_PARALLEL_DEGREE_R,
    V_LOAD_TYPE_R,
    V_LATEST_ADW_RUNAUDIT_R
  INTO LC_V_JOB_NAME_R,
    LC_V_ET_TABLE_NAME_R,
    LC_V_EDW_TABLE_NAME_R,
    LC_V_SELECT_QUERY_R,
    LC_V_WHERE_SOURCE_SYSTEM_R,
    LC_V_GROUP_BY_R,
    LC_V_SOURCE_SYSTEM_R,
    LC_V_PARENT_SOURCE_SYSTEM_R,
    LC_V_SRCTBL_PARALLEL_DEGREE_R,
    LC_V_LOAD_TYPE_R,
    LC_V_LATEST_ADW_RUNAUDIT_R
  FROM
    (SELECT V_JOB_NAME_R,
      V_ET_TABLE_NAME_R,
      V_EDW_TABLE_NAME_R,
      V_SELECT_QUERY_R,
      V_WHERE_SOURCE_SYSTEM_R,
      V_GROUP_BY_R,
      V_SOURCE_SYSTEM_R,
      V_PARENT_SOURCE_SYSTEM_R,
      V_SRCTBL_PARALLEL_DEGREE_R,
      V_LOAD_TYPE_R,
      V_LATEST_ADW_RUNAUDIT_R
    FROM ATOMIC.VW_PRCS_GRP_TPA_EDW_TBL_RECCNT_QUERIES_R
    WHERE V_PARENT_SOURCE_SYSTEM_R=p_source_system
    AND v_edw_table_name_r        =lc_VAR_GRP_DIFW_tgt_TBL_NM
    UNION
    SELECT V_JOB_NAME_R,
      V_ET_TABLE_NAME_R,
      V_EDW_TABLE_NAME_R,
      V_SELECT_QUERY_R,
      V_WHERE_SOURCE_SYSTEM_R,
      V_GROUP_BY_R,
      V_SOURCE_SYSTEM_R,
      V_PARENT_SOURCE_SYSTEM_R,
      V_SRCTBL_PARALLEL_DEGREE_R,
      V_LOAD_TYPE_R,
      V_LATEST_ADW_RUNAUDIT_R
    FROM ATOMIC.VW_PRCS_GRP_APS_EDW_TBL_RECCNT_QUERIES_R
    WHERE V_PARENT_SOURCE_SYSTEM_R=p_source_system
    AND v_edw_table_name_r        =lc_VAR_GRP_DIFW_tgt_TBL_NM
    UNION
    SELECT V_JOB_NAME_R,
      V_ET_TABLE_NAME_R,
      V_EDW_TABLE_NAME_R,
      V_SELECT_QUERY_R,
      V_WHERE_SOURCE_SYSTEM_R,
      V_GROUP_BY_R,
      V_SOURCE_SYSTEM_R,
      V_PARENT_SOURCE_SYSTEM_R,
      V_SRCTBL_PARALLEL_DEGREE_R,
      V_LOAD_TYPE_R,
      V_LATEST_ADW_RUNAUDIT_R
    FROM ATOMIC.VW_PRCS_GRP_VUE_EDW_TBL_RECCNT_QUERIES_R
    WHERE V_PARENT_SOURCE_SYSTEM_R=p_source_system
    AND v_edw_table_name_r        =lc_VAR_GRP_DIFW_tgt_TBL_NM
    UNION
    SELECT V_JOB_NAME_R,
      V_ET_TABLE_NAME_R,
      V_EDW_TABLE_NAME_R,
      V_SELECT_QUERY_R,
      V_WHERE_SOURCE_SYSTEM_R,
      V_GROUP_BY_R,
      V_SOURCE_SYSTEM_R,
      V_PARENT_SOURCE_SYSTEM_R,
      V_SRCTBL_PARALLEL_DEGREE_R,
      V_LOAD_TYPE_R,
      V_LATEST_ADW_RUNAUDIT_R
    FROM ATOMIC.VW_PRCS_GRP_PACS_EDW_TBL_RECCNT_QUERIES_R
    WHERE V_PARENT_SOURCE_SYSTEM_R=p_source_system
    AND v_edw_table_name_r        =lc_VAR_GRP_DIFW_tgt_TBL_NM
    UNION
    SELECT V_JOB_NAME_R,
      V_ET_TABLE_NAME_R,
      V_EDW_TABLE_NAME_R,
      V_SELECT_QUERY_R,
      V_WHERE_SOURCE_SYSTEM_R,
      V_GROUP_BY_R,
      V_SOURCE_SYSTEM_R,
      V_PARENT_SOURCE_SYSTEM_R,
      V_SRCTBL_PARALLEL_DEGREE_R,
      V_LOAD_TYPE_R,
      V_LATEST_ADW_RUNAUDIT_R
    FROM ATOMIC.VW_PRCS_GRP_GEN_REF_EDW_TBL_RECCNT_QUERIES_R
    WHERE V_PARENT_SOURCE_SYSTEM_R= CASE WHEN p_source_system='STACS' THEN 'GEN_REF' ELSE p_source_system END
    AND v_edw_table_name_r        =lc_VAR_GRP_DIFW_tgt_TBL_NM
    UNION
    SELECT 
        V_JOB_NAME_R,
        V_ET_TABLE_NAME_R,
        V_EDW_TABLE_NAME_R,
        V_SELECT_QUERY_R,
        V_WHERE_SOURCE_SYSTEM_R,
        V_GROUP_BY_R,
        V_SOURCE_SYSTEM_R,
        V_PARENT_SOURCE_SYSTEM_R,
        V_SRCTBL_PARALLEL_DEGREE_R,
        V_LOAD_TYPE_R,
        V_LATEST_ADW_RUNAUDIT_R 
    FROM ATOMIC.VW_PRCS_SHINKA_EIS_EDW_TBL_RECCNT_QUERIES_R
    WHERE V_PARENT_SOURCE_SYSTEM_R=p_source_system
    AND v_edw_table_name_r        =lc_VAR_GRP_DIFW_tgt_TBL_NM
    UNION
    SELECT V_JOB_NAME_R,
        V_ET_TABLE_NAME_R,
        V_EDW_TABLE_NAME_R,
        V_SELECT_QUERY_R,
        V_WHERE_SOURCE_SYSTEM_R,
        V_GROUP_BY_R,
        V_SOURCE_SYSTEM_R,
        V_PARENT_SOURCE_SYSTEM_R,
        V_SRCTBL_PARALLEL_DEGREE_R,
        V_LOAD_TYPE_R,
        V_LATEST_ADW_RUNAUDIT_R 
    FROM  ATOMIC.VW_PRCS_SHINKA_CV_EDW_TBL_RECCNT_QUERIES_R  
    WHERE V_PARENT_SOURCE_SYSTEM_R=p_source_system
    AND v_edw_table_name_r=lc_VAR_GRP_DIFW_tgt_TBL_NM
    );
  gc_trcmsg:='10.7 INSERT IN TO PRCS_GRP_EDW_TBL_RECCNT_QUERIES_R'||chr(13);
  --dbms_output.put_line(gc_trcmsg);
  INSERT
  INTO ATOMIC.PRCS_GRP_EDW_TBL_RECCNT_QUERIES_R
    (
      V_JOB_NAME_R ,
      V_ET_TABLE_NAME_R ,
      V_EDW_TABLE_NAME_R ,
      V_SELECT_QUERY_R ,
      V_WHERE_SOURCE_SYSTEM_R ,
      V_GROUP_BY_R ,
      V_SOURCE_SYSTEM_R ,
      V_PARENT_SOURCE_SYSTEM_R ,
      N_LOAD_RUN_ID_R ,
      V_SRCTBL_PARALLEL_DEGREE_R ,
      V_LOAD_TYPE_R ,
      V_ETLID_N_BATCH_ID_R ,
      V_LATEST_ADW_RUNAUDIT_R,
      V_COLLECT_RECCNT_R
    )
    VALUES
    (
      LC_V_JOB_NAME_R ,
      LC_V_ET_TABLE_NAME_R ,
      LC_V_EDW_TABLE_NAME_R ,
      LC_V_SELECT_QUERY_R ,
      LC_V_WHERE_SOURCE_SYSTEM_R ,
      LC_V_GROUP_BY_R ,
      LC_V_SOURCE_SYSTEM_R ,
      LC_V_PARENT_SOURCE_SYSTEM_R ,
      ln_VAR_GRP_EDW_LOAD_RUN_ID_R ,
      LC_V_SRCTBL_PARALLEL_DEGREE_R ,
      LC_V_LOAD_TYPE_R ,
      p_batchid ,
      LC_V_LATEST_ADW_RUNAUDIT_R,
      'JOBWISE'
    );
  COMMIT;
  SELECT COUNT(1)
  INTO LN_PRCS_GRP_EDW_TBL_RECCNT_QUERIES_R
  FROM ATOMIC.PRCS_GRP_EDW_TBL_RECCNT_QUERIES_R
  WHERE V_PARENT_SOURCE_SYSTEM_R=p_source_system
  AND v_edw_table_name_r        = lc_VAR_GRP_DIFW_tgt_TBL_NM;
  gc_trcmsg                    :='10.8  select count from PRCS_GRP_EDW_TBL_RECCNT_QUERIES_R LN_PRCS_GRP_EDW_TBL_RECCNT_QUERIES_R' ||LN_PRCS_GRP_EDW_TBL_RECCNT_QUERIES_R||chr(13);
  --dbms_output.put_line(gc_trcmsg);
  IF LN_PRCS_GRP_EDW_TBL_RECCNT_QUERIES_R > 1 THEN
    gc_errmsg                            :=SUBSTR(SQLERRM,1,4000);
    gc_trcmsg                            :=gc_trcmsg||'10.9 More than one entry detected in PRCS_GRP_EDW_TBL_RECCNT_QUERIES_R and hence terminating ' || LN_PRCS_GRP_EDW_TBL_RECCNT_QUERIES_R||chr(13)||gc_errmsg;
    pkg_grp_log_util.prc_update_log ( gn_out_job_id --p_job_id
    ,gc_error_status                                --p_job_status
    ,gc_errmsg                                      --p_err_msg
    ,gc_trcmsg||chr(13)||gc_errmsg                  --p_trc_msg
    ,gc_updby                                       --p_log_util_called_by_r
    );
    RAISE_APPLICATION_ERROR(-20000, '9.10 More than one entry detected in PRCS_GRP_EDW_TBL_RECCNT_QUERIES_R and hence terminating' || LN_PRCS_GRP_EDW_TBL_RECCNT_QUERIES_R);
  END IF;
  gc_trcmsg:='9.11 Calling the procedure PKG_GRP_LOAD_STATS_EDW_JOBWISE.PRCS_GRP_LOAD_STATS_EDW_JOBWISE'||chr(13);
  --dbms_output.put_line(gc_trcmsg);
  LC_V_SRC_SYSTEM_NM := CASE WHEN p_source_system='STACS' THEN 'GEN_REF' ELSE p_source_system END;

  ATOMIC.PKG_GRP_LOAD_STATS_EDW_JOBWISE.PRCS_GRP_LOAD_STATS_EDW_JOBWISE (p_batchid,ln_VAR_GRP_EDW_LOAD_RUN_ID_R,LC_V_SRC_SYSTEM_NM,LC_VAR_GRP_DIFW_tgt_TBL_NM,lc_VAR_GRP_ET_SRC_TABLE_NM,LC_OUT_LOAD_STATUS);
  IF LC_OUT_LOAD_STATUS <>'SUCCESS' THEN
    raise_application_error(-20001, ' Load '||p_v_job_name_r|| ' PKG_GRP_LOAD_STATS_EDW.PRCS_GRP_LOAD_STATS_EDW_JOBWISE has been failed against the Batch ID ' ||p_batchid|| ' with the error :->' || LC_OUT_LOAD_STATUS);
  END IF;
  --Do we need this exception here?
  --exception
  --when others then
  --raise_application_error(-20001,'Error Occured in the ODI Procedure  :->'||SQLERRM);
  --END;
EXCEPTION
WHEN OTHERS THEN
  gc_errmsg:=SUBSTR(SQLERRM,1,4000);
  gc_trcmsg:=gc_trcmsg||'9.12 Error in prc_recon'||chr(13)||gc_errmsg;
  pkg_grp_log_util.prc_update_log ( gn_out_job_id --p_job_id
  ,gc_error_status                                --p_job_status
  ,gc_errmsg                                      --p_err_msg
  ,gc_trcmsg||chr(13)||gc_errmsg                  --p_trc_msg
  ,gc_updby                                       --p_log_util_called_by_r
  );
  RAISE;
END prc_recon;


-----END MULTI FUCNTIONS & PROCS------
--Function to get batchid

FUNCTION get_batch_id(p_source_system IN VARCHAR2) RETURN VARCHAR2
IS
    lc_batch_id VARCHAR2(40);
    lc_process_name VARCHAR2(100);
BEGIN
    gc_trcmsg := gc_trcmsg || '2.1 Entered into get_batch_id' || chr(60);
    gc_updby := 'get_batch_id';

    -- Handle condition for EIS, CV OR GEN_REF
    IF p_source_system = 'STACS' THEN
        lc_process_name := 'GEN_REF_BATCH_ID';
    ELSIF p_source_system IN ('EIS', 'CV') THEN
        lc_process_name := 'SHINKA_' || p_source_system || '_BATCH_ID';
    ELSE
        lc_process_name := p_source_system || '_BATCH_ID';
    END IF;

    -- Select batch id based on the process name
    SELECT V_batch_id_r 
    INTO lc_batch_id
    FROM ATOMIC.PRCS_GRP_DATE_PARAM_R
    WHERE v_process_name_r = lc_process_name;

    dbms_output.put_line(lc_batch_id);

    gc_trcmsg := gc_trcmsg || '2.z Exit from get_batch_id' || chr(13);

    RETURN lc_batch_id;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        gc_errmsg := SUBSTR(SQLERRM, 1, 4000);
        gc_trcmsg := gc_trcmsg || 'No Batch ID detected' || chr(13) || gc_errmsg;
        pkg_grp_log_util.prc_update_log(gn_out_job_id, --p_job_id
                                        gc_error_status, --p_job_status
                                        gc_errmsg, --p_err_msg
                                        gc_trcmsg || chr(13) || gc_errmsg, --p_trc_msg
                                        gc_updby --p_log_util_called_by_r
                                        );
        RAISE;
END;



--Function to get the src table name



--Function to get where Single Source system Merge
PROCEDURE get_singlesrcsys_merge1(p_v_job_name_r IN VARCHAR2,lc_VAR_GRP_DIFW_tgt_TBL_NM IN VARCHAR2) 
IS
	lc_char CLOB;
	lc_char1 CLOB;
	lc_clob CLOB;
	v_num_rows_affected number;
BEGIN
	gc_trcmsg:=gc_trcmsg||'6.1 Entered into get_singlesrcsys_merge1'||chr(13);
     gc_updby:=  'get_singlesrcsys_merge1';
	dbms_output.put_line(gc_trcmsg);
	SELECT V_MERGE_STATEMENT_1_R INTO lc_char1
	FROM PRCS_GRP_DATAINGESTION_PARAM_R
	WHERE V_PARAM_NAME_R = p_v_job_name_r;
    --IF SUBSTR(lc_VAR_GRP_DIFW_tgt_TBL_NM, 1, 3) = 'DIM'
    IF INSTR(gc_grp_sourcetype, 'FCT')  > 0
     THEN
        SELECT replace('INSERT '||INS||CHR(10)||'VALUES '||VAL,',)',')')  INTO lc_char FROM (
        SELECT '('||TRIM((XMLAGG(XMLELEMENT(A,'D.'||COLUMN_NAME ||',')
        ORDER BY COLUMN_ID).EXTRACT('//text()')).getclobval())||gc_auditcols_FACT||')' INS, '('||TRIM((XMLAGG(XMLELEMENT(A,'S.'||COLUMN_NAME ||',')
        ORDER BY COLUMN_ID).EXTRACT('//text()')).getclobval())||gc_auditcol_values_FACT||')' VAL
        FROM ALL_TAB_COLUMNS WHERE TABLE_NAME=lc_VAR_GRP_DIFW_tgt_TBL_NM
        AND owner='ATOMIC'
        AND COLUMN_NAME NOT IN ('T_CREATION_DATE_R','V_CREATED_BY_R','T_LAST_MODIFIED_DATE_R','V_LAST_MODIFIED_BY_R','N_LOAD_RUN_ID_R')
        );
    ELSIF  INSTR(gc_grp_sourcetype, 'DIM')  > 0
    THEN
        SELECT replace('INSERT '||INS||CHR(10)||'VALUES '||VAL,',)',')')  INTO lc_char FROM (
        SELECT '('||TRIM((XMLAGG(XMLELEMENT(A,'D.'||COLUMN_NAME ||',')
        ORDER BY COLUMN_ID).EXTRACT('//text()')).getclobval())||gc_auditcols_DIM||')' INS, '('||TRIM((XMLAGG(XMLELEMENT(A,'S.'||COLUMN_NAME ||',')
        ORDER BY COLUMN_ID).EXTRACT('//text()')).getclobval())||gc_auditcol_values_DIM||')' VAL
        FROM ALL_TAB_COLUMNS WHERE TABLE_NAME=lc_VAR_GRP_DIFW_tgt_TBL_NM
        AND owner='ATOMIC'
        AND COLUMN_NAME NOT IN ('T_CREATION_DATE_R','V_CREATED_BY_R','T_LAST_MODIFIED_DATE_R','V_LAST_MODIFIED_BY_R','N_LOAD_RUN_ID_R','N_SEQUENCE_NUMBER_R')
        );

    END IF;

	gc_trcmsg:=gc_trcmsg||'6.z Exit from get_singlesrcsys_merge1'||chr(13);

	lc_clob:=lc_char1||' WHEN NOT MATCHED THEN  '||lc_char;

	gc_trcmsg:='Print lc_char1'||chr(13);

	dbms_output.put_line(gc_trcmsg);	


	gc_trcmsg:='Print lc_char'||chr(13);

	dbms_output.put_line(gc_trcmsg);


	gc_trcmsg:='Print lc_clob'||lc_clob||chr(13);

	dbms_output.put_line(gc_trcmsg);

	dbms_output.put_line('lc_merge_final :->'||lc_clob);
	EXECUTE IMMEDIATE lc_clob;

	commit;

    -- Get the number of rows affected
    v_num_rows_affected := SQL%ROWCOUNT;

    -- Output the number of rows affected
    DBMS_OUTPUT.PUT_LINE('Number of rows affected: ' || v_num_rows_affected);



EXCEPTION
WHEN OTHERS THEN
    gc_errmsg:=SUBSTR(SQLERRM,1,4000);
	gc_trcmsg:=gc_trcmsg||'6.z Error in get_singlesrcsys_merge1'||chr(13)||gc_errmsg;
    pkg_grp_log_util.prc_update_log
      (
        gn_out_job_id                 --p_job_id
        ,gc_error_status              --p_job_status
        ,gc_errmsg                    --p_err_msg
        ,gc_trcmsg||chr(13)||gc_errmsg--p_trc_msg
        ,gc_updby                     --p_log_util_called_by_r
      );
    RAISE;

END get_singlesrcsys_merge1;

--Function to get where Single Source system Merge
PROCEDURE get_multisrcsys_insert(
    p_v_job_name_r        IN VARCHAR2,
    p_source_system       IN VARCHAR2,
    p_srctbl_where_clause IN VARCHAR2,
    p_src_sqlcmd_where_clause IN VARCHAR2,
    p_src_tbl_name        IN VARCHAR2,
    p_tgt_tbl_name        IN VARCHAR2)
IS
	lc_char VARCHAR2(4000);
	lc_char1 VARCHAR2(4000);
	lc_clob CLOB;
    SEL_QUERY CLOB;
	v_num_rows_affected number;
BEGIN
	gc_trcmsg:=gc_trcmsg||'6.1 Entered into get_singlesrcsys_merge1'||chr(13);
     gc_updby:=  'get_multisrcsys_insert';


    IF INSTR(gc_grp_sourcetype, 'FCT')  > 0
     THEN

        SELECT replace('INSERT INTO ATOMIC.'||p_tgt_tbl_name ||INS||CHR(10)||'SELECT '||SEL,',)',')')        
        || ' FROM ATOMIC.' || p_src_tbl_name INTO SEL_QUERY FROM (
        SELECT '('||TRIM((XMLAGG(XMLELEMENT(A,COLUMN_NAME ||',')
        ORDER BY COLUMN_ID).EXTRACT('//text()')).getclobval())||REPLACE(gc_auditcols_FACT,'D.','')||')' INS, 
        TRIM((XMLAGG(XMLELEMENT(A,COLUMN_NAME ||',')
        ORDER BY COLUMN_ID).EXTRACT('//text()')).getclobval())||REPLACE(gc_auditcol_values_FACT,'D.','') SEL
        FROM ALL_TAB_COLUMNS WHERE TABLE_NAME=p_tgt_tbl_name
        AND owner='ATOMIC'
         AND COLUMN_NAME NOT IN ('T_CREATION_DATE_R','V_CREATED_BY_R','T_LAST_MODIFIED_DATE_R','V_LAST_MODIFIED_BY_R','N_LOAD_RUN_ID_R')
        );




    END IF;

	gc_trcmsg:=gc_trcmsg||'6.z Exit from get_singlesrcsys_merge1'||chr(13);


     IF INSTR(gc_grp_sourcetype, 'MULTI')  > 0
         THEN
         lc_clob:=SEL_QUERY|| '  '||p_src_sqlcmd_where_clause ||  gn_batchid||' '|| p_srctbl_where_clause||''''|| p_source_system ||'''' ;

    ELSE
        lc_clob:=SEL_QUERY|| '  '||p_src_sqlcmd_where_clause||  gn_batchid;
        gc_trcmsg:='Print lc_char1'||chr(13);
    END IF;
	gc_trcmsg:='Print lc_char1'||chr(13);
    --gc_trcmsg:=gc_trcmsg||chr(13)||lc_clob;
	dbms_output.put_line(gc_trcmsg);	


	gc_trcmsg:='Print lc_char'||chr(13);

	----dbms_output.put_line(gc_trcmsg);


	gc_trcmsg:='Print lc_clob'||lc_clob||chr(13);

	dbms_output.put_line(gc_trcmsg);

	dbms_output.put_line('lc_merge_final :->'||lc_clob);
	EXECUTE IMMEDIATE lc_clob;

	commit;

    -- Get the number of rows affected
    v_num_rows_affected := SQL%ROWCOUNT;

    -- Output the number of rows affected
    DBMS_OUTPUT.PUT_LINE('Number of rows affected: ' || v_num_rows_affected);



EXCEPTION
WHEN OTHERS THEN
    gc_errmsg:=SUBSTR(SQLERRM,1,4000);
	gc_trcmsg:=gc_trcmsg||'6.z Error in get_singlesrcsys_merge1'||chr(13)||gc_errmsg;
    pkg_grp_log_util.prc_update_log
      (
        gn_out_job_id                 --p_job_id
        ,gc_error_status              --p_job_status
        ,gc_errmsg                    --p_err_msg
        ,gc_trcmsg||chr(13)||gc_errmsg--p_trc_msg
        ,gc_updby                     --p_log_util_called_by_r
      );
    RAISE;

END get_multisrcsys_insert;


PROCEDURE tbl_rec_count_jobwise(p_v_job_name_r IN VARCHAR2,p_source_system IN VARCHAR2,p_batchid IN NUMBER,P_VAR_GRP_DIFW_tgt_TBL_NM IN VARCHAR2,
P_VAR_GRP_DIFW_SRC_TBL_NM IN VARCHAR2)
IS
	lc_char VARCHAR2(4000);
	lc_VAR_GRP_EDW_LOAD_RUN_ID_R NUMBER;
	lc_VAR_GRP_DEBUG_FLAG_R VARCHAR2(4000);
	lc_VAR_GRP_ET_SRC_TABLE_NM VARCHAR2(4000);
	lc_V_JOB_NAME_R	VARCHAR2(4000);
	lc_V_ET_TABLE_NAME_R VARCHAR2(4000);
	lc_V_EDW_TABLE_NAME_R	VARCHAR2(4000);
	lc_V_SELECT_QUERY_R	CLOB;
	lc_V_WHERE_SOURCE_SYSTEM_R	VARCHAR2(4000);
	lc_V_GROUP_BY_R	VARCHAR2(4000);
	lc_V_SOURCE_SYSTEM_R	VARCHAR2(4000);
	lc_V_PARENT_SOURCE_SYSTEM_R	VARCHAR2(4000);
	lc_V_SRCTBL_PARALLEL_DEGREE_R	VARCHAR2(4000);
	lc_V_LOAD_TYPE_R	VARCHAR2(4000);
	lc_V_LATEST_ADW_RUNAUDIT_R	VARCHAR2(4000);
	LC_PRCS_GRP_EDW_TBL_RECCNT_QUERIES_R NUMBER;
	LC_OUT_LOAD_STATUS VARCHAR2(4000);
	LC_VAR_GRP_DIFW_tgt_TBL_NM VARCHAR2(4000):=P_VAR_GRP_DIFW_tgt_TBL_NM;
	lc_VAR_GRP_DIFW_SRC_TBL_NM VARCHAR2(4000):=p_VAR_GRP_DIFW_SRC_TBL_NM;

BEGIN

	gc_trcmsg:=gc_trcmsg||'8.1 Entered into tbl_rec_count_jobwise'||chr(13);
	--dbms_output.put_line(gc_trcmsg);
     gc_updby:=  'tbl_rec_count_jobwise';

	SELECT TO_NUMBER(TO_CHAR(SYSDATE,'YYYYMMDD')) into lc_VAR_GRP_EDW_LOAD_RUN_ID_R
	FROM DUAL;

	gc_trcmsg:='8.2 Print lc_VAR_GRP_EDW_LOAD_RUN_ID_R'||lc_VAR_GRP_EDW_LOAD_RUN_ID_R||chr(13);

	--dbms_output.put_line(gc_trcmsg);	

	--getting the lc_VAR_GRP_DEBUG_FLAG_R value
	select NVL(V_DEBUG_FLAG_R,'N') into lc_VAR_GRP_DEBUG_FLAG_R
	from prcs_grp_dataingestion_param_r
	where F_ENABLE_FLAG_R='Y'  
	AND NVL(V_PARAM_NAME_R,'@~') = p_v_job_name_r;

	gc_trcmsg:='8.3 Print lc_VAR_GRP_DEBUG_FLAG_R'||lc_VAR_GRP_DEBUG_FLAG_R||chr(13);

	--dbms_output.put_line(gc_trcmsg);


	select V_ET_TABLE_NAME_R into lc_VAR_GRP_ET_SRC_TABLE_NM
	from prcs_grp_dataingestion_param_r
	where F_ENABLE_FLAG_R='Y'  
	and V_TBL_REC_CNT_RECON_FLAG_R='Y'
	AND NVL(V_PARAM_NAME_R,'@~') = p_v_job_name_r
	group by V_ET_TABLE_NAME_R;

	gc_trcmsg:='8.4 Print lc_VAR_GRP_ET_SRC_TABLE_NM'||lc_VAR_GRP_ET_SRC_TABLE_NM||chr(13);	
	--dbms_output.put_line(gc_trcmsg);


	gc_trcmsg:='8.5 performing delete PRCS_GRP_EDW_TBL_RECCNT_QUERIES_R'||chr(13);	
	--dbms_output.put_line(gc_trcmsg);

	delete from  PRCS_GRP_EDW_TBL_RECCNT_QUERIES_R where V_PARENT_SOURCE_SYSTEM_R= p_source_system
	and v_edw_table_name_r= lc_VAR_GRP_DIFW_tgt_TBL_NM;

	commit;

	gc_trcmsg:='8.6 SELECT TO V_COLUMNS'||chr(13);	
	--dbms_output.put_line(gc_trcmsg);

	SELECT V_JOB_NAME_R,V_ET_TABLE_NAME_R,V_EDW_TABLE_NAME_R,V_SELECT_QUERY_R,V_WHERE_SOURCE_SYSTEM_R,V_GROUP_BY_R,V_SOURCE_SYSTEM_R,V_PARENT_SOURCE_SYSTEM_R,V_SRCTBL_PARALLEL_DEGREE_R,V_LOAD_TYPE_R,V_LATEST_ADW_RUNAUDIT_R 
	INTO LC_V_JOB_NAME_R,LC_V_ET_TABLE_NAME_R,LC_V_EDW_TABLE_NAME_R,LC_V_SELECT_QUERY_R,LC_V_WHERE_SOURCE_SYSTEM_R,LC_V_GROUP_BY_R,
	LC_V_SOURCE_SYSTEM_R,LC_V_PARENT_SOURCE_SYSTEM_R,LC_V_SRCTBL_PARALLEL_DEGREE_R,LC_V_LOAD_TYPE_R,LC_V_LATEST_ADW_RUNAUDIT_R

	FROM 
	(
    SELECT V_JOB_NAME_R,V_ET_TABLE_NAME_R,V_EDW_TABLE_NAME_R,V_SELECT_QUERY_R,V_WHERE_SOURCE_SYSTEM_R,V_GROUP_BY_R,V_SOURCE_SYSTEM_R,V_PARENT_SOURCE_SYSTEM_R,V_SRCTBL_PARALLEL_DEGREE_R,V_LOAD_TYPE_R,V_LATEST_ADW_RUNAUDIT_R FROM  VW_PRCS_GRP_TPA_EDW_TBL_RECCNT_QUERIES_R  WHERE V_PARENT_SOURCE_SYSTEM_R=p_source_system and v_edw_table_name_r=lc_VAR_GRP_DIFW_tgt_TBL_NM UNION
	SELECT V_JOB_NAME_R,V_ET_TABLE_NAME_R,V_EDW_TABLE_NAME_R,V_SELECT_QUERY_R,V_WHERE_SOURCE_SYSTEM_R,V_GROUP_BY_R,V_SOURCE_SYSTEM_R,V_PARENT_SOURCE_SYSTEM_R,V_SRCTBL_PARALLEL_DEGREE_R,V_LOAD_TYPE_R,V_LATEST_ADW_RUNAUDIT_R FROM  VW_PRCS_GRP_APS_EDW_TBL_RECCNT_QUERIES_R  WHERE V_PARENT_SOURCE_SYSTEM_R=p_source_system and v_edw_table_name_r=lc_VAR_GRP_DIFW_tgt_TBL_NM UNION
	SELECT V_JOB_NAME_R,V_ET_TABLE_NAME_R,V_EDW_TABLE_NAME_R,V_SELECT_QUERY_R,V_WHERE_SOURCE_SYSTEM_R,V_GROUP_BY_R,V_SOURCE_SYSTEM_R,V_PARENT_SOURCE_SYSTEM_R,V_SRCTBL_PARALLEL_DEGREE_R,V_LOAD_TYPE_R,V_LATEST_ADW_RUNAUDIT_R FROM  VW_PRCS_GRP_VUE_EDW_TBL_RECCNT_QUERIES_R  WHERE V_PARENT_SOURCE_SYSTEM_R=p_source_system and v_edw_table_name_r=lc_VAR_GRP_DIFW_tgt_TBL_NM UNION
	SELECT V_JOB_NAME_R,V_ET_TABLE_NAME_R,V_EDW_TABLE_NAME_R,V_SELECT_QUERY_R,V_WHERE_SOURCE_SYSTEM_R,V_GROUP_BY_R,V_SOURCE_SYSTEM_R,V_PARENT_SOURCE_SYSTEM_R,V_SRCTBL_PARALLEL_DEGREE_R,V_LOAD_TYPE_R,V_LATEST_ADW_RUNAUDIT_R FROM VW_PRCS_GRP_PACS_EDW_TBL_RECCNT_QUERIES_R  WHERE V_PARENT_SOURCE_SYSTEM_R=p_source_system and v_edw_table_name_r=lc_VAR_GRP_DIFW_tgt_TBL_NM UNION
	SELECT V_JOB_NAME_R,V_ET_TABLE_NAME_R,V_EDW_TABLE_NAME_R,V_SELECT_QUERY_R,V_WHERE_SOURCE_SYSTEM_R,V_GROUP_BY_R,V_SOURCE_SYSTEM_R,V_PARENT_SOURCE_SYSTEM_R,V_SRCTBL_PARALLEL_DEGREE_R,V_LOAD_TYPE_R,V_LATEST_ADW_RUNAUDIT_R FROM VW_PRCS_GRP_GEN_REF_EDW_TBL_RECCNT_QUERIES_R WHERE V_PARENT_SOURCE_SYSTEM_R=p_source_system and v_edw_table_name_r=lc_VAR_GRP_DIFW_tgt_TBL_NM UNION
	SELECT V_JOB_NAME_R,V_ET_TABLE_NAME_R,V_EDW_TABLE_NAME_R,V_SELECT_QUERY_R,V_WHERE_SOURCE_SYSTEM_R,V_GROUP_BY_R,V_SOURCE_SYSTEM_R,V_PARENT_SOURCE_SYSTEM_R,V_SRCTBL_PARALLEL_DEGREE_R,V_LOAD_TYPE_R,V_LATEST_ADW_RUNAUDIT_R FROM VW_PRCS_SHINKA_EIS_EDW_TBL_RECCNT_QUERIES_R  WHERE V_PARENT_SOURCE_SYSTEM_R=p_source_system and v_edw_table_name_r=lc_VAR_GRP_DIFW_tgt_TBL_NM UNION
	SELECT V_JOB_NAME_R,V_ET_TABLE_NAME_R,V_EDW_TABLE_NAME_R,V_SELECT_QUERY_R,V_WHERE_SOURCE_SYSTEM_R,V_GROUP_BY_R,V_SOURCE_SYSTEM_R,V_PARENT_SOURCE_SYSTEM_R,V_SRCTBL_PARALLEL_DEGREE_R,V_LOAD_TYPE_R,V_LATEST_ADW_RUNAUDIT_R FROM VW_PRCS_SHINKA_CV_EDW_TBL_RECCNT_QUERIES_R  WHERE V_PARENT_SOURCE_SYSTEM_R=p_source_system and v_edw_table_name_r=lc_VAR_GRP_DIFW_tgt_TBL_NM
	);

	gc_trcmsg:='8.7 INSERT IN TO PRCS_GRP_EDW_TBL_RECCNT_QUERIES_R'||chr(13);	
	--dbms_output.put_line(gc_trcmsg);

		INSERT INTO  PRCS_GRP_EDW_TBL_RECCNT_QUERIES_R
		(V_JOB_NAME_R                  
		,V_ET_TABLE_NAME_R             
		,V_EDW_TABLE_NAME_R            
		,V_SELECT_QUERY_R              
		,V_WHERE_SOURCE_SYSTEM_R       
		,V_GROUP_BY_R                  
		,V_SOURCE_SYSTEM_R             
		,V_PARENT_SOURCE_SYSTEM_R
		,N_LOAD_RUN_ID_R
		,V_SRCTBL_PARALLEL_DEGREE_R
		,V_LOAD_TYPE_R
		,V_ETLID_N_BATCH_ID_R
		,V_LATEST_ADW_RUNAUDIT_R
        ,V_COLLECT_RECCNT_R
		)
		VALUES 
		(
		 LC_V_JOB_NAME_R                  
		,LC_V_ET_TABLE_NAME_R             
		,LC_V_EDW_TABLE_NAME_R            
		,LC_V_SELECT_QUERY_R              
		,LC_V_WHERE_SOURCE_SYSTEM_R       
		,LC_V_GROUP_BY_R                  
		,LC_V_SOURCE_SYSTEM_R             
		,LC_V_PARENT_SOURCE_SYSTEM_R 
		,lc_VAR_GRP_EDW_LOAD_RUN_ID_R
		,LC_V_SRCTBL_PARALLEL_DEGREE_R
		,LC_V_LOAD_TYPE_R
		,p_batchid
		,LC_V_LATEST_ADW_RUNAUDIT_R
        ,'JOBWISE'
		);

		COMMIT;

	SELECT COUNT(1) into LC_PRCS_GRP_EDW_TBL_RECCNT_QUERIES_R from  PRCS_GRP_EDW_TBL_RECCNT_QUERIES_R 
	where V_PARENT_SOURCE_SYSTEM_R=p_source_system 
	and v_edw_table_name_r= lc_VAR_GRP_DIFW_tgt_TBL_NM;

	gc_trcmsg:='8.8  select count from PRCS_GRP_EDW_TBL_RECCNT_QUERIES_R LC_PRCS_GRP_EDW_TBL_RECCNT_QUERIES_R'
	||LC_PRCS_GRP_EDW_TBL_RECCNT_QUERIES_R||chr(13);	
	--dbms_output.put_line(gc_trcmsg);



	 IF LC_PRCS_GRP_EDW_TBL_RECCNT_QUERIES_R > 1    
		THEN
			gc_errmsg:=SUBSTR(SQLERRM,1,4000);
			gc_trcmsg:=gc_trcmsg||'8.9 More than one entry detected in PRCS_GRP_EDW_TBL_RECCNT_QUERIES_R and hence terminating ' || LC_PRCS_GRP_EDW_TBL_RECCNT_QUERIES_R||chr(13)||gc_errmsg;
			pkg_grp_log_util.prc_update_log
			  (
				gn_out_job_id                 --p_job_id
				,gc_error_status              --p_job_status
				,gc_errmsg                    --p_err_msg
				,gc_trcmsg||chr(13)||gc_errmsg--p_trc_msg
				,gc_updby                     --p_log_util_called_by_r
			  );

			RAISE_APPLICATION_ERROR(-20000, '8.9 More than one entry detected in PRCS_GRP_EDW_TBL_RECCNT_QUERIES_R and hence terminating' || LC_PRCS_GRP_EDW_TBL_RECCNT_QUERIES_R);

	END IF;

	gc_trcmsg:='8.8 Calling the procedure PKG_GRP_LOAD_STATS_EDW_JOBWISE.PRCS_GRP_LOAD_STATS_EDW_JOBWISE'||chr(13);	
	--dbms_output.put_line(gc_trcmsg);
	    -- Print the values of the arguments
    DBMS_OUTPUT.PUT_LINE('p_batchid: ' || p_batchid);
    DBMS_OUTPUT.PUT_LINE('lc_VAR_GRP_EDW_LOAD_RUN_ID_R: ' || lc_VAR_GRP_EDW_LOAD_RUN_ID_R);
    DBMS_OUTPUT.PUT_LINE('p_source_system: ' || p_source_system);
    DBMS_OUTPUT.PUT_LINE('LC_VAR_GRP_DIFW_tgt_TBL_NM: ' || LC_VAR_GRP_DIFW_tgt_TBL_NM);
    DBMS_OUTPUT.PUT_LINE('lc_VAR_GRP_ET_SRC_TABLE_NM: ' || lc_VAR_GRP_ET_SRC_TABLE_NM);

			PKG_GRP_LOAD_STATS_EDW_JOBWISE.PRCS_GRP_LOAD_STATS_EDW_JOBWISE
			(p_batchid,lc_VAR_GRP_EDW_LOAD_RUN_ID_R,p_source_system,LC_VAR_GRP_DIFW_tgt_TBL_NM,lc_VAR_GRP_ET_SRC_TABLE_NM,LC_OUT_LOAD_STATUS);
	IF LC_OUT_LOAD_STATUS <>'SUCCESS' THEN
	   raise_application_error(-20001, ' Load '||p_v_job_name_r|| 
	   ' PKG_GRP_LOAD_STATS_EDW.PRCS_GRP_LOAD_STATS_EDW_JOBWISE has been failed against the Batch ID ' ||p_batchid|| 
	   ' with the error :->' || LC_OUT_LOAD_STATUS);
	END IF;
--Do we need this exception here?
--exception 
--when others then 
  --raise_application_error(-20001,'Error Occured in the ODI Procedure  :->'||SQLERRM);
--END;


	EXCEPTION
	WHEN OTHERS THEN
		gc_errmsg:=SUBSTR(SQLERRM,1,4000);
		gc_trcmsg:=gc_trcmsg||'8.z Error in tbl_rec_count_jobwise'||chr(13)||gc_errmsg;
		pkg_grp_log_util.prc_update_log
		  (
			gn_out_job_id                 --p_job_id
			,gc_error_status              --p_job_status
			,gc_errmsg                    --p_err_msg
			,gc_trcmsg||chr(13)||gc_errmsg--p_trc_msg
			,gc_updby                     --p_log_util_called_by_r
		  );
		RAISE;
END tbl_rec_count_jobwise;

/**
FUNCTION get_reruncheck_cnt1(job_name1 IN VARCHAR2,
                            p_batchid IN number) 
                            RETURN NUMBER
IS
	ln_num NUMBER;
BEGIN
   gc_trcmsg:=gc_trcmsg||'3.1 Entered into get_reruncheck_cnt'||chr(13);
   --dbms_output.put_line(gc_trcmsg);
   gc_trcmsg:=gc_trcmsg||'job_name'||job_name||chr(13);
   --dbms_output.put_line(gc_trcmsg);
   gc_trcmsg:=gc_trcmsg||'p_batchid:'||p_batchid||chr(13);
   --dbms_output.put_line(gc_trcmsg);

	select count(1) into ln_num 
	from PRCS_JOB_LOG_R 
	where V_JOB_NAME_R = job_name1
	and (N_BATCH_ID_R) = (p_batchid)
	and  V_JOB_STATUS_R in ( 'Success' ,'Running');

gc_trcmsg:=gc_trcmsg||'3.2 reruncheck_cnt:'||ln_num||chr(13);
	dbms_output.put_line(ln_num);
	--dbms_output.put_line(gc_trcmsg);
   gc_trcmsg:=gc_trcmsg||'3.z Exit from get_reruncheck_cnt'||chr(13);
RETURN ln_num;


EXCEPTION
	WHEN OTHERS 
	THEN
    gc_errmsg:=SUBSTR(SQLERRM,1,4000);
	gc_trcmsg:=gc_trcmsg||'3.z Error in get_reruncheck_cnt'||chr(13)||gc_errmsg;
    RAISE;

END get_reruncheck_cnt1;

**/


FUNCTION get_reruncheck_cnt(
      p_job_name  IN VARCHAR2,
      p_batchid      IN NUMBER

	 )
 RETURN NUMBER
IS
  ln_num NUMBER;
BEGIN

   gc_trcmsg:=gc_trcmsg||'3.1 Entered into get_reruncheck_cnt'||chr(13);
    gc_updby:=  'get_reruncheck_cnt';
   --dbms_output.put_line(gc_trcmsg);
   gc_trcmsg:=gc_trcmsg||'job_name:->'||p_job_name||chr(13);
   --dbms_output.put_line(gc_trcmsg);
   gc_trcmsg:=gc_trcmsg||'p_batchid:'||p_batchid||chr(13);
   --dbms_output.put_line(gc_trcmsg);
select count(1) into ln_num 
	from PRCS_JOB_LOG_R 
	where V_JOB_NAME_R = p_job_name
	and (N_BATCH_ID_R) = (p_batchid)
	and  V_JOB_STATUS_R in ( 'Success' ,'Running');

gc_trcmsg:=gc_trcmsg||'3.2 reruncheck_cnt:'||ln_num||chr(13);
	dbms_output.put_line(ln_num);
	--dbms_output.put_line(gc_trcmsg);
   gc_trcmsg:=gc_trcmsg||'3.z Exit from get_reruncheck_cnt'||chr(13);
RETURN ln_num;


EXCEPTION

    WHEN OTHERS THEN
    gc_errmsg:=SUBSTR(SQLERRM,1,4000);
    gc_trcmsg:=gc_trcmsg||'3.z Error in get_reruncheck_cnt'||chr(13)||gc_errmsg;
    pkg_grp_log_util.prc_update_log ( gn_out_job_id --p_job_id
    ,gc_error_status                                --p_job_status
    ,gc_errmsg                                      --p_err_msg
    ,gc_trcmsg||chr(13)||gc_errmsg                  --p_trc_msg
    ,gc_updby                                       --p_log_util_called_by_r
    );
    RAISE;


END get_reruncheck_cnt;

FUNCTION get_singlesrc_recon_cnt(
      gn_batchid      IN NUMBER,
      p_source_system IN VARCHAR2,
      p_src_tbl_name  IN VARCHAR2,
      p_tgt_tbl_name  IN VARCHAR2
	 )
 RETURN NUMBER
IS
  ln_num NUMBER;
BEGIN
  gc_trcmsg:=gc_trcmsg||'7.1 Entered into get_recon_cnt'||chr(13);
   gc_updby:=  'get_singlesrc_recon_cnt';
  EXECUTE IMMEDIATE '   
SELECT COUNT(1) FROM    
(     
SELECT        
COUNT(1) REC_CNT     
FROM   atomic.   
"' || p_src_tbl_name || '"     
WHERE N_BATCH_ID_R = :batch_id     
MINUS     
SELECT        
COUNT(1) REC_CNT     
FROM      
"' || p_tgt_tbl_name || '"     
WHERE N_BATCH_ID_R = :batch_id    
)' INTO ln_num USING gn_batchid,
  gn_batchid;
  -- Output the result
  DBMS_OUTPUT.PUT_LINE('Number of records: ' || ln_num);
  gc_trcmsg:=gc_trcmsg||'7.z Exit from get_recon_cnt'||chr(13);
  RETURN ln_num;
EXCEPTION
WHEN OTHERS THEN
  gc_errmsg:=SUBSTR(SQLERRM,1,4000);
  gc_trcmsg:=gc_trcmsg||'7.z Error in get_recon_cnt'||chr(13)||gc_errmsg;
  pkg_grp_log_util.prc_update_log ( gn_out_job_id --p_job_id
  ,gc_error_status                                --p_job_status
  ,gc_errmsg                                      --p_err_msg
  ,gc_trcmsg||chr(13)||gc_errmsg                  --p_trc_msg
  ,gc_updby                                       --p_log_util_called_by_r
  );
  RAISE;
END get_singlesrc_recon_cnt;


PROCEDURE get_delete_load(p_v_job_name_r IN VARCHAR2,lc_VAR_GRP_DIFW_tgt_TBL_NM IN VARCHAR2)

IS
	lc_char VARCHAR2(4000);
	lc_char1 VARCHAR2(4000);
	lc_clob CLOB;
	v_num_rows_affected Number;
BEGIN
	gc_trcmsg:=gc_trcmsg||'6.1 Entered into get_delete_load'||chr(13);
	--dbms_output.put_line(gc_trcmsg);
     gc_updby:=  'get_delete_load';

	SELECT V_MERGE_STATEMENT_1_R INTO lc_char1
	FROM PRCS_GRP_DATAINGESTION_PARAM_R
	WHERE V_PARAM_NAME_R = p_v_job_name_r;


	SELECT replace('INSERT '||INS||CHR(10)||'VALUES '||VAL,',)',')')  INTO lc_char FROM (
	SELECT '('||TRIM((XMLAGG(XMLELEMENT(A,'D.'||COLUMN_NAME ||',')
	ORDER BY COLUMN_ID).EXTRACT('//text()')).getclobval())||gc_auditcols_DIM||')' INS, '('||TRIM((XMLAGG(XMLELEMENT(A,'S.'||COLUMN_NAME ||',')
	ORDER BY COLUMN_ID).EXTRACT('//text()')).getclobval())||gc_auditcol_values_DIM||')' VAL
	FROM ALL_TAB_COLUMNS WHERE TABLE_NAME=lc_VAR_GRP_DIFW_tgt_TBL_NM
	AND owner='ATOMIC'
	AND COLUMN_NAME NOT IN ('T_CREATION_DATE_R','V_CREATED_BY_R','T_LAST_MODIFIED_DATE_R','V_LAST_MODIFIED_BY_R','N_SEQUENCE_NUMBER_R')
	);


	lc_clob:=lc_char1||' WHEN NOT MATCHED THEN  '||lc_char;

	gc_trcmsg:='Print lc_char1:'||lc_char1||chr(13);

	--dbms_output.put_line(gc_trcmsg);	


	gc_trcmsg:='Print lc_char:'||lc_char||chr(13);

	--dbms_output.put_line(gc_trcmsg);

	gc_trcmsg:='Print lc_merge_final:'||lc_clob||chr(13);

	dbms_output.put_line(gc_trcmsg);

	dbms_output.put_line('Performing truncate on Operation on :'||lc_VAR_GRP_DIFW_tgt_TBL_NM);

	EXECUTE IMMEDIATE 'TRUNCATE TABLE ' || lc_VAR_GRP_DIFW_tgt_TBL_NM;
    COMMIT;

	EXECUTE IMMEDIATE lc_clob;

	commit;

    -- Get the number of rows affected
    v_num_rows_affected := SQL%ROWCOUNT;

    -- Output the number of rows affected
    DBMS_OUTPUT.PUT_LINE('Number of rows affected: ' || v_num_rows_affected);


   --RETURN lc_char;
EXCEPTION
WHEN OTHERS THEN
    gc_errmsg:=SUBSTR(SQLERRM,1,4000);
	gc_trcmsg:=gc_trcmsg||'6.z Error in get_delete_load'||chr(13)||gc_errmsg;
    pkg_grp_log_util.prc_update_log
      (
        gn_out_job_id                 --p_job_id
        ,gc_error_status              --p_job_status
        ,gc_errmsg                    --p_err_msg
        ,gc_trcmsg||chr(13)||gc_errmsg--p_trc_msg
        ,gc_updby                     --p_log_util_called_by_r
      );
    RAISE;
END get_delete_load;

END pkg_grp_load_difw;