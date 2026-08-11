create or replace PACKAGE BODY                      PKG_GRP_FULLLOAD_OFFSETS
/* *********************************************************************************************************************************
* Type -            PLSQL Package
* Name -            PKG_GRP_FULLLOAD_OFFSETS
* Owner -           ATOMIC
* Description -     This package has the PLSQL procedures used to populate the Group tables, called by ODI wrappers.
* Created on -      13-March-2023
* CHANGE LOG -
* 13-March-2023: Added procedure PRC_FULLLOAD_FCT_CLAIMPMNT_DET_OFFSET1_R,PRC_FULLLOAD_FCT_CLAIMPMNT_DET_OFFSET2_R,
PRC_FULLLOAD_FCT_CLAIMPMNT_DET_OFFSET3_R to do full load in FCT_CLAIM_PAYMENT_DETAIL_OFFSETS_R table.
*31-March-2023:  Calls procedure proc_truncate_partition before doing Full Load.
*31-Jul-2023: as requested by Erica Added Payee columns and V_PAYEE_TYPE_R in Offset1,Offset2 and Offset3 insert and select
*************************************************************************************************************************************/
as
PROCEDURE PRC_FULLLOAD_FCT_CLAIMPMNT_DET_OFFSET1_R(
    --IN_BATCH_ID_R        IN NUMBER,
    OUT_LOAD_STATUS      OUT VARCHAR2
    )
IS
LD_SYSDATE DATE :=SYSDATE;
LC_SQLCODE VARCHAR2(4000);
LC_SQLERRM VARCHAR2(4000);
LN_SEQUENCE_NUMBER_R NUMBER;
--LN_IN_BATCH_ID_R NUMBER:=IN_BATCH_ID_R;
LN_LOAD_RUN_ID_R NUMBER:=1;
lv_message_type_r  PRCS_JOB_LOG_MESSAGE_R.v_message_type_r%TYPE:= PKG_GRP_LOG_UTIL.gc_message_type_info;
BEGIN

	/*IF LN_IN_BATCH_ID_R IS NULL THEN
	  OUT_LOAD_STATUS:='a) BatchID(IN_BATCH_ID) is null hence terminating the program';
	 RAISE_APPLICATION_ERROR(-20001,'a) BatchID(IN_BATCH_ID) is null hence terminating the program');
	END IF;*/

/*SELECT   MAX(N_SEQUENCE_NUMBER_R)
      INTO LN_SEQUENCE_NUMBER_R
FROM FCT_BENEFIT_PAYMENT_DETAIL_R;*/

/*SELECT   COUNT(1)
      INTO ln_load_run_id_r
FROM PRCS_JOB_LOG_R
WHERE N_BATCH_ID_R =IN_BATCH_ID_R
AND V_JOB_NAME_R='GRP_FULLLOAD_FCT_CLAIMPMNT_DET_OFFSET1_R';*/

 --A) Delete Offset1 data in FCT_CLAIM_PAYMENT_DETAIL_OFFSETS_R
 --  DELETE  from FCT_CLAIM_PAYMENT_DETAIL_OFFSETS_R
 --  WHERE V_OFFSET_TYPE_R='OFFSET1'
 --  ;
  -- COMMIT;

        gc_main_loadedby :='PKG_GRP_FULLLOAD_OFFSETS.PRC_FULLLOAD_FCT_CLAIMPMNT_DET_OFFSET1_R';

        pkg_grp_log_util.prc_insert_log
                       ( p_source              			=> gc_source
					    ,p_job_nm              			=> gc_job_name
                        ,p_job_status          			=> gc_running_status
                        ,p_err_msg             			=> null
                        ,p_trc_msg             			=> null
                        ,p_n_batch_id          			=> gn_sysdt_batchid
                        ,p_log_util_called_by_r			=> gc_main_loadedby
						,out_job_id            			=> gn_out_job_id
						);

		gc_trcmsg:='1. Entered into PRC_FULLLOAD_FCT_CLAIMPMNT_DET_OFFSET1_R ';



		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
						p_job_id_r            			=> gn_out_job_id,
						p_batch_id_r                  	=> gn_sysdt_batchid,
						p_message_type_r              	=> lv_message_type_r,
						p_code_location_r             	=> gc_main_loadedby,
						p_message_r                   	=> gc_trcmsg,
						p_count_type_r                	=> NULL,
						p_count_r                     	=> NULL,
						p_duration_r                  	=> NULL,
						p_created_by_r                	=> GC_JOB_NAME,
						out_prcs_job_log_message_id_r 	=> gn_job_log_message_id_r
						);

		gc_trcmsg:='2. Started Truncation Partition for partition name OFFSET1 for procedure PRC_FULLLOAD_FCT_CLAIMPMNT_DET_OFFSET1_R for table FCT_CLAIM_PAYMENT_DETAIL_OFFSETS_R';
        PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
						p_job_id_r            			=> gn_out_job_id,
						p_batch_id_r                  	=> gn_sysdt_batchid,
						p_message_type_r              	=> lv_message_type_r,
						p_code_location_r             	=> gc_main_loadedby,
						p_message_r                   	=> gc_trcmsg,
						p_count_type_r                	=> NULL,
						p_count_r                     	=> NULL,
						p_duration_r                  	=> NULL,
						p_created_by_r                	=> GC_JOB_NAME,
						out_prcs_job_log_message_id_r 	=> gn_job_log_message_id_r
						);



  proc_truncate_partition('FCT_CLAIM_PAYMENT_DETAIL_OFFSETS_R','OFFSET1',TO_NUMBER(TO_CHAR(SYSDATE,'YYYYMMDD')));

        gc_trcmsg:='3. Completed Truncation Partition for partition OFFSET1 for procedure PRC_FULLLOAD_FCT_CLAIMPMNT_DET_OFFSET1_R for table FCT_CLAIM_PAYMENT_DETAIL_OFFSETS_R';
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
						p_job_id_r            			=> gn_out_job_id,
						p_batch_id_r                  	=> gn_sysdt_batchid,
						p_message_type_r              	=> lv_message_type_r,
						p_code_location_r             	=> gc_main_loadedby,
						p_message_r                   	=> gc_trcmsg,
						p_count_type_r                	=> NULL,
						p_count_r                     	=> NULL,
						p_duration_r                  	=> NULL,
						p_created_by_r                	=> GC_JOB_NAME,
						out_prcs_job_log_message_id_r 	=> gn_job_log_message_id_r
						);


				gc_trcmsg:='4.Started data to insert into FCT_CLAIM_PAYMENT_DETAIL_OFFSETS_R';
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
						p_job_id_r            			=> gn_out_job_id,
						p_batch_id_r                  	=> gn_sysdt_batchid,
						p_message_type_r              	=> lv_message_type_r,
						p_code_location_r             	=> gc_main_loadedby,
						p_message_r                   	=> gc_trcmsg,
						p_count_type_r                	=> NULL,
						p_count_r                     	=> NULL,
						p_duration_r                  	=> NULL,
						p_created_by_r                	=> GC_JOB_NAME,
						out_prcs_job_log_message_id_r 	=> gn_job_log_message_id_r
						);	

INSERT /*+APPEND*/ INTO FCT_CLAIM_PAYMENT_DETAIL_OFFSETS_R
(
N_POLICY_SK_R
,N_PARTY_SK_R
,N_CLAIM_SK_R
,N_CLAIM_COVERAGE_SK_R
,N_CLAIM_COVERAGE_GROUP_SK_R
,N_BATCH_ID_R
,N_LOAD_RUN_ID_R
--,N_SEQUENCE_NUMBER_R
,T_CREATION_DATE_R
,T_LAST_MODIFIED_DATE_R
,V_CREATED_BY_R
,V_LAST_MODIFIED_BY_R
,FIC_MIS_DATE_R
,N_SEQ_R
,D_PAYPERIOD_START_R
,D_PAYPERIOD_END_R
,D_PAYMENTDATE_R
,N_AMOUNT_R
,V_TYPE_R
,N_DEBITAMOUNT_R
,N_CREDITAMOUNT_R
,V_BENEFIT_CODE_R
,V_BENEFIT_DESC_R
,N_PAY_DTL_SOURCE_SYSTEM_KEY_R
,N_PAID_CLAIM_BENEFITS_R
,N_TAXABLE_BENEFIT_AMT_R
,N_FEDERAL_TAX_WITHHELD_AMT_R
,N_STATE_TAX_WITHHELD_AMT_R
,N_EMPLOYEE_SS_WITHHELD_AMT_R
,N_EMPLOYEE_MED_WITHHELD_AMT_R
,N_EMPLOYER_SS_WITHHELD_AMT_R
,N_EMPLOYER_MED_WITHHELD_AMT_R
,N_LEGAL_EXPENSE_DIRECT_AMT_R
,N_OTHER_EXPENSE_DIRECT_AMT_R
,V_AMOUNT_TYPE_CATEGORY_R
,V_AMOUNT_TYPE_CATEGORY_DESC_R
,V_AMOUNT_TYPE_SUB_CATEGORY_R
,V_AMT_TYPE_SUB_CATEGORY_DESC_R
,V_AMOUNT_TYPE_CODE_R
,V_AMOUNT_TYPE_NAME_R
,V_AMOUNT_TYPE_SUB_CODE_R
,V_AMOUNT_TYPE_SUB_NAME_R
,F_PHYSICAL_DELETE_R
,V_CHANGE_REASON_R
,D_RECORD_END_DATE_R
,D_RECORD_START_DATE_R
,V_CLAIM_TYPE_R
,N_GROUP_SEQ_R
,N_SOURCE_VERSION_SEQ_NUMBER_R
,V_PRIVACY_INDICATOR_R
,N_VERSION_NUMBER_R
,T_EVENT_TIMESTAMP_R
,V_OFFSET_TYPE_R
--27-SEP-2023 changes starts
,V_PAYEE_FIRST_NAME_R
,V_PAYEE_MIDDLE_NAME_R
,v_payee_last_name_r
,V_PAYEE_TYPE_R
--27-SEP-2023 changes ends
)
SELECT
 A.N_POLICY_SK_R
,A.N_PARTY_SK_R
,A.N_CLAIM_SK_R
,A.N_CLAIM_COVERAGE_SK_R
,A.N_CLAIM_COVERAGE_GROUP_SK_R
,A.N_BATCH_ID_R                   --For full load
,LN_LOAD_RUN_ID_R N_LOAD_RUN_ID_R
--,NVL(LN_SEQUENCE_NUMBER_R,0)+ROWNUM N_SEQUENCE_NUMBER_R
,LD_SYSDATE T_CREATION_DATE_R
,LD_SYSDATE T_LAST_MODIFIED_DATE_R
--,'ODI' V_CREATED_BY_R --27-SEP-2023 changes
--,'ODI' V_LAST_MODIFIED_BY_R --27-SEP-2023 changes
,'PKG_GRP_FULLLOAD_OFFSETS.PRC_FULLLOAD_FCT_CLAIMPMNT_DET_OFFSET1_R' V_CREATED_BY_R --27-SEP-2023 changes
,'PKG_GRP_FULLLOAD_OFFSETS.PRC_FULLLOAD_FCT_CLAIMPMNT_DET_OFFSET1_R' V_LAST_MODIFIED_BY_R --27-SEP-2023 changes
,A.FIC_MIS_DATE_R
,A.N_SEQ_R
,A.D_PAYPERIOD_START_R
,A.D_PAYPERIOD_END_R
,A.D_PAYMENTDATE_R
,A.N_AMOUNT_R
,A.V_TYPE_R
,A.N_DEBITAMOUNT_R
,A.N_CREDITAMOUNT_R
,A.V_BENEFIT_CODE_R
,A.V_BENEFIT_DESC_R
,A.N_PAY_DTL_SOURCE_SYSTEM_KEY_R
,A.N_PAID_CLAIM_BENEFITS_R
,A.N_TAXABLE_BENEFIT_AMT_R
,A.N_FEDERAL_TAX_WITHHELD_AMT_R
,A.N_STATE_TAX_WITHHELD_AMT_R
,A.N_EMPLOYEE_SS_WITHHELD_AMT_R
,A.N_EMPLOYEE_MED_WITHHELD_AMT_R
,A.N_EMPLOYER_SS_WITHHELD_AMT_R
,A.N_EMPLOYER_MED_WITHHELD_AMT_R
,A.N_LEGAL_EXPENSE_DIRECT_AMT_R
,A.N_OTHER_EXPENSE_DIRECT_AMT_R
,A.V_AMOUNT_TYPE_CATEGORY_R
,A.V_AMOUNT_TYPE_CATEGORY_DESC_R
,A.V_AMOUNT_TYPE_SUB_CATEGORY_R
,A.V_AMT_TYPE_SUB_CATEGORY_DESC_R
,A.V_AMOUNT_TYPE_CODE_R
,A.V_AMOUNT_TYPE_NAME_R
,A.V_AMOUNT_TYPE_SUB_CODE_R
,A.V_AMOUNT_TYPE_SUB_NAME_R
,A.F_PHYSICAL_DELETE_R
,A.V_CHANGE_REASON_R
,A.D_RECORD_END_DATE_R
,A.D_RECORD_START_DATE_R
,A.V_CLAIM_TYPE_R
,A.N_GROUP_SEQ_R
,A.N_SOURCE_VERSION_SEQ_NUMBER_R
,A.V_PRIVACY_INDICATOR_R
,A.N_VERSION_NUMBER_R
,A.T_EVENT_TIMESTAMP_R
,'OFFSET1'
--27-SEP-2023 changes starts
,PA.V_INDIVIDUAL_FIRST_NAME_R V_PAYEE_FIRST_NAME_R
,PA.V_INDIVIDUAL_MIDDLE_NAME_R V_PAYEE_MIDDLE_NAME_R
,pa.V_INDIVIDUAL_LAST_NAME_R v_payee_last_name_r
,(case  when PD.V_PAYEE_TYPE_R = 'Agent' then ' UNK ' when PD.V_PAYEE_TYPE_R = 'Beneficiary' then 'UNK' when PD.V_PAYEE_TYPE_R = 'Customer' then 'GRP' when PD.V_PAYEE_TYPE_R = 'Insured' then 'IND' when PD.V_PAYEE_TYPE_R = 'Vendor' then 'PRV' else PD.V_PAYEE_TYPE_R end ) V_PAYEE_TYPE_R
--27-SEP-2023 changes ends
from
(--13-Nov-2022 Gireesh Changes ends
select  DISTINCT * from (WITH FBP_1 AS (
select DISTINCT N_PAY_SCHD_SOURCE_SYSTEM_KEY_R,N_SOURCE_VERSION_SEQ_NUMBER_R,N_SEQ_R, V_REFERENCE_R, n_claim_sk_r
FROM FCT_BENEFIT_PAYMENT_R
WHERE ( (V_REFERENCE_R) like 'ALLSOURCE%' OR UPPER(V_REFERENCE_R) like 'BACKDOOR%' )
--where ((upper(V_REFERENCE_R) like 'ALLSOURCE%' OR UPPER(V_REFERENCE_R) like 'BACKDOOR%') or nvl((UPPER(V_REFERENCE_R)),'ALLSOURCE') not like 'MINIMUM BENEFIT APPLIED%' OR  UPPER(V_REFERENCE_R) not like 'MINIMUM BENEFIT APPLIED%')
--AND N_BATCH_ID_R = 202109190000-- Added by Gireesh 17mar
--and n_claim_sk_r = 168169
--AND N_BATCH_ID_R = LN_IN_BATCH_ID_R--13-Nov-2022 Added by Gireesh for Incremental
)
--select * from FBP_1);
,
FBP_D_1 AS ( Select * FROM FCT_BENEFIT_PAYMENT_DETAIL_R
--WHERE N_BATCH_ID_R = 202109190000 -- Added by Gireesh 17mar
where
--V_BENEFIT_CODE_R != '382' and
N_SEQ_R != 9000 and N_SEQ_R != 9001--Added recently by Aravind
--and n_claim_sk_r = 168169
--AND N_BATCH_ID_R = LN_IN_BATCH_ID_R --13-Nov-2022 Added by Gireesh for Incremental
)
--select * from FBP_D_1);
, AMT_1 AS (
SELECT TRIM(FBP_D_1.N_PAY_DTL_SOURCE_SYSTEM_KEY_R) N_PAY_DTL_SOURCE_SYSTEM_KEY_R,
TRIM(FBP_D_1.N_SOURCE_VERSION_SEQ_NUMBER_R) N_SOURCE_VERSION_SEQ_NUMBER_R,
TRIM(FBP_D_1.N_GROUP_SEQ_R) N_GROUP_SEQ_R,
Sum(FBP_D_1.N_Amount_R) S_N_Amount_R
FROM FBP_D_1 JOIN FBP_1
ON FBP_1.N_PAY_SCHD_SOURCE_SYSTEM_KEY_R = TRIM(FBP_D_1.N_PAY_DTL_SOURCE_SYSTEM_KEY_R)
AND FBP_1.N_SOURCE_VERSION_SEQ_NUMBER_R = TRIM(FBP_D_1.N_SOURCE_VERSION_SEQ_NUMBER_R)
AND FBP_1.N_SEQ_R = TRIM(FBP_D_1.N_GROUP_SEQ_R)
where
--FBP_D_1.n_claim_sk_r = 168169 and
FBP_D_1.V_BENEFIT_CODE_R in ('402','COL')
Or (UPPER(FBP_D_1.V_TYPE_R) = 'ADJUSTMENT' and UPPER(FBP_D_1.V_BENEFIT_CODE_R) like 'GENERAL%')
Or UPPER(FBP_D_1.V_TYPE_R) in ('OFFSET', 'PAYMENT INTERRUPTION')
group by TRIM(FBP_D_1.N_PAY_DTL_SOURCE_SYSTEM_KEY_R),TRIM(FBP_D_1.N_SOURCE_VERSION_SEQ_NUMBER_R),TRIM(FBP_D_1.N_GROUP_SEQ_R)
)
--select * from AMT_1); -- different amount
, FBP_2 AS (
select DISTINCT N_PAY_SCHD_SOURCE_SYSTEM_KEY_R,N_SOURCE_VERSION_SEQ_NUMBER_R,N_SEQ_R,N_PARENT_OBJECTNUM_R,V_REFERENCE_R,
V_PAY_STATUS_R ,N_ADJ_NET_BENEFIT_R, N_GROSS_BENEFIT_R,N_PRIMARY_PAYEE_R,V_CHECK_NUM_R, D_TRANS_DATE_R, N_ADJ_GROSS_BENEFIT_R,V_LINK_OBJECTNUM_R---27-SEP-2023
FROM FCT_BENEFIT_PAYMENT_R
WHERE  ((V_REFERENCE_R) like 'ALLSOURCE%' OR UPPER(V_REFERENCE_R) like 'BACKDOOR%' )
AND UPPER(V_PAY_STATUS_R) in ('RELEASED','REVERSED','REVERSAL')
--AND N_BATCH_ID_R = 202109190000 -- Added by Gireesh 17mar
--and n_claim_sk_r = 168169
--AND N_BATCH_ID_R = LN_IN_BATCH_ID_R --13-Nov-2022 Added by Gireesh for Incremental
)
--select * from FBP_2);
,FWS AS (Select distinct n_worksheet_seq_nbr_objectnm_r,n_source_system_key_r,n_spec_benefit_adjust_r,n_gross_benefit_r
FROM FCT_GRP_WORKSHEET
--where n_claim_sk_r = 168169
)

--select * from FWS);
,AMT_2 AS (
SELECT FBP_2.N_PAY_SCHD_SOURCE_SYSTEM_KEY_R,FBP_2.N_SOURCE_VERSION_SEQ_NUMBER_R,FBP_2.N_SEQ_R,fbp_2.v_pay_status_r,
FBP_2.N_ADJ_NET_BENEFIT_R, N_PRIMARY_PAYEE_R,
FWS.n_spec_benefit_adjust_r,FWS.n_gross_benefit_r, V_CHECK_NUM_R, D_TRANS_DATE_R,
fws.N_WORKSHEET_SEQ_NBR_OBJECTNM_R,--27-SEP-2023
fws.n_source_system_key_r--27-SEP-2023
,FBP_2.V_LINK_OBJECTNUM_R---27-SEP-2023
,
/* CASE WHEN UPPER(fbp_2.V_PAY_STATUS_R) in ('RELEASED','REVERSED')
     THEN (CASE WHEN FWS.n_spec_benefit_adjust_r > 0 THEN FWS.n_spec_benefit_adjust_r ELSE FWS.n_gross_benefit_r END )
      WHEN  fbp_2.V_PAY_STATUS_R = 'REVERSAL'
      THEN( CASE WHEN FWS.n_spec_benefit_adjust_r > 0 THEN  FWS.n_spec_benefit_adjust_r  ELSE  FWS.n_gross_benefit_r * -1 END)
      ELSE 0 END AS FWS_AMT */
CASE WHEN UPPER(fbp_2.V_PAY_STATUS_R) in ('RELEASED','REVERSED','REVERSAL') and N_PRIMARY_PAYEE_R = 1
     THEN FBP_2.N_ADJ_GROSS_BENEFIT_R
	  WHEN UPPER(fbp_2.V_PAY_STATUS_R) in ('RELEASED','REVERSED') and N_PRIMARY_PAYEE_R = 0
      THEN  (CASE WHEN FWS.n_spec_benefit_adjust_r > 0 THEN FWS.n_spec_benefit_adjust_r ELSE FWS.n_gross_benefit_r END )
      WHEN  fbp_2.V_PAY_STATUS_R = 'REVERSAL' and N_PRIMARY_PAYEE_R = 0
      THEN( CASE WHEN FWS.n_spec_benefit_adjust_r > 0 THEN  FWS.n_spec_benefit_adjust_r  ELSE  FWS.n_gross_benefit_r * -1 END)
      ELSE 0 END AS FWS_AMT
FROM FWS Join FBP_2
ON TRIM(FWS.n_worksheet_seq_nbr_objectnm_r) = TRIM(FBP_2.N_PARENT_OBJECTNUM_R)
AND TRIM(FWS.n_source_system_key_r) = TRIM(FBP_2.N_PAY_SCHD_SOURCE_SYSTEM_KEY_R)
/*JOIN  FBP_D_1
ON FBP_2.N_PAY_SCHD_SOURCE_SYSTEM_KEY_R = TRIM(FBP_D_1.N_PAY_DTL_SOURCE_SYSTEM_KEY_R)
AND FBP_2.N_SOURCE_VERSION_SEQ_NUMBER_R = TRIM(FBP_D_1.N_SOURCE_VERSION_SEQ_NUMBER_R)
AND FBP_2.N_SEQ_R = TRIM(FBP_D_1.N_GROUP_SEQ_R)*/
)
--select * from AMT_2);
, FBP_D_2 AS (Select distinct
N_POLICY_SK_R,
N_PARTY_SK_R,
N_CLAIM_SK_R,
N_CLAIM_COVERAGE_SK_R,
N_CLAIM_COVERAGE_GROUP_SK_R,
N_BATCH_ID_R,--13-Nov-2022 enabled for full load
/* Commented by Gireesh
N_BATCH_ID_R,
N_LOAD_RUN_ID_R,
0 AS N_SEQUENCE_NUMBER_R,
T_CREATION_DATE_R,
T_LAST_MODIFIED_DATE_R,
V_CREATED_BY_R,
V_LAST_MODIFIED_BY_R, */
FIC_MIS_DATE_R,
D_PAYPERIOD_START_R,
D_PAYPERIOD_END_R,
D_PAYMENTDATE_R,
N_PAY_DTL_SOURCE_SYSTEM_KEY_R,
0 AS N_STATE_TAX_WITHHELD_AMT_R,
0 AS N_EMPLOYEE_MED_WITHHELD_AMT_R,
0 AS N_EMPLOYEE_SS_WITHHELD_AMT_R,
0 AS N_EMPLOYER_MED_WITHHELD_AMT_R,
0 AS N_EMPLOYER_SS_WITHHELD_AMT_R,
0 AS N_LEGAL_EXPENSE_DIRECT_AMT_R,
0 AS N_OTHER_EXPENSE_DIRECT_AMT_R,
F_PHYSICAL_DELETE_R,
V_CHANGE_REASON_R,
D_RECORD_END_DATE_R,
D_RECORD_START_DATE_R,
V_CLAIM_TYPE_R ,
N_GROUP_SEQ_R,
N_SOURCE_VERSION_SEQ_NUMBER_R,
V_BENEFIT_CODE_R,
V_TYPE_R,
V_PRIVACY_INDICATOR_R,
N_VERSION_NUMBER_R,
T_EVENT_TIMESTAMP_R
FROM FCT_BENEFIT_PAYMENT_DETAIL_R
--WHERE N_BATCH_ID_R = 202109190000 -- Added by Gireesh 17mar
--where n_claim_sk_r = 168169 --and n_source_version_seq_number_r = '339'-- included  to look for a specific claim number
--AND V_BENEFIT_CODE_R != '382'
Where N_SEQ_R != 9000 and N_SEQ_R != 9001
--where n_claim_sk_r = 551575
--AND N_BATCH_ID_R = LN_IN_BATCH_ID_R --13-Nov-2022 Added by Gireesh for Incremental
)
--select * from FBP_D_2);
select DISTINCT
FBP_D_2.N_POLICY_SK_R,
FBP_D_2.N_PARTY_SK_R,
FBP_D_2.N_CLAIM_SK_R,
FBP_D_2.N_CLAIM_COVERAGE_SK_R,
FBP_D_2.N_CLAIM_COVERAGE_GROUP_SK_R,
FBP_D_2.N_BATCH_ID_R,--13-Nov-2022 enabled for full load
AMT_2.V_CHECK_NUM_R,
AMT_2.D_TRANS_DATE_R,
/*--Commented by Gireesh 20-Mar-2022
FBP_D_2.N_BATCH_ID_R,
FBP_D_2.N_LOAD_RUN_ID_R,
FBP_D_2.N_SEQUENCE_NUMBER_R,
FBP_D_2.T_CREATION_DATE_R,
FBP_D_2.T_LAST_MODIFIED_DATE_R,
FBP_D_2.V_CREATED_BY_R,
FBP_D_2.V_LAST_MODIFIED_BY_R,
*/
FBP_D_2.FIC_MIS_DATE_R,
9000 AS N_SEQ_R,
FBP_D_2.D_PAYPERIOD_START_R,
FBP_D_2.D_PAYPERIOD_END_R,
FBP_D_2.D_PAYMENTDATE_R,
AMT_1.S_N_Amount_R,
 --Case when
--(CASE WHEN NVL(AMT_1.S_N_Amount_R,0) +  NVL(AMT_2.FWS_AMT,0) != AMT_2.N_ADJ_NET_BENEFIT_R THEN nvl(AMT_2.N_ADJ_NET_BENEFIT_R,0) - (nvl(AMT_1.S_N_Amount_R,0) +  NVL(AMT_2.FWS_AMT,0))  ELSE NULL END <> 0)
--then FBP_D_2.V_BENEFIT_CODE_R||' '||V_TYPE_R else '382 Offset' end Check_value,
AMT_2.FWS_AMT,
AMT_2.N_ADJ_NET_BENEFIT_R,
V_PAY_STATUS_R,
CASE WHEN NVL(AMT_1.S_N_Amount_R,0) +  NVL(AMT_2.FWS_AMT,0) != AMT_2.N_ADJ_NET_BENEFIT_R THEN nvl(AMT_2.N_ADJ_NET_BENEFIT_R,0) - (nvl(AMT_1.S_N_Amount_R,0) +  NVL(AMT_2.FWS_AMT,0))  ELSE 0 END
AS N_AMOUNT_R,
'Offset' AS V_TYPE_R,
0 AS N_DEBITAMOUNT_R ,
0 AS N_CREDITAMOUNT_R ,
'382' AS V_BENEFIT_CODE_R,
'ALLSOURCE EXCESS OFFSET' AS V_BENEFIT_DESC_R,
FBP_D_2.N_PAY_DTL_SOURCE_SYSTEM_KEY_R,
CASE WHEN NVL(AMT_1.S_N_Amount_R,0) +  NVL(AMT_2.FWS_AMT,0) != AMT_2.N_ADJ_NET_BENEFIT_R THEN nvl(AMT_2.N_ADJ_NET_BENEFIT_R,0) - (nvl(AMT_1.S_N_Amount_R,0) +  NVL(AMT_2.FWS_AMT,0))  ELSE 0 END
AS N_PAID_CLAIM_BENEFITS_R,
0 AS N_TAXABLE_BENEFIT_AMT_R,
0 AS N_FEDERAL_TAX_WITHHELD_AMT_R,
FBP_D_2.N_STATE_TAX_WITHHELD_AMT_R,
FBP_D_2.N_EMPLOYEE_MED_WITHHELD_AMT_R,
FBP_D_2.N_EMPLOYEE_SS_WITHHELD_AMT_R,
FBP_D_2.N_EMPLOYER_MED_WITHHELD_AMT_R,
FBP_D_2.N_EMPLOYER_SS_WITHHELD_AMT_R,
FBP_D_2.N_LEGAL_EXPENSE_DIRECT_AMT_R,
FBP_D_2.N_OTHER_EXPENSE_DIRECT_AMT_R,
'OF' AS V_AMOUNT_TYPE_CATEGORY_R,
'OFFSETS' AS V_AMOUNT_TYPE_CATEGORY_DESC_R,
'OFFSETS' AS V_AMOUNT_TYPE_SUB_CATEGORY_R ,
'OFFSETS' AS V_AMT_TYPE_SUB_CATEGORY_DESC_R ,
'382' AS V_AMOUNT_TYPE_CODE_R,
'ALLSOURCE EXCESS OFFSET' AS V_AMOUNT_TYPE_NAME_R,
'382' AS V_AMOUNT_TYPE_SUB_CODE_R ,
'ALLSOURCE EXCESS OFFSET' AS V_AMOUNT_TYPE_SUB_NAME_R ,
FBP_D_2.F_PHYSICAL_DELETE_R,
FBP_D_2.V_CHANGE_REASON_R,
FBP_D_2.D_RECORD_END_DATE_R,
FBP_D_2.D_RECORD_START_DATE_R,
FBP_D_2.V_CLAIM_TYPE_R ,
FBP_D_2.N_GROUP_SEQ_R,
FBP_D_2.N_SOURCE_VERSION_SEQ_NUMBER_R,
FBP_D_2.V_PRIVACY_INDICATOR_R,
FBP_D_2.N_VERSION_NUMBER_R,
FBP_D_2.T_EVENT_TIMESTAMP_R
,amt_2.N_WORKSHEET_SEQ_NBR_OBJECTNM_R--27-SEP-2023
,amt_2.n_source_system_key_r--27-SEP-2023
,amt_2.V_LINK_OBJECTNUM_R--27-SEP-2023
FROM FBP_D_2 FULL OUTER JOIN AMT_1
ON FBP_D_2.N_PAY_DTL_SOURCE_SYSTEM_KEY_R= AMT_1.N_PAY_DTL_SOURCE_SYSTEM_KEY_R
AND FBP_D_2.N_SOURCE_VERSION_SEQ_NUMBER_R= AMT_1.N_SOURCE_VERSION_SEQ_NUMBER_R
AND FBP_D_2.N_GROUP_SEQ_R=AMT_1.N_GROUP_SEQ_R
FULL OUTER JOIN AMT_2
ON FBP_D_2.N_PAY_DTL_SOURCE_SYSTEM_KEY_R= AMT_2.N_PAY_SCHD_SOURCE_SYSTEM_KEY_R
AND FBP_D_2.N_SOURCE_VERSION_SEQ_NUMBER_R= AMT_2.N_SOURCE_VERSION_SEQ_NUMBER_R
AND FBP_D_2.N_GROUP_SEQ_R=AMT_2.N_SEQ_R
--WHERE (CASE WHEN NVL(AMT_1.S_N_Amount_R,0) +  NVL(AMT_2.FWS_AMT,0) !=AMT_2.N_ADJ_NET_BENEFIT_R THEN AMT_2.N_ADJ_NET_BENEFIT_R - (AMT_1.S_N_Amount_R +  AMT_2.FWS_AMT)  ELSE 0 END <> 0)
where (NVL(AMT_1.S_N_Amount_R, 0) != 0 or  NVL(AMT_2.FWS_AMT,0) != 0)
and CASE WHEN NVL(AMT_1.S_N_Amount_R,0) +  NVL(AMT_2.FWS_AMT,0) != AMT_2.N_ADJ_NET_BENEFIT_R THEN nvl(AMT_2.N_ADJ_NET_BENEFIT_R,0) - (nvl(AMT_1.S_N_Amount_R,0) +  NVL(AMT_2.FWS_AMT,0))  ELSE 0 END <> 0
AND FBP_D_2.N_CLAIM_SK_R IS NOT NULL
--and  Case when
--(CASE WHEN NVL(AMT_1.S_N_Amount_R,0) +  NVL(AMT_2.FWS_AMT,0) != AMT_2.N_ADJ_NET_BENEFIT_R THEN nvl(AMT_2.N_ADJ_NET_BENEFIT_R,0) - (nvl(AMT_1.S_N_Amount_R,0) +  NVL(AMT_2.FWS_AMT,0))  ELSE NULL END <> 0)
--then FBP_D_2.V_BENEFIT_CODE_R||' '||V_TYPE_R else '382 Offset' end = '382 Offset'
) --order by V_CHECK_NUM_R
--where N_CLAIM_SK_R = 502460 --and V_CHECK_NUM_R = 501354;	PreProd Atomic	10/27/22 5:29 PM	SQL	1	160.394
)--13-Nov-2022 Gireesh Changes
 A
--27-SEP-2023 changes starts
  ,(SELECT * FROM ATOMIC.dim_payment_details pd WHERE PD.V_ACTIVE_STATUS_R = 'Y')PD
  ,(SELECT * FROM ATOMIC.dim_grp_party_r WHERE v_active_status_r = 'Y') pa
--where pd.V_PAYMNT_DTLS_SRC_SYS_KEY_R = DGCDR.n_source_system_key_r
where --pd.V_PAYMNT_DTLS_SRC_SYS_KEY_R = a.n_source_system_key_r
	a.N_SOURCE_SYSTEM_KEY_R =PD.V_PAYMNT_DTLS_SRC_SYS_KEY_R(+)
     --and pd.v_active_status_r = 'Y'
     --and pd.V_WORKSHEET_OBJECTNUM_R = FBPR.N_WORKSHEET_SEQ_NBR_OBJECTNM_R
     --and pd.V_WORKSHEET_OBJECTNUM_R = a.N_WORKSHEET_SEQ_NBR_OBJECTNM_R
	 --AND pd.V_PAYMNT_DTLS_SEQ_NBR_R = a.V_LINK_OBJECTNUM_R---18-SEP-2023
	 AND A.N_WORKSHEET_SEQ_NBR_OBJECTNM_R = PD.V_WORKSHEET_OBJECTNUM_R(+)
     AND NVL(A.V_LINK_OBJECTNUM_R,0)=PD.V_PAYMNT_DTLS_SEQ_NBR_R(+)
     and pd.N_INSRD_PARTY_SK_R = pa.n_party_sk_r(+)
     --and pa.v_active_status_r = 'Y'
     --AND PD.V_PAYMNT_DTLS_SEQ_NBR_R = (SELECT MAX(B.V_PAYMNT_DTLS_SEQ_NBR_R)
     --                            from dim_payment_details b
     --                            where b.V_PAYMNT_DTLS_SRC_SYS_KEY_R = pd.V_PAYMNT_DTLS_SRC_SYS_KEY_R
     --                            and b.V_WORKSHEET_OBJECTNUM_R = pd.V_WORKSHEET_OBJECTNUM_R
     --                            and b.v_active_status_r = 'Y')
--27-SEP-2023 changes ends
/*WHERE NOT EXISTS (
SELECT 1 FROM FCT_CLAIM_PAYMENT_DETAIL_OFFSETS_R B
WHERE
B.N_PAY_DTL_SOURCE_SYSTEM_KEY_R                =A.N_PAY_DTL_SOURCE_SYSTEM_KEY_R
AND B.N_VERSION_NUMBER_R                       =A.N_VERSION_NUMBER_R
AND B.N_SOURCE_VERSION_SEQ_NUMBER_R            =A.N_SOURCE_VERSION_SEQ_NUMBER_R
AND B.N_SEQ_R                                  =A.N_SEQ_R
AND B.V_AMOUNT_TYPE_NAME_R                     =A.V_AMOUNT_TYPE_NAME_R
AND B.V_AMOUNT_TYPE_NAME_R = 'ALLSOURCE EXCESS OFFSET'
AND B.N_SEQ_R='9000'
)*/
;
COMMIT;


		gc_trcmsg:='5.Completed data insertion into FCT_CLAIM_PAYMENT_DETAIL_OFFSETS_R';
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
						p_job_id_r            			=> gn_out_job_id,
						p_batch_id_r                  	=> gn_sysdt_batchid,
						p_message_type_r              	=> lv_message_type_r,
						p_code_location_r             	=> gc_main_loadedby,
						p_message_r                   	=> gc_trcmsg,
						p_count_type_r                	=> NULL,
						p_count_r                     	=> NULL,
						p_duration_r                  	=> NULL,
						p_created_by_r                	=> GC_JOB_NAME,
						out_prcs_job_log_message_id_r 	=> gn_job_log_message_id_r
						);


		gc_trcmsg:='1. Exit from PRC_FULLLOAD_FCT_CLAIMPMNT_DET_OFFSET1_R ';
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
						p_job_id_r            			=> gn_out_job_id,
						p_batch_id_r                  	=> gn_sysdt_batchid,
						p_message_type_r              	=> lv_message_type_r,
						p_code_location_r             	=> gc_main_loadedby,
						p_message_r                   	=> gc_trcmsg,
						p_count_type_r                	=> NULL,
						p_count_r                     	=> NULL,
						p_duration_r                  	=> NULL,
						p_created_by_r                	=> GC_JOB_NAME,
						out_prcs_job_log_message_id_r 	=> gn_job_log_message_id_r
						);

			pkg_grp_log_util.prc_update_log(
      						gn_out_job_id                   --p_job_id
							,gc_success_status              --p_job_status
							,gc_errmsg                      --p_err_msg
							,gc_trcmsg                      --p_trc_msg
							,gc_main_loadedby               --p_log_util_called_by_r
							);

OUT_LOAD_STATUS:='SUCCESS';
EXCEPTION
WHEN OTHERS THEN
LC_SQLCODE:=SQLCODE;
LC_SQLERRM:=SUBSTR(SQLERRM,1,4000);
OUT_LOAD_STATUS:=LC_SQLCODE||'-'||LC_SQLERRM;
DBMS_OUTPUT.PUT_LINE('PRC_FULLLOAD_FCT_CLAIMPMNT_DET_OFFSET1_R  EXCEPTION WITH ERROR CODE AS '
             || SQLCODE
             || ' '
             || SQLERRM
             || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
             ||'PRC_FULLLOAD_FCT_CLAIMPMNT_DET_OFFSET1_R'
             ||';');

    gc_errmsg :=SUBSTR(SQLERRM,1,4000);
    gc_trcmsg:='1.z Error in PRC_FULLLOAD_FCT_CLAIMPMNT_DET_OFFSET1_R: '||gc_errmsg;

         /*START: NEW LOGGING MECHANISM CHANGES*/    
    pkg_grp_log_util.prc_update_log_message_r
			( 
			n_prcs_job_log_message_id_r => gn_job_log_message_id_r,
			p_err_msg 					=> gc_trcmsg 
				);
	     /*END: NEW LOGGING MECHANISM CHANGES*/     

	pkg_grp_log_util.prc_update_log
      (
        gn_out_job_id                   	--p_job_id
        ,gc_error_status                	--p_job_status
        ,gc_errmsg                       	--p_err_msg
        ,gc_trcmsg					     	--p_trc_msg
        ,gc_main_loadedby               	--p_log_util_called_by_r
    );			 

  	RAISE_APPLICATION_ERROR(-20001,'Error in PKG_GRP_FULLLOAD_OFFSETS.PRC_FULLLOAD_FCT_CLAIMPMNT_DET_OFFSET1_R:->
    Error Code:'||LC_SQLCODE||',Error message:'||LC_SQLERRM);			 

END PRC_FULLLOAD_FCT_CLAIMPMNT_DET_OFFSET1_R;


PROCEDURE PRC_FULLLOAD_FCT_CLAIMPMNT_DET_OFFSET2_R(
    --IN_BATCH_ID_R        IN NUMBER,
    OUT_LOAD_STATUS      OUT VARCHAR2
    )
IS
LD_SYSDATE DATE :=SYSDATE;
LC_SQLCODE VARCHAR2(4000);
LC_SQLERRM VARCHAR2(4000);
LN_SEQUENCE_NUMBER_R NUMBER;
--LN_IN_BATCH_ID_R NUMBER:=IN_BATCH_ID_R;
LN_LOAD_RUN_ID_R NUMBER:=1;
lv_message_type_r  PRCS_JOB_LOG_MESSAGE_R.v_message_type_r%TYPE:= PKG_GRP_LOG_UTIL.gc_message_type_info;
BEGIN

	/*IF LN_IN_BATCH_ID_R IS NULL THEN
	  OUT_LOAD_STATUS:='a) BatchID(IN_BATCH_ID) is null hence terminating the program';
	 RAISE_APPLICATION_ERROR(-20001,'a) BatchID(IN_BATCH_ID) is null hence terminating the program');
	END IF; */

/*SELECT   MAX(N_SEQUENCE_NUMBER_R)
      INTO LN_SEQUENCE_NUMBER_R
FROM FCT_BENEFIT_PAYMENT_DETAIL_R;*/

/*SELECT   COUNT(1)
      INTO ln_load_run_id_r
FROM PRCS_JOB_LOG_R
WHERE N_BATCH_ID_R =IN_BATCH_ID_R
AND V_JOB_NAME_R='GRP_FULLLOAD_FCT_CLAIMPMNT_DET_OFFSET2_R';*/

 --B) Delete Offset2 data in FCT_CLAIM_PAYMENT_DETAIL_OFFSETS_R
  -- DELETE from FCT_CLAIM_PAYMENT_DETAIL_OFFSETS_R
  -- WHERE V_OFFSET_TYPE_R='OFFSET2'
  -- ;
  -- COMMIT;


	gc_main_loadedby :='PKG_GRP_FULLLOAD_OFFSETS.PRC_FULLLOAD_FCT_CLAIMPMNT_DET_OFFSET2_R';

    pkg_grp_log_util.prc_insert_log
                       ( p_source              			=> gc_source
					    ,p_job_nm              			=> gc_job_name
                        ,p_job_status          			=> gc_running_status
                        ,p_err_msg             			=> null
                        ,p_trc_msg             			=> null
                        ,p_n_batch_id          			=> gn_sysdt_batchid
                        ,p_log_util_called_by_r			=> gc_main_loadedby
						,out_job_id            			=> gn_out_job_id
						);

				gc_trcmsg:='1. Entered into PRC_FULLLOAD_FCT_CLAIMPMNT_DET_OFFSET2_R ';

			PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
						p_job_id_r            			=> gn_out_job_id,
						p_batch_id_r                  	=> gn_sysdt_batchid,
						p_message_type_r              	=> lv_message_type_r,
						p_code_location_r             	=> gc_main_loadedby,
						p_message_r                   	=> gc_trcmsg,
						p_count_type_r                	=> NULL,
						p_count_r                     	=> NULL,
						p_duration_r                  	=> NULL,
						p_created_by_r                	=> GC_JOB_NAME,
						out_prcs_job_log_message_id_r 	=> gn_job_log_message_id_r
						);			

    gc_trcmsg:='2. Started Truncation Partition for partition name OFFSET2 for procedure PRC_FULLLOAD_FCT_CLAIMPMNT_DET_OFFSET2_R for table FCT_CLAIM_PAYMENT_DETAIL_OFFSETS_R';
    PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
						p_job_id_r            			=> gn_out_job_id,
						p_batch_id_r                  	=> gn_sysdt_batchid,
						p_message_type_r              	=> lv_message_type_r,
						p_code_location_r             	=> gc_main_loadedby,
						p_message_r                   	=> gc_trcmsg,
						p_count_type_r                	=> NULL,
						p_count_r                     	=> NULL,
						p_duration_r                  	=> NULL,
						p_created_by_r                	=> GC_JOB_NAME,
						out_prcs_job_log_message_id_r 	=> gn_job_log_message_id_r
						);

  proc_truncate_partition('FCT_CLAIM_PAYMENT_DETAIL_OFFSETS_R','OFFSET2',TO_NUMBER(TO_CHAR(SYSDATE,'YYYYMMDD')));


  		gc_trcmsg:='3. Completed Truncation Partition for partition OFFSET2 for procedure PRC_FULLLOAD_FCT_CLAIMPMNT_DET_OFFSET2_R for table FCT_CLAIM_PAYMENT_DETAIL_OFFSETS_R ';
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
						p_job_id_r            			=> gn_out_job_id,
						p_batch_id_r                  	=> gn_sysdt_batchid,
						p_message_type_r              	=> lv_message_type_r,
						p_code_location_r             	=> gc_main_loadedby,
						p_message_r                   	=> gc_trcmsg,
						p_count_type_r                	=> NULL,
						p_count_r                     	=> NULL,
						p_duration_r                  	=> NULL,
						p_created_by_r                	=> GC_JOB_NAME,
						out_prcs_job_log_message_id_r 	=> gn_job_log_message_id_r
						);


		gc_trcmsg:='4.Started data to insert into FCT_CLAIM_PAYMENT_DETAIL_OFFSETS_R';
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
						p_job_id_r            			=> gn_out_job_id,
						p_batch_id_r                  	=> gn_sysdt_batchid,
						p_message_type_r              	=> lv_message_type_r,
						p_code_location_r             	=> gc_main_loadedby,
						p_message_r                   	=> gc_trcmsg,
						p_count_type_r                	=> NULL,
						p_count_r                     	=> NULL,
						p_duration_r                  	=> NULL,
						p_created_by_r                	=> GC_JOB_NAME,
						out_prcs_job_log_message_id_r 	=> gn_job_log_message_id_r
						);


INSERT /*+APPEND*/ INTO FCT_CLAIM_PAYMENT_DETAIL_OFFSETS_R
(
N_POLICY_SK_R
,N_PARTY_SK_R
,N_CLAIM_SK_R
,N_CLAIM_COVERAGE_SK_R
,N_CLAIM_COVERAGE_GROUP_SK_R
,N_BATCH_ID_R
,N_LOAD_RUN_ID_R
--,N_SEQUENCE_NUMBER_R
,T_CREATION_DATE_R
,T_LAST_MODIFIED_DATE_R
,V_CREATED_BY_R
,V_LAST_MODIFIED_BY_R
,FIC_MIS_DATE_R
,N_SEQ_R
,D_PAYPERIOD_START_R
,D_PAYPERIOD_END_R
,D_PAYMENTDATE_R
,N_AMOUNT_R
,V_TYPE_R
,N_DEBITAMOUNT_R
,N_CREDITAMOUNT_R
,V_BENEFIT_CODE_R
,V_BENEFIT_DESC_R
,N_PAY_DTL_SOURCE_SYSTEM_KEY_R
,N_PAID_CLAIM_BENEFITS_R
,N_TAXABLE_BENEFIT_AMT_R
,N_FEDERAL_TAX_WITHHELD_AMT_R
,N_STATE_TAX_WITHHELD_AMT_R
,N_EMPLOYEE_SS_WITHHELD_AMT_R
,N_EMPLOYEE_MED_WITHHELD_AMT_R
,N_EMPLOYER_SS_WITHHELD_AMT_R
,N_EMPLOYER_MED_WITHHELD_AMT_R
,N_LEGAL_EXPENSE_DIRECT_AMT_R
,N_OTHER_EXPENSE_DIRECT_AMT_R
,V_AMOUNT_TYPE_CATEGORY_R
,V_AMOUNT_TYPE_CATEGORY_DESC_R
,V_AMOUNT_TYPE_SUB_CATEGORY_R
,V_AMT_TYPE_SUB_CATEGORY_DESC_R
,V_AMOUNT_TYPE_CODE_R
,V_AMOUNT_TYPE_NAME_R
,V_AMOUNT_TYPE_SUB_CODE_R
,V_AMOUNT_TYPE_SUB_NAME_R
,F_PHYSICAL_DELETE_R
,V_CHANGE_REASON_R
,D_RECORD_END_DATE_R
,D_RECORD_START_DATE_R
,V_CLAIM_TYPE_R
,N_GROUP_SEQ_R
,N_SOURCE_VERSION_SEQ_NUMBER_R
,V_PRIVACY_INDICATOR_R
,N_VERSION_NUMBER_R
,T_EVENT_TIMESTAMP_R
,V_OFFSET_TYPE_R
--27-SEP-2023 changes starts
,V_PAYEE_FIRST_NAME_R
,V_PAYEE_MIDDLE_NAME_R
,v_payee_last_name_r
,V_PAYEE_TYPE_R
--27-SEP-2023 changes ends
)
select  A1.N_POLICY_SK_R
,A1.N_PARTY_SK_R
,A1.N_CLAIM_SK_R
,A1.N_CLAIM_COVERAGE_SK_R
,A1.N_CLAIM_COVERAGE_GROUP_SK_R
,A1.N_BATCH_ID_R
,LN_LOAD_RUN_ID_R N_LOAD_RUN_ID_R
--,NVL(LN_SEQUENCE_NUMBER_R,0)+ROWNUM N_SEQUENCE_NUMBER_R
,LD_SYSDATE T_CREATION_DATE_R
,LD_SYSDATE T_LAST_MODIFIED_DATE_R
,'PKG_GRP_FULLLOAD_OFFSETS.PRC_FULLLOAD_FCT_CLAIMPMNT_DET_OFFSET2_R' V_CREATED_BY_R
,'PKG_GRP_FULLLOAD_OFFSETS.PRC_FULLLOAD_FCT_CLAIMPMNT_DET_OFFSET2_R' V_LAST_MODIFIED_BY_R
,A1.FIC_MIS_DATE_R
,A1.N_SEQ_R
,A1.D_PAYPERIOD_START_R
,A1.D_PAYPERIOD_END_R
,A1.D_PAYMENTDATE_R
,A1.N_AMOUNT_R
,A1.V_TYPE_R
,A1.N_DEBITAMOUNT_R
,A1.N_CREDITAMOUNT_R
,A1.V_BENEFIT_CODE_R
,A1.V_BENEFIT_DESC_R
,A1.N_PAY_DTL_SOURCE_SYSTEM_KEY_R
,A1.N_PAID_CLAIM_BENEFITS_R
,A1.N_TAXABLE_BENEFIT_AMT_R
,A1.N_FEDERAL_TAX_WITHHELD_AMT_R
,A1.N_STATE_TAX_WITHHELD_AMT_R
,A1.N_EMPLOYEE_SS_WITHHELD_AMT_R
,A1.N_EMPLOYEE_MED_WITHHELD_AMT_R
,A1.N_EMPLOYER_SS_WITHHELD_AMT_R
,A1.N_EMPLOYER_MED_WITHHELD_AMT_R
,A1.N_LEGAL_EXPENSE_DIRECT_AMT_R
,A1.N_OTHER_EXPENSE_DIRECT_AMT_R
,A1.V_AMOUNT_TYPE_CATEGORY_R
,A1.V_AMOUNT_TYPE_CATEGORY_DESC_R
,A1.V_AMOUNT_TYPE_SUB_CATEGORY_R
,A1.V_AMT_TYPE_SUB_CATEGORY_DESC_R
,A1.V_AMOUNT_TYPE_CODE_R
,A1.V_AMOUNT_TYPE_NAME_R
,A1.V_AMOUNT_TYPE_SUB_CODE_R
,A1.V_AMOUNT_TYPE_SUB_NAME_R
,A1.F_PHYSICAL_DELETE_R
,A1.V_CHANGE_REASON_R
,A1.D_RECORD_END_DATE_R
,A1.D_RECORD_START_DATE_R
,A1.V_CLAIM_TYPE_R
,A1.N_GROUP_SEQ_R
,A1.N_SOURCE_VERSION_SEQ_NUMBER_R
,A1.V_PRIVACY_INDICATOR_R
,A1.N_VERSION_NUMBER_R
,A1.T_EVENT_TIMESTAMP_R
,'OFFSET2'
--27-SEP-2023 changes starts
--,A1.N_PARENT_OBJECTNUM_R
--,A1.N_PAY_SCHD_SOURCE_SYSTEM_KEY_R
,PA.V_INDIVIDUAL_FIRST_NAME_R V_PAYEE_FIRST_NAME_R
,PA.V_INDIVIDUAL_MIDDLE_NAME_R V_PAYEE_MIDDLE_NAME_R
,PA.V_INDIVIDUAL_LAST_NAME_R V_PAYEE_LAST_NAME_R
,(case  when PD.V_PAYEE_TYPE_R = 'Agent' then ' UNK ' when PD.V_PAYEE_TYPE_R = 'Beneficiary' then 'UNK' when PD.V_PAYEE_TYPE_R = 'Customer' then 'GRP' when PD.V_PAYEE_TYPE_R = 'Insured' then 'IND' when PD.V_PAYEE_TYPE_R = 'Vendor' then 'PRV' else PD.V_PAYEE_TYPE_R end ) V_PAYEE_TYPE_R
--27-SEP-2023 changes ends
from (
SELECT
N_POLICY_SK_R
,N_PARTY_SK_R
,N_CLAIM_SK_R
,N_CLAIM_COVERAGE_SK_R
,N_CLAIM_COVERAGE_GROUP_SK_R
,N_BATCH_ID_R
,LN_LOAD_RUN_ID_R N_LOAD_RUN_ID_R
--,NVL(LN_SEQUENCE_NUMBER_R,0)+ROWNUM N_SEQUENCE_NUMBER_R
,LD_SYSDATE T_CREATION_DATE_R
,LD_SYSDATE T_LAST_MODIFIED_DATE_R
,'PKG_GRP_FULLLOAD_OFFSETS.PRC_FULLLOAD_FCT_CLAIMPMNT_DET_OFFSET2_R' V_CREATED_BY_R
,'PKG_GRP_FULLLOAD_OFFSETS.PRC_FULLLOAD_FCT_CLAIMPMNT_DET_OFFSET2_R' V_LAST_MODIFIED_BY_R
,FIC_MIS_DATE_R
,N_SEQ_R
,D_PAYPERIOD_START_R
,D_PAYPERIOD_END_R
,D_PAYMENTDATE_R
,N_AMOUNT_R
,V_TYPE_R
,N_DEBITAMOUNT_R
,N_CREDITAMOUNT_R
,V_BENEFIT_CODE_R
,V_BENEFIT_DESC_R
,N_PAY_DTL_SOURCE_SYSTEM_KEY_R
,N_PAID_CLAIM_BENEFITS_R
,N_TAXABLE_BENEFIT_AMT_R
,N_FEDERAL_TAX_WITHHELD_AMT_R
,N_STATE_TAX_WITHHELD_AMT_R
,N_EMPLOYEE_SS_WITHHELD_AMT_R
,N_EMPLOYEE_MED_WITHHELD_AMT_R
,N_EMPLOYER_SS_WITHHELD_AMT_R
,N_EMPLOYER_MED_WITHHELD_AMT_R
,N_LEGAL_EXPENSE_DIRECT_AMT_R
,N_OTHER_EXPENSE_DIRECT_AMT_R
,V_AMOUNT_TYPE_CATEGORY_R
,V_AMOUNT_TYPE_CATEGORY_DESC_R
,V_AMOUNT_TYPE_SUB_CATEGORY_R
,V_AMT_TYPE_SUB_CATEGORY_DESC_R
,V_AMOUNT_TYPE_CODE_R
,V_AMOUNT_TYPE_NAME_R
,V_AMOUNT_TYPE_SUB_CODE_R
,V_AMOUNT_TYPE_SUB_NAME_R
,F_PHYSICAL_DELETE_R
,V_CHANGE_REASON_R
,D_RECORD_END_DATE_R
,D_RECORD_START_DATE_R
,V_CLAIM_TYPE_R
,N_GROUP_SEQ_R
,N_SOURCE_VERSION_SEQ_NUMBER_R
,V_PRIVACY_INDICATOR_R
,N_VERSION_NUMBER_R
,T_EVENT_TIMESTAMP_R
,'OFFSET2'
--27-SEP-2023 changes starts
,N_PARENT_OBJECTNUM_R
,N_PAY_SCHD_SOURCE_SYSTEM_KEY_R
,V_LINK_OBJECTNUM_R
--27-SEP-2023 changes ends
FROM
(select  DISTINCT * from (WITH FBP_1 AS (
select DISTINCT N_PAY_SCHD_SOURCE_SYSTEM_KEY_R,N_SOURCE_VERSION_SEQ_NUMBER_R,N_SEQ_R,V_REFERENCE_R , N_ADJ_NET_BENEFIT_R
--27-SEP-2023 changes starts
,N_PARENT_OBJECTNUM_R
,V_LINK_OBJECTNUM_R
---27-SEP-2023 ends
FROM FCT_BENEFIT_PAYMENT_R
WHERE (UPPER(V_REFERENCE_R) like 'MINIMUM BENEFIT APPLIED%')
--AND N_BATCH_ID_R = LN_IN_BATCH_ID_R -- Commented by Gireesh 06-May-2022 for full load
/*and N_PAY_SCHD_SOURCE_SYSTEM_KEY_R=2107195  and N_SOURCE_VERSION_SEQ_NUMBER_R=1610  and n_seq_r=1 */
)

, FBP_D_2 AS (Select distinct
N_POLICY_SK_R,
N_PARTY_SK_R,
N_CLAIM_SK_R,
N_CLAIM_COVERAGE_SK_R,
N_CLAIM_COVERAGE_GROUP_SK_R,
N_BATCH_ID_R,-- Enabled by Gireesh 06-May-2022 for full load
/* Commented by Gireesh
N_LOAD_RUN_ID_R,
0 AS N_SEQUENCE_NUMBER_R,
T_CREATION_DATE_R,
T_LAST_MODIFIED_DATE_R,
V_CREATED_BY_R,
V_LAST_MODIFIED_BY_R,   */
FIC_MIS_DATE_R,
D_PAYPERIOD_START_R,
D_PAYPERIOD_END_R,
D_PAYMENTDATE_R,
N_AMOUNT_R,
N_PAY_DTL_SOURCE_SYSTEM_KEY_R,
0 AS N_STATE_TAX_WITHHELD_AMT_R,
0 AS N_EMPLOYEE_MED_WITHHELD_AMT_R,
0 AS N_EMPLOYEE_SS_WITHHELD_AMT_R,
0 AS N_EMPLOYER_MED_WITHHELD_AMT_R,
0 AS N_EMPLOYER_SS_WITHHELD_AMT_R,
0 AS N_LEGAL_EXPENSE_DIRECT_AMT_R,
0 AS N_OTHER_EXPENSE_DIRECT_AMT_R,
F_PHYSICAL_DELETE_R,
V_CHANGE_REASON_R,
D_RECORD_END_DATE_R,
D_RECORD_START_DATE_R,
V_CLAIM_TYPE_R ,
N_GROUP_SEQ_R,
N_SOURCE_VERSION_SEQ_NUMBER_R,
V_PRIVACY_INDICATOR_R,
N_VERSION_NUMBER_R,
T_EVENT_TIMESTAMP_R
FROM FCT_BENEFIT_PAYMENT_DETAIL_R
--WHERE N_BATCH_ID_R = LN_IN_BATCH_ID_R -- Commented by Gireesh 06-May-2022 for full load
/*where N_PAY_DTL_SOURCE_SYSTEM_KEY_R= 2107195 and N_SOURCE_VERSION_SEQ_NUMBER_R=1610 and n_seq_r=1*/
)
/*select * from FBP_D_2 order by N_SOURCE_VERSION_SEQ_NUMBER_R,N_GROUP_SEQ_R;-7-;*/


select DISTINCT
FBP_D_2.N_POLICY_SK_R,
FBP_D_2.N_PARTY_SK_R,
FBP_D_2.N_CLAIM_SK_R,
FBP_D_2.N_CLAIM_COVERAGE_SK_R,
FBP_D_2.N_CLAIM_COVERAGE_GROUP_SK_R,
FBP_D_2.N_BATCH_ID_R,-- Enabled by Gireesh 06-May-2022 for full load
/*--Commented by Gireesh 20-Mar-2022
FBP_D_2.N_LOAD_RUN_ID_R,
FBP_D_2.N_SEQUENCE_NUMBER_R,
FBP_D_2.T_CREATION_DATE_R,
FBP_D_2.T_LAST_MODIFIED_DATE_R,
FBP_D_2.V_CREATED_BY_R,
FBP_D_2.V_LAST_MODIFIED_BY_R, */
FBP_D_2.FIC_MIS_DATE_R,
9000 AS N_SEQ_R,
FBP_D_2.D_PAYPERIOD_START_R,
FBP_D_2.D_PAYPERIOD_END_R,
FBP_D_2.D_PAYMENTDATE_R,
FBP_1.N_ADJ_NET_BENEFIT_R as N_AMOUNT_R,
'Post-Tax Benefit' AS V_TYPE_R,
0 AS N_DEBITAMOUNT_R ,
0 AS N_CREDITAMOUNT_R ,
'080' AS V_BENEFIT_CODE_R,
'MINIMUM BENEFIT' AS V_BENEFIT_DESC_R,
FBP_D_2.N_PAY_DTL_SOURCE_SYSTEM_KEY_R,
FBP_1.N_ADJ_NET_BENEFIT_R AS N_PAID_CLAIM_BENEFITS_R,
0 AS N_TAXABLE_BENEFIT_AMT_R,
0 AS N_FEDERAL_TAX_WITHHELD_AMT_R,
FBP_D_2.N_STATE_TAX_WITHHELD_AMT_R,
FBP_D_2.N_EMPLOYEE_MED_WITHHELD_AMT_R,
FBP_D_2.N_EMPLOYEE_SS_WITHHELD_AMT_R,
FBP_D_2.N_EMPLOYER_MED_WITHHELD_AMT_R,
FBP_D_2.N_EMPLOYER_SS_WITHHELD_AMT_R,
FBP_D_2.N_LEGAL_EXPENSE_DIRECT_AMT_R,
FBP_D_2.N_OTHER_EXPENSE_DIRECT_AMT_R,
'BE' AS V_AMOUNT_TYPE_CATEGORY_R,
'BENEFIT' AS V_AMOUNT_TYPE_CATEGORY_DESC_R,
'BENEFIT' AS V_AMOUNT_TYPE_SUB_CATEGORY_R ,
'BENEFIT' AS V_AMT_TYPE_SUB_CATEGORY_DESC_R ,
'080' AS V_AMOUNT_TYPE_CODE_R,
'MINIMUM BENEFIT' AS V_AMOUNT_TYPE_NAME_R,
'080' AS V_AMOUNT_TYPE_SUB_CODE_R ,
'MINIMUM BENEFIT' AS V_AMOUNT_TYPE_SUB_NAME_R ,
FBP_D_2.F_PHYSICAL_DELETE_R,
FBP_D_2.V_CHANGE_REASON_R,
FBP_D_2.D_RECORD_END_DATE_R,
FBP_D_2.D_RECORD_START_DATE_R,
FBP_D_2.V_CLAIM_TYPE_R ,
FBP_D_2.N_GROUP_SEQ_R,
FBP_D_2.N_SOURCE_VERSION_SEQ_NUMBER_R,
FBP_D_2.V_PRIVACY_INDICATOR_R,
FBP_D_2.N_VERSION_NUMBER_R,
FBP_D_2.T_EVENT_TIMESTAMP_R
--27-SEP-2023 changes starts
,FBP_1.N_PARENT_OBJECTNUM_R
,FBP_1.N_PAY_SCHD_SOURCE_SYSTEM_KEY_R
,FBP_1.V_LINK_OBJECTNUM_R
--27-SEP-2023 changes ends
FROM FBP_D_2 INNER JOIN FBP_1
ON FBP_1.N_PAY_SCHD_SOURCE_SYSTEM_KEY_R = TRIM(FBP_D_2.N_PAY_DTL_SOURCE_SYSTEM_KEY_R)
AND FBP_1.N_SOURCE_VERSION_SEQ_NUMBER_R = TRIM(FBP_D_2.N_SOURCE_VERSION_SEQ_NUMBER_R)
AND FBP_1.N_SEQ_R = TRIM(FBP_D_2.N_GROUP_SEQ_R)
--27-SEP-2023 changes starts
--) A
) A)) a1
--,ATOMIC.dim_payment_details pd
,(SELECT * FROM ATOMIC.dim_payment_details pd WHERE PD.V_ACTIVE_STATUS_R = 'Y')PD
,(SELECT * FROM ATOMIC.dim_grp_party_r WHERE v_active_status_r = 'Y') pa
  --,ATOMIC.dim_grp_party_r pa
--where pd.V_PAYMNT_DTLS_SRC_SYS_KEY_R = DGCDR.n_source_system_key_r
where
	 a1.N_PAY_SCHD_SOURCE_SYSTEM_KEY_R = pd.V_PAYMNT_DTLS_SRC_SYS_KEY_R(+)
	 --pd.V_PAYMNT_DTLS_SRC_SYS_KEY_R = a1.N_PAY_SCHD_SOURCE_SYSTEM_KEY_R
     --and pd.v_active_status_r = 'Y'
     --and pd.V_WORKSHEET_OBJECTNUM_R = FBPR.N_WORKSHEET_SEQ_NBR_OBJECTNM_R
     --and pd.V_WORKSHEET_OBJECTNUM_R = a1.N_PARENT_OBJECTNUM_R
	 and a1.N_PARENT_OBJECTNUM_R  = pd.V_WORKSHEET_OBJECTNUM_R(+)
	 AND NVL(a1.V_LINK_OBJECTNUM_R,0)=PD.V_PAYMNT_DTLS_SEQ_NBR_R(+)
     and pd.N_INSRD_PARTY_SK_R = pa.n_party_sk_r(+)
     --and pa.v_active_status_r = 'Y'
     --AND PD.V_PAYMNT_DTLS_SEQ_NBR_R = (SELECT MAX(B.V_PAYMNT_DTLS_SEQ_NBR_R)
     --                            from dim_payment_details b
     --                            where b.V_PAYMNT_DTLS_SRC_SYS_KEY_R = pd.V_PAYMNT_DTLS_SRC_SYS_KEY_R
     --                            and b.V_WORKSHEET_OBJECTNUM_R = pd.V_WORKSHEET_OBJECTNUM_R
     --                            and b.v_active_status_r = 'Y')
--27-SEP-2023 changes ends
/*WHERE NOT EXISTS (
SELECT 1 FROM FCT_CLAIM_PAYMENT_DETAIL_OFFSETS_R B
WHERE
B.N_PAY_DTL_SOURCE_SYSTEM_KEY_R                =A.N_PAY_DTL_SOURCE_SYSTEM_KEY_R
AND B.N_VERSION_NUMBER_R                       =A.N_VERSION_NUMBER_R
AND B.N_SOURCE_VERSION_SEQ_NUMBER_R            =A.N_SOURCE_VERSION_SEQ_NUMBER_R
AND B.N_SEQ_R                                  =A.N_SEQ_R
AND B.V_AMOUNT_TYPE_NAME_R                     =A.V_AMOUNT_TYPE_NAME_R
AND B.V_AMOUNT_TYPE_NAME_R = ('MINIMUM BENEFIT')
AND B.N_SEQ_R='9000'
)*/
;
--where FBP_D_1.N_PAY_DTL_SOURCE_SYSTEM_KEY_R=11386783 and FBP_D_1.N_SOURCE_VERSION_SEQ_NUMBER_R=366 and FBP_D_1.n_seq_r=1;
COMMIT;


gc_trcmsg:='5.Completed data insertion into FCT_CLAIM_PAYMENT_DETAIL_OFFSETS_R';
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
						p_job_id_r            			=> gn_out_job_id,
						p_batch_id_r                  	=> gn_sysdt_batchid,
						p_message_type_r              	=> lv_message_type_r,
						p_code_location_r             	=> gc_main_loadedby,
						p_message_r                   	=> gc_trcmsg,
						p_count_type_r                	=> NULL,
						p_count_r                     	=> NULL,
						p_duration_r                  	=> NULL,
						p_created_by_r                	=> GC_JOB_NAME,
						out_prcs_job_log_message_id_r 	=> gn_job_log_message_id_r
						);


		gc_trcmsg:='1. Exit from PRC_FULLLOAD_FCT_CLAIMPMNT_DET_OFFSET2_R ';
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
						p_job_id_r            			=> gn_out_job_id,
						p_batch_id_r                  	=> gn_sysdt_batchid,
						p_message_type_r              	=> lv_message_type_r,
						p_code_location_r             	=> gc_main_loadedby,
						p_message_r                   	=> gc_trcmsg,
						p_count_type_r                	=> NULL,
						p_count_r                     	=> NULL,
						p_duration_r                  	=> NULL,
						p_created_by_r                	=> GC_JOB_NAME,
						out_prcs_job_log_message_id_r 	=> gn_job_log_message_id_r
						);

			pkg_grp_log_util.prc_update_log(
      						gn_out_job_id                   --p_job_id
							,gc_success_status              --p_job_status
							,gc_errmsg                      --p_err_msg
							,gc_trcmsg                      --p_trc_msg
							,gc_main_loadedby               --p_log_util_called_by_r
							);	


OUT_LOAD_STATUS:='SUCCESS';
EXCEPTION
WHEN OTHERS THEN
LC_SQLCODE:=SQLCODE;
LC_SQLERRM:=SUBSTR(SQLERRM,1,4000);
OUT_LOAD_STATUS:=LC_SQLCODE||'-'||LC_SQLERRM;
DBMS_OUTPUT.PUT_LINE('PRC_FULLLOAD_FCT_CLAIMPMNT_DET_OFFSET2_R  EXCEPTION WITH ERROR CODE AS '
             || SQLCODE
             || ' '
             || SQLERRM
             || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
             ||'PRC_FULLLOAD_FCT_CLAIMPMNT_DET_OFFSET2_R'
             ||';');

         /*START: NEW LOGGING MECHANISM CHANGES*/    
    pkg_grp_log_util.prc_update_log_message_r
			( 
			n_prcs_job_log_message_id_r => gn_job_log_message_id_r,
			p_err_msg 					=> gc_trcmsg 
				);
	     /*END: NEW LOGGING MECHANISM CHANGES*/     

	pkg_grp_log_util.prc_update_log
      (
        gn_out_job_id                   	--p_job_id
        ,gc_error_status                	--p_job_status
        ,gc_errmsg                       	--p_err_msg
        ,gc_trcmsg					     	--p_trc_msg
        ,gc_main_loadedby               	--p_log_util_called_by_r
    );			 

	RAISE_APPLICATION_ERROR(-20001,'Error in PKG_GRP_FULLLOAD_OFFSETS.PRC_FULLLOAD_FCT_CLAIMPMNT_DET_OFFSET2_R:->
    Error Code:'||LC_SQLCODE||',Error message:'||LC_SQLERRM);		 

END PRC_FULLLOAD_FCT_CLAIMPMNT_DET_OFFSET2_R;

PROCEDURE PRC_FULLLOAD_FCT_CLAIMPMNT_DET_OFFSET3_R(
   -- IN_BATCH_ID_R        IN NUMBER,
    OUT_LOAD_STATUS      OUT VARCHAR2
    )
IS
LD_SYSDATE DATE :=SYSDATE;
LC_SQLCODE VARCHAR2(4000);
LC_SQLERRM VARCHAR2(4000);
LN_SEQUENCE_NUMBER_R NUMBER;
--LN_IN_BATCH_ID_R NUMBER:=IN_BATCH_ID_R;
LN_LOAD_RUN_ID_R NUMBER:=1;
lv_message_type_r  PRCS_JOB_LOG_MESSAGE_R.v_message_type_r%TYPE:= PKG_GRP_LOG_UTIL.gc_message_type_info;
BEGIN

	/*IF LN_IN_BATCH_ID_R IS NULL THEN
	  OUT_LOAD_STATUS:='a) BatchID(IN_BATCH_ID) is null hence terminating the program';
	 RAISE_APPLICATION_ERROR(-20001,'a) BatchID(IN_BATCH_ID) is null hence terminating the program');
	END IF;*/

/*SELECT   MAX(N_SEQUENCE_NUMBER_R)
      INTO LN_SEQUENCE_NUMBER_R
FROM FCT_BENEFIT_PAYMENT_DETAIL_R;*/

/*SELECT   COUNT(1)
      INTO ln_load_run_id_r
FROM PRCS_JOB_LOG_R
WHERE N_BATCH_ID_R =IN_BATCH_ID_R
AND V_JOB_NAME_R='GRP_FULLLOAD_FCT_CLAIMPMNT_DET_OFFSET3_R';*/

--C) Delete Offset3 data in FCT_BENEFIT_PAYMENT_DETAIL_R
  -- DELETE  from FCT_CLAIM_PAYMENT_DETAIL_OFFSETS_R
  -- WHERE V_OFFSET_TYPE_R='OFFSET3'
  -- ;
  -- COMMIT;


	gc_main_loadedby :='PKG_GRP_FULLLOAD_OFFSETS.PRC_FULLLOAD_FCT_CLAIMPMNT_DET_OFFSET3_R';

    pkg_grp_log_util.prc_insert_log
                       ( p_source              			=> gc_source
					    ,p_job_nm              			=> gc_job_name
                        ,p_job_status          			=> gc_running_status
                        ,p_err_msg             			=> null
                        ,p_trc_msg             			=> null
                        ,p_n_batch_id          			=> gn_sysdt_batchid
                        ,p_log_util_called_by_r			=> gc_main_loadedby
						,out_job_id            			=> gn_out_job_id
						);

				gc_trcmsg:='1. Entered into PRC_FULLLOAD_FCT_CLAIMPMNT_DET_OFFSET3_R ';



		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
						p_job_id_r            			=> gn_out_job_id,
						p_batch_id_r                  	=> gn_sysdt_batchid,
						p_message_type_r              	=> lv_message_type_r,
						p_code_location_r             	=> gc_main_loadedby,
						p_message_r                   	=> gc_trcmsg,
						p_count_type_r                	=> NULL,
						p_count_r                     	=> NULL,
						p_duration_r                  	=> NULL,
						p_created_by_r                	=> GC_JOB_NAME,
						out_prcs_job_log_message_id_r 	=> gn_job_log_message_id_r
						);

		gc_trcmsg:='2. Started Truncation Partition for partition name OFFSET3 for procedure PRC_FULLLOAD_FCT_CLAIMPMNT_DET_OFFSET3_R for  table FCT_CLAIM_PAYMENT_DETAIL_OFFSETS_R';
      PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
						p_job_id_r            			=> gn_out_job_id,
						p_batch_id_r                  	=> gn_sysdt_batchid,
						p_message_type_r              	=> lv_message_type_r,
						p_code_location_r             	=> gc_main_loadedby,
						p_message_r                   	=> gc_trcmsg,
						p_count_type_r                	=> NULL,
						p_count_r                     	=> NULL,
						p_duration_r                  	=> NULL,
						p_created_by_r                	=> GC_JOB_NAME,
						out_prcs_job_log_message_id_r 	=> gn_job_log_message_id_r
						);


  proc_truncate_partition('FCT_CLAIM_PAYMENT_DETAIL_OFFSETS_R','OFFSET3',TO_NUMBER(TO_CHAR(SYSDATE,'YYYYMMDD')));


  gc_trcmsg:='3. Completed Truncation Partition for partition OFFSET3 for procedure PRC_FULLLOAD_FCT_CLAIMPMNT_DET_OFFSET3_R for  table FCT_CLAIM_PAYMENT_DETAIL_OFFSETS_R';
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
						p_job_id_r            			=> gn_out_job_id,
						p_batch_id_r                  	=> gn_sysdt_batchid,
						p_message_type_r              	=> lv_message_type_r,
						p_code_location_r             	=> gc_main_loadedby,
						p_message_r                   	=> gc_trcmsg,
						p_count_type_r                	=> NULL,
						p_count_r                     	=> NULL,
						p_duration_r                  	=> NULL,
						p_created_by_r                	=> GC_JOB_NAME,
						out_prcs_job_log_message_id_r 	=> gn_job_log_message_id_r
						);


				gc_trcmsg:='4.Started data to insert into FCT_CLAIM_PAYMENT_DETAIL_OFFSETS_R';
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
						p_job_id_r            			=> gn_out_job_id,
						p_batch_id_r                  	=> gn_sysdt_batchid,
						p_message_type_r              	=> lv_message_type_r,
						p_code_location_r             	=> gc_main_loadedby,
						p_message_r                   	=> gc_trcmsg,
						p_count_type_r                	=> NULL,
						p_count_r                     	=> NULL,
						p_duration_r                  	=> NULL,
						p_created_by_r                	=> GC_JOB_NAME,
						out_prcs_job_log_message_id_r 	=> gn_job_log_message_id_r
						);	


INSERT /*+APPEND*/ INTO FCT_CLAIM_PAYMENT_DETAIL_OFFSETS_R
(
N_POLICY_SK_R
,N_PARTY_SK_R
,N_CLAIM_SK_R
,N_CLAIM_COVERAGE_SK_R
,N_CLAIM_COVERAGE_GROUP_SK_R
,N_BATCH_ID_R
,N_LOAD_RUN_ID_R
--,N_SEQUENCE_NUMBER_R
,T_CREATION_DATE_R
,T_LAST_MODIFIED_DATE_R
,V_CREATED_BY_R
,V_LAST_MODIFIED_BY_R
,FIC_MIS_DATE_R
,N_SEQ_R
,D_PAYPERIOD_START_R
,D_PAYPERIOD_END_R
,D_PAYMENTDATE_R
,N_AMOUNT_R
,V_TYPE_R
,N_DEBITAMOUNT_R
,N_CREDITAMOUNT_R
,V_BENEFIT_CODE_R
,V_BENEFIT_DESC_R
,N_PAY_DTL_SOURCE_SYSTEM_KEY_R
,N_PAID_CLAIM_BENEFITS_R
,N_TAXABLE_BENEFIT_AMT_R
,N_FEDERAL_TAX_WITHHELD_AMT_R
,N_STATE_TAX_WITHHELD_AMT_R
,N_EMPLOYEE_SS_WITHHELD_AMT_R
,N_EMPLOYEE_MED_WITHHELD_AMT_R
,N_EMPLOYER_SS_WITHHELD_AMT_R
,N_EMPLOYER_MED_WITHHELD_AMT_R
,N_LEGAL_EXPENSE_DIRECT_AMT_R
,N_OTHER_EXPENSE_DIRECT_AMT_R
,V_AMOUNT_TYPE_CATEGORY_R
,V_AMOUNT_TYPE_CATEGORY_DESC_R
,V_AMOUNT_TYPE_SUB_CATEGORY_R
,V_AMT_TYPE_SUB_CATEGORY_DESC_R
,V_AMOUNT_TYPE_CODE_R
,V_AMOUNT_TYPE_NAME_R
,V_AMOUNT_TYPE_SUB_CODE_R
,V_AMOUNT_TYPE_SUB_NAME_R
,F_PHYSICAL_DELETE_R
,V_CHANGE_REASON_R
,D_RECORD_END_DATE_R
,D_RECORD_START_DATE_R
,V_CLAIM_TYPE_R
,N_GROUP_SEQ_R
,N_SOURCE_VERSION_SEQ_NUMBER_R
,V_PRIVACY_INDICATOR_R
,N_VERSION_NUMBER_R
,T_EVENT_TIMESTAMP_R
,V_OFFSET_TYPE_R
 --27-SEP-2023 changes starts
,V_PAYEE_FIRST_NAME_R
,V_PAYEE_MIDDLE_NAME_R
,v_payee_last_name_r
,V_PAYEE_TYPE_R
 --27-SEP-2023 changes ends
)
 --27-SEP-2023 changes starts
select
a1.N_POLICY_SK_R
,a1.N_PARTY_SK_R
,a1.N_CLAIM_SK_R
,a1.N_CLAIM_COVERAGE_SK_R
,a1.N_CLAIM_COVERAGE_GROUP_SK_R
,a1.N_BATCH_ID_R
,a1.N_LOAD_RUN_ID_R
--,a1.N_SEQUENCE_NUMBER_R
,a1.T_CREATION_DATE_R
,a1.T_LAST_MODIFIED_DATE_R
,a1.V_CREATED_BY_R
,a1.V_LAST_MODIFIED_BY_R
,a1.FIC_MIS_DATE_R
,a1.N_SEQ_R
,a1.D_PAYPERIOD_START_R
,a1.D_PAYPERIOD_END_R
,a1.D_PAYMENTDATE_R
,a1.N_AMOUNT_R
,a1.V_TYPE_R
,a1.N_DEBITAMOUNT_R
,a1.N_CREDITAMOUNT_R
,a1.V_BENEFIT_CODE_R
,a1.V_BENEFIT_DESC_R
,a1.N_PAY_DTL_SOURCE_SYSTEM_KEY_R
,a1.N_PAID_CLAIM_BENEFITS_R
,a1.N_TAXABLE_BENEFIT_AMT_R
,a1.N_FEDERAL_TAX_WITHHELD_AMT_R
,a1.N_STATE_TAX_WITHHELD_AMT_R
,a1.N_EMPLOYEE_SS_WITHHELD_AMT_R
,a1.N_EMPLOYEE_MED_WITHHELD_AMT_R
,a1.N_EMPLOYER_SS_WITHHELD_AMT_R
,a1.N_EMPLOYER_MED_WITHHELD_AMT_R
,a1.N_LEGAL_EXPENSE_DIRECT_AMT_R
,a1.N_OTHER_EXPENSE_DIRECT_AMT_R
,a1.V_AMOUNT_TYPE_CATEGORY_R
,a1.V_AMOUNT_TYPE_CATEGORY_DESC_R
,a1.V_AMOUNT_TYPE_SUB_CATEGORY_R
,a1.V_AMT_TYPE_SUB_CATEGORY_DESC_R
,a1.V_AMOUNT_TYPE_CODE_R
,a1.V_AMOUNT_TYPE_NAME_R
,a1.V_AMOUNT_TYPE_SUB_CODE_R
,a1.V_AMOUNT_TYPE_SUB_NAME_R
,a1.F_PHYSICAL_DELETE_R
,a1.V_CHANGE_REASON_R
,a1.D_RECORD_END_DATE_R
,a1.D_RECORD_START_DATE_R
,a1.V_CLAIM_TYPE_R
,a1.N_GROUP_SEQ_R
,a1.N_SOURCE_VERSION_SEQ_NUMBER_R
,a1.V_PRIVACY_INDICATOR_R
,a1.N_VERSION_NUMBER_R
,A1.T_EVENT_TIMESTAMP_R
,a1.V_OFFSET_TYPE_R
--27-SEP-2023 CHANGES STARTS
,PA.V_INDIVIDUAL_FIRST_NAME_R  V_PAYEE_FIRST_NAME_R
,PA.V_INDIVIDUAL_MIDDLE_NAME_R V_PAYEE_MIDDLE_NAME_R
,pa.V_INDIVIDUAL_LAST_NAME_R   v_payee_last_name_r
,(case  when PD.V_PAYEE_TYPE_R = 'Agent' then ' UNK ' when PD.V_PAYEE_TYPE_R = 'Beneficiary' then 'UNK' when PD.V_PAYEE_TYPE_R = 'Customer' then 'GRP' when PD.V_PAYEE_TYPE_R = 'Insured' then 'IND' when PD.V_PAYEE_TYPE_R = 'Vendor' then 'PRV' else PD.V_PAYEE_TYPE_R end ) V_PAYEE_TYPE_R
 --27-SEP-2023 changes ends
from (
SELECT
N_POLICY_SK_R
,N_PARTY_SK_R
,N_CLAIM_SK_R
,N_CLAIM_COVERAGE_SK_R
,N_CLAIM_COVERAGE_GROUP_SK_R
,N_BATCH_ID_R
,LN_LOAD_RUN_ID_R N_LOAD_RUN_ID_R
--,NVL(LN_SEQUENCE_NUMBER_R,0)+ROWNUM N_SEQUENCE_NUMBER_R
,LD_SYSDATE T_CREATION_DATE_R
,LD_SYSDATE T_LAST_MODIFIED_DATE_R
,'PKG_GRP_FULLLOAD_OFFSETS.PRC_FULLLOAD_FCT_CLAIMPMNT_DET_OFFSET3_R' V_CREATED_BY_R--27-SEP-2023 CHANGES
,'PKG_GRP_FULLLOAD_OFFSETS.PRC_FULLLOAD_FCT_CLAIMPMNT_DET_OFFSET3_R' V_LAST_MODIFIED_BY_R--27-SEP-2023 CHANGES
,FIC_MIS_DATE_R
,N_SEQ_R
,D_PAYPERIOD_START_R
,D_PAYPERIOD_END_R
,D_PAYMENTDATE_R
,N_AMOUNT_R
,V_TYPE_R
,N_DEBITAMOUNT_R
,N_CREDITAMOUNT_R
,V_BENEFIT_CODE_R
,V_BENEFIT_DESC_R
,N_PAY_DTL_SOURCE_SYSTEM_KEY_R
,N_PAID_CLAIM_BENEFITS_R
,N_TAXABLE_BENEFIT_AMT_R
,N_FEDERAL_TAX_WITHHELD_AMT_R
,N_STATE_TAX_WITHHELD_AMT_R
,N_EMPLOYEE_SS_WITHHELD_AMT_R
,N_EMPLOYEE_MED_WITHHELD_AMT_R
,N_EMPLOYER_SS_WITHHELD_AMT_R
,N_EMPLOYER_MED_WITHHELD_AMT_R
,N_LEGAL_EXPENSE_DIRECT_AMT_R
,N_OTHER_EXPENSE_DIRECT_AMT_R
,V_AMOUNT_TYPE_CATEGORY_R
,V_AMOUNT_TYPE_CATEGORY_DESC_R
,V_AMOUNT_TYPE_SUB_CATEGORY_R
,V_AMT_TYPE_SUB_CATEGORY_DESC_R
,V_AMOUNT_TYPE_CODE_R
,V_AMOUNT_TYPE_NAME_R
,V_AMOUNT_TYPE_SUB_CODE_R
,V_AMOUNT_TYPE_SUB_NAME_R
,F_PHYSICAL_DELETE_R
,V_CHANGE_REASON_R
,D_RECORD_END_DATE_R
,D_RECORD_START_DATE_R
,V_CLAIM_TYPE_R
,N_GROUP_SEQ_R
,N_SOURCE_VERSION_SEQ_NUMBER_R
,V_PRIVACY_INDICATOR_R
,N_VERSION_NUMBER_R
,T_EVENT_TIMESTAMP_R
,'OFFSET3' V_OFFSET_TYPE_R--27-SEP-2023 CHANGES
,N_WORKSHEET_SEQ_NBR_OBJECTNM_R--27-SEP-2023 CHANGES
,N_SOURCE_SYSTEM_KEY_R--27-SEP-2023 CHANGES
,V_LINK_OBJECTNUM_R--27-SEP-2023 CHANGES
FROM
(select  DISTINCT * from (WITH FBP_1 AS (
select DISTINCT N_PAY_SCHD_SOURCE_SYSTEM_KEY_R,N_SOURCE_VERSION_SEQ_NUMBER_R,N_SEQ_R,V_REFERENCE_R
FROM FCT_BENEFIT_PAYMENT_R
WHERE (UPPER(V_REFERENCE_R) like 'MINIMUM BENEFIT APPLIED%' and V_PAY_DESCR_R = 'ALLSOURCE'
--AND N_BATCH_ID_R = LN_IN_BATCH_ID_R --Added by Gireesh for Incremental load
)
--AND N_BATCH_ID_R = 202109190000 -- Added by Gireesh 17mar
--and n_claim_sk_r = 168169
)
--select * from FBP_1);
, FBP_D_1 AS ( Select * FROM FCT_BENEFIT_PAYMENT_DETAIL_R
--WHERE N_BATCH_ID_R = 202109190000 -- Added by Gireesh 17mar
--where V_BENEFIT_CODE_R != '382'
where N_SEQ_R != 9001 and N_SEQ_R != 9000
--and n_claim_sk_r = 168169
--AND N_BATCH_ID_R = LN_IN_BATCH_ID_R --Added by Gireesh for Incremental load
)
--select * from FBP_D_1);--COMMENTED BY GIREESH
, AMT_1 AS (
SELECT TRIM(FBP_D_1.N_PAY_DTL_SOURCE_SYSTEM_KEY_R) N_PAY_DTL_SOURCE_SYSTEM_KEY_R,
TRIM(FBP_D_1.N_SOURCE_VERSION_SEQ_NUMBER_R) N_SOURCE_VERSION_SEQ_NUMBER_R,
TRIM(FBP_D_1.N_GROUP_SEQ_R) N_GROUP_SEQ_R,
Sum(FBP_D_1.N_Amount_R) S_N_Amount_R
FROM FBP_D_1 JOIN FBP_1
ON FBP_1.N_PAY_SCHD_SOURCE_SYSTEM_KEY_R = TRIM(FBP_D_1.N_PAY_DTL_SOURCE_SYSTEM_KEY_R)
AND FBP_1.N_SOURCE_VERSION_SEQ_NUMBER_R = TRIM(FBP_D_1.N_SOURCE_VERSION_SEQ_NUMBER_R)
AND FBP_1.N_SEQ_R = TRIM(FBP_D_1.N_GROUP_SEQ_R)
where FBP_D_1.V_BENEFIT_CODE_R in ('402','COL')
--and n_claim_sk_r = 168169
Or (UPPER(FBP_D_1.V_TYPE_R) = 'ADJUSTMENT' and UPPER(FBP_D_1.V_BENEFIT_CODE_R) like 'GENERAL%')
Or UPPER(FBP_D_1.V_TYPE_R) in ('OFFSET', 'PAYMENT INTERRUPTION')
group by TRIM(FBP_D_1.N_PAY_DTL_SOURCE_SYSTEM_KEY_R),TRIM(FBP_D_1.N_SOURCE_VERSION_SEQ_NUMBER_R),TRIM(FBP_D_1.N_GROUP_SEQ_R)
)
--select * from AMT_1);
, FBP_2 AS (
select DISTINCT N_PAY_SCHD_SOURCE_SYSTEM_KEY_R,N_SOURCE_VERSION_SEQ_NUMBER_R,N_SEQ_R,N_PARENT_OBJECTNUM_R,V_REFERENCE_R,
V_PAY_STATUS_R ,N_ADJ_NET_BENEFIT_R, N_GROSS_BENEFIT_R, N_PRIMARY_PAYEE_R,V_CHECK_NUM_R, D_TRANS_DATE_R, N_ADJ_GROSS_BENEFIT_R,V_LINK_OBJECTNUM_R---27-SEP-2023
FROM FCT_BENEFIT_PAYMENT_R
WHERE (UPPER(V_REFERENCE_R) like 'MINIMUM BENEFIT APPLIED%'  AND V_PAY_DESCR_R = 'ALLSOURCE')
and UPPER(V_PAY_STATUS_R) in ('RELEASED','REVERSED','REVERSAL')
--AND N_BATCH_ID_R = LN_IN_BATCH_ID_R --Added by Gireesh for Incremental load
--and n_claim_sk_r = 168169
--AND N_BATCH_ID_R = 202109190000 -- Added by Gireesh 17mar
)
--select * from FBP_2);--Commented by Gireesh on 13-Nov-2022
,FWS AS (Select distinct n_worksheet_seq_nbr_objectnm_r,n_source_system_key_r,n_spec_benefit_adjust_r,n_gross_benefit_r
FROM FCT_GRP_WORKSHEET
)
,AMT_2 AS (
SELECT FBP_2.N_PAY_SCHD_SOURCE_SYSTEM_KEY_R,FBP_2.N_SOURCE_VERSION_SEQ_NUMBER_R,FBP_2.N_SEQ_R,fbp_2.v_pay_status_r,
FBP_2.N_ADJ_NET_BENEFIT_R,
FWS.n_spec_benefit_adjust_r,FWS.n_gross_benefit_r, V_CHECK_NUM_R, D_TRANS_DATE_R,
fws.N_WORKSHEET_SEQ_NBR_OBJECTNM_R,--27-SEP-2023
FWS.N_SOURCE_SYSTEM_KEY_R,--27-SEP-2023
FBP_2.V_LINK_OBJECTNUM_R,---27-SEP-2023
/*CASE WHEN UPPER(fbp_2.V_PAY_STATUS_R) in ('RELEASED','REVERSED')
     THEN (CASE WHEN FWS.n_spec_benefit_adjust_r > 0 THEN FWS.n_spec_benefit_adjust_r ELSE FWS.n_gross_benefit_r END )
      WHEN  fbp_2.V_PAY_STATUS_R = 'REVERSAL'
      THEN( CASE WHEN FWS.n_spec_benefit_adjust_r > 0 THEN  FWS.n_spec_benefit_adjust_r  ELSE  FWS.n_gross_benefit_r * -1 END)
      ELSE 0 END AS FWS_AMT*/
CASE WHEN UPPER(fbp_2.V_PAY_STATUS_R) in ('RELEASED','REVERSED','REVERSAL') and N_PRIMARY_PAYEE_R = 1
      THEN FBP_2.N_ADJ_GROSS_BENEFIT_R
      WHEN UPPER(fbp_2.V_PAY_STATUS_R) in ('RELEASED','REVERSED') and N_PRIMARY_PAYEE_R = 0
      THEN  (CASE WHEN FWS.n_spec_benefit_adjust_r > 0 THEN FWS.n_spec_benefit_adjust_r ELSE FWS.n_gross_benefit_r END )
      WHEN  fbp_2.V_PAY_STATUS_R = 'REVERSAL' and N_PRIMARY_PAYEE_R = 0
      THEN( CASE WHEN FWS.n_spec_benefit_adjust_r > 0 THEN  FWS.n_spec_benefit_adjust_r  ELSE  FWS.n_gross_benefit_r * -1 END)
      ELSE 0 END AS FWS_AMT
FROM FWS Join FBP_2
ON TRIM(FWS.n_worksheet_seq_nbr_objectnm_r) = TRIM(FBP_2.N_PARENT_OBJECTNUM_R)
AND TRIM(FWS.n_source_system_key_r) = TRIM(FBP_2.N_PAY_SCHD_SOURCE_SYSTEM_KEY_R)
)
, FBP_D_2 AS (Select distinct
N_POLICY_SK_R,
N_PARTY_SK_R,
N_CLAIM_SK_R,
N_CLAIM_COVERAGE_SK_R,
N_CLAIM_COVERAGE_GROUP_SK_R,
N_BATCH_ID_R,--enabled for full load by Gireesh 13-Nov-2022
/* Commented by Gireesh
N_LOAD_RUN_ID_R,
0 AS N_SEQUENCE_NUMBER_R,
T_CREATION_DATE_R,
T_LAST_MODIFIED_DATE_R,
V_CREATED_BY_R,
V_LAST_MODIFIED_BY_R, */
FIC_MIS_DATE_R,
D_PAYPERIOD_START_R,
D_PAYPERIOD_END_R,
D_PAYMENTDATE_R,
N_PAY_DTL_SOURCE_SYSTEM_KEY_R,
0 AS N_STATE_TAX_WITHHELD_AMT_R,
0 AS N_EMPLOYEE_MED_WITHHELD_AMT_R,
0 AS N_EMPLOYEE_SS_WITHHELD_AMT_R,
0 AS N_EMPLOYER_MED_WITHHELD_AMT_R,
0 AS N_EMPLOYER_SS_WITHHELD_AMT_R,
0 AS N_LEGAL_EXPENSE_DIRECT_AMT_R,
0 AS N_OTHER_EXPENSE_DIRECT_AMT_R,
F_PHYSICAL_DELETE_R,
V_CHANGE_REASON_R,
D_RECORD_END_DATE_R,
D_RECORD_START_DATE_R,
V_CLAIM_TYPE_R ,
N_GROUP_SEQ_R,
N_SOURCE_VERSION_SEQ_NUMBER_R,
V_BENEFIT_CODE_R,
V_TYPE_R,
V_PRIVACY_INDICATOR_R,
N_VERSION_NUMBER_R,
T_EVENT_TIMESTAMP_R
FROM FCT_BENEFIT_PAYMENT_DETAIL_R
--where V_BENEFIT_CODE_R != '382'
where N_SEQ_R != 9000 and N_SEQ_R != 9001
--and n_claim_sk_r = 168169
--WHERE N_BATCH_ID_R = 202109190000 -- Added by Gireesh 17mar
--AND N_BATCH_ID_R = LN_IN_BATCH_ID_R --Added by Gireesh for Incremental load
)
select DISTINCT
FBP_D_2.N_POLICY_SK_R,
FBP_D_2.N_PARTY_SK_R,
FBP_D_2.N_CLAIM_SK_R,
FBP_D_2.N_CLAIM_COVERAGE_SK_R,
FBP_D_2.N_CLAIM_COVERAGE_GROUP_SK_R,
AMT_2.V_CHECK_NUM_R,
AMT_2.D_TRANS_DATE_R,
FBP_D_2.N_BATCH_ID_R,--enabled for full load by Gireesh 13-Nov-2022
/*--Commented by Gireesh 20-Mar-2022
FBP_D_2.N_LOAD_RUN_ID_R,
FBP_D_2.N_SEQUENCE_NUMBER_R,
FBP_D_2.T_CREATION_DATE_R,
FBP_D_2.T_LAST_MODIFIED_DATE_R,
FBP_D_2.V_CREATED_BY_R,
FBP_D_2.V_LAST_MODIFIED_BY_R,
*/
FBP_D_2.FIC_MIS_DATE_R,
9001 AS N_SEQ_R,
FBP_D_2.D_PAYPERIOD_START_R,
FBP_D_2.D_PAYPERIOD_END_R,
FBP_D_2.D_PAYMENTDATE_R,
CASE WHEN (NVL(AMT_1.S_N_Amount_R,0) +  NVL(AMT_2.FWS_AMT,0) !=AMT_2.N_ADJ_NET_BENEFIT_R) AND NVL(AMT_1.S_N_Amount_R,0) +  NVL(AMT_2.FWS_AMT,0) <> 0  THEN (nvl(AMT_1.S_N_Amount_R,0) +  NVL(AMT_2.FWS_AMT,0))*-1  ELSE 0 END
 AS N_AMOUNT_R,
'Offset' AS V_TYPE_R,
0 AS N_DEBITAMOUNT_R ,
0 AS N_CREDITAMOUNT_R ,
'382' AS V_BENEFIT_CODE_R,
'ALLSOURCE EXCESS OFFSET' AS V_BENEFIT_DESC_R,
FBP_D_2.N_PAY_DTL_SOURCE_SYSTEM_KEY_R,
CASE WHEN (NVL(AMT_1.S_N_Amount_R,0) +  NVL(AMT_2.FWS_AMT,0) !=AMT_2.N_ADJ_NET_BENEFIT_R) AND NVL(AMT_1.S_N_Amount_R,0) +  NVL(AMT_2.FWS_AMT,0) <> 0  THEN (nvl(AMT_1.S_N_Amount_R,0) +  NVL(AMT_2.FWS_AMT,0))*-1  ELSE 0 END
 AS N_PAID_CLAIM_BENEFITS_R,
0 AS N_TAXABLE_BENEFIT_AMT_R,
0 AS N_FEDERAL_TAX_WITHHELD_AMT_R,
FBP_D_2.N_STATE_TAX_WITHHELD_AMT_R,
FBP_D_2.N_EMPLOYEE_MED_WITHHELD_AMT_R,
FBP_D_2.N_EMPLOYEE_SS_WITHHELD_AMT_R,
FBP_D_2.N_EMPLOYER_MED_WITHHELD_AMT_R,
FBP_D_2.N_EMPLOYER_SS_WITHHELD_AMT_R,
FBP_D_2.N_LEGAL_EXPENSE_DIRECT_AMT_R,
FBP_D_2.N_OTHER_EXPENSE_DIRECT_AMT_R,
'OF' AS V_AMOUNT_TYPE_CATEGORY_R,
'OFFSETS' AS V_AMOUNT_TYPE_CATEGORY_DESC_R,
'OFFSETS' AS V_AMOUNT_TYPE_SUB_CATEGORY_R ,
'OFFSETS' AS V_AMT_TYPE_SUB_CATEGORY_DESC_R ,
'382' AS V_AMOUNT_TYPE_CODE_R,
'ALLSOURCE EXCESS OFFSET' AS V_AMOUNT_TYPE_NAME_R,
'382' AS V_AMOUNT_TYPE_SUB_CODE_R ,
'ALLSOURCE EXCESS OFFSET' AS V_AMOUNT_TYPE_SUB_NAME_R ,
FBP_D_2.F_PHYSICAL_DELETE_R,
FBP_D_2.V_CHANGE_REASON_R,
FBP_D_2.D_RECORD_END_DATE_R,
FBP_D_2.D_RECORD_START_DATE_R,
FBP_D_2.V_CLAIM_TYPE_R ,
FBP_D_2.N_GROUP_SEQ_R,
FBP_D_2.N_SOURCE_VERSION_SEQ_NUMBER_R,
FBP_D_2.V_PRIVACY_INDICATOR_R,
FBP_D_2.N_VERSION_NUMBER_R,
FBP_D_2.T_EVENT_TIMESTAMP_R
,amt_2.N_WORKSHEET_SEQ_NBR_OBJECTNM_R,--27-SEP-2023
AMT_2.N_SOURCE_SYSTEM_KEY_R--27-SEP-2023
,amt_2.V_LINK_OBJECTNUM_R--27-SEP-2023
FROM FBP_D_2 LEFT JOIN AMT_1
ON FBP_D_2.N_PAY_DTL_SOURCE_SYSTEM_KEY_R= AMT_1.N_PAY_DTL_SOURCE_SYSTEM_KEY_R
AND FBP_D_2.N_SOURCE_VERSION_SEQ_NUMBER_R= AMT_1.N_SOURCE_VERSION_SEQ_NUMBER_R
AND FBP_D_2.N_GROUP_SEQ_R=AMT_1.N_GROUP_SEQ_R
LEFT JOIN AMT_2
ON FBP_D_2.N_PAY_DTL_SOURCE_SYSTEM_KEY_R= AMT_2.N_PAY_SCHD_SOURCE_SYSTEM_KEY_R
AND FBP_D_2.N_SOURCE_VERSION_SEQ_NUMBER_R= AMT_2.N_SOURCE_VERSION_SEQ_NUMBER_R
AND FBP_D_2.N_GROUP_SEQ_R=AMT_2.N_SEQ_R
where (NVL(AMT_1.S_N_Amount_R, 0) != 0 or  NVL(AMT_2.FWS_AMT,0) != 0)
and (CASE WHEN (NVL(AMT_1.S_N_Amount_R,0) +  NVL(AMT_2.FWS_AMT,0) !=AMT_2.N_ADJ_NET_BENEFIT_R) AND NVL(AMT_1.S_N_Amount_R,0) +  NVL(AMT_2.FWS_AMT,0) <> 0  THEN (nvl(AMT_1.S_N_Amount_R,0) +  NVL(AMT_2.FWS_AMT,0))*-1  ELSE 0 END) <> 0
--and  Case when
--(CASE WHEN NVL(AMT_1.S_N_Amount_R,0) +  NVL(AMT_2.FWS_AMT,0) != AMT_2.N_ADJ_NET_BENEFIT_R THEN nvl(AMT_2.N_ADJ_NET_BENEFIT_R,0) - (nvl(AMT_1.S_N_Amount_R,0) +  NVL(AMT_2.FWS_AMT,0))  ELSE 0 END <> 0)
--then FBP_D_2.V_BENEFIT_CODE_R||' '||V_TYPE_R else '382 Offset' end = '382 Offset'
order by FBP_D_2.N_SOURCE_VERSION_SEQ_NUMBER_R
) A
/*WHERE NOT EXISTS (
SELECT 1 FROM FCT_CLAIM_PAYMENT_DETAIL_OFFSETS_R B
WHERE
B.N_PAY_DTL_SOURCE_SYSTEM_KEY_R                =A.N_PAY_DTL_SOURCE_SYSTEM_KEY_R
AND B.N_VERSION_NUMBER_R                       =A.N_VERSION_NUMBER_R
AND B.N_SOURCE_VERSION_SEQ_NUMBER_R            =A.N_SOURCE_VERSION_SEQ_NUMBER_R
AND B.N_SEQ_R                                  =A.N_SEQ_R
AND B.V_AMOUNT_TYPE_NAME_R                     =A.V_AMOUNT_TYPE_NAME_R
AND B.V_AMOUNT_TYPE_NAME_R = 'ALLSOURCE EXCESS OFFSET'
AND B.N_SEQ_R='9001'
)*/
)Where NVL(N_AMOUNT_R,0)<>0--11-May-2022 Mohan changes
 --27-SEP-2023 changes starts
) a1
,(SELECT * FROM ATOMIC.dim_payment_details pd WHERE PD.V_ACTIVE_STATUS_R = 'Y')PD
,(SELECT * FROM ATOMIC.dim_grp_party_r WHERE v_active_status_r = 'Y') pa
  --,ATOMIC.dim_payment_details pd
  --,ATOMIC.dim_grp_party_r pa
--where pd.V_PAYMNT_DTLS_SRC_SYS_KEY_R = DGCDR.n_source_system_key_r
where a1.n_source_system_key_r = pd.V_PAYMNT_DTLS_SRC_SYS_KEY_R(+)
	 --pd.V_PAYMNT_DTLS_SRC_SYS_KEY_R = a1.n_source_system_key_r
     --and pd.v_active_status_r = 'Y'
     --and pd.V_WORKSHEET_OBJECTNUM_R = FBPR.N_WORKSHEET_SEQ_NBR_OBJECTNM_R
     and a1.N_WORKSHEET_SEQ_NBR_OBJECTNM_R = pd.V_WORKSHEET_OBJECTNUM_R(+)
	 and NVL(a1.V_LINK_OBJECTNUM_R,0)=PD.V_PAYMNT_DTLS_SEQ_NBR_R(+)
	 --and pd.V_WORKSHEET_OBJECTNUM_R = a1.N_WORKSHEET_SEQ_NBR_OBJECTNM_R
     and pd.N_INSRD_PARTY_SK_R = pa.n_party_sk_r(+)
     --and pa.v_active_status_r = 'Y'
     --AND PD.V_PAYMNT_DTLS_SEQ_NBR_R = (SELECT MAX(B.V_PAYMNT_DTLS_SEQ_NBR_R)
     --                            from dim_payment_details b
     --                            where b.V_PAYMNT_DTLS_SRC_SYS_KEY_R = pd.V_PAYMNT_DTLS_SRC_SYS_KEY_R
     --                            and b.V_WORKSHEET_OBJECTNUM_R = pd.V_WORKSHEET_OBJECTNUM_R
     --                            and b.v_active_status_r = 'Y')
--27-SEP-2023 changes ends
;
COMMIT;


gc_trcmsg:='5.Completed data insertion into FCT_CLAIM_PAYMENT_DETAIL_OFFSETS_R';
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
						p_job_id_r            			=> gn_out_job_id,
						p_batch_id_r                  	=> gn_sysdt_batchid,
						p_message_type_r              	=> lv_message_type_r,
						p_code_location_r             	=> gc_main_loadedby,
						p_message_r                   	=> gc_trcmsg,
						p_count_type_r                	=> NULL,
						p_count_r                     	=> NULL,
						p_duration_r                  	=> NULL,
						p_created_by_r                	=> GC_JOB_NAME,
						out_prcs_job_log_message_id_r 	=> gn_job_log_message_id_r
						);


		gc_trcmsg:='1. Exit from PRC_FULLLOAD_FCT_CLAIMPMNT_DET_OFFSET3_R ';
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
						p_job_id_r            			=> gn_out_job_id,
						p_batch_id_r                  	=> gn_sysdt_batchid,
						p_message_type_r              	=> lv_message_type_r,
						p_code_location_r             	=> gc_main_loadedby,
						p_message_r                   	=> gc_trcmsg,
						p_count_type_r                	=> NULL,
						p_count_r                     	=> NULL,
						p_duration_r                  	=> NULL,
						p_created_by_r                	=> GC_JOB_NAME,
						out_prcs_job_log_message_id_r 	=> gn_job_log_message_id_r
						);

			pkg_grp_log_util.prc_update_log(
      						gn_out_job_id                   --p_job_id
							,gc_success_status              --p_job_status
							,gc_errmsg                      --p_err_msg
							,gc_trcmsg                      --p_trc_msg
							,gc_main_loadedby               --p_log_util_called_by_r
							);


OUT_LOAD_STATUS:='SUCCESS';
EXCEPTION
WHEN OTHERS THEN
LC_SQLCODE:=SQLCODE;
LC_SQLERRM:=SUBSTR(SQLERRM,1,4000);
OUT_LOAD_STATUS:=LC_SQLCODE||'-'||LC_SQLERRM;
DBMS_OUTPUT.PUT_LINE('PRC_FULLLOAD_FCT_CLAIMPMNT_DET_OFFSET3_R  EXCEPTION WITH ERROR CODE AS '
             || SQLCODE
             || ' '
             || SQLERRM
             || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
             ||'PRC_FULLLOAD_FCT_CLAIMPMNT_DET_OFFSET3_R'
             ||';');

	gc_errmsg :=SUBSTR(SQLERRM,1,4000);
    gc_trcmsg:='1.z Error in PRC_FULLLOAD_FCT_CLAIMPMNT_DET_OFFSET3_R: '||gc_errmsg;

         /*START: NEW LOGGING MECHANISM CHANGES*/    
    pkg_grp_log_util.prc_update_log_message_r
			( 
			n_prcs_job_log_message_id_r => gn_job_log_message_id_r,
			p_err_msg 					=> gc_trcmsg 
				);
	     /*END: NEW LOGGING MECHANISM CHANGES*/     

	pkg_grp_log_util.prc_update_log
      (
        gn_out_job_id                   	--p_job_id
        ,gc_error_status                	--p_job_status
        ,gc_errmsg                       	--p_err_msg
        ,gc_trcmsg					     	--p_trc_msg
        ,gc_main_loadedby               	--p_log_util_called_by_r
    );				 

  	RAISE_APPLICATION_ERROR(-20001,'Error in PKG_GRP_FULLLOAD_OFFSETS.PRC_FULLLOAD_FCT_CLAIMPMNT_DET_OFFSET3_R:->
    Error Code:'||LC_SQLCODE||',Error message:'||LC_SQLERRM);			 

END PRC_FULLLOAD_FCT_CLAIMPMNT_DET_OFFSET3_R;
END PKG_GRP_FULLLOAD_OFFSETS;