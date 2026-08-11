create or replace package body               PKG_GRP_FULLLOAD_FCT_CLAIM_PAYMENT_DETAIL_R
IS
/* *********************************************************************************************************************************
* Type -            PLSQL Package
* Name -            PKG_GRP_FULLLOAD_FCT_CLAIM_PAYMENT_DETAIL_R
* Owner -           ATOMIC
* Description -     This package has the PLSQL procedures used to populate the Group tables, called by ODI wrappers.
* Created on -      05-Apr-2021
* Last Updated on - 08-Apr-2022 : Claim Coverage columns and joins has been added in all 4 queries
                    22-Apr-2022 : added FCT_GRP_REDIRECT_PAYMENT_R.N_EXT_SUB_SEQUENCE_R n_SEQ_R in Redirect query
                    26-Apr-2022 : Updated Erica requested changes in Gross Benefit and Adjustment query
                    26-Apr-2022 : Commented BatchID param and added gather table and index stats for full load
                    06-May-2022 : Changes in Adjustment query
                    11-May-2022 : Mohan requested Changes in Benefit Payment query
                    12-May-2022 : Erica requested Changes in Expense query
                    21-May-2022 : Erica requested Changes in Gross Benefit query
                    06-Jun-2022 : Erica requested Changes in Gross Benefit query for GPL
                    08-Jun-2022 : Mohan requested Changes in Redirect query for GPL
                    08-Jun-2022 : Commented GET_N_GROSS_AMOUNT_R,PRC_GRP_UPD_N_GROSS_AMOUNT_R_FCT_CLAIM_PMT_DET_R
                    08-Jun-2022 : Added truncate partition procedure insetad of DELETE
                    24-Jun-2022 : Erica Changes in expense query
                    05-Oct-2022 : Erica changes in Adjustment query
                    24-Oct-2022 : Gross Benefit and Benefit Payment has been changed to Bulk Collect and Bulk Bind
					04-Nov-2022 : As requested by Karim splitted FCT_CLAIM_PAYMENT_DETAIL_R into below 5 tables in the pkg used the below 5 tables
					             dropped the actual FCT_CLAIM_PAYMENT_DETAIL_R and created below view with same name as FCT_CLAIM_PAYMENT_DETAIL_R.
								             FCT_CLAIM_PAYMENT_DETAIL_GROSS_BENEFIT_R
                                             FCT_CLAIM_PAYMENT_DETAIL_BENEFIT_PAYMENT_R
                                             FCT_CLAIM_PAYMENT_DETAIL_ADJUSTMENT_R
                                             FCT_CLAIM_PAYMENT_DETAIL_DISBURSEMENT_R
                                             FCT_CLAIM_PAYMENT_DETAIL_EXPENSE_R
                                  create view fct_claim_payment_detail_r
                                  AS
                                  select * from FCT_CLAIM_PAYMENT_DETAIL_GROSS_BENEFIT_R       union
                                  select * from FCT_CLAIM_PAYMENT_DETAIL_BENEFIT_PAYMENT_R     union
                                  select * from FCT_CLAIM_PAYMENT_DETAIL_ADJUSTMENT_R  union
                                  select * from FCT_CLAIM_PAYMENT_DETAIL_DISBURSEMENT_R union
                                  select * from FCT_CLAIM_PAYMENT_DETAIL_EXPENSE_R;
                    --05-Dec-2022 As per Erica selected Max (Claim Coverage sk) in Disbursement driving select query
                    --06-dEC-2022 Benefit Payment and Gross Benefit passed source system as PACS to stop shinka data full load
                                  for Shinka CV will be having different full load pkg
					--27-Feb-2023: As requested by Erica populated column N_CLAIM_COVERAGE_GROUP_SK_R with value -1
					--27-SEP-2023: Added Payee cols and V_PAYEE_TYPE_R to claim_payment_deatils as per Erica's request
					--12-MAR-2024 : Added N_PARTY_SK_R in 	FCT_CLAIM_PAYMENT_DETAIL_ADJUSTMENT_R
															FCT_CLAIM_PAYMENT_DETAIL_DISBURSEMENT_R
															FCT_CLAIM_PAYMENT_DETAIL_EXPENSE_R
                    --29-May-2024 : For SSL added below columns in BENEFIT_PAYMENT,GROSS_BENEFIT , adjustment,expense
					                V_AMOUNT_TYPE_SUB_NAME_R,
					                V_AMOUNT_TYPE_CATEGORY_R,
					                V_AMOUNT_TYPE_CATEGORY_DESC_R,
					                V_AMOUNT_TYPE_SUB_CATEGORY_R,
					                V_AMT_TYPE_SUB_CATEGORY_DESC_R,
					                V_AMOUNT_TYPE_CODE_R,
					                V_AMOUNT_TYPE_NAME_R,
					                V_AMOUNT_TYPE_SUB_CODE_R
								note: BENEFIT_PAYMENT,GROSS_BENEFIT  full loads we have DL framework to make sure code should be in sync in all places hence doing chnages also here .. but adjustment,expense and disbursement every day full loads happening from this pkg only
                    --28-Aug-2024 : d_check_date_r update in FCT_CLAIM_PAYMENT_DETAIL_EXPENSE_R - PACS_EXPENSE
                    --30-Aug-2024 : Introduced fct_claim_payment_detail_expense_r_chkdt_gtt to update d_check_date_r in FCT_CLAIM_PAYMENT_DETAIL_EXPENSE_R - PACS_EXPENSE
		            --03-Oct-2024 party sk changes in FCT_GRP_REDIRECT_PAYMENT_R
		                           -- ,-1 N_PARTY_SK_R 		--12-MAR-2024 Changes
		                            ,FCT_GRP_REDIRECT_PAYMENT_R.n_payee_party_sk_r  N_PARTY_SK_R 		
		                            --03-Oct-2024 changes ends
					--25-Nov-2024 :dim_grp_party_r added src system name 
					--13-Aug-2025 :Adding mapping for V_PAY_METHOD_R in FCT_CLAIM_PAYMENT_DETAIL_EXPENSE_R as part of Bug 442478
		            --05-Dec-2025 :Aswathi changes in FCT_CLAIM_PAYMENT_DETAIL_ADJUSTMENT_R	
------------------------------------------------------------------------------------------------------------------------------------

FCT_CLAIM_PAYMENT_DETAIL_R
--------------------------
FCT_BENEFIT_PAYMENT_R FBPR
DIM_GRP_CLAIM_DIR_R DGCDR
FCT_GRP_WORKSHEET FGW
FCT_BENEFIT_PAYMENT_DETAIL_R FBPDR
DIM_GRP_CLAIM_COVERAGE_GROUP_R DGCCGR
DIM_GRP_CLAIM_COVERAGE_R DGCCR

FCT_CLAIM_ADJUSTMENT_R
DIM_GRP_CLAIM_DIR_R
DIM_GRP_CLAIM_COVERAGE_R
DIM_GRP_CLAIM_COVERAGE_GROUP_R

FCT_CLAIM_EXPENSE_PAYMENT_R
DIM_GRP_CLAIM_DIR_R
DIM_GRP_CLAIM_COVERAGE_R
DIM_GRP_CLAIM_COVERAGE_GROUP_R

FCT_GRP_REDIRECT_PAYMENT_R
DIM_GRP_CLAIM_DIR_R
DIM_GRP_CLAIM_COVERAGE_R*/


PROCEDURE PRC_FCT_CLAIM_PMNT_DET_GAT_TBL_STATS
IS
BEGIN
 /*commit;
 DBMS_STATS.gather_table_stats('ATOMIC', 'FCT_CLAIM_PAYMENT_DETAIL_R');
 dbms_stats.gather_index_stats('ATOMIC', 'FCT_CLAIM_PAYMENT_DETAIL_R_IDX1', null, DBMS_STATS.AUTO_SAMPLE_SIZE);
 dbms_stats.gather_index_stats('ATOMIC', 'FCT_CLAIM_PAYMENT_DETAIL_R_IDX2', null, DBMS_STATS.AUTO_SAMPLE_SIZE);
 dbms_stats.gather_index_stats('ATOMIC', 'FCT_CLAIM_PAYMENT_DETAIL_R_IDX3', null, DBMS_STATS.AUTO_SAMPLE_SIZE);
 dbms_stats.gather_index_stats('ATOMIC', 'FCT_CLAIM_PAYMENT_DETAIL_R_CMP_IDX1', null, DBMS_STATS.AUTO_SAMPLE_SIZE);
 dbms_stats.gather_index_stats('ATOMIC', 'FCT_CLAIM_PAYMENT_DETAIL_R_CMP_IDX2', null, DBMS_STATS.AUTO_SAMPLE_SIZE);
*/
NULL;
EXCEPTION
WHEN OTHERS
THEN
NULL;
END;
/*
--the below functions called in PRC_FULLLOAD_FCT_CLAIM_PMT_DET_R
FUNCTION GET_N_GROSS_AMOUNT_R(P_RECORD_CNT_R NUMBER,P_V_CLAIM_NUMBER_R IN VARCHAR2,P_N_SOURCE_VERSION_SEQ_NUMBER_R IN NUMBER,P_N_BATCH_ID_R IN NUMBER)
RETURN NUMBER
AS
LN_GROSS_AMOUNT_R NUMBER;
begin
SELECT   distinct
  (CASE WHEN v_lob_type_r = 'ANNUITY'
        THEN n_modal_amount_r
        ELSE
                CASE
                  WHEN n_primary_payee_r = 1
                  THEN n_adj_gross_benefit_r
                  WHEN n_primary_payee_r = 0
                  THEN n_pay_amount_r
                END

            END / p_record_cnt_r   ) into ln_gross_amount_r
FROM ATOMIC.FCT_CLAIM_PAYMENT_DETAIL_R A
     --, atomic.dim_grp_claim_dir_r c
WHERE --A.V_CLAIM_NUMBER_R = C.V_CLAIM_NUMBER_R
--and b.n_claim_sk_r = c.n_claim_sk_r
--AND
A.V_RECORD_TYPE_R = 'Benefit Payment'
--and c.v_active_status_r         = 'Y'
AND A.N_BATCH_ID_R =P_N_BATCH_ID_R
and a.v_claim_number_r = p_v_claim_number_r
and a.n_source_version_seq_number_r = p_n_source_version_seq_number_r
  ;
RETURN ln_gross_amount_r;
EXCEPTION
WHEN OTHERS THEN
RETURN NULL;
END GET_N_GROSS_AMOUNT_R;
*/
PROCEDURE PRC_FULLLOAD_FCT_CLAIM_PMT_DET_R(
    IN_BATCH_ID_R        IN NUMBER,
    IN_MAX_LOAD_RUN_ID_R IN NUMBER,
	IN_TYPE              IN VARCHAR2,
    OUT_LOAD_STATUS      OUT VARCHAR2
    )
IS
  LN_N_BATCH_ID_R        NUMBER := IN_BATCH_ID_R;
  --LN_N_BATCH_ID_R        NUMBER := TO_NUMBER(TO_CHAR(SYSDATE,'YYYYMMDD'));
  LN_N_LOAD_RUN_ID_R NUMBER := IN_MAX_LOAD_RUN_ID_R;
  LN_MAX_SEQ_NUMER_R   NUMBER;
  LC_SQLCODE           VARCHAR2(4000);
  LC_SQLERRM           VARCHAR2(4000);
  lt_systimestamp timestamp := SYSTIMESTAMP;
  LC_SOURCE_CONCEPT    VARCHAR2(4000);
  LN_GROSS_AMT_R NUMBER;
/*CURSOR cur_bene_pymnt_claim_cnt(p_v_record_type_r IN VARCHAR2)
IS
SELECT * FROM
(SELECT COUNT(1) rowcount, v_claim_number_r, n_source_version_seq_number_r
  FROM ATOMIC.FCT_CLAIM_PAYMENT_DETAIL_R
 WHERE v_record_type_r = p_v_record_type_r--'Benefit Payment'
   AND N_BATCH_ID_R=LN_N_BATCH_ID_R
GROUP BY v_claim_number_r, n_source_version_seq_number_r
)
ORDER BY v_claim_number_r, n_source_version_seq_number_r
;

  TYPE l_bene_pymnt_claim_tbl_typ IS TABLE OF cur_bene_pymnt_claim_cnt%ROWTYPE INDEX BY BINARY_INTEGER;
  l_bene_pymnt_claim_rec_typ   l_bene_pymnt_claim_tbl_typ;*/
  LN_BULK_LIMIT_R NUMBER;
  CURSOR cur_benefit_payment
  IS
        SELECT   /*+PARALLEL(4)*/
		DGCDR.v_claim_number_r                                                                                       V_CLAIM_NUMBER_R
		,NVL(DGCCGR.V_CLAIM_COVERAGE_CODE_R,DGCCR.V_CLAIM_COVERAGE_CODE_R)                                         V_COVERAGE_CODE_R--11-aUG-2021 As per Erica's request mapping has been changed from DGCCR.V_COVERAGE_CODE_R
		,DGCCGR.N_COV_GRP_ID_R                                                                                       V_COV_GROUP_ID_R --11-aUG-2021 As per Erica's request mapping has been changed from V_COV_GRP_CODE_R to N_COV_GRP_ID_R
		,FBPR.V_CHECK_NUM_R                                                                                          V_CHECK_NUMBER_R
		,FBPR.V_PAY_METHOD_R                                                                                         V_PAY_METHOD_R
		,FBPDR.V_AMOUNT_TYPE_SUB_CODE_R                                                                              V_BENEFIT_CODE_R
		,FBPDR.V_AMOUNT_TYPE_NAME_R                                                                                  V_BENEFIT_DESCRIPTION_R
		,FBPDR.V_AMOUNT_TYPE_CODE_R                                                                                  V_BENEFIT_GROUP_R
		/*,( CASE WHEN FBPDR.V_BENEFIT_CODE_R IN ('098','FIC','298','MED')
		THEN NVL(FBPR.N_MED_WAGE_BASE_R,0) + NVL(FBPR.N_SS_WAGE_BASE_R,0)
		ELSE 0
		END
		)                                                                                                            N_GROSS_WAGE_BASE_R*/
		/*,(case when FBPDR.V_BENEFIT_CODE_R in ('098','FIC','298','MED')
					THEN (	(CASE WHEN FBPDR.V_AMOUNT_TYPE_CODE_R='098' AND FBPDR.V_AMOUNT_TYPE_SUB_CODE_R  NOT LIKE 'S%' THEN NVL(FBPR.N_SS_WAGE_BASE_R,0)
                             else 0
                             end) 	+
						(	CASE WHEN FBPDR.V_AMOUNT_TYPE_CODE_R='298' AND FBPDR.V_AMOUNT_TYPE_SUB_CODE_R NOT LIKE 'M%'  THEN NVL(FBPR.N_MED_WAGE_BASE_R,0)
                             ELSE 0
                             end
                               ) )
	     else 0
	     END) 																									     N_GROSS_WAGE_BASE_R---31-JAN-2024 Changes*/
		,FBPR.N_MED_WAGE_BASE_R																						 N_GROSS_WAGE_BASE_R --13-MAR-2024 Changes
		,FGW.N_TAXABLE_OVERRIDE_PCT_R                                                                                N_TAXABLE_PERCENT_R
		,DECODE(UPPER(TRIM(FBPR.V_PAY_STATUS_R)),'REVERSAL','VOID','PAID')                                           V_PAYMENT_STATUS_R
		,FBPDR.N_AMOUNT_R                                                                                            N_PAID_AMOUNT_R
		,(CASE WHEN (UPPER(TRIM(DGCDR.V_LOB_TYPE_R)) IN ('LIFE','WOP') AND UPPER(TRIM(FBPR.V_PAY_METHOD_R)) = 'RAA')
		THEN 'FIN'
		ELSE 'PAY'
		END)                                                                                                         V_PAYMENT_TYPE_R
		,FBPR.D_DISB_DATE_R                                                                                          D_CHECK_DATE_R
		,DECODE(UPPER(TRIM(FBPR.V_PAY_METHOD_R)),'ACH','ACH','BP')                                                   V_CHECK_TYPE_R
		--,(CASE WHEN UPPER(TRIM(FBPR.V_PAY_STATUS_R)) NOT IN ('RELEASED','REVERSED')
    /*,(CASE WHEN UPPER(TRIM(FBPR.V_PAY_STATUS_R))  IN ('RELEASED','REVERSED')--19-Jul-2021 Eric'as new logic
		THEN FBPR.D_DISB_DATE_R
		ELSE FBPR.D_REVERSE_DATE_R
		END)                                  D_PAID_DATE_R  */--as per Erica's request on 28-Jul-2021 , code  commented
		,FBPR.D_TRANS_DATE_R                                                                                         D_PAID_DATE_R   --as per Erica's request on 28-Jul-2021 , code  added
		,NULL                                                                                                        N_GROSS_AMOUNT_R
		,FBPR.D_SERVICE_PERIOD_START_R                                                                               D_SERVICE_PERIOD_FROM_R
		,FBPR.D_SERVICE_PERIOD_END_R                                                                                 D_SERVICE_PERIOD_TO_R
		, 'Benefit Payment'                                                                                          V_RECORD_TYPE_R
		,FBPR.N_WORKSHEET_SEQ_NBR_OBJECTNM_R                                                                         N_WORKSHEET_OBJECT_NUM_R
		,FBPR.N_PAY_SCHD_SOURCE_SYSTEM_KEY_R                                                                         N_SOURCE_SYSTEM_KEY_R
		,FBPR.N_SOURCE_VERSION_SEQ_NUMBER_R                                                                          N_SOURCE_VERSION_SEQ_NUMBER_R
		,FBPR.N_SEQ_R                                                                                                N_SEQ_R
		,FBPR.N_GROUP_SEQ_R                                                                                          N_GROUP_SEQ_R
		,FBPR.N_PARENT_OBJECTNUM_R                                                                                   N_PARENT_OBJECTNUM_R
        ,LT_systimestamp                                                                                             T_CREATION_DATE_R
        ,LT_systimestamp                                                                                             T_EVENT_TIMESTAMP_R
        ,LT_systimestamp                                                                                             T_LAST_MODIFIED_DATE_R
        ,'ODI'                                                                                                       V_CREATED_BY_R
        ,'ODI'                                                                                                       V_LAST_MODIFIED_BY_R
		,FBPR.FIC_MIS_DATE_R--26-Apr-2022 Full Load Changes
		,FBPR.N_BATCH_ID_R--26-Apr-2022 Full Load Changes
        ,LN_N_LOAD_RUN_ID_R                     N_LOAD_RUN_ID_R
        ,(NVL(LN_MAX_SEQ_NUMER_R,0)+ROWNUM)     N_SEQUENCE_NUMBER_R
		,FBPDR.V_AMOUNT_TYPE_CATEGORY_DESC_R                                                                         V_BENEFIT_CATEGORY_R
		--On 15-Jul-2021 Erica requested to add below columns
		,FBPDR.N_PAID_CLAIM_BENEFITS_R
		,FBPDR.N_TAXABLE_BENEFIT_AMT_R
		,FBPDR.N_FEDERAL_TAX_WITHHELD_AMT_R
		,FBPDR.N_STATE_TAX_WITHHELD_AMT_R
		,FBPDR.N_EMPLOYEE_SS_WITHHELD_AMT_R
		,FBPDR.N_EMPLOYEE_MED_WITHHELD_AMT_R
		,FBPDR.N_EMPLOYER_SS_WITHHELD_AMT_R
		,FBPDR.N_EMPLOYER_MED_WITHHELD_AMT_R
		,FBPDR.N_LEGAL_EXPENSE_DIRECT_AMT_R
		,FBPDR.N_OTHER_EXPENSE_DIRECT_AMT_R
		--On 15-Jul-2021 Erica request ends
		,DGCDR.V_LOB_TYPE_R         -- to achieve On Erica's requirement 28-Jul-2021
		,  FGW.N_MODAL_AMOUNT_R       -- to achieve On Erica's requirement 28-Jul-2021
		, FBPR.N_PRIMARY_PAYEE_R     -- to achieve On Erica's requirement 28-Jul-2021
		, FBPR.N_ADJ_GROSS_BENEFIT_R -- to achieve On Erica's requirement 28-Jul-2021
		, FBPR.N_PAY_AMOUNT_R        -- to achieve On Erica's requirement 28-Jul-2021
		, FBPR.N_CLAIM_SK_R          -- to achieve On Erica's requirement 28-Jul-2021
        --as requested by Erica on 16-Nov-2021
        ,(CASE WHEN DGCDR.V_LOB_TYPE_R =  'NONS' THEN
        CASE WHEN DGCCGR.V_CLAIM_COVERAGE_CODE_R = 'END' then '025'
        WHEN DGCCGR.V_CLAIM_COVERAGE_CODE_R = 'GCM' then '128'
        WHEN DGCCGR.V_CLAIM_COVERAGE_CODE_R = 'LTY' then '028'
        WHEN DGCCGR.V_CLAIM_COVERAGE_CODE_R IN ('IDL', 'MML', 'ORL', 'PGL', 'PVG') then '010'
        WHEN DGCCGR.V_CLAIM_COVERAGE_CODE_R IN ('ASG', 'SPG', 'VAI') then '051'
        WHEN DGCCGR.V_CLAIM_COVERAGE_CODE_R = 'VCI' then '079'
        WHEN DGCCGR.V_CLAIM_COVERAGE_CODE_R IN ('IWP', 'WP') then '013'
        ELSE '081'
        END
        WHEN DGCDR.V_LOB_TYPE_R =  'ANNUITY' THEN
        CASE WHEN DGCCR.V_CLAIM_COVERAGE_CODE_R = 'GAN' THEN '085'
        ELSE
            --CASE WHEN DGCCR.V_CLAIM_COVERAGE_CODE_R = 'SC' AND upper(DGCCR.V_COVERAGE_CODE_R) in ('J'||CHR(38)||'S',  'LIFE',  'LIFE w/PC') THEN '031'--05-JAN-2022 commented changes
            CASE WHEN DGCCR.V_CLAIM_COVERAGE_CODE_R = 'SC' AND upper(DGCCR.V_COVERAGE_CODE_R) in ('J'||CHR(38)||'S',  'LIFE',  'LIFE W/PC') THEN '031'--05-JAN-2022 changes
            ELSE '032'
            END
        END
        WHEN DGCDR.V_LOB_TYPE_R IN ( 'WOP', 'LIFE') THEN DGCCGR.V_BENEFIT_CODE_R
        WHEN DGCDR.V_LOB_TYPE_R IN ( 'LTD', 'STD', 'VPL', 'VPS' ) THEN '081'
        END
        ) V_GROSS_BENEFIT_CODE_R
		,FBPR.N_CLAIM_COVERAGE_SK_R                  --08-Apr-2022 Erica changes
		,FBPR.N_CLAIM_COVERAGE_GROUP_SK_R            --08-Apr-2022 Erica changes
        ,fbpdr.n_seq_r                         N_FBPR_N_SEQ_R --10-Nov-2022 changes for Merge
		,FBPR.v_source_system_name_r --14-Dec-2022 changes
		,(CASE WHEN FBPDR.V_AMOUNT_TYPE_CODE_R='098' AND FBPDR.V_AMOUNT_TYPE_SUB_CODE_R  NOT LIKE 'S%'
                             THEN NVL(FBPR.N_SS_WAGE_BASE_R,0)
                             ELSE 0
                             END) N_SS_WAGE_BASE_R--07-JUL-2023 changes
		,(CASE WHEN FBPDR.V_AMOUNT_TYPE_CODE_R='298' AND FBPDR.V_AMOUNT_TYPE_SUB_CODE_R NOT LIKE 'M%'
                             THEN NVL(FBPR.N_MED_WAGE_BASE_R,0)
                             ELSE 0
                             END
                             )  N_MED_WAGE_BASE_R--07-JUL-2023 changes
        --27-SEP-2023 changes starts
		,pa.V_INDIVIDUAL_FIRST_NAME_R v_payee_first_name_r
		,pa.V_INDIVIDUAL_middle_NAME_R v_payee_middle_name_r
        ,pa.V_INDIVIDUAL_LAST_NAME_R v_payee_last_name_r
		,(case  when PD.V_PAYEE_TYPE_R = 'Agent' then ' UNK '
        when PD.V_PAYEE_TYPE_R = 'Beneficiary' then 'UNK'
        when PD.V_PAYEE_TYPE_R = 'Customer' then 'GRP'
        when PD.V_PAYEE_TYPE_R = 'Insured' then 'IND'
        when PD.V_PAYEE_TYPE_R = 'Vendor' then 'PRV' else PD.V_PAYEE_TYPE_R end ) V_PAYEE_TYPE_R
		--27-SEP-2023 changes ends
		,'' AS V_PAYMENT_RECORD_TYPE_R --04-JAN-2024 changes
        ,FGW.V_TAX_STATE_R--31-JAN-2024 changes
		,pa.n_party_sk_r as n_party_sk_r --13-MAR-2024 Changes
        --29-May-2024 changes starts
        ,FBPDR.V_AMOUNT_TYPE_SUB_NAME_R,
        FBPDR.V_AMOUNT_TYPE_CATEGORY_R,
        FBPDR.V_AMOUNT_TYPE_CATEGORY_DESC_R,
        FBPDR.V_AMOUNT_TYPE_SUB_CATEGORY_R,
        FBPDR.V_AMT_TYPE_SUB_CATEGORY_DESC_R,
        FBPDR.V_AMOUNT_TYPE_CODE_R,
        FBPDR.V_AMOUNT_TYPE_NAME_R,
        FBPDR.V_AMOUNT_TYPE_SUB_CODE_R
        --29-May-2024 changes ends
		FROM ATOMIC.FCT_BENEFIT_PAYMENT_R FBPR
			,ATOMIC.DIM_GRP_CLAIM_DIR_R DGCDR
			,ATOMIC.FCT_GRP_WORKSHEET FGW
			,ATOMIC.FCT_BENEFIT_PAYMENT_DETAIL_R FBPDR
			,ATOMIC.DIM_GRP_CLAIM_COVERAGE_GROUP_R DGCCGR
			,ATOMIC.DIM_GRP_CLAIM_COVERAGE_R DGCCR
			,(SELECT * FROM ATOMIC.dim_payment_details pd WHERE PD.V_ACTIVE_STATUS_R = 'Y')PD --27-SEP-2023 changes
			,(select * from dim_grp_party_r where v_active_status_r = 'Y' and v_source_system_name_r = 'PACS')  pa --27-SEP-2023 changes
		WHERE  UPPER(TRIM(FBPR.V_PAY_STATUS_R)) IN ('RELEASED','REVERSAL','REVERSED')
		AND FBPR.N_CLAIM_SK_R = DGCDR.N_CLAIM_SK_R
        and FBPR.N_CLAIM_COVERAGE_SK_R = DGCCR.N_CLAIM_COVERAGE_SK_R(+)
        and FBPR.N_CLAIM_COVERAGE_GROUP_SK_R = DGCCGR.N_CLAIM_COVERAGE_GROUP_SK_R(+)
		AND FGW.N_WORKSHEET_SEQ_NBR_OBJECTNM_R = FBPR.N_PARENT_OBJECTNUM_R
		AND FGW.N_SOURCE_SYSTEM_KEY_R = FBPR.N_PAY_SCHD_SOURCE_SYSTEM_KEY_R
		AND FBPR.N_SOURCE_VERSION_SEQ_NUMBER_R = FBPDR.N_SOURCE_VERSION_SEQ_NUMBER_R(+)  --22-Jul-2021 Erica outer join request
		AND FBPR.N_SEQ_R = FBPDR.N_GROUP_SEQ_R(+)--22-Jul-2021 Erica outer join request
		AND FBPR.N_PAY_SCHD_SOURCE_SYSTEM_KEY_R = FBPDR.N_PAY_DTL_SOURCE_SYSTEM_KEY_R(+)--22-Jul-2021 Erica outer join request
		AND DGCDR.V_ACTIVE_STATUS_R         = 'Y'
        and nvl(DGCCGR.V_ACTIVE_STATUS_R,'Y') = 'Y'
        AND NVL(DGCCR.V_ACTIVE_STATUS_R, 'Y')  = 'Y'
		AND UPPER(TRIM(FBPDR.V_BENEFIT_DESC_R)) <> 'PAYMENT TO SECONDARY PAYEE' --11-May-2022 Mohan Changes
        --and NVL(DGCCGR.V_CLAIM_COVERAGE_CODE_R,DGCCR.V_CLAIM_COVERAGE_CODE_R)  is null Erica asked to remove this condition 14-Apr-2022
		--AND FBPR.N_BATCH_ID_R = LN_N_BATCH_ID_R --26-Apr-2022 Full Load Changes
		--27-SEP-2023 changes starts
		AND DGCDR.N_SOURCE_SYSTEM_KEY_R =PD.V_PAYMNT_DTLS_SRC_SYS_KEY_R(+)------27-SEP-2023 change,  TABLE ORDER REVERSED WITH OUTER JOIN
        --AND PD.V_ACTIVE_STATUS_R = 'Y'
        AND FBPR.N_WORKSHEET_SEQ_NBR_OBJECTNM_R = PD.V_WORKSHEET_OBJECTNUM_R(+)------27-SEP-2023 change,  TABLE ORDER REVERSED WITH OUTER JOIN
        --AND PD.V_WORKSHEET_OBJECTNUM_R = FBPR.N_WORKSHEET_SEQ_NBR_OBJECTNM_R(+)
        AND NVL(FBPR.V_LINK_OBJECTNUM_R,0)=PD.V_PAYMNT_DTLS_SEQ_NBR_R(+)----27-SEP-2023 CHANGES,  TABLE ORDER REVERSED WITH OUTER JOIN AND NVL IMPLEMENTATION
        and pd.N_INSRD_PARTY_SK_R = pa.n_party_sk_r(+) --27-SEP-2023 change - outer join on party_SK_R
		--15/09 changes  committed the below code
        --and pa.v_active_status_r = 'Y'
--        and pd.V_PAYMNT_DTLS_SEQ_NBR_R = (select max(a.V_PAYMNT_DTLS_SEQ_NBR_R)
--                                    from dim_payment_details a
--                                    where a.V_PAYMNT_DTLS_SRC_SYS_KEY_R = pd.V_PAYMNT_DTLS_SRC_SYS_KEY_R
--                                    and a.V_WORKSHEET_OBJECTNUM_R = pd.V_WORKSHEET_OBJECTNUM_R
--                                    and a.v_active_status_r = 'Y')
        --27-SEP-2023 changes ends
      AND NVL(FBPR.V_SOURCE_SYSTEM_NAME_R,'X@')='PACS'--07-Dec-2022  filter applied to stop SHINKA data

       ;

  TYPE l_fct_tbl_typ IS TABLE OF cur_benefit_payment%ROWTYPE INDEX BY BINARY_INTEGER;
  l_fct_rec_typ   l_fct_tbl_typ;

CURSOR cur_gross_benefit
IS
       SELECT  /*+PARALLEL(4)*/
		DGCDR.v_claim_number_r                 V_CLAIM_NUMBER_R
		,NVL(DGCCGR.V_CLAIM_COVERAGE_CODE_R,DGCCR.V_CLAIM_COVERAGE_CODE_R) V_COVERAGE_CODE_R--11-aUG-2021 As per Erica's request mapping has been changed from DGCCR.V_COVERAGE_CODE_R
		,DGCCGR.N_COV_GRP_ID_R               V_COV_GROUP_ID_R --11-aUG-2021 As per Erica's request mapping has been changed from V_COV_GRP_CODE_R to N_COV_GRP_ID_R
		,FBPR.V_CHECK_NUM_R                    V_CHECK_NUMBER_R
		,FBPR.V_PAY_METHOD_R                   V_PAY_METHOD_R
		,(CASE WHEN DGCDR.V_LOB_TYPE_R =  'NONS' THEN
         CASE WHEN DGCCGR.V_CLAIM_COVERAGE_CODE_R = 'END' then '025'
         WHEN DGCCGR.V_CLAIM_COVERAGE_CODE_R = 'GCM' then '128'
         WHEN DGCCGR.V_CLAIM_COVERAGE_CODE_R = 'LTY' then '028'
         WHEN DGCCGR.V_CLAIM_COVERAGE_CODE_R IN ('IDL', 'MML', 'ORL', 'PGL', 'PVG') then '010'
         WHEN DGCCGR.V_CLAIM_COVERAGE_CODE_R IN ('ASG', 'SPG', 'VAI','GPL') then '051'      -- Added GPL 06-Jun-2022 changes
         WHEN DGCCGR.V_CLAIM_COVERAGE_CODE_R = 'VCI' then '079'
         WHEN DGCCGR.V_CLAIM_COVERAGE_CODE_R IN ('IWP', 'WP') then '013'
         ELSE '081'
         END
         WHEN DGCDR.V_LOB_TYPE_R =  'ANNUITY' THEN
         CASE WHEN DGCCR.V_CLAIM_COVERAGE_CODE_R = 'GAN' THEN '085'
         ELSE
             --CASE WHEN DGCCR.V_CLAIM_COVERAGE_CODE_R = 'SC' AND upper(DGCCR.V_COVERAGE_CODE_R) in ('J'||CHR(38)||'S',  'LIFE',  'LIFE w/PC') THEN '031'--05-JAN-2022 commented changes
             CASE WHEN DGCCR.V_CLAIM_COVERAGE_CODE_R = 'SC' AND upper(DGCCR.V_COVERAGE_CODE_R) in ('J'||CHR(38)||'S',  'LIFE',  'LIFE W/PC') THEN '031'--05-JAN-2022 changes
             ELSE '032'
             END
         END
         WHEN DGCDR.V_LOB_TYPE_R IN ( 'WOP', 'LIFE') THEN DGCCGR.V_BENEFIT_CODE_R
         WHEN DGCDR.V_LOB_TYPE_R IN ( 'LTD', 'STD', 'VPL', 'VPS' ) THEN '081'
         END
         )       V_BENEFIT_CODE_R
		--21-Jun-2022 Erica changes starts
		--,null         V_BENEFIT_DESCRIPTION_R	-- Populating null for now
		,(CASE WHEN DGCDR.V_LOB_TYPE_R =  'NONS' THEN
         CASE WHEN DGCCGR.V_CLAIM_COVERAGE_CODE_R = 'END' then 'MATURED ENDOWMENT'
         WHEN DGCCGR.V_CLAIM_COVERAGE_CODE_R = 'GCM' then 'MISCELLANEOUS MEDICAL EXPENSE'
         WHEN DGCCGR.V_CLAIM_COVERAGE_CODE_R = 'LTY' then 'ANNUITY PAYMENT, L.C., NON PAR'
         WHEN DGCCGR.V_CLAIM_COVERAGE_CODE_R IN ('IDL', 'MML', 'ORL', 'PGL', 'PVG') then 'FACE AMOUNT'
         WHEN DGCCGR.V_CLAIM_COVERAGE_CODE_R IN ('ASG', 'SPG', 'VAI','GPL') then 'GROUP LIFE BENEFIT'         -- Added GPL 06-Jun-2022 changes
         WHEN DGCCGR.V_CLAIM_COVERAGE_CODE_R = 'VCI' then 'CRITICAL ILLNESS BENEFIT'
         WHEN DGCCGR.V_CLAIM_COVERAGE_CODE_R IN ('IWP', 'WP') then 'REFUND OF PREMIUM'
         ELSE 'GROSS BENEFIT - DISABILITY'
         END
         WHEN DGCDR.V_LOB_TYPE_R =  'ANNUITY' THEN
         CASE WHEN DGCCR.V_CLAIM_COVERAGE_CODE_R = 'GAN' THEN 'PENSION PAYMENTS'
         ELSE
             --CASE WHEN DGCCR.V_CLAIM_COVERAGE_CODE_R = 'SC' AND upper(DGCCR.V_COVERAGE_CODE_R) in ('J'||CHR(38)||'S',  'LIFE',  'LIFE w/PC') THEN '031'--05-JAN-2022 commented changes
             CASE WHEN DGCCR.V_CLAIM_COVERAGE_CODE_R = 'SC' AND upper(DGCCR.V_COVERAGE_CODE_R) in ('J'||CHR(38)||'S',  'LIFE',  'LIFE W/PC') THEN 'S.C. PAYMENT, WITH L.C.'--05-JAN-2022 changes
             ELSE 'S.C. PAYMENT, WITHOUT L.C.'
             END
         END
         WHEN DGCDR.V_LOB_TYPE_R IN ( 'WOP', 'LIFE') THEN
             (CASE WHEN DGCCGR.V_BENEFIT_CODE_R = '076' THEN 'PERMANENT TOTAL DISABILITY'
         WHEN DGCCGR.V_BENEFIT_CODE_R = '079' THEN 'CRITICAL ILLNESS BENEFIT'
         WHEN DGCCGR.V_BENEFIT_CODE_R = '064' THEN 'LOSS OF THUMB AND INDEX FINGER'
         WHEN DGCCGR.V_BENEFIT_CODE_R = '057' THEN 'LOSS OF ONE EYE AND ONE FOOT'
         WHEN DGCCGR.V_BENEFIT_CODE_R = '04C' THEN 'DEP SUPPLEMENTAL LIFE BENEFIT'
         WHEN DGCCGR.V_BENEFIT_CODE_R = '055' THEN 'LOSS OF ONE HAND AND ONE FOOT'
         WHEN DGCCGR.V_BENEFIT_CODE_R = '081' THEN 'GROSS BENEFIT - DISABILITY'
         WHEN DGCCGR.V_BENEFIT_CODE_R = '04B' THEN 'DEPENDENT ACCIDENTAL DEATH BENEFIT'
         WHEN DGCCGR.V_BENEFIT_CODE_R = '04E' THEN 'DEP ACCELERATED DEATH BENEFIT'
         WHEN DGCCGR.V_BENEFIT_CODE_R = '04A' THEN 'DEPENDENT LIFE BENEFIT'
         WHEN DGCCGR.V_BENEFIT_CODE_R = '071' THEN 'SEAT BELT / AIRBAG'
         WHEN DGCCGR.V_BENEFIT_CODE_R = '05G' THEN 'HOLIDAY'
         WHEN DGCCGR.V_BENEFIT_CODE_R = '051' THEN 'GROUP LIFE BENEFIT'
         WHEN DGCCGR.V_BENEFIT_CODE_R = '068' THEN 'ACCELERATED BENEFIT'
         WHEN DGCCGR.V_BENEFIT_CODE_R = '05D' THEN 'AIR BAG BENEFIT'
         WHEN DGCCGR.V_BENEFIT_CODE_R = '059' THEN 'LOSS OF ONE FOOT'
         WHEN DGCCGR.V_BENEFIT_CODE_R = '05I' THEN 'REHABILITATION'
         WHEN DGCCGR.V_BENEFIT_CODE_R = '05F' THEN 'DAYCARE BENEFIT'
         WHEN DGCCGR.V_BENEFIT_CODE_R = '013' THEN 'REFUND OF PREMIUM'
         WHEN DGCCGR.V_BENEFIT_CODE_R = '060' THEN 'LOSS OF SIGHT IN ONE EYE'
         WHEN DGCCGR.V_BENEFIT_CODE_R = '050' THEN 'ACCIDENTAL DEATH BENEFIT'
         WHEN DGCCGR.V_BENEFIT_CODE_R = '049' THEN 'PORTION OF PRINCIPAL SUM'
         WHEN DGCCGR.V_BENEFIT_CODE_R = '072' THEN 'AIRCRAFT PILOT OR PASSENGER'
         WHEN DGCCGR.V_BENEFIT_CODE_R = '066' THEN 'ACCIDENTAL DEATH BENEFIT'
         WHEN DGCCGR.V_BENEFIT_CODE_R = '04D' THEN 'DEP SUPPLMTL LIFE ACCIDENT BENEFIT'
         WHEN DGCCGR.V_BENEFIT_CODE_R = '052' THEN 'LOSS OF BOTH HANDS'
         WHEN DGCCGR.V_BENEFIT_CODE_R = '058' THEN 'LOSS OF ONE HAND'
         WHEN DGCCGR.V_BENEFIT_CODE_R = '053' THEN 'LOSS OF BOTH FEET'
         WHEN DGCCGR.V_BENEFIT_CODE_R = '05E' THEN 'DISMEMBERMENT'
         WHEN DGCCGR.V_BENEFIT_CODE_R = '069' THEN 'ACCELERATED BENEFIT'
         WHEN DGCCGR.V_BENEFIT_CODE_R = '067' THEN 'SURVIVOR BENEFIT: GROUP LIFE CLAIM'
         WHEN DGCCGR.V_BENEFIT_CODE_R = '065' THEN 'LOSS OF USE'
         WHEN DGCCGR.V_BENEFIT_CODE_R = '128' THEN 'MISCELLANEOUS MEDICAL EXPENSE'
         WHEN DGCCGR.V_BENEFIT_CODE_R = '062' THEN 'LOSS OF HEARING'
         WHEN DGCCGR.V_BENEFIT_CODE_R = '05A' THEN 'GROUP LIFE SUPPLEMENTAL BENEFIT'
         WHEN DGCCGR.V_BENEFIT_CODE_R = '05B' THEN 'GROUP LIFE ACCIDENTAL DEATH BENEFIT'
         WHEN DGCCGR.V_BENEFIT_CODE_R = '094' THEN 'EDUCATION BENEFIT'
         WHEN DGCCGR.V_BENEFIT_CODE_R = '070' THEN 'FELONIOUS ASSAULT'
         WHEN DGCCGR.V_BENEFIT_CODE_R = '054' THEN 'LOSS OF SIGHT IN BOTH EYES'
         WHEN DGCCGR.V_BENEFIT_CODE_R = '107' THEN 'HOSPITAL BENEFIT'
         WHEN DGCCGR.V_BENEFIT_CODE_R = '056' THEN 'LOSS OF ONE HAND AND ONE EYE'
         ELSE NULL
         END)
         WHEN DGCDR.V_LOB_TYPE_R IN ( 'LTD', 'STD', 'VPL', 'VPS' ) THEN 'GROSS BENEFIT - DISABILITY'
         END
         )     V_BENEFIT_DESCRIPTION_R
		--,null           V_BENEFIT_GROUP_R	 -- Populating null for now
		 ,(CASE WHEN DGCDR.V_LOB_TYPE_R =  'NONS' THEN
           CASE WHEN DGCCGR.V_CLAIM_COVERAGE_CODE_R = 'END' then '025'
           WHEN DGCCGR.V_CLAIM_COVERAGE_CODE_R = 'GCM' then '128'
           WHEN DGCCGR.V_CLAIM_COVERAGE_CODE_R = 'LTY' then '028'
           WHEN DGCCGR.V_CLAIM_COVERAGE_CODE_R IN ('IDL', 'MML', 'ORL', 'PGL', 'PVG') then '010'
           WHEN DGCCGR.V_CLAIM_COVERAGE_CODE_R IN ('ASG', 'SPG', 'VAI') then '051'
           WHEN DGCCGR.V_CLAIM_COVERAGE_CODE_R = 'VCI' then '079'
           WHEN DGCCGR.V_CLAIM_COVERAGE_CODE_R IN ('IWP', 'WP') then '013'
           ELSE '081'
           END
           WHEN DGCDR.V_LOB_TYPE_R =  'ANNUITY' THEN
           CASE WHEN DGCCR.V_CLAIM_COVERAGE_CODE_R = 'GAN' THEN '085'
           ELSE
               --CASE WHEN DGCCR.V_CLAIM_COVERAGE_CODE_R = 'SC' AND upper(DGCCR.V_COVERAGE_CODE_R) in ('J'||CHR(38)||'S',  'LIFE',  'LIFE w/PC') THEN '031'--05-JAN-2022 commented changes
               CASE WHEN DGCCR.V_CLAIM_COVERAGE_CODE_R = 'SC' AND upper(DGCCR.V_COVERAGE_CODE_R) in ('J'||CHR(38)||'S',  'LIFE',  'LIFE W/PC') THEN '031'--05-JAN-2022 changes
               ELSE '032'
               END
           END
           WHEN DGCDR.V_LOB_TYPE_R IN ( 'WOP', 'LIFE') THEN DGCCGR.V_BENEFIT_CODE_R
           WHEN DGCDR.V_LOB_TYPE_R IN ( 'LTD', 'STD', 'VPL', 'VPS' ) THEN '081'
           END
           ) V_BENEFIT_GROUP_R
		--21-Jun-2022 Erica changes ends
		,FBPR.N_MED_WAGE_BASE_R	                                                        N_GROSS_WAGE_BASE_R
		,FGW.N_TAXABLE_OVERRIDE_PCT_R                                 N_TAXABLE_PERCENT_R
		,DECODE(UPPER(TRIM(FBPR.V_PAY_STATUS_R)),'REVERSAL','VOID','PAID') V_PAYMENT_STATUS_R
		,(CASE WHEN DGCDR.v_lob_type_r = 'ANNUITY'
        --THEN FGW.n_modal_amount_r --26-Apr-2022 Erica changes
        THEN FBPR.n_gross_benefit_r --26-Apr-2022 Erica changes
        ELSE
                CASE
                  WHEN FBPR.n_primary_payee_r = 1
                  THEN FBPR.n_adj_gross_benefit_r
                  WHEN FBPR.n_primary_payee_r = 0
                  THEN FBPR.n_pay_amount_r
                END

            END)    N_PAID_AMOUNT_R -- populating gross amount
		,(CASE WHEN (UPPER(TRIM(DGCDR.V_LOB_TYPE_R)) IN ('LIFE','WOP') AND UPPER(TRIM(FBPR.V_PAY_METHOD_R)) = 'RAA')
		THEN 'FIN'
		ELSE 'PAY'
		END)                                                                        V_PAYMENT_TYPE_R
		,FBPR.D_DISB_DATE_R                                                           D_CHECK_DATE_R
		,DECODE(UPPER(TRIM(FBPR.V_PAY_METHOD_R)),'ACH','ACH','BP')                    V_CHECK_TYPE_R
		--,(CASE WHEN UPPER(TRIM(FBPR.V_PAY_STATUS_R)) NOT IN ('RELEASED','REVERSED')
    /*,(CASE WHEN UPPER(TRIM(FBPR.V_PAY_STATUS_R))  IN ('RELEASED','REVERSED')--19-Jul-2021 Eric'as new logic
		THEN FBPR.D_DISB_DATE_R
		ELSE FBPR.D_REVERSE_DATE_R
		END)                                  D_PAID_DATE_R  */--as per Erica's request on 28-Jul-2021 , code  commented
		,FBPR.D_TRANS_DATE_R                    D_PAID_DATE_R   --as per Erica's request on 28-Jul-2021 , code  added
		,(CASE WHEN DGCDR.v_lob_type_r = 'ANNUITY'
        THEN FGW.n_modal_amount_r
        ELSE
                CASE
                  WHEN FBPR.n_primary_payee_r = 1
                  THEN FBPR.n_adj_gross_benefit_r
                  WHEN FBPR.n_primary_payee_r = 0
                  THEN FBPR.n_pay_amount_r
                END

            END)                                   N_GROSS_AMOUNT_R
		,FBPR.D_SERVICE_PERIOD_START_R          D_SERVICE_PERIOD_FROM_R
		,FBPR.D_SERVICE_PERIOD_END_R            D_SERVICE_PERIOD_TO_R
		, 'Gross Benefit'                     V_RECORD_TYPE_R -- Can either include in benefit payment, or as a separate query for gross amount
		,FBPR.N_WORKSHEET_SEQ_NBR_OBJECTNM_R    N_WORKSHEET_OBJECT_NUM_R
		,FBPR.N_PAY_SCHD_SOURCE_SYSTEM_KEY_R    N_SOURCE_SYSTEM_KEY_R
		,FBPR.N_SOURCE_VERSION_SEQ_NUMBER_R     N_SOURCE_VERSION_SEQ_NUMBER_R
		,FBPR.N_SEQ_R                           N_SEQ_R
		,FBPR.N_GROUP_SEQ_R                     N_GROUP_SEQ_R
		,FBPR.N_PARENT_OBJECTNUM_R              N_PARENT_OBJECTNUM_R
		,LT_systimestamp                        T_CREATION_DATE_R
		,LT_systimestamp                        T_EVENT_TIMESTAMP_R
		,LT_systimestamp                        T_LAST_MODIFIED_DATE_R
		,'ODI'                                  V_CREATED_BY_R
		,'ODI'                                  V_LAST_MODIFIED_BY_R
		,FBPR.FIC_MIS_DATE_R                         --26-Apr-2022 Full Load Changes
		,FBPR.N_BATCH_ID_R                     	    N_BATCH_ID_R--26-Apr-2022 Full Load Changes
		,LN_N_LOAD_RUN_ID_R                     N_LOAD_RUN_ID_R
		,(NVL(LN_MAX_SEQ_NUMER_R,0)+ROWNUM)     N_SEQUENCE_NUMBER_R
		--21-May-2022 Erica changes starts
		--,null  V_BENEFIT_CATEGORY_R --populating all benefit payment detail records as null
      ,(CASE WHEN DGCDR.V_LOB_TYPE_R =  'NONS' THEN
        CASE WHEN DGCCGR.V_CLAIM_COVERAGE_CODE_R = 'END' then 'BENEFIT'
        WHEN DGCCGR.V_CLAIM_COVERAGE_CODE_R = 'GCM' then 'BENEFIT'
        WHEN DGCCGR.V_CLAIM_COVERAGE_CODE_R = 'LTY' then 'BENEFIT'
        WHEN DGCCGR.V_CLAIM_COVERAGE_CODE_R IN ('IDL', 'MML', 'ORL', 'PGL', 'PVG') then 'BENEFIT'
        WHEN DGCCGR.V_CLAIM_COVERAGE_CODE_R IN ('ASG', 'SPG', 'VAI','GPL') then 'BENEFIT'              -- Added GPL 06-Jun-2022 changes
        WHEN DGCCGR.V_CLAIM_COVERAGE_CODE_R = 'VCI' then 'OPTIONAL'
        WHEN DGCCGR.V_CLAIM_COVERAGE_CODE_R IN ('IWP', 'WP') then 'BENEFIT'
        ELSE 'BENEFIT'
        END
        WHEN DGCDR.V_LOB_TYPE_R =  'ANNUITY' THEN
        CASE WHEN DGCCR.V_CLAIM_COVERAGE_CODE_R = 'GAN' THEN 'BENEFIT'
        ELSE
            --CASE WHEN DGCCR.V_CLAIM_COVERAGE_CODE_R = 'SC' AND upper(DGCCR.V_COVERAGE_CODE_R) in ('J'||CHR(38)||'S',  'LIFE',  'LIFE w/PC') THEN '031'--05-JAN-2022 commented changes
            CASE WHEN DGCCR.V_CLAIM_COVERAGE_CODE_R = 'SC' AND upper(DGCCR.V_COVERAGE_CODE_R) in ('J'||CHR(38)||'S',  'LIFE',  'LIFE W/PC') THEN 'BENEFIT'--05-JAN-2022 changes
            ELSE 'BENEFIT'
            END
        END
        WHEN DGCDR.V_LOB_TYPE_R IN ( 'WOP', 'LIFE') THEN
        (CASE
        WHEN DGCCGR.V_BENEFIT_CODE_R = '076' THEN 'OPTIONAL'
        WHEN DGCCGR.V_BENEFIT_CODE_R = '079' THEN 'OPTIONAL'
        WHEN DGCCGR.V_BENEFIT_CODE_R = '064' THEN 'OPTIONAL'
        WHEN DGCCGR.V_BENEFIT_CODE_R = '057' THEN 'OPTIONAL'
        WHEN DGCCGR.V_BENEFIT_CODE_R = '04C' THEN 'BENEFIT'
        WHEN DGCCGR.V_BENEFIT_CODE_R = '055' THEN 'OPTIONAL'
        WHEN DGCCGR.V_BENEFIT_CODE_R = '081' THEN 'BENEFIT'
        WHEN DGCCGR.V_BENEFIT_CODE_R = '04B' THEN 'BENEFIT'
        WHEN DGCCGR.V_BENEFIT_CODE_R = '04E' THEN 'BENEFIT'
        WHEN DGCCGR.V_BENEFIT_CODE_R = '04A' THEN 'BENEFIT'
        WHEN DGCCGR.V_BENEFIT_CODE_R = '071' THEN 'OPTIONAL'
        WHEN DGCCGR.V_BENEFIT_CODE_R = '05G' THEN 'BENEFIT'
        WHEN DGCCGR.V_BENEFIT_CODE_R = '051' THEN 'BENEFIT'
        WHEN DGCCGR.V_BENEFIT_CODE_R = '068' THEN 'OPTIONAL'
        WHEN DGCCGR.V_BENEFIT_CODE_R = '05D' THEN 'BENEFIT'
        WHEN DGCCGR.V_BENEFIT_CODE_R = '059' THEN 'OPTIONAL'
        WHEN DGCCGR.V_BENEFIT_CODE_R = '05I' THEN 'BENEFIT'
        WHEN DGCCGR.V_BENEFIT_CODE_R = '05F' THEN 'BENEFIT'
        WHEN DGCCGR.V_BENEFIT_CODE_R = '013' THEN 'BENEFIT'
        WHEN DGCCGR.V_BENEFIT_CODE_R = '060' THEN 'OPTIONAL'
        WHEN DGCCGR.V_BENEFIT_CODE_R = '050' THEN 'BENEFIT'
        WHEN DGCCGR.V_BENEFIT_CODE_R = '049' THEN 'BENEFIT'
        WHEN DGCCGR.V_BENEFIT_CODE_R = '072' THEN 'OPTIONAL'
        WHEN DGCCGR.V_BENEFIT_CODE_R = '066' THEN 'BENEFIT'
        WHEN DGCCGR.V_BENEFIT_CODE_R = '04D' THEN 'BENEFIT'
        WHEN DGCCGR.V_BENEFIT_CODE_R = '052' THEN 'OPTIONAL'
        WHEN DGCCGR.V_BENEFIT_CODE_R = '058' THEN 'OPTIONAL'
        WHEN DGCCGR.V_BENEFIT_CODE_R = '053' THEN 'OPTIONAL'
        WHEN DGCCGR.V_BENEFIT_CODE_R = '05E' THEN 'BENEFIT'
        WHEN DGCCGR.V_BENEFIT_CODE_R = '069' THEN 'OPTIONAL'
        WHEN DGCCGR.V_BENEFIT_CODE_R = '067' THEN 'OPTIONAL'
        WHEN DGCCGR.V_BENEFIT_CODE_R = '065' THEN 'OPTIONAL'
        WHEN DGCCGR.V_BENEFIT_CODE_R = '128' THEN 'BENEFIT'
        WHEN DGCCGR.V_BENEFIT_CODE_R = '062' THEN 'OPTIONAL'
        WHEN DGCCGR.V_BENEFIT_CODE_R = '05A' THEN 'BENEFIT'
        WHEN DGCCGR.V_BENEFIT_CODE_R = '05B' THEN 'BENEFIT'
        WHEN DGCCGR.V_BENEFIT_CODE_R = '094' THEN 'OPTIONAL'
        WHEN DGCCGR.V_BENEFIT_CODE_R = '070' THEN 'OPTIONAL'
        WHEN DGCCGR.V_BENEFIT_CODE_R = '054' THEN 'OPTIONAL'
        WHEN DGCCGR.V_BENEFIT_CODE_R = '107' THEN 'BENEFIT'
        WHEN DGCCGR.V_BENEFIT_CODE_R = '056' THEN 'OPTIONAL'
        ELSE NULL
        END)
        WHEN DGCDR.V_LOB_TYPE_R IN ( 'LTD', 'STD', 'VPL', 'VPS' ) THEN 'BENEFIT'
        END
        )     V_BENEFIT_CATEGORY_R
		--21-May-2022 Erica changes ends
		--On 15-Jul-2021 Erica requested to add below columns
		,(CASE WHEN DGCDR.v_lob_type_r = 'ANNUITY'
        THEN FGW.n_modal_amount_r
        ELSE
                CASE
                  WHEN FBPR.n_primary_payee_r = 1
                  THEN FBPR.n_adj_gross_benefit_r
                  WHEN FBPR.n_primary_payee_r = 0
                  THEN FBPR.n_pay_amount_r
                END

            END)  N_PAID_CLAIM_BENEFITS_R -- Populating with Gross Amount
		,0 N_TAXABLE_BENEFIT_AMT_R
		,0 N_FEDERAL_TAX_WITHHELD_AMT_R
		,0 N_STATE_TAX_WITHHELD_AMT_R
		,0 N_EMPLOYEE_SS_WITHHELD_AMT_R
		,0 N_EMPLOYEE_MED_WITHHELD_AMT_R
		,0 N_EMPLOYER_SS_WITHHELD_AMT_R
		,0 N_EMPLOYER_MED_WITHHELD_AMT_R
		,0 N_LEGAL_EXPENSE_DIRECT_AMT_R
		,0 N_OTHER_EXPENSE_DIRECT_AMT_R
		--On 15-Jul-2021 Erica request ends
		,DGCDR.V_LOB_TYPE_R         -- to achieve On Erica's requirement 28-Jul-2021
		,FGW.N_MODAL_AMOUNT_R       -- to achieve On Erica's requirement 28-Jul-2021
		,FBPR.N_PRIMARY_PAYEE_R     -- to achieve On Erica's requirement 28-Jul-2021
		,FBPR.N_ADJ_GROSS_BENEFIT_R -- to achieve On Erica's requirement 28-Jul-2021
		,FBPR.N_PAY_AMOUNT_R        -- to achieve On Erica's requirement 28-Jul-2021
		,FBPR.N_CLAIM_SK_R          -- to achieve On Erica's requirement 28-Jul-2021
         --as requested by Erica on 16-Nov-2021
       ,(CASE WHEN DGCDR.V_LOB_TYPE_R =  'NONS' THEN
           CASE WHEN DGCCGR.V_CLAIM_COVERAGE_CODE_R = 'END' then '025'
           WHEN DGCCGR.V_CLAIM_COVERAGE_CODE_R = 'GCM' then '128'
           WHEN DGCCGR.V_CLAIM_COVERAGE_CODE_R = 'LTY' then '028'
           WHEN DGCCGR.V_CLAIM_COVERAGE_CODE_R IN ('IDL', 'MML', 'ORL', 'PGL', 'PVG') then '010'
           WHEN DGCCGR.V_CLAIM_COVERAGE_CODE_R IN ('ASG', 'SPG', 'VAI','GPL') then '051'               -- Added GPL 06-Jun-2022 changes
           WHEN DGCCGR.V_CLAIM_COVERAGE_CODE_R = 'VCI' then '079'
           WHEN DGCCGR.V_CLAIM_COVERAGE_CODE_R IN ('IWP', 'WP') then '013'
           ELSE '081'
           END
        WHEN DGCDR.V_LOB_TYPE_R =  'ANNUITY' THEN
           CASE WHEN DGCCR.V_CLAIM_COVERAGE_CODE_R = 'GAN' THEN '085'
           ELSE
           --CASE WHEN DGCCR.V_CLAIM_COVERAGE_CODE_R = 'SC' AND upper(DGCCR.V_COVERAGE_CODE_R) in ('J'||CHR(38)||'S',  'LIFE',  'LIFE w/PC') THEN '031'--05-JAN-2022 commented changes
           CASE WHEN DGCCR.V_CLAIM_COVERAGE_CODE_R = 'SC' AND upper(DGCCR.V_COVERAGE_CODE_R) in ('J'||CHR(38)||'S',  'LIFE',  'LIFE W/PC') THEN '031'--05-JAN-2022 changes
           ELSE '032'
           END
        END
        WHEN DGCDR.V_LOB_TYPE_R IN ( 'WOP', 'LIFE') THEN DGCCGR.V_BENEFIT_CODE_R
        WHEN DGCDR.V_LOB_TYPE_R IN ( 'LTD', 'STD', 'VPL', 'VPS' ) THEN '081'
        END
        ) V_GROSS_BENEFIT_CODE_R
		,FBPR.N_CLAIM_COVERAGE_SK_R                  --08-Apr-2022 Erica changes
		,FBPR.N_CLAIM_COVERAGE_GROUP_SK_R            --08-Apr-2022 Erica changes
        ,FBPR.v_source_system_name_r --14-Dec-2022 changes
		--27-SEP-2023 changes starts
		,pa.V_INDIVIDUAL_FIRST_NAME_R v_payee_first_name_r
		,pa.V_INDIVIDUAL_middle_NAME_R v_payee_middle_name_r
        ,pa.V_INDIVIDUAL_LAST_NAME_R v_payee_last_name_r
		,(case  when PD.V_PAYEE_TYPE_R = 'Agent' then ' UNK '
        when PD.V_PAYEE_TYPE_R = 'Beneficiary' then 'UNK'
        when PD.V_PAYEE_TYPE_R = 'Customer' then 'GRP'
        when PD.V_PAYEE_TYPE_R = 'Insured' then 'IND'
        when PD.V_PAYEE_TYPE_R = 'Vendor' then 'PRV' else PD.V_PAYEE_TYPE_R end )  V_PAYEE_TYPE_R
		--27-SEP-2023 changes ends
		,FGW.V_TAX_STATE_R--31-JAN-2024 changesg
		,pa.n_party_sk_r as n_party_sk_r --13-MAR-2024 Changes
		FROM ATOMIC.FCT_BENEFIT_PAYMENT_R FBPR
			,ATOMIC.DIM_GRP_CLAIM_DIR_R DGCDR
			,ATOMIC.FCT_GRP_WORKSHEET FGW
			--,ATOMIC.FCT_BENEFIT_PAYMENT_DETAIL_R FBPDR--Removing for gross benefit logic
			,ATOMIC.DIM_GRP_CLAIM_COVERAGE_GROUP_R DGCCGR
			,ATOMIC.DIM_GRP_CLAIM_COVERAGE_R DGCCR
			,(SELECT * FROM ATOMIC.dim_payment_details pd WHERE PD.V_ACTIVE_STATUS_R = 'Y') PD --27-SEP-2023 CHANGES
            ,(select * from dim_grp_party_r where v_active_status_r = 'Y'  and v_source_system_name_r = 'PACS')  pa --27-SEP-2023 CHANGES
		WHERE  UPPER(TRIM(FBPR.V_PAY_STATUS_R)) IN ('RELEASED','REVERSAL','REVERSED')
		AND FBPR.N_CLAIM_SK_R = DGCDR.N_CLAIM_SK_R
        and FBPR.N_CLAIM_COVERAGE_SK_R = DGCCR.N_CLAIM_COVERAGE_SK_R(+)
        and FBPR.N_CLAIM_COVERAGE_GROUP_SK_R = DGCCGR.N_CLAIM_COVERAGE_GROUP_SK_R(+)
		AND FGW.N_WORKSHEET_SEQ_NBR_OBJECTNM_R = FBPR.N_PARENT_OBJECTNUM_R
		AND FGW.N_SOURCE_SYSTEM_KEY_R = FBPR.N_PAY_SCHD_SOURCE_SYSTEM_KEY_R
		--AND FBPR.N_SOURCE_VERSION_SEQ_NUMBER_R = FBPDR.N_SOURCE_VERSION_SEQ_NUMBER_R(+)
		--AND FBPR.N_SEQ_R = FBPDR.N_GROUP_SEQ_R(+)
		--AND FBPR.N_PAY_SCHD_SOURCE_SYSTEM_KEY_R = FBPDR.N_PAY_DTL_SOURCE_SYSTEM_KEY_R(+)
		AND DGCDR.V_ACTIVE_STATUS_R         = 'Y'
        and nvl(DGCCGR.V_ACTIVE_STATUS_R,'Y') = 'Y'
        AND NVL(DGCCR.V_ACTIVE_STATUS_R, 'Y')  = 'Y'
        --and NVL(DGCCGR.V_CLAIM_COVERAGE_CODE_R,DGCCR.V_CLAIM_COVERAGE_CODE_R)  is null
		--AND FBPR.N_BATCH_ID_R = LN_N_BATCH_ID_R--26-Apr-2022 Full Load Changes
		--27-SEP-2023 changes starts
		AND DGCDR.N_SOURCE_SYSTEM_KEY_R =PD.V_PAYMNT_DTLS_SRC_SYS_KEY_R(+)  --19-SEP-2023 CHANGES,  TABLE ORDER REVERSED WITH OUTER JOIN
		AND FBPR.N_WORKSHEET_SEQ_NBR_OBJECTNM_R = PD.V_WORKSHEET_OBJECTNUM_R(+)  --19-SEP-2023 CHANGES,  TABLE ORDER REVERSED WITH OUTER JOIN
        AND NVL(FBPR.V_LINK_OBJECTNUM_R,0)=PD.V_PAYMNT_DTLS_SEQ_NBR_R(+) --19-SEP-2023 CHANGES,  TABLE ORDER REVERSED WITH OUTER JOIN AND NVL IMPLEMENTATION
        and pd.N_INSRD_PARTY_SK_R = pa.n_party_sk_r(+) --1509 change -added outer join to n_party_sk_r
		--1509 change - commented the below code
		--and pa.v_active_status_r = 'Y'
--        and pd.V_PAYMNT_DTLS_SEQ_NBR_R = (select max(a.V_PAYMNT_DTLS_SEQ_NBR_R)
--                                    from dim_payment_details a
--                                    where a.V_PAYMNT_DTLS_SRC_SYS_KEY_R = pd.V_PAYMNT_DTLS_SRC_SYS_KEY_R
--                                    and a.V_WORKSHEET_OBJECTNUM_R = pd.V_WORKSHEET_OBJECTNUM_R
--                                    and a.v_active_status_r = 'Y')


        --27-SEP-2023 changes ends
    AND NVL(FBPR.V_SOURCE_SYSTEM_NAME_R,'X@')='PACS'--07-Dec-2022  filter applied to stop SHINKA data
		;

  TYPE l_gb_fct_tbl_typ IS TABLE OF cur_gross_benefit%ROWTYPE INDEX BY BINARY_INTEGER;
  l_gb_fct_rec_typ   l_gb_fct_tbl_typ;

--28-Aug-2024 changes starts
--Cursor to fetch Check Dt
CURSOR cur_upd_chkdt_col 
IS
--30-Aug-2024 changes starts
SELECT d_min_check_date_r    
       ,n_claim_sk_r         
       ,n_source_system_key_r
       ,v_check_number_r     
  FROM fct_claim_payment_detail_expense_r_chkdt_gtt;
/*SELECT MIN(fcpder.d_check_date_r) min_d_check_date_r
	   --fcpder.v_claim_number_r
	   ,fcpder.n_claim_sk_r--,fcpder.n_paid_amount_r
       ,fcpder.n_source_system_key_r
	   ,fcpder.v_check_number_r
  FROM fct_claim_payment_detail_expense_r fcpder
 WHERE UPPER(fcpder.v_payment_status_r) ='PAID'
   AND EXISTS(SELECT 1 
                FROM fct_claim_payment_detail_expense_r fcpder1
               WHERE fcpder1.n_claim_sk_r                 = fcpder.n_claim_sk_r
				 AND fcpder1.n_source_system_key_r        = fcpder.n_source_system_key_r
				 AND fcpder1.v_check_number_r             = fcpder.v_check_number_r
				 AND UPPER(fcpder1.v_payment_status_r)    ='VOID'
				 AND UPPER(fcpder1.v_source_system_name_r)='PACS'
				 AND UPPER(fcpder.v_source_system_name_r )='PACS'
             )	
GROUP BY --fcpder.v_claim_number_r,
        fcpder.n_claim_sk_r--,fcpder.n_paid_amount_r
       ,fcpder.n_source_system_key_r
	   ,fcpder.v_check_number_r
	;
*/
--30-Aug-2024 changes ends

  TYPE var_upd_tbl_chkdt_type IS TABLE OF cur_upd_chkdt_col%ROWTYPE INDEX BY BINARY_INTEGER;
  lt_var_upd_tbl_chkdt_typ var_upd_tbl_chkdt_type;
--28-Aug-2024 changes ends
BEGIN

	IF LN_N_BATCH_ID_R IS NULL THEN
	  OUT_LOAD_STATUS:='a) BatchID(IN_BATCH_ID) is null hence terminating the program';
	 RAISE_APPLICATION_ERROR(-20001,'a) BatchID(IN_BATCH_ID) is null hence terminating the program');
	END IF;

	IF LN_N_LOAD_RUN_ID_R IS NULL THEN
	  OUT_LOAD_STATUS:='b) BatchID(IN_BATCH_ID) is null hence terminating the program';

	 RAISE_APPLICATION_ERROR(-20001,'b) BatchID(IN_BATCH_ID) is null hence terminating the program');
	END IF;

    BEGIN
	--V_GROUP_R CONTAINS CONCEPT VALUES SEPARATED WITH COMMA (EX: 'BENEFIT PAYMENT,ADJUSTMENT,EXPENSE,DISBURSEMENT') etc
	--for all the conncepts the value should be 'ALL'
    SELECT V_GROUP_R ,N_BULK_LIMIT_R
	 INTO LC_SOURCE_CONCEPT,LN_BULK_LIMIT_R
    FROM ATOMIC.PRCS_GRP_DATAINGESTION_PARAM_R
    WHERE V_PARAM_NAME_R='PACS_GRP_LOAD_FCT_CLAIM_PAYMENT_DETAIL_R_'||LC_SOURCE_CONCEPT;
	EXCEPTION
	WHEN OTHERS THEN
	LC_SOURCE_CONCEPT:='ALL';
	END;
	IF LN_BULK_LIMIT_R IS NULL THEN
	   LN_BULK_LIMIT_R:=500000;
	END IF;

	IF IN_TYPE IS NULL THEN

	  IF LC_SOURCE_CONCEPT IS NULL THEN
	     LC_SOURCE_CONCEPT:='ALL';
	  END IF;
	ELSE
	   LC_SOURCE_CONCEPT:=IN_TYPE;
    END IF;
    /*SELECT NVL(MAX(N_SEQUENCE_NUMBER_R),0) INTO LN_MAX_SEQ_NUMER_R
    FROM ATOMIC.FCT_CLAIM_PAYMENT_DETAIL_R;*/
	IF LC_SOURCE_CONCEPT = 'ALL' OR LC_SOURCE_CONCEPT = 'BENEFIT_PAYMENT' THEN
	-- BENEFIT PAYMENT Data Load Starts

	--08-Jun-2022 changes starts
	EXECUTE IMMEDIATE 'TRUNCATE TABLE ATOMIC.FCT_CLAIM_PAYMENT_DETAIL_BENEFIT_PAYMENT_R PURGE SNAPSHOT LOG';
	--ATOMIC.PROC_TRUNCATE_PARTITION('FCT_CLAIM_PAYMENT_DETAIL_R','BENEFIT_PAYMENT',LN_N_BATCH_ID_R);
	--COMMIT;
	--BEGIN PRC_FCT_CLAIM_PMNT_DET_GAT_TBL_STATS; END;--Gather table and index stats
	--08-Jun-2022 changes ends
	SAVEPOINT SP1;

		/*SELECT NVL(MAX(N_SEQUENCE_NUMBER_R),0) INTO LN_MAX_SEQ_NUMER_R
		FROM ATOMIC.FCT_CLAIM_PAYMENT_DETAIL_R;*/
        BEGIN
        OPEN cur_benefit_payment;
        LOOP
            l_fct_rec_typ.DELETE;
            FETCH cur_benefit_payment BULK COLLECT INTO l_fct_rec_typ LIMIT ln_bulk_limit_r;
            FORall I IN l_fct_rec_typ.FIRST .. l_fct_rec_typ.COUNT --SAVE EXCEPTIONS
	        INSERT  /*+APPEND_VALUES*/  INTO ATOMIC.FCT_CLAIM_PAYMENT_DETAIL_BENEFIT_PAYMENT_R
	    	( V_CLAIM_NUMBER_R
	    	 ,V_COVERAGE_CODE_R
	    	 ,V_COV_GROUP_ID_R
	    	 ,V_CHECK_NUMBER_R
	    	 ,V_PAY_METHOD_R
	    	 ,V_BENEFIT_CODE_R
	    	 ,V_BENEFIT_DESCRIPTION_R
	    	 ,V_BENEFIT_GROUP_R
	    	 ,N_GROSS_WAGE_BASE_R
	    	 ,N_TAXABLE_PERCENT_R
	    	 ,V_PAYMENT_STATUS_R
	    	 ,N_PAID_AMOUNT_R
	    	 ,V_PAYMENT_TYPE_R
	    	 ,D_CHECK_DATE_R
	    	 ,V_CHECK_TYPE_R
	    	 ,D_PAID_DATE_R
	    	 ,N_GROSS_AMOUNT_R
	    	 ,D_SERVICE_PERIOD_FROM_R
	    	 ,D_SERVICE_PERIOD_TO_R
	    	 ,V_RECORD_TYPE_R
	    	 ,N_WORKSHEET_OBJECT_NUM_R
	    	 ,N_SOURCE_SYSTEM_KEY_R
	    	 ,N_SOURCE_VERSION_SEQ_NUMBER_R
	    	 ,N_SEQ_R
	    	 ,N_GROUP_SEQ_R
	    	 ,N_PARENT_OBJECTNUM_R
	    	 ,T_CREATION_DATE_R
	    	 ,T_EVENT_TIMESTAMP_R
	    	 ,T_LAST_MODIFIED_DATE_R
	    	 ,V_CREATED_BY_R
	    	 ,V_LAST_MODIFIED_BY_R
	    	 ,FIC_MIS_DATE_R
	    	 ,N_BATCH_ID_R
	    	 ,N_LOAD_RUN_ID_R
	    	 ,N_SEQUENCE_NUMBER_R
	    	 ,V_BENEFIT_CATEGORY_R
             ,N_PAID_CLAIM_BENEFITS_R
             ,N_TAXABLE_BENEFIT_AMT_R
             ,N_FEDERAL_TAX_WITHHELD_AMT_R
             ,N_STATE_TAX_WITHHELD_AMT_R
             ,N_EMPLOYEE_SS_WITHHELD_AMT_R
             ,N_EMPLOYEE_MED_WITHHELD_AMT_R
             ,N_EMPLOYER_SS_WITHHELD_AMT_R
             ,N_EMPLOYER_MED_WITHHELD_AMT_R
             ,N_LEGAL_EXPENSE_DIRECT_AMT_R
             ,N_OTHER_EXPENSE_DIRECT_AMT_R
             ,V_LOB_TYPE_R                           --to achieve On Erica's requirement 28-Jul-2021
             ,N_MODAL_AMOUNT_R                       --to achieve On Erica's requirement 28-Jul-2021
             ,N_PRIMARY_PAYEE_R                      --to achieve On Erica's requirement 28-Jul-2021
             ,N_ADJ_GROSS_BENEFIT_R                  --to achieve On Erica's requirement 28-Jul-2021
             ,N_PAY_AMOUNT_R                         --to achieve On Erica's requirement 28-Jul-2021
             ,N_CLAIM_SK_R                           --to achieve On Erica's requirement 28-Jul-2021
             ,V_GROSS_BENEFIT_CODE_R                 --As requested by Erica on 16-Nov-2021
	    	 ,N_CLAIM_COVERAGE_SK_R                  --08-Apr-2022 Erica changes
	    	 ,N_CLAIM_COVERAGE_GROUP_SK_R            --08-Apr-2022 Erica changes
             ,N_FBPDR_N_SEQ_R --10-Nov-2022 changes for Merge
			 ,v_source_system_name_r --14-Dec-2022 changes
			 ,N_SS_WAGE_BASE_R   --27-SEP-2023 changes
			 ,N_MED_WAGE_BASE_R  --27-SEP-2023 changes
			 ,v_payee_first_name_r--27-SEP-2023 changes
			 ,v_payee_middle_name_r--27-SEP-2023 changes
			 ,v_payee_last_name_r--27-SEP-2023 changes
			 ,V_PAYEE_TYPE_R----27-SEP-2023 changes
			 ,V_TAX_STATE_R---31-JAN-2024 changes
			 ,n_party_sk_r --13-MAR-2024 Changes
             --29-May-2024 changes starts
             ,V_AMOUNT_TYPE_SUB_NAME_R,
             V_AMOUNT_TYPE_CATEGORY_R,
             V_AMOUNT_TYPE_CATEGORY_DESC_R,
             V_AMOUNT_TYPE_SUB_CATEGORY_R,
             V_AMT_TYPE_SUB_CATEGORY_DESC_R,
             V_AMOUNT_TYPE_CODE_R,
             V_AMOUNT_TYPE_NAME_R,
             V_AMOUNT_TYPE_SUB_CODE_R
             --29-May-2024 changes ends
	    	)
	        VALUES(l_fct_rec_typ(i).V_CLAIM_NUMBER_R
                ,l_fct_rec_typ(i).V_COVERAGE_CODE_R
                ,l_fct_rec_typ(i).V_COV_GROUP_ID_R
                ,l_fct_rec_typ(i).V_CHECK_NUMBER_R
                ,l_fct_rec_typ(i).V_PAY_METHOD_R
                ,l_fct_rec_typ(i).V_BENEFIT_CODE_R
                ,l_fct_rec_typ(i).V_BENEFIT_DESCRIPTION_R
                ,l_fct_rec_typ(i).V_BENEFIT_GROUP_R
                ,l_fct_rec_typ(i).N_GROSS_WAGE_BASE_R
                ,l_fct_rec_typ(i).N_TAXABLE_PERCENT_R
                ,l_fct_rec_typ(i).V_PAYMENT_STATUS_R
                ,l_fct_rec_typ(i).N_PAID_AMOUNT_R
                ,l_fct_rec_typ(i).V_PAYMENT_TYPE_R
                ,l_fct_rec_typ(i).D_CHECK_DATE_R
                ,l_fct_rec_typ(i).V_CHECK_TYPE_R
                ,l_fct_rec_typ(i).D_PAID_DATE_R
                ,l_fct_rec_typ(i).N_GROSS_AMOUNT_R
                ,l_fct_rec_typ(i).D_SERVICE_PERIOD_FROM_R
                ,l_fct_rec_typ(i).D_SERVICE_PERIOD_TO_R
                ,l_fct_rec_typ(i).V_RECORD_TYPE_R
                ,l_fct_rec_typ(i).N_WORKSHEET_OBJECT_NUM_R
                ,l_fct_rec_typ(i).N_SOURCE_SYSTEM_KEY_R
                ,l_fct_rec_typ(i).N_SOURCE_VERSION_SEQ_NUMBER_R
                ,l_fct_rec_typ(i).N_SEQ_R
                ,l_fct_rec_typ(i).N_GROUP_SEQ_R
                ,l_fct_rec_typ(i).N_PARENT_OBJECTNUM_R
                ,l_fct_rec_typ(i).T_CREATION_DATE_R
                ,l_fct_rec_typ(i).T_EVENT_TIMESTAMP_R
                ,l_fct_rec_typ(i).T_LAST_MODIFIED_DATE_R
                ,l_fct_rec_typ(i).V_CREATED_BY_R
                ,l_fct_rec_typ(i).V_LAST_MODIFIED_BY_R
                ,l_fct_rec_typ(i).FIC_MIS_DATE_R
                ,l_fct_rec_typ(i).N_BATCH_ID_R
                ,l_fct_rec_typ(i).N_LOAD_RUN_ID_R
                ,l_fct_rec_typ(i).N_SEQUENCE_NUMBER_R
                ,l_fct_rec_typ(i).V_BENEFIT_CATEGORY_R
                ,l_fct_rec_typ(i).N_PAID_CLAIM_BENEFITS_R
                ,l_fct_rec_typ(i).N_TAXABLE_BENEFIT_AMT_R
                ,l_fct_rec_typ(i).N_FEDERAL_TAX_WITHHELD_AMT_R
                ,l_fct_rec_typ(i).N_STATE_TAX_WITHHELD_AMT_R
                ,l_fct_rec_typ(i).N_EMPLOYEE_SS_WITHHELD_AMT_R
                ,l_fct_rec_typ(i).N_EMPLOYEE_MED_WITHHELD_AMT_R
                ,l_fct_rec_typ(i).N_EMPLOYER_SS_WITHHELD_AMT_R
                ,l_fct_rec_typ(i).N_EMPLOYER_MED_WITHHELD_AMT_R
                ,l_fct_rec_typ(i).N_LEGAL_EXPENSE_DIRECT_AMT_R
                ,l_fct_rec_typ(i).N_OTHER_EXPENSE_DIRECT_AMT_R
                ,l_fct_rec_typ(i).V_LOB_TYPE_R
                ,l_fct_rec_typ(i).N_MODAL_AMOUNT_R
                ,l_fct_rec_typ(i).N_PRIMARY_PAYEE_R
                ,l_fct_rec_typ(i).N_ADJ_GROSS_BENEFIT_R
                ,l_fct_rec_typ(i).N_PAY_AMOUNT_R
                ,l_fct_rec_typ(i).N_CLAIM_SK_R
                ,l_fct_rec_typ(i).V_GROSS_BENEFIT_CODE_R
                ,l_fct_rec_typ(i).N_CLAIM_COVERAGE_SK_R
                ,L_FCT_REC_TYP(I).N_CLAIM_COVERAGE_GROUP_SK_R
                ,L_FCT_REC_TYP(I).N_FBPR_N_SEQ_R --10-Nov-2022 changes for Merge
				,l_fct_rec_typ(i).v_source_system_name_r --14-Dec-2022 changes
				,l_fct_rec_typ(i).N_SS_WAGE_BASE_R    --07-JUL-2023 changes
				,l_fct_rec_typ(i).N_MED_WAGE_BASE_R   --07-JUL-2023 changes
			    ,l_fct_rec_typ(i).v_payee_first_name_r--27-SEP-2023 changes
			    ,l_fct_rec_typ(i).v_payee_middle_name_r--27-SEP-2023 changes
			    ,l_fct_rec_typ(i).v_payee_last_name_r--27-SEP-2023 changes
				,l_fct_rec_typ(i).V_PAYEE_TYPE_R--27-SEP-2023 changes
				,l_fct_rec_typ(i).V_TAX_STATE_R--31-JAN-2024 changes
				,l_fct_rec_typ(i).n_party_sk_r --13-MAR-2024 Changes
                --29-May-2024 changes starts
                ,l_fct_rec_typ(i).V_AMOUNT_TYPE_SUB_NAME_R,
                l_fct_rec_typ(i).V_AMOUNT_TYPE_CATEGORY_R,
                l_fct_rec_typ(i).V_AMOUNT_TYPE_CATEGORY_DESC_R,
                l_fct_rec_typ(i).V_AMOUNT_TYPE_SUB_CATEGORY_R,
                l_fct_rec_typ(i).V_AMT_TYPE_SUB_CATEGORY_DESC_R,
                l_fct_rec_typ(i).V_AMOUNT_TYPE_CODE_R,
                l_fct_rec_typ(i).V_AMOUNT_TYPE_NAME_R,
                l_fct_rec_typ(i).V_AMOUNT_TYPE_SUB_CODE_R
                --29-May-2024 changes ends
	         );
        commit;
        EXIT WHEN cur_benefit_payment%NOTFOUND;
        END LOOP;
        CLOSE CUR_BENEFIT_PAYMENT;

        EXCEPTION
        WHEN OTHERS THEN
        LC_SQLCODE:=SQLCODE;
        LC_SQLERRM:=SUBSTR(SQLERRM,1,4000);
        OUT_LOAD_STATUS:='1)Benefit Payment Error :-'||LC_SQLCODE||'-'||LC_SQLERRM;
	    ROLLBACK TO SAVEPOINT SP1;
	    RAISE_APPLICATION_ERROR(-20001,'1)Benefit Payment Error :-'||LC_SQLCODE||'-'||LC_SQLERRM);
        END ;
      -- Benefit Payment Data Load ends
    END IF;

       -- BEGIN

			/*OPEN cur_bene_pymnt_claim_cnt('Benefit Payment');
			LOOP
				l_bene_pymnt_claim_rec_typ.DELETE;

				FETCH cur_bene_pymnt_claim_cnt BULK COLLECT INTO l_bene_pymnt_claim_rec_typ LIMIT LN_BULK_LIMIT_R;
				FOR i IN 1..l_bene_pymnt_claim_rec_typ.COUNT
				LOOP
					LN_GROSS_AMT_R:=ATOMIC.PKG_GRP_FULLLOAD_FCT_CLAIM_PAYMENT_DETAIL_R.GET_N_GROSS_AMOUNT_R(l_bene_pymnt_claim_rec_typ(i).ROWCOUNT
														,l_bene_pymnt_claim_rec_typ(i).V_CLAIM_NUMBER_R
														,L_BENE_PYMNT_CLAIM_REC_TYP(I).N_SOURCE_VERSION_SEQ_NUMBER_R
                            ,LN_N_BATCH_ID_R);
					UPDATE PARALLEL(4) ATOMIC.FCT_CLAIM_PAYMENT_DETAIL_R
					SET n_gross_amount_r = ln_gross_amt_r
					WHERE v_claim_number_r=l_bene_pymnt_claim_rec_typ(i).v_claim_number_r
					AND n_source_version_seq_number_r =l_bene_pymnt_claim_rec_typ(i).n_source_version_seq_number_r
					and v_record_type_r = 'Benefit Payment'
          AND N_BATCH_ID_R=LN_N_BATCH_ID_R
					 ;
					commit;

				END LOOP;--FOR i IN 1..l_bene_pymnt_claim_rec_typ.COUNT
			EXIT WHEN cur_bene_pymnt_claim_cnt%NOTFOUND;
			END LOOP;
			CLOSE cur_bene_pymnt_claim_cnt;

		EXCEPTION
		WHEN OTHERS THEN
           LC_SQLCODE:=SQLCODE;
           LC_SQLERRM:=SUBSTR(SQLERRM,1,4000);
           OUT_LOAD_STATUS:='1)Benefit Payment n_gross_amount_r Update error:-'||LC_SQLCODE||'-'||LC_SQLERRM;
	       ROLLBACK TO SAVEPOINT SP1;
	       RAISE_APPLICATION_ERROR(-20001,'1)Benefit Payment n_gross_amount_r Update error :-'||LC_SQLCODE||'-'||LC_SQLERRM);
		END;

		*/
        -- Benefit Payment Data Load ends
	commit;
	/*SELECT NVL(MAX(N_SEQUENCE_NUMBER_R),0) INTO LN_MAX_SEQ_NUMER_R
	FROM ATOMIC.FCT_CLAIM_PAYMENT_DETAIL_R;*/

	IF LC_SOURCE_CONCEPT = 'ALL' OR LC_SOURCE_CONCEPT LIKE 'ADJUSTMENT' THEN
	-- Adjustment Data Load Starts
	--08-Jun-2022 changes starts
	EXECUTE IMMEDIATE 'TRUNCATE TABLE ATOMIC.FCT_CLAIM_PAYMENT_DETAIL_ADJUSTMENT_R PURGE SNAPSHOT LOG';
	--COMMIT;
	--BEGIN PRC_FCT_CLAIM_PMNT_DET_GAT_TBL_STATS; END;--Gather table and index stats
	--ATOMIC.PROC_TRUNCATE_PARTITION('FCT_CLAIM_PAYMENT_DETAIL_R','ADJUSTMENT',LN_N_BATCH_ID_R);
	--08-Jun-2022 changes ends
	SAVEPOINT SP2;
	BEGIN
	INSERT  /*+APPEND */  INTO ATOMIC.FCT_CLAIM_PAYMENT_DETAIL_ADJUSTMENT_R
		(V_CLAIM_NUMBER_R
		 ,V_COVERAGE_CODE_R
		 ,V_COV_GROUP_ID_R
		 ,V_CHECK_NUMBER_R
		 ,V_PAY_METHOD_R
		 ,V_BENEFIT_CODE_R
		 ,V_BENEFIT_DESCRIPTION_R
		 ,V_BENEFIT_GROUP_R
		 ,N_GROSS_WAGE_BASE_R
		 ,N_TAXABLE_PERCENT_R
		 ,V_PAYMENT_STATUS_R
		 ,N_PAID_AMOUNT_R
		 ,V_PAYMENT_TYPE_R
		 ,D_CHECK_DATE_R
		 ,V_CHECK_TYPE_R
		 ,D_PAID_DATE_R
		 ,N_GROSS_AMOUNT_R
		 ,D_SERVICE_PERIOD_FROM_R
		 ,D_SERVICE_PERIOD_TO_R
		 ,V_RECORD_TYPE_R
		 ,N_WORKSHEET_OBJECT_NUM_R
		 ,N_SOURCE_SYSTEM_KEY_R
		 ,N_SOURCE_VERSION_SEQ_NUMBER_R
		 ,N_SEQ_R
		 ,N_GROUP_SEQ_R
		 ,N_PARENT_OBJECTNUM_R
		 ,T_CREATION_DATE_R
		 ,T_EVENT_TIMESTAMP_R
		 ,T_LAST_MODIFIED_DATE_R
		 ,V_CREATED_BY_R
		 ,V_LAST_MODIFIED_BY_R
		 ,FIC_MIS_DATE_R
		 ,N_BATCH_ID_R
		 ,N_LOAD_RUN_ID_R
		 ,N_SEQUENCE_NUMBER_R
		 ,V_BENEFIT_CATEGORY_R
		 ,N_PAID_CLAIM_BENEFITS_R   --Erica requested changes on 15-Dec
		,N_CLAIM_SK_R                           --08-Apr-2022 Erica changes
		,N_CLAIM_COVERAGE_SK_R                  --08-Apr-2022 Erica changes
		,N_CLAIM_COVERAGE_GROUP_SK_R            --08-Apr-2022 Erica changes
		 --27-SEP-2023 changes starts
		,V_PAYEE_FIRST_NAME_R
        ,V_PAYEE_MIDDLE_NAME_R
        ,V_PAYEE_LAST_NAME_R
		,V_PAYEE_TYPE_R
		 --27-SEP-2023 changes ends
		 ,N_PARTY_SK_R							--12-MAR-2024 Changes
        --29-May-2024 changes starts
        ,V_AMOUNT_TYPE_SUB_NAME_R,
        V_AMOUNT_TYPE_CATEGORY_R,
        V_AMOUNT_TYPE_CATEGORY_DESC_R,
        V_AMOUNT_TYPE_SUB_CATEGORY_R,
        V_AMT_TYPE_SUB_CATEGORY_DESC_R,
        V_AMOUNT_TYPE_CODE_R,
        V_AMOUNT_TYPE_NAME_R,
        V_AMOUNT_TYPE_SUB_CODE_R,
		n_adj_trans_amount_r
        --29-May-2024 changes ends
		)
		SELECT
		V_CLAIM_NUMBER_R
		,V_COVERAGE_CODE_R
		,V_COV_GROUP_ID_R
		,V_CHECK_NUMBER_R
		,V_PAY_METHOD_R
		,V_BENEFIT_CODE_R
		,V_BENEFIT_DESCRIPTION_R
		,V_BENEFIT_GROUP_R
		,N_GROSS_WAGE_BASE_R
		,N_TAXABLE_PERCENT_R
		,V_PAYMENT_STATUS_R
		,N_PAID_AMOUNT_R
		,V_PAYMENT_TYPE_R
		,D_CHECK_DATE_R
		,V_CHECK_TYPE_R
		,D_PAID_DATE_R
		,N_GROSS_AMOUNT_R
		,D_SERVICE_PERIOD_FROM_R
		,D_SERVICE_PERIOD_TO_R
		,V_RECORD_TYPE_R
		,N_WORKSHEET_OBJECT_NUM_R
		,N_SOURCE_SYSTEM_KEY_R
		,N_SOURCE_VERSION_SEQ_NUMBER_R
		,N_SEQ_R
		,N_GROUP_SEQ_R
		,N_PARENT_OBJECTNUM_R
		,LT_systimestamp                        T_CREATION_DATE_R
		,LT_systimestamp                        T_EVENT_TIMESTAMP_R
		,LT_systimestamp                        T_LAST_MODIFIED_DATE_R
		,'ODI'                                  V_CREATED_BY_R
		,'ODI'                                  V_LAST_MODIFIED_BY_R
		--,TRUNC(SYSDATE)                         FIC_MIS_DATE_R--26-Apr-2022 Full Load Changes
		--,LN_N_BATCH_ID_R                     	N_BATCH_ID_R--26-Apr-2022 Full Load Changes
		,FIC_MIS_DATE_R                    --26-Apr-2022 Full Load Changes
		,N_BATCH_ID_R                     	N_BATCH_ID_R
		,LN_N_LOAD_RUN_ID_R                     N_LOAD_RUN_ID_R
		,(NVL(LN_MAX_SEQ_NUMER_R,0)+ROWNUM)     N_SEQUENCE_NUMBER_R
		,V_BENEFIT_CATEGORY_R
		,N_PAID_CLAIM_BENEFITS_R                --Erica requested changes on 15-Dec
		,N_CLAIM_SK_R                           --08-Apr-2022 Erica changes
		,N_CLAIM_COVERAGE_SK_R                  --08-Apr-2022 Erica changes
		,N_CLAIM_COVERAGE_GROUP_SK_R            --08-Apr-2022 Erica changes
		--27-SEP-2023 changes starts
		,V_PAYEE_FIRST_NAME_R
        ,V_PAYEE_MIDDLE_NAME_R
        ,V_PAYEE_LAST_NAME_R
		,V_PAYEE_TYPE_R
		--27-SEP-2023 changes ends
		,N_PARTY_SK_R							--12-MAR-2024 Changes
        --29-May-2024 changes starts
        ,V_AMOUNT_TYPE_SUB_NAME_R,
        V_AMOUNT_TYPE_CATEGORY_R,
        V_AMOUNT_TYPE_CATEGORY_DESC_R,
        V_AMOUNT_TYPE_SUB_CATEGORY_R,
        V_AMT_TYPE_SUB_CATEGORY_DESC_R,
        V_AMOUNT_TYPE_CODE_R,
        V_AMOUNT_TYPE_NAME_R,
        V_AMOUNT_TYPE_SUB_CODE_R,
		n_adj_trans_amount_r
        --29-May-2024 changes ends
		FROM
		(
		SELECT /*+enable_parallel_dml parallel(8)*/
		DIM_GRP_CLAIM_DIR_R.V_CLAIM_NUMBER_R                          V_CLAIM_NUMBER_R
		--05-Oct-2021 Erica Adjustment query changes starts
		/*,DIM_GRP_CLAIM_COVERAGE_R.V_COVERAGE_CODE_R                   V_COVERAGE_CODE_R
		,DIM_GRP_CLAIM_COVERAGE_GROUP_R.V_COV_GRP_CODE_R              V_COV_GROUP_ID_R*/
		,NVL(DIM_GRP_CLAIM_COVERAGE_GROUP_R.V_CLAIM_COVERAGE_CODE_R,DIM_GRP_CLAIM_COVERAGE_R.V_CLAIM_COVERAGE_CODE_R)   V_COVERAGE_CODE_R
		,DIM_GRP_CLAIM_COVERAGE_GROUP_R.N_COV_GRP_ID_R              V_COV_GROUP_ID_R
		--05-Oct-2021 Erica Adjustment query changes ends
		,(case when UPPER((SUBSTR(FCT_CLAIM_ADJUSTMENT_R.V_ADJUSTMENT_DESC_R,1,9))) = 'APPLYCHQ#'
		THEN replace(trim(substr(substr(FCT_CLAIM_ADJUSTMENT_R.v_adjustment_desc_r,instr(FCT_CLAIM_ADJUSTMENT_R.v_adjustment_desc_r,'=')+1) ,1
					,instr(substr(FCT_CLAIM_ADJUSTMENT_R.v_adjustment_desc_r,instr(FCT_CLAIM_ADJUSTMENT_R.v_adjustment_desc_r,'=')) ,','))
					),',')
		when (UPPER(FCT_CLAIM_ADJUSTMENT_R.V_ADJUSTMENT_TYPE_R) like 'SSWAGEBASE%'
					OR UPPER(FCT_CLAIM_ADJUSTMENT_R.V_ADJUSTMENT_TYPE_R) LIKE 'MEDWAGEBASE%')
		THEN 'NONE'
		--As requested by Gisha 05-Nov-2021 starts
		/*when (UPPER(FCT_CLAIM_ADJUSTMENT_R.V_ADJ_TRANS_STATUS_R) = 'TRNFR'
		AND UPPER(FCT_CLAIM_ADJUSTMENT_R.V_ADJ_TRANSACTION_CODE_R) NOT LIKE 'GENERAL%')
		then 'XFER'*/
		when (UPPER(SUBSTR(FCT_CLAIM_ADJUSTMENT_R. V_ADJUSTMENT_DESC_R,1,5)) = 'TRNFR'
        AND UPPER(FCT_CLAIM_ADJUSTMENT_R.V_ADJ_TRANSACTION_CODE_R) NOT LIKE 'GENERAL%')
        then 'XFER'
		--As requested by Gisha 05-Nov-2021 ends
		else null
		end
		)                                                            V_CHECK_NUMBER_R
		,NULL                                                        V_PAY_METHOD_R
		,FCT_CLAIM_ADJUSTMENT_R.V_AMOUNT_TYPE_SUB_CODE_R             V_BENEFIT_CODE_R
		,FCT_CLAIM_ADJUSTMENT_R.V_AMOUNT_TYPE_NAME_R	             V_BENEFIT_DESCRIPTION_R
		,FCT_CLAIM_ADJUSTMENT_R.V_AMOUNT_TYPE_CODE_R	             V_BENEFIT_GROUP_R
		--26-Apr-2022 Erica changes starts
		--,NULL                                                        N_GROSS_WAGE_BASE_R
        ,(CASE WHEN FCT_CLAIM_ADJUSTMENT_R.V_AMOUNT_TYPE_SUB_CODE_R LIKE 'W%' THEN FCT_CLAIM_ADJUSTMENT_R.n_adj_trans_amount_r
        WHEN FCT_CLAIM_ADJUSTMENT_R.V_AMOUNT_TYPE_SUB_CODE_R LIKE 'Z%' THEN FCT_CLAIM_ADJUSTMENT_R.n_adj_trans_amount_r
        ELSE 0 end)                                                  N_GROSS_WAGE_BASE_R
		--26-Apr-2022 Erica changes ends
		,FGB.N_TAXABLE_PERCENT_R                                     N_TAXABLE_PERCENT_R
		,'R'                                                         V_PAYMENT_STATUS_R
		--26-Apr-2022 Erica changes starts
		--,FCT_CLAIM_ADJUSTMENT_R.n_adj_trans_amount_r                 N_PAID_AMOUNT_R
       --06-May-2022 Erica changes starts
	   /*,(CASE WHEN FCT_CLAIM_ADJUSTMENT_R.V_AMOUNT_TYPE_SUB_CODE_R LIKE 'W%'THEN 0
        WHEN FCT_CLAIM_ADJUSTMENT_R.V_AMOUNT_TYPE_SUB_CODE_R LIKE 'Z%' THEN 0
        ELSE FCT_CLAIM_ADJUSTMENT_R.n_adj_trans_amount_r end)          N_PAID_AMOUNT_R
        --26-Apr-2022 Erica changes ends
		*/
        ,(
          CASE
          WHEN fct_claim_adjustment_r.v_amount_type_sub_code_r LIKE 'W%' THEN
                        0
          WHEN fct_claim_adjustment_r.v_amount_type_sub_code_r LIKE 'Z%' THEN
                        0
          WHEN upper(fct_claim_adjustment_r.v_adj_trans_status_r) = 'RELEASED' THEN
                        fct_claim_adjustment_r.n_adj_trans_amount_r * - 1
          WHEN upper(fct_claim_adjustment_r.v_adj_trans_status_r) = 'EXCLUDED'
                        AND
                        substr(fct_claim_adjustment_r.v_adjustment_desc_r, 1, 5) = 'TRNFR' THEN
                                       (
                                        CASE
                                        WHEN substr(fct_claim_adjustment_r.v_adjustment_desc_r, 8, 2) = 'DR' THEN
                                                      fct_claim_adjustment_r.n_adj_trans_amount_r * - 1
                                        ELSE
                                                      fct_claim_adjustment_r.n_adj_trans_amount_r
                                        END
                                       )
         ELSE
                        0
         END
        ) N_PAID_AMOUNT_R
		--06-May-2022 Erica changes ends
		,'ADJ'                                                       V_PAYMENT_TYPE_R
		,FCT_CLAIM_ADJUSTMENT_R.d_adj_trans_date_r                   D_CHECK_DATE_R
		,'BP'                                                        V_CHECK_TYPE_R
		,FCT_CLAIM_ADJUSTMENT_R.d_adj_trans_date_r                   D_PAID_DATE_R
		,NULL                                                        N_GROSS_AMOUNT_R
		,FCT_CLAIM_ADJUSTMENT_R.d_adj_trans_date_r                   D_SERVICE_PERIOD_FROM_R	--As requested by Erica on 12-Nov-2021
		,FCT_CLAIM_ADJUSTMENT_R.d_adj_trans_date_r                   D_SERVICE_PERIOD_TO_R	  --As requested by Erica on 12-Nov-2021
		,'Adjustment'                                                V_RECORD_TYPE_R
		,NULL                                                        N_WORKSHEET_OBJECT_NUM_R
		,FCT_CLAIM_ADJUSTMENT_R.N_ADJ_SOURCE_SYSTEM_KEY_R            N_SOURCE_SYSTEM_KEY_R
		,FCT_CLAIM_ADJUSTMENT_R.N_SOURCE_VERSION_SEQ_NUMBER_R        N_SOURCE_VERSION_SEQ_NUMBER_R
		,NULL                                                        N_SEQ_R
		,NULL                                                        N_GROUP_SEQ_R
		,NULL                                                        N_PARENT_OBJECTNUM_R
		,FCT_CLAIM_ADJUSTMENT_R.V_AMOUNT_TYPE_CATEGORY_DESC_R        V_BENEFIT_CATEGORY_R
        --26-Apr-2022 Erica changes starts
		--,FCT_CLAIM_ADJUSTMENT_R.n_adj_trans_amount_r                 N_PAID_CLAIM_BENEFITS_R                --Erica requested changes on 15-Dec
        --06-May-2022 Erica changes starts
		/*,(CASE WHEN FCT_CLAIM_ADJUSTMENT_R.V_AMOUNT_TYPE_SUB_CODE_R LIKE 'W%'THEN 0
        WHEN FCT_CLAIM_ADJUSTMENT_R.V_AMOUNT_TYPE_SUB_CODE_R LIKE 'Z%' THEN 0
        ELSE FCT_CLAIM_ADJUSTMENT_R.n_adj_trans_amount_r end)                N_PAID_CLAIM_BENEFITS_R
		--26-Apr-2022 Erica changes ends*/
        ,(
          CASE
          WHEN fct_claim_adjustment_r.v_amount_type_sub_code_r LIKE 'W%' THEN
                        0
          WHEN fct_claim_adjustment_r.v_amount_type_sub_code_r LIKE 'Z%' THEN
                        0
          WHEN FCT_CLAIM_ADJUSTMENT_R.V_AMOUNT_TYPE_CODE_R IN  ('098', '097', '099', '297',  '298' ) THEN 0-- 05-Oct-2022 Erica changes
          WHEN upper(fct_claim_adjustment_r.v_adj_trans_status_r) = 'RELEASED' THEN
                        fct_claim_adjustment_r.n_adj_trans_amount_r * - 1
          WHEN upper(fct_claim_adjustment_r.v_adj_trans_status_r) = 'EXCLUDED'
                        AND
                        substr(fct_claim_adjustment_r.v_adjustment_desc_r, 1, 5) = 'TRNFR' THEN
                                       (
                                        CASE
                                        WHEN substr(fct_claim_adjustment_r.v_adjustment_desc_r, 8, 2) = 'DR' THEN
                                                      fct_claim_adjustment_r.n_adj_trans_amount_r * - 1
                                        ELSE
                                                      fct_claim_adjustment_r.n_adj_trans_amount_r
                                        END
                                       )
         ELSE
                        0
         END
        )	N_PAID_CLAIM_BENEFITS_R
		--06-May-2022 Erica changes ends
		,FCT_CLAIM_ADJUSTMENT_R.N_CLAIM_SK_R                           --08-Apr-2022 Erica changes
		,FCT_CLAIM_ADJUSTMENT_R.N_CLAIM_COVERAGE_SK_R                  --08-Apr-2022 Erica changes
		,FCT_CLAIM_ADJUSTMENT_R.N_CLAIM_COVERAGE_GROUP_SK_R            --08-Apr-2022 Erica changes
		,FCT_CLAIM_ADJUSTMENT_R.N_BATCH_ID_R--26-Apr-2022 Full Load Changes
		,FCT_CLAIM_ADJUSTMENT_R.FIC_MIS_DATE_R--26-Apr-2022 Full Load Changes
		--27-SEP-CHANGES STARTS
		,a.V_INDIVIDUAL_FIRST_NAME_R  V_PAYEE_FIRST_NAME_R
        ,a.V_INDIVIDUAL_MIDDLE_NAME_R V_PAYEE_MIDDLE_NAME_R
        ,a.V_INDIVIDUAL_LAST_NAME_R   V_PAYEE_LAST_NAME_R
		,(case  when a.V_PAYEE_TYPE_R = 'Agent' then ' UNK '
        when a.V_PAYEE_TYPE_R = 'Beneficiary' then 'UNK'
        when a.V_PAYEE_TYPE_R = 'Customer' then 'GRP'
        when a.V_PAYEE_TYPE_R = 'Insured' then 'IND'
        when a.V_PAYEE_TYPE_R = 'Vendor' then 'PRV' else a.V_PAYEE_TYPE_R end ) V_PAYEE_TYPE_R
		--27-SEP-2023 changes ends
		,a.N_INSRD_PARTY_SK_R as N_PARTY_SK_R 						--12-MAR-2024 Changes
        --29-May-2024 changes starts
        ,FCT_CLAIM_ADJUSTMENT_R.V_AMOUNT_TYPE_SUB_NAME_R,
        FCT_CLAIM_ADJUSTMENT_R.V_AMOUNT_TYPE_CATEGORY_R,
        FCT_CLAIM_ADJUSTMENT_R.V_AMOUNT_TYPE_CATEGORY_DESC_R,
        FCT_CLAIM_ADJUSTMENT_R.V_AMOUNT_TYPE_SUB_CATEGORY_R,
        FCT_CLAIM_ADJUSTMENT_R.V_AMT_TYPE_SUB_CATEGORY_DESC_R,
        FCT_CLAIM_ADJUSTMENT_R.V_AMOUNT_TYPE_CODE_R,
        FCT_CLAIM_ADJUSTMENT_R.V_AMOUNT_TYPE_NAME_R,
        FCT_CLAIM_ADJUSTMENT_R.V_AMOUNT_TYPE_SUB_CODE_R,
		FCT_CLAIM_ADJUSTMENT_R.n_adj_trans_amount_r
        --29-May-2024 changes ends
        FROM ATOMIC.FCT_CLAIM_ADJUSTMENT_R
LEFT JOIN (
    SELECT N_TAXABLE_PERCENT_R,
           N_CLAIM_SK_R,
           N_CLAIM_COVERAGE_SK_R,
           N_CLAIM_COVERAGE_GROUP_SK_R
    FROM (
        SELECT N_TAXABLE_PERCENT_R,
               N_CLAIM_SK_R,
               N_CLAIM_COVERAGE_SK_R,
               N_CLAIM_COVERAGE_GROUP_SK_R,
               ROW_NUMBER() OVER (
                   PARTITION BY N_CLAIM_SK_R, N_CLAIM_COVERAGE_SK_R, N_CLAIM_COVERAGE_GROUP_SK_R
                   ORDER BY n_batch_id_r DESC
               ) AS rn
        FROM ATOMIC.fct_claim_payment_detail_benefit_payment_r
    ) 
    WHERE rn = 1
) FGB
    ON FCT_CLAIM_ADJUSTMENT_R.N_CLAIM_SK_R = FGB.N_CLAIM_SK_R
   AND FCT_CLAIM_ADJUSTMENT_R.N_CLAIM_COVERAGE_SK_R = FGB.N_CLAIM_COVERAGE_SK_R
   AND FCT_CLAIM_ADJUSTMENT_R.N_CLAIM_COVERAGE_GROUP_SK_R = FGB.N_CLAIM_COVERAGE_GROUP_SK_R

LEFT JOIN ATOMIC.DIM_GRP_CLAIM_DIR_R
    ON FCT_CLAIM_ADJUSTMENT_R.N_CLAIM_SK_R = DIM_GRP_CLAIM_DIR_R.N_CLAIM_SK_R
LEFT JOIN ATOMIC.DIM_GRP_CLAIM_COVERAGE_R
    ON FCT_CLAIM_ADJUSTMENT_R.N_CLAIM_COVERAGE_SK_R = DIM_GRP_CLAIM_COVERAGE_R.N_CLAIM_COVERAGE_SK_R
LEFT JOIN ATOMIC.DIM_GRP_CLAIM_COVERAGE_GROUP_R
    ON FCT_CLAIM_ADJUSTMENT_R.N_CLAIM_COVERAGE_GROUP_SK_R = DIM_GRP_CLAIM_COVERAGE_GROUP_R.N_CLAIM_COVERAGE_GROUP_SK_R
LEFT JOIN (
    SELECT V_PAYMNT_DTLS_SRC_SYS_KEY_R,
           N_INSRD_PARTY_SK_R,
           pa.V_INDIVIDUAL_FIRST_NAME_R,
           pa.V_INDIVIDUAL_MIDDLE_NAME_R,
           pa.V_INDIVIDUAL_LAST_NAME_R,
           MAX(C.v_payee_type_r) v_payee_type_r
    FROM (
        SELECT B.N_INSRD_PARTY_SK_R,
               B.V_PAYMNT_DTLS_SRC_SYS_KEY_R,
               d.v_payee_type_r
        FROM (
            SELECT MAX(pd.N_INSRD_PARTY_SK_R) AS N_INSRD_PARTY_SK_R,
                   V_PAYMNT_DTLS_SRC_SYS_KEY_R
            FROM atomic.dim_payment_details pd
            WHERE pd.v_active_status_r = 'Y'
            GROUP BY V_PAYMNT_DTLS_SRC_SYS_KEY_R
        ) B
        JOIN atomic.dim_payment_details d
            ON B.N_INSRD_PARTY_SK_R = d.N_INSRD_PARTY_SK_R
           AND d.v_active_status_r = 'Y'
           AND B.V_PAYMNT_DTLS_SRC_SYS_KEY_R = D.V_PAYMNT_DTLS_SRC_SYS_KEY_R
    ) C
    JOIN atomic.dim_grp_party_r pa
        ON C.N_INSRD_PARTY_SK_R = pa.N_PARTY_SK_R
       AND pa.v_active_status_r = 'Y'
    GROUP BY V_PAYMNT_DTLS_SRC_SYS_KEY_R,
             pa.V_INDIVIDUAL_FIRST_NAME_R,
             pa.V_INDIVIDUAL_MIDDLE_NAME_R,
             pa.V_INDIVIDUAL_LAST_NAME_R,
             N_INSRD_PARTY_SK_R
) a
    ON DIM_GRP_CLAIM_DIR_R.N_SOURCE_SYSTEM_KEY_R = a.V_PAYMNT_DTLS_SRC_SYS_KEY_R
  WHERE 
  FCT_CLAIM_ADJUSTMENT_R.V_AMOUNT_TYPE_SUB_CODE_R NOT LIKE '%-%'
  AND DIM_GRP_CLAIM_DIR_R.V_ACTIVE_STATUS_R = 'Y'
  AND NVL(DIM_GRP_CLAIM_COVERAGE_GROUP_R.V_ACTIVE_STATUS_R,'Y') = 'Y'
  AND NVL(DIM_GRP_CLAIM_COVERAGE_R.V_ACTIVE_STATUS_R,'Y') = 'Y'
  AND (CASE WHEN (FCT_CLAIM_ADJUSTMENT_R.V_AMOUNT_TYPE_SUB_CODE_R LIKE 'Z%'
                  OR FCT_CLAIM_ADJUSTMENT_R.V_AMOUNT_TYPE_SUB_CODE_R LIKE 'W%')
            THEN UPPER(FCT_CLAIM_ADJUSTMENT_R.V_RECOVERY_TYPE_R)
            ELSE 'MANUAL' END) LIKE '%MANUAL%')
;
      EXCEPTION
      WHEN OTHERS THEN
      LC_SQLCODE:=SQLCODE;
      LC_SQLERRM:=SUBSTR(SQLERRM,1,4000);
      OUT_LOAD_STATUS:='2)Adjustment Error :-'||LC_SQLCODE||'-'||LC_SQLERRM;
	  ROLLBACK TO SAVEPOINT SP2;
	  RAISE_APPLICATION_ERROR(-20001,'2)Adjustment Error :-'||LC_SQLCODE||'-'||LC_SQLERRM);
      END ;
        -- Adjustment Data Load ends
      END IF;

	commit;
	/*SELECT NVL(MAX(N_SEQUENCE_NUMBER_R),0) INTO LN_MAX_SEQ_NUMER_R
	FROM ATOMIC.FCT_CLAIM_PAYMENT_DETAIL_R;*/





		if LC_SOURCE_CONCEPT = 'ALL' OR LC_SOURCE_CONCEPT like 'PACS_EXPENSE' then
  --LC_SOURCE_SYSTEM_NAME_R :='PACS';
  --LC_SOURCE_CONCEPT = 'ALL' OR
	-- Expense Data Load Starts
	--08-Jun-2022 changes starts
	EXECUTE IMMEDIATE 'ALTER TABLE FCT_CLAIM_PAYMENT_DETAIL_EXPENSE_R TRUNCATE PARTITION '||'PART_PACS UPDATE INDEXES';
	PKG_GRP_FULLLOAD_FCT_CLAIM_PAYMENT_DETAIL_R.prc_rebuild_indexes('FCT_CLAIM_PAYMENT_DETAIL_EXPENSE_R');--21-Mar-2024 changes
  --EXECUTE IMMEDIATE 'DELETE FROM ATOMIC.FCT_CLAIM_PAYMENT_DETAIL_EXPENSE_R WHERE V_SOURCE_SYSTEM_NAME_R='||'''PACS''';
  --EXECUTE IMMEDIATE 'TRUNCATE TABLE ATOMIC.FCT_CLAIM_PAYMENT_DETAIL_ADJUSTMENT_R PURGE SNAPSHOT LOG';
	--ATOMIC.PROC_TRUNCATE_PARTITION('FCT_CLAIM_PAYMENT_DETAIL_R','EXPENSE',LN_N_BATCH_ID_R);
	--COMMIT;
	--BEGIN PRC_FCT_CLAIM_PMNT_DET_GAT_TBL_STATS; END;--Gather table and index stats
	--08-Jun-2022 changes ends
	SAVEPOINT SP3;
  	--EXECUTE IMMEDIATE 'Data has been truncated';
		BEGIN
		INSERT  /*+APPEND_VALUES*/  INTO ATOMIC.FCT_CLAIM_PAYMENT_DETAIL_EXPENSE_R
			(V_CLAIM_NUMBER_R
			 ,V_COVERAGE_CODE_R
			 ,V_COV_GROUP_ID_R
			 ,V_CHECK_NUMBER_R
			 ,V_PAY_METHOD_R
			 ,V_BENEFIT_CODE_R
			 ,V_BENEFIT_DESCRIPTION_R
			 ,V_BENEFIT_GROUP_R
			 ,N_GROSS_WAGE_BASE_R
			 ,N_TAXABLE_PERCENT_R
			 ,V_PAYMENT_STATUS_R
			 ,N_PAID_AMOUNT_R
			 ,V_PAYMENT_TYPE_R
			 ,D_CHECK_DATE_R
			 ,V_CHECK_TYPE_R
			 ,D_PAID_DATE_R
			 ,N_GROSS_AMOUNT_R
			 ,D_SERVICE_PERIOD_FROM_R
			 ,D_SERVICE_PERIOD_TO_R
			 ,V_RECORD_TYPE_R
			 ,N_WORKSHEET_OBJECT_NUM_R
			 ,N_SOURCE_SYSTEM_KEY_R
			 ,N_SOURCE_VERSION_SEQ_NUMBER_R
			 ,N_SEQ_R
			 ,N_GROUP_SEQ_R
			 ,N_PARENT_OBJECTNUM_R
			 ,T_CREATION_DATE_R
			 ,T_EVENT_TIMESTAMP_R
			 ,T_LAST_MODIFIED_DATE_R
			 ,V_CREATED_BY_R
			 ,V_LAST_MODIFIED_BY_R
			 ,FIC_MIS_DATE_R
			 ,N_BATCH_ID_R
			 ,N_LOAD_RUN_ID_R
			 ,N_SEQUENCE_NUMBER_R
			 ,V_BENEFIT_CATEGORY_R
			,N_CLAIM_SK_R                           --08-Apr-2022 Erica changes
			,N_CLAIM_COVERAGE_SK_R                  --08-Apr-2022 Erica changes
			,N_CLAIM_COVERAGE_GROUP_SK_R            --08-Apr-2022 Erica changes
			--27-SEP-2023 changes starts
			,v_payee_first_name_r
			,v_payee_middle_name_r
			,v_payee_last_name_r
			,V_PAYEE_TYPE_R
			---27-SEP-2023 changes ends
			,N_PARTY_SK_R							--12-MAR-2024 Changes
			,V_SOURCE_SYSTEM_NAME_R
			--29-May-2024 changes starts
			,V_AMOUNT_TYPE_SUB_NAME_R,
			V_AMOUNT_TYPE_CATEGORY_R,
			V_AMOUNT_TYPE_CATEGORY_DESC_R,
			V_AMOUNT_TYPE_SUB_CATEGORY_R,
			V_AMT_TYPE_SUB_CATEGORY_DESC_R,
			V_AMOUNT_TYPE_CODE_R,
			V_AMOUNT_TYPE_NAME_R,
			V_AMOUNT_TYPE_SUB_CODE_R
			--29-May-2024 changes ends
			)
			SELECT
			V_CLAIM_NUMBER_R
			,V_COVERAGE_CODE_R
			,V_COV_GROUP_ID_R
			,V_CHECK_NUMBER_R
			,V_PAY_METHOD_R
			,V_BENEFIT_CODE_R
			,V_BENEFIT_DESCRIPTION_R
			,V_BENEFIT_GROUP_R
			,N_GROSS_WAGE_BASE_R
			,N_TAXABLE_PERCENT_R
			,V_PAYMENT_STATUS_R
			,N_PAID_AMOUNT_R
			,V_PAYMENT_TYPE_R
			,D_CHECK_DATE_R
			,V_CHECK_TYPE_R
			,D_PAID_DATE_R
			,N_GROSS_AMOUNT_R
			,D_SERVICE_PERIOD_FROM_R
			,D_SERVICE_PERIOD_TO_R
			,V_RECORD_TYPE_R
			,N_WORKSHEET_OBJECT_NUM_R
			,N_SOURCE_SYSTEM_KEY_R
			,N_SOURCE_VERSION_SEQ_NUMBER_R
			,N_SEQ_R
			,N_GROUP_SEQ_R
			,N_PARENT_OBJECTNUM_R
			,LT_systimestamp                        T_CREATION_DATE_R
			,LT_systimestamp                        T_EVENT_TIMESTAMP_R
			,LT_systimestamp                        T_LAST_MODIFIED_DATE_R
			,'ODI'                                  V_CREATED_BY_R
			,'ODI'                                  V_LAST_MODIFIED_BY_R
			--,TRUNC(SYSDATE)                         FIC_MIS_DATE_R--26-Apr-2022 Full Load Changes
			--,LN_N_BATCH_ID_R                     	N_BATCH_ID_R--26-Apr-2022 Full Load Changes
			,FIC_MIS_DATE_R                     --26-Apr-2022 Full Load Changes
			,N_BATCH_ID_R                     	N_BATCH_ID_R--26-Apr-2022 Full Load Changes
			,LN_N_LOAD_RUN_ID_R                     N_LOAD_RUN_ID_R
			,(NVL(LN_MAX_SEQ_NUMER_R,0)+ROWNUM)     N_SEQUENCE_NUMBER_R
			,V_BENEFIT_CATEGORY_R
			,N_CLAIM_SK_R                           --08-Apr-2022 Erica changes
			,N_CLAIM_COVERAGE_SK_R                  --08-Apr-2022 Erica changes
			,N_CLAIM_COVERAGE_GROUP_SK_R            --08-Apr-2022 Erica changes
			--27-SEP-2023 changes starts
			,v_payee_first_name_r
			,v_payee_middle_name_r
			,v_payee_last_name_r
			,V_PAYEE_TYPE_R
			--27-SEP-2023 changes ends
			,N_PARTY_SK_R							--12-MAR-2024 Changes
			,V_SOURCE_SYSTEM_NAME_R
			--29-May-2024 changes starts
			,V_AMOUNT_TYPE_SUB_NAME_R,
			V_AMOUNT_TYPE_CATEGORY_R,
			V_AMOUNT_TYPE_CATEGORY_DESC_R,
			V_AMOUNT_TYPE_SUB_CATEGORY_R,
			V_AMT_TYPE_SUB_CATEGORY_DESC_R,
			V_AMOUNT_TYPE_CODE_R,
			V_AMOUNT_TYPE_NAME_R,
			V_AMOUNT_TYPE_SUB_CODE_R
			--29-May-2024 changes ends
			FROM
			(SELECT /*+enable_parallel_dml parallel(8)*/
				DIM_GRP_CLAIM_DIR_R.V_CLAIM_NUMBER_R                                           V_CLAIM_NUMBER_R
				--05-Oct-2021 Erica Expense query changes starts
				/*,DIM_GRP_CLAIM_COVERAGE_R.V_COVERAGE_CODE_R                                    V_COVERAGE_CODE_R
				,DIM_GRP_CLAIM_COVERAGE_GROUP_R.V_COV_GRP_CODE_R                               V_COV_GROUP_ID_R*/
				,NVL(DIM_GRP_CLAIM_COVERAGE_GROUP_R.V_CLAIM_COVERAGE_CODE_R,DIM_GRP_CLAIM_COVERAGE_R.V_CLAIM_COVERAGE_CODE_R)          V_COVERAGE_CODE_R
				,DIM_GRP_CLAIM_COVERAGE_GROUP_R.N_COV_GRP_ID_R                               V_COV_GROUP_ID_R
				--05-Oct-2021 Erica Expense query changes ends
				,FCT_CLAIM_EXPENSE_PAYMENT_R.V_CHEQUE_NUMBER_R                                 V_CHECK_NUMBER_R
				,FCT_CLAIM_EXPENSE_PAYMENT_R.V_PAY_METHOD_R									   V_PAY_METHOD_R -- 13-Aug-2025  Rose Adding mapping as part of Bug 442478 
				,FCT_CLAIM_EXPENSE_PAYMENT_R.V_AMOUNT_TYPE_SUB_CODE_R                          V_BENEFIT_CODE_R
				,FCT_CLAIM_EXPENSE_PAYMENT_R.V_AMOUNT_TYPE_NAME_R                              V_BENEFIT_DESCRIPTION_R
				,FCT_CLAIM_EXPENSE_PAYMENT_R.V_AMOUNT_TYPE_CODE_R	                           V_BENEFIT_GROUP_R
				,NULL                                                                          N_GROSS_WAGE_BASE_R
				,NULL                                                                          N_TAXABLE_PERCENT_R
				,DECODE(FCT_CLAIM_EXPENSE_PAYMENT_R.V_TRANS_STATUS_R,'REVERSAL','VOID','PAID') V_PAYMENT_STATUS_R
				,FCT_CLAIM_EXPENSE_PAYMENT_R.N_TRANS_AMOUNT_R                                  N_PAID_AMOUNT_R
				,'PAY'                                                                         V_PAYMENT_TYPE_R
				,FCT_CLAIM_EXPENSE_PAYMENT_R.D_TRANS_DATE_R                                    D_CHECK_DATE_R
				,'OE'                                                                          V_CHECK_TYPE_R
				,FCT_CLAIM_EXPENSE_PAYMENT_R.D_TRANS_DATE_R                                    D_PAID_DATE_R
				,NULL                                                                          N_GROSS_AMOUNT_R
				,NULL                                                                          D_SERVICE_PERIOD_FROM_R
				,NULL                                                                          D_SERVICE_PERIOD_TO_R
				,'Expense'                                                                     V_RECORD_TYPE_R
				,NULL                                                                          N_WORKSHEET_OBJECT_NUM_R
				,FCT_CLAIM_EXPENSE_PAYMENT_R.N_CLAIMEXP_SOURCE_SYSTEM_KEY_R	                   N_SOURCE_SYSTEM_KEY_R
				,FCT_CLAIM_EXPENSE_PAYMENT_R.N_SOURCE_VERSION_SEQ_NUMBER_R	                   N_SOURCE_VERSION_SEQ_NUMBER_R
				,NULL                                                                          N_SEQ_R
				,NULL                                                                          N_GROUP_SEQ_R
				,NULL                                                                          N_PARENT_OBJECTNUM_R
				,FCT_CLAIM_EXPENSE_PAYMENT_R.V_AMOUNT_TYPE_CATEGORY_DESC_R                     V_BENEFIT_CATEGORY_R
				,FCT_CLAIM_EXPENSE_PAYMENT_R.N_CLAIM_SK_R                           --08-Apr-2022 Erica changes
				,FCT_CLAIM_EXPENSE_PAYMENT_R.N_CLAIM_COVERAGE_SK_R                  --08-Apr-2022 Erica changes
				,FCT_CLAIM_EXPENSE_PAYMENT_R.N_CLAIM_COVERAGE_GROUP_SK_R            --08-Apr-2022 Erica changes
				,FCT_CLAIM_EXPENSE_PAYMENT_R.N_BATCH_ID_R                           --26-Apr-2022 Full Load Changes
				,FCT_CLAIM_EXPENSE_PAYMENT_R.FIC_MIS_DATE_R                           --26-Apr-2022 Full Load Changes
				--27-SEP-2023 changes starts
				,dim_grp_party_r.V_INDIVIDUAL_FIRST_NAME_R v_payee_first_name_r
				,dim_grp_party_r.V_INDIVIDUAL_middle_NAME_R v_payee_middle_name_r
				,dim_grp_party_r.V_INDIVIDUAL_LAST_NAME_R v_payee_last_name_r
				,(CASE WHEN PD3.V_PARTY_TYPE_R='VENDOR' THEN 'PRV'
				 ELSE NULL END)			V_PAYEE_TYPE_R
				 --27-SEP-2023 changes ends
				,dim_grp_party_r.N_PARTY_SK_R N_PARTY_SK_R --12-MAR-2024 Changes
				,FCT_CLAIM_EXPENSE_PAYMENT_R.V_SOURCE_SYSTEM_NAME_R V_SOURCE_SYSTEM_NAME_R
				--29-May-2024 changes starts
				,FCT_CLAIM_EXPENSE_PAYMENT_R.V_AMOUNT_TYPE_SUB_NAME_R,
				FCT_CLAIM_EXPENSE_PAYMENT_R.V_AMOUNT_TYPE_CATEGORY_R,
				FCT_CLAIM_EXPENSE_PAYMENT_R.V_AMOUNT_TYPE_CATEGORY_DESC_R,
				FCT_CLAIM_EXPENSE_PAYMENT_R.V_AMOUNT_TYPE_SUB_CATEGORY_R,
				FCT_CLAIM_EXPENSE_PAYMENT_R.V_AMT_TYPE_SUB_CATEGORY_DESC_R,
				FCT_CLAIM_EXPENSE_PAYMENT_R.V_AMOUNT_TYPE_CODE_R,
				FCT_CLAIM_EXPENSE_PAYMENT_R.V_AMOUNT_TYPE_NAME_R,
				FCT_CLAIM_EXPENSE_PAYMENT_R.V_AMOUNT_TYPE_SUB_CODE_R
				--29-May-2024 changes ends
				FROM (SELECT * FROM ATOMIC.FCT_CLAIM_EXPENSE_PAYMENT_R WHERE V_SOURCE_SYSTEM_NAME_R = 'PACS')FCT_CLAIM_EXPENSE_PAYMENT_R
				,ATOMIC.DIM_GRP_CLAIM_DIR_R
				,ATOMIC.DIM_GRP_CLAIM_COVERAGE_R
				,ATOMIC.DIM_GRP_CLAIM_COVERAGE_GROUP_R
				----27-SEP-2023 CHANGES STARTS
				,(SELECT * FROM dim_grp_party_dir_r WHERE V_ACTIVE_STATUS_R = 'Y' AND V_PARTY_TYPE_R='PAYEE' AND V_SOURCE_SYSTEM_NAME_R='PACS' )PD1
				,(SELECT * FROM dim_grp_party_dir_r WHERE V_ACTIVE_STATUS_R = 'Y' AND V_PARTY_TYPE_R='INSURED' AND V_SOURCE_SYSTEM_NAME_R='PACS')PD2
				,(SELECT * FROM dim_grp_party_dir_r WHERE V_ACTIVE_STATUS_R = 'Y' AND V_PARTY_TYPE_R='VENDOR' AND V_SOURCE_SYSTEM_NAME_R='PACS')PD3
				,(SELECT * FROM dim_grp_party_dir_r WHERE V_ACTIVE_STATUS_R = 'Y' AND V_PARTY_TYPE_R='PERSON' AND V_SOURCE_SYSTEM_NAME_R='PACS')PD4
				,(SELECT * FROM dim_grp_party_dir_r WHERE V_ACTIVE_STATUS_R = 'Y' AND V_PARTY_TYPE_R='CUSTOMER' AND V_SOURCE_SYSTEM_NAME_R='PACS')PD5
				,(SELECT * FROM dim_grp_party_r WHERE V_ACTIVE_STATUS_R = 'Y')dim_grp_party_r
				----27-SEP-2023 CHANGES ENDS
			WHERE
			   FCT_CLAIM_EXPENSE_PAYMENT_R.N_CLAIM_SK_R = DIM_GRP_CLAIM_DIR_R.N_CLAIM_SK_R
			   --08-Apr-2022 Erica changes starts
			   /*AND FCT_CLAIM_EXPENSE_PAYMENT_R.N_CLAIM_COVERAGE_SK_R = DIM_GRP_CLAIM_COVERAGE_R.N_CLAIM_COVERAGE_SK_R
			   AND FCT_CLAIM_EXPENSE_PAYMENT_R.N_CLAIM_COVERAGE_GROUP_SK_R = DIM_GRP_CLAIM_COVERAGE_GROUP_R.N_CLAIM_COVERAGE_GROUP_SK_R(+)
			   */
			   AND FCT_CLAIM_EXPENSE_PAYMENT_R.N_CLAIM_COVERAGE_SK_R = DIM_GRP_CLAIM_COVERAGE_R.N_CLAIM_COVERAGE_SK_R(+)
			   AND FCT_CLAIM_EXPENSE_PAYMENT_R.N_CLAIM_COVERAGE_GROUP_SK_R = DIM_GRP_CLAIM_COVERAGE_GROUP_R.N_CLAIM_COVERAGE_GROUP_SK_R(+)
			   AND DIM_GRP_CLAIM_DIR_R.V_ACTIVE_STATUS_R = 'Y'
			   AND nvl(DIM_GRP_CLAIM_COVERAGE_GROUP_R.V_ACTIVE_STATUS_R,'Y') = 'Y'
			   AND nvl(DIM_GRP_CLAIM_COVERAGE_R.V_ACTIVE_STATUS_R, 'Y') = 'Y'
			   --08-Apr-2022 Erica changes ends
			   --27-SEP-2023 changes starts
			   /*Left outer Join dim_grp_party_dir_r on
			   Claimexpense.link_bobjectnum =
			   Claimexpense.link_busobjsequence
			   Filter active status = Y
			   Join dim_grp_party_r
			   On dim_grp_party_dir_r.n_party_sk_r = dim_grp_party_r.n_party_sk_r
			   Filter active status = Y*/
			   AND FCT_CLAIM_EXPENSE_PAYMENT_R.V_LINK_BOBJECTNUM_R=PD3.N_SOURCE_SYSTEM_KEY_R(+)
			   --and FCT_CLAIM_EXPENSE_PAYMENT_R.v_link_busobjsequence_r =PD3.N_SOURCE_VERSION_NUMBER_R(+)---commented as per erica's suggestion
			   AND FCT_CLAIM_EXPENSE_PAYMENT_R.V_LINK_BOBJECTNUM_R=PD1.N_SOURCE_SYSTEM_KEY_R(+)
			   --and FCT_CLAIM_EXPENSE_PAYMENT_R.v_link_busobjsequence_r =PD1.N_SOURCE_VERSION_NUMBER_R(+)---commented as per erica's suggestion
			   AND FCT_CLAIM_EXPENSE_PAYMENT_R.V_LINK_BOBJECTNUM_R=PD2.N_SOURCE_SYSTEM_KEY_R(+)
			   --and FCT_CLAIM_EXPENSE_PAYMENT_R.v_link_busobjsequence_r =PD2.N_SOURCE_VERSION_NUMBER_R(+)---commented as per erica's suggestion 
			   AND FCT_CLAIM_EXPENSE_PAYMENT_R.V_LINK_BOBJECTNUM_R=PD4.N_SOURCE_SYSTEM_KEY_R(+)
			   --and FCT_CLAIM_EXPENSE_PAYMENT_R.v_link_busobjsequence_r =PD4.N_SOURCE_VERSION_NUMBER_R(+)---commented as per erica's suggestion
			   AND FCT_CLAIM_EXPENSE_PAYMENT_R.V_LINK_BOBJECTNUM_R=PD5.N_SOURCE_SYSTEM_KEY_R(+)
			   --and FCT_CLAIM_EXPENSE_PAYMENT_R.v_link_busobjsequence_r =PD5.N_SOURCE_VERSION_NUMBER_R(+)---commented as per erica's suggestion
			   and nvl(PD3.N_PARTY_SK_R, nvl(PD1.N_PARTY_SK_R, nvl(PD2.N_PARTY_SK_R,  nvl(PD4.N_PARTY_SK_R, nvl(PD5.N_PARTY_SK_R, -1)))))  = dim_grp_party_r.n_party_sk_r(+)
			   --AND dim_grp_party_dir_r.V_ACTIVE_STATUS_R = 'Y'----nvl
			   --AND dim_grp_party_dir_r.V_PARTY_TYPE_R='PAYEE'
			   --AND dim_grp_party_r.V_ACTIVE_STATUS_R = 'Y'----nvl
			   --27-SEP-2023 changes ends
			   --AND FCT_CLAIM_EXPENSE_PAYMENT_R.N_BATCH_ID_R = LN_N_BATCH_ID_R--26-Apr-2022 Full Load Changes
		   --AND UPPER(TRIM(FCT_CLAIM_EXPENSE_PAYMENT_R.V_TRANS_STATUS_R)) IN ('RELEASED','REVERSAL','REVERSED/CANCELLED')--12-May-2022 Erica changes
		   and UPPER(TRIM(FCT_CLAIM_EXPENSE_PAYMENT_R.V_TRANS_STATUS_R)) in ('RELEASED','REVERSAL','REVERSED/CANCELLED', 'REVERSED/RE-ISSUED') -- 24-Jun-2022 Erica Changes
		   --AND FCT_CLAIM_EXPENSE_PAYMENT_R.V_SOURCE_SYSTEM_NAME_R = 'PACS'
			);
			--30-Aug-2024 changes starts
			COMMIT;
			INSERT /*+APPEND_VALUES*/ INTO fct_claim_payment_detail_expense_r_chkdt_gtt
            SELECT MIN(fcpder.d_check_date_r) min_d_check_date_r
            	   --fcpder.v_claim_number_r
            	   ,fcpder.n_claim_sk_r--,fcpder.n_paid_amount_r
                   ,fcpder.n_source_system_key_r
            	   ,fcpder.v_check_number_r
              FROM fct_claim_payment_detail_expense_r fcpder
             WHERE UPPER(fcpder.v_payment_status_r) ='PAID'
               AND EXISTS(SELECT 1 
                            FROM fct_claim_payment_detail_expense_r fcpder1
                           WHERE fcpder1.n_claim_sk_r                 = fcpder.n_claim_sk_r
            				 AND fcpder1.n_source_system_key_r        = fcpder.n_source_system_key_r
            				 AND fcpder1.v_check_number_r             = fcpder.v_check_number_r
            				 AND UPPER(fcpder1.v_payment_status_r)    ='VOID'
            				 AND UPPER(fcpder1.v_source_system_name_r)='PACS'
            				 AND UPPER(fcpder.v_source_system_name_r )='PACS'
                         )	
            GROUP BY --fcpder.v_claim_number_r,
                    fcpder.n_claim_sk_r--,fcpder.n_paid_amount_r
                   ,fcpder.n_source_system_key_r
            	   ,fcpder.v_check_number_r
            	;
            COMMIT; 

			-- 28-auG-2024 CHANGES STARTS
			-- Update d_check_date_r
			OPEN cur_upd_chkdt_col;
			LOOP
			  lt_var_upd_tbl_chkdt_typ.DELETE;
			  FETCH cur_upd_chkdt_col BULK COLLECT INTO lt_var_upd_tbl_chkdt_typ LIMIT 10000;
			  FORALL X IN lt_var_upd_tbl_chkdt_typ.FIRST .. lt_var_upd_tbl_chkdt_typ.LAST
			  UPDATE fct_claim_payment_detail_expense_r
				--SET d_check_date_r  = lt_var_upd_tbl_chkdt_typ(X).min_d_check_date_r--30-Aug-2024 changes
				SET d_check_date_r  = lt_var_upd_tbl_chkdt_typ(X).d_min_check_date_r  --30-Aug-2024 changes
					,t_last_modified_date_r=sysdate
					,v_last_modified_by_r  ='PKG_GRP_FULLLOAD_FCT_CLAIM_PAYMENT_DETAIL_R_PACS_EXPENSE_UPD'
			  WHERE n_claim_sk_r                  = lt_var_upd_tbl_chkdt_typ(X).n_claim_sk_r
				AND n_source_system_key_r         = lt_var_upd_tbl_chkdt_typ(X).n_source_system_key_r
				AND v_check_number_r              = lt_var_upd_tbl_chkdt_typ(X).v_check_number_r
				AND UPPER(v_payment_status_r)     ='VOID'
				AND UPPER(v_source_system_name_r) ='PACS';
			   COMMIT;
			  EXIT WHEN cur_upd_chkdt_col%NOTFOUND;
			END LOOP;
			CLOSE cur_upd_chkdt_col;
			-- 28-auG-2024 CHANGES ENDS      
            COMMIT;
		  EXCEPTION
		  WHEN OTHERS THEN
		  LC_SQLCODE:=SQLCODE;
		  LC_SQLERRM:=SUBSTR(SQLERRM,1,4000);
		  OUT_LOAD_STATUS:='3)Expense Error :-'||LC_SQLCODE||'-'||LC_SQLERRM;
		  ROLLBACK TO SAVEPOINT SP3;
		  RAISE_APPLICATION_ERROR(-20001,'3)Expense Error :-'||LC_SQLCODE||'-'||LC_SQLERRM);
		  END ;
			-- Expense Data Load ends
		  END IF;

	commit;
  --OUT_LOAD_STATUS:='Data has been loaded';
	/*SELECT NVL(MAX(N_SEQUENCE_NUMBER_R),0) INTO LN_MAX_SEQ_NUMER_R
	FROM ATOMIC.FCT_CLAIM_PAYMENT_DETAIL_R;*/

   IF LC_SOURCE_CONCEPT = 'ALL' OR LC_SOURCE_CONCEPT LIKE 'CV_EXPENSE' THEN
	-- Expense Data Load Starts
	--08-Jun-2022 changes starts
	EXECUTE IMMEDIATE 'ALTER TABLE FCT_CLAIM_PAYMENT_DETAIL_EXPENSE_R TRUNCATE PARTITION '||'PART_CV UPDATE INDEXES';
	PKG_GRP_FULLLOAD_FCT_CLAIM_PAYMENT_DETAIL_R.prc_rebuild_indexes('FCT_CLAIM_PAYMENT_DETAIL_EXPENSE_R');--21-Mar-2024 changes
	--EXECUTE IMMEDIATE 'DELETE FROM ATOMIC.FCT_CLAIM_PAYMENT_DETAIL_EXPENSE_R WHERE V_SOURCE_SYSTEM_NAME_R="CV"';
	--EXECUTE IMMEDIATE 'TRUNCATE TABLE ATOMIC.FCT_CLAIM_PAYMENT_DETAIL_EXPENSE_R PURGE SNAPSHOT LOG';
	--ATOMIC.PROC_TRUNCATE_PARTITION('FCT_CLAIM_PAYMENT_DETAIL_R','EXPENSE',LN_N_BATCH_ID_R);
	--COMMIT;
	--BEGIN PRC_FCT_CLAIM_PMNT_DET_GAT_TBL_STATS; END;--Gather table and index stats
	--08-Jun-2022 changes ends
	SAVEPOINT SP6;
	BEGIN

	INSERT /*+APPEND_VALUES*/ INTO ATOMIC.FCT_CLAIM_PAYMENT_DETAIL_EXPENSE_R
	(V_CLAIM_NUMBER_R
	,V_COVERAGE_CODE_R
	,V_COV_GROUP_ID_R
	,V_CHECK_NUMBER_R
	,V_PAY_METHOD_R
	,V_BENEFIT_CODE_R
	,V_BENEFIT_DESCRIPTION_R
	,V_BENEFIT_GROUP_R
	,N_GROSS_WAGE_BASE_R
	,N_TAXABLE_PERCENT_R
	,V_PAYMENT_STATUS_R
	,N_PAID_AMOUNT_R
	,V_PAYMENT_TYPE_R
	,D_CHECK_DATE_R
	,V_CHECK_TYPE_R
	,D_PAID_DATE_R
	,N_GROSS_AMOUNT_R
	,D_SERVICE_PERIOD_FROM_R
	,D_SERVICE_PERIOD_TO_R
	,V_RECORD_TYPE_R
	,N_WORKSHEET_OBJECT_NUM_R
	,N_SOURCE_SYSTEM_KEY_R
	,N_SOURCE_VERSION_SEQ_NUMBER_R
	,N_SEQ_R
	,N_GROUP_SEQ_R
	,N_PARENT_OBJECTNUM_R
	,T_CREATION_DATE_R
	,T_EVENT_TIMESTAMP_R
	,T_LAST_MODIFIED_DATE_R
	,V_CREATED_BY_R
	,V_LAST_MODIFIED_BY_R
	,FIC_MIS_DATE_R                     --26-Apr-2022 Full Load Changes
	,N_BATCH_ID_R--26-Apr-2022 Full Load Changes
	,N_LOAD_RUN_ID_R
	,N_SEQUENCE_NUMBER_R
	,V_BENEFIT_CATEGORY_R
	,N_CLAIM_SK_R                           --08-Apr-2022 Erica changes
	,N_CLAIM_COVERAGE_SK_R                  --08-Apr-2022 Erica changes
	,N_CLAIM_COVERAGE_GROUP_SK_R            --08-Apr-2022 Erica changes
	,v_payee_first_name_r
	,v_payee_middle_name_r
    ,v_payee_last_name_r
    ,V_PAYEE_TYPE_R
	,V_SOURCE_SYSTEM_NAME_R
    --29-May-2024 changes starts
    ,V_AMOUNT_TYPE_SUB_NAME_R
    ,V_AMOUNT_TYPE_CATEGORY_R
    ,V_AMOUNT_TYPE_CATEGORY_DESC_R
    ,V_AMOUNT_TYPE_SUB_CATEGORY_R
    ,V_AMT_TYPE_SUB_CATEGORY_DESC_R
    ,V_AMOUNT_TYPE_CODE_R
    ,V_AMOUNT_TYPE_NAME_R
    ,V_AMOUNT_TYPE_SUB_CODE_R
    --29-May-2024 changes ends
	)
    SELECT
		 V_CLAIM_NUMBER_R
		,V_COVERAGE_CODE_R
		,V_COV_GROUP_ID_R
		,V_CHECK_NUMBER_R
		,V_PAY_METHOD_R
		,V_BENEFIT_CODE_R
		,V_BENEFIT_DESCRIPTION_R
		,V_BENEFIT_GROUP_R
		,N_GROSS_WAGE_BASE_R
		,N_TAXABLE_PERCENT_R
		,V_PAYMENT_STATUS_R
		,N_PAID_AMOUNT_R
		,V_PAYMENT_TYPE_R
		,D_CHECK_DATE_R
		,V_CHECK_TYPE_R
		,D_PAID_DATE_R
		,N_GROSS_AMOUNT_R
		,D_SERVICE_PERIOD_FROM_R
		,D_SERVICE_PERIOD_TO_R
		,V_RECORD_TYPE_R
		,N_WORKSHEET_OBJECT_NUM_R
		,N_SOURCE_SYSTEM_KEY_R
		,N_SOURCE_VERSION_SEQ_NUMBER_R
		,N_SEQ_R
		,N_GROUP_SEQ_R
		,N_PARENT_OBJECTNUM_R
		,T_CREATION_DATE_R
		,T_EVENT_TIMESTAMP_R
		,T_LAST_MODIFIED_DATE_R
		,V_CREATED_BY_R
		,V_LAST_MODIFIED_BY_R
		,FIC_MIS_DATE_R                     --26-Apr-2022 Full Load Changes
		,N_BATCH_ID_R                     	--26-Apr-2022 Full Load Changes
		,N_LOAD_RUN_ID_R
		,ROWNUM  N_SEQUENCE_NUMBER_R
		,V_BENEFIT_CATEGORY_R
		,N_CLAIM_SK_R                           --08-Apr-2022 Erica changes
		,N_CLAIM_COVERAGE_SK_R                  --08-Apr-2022 Erica changes
		,N_CLAIM_COVERAGE_GROUP_SK_R            --08-Apr-2022 Erica changes
		,v_payee_first_name_r
		,v_payee_middle_name_r
		,v_payee_last_name_r
		,V_PAYEE_TYPE_R
		,V_SOURCE_SYSTEM_NAME_R
		--29-May-2024 changes starts
		,V_AMOUNT_TYPE_SUB_NAME_R
		,V_AMOUNT_TYPE_CATEGORY_R
		,V_AMOUNT_TYPE_CATEGORY_DESC_R
		,V_AMOUNT_TYPE_SUB_CATEGORY_R
		,V_AMT_TYPE_SUB_CATEGORY_DESC_R
		,V_AMOUNT_TYPE_CODE_R
		,V_AMOUNT_TYPE_NAME_R
		,V_AMOUNT_TYPE_SUB_CODE_R
		--29-May-2024 changes ends
	FROM 
		(
		SELECT
			 V_CLAIM_NUMBER_R
			,V_COVERAGE_CODE_R
			,V_COV_GROUP_ID_R
			,V_CHECK_NUMBER_R
			,V_PAY_METHOD_R
			,V_BENEFIT_CODE_R
			,V_BENEFIT_DESCRIPTION_R
			,V_BENEFIT_GROUP_R
			,N_GROSS_WAGE_BASE_R
			,N_TAXABLE_PERCENT_R
			,V_PAYMENT_STATUS_R
			,N_PAID_AMOUNT_R
			,V_PAYMENT_TYPE_R
			,D_CHECK_DATE_R
			,V_CHECK_TYPE_R
			,D_PAID_DATE_R
			,N_GROSS_AMOUNT_R
			,D_SERVICE_PERIOD_FROM_R
			,D_SERVICE_PERIOD_TO_R
			,V_RECORD_TYPE_R
			,N_WORKSHEET_OBJECT_NUM_R
			,N_SOURCE_SYSTEM_KEY_R
			,N_SOURCE_VERSION_SEQ_NUMBER_R
			,N_SEQ_R
			,N_GROUP_SEQ_R
			,N_PARENT_OBJECTNUM_R
			,T_CREATION_DATE_R
			,T_EVENT_TIMESTAMP_R
			,T_LAST_MODIFIED_DATE_R
			,V_CREATED_BY_R
			,V_LAST_MODIFIED_BY_R
			,FIC_MIS_DATE_R                
			,N_BATCH_ID_R                  
			,N_LOAD_RUN_ID_R
			,V_BENEFIT_CATEGORY_R
			,N_CLAIM_SK_R                  
			,N_CLAIM_COVERAGE_SK_R         
			,N_CLAIM_COVERAGE_GROUP_SK_R   
			,v_payee_first_name_r
			,v_payee_middle_name_r
			,v_payee_last_name_r
			,V_PAYEE_TYPE_R
			,V_SOURCE_SYSTEM_NAME_R
			,V_AMOUNT_TYPE_SUB_NAME_R
			,V_AMOUNT_TYPE_CATEGORY_R
			,V_AMOUNT_TYPE_CATEGORY_DESC_R
			,V_AMOUNT_TYPE_SUB_CATEGORY_R
			,V_AMT_TYPE_SUB_CATEGORY_DESC_R
			,V_AMOUNT_TYPE_CODE_R
			,V_AMOUNT_TYPE_NAME_R
			,V_AMOUNT_TYPE_SUB_CODE_R
		FROM 
			(
			SELECT
				 V_CLAIM_NUMBER_R
				,V_COVERAGE_CODE_R
				,V_COV_GROUP_ID_R
				,V_CHECK_NUMBER_R
				,V_PAY_METHOD_R
				,V_BENEFIT_CODE_R
				,V_BENEFIT_DESCRIPTION_R
				,V_BENEFIT_GROUP_R
				,N_GROSS_WAGE_BASE_R
				,N_TAXABLE_PERCENT_R
				,V_PAYMENT_STATUS_R
				,N_PAID_AMOUNT_R
				,V_PAYMENT_TYPE_R
				,D_CHECK_DATE_R
				,V_CHECK_TYPE_R
				,D_PAID_DATE_R
				,N_GROSS_AMOUNT_R
				,D_SERVICE_PERIOD_FROM_R
				,D_SERVICE_PERIOD_TO_R
				,V_RECORD_TYPE_R
				,N_WORKSHEET_OBJECT_NUM_R
				,N_SOURCE_SYSTEM_KEY_R
				,N_SOURCE_VERSION_SEQ_NUMBER_R
				,N_SEQ_R
				,N_GROUP_SEQ_R
				,N_PARENT_OBJECTNUM_R
				,T_CREATION_DATE_R
				,T_EVENT_TIMESTAMP_R
				,T_LAST_MODIFIED_DATE_R
				,V_CREATED_BY_R
				,V_LAST_MODIFIED_BY_R
				,FIC_MIS_DATE_R                
				,N_BATCH_ID_R                  
				,N_LOAD_RUN_ID_R
				,V_BENEFIT_CATEGORY_R
				,N_CLAIM_SK_R                  
				,N_CLAIM_COVERAGE_SK_R         
				,N_CLAIM_COVERAGE_GROUP_SK_R   
				,v_payee_first_name_r
				,v_payee_middle_name_r
				,v_payee_last_name_r
				,V_PAYEE_TYPE_R
				,V_SOURCE_SYSTEM_NAME_R
				,V_AMOUNT_TYPE_SUB_NAME_R
				,V_AMOUNT_TYPE_CATEGORY_R
				,V_AMOUNT_TYPE_CATEGORY_DESC_R
				,V_AMOUNT_TYPE_SUB_CATEGORY_R
				,V_AMT_TYPE_SUB_CATEGORY_DESC_R
				,V_AMOUNT_TYPE_CODE_R
				,V_AMOUNT_TYPE_NAME_R
				,V_AMOUNT_TYPE_SUB_CODE_R
				,RANK() OVER (PARTITION BY N_SOURCE_VERSION_SEQ_NUMBER_R,N_CLAIM_SK_R,N_CLAIM_COVERAGE_SK_R,N_SEQ_R,N_CLAIM_COVERAGE_GROUP_SK_R,NVL(V_CHECK_NUMBER_R,-999999),NVL(V_PAYMENT_STATUS_R,-999999) 
							  ORDER BY N_BATCH_ID_R desc, FIC_MIS_DATE_R desc, V_PAYEE_TYPE_R desc, v_payee_first_name_r desc ) RNK
			FROM 
				(
					(SELECT
						 V_CLAIM_NUMBER_R
						,V_COVERAGE_CODE_R
						,V_COV_GROUP_ID_R
						,V_CHECK_NUMBER_R
						,V_PAY_METHOD_R
						,V_BENEFIT_CODE_R
						,V_BENEFIT_DESCRIPTION_R
						,V_BENEFIT_GROUP_R
						,N_GROSS_WAGE_BASE_R
						,N_TAXABLE_PERCENT_R
						,V_PAYMENT_STATUS_R
						,N_PAID_AMOUNT_R
						,V_PAYMENT_TYPE_R
						,D_CHECK_DATE_R
						,V_CHECK_TYPE_R
						,D_PAID_DATE_R
						,N_GROSS_AMOUNT_R
						,D_SERVICE_PERIOD_FROM_R
						,D_SERVICE_PERIOD_TO_R
						,V_RECORD_TYPE_R
						,N_WORKSHEET_OBJECT_NUM_R
						,N_SOURCE_SYSTEM_KEY_R
						,N_SOURCE_VERSION_SEQ_NUMBER_R
						,N_SEQ_R
						,N_GROUP_SEQ_R
						,N_PARENT_OBJECTNUM_R
						,systimestamp                        T_CREATION_DATE_R
						,systimestamp                        T_EVENT_TIMESTAMP_R
						,systimestamp                        T_LAST_MODIFIED_DATE_R
						,'ODI'                                  V_CREATED_BY_R
						,'ODI'                                  V_LAST_MODIFIED_BY_R
						--,TRUNC(SYSDATE)                         FIC_MIS_DATE_R--26-Apr-2022 Full Load Changes
						--,LN_N_BATCH_ID_R                     	N_BATCH_ID_R--26-Apr-2022 Full Load Changes
						,FIC_MIS_DATE_R                     --26-Apr-2022 Full Load Changes
						,N_BATCH_ID_R                     	N_BATCH_ID_R--26-Apr-2022 Full Load Changes
						,1                     N_LOAD_RUN_ID_R
						--,SEQ_FCT_CLAIM_PAYMENT_DETAIL_EXPENSE_R.NEXTVAL N_SEQUENCE_NUMBER_R
						,V_BENEFIT_CATEGORY_R
						,N_CLAIM_SK_R                           --08-Apr-2022 Erica changes
						,N_CLAIM_COVERAGE_SK_R                  --08-Apr-2022 Erica changes
						,N_CLAIM_COVERAGE_GROUP_SK_R            --08-Apr-2022 Erica changes
						--27-SEP-2023 changes starts
						,v_payee_first_name_r
						,v_payee_middle_name_r
						,v_payee_last_name_r
						,V_PAYEE_TYPE_R
						,V_SOURCE_SYSTEM_NAME_R
						--27-SEP-2023 changes ends
                        --29-May-2024 changes starts
                        ,V_AMOUNT_TYPE_SUB_NAME_R
                        ,V_AMOUNT_TYPE_CATEGORY_R
                        ,V_AMOUNT_TYPE_CATEGORY_DESC_R
                        ,V_AMOUNT_TYPE_SUB_CATEGORY_R
                        ,V_AMT_TYPE_SUB_CATEGORY_DESC_R
                        ,V_AMOUNT_TYPE_CODE_R
                        ,V_AMOUNT_TYPE_NAME_R
                        ,V_AMOUNT_TYPE_SUB_CODE_R
                        --29-May-2024 changes ends
					FROM
						(SELECT /*+enable_parallel_dml parallel(8)*/
							DIM_GRP_CLAIM_DIR_R.V_CLAIM_NUMBER_R                                           V_CLAIM_NUMBER_R
							--05-Oct-2021 Erica Expense query changes starts
							/*,DIM_GRP_CLAIM_COVERAGE_R.V_COVERAGE_CODE_R                                    V_COVERAGE_CODE_R
							,DIM_GRP_CLAIM_COVERAGE_GROUP_R.V_COV_GRP_CODE_R                               V_COV_GROUP_ID_R*/
							,NVL(DIM_GRP_CLAIM_COVERAGE_GROUP_R.V_CLAIM_COVERAGE_CODE_R,DIM_GRP_CLAIM_COVERAGE_R.V_CLAIM_COVERAGE_CODE_R)          V_COVERAGE_CODE_R
							,DIM_GRP_CLAIM_COVERAGE_GROUP_R.N_COV_GRP_ID_R                               V_COV_GROUP_ID_R
							--05-Oct-2021 Erica Expense query changes ends
							,FCT_CLAIM_EXPENSE_PAYMENT_R.V_CHEQUE_NUMBER_R                                 V_CHECK_NUMBER_R
							,NULL                                                                          V_PAY_METHOD_R
							,FCT_CLAIM_EXPENSE_PAYMENT_R.V_AMOUNT_TYPE_SUB_CODE_R                          V_BENEFIT_CODE_R
							,FCT_CLAIM_EXPENSE_PAYMENT_R.V_AMOUNT_TYPE_NAME_R                              V_BENEFIT_DESCRIPTION_R
							,FCT_CLAIM_EXPENSE_PAYMENT_R.V_AMOUNT_TYPE_CODE_R	                           V_BENEFIT_GROUP_R
							,NULL                                                                          N_GROSS_WAGE_BASE_R
							,NULL                                                                          N_TAXABLE_PERCENT_R
							,DECODE(FCT_CLAIM_EXPENSE_PAYMENT_R.V_TRANS_STATUS_R,'REVERSAL','VOID','PAID') V_PAYMENT_STATUS_R
							,FCT_CLAIM_EXPENSE_PAYMENT_R.N_TRANS_AMOUNT_R                                  N_PAID_AMOUNT_R
							,'PAY'                                                                         V_PAYMENT_TYPE_R
							,FCT_CLAIM_EXPENSE_PAYMENT_R.D_TRANS_DATE_R                                    D_CHECK_DATE_R
							,'OE'                                                                          V_CHECK_TYPE_R
							,FCT_CLAIM_EXPENSE_PAYMENT_R.D_TRANS_DATE_R                                    D_PAID_DATE_R
							,NULL                                                                          N_GROSS_AMOUNT_R
							,NULL                                                                          D_SERVICE_PERIOD_FROM_R
							,NULL                                                                          D_SERVICE_PERIOD_TO_R
							,'Expense'                                                                     V_RECORD_TYPE_R
							,NULL                                                                          N_WORKSHEET_OBJECT_NUM_R
							,FCT_CLAIM_EXPENSE_PAYMENT_R.N_CLAIMEXP_SOURCE_SYSTEM_KEY_R	                   N_SOURCE_SYSTEM_KEY_R
							,FCT_CLAIM_EXPENSE_PAYMENT_R.N_SOURCE_VERSION_SEQ_NUMBER_R	                   N_SOURCE_VERSION_SEQ_NUMBER_R
							,NULL                                                                          N_SEQ_R
							,NULL                                                                          N_GROUP_SEQ_R
							,NULL                                                                          N_PARENT_OBJECTNUM_R
							,FCT_CLAIM_EXPENSE_PAYMENT_R.V_AMOUNT_TYPE_CATEGORY_DESC_R                     V_BENEFIT_CATEGORY_R
							,FCT_CLAIM_EXPENSE_PAYMENT_R.N_CLAIM_SK_R                           --08-Apr-2022 Erica changes
							,FCT_CLAIM_EXPENSE_PAYMENT_R.N_CLAIM_COVERAGE_SK_R                  --08-Apr-2022 Erica changes
							,FCT_CLAIM_EXPENSE_PAYMENT_R.N_CLAIM_COVERAGE_GROUP_SK_R            --08-Apr-2022 Erica changes
							,FCT_CLAIM_EXPENSE_PAYMENT_R.N_BATCH_ID_R                           --26-Apr-2022 Full Load Changes
							,FCT_CLAIM_EXPENSE_PAYMENT_R.FIC_MIS_DATE_R                           --26-Apr-2022 Full Load Changes
							--27-SEP-2023 changes starts
							,dim_grp_party_r.V_INDIVIDUAL_FIRST_NAME_R v_payee_first_name_r
							,dim_grp_party_r.V_INDIVIDUAL_middle_NAME_R v_payee_middle_name_r
							,dim_grp_party_r.V_INDIVIDUAL_LAST_NAME_R v_payee_last_name_r
							,(CASE WHEN PD3.V_PARTY_TYPE_R='VENDOR' THEN 'PRV'
							ELSE NULL END)			V_PAYEE_TYPE_R
							,FCT_CLAIM_EXPENSE_PAYMENT_R.V_SOURCE_SYSTEM_NAME_R V_SOURCE_SYSTEM_NAME_R
							--27-SEP-2023 changes ends
                            --29-May-2024 changes starts
                            ,FCT_CLAIM_EXPENSE_PAYMENT_R.V_AMOUNT_TYPE_SUB_NAME_R,
                            FCT_CLAIM_EXPENSE_PAYMENT_R.V_AMOUNT_TYPE_CATEGORY_R,
                            FCT_CLAIM_EXPENSE_PAYMENT_R.V_AMOUNT_TYPE_CATEGORY_DESC_R,
                            FCT_CLAIM_EXPENSE_PAYMENT_R.V_AMOUNT_TYPE_SUB_CATEGORY_R,
                            FCT_CLAIM_EXPENSE_PAYMENT_R.V_AMT_TYPE_SUB_CATEGORY_DESC_R,
                            FCT_CLAIM_EXPENSE_PAYMENT_R.V_AMOUNT_TYPE_CODE_R,
                            FCT_CLAIM_EXPENSE_PAYMENT_R.V_AMOUNT_TYPE_NAME_R,
                            FCT_CLAIM_EXPENSE_PAYMENT_R.V_AMOUNT_TYPE_SUB_CODE_R
                            --29-May-2024 changes ends
						FROM (SELECT * FROM ATOMIC.FCT_CLAIM_EXPENSE_PAYMENT_R WHERE V_SOURCE_SYSTEM_NAME_R = 'CV') FCT_CLAIM_EXPENSE_PAYMENT_R
							,ATOMIC.DIM_GRP_CLAIM_DIR_R
							,ATOMIC.DIM_GRP_CLAIM_COVERAGE_R
							,ATOMIC.DIM_GRP_CLAIM_COVERAGE_GROUP_R
							----27-SEP-2023 CHANGES STARTS
							,(SELECT * FROM dim_grp_party_dir_r WHERE V_ACTIVE_STATUS_R = 'Y' AND V_PARTY_TYPE_R='PAYEE' AND V_SOURCE_SYSTEM_NAME_R='CV' )PD1
							,(SELECT * FROM dim_grp_party_dir_r WHERE V_ACTIVE_STATUS_R = 'Y' AND V_PARTY_TYPE_R='INSURED' AND V_SOURCE_SYSTEM_NAME_R='CV')PD2
							,(SELECT * FROM dim_grp_party_dir_r WHERE V_ACTIVE_STATUS_R = 'Y' AND V_PARTY_TYPE_R='VENDOR' AND V_SOURCE_SYSTEM_NAME_R='CV')PD3
							,(SELECT * FROM dim_grp_party_dir_r WHERE V_ACTIVE_STATUS_R = 'Y' AND V_PARTY_TYPE_R='PERSON' AND V_SOURCE_SYSTEM_NAME_R='CV')PD4
							,(SELECT * FROM dim_grp_party_dir_r WHERE V_ACTIVE_STATUS_R = 'Y' AND V_PARTY_TYPE_R='CUSTOMER' AND V_SOURCE_SYSTEM_NAME_R='CV')PD5
							,(SELECT * FROM dim_grp_party_r WHERE V_ACTIVE_STATUS_R = 'Y')dim_grp_party_r
							----27-SEP-2023 CHANGES ENDS
							--added by Subhadeep start1
							,(
								select distinct n_claim_sk_r,N_SOURCE_VERSION_SEQ_NUMBER_R,v_cheque_number_r,V_TRANS_STATUS_R,d_trans_date_r 
								from (
									SELECT  n_claim_sk_r,
											NVL(N_SOURCE_VERSION_SEQ_NUMBER_R, - 1) as N_SOURCE_VERSION_SEQ_NUMBER_R,
											NVL(v_cheque_number_r, - 1) as v_cheque_number_r,
											v_current_status_r,
											t_event_timestamp_r,
											d_trans_date_r,
											v_trans_status_r,
											N_BATCH_ID_R,
											row_number() over (partition by n_claim_sk_r,NVL(N_SOURCE_VERSION_SEQ_NUMBER_R, - 1),NVL(v_cheque_number_r, - 1) order by t_event_timestamp_r desc, N_BATCH_ID_R desc) rnk
									FROM ATOMIC.FCT_CLAIM_EXPENSE_PAYMENT_R
									WHERE v_source_system_name_r = 'CV' AND UPPER(V_TRANS_STATUS_R) IN ('RELEASED','CLEARED') AND v_cheque_number_r IS NOT NULL
									) x where rnk = 1
							 ) EP
							--added by Subhadeep end1
						WHERE
						FCT_CLAIM_EXPENSE_PAYMENT_R.N_CLAIM_SK_R = DIM_GRP_CLAIM_DIR_R.N_CLAIM_SK_R
						--08-Apr-2022 Erica changes starts
						/*AND FCT_CLAIM_EXPENSE_PAYMENT_R.N_CLAIM_COVERAGE_SK_R = DIM_GRP_CLAIM_COVERAGE_R.N_CLAIM_COVERAGE_SK_R
						AND FCT_CLAIM_EXPENSE_PAYMENT_R.N_CLAIM_COVERAGE_GROUP_SK_R = DIM_GRP_CLAIM_COVERAGE_GROUP_R.N_CLAIM_COVERAGE_GROUP_SK_R(+)
						*/
						AND FCT_CLAIM_EXPENSE_PAYMENT_R.N_CLAIM_COVERAGE_SK_R = DIM_GRP_CLAIM_COVERAGE_R.N_CLAIM_COVERAGE_SK_R(+)
						AND FCT_CLAIM_EXPENSE_PAYMENT_R.N_CLAIM_COVERAGE_GROUP_SK_R = DIM_GRP_CLAIM_COVERAGE_GROUP_R.N_CLAIM_COVERAGE_GROUP_SK_R(+)
						AND DIM_GRP_CLAIM_DIR_R.V_ACTIVE_STATUS_R = 'Y'
						AND nvl(DIM_GRP_CLAIM_COVERAGE_GROUP_R.V_ACTIVE_STATUS_R,'Y') = 'Y'
						AND nvl(DIM_GRP_CLAIM_COVERAGE_R.V_ACTIVE_STATUS_R, 'Y') = 'Y'
						--08-Apr-2022 Erica changes ends
						--27-SEP-2023 changes starts
						/*Left outer Join dim_grp_party_dir_r on
						Claimexpense.link_bobjectnum =
						Claimexpense.link_busobjsequence
						Filter active status = Y
						Join dim_grp_party_r
						On dim_grp_party_dir_r.n_party_sk_r = dim_grp_party_r.n_party_sk_r
						Filter active status = Y*/
						AND FCT_CLAIM_EXPENSE_PAYMENT_R.V_LINK_BOBJECTNUM_R=PD1.N_SOURCE_SYSTEM_KEY_R(+)
						--and FCT_CLAIM_EXPENSE_PAYMENT_R.v_link_busobjsequence_r =PD1.N_SOURCE_VERSION_NUMBER_R(+)---commented as per erica's suggestion
						AND FCT_CLAIM_EXPENSE_PAYMENT_R.V_LINK_BOBJECTNUM_R=PD2.N_SOURCE_SYSTEM_KEY_R(+)
						--and FCT_CLAIM_EXPENSE_PAYMENT_R.v_link_busobjsequence_r =PD2.N_SOURCE_VERSION_NUMBER_R(+)---commented as per erica's suggestion
						AND FCT_CLAIM_EXPENSE_PAYMENT_R.V_LINK_BOBJECTNUM_R=PD3.N_SOURCE_SYSTEM_KEY_R(+)
						--and FCT_CLAIM_EXPENSE_PAYMENT_R.v_link_busobjsequence_r =PD3.N_SOURCE_VERSION_NUMBER_R(+)---commented as per erica's suggestion
						AND FCT_CLAIM_EXPENSE_PAYMENT_R.V_LINK_BOBJECTNUM_R=PD4.N_SOURCE_SYSTEM_KEY_R(+)
						--and FCT_CLAIM_EXPENSE_PAYMENT_R.v_link_busobjsequence_r =PD4.N_SOURCE_VERSION_NUMBER_R(+)---commented as per erica's suggestion
						AND FCT_CLAIM_EXPENSE_PAYMENT_R.V_LINK_BOBJECTNUM_R=PD5.N_SOURCE_SYSTEM_KEY_R(+)
						--and FCT_CLAIM_EXPENSE_PAYMENT_R.v_link_busobjsequence_r =PD5.N_SOURCE_VERSION_NUMBER_R(+)---commented as per erica's suggestion
						and nvl(PD1.N_PARTY_SK_R, nvl(PD2.N_PARTY_SK_R, nvl(PD3.N_PARTY_SK_R,  nvl(PD4.N_PARTY_SK_R, nvl(PD5.N_PARTY_SK_R, -1)))))  = dim_grp_party_r.n_party_sk_r(+)
						--AND dim_grp_party_dir_r.V_ACTIVE_STATUS_R = 'Y'----nvl
						--AND dim_grp_party_dir_r.V_PARTY_TYPE_R='PAYEE'
						--AND dim_grp_party_r.V_ACTIVE_STATUS_R = 'Y'----nvl
						--27-SEP-2023 changes ends
						--AND FCT_CLAIM_EXPENSE_PAYMENT_R.N_BATCH_ID_R = LN_N_BATCH_ID_R--26-Apr-2022 Full Load Changes
						--AND UPPER(TRIM(FCT_CLAIM_EXPENSE_PAYMENT_R.V_TRANS_STATUS_R)) IN ('RELEASED','REVERSAL','REVERSED/CANCELLED')--12-May-2022 Erica changes
						--AND UPPER(trim(FCT_CLAIM_EXPENSE_PAYMENT_R.V_TRANS_STATUS_R)) IN ('RELEASED','REVERSAL','REVERSED/CANCELLED', 'REVERSED/RE-ISSUED')  --Removed by Subhadeep
						and FCT_CLAIM_EXPENSE_PAYMENT_R.V_SOURCE_SYSTEM_NAME_R = 'CV'
						--added by Subhadeep start2
						AND EP.N_CLAIM_SK_R						= FCT_CLAIM_EXPENSE_PAYMENT_R.N_CLAIM_SK_R
						AND EP.N_SOURCE_VERSION_SEQ_NUMBER_R	= FCT_CLAIM_EXPENSE_PAYMENT_R.N_SOURCE_VERSION_SEQ_NUMBER_R
						AND EP.v_cheque_number_r				= FCT_CLAIM_EXPENSE_PAYMENT_R.v_cheque_number_r
						AND EP.V_TRANS_STATUS_R					= FCT_CLAIM_EXPENSE_PAYMENT_R.V_TRANS_STATUS_R)
						--added by Subhadeep end2
					)
				UNION
					(SELECT
						 V_CLAIM_NUMBER_R
						,V_COVERAGE_CODE_R
						,V_COV_GROUP_ID_R
						,V_CHECK_NUMBER_R
						,V_PAY_METHOD_R
						,V_BENEFIT_CODE_R
						,V_BENEFIT_DESCRIPTION_R
						,V_BENEFIT_GROUP_R
						,N_GROSS_WAGE_BASE_R
						,N_TAXABLE_PERCENT_R
						,V_PAYMENT_STATUS_R
						,N_PAID_AMOUNT_R
						,V_PAYMENT_TYPE_R
						,D_CHECK_DATE_R
						,V_CHECK_TYPE_R
						,D_PAID_DATE_R
						,N_GROSS_AMOUNT_R
						,D_SERVICE_PERIOD_FROM_R
						,D_SERVICE_PERIOD_TO_R
						,V_RECORD_TYPE_R
						,N_WORKSHEET_OBJECT_NUM_R
						,N_SOURCE_SYSTEM_KEY_R
						,N_SOURCE_VERSION_SEQ_NUMBER_R
						,N_SEQ_R
						,N_GROUP_SEQ_R
						,N_PARENT_OBJECTNUM_R
						,systimestamp                        T_CREATION_DATE_R
						,systimestamp                        T_EVENT_TIMESTAMP_R
						,systimestamp                        T_LAST_MODIFIED_DATE_R
						,'ODI'                                  V_CREATED_BY_R
						,'ODI'                                  V_LAST_MODIFIED_BY_R
						--,TRUNC(SYSDATE)                         FIC_MIS_DATE_R--26-Apr-2022 Full Load Changes
						--,LN_N_BATCH_ID_R                     	N_BATCH_ID_R--26-Apr-2022 Full Load Changes
						,FIC_MIS_DATE_R                     --26-Apr-2022 Full Load Changes
						,N_BATCH_ID_R                     	N_BATCH_ID_R--26-Apr-2022 Full Load Changes
						,1                     N_LOAD_RUN_ID_R
						--,(NVL(NULL,0)+ROWNUM)
						--,0     N_SEQUENCE_NUMBER_R
						,V_BENEFIT_CATEGORY_R
						,N_CLAIM_SK_R                           --08-Apr-2022 Erica changes
						,N_CLAIM_COVERAGE_SK_R                  --08-Apr-2022 Erica changes
						,N_CLAIM_COVERAGE_GROUP_SK_R            --08-Apr-2022 Erica changes
						--27-SEP-2023 changes starts
						,v_payee_first_name_r
						,v_payee_middle_name_r
						,v_payee_last_name_r
						,V_PAYEE_TYPE_R
						--27-SEP-2023 changes ends
						,V_SOURCE_SYSTEM_NAME_R
                        --29-May-2024 changes starts
                        ,V_AMOUNT_TYPE_SUB_NAME_R
                        ,V_AMOUNT_TYPE_CATEGORY_R
                        ,V_AMOUNT_TYPE_CATEGORY_DESC_R
                        ,V_AMOUNT_TYPE_SUB_CATEGORY_R
                        ,V_AMT_TYPE_SUB_CATEGORY_DESC_R
                        ,V_AMOUNT_TYPE_CODE_R
                        ,V_AMOUNT_TYPE_NAME_R
                        ,V_AMOUNT_TYPE_SUB_CODE_R
                        --29-May-2024 changes ends
					FROM
						(SELECT /*+enable_parallel_dml parallel(8)*/
							DIM_GRP_CLAIM_DIR_R.V_CLAIM_NUMBER_R                                           V_CLAIM_NUMBER_R
							--05-Oct-2021 Erica Expense query changes starts
							/*,DIM_GRP_CLAIM_COVERAGE_R.V_COVERAGE_CODE_R                                    V_COVERAGE_CODE_R
							,DIM_GRP_CLAIM_COVERAGE_GROUP_R.V_COV_GRP_CODE_R                               V_COV_GROUP_ID_R*/
							,NVL(DIM_GRP_CLAIM_COVERAGE_GROUP_R.V_CLAIM_COVERAGE_CODE_R,DIM_GRP_CLAIM_COVERAGE_R.V_CLAIM_COVERAGE_CODE_R)          V_COVERAGE_CODE_R
							,DIM_GRP_CLAIM_COVERAGE_GROUP_R.N_COV_GRP_ID_R                               V_COV_GROUP_ID_R
							--05-Oct-2021 Erica Expense query changes ends
							,FCT_CLAIM_EXPENSE_PAYMENT_R.V_CHEQUE_NUMBER_R                                 V_CHECK_NUMBER_R
							,NULL                                                                          V_PAY_METHOD_R
							,FCT_CLAIM_EXPENSE_PAYMENT_R.V_AMOUNT_TYPE_SUB_CODE_R                          V_BENEFIT_CODE_R
							,FCT_CLAIM_EXPENSE_PAYMENT_R.V_AMOUNT_TYPE_NAME_R                              V_BENEFIT_DESCRIPTION_R
							,FCT_CLAIM_EXPENSE_PAYMENT_R.V_AMOUNT_TYPE_CODE_R	                           V_BENEFIT_GROUP_R
							,NULL                                                                          N_GROSS_WAGE_BASE_R
							,NULL                                                                          N_TAXABLE_PERCENT_R
							,DECODE(FCT_CLAIM_EXPENSE_PAYMENT_R.V_TRANS_STATUS_R,'REVERSAL','VOID','PAID') V_PAYMENT_STATUS_R
							,FCT_CLAIM_EXPENSE_PAYMENT_R.N_TRANS_AMOUNT_R                                  N_PAID_AMOUNT_R
							,'PAY'                                                                         V_PAYMENT_TYPE_R
							,FCT_CLAIM_EXPENSE_PAYMENT_R.D_TRANS_DATE_R                                    D_CHECK_DATE_R
							,'OE'                                                                          V_CHECK_TYPE_R
							,FCT_CLAIM_EXPENSE_PAYMENT_R.D_TRANS_DATE_R                                    D_PAID_DATE_R
							,NULL                                                                          N_GROSS_AMOUNT_R
							,NULL                                                                          D_SERVICE_PERIOD_FROM_R
							,NULL                                                                          D_SERVICE_PERIOD_TO_R
							,'Expense'                                                                     V_RECORD_TYPE_R
							,NULL                                                                          N_WORKSHEET_OBJECT_NUM_R
							,FCT_CLAIM_EXPENSE_PAYMENT_R.N_CLAIMEXP_SOURCE_SYSTEM_KEY_R	                   N_SOURCE_SYSTEM_KEY_R
							,FCT_CLAIM_EXPENSE_PAYMENT_R.N_SOURCE_VERSION_SEQ_NUMBER_R	                   N_SOURCE_VERSION_SEQ_NUMBER_R
							,NULL                                                                          N_SEQ_R
							,NULL                                                                          N_GROUP_SEQ_R
							,NULL                                                                          N_PARENT_OBJECTNUM_R
							,FCT_CLAIM_EXPENSE_PAYMENT_R.V_AMOUNT_TYPE_CATEGORY_DESC_R                     V_BENEFIT_CATEGORY_R
							,FCT_CLAIM_EXPENSE_PAYMENT_R.N_CLAIM_SK_R                           --08-Apr-2022 Erica changes
							,FCT_CLAIM_EXPENSE_PAYMENT_R.N_CLAIM_COVERAGE_SK_R                  --08-Apr-2022 Erica changes
							,FCT_CLAIM_EXPENSE_PAYMENT_R.N_CLAIM_COVERAGE_GROUP_SK_R            --08-Apr-2022 Erica changes
							,FCT_CLAIM_EXPENSE_PAYMENT_R.N_BATCH_ID_R                           --26-Apr-2022 Full Load Changes
							,FCT_CLAIM_EXPENSE_PAYMENT_R.FIC_MIS_DATE_R                           --26-Apr-2022 Full Load Changes
							--27-SEP-2023 changes starts
							,dim_grp_party_r.V_INDIVIDUAL_FIRST_NAME_R v_payee_first_name_r
							,dim_grp_party_r.V_INDIVIDUAL_middle_NAME_R v_payee_middle_name_r
							,dim_grp_party_r.V_INDIVIDUAL_LAST_NAME_R v_payee_last_name_r
							,(CASE WHEN PD3.V_PARTY_TYPE_R='VENDOR' THEN 'PRV'
							ELSE NULL END)			V_PAYEE_TYPE_R
							--27-SEP-2023 changes ends
							,FCT_CLAIM_EXPENSE_PAYMENT_R.V_SOURCE_SYSTEM_NAME_R V_SOURCE_SYSTEM_NAME_R
                            --29-May-2024 changes starts
                            ,FCT_CLAIM_EXPENSE_PAYMENT_R.V_AMOUNT_TYPE_SUB_NAME_R,
                            FCT_CLAIM_EXPENSE_PAYMENT_R.V_AMOUNT_TYPE_CATEGORY_R,
                            FCT_CLAIM_EXPENSE_PAYMENT_R.V_AMOUNT_TYPE_CATEGORY_DESC_R,
                            FCT_CLAIM_EXPENSE_PAYMENT_R.V_AMOUNT_TYPE_SUB_CATEGORY_R,
                            FCT_CLAIM_EXPENSE_PAYMENT_R.V_AMT_TYPE_SUB_CATEGORY_DESC_R,
                            FCT_CLAIM_EXPENSE_PAYMENT_R.V_AMOUNT_TYPE_CODE_R,
                            FCT_CLAIM_EXPENSE_PAYMENT_R.V_AMOUNT_TYPE_NAME_R,
                            FCT_CLAIM_EXPENSE_PAYMENT_R.V_AMOUNT_TYPE_SUB_CODE_R
                            --29-May-2024 changes ends
						FROM (SELECT * FROM ATOMIC.FCT_CLAIM_EXPENSE_PAYMENT_R WHERE V_SOURCE_SYSTEM_NAME_R = 'CV') FCT_CLAIM_EXPENSE_PAYMENT_R
							,ATOMIC.DIM_GRP_CLAIM_DIR_R
							,ATOMIC.DIM_GRP_CLAIM_COVERAGE_R
							,ATOMIC.DIM_GRP_CLAIM_COVERAGE_GROUP_R
							----27-SEP-2023 CHANGES STARTS
							,(SELECT * FROM dim_grp_party_dir_r WHERE V_ACTIVE_STATUS_R = 'Y' AND V_PARTY_TYPE_R='PAYEE' AND V_SOURCE_SYSTEM_NAME_R='CV' )PD1
							,(SELECT * FROM dim_grp_party_dir_r WHERE V_ACTIVE_STATUS_R = 'Y' AND V_PARTY_TYPE_R='INSURED' AND V_SOURCE_SYSTEM_NAME_R='CV')PD2
							,(SELECT * FROM dim_grp_party_dir_r WHERE V_ACTIVE_STATUS_R = 'Y' AND V_PARTY_TYPE_R='VENDOR' AND V_SOURCE_SYSTEM_NAME_R='CV')PD3
							,(SELECT * FROM dim_grp_party_dir_r WHERE V_ACTIVE_STATUS_R = 'Y' AND V_PARTY_TYPE_R='PERSON' AND V_SOURCE_SYSTEM_NAME_R='CV')PD4
							,(SELECT * FROM dim_grp_party_dir_r WHERE V_ACTIVE_STATUS_R = 'Y' AND V_PARTY_TYPE_R='CUSTOMER' AND V_SOURCE_SYSTEM_NAME_R='CV')PD5
							,(SELECT * FROM dim_grp_party_r WHERE V_ACTIVE_STATUS_R = 'Y')dim_grp_party_r
							----27-SEP-2023 CHANGES ENDS
						WHERE
						FCT_CLAIM_EXPENSE_PAYMENT_R.N_CLAIM_SK_R = DIM_GRP_CLAIM_DIR_R.N_CLAIM_SK_R
						--08-Apr-2022 Erica changes starts
						/*AND FCT_CLAIM_EXPENSE_PAYMENT_R.N_CLAIM_COVERAGE_SK_R = DIM_GRP_CLAIM_COVERAGE_R.N_CLAIM_COVERAGE_SK_R
						AND FCT_CLAIM_EXPENSE_PAYMENT_R.N_CLAIM_COVERAGE_GROUP_SK_R = DIM_GRP_CLAIM_COVERAGE_GROUP_R.N_CLAIM_COVERAGE_GROUP_SK_R(+)
						*/
						AND FCT_CLAIM_EXPENSE_PAYMENT_R.N_CLAIM_COVERAGE_SK_R = DIM_GRP_CLAIM_COVERAGE_R.N_CLAIM_COVERAGE_SK_R(+)
						AND FCT_CLAIM_EXPENSE_PAYMENT_R.N_CLAIM_COVERAGE_GROUP_SK_R = DIM_GRP_CLAIM_COVERAGE_GROUP_R.N_CLAIM_COVERAGE_GROUP_SK_R(+)
						AND DIM_GRP_CLAIM_DIR_R.V_ACTIVE_STATUS_R = 'Y'
						AND nvl(DIM_GRP_CLAIM_COVERAGE_GROUP_R.V_ACTIVE_STATUS_R,'Y') = 'Y'
						AND nvl(DIM_GRP_CLAIM_COVERAGE_R.V_ACTIVE_STATUS_R, 'Y') = 'Y'
						--08-Apr-2022 Erica changes ends
						--27-SEP-2023 changes starts
						/*Left outer Join dim_grp_party_dir_r on
						Claimexpense.link_bobjectnum =
						Claimexpense.link_busobjsequence
						Filter active status = Y
						Join dim_grp_party_r
						On dim_grp_party_dir_r.n_party_sk_r = dim_grp_party_r.n_party_sk_r
						Filter active status = Y*/
						AND FCT_CLAIM_EXPENSE_PAYMENT_R.V_LINK_BOBJECTNUM_R=PD1.N_SOURCE_SYSTEM_KEY_R(+)
						--and FCT_CLAIM_EXPENSE_PAYMENT_R.v_link_busobjsequence_r =PD1.N_SOURCE_VERSION_NUMBER_R(+)---commented as per erica's suggestion
						AND FCT_CLAIM_EXPENSE_PAYMENT_R.V_LINK_BOBJECTNUM_R=PD2.N_SOURCE_SYSTEM_KEY_R(+)
						--and FCT_CLAIM_EXPENSE_PAYMENT_R.v_link_busobjsequence_r =PD2.N_SOURCE_VERSION_NUMBER_R(+)---commented as per erica's suggestion
						AND FCT_CLAIM_EXPENSE_PAYMENT_R.V_LINK_BOBJECTNUM_R=PD3.N_SOURCE_SYSTEM_KEY_R(+)
						--and FCT_CLAIM_EXPENSE_PAYMENT_R.v_link_busobjsequence_r =PD3.N_SOURCE_VERSION_NUMBER_R(+)---commented as per erica's suggestion
						AND FCT_CLAIM_EXPENSE_PAYMENT_R.V_LINK_BOBJECTNUM_R=PD4.N_SOURCE_SYSTEM_KEY_R(+)
						--and FCT_CLAIM_EXPENSE_PAYMENT_R.v_link_busobjsequence_r =PD4.N_SOURCE_VERSION_NUMBER_R(+)---commented as per erica's suggestion
						AND FCT_CLAIM_EXPENSE_PAYMENT_R.V_LINK_BOBJECTNUM_R=PD5.N_SOURCE_SYSTEM_KEY_R(+)
						--and FCT_CLAIM_EXPENSE_PAYMENT_R.v_link_busobjsequence_r =PD5.N_SOURCE_VERSION_NUMBER_R(+)---commented as per erica's suggestion
						and nvl(PD1.N_PARTY_SK_R, nvl(PD2.N_PARTY_SK_R, nvl(PD3.N_PARTY_SK_R,  nvl(PD4.N_PARTY_SK_R, nvl(PD5.N_PARTY_SK_R, -1)))))  = dim_grp_party_r.n_party_sk_r(+)
						--AND dim_grp_party_dir_r.V_ACTIVE_STATUS_R = 'Y'----nvl
						--AND dim_grp_party_dir_r.V_PARTY_TYPE_R='PAYEE'
						--AND dim_grp_party_r.V_ACTIVE_STATUS_R = 'Y'----nvl
						--27-SEP-2023 changes ends
						--AND FCT_CLAIM_EXPENSE_PAYMENT_R.N_BATCH_ID_R = LN_N_BATCH_ID_R--26-Apr-2022 Full Load Changes
						--AND UPPER(TRIM(FCT_CLAIM_EXPENSE_PAYMENT_R.V_TRANS_STATUS_R)) IN ('RELEASED','REVERSAL','REVERSED/CANCELLED')--12-May-2022 Erica changes
						--AND UPPER(trim(FCT_CLAIM_EXPENSE_PAYMENT_R.V_TRANS_STATUS_R)) IN ('RELEASED','REVERSAL','REVERSED/CANCELLED', 'REVERSED/RE-ISSUED')
						AND FCT_CLAIM_EXPENSE_PAYMENT_R.V_SOURCE_SYSTEM_NAME_R = 'CV'
						AND UPPER(trim(FCT_CLAIM_EXPENSE_PAYMENT_R.V_TRANS_STATUS_R)) IN ('VOID')  --added by Subhadeep
						--	AND FCT_CLAIM_EXPENSE_PAYMENT_R.V_CHEQUE_NUMBER_R in (select a.V_CHEQUE_NUMBER_R from (select FBPR.V_CHEQUE_NUMBER_R, count(FBPR.v_current_status_r)
						--from FCT_CLAIM_EXPENSE_PAYMENT_R FBPR where  FBPR.v_source_system_name_r = 'CV'
						--group by FBPR.V_CHEQUE_NUMBER_R
						--having count(FBPR.v_current_status_r) = 1)a inner join FCT_CLAIM_EXPENSE_PAYMENT_R b
						--on a.V_CHEQUE_NUMBER_R = B.V_CHEQUE_NUMBER_R
						--where  UPPER(TRIM(b.v_current_status_r)) = 'CLEARED')
						)
					)
				) FullData
			) X WHERE RNK = 1
        ) LatestData;







	  EXCEPTION
      WHEN OTHERS THEN
      LC_SQLCODE:=SQLCODE;
      LC_SQLERRM:=SUBSTR(SQLERRM,1,4000);
      OUT_LOAD_STATUS:='r)CV Expense Error :-'||LC_SQLCODE||'-'||LC_SQLERRM;
	  ROLLBACK TO SAVEPOINT SP6;
	  RAISE_APPLICATION_ERROR(-20001,'r)CV Expense Error :-'||LC_SQLCODE||'-'||LC_SQLERRM);
      END ;
        -- Expense Data Load ends
      END IF;

	commit;







	/*SELECT NVL(MAX(N_SEQUENCE_NUMBER_R),0) INTO LN_MAX_SEQ_NUMER_R
	FROM ATOMIC.FCT_CLAIM_PAYMENT_DETAIL_R;*/

	IF LC_SOURCE_CONCEPT = 'ALL' OR LC_SOURCE_CONCEPT LIKE 'DISBURS%' THEN
	-- Disbursement Data Load Starts
	--08-Jun-2022 changes starts
	EXECUTE IMMEDIATE 'TRUNCATE TABLE ATOMIC.FCT_CLAIM_PAYMENT_DETAIL_DISBURSEMENT_R PURGE SNAPSHOT LOG';
	--ATOMIC.PROC_TRUNCATE_PARTITION('FCT_CLAIM_PAYMENT_DETAIL_R','REDIRECT',LN_N_BATCH_ID_R);
	--COMMIT;
	--BEGIN PRC_FCT_CLAIM_PMNT_DET_GAT_TBL_STATS; END;--Gather table and index stats
	--08-Jun-2022 changes ends
    SAVEPOINT SP4;
	BEGIN
	INSERT  /*+APPEND_VALUES*/  INTO ATOMIC.FCT_CLAIM_PAYMENT_DETAIL_DISBURSEMENT_R
		(V_CLAIM_NUMBER_R
		 ,V_COVERAGE_CODE_R
		 ,V_COV_GROUP_ID_R
		 ,V_CHECK_NUMBER_R
		 ,V_PAY_METHOD_R
		 ,V_BENEFIT_CODE_R
		 ,V_BENEFIT_DESCRIPTION_R
		 ,V_BENEFIT_GROUP_R
		 ,N_GROSS_WAGE_BASE_R
		 ,N_TAXABLE_PERCENT_R
		 ,V_PAYMENT_STATUS_R
		 ,N_PAID_AMOUNT_R
		 ,V_PAYMENT_TYPE_R
		 ,D_CHECK_DATE_R
		 ,V_CHECK_TYPE_R
		 ,D_PAID_DATE_R
		 ,N_GROSS_AMOUNT_R
		 ,D_SERVICE_PERIOD_FROM_R
		 ,D_SERVICE_PERIOD_TO_R
		 ,V_RECORD_TYPE_R
		 ,N_WORKSHEET_OBJECT_NUM_R
		 ,N_SOURCE_SYSTEM_KEY_R
		 ,N_SOURCE_VERSION_SEQ_NUMBER_R
		 ,N_SEQ_R
		 ,N_GROUP_SEQ_R
		 ,N_PARENT_OBJECTNUM_R
		 ,T_CREATION_DATE_R
		 ,T_EVENT_TIMESTAMP_R
		 ,T_LAST_MODIFIED_DATE_R
		 ,V_CREATED_BY_R
		 ,V_LAST_MODIFIED_BY_R
		 ,FIC_MIS_DATE_R
		 ,N_BATCH_ID_R
		 ,N_LOAD_RUN_ID_R
		 ,N_SEQUENCE_NUMBER_R
		 ,V_BENEFIT_CATEGORY_R
		 ,N_CLAIM_SK_R           --08-Apr-2022 Erica changes
		 ,N_CLAIM_COVERAGE_SK_R  --08-Apr-2022 Erica changes
		 ,N_CLAIM_COVERAGE_GROUP_SK_R  --27-Feb-2023 Erica changes
		 ,v_payee_last_name_r--27-SEP-2023 changes
		 ,V_PAYEE_TYPE_R---27-SEP-2023 changes
		 ,N_PARTY_SK_R --12-MAR-2024 Changes
		)
		SELECT
		V_CLAIM_NUMBER_R
		,V_COVERAGE_CODE_R
		,V_COV_GROUP_ID_R
		,V_CHECK_NUMBER_R
		,V_PAY_METHOD_R
		,V_BENEFIT_CODE_R
		,V_BENEFIT_DESCRIPTION_R
		,V_BENEFIT_GROUP_R
		,N_GROSS_WAGE_BASE_R
		,N_TAXABLE_PERCENT_R
		,V_PAYMENT_STATUS_R
		,N_PAID_AMOUNT_R
		,V_PAYMENT_TYPE_R
		,D_CHECK_DATE_R
		,V_CHECK_TYPE_R
		,D_PAID_DATE_R
		,N_GROSS_AMOUNT_R
		,D_SERVICE_PERIOD_FROM_R
		,D_SERVICE_PERIOD_TO_R
		,V_RECORD_TYPE_R
		,N_WORKSHEET_OBJECT_NUM_R
		,N_SOURCE_SYSTEM_KEY_R
		,N_SOURCE_VERSION_SEQ_NUMBER_R
		,N_SEQ_R
		,N_GROUP_SEQ_R
		,N_PARENT_OBJECTNUM_R
		,LT_systimestamp                        T_CREATION_DATE_R
		,LT_systimestamp                        T_EVENT_TIMESTAMP_R
		,LT_systimestamp                        T_LAST_MODIFIED_DATE_R
		,'ODI'                                  V_CREATED_BY_R
		,'ODI'                                  V_LAST_MODIFIED_BY_R
		--,TRUNC(SYSDATE)                         FIC_MIS_DATE_R--26-Apr-2022 Full Load Changes
		--,LN_N_BATCH_ID_R                     	N_BATCH_ID_R--26-Apr-2022 Full Load Changes
		,FIC_MIS_DATE_R                     --26-Apr-2022 Full Load Changes
		,N_BATCH_ID_R                     	N_BATCH_ID_R --26-Apr-2022 Full Load Changes
		,LN_N_LOAD_RUN_ID_R                     N_LOAD_RUN_ID_R
		,(NVL(LN_MAX_SEQ_NUMER_R,0)+ROWNUM)     N_SEQUENCE_NUMBER_R
		,'REDIRECT'                             V_BENEFIT_CATEGORY_R
		,N_CLAIM_SK_R                           --08-Apr-2022 Erica changes
		,N_CLAIM_COVERAGE_SK_R                  --08-Apr-2022 Erica changes
		,N_CLAIM_COVERAGE_GROUP_SK_R  --27-Feb-2023 Erica changes
		,v_payee_last_name_r                     --27-SEP-2023 changes
		,V_PAYEE_TYPE_R ----27-SEP-2023
		,N_PARTY_SK_R 	--12-MAR-2024 Changes
		FROM(
		SELECT /*+enable_parallel_dml parallel(8)*/
		   DIM_GRP_CLAIM_DIR_R.V_CLAIM_NUMBER_R                                     V_CLAIM_NUMBER_R
		   --,DIM_GRP_CLAIM_COVERAGE_R.V_COVERAGE_CODE_R                               V_COVERAGE_CODE_R --08-Apr-2022 Erica changes
		   ,DIM_GRP_CLAIM_COVERAGE_R.V_claim_COVERAGE_CODE_R                               V_COVERAGE_CODE_R--08-Apr-2022 Erica changes
		   ,NULL                                                                     V_COV_GROUP_ID_R
		   --,Fct_Claim_Disbursement_R.v_check_num_r                                   V_CHECK_NUMBER_R
		   ,FCT_GRP_REDIRECT_PAYMENT_R.V_CHECK_NUM_R                                   V_CHECK_NUMBER_R
		   ,FCT_GRP_REDIRECT_PAYMENT_R.v_pay_method_r                                  V_PAY_METHOD_R
		   ,(CASE WHEN LENGTH(FCT_GRP_REDIRECT_PAYMENT_R.v_benefit_code_r) <= 3
		   	 THEN FCT_GRP_REDIRECT_PAYMENT_R.v_benefit_code_r
		     ELSE
		   	 CASE WHEN UPPER(SUBSTR(FCT_GRP_REDIRECT_PAYMENT_R.v_benefit_code_r,1,6)) ='POSTTA'
		   	 THEN 'H'||SUBSTR(FCT_GRP_REDIRECT_PAYMENT_R.v_benefit_code_r,19,2)
		   	 WHEN UPPER(SUBSTR(FCT_GRP_REDIRECT_PAYMENT_R.v_benefit_code_r,1,6)) ='PRETAX'
		   	 THEN 'J'||SUBSTR(FCT_GRP_REDIRECT_PAYMENT_R.v_benefit_code_r,18,2)
		   	 ELSE
		   	 	NULL
		   	 End
		     END
		   )                                                                         V_BENEFIT_CODE_R
		   ,FCT_GRP_REDIRECT_PAYMENT_R.V_BENEFIT_DESC_R                                V_BENEFIT_DESCRIPTION_R
		   ,FCT_GRP_REDIRECT_PAYMENT_R.V_BENEFIT_CODE_R                                V_BENEFIT_GROUP_R
		   ,NULL                                                                     N_GROSS_WAGE_BASE_R
		   ,NULL                                                                     N_TAXABLE_PERCENT_R
		   ,DECODE(FCT_GRP_REDIRECT_PAYMENT_R.V_PAY_STATUS_R,'REVERSAL','VOID','PAID') V_PAYMENT_STATUS_R
		   --,FCT_CLAIM_DISBURSEMENT_R.N_AMOUNT_R                                      N_PAID_AMOUNT_R-- 24-Jun-2021 as per Erica/Gisha request
		   ,FCT_GRP_REDIRECT_PAYMENT_R.N_AMOUNT_R                              N_PAID_AMOUNT_R-- 24-Jun-2021 as per Erica/Gisha request
		   ,'RED'                                                                    V_PAYMENT_TYPE_R
		   /*,FCT_GRP_REDIRECT_PAYMENT_R.D_DISBURSE_DATE_R                               D_CHECK_DATE_R*/
		   ,NVL(FCT_GRP_REDIRECT_PAYMENT_R.D_DISBURSE_DATE_R,FCT_GRP_REDIRECT_PAYMENT_R.D_DISB_DATE_R) D_CHECK_DATE_R
		   ,DECODE(FCT_GRP_REDIRECT_PAYMENT_R.V_PAY_METHOD_R,'ACH','ACH','BP')         V_CHECK_TYPE_R
		   --08-Jun-2022 Mohange changes starts
		   /*,DECODE(FCT_GRP_REDIRECT_PAYMENT_R.V_PAY_SCHEDULE_PAYEE_DESC_R,'REVERSED'
		   		,FCT_GRP_REDIRECT_PAYMENT_R.D_REVERSE_DATE_R
		   		,FCT_GRP_REDIRECT_PAYMENT_R.D_DISB_DATE_R)	                         D_PAID_DATE_R*/
           ,(CASE WHEN D_REVERSE_DATE_R is not null THEN
		       D_PAY_DATE_R
		     ELSE DECODE(FCT_GRP_REDIRECT_PAYMENT_R.V_PAY_SCHEDULE_PAYEE_DESC_R,'REVERSED'
                                                                               ,FCT_GRP_REDIRECT_PAYMENT_R.D_REVERSE_DATE_R
                                                                               ,FCT_GRP_REDIRECT_PAYMENT_R.D_DISB_DATE_R)
			END) D_PAID_DATE_R
			--08-Jun-2022 Mohan  changes ends
		   ,NULL                                                                     N_GROSS_AMOUNT_R
		   ,FCT_GRP_REDIRECT_PAYMENT_R.D_SERVICE_PERIOD_START_R                        D_SERVICE_PERIOD_FROM_R
		   ,FCT_GRP_REDIRECT_PAYMENT_R.D_SERVICE_PERIOD_END_R	                         D_SERVICE_PERIOD_TO_R
		   ,'Redirect'                                                               V_RECORD_TYPE_R
		   ,NULL                                                                     N_WORKSHEET_OBJECT_NUM_R
		   ,FCT_GRP_REDIRECT_PAYMENT_R.N_PAY_SCHDL_PAYEE_SRCSYS_KEY_R                      N_SOURCE_SYSTEM_KEY_R
		   ,FCT_GRP_REDIRECT_PAYMENT_R.N_OBJECT_NUM_R	                             N_SOURCE_VERSION_SEQ_NUMBER_R
		   --,NULL                                                                     N_SEQ_R    --22-Apr-2022 Changes
		   ,FCT_GRP_REDIRECT_PAYMENT_R.N_EXT_SUB_SEQUENCE_R                            N_SEQ_R    --22-Apr-2022 Changes
		   ,NULL                                                                     N_GROUP_SEQ_R
		   ,NULL                                                                     N_PARENT_OBJECTNUM_R
           ,FCT_GRP_REDIRECT_PAYMENT_R.N_CLAIM_SK_R		                             N_CLAIM_SK_R --08-Apr-2022 Erica changes
           ,DIM_GRP_CLAIM_COVERAGE_R.N_CLAIM_COVERAGE_SK_R		                     N_CLAIM_COVERAGE_SK_R --08-Apr-2022 Erica changes
		   ,FCT_GRP_REDIRECT_PAYMENT_R.N_BATCH_ID_R                --26-Apr-2022 Full Load Changes
		   ,FCT_GRP_REDIRECT_PAYMENT_R.FIC_MIS_DATE_R                --26-Apr-2022 Full Load Changes
		   ,-1 N_CLAIM_COVERAGE_GROUP_SK_R  --27-Feb-2023 Erica changes
		   ,FCT_GRP_REDIRECT_PAYMENT_R.V_PAYEE_NAME_R v_payee_last_name_r--27-SEP-2023 changes
		   ,'GRP'                                   V_PAYEE_TYPE_R ----27-SEP-2023 Hardcoded as 'PRV' as per gisha's suggestion
		   --03-Oct-2024 changes starts
		  -- ,-1 N_PARTY_SK_R 		--12-MAR-2024 Changes
		   ,FCT_GRP_REDIRECT_PAYMENT_R.n_payee_party_sk_r  N_PARTY_SK_R 		
		   --03-Oct-2024 changes ends
		FROM ATOMIC.FCT_GRP_REDIRECT_PAYMENT_R
			,ATOMIC.DIM_GRP_CLAIM_DIR_R
			,ATOMIC.DIM_GRP_CLAIM_COVERAGE_R
		WHERE
		   FCT_GRP_REDIRECT_PAYMENT_R.N_CLAIM_SK_R = DIM_GRP_CLAIM_DIR_R.N_CLAIM_SK_R
		   and FCT_GRP_REDIRECT_PAYMENT_R.N_CLAIM_SK_R = DIM_GRP_CLAIM_COVERAGE_R.N_CLAIM_SK_R
        --05-Dec-2022 changes start
		   and DIM_GRP_CLAIM_COVERAGE_R.N_CLAIM_COVERAGE_SK_R in (select max(d2.N_CLAIM_COVERAGE_SK_R)
		                                                            from atomic.DIM_GRP_CLAIM_COVERAGE_R D2
		                                                           WHERE D2.N_CLAIM_SK_R =DIM_GRP_CLAIM_COVERAGE_R.N_CLAIM_SK_R
																   AND nvl(d2.V_ACTIVE_STATUS_R, 'Y') = 'Y'
		                                                          )
        --05-Dec-2022 changes end
		   --AND FCT_CLAIM_DISBURSEMENT_R.V_CHECK_NUM_R IS NOT NULL -- 24-Jun-2021 as per Erica/Gisha request
		  -- AND FCT_GRP_REDIRECT_PAYMENT_R.N_CHECK_NUMBER_R IS NOT NULL -- not required with new table
		   --AND FCT_GRP_REDIRECT_PAYMENT_R.N_BATCH_ID_R = LN_N_BATCH_ID_R--26-Apr-2022 Full Load Changes
           AND DIM_GRP_CLAIM_DIR_R.V_ACTIVE_STATUS_R = 'Y'                         --08-Apr-2022 Erica changes
           AND nvl(DIM_GRP_CLAIM_COVERAGE_R.V_ACTIVE_STATUS_R, 'Y') = 'Y'		   --08-Apr-2022 Erica changes
		);



      EXCEPTION
      WHEN OTHERS THEN
      LC_SQLCODE:=SQLCODE;
      LC_SQLERRM:=SUBSTR(SQLERRM,1,4000);
      OUT_LOAD_STATUS:='4)Disbursement Error :-'||LC_SQLCODE||'-'||LC_SQLERRM;
	  ROLLBACK TO SAVEPOINT SP4;
	  RAISE_APPLICATION_ERROR(-20001,'4)Disbursement Error :-'||LC_SQLCODE||'-'||LC_SQLERRM);
      END ;
        -- Disbursement Data Load ends
      END IF;

	COMMIT;

	/*SELECT NVL(MAX(N_SEQUENCE_NUMBER_R),0) INTO LN_MAX_SEQ_NUMER_R
	FROM ATOMIC.FCT_CLAIM_PAYMENT_DETAIL_R;*/

	IF LC_SOURCE_CONCEPT = 'ALL' OR LC_SOURCE_CONCEPT = 'GROSS_BENEFIT' THEN
	--08-Jun-2022 changes starts
 	EXECUTE IMMEDIATE 'TRUNCATE TABLE ATOMIC.FCT_CLAIM_PAYMENT_DETAIL_GROSS_BENEFIT_R PURGE SNAPSHOT LOG';
	--ATOMIC.PROC_TRUNCATE_PARTITION('FCT_CLAIM_PAYMENT_DETAIL_R','GROSS_BENEFIT',LN_N_BATCH_ID_R);
	--COMMIT;
	--BEGIN PRC_FCT_CLAIM_PMNT_DET_GAT_TBL_STATS; END;--Gather table and index stats
    --08-Jun-2022 changes ends
	SAVEPOINT SP5;
	-- 5)Gross Benefit Data Load Starts
	begin
    OPEN cur_gross_benefit;
    LOOP
      l_gb_fct_rec_typ.DELETE;
      FETCH cur_gross_benefit BULK COLLECT INTO l_gb_fct_rec_typ LIMIT ln_bulk_limit_r;
      FORall I IN l_gb_fct_rec_typ.FIRST .. l_gb_fct_rec_typ.COUNT --SAVE EXCEPTIONS
	--loop
	  INSERT /*+APPEND_VALUES*/ INTO atomic.FCT_CLAIM_PAYMENT_DETAIL_GROSS_BENEFIT_R
		( V_CLAIM_NUMBER_R
		 ,V_COVERAGE_CODE_R
		 ,V_COV_GROUP_ID_R
		 ,V_CHECK_NUMBER_R
		 ,V_PAY_METHOD_R
		 ,V_BENEFIT_CODE_R
		 ,V_BENEFIT_DESCRIPTION_R
		 ,V_BENEFIT_GROUP_R
		 ,N_GROSS_WAGE_BASE_R
		 ,N_TAXABLE_PERCENT_R
		 ,V_PAYMENT_STATUS_R
		 ,N_PAID_AMOUNT_R
		 ,V_PAYMENT_TYPE_R
		 ,D_CHECK_DATE_R
		 ,V_CHECK_TYPE_R
		 ,D_PAID_DATE_R
		 ,N_GROSS_AMOUNT_R
		 ,D_SERVICE_PERIOD_FROM_R
		 ,D_SERVICE_PERIOD_TO_R
		 ,V_RECORD_TYPE_R
		 ,N_WORKSHEET_OBJECT_NUM_R
		 ,N_SOURCE_SYSTEM_KEY_R
		 ,N_SOURCE_VERSION_SEQ_NUMBER_R
		 ,N_SEQ_R
		 ,N_GROUP_SEQ_R
		 ,N_PARENT_OBJECTNUM_R
		 ,T_CREATION_DATE_R
		 ,T_EVENT_TIMESTAMP_R
		 ,T_LAST_MODIFIED_DATE_R
		 ,V_CREATED_BY_R
		 ,V_LAST_MODIFIED_BY_R
		 ,FIC_MIS_DATE_R
		 ,N_BATCH_ID_R
		 ,N_LOAD_RUN_ID_R
		 ,N_SEQUENCE_NUMBER_R
		 ,V_BENEFIT_CATEGORY_R
         ,N_PAID_CLAIM_BENEFITS_R
         ,N_TAXABLE_BENEFIT_AMT_R
         ,N_FEDERAL_TAX_WITHHELD_AMT_R
         ,N_STATE_TAX_WITHHELD_AMT_R
         ,N_EMPLOYEE_SS_WITHHELD_AMT_R
         ,N_EMPLOYEE_MED_WITHHELD_AMT_R
         ,N_EMPLOYER_SS_WITHHELD_AMT_R
         ,N_EMPLOYER_MED_WITHHELD_AMT_R
         ,N_LEGAL_EXPENSE_DIRECT_AMT_R
         ,N_OTHER_EXPENSE_DIRECT_AMT_R
         ,V_LOB_TYPE_R                  --to achieve On Erica's requirement 28-Jul-2021
         ,N_MODAL_AMOUNT_R              --to achieve On Erica's requirement 28-Jul-2021
         ,N_PRIMARY_PAYEE_R             --to achieve On Erica's requirement 28-Jul-2021
         ,N_ADJ_GROSS_BENEFIT_R         --to achieve On Erica's requirement 28-Jul-2021
         ,N_PAY_AMOUNT_R                --to achieve On Erica's requirement 28-Jul-2021
         ,N_CLAIM_SK_R                  --to achieve On Erica's requirement 28-Jul-2021
         ,V_GROSS_BENEFIT_CODE_R        --As requested by Erica on 16-Nov-2021
		 ,N_CLAIM_COVERAGE_SK_R                  --08-Apr-2022 Erica changes
		 ,N_CLAIM_COVERAGE_GROUP_SK_R            --08-Apr-2022 Erica changes
         ,v_source_system_name_r --14-Dec-2022 changes
		 --27-SEP-2023 CHANGES STARTS
		 ,v_payee_first_name_r
		 ,v_payee_middle_name_r
		 ,v_payee_last_name_r
         ,V_PAYEE_TYPE_R
         --27-SEP-2023 CHANGES ENDS
		 ,V_TAX_STATE_R--31-JAN-2024 changes
		 ,n_party_sk_r
         --29-May-2024 changes starts
         ,V_AMOUNT_TYPE_SUB_NAME_R,
         V_AMOUNT_TYPE_CATEGORY_R,
         V_AMOUNT_TYPE_CATEGORY_DESC_R,
         V_AMOUNT_TYPE_SUB_CATEGORY_R,
         V_AMT_TYPE_SUB_CATEGORY_DESC_R,
         V_AMOUNT_TYPE_CODE_R,
         V_AMOUNT_TYPE_NAME_R,
         V_AMOUNT_TYPE_SUB_CODE_R
         --29-May-2024 changes ends
		)
       VALUES(l_gb_fct_rec_typ(i).V_CLAIM_NUMBER_R
		     ,l_gb_fct_rec_typ(i).V_COVERAGE_CODE_R
		     ,l_gb_fct_rec_typ(i).V_COV_GROUP_ID_R
		     ,l_gb_fct_rec_typ(i).V_CHECK_NUMBER_R
		     ,l_gb_fct_rec_typ(i).V_PAY_METHOD_R
		     ,l_gb_fct_rec_typ(i).V_BENEFIT_CODE_R
		     ,l_gb_fct_rec_typ(i).V_BENEFIT_DESCRIPTION_R
		     ,l_gb_fct_rec_typ(i).V_BENEFIT_GROUP_R
		     ,l_gb_fct_rec_typ(i).N_GROSS_WAGE_BASE_R
		     ,l_gb_fct_rec_typ(i).N_TAXABLE_PERCENT_R
		     ,l_gb_fct_rec_typ(i).V_PAYMENT_STATUS_R
		     ,l_gb_fct_rec_typ(i).N_PAID_AMOUNT_R
		     ,l_gb_fct_rec_typ(i).V_PAYMENT_TYPE_R
		     ,l_gb_fct_rec_typ(i).D_CHECK_DATE_R
		     ,l_gb_fct_rec_typ(i).V_CHECK_TYPE_R
		     ,l_gb_fct_rec_typ(i).D_PAID_DATE_R
		     ,l_gb_fct_rec_typ(i).N_GROSS_AMOUNT_R
		     ,l_gb_fct_rec_typ(i).D_SERVICE_PERIOD_FROM_R
		     ,l_gb_fct_rec_typ(i).D_SERVICE_PERIOD_TO_R
		     ,l_gb_fct_rec_typ(i).V_RECORD_TYPE_R
		     ,l_gb_fct_rec_typ(i).N_WORKSHEET_OBJECT_NUM_R
		     ,l_gb_fct_rec_typ(i).N_SOURCE_SYSTEM_KEY_R
		     ,l_gb_fct_rec_typ(i).N_SOURCE_VERSION_SEQ_NUMBER_R
		     ,l_gb_fct_rec_typ(i).N_SEQ_R
		     ,l_gb_fct_rec_typ(i).N_GROUP_SEQ_R
		     ,l_gb_fct_rec_typ(i).N_PARENT_OBJECTNUM_R
		     ,l_gb_fct_rec_typ(i).T_CREATION_DATE_R
		     ,l_gb_fct_rec_typ(i).T_EVENT_TIMESTAMP_R
		     ,l_gb_fct_rec_typ(i).T_LAST_MODIFIED_DATE_R
		     ,l_gb_fct_rec_typ(i).V_CREATED_BY_R
		     ,l_gb_fct_rec_typ(i).V_LAST_MODIFIED_BY_R
		     ,l_gb_fct_rec_typ(i).FIC_MIS_DATE_R
		     ,l_gb_fct_rec_typ(i).N_BATCH_ID_R
		     ,l_gb_fct_rec_typ(i).N_LOAD_RUN_ID_R
		     ,l_gb_fct_rec_typ(i).N_SEQUENCE_NUMBER_R
		     ,l_gb_fct_rec_typ(i).V_BENEFIT_CATEGORY_R
             ,l_gb_fct_rec_typ(i).N_PAID_CLAIM_BENEFITS_R
             ,l_gb_fct_rec_typ(i).N_TAXABLE_BENEFIT_AMT_R
             ,l_gb_fct_rec_typ(i).N_FEDERAL_TAX_WITHHELD_AMT_R
             ,l_gb_fct_rec_typ(i).N_STATE_TAX_WITHHELD_AMT_R
             ,l_gb_fct_rec_typ(i).N_EMPLOYEE_SS_WITHHELD_AMT_R
             ,l_gb_fct_rec_typ(i).N_EMPLOYEE_MED_WITHHELD_AMT_R
             ,l_gb_fct_rec_typ(i).N_EMPLOYER_SS_WITHHELD_AMT_R
             ,l_gb_fct_rec_typ(i).N_EMPLOYER_MED_WITHHELD_AMT_R
             ,l_gb_fct_rec_typ(i).N_LEGAL_EXPENSE_DIRECT_AMT_R
             ,l_gb_fct_rec_typ(i).N_OTHER_EXPENSE_DIRECT_AMT_R
             ,l_gb_fct_rec_typ(i).V_LOB_TYPE_R                  --to achieve On Erica's requirement 28-Jul-2021
             ,l_gb_fct_rec_typ(i).N_MODAL_AMOUNT_R              --to achieve On Erica's requirement 28-Jul-2021
             ,l_gb_fct_rec_typ(i).N_PRIMARY_PAYEE_R             --to achieve On Erica's requirement 28-Jul-2021
             ,l_gb_fct_rec_typ(i).N_ADJ_GROSS_BENEFIT_R         --to achieve On Erica's requirement 28-Jul-2021
             ,l_gb_fct_rec_typ(i).N_PAY_AMOUNT_R                --to achieve On Erica's requirement 28-Jul-2021
             ,l_gb_fct_rec_typ(i).N_CLAIM_SK_R                  --to achieve On Erica's requirement 28-Jul-2021
             ,l_gb_fct_rec_typ(i).V_GROSS_BENEFIT_CODE_R        --As requested by Erica on 16-Nov-2021
		     ,l_gb_fct_rec_typ(i).N_CLAIM_COVERAGE_SK_R                  --08-Apr-2022 Erica changes
		     ,l_gb_fct_rec_typ(i).N_CLAIM_COVERAGE_GROUP_SK_R            --08-Apr-2022 Erica changes
             ,l_gb_fct_rec_typ(i).v_source_system_name_r --14-Dec-2022 changes
			 --27-SEP-2023 STARTS
			 ,l_gb_fct_rec_typ(i).v_payee_first_name_r
			 ,l_gb_fct_rec_typ(i).v_payee_middle_name_r
			 ,l_gb_fct_rec_typ(i).v_payee_last_name_r
			 ,l_gb_fct_rec_typ(i).V_PAYEE_TYPE_R
			 --27-SEP-2023 ENDS
			 ,l_gb_fct_rec_typ(i).V_TAX_STATE_R--31-JAN-2024 changes
			 ,l_gb_fct_rec_typ(i).n_party_sk_r
              --29-May-2024 changes starts
             ,l_gb_fct_rec_typ(i).V_BENEFIT_DESCRIPTION_R            --V_AMOUNT_TYPE_SUB_NAME_R,
             ,DECODE(UPPER(l_gb_fct_rec_typ(i).V_BENEFIT_CATEGORY_R)
			                    ,'REDIRECT','RE'
                                ,'OFFSETS' ,'OF'
                                ,'OPTIONAL','OP'
             		            ,'BENEFIT' ,'BE'
             		            ,'EXPENSE' ,'EX'
             		            ,'TAXES'   ,'TA'
             		            ,NULL
             		       ),-- V_AMOUNT_TYPE_CATEGORY_R,
              l_gb_fct_rec_typ(i).V_BENEFIT_CATEGORY_R               --V_AMOUNT_TYPE_CATEGORY_DESC_R,
              ,DECODE(UPPER(l_gb_fct_rec_typ(i).V_BENEFIT_CATEGORY_R)
			       ,'REDIRECT','RE'
                   ,'OFFSETS' ,'OF'
                   ,'OPTIONAL','OP'
                   ,'BENEFIT' ,'BE'
                   ,'EXPENSE' ,'EX'
                   ,'TAXES'   ,'TA'
                   ,NULL
              ) ,                                                     --V_AMOUNT_TYPE_SUB_CATEGORY_R,
              l_gb_fct_rec_typ(i).V_BENEFIT_CATEGORY_R,               --V_AMT_TYPE_SUB_CATEGORY_DESC_R,
              l_gb_fct_rec_typ(i).V_BENEFIT_GROUP_R,                  --V_AMOUNT_TYPE_CODE_R,
              l_gb_fct_rec_typ(i).V_BENEFIT_DESCRIPTION_R,            --V_AMOUNT_TYPE_NAME_R,
              l_gb_fct_rec_typ(i).V_BENEFIT_CODE_R                    --V_AMOUNT_TYPE_SUB_CODE_R
              --29-May-2024 changes ends
		);

    EXIT WHEN cur_gross_benefit%NOTFOUND;
    END LOOP;
    CLOSE cur_gross_benefit;


    EXCEPTION
    WHEN OTHERS THEN
    LC_SQLCODE:=SQLCODE;
    LC_SQLERRM:=SUBSTR(SQLERRM,1,4000);
    OUT_LOAD_STATUS:='5)Gross Benefit Error :-'||LC_SQLCODE||'-'||LC_SQLERRM;
	ROLLBACK TO SAVEPOINT SP5;
	RAISE_APPLICATION_ERROR(-20001,'5)Gross Benefit Error :-'||LC_SQLCODE||'-'||LC_SQLERRM);
    END ;
        -- 5)Gross Benefit Data Load ends
    END IF;


commit;
OUT_LOAD_STATUS:='SUCCESS';
EXCEPTION
WHEN OTHERS THEN
LC_SQLCODE:=SQLCODE;
LC_SQLERRM:=SUBSTR(SQLERRM,1,4000);
OUT_LOAD_STATUS:=LC_SQLCODE||'-'||LC_SQLERRM;
DBMS_OUTPUT.PUT_LINE('PRC_LOAD_PRC_FULLLOAD_FCT_CLAIM_PMT_DET_R  EXCEPTION WITH ERROR CODE AS '
             || SQLCODE
             || ' '
             || SQLERRM
             || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
             ||'PRC_FULLLOAD_FCT_CLAIM_PMT_DET_R'
             ||';');

END PRC_FULLLOAD_FCT_CLAIM_PMT_DET_R;

--21-Mar-2024 changes starts
PROCEDURE prc_rebuild_indexes(p_table_name IN VARCHAR2)
IS
LC_REBUILD_INDEX  VARCHAR2(300);
 LC_SQLCODE VARCHAR2(40);
 LC_SQLERRM VARCHAR2(4000);
BEGIN
  FOR I IN ( select
    'ALTER INDEX '||INDEX_NAME||' REBUILD' REBUILD_INDEX
    from ALL_INDEXES  where TABLE_NAME =UPPER(p_table_name)
	--AND INDEX_NAME NOT LIKE 'PK_%'
	AND INDEX_NAME NOT LIKE 'FK_%'
	AND STATUS='UNUSABLE'
	)
  LOOP
    LC_REBUILD_INDEX:=I.REBUILD_INDEX;
    EXECUTE IMMEDIATE LC_REBUILD_INDEX;
  END LOOP;
EXCEPTION
WHEN OTHERS THEN
    LC_SQLCODE:=SQLCODE;
    LC_SQLERRM:=SUBSTR(SQLERRM,1,4000);
	RAISE_APPLICATION_ERROR(-20001,'z)prc_rebuild_indexes Error :-'||p_table_name||'->'||LC_SQLCODE||'-'||LC_SQLERRM);
END prc_rebuild_indexes;
--21-Mar-2024 changes ends
/*-- This procedure can be used adhoc if the procedure PRC_FULLLOAD_FCT_CLAIM_PMT_DET_R fails to update N_GROSS_AMOUNT_R column for Benefit Payment Records
--then the below procedure can run adhoc instead of running again PRC_FULLLOAD_FCT_CLAIM_PMT_DET_R to update N_GROSS_AMOUNT_R which wil try to load the data again
PROCEDURE PRC_GRP_UPD_N_GROSS_AMOUNT_R_FCT_CLAIM_PMT_DET_R(
    IN_BATCH_ID_R        IN NUMBER,
    OUT_LOAD_STATUS      OUT VARCHAR2
    )
IS
  LC_SQLCODE           VARCHAR2(4000);
  LC_SQLERRM           VARCHAR2(4000);
  LN_N_BATCH_ID_R      NUMBER:=IN_BATCH_ID_R;
  LN_GROSS_AMT_R       NUMBER;
CURSOR cur_bene_pymnt_claim_cnt(p_v_record_type_r IN VARCHAR2)
IS
SELECT * FROM
(SELECT COUNT(1) rowcount, v_claim_number_r, n_source_version_seq_number_r
  FROM ATOMIC.FCT_CLAIM_PAYMENT_DETAIL_R
 WHERE v_record_type_r = p_v_record_type_r--'Benefit Payment'
   AND N_BATCH_ID_R=LN_N_BATCH_ID_R
   AND n_gross_amount_r IS NULL
GROUP BY v_claim_number_r, n_source_version_seq_number_r
)
ORDER BY v_claim_number_r, n_source_version_seq_number_r
;

  TYPE l_bene_pymnt_claim_tbl_typ IS TABLE OF cur_bene_pymnt_claim_cnt%ROWTYPE INDEX BY BINARY_INTEGER;
  L_BENE_PYMNT_CLAIM_REC_TYP   L_BENE_PYMNT_CLAIM_TBL_TYP;
  LN_BULK_LIMIT_R NUMBER:=1000;

BEGIN

			OPEN cur_bene_pymnt_claim_cnt('Benefit Payment');
			LOOP
				l_bene_pymnt_claim_rec_typ.DELETE;

				FETCH cur_bene_pymnt_claim_cnt BULK COLLECT INTO l_bene_pymnt_claim_rec_typ LIMIT LN_BULK_LIMIT_R;
				FOR i IN 1..l_bene_pymnt_claim_rec_typ.COUNT
				LOOP
					LN_GROSS_AMT_R:=ATOMIC.PKG_GRP_FULLLOAD_FCT_CLAIM_PAYMENT_DETAIL_R.GET_N_GROSS_AMOUNT_R(l_bene_pymnt_claim_rec_typ(i).ROWCOUNT
														,l_bene_pymnt_claim_rec_typ(i).V_CLAIM_NUMBER_R
														,L_BENE_PYMNT_CLAIM_REC_TYP(I).N_SOURCE_VERSION_SEQ_NUMBER_R
                            ,LN_N_BATCH_ID_R);
					UPDATE  ATOMIC.FCT_CLAIM_PAYMENT_DETAIL_R
					SET n_gross_amount_r = ln_gross_amt_r
					WHERE v_claim_number_r=l_bene_pymnt_claim_rec_typ(i).v_claim_number_r
					AND n_source_version_seq_number_r =l_bene_pymnt_claim_rec_typ(i).n_source_version_seq_number_r
					and v_record_type_r = 'Benefit Payment'
          AND N_BATCH_ID_R=LN_N_BATCH_ID_R
					 ;
					commit;

				END LOOP;--FOR i IN 1..l_bene_pymnt_claim_rec_typ.COUNT
			EXIT WHEN cur_bene_pymnt_claim_cnt%NOTFOUND;
			END LOOP;
			CLOSE CUR_BENE_PYMNT_CLAIM_CNT;
OUT_LOAD_STATUS:='SUCCESS';
EXCEPTION
WHEN OTHERS THEN
LC_SQLCODE:=SQLCODE;
LC_SQLERRM:=SUBSTR(SQLERRM,1,4000);
OUT_LOAD_STATUS:=LC_SQLCODE||'-'||LC_SQLERRM;
DBMS_OUTPUT.PUT_LINE('PRC_GRP_UPD_N_GROSS_AMOUNT_R_FCT_CLAIM_PMT_DET_R  EXCEPTION WITH ERROR CODE AS '
             || SQLCODE
             || ' '
             || SQLERRM
             || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
             ||'PRC_GRP_UPD_N_GROSS_AMOUNT_R_FCT_CLAIM_PMT_DET_R'
             ||';');

END PRC_GRP_UPD_N_GROSS_AMOUNT_R_FCT_CLAIM_PMT_DET_R;
*/
end PKG_GRP_FULLLOAD_FCT_CLAIM_PAYMENT_DETAIL_R;