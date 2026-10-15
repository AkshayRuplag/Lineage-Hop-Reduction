-- Cleaned for lineage: PKG_GRP_LOAD_RPT_POLICY_DTL_R_PRC_UPD_COL_DETAILS (part 4/4)

-- Lineage: Cursor CUR_UPD_INFORCEINDICATOR_COLS -> UPDATE RPT_POLICY_DTL_R
-- Source query:
SELECT  a.n_policy_sk_r,
		  CASE
			WHEN a.n_annualized_premium_r <> 0 AND NVL(a.N_YTD_PRIOR_PREMIUM_R,0) = 0
			THEN 'New'
			WHEN a.n_annualized_premium_r <> 0 AND NVL(a.N_YTD_PRIOR_PREMIUM_R,0) <> 0
			THEN 'Existing'
			WHEN a.n_annualized_premium_r = 0 AND NVL(a.N_YTD_PRIOR_PREMIUM_R,0) <> 0
			THEN 'Lapse'
			ELSE 'Lapse'
		  END V_POLICY_INFORCE_INDICATOR_R
	    , SUM (nvl(a.N_ANNUALIZED_PREMIUM_R,0)) N_ANNUALIZED_PREMIUM_R  
	FROM 
		
	   ( SELECT NVL(SUM(N_YTD_PRIOR_PREMIUM_R),0)  AS N_YTD_PRIOR_PREMIUM_R
			  , NVL(SUM(N_ANNUALIZED_PREMIUM_R),0) AS N_ANNUALIZED_PREMIUM_R
			  , N_POLICY_SK_R                      AS N_POLICY_SK_R
			  , D_CYCLE_DATE_R                     AS D_CYCLE_DATE_R
			FROM FCT_RPT_ANN_PREM_SUMMARY_R
	    GROUP BY N_POLICY_SK_R,D_CYCLE_DATE_R
		) a,
	
	    RPT_POLICY_DTL_R b
	WHERE a.n_policy_sk_r = b.n_policy_sk_r
	  AND TO_CHAR(a.D_CYCLE_DATE_R, 'YYYYMM') = gn_current_month
	  AND b.n_yearmonth_r = gn_current_month
	  AND EXISTS ( SELECT 1
			         FROM rpt_policy_dtl_r policy
			        WHERE policy.n_policy_sk_r = a.n_policy_sk_r
			          AND policy.n_yearmonth_r = gn_current_month
		         )
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