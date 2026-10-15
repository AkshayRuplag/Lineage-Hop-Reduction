-- Cleaned for lineage: FCT_CLAIM_PAYMENT_SUMMARY_MV_TBL

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
					P_MV_TBL_NAME||'.PROC_REFRESH_GRP_M_VIEW_TBLS.FCT_CLAIM_PAYMENT_SUMMARY_MV_TBL',
					N_MAX_SERIAL_NUM_R
					);

INSERT  INTO  FCT_CLAIM_PAYMENT_SUMMARY_MV_TBL
                        (V_CLAIM_NUMBER_R
                        ,N_CLAIM_COVERAGE_GROUP_SK_R
                        ,V_COVERAGE_CODE_R
                        ,N_FISCAL_YEAR_R
                        ,N_QUARTER_R
                        ,QTD_GROSS_AMNT
                        ,QTD_TAXABLE_BENEFITS
                        ,QTD_NON_TAXABLE_BENEFITS
                        ,QTD_FIT
                        ,QTD_SIT
                        ,QTD_FICA
                        ,QTD_MEDICARE_TAX
                        ,QTD_FICA_WAGE_BASE
                        ,QTD_MEDICARE_WAGE_BASE
                        ,QTD_FUTA
                        ,QTD_NET_AMT
                        ,YTD_GROSS_AMNT
                        ,YTD_TAXABLE_BENEFITS
                        ,YTD_NON_TAXABLE_BENEFITS
                        ,YTD_FIT
                        ,YTD_SIT
                        ,YTD_FICA
                        ,YTD_MEDICARE_TAX
                        ,YTD_FICA_WAGE_BASE
                        ,YTD_MEDICARE_WAGE_BASE
                        ,YTD_FUTA
                        ,YTD_NET_AMT
                        )
                        WITH FCT_CLAIM_PAYMENT_DETAIL_QTD AS
                        (SELECT
                        F.V_CLAIM_NUMBER_R
                        ,F.N_CLAIM_COVERAGE_GROUP_SK_R
                        ,F.V_COVERAGE_CODE_R
                        ,D.N_FISCAL_YEAR_R
                        ,D.N_QUARTER_R
                        ,SUM(F.N_PAID_AMOUNT_R) QTD_GROSS_AMNT
                        ,SUM(F.N_TAXABLE_BENEFIT_AMT_R) as QTD_TAXABLE_BENEFITS
                        ,SUM(F.N_PAID_AMOUNT_R)-SUM(F.N_TAXABLE_BENEFIT_AMT_R) as QTD_NON_TAXABLE_BENEFITS
                        ,SUM(case when F.V_BENEFIT_CODE_R in ( '099' ) then F.N_PAID_AMOUNT_R else 0 end) QTD_FIT
                        ,SUM(CASE WHEN F.V_BENEFIT_CODE_R IN ( '297' ) THEN F.N_PAID_AMOUNT_R ELSE 0 END) QTD_SIT
                        ,SUM(CASE WHEN F.V_BENEFIT_CODE_R IN ( '098') THEN F.N_PAID_AMOUNT_R ELSE 0 END)  QTD_FICA
                        ,SUM(CASE WHEN F.V_BENEFIT_CODE_R IN ( '298') THEN F.N_PAID_AMOUNT_R ELSE 0 END)  QTD_MEDICARE_TAX
                        ,SUM(CASE WHEN F.V_BENEFIT_CODE_R IN ( '098') THEN F.N_SS_WAGE_BASE_R ELSE 0 END) QTD_FICA_WAGE_BASE
                        ,SUM(CASE WHEN F.V_BENEFIT_CODE_R IN ( '298') THEN F.N_MED_WAGE_BASE_R ELSE 0 END) QTD_MEDICARE_WAGE_BASE
                        ,SUM(case when F.V_BENEFIT_CODE_R in ( '097') then F.N_PAID_AMOUNT_R else 0 end)  QTD_FUTA
                        ,SUM(CASE WHEN F.V_BENEFIT_CODE_R NOT IN ( 'FIC', 'MED') THEN F.N_PAID_AMOUNT_R ELSE 0 END ) QTD_NET_AMT
                        FROM FCT_CLAIM_PAYMENT_DETAIL_R F
                        inner join DIM_TIME_R D on F.D_PAID_DATE_R=D.D_CALENDAR_DATE_R
                        WHERE F.V_CHECK_TYPE_R <> 'OE'
                        and F.V_PAYMENT_TYPE_R <> 'RED'
                        AND D.D_CALENDAR_DATE_R <= SYSDATE
                        GROUP BY
                        F.V_CLAIM_NUMBER_R
                        ,F.N_CLAIM_COVERAGE_GROUP_SK_R
                        ,F.V_COVERAGE_CODE_R
                        ,D.N_FISCAL_YEAR_R
                        ,D.N_QUARTER_R
                        )
                        ,FCT_CLAIM_PAYMENT_DETAIL_YTD as
                        (SELECT
                        F.V_CLAIM_NUMBER_R
                        ,F.N_CLAIM_COVERAGE_GROUP_SK_R
                        ,F.V_COVERAGE_CODE_R
                        ,D.N_FISCAL_YEAR_R
                        ,SUM(F.N_PAID_AMOUNT_R) YTD_GROSS_AMNT
                        ,SUM(F.N_TAXABLE_BENEFIT_AMT_R) as YTD_TAXABLE_BENEFITS
                        ,SUM(F.N_PAID_AMOUNT_R)-SUM(F.N_TAXABLE_BENEFIT_AMT_R) as YTD_NON_TAXABLE_BENEFITS
                        ,SUM(case when F.V_BENEFIT_CODE_R in ( '099' ) then F.N_PAID_AMOUNT_R else 0 end) YTD_FIT
                        ,SUM(CASE WHEN F.V_BENEFIT_CODE_R IN ( '297' ) THEN F.N_PAID_AMOUNT_R ELSE 0 END) YTD_SIT
                        ,SUM(CASE WHEN F.V_BENEFIT_CODE_R IN ( '098') THEN F.N_PAID_AMOUNT_R ELSE 0 END)  YTD_FICA
                        ,SUM(CASE WHEN F.V_BENEFIT_CODE_R IN ( '298') THEN F.N_PAID_AMOUNT_R ELSE 0 END)  YTD_MEDICARE_TAX
                        ,SUM(CASE WHEN F.V_BENEFIT_CODE_R IN ( '098') THEN F.N_SS_WAGE_BASE_R ELSE 0 END) YTD_FICA_WAGE_BASE
                        ,SUM(CASE WHEN F.V_BENEFIT_CODE_R IN ( '298') THEN F.N_MED_WAGE_BASE_R ELSE 0 END) YTD_MEDICARE_WAGE_BASE
                        ,SUM(case when F.V_BENEFIT_CODE_R in ( '097') then F.N_PAID_AMOUNT_R else 0 end)  YTD_FUTA
                        ,SUM(CASE WHEN F.V_BENEFIT_CODE_R NOT IN ( 'FIC', 'MED') THEN F.N_PAID_AMOUNT_R ELSE 0 END ) YTD_NET_AMT
                        FROM FCT_CLAIM_PAYMENT_DETAIL_R F
                        inner join DIM_TIME_R D on F.D_PAID_DATE_R=D.D_CALENDAR_DATE_R
                        WHERE F.V_CHECK_TYPE_R <> 'OE'
                        and F.V_PAYMENT_TYPE_R <> 'RED'
                        AND D.D_CALENDAR_DATE_R <= SYSDATE
                        GROUP BY
                        F.V_CLAIM_NUMBER_R
                        ,F.N_CLAIM_COVERAGE_GROUP_SK_R
                        ,F.V_COVERAGE_CODE_R
                        ,D.N_FISCAL_YEAR_R
                        )
                        SELECT
                        A.V_CLAIM_NUMBER_R
                        ,A.N_CLAIM_COVERAGE_GROUP_SK_R
                        ,A.V_COVERAGE_CODE_R
                        ,A.N_FISCAL_YEAR_R
                        ,A.N_QUARTER_R
                        ,QTD_GROSS_AMNT
                        ,QTD_TAXABLE_BENEFITS
                        ,QTD_NON_TAXABLE_BENEFITS
                        ,QTD_FIT
                        ,QTD_SIT
                        ,QTD_FICA
                        ,QTD_MEDICARE_TAX
                        ,QTD_FICA_WAGE_BASE
                        ,QTD_MEDICARE_WAGE_BASE
                        ,QTD_FUTA
                        ,QTD_NET_AMT
                        ,YTD_GROSS_AMNT
                        ,YTD_TAXABLE_BENEFITS
                        ,YTD_NON_TAXABLE_BENEFITS
                        ,YTD_FIT
                        ,YTD_SIT
                        ,YTD_FICA
                        ,YTD_MEDICARE_TAX
                        ,YTD_FICA_WAGE_BASE
                        ,YTD_MEDICARE_WAGE_BASE
                        ,YTD_FUTA
                        ,YTD_NET_AMT
                        FROM FCT_CLAIM_PAYMENT_DETAIL_QTD A join FCT_CLAIM_PAYMENT_DETAIL_YTD B
                        ON A.V_CLAIM_NUMBER_R=B.V_CLAIM_NUMBER_R AND
                        A.N_FISCAL_YEAR_R=B.N_FISCAL_YEAR_R;

UPDATE FCT_PROC_EXEC_STATUS_LOG_R
                    							SET V_STATUS_R                = 'Successful',
                    							T_EXECUTION_END_TIMESTAMP_R = systimestamp
                    							WHERE N_SERIAL_NUM_R          = N_MAX_SERIAL_NUM_R;