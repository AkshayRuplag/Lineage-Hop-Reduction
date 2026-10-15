-- Cleaned for lineage: CLAIM_NOTE_TIER_MV

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
					P_MV_TBL_NAME||'.PROC_REFRESH_GRP_M_VIEW_TBLS.CLAIM_NOTE_TIER_MV_TBL',
					N_MAX_SERIAL_NUM_R
					);

INSERT  INTO CLAIM_NOTE_TIER_MV_TBL (
				 V_TIER_R           ,
				 N_CLAIM_SK_R       ,
				 V_CLAIM_NUMBER_R   ,
				 D_CREATED_DATE_R   ,
				 RANK
				)
				select distinct * from
				(select a.v_tier_r,  a.n_claim_sk_r ,b.v_claim_number_r,D_CREATED_DATE_R,   RANK() OVER (PARTITION BY a.N_CLAIM_SK_R
				ORDER BY a.D_CREATED_DATE_R DESC,a.V_CREATED_TIME_R DESC, N_CLAIM_SUBSEQUENCE_NUMBER_R DESC) rank
				from
				(select * from FCT_GRP_CLAIM_NOTE_R F where F.N_CLAIM_SK_R >-1
				and f.V_TIER_R is not null
				) a,
				dim_grp_claim_dir_r b
				where
				a.n_claim_sk_r = b.n_claim_sk_r
				and b.v_active_status_r = 'Y'
				)
				where RANK = 1;

UPDATE FCT_PROC_EXEC_STATUS_LOG_R
							SET V_STATUS_R                = 'Successful',
							T_EXECUTION_END_TIMESTAMP_R = systimestamp
							WHERE N_SERIAL_NUM_R          = N_MAX_SERIAL_NUM_R;