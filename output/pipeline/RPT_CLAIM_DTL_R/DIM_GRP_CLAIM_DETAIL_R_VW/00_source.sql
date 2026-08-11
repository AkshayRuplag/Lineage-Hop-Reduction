
  CREATE OR REPLACE FORCE EDITIONABLE VIEW "ATOMIC"."DIM_GRP_CLAIM_DETAIL_R_VW" ("N_CLAIM_SK_R", "V_CLAIM_STATUS_REASON_CODE_R", "V_REASON_CODE_R", "T_EVENT_TIMESTAMP_R_1", "T_EVENT_TIMESTAMP_R_2", "V_REASON_FLAG_R", "V_CLAIM_NUMBER_R", "N_CLAIM_COVERAGE_SK_R", "N_CLAIM_COVERAGE_GROUP_SK_R", "V_CLAIM_IDENTIFIER_R", "V_CLAIM_COVERAGE_CODE_R", "N_POLICY_SK_R") AS
  SELECT
		--/*+PARALLEL(16)*/
        a.n_claim_sk_r,
		--3.claim status code for some life claims  changes starts
        --a.v_claim_status_reason_code_r,
		(CASE WHEN (C.V_LOB_TYPE_R IN ('VPS', 'STD', 'VPL', 'LTD') OR C.V_SOURCE_SYSTEM_NAME_R = 'CV') THEN
		 a.v_claim_status_reason_code_r
		ELSE ''
		END) v_claim_status_reason_code_r,
		--3.claim status code for some life claims  changes ends
        b.v_reason_code_r, --Add not in above LOB CASE WHEN NOT IN VPS, STD, VPL or LTD then value else ''
        b.t_event_timestamp_r             t_event_timestamp_r_1,
        a.t_event_timestamp_r             t_event_timestamp_r_2,
        CAST(NULL AS VARCHAR2(20))        v_reason_flag_r,
        a.v_claim_number_r,
        b.n_claim_coverage_sk_r,
        b.n_claim_coverage_group_sk_r,
        b.v_claim_identifier_r,
        b.v_claim_coverage_code_r -- CHECK THE USAGE
        ,
        (
            SELECT
                n_policy_sk_r
            FROM
                dim_grp_claim_dir_r a2
            WHERE
                    a2.n_claim_sk_r = a.n_claim_sk_r
                AND a2.v_active_status_r = 'Y'
            GROUP BY
                a2.n_policy_sk_r
        )                                 n_policy_sk_r
    --      ,( SELECT
    --   A1.v_policy_number_r
    --  FROM dim_grp_policy_dir_r A1
    --  WHERE
    --  A1.v_active_status_r = 'Y'
    --  AND exists (select 1 from  dim_grp_claim_dir_r B1
    --  WHERE B1.n_claim_sk_r    = A.n_claim_sk_r
    --  AND B1.v_active_status_r = 'Y'
    --  AND A1.n_policy_sk_r=B1.n_policy_sk_r
    --  GROUP BY B1.n_policy_sk_r)
    --  GROUP BY A1.v_policy_number_r) v_policy_number_r
    FROM
        ATOMIC.dim_grp_claim_dir_r c --3.claim status code for some life claims  changes
		join (select * from ATOMIC.dim_grp_claim_detail_r where --Removed ASW from filter for policy prefix as legacy has ASW policies (July 2024)
        (v_policy_prefix_r NOT IN ('ASL') or v_policy_prefix_r is null) and n_claim_sk_r > -1 and v_active_status_r = 'Y') a
        on a.n_claim_sk_r = c.n_claim_sk_r
		and a.n_claim_sk_r > -1
		AND c.v_active_status_r = 'Y'
		and a.v_active_status_r = 'Y'
		and c.v_active_status_r = 'Y'
        LEFT JOIN ATOMIC.dim_grp_claim_coverage_group_r  b ON a.n_claim_sk_r = b.n_claim_sk_r
													AND b.v_claim_number_r = c.v_claim_number_r
                                                    AND b.v_active_status_r = 'Y'
													/* Any claim that has Error status in Claim Detail should not be considered (Oct 2024) */
													AND NOT (a.v_claim_status_reason_code_r in ('91', '92') and b.v_reason_code_r = '22')

    WHERE
        b.t_event_timestamp_r = (
            SELECT
                MAX(c.t_event_timestamp_r)
            FROM
                ATOMIC.dim_grp_claim_coverage_group_r c
            WHERE
                b.v_claim_identifier_r = c.v_claim_identifier_r
        )
		--03-Nov-2023 changes starts
        --1.	Filter out claims where v_lob_type_r is 'ANNUITY' so we remove annuities
		AND  EXISTS (SELECT 1
		                  FROM ATOMIC.dim_grp_claim_dir_r d
						  WHERE d.v_active_status_r = 'Y'
                            AND d.v_lob_type_r <> 'ANNUITY'
						    AND d.n_claim_sk_r=a.n_claim_sk_r
						)
		--2.	Policy prefix not in (ASW, ASL)
		--AND d.v_policy_prefix_r NOT IN ('ASW', 'ASL') --4. Policy prefix fetched from Policy Dir
		--03-Nov-2023 changes ends
    GROUP BY
        A.N_CLAIM_SK_R,
        --3.claim status code for some life claims  changes starts
       -- a.v_claim_status_reason_code_r,
       (CASE WHEN (C.V_LOB_TYPE_R IN ('VPS', 'STD', 'VPL', 'LTD') OR C.V_SOURCE_SYSTEM_NAME_R = 'CV') THEN
		 a.v_claim_status_reason_code_r
		ELSE ''
		END),
    --3.claim status code for some life claims  changes ends
        b.v_reason_code_r,
        b.t_event_timestamp_r,
        a.t_event_timestamp_r,
        a.v_claim_number_r,
        b.n_claim_coverage_sk_r,
        b.n_claim_coverage_group_sk_r,
        B.V_CLAIM_IDENTIFIER_R,
        b.v_claim_coverage_code_r;

