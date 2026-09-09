--------------------------------------------------------
--  DDL for Procedure PRC_GRP_LOAD_MERGE_UPDATE_FCT_RPT_PREMIUM_SUMMARY_R_NON_GL
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "ATOMIC"."PRC_GRP_LOAD_MERGE_UPDATE_FCT_RPT_PREMIUM_SUMMARY_R_NON_GL" (
	P_BATCH_ID_R IN NUMBER
)  AS
	V_SYS_DATE                  VARCHAR2(15) := TO_CHAR(SYSDATE,'YYYYMMDDHHMISS');
	N_MAX_SERIAL_NUM_R          NUMBER;
	V_SQLCODE                   VARCHAR2(100);
	V_SQLERRM                   VARCHAR2(500);
	LN_BATCH_ID_R               NUMBER       := P_BATCH_ID_R;
    LN_CURR_FISCAL_DATE         DATE;

	BEGIN
    /* Get the Cycle's BatchID */
    SELECT 
        MAX(DTR.D_CALENDAR_DATE_R)
    INTO
        LN_CURR_FISCAL_DATE
    FROM
    (
        SELECT 
            N_MONTH_R,
            N_YEAR_R 
        FROM
            DIM_TIME_R 
        WHERE 
            D_CALENDAR_DATE_R = TO_DATE(SUBSTR(P_BATCH_ID_R, 1, 8), 'YYYYMMDD')
    ) DTR_CURR
    JOIN DIM_TIME_R DTR
    ON
    DTR.V_END_OF_FISCAL_MONTH_IND_R = 'Y'
    AND DTR.N_MONTH_R = DTR_CURR.N_MONTH_R
    AND DTR.N_YEAR_R = DTR_CURR.N_YEAR_R;


MERGE INTO FCT_RPT_PREMIUM_SUMMARY_R T
USING (
          SELECT DISTINCT
              N_POLICY_SK_R,
              V_POLICY_NUMBER_R,
              V_PRIMARY_REINSURER_R,
              V_SECONDARY_REINSURER_R,
              V_TERNARY_REINSURER_R,
              N_PRIMARY_REINS_PREM_PCT_R,
              N_SEC_REINS_PREM_PCT_R,
              N_TERNARY_REINS_PREM_PCT_R,
              N_TOTAL_REINS_PREM_PCT_R,
			  V_LINE_OF_BUSINESS_R
          FROM
              STG_GRP_REINSURER_PREM_PCT_R
          WHERE 
              NVL(N_TOTAL_REINS_PREM_PCT_R, 0) >= 0
      )
S ON ( 
        T.V_POLICY_NUMBER_R = S.V_POLICY_NUMBER_R
       AND T.N_POLICY_SK_R = S.N_POLICY_SK_R
       AND T.D_CYCLE_DATE_R=LN_CURR_FISCAL_DATE  
)
WHEN MATCHED THEN UPDATE
SET T.V_PRIMARY_REINSURER_R = S.V_PRIMARY_REINSURER_R,
    T.V_SECONDARY_REINSURER_R = S.V_SECONDARY_REINSURER_R,
    T.V_TERNARY_REINSURER_R = S.V_TERNARY_REINSURER_R,
    T.N_PRIMARY_REINS_PREM_PCT_R = S.N_PRIMARY_REINS_PREM_PCT_R,
    T.N_SEC_REINS_PREM_PCT_R = S.N_SEC_REINS_PREM_PCT_R,
    T.N_TERNARY_REINS_PREM_PCT_R = S.N_TERNARY_REINS_PREM_PCT_R,
	T.N_TOTAL_REINS_PREM_PCT_R = NVL(S.N_TOTAL_REINS_PREM_PCT_R,0),
	T.n_written_prem_net_amt_r = (T.n_written_prem_amt_r - (T.n_written_prem_amt_r * NVL(S.N_TOTAL_REINS_PREM_PCT_R,0))),
	T.n_chg_prem_unearned_net_amt_r = T.n_chg_prem_unearned_amt_r,
	T.n_written_prem_ceded_amt_r = (T.n_written_prem_amt_r * NVL(S.N_TOTAL_REINS_PREM_PCT_R,0)),
	T.n_earned_prem_net_amt_r = (T.n_earned_prem_amt_r - (T.n_earned_prem_amt_r * NVL(S.N_TOTAL_REINS_PREM_PCT_R,0)))
	where S.V_LINE_OF_BUSINESS_R IN ('VAI','VAR','VCI','VHI','VLT','VPL','VPS','SR','LTD','LTD-SMALL','STD');
COMMIT;
EXCEPTION
WHEN OTHERS THEN
	V_SQLERRM := SUBSTR(SQLERRM, 1, 4000);
    RAISE_APPLICATION_ERROR(-20111, 'Raise Application Error in PRC_GRP_LOAD_MERGE_UPDATE_FCT_RPT_PREMIUM_SUMMARY_R_LTD :->' || V_SQLERRM);
END;

/

  GRANT EXECUTE ON "ATOMIC"."PRC_GRP_LOAD_MERGE_UPDATE_FCT_RPT_PREMIUM_SUMMARY_R_NON_GL" TO "ATOMIC_ALL_RO";
