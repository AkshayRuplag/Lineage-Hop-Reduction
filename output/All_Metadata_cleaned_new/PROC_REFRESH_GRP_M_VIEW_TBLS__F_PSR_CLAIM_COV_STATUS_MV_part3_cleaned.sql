-- Cleaned for lineage: PROC_REFRESH_GRP_M_VIEW_TBLS__F_PSR_CLAIM_COV_STATUS_MV (part 3/3)

UPDATE FCT_PROC_EXEC_STATUS_LOG_R
						SET V_STATUS_R                = 'Successful',
						T_EXECUTION_END_TIMESTAMP_R = systimestamp
						WHERE N_SERIAL_NUM_R          = N_MAX_SERIAL_NUM_R;