-- Cleaned for lineage: VW_FCT_CLAIM_PAYMENT_DETAIL_R_MV_SSL_INC

CREATE MATERIALIZED VIEW VW_FCT_CLAIM_PAYMENT_DETAIL_R_MV_SSL_INC AS
SELECT
    a.N_CLAIM_SK_R,
    a.N_CLAIM_COVERAGE_SK_R,	
    case when sign(a.N_CLAIM_COVERAGE_GROUP_SK_R)=-1 
		then NVL(d.n_claim_coverage_group_sk_r, a.n_claim_coverage_group_sk_r)
		else E.n_claim_coverage_group_sk_r
    end 
        as N_CLAIM_COVERAGE_GROUP_SK_R,
    a.V_CLAIM_NUMBER_R,
    a.V_COVERAGE_CODE_R,
    a.V_COV_GROUP_ID_R,
    a.V_CHECK_NUMBER_R,
    a.V_PAY_METHOD_R,
    a.V_BENEFIT_CODE_R,
    a.V_BENEFIT_DESCRIPTION_R,
    a.V_BENEFIT_GROUP_R,
    a.N_GROSS_WAGE_BASE_R,
    a.N_TAXABLE_PERCENT_R,
    a.V_PAYMENT_STATUS_R,
    a.N_PAID_AMOUNT_R,
    a.V_PAYMENT_TYPE_R,
    a.D_CHECK_DATE_R,
    a.V_CHECK_TYPE_R,
    a.D_PAID_DATE_R,
    a.N_GROSS_AMOUNT_R,
    a.D_SERVICE_PERIOD_FROM_R,
    a.D_SERVICE_PERIOD_TO_R,
    a.V_RECORD_TYPE_R,
    a.N_WORKSHEET_OBJECT_NUM_R,
    a.N_SOURCE_SYSTEM_KEY_R,
    a.N_SOURCE_VERSION_SEQ_NUMBER_R,
    a.N_SEQ_R,
    a.N_GROUP_SEQ_R,
    a.N_PARENT_OBJECTNUM_R,
    a.N_LOAD_RUN_ID_R,
    a.T_EVENT_TIMESTAMP_R,
    a.FIC_MIS_DATE_R,
    a.N_BATCH_ID_R,
    a.N_SEQUENCE_NUMBER_R,
    a.T_CREATION_DATE_R,
    a.T_LAST_MODIFIED_DATE_R,
    a.V_CREATED_BY_R,
    a.V_LAST_MODIFIED_BY_R,
    a.V_BENEFIT_CATEGORY_R,
    a.N_PAID_CLAIM_BENEFITS_R,
    a.N_TAXABLE_BENEFIT_AMT_R,
    a.N_FEDERAL_TAX_WITHHELD_AMT_R,
    a.N_STATE_TAX_WITHHELD_AMT_R,
    a.N_EMPLOYEE_SS_WITHHELD_AMT_R,
    a.N_EMPLOYEE_MED_WITHHELD_AMT_R,
    a.N_EMPLOYER_SS_WITHHELD_AMT_R,
    a.N_EMPLOYER_MED_WITHHELD_AMT_R,
    a.N_LEGAL_EXPENSE_DIRECT_AMT_R,
    a.N_OTHER_EXPENSE_DIRECT_AMT_R,
    a.V_LOB_TYPE_R,
    a.N_MODAL_AMOUNT_R,
    a.N_PRIMARY_PAYEE_R,
    a.N_ADJ_GROSS_BENEFIT_R,
    a.N_PAY_AMOUNT_R,
    b.V_PRIVACY_INDICATOR_R,
    a.V_GROSS_BENEFIT_CODE_R,
    a.N_SS_WAGE_BASE_R,
    a.N_MED_WAGE_BASE_R,
    a.ROW_NUM_PAYMENT_SK AS N_PAYMENT_SK_R ,
    a.V_PAYEE_FIRST_NAME_R ,
    a.V_PAYEE_MIDDLE_NAME_R ,
    a.V_PAYEE_LAST_NAME_R ,
    a.V_PAYEE_TYPE_R ,
    a.V_PRIMARY_REINSURER_R ,
    a.V_SECONDARY_REINSURER_R ,
    a.V_TERNARY_REINSURER_R ,
    a.N_PRIMARY_REINSURER_REINS_SHARE_PCT_R ,
    a.N_SECONDARY_REINSURER_REINS_SHARE_PCT_R ,
    a.N_TERNARY_REINSURER_REINS_SHARE_PCT_R ,
    a.N_PRIMARY_REINSURER_REINSURANCE_PCT_R ,
    a.N_SECONDARY_REINSURER_REINSURANCE_PCT_R ,
    a.N_TERNARY_REINSURER_REINSURANCE_PCT_R ,
    a.N_TOTAL_REINSURANCE_PCT_R ,
    a.V_PAYMENT_RECORD_TYPE_R ,
    a.V_TAX_STATE_R ,
    a.N_PAYEE_PARTY_SK_R ,
    b.V_SOURCE_SYSTEM_NAME_R
     ,a.V_AMOUNT_TYPE_SUB_NAME_R
     ,a.V_AMOUNT_TYPE_CATEGORY_R
     ,a.V_AMOUNT_TYPE_CATEGORY_DESC_R
     ,a.V_AMOUNT_TYPE_SUB_CATEGORY_R
     ,a.V_AMT_TYPE_SUB_CATEGORY_DESC_R
     ,a.V_AMOUNT_TYPE_CODE_R
     ,a.V_AMOUNT_TYPE_NAME_R
     ,a.V_AMOUNT_TYPE_SUB_CODE_R
    ,    (CASE  
			WHEN  UPPER(a.V_RECORD_TYPE_R) = 'REDIRECT' 
				THEN NVL(a.n_paid_amount_r, 0)
			WHEN a.v_check_type_r <> 'OE' AND a.v_benefit_group_r IN ('FIC', 'MED') AND  UPPER(a.V_RECORD_TYPE_R) = 'BENEFIT PAYMENT' 
				THEN  NVL(a.n_paid_claim_benefits_r, 0) * -(1)
			WHEN a.v_check_type_r <> 'OE' AND a.v_benefit_group_r IN ('FIC', 'MED') AND  UPPER(a.V_RECORD_TYPE_R) = 'ADJUSTMENT'
				THEN  NVL(n_paid_claim_benefits_r, 0)
			WHEN a.v_check_type_r <> 'OE' AND  a.v_benefit_group_r NOT IN ('FIC', 'MED') and a.V_BENEFIT_CODE_R not in ('013', '015')   AND a.v_benefit_code_r IS NOT NULL
				THEN NVL(a.n_paid_claim_benefits_r , a.n_paid_amount_r) 
			ELSE 0 
		   END
        ) as n_claim_paid_loss_amount_r
      ,a.V_HASH_KEY_R
	
      
    FROM (
            select A.*,ROWNUM ROW_NUM_PAYMENT_SK from ATOMIC.FCT_CLAIM_PAYMENT_DETAIL_R_MV_SSL A 
            WHERE   (sign(A.N_CLAIM_COVERAGE_GROUP_SK_R)=-1 
            or      sign(A.N_CLAIM_COVERAGE_GROUP_SK_R)=1) 
           
            
        ) a
	
    INNER JOIN ATOMIC.dim_grp_claim_dir_r b
		ON a.n_claim_sk_r= b.n_claim_sk_r 
		AND B.V_ACTIVE_STATUS_R = 'Y'
		
    LEFT JOIN
		  (
			SELECT 
				MAX(N_CLAIM_COVERAGE_GROUP_SK_R) N_CLAIM_COVERAGE_GROUP_SK_R, 
				N_CLAIM_COVERAGE_SK_R
			FROM ATOMIC.dim_grp_claim_coverage_group_r
			WHERE v_active_status_r = 'Y'
			GROUP BY n_claim_coverage_sk_r
		  ) D
		ON a.n_claim_coverage_sk_r = d.n_claim_coverage_sk_r 
		and sign(a.N_CLAIM_COVERAGE_GROUP_SK_R)=-1
		
	LEFT JOIN ATOMIC.dim_grp_claim_coverage_group_r E 
		ON a.n_claim_coverage_group_sk_r = E.n_claim_coverage_group_sk_r 
		AND E.v_active_status_r = 'Y' 
		and sign(a.N_CLAIM_COVERAGE_GROUP_SK_R)=1;