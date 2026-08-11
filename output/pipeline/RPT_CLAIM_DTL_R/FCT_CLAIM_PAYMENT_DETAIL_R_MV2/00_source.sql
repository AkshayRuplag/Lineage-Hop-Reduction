

  CREATE MATERIALIZED VIEW "ATOMIC"."FCT_CLAIM_PAYMENT_DETAIL_R_MV2" ("D_PAID_DATE_R", "N_CLAIM_SK_R", "V_CLAIM_IDENTIFIER_R")
  SEGMENT CREATION IMMEDIATE
  ORGANIZATION HEAP PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "OFS_OIDF_DATA_3"
  BUILD IMMEDIATE
  USING INDEX
  REFRESH FORCE ON DEMAND
  USING DEFAULT LOCAL ROLLBACK SEGMENT
  USING ENFORCED CONSTRAINTS DISABLE ON QUERY COMPUTATION DISABLE QUERY REWRITE
  AS SELECT MAX(CP.D_PAID_DATE_R) D_PAID_DATE_R,
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
--  left join dim_grp_claim_coverage_group_r cg
--on cp.N_CLAIM_COVERAGE_GROUP_SK_R = cg.N_CLAIM_COVERAGE_GROUP_SK_R    --Added on !8-Oct-2022
/* ON (
    CASE
    WHEN cp.N_CLAIM_COVERAGE_GROUP_SK_R = -1
    THEN co.N_CLAIM_COVERAGE_SK_R
    ELSE cp.N_CLAIM_COVERAGE_GROUP_SK_R
    END) = (
    CASE
    WHEN cp.N_CLAIM_COVERAGE_GROUP_SK_R = -1
    THEN cg.N_CLAIM_COVERAGE_SK_R
    ELSE cg.N_CLAIM_COVERAGE_GROUP_SK_R
    END)*/
-- AND CG.V_ACTIVE_STATUS_R = 'Y'
--WHERE
	--cp.n_claim_sk_r = :p_n_claim_sk_r
	--CP.V_PAYMENT_STATUS_R <> 'VOID'
GROUP BY CP.N_CLAIM_SK_R,
	CD.V_CLAIM_NUMBER_R

UNION

SELECT MAX(CP.D_PAID_DATE_R) D_PAID_DATE_R,
	cp.n_claim_sk_r,
	cg.v_claim_identifier_r v_claim_identifier_r
--INTO ld_date
--FROM fct_claim_payment_detail_r CP
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
	ON cp.N_CLAIM_COVERAGE_GROUP_SK_R = cg.N_CLAIM_COVERAGE_GROUP_SK_R --Added on !8-Oct-2022
		/* ON (
    CASE
    WHEN cp.N_CLAIM_COVERAGE_GROUP_SK_R = -1
    THEN co.N_CLAIM_COVERAGE_SK_R
    ELSE cp.N_CLAIM_COVERAGE_GROUP_SK_R
    END) = (
    CASE
    WHEN cp.N_CLAIM_COVERAGE_GROUP_SK_R = -1
    THEN cg.N_CLAIM_COVERAGE_SK_R
    ELSE cg.N_CLAIM_COVERAGE_GROUP_SK_R
    END)*/
		AND CG.V_ACTIVE_STATUS_R = 'Y'
--WHERE
	--cp.n_claim_sk_r = :p_n_claim_sk_r
	--CP.V_PAYMENT_STATUS_R <> 'VOID'
GROUP BY CP.N_CLAIM_SK_R,
	cg.v_claim_identifier_r

