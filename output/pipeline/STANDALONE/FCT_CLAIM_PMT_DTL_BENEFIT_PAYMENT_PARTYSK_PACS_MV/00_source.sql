"
CREATE MATERIALIZED VIEW "ATOMIC"."FCT_CLAIM_PMT_DTL_BENEFIT_PAYMENT_PARTYSK_PACS_MV" ("V_CLAIM_NUMBER_R", "V_COVERAGE_CODE_R", "V_COV_GROUP_ID_R", "V_CHECK_NUMBER_R", "V_PAY_METHOD_R", "V_BENEFIT_CODE_R", "V_BENEFIT_DESCRIPTION_R", "V_BENEFIT_GROUP_R", "N_GROSS_WAGE_BASE_R", "N_TAXABLE_PERCENT_R", "V_PAYMENT_STATUS_R", "N_PAID_AMOUNT_R", "V_PAYMENT_TYPE_R", "D_CHECK_DATE_R", "V_CHECK_TYPE_R", "D_PAID_DATE_R", "N_GROSS_AMOUNT_R", "D_SERVICE_PERIOD_FROM_R", "D_SERVICE_PERIOD_TO_R", "V_RECORD_TYPE_R", "N_WORKSHEET_OBJECT_NUM_R", "N_SOURCE_SYSTEM_KEY_R", "N_SOURCE_VERSION_SEQ_NUMBER_R", "N_SEQ_R", "N_GROUP_SEQ_R", "N_PARENT_OBJECTNUM_R", "FIC_MIS_DATE_R", "N_BATCH_ID_R", "V_BENEFIT_CATEGORY_R", "N_PAID_CLAIM_BENEFITS_R", "N_TAXABLE_BENEFIT_AMT_R", "N_FEDERAL_TAX_WITHHELD_AMT_R", "N_STATE_TAX_WITHHELD_AMT_R", "N_EMPLOYEE_SS_WITHHELD_AMT_R", "N_EMPLOYEE_MED_WITHHELD_AMT_R", "N_EMPLOYER_SS_WITHHELD_AMT_R", "N_EMPLOYER_MED_WITHHELD_AMT_R", "N_LEGAL_EXPENSE_DIRECT_AMT_R", "N_OTHER_EXPENSE_DIRECT_AMT_R", "V_LOB_TYPE_R", "N_MODAL_AMOUNT_R", "N_PRIMARY_PAYEE_R", "N_ADJ_GROSS_BENEFIT_R", "N_PAY_AMOUNT_R", "N_CLAIM_SK_R", "V_GROSS_BENEFIT_CODE_R", "N_CLAIM_COVERAGE_SK_R", "N_CLAIM_COVERAGE_GROUP_SK_R", "N_FBPDR_N_SEQ_R", "V_SOURCE_SYSTEM_NAME_R", "N_SS_WAGE_BASE_R", "N_MED_WAGE_BASE_R", "V_PAYEE_FIRST_NAME_R", "V_PAYEE_MIDDLE_NAME_R", "V_PAYEE_LAST_NAME_R", "V_PAYEE_TYPE_R", "V_PAYMENT_RECORD_TYPE_R", "V_TAX_STATE_R", "N_PARTY_SK_R", "V_AMOUNT_TYPE_SUB_NAME_R", "V_AMOUNT_TYPE_CATEGORY_R", "V_AMOUNT_TYPE_CATEGORY_DESC_R", "V_AMOUNT_TYPE_SUB_CATEGORY_R", "V_AMT_TYPE_SUB_CATEGORY_DESC_R", "V_AMOUNT_TYPE_CODE_R", "V_AMOUNT_TYPE_NAME_R", "V_AMOUNT_TYPE_SUB_CODE_R", "PARTY_D_RECORD_START_DATE_R")
  SEGMENT CREATION IMMEDIATE
  ORGANIZATION HEAP PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "OFS_OIDF_DATA_3" 
  PARALLEL 16 
  BUILD IMMEDIATE
  USING INDEX 
  REFRESH FORCE ON DEMAND
  USING DEFAULT LOCAL ROLLBACK SEGMENT
  USING ENFORCED CONSTRAINTS DISABLE ON QUERY COMPUTATION DISABLE QUERY REWRITE
  AS SELECT    /*+PARALLEL(4)*/ DISTINCT 
		DGCDR.v_claim_number_r                                                                                       V_CLAIM_NUMBER_R
		,NVL(DGCCGR.V_CLAIM_COVERAGE_CODE_R,DGCCR.V_CLAIM_COVERAGE_CODE_R)                                           V_COVERAGE_CODE_R--11-aUG-2021 As per Erica's request mapping has been changed from DGCCR.V_COVERAGE_CODE_R
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
		,cast(NULL as number)                                                                                                        N_GROSS_AMOUNT_R
		,FBPR.D_SERVICE_PERIOD_START_R                                                                               D_SERVICE_PERIOD_FROM_R
		,FBPR.D_SERVICE_PERIOD_END_R                                                                                 D_SERVICE_PERIOD_TO_R
		, 'Benefit Payment'                                                                                          V_RECORD_TYPE_R
		,FBPR.N_WORKSHEET_SEQ_NBR_OBJECTNM_R                                                                         N_WORKSHEET_OBJECT_NUM_R
		,FBPR.N_PAY_SCHD_SOURCE_SYSTEM_KEY_R                                                                         N_SOURCE_SYSTEM_KEY_R
		,FBPR.N_SOURCE_VERSION_SEQ_NUMBER_R                                                                          N_SOURCE_VERSION_SEQ_NUMBER_R
		,FBPR.N_SEQ_R                                                                                                N_SEQ_R
		,FBPR.N_GROUP_SEQ_R                                                                                          N_GROUP_SEQ_R
		,FBPR.N_PARENT_OBJECTNUM_R                                                                                   N_PARENT_OBJECTNUM_R
		--26-Jun-2024 changes starts
        --,LT_systimestamp                                                                                             T_CREATION_DATE_R
        --,LT_systimestamp                                                                                             T_EVENT_TIMESTAMP_R
        --,LT_systimestamp                                                                                             T_LAST_MODIFIED_DATE_R
        --,'ODI'                                                                                                       V_CREATED_BY_R
        --,'ODI'                                                                                                       V_LAST_MODIFIED_BY_R
		--26-Jun-2024 changes ends
		,FBPR.FIC_MIS_DATE_R--26-Apr-2022 Full Load Changes
		,FBPR.N_BATCH_ID_R--26-Apr-2022 Full Load Changes
        --,LN_N_LOAD_RUN_ID_R                     N_LOAD_RUN_ID_R
       -- ,(NVL(LN_MAX_SEQ_NUMER_R,0)+ROWNUM)     N_SEQUENCE_NUMBER_R--		--26-Jun-2024 changes 
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
		,FBPDR.N_SEQ_R                       N_FBPDR_N_SEQ_R --10-Nov-2022 changes for Merge
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
		,cast(null as varchar2(30)) AS V_PAYMENT_RECORD_TYPE_R --04-JAN-2024 changes
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
		,pa.d_record_start_date_r as party_d_record_start_date_r 		--26-Jun-2024 changes 
		FROM ATOMIC.FCT_BENEFIT_PAYMENT_R FBPR
			,ATOMIC.DIM_GRP_CLAIM_DIR_R DGCDR
			,ATOMIC.FCT_GRP_WORKSHEET FGW
			,ATOMIC.FCT_BENEFIT_PAYMENT_DETAIL_R FBPDR
			,ATOMIC.DIM_GRP_CLAIM_COVERAGE_GROUP_R DGCCGR
			,ATOMIC.DIM_GRP_CLAIM_COVERAGE_R DGCCR
			,(SELECT * FROM ATOMIC.dim_payment_details pd WHERE PD.V_ACTIVE_STATUS_R = 'Y')PD --27-SEP-2023 changes
			,(select * from dim_grp_party_r where v_active_status_r = 'Y')  pa --27-SEP-2023 changes
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
		--AND FBPR.N_BATCH_ID_R = LN_N_BATCH_ID_R
		--27-SEP-2023 changes starts
		AND DGCDR.N_SOURCE_SYSTEM_KEY_R =PD.V_PAYMNT_DTLS_SRC_SYS_KEY_R(+)------27-SEP-2023 change,  TABLE ORDER REVERSED WITH OUTER JOIN
        --AND PD.V_ACTIVE_STATUS_R = 'Y'
        AND FBPR.N_WORKSHEET_SEQ_NBR_OBJECTNM_R = PD.V_WORKSHEET_OBJECTNUM_R(+)------27-SEP-2023 change,  TABLE ORDER REVERSED WITH OUTER JOIN
        --AND PD.V_WORKSHEET_OBJECTNUM_R = FBPR.N_WORKSHEET_SEQ_NBR_OBJECTNM_R(+)
        --26-Jun-2024 below join commented to pull the party sk for the update		
        --AND NVL(FBPR.V_LINK_OBJECTNUM_R,0)=PD.V_PAYMNT_DTLS_SEQ_NBR_R(+)----27-SEP-2023 CHANGES,  TABLE ORDER REVERSED WITH OUTER JOIN AND NVL IMPLEMENTATION
		--06-Jun-2024 commented above join to fetch party_sk
        and pd.N_INSRD_PARTY_SK_R = pa.n_party_sk_r(+) --27-SEP-2023 change - outer join on party_SK_R
		--15/09 changes  committed the below code
        --and pa.v_active_status_r = 'Y'
--        and pd.V_PAYMNT_DTLS_SEQ_NBR_R = (select max(a.V_PAYMNT_DTLS_SEQ_NBR_R)
--                                    from dim_payment_details a
--                                    where a.V_PAYMNT_DTLS_SRC_SYS_KEY_R = pd.V_PAYMNT_DTLS_SRC_SYS_KEY_R
--                                    and a.V_WORKSHEET_OBJECTNUM_R = pd.V_WORKSHEET_OBJECTNUM_R
--                                    and a.v_active_status_r = 'Y')
        --27-SEP-2023 changes ends
		--26-Jun-2024 changes starts
	    and NVL(FBPR.v_source_system_name_r,'X@')='PACS'
		AND EXISTS (SELECT 1 
		              FROM FCT_CLAIM_PAYMENT_DETAIL_BENEFIT_PAYMENT_R F
					 WHERE F.N_SOURCE_VERSION_SEQ_NUMBER_R||F.N_CLAIM_SK_R||F.N_CLAIM_COVERAGE_SK_R||F.N_SEQ_R||F.N_CLAIM_COVERAGE_GROUP_SK_R||F.N_FBPDR_N_SEQ_R
					 = FBPR.N_SOURCE_VERSION_SEQ_NUMBER_R||FBPR.N_CLAIM_SK_R||FBPR.N_CLAIM_COVERAGE_SK_R||FBPR.N_SEQ_R||FBPR.N_CLAIM_COVERAGE_GROUP_SK_R||FBPDR.N_SEQ_R
					 AND NVL(F.N_PARTY_SK_R,-1)=-1
					 and NVL(F.v_source_system_name_r,'X@')='PACS'
					)
		AND NVL(pa.n_party_sk_r,-1)<>-1
		--26-Jun-2024 changes ends"