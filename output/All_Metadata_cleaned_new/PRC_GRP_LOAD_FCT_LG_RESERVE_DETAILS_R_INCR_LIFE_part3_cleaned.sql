-- Cleaned for lineage: PRC_GRP_LOAD_FCT_LG_RESERVE_DETAILS_R_INCR_LIFE (part 3/3)

INSERT INTO ATOMIC.PRCS_GRP_TBL_LOAD_DEBUG_TRC (
            V_JOB_NAME_R,
            V_PKG_PRC_NAME_R,
            N_SK_R,
            V_NUMBER_R,
            V_TRC_MSG_R,
            N_BATCH_ID_R,
            V_CREATED_BY_R,
            V_LAST_MODIFIED_BY_R
        ) VALUES (
            'PRC_GRP_LOAD_FCT_LG_RESERVE_DETAILS_R_INCR_LIFE',
            'PRC_GRP_LOAD_FCT_LG_RESERVE_DETAILS_R_INCR_LIFE',
            NULL,
            NULL,
            'WHEN OTHERS RAISED IN PRC_GRP_LOAD_FCT_LG_RESERVE_DETAILS_R_INCR_LIFE :->'
            || LC_TRCMSG
            || LC_SQLCODE
            || '->'
            || LC_SQLERRM,
            LN_N_BATCH_ID_R,
            'PRC_GRP_LOAD_FCT_LG_RESERVE_DETAILS_R_INCR_LIFE',
            'PRC_GRP_LOAD_FCT_LG_RESERVE_DETAILS_R_INCR_LIFE'
        );