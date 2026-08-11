

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ATOMIC"."PKG_GRP_LOAD_DIFW_PD" AS

    PROCEDURE main
	(
        p_v_job_name_r            IN  VARCHAR2,
        p_source_system           IN  VARCHAR2,
      p_grp_sourcetype           IN  VARCHAR2 --FCT_SINGLE_SRC,FCT_MULTI_SRC
    ) IS

      -- lc_errmsg        VARCHAR2(4000);
      --lc_errcd         VARCHAR2(30);
      --lc_trackmsg      VARCHAR2(4000);
      lc_batch_id      VARCHAR2(40);
      lc_rerun_check   NUMBER;
      lc_src_sqlcmd_where_clause     VARCHAR2(4000);
      lc_srctbl_where_clause     VARCHAR2(4000);
	  lc_get_var_grp_difw_physical_delete VARCHAR2(4000);
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
        dbms_output.put_line(gc_trcmsg);

        IF p_grp_sourcetype not in ('FCT_SINGLE_SRC','FCT_MULTI_SRC')
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
        dbms_output.put_line('lc_jobname is ->  '||gc_job_name);
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
            gc_trcmsg:=gc_trcmsg||'4.z Run detected for the batch and hence terminating ' || gn_batchid||chr(13)||gc_errmsg;

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

		gc_trcmsg:=GC_TRCMSG||'5.0 Call get_tgt_table_name from MAIN'||CHR(13);
        --dbms_output.put_line(gc_trcmsg);
        lc_var_grp_difw_src_tbl_nm:=pkg_grp_load_difw.get_src_table_name(lc_jobname);

        gc_trcmsg:=gc_trcmsg||'5.z Called get_src_table_name  MAIN :->src table name is :->'||lc_var_grp_difw_src_tbl_nm||chr(13);

        gc_trcmsg:=GC_TRCMSG||'6.0 Call get_tgt_table_name from MAIN'||CHR(13);
        --dbms_output.put_line(gc_trcmsg);

        lc_var_grp_difw_tgt_tbl_nm:=pkg_grp_load_difw.get_tgt_table_name(lc_jobname);

        gc_trcmsg:=gc_trcmsg||'6.z Called get_tgt_table_name  MAIN :->tgt table name is :->'||lc_var_grp_difw_tgt_tbl_nm||chr(13);

		gc_trcmsg:=GC_TRCMSG||'7.0 Call get_var_grp_difw_physical_delete from MAIN'||CHR(13);
        dbms_output.put_line(gc_trcmsg);
        lc_get_var_grp_difw_physical_delete:=pkg_grp_load_difw_pd.get_var_grp_difw_physical_delete(lc_jobname);
		 gc_trcmsg:=gc_trcmsg||'7.z Called get_var_grp_difw_physical_delete  MAIN :->get_var_grp_difw_physical_delete is :->'||lc_get_var_grp_difw_physical_delete||chr(13);

	IF INSTR(gc_grp_sourcetype, 'MULTI')  > 0
    THEN
        gc_trcmsg:=GC_TRCMSG||'8.0 Call where_source_system from MAIN'||CHR(13);
        dbms_output.put_line(gc_trcmsg);
        lc_srctbl_where_clause:=pkg_grp_load_difw_pd.get_multisrcsys_where_source_system(lc_jobname);
		gc_trcmsg:=GC_TRCMSG||'8.z Called get_multisrcsys_where_source_system from MAIN'||lc_srctbl_where_clause||CHR(13);
        dbms_output.put_line(gc_trcmsg);

		gc_trcmsg:=GC_TRCMSG||'9.0 Call where_source_system from MAIN'||CHR(13);
        dbms_output.put_line(gc_trcmsg);
		pkg_grp_load_difw_pd.get_multisrcsys_merge (p_v_job_name_r,p_source_system,lc_srctbl_where_clause,lc_get_var_grp_difw_physical_delete,lc_var_grp_difw_src_tbl_nm,lc_var_grp_difw_tgt_tbl_nm);
        gc_trcmsg:=gc_trcmsg||'9.z Called get_multisrcsys_merge  '||chr(13);
            --dbms_output.put_line(gc_trcmsg);

		 gc_trcmsg:=GC_TRCMSG||'10.0 Call prc_recon from MAIN'||CHR(50);
                --dbms_output.put_line(gc_trcmsg);

            pkg_grp_load_difw.prc_recon(p_v_job_name_r,p_source_system,gn_batchid,lc_var_grp_difw_tgt_tbl_nm,lc_VAR_GRP_DIFW_SRC_TBL_NM);
                gc_trcmsg:=GC_TRCMSG||'10.Z Called prc_recon from MAIN'||CHR(50);


	ELSE


                pkg_grp_load_difw_pd.get_singlesrcsys_merge(p_v_job_name_r,lc_VAR_GRP_DIFW_tgt_TBL_NM,lc_get_var_grp_difw_physical_delete);
                gc_trcmsg:=gc_trcmsg||'11.z Called get_singlesrcsys_merge  MAIN :->singlesrcsys_merge'||chr(13);
                dbms_output.put_line(gc_trcmsg);

				gc_trcmsg:=GC_TRCMSG||'12.0 Call tbl_rec_count_jobwise from MAIN'||CHR(50);
            --dbms_output.put_line(gc_trcmsg);
            pkg_grp_load_difw.tbl_rec_count_jobwise
            (p_v_job_name_r,p_source_system,gn_batchid,lc_VAR_GRP_DIFW_tgt_TBL_NM,lc_VAR_GRP_DIFW_SRC_TBL_NM);
            GC_TRCMSG:=GC_TRCMSG||'12.Z Called tbl_rec_count_jobwise from MAIN'||CHR(50);
            --dbms_output.put_line(gc_trcmsg);
            --Entry to prcs log after the succssful completion


	END IF;
            pkg_grp_log_util.prc_update_log
            (
                gn_out_job_id                   --p_job_id
                ,gc_success_status              --p_job_status
                ,gc_errmsg                      --p_err_msg
                ,gc_trcmsg                      --p_trc_msg
                ,gc_main_loadedby               --p_log_util_called_by_r
            );
            gc_trcmsg := gc_trcmsg
            || '13.z Called procedure prc_update_log'
            || chr(13);
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

FUNCTION get_multisrcsys_where_source_system(p_job_name IN VARCHAR2) RETURN VARCHAR2
IS
  lc_char VARCHAR2(4000);
BEGIN
  gc_trcmsg:=gc_trcmsg||'8.1 Entered into get_multisrcsys_where_source_system'||chr(13);
  gc_updby:= 'get_multisrcsys_where_source_system';

	  SELECT   V_WHERE_SOURCE_SYSTEM_R
	  INTO lc_char
	  FROM PRCS_GRP_DATAINGESTION_PARAM_R
	  WHERE F_ENABLE_FLAG_R        ='Y'
	  AND NVL(V_PARAM_NAME_R,'@~') = p_job_name;
	  gc_trcmsg:=gc_trcmsg||'8.z Exit from get_multisrcsys_where_source_system'||chr(13);

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

FUNCTION get_var_grp_difw_physical_delete(p_job_name IN VARCHAR2) RETURN VARCHAR2
IS
  lc_char VARCHAR2(4000);
BEGIN
  gc_trcmsg:=gc_trcmsg||'7.1 Entered into get_var_grp_difw_physical_delete'||chr(13);
  gc_updby:= 'get_var_grp_difw_physical_delete';

	  SELECT   V_PHYSICAL_DELETE_R
	  INTO lc_char
	  FROM PRCS_GRP_DATAINGESTION_PARAM_R
	  WHERE F_ENABLE_FLAG_R        ='Y'
	  AND NVL(V_PARAM_NAME_R,'@~') = p_job_name;
	  gc_trcmsg:=gc_trcmsg||'7.z Exit from get_var_grp_difw_physical_delete'||chr(13);

  RETURN lc_char;
EXCEPTION
WHEN OTHERS THEN
  gc_errmsg:=SUBSTR(SQLERRM,1,4000);
  gc_trcmsg:=gc_trcmsg||'7.z Error in get_var_grp_difw_physical_delete'||chr(13)||gc_errmsg;
  pkg_grp_log_util.prc_update_log ( gn_out_job_id --p_job_id
  ,gc_error_status                                --p_job_status
  ,gc_errmsg                                      --p_err_msg
  ,gc_trcmsg||chr(13)||gc_errmsg                  --p_trc_msg
  ,gc_updby                                       --p_log_util_called_by_r
  );
  RAISE;
END get_var_grp_difw_physical_delete;


PROCEDURE get_multisrcsys_merge(
    p_v_job_name_r        IN VARCHAR2,
    p_source_system       IN VARCHAR2,
    p_srctbl_where_clause IN VARCHAR2,
    lc_get_var_grp_difw_physical_delete IN VARCHAR2,
    p_src_tbl_name        IN VARCHAR2,
    p_tgt_tbl_name        IN VARCHAR2)
IS
  lc_merge1 CLOB;
  lc_merge2 CLOB;
  lc_merge3 CLOB;
  lc_merge4 CLOB;
  lc_merge_final CLOB;
  ln_row_cnt NUMBER;
  lc_del CLOB;
  lc_del_final CLOB;
BEGIN
gc_updby:=  'get_multisrcsys_merge';

SELECT V_PD_DELETE_QUERY_R
INTO lc_del
FROM PRCS_GRP_DATAINGESTION_PARAM_R
WHERE F_ENABLE_FLAG_R='Y'
AND NVL(V_PARAM_NAME_R,'@~') = p_source_system||'_'||p_v_job_name_r;


 SELECT V_ADD_ON_MERGE1_R
  INTO lc_merge1
  FROM PRCS_GRP_DATAINGESTION_PARAM_R
  WHERE V_PARAM_NAME_R = p_source_system
    ||'_'
    ||p_v_job_name_r;
  dbms_output.put_line('lc_merge1 :->'||lc_merge1);

  SELECT V_ADD_ON_MERGE2_R
  INTO lc_merge2
  FROM PRCS_GRP_DATAINGESTION_PARAM_R
  WHERE V_PARAM_NAME_R = p_source_system
    ||'_'
    ||p_v_job_name_r;
  dbms_output.put_line('lc_merge2 :->'||lc_merge2);

  SELECT V_ADD_ON_MERGE3_R
  INTO lc_merge3
  FROM PRCS_GRP_DATAINGESTION_PARAM_R
  WHERE V_PARAM_NAME_R = p_source_system
    ||'_'
    ||p_v_job_name_r;
  --dbms_output.put_line('9.lc_merge3 :->'||lc_merge3);

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


 lc_merge_final :=lc_merge1||' '|| p_srctbl_where_clause||''''|| p_source_system ||''''||lc_merge2||' ' ||lc_merge3||' '||lc_merge4|| 'where 1=1 '||lc_get_var_grp_difw_physical_delete;

  dbms_output.put_line('9.1 lc_merge_final :->'||lc_merge_final);

  lc_del_final := lc_del || ' ' || p_srctbl_where_clause || ' ' ||''''|| p_source_system||''''|| ')';

dbms_output.put_line('9.2 lc_del_final :->' || lc_del_final);

 IF p_v_job_name_r = 'GRP_LOAD_FCT_BENEFIT_PAYMENT_DETAIL_R_PD'
 THEN
      EXECUTE IMMEDIATE lc_del_final;
      COMMIT;

      EXECUTE IMMEDIATE lc_merge_final;
      COMMIT;
 ELSE
      EXECUTE IMMEDIATE lc_merge_final;
      COMMIT;

      EXECUTE IMMEDIATE lc_del_final;
      COMMIT;
 END IF;

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

PROCEDURE get_singlesrcsys_merge(p_v_job_name_r IN VARCHAR2,lc_VAR_GRP_DIFW_tgt_TBL_NM IN VARCHAR2,lc_get_var_grp_difw_physical_delete IN VARCHAR2)
IS
	lc_char CLOB;
	lc_char1 CLOB;
	lc_clob CLOB;
	v_num_rows_affected number;
	lc_del CLOB;
BEGIN
	gc_trcmsg:=gc_trcmsg||'11.1 Entered into get_singlesrcsys_merge'||chr(13);
     gc_updby:=  'get_singlesrcsys_merge';
	dbms_output.put_line(gc_trcmsg);

	SELECT V_PD_DELETE_QUERY_R
INTO lc_del
FROM PRCS_GRP_DATAINGESTION_PARAM_R
WHERE F_ENABLE_FLAG_R='Y'
AND NVL(V_PARAM_NAME_R,'@~') = p_v_job_name_r;

	SELECT V_MERGE_STATEMENT_1_R INTO lc_char1
	FROM PRCS_GRP_DATAINGESTION_PARAM_R
	WHERE V_PARAM_NAME_R = p_v_job_name_r;

        SELECT replace('INSERT '||INS||CHR(10)||'VALUES '||VAL,',)',')')  INTO lc_char FROM (
        SELECT '('||TRIM((XMLAGG(XMLELEMENT(A,'D.'||COLUMN_NAME ||',')
        ORDER BY COLUMN_ID).EXTRACT('//text()')).getclobval())||gc_auditcols_FACT||')' INS, '('||TRIM((XMLAGG(XMLELEMENT(A,'S.'||COLUMN_NAME ||',')
        ORDER BY COLUMN_ID).EXTRACT('//text()')).getclobval())||gc_auditcol_values_FACT||')' VAL
        FROM ALL_TAB_COLUMNS WHERE TABLE_NAME=lc_VAR_GRP_DIFW_tgt_TBL_NM
        AND owner='ATOMIC'
        AND COLUMN_NAME NOT IN ('T_CREATION_DATE_R','V_CREATED_BY_R','T_LAST_MODIFIED_DATE_R','V_LAST_MODIFIED_BY_R','N_LOAD_RUN_ID_R')
        );



	lc_clob:=lc_char1||' WHEN NOT MATCHED THEN  '||lc_char||'where 1=1 '||lc_get_var_grp_difw_physical_delete;

	gc_trcmsg:='Print lc_clob'||lc_clob||chr(13);
	dbms_output.put_line('11.2 lc_clob :->' || lc_clob);
	gc_trcmsg:='Print 11.3lc_del'||lc_del||chr(13);

	EXECUTE IMMEDIATE lc_clob;

	commit;

	EXECUTE IMMEDIATE lc_del;

	commit;

gc_trcmsg:=gc_trcmsg||'11.z Exit from get_singlesrcsys_merge'||chr(13);
EXCEPTION
WHEN OTHERS THEN
    gc_errmsg:=SUBSTR(SQLERRM,1,4000);
	gc_trcmsg:=gc_trcmsg||'11.z Error in get_singlesrcsys_merge'||chr(13)||gc_errmsg;
    pkg_grp_log_util.prc_update_log
      (
        gn_out_job_id                 --p_job_id
        ,gc_error_status              --p_job_status
        ,gc_errmsg                    --p_err_msg
        ,gc_trcmsg||chr(13)||gc_errmsg--p_trc_msg
        ,gc_updby                     --p_log_util_called_by_r
      );
    RAISE;

END get_singlesrcsys_merge;


END pkg_grp_load_difw_pd;

