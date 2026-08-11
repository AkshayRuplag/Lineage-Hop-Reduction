

  CREATE MATERIALIZED VIEW "ATOMIC"."DIM_GRP_CLAIM_DETAIL_R_MV_SSL_INC" ("N_INSRD_PARTY_SK_R", "V_PRIVACY_INDICATOR_R", "T_LAST_MODIFIED_DATE_R")
  SEGMENT CREATION IMMEDIATE
  ORGANIZATION HEAP PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "OFS_OIDF_DATA_3"
  PARALLEL
  BUILD IMMEDIATE
  USING INDEX
  REFRESH FORCE ON DEMAND
  USING DEFAULT LOCAL ROLLBACK SEGMENT
  USING ENFORCED CONSTRAINTS DISABLE ON QUERY COMPUTATION DISABLE QUERY REWRITE
  AS SELECT MAIN.n_insrd_party_sk_r,MAIN.v_privacy_indicator_r
,GREATEST(
         COALESCE(MAIN.t_last_modified_date_r, TO_DATE('1900-01-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS'))
        ,COALESCE(PR.t_last_modified_date_r, TO_DATE('1900-01-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS'))
        ,COALESCE(FCT_MAIN_ADD.t_last_modified_date_r, TO_DATE('1900-01-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS'))
        ,COALESCE(FCT_MAIL_ADD.t_last_modified_date_r, TO_DATE('1900-01-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS'))
        ) t_last_modified_date_r
FROM (
        select DISTINCT
            main.n_insrd_party_sk_r,
            main.v_privacy_indicator_r ,
            TO_DATE(TO_CHAR(mts.max_t_last_modified_date_r, 'YYYY-MM-DD HH24:MI:SS'), 'YYYY-MM-DD HH24:MI:SS') as t_last_modified_date_r
        from ATOMIC.dim_grp_claim_detail_r main
        JOIN
        (	select b.n_insrd_party_sk_r
                ,max(trim(b.T_EVENT_TIMESTAMP_R)) AS T_EVENT_TIMESTAMP_R
                ,MAX(t_last_modified_date_r) AS max_t_last_modified_date_r
            from ATOMIC.dim_grp_claim_detail_r b
            where  B.N_CLAIM_SK_R > -1
            GROUP BY b.n_insrd_party_sk_r
        ) mts
        ON  trim(main.T_EVENT_TIMESTAMP_R)=mts.T_EVENT_TIMESTAMP_R AND main.n_insrd_party_sk_r=mts.n_insrd_party_sk_r
        where  main.n_claim_sk_r>-1 --and main.n_insrd_party_sk_r=16710466
    ) MAIN
    inner join
    (   select n_party_sk_r,N_SOURCE_VERSION_NUMBER_R,t_last_modified_date_r
        from  ATOMIC.dim_grp_party_r where v_active_status_r = 'Y'
    ) PR
        on MAIN.n_insrd_party_sk_r = PR.n_party_sk_r
 left join
        (
            select  n_party_sk_r,N_SOURCE_VERSION_NUMBER_R,t_last_modified_date_r
            from ATOMIC.fct_grp_party_address_r where V_LOCATION_ID_R = 'MAIN'
            and n_address_sk_r>-1
		) FCT_MAIN_ADD
        on FCT_MAIN_ADD.n_party_sk_r = PR.n_party_sk_r
        and FCT_MAIN_ADD.N_SOURCE_VERSION_NUMBER_R = PR.N_SOURCE_VERSION_NUMBER_R
left join (
            select   n_party_sk_r,N_SOURCE_VERSION_NUMBER_R,t_last_modified_date_r
            from ATOMIC.fct_grp_party_address_r
            where V_LOCATION_ID_R = 'MAILING'  and n_address_sk_r>-1
		) FCT_MAIL_ADD
        on FCT_MAIL_ADD.n_party_sk_r = PR.n_party_sk_r
        and FCT_MAIL_ADD.N_SOURCE_VERSION_NUMBER_R = PR.N_SOURCE_VERSION_NUMBER_R

