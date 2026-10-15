-- Cleaned for lineage: PKG_GRP_LOAD_RPT_POLICY_DTL_R_PRC_UPD_COL_DETAILS (part 2/4)

FORALL X IN 1 .. lt_var_upd_tbl_inforceindicator_typ_rec.COUNT
      UPDATE RPT_POLICY_DTL_R
         SET V_POLICY_INFORCE_INDICATOR_R = lt_var_upd_tbl_inforceindicator_typ_rec(X).V_POLICY_INFORCE_INDICATOR_R
           , N_ANNUALIZED_PREMIUM_R = lt_var_upd_tbl_inforceindicator_typ_rec(X).N_ANNUALIZED_PREMIUM_R
       WHERE n_policy_sk_r = lt_var_upd_tbl_inforceindicator_typ_rec(X).n_policy_sk_r
         AND n_yearmonth_r = gn_current_month;

gv_trcmsg:='9.38 Update V_POLICY_INFORCE_INDICATOR_R  Completed from main';

-- Lineage: Cursor CUR_UPD_CLIENT_DTLS -> UPDATE RPT_POLICY_DTL_R
-- Source query:
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

-- Lineage: Cursor CUR_UPD_UW_DTLS (target inferred from procedure)
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

-- Lineage: Cursor CUR_UPD_THEFT_IND_COL -> UPDATE RPT_POLICY_DTL_R
-- Source query:
SELECT t4804933.n_policy_sk_r                              AS n_policy_sk_r
		 , NVL(MAX( t4805277.v_override_description_r),'No')   AS v_id_theft_ind_r
	  FROM fct_plan_design_summary_r t4805277
		 , dim_plan_design_directory_r_gtt t4804933
	 WHERE t4804933.n_plan_design_sk_r = t4805277.n_plan_design_sk_r
	   AND t4804933.v_coverage_code_r = 'IDTHEFT'
  GROUP BY t4804933.n_policy_sk_r;

-- Lineage: Cursor CUR_UPD_THEFT_DT_COL -> UPDATE RPT_POLICY_DTL_R
-- Source query:
SELECT t4804933.n_policy_sk_r                  AS n_policy_sk_r
		 , MIN( t4805277.v_override_description_r) AS v_override_description_r
		 , CAST(NULL AS DATE)                      AS d_id_theft_date_r
	  FROM fct_plan_design_summary_r t4805277
		  ,dim_plan_design_directory_r_gtt t4804933
	 WHERE t4804933.n_plan_design_sk_r = t4805277.n_plan_design_sk_r
	   AND t4804933.v_coverage_code_r = 'IDTHEFTEFFDATE'
	   AND t4805277.v_override_description_r IS NOT NULL
	GROUP BY t4804933.n_policy_sk_r;

-- Lineage: Cursor CUR_UPD_PRS_STRS_IND_R -> UPDATE RPT_POLICY_DTL_R
-- Source query:
SELECT t4804933.n_policy_sk_r                 AS n_policy_sk_r
	     , MIN(t4805277.v_override_description_r) AS v_prs_strs_ind_r
	  FROM fct_plan_design_summary_r t4805277
		 , dim_plan_design_directory_r_gtt t4804933
	 WHERE t4804933.n_plan_design_sk_r = t4805277.n_plan_design_sk_r
	   AND t4804933.v_coverage_code_r = 'PSINDICATOR'
	GROUP BY t4804933.n_policy_sk_r;

-- Lineage: Cursor CUR_UPD_ELIMPERIOD_COL -> UPDATE RPT_POLICY_DTL_R
-- Source query:
SELECT t4804933.n_policy_sk_r                  AS n_policy_sk_r
	     , MAX( t4805277.v_override_description_r) AS V_ELIM_PERIOD_R
	  FROM fct_plan_design_summary_r t4805277
		 , dim_plan_design_directory_r_gtt t4804933
	 WHERE t4804933.n_plan_design_sk_r = t4805277.n_plan_design_sk_r
	   AND t4804933.v_coverage_code_r = 'ELIMPERIOD'
  GROUP BY t4804933.n_policy_sk_r;

-- Lineage: Cursor CUR_UPD_EAP_DESC_COL -> UPDATE RPT_POLICY_DTL_R
-- Source query:
SELECT t4804933.n_policy_sk_r                 AS n_policy_sk_r
	     , MAX(t4805277.v_override_description_r) AS v_eap_desc_r
		 , t4804933.V_COVERAGE_CODE_R             AS V_COVERAGE_CODE_R
	  FROM fct_plan_design_summary_r t4805277
		 , dim_plan_design_directory_r_gtt t4804933
	 WHERE t4804933.n_plan_design_sk_r = t4805277.n_plan_design_sk_r
	   AND t4804933.v_coverage_code_r IN ('EAIND', 'EAP') 
  GROUP BY t4804933.n_policy_sk_r,t4804933.V_COVERAGE_CODE_R;

-- Lineage: Cursor CUR_UPD_BEREAVE_DESC_COL -> UPDATE RPT_POLICY_DTL_R
-- Source query:
SELECT t4804933.n_policy_sk_r                 AS n_policy_sk_r
	     , MAX(t4805277.v_override_description_r) AS V_BEREAVE_DESC_R
		 , t4804933.V_COVERAGE_CODE_R             AS V_COVERAGE_CODE_R
	  FROM fct_plan_design_summary_r t4805277
		 , dim_plan_design_directory_r_gtt t4804933
	 WHERE t4804933.n_plan_design_sk_r = t4805277.n_plan_design_sk_r
	   AND t4804933.v_coverage_code_r ='BEREAVE'
  GROUP BY t4804933.n_policy_sk_r,t4804933.V_COVERAGE_CODE_R;

-- Lineage: Cursor CUR_UPD_EAP_EFF_DATE_COL -> UPDATE RPT_POLICY_DTL_R
-- Source query:
SELECT t4804933.n_policy_sk_r                 AS n_policy_sk_r
	     , MAX(t4805277.v_override_description_r) AS V_EAP_EFF_DATE_R
	  FROM fct_plan_design_summary_r t4805277
		 , dim_plan_design_directory_r_gtt t4804933
	 WHERE t4804933.n_plan_design_sk_r = t4805277.n_plan_design_sk_r
	   AND t4804933.v_coverage_code_r ='EAP_EFF_DATE'
	 GROUP BY t4804933.n_policy_sk_r;

-- Lineage: Cursor CUR_UPD_BEREAVEDATE_COL -> UPDATE RPT_POLICY_DTL_R
-- Source query:
SELECT t4804933.n_policy_sk_r, MAX(t4805277.v_override_description_r) V_BEREAVEDATE_R
	  FROM fct_plan_design_summary_r t4805277
		 , dim_plan_design_directory_r_gtt t4804933
	 WHERE t4804933.n_plan_design_sk_r = t4805277.n_plan_design_sk_r
	   AND t4804933.v_coverage_code_r ='BEREAVEDATE'
  GROUP BY t4804933.n_policy_sk_r;