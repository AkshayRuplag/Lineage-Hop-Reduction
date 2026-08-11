create or replace PROCEDURE PRC_GRP_LOAD_STG_RPT_ANN_PREM_EXCLUSION_R
IS
LC_SQLCODE VARCHAR2(300);
LC_DAY VARCHAR2(300);
LC_SQLERRM VARCHAR2(4000);
ld_fic_mis_date DIM_TIME_R.D_CALENDAR_DATE_R%TYPE;
ld_sysdate DATE;
lt_systimestamp TIMESTAMP:=SYSDATE;
ln_N_BATCH_ID_R NUMBER;
BEGIN

   SELECT TRUNC(D_START_DATE_R)+1 INTO ld_sysdate 
   FROM ATOMIC.PRCS_GRP_MONTH_END_CONFIG_R
   WHERE V_TABLE_NAME_R = 'RPT_BATCH_ID';

   SELECT D_CALENDAR_DATE_R +1 INTO ld_fic_mis_date
   FROM DIM_TIME_R D 
   WHERE  V_END_OF_FISCAL_MONTH_IND_R = 'Y'
   and to_char(d_calendar_date_r,'YYYYMM')=to_char(ld_sysdate,'YYYYMM');

   SELECT TO_NUMBER(TO_CHAR(TRUNC(D_START_DATE_R)+1,'YYYYMMDD')) INTO ln_N_BATCH_ID_R 
   FROM ATOMIC.PRCS_GRP_MONTH_END_CONFIG_R
   WHERE V_TABLE_NAME_R = 'RPT_BATCH_ID';


    SELECT TO_CHAR(ld_sysdate,'DAY')
    INTO LC_DAY
    FROM DUAL;

	IF TO_DATE(ld_fic_mis_date) = TO_DATE(ld_sysdate) --to load data on next day of Fiscal Month (Ex:the fiscal month end for May 2023 is 26-MAY-23 so we should load this on 27-MAY-23)
	OR TRIM(LC_DAY)='SATURDAY'-- or to load data on Saturday
	THEN
        BEGIN
           EXECUTE IMMEDIATE 'DROP TABLE STG_RPT_ANN_PREM_EXCLUSION_R_BKP';
        EXCEPTION
        WHEN OTHERS THEN
        NULL;
        END;

        BEGIN
           EXECUTE IMMEDIATE 'CREATE TABLE STG_RPT_ANN_PREM_EXCLUSION_R_BKP AS SELECT * FROM STG_RPT_ANN_PREM_EXCLUSION_INCR_R';
        EXCEPTION
        WHEN OTHERS THEN
        NULL;
        END;


        EXECUTE IMMEDIATE 'TRUNCATE TABLE STG_RPT_ANN_PREM_EXCLUSION_INCR_R PURGE SNAPSHOT LOG';

        Insert /*+APPEND*/ into STG_RPT_ANN_PREM_EXCLUSION_INCR_R
        (D_CYCLE_DATE_R, V_POLICY_NUMBER_R, V_CUSTOMER_BILL_GROUP_R, V_COVERAGE_CODE_R, V_PLAN_TYPE_R, V_CLASS_ID_R, D_TRANSACTION_DATE_R, D_DUE_DATE_R, FIC_MIS_DATE_R, N_BATCH_ID_R, N_SEQUENCE_NUMBER_R,
        T_CREATION_DATE_R, T_EVENT_TIMESTAMP_R, T_LAST_MODIFIED_DATE_R, V_CREATED_BY_R, V_LAST_MODIFIED_BY_R, V_SOURCE_SYSTEM_NAME_R, V_SUBJECT_AREA_TYPE_R, N_VERSION_NUMBER_R, D_RECORD_START_DATE_R, 
        D_RECORD_END_DATE_R, F_PHYSICAL_DELETE_R, V_CHANGE_REASON_R, V_ACTIVE_STATUS_R, N_CLAIM_SK_R, N_POLICY_SK_R, N_PARTY_SK_R, N_QUOTE_SK_R)
        select D_CYCLE_DATE_R, V_POLICY_NUMBER_R, V_CUSTOMER_BILL_GROUP_R, V_COVERAGE_CODE_R, V_PLAN_TYPE_R, V_CLASS_ID_R, D_TRANSACTION_DATE_R, D_DUE_DATE_R, FIC_MIS_DATE_R, N_BATCH_ID_R, rownum N_SEQUENCE_NUMBER_R,
        T_CREATION_DATE_R, T_EVENT_TIMESTAMP_R, T_LAST_MODIFIED_DATE_R, V_CREATED_BY_R, V_LAST_MODIFIED_BY_R, V_SOURCE_SYSTEM_NAME_R, V_SUBJECT_AREA_TYPE_R, N_VERSION_NUMBER_R, D_RECORD_START_DATE_R, 
        D_RECORD_END_DATE_R, F_PHYSICAL_DELETE_R, V_CHANGE_REASON_R, V_ACTIVE_STATUS_R, N_CLAIM_SK_R, N_POLICY_SK_R, N_PARTY_SK_R, N_QUOTE_SK_R from
        (select distinct 
         (SELECT D_CALENDAR_DATE_R FROM DIM_TIME_R T WHERE T.N_FISCAL_MONTH_R = SUBSTR(CYCLE_YYMM,6,2) AND T.N_FISCAL_YEAR_R = SUBSTR(CYCLE_YYMM,1,4) and T.V_END_OF_FISCAL_MONTH_IND_R = 'Y') D_CYCLE_DATE_R, 
         case when pacs_lob_code = 'MAL' then pacs_lob_code else policy_prefix end||policy_suffix V_POLICY_NUMBER_R, 
         SUB_POLICY || BILL_GROUP_NUMB V_CUSTOMER_BILL_GROUP_R, 
         COVERAGE_CODE V_COVERAGE_CODE_R, 
         NULL V_PLAN_TYPE_R,
         NULL V_CLASS_ID_R,
         NULL D_TRANSACTION_DATE_R,
         NULL D_DUE_DATE_R,
         (ld_fic_mis_date-1) FIC_MIS_DATE_R, 
         TO_NUMBER(TO_CHAR(SYSDATE,'YYYYMMDD')) N_BATCH_ID_R,
        -- rownum N_SEQUENCE_NUMBER_R,
         ld_sysdate T_CREATION_DATE_R, 
         lt_systimestamp T_EVENT_TIMESTAMP_R, 
         ld_sysdate T_LAST_MODIFIED_DATE_R, 
         'PRC_GRP_LOAD_STG_RPT_ANN_PREM_EXCLUSION_R' V_CREATED_BY_R, 
        'PRC_GRP_LOAD_STG_RPT_ANN_PREM_EXCLUSION_R' V_LAST_MODIFIED_BY_R,
        'TPA' V_SOURCE_SYSTEM_NAME_R, 
        NULL V_SUBJECT_AREA_TYPE_R, 
        0 N_VERSION_NUMBER_R, 
        sysdate D_RECORD_START_DATE_R, 
        '31-DEC-99' D_RECORD_END_DATE_R,--checked with Erica .. this hard coded value 31-DEC-99 is fine
        NULL F_PHYSICAL_DELETE_R ,
        NULL V_CHANGE_REASON_R , 
        'Y' V_ACTIVE_STATUS_R,
        -1 N_CLAIM_SK_R,
        -1 N_POLICY_SK_R,
        -1 N_PARTY_SK_R,
        -1 N_QUOTE_SK_R
        from sdmstage.PERF_ANNUALIZED_PREMIUM_EXCL@EDW_SDMSTAGE.RSLI.COM ex
        inner join
        (select distinct policy_prefix, policy_suffix , pacs_lob_code
        from sdmstage.customer_dim@EDW_SDMSTAGE.RSLI.COM
        where snapshot_id = 1) c
        on ex.policy_pfx = c.policy_prefix
        and ex.policy_sfx = c.policy_suffix
        );

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
										VALUES('GRP_LOAD_STG_RPT_ANN_PREM_EXCLUSION_INCR_R' 
										      ,'PRC_GRP_LOAD_STG_RPT_ANN_PREM_EXCLUSION_R'
											  ,NULL
											  ,NULL
											  ,'Error in PRC_GRP_LOAD_STG_RPT_ANN_PREM_EXCLUSION_R :->'||LC_SQLCODE||'->'||LC_SQLERRM
											  ,ln_N_BATCH_ID_R
											  ,'PRC_GRP_LOAD_STG_RPT_ANN_PREM_EXCLUSION_R'
											  ,'PRC_GRP_LOAD_STG_RPT_ANN_PREM_EXCLUSION_R'
										);

commit;
raise_application_error(-20001,'Error in PRC_GRP_LOAD_STG_RPT_ANN_PREM_EXCLUSION_R:->'||SQLERRM);
END PRC_GRP_LOAD_STG_RPT_ANN_PREM_EXCLUSION_R;