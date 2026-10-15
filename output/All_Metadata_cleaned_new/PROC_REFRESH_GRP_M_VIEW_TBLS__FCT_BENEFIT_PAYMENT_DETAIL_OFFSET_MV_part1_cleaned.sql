-- Cleaned for lineage: PROC_REFRESH_GRP_M_VIEW_TBLS__FCT_BENEFIT_PAYMENT_DETAIL_OFFSET_MV (part 1/3)

-- Cleaned for lineage: FCT_BENEFIT_PAYMENT_DETAIL_OFFSET_MV

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
					LN_BATCH_ID_R,
					TO_CHAR(sysdate,'yyyymmdd'),
					1,
					'Started',
					SYSTIMESTAMP,
					USER,
					P_MV_TBL_NAME||'.PROC_REFRESH_GRP_M_VIEW_TBLS.FCT_BENEFIT_PAYMENT_DETAIL_OFFSET_MV_TBL',
					N_MAX_SERIAL_NUM_R
					);