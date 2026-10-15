-- Cleaned for lineage: PRC_GRP_LOAD_FCT_LG_RESERVE_DETAILS_R (part 3/3)

INSERT INTO ATOMIC.PRCS_GRP_TBL_LOAD_DEBUG_TRC(V_JOB_NAME_R
                                                   ,V_PKG_PRC_NAME_R
                                                   ,N_SK_R
                                                   ,V_NUMBER_R
                                                   ,V_TRC_MSG_R
                                                   ,N_BATCH_ID_R
                                                   ,v_created_by_r
                                                   ,V_LAST_MODIFIED_BY_R
                                                  )
    										VALUES('GRP_LOAD_FCT_LG_RESERVE_DETAILS_R'
    										      ,'PRC_GRP_LOAD_FCT_LG_RESERVE_DETAILS_R'
    											  ,NULL
    											  ,NULL
    											  ,lc_trcmsg
    											  ,ln_N_BATCH_ID_R
    											  ,'PRC_GRP_LOAD_FCT_LG_RESERVE_DETAILS_R'
    											  ,'PRC_GRP_LOAD_FCT_LG_RESERVE_DETAILS_R'
    										);