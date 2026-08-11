create or replace procedure PRC_GRP_UPD_PACS_PARTYSK_FCT_CLAIM_PMNT_DTL_BENEFIT_PMNT_R
as
ln_start_time   NUMBER;
ln_cnt          NUMBER:=0;
ln_rowcnt       NUMBER;
ld_sysdate      DATE :=sysdate;
lc_errmsg       VARCHAR2(4000);
lc_row_id       VARCHAR2(4000);
N_EXISTS        NUMBER;
V_TABLE_NAME_R  VARCHAR2(100);
gd_sysdate               DATE               := TRUNC(SYSDATE);
gc_source                VARCHAR2(30)       :='EDW';
gc_job_name              VARCHAR2(50 CHAR)  :='PKG_GRP_FULLLOAD_OFFSETS';
gn_sysdt_batchid         NUMBER             := TO_NUMBER(TO_CHAR(gd_sysdate,'YYYYMMDD'));
gc_trcmsg                CLOB               :='Trace Message:->';
gc_error_status          VARCHAR2(30)       :='Error';
gc_success_status        VARCHAR2(30)       :='Success';
gc_running_status        VARCHAR2(30)       :='Running';
gc_errmsg                VARCHAR2(4000 CHAR);
gn_out_job_id            NUMBER;
gn_job_log_message_id_r  NUMBER;
gc_main_loadedby VARCHAR2(100 CHAR);

LC_SQLCODE VARCHAR2(4000);
LC_SQLERRM VARCHAR2(4000);
LN_SEQUENCE_NUMBER_R NUMBER;
--LN_IN_BATCH_ID_R NUMBER:=IN_BATCH_ID_R;
LN_LOAD_RUN_ID_R NUMBER:=1;
lv_message_type_r  PRCS_JOB_LOG_MESSAGE_R.v_message_type_r%TYPE:= PKG_GRP_LOG_UTIL.gc_message_type_info;

BEGIN

begin

ln_start_time := ATOMIC.LOG_TIME(ln_start_time, '1. atomic.PRC_GRP_UPD_PACS_PARTYSK_FCT_CLAIM_PMNT_DTL_BENEFIT_PMNT_R Entered-:'
, ld_sysdate);

FOR I IN (select *
from
  (select 
    n_party_sk_r,
    v_payee_first_name_r,
    v_payee_middle_name_r,
    v_payee_last_name_r,
    mv.party_d_record_start_date_r,
    mv.v_source_system_name_r ,
    --n_batch_id_r,
	  mv.n_source_version_seq_number_r
    ||mv.n_claim_sk_r
    ||mv.n_claim_coverage_sk_r
    ||mv.n_seq_r
    ||mv.n_claim_coverage_group_sk_r
    ||mv.n_fbpdr_n_seq_r
    ||mv.v_source_system_name_r row_id,
    rank() over (partition by 
	  mv.n_source_version_seq_number_r
    ||mv.n_claim_sk_r
    ||mv.n_claim_coverage_sk_r
    ||mv.n_seq_r
    ||mv.n_claim_coverage_group_sk_r
    ||mv.n_fbpdr_n_seq_r
    ||mv.v_source_system_name_r 
	order by mv.party_d_record_start_date_r desc) as rnk
  from fct_claim_pmt_dtl_benefit_payment_partysk_pacs_mv MV
  /*where mv.n_source_version_seq_number_r
    ||mv.n_claim_sk_r
    ||mv.n_claim_coverage_sk_r
    ||mv.n_seq_r
    ||mv.n_claim_coverage_group_sk_r
    ||mv.n_fbpdr_n_seq_r
    ||mv.v_source_system_name_r
	--||mv.n_batch_id_r 
	--= '67130295030515001-12PACS'*/
  ) f
  WHERE RNK=1
 -- AND ROWNUM <100
  )
LOOP
   UPDATE FCT_CLAIM_PAYMENT_DETAIL_BENEFIT_PAYMENT_R F
      SET  n_party_sk_r           =i.n_party_sk_r          
          ,v_payee_first_name_r   =i.v_payee_first_name_r  
          ,v_payee_middle_name_r  =i.v_payee_middle_name_r 
          ,v_payee_last_name_r    =i.v_payee_last_name_r   
		  ,t_last_modified_date_r =ld_sysdate
		  ,v_last_modified_by_r   ='PRC_GRP_UPD_PACS_PARTYSK_FCT_CLAIM_PMNT_DTL_BENEFIT_PMNT_R'
    WHERE F.n_source_version_seq_number_r
           ||F.n_claim_sk_r
           ||F.n_claim_coverage_sk_r
           ||F.n_seq_r
           ||F.n_claim_coverage_group_sk_r
           ||F.n_fbpdr_n_seq_r
           ||F.v_source_system_name_r	
           =  I.row_id
	       AND F.V_SOURCE_SYSTEM_NAME_R='PACS';
	COMMIT;	   
    ln_rowcnt :=sql%rowcount;
	COMMIT;	  	
	LC_ROW_ID:=I.ROW_ID;
	ln_cnt:=ln_cnt+ln_rowcnt;
END LOOP;
ln_start_time := ATOMIC.LOG_TIME(ln_start_time, '1.z Number of records updated :->'||ln_cnt||':-'||lc_row_id||' from procedure atomic.PRC_GRP_UPD_PACS_PARTYSK_FCT_CLAIM_PMNT_DTL_BENEFIT_PMNT_R and Exiting from the procedure-:'
, ld_sysdate);

EXCEPTION
WHEN OTHERS THEN
lc_errmsg:=SUBSTR(SQLERRM,1,4000);
ln_start_time := ATOMIC.LOG_TIME(ln_start_time, '1.z. Exception - Error in atomic.PRC_GRP_UPD_PACS_PARTYSK_FCT_CLAIM_PMNT_DTL_BENEFIT_PMNT_R Exit-:'||lc_errmsg
                 , ld_sysdate);
RAISE_APPLICATION_ERROR (-20343, 'Raise PRC_GRP_UPD_PACS_PARTYSK_FCT_CLAIM_PMNT_DTL_BENEFIT_PMNT_R Error -'||lc_errmsg);

end;

begin

V_TABLE_NAME_R :='FCT_CLAIM_PAYMENT_DETAIL_BENEFIT_PAYMENT_R_UPD_PAYEE_NAME';

gc_trcmsg:='1. Drop and recreate table FCT_CLAIM_PAYMENT_DETAIL_BENEFIT_PAYMENT_R_UPD_PAYEE_NAME';



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


SELECT COUNT(1) INTO N_EXISTS FROM USER_TABLES WHERE TABLE_NAME ='FCT_CLAIM_PAYMENT_DETAIL_BENEFIT_PAYMENT_R_UPD_PAYEE_NAME';

  IF N_EXISTS<>0 THEN
   EXECUTE immediate 'DROP TABLE FCT_CLAIM_PAYMENT_DETAIL_BENEFIT_PAYMENT_R_UPD_PAYEE_NAME';
  END IF;

EXECUTE IMMEDIATE 'CREATE TABLE FCT_CLAIM_PAYMENT_DETAIL_BENEFIT_PAYMENT_R_UPD_PAYEE_NAME AS
SELECT 
N_SOURCE_VERSION_SEQ_NUMBER_R,N_SEQ_R,N_CLAIM_SK_R,N_CLAIM_COVERAGE_SK_R,N_CLAIM_COVERAGE_GROUP_SK_R,N_FBPDR_N_SEQ_R,v_source_system_name_r,
v_payee_first_name_r,v_payee_middle_name_r, v_payee_last_name_r from
(
SELECT   /*+PARALLEL(4)*/
		FBPR.N_SOURCE_VERSION_SEQ_NUMBER_R                                                                          N_SOURCE_VERSION_SEQ_NUMBER_R
		,FBPR.N_SEQ_R                                                                                                N_SEQ_R
		, FBPR.N_CLAIM_SK_R               
		,FBPR.N_CLAIM_COVERAGE_SK_R                  --08-Apr-2022 Erica changes
		,FBPR.N_CLAIM_COVERAGE_GROUP_SK_R            --08-Apr-2022 Erica changes
		,FBPDR.N_SEQ_R                       N_FBPDR_N_SEQ_R --10-Nov-2022 changes for Merge
		,FBPR.v_source_system_name_r --14-Dec-2022 changes		
		,pa.V_INDIVIDUAL_FIRST_NAME_R v_payee_first_name_r
		,pa.V_INDIVIDUAL_middle_NAME_R v_payee_middle_name_r
        ,pa.V_INDIVIDUAL_LAST_NAME_R v_payee_last_name_r		
		FROM 
		ATOMIC.FCT_BENEFIT_PAYMENT_R FBPR	
		,ATOMIC.DIM_GRP_CLAIM_DIR_R DGCDR
		,ATOMIC.FCT_GRP_WORKSHEET FGW
		,ATOMIC.FCT_BENEFIT_PAYMENT_DETAIL_R FBPDR
		,ATOMIC.DIM_GRP_CLAIM_COVERAGE_GROUP_R DGCCGR
		,ATOMIC.DIM_GRP_CLAIM_COVERAGE_R DGCCR
		,(SELECT * FROM ATOMIC.dim_payment_details pd WHERE PD.V_ACTIVE_STATUS_R = ''Y'')PD --27-SEP-2023 changes
		,(select * from dim_grp_party_r where v_active_status_r = ''Y'' and V_SOURCE_SYSTEM_NAME_R = ''PACS'')  pa --27-SEP-2023 changes
		WHERE  UPPER(TRIM(FBPR.V_PAY_STATUS_R)) IN (''RELEASED'',''REVERSAL'',''REVERSED'')
		AND FBPR.N_CLAIM_SK_R = DGCDR.N_CLAIM_SK_R
        and FBPR.N_CLAIM_COVERAGE_SK_R = DGCCR.N_CLAIM_COVERAGE_SK_R(+)
        and FBPR.N_CLAIM_COVERAGE_GROUP_SK_R = DGCCGR.N_CLAIM_COVERAGE_GROUP_SK_R(+)
		AND FGW.N_WORKSHEET_SEQ_NBR_OBJECTNM_R = FBPR.N_PARENT_OBJECTNUM_R
		AND FGW.N_SOURCE_SYSTEM_KEY_R = FBPR.N_PAY_SCHD_SOURCE_SYSTEM_KEY_R
		AND FBPR.N_SOURCE_VERSION_SEQ_NUMBER_R = FBPDR.N_SOURCE_VERSION_SEQ_NUMBER_R(+)  --22-Jul-2021 Erica outer join request
		AND FBPR.N_SEQ_R = FBPDR.N_GROUP_SEQ_R(+)--22-Jul-2021 Erica outer join request
		AND FBPR.N_PAY_SCHD_SOURCE_SYSTEM_KEY_R = FBPDR.N_PAY_DTL_SOURCE_SYSTEM_KEY_R(+)--22-Jul-2021 Erica outer join request
		AND DGCDR.V_ACTIVE_STATUS_R         = ''Y''
        and nvl(DGCCGR.V_ACTIVE_STATUS_R,''Y'') = ''Y''
        AND NVL(DGCCR.V_ACTIVE_STATUS_R, ''Y'')  = ''Y''
		AND UPPER(TRIM(FBPDR.V_BENEFIT_DESC_R)) <> ''PAYMENT TO SECONDARY PAYEE'' --11-May-2022 Mohan Changes
		AND DGCDR.N_SOURCE_SYSTEM_KEY_R =PD.V_PAYMNT_DTLS_SRC_SYS_KEY_R(+)------27-SEP-2023 change,  TABLE ORDER REVERSED WITH OUTER JOIN
        AND FBPR.N_WORKSHEET_SEQ_NBR_OBJECTNM_R = PD.V_WORKSHEET_OBJECTNUM_R(+)------27-SEP-2023 change,  TABLE ORDER REVERSED WITH OUTER JOIN
        AND NVL(FBPR.V_LINK_OBJECTNUM_R,0)=PD.V_PAYMNT_DTLS_SEQ_NBR_R(+)----27-SEP-2023 CHANGES,  TABLE ORDER REVERSED WITH OUTER JOIN AND NVL IMPLEMENTATION
        and pd.N_INSRD_PARTY_SK_R = pa.n_party_sk_r(+) --27-SEP-2023 change - outer join on party_SK_R		
	    and NVL(FBPR.v_source_system_name_r,''X@'')=''PACS''--01-Dec-2022 temp filter applied to stop SHINKA data
) 
MINUS
SELECT N_SOURCE_VERSION_SEQ_NUMBER_R,N_SEQ_R,N_CLAIM_SK_R,N_CLAIM_COVERAGE_SK_R,N_CLAIM_COVERAGE_GROUP_SK_R,N_FBPDR_N_SEQ_R,v_source_system_name_r,
v_payee_first_name_r,v_payee_middle_name_r, v_payee_last_name_r
FROM ATOMIC.FCT_CLAIM_PAYMENT_DETAIL_BENEFIT_PAYMENT_R WHERE V_SOURCE_SYSTEM_NAME_R = ''PACS''
';

EXECUTE IMMEDIATE 'GRANT SELECT ON FCT_CLAIM_PAYMENT_DETAIL_BENEFIT_PAYMENT_R_UPD_PAYEE_NAME TO ATOMIC_ALL_RO';


gc_trcmsg:='2. Table FCT_CLAIM_PAYMENT_DETAIL_BENEFIT_PAYMENT_R_UPD_PAYEE_NAME created';



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

gc_trcmsg:='3. Merge table FCT_CLAIM_PAYMENT_DETAIL_BENEFIT_PAYMENT_R with latest Payee Names';



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


EXECUTE IMMEDIATE 'MERGE /*+APPEND*/ INTO ATOMIC.FCT_CLAIM_PAYMENT_DETAIL_BENEFIT_PAYMENT_R D
USING
(
SELECT /*+PARALLE(4) */ * FROM ' || V_TABLE_NAME_R ||
') S
ON 
( D.N_SOURCE_VERSION_SEQ_NUMBER_R   = S.N_SOURCE_VERSION_SEQ_NUMBER_R 
     AND D.N_CLAIM_SK_R                    = S.N_CLAIM_SK_R                  
     AND D.N_CLAIM_COVERAGE_SK_R           = S.N_CLAIM_COVERAGE_SK_R         
     AND D.N_SEQ_R                         = S.N_SEQ_R                       
     AND D.N_CLAIM_COVERAGE_GROUP_SK_R     = S.N_CLAIM_COVERAGE_GROUP_SK_R
     AND D.N_FBPDR_N_SEQ_R	              = S.N_FBPDR_N_SEQ_R	  
)
WHEN MATCHED THEN
UPDATE SET
 D.V_PAYEE_FIRST_NAME_R  =  S.V_PAYEE_FIRST_NAME_R
,D.V_PAYEE_MIDDLE_NAME_R =  S.V_PAYEE_MIDDLE_NAME_R
,D.V_PAYEE_LAST_NAME_R   =  S.V_PAYEE_LAST_NAME_R
WHERE D.V_SOURCE_SYSTEM_NAME_R = ''PACS''
';
COMMIT;

gc_trcmsg:='4. Table FCT_CLAIM_PAYMENT_DETAIL_BENEFIT_PAYMENT_R merged with latest Payee Names';



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

--OUT_LOAD_STATUS:='SUCCESS';
EXCEPTION
WHEN OTHERS THEN
LC_SQLCODE:=SQLCODE;
LC_SQLERRM:=SUBSTR(SQLERRM,1,4000);
--OUT_LOAD_STATUS:=LC_SQLCODE||'-'||LC_SQLERRM;
DBMS_OUTPUT.PUT_LINE('PRC_GRP_UPD_PACS_PARTYSK_FCT_CLAIM_PMNT_DTL_BENEFIT_PMNT_R EXCEPTION WITH ERROR CODE AS '
             || SQLCODE
             || ' '
             || SQLERRM
             || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
             ||'PRC_GRP_UPD_PACS_PARTYSK_FCT_CLAIM_PMNT_DTL_BENEFIT_PMNT_R'
             ||';');

    gc_errmsg :=SUBSTR(SQLERRM,1,4000);
    gc_trcmsg:='1.z Error in PRC_GRP_UPD_PACS_PARTYSK_FCT_CLAIM_PMNT_DTL_BENEFIT_PMNT_R: '||gc_errmsg;

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

  	RAISE_APPLICATION_ERROR(-20001,'Error in PRC_GRP_UPD_PACS_PARTYSK_FCT_CLAIM_PMNT_DTL_BENEFIT_PMNT_R.FCT_CLAIM_PAYMENT_DETAIL_BENEFIT_PAYMENT_R:->
    Error Code:'||LC_SQLCODE||',Error message:'||LC_SQLERRM);			 

END;

END;