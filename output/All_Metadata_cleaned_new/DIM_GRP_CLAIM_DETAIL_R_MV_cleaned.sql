-- Cleaned for lineage: DIM_GRP_CLAIM_DETAIL_R_MV

CREATE MATERIALIZED VIEW DIM_GRP_CLAIM_DETAIL_R_MV AS
SELECT
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
    FROM
        dim_grp_claim_detail_r_vw_2;