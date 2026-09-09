-- Cleaned for lineage: PRC_GRP_LOAD_MERGE_UPDATE_FCT_RPT_PREMIUM_SUMMARY_R_NON_GL

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