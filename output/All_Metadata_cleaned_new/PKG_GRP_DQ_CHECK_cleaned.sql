-- Cleaned for lineage: PKG_GRP_DQ_CHECK

INSERT INTO PRC_DQ_CHECK_AUDIT_R (
                 N_AUDIT_ID_R
				,N_BATCH_ID_R
				,V_RUN_ID_R
				,T_CHECK_TIMESTAMP_R
				,V_TBL_NM_R 
				,V_COLUMN_NM_R 
				,N_DQ_RULE_ID_R 
				,V_DQ_RULE_NM_R
				,V_CHECK_RESULT_R 
				,V_SEVERITY_R
				,N_AFFECTED_ROWS_R 
				,N_TOTAL_ROWS_R 
				,N_FAILURE_PCT_R
				,V_EXECUTION_TIME_R
				,V_DETAIL_MSG_R 
				,V_EXECUTED_BY_R
				,V_DQ_CUSTOM_TYPE_R
			)
			VALUES (
				lv_audit_id
				,gn_sysdt_batchid
				,gn_out_job_id
				,SYSTIMESTAMP
                ,r_rule.V_TBL_NM_R
				,r_rule.V_COLUMN_NM_R
				,r_rule.N_DQ_RULE_ID_R
				,r_rule.V_DQ_RULE_NM_R
				,lv_check_result
				,lv_severity	
				,lv_failed_rows
				,lv_total_count
				,ln_failed_percentage	
				,FNC_GRP_TIME_DURATION(lv_start_time,lv_end_time)
				,lv_detail_msg
				,USER
				,r_rule.V_DQ_CUSTOM_TYPE_R
			);

-- Lineage: Cursor C_RULES (target inferred from procedure)
SELECT p.V_TBL_NM_R, p.V_COLUMN_NM_R, r.N_DQ_RULE_ID_R, r.V_DQ_RULE_NM_R, p.V_DQ_RULE_VAL_R, p.V_DQ_CUSTOM_QUERY,p.V_DQ_CUSTOM_TYPE_R
        FROM PRC_DQ_RULE_PARAM_R p
        JOIN PRC_DQ_RULE_MASTER_R r 
		  ON p.N_DQ_RULE_ID_R = r.N_DQ_RULE_ID_R
       WHERE 
		     p.V_ACTIVE_IND_R = &apos;