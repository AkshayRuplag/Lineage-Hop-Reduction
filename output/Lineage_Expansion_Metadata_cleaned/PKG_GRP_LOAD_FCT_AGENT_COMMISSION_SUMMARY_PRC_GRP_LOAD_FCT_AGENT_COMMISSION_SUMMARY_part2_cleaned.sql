-- Cleaned for lineage: PKG_GRP_LOAD_FCT_AGENT_COMMISSION_SUMMARY_PRC_GRP_LOAD_FCT_AGENT_COMMISSION_SUMMARY (part 2/2)

-- Lineage: Cursor CUR_V_DEBUG_FLAG_R (target inferred from procedure)
SELECT
            v_debug_flag_r,
            n_bulk_limit_r
        FROM
            prcs_grp_dataingestion_param_r
        WHERE
            v_job_name_r = 'GRP_LOAD_FCT_AGENT_COMMISSION_SUMMARY';

-- Lineage: Cursor CUR_MAX_N_SEQUENCE_NUMBER_R (target inferred from procedure)
SELECT
            nvl(MAX(n_sequence_number_r), 0)
        FROM
            fct_agent_commission_summary;