-- Cleaned for lineage: PROC_REFRESH_GRP_M_VIEW_TBLS__FCT_BENEFIT_PAYMENT_DETAIL_OFFSET_MV (part 2/3)

INSERT  INTO FCT_BENEFIT_PAYMENT_DETAIL_OFFSET_MV_TBL (
							V_CLAIM_NUMBER_R                       ,
							V_COVERAGE_CODE_R                      ,
							V_COV_GROUP_ID_R                       ,
							V_CHECK_NUMBER_R                       ,
							V_PAY_METHOD_R                         ,
							V_BENEFIT_CODE_R                       ,
							V_BENEFIT_DESCRIPTION_R                ,
							V_BENEFIT_GROUP_R                      ,
							N_GROSS_WAGE_BASE_R                    ,
							N_TAXABLE_PERCENT_R                    ,
							V_PAYMENT_STATUS_R                     ,
							N_PAID_AMOUNT_R                        ,
							V_PAYMENT_TYPE_R                       ,
							D_CHECK_DATE_R                         ,
							V_CHECK_TYPE_R                         ,
							D_PAID_DATE_R                          ,
							N_GROSS_AMOUNT_R                       ,
							D_SERVICE_PERIOD_FROM_R                ,
							D_SERVICE_PERIOD_TO_R                  ,
							V_OFFSET_TYPE_R                        ,
							V_RECORD_TYPE_R                        ,
							N_WORKSHEET_OBJECT_NUM_R               ,
							N_SOURCE_SYSTEM_KEY_R                  ,
							N_SOURCE_VERSION_SEQ_NUMBER_R          ,
							N_SEQ_R                                ,
							N_GROUP_SEQ_R                          ,
							N_PARENT_OBJECTNUM_R                   ,
							T_CREATION_DATE_R                      ,
							T_EVENT_TIMESTAMP_R                    ,
							T_LAST_MODIFIED_DATE_R                 ,
							V_CREATED_BY_R                         ,
							V_LAST_MODIFIED_BY_R                   ,
							FIC_MIS_DATE_R                         ,
							N_BATCH_ID_R                           ,
							N_LOAD_RUN_ID_R                        ,
							N_SEQUENCE_NUMBER_R                    ,
							V_BENEFIT_CATEGORY_R                   ,
							N_PAID_CLAIM_BENEFITS_R                ,
							N_TAXABLE_BENEFIT_AMT_R                ,
							N_FEDERAL_TAX_WITHHELD_AMT_R           ,
							N_STATE_TAX_WITHHELD_AMT_R             ,
							N_EMPLOYEE_SS_WITHHELD_AMT_R           ,
							N_EMPLOYEE_MED_WITHHELD_AMT_R          ,
							N_EMPLOYER_SS_WITHHELD_AMT_R           ,
							N_EMPLOYER_MED_WITHHELD_AMT_R          ,
							N_LEGAL_EXPENSE_DIRECT_AMT_R           ,
							N_OTHER_EXPENSE_DIRECT_AMT_R           ,
							V_LOB_TYPE_R                           ,
							N_MODAL_AMOUNT_R                       ,
							N_PRIMARY_PAYEE_R                      ,
							N_ADJ_GROSS_BENEFIT_R                  ,
							N_PAY_AMOUNT_R                         ,
							N_CLAIM_SK_R                           ,
							V_GROSS_BENEFIT_CODE_R                 ,
							N_CLAIM_COVERAGE_SK_R                  ,
							N_CLAIM_COVERAGE_GROUP_SK_R            ,
							N_FBPR_N_SEQ_R                         ,
							V_PRIVACY_INDICATOR_R				   ,
							V_PAYEE_FIRST_NAME_R                   ,	
							V_PAYEE_MIDDLE_NAME_R                  ,	
							V_PAYEE_LAST_NAME_R					   ,	
							V_PAYEE_TYPE_R						   ,	
							N_PARTY_SK_R								
                            ,V_AMOUNT_TYPE_SUB_NAME_R
                            ,V_AMOUNT_TYPE_CATEGORY_R
                            ,V_AMOUNT_TYPE_CATEGORY_DESC_R
                            ,V_AMOUNT_TYPE_SUB_CATEGORY_R
                            ,V_AMT_TYPE_SUB_CATEGORY_DESC_R
                            ,V_AMOUNT_TYPE_CODE_R
                            ,V_AMOUNT_TYPE_NAME_R
                            ,V_AMOUNT_TYPE_SUB_CODE_R
				)
				SELECT
		DGCDR.v_claim_number_r                                                                                       V_CLAIM_NUMBER_R
		,NVL(DGCCGR.V_CLAIM_COVERAGE_CODE_R,DGCCR.V_CLAIM_COVERAGE_CODE_R)                                           V_COVERAGE_CODE_R
		,DGCCGR.N_COV_GRP_ID_R                                                                                       V_COV_GROUP_ID_R 
		,FBPR.V_CHECK_NUM_R                                                                                          V_CHECK_NUMBER_R
		,FBPR.V_PAY_METHOD_R                                                                                         V_PAY_METHOD_R
		,FBPDR.V_AMOUNT_TYPE_SUB_CODE_R                                                                              V_BENEFIT_CODE_R
		,FBPDR.V_AMOUNT_TYPE_NAME_R                                                                                  V_BENEFIT_DESCRIPTION_R
		,FBPDR.V_AMOUNT_TYPE_CODE_R                                                                                  V_BENEFIT_GROUP_R
		,( CASE WHEN FBPDR.V_BENEFIT_CODE_R IN ('098','FIC','298','MED')
		THEN NVL(FBPR.N_MED_WAGE_BASE_R,0) + NVL(FBPR.N_SS_WAGE_BASE_R,0)
		ELSE 0
		END
		)                                                                                                            N_GROSS_WAGE_BASE_R
		,CASE WHEN DGCDR.V_CLAIM_NUMBER_R LIKE '%SC%' 
			THEN (100-FGW.N_EXCLUSION_RATIO_R)
		ELSE FGW.N_TAXABLE_OVERRIDE_PCT_R    
		END AS N_TAXABLE_PERCENT_R 
		,DECODE(UPPER(TRIM(FBPR.V_PAY_STATUS_R)),'REVERSAL','VOID','PAID')                                           V_PAYMENT_STATUS_R
		,FBPDR.N_AMOUNT_R                                                                                            N_PAID_AMOUNT_R
		,(CASE WHEN (UPPER(TRIM(DGCDR.V_LOB_TYPE_R)) IN ('LIFE','WOP') AND UPPER(TRIM(FBPR.V_PAY_METHOD_R)) = 'RAA')
		THEN 'FIN'
		ELSE 'PAY'
		END)                                                                                                         V_PAYMENT_TYPE_R
		,FBPR.D_DISB_DATE_R                                                                                          D_CHECK_DATE_R
		,DECODE(UPPER(TRIM(FBPR.V_PAY_METHOD_R)),'ACH','ACH','BP')                                                   V_CHECK_TYPE_R
		,FBPR.D_TRANS_DATE_R                                                                                         D_PAID_DATE_R   
		,cast(NULL   as Number)                                                                                                     N_GROSS_AMOUNT_R
		,FBPR.D_SERVICE_PERIOD_START_R                                                                               D_SERVICE_PERIOD_FROM_R
		,FBPR.D_SERVICE_PERIOD_END_R                                                                                 D_SERVICE_PERIOD_TO_R
		,FBPDR.V_OFFSET_TYPE_R
        ,'Benefit Payment'
		,FBPR.N_WORKSHEET_SEQ_NBR_OBJECTNM_R                                                                         N_WORKSHEET_OBJECT_NUM_R
		,FBPR.N_PAY_SCHD_SOURCE_SYSTEM_KEY_R                                                                         N_SOURCE_SYSTEM_KEY_R
		,FBPR.N_SOURCE_VERSION_SEQ_NUMBER_R                                                                          N_SOURCE_VERSION_SEQ_NUMBER_R
		,FBPR.N_SEQ_R                                                                                                N_SEQ_R
		,FBPR.N_GROUP_SEQ_R                                                                                          N_GROUP_SEQ_R
		,FBPR.N_PARENT_OBJECTNUM_R                                                                                   N_PARENT_OBJECTNUM_R
        ,systimestamp                                                                                             T_CREATION_DATE_R
        ,systimestamp                                                                                             T_EVENT_TIMESTAMP_R
        ,systimestamp                                                                                             T_LAST_MODIFIED_DATE_R
        ,'ODI'                                                                                                       V_CREATED_BY_R
        ,'ODI'                                                                                                       V_LAST_MODIFIED_BY_R
		,FBPR.FIC_MIS_DATE_R
		,FBPR.N_BATCH_ID_R
        ,1                     N_LOAD_RUN_ID_R
        ,(NVL(FBPDR.N_SEQUENCE_NUMBER_R,0)+ROWNUM)     N_SEQUENCE_NUMBER_R
		,FBPDR.V_AMOUNT_TYPE_CATEGORY_DESC_R                                                                         V_BENEFIT_CATEGORY_R
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
		,DGCDR.V_LOB_TYPE_R         
		,  FGW.N_MODAL_AMOUNT_R       
		, FBPR.N_PRIMARY_PAYEE_R     
		, FBPR.N_ADJ_GROSS_BENEFIT_R 
		, FBPR.N_PAY_AMOUNT_R        
		, FBPR.N_CLAIM_SK_R          
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
            CASE WHEN DGCCR.V_CLAIM_COVERAGE_CODE_R = 'SC' AND upper(DGCCR.V_COVERAGE_CODE_R) in ('J'||CHR(38)||'S',  'LIFE',  'LIFE W/PC') THEN '031'
            ELSE '032'
            END
        END
        WHEN DGCDR.V_LOB_TYPE_R IN ( 'WOP', 'LIFE') THEN DGCCGR.V_BENEFIT_CODE_R
        WHEN DGCDR.V_LOB_TYPE_R IN ( 'LTD', 'STD', 'VPL', 'VPS' ) THEN '081'
        END
        ) V_GROSS_BENEFIT_CODE_R
		,FBPR.N_CLAIM_COVERAGE_SK_R                  
		,FBPR.N_CLAIM_COVERAGE_GROUP_SK_R            
    ,fbpdr.n_seq_r                         N_FBPR_N_SEQ_R 
    ,FBPDR.v_privacy_indicator_r
	,FBPDR.V_PAYEE_FIRST_NAME_R	
	,FBPDR.V_PAYEE_MIDDLE_NAME_R	
	,FBPDR.V_PAYEE_LAST_NAME_R	
	,FBPDR.V_PAYEE_TYPE_R	
	,FBPDR.N_PARTY_SK_R  
    ,FBPDR.V_AMOUNT_TYPE_SUB_NAME_R
    ,FBPDR.V_AMOUNT_TYPE_CATEGORY_R
    ,FBPDR.V_AMOUNT_TYPE_CATEGORY_DESC_R
    ,FBPDR.V_AMOUNT_TYPE_SUB_CATEGORY_R
    ,FBPDR.V_AMT_TYPE_SUB_CATEGORY_DESC_R
    ,FBPDR.V_AMOUNT_TYPE_CODE_R
    ,FBPDR.V_AMOUNT_TYPE_NAME_R
    ,FBPDR.V_AMOUNT_TYPE_SUB_CODE_R
		FROM FCT_BENEFIT_PAYMENT_R FBPR
			,DIM_GRP_CLAIM_DIR_R DGCDR
			,FCT_GRP_WORKSHEET FGW
			,FCT_CLAIM_PAYMENT_DETAIL_OFFSETS_R FBPDR
			,DIM_GRP_CLAIM_COVERAGE_GROUP_R DGCCGR
			,DIM_GRP_CLAIM_COVERAGE_R DGCCR
		WHERE  UPPER(TRIM(FBPR.V_PAY_STATUS_R)) IN ('RELEASED','REVERSAL','REVERSED')
		AND FBPR.N_CLAIM_SK_R = DGCDR.N_CLAIM_SK_R
        and FBPR.N_CLAIM_COVERAGE_SK_R = DGCCR.N_CLAIM_COVERAGE_SK_R(+)
        and FBPR.N_CLAIM_COVERAGE_GROUP_SK_R = DGCCGR.N_CLAIM_COVERAGE_GROUP_SK_R(+)
		AND FGW.N_WORKSHEET_SEQ_NBR_OBJECTNM_R = FBPR.N_PARENT_OBJECTNUM_R
		AND FGW.N_SOURCE_SYSTEM_KEY_R = FBPR.N_PAY_SCHD_SOURCE_SYSTEM_KEY_R
		AND FBPR.N_SOURCE_VERSION_SEQ_NUMBER_R = FBPDR.N_SOURCE_VERSION_SEQ_NUMBER_R(+)  
		AND FBPR.N_SEQ_R = FBPDR.N_GROUP_SEQ_R(+)
		AND FBPR.N_PAY_SCHD_SOURCE_SYSTEM_KEY_R = FBPDR.N_PAY_DTL_SOURCE_SYSTEM_KEY_R(+)
		AND DGCDR.V_ACTIVE_STATUS_R         = 'Y'
        and nvl(DGCCGR.V_ACTIVE_STATUS_R,'Y') = 'Y'
        AND NVL(DGCCR.V_ACTIVE_STATUS_R, 'Y')  = 'Y'
		AND UPPER(TRIM(FBPDR.V_BENEFIT_DESC_R)) <> 'PAYMENT TO SECONDARY PAYEE' 
      AND NVL(FBPR.V_SOURCE_SYSTEM_NAME_R,'X@')='PACS';