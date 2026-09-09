-- Cleaned for lineage: PRC_GRP_LOAD_RPT_CLAIM_SUM_R_INCR_LIFE_ADHOC

MERGE  INTO ATOMIC.RPT_CLAIM_SUM_R TGT
USING (
	SELECT n_claim_sk_r
		,n_claim_coverage_sk_r
		,n_claim_coverage_group_sk_r
		,sum(nvl(N_RESERVE_DIRECT_BEST_ESTMT_R, 0)) N_CURR_BEST_ESTIMATE_RESERVE_R
		,sum(nvl(N_RESERVE_DIRECT_GAAP_R, 0)) N_CURR_GAAP_RESERVE_R
		,sum(nvl(N_RESERVE_DIRECT_STAT_R, 0)) N_CURR_STAT_RESERVE_R
		,sum(nvl(N_RESERVE_DIRECT_FIELD_R, 0)) N_CURR_FIELD_RESERVE_R
		,D_RESERVE_VALUATION_DATE_R D_MOST_RECENT_RESERVE_VALUATION_DATE_R
		,n_reportmonth_r
		,sum(nvl(N_CURRENT_RESERVE_R, 0)) N_CURRENT_RESERVE_R
	FROM ATOMIC.RPT_RESERVE_DETAILS_R A
	WHERE a.D_RESERVE_VALUATION_DATE_R = LD_MIS_DATE_R
		AND n_reportmonth_r = LD_MIS_CYCLE_MONTH_R 
		AND EXISTS (
			SELECT 1
			FROM atomic.RPT_CLAIM_SUM_R
			WHERE RPT_CLAIM_SUM_R.N_CLAIM_COVERAGE_GROUP_SK_R = A.N_CLAIM_COVERAGE_GROUP_SK_R
				AND RPT_CLAIM_SUM_R.N_CLAIM_COVERAGE_SK_R = A.N_CLAIM_COVERAGE_SK_R
				AND RPT_CLAIM_SUM_R.N_CLAIM_SK_R = A.N_CLAIM_SK_R
				AND RPT_CLAIM_SUM_R.N_YEARMONTH_R = LD_MIS_CYCLE_MONTH_R
			)
	GROUP BY n_claim_sk_r
		,n_claim_coverage_sk_r
		,n_claim_coverage_group_sk_r
		,d_reserve_valuation_date_r
		,n_reportmonth_r
	) SRC
	ON (
			SRC.N_CLAIM_COVERAGE_GROUP_SK_R = TGT.N_CLAIM_COVERAGE_GROUP_SK_R
			AND SRC.n_claim_coverage_sk_r = TGT.n_claim_coverage_sk_r
			AND SRC.n_claim_sk_r = TGT.n_claim_sk_r
			AND SRC.n_reportmonth_r = TGT.N_YEARMONTH_R
			)
WHEN MATCHED
	THEN
		UPDATE
		SET TGT.N_CURR_BEST_ESTIMATE_RESERVE_R = SRC.N_CURR_BEST_ESTIMATE_RESERVE_R
			,TGT.N_CURR_GAAP_RESERVE_R = SRC.N_CURR_GAAP_RESERVE_R
			,TGT.N_CURR_STAT_RESERVE_R = SRC.N_CURR_STAT_RESERVE_R
			,TGT.N_CURR_FIELD_RESERVE_R = SRC.N_CURR_FIELD_RESERVE_R
			,TGT.d_most_recent_reserve_valuation_date_r = SRC.d_most_recent_reserve_valuation_date_r
			,TGT.N_CURRENT_RESERVE_R = SRC.N_CURRENT_RESERVE_R
		WHERE SRC.n_claim_coverage_group_sk_r = TGT.n_claim_coverage_group_sk_r
			AND SRC.n_claim_coverage_sk_r = TGT.n_claim_coverage_sk_r
			AND SRC.n_claim_sk_r = TGT.n_claim_sk_r
			AND SRC.n_reportmonth_r = TGT.N_YEARMONTH_R;