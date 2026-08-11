create or replace PROCEDURE PRC_GRP_LOAD_STG_ANN_PREM_CUSTOMER_LINK_R
IS
LC_SQLCODE VARCHAR2(300);
LC_DAY VARCHAR2(300);
LC_SQLERRM VARCHAR2(4000);
ld_fic_mis_date DIM_TIME_R.D_CALENDAR_DATE_R%TYPE;
ld_sysdate DATE:=SYSDATE;
lt_systimestamp TIMESTAMP:=SYSDATE;
ln_N_BATCH_ID_R NUMBER:=TO_NUMBER(TO_CHAR(SYSDATE,'YYYYMMDD'));
BEGIN

   SELECT D_CALENDAR_DATE_R +1 INTO ld_fic_mis_date
   FROM DIM_TIME_R D
   WHERE  V_END_OF_FISCAL_MONTH_IND_R = 'Y'
   and to_char(d_calendar_date_r,'YYYYMM')=to_char(sysdate,'YYYYMM');


    SELECT TO_CHAR(SYSDATE,'DAY')
    INTO LC_DAY
    FROM DUAL;

	IF TO_DATE(ld_fic_mis_date) = TO_DATE(ld_sysdate) --to load data on next day of Fiscal Month (Ex:the fiscal month end for May 2023 is 26-MAY-23 so we should load this on 27-MAY-23)
	OR TRIM(LC_DAY)='SATURDAY'-- or to load data on Saturday
	THEN
        BEGIN
           EXECUTE IMMEDIATE 'DROP TABLE STG_ANN_PREM_CUSTOMER_LINK_R_BKP';
        EXCEPTION
        WHEN OTHERS THEN
        NULL;
        END;

        BEGIN
           EXECUTE IMMEDIATE 'CREATE TABLE STG_ANN_PREM_CUSTOMER_LINK_R_BKP AS SELECT * FROM STG_ANN_PREM_CUSTOMER_LINK_INCR_R';
        EXCEPTION
        WHEN OTHERS THEN
        NULL;
        END;


        EXECUTE IMMEDIATE 'TRUNCATE TABLE STG_ANN_PREM_CUSTOMER_LINK_INCR_R PURGE SNAPSHOT LOG';

        Insert /*+APPEND*/ into STG_ANN_PREM_CUSTOMER_LINK_INCR_R
        select orig_customer_key N_ORIG_CUSTOMER_KEY_R,
        orig_policy_prefix V_ORIG_POLICY_PREFIX_R,
        ORIG_POLICY_SUFFIX V_ORIG_POLICY_SUFFIX_R,
        NEW_CUSTOMER_KEY N_NEW_CUSTOMER_KEY_R,
        NEW_POLICY_PREFIX V_NEW_POLICY_PREFIX_R,
        NEW_POLICY_SUFFIX V_NEW_POLICY_SUFFIX_R,
        (ld_fic_mis_date-1) FIC_MIS_DATE_R,
        ln_N_BATCH_ID_R N_BATCH_ID_R,
        rownum N_SEQUENCE_NUMBER_R,
        ld_sysdate T_CREATION_DATE_R,
        ld_sysdate T_EVENT_TIMESTAMP_R,
        ld_sysdate T_LAST_MODIFIED_DATE_R,
        'PRC_GRP_LOAD_STG_ANN_PREM_CUSTOMER_LINK_R' V_CREATED_BY_R,
        'PRC_GRP_LOAD_STG_ANN_PREM_CUSTOMER_LINK_R' V_LAST_MODIFIED_BY_R,
        'TPA' V_SOURCE_SYSTEM_NAME_R,
        '' V_SUBJECT_AREA_TYPE_R,
        0 N_VERSION_NUMBER_R,
        sysdate D_RECORD_START_DATE_R,
        '31-DEC-99' D_RECORD_END_DATE_R,--checked with Erica .. this hard coded value 31-DEC-99 is fine
        '' F_PHYSICAL_DELETE_R,
        '' V_CHANGE_REASON_R,
        'Y' V_ACTIVE_STATUS_R,
        -1 N_CLAIM_SK_R,
        -1 N_POLICY_SK_R,
        -1 N_PARTY_SK_R,
        -1 N_QUOTE_SK_R
        from
        RDM.PERF_ANN_PREM_CUSTOMER_LINK@report.rsli.com;

        commit;
    END IF;
EXCEPTION
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
										VALUES('GRP_LOAD_STG_ANN_PREM_CUSTOMER_LINK_INCR_R'
										      ,'PRC_GRP_LOAD_STG_ANN_PREM_CUSTOMER_LINK_R'
											  ,NULL
											  ,NULL
											  ,'Error in PRC_GRP_LOAD_STG_ANN_PREM_CUSTOMER_LINK_R :->'||LC_SQLCODE||'->'||LC_SQLERRM
											  ,ln_N_BATCH_ID_R
											  ,'PRC_GRP_LOAD_STG_ANN_PREM_CUSTOMER_LINK_R'
											  ,'PRC_GRP_LOAD_STG_ANN_PREM_CUSTOMER_LINK_R'
										);

commit;
raise_application_error(-20001,'Error in PRC_GRP_LOAD_STG_ANN_PREM_CUSTOMER_LINK_R:->'||SQLERRM);
END PRC_GRP_LOAD_STG_ANN_PREM_CUSTOMER_LINK_R;