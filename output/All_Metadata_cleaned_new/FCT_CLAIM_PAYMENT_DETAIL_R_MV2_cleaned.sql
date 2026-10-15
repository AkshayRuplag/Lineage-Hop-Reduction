-- Cleaned for lineage: FCT_CLAIM_PAYMENT_DETAIL_R_MV2

CREATE MATERIALIZED VIEW FCT_CLAIM_PAYMENT_DETAIL_R_MV2 AS
SELECT MAX(CP.D_PAID_DATE_R) D_PAID_DATE_R,
	cp.n_claim_sk_r,
	CD.V_CLAIM_NUMBER_R v_claim_identifier_r
FROM FCT_CLAIM_PAYMENT_DETAIL_R CP
INNER JOIN dim_time_r td
	ON cp.D_PAID_DATE_R = td.d_calendar_date_r
INNER JOIN dim_grp_claim_dir_r cd
	ON cp.n_claim_sk_r = cd.n_claim_sk_r
		AND cd.v_active_status_r = 'Y'
		AND cd.v_lob_type_r IN (
			'LTD',
			'STD',
			'VPL',
			'VPS'
		)
LEFT JOIN dim_grp_claim_coverage_r co
	ON cp.n_claim_coverage_sk_r = co.n_claim_coverage_sk_r
		AND co.v_active_status_r = 'Y'





	
	
GROUP BY CP.N_CLAIM_SK_R,
	CD.V_CLAIM_NUMBER_R

UNION

SELECT MAX(CP.D_PAID_DATE_R) D_PAID_DATE_R,
	cp.n_claim_sk_r,
	cg.v_claim_identifier_r v_claim_identifier_r


FROM FCT_CLAIM_PAYMENT_DETAIL_R CP
INNER JOIN dim_time_r td
	ON cp.D_PAID_DATE_R = td.d_calendar_date_r
INNER JOIN dim_grp_claim_dir_r cd
	ON cp.n_claim_sk_r = cd.n_claim_sk_r
		AND cd.v_active_status_r = 'Y'
		AND cd.v_lob_type_r IN (
			'LIFE',
			'NONS',
			'WOP'
			)
LEFT JOIN dim_grp_claim_coverage_r co
	ON cp.n_claim_coverage_sk_r = co.n_claim_coverage_sk_r
		AND co.v_active_status_r = 'Y'
LEFT JOIN dim_grp_claim_coverage_group_r cg
	ON cp.N_CLAIM_COVERAGE_GROUP_SK_R = cg.N_CLAIM_COVERAGE_GROUP_SK_R 
		
		AND CG.V_ACTIVE_STATUS_R = 'Y'

	
	
GROUP BY CP.N_CLAIM_SK_R,
	cg.v_claim_identifier_r;