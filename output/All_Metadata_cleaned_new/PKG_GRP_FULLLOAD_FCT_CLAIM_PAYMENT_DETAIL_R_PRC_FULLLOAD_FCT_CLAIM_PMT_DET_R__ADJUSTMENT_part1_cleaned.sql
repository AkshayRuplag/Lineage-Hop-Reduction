-- Source-concept branch: ADJUSTMENT (part 1/1)

-- Cleaned for lineage: ADJUSTMENT

INSERT    INTO ATOMIC.FCT_CLAIM_PAYMENT_DETAIL_ADJUSTMENT_R
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
		 ,N_PAID_CLAIM_BENEFITS_R   
		,N_CLAIM_SK_R                           
		,N_CLAIM_COVERAGE_SK_R                  
		,N_CLAIM_COVERAGE_GROUP_SK_R            
		,V_PAYEE_FIRST_NAME_R
        ,V_PAYEE_MIDDLE_NAME_R
        ,V_PAYEE_LAST_NAME_R
		,V_PAYEE_TYPE_R
		 ,N_PARTY_SK_R							
        ,V_AMOUNT_TYPE_SUB_NAME_R,
        V_AMOUNT_TYPE_CATEGORY_R,
        V_AMOUNT_TYPE_CATEGORY_DESC_R,
        V_AMOUNT_TYPE_SUB_CATEGORY_R,
        V_AMT_TYPE_SUB_CATEGORY_DESC_R,
        V_AMOUNT_TYPE_CODE_R,
        V_AMOUNT_TYPE_NAME_R,
        V_AMOUNT_TYPE_SUB_CODE_R,
		n_adj_trans_amount_r
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
		,V_BENEFIT_CATEGORY_R
		,N_PAID_CLAIM_BENEFITS_R                
		,N_CLAIM_SK_R                           
		,N_CLAIM_COVERAGE_SK_R                  
		,N_CLAIM_COVERAGE_GROUP_SK_R            
		,V_PAYEE_FIRST_NAME_R
        ,V_PAYEE_MIDDLE_NAME_R
        ,V_PAYEE_LAST_NAME_R
		,V_PAYEE_TYPE_R
		,N_PARTY_SK_R							
        ,V_AMOUNT_TYPE_SUB_NAME_R,
        V_AMOUNT_TYPE_CATEGORY_R,
        V_AMOUNT_TYPE_CATEGORY_DESC_R,
        V_AMOUNT_TYPE_SUB_CATEGORY_R,
        V_AMT_TYPE_SUB_CATEGORY_DESC_R,
        V_AMOUNT_TYPE_CODE_R,
        V_AMOUNT_TYPE_NAME_R,
        V_AMOUNT_TYPE_SUB_CODE_R,
		n_adj_trans_amount_r
		FROM
		(
		SELECT 
		DIM_GRP_CLAIM_DIR_R.V_CLAIM_NUMBER_R                          V_CLAIM_NUMBER_R
		,NVL(DIM_GRP_CLAIM_COVERAGE_GROUP_R.V_CLAIM_COVERAGE_CODE_R,DIM_GRP_CLAIM_COVERAGE_R.V_CLAIM_COVERAGE_CODE_R)   V_COVERAGE_CODE_R
		,DIM_GRP_CLAIM_COVERAGE_GROUP_R.N_COV_GRP_ID_R              V_COV_GROUP_ID_R
		,(case when UPPER((SUBSTR(FCT_CLAIM_ADJUSTMENT_R.V_ADJUSTMENT_DESC_R,1,9))) = 'APPLYCHQ#'
		THEN replace(trim(substr(substr(FCT_CLAIM_ADJUSTMENT_R.v_adjustment_desc_r,instr(FCT_CLAIM_ADJUSTMENT_R.v_adjustment_desc_r,'=')+1) ,1
					,instr(substr(FCT_CLAIM_ADJUSTMENT_R.v_adjustment_desc_r,instr(FCT_CLAIM_ADJUSTMENT_R.v_adjustment_desc_r,'=')) ,','))
					),',')
		when (UPPER(FCT_CLAIM_ADJUSTMENT_R.V_ADJUSTMENT_TYPE_R) like 'SSWAGEBASE%'
					OR UPPER(FCT_CLAIM_ADJUSTMENT_R.V_ADJUSTMENT_TYPE_R) LIKE 'MEDWAGEBASE%')
		THEN 'NONE'
		when (UPPER(SUBSTR(FCT_CLAIM_ADJUSTMENT_R. V_ADJUSTMENT_DESC_R,1,5)) = 'TRNFR'
        AND UPPER(FCT_CLAIM_ADJUSTMENT_R.V_ADJ_TRANSACTION_CODE_R) NOT LIKE 'GENERAL%')
        then 'XFER'
		else null
		end
		)                                                            V_CHECK_NUMBER_R
		,NULL                                                        V_PAY_METHOD_R
		,FCT_CLAIM_ADJUSTMENT_R.V_AMOUNT_TYPE_SUB_CODE_R             V_BENEFIT_CODE_R
		,FCT_CLAIM_ADJUSTMENT_R.V_AMOUNT_TYPE_NAME_R	             V_BENEFIT_DESCRIPTION_R
		,FCT_CLAIM_ADJUSTMENT_R.V_AMOUNT_TYPE_CODE_R	             V_BENEFIT_GROUP_R
        ,(CASE WHEN FCT_CLAIM_ADJUSTMENT_R.V_AMOUNT_TYPE_SUB_CODE_R LIKE 'W%' THEN FCT_CLAIM_ADJUSTMENT_R.n_adj_trans_amount_r
        WHEN FCT_CLAIM_ADJUSTMENT_R.V_AMOUNT_TYPE_SUB_CODE_R LIKE 'Z%' THEN FCT_CLAIM_ADJUSTMENT_R.n_adj_trans_amount_r
        ELSE 0 end)                                                  N_GROSS_WAGE_BASE_R
		,FGB.N_TAXABLE_PERCENT_R                                     N_TAXABLE_PERCENT_R
		,'R'                                                         V_PAYMENT_STATUS_R
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
		,'ADJ'                                                       V_PAYMENT_TYPE_R
		,FCT_CLAIM_ADJUSTMENT_R.d_adj_trans_date_r                   D_CHECK_DATE_R
		,'BP'                                                        V_CHECK_TYPE_R
		,FCT_CLAIM_ADJUSTMENT_R.d_adj_trans_date_r                   D_PAID_DATE_R
		,NULL                                                        N_GROSS_AMOUNT_R
		,FCT_CLAIM_ADJUSTMENT_R.d_adj_trans_date_r                   D_SERVICE_PERIOD_FROM_R	
		,FCT_CLAIM_ADJUSTMENT_R.d_adj_trans_date_r                   D_SERVICE_PERIOD_TO_R	  
		,'Adjustment'                                                V_RECORD_TYPE_R
		,NULL                                                        N_WORKSHEET_OBJECT_NUM_R
		,FCT_CLAIM_ADJUSTMENT_R.N_ADJ_SOURCE_SYSTEM_KEY_R            N_SOURCE_SYSTEM_KEY_R
		,FCT_CLAIM_ADJUSTMENT_R.N_SOURCE_VERSION_SEQ_NUMBER_R        N_SOURCE_VERSION_SEQ_NUMBER_R
		,NULL                                                        N_SEQ_R
		,NULL                                                        N_GROUP_SEQ_R
		,NULL                                                        N_PARENT_OBJECTNUM_R
		,FCT_CLAIM_ADJUSTMENT_R.V_AMOUNT_TYPE_CATEGORY_DESC_R        V_BENEFIT_CATEGORY_R
        ,(
          CASE
          WHEN fct_claim_adjustment_r.v_amount_type_sub_code_r LIKE 'W%' THEN
                        0
          WHEN fct_claim_adjustment_r.v_amount_type_sub_code_r LIKE 'Z%' THEN
                        0
          WHEN FCT_CLAIM_ADJUSTMENT_R.V_AMOUNT_TYPE_CODE_R IN  ('098', '097', '099', '297',  '298' ) THEN 0
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
		,FCT_CLAIM_ADJUSTMENT_R.N_CLAIM_SK_R                           
		,FCT_CLAIM_ADJUSTMENT_R.N_CLAIM_COVERAGE_SK_R                  
		,FCT_CLAIM_ADJUSTMENT_R.N_CLAIM_COVERAGE_GROUP_SK_R            
		,FCT_CLAIM_ADJUSTMENT_R.N_BATCH_ID_R
		,FCT_CLAIM_ADJUSTMENT_R.FIC_MIS_DATE_R
		,a.V_INDIVIDUAL_FIRST_NAME_R  V_PAYEE_FIRST_NAME_R
        ,a.V_INDIVIDUAL_MIDDLE_NAME_R V_PAYEE_MIDDLE_NAME_R
        ,a.V_INDIVIDUAL_LAST_NAME_R   V_PAYEE_LAST_NAME_R
		,(case  when a.V_PAYEE_TYPE_R = 'Agent' then ' UNK '
        when a.V_PAYEE_TYPE_R = 'Beneficiary' then 'UNK'
        when a.V_PAYEE_TYPE_R = 'Customer' then 'GRP'
        when a.V_PAYEE_TYPE_R = 'Insured' then 'IND'
        when a.V_PAYEE_TYPE_R = 'Vendor' then 'PRV' else a.V_PAYEE_TYPE_R end ) V_PAYEE_TYPE_R
		,a.N_INSRD_PARTY_SK_R as N_PARTY_SK_R 						
        ,FCT_CLAIM_ADJUSTMENT_R.V_AMOUNT_TYPE_SUB_NAME_R,
        FCT_CLAIM_ADJUSTMENT_R.V_AMOUNT_TYPE_CATEGORY_R,
        FCT_CLAIM_ADJUSTMENT_R.V_AMOUNT_TYPE_CATEGORY_DESC_R,
        FCT_CLAIM_ADJUSTMENT_R.V_AMOUNT_TYPE_SUB_CATEGORY_R,
        FCT_CLAIM_ADJUSTMENT_R.V_AMT_TYPE_SUB_CATEGORY_DESC_R,
        FCT_CLAIM_ADJUSTMENT_R.V_AMOUNT_TYPE_CODE_R,
        FCT_CLAIM_ADJUSTMENT_R.V_AMOUNT_TYPE_NAME_R,
        FCT_CLAIM_ADJUSTMENT_R.V_AMOUNT_TYPE_SUB_CODE_R,
		FCT_CLAIM_ADJUSTMENT_R.n_adj_trans_amount_r
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
            ELSE 'MANUAL' END) LIKE '%MANUAL%');