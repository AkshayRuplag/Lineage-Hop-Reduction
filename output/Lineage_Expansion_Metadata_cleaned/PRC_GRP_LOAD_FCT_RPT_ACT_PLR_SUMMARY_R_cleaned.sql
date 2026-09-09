-- Cleaned for lineage: PRC_GRP_LOAD_FCT_RPT_ACT_PLR_SUMMARY_R

Insert into the table FCT_RPT_ACT_PLR_SUMMARY_R:->'||ln_start_time||' Seconds';

INSERT /*+APPEND*/ INTO ATOMIC.FCT_RPT_ACT_PLR_SUMMARY_R
      (
      V_SUBJECT_AREA_TYPE_R,
      V_CREATED_BY_R,
      T_EVENT_TIMESTAMP_R,
      N_SEQUENCE_NUMBER_R,
      FIC_MIS_DATE_R,
      N_PERMISSABLE_LR_R,
      N_PARTY_SK_R,
      N_5YR_TARGET_PROFIT_R,
      N_SOLD_ANNUALIZED_PREM_R,
      N_5YR_EARNED_PREM_R,
      N_BILL_TO_MANUAL_R,
      N_3YR_PV_INCURRED_CLAIMS_R,
      N_MANUAL_ANNUALIZED_PREM_R,
      N_PROFITPCT_R,
      N_COMMPCT_R,
      N_CLAIM_SK_R,
      V_CHANGE_REASON_R,
      F_PHYSICAL_DELETE_R,
      N_VERSION_NUMBER_R,
      V_SOURCE_SYSTEM_NAME_R,
      N_LOAD_RUN_ID_R,
      V_LAST_MODIFIED_BY_R,
      T_LAST_MODIFIED_DATE_R,
      T_CREATION_DATE_R,
      N_BATCH_ID_R,
      N_3YR_CONSTANT_PREM_R,
      N_5YR_PV_INCURRED_CLAIMS_R,
      N_5YR_CONSTANT_PREM_R,
      D_CYCLE_DATE_R,
      N_CENSUS_LIVES_R,
      N_3YR_TARGET_PROFIT_R,
      N_3YR_EARNED_PREM_R,
      N_ACTUARIAL_LIVES_R,
      N_POLICY_SK_R,
      N_QUOTE_SK_R
      )
      select  /*+PARALLEL(4)*/
      'Policy' AS V_SUBJECT_AREA_TYPE_R,
      'PRC_GRP_LOAD_FCT_RPT_ACT_PLR_SUMMARY_R' AS V_CREATED_BY_R,
      lt_systimestamp AS T_EVENT_TIMESTAMP_R,
      ROWNUM AS N_SEQUENCE_NUMBER_R,
      ld_sysdate AS FIC_MIS_DATE_R,
      PERMISSIBLE_LOSS_RATIO N_PERMISSABLE_LR_R,
      FP.n_cust_party_sk_r AS N_PARTY_SK_R, 
      FIVE_YEAR_TARGET_PROFITS AS N_5YR_TARGET_PROFIT_R,
      SOLD_ANNUALIZED_PREMIUM AS N_SOLD_ANNUALIZED_PREM_R,
      FIVE_YEAR_EARNED_PREMIUM AS N_5YR_EARNED_PREM_R,
      BILL_TO_MANUAL AS N_BILL_TO_MANUAL_R,
      THREE_YEAR_PV_INCURRED_CLAIMS AS N_3YR_PV_INCURRED_CLAIMS_R,
      MANUAL_ANNUALIZED_PREMIUM AS N_MANUAL_ANNUALIZED_PREM_R,
      PROFIT_TARGET_PCT AS N_PROFITPCT_R,
      COMMISSION_PCT AS N_COMMPCT_R,
      -1 N_CLAIM_SK_R, 
      '' V_CHANGE_REASON_R,
      '' F_PHYSICAL_DELETE_R,
      1 N_VERSION_NUMBER_R,
      'RDM' V_SOURCE_SYSTEM_NAME_R,
      1 N_LOAD_RUN_ID_R,
      'PRC_GRP_LOAD_FCT_RPT_ACT_PLR_SUMMARY_R' V_LAST_MODIFIED_BY_R,
      ld_sysdate T_LAST_MODIFIED_DATE_R,
      ld_sysdate T_CREATION_DATE_R,
      ln_n_batch_id_r N_BATCH_ID_R,
      THREE_YEAR_CONSTANT_PREMIUM AS N_3YR_CONSTANT_PREM_R,
      FIVE_YEAR_PV_INCURRED_CLAIMS AS N_5YR_PV_INCURRED_CLAIMS_R,
      FIVE_YEAR_CONSTANT_PREMIUM AS N_5YR_CONSTANT_PREM_R,
      CYCLE_DATE AS D_CYCLE_DATE_R,
      CENSUS_LIVES AS N_CENSUS_LIVES_R,
      THREE_YEAR_TARGET_PROFITS AS N_3YR_TARGET_PROFIT_R,
      THREE_YEAR_EARNED_PREMIUM AS N_3YR_EARNED_PREM_R,
      ACTUARIAL_LIVES AS N_ACTUARIAL_LIVES_R,
      pol_dir.N_POLICY_SK_R,
      -1 N_QUOTE_SK_R 
      from RDM.PERF_ACT_PLR_SUMMARY_FACT@REPORT.RSLI.COM pf JOIN RDM.CUSTOMER_DIM@REPORT.RSLI.COM CD
      ON pf.CUSTOMER_KEY = CD.CUSTOMER_KEY
      JOIN (select  N_POLICY_SK_R, OLD_V_POLICY_NUMBER_R  V_POLICY_NUMBER_R,
	           n_policy_version_number_r from VW_DIM_GRP_POLICY_DIR_R_POLICY_PREFIX_BRIDGE vw
            where exists (SELECT 1 from DIM_GRP_POLICY_DIR_R dim WHERE  dim.v_active_status_r ='Y' and dim.N_POLICY_SK_R=vw.N_POLICY_SK_R)
            group by N_POLICY_SK_R, OLD_V_POLICY_NUMBER_R,n_policy_version_number_r
		   ) pol_dir
      ON (case when cd.PACS_LOB_CODE = 'MAL' then cd.PACS_LOB_CODE||cd.POLICY_SUFFIX else cd.policy_num end)=POL_DIR.V_POLICY_NUMBER_R
      LEFT JOIN (select /*+PARALLEL(4)*/ distinct n_version_number_r,N_POLICY_SK_R,n_cust_party_sk_r from  ATOMIC.fct_grp_policy_r) FP
      ON FP.n_policy_sk_r= pol_dir.n_policy_sk_r
      AND FP.n_version_number_r=pol_dir.n_policy_version_number_r;

INSERT INTO ATOMIC.PRCS_GRP_TBL_LOAD_DEBUG_TRC(V_JOB_NAME_R
                                                   ,V_PKG_PRC_NAME_R
                                                   ,N_SK_R
                                                   ,V_NUMBER_R
                                                   ,V_TRC_MSG_R
                                                   ,N_BATCH_ID_R
                                                   ,v_created_by_r
                                                   ,V_LAST_MODIFIED_BY_R
                                                  )
    										VALUES('GRP_LOAD_FCT_RPT_ACT_PLR_SUMMARY_R'
    										      ,'PRC_GRP_LOAD_FCT_RPT_ACT_PLR_SUMMARY_R'
    											  ,NULL
    											  ,NULL
    											  ,lc_trcmsg
    											  ,ln_N_BATCH_ID_R
    											  ,'PRC_GRP_LOAD_FCT_RPT_ACT_PLR_SUMMARY_R'
    											  ,'PRC_GRP_LOAD_FCT_RPT_ACT_PLR_SUMMARY_R'
    										);