-- Cleaned for lineage: PRC_GRP_UPD_PACS_PARTYSK_FCT_CLAIM_PMNT_DTL_BENEFIT_PMNT_R

FOR I IN (select *
from
  (select 
    n_party_sk_r,
    v_payee_first_name_r,
    v_payee_middle_name_r,
    v_payee_last_name_r,
    mv.party_d_record_start_date_r,
    mv.v_source_system_name_r ,
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
  ) f
  WHERE RNK=1
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

EXECUTE IMMEDIATE 'CREATE TABLE FCT_CLAIM_PAYMENT_DETAIL_BENEFIT_PAYMENT_R_UPD_PAYEE_NAME AS
SELECT 
N_SOURCE_VERSION_SEQ_NUMBER_R,N_SEQ_R,N_CLAIM_SK_R,N_CLAIM_COVERAGE_SK_R,N_CLAIM_COVERAGE_GROUP_SK_R,N_FBPDR_N_SEQ_R,v_source_system_name_r,
v_payee_first_name_r,v_payee_middle_name_r, v_payee_last_name_r from
(
SELECT   /*+PARALLEL(4)*/
		FBPR.N_SOURCE_VERSION_SEQ_NUMBER_R                                                                          N_SOURCE_VERSION_SEQ_NUMBER_R
		,FBPR.N_SEQ_R                                                                                                N_SEQ_R
		, FBPR.N_CLAIM_SK_R               
		,FBPR.N_CLAIM_COVERAGE_SK_R                  
		,FBPR.N_CLAIM_COVERAGE_GROUP_SK_R            
		,FBPDR.N_SEQ_R                       N_FBPDR_N_SEQ_R 
		,FBPR.v_source_system_name_r 
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
		,(SELECT * FROM ATOMIC.dim_payment_details pd WHERE PD.V_ACTIVE_STATUS_R = ''Y'')PD 
		,(select * from dim_grp_party_r where v_active_status_r = ''Y'' and V_SOURCE_SYSTEM_NAME_R = ''PACS'')  pa 
		WHERE  UPPER(TRIM(FBPR.V_PAY_STATUS_R)) IN (''RELEASED'',''REVERSAL'',''REVERSED'')
		AND FBPR.N_CLAIM_SK_R = DGCDR.N_CLAIM_SK_R
        and FBPR.N_CLAIM_COVERAGE_SK_R = DGCCR.N_CLAIM_COVERAGE_SK_R(+)
        and FBPR.N_CLAIM_COVERAGE_GROUP_SK_R = DGCCGR.N_CLAIM_COVERAGE_GROUP_SK_R(+)
		AND FGW.N_WORKSHEET_SEQ_NBR_OBJECTNM_R = FBPR.N_PARENT_OBJECTNUM_R
		AND FGW.N_SOURCE_SYSTEM_KEY_R = FBPR.N_PAY_SCHD_SOURCE_SYSTEM_KEY_R
		AND FBPR.N_SOURCE_VERSION_SEQ_NUMBER_R = FBPDR.N_SOURCE_VERSION_SEQ_NUMBER_R(+)  
		AND FBPR.N_SEQ_R = FBPDR.N_GROUP_SEQ_R(+)
		AND FBPR.N_PAY_SCHD_SOURCE_SYSTEM_KEY_R = FBPDR.N_PAY_DTL_SOURCE_SYSTEM_KEY_R(+)
		AND DGCDR.V_ACTIVE_STATUS_R         = ''Y''
        and nvl(DGCCGR.V_ACTIVE_STATUS_R,''Y'') = ''Y''
        AND NVL(DGCCR.V_ACTIVE_STATUS_R, ''Y'')  = ''Y''
		AND UPPER(TRIM(FBPDR.V_BENEFIT_DESC_R)) <> ''PAYMENT TO SECONDARY PAYEE'' 
		AND DGCDR.N_SOURCE_SYSTEM_KEY_R =PD.V_PAYMNT_DTLS_SRC_SYS_KEY_R(+)
        AND FBPR.N_WORKSHEET_SEQ_NBR_OBJECTNM_R = PD.V_WORKSHEET_OBJECTNUM_R(+)
        AND NVL(FBPR.V_LINK_OBJECTNUM_R,0)=PD.V_PAYMNT_DTLS_SEQ_NBR_R(+)
        and pd.N_INSRD_PARTY_SK_R = pa.n_party_sk_r(+) 
	    and NVL(FBPR.v_source_system_name_r,''X@'')=''PACS''
) 
MINUS
SELECT N_SOURCE_VERSION_SEQ_NUMBER_R,N_SEQ_R,N_CLAIM_SK_R,N_CLAIM_COVERAGE_SK_R,N_CLAIM_COVERAGE_GROUP_SK_R,N_FBPDR_N_SEQ_R,v_source_system_name_r,
v_payee_first_name_r,v_payee_middle_name_r, v_payee_last_name_r
FROM ATOMIC.FCT_CLAIM_PAYMENT_DETAIL_BENEFIT_PAYMENT_R WHERE V_SOURCE_SYSTEM_NAME_R = ''PACS''
';

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