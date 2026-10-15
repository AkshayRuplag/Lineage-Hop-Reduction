-- Cleaned for lineage: PKG_GRP_LOAD_STG_GRP_CLAIM_SUMMARY_R_PRC_LOAD_STG_GRP_CLAIM_SUMMARY_R (part 1/3)

INSERT
  INTO FCT_PROC_EXEC_STATUS_LOG_R
    (
      N_BATCH_ID_R,
      N_MIS_DATE_SKEY_R,
      N_LOAD_RUN_ID_R,
      V_STATUS_R,
      T_EXECUTION_TIMESTAMP_R,
      V_USER_R,
      V_PLSQL_BLOCK_NAME_R,
      N_SERIAL_NUM_R
    )
    VALUES
    (
      99999999,
      TO_CHAR(sysdate,'yyyymmdd'),
      1,
      'Started',
      SYSTIMESTAMP,
      USER,
      'PRC_LOAD_STG_GRP_CLAIM_SUMMARY_R',
      N_MAX_SERIAL_NUM_R
    );