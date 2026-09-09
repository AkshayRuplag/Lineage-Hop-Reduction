--------------------------------------------------------
--  DDL for Procedure PRC_GRP_LOAD_FCT_RPT_EARN_PREMIUM_SUMMARY_R_MGIS
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "ATOMIC"."PRC_GRP_LOAD_FCT_RPT_EARN_PREMIUM_SUMMARY_R_MGIS" 

AS
BEGIN
    --Delete data if exists for MGIS
DELETE FROM ATOMIC.FCT_RPT_EARN_PREMIUM_SUMMARY_R WHERE V_SOURCE_SYSTEM_NAME_R = 'MGIS' AND D_CYCLE_DATE_R = (SELECT
        D_CALENDAR_DATE_R as D_CYCLE_DATE_R

    FROM
        DIM_TIME_R
    WHERE
            V_END_OF_FISCAL_MONTH_IND_R = 'Y'
        AND EXTRACT(MONTH FROM D_CALENDAR_DATE_R) = EXTRACT(MONTH FROM SYSDATE)
        AND EXTRACT(YEAR FROM D_CALENDAR_DATE_R) = EXTRACT(YEAR FROM SYSDATE)) ;
commit;
DELETE FROM atomic.fct_rpt_premium_summary_r WHERE V_SOURCE_SYSTEM_NAME_R = 'MGIS' AND D_CYCLE_DATE_R = (SELECT
        D_CALENDAR_DATE_R as D_CYCLE_DATE_R

    FROM
        DIM_TIME_R
    WHERE
            V_END_OF_FISCAL_MONTH_IND_R = 'Y'
        AND EXTRACT(MONTH FROM D_CALENDAR_DATE_R) = EXTRACT(MONTH FROM SYSDATE)
        AND EXTRACT(YEAR FROM D_CALENDAR_DATE_R) = EXTRACT(YEAR FROM SYSDATE)) ;
commit;
 INSERT INTO ATOMIC.FCT_RPT_EARN_PREMIUM_SUMMARY_R
(
D_CYCLE_DATE_R ,
D_DUE_DATE_R  ,
N_POLICY_SK_R  ,
V_POLICY_NUMBER_R  ,
V_CUSTOMER_BILL_GROUP_NUMBER_R ,
V_SHORT_NAME_R  ,
V_COVERAGE_CODE_R   ,
N_COLLECTED_PREMIUM_AMT_R  ,
N_WRITTEN_PREM_AMT_R   ,
N_EARNED_PREM_AMT_R ,
D_PRIOR_CYCLE_DATE_R ,
PRIOR_N_COLLECTED_PREMIUM_AMT_R,
FIC_MIS_DATE_R   ,
V_SOURCE_SYSTEM_NAME_R  ,
V_SUBJECT_AREA_TYPE_R,
N_VERSION_NUMBER_R   ,
F_PHYSICAL_DELETE_R ,
V_CHANGE_REASON_R ,
N_CLAIM_SK_R  ,
N_PARTY_SK_R ,
N_QUOTE_SK_R  ,
N_LOAD_RUN_ID_R  ,
N_SEQUENCE_NUMBER_R ,
T_CREATION_DATE_R ,
T_EVENT_TIMESTAMP_R  ,
T_LAST_MODIFIED_DATE_R ,
V_CREATED_BY_R ,
V_LAST_MODIFIED_BY_R ,
V_PRIVACY_INDICATOR_R   ,
V_CUSTOMER_NUMBER_R ,
N_BATCH_ID_R
)
with stagedata as (
Select
(SELECT
      D_CALENDAR_DATE_R as D_CYCLE_DATE_R

    FROM
        DIM_TIME_R
    WHERE
            V_END_OF_FISCAL_MONTH_IND_R = 'Y'
        AND EXTRACT(MONTH FROM D_CALENDAR_DATE_R) = EXTRACT(MONTH FROM SYSDATE)
        AND EXTRACT(YEAR FROM D_CALENDAR_DATE_R) = EXTRACT(YEAR FROM SYSDATE)) as D_CYCLE_DATE_R ,
TO_DATE(A.D_DUE_DATE_R, 'yyyy-MM-dd') AS D_DUE_DATE_R  ,
NVL(c.N_POLICY_SK_R,-1) AS N_POLICY_SK_R  ,
A.V_PREFIX_R || A.N_SUFFIX_R AS V_POLICY_NUMBER_R  ,
A.N_BILL_GROUP_R AS V_CUSTOMER_BILL_GROUP_NUMBER_R ,
A.V_COMPANY_R AS V_SHORT_NAME_R  ,
B.N_RSL_COVERAGE_CODE_R AS V_COVERAGE_CODE_R   ,
A.N_PREMIUM_AMT_R AS N_COLLECTED_PREMIUM_AMT_R  ,
A.N_PREMIUM_AMT_R AS N_WRITTEN_PREM_AMT_R   ,
A.N_PREMIUM_AMT_R AS N_EARNED_PREM_AMT_R ,
A.FIC_MIS_DATE_R

FROM
(Select
 V_PREFIX_R,N_SUFFIX_R, MAX(V_COMPANY_R) AS V_COMPANY_R,
 MAX(D_DUE_DATE_R) AS D_DUE_DATE_R,
 SUM(N_LIVES_R) AS N_LIVES_R ,
 SUM(N_VOLUME_R) AS N_VOLUME_R ,
 SUM(N_PREMIUM_AMT_R) AS N_PREMIUM_AMT_R,
 N_BILL_GROUP_R,
 V_COVERAGE_CODE_R,
 N_BILLING_MODE_R,
 MAX(N_BATCH_ID_R) AS N_BATCH_ID_R,
 MAX(FIC_MIS_DATE_R) AS FIC_MIS_DATE_R


FROM STG_MGIS_RM_PREMIUM_R
where N_BATCH_ID_R=(Select max(n_batch_id_r) from ATOMIC.STG_MGIS_RM_PREMIUM_R)
group by V_PREFIX_R,N_SUFFIX_R,V_COVERAGE_CODE_R,N_BILL_GROUP_R,
    N_BILLING_MODE_R) A
LEFT JOIN
STG_LKP_MGIS_COVG_CD_R B
ON A.V_COVERAGE_CODE_R = B.V_COVERAGE_CODE_R
LEFT JOIN
dim_grp_policy_dir_r C
ON
A.V_PREFIX_R||A.N_SUFFIX_R = C.V_ORIG_POLICY_NUMBER_R
--A.V_PREFIX_R = C.V_POLICY_PREFIX_R
--AND LTRIM(A.N_SUFFIX_R,'0') = LTRIM(C.V_POLICY_SUFFIX_R,'0')
AND C.V_ACTIVE_STATUS_R='Y' ),
FinalData as (
SELECT
D_CYCLE_DATE_R ,
MAX(D_DUE_DATE_R) AS D_DUE_DATE_R  ,
N_POLICY_SK_R  ,
V_POLICY_NUMBER_R  ,
V_CUSTOMER_BILL_GROUP_NUMBER_R ,
V_SHORT_NAME_R  ,
V_COVERAGE_CODE_R   ,
SUM(N_COLLECTED_PREMIUM_AMT_R) AS N_COLLECTED_PREMIUM_AMT_R   ,
SUM(N_WRITTEN_PREM_AMT_R) AS N_WRITTEN_PREM_AMT_R   ,
SUM(N_EARNED_PREM_AMT_R) AS N_EARNED_PREM_AMT_R ,
FIC_MIS_DATE_R
from stagedata
GROUP BY
D_CYCLE_DATE_R ,
N_POLICY_SK_R  ,
V_POLICY_NUMBER_R  ,
V_CUSTOMER_BILL_GROUP_NUMBER_R ,
V_SHORT_NAME_R  ,
V_COVERAGE_CODE_R   ,
FIC_MIS_DATE_R

),
BATCH_DATE AS (
        SELECT * FROM
            ( SELECT to_date(D_CALENDAR_DATE_R,'YYYY-MM-DD') as D_CALENDAR_DATE_R,
                    RANK() OVER (  ORDER BY D_CALENDAR_DATE_R DESC) DATE_RANK
                from
                    Atomic.DIM_TIME_R
                where
                    V_END_OF_FISCAL_MONTH_IND_R = 'Y' AND D_CALENDAR_DATE_R < (SELECT D_CALENDAR_DATE_R +1
    FROM DIM_TIME_R D
    WHERE  V_END_OF_FISCAL_MONTH_IND_R = 'Y'
    and to_char(d_calendar_date_r,'YYYYMM')=to_char(sysdate,'YYYYMM'))
            ) WHERE DATE_RANK < 3
    ),
	MTD_Final as
	 (
SELECT
D_CYCLE_DATE_R ,
--D_DUE_DATE_R  ,
N_POLICY_SK_R  ,
V_POLICY_NUMBER_R  ,
V_CUSTOMER_BILL_GROUP_NUMBER_R ,
V_SHORT_NAME_R  ,
V_COVERAGE_CODE_R   ,
SUM(N_COLLECTED_PREMIUM_AMT_R) AS PRIOR_N_COLLECTED_PREMIUM_AMT_R    ,
SUM(N_WRITTEN_PREM_AMT_R) AS N_WRITTEN_PREM_AMT_R   ,
SUM(N_EARNED_PREM_AMT_R) AS N_EARNED_PREM_AMT_R
--,FIC_MIS_DATE_R
from ATOMIC.FCT_RPT_EARN_PREMIUM_SUMMARY_R
where V_SOURCE_SYSTEM_NAME_R = 'MGIS' and D_CYCLE_DATE_R = (SELECT BATCH_DATE.D_CALENDAR_DATE_R FROM BATCH_DATE WHERE DATE_RANK = 2)
GROUP BY
D_CYCLE_DATE_R ,
--D_DUE_DATE_R  ,
N_POLICY_SK_R  ,
V_POLICY_NUMBER_R  ,
V_CUSTOMER_BILL_GROUP_NUMBER_R ,
V_SHORT_NAME_R  ,
V_COVERAGE_CODE_R
--, FIC_MIS_DATE_R

)
SELECT
FD.D_CYCLE_DATE_R ,
FD.D_DUE_DATE_R  ,
FD.N_POLICY_SK_R  ,
FD.V_POLICY_NUMBER_R  ,
FD.V_CUSTOMER_BILL_GROUP_NUMBER_R ,
FD.V_SHORT_NAME_R  ,
FD.V_COVERAGE_CODE_R   ,
FD.N_COLLECTED_PREMIUM_AMT_R  ,
FD.N_WRITTEN_PREM_AMT_R   ,
FD.N_EARNED_PREM_AMT_R ,
MTD.D_CYCLE_DATE_R AS D_PRIOR_CYCLE_DATE_R ,
MTD.PRIOR_N_COLLECTED_PREMIUM_AMT_R,
FD.FIC_MIS_DATE_R   ,
'MGIS' AS V_SOURCE_SYSTEM_NAME_R  ,
NULL as V_SUBJECT_AREA_TYPE_R,
NULL as N_VERSION_NUMBER_R   ,
NULL as F_PHYSICAL_DELETE_R ,
NULL as V_CHANGE_REASON_R ,
-1 as N_CLAIM_SK_R  ,
-1 as N_PARTY_SK_R ,
-1 as N_QUOTE_SK_R  ,
(select NVL(MAX(N_LOAD_RUN_ID_R),0)+1 from ATOMIC.FCT_RPT_EARN_PREMIUM_SUMMARY_R where V_SOURCE_SYSTEM_NAME_R ='MGIS' AND
FIC_MIS_DATE_R=(Select max(FIC_MIS_DATE_R) from ATOMIC.STG_MGIS_RM_PREMIUM_R)) AS N_LOAD_RUN_ID_R ,
(select NVL(MAX(N_SEQUENCE_NUMBER_R),0) from ATOMIC.FCT_RPT_EARN_PREMIUM_SUMMARY_R) + rownum as N_SEQUENCE_NUMBER_R,
sysdate as T_CREATION_DATE_R ,
sysdate as T_EVENT_TIMESTAMP_R  ,
sysdate as T_LAST_MODIFIED_DATE_R ,
'Data Lake' as V_CREATED_BY_R ,
'Data Lake' as V_LAST_MODIFIED_BY_R ,
NULL as V_PRIVACY_INDICATOR_R   ,
NULL as V_CUSTOMER_NUMBER_R ,
sysdate as N_BATCH_ID_R
From
FinalData FD
LEFT JOIN MTD_Final MTD
ON

--FD.D_DUE_DATE_R = MTD.D_DUE_DATE_R AND
FD.N_POLICY_SK_R = MTD.N_POLICY_SK_R  AND
FD.V_POLICY_NUMBER_R  =  MTD.V_POLICY_NUMBER_R AND
FD.V_CUSTOMER_BILL_GROUP_NUMBER_R =  MTD.V_CUSTOMER_BILL_GROUP_NUMBER_R   AND
FD.V_SHORT_NAME_R = MTD.V_SHORT_NAME_R AND
FD.V_COVERAGE_CODE_R = MTD.V_COVERAGE_CODE_R ;
commit;
INSERT /*+APPEND_VALUES*/ INTO atomic.fct_rpt_premium_summary_r (
                n_batch_id_r,
                v_policy_number_r,
                v_customer_bill_group_number_r,
                v_short_name_r,
                v_coverage_code_r,
                n_collected_premium_amt_r,
                n_due_prem_amt_r,
                n_due_prem_unearned_amt,
                n_prem_unearned_amt,
                n_written_prem_amt_r,
                n_earned_prem_amt_r,
                d_prior_cycle_date_r,
                n_prior_due_prem_amt_r,
                n_prior_dueprem_unearned_amt_r,
                n_prior_prem_unearned_amt_r,
                n_chg_due_prem_amt_r,
                n_chg_due_prem_unearned_amt_r,
                n_chg_prem_unearned_amt_r,
                n_constant_earned_prem_amt_r,
                n_load_run_id_r,
                n_sequence_number_r,
                t_creation_date_r,
                t_event_timestamp_r,
                t_last_modified_date_r,
                v_created_by_r,
                v_last_modified_by_r,
                d_cycle_date_r,
                d_due_date_r,
                v_reinsurance_indicator_r,
                fic_mis_date_r,
                v_source_system_name_r,
                v_subject_area_type_r,
                n_version_number_r,
                f_physical_delete_r,
                v_change_reason_r,
                n_policy_sk_r,
                n_claim_sk_r,
                n_party_sk_r,
                n_quote_sk_r,
                n_prior_due_prem_amt_fin_r,
                n_chg_due_prem_amt_fin_r,
                n_due_prem_amt_fin_r,
                n_prior_dueprem_unearned_fin_r,
                n_chg_dueprem_unearned_fin_r,
                n_due_prem_unearned_amt_fin_r,
                v_customer_number_r,
                v_policy_prefix_r,
                v_policy_suffix_r,
                n_coll_prem_net_amt_r,
                n_due_prem_net_amt_r,
                n_due_prem_unearned_net_amt_r,
                n_prem_unearned_net_amt_r,
                n_written_prem_net_amt_r,
                n_earned_prem_net_amt_r,
                n_chg_due_prem_net_amt_r,
                n_chg_due_prm_unrnd_net_amt_r,
                n_chg_prem_unearned_net_amt_r,
                n_coll_prem_ceded_amt_r,
                n_due_prem_ceded_amt_r,
                n_due_prem_unearned_ceded_amt_r,
                n_prem_unearned_ceded_amt_r,
                n_written_prem_ceded_amt_r,
                n_earned_prem_ceded_amt_r,
                n_chg_due_prem_ceded_amt_r,
                n_chg_due_prm_unrnd_ceded_amt_r,
                n_chg_prem_unearned_ceded_amt_r,
                n_total_reins_prem_pct_r,
                n_primary_reins_prem_pct_r,
                n_sec_reins_prem_pct_r,
                n_ternary_reins_prem_pct_r,
                v_primary_reinsurer_r,
                v_secondary_reinsurer_r,
                v_ternary_reinsurer_r,
                v_privacy_indicator_r,
                n_collected_premium_unearned_amt_r,
          --      n_prior_collected_premium_amt_r,
           --     n_prior_collected_premium_unearned_amt_r,
                n_mtd_chg_collected_premium_amt_r,
                n_mtd_collected_premium_unearned_amt_r,
                n_due_prem_amt_r_all,
                n_due_prem_unearned_amt_all,
                n_prem_unearned_amt_all,
                n_prior_due_prem_amt_r_all,
                n_prior_dueprem_unearned_amt_r_all,
                n_prior_prem_unearned_amt_r_all,
                n_earned_prem_amt_r_all,
                n_chg_due_prem_amt_r_all,
                n_chg_due_prem_unearned_amt_r_all,
                n_chg_prem_unearned_amt_r_all
            )
            SELECT
                 TO_NUMBER(TO_CHAR(SYSDATE,'YYYYDD'))||'0000' n_batch_id_r,
                v_policy_number_r,
                v_customer_bill_group_number_r,
                v_short_name_r,
                v_coverage_code_r,
                n_collected_premium_amt_r,
                n_due_prem_amt_r,
                n_due_prem_unearned_amt,
                n_prem_unearned_amt,
                n_written_prem_amt_r,
                n_earned_prem_amt_r,
                d_prior_cycle_date_r,
                n_prior_due_prem_amt_r,
                n_prior_dueprem_unearned_amt_r,
                n_prior_prem_unearned_amt_r,
                n_chg_due_prem_amt_r,
                n_chg_due_prem_unearned_amt_r,
                n_chg_prem_unearned_amt_r,
                n_constant_earned_prem_amt_r,
                n_load_run_id_r,
               (select NVL(MAX(N_SEQUENCE_NUMBER_R),0) from ATOMIC.FCT_RPT_EARN_PREMIUM_SUMMARY_R) + rownum      AS n_sequence_number_r,
                t_creation_date_r,
                t_event_timestamp_r,
                t_last_modified_date_r,
                v_created_by_r,
                v_last_modified_by_r,
                d_cycle_date_r,
                d_due_date_r,
                v_reinsurance_indicator_r,
                fic_mis_date_r,
                v_source_system_name_r,
                v_subject_area_type_r,
                n_version_number_r,
                f_physical_delete_r,
                v_change_reason_r,
                n_policy_sk_r,
                n_claim_sk_r,
                n_party_sk_r,
                n_quote_sk_r,
                0            n_prior_due_prem_amt_fin_r,
                0            n_chg_due_prem_amt_fin_r,
                0            n_due_prem_amt_fin_r,
                0            n_prior_dueprem_unearned_fin_r,
                0            n_chg_dueprem_unearned_fin_r,
                0            n_due_prem_unearned_amt_fin_r,
                v_customer_number_r,
                ' '          v_policy_prefix_r,
                ' '          v_policy_suffix_r,
                0            n_coll_prem_net_amt_r,
                0            n_due_prem_net_amt_r,
                0            n_due_prem_unearned_net_amt_r,
                0            n_prem_unearned_net_amt_r,
                0            n_written_prem_net_amt_r,
                0            n_earned_prem_net_amt_r,
                0            n_chg_due_prem_net_amt_r,
                0            n_chg_due_prm_unrnd_net_amt_r,
                0            n_chg_prem_unearned_net_amt_r,
                0            n_coll_prem_ceded_amt_r,
                0            n_due_prem_ceded_amt_r,
                0            n_due_prem_unearned_ceded_amt_r,
                0            n_prem_unearned_ceded_amt_r,
                0            n_written_prem_ceded_amt_r,
                0            n_earned_prem_ceded_amt_r,
                0            n_chg_due_prem_ceded_amt_r,
                0            n_chg_due_prm_unrnd_ceded_amt_r,
                0            n_chg_prem_unearned_ceded_amt_r,
                0            n_total_reins_prem_pct_r,
                1            n_primary_reins_prem_pct_r,
                0            n_sec_reins_prem_pct_r,
                0            n_ternary_reins_prem_pct_r,
                'N/A'        v_primary_reinsurer_r,
                'NA'         v_secondary_reinsurer_r,
                'NA'         v_ternary_reinsurer_r,
                'N/A'        v_privacy_indicator_r,
                n_collected_premium_unearned_amt_r,
--                n_prior_collected_premium_amt_r,
--                n_prior_collected_premium_unearned_amt_r,
                n_mtd_chg_collected_premium_amt_r,
                n_mtd_collected_premium_unearned_amt_r,
                n_due_prem_amt_r_all,
                n_due_prem_unearned_amt_all,
                n_prem_unearned_amt_all,
                n_prior_due_prem_amt_r_all,
                n_prior_dueprem_unearned_amt_r_all,
                n_prior_prem_unearned_amt_r_all,
                n_earned_prem_amt_r_all,
                n_chg_due_prem_amt_r_all,
                n_chg_due_prem_unearned_amt_r_all,
                n_chg_prem_unearned_amt_r_all
            FROM
                FCT_RPT_EARN_PREMIUM_SUMMARY_R WHERE V_SOURCE_SYSTEM_NAME_R = 'MGIS' AND D_CYCLE_DATE_R = (SELECT
        D_CALENDAR_DATE_R as D_CYCLE_DATE_R

    FROM
        DIM_TIME_R
    WHERE
            V_END_OF_FISCAL_MONTH_IND_R = 'Y'
        AND EXTRACT(MONTH FROM D_CALENDAR_DATE_R) = EXTRACT(MONTH FROM SYSDATE)
        AND EXTRACT(YEAR FROM D_CALENDAR_DATE_R) = EXTRACT(YEAR FROM SYSDATE)) ;
commit;
END;

/

  GRANT EXECUTE ON "ATOMIC"."PRC_GRP_LOAD_FCT_RPT_EARN_PREMIUM_SUMMARY_R_MGIS" TO "ATOMIC_ALL_RO";
