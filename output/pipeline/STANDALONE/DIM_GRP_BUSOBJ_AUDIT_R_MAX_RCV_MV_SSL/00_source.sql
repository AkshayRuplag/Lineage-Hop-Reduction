

  CREATE MATERIALIZED VIEW "ATOMIC"."DIM_GRP_BUSOBJ_AUDIT_R_MAX_RCV_MV_SSL" ("V_CLAIM_NUMBER_R", "RECEIVED_DATE")
  SEGMENT CREATION IMMEDIATE
  ORGANIZATION HEAP PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "OFS_OIDF_DATA_3"
  BUILD IMMEDIATE
  USING INDEX
  REFRESH FORCE ON DEMAND
  USING DEFAULT LOCAL ROLLBACK SEGMENT
  USING ENFORCED CONSTRAINTS DISABLE ON QUERY COMPUTATION DISABLE QUERY REWRITE
  AS SELECT             v_claim_number_r,
                              MAX(nvl(t374156.d_received_date_r,
                                      TO_DATE(substr(t374156.v_claim_number_r, 1, 10),
                                              'YYYY-MM-DD'))) AS received_date
                          FROM
                              DIM_GRP_BUSOBJ_AUDIT_R t374156
                          WHERE
                                  v_active_status_r = 'Y'
                              AND v_claim_number_r NOT IN ( '-LIFE-01', '-LTD-01', '-STD-01', '-VPS-01', '-WOP-01' )
                          GROUP BY
                              v_claim_number_r
  --20-Feb-2024 changes starts
  union
    select  b.v_claim_number_r, a.D_RECEIVED_DATE_R as received_date
     from dim_grp_claim_detail_r a, dim_grp_claim_dir_r b
     where a.n_claim_sk_r = b.n_claim_sk_r
     and a.v_active_status_r = 'Y'
     and b.v_active_status_r = 'Y'
     and b.v_source_system_name_r = 'CV'
   GROUP BY b.v_claim_number_r, a.D_RECEIVED_DATE_R

