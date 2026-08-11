create or replace PROCEDURE PRC_GRP_LOAD_STG_RPT_ANN_PREM_OVERRIDE_R
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

   SELECT TO_NUMBER(TO_CHAR(TRUNC(D_START_DATE_R)+1,'YYYYMMDD')) INTO ln_N_BATCH_ID_R 
   FROM ATOMIC.PRCS_GRP_MONTH_END_CONFIG_R
   WHERE V_TABLE_NAME_R = 'RPT_BATCH_ID';

   SELECT D_CALENDAR_DATE_R +1 INTO ld_fic_mis_date
   FROM DIM_TIME_R D
   WHERE  V_END_OF_FISCAL_MONTH_IND_R = 'Y'
   and to_char(d_calendar_date_r,'YYYYMM')=to_char(ld_sysdate,'YYYYMM');


    SELECT TO_CHAR(ld_sysdate,'DAY')
    INTO LC_DAY
    FROM DUAL;

	IF TO_DATE(ld_fic_mis_date) = TO_DATE(ld_sysdate) --to load data on next day of Fiscal Month (Ex:the fiscal month end for May 2023 is 26-MAY-23 so we should load this on 27-MAY-23)
	OR TRIM(LC_DAY)='SATURDAY'-- or to load data on Saturday
	THEN
        BEGIN
           EXECUTE IMMEDIATE 'DROP TABLE STG_RPT_ANN_PREM_OVERRIDE_R_BKP';
        EXCEPTION
        WHEN OTHERS THEN
        NULL;
        END;

        BEGIN
           EXECUTE IMMEDIATE 'CREATE TABLE STG_RPT_ANN_PREM_OVERRIDE_R_BKP AS SELECT * FROM STG_RPT_ANN_PREM_OVERRIDE_INCR_R';
        EXCEPTION
        WHEN OTHERS THEN
        NULL;
        END;

------------------Change History-----------------------------------------
--Gireesh - Changed the below logic order 10Apr24--
-------------------------------------------------------------------------
        EXECUTE IMMEDIATE 'TRUNCATE TABLE STG_RPT_ANN_PREM_OVERRIDE_INCR_R PURGE SNAPSHOT LOG';

        Insert /*+APPEND*/ into STG_RPT_ANN_PREM_OVERRIDE_INCR_R
        (F_PHYSICAL_DELETE_R, V_CHANGE_REASON_R, V_ACTIVE_STATUS_R, N_CLAIM_SK_R, N_POLICY_SK_R, N_PARTY_SK_R, N_QUOTE_SK_R, D_CYCLE_DATE_R, V_POLICY_NUMBER_R, V_CUSTOMER_BILL_GROUP_R, V_SHORT_NAME_R, V_COVERAGE_CODE_R,
         V_PLAN_TYPE_R, V_CLASS_ID_R, V_DELETE_BY_R, D_TRANSACTION_DATE_R, D_DUE_DATE_R, V_PREMIUM_MODE_R, N_PREMIUM_MODE_FACTOR_R, N_ANNUALIZED_PREMIUM_R, N_GROSS_LIVES_R, N_VOLUME_R, N_COVERAGE_LIVES_R,N_COVERAGE_LEVEL_R,
         N_COVERAGE_VOLUME_R, N_DEPENDENT_LIVES_R, N_DEPENDENT_VOLUME_R, N_POLICY_LIVES_R, N_POLICY_VOLUME_R, N_POLICY_COVERAGE_COUNT_R, N_POLICY_COUNT_R, N_CLIENT_COVERAGE_COUNT_R,  N_CLIENT_LOB_COUNT_R, N_CLIENT_POLICY_COUNT_R, N_CLIENT_LIVES_R, D_YTD_PRIOR_CYCLE_DATE_R,
         N_YTD_PRIOR_PREMIUM_R, N_YTD_PRIOR_LIVES_R, N_YTD_PRIOR_VOLUME_R, N_YTD_PRIOR_COVERAGE_LIVES_R, N_YTD_PRIOR_COVERAGE_VOLUME_R, N_YTD_PRIOR_POLICY_LIVES_R, N_YTD_PRIOR_POLICY_VOLUME_R,
         N_YTD_PRIOR_DEPENDENT_LIVES_R, N_YTD_PRIOR_DEPENDENT_VOLUME_R, N_YTD_PRIOR_POL_COVERAGE_CNT_R, N_YTD_PRIOR_POLICY_COUNT_R, N_YTD_PRIOR_CLIENT_COV_CNT_R, N_YTD_PRIOR_CLIENT_LOB_COUNT_R,
         N_YTD_PRIOR_CLIENT_POL_CNT_R, N_YTD_PRIOR_CLIENT_LIVES_R, N_YTD_CHG_DEPENDENT_LIVES_R, N_YTD_CHG_POLICY_LIVES_R, N_YTD_CHG_POLICY_VOLUME_R, N_YTD_CHG_DEPENDENT_VOLUME_R, N_YTD_CHG_POL_COVERAGE_CNT_R,
         N_YTD_CHG_POLICY_COUNT_R, N_YTD_CHG_CLIENT_COV_CNT_R, N_YTD_CHG_CLIENT_LOB_COUNT_R, N_YTD_CHG_CLIENT_POLICY_CNT_R, N_YTD_CHG_CLIENT_LIVES_R, N_YTD_CHG_PREMIUM_R, N_YTD_CHG_LIVES_R, N_YTD_CHG_VOLUME_R,
         N_YTD_CHG_COVERAGE_LIVES_R, N_YTD_CHG_COVERAGE_VOLUME_R, N_YTD_CURR_DEPENDENT_LIVES_R, N_YTD_CURR_POLICY_LIVES_R, N_YTD_CURR_POLICY_VOLUME_R, N_YTD_CURR_DEPENDENT_VOLUME_R, N_YTD_CURR_POL_COVERAGE_CNT_R,
         N_YTD_CURR_POLICY_COUNT_R, N_YTD_CURR_CLIENT_COV_CNT_R, N_YTD_CURR_CLIENT_LOB_COUNT_R, N_YTD_CURR_CLIENT_POLICY_CNT_R, N_YTD_CURR_CLIENT_LIVES_R, N_YTD_CURR_PREMIUM_R, N_YTD_CURR_LIVES_R, N_YTD_CURR_VOLUME_R,
         N_YTD_CURR_COVERAGE_LIVES_R, N_YTD_CURR_COVERAGE_VOLUME_R, D_QTD_PRIOR_CYCLE_DATE_R, N_QTD_PRIOR_PREMIUM_R, N_QTD_PRIOR_LIVES_R, N_QTD_PRIOR_VOLUME_R, N_QTD_PRIOR_COVERAGE_LIVES_R, N_QTD_PRIOR_COVERAGE_VOLUME_R,
         N_QTD_PRIOR_POLICY_LIVES_R, N_QTD_PRIOR_POLICY_VOLUME_R, N_QTD_PRIOR_DEPENDENT_LIVES_R, N_QTD_PRIOR_DEPENDENT_VOLUME_R, N_QTD_PRIOR_POL_COVERAGE_CNT_R, N_QTD_PRIOR_POLICY_COUNT_R, N_QTD_PRIOR_CLIENT_COV_CNT_R,
         N_QTD_PRIOR_CLIENT_LOB_COUNT_R, N_QTD_PRIOR_CLIENT_POL_CNT_R, N_QTD_PRIOR_CLIENT_LIVES_R, N_QTD_CHG_POLICY_LIVES_R, N_QTD_CHG_POLICY_VOLUME_R, N_QTD_CHG_DEPENDENT_LIVES_R, N_QTD_CHG_DEPENDENT_VOLUME_R,
         N_QTD_CHG_POL_COVERAGE_CNT_R, N_QTD_CHG_POLICY_COUNT_R, N_QTD_CHG_CLIENT_COV_CNT_R, N_QTD_CHG_CLIENT_LOB_COUNT_R, N_QTD_CHG_CLIENT_POLICY_CNT_R, N_QTD_CHG_CLIENT_LIVES_R, N_QTD_CHG_PREMIUM_R, N_QTD_CHG_LIVES_R,
         N_QTD_CHG_VOLUME_R, N_QTD_CHG_COVERAGE_LIVES_R, N_QTD_CHG_COVERAGE_VOLUME_R, N_QTD_CURR_POLICY_LIVES_R, N_QTD_CURR_POLICY_VOLUME_R, N_QTD_CURR_DEPENDENT_LIVES_R, N_QTD_CURR_DEPENDENT_VOLUME_R,
         N_QTD_CURR_POL_COVERAGE_CNT_R, N_QTD_CURR_POLICY_COUNT_R, N_QTD_CURR_CLIENT_COV_CNT_R, N_QTD_CURR_CLIENT_LOB_COUNT_R, N_QTD_CURR_CLIENT_POLICY_CNT_R, N_QTD_CURR_CLIENT_LIVES_R, N_QTD_CURR_PREMIUM_R,
         N_QTD_CURR_LIVES_R, N_QTD_CURR_VOLUME_R, N_QTD_CURR_COVERAGE_LIVES_R, N_QTD_CURR_COVERAGE_VOLUME_R, D_MTD_PRIOR_CYCLE_DATE_R, N_MTD_PRIOR_PREMIUM_R, N_MTD_PRIOR_LIVES_R, N_MTD_PRIOR_VOLUME_R, N_MTD_PRIOR_COVERAGE_LIVES_R, N_MTD_PRIOR_COVERAGE_VOLUME_R, N_MTD_PRIOR_POLICY_LIVES_R, N_MTD_PRIOR_POLICY_VOLUME_R, N_MTD_PRIOR_DEPENDENT_LIVES_R, N_MTD_PRIOR_DEPENDENT_VOLUME_R, N_MTD_PRIOR_POL_COVERAGE_CNT_R, N_MTD_PRIOR_POLICY_COUNT_R, N_MTD_PRIOR_CLIENT_COV_CNT_R, N_MTD_PRIOR_CLIENT_LOB_COUNT_R, N_MTD_PRIOR_CLIENT_POL_CNT_R, N_MTD_PRIOR_CLIENT_LIVES_R, N_MTD_CHG_POLICY_LIVES_R, N_MTD_CHG_POLICY_VOLUME_R, N_MTD_CHG_DEPENDENT_LIVES_R, N_MTD_CHG_DEPENDENT_VOLUME_R, N_MTD_CHG_POL_COVERAGE_CNT_R, N_MTD_CHG_POLICY_COUNT_R,
         N_MTD_CHG_CLIENT_COV_CNT_R, N_MTD_CHG_CLIENT_LOB_COUNT_R, N_MTD_CHG_CLIENT_POLICY_CNT_R, N_MTD_CHG_CLIENT_LIVES_R, N_MTD_CHG_PREMIUM_R, N_MTD_CHG_LIVES_R, N_MTD_CHG_VOLUME_R, N_MTD_CHG_COVERAGE_LIVES_R,
         N_MTD_CHG_COVERAGE_VOLUME_R, N_MTD_CURR_POLICY_LIVES_R, N_MTD_CURR_POLICY_VOLUME_R, N_MTD_CURR_DEPENDENT_LIVES_R, N_MTD_CURR_DEPENDENT_VOLUME_R, N_MTD_CURR_POL_COVERAGE_CNT_R, N_MTD_CURR_POLICY_COUNT_R, N_MTD_CURR_CLIENT_COV_CNT_R, N_MTD_CURR_CLIENT_LOB_COUNT_R, N_MTD_CURR_CLIENT_POLICY_CNT_R, N_MTD_CURR_CLIENT_LIVES_R,
         N_MTD_CURR_PREMIUM_R, N_MTD_CURR_LIVES_R, N_MTD_CURR_VOLUME_R, N_MTD_CURR_COVERAGE_LIVES_R, N_MTD_CURR_COVERAGE_VOLUME_R, N_MTD_CURR_COVERAGE_VOLUME_R_, FIC_MIS_DATE_R
         , N_BATCH_ID_R, T_CREATION_DATE_R, T_EVENT_TIMESTAMP_R, T_LAST_MODIFIED_DATE_R, V_CREATED_BY_R, V_LAST_MODIFIED_BY_R, V_SOURCE_SYSTEM_NAME_R, V_SUBJECT_AREA_TYPE_R, N_VERSION_NUMBER_R, D_RECORD_START_DATE_R, D_RECORD_END_DATE_R,N_SEQUENCE_NUMBER_R
        )
		select a.*,rownum N_SEQUENCE_NUMBER_R
		from (
        select distinct
        Null                        F_PHYSICAL_DELETE_R,
        Null                        V_CHANGE_REASON_R,
        'Y'                         V_ACTIVE_STATUS_R,
        -1                          N_CLAIM_SK_R,
        -1                          N_POLICY_SK_R,
        -1                          N_PARTY_SK_R,
        -1                          N_QUOTE_SK_R,
         (SELECT D_CALENDAR_DATE_R FROM DIM_TIME_R T WHERE T.N_FISCAL_MONTH_R = SUBSTR(CYCLE_YYMM,6,2) AND T.N_FISCAL_YEAR_R = SUBSTR(CYCLE_YYMM,1,4) and T.V_END_OF_FISCAL_MONTH_IND_R = 'Y') D_CYCLE_DATE_R,
        POLICY_PFX || POLICY_SFX                         V_POLICY_NUMBER_R,
        SUB_POLICY || BILL_GROUP_NUMB                    V_CUSTOMER_BILL_GROUP_R,
        COMPANY                                          V_SHORT_NAME_R,
        COVERAGE_CODE                                    V_COVERAGE_CODE_R,
        PLAN_TYPE                                        V_PLAN_TYPE_R,
        PH_CLASS                                         V_CLASS_ID_R,
        Null                                             V_DELETE_BY_R,
        Null                                             D_TRANSACTION_DATE_R,
        DUE_DATE                                         D_DUE_DATE_R,
        BILL_GROUP_MODE                                  V_PREMIUM_MODE_R,
        Null                                             N_PREMIUM_MODE_FACTOR_R,
        PREMIUM                                          N_ANNUALIZED_PREMIUM_R,
        LIVES                                            N_GROSS_LIVES_R,
        VOLUME                                           N_VOLUME_R,
        Null                                             N_COVERAGE_LIVES_R,
        Null                                             N_COVERAGE_LEVEL_R,
        Null                                             N_COVERAGE_VOLUME_R,
        Null                                             N_DEPENDENT_LIVES_R,
        Null                                             N_DEPENDENT_VOLUME_R,
        Null                                             N_POLICY_LIVES_R,
        Null                                             N_POLICY_VOLUME_R,
        Null                                             N_POLICY_COVERAGE_COUNT_R,
        Null                                             N_POLICY_COUNT_R,
        Null                                             N_CLIENT_COVERAGE_COUNT_R,
        Null                                             N_CLIENT_LOB_COUNT_R,
        Null                                             N_CLIENT_POLICY_COUNT_R,
        Null                                             N_CLIENT_LIVES_R,
        Null                                             D_YTD_PRIOR_CYCLE_DATE_R,
        Null                                             N_YTD_PRIOR_PREMIUM_R,
        Null                                             N_YTD_PRIOR_LIVES_R,
        Null                                             N_YTD_PRIOR_VOLUME_R,
        Null                                             N_YTD_PRIOR_COVERAGE_LIVES_R,
        Null                                             N_YTD_PRIOR_COVERAGE_VOLUME_R,
        Null                                             N_YTD_PRIOR_POLICY_LIVES_R,
        Null                                             N_YTD_PRIOR_POLICY_VOLUME_R,
        Null                                             N_YTD_PRIOR_DEPENDENT_LIVES_R,
        Null                                             N_YTD_PRIOR_DEPENDENT_VOLUME_R,
        Null                                             N_YTD_PRIOR_POL_COVERAGE_CNT_R,
        Null                                             N_YTD_PRIOR_POLICY_COUNT_R,
        Null                                             N_YTD_PRIOR_CLIENT_COV_CNT_R,
        Null                                             N_YTD_PRIOR_CLIENT_LOB_COUNT_R,
        Null                                             N_YTD_PRIOR_CLIENT_POL_CNT_R,
        Null                                             N_YTD_PRIOR_CLIENT_LIVES_R,
        Null                                             N_YTD_CHG_DEPENDENT_LIVES_R,
        Null                                             N_YTD_CHG_POLICY_LIVES_R,
        Null                                             N_YTD_CHG_POLICY_VOLUME_R,
        Null                                             N_YTD_CHG_DEPENDENT_VOLUME_R,
        Null                                             N_YTD_CHG_POL_COVERAGE_CNT_R,
        Null                                             N_YTD_CHG_POLICY_COUNT_R,
        Null                                             N_YTD_CHG_CLIENT_COV_CNT_R,
        Null                                             N_YTD_CHG_CLIENT_LOB_COUNT_R,
        Null                                             N_YTD_CHG_CLIENT_POLICY_CNT_R,
        Null                                             N_YTD_CHG_CLIENT_LIVES_R,
        Null                                             N_YTD_CHG_PREMIUM_R,
        Null                                             N_YTD_CHG_LIVES_R,
        Null                                             N_YTD_CHG_VOLUME_R,
        Null                                             N_YTD_CHG_COVERAGE_LIVES_R,
        Null                                             N_YTD_CHG_COVERAGE_VOLUME_R,
        Null                                             N_YTD_CURR_DEPENDENT_LIVES_R,
        Null                                             N_YTD_CURR_POLICY_LIVES_R,
        Null                                             N_YTD_CURR_POLICY_VOLUME_R,
        Null                                             N_YTD_CURR_DEPENDENT_VOLUME_R,
        Null                                             N_YTD_CURR_POL_COVERAGE_CNT_R,
        Null                                             N_YTD_CURR_POLICY_COUNT_R,
        Null                                             N_YTD_CURR_CLIENT_COV_CNT_R,
        Null                                             N_YTD_CURR_CLIENT_LOB_COUNT_R,
        Null                                             N_YTD_CURR_CLIENT_POLICY_CNT_R,
        Null                                             N_YTD_CURR_CLIENT_LIVES_R,
        Null                                             N_YTD_CURR_PREMIUM_R,
        Null                                             N_YTD_CURR_LIVES_R,
        Null                                             N_YTD_CURR_VOLUME_R,
        Null                                             N_YTD_CURR_COVERAGE_LIVES_R,
        Null                                             N_YTD_CURR_COVERAGE_VOLUME_R,
        Null                                             D_QTD_PRIOR_CYCLE_DATE_R,
        Null                                             N_QTD_PRIOR_PREMIUM_R,
        Null                                             N_QTD_PRIOR_LIVES_R,
        Null                                             N_QTD_PRIOR_VOLUME_R,
        Null                                             N_QTD_PRIOR_COVERAGE_LIVES_R,
        Null                                             N_QTD_PRIOR_COVERAGE_VOLUME_R,
        Null                                             N_QTD_PRIOR_POLICY_LIVES_R,
        Null                                             N_QTD_PRIOR_POLICY_VOLUME_R,
        Null                                             N_QTD_PRIOR_DEPENDENT_LIVES_R,
        Null                                             N_QTD_PRIOR_DEPENDENT_VOLUME_R,
        Null                                             N_QTD_PRIOR_POL_COVERAGE_CNT_R,
        Null                                             N_QTD_PRIOR_POLICY_COUNT_R,
        Null                                             N_QTD_PRIOR_CLIENT_COV_CNT_R,
        Null                                             N_QTD_PRIOR_CLIENT_LOB_COUNT_R,
        Null                                             N_QTD_PRIOR_CLIENT_POL_CNT_R,
        Null                                             N_QTD_PRIOR_CLIENT_LIVES_R,
        Null                                             N_QTD_CHG_POLICY_LIVES_R,
        Null                                             N_QTD_CHG_POLICY_VOLUME_R,
        Null                                             N_QTD_CHG_DEPENDENT_LIVES_R,
        Null                                             N_QTD_CHG_DEPENDENT_VOLUME_R,
        Null                                             N_QTD_CHG_POL_COVERAGE_CNT_R,
        Null                                             N_QTD_CHG_POLICY_COUNT_R,
        Null                                             N_QTD_CHG_CLIENT_COV_CNT_R,
        Null                                             N_QTD_CHG_CLIENT_LOB_COUNT_R,
        Null                                             N_QTD_CHG_CLIENT_POLICY_CNT_R,
        Null                                             N_QTD_CHG_CLIENT_LIVES_R,
        Null                                             N_QTD_CHG_PREMIUM_R,
        Null                                             N_QTD_CHG_LIVES_R,
        Null                                             N_QTD_CHG_VOLUME_R,
        Null                                             N_QTD_CHG_COVERAGE_LIVES_R,
        Null                                             N_QTD_CHG_COVERAGE_VOLUME_R,
        Null                                             N_QTD_CURR_POLICY_LIVES_R,
        Null                                             N_QTD_CURR_POLICY_VOLUME_R,
        Null                                             N_QTD_CURR_DEPENDENT_LIVES_R,
        Null                                             N_QTD_CURR_DEPENDENT_VOLUME_R,
        Null                                             N_QTD_CURR_POL_COVERAGE_CNT_R,
        Null                                             N_QTD_CURR_POLICY_COUNT_R,
        Null                                             N_QTD_CURR_CLIENT_COV_CNT_R,
        Null                                             N_QTD_CURR_CLIENT_LOB_COUNT_R,
        Null                                             N_QTD_CURR_CLIENT_POLICY_CNT_R,
        Null                                             N_QTD_CURR_CLIENT_LIVES_R,
        Null                                             N_QTD_CURR_PREMIUM_R,
        Null                                             N_QTD_CURR_LIVES_R,
        Null                                             N_QTD_CURR_VOLUME_R,
        Null                                             N_QTD_CURR_COVERAGE_LIVES_R,
        Null                                             N_QTD_CURR_COVERAGE_VOLUME_R,
        Null                                             D_MTD_PRIOR_CYCLE_DATE_R,
        Null                                             N_MTD_PRIOR_PREMIUM_R,
        Null                                             N_MTD_PRIOR_LIVES_R,
        Null                                             N_MTD_PRIOR_VOLUME_R,
        Null                                             N_MTD_PRIOR_COVERAGE_LIVES_R,
        Null                                             N_MTD_PRIOR_COVERAGE_VOLUME_R,
        Null                                             N_MTD_PRIOR_POLICY_LIVES_R,
        Null                                             N_MTD_PRIOR_POLICY_VOLUME_R,
        Null                                             N_MTD_PRIOR_DEPENDENT_LIVES_R,
        Null                                             N_MTD_PRIOR_DEPENDENT_VOLUME_R,
        Null                                             N_MTD_PRIOR_POL_COVERAGE_CNT_R,
        Null                                             N_MTD_PRIOR_POLICY_COUNT_R,
        Null                                             N_MTD_PRIOR_CLIENT_COV_CNT_R,
        Null                                             N_MTD_PRIOR_CLIENT_LOB_COUNT_R,
        Null                                             N_MTD_PRIOR_CLIENT_POL_CNT_R,
        Null                                             N_MTD_PRIOR_CLIENT_LIVES_R,
        Null                                             N_MTD_CHG_POLICY_LIVES_R,
        Null                                             N_MTD_CHG_POLICY_VOLUME_R,
        Null                                             N_MTD_CHG_DEPENDENT_LIVES_R,
        Null                                             N_MTD_CHG_DEPENDENT_VOLUME_R,
        Null                                             N_MTD_CHG_POL_COVERAGE_CNT_R,
        Null                                             N_MTD_CHG_POLICY_COUNT_R,
        Null                                             N_MTD_CHG_CLIENT_COV_CNT_R,
        Null                                             N_MTD_CHG_CLIENT_LOB_COUNT_R,
        Null                                             N_MTD_CHG_CLIENT_POLICY_CNT_R,
        Null                                             N_MTD_CHG_CLIENT_LIVES_R,
        Null                                             N_MTD_CHG_PREMIUM_R,
        Null                                             N_MTD_CHG_LIVES_R,
        Null                                             N_MTD_CHG_VOLUME_R,
        Null                                             N_MTD_CHG_COVERAGE_LIVES_R,
        Null                                             N_MTD_CHG_COVERAGE_VOLUME_R,
        Null                                             N_MTD_CURR_POLICY_LIVES_R,
        Null                                             N_MTD_CURR_POLICY_VOLUME_R,
        Null                                             N_MTD_CURR_DEPENDENT_LIVES_R,
        Null                                             N_MTD_CURR_DEPENDENT_VOLUME_R,
        Null                                             N_MTD_CURR_POL_COVERAGE_CNT_R,
        Null                                             N_MTD_CURR_POLICY_COUNT_R,
        Null                                             N_MTD_CURR_CLIENT_COV_CNT_R,
        Null                                             N_MTD_CURR_CLIENT_LOB_COUNT_R,
        Null                                             N_MTD_CURR_CLIENT_POLICY_CNT_R,
        Null                                             N_MTD_CURR_CLIENT_LIVES_R,
        Null                                             N_MTD_CURR_PREMIUM_R,
        Null                                             N_MTD_CURR_LIVES_R,
        Null                                             N_MTD_CURR_VOLUME_R,
        Null                                             N_MTD_CURR_COVERAGE_LIVES_R,
        Null                                             N_MTD_CURR_COVERAGE_VOLUME_R,
        Null                                             N_MTD_CURR_COVERAGE_VOLUME_R_,
         --'31-Aug-22'
         (ld_fic_mis_date-1)                             FIC_MIS_DATE_R ,
         --202208310000
        TO_NUMBER(TO_CHAR(SYSDATE,'YYYYMMDD'))            N_BATCH_ID_R,
        --rownum
        ld_sysdate                                       T_CREATION_DATE_R,
        --systimestamp
        lt_systimestamp                                  T_EVENT_TIMESTAMP_R,
        ld_sysdate                                       T_LAST_MODIFIED_DATE_R,
        --'History'
        --'History'
        'PRC_GRP_LOAD_STG_RPT_ANN_PREM_OVERRIDE_R'    V_CREATED_BY_R,
        'PRC_GRP_LOAD_STG_RPT_ANN_PREM_OVERRIDE_R'    V_LAST_MODIFIED_BY_R,
        'TPA'                                         V_SOURCE_SYSTEM_NAME_R,
        NULL                                          V_SUBJECT_AREA_TYPE_R,
        0                                             N_VERSION_NUMBER_R,
        sysdate                                       D_RECORD_START_DATE_R,
        '31-DEC-99'     --checked with Erica .. this hard coded value 31-DEC-99 is fine
		 D_RECORD_END_DATE_R
        from sdmstage.PERF_ANNUALIZED_PREMIUM_ADJ@EDW_SDMSTAGE.RSLI.COM
		) A;

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
										VALUES('GRP_LOAD_STG_RPT_ANN_PREM_OVERRIDE_INCR_R'
										      ,'PRC_GRP_LOAD_STG_RPT_ANN_PREM_OVERRIDE_R'
											  ,NULL
											  ,NULL
											  ,'Error in PRC_GRP_LOAD_STG_RPT_ANN_PREM_OVERRIDE_R :->'||LC_SQLCODE||'->'||LC_SQLERRM
											  ,ln_N_BATCH_ID_R
											  ,'PRC_GRP_LOAD_STG_RPT_ANN_PREM_OVERRIDE_R'
											  ,'PRC_GRP_LOAD_STG_RPT_ANN_PREM_OVERRIDE_R'
										);

commit;
raise_application_error(-20001,'Error in PRC_GRP_LOAD_STG_RPT_ANN_PREM_OVERRIDE_R:->'||SQLERRM);
END PRC_GRP_LOAD_STG_RPT_ANN_PREM_OVERRIDE_R;