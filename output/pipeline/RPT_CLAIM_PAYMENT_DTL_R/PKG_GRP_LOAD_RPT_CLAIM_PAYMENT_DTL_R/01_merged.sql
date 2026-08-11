

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ATOMIC"."PKG_GRP_LOAD_RPT_CLAIM_PAYMENT_DTL_R"
IS
/***********************************************************************
  Purpose:  This package body contains procedures which loads data into RPT_CLAIM_PAYMENT_DTL_R

  Author     Date     Description
  ---------- -------- -------------------------------------------------
  VGireesh   10/11/23 Initial Creation
  VGireesh   04/01/24 Gather table stats added
  VGireesh   11/01/24 MV'S HAS BEEN used
  VGireesh   17/01/24 n_payment_sk_r derivation has been added
  VGireesh   18/01/24 Added procedure prc_rebuild_indexes
  VGireesh   23/01/24 Closed REF Cursor
  VGireesh   31/01/24 Updated logic for n_claim_paid_net_amount_r
  VGireesh   26/02/24 for month end  that the tables start loading data in the next month partition
                      Ex: March data on February 29th (as of 2.28).
                          27th is Feb Fisc Month End    202402  should be truncate and load in 202402 partition
                          28th is feb Fisc Month End +1 202402  should be truncate and load in 202402 partition
                          29th is Feb Fisc Month End +2 202403  should inactive records against the partition 202402 and load data in 202403 partition
  VGireesh   19/03/24 increased bulk limit in spec and added logic to alter unusable PK index
  VGireesh   20/03/24  Commented Gather table stats to see the job completion time without gather table stats
  VGireesh   26/03/24  updated the logic for the column n_taxable_benefit_amount_r
  VGireesh   03/04/24 Added Parallel to rebuild index fast  parallel 16 nologging
  VGireesh   29/04/24 Void Check - Column changes
  Chandra    17/05/24 Addition of new columns N_FICA_Wage_Base_Amount_R,N_Employee_SS_R,N_Employee_Med_R,N_Employer_SS_R,N_Employer_Med_R
  VGireesh   21/05/24 Column n_taxable_benefit_percentage_r,n_federal_income_tax_amount_r,n_state_income_tax_amount_r remapping
  VGireesh   07/06/24 v_benefit_code_r has been changed to v_benefit_group_r for the amount columns
  Vgireesh   01/07/24 Changes in n_taxable_benefit_amount_r , n_nontaxable_benefit_amount_r from Gisha
  Jagan	     24/07/24 Added the additional column N_08B_OFFSET_Amount_R from Karthick
  Jagan	     07/08/24 Added the additional column n_rsl_paid_direct_r from Karthick
  Vgireesh   13/08/24 Added columns n_claim_paid_loss_amount_ceded_r,n_claim_paid_loss_amount_net_r
                      Moved column N_CLAIM_PAID_LOSS_AMOUNT_R CASE logic to VW_FCT_CLAIM_PAYMENT_DETAIL_R_MV_SSL
  Chandra    28/08/24 Changed Logic of N_GROSS_AMOUNT_R
  Chandra    15/10/24 Added Column V_BENEFIT_CODE_R
  Suresh     25/08/25 Standardization of Code
						1. Variable Naming Convention:
							-- [scope][type]_[name]
							-- Scope: g = global, l = local
							-- Types: v = VARCHAR2, n = NUMBER, t = TIMESTAMP
							-- Examples: gv_name, ln_count, lt_created
							-- Use global vars (g_) only if shared across procedures.
							-- Prefer local vars (l_) for within a procedure.
							-- Keep names clear and concise.
						2. Using %TYPE for Variable declaration for all the Variables
						3. Using CONSTANT Key word if values do not change.
						4. Using PLS_INTEGER for all integer values
						5. Indentation of Code
						6. Do not use "_R" for the Variables declared within the Package
 Samba		12/05/26 Kill/Fill Changes: User Story - 514605
					 	- All code changes are marked with Kill/Fill start and end comment blocks.
					 	- Code changes ensure continuous data availability in reports, replacing the current truncate-and-load approach, which is not partition-exchange based.
					 	- Retaining old code base of bulk collect load; which can be used when this Package to be converted to incremental processing
***********************************************************************/
  --Global Constants
		gd_sysdate               CONSTANT DATE           											 := TRUNC(SYSDATE);
		gn_prior_month           PRCS_JOB_LOG_MESSAGE_R.N_COUNT_R%TYPE 					             := TO_NUMBER(TO_CHAR(ADD_MONTHS(TRUNC(gd_sysdate,'MM'),-1),'YYYYMM'));
		gn_current_month         PRCS_JOB_LOG_MESSAGE_R.N_COUNT_R%TYPE 					             := TO_NUMBER(TO_CHAR(gd_sysdate,'YYYYMM'));
		gn_sysdt_batchid         CONSTANT PRCS_JOB_LOG_MESSAGE_R.N_COUNT_R%TYPE 					 := TO_NUMBER(TO_CHAR(gd_sysdate,'YYYYMMDD'));
		gv_main_loadedby         CONSTANT PRCS_JOB_LOG_MESSAGE_R.V_CODE_LOCATION_R%TYPE				 := 'PKG_GRP_LOAD_RPT_CLAIM_PAYMENT_DTL_R.MAIN';
		gv_updby                 CONSTANT PRCS_JOB_LOG_MESSAGE_R.V_CODE_LOCATION_R%TYPE				 := 'PKG_GRP_LOAD_RPT_CLAIM_PAYMENT_DTL_R.PRC_UPD_DEL_DATA';
		gv_getcur_loadedby       CONSTANT PRCS_JOB_LOG_MESSAGE_R.V_CODE_LOCATION_R%TYPE				 := 'PKG_GRP_LOAD_RPT_CLAIM_PAYMENT_DTL_R.PRC_GET_CUR_DATA';
		gv_truncpartby           CONSTANT PRCS_JOB_LOG_MESSAGE_R.V_CODE_LOCATION_R%TYPE				 := 'PKG_GRP_LOAD_RPT_CLAIM_PAYMENT_DTL_R.PRC_TRUNC_PARTITION';
		gv_rebuildindexes        CONSTANT PRCS_JOB_LOG_MESSAGE_R.V_CODE_LOCATION_R%TYPE				 := 'PKG_GRP_LOAD_RPT_CLAIM_PAYMENT_DTL_R.PRC_REBUILD_INDEXES';
		gv_job_name              CONSTANT PRCS_JOB_LOG_R.V_JOB_NAME_R%TYPE							 := 'GRP_LOAD_RPT_CLAIM_PAYMENT_DTL_R';
		gv_running_status        CONSTANT PRCS_JOB_LOG_R.V_JOB_STATUS_R%TYPE  						 := 'Running';
		gv_error_status          CONSTANT PRCS_JOB_LOG_R.V_JOB_STATUS_R%TYPE    					 := 'Error';
		gv_success_status        CONSTANT PRCS_JOB_LOG_R.V_JOB_STATUS_R%TYPE  						 := 'Success';
		gv_source                CONSTANT PRCS_JOB_LOG_R.V_JOB_STATUS_R%TYPE 						 := 'EDW';
		gv_yes_ind               CONSTANT DIM_GRP_POLICY_DIR_R.v_active_status_r%TYPE				 := 'Y';
		gv_source_syst			 CONSTANT DIM_GRP_BILLING_POL_BILLGRP_R.v_source_system_name_r%TYPE	 := 'VUE';
		gv_message_type 	     CONSTANT PRCS_JOB_LOG_MESSAGE_R.v_message_type_r%TYPE  			 := PKG_GRP_LOG_UTIL.gc_message_type_info;
		gv_count_type    	     CONSTANT PRCS_JOB_LOG_MESSAGE_R.v_count_type_r%TYPE    			 := PKG_GRP_LOG_UTIL.gc_count_type_insert;
		gn_bulk_coll_cnt         CONSTANT PLS_INTEGER				                            	 := 50000;
        gn_run_cnt               PRCS_JOB_LOG_MESSAGE_R.N_COUNT_R%TYPE 	 				             := 0;
		gv_trcmsg                PRCS_JOB_LOG_MESSAGE_R.V_MESSAGE_R%TYPE;
		gt_start_time   	     PRCS_JOB_LOG_MESSAGE_R.D_CREATION_DATE_R %TYPE;
        gt_start_time_insd_lp    PRCS_JOB_LOG_MESSAGE_R.D_CREATION_DATE_R %TYPE;
		gt_end_time 		     PRCS_JOB_LOG_MESSAGE_R.D_CREATION_DATE_R %TYPE;
		gn_job_log_message_id    PRCS_JOB_LOG_MESSAGE_R.N_COUNT_R%TYPE;
		gn_error_line            PRCS_JOB_LOG_MESSAGE_R.v_message_type_r%TYPE;
		gn_out_job_id            PRCS_JOB_LOG_MESSAGE_R.N_JOB_ID_R%TYPE;
		gv_errmsg                PRCS_JOB_LOG_MESSAGE_R.V_MESSAGE_R%TYPE;

		gn_loop_counter_r   PRCS_JOB_LOG_MESSAGE_R.N_COUNT_R%TYPE 			:=0;
		--Start: kill/fill additions
		gv_rpt_table_name        CONSTANT PRCS_JOB_LOG_R.V_JOB_NAME_R%TYPE	 := 'RPT_CLAIM_PAYMENT_DTL_R';
		gv_exg_table_name        CONSTANT PRCS_JOB_LOG_R.V_JOB_NAME_R%TYPE	 := gv_rpt_table_name||'_EXG';
		gv_schema_owner        	 CONSTANT PRCS_JOB_LOG_R.V_JOB_NAME_R%TYPE	 := 'ATOMIC';
		--End: kill/fill additions

PROCEDURE prc_get_cur_data
	--(p_out_cursor OUT SYS_REFCURSOR) -- commented as part of Kill Fill process
/**************************************************************************************
  Purpose:  Procedure is used to get the latest data and perform ref_cursor assignment.

  Usage:	This procedure accepts one output parameters,output Variables: p_out_cursor: Used to perform ref cursor assignment

---------- -------- -------------------------------------------------
  Suresh     29/08/25 Standardization of Code
  Samba      12/05/26 Kill Fill CHnages
*******************************************************************************/
AS
BEGIN
       gv_trcmsg :='5.1 Entered into prc_get_cur_data ';
   gt_start_time := SYSTIMESTAMP;
	   /*START: NEW LOGGING MECHANISM CHANGES*/
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
				( p_job_id_r                    => gn_out_job_id
				 ,p_batch_id_r                  => gn_sysdt_batchid
				 ,p_message_type_r              => gv_message_type
				 ,p_code_location_r             => gv_getcur_loadedby
				 ,p_message_r                   => gv_trcmsg
				 ,p_count_type_r                => NULL
				 ,p_count_r                     => NULL
				 ,p_duration_r                  => NULL
				 ,p_created_by_r                => gv_job_name
				 ,out_prcs_job_log_message_id_r => gn_job_log_message_id
				);
	-- Start : Kill/Fill Changes 12th May 2026
		EXECUTE IMMEDIATE 'ALTER SESSION ENABLE PARALLEL DML';
	-- End : Kill/Fill Changes 12th May 2026


	gv_trcmsg := '5.2 - Data load starts for _EXG table for Partition Exchange';
  /*NEW LOGGING MECHANISM CHANGES*/
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
				( p_job_id_r                    => gn_out_job_id
				 ,p_batch_id_r                  => gn_sysdt_batchid
				 ,p_message_type_r              => gv_message_type
				 ,p_code_location_r             => gv_getcur_loadedby
				 ,p_message_r                   => gv_trcmsg
				 ,p_count_type_r                => NULL
				 ,p_count_r                     => NULL
				 ,p_duration_r                  => NULL
				 ,p_created_by_r                => gv_job_name
				 ,out_prcs_job_log_message_id_r => gn_job_log_message_id
				);

	-- Start : Kill/Fill Changes 12th May 2026: Commented following
	--Open/Assign SELECT stmnt
    --open P_OUT_CURSOR for

		INSERT /*+ APPEND PARALLEL(stg, 8) */ INTO RPT_CLAIM_PAYMENT_DTL_R_EXG stg
		  SELECT /*+ PARALLEL(8) */
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
				-- E-REC M-0004: MV FCT_GRP_POLICY_R_MV_SSL inlined (shared MV, not yet decommissioned)
				SELECT MAX(N_CUST_PARTY_SK_R) N_CUST_PARTY_SK_R, N_POLICY_SK_R, N_VERSION_NUMBER_R
				FROM ATOMIC.FCT_GRP_POLICY_R
				GROUP BY N_POLICY_SK_R, N_VERSION_NUMBER_R
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
			ON dim_grp_product_r_l.n_product_sk_r = MV_PRD_LKI.n_product_sk_r
			--fetch first 253 rows only
		;

	gn_run_cnt:= SQL%ROWCOUNT;

	-- Start : Kill/Fill Changes 12th May 2026: Commented following
	COMMIT;
	EXECUTE IMMEDIATE 'ALTER SESSION DISABLE PARALLEL DML';
	-- End : Kill/Fill Changes 12th May 2026

	/*START: NEW LOGGING MECHANISM CHANGES*/
	gv_trcmsg:='5.3 Exit from prc_get_cur_data';
	gt_end_time:= SYSTIMESTAMP;

	 /*START: NEW LOGGING MECHANISM CHANGES*/
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
				( p_job_id_r                    => gn_out_job_id
				 ,p_batch_id_r                  => gn_sysdt_batchid
				 ,p_message_type_r              => gv_message_type
				 ,p_code_location_r             => gv_getcur_loadedby
				 ,p_message_r                   => gv_trcmsg
				 ,p_count_type_r                => gv_count_type
				 ,p_count_r                     => gn_run_cnt
				 ,p_duration_r                  => FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
				 ,p_created_by_r                => GV_JOB_NAME
				 ,out_prcs_job_log_message_id_r => gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/

EXCEPTION
WHEN OTHERS THEN
    gv_errmsg :=SUBSTR(SQLERRM,1,4000);
    gv_trcmsg:='6.z - Error in prc_get_cur_data: '||gv_errmsg;

	/*START: NEW LOGGING MECHANISM CHANGES*/
    pkg_grp_log_util.prc_update_log_message_r
			   (   n_prcs_job_log_message_id_r  => gn_job_log_message_id
				  ,p_err_msg                    => gv_trcmsg
					   );
    /*END: NEW LOGGING MECHANISM CHANGES*/

    pkg_grp_log_util.prc_update_log
			  (   p_job_id  					=> gn_out_job_id
				 ,p_job_status					=> gv_error_status
				 ,p_err_msg						=> gv_errmsg
				 ,p_trc_msg						=> gv_trcmsg
				 ,p_log_util_called_by_r		=> gv_getcur_loadedby
			  );
    RAISE;
END prc_get_cur_data;
--Procedure to insert dummy record in the table RPT_CLAIM_PAYMENT_DTL_R
PROCEDURE prc_insert_dummy_rec
IS
BEGIN
 	gv_trcmsg:='5. Call procedure prc_insert_dummy_rec from main';
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
	(
		p_job_id_r                    => gn_out_job_id,
		p_batch_id_r                  => gn_sysdt_batchid,
		p_message_type_r              => gv_message_type,
		p_code_location_r             => gv_main_loadedby,
		p_message_r                   => gv_trcmsg,
		p_count_type_r                => NULL,
		p_count_r                     => NULL,
		p_duration_r                  => NULL,
		p_created_by_r                => GV_JOB_NAME,
		out_prcs_job_log_message_id_r => gn_job_log_message_id
	);

     INSERT /*+APPEND*/ INTO  RPT_CLAIM_PAYMENT_DTL_R
		   (
		    v_last_modified_by_r
           ,t_creation_date_r
           ,v_created_by_r
           ,t_last_modified_date_r
           ,n_yearmonth_r
           ,v_rpt_active_status_r
           ,n_batch_id_r
		   ,N_PAYMENT_SK_R
		   ,N_CLAIM_SK_R
		   ,N_CLAIM_COVERAGE_SK_R
		   ,N_CLAIM_COVERAGE_GROUP_SK_R
		   ,N_PRODUCT_SK_R
		   ,N_PAYEE_PARTY_SK_R
		   ,N_INSRD_PARTY_SK_R
		   ,N_CUST_PARTY_SK_R
		   ,N_WORKSHEET_SK_R
		   ,N_EMPLOYEE_SK_R
		   ,N_POLICY_SK_R
		   )
    VALUES(gv_main_loadedby
		  ,SYSTIMESTAMP
		  ,gv_main_loadedby
		  ,SYSTIMESTAMP
		  ,gn_current_month
		  ,'Y'
		  ,gn_sysdt_batchid
         ,-1			--N_PAYMENT_SK_R
		  ,-1			--N_CLAIM_SK_R
		  ,-1			--N_CLAIM_COVERAGE_SK_R
		  ,-1			--N_CLAIM_COVERAGE_GROUP_SK_R
		  ,-1			--N_PRODUCT_SK_R
		  ,-1			--N_PAYEE_PARTY_SK_R
		  ,-1			--N_INSRD_PARTY_SK_R
		  ,-1			--N_CUST_PARTY_SK_R
		  ,-1			--N_WORKSHEET_SK_R
		  ,-1			--N_EMPLOYEE_SK_R
		  ,-1			--N_POLICY_SK_R
		  );
    COMMIT;

    GV_TRCMSG:='5.2 Completed Procedure prc_insert_dummy_rec call from main';
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
	(
		p_job_id_r                    => gn_out_job_id,
		p_batch_id_r                  => gn_sysdt_batchid,
		p_message_type_r              => GV_MESSAGE_TYPE,
		p_code_location_r             => gv_main_loadedby,
		p_message_r                   => GV_TRCMSG,
		p_count_type_r                => NULL,
		p_count_r                     => NULL,
		p_duration_r                  => NULL,
		p_created_by_r                => GV_JOB_NAME,
		out_prcs_job_log_message_id_r => gn_job_log_message_id
	);

EXCEPTION
WHEN OTHERS THEN

    gv_errmsg :=SUBSTR(SQLERRM,1,4000);
    gv_trcmsg:='5.z - Error in prc_insert_dummy_rec: '||gv_errmsg;

	/*START: NEW LOGGING MECHANISM CHANGES*/
    pkg_grp_log_util.prc_update_log_message_r
			   (   n_prcs_job_log_message_id_r  => gn_job_log_message_id
				  ,p_err_msg                    => gv_trcmsg
					   );
    /*END: NEW LOGGING MECHANISM CHANGES*/

    pkg_grp_log_util.prc_update_log
			  (   p_job_id  					=> gn_out_job_id
				 ,p_job_status					=> gv_error_status
				 ,p_err_msg						=> gv_errmsg
				 ,p_trc_msg						=> gv_trcmsg
				 ,p_log_util_called_by_r		=> gv_getcur_loadedby
			  );
    RAISE;
END prc_insert_dummy_rec;

PROCEDURE main
/***********************************************************************
  Purpose:  This procedure controls the overall process and calls the child
            procedures needed

  Author     Date     Description
  ---------- -------- ----------------------------------------------------------
  VGireesh   10/11/23 Developed first Version
  Suresh     25/08/25 Standardization of Code
						1. Main uses following Procedures and functions which are called from the package PKG_GRP_COMMON_UTIL
								1. PRC_UPD_DEL_DATA updates the Prior Month active status to 'N' and also does the Truncate Partition
								2. PRC_REBUILD_INDEXES to rebuild indexes after they were disabled for performance improvement
								3. FNC_GRP_TIME_DURATION, this functions calculates the duration between start & end time of a step
								   and returns the Number of seconds.
						2. Main uses following functions which are called from the package PKG_GRP_LOG_UTIL
								1. PRC_INSTERT_LOG, This procedure creates log entry in the log table with status In-Progress.
								2. PRC_UPDATE_LOG, This procedure updates the log entry in the log table with the following status
											Success - Upon successful completion
											Error - If encounters any error
								3. prc_ins_prcs_job_log_message_r provides the standard process to Insert the Process Job Log Message record
						3. standardizing the Local Variables used - For the standardizing steps refer the master comment block from Package Body
						4. Declare all the Local variables
  Samba      12/05/26 Kill/Fill Changes

*******************************************************************************/
IS

       --Start: Commenting for kill/fill
	   /*TYPE lt_var_tbl_type IS TABLE OF RPT_CLAIM_PAYMENT_DTL_R%ROWTYPE INDEX BY BINARY_INTEGER;
		lt_var_tbl_type_rec lt_var_tbl_type;
		lc_var_ref_cur 		SYS_REFCURSOR;  */
		--End: Commenting for kill/fill

        lt_insert_time	    PRCS_JOB_LOG_MESSAGE_R.D_CREATION_DATE_R %TYPE  ;
        lv_rpt_table 		PRCS_JOB_LOG_R.CREATED_BY_R%TYPE 			    :='RPT_CLAIM_PAYMENT_DTL_R';
		ln_loop_counter     PLS_INTEGER                          		    := 1;
		ln_rec_cnt 			PLS_INTEGER									    := 0;
		ln_idx_num			PLS_INTEGER									    := 8;
        ld_fic_mis_date_2 DATE;
        ln_fisc_current_month NUMBER;

BEGIN
    --Call Log Util pkg to Insert entry in PRCS_JOB_LOG_R
	--For more details how this procedure is being used, refer the Main Procedure comment block.
	pkg_grp_log_util.PRC_INSERT_LOG
					( p_source              		=> gv_source
					 ,p_job_nm               		=> gv_job_name
					 ,p_job_status           		=> gv_running_status
					 ,p_err_msg              		=> NULL
					 ,p_trc_msg              		=> NULL
					 ,p_n_batch_id           		=> gn_sysdt_batchid
					 ,p_log_util_called_by_r 		=> gv_main_loadedby
					 ,out_job_id             		=> gn_out_job_id
					);

	gv_trcmsg:='1. Entered into Main';
    /*START: NEW LOGGING MECHANISM CHANGES*/
	 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
				   ( p_job_id_r                  	=> gn_out_job_id
					,p_batch_id_r               	=> gn_sysdt_batchid
					,p_message_type_r            	=> gv_message_type
					,p_code_location_r            	=> gv_main_loadedby
					,p_message_r                  	=> gv_trcmsg
					,p_count_type_r               	=> NULL
					,p_count_r                    	=> NULL
					,p_duration_r                 	=> NULL
					,p_created_by_r               	=> GV_JOB_NAME
					,out_prcs_job_log_message_id_r	=> gn_job_log_message_id
					);
    /*END: NEW LOGGING MECHANISM CHANGES*/

    /*Common Utility Proc to get month end+2 date and month. Ex: If month end is 29-Aug-2025 then ln_fisc_current_month will be 202509*/
	PKG_GRP_COMMON_UTIL.prc_fisc_month_calc
	(
		p_out_job_id            =>	gn_out_job_id,
        p_Log_seq_num           =>	2,
		ln_fisc_current_month   =>	ln_fisc_current_month,
		ld_fic_mis_date_2       =>	ld_fic_mis_date_2
	);

	/*Common Utility Proc to determine current and prior month ; Checks for month end logic and daily load logic as well */
	PKG_GRP_COMMON_UTIL.PRC_GET_CURRENT_PRIOR_MONTH
	(
		p_out_job_id            =>	gn_out_job_id,
		p_Log_seq_num           =>	3,
		P_fic_mis_date       	=>	ld_fic_mis_date_2,
		P_fisc_current_month    =>	ln_fisc_current_month,
		p_current_month         =>	gn_current_month,
		p_prior_month           =>	gn_prior_month
	);

	-- Start : Kill/Fill Changes 12th May 2026 	: Added New
	PKG_GRP_COMMON_UTIL.PRC_CREATE_EXCHANGE_TABLE_DDL
		(
			p_job_id            	=> gn_out_job_id,
			p_log_seq_num           => 4,
			p_main_table_name       => gv_rpt_table_name,
			p_exg_table_name        => gv_exg_table_name,
			p_schema_name           => gv_schema_owner
		);


	/*EXECUTE IMMEDIATE 'DROP TABLE RPT_CLAIM_PAYMENT_DTL_R_EXG CASCADE CONSTRAINTS';
	EXECUTE IMMEDIATE 'CREATE TABLE RPT_CLAIM_PAYMENT_DTL_R_EXG FOR EXCHANGE WITH TABLE RPT_CLAIM_PAYMENT_DTL_R';
	EXECUTE IMMEDIATE 'ALTER TABLE RPT_CLAIM_PAYMENT_DTL_R_EXG ADD CONSTRAINT PK_LOCAL_8894_EXG PRIMARY KEY (N_YEARMONTH_R, N_EMPLOYEE_SK_R, N_PRODUCT_SK_R, N_PAYMENT_SK_R, N_CLAIM_SK_R, N_CLAIM_COVERAGE_SK_R, N_CLAIM_COVERAGE_GROUP_SK_R, N_PAYEE_PARTY_SK_R, N_INSRD_PARTY_SK_R, N_CUST_PARTY_SK_R, N_WORKSHEET_SK_R, N_POLICY_SK_R) DISABLE';
	EXECUTE IMMEDIATE 'ALTER TABLE RPT_CLAIM_PAYMENT_DTL_R_EXG ADD CONSTRAINT R_LOCAL_7625_EXG FOREIGN KEY (N_YEARMONTH_R, N_CUST_PARTY_SK_R, N_POLICY_SK_R) REFERENCES ATOMIC.RPT_POLICY_DTL_R (N_YEARMONTH_R,N_CUST_PARTY_SK_R, N_POLICY_SK_R) ON DELETE SET NULL DISABLE'	;
	EXECUTE IMMEDIATE 'ALTER TABLE RPT_CLAIM_PAYMENT_DTL_R_EXG ADD CONSTRAINT R_LOCAL_7630_EXG FOREIGN KEY (N_YEARMONTH_R, N_PAYEE_PARTY_SK_R) REFERENCES ATOMIC.RPT_PAYEE_DTL_R (N_YEARMONTH_R, N_PAYEE_PARTY_SK_R) DISABLE'	;
	EXECUTE IMMEDIATE 'ALTER TABLE RPT_CLAIM_PAYMENT_DTL_R_EXG ADD CONSTRAINT R_LOCAL_7631_EXG FOREIGN KEY (N_YEARMONTH_R, N_WORKSHEET_SK_R) REFERENCES ATOMIC.RPT_WORKSHEET_DTL_R (N_YEARMONTH_R, N_WORKSHEET_SK_R) DISABLE'	;
	EXECUTE IMMEDIATE 'ALTER TABLE RPT_CLAIM_PAYMENT_DTL_R_EXG ADD CONSTRAINT R_LOCAL_7627_EXG FOREIGN KEY (N_YEARMONTH_R, N_PAYMENT_SK_R) REFERENCES ATOMIC.RPT_CLAIM_PAYMENT_R (N_YEARMONTH_R, N_PAYMENT_SK_R) DISABLE'	;
	*/

	PKG_GRP_LOAD_RPT_CLAIM_PAYMENT_DTL_R.prc_get_cur_data;

   /*Common Utility Proc to truncate partition */
	/*PKG_GRP_COMMON_UTIL.prc_trunc_partition
	(
		p_out_job_id    	=>	gn_out_job_id,
		p_Log_seq_num   	=>	4,
		p_rpt_table     	=>	lv_rpt_table,  --gc_rpt_table_name  to lv_rpt_table
		p_idx_num       	=>	ln_idx_num ,   --gc_rebuild_idx_degree to ln_idx_num
		p_current_month     =>	gn_current_month
	);

    EXECUTE IMMEDIATE 'ALTER TABLE '||lv_rpt_table||' MODIFY PARTITION PART_'||lv_rpt_table||'_'||gn_current_month||' UNUSABLE LOCAL INDEXES';

    gv_trcmsg:='5. Disable Local indexes for partition: PART_'||lv_rpt_table||'_'||gn_current_month;
    		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
			(
				p_job_id_r                    => gn_out_job_id,
				p_batch_id_r                  => gn_sysdt_batchid,
				p_message_type_r              => gv_message_type,
				p_code_location_r             => gv_main_loadedby,
				p_message_r                   => gv_trcmsg,
				p_count_type_r                => NULL,
				p_count_r                     => NULL,
				p_duration_r                  => NULL,
				p_created_by_r                => GV_JOB_NAME,
				out_prcs_job_log_message_id_r => gn_job_log_message_id
			);
    /*5. Call procedure prc_insert_dummy_rec from main*/
    --prc_insert_dummy_rec;

    ---6. Call prc_get_cur_data to get the latest data and perform ref_cursor assignment.
    --prc_get_cur_data (lc_var_ref_cur);

    --gv_trcmsg:='7.Start Data Load.';

	--gt_start_time:= SYSTIMESTAMP;

	/*START: NEW LOGGING MECHANISM CHANGES*/
	/*PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
					(
					 p_job_id_r                    => gn_out_job_id
					,p_batch_id_r                  => gn_sysdt_batchid
					,p_message_type_r              => gv_message_type
					,p_code_location_r             => gv_main_loadedby
					,p_message_r                   => gv_trcmsg
					,p_count_type_r                => NULL
					,p_count_r                     => NULL
					,p_duration_r                  => NULL
					,p_created_by_r                => GV_JOB_NAME
					,out_prcs_job_log_message_id_r => gn_job_log_message_id
					);
    /*END: NEW LOGGING MECHANISM CHANGES*/

     /*   gn_loop_counter_r := 1; -- Initialize loop counter
	ln_rec_cnt:=0;
    LOOP
	lt_var_tbl_type_rec.DELETE;
    FETCH lc_var_ref_cur BULK COLLECT INTO  lt_var_tbl_type_rec LIMIT GN_BULK_COLL_CNT;
	 gt_start_time_insd_lp := SYSTIMESTAMP; -- Start timing before the insert

     FORALL x in lt_var_tbl_type_rec.First..lt_var_tbl_type_rec.Last
     INSERT /*+APPEND_VALUES*/ /*INTO RPT_CLAIM_PAYMENT_DTL_R VALUES lt_var_tbl_type_rec(x) ;
	 commit;
	 gt_end_time := SYSTIMESTAMP; -- End timing after the insert

		gv_trcmsg := '7.1 data load: Bulk Set-'|| gn_loop_counter_r ||': '||LN_REC_CNT||' records loaded' ;
		/*START: NEW LOGGING MECHANISM CHANGES*/
	    /*PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
			   ( p_job_id_r 					=> gn_out_job_id
				,p_batch_id_r					=> gn_sysdt_batchid
				,p_message_type_r 				=> gv_message_type
				,p_code_location_r 				=> gv_main_loadedby
				,p_message_r 					=> gv_trcmsg
				,p_count_type_r 				=> gv_count_type
				,p_count_r 						=> ln_rec_cnt
				,p_duration_r 					=> FNC_GRP_TIME_DURATION(gt_start_time_insd_lp,gt_end_time)
				,p_created_by_r 				=> Gv_JOB_NAME
				,out_prcs_job_log_message_id_r	=> gn_job_log_message_id
				);
		/*END: NEW LOGGING MECHANISM CHANGES*/

        /* gn_loop_counter_r:= gn_loop_counter_r + 1;
	     LN_REC_CNT:=LN_REC_CNT+lt_var_tbl_type_rec.COUNT;

     EXIT WHEN lc_var_ref_cur%NOTFOUND;
    END LOOP;
    CLOSE lc_var_ref_cur;--23-Jan-2024 Changes
    gv_trcmsg:='8 Data Loaded '||ln_rec_cnt||' records '||chr(13);

	/*START: NEW LOGGING MECHANISM CHANGES*/
      /*  gt_end_time := SYSTIMESTAMP;
        PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
                (    p_job_id_r                    => gn_out_job_id
                    ,p_batch_id_r                  => gn_sysdt_batchid
                    ,p_message_type_r              => gv_message_type
                    ,p_code_location_r             => gv_main_loadedby
                    ,p_message_r                   => gv_trcmsg
                    ,p_count_type_r                => gv_count_type
                    ,p_count_r                     => ln_rec_cnt
                    ,p_duration_r                  => FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
                    ,p_created_by_r                => GV_JOB_NAME
                    ,out_prcs_job_log_message_id_r => gn_job_log_message_id
                    );
        /*END: NEW LOGGING MECHANISM CHANGES*/


	-- Start : Kill/Fill Changes 12th May 2026 	: Added New
	-- Partition Exchange Common Utility Called to Move data from Exg table to the Main table Current month Partition
	PKG_GRP_COMMON_UTIL.PRC_PARTITION_EXCHANGE
	(
		p_job_id            	=> gn_out_job_id,
		p_log_seq_num           => 6,
		p_main_table_name       => gv_rpt_table_name,
		p_exg_table_name        => gv_exg_table_name,
		p_partition_name        => 'PART_'|| gv_rpt_table_name ||'_'||gn_current_month,
		p_schema_name           => gv_schema_owner
	);


    gv_trcmsg :='7. Rebuild Local Index prc_rebuild_index_partitions from Common Util for Partition: '||gn_current_month;
    gt_start_time :=SYSTIMESTAMP;
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
		 (
			p_job_id_r                    => gn_out_job_id,
			p_batch_id_r                  => gn_sysdt_batchid,
			p_message_type_r              => gv_message_type,
			p_code_location_r             => gv_rebuildindexes,
			p_message_r                   => gv_trcmsg,
			p_count_type_r                => NULL,
			p_count_r                     => NULL,
			p_duration_r                  => NULL,
			p_created_by_r                => GV_JOB_NAME,
			out_prcs_job_log_message_id_r => gn_job_log_message_id
		);

    --22-08-2025: Added Local Index Rebuild
	PKG_GRP_COMMON_UTIL.prc_rebuild_index_partitions
	(
		p_table_name   		  		  => 'RPT_CLAIM_PAYMENT_DTL_R',
		p_parallel_degree   		  => 8,
		p_partition_name  		  	  => 'PART_RPT_CLAIM_PAYMENT_DTL_R_'||gn_current_month,
		p_out_job_id              	  => gn_out_job_id,
		p_Log_seq_num             	  => 7
	);

        gv_trcmsg:='7.z Completed Rebuild Local Index prc_rebuild_index_partitions from Common Util for Partition: '||gn_current_month;
	/*START: NEW LOGGING MECHANISM CHANGES*/
        gt_end_time := SYSTIMESTAMP;
        PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
                (    p_job_id_r                    => gn_out_job_id
                    ,p_batch_id_r                  => gn_sysdt_batchid
                    ,p_message_type_r              => gv_message_type
                    ,p_code_location_r             => gv_rebuildindexes
                    ,p_message_r                   => gv_trcmsg
                    ,p_count_type_r                => NULL
                    ,p_count_r                     => null
                    ,p_duration_r                  => FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
                    ,p_created_by_r                => GV_JOB_NAME
                    ,out_prcs_job_log_message_id_r => gn_job_log_message_id
                    );
        /*END: NEW LOGGING MECHANISM CHANGES*/
    GV_TRCMSG:='8. Exit from main';
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
            (	 p_job_id_r                    => gn_out_job_id
				,p_batch_id_r                  => gn_sysdt_batchid
				,p_message_type_r              => gv_message_type
				,p_code_location_r             => gv_main_loadedby
				,p_message_r                   => gv_trcmsg
				,p_count_type_r                => NULL
				,p_count_r                     => NULL
				,p_duration_r                  => NULL
				,p_created_by_r                => Gv_JOB_NAME
				,out_prcs_job_log_message_id_r => gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/

    pkg_grp_log_util.prc_update_log
			  (   p_job_id  					=> gn_out_job_id
				 ,p_job_status					=> gv_success_status
				 ,p_err_msg						=> gv_errmsg
				 ,p_trc_msg						=> gv_trcmsg
				 ,p_log_util_called_by_r		=> gv_main_loadedby
			  );

EXCEPTION
WHEN OTHERS THEN
    gv_errmsg :=SUBSTR(SQLERRM,1,4000);
    gv_trcmsg:='1.Z Error in main: '||gv_errmsg;

	/*START: NEW LOGGING MECHANISM CHANGES*/
    pkg_grp_log_util.prc_update_log_message_r
			   (   n_prcs_job_log_message_id_r  => gn_job_log_message_id
				  ,p_err_msg                    => gv_trcmsg
					   );
    /*END: NEW LOGGING MECHANISM CHANGES*/

    pkg_grp_log_util.prc_update_log
			  (   p_job_id  					=> gn_out_job_id
				 ,p_job_status					=> gv_error_status
				 ,p_err_msg						=> gv_errmsg
				 ,p_trc_msg						=> gv_trcmsg
				 ,p_log_util_called_by_r		=> gv_main_loadedby
			  );

    RAISE;
END main;

end PKG_GRP_LOAD_RPT_CLAIM_PAYMENT_DTL_R;

