

  CREATE OR REPLACE EDITIONABLE PROCEDURE "ATOMIC"."PRC_GRP_LOAD_FCT_BILLING_POLICY_PREMIUM_R_TABLE"
IS
--14-Aug-2023 : Day logic query has been added
--07-Feb-2024 : Disabled weekly,saturday logic to run the job daily and some hints added blocks commented to improve the performance
LC_SQLCODE VARCHAR2(300);
LC_SQLERRM VARCHAR2(4000);
--ld_fic_mis_date DIM_TIME_R.D_CALENDAR_DATE_R%TYPE;--07-Feb-2024 changes
--ld_sysdate DATE:=SYSDATE;--07-Feb-2024 changes
--lt_systimestamp TIMESTAMP:=SYSDATE;--07-Feb-2024 changes
ln_N_BATCH_ID_R NUMBER:=TO_NUMBER(TO_CHAR(SYSDATE,'YYYYMMDD'));
LC_FINAL_ERRM VARCHAR2(4000);
LC_EXCEPTION EXCEPTION;

gn_out_job_id number;

--LC_DAY VARCHAR2(30);--07-Feb-2024 changes
BEGIN

   /*--07-Feb-2024 changes starts commented
   SELECT D_CALENDAR_DATE_R +1 INTO ld_fic_mis_date
   FROM DIM_TIME_R D
   WHERE  V_END_OF_FISCAL_MONTH_IND_R = 'Y'
   and to_char(d_calendar_date_r,'YYYYMM')=to_char(sysdate,'YYYYMM');
   --14-Aug-2023 changes starts
   SELECT TO_CHAR(SYSDATE,'DAY')
     INTO LC_DAY
     FROM DUAL;
   --14-Aug-2023 changes ends
   */--07-Feb-2024 changes ends commented

	/*IF TO_DATE(LD_FIC_MIS_DATE) = TO_DATE(LD_SYSDATE) --to load data on next day of Fiscal Month (Ex:the fiscal month end for May 2023 is 26-MAY-23 so we should load this on 27-MAY-23)
	OR TRIM(LC_DAY)='SATURDAY'-- or to load data on Saturday
	THEN*/--07-Feb-2024 changes commented
        BEGIN
           EXECUTE IMMEDIATE 'DROP TABLE FCT_BILLING_POLICY_PREMIUM_R_TABLE_TMP';
        EXCEPTION
        WHEN OTHERS THEN
        NULL;
        END;

        BEGIN
           DBMS_STATS.GATHER_TABLE_STATS('ATOMIC','FCT_BILLING_POLICY_PREMIUM_R');
        EXCEPTION
        WHEN OTHERS THEN
        NULL;
        END;

		BEGIN
           --07-feb-2024 Parallel hent added
		   EXECUTE IMMEDIATE 'CREATE TABLE FCT_BILLING_POLICY_PREMIUM_R_TABLE_TMP AS
                              SELECT /*+PARALLEL(4)*/
                              NVL(MAX(N_SRC_NET_PREMIUM_ID_R),9999) AS N_SRC_NET_PREMIUM_ID_R,
                              N_SRC_PREMIUM_PAYMENT_ID_R
                              FROM
                              ATOMIC.FCT_BILLING_POLICY_PREMIUM_R
                              WHERE ATOMIC.FCT_BILLING_POLICY_PREMIUM_R.V_PREM_PAYMENT_DELETE_BY_R IS NULL
                              GROUP BY N_SRC_PREMIUM_PAYMENT_ID_R'
							  ;
        EXCEPTION
        WHEN OTHERS THEN
        LC_SQLCODE:=SQLCODE;
		LC_SQLERRM:=SUBSTR(SQLERRM,1,3000);
		LC_FINAL_ERRM:='Error Occured while Creating FCT_BILLING_POLICY_PREMIUM_R_TABLE_TMP Table :->'||LC_SQLCODE||'-'||LC_SQLERRM;
        RAISE LC_EXCEPTION;
        END;

        BEGIN
           EXECUTE IMMEDIATE 'CREATE INDEX FCT_BILLING_POLICY_PREMIUM_R_TABLE_TMP_IDX1 ON FCT_BILLING_POLICY_PREMIUM_R_TABLE_TMP(N_SRC_NET_PREMIUM_ID_R)';
        EXCEPTION
        WHEN OTHERS THEN
        LC_SQLCODE:=SQLCODE;
		LC_SQLERRM:=SUBSTR(SQLERRM,1,3000);
		LC_FINAL_ERRM:='Error Occured while Creating FCT_BILLING_POLICY_PREMIUM_R_TABLE_TMP_IDX1 Index :->'||LC_SQLCODE||'-'||LC_SQLERRM;
        RAISE LC_EXCEPTION;
        END;

        /*BEGIN
           DBMS_STATS.GATHER_TABLE_STATS('ATOMIC','FCT_BILLING_POLICY_PREMIUM_R_TABLE_TMP');
        EXCEPTION
        WHEN OTHERS THEN
        NULL;
        END;*/--07-Feb-2024 chaneges commented

        /*BEGIN
           EXECUTE IMMEDIATE 'DROP TABLE FCT_BILLING_POLICY_PREMIUM_R_TABLE_BKP';
        EXCEPTION
        WHEN OTHERS THEN
        NULL;
        END;

        BEGIN
           EXECUTE IMMEDIATE 'CREATE TABLE FCT_BILLING_POLICY_PREMIUM_R_TABLE_BKP AS SELECT * FROM FCT_BILLING_POLICY_PREMIUM_R_TABLE';
        EXCEPTION
        WHEN OTHERS THEN
        LC_SQLCODE:=SQLCODE;
		LC_SQLERRM:=SUBSTR(SQLERRM,1,3000);
		LC_FINAL_ERRM:='Error Occured while Creating FCT_BILLING_POLICY_PREMIUM_R_TABLE_BKP Table :->'||LC_SQLCODE||'-'||LC_SQLERRM;
        RAISE LC_EXCEPTION;
        END;*/--07-Feb-2024 changes commented to improve the perfromance of the job

        BEGIN
           EXECUTE IMMEDIATE 'TRUNCATE TABLE FCT_BILLING_POLICY_PREMIUM_R_TABLE PURGE SNAPSHOT LOG';
        EXCEPTION
        WHEN OTHERS THEN
        LC_SQLCODE:=SQLCODE;
		LC_SQLERRM:=SUBSTR(SQLERRM,1,3000);
		LC_FINAL_ERRM:='Error Occured while Truncating FCT_BILLING_POLICY_PREMIUM_R_TABLE Table :->'||LC_SQLCODE||'-'||LC_SQLERRM;
        RAISE LC_EXCEPTION;

        END;
		PKG_GRP_COMMON_UTIL.prc_force_indexes_unusable
		(
		p_out_job_id   		  		  => gn_out_job_id,
		p_rpt_table			   		  => 'FCT_BILLING_POLICY_PREMIUM_R_TABLE',
		p_Log_seq_num             	  => 1
		);

        BEGIN
		  --07-Feb-2024 changes replaced APPEND hint with APPEND_VALUES and added PARALLEL hint
          EXECUTE IMMEDIATE '  Insert /*+APPEND_VALUES*/ into FCT_BILLING_POLICY_PREMIUM_R_TABLE
             SELECT /*+PARALLEL(4)*/ P.* FROM FCT_BILLING_POLICY_PREMIUM_R P
             ,            ATOMIC.FCT_BILLING_POLICY_PREMIUM_R_TABLE_TMP A
             where P.N_SRC_PREMIUM_PAYMENT_ID_R = A.N_SRC_PREMIUM_PAYMENT_ID_R
            AND NVL(P.N_SRC_NET_PREMIUM_ID_R,9999) = A.N_SRC_NET_PREMIUM_ID_R';

            commit;
        EXCEPTION
        WHEN OTHERS THEN
        LC_SQLCODE:=SQLCODE;
		LC_SQLERRM:=SUBSTR(SQLERRM,1,3000);
		LC_FINAL_ERRM:='Error Occured while inserting data into FCT_BILLING_POLICY_PREMIUM_R_TABLE Table :->'||LC_SQLCODE||'-'||LC_SQLERRM;
        RAISE LC_EXCEPTION;
        END;

		PKG_GRP_COMMON_UTIL.prc_rebuild_indexes
		(
		p_out_job_id   		  		  => gn_out_job_id,
		p_rpt_table			   		  => 'FCT_BILLING_POLICY_PREMIUM_R_TABLE',
		p_idx_num		  		  	  => 8,
		p_Log_seq_num             	  => 1
		);

		PKG_GRP_COMMON_UTIL.prc_set_global_idx_to_no_parallel
		(
		p_table_name   		  		  => 'FCT_BILLING_POLICY_PREMIUM_R_TABLE',
		p_degree			   		  => 1,
		p_out_job_id             	  => gn_out_job_id,
		p_Log_seq_num				  => 1
		);

  --END IF;--07-Feb-2024 changes
EXCEPTION
 WHEN LC_EXCEPTION THEN
       INSERT INTO ATOMIC.PRCS_GRP_TBL_LOAD_DEBUG_TRC(V_JOB_NAME_R
                                               ,V_PKG_PRC_NAME_R
                                               ,N_SK_R
                                               ,V_NUMBER_R
                                               ,V_TRC_MSG_R
                                               ,N_BATCH_ID_R
                                               ,v_created_by_r
                                               ,V_LAST_MODIFIED_BY_R
                                              )
										VALUES('GRP_LOAD_FCT_BILLING_POLICY_PREMIUM_R_TABLE'
										      ,'PRC_GRP_LOAD_FCT_BILLING_POLICY_PREMIUM_R_TABLE'
											  ,NULL
											  ,NULL
											  ,'Custom Exception raised in PRC_GRP_LOAD_FCT_BILLING_POLICY_PREMIUM_R_TABLE :->'||LC_FINAL_ERRM
											  ,ln_N_BATCH_ID_R
											  ,'PRC_GRP_LOAD_FCT_BILLING_POLICY_PREMIUM_R_TABLE'
											  ,'PRC_GRP_LOAD_FCT_BILLING_POLICY_PREMIUM_R_TABLE'
										);

    commit;
    raise_application_error(-20001,'Custom-Error in PRC_GRP_LOAD_FCT_BILLING_POLICY_PREMIUM_R_TABLE:->'||LC_FINAL_ERRM);
WHEN OTHERS THEN
LC_SQLCODE:=SQLCODE;
LC_SQLERRM:=SUBSTR(SQLERRM,1,4000);
--OUT_LOAD_STATUS:=LC_SQLCODE||'-'||LC_SQLERRM;
--GC_TRC_MSG:='Final Error Message:->'||LC_SQLCODE||'-'||LC_SQLERRM;
INSERT INTO ATOMIC.PRCS_GRP_TBL_LOAD_DEBUG_TRC(V_JOB_NAME_R
                                               ,V_PKG_PRC_NAME_R
                                               ,N_SK_R
                                               ,V_NUMBER_R
                                               ,V_TRC_MSG_R
                                               ,N_BATCH_ID_R
                                               ,v_created_by_r
                                               ,V_LAST_MODIFIED_BY_R
                                              )
										VALUES('GRP_LOAD_FCT_BILLING_POLICY_PREMIUM_R_TABLE'
										      ,'PRC_GRP_LOAD_FCT_BILLING_POLICY_PREMIUM_R_TABLE'
											  ,NULL
											  ,NULL
											  ,'When others raised in PRC_GRP_LOAD_FCT_BILLING_POLICY_PREMIUM_R_TABLE :->'||LC_SQLCODE||'->'||LC_SQLERRM
											  ,ln_N_BATCH_ID_R
											  ,'PRC_GRP_LOAD_FCT_BILLING_POLICY_PREMIUM_R_TABLE'
											  ,'PRC_GRP_LOAD_FCT_BILLING_POLICY_PREMIUM_R_TABLE'
										);

commit;
raise_application_error(-20001,'Others-Error in PRC_GRP_LOAD_FCT_BILLING_POLICY_PREMIUM_R_TABLE:->'||SQLERRM);

END PRC_GRP_LOAD_FCT_BILLING_POLICY_PREMIUM_R_TABLE;

