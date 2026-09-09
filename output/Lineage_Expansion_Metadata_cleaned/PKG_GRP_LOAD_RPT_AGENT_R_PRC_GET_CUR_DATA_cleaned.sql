-- Cleaned for lineage: PKG_GRP_LOAD_RPT_AGENT_R_PRC_GET_CUR_DATA

INSERT  INTO RPT_AGENT_R_EXG stg    
  SELECT  
  SUBSTR(C.V_AGENT_NUMBER_R,1, 6) AS V_AGENCY_code_R,
    C.V_FULL_NAME_R               AS V_AGENCY_NAME_R,
    adr.V_ADDRESSLINE1_R          AS V_AGENT_ADDRESS_1_R,
    adr.V_ADDRESSLINE2_R          AS V_AGENT_ADDRESS_2_R,
    adr.V_ADDRESSLINE3_R          AS V_AGENT_ADDRESS_3_R,
    adr.V_CITY_R                  AS V_AGENT_CITY_R ,
    C.V_AGENT_NUMBER_R            AS V_AGENT_CODE_R,
    c.V_CORPORATION_TYPE_R        AS V_AGENT_CORPORATION_TYPE_R,
    c.V_DOB_R                     AS D_AGENT_DATE_OF_BIRTH_R,
    c.D_DATE_OF_DEATH_R           AS D_AGENT_DATE_OF_DEATH_R,
    c.V_FIRST_NAME_R              AS V_AGENT_FIRST_NAME_R,
    c.V_GENDER_TEXT_R             AS V_AGENT_GENDER_R,
    c.V_LAST_NAME_R               AS V_AGENT_LAST_NAME_R,
    c.V_MIDDLE_NAME_R             AS V_AGENT_MIDDLE_NAME_R,
    c.V_FULL_NAME_R               AS V_AGENT_NAME_R,
    c.V_NPN_R                     AS V_AGENT_NPN_R,
    c.V_FIELD_OFFICE_NAME_R       AS V_AGENT_RSO_NAME_R,
    adr.V_STATE_NAME_R            AS V_AGENT_STATE_R,
    c.V_STATUS_R                  AS V_AGENT_STATUS_R,
    c.V_REASON_R                  AS V_AGENT_STATUS_REASON_R,
    c.V_SSN_R                     AS V_AGENT_TIN_R,
    adr.V_POSTAL_ZIP_R            AS V_AGENT_ZIP_CODE_R,
    c.D_BUSINESS_FROM_R           AS D_AGENT_BUSINESS_FROM_R,
    c.F_BUSINESS_TYPE_R           AS V_BUSINESS_TYPE_R,
    c.N_IS_AGENCY_R               AS N_IS_AGENCY_R,
    B.N_PARTY_SK_R                AS N_AGENT_PARTY_SK_R ,
    B.N_AGENT_SK_R                AS N_AGENT_SK_R ,
    PD.V_BROKER_DESC_R            AS V_PRODUCER_NAME_R,
    gc_getcur_loadedby            AS V_LAST_MODIFIED_BY_R,                              
    gd_sysdate                    AS T_CREATION_DATE_R,                                 
    gc_getcur_loadedby            AS V_CREATED_BY_R,                                    
    gd_sysdate                    AS T_LAST_MODIFIED_DATE_R,                            
    'Y'                           AS V_RPT_ACTIVE_STATUS_R,                             
    gn_sysdt_batchid              AS N_BATCH_ID_R,                                      
    gn_current_month              AS N_REPORTMONTH_R  ,
    T1011891.V_MSA_R            as v_agent_msa_code_r,
    T1011891.V_MSA_NAME_R       as v_agent_msa_name_r
  FROM 
  (SELECT CASE WHEN DMGD1.N_PARTY_SK_R <> -1 THEN DMGD1.N_PARTY_SK_R
                     ELSE NVL((SELECT N_PARTY_SK_R FROM (SELECT N_PARTY_SK_r,ROW_NUMBER() OVER (PARTITION BY N_AGENT_SK_r ORDER BY T_EVENT_TIMESTAMP_R DESC ,N_BATCH_ID_R DESC) AS rn
                                                     FROM DIM_GRP_AGENT_DIRECTORY_R DMGD 
													 WHERE DMGD.V_AGENT_NUMBER_R = DMGD1.V_AGENT_NUMBER_R AND V_ACTIVE_STATUS_R='N' 
													 AND N_PARTY_SK_R<>-1) 
                           WHERE RN =1),-1) END N_PARTY_SK_r,
					  DMGD1.N_AGENT_SK_R,
					  DMGD1.V_ACTIVE_STATUS_R
              FROM DIM_GRP_AGENT_DIRECTORY_R DMGD1 
			  WHERE V_ACTIVE_STATUS_R = 'Y' AND N_PARTY_SK_R IS NOT NULL) B 
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
    (
    SELECT * FROM 
    (SELECT DISTINCT V_ADDRESSLINE1_R,
          V_ADDRESSLINE2_R,
          V_ADDRESSLINE3_R,
          V_CITY_R ,
          V_STATE_NAME_R,
          V_POSTAL_ZIP_R,
          n_party_sk_r,
          N_PRIMARY_LOCATION_R
    	  ,       rank() over (partition by n_party_sk_r order by V_ADDRESSLINE1_R,
          V_ADDRESSLINE2_R,
          V_ADDRESSLINE3_R,
          V_CITY_R ,
          V_STATE_NAME_R,
          V_POSTAL_ZIP_R,
          N_PARTY_SK_R,
          N_PRIMARY_LOCATION_R desc) as rnk
        FROM FCT_GRP_PARTY_ADDRESS_R
        WHERE V_SOURCE_SYSTEM_NAME_R = 'APS'
        AND N_PRIMARY_LOCATION_R     = '1'
        AND n_party_sk_r            <> -1
        AND D_DELETE_DATE_R         IS NULL
    	  and T_EVENT_TIMESTAMP_R=
        (select max(T_EVENT_TIMESTAMP_R) from FCT_GRP_PARTY_ADDRESS_R fgpar2
        WHERE fgpar2.V_SOURCE_SYSTEM_NAME_R = 'APS'
        AND fgpar2.N_PRIMARY_LOCATION_R     = '1'
        AND fgpar2.n_party_sk_r            <> -1
        AND fgpar2.D_DELETE_DATE_R         IS NULL
        AND FGPAR2.N_PARTY_SK_R=     FCT_GRP_PARTY_ADDRESS_R.N_PARTY_SK_R
       )
       )where rnk=1
    )adr
  ON adr.n_party_sk_r = b.n_party_sk_r
  LEFT JOIN stg_premier_producer_r pp
  ON pp.V_AGENCY_CODE_R = SUBSTR(C.V_AGENT_NUMBER_R,1, 6)
  LEFT JOIN stg_premier_producer_desc_r pd
  ON PP.V_BROKER_NAME_R     = PD.V_BROKER_NAME_R
  left outer join STG_CMSA_R T1011891   
  On T1011891.v_zip_code_r = substr(adr.V_POSTAL_ZIP_R , 1 , 5);