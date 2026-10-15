-- Cleaned for lineage: PKG_GRP_LOAD_RPT_CLAIM_NOTE_R_INC_PRC_DEL_EXT_DATA

gv_trcmsg:='6.1 START: DELETE EXSISTING RECORDS ';

DELETE 
	  FROM RPT_CLAIM_NOTE_R T
	 WHERE EXISTS ( SELECT 1
					  FROM (SELECT DISTINCT
								   N_CLAIM_SK_R
								 , N_CLAIM_SUBSEQUENCE_NUMBER_R
								 , N_SEQ_R
								 , D_CREATED_DATE_R
								 , N_BATCH_ID_R
							  FROM FCT_GRP_CLAIM_NOTE_R_DRQ_MV_SSL_INC
							 WHERE T_LAST_MODIFIED_DATE_R >=(SELECT max(END_DATE)
															   FROM SSL_PACKAGE_MILESTONE_TABLE
															  WHERE JOB_NAME='PKG_GRP_LOAD_RPT_CLAIM_NOTE_R_INC'
															)
						    ) S
					  WHERE S.N_CLAIM_SK_R                  =   T.N_CLAIM_SK_R
					    AND S.N_CLAIM_SUBSEQUENCE_NUMBER_R  =   T.N_CLAIM_SUBSEQUENCE_NUMBER_R
					    AND S.N_SEQ_R                       =   T.N_SEQ_R
					    AND S.D_CREATED_DATE_R              =   T.D_NOTE_CREATED_DATE_R
					    AND S.N_BATCH_ID_R                  =   T.N_BATCH_ID_R_NOTE
					    AND T.N_YEARMONTH_R = gn_current_month
				     );

gv_trcmsg:='6.2 END: DELETE EXSISTING RECORDS .Total records deleted : '||ln_sqlrowcnt;

gv_trcmsg:='6.3 START: DELETE ACTIVE=N AND PHYSICAL DELETE ';

DELETE 
    FROM RPT_CLAIM_NOTE_R T
	WHERE n_claim_sk_r in ( SELECT n_claim_sk_r
	                          FROM ATOMIC.DIM_GRP_CLAIM_DIR_R
                             WHERE n_claim_sk_r IN (SELECT n_claim_sk_r
													  FROM (SELECT n_claim_sk_r
													             , v_active_status_r
																 , COUNT(1) CNT
															  FROM ATOMIC.DIM_GRP_CLAIM_DIR_R A
															 WHERE n_claim_sk_r > -1
														  GROUP BY n_claim_sk_r
														         , v_active_status_r
													) T GROUP BY n_claim_sk_r
												  HAVING COUNT(1) =1
                           )
							   AND (v_active_status_r='N'
                               AND V_CHANGE_REASON_R = 'Physically Deleted'
								   )
							   AND t_last_modified_date_r>= (SELECT max(END_DATE)
															  FROM SSL_PACKAGE_MILESTONE_TABLE
															 WHERE JOB_NAME='PKG_GRP_LOAD_RPT_CLAIM_NOTE_R_INC'
														     )
						  GROUP BY n_claim_sk_r
						 )
      AND T.N_YEARMONTH_R = gn_current_month;

gv_trcmsg:='6.4 END: DELETE ACTIVE=N AND PHYSICAL DELETE '||ln_sqlrowcnt;