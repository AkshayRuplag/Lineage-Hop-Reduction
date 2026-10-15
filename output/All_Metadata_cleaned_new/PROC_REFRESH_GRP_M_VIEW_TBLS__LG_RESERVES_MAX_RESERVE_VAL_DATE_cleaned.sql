-- Cleaned for lineage: LG_RESERVES_MAX_RESERVE_VAL_DATE

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
				P_MV_TBL_NAME||'.PROC_REFRESH_GRP_M_VIEW_TBLS.LG_RESERVES_MAX_RESERVE_VAL_DATE_MV_TBL',
				N_MAX_SERIAL_NUM_R
				);

INSERT
			INTO LG_RESERVES_MAX_RESERVE_VAL_DATE_MV_TBL
			  (
				CLAIM_IDENTIFIER,
				CLAIM_ID_RESERVE_VALUATION_DATE,
				RESERVE_VALUATION_DATE
			  )
			SELECT
			  DISTINCT d1.c5                                                     AS CLAIM_IDENTIFIER,
			  concat(D1.c5, NVL(CAST(D1.c2 AS VARCHAR ( 20 ) ) , '01-JAN-1900')) AS CLAIM_ID_RESERVE_VALUATION_DATE,
			  NVL(CAST(D1.c2 AS VARCHAR ( 20 ) ) , '01/JAN/1900')                AS RESERVE_VALUATION_DATE
			FROM
						  (SELECT
				MAX(1)                                  AS c1,
				MAX(T424800.D_RESERVE_VALUATION_DATE_R) AS c2,
				t357774.v_claim_identifier_r                AS c5
			  FROM dim_grp_claim_coverage_group_r  t357774  
			  LEFT OUTER JOIN fct_lg_reserve_details_r        t424800  
			  ON t357774.v_claim_identifier_r = t424800.v_claim_identifier_r
			WHERE
			t357774.v_active_status_r='Y'			 
			  GROUP BY t357774.v_claim_identifier_r
			  )d1;

UPDATE FCT_PROC_EXEC_STATUS_LOG_R
						SET V_STATUS_R                = 'Successful',
						T_EXECUTION_END_TIMESTAMP_R = systimestamp
						WHERE N_SERIAL_NUM_R          = N_MAX_SERIAL_NUM_R;