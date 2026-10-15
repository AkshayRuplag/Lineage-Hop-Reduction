-- Cleaned for lineage: PKG_GRP_LOAD_RPT_CLAIM_PAYMENT_R_PRC_GET_CUR_DATA (part 1/1)

INSERT  INTO RPT_CLAIM_PAYMENT_R_EXG stg
	SELECT 
         CASE
			WHEN FCPD.V_PAY_METHOD_R = 'ACH'
			THEN 'Y'
			ELSE 'N'
		 END  																		AS V_ACH_PAYMENT_IND_R
        ,FCPD.D_CHECK_DATE_R														AS D_CHECK_DATE_R
        ,FCPD.V_CHECK_NUMBER_R														AS V_CHECK_NUMBER_R
        ,SUBSTR(FCPD.V_PAYMENT_STATUS_R,1,1) 										AS V_CHECK_STATUS_R
        ,FCPD.V_PAYMENT_STATUS_R 													AS V_CHECK_STATUS_DESC_R
        ,FCPD.V_CHECK_TYPE_R 														AS V_CHECK_TYPE_R
        ,CAST(NULL AS VARCHAR2(140))  												AS V_CLAIM_PAYMENT_ADDRESS_LINE_1_R
		,CAST(NULL AS VARCHAR2(140))  												AS V_CLAIM_PAYMENT_ADDRESS_LINE_2_R
		,CAST(NULL AS VARCHAR2(140))  												AS V_CLAIM_PAYMENT_ADDRESS_LINE_3_R
		,CAST(NULL AS VARCHAR2(60))   												AS V_CLAIM_PAYMENT_CITY_R
		,FCPD.D_PAID_DATE_R  														AS D_PAID_DATE_R
		,TO_CHAR(FCPD.D_PAID_DATE_R,'YYYY') 										AS V_PAID_YEAR_R
		,FCPD.D_SERVICE_PERIOD_FROM_R												AS D_SERVICE_PERIOD_FROM_R
		,FCPD.D_SERVICE_PERIOD_TO_R													AS D_SERVICE_PERIOD_TO_R
        ,FCPD.V_PAYMENT_TYPE_R														AS V_PAYMENT_TYPE_R
		,CAST(NULL AS VARCHAR2(30)) 												AS V_POSTAL_ZIP_R
		,CAST(NULL AS DATE) 														AS D_PAYMENT_DATE_R
		,CAST(NULL AS VARCHAR2(40))   												AS V_CUSTOMER_PAYEE_MAIL_COUNTRY_R
		,CAST(NULL AS VARCHAR2(30))  												AS V_CUSTOMER_PAYEE_MAIL_STATE_R
		,CAST(NULL AS VARCHAR2(100)) 												AS V_PAYMENT_EXAMINER_LOGIN_ID_R
		,CAST(NULL AS VARCHAR2(100)) 												AS V_PAYMENT_EXAMINER_NAME_R
		,FCPD.V_PAYMENT_STATUS_R  													AS V_PAYMENT_STATUS_R
		,CAST(NULL AS VARCHAR2(20))  												AS V_CLAIM_PAYMENT_STATE_R
		,CAST(NULL AS date)  														AS D_BENEFIT_DTL_PAYMENT_DATE_R
		,(
			select DIM_TIME_R.N_FISCAL_MONTH_R
			from DIM_TIME_R
			where D_CALENDAR_DATE_R= FCPD.D_PAID_DATE_R
		) 																			AS N_CLAIM_PAID_FISCAL_MONTH_R
        ,(
			select DIM_TIME_R.N_FISCAL_YEAR_R
			from DIM_TIME_R
			where D_CALENDAR_DATE_R= FCPD.D_PAID_DATE_R
		) 																			AS N_CLAIM_PAID_FISCAL_YEAR_R
        ,FCPD.V_PAYEE_TYPE_R
		,FCPD.V_BENEFIT_CATEGORY_R  												AS V_BENEFIT_CATEGORY_R
		,FCPD.V_BENEFIT_CODE_R 														AS V_BENEFIT_CODE_R
		,FCPD.V_RECORD_TYPE_R   													AS V_RECORD_TYPE_R
		,FCPD.V_BENEFIT_DESCRIPTION_R  												AS V_BENEFIT_DESCRIPTION_R
		,FCPD.V_BENEFIT_GROUP_R  													AS V_BENEFIT_GROUP_R
		,FCPD.N_SEQUENCE_NUMBER_R  													AS N_SEQUENCE_NUMBER_R
		,FCPD.N_SOURCE_VERSION_SEQ_NUMBER_R  										AS N_SOURCE_VERSION_SEQ_NUMBER_R
		,FCPD.N_PAYMENT_SK_R 														AS N_PAYMENT_SK_R
		,gc_main_loadedby                                                   		AS v_last_modified_by_r
		,systimestamp                                                       		AS t_creation_date_r
		,gc_main_loadedby                                                   		AS v_created_by_r
		,systimestamp                                                       		AS t_last_modified_date_r
		,GN_CURRENT_MONTH                                                   		AS N_YEARMONTH_R
		,'Y' 																		AS v_rpt_active_status_r
        ,gn_sysdt_batchid  															AS n_batch_id_r
		,CAST(FCPD.N_CLAIM_SK_R AS NUMBER) 											AS N_CLAIM_SK_R
		,CAST(FCPD.N_SOURCE_SYSTEM_KEY_R AS NUMBER) 								AS N_SOURCE_SYSTEM_KEY_R
		,FCPD.v_privacy_indicator_r  												AS v_privacy_indicator_r
		,CAST(NULL AS VARCHAR2(100)) 												AS V_PAYMENT_EXAMINER_LOGIN_NAME_R
		,FCPD.V_PAYEE_FIRST_NAME_R		                                            AS V_PAYEE_FIRST_NAME_R
		,FCPD.V_PAYEE_MIDDLE_NAME_R		                                            AS V_PAYEE_MIDDLE_NAME_R
		,FCPD.V_PAYEE_LAST_NAME_R		                                            AS V_PAYEE_LAST_NAME_R
		,FCPD.V_PRIMARY_REINSURER_R		                                            AS V_PRIMARY_REINSURER_R
		,FCPD.V_SECONDARY_REINSURER_R		                                        AS V_SECONDARY_REINSURER_R
		,FCPD.V_TERNARY_REINSURER_R		                                            AS V_TERNARY_REINSURER_R
		,FCPD.V_PAYMENT_RECORD_TYPE_R		                                        AS V_PAYMENT_RECORD_TYPE_R
		,	case
				when FCPD.v_lob_type_r = 'ANNUITY'
				then c.V_STATE_NAME_R
				else FCPD.V_TAX_STATE_R
			end 																	AS V_TAX_STATE_R
        ,FCPD.N_PAYEE_PARTY_SK_R
		,c.V_ADDRESSLINE1_R                                              			AS V_PAYEE_ADDRESS_1_R
        ,c.V_ADDRESSLINE2_R                                              			AS V_PAYEE_ADDRESS_2_R
        ,c.V_ADDRESSLINE3_R                                              			AS V_PAYEE_ADDRESS_3_R
        ,c.V_CITY_R                                                     			AS V_PAYEE_CITY
        ,c.V_COUNTRY_R                                                 				AS V_PAYEE_COUNTRY_R
        ,d.D_BIRTH_DATE_R                                                   		AS D_PAYEE_BIRTH_DATE_R
        ,d.V_GENDER_R                                                       		AS V_PAYEE_GENDER_R
        ,d.V_TAX_NUMBER_R                                                   		AS V_CLAIM_PAYEE_SSN_R
        ,c.V_STATE_NAME_R                                                   		AS V_PAYEE_STATE_R
        ,d.V_TAX_NUMBER_R                                                   		AS V_CLAIM_PAYEE_TAX_ID_R
        ,c.V_POSTAL_ZIP_R                                                   		AS V_PAYEE_ZIP_R
		,FCPD.V_AMOUNT_TYPE_SUB_NAME_R                                              AS V_AMOUNT_TYPE_SUB_NAME_R
        ,FCPD.V_AMOUNT_TYPE_CATEGORY_R                                              AS V_AMOUNT_TYPE_CATEGORY_R
        ,FCPD.V_AMOUNT_TYPE_CATEGORY_DESC_R                                         AS V_AMOUNT_TYPE_CATEGORY_DESC_R
        ,FCPD.V_AMOUNT_TYPE_SUB_CATEGORY_R                                          AS V_AMOUNT_TYPE_SUB_CATEGORY_R
        ,FCPD.V_AMT_TYPE_SUB_CATEGORY_DESC_R                                        AS V_AMT_TYPE_SUB_CATEGORY_DESC_R
        ,FCPD.V_AMOUNT_TYPE_CODE_R                                                  AS V_AMOUNT_TYPE_CODE_R
        ,FCPD.V_AMOUNT_TYPE_NAME_R                                                  AS V_AMOUNT_TYPE_NAME_R
        ,FCPD.V_AMOUNT_TYPE_SUB_CODE_R                                              AS V_AMOUNT_TYPE_SUB_CODE_R
		,FCPD.V_PAY_METHOD_R 														AS V_PAY_METHOD_R
		 ,	CASE
				WHEN 	FCPD.V_PAYEE_LAST_NAME_R IS NULL
					AND FCPD.V_PAYEE_FIRST_NAME_R IS NULL
					AND FCPD.V_PAYEE_MIDDLE_NAME_R  IS NULL
				THEN NULL
				WHEN 	FCPD.V_PAYEE_FIRST_NAME_R  IS NULL
					AND FCPD.V_PAYEE_LAST_NAME_R IS NOT NULL
					AND FCPD.V_PAYEE_MIDDLE_NAME_R IS NOT NULL
				THEN  FCPD.V_PAYEE_LAST_NAME_R ||',' || FCPD.V_PAYEE_LAST_NAME_R
				WHEN  FCPD.V_PAYEE_LAST_NAME_R   IS NULL
					AND FCPD.V_PAYEE_FIRST_NAME_R   IS NOT NULL
					AND FCPD.V_PAYEE_MIDDLE_NAME_R IS NOT NULL
				THEN FCPD.V_PAYEE_MIDDLE_NAME_R ||','|| FCPD.V_PAYEE_FIRST_NAME_R
				WHEN FCPD.V_PAYEE_MIDDLE_NAME_R IS NULL
					AND FCPD.V_PAYEE_FIRST_NAME_R IS NOT NULL
					AND FCPD.V_PAYEE_LAST_NAME_R   IS NOT NULL
				THEN FCPD.V_PAYEE_LAST_NAME_R||','|| FCPD.V_PAYEE_FIRST_NAME_R
				WHEN FCPD.V_PAYEE_FIRST_NAME_R IS NULL
					AND   FCPD.V_PAYEE_LAST_NAME_R  IS NULL
					AND   FCPD.V_PAYEE_MIDDLE_NAME_R IS NOT NULL
				THEN   FCPD.V_PAYEE_MIDDLE_NAME_R
				WHEN FCPD.V_PAYEE_LAST_NAME_R IS NULL
					AND FCPD.V_PAYEE_MIDDLE_NAME_R IS NULL
					AND FCPD.V_PAYEE_FIRST_NAME_R IS NOT NULL
				THEN FCPD.V_PAYEE_FIRST_NAME_R
				WHEN FCPD.V_PAYEE_MIDDLE_NAME_R IS NULL
					AND  FCPD.V_PAYEE_FIRST_NAME_R  IS NULL
					AND  FCPD.V_PAYEE_LAST_NAME_R IS NOT NULL
				THEN FCPD.V_PAYEE_LAST_NAME_R
			ELSE
					FCPD.V_PAYEE_LAST_NAME_R ||','||
					FCPD.V_PAYEE_MIDDLE_NAME_R  ||',' ||
					FCPD.V_PAYEE_FIRST_NAME_R
			END 																AS V_PAYEE_NAME_R
		,N_CHECK_WAGE_BASE_R 													AS N_CHECK_WAGE_BASE_R
        ,N_CHECK_TAXABLE_BENEFIT_R												AS N_CHECK_TAXABLE_BENEFIT_R
        ,FCPD.V_HASH_KEY_R														AS V_HASH_KEY_R
        ,FCPD.n_claim_coverage_sk_r												AS n_claim_coverage_sk_r
        , D.V_DAY_PHONE_R 														AS V_DAY_PHONE_R
        , CASE
			WHEN FCPD.V_PAYMENT_STATUS_R = 'PAID'
			then 'PAID'
			WHEN FCPD.V_PAYMENT_STATUS_R = 'VOID'
			then  'VOIDED'
			WHEN FCPD.V_PAYMENT_STATUS_R = 'R'
			then 'REIMBURSEMENT'
          ELSE NULL
          END  																	AS V_PAYMENT_STATUS_TYPE_R
        , '0' 																	AS V_EMPLOYER_FICA_WAGE_BASE_R
        , '0' 																	AS V_EMPLOYER_MEDICARE_WAGE_BASE_R
    from
		(
			SELECT
				MV.N_CLAIM_SK_R, MV.N_CLAIM_COVERAGE_SK_R, MV.N_CLAIM_COVERAGE_GROUP_SK_R, MV.V_CLAIM_NUMBER_R, MV.V_COVERAGE_CODE_R
				, MV.V_COV_GROUP_ID_R, MV.V_CHECK_NUMBER_R, MV.V_PAY_METHOD_R, MV.V_BENEFIT_CODE_R, MV.V_BENEFIT_DESCRIPTION_R
				, MV.V_BENEFIT_GROUP_R, MV.N_GROSS_WAGE_BASE_R, MV.N_TAXABLE_PERCENT_R, MV.V_PAYMENT_STATUS_R, MV.N_PAID_AMOUNT_R
				, MV.V_PAYMENT_TYPE_R, MV.D_CHECK_DATE_R, MV.V_CHECK_TYPE_R, MV.D_PAID_DATE_R, MV.N_GROSS_AMOUNT_R
				, MV.D_SERVICE_PERIOD_FROM_R, MV.D_SERVICE_PERIOD_TO_R, MV.V_RECORD_TYPE_R, MV.N_WORKSHEET_OBJECT_NUM_R
				, MV.N_SOURCE_SYSTEM_KEY_R, MV.N_SOURCE_VERSION_SEQ_NUMBER_R, MV.N_SEQ_R, MV.N_GROUP_SEQ_R, MV.N_PARENT_OBJECTNUM_R
				, MV.N_LOAD_RUN_ID_R, MV.T_EVENT_TIMESTAMP_R, MV.FIC_MIS_DATE_R, MV.N_BATCH_ID_R, MV.N_SEQUENCE_NUMBER_R
				, MV.T_CREATION_DATE_R, MV.T_LAST_MODIFIED_DATE_R, MV.V_CREATED_BY_R, MV.V_LAST_MODIFIED_BY_R, MV.V_BENEFIT_CATEGORY_R
				, MV.N_PAID_CLAIM_BENEFITS_R, MV.N_TAXABLE_BENEFIT_AMT_R, MV.N_FEDERAL_TAX_WITHHELD_AMT_R, MV.N_STATE_TAX_WITHHELD_AMT_R
				, MV.N_EMPLOYEE_SS_WITHHELD_AMT_R, MV.N_EMPLOYEE_MED_WITHHELD_AMT_R, MV.N_EMPLOYER_SS_WITHHELD_AMT_R
				, MV.N_EMPLOYER_MED_WITHHELD_AMT_R, MV.N_LEGAL_EXPENSE_DIRECT_AMT_R, MV.N_OTHER_EXPENSE_DIRECT_AMT_R
				, MV.V_LOB_TYPE_R, MV.N_MODAL_AMOUNT_R, MV.N_PRIMARY_PAYEE_R, MV.N_ADJ_GROSS_BENEFIT_R, MV.N_PAY_AMOUNT_R
				, MV.V_PRIVACY_INDICATOR_R, MV.V_GROSS_BENEFIT_CODE_R, MV.N_SS_WAGE_BASE_R, MV.N_MED_WAGE_BASE_R, MV.N_PAYMENT_SK_R
				, MV.V_PAYEE_FIRST_NAME_R, MV.V_PAYEE_MIDDLE_NAME_R, MV.V_PAYEE_LAST_NAME_R, MV.V_PAYEE_TYPE_R
				, MV.V_PRIMARY_REINSURER_R, MV.V_SECONDARY_REINSURER_R, MV.V_TERNARY_REINSURER_R, MV.N_PRIMARY_REINSURER_REINS_SHARE_PCT_R
				, MV.N_SECONDARY_REINSURER_REINS_SHARE_PCT_R, MV.N_TERNARY_REINSURER_REINS_SHARE_PCT_R
				, MV.N_PRIMARY_REINSURER_REINSURANCE_PCT_R, MV.N_SECONDARY_REINSURER_REINSURANCE_PCT_R
				, MV.N_TERNARY_REINSURER_REINSURANCE_PCT_R, MV.N_TOTAL_REINSURANCE_PCT_R, MV.V_PAYMENT_RECORD_TYPE_R
				, MV.V_TAX_STATE_R, MV.N_PAYEE_PARTY_SK_R, MV.V_SOURCE_SYSTEM_NAME_R, MV.V_AMOUNT_TYPE_SUB_NAME_R
				, MV.V_AMOUNT_TYPE_CATEGORY_R, MV.V_AMOUNT_TYPE_CATEGORY_DESC_R, MV.V_AMOUNT_TYPE_SUB_CATEGORY_R
				, MV.V_AMT_TYPE_SUB_CATEGORY_DESC_R, MV.V_AMOUNT_TYPE_CODE_R, MV.V_AMOUNT_TYPE_NAME_R
				, MV.V_AMOUNT_TYPE_SUB_CODE_R, MV.N_CLAIM_PAID_LOSS_AMOUNT_R
				,(SELECT SUM(WAGEBASE.N_CHECK_TAXABLE_BENEFIT_R)
				   FROM VW_FCT_CLAIM_PAYMENT_DETAIL_R_MV_SSL_WAGEBASE_INC WAGEBASE
				   WHERE
					   WAGEBASE.D_SERVICE_PERIOD_FROM_R = MV.D_SERVICE_PERIOD_FROM_R
					AND WAGEBASE.D_SERVICE_PERIOD_TO_R   = MV.D_SERVICE_PERIOD_TO_R
					AND WAGEBASE.V_BENEFIT_CODE_R        = MV.V_BENEFIT_CODE_R
					AND WAGEBASE.V_CHECK_NUMBER_R        = MV.V_CHECK_NUMBER_R
					AND WAGEBASE.V_CLAIM_NUMBER_R        = MV.V_CLAIM_NUMBER_R
					AND WAGEBASE.N_CLAIM_SK_R            = MV.N_CLAIM_SK_R
					AND WAGEBASE.D_CHECK_DATE_R          = MV.D_CHECK_DATE_R
					AND WAGEBASE.D_PAID_DATE_R           = MV.D_PAID_DATE_R
				  ) N_CHECK_TAXABLE_BENEFIT_R
				,(SELECT SUM(WAGEBASE.N_CHECK_WAGE_BASE_R)
				   FROM VW_FCT_CLAIM_PAYMENT_DETAIL_R_MV_SSL_WAGEBASE_INC WAGEBASE
				   WHERE
					   WAGEBASE.D_SERVICE_PERIOD_FROM_R = MV.D_SERVICE_PERIOD_FROM_R
					AND   WAGEBASE.D_SERVICE_PERIOD_TO_R   = MV.D_SERVICE_PERIOD_TO_R
					AND   WAGEBASE.V_BENEFIT_CODE_R        = MV.V_BENEFIT_CODE_R
					AND   WAGEBASE.V_CHECK_NUMBER_R        = MV.V_CHECK_NUMBER_R
					AND   WAGEBASE.V_CLAIM_NUMBER_R        = MV.V_CLAIM_NUMBER_R
					AND   WAGEBASE.N_CLAIM_SK_R            = MV.N_CLAIM_SK_R
					AND   WAGEBASE.D_CHECK_DATE_R          = MV.D_CHECK_DATE_R
					AND   WAGEBASE.D_PAID_DATE_R           = MV.D_PAID_DATE_R
				  ) N_CHECK_WAGE_BASE_R
				,MV.V_HASH_KEY_R
			FROM VW_FCT_CLAIM_PAYMENT_DETAIL_R_MV_SSL_INC MV
		) FCPD
	left join dim_grp_party_dir_r b
		on FCPD.n_payee_party_sk_r = b.n_party_sk_r
		and b.v_active_status_r = 'Y'
	left join dim_grp_party_r d
		on b.n_party_sk_r = d.n_party_sk_r
		and b.n_source_version_number_r = d.n_source_version_number_r
		and d.v_active_status_r = 'Y'
	left join
	(
		select * from fct_grp_party_address_r c
		where
				c.v_location_id_r = 'MAIN'
			and c.n_party_sk_r <> -1
			and c.v_source_system_name_r = 'PACS'
			and
			c.N_SOURCE_VERSION_SEQ_NUMBER_R
			in (
				select max(C1.N_SOURCE_VERSION_SEQ_NUMBER_R)
				from FCT_GRP_PARTY_ADDRESS_R C1
				where C1.V_LOCATION_ID_R = 'MAIN'
				and C1.N_PARTY_SK_R <> -1
				and C1.V_SOURCE_SYSTEM_NAME_R = 'PACS'
				and c1.N_PARTY_SK_R=c.N_PARTY_SK_R
				and C1.N_SOURCE_VERSION_NUMBER_R=C.N_SOURCE_VERSION_NUMBER_R
				)
	) c
	on b.n_party_sk_r = c.n_party_sk_r
	and b.n_source_version_number_r = c.n_source_version_number_r;