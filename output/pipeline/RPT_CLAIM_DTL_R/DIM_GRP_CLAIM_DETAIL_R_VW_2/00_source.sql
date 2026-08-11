
  CREATE OR REPLACE FORCE EDITIONABLE VIEW "ATOMIC"."DIM_GRP_CLAIM_DETAIL_R_VW_2" ("N_CLAIM_SK_R", "V_CLAIM_STATUS_REASON_CODE_R", "V_REASON_CODE_R", "T_EVENT_TIMESTAMP_R_1", "T_EVENT_TIMESTAMP_R_2", "V_REASON_FLAG_R", "V_CLAIM_NUMBER_R", "N_CLAIM_COVERAGE_SK_R", "N_CLAIM_COVERAGE_GROUP_SK_R", "V_CLAIM_IDENTIFIER_R", "V_CLAIM_COVERAGE_CODE_R", "N_POLICY_SK_R", "V_POLICY_NUMBER_R") AS
  select
    n_claim_sk_r,
    v_claim_status_reason_code_r,
    v_reason_code_r,
    t_event_timestamp_r_1,
    t_event_timestamp_r_2,
    v_reason_flag_r,
    v_claim_number_r,
    n_claim_coverage_sk_r,
    n_claim_coverage_group_sk_r,
    v_claim_identifier_r,
    v_claim_coverage_code_r,
    n_policy_sk_r,
    v_policy_number_r
from (
    SELECT
        a.n_claim_sk_r,
        a.v_claim_status_reason_code_r,
        a.v_reason_code_r,
        a.t_event_timestamp_r_1,
        a.t_event_timestamp_r_2,
        a.v_reason_flag_r,
        a.v_claim_number_r,
        a.n_claim_coverage_sk_r,
        a.n_claim_coverage_group_sk_r,
        a.v_claim_identifier_r,
        a.v_claim_coverage_code_r,
        a.n_policy_sk_r,
       /* CASE
            WHEN b.N_CLAIM_CVRG_GRP_SRC_SYS_KEY_R IS NULL
			THEN CASE
					WHEN rank() OVER (
							PARTITION BY b.n_claim_sk_r ORDER BY nvl(b.N_CLAIM_CVRG_GRP_SRC_SYS_KEY_R, 0) DESC
							) = 1
						THEN 1
					ELSE 0
					END
            ELSE 1
		END df_cvg,----GETTING MULTIPLE REC FOR N_CLAIM_CVRG_GRP_SRC_SYS_KEY_R AS NULL HENCE THERE WERE DUPLICATES..*/



		--rank() OVER (PARTITION BY b.n_claim_sk_r ORDER BY b.N_CLAIM_CVRG_SEQUENCE_NUMBER_R DESC NULLS LAST) df_cvg, --commented because it was falsely removing valid claims
		case WHEN b.N_CLAIM_CVRG_GRP_SRC_SYS_KEY_R IS NULL
			THEN CASE
					WHEN rank() OVER (
							PARTITION BY b.n_claim_sk_r ORDER BY b.N_CLAIM_CVRG_GRP_SRC_SYS_KEY_R desc nulls last, b.N_CLAIM_CVRG_SEQUENCE_NUMBER_R desc NULLS LAST
							) = 1
						THEN 1
					ELSE 0
					END
        ELSE 1
        end             as df_cvg, --Added July 2024
    --pkg_grp_load_fct_rpt_claim_summary_r_incr_hpc.get_v_policy_number_r(A.n_policy_sk_r) v_policy_number
        (
            SELECT
      --/*+PARALLEL(4)*/
                v_policy_number_r
            FROM
                dim_grp_policy_dir_r dim_grp_policy_dir_r
            WHERE
                    dim_grp_policy_dir_r.n_policy_sk_r = a.n_policy_sk_r
                AND v_active_status_r = 'Y'
            GROUP BY
                v_policy_number_r
        ) v_policy_number_r
    FROM
        DIM_GRP_CLAIM_DETAIL_R_VW a
    JOIN
        DIM_GRP_CLAIM_COVERAGE_GROUP_R b
        ON b.n_claim_sk_r = a.n_claim_sk_r
		and b.v_claim_identifier_r = a.v_claim_identifier_r
        and b.v_active_status_r = 'Y'
    )
    where df_cvg = 1;

