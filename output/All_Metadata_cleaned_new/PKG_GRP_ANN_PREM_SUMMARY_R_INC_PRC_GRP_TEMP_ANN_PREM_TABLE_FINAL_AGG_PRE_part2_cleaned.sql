-- Cleaned for lineage: PKG_GRP_ANN_PREM_SUMMARY_R_INC_PRC_GRP_TEMP_ANN_PREM_TABLE_FINAL_AGG_PRE (part 2/2)

delete  from TEMP_ANN_PREM_TABLE_FINAL_AGG_PRE A1
        WHERE nvl(V_COVERAGE_CODE_R, 9999) NOT IN ( 1200 , 2100 ) AND EXISTS (SELECT 1  FROM  TEMP_ANN_PREM_TABLE_FINAL_AGG_PRE a2
                WHERE a1.N_POLICY_SK_R = a2.N_POLICY_SK_R AND a1.N_POLICY_BILLGROUP_ID_R = a2.N_POLICY_BILLGROUP_ID_R AND A1.N_PREMIUM_MODE_FACTOR_R <> 0
                GROUP BY a2.N_POLICY_SK_R, a2.N_POLICY_BILLGROUP_ID_R
                HAVING  MONTHS_BETWEEN (MAX(a2.D_DUE_DATE_R) , a1.D_DUE_DATE_R) >= (12 / A1.N_PREMIUM_MODE_FACTOR_R) * 6 );

INSERT INTO ATOMIC.PRCS_GRP_TBL_LOAD_DEBUG_TRC(V_JOB_NAME_R
                                               ,V_PKG_PRC_NAME_R
                                               ,N_SK_R
                                               ,V_NUMBER_R
                                               ,V_TRC_MSG_R
                                               ,N_BATCH_ID_R
                                               ,v_created_by_r
                                               ,V_LAST_MODIFIED_BY_R
                                              )
										VALUES('GRP_LOAD_TEMP_ANN_PREM_TABLE_FINAL_AGG_PRE'
										      ,'PKG_GRP_ANN_PREM_SUMMARY_R_INC.PRC_GRP_TEMP_ANN_PREM_TABLE_FINAL_AGG_PRE'
											  ,NULL
											  ,NULL
											  ,gc_step
											  ,ln_N_BATCH_ID_R
											  ,'PKG_GRP_ANN_PREM_SUMMARY_R_INC.PRC_GRP_TEMP_ANN_PREM_TABLE_FINAL_AGG_PRE'
											  ,'PKG_GRP_ANN_PREM_SUMMARY_R_INC.PRC_GRP_TEMP_ANN_PREM_TABLE_FINAL_AGG_PRE'
										);