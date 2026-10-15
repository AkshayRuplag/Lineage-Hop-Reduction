-- Cleaned for lineage: PROC_REFRESH_GRP_M_VIEW_TBLS__F_POLICY_SPECIFIC_MV (part 2/3)

INSERT 
			INTO F_POLICY_SPECIFIC_MV_TBL
			  (
				POLICY_SKEY                                                   ,
              CLAIM_SKEY                                                    ,
              ADMINISTERED_BY                                               ,
              AS_OF_DATE                                                    ,
              POLICY_PREFIX                                                 ,
              POLICY_SUFFIX                                                 ,
              WORKSHEET_END_DATE                                            ,
              WORKSHEET_START_DATE                                          ,
              CLAIM_CLOSED_DATE                                             ,
              CLAIM_GROSS_BENEFIT_AMOUNT                                    ,
              CLAIM_MOST_RECENT_ACTIVITY_DATE                               ,
              CLAIM_NET_BENEFIT_AMOUNT                                      ,
              CLAIM_NUMBER                                                  ,
              CLAIM_RECEIVED_DATE                                           ,
              CLAIM_TAXABLE_BENEFIT_PERCENTAGE                              ,
              DURATION_INDICATOR                                            ,
              DURATION_PERIOD                                               ,
              ELLIMINATION_PERIOD                                           ,
              LOSS_DATE                                                     ,
              OCCUPATION_CODE                                               ,
              OCCUPATION_DECRIPTION                                         ,
              PLAN_DURATION_DATE                                            ,
              MODIFIED_RTW_DATE                                             ,
              RETURN_TO_WORK_DATE                                           ,
              CLAIM_CLASS_ID                                                ,
              DISABILITY_START_DATE                                         ,
              COVERAGE_TYPE                                                 ,
              PRODUCT_COVERAGE_CODE                                         ,
              COVERAGE_TYPE_CODE                                            ,
              COVERAGE_TYPE_DESCRIPTION                                     ,
              EXAMINER_DEPARTMENT_CODE                                      ,
              EXAMINER_LOGIN_ID                                             ,
              EXAMINER_NAME                                                 ,
              VOCATIONAL_REHAB_ACTIVE_STATUS                                ,
              VOCATIONAL_REHAB_OUTCOME                                      ,
              VOCATIONAL_REHAB_SERVICE_REQUESTED_OTHER                      ,
              VOCATIONAL_REHAB_SERVICE_REQUESTED                            ,
              CLAIM_IDENTIFER                                               ,
              ANY_OCC_DECISION_MADE_DATE                                    ,
              ANY_OCC_PERIOD_INDICATOR                                      ,
              OWN_OCC_PERIOD                                                ,
              ANY_OCC_START_DATE                                            ,
              CLAIM_COVERAGE_DESCRIPTION                                    ,
              COVERAGE_GROUP_CODE                                           ,
              CLAIM_STATUS_CATEGORY                                         ,
              CLAIM_STATUS_DESCRIPTION                                      ,
              CLAIM_STATUS_EFFECTIVE_DATE                                   ,
              CLAIM_TYPE                                                    ,
              CLAIM_STATUS_CODE                                             ,
              PRIOR_STATUS_CODE                                             ,
              CLAIMANT_NAME                                                 ,
              CLAIMANT_GENDER                                               ,
              CLAIMANT_DOB                                                  ,
              CLAIMANT_AGE                                                  ,
              CLAIMANT_HIERDATE                                             ,
              CLAIM_COMPANY_NAME                                            ,
              CLAIM_COMPANY_CODE                                            ,
              LOCATION_NAME                                                 ,
              LOCATION_NUMBER                                               ,
              LOCATION_ID                                                   ,
              SITUS_STATE                                                   ,
              INSURED_STATE                                                 ,
              CLAIMANT_ADDRESS1                                             ,
              CLAIMANT_ADDRESS2                                             ,
              CLAIMANT_ADDRESS3                                             ,
              CLAIMANT_CITY                                                 ,
              CLAIMANT_ZIPCODE                                              ,
              CERTIFICATE_NUMBER                                            ,
              CLAIMANT_SALARY                                               ,
              CLAIMANT_SALARY_INDICATOR                                     ,
              ANN_PREMIUM_CYCLE_DATE                                        ,
              PRIMARY_DIAGNOSIS_CODE                                        ,
              PRIMARY_DIAGNOSIS_CODE_DESCRIPTION                            ,
              PRIMARY_DIAGNOSIS_CATEGORY_DESCRIPTION                        ,
              PRIMARY_DIAGNOSIS_CATEGORY                                    ,
              ADDITIONAL_DIAGNOSIS_CODE_DESCRIPTION                         ,
              ADDITIONAL_DIAGNOSIS_CODE                                     ,
              ADDITIONAL_DIAGNOSIS_CATEGORY_DESCRIPTION                     ,
              ADDITIONAL_DIAGNOSIS_CATEGORY                                 ,
              REHABILITATION_OFFSET_AMOUNT_088                              ,
              WORKERS_COMPENSATION_OFFSET_AMOUNT_083                        ,
              OTHER_OFFSET_AMOUNTS                                          ,
              REHABILITATION_OFFSET_INDICATOR_088                           ,
              WORK_INCENTIVE_EXCESS_OFFSET_INDICATOR_188                    ,
              CLAIM_AGE                                                     ,
              CLAIM_COUNT                                                   ,
              SOCIAL_SECURITY_PRIMARY_AWARD_AMOUNT                          ,
              SOCIAL_SECURITY_PRIMARY_AWARD_STATUS                          ,
              SOCIAL_SECURITY_PRIMARY_AWARD_TYPE                            ,
              SOCIAL_SECURITY_PRIMARY_AWARD_EFFECTIVE_DATE                  ,
              SOCIAL_SECURITY_PRIMARY_AWARD_TERMINATION_DATE                ,
              SOCIAL_SECURITY_DEPENDENT_AWARD_AMOUNT                        ,
              SOCIAL_SECURITY_DEPENDENT_AWARD_STATUS                        ,
              SOCIAL_SECURITY_DEPENDENT_AWARD_TYPE                          ,
              SOCIAL_SECURITY_DEPENDENT_AWARD_EFFECTIVE_DATE                ,
              SOCIAL_SECURITY_DEPENDENT_AWARD_TERMINATION_DATE              ,
              ACH_INDICATOR                                                 ,
              MOST_RECENT_SERVICE_PERIOD_FROM_DATE                          ,
              MOST_RECENT_SERVICE_PERIOD_TO_DATE                            ,
              EARLIEST_BENEFIT_PAYMENT_DATE                                 ,
              LAST_BENEFIT_PAYMENT_DATE                                     ,
              CLAIM_TOTAL_PAID_NET_AMOUNT                                   ,
              CLAIM_TOTAL_PAID_TAXABLE_AMOUNT                               ,
              CLAIM_TOTAL_PAID_LOSS_AMOUNT                                  ,
              CLAIM_TOTAL_PAID_GROSS_AMT                                    ,
              CLAIM_MODAL_AMOUNT                                            ,
              D_LAST_IN_STATUS_46_DATE_R                                    ,
              PRIVACY_INDICATOR
			  ,DIRECTOR_FULL_NAME
			  ,SUPERVISOR_FULL_NAME
			  ,DIRECTOR_LOGIN_ID
			  ,SUPERVISOR_LOGIN_ID
			  ,NURSE_CERT_END_DATE
			  ,NURSE_CERT_FLAG
			  ,TIER_CREATED_DATE
			  ,TIER
			  ,CURRENT_RESERVE 
			  ,Policy_effective_date 
			  ,N_PRODUCT_SK_R             
              ,V_BASIC_PRODUCT_LINE_CODE_R
              ,V_BASIC_PRODUCT_LINE_DESC_R
			  ,CLIENT_NAME 
			  ,v_distribution_channel_r 
			  )
			SELECT
          DISTINCT F_PSR_CLAIM_MV_1.POLICY_SKEY POLICY_SKEY,
          F_PSR_CLAIM_MV_1.Claim_Skey AS Claim_Skey,
          F_PSR_CLAIM_MV_1.Administered_By,
          F_PSR_CLAIM_MV_1.AS_OF_DATE,
          F_PSR_CLAIM_MV_1.POLICY_PREFIX,
          F_PSR_CLAIM_MV_1.POLICY_SUFFIX,
          F_PSR_CLAIM_MV_1.WORKSHEET_END_DATE WORKSHEET_END_DATE,
          F_PSR_CLAIM_MV_1.WORKSHEET_START_DATE WORKSHEET_START_DATE,
          F_PSR_CLAIM_MV_1.CLAIM_CLOSED_DATE,
          F_PSR_CLAIM_MV_1.CLAIM_GROSS_BENEFIT_AMOUNT,
          F_PSR_CLAIM_MV_1.CLAIM_MOST_RECENT_ACTIVITY_DATE ,
          F_PSR_CLAIM_MV_1.CLAIM_NET_BENEFIT_AMOUNT,
          F_PSR_CLAIM_MV_1.CLAIM_NUMBER,
          F_PSR_CLAIM_MV_1.CLAIM_RECEIVED_DATE,
          F_PSR_CLAIM_MV_1.CLAIM_TAXABLE_BENEFIT_PERCENTAGE ,
          F_PSR_CLAIM_MV_1.DURATION_INDICATOR,
          F_PSR_CLAIM_MV_1.DURATION_PERIOD,
          F_PSR_CLAIM_MV_1.ELLIMINATION_PERIOD,
          F_PSR_CLAIM_MV_1.LOSS_DATE,
          F_PSR_CLAIM_MV_1.OCCUPATION_CODE,
          F_PSR_CLAIM_MV_1.OCCUPATION_DECRIPTION,
          F_PSR_CLAIM_MV_1.PLAN_DURATION_DATE,
          F_PSR_CLAIM_MV_1.MODIFIED_RTW_DATE,
          F_PSR_CLAIM_MV_1.RETURN_TO_WORK_DATE,
          F_PSR_CLAIM_MV_1.CLAIM_CLASS_ID ,
          F_PSR_CLAIM_MV_1.DISABILITY_START_DATE ,
          F_PSR_CLAIM_MV_2.COVERAGE_TYPE ,
          F_PSR_CLAIM_MV_2.PRODUCT_COVERAGE_CODE ,
          F_PSR_CLAIM_MV_2.COVERAGE_TYPE_CODE ,
          F_PSR_CLAIM_MV_2.COVERAGE_TYPE_DESCRIPTION ,
          F_PSR_CLAIM_MV_2.EXAMINER_DEPARTMENT_CODE ,
          F_PSR_CLAIM_MV_2.EXAMINER_LOGIN_ID ,
          F_PSR_CLAIM_MV_2.EXAMINER_NAME ,
          F_PSR_CLAIM_MV_2.VOCATIONAL_REHAB_ACTIVE_STATUS ,
          F_PSR_CLAIM_MV_2.VOCATIONAL_REHAB_OUTCOME ,
          F_PSR_CLAIM_MV_2.VOCATIONAL_REHAB_SERVICE_REQUESTED_OTHER ,
          F_PSR_CLAIM_MV_2.VOCATIONAL_REHAB_SERVICE_REQUESTED ,
          F_PSR_CLAIM_MV_2.CLAIM_IDENTIFER ,
          F_PSR_CLAIM_MV_2.ANY_OCC_DECISION_MADE_DATE ,
          F_PSR_CLAIM_MV_2.ANY_OCC_PERIOD_INDICATOR ,
          F_PSR_CLAIM_MV_2.OWN_OCC_PERIOD ,
          F_PSR_CLAIM_MV_2.ANY_OCC_START_DATE ,
          F_PSR_CLAIM_MV_2.CLAIM_COVERAGE_DESCRIPTION ,
          F_PSR_CLAIM_MV_2.COVERAGE_GROUP_CODE ,
          F_PSR_CLAIM_MV_2.CLAIM_STATUS_CATEGORY ,
          F_PSR_CLAIM_MV_2.CLAIM_STATUS_DESCRIPTION ,
          F_PSR_CLAIM_MV_2.CLAIM_STATUS_EFFECTIVE_DATE ,
          F_PSR_CLAIM_MV_2.CLAIM_TYPE ,
          F_PSR_CLAIM_MV_2.CLAIM_STATUS_CODE ,
          F_PSR_CLAIM_MV_2.PRIOR_STATUS_CODE ,
          F_PSR_CLAIM_MV_2.CLAIMANT_NAME ,
          F_PSR_CLAIM_MV_2.CLAIMANT_GENDER ,
          F_PSR_CLAIM_MV_2.CLAIMANT_DOB ,
          F_PSR_CLAIM_MV_2.CLAIMANT_AGE ,
          F_PSR_CLAIM_MV_2.CLAIMANT_HIERDATE ,
          F_PSR_CLAIM_MV_2.CLAIM_COMPANY_NAME ,
          F_PSR_CLAIM_MV_2.CLAIM_COMPANY_CODE ,
          F_PSR_CLAIM_MV_2.LOCATION_NAME ,
          F_PSR_CLAIM_MV_2.LOCATION_NUMBER ,
          F_PSR_CLAIM_MV_2.LOCATION_ID ,
          F_PSR_CLAIM_MV_2.SITUS_STATE ,
          F_PSR_CLAIM_MV_2.INSURED_STATE ,
          F_PSR_CLAIM_MV_2.CLAIMANT_ADDRESS1 ,
          F_PSR_CLAIM_MV_2.CLAIMANT_ADDRESS2 ,
          F_PSR_CLAIM_MV_2.CLAIMANT_ADDRESS3 ,
          F_PSR_CLAIM_MV_2.CLAIMANT_CITY ,
          F_PSR_CLAIM_MV_2.CLAIMANT_ZIPCODE ,
          F_PSR_CLAIM_MV_2.CERTIFICATE_NUMBER ,
          F_PSR_CLAIM_MV_2.CLAIMANT_SALARY ,
          F_PSR_CLAIM_MV_2.CLAIMANT_SALARY_INDICATOR ,
          F_PSR_CLAIM_MV_3.ANN_PREMIUM_CYCLE_DATE ,
          F_PSR_CLAIM_MV_3.PRIMARY_DIAGNOSIS_CODE             AS PRIMARY_DIAGNOSIS_CODE ,
          F_PSR_CLAIM_MV_3.PRIMARY_DIAGNOSIS_CODE_DESCRIPTION AS PRIMARY_DIAGNOSIS_CODE_DESCRIPTION ,
          F_PSR_CLAIM_MV_3.PRIMARY_DIAGNOSIS_CATEGORY_DESCRIPTION ,
          F_PSR_CLAIM_MV_3.PRIMARY_DIAGNOSIS_CATEGORY ,
          F_PSR_CLAIM_MV_3.ADDITIONAL_DIAGNOSIS_CODE_DESCRIPTION ,
          F_PSR_CLAIM_MV_3.ADDITIONAL_DIAGNOSIS_CODE ,
          F_PSR_CLAIM_MV_3.ADDITIONAL_DIAGNOSIS_CATEGORY_DESCRIPTION ,
          F_PSR_CLAIM_MV_3.ADDITIONAL_DIAGNOSIS_CATEGORY ,
          F_PSR_CLAIM_MV_4.REHABILITATION_OFFSET_AMOUNT_088 ,
          F_PSR_CLAIM_MV_4.WORKERS_COMPENSATION_OFFSET_AMOUNT_083 ,
          F_PSR_CLAIM_MV_4.OTHER_OFFSET_AMOUNTS ,
          F_PSR_CLAIM_MV_4.REHABILITATION_OFFSET_INDICATOR_088 ,
          F_PSR_CLAIM_MV_4.WORK_INCENTIVE_EXCESS_OFFSET_INDICATOR_188 ,
           case when F_PSR_CLAIM_MV_3.CLAIM_AGE is null
           then F_PSR_CLAIM_MV_1.AS_OF_DATE - F_PSR_CLAIM_MV_1.CLAIM_RECEIVED_DATE
           else F_PSR_CLAIM_MV_3.CLAIM_AGE
           end CLAIM_AGE,
          F_PSR_CLAIM_MV_3.CLAIM_COUNT ,
          F_PSR_CLAIM_MV_3.SOCIAL_SECURITY_PRIMARY_AWARD_AMOUNT ,
          F_PSR_CLAIM_MV_3.SOCIAL_SECURITY_PRIMARY_AWARD_STATUS ,
          F_PSR_CLAIM_MV_3.SOCIAL_SECURITY_PRIMARY_AWARD_TYPE ,
          F_PSR_CLAIM_MV_3.SOCIAL_SECURITY_PRIMARY_AWARD_EFFECTIVE_DATE ,
          F_PSR_CLAIM_MV_3.SOCIAL_SECURITY_PRIMARY_AWARD_TERMINATION_DATE ,
          F_PSR_CLAIM_MV_3.SOCIAL_SECURITY_DEPENDENT_AWARD_AMOUNT ,
          F_PSR_CLAIM_MV_3.SOCIAL_SECURITY_DEPENDENT_AWARD_STATUS ,
          F_PSR_CLAIM_MV_3.SOCIAL_SECURITY_DEPENDENT_AWARD_TYPE ,
          F_PSR_CLAIM_MV_3.SOCIAL_SECURITY_DEPENDENT_AWARD_EFFECTIVE_DATE ,
          F_PSR_CLAIM_MV_3.SOCIAL_SECURITY_DEPENDENT_AWARD_TERMINATION_DATE ,
          F_PSR_CLAIM_MV_4.ACH_INDICATOR ,
          F_PSR_CLAIM_MV_4.MOST_RECENT_SERVICE_PERIOD_FROM_DATE ,
          F_PSR_CLAIM_MV_4.MOST_RECENT_SERVICE_PERIOD_TO_DATE ,
          F_PSR_CLAIM_MV_4.EARLIEST_BENEFIT_PAYMENT_DATE ,
          F_PSR_CLAIM_MV_4.LAST_BENEFIT_PAYMENT_DATE ,
          F_PSR_CLAIM_MV_4.CLAIM_TOTAL_PAID_NET_AMOUNT ,
          F_PSR_CLAIM_MV_4.CLAIM_TOTAL_PAID_TAXABLE_AMOUNT ,
          F_PSR_CLAIM_MV_4.CLAIM_TOTAL_PAID_LOSS_AMOUNT ,
          F_PSR_CLAIM_MV_4.CLAIM_TOTAL_PAID_GROSS_AMT ,
          F_PSR_CLAIM_MV_4.CLAIM_MODAL_AMOUNT,
		  F_PSR_CLAIM_MV_2.D_LAST_IN_STATUS_46_DATE_R,
		  F_PSR_CLAIM_MV_1.PRIVACY_INDICATOR
		 ,F_PSR_CLAIM_MV_2.DIRECTOR_FULL_NAME
		 ,F_PSR_CLAIM_MV_2.SUPERVISOR_FULL_NAME
		 ,F_PSR_CLAIM_MV_2.DIRECTOR_LOGIN_ID
		 ,F_PSR_CLAIM_MV_2.SUPERVISOR_LOGIN_ID
		 ,F_PSR_CLAIM_MV_2.NURSE_CERT_END_DATE
		 ,F_PSR_CLAIM_MV_2.NURSE_CERT_FLAG
		 ,TIER_MV.D_CREATED_DATE_R  TIER_CREATED_DATE
		 ,TIER_MV.V_TIER_R TIER
		 ,F_PSR_CLAIM_MV_1.CURRENT_RESERVE 
		 ,F_PSR_CLAIM_MV_1.Policy_effective_date
		 ,F_PSR_CLAIM_MV_2.N_PRODUCT_SK_R             
         ,F_PSR_CLAIM_MV_2.V_BASIC_PRODUCT_LINE_CODE_R
         ,F_PSR_CLAIM_MV_2.V_BASIC_PRODUCT_LINE_DESC_R
	     ,F_PSR_CLAIM_MV_2.CLIENT_NAME 
		 ,s.v_distribution_channel_r 
        FROM F_PSR_CLAIM_MV_1_TBL F_PSR_CLAIM_MV_1
        LEFT OUTER JOIN
          (SELECT DISTINCT F_PSR_CLAIM_COV_STATUS_MV.POLICY_SKEY POLICY_SKEY ,
            F_PSR_CLAIM_COV_STATUS_MV.CLAIM_SKEY CLAIM_SKEY ,
            F_PSR_CLAIM_COV_STATUS_MV.AS_OF_DATE AS_OF_DATE ,
            F_PSR_CLAIM_COV_STATUS_MV.COVERAGE_TYPE COVERAGE_TYPE ,
            F_PSR_CLAIM_COV_STATUS_MV.PRODUCT_COVERAGE_CODE PRODUCT_COVERAGE_CODE ,
            F_PSR_CLAIM_COV_STATUS_MV.COVERAGE_TYPE_CODE COVERAGE_TYPE_CODE ,
            F_PSR_CLAIM_COV_STATUS_MV.COVERAGE_TYPE_DESCRIPTION COVERAGE_TYPE_DESCRIPTION ,
            F_PSR_CLAIM_COV_STATUS_MV.EXAMINER_DEPARTMENT_CODE EXAMINER_DEPARTMENT_CODE ,
            F_PSR_CLAIM_COV_STATUS_MV.EXAMINER_LOGIN_ID EXAMINER_LOGIN_ID ,
            F_PSR_CLAIM_COV_STATUS_MV.EXAMINER_NAME EXAMINER_NAME ,
            F_PSR_CLAIM_COV_STATUS_MV.VOCATIONAL_REHAB_ACTIVE_STATUS VOCATIONAL_REHAB_ACTIVE_STATUS ,
            F_PSR_CLAIM_COV_STATUS_MV.VOCATIONAL_REHAB_OUTCOME VOCATIONAL_REHAB_OUTCOME ,
            F_PSR_CLAIM_COV_STATUS_MV.VOCATIONAL_REHAB_SERVICE_REQUESTED_OTHER VOCATIONAL_REHAB_SERVICE_REQUESTED_OTHER ,
            F_PSR_CLAIM_COV_STATUS_MV.VOCATIONAL_REHAB_SERVICE_REQUESTED VOCATIONAL_REHAB_SERVICE_REQUESTED ,
            F_PSR_CLAIM_COV_STATUS_MV.CLAIM_IDENTIFER CLAIM_IDENTIFER ,
             F_PSR_CLAIM_COV_STATUS_MV.D_LAST_IN_STATUS_46_DATE_R,
            F_PSR_CLAIM_COV_STATUS_MV.ANY_OCC_DECISION_MADE_DATE ANY_OCC_DECISION_MADE_DATE ,
            F_PSR_CLAIM_COV_STATUS_MV.ANY_OCC_PERIOD_INDICATOR ANY_OCC_PERIOD_INDICATOR ,
            F_PSR_CLAIM_COV_STATUS_MV.OWN_OCC_PERIOD OWN_OCC_PERIOD ,
            F_PSR_CLAIM_COV_STATUS_MV.ANY_OCC_START_DATE ANY_OCC_START_DATE ,
            F_PSR_CLAIM_COV_STATUS_MV.CLAIM_COVERAGE_DESCRIPTION CLAIM_COVERAGE_DESCRIPTION ,
            F_PSR_CLAIM_COV_STATUS_MV.COVERAGE_GROUP_CODE COVERAGE_GROUP_CODE ,
            F_PSR_CLAIM_COV_STATUS_MV.CLAIM_STATUS_CATEGORY CLAIM_STATUS_CATEGORY ,
            F_PSR_CLAIM_COV_STATUS_MV.CLAIM_STATUS_DESCRIPTION CLAIM_STATUS_DESCRIPTION ,
            F_PSR_CLAIM_COV_STATUS_MV.CLAIM_STATUS_EFFECTIVE_DATE CLAIM_STATUS_EFFECTIVE_DATE ,
            F_PSR_CLAIM_COV_STATUS_MV.CLAIM_TYPE CLAIM_TYPE ,
            F_PSR_CLAIM_COV_STATUS_MV.CLAIM_STATUS_CODE CLAIM_STATUS_CODE ,
            F_PSR_CLAIM_COV_STATUS_MV.PRIOR_STATUS_CODE PRIOR_STATUS_CODE ,
            F_PSR_CLAIMANT_MV.CLAIMANT_NAME CLAIMANT_NAME ,
            F_PSR_CLAIMANT_MV.CLAIMANT_GENDER CLAIMANT_GENDER ,
            F_PSR_CLAIMANT_MV.CLAIMANT_DOB CLAIMANT_DOB ,
            F_PSR_CLAIMANT_MV.CLAIMANT_AGE CLAIMANT_AGE ,
            F_PSR_CLAIMANT_MV.CLAIMANT_HIERDATE CLAIMANT_HIERDATE ,
            F_PSR_CLAIMANT_MV.CLAIM_COMPANY_NAME CLAIM_COMPANY_NAME ,
            F_PSR_CLAIMANT_MV.CLAIM_COMPANY_CODE CLAIM_COMPANY_CODE ,
            F_PSR_CLAIMANT_MV.LOCATION_NAME LOCATION_NAME ,
            F_PSR_CLAIMANT_MV.LOCATION_NUMBER LOCATION_NUMBER ,
            F_PSR_CLAIMANT_MV.LOCATION_ID LOCATION_ID ,
            F_PSR_CLAIMANT_MV.SITUS_STATE SITUS_STATE ,
            F_PSR_CLAIMANT_MV.INSURED_STATE INSURED_STATE ,
            F_PSR_CLAIMANT_MV.CLAIMANT_ADDRESS1 CLAIMANT_ADDRESS1 ,
            F_PSR_CLAIMANT_MV.CLAIMANT_ADDRESS2 CLAIMANT_ADDRESS2 ,
            F_PSR_CLAIMANT_MV.CLAIMANT_ADDRESS3 CLAIMANT_ADDRESS3 ,
            F_PSR_CLAIMANT_MV.CLAIMANT_CITY CLAIMANT_CITY ,
            F_PSR_CLAIMANT_MV.CLAIMANT_ZIPCODE CLAIMANT_ZIPCODE ,
            F_PSR_CLAIMANT_MV.CERTIFICATE_NUMBER CERTIFICATE_NUMBER ,
            F_PSR_CLAIMANT_MV.CLAIMANT_SALARY CLAIMANT_SALARY ,
            F_PSR_CLAIMANT_MV.CLAIMANT_SALARY_INDICATOR CLAIMANT_SALARY_INDICATOR
			,F_PSR_CLAIM_COV_STATUS_MV.DIRECTOR_FULL_NAME
			,F_PSR_CLAIM_COV_STATUS_MV.SUPERVISOR_FULL_NAME
			,F_PSR_CLAIM_COV_STATUS_MV.DIRECTOR_LOGIN_ID
			,F_PSR_CLAIM_COV_STATUS_MV.SUPERVISOR_LOGIN_ID
			,F_PSR_CLAIM_COV_STATUS_MV.NURSE_CERT_END_DATE
			,F_PSR_CLAIM_COV_STATUS_MV.NURSE_CERT_FLAG
		    ,F_PSR_CLAIM_COV_STATUS_MV.N_PRODUCT_SK_R             
            ,F_PSR_CLAIM_COV_STATUS_MV.V_BASIC_PRODUCT_LINE_CODE_R
            ,F_PSR_CLAIM_COV_STATUS_MV.V_BASIC_PRODUCT_LINE_DESC_R
			,F_PSR_CLAIMANT_MV.CLIENT_NAME 
          from F_PSR_CLAIM_COV_STATUS_MV_TBL F_PSR_CLAIM_COV_STATUS_MV
          INNER JOIN F_PSR_CLAIMANT_MV_TBL F_PSR_CLAIMANT_MV
          ON F_PSR_CLAIM_COV_STATUS_MV.POLICY_SKEY               = F_PSR_CLAIMANT_MV.POLICY_SKEY
          AND F_PSR_CLAIM_COV_STATUS_MV.CLAIM_SKEY               = F_PSR_CLAIMANT_MV.CLAIM_SKEY
          AND F_PSR_CLAIM_COV_STATUS_MV.AS_OF_DATE               =F_PSR_CLAIMANT_MV.AS_OF_DATE
          AND NVL(F_PSR_CLAIM_COV_STATUS_MV.CLAIM_IDENTIFER,' ') = NVL(F_PSR_CLAIMANT_MV.CLAIM_IDENTIFER,' ')
          )F_PSR_CLAIM_MV_2 ON F_PSR_CLAIM_MV_1.Policy_skey      = F_PSR_CLAIM_MV_2.Policy_skey
        AND F_PSR_CLAIM_MV_1.claim_skey                          =F_PSR_CLAIM_MV_2.claim_skey
        AND F_PSR_CLAIM_MV_1.AS_OF_DATE                          =F_PSR_CLAIM_MV_2.AS_OF_DATE
        AND NVL(F_PSR_CLAIM_MV_1.CLAIM_IDENTIFIER,' ')           = NVL(F_PSR_CLAIM_MV_2.CLAIM_IDENTIFER,' ')
        LEFT OUTER JOIN F_PSR_CLAIM_MV_3_TBL F_PSR_CLAIM_MV_3
        ON F_PSR_CLAIM_MV_2.Policy_skey               =F_PSR_CLAIM_MV_3.Policy_skey
        AND F_PSR_CLAIM_MV_2.claim_skey               =F_PSR_CLAIM_MV_3.claim_skey
        AND F_PSR_CLAIM_MV_2.AS_OF_DATE               =F_PSR_CLAIM_MV_3.AS_OF_DATE
        AND NVL(F_PSR_CLAIM_MV_2.CLAIM_IDENTIFER,' ') = NVL(F_PSR_CLAIM_MV_3.CLAIM_IDENTIFIER,' ')
        LEFT OUTER JOIN F_PSR_CLAIM_MV_4_TBL F_PSR_CLAIM_MV_4
        ON F_PSR_CLAIM_MV_1.POLICY_SKEY =F_PSR_CLAIM_MV_4.N_POLICY_SK_R
        AND F_PSR_CLAIM_MV_1.CLAIM_SKEY =F_PSR_CLAIM_MV_4.N_CLAIM_SK_R
         AND NVL(F_PSR_CLAIM_MV_1.CLAIM_IDENTIFIER,' ') = NVL(F_PSR_CLAIM_MV_4.v_claim_identifier_r,' ')
		LEFT OUTER JOIN CLAIM_NOTE_TIER_MV TIER_MV
         ON TIER_MV.N_CLAIM_SK_R = F_PSR_CLAIM_MV_1.Claim_Skey
         LEFT JOIN
		  (SELECT  distinct N_POLICY_SK_R, v_distribution_channel_r FROM ATOMIC.fct_grp_policy_r where v_distribution_channel_r like '%MGIS%'  ) s
ON        F_PSR_CLAIM_MV_1.POLICY_SKEY=s.N_POLICY_SK_R;