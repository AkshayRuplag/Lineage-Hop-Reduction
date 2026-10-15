-- Cleaned for lineage: PKG_GRP_LOAD_RPT_AGENT_POLICY_R_PRC_GET_CUR_DATA (part 1/1)

-- REF CURSOR lineage (OPEN ... FOR SELECT -> INSERT INTO RPT_AGENT_POLICY_R)
INSERT INTO RPT_AGENT_POLICY_R
SELECT
     
     C.V_FULL_NAME_R V_AGENCY_NAME_R,
     SUBSTR(C.V_AGENT_NUMBER_R,1, 6) V_AGENCY_code_R,
     C.V_FULL_NAME_R V_AGENT_NAME_R,    
     C.V_AGENT_NUMBER_R V_AGENT_CODE_R, 
     NVL(agent_share.N_RPT_SPLIT_PERCENTAGE_R,1) N_AGENT_SHARE_R,
     agent_share.D_START_DATE_R D_AGENT_SHARE_START_DATE_R,
     agent_share.D_END_DATE_R D_AGENT_SHARE_TERM_DATE_R,
     CASE
       WHEN agent_share.N_RPT_PRIMARY_INDICATOR_R = 'P'
       THEN adr.V_ADDRESSLINE1_R
     END V_PRIMARY_AGENT_ADDRESS_1_R,
     CASE
       WHEN agent_share.N_RPT_PRIMARY_INDICATOR_R = 'P'
       THEN adr.V_ADDRESSLINE2_R
     END V_PRIMARY_AGENT_ADDRESS_2_R,
     CASE
       WHEN agent_share.N_RPT_PRIMARY_INDICATOR_R = 'P'
       THEN adr.v_city_r
     END V_PRIMARY_AGENT_CITY_R,
     CASE
       WHEN agent_share.N_RPT_PRIMARY_INDICATOR_R = 'P'
       THEN C.V_AGENT_NUMBER_R
     END V_PRIMARY_AGENT_CODE_R,
     CASE
       WHEN agent_share.N_RPT_PRIMARY_INDICATOR_R = 'P'
       THEN C.V_FULL_NAME_R
       WHEN agent_share.n_agent_sk_r IS NULL
       THEN 'Unknown'
     END V_PRIMARY_AGENT_NAME_R,
     CASE
       WHEN agent_share.N_RPT_PRIMARY_INDICATOR_R = 'P'
       THEN agent_share.N_RPT_SPLIT_PERCENTAGE_R
       WHEN agent_share.n_agent_sk_r IS NULL
       THEN 1
     END N_PRIMARY_AGENT_SHARE_R,
     CASE
       WHEN agent_share.N_RPT_PRIMARY_INDICATOR_R = 'P'
       THEN adr.V_STATE_NAME_R
     END V_PRIMARY_AGENT_STATE_R,
     CASE
       WHEN agent_share.N_RPT_PRIMARY_INDICATOR_R = 'P'
       THEN adr.V_POSTAL_ZIP_R
     END V_PRIMARY_AGENT_ZIP_R,
     agent_share.N_RPT_PRIMARY_INDICATOR_R AS V_PRIMARY_AGENT_IND_R,
     adr.N_PRIMARY_LOCATION_R              AS V_PRIMARY_LOCATION_R ,
     pd.V_BROKER_DESC_R V_PREMIER_PRODUCER_NAME_R,
     CASE
       WHEN agent_share.N_RPT_PRIMARY_INDICATOR_R                                                                                                            = 'S'
       AND rank() over(partition BY agent_share2.N_POLICY_SK_R, agent_share2. N_RPT_PRIMARY_INDICATOR_R order by agent_share2.N_RPT_SPLIT_PERCENTAGE_R DESC) =1
       THEN adr.V_ADDRESSLINE1_R
     END V_SECONDARY_AGENT_ADDRESS_1_R,
     CASE
       WHEN agent_share.N_RPT_PRIMARY_INDICATOR_R                                                                                                            = 'S'
       AND rank() over(partition BY agent_share2.N_POLICY_SK_R, agent_share2. N_RPT_PRIMARY_INDICATOR_R order by agent_share2.N_RPT_SPLIT_PERCENTAGE_R DESC) =1
       THEN adr.V_ADDRESSLINE2_R
     END V_SECONDARY_AGENT_ADDRESS_2_R,
     CASE
       WHEN agent_share.N_RPT_PRIMARY_INDICATOR_R                                                                                                            = 'S'
       AND rank() over(partition BY agent_share2.N_POLICY_SK_R, agent_share2. N_RPT_PRIMARY_INDICATOR_R order by agent_share2.N_RPT_SPLIT_PERCENTAGE_R DESC) =1
       THEN adr.v_city_r
     END V_SECONDARY_AGENT_CITY_R,
     CASE
       WHEN agent_share.N_RPT_PRIMARY_INDICATOR_R                                                                                                           = 'S'
       AND rank() over(partition BY agent_share2.N_POLICY_SK_R, agent_share2.N_RPT_PRIMARY_INDICATOR_R order by agent_share2.N_RPT_SPLIT_PERCENTAGE_R DESC) =1
       THEN C.V_FULL_NAME_R
     END V_SECONDARY_AGENT_NAME_R,
     CASE
       WHEN agent_share2.N_RPT_PRIMARY_INDICATOR_R                                                                                                          = 'S'
       AND rank() over(partition BY agent_share2.N_POLICY_SK_R, agent_share2.N_RPT_PRIMARY_INDICATOR_R order by agent_share2.N_RPT_SPLIT_PERCENTAGE_R DESC) =1
       THEN agent_share2.N_RPT_SPLIT_PERCENTAGE_R
     END N_SECONDARY_AGENT_SHARE_R,
     CASE
       WHEN agent_share.N_RPT_PRIMARY_INDICATOR_R                                                                                                            = 'S'
       AND rank() over(partition BY agent_share2.N_POLICY_SK_R, agent_share2. N_RPT_PRIMARY_INDICATOR_R order by agent_share2.N_RPT_SPLIT_PERCENTAGE_R DESC) =1
       THEN adr.V_STATE_NAME_R
     END V_SECONDARY_AGENT_STATE_R,
     CASE
       WHEN agent_share.N_RPT_PRIMARY_INDICATOR_R                                                                                                            = 'S'
       AND rank() over(partition BY agent_share2.N_POLICY_SK_R, agent_share2. N_RPT_PRIMARY_INDICATOR_R order by agent_share2.N_RPT_SPLIT_PERCENTAGE_R DESC) =1
       THEN adr.V_POSTAL_ZIP_R
     END V_SECONDARY_AGENT_ZIP_R,
     CASE
       WHEN agent_share.N_RPT_PRIMARY_INDICATOR_R                                                                                                            = 'S'
       AND rank() over(partition BY agent_share2.N_POLICY_SK_R, agent_share2. N_RPT_PRIMARY_INDICATOR_R order by agent_share2.N_RPT_SPLIT_PERCENTAGE_R DESC) =1
       THEN C.V_AGENT_NUMBER_R
     END V_SECONDARY_AGENT_CODE_R,
     CASE
       WHEN agent_share.N_RPT_PRIMARY_INDICATOR_R                                                                                                           = 'S'
       AND rank() over(partition BY agent_share2.N_POLICY_SK_R, agent_share2.N_RPT_PRIMARY_INDICATOR_R order by agent_share2.N_RPT_SPLIT_PERCENTAGE_R DESC) =2
       THEN adr.V_ADDRESSLINE1_R
     END V_TERTIARY_AGENT_ADDRESS_1_R,
     CASE
       WHEN agent_share.N_RPT_PRIMARY_INDICATOR_R                                                                                                           = 'S'
       AND rank() over(partition BY agent_share2.N_POLICY_SK_R, agent_share2.N_RPT_PRIMARY_INDICATOR_R order by agent_share2.N_RPT_SPLIT_PERCENTAGE_R DESC) =2
       THEN adr.V_ADDRESSLINE2_R
     END V_TERTIARY_AGENT_ADDRESS_2_R,
     CASE
       WHEN agent_share.N_RPT_PRIMARY_INDICATOR_R                                                                                                           = 'S'
       AND rank() over(partition BY agent_share2.N_POLICY_SK_R, agent_share2.N_RPT_PRIMARY_INDICATOR_R order by agent_share2.N_RPT_SPLIT_PERCENTAGE_R DESC) =2
       THEN adr.v_city_r
     END V_TERTIARY_AGENT_CITY_R,
     CASE
       WHEN agent_share.N_RPT_PRIMARY_INDICATOR_R                                                                                                           = 'S'
       AND rank() over(partition BY agent_share2.N_POLICY_SK_R, agent_share2.N_RPT_PRIMARY_INDICATOR_R order by agent_share2.N_RPT_SPLIT_PERCENTAGE_R DESC) =2
       THEN C.V_AGENT_NUMBER_R
     END V_TERTIARY_AGENT_CODE_R,
     CASE
       WHEN agent_share.N_RPT_PRIMARY_INDICATOR_R                                                                                                           = 'S'
       AND rank() over(partition BY agent_share2.N_POLICY_SK_R, agent_share2.N_RPT_PRIMARY_INDICATOR_R order by agent_share2.N_RPT_SPLIT_PERCENTAGE_R DESC) =2
       THEN C.V_FULL_NAME_R
     END V_TERTIARY_AGENT_NAME_R,
     CASE
       WHEN agent_share.N_RPT_PRIMARY_INDICATOR_R                                                                                                           = 'S'
       AND rank() over(partition BY agent_share2.N_POLICY_SK_R, agent_share2.N_RPT_PRIMARY_INDICATOR_R order by agent_share2.N_RPT_SPLIT_PERCENTAGE_R DESC) =2
       THEN agent_share.N_RPT_SPLIT_PERCENTAGE_R
     END N_TERTIARY_AGENT_SHARE_R,
     CASE
       WHEN agent_share.N_RPT_PRIMARY_INDICATOR_R                                                                                                           = 'S'
       AND rank() over(partition BY agent_share2.N_POLICY_SK_R, agent_share2.N_RPT_PRIMARY_INDICATOR_R order by agent_share2.N_RPT_SPLIT_PERCENTAGE_R DESC) =2
       THEN adr.V_STATE_NAME_R
     END V_TERTIARY_AGENT_STATE_R,
     CASE
       WHEN agent_share.N_RPT_PRIMARY_INDICATOR_R                                                                                                           = 'S'
       AND rank() over(partition BY agent_share2.N_POLICY_SK_R, agent_share2.N_RPT_PRIMARY_INDICATOR_R order by agent_share2.N_RPT_SPLIT_PERCENTAGE_R DESC) =2
       THEN adr.V_POSTAL_ZIP_R
     END V_TERTIARY_AGENT_ZIP_R,
     a.N_POLICY_SK_R,
     NVL(AGENT_SHARE.N_AGENT_SK_R,-1) AS N_AGENT_SK_R,

gc_getcur_loadedby             AS V_LAST_MODIFIED_BY_R,
         gd_sysdate                     AS T_CREATION_DATE_R,
         gc_getcur_loadedby             AS V_CREATED_BY_R,
         gd_sysdate                     AS T_LAST_MODIFIED_DATE_R,
         'Y'                            AS V_RPT_ACTIVE_STATUS_R,
         gn_sysdt_batchid               AS N_BATCH_ID_R,
         gn_current_month               AS N_REPORTMONTH_R,
		 agent_share.V_TEMPLATE_NAME_R  AS N_PLAN_CODE_R,
		 agent_share.N_LAST_RATE_R      as N_LAST_RATE_R,
         
         NVL(stg.V_SALES_PLAN_DESC_R,stg1.V_SALES_PLAN_DESC_R)        as V_SALES_PLAN_DESC_R,

CALCULATE_EST_COMM_FUNC(
    AGNT_P.D_POLICY_EFFECTIVE_DATE_R,
    ANN_PREM.N_ANNUALIZED_PREMIUM_R,
    agent_share.V_TEMPLATE_NAME_R,
    agent_share.N_LAST_RATE_R)  AS N_ESTIMATED_COMMISSION_R
         
   FROM dim_grp_policy_dir_r a
   LEFT JOIN
     (SELECT N_POLICY_SK_R,
       n_agent_sk_r,
       N_RPT_PRIMARY_INDICATOR_R,
       SUM(NVL(N_RPT_SPLIT_PERCENTAGE_R,0))N_RPT_SPLIT_PERCENTAGE_R,
       MIN(D_START_DATE_R) D_START_DATE_R,
       MAX(N_RPT_SORT_ORDER_R)N_RPT_SORT_ORDER_R,
       MAX(D_END_DATE_R) D_END_DATE_R,
	   v_template_name_r ,
	   N_LAST_RATE_R
     FROM fct_grp_agent_policy_r_lookup
     WHERE n_policy_sk_r <>-1
     GROUP BY N_POLICY_SK_R,
       n_agent_sk_r,
       N_RPT_PRIMARY_INDICATOR_R,
	   v_template_name_r ,
	   N_LAST_RATE_R
     ) agent_share
   ON a.n_policy_sk_r = agent_share.n_policy_sk_r
   LEFT JOIN
     (SELECT N_POLICY_SK_R,
       n_agent_sk_r,
       N_RPT_PRIMARY_INDICATOR_R,
       SUM(NVL(N_RPT_SPLIT_PERCENTAGE_R,0))N_RPT_SPLIT_PERCENTAGE_R,
       MIN(D_START_DATE_R) D_START_DATE_R,
       MAX(N_RPT_SORT_ORDER_R)N_RPT_SORT_ORDER_R,
       MAX(D_END_DATE_R) D_END_DATE_R,
	   v_template_name_r
     FROM fct_grp_agent_policy_r_lookup
     WHERE n_policy_sk_r          <>-1
     AND N_RPT_PRIMARY_INDICATOR_R ='S'
     GROUP BY N_POLICY_SK_R,
       n_agent_sk_r,
       N_RPT_PRIMARY_INDICATOR_R,
	   v_template_name_r
     ) agent_share2
   ON agent_share.N_POLICY_SK_R              =agent_share2.N_POLICY_SK_R
   AND agent_share.n_agent_sk_r              =agent_share2.n_agent_sk_r
   AND agent_share.N_RPT_SORT_ORDER_R        =agent_share2.N_RPT_SORT_ORDER_R
   AND agent_share.N_RPT_PRIMARY_INDICATOR_R = agent_share2.N_RPT_PRIMARY_INDICATOR_R
   
   LEFT JOIN (SELECT CASE WHEN DMGD1.N_PARTY_SK_R <> -1 THEN DMGD1.N_PARTY_SK_R
                     ELSE NVL((SELECT N_PARTY_SK_R FROM (SELECT N_PARTY_SK_r,ROW_NUMBER() OVER (PARTITION BY N_AGENT_SK_r ORDER BY T_EVENT_TIMESTAMP_R DESC ,N_BATCH_ID_R DESC) AS rn
                                                     FROM DIM_GRP_AGENT_DIRECTORY_R DMGD
													 WHERE DMGD.V_AGENT_NUMBER_R = DMGD1.V_AGENT_NUMBER_R AND V_ACTIVE_STATUS_R='N'
													 AND N_PARTY_SK_R<>-1)
                           WHERE RN =1),-1) END N_PARTY_SK_r,
					  DMGD1.N_AGENT_SK_R,
					  DMGD1.V_ACTIVE_STATUS_R
              FROM DIM_GRP_AGENT_DIRECTORY_R DMGD1
			  WHERE V_ACTIVE_STATUS_R = 'Y')B

ON AGENT_SHARE.N_AGENT_SK_R = B.N_AGENT_SK_R
   AND B.V_ACTIVE_STATUS_R     = 'Y'
   LEFT JOIN

(SELECT *
    FROM DIM_GRP_AGENT_R d
    WHERE  	d.V_ACTIVE_STATUS_R = 'Y' AND 
	trunc(T_EVENT_TIMESTAMP_R) =
      (SELECT MAX(trunc(T_EVENT_TIMESTAMP_R))
      FROM DIM_GRP_AGENT_R z
      WHERE z.n_agent_sk_r = d.n_agent_sk_r
       )
     ) C

ON B.N_AGENT_SK_R       = C.N_AGENT_SK_R
   LEFT JOIN
     (SELECT DISTINCT V_ADDRESSLINE1_R,
       V_ADDRESSLINE2_R,
       V_CITY_R ,
       V_STATE_NAME_R,
       V_POSTAL_ZIP_R,
       n_party_sk_r,
       N_PRIMARY_LOCATION_R
    , Row_number () over( partition by n_party_sk_r ORDER BY N_BATCH_ID_R DESC) RECNT_RCD  
     FROM FCT_GRP_PARTY_ADDRESS_R
     WHERE V_SOURCE_SYSTEM_NAME_R = 'APS'
     AND N_PRIMARY_LOCATION_R     = '1'
     AND n_party_sk_r            <> -1
     AND D_DELETE_DATE_R         IS NULL
     )adr
   ON adr.n_party_sk_r = b.n_party_sk_r
   and adr.RECNT_RCD = 1  
   LEFT JOIN stg_premier_producer_r pp
   ON pp.V_AGENCY_CODE_R = SUBSTR(C.V_AGENT_NUMBER_R,1, 6)
   LEFT JOIN stg_premier_producer_desc_r pd
   ON PP.V_BROKER_NAME_R     = PD.V_BROKER_NAME_R
   
    LEFT JOIN
   (SELECT N_PLAN_CODE_R
         , N_RATE_R
         , V_SALES_PLAN_DESC_R
         , Row_number() over( partition by N_PLAN_CODE_R ,N_RATE_R order by N_PLAN_CODE_R ,N_RATE_R ) RANK_RW
    FROM ATOMIC.STG_PLAN_DETAIL) STG
   ON  STG.N_PLAN_CODE_R = agent_share.V_TEMPLATE_NAME_R
   AND STG.N_RATE_R      = agent_share.N_LAST_RATE_R
   and stg.RANK_RW       = 1

LEFT JOIN (SELECT N_POLICY_SK_R , D_POLICY_EFFECTIVE_DATE_R
                   , ROW_NUMBER() OVER(PARTITION BY D_POLICY_EFFECTIVE_DATE_R ORDER BY D_POLICY_EFFECTIVE_DATE_R) AGNT_RANK_RW
               FROM rpt_policy_dtl_r t1
              ) AGNT_P
    on AGNT_P.N_POLICY_SK_R = agent_share.n_policy_sk_r
    AND AGNT_P.AGNT_RANK_RW = 1
   LEFT JOIN (SELECT T1.N_POLICY_SK_R N_POLICY_SK_R
                   , T1.N_AGENT_SK_R N_AGENT_SK_R
                   , sum(N_ANNUALIZED_PREMIUM_R) N_ANNUALIZED_PREMIUM_R
                FROM RPT_FCT_RPT_ANN_PREM_SUMMARY_R T1
                WHERE N_REPORTMONTH_R = (SELECT MAX(N_REPORTMONTH_R) FROM RPT_FCT_RPT_ANN_PREM_SUMMARY_R T2
                                          WHERE T2.N_POLICY_SK_R = T1.N_POLICY_SK_R
                                            AND N_AGENT_SK_R = T1.N_AGENT_SK_R)
                GROUP BY T1.N_POLICY_SK_R,T1.N_AGENT_SK_R ,T1.N_REPORTMONTH_R) ANN_PREM
  on ANN_PREM.N_POLICY_SK_R = agent_share.n_policy_sk_r
  AND ANN_PREM.N_AGENT_SK_R = agent_share.n_agent_sk_r

left join   (SELECT N_PLAN_CODE_R
         , N_RATE_R
         , V_SALES_PLAN_DESC_R
         , Row_number() over( partition by N_PLAN_CODE_R  order by N_PLAN_CODE_R ) RANK_RW
    FROM ATOMIC.STG_PLAN_DETAIL) STG1
   ON  STG1.N_PLAN_CODE_R = agent_share.V_TEMPLATE_NAME_R
   and stg1.RANK_RW       = 1
    
   WHERE a.v_active_status_r = 'Y';