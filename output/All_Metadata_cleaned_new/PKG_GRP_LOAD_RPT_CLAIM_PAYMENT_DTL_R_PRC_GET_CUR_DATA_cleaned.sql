-- Cleaned for lineage: PKG_GRP_LOAD_RPT_CLAIM_PAYMENT_DTL_R_PRC_GET_CUR_DATA

INSERT  INTO RPT_CLAIM_PAYMENT_DTL_R_EXG stg
		  SELECT 
			 FCPD.n_pay_amount_r 												AS n_check_amount_r
			,CASE
				WHEN FCPD.V_BENEFIT_GROUP_R IN ('098', 'FIC', '298', 'MED')
				THEN FCPD.N_MED_WAGE_BASE_R + FCPD.N_SS_WAGE_BASE_R
			 END 																AS n_gross_wage_base_amount_r
			,CASE
				WHEN FCPD.V_BENEFIT_GROUP_R IN ('283', '282', '182')
				THEN FCPD.n_paid_amount_r
			END  											 					AS n_ss_approved_offset_amt_r
			,CASE
				WHEN FCPD.V_BENEFIT_GROUP_R IN ('293', '292', '092')
				THEN FCPD.n_paid_amount_r
			END 												 				AS n_ss_estimated_offset_amt_r
			,CASE
				WHEN FCPD.v_benefit_code_r IN ('284','082')
				THEN FCPD.n_paid_amount_r
			END 																AS n_state_disability_offset_amt_r
			,CASE
				WHEN FCPD.V_BENEFIT_GROUP_R in( 'FIC', 'MED' )
					THEN -1 * FCPD.N_PAID_AMOUNT_R
				WHEN FCPD.v_benefit_code_r is not null
					THEN FCPD.N_PAID_AMOUNT_R
				ELSE 0
			END																	AS N_GROSS_AMOUNT_R
			,FCPD.n_paid_amount_r 												AS n_paid_amount_r
			,CASE
				WHEN
					SUBSTR(FCPD.V_BENEFIT_GROUP_R, 1, 3) = 'FIT'
					OR FCPD.V_BENEFIT_GROUP_R IN ('099')
				THEN N_PAID_AMOUNT_R
			END																	AS n_federal_income_tax_amount_r
			,CASE
				WHEN FCPD.v_benefit_group_r IN ('298')
				THEN FCPD.n_paid_amount_r
			END                      											AS n_medicare_tax_amount_r
			,CASE
				WHEN FCPD.v_benefit_group_r IN ('098', 'FIC', '298', 'MED')
				THEN N_MED_WAGE_BASE_R
			END                       											AS n_medicare_wage_base_amount_r
			,CASE
				WHEN FCPD.v_benefit_group_r
					IN ('FIC', 'MED','098', '097', '099', '200', '297', '298')
					AND FCPD.n_paid_amount_r > 0
					AND FCPD.v_check_type_r <> 'OE'
				THEN FCPD.n_paid_amount_r
				ELSE 0
			END 																AS n_nontaxable_benefit_amount_r
			,CASE
				WHEN FCPD.v_benefit_group_r IN ('098')
				THEN FCPD.n_paid_amount_r
			END                      											AS n_social_security_tax_amount_r
			,CASE
				WHEN FCPD.v_benefit_group_r IN ('098', 'FIC', '298', 'MED')
				THEN N_SS_WAGE_BASE_R
			END                         										AS n_social_security_wage_base_amount_r
			,CASE
				WHEN FCPD.V_BENEFIT_GROUP_R IN ('297')
				THEN N_PAID_AMOUNT_R
			END 																AS n_state_income_tax_amount_r
			,CASE
				WHEN FCPD.v_benefit_group_r IN ('097')
				THEN FCPD.n_paid_amount_r
			END                      											AS n_state_unemployment_tax_amount_r
			,CASE
				WHEN FCPD.v_benefit_group_r NOT IN ('098', '097', '099'
				                                  , '200', '297', '298'
												  , 'FIC', 'MED'
							                       )
				 AND FCPD.n_paid_amount_r <> 0
				 AND FCPD.v_check_type_r <> 'OE'
				THEN FCPD.n_paid_amount_r
				ELSE 0
			 END                     											AS n_taxable_benefit_amount_r
			,CASE
				WHEN FCPD.V_SOURCE_SYSTEM_NAME_R = 'CV'
				THEN NVL(FCPD.n_taxable_percent_r, 100)
				ELSE FCPD.n_taxable_percent_r
			END 																AS n_taxable_benefit_percentage_r
			,FCPD.n_claim_paid_loss_amount_r									AS n_claim_paid_loss_amount_r
			,CASE
				WHEN FCPD.V_CHECK_TYPE_R NOT IN ('OE')
				AND  FCPD.V_BENEFIT_GROUP_R NOT IN ('FIC', 'MED')
				THEN FCPD.N_PAID_AMOUNT_R
				ELSE 0
			END 																AS n_claim_paid_net_amount_r
			,COALESCE(dim_grp_product_r_l.n_product_sk_r
					, DG_PRD_J.n_product_sk_r
					, -1
				     ) 															AS n_product_sk_r
			,NVL(DIM_EMP.n_employee_sk_r, -1) 									AS n_employee_sk_r
			,gv_main_loadedby                                                   AS v_last_modified_by_r
			,SYSTIMESTAMP                                                       AS t_creation_date_r
			,gv_main_loadedby                                                   AS v_created_by_r
			,SYSTIMESTAMP                                                       AS t_last_modified_date_r
			,'Y'                                                        		AS v_rpt_active_status_r
			,gn_sysdt_batchid  													AS n_batch_id_r
			,gn_current_month                                                   AS n_yearmonth_r
			,NVL(DG_POL_DIR.n_policy_sk_r,-1)   								AS n_policy_sk_r
			,NVL(DGC_COV_GRP.n_claim_coverage_group_sk_r,-1)   					AS n_claim_coverage_group_sk_r
			,NVL(DGC_COV_GRP.n_claim_coverage_sk_r,-1)   						AS n_claim_coverage_sk_r
			,NVL(DIGCD.n_claim_sk_r,-1)         								AS n_claim_sk_r
			,FCPD.n_payment_sk_r												AS n_payment_sk_r
			,nvl(DG_CL_DTL.n_insrd_party_sk_r,-1)  								AS n_insrd_party_sk_r
			,nvl(FG_POL.n_cust_party_sk_r ,-1) 									AS n_cust_party_sk_r
			,-1                             									AS n_payee_party_sk_r
			,-1                                                                 AS n_worksheet_sk_r
			,NULL                        					                    AS N_CHECK_DATE_SK_R
			,NULL                        										AS N_PAID_DATE_SK_R
			,cast( null as number) 												AS N_POLICY_ID_R
			,FCPD.n_primary_reinsurer_reins_share_pct_r							AS n_primary_reinsurer_reins_share_pct_r
			,FCPD.n_secondary_reinsurer_reins_share_pct_r                       AS n_secondary_reinsurer_reins_share_pct_r
			,FCPD.n_ternary_reinsurer_reins_share_pct_r                         AS n_ternary_reinsurer_reins_share_pct_r
			,FCPD.n_primary_reinsurer_reinsurance_pct_r                         AS n_primary_reinsurer_reinsurance_pct_r
			,FCPD.n_secondary_reinsurer_reinsurance_pct_r                       AS n_secondary_reinsurer_reinsurance_pct_r
			,FCPD.n_ternary_reinsurer_reinsurance_pct_r                         AS n_ternary_reinsurer_reinsurance_pct_r
			,FCPD.n_total_reinsurance_pct_r                                     AS n_total_reinsurance_pct_r
			,CASE
				WHEN FCPD.V_BENEFIT_GROUP_R IN ('098')
				THEN FCPD.N_GROSS_WAGE_BASE_R
				ELSE 0
			END 																AS N_FICA_Wage_Base_Amount_R
			,CASE
				WHEN FCPD.V_BENEFIT_GROUP_R IN ('098')
				THEN FCPD.N_PAID_AMOUNT_R
				ELSE 0
			END 																AS N_Employee_SS_R
			,CASE
				WHEN FCPD.V_BENEFIT_GROUP_R IN ('298')
				THEN FCPD.N_PAID_AMOUNT_R
				ELSE 0
			END 																AS N_Employee_Med_R
			,CASE
				WHEN FCPD.V_BENEFIT_GROUP_R IN ('FIC')
				THEN
					CASE
						WHEN FCPD.V_PAYMENT_TYPE_R = 'PAY'
						THEN FCPD.N_PAID_AMOUNT_R * -1
						ELSE FCPD.N_PAID_AMOUNT_R
					END
				ELSE 0
			END 																AS N_Employer_SS_R
			,CASE
				WHEN FCPD.V_BENEFIT_GROUP_R IN ('MED')
				THEN
					CASE
						WHEN FCPD.V_PAYMENT_TYPE_R = 'PAY'
						THEN FCPD.N_PAID_AMOUNT_R * -1
						ELSE FCPD.N_PAID_AMOUNT_R
					END
				ELSE 0
				END 															AS N_Employer_Med_R
			,CASE
				WHEN FCPD.V_BENEFIT_CODE_R = '08B'
				THEN FCPD.N_PAID_AMOUNT_R
				ELSE 0
			END 																AS N_08B_OFFSET_Amount_R
			,CASE
				WHEN UPPER(FCPD.V_BENEFIT_CATEGORY_R)='TAXES'
				THEN (-1*FCPD.N_PAID_CLAIM_BENEFITS_R)
				ELSE FCPD.N_PAID_CLAIM_BENEFITS_R
			 END 																AS n_rsl_paid_direct_r
			,(FCPD.n_claim_paid_loss_amount_r * FCPD.n_total_reinsurance_pct_r) AS n_claim_paid_loss_amount_ceded_r
			,(FCPD.n_claim_paid_loss_amount_r
			 - (FCPD.n_claim_paid_loss_amount_r * FCPD.n_total_reinsurance_pct_r)
			 ) 																	AS n_claim_paid_loss_amount_net_r
			,FCPD.V_BENEFIT_CODE_R  											AS V_BENEFIT_CODE_R
			,FCPD.V_HASH_KEY_R													AS V_HASH_KEY_R
		FROM ATOMIC.vw_fct_claim_payment_detail_r_mv_ssl_inc FCPD
		LEFT JOIN ATOMIC.dim_grp_claim_dir_r DIGCD
			 ON FCPD.n_claim_sk_r = DIGCD.n_claim_sk_r
			AND DIGCD.v_active_status_r = 'Y'
		LEFT JOIN ATOMIC.dim_grp_claim_coverage_r DIGCOV
			ON 	FCPD.n_claim_coverage_sk_r = DIGCOV.n_claim_coverage_sk_r
			AND DIGCOV.v_active_status_r = 'Y'
		LEFT JOIN ATOMIC.dim_grp_claim_coverage_group_r DGC_COV_GRP
			ON 	FCPD.n_claim_coverage_group_sk_r = DGC_COV_GRP.n_claim_coverage_group_sk_r
			AND DGC_COV_GRP.v_active_status_r = 'Y'
		LEFT JOIN ATOMIC.dim_grp_policy_dir_r DG_POL_DIR
			ON 	DIGCD.n_policy_sk_r = DG_POL_DIR.n_policy_sk_r
			AND DG_POL_DIR.v_active_status_r = 'Y'
		LEFT JOIN ATOMIC.dim_grp_claim_detail_r DG_CL_DTL
			ON 	DIGCD.n_claim_sk_r = DG_CL_DTL.n_claim_sk_r
			AND DG_CL_DTL.v_active_status_r = 'Y'
		LEFT JOIN ATOMIC.dim_employee_r DIM_EMP
			ON 	DG_CL_DTL.V_EXAMINER_LOGIN_ID_R = DIM_EMP.V_EMPLOYEE_LOGIN_ID_R
			AND DIM_EMP.V_BUSINESS_UNIT_R = 'Claims'
		LEFT JOIN
			(
				SELECT N_CUST_PARTY_SK_R, N_POLICY_SK_R, N_VERSION_NUMBER_R
				FROM ATOMIC.FCT_GRP_POLICY_R_MV_SSL
			) FG_POL
			ON 	DG_POL_DIR.n_policy_sk_r = FG_POL.n_policy_sk_r
			AND DG_POL_DIR.N_POLICY_VERSION_NUMBER_R = FG_POL.N_VERSION_NUMBER_R
		LEFT JOIN
			(
				SELECT N_PRODUCT_SK_R, N_CLAIM_SK_R,V_CLAIM_COVERAGE_CODE_R
				FROM ATOMIC.MVW_PRODUCT_SK_LOOKUP_MIN_MV_SSL
			) MV_PRD_LKP
			ON  MV_PRD_LKP.n_claim_sk_r = DIGCD.n_claim_sk_r
			AND MV_PRD_LKP.v_claim_coverage_code_r = DIGCOV.v_claim_coverage_code_r
		LEFT JOIN ATOMIC.dim_grp_product_r DG_PRD_J
			ON 	MV_PRD_LKP.N_PRODUCT_SK_R = DG_PRD_J.N_PRODUCT_SK_R
		LEFT JOIN
			(
				SELECT
					 N_PRODUCT_SK_R
					,N_CLAIM_SK_R
					,V_CLAIM_COVERAGE_CODE_R
				FROM ATOMIC.MVW_PRODUCT_SK_LOOKUP_MIN_MV_SSL
			) 	MV_PRD_LKI
			ON  MV_PRD_LKI.n_claim_sk_r = DIGCD.n_claim_sk_r
			AND MV_PRD_LKI.v_claim_coverage_code_r = DGC_COV_GRP.v_claim_coverage_code_r
		LEFT JOIN ATOMIC.dim_grp_product_r dim_grp_product_r_l
			ON dim_grp_product_r_l.n_product_sk_r = MV_PRD_LKI.n_product_sk_r;