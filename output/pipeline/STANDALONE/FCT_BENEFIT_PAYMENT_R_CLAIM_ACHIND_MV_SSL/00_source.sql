

  CREATE MATERIALIZED VIEW "ATOMIC"."FCT_BENEFIT_PAYMENT_R_CLAIM_ACHIND_MV_SSL" ("N_CLAIM_SK_R", "ACH_INDICATOR")
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
  AS SELECT  /*+PARALLEL(4)*/
        n_claim_sk_r --AS claim_skey,
        ,max(ACH_INDICATOR) ACH_INDICATOR
		--INTO LV_ACH_INDICATOR
            FROM
              ( SELECT
              --DISTINCT
		     T334051.n_claim_sk_r
             ,  CASE
                  WHEN upper(T334051.V_PAY_METHOD_R) = 'ACH'
                  THEN 'Y'
                  ELSE 'N'
                END AS ACH_indicator
              FROM FCT_BENEFIT_PAYMENT_R T334051--,
                --dim_grp_claim_dir_r cd
              --WHERE
               --cd.n_claim_sk_r = T334051.n_claim_sk_r
              ----T334051.n_claim_sk_r = p_n_claim_sk_r
              --and cd.v_active_status_r = 'Y'
		group by --T334051.n_claim_sk_r,
		     T334051.n_claim_sk_r
             ,CASE
                  WHEN upper(T334051.V_PAY_METHOD_R) = 'ACH'
                  THEN 'Y'
                  ELSE 'N'
                END
              )
	GROUP BY N_CLAIM_SK_R

