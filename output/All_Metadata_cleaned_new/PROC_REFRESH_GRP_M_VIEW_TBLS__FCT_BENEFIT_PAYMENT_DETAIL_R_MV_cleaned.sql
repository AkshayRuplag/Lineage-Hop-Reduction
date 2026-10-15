-- Cleaned for lineage: FCT_BENEFIT_PAYMENT_DETAIL_R_MV

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
					P_MV_TBL_NAME||'.PROC_REFRESH_GRP_M_VIEW_TBLS.FCT_BENEFIT_PAYMENT_DETAIL_R_MV_TBL',
					N_MAX_SERIAL_NUM_R
					);

INSERT  INTO FCT_BENEFIT_PAYMENT_DETAIL_R_MV_TBL (n_claim_sk_r,
	n_policy_sk_r,
	v_benefit_code_r,
	n_amount_r)
				SELECT fbpd.n_claim_sk_r,fbpd.n_policy_sk_r,fbpd.v_benefit_code_r,fbpd.n_amount_r
				FROM fct_benefit_payment_detail_r FBPD
				JOIN dim_grp_claim_dir_r DGCD
				ON DGCD.n_claim_sk_r  = FBPD.n_claim_sk_r
				JOIN dim_grp_policy_dir_r DGPD
				ON DGPD.n_policy_sk_r = DGCD.n_policy_sk_r
				GROUP BY fbpd.n_claim_sk_r,fbpd.n_policy_sk_r,fbpd.v_benefit_code_r,fbpd.n_amount_r;

UPDATE FCT_PROC_EXEC_STATUS_LOG_R
							SET V_STATUS_R                = 'Successful',
							T_EXECUTION_END_TIMESTAMP_R = systimestamp
							WHERE N_SERIAL_NUM_R          = N_MAX_SERIAL_NUM_R;