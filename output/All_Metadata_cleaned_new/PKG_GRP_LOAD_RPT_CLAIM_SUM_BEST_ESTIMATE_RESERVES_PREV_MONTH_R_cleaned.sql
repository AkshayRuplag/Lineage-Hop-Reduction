-- Cleaned for lineage: PKG_GRP_LOAD_RPT_CLAIM_SUM_BEST_ESTIMATE_RESERVES_PREV_MONTH_R

Update Atomic.RPT_CLAIM_SUM_R set BE_AND_FIELD_MOST_RECENT_AS_OF_DATE=gd_mis_date_be_r,N_CURR_BEST_ESTIMATE_RESERVE_R=0,N_CURR_FIELD_RESERVE_R=0 where N_YEARMONTH_R = LD_MIS_CYCLE_MONTH_R;

MERGE  INTO ATOMIC.RPT_CLAIM_SUM_R TGT
USING 
		(select N_CLAIM_SK_R                  AS N_CLAIM_SK_R
	     ,N_CLAIM_COVERAGE_SK_R              AS N_CLAIM_COVERAGE_SK_R
		 ,N_CLAIM_COVERAGE_GROUP_SK_R        AS N_CLAIM_COVERAGE_GROUP_SK_R
		 ,sum(N_RESERVE_DIRECT_BEST_ESTMT_R) AS N_CURR_BEST_ESTIMATE_RESERVE_R
	     ,sum(N_RESERVE_DIRECT_FIELD_R)      AS N_CURR_FIELD_RESERVE_R
		 ,n_reportmonth_r
	  from ATOMIC.RPT_RESERVE_DETAILS_R a
     where a.D_RESERVE_VALUATION_DATE_R =gd_mis_cycle_date_r
	   AND EXISTS(SELECT 1
					FROM ATOMIC.RPT_CLAIM_SUM_R
				   WHERE RPT_CLAIM_SUM_R.N_CLAIM_COVERAGE_GROUP_SK_R = A.N_CLAIM_COVERAGE_GROUP_SK_R
				     AND RPT_CLAIM_SUM_R.N_CLAIM_COVERAGE_SK_R       = A.N_CLAIM_COVERAGE_SK_R
					 AND RPT_CLAIM_SUM_R.N_CLAIM_SK_R                = A.N_CLAIM_SK_R
					 AND RPT_CLAIM_SUM_R.N_YEARMONTH_R               = LD_MIS_CYCLE_MONTH_R
				  )
	  group by n_claim_sk_r, n_claim_coverage_sk_r, n_claim_coverage_group_sk_r,n_reportmonth_r
		) SRC
		ON (SRC.N_CLAIM_COVERAGE_GROUP_SK_R    =  TGT.N_CLAIM_COVERAGE_GROUP_SK_R
			AND SRC.n_claim_coverage_sk_r      =  TGT.n_claim_coverage_sk_r      
			AND SRC.n_claim_sk_r               =  TGT.n_claim_sk_r               
			AND SRC.n_reportmonth_r            =  TGT.N_YEARMONTH_R)
WHEN MATCHED THEN
	UPDATE SET   TGT.N_CURR_BEST_ESTIMATE_RESERVE_R         = SRC.N_CURR_BEST_ESTIMATE_RESERVE_R                  
				,TGT.N_CURR_FIELD_RESERVE_R                 = SRC.N_CURR_FIELD_RESERVE_R 
	WHERE 
			SRC.n_claim_coverage_group_sk_r    =TGT.n_claim_coverage_group_sk_r
			and SRC.n_claim_coverage_sk_r      =TGT.n_claim_coverage_sk_r      
			and SRC.n_claim_sk_r               =TGT.n_claim_sk_r               
			AND SRC.n_reportmonth_r            =TGT.N_YEARMONTH_R;