-- Cleaned for lineage: PKG_GRP_LOAD_RPT_CLAIM_SUM_R_PRC_UPD_COLS

gv_trcmsg := '1.1 :Update Amount columns from main.';

UPDATE   rpt_claim_sum_r
      set
        n_claim_total_gross_amt_r= lt_var_upd_tbl_amt_typ(X).n_claim_total_gross_amt_r
       ,n_claim_total_loss_amt_r = lt_var_upd_tbl_amt_typ(X).n_claim_total_loss_amt_r
       ,n_claim_total_paid_amt_r = lt_var_upd_tbl_amt_typ(X).n_claim_total_loss_amt_r
       ,n_claim_total_net_amt_r  = lt_var_upd_tbl_amt_typ(X).n_claim_total_net_amt_r
       ,n_most_recent_net_amt_r  = lt_var_upd_tbl_amt_typ(X).n_claim_total_net_amt_r
       ,n_claim_total_tax_amt_r  = lt_var_upd_tbl_amt_typ(X).n_claim_total_tax_amt_r
	   ,N_CLAIM_MTD_LOSS_AMT_R   = lt_var_upd_tbl_amt_typ(X).N_CLAIM_MTD_LOSS_AMT_R
	   ,N_CLAIM_QTD_LOSS_AMT_R   =  lt_var_upd_tbl_amt_typ(X).N_CLAIM_QTD_LOSS_AMT_R
	   ,N_CLAIM_YTD_LOSS_AMT_R   =  lt_var_upd_tbl_amt_typ(X).N_CLAIM_YTD_LOSS_AMT_R
    where
	    rpt_claim_sum_r.n_claim_coverage_group_sk_r=lt_var_upd_tbl_amt_typ(X).n_claim_coverage_group_sk_r
    and rpt_claim_sum_r.n_claim_coverage_sk_r      =lt_var_upd_tbl_amt_typ(X).n_claim_coverage_sk_r
    and rpt_claim_sum_r.n_claim_sk_r               =lt_var_upd_tbl_amt_typ(X).n_claim_sk_r
    and rpt_claim_sum_r.n_yearmonth_r              =gn_current_month;

gv_trcmsg := '1.3 : Update Reserve Amount columns from main.';

UPDATE   rpt_claim_sum_r
      set
        n_curr_best_estimate_reserve_r        = lt_var_upd_tbl_reserveamt_typ(X).n_curr_best_estimate_reserve_r
       ,n_curr_gaap_reserve_r                 = lt_var_upd_tbl_reserveamt_typ(X).n_curr_gaap_reserve_r
       ,n_curr_stat_reserve_r                 = lt_var_upd_tbl_reserveamt_typ(X).n_curr_stat_reserve_r
       ,n_curr_field_reserve_r                = lt_var_upd_tbl_reserveamt_typ(X).n_curr_field_reserve_r
       ,d_most_recent_reserve_valuation_date_r= lt_var_upd_tbl_reserveamt_typ(X).d_most_recent_reserve_valuation_date_r
	   ,N_CURRENT_RESERVE_R                = lt_var_upd_tbl_reserveamt_typ(X).N_CURRENT_RESERVE_R 
    where
	    rpt_claim_sum_r.n_claim_coverage_group_sk_r=lt_var_upd_tbl_reserveamt_typ(X).n_claim_coverage_group_sk_r
    and rpt_claim_sum_r.n_claim_coverage_sk_r      =lt_var_upd_tbl_reserveamt_typ(X).n_claim_coverage_sk_r
    and rpt_claim_sum_r.n_claim_sk_r               =lt_var_upd_tbl_reserveamt_typ(X).n_claim_sk_r
    and rpt_claim_sum_r.n_yearmonth_r              =gn_current_month;

gv_trcmsg := '1.7 : Update Current Face Amt starts from main.';

UPDATE   RPT_CLAIM_SUM_R
      set
	  n_current_face_amount_r=lt_var_upd_tbl_typ3(X).n_current_face_amount_r
	  where rowid=lt_var_upd_tbl_typ3(X).row_id
	    AND n_yearmonth_r=gn_current_month;

gv_trcmsg       := '1.8 - Update Current Face Amt Completed .';

-- Lineage: Cursor CUR_UPD_DATA -> UPDATE RPT_CLAIM_SUM_R
-- Source query:
SELECT 
	     RPT_CLAIM_SUM_R.ROWID                     AS ROW_ID
	   , RPT_CLAIM_SUM_R.n_policy_sk_r             AS N_POLICY_SK_R
	   , NVL(RPT_CLAIM_SUM_R.v_lob_type_r ,'@')    AS V_LOB_TYPE_R
	   , RPT_CLAIM_SUM_R.N_ORIGINAL_FACE_AMOUNT_R  AS N_RESERVE_AMOUNT_R
	   , RPT_CLAIM_SUM_R.n_ws_released_amount_r    AS N_WS_RELEASED_AMOUNT_R
	   , (RPT_CLAIM_SUM_R.N_ORIGINAL_FACE_AMOUNT_R
        - RPT_CLAIM_SUM_R.N_WS_RELEASED_AMOUNT_R
          )                                        AS N_LIFE_WOP_AMT_R
	   , CAST(NULL AS NUMBER)                      AS N_CURRENT_FACE_AMOUNT_R
	
	   ,(SELECT 
                V_CLASS_OF_BUSINESS_R
		   FROM RPT_POLICY_DTL_R_CLASSOFBUS_MV_SSL rpt_policy_dtl_r
		  WHERE RPT_POLICY_DTL_R.N_POLICY_SK_R = RPT_CLAIM_SUM_R.N_POLICY_SK_R
	   GROUP BY V_CLASS_OF_BUSINESS_R
	    )                                          AS V_CLASS_OF_BUSINESS_R
	
	FROM RPT_CLAIM_SUM_R
   WHERE N_YEARMONTH_R=GN_CURRENT_MONTH;

-- Lineage: Cursor CUR_GET_AMT (target inferred from procedure)
SELECT N_CLAIM_TOTAL_GROSS_AMT_R
		 , N_CLAIM_TOTAL_LOSS_AMT_R
		 , N_CLAIM_TOTAL_NET_AMT_R
		 , N_CLAIM_TOTAL_TAX_AMT_R
		 , N_CLAIM_COVERAGE_GROUP_SK_R
		 , N_CLAIM_COVERAGE_SK_R
		 , N_CLAIM_SK_R
		 , N_YEARMONTH_R
		 
		 , N_CLAIM_MTD_LOSS_AMT_R
		 , N_CLAIM_QTD_LOSS_AMT_R
		 , N_CLAIM_YTD_LOSS_AMT_R
		 
	 FROM RPT_CLAIM_PAYMENT_DTL_AMT_MV_SSL			A
	WHERE N_YEARMONTH_R = GN_CURRENT_MONTH
	
      AND EXISTS(SELECT 1
                   FROM RPT_CLAIM_SUM_R
                  WHERE RPT_CLAIM_SUM_R.N_CLAIM_COVERAGE_GROUP_SK_R = A.N_CLAIM_COVERAGE_GROUP_SK_R
                    AND RPT_CLAIM_SUM_R.N_CLAIM_COVERAGE_SK_R       =A.N_CLAIM_COVERAGE_SK_R
                    AND RPT_CLAIM_SUM_R.N_CLAIM_SK_R                = A.N_CLAIM_SK_R
                    AND RPT_CLAIM_SUM_R.N_YEARMONTH_R               =GN_CURRENT_MONTH
              );

-- Lineage: Cursor CUR_RESERVEAMT (target inferred from procedure)
select N_CLAIM_SK_R                       AS N_CLAIM_SK_R
	     , N_CLAIM_COVERAGE_SK_R              AS N_CLAIM_COVERAGE_SK_R
		 , N_CLAIM_COVERAGE_GROUP_SK_R        AS N_CLAIM_COVERAGE_GROUP_SK_R
		 , sum(N_RESERVE_DIRECT_BEST_ESTMT_R) AS N_CURR_BEST_ESTIMATE_RESERVE_R
	     , sum(N_RESERVE_DIRECT_GAAP_R)       AS N_CURR_GAAP_RESERVE_R
	     , sum(N_RESERVE_DIRECT_STAT_R)       AS N_CURR_STAT_RESERVE_R
	     , sum(N_RESERVE_DIRECT_FIELD_R)      AS N_CURR_FIELD_RESERVE_R
	     , D_RESERVE_VALUATION_DATE_R         AS D_MOST_RECENT_RESERVE_VALUATION_DATE_R
	
	     , N_CURRENT_RESERVE_R                AS N_CURRENT_RESERVE_R 
	  from RPT_RESERVE_DETAILS_R a
     where a.D_RESERVE_VALUATION_DATE_R =
     	(select max(b.D_RESERVE_VALUATION_DATE_R)
     	   from RPT_RESERVE_DETAILS_R b
     	  where a.n_claim_sk_r = b.n_claim_sk_r
     	    and a.n_claim_coverage_sk_r = b.n_claim_coverage_sk_r
     	    and a.n_claim_coverage_group_sk_r = b.n_claim_coverage_group_sk_r
     	  
     	)
	
	   AND EXISTS(SELECT 1
					FROM RPT_CLAIM_SUM_R
				   WHERE RPT_CLAIM_SUM_R.N_CLAIM_COVERAGE_GROUP_SK_R = A.N_CLAIM_COVERAGE_GROUP_SK_R
				     AND RPT_CLAIM_SUM_R.N_CLAIM_COVERAGE_SK_R       = A.N_CLAIM_COVERAGE_SK_R
					 AND RPT_CLAIM_SUM_R.N_CLAIM_SK_R                = A.N_CLAIM_SK_R
					 AND RPT_CLAIM_SUM_R.N_YEARMONTH_R               = GN_CURRENT_MONTH
				  )

	  group by n_claim_sk_r, n_claim_coverage_sk_r, n_claim_coverage_group_sk_r,d_reserve_valuation_date_r,n_reportmonth_r,N_CURRENT_RESERVE_R;