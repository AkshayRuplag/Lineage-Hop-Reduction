create or replace procedure PRC_GRP_UPD_CV_PAYEE_NAME_FCT_CLAIM_PMNT_DTL_BENEFIT_PMNT_R
as
N_EXISTS        NUMBER;
V_TABLE_NAME_R  VARCHAR2(100);
gd_sysdate               DATE               := TRUNC(SYSDATE);
gc_source                VARCHAR2(30)       :='EDW';
gc_job_name              VARCHAR2(70 CHAR)  :='PRC_GRP_UPD_CV_PAYEE_NAME_FCT_CLAIM_PMNT_DTL_BENEFIT_PMNT_R';
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
lv_message_type_r  PRCS_JOB_LOG_MESSAGE_R.v_message_type_r%TYPE:= PKG_GRP_LOG_UTIL.gc_message_type_info;

BEGIN


        gc_main_loadedby :='PRC_GRP_UPD_CV_PAYEE_NAME_FCT_CLAIM_PMNT_DTL_BENEFIT_PMNT_R';

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



V_TABLE_NAME_R :='FCT_CLAIM_PAYMENT_DETAIL_BENEFIT_PAYMNT_CV_UPD_PAYEE_NAME';

gc_trcmsg:='1. Drop and recreate table FCT_CLAIM_PAYMENT_DETAIL_BENEFIT_PAYMNT_CV_UPD_PAYEE_NAME';



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


SELECT COUNT(1) INTO N_EXISTS FROM USER_TABLES WHERE TABLE_NAME ='FCT_CLAIM_PAYMENT_DETAIL_BENEFIT_PAYMNT_CV_UPD_PAYEE_NAME';

  IF N_EXISTS<>0 THEN
   EXECUTE immediate 'DROP TABLE FCT_CLAIM_PAYMENT_DETAIL_BENEFIT_PAYMNT_CV_UPD_PAYEE_NAME';
  END IF;

EXECUTE IMMEDIATE 'CREATE TABLE FCT_CLAIM_PAYMENT_DETAIL_BENEFIT_PAYMNT_CV_UPD_PAYEE_NAME AS

WITH Union_1 AS (select /*+PARALLEL(16)*/  FBPR.N_SOURCE_VERSION_SEQ_NUMBER_R N_SOURCE_VERSION_SEQ_NUMBER_R,
FBPR.N_CLAIM_SK_R,FBPR.N_CLAIM_COVERAGE_SK_R,FBPR.N_SEQ_R N_SEQ_R,FBPR.N_CLAIM_COVERAGE_GROUP_SK_R,
FBPDR.N_SEQ_R N_FBPDR_N_SEQ_R,FBPR.V_CHECK_NUM_R V_CHECK_NUMBER_R								,(
												case 
															when (UPPER(TRIM(FBPR.V_PAY_STATUS_R))) IN (''REVERSAL'',''VOID'')      /*VOID added for SHINKA data flow 09-MAR-23 */
																			then ''VOID''
															else ''PAID''
															end
												) V_PAYMENT_STATUS_R,

FBPDR.V_BENEFIT_DESC_R,	NVL(FBPR.V_SOURCE_SYSTEM_NAME_R,''@'') V_SOURCE_SYSTEM_NAME_R 
							,pa.V_INDIVIDUAL_FIRST_NAME_R v_payee_first_name_r		
							,pa.V_INDIVIDUAL_middle_NAME_R v_payee_middle_name_r
							,pa.V_INDIVIDUAL_LAST_NAME_R v_payee_last_name_r


					from ATOMIC.FCT_BENEFIT_PAYMENT_R FBPR
					inner join ATOMIC.DIM_GRP_CLAIM_DIR_R DGCDR on FBPR.N_CLAIM_SK_R = DGCDR.N_CLAIM_SK_R and DGCDR.V_ACTIVE_STATUS_R = ''Y''  --Subhadeep Change moved "V_ACTIVE_STATUS_R = ''Y'' " to join
					/* --inner join $tbl_name3 FGW on FGW.N_WORKSHEET_SEQ_NBR_OBJECTNM_R = FBPR.N_PARENT_OBJECTNUM_R -- For SHINKA Worksheet table not considered.
								--and FGW.N_SOURCE_SYSTEM_KEY_R = FBPR.N_PAY_SCHD_SOURCE_SYSTEM_KEY_R -- For SHINKA Worksheet table not considered. */
					left join ATOMIC.FCT_BENEFIT_PAYMENT_DETAIL_R FBPDR on TRIM(FBPR.N_PAY_SCHD_SOURCE_SYSTEM_KEY_R) = TRIM(FBPDR.N_PAY_DTL_SOURCE_SYSTEM_KEY_R)
								and FBPR.N_SOURCE_VERSION_SEQ_NUMBER_R = FBPDR.N_SOURCE_VERSION_SEQ_NUMBER_R 
								and NVL(CONCAT(FBPR.V_CHECK_NUM_R,FBPR.V_PAY_STATUS_R),-1) = NVL(FBPDR.V_CHECKPAY_STATUS_R,-1)
								and NVL(FBPR.N_SEQ_R,-1) = NVL(FBPDR.N_GROUP_SEQ_R,-1)           /* NVL added for SHINKA data 09-MAR-23 */
					left join ATOMIC.DIM_GRP_CLAIM_COVERAGE_GROUP_R DGCCGR on FBPR.N_CLAIM_COVERAGE_GROUP_SK_R = DGCCGR.N_CLAIM_COVERAGE_GROUP_SK_R and NVL(DGCCGR.V_ACTIVE_STATUS_R, ''Y'') = ''Y''  --Subhadeep Change moved "V_ACTIVE_STATUS_R = ''Y'' " to join
					left join ATOMIC.DIM_GRP_CLAIM_COVERAGE_R DGCCR on FBPR.N_CLAIM_COVERAGE_SK_R = DGCCR.N_CLAIM_COVERAGE_SK_R and NVL(DGCCR.V_ACTIVE_STATUS_R, ''Y'') = ''Y''  --Subhadeep Change moved "V_ACTIVE_STATUS_R = ''Y'' " to join

					left join
					(SELECT * FROM ATOMIC.dim_payment_details pd WHERE PD.V_ACTIVE_STATUS_R = ''Y'')PD --27-SEP-2023 changes
					on   -- DGCDR.N_SOURCE_SYSTEM_KEY_R =PD.V_PAYMNT_DTLS_SRC_SYS_KEY_R 
					FBPR.N_SOURCE_VERSION_SEQ_NUMBER_R =PD.V_PAYMNT_DTLS_SEQ_NBR_R  -- (CHANGED BY SUDIP)
					--AND NVL(FBPR.V_LINK_OBJECTNUM_R,0)=PD.V_PAYMNT_DTLS_SEQ_NBR_R----27-SEP-2023 CHANGES,  TABLE ORDER REVERSED WITH OUTER JOIN AND NVL IMPLEMENTATION (DISABLED BY SUDIP)
					left join (select * from Atomic.dim_grp_party_r where v_active_status_r = ''Y'')  pa 				--- changes made in order to map payee name
					      on pd.N_INSRD_PARTY_SK_R = pa.n_party_sk_r AND PA.V_SOURCE_SYSTEM_NAME_R=PD.v_source_system_name_r AND PA.v_party_type_r=PD.v_party_type_r
						  AND pa.n_party_sk_r<>-1 AND PA.v_source_system_name_r = ''CV''
					where 	
					( UPPER(TRIM(FBPR.V_PAY_STATUS_R)) in (
												''VOID''                                               /* VOID added for SHINKA data flow 09-MAR-23 */
												)
								AND UPPER(TRIM(FBPDR.V_BENEFIT_DESC_R)) <> ''PAYMENT TO SECONDARY PAYEE''
								and NVL(FBPR.V_SOURCE_SYSTEM_NAME_R,''X@'') = ''CV''

					) AND  FBPR.V_CHECK_NUM_R = ''CVR1034011''

					--  OR 
					--  
					--  (FBPR.v_check_num_r in (select a.v_check_num_r from (
					--select v_check_num_r, count(V_PAY_STATUS_R) 
					--from FCT_BENEFIT_PAYMENT_R_CV_PREP_20241016 where  v_source_system_name_r = ''CV'' 
					--group by v_check_num_r
					--having count(V_PAY_STATUS_R) = 1)a inner join FCT_BENEFIT_PAYMENT_R_CV_PREP_20241016 b
					--on a.v_check_num_r = b.v_check_num_r
					--where  UPPER(TRIM(B.V_PAY_STATUS_R)) = ''CLEARED''
					----and b.n_claim_sk_r = ''1517263''
					--))


UNION 					

select /*+PARALLEL(16)*/   FBPR.N_SOURCE_VERSION_SEQ_NUMBER_R N_SOURCE_VERSION_SEQ_NUMBER_R,
FBPR.N_CLAIM_SK_R,FBPR.N_CLAIM_COVERAGE_SK_R,FBPR.N_SEQ_R N_SEQ_R,FBPR.N_CLAIM_COVERAGE_GROUP_SK_R,FBPDR.N_SEQ_R N_FBPDR_N_SEQ_R,
FBPR.V_CHECK_NUM_R V_CHECK_NUMBER_R,(
												case 
															when (UPPER(TRIM(FBPR.V_PAY_STATUS_R))) IN (''REVERSAL'',''VOID'')      /*VOID added for SHINKA data flow 09-MAR-23 */
																			then ''VOID''
															else ''PAID''
															end
												) V_PAYMENT_STATUS_R,

FBPDR.V_BENEFIT_DESC_R,NVL(FBPR.V_SOURCE_SYSTEM_NAME_R,''@'') V_SOURCE_SYSTEM_NAME_R,
pa.V_INDIVIDUAL_FIRST_NAME_R v_payee_first_name_r
							,pa.V_INDIVIDUAL_middle_NAME_R v_payee_middle_name_r
							,pa.V_INDIVIDUAL_LAST_NAME_R v_payee_last_name_r







					from ATOMIC.FCT_BENEFIT_PAYMENT_R FBPR
					inner join ATOMIC.DIM_GRP_CLAIM_DIR_R DGCDR on FBPR.N_CLAIM_SK_R = DGCDR.N_CLAIM_SK_R and DGCDR.V_ACTIVE_STATUS_R = ''Y''  --Subhadeep Change moved "V_ACTIVE_STATUS_R = ''Y'' " to join
					/* --inner join $tbl_name3 FGW on FGW.N_WORKSHEET_SEQ_NBR_OBJECTNM_R = FBPR.N_PARENT_OBJECTNUM_R -- For SHINKA Worksheet table not considered.
								--and FGW.N_SOURCE_SYSTEM_KEY_R = FBPR.N_PAY_SCHD_SOURCE_SYSTEM_KEY_R -- For SHINKA Worksheet table not considered. */
					left join ATOMIC.FCT_BENEFIT_PAYMENT_DETAIL_R FBPDR on TRIM(FBPR.N_PAY_SCHD_SOURCE_SYSTEM_KEY_R) = TRIM(FBPDR.N_PAY_DTL_SOURCE_SYSTEM_KEY_R)
								and FBPR.N_SOURCE_VERSION_SEQ_NUMBER_R = FBPDR.N_SOURCE_VERSION_SEQ_NUMBER_R 
								and NVL(CONCAT(FBPR.V_CHECK_NUM_R,FBPR.V_PAY_STATUS_R),-1) = NVL(FBPDR.V_CHECKPAY_STATUS_R,-1)
								and NVL(FBPR.N_SEQ_R,-1) = NVL(FBPDR.N_GROUP_SEQ_R,-1)           /* NVL added for SHINKA data 09-MAR-23 */
					left join ATOMIC.DIM_GRP_CLAIM_COVERAGE_GROUP_R DGCCGR on FBPR.N_CLAIM_COVERAGE_GROUP_SK_R = DGCCGR.N_CLAIM_COVERAGE_GROUP_SK_R and NVL(DGCCGR.V_ACTIVE_STATUS_R, ''Y'') = ''Y''  --Subhadeep Change moved "V_ACTIVE_STATUS_R = ''Y''" to join
					left join ATOMIC.DIM_GRP_CLAIM_COVERAGE_R DGCCR on FBPR.N_CLAIM_COVERAGE_SK_R = DGCCR.N_CLAIM_COVERAGE_SK_R and NVL(DGCCR.V_ACTIVE_STATUS_R, ''Y'') = ''Y''  --Subhadeep Change moved "V_ACTIVE_STATUS_R = ''Y'' " to join

					left join
					(SELECT * FROM ATOMIC.dim_payment_details pd WHERE PD.V_ACTIVE_STATUS_R = ''Y'')PD --27-SEP-2023 changes
					on   -- DGCDR.N_SOURCE_SYSTEM_KEY_R =PD.V_PAYMNT_DTLS_SRC_SYS_KEY_R 
					FBPR.N_SOURCE_VERSION_SEQ_NUMBER_R =PD.V_PAYMNT_DTLS_SEQ_NBR_R  -- (CHANGED BY SUDIP)
					--AND NVL(FBPR.V_LINK_OBJECTNUM_R,0)=PD.V_PAYMNT_DTLS_SEQ_NBR_R----27-SEP-2023 CHANGES,  TABLE ORDER REVERSED WITH OUTER JOIN AND NVL IMPLEMENTATION (DISABLED BY SUDIP)
					LEFT JOIN (SELECT * FROM Atomic.dim_grp_party_r WHERE v_active_status_r = ''Y'')  pa 
					      ON pd.N_INSRD_PARTY_SK_R = pa.n_party_sk_r AND PA.V_SOURCE_SYSTEM_NAME_R=PD.v_source_system_name_r AND PA.v_party_type_r=PD.v_party_type_r 
						  AND pa.n_party_sk_r<>-1 AND PA.v_source_system_name_r = ''CV''  --- changes made in order to map payee name
					Inner Join 
							(select distinct n_claim_sk_r,N_SOURCE_VERSION_SEQ_NUMBER_R,v_check_num_r,V_PAY_STATUS_R,d_trans_date_r from (
								SELECT  n_claim_sk_r,
										NVL(N_SOURCE_VERSION_SEQ_NUMBER_R, - 1) as N_SOURCE_VERSION_SEQ_NUMBER_R,
										NVL(V_CHECK_NUM_R, - 1) as v_check_num_r,
										V_PAY_STATUS_R,
										t_event_timestamp_r,
										d_trans_date_r,
										v_trans_status_r,
										N_BATCH_ID_R,
										row_number() over (partition by n_claim_sk_r,NVL(N_SOURCE_VERSION_SEQ_NUMBER_R, - 1),NVL(V_CHECK_NUM_R, - 1) order by t_event_timestamp_r desc, N_BATCH_ID_R desc) rnk
								FROM ATOMIC.FCT_BENEFIT_PAYMENT_R
								WHERE v_source_system_name_r = ''CV'' AND UPPER(V_PAY_STATUS_R) IN (''RELEASED'',''CLEARED'') AND V_CHECK_NUM_R IS NOT NULL
							) x where rnk = 1
					) BP
					ON  BP.N_CLAIM_SK_R						= FBPR.N_CLAIM_SK_R
					AND BP.N_SOURCE_VERSION_SEQ_NUMBER_R	= FBPR.N_SOURCE_VERSION_SEQ_NUMBER_R
					AND BP.V_CHECK_NUM_R					= FBPR.V_CHECK_NUM_R
					AND BP.V_PAY_STATUS_R					= FBPR.V_PAY_STATUS_R


                     )

SELECT N_SOURCE_VERSION_SEQ_NUMBER_R,N_CLAIM_SK_R,N_CLAIM_COVERAGE_SK_R,N_SEQ_R,N_CLAIM_COVERAGE_GROUP_SK_R,N_FBPDR_N_SEQ_R,V_CHECK_NUMBER_R,
V_PAYMENT_STATUS_R,V_BENEFIT_DESC_R,V_SOURCE_SYSTEM_NAME_R, V_PAYEE_FIRST_NAME_R, V_PAYEE_MIDDLE_NAME_R, V_PAYEE_LAST_NAME_R FROM Union_1	


MINUS

SELECT N_SOURCE_VERSION_SEQ_NUMBER_R,N_CLAIM_SK_R,N_CLAIM_COVERAGE_SK_R,N_SEQ_R,N_CLAIM_COVERAGE_GROUP_SK_R,N_FBPDR_N_SEQ_R,V_CHECK_NUMBER_R,
V_PAYMENT_STATUS_R,V_BENEFIT_DESC_R,V_SOURCE_SYSTEM_NAME_R, V_PAYEE_FIRST_NAME_R, V_PAYEE_MIDDLE_NAME_R, V_PAYEE_LAST_NAME_R
FROM ATOMIC.FCT_CLAIM_PAYMENT_DETAIL_BENEFIT_PAYMENT_R WHERE V_SOURCE_SYSTEM_NAME_R = ''CV'' 
';

EXECUTE IMMEDIATE 'GRANT SELECT ON FCT_CLAIM_PAYMENT_DETAIL_BENEFIT_PAYMNT_CV_UPD_PAYEE_NAME TO ATOMIC_ALL_RO';


gc_trcmsg:='2. Table FCT_CLAIM_PAYMENT_DETAIL_BENEFIT_PAYMNT_CV_UPD_PAYEE_NAME created';



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

gc_trcmsg:='3. Merge table FCT_CLAIM_PAYMENT_DETAIL_BENEFIT_PAYMENT_R with latest Payee Names for CV';



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
ON ( D.N_SOURCE_VERSION_SEQ_NUMBER_R   = S.N_SOURCE_VERSION_SEQ_NUMBER_R
     AND D.N_CLAIM_SK_R                    = S.N_CLAIM_SK_R
     AND D.N_CLAIM_COVERAGE_SK_R           = S.N_CLAIM_COVERAGE_SK_R
     AND D.N_SEQ_R                         = S.N_SEQ_R
     AND D.N_CLAIM_COVERAGE_GROUP_SK_R     = S.N_CLAIM_COVERAGE_GROUP_SK_R
     AND D.N_FBPDR_N_SEQ_R	              = S.N_FBPDR_N_SEQ_R
     AND NVL(D.V_CHECK_NUMBER_R,-999999)               = NVL(S.V_CHECK_NUMBER_R,-999999)
     AND NVL(D.V_PAYMENT_STATUS_R,-999999)             = NVL(S.V_PAYMENT_STATUS_R,-999999)
	 AND D.V_BENEFIT_DESC_R = S.V_BENEFIT_DESC_R              	  
)
WHEN MATCHED THEN
UPDATE SET
 D.V_PAYEE_FIRST_NAME_R  =  S.V_PAYEE_FIRST_NAME_R
,D.V_PAYEE_MIDDLE_NAME_R =  S.V_PAYEE_MIDDLE_NAME_R
,D.V_PAYEE_LAST_NAME_R   =  S.V_PAYEE_LAST_NAME_R
WHERE D.V_SOURCE_SYSTEM_NAME_R = ''CV''
';
COMMIT;

gc_trcmsg:='4. Table FCT_CLAIM_PAYMENT_DETAIL_BENEFIT_PAYMENT_R merged with latest Payee Names for CV';



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
DBMS_OUTPUT.PUT_LINE('PRC_GRP_UPD_CV_PAYEE_NAME_FCT_CLAIM_PMNT_DTL_BENEFIT_PMNT_R EXCEPTION WITH ERROR CODE AS '
             || SQLCODE
             || ' '
             || SQLERRM
             || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
             ||'PRC_GRP_UPD_CV_PAYEE_NAME_FCT_CLAIM_PMNT_DTL_BENEFIT_PMNT_R'
             ||';');

    gc_errmsg :=SUBSTR(SQLERRM,1,4000);
    gc_trcmsg:='1.z Error in PRC_GRP_UPD_CV_PAYEE_NAME_FCT_CLAIM_PMNT_DTL_BENEFIT_PMNT_R: '||gc_errmsg;

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

  	RAISE_APPLICATION_ERROR(-20001,'Error in PRC_GRP_UPD_CV_PAYEE_NAME_FCT_CLAIM_PMNT_DTL_BENEFIT_PMNT_R:->
    Error Code:'||LC_SQLCODE||',Error message:'||LC_SQLERRM);			 



END;