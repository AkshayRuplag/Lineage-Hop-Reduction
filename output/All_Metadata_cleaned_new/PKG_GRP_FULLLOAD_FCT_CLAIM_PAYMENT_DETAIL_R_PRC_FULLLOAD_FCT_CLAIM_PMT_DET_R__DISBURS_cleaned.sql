-- Cleaned for lineage: DISBURS

INSERT    INTO ATOMIC.FCT_CLAIM_PAYMENT_DETAIL_DISBURSEMENT_R
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
		 ,N_CLAIM_SK_R           
		 ,N_CLAIM_COVERAGE_SK_R  
		 ,N_CLAIM_COVERAGE_GROUP_SK_R  
		 ,v_payee_last_name_r
		 ,V_PAYEE_TYPE_R
		 ,N_PARTY_SK_R 
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
		,FIC_MIS_DATE_R                     
		,N_BATCH_ID_R                     	N_BATCH_ID_R 
		,LN_N_LOAD_RUN_ID_R                     N_LOAD_RUN_ID_R
		,(NVL(LN_MAX_SEQ_NUMER_R,0)+ROWNUM)     N_SEQUENCE_NUMBER_R
		,'REDIRECT'                             V_BENEFIT_CATEGORY_R
		,N_CLAIM_SK_R                           
		,N_CLAIM_COVERAGE_SK_R                  
		,N_CLAIM_COVERAGE_GROUP_SK_R  
		,v_payee_last_name_r                     
		,V_PAYEE_TYPE_R 
		,N_PARTY_SK_R 	
		FROM(
		SELECT 
		   DIM_GRP_CLAIM_DIR_R.V_CLAIM_NUMBER_R                                     V_CLAIM_NUMBER_R
		   ,DIM_GRP_CLAIM_COVERAGE_R.V_claim_COVERAGE_CODE_R                               V_COVERAGE_CODE_R
		   ,NULL                                                                     V_COV_GROUP_ID_R
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
		   ,FCT_GRP_REDIRECT_PAYMENT_R.N_AMOUNT_R                              N_PAID_AMOUNT_R
		   ,'RED'                                                                    V_PAYMENT_TYPE_R
		   ,NVL(FCT_GRP_REDIRECT_PAYMENT_R.D_DISBURSE_DATE_R,FCT_GRP_REDIRECT_PAYMENT_R.D_DISB_DATE_R) D_CHECK_DATE_R
		   ,DECODE(FCT_GRP_REDIRECT_PAYMENT_R.V_PAY_METHOD_R,'ACH','ACH','BP')         V_CHECK_TYPE_R
           ,(CASE WHEN D_REVERSE_DATE_R is not null THEN
		       D_PAY_DATE_R
		     ELSE DECODE(FCT_GRP_REDIRECT_PAYMENT_R.V_PAY_SCHEDULE_PAYEE_DESC_R,'REVERSED'
                                                                               ,FCT_GRP_REDIRECT_PAYMENT_R.D_REVERSE_DATE_R
                                                                               ,FCT_GRP_REDIRECT_PAYMENT_R.D_DISB_DATE_R)
			END) D_PAID_DATE_R
		   ,NULL                                                                     N_GROSS_AMOUNT_R
		   ,FCT_GRP_REDIRECT_PAYMENT_R.D_SERVICE_PERIOD_START_R                        D_SERVICE_PERIOD_FROM_R
		   ,FCT_GRP_REDIRECT_PAYMENT_R.D_SERVICE_PERIOD_END_R	                         D_SERVICE_PERIOD_TO_R
		   ,'Redirect'                                                               V_RECORD_TYPE_R
		   ,NULL                                                                     N_WORKSHEET_OBJECT_NUM_R
		   ,FCT_GRP_REDIRECT_PAYMENT_R.N_PAY_SCHDL_PAYEE_SRCSYS_KEY_R                      N_SOURCE_SYSTEM_KEY_R
		   ,FCT_GRP_REDIRECT_PAYMENT_R.N_OBJECT_NUM_R	                             N_SOURCE_VERSION_SEQ_NUMBER_R
		   ,FCT_GRP_REDIRECT_PAYMENT_R.N_EXT_SUB_SEQUENCE_R                            N_SEQ_R    
		   ,NULL                                                                     N_GROUP_SEQ_R
		   ,NULL                                                                     N_PARENT_OBJECTNUM_R
           ,FCT_GRP_REDIRECT_PAYMENT_R.N_CLAIM_SK_R		                             N_CLAIM_SK_R 
           ,DIM_GRP_CLAIM_COVERAGE_R.N_CLAIM_COVERAGE_SK_R		                     N_CLAIM_COVERAGE_SK_R 
		   ,FCT_GRP_REDIRECT_PAYMENT_R.N_BATCH_ID_R                
		   ,FCT_GRP_REDIRECT_PAYMENT_R.FIC_MIS_DATE_R                
		   ,-1 N_CLAIM_COVERAGE_GROUP_SK_R  
		   ,FCT_GRP_REDIRECT_PAYMENT_R.V_PAYEE_NAME_R v_payee_last_name_r
		   ,'GRP'                                   V_PAYEE_TYPE_R 
		   ,FCT_GRP_REDIRECT_PAYMENT_R.n_payee_party_sk_r  N_PARTY_SK_R 		
		FROM ATOMIC.FCT_GRP_REDIRECT_PAYMENT_R
			,ATOMIC.DIM_GRP_CLAIM_DIR_R
			,ATOMIC.DIM_GRP_CLAIM_COVERAGE_R
		WHERE
		   FCT_GRP_REDIRECT_PAYMENT_R.N_CLAIM_SK_R = DIM_GRP_CLAIM_DIR_R.N_CLAIM_SK_R
		   and FCT_GRP_REDIRECT_PAYMENT_R.N_CLAIM_SK_R = DIM_GRP_CLAIM_COVERAGE_R.N_CLAIM_SK_R
		   and DIM_GRP_CLAIM_COVERAGE_R.N_CLAIM_COVERAGE_SK_R in (select max(d2.N_CLAIM_COVERAGE_SK_R)
		                                                            from atomic.DIM_GRP_CLAIM_COVERAGE_R D2
		                                                           WHERE D2.N_CLAIM_SK_R =DIM_GRP_CLAIM_COVERAGE_R.N_CLAIM_SK_R
																   AND nvl(d2.V_ACTIVE_STATUS_R, 'Y') = 'Y'
		                                                          )
           AND DIM_GRP_CLAIM_DIR_R.V_ACTIVE_STATUS_R = 'Y'                         
           AND nvl(DIM_GRP_CLAIM_COVERAGE_R.V_ACTIVE_STATUS_R, 'Y') = 'Y'		   
		);