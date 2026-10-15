-- Cleaned for lineage: PKG_GRP_LOAD_RPT_POLICY_DTL_R_PRC_UPD_COL_DETAILS (part 3/4)

-- Lineage: Cursor CUR_UPD_CROSS_SELL_COL (target inferred from procedure)
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
 	    FROM fct_rpt_cross_sell_summary_r frcssr
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

-- Lineage: Cursor CUR_UPD_NXTRENEWALDT_COL -> UPDATE RPT_POLICY_DTL_R
-- Source query:
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

-- Lineage: Cursor CUR_UPD_D_RATE_GUAR_R_COL -> UPDATE RPT_POLICY_DTL_R
-- Source query:
SELECT d_rate_guar_r,n_policy_sk_r
	  FROM
		  stg_perf_ameritas_renewal_info
	 GROUP BY d_rate_guar_r,n_policy_sk_r;

-- Lineage: Cursor CUR_UPD_OPTION_COL -> UPDATE RPT_POLICY_DTL_R
-- Source query:
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
    FROM rpt_policy_dtl_r t6327792 
   WHERE n_yearmonth_r = gn_current_month;

-- Lineage: Cursor CUR_UPD_AGENCYCODE_COLS -> UPDATE RPT_POLICY_DTL_R
-- Source query:
select LISTAGG(agent.V_AGENCY_CODE_R, ';

-- Lineage: Cursor CUR_UPD_SUBMISSION_DT -> UPDATE RPT_POLICY_DTL_R
-- Source query:
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
	GROUP BY N_POLICY_SK_R;

-- Lineage: Cursor CUR_UPD_NXTRENEWALEFFDT_COL -> UPDATE RPT_POLICY_DTL_R
-- Source query:
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
		    ) ft,
		   (SELECT N_SOURCE_SYSTEM_KEY_R
		         , N_TXN_VERSION_NUMBER_R
				 , D_EFFECTIVE_R
				 , n_policy_skey_r
				 , V_VERSION_TYPE_R
				 , V_BUS_OBJ_STATUS_R
			  FROM fct_grp_transactions_r
		     WHERE V_VERSION_TYPE_R in('RENEWAL', 'NEWBUS')
		  order by N_TXN_VERSION_NUMBER_R desc
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