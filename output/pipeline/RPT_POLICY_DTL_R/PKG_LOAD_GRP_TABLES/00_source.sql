

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ATOMIC"."PKG_LOAD_GRP_TABLES"
	/* *********************************************************************************************************************************
	* Type -            PLSQL Package
	* Name -            PKG_LOAP_GRP_TABLES
	* Owner -           ATOMIC
	* Description -     This package has the PLSQL procedures used to populate the Group tables, called by ODI wrappers.
	* Created on -      05-Apr-2021
	* CHANGE LOG -
	* 07-Apr-2021: Added procedure PRC_LOAD_DIM_TIME_R declaration for loading DIM_TIME_R table.
	* 20-May-2021: Added procedure PRC_LOAD_DIM_EMPLOYEE_R declaration for loading DIM_EMPLOYEE_R table.
	* 18-Mar-2022: Added offset1,offset2 procedures
	  04-May-2022:      Added procedure PRC_LOAD_FCT_BENEFIT_PMNT_DET_OFFSET1_R,PRC_LOAD_FCT_BENEFIT_PMNT_DET_OFFSET2_R,PRC_LOAD_FCT_BENEFIT_PMNT_DET_OFFSET3_R
	  06-May-2022:      Added procedures for full load PRC_FULLLOAD_FCT_BENEFIT_PMNT_DET_OFFSET1_R
	  06-May-2022:      Added procedures for full load PRC_FULLLOAD_FCT_BENEFIT_PMNT_DET_OFFSET1_R
													   ,PRC_FULLLOAD_FCT_BENEFIT_PMNT_DET_OFFSET2_R
													   ,PRC_FULLLOAD_FCT_BENEFIT_PMNT_DET_OFFSET3_R
	  11-May-2022:      Mohan Changes in PRC_FULLLOAD_FCT_BENEFIT_PMNT_DET_OFFSET3_R,PRC_LOAD_FCT_BENEFIT_PMNT_DET_OFFSET3_R
	  13-Jun-2022:      Removed Parallel(4) hints in offset procs and replaced count(*) with count(1)
	  28-Jun-2022:      Replaced table STG_CLAIMS_HIERARCHY_R with view VW_STG_CLAIMS_HIERARCHY_R
	  29-Jun-2022 : Added procedure PRC_LOAD_VUE_FCT_GRP_POLICY_R	,PRC_LOAD_FCT_GRP_POLICY_R_PBC_TEAM_LOOKUP	,DIM_GRP_CLAIM_DETAIL_SUBGROUP_LOOKUP
	  09-Aug-2022 : Changes in PRC_LOAD_VUE_FCT_GRP_POLICY_R
	  18-Aug-2022 : Commented AND V_SOURCE_SYSTEM_NAME_R='PACS' in procedure PRC_LOAD_FCT_GRP_POLICY_R_PBC_TEAM_LOOKUP requested by Gisha
	  27-Aug-2022 : In PRC_LOAD_VUE_FCT_GRP_POLICY_R Commented and B1.N_BATCH_ID_R=IN_BATCH_ID_R  ater discussion with Gisha to avoid missing policies
	  29-Sep-2022 : Premium Services Dim_Employee_r load changes - removed dot(.) from emp first name
	  30-Sep-2022 : FCT_GRP_AGENT_POLICY_R_LOOKUP Erica changes
	  07-Oct-2022 : Erica changes in FCT_GRP_POLICY_R_PBC_TEAM_LOOKUP requested on 07-Oct-2022
	  21-Oct-2022 : Added procedure PRC_LOAD_FCT_GRP_POLICY_R_UW_NEEDED
	  27-Oct-2022 : As requested by Erica Replaced V_ORIG_LOB_R  with CASE WHEN V_ORIG_LOB_R = 'VG' THEN 'VG' ELSE 'ZZZ' END  in SELECT and group by in PRC_LOAD_FCT_GRP_POLICY_R_PBC_TEAM_LOOKUP
	  13-Nov-2022 : As requested by Aravind on 04-Nov-2022 underlying queries has been changed in below procedures
					PRC_LOAD_FCT_BENEFIT_PMNT_DET_OFFSET1_R
					PRC_LOAD_FCT_BENEFIT_PMNT_DET_OFFSET3_R
					PRC_FULLLOAD_FCT_BENEFIT_PMNT_DET_OFFSET1_R
					PRC_FULLLOAD_FCT_BENEFIT_PMNT_DET_OFFSET3_R
	  09-Dec-2022 : Changes in Offset3 Full load query
	  04-Jan-2023 : Changes in FCT_GRP_AGENT_POLICY_R_LOOKUP
	  27-Jan-2023 : Changes in FCT_GRP_POLICY_R_PBC_TEAM_LOOKUP
	  02-Mar-2023 : Changes in DIM_GRP_CLAIM_DETAIL_SUBGROUP_LOOKUP
	  17-Mar-2023 : Changes in FCT_GRP_POLICY_R_PBC_TEAM_LOOKUP
	  19-Apr-2023 : Changes in PRC_LOAD_DIM_GRP_CLAIM_DETAIL_SUBGROUP_LOOKUP SELECT query
	  22-Aug-2023 : Changes in PRC_LOAD_FCT_GRP_POLICY_R_PBC_TEAM_LOOKUP requested by Erica SELECT query
	  13-Nov-2023 : Added PRC_LOAD_DIM_GRP_CLAIM_DETAIL_SUBGROUP_LOOKUP_CV
	  16-Apr-2024 : Added DISTINCT in the SELECT query and group by a.v_claim_number_r,a.V_SUBGROUP_NAME_R,a.V_OVERRIDE_NAME_R , b.V_SUBGROUP_ID_R in PRC_LOAD_DIM_GRP_CLAIM_DETAIL_SUBGROUP_LOOKUP
	  31-jUL-2024 : replaced APPEND with APPEND_VALUES nad added gather stats for FCT_GRP_POLICY_R_UW_NEEDED
	  19-Aug-2024 : As requested by erica below changes applied.
					All references to  and UPPER(trim(a.V_COMMISSION_TYPE_R))  in ('COMMISSION','OVERRIDE')
					Should be updated to and UPPER(trim(a.V_COMMISSION_TYPE_R))  in ('COMMISSION')
	  20-Aug-2024   : Added join with policy prefix bridge table

	  11-DEC-2024 : Added v_template_name_r in FCT_GRP_AGENT_POLICY_R_LOOKUP requested by gisha.

	  15-JAN-2025 : Added N_LAST_RATE_R in FCT_GRP_AGENT_POLICY_R_LOOKUP requested by gisha.

      28-JAN-2025 : Added V_TEMPLATE_NAME_R_1 in FCT_GRP_AGENT_POLICY_R_LOOKUP requested by gisha.
      31-JAN-2025 : Comment and replace code as requested by Gisha .TO_NUMBER(nvl(SUBSTR(V_TEMPLATE_NAME_R, INSTR(V_TEMPLATE_NAME_R, '-') + 1, INSTR(V_TEMPLATE_NAME_R, '%') - INSTR(V_TEMPLATE_NAME_R, '-') - 1),0)) / 100  -- 31-01-2025 added as per rounding issue.
	  26-Aug-2025 : Commented out name columns in DIM_EMPLOYEE_R merge statement. User Story 439134: Claims - DIM_EMPLOYEE duplicates permanent solution
      23-OCT-2025 : Added new_corp_year parameter to PRC_LOAD_DIM_TIME_R  (Devops #455190)

	------------------------------------------------------------------------------------------------------------------------------------
	* Change log : This package having dependency on the below tables
	FCT_RPT_POSTED_SUSPENSE_R
	-------------------------
	FCT_BILLING_POLICY_SUSPENSE_R
	FCT_RPT_POSTED_SUSPENSE_R
	PRCS_GRP_DATAINGESTION_PARAM_R

	DIM_TIME_R
	----------
	DIM_TIME_R
	DIM_DATES
	STG_FISCAL_CLOSING_DATE_R
	STG_RSL_HOLIDAY_R

	FCT_RPT_POSTED_SUSPENSE_R
	-------------------------
	ATOMIC.DIM_GRP_POLICY_DIR_R
	PRCS_GRP_DATAINGESTION_PARAM_R

	DIM_EMPLOYEE_R
	--------------
	DIM_EMPLOYEE_R_TEMP

	STG_CLAIMS_HIERARCHY_R
	DIM_GRP_SYSUSESO_R

	STG_PBC_RSO_TEAM_R

	DIM_GRP_SALES_REPRESENTATIVE_R
	DIM_GRP_SALES_REP_LEVEL_R
	DIM_GRP_FIELD_OFFICE_R
	STG_RSO_TO_REGION_R

	STG_UW_HIERARCHY_R

	PRC_LOAD_VUE_FCT_GRP_POLICY_R
	-----------------------------
	FCT_GRP_POLICY_R
	DIM_GRP_POLICY_DIR_R
	FCT_GRP_BILLING_POLICY_DTL_R
	DIM_GRP_PARTY_DIR_R
	STG_PBC_RSO_TEAM_R
	DIM_GRP_MTOPTION_R
	DIM_GRP_UDFIELD_R
	FCT_BILLING_POLICY_PREMIUM_R

	PRC_LOAD_FCT_GRP_POLICY_R_PBC_TEAM_LOOKUP
	-----------------------------
	FCT_GRP_POLICY_R
	DIM_GRP_POLICY_DIR_R
	DIM_GRP_PARTY_DIR_R
	STG_PBC_RSO_TEAM_R
	DIM_GRP_UDFIELD_R
	DIM_GRP_MTOPTION_R
	FCT_GRP_BILLING_POLICY_DTL_R
	FCT_BILLING_POLICY_PREMIUM_R
	DIM_GRP_WRKFLW_ACTIVITY_DTLS_R

	DIM_GRP_CLAIM_DETAIL_SUBGROUP_LOOKUP
	-----------------------------
	DIM_GRP_CLAIM_DIR_R
	FCT_GRP_POLICY_R
	DIM_GRP_PARTY_DIR_R
	DIM_GRP_CUST_ENTITYSUBGROUP_R
	DIM_GRP_ENTITYLOCATION_R

	FCT_GRP_POLICY_R_UW_NEEDED
	--------------------------
	fct_grp_policy_r
	DIM_GRP_POLICY_DIR_R


	Shiva		18-May-2026		Kill/Fill Changes: User Story -
								- All code changes are marked with Kill/Fill start and end comment blocks.
								- Code changes ensure continuous data availability in reports, replacing the current truncate-and-load approach, which is not partition-exchange based.
								- Retaining old code base of bulk collect load; which can be used when this Package to be converted to incremental processing
								- Added Coding Standarisation; formatted the code

	*********************************************************************************************************************************** */
	as
	-- This procedure loads FCT_RPT_POSTED_SUSPENSE_R
PROCEDURE PRC_LOAD_FCT_RPT_POSTED_SUSP_R(
		IN_BATCH_ID_R        IN NUMBER,
		IN_MAX_LOAD_RUN_ID_R IN NUMBER,
		OUT_LOAD_STATUS      OUT VARCHAR2
		)
	IS
	  LN_N_BATCH_ID_R        NUMBER := IN_BATCH_ID_R;
	  LN_N_LOAD_RUN_ID_R NUMBER := IN_MAX_LOAD_RUN_ID_R;
	  LN_MAX_SEQ_NUMER_R   NUMBER;
	  LC_SQLCODE           VARCHAR2(4000);
	  LC_SQLERRM           VARCHAR2(4000);
	  lt_systimestamp timestamp := SYSTIMESTAMP;
	  lv_message_type_r  PRCS_JOB_LOG_MESSAGE_R.v_message_type_r%TYPE:= PKG_GRP_LOG_UTIL.gc_message_type_info;

BEGIN
	gc_main_loadedby :='PKG_LOAD_GRP_TABLES.PRC_LOAD_FCT_RPT_POSTED_SUSP_R';

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

	gc_trcmsg:='1. Entered into PRC_LOAD_FCT_RPT_POSTED_SUSP_R ';
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




	gc_trcmsg:='2.Started data to insert into FCT_RPT_POSTED_SUSPENSE_R';
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

	SELECT NVL(MAX(N_SEQUENCE_NUMBER_R),0) INTO LN_MAX_SEQ_NUMER_R
	FROM ATOMIC.FCT_RPT_POSTED_SUSPENSE_R;
	INSERT /*+APPEND_VALUES*/ INTO ATOMIC.FCT_RPT_POSTED_SUSPENSE_R
	(N_SUSPENSE_PREMIUM_ID_R
	,V_POLICY_NUMBER_R
	,V_BILL_GROUP_NUMBER_R
	,D_DUE_DATE_R
	,D_POSTED_DATE_R
	,N_SUSPENSE_AMOUNT_R
	,V_SUSPENSE_DESCRIPTION_R
	,V_SUSPENSE_OPERATOR_ID_R
	,D_SUSPENSE_DATE_R
	,N_PROCESS_DAYS_R
	,N_BATCH_ID_R
	,N_LOAD_RUN_ID_R
	,N_SEQUENCE_NUMBER_R
	,T_CREATION_DATE_R
	,T_EVENT_TIMESTAMP_R
	,T_LAST_MODIFIED_DATE_R
	,V_CREATED_BY_R
	,V_LAST_MODIFIED_BY_R
	,D_CYCLE_DATE_R
	,FIC_MIS_DATE_R
	,N_PARTY_SK_R
	,N_QUOTE_SK_R
	)
	SELECT /*+enable_parallel_dml parallel(8)*/
	 FBPSR.N_SRC_SUSPENSE_PREMIUM_ID_R N_SUSPENSE_PREMIUM_ID_R
	,(SELECT DIM_GRP_POLICY_R.V_POLICY_NUMBER_R
		FROM ATOMIC.DIM_GRP_POLICY_DIR_R DIM_GRP_POLICY_R
	   WHERE ATOMIC.DIM_GRP_POLICY_R.N_POLICY_SK_R = FBPSR.N_POLICY_SK_R
	  ) V_POLICY_NUMBER_R --EDW_TR_001
	,v_billgroup_number_r V_BILL_GROUP_NUMBER_R
	,FBPSR.D_DUE_DATE_R
	,FBPSR.D_DELETE_DATE_R     D_POSTED_DATE_R
	,TO_CHAR(FBPSR.N_AMOUNT_R, '999999999999.99') N_SUSPENSE_AMOUNT_R
	,SUBSTR(TRANSLATE(TRANSLATE(TRANSLATE(FBPSR.V_DESCRIPTION_R, '~', ' '), '"', ' '), chr(13)||chr(10)||chr(9), ' '), 1, 200) V_SUSPENSE_DESCRIPTION_R
	,(CASE WHEN UPPER(FBPSR.V_DELETE_BY_R) LIKE  '%ONLINE%' THEN '869'
	 WHEN  UPPER(FBPSR.V_DELETE_BY_R) LIKE 'ONLINE%' THEN '869'
	 WHEN  UPPER(FBPSR.V_DELETE_BY_R) LIKE '%BILLING%' THEN '869'
	 WHEN  UPPER(FBPSR.V_DELETE_BY_R) LIKE '%BILLING' THEN '869'
	 WHEN  UPPER(FBPSR.V_DELETE_BY_R) LIKE '%OBS%' THEN '869'
	 WHEN  FBPSR.V_USER_NAME_R IS NOT NULL THEN  FBPSR.V_USER_NAME_R
	ELSE '000'
	end) V_SUSPENSE_OPERATOR_ID_R
	,FBPSR.D_INSERT_DATE_R     D_SUSPENSE_DATE_R
	,(SELECT count(1)
	  FROM ATOMIC.DIM_TIME_R DT
	  WHERE DT.D_CALENDAR_DATE_R BETWEEN TRUNC(SYSDATE) and TRUNC(FBPSR.D_DELETE_DATE_R)
			AND DT.v_BUSINESS_DAY_IND_R = 'Y' AND DT.v_PREMIUM_DEAD_DAY_IND_R = 'N')  N_PROCESS_DAYS_R--PS_TR_002
	,LN_N_BATCH_ID_R
	,LN_N_LOAD_RUN_ID_R
	,( nvl(LN_MAX_SEQ_NUMER_R,0)+rownum) N_SEQUENCE_NUMBER_R
	,LT_systimestamp      T_CREATION_DATE_R
	,LT_systimestamp      T_EVENT_TIMESTAMP_R
	,LT_systimestamp      T_LAST_MODIFIED_DATE_R
	,'ODI'             V_CREATED_BY_R
	,'ODI'             V_LAST_MODIFIED_BY_R
	,TRUNC(SYSDATE)            D_CYCLE_DATE_R
	,to_date(substr(LN_N_BATCH_ID_R,1,8),'YYYYMMDD') FIC_MIS_DATE_R
	,-1 --need to change
	,-1 --need to change
	FROM ATOMIC.FCT_BILLING_POLICY_SUSPENSE_R FBPSR
	WHERE
	  --PS_TR_001 Starts
		TRUNC(FBPSR.D_DELETE_DATE_R) = TRUNC(SYSDATE)-1 --PS_TR_001->1
	  AND FBPSR.N_AMOUNT_R <> 0                       --PS_TR_001->2
	  AND NOT EXISTS (SELECT 1
						FROM ATOMIC.FCT_RPT_POSTED_SUSPENSE_R FRPSR
					   WHERE FRPSR.N_SUSPENSE_PREMIUM_ID_R = FBPSR.N_SRC_SUSPENSE_PREMIUM_ID_R
					  )                               --PS_TR_001->3
	--PS_TR_001->4 start
	and (CASE WHEN UPPER(FBPSR.V_DELETE_BY_R) LIKE  '%ONLINE%' THEN '869'
	 WHEN  UPPER(FBPSR.V_DELETE_BY_R) LIKE 'ONLINE%' THEN '869'
	 WHEN  UPPER(FBPSR.V_DELETE_BY_R) LIKE '%BILLING%' THEN '869'
	 WHEN  UPPER(FBPSR.V_DELETE_BY_R) LIKE '%BILLING' THEN '869'
	 WHEN  UPPER(FBPSR.V_DELETE_BY_R) LIKE '%OBS%' THEN '869'
	 WHEN  FBPSR.V_USER_NAME_R IS NOT NULL THEN  FBPSR.V_USER_NAME_R
	ELSE '000'
	end)= ( select V_SUSPENSE_OPERATOR_ID_R_1
			 from
			(SELECT MIN(V_SUSPENSE_OPERATOR_ID_R_1) V_SUSPENSE_OPERATOR_ID_R_1,N_SRC_SUSPENSE_PREMIUM_ID_R_1,D_DELETE_DATE_R_1
			FROM
			(SELECT  (CASE WHEN UPPER(FBPSR1.V_DELETE_BY_R) LIKE  '%ONLINE%' THEN '869'
			  WHEN  UPPER(FBPSR1.V_DELETE_BY_R) LIKE 'ONLINE%' THEN '869'
			  WHEN  UPPER(FBPSR1.V_DELETE_BY_R) LIKE '%BILLING%' THEN '869'
			  WHEN  UPPER(FBPSR1.V_DELETE_BY_R) LIKE '%BILLING' THEN '869'
			  WHEN  UPPER(FBPSR1.V_DELETE_BY_R) LIKE '%OBS%' THEN '869'
			  WHEN  FBPSR1.V_USER_NAME_R IS NOT NULL THEN  FBPSR1.V_USER_NAME_R
			 ELSE '000'
			 END) V_SUSPENSE_OPERATOR_ID_R_1,FBPSR1.N_SRC_SUSPENSE_PREMIUM_ID_R N_SRC_SUSPENSE_PREMIUM_ID_R_1
			 ,FBPSR1.D_DELETE_DATE_R D_DELETE_DATE_R_1
			FROM ATOMIC.FCT_BILLING_POLICY_SUSPENSE_R FBPSR1
			WHERE  TRUNC(FBPSR1.D_DELETE_DATE_R) = TRUNC(SYSDATE)-1 --PS_TR_001->1
			  AND FBPSR1.N_AMOUNT_R <> 0                       --PS_TR_001->2
			  AND NOT EXISTS (SELECT 1
								FROM ATOMIC.FCT_RPT_POSTED_SUSPENSE_R FRPSR1
							   WHERE FRPSR1.N_SUSPENSE_PREMIUM_ID_R = FBPSR1.N_SRC_SUSPENSE_PREMIUM_ID_R
							 )                               --PS_TR_001->3
			GROUP BY (CASE WHEN UPPER(FBPSR1.V_DELETE_BY_R) LIKE  '%ONLINE%' THEN '869'
			  WHEN  UPPER(FBPSR1.V_DELETE_BY_R) LIKE 'ONLINE%' THEN '869'
			  WHEN  UPPER(FBPSR1.V_DELETE_BY_R) LIKE '%BILLING%' THEN '869'
			  WHEN  UPPER(FBPSR1.V_DELETE_BY_R) LIKE '%BILLING' THEN '869'
			  WHEN  UPPER(FBPSR1.V_DELETE_BY_R) LIKE '%OBS%' THEN '869'
			  WHEN  FBPSR1.V_USER_NAME_R IS NOT NULL THEN  FBPSR1.V_USER_NAME_R
			 ELSE '000'
			 END) ,FBPSR1.N_SRC_SUSPENSE_PREMIUM_ID_R,FBPSR1.D_DELETE_DATE_R
		   )
		   GROUP BY N_SRC_SUSPENSE_PREMIUM_ID_R_1,D_DELETE_DATE_R_1
		   ) FBPSR2
		   WHERE FBPSR2.N_SRC_SUSPENSE_PREMIUM_ID_R_1=FBPSR.N_SRC_SUSPENSE_PREMIUM_ID_R
			 AND FBPSR2.D_DELETE_DATE_R_1 = FBPSR.D_DELETE_DATE_R
			)
	--PS_TR_001->4 end
	;

	commit;

	gc_trcmsg:='3.Completed data insertion into FCT_RPT_POSTED_SUSPENSE_R';
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
	gc_trcmsg:='1. Exit from PRC_LOAD_FCT_RPT_POSTED_SUSP_R ';
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
	DBMS_OUTPUT.PUT_LINE('FCT_RPT_POSTED_SUSPENSE_R  EXCEPTION WITH ERROR CODE AS '
				 || SQLCODE
				 || ' '
				 || SQLERRM
				 || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
				 ||'FCT_RPT_POSTED_SUSPENSE_R'
				 ||';');

	gc_errmsg :=SUBSTR(SQLERRM,1,4000);
    gc_trcmsg:='1.z Error in PRC_LOAD_FCT_RPT_POSTED_SUSP_R: '||gc_errmsg;

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

    RAISE_APPLICATION_ERROR(-20001,'Error in PKG_LOAD_GRP_TABLES.PRC_LOAD_FCT_RPT_POSTED_SUSP_R:->
    Error Code:'||LC_SQLCODE||',Error message:'||LC_SQLERRM);

	END PRC_LOAD_FCT_RPT_POSTED_SUSP_R;

	-- This procedure loads DIM_TIME_R
	PROCEDURE PRC_LOAD_DIM_TIME_R(
		IN_BATCH_ID_R        IN NUMBER,
		IN_MAX_LOAD_RUN_ID_R IN NUMBER,
		IN_NEW_YEAR_R        IN NUMBER  DEFAULT NULL
		)
	IS
    -- #455190 - dt 20251023
	cursor c1 is
		select * from ATOMIC.DIM_DATES
        where N_DATE_SKEY not in (-1,0,19000101,99991231)                   --N_MONTH_CALENDAR=1 and  N_YEAR_CALENDAR=2021
                AND  N_YEAR_CALENDAR>= NVL(IN_NEW_YEAR_R, N_YEAR_CALENDAR)
		;


	p_incr_date	DATE;
	l_incr_date	DATE;
	p_year	VARCHAR2(4);
	p_month	VARCHAR2(2);
	p_quarter	VARCHAR2(1);
	L_D_CLOSING_DATE_R_CORP	DATE;
	l_fiscal_month_CORP	VARCHAR2(2);
	l_fiscal_month_name_CORP	VARCHAR2(3);
	l_fiscal_quarter_CORP	VARCHAR2(1);
	l_fiscal_year_CORP	VARCHAR2(4);
	v_end_of_fiscal_month_ind_r	VARCHAR2(1);
	V_END_OF_FISCAL_QUARTER_IND_R	VARCHAR2(1);
	V_END_OF_FISCAL_YEAR_IND_R	VARCHAR2(1);
	L_D_CLOSING_DATE_R_CAS	DATE;
	l_fiscal_month_CAS	VARCHAR2(2);
	l_fiscal_month_name_CAS	VARCHAR2(3);
	l_fiscal_quarter_CAS	VARCHAR2(1);
	l_fiscal_year_CAS	VARCHAR2(4);
	v_end_of_CLAIMS_month_ind_r	VARCHAR2(1);
	L_HOLIDAY_IND	VARCHAR2(1);
	v_holiday_count	NUMBER;
	L_BUSINESS_DAY_IND	VARCHAR2(1);
	l_day_of_month	VARCHAR2(2);
	l_mid_month_date	DATE;
	l_mid_month_ind	VARCHAR2(1):='N';
	l_month_before	VARCHAR2(2);
	l_month_after	VARCHAR2(2);
	l_last_day_ind	VARCHAR2(1);
	l_b_days_count_004	NUMBER:=null;
	l_b_days_count_005	NUMBER:=null;
	l_date	DATE;
	l_end_of_quarter_ind	VARCHAR2(1);
	l_end_of_year_ind	VARCHAR2(1);
	l_premium_dead_day_count	NUMBER;
	l_premium_dead_day_ind	VARCHAR2(1):='N';
	l_sequence_number NUMBER;
	lv_message_type_r  PRCS_JOB_LOG_MESSAGE_R.v_message_type_r%TYPE:= PKG_GRP_LOG_UTIL.gc_message_type_info;
	begin
	gc_main_loadedby :='PKG_LOAD_GRP_TABLES.PRC_LOAD_DIM_TIME_R';

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

		gc_trcmsg:='1. Entered into PRC_LOAD_DIM_TIME_R ';

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



--	select count(1)+1 into l_sequence_number from ATOMIC.dim_time_r;
    select max(N_SEQUENCE_NUMBER_R)+1 into l_sequence_number from ATOMIC.dim_time_r;

	for rec1 in c1 loop

        p_incr_date		:= rec1.D_CALENDAR_DATE;
        l_incr_date		:= p_incr_date;
        p_year			:= TO_CHAR(p_incr_date, 'YYYY');
        p_month			:= TO_CHAR(p_incr_date, 'MM');
        p_quarter		:= TO_CHAR(p_incr_date, 'Q');

        --------------------------------------------------------------------------------------------------------------------------------
        /*TD_TR_008*/
            begin
                SELECT fd.D_CLOSING_DATE_R,
                 TO_CHAR(fd.D_CLOSING_DATE_R, 'MM')   fiscal_month,
                 TO_CHAR(fd.D_CLOSING_DATE_R, 'MON')  fiscal_month_name,
                 TO_CHAR(fd.D_CLOSING_DATE_R, 'Q')    fiscal_quarter,
                 TO_CHAR(fd.D_CLOSING_DATE_R, 'YYYY') fiscal_year
                 into L_D_CLOSING_DATE_R_CORP,
                 l_fiscal_month_CORP,
                 l_fiscal_month_name_CORP,
                 l_fiscal_quarter_CORP,
                 l_fiscal_year_CORP
                FROM ATOMIC.STG_FISCAL_CLOSING_DATE_R fd
               WHERE p_incr_date BETWEEN ( SELECT MAX(D_CLOSING_DATE_R) + 1 FROM ATOMIC.STG_FISCAL_CLOSING_DATE_R fd1
                                              WHERE fd1.D_CLOSING_DATE_R <  fd.D_CLOSING_DATE_R
                                                AND V_APPLICATION_R = 'CORP')
                                       AND ( SELECT MIN(D_CLOSING_DATE_R)  FROM ATOMIC.STG_FISCAL_CLOSING_DATE_R fd2
                                              WHERE fd2.D_CLOSING_DATE_R >=  fd.D_CLOSING_DATE_R AND V_APPLICATION_R ='CORP')
               AND V_APPLICATION_R = 'CORP';
            exception
                when others then
                L_D_CLOSING_DATE_R_CORP := null;
                l_fiscal_month_CORP		:= null;
                l_fiscal_month_name_CORP:= null;
                l_fiscal_quarter_CORP	:= null;
                l_fiscal_year_CORP		:= null;
            end;

        If L_D_CLOSING_DATE_R_CORP  = p_incr_date then
            v_end_of_fiscal_month_ind_r := 'Y' ;
        else
            v_end_of_fiscal_month_ind_r := 'N';
        end if;

        if TO_CHAR(L_D_CLOSING_DATE_R_CORP, 'MM') in (3,6,9,12) and L_D_CLOSING_DATE_R_CORP  = p_incr_date then
            V_END_OF_FISCAL_QUARTER_IND_R := 'Y';
        else
            V_END_OF_FISCAL_QUARTER_IND_R := 'N';
        end if;

        if TO_CHAR(L_D_CLOSING_DATE_R_CORP, 'MM') = 12 and L_D_CLOSING_DATE_R_CORP  = p_incr_date then
            V_END_OF_FISCAL_YEAR_IND_R := 'Y';
        else
            V_END_OF_FISCAL_YEAR_IND_R := 'N';
        end if;

        ----------------------------------------------------------------

        /*TD_TR_009*/
            begin
                SELECT fd.D_CLOSING_DATE_R,
                 TO_CHAR(fd.D_CLOSING_DATE_R, 'MM')   fiscal_month,
                 TO_CHAR(fd.D_CLOSING_DATE_R, 'MON')  fiscal_month_name,
                 TO_CHAR(fd.D_CLOSING_DATE_R, 'Q')    fiscal_quarter,
                 TO_CHAR(fd.D_CLOSING_DATE_R, 'YYYY') fiscal_year
                 into L_D_CLOSING_DATE_R_CAS,
                 l_fiscal_month_CAS,
                 l_fiscal_month_name_CAS,
                 l_fiscal_quarter_CAS,
                 l_fiscal_year_CAS
                FROM ATOMIC.STG_FISCAL_CLOSING_DATE_R fd
               WHERE p_incr_date BETWEEN ( SELECT MAX(D_CLOSING_DATE_R) + 1 FROM ATOMIC.STG_FISCAL_CLOSING_DATE_R fd1
                                              WHERE fd1.D_CLOSING_DATE_R <  fd.D_CLOSING_DATE_R
                                                AND V_APPLICATION_R = 'CAS')
                                       AND ( SELECT MIN(D_CLOSING_DATE_R)  FROM ATOMIC.STG_FISCAL_CLOSING_DATE_R fd2
                                              WHERE fd2.D_CLOSING_DATE_R >=  fd.D_CLOSING_DATE_R AND V_APPLICATION_R ='CAS')
               AND V_APPLICATION_R = 'CAS';

            exception
                when others then
                 L_D_CLOSING_DATE_R_CAS	:= null;
                 l_fiscal_month_CAS	:= null;
                 l_fiscal_month_name_CAS	:= null;
                 l_fiscal_quarter_CAS	:= null;
                 l_fiscal_year_CAS	:= null;

            end;

        If L_D_CLOSING_DATE_R_CAS  = p_incr_date then
            v_end_of_CLAIMS_month_ind_r := 'Y';
        else
            v_end_of_CLAIMS_month_ind_r := 'N';
        end if;


        ----------------------------------------------------------------
        /*TD_TR_001*/
        SELECT count(1)
             INTO v_holiday_count
             FROM ATOMIC.STG_RSL_HOLIDAY_R
            WHERE d_holiday_date_r = l_incr_date;

           IF v_holiday_count > 0 THEN
              l_holiday_ind := 'Y';
           ELSE
              l_holiday_ind := 'N';
           END IF;

        IF rec1.N_DAY_OF_WEEK in (2,3,4,5,6) and  l_holiday_ind = 'N' THEN
            L_BUSINESS_DAY_IND := 'Y';
        ELSE
            L_BUSINESS_DAY_IND := 'N';
        end if;

        ----------------------------------------------------------------
        /*TD_TR_003*/
           l_incr_date    := p_incr_date;

           l_month_before := TO_CHAR(l_incr_date, 'MM');

           l_incr_date    := l_incr_date + 1;

           l_month_after  := TO_CHAR(l_incr_date, 'MM');

           IF l_month_before = l_month_after THEN
              l_last_day_ind := 'N';
           ELSE
              l_last_day_ind := 'Y';
           END IF;

        ----------------------------------------------------------------

        /*TD_TR_006*/	l_incr_date    := p_incr_date;
            SELECT MAX(D_CALENDAR_DATE)
             INTO l_date
             FROM ATOMIC.DIM_DATES
            WHERE TO_CHAR(D_CALENDAR_DATE, 'YYYY') = p_year
              AND TO_CHAR(D_CALENDAR_DATE, 'Q') = p_quarter;

           IF l_incr_date = l_date THEN
              l_end_of_quarter_ind := 'Y';
           ELSE
              l_end_of_quarter_ind := 'N';
           END IF;

        ----------------------------------------------------------------

        /*TD_TR_007*/
           l_incr_date    := p_incr_date;

           SELECT MAX(D_CALENDAR_DATE)
             INTO l_date
             FROM ATOMIC.DIM_DATES
            WHERE TO_CHAR(D_CALENDAR_DATE, 'YYYY') = p_year;

           IF l_incr_date = l_date THEN
              l_end_of_year_ind := 'Y';
           ELSE
              l_end_of_year_ind := 'N';
           END IF;

        --------------------------------------------------------------------------------------------------------------------------------

        gc_trcmsg:='2.Started Merging data into table DIM_TIME_R';
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

        merge into DIM_TIME_R TARGET using
            (select DIM_DATES.N_DATE_SKEY	as N_DATE_SK_R,
                    DIM_DATES.D_CALENDAR_DATE	as D_CALENDAR_DATE_R,
                    TO_CHAR(DIM_DATES.D_CALENDAR_DATE, 'D')	as N_DAY_OF_WEEK_R,
                    TO_CHAR(DIM_DATES.D_CALENDAR_DATE, 'Day')	as V_DAY_NAME_R,
                    TO_CHAR(DIM_DATES.D_CALENDAR_DATE, 'DD')	as N_DAY_OF_MONTH_R,
                    TO_CHAR(DIM_DATES.D_CALENDAR_DATE, 'DDD')	as N_DAY_OF_YEAR_R,
                    L_BUSINESS_DAY_IND	as V_BUSINESS_DAY_IND_R,
                    L_HOLIDAY_IND	as V_HOLIDAY_IND_R,
                    l_mid_month_ind	as V_MID_MONTH_IND_R,
                    TO_CHAR(DIM_DATES.D_CALENDAR_DATE, 'WW')	as N_WEEK_OF_YEAR_R,
                    TO_CHAR(DIM_DATES.D_CALENDAR_DATE, 'MM')	as N_MONTH_R,
                    TO_CHAR(DIM_DATES.D_CALENDAR_DATE, 'MON')	as V_MONTH_NAME_R,
                    l_last_day_ind	as V_END_OF_MONTH_IND_R,
                    l_b_days_count_004	as N_BUSINESS_DAYS_IN_MONTH_R,
                    TO_CHAR(DIM_DATES.D_CALENDAR_DATE, 'Q')	as N_QUARTER_R,
                    l_end_of_quarter_ind	as V_END_OF_QUARTER_IND_R,
                    TO_CHAR(DIM_DATES.D_CALENDAR_DATE, 'YYYY')	as N_YEAR_R,
                    l_end_of_year_ind	as V_END_OF_YEAR_IND_R,
                    l_fiscal_month_CORP	as N_FISCAL_MONTH_R,
                    l_fiscal_month_name_CORP	as V_FISCAL_MONTH_NAME_R,
                    v_end_of_fiscal_month_ind_r	as V_END_OF_FISCAL_MONTH_IND_R,
                    l_b_days_count_005	as N_BUSINESS_DAYS_IN_FISCALMTH_R,
                    l_fiscal_quarter_CORP	as N_FISCAL_QUARTER_R,
                    V_END_OF_FISCAL_QUARTER_IND_R	as V_END_OF_FISCAL_QUARTER_IND_R,
                    l_fiscal_year_CORP	as N_FISCAL_YEAR_R,
                    V_END_OF_FISCAL_YEAR_IND_R	as V_END_OF_FISCAL_YEAR_IND_R,
                    l_fiscal_month_CAS	as N_CLAIMS_MONTH_R,
                    l_fiscal_month_name_CAS	as V_CLAIMS_MONTH_NAME_R,
                    l_fiscal_quarter_CAS	as N_CLAIMS_QUARTER_R,
                    l_fiscal_year_CAS	as N_CLAIMS_YEAR_R,
                    v_end_of_CLAIMS_month_ind_r	as V_END_OF_CLAIMS_MONTH_IND_R,
                    l_premium_dead_day_ind	as V_PREMIUM_DEAD_DAY_IND_R,
                    ''	as N_TM_FISCAL_YEAR_R,
                    ''	as N_TM_QUARTER_R,
                    ''	as V_TM_FISCAL_MONTH_NAME,
                    'ODI'	as V_CREATED_BY_R,
                    systimestamp	as T_LAST_MODIFIED_DATE_R,
                    systimestamp	as T_EVENT_TIMESTAMP_R,
                    systimestamp	as T_CREATION_DATE_R,
                    l_sequence_number	as N_SEQUENCE_NUMBER_R,
                    /*'201012310000'*/IN_BATCH_ID_R	as N_BATCH_ID_R,
                    to_date(substr(IN_BATCH_ID_R,1,8),'YYYYMMDD') as FIC_MIS_DATE_R,
                    'ODI'	as V_LAST_MODIFIED_BY_R
              FROM ATOMIC.DIM_DATES
              WHERE D_CALENDAR_DATE = p_incr_date) SOURCE
        ON (TARGET.N_DATE_SK_R = SOURCE.N_DATE_SK_R)
        WHEN MATCHED THEN
            UPDATE SET
                    TARGET.D_CALENDAR_DATE_R = SOURCE.D_CALENDAR_DATE_R,
                    TARGET.N_DAY_OF_WEEK_R = SOURCE.N_DAY_OF_WEEK_R,
                    TARGET.V_DAY_NAME_R = SOURCE.V_DAY_NAME_R,
                    TARGET.N_DAY_OF_MONTH_R = SOURCE.N_DAY_OF_MONTH_R,
                    TARGET.N_DAY_OF_YEAR_R = SOURCE.N_DAY_OF_YEAR_R,
                    TARGET.V_BUSINESS_DAY_IND_R = SOURCE.V_BUSINESS_DAY_IND_R,
                    TARGET.V_HOLIDAY_IND_R = SOURCE.V_HOLIDAY_IND_R,
                    TARGET.V_MID_MONTH_IND_R = SOURCE.V_MID_MONTH_IND_R,
                    TARGET.N_WEEK_OF_YEAR_R = SOURCE.N_WEEK_OF_YEAR_R,
                    TARGET.N_MONTH_R = SOURCE.N_MONTH_R,
                    TARGET.V_MONTH_NAME_R = SOURCE.V_MONTH_NAME_R,
                    TARGET.V_END_OF_MONTH_IND_R = SOURCE.V_END_OF_MONTH_IND_R,
                    TARGET.N_BUSINESS_DAYS_IN_MONTH_R = SOURCE.N_BUSINESS_DAYS_IN_MONTH_R,
                    TARGET.N_QUARTER_R = SOURCE.N_QUARTER_R,
                    TARGET.V_END_OF_QUARTER_IND_R = SOURCE.V_END_OF_QUARTER_IND_R,
                    TARGET.N_YEAR_R = SOURCE.N_YEAR_R,
                    TARGET.V_END_OF_YEAR_IND_R = SOURCE.V_END_OF_YEAR_IND_R,
                    TARGET.N_FISCAL_MONTH_R = SOURCE.N_FISCAL_MONTH_R,
                    TARGET.V_FISCAL_MONTH_NAME_R = SOURCE.V_FISCAL_MONTH_NAME_R,
                    TARGET.V_END_OF_FISCAL_MONTH_IND_R = SOURCE.V_END_OF_FISCAL_MONTH_IND_R,
                    TARGET.N_BUSINESS_DAYS_IN_FISCALMTH_R = SOURCE.N_BUSINESS_DAYS_IN_FISCALMTH_R,
                    TARGET.N_FISCAL_QUARTER_R = SOURCE.N_FISCAL_QUARTER_R,
                    TARGET.V_END_OF_FISCAL_QUARTER_IND_R = SOURCE.V_END_OF_FISCAL_QUARTER_IND_R,
                    TARGET.N_FISCAL_YEAR_R = SOURCE.N_FISCAL_YEAR_R,
                    TARGET.V_END_OF_FISCAL_YEAR_IND_R = SOURCE.V_END_OF_FISCAL_YEAR_IND_R,
                    TARGET.N_CLAIMS_MONTH_R = SOURCE.N_CLAIMS_MONTH_R,
                    TARGET.V_CLAIMS_MONTH_NAME_R = SOURCE.V_CLAIMS_MONTH_NAME_R,
                    TARGET.N_CLAIMS_QUARTER_R = SOURCE.N_CLAIMS_QUARTER_R,
                    TARGET.N_CLAIMS_YEAR_R = SOURCE.N_CLAIMS_YEAR_R,
                    TARGET.V_END_OF_CLAIMS_MONTH_IND_R = SOURCE.V_END_OF_CLAIMS_MONTH_IND_R,
                    TARGET.V_PREMIUM_DEAD_DAY_IND_R = SOURCE.V_PREMIUM_DEAD_DAY_IND_R,
                    TARGET.N_TM_FISCAL_YEAR_R = SOURCE.N_TM_FISCAL_YEAR_R,
                    TARGET.N_TM_QUARTER_R = SOURCE.N_TM_QUARTER_R,
                    TARGET.V_TM_FISCAL_MONTH_NAME = SOURCE.V_TM_FISCAL_MONTH_NAME,
                    --TARGET.V_CREATED_BY_R = SOURCE.V_CREATED_BY_R,
                    TARGET.T_LAST_MODIFIED_DATE_R = SOURCE.T_LAST_MODIFIED_DATE_R,
                    TARGET.T_EVENT_TIMESTAMP_R = SOURCE.T_EVENT_TIMESTAMP_R,
                    --TARGET.T_CREATION_DATE_R = SOURCE.T_CREATION_DATE_R,
                    --TARGET.N_SEQUENCE_NUMBER_R = SOURCE.N_SEQUENCE_NUMBER_R,
                    TARGET.N_BATCH_ID_R = SOURCE.N_BATCH_ID_R,
                    TARGET.FIC_MIS_DATE_R = SOURCE.FIC_MIS_DATE_R,
                    TARGET.V_LAST_MODIFIED_BY_R = SOURCE.V_LAST_MODIFIED_BY_R
        when not matched then insert (
        N_DATE_SK_R,
        D_CALENDAR_DATE_R,
        N_DAY_OF_WEEK_R,
        V_DAY_NAME_R,
        N_DAY_OF_MONTH_R,
        N_DAY_OF_YEAR_R,
        V_BUSINESS_DAY_IND_R,
        V_HOLIDAY_IND_R,
        V_MID_MONTH_IND_R,
        N_WEEK_OF_YEAR_R,
        N_MONTH_R,
        V_MONTH_NAME_R,
        V_END_OF_MONTH_IND_R,
        N_BUSINESS_DAYS_IN_MONTH_R,
        N_QUARTER_R,
        V_END_OF_QUARTER_IND_R,
        N_YEAR_R,
        V_END_OF_YEAR_IND_R,
        N_FISCAL_MONTH_R,
        V_FISCAL_MONTH_NAME_R,
        V_END_OF_FISCAL_MONTH_IND_R,
        N_BUSINESS_DAYS_IN_FISCALMTH_R,
        N_FISCAL_QUARTER_R,
        V_END_OF_FISCAL_QUARTER_IND_R,
        N_FISCAL_YEAR_R,
        V_END_OF_FISCAL_YEAR_IND_R,
        N_CLAIMS_MONTH_R,
        V_CLAIMS_MONTH_NAME_R,
        N_CLAIMS_QUARTER_R,
        N_CLAIMS_YEAR_R,
        V_END_OF_CLAIMS_MONTH_IND_R,
        V_PREMIUM_DEAD_DAY_IND_R,
        N_TM_FISCAL_YEAR_R,
        N_TM_QUARTER_R,
        V_TM_FISCAL_MONTH_NAME,
        V_CREATED_BY_R,
        T_LAST_MODIFIED_DATE_R,
        T_EVENT_TIMESTAMP_R,
        T_CREATION_DATE_R,
        N_SEQUENCE_NUMBER_R,
        N_BATCH_ID_R,
        FIC_MIS_DATE_R,
        V_LAST_MODIFIED_BY_R
        )
        values
        (SOURCE.N_DATE_SK_R,
        SOURCE.D_CALENDAR_DATE_R,
        SOURCE.N_DAY_OF_WEEK_R,
        SOURCE.V_DAY_NAME_R,
        SOURCE.N_DAY_OF_MONTH_R,
        SOURCE.N_DAY_OF_YEAR_R,
        SOURCE.V_BUSINESS_DAY_IND_R,
        SOURCE.V_HOLIDAY_IND_R,
        SOURCE.V_MID_MONTH_IND_R,
        SOURCE.N_WEEK_OF_YEAR_R,
        SOURCE.N_MONTH_R,
        SOURCE.V_MONTH_NAME_R,
        SOURCE.V_END_OF_MONTH_IND_R,
        SOURCE.N_BUSINESS_DAYS_IN_MONTH_R,
        SOURCE.N_QUARTER_R,
        SOURCE.V_END_OF_QUARTER_IND_R,
        SOURCE.N_YEAR_R,
        SOURCE.V_END_OF_YEAR_IND_R,
        SOURCE.N_FISCAL_MONTH_R,
        SOURCE.V_FISCAL_MONTH_NAME_R,
        SOURCE.V_END_OF_FISCAL_MONTH_IND_R,
        SOURCE.N_BUSINESS_DAYS_IN_FISCALMTH_R,
        SOURCE.N_FISCAL_QUARTER_R,
        SOURCE.V_END_OF_FISCAL_QUARTER_IND_R,
        SOURCE.N_FISCAL_YEAR_R,
        SOURCE.V_END_OF_FISCAL_YEAR_IND_R,
        SOURCE.N_CLAIMS_MONTH_R,
        SOURCE.V_CLAIMS_MONTH_NAME_R,
        SOURCE.N_CLAIMS_QUARTER_R,
        SOURCE.N_CLAIMS_YEAR_R,
        SOURCE.V_END_OF_CLAIMS_MONTH_IND_R,
        SOURCE.V_PREMIUM_DEAD_DAY_IND_R,
        SOURCE.N_TM_FISCAL_YEAR_R,
        SOURCE.N_TM_QUARTER_R,
        SOURCE.V_TM_FISCAL_MONTH_NAME,
        SOURCE.V_CREATED_BY_R,
        SOURCE.T_LAST_MODIFIED_DATE_R,
        SOURCE.T_EVENT_TIMESTAMP_R,
        SOURCE.T_CREATION_DATE_R,
        SOURCE.N_SEQUENCE_NUMBER_R,
        SOURCE.N_BATCH_ID_R,
        SOURCE.FIC_MIS_DATE_R,
        SOURCE.V_LAST_MODIFIED_BY_R);
        commit;


        l_sequence_number := l_sequence_number + 1;




        /*
        dbms_output.put_line('p_incr_date: '||p_incr_date||CHR(10)||
        'l_incr_date: '||l_incr_date||CHR(10)||
        'p_year: '||p_year||CHR(10)||
        'p_month: '||p_month||CHR(10)||
        'p_quarter: '||p_quarter||CHR(10)||
        'L_D_CLOSING_DATE_R_CORP: '||L_D_CLOSING_DATE_R_CORP||CHR(10)||
        'l_fiscal_month_CORP: '||l_fiscal_month_CORP||CHR(10)||
        'l_fiscal_month_name_CORP: '||l_fiscal_month_name_CORP||CHR(10)||
        'l_fiscal_quarter_CORP: '||l_fiscal_quarter_CORP||CHR(10)||
        'l_fiscal_year_CORP: '||l_fiscal_year_CORP||CHR(10)||
        'v_end_of_fiscal_month_ind_r: '||v_end_of_fiscal_month_ind_r||CHR(10)||
        'V_END_OF_FISCAL_QUARTER_IND_R: '||V_END_OF_FISCAL_QUARTER_IND_R||CHR(10)||
        'V_END_OF_FISCAL_YEAR_IND_R: '||V_END_OF_FISCAL_YEAR_IND_R||CHR(10)||
        'L_D_CLOSING_DATE_R_CAS: '||L_D_CLOSING_DATE_R_CAS||CHR(10)||
        'l_fiscal_month_CAS: '||l_fiscal_month_CAS||CHR(10)||
        'l_fiscal_month_name_CAS: '||l_fiscal_month_name_CAS||CHR(10)||
        'l_fiscal_quarter_CAS: '||l_fiscal_quarter_CAS||CHR(10)||
        'l_fiscal_year_CAS: '||l_fiscal_year_CAS||CHR(10)||
        'v_end_of_CLAIMS_month_ind_r: '||v_end_of_CLAIMS_month_ind_r||CHR(10)||
        'v_holiday_count: '||v_holiday_count||CHR(10)||
        'L_BUSINESS_DAY_IND: '||L_BUSINESS_DAY_IND||CHR(10)||
        'l_day_of_month: '||l_day_of_month||CHR(10)||
        'l_mid_month_date: '||l_mid_month_date||CHR(10)||
        'l_mid_month_ind: '||l_mid_month_ind||CHR(10)||
        'l_month_before: '||l_month_before||CHR(10)||
        'l_month_after: '||l_month_after||CHR(10)||
        'l_last_day_ind: '||l_last_day_ind||CHR(10)||
        'l_b_days_count_004: '||l_b_days_count_004||CHR(10)||
        'l_b_days_count_005: '||l_b_days_count_005||CHR(10)||
        'l_date: '||l_date||CHR(10)||
        'l_end_of_quarter_ind: '||l_end_of_quarter_ind||CHR(10)||
        'l_end_of_year_ind: '||l_end_of_year_ind||CHR(10)||
        'l_premium_dead_day_count: '||l_premium_dead_day_count||CHR(10)||
        'l_premium_dead_day_ind: '||l_premium_dead_day_ind||CHR(10));*/

	end loop;

	----------------------------------------------------------------
		/*TD_TR_002*/



		merge into DIM_TIME_R TARGET using
		(SELECT MIN(D_CALENDAR_DATE_R)
				as D_CALENDAR_DATE_R, n_year_r, n_month_r
				FROM DIM_TIME_R
			   WHERE TO_CHAR(D_CALENDAR_DATE_R, 'DD') >= '15'
				 AND V_BUSINESS_DAY_IND_R='Y'
				 group by n_year_r, n_month_r) SOURCE
		on (source.n_year_r = target.n_year_r
				 AND source.n_month_r = target.n_month_r)
		when matched then update set TARGET.V_MID_MONTH_IND_R =
		(case when TO_CHAR(TARGET.D_CALENDAR_DATE_R, 'DD') >= 15 and TO_CHAR(TARGET.D_CALENDAR_DATE_R, 'DD') < 20 and SOURCE.D_CALENDAR_DATE_R = TARGET.D_CALENDAR_DATE_R then 'Y' else 'N' end)
        --#455190 Changes starts
			WHERE SOURCE.N_YEAR_R = TARGET.N_YEAR_R AND SOURCE.N_MONTH_R = TARGET.N_MONTH_R
			and target.N_YEAR_R>=NVL(IN_NEW_YEAR_R, target.N_YEAR_R)
        ;
	    --#455190 Changes ends
		commit;

	----------------------------------------------------------------

		/*TD_TR_004*/
				merge into DIM_TIME_R TARGET using
				(SELECT count(1) as l_b_days_count_004, N_YEAR_R, N_MONTH_R
						FROM DIM_TIME_R SOURCE
						WHERE (case when SOURCE.N_DAY_OF_WEEK_R in (2,3,4,5,6) and  SOURCE.V_HOLIDAY_IND_R = 'N' THEN 'Y' else 'N' end)= 'Y'
						group by N_YEAR_R, N_MONTH_R) SOURCE
				on ( SOURCE.N_YEAR_R = TARGET.N_YEAR_R AND SOURCE.N_MONTH_R = TARGET.N_MONTH_R)
				when matched then
                    update set TARGET.N_BUSINESS_DAYS_IN_MONTH_R = SOURCE.l_b_days_count_004
                    --#455190 Changes starts
                        WHERE SOURCE.N_YEAR_R = TARGET.N_YEAR_R AND SOURCE.N_MONTH_R = TARGET.N_MONTH_R
                            and target.N_YEAR_R>=NVL(IN_NEW_YEAR_R, target.N_YEAR_R)
                    ;
                --#455190 Changes ends


			  /*update DIM_TIME_R TARGET set N_BUSINESS_DAYS_IN_MONTH_R = (
					SELECT count(1) --into l_b_days_count_004
						FROM DIM_TIME_R SOURCE
						WHERE TO_CHAR(SOURCE.D_CALENDAR_DATE_R, 'YYYY') = TO_CHAR(TARGET.D_CALENDAR_DATE_R, 'YYYY')
						  AND TO_CHAR(SOURCE.D_CALENDAR_DATE_R, 'MM') = TO_CHAR(TARGET.D_CALENDAR_DATE_R, 'MM')
						  AND (case when SOURCE.N_DAY_OF_WEEK_R in (2,3,4,5,6) and  SOURCE.V_HOLIDAY_IND_R = 'N' THEN 'Y' else 'N' end)= 'Y');*/
			  commit;
		----------------------------------------------------------------
		/*TD_TR_005*/

				merge into DIM_TIME_R TARGET using
				(SELECT count(1) as l_b_days_count_005, N_FISCAL_YEAR_R, N_FISCAL_MONTH_R
					 FROM ATOMIC.DIM_TIME_R SOURCE
					WHERE SOURCE.V_BUSINESS_DAY_IND_R= 'Y'
					  group by N_FISCAL_YEAR_R, N_FISCAL_MONTH_R) SOURCE
				on ( SOURCE.N_FISCAL_YEAR_R = TARGET.N_FISCAL_YEAR_R AND SOURCE.N_FISCAL_MONTH_R = TARGET.N_FISCAL_MONTH_R)
				when matched then update set TARGET.N_BUSINESS_DAYS_IN_FISCALMTH_R = SOURCE.l_b_days_count_005
                    --#455190 Changes starts
                        WHERE SOURCE.N_FISCAL_YEAR_R = TARGET.N_FISCAL_YEAR_R AND SOURCE.N_FISCAL_MONTH_R = TARGET.N_FISCAL_MONTH_R
                            and target.N_YEAR_R>=NVL(IN_NEW_YEAR_R, target.N_YEAR_R)
                    ;
                --#455190 Changes ends


				/*update DIM_TIME_R TARGET set N_BUSINESS_DAYS_IN_FISCALMTH_R = (
				  SELECT count(1) --into l_b_days_count_005
					 FROM DIM_TIME_R SOURCE
					WHERE SOURCE.N_FISCAL_YEAR_R =  TO_CHAR(SOURCE.D_CALENDAR_DATE_R, 'YYYY') and TO_CHAR(SOURCE.D_CALENDAR_DATE_R, 'YYYY') = TO_CHAR(TARGET.D_CALENDAR_DATE_R, 'YYYY')
						  AND TO_CHAR(SOURCE.D_CALENDAR_DATE_R, 'MM') = TO_CHAR(TARGET.D_CALENDAR_DATE_R, 'MM')
					  AND SOURCE.N_FISCAL_MONTH_R = TO_CHAR(SOURCE.D_CALENDAR_DATE_R, 'MM')
					  AND (case when SOURCE.N_DAY_OF_WEEK_R in (2,3,4,5,6) and  SOURCE.V_HOLIDAY_IND_R = 'N' THEN 'Y' else 'N' end)= 'Y');*/
				commit;

		----------------------------------------------------------------

		/*TD_TR_010*/
				merge into DIM_TIME_R a using
				(select d_calendar_date_r, n_year_r, n_month_r
				from DIM_TIME_R
			   where v_end_of_fiscal_month_ind_r = 'Y') td1
				on (td1.n_month_r = a.n_month_r and td1.n_year_r = a.n_year_r and a.V_BUSINESS_DAY_IND_R = 'Y' and a.D_CALENDAR_DATE_r > td1.D_CALENDAR_DATE_r)
			when matched then update set V_PREMIUM_DEAD_DAY_IND_R = 'Y'
                --#455190 Changes starts
                        WHERE td1.N_YEAR_R = a.N_YEAR_R AND td1.N_MONTH_R = a.N_MONTH_R
                            and a.N_YEAR_R>=NVL(IN_NEW_YEAR_R, a.N_YEAR_R)
                    ;
                --#455190 Changes ends
			commit;

	gc_trcmsg:='3.Completed merging data into table DIM_TIME_R';
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


	EXCEPTION
	WHEN OTHERS THEN
    gc_errmsg :=SUBSTR(SQLERRM,1,4000);
    gc_trcmsg:='5.z Error in 	PRC_LOAD_DIM_TIME_R: '||gc_errmsg;

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

    RAISE_APPLICATION_ERROR(-20001,'Error in PKG_LOAD_GRP_TABLES.PRC_LOAD_DIM_TIME_R:->
    Error Code:'||SQLCODE||',Error message:'||SUBSTR(SQLERRM,1,4000));

		----------------------------------------------------------------
		end PRC_LOAD_DIM_TIME_R;



	-- This procedure loads DIM_EMPLOYEE_R
	PROCEDURE PRC_LOAD_DIM_EMPLOYEE_R(
		IN_BATCH_ID_R        IN NUMBER,
		--IN_MAX_LOAD_RUN_ID_R IN NUMBER,
		OUT_LOAD_STATUS      OUT VARCHAR2
		)
	IS
	  LN_N_BATCH_ID_R        NUMBER := IN_BATCH_ID_R;
	  --LN_N_BATCH_ID_R        NUMBER := TO_NUMBER(TO_CHAR(SYSDATE,'YYYYMMDD'));
	  --LN_N_LOAD_RUN_ID_R NUMBER := IN_MAX_LOAD_RUN_ID_R;
	  LN_MAX_SEQ_NUMER_R   NUMBER;
	  LC_SQLCODE           VARCHAR2(4000);
	  LC_SQLERRM           VARCHAR2(4000);
	  lt_systimestamp timestamp := SYSTIMESTAMP;
	  LC_SOURCE_CONCEPT    VARCHAR2(4000);
	lv_message_type_r  PRCS_JOB_LOG_MESSAGE_R.v_message_type_r%TYPE:= PKG_GRP_LOG_UTIL.gc_message_type_info;
	BEGIN

	gc_main_loadedby :='PKG_LOAD_GRP_TABLES.PRC_LOAD_DIM_EMPLOYEE_R';

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

		gc_trcmsg:='1. Entered into PRC_LOAD_DIM_EMPLOYEE_R  ';


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

		IF LN_N_BATCH_ID_R IS NULL THEN
		  OUT_LOAD_STATUS:='0) BatchID(IN_BATCH_ID) is null hence terminating the program';
		 RETURN;
		END IF;

		BEGIN
		--V_GROUP_R CONTAINS CONCEPT VALUES SEPARATED WITH COMMA (EX: 'CLAIMS,PREMIUM SERVICES') etc
		--for all the conncepts the value should be 'ALL'
		SELECT V_GROUP_R INTO LC_SOURCE_CONCEPT
		FROM ATOMIC.PRCS_GRP_DATAINGESTION_PARAM_R
		WHERE V_PARAM_NAME_R='GRP_LOAD_DIM_EMPLOYEE_R';
		EXCEPTION
		WHEN OTHERS THEN
		LC_SOURCE_CONCEPT:='ALL';
		END;

		IF LC_SOURCE_CONCEPT IS NULL THEN
		   LC_SOURCE_CONCEPT:='ALL';
		END IF;

		SELECT NVL(MAX(N_SEQUENCE_NUMBER_R),0) INTO LN_MAX_SEQ_NUMER_R
		FROM ATOMIC.DIM_EMPLOYEE_R;
		BEGIN
		--EXECUTE IMMEDIATE 'DROP TABLE ATOMIC.DIM_EMPLOYEE_R_TEMP';--05-OCT-2021
		gc_trcmsg:='2. Started Truncation Partition for partition name OFFSET1 for procedure PRC_LOAD_DIM_EMPLOYEE_R for table DIM_EMPLOYEE_R_TEMP';
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
		EXECUTE IMMEDIATE 'TRUNCATE TABLE ATOMIC.DIM_EMPLOYEE_R_TEMP';--05-OCT-2021
		gc_trcmsg:='3. Completed Truncation Partition for partition name OFFSET1 for procedure PRC_LOAD_DIM_EMPLOYEE_R for table DIM_EMPLOYEE_R_TEMP';
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
		EXCEPTION
		WHEN OTHERS THEN
		NULL;
		END;
		/*BEGIN
		EXECUTE IMMEDIATE 'CREATE TABLE ATOMIC.DIM_EMPLOYEE_R_TEMP AS SELECT * FROM ATOMIC.DIM_EMPLOYEE_R WHERE 1=2';
		EXCEPTION
		WHEN OTHERS THEN
		NULL;
		END;
		*/--05-OCT-2021

		SAVEPOINT SP1;
		IF LC_SOURCE_CONCEPT = 'ALL' OR LC_SOURCE_CONCEPT LIKE '%CLAIMS%' THEN
		-- Claim Data Load Starts
		BEGIN




		gc_trcmsg:='4.Started data to insert into DIM_EMPLOYEE_R_TEMP';
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

		INSERT  /*+APPEND_VALUES*/  INTO ATOMIC.DIM_EMPLOYEE_R_TEMP
			(
			N_EMPLOYEE_SK_R                       --Populate Skey
			,V_BUSINESS_UNIT_R                       --Populate with "Claims"
			,V_EMPLOYEE_FIRST_NAME_R               --trim(substr(DIM_GRP_SYSUSESO_R.V_DESCRIPTION_R,instr(DIM_GRP_SYSUSESO_R.V_DESCRIPTION_R,' ',1,1),instr(DIM_GRP_SYSUSESO_R.V_DESCRIPTION_R,' ',1,1))) Derive first name from name field Name format: Lastname, Firstname M.; Join on V_EXAMINER_FULL_NAME_R from the hierarchy file (STG_CLAIMS_HIERARCHY_R)
			,V_EMPLOYEE_MIDDLE_NAME_R              --trim(substr(DIM_GRP_SYSUSESO_R.V_DESCRIPTION_R,instr(DIM_GRP_SYSUSESO_R.V_DESCRIPTION_R,' ',1,2))) Derive middle name from name field Name format: Lastname, Firstname M.;  Join on V_EXAMINER_FULL_NAME_R from the hierarchy file (STG_CLAIMS_HIERARCHY_R)
			,V_EMPLOYEE_LAST_NAME_R                --replace(trim(substr(DIM_GRP_SYSUSESO_R.V_DESCRIPTION_R,1,instr(DIM_GRP_SYSUSESO_R.V_DESCRIPTION_R,' ',1))),',') Derive last name from name field Name format: Lastname, Firstname M.;  Join on V_EXAMINER_FULL_NAME_R from the hierarchy file (STG_CLAIMS_HIERARCHY_R)
			,V_EMPLOYEE_EMAIL_R 				   --STG_CLAIMS_HIERARCHY_R.V_LIST_EXAMINER_EMAIL_R  (Join STG_CLAIMS_HIERARCHY_R.V_EXAMINER_FULL_NAME_R=DIM_GRP_SYSUSESO_R.V_DESCRIPTION_R)
			,V_EMPLOYEE_LOGIN_ID_R                 --DIM_GRP_SYSUSESO_R.V_LOGIN_ID_R
			,V_EMPLOYEE_STATUS_R                   --DIM_GRP_SYSUSESO_R.V_LOGIN_ID_R --"If V_LOGIN_ID_R begins with T then set to ""Inactive"" Else V_USER_STATUS_R"
			,V_SUPERVISOR_FULL_NAME_R              --STG_CLAIMS_HIERARCHY_R.V_SUPERVISOR_FULL_NAME_R (Join STG_CLAIMS_HIERARCHY_R.V_EXAMINER_FULL_NAME_R=DIM_GRP_SYSUSESO_R.V_DESCRIPTION_R)
			,V_MANAGER_FULL_NAME_R                 --NULL
			,V_DIRECTOR_FULL_NAME_R                --STG_CLAIMS_HIERARCHY_R.V_DIRECTOR_FULL_NAME_R   (Join STG_CLAIMS_HIERARCHY_R.V_EXAMINER_FULL_NAME_R=DIM_GRP_SYSUSESO_R.V_DESCRIPTION_R)
			,V_SUPERVISOR_LOGIN_ID_R               --STG_CLAIMS_HIERARCHY_R.V_SUPERVISOR_LOGIN_ID_R  (Join STG_CLAIMS_HIERARCHY_R.V_EXAMINER_FULL_NAME_R=DIM_GRP_SYSUSESO_R.V_DESCRIPTION_R)
			,V_DIRECTOR_LOGIN_ID_R                 --STG_CLAIMS_HIERARCHY_R.V_DIRECTOR_LOGIN_ID_R    (Join STG_CLAIMS_HIERARCHY_R.V_EXAMINER_FULL_NAME_R=DIM_GRP_SYSUSESO_R.V_DESCRIPTION_R)
			,V_REGION_CODE_R                       --NULL
			,V_REGION_AVP_FULL_NAME_R              --NULL
			,V_REGION_DESC_R                       --NULL
			,N_RSO_NUMBER_R                        --NULL
			,V_RSO_NAME_R                          --NULL
			,V_RSO_CODE_R                          --NULL
			,V_RSO_LOCATION_CODE_R                 --NULL
			,V_SALES_REP_NUMBER_R                  --NULL
			,V_MANAGER_NUMBER_R                    --NULL
			,V_EMPLOYEE_LEVEL_R                    --NULL
			,V_EMPLOYEE_TITLE_R                    --NULL
			,V_EMPLOYEE_TITLE_DESCRIPTION_R        --NULL
			,D_EMPLOYEE_HIRE_DATE_R                --NULL
			,D_EMPLOYEE_START_DATE_R               --NULL
			,D_EMPLOYEE_TERMINATION_DATE_R         --NULL
			,V_ROOKIE_INDICATOR_R                  --NULL
			,V_MANAGER_INDICATOR_R                 --NULL
			,D_EMPLOYEE_PROMOTION_DATE_R           --NULL
			,V_EMPLOYEE_ID_R                       --NULL
			,V_REGIONAL_VP_FULL_NAME_R             --NULL
			,V_REGIONAL_VP_GROUP_R                 --NULL
			,V_REGIONAL_VP_TITLE_R                 --NULL
			,V_RSO_MANAGER_R                       --NULL
			,V_REGION_SHORT_NAME_R                 --NULL
			,V_UW_DEPARTMENT_R                     --NULL
			,V_WORK_LOCATION_R                     --NULL
			,V_ANALYST_ID_R                        --NULL
			,V_EMPLOYEE_EXTENTION_R                --NULL
			,V_EMPLOYEE_SUB_TEAM_R                 --NULL
			,V_EMPLOYEE_TEAM_NAME_R                --NULL
			,V_MANAGER_ID_R                        --NULL
			,V_MANAGER_EXTENSION_R                 --NULL
			,V_NEW_BUSINESS_INDICATOR_R            --NULL
			,T_CREATION_DATE_R
			,T_EVENT_TIMESTAMP_R
			,T_LAST_MODIFIED_DATE_R
			,V_CREATED_BY_R
			,V_LAST_MODIFIED_BY_R
			,FIC_MIS_DATE_R
			,N_BATCH_ID_R
			,N_SALES_REPRESENTATIVE_SK_R
			--,N_LOAD_RUN_ID_R
			,N_SEQUENCE_NUMBER_R
			,N_CLAIM_SK_R
			,V_EMPLOYEE_FULL_NAME_R					--New change from Erica on 24-02-2023
			)
			SELECT
			 ( nvl(LN_MAX_SEQ_NUMER_R,0)+rownum) N_EMPLOYEE_SK_R
			,V_BUSINESS_UNIT_R
			,V_EMPLOYEE_FIRST_NAME_R
			,V_EMPLOYEE_MIDDLE_NAME_R
			,V_EMPLOYEE_LAST_NAME_R
			,V_EMPLOYEE_EMAIL_R
			,V_EMPLOYEE_LOGIN_ID_R
			,V_EMPLOYEE_STATUS_R
			,V_SUPERVISOR_FULL_NAME_R
			,V_MANAGER_FULL_NAME_R
			,V_DIRECTOR_FULL_NAME_R
			,V_SUPERVISOR_LOGIN_ID_R
			,V_DIRECTOR_LOGIN_ID_R
			,V_REGION_CODE_R
			,V_REGION_AVP_FULL_NAME_R
			,V_REGION_DESC_R
			,N_RSO_NUMBER_R
			,V_RSO_NAME_R
			,V_RSO_CODE_R
			,V_RSO_LOCATION_CODE_R
			,V_SALES_REP_NUMBER_R
			,V_MANAGER_NUMBER_R
			,V_EMPLOYEE_LEVEL_R
			,V_EMPLOYEE_TITLE_R
			,V_EMPLOYEE_TITLE_DESCRIPTION_R
			,D_EMPLOYEE_HIRE_DATE_R
			,D_EMPLOYEE_START_DATE_R
			,D_EMPLOYEE_TERMINATION_DATE_R
			,V_ROOKIE_INDICATOR_R
			,V_MANAGER_INDICATOR_R
			,D_EMPLOYEE_PROMOTION_DATE_R
			,V_EMPLOYEE_ID_R
			,V_REGIONAL_VP_FULL_NAME_R
			,V_REGIONAL_VP_GROUP_R
			,V_REGIONAL_VP_TITLE_R
			,V_RSO_MANAGER_R
			,V_REGION_SHORT_NAME_R
			,V_UW_DEPARTMENT_R
			,V_WORK_LOCATION_R
			,V_ANALYST_ID_R
			,V_EMPLOYEE_EXTENTION_R
			,V_EMPLOYEE_SUB_TEAM_R
			,V_EMPLOYEE_TEAM_NAME_R
			,V_MANAGER_ID_R
			,V_MANAGER_EXTENSION_R
			,V_NEW_BUSINESS_INDICATOR_R
			,T_CREATION_DATE_R
			,T_EVENT_TIMESTAMP_R
			,T_LAST_MODIFIED_DATE_R
			,V_CREATED_BY_R
			,V_LAST_MODIFIED_BY_R
			,FIC_MIS_DATE_R
			,N_BATCH_ID_R
			,N_SALES_REPRESENTATIVE_SK_R
			--,N_LOAD_RUN_ID_R
			,( nvl(LN_MAX_SEQ_NUMER_R,0)+rownum)                                 N_SEQUENCE_NUMBER_R
			,N_CLAIM_SK_R
			,V_EMPLOYEE_FULL_NAME_R						--New change from Erica on 24-02-2023
			FROM (SELECT   DISTINCT
			'Claims'                                                                         V_BUSINESS_UNIT_R
			,trim(REGEXP_SUBSTR (DIM_GRP_SYSUSESO_R.V_DESCRIPTION_R||' ', '(\S*)(\s)',1,2))  V_EMPLOYEE_FIRST_NAME_R
			,TRIM(REGEXP_SUBSTR (DIM_GRP_SYSUSESO_R.V_DESCRIPTION_R||' ', '(\S*)(\s)',1,3))  V_EMPLOYEE_MIDDLE_NAME_R
			,REPLACE(TRIM(REGEXP_SUBSTR (DIM_GRP_SYSUSESO_R.V_DESCRIPTION_R||' ', '(\S*)',1,1)),',')		 V_EMPLOYEE_LAST_NAME_R
			--,STG_CLAIMS_HIERARCHY_R.V_LIST_EXAMINER_EMAIL_R                      V_EMPLOYEE_EMAIL_R--28-Jun-2022 changes
		,STG_CLAIMS_HIERARCHY_R.V_EMPLOYEE_EMAIL_R                           V_EMPLOYEE_EMAIL_R--28-Jun-2022 changes
			,DIM_GRP_SYSUSESO_R.V_LOGIN_ID_R                                     V_EMPLOYEE_LOGIN_ID_R
			,(CASE WHEN DIM_GRP_SYSUSESO_R.V_LOGIN_ID_R LIKE 'T%' THEN
				'Inactive'
			ELSE
			DIM_GRP_SYSUSESO_R.V_USER_STATUS_R
			END
			)                                                                   V_EMPLOYEE_STATUS_R
			,STG_CLAIMS_HIERARCHY_R.V_SUPERVISOR_FULL_NAME_R                     V_SUPERVISOR_FULL_NAME_R
			,NULL                                                                V_MANAGER_FULL_NAME_R
			,STG_CLAIMS_HIERARCHY_R.V_DIRECTOR_FULL_NAME_R                       V_DIRECTOR_FULL_NAME_R
			,STG_CLAIMS_HIERARCHY_R.V_SUPERVISOR_LOGIN_ID_R                      V_SUPERVISOR_LOGIN_ID_R
			,STG_CLAIMS_HIERARCHY_R.V_DIRECTOR_LOGIN_ID_R                        V_DIRECTOR_LOGIN_ID_R
			,NULL                                                                V_REGION_CODE_R
			,NULL                                                                V_REGION_AVP_FULL_NAME_R
			,NULL                                                                V_REGION_DESC_R
			,NULL                                                                N_RSO_NUMBER_R
			,NULL                                                                V_RSO_NAME_R
			,NULL                                                                V_RSO_CODE_R
			,NULL                                                                V_RSO_LOCATION_CODE_R
			,NULL                                                                V_SALES_REP_NUMBER_R
			,NULL                                                                V_MANAGER_NUMBER_R
			,NULL                                                                V_EMPLOYEE_LEVEL_R
			,NULL                                                                V_EMPLOYEE_TITLE_R
			,NULL                                                                V_EMPLOYEE_TITLE_DESCRIPTION_R
			,NULL                                                                D_EMPLOYEE_HIRE_DATE_R
			,NULL                                                                D_EMPLOYEE_START_DATE_R
			,NULL                                                                D_EMPLOYEE_TERMINATION_DATE_R
			,NULL                                                                V_ROOKIE_INDICATOR_R
			,NULL                                                                V_MANAGER_INDICATOR_R
			,NULL                                                                D_EMPLOYEE_PROMOTION_DATE_R
			,NULL                                                                V_EMPLOYEE_ID_R
			,NULL                                                                V_REGIONAL_VP_FULL_NAME_R
			,NULL                                                                V_REGIONAL_VP_GROUP_R
			,NULL                                                                V_REGIONAL_VP_TITLE_R
			,NULL                                                                V_RSO_MANAGER_R
			,NULL                                                                V_REGION_SHORT_NAME_R
			,NULL                                                                V_UW_DEPARTMENT_R
			,NULL                                                                V_WORK_LOCATION_R
			,NULL                                                                V_ANALYST_ID_R
			,NULL                                                                V_EMPLOYEE_EXTENTION_R
			,NULL                                                                V_EMPLOYEE_SUB_TEAM_R
			,NULL                                                                V_EMPLOYEE_TEAM_NAME_R
			,NULL                                                                V_MANAGER_ID_R
			,NULL                                                                V_MANAGER_EXTENSION_R
			,NULL                                                                V_NEW_BUSINESS_INDICATOR_R
			,LT_systimestamp                                                     T_CREATION_DATE_R
			,LT_systimestamp                                                     T_EVENT_TIMESTAMP_R
			,LT_systimestamp                                                     T_LAST_MODIFIED_DATE_R
			,'ODI'                                                               V_CREATED_BY_R
			,'ODI'                                                               V_LAST_MODIFIED_BY_R
			,TRUNC(SYSDATE)                                                      FIC_MIS_DATE_R
			,LN_N_BATCH_ID_R                     								 N_BATCH_ID_R
			,-1 																 N_SALES_REPRESENTATIVE_SK_R
			--,LN_N_LOAD_RUN_ID_R
			,NULL                                                                N_CLAIM_SK_R
			,DIM_GRP_SYSUSESO_R.V_DESCRIPTION_R                                  V_EMPLOYEE_FULL_NAME_R		--New change from Erica on 24-02-2023
			FROM --ATOMIC.STG_CLAIMS_HIERARCHY_R --28-Jun-2022 changes
		 ATOMIC.VW_STG_CLAIMS_HIERARCHY_R STG_CLAIMS_HIERARCHY_R--28-Jun-2022 changes
				,ATOMIC.DIM_GRP_SYSUSESO_R
			WHERE UPPER(STG_CLAIMS_HIERARCHY_R.V_EXAMINER_FULL_NAME_R)=UPPER(DIM_GRP_SYSUSESO_R.V_DESCRIPTION_R)
			  --AND STG_CLAIMS_HIERARCHY_R.N_BATCH_ID_R=LN_N_BATCH_ID_R
			  );

		  commit;
		  	gc_trcmsg:='5.Completed insert into DIM_EMPLOYEE_R_TEMP';
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
			SELECT NVL(MAX(N_SEQUENCE_NUMBER_R),0) INTO LN_MAX_SEQ_NUMER_R
			FROM ATOMIC.DIM_EMPLOYEE_R_temp;

		  EXCEPTION
		  WHEN OTHERS THEN
		  LC_SQLCODE:=SQLCODE;
		  LC_SQLERRM:=SUBSTR(SQLERRM,1,4000);
		  OUT_LOAD_STATUS:='1)Claim Concept Error :-'||LC_SQLCODE||'-'||LC_SQLERRM;
		  ROLLBACK TO SAVEPOINT SP1;
		  RETURN;
		  END ;
			-- Claim Data Load ends
		  END IF;
		IF LC_SOURCE_CONCEPT = 'ALL' OR LC_SOURCE_CONCEPT LIKE '%PREMIUM SERVICES%' THEN
		-- Premium Services Data Load Starts
		BEGIN
			gc_trcmsg:='6.Started Premium Services Data Load to insert into DIM_EMPLOYEE_R_TEMP';
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
		INSERT  /*+APPEND_VALUES*/  INTO ATOMIC.DIM_EMPLOYEE_R_TEMP
			(N_EMPLOYEE_SK_R                       --Populate Skey
			,V_BUSINESS_UNIT_R                     --Populate with "Premium Services"
			,V_EMPLOYEE_FIRST_NAME_R               --replace(trim(substr(STG_PBC_RSO_TEAM_R.V_ANALYST_NAME_R,1,instr(STG_PBC_RSO_TEAM_R.V_ANALYST_NAME_R))),'.') Derive first name from Format: FIRSTNAME.LASTNAME
			,V_EMPLOYEE_MIDDLE_NAME_R              --NULL
			,V_EMPLOYEE_LAST_NAME_R                --replace(trim(substr(STG_PBC_RSO_TEAM_R.V_ANALYST_NAME_R,instr(STG_PBC_RSO_TEAM_R.V_ANALYST_NAME_R,'.'))),'.') Derive LAST name from Format: FIRSTNAME.LASTNAME
			,V_EMPLOYEE_EMAIL_R 				   --NULL
			,V_EMPLOYEE_LOGIN_ID_R                 --NULL
			,V_EMPLOYEE_STATUS_R                   --NULL
			,V_SUPERVISOR_FULL_NAME_R              --NULL
			,V_MANAGER_FULL_NAME_R                 --NULL
			,V_DIRECTOR_FULL_NAME_R                --STG_PBC_RSO_TEAM_R.V_MANAGER_NAME_R
			,V_SUPERVISOR_LOGIN_ID_R               --NULL
			,V_DIRECTOR_LOGIN_ID_R                 --NULL
			,V_REGION_CODE_R                       --NULL
			,V_REGION_AVP_FULL_NAME_R              --NULL
			,V_REGION_DESC_R                       --NULL
			,N_RSO_NUMBER_R                        --NULL
			,V_RSO_NAME_R                          --NULL
			,V_RSO_CODE_R                          --NULL
			,V_RSO_LOCATION_CODE_R                 --NULL
			,V_SALES_REP_NUMBER_R                  --NULL
			,V_MANAGER_NUMBER_R                    --NULL
			,V_EMPLOYEE_LEVEL_R                    --NULL
			,V_EMPLOYEE_TITLE_R                    --NULL
			,V_EMPLOYEE_TITLE_DESCRIPTION_R        --NULL
			,D_EMPLOYEE_HIRE_DATE_R                --NULL
			,D_EMPLOYEE_START_DATE_R               --NULL
			,D_EMPLOYEE_TERMINATION_DATE_R         --NULL
			,V_ROOKIE_INDICATOR_R                  --NULL
			,V_MANAGER_INDICATOR_R                 --NULL
			,D_EMPLOYEE_PROMOTION_DATE_R           --NULL
			,V_EMPLOYEE_ID_R                       --NULL
			,V_REGIONAL_VP_FULL_NAME_R             --NULL
			,V_REGIONAL_VP_GROUP_R                 --NULL
			,V_REGIONAL_VP_TITLE_R                 --NULL
			,V_RSO_MANAGER_R                       --NULL
			,V_REGION_SHORT_NAME_R                 --NULL
			,V_UW_DEPARTMENT_R                     --NULL
			,V_WORK_LOCATION_R                     --NULL
			,V_ANALYST_ID_R                        --STG_PBC_RSO_TEAM_R.V_ANALYST_ID_R
			,V_EMPLOYEE_EXTENTION_R                --STG_PBC_RSO_TEAM_R.V_ANALYST_EXT_R
			,V_EMPLOYEE_SUB_TEAM_R                 --NULL
			,V_EMPLOYEE_TEAM_NAME_R                --NULL
			,V_MANAGER_ID_R                        --STG_PBC_RSO_TEAM_R.V_MANAGER_ID_R
			,V_MANAGER_EXTENSION_R                 --STG_PBC_RSO_TEAM_R.V_MANAGER_EXT_R
			,V_NEW_BUSINESS_INDICATOR_R            --NULL
			,T_CREATION_DATE_R
			,T_EVENT_TIMESTAMP_R
			,T_LAST_MODIFIED_DATE_R
			,V_CREATED_BY_R
			,V_LAST_MODIFIED_BY_R
			,FIC_MIS_DATE_R
			,N_BATCH_ID_R
			,N_SALES_REPRESENTATIVE_SK_R
			--,N_LOAD_RUN_ID_R
			,N_SEQUENCE_NUMBER_R
			,N_CLAIM_SK_R
			)
			SELECT
			 ( nvl(LN_MAX_SEQ_NUMER_R,0)+rownum) N_EMPLOYEE_SK_R
			,V_BUSINESS_UNIT_R
			,V_EMPLOYEE_FIRST_NAME_R
			,V_EMPLOYEE_MIDDLE_NAME_R
			,V_EMPLOYEE_LAST_NAME_R
			,V_EMPLOYEE_EMAIL_R
			,V_EMPLOYEE_LOGIN_ID_R
			,V_EMPLOYEE_STATUS_R
			,V_SUPERVISOR_FULL_NAME_R
			,V_MANAGER_FULL_NAME_R
			,V_DIRECTOR_FULL_NAME_R
			,V_SUPERVISOR_LOGIN_ID_R,V_DIRECTOR_LOGIN_ID_R
			,V_REGION_CODE_R
			,V_REGION_AVP_FULL_NAME_R
			,V_REGION_DESC_R
			,N_RSO_NUMBER_R
			,V_RSO_NAME_R
			,V_RSO_CODE_R
			,V_RSO_LOCATION_CODE_R
			,V_SALES_REP_NUMBER_R
			,V_MANAGER_NUMBER_R
			,V_EMPLOYEE_LEVEL_R
			,V_EMPLOYEE_TITLE_R
			,V_EMPLOYEE_TITLE_DESCRIPTION_R
			,D_EMPLOYEE_HIRE_DATE_R
			,D_EMPLOYEE_START_DATE_R
			,D_EMPLOYEE_TERMINATION_DATE_R
			,V_ROOKIE_INDICATOR_R
			,V_MANAGER_INDICATOR_R
			,D_EMPLOYEE_PROMOTION_DATE_R
			,V_EMPLOYEE_ID_R
			,V_REGIONAL_VP_FULL_NAME_R
			,V_REGIONAL_VP_GROUP_R
			,V_REGIONAL_VP_TITLE_R
			,V_RSO_MANAGER_R
			,V_REGION_SHORT_NAME_R
			,V_UW_DEPARTMENT_R
			,V_WORK_LOCATION_R
			,V_ANALYST_ID_R
			,V_EMPLOYEE_EXTENTION_R
			,V_EMPLOYEE_SUB_TEAM_R
			,V_EMPLOYEE_TEAM_NAME_R
			,V_MANAGER_ID_R
			,V_MANAGER_EXTENSION_R
			,V_NEW_BUSINESS_INDICATOR_R
			,T_CREATION_DATE_R
			,T_EVENT_TIMESTAMP_R
			,T_LAST_MODIFIED_DATE_R
			,V_CREATED_BY_R
			,V_LAST_MODIFIED_BY_R
			,FIC_MIS_DATE_R
			,N_BATCH_ID_R
			,N_SALES_REPRESENTATIVE_SK_R
			--,N_LOAD_RUN_ID_R
			,( nvl(LN_MAX_SEQ_NUMER_R,0)+rownum)                                 N_SEQUENCE_NUMBER_R
			,N_CLAIM_SK_R
			FROM (SELECT   DISTINCT
			 'Premium Services'                       V_BUSINESS_UNIT_R
			,replace(TRIM(SUBSTR(STG_PBC_RSO_TEAM_R.V_ANALYST_NAME_R,1,INSTR(STG_PBC_RSO_TEAM_R.V_ANALYST_NAME_R,'.')))
		,'.' ) V_EMPLOYEE_FIRST_NAME_R --29-Sep-2022 changes added replace function to remove dot(.)
			,NULL                                   V_EMPLOYEE_MIDDLE_NAME_R
			,trim(substr(STG_PBC_RSO_TEAM_R.V_ANALYST_NAME_R,instr(STG_PBC_RSO_TEAM_R.V_ANALYST_NAME_R,'.')+1)) V_EMPLOYEE_LAST_NAME_R
			,NULL                                  V_EMPLOYEE_EMAIL_R
			,NULL                                  V_EMPLOYEE_LOGIN_ID_R
			,NULL                                  V_EMPLOYEE_STATUS_R
			,NULL                                  V_SUPERVISOR_FULL_NAME_R
			,NULL                                  V_MANAGER_FULL_NAME_R
			,STG_PBC_RSO_TEAM_R.V_MANAGER_NAME_R   V_DIRECTOR_FULL_NAME_R                --
			,NULL                                  V_SUPERVISOR_LOGIN_ID_R
			,NULL                                  V_DIRECTOR_LOGIN_ID_R
			,NULL                                  V_REGION_CODE_R
			,NULL                                  V_REGION_AVP_FULL_NAME_R
			,NULL                                  V_REGION_DESC_R
			,NULL                                  N_RSO_NUMBER_R
			,NULL                                  V_RSO_NAME_R
			,NULL                                  V_RSO_CODE_R
			,NULL                                  V_RSO_LOCATION_CODE_R
			,NULL                                  V_SALES_REP_NUMBER_R
			,NULL                                  V_MANAGER_NUMBER_R
			,NULL                                  V_EMPLOYEE_LEVEL_R
			,NULL                                  V_EMPLOYEE_TITLE_R
			,NULL                                  V_EMPLOYEE_TITLE_DESCRIPTION_R
			,NULL                                  D_EMPLOYEE_HIRE_DATE_R
			,NULL                                  D_EMPLOYEE_START_DATE_R
			,NULL                                  D_EMPLOYEE_TERMINATION_DATE_R
			,NULL                                  V_ROOKIE_INDICATOR_R
			,NULL                                  V_MANAGER_INDICATOR_R
			,NULL                                  D_EMPLOYEE_PROMOTION_DATE_R
			,NULL                                  V_EMPLOYEE_ID_R
			,NULL                                  V_REGIONAL_VP_FULL_NAME_R
			,NULL                                  V_REGIONAL_VP_GROUP_R
			,NULL                                  V_REGIONAL_VP_TITLE_R
			,NULL                                  V_RSO_MANAGER_R
			,NULL                                  V_REGION_SHORT_NAME_R
			,NULL                                  V_UW_DEPARTMENT_R
			,NULL                                  V_WORK_LOCATION_R
			,STG_PBC_RSO_TEAM_R.V_ANALYST_ID_R     V_ANALYST_ID_R
			,STG_PBC_RSO_TEAM_R.V_ANALYST_EXT_R    V_EMPLOYEE_EXTENTION_R
			,NULL                                  V_EMPLOYEE_SUB_TEAM_R
			,NULL                                  V_EMPLOYEE_TEAM_NAME_R
			,STG_PBC_RSO_TEAM_R.V_MANAGER_ID_R     V_MANAGER_ID_R
			,STG_PBC_RSO_TEAM_R.V_MANAGER_EXT_R    V_MANAGER_EXTENSION_R
			,NULL                                  V_NEW_BUSINESS_INDICATOR_R
			--,( nvl(LN_MAX_SEQ_NUMER_R,0)+rownum)                                 N_SEQUENCE_NUMBER_R
			,LT_systimestamp                                                     T_CREATION_DATE_R
			,LT_systimestamp                                                     T_EVENT_TIMESTAMP_R
			,LT_systimestamp                                                     T_LAST_MODIFIED_DATE_R
			,'ODI'                                                               V_CREATED_BY_R
			,'ODI'                                                               V_LAST_MODIFIED_BY_R
			,TRUNC(SYSDATE)                                                      FIC_MIS_DATE_R
			,LN_N_BATCH_ID_R                     								 N_BATCH_ID_R
			,-1 																 N_SALES_REPRESENTATIVE_SK_R
			--,LN_N_LOAD_RUN_ID_R
			,NULL                                                                N_CLAIM_SK_R
			FROM ATOMIC.STG_PBC_RSO_TEAM_R
			);--

		  commit;
		  	gc_trcmsg:='7.Completed Premium Services Data Load to insert into DIM_EMPLOYEE_R_TEMP';
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
			SELECT NVL(MAX(N_SEQUENCE_NUMBER_R),0) INTO LN_MAX_SEQ_NUMER_R
			FROM ATOMIC.DIM_EMPLOYEE_R_temp;

		  EXCEPTION
		  WHEN OTHERS THEN
		  LC_SQLCODE:=SQLCODE;
		  LC_SQLERRM:=SUBSTR(SQLERRM,1,4000);
		  OUT_LOAD_STATUS:='2)Premium Services Concept Error :-'||LC_SQLCODE||'-'||LC_SQLERRM;
		  ROLLBACK TO SAVEPOINT SP1;
		  RETURN;
		  END ;
		-- Premium Services Data Load Ends
		  END IF;
		IF LC_SOURCE_CONCEPT = 'ALL' OR LC_SOURCE_CONCEPT LIKE '%SALES%' THEN
		-- Sales Rep Data Load Starts
		BEGIN
			gc_trcmsg:='8.Started Sales Rep Data Load to insert into DIM_EMPLOYEE_R_TEMP';
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
			INSERT /*+APPEND_VALUES*/ INTO ATOMIC.DIM_EMPLOYEE_R_TEMP
			(
			N_EMPLOYEE_SK_R                       --Populate Skey
			,V_BUSINESS_UNIT_R                      --Populate with "Sales"
			,V_EMPLOYEE_FIRST_NAME_R               --trim(DIM_GRP_SALES_REPRESENTATIVE_R.v_first_name_r)              ED_TR_001
			,V_EMPLOYEE_MIDDLE_NAME_R              --ltrim(Dim_Grp_Sales_Representative_R.v_middle_name_r)            ED_TR_001
			,V_EMPLOYEE_LAST_NAME_R                --ltrim(Dim_Grp_Sales_Representative_R.v_last_name_r)              ED_TR_001
			,V_EMPLOYEE_EMAIL_R 				   --NULL
			,V_EMPLOYEE_LOGIN_ID_R                 --NULL
			,V_EMPLOYEE_STATUS_R                   --NULL
			,V_SUPERVISOR_FULL_NAME_R              --NULL
			,V_MANAGER_FULL_NAME_R                 --Dim_Grp_Sales_Representative_R.v_manager_r
			,V_DIRECTOR_FULL_NAME_R                --NULL
			,V_SUPERVISOR_LOGIN_ID_R               --NULL
			,V_DIRECTOR_LOGIN_ID_R                 --NULL
			,V_REGION_CODE_R                       --STG_RSO_TO_REGION_R.V_REGION_CODE_R        Join (Dim_Grp_Sales_Representative_R.n_sales_rep_level_sk_r=Dim_Grp_Sales_Rep_Level_R.n_sales_rep_level_sk_r
			,V_REGION_AVP_FULL_NAME_R              --STG_RSO_TO_REGION_R.V_REGIONAL_AVP_NAME_R   AND Dim_Grp_Sales_Representative_R.n_field_office_sk_r = Dim_Grp_Field_Office_R.n_field_office_sk_r
			,V_REGION_DESC_R                       --STG_RSO_TO_REGION_R.V_REGION_NAME_R         AND STG_RSO_TO_REGION_R.V_RSL_LOC_CODE_R =Dim_Grp_Field_Office_R.v_rsl_location_code_r)
			,N_RSO_NUMBER_R                        --Dim_Grp_Field_Office_R.v_regional_office_number_r                                      ED_TR_001,ED_TR_002
			,V_RSO_NAME_R                          --LTRIM(Dim_Grp_Field_Office_R.v_field_office_name_r)                                    ED_TR_001,ED_TR_002
			,V_RSO_CODE_R                          --DIM_GRP_FIELD_OFFICE_R.v_rso_assoc_r                                                   ED_TR_001,ED_TR_002
			,V_RSO_LOCATION_CODE_R                 --Dim_Grp_Field_Office_R.v_rsl_location_code_r                                           ED_TR_001
			,V_SALES_REP_NUMBER_R                  --Dim_Grp_Sales_Representative_R.v_sales_rep_nbr_r                                       ED_TR_001
			,V_MANAGER_NUMBER_R                    --Dim_Grp_Sales_Representative_R.v_manager_r                                             ED_TR_001
			,V_EMPLOYEE_LEVEL_R                    --Dim_Grp_Sales_Rep_Level_R.v_sales_rep_level_r                                          ED_TR_001
			,V_EMPLOYEE_TITLE_R                    --DIM_GRP_SALES_REP_LEVEL_R.v_level_title_r                                              ED_TR_001
			,V_EMPLOYEE_TITLE_DESCRIPTION_R        --Dim_Grp_Sales_Rep_Level_R.v_description_r                                              ED_TR_001
			,D_EMPLOYEE_HIRE_DATE_R                --Dim_Grp_Sales_Representative_R.d_hire_date_r                                           ED_TR_001
			,D_EMPLOYEE_START_DATE_R               --Dim_Grp_Sales_Representative_R.d_sales_rep_effective_date_r                            ED_TR_001
			,D_EMPLOYEE_TERMINATION_DATE_R         --Dim_Grp_Sales_Representative_R.d_sales_rep_eff_end_date_r                              ED_TR_001
			,V_ROOKIE_INDICATOR_R                  --Dim_Grp_Sales_Representative_R.v_rookie_flag_r                                         ED_TR_001
			,V_MANAGER_INDICATOR_R                 --DECODE(Dim_Grp_Sales_Representative_R.v_manager_flag_r, NULL, 'N', 'Y', 'N', 'N', 'Y') ED_TR_001
			,D_EMPLOYEE_PROMOTION_DATE_R           --Dim_Grp_Sales_Representative_R.d_promotion_date_r                                      ED_TR_001
			,V_EMPLOYEE_ID_R                       --Dim_Grp_Sales_Representative_R.n_employee_id_r                                         ED_TR_001
			,V_REGIONAL_VP_FULL_NAME_R             --STG_RSO_TO_REGION_R.V_REGIONAL_VP_NAME_R
			,V_REGIONAL_VP_GROUP_R                 --STG_RSO_TO_REGION_R.V_REGIONAL_VP_GROUP_R
			,V_REGIONAL_VP_TITLE_R                 --STG_RSO_TO_REGION_R.V_REGIONAL_VP_TITLE_R
			,V_RSO_MANAGER_R                       --STG_RSO_TO_REGION_R.V_OFC_MANAGER_R
			,V_REGION_SHORT_NAME_R                 --STG_RSO_TO_REGION_R.V_REGION_SHORT_NAME_R
			,V_UW_DEPARTMENT_R                     --NULL
			,V_WORK_LOCATION_R                     --NULL
			,V_ANALYST_ID_R                        --NULL
			,V_EMPLOYEE_EXTENTION_R                --NULL
			,V_EMPLOYEE_SUB_TEAM_R                 --NULL
			,V_EMPLOYEE_TEAM_NAME_R                --NULL
			,V_MANAGER_ID_R                        --NULL
			,V_MANAGER_EXTENSION_R                 --NULL
			,V_NEW_BUSINESS_INDICATOR_R            --NULL
			,T_CREATION_DATE_R
			,T_EVENT_TIMESTAMP_R
			,T_LAST_MODIFIED_DATE_R
			,V_CREATED_BY_R
			,V_LAST_MODIFIED_BY_R
			,FIC_MIS_DATE_R
			,N_BATCH_ID_R
			,N_SALES_REPRESENTATIVE_SK_R
			--,N_LOAD_RUN_ID_R
			,N_SEQUENCE_NUMBER_R
			,N_CLAIM_SK_R
			)
			SELECT
			 ( nvl(LN_MAX_SEQ_NUMER_R,0)+rownum) N_EMPLOYEE_SK_R
			,V_BUSINESS_UNIT_R
			,V_EMPLOYEE_FIRST_NAME_R
			,V_EMPLOYEE_MIDDLE_NAME_R
			,V_EMPLOYEE_LAST_NAME_R
			,V_EMPLOYEE_EMAIL_R
			,V_EMPLOYEE_LOGIN_ID_R
			,V_EMPLOYEE_STATUS_R
			,V_SUPERVISOR_FULL_NAME_R
			,V_MANAGER_FULL_NAME_R
			,V_DIRECTOR_FULL_NAME_R
			,V_SUPERVISOR_LOGIN_ID_R
			,V_DIRECTOR_LOGIN_ID_R
			,V_REGION_CODE_R
			,V_REGION_AVP_FULL_NAME_R
			,V_REGION_DESC_R
			,N_RSO_NUMBER_R
			,V_RSO_NAME_R
			,V_RSO_CODE_R
			,V_RSO_LOCATION_CODE_R
			,V_SALES_REP_NUMBER_R
			,V_MANAGER_NUMBER_R
			,V_EMPLOYEE_LEVEL_R
			,V_EMPLOYEE_TITLE_R
			,V_EMPLOYEE_TITLE_DESCRIPTION_R
			,D_EMPLOYEE_HIRE_DATE_R
			,D_EMPLOYEE_START_DATE_R
			,D_EMPLOYEE_TERMINATION_DATE_R
			,V_ROOKIE_INDICATOR_R
			,V_MANAGER_INDICATOR_R
			,D_EMPLOYEE_PROMOTION_DATE_R
			,V_EMPLOYEE_ID_R
			,V_REGIONAL_VP_FULL_NAME_R
			,V_REGIONAL_VP_GROUP_R
			,V_REGIONAL_VP_TITLE_R
			,V_RSO_MANAGER_R
			,V_REGION_SHORT_NAME_R
			,V_UW_DEPARTMENT_R
			,V_WORK_LOCATION_R
			,V_ANALYST_ID_R
			,V_EMPLOYEE_EXTENTION_R
			,V_EMPLOYEE_SUB_TEAM_R
			,V_EMPLOYEE_TEAM_NAME_R
			,V_MANAGER_ID_R
			,V_MANAGER_EXTENSION_R
			,V_NEW_BUSINESS_INDICATOR_R
			,T_CREATION_DATE_R
			,T_EVENT_TIMESTAMP_R
			,T_LAST_MODIFIED_DATE_R
			,V_CREATED_BY_R
			,V_LAST_MODIFIED_BY_R
			,FIC_MIS_DATE_R
			,N_BATCH_ID_R
			,N_SALES_REPRESENTATIVE_SK_R
			--,N_LOAD_RUN_ID_R
			,( nvl(LN_MAX_SEQ_NUMER_R,0)+rownum)                                 N_SEQUENCE_NUMBER_R
			,N_CLAIM_SK_R
			FROM (SELECT   DISTINCT
			'Sales'                                                             V_BUSINESS_UNIT_R
			,trim(DIM_GRP_SALES_REPRESENTATIVE_R.v_first_name_r)                                             V_EMPLOYEE_FIRST_NAME_R
			,ltrim(Dim_Grp_Sales_Representative_R.v_middle_name_r)                                           V_EMPLOYEE_MIDDLE_NAME_R
			,ltrim(Dim_Grp_Sales_Representative_R.v_last_name_r)                                             V_EMPLOYEE_LAST_NAME_R
			,NULL                                                                                            V_EMPLOYEE_EMAIL_R
			,NULL                                                                                            V_EMPLOYEE_LOGIN_ID_R
			,NULL                                                                                            V_EMPLOYEE_STATUS_R
			,NULL                                                                                            V_SUPERVISOR_FULL_NAME_R
			,Dim_Grp_Sales_Representative_R.v_manager_r                                                      V_MANAGER_FULL_NAME_R
			,NULL                                                                                            V_DIRECTOR_FULL_NAME_R
			,NULL                                                                                            V_SUPERVISOR_LOGIN_ID_R
			,NULL                                                                                            V_DIRECTOR_LOGIN_ID_R
			,STG_RSO_TO_REGION_R.V_REGION_CODE_R                                                             V_REGION_CODE_R
			,STG_RSO_TO_REGION_R.V_REGIONAL_AVP_NAME_R                                                       V_REGION_AVP_FULL_NAME_R
			,STG_RSO_TO_REGION_R.V_REGION_NAME_R                                                             V_REGION_DESC_R
			,Dim_Grp_Field_Office_R.v_regional_office_number_r                                               N_RSO_NUMBER_R
			,LTRIM(Dim_Grp_Field_Office_R.v_field_office_name_r)                                             V_RSO_NAME_R
			,DIM_GRP_FIELD_OFFICE_R.V_CODE_R                                                                 V_RSO_CODE_R
			,Dim_Grp_Field_Office_R.v_rsl_location_code_r                                                    V_RSO_LOCATION_CODE_R
			,Dim_Grp_Sales_Representative_R.v_sales_rep_nbr_r                                                V_SALES_REP_NUMBER_R
			,Dim_Grp_Sales_Representative_R.v_manager_r                                                      V_MANAGER_NUMBER_R
			,Dim_Grp_Sales_Rep_Level_R.v_sales_rep_level_r                                                   V_EMPLOYEE_LEVEL_R
			,DIM_GRP_SALES_REP_LEVEL_R.v_level_title_r                                                       V_EMPLOYEE_TITLE_R
			,Dim_Grp_Sales_Rep_Level_R.v_description_r                                                       V_EMPLOYEE_TITLE_DESCRIPTION_R
			,Dim_Grp_Sales_Representative_R.d_hire_date_r                                                    D_EMPLOYEE_HIRE_DATE_R
			,Dim_Grp_Sales_Representative_R.d_sales_rep_effective_date_r                                     D_EMPLOYEE_START_DATE_R
			,Dim_Grp_Sales_Representative_R.d_sales_rep_eff_end_date_r                                       D_EMPLOYEE_TERMINATION_DATE_R
			,Dim_Grp_Sales_Representative_R.v_rookie_flag_r                                                  V_ROOKIE_INDICATOR_R
			,DECODE(Dim_Grp_Sales_Representative_R.v_manager_flag_r, NULL, 'N', 'Y', 'N', 'N', 'Y')          V_MANAGER_INDICATOR_R
			,Dim_Grp_Sales_Representative_R.d_promotion_date_r                                               D_EMPLOYEE_PROMOTION_DATE_R
			,Dim_Grp_Sales_Representative_R.n_employee_id_r                                                  V_EMPLOYEE_ID_R
			,STG_RSO_TO_REGION_R.V_REGIONAL_VP_NAME_R                                                        V_REGIONAL_VP_FULL_NAME_R
			,STG_RSO_TO_REGION_R.V_REGIONAL_VP_GROUP_R                                                       V_REGIONAL_VP_GROUP_R
			,STG_RSO_TO_REGION_R.V_REGIONAL_VP_TITLE_R                                                       V_REGIONAL_VP_TITLE_R
			,STG_RSO_TO_REGION_R.V_OFC_MANAGER_R                                                             V_RSO_MANAGER_R
			,STG_RSO_TO_REGION_R.V_REGION_SHORT_NAME_R                                                       V_REGION_SHORT_NAME_R
			,NULL                                                                                            V_UW_DEPARTMENT_R
			,NULL                                                                                            V_WORK_LOCATION_R
			,NULL                                                                                            V_ANALYST_ID_R
			,NULL                                                                                            V_EMPLOYEE_EXTENTION_R
			,NULL                                                                                            V_EMPLOYEE_SUB_TEAM_R
			,NULL                                                                                            V_EMPLOYEE_TEAM_NAME_R
			,NULL                                                                                            V_MANAGER_ID_R
			,NULL                                                                                            V_MANAGER_EXTENSION_R
			,NULL                                                                                            V_NEW_BUSINESS_INDICATOR_R
			,LT_systimestamp                                                     T_CREATION_DATE_R
			,LT_systimestamp                                                     T_EVENT_TIMESTAMP_R
			,LT_systimestamp                                                     T_LAST_MODIFIED_DATE_R
			,'ODI'                                                               V_CREATED_BY_R
			,'ODI'                                                               V_LAST_MODIFIED_BY_R
			,TRUNC(SYSDATE)                                                      FIC_MIS_DATE_R
			,LN_N_BATCH_ID_R                     								 N_BATCH_ID_R
			,DIM_GRP_SALES_REPRESENTATIVE_R.N_SALES_REPRESENTATIVE_SK_R     	 N_SALES_REPRESENTATIVE_SK_R
			--,LN_N_LOAD_RUN_ID_R
			,NULL                                                                N_CLAIM_SK_R
			FROM ATOMIC.DIM_GRP_SALES_REPRESENTATIVE_R,ATOMIC.DIM_GRP_SALES_REP_LEVEL_R
			,ATOMIC.DIM_GRP_FIELD_OFFICE_R,atomic.STG_RSO_TO_REGION_R
			WHERE Dim_Grp_Sales_Representative_R.n_sales_rep_level_sk_r=Dim_Grp_Sales_Rep_Level_R.n_sales_rep_level_sk_r
			AND Dim_Grp_Sales_Representative_R.n_field_office_sk_r = Dim_Grp_Field_Office_R.n_field_office_sk_r
			AND STG_RSO_TO_REGION_R.V_RSL_LOC_CODE_R =Dim_Grp_Field_Office_R.v_rsl_location_code_r
			AND UPPER(TRIM(DIM_GRP_FIELD_OFFICE_R.V_FIELD_OFFICE_NAME_R)) <> 'INDIANAPOLIS'  --ED_TR_002
			/*AND (Dim_Grp_Sales_Representative_R.d_sales_rep_eff_end_date_r is null or Dim_Grp_Sales_Representative_R.d_sales_rep_eff_end_date_r > sysdate - 180)--ED_TR_001
			As per Erica for now the above condition is not required*/
			);--

		  commit;
		  gc_trcmsg:='9.Completed Sales Rep Data Load to insert into DIM_EMPLOYEE_R_TEMP';
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
			SELECT NVL(MAX(N_SEQUENCE_NUMBER_R),0) INTO LN_MAX_SEQ_NUMER_R
			FROM ATOMIC.DIM_EMPLOYEE_R_temp;
		  EXCEPTION
		  WHEN OTHERS THEN
		  LC_SQLCODE:=SQLCODE;
		  LC_SQLERRM:=SUBSTR(SQLERRM,1,4000);
		  OUT_LOAD_STATUS:='3)Sales Rep Concept Error :-'||LC_SQLCODE||'-'||LC_SQLERRM;
		  ROLLBACK TO SAVEPOINT SP1;
		  RETURN;
		  END ;
		-- Sales Rep Data Load Ends
		  END IF;
		IF LC_SOURCE_CONCEPT = 'ALL' OR LC_SOURCE_CONCEPT LIKE '%UNDERWRITING%' THEN
		-- Underwriting Data Load Starts
		BEGIN
		gc_trcmsg:='10.Started Underwriting Data Load to insert into DIM_EMPLOYEE_R_TEMP';
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
			INSERT /*+APPEND_VALUES*/ INTO ATOMIC.DIM_EMPLOYEE_R_TEMP
			(N_EMPLOYEE_SK_R                       --Populate Skey
			,V_BUSINESS_UNIT_R                      --Populate with "Underwriting"
			,V_EMPLOYEE_FIRST_NAME_R               --TRIM(REGEXP_SUBSTR (STG_UW_HIERARCHY_R.V_Worker_R, '(\S*)(\s)', 1,1)) Derive first name from Format: Firstname Lastname (1234)  IDS are after names
			,V_EMPLOYEE_MIDDLE_NAME_R              --NULL
			,V_EMPLOYEE_LAST_NAME_R                --TRIM(REGEXP_SUBSTR (STG_UW_HIERARCHY_R.V_Worker_R, '(\S*)(\s)', 1,2) Derive LAST name from Format: Firstname Lastname (1234)  IDS are after names
			,V_EMPLOYEE_EMAIL_R 				   --STG_UW_HIERARCHY_R.V_EMAIL_R
			,V_EMPLOYEE_LOGIN_ID_R                 --NULL
			,V_EMPLOYEE_STATUS_R                   --NULL
			,V_SUPERVISOR_FULL_NAME_R              --STG_UW_HIERARCHY_R.V_Supervisory_Organization_R
			,V_MANAGER_FULL_NAME_R                 --NULL
			,V_DIRECTOR_FULL_NAME_R                --NULL
			,V_SUPERVISOR_LOGIN_ID_R               --NULL
			,V_DIRECTOR_LOGIN_ID_R                 --NULL
			,V_REGION_CODE_R                       --NULL
			,V_REGION_AVP_FULL_NAME_R              --NULL
			,V_REGION_DESC_R                       --NULL
			,N_RSO_NUMBER_R                        --NULL
			,V_RSO_NAME_R                          --NULL
			,V_RSO_CODE_R                          --NULL
			,V_RSO_LOCATION_CODE_R                 --NULL
			,V_SALES_REP_NUMBER_R                  --NULL
			,V_MANAGER_NUMBER_R                    --NULL
			,V_EMPLOYEE_LEVEL_R                    --NULL
			,V_EMPLOYEE_TITLE_R                    --STG_UW_HIERARCHY_R.V_position_r
			,V_EMPLOYEE_TITLE_DESCRIPTION_R        --NULL
			,D_EMPLOYEE_HIRE_DATE_R                --NULL
			,D_EMPLOYEE_START_DATE_R               --NULL
			,D_EMPLOYEE_TERMINATION_DATE_R         --NULL
			,V_ROOKIE_INDICATOR_R                  --NULL
			,V_MANAGER_INDICATOR_R                 --NULL
			,D_EMPLOYEE_PROMOTION_DATE_R           --NULL
			,V_EMPLOYEE_ID_R                       --trim(replace(replace(substr(STG_UW_HIERARCHY_R.V_Worker_R,instr(STG_UW_HIERARCHY_R.V_Worker_R,'(')) ,')'),'(')) Derive ID from V_Worker_R (i.e. value between brackets (1234) derive 1234)
			,V_REGIONAL_VP_FULL_NAME_R             --NULL
			,V_REGIONAL_VP_GROUP_R                 --NULL
			,V_REGIONAL_VP_TITLE_R                 --NULL
			,V_RSO_MANAGER_R                       --NULL
			,V_REGION_SHORT_NAME_R                 --NULL
			,V_UW_DEPARTMENT_R                     --STG_UW_HIERARCHY_R.V_Supervisory_Organization_R
			,V_WORK_LOCATION_R                     --STG_UW_HIERARCHY_R.V_location_R
			,V_ANALYST_ID_R                        --NULL
			,V_EMPLOYEE_EXTENTION_R                --NULL
			,V_EMPLOYEE_SUB_TEAM_R                 --NULL
			,V_EMPLOYEE_TEAM_NAME_R                --NULL
			,V_MANAGER_ID_R                        --NULL
			,V_MANAGER_EXTENSION_R                 --NULL
			,V_NEW_BUSINESS_INDICATOR_R            --NULL
			,T_CREATION_DATE_R
			,T_EVENT_TIMESTAMP_R
			,T_LAST_MODIFIED_DATE_R
			,V_CREATED_BY_R
			,V_LAST_MODIFIED_BY_R
			,FIC_MIS_DATE_R
			,N_BATCH_ID_R
			,N_SALES_REPRESENTATIVE_SK_R
			--,N_LOAD_RUN_ID_R
			,N_SEQUENCE_NUMBER_R
			,N_CLAIM_SK_R
			)
			SELECT
			 ( nvl(LN_MAX_SEQ_NUMER_R,0)+rownum) N_EMPLOYEE_SK_R
			,V_BUSINESS_UNIT_R
			,V_EMPLOYEE_FIRST_NAME_R
			,V_EMPLOYEE_MIDDLE_NAME_R
			,V_EMPLOYEE_LAST_NAME_R
			,V_EMPLOYEE_EMAIL_R
			,V_EMPLOYEE_LOGIN_ID_R
			,V_EMPLOYEE_STATUS_R
			,V_SUPERVISOR_FULL_NAME_R
			,V_MANAGER_FULL_NAME_R
			,V_DIRECTOR_FULL_NAME_R
			,V_SUPERVISOR_LOGIN_ID_R
			,V_DIRECTOR_LOGIN_ID_R
			,V_REGION_CODE_R
			,V_REGION_AVP_FULL_NAME_R
			,V_REGION_DESC_R
			,N_RSO_NUMBER_R
			,V_RSO_NAME_R
			,V_RSO_CODE_R
			,V_RSO_LOCATION_CODE_R
			,V_SALES_REP_NUMBER_R
			,V_MANAGER_NUMBER_R
			,V_EMPLOYEE_LEVEL_R
			,V_EMPLOYEE_TITLE_R
			,V_EMPLOYEE_TITLE_DESCRIPTION_R
			,D_EMPLOYEE_HIRE_DATE_R
			,D_EMPLOYEE_START_DATE_R
			,D_EMPLOYEE_TERMINATION_DATE_R
			,V_ROOKIE_INDICATOR_R
			,V_MANAGER_INDICATOR_R
			,D_EMPLOYEE_PROMOTION_DATE_R
			,V_EMPLOYEE_ID_R
			,V_REGIONAL_VP_FULL_NAME_R
			,V_REGIONAL_VP_GROUP_R
			,V_REGIONAL_VP_TITLE_R
			,V_RSO_MANAGER_R
			,V_REGION_SHORT_NAME_R
			,V_UW_DEPARTMENT_R
			,V_WORK_LOCATION_R
			,V_ANALYST_ID_R
			,V_EMPLOYEE_EXTENTION_R
			,V_EMPLOYEE_SUB_TEAM_R
			,V_EMPLOYEE_TEAM_NAME_R
			,V_MANAGER_ID_R
			,V_MANAGER_EXTENSION_R
			,V_NEW_BUSINESS_INDICATOR_R
			,T_CREATION_DATE_R
			,T_EVENT_TIMESTAMP_R
			,T_LAST_MODIFIED_DATE_R
			,V_CREATED_BY_R
			,V_LAST_MODIFIED_BY_R
			,FIC_MIS_DATE_R
			,N_BATCH_ID_R
			,N_SALES_REPRESENTATIVE_SK_R
			--,N_LOAD_RUN_ID_R
			,( nvl(LN_MAX_SEQ_NUMER_R,0)+rownum)                                 N_SEQUENCE_NUMBER_R
			,N_CLAIM_SK_R
			FROM (SELECT   DISTINCT
			'Underwriting'                                                      V_BUSINESS_UNIT_R
			,TRIM(REGEXP_SUBSTR (STG_UW_HIERARCHY_R.V_Worker_R, '(\S*)(\s)', 1,1))             V_EMPLOYEE_FIRST_NAME_R
			,NULL                                                                              V_EMPLOYEE_MIDDLE_NAME_R
			,TRIM(REGEXP_SUBSTR (STG_UW_HIERARCHY_R.V_Worker_R, '(\S*)(\s)', 1,2))              V_EMPLOYEE_LAST_NAME_R
			,STG_UW_HIERARCHY_R.V_EMAIL_R                                                      V_EMPLOYEE_EMAIL_R
			,NULL                                                                              V_EMPLOYEE_LOGIN_ID_R
			,NULL                                                                              V_EMPLOYEE_STATUS_R
			,STG_UW_HIERARCHY_R.V_Supervisory_Organization_R                                   V_SUPERVISOR_FULL_NAME_R
			,NULL                                                                              V_MANAGER_FULL_NAME_R
			,NULL                                                                              V_DIRECTOR_FULL_NAME_R
			,NULL                                                                              V_SUPERVISOR_LOGIN_ID_R
			,NULL                                                                              V_DIRECTOR_LOGIN_ID_R
			,NULL                                                                              V_REGION_CODE_R
			,NULL                                                                              V_REGION_AVP_FULL_NAME_R
			,NULL                                                                              V_REGION_DESC_R
			,NULL                                                                              N_RSO_NUMBER_R
			,NULL                                                                              V_RSO_NAME_R
			,NULL                                                                              V_RSO_CODE_R
			,NULL                                                                              V_RSO_LOCATION_CODE_R
			,NULL                                                                              V_SALES_REP_NUMBER_R
			,NULL                                                                              V_MANAGER_NUMBER_R
			,NULL                                                                              V_EMPLOYEE_LEVEL_R
			,STG_UW_HIERARCHY_R.V_position_r                                                   V_EMPLOYEE_TITLE_R
			,NULL                                                                              V_EMPLOYEE_TITLE_DESCRIPTION_R
			,NULL                                                                              D_EMPLOYEE_HIRE_DATE_R
			,NULL                                                                              D_EMPLOYEE_START_DATE_R
			,NULL                                                                              D_EMPLOYEE_TERMINATION_DATE_R
			,NULL                                                                              V_ROOKIE_INDICATOR_R
			,NULL                                                                              V_MANAGER_INDICATOR_R
			,NULL                                                                              D_EMPLOYEE_PROMOTION_DATE_R
			,trim(replace(replace(substr(STG_UW_HIERARCHY_R.V_Worker_R,instr(STG_UW_HIERARCHY_R.V_Worker_R,'(')) ,')'),'(')) V_EMPLOYEE_ID_R
			,NULL                                                                              V_REGIONAL_VP_FULL_NAME_R
			,NULL                                                                              V_REGIONAL_VP_GROUP_R

			,NULL                                                                              V_REGIONAL_VP_TITLE_R
			,NULL                                                                              V_RSO_MANAGER_R
			,NULL                                                                              V_REGION_SHORT_NAME_R
			,STG_UW_HIERARCHY_R.V_Supervisory_Organization_R                                   V_UW_DEPARTMENT_R
			,STG_UW_HIERARCHY_R.V_location_R                                                   V_WORK_LOCATION_R
			,NULL                                                                              V_ANALYST_ID_R
			,NULL                                                                              V_EMPLOYEE_EXTENTION_R
			,NULL                                                                              V_EMPLOYEE_SUB_TEAM_R
			,NULL                                                                              V_EMPLOYEE_TEAM_NAME_R
			,NULL                                                                              V_MANAGER_ID_R
			,NULL                                                                              V_MANAGER_EXTENSION_R
			,NULL                                                                              V_NEW_BUSINESS_INDICATOR_R
			,( nvl(LN_MAX_SEQ_NUMER_R,0)+rownum)                                 N_SEQUENCE_NUMBER_R
			,LT_systimestamp                                                     T_CREATION_DATE_R
			,LT_systimestamp                                                     T_EVENT_TIMESTAMP_R
			,LT_systimestamp                                                     T_LAST_MODIFIED_DATE_R
			,'ODI'                                                               V_CREATED_BY_R
			,'ODI'                                                               V_LAST_MODIFIED_BY_R
			,TRUNC(SYSDATE)                                                      FIC_MIS_DATE_R
			,LN_N_BATCH_ID_R                     								 N_BATCH_ID_R
			,-1 																 N_SALES_REPRESENTATIVE_SK_R
			--,LN_N_LOAD_RUN_ID_R
			,NULL                                                                N_CLAIM_SK_R
			FROM ATOMIC.STG_UW_HIERARCHY_R
			);--

		  EXCEPTION
		  WHEN OTHERS THEN
		  LC_SQLCODE:=SQLCODE;
		  LC_SQLERRM:=SUBSTR(SQLERRM,1,4000);
		  OUT_LOAD_STATUS:='4)Underwriting Concept Error :-'||LC_SQLCODE||'-'||LC_SQLERRM;
		  ROLLBACK TO SAVEPOINT SP1;
		  RETURN;
		  END ;
		  commit;
		   gc_trcmsg:='11.Completed Underwriting Data Load to insert into DIM_EMPLOYEE_R_TEMP';
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

		-- Underwriting Data Load Ends
		END IF;

		--MERGE statement start
		BEGIN
		gc_trcmsg:='12.Started Merging Data into DIM_EMPLOYEE_R_TEMP';
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
			MERGE /*+PARALLEL(4) APPEND */INTO ATOMIC.DIM_EMPLOYEE_R D
			 USING (SELECT  * FROM ATOMIC.DIM_EMPLOYEE_R_TEMP ORDER BY N_BATCH_ID_R ASC ) TEMP
			ON ( D.V_BUSINESS_UNIT_R
				--||D.V_EMPLOYEE_FIRST_NAME_R       -- User Story 439134: DIM_EMPLOYEE duplicates permanent solution
				--||D.V_EMPLOYEE_MIDDLE_NAME_R      -- User Story 439134: DIM_EMPLOYEE duplicates permanent solution
				--||D.V_EMPLOYEE_LAST_NAME_R        -- User Story 439134: DIM_EMPLOYEE duplicates permanent solution
				||D.V_EMPLOYEE_LOGIN_ID_R
				||D.V_SALES_REP_NUMBER_R
				||D.V_EMPLOYEE_ID_R
				||D.V_ANALYST_ID_R
				= TEMP.V_BUSINESS_UNIT_R
				--||TEMP.V_EMPLOYEE_FIRST_NAME_R    -- User Story 439134: DIM_EMPLOYEE duplicates permanent solution
				--||TEMP.V_EMPLOYEE_MIDDLE_NAME_R   -- User Story 439134: DIM_EMPLOYEE duplicates permanent solution
				--||TEMP.V_EMPLOYEE_LAST_NAME_R     -- User Story 439134: DIM_EMPLOYEE duplicates permanent solution
				||TEMP.V_EMPLOYEE_LOGIN_ID_R
				||TEMP.V_SALES_REP_NUMBER_R
				||TEMP.V_EMPLOYEE_ID_R
				||TEMP.V_ANALYST_ID_R
			   --AND D.D_RECORD_START_DATE_R = S.D_RECORD_START_DATE_R)
			   )
			WHEN MATCHED THEN
			  UPDATE SET
			--,D.V_BUSINESS_UNIT_R                    = TEMP.V_BUSINESS_UNIT_R
			D.V_EMPLOYEE_FIRST_NAME_R              = TEMP.V_EMPLOYEE_FIRST_NAME_R       -- User Story 439134: DIM_EMPLOYEE duplicates permanent solution
			,D.V_EMPLOYEE_MIDDLE_NAME_R             = TEMP.V_EMPLOYEE_MIDDLE_NAME_R     -- User Story 439134: DIM_EMPLOYEE duplicates permanent solution
			,D.V_EMPLOYEE_LAST_NAME_R               = TEMP.V_EMPLOYEE_LAST_NAME_R       -- User Story 439134: DIM_EMPLOYEE duplicates permanent solution
			,D.V_EMPLOYEE_EMAIL_R 				    = TEMP.V_EMPLOYEE_EMAIL_R
			--,D.V_EMPLOYEE_LOGIN_ID_R                = TEMP.V_EMPLOYEE_LOGIN_ID_R
			,D.V_EMPLOYEE_STATUS_R                  = TEMP.V_EMPLOYEE_STATUS_R
			,D.V_SUPERVISOR_FULL_NAME_R             = TEMP.V_SUPERVISOR_FULL_NAME_R
			,D.V_MANAGER_FULL_NAME_R                = TEMP.V_MANAGER_FULL_NAME_R
			,D.V_DIRECTOR_FULL_NAME_R               = TEMP.V_DIRECTOR_FULL_NAME_R
			,D.V_SUPERVISOR_LOGIN_ID_R              = TEMP.V_SUPERVISOR_LOGIN_ID_R
			,D.V_DIRECTOR_LOGIN_ID_R                = TEMP.V_DIRECTOR_LOGIN_ID_R
			,D.V_REGION_CODE_R                      = TEMP.V_REGION_CODE_R
			,D.V_REGION_AVP_FULL_NAME_R             = TEMP.V_REGION_AVP_FULL_NAME_R
			,D.V_REGION_DESC_R                      = TEMP.V_REGION_DESC_R
			,D.N_RSO_NUMBER_R                       = TEMP.N_RSO_NUMBER_R
			,D.V_RSO_NAME_R                         = TEMP.V_RSO_NAME_R
			,D.V_RSO_CODE_R                         = TEMP.V_RSO_CODE_R
			,D.V_RSO_LOCATION_CODE_R                = TEMP.V_RSO_LOCATION_CODE_R
			--,D.V_SALES_REP_NUMBER_R                 = TEMP.V_SALES_REP_NUMBER_R
			,D.V_MANAGER_NUMBER_R                   = TEMP.V_MANAGER_NUMBER_R
			,D.V_EMPLOYEE_LEVEL_R                   = TEMP.V_EMPLOYEE_LEVEL_R
			,D.V_EMPLOYEE_TITLE_R                   = TEMP.V_EMPLOYEE_TITLE_R
			,D.V_EMPLOYEE_TITLE_DESCRIPTION_R       = TEMP.V_EMPLOYEE_TITLE_DESCRIPTION_R
			,D.D_EMPLOYEE_HIRE_DATE_R               = TEMP.D_EMPLOYEE_HIRE_DATE_R
			,D.D_EMPLOYEE_START_DATE_R              = TEMP.D_EMPLOYEE_START_DATE_R
			,D.D_EMPLOYEE_TERMINATION_DATE_R        = TEMP.D_EMPLOYEE_TERMINATION_DATE_R
			,D.V_ROOKIE_INDICATOR_R                 = TEMP.V_ROOKIE_INDICATOR_R
			,D.V_MANAGER_INDICATOR_R                = TEMP.V_MANAGER_INDICATOR_R
			,D.D_EMPLOYEE_PROMOTION_DATE_R          = TEMP.D_EMPLOYEE_PROMOTION_DATE_R
			--,D.V_EMPLOYEE_ID_R                      = TEMP.V_EMPLOYEE_ID_R
			,D.V_REGIONAL_VP_FULL_NAME_R            = TEMP.V_REGIONAL_VP_FULL_NAME_R
			,D.V_REGIONAL_VP_GROUP_R                = TEMP.V_REGIONAL_VP_GROUP_R
			,D.V_REGIONAL_VP_TITLE_R                = TEMP.V_REGIONAL_VP_TITLE_R
			,D.V_RSO_MANAGER_R                      = TEMP.V_RSO_MANAGER_R
			,D.V_REGION_SHORT_NAME_R                = TEMP.V_REGION_SHORT_NAME_R
			,D.V_UW_DEPARTMENT_R                    = TEMP.V_UW_DEPARTMENT_R
			,D.V_WORK_LOCATION_R                    = TEMP.V_WORK_LOCATION_R
			--,D.V_ANALYST_ID_R                       = TEMP.V_ANALYST_ID_R
			,D.V_EMPLOYEE_EXTENTION_R               = TEMP.V_EMPLOYEE_EXTENTION_R
			,D.V_EMPLOYEE_SUB_TEAM_R                = TEMP.V_EMPLOYEE_SUB_TEAM_R
			,D.V_EMPLOYEE_TEAM_NAME_R               = TEMP.V_EMPLOYEE_TEAM_NAME_R
			,D.V_MANAGER_ID_R                       = TEMP.V_MANAGER_ID_R
			,D.V_MANAGER_EXTENSION_R                = TEMP.V_MANAGER_EXTENSION_R
			,D.V_NEW_BUSINESS_INDICATOR_R           = TEMP.V_NEW_BUSINESS_INDICATOR_R
			--,D.T_EVENT_TIMESTAMP_R                = TEMP.T_EVENT_TIMESTAMP_R
			,D.T_LAST_MODIFIED_DATE_R               = SYSTIMESTAMP
			,D.FIC_MIS_DATE_R                       = TEMP.FIC_MIS_DATE_R
			,D.N_BATCH_ID_R                         = TO_NUMBER(TO_CHAR(SYSDATE,'YYYYMMDD'))
			,D.N_SALES_REPRESENTATIVE_SK_R          = TEMP.N_SALES_REPRESENTATIVE_SK_R
			,D.V_EMPLOYEE_FULL_NAME_R				= TEMP.V_EMPLOYEE_FULL_NAME_R					--New change from Erica on 24-02-2023
			--,D.N_LOAD_RUN_ID_R                    = TEMP.N_LOAD_RUN_ID_R
			--,D.N_SEQUENCE_NUMBER_R                  = TEMP.N_SEQUENCE_NUMBER_R
			  WHERE   D.V_BUSINESS_UNIT_R
				--||D.V_EMPLOYEE_FIRST_NAME_R       -- User Story 439134: DIM_EMPLOYEE duplicates permanent solution
				--||D.V_EMPLOYEE_MIDDLE_NAME_R      -- User Story 439134: DIM_EMPLOYEE duplicates permanent solution
				--||D.V_EMPLOYEE_LAST_NAME_R        -- User Story 439134: DIM_EMPLOYEE duplicates permanent solution
				||D.V_EMPLOYEE_LOGIN_ID_R
				||D.V_SALES_REP_NUMBER_R
				||D.V_EMPLOYEE_ID_R
				||D.V_ANALYST_ID_R
				= TEMP.V_BUSINESS_UNIT_R
				--||TEMP.V_EMPLOYEE_FIRST_NAME_R    -- User Story 439134: DIM_EMPLOYEE duplicates permanent solution
				--||TEMP.V_EMPLOYEE_MIDDLE_NAME_R   -- User Story 439134: DIM_EMPLOYEE duplicates permanent solution
				--||TEMP.V_EMPLOYEE_LAST_NAME_R     -- User Story 439134: DIM_EMPLOYEE duplicates permanent solution
				||TEMP.V_EMPLOYEE_LOGIN_ID_R
				||TEMP.V_SALES_REP_NUMBER_R
				||TEMP.V_EMPLOYEE_ID_R
				||TEMP.V_ANALYST_ID_R
			   --AND D.D_RECORD_START_DATE_R = S.D_RECORD_START_DATE_R
			WHEN NOT MATCHED THEN
			INSERT
			(D.N_EMPLOYEE_SK_R
			,D.V_BUSINESS_UNIT_R
			,D.V_EMPLOYEE_FIRST_NAME_R
			,D.V_EMPLOYEE_MIDDLE_NAME_R
			,D.V_EMPLOYEE_LAST_NAME_R
			,D.V_EMPLOYEE_EMAIL_R
			,D.V_EMPLOYEE_LOGIN_ID_R
			,D.V_EMPLOYEE_STATUS_R
			,D.V_SUPERVISOR_FULL_NAME_R
			,D.V_MANAGER_FULL_NAME_R
			,D.V_DIRECTOR_FULL_NAME_R
			,D.V_SUPERVISOR_LOGIN_ID_R
			,D.V_DIRECTOR_LOGIN_ID_R
			,D.V_REGION_CODE_R
			,D.V_REGION_AVP_FULL_NAME_R
			,D.V_REGION_DESC_R
			,D.N_RSO_NUMBER_R
			,D.V_RSO_NAME_R
			,D.V_RSO_CODE_R
			,D.V_RSO_LOCATION_CODE_R
			,D.V_SALES_REP_NUMBER_R
			,D.V_MANAGER_NUMBER_R
			,D.V_EMPLOYEE_LEVEL_R
			,D.V_EMPLOYEE_TITLE_R
			,D.V_EMPLOYEE_TITLE_DESCRIPTION_R
			,D.D_EMPLOYEE_HIRE_DATE_R
			,D.D_EMPLOYEE_START_DATE_R
			,D.D_EMPLOYEE_TERMINATION_DATE_R
			,D.V_ROOKIE_INDICATOR_R
			,D.V_MANAGER_INDICATOR_R
			,D.D_EMPLOYEE_PROMOTION_DATE_R
			,D.V_EMPLOYEE_ID_R
			,D.V_REGIONAL_VP_FULL_NAME_R
			,D.V_REGIONAL_VP_GROUP_R
			,D.V_REGIONAL_VP_TITLE_R
			,D.V_RSO_MANAGER_R
			,D.V_REGION_SHORT_NAME_R
			,D.V_UW_DEPARTMENT_R
			,D.V_WORK_LOCATION_R
			,D.V_ANALYST_ID_R
			,D.V_EMPLOYEE_EXTENTION_R
			,D.V_EMPLOYEE_SUB_TEAM_R
			,D.V_EMPLOYEE_TEAM_NAME_R
			,D.V_MANAGER_ID_R
			,D.V_MANAGER_EXTENSION_R
			,D.V_NEW_BUSINESS_INDICATOR_R
			,D.FIC_MIS_DATE_R
			,D.N_BATCH_ID_R
			,D.N_SEQUENCE_NUMBER_R
			,D.T_CREATION_DATE_R
			,D.T_EVENT_TIMESTAMP_R
			,D.T_LAST_MODIFIED_DATE_R
			,D.V_CREATED_BY_R
			,D.V_LAST_MODIFIED_BY_R
			,D.N_SALES_REPRESENTATIVE_SK_R
			,D.N_CLAIM_SK_R
			,D.V_EMPLOYEE_FULL_NAME_R						--New change from Erica on 24-02-2023
			) VALUES
			(TEMP.N_EMPLOYEE_SK_R
			,TEMP.V_BUSINESS_UNIT_R
			,TEMP.V_EMPLOYEE_FIRST_NAME_R
			,TEMP.V_EMPLOYEE_MIDDLE_NAME_R
			,TEMP.V_EMPLOYEE_LAST_NAME_R
			,TEMP.V_EMPLOYEE_EMAIL_R
			,TEMP.V_EMPLOYEE_LOGIN_ID_R
			,TEMP.V_EMPLOYEE_STATUS_R
			,TEMP.V_SUPERVISOR_FULL_NAME_R
			,TEMP.V_MANAGER_FULL_NAME_R
			,TEMP.V_DIRECTOR_FULL_NAME_R
			,TEMP.V_SUPERVISOR_LOGIN_ID_R
			,TEMP.V_DIRECTOR_LOGIN_ID_R
			,TEMP.V_REGION_CODE_R
			,TEMP.V_REGION_AVP_FULL_NAME_R
			,TEMP.V_REGION_DESC_R
			,TEMP.N_RSO_NUMBER_R
			,TEMP.V_RSO_NAME_R
			,TEMP.V_RSO_CODE_R
			,TEMP.V_RSO_LOCATION_CODE_R
			,TEMP.V_SALES_REP_NUMBER_R
			,TEMP.V_MANAGER_NUMBER_R
			,TEMP.V_EMPLOYEE_LEVEL_R
			,TEMP.V_EMPLOYEE_TITLE_R
			,TEMP.V_EMPLOYEE_TITLE_DESCRIPTION_R
			,TEMP.D_EMPLOYEE_HIRE_DATE_R
			,TEMP.D_EMPLOYEE_START_DATE_R
			,TEMP.D_EMPLOYEE_TERMINATION_DATE_R
			,TEMP.V_ROOKIE_INDICATOR_R
			,TEMP.V_MANAGER_INDICATOR_R
			,TEMP.D_EMPLOYEE_PROMOTION_DATE_R
			,TEMP.V_EMPLOYEE_ID_R
			,TEMP.V_REGIONAL_VP_FULL_NAME_R
			,TEMP.V_REGIONAL_VP_GROUP_R
			,TEMP.V_REGIONAL_VP_TITLE_R
			,TEMP.V_RSO_MANAGER_R
			,TEMP.V_REGION_SHORT_NAME_R
			,TEMP.V_UW_DEPARTMENT_R
			,TEMP.V_WORK_LOCATION_R
			,TEMP.V_ANALYST_ID_R
			,TEMP.V_EMPLOYEE_EXTENTION_R
			,TEMP.V_EMPLOYEE_SUB_TEAM_R
			,TEMP.V_EMPLOYEE_TEAM_NAME_R
			,TEMP.V_MANAGER_ID_R
			,TEMP.V_MANAGER_EXTENSION_R
			,TEMP.V_NEW_BUSINESS_INDICATOR_R
			,TEMP.FIC_MIS_DATE_R
			,TEMP.N_BATCH_ID_R
			,TEMP.N_SEQUENCE_NUMBER_R
			,TEMP.T_CREATION_DATE_R
			,TEMP.T_EVENT_TIMESTAMP_R
			,TEMP.T_LAST_MODIFIED_DATE_R
			,TEMP.V_CREATED_BY_R
			,TEMP.V_LAST_MODIFIED_BY_R
			,TEMP.N_SALES_REPRESENTATIVE_SK_R
			,TEMP.N_CLAIM_SK_R
			,TEMP.V_EMPLOYEE_FULL_NAME_R					--New change from Erica on 24-02-2023
			)  ;

		EXCEPTION
		WHEN OTHERS THEN
		LC_SQLCODE:=SQLCODE;
		LC_SQLERRM:=SUBSTR(SQLERRM,1,4000);
		OUT_LOAD_STATUS:='5)Merge statement Error :-'||LC_SQLCODE||'-'||LC_SQLERRM;
		ROLLBACK TO SAVEPOINT SP1;
		RETURN;
		END ;
		--MERGE statement end

	commit;

	gc_trcmsg:='13.Complted Merging Data into DIM_EMPLOYEE_R_TEMP';
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


		gc_trcmsg:='1. Exit from PRC_LOAD_DIM_EMPLOYEE_R';
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
	DBMS_OUTPUT.PUT_LINE('PRC_LOAD_DIM_EMPLOYEE_R  EXCEPTION WITH ERROR CODE AS '
				 || SQLCODE
				 || ' '
				 || SQLERRM
				 || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
				 ||'PRC_LOAD_DIM_EMPLOYEE_R'
				 ||';');

	gc_errmsg :=SUBSTR(SQLERRM,1,4000);
    gc_trcmsg:='16.z Error in PRC_LOAD_DIM_EMPLOYEE_R: '||gc_errmsg;

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


    RAISE_APPLICATION_ERROR(-20001,'Error in PKG_LOAD_GRP_TABLES.PRC_LOAD_DIM_EMPLOYEE_R:->
    Error Code:'||LC_SQLCODE||',Error message:'||LC_SQLERRM);

	END PRC_LOAD_DIM_EMPLOYEE_R;






	PROCEDURE PRC_LOAD_FCT_BENEFIT_PMNT_DET_OFFSET1_R(
		IN_BATCH_ID_R        IN NUMBER,
		OUT_LOAD_STATUS      OUT VARCHAR2
		)
	IS
	LD_SYSDATE DATE :=SYSDATE;
	LC_SQLCODE VARCHAR2(4000);
	LC_SQLERRM VARCHAR2(4000);
	LN_SEQUENCE_NUMBER_R NUMBER;
	LN_IN_BATCH_ID_R NUMBER:=IN_BATCH_ID_R;
	LN_LOAD_RUN_ID_R NUMBER;
	BEGIN

		IF LN_IN_BATCH_ID_R IS NULL THEN
		  OUT_LOAD_STATUS:='a) BatchID(IN_BATCH_ID) is null hence terminating the program';
		 RAISE_APPLICATION_ERROR(-20001,'a) BatchID(IN_BATCH_ID) is null hence terminating the program');
		END IF;

	SELECT   MAX(N_SEQUENCE_NUMBER_R)
		  INTO LN_SEQUENCE_NUMBER_R
	FROM ATOMIC.FCT_BENEFIT_PAYMENT_DETAIL_R;

	SELECT   COUNT(1)
		  INTO ln_load_run_id_r
	FROM ATOMIC.PRCS_JOB_LOG_R
	WHERE N_BATCH_ID_R =IN_BATCH_ID_R
	AND V_JOB_NAME_R='GRP_LOAD_FCT_BENEFIT_PMNT_DET_OFFSET1_R';

	INSERT /*+APPEND_VALUES*/ INTO ATOMIC.FCT_BENEFIT_PAYMENT_DETAIL_R
	(
	N_POLICY_SK_R
	,N_PARTY_SK_R
	,N_CLAIM_SK_R
	,N_CLAIM_COVERAGE_SK_R
	,N_CLAIM_COVERAGE_GROUP_SK_R
	,N_BATCH_ID_R
	,N_LOAD_RUN_ID_R
	,N_SEQUENCE_NUMBER_R
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
	)
	--13-Nov-2022 Gireesh Changes starts
	SELECT
	N_POLICY_SK_R
	,N_PARTY_SK_R
	,N_CLAIM_SK_R
	,N_CLAIM_COVERAGE_SK_R
	,N_CLAIM_COVERAGE_GROUP_SK_R
	,LN_IN_BATCH_ID_R N_BATCH_ID_R
	,LN_LOAD_RUN_ID_R N_LOAD_RUN_ID_R
	,NVL(LN_SEQUENCE_NUMBER_R,0)+ROWNUM N_SEQUENCE_NUMBER_R
	,LD_SYSDATE T_CREATION_DATE_R
	,LD_SYSDATE T_LAST_MODIFIED_DATE_R
	,'ODI' V_CREATED_BY_R
	,'ODI' V_LAST_MODIFIED_BY_R
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
	from
	(--13-Nov-2022 Gireesh Changes ends
	select DISTINCT * from (WITH FBP_1 AS (
	select DISTINCT N_PAY_SCHD_SOURCE_SYSTEM_KEY_R,N_SOURCE_VERSION_SEQ_NUMBER_R,N_SEQ_R, V_REFERENCE_R, n_claim_sk_r
	FROM ATOMIC.FCT_BENEFIT_PAYMENT_R
	WHERE ( (V_REFERENCE_R) like 'ALLSOURCE%' OR UPPER(V_REFERENCE_R) like 'BACKDOOR%' )
	--where ((upper(V_REFERENCE_R) like 'ALLSOURCE%' OR UPPER(V_REFERENCE_R) like 'BACKDOOR%') or nvl((UPPER(V_REFERENCE_R)),'ALLSOURCE') not like 'MINIMUM BENEFIT APPLIED%' OR  UPPER(V_REFERENCE_R) not like 'MINIMUM BENEFIT APPLIED%')
	--AND N_BATCH_ID_R = 202109190000-- Added by Gireesh 17mar
	--and n_claim_sk_r = 168169
	AND N_BATCH_ID_R = LN_IN_BATCH_ID_R--13-Nov-2022 Added by Gireesh for Incremental
	)
	--select * from FBP_1);
	,
	FBP_D_1 AS ( Select * FROM ATOMIC.FCT_BENEFIT_PAYMENT_DETAIL_R
	--WHERE N_BATCH_ID_R = 202109190000 -- Added by Gireesh 17mar
	where
	--V_BENEFIT_CODE_R != '382' and
	N_SEQ_R != 9000 and N_SEQ_R != 9001--Added recently by Aravind
	--and n_claim_sk_r = 168169
	AND N_BATCH_ID_R = LN_IN_BATCH_ID_R --13-Nov-2022 Added by Gireesh for Incremental
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
	V_PAY_STATUS_R ,N_ADJ_NET_BENEFIT_R, N_GROSS_BENEFIT_R,N_PRIMARY_PAYEE_R,V_CHECK_NUM_R, D_TRANS_DATE_R, N_ADJ_GROSS_BENEFIT_R
	FROM ATOMIC.FCT_BENEFIT_PAYMENT_R
	WHERE  ((V_REFERENCE_R) like 'ALLSOURCE%' OR UPPER(V_REFERENCE_R) like 'BACKDOOR%' )
	AND UPPER(V_PAY_STATUS_R) in ('RELEASED','REVERSED','REVERSAL')
	--AND N_BATCH_ID_R = 202109190000 -- Added by Gireesh 17mar
	--and n_claim_sk_r = 168169
	AND N_BATCH_ID_R = LN_IN_BATCH_ID_R --13-Nov-2022 Added by Gireesh for Incremental
	)
	--select * from FBP_2);
	,FWS AS (Select distinct n_worksheet_seq_nbr_objectnm_r,n_source_system_key_r,n_spec_benefit_adjust_r,n_gross_benefit_r
	FROM ATOMIC.FCT_GRP_WORKSHEET
	--where n_claim_sk_r = 168169
	)

	--select * from FWS);
	,AMT_2 AS (
	SELECT FBP_2.N_PAY_SCHD_SOURCE_SYSTEM_KEY_R,FBP_2.N_SOURCE_VERSION_SEQ_NUMBER_R,FBP_2.N_SEQ_R,fbp_2.v_pay_status_r,
	FBP_2.N_ADJ_NET_BENEFIT_R, N_PRIMARY_PAYEE_R,
	FWS.n_spec_benefit_adjust_r,FWS.n_gross_benefit_r, V_CHECK_NUM_R, D_TRANS_DATE_R,
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
	FROM ATOMIC.FCT_BENEFIT_PAYMENT_DETAIL_R
	--WHERE N_BATCH_ID_R = 202109190000 -- Added by Gireesh 17mar
	--where n_claim_sk_r = 168169 --and n_source_version_seq_number_r = '339'-- included  to look for a specific claim number
	--AND V_BENEFIT_CODE_R != '382'
	Where N_SEQ_R != 9000 and N_SEQ_R != 9001
	--where n_claim_sk_r = 551575
	AND N_BATCH_ID_R = LN_IN_BATCH_ID_R --13-Nov-2022 Added by Gireesh for Incremental
	)
	--select * from FBP_D_2);
	select DISTINCT
	FBP_D_2.N_POLICY_SK_R,
	FBP_D_2.N_PARTY_SK_R,
	FBP_D_2.N_CLAIM_SK_R,
	FBP_D_2.N_CLAIM_COVERAGE_SK_R,
	FBP_D_2.N_CLAIM_COVERAGE_GROUP_SK_R,
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
	WHERE NOT EXISTS (
	SELECT 1 FROM ATOMIC.FCT_BENEFIT_PAYMENT_DETAIL_R B
	WHERE
	B.N_PAY_DTL_SOURCE_SYSTEM_KEY_R                =A.N_PAY_DTL_SOURCE_SYSTEM_KEY_R
	AND B.N_VERSION_NUMBER_R                       =A.N_VERSION_NUMBER_R
	AND B.N_SOURCE_VERSION_SEQ_NUMBER_R            =A.N_SOURCE_VERSION_SEQ_NUMBER_R
	AND B.N_SEQ_R                                  =A.N_SEQ_R
	AND B.V_AMOUNT_TYPE_NAME_R                     =A.V_AMOUNT_TYPE_NAME_R
	AND B.V_AMOUNT_TYPE_NAME_R = 'ALLSOURCE EXCESS OFFSET'
	AND B.N_SEQ_R='9000'
	)
	;
	COMMIT;
	OUT_LOAD_STATUS:='SUCCESS';
	EXCEPTION
	WHEN OTHERS THEN
	LC_SQLCODE:=SQLCODE;
	LC_SQLERRM:=SUBSTR(SQLERRM,1,4000);
	OUT_LOAD_STATUS:=LC_SQLCODE||'-'||LC_SQLERRM;
	DBMS_OUTPUT.PUT_LINE('PRC_LOAD_FCT_BENEFIT_PMNT_DET_OFFSET1_R  EXCEPTION WITH ERROR CODE AS '
				 || SQLCODE
				 || ' '
				 || SQLERRM
				 || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
				 ||'PRC_LOAD_FCT_BENEFIT_PMNT_DET_OFFSET1_R'
				 ||';');

    RAISE_APPLICATION_ERROR(-20001,'Error in PKG_LOAD_GRP_TABLES.PRC_LOAD_FCT_BENEFIT_PMNT_DET_OFFSET1_R:->
    Error Code:'||SQLCODE||',Error message:'||SUBSTR(SQLERRM,1,4000));

	END PRC_LOAD_FCT_BENEFIT_PMNT_DET_OFFSET1_R;


	PROCEDURE PRC_LOAD_FCT_BENEFIT_PMNT_DET_OFFSET2_R(
		IN_BATCH_ID_R        IN NUMBER,
		OUT_LOAD_STATUS      OUT VARCHAR2
		)
	IS
	LD_SYSDATE DATE :=SYSDATE;
	LC_SQLCODE VARCHAR2(4000);
	LC_SQLERRM VARCHAR2(4000);
	LN_SEQUENCE_NUMBER_R NUMBER;
	LN_IN_BATCH_ID_R NUMBER:=IN_BATCH_ID_R;
	LN_LOAD_RUN_ID_R NUMBER;
	BEGIN

		IF LN_IN_BATCH_ID_R IS NULL THEN
		  OUT_LOAD_STATUS:='a) BatchID(IN_BATCH_ID) is null hence terminating the program';
		 RAISE_APPLICATION_ERROR(-20001,'a) BatchID(IN_BATCH_ID) is null hence terminating the program');
		END IF;

	SELECT   MAX(N_SEQUENCE_NUMBER_R)
		  INTO LN_SEQUENCE_NUMBER_R
	FROM ATOMIC.FCT_BENEFIT_PAYMENT_DETAIL_R;

	SELECT   COUNT(1)
		  INTO ln_load_run_id_r
	FROM ATOMIC.PRCS_JOB_LOG_R
	WHERE N_BATCH_ID_R =IN_BATCH_ID_R
	AND V_JOB_NAME_R='GRP_LOAD_FCT_BENEFIT_PMNT_DET_OFFSET2_R';

	INSERT /*+APPEND_VALUES*/ INTO ATOMIC.FCT_BENEFIT_PAYMENT_DETAIL_R
	(
	N_POLICY_SK_R
	,N_PARTY_SK_R
	,N_CLAIM_SK_R
	,N_CLAIM_COVERAGE_SK_R
	,N_CLAIM_COVERAGE_GROUP_SK_R
	,N_BATCH_ID_R
	,N_LOAD_RUN_ID_R
	,N_SEQUENCE_NUMBER_R
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
	)
	SELECT
	N_POLICY_SK_R
	,N_PARTY_SK_R
	,N_CLAIM_SK_R
	,N_CLAIM_COVERAGE_SK_R
	,N_CLAIM_COVERAGE_GROUP_SK_R
	,LN_IN_BATCH_ID_R N_BATCH_ID_R
	,LN_LOAD_RUN_ID_R N_LOAD_RUN_ID_R
	,NVL(LN_SEQUENCE_NUMBER_R,0)+ROWNUM N_SEQUENCE_NUMBER_R
	,LD_SYSDATE T_CREATION_DATE_R
	,LD_SYSDATE T_LAST_MODIFIED_DATE_R
	,'ODI' V_CREATED_BY_R
	,'ODI' V_LAST_MODIFIED_BY_R
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
	FROM
	(select DISTINCT * from (WITH FBP_1 AS (
	select DISTINCT N_PAY_SCHD_SOURCE_SYSTEM_KEY_R,N_SOURCE_VERSION_SEQ_NUMBER_R,N_SEQ_R,V_REFERENCE_R , N_ADJ_NET_BENEFIT_R
	FROM ATOMIC.FCT_BENEFIT_PAYMENT_R
	WHERE (UPPER(V_REFERENCE_R) like 'MINIMUM BENEFIT APPLIED%')
	AND N_BATCH_ID_R = LN_IN_BATCH_ID_R--Added by Gireesh 17Mar
	/*and N_PAY_SCHD_SOURCE_SYSTEM_KEY_R=2107195  and N_SOURCE_VERSION_SEQ_NUMBER_R=1610  and n_seq_r=1 */
	)

	, FBP_D_2 AS (Select distinct
	N_POLICY_SK_R,
	N_PARTY_SK_R,
	N_CLAIM_SK_R,
	N_CLAIM_COVERAGE_SK_R,
	N_CLAIM_COVERAGE_GROUP_SK_R,
	/* Commented by Gireesh
	N_BATCH_ID_R,
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
	FROM ATOMIC.FCT_BENEFIT_PAYMENT_DETAIL_R
	WHERE N_BATCH_ID_R = LN_IN_BATCH_ID_R--Added by Gireesh 17Mar
	/*where N_PAY_DTL_SOURCE_SYSTEM_KEY_R= 2107195 and N_SOURCE_VERSION_SEQ_NUMBER_R=1610 and n_seq_r=1*/
	)
	/*select * from FBP_D_2 order by N_SOURCE_VERSION_SEQ_NUMBER_R,N_GROUP_SEQ_R;-7-;*/


	select DISTINCT
	FBP_D_2.N_POLICY_SK_R,
	FBP_D_2.N_PARTY_SK_R,
	FBP_D_2.N_CLAIM_SK_R,
	FBP_D_2.N_CLAIM_COVERAGE_SK_R,
	FBP_D_2.N_CLAIM_COVERAGE_GROUP_SK_R,
	/*--Commented by Gireesh 20-Mar-2022
	FBP_D_2.N_BATCH_ID_R,
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

	FROM FBP_D_2 INNER JOIN FBP_1

	ON FBP_1.N_PAY_SCHD_SOURCE_SYSTEM_KEY_R = TRIM(FBP_D_2.N_PAY_DTL_SOURCE_SYSTEM_KEY_R)
	AND FBP_1.N_SOURCE_VERSION_SEQ_NUMBER_R = TRIM(FBP_D_2.N_SOURCE_VERSION_SEQ_NUMBER_R)
	AND FBP_1.N_SEQ_R = TRIM(FBP_D_2.N_GROUP_SEQ_R)
	) A WHERE NOT EXISTS (
	SELECT 1 FROM ATOMIC.FCT_BENEFIT_PAYMENT_DETAIL_R B
	WHERE
	B.N_PAY_DTL_SOURCE_SYSTEM_KEY_R                =A.N_PAY_DTL_SOURCE_SYSTEM_KEY_R
	AND B.N_VERSION_NUMBER_R                       =A.N_VERSION_NUMBER_R
	AND B.N_SOURCE_VERSION_SEQ_NUMBER_R            =A.N_SOURCE_VERSION_SEQ_NUMBER_R
	AND B.N_SEQ_R                                  =A.N_SEQ_R
	AND B.V_AMOUNT_TYPE_NAME_R                     =A.V_AMOUNT_TYPE_NAME_R
	AND B.V_AMOUNT_TYPE_NAME_R = ('MINIMUM BENEFIT')
	AND B.N_SEQ_R='9000'
	)
	);
	--where FBP_D_1.N_PAY_DTL_SOURCE_SYSTEM_KEY_R=11386783 and FBP_D_1.N_SOURCE_VERSION_SEQ_NUMBER_R=366 and FBP_D_1.n_seq_r=1;
	COMMIT;
	OUT_LOAD_STATUS:='SUCCESS';
	EXCEPTION
	WHEN OTHERS THEN
	LC_SQLCODE:=SQLCODE;
	LC_SQLERRM:=SUBSTR(SQLERRM,1,4000);
	OUT_LOAD_STATUS:=LC_SQLCODE||'-'||LC_SQLERRM;
	DBMS_OUTPUT.PUT_LINE('PRC_LOAD_FCT_BENEFIT_PMNT_DET_OFFSET2_R  EXCEPTION WITH ERROR CODE AS '
				 || SQLCODE
				 || ' '
				 || SQLERRM
				 || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
				 ||'PRC_LOAD_FCT_BENEFIT_PMNT_DET_OFFSET2_R'
				 ||';');


    RAISE_APPLICATION_ERROR(-20001,'Error in PKG_LOAD_GRP_TABLES.PRC_LOAD_FCT_BENEFIT_PMNT_DET_OFFSET2_R:->
    Error Code:'||SQLCODE||',Error message:'||SUBSTR(SQLERRM,1,4000));

	END PRC_LOAD_FCT_BENEFIT_PMNT_DET_OFFSET2_R;

	PROCEDURE PRC_LOAD_FCT_BENEFIT_PMNT_DET_OFFSET3_R(
		IN_BATCH_ID_R        IN NUMBER,
		OUT_LOAD_STATUS      OUT VARCHAR2
		)
	IS
	LD_SYSDATE DATE :=SYSDATE;
	LC_SQLCODE VARCHAR2(4000);
	LC_SQLERRM VARCHAR2(4000);
	LN_SEQUENCE_NUMBER_R NUMBER;
	LN_IN_BATCH_ID_R NUMBER:=IN_BATCH_ID_R;
	LN_LOAD_RUN_ID_R NUMBER;
	BEGIN

		IF LN_IN_BATCH_ID_R IS NULL THEN
		  OUT_LOAD_STATUS:='a) BatchID(IN_BATCH_ID) is null hence terminating the program';
		 RAISE_APPLICATION_ERROR(-20001,'a) BatchID(IN_BATCH_ID) is null hence terminating the program');
		END IF;

	SELECT   MAX(N_SEQUENCE_NUMBER_R)
		  INTO LN_SEQUENCE_NUMBER_R
	FROM ATOMIC.FCT_BENEFIT_PAYMENT_DETAIL_R;

	SELECT   COUNT(1)
		  INTO ln_load_run_id_r
	FROM ATOMIC.PRCS_JOB_LOG_R
	WHERE N_BATCH_ID_R =IN_BATCH_ID_R
	AND V_JOB_NAME_R='GRP_LOAD_FCT_BENEFIT_PMNT_DET_OFFSET3_R';


	INSERT /*+APPEND_VALUES*/ INTO ATOMIC.FCT_BENEFIT_PAYMENT_DETAIL_R
	(
	N_POLICY_SK_R
	,N_PARTY_SK_R
	,N_CLAIM_SK_R
	,N_CLAIM_COVERAGE_SK_R
	,N_CLAIM_COVERAGE_GROUP_SK_R
	,N_BATCH_ID_R
	,N_LOAD_RUN_ID_R
	,N_SEQUENCE_NUMBER_R
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
	)
	SELECT
	N_POLICY_SK_R
	,N_PARTY_SK_R
	,N_CLAIM_SK_R
	,N_CLAIM_COVERAGE_SK_R
	,N_CLAIM_COVERAGE_GROUP_SK_R
	,LN_IN_BATCH_ID_R N_BATCH_ID_R
	,LN_LOAD_RUN_ID_R N_LOAD_RUN_ID_R
	,NVL(LN_SEQUENCE_NUMBER_R,0)+ROWNUM N_SEQUENCE_NUMBER_R
	,LD_SYSDATE T_CREATION_DATE_R
	,LD_SYSDATE T_LAST_MODIFIED_DATE_R
	,'ODI' V_CREATED_BY_R
	,'ODI' V_LAST_MODIFIED_BY_R
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
	FROM
	(select DISTINCT * from (WITH FBP_1 AS (
	select DISTINCT N_PAY_SCHD_SOURCE_SYSTEM_KEY_R,N_SOURCE_VERSION_SEQ_NUMBER_R,N_SEQ_R,V_REFERENCE_R
	FROM ATOMIC.FCT_BENEFIT_PAYMENT_R
	WHERE (UPPER(V_REFERENCE_R) like 'MINIMUM BENEFIT APPLIED%' and V_PAY_DESCR_R = 'ALLSOURCE'
	AND N_BATCH_ID_R = LN_IN_BATCH_ID_R --Added by Gireesh for Incremental load
	)
	--AND N_BATCH_ID_R = 202109190000 -- Added by Gireesh 17mar
	--and n_claim_sk_r = 168169
	)
	--select * from FBP_1);
	, FBP_D_1 AS ( Select * FROM ATOMIC.FCT_BENEFIT_PAYMENT_DETAIL_R
	--WHERE N_BATCH_ID_R = 202109190000 -- Added by Gireesh 17mar
	--where V_BENEFIT_CODE_R != '382'
	where N_SEQ_R != 9001 and N_SEQ_R != 9000
	--and n_claim_sk_r = 168169
	AND N_BATCH_ID_R = LN_IN_BATCH_ID_R --Added by Gireesh for Incremental load
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
	V_PAY_STATUS_R ,N_ADJ_NET_BENEFIT_R, N_GROSS_BENEFIT_R, N_PRIMARY_PAYEE_R,V_CHECK_NUM_R, D_TRANS_DATE_R, N_ADJ_GROSS_BENEFIT_R
	FROM ATOMIC.FCT_BENEFIT_PAYMENT_R
	WHERE (UPPER(V_REFERENCE_R) like 'MINIMUM BENEFIT APPLIED%'  AND V_PAY_DESCR_R = 'ALLSOURCE')
	and UPPER(V_PAY_STATUS_R) in ('RELEASED','REVERSED','REVERSAL')
	AND N_BATCH_ID_R = LN_IN_BATCH_ID_R --Added by Gireesh for Incremental load
	--and n_claim_sk_r = 168169
	--AND N_BATCH_ID_R = 202109190000 -- Added by Gireesh 17mar
	)
	--select * from FBP_2);--Commented by Gireesh on 13-Nov-2022
	,FWS AS (Select distinct n_worksheet_seq_nbr_objectnm_r,n_source_system_key_r,n_spec_benefit_adjust_r,n_gross_benefit_r
	FROM ATOMIC.FCT_GRP_WORKSHEET
	)
	,AMT_2 AS (
	SELECT FBP_2.N_PAY_SCHD_SOURCE_SYSTEM_KEY_R,FBP_2.N_SOURCE_VERSION_SEQ_NUMBER_R,FBP_2.N_SEQ_R,fbp_2.v_pay_status_r,
	FBP_2.N_ADJ_NET_BENEFIT_R,
	FWS.n_spec_benefit_adjust_r,FWS.n_gross_benefit_r, V_CHECK_NUM_R, D_TRANS_DATE_R,
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
	FROM ATOMIC.FCT_BENEFIT_PAYMENT_DETAIL_R
	--where V_BENEFIT_CODE_R != '382'
	where N_SEQ_R != 9000 and N_SEQ_R != 9001
	--and n_claim_sk_r = 168169
	--WHERE N_BATCH_ID_R = 202109190000 -- Added by Gireesh 17mar
	AND N_BATCH_ID_R = LN_IN_BATCH_ID_R --Added by Gireesh for Incremental load
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
	FBP_D_2.N_BATCH_ID_R,
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
	) A WHERE NOT EXISTS (
	SELECT 1 FROM ATOMIC.FCT_BENEFIT_PAYMENT_DETAIL_R B
	WHERE
	B.N_PAY_DTL_SOURCE_SYSTEM_KEY_R                =A.N_PAY_DTL_SOURCE_SYSTEM_KEY_R
	AND B.N_VERSION_NUMBER_R                       =A.N_VERSION_NUMBER_R
	AND B.N_SOURCE_VERSION_SEQ_NUMBER_R            =A.N_SOURCE_VERSION_SEQ_NUMBER_R
	AND B.N_SEQ_R                                  =A.N_SEQ_R
	AND B.V_AMOUNT_TYPE_NAME_R                     =A.V_AMOUNT_TYPE_NAME_R
	AND B.V_AMOUNT_TYPE_NAME_R = 'ALLSOURCE EXCESS OFFSET'
	AND B.N_SEQ_R='9001'
	)
	)Where NVL(N_AMOUNT_R,0)<>0;--11-May-2022 Mohan changes
	COMMIT;
	OUT_LOAD_STATUS:='SUCCESS';
	EXCEPTION
	WHEN OTHERS THEN
	LC_SQLCODE:=SQLCODE;
	LC_SQLERRM:=SUBSTR(SQLERRM,1,4000);
	OUT_LOAD_STATUS:=LC_SQLCODE||'-'||LC_SQLERRM;
	DBMS_OUTPUT.PUT_LINE('PRC_LOAD_FCT_BENEFIT_PMNT_DET_OFFSET3_R  EXCEPTION WITH ERROR CODE AS '
				 || SQLCODE
				 || ' '
				 || SQLERRM
				 || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
				 ||'PRC_LOAD_FCT_BENEFIT_PMNT_DET_OFFSET3_R'
				 ||';');


    RAISE_APPLICATION_ERROR(-20001,'Error in PKG_LOAD_GRP_TABLES.PRC_LOAD_FCT_BENEFIT_PMNT_DET_OFFSET3_R:->
    Error Code:'||SQLCODE||',Error message:'||SUBSTR(SQLERRM,1,4000));

	END PRC_LOAD_FCT_BENEFIT_PMNT_DET_OFFSET3_R;


	PROCEDURE PRC_FULLLOAD_FCT_BENEFIT_PMNT_DET_OFFSET1_R(
		IN_BATCH_ID_R        IN NUMBER,
		OUT_LOAD_STATUS      OUT VARCHAR2
		)
	IS
	LD_SYSDATE DATE :=SYSDATE;
	LC_SQLCODE VARCHAR2(4000);
	LC_SQLERRM VARCHAR2(4000);
	LN_SEQUENCE_NUMBER_R NUMBER;
	LN_IN_BATCH_ID_R NUMBER:=IN_BATCH_ID_R;
	LN_LOAD_RUN_ID_R NUMBER;
	BEGIN

		IF LN_IN_BATCH_ID_R IS NULL THEN
		  OUT_LOAD_STATUS:='a) BatchID(IN_BATCH_ID) is null hence terminating the program';
		 RAISE_APPLICATION_ERROR(-20001,'a) BatchID(IN_BATCH_ID) is null hence terminating the program');
		END IF;

	SELECT   MAX(N_SEQUENCE_NUMBER_R)
		  INTO LN_SEQUENCE_NUMBER_R
	FROM ATOMIC.FCT_BENEFIT_PAYMENT_DETAIL_R;

	SELECT   COUNT(1)
		  INTO ln_load_run_id_r
	FROM ATOMIC.PRCS_JOB_LOG_R
	WHERE N_BATCH_ID_R =IN_BATCH_ID_R
	AND V_JOB_NAME_R='GRP_FULLLOAD_FCT_BENEFIT_PMNT_DET_OFFSET1_R';

	INSERT /*+APPEND_VALUES*/ INTO ATOMIC.FCT_BENEFIT_PAYMENT_DETAIL_R
	(
	N_POLICY_SK_R
	,N_PARTY_SK_R
	,N_CLAIM_SK_R
	,N_CLAIM_COVERAGE_SK_R
	,N_CLAIM_COVERAGE_GROUP_SK_R
	,N_BATCH_ID_R
	,N_LOAD_RUN_ID_R
	,N_SEQUENCE_NUMBER_R
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
	)
	SELECT
	N_POLICY_SK_R
	,N_PARTY_SK_R
	,N_CLAIM_SK_R
	,N_CLAIM_COVERAGE_SK_R
	,N_CLAIM_COVERAGE_GROUP_SK_R
	,N_BATCH_ID_R                   --For full load
	,LN_LOAD_RUN_ID_R N_LOAD_RUN_ID_R
	,NVL(LN_SEQUENCE_NUMBER_R,0)+ROWNUM N_SEQUENCE_NUMBER_R
	,LD_SYSDATE T_CREATION_DATE_R
	,LD_SYSDATE T_LAST_MODIFIED_DATE_R
	,'ODI' V_CREATED_BY_R
	,'ODI' V_LAST_MODIFIED_BY_R
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
	from
	(--13-Nov-2022 Gireesh Changes ends
	select /*+enable_parallel_dml parallel(8)*/ DISTINCT * from (WITH FBP_1 AS (
	select DISTINCT N_PAY_SCHD_SOURCE_SYSTEM_KEY_R,N_SOURCE_VERSION_SEQ_NUMBER_R,N_SEQ_R, V_REFERENCE_R, n_claim_sk_r
	FROM ATOMIC.FCT_BENEFIT_PAYMENT_R
	WHERE ( (V_REFERENCE_R) like 'ALLSOURCE%' OR UPPER(V_REFERENCE_R) like 'BACKDOOR%' )
	--where ((upper(V_REFERENCE_R) like 'ALLSOURCE%' OR UPPER(V_REFERENCE_R) like 'BACKDOOR%') or nvl((UPPER(V_REFERENCE_R)),'ALLSOURCE') not like 'MINIMUM BENEFIT APPLIED%' OR  UPPER(V_REFERENCE_R) not like 'MINIMUM BENEFIT APPLIED%')
	--AND N_BATCH_ID_R = 202109190000-- Added by Gireesh 17mar
	--and n_claim_sk_r = 168169
	--AND N_BATCH_ID_R = LN_IN_BATCH_ID_R--13-Nov-2022 Added by Gireesh for Incremental
	)
	--select * from FBP_1);
	,
	FBP_D_1 AS ( Select * FROM ATOMIC.FCT_BENEFIT_PAYMENT_DETAIL_R
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
	V_PAY_STATUS_R ,N_ADJ_NET_BENEFIT_R, N_GROSS_BENEFIT_R,N_PRIMARY_PAYEE_R,V_CHECK_NUM_R, D_TRANS_DATE_R, N_ADJ_GROSS_BENEFIT_R
	FROM ATOMIC.FCT_BENEFIT_PAYMENT_R
	WHERE  ((V_REFERENCE_R) like 'ALLSOURCE%' OR UPPER(V_REFERENCE_R) like 'BACKDOOR%' )
	AND UPPER(V_PAY_STATUS_R) in ('RELEASED','REVERSED','REVERSAL')
	--AND N_BATCH_ID_R = 202109190000 -- Added by Gireesh 17mar
	--and n_claim_sk_r = 168169
	--AND N_BATCH_ID_R = LN_IN_BATCH_ID_R --13-Nov-2022 Added by Gireesh for Incremental
	)
	--select * from FBP_2);
	,FWS AS (Select distinct n_worksheet_seq_nbr_objectnm_r,n_source_system_key_r,n_spec_benefit_adjust_r,n_gross_benefit_r
	FROM ATOMIC.FCT_GRP_WORKSHEET
	--where n_claim_sk_r = 168169
	)

	--select * from FWS);
	,AMT_2 AS (
	SELECT FBP_2.N_PAY_SCHD_SOURCE_SYSTEM_KEY_R,FBP_2.N_SOURCE_VERSION_SEQ_NUMBER_R,FBP_2.N_SEQ_R,fbp_2.v_pay_status_r,
	FBP_2.N_ADJ_NET_BENEFIT_R, N_PRIMARY_PAYEE_R,
	FWS.n_spec_benefit_adjust_r,FWS.n_gross_benefit_r, V_CHECK_NUM_R, D_TRANS_DATE_R,
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
	FROM ATOMIC.FCT_BENEFIT_PAYMENT_DETAIL_R
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
	WHERE NOT EXISTS (
	SELECT 1 FROM ATOMIC.FCT_BENEFIT_PAYMENT_DETAIL_R B
	WHERE
	B.N_PAY_DTL_SOURCE_SYSTEM_KEY_R                =A.N_PAY_DTL_SOURCE_SYSTEM_KEY_R
	AND B.N_VERSION_NUMBER_R                       =A.N_VERSION_NUMBER_R
	AND B.N_SOURCE_VERSION_SEQ_NUMBER_R            =A.N_SOURCE_VERSION_SEQ_NUMBER_R
	AND B.N_SEQ_R                                  =A.N_SEQ_R
	AND B.V_AMOUNT_TYPE_NAME_R                     =A.V_AMOUNT_TYPE_NAME_R
	AND B.V_AMOUNT_TYPE_NAME_R = 'ALLSOURCE EXCESS OFFSET'
	AND B.N_SEQ_R='9000'
	)
	;
	COMMIT;
	OUT_LOAD_STATUS:='SUCCESS';
	EXCEPTION
	WHEN OTHERS THEN
	LC_SQLCODE:=SQLCODE;
	LC_SQLERRM:=SUBSTR(SQLERRM,1,4000);
	OUT_LOAD_STATUS:=LC_SQLCODE||'-'||LC_SQLERRM;
	DBMS_OUTPUT.PUT_LINE('PRC_FULLLOAD_FCT_BENEFIT_PMNT_DET_OFFSET1_R  EXCEPTION WITH ERROR CODE AS '
				 || SQLCODE
				 || ' '
				 || SQLERRM
				 || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
				 ||'PRC_FULLLOAD_FCT_BENEFIT_PMNT_DET_OFFSET1_R'
				 ||';');

    RAISE_APPLICATION_ERROR(-20001,'Error in PKG_LOAD_GRP_TABLES.PRC_FULLLOAD_FCT_BENEFIT_PMNT_DET_OFFSET1_R:->
    Error Code:'||SQLCODE||',Error message:'||SUBSTR(SQLERRM,1,4000));

	END PRC_FULLLOAD_FCT_BENEFIT_PMNT_DET_OFFSET1_R;


	PROCEDURE PRC_FULLLOAD_FCT_BENEFIT_PMNT_DET_OFFSET2_R(
		IN_BATCH_ID_R        IN NUMBER,
		OUT_LOAD_STATUS      OUT VARCHAR2
		)
	IS
	LD_SYSDATE DATE :=SYSDATE;
	LC_SQLCODE VARCHAR2(4000);
	LC_SQLERRM VARCHAR2(4000);
	LN_SEQUENCE_NUMBER_R NUMBER;
	LN_IN_BATCH_ID_R NUMBER:=IN_BATCH_ID_R;
	LN_LOAD_RUN_ID_R NUMBER;
	BEGIN

		IF LN_IN_BATCH_ID_R IS NULL THEN
		  OUT_LOAD_STATUS:='a) BatchID(IN_BATCH_ID) is null hence terminating the program';
		 RAISE_APPLICATION_ERROR(-20001,'a) BatchID(IN_BATCH_ID) is null hence terminating the program');
		END IF;

	SELECT   MAX(N_SEQUENCE_NUMBER_R)
		  INTO LN_SEQUENCE_NUMBER_R
	FROM ATOMIC.FCT_BENEFIT_PAYMENT_DETAIL_R;

	SELECT   COUNT(1)
		  INTO ln_load_run_id_r
	FROM ATOMIC.PRCS_JOB_LOG_R
	WHERE N_BATCH_ID_R =IN_BATCH_ID_R
	AND V_JOB_NAME_R='GRP_FULLLOAD_FCT_BENEFIT_PMNT_DET_OFFSET2_R';

	INSERT /*+APPEND_VALUES*/ INTO ATOMIC.FCT_BENEFIT_PAYMENT_DETAIL_R
	(
	N_POLICY_SK_R
	,N_PARTY_SK_R
	,N_CLAIM_SK_R
	,N_CLAIM_COVERAGE_SK_R
	,N_CLAIM_COVERAGE_GROUP_SK_R
	,N_BATCH_ID_R
	,N_LOAD_RUN_ID_R
	,N_SEQUENCE_NUMBER_R
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
	)
	SELECT
	N_POLICY_SK_R
	,N_PARTY_SK_R
	,N_CLAIM_SK_R
	,N_CLAIM_COVERAGE_SK_R
	,N_CLAIM_COVERAGE_GROUP_SK_R
	,N_BATCH_ID_R
	,LN_LOAD_RUN_ID_R N_LOAD_RUN_ID_R
	,NVL(LN_SEQUENCE_NUMBER_R,0)+ROWNUM N_SEQUENCE_NUMBER_R
	,LD_SYSDATE T_CREATION_DATE_R
	,LD_SYSDATE T_LAST_MODIFIED_DATE_R
	,'ODI' V_CREATED_BY_R
	,'ODI' V_LAST_MODIFIED_BY_R
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
	FROM
	(select /*+enable_parallel_dml parallel(8)*/ DISTINCT * from (WITH FBP_1 AS (
	select DISTINCT N_PAY_SCHD_SOURCE_SYSTEM_KEY_R,N_SOURCE_VERSION_SEQ_NUMBER_R,N_SEQ_R,V_REFERENCE_R , N_ADJ_NET_BENEFIT_R
	FROM ATOMIC.FCT_BENEFIT_PAYMENT_R
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
	FROM ATOMIC.FCT_BENEFIT_PAYMENT_DETAIL_R
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

	FROM FBP_D_2 INNER JOIN FBP_1
	ON FBP_1.N_PAY_SCHD_SOURCE_SYSTEM_KEY_R = TRIM(FBP_D_2.N_PAY_DTL_SOURCE_SYSTEM_KEY_R)
	AND FBP_1.N_SOURCE_VERSION_SEQ_NUMBER_R = TRIM(FBP_D_2.N_SOURCE_VERSION_SEQ_NUMBER_R)
	AND FBP_1.N_SEQ_R = TRIM(FBP_D_2.N_GROUP_SEQ_R)
	) A WHERE NOT EXISTS (
	SELECT 1 FROM ATOMIC.FCT_BENEFIT_PAYMENT_DETAIL_R B
	WHERE
	B.N_PAY_DTL_SOURCE_SYSTEM_KEY_R                =A.N_PAY_DTL_SOURCE_SYSTEM_KEY_R
	AND B.N_VERSION_NUMBER_R                       =A.N_VERSION_NUMBER_R
	AND B.N_SOURCE_VERSION_SEQ_NUMBER_R            =A.N_SOURCE_VERSION_SEQ_NUMBER_R
	AND B.N_SEQ_R                                  =A.N_SEQ_R
	AND B.V_AMOUNT_TYPE_NAME_R                     =A.V_AMOUNT_TYPE_NAME_R
	AND B.V_AMOUNT_TYPE_NAME_R = ('MINIMUM BENEFIT')
	AND B.N_SEQ_R='9000'
	)
	);
	--where FBP_D_1.N_PAY_DTL_SOURCE_SYSTEM_KEY_R=11386783 and FBP_D_1.N_SOURCE_VERSION_SEQ_NUMBER_R=366 and FBP_D_1.n_seq_r=1;
	COMMIT;
	OUT_LOAD_STATUS:='SUCCESS';
	EXCEPTION
	WHEN OTHERS THEN
	LC_SQLCODE:=SQLCODE;
	LC_SQLERRM:=SUBSTR(SQLERRM,1,4000);
	OUT_LOAD_STATUS:=LC_SQLCODE||'-'||LC_SQLERRM;
	DBMS_OUTPUT.PUT_LINE('PRC_FULLLOAD_FCT_BENEFIT_PMNT_DET_OFFSET2_R  EXCEPTION WITH ERROR CODE AS '
				 || SQLCODE
				 || ' '
				 || SQLERRM
				 || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
				 ||'PRC_FULLLOAD_FCT_BENEFIT_PMNT_DET_OFFSET2_R'
				 ||';');


    RAISE_APPLICATION_ERROR(-20001,'Error in PKG_LOAD_GRP_TABLES.PRC_FULLLOAD_FCT_BENEFIT_PMNT_DET_OFFSET2_R:->
    Error Code:'||SQLCODE||',Error message:'||SUBSTR(SQLERRM,1,4000));

	END PRC_FULLLOAD_FCT_BENEFIT_PMNT_DET_OFFSET2_R;

	PROCEDURE PRC_FULLLOAD_FCT_BENEFIT_PMNT_DET_OFFSET3_R(
		IN_BATCH_ID_R        IN NUMBER,
		OUT_LOAD_STATUS      OUT VARCHAR2
		)
	IS
	LD_SYSDATE DATE :=SYSDATE;
	LC_SQLCODE VARCHAR2(4000);
	LC_SQLERRM VARCHAR2(4000);
	LN_SEQUENCE_NUMBER_R NUMBER;
	LN_IN_BATCH_ID_R NUMBER:=IN_BATCH_ID_R;
	LN_LOAD_RUN_ID_R NUMBER;
	BEGIN

		IF LN_IN_BATCH_ID_R IS NULL THEN
		  OUT_LOAD_STATUS:='a) BatchID(IN_BATCH_ID) is null hence terminating the program';
		 RAISE_APPLICATION_ERROR(-20001,'a) BatchID(IN_BATCH_ID) is null hence terminating the program');
		END IF;

	SELECT   MAX(N_SEQUENCE_NUMBER_R)
		  INTO LN_SEQUENCE_NUMBER_R
	FROM ATOMIC.FCT_BENEFIT_PAYMENT_DETAIL_R;

	SELECT   COUNT(1)
		  INTO ln_load_run_id_r
	FROM ATOMIC.PRCS_JOB_LOG_R
	WHERE N_BATCH_ID_R =IN_BATCH_ID_R
	AND V_JOB_NAME_R='GRP_FULLLOAD_FCT_BENEFIT_PMNT_DET_OFFSET3_R';


	INSERT /*+APPEND_VALUES*/ INTO ATOMIC.FCT_BENEFIT_PAYMENT_DETAIL_R
	(
	N_POLICY_SK_R
	,N_PARTY_SK_R
	,N_CLAIM_SK_R
	,N_CLAIM_COVERAGE_SK_R
	,N_CLAIM_COVERAGE_GROUP_SK_R
	,N_BATCH_ID_R
	,N_LOAD_RUN_ID_R
	,N_SEQUENCE_NUMBER_R
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
	)
	SELECT
	N_POLICY_SK_R
	,N_PARTY_SK_R
	,N_CLAIM_SK_R
	,N_CLAIM_COVERAGE_SK_R
	,N_CLAIM_COVERAGE_GROUP_SK_R
	,N_BATCH_ID_R
	,LN_LOAD_RUN_ID_R N_LOAD_RUN_ID_R
	,NVL(LN_SEQUENCE_NUMBER_R,0)+ROWNUM N_SEQUENCE_NUMBER_R
	,LD_SYSDATE T_CREATION_DATE_R
	,LD_SYSDATE T_LAST_MODIFIED_DATE_R
	,'ODI' V_CREATED_BY_R
	,'ODI' V_LAST_MODIFIED_BY_R
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
	FROM
	(select /*+enable_parallel_dml parallel(8)*/ DISTINCT * from (WITH FBP_1 AS (
	select DISTINCT N_PAY_SCHD_SOURCE_SYSTEM_KEY_R,N_SOURCE_VERSION_SEQ_NUMBER_R,N_SEQ_R,V_REFERENCE_R
	FROM ATOMIC.FCT_BENEFIT_PAYMENT_R
	WHERE (UPPER(V_REFERENCE_R) like 'MINIMUM BENEFIT APPLIED%' and V_PAY_DESCR_R = 'ALLSOURCE'
	--AND N_BATCH_ID_R = LN_IN_BATCH_ID_R --Added by Gireesh for Incremental load
	)
	--AND N_BATCH_ID_R = 202109190000 -- Added by Gireesh 17mar
	--and n_claim_sk_r = 168169
	)
	--select * from FBP_1);
	, FBP_D_1 AS ( Select * FROM ATOMIC.FCT_BENEFIT_PAYMENT_DETAIL_R
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
	V_PAY_STATUS_R ,N_ADJ_NET_BENEFIT_R, N_GROSS_BENEFIT_R, N_PRIMARY_PAYEE_R,V_CHECK_NUM_R, D_TRANS_DATE_R, N_ADJ_GROSS_BENEFIT_R
	FROM ATOMIC.FCT_BENEFIT_PAYMENT_R
	WHERE (UPPER(V_REFERENCE_R) like 'MINIMUM BENEFIT APPLIED%'  AND V_PAY_DESCR_R = 'ALLSOURCE')
	and UPPER(V_PAY_STATUS_R) in ('RELEASED','REVERSED','REVERSAL')
	--AND N_BATCH_ID_R = LN_IN_BATCH_ID_R --Added by Gireesh for Incremental load
	--and n_claim_sk_r = 168169
	--AND N_BATCH_ID_R = 202109190000 -- Added by Gireesh 17mar
	)
	--select * from FBP_2);--Commented by Gireesh on 13-Nov-2022
	,FWS AS (Select distinct n_worksheet_seq_nbr_objectnm_r,n_source_system_key_r,n_spec_benefit_adjust_r,n_gross_benefit_r
	FROM ATOMIC.FCT_GRP_WORKSHEET
	)
	,AMT_2 AS (
	SELECT FBP_2.N_PAY_SCHD_SOURCE_SYSTEM_KEY_R,FBP_2.N_SOURCE_VERSION_SEQ_NUMBER_R,FBP_2.N_SEQ_R,fbp_2.v_pay_status_r,
	FBP_2.N_ADJ_NET_BENEFIT_R,
	FWS.n_spec_benefit_adjust_r,FWS.n_gross_benefit_r, V_CHECK_NUM_R, D_TRANS_DATE_R,
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
	FROM ATOMIC.FCT_BENEFIT_PAYMENT_DETAIL_R
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
	) A WHERE NOT EXISTS (
	SELECT 1 FROM ATOMIC.FCT_BENEFIT_PAYMENT_DETAIL_R B
	WHERE
	B.N_PAY_DTL_SOURCE_SYSTEM_KEY_R                =A.N_PAY_DTL_SOURCE_SYSTEM_KEY_R
	AND B.N_VERSION_NUMBER_R                       =A.N_VERSION_NUMBER_R
	AND B.N_SOURCE_VERSION_SEQ_NUMBER_R            =A.N_SOURCE_VERSION_SEQ_NUMBER_R
	AND B.N_SEQ_R                                  =A.N_SEQ_R
	AND B.V_AMOUNT_TYPE_NAME_R                     =A.V_AMOUNT_TYPE_NAME_R
	AND B.V_AMOUNT_TYPE_NAME_R = 'ALLSOURCE EXCESS OFFSET'
	AND B.N_SEQ_R='9001'
	)
	)Where NVL(N_AMOUNT_R,0)<>0;--11-May-2022 Mohan changes
	COMMIT;
	OUT_LOAD_STATUS:='SUCCESS';
	EXCEPTION
	WHEN OTHERS THEN
	LC_SQLCODE:=SQLCODE;
	LC_SQLERRM:=SUBSTR(SQLERRM,1,4000);
	OUT_LOAD_STATUS:=LC_SQLCODE||'-'||LC_SQLERRM;
	DBMS_OUTPUT.PUT_LINE('PRC_FULLLOAD_FCT_BENEFIT_PMNT_DET_OFFSET3_R  EXCEPTION WITH ERROR CODE AS '
				 || SQLCODE
				 || ' '
				 || SQLERRM
				 || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
				 ||'PRC_FULLLOAD_FCT_BENEFIT_PMNT_DET_OFFSET3_R'
				 ||';');

    RAISE_APPLICATION_ERROR(-20001,'Error in PKG_LOAD_GRP_TABLES.PRC_FULLLOAD_FCT_BENEFIT_PMNT_DET_OFFSET3_R:->
    Error Code:'||SQLCODE||',Error message:'||SUBSTR(SQLERRM,1,4000));

	END PRC_FULLLOAD_FCT_BENEFIT_PMNT_DET_OFFSET3_R;

	PROCEDURE PRC_LOAD_VUE_FCT_GRP_POLICY_R(
		IN_BATCH_ID_R        IN NUMBER,
		OUT_LOAD_STATUS      OUT VARCHAR2
		)
	IS
	LD_SYSDATE DATE :=SYSDATE;
	LC_SQLCODE VARCHAR2(4000);
	LC_SQLERRM VARCHAR2(4000);
	LN_SEQUENCE_NUMBER_R NUMBER;
	LN_IN_BATCH_ID_R NUMBER:=IN_BATCH_ID_R;
	LN_LOAD_RUN_ID_R NUMBER;
	BEGIN

		IF LN_IN_BATCH_ID_R IS NULL THEN
		  OUT_LOAD_STATUS:='a) BatchID(IN_BATCH_ID) is null hence terminating the program';
		 RAISE_APPLICATION_ERROR(-20001,'a) BatchID(IN_BATCH_ID) is null hence terminating the program');
		END IF;

	SELECT   MAX(N_SEQUENCE_NUMBER_R)
		  INTO LN_SEQUENCE_NUMBER_R
	FROM ATOMIC.FCT_GRP_POLICY_R;

	SELECT   COUNT(1)
		  INTO ln_load_run_id_r
	FROM ATOMIC.PRCS_JOB_LOG_R
	WHERE N_BATCH_ID_R =IN_BATCH_ID_R
	AND V_JOB_NAME_R='PKG_GRP_LOAD_VUE_FCT_GRP_POLICY_R';


	INSERT /*+APPEND_VALUES*/ INTO ATOMIC.FCT_GRP_POLICY_R
	(
	V_SOURCE_SYSTEM_NAME_R
	,V_SUBJECT_AREA_TYPE_R
	,T_EVENT_TIMESTAMP_R
	,V_NAMED_INSURED_R
	,V_JURISDICTION_R
	,D_RATED_DATE_R
	,V_CLASS_OF_BUSINESS_R
	,N_SOURCE_SYSTEM_KEY_R
	,D_RENEWAL_DATE_R
	,V_LINE_OF_BUSINESS_R
	,N_AUTO_RENEWAL_R
	,N_CENSUS_REQUESTED_R
	,D_CENSUS_RECEIVED_DATE_R
	,D_NOCENSUS_DEADLINE_DATE_R
	,N_CENSUS_RECEIVED_FLAG_R
	,V_ANNIVERSARY_DATE_AND_MONTH_R
	,V_TYPE_OF_BILLING_R
	,N_RATE_GUARANTEE_R
	,N_DEPOSIT_AMOUNT_R
	,N_EMPLOYEES_ACTIVELY_AT_WORK_R
	,N_GRANDFATHER_EMP_NOT_ACTIVE_R
	,V_FUNDING_ARRANGEMENT_R
	,N_MEDICAL_CONVERSION_R
	,N_RENEWAL_NOTIFICATION_DAYS_R
	,N_CLAIMS_TAX_INDICATOR_R
	,V_CLAIMS_DISTRIBUTION_CHECKS_R
	,D_INSTALLATION_DATE_R
	,N_COST_SHIFTING_R
	,D_CALCULATED_EXPIRY_DATE_R
	,N_INITIAL_CHECK_AMT_R
	,N_PAYABLE_RATE_R
	,N_MANUAL_RATE_R
	,N_TOTAL_CLASSES_R
	,D_RENEWAL_CENSUS_REQDATE1_R
	,D_RENEWAL_CENSUS_REQDATE2_R
	,D_RENEWAL_CENSUS_REQDATE3_R
	,V_INFORMATION_5500_R
	,N_RENEWAL_LIVES_R
	,N_NUMBER_OF_BILL_GROUP_R
	,N_CUSTOMER_CONTRACTUAL_CHG_R
	,N_OVERRIDE_EXPIRY_DATE_R
	,V_VERSION_REASON_CODE_R
	,N_COST_SHIFT_PREMIUM_R
	,N_MRP_OVERRIDEN_R
	,N_EXP_COMMISSIONS_R
	,N_EXP_PREMIUM_TAX_R
	,N_EXP_PER_CONTRACT_R
	,N_EXP_PERCENT_OF_PREM_R
	,N_EXP_TOTAL_R
	,N_TOTAL_FINAL_PREMIUM_R
	,V_LOB_BLOCK_R
	,N_RI_TRUST_FLAG_R
	,N_CALC_CENSUS_PCC_R
	,N_STEP_RATE_R
	,V_GE_DESC_R
	,V_GE_EMPLOYEE_R
	,N_GE_ARE_EMP_EXCLUDED_R
	,V_GRANDFATHERING_EMP_DATA_R
	,N_CREATED_FROM_CUSTOMER_R
	,N_NUM_LIVES_R
	,V_EMP_EXCLUDED_R
	,N_FULL_TIME_HOURS_R
	,N_PART_TIME_ELIGIBILITY_R
	,N_PART_TIME_HOURS_R
	,N_QUOTED_AMOUNT_R
	,N_PARTICIPATING_NUM_LIVES_R
	,N_RENEW_GROUP_R
	,D_PROPOSAL_DATE_R
	,N_ACCUM_UW_FACTOR_R
	,N_ACCUM_OCC_FACTOR_R
	,V_MATRIX_ADMINISTERED_R
	,N_INIT_PROP_RENEWAL_RATE_R
	,N_PLAN_CHANGE_PERCENT_R
	,N_INIT_PROP_RENEWAL_RATE2_R
	,N_PLAN_CHANGE_PERCENT2_R
	,V_CONTRACT_ISSUE_STATE_R
	,V_GI_BILLING_R
	,V_GI_BILLING_RULE_R
	,V_EMPLOYEE_APPLICATION_REQUI_R
	,N_CLAIMS_PER_1000_R
	,V_ADMINISTERED_BY_R
	,V_ORIG_SYSTEM_R
	,V_BRAND_NAME_R
	,V_MEMEXCHANGE_R
	,V_MEMBLOCK_R
	,N_W2_EXCLUDE_FICA_MATCH_R
	,V_PLANDESIGN_VERSION_R
	,T_EFFECTIVE_START_DATE_R
	,D_EFFECTIVE_END_DATE_R
	,V_POLICY_NUMBER_R
	,T_POLICY_EFFECTIVE_DATE_R
	,T_POLICY_EXPIRY_DATE_R
	,N_POLICY_SK_R                  --NOT NULL
	,N_VERSION_NUMBER_R
	,N_QUOTE_SK_R
	--,N_CUST_PARTY_SK_R              --NOT NULL --Commented by Gireesh 09-Aug-2022
	,N_BATCH_ID_R                   --NOT NULL
	,N_LOAD_RUN_ID_R                --NOT NULL
	,N_SEQUENCE_NUMBER_R            --NOT NULL
	,T_CREATION_DATE_R              --NOT NULL
	,T_LAST_MODIFIED_DATE_R         --NOT NULL
	,V_CREATED_BY_R                 --NOT NULL
	,V_LAST_MODIFIED_BY_R           --NOT NULL
	,FIC_MIS_DATE_R                 --NOT NULL
	,V_CROSS_SELL_INDICATOR_R
	,V_6MNTH_CROSS_SELL_INDICATOR_R
	,V_REWRITE_INDICATOR_R
	,V_ANY_LOB_CROSS_SELL_R
	,V_LTD_CROSS_SELL_R
	,V_STD_CROSS_SELL_R
	,V_LIFE_CROSS_SELL_R
	,V_BASIC_LIFE_CROSS_SELL_R
	,V_SUPP_LIFE_CROSS_SELL_R
	,V_DEP_LIFE_CROSS_SELL_R
	,V_ADD_CROSS_SELL_R
	,V_SR_CROSS_SELL_R
	,V_VAR_CROSS_SELL_R
	,V_VAI_CROSS_SELL_R
	,V_VCI_CROSS_SELL_R
	,N_TOTAL_PRODUCT_LINES_R
	,V_5500_POLICY_INFORCE_IND_R
	,V_ASO_FEE_CODE_R
	,V_ASO_FEE_DESC_R
	,N_ASO_SETUP_FEE_AMT_R
	,N_ASO_FEE_AMT_R
	,V_SIC_CODE_R
	,V_POLICY_TYPE_DESC_R
	,V_RATEBOOK_ID_R
	,V_RATEBOOK_DESC_R
	,D_RATEBOOK_EFFECTIVE_DATE_R
	,V_VOLUNTARY_IND_R
	,V_PROD_PRODUCT_LINE_CODE_R
	,V_PROD_PRODUCT_LINE_DESC_R
	,V_SMARTCHOICE_IND_R
	,D_UW_WORK_MONTH_R
	,V_UW_NEEDED_RENEWAL_STATUS_R
	,N_UW_NEEDED_PERCENT_R
	,N_UW_REQUESTED_PERCENT_R
	,V_UW_NEEDED_UNDERWRITER_NAME_R
	,V_UW_NEEDED_COMMENTS_R
	,D_UW_NEXT_RENEWAL_DATE_R
	,V_UW_TRK_NEEDED_RENEW_STATUS_R
	,N_UW_TRK_NEEDED_PERCENT_R
	,N_UW_TRK_REQUESTED_PERCENT_R
	,V_UW_TRK_NEEDED_UW_NAME_R
	,V_UW_TRK_NEEDED_COMMENTS_R
	,D_UW_TRK_NEXT_RENEWAL_DATE_R
	,V_CASE_SIZE_SORT_R
	,D_MOST_RECENT_CENSUS_DATE_R
	,N_POLICY_LIVES_R
	--,V_PBC_SUB_TEAM_R                        --Commented by Gireesh 09-Aug-2022
	--,V_PBC_TEAM_NAME_R                       --Commented by Gireesh 09-Aug-2022
	,V_NEW_BUSINESS_INDICATOR_R
	,V_SIC_DESC_R
	,V_SIC_CATEGORY_R
	,V_IEB_IND_R
	,V_SIC_MAJOR_CODE_R
	,V_SIC_MAJOR_RANGE_R
	,V_SIC_CATEGORY_GROUP_CODE_R
	,V_SIC_CATEGORY_GROUP_DESC_R
	,V_SIC_CATEGORY_GROUP_RANGE_R
	,F_PHYSICAL_DELETE_R
	,V_CHANGE_REASON_R
	,D_UNADJ_POLICY_EFF_DATE_R
	,V_PRIVACY_INDICATOR_R
	,N_CUST_PARTY_SK_R                       --Added by Gireesh 09-Aug-2022
	,V_PBC_SUB_TEAM_R                        --Added by Gireesh 09-Aug-2022
	,V_PBC_TEAM_NAME_R                       --Added by Gireesh 09-Aug-2022
	)
	select
	V_SOURCE_SYSTEM_NAME_R
	,V_SUBJECT_AREA_TYPE_R
	,T_EVENT_TIMESTAMP_R
	,V_NAMED_INSURED_R
	,V_JURISDICTION_R
	,D_RATED_DATE_R
	,V_CLASS_OF_BUSINESS_R
	,N_SOURCE_SYSTEM_KEY_R
	,D_RENEWAL_DATE_R
	,V_LINE_OF_BUSINESS_R
	,N_AUTO_RENEWAL_R
	,N_CENSUS_REQUESTED_R
	,D_CENSUS_RECEIVED_DATE_R
	,D_NOCENSUS_DEADLINE_DATE_R
	,N_CENSUS_RECEIVED_FLAG_R
	,V_ANNIVERSARY_DATE_AND_MONTH_R
	,V_TYPE_OF_BILLING_R
	,N_RATE_GUARANTEE_R
	,N_DEPOSIT_AMOUNT_R
	,N_EMPLOYEES_ACTIVELY_AT_WORK_R
	,N_GRANDFATHER_EMP_NOT_ACTIVE_R
	,V_FUNDING_ARRANGEMENT_R
	,N_MEDICAL_CONVERSION_R
	,N_RENEWAL_NOTIFICATION_DAYS_R
	,N_CLAIMS_TAX_INDICATOR_R
	,V_CLAIMS_DISTRIBUTION_CHECKS_R
	,D_INSTALLATION_DATE_R
	,N_COST_SHIFTING_R
	,D_CALCULATED_EXPIRY_DATE_R
	,N_INITIAL_CHECK_AMT_R
	,N_PAYABLE_RATE_R
	,N_MANUAL_RATE_R
	,N_TOTAL_CLASSES_R
	,D_RENEWAL_CENSUS_REQDATE1_R
	,D_RENEWAL_CENSUS_REQDATE2_R
	,D_RENEWAL_CENSUS_REQDATE3_R
	,V_INFORMATION_5500_R
	,N_RENEWAL_LIVES_R
	,N_NUMBER_OF_BILL_GROUP_R
	,N_CUSTOMER_CONTRACTUAL_CHG_R
	,N_OVERRIDE_EXPIRY_DATE_R
	,V_VERSION_REASON_CODE_R
	,N_COST_SHIFT_PREMIUM_R
	,N_MRP_OVERRIDEN_R
	,N_EXP_COMMISSIONS_R
	,N_EXP_PREMIUM_TAX_R
	,N_EXP_PER_CONTRACT_R
	,N_EXP_PERCENT_OF_PREM_R
	,N_EXP_TOTAL_R
	,N_TOTAL_FINAL_PREMIUM_R
	,V_LOB_BLOCK_R
	,N_RI_TRUST_FLAG_R
	,N_CALC_CENSUS_PCC_R
	,N_STEP_RATE_R
	,V_GE_DESC_R
	,V_GE_EMPLOYEE_R
	,N_GE_ARE_EMP_EXCLUDED_R
	,V_GRANDFATHERING_EMP_DATA_R
	,N_CREATED_FROM_CUSTOMER_R
	,N_NUM_LIVES_R
	,V_EMP_EXCLUDED_R
	,N_FULL_TIME_HOURS_R
	,N_PART_TIME_ELIGIBILITY_R
	,N_PART_TIME_HOURS_R
	,N_QUOTED_AMOUNT_R
	,N_PARTICIPATING_NUM_LIVES_R
	,N_RENEW_GROUP_R
	,D_PROPOSAL_DATE_R
	,N_ACCUM_UW_FACTOR_R
	,N_ACCUM_OCC_FACTOR_R
	,V_MATRIX_ADMINISTERED_R
	,N_INIT_PROP_RENEWAL_RATE_R
	,N_PLAN_CHANGE_PERCENT_R
	,N_INIT_PROP_RENEWAL_RATE2_R
	,N_PLAN_CHANGE_PERCENT2_R
	,V_CONTRACT_ISSUE_STATE_R
	,V_GI_BILLING_R
	,V_GI_BILLING_RULE_R
	,V_EMPLOYEE_APPLICATION_REQUI_R
	,N_CLAIMS_PER_1000_R
	,V_ADMINISTERED_BY_R
	,V_ORIG_SYSTEM_R
	,V_BRAND_NAME_R
	,V_MEMEXCHANGE_R
	,V_MEMBLOCK_R
	,N_W2_EXCLUDE_FICA_MATCH_R
	,V_PLANDESIGN_VERSION_R
	,T_EFFECTIVE_START_DATE_R
	,D_EFFECTIVE_END_DATE_R
	,V_POLICY_NUMBER_R
	,T_POLICY_EFFECTIVE_DATE_R
	,T_POLICY_EXPIRY_DATE_R
	,N_POLICY_SK_R                  --NOT NULL
	,N_VERSION_NUMBER_R
	,N_QUOTE_SK_R
	--,N_CUST_PARTY_SK_R              --NOT NULL --Commented by Gireesh 09-Aug-2022
	,IN_BATCH_ID_R                   --NOT NULL
	,LN_LOAD_RUN_ID_R               N_LOAD_RUN_ID_R --NOT NULL
	,(NVL(LN_SEQUENCE_NUMBER_R,0)+ROWNUM) N_SEQUENCE_NUMBER_R            --NOT NULL
	,LD_SYSDATE T_CREATION_DATE_R              --NOT NULL
	,LD_SYSDATE T_LAST_MODIFIED_DATE_R         --NOT NULL
	,'ODI' V_CREATED_BY_R                 --NOT NULL
	,'ODI' V_LAST_MODIFIED_BY_R           --NOT NULL
	,FIC_MIS_DATE_R                 --NOT NULL
	,V_CROSS_SELL_INDICATOR_R
	,V_6MNTH_CROSS_SELL_INDICATOR_R
	,V_REWRITE_INDICATOR_R
	,V_ANY_LOB_CROSS_SELL_R
	,V_LTD_CROSS_SELL_R
	,V_STD_CROSS_SELL_R
	,V_LIFE_CROSS_SELL_R
	,V_BASIC_LIFE_CROSS_SELL_R
	,V_SUPP_LIFE_CROSS_SELL_R
	,V_DEP_LIFE_CROSS_SELL_R
	,V_ADD_CROSS_SELL_R
	,V_SR_CROSS_SELL_R
	,V_VAR_CROSS_SELL_R
	,V_VAI_CROSS_SELL_R
	,V_VCI_CROSS_SELL_R
	,N_TOTAL_PRODUCT_LINES_R
	,V_5500_POLICY_INFORCE_IND_R
	,V_ASO_FEE_CODE_R
	,V_ASO_FEE_DESC_R
	,N_ASO_SETUP_FEE_AMT_R
	,N_ASO_FEE_AMT_R
	,V_SIC_CODE_R
	,V_POLICY_TYPE_DESC_R
	,V_RATEBOOK_ID_R
	,V_RATEBOOK_DESC_R
	,D_RATEBOOK_EFFECTIVE_DATE_R
	,V_VOLUNTARY_IND_R
	,V_PROD_PRODUCT_LINE_CODE_R
	,V_PROD_PRODUCT_LINE_DESC_R
	,V_SMARTCHOICE_IND_R
	,D_UW_WORK_MONTH_R
	,V_UW_NEEDED_RENEWAL_STATUS_R
	,N_UW_NEEDED_PERCENT_R
	,N_UW_REQUESTED_PERCENT_R
	,V_UW_NEEDED_UNDERWRITER_NAME_R
	,V_UW_NEEDED_COMMENTS_R
	,D_UW_NEXT_RENEWAL_DATE_R
	,V_UW_TRK_NEEDED_RENEW_STATUS_R
	,N_UW_TRK_NEEDED_PERCENT_R
	,N_UW_TRK_REQUESTED_PERCENT_R
	,V_UW_TRK_NEEDED_UW_NAME_R
	,V_UW_TRK_NEEDED_COMMENTS_R
	,D_UW_TRK_NEXT_RENEWAL_DATE_R
	,V_CASE_SIZE_SORT_R
	,D_MOST_RECENT_CENSUS_DATE_R
	,N_POLICY_LIVES_R
	--,V_PBC_SUB_TEAM_R    --Commented by Gireesh 09-Aug-2022
	--,V_PBC_TEAM_NAME_R   --Commented by Gireesh 09-Aug-2022
	,V_NEW_BUSINESS_INDICATOR_R
	,V_SIC_DESC_R
	,V_SIC_CATEGORY_R
	,V_IEB_IND_R
	,V_SIC_MAJOR_CODE_R
	,V_SIC_MAJOR_RANGE_R
	,V_SIC_CATEGORY_GROUP_CODE_R
	,V_SIC_CATEGORY_GROUP_DESC_R
	,V_SIC_CATEGORY_GROUP_RANGE_R
	,F_PHYSICAL_DELETE_R
	,V_CHANGE_REASON_R
	,D_UNADJ_POLICY_EFF_DATE_R
	,V_PRIVACY_INDICATOR_R
	,N_CUST_PARTY_SK_R--Added by Gireesh 09-Aug-2022
	,V_PBC_SUB_TEAM_R--Added by Gireesh 09-Aug-2022
	,V_PBC_TEAM_NAME_R--Added by Gireesh 09-Aug-2022
	 from (
	 --Gireesh changes starts 09-Aug-2022
	(select B.*
	,NVL(NVL(E.N_PARTY_SK_R, D.N_PARTY_SK_R),-1) as  N_CUST_PARTY_SK_R
	,CASE  WHEN DIM_GRP_MTOPTION_R_NSC.v_ITEM_r LIKE '%NSC%' THEN DIM_GRP_MTOPTION_R_NSC.V_PBC_SUB_TEAM_R WHEN DIM_GRP_MTOPTION_R_NOTNSC.v_ITEM_r NOT LIKE '%NSC%' THEN DIM_GRP_MTOPTION_R_NOTNSC.v_ITEM_r WHEN STG_PBC_RSO_TEAM_R_ET_STEP1.V_NEW_BUSINESS_IND_R = 'INFORCE' AND  UPPER(STG_PBC_RSO_TEAM_R_ET_STEP1.V_RSO_DESC_R)  NOT LIKE 'NSC%'  THEN NVL(STG_PBC_RSO_TEAM_R_ET_STEP1.V_PBC_SUB_TEAM_R,'UNKNOWN')  ELSE NULL END AS V_PBC_SUB_TEAM_R
	,case when DIM_GRP_MTOPTION_R_NSC.V_ITEM_R like '%NSC%' then DIM_GRP_MTOPTION_R_NSC.V_PBC_TEAM_NAME_R when DIM_GRP_MTOPTION_R_NOTNSC.V_ITEM_R not like '%NSC%' then case DIM_GRP_MTOPTION_R_NOTNSC.V_ITEM_R when 'TEAM 7' then 'Team L' when 'TEAM A'  then 'Team L'  when 'TEAM B'  then 'Team L'  when 'TEAM C'  then 'Team L'  when 'TEAM D'  then 'Team L'  when 'TEAM E'  then 'Team L'  when 'TEAM F'  then 'Team L'  when 'TEAM H'  then 'Team L'  when 'TEAM I'  then 'Team L'  when 'TEAM J'  then 'Team L'  when 'TEAM K'  then 'Team L'  when 'TEAM L'  then 'Team L'  when 'TEAM N'  then 'Team L'  when 'TEAM P'  then 'Team L'  when 'TEAM G'  then 'Team S'  when 'TEAM 8'  then 'Team S'  when 'TEAM 9'  then 'Team S'  when 'FER'  then 'Team R'  else 'Team S' end when STG_PBC_RSO_TEAM_R_ET_STEP1.V_NEW_BUSINESS_IND_R = 'INFORCE' and  UPPER(STG_PBC_RSO_TEAM_R_ET_STEP1.V_RSO_DESC_R)
	not like 'NSC%'  then  NVL(STG_PBC_RSO_TEAM_R_ET_STEP1.V_PBC_TEAM_NAME_R,'UNKNOWN')   else null end as V_PBC_TEAM_NAME_R
	from (
	--Gireesh changes ends 09-Aug-2022
	SELECT
	DISTINCT
	CAST ( NULL AS CHAR) AS V_PRIVACY_INDICATOR_R
	,CAST ( NULL AS CHAR) AS V_UW_TRK_NEEDED_RENEW_STATUS_R
	,CAST ( NULL AS NUMBER) AS N_UW_TRK_NEEDED_PERCENT_R
	,CAST ( NULL AS NUMBER) AS N_UW_TRK_REQUESTED_PERCENT_R
	,CAST ( NULL AS CHAR) AS V_UW_TRK_NEEDED_UW_NAME_R
	,CAST ( NULL AS CHAR) AS V_UW_TRK_NEEDED_COMMENTS_R
	,CAST ( NULL AS DATE) AS D_UW_TRK_NEXT_RENEWAL_DATE_R
	,CAST ( NULL AS CHAR) AS V_CASE_SIZE_SORT_R
	,CAST ( NULL AS DATE) AS D_MOST_RECENT_CENSUS_DATE_R
	,CAST ( NULL AS NUMBER) AS N_POLICY_LIVES_R
	,CAST ( NULL AS CHAR) AS V_NEW_BUSINESS_INDICATOR_R
	,CAST ( NULL AS CHAR) AS V_SIC_DESC_R
	,CAST ( NULL AS CHAR) AS V_SIC_CATEGORY_R
	,CAST ( NULL AS CHAR) AS V_IEB_IND_R
	,CAST ( NULL AS CHAR) AS V_SIC_MAJOR_CODE_R
	,CAST ( NULL AS CHAR) AS V_SIC_MAJOR_RANGE_R
	,CAST ( NULL AS CHAR) AS V_SIC_CATEGORY_GROUP_CODE_R
	,CAST ( NULL AS CHAR) AS V_SIC_CATEGORY_GROUP_DESC_R
	,CAST ( NULL AS CHAR) AS V_SIC_CATEGORY_GROUP_RANGE_R
	,CAST ( NULL AS CHAR) AS F_PHYSICAL_DELETE_R
	,B1.V_CHANGE_REASON_R
	,CAST ( NULL AS DATE) AS D_UNADJ_POLICY_EFF_DATE_R
	,CAST ( NULL AS TIMESTAMP(6)) AS T_POLICY_EXPIRY_DATE_R
	,B1.N_POLICY_SK_R
	,CAST ( 0 AS NUMBER) AS N_VERSION_NUMBER_R
	,CAST ( NULL AS NUMBER) AS N_QUOTE_SK_R
	,B1.N_BATCH_ID_R
	,CAST ( NULL AS NUMBER) AS N_LOAD_RUN_ID_R
	,B1.N_SEQUENCE_NUMBER_R
	,B1.T_CREATION_DATE_R
	,B1.T_LAST_MODIFIED_DATE_R
	,B1.V_CREATED_BY_R
	,B1.V_LAST_MODIFIED_BY_R
	,B1.FIC_MIS_DATE_R
	,CAST ( NULL AS CHAR) AS V_CROSS_SELL_INDICATOR_R
	,CAST ( NULL AS CHAR) AS V_6MNTH_CROSS_SELL_INDICATOR_R
	,CAST ( NULL AS CHAR) AS V_REWRITE_INDICATOR_R
	,CAST ( NULL AS CHAR) AS V_ANY_LOB_CROSS_SELL_R
	,CAST ( NULL AS CHAR) AS V_LTD_CROSS_SELL_R
	,CAST ( NULL AS CHAR) AS V_STD_CROSS_SELL_R
	,CAST ( NULL AS CHAR) AS V_LIFE_CROSS_SELL_R
	,CAST ( NULL AS CHAR) AS V_BASIC_LIFE_CROSS_SELL_R
	,CAST ( NULL AS CHAR) AS V_SUPP_LIFE_CROSS_SELL_R
	,CAST ( NULL AS CHAR) AS V_DEP_LIFE_CROSS_SELL_R
	,CAST ( NULL AS CHAR) AS V_ADD_CROSS_SELL_R
	,CAST ( NULL AS CHAR) AS V_SR_CROSS_SELL_R
	,CAST ( NULL AS CHAR) AS V_VAR_CROSS_SELL_R
	,CAST ( NULL AS CHAR) AS V_VAI_CROSS_SELL_R
	,CAST ( NULL AS CHAR) AS V_VCI_CROSS_SELL_R
	,CAST ( NULL AS NUMBER) AS N_TOTAL_PRODUCT_LINES_R
	,CAST ( NULL AS CHAR) AS V_5500_POLICY_INFORCE_IND_R
	,CAST ( NULL AS CHAR) AS V_ASO_FEE_CODE_R
	,CAST ( NULL AS CHAR) AS V_ASO_FEE_DESC_R
	,CAST ( NULL AS NUMBER) AS N_ASO_SETUP_FEE_AMT_R
	,CAST ( NULL AS NUMBER) AS N_ASO_FEE_AMT_R
	,CAST ( NULL AS CHAR) AS V_SIC_CODE_R
	,CAST ( NULL AS CHAR) AS V_POLICY_TYPE_DESC_R
	,CAST ( NULL AS CHAR) AS V_RATEBOOK_ID_R
	,CAST ( NULL AS CHAR) AS V_RATEBOOK_DESC_R
	,CAST ( NULL AS DATE) AS D_RATEBOOK_EFFECTIVE_DATE_R
	,CAST ( NULL AS CHAR) AS V_VOLUNTARY_IND_R
	,CAST ( NULL AS CHAR) AS V_PROD_PRODUCT_LINE_CODE_R
	,CAST ( NULL AS CHAR) AS V_PROD_PRODUCT_LINE_DESC_R
	,CAST ( NULL AS CHAR) AS V_SMARTCHOICE_IND_R
	,CAST ( NULL AS DATE) AS D_UW_WORK_MONTH_R
	,CAST ( NULL AS CHAR) AS V_UW_NEEDED_RENEWAL_STATUS_R
	,CAST ( NULL AS NUMBER) AS N_UW_NEEDED_PERCENT_R
	,CAST ( NULL AS NUMBER) AS N_UW_REQUESTED_PERCENT_R
	,CAST ( NULL AS CHAR) AS V_UW_NEEDED_UNDERWRITER_NAME_R
	,CAST ( NULL AS CHAR) AS V_UW_NEEDED_COMMENTS_R
	,CAST ( NULL AS DATE) AS D_UW_NEXT_RENEWAL_DATE_R
	,CAST ( NULL AS DATE) AS D_CENSUS_RECEIVED_DATE_R
	,CAST ( NULL AS DATE) AS D_NOCENSUS_DEADLINE_DATE_R
	,CAST ( NULL AS NUMBER) AS N_CENSUS_RECEIVED_FLAG_R
	,CAST ( NULL AS CHAR) AS V_ANNIVERSARY_DATE_AND_MONTH_R
	,CAST ( NULL AS CHAR) AS V_TYPE_OF_BILLING_R
	,CAST ( NULL AS NUMBER) AS N_RATE_GUARANTEE_R
	,CAST ( NULL AS NUMBER) AS N_DEPOSIT_AMOUNT_R
	,CAST ( NULL AS NUMBER) AS N_EMPLOYEES_ACTIVELY_AT_WORK_R
	,CAST ( NULL AS NUMBER) AS N_GRANDFATHER_EMP_NOT_ACTIVE_R
	,CAST ( NULL AS CHAR) AS V_FUNDING_ARRANGEMENT_R
	,CAST ( NULL AS NUMBER) AS N_MEDICAL_CONVERSION_R
	,CAST ( NULL AS NUMBER) AS N_RENEWAL_NOTIFICATION_DAYS_R
	,CAST ( NULL AS NUMBER) AS N_CLAIMS_TAX_INDICATOR_R
	,CAST ( NULL AS CHAR) AS V_CLAIMS_DISTRIBUTION_CHECKS_R
	,CAST ( NULL AS DATE) AS D_INSTALLATION_DATE_R
	,CAST ( NULL AS NUMBER) AS N_COST_SHIFTING_R
	,CAST ( NULL AS DATE) AS D_CALCULATED_EXPIRY_DATE_R
	,CAST ( NULL AS NUMBER) AS N_INITIAL_CHECK_AMT_R
	,CAST ( NULL AS NUMBER) AS N_PAYABLE_RATE_R
	,CAST ( NULL AS NUMBER) AS N_MANUAL_RATE_R
	,CAST ( NULL AS NUMBER) AS N_TOTAL_CLASSES_R
	,CAST ( NULL AS DATE) AS D_RENEWAL_CENSUS_REQDATE1_R
	,CAST ( NULL AS DATE) AS D_RENEWAL_CENSUS_REQDATE2_R
	,CAST ( NULL AS DATE) AS D_RENEWAL_CENSUS_REQDATE3_R
	,CAST ( NULL AS CHAR) AS V_INFORMATION_5500_R
	,CAST ( NULL AS NUMBER) AS N_RENEWAL_LIVES_R
	,CAST ( NULL AS NUMBER) AS N_NUMBER_OF_BILL_GROUP_R
	,CAST ( NULL AS NUMBER) AS N_CUSTOMER_CONTRACTUAL_CHG_R
	,CAST ( NULL AS NUMBER) AS N_OVERRIDE_EXPIRY_DATE_R
	,CAST ( NULL AS CHAR) AS V_VERSION_REASON_CODE_R
	,CAST ( NULL AS NUMBER) AS N_COST_SHIFT_PREMIUM_R
	,CAST ( NULL AS NUMBER) AS N_MRP_OVERRIDEN_R
	,CAST ( NULL AS NUMBER) AS N_EXP_COMMISSIONS_R
	,CAST ( NULL AS NUMBER) AS N_EXP_PREMIUM_TAX_R
	,CAST ( NULL AS NUMBER) AS N_EXP_PER_CONTRACT_R
	,CAST ( NULL AS NUMBER) AS N_EXP_PERCENT_OF_PREM_R
	,CAST ( NULL AS NUMBER) AS N_EXP_TOTAL_R
	,CAST ( NULL AS NUMBER) AS N_TOTAL_FINAL_PREMIUM_R
	,CAST ( NULL AS CHAR) AS V_LOB_BLOCK_R
	,CAST ( NULL AS NUMBER) AS N_RI_TRUST_FLAG_R
	,CAST ( NULL AS NUMBER) AS N_CALC_CENSUS_PCC_R
	,CAST ( NULL AS NUMBER) AS N_STEP_RATE_R
	,CAST ( NULL AS CHAR) AS V_GE_DESC_R
	,CAST ( NULL AS CHAR) AS V_GE_EMPLOYEE_R
	,CAST ( NULL AS NUMBER) AS N_GE_ARE_EMP_EXCLUDED_R
	,CAST ( NULL AS CHAR) AS V_GRANDFATHERING_EMP_DATA_R
	,CAST ( NULL AS NUMBER) AS N_CREATED_FROM_CUSTOMER_R
	,CAST ( NULL AS NUMBER) AS N_NUM_LIVES_R
	,CAST ( NULL AS CHAR) AS V_EMP_EXCLUDED_R
	,CAST ( NULL AS NUMBER) AS N_FULL_TIME_HOURS_R
	,CAST ( NULL AS NUMBER) AS N_PART_TIME_ELIGIBILITY_R
	,CAST ( NULL AS NUMBER) AS N_PART_TIME_HOURS_R
	,CAST ( NULL AS NUMBER) AS N_QUOTED_AMOUNT_R
	,CAST ( NULL AS NUMBER) AS N_PARTICIPATING_NUM_LIVES_R
	,CAST ( NULL AS NUMBER) AS N_RENEW_GROUP_R
	,CAST ( NULL AS DATE) AS D_PROPOSAL_DATE_R
	,CAST ( NULL AS NUMBER) AS N_ACCUM_UW_FACTOR_R
	,CAST ( NULL AS NUMBER) AS N_ACCUM_OCC_FACTOR_R
	,CAST ( NULL AS CHAR) AS V_MATRIX_ADMINISTERED_R
	,CAST ( NULL AS NUMBER) AS N_INIT_PROP_RENEWAL_RATE_R
	,CAST ( NULL AS NUMBER) AS N_PLAN_CHANGE_PERCENT_R
	,CAST ( NULL AS NUMBER) AS N_INIT_PROP_RENEWAL_RATE2_R
	,CAST ( NULL AS NUMBER) AS N_PLAN_CHANGE_PERCENT2_R
	,CAST ( NULL AS CHAR) AS V_CONTRACT_ISSUE_STATE_R
	,CAST ( NULL AS CHAR) AS V_GI_BILLING_R
	,CAST ( NULL AS CHAR) AS V_GI_BILLING_RULE_R
	,CAST ( NULL AS CHAR) AS V_EMPLOYEE_APPLICATION_REQUI_R
	,CAST ( NULL AS NUMBER) AS N_CLAIMS_PER_1000_R
	,CAST ( NULL AS CHAR) AS V_ADMINISTERED_BY_R
	,CAST ( NULL AS CHAR) AS V_ORIG_SYSTEM_R
	,CAST ( NULL AS CHAR) AS V_BRAND_NAME_R
	,CAST ( NULL AS CHAR) AS V_MEMEXCHANGE_R
	,CAST ( NULL AS CHAR) AS V_MEMBLOCK_R
	,CAST ( NULL AS NUMBER) AS N_W2_EXCLUDE_FICA_MATCH_R
	,CAST ( NULL AS CHAR) AS V_PLANDESIGN_VERSION_R
	,CAST ( NULL AS TIMESTAMP(6)) AS T_EFFECTIVE_START_DATE_R
	,B1.D_RECORD_END_DATE_R AS D_EFFECTIVE_END_DATE_R
	,B1.V_POLICY_NUMBER_R
	,B1.T_POLICY_EFFECTIVE_DATE_R
	,B1.V_SOURCE_SYSTEM_NAME_R
	,'POLICY' AS V_SUBJECT_AREA_TYPE_R
	,B1.T_EVENT_TIMESTAMP_R
	,CAST ( NULL AS CHAR) AS V_NAMED_INSURED_R
	,CAST ( NULL AS CHAR) AS V_JURISDICTION_R
	,CAST ( NULL AS DATE) AS D_RATED_DATE_R
	,CAST ( NULL AS CHAR) AS V_CLASS_OF_BUSINESS_R
	,B1.N_SOURCE_SYSTEM_KEY_R
	,CAST ( NULL AS DATE) AS D_RENEWAL_DATE_R
	,CAST ( NULL AS CHAR) AS V_LINE_OF_BUSINESS_R
	,CAST ( NULL AS NUMBER) AS N_AUTO_RENEWAL_R
	,CAST ( NULL AS NUMBER) AS N_CENSUS_REQUESTED_R
	from ATOMIC.DIM_GRP_POLICY_DIR_R B1
	--Gireesh changes starts 09-Aug-2022
	where B1.V_SOURCE_SYSTEM_NAME_R='VUE'
	and B1.V_ACTIVE_STATUS_R='Y'
	--and B1.N_BATCH_ID_R=IN_BATCH_ID_R  --27-Aug-2022 changes after discussion with Gisha to avoid missing policies
	and not exists(select 1
					from ATOMIC.FCT_GRP_POLICY_R C
					where C.N_POLICY_SK_R=B1.N_POLICY_SK_R and C.V_SOURCE_SYSTEM_NAME_R='VUE') )B
	--Gireesh changes ends 09-Aug-2022
	LEFT JOIN ATOMIC.FCT_GRP_BILLING_POLICY_DTL_R C
		ON B.N_SOURCE_SYSTEM_KEY_R = C.N_POLICY_ID_R
		and B.V_POLICY_NUMBER_R = C.V_POLICY_NUMBER_R
	  --AND B.N_BATCH_ID_R=IN_BATCH_ID_R --Commented by Gireesh 09-Aug-2022
	LEFT JOIN ATOMIC.DIM_GRP_PARTY_DIR_R D
		ON C.N_CUSTOMER_ID_R = D.N_SOURCE_SYSTEM_KEY_R
		AND D.V_SOURCE_SYSTEM_NAME_R = 'VUE'
		AND D.V_PARTY_TYPE_R = 'CUSTOMER'
		AND D.V_ACTIVE_STATUS_R = 'Y'
	LEFT JOIN
	(select n_party_sk_r,n_customer_number_r,V_ACTIVE_STATUS_R,V_PARTY_TYPE_R,V_SOURCE_SYSTEM_NAME_R,
	CASE V_RSO_ABBREV_R WHEN 'MAIN' THEN 'HO' WHEN 'MIC' THEN 'DET' WHEN 'NOC' THEN 'SAN' WHEN 'NY' THEN 'NEW' WHEN 'SOC' THEN 'COS' WHEN 'TWC' THEN 'TWI' ELSE V_RSO_ABBREV_R END as V_RSO_ABBREV_R
	from ATOMIC.DIM_GRP_PARTY_DIR_R where V_ACTIVE_STATUS_R='Y' group by n_party_sk_r,n_customer_number_r,V_ACTIVE_STATUS_R,V_PARTY_TYPE_R,V_SOURCE_SYSTEM_NAME_R,V_RSO_ABBREV_R) E
		ON TRIM(D.N_CUSTOMER_NUMBER_R) = TRIM(E.N_CUSTOMER_NUMBER_R)
		AND E.V_SOURCE_SYSTEM_NAME_R ='PACS'
		AND E.V_PARTY_TYPE_R = 'CUSTOMER'
		AND E.V_ACTIVE_STATUS_R = 'Y'
	LEFT JOIN (select * from ATOMIC.STG_PBC_RSO_TEAM_R where V_NEW_BUSINESS_IND_R = 'INFORCE'  AND UPPER(V_RSO_DESC_R)  NOT LIKE 'NSC%' )STG_PBC_RSO_TEAM_R_ET_STEP1 ON E.V_RSO_ABBREV_R =STG_PBC_RSO_TEAM_R_ET_STEP1.V_RSO_ABBREV_R

	LEFT JOIN (select * from ATOMIC.DIM_GRP_UDFIELD_R where N_ENTITY_TYPE_ID_R='200')DIM_GRP_UDFIELD_R ON DIM_GRP_UDFIELD_R.N_ENTITY_ID_R=B.N_SOURCE_SYSTEM_KEY_R

	LEFT JOIN (SELECT * FROM ATOMIC.DIM_GRP_MTOPTION_R  WHERE v_ITEM_r NOT LIKE '%NSC%' )DIM_GRP_MTOPTION_R_NOTNSC ON DIM_GRP_UDFIELD_R.V_FIELD6_R = DIM_GRP_MTOPTION_R_NOTNSC.N_OPTIONID_R

	LEFT JOIN (SELECT * FROM ATOMIC.DIM_GRP_MTOPTION_R A JOIN ATOMIC.STG_PBC_RSO_TEAM_R B ON  upper(B.V_RSO_DESC_R)=A.v_ITEM_r  WHERE v_ITEM_r  LIKE '%NSC%'
	)DIM_GRP_MTOPTION_R_NSC ON DIM_GRP_UDFIELD_R.V_FIELD6_R = DIM_GRP_MTOPTION_R_NSC.N_OPTIONID_R

	LEFT JOIN (select * from ATOMIC.STG_PBC_RSO_TEAM_R A JOIN ATOMIC.FCT_GRP_SALESREP_RELATIONSHP_R B ON A.V_RSO_ABBREV_R = B.V_RSO_ASSOC_R where A.V_NEW_BUSINESS_IND_R = 'NEW' )STG_PBC_RSO_TEAM_R_ET_STEP4 ON
	E.N_CUSTOMER_NUMBER_R=STG_PBC_RSO_TEAM_R_ET_STEP4.V_CUSTOMER_NUMBER_R  and E.V_RSO_ABBREV_R=STG_PBC_RSO_TEAM_R_ET_STEP4.V_RSO_ABBREV_R


	LEFT JOIN (SELECT N_POLICY_SK_R FROM ATOMIC.FCT_BILLING_POLICY_PREMIUM_R GROUP BY N_POLICY_SK_R)F ON B.N_POLICY_SK_R=F.N_POLICY_SK_R

	--WHERE B.V_SOURCE_SYSTEM_NAME_R='VUE' --Commented by Gireesh 09-Aug-2022
	--AND B.V_ACTIVE_STATUS_R='Y'          --Commented by Gireesh 09-Aug-2022
	)
	);

	COMMIT;
	OUT_LOAD_STATUS:='SUCCESS';
	EXCEPTION
	WHEN OTHERS THEN
	LC_SQLCODE:=SQLCODE;
	LC_SQLERRM:=SUBSTR(SQLERRM,1,4000);
	OUT_LOAD_STATUS:=LC_SQLCODE||'-'||LC_SQLERRM;
	DBMS_OUTPUT.PUT_LINE('PRC_LOAD_VUE_FCT_GRP_POLICY_R  EXCEPTION WITH ERROR CODE AS '
				 || SQLCODE
				 || ' '
				 || SQLERRM
				 || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
				 ||'PRC_LOAD_VUE_FCT_GRP_POLICY_R'
				 ||';');

    RAISE_APPLICATION_ERROR(-20001,'Error in PKG_LOAD_GRP_TABLES.PRC_LOAD_VUE_FCT_GRP_POLICY_R:->
    Error Code:'||SQLCODE||',Error message:'||SUBSTR(SQLERRM,1,4000));

	end PRC_LOAD_VUE_FCT_GRP_POLICY_R;




	PROCEDURE PRC_LOAD_FCT_GRP_POLICY_R_PBC_TEAM_LOOKUP(
		IN_BATCH_ID_R        IN NUMBER,
		OUT_LOAD_STATUS      OUT VARCHAR2
		)
	IS
	LD_SYSDATE DATE :=SYSDATE;
	LC_SQLCODE VARCHAR2(4000);
	LC_SQLERRM VARCHAR2(4000);
	LN_SEQUENCE_NUMBER_R NUMBER;
	LN_IN_BATCH_ID_R NUMBER:=IN_BATCH_ID_R;
	LN_LOAD_RUN_ID_R NUMBER;
	BEGIN

		IF LN_IN_BATCH_ID_R IS NULL THEN
		  OUT_LOAD_STATUS:='a) BatchID(IN_BATCH_ID) is null hence terminating the program';
		 RAISE_APPLICATION_ERROR(-20001,'a) BatchID(IN_BATCH_ID) is null hence terminating the program');
		END IF;

	SELECT   COUNT(1)
		  INTO ln_load_run_id_r
	FROM ATOMIC.PRCS_JOB_LOG_R
	WHERE N_BATCH_ID_R =IN_BATCH_ID_R
	AND V_JOB_NAME_R='PKG_GRP_LOAD_FCT_GRP_POLICY_R_PBC_TEAM_LOOKUP';
	BEGIN
	execute immediate 'TRUNCATE TABLE ATOMIC.FCT_GRP_POLICY_R_PBC_TEAM_LOOKUP PURGE SNAPSHOT LOG';
	END;
	-- Need to be changed after discussing with Gisha(Audit COlumns & Driving table to pass batchid)
	INSERT /*+APPEND_VALUES*/ INTO ATOMIC.FCT_GRP_POLICY_R_PBC_TEAM_LOOKUP
	(
	N_SEQUENCE_NUMBER_R,
	T_CREATION_DATE_R,
	V_CREATED_BY_R,
	T_LAST_MODIFIED_DATE_R,
	V_LAST_MODIFIED_BY_R,
	N_POLICY_SK_R,
	V_POLICY_NUMBER_R,
	N_VERSION_NUMBER_R,
	V_PBC_SUB_TEAM_R,
	V_PBC_TEAM_NAME_R,
	V_NEW_BUSINESS_INDICATOR_R,
	N_BATCH_ID_R
	)


	SELECT
	(NVL(LN_SEQUENCE_NUMBER_R,0)+ROWNUM) N_SEQUENCE_NUMBER_R            --NOT NULL
	,LD_SYSDATE T_CREATION_DATE_R              							--NOT NULL
	,'ODI' V_CREATED_BY_R                 								--NOT NULL
	,LD_SYSDATE T_LAST_MODIFIED_DATE_R         							--NOT NULL
	,'ODI' V_LAST_MODIFIED_BY_R           								--NOT NULL
	,FCT_POLICY.N_POLICY_SK_R
	,FCT_POLICY.V_POLICY_NUMBER_R
	,FCT_POLICY.N_VERSION_NUMBER_R
	,CASE WHEN FCT_POLICY.v_line_of_business_r like '%SMALL' AND STEP5.N_POLICY_SK_R IS NOT NULL THEN  'TEAM H' WHEN FCT_POLICY.D_INSTALLATION_DATE_R IS NULL AND
	F.N_POLICY_SK_R IS NULL AND FCT_POLICY.V_ORIG_LOB_R <> 'VG' THEN NVL(FCT_POLICY.V_PBC_SUB_TEAM_R,FCT_POLICY.V_PBC_SUB_TEAM_R_INNER)   ELSE FCT_POLICY.V_PBC_SUB_TEAM_R_INNER END as V_PBC_SUB_TEAM_R
	,CASE WHEN FCT_POLICY.v_line_of_business_r like '%SMALL' AND STEP5.N_POLICY_SK_R IS NOT NULL THEN  'Team H' WHEN FCT_POLICY.D_INSTALLATION_DATE_R IS NULL
	and F.N_POLICY_SK_R is null and FCT_POLICY.V_ORIG_LOB_R <> 'VG' then NVL(FCT_POLICY.V_PBC_TEAM_NAME_R,FCT_POLICY.V_PBC_TEAM_NAME_R_INNER)  when V_PBC_SUB_TEAM_R_INNER='FER' then 'Team R'
	--when V_PBC_SUB_TEAM_R_INNER in ('TEAM G', 'TEAM 8', 'TEAM 9') then 'Team S' else V_PBC_TEAM_NAME_R_INNER end as V_PBC_TEAM_NAME_R
	WHEN V_PBC_SUB_TEAM_R_INNER IN ('TEAM 8', 'TEAM 9') THEN 'Team S' ELSE V_PBC_TEAM_NAME_R_INNER END as V_PBC_TEAM_NAME_R---new changes by Erica on 27-Jan-2023
	,CASE WHEN FCT_POLICY.D_INSTALLATION_DATE_R IS NULL  AND F.N_POLICY_SK_R IS NULL  AND FCT_POLICY.V_ORIG_LOB_R <> 'VG' THEN 'Y' ELSE 'N' END as V_NEW_BUSINESS_INDICATOR_R
	,IN_BATCH_ID_R
	FROM
	(SELECT
	DISTINCT

	 --TBL_NAME1.D_INSTALLATION_DATE_R---new changes by Erica on 10-Oct-2022
	NVL(FCT_GRP_BILLING_POLICY_DTL_R.D_INSTALLATION_DATE_R,TBL_NAME1.D_INSTALLATION_DATE_R) D_INSTALLATION_DATE_R---new changes by Erica on 10-Oct-2022
	,TBL_NAME1.N_VERSION_NUMBER_R
	,TBL_NAME2.V_ORIG_LOB_R
	,TBL_NAME2.N_POLICY_SK_R
	,TBL_NAME2.V_POLICY_NUMBER_R
	,TBL_NAME1.v_line_of_business_r
	,STG_PBC_RSO_TEAM_R_ET_STEP4.V_PBC_TEAM_NAME_R
	,STG_PBC_RSO_TEAM_R_ET_STEP4.V_PBC_SUB_TEAM_R
	,case  when DIM_GRP_MTOPTION_R_NSC.V_ITEM_R like '%NSC%' then DIM_GRP_MTOPTION_R_NSC.V_PBC_SUB_TEAM_R when DIM_GRP_MTOPTION_R_NOTNSC.V_ITEM_R not like '%NSC%' then DIM_GRP_MTOPTION_R_NOTNSC.V_ITEM_R when STG_PBC_RSO_TEAM_R_ET_STEP1.V_NEW_BUSINESS_IND_R = 'INFORCE' and  UPPER(STG_PBC_RSO_TEAM_R_ET_STEP1.V_RSO_DESC_R)  not like 'NSC%'  then NVL(STG_PBC_RSO_TEAM_R_ET_STEP1.V_PBC_SUB_TEAM_R,'UNKNOWN')  else null end as V_PBC_SUB_TEAM_R_INNER
	--,CASE WHEN DIM_GRP_MTOPTION_R_NSC.v_ITEM_r LIKE '%NSC%' THEN DIM_GRP_MTOPTION_R_NSC.V_PBC_TEAM_NAME_R WHEN DIM_GRP_MTOPTION_R_NOTNSC.v_ITEM_r NOT LIKE '%NSC%' THEN CASE DIM_GRP_MTOPTION_R_NOTNSC.v_ITEM_r WHEN 'TEAM 7' THEN 'Team L' WHEN 'TEAM A'  THEN 'Team L'  WHEN 'TEAM B'  THEN 'Team L'  WHEN 'TEAM C'  THEN 'Team L'  WHEN 'TEAM D'  THEN 'Team L'  WHEN 'TEAM E'  THEN 'Team L'  WHEN 'TEAM F'  THEN 'Team L'  WHEN 'TEAM H'  THEN 'Team L'  WHEN 'TEAM I'  THEN 'Team L'  WHEN 'TEAM J'  THEN 'Team L'  WHEN 'TEAM K'  THEN 'Team L'  WHEN 'TEAM L'  THEN 'Team L'  WHEN 'TEAM N'  THEN 'Team L'  WHEN 'TEAM P'  THEN 'Team L'  WHEN 'TEAM G'  THEN 'Team S'  WHEN 'TEAM 8'  THEN 'Team S'  WHEN 'TEAM 9'  THEN 'Team S'  WHEN 'FER'  THEN 'Team R'  ELSE 'Team S' END WHEN STG_PBC_RSO_TEAM_R_ET_STEP1.V_NEW_BUSINESS_IND_R = 'INFORCE' AND  UPPER(STG_PBC_RSO_TEAM_R_ET_STEP1.V_RSO_DESC_R)  NOT LIKE 'NSC%'  THEN  NVL(STG_PBC_RSO_TEAM_R_ET_STEP1.V_PBC_TEAM_NAME_R,'UNKNOWN')   ELSE NULL END AS V_PBC_TEAM_NAME_R_INNER
	--,case when DIM_GRP_MTOPTION_R_NSC.V_ITEM_R like '%NSC%' then DIM_GRP_MTOPTION_R_NSC.V_PBC_TEAM_NAME_R when DIM_GRP_MTOPTION_R_NOTNSC.V_ITEM_R not like '%NSC%' then case DIM_GRP_MTOPTION_R_NOTNSC.V_ITEM_R when  'TEAM A'  then 'Team L'   when 'TEAM D'  then 'Team L'   when 'TEAM G'  then 'Team L' when 'TEAM H'  then 'Team L' when 'TEAM S'  then 'Team L'  when 'TEAM T'  then 'Team L'  when 'TEAM X'  then 'Team L' when 'TEAM 8'  then 'Team S'  when 'TEAM 9'  then 'Team S'  when 'FER'  then 'Team R'  else 'Team S' end when STG_PBC_RSO_TEAM_R_ET_STEP1.V_NEW_BUSINESS_IND_R = 'INFORCE' and  UPPER(STG_PBC_RSO_TEAM_R_ET_STEP1.V_RSO_DESC_R)  not like 'NSC%'  then  NVL(STG_PBC_RSO_TEAM_R_ET_STEP1.V_PBC_TEAM_NAME_R,'UNKNOWN')   else null end as V_PBC_TEAM_NAME_R_INNER---new changes by Erica on 27-Jan-2023
	--22-Aug-2023 changes starts
	--,CASE WHEN DIM_GRP_MTOPTION_R_NSC.v_ITEM_r LIKE '%NSC%' THEN DIM_GRP_MTOPTION_R_NSC.V_PBC_TEAM_NAME_R WHEN DIM_GRP_MTOPTION_R_NOTNSC.v_ITEM_r NOT LIKE '%NSC%' THEN CASE DIM_GRP_MTOPTION_R_NOTNSC.v_ITEM_r WHEN  'TEAM A'  THEN 'Team L'   WHEN 'TEAM W'  THEN 'Team L'   WHEN 'TEAM D'  THEN 'Team L'   WHEN 'TEAM G'  THEN 'Team L' WHEN 'TEAM H'  THEN 'Team L' WHEN 'TEAM S'  THEN 'Team L'  WHEN 'TEAM T'  THEN 'Team L'  WHEN 'TEAM X'  THEN 'Team L' WHEN 'TEAM 8'  THEN 'Team S'  WHEN 'TEAM 9'  THEN 'Team S'  WHEN 'FER'  THEN 'Team R'  ELSE 'Team S' END WHEN STG_PBC_RSO_TEAM_R_ET_STEP1.V_NEW_BUSINESS_IND_R = 'INFORCE' AND  UPPER(STG_PBC_RSO_TEAM_R_ET_STEP1.V_RSO_DESC_R)  NOT LIKE 'NSC%'  THEN  NVL(STG_PBC_RSO_TEAM_R_ET_STEP1.V_PBC_TEAM_NAME_R,'UNKNOWN')   ELSE NULL END AS V_PBC_TEAM_NAME_R_INNER---new changes by Erica on 17-Mar-2023
	,CASE
		WHEN DIM_GRP_MTOPTION_R_NSC.v_ITEM_r LIKE '%NSC%'
			THEN DIM_GRP_MTOPTION_R_NSC.V_PBC_TEAM_NAME_R
		WHEN DIM_GRP_MTOPTION_R_NOTNSC.v_ITEM_r NOT LIKE '%NSC%'
			THEN CASE DIM_GRP_MTOPTION_R_NOTNSC.v_ITEM_r
					WHEN 'TEAM A'
						THEN 'Team L'
					--WHEN 'TEAM W'
					--	THEN 'Team L'
					WHEN 'TEAM D'
						THEN 'Team L'
					WHEN 'TEAM G'
						THEN 'Team L'
					WHEN 'TEAM H'
						THEN 'Team L'
					WHEN 'TEAM S'
						THEN 'Team S'
					--WHEN 'TEAM T'
					--	THEN 'Team L'
					WHEN 'TEAM X'
						THEN 'Team S'
					WHEN 'TEAM 8'
						THEN 'Team S'
					WHEN 'TEAM 9'
						THEN 'Team S'
					WHEN 'FER'
						THEN 'Team R'
					WHEN 'TEAM O'
						THEN 'Team L'
					ELSE 'Team S'
					END
		WHEN STG_PBC_RSO_TEAM_R_ET_STEP1.V_NEW_BUSINESS_IND_R = 'INFORCE'
			AND UPPER(STG_PBC_RSO_TEAM_R_ET_STEP1.V_RSO_DESC_R) NOT LIKE 'NSC%'
			THEN NVL(STG_PBC_RSO_TEAM_R_ET_STEP1.V_PBC_TEAM_NAME_R, 'UNKNOWN')
		ELSE NULL
		END AS V_PBC_TEAM_NAME_R_INNER
---new changes by Erica on 17-Mar-2023
	--22-Aug-2023 changes ends
	from

	(SELECT  DISTINCT
	N_POLICY_SK_R,
	D_INSTALLATION_DATE_R,
	N_VERSION_NUMBER_R,
	V_POLICY_NUMBER_R,
	V_LINE_OF_BUSINESS_R,
	N_SOURCE_SYSTEM_KEY_R,
	N_CUST_PARTY_SK_R
	FROM ATOMIC.FCT_GRP_POLICY_R
	--WHERE 1=1--N_BATCH_ID_R =IN_BATCH_ID_R --10-Oct-2022
	) TBL_NAME1

	LEFT JOIN (SELECT N_POLICY_SK_R,CASE WHEN V_ORIG_LOB_R = 'VG' THEN 'VG' ELSE 'ZZZ' END V_ORIG_LOB_R ,V_POLICY_SUFFIX_R,V_ORIG_POLICY_NUMBER_R,V_POLICY_NUMBER_R ,N_SOURCE_SYSTEM_KEY_R FROM ATOMIC.DIM_GRP_POLICY_DIR_R  WHERE V_ACTIVE_STATUS_R IN('Y','N')
	--AND V_SOURCE_SYSTEM_NAME_R='PACS'  --18-Aug-2022 changes requested by Gisha
	GROUP BY N_POLICY_SK_R,N_SOURCE_SYSTEM_KEY_R,V_ORIG_POLICY_NUMBER_R,CASE WHEN V_ORIG_LOB_R = 'VG' THEN 'VG' ELSE 'ZZZ' END ,V_POLICY_NUMBER_R,V_POLICY_SUFFIX_R)TBL_NAME2
	ON
	TBL_NAME2.N_POLICY_SK_R=TBL_NAME1.N_POLICY_SK_R
	AND NVL(TBL_NAME2.N_SOURCE_SYSTEM_KEY_R,-99999)=NVL(TBL_NAME1.N_SOURCE_SYSTEM_KEY_R,-99999)----07-Oct-2022 changes for Shinka polices
	AND TBL_NAME2.V_POLICY_NUMBER_R=TBL_NAME1.V_POLICY_NUMBER_R

	LEFT JOIN (SELECT N_SOURCE_SYSTEM_KEY_R,V_PARTY_TYPE_R,V_SOURCE_SYSTEM_NAME_R,N_PARTY_SK_R,
	CASE V_RSO_ABBREV_R WHEN 'MAIN' THEN 'HO' WHEN 'MIC' THEN 'DET' WHEN 'NOC' THEN 'SAN' WHEN 'NY' THEN 'NEW' WHEN 'SOC' THEN 'COS' WHEN 'TWC' THEN 'TWI' ELSE V_RSO_ABBREV_R END AS V_RSO_ABBREV_R,N_CUSTOMER_NUMBER_R
	FROM ATOMIC.DIM_GRP_PARTY_DIR_R WHERE V_ACTIVE_STATUS_R='Y' GROUP BY N_SOURCE_SYSTEM_KEY_R,V_PARTY_TYPE_R,V_SOURCE_SYSTEM_NAME_R,N_PARTY_SK_R,V_RSO_ABBREV_R,N_CUSTOMER_NUMBER_R)TBL_NAME3

	ON TBL_NAME1.N_CUST_PARTY_SK_R=TBL_NAME3.N_PARTY_SK_R
	AND TBL_NAME3.V_SOURCE_SYSTEM_NAME_R='PACS'

	LEFT JOIN (SELECT V_ORIG_POLICY_NUMBER_R,N_SOURCE_SYSTEM_KEY_R ,V_POLICY_NUMBER_R,N_POLICY_SK_R FROM ATOMIC.DIM_GRP_POLICY_DIR_R  WHERE V_SOURCE_SYSTEM_NAME_R='VUE'  and N_SOURCE_SYSTEM_KEY_R <> '181049'
	GROUP BY N_SOURCE_SYSTEM_KEY_R,V_ORIG_POLICY_NUMBER_R,V_POLICY_NUMBER_R,N_POLICY_SK_R)TBL_NAME4
	ON TBL_NAME4.N_POLICY_SK_R=TBL_NAME2.N_POLICY_SK_R


	LEFT JOIN (select * from ATOMIC.STG_PBC_RSO_TEAM_R where V_NEW_BUSINESS_IND_R = 'INFORCE'  AND UPPER(V_RSO_DESC_R)  NOT LIKE 'NSC%' )STG_PBC_RSO_TEAM_R_ET_STEP1
	ON TBL_NAME3.V_RSO_ABBREV_R =STG_PBC_RSO_TEAM_R_ET_STEP1.V_RSO_ABBREV_R

	LEFT JOIN (select * from ATOMIC.DIM_GRP_UDFIELD_R where N_ENTITY_TYPE_ID_R='200' AND  V_FIELD2_r ='1')DIM_GRP_UDFIELD_R
	ON DIM_GRP_UDFIELD_R.N_ENTITY_ID_R=TBL_NAME4.N_SOURCE_SYSTEM_KEY_R

	LEFT JOIN (SELECT * FROM ATOMIC.DIM_GRP_MTOPTION_R  WHERE v_ITEM_r NOT LIKE '%NSC%' )DIM_GRP_MTOPTION_R_NOTNSC

	ON DIM_GRP_UDFIELD_R.V_FIELD6_R = DIM_GRP_MTOPTION_R_NOTNSC.N_OPTIONID_R

	LEFT JOIN (SELECT * FROM ATOMIC.DIM_GRP_MTOPTION_R A JOIN ATOMIC.STG_PBC_RSO_TEAM_R B ON  upper(B.V_RSO_DESC_R)=A.v_ITEM_r  WHERE v_ITEM_r  LIKE '%NSC%'
	)DIM_GRP_MTOPTION_R_NSC ON DIM_GRP_UDFIELD_R.V_FIELD6_R = DIM_GRP_MTOPTION_R_NSC.N_OPTIONID_R

	LEFT JOIN (select V_RSO_ABBREV_R,V_PBC_SUB_TEAM_R,V_PBC_TEAM_NAME_R from ATOMIC.STG_PBC_RSO_TEAM_R A where A.V_NEW_BUSINESS_IND_R = 'NEW'
	GROUP BY  V_RSO_ABBREV_R,V_PBC_SUB_TEAM_R,V_PBC_TEAM_NAME_R)STG_PBC_RSO_TEAM_R_ET_STEP4
	ON     TBL_NAME3.V_RSO_ABBREV_R=STG_PBC_RSO_TEAM_R_ET_STEP4.V_RSO_ABBREV_R
	---new changes by Erica on 07-Oct-2022 starts
	LEFT JOIN (SELECT MAX(FP.D_INSTALLATION_DATE_R) D_INSTALLATION_DATE_R, FP.N_POLICY_SK_R FROM ATOMIC.FCT_GRP_BILLING_POLICY_DTL_R FP
	WHERE FP.N_BATCH_ID_R = (SELECT MAX(N_BATCH_ID_R) MAX_BATCH_ID FROM FCT_GRP_BILLING_POLICY_DTL_R MAX_BATCH WHERE MAX_BATCH.N_POLICY_SK_R = FP.N_POLICY_SK_R)
	GROUP BY  FP.N_POLICY_SK_R
	)FCT_GRP_BILLING_POLICY_DTL_R
	ON FCT_GRP_BILLING_POLICY_DTL_R.N_POLICY_SK_R=TBL_NAME2.N_POLICY_SK_R
	---new changes by Erica on 07-Oct-2022 ends
	) FCT_POLICY

	LEFT JOIN (SELECT N_POLICY_SK_R FROM ATOMIC.FCT_BILLING_POLICY_PREMIUM_R GROUP BY N_POLICY_SK_R)F ON FCT_POLICY.N_POLICY_SK_R=F.N_POLICY_SK_R

	LEFT JOIN (select N_POLICY_SK_R,v_action_description_r FROM  ATOMIC.DIM_GRP_WRKFLW_ACTIVITY_DTLS_R where v_action_description_r='SMARTCHOICEINDICATOR' GROUP BY N_POLICY_SK_R,v_action_description_r)STEP5 ON TRIM(FCT_POLICY.N_POLICY_SK_R)=TRIM(STEP5.N_POLICY_SK_R)
	;




	COMMIT;
	OUT_LOAD_STATUS:='SUCCESS';
	EXCEPTION
	WHEN OTHERS THEN
	LC_SQLCODE:=SQLCODE;
	LC_SQLERRM:=SUBSTR(SQLERRM,1,4000);
	OUT_LOAD_STATUS:=LC_SQLCODE||'-'||LC_SQLERRM;
	DBMS_OUTPUT.PUT_LINE('PRC_LOAD_FCT_GRP_POLICY_R_PBC_TEAM_LOOKUP  EXCEPTION WITH ERROR CODE AS '
				 || SQLCODE
				 || ' '
				 || SQLERRM
				 || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
				 ||'PRC_LOAD_FCT_GRP_POLICY_R_PBC_TEAM_LOOKUP'
				 ||';');

    RAISE_APPLICATION_ERROR(-20001,'Error in PKG_LOAD_GRP_TABLES.PRC_LOAD_FCT_GRP_POLICY_R_PBC_TEAM_LOOKUP:->
    Error Code:'||SQLCODE||',Error message:'||SUBSTR(SQLERRM,1,4000));

	END PRC_LOAD_FCT_GRP_POLICY_R_PBC_TEAM_LOOKUP;










	PROCEDURE PRC_LOAD_DIM_GRP_CLAIM_DETAIL_SUBGROUP_LOOKUP(
		IN_BATCH_ID_R        IN NUMBER,
		OUT_LOAD_STATUS      OUT VARCHAR2
		)
	IS
	LD_SYSDATE DATE :=SYSDATE;
	LC_SQLCODE VARCHAR2(4000);
	LC_SQLERRM VARCHAR2(4000);
	LN_SEQUENCE_NUMBER_R NUMBER;
	LN_IN_BATCH_ID_R NUMBER:=IN_BATCH_ID_R;
	LN_LOAD_RUN_ID_R NUMBER;
	BEGIN

		IF LN_IN_BATCH_ID_R IS NULL THEN
		  OUT_LOAD_STATUS:='a) BatchID(IN_BATCH_ID) is null hence terminating the program';
		 RAISE_APPLICATION_ERROR(-20001,'a) BatchID(IN_BATCH_ID) is null hence terminating the program');
		END IF;



	SELECT   COUNT(1)
		  INTO ln_load_run_id_r
	FROM ATOMIC.PRCS_JOB_LOG_R
	WHERE N_BATCH_ID_R =IN_BATCH_ID_R
	AND V_JOB_NAME_R='PKG_GRP_LOAD_DIM_GRP_CLAIM_DETAIL_SUBGROUP_LOOKUP';

	DELETE FROM DIM_GRP_CLAIM_DETAIL_SUBGROUP_LOOKUP WHERE V_SOURCE_SYSTEM_NAME_R ='PACS';
	COMMIT;



	INSERT /*+APPEND_VALUES*/ INTO ATOMIC.DIM_GRP_CLAIM_DETAIL_SUBGROUP_LOOKUP
	(V_CLAIM_NUMBER_R,
	N_POLICY_SK_R,
	N_SOURCE_SYSTEM_KEY_R,
	N_PARTY_SK_R,
	N_SOURCE_VERSION_NUMBER_R,
	V_SUBGROUP_ID_R,
	V_CORRESPONDENT_NAME_R,
	V_SUBGROUP_NAME_R,
	V_SUBGROUP_ADDRESSLINE1_R,
	V_SUBGROUP_ADDRESSLINE2_R,
	V_SUBGROUP_POSTALZIP_R,
	V_SUBGROUP_PROVSTATE_R,
	V_SUBGROUP_CITY_R,
	N_BATCH_ID_R          ,
	N_SEQUENCE_NUMBER_R   ,
	T_CREATION_DATE_R     ,
	T_LAST_MODIFIED_DATE_R,
	V_CREATED_BY_R        ,
	V_LAST_MODIFIED_BY_R,
	V_SOURCE_SYSTEM_NAME_R
	)
	SELECT
	DISTINCT --16-Apr-2024 changes
	CLAIM_DIR.V_CLAIM_NUMBER_R,
	CLAIM_DIR.N_POLICY_SK_R,
	PARTY_DIR.N_SOURCE_SYSTEM_KEY_R,
	PARTY_DIR.N_PARTY_SK_R,
	PARTY_DIR.N_SOURCE_VERSION_NUMBER_R,
	NVL(NVL(NVL(NVL(NVL(subs_test.v_subgroup_id_r,'00000'),ENTITYLOCATION_MAIN.v_subgroup_id_r),ENTITYLOCATION_SITUS.v_subgroup_id_r),
	ENTITYLOCATION_SUBGROUP.v_subgroup_id_r) ,'00000')AS v_subgroup_id_r,
	NVL(NVL(NVL(NVL(SUBGROUP1.v_correspondent_name_r,SUBGROUP.v_correspondent_name_r),ENTITYLOCATION_MAIN.v_subgroup_name_r),
	ENTITYLOCATION_SITUS.v_subgroup_name_r),
	ENTITYLOCATION_SUBGROUP.v_subgroup_name_r) AS v_correspondent_name_r,
	NVL(NVL(NVL(NVL(NVL(NVL(subs_test.V_OVERRIDE_NAME_R,SUBGROUP1.v_subgroup_name_r),SUBGROUP.v_subgroup_name_r),ENTITYLOCATION_MAIN.v_subgroup_name_r),
	ENTITYLOCATION_SITUS.v_subgroup_name_r),
	ENTITYLOCATION_SUBGROUP.v_subgroup_name_r),PARTY.V_INDIVIDUAL_LAST_NAME_R) AS v_subgroup_name_r,
	NVL(NVL(SUBGROUP.v_subgroup_addressline1_r,ENTITYLOCATION_MAIN.v_subgroup_addressline1_r),ENTITYLOCATION_SITUS.v_subgroup_addressline1_r) AS v_subgroup_addressline1_r ,
	NVL(NVL(SUBGROUP.v_subgroup_addressline2_r,ENTITYLOCATION_MAIN.v_subgroup_addressline2_r),ENTITYLOCATION_SITUS.v_subgroup_addressline2_r) AS v_subgroup_addressline2_r,
	NVL(NVL(SUBGROUP.v_subgroup_postalzip_r,ENTITYLOCATION_MAIN.v_subgroup_postalzip_r),ENTITYLOCATION_SITUS.v_subgroup_postalzip_r) AS v_subgroup_postalzip_r ,
	NVL(NVL(SUBGROUP.v_subgroup_provstate_r,ENTITYLOCATION_MAIN.v_subgroup_provstate_r),ENTITYLOCATION_SITUS.v_subgroup_provstate_r) AS v_subgroup_provstate_r,
	NVL(NVL(SUBGROUP.v_subgroup_city_r,ENTITYLOCATION_MAIN.v_subgroup_city_r),ENTITYLOCATION_SITUS.v_subgroup_city_r) AS v_subgroup_city_r,
	IN_BATCH_ID_R          ,
	NVL(LN_SEQUENCE_NUMBER_R,0)+ROWNUM   ,
	LD_SYSDATE,--T_CREATION_DATE_R     ,
	LD_SYSDATE,--T_LAST_MODIFIED_DATE_R,
	'ODI' V_CREATED_BY_R        ,
	'ODI' V_LAST_MODIFIED_BY_R,
	V_SOURCE_SYSTEM_NAME_R
	FROM (SELECT V_CLAIM_NUMBER_R,N_POLICY_SK_R,N_POLICY_SOURCE_SYSTEM_KEY_R,V_SOURCE_SYSTEM_NAME_R FROM DIM_GRP_CLAIM_DIR_R WHERE V_ACTIVE_STATUS_R='Y' and V_SOURCE_SYSTEM_NAME_R='PACS'-----new changes by Gisha on 02-Mar-2023 starts
	GROUP BY V_CLAIM_NUMBER_R,N_POLICY_SK_R,N_POLICY_SOURCE_SYSTEM_KEY_R,V_SOURCE_SYSTEM_NAME_R) CLAIM_DIR
	LEFT JOIN (SELECT N_CUST_PARTY_SK_R,N_POLICY_SK_R,N_SOURCE_SYSTEM_KEY_R FROM FCT_GRP_POLICY_R
	GROUP BY N_CUST_PARTY_SK_R,N_POLICY_SK_R,N_SOURCE_SYSTEM_KEY_R ) FCT_GRP_POLICY
	ON TRIM(CLAIM_DIR.N_POLICY_SK_R)=TRIM(FCT_GRP_POLICY.N_POLICY_SK_R)
	AND  TRIM(CLAIM_DIR.N_POLICY_SOURCE_SYSTEM_KEY_R)=TRIM(FCT_GRP_POLICY.N_SOURCE_SYSTEM_KEY_R)--------new changes by Gisha on 02-Mar-2023 ends

	LEFT JOIN (SELECT N_PARTY_SK_R,N_SOURCE_SYSTEM_KEY_R,N_SOURCE_VERSION_NUMBER_R FROM DIM_GRP_PARTY_DIR_R
	WHERE V_ACTIVE_STATUS_R='Y'
	GROUP BY N_PARTY_SK_R,N_SOURCE_SYSTEM_KEY_R,N_SOURCE_VERSION_NUMBER_R) PARTY_DIR
	ON TRIM(PARTY_DIR.N_PARTY_SK_R)=TRIM(FCT_GRP_POLICY.N_CUST_PARTY_SK_R)

	LEFT JOIN (SELECT A.n_cust_subgrp_src_sys_key_r,A.n_cust_subgrp_src_version_nbr_r,A.v_correspondent_name_r,A.v_subgroup_name_r,A.v_subgroup_id_r
	FROM DIM_GRP_CUST_ENTITYSUBGROUP_R A
	JOIN
	(SELECT n_cust_subgrp_src_sys_key_r,n_cust_subgrp_src_version_nbr_r,MAX(cust_subgrp_seq_nbr_r) AS MAX_SEQ_NBR
	FROM DIM_GRP_CUST_ENTITYSUBGROUP_R WHERE V_ACTIVE_STATUS_R='Y'
	GROUP BY n_cust_subgrp_src_sys_key_r,n_cust_subgrp_src_version_nbr_r)MAX_SEQ
	ON TRIM(A.n_cust_subgrp_src_sys_key_r)=TRIM(MAX_SEQ.n_cust_subgrp_src_sys_key_r)
	AND TRIM(A.n_cust_subgrp_src_version_nbr_r)=TRIM(MAX_SEQ.n_cust_subgrp_src_version_nbr_r)
	AND TRIM(A.cust_subgrp_seq_nbr_r)=TRIM(MAX_SEQ.MAX_SEQ_NBR)
	WHERE V_ACTIVE_STATUS_R='Y'  AND A.v_subgroup_id_r='00000'  and cust_subgrp_add_seq_nbr_r is  null
	GROUP BY A.n_cust_subgrp_src_sys_key_r,A.n_cust_subgrp_src_version_nbr_r,A.v_correspondent_name_r,A.v_subgroup_name_r,A.v_subgroup_id_r)SUBGROUP1
	ON TRIM(PARTY_DIR.N_SOURCE_SYSTEM_KEY_R)=TRIM(SUBGROUP1.n_cust_subgrp_src_sys_key_r)
	AND TRIM(PARTY_DIR.N_SOURCE_VERSION_NUMBER_R)=TRIM(SUBGROUP1.n_cust_subgrp_src_version_nbr_r)

	LEFT JOIN (SELECT A.n_cust_subgrp_src_sys_key_r,A.n_cust_subgrp_src_version_nbr_r,v_subgroup_id_r,
	v_correspondent_name_r,v_subgroup_name_r,v_subgroup_addressline1_r,v_subgroup_addressline2_r,v_subgroup_postalzip_r,
	v_subgroup_provstate_r,v_subgroup_city_r
	FROM DIM_GRP_CUST_ENTITYSUBGROUP_R A
	JOIN
	(SELECT n_cust_subgrp_src_sys_key_r,n_cust_subgrp_src_version_nbr_r,MAX(cust_subgrp_seq_nbr_r) AS MAX_SEQ_NBR
	FROM DIM_GRP_CUST_ENTITYSUBGROUP_R WHERE V_ACTIVE_STATUS_R='Y'
	GROUP BY n_cust_subgrp_src_sys_key_r,n_cust_subgrp_src_version_nbr_r)MAX_SEQ
	ON TRIM(A.n_cust_subgrp_src_sys_key_r)=TRIM(MAX_SEQ.n_cust_subgrp_src_sys_key_r)
	AND TRIM(A.n_cust_subgrp_src_version_nbr_r)=TRIM(MAX_SEQ.n_cust_subgrp_src_version_nbr_r)
	AND TRIM(A.cust_subgrp_seq_nbr_r)=TRIM(MAX_SEQ.MAX_SEQ_NBR)
	WHERE V_ACTIVE_STATUS_R='Y'  and cust_subgrp_add_seq_nbr_r is not null
	GROUP BY A.n_cust_subgrp_src_sys_key_r,A.n_cust_subgrp_src_version_nbr_r,v_subgroup_id_r,
	v_correspondent_name_r,v_subgroup_name_r,v_subgroup_addressline1_r,v_subgroup_addressline2_r,v_subgroup_postalzip_r,
	v_subgroup_provstate_r,v_subgroup_city_r)SUBGROUP
	ON TRIM(PARTY_DIR.N_SOURCE_SYSTEM_KEY_R)=TRIM(SUBGROUP.n_cust_subgrp_src_sys_key_r)
	AND TRIM(PARTY_DIR.N_SOURCE_VERSION_NUMBER_R)=TRIM(SUBGROUP.n_cust_subgrp_src_version_nbr_r)





	LEFT JOIN (SELECT C.N_SOURCE_SYSTEM_KEY_R,C.N_ADDRESS_VERSION_NUMBER_R,C.V_SUBGROUP_ID_R,
	C.V_SUBGROUP_NAME_R,C.V_SUBGROUP_ADDRESSLINE1_R,C.V_SUBGROUP_ADDRESSLINE2_R,C.V_SUBGROUP_POSTALZIP_R,
	c.V_SUBGROUP_PROVSTATE_R,c.V_SUBGROUP_CITY_R
	FROM DIM_GRP_ENTITYLOCATION_R c -- added alias name
	WHERE V_ACTIVE_STATUS_R='Y'  AND  UPPER(V_LOCATION_ID_R)='MAIN'
	 --19-Apr-2023 changes starts
	/*AND UPPER(V_DESCRIPTION_R)='MAILING ADDRESS'*/
	and C.T_EVENT_TIMESTAMP_R =
	(select max(b.T_EVENT_TIMESTAMP_R)T_EVENT_TIMESTAMP_R from
	DIM_GRP_ENTITYLOCATION_R b
	where b.V_ACTIVE_STATUS_R='Y'
	AND  UPPER(b.V_LOCATION_ID_R)='MAIN'
	and b.N_ADDRESS_VERSION_NUMBER_R = C.N_ADDRESS_VERSION_NUMBER_R
	and b.N_SOURCE_SYSTEM_KEY_R = C.N_SOURCE_SYSTEM_KEY_R)
	 --19-Apr-2023 changes ends
	GROUP BY N_SOURCE_SYSTEM_KEY_R,N_ADDRESS_VERSION_NUMBER_R,v_subgroup_id_r,
	v_subgroup_name_r,v_subgroup_addressline1_r,v_subgroup_addressline2_r,v_subgroup_postalzip_r,
	v_subgroup_provstate_r,v_subgroup_city_r)ENTITYLOCATION_MAIN
	ON TRIM(PARTY_DIR.N_SOURCE_SYSTEM_KEY_R)=TRIM(ENTITYLOCATION_MAIN.N_SOURCE_SYSTEM_KEY_R)
	AND TRIM(PARTY_DIR.N_SOURCE_VERSION_NUMBER_R)=TRIM(ENTITYLOCATION_MAIN.N_ADDRESS_VERSION_NUMBER_R)

	LEFT JOIN (SELECT N_SOURCE_SYSTEM_KEY_R,N_ADDRESS_VERSION_NUMBER_R,v_subgroup_id_r,
	v_subgroup_name_r,v_subgroup_addressline1_r,v_subgroup_addressline2_r,v_subgroup_postalzip_r,
	v_subgroup_provstate_r,v_subgroup_city_r
	FROM DIM_GRP_ENTITYLOCATION_R
	WHERE V_ACTIVE_STATUS_R='Y'  AND   UPPER(V_LOCATION_ID_R)='SITUS' AND UPPER(V_DESCRIPTION_R)='SITUS ADDRESS'
	GROUP BY N_SOURCE_SYSTEM_KEY_R,N_ADDRESS_VERSION_NUMBER_R,v_subgroup_id_r,
	v_subgroup_name_r,v_subgroup_addressline1_r,v_subgroup_addressline2_r,v_subgroup_postalzip_r,
	v_subgroup_provstate_r,v_subgroup_city_r)ENTITYLOCATION_SITUS
	ON TRIM(PARTY_DIR.N_SOURCE_SYSTEM_KEY_R)=TRIM(ENTITYLOCATION_SITUS.N_SOURCE_SYSTEM_KEY_R)
	AND TRIM(PARTY_DIR.N_SOURCE_VERSION_NUMBER_R)=TRIM(ENTITYLOCATION_SITUS.N_ADDRESS_VERSION_NUMBER_R)


	LEFT JOIN (SELECT N_SOURCE_SYSTEM_KEY_R,N_ADDRESS_VERSION_NUMBER_R,V_SUBGROUP_ID_R,
	V_SUBGROUP_NAME_R
	FROM DIM_GRP_ENTITYLOCATION_R
	WHERE V_ACTIVE_STATUS_R='Y'
	GROUP BY N_SOURCE_SYSTEM_KEY_R,N_ADDRESS_VERSION_NUMBER_R,V_SUBGROUP_ID_R,
	V_SUBGROUP_NAME_R)ENTITYLOCATION_SUBGROUP
	ON TRIM(PARTY_DIR.N_SOURCE_SYSTEM_KEY_R)=TRIM(ENTITYLOCATION_SUBGROUP.N_SOURCE_SYSTEM_KEY_R)
	AND TRIM(PARTY_DIR.N_SOURCE_VERSION_NUMBER_R)=TRIM(ENTITYLOCATION_SUBGROUP.N_ADDRESS_VERSION_NUMBER_R)
	left join (select a.v_claim_number_r,a.V_SUBGROUP_NAME_R,a.V_OVERRIDE_NAME_R , b.V_SUBGROUP_ID_R
	from (SELECT v_claim_number_r, V_SUBGROUP_NAME_R, V_OVERRIDE_NAME_R, N_CLAIM_SUBS_LINK_VERSION_NBR_R,N_CLAIM_SUBS_LINK_SEQ_NBR_R, N_CLAIM_SUBS_LINK_SRC_SYS_KEY_R, V_ACTIVE_STATUS_R, rank FROM (
			select v_claim_number_r,V_SUBGROUP_NAME_R,V_OVERRIDE_NAME_R, N_CLAIM_SUBS_LINK_SEQ_NBR_R, N_CLAIM_SUBS_LINK_SRC_SYS_KEY_R,N_CLAIM_SUBS_LINK_VERSION_NBR_R, V_ACTIVE_STATUS_R,
			RANK() OVER (PARTITION BY v_claim_number_r ORDER BY N_BATCH_ID_R DESC) AS rank
			FROM atomic.dim_GRP_CLAIM_SUBSIDIARY_R  ) WHERE rank = 1)  a
	left join DIM_GRP_CUST_ENTITYSUBGROUP_R b
	on a.N_CLAIM_SUBS_LINK_SEQ_NBR_R=b.CUST_SUBGRP_SEQ_NBR_R
	and a.N_CLAIM_SUBS_LINK_SRC_SYS_KEY_R= b.N_CUST_SUBGRP_SRC_SYS_KEY_R
	and a.N_CLAIM_SUBS_LINK_VERSION_NBR_R = b.N_CUST_SUBGRP_SRC_VERSION_NBR_R
	and b.v_active_status_r = 'Y'
	where a.v_active_Status_R='Y'
	GROUP BY a.v_claim_number_r,a.V_SUBGROUP_NAME_R,a.V_OVERRIDE_NAME_R , b.V_SUBGROUP_ID_R --16-Apr-2024 changes
	)subs_test on
	trim( CLAIM_DIR.v_claim_number_r)=trim(subs_test.v_claim_number_r)
	left join (select V_INDIVIDUAL_LAST_NAME_R,n_party_sk_R from dim_grp_party_r where v_active_Status_R='Y')PARTY
	on PARTY_DIR.n_party_sk_R=PARTY.n_party_sk_r;

	COMMIT;
	OUT_LOAD_STATUS:='SUCCESS';
	EXCEPTION
	WHEN OTHERS THEN
	LC_SQLCODE:=SQLCODE;
	LC_SQLERRM:=SUBSTR(SQLERRM,1,4000);
	OUT_LOAD_STATUS:=LC_SQLCODE||'-'||LC_SQLERRM;
	DBMS_OUTPUT.PUT_LINE('PRC_LOAD_DIM_GRP_CLAIM_DETAIL_SUBGROUP_LOOKUP  EXCEPTION WITH ERROR CODE AS '
				 || SQLCODE
				 || ' '
				 || SQLERRM
				 || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
				 ||'PRC_LOAD_DIM_GRP_CLAIM_DETAIL_SUBGROUP_LOOKUP'
				 ||';');

    RAISE_APPLICATION_ERROR(-20001,'Error in PKG_LOAD_GRP_TABLES.PRC_LOAD_DIM_GRP_CLAIM_DETAIL_SUBGROUP_LOOKUP:->
    Error Code:'||SQLCODE||',Error message:'||SUBSTR(SQLERRM,1,4000));
	end PRC_LOAD_DIM_GRP_CLAIM_DETAIL_SUBGROUP_LOOKUP;



	PROCEDURE PRC_LOAD_DIM_GRP_CLAIM_DETAIL_SUBGROUP_LOOKUP_CV(
		IN_BATCH_ID_R        IN NUMBER
		)
	IS
	LD_SYSDATE DATE :=SYSDATE;
	LC_SQLCODE VARCHAR2(4000);
	LC_SQLERRM VARCHAR2(4000);
	LN_SEQUENCE_NUMBER_R NUMBER;
	LN_IN_BATCH_ID_R NUMBER:=IN_BATCH_ID_R;
	LN_LOAD_RUN_ID_R NUMBER;
	BEGIN

		IF LN_IN_BATCH_ID_R IS NULL THEN
		 RAISE_APPLICATION_ERROR(-20001,'a) BatchID(IN_BATCH_ID) is null hence terminating the program');
		END IF;


	SELECT   COUNT(1)
		  INTO ln_load_run_id_r
	FROM ATOMIC.PRCS_JOB_LOG_R
	WHERE N_BATCH_ID_R =IN_BATCH_ID_R
	AND V_JOB_NAME_R='CV_PKG_GRP_LOAD_DIM_GRP_CLAIM_DETAIL_SUBGROUP_LOOKUP';

	DELETE FROM DIM_GRP_CLAIM_DETAIL_SUBGROUP_LOOKUP WHERE V_SOURCE_SYSTEM_NAME_R ='CV';
	COMMIT;




	INSERT /*+APPEND_VALUES*/ INTO ATOMIC.DIM_GRP_CLAIM_DETAIL_SUBGROUP_LOOKUP
	(V_CLAIM_NUMBER_R,
	N_POLICY_SK_R,
	N_SOURCE_SYSTEM_KEY_R,
	N_PARTY_SK_R,
	N_SOURCE_VERSION_NUMBER_R,
	V_SUBGROUP_ID_R,
	V_CORRESPONDENT_NAME_R,
	V_SUBGROUP_NAME_R,
	V_SUBGROUP_ADDRESSLINE1_R,
	V_SUBGROUP_ADDRESSLINE2_R,
	V_SUBGROUP_POSTALZIP_R,
	V_SUBGROUP_PROVSTATE_R,
	V_SUBGROUP_CITY_R,
	N_BATCH_ID_R          ,
	N_SEQUENCE_NUMBER_R   ,
	T_CREATION_DATE_R     ,
	T_LAST_MODIFIED_DATE_R,
	V_CREATED_BY_R        ,
	V_LAST_MODIFIED_BY_R,
	V_SOURCE_SYSTEM_NAME_R
	)
	SELECT
	CLAIM_DIR.V_CLAIM_NUMBER_R,
	CLAIM_DIR.N_POLICY_SK_R,
	CLAIM_DIR.N_SOURCE_SYSTEM_KEY_R,
	CLAIM_DETAIL.N_INSRD_PARTY_SK_R,
	CLAIM_DIR.N_SOURCE_VERSION_NUMBER_R,
	CLAIM_DETAIL.V_SUBGROUP_ID_R,
	CLAIM_DETAIL.V_CORRESPONDENT_NAME_R,
	CLAIM_DETAIL.V_SUBGROUP_NAME_R,
	CLAIM_DETAIL.V_SUBGROUP_ADDRESSLINE1_R,
	CLAIM_DETAIL.V_SUBGROUP_ADDRESSLINE2_R,
	CLAIM_DETAIL.V_SUBGROUP_POSTALZIP_R,
	CLAIM_DETAIL.V_SUBGROUP_PROVSTATE_R,
	CLAIM_DETAIL.V_SUBGROUP_CITY_R,
	IN_BATCH_ID_R          ,
	NVL(LN_SEQUENCE_NUMBER_R,0)+ROWNUM   ,
	LD_SYSDATE,--T_CREATION_DATE_R     ,
	LD_SYSDATE,--T_LAST_MODIFIED_DATE_R,
	'PKG_LOAD_GRP_TABLES.PRC_LOAD_DIM_GRP_CLAIM_DETAIL_SUBGROUP_LOOKUP_CV' V_CREATED_BY_R        ,
	'PKG_LOAD_GRP_TABLES.PRC_LOAD_DIM_GRP_CLAIM_DETAIL_SUBGROUP_LOOKUP_CV' V_LAST_MODIFIED_BY_R,
	V_SOURCE_SYSTEM_NAME_R
	FROM (SELECT V_CLAIM_NUMBER_R,N_POLICY_SK_R,N_CLAIM_SK_R,N_SOURCE_SYSTEM_KEY_R,N_SOURCE_VERSION_NUMBER_R,
	N_BATCH_ID_R,N_SEQUENCE_NUMBER_R,T_CREATION_DATE_R,T_LAST_MODIFIED_DATE_R,V_CREATED_BY_R,V_LAST_MODIFIED_BY_R,V_SOURCE_SYSTEM_NAME_R FROM DIM_GRP_CLAIM_DIR_R WHERE V_ACTIVE_STATUS_R = 'Y' and V_SOURCE_SYSTEM_NAME_R = 'CV') CLAIM_DIR
	LEFT JOIN (SELECT N_INSRD_PARTY_SK_R,N_CLAIM_SK_R,V_SUBGROUP_ID_R,V_CORRESPONDENT_NAME_R,V_SUBGROUP_NAME_R,V_SUBGROUP_ADDRESSLINE1_R,V_SUBGROUP_ADDRESSLINE2_R,V_SUBGROUP_POSTALZIP_R,V_SUBGROUP_PROVSTATE_R,V_SUBGROUP_CITY_R FROM DIM_GRP_CLAIM_DETAIL_R WHERE V_ACTIVE_STATUS_R = 'Y' and V_SOURCE_SYSTEM_NAME_R = 'CV') CLAIM_DETAIL ON CLAIM_DETAIL.N_CLAIM_SK_R = CLAIM_DIR.N_CLAIM_SK_R;

	commit;




	EXCEPTION
	WHEN OTHERS THEN
	LC_SQLCODE:=SQLCODE;
	LC_SQLERRM:=SUBSTR(SQLERRM,1,4000);
	DBMS_OUTPUT.PUT_LINE('PRC_LOAD_DIM_GRP_CLAIM_DETAIL_SUBGROUP_LOOKUP_CV  EXCEPTION WITH ERROR CODE AS '
				 || SQLCODE
				 || ' '
				 || SQLERRM
				 || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
				 ||'PRC_LOAD_DIM_GRP_CLAIM_DETAIL_SUBGROUP_LOOKUP_CV'
				 ||';');
	RAISE;
	end PRC_LOAD_DIM_GRP_CLAIM_DETAIL_SUBGROUP_LOOKUP_CV;


/**************************************************************************************
  Purpose	:  	Procedure is used to get the for FCT_GRP_AGENT_POLICY_R_LOOKUP.
  Proc Name	:	PRC_LOAD_FCT_GRP_AGENT_POLICY_R_LOOKUP
---------- 		-------- 		-------------------------------------------------
	VGireesh   	03-Sep-2022 	Initial Version
	Shiva		18-May-2026		Kill/Fill Changes: User Story -
								- All code changes are marked with Kill/Fill start and end comment blocks.
								- Code changes ensure continuous data availability in reports, replacing the current truncate-and-load approach, which is not partition-exchange based.
								- Retaining old code base of bulk collect load; which can be used when this Package to be converted to incremental processing
								- Added Coding Standarisation; formatted the code
***********************************************************************/
	PROCEDURE PRC_LOAD_FCT_GRP_AGENT_POLICY_R_LOOKUP
	(
		IN_BATCH_ID_R        IN NUMBER,
		OUT_LOAD_STATUS      OUT VARCHAR2
	)
	AS
		LD_SYSDATE DATE :=SYSDATE;
		LC_SQLCODE VARCHAR2(4000);
		LC_SQLERRM VARCHAR2(4000);
		LN_SEQUENCE_NUMBER_R NUMBER;
		LN_IN_BATCH_ID_R NUMBER:=IN_BATCH_ID_R;
		LN_LOAD_RUN_ID_R NUMBER;
	BEGIN

	IF LN_IN_BATCH_ID_R IS NULL THEN
		OUT_LOAD_STATUS:='a) BatchID(IN_BATCH_ID) is null hence terminating the program';
		RAISE_APPLICATION_ERROR(-20001,'a) BatchID(IN_BATCH_ID) is null hence terminating the program');
	END IF;

	SELECT   COUNT(1)
		  INTO ln_load_run_id_r
	FROM ATOMIC.PRCS_JOB_LOG_R
	WHERE N_BATCH_ID_R =IN_BATCH_ID_R
	AND V_JOB_NAME_R='PKG_GRP_LOAD_FCT_GRP_AGENT_POLICY_R_LOOKUP';


	BEGIN
		execute immediate 'TRUNCATE TABLE ATOMIC.FCT_GRP_AGENT_POLICY_R_LOOKUP_STG'; --kill/fill changes ; Added New
		--execute immediate 'TRUNCATE TABLE ATOMIC.FCT_GRP_AGENT_POLICY_R_LOOKUP PURGE SNAPSHOT LOG'; --kill/fill changes ; commented
	END;


	INSERT /*+APPEND_VALUES*/ INTO ATOMIC.FCT_GRP_AGENT_POLICY_R_LOOKUP_STG
	(
		n_agent_sk_r ,
		n_policy_billgroup_sk_r,
		n_policy_sk_r ,
		--n_party_sk_r,
		--v_prdcr_agent_id_r ,
		--n_policy_billgroup_id_r ,
		--v_policy_id_r ,
		--n_customer_number_r ,
		n_is_split_agent_r ,
		n_split_percentage_r ,
		n_arrangement_code_r ,
		d_start_date_r ,
		d_end_date_r ,
		n_split_with_r ,
		d_insert_date_r ,
		d_delete_date_r ,
		v_commission_type_r ,
		n_dc_arrangement_code_r ,
		v_subject_area_type_r ,
		t_event_timestamp_r ,
		v_source_system_name_r ,
		FIC_MIS_DATE_R ,
		N_BATCH_ID_R ,
		N_SEQUENCE_NUMBER_R ,
		T_CREATION_DATE_R ,
		T_LAST_MODIFIED_DATE_R ,
		V_CREATED_BY_R ,
		V_LAST_MODIFIED_BY_R,
		--JSON_FILENAME ,
		D_RPT_START_DATE_R ,
		D_RPT_END_DATE_R ,
		N_RPT_PRIMARY_INDICATOR_R ,
		V_SPECIAL_HANDLING_5500_IND_R ,
		 N_RPT_TOTAL_AGENTS_R ,
		N_RPT_SORT_ORDER_R,
		F_PHYSICAL_DELETE_R ,
		V_CHANGE_REASON_R ,
		--V_ACTIVE_STATUS_R,
		N_RPT_SPLIT_PERCENTAGE_R,
		final_result_1,
		final_result_2,
		n_agent_policy_id_r,
		v_delete_by_r,
		V_TEMPLATE_NAME_R ,
		N_LAST_RATE_R ,
		--28-01-2025 change start
		V_TEMPLATE_NAME_R_1
		--28-01-2025 change end
	)


	-- CTE FUNCTION
	with RPT_SPLIT_PERCENTAGE_FIRST as
	(
	select
		cte1.n_policy_sk_r as n_policy_sk_r  ,
		cte1.n_agent_sk_r as n_agent_sk_r ,
		cte1.V_COMMISSION_TYPE_R,
		CTE1.N_AGENT_POLICY_ID_R,
		n_rpt_split_percentage_r_1,
		n_rpt_split_percentage_r ,
		(n_rpt_split_percentage_r_1/nullif(n_rpt_split_percentage_r,0)) as final_result_1

	from
	(
		select
			a.N_POLICY_SK_R,
			A.n_agent_sk_r,
			A.V_COMMISSION_TYPE_R,
			A.N_AGENT_POLICY_ID_R,
			SUM(NVL(N_SPLIT_PERCENTAGE_R,100)) as N_RPT_SPLIT_PERCENTAGE_R_1
		from atomic.fct_grp_agent_policy_r  a
		join
		(
			select
				N_POLICY_SK_R,
				N_AGENT_SK_R,
				n_contract_template_id_r
			from atomic.dim_grp_agent_contract_tmplt_r
			where  UPPER(V_TEMPLATE_NAME_R) <> 'PCW00' and v_active_status_r = 'Y'
			group by N_POLICY_SK_R, N_AGENT_SK_R, n_contract_template_id_r
		) b
		on 	a.N_POLICY_SK_R=b.N_POLICY_SK_R
		and a.N_AGENT_SK_R=b.N_AGENT_SK_R
		--AND a.N_BATCH_ID_R = IN_BATCH_ID_R--'202109190000'
		join atomic.dim_grp_arrangement_r c
			on a.N_ARRANGEMENT_CODE_R =c.N_ARRANGEMENT_ID_R and b.n_contract_template_id_r =c.N_TEMPLATE_ID_R
		join atomic.dim_grp_agent_directory_r ad
			on b.n_agent_sk_r = ad.n_agent_sk_r and ad.v_active_status_r = 'Y'
		where
			sysdate between a.d_start_date_r and NVL(a.d_end_date_r,sysdate)
		and a.d_delete_date_r is null--04-Jan-2023 changes
		and ad.v_agent_number_r <> '273286-0001' and ad.v_agent_number_r like '%-0000'
		and /*UPPER(trim(a.V_COMMISSION_TYPE_R))  in ('COMMISSION','OVERRIDE') */ --19-Aug-2024 Changes
		UPPER(trim(a.V_COMMISSION_TYPE_R)) = 'COMMISSION'  --19-Aug-2024 Changes
		group by a.N_POLICY_SK_R,
		a.N_AGENT_SK_R,
		a.V_COMMISSION_TYPE_R,
		a.N_AGENT_POLICY_ID_R
	) cte1
	join
	(
		select a.n_policy_sk_r,
		NVL(sum(a.n_split_percentage_r), 100) as n_rpt_split_percentage_r
		from atomic.fct_grp_agent_policy_r a
		join
		(
			select n_policy_sk_r,
			n_agent_sk_r,
			n_contract_template_id_r
			from atomic.dim_grp_agent_contract_tmplt_r
			where  UPPER(V_TEMPLATE_NAME_R) <> 'PCW00' and v_active_status_r = 'Y'
			group by n_policy_sk_r,
			n_agent_sk_r,
			n_contract_template_id_r
		) b
		on a.n_policy_sk_r=b.n_policy_sk_r
		and a.n_agent_sk_r=b.n_agent_sk_r
		--AND a.N_BATCH_ID_R = IN_BATCH_ID_R--'202109190000'
		join atomic.dim_grp_arrangement_r c
			on a.N_ARRANGEMENT_CODE_R =c.N_ARRANGEMENT_ID_R and b.n_contract_template_id_r =c.N_TEMPLATE_ID_R
		join atomic.dim_grp_agent_directory_r ad
			on b.n_agent_sk_r = ad.n_agent_sk_r and ad.v_active_status_r = 'Y'--04-Jan-2023 changes
		where sysdate between a.d_start_date_r and NVL(a.d_end_date_r,sysdate)
		 and a.d_delete_date_r is null--04-Jan-2023 changes
		and
		 /*UPPER(trim(a.V_COMMISSION_TYPE_R))  in ('COMMISSION','OVERRIDE') */ --19-Aug-2024 Changes
		UPPER(trim(a.V_COMMISSION_TYPE_R)) = 'COMMISSION'  --19-Aug-2024 Changes
		 and
		ad.v_agent_number_r <> '273286-0001' and ad.v_agent_number_r like '%-0000' and
		/*UPPER(trim(a.V_COMMISSION_TYPE_R))  in ('COMMISSION','OVERRIDE') */ --19-Aug-2024 Changes
		UPPER(trim(a.V_COMMISSION_TYPE_R)) = 'COMMISSION'  --19-Aug-2024 Changes
		group by a.n_policy_sk_r
	)cte2
		on cte1.n_policy_sk_r=cte2.n_policy_sk_r
		where n_rpt_split_percentage_r_1<>0
		order by cte1.n_policy_sk_r, cte1.n_agent_sk_r
	)

	-- CTE FUNCTION
	,
	RPT_SPLIT_PERCENTAGE_SECOND as
	(
		select cte1.n_policy_sk_r as n_policy_sk_r,
		cte1.n_agent_sk_r as n_agent_sk_r,
		cte1.V_COMMISSION_TYPE_R,
		cte1.n_agent_policy_id_r,
		n_rpt_split_percentage_r_2,
		n_rpt_split_percentage_r ,
		(n_rpt_split_percentage_r_2/nullif(n_rpt_split_percentage_r,0)) as final_result_2
		from
		(
			select a.n_policy_sk_r,
				a.n_agent_sk_r,
				a.V_COMMISSION_TYPE_R,
				a.n_agent_policy_id_r,
				sum(NVL(n_split_percentage_r, 100)) as n_rpt_split_percentage_r_2
			from atomic.fct_grp_agent_policy_r a
			join
			(
				select n_policy_sk_r,
				n_agent_sk_r,
				n_contract_template_id_r from atomic.dim_grp_agent_contract_tmplt_r
				where  UPPER(V_TEMPLATE_NAME_R) <> 'PCW00' and v_active_status_r = 'Y'
				group by n_policy_sk_r,
				n_agent_sk_r,
				n_contract_template_id_r
			) b on a.n_policy_sk_r=b.n_policy_sk_r and a.n_agent_sk_r=b.n_agent_sk_r --AND a.N_BATCH_ID_R = IN_BATCH_ID_R--'202109190000'
			join atomic.dim_grp_arrangement_r c on a.N_ARRANGEMENT_CODE_R =c.N_ARRANGEMENT_ID_R
			join atomic.dim_grp_agent_directory_r ad
				on 	b.n_agent_sk_r = ad.n_agent_sk_r
				and ad.v_active_status_r = 'Y'
				and b.n_contract_template_id_r =c.N_TEMPLATE_ID_R
			where
				sysdate between a.d_start_date_r and NVL(a.d_end_date_r,sysdate)
				and 	 a.d_delete_date_r is null--04-Jan-2023 changes
				and 	ad.v_agent_number_r <> '273286-0001'
				and 	ad.v_agent_number_r like '%-0000'
				and 	UPPER(a.V_COMMISSION_TYPE_R)  in ('ADMIN')
			group by a.n_policy_sk_r, a.n_agent_sk_r, a.V_COMMISSION_TYPE_R, a.n_agent_policy_id_r
		)cte1

		join
		(
			select a.n_policy_sk_r,
			NVL(sum(a.n_split_percentage_r),100) as n_rpt_split_percentage_r
			from atomic.fct_grp_agent_policy_r a
			join
			(
				select n_policy_sk_r, n_agent_sk_r, n_contract_template_id_r
				from atomic.dim_grp_agent_contract_tmplt_r
				where  UPPER(V_TEMPLATE_NAME_R) <> 'PCW00' and v_active_status_r = 'Y'
				group by n_policy_sk_r, n_agent_sk_r, n_contract_template_id_r
			) b
			on a.n_policy_sk_r=b.n_policy_sk_r
			and a.n_agent_sk_r=b.n_agent_sk_r
			--AND a.N_BATCH_ID_R = IN_BATCH_ID_R--'202109190000'
			join atomic.dim_grp_arrangement_r c
			on 	a.N_ARRANGEMENT_CODE_R =	c.N_ARRANGEMENT_ID_R
			and b.n_contract_template_id_r =c.N_TEMPLATE_ID_R
		 where
			sysdate between a.d_start_date_r and NVL(a.d_end_date_r,sysdate)
			and  a.d_delete_date_r is null--04-Jan-2023 changes
			and
			 /*UPPER(trim(a.V_COMMISSION_TYPE_R))  in ('COMMISSION','OVERRIDE') */ --19-Aug-2024 Changes
			UPPER(trim(a.V_COMMISSION_TYPE_R)) = 'COMMISSION'  --19-Aug-2024 Changes
			group by a.n_policy_sk_r
		 )cte2
		 on 		cte1.n_policy_sk_r=cte2.n_policy_sk_r
		 where 		n_rpt_split_percentage_r_2<>0
		 order by 	cte1.n_policy_sk_r, cte1.n_agent_sk_r
	)

	-- CTE FUNCTION
	, RPT_PRIMARY_INDICATOR as
	(
		select
		(
			case when rank() over( partition by a.n_policy_sk_r order by a.n_policy_sk_r,a.n_is_split_agent_r, RPT_SPLIT_PERCENTAGE_FIRST.final_result_1 ,RPT_SPLIT_PERCENTAGE_SECOND.final_result_2, a.V_COMMISSION_TYPE_R,a.n_agent_sk_r) =1
			then 'P'
			else 'S' end
		) as n_rpt_primary_indicator_r,
		rank() over( partition by a.n_policy_sk_r order by a.n_policy_sk_r,a.n_is_split_agent_r, RPT_SPLIT_PERCENTAGE_FIRST.final_result_1 ,RPT_SPLIT_PERCENTAGE_SECOND.final_result_2, a.V_COMMISSION_TYPE_R,a.n_agent_sk_r) rank_primary,
		a.n_policy_sk_r ,
		a.n_agent_sk_r,
		a.V_COMMISSION_TYPE_R,
		a.n_agent_policy_id_r,
		b.V_TEMPLATE_NAME_R ,
		-- 15/01/25 Changes start
		b.N_LAST_RATE_R
		-- 15/01/25 Changes end
		from atomic.fct_grp_agent_policy_r a
		join
		(
			select n_policy_sk_r,
				n_agent_sk_r,
				n_contract_template_id_r,V_TEMPLATE_NAME_R ,
				CASE
				WHEN SUBSTR(V_TEMPLATE_NAME_R, 1, 3) = 'PCH'
				THEN 0
				ELSE
				  --round(CAST(nvl(SUBSTR(V_TEMPLATE_NAME_R, INSTR(V_TEMPLATE_NAME_R, '-') + 1, INSTR(V_TEMPLATE_NAME_R, '%') - INSTR(V_TEMPLATE_NAME_R, '-') - 1),0) AS DECIMAL) / 100,2)  -- 31-01-2025 Commented as per rounding issue.
				  TO_NUMBER(nvl(SUBSTR(V_TEMPLATE_NAME_R, INSTR(V_TEMPLATE_NAME_R, '-') + 1, INSTR(V_TEMPLATE_NAME_R, '%') - INSTR(V_TEMPLATE_NAME_R, '-') - 1),0)) / 100  -- 31-01-2025 added as per rounding issue.
				END AS N_LAST_RATE_R
			from atomic.dim_grp_agent_contract_tmplt_r
			where  UPPER(V_TEMPLATE_NAME_R) <> 'PCW00' and v_active_status_r = 'Y'
			group by n_policy_sk_r, n_agent_sk_r, n_contract_template_id_r, V_TEMPLATE_NAME_R
		) b
		on 			a.n_policy_sk_r=b.n_policy_sk_r
			and 	a.n_agent_sk_r=b.n_agent_sk_r
		join atomic.dim_grp_arrangement_r c
			on 	a.N_ARRANGEMENT_CODE_R =c.N_ARRANGEMENT_ID_R
			and b.n_contract_template_id_r =c.N_TEMPLATE_ID_R
		join atomic.dim_grp_agent_directory_r ad
			on 	b.n_agent_sk_r = ad.n_agent_sk_r
			and ad.v_active_status_r = 'Y'
		left join RPT_SPLIT_PERCENTAGE_FIRST
			on a.n_agent_policy_id_r = RPT_SPLIT_PERCENTAGE_FIRST.n_agent_policy_id_r
		left join RPT_SPLIT_PERCENTAGE_SECOND
			on a.n_agent_policy_id_r = RPT_SPLIT_PERCENTAGE_SECOND.n_agent_policy_id_r
		where
		sysdate between a.d_start_date_r and NVL(a.d_end_date_r,sysdate)
		and ad.v_agent_number_r <> '273286-0001'
		and ad.v_agent_number_r like '%-0000'
		and a.d_delete_date_r is null
		and
		/*UPPER(trim(a.V_COMMISSION_TYPE_R))  in ('COMMISSION','OVERRIDE') */ --19-Aug-2024 Changes
		UPPER(trim(a.V_COMMISSION_TYPE_R)) = 'COMMISSION'  --19-Aug-2024 Changes

		--and  a.n_rpt_sort_order_r = 1 --13-jan-2023 Added OVERRIDE and n_rpt_sort_order_r filter

		--AND a.N_BATCH_ID_R = IN_BATCH_ID_R--'202109190000'
		/*
		group by
		a.n_policy_sk_r,
		a.n_agent_sk_r,
		a.V_COMMISSION_TYPE_R,
		a.n_agent_policy_id_r*/
	)   /* Commented n_rpt_sort_order_r filter and group by on 20-Jan-2023 Erica changes*/
	--select * from RPT_PRIMARY_INDICATOR;    p

	-- CTE FUNCTION
	, RPT_TOTAL_AGENTS as
	(
		select count(a.n_agent_sk_r) as N_RPT_TOTAL_AGENTS_R,
		a.n_policy_sk_r
		from atomic.fct_grp_agent_policy_r a
		join
		(
			select n_policy_sk_r,
			n_agent_sk_r
			from atomic.dim_grp_agent_contract_tmplt_r
			where  UPPER(V_TEMPLATE_NAME_R) <> 'PCW00' and v_active_status_r = 'Y'
			group by n_policy_sk_r, n_agent_sk_r
		) b
		on a.n_policy_sk_r=b.n_policy_sk_r
			and a.n_agent_sk_r=b.n_agent_sk_r
		join
		(
			select n_policy_sk_r,
			n_agent_sk_r,
			n_contract_template_id_r
			from atomic.dim_grp_agent_contract_tmplt_r
			where  UPPER(V_TEMPLATE_NAME_R) <> 'PCW00' and v_active_status_r = 'Y'
			group by n_policy_sk_r, N_AGENT_SK_R, n_contract_template_id_r
		) b1 -- 02-Dec-2022 alias name changed from b to b1 as 19c not supporting
		on 	a.n_policy_sk_r=b.n_policy_sk_r
			and a.n_agent_sk_r=b.n_agent_sk_r
		join atomic.dim_grp_arrangement_r c
			on a.N_ARRANGEMENT_CODE_R =c.N_ARRANGEMENT_ID_R
		--and b.n_contract_template_id_r =c.N_TEMPLATE_ID_R
			and b1.n_contract_template_id_r =c.N_TEMPLATE_ID_R-- 02-Dec-2022 alias name changed from b to b1 as 19c not supporting
		join atomic.dim_grp_agent_directory_r ad
			on b.n_agent_sk_r = ad.n_agent_sk_r
			and ad.v_active_status_r = 'Y'
		where
		sysdate between a.d_start_date_r and NVL(a.d_end_date_r,sysdate)
		and  a.d_delete_date_r is null--04-Jan-2023 changes
		and
		ad.v_agent_number_r <> '273286-0001'
		and ad.v_agent_number_r like '%-0000'
		and
		/*UPPER(trim(a.V_COMMISSION_TYPE_R))  in ('COMMISSION','OVERRIDE') */ --19-Aug-2024 Changes
		UPPER(trim(a.V_COMMISSION_TYPE_R)) = 'COMMISSION'  --19-Aug-2024 Changes
		--AND a.N_BATCH_ID_R = IN_BATCH_ID_R--'202109190000'
		group by a.n_policy_sk_r
		--select * from RPT_TOTAL_AGENTS;   t
	)

	-- Main Select Query
	select
	z.n_agent_sk_r ,
	z.n_policy_billgroup_sk_r,
	z.n_policy_sk_r ,
	--z.n_party_sk_r,
	--z.v_prdcr_agent_id_r ,
	--z.n_policy_billgroup_id_r ,
	--z.v_policy_id_r ,
	--z.n_customer_number_r ,
	z.n_is_split_agent_r ,
	z.n_split_percentage_r ,
	z.n_arrangement_code_r ,
	z.d_start_date_r ,
	z.d_end_date_r ,
	z.n_split_with_r ,
	z.d_insert_date_r ,
	z.d_delete_date_r ,
	z.v_commission_type_r ,
	z.n_dc_arrangement_code_r ,
	z.v_subject_area_type_r ,
	z.t_event_timestamp_r ,
	z.v_source_system_name_r ,
	z.FIC_MIS_DATE_R ,
	IN_BATCH_ID_R,
	--z.N_BATCH_ID_R ,
	--z.N_SEQUENCE_NUMBER_R ,
	NVL(LN_SEQUENCE_NUMBER_R,0)+ROWNUM,
	LD_SYSDATE,--z.T_CREATION_DATE_R ,
	LD_SYSDATE,--z.T_LAST_MODIFIED_DATE_R ,
	'ODI',--z.V_CREATED_BY_R ,
	'ODI',--z.V_LAST_MODIFIED_BY_R,
	--z.JSON_FILENAME ,
	z.D_RPT_START_DATE_R ,
	z.D_RPT_END_DATE_R ,
	p.N_RPT_PRIMARY_INDICATOR_R ,
	z.V_SPECIAL_HANDLING_5500_IND_R ,
	NVL(t.N_RPT_TOTAL_AGENTS_R,0) as N_RPT_TOTAL_AGENTS_R ,
	z.N_RPT_SORT_ORDER_R,
	z.F_PHYSICAL_DELETE_R ,
	z.V_CHANGE_REASON_R ,
	--z.V_ACTIVE_STATUS_R,
	 CASE WHEN UPPER(z.V_COMMISSION_TYPE_R)='ADMIN'
	 then 0 ELSE NVL((case when y.final_result_1 is null then x.final_result_2 else y.final_result_1 end ),
	0) END as N_RPT_SPLIT_PERCENTAGE_R,
	y.final_result_1,
	x.final_result_2,
	z.n_agent_policy_id_r,
	' ' as v_delete_by_r,
	CASE

		WHEN substr(p.V_TEMPLATE_NAME_R,1,4) ='PCHI' THEN 'PCHI'
		WHEN  substr(p.V_TEMPLATE_NAME_R,1,3) ='PCH' THEN 'PCH'
		WHEN  substr(p.V_TEMPLATE_NAME_R,1,3) ='PCO' THEN '63'
		WHEN  SUBSTR(v_template_name_r, -1) ='%' THEN SUBSTR(p.V_TEMPLATE_NAME_R,3,2)
		WHEN  LENGTH(p.V_TEMPLATE_NAME_R) =4 THEN SUBSTR(p.V_TEMPLATE_NAME_R,3,2)

	ELSE p.V_TEMPLATE_NAME_R
	END as V_TEMPLATE_NAME_R,
	CASE
    WHEN SUBSTR(p.V_TEMPLATE_NAME_R, 1, 3) = 'PCH' THEN
      0
    ELSE
      --round(CAST(nvl(SUBSTR(p.V_TEMPLATE_NAME_R, INSTR(p.V_TEMPLATE_NAME_R, '-') + 1, INSTR(p.V_TEMPLATE_NAME_R, '%') - INSTR(p.V_TEMPLATE_NAME_R, '-') - 1),0) AS DECIMAL) / 100,2)-- 31-01-2025 COMMNETED
       TO_NUMBER(nvl(SUBSTR(p.V_TEMPLATE_NAME_R, INSTR(p.V_TEMPLATE_NAME_R, '-') + 1, INSTR(p.V_TEMPLATE_NAME_R, '%') - INSTR(p.V_TEMPLATE_NAME_R, '-') - 1),0)  / 100)  -- 31-01-2025 ADDED
    END AS N_LAST_RATE_R ,
    -- 28-01-2025 change start
    p.V_TEMPLATE_NAME_R  V_TEMPLATE_NAME_R_1
    -- 28-01-2025 changend
	from atomic.fct_grp_agent_policy_r z
	left join RPT_SPLIT_PERCENTAGE_FIRST y
		on z.n_policy_sk_r=y.n_policy_sk_r
		and z.n_agent_sk_r=y.n_agent_sk_r
		and z.V_COMMISSION_TYPE_R = y.V_COMMISSION_TYPE_R
		and z.n_agent_policy_id_r=y.n_agent_policy_id_r
		--AND  z.N_BATCH_ID_R =IN_BATCH_ID_R
	left join RPT_SPLIT_PERCENTAGE_SECOND x
		on z.n_policy_sk_r=x.n_policy_sk_r

		and z.n_agent_sk_r=x.n_agent_sk_r
		and z.V_COMMISSION_TYPE_R = x.V_COMMISSION_TYPE_R
		and z.n_agent_policy_id_r=x.n_agent_policy_id_r
		--and  Z.N_BATCH_ID_R =IN_BATCH_ID_R
	left join RPT_PRIMARY_INDICATOR p
		on z.n_policy_sk_r=p.n_policy_sk_r
		and z.n_agent_sk_r=p.n_agent_sk_r
		and z.V_COMMISSION_TYPE_R = p.V_COMMISSION_TYPE_R
		and z.n_agent_policy_id_r=p.n_agent_policy_id_r
		--and  Z.N_BATCH_ID_R =IN_BATCH_ID_R
	left join RPT_TOTAL_AGENTS t
		on z.n_policy_sk_r=t.n_policy_sk_r
	left join atomic.dim_grp_policy_dir_r p
		on z.n_policy_sk_r = p.n_policy_sk_r
		and p.v_active_status_r = 'Y'
	where z.d_delete_date_r  is null
	--and  Z.N_BATCH_ID_R =IN_BATCH_ID_R
	and sysdate between z.d_start_date_r and NVL(z.d_end_date_r,sysdate)
	and
	 CASE
		WHEN UPPER(z.V_COMMISSION_TYPE_R)='ADMIN'
		then 0
		ELSE NVL((case when y.final_result_1 is null then x.final_result_2 else y.final_result_1 end ),0)
		END <> 0
	;
	--and p.v_policy_number_r = 'G159131';

	COMMIT;

	--Start	: 18th May:: Added New Chnages as part of Kill/Fill Sales report data availibity

		-- DROP TABLE IF EXSISTS ; This table should not exsists as old table will be renamed to stage post data swap.
		BEGIN
			EXECUTE IMMEDIATE 'DROP TABLE FCT_GRP_AGENT_POLICY_R_LOOKUP_OLD PURGE';
		EXCEPTION
			WHEN OTHERS THEN NULL;
		END;

		-- RENAME MAIN TABLE TO OLD ; THEN RENAME STAGE TABLE TO MAIN TABLE ; THEN RENAME OLD TABLE TO STAGE
		EXECUTE IMMEDIATE 'ALTER TABLE FCT_GRP_AGENT_POLICY_R_LOOKUP 		RENAME TO FCT_GRP_AGENT_POLICY_R_LOOKUP_OLD';
		EXECUTE IMMEDIATE 'ALTER TABLE FCT_GRP_AGENT_POLICY_R_LOOKUP_STG 	RENAME TO FCT_GRP_AGENT_POLICY_R_LOOKUP';
		EXECUTE IMMEDIATE 'ALTER TABLE FCT_GRP_AGENT_POLICY_R_LOOKUP_OLD 	RENAME TO FCT_GRP_AGENT_POLICY_R_LOOKUP_STG';

	--End	: 18th May:: Added New Chnages as part of Kill/Fill Sales report data availibity

	COMMIT;

	OUT_LOAD_STATUS:='SUCCESS';
	EXCEPTION
	WHEN OTHERS THEN
	LC_SQLCODE:=SQLCODE;
	LC_SQLERRM:=SUBSTR(SQLERRM,1,4000);
	OUT_LOAD_STATUS:=LC_SQLCODE||'-'||LC_SQLERRM;
	DBMS_OUTPUT.PUT_LINE('PRC_LOAD_FCT_GRP_AGENT_POLICY_R_LOOKUP  EXCEPTION WITH ERROR CODE AS '
				 || SQLCODE
				 || ' '
				 || SQLERRM
				 || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
				 ||'PRC_LOAD_FCT_GRP_AGENT_POLICY_R_LOOKUP'
				 ||';');


    RAISE_APPLICATION_ERROR(-20001,'Error in PKG_LOAD_GRP_TABLES.PRC_LOAD_FCT_GRP_AGENT_POLICY_R_LOOKUP:->
    Error Code:'||SQLCODE||',Error message:'||SUBSTR(SQLERRM,1,4000));

	end PRC_LOAD_FCT_GRP_AGENT_POLICY_R_LOOKUP;


	PROCEDURE PRC_LOAD_FCT_GRP_POLICY_R_UW_NEEDED(
		IN_BATCH_ID_R        IN NUMBER,
		OUT_LOAD_STATUS      OUT VARCHAR2
		)
	IS
	LD_SYSDATE DATE :=SYSDATE;
	LC_SQLCODE VARCHAR2(4000);
	LC_SQLERRM VARCHAR2(4000);
	LN_SEQUENCE_NUMBER_R NUMBER;
	LN_IN_BATCH_ID_R NUMBER:=IN_BATCH_ID_R;
	LN_LOAD_RUN_ID_R NUMBER;
	N_COUNT NUMBER;
	ld_cycle_date_r DATE;
	uw_cycle_date_r DATE;
	BEGIN

		IF LN_IN_BATCH_ID_R IS NULL THEN
		  OUT_LOAD_STATUS:='a) BatchID(IN_BATCH_ID) is null hence terminating the program';
		 RAISE_APPLICATION_ERROR(-20001,'a) BatchID(IN_BATCH_ID) is null hence terminating the program');
		END IF;

	/*
	SELECT   COUNT(1)
		  INTO ln_load_run_id_r
	FROM ATOMIC.PRCS_JOB_LOG_R
	WHERE N_BATCH_ID_R =IN_BATCH_ID_R
	AND V_JOB_NAME_R='PKG_GRP_LOAD_FCT_GRP_POLICY_R_UW_NEEDED';*/


	--BEGIN
	--execute immediate 'TRUNCATE TABLE ATOMIC.FCT_GRP_POLICY_R_UW_NEEDED PURGE SNAPSHOT LOG';
	--END;

	begin

	select
	 D_CALENDAR_DATE_R
	 into ld_cycle_date_r
	 from
	(SELECT  D_CALENDAR_DATE_R, RANK() OVER (ORDER BY D_CALENDAR_DATE_R DESC) DATE_RANK from ATOMIC.DIM_TIME_R
	where
	--V_END_OF_FISCAL_MONTH_IND_R = 'Y' and D_CALENDAR_DATE_R < ADD_MONTHS(TO_DATE(SUBSTR(P_N_BATCH_ID_R, 1, 8), 'YYYYMMDD'),1)
	V_END_OF_FISCAL_MONTH_IND_R = 'Y' and D_CALENDAR_DATE_R < ADD_MONTHS(TO_DATE(SUBSTR(IN_BATCH_ID_R, 1, 6), 'YYYYMM'),1)
	--need added for Incre testing 06-Jun-2022 since we are passing batchid as 202204 Apr-2022
	)
	where DATE_RANK =1
	;
	select
	 max(CAST(T_CREATION_DATE_R AS DATE))
	 into uw_cycle_date_r
	 from stg_uw_needed_r ;
	select count(*) into n_count from ATOMIC.FCT_GRP_POLICY_R_UW_NEEDED  where d_cycle_Date_r=ld_cycle_date_r;
	--DBMS_OUTPUT.PUT_LINE(n_count);
	end;

	if n_count<>0 then delete from ATOMIC.FCT_GRP_POLICY_R_UW_NEEDED where d_cycle_Date_r=ld_cycle_date_r;
	commit;
	end if;

	delete from  ATOMIC.FCT_GRP_POLICY_R_UW_NEEDED where d_cycle_Date_r<(add_months(ld_cycle_Date_r,-5));
	commit;

	INSERT /*+APPEND_VALUES*/ INTO ATOMIC.FCT_GRP_POLICY_R_UW_NEEDED
	(
	D_UW_WORK_MONTH_R
	,V_UW_NEEDED_RENEWAL_STATUS_R
	,N_UW_NEEDED_PERCENT_R
	,N_UW_REQUESTED_PERCENT_R
	,V_UW_NEEDED_UNDERWRITER_NAME_R
	,V_UW_NEEDED_COMMENTS_R
	,D_UW_NEXT_RENEWAL_DATE_R
	,V_UW_TRK_NEEDED_RENEW_STATUS_R
	,N_UW_TRK_NEEDED_PERCENT_R
	,N_UW_TRK_REQUESTED_PERCENT_R
	,V_UW_TRK_NEEDED_UW_NAME_R
	,V_UW_TRK_NEEDED_COMMENTS_R
	,D_UW_TRK_NEXT_RENEWAL_DATE_R
	,N_POLICY_SK_R
	,N_VERSION_NUMBER_R
	,V_POLICY_NUMBER_R
	,N_SEQUENCE_NUMBER_R
	,T_CREATION_DATE_R
	,V_CREATED_BY_R
	,T_LAST_MODIFIED_DATE_R
	,V_LAST_MODIFIED_BY_R
	,N_BATCH_ID_R
	,D_CYCLE_DATE_R
	,D_UW_CYCLE_DATE_R
	)
	select
	NVL(tbl_name2.D_UW_WORK_MONTH_R,tbl_name4.D_UW_WORK_MONTH_R) AS  D_UW_WORK_MONTH_R
	,NVL(tbl_name2.V_UW_NEEDED_RENEWAL_STATUS_R,tbl_name4.V_UW_NEEDED_RENEWAL_STATUS_R) AS  V_UW_NEEDED_RENEWAL_STATUS_R
	,NVL(tbl_name2.N_UW_NEEDED_PERCENT_R,tbl_name4.N_UW_NEEDED_PERCENT_R) AS  N_UW_NEEDED_PERCENT_R
	,NVL(tbl_name2.N_UW_REQUESTED_PERCENT_R,tbl_name4.N_UW_REQUESTED_PERCENT_R) AS  N_UW_REQUESTED_PERCENT_R
	,NVL(tbl_name2.V_UW_NEEDED_UNDERWRITER_NAME_R,tbl_name4.V_UW_NEEDED_UNDERWRITER_NAME_R) AS  V_UW_NEEDED_UNDERWRITER_NAME_R
	,NVL(tbl_name2.V_UW_NEEDED_COMMENTS_R,tbl_name4.V_UW_NEEDED_COMMENTS_R) AS  V_UW_NEEDED_COMMENTS_R
	,NVL(tbl_name2.D_UW_NEXT_RENEWAL_DATE_R,tbl_name4.D_UW_NEXT_RENEWAL_DATE_R) AS  D_UW_NEXT_RENEWAL_DATE_R
	,CASE WHEN tbl_name1.d_calculated_expiry_date_r=tbl_name2.D_UW_NEXT_RENEWAL_DATE_R THEN    tbl_name2.V_UW_NEEDED_RENEWAL_STATUS_R END AS V_UW_TRK_NEEDED_RENEW_STATUS_R
	,CASE WHEN tbl_name1.d_calculated_expiry_date_r=tbl_name2.D_UW_NEXT_RENEWAL_DATE_R THEN    tbl_name2.N_UW_NEEDED_PERCENT_R  END AS  N_UW_TRK_NEEDED_PERCENT_R
	,CASE WHEN tbl_name1.d_calculated_expiry_date_r=tbl_name2.D_UW_NEXT_RENEWAL_DATE_R THEN    tbl_name2.N_UW_REQUESTED_PERCENT_R  END AS  N_UW_TRK_REQUESTED_PERCENT_R
	,CASE WHEN tbl_name1.d_calculated_expiry_date_r=tbl_name2.D_UW_NEXT_RENEWAL_DATE_R THEN    tbl_name2.V_UW_NEEDED_UNDERWRITER_NAME_R  END AS  V_UW_TRK_NEEDED_UW_NAME_R
	,CASE WHEN tbl_name1.d_calculated_expiry_date_r=tbl_name2.D_UW_NEXT_RENEWAL_DATE_R THEN    tbl_name2.V_UW_NEEDED_COMMENTS_R END AS  V_UW_TRK_NEEDED_COMMENTS_R
	,CASE WHEN tbl_name1.d_calculated_expiry_date_r=tbl_name2.D_UW_NEXT_RENEWAL_DATE_R THEN    tbl_name2.D_UW_NEXT_RENEWAL_DATE_R  END AS  D_UW_TRK_NEXT_RENEWAL_DATE_R
	,TBL_NAME1.N_POLICY_SK_R
	,TBL_NAME1.N_VERSION_NUMBER_R
	,TBL_NAME1.V_POLICY_NUMBER_R
	,ROWNUM N_SEQUENCE_NUMBER_R            --NOT NULL
	,LD_SYSDATE T_CREATION_DATE_R              							--NOT NULL
	,'ODI' V_CREATED_BY_R                 								--NOT NULL
	,LD_SYSDATE T_LAST_MODIFIED_DATE_R         							--NOT NULL
	,'ODI' V_LAST_MODIFIED_BY_R           								--NOT NULL
	,IN_BATCH_ID_R
	,ld_cycle_date_r
	,uw_cycle_date_r
	FROM atomic.fct_grp_policy_r tbl_name1
	left JOIN
	(SELECT N_POLICY_SK_R
	--,V_ORIG_LOB_R
	,V_POLICY_SUFFIX_R
	--,V_ORIG_POLICY_NUMBER_R
	,V_POLICY_NUMBER_R
	,N_SOURCE_SYSTEM_KEY_R
	,n_policy_version_number_r
	,v_policy_prefix_r
	FROM ATOMIC.DIM_GRP_POLICY_DIR_R
	--WHERE V_ACTIVE_STATUS_R IN('Y')-- AND V_SOURCE_SYSTEM_NAME_R='PACS'
	GROUP BY
	N_POLICY_SK_R
	,N_SOURCE_SYSTEM_KEY_R
	--,V_ORIG_POLICY_NUMBER_R
	--,V_ORIG_LOB_R
	,V_POLICY_NUMBER_R
	,V_POLICY_SUFFIX_R
	,V_POLICY_PREFIX_R,
	n_policy_version_number_r)tbl_name3
	on tbl_name3.N_POLICY_SK_R=tbl_name1.N_POLICY_SK_R
	and tbl_name3.n_policy_version_number_r = tbl_name1.n_version_number_r
	and NVL(TBL_NAME3.N_SOURCE_SYSTEM_KEY_R,-1) = NVL(TBL_NAME1.N_SOURCE_SYSTEM_KEY_R,-1)
	AND tbl_name3.V_POLICY_NUMBER_R=tbl_name1.V_POLICY_NUMBER_R
	LEFT JOIN ATOMIC.VW_DIM_GRP_POLICY_DIR_R_POLICY_PREFIX_BRIDGE_MV POLICY_PREFIX
	ON tbl_name1.V_POLICY_NUMBER_R = POLICY_PREFIX.V_POLICY_NUMBER_R
	left join atomic.stg_uw_needed_r tbl_name2
	ON POLICY_PREFIX.OLD_V_POLICY_PREFIX_R = tbl_name2.V_POLICY_PREFIX_R
	AND ltrim(POLICY_PREFIX.V_POLICY_SUFFIX_R, '0') = ltrim(TBL_NAME2.V_POLICY_SUFFIX_R, '0')
	left join atomic.stg_uw_needed_r tbl_name4
	ON tbl_name4.V_POLICY_PREFIX_R =( case when tbl_name3.V_POLICY_PREFIX_R = 'MAL'  then 'G' else tbl_name3.V_POLICY_PREFIX_R  end)
	--tbl_name2.v_policy_suffix_r=tbl_name3.V_POLICY_SUFFIX_R;
	and ltrim(tbl_name4.V_POLICY_SUFFIX_R, '0') = ltrim(tbl_name3.V_POLICY_SUFFIX_R, '0');
	--*/;

	DBMS_STATS.GATHER_TABLE_STATS('ATOMIC','FCT_GRP_POLICY_R_UW_NEEDED');--31-Jul-2024 changes
	COMMIT;
	OUT_LOAD_STATUS:='SUCCESS';
	EXCEPTION
	WHEN OTHERS THEN
	LC_SQLCODE:=SQLCODE;
	LC_SQLERRM:=SUBSTR(SQLERRM,1,4000);
	OUT_LOAD_STATUS:=LC_SQLCODE||'-'||LC_SQLERRM;
	DBMS_OUTPUT.PUT_LINE('PRC_LOAD_FCT_GRP_POLICY_R_UW_NEEDED  EXCEPTION WITH ERROR CODE AS '
				 || SQLCODE
				 || ' '
				 || SQLERRM
				 || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
				 ||'PRC_LOAD_FCT_GRP_POLICY_R_UW_NEEDED'
				 ||';');


    RAISE_APPLICATION_ERROR(-20001,'Error in PKG_LOAD_GRP_TABLES.PRC_LOAD_FCT_GRP_POLICY_R_UW_NEEDED:->
    Error Code:'||SQLCODE||',Error message:'||SUBSTR(SQLERRM,1,4000));

	end PRC_LOAD_FCT_GRP_POLICY_R_UW_NEEDED;


	END PKG_LOAD_GRP_TABLES;

