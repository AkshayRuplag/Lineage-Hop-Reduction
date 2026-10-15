-- Cleaned for lineage: FCT_RPT_EOI_HISTORY_R_MV_TBL

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
					P_MV_TBL_NAME||'.PROC_REFRESH_GRP_M_VIEW_TBLS.FCT_RPT_EOI_HISTORY_R_MV_TBL',
					N_MAX_SERIAL_NUM_R
					);

INSERT  INTO  FCT_RPT_EOI_HISTORY_R_MV_TBL
	            (N_BATCH_ID_R
                 ,V_POLICY_PREFIX_R
                 ,V_RSO_R
                 ,V_CLIENT_NAME_R
                 ,D_APPLICATION_ENTRY_DATE_R
                 ,N_APPLICATION_ID_R
                 ,V_EOI_LOGIN_ID_R
                 ,N_APPROVED_APP_COUNT_R
                 ,N_DECLINED_APP_COUNT_R
                 ,N_INCOMPLETE_APP_COUNT_R
                 ,N_DECLINED_INCOMPLETE_APPCNT_R
                 ,N_PENDING_APP_COUNT_R
                 ,N_EMPLOYEE_APP_COUNT_R
                 ,N_SPOUSE_APP_COUNT_R
                 ,N_CHILD_APP_COUNT_R
                 ,N_APP_COUNT_R
                 ,N_AUTO_APPROVAL_COUNT_R
                 ,D_EMPLOYEE_GI_EFFECTIVE_DATE_R
                 ,N_EMPLOYEE_GI_APPROVED_R
                 ,N_EMPLOYEE_GI_DECLINED_R
                 ,N_EMPLOYEE_GI_PENDING_R
                 ,D_SPOUSE_GI_EFFECTIVE_DATE_R
                 ,N_SPOUSE_GI_APPROVED_R
                 ,N_SPOUSE_GI_DECLINED_R
                 ,N_SPOUSE_GI_PENDING_R
                 ,D_CHILD_GI_EFFECTIVE_DATE_R
                 ,N_CHILD_GI_APPROVED_R
                 ,N_CHILD_GI_DECLINED_R
                 ,N_CHILD_GI_PENDING_R
                 ,D_EMPLOYEE_EXCESS_EFF_DATE_R
                 ,N_EMPLOYEE_EXCESS_APPRVD_AMT_R
                 ,N_EMPLOYEE_EXCESSDECLINEDAMT_R
                 ,N_EMPLOYEE_EXCESSINCOMPLTAMT_R
                 ,N_EMPLOYEE_EXCESS_PENDINGAMT_R
                 ,D_SPOUSE_EXCESS_EFF_DATE_R
                 ,N_SPOUSE_EXCESS_APPROVED_AMT_R
                 ,N_SPOUSE_EXCESS_DECLINED_AMT_R
                 ,N_SPOUSE_EXCESS_INCOMPLTEAMT_R
                 ,N_SPOUSE_EXCESS_PENDING_AMT_R
                 ,N_LOAD_RUN_ID_R
                 ,N_SEQUENCE_NUMBER_R
                 ,T_CREATION_DATE_R
                 ,T_EVENT_TIMESTAMP_R
                 ,T_LAST_MODIFIED_DATE_R
                 ,V_CREATED_BY_R
                 ,V_LAST_MODIFIED_BY_R
                 ,D_CYCLE_DATE_R
                 ,FIC_MIS_DATE_R
                 ,V_SOURCE_SYSTEM_NAME_R
                 ,V_SUBJECT_AREA_TYPE_R
                 ,N_VERSION_NUMBER_R
                 ,F_PHYSICAL_DELETE_R
                 ,V_CHANGE_REASON_R
                 ,V_POLICY_SUFFIX_R
                 ,N_POLICY_SK_R
                 ,N_CLAIM_SK_R
                 ,N_PARTY_SK_R
                 ,N_QUOTE_SK_R
                 ,V_POLICY_SFX_R
                 ,N_APPLICATION_HISTORY_SK_R
                 ,V_ENTITY_TYPE_R
                 ,V_CODE_R
                 ,V_PRIVACY_INDICATOR_R
                 ,N_LOB_APP_COUNT_R
                 ,D_APP_ENTRY_DATE_R
                 ,APP_BUCKET
                 ,N_APP_PENDING_COUNT_R)
	             WITH APP_MAX AS
                    (SELECT MAX(D_APPLICATION_ENTRY_DATE_R) AS MAX_D_APPLICATION_ENTRY_DATE_R,
                    N_APPLICATION_ID_R FROM FCT_RPT_EOI_HISTORY_R WHERE V_CODE_R='APP' GROUP BY N_APPLICATION_ID_R
                    ),
                    APP_PENDING_COUNT_R AS(
                    SELECT N_APPLICATION_ID_R,
                    CASE WHEN (sum(N_APPROVED_APP_COUNT_R+ N_DECLINED_APP_COUNT_R + N_INCOMPLETE_APP_COUNT_R+ N_DECLINED_INCOMPLETE_APPCNT_R)>=1
                                 AND SUM(N_PENDING_APP_COUNT_R)>=1)
                                 THEN 0
                                 ELSE 1
                                 END AS N_APP_PENDING_COUNT_R
                    FROM FCT_RPT_EOI_HISTORY_R GROUP BY N_APPLICATION_ID_R
                    )
                    select                   
					A.N_BATCH_ID_R
                    ,A.V_POLICY_PREFIX_R
                    ,A.V_RSO_R
                    ,A.V_CLIENT_NAME_R
                    ,A.D_APPLICATION_ENTRY_DATE_R
                    ,A.N_APPLICATION_ID_R
                    ,A.V_EOI_LOGIN_ID_R
                    ,A.N_APPROVED_APP_COUNT_R
                    ,A.N_DECLINED_APP_COUNT_R
                    ,A.N_INCOMPLETE_APP_COUNT_R
                    ,A.N_DECLINED_INCOMPLETE_APPCNT_R
                    ,A.N_PENDING_APP_COUNT_R
                    ,A.N_EMPLOYEE_APP_COUNT_R
                    ,A.N_SPOUSE_APP_COUNT_R
                    ,A.N_CHILD_APP_COUNT_R
                    ,A.N_APP_COUNT_R
                    ,A.N_AUTO_APPROVAL_COUNT_R
                    ,A.D_EMPLOYEE_GI_EFFECTIVE_DATE_R
                    ,A.N_EMPLOYEE_GI_APPROVED_R
                    ,A.N_EMPLOYEE_GI_DECLINED_R
                    ,A.N_EMPLOYEE_GI_PENDING_R
                    ,A.D_SPOUSE_GI_EFFECTIVE_DATE_R
                    ,A.N_SPOUSE_GI_APPROVED_R
                    ,A.N_SPOUSE_GI_DECLINED_R
                    ,A.N_SPOUSE_GI_PENDING_R
                    ,A.D_CHILD_GI_EFFECTIVE_DATE_R
                    ,A.N_CHILD_GI_APPROVED_R
                    ,A.N_CHILD_GI_DECLINED_R
                    ,A.N_CHILD_GI_PENDING_R
                    ,A.D_EMPLOYEE_EXCESS_EFF_DATE_R
                    ,A.N_EMPLOYEE_EXCESS_APPRVD_AMT_R
                    ,A.N_EMPLOYEE_EXCESSDECLINEDAMT_R
                    ,A.N_EMPLOYEE_EXCESSINCOMPLTAMT_R
                    ,A.N_EMPLOYEE_EXCESS_PENDINGAMT_R
                    ,A.D_SPOUSE_EXCESS_EFF_DATE_R
                    ,A.N_SPOUSE_EXCESS_APPROVED_AMT_R
                    ,A.N_SPOUSE_EXCESS_DECLINED_AMT_R
                    ,A.N_SPOUSE_EXCESS_INCOMPLTEAMT_R
                    ,A.N_SPOUSE_EXCESS_PENDING_AMT_R
                    ,A.N_LOAD_RUN_ID_R
                    ,A.N_SEQUENCE_NUMBER_R
                    ,A.T_CREATION_DATE_R
                    ,A.T_EVENT_TIMESTAMP_R
                    ,A.T_LAST_MODIFIED_DATE_R
                    ,A.V_CREATED_BY_R
                    ,A.V_LAST_MODIFIED_BY_R
                    ,A.D_CYCLE_DATE_R
                    ,A.FIC_MIS_DATE_R
                    ,A.V_SOURCE_SYSTEM_NAME_R
                    ,A.V_SUBJECT_AREA_TYPE_R
                    ,A.N_VERSION_NUMBER_R
                    ,A.F_PHYSICAL_DELETE_R
                    ,A.V_CHANGE_REASON_R
                    ,A.V_POLICY_SUFFIX_R
                    ,A.N_POLICY_SK_R
                    ,A.N_CLAIM_SK_R
                    ,A.N_PARTY_SK_R
                    ,A.N_QUOTE_SK_R
                    ,A.V_POLICY_SFX_R
                    ,A.N_APPLICATION_HISTORY_SK_R
                    ,A.V_ENTITY_TYPE_R
                    ,A.V_CODE_R
                    ,A.V_PRIVACY_INDICATOR_R
                    ,A.N_LOB_APP_COUNT_R
				    ,B.MAX_D_APPLICATION_ENTRY_DATE_R AS D_APP_ENTRY_DATE_R
                    ,CASE WHEN (A.D_APPLICATION_ENTRY_DATE_R-B.MAX_D_APPLICATION_ENTRY_DATE_R) BETWEEN 0 AND 30 THEN '1-30'
                    WHEN (A.D_APPLICATION_ENTRY_DATE_R-B.MAX_D_APPLICATION_ENTRY_DATE_R) BETWEEN 31 AND 60 THEN '31-60'
                    WHEN (A.D_APPLICATION_ENTRY_DATE_R-B.MAX_D_APPLICATION_ENTRY_DATE_R) BETWEEN 61 AND 90 THEN '61-90'
                    ELSE NULL
                    END
                    AS APP_BUCKET
                    ,C.N_APP_PENDING_COUNT_R
                    from FCT_RPT_EOI_HISTORY_R A
                    LEFT OUTER JOIN APP_MAX B
                    ON A.N_APPLICATION_ID_R=B.N_APPLICATION_ID_R
                    LEFT OUTER JOIN APP_PENDING_COUNT_R C
                    ON A.N_APPLICATION_ID_R=C.N_APPLICATION_ID_R;

UPDATE FCT_PROC_EXEC_STATUS_LOG_R
                    							SET V_STATUS_R                = 'Successful',
                    							T_EXECUTION_END_TIMESTAMP_R = systimestamp
                    							WHERE N_SERIAL_NUM_R          = N_MAX_SERIAL_NUM_R;