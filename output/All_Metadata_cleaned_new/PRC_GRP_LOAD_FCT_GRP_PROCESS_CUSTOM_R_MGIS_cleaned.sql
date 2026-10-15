-- Cleaned for lineage: PRC_GRP_LOAD_FCT_GRP_PROCESS_CUSTOM_R_MGIS

MERGE  INTO ATOMIC.FCT_GRP_PROCESS_CUSTOM_R d
 USING (SELECT  distinct N_POLICY_SK_R, v_distribution_channel_r FROM ATOMIC.fct_grp_policy_r where v_distribution_channel_r like '%MGIS%'  ) s
ON ( d.N_POLICY_SK_R=s.N_POLICY_SK_R
   )
WHEN MATCHED THEN
  UPDATE SET
D.v_distribution_channel_r=S.v_distribution_channel_r
WHERE
 d.N_POLICY_SK_R=s.N_POLICY_SK_R;