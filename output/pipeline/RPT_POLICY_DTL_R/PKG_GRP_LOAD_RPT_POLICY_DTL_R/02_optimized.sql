-- =============================================================================
-- 02_optimized.sql - PKG_GRP_LOAD_RPT_POLICY_DTL_R
-- Stage 2: PL/SQL Optimizer output (Mode A - post-merger scan)
-- Date: 2026-08-04
-- Applied: MGAP-1, OPP-02, OPP-03, OPP-04, OPP-05, OPP-06, OPP-07, OPP-08, OPP-12, OPP-14
-- Deferred to Standardizer: OPP-11, OPP-13
-- Not applied: OPP-01 (Cond.Safe), OPP-09, OPP-10 (Unsafe), OPP-15/16/17 (DBA)
-- Source: 01_merged.sql
-- =============================================================================


  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ATOMIC"."PKG_GRP_LOAD_RPT_POLICY_DTL_R"
/***********************************************************************
  Purpose:  This package body contains procedures which loads data into RPT_POLICY_DTL_R

  Author     Date     Description
  ---------- -------- -------------------------------------------------
  VGireesh   10/11/23 Initial Creation
  VGireesh   04/01/24 Gather table stats added
  VGireesh   23/01/24 Closed REF Cursor
  VGireesh   30/01/24 When we fixed the duplication issue on 12/7 that was impacting NONS policies, it caused EIS policies to get filtered out.
                      so added back in the policy SK join and add the NVL on source system key
  VGireesh   31/01/24 Since and nvl(FCT_GRP_POLICY_R.N_SOURCE_SYSTEM_KEY_R,999999) = nvl(DIM_GRP_POLICY_DIR_R.N_SOURCE_SYSTEM_KEY_R,999999) used hence commented out below
					  AND FCT_GRP_POLICY_R.N_SOURCE_SYSTEM_KEY_R = DIM_GRP_POLICY_DIR_R.N_SOURCE_SYSTEM_KEY_R
  VGireesh   26/02/24 for month end  that the tables start loading data in the next month partition
                      Ex: March data on February 29th (as of 2.28).
                          27th is Feb Fisc Month End    202402  should be truncate and load in 202402 partition
                          28th is feb Fisc Month End +1 202402  should be truncate and load in 202402 partition
                          29th is Feb Fisc Month End +2 202403  should inactive records against the partition 202402 and load data in 202403 partition
  VGireesh   26/02/24 Joins update and nvl(fct_grp_transactions_r.N_SOURCE_SYSTEM_KEY_R,999999)=nvl(DIM_GRP_POLICY_DIR_R.N_SOURCE_SYSTEM_KEY_R,999999)
  VGireesh   20/03/24 Added below condition to exclude bad records which are causing PK issue - confirmed with Erica
                      		  and a.N_POLICY_ID_R not in (68215,64819)--20-Mar-2024 changes
  VGireesh   29/03/24 and nvl(fct_grp_transactions_r.N_SOURCE_SYSTEM_KEY_R,-1)=nvl(DIM_GRP_POLICY_DIR_R.N_SOURCE_SYSTEM_KEY_R,-1)--29-Mar-2024 Erica changes  due to shinka
  VGireesh   03/04/24 Added Parallel to rebuild index fast  parallel 16 nologging
  VGireesh   29/04/24 Void Check - Column changes and added column N_POLICY_LIVES_R
  Chandra    21/06/24 Added D_UW_NEXT_RENEWAL_DATE_R, V_UW_NEEDED_UNDERWRITER_NAME_R, V_UW_NEEDED_COMMENTS_R, N_UW_NEEDED_PERCENT_R, V_UW_NEEDED_RENEWAL_STATUS_R,
                      N_UW_REQUESTED_PERCENT_R, D_RENEWAL_DATE_R,V_UW_TRK_NEEDED_UW_NAME_R, V_UW_TRK_NEEDED_COMMENTS_R, N_UW_TRK_NEEDED_PERCENT_R, V_UW_TRK_NEEDED_RENEW_STATUS_R, N_UW_TRK_REQUESTED_PERCENT_R
  Chandra    26/06/24 Updated Logic for v_carrier_name_r column nvl( fct_grp_policy_r.v_carrier_name_r  ,fct_grp_policy_r.v_administered_by_r)
  Chandra    02/07/24 Added column V_CLIENT_NAME_R and added block to update this column
  Chandra    24/07/24 Added column v_prs_strs_ind_r
  Jagan		 24/07/24 Added column D_UW_CYCLE_DATE_R,D_UW_LAST_UPDATE_DATE_R
  Chandra    30/07/24 Modified the Logic for v_client_name_r
  Vgireesh   30/07/24 Added columns D_ID_THEFT_DATE_R
                                    V_ID_THEFT_IND_R
  Vgireesh   03/08/24 Added column N_ASO_FEE_AMT_R
  Vgireesh   03/08/24 Added logic to populate below columns
                      D_CYCLE_DATE_R D_UW_CYCLE_DATE_R
					  ,D_UW_WORK_MONTH_R D_UW_LAST_UPDATE_DATE_R
					  ,N_POLICY_SK_R
                      ,D_UW_NEXT_RENEWAL_DATE_R
                      ,V_UW_NEEDED_UNDERWRITER_NAME_R
                      ,V_UW_NEEDED_COMMENTS_R
                      ,N_UW_NEEDED_PERCENT_R
                      ,V_UW_NEEDED_RENEWAL_STATUS_R
                      ,N_UW_REQUESTED_PERCENT_R
                      ,V_UW_TRK_NEEDED_UW_NAME_R
                      ,V_UW_TRK_NEEDED_COMMENTS_R
                      ,N_UW_TRK_NEEDED_PERCENT_R
                      ,V_UW_TRK_NEEDED_RENEW_STATUS_R
                      ,N_UW_TRK_REQUESTED_PERCENT_R
					  ,V_ID_THEFT_IND_R
                      ,d_id_theft_date_r
  Vgireesh   07/08/24 Added column V_ELIM_PERIOD_R and logic to populate V_ELIM_PERIOD_R
  Vgireesh   09/08/24 Added below cross sell columns
		               ,CAST(NULL AS VARCHAR2(10))                                             V_CROSS_SELL_INDICATOR_R
		               ,CAST(NULL AS VARCHAR2(10))                                             V_6MNTH_CROSS_SELL_INDICATOR_R
		               ,CAST(NULL AS VARCHAR2(300))                                            V_ANY_LOB_CROSS_SELL_R
		               ,CAST(NULL AS VARCHAR2(300))                                            V_LTD_CROSS_SELL_R
		               ,CAST(NULL AS VARCHAR2(300))                                            V_STD_CROSS_SELL_R
		               ,CAST(NULL AS VARCHAR2(300))                                            V_LIFE_CROSS_SELL_R
		               ,CAST(NULL AS VARCHAR2(300))                                            V_BASIC_LIFE_CROSS_SELL_R
		               ,CAST(NULL AS VARCHAR2(300))                                            V_SUPP_LIFE_CROSS_SELL_R
		               ,CAST(NULL AS VARCHAR2(300))                                            V_DEP_LIFE_CROSS_SELL_R
		               ,CAST(NULL AS VARCHAR2(300))                                            V_ADD_CROSS_SELL_R
		               ,CAST(NULL AS VARCHAR2(300))                                            V_SR_CROSS_SELL_R
		               ,CAST(NULL AS VARCHAR2(300))                                            V_VAR_CROSS_SELL_R
		               ,CAST(NULL AS VARCHAR2(300))                                            V_VAI_CROSS_SELL_R
		               ,CAST(NULL AS VARCHAR2(300))                                            V_VCI_CROSS_SELL_R
		               ,CAST(NULL AS NUMBER)                                                   N_TOTAL_PRODUCT_LINES_R
  Vgireesh   20/08/24 Logic change in d_next_renewal_date_r
  Vgireesh   23/08/24 Added below columns later will need to update these columns using update blocks
                      V_EAP_DESC_R
                      V_BEREAVE_DESC_R
                      V_EAP_EFF_DATE_R
                      V_BEREAVEDATE_R
  Vgireesh   24/08/24 Introduced Global Temporary table for better performance in UPDATE cursors
  Vgireesh   26/08/24 Added procedure prc_load_data_dim_gtt to load data in dim_plan_design_directory_r_gtt and called in MAIN procedure
  Vgireesh   03/09/24 Erica requeseted changes
                      --03-Sep-2024 changes starts
	                    --,nvl( fct_grp_policy_r.v_carrier_name_r  ,fct_grp_policy_r.v_administered_by_r) v_carrier_name_r--29-Apr-2024 changes
                          ,nvl( fct_grp_policy_r.v_carrier_name_r  ,
		                        (case when fct_grp_policy_r.v_administered_by_r = 'RSL'
		                		      then 'Reliance Standard Life Insurance Company'
		                			 when fct_grp_policy_r.v_administered_by_r = 'FRSLIC'
		                			 then 'First Reliance Standard Life Insurance Company'
                                     else
                                        null
		                			 end
		                	    )
		                	)	v_carrier_name_r
	                    --03-Sep-2024 changes ends
    Vgireesh   03/09/24 Temp fix till the issue got fixed 	 --AND dim_grp_policy_dir_r.v_policy_number_r NOT IN ('VCI885893','VAI884068')  ------THIS NEEDS TO BE REMOVE WHEN
	                    FIX SENT TO PROD BY SUDIP FOR FCT_GRP_TRANSACTIONS_R TABLE

	                    --03-sep-2024 changes starts
		                --, fct_grp_transactions_r fct_grp_transactions_r
	                    , (select * from fct_grp_transactions_r
		                   where
                           (case when n_policy_skey_r
                           --in (231201,231258)--prep
		                   in (231258,231197) --prod
                           then N_SOURCE_SYSTEM_KEY_R
                           else 1
		                   end)
                           is not null
		                   ) fct_grp_transactions_r
	                    --03-sep-2024 changes starts
    Vgireesh   04/09/24 Added new column V_RSL_EIN_IND_R
                        --04/09/2024 changes starts
		                ,(CASE  WHEN fct_grp_policy_r.N_W2_EXCLUDE_FICA_MATCH_R = 1 THEN 'X'
                                WHEN fct_grp_policy_r.N_CLAIMS_TAX_INDICATOR_R = 1
                                AND dim_grp_policy_dir_r.V_POLICY_PREFIX_R IN ('ASL', 'ASW') THEN 'Y'
                                WHEN fct_grp_policy_r.N_CLAIMS_TAX_INDICATOR_R = 1
                                AND fct_grp_policy_r.V_CARRIER_NAME_R IN ('First Reliance Standard Life Insurance Company', 'Reliance Standard Life Insurance Company')
                                THEN 'Y' ELSE 'N' END
                         )                                                                      V_RSL_EIN_IND_R
                        --04/09/2024 changes ends
  VGireesh     05/09/24 Changes in D_UW_CYCLE_DATE_R in the UW_NEED cursor
  Chandra      19/09/24 Added N_ASO_SETUP_FEE_AMT_R Column Request by karthick
  vGireesh     04/10/24 Used TRIM , as some extra character is coming eventhough it's date datatype column
                        TRIM(D_UW_CYCLE_DATE_R) D_UW_CYCLE_DATE_R
  Chandra      14/10/24 Added t4804933.V_COVERAGE_CODE_R in Cursor t4804933.V_COVERAGE_CODE_R
  Chandra      14/10/24 Added V_COVERAGE_CODE_R column
  Gireesh      16/10/24 Added d_rate_guar_r column and update block
  Gireesh      21/10/24 Added below columns
                        d_option_eff_date_r
                        v_option_r
                        n_new_option_rate_r and update block
  Chandra      25/10/24 Added column D_NEXT_RENEWAL_EFFECTIVE_DATE_R,N_RATE_GUARANTEE_R and added cursor cur_upd_nxt_ren_dt_col
  Gireesh      29/10/24 Added n_yearmonth_r filter in the cursor cur_upd_nxt_ren_dt_col
  Chandra      06/11/24 Added D_EFFECTIVE_R column in cursor cur_upd_nxtrenewaldt_col and populated column D_NEXT_RENEWAL_EFFECTIVE_DATE_R and commented cursor cur_upd_nxt_ren_dt_col
  Gireesh      15/11/24 Added D_SUBMISSION_DATE_R column and the cursor cur_upd_submission_dt
  Gireesh      15/11/24 Existing logic for D_NEXT_RENEWAL_EFFECTIVE_DATE_R has been disabled and moved to another cursor cur_upd_nxtrenewaleffdt_col
  Beneshya	   25/11/24 Changed the logic for D_NEXT_RENEWAL_EFFECTIVE_DATE_R column after validating it against Legacy for Rate Guarantee Report
  Chandra      27/11/24 Added filter for fct_grp_transactions_r v_source_system_name_r IN ('PACS','EIS')
  Chandra      11/12/24 Changed the logic of FCT_GRP_TRANSACTIONS_R join
  Chandra      09/01/25 Added column V_POLICY_INFORCE_INDICATOR_R and
                        Cursor cur_upd_inforceindicator_cols to update this field.
  Suresh       06/02/25 Added NVL  for V_POLICY_INFORCE_INDICATOR_R col.
  Suresh       11/02/25 Added N_ANNUALIZED_PREMIUM_R col
  Suresh       24/03/25 To change the logic to populate column V_POLICY_INFORCE_INDICATOR_R
  Rose		   21/05/25 Commented update flag = 'N' for Month End+2 Load.
                         Added Truncate for Month End+2 Load.
  Rose		   26/05/25 Added new logging Mechanism
  Suresh       24/06/25 Add column V_PLAN_DURATION_R to table.
  Suresh       24/06/25 Add column V_DISTRIBUTION_CHANNEL_R as per bug number 416953
  Suresh       11/07/25 Remove remove column V_PLAN_DURATION_R details.
  Suresh       18/08/25 Standardization of Code
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
 Suresh        11/09/25 Optimize Query for Temporary data insert , Procedure prc_load_data_dim_gtt

 Rose		   09/02/26 Logic change for D_POLICY_EFFECTIVE_DATE_R.
Samba         10/02/26 Added logging to capture the target count for Control Audits

Shiva			08-May-2026		Kill/Fill Changes: User Story - 514600
								- All code changes are marked with Kill/Fill start and end comment blocks.
								- Code changes ensure continuous data availability in reports, replacing the current truncate-and-load approach, which is not partition-exchange based.
								- Retaining old code base of bulk collect load; which can be used when this Package to be converted to incremental processing

 ***********************************************************************/
IS
 --Global Constants
		gd_sysdate               CONSTANT DATE           											 := TRUNC(SYSDATE);
		gn_prior_month           PRCS_JOB_LOG_MESSAGE_R.N_COUNT_R%TYPE 					             := TO_NUMBER(TO_CHAR(ADD_MONTHS(TRUNC(gd_sysdate,'MM'),-1),'YYYYMM'));
		gn_current_month         PRCS_JOB_LOG_MESSAGE_R.N_COUNT_R%TYPE 					             := TO_NUMBER(TO_CHAR(gd_sysdate,'YYYYMM'));
		gn_sysdt_batchid         CONSTANT PRCS_JOB_LOG_MESSAGE_R.N_COUNT_R%TYPE 					 := TO_NUMBER(TO_CHAR(gd_sysdate,'YYYYMMDD'));
		gv_main_loadedby         CONSTANT PRCS_JOB_LOG_MESSAGE_R.V_CODE_LOCATION_R%TYPE				 := 'PKG_GRP_LOAD_RPT_POLICY_DTL_R.MAIN';
		gv_updby                 CONSTANT PRCS_JOB_LOG_MESSAGE_R.V_CODE_LOCATION_R%TYPE				 := 'PKG_GRP_LOAD_RPT_POLICY_DTL_R.PRC_UPD_DEL_DATA';
		gv_getcur_loadedby       CONSTANT PRCS_JOB_LOG_MESSAGE_R.V_CODE_LOCATION_R%TYPE				 := 'PKG_GRP_LOAD_RPT_POLICY_DTL_R.PRC_GET_CUR_DATA';
		gv_truncpartby           CONSTANT PRCS_JOB_LOG_MESSAGE_R.V_CODE_LOCATION_R%TYPE				 := 'PKG_GRP_LOAD_RPT_POLICY_DTL_R.PRC_TRUNC_PARTITION';
		gv_rebuildindexes        CONSTANT PRCS_JOB_LOG_MESSAGE_R.V_CODE_LOCATION_R%TYPE				 := 'PKG_GRP_LOAD_RPT_POLICY_DTL_R.PRC_REBUILD_INDEXES';
        gv_upd_ind_cols_by       CONSTANT PRCS_JOB_LOG_MESSAGE_R.V_CODE_LOCATION_R%TYPE				 := 'PKG_GRP_LOAD_RPT_POLICY_DTL_R.PRC_UPD_COLS';
		gv_job_name              CONSTANT PRCS_JOB_LOG_R.V_JOB_NAME_R%TYPE							 := 'GRP_LOAD_RPT_POLICY_DTL_R';
        gv_dummyrec_loadedby     CONSTANT PRCS_JOB_LOG_MESSAGE_R.V_CODE_LOCATION_R%TYPE				 := 'PKG_GRP_LOAD_RPT_POLICY_DTL_R.PRC_INSERT_DUMMY_REC';
		gv_running_status        CONSTANT PRCS_JOB_LOG_R.V_JOB_STATUS_R%TYPE  						 := 'Running';
		gv_error_status          CONSTANT PRCS_JOB_LOG_R.V_JOB_STATUS_R%TYPE    					 := 'Error';
		gv_success_status        CONSTANT PRCS_JOB_LOG_R.V_JOB_STATUS_R%TYPE  						 := 'Success';
		gv_source                CONSTANT PRCS_JOB_LOG_R.V_JOB_STATUS_R%TYPE 						 := 'EDW';
		gv_target                CONSTANT PRCS_JOB_LOG_R.V_JOB_STATUS_R%TYPE 						 := 'RPT';
		gv_main_entity           CONSTANT PRCS_JOB_LOG_R.V_JOB_NAME_R%TYPE							 := 'POLICY_DTL';
		gv_yes_ind               CONSTANT DIM_GRP_POLICY_DIR_R.v_active_status_r%TYPE				 := 'Y';
		gv_source_syst			 CONSTANT DIM_GRP_BILLING_POL_BILLGRP_R.v_source_system_name_r%TYPE	 := 'VUE';
		gv_message_type 	     CONSTANT PRCS_JOB_LOG_MESSAGE_R.v_message_type_r%TYPE  			 := PKG_GRP_LOG_UTIL.gc_message_type_info;
		gv_count_type    	     CONSTANT PRCS_JOB_LOG_MESSAGE_R.v_count_type_r%TYPE    			 := PKG_GRP_LOG_UTIL.gc_count_type_insert;
        gv_count_type_upd	     CONSTANT PRCS_JOB_LOG_MESSAGE_R.v_count_type_r%TYPE    			 := PKG_GRP_LOG_UTIL.gc_count_type_update;
		gn_bulk_coll_cnt         CONSTANT PLS_INTEGER				                            	 := 50000;
        gn_run_cnt               PRCS_JOB_LOG_MESSAGE_R.N_COUNT_R%TYPE 	 				             := 0;
		gv_trcmsg                PRCS_JOB_LOG_MESSAGE_R.V_MESSAGE_R%TYPE;
		gt_start_time   	     PRCS_JOB_LOG_MESSAGE_R.D_CREATION_DATE_R %TYPE;
        gt_start_time_inside_lp  PRCS_JOB_LOG_MESSAGE_R.D_CREATION_DATE_R %TYPE;
		gt_end_time 		     PRCS_JOB_LOG_MESSAGE_R.D_CREATION_DATE_R %TYPE;
		gn_job_log_message_id    PRCS_JOB_LOG_MESSAGE_R.N_COUNT_R%TYPE;
		gn_error_line            PRCS_JOB_LOG_MESSAGE_R.v_message_type_r%TYPE;
		gn_out_job_id            PRCS_JOB_LOG_MESSAGE_R.N_JOB_ID_R%TYPE;
		gv_errmsg                PRCS_JOB_LOG_MESSAGE_R.V_MESSAGE_R%TYPE;
		--Start: kill/fill additions
		gv_rpt_table_name        CONSTANT PRCS_JOB_LOG_R.V_JOB_NAME_R%TYPE							 := 'RPT_POLICY_DTL_R';
		gv_exg_table_name        CONSTANT PRCS_JOB_LOG_R.V_JOB_NAME_R%TYPE							 := gv_rpt_table_name||'_EXG';
		gv_schema_owner        	 CONSTANT PRCS_JOB_LOG_R.V_JOB_NAME_R%TYPE							 := 'ATOMIC';
		--End: kill/fill additions

-- M-0031+M-0058+M-0073+M-0074 (compound): prc_load_data_dim_gtt removed — 8 GTT cursors rewritten to query DIM_PLAN_DESIGN_DIRECTORY_R directly

PROCEDURE PRC_UPD_COL_DETAILS
AS
CURSOR cur_upd_client_dtls
IS
   SELECT V_CLIENT_NAME_R  AS V_CLIENT_NAME_R
        , N_PARTY_SK_R     AS N_CUST_PARTY_SK_R
     FROM (SELECT V_CLIENT_NAME_R
                , N_PARTY_SK_R
                , RNK
             FROM (SELECT D.V_INDIVIDUAL_FIRST_NAME_R || ' ' || D.V_INDIVIDUAL_LAST_NAME_R AS V_CLIENT_NAME_R
                        , N_PARTY_SK_R
                        , RANK() OVER (PARTITION BY D.N_PARTY_SK_R ORDER BY D.T_EVENT_TIMESTAMP_R DESC) RNK
                     FROM DIM_GRP_PARTY_R D
                    WHERE EXISTS (SELECT 1
                                    FROM RPT_POLICY_DTL_R R
                                   WHERE D.N_PARTY_SK_R = R.N_CUST_PARTY_SK_R
                                     AND R.N_YEARMONTH_R = GN_CURRENT_MONTH
                                  )
                   )
           WHERE RNK=1
           );

TYPE var_upd_tbl_client_type IS TABLE OF cur_upd_client_dtls%ROWTYPE INDEX BY BINARY_INTEGER;
lt_var_upd_tbl_client_typ_rec var_upd_tbl_client_type;

CURSOR cur_upd_uw_dtls
IS
  SELECT TRIM(D_UW_CYCLE_DATE_R)         AS D_UW_CYCLE_DATE_R
       , D_UW_WORK_MONTH_R               AS D_UW_LAST_UPDATE_DATE_R
	   , N_POLICY_SK_R                   AS N_POLICY_SK_R
	   , D_UW_NEXT_RENEWAL_DATE_R        AS D_UW_NEXT_RENEWAL_DATE_R
	   , V_UW_NEEDED_UNDERWRITER_NAME_R  AS V_UW_NEEDED_UNDERWRITER_NAME_R
	   , V_UW_NEEDED_COMMENTS_R          AS V_UW_NEEDED_COMMENTS_R
	   , N_UW_NEEDED_PERCENT_R           AS N_UW_NEEDED_PERCENT_R
	   , V_UW_NEEDED_RENEWAL_STATUS_R    AS V_UW_NEEDED_RENEWAL_STATUS_R
	   , N_UW_REQUESTED_PERCENT_R        AS N_UW_REQUESTED_PERCENT_R
	   , V_UW_TRK_NEEDED_UW_NAME_R       AS V_UW_TRK_NEEDED_UW_NAME_R
	   , V_UW_TRK_NEEDED_COMMENTS_R      AS V_UW_TRK_NEEDED_COMMENTS_R
	   , N_UW_TRK_NEEDED_PERCENT_R       AS N_UW_TRK_NEEDED_PERCENT_R
	   , V_UW_TRK_NEEDED_RENEW_STATUS_R  AS V_UW_TRK_NEEDED_RENEW_STATUS_R
	   , N_UW_TRK_REQUESTED_PERCENT_R    AS N_UW_TRK_REQUESTED_PERCENT_R
    FROM FCT_GRP_POLICY_R_UW_NEEDED
   WHERE FCT_GRP_POLICY_R_UW_NEEDED.V_POLICY_NUMBER_R NOT LIKE 'GA%'
     AND FCT_GRP_POLICY_R_UW_NEEDED.D_CYCLE_DATE_R = (SELECT MAX(FCT_GRP_POLICY_R_UW_NEEDED_1.D_CYCLE_DATE_R)
	                                                    FROM FCT_GRP_POLICY_R_UW_NEEDED FCT_GRP_POLICY_R_UW_NEEDED_1
													  )
     AND EXISTS ( SELECT 1
					FROM DIM_GRP_POLICY_DIR_R T4817886
				   WHERE T4817886.N_POLICY_SK_R = FCT_GRP_POLICY_R_UW_NEEDED.N_POLICY_SK_R
					 AND FCT_GRP_POLICY_R_UW_NEEDED.N_VERSION_NUMBER_R = T4817886.N_POLICY_VERSION_NUMBER_R
					 AND T4817886.V_ACTIVE_STATUS_R = 'Y'
					 AND EXISTS (SELECT 1
								   FROM RPT_POLICY_DTL_R RPT
								  WHERE RPT.N_POLICY_SK_R = T4817886.N_POLICY_SK_R
									AND RPT.N_YEARMONTH_R = GN_CURRENT_MONTH
								 )
				 );

  TYPE var_upd_tbl_uw_type IS TABLE OF cur_upd_uw_dtls%ROWTYPE INDEX BY BINARY_INTEGER;
  lt_var_upd_tbl_uw_typ_rec var_upd_tbl_uw_type;

--Cursor cur_upd_theft_ind_col to fetch V_ID_THEFT_IND_R
--start time
	CURSOR cur_upd_theft_ind_col
	IS
	SELECT t4804933.n_policy_sk_r                              AS n_policy_sk_r
		 , NVL(MAX( t4805277.v_override_description_r),'No')   AS v_id_theft_ind_r
	  FROM fct_plan_design_summary_r t4805277
		 , DIM_PLAN_DESIGN_DIRECTORY_R t4804933  -- M-0031: GTT eliminated
	 WHERE t4804933.n_plan_design_sk_r = t4805277.n_plan_design_sk_r
	   AND t4804933.v_coverage_code_r = 'IDTHEFT'
   AND t4804933.v_active_status_r = 'Y'
   AND t4804933.N_PLAN_DESIGN_SRC_VERSION_NO_R = (
           SELECT T4817886.N_POLICY_VERSION_NUMBER_R
             FROM DIM_GRP_POLICY_DIR_R T4817886
            WHERE T4817886.N_POLICY_SK_R = t4804933.N_POLICY_SK_R
              AND T4817886.v_active_status_r = 'Y'
              AND EXISTS (SELECT 1 FROM RPT_POLICY_DTL_R RPT
                           WHERE RPT.N_POLICY_SK_R = T4817886.N_POLICY_SK_R
                             AND RPT.N_YEARMONTH_R = gn_current_month))
  GROUP BY t4804933.n_policy_sk_r;

  TYPE var_upd_tbl_theft_ind_type IS TABLE OF cur_upd_theft_ind_col%ROWTYPE INDEX BY BINARY_INTEGER;
  lt_var_upd_tbl_theft_ind_typ_rec var_upd_tbl_theft_ind_type;

	--Data fetch to cursor completed for cur_upd_theft_ind_col
	CURSOR cur_upd_theft_dt_col
	IS
	SELECT t4804933.n_policy_sk_r                  AS n_policy_sk_r
		 , MIN( t4805277.v_override_description_r) AS v_override_description_r
		 , CAST(NULL AS DATE)                      AS d_id_theft_date_r
	  FROM fct_plan_design_summary_r t4805277
		  ,DIM_PLAN_DESIGN_DIRECTORY_R t4804933  -- M-0031: GTT eliminated
	 WHERE t4804933.n_plan_design_sk_r = t4805277.n_plan_design_sk_r
	   AND t4804933.v_coverage_code_r = 'IDTHEFTEFFDATE'
	   AND t4805277.v_override_description_r IS NOT NULL
   AND t4804933.v_active_status_r = 'Y'
   AND t4804933.N_PLAN_DESIGN_SRC_VERSION_NO_R = (
           SELECT T4817886.N_POLICY_VERSION_NUMBER_R
             FROM DIM_GRP_POLICY_DIR_R T4817886
            WHERE T4817886.N_POLICY_SK_R = t4804933.N_POLICY_SK_R
              AND T4817886.v_active_status_r = 'Y'
              AND EXISTS (SELECT 1 FROM RPT_POLICY_DTL_R RPT
                           WHERE RPT.N_POLICY_SK_R = T4817886.N_POLICY_SK_R
                             AND RPT.N_YEARMONTH_R = gn_current_month))
	GROUP BY t4804933.n_policy_sk_r;

    TYPE var_upd_tbl_theft_dt_type IS TABLE OF cur_upd_theft_dt_col%ROWTYPE INDEX BY BINARY_INTEGER;
	LT_VAR_UPD_TBL_THEFT_DT_TYP_REC VAR_UPD_TBL_THEFT_DT_TYPE;
	ld_theft_dt DATE;

--Cursor to fetch Prs Strs Indicator
	CURSOR cur_upd_prs_strs_ind_r
	IS
	SELECT t4804933.n_policy_sk_r                 AS n_policy_sk_r
	     , MIN(t4805277.v_override_description_r) AS v_prs_strs_ind_r
	  FROM fct_plan_design_summary_r t4805277
		 , DIM_PLAN_DESIGN_DIRECTORY_R t4804933  -- M-0031: GTT eliminated
	 WHERE t4804933.n_plan_design_sk_r = t4805277.n_plan_design_sk_r
	   AND t4804933.v_coverage_code_r = 'PSINDICATOR'
   AND t4804933.v_active_status_r = 'Y'
   AND t4804933.N_PLAN_DESIGN_SRC_VERSION_NO_R = (
           SELECT T4817886.N_POLICY_VERSION_NUMBER_R
             FROM DIM_GRP_POLICY_DIR_R T4817886
            WHERE T4817886.N_POLICY_SK_R = t4804933.N_POLICY_SK_R
              AND T4817886.v_active_status_r = 'Y'
              AND EXISTS (SELECT 1 FROM RPT_POLICY_DTL_R RPT
                           WHERE RPT.N_POLICY_SK_R = T4817886.N_POLICY_SK_R
                             AND RPT.N_YEARMONTH_R = gn_current_month))
	GROUP BY t4804933.n_policy_sk_r;

	TYPE var_upd_prs_strs_ind IS TABLE OF cur_upd_prs_strs_ind_r%ROWTYPE INDEX BY BINARY_INTEGER;
    lt_var_upd_prs_strs_indp_rec var_upd_prs_strs_ind;

	CURSOR cur_upd_elimperiod_col
	IS
	SELECT t4804933.n_policy_sk_r                  AS n_policy_sk_r
	     , MAX( t4805277.v_override_description_r) AS V_ELIM_PERIOD_R
	  FROM fct_plan_design_summary_r t4805277
		 , DIM_PLAN_DESIGN_DIRECTORY_R t4804933  -- M-0031: GTT eliminated
	 WHERE t4804933.n_plan_design_sk_r = t4805277.n_plan_design_sk_r
	   AND t4804933.v_coverage_code_r = 'ELIMPERIOD'
   AND t4804933.v_active_status_r = 'Y'
   AND t4804933.N_PLAN_DESIGN_SRC_VERSION_NO_R = (
           SELECT T4817886.N_POLICY_VERSION_NUMBER_R
             FROM DIM_GRP_POLICY_DIR_R T4817886
            WHERE T4817886.N_POLICY_SK_R = t4804933.N_POLICY_SK_R
              AND T4817886.v_active_status_r = 'Y'
              AND EXISTS (SELECT 1 FROM RPT_POLICY_DTL_R RPT
                           WHERE RPT.N_POLICY_SK_R = T4817886.N_POLICY_SK_R
                             AND RPT.N_YEARMONTH_R = gn_current_month))
  GROUP BY t4804933.n_policy_sk_r;

  TYPE var_upd_tbl_elimperiod_type IS TABLE OF cur_upd_elimperiod_col%ROWTYPE INDEX BY BINARY_INTEGER;
  lt_var_upd_tbl_elimperiod_typ_rec var_upd_tbl_elimperiod_type;

--Cursor to fetch Eap Description
	CURSOR cur_upd_eap_desc_col
	IS
	SELECT t4804933.n_policy_sk_r                 AS n_policy_sk_r
	     , MAX(t4805277.v_override_description_r) AS v_eap_desc_r
		 , t4804933.V_COVERAGE_CODE_R             AS V_COVERAGE_CODE_R
	  FROM fct_plan_design_summary_r t4805277
		 , DIM_PLAN_DESIGN_DIRECTORY_R t4804933  -- M-0031: GTT eliminated
	 WHERE t4804933.n_plan_design_sk_r = t4805277.n_plan_design_sk_r
	   AND t4804933.v_coverage_code_r IN ('EAIND', 'EAP') --,'BEREAVE' --remove as requested by vamsi
   AND t4804933.v_active_status_r = 'Y'
   AND t4804933.N_PLAN_DESIGN_SRC_VERSION_NO_R = (
           SELECT T4817886.N_POLICY_VERSION_NUMBER_R
             FROM DIM_GRP_POLICY_DIR_R T4817886
            WHERE T4817886.N_POLICY_SK_R = t4804933.N_POLICY_SK_R
              AND T4817886.v_active_status_r = 'Y'
              AND EXISTS (SELECT 1 FROM RPT_POLICY_DTL_R RPT
                           WHERE RPT.N_POLICY_SK_R = T4817886.N_POLICY_SK_R
                             AND RPT.N_YEARMONTH_R = gn_current_month))
  GROUP BY t4804933.n_policy_sk_r,t4804933.V_COVERAGE_CODE_R;

   TYPE var_upd_tbl_eap_desc_type IS TABLE OF cur_upd_eap_desc_col%ROWTYPE INDEX BY BINARY_INTEGER;
   lt_var_upd_tbl_eap_desc_typ_rec var_upd_tbl_eap_desc_type;

	--Cursor to fetch Breave Description
	CURSOR cur_upd_bereave_desc_col
	IS
	SELECT t4804933.n_policy_sk_r                 AS n_policy_sk_r
	     , MAX(t4805277.v_override_description_r) AS V_BEREAVE_DESC_R
		 , t4804933.V_COVERAGE_CODE_R             AS V_COVERAGE_CODE_R
	  FROM fct_plan_design_summary_r t4805277
		 , DIM_PLAN_DESIGN_DIRECTORY_R t4804933  -- M-0031: GTT eliminated
	 WHERE t4804933.n_plan_design_sk_r = t4805277.n_plan_design_sk_r
	   AND t4804933.v_coverage_code_r ='BEREAVE'
   AND t4804933.v_active_status_r = 'Y'
   AND t4804933.N_PLAN_DESIGN_SRC_VERSION_NO_R = (
           SELECT T4817886.N_POLICY_VERSION_NUMBER_R
             FROM DIM_GRP_POLICY_DIR_R T4817886
            WHERE T4817886.N_POLICY_SK_R = t4804933.N_POLICY_SK_R
              AND T4817886.v_active_status_r = 'Y'
              AND EXISTS (SELECT 1 FROM RPT_POLICY_DTL_R RPT
                           WHERE RPT.N_POLICY_SK_R = T4817886.N_POLICY_SK_R
                             AND RPT.N_YEARMONTH_R = gn_current_month))
  GROUP BY t4804933.n_policy_sk_r,t4804933.V_COVERAGE_CODE_R;

	  TYPE var_upd_tbl_bereave_desc_type IS TABLE OF cur_upd_bereave_desc_col%ROWTYPE INDEX BY BINARY_INTEGER;
	  lt_var_upd_tbl_bereave_desc_typ_rec var_upd_tbl_bereave_desc_type;

	--Cursor to fetch Eap Effective Date
	CURSOR cur_upd_eap_eff_date_col
	IS
	SELECT t4804933.n_policy_sk_r                 AS n_policy_sk_r
	     , MAX(t4805277.v_override_description_r) AS V_EAP_EFF_DATE_R
	  FROM fct_plan_design_summary_r t4805277
		 , DIM_PLAN_DESIGN_DIRECTORY_R t4804933  -- M-0031: GTT eliminated
	 WHERE t4804933.n_plan_design_sk_r = t4805277.n_plan_design_sk_r
	   AND t4804933.v_coverage_code_r ='EAP_EFF_DATE'
   AND t4804933.v_active_status_r = 'Y'
   AND t4804933.N_PLAN_DESIGN_SRC_VERSION_NO_R = (
           SELECT T4817886.N_POLICY_VERSION_NUMBER_R
             FROM DIM_GRP_POLICY_DIR_R T4817886
            WHERE T4817886.N_POLICY_SK_R = t4804933.N_POLICY_SK_R
              AND T4817886.v_active_status_r = 'Y'
              AND EXISTS (SELECT 1 FROM RPT_POLICY_DTL_R RPT
                           WHERE RPT.N_POLICY_SK_R = T4817886.N_POLICY_SK_R
                             AND RPT.N_YEARMONTH_R = gn_current_month))
	 GROUP BY t4804933.n_policy_sk_r;

	  TYPE var_upd_tbl_eap_eff_date_type IS TABLE OF cur_upd_eap_eff_date_col%ROWTYPE INDEX BY BINARY_INTEGER;
	  lt_var_upd_tbl_eap_eff_date_typ_rec var_upd_tbl_eap_eff_date_type;

	--Cursor to fetch Bereave Date
	CURSOR cur_upd_bereavedate_col
	IS
	SELECT t4804933.n_policy_sk_r, MAX(t4805277.v_override_description_r) V_BEREAVEDATE_R
	  FROM fct_plan_design_summary_r t4805277
		 , DIM_PLAN_DESIGN_DIRECTORY_R t4804933  -- M-0031: GTT eliminated
	 WHERE t4804933.n_plan_design_sk_r = t4805277.n_plan_design_sk_r
	   AND t4804933.v_coverage_code_r ='BEREAVEDATE'
   AND t4804933.v_active_status_r = 'Y'
   AND t4804933.N_PLAN_DESIGN_SRC_VERSION_NO_R = (
           SELECT T4817886.N_POLICY_VERSION_NUMBER_R
             FROM DIM_GRP_POLICY_DIR_R T4817886
            WHERE T4817886.N_POLICY_SK_R = t4804933.N_POLICY_SK_R
              AND T4817886.v_active_status_r = 'Y'
              AND EXISTS (SELECT 1 FROM RPT_POLICY_DTL_R RPT
                           WHERE RPT.N_POLICY_SK_R = T4817886.N_POLICY_SK_R
                             AND RPT.N_YEARMONTH_R = gn_current_month))
  GROUP BY t4804933.n_policy_sk_r;

	  TYPE var_upd_tbl_bereavedate_type IS TABLE OF cur_upd_bereavedate_col%ROWTYPE INDEX BY BINARY_INTEGER;
	  lt_var_upd_tbl_bereavedate_typ_rec var_upd_tbl_bereavedate_type;

	CURSOR cur_upd_cross_sell_col
	IS
	  SELECT frcssr.n_policy_sk_r                           AS n_policy_sk_r
		   , frcssr.v_cross_sell_indicator_r                AS v_cross_sell_indicator_r
		   , frcssr.v_6mnth_cross_sell_indicator_r          AS v_6mnth_cross_sell_indicator_r
		   , frcssr.v_any_lob_cross_sell_r                  AS v_any_lob_cross_sell_r
		   , frcssr.v_ltd_cross_sell_r                      AS v_ltd_cross_sell_r
		   , frcssr.v_std_cross_sell_r                      AS v_std_cross_sell_r
		   , frcssr.v_life_cross_sell_r                     AS v_life_cross_sell_r
		   , frcssr.v_basic_life_cross_sell_r               AS v_basic_life_cross_sell_r
		   , frcssr.v_supp_life_cross_sell_r                AS v_supp_life_cross_sell_r
		   , frcssr.v_dep_life_cross_sell_r                 AS v_dep_life_cross_sell_r
		   , frcssr.v_add_cross_sell_r                      AS v_add_cross_sell_r
		   , frcssr.v_sr_cross_sell_r                       AS v_sr_cross_sell_r
		   , frcssr.v_var_cross_sell_r                      AS v_var_cross_sell_r
		   , frcssr.v_vai_cross_sell_r                      AS v_vai_cross_sell_r
		   , frcssr.v_vci_cross_sell_r                      AS v_vci_cross_sell_r
		   , frcssr.n_total_product_lines_r                 AS n_total_product_lines_r
		   , frcssr.n_yearmonth_r                           AS n_yearmonth_r
 	    FROM stg_cross_sell_summary_r frcssr  -- M-0028: renamed table
 	       , rpt_policy_dtl_r rpdr
 	   WHERE rpdr.n_policy_sk_r = frcssr.n_policy_sk_r
 	     AND rpdr.n_yearmonth_r = frcssr.n_yearmonth_r
 	     AND rpdr.n_yearmonth_r = gn_current_month
    GROUP BY frcssr.n_policy_sk_r
 		   , frcssr.v_cross_sell_indicator_r
 		   , frcssr.v_6mnth_cross_sell_indicator_r
 		   , frcssr.v_any_lob_cross_sell_r
 		   , frcssr.v_ltd_cross_sell_r
 		   , frcssr.v_std_cross_sell_r
 		   , frcssr.v_life_cross_sell_r
 		   , frcssr.v_basic_life_cross_sell_r
 		   , frcssr.v_supp_life_cross_sell_r
 		   , frcssr.v_dep_life_cross_sell_r
 		   , frcssr.v_add_cross_sell_r
 		   , frcssr.v_sr_cross_sell_r
 		   , frcssr.v_var_cross_sell_r
 		   , frcssr.v_vai_cross_sell_r
 		   , frcssr.v_vci_cross_sell_r
 		   , frcssr.n_total_product_lines_r
 		   , frcssr.n_yearmonth_r;

  TYPE var_upd_tbl_cross_sell_type IS TABLE OF cur_upd_cross_sell_col%ROWTYPE INDEX BY BINARY_INTEGER;
  lt_var_upd_tbl_cross_sell_typ var_upd_tbl_cross_sell_type;

  --Cursor to fetch D_NEXT_RENEWAL_DATE_R Date
  CURSOR cur_upd_nxtrenewaldt_col
	IS
	SELECT n_policy_sk_r               AS n_policy_sk_r
	     , d_calculated_expiry_date_r  AS d_next_renewal_date_r
      FROM (SELECT fgpr.n_policy_sk_r              AS n_policy_sk_r
	             , fgpr.d_calculated_expiry_date_r AS d_calculated_expiry_date_r
	             , RANK() OVER(PARTITION BY dgpdr.n_policy_sk_r ORDER BY dgpdr.t_event_timestamp_r desc) AS rnk
			  FROM fct_grp_policy_r fgpr,
				   dim_grp_policy_dir_r dgpdr,
				   fct_grp_transactions_r ft
	 WHERE EXISTS (SELECT 1
					 FROM fct_grp_transactions_r fgtr
					WHERE dgpdr.n_policy_sk_r = fgtr.n_policy_skey_r
					  AND dgpdr.n_policy_version_number_r = fgtr.N_TXN_VERSION_NUMBER_R
					  AND dgpdr.N_SOURCE_SYSTEM_KEY_R=fgtr.N_SOURCE_SYSTEM_KEY_R
					  AND fgtr.V_BUS_OBJ_STATUS_R = 'ACTIVE'
					)
	   AND dgpdr.n_policy_sk_r = fgpr.n_policy_sk_r
	   AND dgpdr.n_policy_version_number_r=fgpr.n_version_number_r
	   AND dgpdr.V_SOURCE_SYSTEM_NAME_R <> 'EIS'
	   AND dgpdr.n_policy_sk_r = ft.n_policy_skey_r
	   AND   dgpdr.n_policy_version_number_r = ft.N_TXN_VERSION_NUMBER_R
	   AND dgpdr.N_SOURCE_SYSTEM_KEY_R=ft.N_SOURCE_SYSTEM_KEY_R
	   AND EXISTS (SELECT 1
				     FROM rpt_policy_dtl_r rpt
				    WHERE rpt.n_policy_sk_r= fgpr.n_policy_sk_r
				      AND rpt.n_yearmonth_r= gn_current_month
				  )
	        )
	WHERE rnk = 1
	GROUP BY n_policy_sk_r,d_calculated_expiry_date_r;

    TYPE var_upd_tbl_nxtrenewaldt_type IS TABLE OF cur_upd_nxtrenewaldt_col%ROWTYPE INDEX BY BINARY_INTEGER;
    lt_var_upd_tbl_nxtrenewaldt_typ_rec var_upd_tbl_nxtrenewaldt_type;

	--Cursor to fetch d_rate_guar_r
	CURSOR cur_upd_d_rate_guar_r_col
	IS
	SELECT d_rate_guar_r,n_policy_sk_r
	  FROM
		  stg_perf_ameritas_renewal_info
	 GROUP BY d_rate_guar_r,n_policy_sk_r;
	  TYPE var_upd_tbl_d_rate_guar_r_type IS TABLE OF cur_upd_d_rate_guar_r_col%ROWTYPE INDEX BY BINARY_INTEGER;
	  lt_var_upd_tbl_d_rate_guar_r_typ_rec var_upd_tbl_d_rate_guar_r_type;
	--16/10/24 changes ends

    --21/10/24 changes starts
    CURSOR cur_upd_option_col
    IS
    SELECT rowid row_id,
    	CASE
            WHEN NOT t6327792.v_eap_eff_date_r IS NULL
			THEN t6327792.v_eap_eff_date_r
            WHEN NOT t6327792.v_bereavedate_r IS NULL
			THEN t6327792.v_bereavedate_r
            ELSE NULL
         END  d_option_eff_date_r,
        CASE
            WHEN upper(t6327792.v_bereave_desc_r) = 'NO'
             AND upper(t6327792.v_eap_desc_r) IN ( 'NO', 'NONE' )
			THEN 'None'
            WHEN upper(t6327792.v_eap_desc_r) IN ( 'PHONE SUPPORT W/ FOLLOW UP'
			                                     , 'PHONE SUPPORT WITH FOLLOW UP'
                                                 , 'PHONE SUPPORT/FOLLOW UP' )
			THEN 'Phone Support w/Follow Up'
            WHEN upper(t6327792.v_eap_desc_r) = 'FOLLOW UP PLUS 5'
			THEN 'Follow Up +5'
            WHEN upper(t6327792.v_eap_desc_r) = 'PHONE SUPPORT'
			THEN 'Phone Support'
            WHEN t6327792.v_bereave_desc_r = 'YES'
			THEN 'Bereavement'
        END v_option_r,
        CASE
            WHEN upper(t6327792.v_bereave_desc_r) = 'NO'
                 AND upper(t6327792.v_eap_desc_r) IN ( 'NO', 'NONE' )
			THEN 0.0
            WHEN upper(t6327792.v_eap_desc_r) IN ( 'PHONE SUPPORT W/ FOLLOW UP'
			                                     , 'PHONE SUPPORT WITH FOLLOW UP'
                                                 , 'PHONE SUPPORT/FOLLOW UP' )
			THEN 0.485
            WHEN upper(t6327792.v_eap_desc_r) = 'FOLLOW UP PLUS 5'
			THEN 0.69
            WHEN upper(t6327792.v_eap_desc_r) = 'PHONE SUPPORT'
			THEN 0.38
            WHEN upper(t6327792.v_bereave_desc_r) = 'YES'
			THEN 0.003
            ELSE NULL
          END  n_new_option_rate_r
    FROM rpt_policy_dtl_r t6327792 /* D_RPT_POLICY_DTL */
   WHERE n_yearmonth_r = gn_current_month;

    TYPE var_upd_tbl_option_type IS TABLE OF cur_upd_option_col%ROWTYPE INDEX BY BINARY_INTEGER;
    lt_var_upd_tbl_option_typ_rec var_upd_tbl_option_type;

	CURSOR cur_upd_agencycode_cols
	IS
	  select LISTAGG(agent.V_AGENCY_CODE_R, '; ') WITHIN GROUP (ORDER BY agent.n_policy_sk_r,agent.n_reportmonth_r) v_agency_code_r,n_policy_sk_r,n_reportmonth_r
	    from rpt_agent_policy_r agent
	   where n_reportmonth_r = gn_current_month
	     AND EXISTS (SELECT 1
					   FROM rpt_policy_dtl_r policy
					  WHERE policy.n_policy_sk_r = agent.n_policy_sk_r
					    AND policy.n_yearmonth_r=gn_current_month
				  )
    group by n_policy_sk_r, n_reportmonth_r;

	TYPE var_upd_tbl_agencycode_type IS TABLE OF cur_upd_agencycode_cols%ROWTYPE;
	lt_var_upd_tbl_agencycode_typ_rec var_upd_tbl_agencycode_type;

	CURSOR cur_upd_submission_dt
	IS
	SELECT MAX(D_BUSINESS_EFF_START_DATE_R)D_SUBMISSION_DATE_R ,N_POLICY_SK_R
	FROM dim_grp_wrkflw_activity_dtls_r wrkflw
	WHERE
	V_ACTIVE_STATUS_R = 'Y'
	AND V_ACTION_DESCRIPTION_R = 'SOLDQUOTE'
	AND EXISTS(SELECT 1
				 FROM RPT_POLICY_DTL_R rpdr
				WHERE rpdr.n_policy_sk_r=wrkflw.n_policy_sk_r
				  AND rpdr.n_yearmonth_r=gn_current_month
			  )
	GROUP BY N_POLICY_SK_R ;

	TYPE var_upd_tbl_submissiondt_typ IS TABLE OF cur_upd_submission_dt%ROWTYPE INDEX BY BINARY_INTEGER;
	lt_var_upd_tbl_submissiondt_typ_rec var_upd_tbl_submissiondt_typ;


	CURSOR cur_upd_nxtrenewaleffdt_col
	IS
	SELECT fgpr.n_policy_sk_r     AS n_policy_sk_r
	     , max(ft2.d_effective_r) AS D_NEXT_RENEWAL_EFFECTIVE_DATE_R
	  from  fct_grp_policy_r fgpr,
		    dim_grp_policy_dir_r dgpdr,
		   (SELECT N_SOURCE_SYSTEM_KEY_R
		         , N_TXN_VERSION_NUMBER_R
				 , D_EFFECTIVE_R
				 , n_policy_skey_r
				 , V_VERSION_TYPE_R
				 , V_BUS_OBJ_STATUS_R
			  FROM fct_grp_transactions_r
		     WHERE V_BUS_OBJ_STATUS_R in('ACTIVE')
			    OR V_BUS_OBJ_STATUS_R in('TERMINATED')
		    ) ft,--25-Nov-24 Changes added after checking with Erica as part of next guarantee detail report
		   (SELECT N_SOURCE_SYSTEM_KEY_R
		         , N_TXN_VERSION_NUMBER_R
				 , D_EFFECTIVE_R
				 , n_policy_skey_r
				 , V_VERSION_TYPE_R
				 , V_BUS_OBJ_STATUS_R
			  FROM fct_grp_transactions_r
		     WHERE V_VERSION_TYPE_R IN ('RENEWAL', 'NEWBUS')  -- OPT-12: ORDER BY removed from inline view (no guaranteed ordering)
		    )ft2
	  WHERE dgpdr.n_policy_sk_r = fgpr.n_policy_sk_r
		AND dgpdr.n_policy_version_number_r=fgpr.n_version_number_r
		AND dgpdr.V_SOURCE_SYSTEM_NAME_R <> 'EIS'
		AND dgpdr.n_policy_sk_r = ft.n_policy_skey_r
		AND dgpdr.n_policy_version_number_r = ft.N_TXN_VERSION_NUMBER_R
		AND dgpdr.N_SOURCE_SYSTEM_KEY_R=ft.N_SOURCE_SYSTEM_KEY_R
		AND ft.n_policy_skey_r = ft2.n_policy_skey_r


		AND ft2.d_effective_r <= ft.d_effective_r
	    AND EXISTS (SELECT 1
				      FROM rpt_policy_dtl_r rpt
				     WHERE rpt.n_policy_sk_r= fgpr.n_policy_sk_r
				       AND rpt.n_yearmonth_r= gn_current_month
				    )
	 group by fgpr.n_policy_sk_r;

	TYPE var_upd_tbl_nxtrenewaleffdt_type IS TABLE OF cur_upd_nxtrenewaleffdt_col%ROWTYPE INDEX BY BINARY_INTEGER;
    lt_var_upd_tbl_nxtrenewaleffdt_typ_rec var_upd_tbl_nxtrenewaleffdt_type;

	CURSOR cur_upd_inforceindicator_cols IS
	SELECT /*+PARALLEL(4)*/ a.n_policy_sk_r,
		  CASE
			WHEN a.n_annualized_premium_r <> 0 AND NVL(a.N_YTD_PRIOR_PREMIUM_R,0) = 0
			THEN 'New'
			WHEN a.n_annualized_premium_r <> 0 AND NVL(a.N_YTD_PRIOR_PREMIUM_R,0) <> 0
			THEN 'Existing'
			WHEN a.n_annualized_premium_r = 0 AND NVL(a.N_YTD_PRIOR_PREMIUM_R,0) <> 0
			THEN 'Lapse'
			ELSE 'Lapse'
		  END V_POLICY_INFORCE_INDICATOR_R
	    , SUM (nvl(a.N_ANNUALIZED_PREMIUM_R,0)) N_ANNUALIZED_PREMIUM_R  -- 11-02-2025 ADDED
	FROM -- 24-03-25 Change Start
		--FCT_RPT_ANN_PREM_SUMMARY_R
	   ( SELECT NVL(SUM(N_YTD_PRIOR_PREMIUM_R),0)  AS N_YTD_PRIOR_PREMIUM_R
			  , NVL(SUM(N_ANNUALIZED_PREMIUM_R),0) AS N_ANNUALIZED_PREMIUM_R
			  , N_POLICY_SK_R                      AS N_POLICY_SK_R
			  , D_CYCLE_DATE_R                     AS D_CYCLE_DATE_R
			FROM FCT_RPT_ANN_PREM_SUMMARY_R
	    GROUP BY N_POLICY_SK_R,D_CYCLE_DATE_R
		) a,
	-- 24-03-25 Change End
	    RPT_POLICY_DTL_R b
	WHERE a.n_policy_sk_r = b.n_policy_sk_r
	  AND a.D_CYCLE_DATE_R >= TRUNC(TO_DATE(TO_CHAR(gn_current_month), 'YYYYMM'), 'MM')  -- OPT-03: sargable range replaces TO_CHAR on column
	  AND a.D_CYCLE_DATE_R <  ADD_MONTHS(TRUNC(TO_DATE(TO_CHAR(gn_current_month), 'YYYYMM'), 'MM'), 1)
	  AND b.n_yearmonth_r = gn_current_month
	  -- OPT-04: redundant EXISTS(RPT_POLICY_DTL_R) removed - join to b already enforces this filter
	  group by a.n_policy_sk_r
			 , CASE
				WHEN a.n_annualized_premium_r <> 0 AND NVL(a.N_YTD_PRIOR_PREMIUM_R,0) = 0
				THEN 'New'
				WHEN a.n_annualized_premium_r <> 0 AND NVL(a.N_YTD_PRIOR_PREMIUM_R,0) <> 0
				THEN 'Existing'
				WHEN a.n_annualized_premium_r = 0 AND NVL(a.N_YTD_PRIOR_PREMIUM_R,0) <> 0
				THEN 'Lapse'
				ELSE 'Lapse'
			   END;
	TYPE var_upd_tbl_inforceindicator_type IS TABLE OF cur_upd_inforceindicator_cols%ROWTYPE;
	lt_var_upd_tbl_inforceindicator_typ_rec var_upd_tbl_inforceindicator_type;

    ln_rec_cnt          PLS_INTEGER	                                    := 0 ;

BEGIN

---Update PROCEDURE
	/*START:NEW LOGGING MECHANISM CHANGES*/
	gv_trcmsg:='9.1 Update v_client_name_r starts from main ';
	gt_start_time := SYSTIMESTAMP;
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                     => gn_out_job_id
					,p_batch_id_r                   => gn_sysdt_batchid
					,p_message_type_r               => GV_MESSAGE_TYPE
					,p_code_location_r              => gv_main_loadedby
					,p_message_r                    => gv_trcmsg
					,p_count_type_r                 => gv_count_type_upd
					,p_count_r                      => NULL
					,p_duration_r                   => NULL
					,p_created_by_r                 => gv_job_name
					,out_prcs_job_log_message_id_r  => gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/

    OPEN cur_upd_client_dtls;
    LOOP
      lt_var_upd_tbl_client_typ_rec.DELETE;
      FETCH cur_upd_client_dtls BULK COLLECT INTO lt_var_upd_tbl_client_typ_rec LIMIT gn_bulk_coll_cnt;
      FORALL X IN lt_var_upd_tbl_client_typ_rec.FIRST .. lt_var_upd_tbl_client_typ_rec.LAST
        UPDATE rpt_policy_dtl_r
           SET v_client_name_r = lt_var_upd_tbl_client_typ_rec(X).v_client_name_r
         WHERE n_cust_party_sk_r = lt_var_upd_tbl_client_typ_rec(X).n_cust_party_sk_r
           AND n_yearmonth_r = gn_current_month;

      COMMIT;
      EXIT WHEN cur_upd_client_dtls%NOTFOUND;
    END LOOP;
	CLOSE cur_upd_client_dtls;  -- OPT-08: cursor was left open


	/*START: NEW LOGGING MECHANISM CHANGES*/

	gt_end_time := SYSTIMESTAMP;
	  gv_trcmsg :='9.2 Update v_client_name_r Completed from main';
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                    	=> gn_out_job_id
					,p_batch_id_r                  	=> gn_sysdt_batchid
					,p_message_type_r              	=> GV_MESSAGE_TYPE
					,p_code_location_r             	=> gv_main_loadedby
					,p_message_r                   	=> gv_trcmsg
					,p_count_type_r                	=> gv_count_type_upd
					,p_count_r                     	=> ln_rec_cnt
					,p_duration_r                  	=> FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
					,p_created_by_r                	=> gv_job_name
					,out_prcs_job_log_message_id_r 	=> gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/


	-- M-0031+M-0058+M-0073+M-0074 (compound): prc_load_data_dim_gtt call removed

	/*START:NEW LOGGING MECHANISM CHANGES*/
	gv_trcmsg:='9.5 Update v_prs_strs_ind_r Start from main';
	gt_start_time := SYSTIMESTAMP;
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                     => gn_out_job_id
					,p_batch_id_r                   => gn_sysdt_batchid
					,p_message_type_r               => GV_MESSAGE_TYPE
					,p_code_location_r              => gv_main_loadedby
					,p_message_r                    => gv_trcmsg
					,p_count_type_r                 => gv_count_type_upd
					,p_count_r                      => NULL
					,p_duration_r                   => NULL
					,p_created_by_r                 => gv_job_name
					,out_prcs_job_log_message_id_r  => gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/

    OPEN cur_upd_prs_strs_ind_r;
	LOOP
      lt_var_upd_prs_strs_indp_rec.DELETE;
      FETCH cur_upd_prs_strs_ind_r BULK COLLECT INTO lt_var_upd_prs_strs_indp_rec LIMIT gn_bulk_coll_cnt;
      FORALL X IN lt_var_upd_prs_strs_indp_rec.FIRST .. lt_var_upd_prs_strs_indp_rec.LAST
    UPDATE RPT_POLICY_DTL_R
	  SET v_prs_strs_ind_r= lt_var_upd_prs_strs_indp_rec(X).v_prs_strs_ind_r
	WHERE n_policy_sk_r=lt_var_upd_prs_strs_indp_rec(X).n_policy_sk_r
	  AND n_yearmonth_r=gn_current_month;
       COMMIT;
      EXIT WHEN cur_upd_prs_strs_ind_r%NOTFOUND;
    END LOOP;
	CLOSE cur_upd_prs_strs_ind_r;

    -- 07-04-2025 addition start
    /* 11-07-2025 Start Commented as per as not required
    OPEN cur_upd_v_plan_duration_r;
	LOOP
      lt_var_upd_v_plan_duration_r.DELETE;
      FETCH cur_upd_v_plan_duration_r BULK COLLECT INTO lt_var_upd_v_plan_duration_r LIMIT gn_bulk_coll_cnt;
      FORALL X IN lt_var_upd_v_plan_duration_r.FIRST .. lt_var_upd_v_plan_duration_r.LAST
    UPDATE RPT_POLICY_DTL_R
	  SET V_PLAN_DURATION_R= lt_var_upd_v_plan_duration_r(X).V_PLAN_DURATION_R
	WHERE n_policy_sk_r=lt_var_upd_v_plan_duration_r(X).n_policy_sk_r
	  AND n_yearmonth_r=gn_current_month;
       COMMIT;
      EXIT WHEN cur_upd_v_plan_duration_r%NOTFOUND;
    END LOOP;
	CLOSE cur_upd_v_plan_duration_r;
    -- 07-04-2025 addition end
    -- 11-07-2025 end Commented as per as not required */

	/*START: NEW LOGGING MECHANISM CHANGES*/
	gt_end_time := SYSTIMESTAMP;
	gv_trcmsg:='9.6 Update v_prs_strs_ind_r Completed from main';
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                    	=> gn_out_job_id
					,p_batch_id_r                  	=> gn_sysdt_batchid
					,p_message_type_r              	=> GV_MESSAGE_TYPE
					,p_code_location_r             	=> gv_main_loadedby
					,p_message_r                   	=> gv_trcmsg
					,p_count_type_r                	=> gv_count_type_upd
					,p_count_r                     	=> ln_rec_cnt
					,p_duration_r                  	=> FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
					,p_created_by_r                	=> gv_job_name
					,out_prcs_job_log_message_id_r 	=> gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/

	/*START:NEW LOGGING MECHANISM CHANGES*/
	gv_trcmsg:='9.7 Update D_UW_CYCLE_DATE_R,D_UW_LAST_UPDATE_DATE_R and few other columns Start from main';
	gt_start_time := SYSTIMESTAMP;
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                     => gn_out_job_id
					,p_batch_id_r                   => gn_sysdt_batchid
					,p_message_type_r               => GV_MESSAGE_TYPE
					,p_code_location_r              => gv_main_loadedby
					,p_message_r                    => gv_trcmsg
					,p_count_type_r                 => gv_count_type_upd
					,p_count_r                      => NULL
					,p_duration_r                   => NULL
					,p_created_by_r                 => gv_job_name
					,out_prcs_job_log_message_id_r  => gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/


	OPEN cur_upd_uw_dtls;
	LOOP
      lt_var_upd_tbl_uw_typ_rec.DELETE;
      FETCH cur_upd_uw_dtls BULK COLLECT INTO lt_var_upd_tbl_uw_typ_rec LIMIT gn_bulk_coll_cnt;
      FORALL X IN lt_var_upd_tbl_uw_typ_rec.FIRST .. lt_var_upd_tbl_uw_typ_rec.LAST
    UPDATE RPT_POLICY_DTL_R
	  SET D_UW_CYCLE_DATE_R= lt_var_upd_tbl_uw_typ_rec(X).D_UW_CYCLE_DATE_R,
		  D_UW_LAST_UPDATE_DATE_R= lt_var_upd_tbl_uw_typ_rec(X).D_UW_LAST_UPDATE_DATE_R
		  --03/08/24 changes starts
		  ,D_UW_NEXT_RENEWAL_DATE_R          = lt_var_upd_tbl_uw_typ_rec(X).D_UW_NEXT_RENEWAL_DATE_R
		  ,V_UW_NEEDED_UNDERWRITER_NAME_R    = lt_var_upd_tbl_uw_typ_rec(X).V_UW_NEEDED_UNDERWRITER_NAME_R
		  ,V_UW_NEEDED_COMMENTS_R            = lt_var_upd_tbl_uw_typ_rec(X).V_UW_NEEDED_COMMENTS_R
		  ,N_UW_NEEDED_PERCENT_R             = lt_var_upd_tbl_uw_typ_rec(X).N_UW_NEEDED_PERCENT_R
		  ,V_UW_NEEDED_RENEWAL_STATUS_R      = lt_var_upd_tbl_uw_typ_rec(X).V_UW_NEEDED_RENEWAL_STATUS_R
		  ,N_UW_REQUESTED_PERCENT_R          = lt_var_upd_tbl_uw_typ_rec(X).N_UW_REQUESTED_PERCENT_R
		  ,V_UW_TRK_NEEDED_UW_NAME_R         = lt_var_upd_tbl_uw_typ_rec(X).V_UW_TRK_NEEDED_UW_NAME_R
		  ,V_UW_TRK_NEEDED_COMMENTS_R        = lt_var_upd_tbl_uw_typ_rec(X).V_UW_TRK_NEEDED_COMMENTS_R
		  ,N_UW_TRK_NEEDED_PERCENT_R         = lt_var_upd_tbl_uw_typ_rec(X).N_UW_TRK_NEEDED_PERCENT_R
		  ,V_UW_TRK_NEEDED_RENEW_STATUS_R    = lt_var_upd_tbl_uw_typ_rec(X).V_UW_TRK_NEEDED_RENEW_STATUS_R
		  ,N_UW_TRK_REQUESTED_PERCENT_R      = lt_var_upd_tbl_uw_typ_rec(X).N_UW_TRK_REQUESTED_PERCENT_R
		  --03/08/24 changes ends
	WHERE n_policy_sk_r=lt_var_upd_tbl_uw_typ_rec(X).n_policy_sk_r
	  AND N_YEARMONTH_R=gn_current_month;
       COMMIT;
      EXIT WHEN cur_upd_uw_dtls%NOTFOUND;
    END LOOP;
	CLOSE cur_upd_uw_dtls;

	/*START: NEW LOGGING MECHANISM CHANGES*/
	gt_end_time := SYSTIMESTAMP;
	gv_trcmsg:='9.8 Update D_UW_CYCLE_DATE_R,D_UW_LAST_UPDATE_DATE_R and few other columns Completed from main';
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                    	=> gn_out_job_id
					,p_batch_id_r                  	=> gn_sysdt_batchid
					,p_message_type_r              	=> GV_MESSAGE_TYPE
					,p_code_location_r             	=> gv_main_loadedby
					,p_message_r                   	=> gv_trcmsg
					,p_count_type_r                	=> gv_count_type_upd
					,p_count_r                     	=> ln_rec_cnt
					,p_duration_r                  	=> FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
					,p_created_by_r                	=> gv_job_name
					,out_prcs_job_log_message_id_r 	=> gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/

    /*START:NEW LOGGING MECHANISM CHANGES*/
	gv_trcmsg:='9.9 Update V_ID_THEFT_IND_R Start from main';
	gt_start_time := SYSTIMESTAMP;
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                     => gn_out_job_id
					,p_batch_id_r                   => gn_sysdt_batchid
					,p_message_type_r               => GV_MESSAGE_TYPE
					,p_code_location_r              => gv_main_loadedby
					,p_message_r                    => gv_trcmsg
					,p_count_type_r                 => gv_count_type_upd
					,p_count_r                      => NULL
					,p_duration_r                   => NULL
					,p_created_by_r                 => gv_job_name
					,out_prcs_job_log_message_id_r  => gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/

	OPEN cur_upd_theft_ind_col;
	LOOP
      lt_var_upd_tbl_theft_ind_typ_rec.DELETE;
      FETCH cur_upd_theft_ind_col BULK COLLECT INTO lt_var_upd_tbl_theft_ind_typ_rec LIMIT gn_bulk_coll_cnt;
      FORALL X IN lt_var_upd_tbl_theft_ind_typ_rec.FIRST .. lt_var_upd_tbl_theft_ind_typ_rec.LAST
    UPDATE RPT_POLICY_DTL_R
	  SET V_ID_THEFT_IND_R      = lt_var_upd_tbl_theft_ind_typ_rec(X).V_ID_THEFT_IND_R
	WHERE n_policy_sk_r=lt_var_upd_tbl_theft_ind_typ_rec(X).n_policy_sk_r
	  AND N_YEARMONTH_R=gn_current_month;

       COMMIT;
      EXIT WHEN cur_upd_theft_ind_col%NOTFOUND;
    END LOOP;
	CLOSE cur_upd_theft_ind_col;

	/*START: NEW LOGGING MECHANISM CHANGES*/
	gt_end_time := SYSTIMESTAMP;
	gv_trcmsg:='9.10 Update V_ID_THEFT_IND_R Completed from main';
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                    	=> gn_out_job_id
					,p_batch_id_r                  	=> gn_sysdt_batchid
					,p_message_type_r              	=> GV_MESSAGE_TYPE
					,p_code_location_r             	=> gv_main_loadedby
					,p_message_r                   	=> gv_trcmsg
					,p_count_type_r                	=> gv_count_type_upd
					,p_count_r                     	=> ln_rec_cnt
					,p_duration_r                  	=> FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
					,p_created_by_r                	=> gv_job_name
					,out_prcs_job_log_message_id_r 	=> gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/

	/*START:NEW LOGGING MECHANISM CHANGES*/
	gv_trcmsg:='9.11 Update D_ID_THEFT_DATE_R Start from main';
	gt_start_time := SYSTIMESTAMP;
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                     => gn_out_job_id
					,p_batch_id_r                   => gn_sysdt_batchid
					,p_message_type_r               => GV_MESSAGE_TYPE
					,p_code_location_r              => gv_main_loadedby
					,p_message_r                    => gv_trcmsg
					,p_count_type_r                 => gv_count_type_upd
					,p_count_r                      => NULL
					,p_duration_r                   => NULL
					,p_created_by_r                 => gv_job_name
					,out_prcs_job_log_message_id_r  => gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/
	OPEN cur_upd_theft_dt_col;
	LOOP
      LT_VAR_UPD_TBL_THEFT_DT_TYP_REC.DELETE;
      FETCH cur_upd_theft_dt_col BULK COLLECT INTO LT_VAR_UPD_TBL_THEFT_DT_TYP_REC LIMIT gn_bulk_coll_cnt;
	  FOR x IN LT_VAR_UPD_TBL_THEFT_DT_TYP_REC.first .. LT_VAR_UPD_TBL_THEFT_DT_TYP_REC.LAST
	  LOOP
     ld_theft_dt:=null;
	    BEGIN
		   ld_theft_dt := TO_DATE(LT_VAR_UPD_TBL_THEFT_DT_TYP_REC(x).v_override_description_r, 'MM/DD/YYYY');  -- OPT-07: direct assignment replaces SELECT FROM DUAL
		   LT_VAR_UPD_TBL_THEFT_DT_TYP_REC(x).d_id_theft_date_r := ld_theft_dt;
			 LT_VAR_UPD_TBL_THEFT_DT_TYP_REC(x).d_id_theft_date_r:=ld_theft_dt;
		EXCEPTION
		EXCEPTION WHEN OTHERS THEN                                              -- OPT-06: log instead of swallowing
		    gv_errmsg := SUBSTR(SQLERRM, 1, 4000);
		    gv_trcmsg := 'Error parsing theft date: ' || gv_errmsg;
		    -- non-fatal: continue processing remaining rows
		END;
	  END LOOP;
      FORALL X IN LT_VAR_UPD_TBL_THEFT_DT_TYP_REC.FIRST .. LT_VAR_UPD_TBL_THEFT_DT_TYP_REC.LAST
    UPDATE RPT_POLICY_DTL_R
	  SET D_ID_THEFT_DATE_R = LT_VAR_UPD_TBL_THEFT_DT_TYP_REC(X).d_id_theft_date_r
	WHERE n_policy_sk_r     = LT_VAR_UPD_TBL_THEFT_DT_TYP_REC(X).n_policy_sk_r
	  AND N_YEARMONTH_R=gn_current_month;
       COMMIT;
      EXIT WHEN cur_upd_theft_dt_col%NOTFOUND;
    END LOOP;
	CLOSE cur_upd_theft_dt_col;

	/*START: NEW LOGGING MECHANISM CHANGES*/
	gt_end_time := SYSTIMESTAMP;
	gv_trcmsg:='9.12 Update D_ID_THEFT_DATE_R Completed from main';
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                    	=> gn_out_job_id
					,p_batch_id_r                  	=> gn_sysdt_batchid
					,p_message_type_r              	=> GV_MESSAGE_TYPE
					,p_code_location_r             	=> gv_main_loadedby
					,p_message_r                   	=> gv_trcmsg
					,p_count_type_r                	=> gv_count_type_upd
					,p_count_r                     	=> ln_rec_cnt
					,p_duration_r                  	=> FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
					,p_created_by_r                	=> gv_job_name
					,out_prcs_job_log_message_id_r 	=> gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/

	/*START:NEW LOGGING MECHANISM CHANGES*/
	gv_trcmsg:='9.13 START: UPDATE N_ANY_OCC_DAYS_REMAINING_R COLUMN';
	gt_start_time := SYSTIMESTAMP;
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                     => gn_out_job_id
					,p_batch_id_r                   => gn_sysdt_batchid
					,p_message_type_r               => GV_MESSAGE_TYPE
					,p_code_location_r              => gv_main_loadedby
					,p_message_r                    => gv_trcmsg
					,p_count_type_r                 => gv_count_type_upd
					,p_count_r                      => NULL
					,p_duration_r                   => NULL
					,p_created_by_r                 => gv_job_name
					,out_prcs_job_log_message_id_r  => gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/
	OPEN cur_upd_elimperiod_col;
	LOOP
      lt_var_upd_tbl_elimperiod_typ_rec.DELETE;
      FETCH cur_upd_elimperiod_col BULK COLLECT INTO lt_var_upd_tbl_elimperiod_typ_rec LIMIT gn_bulk_coll_cnt;
      FORALL X IN lt_var_upd_tbl_elimperiod_typ_rec.FIRST .. lt_var_upd_tbl_elimperiod_typ_rec.LAST
      UPDATE RPT_POLICY_DTL_R
	    SET V_ELIM_PERIOD_R   = lt_var_upd_tbl_elimperiod_typ_rec(X).V_ELIM_PERIOD_R
	  WHERE n_policy_sk_r     = lt_var_upd_tbl_elimperiod_typ_rec(X).n_policy_sk_r
	    AND N_YEARMONTH_R=gn_current_month;
       COMMIT;
      EXIT WHEN cur_upd_elimperiod_col%NOTFOUND;
    END LOOP;
	CLOSE cur_upd_elimperiod_col;

	/*START: NEW LOGGING MECHANISM CHANGES*/
	gt_end_time := SYSTIMESTAMP;
	gv_trcmsg:='9.14 Update V_ELIM_PERIOD_R Completed from main ';
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                    	=> gn_out_job_id
					,p_batch_id_r                  	=> gn_sysdt_batchid
					,p_message_type_r              	=> GV_MESSAGE_TYPE
					,p_code_location_r             	=> gv_main_loadedby
					,p_message_r                   	=> gv_trcmsg
					,p_count_type_r                	=> gv_count_type_upd
					,p_count_r                     	=> ln_rec_cnt
					,p_duration_r                  	=> FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
					,p_created_by_r                	=> gv_job_name
					,out_prcs_job_log_message_id_r 	=> gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/

    /*START:NEW LOGGING MECHANISM CHANGES*/
	gv_trcmsg:='9.15 Update Cross Sell cols Start from main';
	gt_start_time := SYSTIMESTAMP;
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                     => gn_out_job_id
					,p_batch_id_r                   => gn_sysdt_batchid
					,p_message_type_r               => GV_MESSAGE_TYPE
					,p_code_location_r              => gv_main_loadedby
					,p_message_r                    => gv_trcmsg
					,p_count_type_r                 => gv_count_type_upd
					,p_count_r                      => NULL
					,p_duration_r                   => NULL
					,p_created_by_r                 => gv_job_name
					,out_prcs_job_log_message_id_r  => gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/

	OPEN cur_upd_cross_sell_col;
	LOOP
      lt_var_upd_tbl_cross_sell_typ.DELETE;
      FETCH cur_upd_cross_sell_col BULK COLLECT INTO lt_var_upd_tbl_cross_sell_typ LIMIT gn_bulk_coll_cnt;
      FORALL X IN lt_var_upd_tbl_cross_sell_typ.FIRST .. lt_var_upd_tbl_cross_sell_typ.LAST
    UPDATE RPT_POLICY_DTL_R
	  SET  v_cross_sell_indicator_r       = lt_var_upd_tbl_cross_sell_typ(X).v_cross_sell_indicator_r
		  ,v_6mnth_cross_sell_indicator_r = lt_var_upd_tbl_cross_sell_typ(X).v_6mnth_cross_sell_indicator_r
		  ,v_any_lob_cross_sell_r         = lt_var_upd_tbl_cross_sell_typ(X).v_any_lob_cross_sell_r
	      ,v_ltd_cross_sell_r             = lt_var_upd_tbl_cross_sell_typ(X).v_ltd_cross_sell_r
	      ,v_std_cross_sell_r             = lt_var_upd_tbl_cross_sell_typ(X).v_std_cross_sell_r
	      ,v_life_cross_sell_r            = lt_var_upd_tbl_cross_sell_typ(X).v_life_cross_sell_r
	      ,v_basic_life_cross_sell_r      = lt_var_upd_tbl_cross_sell_typ(X).v_basic_life_cross_sell_r
	      ,v_supp_life_cross_sell_r       = lt_var_upd_tbl_cross_sell_typ(X).v_supp_life_cross_sell_r
	      ,v_dep_life_cross_sell_r        = lt_var_upd_tbl_cross_sell_typ(X).v_dep_life_cross_sell_r
	      ,v_add_cross_sell_r             = lt_var_upd_tbl_cross_sell_typ(X).v_add_cross_sell_r
	      ,v_sr_cross_sell_r              = lt_var_upd_tbl_cross_sell_typ(X).v_sr_cross_sell_r
	      ,v_var_cross_sell_r             = lt_var_upd_tbl_cross_sell_typ(X).v_var_cross_sell_r
	      ,v_vai_cross_sell_r             = lt_var_upd_tbl_cross_sell_typ(X).v_vai_cross_sell_r
	      ,v_vci_cross_sell_r             = lt_var_upd_tbl_cross_sell_typ(X).v_vci_cross_sell_r
	      ,n_total_product_lines_r        = lt_var_upd_tbl_cross_sell_typ(X).n_total_product_lines_r
	WHERE n_policy_sk_r     = lt_var_upd_tbl_cross_sell_typ(X).n_policy_sk_r
	  AND n_yearmonth_r=gn_current_month;
       COMMIT;
      EXIT WHEN cur_upd_cross_sell_col%NOTFOUND;
    END LOOP;
	CLOSE cur_upd_cross_sell_col;

	/*START: NEW LOGGING MECHANISM CHANGES*/
	gt_end_time := SYSTIMESTAMP;
	   gv_trcmsg:='9.16 Update upd_cross_sell_col Completed from main';
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                    	=> gn_out_job_id
					,p_batch_id_r                  	=> gn_sysdt_batchid
					,p_message_type_r              	=> GV_MESSAGE_TYPE
					,p_code_location_r             	=> gv_main_loadedby
					,p_message_r                   	=> gv_trcmsg
					,p_count_type_r                	=> gv_count_type_upd
					,p_count_r                     	=> ln_rec_cnt
					,p_duration_r                  	=> FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
					,p_created_by_r                	=> gv_job_name
					,out_prcs_job_log_message_id_r 	=> gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/

    /*START:NEW LOGGING MECHANISM CHANGES*/
	gv_trcmsg:='9.17 Update v_eap_desc_r Start from main';
	gt_start_time := SYSTIMESTAMP;
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                     => gn_out_job_id
					,p_batch_id_r                   => gn_sysdt_batchid
					,p_message_type_r               => GV_MESSAGE_TYPE
					,p_code_location_r              => gv_main_loadedby
					,p_message_r                    => gv_trcmsg
					,p_count_type_r                 => gv_count_type_upd
					,p_count_r                      => NULL
					,p_duration_r                   => NULL
					,p_created_by_r                 => gv_job_name
					,out_prcs_job_log_message_id_r  => gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/

	OPEN cur_upd_eap_desc_col;
	LOOP
      lt_var_upd_tbl_eap_desc_typ_rec.DELETE;
      FETCH cur_upd_eap_desc_col BULK COLLECT INTO lt_var_upd_tbl_eap_desc_typ_rec LIMIT gn_bulk_coll_cnt;
      FORALL X IN lt_var_upd_tbl_eap_desc_typ_rec.FIRST .. lt_var_upd_tbl_eap_desc_typ_rec.LAST
      UPDATE RPT_POLICY_DTL_R
	    SET v_eap_desc_r   = lt_var_upd_tbl_eap_desc_typ_rec(X).v_eap_desc_r
		,V_COVERAGE_CODE_R  = lt_var_upd_tbl_eap_desc_typ_rec(X).V_COVERAGE_CODE_R
	  WHERE n_policy_sk_r     = lt_var_upd_tbl_eap_desc_typ_rec(X).n_policy_sk_r
	    AND N_YEARMONTH_R=gn_current_month;
       COMMIT;
      EXIT WHEN cur_upd_eap_desc_col%NOTFOUND;
    END LOOP;
	CLOSE cur_upd_eap_desc_col;

	/*START: NEW LOGGING MECHANISM CHANGES*/
	gt_end_time := SYSTIMESTAMP;
	gv_trcmsg:='9.18 Update v_eap_desc_r Completed from main';
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                    	=> gn_out_job_id
					,p_batch_id_r                  	=> gn_sysdt_batchid
					,p_message_type_r              	=> GV_MESSAGE_TYPE
					,p_code_location_r             	=> gv_main_loadedby
					,p_message_r                   	=> gv_trcmsg
					,p_count_type_r                	=> gv_count_type_upd
					,p_count_r                     	=> ln_rec_cnt
					,p_duration_r                  	=> FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
					,p_created_by_r                	=> gv_job_name
					,out_prcs_job_log_message_id_r 	=> gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/

	/*START:NEW LOGGING MECHANISM CHANGES*/
	gv_trcmsg:='9.19 Update V_BEREAVE_DESC_R Start from main';
	gt_start_time := SYSTIMESTAMP;
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                     => gn_out_job_id
					,p_batch_id_r                   => gn_sysdt_batchid
					,p_message_type_r               => GV_MESSAGE_TYPE
					,p_code_location_r              => gv_main_loadedby
					,p_message_r                    => gv_trcmsg
					,p_count_type_r                 => gv_count_type_upd
					,p_count_r                      => NULL
					,p_duration_r                   => NULL
					,p_created_by_r                 => gv_job_name
					,out_prcs_job_log_message_id_r  => gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/

	OPEN cur_upd_bereave_desc_col;
	LOOP
      lt_var_upd_tbl_bereave_desc_typ_rec.DELETE;
      FETCH cur_upd_bereave_desc_col BULK COLLECT INTO lt_var_upd_tbl_bereave_desc_typ_rec LIMIT gn_bulk_coll_cnt;
      FORALL X IN lt_var_upd_tbl_bereave_desc_typ_rec.FIRST .. lt_var_upd_tbl_bereave_desc_typ_rec.LAST
      UPDATE RPT_POLICY_DTL_R
	    SET V_BEREAVE_DESC_R   = lt_var_upd_tbl_bereave_desc_typ_rec(X).V_BEREAVE_DESC_R
	  WHERE n_policy_sk_r     = lt_var_upd_tbl_bereave_desc_typ_rec(X).n_policy_sk_r
	    AND N_YEARMONTH_R=gn_current_month;
       COMMIT;
      EXIT WHEN cur_upd_bereave_desc_col%NOTFOUND;
    END LOOP;
	CLOSE cur_upd_bereave_desc_col;

	/*START: NEW LOGGING MECHANISM CHANGES*/
	gt_end_time := SYSTIMESTAMP;
	gv_trcmsg:='9.20 Update V_BEREAVE_DESC_R Completed from main';
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                    	=> gn_out_job_id
					,p_batch_id_r                  	=> gn_sysdt_batchid
					,p_message_type_r              	=> GV_MESSAGE_TYPE
					,p_code_location_r             	=> gv_main_loadedby
					,p_message_r                   	=> gv_trcmsg
					,p_count_type_r                	=> gv_count_type_upd
					,p_count_r                     	=> ln_rec_cnt
					,p_duration_r                  	=> FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
					,p_created_by_r                	=> gv_job_name
					,out_prcs_job_log_message_id_r 	=> gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/

	/*START:NEW LOGGING MECHANISM CHANGES*/
	gv_trcmsg:='9.21 Update V_EAP_EFF_DATE_R Start from main ';
	gt_start_time := SYSTIMESTAMP;
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                     => gn_out_job_id
					,p_batch_id_r                   => gn_sysdt_batchid
					,p_message_type_r               => GV_MESSAGE_TYPE
					,p_code_location_r              => gv_main_loadedby
					,p_message_r                    => gv_trcmsg
					,p_count_type_r                 => gv_count_type_upd
					,p_count_r                      => NULL
					,p_duration_r                   => NULL
					,p_created_by_r                 => gv_job_name
					,out_prcs_job_log_message_id_r  => gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/
	OPEN cur_upd_eap_eff_date_col;
	LOOP
      lt_var_upd_tbl_eap_eff_date_typ_rec.DELETE;
      FETCH cur_upd_eap_eff_date_col BULK COLLECT INTO lt_var_upd_tbl_eap_eff_date_typ_rec LIMIT gn_bulk_coll_cnt;
      FORALL X IN lt_var_upd_tbl_eap_eff_date_typ_rec.FIRST .. lt_var_upd_tbl_eap_eff_date_typ_rec.LAST
      UPDATE RPT_POLICY_DTL_R
	    SET V_EAP_EFF_DATE_R   = lt_var_upd_tbl_eap_eff_date_typ_rec(X).V_EAP_EFF_DATE_R
	  WHERE n_policy_sk_r     = lt_var_upd_tbl_eap_eff_date_typ_rec(X).n_policy_sk_r
	    AND N_YEARMONTH_R=gn_current_month;
       COMMIT;
      EXIT WHEN cur_upd_eap_eff_date_col%NOTFOUND;
    END LOOP;
	CLOSE cur_upd_eap_eff_date_col;

	/*START: NEW LOGGING MECHANISM CHANGES*/
	gt_end_time := SYSTIMESTAMP;
	gv_trcmsg:='9.22 Update V_EAP_EFF_DATE_R Completed from main';
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                    	=> gn_out_job_id
					,p_batch_id_r                  	=> gn_sysdt_batchid
					,p_message_type_r              	=> GV_MESSAGE_TYPE
					,p_code_location_r             	=> gv_main_loadedby
					,p_message_r                   	=> gv_trcmsg
					,p_count_type_r                	=> gv_count_type_upd
					,p_count_r                     	=> ln_rec_cnt
					,p_duration_r                  	=> FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
					,p_created_by_r                	=> gv_job_name
					,out_prcs_job_log_message_id_r 	=> gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/

	/*START:NEW LOGGING MECHANISM CHANGES*/
	gv_trcmsg:='9.23 Update V_BEREAVEDATE_R Start from main ';
	gt_start_time := SYSTIMESTAMP;
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                     => gn_out_job_id
					,p_batch_id_r                   => gn_sysdt_batchid
					,p_message_type_r               => GV_MESSAGE_TYPE
					,p_code_location_r              => gv_main_loadedby
					,p_message_r                    => gv_trcmsg
					,p_count_type_r                 => gv_count_type_upd
					,p_count_r                      => NULL
					,p_duration_r                   => NULL
					,p_created_by_r                 => gv_job_name
					,out_prcs_job_log_message_id_r  => gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/

	OPEN cur_upd_bereavedate_col;
	LOOP
      lt_var_upd_tbl_bereavedate_typ_rec.DELETE;
      FETCH cur_upd_bereavedate_col BULK COLLECT INTO lt_var_upd_tbl_bereavedate_typ_rec LIMIT gn_bulk_coll_cnt;
      FORALL X IN lt_var_upd_tbl_bereavedate_typ_rec.FIRST .. lt_var_upd_tbl_bereavedate_typ_rec.LAST
      UPDATE RPT_POLICY_DTL_R
	    SET V_BEREAVEDATE_R   = lt_var_upd_tbl_bereavedate_typ_rec(X).V_BEREAVEDATE_R
	  WHERE n_policy_sk_r     = lt_var_upd_tbl_bereavedate_typ_rec(X).n_policy_sk_r
	    AND N_YEARMONTH_R=gn_current_month;
       COMMIT;
      EXIT WHEN cur_upd_bereavedate_col%NOTFOUND;
    END LOOP;
	CLOSE cur_upd_bereavedate_col;

	/*START: NEW LOGGING MECHANISM CHANGES*/
	gt_end_time := SYSTIMESTAMP;
	gv_trcmsg:='9.24 Update V_BEREAVEDATE_R Completed from main';
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                    	=> gn_out_job_id
					,p_batch_id_r                  	=> gn_sysdt_batchid
					,p_message_type_r              	=> GV_MESSAGE_TYPE
					,p_code_location_r             	=> gv_main_loadedby
					,p_message_r                   	=> gv_trcmsg
					,p_count_type_r                	=> gv_count_type_upd
					,p_count_r                     	=> ln_rec_cnt
					,p_duration_r                  	=> FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
					,p_created_by_r                	=> gv_job_name
					,out_prcs_job_log_message_id_r 	=> gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/

	/*START:NEW LOGGING MECHANISM CHANGES*/
	gv_trcmsg:='9.25 Update D_NEXT_RENEWAL_DATE_R Start from main ';
	gt_start_time := SYSTIMESTAMP;
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                     => gn_out_job_id
					,p_batch_id_r                   => gn_sysdt_batchid
					,p_message_type_r               => GV_MESSAGE_TYPE
					,p_code_location_r              => gv_main_loadedby
					,p_message_r                    => gv_trcmsg
					,p_count_type_r                 => gv_count_type_upd
					,p_count_r                      => NULL
					,p_duration_r                   => NULL
					,p_created_by_r                 => gv_job_name
					,out_prcs_job_log_message_id_r  => gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/
    OPEN cur_upd_nxtrenewaldt_col;
    LOOP
    lt_var_upd_tbl_nxtrenewaldt_typ_rec.DELETE;
    FETCH cur_upd_nxtrenewaldt_col BULK COLLECT INTO lt_var_upd_tbl_nxtrenewaldt_typ_rec LIMIT gn_bulk_coll_cnt;
    FORALL X IN lt_var_upd_tbl_nxtrenewaldt_typ_rec.FIRST .. lt_var_upd_tbl_nxtrenewaldt_typ_rec.LAST
        UPDATE RPT_POLICY_DTL_R
        SET D_NEXT_RENEWAL_DATE_R = lt_var_upd_tbl_nxtrenewaldt_typ_rec(X).D_NEXT_RENEWAL_DATE_R--,
            --D_NEXT_RENEWAL_EFFECTIVE_DATE_R = lt_var_upd_tbl_nxtrenewaldt_typ_rec(X).D_NEXT_RENEWAL_EFFECTIVE_DATE_R--15/11/24 changes commented
        WHERE n_policy_sk_r = lt_var_upd_tbl_nxtrenewaldt_typ_rec(X).n_policy_sk_r
          AND N_YEARMONTH_R = gn_current_month;
      COMMIT;
      EXIT WHEN cur_upd_nxtrenewaldt_col%NOTFOUND;
    END LOOP;
	CLOSE cur_upd_nxtrenewaldt_col;

	/*START: NEW LOGGING MECHANISM CHANGES*/
	gt_end_time := SYSTIMESTAMP;
	gv_trcmsg:='9.26 Update D_NEXT_RENEWAL_DATE_R Completed from main';
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                    	=> gn_out_job_id
					,p_batch_id_r                  	=> gn_sysdt_batchid
					,p_message_type_r              	=> GV_MESSAGE_TYPE
					,p_code_location_r             	=> gv_main_loadedby
					,p_message_r                   	=> gv_trcmsg
					,p_count_type_r                	=> gv_count_type_upd
					,p_count_r                     	=> ln_rec_cnt
					,p_duration_r                  	=> FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
					,p_created_by_r                	=> gv_job_name
					,out_prcs_job_log_message_id_r 	=> gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/

	/*START:NEW LOGGING MECHANISM CHANGES*/
	gv_trcmsg:='9.27 Update d_rate_guar_r Start from main ';
	gt_start_time := SYSTIMESTAMP;
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                     => gn_out_job_id
					,p_batch_id_r                   => gn_sysdt_batchid
					,p_message_type_r               => GV_MESSAGE_TYPE
					,p_code_location_r              => gv_main_loadedby
					,p_message_r                    => gv_trcmsg
					,p_count_type_r                 => gv_count_type_upd
					,p_count_r                      => NULL
					,p_duration_r                   => NULL
					,p_created_by_r                 => gv_job_name
					,out_prcs_job_log_message_id_r  => gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/

	OPEN cur_upd_d_rate_guar_r_col;
	LOOP
      lt_var_upd_tbl_d_rate_guar_r_typ_rec.DELETE;
      FETCH cur_upd_d_rate_guar_r_col BULK COLLECT INTO lt_var_upd_tbl_d_rate_guar_r_typ_rec LIMIT gn_bulk_coll_cnt;
      FORALL X IN lt_var_upd_tbl_d_rate_guar_r_typ_rec.FIRST .. lt_var_upd_tbl_d_rate_guar_r_typ_rec.LAST
      UPDATE RPT_POLICY_DTL_R
	    SET d_rate_guar_r   = lt_var_upd_tbl_d_rate_guar_r_typ_rec(X).d_rate_guar_r
	  WHERE n_policy_sk_r     = lt_var_upd_tbl_d_rate_guar_r_typ_rec(X).n_policy_sk_r
	    AND N_YEARMONTH_R=gn_current_month;
       COMMIT;
      EXIT WHEN cur_upd_d_rate_guar_r_col%NOTFOUND;
    END LOOP;
	CLOSE cur_upd_d_rate_guar_r_col;

	/*START: NEW LOGGING MECHANISM CHANGES*/
	gt_end_time := SYSTIMESTAMP;
	gv_trcmsg:='9.28 Update d_rate_guar_r Completed from main';
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                    	=> gn_out_job_id
					,p_batch_id_r                  	=> gn_sysdt_batchid
					,p_message_type_r              	=> GV_MESSAGE_TYPE
					,p_code_location_r             	=> gv_main_loadedby
					,p_message_r                   	=> gv_trcmsg
					,p_count_type_r                	=> gv_count_type_upd
					,p_count_r                     	=> ln_rec_cnt
					,p_duration_r                  	=> FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
					,p_created_by_r                	=> gv_job_name
					,out_prcs_job_log_message_id_r 	=> gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/

	/*START:NEW LOGGING MECHANISM CHANGES*/
	gv_trcmsg:='9.29 Update option cols Start from main ';
	gt_start_time := SYSTIMESTAMP;
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                     => gn_out_job_id
					,p_batch_id_r                   => gn_sysdt_batchid
					,p_message_type_r               => GV_MESSAGE_TYPE
					,p_code_location_r              => gv_main_loadedby
					,p_message_r                    => gv_trcmsg
					,p_count_type_r                 => gv_count_type_upd
					,p_count_r                      => NULL
					,p_duration_r                   => NULL
					,p_created_by_r                 => gv_job_name
					,out_prcs_job_log_message_id_r  => gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/

	OPEN cur_upd_option_col;
	LOOP
      lt_var_upd_tbl_option_typ_rec.DELETE;
      FETCH cur_upd_option_col BULK COLLECT INTO lt_var_upd_tbl_option_typ_rec LIMIT gn_bulk_coll_cnt;
      FORALL X IN lt_var_upd_tbl_option_typ_rec.FIRST .. lt_var_upd_tbl_option_typ_rec.LAST
      UPDATE RPT_POLICY_DTL_R
	    SET d_option_eff_date_r   = lt_var_upd_tbl_option_typ_rec(X).d_option_eff_date_r
	      , v_option_r            = lt_var_upd_tbl_option_typ_rec(X).v_option_r
	      , n_new_option_rate_r   = lt_var_upd_tbl_option_typ_rec(X).n_new_option_rate_r
	  WHERE rowid     = lt_var_upd_tbl_option_typ_rec(X).row_id
	    AND N_YEARMONTH_R=gn_current_month;
       COMMIT;
      EXIT WHEN cur_upd_option_col%NOTFOUND;
    END LOOP;
	CLOSE cur_upd_option_col;

	/*START: NEW LOGGING MECHANISM CHANGES*/
	gt_end_time := SYSTIMESTAMP;
	gv_trcmsg:='9.30 Update option cols Completed from main';
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                    	=> gn_out_job_id
					,p_batch_id_r                  	=> gn_sysdt_batchid
					,p_message_type_r              	=> GV_MESSAGE_TYPE
					,p_code_location_r             	=> gv_main_loadedby
					,p_message_r                   	=> gv_trcmsg
					,p_count_type_r                	=> gv_count_type_upd
					,p_count_r                     	=> ln_rec_cnt
					,p_duration_r                  	=> FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
					,p_created_by_r                	=> gv_job_name
					,out_prcs_job_log_message_id_r 	=> gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/

	/*START:NEW LOGGING MECHANISM CHANGES*/
	gv_trcmsg:='9.31 Update v_agency_code_r Start from main ';
	gt_start_time := SYSTIMESTAMP;
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                     => gn_out_job_id
					,p_batch_id_r                   => gn_sysdt_batchid
					,p_message_type_r               => GV_MESSAGE_TYPE
					,p_code_location_r              => gv_main_loadedby
					,p_message_r                    => gv_trcmsg
					,p_count_type_r                 => gv_count_type_upd
					,p_count_r                      => NULL
					,p_duration_r                   => NULL
					,p_created_by_r                 => gv_job_name
					,out_prcs_job_log_message_id_r  => gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/

	OPEN cur_upd_agencycode_cols;
    LOOP
        FETCH cur_upd_agencycode_cols BULK COLLECT INTO lt_var_upd_tbl_agencycode_typ_rec LIMIT gn_bulk_coll_cnt; -- OPP-14: was LIMIT 10000
        EXIT WHEN lt_var_upd_tbl_agencycode_typ_rec.COUNT = 0;
        FORALL X IN 1 .. lt_var_upd_tbl_agencycode_typ_rec.COUNT
        UPDATE rpt_policy_dtl_r
           SET v_agency_code_r = lt_var_upd_tbl_agencycode_typ_rec(X).v_agency_code_r
         WHERE n_policy_sk_r = lt_var_upd_tbl_agencycode_typ_rec(X).n_policy_sk_r
           AND n_yearmonth_r = gn_current_month;
        COMMIT;
    END LOOP;
    CLOSE cur_upd_agencycode_cols;

	/*START: NEW LOGGING MECHANISM CHANGES*/
	gt_end_time := SYSTIMESTAMP;
	gv_trcmsg:='9.32 Update v_agency_code_r  Completed from main';
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                    	=> gn_out_job_id
					,p_batch_id_r                  	=> gn_sysdt_batchid
					,p_message_type_r              	=> GV_MESSAGE_TYPE
					,p_code_location_r             	=> gv_main_loadedby
					,p_message_r                   	=> gv_trcmsg
					,p_count_type_r                	=> gv_count_type_upd
					,p_count_r                     	=> ln_rec_cnt
					,p_duration_r                  	=> FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
					,p_created_by_r                	=> gv_job_name
					,out_prcs_job_log_message_id_r 	=> gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/

	/*START:NEW LOGGING MECHANISM CHANGES*/
	gv_trcmsg:='9.33 Update D_SUBMISSION_DATE_R Start from main ';
	gt_start_time := SYSTIMESTAMP;
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                     => gn_out_job_id
					,p_batch_id_r                   => gn_sysdt_batchid
					,p_message_type_r               => GV_MESSAGE_TYPE
					,p_code_location_r              => gv_main_loadedby
					,p_message_r                    => gv_trcmsg
					,p_count_type_r                 => gv_count_type_upd
					,p_count_r                      => NULL
					,p_duration_r                   => NULL
					,p_created_by_r                 => gv_job_name
					,out_prcs_job_log_message_id_r  => gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/

    OPEN cur_upd_submission_dt;
    LOOP
    lt_var_upd_tbl_submissiondt_typ_rec.DELETE;
    FETCH cur_upd_submission_dt BULK COLLECT INTO lt_var_upd_tbl_submissiondt_typ_rec LIMIT gn_bulk_coll_cnt;
    FORALL X IN lt_var_upd_tbl_submissiondt_typ_rec.FIRST .. lt_var_upd_tbl_submissiondt_typ_rec.LAST
        UPDATE RPT_POLICY_DTL_R
        SET D_SUBMISSION_DATE_R = lt_var_upd_tbl_submissiondt_typ_rec(X).D_SUBMISSION_DATE_R
        WHERE n_policy_sk_r = lt_var_upd_tbl_submissiondt_typ_rec(X).n_policy_sk_r
          AND N_YEARMONTH_R = gn_current_month;
      COMMIT;
      EXIT WHEN cur_upd_submission_dt%NOTFOUND;
    END LOOP;
	CLOSE cur_upd_submission_dt;

	/*START: NEW LOGGING MECHANISM CHANGES*/
	gt_end_time := SYSTIMESTAMP;
	gv_trcmsg:='9.34 Update D_SUBMISSION_DATE_R  Completed from main';
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                    	=> gn_out_job_id
					,p_batch_id_r                  	=> gn_sysdt_batchid
					,p_message_type_r              	=> GV_MESSAGE_TYPE
					,p_code_location_r             	=> gv_main_loadedby
					,p_message_r                   	=> gv_trcmsg
					,p_count_type_r                	=> gv_count_type_upd
					,p_count_r                     	=> ln_rec_cnt
					,p_duration_r                  	=> FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
					,p_created_by_r                	=> gv_job_name
					,out_prcs_job_log_message_id_r 	=> gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/

	/*START:NEW LOGGING MECHANISM CHANGES*/
	gv_trcmsg:='9.35 Update D_NEXT_RENEWAL_EFFECTIVE_DATE_R Start from main ';
	gt_start_time := SYSTIMESTAMP;
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                     => gn_out_job_id
					,p_batch_id_r                   => gn_sysdt_batchid
					,p_message_type_r               => GV_MESSAGE_TYPE
					,p_code_location_r              => gv_main_loadedby
					,p_message_r                    => gv_trcmsg
					,p_count_type_r                 => gv_count_type_upd
					,p_count_r                      => NULL
					,p_duration_r                   => NULL
					,p_created_by_r                 => gv_job_name
					,out_prcs_job_log_message_id_r  => gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/

    OPEN cur_upd_nxtrenewaleffdt_col;
    LOOP
    lt_var_upd_tbl_nxtrenewaleffdt_typ_rec.DELETE;
    FETCH cur_upd_nxtrenewaleffdt_col BULK COLLECT INTO lt_var_upd_tbl_nxtrenewaleffdt_typ_rec LIMIT gn_bulk_coll_cnt;
    FORALL X IN lt_var_upd_tbl_nxtrenewaleffdt_typ_rec.FIRST .. lt_var_upd_tbl_nxtrenewaleffdt_typ_rec.LAST
        UPDATE RPT_POLICY_DTL_R
        SET D_NEXT_RENEWAL_EFFECTIVE_DATE_R = lt_var_upd_tbl_nxtrenewaleffdt_typ_rec(X).D_NEXT_RENEWAL_EFFECTIVE_DATE_R
        WHERE n_policy_sk_r = lt_var_upd_tbl_nxtrenewaleffdt_typ_rec(X).n_policy_sk_r
          AND N_YEARMONTH_R = gn_current_month;
       COMMIT;
      EXIT WHEN cur_upd_nxtrenewaleffdt_col%NOTFOUND;
    END LOOP;
	CLOSE cur_upd_nxtrenewaleffdt_col;

	/*START: NEW LOGGING MECHANISM CHANGES*/
	gt_end_time := SYSTIMESTAMP;
	gv_trcmsg:='9.36 Update D_NEXT_RENEWAL_EFFECTIVE_DATE_R  Completed from main';
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                    	=> gn_out_job_id
					,p_batch_id_r                  	=> gn_sysdt_batchid
					,p_message_type_r              	=> GV_MESSAGE_TYPE
					,p_code_location_r             	=> gv_main_loadedby
					,p_message_r                   	=> gv_trcmsg
					,p_count_type_r                	=> gv_count_type_upd
					,p_count_r                     	=> ln_rec_cnt
					,p_duration_r                  	=> FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
					,p_created_by_r                	=> gv_job_name
					,out_prcs_job_log_message_id_r 	=> gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/

	/*START:NEW LOGGING MECHANISM CHANGES*/
	gv_trcmsg:='9.37 Update V_POLICY_INFORCE_INDICATOR_R Start from main ';
	gt_start_time := SYSTIMESTAMP;
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                     => gn_out_job_id
					,p_batch_id_r                   => gn_sysdt_batchid
					,p_message_type_r               => GV_MESSAGE_TYPE
					,p_code_location_r              => gv_main_loadedby
					,p_message_r                    => gv_trcmsg
					,p_count_type_r                 => gv_count_type_upd
					,p_count_r                      => NULL
					,p_duration_r                   => NULL
					,p_created_by_r                 => gv_job_name
					,out_prcs_job_log_message_id_r  => gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/

    BEGIN
     OPEN cur_upd_inforceindicator_cols;
     LOOP
      FETCH cur_upd_inforceindicator_cols BULK COLLECT INTO lt_var_upd_tbl_inforceindicator_typ_rec LIMIT gn_bulk_coll_cnt;
      EXIT WHEN lt_var_upd_tbl_inforceindicator_typ_rec.COUNT = 0;
      FORALL X IN 1 .. lt_var_upd_tbl_inforceindicator_typ_rec.COUNT
      UPDATE RPT_POLICY_DTL_R
         SET V_POLICY_INFORCE_INDICATOR_R = lt_var_upd_tbl_inforceindicator_typ_rec(X).V_POLICY_INFORCE_INDICATOR_R
           , N_ANNUALIZED_PREMIUM_R = lt_var_upd_tbl_inforceindicator_typ_rec(X).N_ANNUALIZED_PREMIUM_R
       WHERE n_policy_sk_r = lt_var_upd_tbl_inforceindicator_typ_rec(X).n_policy_sk_r
         AND n_yearmonth_r = gn_current_month;
     END LOOP;
     COMMIT;
     CLOSE cur_upd_inforceindicator_cols;
     END;

	/*START: NEW LOGGING MECHANISM CHANGES*/
	gt_end_time := SYSTIMESTAMP;
	gv_trcmsg:='9.38 Update V_POLICY_INFORCE_INDICATOR_R  Completed from main';
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                    	=> gn_out_job_id
					,p_batch_id_r                  	=> gn_sysdt_batchid
					,p_message_type_r              	=> GV_MESSAGE_TYPE
					,p_code_location_r             	=> gv_main_loadedby
					,p_message_r                   	=> gv_trcmsg
					,p_count_type_r                	=> gv_count_type_upd
					,p_count_r                     	=> ln_rec_cnt
					,p_duration_r                  	=> FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
					,p_created_by_r                	=> gv_job_name
					,out_prcs_job_log_message_id_r 	=> gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/
  EXCEPTION
    WHEN OTHERS THEN
        GV_ERRMSG :=SUBSTR(SQLERRM,1,4000);
        gv_trcmsg:='9.z Error in prc_upd_col_details';
        /*START: NEW LOGGING MECHANISM CHANGES*/
            pkg_grp_log_util.prc_update_log_message_r ( n_prcs_job_log_message_id_r => GN_JOB_LOG_MESSAGE_ID,
                                                                          p_err_msg => gv_trcmsg
                                                       );
        /*END: NEW LOGGING MECHANISM CHANGES*/
        pkg_grp_log_util.prc_update_log
              ( gn_out_job_id
                ,GV_ERROR_STATUS
                ,GV_ERRMSG
                ,gv_trcmsg||GV_ERRMSG
                ,GV_dummyrec_loadedby
              );
        RAISE;
  END PRC_UPD_COL_DETAILS;

PROCEDURE prc_get_cur_data  --prc_get_cur_data(p_out_cursor OUT SYS_REFCURSOR) -- Kill/Fill Changes 5th May 2026
/**************************************************************************************
  Purpose:  Procedure is used to get the latest data and perform ref_cursor assignment.

  Usage:	This procedure accepts one output parameters,output Variables: p_out_cursor: Used to perform ref cursor assignment

---------- -------- -------------------------------------------------
  VGireesh   10/11/23 Developed first Version
  Suresh     12/08/25 Standardization of Code
  Shiva		 08-May-2026	Kill/Fill: Added Partition Exchange to address reporitng data availability
*******************************************************************************/
AS
BEGIN
       gv_trcmsg:='6.1 Entered into prc_get_cur_data ';

	   	/*START: NEW LOGGING MECHANISM CHANGES*/
		GT_START_TIME:= SYSTIMESTAMP;

		 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
		 (
			p_job_id_r                    => gn_out_job_id,
			p_batch_id_r                  => gn_sysdt_batchid,
			p_message_type_r              => GV_MESSAGE_TYPE,
			p_code_location_r             => GV_getcur_loadedby,
			p_message_r                   => gv_trcmsg,
			p_count_type_r                => NULL,
			p_count_r                     => NULL,
			p_duration_r                  => NULL,
			p_created_by_r                => GV_JOB_NAME,
			out_prcs_job_log_message_id_r => GN_JOB_LOG_MESSAGE_ID
		);
		/*END: NEW LOGGING MECHANISM CHANGES*/


	-- Start : Kill/Fill Changes 5th May 2026
		EXECUTE IMMEDIATE 'ALTER SESSION ENABLE PARALLEL DML';
	-- End : Kill/Fill Changes 5th May 2026

	-- Start : Kill/Fill Changes 5th May 2026: Commented following
	   --Open/Assign SELECT stmnt
   /* OPEN p_out_cursor FOR */

	-- Start : Kill/Fill Changes 5th May 2026: Added following
	INSERT /*+ APPEND PARALLEL(stg, 8) */ INTO RPT_POLICY_DTL_R_EXG stg
	-- End : Kill/Fill Changes 5th May 2026: Added following
     SELECT /*+ PARALLEL(8) */
	   fct_grp_policy_r.v_administered_by_r                                            AS v_administered_by_r
	 , CASE
	      WHEN UPPER(fct_grp_policy_r.v_brand_name_r) = 'ALEAVEIATE'
		  THEN 'YES'
		  ELSE  NULL
	    END                                                                                 AS v_aleaveiate_ind_r
	 , fct_grp_billing_policy_dtl_r.d_installation_date_r                                   AS d_billing_installation_date_r
	 , fct_grp_policy_r.v_memblock_r                                                        AS v_block_name_r
	 , CASE
	      WHEN nvl(fct_grp_billing_policy_dtl_r.N_CREATE_BILL_R, 0) <> 0
		  THEN 'Yes'
		END                                                                                 AS v_create_bill_ind_r
	 , fct_grp_policy_r.n_num_lives_r                                                       AS n_eligible_num_lives_r
	 , FCT_GRP_POLICY_R.V_MEMEXCHANGE_R                                                     AS V_EXCHANGE_NAME_R
	 , to_date(dim_grp_policy_dir_r.fic_mis_date_r)                                         AS FIC_MIS_DATE_R
	 , dim_grp_policy_dir_r.v_policy_suffix_r v_line_of_business_r
     , lob_map.TARGET_LABEL                                                              AS v_line_of_business_group_r  -- M-0053: CASE replaced with REF_LINE_OF_BUSINESS_GROUP_MAP lookup
	  , CASE
	       WHEN fct_grp_policy_r.V_SOURCE_SYSTEM_NAME_R = 'EIS'
		   THEN fct_grp_policy_r.d_renewal_date_r
           ELSE FCT_GRP_POLICY_R.D_CALCULATED_EXPIRY_DATE_R
          END 																				 AS d_next_renewal_date_r
	  , CASE
	       WHEN dim_grp_udfield_r.v_field2_r = 1
		   THEN 'Y'
		   ELSE 'N'
		 END     																			 AS v_nsc_indicator_r
	  , dim_grp_policy_dir_r.v_orig_lob_r                                    		         AS v_orig_lob_r
	  , FCT_GRP_POLICY_R.N_PARTICIPATING_NUM_LIVES_R                                         AS N_PARTICIPATING_NUM_LIVES_R
      , CASE
	        WHEN fct_grp_policy_r.n_participating_num_lives_r IS NULL
			THEN 'Blank'
		    WHEN fct_grp_policy_r.n_participating_num_lives_r < 100
			THEN '<100'
            WHEN fct_grp_policy_r.n_participating_num_lives_r < 500
			THEN '100-500'
			WHEN fct_grp_policy_r.n_participating_num_lives_r < 2000
			THEN '500-2000'
			ELSE '>=2000'
		  END                                                                                 AS v_participating_num_lives_bucket_r
		, fct_grp_transactions_r.v_visualid_r                                                 AS v_policy_visual_id_r
		, fct_grp_policy_r.v_anniversary_date_and_month_r                                     AS v_policy_anniversary_date_r
		, FCT_GRP_BILLING_POLICY_DTL_R.V_BILL_CATEGORY_R                                      AS V_BILL_CATEGORY_R
		, TO_CHAR(fct_grp_billing_policy_dtl_r.n_billing_option_value_r)                           AS v_bill_option_r
-- M-0053: deferred - range-based + smartchoice_ind_r flag override requires analyst review before REF table conversion
		, CASE
		     WHEN fct_grp_policy_r.v_smartchoice_ind_r = 'Y'
			 THEN 'Smart Choice'
             WHEN fct_grp_policy_r.n_policy_lives_r < 100
			 THEN '<100'
             WHEN fct_grp_policy_r.n_policy_lives_r BETWEEN 100 AND 299
			 THEN '100-299'
             WHEN fct_grp_policy_r.n_policy_lives_r BETWEEN 300 AND 499
			 THEN '300-499'
             WHEN fct_grp_policy_r.n_policy_lives_r BETWEEN 500 AND 999
			 THEN '500-999'
             WHEN fct_grp_policy_r.n_policy_lives_r BETWEEN 1000 AND 1999
			 THEN '1,000-1,999'
             WHEN fct_grp_policy_r.n_policy_lives_r BETWEEN 2000 AND 2999
			 THEN '2,000-2,999'
             WHEN fct_grp_policy_r.n_policy_lives_r BETWEEN 3000 AND 4999
			 THEN '3,000-4,999'
             WHEN fct_grp_policy_r.n_policy_lives_r >= 5000
             THEN '5,000+'
             ELSE 'Blank'
		   END                                                                                 AS v_policy_case_size_r
		 , CASE
		      WHEN fct_grp_policy_r.n_policy_lives_r < 500
			  THEN '<500'
		      WHEN fct_grp_policy_r.n_policy_lives_r BETWEEN 500 AND 1999
			  THEN '500-1,999'
		      WHEN fct_grp_policy_r.n_policy_lives_r >= 2000
			  THEN '2,000+'
		    END                                                                                AS v_policy_case_size_group_r
		, dim_grp_policy_dir_r.n_policy_sk_r                                                   AS n_policy_count_r
		, CASE  WHEN DIM_GRP_POLICY_DIR_R.V_SOURCE_SYSTEM_NAME_R ='EIS'
				THEN NVL(CAST(POLICY_DIR_EFF_DATE.T_POLICY_EFFECTIVE_DATE_R_1 AS DATE),
						CAST(POLICY_DIR_EFF_DATE.T_POLICY_EFFECTIVE_DATE_R_0 AS DATE))
				ELSE
				CAST(DIM_GRP_POLICY_DIR_R.T_POLICY_EFFECTIVE_DATE_R AS DATE)
		  END
          AS D_POLICY_EFFECTIVE_DATE_R
        , EXTRACT( YEAR  FROM dim_grp_policy_dir_r.t_policy_effective_date_r)                  AS v_policy_effective_year_r
		, fct_grp_policy_r.d_installation_date_r                                               AS d_policy_installation_date_r
		, dim_grp_policy_dir_r.v_policy_prefix_r                                               AS v_policy_prefix_r
        , CASE
		     WHEN UPPER(fct_grp_transactions_r.v_bus_obj_status_r) LIKE '%TERMINATED%'
		 	 THEN 'Cancelled'
		 	 ELSE 'Active'
		   END                                                                                 AS v_policy_status_r
		, DIM_GRP_POLICY_DIR_R.V_POLICY_SUFFIX_R                                               AS V_POLICY_SUFFIX_R
        , CASE
      		WHEN LENGTH(CASE
							WHEN FCT_GRP_TRANSACTIONS_R.V_BUS_OBJ_STATUS_R IN('BOUNDTERMINATE', 'TERMINATED', 'CANCELREINSTATE')
							THEN FCT_GRP_TRANSACTIONS_R.D_EFFECTIVE_R
							ELSE  NULL
		                END
					   ) > 0
	        THEN 'T'
            ELSE ' '
          END                                                                                  AS v_policy_terminated_ind_r
        , CASE
		      WHEN fct_grp_transactions_r.v_bus_obj_status_r IN ('BOUNDTERMINATE', 'TERMINATED', 'CANCELREINSTATE')
		      THEN fct_grp_transactions_r.d_effective_r
			  ELSE  NULL
		   END 		                                                                           AS d_policy_termination_date_r
        , CASE
		      WHEN fct_grp_transactions_r.v_bus_obj_status_r IN ('BOUNDTERMINATE', 'TERMINATED', 'CANCELREINSTATE')
		      THEN fct_grp_policy_r.v_version_reason_code_r
			  ELSE  NULL
		   END 		                                                                           AS v_policy_termination_reason_r
        , CASE
		      WHEN dim_grp_policy_dir_r.v_policy_prefix_r = 'SC'
		      THEN 'IND'
			  ELSE 'GRP'
		   END                                                                                 AS v_policy_type_r
		, dim_grp_policy_dir_r.n_policy_sk_r                                                   AS n_policy_sk_r
		, fct_grp_billing_policy_dtl_r.n_policy_id_r                                           AS n_policy_id_r
		, dim_grp_policy_dir_r.v_policy_number_r                                               AS v_policy_number_r
		, fct_grp_billing_policy_dtl_r.v_policy_status_r                                       AS v_prem_policy_status_r
		, fct_grp_policy_r.n_claims_tax_indicator_r                                            AS n_claims_tax_indicator_r
		, fct_grp_policy_r.v_ratebook_desc_r                                                   AS v_ratebook_desc_r
		, fct_grp_policy_r.v_ratebook_id_r                                                     AS v_ratebook_id_r
		, fct_grp_policy_r.n_renewal_notification_days_r                                       AS n_renewal_notification_days_r
		, fct_grp_policy_r.v_rewrite_indicator_r                                               AS v_rewrite_indicator_r
        , CASE
		     WHEN UPPER(fct_grp_policy_r.v_line_of_business_r) LIKE '%SMALL%'
		     THEN 'Y'
			 ELSE 'N'
		   END 		                                                                           AS v_small_group_ind_r
		, fct_grp_policy_r.v_smartchoice_ind_r                                                 AS v_smartchoice_ind_r
		, dim_grp_policy_dir_r.v_source_system_name_r                                          AS v_source_system_name_r
		, fct_grp_transactions_r.v_originated_from_r                                           AS v_source_version_r
		, fct_grp_policy_r.t_effective_start_date_r                                            AS d_version_effective_date_r
		, fct_grp_policy_r.n_version_number_r                                                  AS n_version_number_r
		, fct_grp_transactions_r.v_bus_obj_status_r                                            AS v_version_status_r
		, fct_grp_transactions_r.v_version_type_r                                              AS v_version_type_r
		, fct_grp_policy_r.n_w2_exclude_fica_match_r                                           AS n_w2_exclude_fica_match_r
		, dim_grp_policy_dir_r.n_batch_id_r                                                    AS n_batch_id_r
		, fct_grp_policy_r.n_cust_party_sk_r                                                   AS n_cust_party_sk_r
		, dim_grp_udfield_r.n_entity_type_id_r                                                 AS n_ud_entity_type_id_r
		, dim_grp_policy_dir_r.d_delete_date_r                                                 AS d_policy_delete_date_r
		, fct_grp_transactions_r.t_event_timestamp_r                                           AS t_transaction_event_timestamp_r
		, fct_grp_policy_r.v_policy_coverage_code_r                                            AS v_policy_coverage_code_r
		, dim_grp_policy_dir_r.n_quote_sk_r                                                    AS n_quote_sk_r
		, fct_grp_billing_policy_dtl_r.d_delete_date_r                                         AS d_billing_policy_delete_date_r
		, fct_grp_policy_r.n_policy_lives_r                                                    AS v_policy_case_size_2_r
        , GV_MAIN_LOADEDBY                                                                     AS v_last_modified_by_r
        , systimestamp                                                                         AS t_creation_date_r
        , GV_MAIN_LOADEDBY                                                                     AS v_created_by_r
        , systimestamp                                                                         AS t_last_modified_date_r
        , gn_current_month                                                                     AS n_yearmonth_r
	    , dim_grp_policy_dir_r.v_active_status_r                                               AS v_rpt_active_status_r
	    , fct_grp_policy_r.v_class_of_business_r                                               AS v_class_of_business_r
	    , fct_grp_policy_r.n_policy_lives_r                                                    AS n_policy_lives_r
        , nvl( fct_grp_policy_r.v_carrier_name_r  ,
		        (case
				    when fct_grp_policy_r.v_administered_by_r = 'RSL'
				    then 'Reliance Standard Life Insurance Company'
					when fct_grp_policy_r.v_administered_by_r = 'FRSLIC'
					then 'First Reliance Standard Life Insurance Company'
                    else null
					end
			     )
			  )	                                                                               AS v_carrier_name_r
		, CAST(NULL AS DATE)                                                                   AS D_UW_NEXT_RENEWAL_DATE_R
        , CAST(NULL AS VARCHAR2(300 CHAR))                                                     AS V_UW_NEEDED_UNDERWRITER_NAME_R
        , CAST(NULL AS VARCHAR2(300 CHAR))                                                     AS V_UW_NEEDED_COMMENTS_R
        , CAST(NULL AS NUMBER)                                                                 AS N_UW_NEEDED_PERCENT_R
        , CAST(NULL AS VARCHAR2(300 CHAR))                                                     AS V_UW_NEEDED_RENEWAL_STATUS_R
        , CAST(NULL AS NUMBER)                                                                 AS N_UW_REQUESTED_PERCENT_R
        , fct_grp_policy_r.d_renewal_date_r                                                    AS D_RENEWAL_DATE_R
        , CAST(NULL AS VARCHAR2(300 CHAR))                                                     AS V_UW_TRK_NEEDED_UW_NAME_R
        , CAST(NULL AS VARCHAR2(300 CHAR))                                                     AS V_UW_TRK_NEEDED_COMMENTS_R
        , CAST(NULL AS NUMBER)                                                                 AS N_UW_TRK_NEEDED_PERCENT_R
        , CAST(NULL AS VARCHAR2(300 CHAR))                                                     AS V_UW_TRK_NEEDED_RENEW_STATUS_R
        , CAST(NULL AS NUMBER)                                                                 AS N_UW_TRK_REQUESTED_PERCENT_R
		, CAST(NULL AS VARCHAR2(300))                                                          AS V_CLIENT_NAME_R
		, CAST(NULL AS VARCHAR2(50))                                                           AS v_prs_strs_ind_r
		, CAST(NULL AS DATE)													               AS D_UW_CYCLE_DATE_R
		, CAST(NULL AS DATE)													               AS D_UW_LAST_UPDATE_DATE_R
		, cast(null as DATE)                                                                   AS D_ID_THEFT_DATE_R
		, cast(null as VARCHAR2(30))                                                           AS V_ID_THEFT_IND_R
		, fct_grp_policy_r.N_ASO_FEE_AMT_R				                                       AS N_ASO_FEE_AMT_R
		, CAST(NULL AS VARCHAR2(300))                                                          AS V_ELIM_PERIOD_R
		, CAST(NULL AS VARCHAR2(10))                                                           AS V_CROSS_SELL_INDICATOR_R
		, CAST(NULL AS VARCHAR2(10))                                                           AS V_6MNTH_CROSS_SELL_INDICATOR_R
		, CAST(NULL AS VARCHAR2(300))                                                          AS V_ANY_LOB_CROSS_SELL_R
		, CAST(NULL AS VARCHAR2(300))                                                          AS V_LTD_CROSS_SELL_R
		, CAST(NULL AS VARCHAR2(300))                                                          AS V_STD_CROSS_SELL_R
		, CAST(NULL AS VARCHAR2(300))                                                          AS V_LIFE_CROSS_SELL_R
		, CAST(NULL AS VARCHAR2(300))                                                          AS V_BASIC_LIFE_CROSS_SELL_R
		, CAST(NULL AS VARCHAR2(300))                                                          AS V_SUPP_LIFE_CROSS_SELL_R
		, CAST(NULL AS VARCHAR2(300))                                                          AS V_DEP_LIFE_CROSS_SELL_R
		, CAST(NULL AS VARCHAR2(300))                                                          AS V_ADD_CROSS_SELL_R
		, CAST(NULL AS VARCHAR2(300))                                                          AS V_SR_CROSS_SELL_R
		, CAST(NULL AS VARCHAR2(300))                                                          AS V_VAR_CROSS_SELL_R
		, CAST(NULL AS VARCHAR2(300))                                                          AS V_VAI_CROSS_SELL_R
		, CAST(NULL AS VARCHAR2(300))                                                          AS V_VCI_CROSS_SELL_R

		, CAST(NULL AS NUMBER)                                                                 AS N_TOTAL_PRODUCT_LINES_R
		, CAST(NULL AS VARCHAR2(3000))                                                         AS V_EAP_DESC_R
		, CAST(NULL AS VARCHAR2(3000))                                                         AS V_BEREAVE_DESC_R
		, CAST(NULL AS VARCHAR2(300))                                                          AS V_EAP_EFF_DATE_R
		, CAST(NULL AS VARCHAR2(300))                                                          AS V_BEREAVEDATE_R
		, CASE
			WHEN fct_grp_policy_r.V_SOURCE_SYSTEM_NAME_R = 'EIS'
			THEN
			CASE WHEN fct_grp_policy_r.N_CLAIMS_TAX_INDICATOR_R = 0 THEN 'N'
				 WHEN fct_grp_policy_r.N_CLAIMS_TAX_INDICATOR_R = 1 THEN 'Y'
				 WHEN fct_grp_policy_r.N_CLAIMS_TAX_INDICATOR_R = 2 THEN 'X'
			END
			WHEN fct_grp_policy_r.N_W2_EXCLUDE_FICA_MATCH_R = 1
		 	 THEN 'X'
            WHEN fct_grp_policy_r.N_CLAIMS_TAX_INDICATOR_R = 1 AND dim_grp_policy_dir_r.V_POLICY_PREFIX_R IN ('ASL', 'ASW')
		 	 THEN 'Y'
            WHEN fct_grp_policy_r.N_CLAIMS_TAX_INDICATOR_R = 1
              AND fct_grp_policy_r.V_CARRIER_NAME_R IN ('First Reliance Standard Life Insurance Company'
			                                          , 'Reliance Standard Life Insurance Company')
             THEN 'Y'
			ELSE 'N' END 																	   AS V_RSL_EIN_IND_R
		, fct_grp_policy_r.N_ASO_SETUP_FEE_AMT_R                                               AS N_ASO_SETUP_FEE_AMT_R
		, CAST(NULL AS VARCHAR2(300))                                                          AS V_COVERAGE_CODE_R
		, CAST(NULL AS DATE)          										                   AS d_rate_guar_r
        , CAST(NULL AS VARCHAR2(100)) 										                   AS d_option_eff_date_r
        , CAST(NULL AS VARCHAR2(100)) 										                   AS v_option_r
        , CAST(NULL AS NUMBER)                   							                   AS n_new_option_rate_r
		, fct_grp_policy_r.N_RATE_GUARANTEE_R                                                  AS N_RATE_GUARANTEE_R
        , CAST(NULL AS DATE)                                                                   AS D_NEXT_RENEWAL_EFFECTIVE_DATE_R
		, CAST(NULL AS VARCHAR2(1000))                                                         AS V_AGENCY_CODE_r
        , CAST (NULL AS DATE)                                                                  AS D_SUBMISSION_DATE_R
		, CAST(NULL AS VARCHAR2(100))                                                          AS V_POLICY_INFORCE_INDICATOR_R
        , CAST(NULL AS NUMBER)                                                                 AS N_ANNUALIZED_PREMIUM_R
     -- , CAST(NULL AS VARCHAR2(50))                                                           AS V_PLAN_DURATION_R        -- 24-06-2025 added as per as FDM Reqt  11-07-2025 Commented as per as not required
        , fct_grp_policy_r.V_DISTRIBUTION_CHANNEL_R                                            AS V_DISTRIBUTION_CHANNEL_R -- 24-06-2025 as per reqt 416953

		,(
			CASE
			WHEN  	dim_grp_policy_dir_r.v_policy_prefix_r LIKE '%ASW%'
					AND
					nvl ( fct_grp_policy_r.v_carrier_name_r  ,
							(case 	when fct_grp_policy_r.v_administered_by_r = 'RSL'
									then 'Reliance Standard Life Insurance Company'
									when fct_grp_policy_r.v_administered_by_r = 'FRSLIC'
									then 'First Reliance Standard Life Insurance Company'
									else
									null
								 end
							)
						)= 'First Reliance Standard Life Insurance Company'
				THEN  nvl( fct_grp_policy_r.v_carrier_name_r  ,
								(case 	when fct_grp_policy_r.v_administered_by_r = 'RSL'
										then 'Reliance Standard Life Insurance Company'
										when fct_grp_policy_r.v_administered_by_r = 'FRSLIC'
										then 'First Reliance Standard Life Insurance Company'
										else
										null
								end
								)
						 )
			WHEN 	dim_grp_policy_dir_r.v_policy_prefix_r LIKE '%ASL%'
					AND
					nvl( fct_grp_policy_r.v_carrier_name_r  ,

							(case 	when fct_grp_policy_r.v_administered_by_r = 'RSL'
									then 'Reliance Standard Life Insurance Company'
									when fct_grp_policy_r.v_administered_by_r = 'FRSLIC'
									then 'First Reliance Standard Life Insurance Company'
									else
									null
							end
							)
						)= 'First Reliance Standard Life Insurance Company'
				THEN  nvl( fct_grp_policy_r.v_carrier_name_r  ,
								(case 	when fct_grp_policy_r.v_administered_by_r = 'RSL'
										then 'Reliance Standard Life Insurance Company'
										when fct_grp_policy_r.v_administered_by_r = 'FRSLIC'
										then 'First Reliance Standard Life Insurance Company'
										else
										null
								end
								)
						 )
            WHEN dim_grp_policy_dir_r.v_policy_prefix_r LIKE '%ASW%'
				THEN 'RSL ADMINISTRATIVE SERVICES'

			WHEN dim_grp_policy_dir_r.v_policy_prefix_r LIKE '%ASL%'
				THEN 'RSL ADMINISTRATIVE SERVICES'

			ELSE nvl( fct_grp_policy_r.v_carrier_name_r  ,
							(case 	when fct_grp_policy_r.v_administered_by_r = 'RSL'
									then 'Reliance Standard Life Insurance Company'
									when fct_grp_policy_r.v_administered_by_r = 'FRSLIC'
									then 'First Reliance Standard Life Insurance Company'
									else
									null
							end
							)
					)

			END
		) 						AS V_CARRIER_NAME_TAX_R
		 FROM ATOMIC.DIM_GRP_POLICY_DIR_R DIM_GRP_POLICY_DIR_R
	        , ATOMIC.FCT_GRP_POLICY_R FCT_GRP_POLICY_R
			,(
				SELECT  N_POLICY_SK_R,  -- OPT-05: DISTINCT removed - redundant with GROUP BY
				  V_POLICY_NUMBER_R,
				  MIN(case when N_POLICY_VERSION_NUMBER_R = 1 THEN T_POLICY_EFFECTIVE_DATE_R END) AS T_POLICY_EFFECTIVE_DATE_R_1,
                  MIN(case when N_POLICY_VERSION_NUMBER_R = 0 THEN T_POLICY_EFFECTIVE_DATE_R END) AS T_POLICY_EFFECTIVE_DATE_R_0
				FROM ATOMIC.DIM_GRP_POLICY_DIR_R
				group by N_POLICY_SK_R,
				V_POLICY_NUMBER_R
			) POLICY_DIR_EFF_DATE
	    ,(SELECT *                                                          -- OPT-02: ROW_NUMBER() replaces per-row correlated MAX subquery
		    FROM (SELECT a.*,
		                 ROW_NUMBER() OVER (PARTITION BY a.N_POLICY_SK_R
		                                       ORDER BY a.T_EVENT_TIMESTAMP_R DESC) AS rn
		            FROM ATOMIC.FCT_GRP_BILLING_POLICY_DTL_R a
		           WHERE a.D_DELETE_DATE_R IS NULL
		             AND a.N_POLICY_ID_R NOT IN (68215,64819))
		   WHERE rn = 1
          ) FCT_GRP_BILLING_POLICY_DTL_R
         ,(SELECT *
		    FROM (SELECT RANK() OVER ( PARTITION BY NVL(N_SOURCE_SYSTEM_KEY_R, -1)
												      , N_VERSION_NUMBER_R
												      , N_POLICY_SKEY_R
											ORDER BY N_BATCH_ID_R DESC
												   , T_EVENT_TIMESTAMP_R DESC
												   , N_TXN_VERSION_NUMBER_R DESC
                                     ) RNK,
                  A.*
            FROM ATOMIC.FCT_GRP_TRANSACTIONS_R A
           WHERE N_POLICY_SKEY_R <> -1
             AND V_SOURCE_SYSTEM_NAME_R IN ('EIS', 'PACS')) X WHERE RNK = 1
			) FCT_GRP_TRANSACTIONS_R
	    , atomic.dim_grp_udfield_r  dim_grp_udfield_r
     LEFT JOIN REF_LINE_OF_BUSINESS_GROUP_MAP lob_map
            ON lob_map.SOURCE_CODE = dim_grp_policy_dir_r.v_policy_prefix_r
	WHERE dim_grp_policy_dir_r.v_active_status_r ='Y'
	  AND fct_grp_policy_r.n_policy_sk_r=dim_grp_policy_dir_r.n_policy_sk_r
	  AND fct_grp_billing_policy_dtl_r.n_policy_sk_r(+)=dim_grp_policy_dir_r.n_policy_sk_r
	  and FCT_GRP_POLICY_R.N_VERSION_NUMBER_R=DIM_GRP_POLICY_DIR_R.N_POLICY_VERSION_NUMBER_R
      and nvl(FCT_GRP_POLICY_R.N_SOURCE_SYSTEM_KEY_R,999999) = nvl(DIM_GRP_POLICY_DIR_R.N_SOURCE_SYSTEM_KEY_R,999999)
      AND FCT_GRP_POLICY_R.N_POLICY_SK_R = DIM_GRP_POLICY_DIR_R.N_POLICY_SK_R
      AND fct_grp_transactions_r.n_policy_skey_r=dim_grp_policy_dir_r.n_policy_sk_r
	  and FCT_GRP_TRANSACTIONS_R.N_VERSION_NUMBER_R=DIM_GRP_POLICY_DIR_R.N_POLICY_VERSION_NUMBER_R
      and nvl(fct_grp_transactions_r.N_SOURCE_SYSTEM_KEY_R,-1)=nvl(DIM_GRP_POLICY_DIR_R.N_SOURCE_SYSTEM_KEY_R,-1) --29-Mar-2024 Erica changes  due to shinka
      and DIM_GRP_UDFIELD_R.N_ENTITY_ID_R(+) = FCT_GRP_BILLING_POLICY_DTL_R.N_POLICY_ID_R
      and DIM_GRP_UDFIELD_R.N_ENTITY_TYPE_ID_R(+) = 200
      and DIM_GRP_POLICY_DIR_R.n_policy_sk_r = POLICY_DIR_EFF_DATE.n_policy_sk_r(+);


	gn_run_cnt:= SQL%ROWCOUNT;

	-- Start : Kill/Fill Changes 5th May 2026: Commented following
	COMMIT;
	EXECUTE IMMEDIATE 'ALTER SESSION DISABLE PARALLEL DML';
	-- End : Kill/Fill Changes 5th May 2026

    gv_trcmsg:='6.2 Exit from prc_get_cur_data - Rows Loaded :->'||gn_run_cnt;

	/*START: NEW LOGGING MECHANISM CHANGES*/
        gt_end_time := SYSTIMESTAMP;
        PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
                (    p_job_id_r                    => gn_out_job_id
                    ,p_batch_id_r                  => gn_sysdt_batchid
                    ,p_message_type_r              => gv_message_type
                    ,p_code_location_r             => gv_getcur_loadedby
                    ,p_message_r                   => gv_trcmsg
                    ,p_count_type_r                => 'AUDIT_TARGET_COUNT'
                    ,p_count_r                     => gn_run_cnt
                    ,p_duration_r                  => FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
                    ,p_created_by_r                => GV_JOB_NAME
                    ,out_prcs_job_log_message_id_r => gn_job_log_message_id
                    );
        /*END: NEW LOGGING MECHANISM CHANGES*/
EXCEPTION
WHEN OTHERS THEN
    GV_ERRMSG :=SUBSTR(SQLERRM,1,4000);
    gv_trcmsg:='6.z Error in prc_get_cur_data';

	/*START: NEW LOGGING MECHANISM CHANGES*/
        pkg_grp_log_util.prc_update_log_message_r
		(
        n_prcs_job_log_message_id_r => GN_JOB_LOG_MESSAGE_ID,
        p_err_msg => gv_trcmsg
		);
    /*END: NEW LOGGING MECHANISM CHANGES*/

    pkg_grp_log_util.prc_update_log
          (
			p_job_id => gn_out_job_id,
			p_job_status => GV_ERROR_STATUS,
			p_err_msg => GV_ERRMSG,
			p_trc_msg => chr(13) || GV_ERRMSG,
			p_log_util_called_by_r => GV_getcur_loadedby
          );
    RAISE;
END prc_get_cur_data;

    --Procedure to insert dummy record in the table RPT_POLICY_DTL_R
    PROCEDURE prc_insert_dummy_rec
    IS
    BEGIN
        gv_trcmsg:='5.1 Entered into from prc_insert_dummy_rec';

        /*START: NEW LOGGING MECHANISM CHANGES*/
		GT_START_TIME:= SYSTIMESTAMP;

		 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
		 (
			p_job_id_r                    => gn_out_job_id,
			p_batch_id_r                  => gn_sysdt_batchid,
			p_message_type_r              => GV_MESSAGE_TYPE,
			p_code_location_r             => gv_dummyrec_loadedby,
			p_message_r                   => gv_trcmsg,
			p_count_type_r                => NULL,
			p_count_r                     => NULL,
			p_duration_r                  => NULL,
			p_created_by_r                => GV_JOB_NAME,
			out_prcs_job_log_message_id_r => GN_JOB_LOG_MESSAGE_ID
		);
		/*END: NEW LOGGING MECHANISM CHANGES*/

         INSERT /*+APPEND*/ INTO  RPT_POLICY_DTL_R
               (
                v_last_modified_by_r
               ,t_creation_date_r
               ,v_created_by_r
               ,t_last_modified_date_r
               ,n_yearmonth_r
               ,v_rpt_active_status_r
               ,n_batch_id_r
               ,n_policy_sk_r
               ,N_CUST_PARTY_SK_R
               ,N_QUOTE_SK_R
               )
        VALUES(GV_MAIN_LOADEDBY
              ,systimestamp
              ,GV_MAIN_LOADEDBY
              ,systimestamp
              ,gn_current_month
              ,'Y'
              ,gn_sysdt_batchid
              ,-1           --n_policy_sk_r
              ,-1   -- N_CUST_PARTY_SK_R
              ,-1  -- N_QUOTE_SK_R
              );
        gn_run_cnt := SQL%ROWCOUNT;
        COMMIT;
        gv_trcmsg:='5.2 Exit from prc_insert_dummy_rec';
        /*START: NEW LOGGING MECHANISM CHANGES*/
        gt_end_time := SYSTIMESTAMP;
        PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
                (    p_job_id_r                    => gn_out_job_id
                    ,p_batch_id_r                  => gn_sysdt_batchid
                    ,p_message_type_r              => gv_message_type
                    ,p_code_location_r             => gv_dummyrec_loadedby
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
        GV_ERRMSG :=SUBSTR(SQLERRM,1,4000);
        gv_trcmsg:='5.z Error in prc_insert_dummy_rec';
        /*START: NEW LOGGING MECHANISM CHANGES*/
            pkg_grp_log_util.prc_update_log_message_r
        (
            n_prcs_job_log_message_id_r => GN_JOB_LOG_MESSAGE_ID,
            p_err_msg => gv_trcmsg
        );
        /*END: NEW LOGGING MECHANISM CHANGES*/
        pkg_grp_log_util.prc_update_log
              (
                gn_out_job_id
                ,GV_ERROR_STATUS
                ,GV_ERRMSG
                ,gv_trcmsg||GV_ERRMSG
                ,GV_dummyrec_loadedby
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
  Suresh     12/08/25 Standardization of Code
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
*******************************************************************************/
IS

 TYPE lt_var_tbl_type IS TABLE OF RPT_POLICY_DTL_R%ROWTYPE INDEX BY BINARY_INTEGER;
      lt_var_tbl_type_rec lt_var_tbl_type;
      lc_var_ref_cur 		SYS_REFCURSOR;
      lt_insert_time	    PRCS_JOB_LOG_MESSAGE_R.D_CREATION_DATE_R%TYPE  ;
      lv_rpt_table 		    PRCS_JOB_LOG_R.CREATED_BY_R%TYPE 			    :='RPT_POLICY_DTL_R';
	  ln_loop_counter       PLS_INTEGER                          		    := 1;
	  ln_rec_cnt 			PLS_INTEGER									    := 0;
	  ln_idx_num			PLS_INTEGER									    := 8;

      ld_fic_mis_date_2     DATE;
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

    ---2. Call procedure prc_upd_del_data to update active status to N for the records in Fisc prior month
    ---Also, Truncate the current Partion month data if any data present already.
   /* PKG_GRP_COMMON_UTIL.prc_upd_del_data
					( p_out_job_id	 				=> gn_out_job_id
					 ,p_rpt_table 					=> lv_rpt_table
					 ,p_upd_flag 					=> gv_yes_ind
					 ,p_idx_num						=> ln_idx_num
					 ,p_log_seq_num					=> 2
					 ,p_idx_unusable				=> NULL
					 );*/

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

    --4. Call Procedure prc_trunc_partition to delete the data either from Prior/Current month partiotion Data
    /*Common Utility Proc to truncate partition */

 -- Start: commented as part of Kill/Fill Process : 5th May 2026 : Commenting this part
	/*PKG_GRP_COMMON_UTIL.prc_trunc_partition
	(
		p_out_job_id    	=>	gn_out_job_id,
		p_Log_seq_num   	=>	4,
		p_rpt_table     	=>	lv_rpt_table,  --gc_rpt_table_name  to lv_rpt_table
		p_idx_num       	=>	ln_idx_num ,   --gc_rebuild_idx_degree to ln_idx_num
		p_current_month     =>	gn_current_month
	);;*/
-- End: commented as part of Kill/Fill Process : 5th May 2026 : Commenting this part

 -- Start: commented as part of Kill/Fill Process : 5th May 2026 : Added New

	/*EXECUTE IMMEDIATE 'DROP TABLE RPT_POLICY_DTL_R_EXG CASCADE CONSTRAINTS';
	EXECUTE IMMEDIATE 'CREATE TABLE RPT_POLICY_DTL_R_EXG FOR EXCHANGE WITH TABLE RPT_POLICY_DTL_R';
	EXECUTE IMMEDIATE 'ALTER TABLE RPT_POLICY_DTL_R_EXG ADD CONSTRAINT PK_8891_EXG PRIMARY KEY (N_YEARMONTH_R, N_CUST_PARTY_SK_R, N_POLICY_SK_R) DISABLE';
    */

	-- Call common Utility Package to create a exchange table if its not present else create new exg table with NoLogging
	PKG_GRP_COMMON_UTIL.PRC_CREATE_EXCHANGE_TABLE_DDL
		(
			p_job_id            	=> gn_out_job_id,
			p_log_seq_num           => 5,
			p_main_table_name       => gv_rpt_table_name,
			p_exg_table_name        => gv_exg_table_name,
			p_schema_name           => gv_schema_owner
		);
-- End: commented as part of Kill/Fill Process : 5th May 2026 : Added New


 -- Start: commented as part of Kill/Fill Process : 5th May 2026 : Added New
    ---4. Call prc_get_cur_data to get the latest data and perform ref_cursor assignment.
/*
    gv_trcmsg:='5. Call procedure prc_insert_dummy_rec .';
    GT_START_TIME:=SYSTIMESTAMP;
	 -- START: NEW LOGGING MECHANISM CHANGES
		 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
		 (
			p_job_id_r                    => gn_out_job_id,
			p_batch_id_r                  => gn_sysdt_batchid,
			p_message_type_r              => GV_MESSAGE_TYPE,
			p_code_location_r             => GV_MAIN_LOADEDBY,
			p_message_r                   => gv_trcmsg,
			p_count_type_r                => NULL,
			p_count_r                     => NULL,
			p_duration_r                  => NULL,
			p_created_by_r                => GV_JOB_NAME,
			out_prcs_job_log_message_id_r => GN_JOB_LOG_MESSAGE_ID
		);
	-- END: NEW LOGGING MECHANISM CHANGES

     prc_insert_dummy_rec;
    gv_trcmsg:='5.3 Completed Procedure prc_insert_dummy_rec call from main';

	-- START: NEW LOGGING MECHANISM CHANGES
        gt_end_time := SYSTIMESTAMP;
        PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
                (    p_job_id_r                    => gn_out_job_id
                    ,p_batch_id_r                  => gn_sysdt_batchid
                    ,p_message_type_r              => gv_message_type
                    ,p_code_location_r             => gv_main_loadedby
                    ,p_message_r                   => gv_trcmsg
                    ,p_count_type_r                => gv_count_type
                    ,p_count_r                     => null
                    ,p_duration_r                  => FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
                    ,p_created_by_r                => GV_JOB_NAME
                    ,out_prcs_job_log_message_id_r => gn_job_log_message_id
                    );
        -- END: NEW LOGGING MECHANISM CHANGES

   -- EXECUTE IMMEDIATE 'ALTER TABLE RPT_POLICY_DTL_R MODIFY PARTITION PART_RPT_POLICY_DTL_R_'||gn_current_month||' UNUSABLE LOCAL INDEXES';

	gv_trcmsg:='6. Disable Local indexes for partition: PART_RPT_POLICY_DTL_R_'||gn_current_month;

	-- START: NEW LOGGING MECHANISM CHANGES
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
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
                */
-- End: commented as part of Kill/Fill Process : 5th May 2026 : Commenting this part

	---4. Call prc_get_cur_data to get the latest data and perform ref_cursor assignment.
	prc_get_cur_data; 						/* Added as part of Kill/Fill Process : 5th May 2026 	 */

-- Start: commented as part of Kill/Fill Process : 5th May 2026
/*	prc_get_cur_data (lc_var_ref_cur); 	--kill/Fill: commented this : retaining for later converting to incremental to load using bulk collect
    gv_trcmsg:='7. Data Load starts ';

	gt_start_time:= SYSTIMESTAMP;

	 -- START: NEW LOGGING MECHANISM CHANGES
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
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
    -- END: NEW LOGGING MECHANISM CHANGES

	ln_rec_cnt:=0;
    LOOP
	      lt_var_tbl_type_rec.DELETE;

        FETCH lc_var_ref_cur
            BULK COLLECT
            INTO LT_VAR_TBL_TYPE_REC
            LIMIT GN_BULK_COLL_CNT;
            LT_INSERT_TIME  := SYSTIMESTAMP ;
            FOR i IN 1..lt_var_tbl_type_rec.COUNT
            LOOP
                lt_var_tbl_type_rec(i).t_creation_date_r := lt_insert_time ; -- Assign unique timestamp to each record
                lt_insert_time :=lt_insert_time + interval '0.000001' SECOND;
            END LOOP;

		gt_start_time_inside_lp := SYSTIMESTAMP; -- Start timing before the insert
        FORALL x in lt_var_tbl_type_rec.First..lt_var_tbl_type_rec.Last
         INSERT /*+APPEND_VALUES*/ /* INTO RPT_POLICY_DTL_R VALUES lt_var_tbl_type_rec(x) ;
                ln_rec_cnt:=ln_rec_cnt+lt_var_tbl_type_rec.COUNT;
         COMMIT;

	    gt_end_time := SYSTIMESTAMP; -- End timing after the insert
		--ln_rec_cnt  := ln_rec_cnt + lt_var_tbl_type_rec.COUNT;
		gv_trcmsg   := '7.1: Data load: Bulk Set - '|| ln_loop_counter || ': ' || ln_rec_cnt || ' records loaded' ;

		-- START: NEW LOGGING MECHANISM CHANGES
            PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
                   ( p_job_id_r 					=> gn_out_job_id
                    ,p_batch_id_r					=> gn_sysdt_batchid
                    ,p_message_type_r 				=> gv_message_type
                    ,p_code_location_r 				=> gv_main_loadedby
                    ,p_message_r 					=> gv_trcmsg
                    ,p_count_type_r 				=> gv_count_type
                    ,p_count_r 						=> ln_rec_cnt
                    ,p_duration_r 					=> FNC_GRP_TIME_DURATION(gt_start_time_inside_lp,gt_end_time)
                    ,p_created_by_r 				=> Gv_JOB_NAME
                    ,out_prcs_job_log_message_id_r	=> gn_job_log_message_id
                    );
		-- END: NEW LOGGING MECHANISM CHANGES

		ln_loop_counter := ln_loop_counter + 1;
      EXIT WHEN lc_var_ref_cur%NOTFOUND;
     END LOOP;
	CLOSE lc_var_ref_cur;

	gv_trcmsg :='7.2: Data Loaded '||ln_rec_cnt||' records ';

     -- START: NEW LOGGING MECHANISM CHANGES
        gt_end_time := SYSTIMESTAMP;
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
        -- END: NEW LOGGING MECHANISM CHANGES

	gv_trcmsg:='7.3: Target count for Audit control Process';

     -- START: NEW LOGGING MECHANISM CHANGES
          PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
                (    p_job_id_r                    => gn_out_job_id
                    ,p_batch_id_r                  => gn_sysdt_batchid
                    ,p_message_type_r              => gv_message_type
                    ,p_code_location_r             => gv_main_loadedby
                    ,p_message_r                   => gv_trcmsg
                    ,p_count_type_r                => 'AUDIT_TARGET_COUNT'
                    ,p_count_r                     => ln_rec_cnt
                    ,p_duration_r                  => NULL
                    ,p_created_by_r                => GV_JOB_NAME
                    ,out_prcs_job_log_message_id_r => gn_job_log_message_id
                    );
        -- END: NEW LOGGING MECHANISM CHANGES
	*/

	-- End: commented as part of Kill/Fill Process : 5th May 2026

	-- Start : Kill/Fill Changes 5th May 2026 	: Added New
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

	-- End : Kill/Fill Changes 5th May 2026 : Added New

    gv_trcmsg:='8. Rebuild Local Index prc_rebuild_index_partitions from Common Util for Partition: '||gn_current_month;
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
    --22-08-2025 : Added Local Index Rebuild
	PKG_GRP_COMMON_UTIL.prc_rebuild_index_partitions
	(
		p_table_name   		  		  => 'RPT_POLICY_DTL_R',
		p_parallel_degree   		  => 8,
		p_partition_name  		  	  => 'PART_RPT_POLICY_DTL_R_'||gn_current_month,
		p_out_job_id              	  => gn_out_job_id,
		p_Log_seq_num             	  => 8
	);

    /*START: NEW LOGGING MECHANISM CHANGES*/
        gv_trcmsg:='8.Z Completed Rebuild Local Index prc_rebuild_index_partitions from Common Util for Partition: '||gn_current_month;
        gt_end_time := SYSTIMESTAMP;
        PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
                (    p_job_id_r                    => gn_out_job_id
                    ,p_batch_id_r                  => gn_sysdt_batchid
                    ,p_message_type_r              => gv_message_type
                    ,p_code_location_r             => gv_rebuildindexes
                    ,p_message_r                   => gv_trcmsg
                    ,p_count_type_r                => gv_count_type
                    ,p_count_r                     => null
                    ,p_duration_r                  => FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
                    ,p_created_by_r                => GV_JOB_NAME
                    ,out_prcs_job_log_message_id_r => gn_job_log_message_id
                    );
        /*END: NEW LOGGING MECHANISM CHANGES*/

    gv_trcmsg:='9 Call procedure PRC_UPD_COL_DETAILS from main';

    GT_START_TIME:=SYSTIMESTAMP;
	/*START: NEW LOGGING MECHANISM CHANGES*/
		 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
		 (
			p_job_id_r                    => gn_out_job_id,
			p_batch_id_r                  => gn_sysdt_batchid,
			p_message_type_r              => GV_MESSAGE_TYPE,
			p_code_location_r             => GV_MAIN_LOADEDBY,
			p_message_r                   => gv_trcmsg,
			p_count_type_r                => NULL,
			p_count_r                     => NULL,
			p_duration_r                  => NULL,
			p_created_by_r                => GV_JOB_NAME,
			out_prcs_job_log_message_id_r => GN_JOB_LOG_MESSAGE_ID
		);
	/*END: NEW LOGGING MECHANISM CHANGES*/


    PRC_UPD_COL_DETAILS; --KILL/FILL: UNCOMMENT THIS


    gv_trcmsg:='10 Completed Procedure PRC_UPD_COL_DETAILS call from main';

	/*START: NEW LOGGING MECHANISM CHANGES*/
        gt_end_time := SYSTIMESTAMP;
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


	gv_trcmsg:='11 Calling Audit Control Procedure';

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

	PRC_GRP_AUDIT_CONTROL_PROCESS(gv_source,gv_main_entity,gv_source,gv_target);

    gv_trcmsg :='11 Exit from main';

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
END PKG_GRP_LOAD_RPT_POLICY_DTL_R;

