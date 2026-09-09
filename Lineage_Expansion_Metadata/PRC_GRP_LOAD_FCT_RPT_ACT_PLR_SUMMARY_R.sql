--------------------------------------------------------
--  DDL for Procedure PRC_GRP_LOAD_FCT_RPT_ACT_PLR_SUMMARY_R
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "ATOMIC"."PRC_GRP_LOAD_FCT_RPT_ACT_PLR_SUMMARY_R" 
AS
/*4.	FCT_RPT_ACT_PLR_SUMMARY_R
a.	Already truncate and reload
b.	fiscal month end and weekly on saturdays
c. Dependent EDW Tables and tidal jobs
   fct_grp_policy_r
   --EDP_ODI_EDW_GRP_VUE_LOAD_VUE_FCT_GRP_POLICY_R
   --EDP_ODI_EDW_GRP_PACS_LOAD_FCT_GRP_POLICY_R
   --EDP_ODI_EDW_EIS_SHINKA_LOAD_FCT_GRP_POLICY_R

   dim_grp_policy_dir_r
   --EDP_ODI_EDW_GRP_VUE_LOAD_DIM_GRP_POLICY_DIR_R
   --EDP_ODI_EDW_GRP_PACS_LOAD_DIM_GRP_POLICY_DIR_R
   --EDP_ODI_EDW_GRP_STACS_LOAD_DIM_GRP_POLICY_DIR_R
   --EDP_ODI_EDW_EIS_SHINKA_LOAD_DIM_GRP_POLICY_DIR_R

Called by Tidal shell script :- edw_grp_load_fct_rpt_act_plr_summary_r.sh

--05-Sep-2023 : Changes in lc_bkp_tbl_str value  , added SS to make sure that even though the porgram runs more than one time in a day should not give Bkp table already exists
*/
--16-Jul-2024 : Due to Polocy prefix chnage done by Sudip in DIM_GRP_POLIICY_DIR the Policy Number logic also should be changed using the bridge table
--              VW_DIM_GRP_POLICY_DIR_R_POLICY_PREFIX_BRIDGE as RDM policy prefix change not happend
--              To make sure that Plr Summary  load won't fails
lc_bkp_tbl_str  VARCHAR2(10):=TO_CHAR(SYSDATE,'MMDDSS');
lc_sqlcode      VARCHAR2(300);
LC_SQLERRM       VARCHAR2(4000);
ld_sysdate      DATE:=SYSDATE;
lt_systimestamp TIMESTAMP:=SYSDATE;
lc_trcmsg       VARCHAR2(4000):='Trace Message:->';
ln_start_time   NUMBER;
ld_fic_mis_date DATE;
LC_DAY          VARCHAR2(30);
ln_n_batch_id_r number:=to_number(to_char(sysdate,'YYYYMMDD'));
BEGIN
  --TAKE BKP
  lc_trcmsg:=lc_trcmsg||chr(13)||'1. Entered into Procedure PRC_GRP_LOAD_FCT_RPT_ACT_PLR_SUMMARY_R';
  lc_trcmsg:=lc_trcmsg||chr(13)||'2 Get Day';
  SELECT TO_CHAR(SYSDATE,'DAY')
     INTO LC_DAY
     FROM DUAL;
  lc_trcmsg:=lc_trcmsg||chr(13)||'2.1 Day is:->'||LC_DAY;

  lc_trcmsg:=lc_trcmsg||chr(13)||'3. Get Fiscal Month End Date +1 ';
     SELECT D_CALENDAR_DATE_R +1 INTO ld_fic_mis_date
     FROM DIM_TIME_R D
     WHERE  V_END_OF_FISCAL_MONTH_IND_R = 'Y'
     and to_char(d_calendar_date_r,'YYYYMM')=to_char(sysdate,'YYYYMM');
  lc_trcmsg:=lc_trcmsg||chr(13)||'3.1 Fiscal Month End Date +1 is :->'||ld_fic_mis_date;

   IF TO_DATE(ld_fic_mis_date) = TO_DATE(ld_sysdate)  --to load data on next day of Fiscal Month (Ex:the fiscal month end for May 2023 is 26-MAY-23 so we should load this on 27-MAY-23)
   OR TRIM(LC_DAY)='SATURDAY'-- or to load data on Saturday
   THEN
      BEGIN
        EXECUTE IMMEDIATE 'CREATE TABLE ATOMIC.FCT_RPT_ACT_PLR_SUMMARY_R_BKP_'||lc_bkp_tbl_str||' as select * from ATOMIC.FCT_RPT_ACT_PLR_SUMMARY_R';
      	lc_trcmsg:=lc_trcmsg||chr(13)||'4. Bkp Table Created FCT_RPT_ACT_PLR_SUMMARY_R_BKP_'||lc_bkp_tbl_str;
      EXCEPTION
      WHEN OTHERS THEN
        LC_SQLERRM:=SUBSTR(SQLERRM,1,4000);
	    lc_trcmsg:=lc_trcmsg||chr(13)||'4.1. '||LC_SQLERRM;
      END;
      lc_trcmsg:=lc_trcmsg||chr(13)||'5. Truncate the table FCT_RPT_ACT_PLR_SUMMARY_R';

      EXECUTE IMMEDIATE 'TRUNCATE TABLE ATOMIC.FCT_RPT_ACT_PLR_SUMMARY_R  purge snapshot log';
      LC_TRCMSG:=LC_TRCMSG||CHR(13)||'5.1 Truncated the table FCT_RPT_ACT_PLR_SUMMARY_R';
      ln_start_time:=DBMS_UTILITY.GET_TIME;
      lc_trcmsg:=lc_trcmsg||chr(13)||'6. Insert into the table FCT_RPT_ACT_PLR_SUMMARY_R:->'||ln_start_time||' Seconds';

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
      --'Manual-Full Load' AS V_CREATED_BY_R,
      'PRC_GRP_LOAD_FCT_RPT_ACT_PLR_SUMMARY_R' AS V_CREATED_BY_R,
      --SYSDATE AS T_EVENT_TIMESTAMP_R,
      lt_systimestamp AS T_EVENT_TIMESTAMP_R,
      ROWNUM AS N_SEQUENCE_NUMBER_R,
      --SYSDATE AS FIC_MIS_DATE_R,
      ld_sysdate AS FIC_MIS_DATE_R,
      PERMISSIBLE_LOSS_RATIO N_PERMISSABLE_LR_R,
      FP.n_cust_party_sk_r AS N_PARTY_SK_R, -- could look up, but not required since we have policy
      FIVE_YEAR_TARGET_PROFITS AS N_5YR_TARGET_PROFIT_R,
      SOLD_ANNUALIZED_PREMIUM AS N_SOLD_ANNUALIZED_PREM_R,
      FIVE_YEAR_EARNED_PREMIUM AS N_5YR_EARNED_PREM_R,
      BILL_TO_MANUAL AS N_BILL_TO_MANUAL_R,
      THREE_YEAR_PV_INCURRED_CLAIMS AS N_3YR_PV_INCURRED_CLAIMS_R,
      MANUAL_ANNUALIZED_PREMIUM AS N_MANUAL_ANNUALIZED_PREM_R,
      PROFIT_TARGET_PCT AS N_PROFITPCT_R,
      COMMISSION_PCT AS N_COMMPCT_R,
      -1 N_CLAIM_SK_R, -- Not relevant
      '' V_CHANGE_REASON_R,
      '' F_PHYSICAL_DELETE_R,
      1 N_VERSION_NUMBER_R,
      'RDM' V_SOURCE_SYSTEM_NAME_R,
      1 N_LOAD_RUN_ID_R,
      --'Manual-Full Load' V_LAST_MODIFIED_BY_R,
      'PRC_GRP_LOAD_FCT_RPT_ACT_PLR_SUMMARY_R' V_LAST_MODIFIED_BY_R,
      ld_sysdate T_LAST_MODIFIED_DATE_R,
      ld_sysdate T_CREATION_DATE_R,
      --202012310000 AS N_BATCH_ID_R,
      --to_char(SYSDATE ,'YYYYMMDD') N_BATCH_ID_R,
      ln_n_batch_id_r N_BATCH_ID_R,
      THREE_YEAR_CONSTANT_PREMIUM AS N_3YR_CONSTANT_PREM_R,
      FIVE_YEAR_PV_INCURRED_CLAIMS AS N_5YR_PV_INCURRED_CLAIMS_R,
      FIVE_YEAR_CONSTANT_PREMIUM AS N_5YR_CONSTANT_PREM_R,
      CYCLE_DATE AS D_CYCLE_DATE_R,
      CENSUS_LIVES AS N_CENSUS_LIVES_R,
      THREE_YEAR_TARGET_PROFITS AS N_3YR_TARGET_PROFIT_R,
      THREE_YEAR_EARNED_PREMIUM AS N_3YR_EARNED_PREM_R,
      ACTUARIAL_LIVES AS N_ACTUARIAL_LIVES_R,
      pol_dir.N_POLICY_SK_R,-- look up based on Policy Number in the policy directory. For now I added another column called v_policy_number_r.
      -1 N_QUOTE_SK_R -- not relevant CD.POLICY_NUM V_POLICY_NUMBER_R
      from RDM.PERF_ACT_PLR_SUMMARY_FACT@REPORT.RSLI.COM pf JOIN RDM.CUSTOMER_DIM@REPORT.RSLI.COM CD
      ON pf.CUSTOMER_KEY = CD.CUSTOMER_KEY
	  --16-Jul-2024 changes starts
      --JOIN (SELECT /*+PARALLEL(4)*/  * FROM ATOMIC.dim_grp_policy_dir_r WHERE v_active_status_r='Y') pol_dir
      JOIN (select  N_POLICY_SK_R, OLD_V_POLICY_NUMBER_R  V_POLICY_NUMBER_R,
	           n_policy_version_number_r from VW_DIM_GRP_POLICY_DIR_R_POLICY_PREFIX_BRIDGE vw
            where exists (SELECT 1 from DIM_GRP_POLICY_DIR_R dim WHERE  dim.v_active_status_r ='Y' and dim.N_POLICY_SK_R=vw.N_POLICY_SK_R)
            group by N_POLICY_SK_R, OLD_V_POLICY_NUMBER_R,n_policy_version_number_r
		   ) pol_dir
	  --16-Jul-2024 changes ends
      --ON CD.POLICY_NUM=POL_DIR.V_POLICY_NUMBER_R
      ON (case when cd.PACS_LOB_CODE = 'MAL' then cd.PACS_LOB_CODE||cd.POLICY_SUFFIX else cd.policy_num end)=POL_DIR.V_POLICY_NUMBER_R
      LEFT JOIN (select /*+PARALLEL(4)*/ distinct n_version_number_r,N_POLICY_SK_R,n_cust_party_sk_r from  ATOMIC.fct_grp_policy_r) FP
      ON FP.n_policy_sk_r= pol_dir.n_policy_sk_r
      AND FP.n_version_number_r=pol_dir.n_policy_version_number_r;
      commit;
      lc_trcmsg:=lc_trcmsg||chr(13)||'6.1. Inserted data into the table FCT_RPT_ACT_PLR_SUMMARY_R:->'||(DBMS_UTILITY.GET_TIME-ln_start_time)||' Seconds';
	ELSE
	  lc_trcmsg:=lc_trcmsg||chr(13)||'6.2. The current date/day is neither Fiscal Month End Date +1 nor Saturday , So data will not be loaded';
    END IF;
	lc_trcmsg:=lc_trcmsg||'7. Insert trace message into the table PRCS_GRP_TBL_LOAD_DEBUG_TRC';
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

    commit;

EXCEPTION
WHEN OTHERS THEN
LC_SQLCODE:=SQLCODE;
LC_SQLERRM:=SUBSTR(SQLERRM,1,4000);
--OUT_LOAD_STATUS:=LC_SQLCODE||'-'||LC_SQLERRM;
--GC_TRC_MSG:='Final Error Message:->'||LC_SQLCODE||'-'||LC_SQLERRM;
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
											  ,'When others raised in PRC_GRP_LOAD_FCT_RPT_ACT_PLR_SUMMARY_R :->'||lc_trcmsg||LC_SQLCODE||'->'||LC_SQLERRM
											  ,ln_N_BATCH_ID_R
											  ,'PRC_GRP_LOAD_FCT_RPT_ACT_PLR_SUMMARY_R'
											  ,'PRC_GRP_LOAD_FCT_RPT_ACT_PLR_SUMMARY_R'
										);

commit;
raise_application_error(-20001,'Others-Error in PRC_GRP_LOAD_FCT_RPT_ACT_PLR_SUMMARY_R:->'||SQLERRM);

END PRC_GRP_LOAD_FCT_RPT_ACT_PLR_SUMMARY_R;

/

  GRANT EXECUTE ON "ATOMIC"."PRC_GRP_LOAD_FCT_RPT_ACT_PLR_SUMMARY_R" TO "ATOMIC_ALL_RO";
  GRANT EXECUTE ON "ATOMIC"."PRC_GRP_LOAD_FCT_RPT_ACT_PLR_SUMMARY_R" TO "EXT_DIGITAL_RO";
  GRANT EXECUTE ON "ATOMIC"."PRC_GRP_LOAD_FCT_RPT_ACT_PLR_SUMMARY_R" TO "EXT_EIS_RO";
  GRANT DEBUG ON "ATOMIC"."PRC_GRP_LOAD_FCT_RPT_ACT_PLR_SUMMARY_R" TO "ATOMIC_DEBUG";
