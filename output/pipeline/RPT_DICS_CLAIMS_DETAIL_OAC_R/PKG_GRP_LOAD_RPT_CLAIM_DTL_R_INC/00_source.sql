

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ATOMIC"."PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC"
as
/***********************************************************************
  Purpose:  This package body contains procedures which loads data into RPT_CLAIM_DTL_R
  Used MV's :
             FCT_GRP_POLICY_R_MV_SSL
             MVW_PRODUCT_SK_LOOKUP_MIN_MV_SSL
             CLAIM_ACTIVITY_DATE_MV_TBL
             VW_DIM_GRP_CLAIM_PRIOR_STATUS_R_MV_SSL
             DIM_GRP_NURSE_CERT_R_MV_SSL
             DIM_GRP_MEDICAL_DIAGNOSIS_R_MV_SSL
             DIM_GRP_BUSOBJ_AUDIT_R_MAX_RCV_MV_SSL
             FCT_GRP_POLICY_R_LTDPOLIND_MV_SSL
             FCT_CLAIM_PAYMENT_DETAIL_R_PMNT_MV_SSL
			 RPT_CLAIM_DTL_R_totbenperdys_mv_ssl--added on 30-Jan-2024
			 RPT_CLAIM_DTL_R_curbenperdys_mv_ssl--added on 30-Jan-2024
			 RPT_CLAIM_DTL_R_OFFSET_MV_SSL--added on 31-Jan-2024
  Used Tables : dim_grp_claim_dir_r
                dim_grp_claim_coverage_r
                dim_grp_claim_coverage_group_r
                DIM_CLAIM_STATUS_DESC_R
                dim_grp_policy_dir_r
                dim_grp_claim_detail_r
                dim_employee_r
                FCT_CLAIM_SOCIALSECURITY_INC_R
                dim_grp_product_r
                FCT_GRP_WORKSHEET
                DIM_GRP_CLAIM_ELIGIBILITY_R
                dim_grp_claim_event_dir_r
                dim_grp_claim_event_r
                DIM_GRP_EEOC_R
                DIM_GRP_REF_TIER_R
                CLAIM_TIER_WFAM_MV_TBL
                DIM_GRP_CLAIM_DETAIL_SUBGROUP_LOOKUP
				FCT_BENEFIT_PAYMENT_R --18-Jan-2024
				DIM_GRP_VOCREHAB_R    --26-Jan-2024
  Pkg runtime on 13/Dec23- 2400 seconds with mv refresh
  Pkg runtime on 13/Dec23- 989 seconds without mv refresh

  Author     Date     Description
  ---------- -------- -------------------------------------------------
  VGireesh   10/11/23 Initial Creation
  VGireesh   04/01/24 Added table gather stats
  VGireesh   11/01/24 Added D_WORKSHEET_END_DATE_R  ,D_WORKSHEET_START_DATE_R
  VGireesh   18/01/24 Added column v_claim_ach_payment_ind_r and function get_v_claim_ach_payment_ind_r and below changes
                      a.	N: replace n.n_claim_coverage_group_sk_r = n.n_claim_coverage_group_sk_r with and n.n_claim_coverage_group_sk_r = g.n_claim_coverage_group_sk_r
                      b.	M: replace and m.n_claim_coverage_sk_r = m.n_claim_coverage_sk_r with and m.n_claim_coverage_sk_r = b.n_claim_coverage_sk_r
  VGireesh   18/01/24 Added procedure prc_rebuild_indexes
  VGireesh   23/01/24 Added columns V_SOURCE_SYSTEM_NAME_R ,N_CURR_BENEFIT_PERIOD_DAYS_R ,N_TOTAL_BENEFIT_PERIOD_DAYS_R
  VGireesh   23/01/24 Closed REF Cursor
  VGireesh   26/01/24 a.Remap D_EARLIEST_SERVICE_PERIOD_TO_R to PAYMENT_DATES.MOST_RECENT_SERVICE_PERIOD_TO_DATE
                      b.Remap D_EARLIEST_SERVICE_PERIOD_FROM_R to PAYMENT_DATES.MOST_RECENT_SERVICE_PERIOD_FROM_DATE
					  V_EXTENDED_DURATION_IND_R        - Derivation added
					  V_TURNAROUND_RANGE_R             - Derivation added
					  V_ANY_OCC_PERIOD_IND_R           - Derivation added
					  V_ANY_OCC_PERIOD_R               - Derivation added
					  V_ANY_OCC_OWN_OCC_IND_R          - Derivation added
					  V_OWN_OCC_PERIOD_R               - Derivation added
					  V_OWN_OCC_PERIOD_IND_R           - Derivation added
					  V_CLAIM_STATUS_CATEGORY_R        - Derivation added
					  D_PRD_DAYS_REMAINING_R           - Derivation added
					  V_RECOVERY_EXPECTATIONS_r        - Derivation added
					  V_VOC_REHAB_STATUS_R             - Derivation added
					  V_VOC_REHAB_MGR_NAME_R           - Derivation added
					  V_VOC_REHAB_SPECIALIST_R         - Derivation added
					  V_VOC_REHAB_OUTCOME_R            - Derivation added
					  V_VOC_REHAB_ACTIVE_STATUS_R      - Derivation added
					  D_TSA_DATE_R                     - Derivation added
					  N_BASIC_INSURED_SALARY_R         - New Column added
					  V_BASIC_INSURED_SALARY_IND_R     - New Column added
  VGireesh   30/01/24 Used MV's to fetch calculated N_CURR_BENEFIT_PERIOD_DAYS_R,N_totAL_BENEFIT_PERIOD_DAYS_R and update the the same in RPT_CLAIM_DTL_R
  VGireesh   31/01/24 Added below columns
                      n_rehab_offset_amt_088_r
                      n_rehab_offset_ind_088_r
                      n_workers_comp_offset_amt_083_r
                      n_other_offset_amt_r
                      v_pfl_leave_type_r
                      v_pfl_license_number_r
  VGireesh	20/02/24 : Change v_claim_identifier_r to v_claim_number_r from claim directory
                       case when v_lob_type_r in ('LTD', 'STD', 'VPL', 'VPS') then rank() over (partition by v_claim_identifier_r order by b.N_CLAIM_CVRG_SEQUENCE_NUMBER_R desc nulls last)else 1 end rank,
  VGireesh	20/02/24 : Added columns d_closed_month_start_date_r,d_closed_month_end_date_r
  VGireesh  26/02/24 for month end  that the tables start loading data in the next month partition
                      Ex: March data on February 29th (as of 2.28).
                          27th is Feb Fisc Month End    202402  should be truncate and load in 202402 partition
                          28th is feb Fisc Month End +1 202402  should be truncate and load in 202402 partition
                          29th is Feb Fisc Month End +2 202403  should inactive records against the partition 202402 and load data in 202403 partition
  VGireesh  01/03/24   Added below changes for OAC filter performance issue
                       --,a.V_PRIVACY_INDICATOR_R                                                         V_PRIVACY_INDICATOR_R                     --01-Mar-2024 changes
                       ,NVL(UPPER(a.V_PRIVACY_INDICATOR_R),'EXTERNAL')                                                         V_PRIVACY_INDICATOR_R--01-Mar-2024 changes

                      OAC filter
					  ---------
			          CASE
                      WHEN instr('DVConsumer;BIServiceAdministrator;BIDataModelAuthor;BIConsumer;OAC-DeveloperRole;OAC-AdministratorRole;DVContentAuthor;BIDataLoadAuthor;AuthenticatedUser;BIContentAuthor' , 'OAC-SubjectAreaAccess-EmployeeClaimOnlyRole') > 0
                      THEN
                        CASE
                          WHEN upper(T3185561.V_PRIVACY_INDICATOR_R) = ('INTERNAL')
                          THEN 1
                          ELSE 0
                        END

                      WHEN instr('DVConsumer;BIServiceAdministrator;BIDataModelAuthor;BIConsumer;OAC-DeveloperRole;OAC-AdministratorRole;DVContentAuthor;BIDataLoadAuthor;AuthenticatedUser;BIContentAuthor' , 'OAC-SubjectAreaAccess-EmployeeClaimPartialUserRole') > 0
                      THEN 1
                      WHEN instr('DVConsumer;BIServiceAdministrator;BIDataModelAuthor;BIConsumer;OAC-DeveloperRole;OAC-AdministratorRole;DVContentAuthor;BIDataLoadAuthor;AuthenticatedUser;BIContentAuthor' , 'OAC-SubjectAreaAccess-EmployeeClaimPIIUserRole') > 0
                      THEN 1
                      ELSE
                        CASE
                          WHEN (NVL(upper(T3185561.V_PRIVACY_INDICATOR_R) , 'EXTERNAL')) = ('EXTERNAL')
			          	--WHEN upper(T3185561.V_PRIVACY_INDICATOR_R) = ('EXTERNAL')
                          THEN 1
                          ELSE 0
                        END
                    END = 1
  VGireesh   04/03/24 Added logic to update D_CLOSED_MONTH_START_DATE_R , D_CLOSED_MONTH_END_DATE_R,d_most_recent_medical_note_date_r,v_most_recent_medical_note_r
                      and also update happened in the cursors cur_upd_mostmed,cur_upd_mostmgmnt
  VGireesh   14/03/24 Remapped D_EARLIEST_SERVICE_PERIOD_FROM_R,EARLIEST_SERVICE_PERIOD_TO_DATE logic and commented unused cursors
  Satya 	 20/03/24 V_CODE_R and V_DESCRIPTION_R for table DIM_GRP_EEOC_R alias has been changed from t to x.
  Satya 	 20/03/24 remapped below columns from NULL
                     ,payment_dates.most_recent_service_period_from_date     D_MOST_RECENT_SERVICE_PERIOD_FROM_R
                     ,payment_dates.most_recent_service_period_to_date       D_MOST_RECENT_SERVICE_PERIOD_TO_R
  VGireesh   03/04/24 Added Parallel to rebuild index fast  parallel 16 nologging
  VGireesh   03/05/24 updated V_SALES_CLAIM_STATUS_DESC_R in RPT_CLAIM_DTL_R so that if there is no record at all in the reference/lookup table, we populate
                      V_CLAIM_STATUS_REASON_DESC_R from dim_grp_claim_detail_r?
                      If either  v_claim_status_reason_code_r or v_reason_code_r are equal to dim_claim_status_desc_r.v_claim_status_code,  then if v_new_claim_status_desc_r is not null, return v_new_claim_status_desc_r , else if V_orig_claim_status_desc_r is not null, return V_orig_claim_status_desc_r
                      Else return V_CLAIM_STATUS_REASON_DESC_R
  VGireesh   06/05/24   Changed CASE (t.v_event_cause_r) to CASE upper(t.v_event_cause_r)
                        and added "and d_claim_closed_date_r is not null" for perfromance changes
  VGireesh   17/05/24 Since the table DIM_GRP_CLAIM_DETAIL_SUBGROUP_LOOKUP  having duplicates against claim number due to fct grp policy r duplicates issue hence
                      added below condition to stop the duplicates until the underlying tables issues has been fixed
                      and q.N_SOURCE_SYSTEM_KEY_R is not null--17-May-2024 changes
  Chandra    29/05/24 nvl(b.v_claim_coverage_code_r,g.v_claim_coverage_code_r) -------nvl added at line 1442 bcoz N_TIER_NUM_R was populating Null
  VGireesh   30/05/24 added able DIM_GRP_APPEALS_R for the below columns mapping
                      D_APPEAL_RECEIVED_DATE_R
                      V_APPEAL_DENIAL_OVERTURN_TYPE_R
                      V_APPEALS_ANALYST_R
                      D_APPEAL_COMPLETED_DATE_R
                      N_APPEAL_SOURCE_VERSION_SEQ_NUMBER_R
  VGireesh   15/06/24 added COLUMNS
                            V_APPEAL_IND_R,
                            V_APPEAL_RESULT_STATUS_CODE_R,
                            D_APPEAL_RESULT_STATUS_CODE_EFF_DATE_R
                      and introduced dim_grp_claim_prior_status_r_approved_mv_ssl to fetch the above columns mapping

  Chandra    21/06/24  Added V_APPEAL_ANALYST_NAME_r,V_APPEAL_STATUS_CODE_R,V_RPT_WORKSHEET_INDICATOR_R
                                                                            N_WORKSHEET_NUMBER_R
                                                                            V_WORKSHEET_STATUS_R
                                                                            N_WORKSHEET_SEQ_NBR_OBJECTNM_R,v_coverage_type_code_r
                                                                            N_MAX_BENEFIT_R
                                                                            N_MINIMUM_BENEFIT_R

  VGireesh   24/07/24  Changes in RANK logic - from Gisha and Mereen
  Chandra    06/08/24  Added where PMNT.N_CLAIM_COVERAGE_GROUP_SK_R <> -1 in FCT_CLAIM_PAYMENT_DETAIL_R_PMNT_MV_SSL join Its a Temp Fix need to revisit.
  Chandra    16/08/24  Logic change for D_MOST_RECENT_ACTIVITY_DATE_R column
  VGireesh   19/08/24  Temp Fix and a1.T_EVENT_TIMESTAMP_R = (select max(b1.T_EVENT_TIMESTAMP_R) from DIM_GRP_CLAIM_ELIGIBILITY_R b1
  VGireesh   21/08/24  Moved the updates into another procedure PRC_GRP_UPD_RPT_CLAIM_DTL_R_COLS and commeneted UPDATE cursors and commented gather table stats
  Chandra    26/08/24  Added V_CLAIM_WELLNESS_IND_R column
  Chandra    04/09/24  Logic Chnange for column V_CLAIM_STATUS_DESC_R
  VGireesh   11/09/24  Added below columns
                      ,CAST(NULL AS VARCHAR2(1))  V_HAS_ASSOCIATED_WAIVER_IND_R--11-SEP-2024 CHANGES
                      ,CAST(NULL AS VARCHAR2(1))  V_HAS_ASSOCIATED_LTD_IND_R   --11-SEP-2024 CHANGES
  Chandra    11/09/24  Added V_CLAIM_STATUS_REASON_DESC_R column
  VGireesh   11/09/24 Added procedure prc_upd_wavier_ltd_ind_cols
                          Commented below unused procedures
                          prc_refresh_ssl_mvs
             			  get_n_curr_benefit_period_days_r
             			  get_n_total_benefit_period_days_r
 Chandra     23/09/24  Added D_CLAIM_DECISION_DATE_R,N_CLAIM_DECISION_DAYS_R,V_TURNAROUND_RANGE1_R
 Vgireesh	 30/09/24  Modified D_CLAIM_CLOSED_DATE_R as below
                        --,d.d_closure_date_r                                                              D_CLAIM_CLOSED_DATE_R	                    --On-priority
                        ,(CASE WHEN a.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP')
                               THEN g.D_DATE_CLOSED_R
                               else D.d_closure_date_r
                          end
		                 )                                                                               D_CLAIM_CLOSED_DATE_R	                    --On-priority
Vgireesh     05/10/24 Added procedure prc_upd_decision_cols
 Vgireesh    25/10/24 Commented the below CURSOR as it has been moved to the procedure
	                   cur_upd_cib_ind;
                       and intorduced global temporary table RPT_CLAIM_DTL_R_BENPERDYS_GTT
 VGireesh    31/10/24 Added below condition in the function get_n_total_benefit_period_days_r
                       AND n_total_benefit_period_days_r IS NOT NULL;--31/10/24 changes
                      Added below condition in the function get_n_curr_benefit_period_days_r
                       AND n_curr_benefit_period_days_r IS NOT NULL;--31/10/24 changes
                      Changed bulk limit to 2000 in the below cursors
					  cur_upd_tot_ben_perioddys
					  cur_upd_curr_ben_perioddys
  VGireesh   04/11/24 BenPeriod days blocks has been moved in the procedure prc_upd_wavier_ltd_ind_cols to the stand alone porcedure
                      PRC_GRP_UPD_RPT_CLAIM_DTL_R_COLS
Chandra      13/11/24 Changed the Logic for D_CLAIM_CLOSED_DATE_R
Chandra      27/11/24 changed the logic for V_CLAIM_WELLNESS_IND_R d.v_benefittype_r else null end as V_CLAIM_WELLNESS_IND_R
Rose		 21/05/25  Commented Insert to RPT_CLAIM_DTL_R and update flag = 'N' for Month End+2 Load.
Samba		 26/05/25  Added new logging Mechanism
Shashi - Delete Physical records section modification on 11th Jul 2025

--------------------------------------------------------------------------------------------------------------------------------------------------
Performance improvement Steps are added on 27th Feb 2025
				As part of Performance Tuning Adding following Query which is Combine query consisting of procedures and functions.
				Only Incremental data will be processed as part of daily execution.
					Procedures combined
					- PROCEDURE: prc_get_cur_data :  This is used as base query - only change is adding filter condition to get delta records.
					- PROCEDURE: PRC_GRP_UPD_RPT_CLAIM_DTL_R_COLS - All logic from this has been impemented in the following combined query.
					- FUNCTION: get_pacs_as_of_date_r :  This has been used as left join to the main query.
					- PROCEDURE: prc_upd_wavier_ltd_ind_cols  :  This has been used as left join to the main query.
					- PROCEDURE prc_upd_decision_cols  :  This has been used as left join to the main query.

Following are obselete and no longer to be used for processing incremental loads.
        - PROCEDURE: prc_get_cur_data
        - PROCEDURE: PRC_GRP_UPD_RPT_CLAIM_DTL_R_COLS
        - FUNCTION:  get_pacs_as_of_date_r
        - PROCEDURE: prc_upd_wavier_ltd_ind_cols
        - PROCEDURE prc_upd_decision_cols
		- PROCEDURE prc_trunc_partition
		- PROCEDURE prc_rebuild_indexes

--------------------------------------------------------------------------------------------------------------------------------------------------
Samba   08/19/25   Rebuild Local Index on Partition
Aleeta  21/11/25 changed the logic for N_CLAIM_TAXABLE_BENEFIT_PCT_R and left join as mcv for CV source system with row_number function.

***********************************************************************/
--Procedure to update prior month active flag and current month partition
PROCEDURE prc_upd_del_data
IS
ln_sqlrowcnt      NUMBER;
ln_cnt            NUMBER;
ld_first_day_date DATE;
--26-Feb-2024 changes starts
ln_fisc_current_month NUMBER;
ln_fisc_prior_month   NUMBER;
ld_fic_mis_date_2     DATE;
--26-Feb-2024 changes ends
BEGIN
    gc_trcmsg:='2.1 Entered into in prc_upd_del_data'||chr(13);
    /*START: 20-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
gc_trcmsg:='2.1 Entered into prc_upd_del_data'||chr(13);
 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
	 (
		p_job_id_r                    => gn_out_job_id,
		p_batch_id_r                  => gn_sysdt_batchid,
		p_message_type_r              => gc_message_type_r,
		p_code_location_r             => gc_updby,
		p_message_r                   => gc_trcmsg,
		p_count_type_r                => NULL,
		p_count_r                     => NULL,
		p_duration_r                  => NULL,
		p_created_by_r                => GC_JOB_NAME,
		out_prcs_job_log_message_id_r => gn_job_log_message_id_r
	);
  /*END: 20-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
    /*gc_trcmsg:=gc_trcmsg||'3.2 Get First Day Date of the current month'||chr(13);
	--Get First Day Date of the current month
    SELECT TRUNC(gd_sysdate, 'MONTH') INTO ld_first_day_date
    FROM dual;
    gc_trcmsg:=gc_trcmsg||'3.3 First Day Date of the current month is:->'||ld_first_day_date||chr(13);
	--If First Day date of current month is sysdate then delete all the data as reload is going to happen for Current , Prior and past 6 history months data
    IF TRUNC(ld_first_day_date) =TRUNC(gd_sysdate) THEN
	    --Today is first day of the current month hence Updating v_rpt_active_status_r=N against the records loaded in prior month
   	    gc_trcmsg:=gc_trcmsg||'3.4 Today is first day of the current month hence Updating v_rpt_active_status_r=N against the records loaded in prior month'||CHR(13);
        UPDATE RPT_CLAIM_DTL_R
	       SET v_rpt_active_status_r='N'
		      ,v_last_modified_by_r=gc_updby
			  ,t_last_modified_date_r=gd_sysdate
	    WHERE n_yearmonth_r = gn_prior_month;
	    ln_sqlrowcnt:=SQL%ROWCOUNT;
	    COMMIT;
   	    gc_trcmsg:=gc_trcmsg||'3.5  Updated v_rpt_active_status_r=N against the records loaded in prior month :->'||ln_sqlrowcnt||chr(13);
	ELSE
	    --Since sysdate is not first day of the current month hence data loaded in Current Month needs to be deleted but prior months data should not be touched
	    gc_trcmsg:=gc_trcmsg||'3.6 Today is not first day of the current month hence Calling procedure prc_trunc_partition to truncate current month partition from main'||chr(13);
        prc_trunc_partition;
	    gc_trcmsg:=gc_trcmsg||'3.7 Completed procedure prc_trunc_partition call from main'||chr(13);
	END IF;*/
  --26-Feb-2024 changes starts
  --Fetch Fisc Month End +2 and Fisc Current Month
  SELECT --D_CALENDAR_DATE_R,D_CALENDAR_DATE_R +1
    D_CALENDAR_DATE_R                  +2 ,
    to_number(TO_CHAR(last_day(sysdate)+1,'YYYYMM'))
  INTO ld_fic_mis_date_2 ,
    ln_fisc_current_month
  FROM ATOMIC.DIM_TIME_R D
  WHERE V_END_OF_FISCAL_MONTH_IND_R      = 'Y'
  AND TO_CHAR(D_CALENDAR_DATE_R,'YYYYMM')=TO_CHAR(sysdate,'YYYYMM');
  gc_trcmsg  :='3.2 Fisc Month End +2 Day Date of the current month is:->'||ld_fic_mis_date_2||chr(13);
  gc_trcmsg  :='3.3 Fisc Current Month of the current month is:->'||ln_fisc_current_month||chr(13);
  /*START: 20-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
  gc_trcmsg:='2.2 Fisc Month End +2 Day Date of the current month:'||ld_fic_mis_date_2 ;
   PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
	 (
		p_job_id_r                    => gn_out_job_id,
		p_batch_id_r                  => gn_sysdt_batchid,
		p_message_type_r              => gc_message_type_r,
		p_code_location_r             => gc_updby,
		p_message_r                   => gc_trcmsg,
		p_count_type_r                => NULL,
		p_count_r                     => NULL,
		p_duration_r                  => NULL,
		p_created_by_r                => GC_JOB_NAME,
		out_prcs_job_log_message_id_r => gn_job_log_message_id_r
	);
/*END: 20-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
  IF TRUNC(ld_fic_mis_date_2)            =TRUNC(sysdate) THEN
    ln_fisc_prior_month                 :=to_number(TO_CHAR(ld_fic_mis_date_2,'YYYYMM'));
    gc_trcmsg                           :=gc_trcmsg||'3.3.1 Fisc Prior Month of the current month is:->'||ln_fisc_prior_month||chr(13);
    gc_trcmsg                           :=gc_trcmsg||'3.4 Today Fisc Month End +2 '||ld_fic_mis_date_2||' hence Updating v_rpt_active_status_r=N against the records loaded in prior fisc month which is :->'||ln_fisc_prior_month||CHR(13);

/*Perf Tuning Changes : Start: Copy Current Month Partition to Next Month*/

    INSERT INTO ATOMIC.SSL_PACKAGE_LOG_TABLE(job_name,process_name, start_date, end_date)
    VALUES ('PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC','START: INSERT NEXT PARTITION RECORDS:', SYSDATE, NULL);
    COMMIT;

    ln_sqlrowcnt := 0;

    --INSERT /*+ APPEND */ INTO ATOMIC.RPT_CLAIM_DTL_R
    --SELECT /*+PARALLEL(4)*/
	/*	V_ADD_DIAG_CATEGORY_CODE_R,V_ADD_DIAG_CATEGORY_DESC_R,V_ADD_DIAGNOSIS_CODE_R,V_PRI_DIAG_CATEGORY_CODE_R,V_PRI_DIAG_CATEGORY_DESC_R
		,V_PRI_DIAGNOSIS_CODE_R,N_DIAGNOSIS_TYPE_CODE_R,V_ADD_DIAG_CODE_DESC_R,V_PRI_DIAG_CODE_DESC_R,D_LAST_PAYMENT_DATE_R,D_AGE_REDUCTION_DATE_R
		,V_CLAIM_ACH_PAYMENT_IND_R,D_BENEFIT_START_R,V_CAUSE_OF_EVENT_CODE_R,V_CAUSE_OF_EVENT_DESC_R,V_CLAIM_CLASS_ID_R,D_CLAIM_CLOSED_DATE_R
		,V_ELIGIBILITY_DECISION_R,V_ELIGIBILITY_REASON_R,N_CLAIM_COVERAGE_GROUP_SK_R,N_CLAIM_COVERAGE_SK_R,N_CLAIM_SK_R,V_CLAIM_EVENT_NUMBER_R
		,V_CLAIM_NUMBER_R,N_CLAIM_PENDING_AGE_R,N_CLAIM_TAXABLE_BENEFIT_PCT_R,N_DAYS_OPEN_R,D_DISABILITY_START_DATE_R,V_EXERTION_LEVEL_R
		,V_DURATION_INDICATOR_R,V_DURATION_PERIOD_R,D_EARLIEST_BENEFIT_PAYMENT_DATE_R,D_EARLIEST_SERVICE_PERIOD_FROM_R,D_EARLIEST_SERVICE_PERIOD_TO_R
		,V_ELIMINATION_PERIOD_R,D_EST_QUALIFYING_PERIOD_EXP_DATE_R,V_EST_SS_IND_R,V_EXTENDED_DURATION_IND_R,D_LOSS_DATE_R,D_MODIFIED_RTW_DATE_R
		,D_MOST_RECENT_SERVICE_PERIOD_FROM_R,D_MOST_RECENT_SERVICE_PERIOD_TO_R,D_NURSE_CERT_END_DATE_R,N_NURSE_CERT_SEQ_R,V_OCCUPATION_CODE_R
		,V_OCCUPATION_DESC_R,V_PFL_CHILD_GENDER_R,D_PFL_DOB_R,V_MANDATED_FAMILY_MEMBER_R,V_LEAVE_REASON_R,D_PFL_DOP_R,D_PHYS_CERT_END_DATE_R
		,D_PLAN_DUR_DATE_R,D_RETIREMENT_TERMINATION_DATE_R,D_RETURN_TO_WORK_DATE_R,V_SOCIAL_SECURITY_IND_R,V_TURNAROUND_RANGE_R,V_WAIVER_IND_R
		,D_WAIVER_STATUS_DATE_R,N_WAIVER_TERMINATION_AGE_R,D_WAIVER_TERMINATION_DATE_R,D_CLAIM_AS_OF_DATE_R,V_METHOD_R,V_METHOD_STYLE_R,V_CLAIM_IDENTIFIER_R
		,D_MOST_RECENT_ACTIVITY_DATE_R,D_CLAIM_RECEIVED_DATE_R,FIC_MIS_DATE_R,V_LTD_POLICY_IND_R,V_CLAIM_COMPANY_R,V_PRIVACY_INDICATOR_R
		,N_ANY_OCC_DAYS_REMAINING_R,D_ANY_OCC_DECISION_DATE_R,V_ANY_OCC_PERIOD_R,V_ANY_OCC_PERIOD_IND_R,D_ANY_OCC_START_DATE_R,V_ANY_OCC_OWN_OCC_IND_R
		,V_OWN_OCC_PERIOD_R,V_OWN_OCC_PERIOD_IND_R,V_CLAIM_COVERAGE_CODE_R,V_PRODUCT_LINE_DESC_R,N_COV_GRP_ID_R,V_CLAIM_COVERAGE_DESC_R
		,D_APPEAL_RECEIVED_DATE_R,V_APPEAL_DENIAL_OVERTURN_TYPE_R,V_APPEALS_ANALYST_R,D_APPEAL_COMPLETED_DATE_R,N_APPEAL_SOURCE_VERSION_SEQ_NUMBER_R
		,D_MOST_RECENT_MEDICAL_NOTE_DATE_R,V_MOST_RECENT_MEDICAL_NOTE_R,D_MOST_RECENT_MANAGEMENT_NOTE_DATE_R,V_MOST_RECENT_MGMT_NOTE_R
		,D_SS_DEP_AWARD_EFF_DATE_R,V_SS_DEPENDENT_STATUS_R,D_SS_DEP_TERM_DATE_R,V_SS_DEP_AWARD_TYPE_R,V_SS_DEP_PURSUE_IND_R,D_SS_MOST_RECENT_UPDATE_DATE_R
		,D_SS_PRIMARY_EFF_DATE_R,V_SS_STATUS_DESCRIPTION_R,D_SS_CLOSED_TERM_DATE_R,V_SS_PRIMARY_AWARD_TYPE_R,V_SS_PRIMARY_PURSUE_IND_R
		,V_SS_REJECT_REASON_CODE_R,V_SS_REJECT_REASON_R,V_CLAIM_STATUS_CATEGORY_R,V_CLAIM_STATUS_CODE_R,V_CLAIM_STATUS_DESC_R,D_CLAIM_STATUS_EFF_DATE_R
		,D_LAST_IN_STATUS_46_DATE_R,V_PRIOR_CLAIM_STATUS_CLOSURE_CODE_R,V_PRIOR_CLAIM_STATUS_CODE_R,V_SALES_CLAIM_STATUS_DESC_R,V_CURR_CLAIM_STATUS_CODE_R
		,V_CLAIM_TYPE_R,D_TIER_CREATED_DATE_R,D_WFAM_CODE_CREATED_DATE_R,V_TIER_R,V_WFAM_R,D_PRD_R,D_PRD_DAYS_REMAINING_R,V_ACCOMMODATIONS_NEEDED_R
		,V_CLINICAL_VOC_ENGAGEMENT_R,V_TIER_DESCRIPTION_R,N_TIER_NUM_R,V_RECOVERY_EXPECTATIONS_R,V_VOC_REHAB_STATUS_R,V_VOC_REHAB_MGR_NAME_R
		,V_VOC_REHAB_SPECIALIST_R,V_SERVICE_REQUESTED_OTHER_R,V_SERVICE_REQUESTED_R,V_VOC_REHAB_OUTCOME_R,V_VOC_REHAB_ACTIVE_STATUS_R,D_TSA_DATE_R
		,V_LOCATION_NUMBER_R,V_CORRESPONDENT_NAME_R,V_SUBGROUP_ADDRESSLINE1_R,V_SUBGROUP_ADDRESSLINE2_R,V_SUBGROUP_CITY_R,V_SUBGROUP_ID_R,V_SUBGROUP_NAME_R
		,V_SUBGROUP_POSTALZIP_R,V_SUBGROUP_PROVSTATE_R,V_LAST_MODIFIED_BY_R,T_CREATION_DATE_R,V_CREATED_BY_R,T_LAST_MODIFIED_DATE_R

		,ln_fisc_current_month as N_YEARMONTH_R -- NEXT MONTH VALUE USING PREVIOUS MONTH DATA

		,V_RPT_ACTIVE_STATUS_R,N_BATCH_ID_R,V_EXAMINER_ID_R,V_EXAMINER_NAME_R,D_HIRE_DATE_R,D_SS_COUNCIL_START_DATE_R,D_SS_APPEAL_END_DATE_R
		,D_SS_COURT_START_DATE_R,D_SS_COURT_APPEAL_END_DATE_R,D_SS_HEARING_START_DATE_R,D_SS_HEARING_END_DATE_R,D_SS_INIT_FILING_START_DATE_R
		,D_SS_INIT_FILING_END_DATE_R,D_SS_RECONSIDER_START_DATE_R,D_SS_RECONSIDER_END_DATE_R,V_SS_HARDSHIP_IND_R,D_WORKSHEET_START_DATE_R
		,D_WORKSHEET_END_DATE_R,V_LOB_TYPE_R,V_SOURCE_SYSTEM_NAME_R,N_CURR_BENEFIT_PERIOD_DAYS_R,N_TOTAL_BENEFIT_PERIOD_DAYS_R,N_BASIC_INSURED_SALARY_R
		,V_BASIC_INSURED_SALARY_IND_R,N_REHAB_OFFSET_AMT_088_R,V_REHAB_OFFSET_IND_088_R,N_WORKERS_COMP_OFFSET_AMT_083_R,N_OTHER_OFFSET_AMT_R
		,V_PFL_LEAVE_TYPE_R,V_PFL_LICENSE_NUMBER_R,D_CLOSED_MONTH_START_DATE_R,D_CLOSED_MONTH_END_DATE_R,V_APPEAL_IND_R,V_APPEAL_RESULT_STATUS_CODE_R
		,D_APPEAL_RESULT_STATUS_CODE_EFF_DATE_R,V_APPEAL_ANALYST_NAME_R,V_APPEAL_STATUS_CODE_R,V_RPT_WORKSHEET_INDICATOR_R,N_WORKSHEET_NUMBER_R
		,V_WORKSHEET_STATUS_R,N_WORKSHEET_SEQ_NBR_OBJECTNM_R,V_COVERAGE_TYPE_CODE_R,N_MAX_BENEFIT_R,N_MINIMUM_BENEFIT_R,V_CLAIM_WELLNESS_IND_R
		,V_HAS_ASSOCIATED_WAIVER_IND_R,V_HAS_ASSOCIATED_LTD_IND_R,V_CLAIM_STATUS_REASON_DESC_R,D_CLAIM_DECISION_DATE_R,N_CLAIM_DECISION_DAYS_R
		,V_TURNAROUND_RANGE1_R
        ,V_OVERRIDE_NAME_R
		,D_RECORD_START_DATE_R
		,D_RECORD_END_DATE_R
    FROM ATOMIC.RPT_CLAIM_DTL_R
    WHERE N_YEARMONTH_R = ln_fisc_prior_month;
    COMMIT;*/

	ln_sqlrowcnt := SQL%ROWCOUNT;

    INSERT INTO ATOMIC.SSL_PACKAGE_LOG_TABLE(job_name,process_name, start_date, end_date,SOURCE_TABLE_COUNT)
    VALUES ('PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC','END: INSERT NEXT PARTITION RECORDS:',  NULL,SYSDATE,ln_sqlrowcnt);
    COMMIT;


/*Perf Tuning Changes : End: Copy Current Month Partition to Next Month*/
	ln_sqlrowcnt := 0;

    INSERT INTO ATOMIC.SSL_PACKAGE_LOG_TABLE(job_name,process_name, start_date, end_date)
    VALUES ('PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC','START: UPDATE PREV MONTH RECORDS TO N ',  NULL,SYSDATE);
    COMMIT;

   /* UPDATE ATOMIC.RPT_CLAIM_DTL_R
	   SET v_rpt_active_status_r='N'
	      ,v_last_modified_by_r=gc_updby
	      ,t_last_modified_date_r=gd_sysdate
	WHERE n_yearmonth_r = ln_fisc_prior_month;
    ln_sqlrowcnt            :=SQL%ROWCOUNT;
    COMMIT;*/

    INSERT INTO ATOMIC.SSL_PACKAGE_LOG_TABLE(job_name,process_name, start_date, end_date,SOURCE_TABLE_COUNT)
    VALUES ('PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC','END: UPDATE PREV MONTH RECORDS TO N :',  NULL,SYSDATE,ln_sqlrowcnt);
    COMMIT;

    gc_trcmsg       :='3.5  Updated v_rpt_active_status_r=N against the records loaded in Fisc prior month :->'||ln_fisc_prior_month||' records '||ln_sqlrowcnt||chr(13);
    gc_trcmsg       :='3.6 Set gn_current_month to  ln_fisc_current_month ';
    gn_current_month:=ln_fisc_current_month;
    gc_trcmsg       :='3.7 now current month is :->'|| gn_current_month ;

  ELSE
    --If Sysdate is greater than to Fisc Month End +2 and less than last day of the present month then Current Month is next fisc month
	--Ex: if sysdate is  28-MAR-24 which is also Fisc Month end +2 and leass than current month end date 31-MAR-24 then current month 202403 becomes next fisc month which is 202404
	--partition 202404 should be truncated and reloaded
	IF TRUNC(sysdate)>trunc(ld_fic_mis_date_2) and  TRUNC(sysdate)<= trunc(last_day(sysdate)) then
       gc_trcmsg       :='3.8 Set gn_current_month to  ln_fisc_current_month ';
       gn_current_month:=ln_fisc_current_month;
       gc_trcmsg       :='3.9 now current month is :->'|| gn_current_month ;
	ELSE
       gc_trcmsg       :='3.9.1 now current month is :->'|| gn_current_month ;
	END IF;
	--Since sysdate is not fisc month end +2 hence data loaded in Current Month needs to be deleted but prior months data should not be touched
    gc_trcmsg:='3.10 Today is not fisc month end +2 of the current month hence Calling procedure prc_trunc_partition to truncate current month partition from main'||chr(13);

/*Perf Tuning Changes : Start: Delete records from the target Table if Exsists */

    -- prc_trunc_partition; -- Perf Improvement  Steps - disable truncate partition - no longer required.
	gc_trcmsg:='3.11 Completed procedure prc_trunc_partition call from main'||chr(13);
  END IF;
/*START: 20-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
  gc_trcmsg:='2.3 Fisc Current Month is- '||gn_current_month;
   PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
	 (
		p_job_id_r                    => gn_out_job_id,
		p_batch_id_r                  => gn_sysdt_batchid,
		p_message_type_r              => gc_message_type_r,
		p_code_location_r             => gc_updby,
		p_message_r                   => gc_trcmsg,
		p_count_type_r                => NULL,
		p_count_r                     => NULL,
		p_duration_r                  => NULL,
		p_created_by_r                => GC_JOB_NAME,
		out_prcs_job_log_message_id_r => gn_job_log_message_id_r
	);
/*END: 20-MAY-2025: NEW LOGGING MECHANISM CHANGES*/

		INSERT INTO ATOMIC.SSL_PACKAGE_LOG_TABLE(job_name,process_name, start_date, end_date)
		VALUES ('PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC','START: DELETE EXSISTING AND INACTIVE RECORDS', SYSDATE, NULL);
		COMMIT;

		ln_sqlrowcnt := 0;
/*START: 20-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
gt_start_time_r:= SYSTIMESTAMP;
gc_trcmsg:='2.4 - START: DELETE EXSISTING AND INACTIVE RECORDS '||chr(13);
gc_count_type_r := PKG_GRP_LOG_UTIL.gc_count_type_delete;
 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
	 (
		p_job_id_r                    => gn_out_job_id,
		p_batch_id_r                  => gn_sysdt_batchid,
		p_message_type_r              => gc_message_type_r,
		p_code_location_r             => gc_updby,
		p_message_r                   => gc_trcmsg,
		p_count_type_r                => gc_count_type_r,
		p_count_r                     => NULL,
		p_duration_r                  => NULL,
		p_created_by_r                => GC_JOB_NAME,
		out_prcs_job_log_message_id_r => gn_job_log_message_id_r
	);
/*END: 20-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
		DELETE FROM ATOMIC.RPT_CLAIM_DTL_R T
		WHERE EXISTS
		(
			SELECT 1 FROM
			(   SELECT
					 A.n_claim_sk_r
					,B.n_claim_coverage_sk_r
					,G.n_claim_coverage_group_sk_r
					/*,CASE
						WHEN v_lob_type_r in ('LTD', 'STD', 'VPL', 'VPS')
						THEN
							rank() over (partition by a.v_claim_number_r order by b.N_CLAIM_CVRG_SEQUENCE_NUMBER_R desc nulls last)
						WHEN v_lob_type_r ='WOP'
						THEN
							CASE
								WHEN g.N_CLAIM_CVRG_GRP_SRC_SYS_KEY_R IS NULL
								THEN
									CASE
										WHEN
											rank() OVER ( PARTITION BY g.n_claim_sk_r
															ORDER BY g.N_CLAIM_CVRG_GRP_SRC_SYS_KEY_R desc nulls last
															, g.N_CLAIM_CVRG_SEQUENCE_NUMBER_R desc NULLS LAST
														) = 1
										THEN 1
										ELSE 0
									END
							   ELSE 1
							END
						ELSE 1
					END RANK_VAL */  --commented By SP on 11-Jul-2025
				FROM
				(
					SELECT * FROM ATOMIC.dim_grp_claim_dir_r
					WHERE
						/*(   V_ACTIVE_STATUS_R = 'Y'
							OR
							(V_ACTIVE_STATUS_R='N' AND V_CHANGE_REASON_R = 'Physically Deleted')
						) */  -----commented By SP on 11-Jul-2025
					 t_last_modified_date_r > -- TO_DATE('20250222')
							(   SELECT max(END_DATE)
								FROM ATOMIC.SSL_PACKAGE_MILESTONE_TABLE
								WHERE JOB_NAME='PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC'
							)

				) a
				LEFT JOIN ATOMIC.dim_grp_claim_coverage_r b ON a.n_claim_sk_r = b.n_claim_sk_r --and b.v_active_status_r = 'Y'  ----Commented By SP on 11-Jul-2025
				LEFT JOIN ATOMIC.dim_grp_claim_coverage_group_r g on b.n_claim_coverage_sk_r = g.n_claim_coverage_sk_r --and g.v_active_status_r = 'Y'  ----Commented By SP on 11-Jul-2025
			) S
			WHERE --S.RANK_VAL=1
			S.n_claim_sk_r          = T.n_claim_sk_r
			AND S.n_claim_coverage_sk_r = T.n_claim_coverage_sk_r
			AND S.n_claim_coverage_group_sk_r = T.n_claim_coverage_group_sk_r
			AND T.N_YEARMONTH_R         = gn_current_month
		);


		  ln_sqlrowcnt := SQL%ROWCOUNT;
		  commit;
/*START: 20-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
gt_end_time_r:= SYSTIMESTAMP;
    gc_duration_r := EXTRACT(SECOND FROM (gt_end_time_r - gt_start_time_r)) +
                     EXTRACT(MINUTE FROM (gt_end_time_r - gt_start_time_r)) * 60 +
                     EXTRACT(HOUR FROM (gt_end_time_r - gt_start_time_r)) * 3600;

	gc_count_type_r:= PKG_GRP_LOG_UTIL.gc_count_type_delete;
    gc_trcmsg:='2.5 - END: DELETE EXSISTING AND INACTIVE RECORDS '||chr(13);
	 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
	 (
		p_job_id_r                    => gn_out_job_id,
		p_batch_id_r                  => gn_sysdt_batchid,
		p_message_type_r              => gc_message_type_r,
		p_code_location_r             => gc_updby,
		p_message_r                   => gc_trcmsg,
		p_count_type_r                => gc_count_type_r,
		p_count_r                     => ln_sqlrowcnt,
		p_duration_r                  => gc_duration_r,
		p_created_by_r                => GC_JOB_NAME,
		out_prcs_job_log_message_id_r => gn_job_log_message_id_r
	);
/*END: 20-MAY-2025: NEW LOGGING MECHANISM CHANGES*/

			INSERT INTO ATOMIC.SSL_PACKAGE_LOG_TABLE(job_name,process_name, start_date, end_date,SOURCE_TABLE_COUNT)
			VALUES ('PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC','END: DELETE EXSISTING AND INACTIVE RECORDS:',  NULL,SYSDATE,ln_sqlrowcnt);
			COMMIT;


  --26-Feb-2024 changes ends
	--gc_trcmsg:=gc_trcmsg||'3.12 Exit from in prc_upd_del_data'||chr(13);
   --   gc_trcmsg:='3.12 Exit from in prc_upd_del_data'||chr(13);
/*START: 20-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
  gc_trcmsg:='2.6 Exit from prc_upd_del_data'||chr(13);
		 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
	 (
		p_job_id_r                    => gn_out_job_id,
		p_batch_id_r                  => gn_sysdt_batchid,
		p_message_type_r              => gc_message_type_r,
		p_code_location_r             => gc_updby,
		p_message_r                   => gc_trcmsg,
		p_count_type_r                => NULL,
		p_count_r                     => NULL,
		p_duration_r                  => NULL,
		p_created_by_r                => GC_JOB_NAME,
		out_prcs_job_log_message_id_r => gn_job_log_message_id_r
	);
/*END: 20-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
EXCEPTION
WHEN OTHERS THEN
    gc_errmsg:=SUBSTR(SQLERRM,1,4000);
	gc_trcmsg:='2.z Error in prc_upd_del_data - '||gc_errmsg;
   /*START: 20-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
        pkg_grp_log_util.prc_update_log_message_r
    (
        n_prcs_job_log_message_id_r => gn_job_log_message_id_r,
        p_err_msg => gc_trcmsg
    );
	/*END: 20-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
    pkg_grp_log_util.prc_update_log
      (
        gn_out_job_id                 --p_job_id
        ,gc_error_status              --p_job_status
        ,gc_errmsg                    --p_err_msg
        ,gc_trcmsg                    --p_trc_msg
        ,gc_updby                     --p_log_util_called_by_r
      );
    RAISE;

END prc_upd_del_data;
--Procedure to truncate the YEARMONTH partition
PROCEDURE prc_trunc_partition
AS
lc_tbl VARCHAR2(30):='RPT_CLAIM_DTL_R';
LC_REBUILD_INDEX VARCHAR2(300);
BEGIN
   gc_trcmsg:=gc_trcmsg||'3.7.1 Entered into prc_trunc_partition :->'||'ALTER TABLE '||lc_tbl||' TRUNCATE PARTITION '||'PART_'||lc_tbl||'_'||gn_current_month||CHR(13);
   execute immediate 'ALTER TABLE '||lc_tbl||' TRUNCATE PARTITION '||'PART_'||lc_tbl||'_'||gn_current_month;
  gc_trcmsg:=gc_trcmsg||'3.7.2 Truncate partition completed'||chr(13);
  gc_trcmsg:=gc_trcmsg||'3.7.3 Rebuild PK Index starts'||chr(13);
  FOR I IN
  (SELECT 'ALTER INDEX '
    ||INDEX_NAME
    ||' REBUILD parallel 16 nologging' REBUILD_INDEX
  FROM ALL_INDEXES
  WHERE TABLE_NAME ='RPT_CLAIM_DTL_R'
  AND INDEX_NAME LIKE 'PK_%'
  AND STATUS='UNUSABLE'
  )
  LOOP
    LC_REBUILD_INDEX:=I.REBUILD_INDEX;
    EXECUTE IMMEDIATE LC_REBUILD_INDEX;
  END LOOP;
  gc_trcmsg:=gc_trcmsg||'3.7.z Exit from prc_trunc_partition'||CHR(13);
EXCEPTION
WHEN OTHERS THEN
    gc_errmsg :=SUBSTR(SQLERRM,1,4000);
    gc_trcmsg:=gc_trcmsg||'2.z Error in prc_trunc_partition'||chr(13);
    pkg_grp_log_util.prc_update_log
      (
        gn_out_job_id                 --p_job_id
        ,gc_error_status              --p_job_status
        ,gc_errmsg                    --p_err_msg
        ,gc_trcmsg||chr(13)||gc_errmsg--p_trc_msg
        ,gc_truncpartby               --p_log_util_called_by_r
      );
    RAISE;
END prc_trunc_partition;
--Main procedures calls other procedure to load data in RPT_CLAIM_DTL_R
PROCEDURE main
IS
/*Perf Tuning Changes : Start: Cursor is no longer required - Commenting this section */
/*
VAR_REF_CUR SYS_REFCURSOR;
TYPE var_tbl_type IS TABLE OF RPT_CLAIM_DTL_R%ROWTYPE INDEX BY BINARY_INTEGER;
lt_var_tbl_typ var_tbl_type;
*/
/*Perf Tuning Changes : End: Cursor is no longer required - Commenting this section */
ln_rec_cnt NUMBER:=0;
ln_START_TIME NUMBER;
/* 21-Aug-2024 changes starts
CURSOR cur_upd_occdays_remain
IS
SELECT  D_ANY_OCC_START_DATE_R--PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC.get_pacs_as_of_date_r D_CLAIM_AS_OF_DATE_R,
,(D_ANY_OCC_START_DATE_R-gd_pacs_as_of_date_r) N_ANY_OCC_DAYS_REMAINING_R
FROM RPT_CLAIM_DTL_R
WHERE N_YEARMONTH_R=gn_current_month
GROUP BY D_ANY_OCC_START_DATE_R;
TYPE var_upd_tbl_dys_type IS TABLE OF cur_upd_occdays_remain%ROWTYPE INDEX BY BINARY_INTEGER;
lt_var_upd_tbl_dys_typ var_upd_tbl_dys_type;

CURSOR cur_upd_achpmnt_ind
IS
--SELECT n_claim_sk_r,CAST(NULL AS VARCHAR2(100)) V_CLAIM_ACH_PAYMENT_IND_R
--FROM RPT_CLAIM_DTL_R
--WHERE N_YEARMONTH_R=gn_current_month
--GROUP BY n_claim_sk_r;
SELECT RPT_CLAIM_DTL_R.n_claim_sk_r,fct_benefit_payment_r_claim_achind_mv_ssl.ach_indicator V_CLAIM_ACH_PAYMENT_IND_R
FROM RPT_CLAIM_DTL_R,FCT_BENEFIT_PAYMENT_R_CLAIM_ACHIND_MV_SSL
WHERE N_YEARMONTH_R=gn_current_month
  AND RPT_CLAIM_DTL_R.n_claim_sk_r=FCT_BENEFIT_PAYMENT_R_CLAIM_ACHIND_MV_SSL.n_claim_sk_r
  and fct_benefit_payment_r_claim_achind_mv_ssl.ach_indicator IS NOT NULL
GROUP BY RPT_CLAIM_DTL_R.n_claim_sk_r,fct_benefit_payment_r_claim_achind_mv_ssl.ach_indicator;
TYPE var_upd_tbl_pmntind_type IS TABLE OF cur_upd_achpmnt_ind%ROWTYPE INDEX BY BINARY_INTEGER;
lt_var_upd_tbl_pmntind_typ var_upd_tbl_pmntind_type;
--LV_CLAIM_ACH_PAYMENT_IND_R VARCHAR2(100);
*/--21-AUg-2024 changes ends
/*--14-Mar-2024 changes
CURSOR cur_upd_dt
IS
SELECT n_claim_sk_r,N_CLAIM_COVERAGE_GROUP_SK_R,V_LOB_TYPE_R
--,CAST(NULL AS DATE) d_earliest_service_period_from_r -26-jan-2024 changes
--,CAST(NULL AS DATE) d_earliest_service_period_to_r   -26-jan-2024 changes
,CAST(NULL AS DATE) d_most_recent_service_period_from_r
,CAST(NULL AS DATE) d_most_recent_service_period_to_r
FROM RPT_CLAIM_DTL_R
WHERE N_YEARMONTH_R=gn_current_month
GROUP BY n_claim_sk_r,N_CLAIM_COVERAGE_GROUP_SK_R,V_LOB_TYPE_R;
TYPE var_upd_tbl_dt_type IS TABLE OF cur_upd_dt%ROWTYPE INDEX BY BINARY_INTEGER;
lt_var_upd_tbl_dt_typ var_upd_tbl_dt_type;

--ld_earliest_service_period_from_r   DATE;26-jan-2024 changes
--ld_earliest_service_period_to_r     DATE;26-jan-2024 changes
ld_mostrecent_service_period_from_r DATE;
ld_mostrecent_service_period_to_r   DATE;
*/
/*21-AUg-2024 changes starts
--30-Jan-2024 changes starts
CURSOR cur_upd_perioddys
IS
SELECT V_CLAIM_NUMBER_R
,PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC.GET_N_CURR_BENEFIT_PERIOD_DAYS_R(V_CLAIM_NUMBER_R,NULL ) N_CURR_BENEFIT_PERIOD_DAYS_R
,PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC.GET_N_total_BENEFIT_PERIOD_DAYS_R(V_CLAIM_NUMBER_R,NULL ) N_totAL_BENEFIT_PERIOD_DAYS_R
FROM RPT_CLAIM_DTL_R
WHERE N_YEARMONTH_R=gn_current_month
GROUP BY v_claim_number_R;
TYPE var_upd_tbl_perioddys_type IS TABLE OF cur_upd_perioddys%ROWTYPE INDEX BY BINARY_INTEGER;
lt_var_upd_tbl_perioddys_typ var_upd_tbl_perioddys_type;
--30-Jan-2024 changes ENDS
--31-Jan-2024 changes starts
CURSOR cur_upd_offset
IS
SELECT RPT_CLAIM_DTL_R.n_claim_sk_r,RPT_CLAIM_DTL_R.n_claim_coverage_group_sk_r
,RPT_CLAIM_DTL_R_offset_mv_ssl.rehabilitation_offset_amount_088             n_rehab_offset_amt_088_r
,RPT_CLAIM_DTL_R_offset_mv_ssl.workers_compensation_offset_amount_083       n_workers_comp_offset_amt_083_r
,RPT_CLAIM_DTL_R_offset_mv_ssl.other_offset_amounts                         n_other_offset_amt_r
,RPT_CLAIM_DTL_R_offset_mv_ssl.rehabilitation_offset_indicator_088          v_rehab_offset_ind_088_r
FROM RPT_CLAIM_DTL_R,RPT_CLAIM_DTL_R_offset_mv_ssl
WHERE RPT_CLAIM_DTL_R.n_yearmonth_r=gn_current_month
AND RPT_CLAIM_DTL_R_offset_mv_ssl.n_claim_coverage_group_sk_r=RPT_CLAIM_DTL_R.n_claim_coverage_group_sk_r
AND RPT_CLAIM_DTL_R_offset_mv_ssl.n_claim_sk_r=RPT_CLAIM_DTL_R.n_claim_sk_r
GROUP BY RPT_CLAIM_DTL_R.n_claim_sk_r,RPT_CLAIM_DTL_R.n_claim_coverage_group_sk_r
,RPT_CLAIM_DTL_R_offset_mv_ssl.rehabilitation_offset_amount_088
,RPT_CLAIM_DTL_R_offset_mv_ssl.workers_compensation_offset_amount_083
,RPT_CLAIM_DTL_R_offset_mv_ssl.other_offset_amounts
,RPT_CLAIM_DTL_R_offset_mv_ssl.rehabilitation_offset_indicator_088
;
TYPE var_upd_tbl_offset_type IS TABLE OF cur_upd_offset%ROWTYPE INDEX BY BINARY_INTEGER;
lt_var_upd_tbl_offset_typ var_upd_tbl_offset_type;
--31-Jan-2024 changes ENDS
--04-Mar-2024 changes starts
CURSOR cur_upd_dates
IS
select (  SELECT
                  MAX(td2.d_calendar_date_r) D_CLOSED_MONTH_END_DATE_R
             FROM dim_time_r td, dim_time_r td2
             where td.d_calendar_date_r = a.d_claim_closed_date_r
             and td.N_CLAIMS_YEAR_R = td2.N_CLAIMS_YEAR_R
             and td.N_CLAIMS_MONTH_R = td2.N_CLAIMS_MONTH_R
             ) D_CLOSED_MONTH_END_DATE_R,
             (SELECT
                 MIN(td2.d_calendar_date_r)  D_CLOSED_MONTH_START_DATE_R
             FROM dim_time_r td, dim_time_r td2
             where td.d_calendar_date_r = a.d_claim_closed_date_r
             and td.N_CLAIMS_YEAR_R = td2.N_CLAIMS_YEAR_R
             and td.N_CLAIMS_MONTH_R = td2.N_CLAIMS_MONTH_R
             ) D_CLOSED_MONTH_START_DATE_R  ,
           a.rowid row_id from RPT_CLAIM_DTL_R a
WHERE N_YEARMONTH_R=gn_current_month
and d_claim_closed_date_r is not null;--06-May-2024 changes
TYPE var_upd_tbl_dates_type IS TABLE OF cur_upd_dates%ROWTYPE INDEX BY BINARY_INTEGER;
lt_var_upd_tbl_dates_typ var_upd_tbl_dates_type;

CURSOR cur_upd_mostmed
IS
SELECT
   d_created_date_r d_most_recent_medical_note_date_r
   --,v_note_content_r v_most_recent_medical_note_r --04-Mar-2024 changes
   ,v_med_note_data_r v_most_recent_medical_note_r  --04-Mar-2024 changes
   ,n_claim_sk_r
 FROM FCT_CLAIM_NOTE_R_DUR_MV_SSL med_note
WHERE med_note.dupremov    =1
AND EXISTS (SELECT 1
              FROM RPT_CLAIM_DTL_R
			WHERE RPT_CLAIM_DTL_R.n_yearmonth_r=gn_current_month
              AND RPT_CLAIM_DTL_R.n_claim_sk_r=med_note.n_claim_sk_r
			)
  GROUP BY D_CREATED_DATE_R,v_med_note_data_r,N_CLAIM_SK_R
            ;
TYPE var_upd_tbl_mostmed_type IS TABLE OF cur_upd_mostmed%ROWTYPE INDEX BY BINARY_INTEGER;
lt_var_upd_tbl_mostmed_typ var_upd_tbl_mostmed_type;

CURSOR cur_upd_mostmgmnt
IS
SELECT
   d_created_date_r  d_most_recent_management_note_date_r
   --,v_note_content_r v_most_recent_mgmt_note_r --04-Mar-2024 changes
   ,v_mgt_note_data_r v_most_recent_mgmt_note_r  --04-Mar-2024 changes
   ,n_claim_sk_r
 FROM fct_claim_note_r_mgmnt_mv_ssl med_note
WHERE med_note.dupremov    =1
AND EXISTS (SELECT 1
              FROM RPT_CLAIM_DTL_R
			WHERE RPT_CLAIM_DTL_R.n_yearmonth_r=gn_current_month
              AND RPT_CLAIM_DTL_R.n_claim_sk_r=med_note.n_claim_sk_r
			)
  GROUP BY d_created_date_r,v_mgt_note_data_r,n_claim_sk_r
            ;
TYPE var_upd_tbl_mostmgmnt_type IS TABLE OF cur_upd_mostmgmnt%ROWTYPE INDEX BY BINARY_INTEGER;
lt_var_upd_tbl_mostmgmnt_typ var_upd_tbl_mostmgmnt_type;

--04-Mar-2024 changes ends
*/--21-AUg-2024 changes ends

BEGIN

--Perf Tuning Changes: Start : Logging
INSERT INTO ATOMIC.SSL_PACKAGE_LOG_TABLE(job_name,process_name, start_date, end_date)
    VALUES ('PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC','START: MAIN PROCESS - LOAD RPT_CLAIM_DTL_R TABLE', SYSDATE, NULL);
COMMIT;


--DBMS_OUTPUT.PUT_LINE(1);

-- SET JOB TO IN-PROGRESS
UPDATE SSL_PACKAGE_MILESTONE_TABLE SET
    JOB_TIMESTAMP   = CURRENT_TIMESTAMP,
    JOB_STATUS      = 'IN-PROGRESS'
WHERE JOB_NAME='PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC';
COMMIT;


--DBMS_OUTPUT.PUT_LINE(2);
--Perf Tuning Changes: End : Logging

    --Call Log Util pkg to Insert entry in PRCS_JOB_LOG_R
	pkg_grp_log_util.prc_insert_log
                       ( p_source              => gc_source
					    ,p_job_nm              => gc_job_name
                        ,p_job_status          => gc_running_status
                        ,p_err_msg             => null
                        ,p_trc_msg             => null
                        ,p_n_batch_id          => gn_sysdt_batchid
                        ,p_log_util_called_by_r=> gc_main_loadedby
						,out_job_id            => gn_out_job_id
						);
    gc_trcmsg:='1. Entered into main'||chr(13);
    GC_TRCMSG:='gn_current_month     :->'||GN_CURRENT_MONTH||CHR(13);
    GC_TRCMSG:='gn_prior_month       :->'||GN_PRIOR_MONTH||CHR(13);
   /*START: 20-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
   gc_trcmsg:='1. Entered into main. '||'gn_current_month:->'||gn_current_month|| ' - gn_prior_month:->'||gn_prior_month;
	 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
	 (
		p_job_id_r                    => gn_out_job_id,
		p_batch_id_r                  => gn_sysdt_batchid,
		p_message_type_r              => gc_message_type_r,
		p_code_location_r             => gc_main_loadedby,
		p_message_r                   => gc_trcmsg,
		p_count_type_r                => NULL,
		p_count_r                     => NULL,
		p_duration_r                  => NULL,
		p_created_by_r                => GC_JOB_NAME,
		out_prcs_job_log_message_id_r => gn_job_log_message_id_r
	);
	-- Perf Improvement: Start: No Longer required - handle as left join in the rpt load query
	--gd_pacs_as_of_date_r:=PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC.get_pacs_as_of_date_r;             --19-jan-2024 changes
	-- Perf Improvement: End: No Longer required - handle as left join in the rpt load query

	GC_TRCMSG:='gd_pacs_as_of_date_r       :->'||gd_pacs_as_of_date_r||CHR(13);--19-jan-2024 changes
    --GC_TRCMSG:=GC_TRCMSG||'2.Refresh MVs starts  '||CHR(13);
    --PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC.prc_refresh_ssl_mvs;
    --GC_TRCMSG:=GC_TRCMSG||'2.z Refresh MVs starts ends '||CHR(13);
    --gc_trcmsg:=gc_trcmsg||'1.c gn_prior2prior_month :->'||gn_prior2prior_month||chr(13);
	GC_TRCMSG:='3. Call procedure prc_upd_del_data from main'||CHR(13);
    gc_trcmsg:='2. Call procedure prc_upd_del_data from main'||chr(13);
    PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC.prc_upd_del_data;
    gc_trcmsg:='2.z Exit from in prc_upd_del_data'||chr(13);
	gc_trcmsg:='3.z Completed Procedure prc_upd_del_data call from main'||chr(13);

     /**************************************** START: PERFORMANCE TUNING MAIN QUERY *********************************************
    As part of Performance Tuning Adding following Query which is Combine query consisting of procedures and functions
        Procedures combined
        - PROCEDURE: prc_get_cur_data :  This is used as base query - only change is adding filter condition to get delta records.
        - PROCEDURE: PRC_GRP_UPD_RPT_CLAIM_DTL_R_COLS - All logic from this has been impemented in the following combined query.
        - FUNCTION: get_pacs_as_of_date_r :  This has been used as left join to the main query.
        - PROCEDURE: prc_upd_wavier_ltd_ind_cols  :  This has been used as left join to the main query.
        - PROCEDURE prc_upd_decision_cols  :  This has been used as left join to the main query.

        Date : 27-Feb-2025
    */



--DBMS_OUTPUT.PUT_LINE(3);
        ln_rec_cnt:=0;
        SELECT COUNT(1) into ln_rec_cnt FROM ATOMIC.RPT_CLAIM_DTL_R where n_yearmonth_r=gn_current_month;

        INSERT INTO ATOMIC.SSL_PACKAGE_LOG_TABLE(job_name,process_name, start_date, end_date,SOURCE_TABLE_COUNT)
        VALUES ('PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC','START: DATA LOAD TO RPT_CLAIM_DTL_R', SYSDATE, NULL,ln_rec_cnt);
        COMMIT;
/*START: 20-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
 gc_trcmsg:='3.1 START: LOAD DATA TO TARGET TABLE RPT_CLAIM_DTL_R'||chr(13);
 gt_start_time_r := SYSTIMESTAMP;
 gc_count_type_r:= PKG_GRP_LOG_UTIL.gc_count_type_insert;

			 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
			 (
				p_job_id_r                    => gn_out_job_id,
				p_batch_id_r                  => gn_sysdt_batchid,
				p_message_type_r              => gc_message_type_r,
				p_code_location_r             => gc_main_loadedby,
				p_message_r                   => gc_trcmsg,
				p_count_type_r                => gc_count_type_r,
				p_count_r                     => NULL,
				p_duration_r                  => NULL,
				p_created_by_r                => GC_JOB_NAME,
				out_prcs_job_log_message_id_r => gn_job_log_message_id_r
			);
/*END: 20-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
--DBMS_OUTPUT.PUT_LINE(4);
    INSERT INTO ATOMIC.RPT_CLAIM_DTL_R
    WITH CTE AS
    (    select /*+PARALLEL(8)*/
            V_ADD_DIAG_CATEGORY_CODE_R
            ,V_ADD_DIAG_CATEGORY_DESC_R
            ,V_ADD_DIAGNOSIS_CODE_R
            ,V_PRI_DIAG_CATEGORY_CODE_R
            ,V_PRI_DIAG_CATEGORY_DESC_R
            ,V_PRI_DIAGNOSIS_CODE_R
            ,N_DIAGNOSIS_TYPE_CODE_R
            ,V_ADD_DIAG_CODE_DESC_R
            ,V_PRI_DIAG_CODE_DESC_R
            ,D_LAST_PAYMENT_DATE_R
            ,D_AGE_REDUCTION_DATE_R
            ,V_CLAIM_ACH_PAYMENT_IND_R
            ,D_BENEFIT_START_R
            ,V_CAUSE_OF_EVENT_CODE_R
            ,V_CAUSE_OF_EVENT_DESC_R
            ,V_CLAIM_CLASS_ID_R
            ,D_CLAIM_CLOSED_DATE_R
            ,V_ELIGIBILITY_DECISION_R
            ,V_ELIGIBILITY_REASON_R
            ,N_CLAIM_COVERAGE_GROUP_SK_R
            ,N_CLAIM_COVERAGE_SK_R
            ,N_CLAIM_SK_R
            ,V_CLAIM_EVENT_NUMBER_R
            ,V_CLAIM_NUMBER_R
            ,N_CLAIM_PENDING_AGE_R
            ,N_CLAIM_TAXABLE_BENEFIT_PCT_R
            ,N_DAYS_OPEN_R
            ,D_DISABILITY_START_DATE_R
            ,V_EXERTION_LEVEL_R
            ,V_DURATION_INDICATOR_R
            ,V_DURATION_PERIOD_R
            ,D_EARLIEST_BENEFIT_PAYMENT_DATE_R
            ,D_EARLIEST_SERVICE_PERIOD_FROM_R
            ,D_EARLIEST_SERVICE_PERIOD_TO_R
            ,V_ELIMINATION_PERIOD_R
            ,D_EST_QUALIFYING_PERIOD_EXP_DATE_R
            ,V_EST_SS_IND_R
            ,V_EXTENDED_DURATION_IND_R
            ,D_LOSS_DATE_R
            ,D_MODIFIED_RTW_DATE_R
            ,D_MOST_RECENT_SERVICE_PERIOD_FROM_R
            ,D_MOST_RECENT_SERVICE_PERIOD_TO_R
            ,D_NURSE_CERT_END_DATE_R
            ,N_NURSE_CERT_SEQ_R
            ,V_OCCUPATION_CODE_R
            ,V_OCCUPATION_DESC_R
            ,V_PFL_CHILD_GENDER_R
            ,D_PFL_DOB_R
            ,V_MANDATED_FAMILY_MEMBER_R
            ,V_LEAVE_REASON_R
            ,D_PFL_DOP_R
            ,D_PHYS_CERT_END_DATE_R
            ,D_PLAN_DUR_DATE_R
            ,D_RETIREMENT_TERMINATION_DATE_R
            ,D_RETURN_TO_WORK_DATE_R
            ,V_SOCIAL_SECURITY_IND_R
            ,V_TURNAROUND_RANGE_R
            ,V_WAIVER_IND_R
            ,D_WAIVER_STATUS_DATE_R
            ,N_WAIVER_TERMINATION_AGE_R
            ,D_WAIVER_TERMINATION_DATE_R
            ,D_CLAIM_AS_OF_DATE_R
            ,V_METHOD_R
            ,V_METHOD_STYLE_R
            ,V_CLAIM_IDENTIFIER_R
            ,D_MOST_RECENT_ACTIVITY_DATE_R
            ,D_CLAIM_RECEIVED_DATE_R
            ,FIC_MIS_DATE_R
            ,V_LTD_POLICY_IND_R
            ,V_CLAIM_COMPANY_R
            ,V_PRIVACY_INDICATOR_R
            ,N_ANY_OCC_DAYS_REMAINING_R
            ,D_ANY_OCC_DECISION_DATE_R
            ,V_ANY_OCC_PERIOD_R
            ,V_ANY_OCC_PERIOD_IND_R
            ,D_ANY_OCC_START_DATE_R
            ,V_ANY_OCC_OWN_OCC_IND_R
            ,V_OWN_OCC_PERIOD_R
            ,V_OWN_OCC_PERIOD_IND_R
            ,V_CLAIM_COVERAGE_CODE_R
            ,V_PRODUCT_LINE_DESC_R
            ,N_COV_GRP_ID_R
            ,V_CLAIM_COVERAGE_DESC_R
            ,D_APPEAL_RECEIVED_DATE_R
            ,V_APPEAL_DENIAL_OVERTURN_TYPE_R
            ,V_APPEALS_ANALYST_R
            ,D_APPEAL_COMPLETED_DATE_R
            ,N_APPEAL_SOURCE_VERSION_SEQ_NUMBER_R
            ,D_MOST_RECENT_MEDICAL_NOTE_DATE_R
            ,V_MOST_RECENT_MEDICAL_NOTE_R
            ,D_MOST_RECENT_MANAGEMENT_NOTE_DATE_R
            ,V_MOST_RECENT_MGMT_NOTE_R
            ,D_SS_DEP_AWARD_EFF_DATE_R
            ,V_SS_DEPENDENT_STATUS_R
            ,D_SS_DEP_TERM_DATE_R
            ,V_SS_DEP_AWARD_TYPE_R
            ,V_SS_DEP_PURSUE_IND_R
            ,D_SS_MOST_RECENT_UPDATE_DATE_R
            ,D_SS_PRIMARY_EFF_DATE_R
            ,V_SS_STATUS_DESCRIPTION_R
            ,D_SS_CLOSED_TERM_DATE_R
            ,V_SS_PRIMARY_AWARD_TYPE_R
            ,V_SS_PRIMARY_PURSUE_IND_R
            ,V_SS_REJECT_REASON_CODE_R
            ,V_SS_REJECT_REASON_R
            ,V_CLAIM_STATUS_CATEGORY_R
            ,V_CLAIM_STATUS_CODE_R
            ,V_CLAIM_STATUS_DESC_R
            ,D_CLAIM_STATUS_EFF_DATE_R
            ,D_LAST_IN_STATUS_46_DATE_R
            ,V_PRIOR_CLAIM_STATUS_CLOSURE_CODE_R
            ,V_PRIOR_CLAIM_STATUS_CODE_R
            ,V_SALES_CLAIM_STATUS_DESC_R
            ,V_CURR_CLAIM_STATUS_CODE_R
            ,V_CLAIM_TYPE_R
            ,D_TIER_CREATED_DATE_R
            ,D_WFAM_CODE_CREATED_DATE_R
            ,V_TIER_R
            ,V_WFAM_R
            ,D_PRD_R
            ,D_PRD_DAYS_REMAINING_R
            ,V_ACCOMMODATIONS_NEEDED_R
            ,V_CLINICAL_VOC_ENGAGEMENT_R
            ,V_TIER_DESCRIPTION_R
            ,N_TIER_NUM_R
            ,V_RECOVERY_EXPECTATIONS_R
            ,V_VOC_REHAB_STATUS_R
            ,V_VOC_REHAB_MGR_NAME_R
            ,V_VOC_REHAB_SPECIALIST_R
            ,V_SERVICE_REQUESTED_OTHER_R
            ,V_SERVICE_REQUESTED_R
            ,V_VOC_REHAB_OUTCOME_R
            ,V_VOC_REHAB_ACTIVE_STATUS_R
            ,D_TSA_DATE_R
            ,V_LOCATION_NUMBER_R
            ,V_CORRESPONDENT_NAME_R
            ,V_SUBGROUP_ADDRESSLINE1_R
            ,V_SUBGROUP_ADDRESSLINE2_R
            ,V_SUBGROUP_CITY_R
            ,V_SUBGROUP_ID_R
            ,V_SUBGROUP_NAME_R
            ,V_SUBGROUP_POSTALZIP_R
            ,V_SUBGROUP_PROVSTATE_R
            ,V_LAST_MODIFIED_BY_R
            ,T_CREATION_DATE_R
            ,V_CREATED_BY_R
            ,T_LAST_MODIFIED_DATE_R
            ,N_YEARMONTH_R
            ,V_RPT_ACTIVE_STATUS_R
            ,N_BATCH_ID_R
            ,V_EXAMINER_ID_R
            ,V_EXAMINER_NAME_R
            ,D_HIRE_DATE_R
            --26-dEC-2023 CHANGES STARTS
            ,d_ss_council_start_date_r
            ,d_ss_appeal_end_date_r
            ,d_ss_court_start_date_r
            ,d_ss_court_appeal_end_date_r
            ,d_ss_hearing_start_date_r
            ,d_ss_hearing_end_date_r
            ,d_ss_init_filing_start_date_r
            ,d_ss_init_filing_end_date_r
            ,d_ss_reconsider_start_date_r
            ,d_ss_reconsider_end_date_r
            ,V_SS_HARDSHIP_IND_R
            --26-dEC-2023 CHANGES ENDS
            ,D_WORKSHEET_START_DATE_R
            ,D_WORKSHEET_END_DATE_R
            ,v_lob_type_r --19-JAN-2024 CHANGES
            --23-jAN-2024 changes starts
            ,V_SOURCE_SYSTEM_NAME_R
            ,N_CURR_BENEFIT_PERIOD_DAYS_R
            ,N_TOTAL_BENEFIT_PERIOD_DAYS_R
            --23-jAN-2024 changes ends
            --26-jAN-2024 changes starts
            ,N_BASIC_INSURED_SALARY_R
            ,V_BASIC_INSURED_SALARY_IND_R
            --26-jAN-2024 changes ends
            --31-jAN-2024 changes starts
            ,n_rehab_offset_amt_088_r
            ,v_rehab_offset_ind_088_r
            ,n_workers_comp_offset_amt_083_r
            ,n_other_offset_amt_r
            ,v_pfl_leave_type_r
            ,v_pfl_license_number_r
            --31-jAN-2024 changes ends
            --20-Feb-2024 changes ends

            /*******************************************************************************************************/
            -- Perf Tuning :: Start
            --,d_closed_month_start_date_r -- Perf Tuning :: Commented out as part of Performance Tuning
            --,d_closed_month_end_date_r -- Perf Tuning :: Commented out as part of Performance Tuning

            ,(SELECT /*+PARALLEL(4)*/
                         MIN(td2.d_calendar_date_r)  D_CLOSED_MONTH_START_DATE_R
                     FROM ATOMIC.dim_time_r td, ATOMIC.dim_time_r td2
                     where td.d_calendar_date_r = a.D_CLAIM_CLOSED_DATE_R
                     and td.N_CLAIMS_YEAR_R = td2.N_CLAIMS_YEAR_R
                     and td.N_CLAIMS_MONTH_R = td2.N_CLAIMS_MONTH_R
                     ) as d_closed_month_start_date_r
            ,(  SELECT /*+PARALLEL(4)*/
                          MAX(td2.d_calendar_date_r) D_CLOSED_MONTH_END_DATE_R
                     FROM ATOMIC.dim_time_r td, ATOMIC.dim_time_r td2
                     where td.d_calendar_date_r = a.D_CLAIM_CLOSED_DATE_R
                     and td.N_CLAIMS_YEAR_R = td2.N_CLAIMS_YEAR_R
                     and td.N_CLAIMS_MONTH_R = td2.N_CLAIMS_MONTH_R
                     ) d_closed_month_end_date_r

            -- Perf Tuning :: End

            /*******************************************************************************************************/
            --20-Feb-2024 changes ends
            --15-Jun-2024 changes starts
            ,V_APPEAL_IND_R
            ,V_APPEAL_RESULT_STATUS_CODE_R
            ,D_APPEAL_RESULT_STATUS_CODE_EFF_DATE_R		,
            --15-Jun-2024 changes ends
            --21/Jun/2024 - Changes start
              CAST(NULL AS VARCHAR2(300 CHAR)) V_APPEAL_ANALYST_NAME_r         ,
              CAST(NULL AS VARCHAR2(300 CHAR)) V_APPEAL_STATUS_CODE_R          ,
              CAST(NULL AS VARCHAR2(300 CHAR)) V_RPT_WORKSHEET_INDICATOR_R     ,
              CAST(NULL AS number)            N_WORKSHEET_NUMBER_R            ,
              CAST(NULL AS VARCHAR2(300 CHAR)) V_WORKSHEET_STATUS_R            ,
              CAST(NULL AS NUMBER)            N_WORKSHEET_SEQ_NBR_OBJECTNM_R,
              case when v_coverage_type_code_r ='1' then 'LTD'
              when v_coverage_type_code_r = '2' then 'STD'
              when v_coverage_type_code_r = '3' then  'Life'
              else v_coverage_type_code_r
              end as                          v_coverage_type_code_r,
              N_MAX_BENEFIT_R,
              N_MINIMUM_BENEFIT_R,
            --21/Jun/2024 - Changes end
            --26/08/24 Changes Start
            V_CLAIM_WELLNESS_IND_R
            --26/08/24 Changes End
           ,V_HAS_ASSOCIATED_WAIVER_IND_R--11/09/24 CHANGES
           ,V_HAS_ASSOCIATED_LTD_IND_R   --11/09/24 CHANGES
            --11/09/24 changes start
           , V_CLAIM_STATUS_REASON_DESC_R
            --11/09/24 changes end
            --23/09/34 Changes Start
            ,D_CLAIM_DECISION_DATE_R
            ,N_CLAIM_DECISION_DAYS_R
            ,V_TURNAROUND_RANGE1_R
            --23/09/34 Changes Start
            , V_OVERRIDE_NAME_R
            , D_RECORD_START_DATE_R
            , D_RECORD_END_DATE_R
			-- 26-march-2026 added as per FDM reqt start
            ,D_DURATION_EFF_DATE_R
            ,D_ELIMINATION_EFF_DATE_R
            ,D_GROSS_BEN_EFF_DATE_R
            ,D_LOSS_DATE_EFF_DATE_R
            ,N_SS_PRIMARY_AWARD_AMOUNT_R
            ,D_SS_EST_START_DATE_R
            ,D_SS_AWARDED_START_DATE_R
            ,V_SS_PURSUING_REMARKS_R
            ,V_SS_DEP_OFFSET_ALLOWED_R
            ,V_DOT_CODE_PRIMARY_DESC_R
            ,V_DOT_CODE_PRIMARY_R
			--, D_DISBURSE_DATE_R
            ,D_PRIMARY_DIAG_EFF_DATE_R
            ,V_ELIMINATION_IND_R
            ,D_CHECK_NET_BEN_EFF_DATE_R
			-- 26-march-2026 added as per FDM reqt end
             from (
            select
            --20-Feb-2024 changes starts
            --case when v_lob_type_r in ('LTD', 'STD', 'VPL', 'VPS') then rank() over (partition by v_claim_identifier_r order by b.N_CLAIM_CVRG_SEQUENCE_NUMBER_R desc nulls --last)else 1 end rank,
            /*case when v_lob_type_r in ('LTD', 'STD', 'VPL', 'VPS','WOP') then rank() over (partition by a.v_claim_number_r order by b.N_CLAIM_CVRG_SEQUENCE_NUMBER_R desc nulls last)else 1 end rank,
            --20-Feb-2024 changes ends */
            --24-Jul-2024 changes starts
            case when v_lob_type_r in ('LTD', 'STD', 'VPL', 'VPS') then rank() over (partition by a.v_claim_number_r order by b.N_CLAIM_CVRG_SEQUENCE_NUMBER_R desc nulls last)
            when v_lob_type_r ='WOP'  THEN
                   case WHEN g.N_CLAIM_CVRG_GRP_SRC_SYS_KEY_R IS NULL
                    THEN CASE
                            WHEN rank() OVER (
                                    PARTITION BY g.n_claim_sk_r ORDER BY g.N_CLAIM_CVRG_GRP_SRC_SYS_KEY_R desc nulls last, g.N_CLAIM_CVRG_SEQUENCE_NUMBER_R desc NULLS LAST
                                    ) = 1
                                THEN 1
                            ELSE 0
                            END
                   ELSE 1
                   end
            else 1 end rank,
            --24-Jul-2024 changes ends
             diag.additional_diag_code                                                       V_ADD_DIAG_CATEGORY_CODE_R
            ,diag.add_diag_category_desc                                                     V_ADD_DIAG_CATEGORY_DESC_R
            ,diag.additional_diag_code                                                       V_ADD_DIAGNOSIS_CODE_R	                    --On-priority
            ,diag.V_PRI_DIAG_CATEGORY_CODE_R                                                 V_PRI_DIAG_CATEGORY_CODE_R	                --On-priority
            ,diag.V_PRI_DIAG_CATEGORY_DESC_R                                                 V_PRI_DIAG_CATEGORY_DESC_R	                --On-priority
            ,diag.primary_diag_code                                                          V_PRI_DIAGNOSIS_CODE_R	                    --On-priority
            ,diag.diagnosis_type_code                                                        N_DIAGNOSIS_TYPE_CODE_R	                --On-priority
            ,diag.additional_desc                                                            V_ADD_DIAG_CODE_DESC_R	                    --On-priority
            ,DIAG.Primary_desc                                                               V_PRI_DIAG_CODE_DESC_R	                    --On-priority
            ,PAYMENT_DATES.Last_Payment_Date                                                 D_LAST_PAYMENT_DATE_R	                    --On-priority
            ,G.D_AGE_REDUCTION_DATE_R                                                        D_AGE_REDUCTION_DATE_R
            --,OV_CLAIM_ACH_PAYMENT.ACH_indicator                                              V_CLAIM_ACH_PAYMENT_IND_R
            --,CAST(NULL AS VARCHAR2(100))                                                     V_CLAIM_ACH_PAYMENT_IND_R
            --,pkg_grp_load_RPT_CLAIM_DTL_R.get_v_claim_ach_payment_ind_r(a.n_claim_sk_r)     V_CLAIM_ACH_PAYMENT_IND_R	--19-Jan-2024 changes


            -- Perf Tuning :: End : PRC_GRP_UPD_RPT_CLAIM_DTL_R_COLS procedure logic
            --,CAST(NULL AS VARCHAR2(100))                                                      V_CLAIM_ACH_PAYMENT_IND_R	--19-Jan-2024 changes
            ,ach_ind.v_claim_ach_payment_ind_r                                                V_CLAIM_ACH_PAYMENT_IND_R	-- -- Perf Tuning changes
            -- Perf Tuning :: End : PRC_GRP_UPD_RPT_CLAIM_DTL_R_COLS procedure logic

            ,case when v_lob_type_r in ('LTD', 'STD', 'VPL', 'VPS')
            then m.D_BENEFIT_START_R else n.D_BENEFIT_START_R     end                        D_BENEFIT_START_R
            ,t.v_event_cause_r                                                               V_CAUSE_OF_EVENT_CODE_R
            --,DIM_GRP_LOSS_R.V_LOSS_DESC_R                                                    V_CAUSE_OF_EVENT_DESC_R
            ,cast(null as varchar2(100))                                                     V_CAUSE_OF_EVENT_DESC_R
            ,(CASE WHEN a.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP')
              THEN g.V_CLASS_ID_R
              ELSE b.V_CLASS_ID_R
              END
              )                                                                  			 V_CLAIM_CLASS_ID_R--On-priority
            --30/09/24 changes starts
            --,d.d_closure_date_r                                                              D_CLAIM_CLOSED_DATE_R	                    --On-priority
           /* ,(CASE WHEN a.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP')
                   THEN g.D_DATE_CLOSED_R
                   else D.d_closure_date_r
              end
             )                                                                               D_CLAIM_CLOSED_DATE_R	  */
            ,(CASE WHEN a.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP') and A.V_SOURCE_SYSTEM_NAME_R = 'PACS'
                  THEN g.D_DATE_CLOSED_R
                  else D.d_closure_date_r
              end
                                                  )                                          D_CLAIM_CLOSED_DATE_R	           --On-priority
            --30/09/24 changes ends
            ,r.V_ELIGIBILITY_OUTCOME_R                                                       V_ELIGIBILITY_DECISION_R	                --On-priority
            ,r.V_DISABILITY_DATE_STATUS_R                                                    V_ELIGIBILITY_REASON_R
            ,g.N_CLAIM_COVERAGE_GROUP_SK_R                                                   N_CLAIM_COVERAGE_GROUP_SK_R	            --On-priority
            ,b.n_claim_coverage_sk_r                                                         N_CLAIM_COVERAGE_SK_R	                    --On-priority
            ,a.N_CLAIM_SK_R                                                                  N_CLAIM_SK_R	                            --On-priority
            ,s.V_CLAIM_EVENT_NUMBER_R                                                        V_CLAIM_EVENT_NUMBER_R
            ,a.V_CLAIM_NUMBER_R                                                              V_CLAIM_NUMBER_R	                         --On-priority
            ,(CASE WHEN d.V_CLAIM_STATUS_REASON_CODE_R IN ('22','46') THEN
               (SYSDATE - RECEIVED_DATE.RECEIVED_DATE)
               ELSE NULL
               END
              )                                                                              N_CLAIM_PENDING_AGE_R	                     --On-priority
            ,(CASE
                                         WHEN a.V_SOURCE_SYSTEM_NAME_R = 'PACS' then m.n_taxable_override_pct_r
                                         when a.V_SOURCE_SYSTEM_NAME_R = 'CV' THEN mcv.n_taxable_override_pct_r
                                         END
                                        )                                               AS N_CLAIM_TAXABLE_BENEFIT_PCT_R
            ,cast(null as number)                                                            N_DAYS_OPEN_R
            ,
            /*(CASE
                WHEN c.v_orig_lob_r = 'VAI' THEN
                    t.d_date_of_event_r +
                    CASE
                        WHEN r.n_elim_period_r <> ''
                             OR r.n_elim_period_r <> 0 THEN r.n_elim_period_r
                        ELSE
                            0
                    END
                ELSE
                    t.d_date_of_event_r
            END
            )        */

            (case
                    when
                         nvl(r.n_elim_period_r,0) <> 0 THEN
                        r.n_elim_period_r
                    WHEN
                        --CASE t.v_event_cause_r--06-May-2024 changes
                        CASE UPPER(t.v_event_cause_r) --06-May-2024 changes
                            WHEN 'ACCIDENT'                        THEN 'A6'
                            WHEN 'ACCIDENT - AVIATION'             THEN 'A3'
                            WHEN 'ACCIDENT- AVIATION'              THEN 'A3'
                            WHEN 'ACCIDENT - OCCUPATIONAL'         THEN 'A1'
                            WHEN 'ACCIDENT- OCCUPATIONAL'          THEN 'A1'
                            WHEN 'ACCIDENT- OTHER'                 THEN 'A6'
                            WHEN 'ACCIDENT - OTHER'                THEN 'A6'
                            WHEN 'ACCIDENT - SPORTS'               THEN 'A4'
                            WHEN 'ACCIDENT- SPORTS'                THEN 'A4'
                            WHEN 'ADOPTION'                        THEN 'AE'
                            WHEN 'ALCOHOL'                         THEN 'AC'
                            WHEN 'ASSAULT'                         THEN 'A5'
                            WHEN 'BONDING'                         THEN 'AE'
                            WHEN 'COMMONDISASTER'                  THEN '31'
                            WHEN 'COMMON DISASTER'                 THEN '31'
                            WHEN 'DRUGS'                           THEN 'AD'
                            WHEN 'FOSTER'                          THEN 'AE'
                            WHEN 'MATERNITY'                       THEN 'AE'
                            WHEN 'MENTAL'                          THEN 'AA'
                            WHEN 'MISSING INSURED / DISAPPEARANCE' THEN '33'
                            WHEN 'MOTOR VEHICLE'                   THEN 'A2'
                            WHEN 'MOTORCYCLE'                      THEN 'A2'
                            WHEN 'NERVOUS'                         THEN 'AB'
                            WHEN 'SICKNESS'                        THEN 'AE'
                            WHEN 'SUICIDE'                         THEN 'SU'
                            WHEN 'UNKNOWN / UNDETERMINED'          THEN 'UN'
                            WHEN 'UNKNOWN / UNDETER '              THEN 'UN'
                            WHEN 'WAR / TERRORISM'                 THEN '40'
                            WHEN 'WELLNESS'                        THEN 'WL'
                            ELSE
                                'UN'
                        END
                    IN ( 'A1', 'A2', 'A3', 'A4', 'A5','A6' ) THEN
                        r.n_elim_period_acc_r
                    ELSE
                        r.n_elim_period_sick_r
                END
                )               + D.d_date_of_loss_r                                         D_DISABILITY_START_DATE_R	                 --On-priority--need to check mapping	                 --On-priority--need to check mapping
            ,D.V_EXERTION_LEVEL_R                                                            V_EXERTION_LEVEL_R
            ,(CASE
                  WHEN a.v_lob_type_r IN ( 'LTD', 'VPL' ) THEN
                      'M'
                  WHEN a.v_lob_type_r IN ( 'STD','VPS' ) THEN
                      'W'
                  WHEN NOT r.n_waiver_termination_age_r IS NULL THEN
                      'A'
                  ELSE
                      NULL
              END)                                                                           V_DURATION_INDICATOR_R	                     --On-priority
            ,--cast(null as VARCHAR2(100))
               CAST(p.V_CURR_DURATION_R	 AS VARCHAR2(100))														V_DURATION_PERIOD_R
             ,payment_dates.earliest_payment_date                                             D_EARLIEST_BENEFIT_PAYMENT_DATE_R	         --On-priority
            --,pkg_grp_load_RPT_CLAIM_DTL_R.get_d_earliest_service_period_from_r(a.n_claim_sk_r,g.N_CLAIM_COVERAGE_GROUP_SK_R,a.v_lob_type_r)   D_EARLIEST_SERVICE_PERIOD_FROM_R--19-jAN-2024 CHANGES
            --,pkg_grp_load_RPT_CLAIM_DTL_R.get_d_earliest_service_period_to_r(a.n_claim_sk_r,g.N_CLAIM_COVERAGE_GROUP_SK_R,a.v_lob_type_r)     D_EARLIEST_SERVICE_PERIOD_TO_R	--19-jAN-2024 CHANGES
            --,PAYMENT_DATES.MOST_RECENT_SERVICE_PERIOD_FROM_DATE D_EARLIEST_SERVICE_PERIOD_FROM_R--26-jAN-2024 CHANGES  --14-mar-2024 changes
            --,PAYMENT_DATES.MOST_RECENT_SERVICE_PERIOD_TO_DATE   D_EARLIEST_SERVICE_PERIOD_TO_R	--26-jAN-2024 CHANGES--14-mar-2024 changes
            ,PAYMENT_DATES.EARLIEST_SERVICE_PERIOD_FROM_DATE D_EARLIEST_SERVICE_PERIOD_FROM_R--14-mar-2024 changes
            ,PAYMENT_DATES.EARLIEST_SERVICE_PERIOD_TO_DATE   D_EARLIEST_SERVICE_PERIOD_TO_R	--14-mar-2024 changes
            ,CAST((CASE
                    WHEN r.n_elim_period_r <> ''
                         OR r.n_elim_period_r <> 0 THEN
                        r.n_elim_period_r
                    WHEN
                        --CASE t.v_event_cause_r--06-May-2024 changes
                        CASE UPPER(t.v_event_cause_r) --06-May-2024 changes
                            WHEN 'ACCIDENT'                        THEN 'A6'
                            WHEN 'ACCIDENT - AVIATION'             THEN 'A3'
                            WHEN 'ACCIDENT- AVIATION'              THEN 'A3'
                            WHEN 'ACCIDENT - OCCUPATIONAL'         THEN 'A1'
                            WHEN 'ACCIDENT- OCCUPATIONAL'          THEN 'A1'
                            WHEN 'ACCIDENT- OTHER'                 THEN 'A6'
                            WHEN 'ACCIDENT - OTHER'                THEN 'A6'
                            WHEN 'ACCIDENT - SPORTS'               THEN 'A4'
                            WHEN 'ACCIDENT- SPORTS'                THEN 'A4'
                            WHEN 'ADOPTION'                        THEN 'AE'
                            WHEN 'ALCOHOL'                         THEN 'AC'
                            WHEN 'ASSAULT'                         THEN 'A5'
                            WHEN 'BONDING'                         THEN 'AE'
                            WHEN 'COMMONDISASTER'                  THEN '31'
                            WHEN 'COMMON DISASTER'                 THEN '31'
                            WHEN 'DRUGS'                           THEN 'AD'
                            WHEN 'FOSTER'                          THEN 'AE'
                            WHEN 'MATERNITY'                       THEN 'AE'
                            WHEN 'MENTAL'                          THEN 'AA'
                            WHEN 'MISSING INSURED / DISAPPEARANCE' THEN '33'
                            WHEN 'MOTOR VEHICLE'                   THEN 'A2'
                            WHEN 'MOTORCYCLE'                      THEN 'A2'
                            WHEN 'NERVOUS'                         THEN 'AB'
                            WHEN 'SICKNESS'                        THEN 'AE'
                            WHEN 'SUICIDE'                         THEN 'SU'
                            WHEN 'UNKNOWN / UNDETERMINED'          THEN 'UN'
                            WHEN 'UNKNOWN / UNDETER '              THEN 'UN'
                            WHEN 'WAR / TERRORISM'                 THEN '40'
                            WHEN 'WELLNESS'                        THEN 'WL'
                            ELSE
                                'UN'
                        END
                    IN ( 'A1', 'A2', 'A3', 'A4', 'A5','A6' ) THEN
                        r.n_elim_period_acc_r
                    ELSE
                        r.n_elim_period_sick_r
                END
                ) AS VARCHAR2(100))                                                                           V_ELIMINATION_PERIOD_R	                     --On-priority
            ,R.D_DATE_QP_ENDS_R                                                              D_EST_QUALIFYING_PERIOD_EXP_DATE_R
            ----,payment_dates.D_PAID_DATE_R                                                     V_EST_SS_IND_R
            ,CAST(NULL AS VARCHAR2(100))                                                      V_EST_SS_IND_R
            --26-jan-2024 changes starts
            --,CAST(NULL AS VARCHAR2(100))                                                          V_EXTENDED_DURATION_IND_R
            ,(Case when a.v_lob_type_r IN ( 'LTD', 'VPL' )
              and p.V_CURR_DURATION_R >= '024'   --26/09/24 Changed from p.V_CURR_DURATION_R <= '024'  to p.V_CURR_DURATION_R >= '024'
              and p.V_CURR_DURATION_R <= '036'
              then 'Y' else 'N' end)                                                          V_EXTENDED_DURATION_IND_R
            --26-jan-2024 changes ends
            ,(CASE
                WHEN C.v_policy_prefix_r = 'VAI' THEN
                    D.d_date_of_event_r
                ELSE
                    D.d_date_of_loss_r
             END)                                                                            D_LOSS_DATE_R	                             --On-priority
            ,d.D_RETURN_TO_MOD_WKDT_R                                                        D_MODIFIED_RTW_DATE_R	                     --On-priority
            --,pkg_grp_load_RPT_CLAIM_DTL_R.get_d_mostrecent_service_period_from_r(a.n_claim_sk_r,g.N_CLAIM_COVERAGE_GROUP_SK_R,a.v_lob_type_r)             D_MOST_RECENT_SERVICE_PERIOD_FROM_R	                      --19-JAN-2024 CHANGES              --On-priority
            --,pkg_grp_load_RPT_CLAIM_DTL_R.get_d_mostrecent_service_period_to_r(a.n_claim_sk_r,g.N_CLAIM_COVERAGE_GROUP_SK_R,a.v_lob_type_r)               D_MOST_RECENT_SERVICE_PERIOD_TO_R	         --On-priority--19-JAN-2024 CHANGES
            --,pkg_grp_load_RPT_CLAIM_DTL_R.get_d_nurse_cert_end_date_r(a.n_claim_sk_r)        D_NURSE_CERT_END_DATE_R	                 --On-priority                                                                --19-JAN-2024 CHANGES
            ,payment_dates.most_recent_service_period_from_date                              D_MOST_RECENT_SERVICE_PERIOD_FROM_R--19-JAN-2024 CHANGES --21-Mar-2023 changes remapped from null
            ,payment_dates.most_recent_service_period_to_date                                D_MOST_RECENT_SERVICE_PERIOD_TO_R--19-JAN-2024 CHANGES   --21-Mar-2023 changes remapped from null
            ,CAST(NULL AS DATE)                                                              D_NURSE_CERT_END_DATE_R--19-JAN-2024 CHANGES
            ,u.N_NURSE_CERT_SEQ_R                                                            N_NURSE_CERT_SEQ_R
            ,x.V_CODE_R                                                                      V_OCCUPATION_CODE_R 						 --20-Mar-24 alias name changed from t to x
            ,x.V_DESCRIPTION_R                                                               V_OCCUPATION_DESC_R	                     --20-Mar-24 alias name changed from t to x
            ,d.V_CHILD_GENDER_R                                                              V_PFL_CHILD_GENDER_R	                     --On-priority
            ,d.D_PFL_DOB_R                                                                   D_PFL_DOB_R	                             --On-priority
            ,d.V_MANDATED_FAMILY_MEMBER_R                                                    V_MANDATED_FAMILY_MEMBER_R	                 --On-priority
            ,d.V_LEAVE_REASON_R                                                              V_LEAVE_REASON_R	                         --On-priority
            ,d.D_PFL_DOP_R                                                                   D_PFL_DOP_R	                             --On-priority
            ,CAST(NULL AS DATE)                                                              D_PHYS_CERT_END_DATE_R	--TBD
            ,r.D_PLAN_DUR_DATE_R                                                             D_PLAN_DUR_DATE_R	                         --On-priority
            ,g.D_RETIREMENT_TERMINATION_DAT_R                                                D_RETIREMENT_TERMINATION_DATE_R
            ,d.D_RETURN_TO_WORK_DATE_R                                                       D_RETURN_TO_WORK_DATE_R
            ,CAST(NULL AS VARCHAR2(100))                                                     V_SOCIAL_SECURITY_IND_R
            ,(CASE WHEN d.d_closure_date_r - received_date.Received_date BETWEEN 0 AND 3 THEN '0 - 3'
             WHEN d.d_closure_date_r - received_date.Received_date BETWEEN 4 AND 5 THEN '4 - 5'
             WHEN d.d_closure_date_r - received_date.Received_date BETWEEN 6 AND 7 THEN '6 - 7'
             WHEN d.d_closure_date_r - received_date.Received_date BETWEEN 8 AND 10 THEN  '8 - 10'
             WHEN d.d_closure_date_r - received_date.Received_date > 10 THEN '>10' ELSE 'U' END)   V_TURNAROUND_RANGE_R
            ,(CASE WHEN g.V_CLAIM_COVERAGE_CODE_R like '%WP%' then 'Waiver' else 'Non-Waiver' END) V_WAIVER_IND_R	                             --On-priority
            ,(CASE WHEN A.v_lob_type_r = 'WOP' then g.d_date_closed_r else NULL END)              D_WAIVER_STATUS_DATE_R
            ,r.N_WAIVER_TERMINATION_AGE_R                                                    N_WAIVER_TERMINATION_AGE_R
            ,R.D_WAIVER_TERMINATION_DATE_R                                                   D_WAIVER_TERMINATION_DATE_R
            --,pkg_grp_load_RPT_CLAIM_DTL_R.get_pacs_as_of_date_r                              D_CLAIM_AS_OF_DATE_R	                     --On-priority--19-JAN-2024 CHANGES
           --,CAST(NULL AS DATE)                                                              D_CLAIM_AS_OF_DATE_R	                     --On-priority--19-JAN-2024 CHANGES
            ,get_pacs_as_of_date_r.GD_PACS_AS_OF_DATE_R                                        D_CLAIM_AS_OF_DATE_R
            --,DIM_GRP_BUSOBJ_AUDIT_R.V_METHOD_R                                             V_METHOD_R
            ,CAST(NULL AS VARCHAR2(100))                                                     V_METHOD_R
            --,DIM_GRP_BUSOBJ_AUDIT_R.V_METHOD_STYLE                                         V_METHOD_STYLE_R
            ,CAST(NULL AS VARCHAR2(100))                                                     V_METHOD_STYLE_R
            ,NVL(G.V_CLAIM_IDENTIFIER_R, a.v_claim_number_r)                                 V_CLAIM_IDENTIFIER_R	                     --On-priority
            --16/08/24 changes start
            --,o.MOST_RECENT_ACTIVITY_DATE                                                     D_MOST_RECENT_ACTIVITY_DATE_R
            ,CASE
            WHEN o.MOST_RECENT_ACTIVITY_DATE IS NULL
            THEN d.T_EVENT_TIMESTAMP_R
            ELSE o.MOST_RECENT_ACTIVITY_DATE END AS D_MOST_RECENT_ACTIVITY_DATE_R
            --CAST(NVL(o.MOST_RECENT_ACTIVITY_DATE, d.T_EVENT_TIMESTAMP_R) AS DATE) AS D_MOST_RECENT_ACTIVITY_DATE_R
            --16/08/24 changes End
            --On-priority
            ,received_date.Received_date                                                     D_CLAIM_RECEIVED_DATE_R
            --On-priority
            ,a.FIC_MIS_DATE_R                                                                FIC_MIS_DATE_R
            ,ltd_policy_indicator.ltd_policy_ind                                             V_LTD_POLICY_IND_R	                         --On-priority
            ,a.V_COMPANY_R                                                                   V_CLAIM_COMPANY_R	                         --On-priority
            --,a.V_PRIVACY_INDICATOR_R                                                         V_PRIVACY_INDICATOR_R                     --01-Mar-2024 changes
            ,NVL(UPPER(a.V_PRIVACY_INDICATOR_R),'EXTERNAL')                                                         V_PRIVACY_INDICATOR_R--01-Mar-2024 changes
            --,(R.d_anyocc_start_date_r
            --- pkg_grp_load_RPT_CLAIM_DTL_R.get_pacs_as_of_date_r)                            N_ANY_OCC_DAYS_REMAINING_R --19-JAN-2024 CHANGES

            -- Perf Tuning :: Start : PRC_GRP_UPD_RPT_CLAIM_DTL_R_COLS procedure logic
            --,CAST(NULL AS NUMBER)                                                            N_ANY_OCC_DAYS_REMAINING_R   --19-JAN-2024 CHANGES
            ,(r.D_ANYOCC_START_DATE_R-(sysdate-1))												N_ANY_OCC_DAYS_REMAINING_R
            -- Perf Tuning :: End : PRC_GRP_UPD_RPT_CLAIM_DTL_R_COLS procedure logic

            ,r.D_ANYOCC_DATE_R                                                               D_ANY_OCC_DECISION_DATE_R	                 --On-priority
            --26-Jan-2024 changes starts
            --,r.v_own_occ_period_r                                                            V_ANY_OCC_PERIOD_R
            ,(Case when r.v_own_occ_period_r like '%MOS' then substr(r.v_own_occ_period_R,1,2)
              When r.v_own_occ_period_r like '@%' then substr(r.v_own_occ_period_R,2,2)
              End)                                                                             V_ANY_OCC_PERIOD_R
            --,r.v_own_occ_period_r                                                            V_ANY_OCC_PERIOD_IND_R
            ,(Case when r.v_own_occ_period_r like '%MOS' then 'M'
             When r.v_own_occ_period_r like '@%' then 'A'
             End)                                                                              V_ANY_OCC_PERIOD_IND_R
            --26-Jan-2024 changes ends
            ,r.D_ANYOCC_START_DATE_R                                                           D_ANY_OCC_START_DATE_R	                     --On-priority
            --26-Jan-2024 changes starts
            --,r.v_own_occ_period_r                                                            V_ANY_OCC_OWN_OCC_IND_R
            ,(case when r.v_own_occ_period_r like '@%'  then 'Own Occ Only'
                     when gd_pacs_as_of_date_r <= r.D_ANYOCC_START_DATE_R  then 'Own Occ'
                     when gd_pacs_as_of_date_r > r.D_ANYOCC_START_DATE_R    then 'Any Occ'
                     else 'Unknown'
             end )                                                                            V_ANY_OCC_OWN_OCC_IND_R
            --,r.v_own_occ_period_r                                                            V_OWN_OCC_PERIOD_R
            ,(Case when r.v_own_occ_period_r like '%MOS' then substr(r.v_own_occ_period_R,1,2)
              When r.v_own_occ_period_r like '@%' then substr(r.v_own_occ_period_R,2,2)
              End
              )                                                                               V_OWN_OCC_PERIOD_R
            --,r.v_own_occ_period_r                                                           V_OWN_OCC_PERIOD_IND_R
            ,(Case when r.v_own_occ_period_r like '%MOS' then 'M'
              When r.v_own_occ_period_r like '@%' then 'A'
              End)                                                                            V_OWN_OCC_PERIOD_IND_R
            --26-Jan-2024 changes ends
            ,(CASE WHEN a.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP')
              THEN g.V_CLAIM_COVERAGE_CODE_R
              ELSE b.V_CLAIM_COVERAGE_CODE_R
              END
              )                                                                               V_CLAIM_COVERAGE_CODE_R	                 --On-priority
            ,(CASE WHEN a.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP')
              THEN l.V_PRODUCT_LINE_DESC_R
              ELSE j.V_PRODUCT_LINE_DESC_R
              END
              )                                                          					 V_PRODUCT_LINE_DESC_R	                     --On-priority
            ,g.N_COV_GRP_ID_R                                                                N_COV_GRP_ID_R	                             --On-priority
            ,(CASE WHEN a.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP')
              THEN l.v_basic_product_line_desc_r
              ELSE j.v_basic_product_line_desc_r
              END
              )                                                  								V_CLAIM_COVERAGE_DESC_R	                 --On-priority
            --,DIM_GRP_APPEALS_R.D_RECEIVED_DATE_R                                             D_APPEAL_RECEIVED_DATE_R	                 --On-priority
            /*--30-May-2024 changes starts
            ,CAST(NULL AS DATE)                                                                D_APPEAL_RECEIVED_DATE_R	                 --On-priority
            --,DIM_GRP_APPEALS_R.V_DENIAL_OVERTURN_TYPE_R                                      V_APPEAL_DENIAL_OVERTURN_TYPE_R	         --On-priority
            ,CAST(NULL AS VARCHAR2(100))                                                       V_APPEAL_DENIAL_OVERTURN_TYPE_R	         --On-priority
            --,DIM_GRP_APPEALS_R.V_USER_ID_R                                                   V_APPEALS_ANALYST_R	                     --On-priority
            ,CAST(NULL AS VARCHAR2(100))                                                       V_APPEALS_ANALYST_R	                     --On-priority
            --,DIM_GRP_APPEALS_R.D_REAFFIRMED_DATE_R                                           D_APPEAL_COMPLETED_DATE_R	                 --On-priority
            ,CAST(NULL AS DATE)                                                                D_APPEAL_COMPLETED_DATE_R	                 --On-priority
            --,DIM_GRP_APPEALS_R.N_SOURCE_VERSION_SEQ_NUMBER_R                                 N_APPEAL_SOURCE_VERSION_SEQ_NUMBER_R	                                    --On-priority
            ,cast(null as number)                                                              N_APPEAL_SOURCE_VERSION_SEQ_NUMBER_R	                                    --On-priority
            */
            ,appeal.d_received_date_r                                                          D_APPEAL_RECEIVED_DATE_R
            ,appeal.v_denial_overturn_type_r                                                   V_APPEAL_DENIAL_OVERTURN_TYPE_R
            ,appeal.v_user_id_r                                                                V_APPEALS_ANALYST_R
            ,appeal.d_reaffirmed_date_r                                                        D_APPEAL_COMPLETED_DATE_R
            ,appeal.n_source_version_seq_number_r                                              N_APPEAL_SOURCE_VERSION_SEQ_NUMBER_R
            --30-May-2024 changes ends
            --,pkg_grp_load_RPT_CLAIM_DTL_R.get_d_most_recent_medical_note_date_r(a.n_claim_sk_r)    D_MOST_RECENT_MEDICAL_NOTE_DATE_R	         --On-priority--19-JAN-2024 CHANGES
            --,pkg_grp_load_RPT_CLAIM_DTL_R.get_v_most_recent_medical_note_r(a.n_claim_sk_r)         V_MOST_RECENT_MEDICAL_NOTE_R	             --On-priority--19-JAN-2024 CHANGES
            --,pkg_grp_load_RPT_CLAIM_DTL_R.get_d_most_recent_management_note_date_r(a.n_claim_sk_r) D_MOST_RECENT_MANAGEMENT_NOTE_DATE_R	     --On-priority--19-JAN-2024 CHANGES
            --,pkg_grp_load_RPT_CLAIM_DTL_R.get_v_most_recent_mgmt_note_r(a.n_claim_sk_r)            V_MOST_RECENT_MGMT_NOTE_R	                 --On-priority--19-JAN-2024 CHANGES


            -- Perf Tuning :: End : PRC_GRP_UPD_RPT_CLAIM_DTL_R_COLS procedure logic
            --,CAST(NULL AS DATE)                                                            D_MOST_RECENT_MEDICAL_NOTE_DATE_R -- Perf Tuning
            --,CAST(NULL AS VARCHAR2(4000))                                                  V_MOST_RECENT_MEDICAL_NOTE_R	-- Perf Tuning
            --,CAST(NULL AS DATE)                                                            D_MOST_RECENT_MANAGEMENT_NOTE_DATE_R-- Perf Tuning
            --,CAST(NULL AS VARCHAR2(4000))                                                  V_MOST_RECENT_MGMT_NOTE_R -- Perf Tuning

            ,med_note.d_most_recent_medical_note_date_r                             D_MOST_RECENT_MEDICAL_NOTE_DATE_R-- Perf Tuning
            ,med_note.v_most_recent_medical_note_r                                           V_MOST_RECENT_MEDICAL_NOTE_R-- Perf Tuning
            ,mgmt_note.d_most_recent_management_note_date_r                                  D_MOST_RECENT_MANAGEMENT_NOTE_DATE_R-- Perf Tuning
            ,mgmt_note.v_most_recent_mgmt_note_r                                             V_MOST_RECENT_MGMT_NOTE_R-- Perf Tuning

            -- Perf Tuning :: End : PRC_GRP_UPD_RPT_CLAIM_DTL_R_COLS procedure logic

            ,f.D_SS_DEP_AWARD_EFF_DATE_R                                                     D_SS_DEP_AWARD_EFF_DATE_R
            ,f.V_SS_DEPENDENT_STATUS_R                                                       V_SS_DEPENDENT_STATUS_R
            ,f.D_SS_DEP_TERM_DATE_R                                                          D_SS_DEP_TERM_DATE_R
            ,f.V_SS_DEP_AWARD_TYPE_R                                                         V_SS_DEP_AWARD_TYPE_R
            ,f.v_ss_dep_pursue_flag_r                                                        V_SS_DEP_PURSUE_IND_R	                     --On-priority
            ,f.D_CHANGE_DATE_R                                                               D_SS_MOST_RECENT_UPDATE_DATE_R	             --On-priority
            ,f.D_SS_PRIMARY_EFF_DATE_R                                                       D_SS_PRIMARY_EFF_DATE_R
            ,f.V_SS_STATUS_DESCRIPTION_R                                                     V_SS_STATUS_DESCRIPTION_R
            ,f.D_SS_CLOSED_TERM_DATE_R                                                       D_SS_CLOSED_TERM_DATE_R
            ,f.V_SS_PRIMARY_AWARD_TYPE_R                                                     V_SS_PRIMARY_AWARD_TYPE_R
            --,f.v_ss_pursue_flag_r                                                            V_SS_PRIMARY_PURSUE_IND_R	                 --On-priority --26-dEC-2023 CHANGES
            ,(case  when upper(F.V_SS_PURSUE_FLAG_R) in ('INSURED PURSUING', 'YES') then 'Y' else case  when upper(F.V_SS_PURSUE_FLAG_R) = 'NO' then 'N' else NULL end  end  ) V_SS_PRIMARY_PURSUE_IND_R --On-priority --26-dEC-2023 CHANGES
            --,f.V_SS_REJECT_REASON_R                                                          V_SS_REJECT_REASON_CODE_R	                 --On-priority --26-dEC-2023 CHANGES
            ,substr(V_SS_REJECT_REASON_R , 1 , instr(V_SS_REJECT_REASON_R , '-') - 1)        V_SS_REJECT_REASON_CODE_R                   --On-priority --26-dEC-2023 CHANGES
            ,f.V_SS_REJECT_REASON_R                                                          V_SS_REJECT_REASON_R
            --26-Jan-2024 changes starts
            --,CAST(NULL AS VARCHAR2(100))                                                     V_CLAIM_STATUS_CATEGORY_R
            ,(Case when
                     (CASE WHEN a.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP')
                      THEN g.V_REASON_CODE_R
                      else D.V_CLAIM_STATUS_REASON_CODE_R
                      end
                      )   >= '60'
                      THEN  'CLOSED'
                when (CASE WHEN a.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP')
                      THEN g.V_REASON_CODE_R
                      else D.V_CLAIM_STATUS_REASON_CODE_R
                      end
                      )   >= '50'
                      AND (CASE WHEN a.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP')
                          THEN g.V_REASON_CODE_R
                          else D.V_CLAIM_STATUS_REASON_CODE_R
                          end
                          )   <  '60'
                      THEN  'RESISTING'
                when (CASE WHEN a.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP')
                      THEN g.V_REASON_CODE_R
                      else D.V_CLAIM_STATUS_REASON_CODE_R
                      end
                      )   >= '40'
                      AND (CASE WHEN a.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP')
                          THEN g.V_REASON_CODE_R
                          else D.V_CLAIM_STATUS_REASON_CODE_R
                          end
                          )   <  '50'
                      THEN  'OPEN, NO LIABILITIES'
                when (CASE WHEN a.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP')
                      THEN g.V_REASON_CODE_R
                      else D.V_CLAIM_STATUS_REASON_CODE_R
                      end
                      )   >= '30'
                      AND (CASE WHEN a.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP')
                           THEN g.V_REASON_CODE_R
                           else D.V_CLAIM_STATUS_REASON_CODE_R
                           end
                      )   <  '40'
                     THEN 'ACTIVE'
                when (CASE WHEN a.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP')
                      THEN g.V_REASON_CODE_R
                      else D.V_CLAIM_STATUS_REASON_CODE_R
                      end
                      )   < '30'
                     THEN  'OPEN INCOMPLETE'
             ELSE
                NULL
             END)                                                                            V_CLAIM_STATUS_CATEGORY_R
            --26-Jan-2024 changes ends
            ,(CASE WHEN a.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP')
            THEN g.V_REASON_CODE_R
            else D.V_CLAIM_STATUS_REASON_CODE_R
            end
            )                                                                                  V_CLAIM_STATUS_CODE_R	                     --On-priority
            ,
            -- 04/09/24 Changes start
            /*(
            case when a.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP')
            then
            CASE WHEN g.V_REASON_CODE_R  >= '60'
              THEN  'CLOSED'
              WHEN g.V_REASON_CODE_R >= '50'
                AND g.V_REASON_CODE_R <  '60'
              THEN  'RESISTING'
              WHEN g.V_REASON_CODE_R >= '40'
                AND g.V_REASON_CODE_R <  '50'
              THEN  'OPEN, NO LIABILITIES'
              WHEN g.V_REASON_CODE_R >= '30'
                AND g.V_REASON_CODE_R <  '40'
              THEN 'ACTIVE'
              WHEN g.V_REASON_CODE_R < '30'
              THEN  'OPEN INCOMPLETE'
              end
            else
            CASE WHEN d.V_CLAIM_STATUS_REASON_CODE_R >= '60'
              THEN  'CLOSED'
              WHEN d.V_CLAIM_STATUS_REASON_CODE_R >= '50'
                AND d.V_CLAIM_STATUS_REASON_CODE_R <  '60'
              THEN  'RESISTING'
              WHEN d.V_CLAIM_STATUS_REASON_CODE_R >= '40'
                AND d.V_CLAIM_STATUS_REASON_CODE_R <  '50'
              THEN  'OPEN, NO LIABILITIES'
              WHEN d.V_CLAIM_STATUS_REASON_CODE_R >= '30'
                AND d.V_CLAIM_STATUS_REASON_CODE_R <  '40'
              THEN 'ACTIVE'
              WHEN d.V_CLAIM_STATUS_REASON_CODE_R < '30'
              THEN  'OPEN INCOMPLETE'
              ELSE
               NULL
             END
             end)                                                             V_CLAIM_STATUS_DESC_R	                     --On-priority
             */
            case when a.v_lob_type_r in ('LIFE', 'NONS', 'WOP')
            then nvl(claim_status_life.V_CLAIM_STATUS_DESC_R, sales_status_life.V_ORIG_CLAIM_STATUS_DESC_R)
            else COALESCE(claim_status_disability.V_CLAIM_STATUS_DESC_R,sales_status_disability.V_ORIG_CLAIM_STATUS_DESC_R,D.V_CLAIM_STATUS_REASON_DESC_R)  end V_CLAIM_STATUS_DESC_R
    -- 04/09/24 Changes End
            ,CAST(p.D_CLAIM_STATUS_CODE_EFF_DATE_R AS DATE)                                                D_CLAIM_STATUS_EFF_DATE_R	                 --On-priority
            ,CAST(p.D_LAST_IN_STATUS_46_DATE_R      AS DATE)                                              D_LAST_IN_STATUS_46_DATE_R	                 --On-priority
            ,p.V_PRIOR_CLAIM_CLOSURE_CODE_R                                                  V_PRIOR_CLAIM_STATUS_CLOSURE_CODE_R
            ,P.V_PRIOR_CLAIM_STATUS_CODE_R                                                   V_PRIOR_CLAIM_STATUS_CODE_R	             --On-priority
            ,/*case when a.v_lob_type_r in ('LIFE', 'NONS', 'WOP')
             then sales_status_life.V_NEW_CLAIM_STATUS_DESC_R
             else sales_status_disability.V_NEW_CLAIM_STATUS_DESC_R  end                             V_SALES_CLAIM_STATUS_DESC_R	             --On-priority*/
            case when a.v_lob_type_r in ('LIFE', 'NONS', 'WOP')
            then nvl(sales_status_life.V_NEW_CLAIM_STATUS_DESC_R, sales_status_life.V_ORIG_CLAIM_STATUS_DESC_R)
            --else nvl(sales_status_disability.V_NEW_CLAIM_STATUS_DESC_R,sales_status_disability.V_ORIG_CLAIM_STATUS_DESC_R)  end                             V_SALES_CLAIM_STATUS_DESC_R	             --On-priority --03-May-2024 changes
            else COALESCE(sales_status_disability.V_NEW_CLAIM_STATUS_DESC_R,sales_status_disability.V_ORIG_CLAIM_STATUS_DESC_R,D.V_CLAIM_STATUS_REASON_DESC_R)  end                             V_SALES_CLAIM_STATUS_DESC_R	             --On-priority --03-May-2024 changes
            ,p.V_CURR_CLAIM_STATUS_CODE_R                                                    V_CURR_CLAIM_STATUS_CODE_R	                 --On-priority
            ,CAST(NULL AS VARCHAR2(100))                                                    V_CLAIM_TYPE_R	                             --On-priority - tbd
            ,CLAIM_TIER_WFAM_MV_TBL.D_CREATED_DATE_R_TIER                                  D_TIER_CREATED_DATE_R	                     --On-priority
            ,CLAIM_TIER_WFAM_MV_TBL.D_CREATED_DATE_R_WFAM                                    D_WFAM_CODE_CREATED_DATE_R	                 --On-priority
            ,CLAIM_TIER_WFAM_MV_TBL.V_TIER_R                                                 V_TIER_R	                                 --On-priority
            ,CLAIM_TIER_WFAM_MV_TBL.V_WFAM_R                                                 V_WFAM_R	                                 --On-priority
            ,CLAIM_TIER_WFAM_MV_TBL.D_PRD_R                                                      D_PRD_R
            --26-Jan-2024 changes starts
            --,CLAIM_TIER_WFAM_MV_TBL.D_PRD_R                                                      D_PRD_DAYS_REMAINING_R
            ,(CLAIM_TIER_WFAM_MV_TBL.D_PRD_R -get_pacs_as_of_date_r.GD_PACS_AS_OF_DATE_R)                                D_PRD_DAYS_REMAINING_R
            --26-Jan-2024 changes ends
            ,case when a.v_lob_type_r in ('LIFE', 'NONS', 'WOP')
            then DIM_GRP_REF_TIER_R_life.V_ACCOMMODATIONS_NEEDED_R
            else        DIM_GRP_REF_TIER_R_disability.V_ACCOMMODATIONS_NEEDED_R    end                      V_ACCOMMODATIONS_NEEDED_R
            ,case when a.v_lob_type_r in ('LIFE', 'NONS', 'WOP')
            then DIM_GRP_REF_TIER_R_life.V_CLINICAL_VOC_ENGAGEMENT_R
            else        DIM_GRP_REF_TIER_R_disability.V_CLINICAL_VOC_ENGAGEMENT_R  end                        V_CLINICAL_VOC_ENGAGEMENT_R
            ,
            case when a.v_lob_type_r in ('LIFE', 'NONS', 'WOP')
            then DIM_GRP_REF_TIER_R_life.V_TIER_DESCRIPTION_R
            else        DIM_GRP_REF_TIER_R_disability.V_TIER_DESCRIPTION_R  end
                                                                                            V_TIER_DESCRIPTION_R	                     --On-priority
            ,case when a.v_lob_type_r in ('LIFE', 'NONS', 'WOP')
            then DIM_GRP_REF_TIER_R_life.N_TIER_NUM_R
            else        DIM_GRP_REF_TIER_R_disability.N_TIER_NUM_R  end     				N_TIER_NUM_R
            --26-Jan-2024 changes starts
            --,CAST(NULL AS VARCHAR2(100))                                                     V_RECOVERY_EXPECTATIONS_R
            ,(case when a.v_lob_type_r in ('LIFE', 'NONS', 'WOP')
              then DIM_GRP_REF_TIER_R_life.V_RECOVERY_EXPECTATIONS_r
              else        DIM_GRP_REF_TIER_R_disability. V_RECOVERY_EXPECTATIONS_r
              end)                                                                             V_RECOVERY_EXPECTATIONS_R
            --26-Jan-2024 changes ends
            ,DIM_GRP_VOCREHAB_R.V_VOC_REHAB_STATUS_R                                         V_VOC_REHAB_STATUS_R	        --26-Jan-2024 changes
            ,DIM_GRP_VOCREHAB_R.V_VOC_CASE_LASTNAME_R                                        V_VOC_REHAB_MGR_NAME_R	        --26-Jan-2024 changes
            ,DIM_GRP_VOCREHAB_R.V_SPECIALIST_R                                               V_VOC_REHAB_SPECIALIST_R	    --26-Jan-2024 changes
            ,CAST(NULL AS VARCHAR2(100))                                                     V_SERVICE_REQUESTED_OTHER_R
            ,CAST(NULL AS VARCHAR2(100))                                                     V_SERVICE_REQUESTED_R
            ,DIM_GRP_VOCREHAB_R.V_VOC_REHAB_OUTCOME_R                                        V_VOC_REHAB_OUTCOME_R	        --26-Jan-2024 changes
            ,DIM_GRP_VOCREHAB_R.V_REHAB_STATUS_R                                             V_VOC_REHAB_ACTIVE_STATUS_R	--26-Jan-2024 changes
            ,DIM_GRP_VOCREHAB_R.D_TSA_DATE_R                                                 D_TSA_DATE_R	                --26-Jan-2024 changes
            ,C.V_POLICY_NUMBER_R || '-' || q.V_SUBGROUP_ID_R                                 V_LOCATION_NUMBER_R	                      --On-priority
            ,q.V_CORRESPONDENT_NAME_R                                                        V_CORRESPONDENT_NAME_R
            ,q.V_SUBGROUP_ADDRESSLINE1_R                                                     V_SUBGROUP_ADDRESSLINE1_R
            ,q.V_SUBGROUP_ADDRESSLINE2_R                                                     V_SUBGROUP_ADDRESSLINE2_R
            ,q.V_SUBGROUP_CITY_R                                                             V_SUBGROUP_CITY_R
            ,q.V_SUBGROUP_ID_R                                                               V_SUBGROUP_ID_R	                          --On-priority
            ,q.V_SUBGROUP_NAME_R                                                             V_SUBGROUP_NAME_R	                          --On-priority
            ,q.V_SUBGROUP_POSTALZIP_R                                                        V_SUBGROUP_POSTALZIP_R
            ,q.V_SUBGROUP_PROVSTATE_R                                                        V_SUBGROUP_PROVSTATE_R	                       --On-priority
            ,gc_main_loadedby                                            v_last_modified_by_r
            ,systimestamp                                                  t_creation_date_r
            ,gc_main_loadedby                                            v_created_by_r
            ,systimestamp                                                  t_last_modified_date_r
            ,gn_current_month                                            n_yearmonth_r
            ,'Y'                                                         v_rpt_active_status_r
            ,gn_sysdt_batchid                                            n_batch_id_r
            ,d.V_EXAMINER_LOGIN_ID_R                                     V_EXAMINER_ID_R
            ,d.V_EXAMINER_DESC_R                                         V_EXAMINER_NAME_R
            ,s.D_HIRE_DATE_R                                             D_HIRE_DATE_R
            --26-DEC-2023 CHANGES STARTS
            ,F.d_ss_council_start_date_r
            ,F.d_ss_appeal_end_date_r
            ,F.d_ss_court_start_date_r
            ,F.d_ss_court_appeal_end_date_r
            ,F.d_ss_hearing_start_date_r
            ,F.d_ss_hearing_end_date_r
            ,F.d_ss_init_filing_start_date_r
            ,F.d_ss_init_filing_end_date_r
            ,F.d_ss_reconsider_start_date_r
            ,F.d_ss_reconsider_end_date_r
            ,(case  when F.N_SS_HARDSHIP_IND_R = '0' then 'N' else 'Y' end ) V_SS_HARDSHIP_IND_R
            --26-DEC-2023 CHANGES ENDS
             --,cast(nvl(n.D_START_DATE_R,m.D_START_DATE_R) as date)     D_WORKSHEET_START_DATE_R
            --,cast(nvl(n.D_END_DATE_R,m.D_END_DATE_R)     as date) D_WORKSHEET_END_DATE_R


            ,CASE   WHEN n.D_START_DATE_R IS NULL
                    THEN
                        CASE
                            WHEN LENGTH(m.D_START_DATE_R) IN (31,9)
                            THEN TO_DATE(SUBSTR(m.D_START_DATE_R,1,9),'DD-MON-YY')
                            ELSE CAST(m.D_START_DATE_R AS DATE)
                         END
                    ELSE
                        CASE
                            WHEN LENGTH(n.D_START_DATE_R) IN (31,9)
                            THEN TO_DATE(SUBSTR(n.D_START_DATE_R,1,9),'DD-MON-YY')
                            ELSE CAST(n.D_START_DATE_R AS DATE)
                         END
             END AS D_WORKSHEET_START_DATE_R

            ,CASE   WHEN n.D_END_DATE_R IS NULL
                    THEN
                        CASE
                            WHEN LENGTH(m.D_END_DATE_R) IN (31,9)
                            THEN TO_DATE(SUBSTR(m.D_END_DATE_R,1,9),'DD-MON-YY')
                            ELSE CAST(m.D_END_DATE_R AS DATE)
                         END
                    ELSE
                        CASE
                            WHEN LENGTH(n.D_END_DATE_R) IN (31,9)
                            THEN TO_DATE(SUBSTR(n.D_END_DATE_R,1,9),'DD-MON-YY')
                            ELSE CAST(n.D_END_DATE_R AS DATE)
                         END
             END AS  D_WORKSHEET_END_DATE_R

            ,a.v_lob_type_r --19-JAN-2024 CHANGES
            --23-jAN-2024 changes starts
            ,A.V_SOURCE_SYSTEM_NAME_R

            -- Perf Tuning :: Start : PRC_GRP_UPD_RPT_CLAIM_DTL_R_COLS procedure logic

            --,CAST(NULL AS NUMBER)                                 N_CURR_BENEFIT_PERIOD_DAYS_R -- Perf Tuning
            --,CAST(NULL AS NUMBER)                                 N_TOTAL_BENEFIT_PERIOD_DAYS_R -- Perf Tuning

            ,CURBEN.N_CURR_BENEFIT_PERIOD_DAYS_R					N_CURR_BENEFIT_PERIOD_DAYS_R
            ,TOTBEN.N_TOTAL_BENEFIT_PERIOD_DAYS_R					N_TOTAL_BENEFIT_PERIOD_DAYS_R

            -- Perf Tuning :: End : PRC_GRP_UPD_RPT_CLAIM_DTL_R_COLS procedure logic

            --23-jAN-2024 changes ends
            --26-jAN-2024 changes starts
            ,COALESCE(s.n_basic_insured_salary_r,b.n_basic_insured_salary_r)                AS N_BASIC_INSURED_SALARY_R    --446024
            ,COALESCE(s.v_basic_insured_salary_ind_r ,b.v_salaryindicator_r)                AS V_BASIC_INSURED_SALARY_IND_R  --446024
            --26-jAN-2024 changes ends
            --31-jAN-2024 changes starts

            -- Perf Tuning :: Start : PRC_GRP_UPD_RPT_CLAIM_DTL_R_COLS procedure logic

            ,clm_offset_mv.n_rehab_offset_amt_088_r         	as  n_rehab_offset_amt_088_r
            ,clm_offset_mv.v_rehab_offset_ind_088_r      		as  v_rehab_offset_ind_088_r
            ,clm_offset_mv.n_workers_comp_offset_amt_083_r   	as  n_workers_comp_offset_amt_083_r
            ,clm_offset_mv.n_other_offset_amt_r                 as  n_other_offset_amt_r

            /*
            ,CAST(NULL AS NUMBER)                                 n_rehab_offset_amt_088_r
            ,CAST(NULL AS NUMBER)                                 v_rehab_offset_ind_088_r
            ,CAST(NULL AS NUMBER)                                 n_workers_comp_offset_amt_083_r
            ,CAST(NULL AS NUMBER)                                 n_other_offset_amt_r
            */

            -- Perf Tuning :: End : PRC_GRP_UPD_RPT_CLAIM_DTL_R_COLS procedure logic

            ,d.v_leave_type_r                                     v_pfl_leave_type_r
            ,d.v_license_num_r                                    v_pfl_license_number_r
            --31-jAN-2024 changes ends
            --20-Feb-2024 changes ends
            ,CAST(NULL AS date) d_closed_month_start_date_r
            ,CAST(NULL AS date) d_closed_month_end_date_r
            --20-Feb-2024 changes ends
            --15-Jun-2024 changes starts
            ,claim_prior_approved_mv.V_APPEAL_IND_R
            ,claim_prior_approved_mv.V_APPEAL_RESULT_STATUS_CODE_R
            ,claim_prior_approved_mv.D_APPEAL_RESULT_STATUS_CODE_EFF_DATE_R,
            --15-Jun-2024 changes ends

             --21/Jun/2024 - Changes start
              T4418483.V_DESCRIPTION_R  AS V_APPEAL_ANALYST_NAME_r         ,
              appeal.V_STATUS_CODE_R    AS V_APPEAL_STATUS_CODE_R          ,
              CASE
                WHEN m.V_RPT_WORKSHEET_INDICATOR_R IS NULL
                THEN n.V_RPT_WORKSHEET_INDICATOR_R
                ELSE m.V_RPT_WORKSHEET_INDICATOR_R
              END AS   V_RPT_WORKSHEET_INDICATOR_R     ,

              CASE
                WHEN m.N_VERSION_R IS NULL
                THEN n.N_VERSION_R
                ELSE m.N_VERSION_R
              END AS   N_WORKSHEET_NUMBER_R            ,

              CASE
                WHEN m.V_WORKSHEET_STATUS_R IS NULL
                THEN n.V_WORKSHEET_STATUS_R
                ELSE m.V_WORKSHEET_STATUS_R
              END AS   V_WORKSHEET_STATUS_R            ,

              CASE
                WHEN m.N_WORKSHEET_SEQ_NBR_OBJECTNM_R IS NULL
                THEN n.N_WORKSHEET_SEQ_NBR_OBJECTNM_R
                ELSE m.N_WORKSHEET_SEQ_NBR_OBJECTNM_R
              END AS   N_WORKSHEET_SEQ_NBR_OBJECTNM_R,

              CASE WHEN a.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP')
              THEN l.v_coverage_type_code_r
              ELSE j.v_coverage_type_code_r
              END v_coverage_type_code_r,
              m.N_MAX_BENEFIT_R AS N_MAX_BENEFIT_R  ,
              m.N_MINIMUM_BENEFIT_R  as N_MINIMUM_BENEFIT_R  ,
            --21/Jun/2024 - Changes end
            --26/08/24 Changes Start
            case when A.V_SOURCE_SYSTEM_NAME_R = 'PACS' and diag.PRIMARY_DIAG_CODE in ('V70', 'V70,.0', 'V70,0','V70.0','V70.7') then 'Wellness'
            when  A.V_SOURCE_SYSTEM_NAME_R = 'PACS' and g.V_CLAIM_COVERAGE_CODE_R = 'VHI' then 'Hospital Indemnity'
            when  A.V_SOURCE_SYSTEM_NAME_R = 'PACS' and  g.V_CLAIM_COVERAGE_CODE_R = 'VAI' then 'Accident'
            when  A.V_SOURCE_SYSTEM_NAME_R = 'PACS' and g.V_CLAIM_COVERAGE_CODE_R = 'VCI' then 'Critical Illness'
            when g.V_CLAIM_COVERAGE_CODE_R in ('VAI', 'VCI', 'VHI') and  A.V_SOURCE_SYSTEM_NAME_R = 'CV' then  d.v_benefittype_r else null end as V_CLAIM_WELLNESS_IND_R   --27/11/24--changed to the d.v_benefittype_r from s.V_CEASED_WORK_REASON_R
            --26/08/24 Changes End
            ,wavier_ind.V_HAS_ASSOCIATED_WAIVER_IND_R  V_HAS_ASSOCIATED_WAIVER_IND_R--11/09/24 CHANGES
            ,ltd_ind.v_has_associated_ltd_ind_r  V_HAS_ASSOCIATED_LTD_IND_R   --11/09/24 CHANGES
            --11/09/24 changes start
            ,d.V_CLAIM_STATUS_REASON_DESC_R  AS V_CLAIM_STATUS_REASON_DESC_R
            --11/09/24 changes end
            --23/09/24 Changes Start
            ,CAST(NULL AS DATE)          D_CLAIM_DECISION_DATE_R --will be populated in update proc
            ,CAST(NULL AS NUMBER)        N_CLAIM_DECISION_DAYS_R --will be populated in update proc
            ,CAST(NULL AS VARCHAR2(300)) V_TURNAROUND_RANGE1_R   --will be populated in update proc
            -- 23/09/24 Changes End
            ,d.V_OVERRIDE_NAME_R
            ,d.D_RECORD_START_DATE_R
            ,d.D_RECORD_END_DATE_R
			-- 26-march-2026 added as per FDM reqt start
            , P.D_DURATION_EFF_DATE_R                                  						AS D_DURATION_EFF_DATE_R
            , P.D_ELIMINATION_EFF_DATE_R                               						AS D_ELIMINATION_EFF_DATE_R
            , P.D_GROSS_BEN_EFF_DATE_R                                 						AS D_GROSS_BEN_EFF_DATE_R
            , P.D_LOSS_DATE_EFF_DATE_R                                 						AS D_LOSS_DATE_EFF_DATE_R
            , F.N_SS_PRIMARY_AWARD_AMOUNT_R							   						AS N_SS_PRIMARY_AWARD_AMOUNT_R
            , F.D_SS_EST_START_DATE_R      							   						AS D_SS_EST_START_DATE_R
            , F.D_SS_AWARDED_START_DATE_R  							   						AS D_SS_AWARDED_START_DATE_R
            , F.V_SS_PURSUING_REMARKS_R    							   						AS V_SS_PURSUING_REMARKS_R
            , F.V_SS_DEP_OFFSET_ALLOWED_R  							   						AS V_SS_DEP_OFFSET_ALLOWED_R
            , D.V_DOT_CODE_PRIMARY_DESC_R  							   						AS V_DOT_CODE_PRIMARY_DESC_R
            , D.V_DOT_CODE_PRIMARY_R       							   						AS V_DOT_CODE_PRIMARY_R
            --, FCDR.D_DISBURSE_DATE_R        D_DISBURSE_DATE_R
            , P.D_PRIMARY_DIAG_EFF_DATE_R    												AS D_PRIMARY_DIAG_EFF_DATE_R
            ,(CASE WHEN COALESCE(r.n_elim_period_r,n_elim_period_acc_r, n_elim_period_sick_r,0)<>0 and a.v_lob_type_r = 'WOPCLAIM'
										THEN 'M'
                    WHEN COALESCE(r.n_elim_period_r,n_elim_period_acc_r, n_elim_period_sick_r,0)<>0
										THEN 'D'
                    ELSE null
                END )																	 	AS V_ELIMINATION_IND_R
            , P.D_CHECK_NET_BEN_EFF_DATE_R              									AS D_CHECK_NET_BEN_EFF_DATE_R
			-- 26-march-2026 added as per FDM reqt reqt
             from
                (
                    SELECT * FROM ATOMIC.dim_grp_claim_dir_r
                    WHERE
                        dim_grp_claim_dir_r.V_ACTIVE_STATUS_R = 'Y'
                -- Perf Tuning :: Start : Incremental Data Load
                    and dim_grp_claim_dir_r.t_last_modified_date_r >
                        (   SELECT max(END_DATE)
                            FROM ATOMIC.SSL_PACKAGE_MILESTONE_TABLE
                            WHERE JOB_NAME='PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC'
                        )
                -- Perf Tuning :: End : Incremental Data Load

                ) a
            left join ATOMIC.dim_grp_claim_coverage_r b
            on a.n_claim_sk_r = b.n_claim_sk_r
            and b.v_active_status_r = 'Y'
            left join ATOMIC.dim_grp_claim_coverage_group_r g
            on b.n_claim_coverage_sk_r = g.n_claim_coverage_sk_r
            and g.v_active_status_r = 'Y'
            --15-Jun-2024 changes starts
            left join ATOMIC.dim_grp_claim_prior_status_r_approved_mv_ssl claim_prior_approved_mv
            on a.n_claim_sk_r=claim_prior_approved_mv.n_claim_sk_r
            and b.n_claim_coverage_sk_r=claim_prior_approved_mv.n_claim_coverage_sk_r
            and g.n_claim_coverage_group_sk_r=claim_prior_approved_mv.n_claim_coverage_group_sk_r
            --15-Jun-2024 changes ends
            left join ATOMIC.DIM_CLAIM_STATUS_DESC_R sales_status_life
            on g.v_reason_code_r = sales_status_life.V_CLAIM_STATUS_CODE_R
            and sales_status_life.v_active_status_r = 'Y'
                    left join ATOMIC.DIM_CLAIM_STATUS_R claim_status_life
            on g.v_reason_code_r = claim_status_life.V_CLAIM_STATUS_CODE_R
            and claim_status_life.v_active_status_r = 'Y'
            left join ATOMIC.dim_grp_policy_dir_r c
            on a.n_policy_sk_r = c.n_policy_sk_r
            and c.v_active_status_r = 'Y'
            left join ATOMIC.dim_grp_claim_detail_r d
            on a.n_claim_sk_r = d.n_claim_sk_r
            and d.v_active_status_r = 'Y'
            left join ATOMIC.DIM_CLAIM_STATUS_DESC_R sales_status_disability
            on d.v_claim_status_reason_code_r = sales_status_disability.V_CLAIM_STATUS_CODE_R
            and sales_status_disability.v_active_status_r = 'Y'
                    left join ATOMIC.DIM_CLAIM_STATUS_R claim_status_disability
            on d.v_claim_status_reason_code_r = claim_status_disability.V_CLAIM_STATUS_CODE_R
            and claim_status_disability.v_active_status_r = 'Y'
            left join ATOMIC.dim_employee_r e
            on d.V_EXAMINER_LOGIN_ID_R = e.V_EMPLOYEE_LOGIN_ID_R
            and e.V_BUSINESS_UNIT_R = 'Claims'
            --30-May-2024 changes starts
            Left Join
            (SELECT *
               FROM
                ATOMIC.dim_grp_appeals_r a
              WHERE a.v_active_status_r = 'Y'
              AND a.n_source_version_seq_number_r
               = (SELECT MAX(N_SOURCE_VERSION_SEQ_NUMBER_R) N_SOURCE_VERSION_SEQ_NUMBER_R
                    FROM ATOMIC.dim_grp_appeals_r b
                 WHERE b.n_source_system_key_r = a.n_source_system_key_r
                  and b.v_active_status_r = 'Y')
              and a.n_claim_sk_r <>-1
              ) appeal
            on d.n_claim_sk_r=appeal.n_claim_sk_r
            --30-May-2024 changes ends
            left join (--SELECT   max(n_cust_party_sk_r)n_cust_party_sk_r, n_policy_sk_r, n_version_number_r
                       --from  fct_grp_policy_r group by n_policy_sk_r,n_version_number_r
                       --SELECT n_cust_party_sk_r, n_policy_sk_r, n_version_number_r from
                       ATOMIC.FCT_GRP_POLICY_R_MV_SSL
                       ) f1
            on c.n_policy_sk_r = f1.n_policy_sk_r
            and c.n_policy_version_number_r = f1.n_version_number_r
            left join ATOMIC.FCT_CLAIM_SOCIALSECURITY_INC_R f
            on a.n_claim_sk_r = f.n_claim_sk_r
            left join (--SELECT   min(n_product_sk_r)n_product_sk_r, n_claim_sk_r,v_claim_coverage_code_r
                       --from mvw_product_sk_lookup group by n_claim_sk_r,v_claim_coverage_code_r
                      --SELECT n_product_sk_r, n_claim_sk_r,v_claim_coverage_code_r from
                      ATOMIC.MVW_PRODUCT_SK_LOOKUP_MIN_MV_SSL
                      ) h
            on h.n_claim_sk_r = a.n_claim_sk_r
            and h.v_claim_coverage_code_r = nvl(b.v_claim_coverage_code_r,g.v_claim_coverage_code_r) -------nvl added on 29/05/24 @Chandra
            left join ATOMIC.dim_grp_product_r j
            on h.n_product_sk_r = j.n_product_sk_r
            left join (--SELECT  min(n_product_sk_r)n_product_sk_r, n_claim_sk_r,v_claim_coverage_code_r
                       -- from mvw_product_sk_lookup group by n_claim_sk_r,v_claim_coverage_code_r
                       --SELECT n_product_sk_r, n_claim_sk_r,v_claim_coverage_code_r from
                       ATOMIC.MVW_PRODUCT_SK_LOOKUP_MIN_MV_SSL
                      ) i
            on i.n_claim_sk_r = a.n_claim_sk_r
            and i.v_claim_coverage_code_r = g.v_claim_coverage_code_r
            left join ATOMIC.dim_grp_product_r l
            on l.n_product_sk_r = i.n_product_sk_r
            left join ATOMIC.FCT_GRP_WORKSHEET m
            on m.n_claim_sk_r = a.n_claim_sk_r
            --and m.n_claim_coverage_sk_r = m.n_claim_coverage_sk_r--18-Jan-2024 changes
            and m.n_claim_coverage_sk_r = b.n_claim_coverage_sk_r--18-Jan-2024 changes
            and m.V_RPT_WORKSHEET_INDICATOR_R  = 'Y' and  m.v_source_system_name_r='PACS'
            left join ATOMIC.FCT_GRP_WORKSHEET n
            on n.n_claim_sk_r = a.n_claim_sk_r
            --and n.n_claim_coverage_group_sk_r = n.n_claim_coverage_group_sk_r --18-Jan-2024 changes
            and n.n_claim_coverage_group_sk_r = g.n_claim_coverage_group_sk_r --18-Jan-2024 changes
            and n.V_RPT_WORKSHEET_INDICATOR_R  = 'Y' and  n.v_source_system_name_r='PACS'
			left join (SELECT * FROM (
				SELECT D_BENEFIT_START_R,
				n_taxable_override_pct_r ,
				n_claim_sk_r,
				n_claim_coverage_sk_r,
				V_RPT_WORKSHEET_INDICATOR_R,
				D_START_DATE_R,
				D_END_DATE_R,
				N_VERSION_R,
				V_WORKSHEET_STATUS_R,
				N_WORKSHEET_SEQ_NBR_OBJECTNM_R,
				N_MAX_BENEFIT_R,
				N_MINIMUM_BENEFIT_R,
                v_source_system_name_r,
               ROW_NUMBER() OVER (PARTITION BY n_claim_coverage_sk_r, n_claim_sk_r ORDER BY n_batch_id_r DESC) AS rn
        FROM   atomic.FCT_GRP_WORKSHEET where v_source_system_name_r='CV'
    )
			WHERE rn = 1) mcv
			ON  mcv.n_claim_sk_r = a.n_claim_sk_r
			and mcv.n_claim_coverage_sk_r = b.n_claim_coverage_sk_r
            left join ATOMIC.CLAIM_ACTIVITY_DATE_MV_TBL o
            on o.n_claim_sk_r = a.n_claim_sk_r
            and o.V_CLAIM_NUMBER_R = a.V_CLAIM_NUMBER_R
            left join ATOMIC.VW_DIM_GRP_CLAIM_PRIOR_STATUS_R_MV_SSL p
            on p.n_claim_sk_r = a.n_claim_sk_r
            and p.n_claim_coverage_sk_r = b.n_claim_coverage_sk_r
            and p.n_claim_coverage_group_sk_r = g.n_claim_coverage_group_sk_r
            left join ATOMIC.DIM_GRP_CLAIM_DETAIL_SUBGROUP_LOOKUP q
            on a.v_claim_number_r = q.v_claim_number_r
            and q.N_SOURCE_SYSTEM_KEY_R is not null--17-May-2024 changes
            --19-AUg-2024 changes starts
            --left outer join DIM_GRP_CLAIM_ELIGIBILITY_R r
            left outer join (SELECT * FROM ATOMIC.DIM_GRP_CLAIM_ELIGIBILITY_R a1
            WHERE a1.v_active_status_r = 'Y'
            and a1.v_source_system_name_r = 'PACS'
            and a1.T_EVENT_TIMESTAMP_R = (select max(b1.T_EVENT_TIMESTAMP_R) from ATOMIC.DIM_GRP_CLAIM_ELIGIBILITY_R b1
            where a1.n_claim_sk_r = b1.n_claim_sk_r
            and b1.v_source_system_name_r = 'PACS'
            and b1.v_active_status_r = 'Y')
            ) r
            --19-AUg-2024 changes ends
            On r.N_CLAIM_COVERAGE_SK_R = case  when r.N_CLAIM_COVERAGE_SK_R <> -1 then b.N_CLAIM_COVERAGE_SK_R else -1 end
            and r.N_CLAIM_SK_R = a.N_CLAIM_SK_R
            and r.v_active_status_r = 'Y'
            and r.v_source_system_name_r = 'PACS'

              left join ATOMIC.dim_grp_claim_event_dir_r t
            on t.n_claim_event_sk_r = d.n_claim_event_sk_r
            and t.v_active_status_r = 'Y'
              left join ATOMIC.dim_grp_claim_event_r s
            on s.n_claim_event_sk_r = t.n_claim_event_sk_r
            and s.v_active_status_r = 'Y'
              left outer join ATOMIC.DIM_GRP_EEOC_R x /* D_GRP_EEOC_R */ --20-Mar-24 alias name changed from t to x
              On s.V_EEOC_CODE_R = x.V_CODE_R --20-Mar-24 alias name changed from t to x
              and x.v_active_status_r = 'Y' --20-Mar-24 alias name changed from t to x
            left outer join ATOMIC.CLAIM_TIER_WFAM_MV_TBL CLAIM_TIER_WFAM_MV_TBL
              on a.n_claim_sk_r = CLAIM_TIER_WFAM_MV_TBL.n_claim_sk_r
              left join ATOMIC.DIM_GRP_REF_TIER_R DIM_GRP_REF_TIER_R_disability
              on CLAIM_TIER_WFAM_MV_TBL.v_tier_r = DIM_GRP_REF_TIER_R_disability.V_TIER_TXT_R
              and DIM_GRP_REF_TIER_R_disability.V_COVERAGE_TYPE_CODE_R = j.V_COVERAGE_TYPE_CODE_R
              left join ATOMIC.DIM_GRP_REF_TIER_R DIM_GRP_REF_TIER_R_life
              on CLAIM_TIER_WFAM_MV_TBL.v_tier_r = DIM_GRP_REF_TIER_R_life.V_TIER_TXT_R
              and DIM_GRP_REF_TIER_R_life.V_COVERAGE_TYPE_CODE_R = j.V_COVERAGE_TYPE_CODE_R

              left outer join
             (SELECT * FROM ATOMIC.DIM_GRP_NURSE_CERT_R_mv_ssl
               /*SELECT   *
                       FROM dim_grp_nurse_cert_r c
                       WHERE v_active_status_r = 'Y'
                       AND N_NURSE_CERT_SEQ_R  =
                         (SELECT   MAX(N_NURSE_CERT_SEQ_R)
                          FROM dim_grp_nurse_cert_r
                          WHERE n_claim_sk_r    = c.n_claim_sk_r
                          AND v_active_status_r = 'Y'
                         )*/
                       ) u
                       on u.n_claim_sk_r = a.n_claim_sk_r

            left join (
            SELECT DIAG_IND.* FROM ATOMIC.dim_grp_medical_diagnosis_r_MV_SSL DIAG_IND
            /*SELECT   n_claim_sk_r,
            LISTAGG(case when n_primary_ind_r = 0 then v_diagnosis_desc_r else '' end, '; ') WITHIN GROUP (ORDER BY n_claim_sk_r) as  additional_desc,
            LISTAGG(case when n_primary_ind_r = 1 then v_diagnosis_desc_r else '' end, '; ') WITHIN GROUP (ORDER BY n_claim_sk_r) as  Primary_desc,
            LISTAGG(case when n_primary_ind_r = 0 then V_DIAGNOSIS_CODE_R else '' end, '; ') WITHIN GROUP (ORDER BY n_claim_sk_r) as  additional_diag_code,
            LISTAGG(case when n_primary_ind_r = 1 then V_DIAGNOSIS_CODE_R else '' end, '; ') WITHIN GROUP (ORDER BY n_claim_sk_r) as  primary_diag_code,
            LISTAGG(case when n_primary_ind_r = 1 then DIM_DIAGNOSIS_CODE_R.V_DIAG_CATEGORY_CODE_R else '' end, '; ') WITHIN GROUP (ORDER BY n_claim_sk_r) as  V_PRI_DIAG_CATEGORY_CODE_R,
            LISTAGG(case when n_primary_ind_r = 0 then DIM_DIAGNOSIS_CODE_R.V_DIAG_CATEGORY_CODE_R else '' end, '; ') WITHIN GROUP (ORDER BY n_claim_sk_r) as  add_diag_category_code,
            LISTAGG(case when n_primary_ind_r = 1 then DIM_DIAGNOSIS_CATEGORY_R.V_DIAG_CATEGORY_DESC_R else '' end, '; ') WITHIN GROUP (ORDER BY n_claim_sk_r) as  V_PRI_DIAG_CATEGORY_DESC_R,
            LISTAGG(case when n_primary_ind_r = 0 then DIM_DIAGNOSIS_CATEGORY_R.V_DIAG_CATEGORY_DESC_R else '' end, '; ') WITHIN GROUP (ORDER BY n_claim_sk_r) as  add_diag_category_desc,
            max(case when n_primary_ind_r = 1  then N_DIAGNOSIS_TYPE_CODE_R else 0 end) as  diagnosis_type_code
            FROM
            dim_grp_medical_diagnosis_r dim_grp_medical_diagnosis_r
            left join DIM_DIAGNOSIS_CODE_R DIM_DIAGNOSIS_CODE_R
            on dim_grp_medical_diagnosis_r.V_DIAGNOSIS_CODE_R = DIM_DIAGNOSIS_CODE_R.V_DIAG_CODE_R
            and DIM_DIAGNOSIS_CODE_R.v_active_status_r = 'Y'
            left join DIM_DIAGNOSIS_CATEGORY_R DIM_DIAGNOSIS_CATEGORY_R
            on DIM_DIAGNOSIS_CODE_R.V_DIAG_CATEGORY_CODE_R = DIM_DIAGNOSIS_CATEGORY_R.V_DIAG_CATEGORY_CODE_R
            and DIM_DIAGNOSIS_CATEGORY_R.v_active_status_r = 'Y'
            WHERE
            dim_grp_medical_diagnosis_r.v_active_status_r = 'Y'
            and n_claim_sk_r<>-1
            GROUP BY
            n_claim_sk_r*/
            ) diag
            on diag.n_claim_sk_r = a.n_claim_sk_r
            left join
              (/*SELECT
                                            v_claim_number_r,
                                            MAX(nvl(t374156.d_received_date_r,
                                                    TO_DATE(substr(t374156.v_claim_number_r, 1, 10),
                                                            'YYYY-MM-DD'))) AS received_date
                                        FROM
                                            dim_grp_busobj_audit_r t374156
                                        WHERE
                                                v_active_status_r = 'Y'
                                            AND v_claim_number_r NOT IN ( '-LIFE-01', '-LTD-01', '-STD-01', '-VPS-01', '-WOP-01' )
                                        GROUP BY
                                            v_claim_number_r*/
                SELECT obj.v_claim_number_r,obj.received_date FROM ATOMIC.DIM_GRP_BUSOBJ_AUDIT_R_MAX_RCV_MV_SSL	 obj
                                    )      received_date
                                    on received_date.v_claim_number_r = a.v_claim_number_r

            left join (
            SELECT LTD.CLAIM_SK ,LTD.ltd_policy_ind FROM ATOMIC.fct_grp_policy_r_LTDPOLIND_MV_SSL LTD
            /*SELECT    a.N_CLAIM_SK_R as CLAIM_SK,
            (case when a.v_lob_type_r in ('LIFE', 'STD', 'VPS', 'WOP','NONS')
            and c.n_cust_party_sk_r in
            (SELECT   c.n_cust_party_sk_r from
            dim_grp_policy_dir_r b,
            fct_grp_policy_r c
            where
            b.n_policy_version_number_r = c.n_version_number_r
            and b.n_policy_sk_r = c.n_policy_sk_r
            and b.v_active_status_r = 'Y'
            and b.v_orig_lob_r in ('ASL', 'LTD-SMALL', 'LTD', 'VPL', 'LTDVLT'))
            then
            'Y'
            else null
            end) ltd_policy_ind
            from
            dim_grp_claim_dir_r a ,
            dim_grp_policy_dir_r b,
            fct_grp_policy_r c
            where a.v_active_status_r = 'Y'
            and a.n_policy_sk_r = b.n_policy_sk_r
            and b.v_active_status_r = 'Y'
            and b.n_policy_version_number_r = c.n_version_number_r
            and b.n_policy_sk_r = c.n_policy_sk_r
            and v_lob_type_r <> 'ANNUITY'*/) ltd_policy_indicator
            on ltd_policy_indicator.CLAIM_SK = a.N_CLAIM_SK_R
            left join  (
            SELECT  PMNT.v_claim_number_r
               ,  PMNT.N_CLAIM_COVERAGE_GROUP_SK_R,
                PMNT.V_COV_GROUP_ID_R,
                PMNT.Last_Payment_Date, PMNT.earliest_payment_date,
                PMNT.MOST_RECENT_SERVICE_PERIOD_TO_DATE,
                PMNT.MOST_RECENT_SERVICE_PERIOD_FROM_DATE
                ,PMNT.EARLIEST_SERVICE_PERIOD_FROM_DATE --14-Mar-2024 changes
                ,PMNT.EARLIEST_SERVICE_PERIOD_TO_DATE   --14-Mar-2024 changes
                FROM ATOMIC.FCT_CLAIM_PAYMENT_DETAIL_R_PMNT_MV_SSL PMNT
                 where PMNT.N_CLAIM_COVERAGE_GROUP_SK_R <> -1                          ------------------                   /*TEMP FIX APPLIED NEED TO REVISIT*/
            /*SELECT   v_claim_number_r ,  N_CLAIM_COVERAGE_GROUP_SK_R,
                V_COV_GROUP_ID_R,
                MAX(d_paid_date_r) Last_Payment_Date, min(d_paid_date_r)earliest_payment_date,
            max(D_SERVICE_PERIOD_TO_R) MOST_RECENT_SERVICE_PERIOD_TO_DATE,
                 max(D_SERVICE_PERIOD_FROM_R) MOST_RECENT_SERVICE_PERIOD_FROM_DATE
              FROM
                (SELECT   v_claim_number_r,
                  d_paid_date_r,
                  N_SOURCE_VERSION_SEQ_NUMBER_R,
                  SUM(N_PAID_AMOUNT_R),
                  N_CLAIM_COVERAGE_GROUP_SK_R,
                  V_COV_GROUP_ID_R,
                 D_SERVICE_PERIOD_FROM_R,
                  D_SERVICE_PERIOD_TO_R
                FROM fct_claim_payment_detail_r
                WHERE V_CHECK_TYPE_R      <> 'OE'
                AND V_BENEFIT_GROUP_R NOT IN ('FIC', 'MED')
                GROUP BY v_claim_number_r,
                  d_paid_date_r,
                  N_SOURCE_VERSION_SEQ_NUMBER_R,
                  N_CLAIM_COVERAGE_GROUP_SK_R,
                  V_COV_GROUP_ID_R,
                  D_SERVICE_PERIOD_FROM_R,
                  D_SERVICE_PERIOD_TO_R
                HAVING SUM(N_PAID_AMOUNT_R) >0
                )
              GROUP BY v_claim_number_r,
                N_CLAIM_COVERAGE_GROUP_SK_R,
                V_COV_GROUP_ID_R
                */) payment_dates
                --19-Dec-2023 changes starts
                --on PAYMENT_DATES.N_CLAIM_COVERAGE_GROUP_SK_R = G.N_CLAIM_COVERAGE_GROUP_SK_R
                ON PAYMENT_DATES.v_claim_number_r = A. v_claim_number_r
                And PAYMENT_DATES.N_CLAIM_COVERAGE_GROUP_SK_R  = (case when PAYMENT_DATES.N_CLAIM_COVERAGE_GROUP_SK_R = -1 then -1 else G.N_CLAIM_COVERAGE_GROUP_SK_R end)
                --19-Dec-2023 changes ends
            --where a.V_ACTIVE_STATUS_R = 'Y' --moved to top on 18-Jan-2024
             --21-06-24 changes start
           left outer join ATOMIC.DIM_GRP_SYSUSESO_R T4418483 /* D_GRP_SYSUSESO_R_Claims */  On upper(T4418483.V_LOGIN_ID_R) = upper(appeal.V_USER_ID_R)
            --21-06-24 changes start
            --26-Jan-2024 changes starts
            Left join
            (select *   from ATOMIC.DIM_GRP_VOCREHAB_R
                          where v_active_status_r = 'Y'
                          and v_source_system_name_r <> 'CV'
                          and n_claim_sk_r <>-1) DIM_GRP_VOCREHAB_R
            on DIM_GRP_VOCREHAB_R.n_claim_sk_r = a.N_CLAIM_SK_R

            -- Perf Tuning :: Start : PRC_GRP_UPD_RPT_CLAIM_DTL_R_COLS procedure logic

            LEFT JOIN
                (
                    SELECT
                        ach_indicator as v_claim_ach_payment_ind_r
                        ,n_claim_sk_r
                    FROM ATOMIC.fct_benefit_payment_r_claim_achind_mv_ssl
                    WHERE ach_indicator IS NOT NULL
                    GROUP BY  ach_indicator,n_claim_sk_r
                ) ach_ind
                ON a.n_claim_sk_r = ach_ind.n_claim_sk_r

            LEFT JOIN
                (
                    SELECT
                         d_most_recent_medical_note_date_r
                        ,v_most_recent_medical_note_r
                        ,n_claim_sk_r
                    FROM (
                         SELECT
                            d_created_date_r AS d_most_recent_medical_note_date_r
                           ,TO_CHAR(DBMS_LOB.SUBSTR(v_med_note_data_r,2000,1)) v_most_recent_medical_note_r
                           ,n_claim_sk_r
                           ,ROW_NUMBER()
                                OVER
                                    (PARTITION BY n_claim_sk_r
                                        ORDER BY d_created_date_r
                                        ,TO_CHAR(DBMS_LOB.SUBSTR(v_med_note_data_r,2000,1))
                                    ) AS RN
                        FROM ATOMIC.FCT_CLAIM_NOTE_R_DUR_MV_SSL med_note
                        WHERE med_note.dupremov    =1
                    ) med_note WHERE RN=1
                    GROUP BY d_most_recent_medical_note_date_r  ,v_most_recent_medical_note_r ,n_claim_sk_r
                ) med_note
                ON a.n_claim_sk_r = med_note.n_claim_sk_r

            LEFT JOIN
                (
                    SELECT
                         d_most_recent_management_note_date_r
                        ,v_most_recent_mgmt_note_r
                        ,n_claim_sk_r
                    FROM (
                         SELECT
                            d_created_date_r as d_most_recent_management_note_date_r
                           ,TO_CHAR(DBMS_LOB.SUBSTR(v_mgt_note_data_r,2000,1)) v_most_recent_mgmt_note_r
                           ,n_claim_sk_r
                           ,ROW_NUMBER()
                                OVER
                                    (PARTITION BY n_claim_sk_r
                                        ORDER BY d_created_date_r
                                        ,TO_CHAR(DBMS_LOB.SUBSTR(v_mgt_note_data_r,2000,1))
                                    ) AS RN
                        FROM ATOMIC.fct_claim_note_r_mgmnt_mv_ssl mgmt_note
                        WHERE mgmt_note.dupremov    =1
                    ) mgmt_note WHERE RN=1
                    GROUP BY d_most_recent_management_note_date_r  ,v_most_recent_mgmt_note_r ,n_claim_sk_r
                ) mgmt_note
                ON a.n_claim_sk_r = mgmt_note.n_claim_sk_r

            LEFT JOIN
                (
                    SELECT /*+PARALLEL(4)*/
                         RPT_CLAIM_DTL_R_offset_mv_ssl.n_claim_sk_r                             as	n_claim_sk_r
                        ,RPT_CLAIM_DTL_R_offset_mv_ssl.n_claim_coverage_group_sk_r              as	n_claim_coverage_group_sk_r
                        ,RPT_CLAIM_DTL_R_offset_mv_ssl.rehabilitation_offset_amount_088         as  n_rehab_offset_amt_088_r
                        ,RPT_CLAIM_DTL_R_offset_mv_ssl.workers_compensation_offset_amount_083   as  n_workers_comp_offset_amt_083_r
                        ,RPT_CLAIM_DTL_R_offset_mv_ssl.other_offset_amounts                     as  n_other_offset_amt_r
                        ,RPT_CLAIM_DTL_R_offset_mv_ssl.rehabilitation_offset_indicator_088      as  v_rehab_offset_ind_088_r
                    FROM ATOMIC.RPT_CLAIM_DTL_R_offset_mv_ssl RPT_CLAIM_DTL_R_offset_mv_ssl
                    GROUP BY
                         RPT_CLAIM_DTL_R_offset_mv_ssl.n_claim_sk_r
                        ,RPT_CLAIM_DTL_R_offset_mv_ssl.n_claim_coverage_group_sk_r
                        ,RPT_CLAIM_DTL_R_offset_mv_ssl.rehabilitation_offset_amount_088
                        ,RPT_CLAIM_DTL_R_offset_mv_ssl.workers_compensation_offset_amount_083
                        ,RPT_CLAIM_DTL_R_offset_mv_ssl.other_offset_amounts
                        ,RPT_CLAIM_DTL_R_offset_mv_ssl.rehabilitation_offset_indicator_088
                ) clm_offset_mv
                ON  a.n_claim_sk_r = clm_offset_mv.n_claim_sk_r
                and g.n_claim_coverage_group_sk_r=clm_offset_mv.n_claim_coverage_group_sk_r

            LEFT JOIN
                (
                    SELECT /*+PARALLEL(4)*/
                       TOTBEN.V_CLAIM_NUMBER_R
                      ,TOTBEN.n_total_benefit_period_days_r as N_TOTAL_BENEFIT_PERIOD_DAYS_R
                    FROM ATOMIC.RPT_CLAIM_DTL_R_totbenperdys_mv_ssl TOTBEN
                    WHERE TOTBEN.n_total_benefit_period_days_r IS NOT NULL
                    group by TOTBEN.V_CLAIM_NUMBER_R,TOTBEN.N_TOTAL_BENEFIT_PERIOD_DAYS_R
                ) TOTBEN
                ON a.V_CLAIM_NUMBER_R=TOTBEN.V_CLAIM_NUMBER_R

            LEFT JOIN
                (
                    SELECT /*+PARALLEL(4)*/
                       CURBEN.V_CLAIM_NUMBER_R
                      ,CURBEN.N_CURR_BENEFIT_PERIOD_DAYS_R as N_CURR_BENEFIT_PERIOD_DAYS_R
                    FROM ATOMIC.RPT_CLAIM_DTL_R_curbenperdys_mv_ssl CURBEN
                    WHERE CURBEN.N_CURR_BENEFIT_PERIOD_DAYS_R IS NOT NULL
                    group by CURBEN.V_CLAIM_NUMBER_R,CURBEN.N_CURR_BENEFIT_PERIOD_DAYS_R
                ) CURBEN
                ON a.V_CLAIM_NUMBER_R=CURBEN.V_CLAIM_NUMBER_R
     -- Perf Tuning --Start : PROCEDURE prc_upd_wavier_ltd_ind_cols logic implemented as left join
            LEFT JOIN
            (
                SELECT
                    n_wop_claim_sk_r                n_claim_sk_r,
                    n_wop_claim_coverage_sk_r       n_claim_coverage_sk_r,
                    n_wop_claim_coverage_group_sk_r n_claim_coverage_group_sk_r,
                    v_wop_claim_number_r            v_claim_number_r,
                    v_wop_claim_identifier_r        v_claim_identifier_r,
                    'Y'                             v_has_associated_waiver_ind_r,
                    NULL                             v_has_associated_ltd_ind_r
                FROM
                    ATOMIC.rpt_associated_claims_mv_ssl
                GROUP BY n_wop_claim_sk_r
                       , n_wop_claim_coverage_sk_r
                       , n_wop_claim_coverage_group_sk_r
                       , v_wop_claim_number_r
                       , v_wop_claim_identifier_r

                ) wavier_ind
            ON      wavier_ind.n_claim_sk_r             = a.n_claim_sk_r
              AND wavier_ind.n_claim_coverage_sk_r      = b.n_claim_coverage_sk_r
              AND wavier_ind.n_claim_coverage_group_sk_r = g.n_claim_coverage_group_sk_r

            LEFT JOIN
            (
            SELECT
                n_ltd_claim_sk_r                n_claim_sk_r,
                n_ltd_claim_coverage_sk_r       n_claim_coverage_sk_r,
                n_ltd_claim_coverage_group_sk_r n_claim_coverage_group_sk_r,
                v_ltd_claim_number_r            v_claim_number_r,
                v_ltd_claim_identifier_r        v_claim_identifier_r,
                NULL                             v_has_associated_waiver_ind_r,
                'Y'                            v_has_associated_ltd_ind_r
            FROM
                ATOMIC.rpt_associated_claims_mv_ssl
            GROUP BY n_ltd_claim_sk_r
                   , n_ltd_claim_coverage_sk_r
                   , n_ltd_claim_coverage_group_sk_r
                   , v_ltd_claim_number_r
                   , v_ltd_claim_identifier_r
                ) ltd_ind
            ON      ltd_ind.n_claim_sk_r             = a.n_claim_sk_r
              AND ltd_ind.n_claim_coverage_sk_r      = b.n_claim_coverage_sk_r
              AND ltd_ind.n_claim_coverage_group_sk_r = g.n_claim_coverage_group_sk_r
     -- Perf Tuning --End : PROCEDURE prc_upd_wavier_ltd_ind_cols logic implemented as left join
            LEFT JOIN
                (
                    select CAST(D_EDS_CYCLEDATE_R AS DATE) as GD_PACS_AS_OF_DATE_R
                    from ATOMIC.PRCS_GRP_DATE_PARAM_R
                    where V_PROCESS_NAME_R ='PACS_BATCH_ID'
                ) get_pacs_as_of_date_r ON 1=1


            -- Perf Tuning :: End : PRC_GRP_UPD_RPT_CLAIM_DTL_R_COLS procedure logic

            ) a
            --26-Jan-2024 changes ends
    -- 04/09/24 Changes start
    --04/09/24 Changes End
           where  rank= 1
           )

    -- Perf Tuning :: Start : PRC_GRP_UPD_RPT_CLAIM_DTL_R_COLS procedure logic
     SELECT
     DISTINCT
         main.V_ADD_DIAG_CATEGORY_CODE_R
        ,main.V_ADD_DIAG_CATEGORY_DESC_R
        ,main.V_ADD_DIAGNOSIS_CODE_R
        ,main.V_PRI_DIAG_CATEGORY_CODE_R
        ,main.V_PRI_DIAG_CATEGORY_DESC_R
        ,main.V_PRI_DIAGNOSIS_CODE_R
        ,main.N_DIAGNOSIS_TYPE_CODE_R
        ,main.V_ADD_DIAG_CODE_DESC_R
        ,main.V_PRI_DIAG_CODE_DESC_R
        ,main.D_LAST_PAYMENT_DATE_R
        ,main.D_AGE_REDUCTION_DATE_R
        ,main.V_CLAIM_ACH_PAYMENT_IND_R
        ,main.D_BENEFIT_START_R
        ,main.V_CAUSE_OF_EVENT_CODE_R
        ,main.V_CAUSE_OF_EVENT_DESC_R
        ,main.V_CLAIM_CLASS_ID_R
        ,main.D_CLAIM_CLOSED_DATE_R
        ,main.V_ELIGIBILITY_DECISION_R
        ,main.V_ELIGIBILITY_REASON_R
        ,main.N_CLAIM_COVERAGE_GROUP_SK_R
        ,main.N_CLAIM_COVERAGE_SK_R
        ,main.N_CLAIM_SK_R
        ,main.V_CLAIM_EVENT_NUMBER_R
        ,main.V_CLAIM_NUMBER_R
        ,main.N_CLAIM_PENDING_AGE_R
        ,main.N_CLAIM_TAXABLE_BENEFIT_PCT_R
        ,main.N_DAYS_OPEN_R
        ,main.D_DISABILITY_START_DATE_R
        ,main.V_EXERTION_LEVEL_R
        ,main.V_DURATION_INDICATOR_R
        ,main.V_DURATION_PERIOD_R
        ,main.D_EARLIEST_BENEFIT_PAYMENT_DATE_R
        ,main.D_EARLIEST_SERVICE_PERIOD_FROM_R
        ,main.D_EARLIEST_SERVICE_PERIOD_TO_R
        ,main.V_ELIMINATION_PERIOD_R
        ,main.D_EST_QUALIFYING_PERIOD_EXP_DATE_R
        ,main.V_EST_SS_IND_R
        ,main.V_EXTENDED_DURATION_IND_R
        ,main.D_LOSS_DATE_R
        ,main.D_MODIFIED_RTW_DATE_R
        ,main.D_MOST_RECENT_SERVICE_PERIOD_FROM_R
        ,main.D_MOST_RECENT_SERVICE_PERIOD_TO_R
        ,main.D_NURSE_CERT_END_DATE_R
        ,main.N_NURSE_CERT_SEQ_R
        ,main.V_OCCUPATION_CODE_R
        ,main.V_OCCUPATION_DESC_R
        ,main.V_PFL_CHILD_GENDER_R
        ,main.D_PFL_DOB_R
        ,main.V_MANDATED_FAMILY_MEMBER_R
        ,main.V_LEAVE_REASON_R
        ,main.D_PFL_DOP_R
        ,main.D_PHYS_CERT_END_DATE_R
        ,main.D_PLAN_DUR_DATE_R
        ,main.D_RETIREMENT_TERMINATION_DATE_R
        ,main.D_RETURN_TO_WORK_DATE_R
        ,main.V_SOCIAL_SECURITY_IND_R
        ,main.V_TURNAROUND_RANGE_R
        ,main.V_WAIVER_IND_R
        ,main.D_WAIVER_STATUS_DATE_R
        ,main.N_WAIVER_TERMINATION_AGE_R
        ,main.D_WAIVER_TERMINATION_DATE_R
        ,main.D_CLAIM_AS_OF_DATE_R
        ,main.V_METHOD_R
        ,main.V_METHOD_STYLE_R
        ,main.V_CLAIM_IDENTIFIER_R
        ,main.D_MOST_RECENT_ACTIVITY_DATE_R
        ,main.D_CLAIM_RECEIVED_DATE_R
        ,main.FIC_MIS_DATE_R
        ,main.V_LTD_POLICY_IND_R
        ,main.V_CLAIM_COMPANY_R
        ,main.V_PRIVACY_INDICATOR_R
        ,main.N_ANY_OCC_DAYS_REMAINING_R
        ,main.D_ANY_OCC_DECISION_DATE_R
        ,main.V_ANY_OCC_PERIOD_R
        ,main.V_ANY_OCC_PERIOD_IND_R
        ,main.D_ANY_OCC_START_DATE_R
        ,main.V_ANY_OCC_OWN_OCC_IND_R
        ,main.V_OWN_OCC_PERIOD_R
        ,main.V_OWN_OCC_PERIOD_IND_R
        ,main.V_CLAIM_COVERAGE_CODE_R
        ,main.V_PRODUCT_LINE_DESC_R
        ,main.N_COV_GRP_ID_R
        ,main.V_CLAIM_COVERAGE_DESC_R
        ,main.D_APPEAL_RECEIVED_DATE_R
        ,main.V_APPEAL_DENIAL_OVERTURN_TYPE_R
        ,main.V_APPEALS_ANALYST_R
        ,main.D_APPEAL_COMPLETED_DATE_R
        ,main.N_APPEAL_SOURCE_VERSION_SEQ_NUMBER_R
        ,main.D_MOST_RECENT_MEDICAL_NOTE_DATE_R
        ,main.V_MOST_RECENT_MEDICAL_NOTE_R
        ,main.D_MOST_RECENT_MANAGEMENT_NOTE_DATE_R
        ,main.V_MOST_RECENT_MGMT_NOTE_R
        ,main.D_SS_DEP_AWARD_EFF_DATE_R
        ,main.V_SS_DEPENDENT_STATUS_R
        ,main.D_SS_DEP_TERM_DATE_R
        ,main.V_SS_DEP_AWARD_TYPE_R
        ,main.V_SS_DEP_PURSUE_IND_R
        ,main.D_SS_MOST_RECENT_UPDATE_DATE_R
        ,main.D_SS_PRIMARY_EFF_DATE_R
        ,main.V_SS_STATUS_DESCRIPTION_R
        ,main.D_SS_CLOSED_TERM_DATE_R
        ,main.V_SS_PRIMARY_AWARD_TYPE_R
        ,main.V_SS_PRIMARY_PURSUE_IND_R
        ,main.V_SS_REJECT_REASON_CODE_R
        ,main.V_SS_REJECT_REASON_R
        ,main.V_CLAIM_STATUS_CATEGORY_R
        ,main.V_CLAIM_STATUS_CODE_R
        ,main.V_CLAIM_STATUS_DESC_R
        ,main.D_CLAIM_STATUS_EFF_DATE_R
        ,main.D_LAST_IN_STATUS_46_DATE_R
        ,main.V_PRIOR_CLAIM_STATUS_CLOSURE_CODE_R
        ,main.V_PRIOR_CLAIM_STATUS_CODE_R
        ,main.V_SALES_CLAIM_STATUS_DESC_R
        ,main.V_CURR_CLAIM_STATUS_CODE_R
        ,main.V_CLAIM_TYPE_R
        ,main.D_TIER_CREATED_DATE_R
        ,main.D_WFAM_CODE_CREATED_DATE_R
        ,main.V_TIER_R
        ,main.V_WFAM_R
        ,main.D_PRD_R
        ,main.D_PRD_DAYS_REMAINING_R
        ,main.V_ACCOMMODATIONS_NEEDED_R
        ,main.V_CLINICAL_VOC_ENGAGEMENT_R
        ,main.V_TIER_DESCRIPTION_R
        ,main.N_TIER_NUM_R
        ,main.V_RECOVERY_EXPECTATIONS_R
        ,main.V_VOC_REHAB_STATUS_R
        ,main.V_VOC_REHAB_MGR_NAME_R
        ,main.V_VOC_REHAB_SPECIALIST_R
        ,main.V_SERVICE_REQUESTED_OTHER_R
        ,main.V_SERVICE_REQUESTED_R
        ,main.V_VOC_REHAB_OUTCOME_R
        ,main.V_VOC_REHAB_ACTIVE_STATUS_R
        ,main.D_TSA_DATE_R
        ,main.V_LOCATION_NUMBER_R
        ,main.V_CORRESPONDENT_NAME_R
        ,main.V_SUBGROUP_ADDRESSLINE1_R
        ,main.V_SUBGROUP_ADDRESSLINE2_R
        ,main.V_SUBGROUP_CITY_R
        ,main.V_SUBGROUP_ID_R
        ,main.V_SUBGROUP_NAME_R
        ,main.V_SUBGROUP_POSTALZIP_R
        ,main.V_SUBGROUP_PROVSTATE_R
        ,main.V_LAST_MODIFIED_BY_R
        ,main.T_CREATION_DATE_R
        ,main.V_CREATED_BY_R
        ,main.T_LAST_MODIFIED_DATE_R
        ,main.N_YEARMONTH_R
        ,main.V_RPT_ACTIVE_STATUS_R
        ,main.N_BATCH_ID_R
        ,main.V_EXAMINER_ID_R
        ,main.V_EXAMINER_NAME_R
        ,main.D_HIRE_DATE_R
        ,main.D_SS_COUNCIL_START_DATE_R
        ,main.D_SS_APPEAL_END_DATE_R
        ,main.D_SS_COURT_START_DATE_R
        ,main.D_SS_COURT_APPEAL_END_DATE_R
        ,main.D_SS_HEARING_START_DATE_R
        ,main.D_SS_HEARING_END_DATE_R
        ,main.D_SS_INIT_FILING_START_DATE_R
        ,main.D_SS_INIT_FILING_END_DATE_R
        ,main.D_SS_RECONSIDER_START_DATE_R
        ,main.D_SS_RECONSIDER_END_DATE_R
        ,main.V_SS_HARDSHIP_IND_R
        ,main.D_WORKSHEET_START_DATE_R
        ,main.D_WORKSHEET_END_DATE_R
        ,main.V_LOB_TYPE_R
        ,main.V_SOURCE_SYSTEM_NAME_R
        ,main.N_CURR_BENEFIT_PERIOD_DAYS_R
        ,main.N_TOTAL_BENEFIT_PERIOD_DAYS_R
        ,main.N_BASIC_INSURED_SALARY_R
        ,main.V_BASIC_INSURED_SALARY_IND_R
        ,main.N_REHAB_OFFSET_AMT_088_R
        ,main.V_REHAB_OFFSET_IND_088_R
        ,main.N_WORKERS_COMP_OFFSET_AMT_083_R
        ,main.N_OTHER_OFFSET_AMT_R
        ,main.V_PFL_LEAVE_TYPE_R
        ,main.V_PFL_LICENSE_NUMBER_R
        ,main.D_CLOSED_MONTH_START_DATE_R
        ,main.D_CLOSED_MONTH_END_DATE_R
        ,main.V_APPEAL_IND_R
        ,main.V_APPEAL_RESULT_STATUS_CODE_R
        ,main.D_APPEAL_RESULT_STATUS_CODE_EFF_DATE_R
        ,main.V_APPEAL_ANALYST_NAME_R
        ,main.V_APPEAL_STATUS_CODE_R
        ,main.V_RPT_WORKSHEET_INDICATOR_R
        ,main.N_WORKSHEET_NUMBER_R
        ,main.V_WORKSHEET_STATUS_R
        ,main.N_WORKSHEET_SEQ_NBR_OBJECTNM_R
        ,main.V_COVERAGE_TYPE_CODE_R
        ,main.N_MAX_BENEFIT_R
        ,main.N_MINIMUM_BENEFIT_R
        ,main.V_CLAIM_WELLNESS_IND_R
        ,main.V_HAS_ASSOCIATED_WAIVER_IND_R
        ,main.V_HAS_ASSOCIATED_LTD_IND_R
        ,main.V_CLAIM_STATUS_REASON_DESC_R
        ,upd1.D_CLAIM_DECISION_DATE_R
        ,upd1.N_CLAIM_DECISION_DAYS_R
        ,upd1.V_TURNAROUND_RANGE1_R
		,main.V_OVERRIDE_NAME_R
		,main.D_RECORD_START_DATE_R
		,main.D_RECORD_END_DATE_R
		-- 26-mar-2026 added as per FDM reqt start
        , main.D_DURATION_EFF_DATE_R                                  					AS D_DURATION_EFF_DATE_R
        , main.D_ELIMINATION_EFF_DATE_R                               					AS D_ELIMINATION_EFF_DATE_R
        , main.D_GROSS_BEN_EFF_DATE_R                                 					AS D_GROSS_BEN_EFF_DATE_R
        , main.D_LOSS_DATE_EFF_DATE_R                                 					AS D_LOSS_DATE_EFF_DATE_R
        , main.N_SS_PRIMARY_AWARD_AMOUNT_R												AS N_SS_PRIMARY_AWARD_AMOUNT_R
        , main.D_SS_EST_START_DATE_R      												AS D_SS_EST_START_DATE_R
        , main.D_SS_AWARDED_START_DATE_R  												AS D_SS_AWARDED_START_DATE_R
        , main.V_SS_PURSUING_REMARKS_R    												AS V_SS_PURSUING_REMARKS_R
        , main.V_SS_DEP_OFFSET_ALLOWED_R  												AS V_SS_DEP_OFFSET_ALLOWED_R
        , main.V_DOT_CODE_PRIMARY_DESC_R  												AS V_DOT_CODE_PRIMARY_DESC_R
        , main.V_DOT_CODE_PRIMARY_R       												AS V_DOT_CODE_PRIMARY_R
		--main FCDR.D_DISBURSE_DATE_R     												AS D_DISBURSE_DATE_R
        , main.D_PRIMARY_DIAG_EFF_DATE_R  												AS D_PRIMARY_DIAG_EFF_DATE_R
        , main.V_ELIMINATION_IND_R        												AS V_ELIMINATION_IND_R
        , main.D_CHECK_NET_BEN_EFF_DATE_R 												AS D_CHECK_NET_BEN_EFF_DATE_R
        -- 26-mar-2026 added as per FDM reqt end
    FROM CTE  main

    -- Perf Tuning --Start : PROCEDURE prc_upd_decision_cols logic implemented as left join
    LEFT JOIN
      (
          SELECT  n_claim_sk_r,
                n_claim_coverage_sk_r,
                n_claim_coverage_group_sk_r,
                d_claim_decision_date_r,
                d_claim_received_date_r,
                N_CLAIM_DECISION_DAYS_R,
                CASE
                    WHEN d_claim_decision_date_r - d_claim_received_date_r BETWEEN 0 AND 3 THEN '0 - 3'
                    WHEN d_claim_decision_date_r - d_claim_received_date_r BETWEEN 4 AND 5 THEN '4 - 5'
                    WHEN d_claim_decision_date_r - d_claim_received_date_r BETWEEN 6 AND 7 THEN '6 - 7'
                    WHEN d_claim_decision_date_r - d_claim_received_date_r BETWEEN 8 AND 10 THEN '8 - 10'
                    WHEN d_claim_decision_date_r - d_claim_received_date_r > 10 THEN '> 10'
                    ELSE 'U'
                END AS V_TURNAROUND_RANGE1_R
        FROM (
        SELECT  a.n_claim_sk_r,
                a.n_claim_coverage_sk_r,
                a.n_claim_coverage_group_sk_r,
                b.d_claim_received_date_r,
                MAX(a.d_claim_decision_date_r) d_claim_decision_date_r,
                MAX(a.d_claim_decision_date_r - b.d_claim_received_date_r) AS N_CLAIM_DECISION_DAYS_R
            FROM ATOMIC.rpt_fct_rpt_claim_summary_r a, CTE b
            WHERE   b.n_claim_sk_r                = a.n_claim_sk_r
                AND b.n_claim_coverage_sk_r       = a.n_claim_coverage_sk_r
                AND b.n_claim_coverage_group_sk_r = a.n_claim_coverage_group_sk_r
            group by a.n_claim_sk_r, a.n_claim_coverage_sk_r,  a.n_claim_coverage_group_sk_r,
                b.d_claim_received_date_r
        )
        GROUP BY n_claim_sk_r,  n_claim_coverage_sk_r,  n_claim_coverage_group_sk_r,
                d_claim_decision_date_r, d_claim_received_date_r, N_CLAIM_DECISION_DAYS_R,
                CASE
                    WHEN d_claim_decision_date_r - d_claim_received_date_r BETWEEN 0 AND 3 THEN '0 - 3'
                    WHEN d_claim_decision_date_r - d_claim_received_date_r BETWEEN 4 AND 5 THEN '4 - 5'
                    WHEN d_claim_decision_date_r - d_claim_received_date_r BETWEEN 6 AND 7 THEN '6 - 7'
                    WHEN d_claim_decision_date_r - d_claim_received_date_r BETWEEN 8 AND 10 THEN '8 - 10'
                    WHEN d_claim_decision_date_r - d_claim_received_date_r > 10 THEN '> 10'
                    ELSE 'U'
                END
     ) upd1
     on
        main.n_claim_sk_r                = upd1.n_claim_sk_r
    AND main.n_claim_coverage_sk_r       = upd1.n_claim_coverage_sk_r
    AND main.n_claim_coverage_group_sk_r = upd1.n_claim_coverage_group_sk_r
    -- Perf Tuning --End : PROCEDURE prc_upd_decision_cols logic implemented as left join
    ;
    COMMIT;
  ln_rec_cnt := SQL%ROWCOUNT;

  --DBMS_OUTPUT.PUT_LINE(6);
/*START: 20-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
 gt_end_time_r := SYSTIMESTAMP;
 gc_duration_r := EXTRACT(SECOND FROM (gt_end_time_r - gt_start_time_r)) +
						 EXTRACT(MINUTE FROM (gt_end_time_r - gt_start_time_r)) * 60 +
						 EXTRACT(HOUR FROM (gt_end_time_r - gt_start_time_r)) * 3600;
gc_trcmsg:='3.2 END: LOAD DATA TO TARGET TABLE RPT_CLAIM_DTL_R'||chr(13);
	 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
	 (
		p_job_id_r                    => gn_out_job_id,
		p_batch_id_r                  => gn_sysdt_batchid,
		p_message_type_r              => gc_message_type_r,
		p_code_location_r             => gc_main_loadedby,
		p_message_r                   => gc_trcmsg,
		p_count_type_r                => gc_count_type_r,
		p_count_r                     => ln_rec_cnt,
		p_duration_r                  => gc_duration_r,
		p_created_by_r                => GC_JOB_NAME,
		out_prcs_job_log_message_id_r => gn_job_log_message_id_r
	);
/*END: 20-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
        --ln_rec_cnt:=0;
      --  SELECT COUNT(1) into ln_rec_cnt FROM ATOMIC.RPT_CLAIM_DTL_R where n_yearmonth_r=gn_current_month;

        INSERT INTO ATOMIC.SSL_PACKAGE_LOG_TABLE(job_name,process_name, start_date, end_date,TARGET_TABLE_COUNT)
        VALUES ('PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC','END: DATA LOAD TO RPT_CLAIM_DTL_R', SYSDATE, NULL,ln_rec_cnt);
        COMMIT;
  --DBMS_OUTPUT.PUT_LINE(7);

    --- UPDATE N_ANY_OCC_DAYS_REMAINING_R COLUMN IN RPT TABLE

        INSERT INTO ATOMIC.SSL_PACKAGE_LOG_TABLE(job_name,process_name, start_date, end_date)
        VALUES ('PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC','START: UPDATE N_ANY_OCC_DAYS_REMAINING_R COLUMN', SYSDATE, NULL);
        COMMIT;
/*START: 20-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
 gc_trcmsg:='3.3 START: UPDATE N_ANY_OCC_DAYS_REMAINING_R COLUMN'||chr(13);
 gt_start_time_r := SYSTIMESTAMP;
 gc_count_type_r:= PKG_GRP_LOG_UTIL.gc_count_type_update;

			 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
			 (
				p_job_id_r                    => gn_out_job_id,
				p_batch_id_r                  => gn_sysdt_batchid,
				p_message_type_r              => gc_message_type_r,
				p_code_location_r             => gc_main_loadedby,
				p_message_r                   => gc_trcmsg,
				p_count_type_r                => gc_count_type_r,
				p_count_r                     => NULL,
				p_duration_r                  => NULL,
				p_created_by_r                => GC_JOB_NAME,
				out_prcs_job_log_message_id_r => gn_job_log_message_id_r
			);
/*END: 20-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
        MERGE  INTO ATOMIC.RPT_CLAIM_DTL_R M
        USING (
                SELECT
                      D_ANY_OCC_START_DATE_R
                    ,(D_ANY_OCC_START_DATE_R-(sysdate-1)) AS  N_ANY_OCC_DAYS_REMAINING_R
                FROM ATOMIC.RPT_CLAIM_DTL_R
                WHERE N_YEARMONTH_R = GN_CURRENT_MONTH
                GROUP BY D_ANY_OCC_START_DATE_R
            ) C
        ON (M.D_ANY_OCC_START_DATE_R = C.D_ANY_OCC_START_DATE_R AND M.n_yearmonth_r = GN_CURRENT_MONTH)
        WHEN MATCHED
            THEN
                UPDATE SET M.N_ANY_OCC_DAYS_REMAINING_R = C.N_ANY_OCC_DAYS_REMAINING_R;

        commit;
 ln_rec_cnt := SQL%ROWCOUNT;
/*START: 20-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
 gt_end_time_r := SYSTIMESTAMP;
 gc_duration_r := EXTRACT(SECOND FROM (gt_end_time_r - gt_start_time_r)) +
						 EXTRACT(MINUTE FROM (gt_end_time_r - gt_start_time_r)) * 60 +
						 EXTRACT(HOUR FROM (gt_end_time_r - gt_start_time_r)) * 3600;
gc_trcmsg:='3.4 END: UPDATE N_ANY_OCC_DAYS_REMAINING_R COLUMN'||chr(13);
	 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
	 (
		p_job_id_r                    => gn_out_job_id,
		p_batch_id_r                  => gn_sysdt_batchid,
		p_message_type_r              => gc_message_type_r,
		p_code_location_r             => gc_main_loadedby,
		p_message_r                   => gc_trcmsg,
		p_count_type_r                => gc_count_type_r,
		p_count_r                     => ln_rec_cnt,
		p_duration_r                  => gc_duration_r,
		p_created_by_r                => GC_JOB_NAME,
		out_prcs_job_log_message_id_r => gn_job_log_message_id_r
	);
/*END: 20-MAY-2025: NEW LOGGING MECHANISM CHANGES*/


 gc_trcmsg:='3.5 START: UPDATE D_PRD_R COLUMN'||chr(13);
 gt_start_time_r := SYSTIMESTAMP;
 gc_count_type_r:= PKG_GRP_LOG_UTIL.gc_count_type_update;

			 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
			 (
				p_job_id_r                    => gn_out_job_id,
				p_batch_id_r                  => gn_sysdt_batchid,
				p_message_type_r              => gc_message_type_r,
				p_code_location_r             => gc_main_loadedby,
				p_message_r                   => gc_trcmsg,
				p_count_type_r                => gc_count_type_r,
				p_count_r                     => NULL,
				p_duration_r                  => NULL,
				p_created_by_r                => GC_JOB_NAME,
				out_prcs_job_log_message_id_r => gn_job_log_message_id_r
			);


	        UPDATE ATOMIC.RPT_CLAIM_DTL_R A
            SET D_PRD_R = (SELECT D_PRD_R FROM
                           ATOMIC.CLAIM_TIER_WFAM_MV_TBL B
			               WHERE A.N_CLAIM_SK_R = B.N_CLAIM_SK_R
                           AND A.N_YEARMONTH_R = GN_CURRENT_MONTH
			               AND A.D_PRD_R <> B.D_PRD_R
			               )
            WHERE EXISTS  (SELECT N_CLAIM_SK_R FROM
                           ATOMIC.CLAIM_TIER_WFAM_MV_TBL B
			               WHERE A.N_CLAIM_SK_R = B.N_CLAIM_SK_R
						   AND A.N_YEARMONTH_R = GN_CURRENT_MONTH
			               AND A.D_PRD_R <> B.D_PRD_R
			               )
            AND N_YEARMONTH_R = GN_CURRENT_MONTH;
            COMMIT;
	ln_rec_cnt := SQL%ROWCOUNT;

	/*NEW LOGGING MECHANISM CHANGES*/
	 gt_end_time_r := SYSTIMESTAMP;
 gc_duration_r := EXTRACT(SECOND FROM (gt_end_time_r - gt_start_time_r)) +
						 EXTRACT(MINUTE FROM (gt_end_time_r - gt_start_time_r)) * 60 +
						 EXTRACT(HOUR FROM (gt_end_time_r - gt_start_time_r)) * 3600;
gc_trcmsg:='3.6 END: UPDATE D_PRD_R COLUMN'||chr(13);
	 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
	 (
		p_job_id_r                    => gn_out_job_id,
		p_batch_id_r                  => gn_sysdt_batchid,
		p_message_type_r              => gc_message_type_r,
		p_code_location_r             => gc_main_loadedby,
		p_message_r                   => gc_trcmsg,
		p_count_type_r                => gc_count_type_r,
		p_count_r                     => ln_rec_cnt,
		p_duration_r                  => gc_duration_r,
		p_created_by_r                => GC_JOB_NAME,
		out_prcs_job_log_message_id_r => gn_job_log_message_id_r
	);

	--19th Aug 2025: Added Local Index Rebuild
	PKG_GRP_COMMON_UTIL.prc_rebuild_index_partitions
	(
		p_table_name   		  		  => 'RPT_CLAIM_DTL_R',
		p_parallel_degree   		  => 8,
		p_partition_name  		  	  => 'PART_RPT_CLAIM_DTL_R_'||gn_current_month,
		p_out_job_id              	  => gn_out_job_id,
		p_Log_seq_num             	  => 4
	);

     INSERT INTO ATOMIC.SSL_PACKAGE_LOG_TABLE(job_name,process_name, start_date, end_date)
        VALUES ('PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC','END: UPDATE N_ANY_OCC_DAYS_REMAINING_R COLUMN',  NULL,SYSDATE);
        COMMIT;

-- Mark the job as complete
    UPDATE ATOMIC.SSL_PACKAGE_MILESTONE_TABLE SET
        JOB_TIMESTAMP   = CURRENT_TIMESTAMP,
        JOB_STATUS      = 'SUCCESS',
        START_DATE      = END_DATE,
        END_DATE        = (SELECT MAX(t_last_modified_date_r) FROM ATOMIC.dim_grp_claim_dir_r WHERE V_ACTIVE_STATUS_R = 'Y')
    WHERE JOB_NAME='PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC';
    COMMIT;

 INSERT INTO ATOMIC.SSL_PACKAGE_LOG_TABLE(job_name,process_name, start_date, end_date)
    VALUES ('PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC','END: MAIN PROCESS - LOAD RPT_CLAIM_DTL_R TABLE',  NULL,SYSDATE);
    COMMIT;
 gc_trcmsg:='1.z Exit from main'||chr(13);
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
		 (
			p_job_id_r                    => gn_out_job_id,
			p_batch_id_r                  => gn_sysdt_batchid,
			p_message_type_r              => gc_message_type_r,
			p_code_location_r             => gc_main_loadedby,
			p_message_r                   => gc_trcmsg,
			p_count_type_r                => NULL,
			p_count_r                     => NULL,
			p_duration_r                  => NULL,
			p_created_by_r                => GC_JOB_NAME,
			out_prcs_job_log_message_id_r => gn_job_log_message_id_r
		);
  --Perf Tuning Changes: End : Load data from Source

    /**************************************** END: PERFORMANCE TUNING MAIN QUERY *********************************************/




	-- Perf Improvement: Start: No Longer required - handle as  the rpt load query
/*
	gc_trcmsg:=gc_trcmsg||'4. Call prc_get_cur_data to get ref_cursor '||chr(13);


	PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC.prc_get_cur_data (var_ref_cur);

    gc_trcmsg:=gc_trcmsg||'4.z Completed Call Procedure prc_get_cur_data to get ref_cursor'||chr(13);
    ln_start_time := dbms_utility.get_time;
	gc_trcmsg:=gc_trcmsg||'5 data load starts '||ln_START_TIME||chr(13);
	ln_rec_cnt:=0;
    LOOP
	lt_var_tbl_typ.DELETE;
    FETCH var_ref_cur BULK COLLECT INTO  lt_var_tbl_typ LIMIT gn_bulk_coll_cnt;
     FORALL X in LT_VAR_TBL_TYP.first..LT_VAR_TBL_TYP.last
 */--    INSERT /*+APPEND_VALUES*/ INTO RPT_CLAIM_DTL_R VALUES lt_var_tbl_typ(x) ;
/*	 ln_rec_cnt:=ln_rec_cnt+lt_var_tbl_typ.COUNT;
	 COMMIT;
     EXIT WHEN var_ref_cur%NOTFOUND;
    END LOOP;
	CLOSE var_ref_cur;
    gc_trcmsg:=gc_trcmsg||'5.z Data Loaded '||ln_rec_cnt||' records '||chr(13);
 	gc_trcmsg:=gc_trcmsg||'6. Call procedure prc_insert_dummy_rec from main '||((dbms_utility.get_time - ln_start_time)/100)||chr(13);
    PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC.prc_insert_dummy_rec;
    gc_trcmsg:=gc_trcmsg||'6.z Completed Procedure prc_insert_dummy_rec from main'||chr(13);
    ln_START_TIME := DBMS_UTILITY.GET_TIME;
 	gc_trcmsg:=gc_trcmsg||'7. Call procedure unusable prc_rebuild_indexes from main '||ln_START_TIME||chr(13);
    PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC.prc_rebuild_indexes;
    gc_trcmsg:=gc_trcmsg||'7.z Completed Procedure unusable prc_rebuild_indexes call from main '||((dbms_utility.get_time - ln_start_time)/100)||chr(13);
    ln_START_TIME := DBMS_UTILITY.GET_TIME;
 	--gc_trcmsg:=gc_trcmsg||'8. Gather RPT_CLAIM_DTL_R table stats from main '||ln_START_TIME||chr(13);
    --DBMS_STATS.GATHER_TABLE_STATS('ATOMIC','RPT_CLAIM_DTL_R');
    --gc_trcmsg:=gc_trcmsg||'8.z Completed Gather RPT_CLAIM_DTL_R table stats from main'||((dbms_utility.get_time - ln_start_time)/100)||chr(13);
    --ln_START_TIME := DBMS_UTILITY.GET_TIME;
    gc_trcmsg:=gc_trcmsg||'9. Update D_CLAIM_AS_OF_DATE_R starts from main '||ln_START_TIME||chr(13);
 */--   UPDATE /*+PARALLEL(4)*/ RPT_CLAIM_DTL_R
/*      set D_CLAIM_AS_OF_DATE_R=gd_pacs_as_of_date_r--PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC.get_pacs_as_of_date_r
    where RPT_CLAIM_DTL_R.n_yearmonth_r=gn_current_month;
	commit;
    gc_trcmsg:=gc_trcmsg||'9.z Update D_CLAIM_AS_OF_DATE_R completed from main '||((dbms_utility.get_time - ln_start_time)/100)||chr(13);
*/
	-- Perf Improvement: End: No Longer required - handle as  the rpt load query

 /*ln_START_TIME := DBMS_UTILITY.GET_TIME;
    gc_trcmsg:=gc_trcmsg||'10. Update N_ANY_OCC_DAYS_REMAINING_Rstarts from main '||ln_START_TIME||chr(13);
    OPEN  cur_upd_occdays_remain ;
	LOOP
	lt_var_upd_tbl_dys_typ.DELETE;
    FETCH cur_upd_occdays_remain bulk collect into  lt_var_upd_tbl_dys_typ limit GN_BULK_COLL_CNT;
	FORALL X in lt_var_upd_tbl_dys_typ.first..lt_var_upd_tbl_dys_typ.last
    UPDATE  RPT_CLAIM_DTL_R
      set N_ANY_OCC_DAYS_REMAINING_R=lt_var_upd_tbl_dys_typ(X).N_ANY_OCC_DAYS_REMAINING_R
    where RPT_CLAIM_DTL_R.n_yearmonth_r=gn_current_month
    and (RPT_CLAIM_DTL_R.D_ANY_OCC_START_DATE_R)=lt_var_upd_tbl_dys_typ(X).D_ANY_OCC_START_DATE_R;
     commit;
     EXIT WHEN cur_upd_occdays_remain%NOTFOUND;
    END LOOP;
	CLOSE cur_upd_occdays_remain;
    gc_trcmsg:=gc_trcmsg||'10.z Update N_ANY_OCC_DAYS_REMAINING_R completed from main '||((dbms_utility.get_time - ln_start_time)/100)||chr(13);
    ln_START_TIME := DBMS_UTILITY.GET_TIME;
    gc_trcmsg:=gc_trcmsg||'11. update ach ind from main '||ln_START_TIME||chr(13);
    OPEN  cur_upd_achpmnt_ind ;
	LOOP
	lt_var_upd_tbl_pmntind_typ.DELETE;
    FETCH cur_upd_achpmnt_ind bulk collect into  lt_var_upd_tbl_pmntind_typ limit GN_BULK_COLL_CNT;
	--FOR I in lt_var_upd_tbl_pmntind_typ.first..lt_var_upd_tbl_pmntind_typ.last
	--LOOP
	--   LV_CLAIM_ACH_PAYMENT_IND_R:=NULL;
	--   SELECT PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC.get_v_claim_ach_payment_ind_r(lt_var_upd_tbl_pmntind_typ(I).N_CLAIM_SK_R)
	--   INTO LV_CLAIM_ACH_PAYMENT_IND_R
	--   FROM DUAL;
	--   lt_var_upd_tbl_pmntind_typ(I).V_CLAIM_ACH_PAYMENT_IND_R:=LV_CLAIM_ACH_PAYMENT_IND_R;
	--END LOOP;
	FORALL X in lt_var_upd_tbl_pmntind_typ.first..lt_var_upd_tbl_pmntind_typ.last
    UPDATE   RPT_CLAIM_DTL_R
      set V_CLAIM_ACH_PAYMENT_IND_R=lt_var_upd_tbl_pmntind_typ(X).V_CLAIM_ACH_PAYMENT_IND_R
    where RPT_CLAIM_DTL_R.n_yearmonth_r=gn_current_month
    and (RPT_CLAIM_DTL_R.n_claim_sk_r)=lt_var_upd_tbl_pmntind_typ(X).n_claim_sk_r;
     commit;
     EXIT WHEN cur_upd_achpmnt_ind%NOTFOUND;
    END LOOP;
	CLOSE cur_upd_achpmnt_ind;
 	gc_trcmsg:=gc_trcmsg||'11.z update ach ind completed from main '||((dbms_utility.get_time - ln_start_time)/100)||chr(13);
    --30-Jan-2024 changes starts
 	ln_START_TIME:=dbms_utility.get_time;
    gc_trcmsg:=gc_trcmsg||'12. update Total and Current Period Days from main '||ln_START_TIME||chr(13);
    OPEN  cur_upd_perioddys ;
	LOOP
	lt_var_upd_tbl_perioddys_typ.DELETE;
    FETCH cur_upd_perioddys bulk collect into  lt_var_upd_tbl_perioddys_typ limit GN_BULK_COLL_CNT;
	FORALL X in lt_var_upd_tbl_perioddys_typ.first..lt_var_upd_tbl_perioddys_typ.last
    UPDATE   RPT_CLAIM_DTL_R
      set n_curr_benefit_period_days_r=lt_var_upd_tbl_perioddys_typ(X).n_curr_benefit_period_days_r
      , n_total_benefit_period_days_r=lt_var_upd_tbl_perioddys_typ(X).n_total_benefit_period_days_r
    where RPT_CLAIM_DTL_R.n_yearmonth_r=gn_current_month
    and (RPT_CLAIM_DTL_R.V_CLAIM_NUMBER_R)=lt_var_upd_tbl_perioddys_typ(X).V_CLAIM_NUMBER_R;
     commit;
     EXIT WHEN cur_upd_perioddys%NOTFOUND;
    END LOOP;
	CLOSE cur_upd_perioddys;
    gc_trcmsg:=gc_trcmsg||'12.z Update Total and Current Period Days completed from main '||((dbms_utility.get_time - ln_start_time)/100)||chr(13);
	ln_START_TIME:=dbms_utility.get_time;
    gc_trcmsg:=gc_trcmsg||'13. update start and end dates from main '||ln_START_TIME||chr(13);
    OPEN  cur_upd_dates ;
	LOOP
	lt_var_upd_tbl_dates_typ.DELETE;
    FETCH cur_upd_dates bulk collect into  lt_var_upd_tbl_dates_typ limit GN_BULK_COLL_CNT;
	FORALL X in lt_var_upd_tbl_dates_typ.first..lt_var_upd_tbl_dates_typ.last
    UPDATE   RPT_CLAIM_DTL_R
      set d_closed_month_start_date_r=lt_var_upd_tbl_dates_typ(x).d_closed_month_start_date_r
      , d_closed_month_end_date_r=lt_var_upd_tbl_dates_typ(X).d_closed_month_end_date_r
    where rowid=lt_var_upd_tbl_dates_typ(X).row_id;
     commit;
     EXIT WHEN cur_upd_dates%NOTFOUND;
    END LOOP;
	CLOSE cur_upd_dates;
    gc_trcmsg:=gc_trcmsg||'13.z Update start and end dates completed from main '||((dbms_utility.get_time - ln_start_time)/100)||chr(13);

	ln_start_time:=dbms_utility.get_time;
    gc_trcmsg:=gc_trcmsg||'14. update Most Medical Date and Note from main '||ln_start_time||chr(13);
    OPEN  cur_upd_mostmed ;
    LOOP
    lt_var_upd_tbl_mostmed_typ.DELETE;
    FETCH cur_upd_mostmed bulk collect into  lt_var_upd_tbl_mostmed_typ limit gn_bulk_coll_cnt;
    FORALL X in lt_var_upd_tbl_mostmed_typ.first..lt_var_upd_tbl_mostmed_typ.last
    UPDATE   RPT_CLAIM_DTL_R
      set d_most_recent_medical_note_date_r=lt_var_upd_tbl_mostmed_typ(X).d_most_recent_medical_note_date_r
      , v_most_recent_medical_note_r       =lt_var_upd_tbl_mostmed_typ(X).v_most_recent_medical_note_r
    where n_yearmonth_r=gn_current_month
	  and n_claim_sk_r=lt_var_upd_tbl_mostmed_typ(X).n_claim_sk_r;
     commit;
     EXIT WHEN cur_upd_mostmed%NOTFOUND;
    END LOOP;
    CLOSE cur_upd_mostmed;
    gc_trcmsg:=gc_trcmsg||'14.z Update Most Medical Date and Note completed from main '||((dbms_utility.get_time - ln_start_time)/100)||chr(13);

    ln_start_time:=dbms_utility.get_time;
    gc_trcmsg:=gc_trcmsg||'15. update Most Management Date and Note from main '||ln_start_time||chr(13);
    OPEN  cur_upd_mostmgmnt ;
    LOOP
    lt_var_upd_tbl_mostmgmnt_typ.DELETE;
    FETCH cur_upd_mostmgmnt bulk collect into  lt_var_upd_tbl_mostmgmnt_typ limit gn_bulk_coll_cnt;
    FORALL X in lt_var_upd_tbl_mostmgmnt_typ.first..lt_var_upd_tbl_mostmgmnt_typ.last
    UPDATE   RPT_CLAIM_DTL_R
      set d_most_recent_management_note_date_r=lt_var_upd_tbl_mostmgmnt_typ(X).d_most_recent_management_note_date_r
        , v_most_recent_mgmt_note_r           =lt_var_upd_tbl_mostmgmnt_typ(X).v_most_recent_mgmt_note_r
    where n_claim_sk_r=lt_var_upd_tbl_mostmgmnt_typ(X).n_claim_sk_r
	  and n_yearmonth_r=gn_current_month;
     commit;
     EXIT WHEN cur_upd_mostmgmnt%NOTFOUND;
    END LOOP;
    CLOSE cur_upd_mostmgmnt;
    gc_trcmsg:=gc_trcmsg||'15.z Update Most Management Date and Note completed from main '||((dbms_utility.get_time - ln_start_time)/100)||chr(13);
    */
   /*gc_trcmsg:=gc_trcmsg||'13. update Offset Amts from main '||ln_START_TIME||chr(13);
    OPEN  cur_upd_offset ;
	LOOP
	lt_var_upd_tbl_offset_typ.DELETE;
    FETCH cur_upd_offset bulk collect into  lt_var_upd_tbl_offset_typ limit gn_bulk_coll_cnt;
	FORALL X in lt_var_upd_tbl_offset_typ.first..lt_var_upd_tbl_offset_typ.last
    UPDATE   RPT_CLAIM_DTL_R
      set n_rehab_offset_amt_088_r        =lt_var_upd_tbl_offset_typ(x).n_rehab_offset_amt_088_r
        , n_workers_comp_offset_amt_083_r =lt_var_upd_tbl_offset_typ(x).n_workers_comp_offset_amt_083_r
        , n_other_offset_amt_r            =lt_var_upd_tbl_offset_typ(x).n_other_offset_amt_r
        , v_rehab_offset_ind_088_r        =lt_var_upd_tbl_offset_typ(x).v_rehab_offset_ind_088_r
    where RPT_CLAIM_DTL_R.n_yearmonth_r=gn_current_month
    and RPT_CLAIM_DTL_R.n_claim_coverage_group_sk_r=lt_var_upd_tbl_offset_typ(X).n_claim_coverage_group_sk_r
    and RPT_CLAIM_DTL_R.n_claim_sk_r=lt_var_upd_tbl_offset_typ(X).n_claim_sk_r;
     commit;
     EXIT WHEN cur_upd_offset%NOTFOUND;
    END LOOP;
	CLOSE cur_upd_offset;
    gc_trcmsg:=gc_trcmsg||'13.z Update Offset Amts completed from main '||((dbms_utility.get_time - ln_start_time)/100)||chr(13);
   --31-Jan-2024 changes ends
*/


	gc_trcmsg:=gc_trcmsg||'1.z Exit from main'||chr(13);
    pkg_grp_log_util.prc_update_log
      (
        gn_out_job_id                   --p_job_id
        ,gc_success_status              --p_job_status
        ,gc_errmsg                      --p_err_msg
        ,gc_trcmsg                      --p_trc_msg
        ,gc_main_loadedby               --p_log_util_called_by_r
      );

EXCEPTION
WHEN OTHERS THEN
    gc_errmsg :=SUBSTR(SQLERRM,1,4000);
    gc_trcmsg:='1. Error in main - '||gc_errmsg;
      /*START: 20-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
        pkg_grp_log_util.prc_update_log_message_r
    (
        n_prcs_job_log_message_id_r => gn_job_log_message_id_r,
        p_err_msg => gc_trcmsg
    );
    /*END: 20-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
    pkg_grp_log_util.prc_update_log
      (
        gn_out_job_id                   --p_job_id
        ,gc_error_status                --p_job_status
        ,gc_errmsg                       --p_err_msg
        ,gc_trcmsg                      --p_trc_msg
        ,gc_main_loadedby               --p_log_util_called_by_r
      );
    RAISE;
END main;

--Procedure to perform ref cursor assignment
PROCEDURE prc_get_cur_data(
    p_out_cursor OUT SYS_REFCURSOR
	)
AS
BEGIN
       GC_TRCMSG:=GC_TRCMSG||'4.1 Entered into prc_get_cur_data '||CHR(13);
	   --Open/Assign SELECT stmnt
        open P_OUT_CURSOR for
        select /*+PARALLEL(8)*/
        V_ADD_DIAG_CATEGORY_CODE_R
        ,V_ADD_DIAG_CATEGORY_DESC_R
        ,V_ADD_DIAGNOSIS_CODE_R
        ,V_PRI_DIAG_CATEGORY_CODE_R
        ,V_PRI_DIAG_CATEGORY_DESC_R
        ,V_PRI_DIAGNOSIS_CODE_R
        ,N_DIAGNOSIS_TYPE_CODE_R
        ,V_ADD_DIAG_CODE_DESC_R
        ,V_PRI_DIAG_CODE_DESC_R
        ,D_LAST_PAYMENT_DATE_R
        ,D_AGE_REDUCTION_DATE_R
        ,V_CLAIM_ACH_PAYMENT_IND_R
        ,D_BENEFIT_START_R
        ,V_CAUSE_OF_EVENT_CODE_R
        ,V_CAUSE_OF_EVENT_DESC_R
        ,V_CLAIM_CLASS_ID_R
        ,D_CLAIM_CLOSED_DATE_R
        ,V_ELIGIBILITY_DECISION_R
        ,V_ELIGIBILITY_REASON_R
        ,N_CLAIM_COVERAGE_GROUP_SK_R
        ,N_CLAIM_COVERAGE_SK_R
        ,N_CLAIM_SK_R
        ,V_CLAIM_EVENT_NUMBER_R
        ,V_CLAIM_NUMBER_R
        ,N_CLAIM_PENDING_AGE_R
        ,N_CLAIM_TAXABLE_BENEFIT_PCT_R
        ,N_DAYS_OPEN_R
        ,D_DISABILITY_START_DATE_R
        ,V_EXERTION_LEVEL_R
        ,V_DURATION_INDICATOR_R
        ,V_DURATION_PERIOD_R
        ,D_EARLIEST_BENEFIT_PAYMENT_DATE_R
        ,D_EARLIEST_SERVICE_PERIOD_FROM_R
        ,D_EARLIEST_SERVICE_PERIOD_TO_R
        ,V_ELIMINATION_PERIOD_R
        ,D_EST_QUALIFYING_PERIOD_EXP_DATE_R
        ,V_EST_SS_IND_R
        ,V_EXTENDED_DURATION_IND_R
        ,D_LOSS_DATE_R
        ,D_MODIFIED_RTW_DATE_R
        ,D_MOST_RECENT_SERVICE_PERIOD_FROM_R
        ,D_MOST_RECENT_SERVICE_PERIOD_TO_R
        ,D_NURSE_CERT_END_DATE_R
        ,N_NURSE_CERT_SEQ_R
        ,V_OCCUPATION_CODE_R
        ,V_OCCUPATION_DESC_R
        ,V_PFL_CHILD_GENDER_R
        ,D_PFL_DOB_R
        ,V_MANDATED_FAMILY_MEMBER_R
        ,V_LEAVE_REASON_R
        ,D_PFL_DOP_R
        ,D_PHYS_CERT_END_DATE_R
        ,D_PLAN_DUR_DATE_R
        ,D_RETIREMENT_TERMINATION_DATE_R
        ,D_RETURN_TO_WORK_DATE_R
        ,V_SOCIAL_SECURITY_IND_R
        ,V_TURNAROUND_RANGE_R
        ,V_WAIVER_IND_R
        ,D_WAIVER_STATUS_DATE_R
        ,N_WAIVER_TERMINATION_AGE_R
        ,D_WAIVER_TERMINATION_DATE_R
        ,D_CLAIM_AS_OF_DATE_R
        ,V_METHOD_R
        ,V_METHOD_STYLE_R
        ,V_CLAIM_IDENTIFIER_R
        ,D_MOST_RECENT_ACTIVITY_DATE_R
        ,D_CLAIM_RECEIVED_DATE_R
        ,FIC_MIS_DATE_R
        ,V_LTD_POLICY_IND_R
        ,V_CLAIM_COMPANY_R
        ,V_PRIVACY_INDICATOR_R
        ,N_ANY_OCC_DAYS_REMAINING_R
        ,D_ANY_OCC_DECISION_DATE_R
        ,V_ANY_OCC_PERIOD_R
        ,V_ANY_OCC_PERIOD_IND_R
        ,D_ANY_OCC_START_DATE_R
        ,V_ANY_OCC_OWN_OCC_IND_R
        ,V_OWN_OCC_PERIOD_R
        ,V_OWN_OCC_PERIOD_IND_R
        ,V_CLAIM_COVERAGE_CODE_R
        ,V_PRODUCT_LINE_DESC_R
        ,N_COV_GRP_ID_R
        ,V_CLAIM_COVERAGE_DESC_R
        ,D_APPEAL_RECEIVED_DATE_R
        ,V_APPEAL_DENIAL_OVERTURN_TYPE_R
        ,V_APPEALS_ANALYST_R
        ,D_APPEAL_COMPLETED_DATE_R
        ,N_APPEAL_SOURCE_VERSION_SEQ_NUMBER_R
        ,D_MOST_RECENT_MEDICAL_NOTE_DATE_R
        ,V_MOST_RECENT_MEDICAL_NOTE_R
        ,D_MOST_RECENT_MANAGEMENT_NOTE_DATE_R
        ,V_MOST_RECENT_MGMT_NOTE_R
        ,D_SS_DEP_AWARD_EFF_DATE_R
        ,V_SS_DEPENDENT_STATUS_R
        ,D_SS_DEP_TERM_DATE_R
        ,V_SS_DEP_AWARD_TYPE_R
        ,V_SS_DEP_PURSUE_IND_R
        ,D_SS_MOST_RECENT_UPDATE_DATE_R
        ,D_SS_PRIMARY_EFF_DATE_R
        ,V_SS_STATUS_DESCRIPTION_R
        ,D_SS_CLOSED_TERM_DATE_R
        ,V_SS_PRIMARY_AWARD_TYPE_R
        ,V_SS_PRIMARY_PURSUE_IND_R
        ,V_SS_REJECT_REASON_CODE_R
        ,V_SS_REJECT_REASON_R
        ,V_CLAIM_STATUS_CATEGORY_R
        ,V_CLAIM_STATUS_CODE_R
        ,V_CLAIM_STATUS_DESC_R
        ,D_CLAIM_STATUS_EFF_DATE_R
        ,D_LAST_IN_STATUS_46_DATE_R
        ,V_PRIOR_CLAIM_STATUS_CLOSURE_CODE_R
        ,V_PRIOR_CLAIM_STATUS_CODE_R
        ,V_SALES_CLAIM_STATUS_DESC_R
        ,V_CURR_CLAIM_STATUS_CODE_R
        ,V_CLAIM_TYPE_R
        ,D_TIER_CREATED_DATE_R
        ,D_WFAM_CODE_CREATED_DATE_R
        ,V_TIER_R
        ,V_WFAM_R
        ,D_PRD_R
        ,D_PRD_DAYS_REMAINING_R
        ,V_ACCOMMODATIONS_NEEDED_R
        ,V_CLINICAL_VOC_ENGAGEMENT_R
        ,V_TIER_DESCRIPTION_R
        ,N_TIER_NUM_R
        ,V_RECOVERY_EXPECTATIONS_R
        ,V_VOC_REHAB_STATUS_R
        ,V_VOC_REHAB_MGR_NAME_R
        ,V_VOC_REHAB_SPECIALIST_R
        ,V_SERVICE_REQUESTED_OTHER_R
        ,V_SERVICE_REQUESTED_R
        ,V_VOC_REHAB_OUTCOME_R
        ,V_VOC_REHAB_ACTIVE_STATUS_R
        ,D_TSA_DATE_R
        ,V_LOCATION_NUMBER_R
        ,V_CORRESPONDENT_NAME_R
        ,V_SUBGROUP_ADDRESSLINE1_R
        ,V_SUBGROUP_ADDRESSLINE2_R
        ,V_SUBGROUP_CITY_R
        ,V_SUBGROUP_ID_R
        ,V_SUBGROUP_NAME_R
        ,V_SUBGROUP_POSTALZIP_R
        ,V_SUBGROUP_PROVSTATE_R
        ,V_LAST_MODIFIED_BY_R
        ,T_CREATION_DATE_R
        ,V_CREATED_BY_R
        ,T_LAST_MODIFIED_DATE_R
        ,N_YEARMONTH_R
        ,V_RPT_ACTIVE_STATUS_R
        ,N_BATCH_ID_R
        ,V_EXAMINER_ID_R
        ,V_EXAMINER_NAME_R
        ,D_HIRE_DATE_R
        --26-dEC-2023 CHANGES STARTS
        ,d_ss_council_start_date_r
        ,d_ss_appeal_end_date_r
        ,d_ss_court_start_date_r
        ,d_ss_court_appeal_end_date_r
        ,d_ss_hearing_start_date_r
        ,d_ss_hearing_end_date_r
        ,d_ss_init_filing_start_date_r
        ,d_ss_init_filing_end_date_r
        ,d_ss_reconsider_start_date_r
        ,d_ss_reconsider_end_date_r
        ,V_SS_HARDSHIP_IND_R
        --26-dEC-2023 CHANGES ENDS
        ,D_WORKSHEET_START_DATE_R
        ,D_WORKSHEET_END_DATE_R
        ,v_lob_type_r --19-JAN-2024 CHANGES
        --23-jAN-2024 changes starts
        ,V_SOURCE_SYSTEM_NAME_R
        ,N_CURR_BENEFIT_PERIOD_DAYS_R
        ,N_TOTAL_BENEFIT_PERIOD_DAYS_R
        --23-jAN-2024 changes ends
        --26-jAN-2024 changes starts
        ,N_BASIC_INSURED_SALARY_R
        ,V_BASIC_INSURED_SALARY_IND_R
        --26-jAN-2024 changes ends
        --31-jAN-2024 changes starts
        ,n_rehab_offset_amt_088_r
        ,v_rehab_offset_ind_088_r
        ,n_workers_comp_offset_amt_083_r
        ,n_other_offset_amt_r
        ,v_pfl_leave_type_r
        ,v_pfl_license_number_r
        --31-jAN-2024 changes ends
        --20-Feb-2024 changes ends
        ,d_closed_month_start_date_r
        ,d_closed_month_end_date_r
        --20-Feb-2024 changes ends
        --15-Jun-2024 changes starts
        ,V_APPEAL_IND_R
        ,V_APPEAL_RESULT_STATUS_CODE_R
        ,D_APPEAL_RESULT_STATUS_CODE_EFF_DATE_R		,
        --15-Jun-2024 changes ends
        --21/Jun/2024 - Changes start
          CAST(NULL AS VARCHAR2(300 CHAR)) V_APPEAL_ANALYST_NAME_r         ,
          CAST(NULL AS VARCHAR2(300 CHAR)) V_APPEAL_STATUS_CODE_R          ,
          CAST(NULL AS VARCHAR2(300 CHAR)) V_RPT_WORKSHEET_INDICATOR_R     ,
          CAST(NULL AS number)            N_WORKSHEET_NUMBER_R            ,
          CAST(NULL AS VARCHAR2(300 CHAR)) V_WORKSHEET_STATUS_R            ,
          CAST(NULL AS NUMBER)            N_WORKSHEET_SEQ_NBR_OBJECTNM_R,
          case when v_coverage_type_code_r ='1' then 'LTD'
          when v_coverage_type_code_r = '2' then 'STD'
          when v_coverage_type_code_r = '3' then  'Life'
          else v_coverage_type_code_r
          end as                          v_coverage_type_code_r,
          N_MAX_BENEFIT_R,
          N_MINIMUM_BENEFIT_R,
        --21/Jun/2024 - Changes end
        --26/08/24 Changes Start
        V_CLAIM_WELLNESS_IND_R
        --26/08/24 Changes End
       ,V_HAS_ASSOCIATED_WAIVER_IND_R--11/09/24 CHANGES
       ,V_HAS_ASSOCIATED_LTD_IND_R   --11/09/24 CHANGES
        --11/09/24 changes start
       , V_CLAIM_STATUS_REASON_DESC_R
        --11/09/24 changes end
		--23/09/34 Changes Start
		,D_CLAIM_DECISION_DATE_R
		,N_CLAIM_DECISION_DAYS_R
		,V_TURNAROUND_RANGE1_R
        --23/09/34 Changes Start
         from (
        select
        --20-Feb-2024 changes starts
        --case when v_lob_type_r in ('LTD', 'STD', 'VPL', 'VPS') then rank() over (partition by v_claim_identifier_r order by b.N_CLAIM_CVRG_SEQUENCE_NUMBER_R desc nulls --last)else 1 end rank,
        /*case when v_lob_type_r in ('LTD', 'STD', 'VPL', 'VPS','WOP') then rank() over (partition by a.v_claim_number_r order by b.N_CLAIM_CVRG_SEQUENCE_NUMBER_R desc nulls last)else 1 end rank,
		--20-Feb-2024 changes ends */
		--24-Jul-2024 changes starts
        case when v_lob_type_r in ('LTD', 'STD', 'VPL', 'VPS') then rank() over (partition by a.v_claim_number_r order by b.N_CLAIM_CVRG_SEQUENCE_NUMBER_R desc nulls last)
        when v_lob_type_r ='WOP'  THEN
               case WHEN g.N_CLAIM_CVRG_GRP_SRC_SYS_KEY_R IS NULL
  	     		THEN CASE
  	     				WHEN rank() OVER (
  	     						PARTITION BY g.n_claim_sk_r ORDER BY g.N_CLAIM_CVRG_GRP_SRC_SYS_KEY_R desc nulls last, g.N_CLAIM_CVRG_SEQUENCE_NUMBER_R desc NULLS LAST
  	     						) = 1
  	     					THEN 1
  	     				ELSE 0
  	     				END
               ELSE 1
               end
        else 1 end rank,
		--24-Jul-2024 changes ends
         diag.additional_diag_code                                                       V_ADD_DIAG_CATEGORY_CODE_R
        ,diag.add_diag_category_desc                                                     V_ADD_DIAG_CATEGORY_DESC_R
        ,diag.additional_diag_code                                                       V_ADD_DIAGNOSIS_CODE_R	                    --On-priority
        ,diag.V_PRI_DIAG_CATEGORY_CODE_R                                                 V_PRI_DIAG_CATEGORY_CODE_R	                --On-priority
        ,diag.V_PRI_DIAG_CATEGORY_DESC_R                                                 V_PRI_DIAG_CATEGORY_DESC_R	                --On-priority
        ,diag.primary_diag_code                                                          V_PRI_DIAGNOSIS_CODE_R	                    --On-priority
        ,diag.diagnosis_type_code                                                        N_DIAGNOSIS_TYPE_CODE_R	                --On-priority
        ,diag.additional_desc                                                            V_ADD_DIAG_CODE_DESC_R	                    --On-priority
        ,DIAG.Primary_desc                                                               V_PRI_DIAG_CODE_DESC_R	                    --On-priority
        ,PAYMENT_DATES.Last_Payment_Date                                                 D_LAST_PAYMENT_DATE_R	                    --On-priority
        ,G.D_AGE_REDUCTION_DATE_R                                                        D_AGE_REDUCTION_DATE_R
        --,OV_CLAIM_ACH_PAYMENT.ACH_indicator                                              V_CLAIM_ACH_PAYMENT_IND_R
        --,CAST(NULL AS VARCHAR2(100))                                                     V_CLAIM_ACH_PAYMENT_IND_R
        --,PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC.get_v_claim_ach_payment_ind_r(a.n_claim_sk_r)     V_CLAIM_ACH_PAYMENT_IND_R	--19-Jan-2024 changes
        ,CAST(NULL AS VARCHAR2(100))                                                      V_CLAIM_ACH_PAYMENT_IND_R	--19-Jan-2024 changes
        ,case when v_lob_type_r in ('LTD', 'STD', 'VPL', 'VPS')
        then m.D_BENEFIT_START_R else n.D_BENEFIT_START_R     end                        D_BENEFIT_START_R
        ,t.v_event_cause_r                                                               V_CAUSE_OF_EVENT_CODE_R
        --,DIM_GRP_LOSS_R.V_LOSS_DESC_R                                                    V_CAUSE_OF_EVENT_DESC_R
        ,cast(null as varchar2(100))                                                     V_CAUSE_OF_EVENT_DESC_R
        ,(CASE WHEN a.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP')
          THEN g.V_CLASS_ID_R
          ELSE b.V_CLASS_ID_R
          END
          )                                                                  			 V_CLAIM_CLASS_ID_R--On-priority
        --30/09/24 changes starts
		--,d.d_closure_date_r                                                              D_CLAIM_CLOSED_DATE_R	                    --On-priority
       /* ,(CASE WHEN a.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP')
               THEN g.D_DATE_CLOSED_R
               else D.d_closure_date_r
          end
		 )                                                                               D_CLAIM_CLOSED_DATE_R	  */
        ,(CASE WHEN a.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP') and A.V_SOURCE_SYSTEM_NAME_R = 'PACS'
              THEN g.D_DATE_CLOSED_R
              else D.d_closure_date_r
          end
                                              )                                          D_CLAIM_CLOSED_DATE_R	           --On-priority
        --30/09/24 changes ends
        ,r.V_ELIGIBILITY_OUTCOME_R                                                       V_ELIGIBILITY_DECISION_R	                --On-priority
        ,r.V_DISABILITY_DATE_STATUS_R                                                    V_ELIGIBILITY_REASON_R
        ,g.N_CLAIM_COVERAGE_GROUP_SK_R                                                   N_CLAIM_COVERAGE_GROUP_SK_R	            --On-priority
        ,b.n_claim_coverage_sk_r                                                         N_CLAIM_COVERAGE_SK_R	                    --On-priority
        ,a.N_CLAIM_SK_R                                                                  N_CLAIM_SK_R	                            --On-priority
        ,s.V_CLAIM_EVENT_NUMBER_R                                                        V_CLAIM_EVENT_NUMBER_R
        ,a.V_CLAIM_NUMBER_R                                                              V_CLAIM_NUMBER_R	                         --On-priority
        ,(CASE WHEN d.V_CLAIM_STATUS_REASON_CODE_R IN ('22','46') THEN
           (SYSDATE - RECEIVED_DATE.RECEIVED_DATE)
           ELSE NULL
           END
          )                                                                              N_CLAIM_PENDING_AGE_R	                     --On-priority
        ,m.n_taxable_override_pct_r                                                      N_CLAIM_TAXABLE_BENEFIT_PCT_R
        ,cast(null as number)                                                            N_DAYS_OPEN_R
        ,
        /*(CASE
            WHEN c.v_orig_lob_r = 'VAI' THEN
                t.d_date_of_event_r +
                CASE
                    WHEN r.n_elim_period_r <> ''
                         OR r.n_elim_period_r <> 0 THEN
                            r.n_elim_period_r
                    ELSE
                        0
                END
            ELSE
                t.d_date_of_event_r
        END
        )        */

        (case
                when
                     nvl(r.n_elim_period_r,0) <> 0 THEN
                    r.n_elim_period_r
                WHEN
                    --CASE t.v_event_cause_r--06-May-2024 changes
                    CASE UPPER(t.v_event_cause_r) --06-May-2024 changes
                        WHEN 'ACCIDENT'                        THEN
                            'A6'
                        WHEN 'ACCIDENT - AVIATION'             THEN
                            'A3'
                        WHEN 'ACCIDENT- AVIATION'              THEN
                            'A3'
                        WHEN 'ACCIDENT - OCCUPATIONAL'         THEN
                            'A1'
                        WHEN 'ACCIDENT- OCCUPATIONAL'          THEN
                            'A1'
                        WHEN 'ACCIDENT- OTHER'                 THEN
                            'A6'
                        WHEN 'ACCIDENT - OTHER'                THEN
                            'A6'
                        WHEN 'ACCIDENT - SPORTS'               THEN
                            'A4'
                        WHEN 'ACCIDENT- SPORTS'                THEN
                            'A4'
                        WHEN 'ADOPTION'                        THEN
                            'AE'
                        WHEN 'ALCOHOL'                         THEN
                            'AC'
                        WHEN 'ASSAULT'                         THEN
                            'A5'
                        WHEN 'BONDING'                         THEN
                            'AE'
                        WHEN 'COMMONDISASTER'                  THEN
                            '31'
                        WHEN 'COMMON DISASTER'                 THEN
                            '31'
                        WHEN 'DRUGS'                           THEN
                            'AD'
                        WHEN 'FOSTER'                          THEN
                            'AE'
                        WHEN 'MATERNITY'                       THEN
                            'AE'
                        WHEN 'MENTAL'                          THEN
                            'AA'
                        WHEN 'MISSING INSURED / DISAPPEARANCE' THEN
                            '33'
                        WHEN 'MOTOR VEHICLE'                   THEN
                            'A2'
                        WHEN 'MOTORCYCLE'                      THEN
                            'A2'
                        WHEN 'NERVOUS'                         THEN
                            'AB'
                        WHEN 'SICKNESS'                        THEN
                            'AE'
                        WHEN 'SUICIDE'                         THEN
                            'SU'
                        WHEN 'UNKNOWN / UNDETERMINED'          THEN
                            'UN'
                        WHEN 'UNKNOWN / UNDETER '              THEN
                            'UN'
                        WHEN 'WAR / TERRORISM'                 THEN
                            '40'
                        WHEN 'WELLNESS'                        THEN
                            'WL'
                        ELSE
                            'UN'
                    END
                IN ( 'A1', 'A2', 'A3', 'A4', 'A5',
                     'A6' ) THEN
                    r.n_elim_period_acc_r
                ELSE
                    r.n_elim_period_sick_r
            END
        	)               + D.d_date_of_loss_r                                         D_DISABILITY_START_DATE_R	                 --On-priority--need to check mapping	                 --On-priority--need to check mapping
        ,D.V_EXERTION_LEVEL_R                                                            V_EXERTION_LEVEL_R
        ,(CASE
              WHEN a.v_lob_type_r IN ( 'LTD', 'VPL' ) THEN
                  'M'
              WHEN a.v_lob_type_r IN ( 'STD','VPS' ) THEN
                  'W'
              WHEN NOT r.n_waiver_termination_age_r IS NULL THEN
                  'A'
              ELSE
                  NULL
          END)                                                                           V_DURATION_INDICATOR_R	                     --On-priority
        ,--cast(null as VARCHAR2(100))
           CAST(p.V_CURR_DURATION_R	 AS VARCHAR2(100))														V_DURATION_PERIOD_R
         ,payment_dates.earliest_payment_date                                             D_EARLIEST_BENEFIT_PAYMENT_DATE_R	         --On-priority
        --,PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC.get_d_earliest_service_period_from_r(a.n_claim_sk_r,g.N_CLAIM_COVERAGE_GROUP_SK_R,a.v_lob_type_r)   D_EARLIEST_SERVICE_PERIOD_FROM_R--19-jAN-2024 CHANGES
        --,PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC.get_d_earliest_service_period_to_r(a.n_claim_sk_r,g.N_CLAIM_COVERAGE_GROUP_SK_R,a.v_lob_type_r)     D_EARLIEST_SERVICE_PERIOD_TO_R	--19-jAN-2024 CHANGES
        --,PAYMENT_DATES.MOST_RECENT_SERVICE_PERIOD_FROM_DATE D_EARLIEST_SERVICE_PERIOD_FROM_R--26-jAN-2024 CHANGES  --14-mar-2024 changes
        --,PAYMENT_DATES.MOST_RECENT_SERVICE_PERIOD_TO_DATE   D_EARLIEST_SERVICE_PERIOD_TO_R	--26-jAN-2024 CHANGES--14-mar-2024 changes
        ,PAYMENT_DATES.EARLIEST_SERVICE_PERIOD_FROM_DATE D_EARLIEST_SERVICE_PERIOD_FROM_R--14-mar-2024 changes
        ,PAYMENT_DATES.EARLIEST_SERVICE_PERIOD_TO_DATE   D_EARLIEST_SERVICE_PERIOD_TO_R	--14-mar-2024 changes
        ,CAST((CASE
                WHEN r.n_elim_period_r <> ''
                     OR r.n_elim_period_r <> 0 THEN
                    r.n_elim_period_r
                WHEN
                    --CASE t.v_event_cause_r--06-May-2024 changes
                    CASE UPPER(t.v_event_cause_r) --06-May-2024 changes
                        WHEN 'ACCIDENT'                        THEN
                            'A6'
                        WHEN 'ACCIDENT - AVIATION'             THEN
                            'A3'
                        WHEN 'ACCIDENT- AVIATION'              THEN
                            'A3'
                        WHEN 'ACCIDENT - OCCUPATIONAL'         THEN
                            'A1'
                        WHEN 'ACCIDENT- OCCUPATIONAL'          THEN
                            'A1'
                        WHEN 'ACCIDENT- OTHER'                 THEN
                            'A6'
                        WHEN 'ACCIDENT - OTHER'                THEN
                            'A6'
                        WHEN 'ACCIDENT - SPORTS'               THEN
                            'A4'
                        WHEN 'ACCIDENT- SPORTS'                THEN
                            'A4'
                        WHEN 'ADOPTION'                        THEN
                            'AE'
                        WHEN 'ALCOHOL'                         THEN
                            'AC'
                        WHEN 'ASSAULT'                         THEN
                            'A5'
                        WHEN 'BONDING'                         THEN
                            'AE'
                        WHEN 'COMMONDISASTER'                  THEN
                            '31'
                        WHEN 'COMMON DISASTER'                 THEN
                            '31'
                        WHEN 'DRUGS'                           THEN
                            'AD'
                        WHEN 'FOSTER'                          THEN
                            'AE'
                        WHEN 'MATERNITY'                       THEN
                            'AE'
                        WHEN 'MENTAL'                          THEN
                            'AA'
                        WHEN 'MISSING INSURED / DISAPPEARANCE' THEN
                            '33'
                        WHEN 'MOTOR VEHICLE'                   THEN
                            'A2'
                        WHEN 'MOTORCYCLE'                      THEN
                            'A2'
                        WHEN 'NERVOUS'                         THEN
                            'AB'
                        WHEN 'SICKNESS'                        THEN
                            'AE'
                        WHEN 'SUICIDE'                         THEN
                            'SU'
                        WHEN 'UNKNOWN / UNDETERMINED'          THEN
                            'UN'
                        WHEN 'UNKNOWN / UNDETER '              THEN
                            'UN'
                        WHEN 'WAR / TERRORISM'                 THEN
                            '40'
                        WHEN 'WELLNESS'                        THEN
                            'WL'
                        ELSE
                            'UN'
                    END
                IN ( 'A1', 'A2', 'A3', 'A4', 'A5',
                     'A6' ) THEN
                    r.n_elim_period_acc_r
                ELSE
                    r.n_elim_period_sick_r
            END
        	) AS VARCHAR2(100))                                                                           V_ELIMINATION_PERIOD_R	                     --On-priority
        ,R.D_DATE_QP_ENDS_R                                                              D_EST_QUALIFYING_PERIOD_EXP_DATE_R
        ----,payment_dates.D_PAID_DATE_R                                                     V_EST_SS_IND_R
        ,CAST(NULL AS VARCHAR2(100))                                                      V_EST_SS_IND_R
        --26-jan-2024 changes starts
        --,CAST(NULL AS VARCHAR2(100))                                                          V_EXTENDED_DURATION_IND_R
        ,(Case when a.v_lob_type_r IN ( 'LTD', 'VPL' )
          and p.V_CURR_DURATION_R >= '024'   --26/09/24 Changed from p.V_CURR_DURATION_R <= '024'  to p.V_CURR_DURATION_R >= '024'
          and p.V_CURR_DURATION_R <= '036'
          then 'Y' else 'N' end)                                                          V_EXTENDED_DURATION_IND_R
        --26-jan-2024 changes ends
        ,(CASE
            WHEN C.v_policy_prefix_r = 'VAI' THEN
                D.d_date_of_event_r
            ELSE
                D.d_date_of_loss_r
         END)                                                                            D_LOSS_DATE_R	                             --On-priority
        ,d.D_RETURN_TO_MOD_WKDT_R                                                        D_MODIFIED_RTW_DATE_R	                     --On-priority
        --,PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC.get_d_mostrecent_service_period_from_r(a.n_claim_sk_r,g.N_CLAIM_COVERAGE_GROUP_SK_R,a.v_lob_type_r)             D_MOST_RECENT_SERVICE_PERIOD_FROM_R	                      --19-JAN-2024 CHANGES              --On-priority
        --,PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC.get_d_mostrecent_service_period_to_r(a.n_claim_sk_r,g.N_CLAIM_COVERAGE_GROUP_SK_R,a.v_lob_type_r)               D_MOST_RECENT_SERVICE_PERIOD_TO_R	         --On-priority--19-JAN-2024 CHANGES
        --,PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC.get_d_nurse_cert_end_date_r(a.n_claim_sk_r)        D_NURSE_CERT_END_DATE_R	                 --On-priority                                                                --19-JAN-2024 CHANGES
        ,payment_dates.most_recent_service_period_from_date                              D_MOST_RECENT_SERVICE_PERIOD_FROM_R--19-JAN-2024 CHANGES --21-Mar-2023 changes remapped from null
        ,payment_dates.most_recent_service_period_to_date                                D_MOST_RECENT_SERVICE_PERIOD_TO_R--19-JAN-2024 CHANGES   --21-Mar-2023 changes remapped from null
        ,CAST(NULL AS DATE)                                                              D_NURSE_CERT_END_DATE_R--19-JAN-2024 CHANGES
        ,u.N_NURSE_CERT_SEQ_R                                                            N_NURSE_CERT_SEQ_R
        ,x.V_CODE_R                                                                      V_OCCUPATION_CODE_R 						 --20-Mar-24 alias name changed from t to x
        ,x.V_DESCRIPTION_R                                                               V_OCCUPATION_DESC_R	                     --20-Mar-24 alias name changed from t to x
        ,d.V_CHILD_GENDER_R                                                              V_PFL_CHILD_GENDER_R	                     --On-priority
        ,d.D_PFL_DOB_R                                                                   D_PFL_DOB_R	                             --On-priority
        ,d.V_MANDATED_FAMILY_MEMBER_R                                                    V_MANDATED_FAMILY_MEMBER_R	                 --On-priority
        ,d.V_LEAVE_REASON_R                                                              V_LEAVE_REASON_R	                         --On-priority
        ,d.D_PFL_DOP_R                                                                   D_PFL_DOP_R	                             --On-priority
        ,CAST(NULL AS DATE)                                                              D_PHYS_CERT_END_DATE_R	--TBD
        ,r.D_PLAN_DUR_DATE_R                                                             D_PLAN_DUR_DATE_R	                         --On-priority
        ,g.D_RETIREMENT_TERMINATION_DAT_R                                                D_RETIREMENT_TERMINATION_DATE_R
        ,d.D_RETURN_TO_WORK_DATE_R                                                       D_RETURN_TO_WORK_DATE_R
        ,CAST(NULL AS VARCHAR2(100))                                                     V_SOCIAL_SECURITY_IND_R
        ,(CASE WHEN d.d_closure_date_r - received_date.Received_date BETWEEN 0 AND 3 THEN '0 - 3'
         WHEN d.d_closure_date_r - received_date.Received_date BETWEEN 4 AND 5 THEN '4 - 5'
         WHEN d.d_closure_date_r - received_date.Received_date BETWEEN 6 AND 7 THEN '6 - 7'
         WHEN d.d_closure_date_r - received_date.Received_date BETWEEN 8 AND 10 THEN  '8 - 10'
         WHEN d.d_closure_date_r - received_date.Received_date > 10 THEN '>10' ELSE 'U' END)   V_TURNAROUND_RANGE_R
        ,(CASE WHEN g.V_CLAIM_COVERAGE_CODE_R like '%WP%' then 'Waiver' else 'Non-Waiver' END) V_WAIVER_IND_R	                             --On-priority
        ,(CASE WHEN A.v_lob_type_r = 'WOP' then g.d_date_closed_r else NULL END)              D_WAIVER_STATUS_DATE_R
        ,r.N_WAIVER_TERMINATION_AGE_R                                                    N_WAIVER_TERMINATION_AGE_R
        ,R.D_WAIVER_TERMINATION_DATE_R                                                   D_WAIVER_TERMINATION_DATE_R
        --,PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC.get_pacs_as_of_date_r                              D_CLAIM_AS_OF_DATE_R	                     --On-priority--19-JAN-2024 CHANGES
        ,CAST(NULL AS DATE)                                                              D_CLAIM_AS_OF_DATE_R	                     --On-priority--19-JAN-2024 CHANGES
        --,DIM_GRP_BUSOBJ_AUDIT_R.V_METHOD_R                                             V_METHOD_R
        ,CAST(NULL AS VARCHAR2(100))                                                     V_METHOD_R
        --,DIM_GRP_BUSOBJ_AUDIT_R.V_METHOD_STYLE                                         V_METHOD_STYLE_R
        ,CAST(NULL AS VARCHAR2(100))                                                     V_METHOD_STYLE_R
        ,NVL(G.V_CLAIM_IDENTIFIER_R, a.v_claim_number_r)                                 V_CLAIM_IDENTIFIER_R	                     --On-priority
        --16/08/24 changes start
		--,o.MOST_RECENT_ACTIVITY_DATE                                                     D_MOST_RECENT_ACTIVITY_DATE_R
        ,CASE
            WHEN o.MOST_RECENT_ACTIVITY_DATE IS NULL
            THEN d.T_EVENT_TIMESTAMP_R
            ELSE o.MOST_RECENT_ACTIVITY_DATE END AS D_MOST_RECENT_ACTIVITY_DATE_R
--        CAST(NVL(o.MOST_RECENT_ACTIVITY_DATE, d.T_EVENT_TIMESTAMP_R) AS DATE) AS D_MOST_RECENT_ACTIVITY_DATE_R
		--16/08/24 changes End
		--On-priority
        ,received_date.Received_date                                                     D_CLAIM_RECEIVED_DATE_R
		--On-priority
        ,a.FIC_MIS_DATE_R                                                                FIC_MIS_DATE_R
        ,ltd_policy_indicator.ltd_policy_ind                                             V_LTD_POLICY_IND_R	                         --On-priority
        ,a.V_COMPANY_R                                                                   V_CLAIM_COMPANY_R	                         --On-priority
        --,a.V_PRIVACY_INDICATOR_R                                                         V_PRIVACY_INDICATOR_R                     --01-Mar-2024 changes
        ,NVL(UPPER(a.V_PRIVACY_INDICATOR_R),'EXTERNAL')                                                         V_PRIVACY_INDICATOR_R--01-Mar-2024 changes
        --,(R.d_anyocc_start_date_r
        --- PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC.get_pacs_as_of_date_r)                            N_ANY_OCC_DAYS_REMAINING_R --19-JAN-2024 CHANGES
        ,CAST(NULL AS NUMBER)                                                            N_ANY_OCC_DAYS_REMAINING_R   --19-JAN-2024 CHANGES
        ,r.D_ANYOCC_DATE_R                                                               D_ANY_OCC_DECISION_DATE_R	                 --On-priority
        --26-Jan-2024 changes starts
        --,r.v_own_occ_period_r                                                            V_ANY_OCC_PERIOD_R
        ,(Case when r.v_own_occ_period_r like '%MOS' then substr(r.v_own_occ_period_R,1,2)
          When r.v_own_occ_period_r like '@%' then substr(r.v_own_occ_period_R,2,2)
          End)                                                                             V_ANY_OCC_PERIOD_R
        --,r.v_own_occ_period_r                                                            V_ANY_OCC_PERIOD_IND_R
        ,(Case when r.v_own_occ_period_r like '%MOS' then 'M'
         When r.v_own_occ_period_r like '@%' then 'A'
         End)                                                                              V_ANY_OCC_PERIOD_IND_R
        --26-Jan-2024 changes ends
        ,r.D_ANYOCC_START_DATE_R                                                           D_ANY_OCC_START_DATE_R	                     --On-priority
        --26-Jan-2024 changes starts
        --,r.v_own_occ_period_r                                                            V_ANY_OCC_OWN_OCC_IND_R
        ,(case when r.v_own_occ_period_r like '@%'  then 'Own Occ Only'
                 when gd_pacs_as_of_date_r <= r.D_ANYOCC_START_DATE_R  then 'Own Occ'
                 when gd_pacs_as_of_date_r > r.D_ANYOCC_START_DATE_R    then 'Any Occ'
                 else 'Unknown'
         end )                                                                            V_ANY_OCC_OWN_OCC_IND_R
        --,r.v_own_occ_period_r                                                            V_OWN_OCC_PERIOD_R
        ,(Case when r.v_own_occ_period_r like '%MOS' then substr(r.v_own_occ_period_R,1,2)
          When r.v_own_occ_period_r like '@%' then substr(r.v_own_occ_period_R,2,2)
          End
          )                                                                               V_OWN_OCC_PERIOD_R
        --,r.v_own_occ_period_r                                                           V_OWN_OCC_PERIOD_IND_R
        ,(Case when r.v_own_occ_period_r like '%MOS' then 'M'
          When r.v_own_occ_period_r like '@%' then 'A'
          End)                                                                            V_OWN_OCC_PERIOD_IND_R
        --26-Jan-2024 changes ends
        ,(CASE WHEN a.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP')
          THEN g.V_CLAIM_COVERAGE_CODE_R
          ELSE b.V_CLAIM_COVERAGE_CODE_R
          END
          )                                                                               V_CLAIM_COVERAGE_CODE_R	                 --On-priority
        ,(CASE WHEN a.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP')
          THEN l.V_PRODUCT_LINE_DESC_R
          ELSE j.V_PRODUCT_LINE_DESC_R
          END
          )                                                          					 V_PRODUCT_LINE_DESC_R	                     --On-priority
        ,g.N_COV_GRP_ID_R                                                                N_COV_GRP_ID_R	                             --On-priority
        ,(CASE WHEN a.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP')
          THEN l.v_basic_product_line_desc_r
          ELSE j.v_basic_product_line_desc_r
          END
          )                                                  								V_CLAIM_COVERAGE_DESC_R	                 --On-priority
        --,DIM_GRP_APPEALS_R.D_RECEIVED_DATE_R                                             D_APPEAL_RECEIVED_DATE_R	                 --On-priority
        /*--30-May-2024 changes starts
		,CAST(NULL AS DATE)                                                                D_APPEAL_RECEIVED_DATE_R	                 --On-priority
        --,DIM_GRP_APPEALS_R.V_DENIAL_OVERTURN_TYPE_R                                      V_APPEAL_DENIAL_OVERTURN_TYPE_R	         --On-priority
        ,CAST(NULL AS VARCHAR2(100))                                                       V_APPEAL_DENIAL_OVERTURN_TYPE_R	         --On-priority
        --,DIM_GRP_APPEALS_R.V_USER_ID_R                                                   V_APPEALS_ANALYST_R	                     --On-priority
        ,CAST(NULL AS VARCHAR2(100))                                                       V_APPEALS_ANALYST_R	                     --On-priority
        --,DIM_GRP_APPEALS_R.D_REAFFIRMED_DATE_R                                           D_APPEAL_COMPLETED_DATE_R	                 --On-priority
        ,CAST(NULL AS DATE)                                                                D_APPEAL_COMPLETED_DATE_R	                 --On-priority
        --,DIM_GRP_APPEALS_R.N_SOURCE_VERSION_SEQ_NUMBER_R                                 N_APPEAL_SOURCE_VERSION_SEQ_NUMBER_R	                                    --On-priority
        ,cast(null as number)                                                              N_APPEAL_SOURCE_VERSION_SEQ_NUMBER_R	                                    --On-priority
        */
		,appeal.d_received_date_r                                                          D_APPEAL_RECEIVED_DATE_R
		,appeal.v_denial_overturn_type_r                                                   V_APPEAL_DENIAL_OVERTURN_TYPE_R
		,appeal.v_user_id_r                                                                V_APPEALS_ANALYST_R
		,appeal.d_reaffirmed_date_r                                                        D_APPEAL_COMPLETED_DATE_R
		,appeal.n_source_version_seq_number_r                                              N_APPEAL_SOURCE_VERSION_SEQ_NUMBER_R
		--30-May-2024 changes ends
        --,PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC.get_d_most_recent_medical_note_date_r(a.n_claim_sk_r)    D_MOST_RECENT_MEDICAL_NOTE_DATE_R	         --On-priority--19-JAN-2024 CHANGES
        --,PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC.get_v_most_recent_medical_note_r(a.n_claim_sk_r)         V_MOST_RECENT_MEDICAL_NOTE_R	             --On-priority--19-JAN-2024 CHANGES
        --,PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC.get_d_most_recent_management_note_date_r(a.n_claim_sk_r) D_MOST_RECENT_MANAGEMENT_NOTE_DATE_R	     --On-priority--19-JAN-2024 CHANGES
        --,PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC.get_v_most_recent_mgmt_note_r(a.n_claim_sk_r)            V_MOST_RECENT_MGMT_NOTE_R	                 --On-priority--19-JAN-2024 CHANGES
        ,CAST(NULL AS DATE)                                                                      D_MOST_RECENT_MEDICAL_NOTE_DATE_R	                      --19-JAN-2024 CHANGES
        ,CAST(NULL AS VARCHAR2(4000))                                                            V_MOST_RECENT_MEDICAL_NOTE_R	                          --19-JAN-2024 CHANGES
        ,CAST(NULL AS DATE)                                                                      D_MOST_RECENT_MANAGEMENT_NOTE_DATE_R	                  --19-JAN-2024 CHANGES
        ,CAST(NULL AS VARCHAR2(4000))                                                            V_MOST_RECENT_MGMT_NOTE_R
        ,f.D_SS_DEP_AWARD_EFF_DATE_R                                                     D_SS_DEP_AWARD_EFF_DATE_R
        ,f.V_SS_DEPENDENT_STATUS_R                                                       V_SS_DEPENDENT_STATUS_R
        ,f.D_SS_DEP_TERM_DATE_R                                                          D_SS_DEP_TERM_DATE_R
        ,f.V_SS_DEP_AWARD_TYPE_R                                                         V_SS_DEP_AWARD_TYPE_R
        ,f.v_ss_dep_pursue_flag_r                                                        V_SS_DEP_PURSUE_IND_R	                     --On-priority
        ,f.D_CHANGE_DATE_R                                                               D_SS_MOST_RECENT_UPDATE_DATE_R	             --On-priority
        ,f.D_SS_PRIMARY_EFF_DATE_R                                                       D_SS_PRIMARY_EFF_DATE_R
        ,f.V_SS_STATUS_DESCRIPTION_R                                                     V_SS_STATUS_DESCRIPTION_R
        ,f.D_SS_CLOSED_TERM_DATE_R                                                       D_SS_CLOSED_TERM_DATE_R
        ,f.V_SS_PRIMARY_AWARD_TYPE_R                                                     V_SS_PRIMARY_AWARD_TYPE_R
        --,f.v_ss_pursue_flag_r                                                            V_SS_PRIMARY_PURSUE_IND_R	                 --On-priority --26-dEC-2023 CHANGES
        ,(case  when upper(F.V_SS_PURSUE_FLAG_R) in ('INSURED PURSUING', 'YES') then 'Y' else case  when upper(F.V_SS_PURSUE_FLAG_R) = 'NO' then 'N' else NULL end  end  ) V_SS_PRIMARY_PURSUE_IND_R --On-priority --26-dEC-2023 CHANGES
        --,f.V_SS_REJECT_REASON_R                                                          V_SS_REJECT_REASON_CODE_R	                 --On-priority --26-dEC-2023 CHANGES
        ,substr(V_SS_REJECT_REASON_R , 1 , instr(V_SS_REJECT_REASON_R , '-') - 1)        V_SS_REJECT_REASON_CODE_R                   --On-priority --26-dEC-2023 CHANGES
        ,f.V_SS_REJECT_REASON_R                                                          V_SS_REJECT_REASON_R
        --26-Jan-2024 changes starts
        --,CAST(NULL AS VARCHAR2(100))                                                     V_CLAIM_STATUS_CATEGORY_R
        ,(Case when
                 (CASE WHEN a.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP')
                  THEN g.V_REASON_CODE_R
                  else D.V_CLAIM_STATUS_REASON_CODE_R
                  end
                  )   >= '60'
                  THEN  'CLOSED'
            when (CASE WHEN a.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP')
                  THEN g.V_REASON_CODE_R
                  else D.V_CLAIM_STATUS_REASON_CODE_R
                  end
                  )   >= '50'
                  AND (CASE WHEN a.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP')
                      THEN g.V_REASON_CODE_R
                      else D.V_CLAIM_STATUS_REASON_CODE_R
                      end
                      )   <  '60'
                  THEN  'RESISTING'
            when (CASE WHEN a.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP')
                  THEN g.V_REASON_CODE_R
                  else D.V_CLAIM_STATUS_REASON_CODE_R
                  end
                  )   >= '40'
                  AND (CASE WHEN a.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP')
                      THEN g.V_REASON_CODE_R
                      else D.V_CLAIM_STATUS_REASON_CODE_R
                      end
                      )   <  '50'
                  THEN  'OPEN, NO LIABILITIES'
            when (CASE WHEN a.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP')
                  THEN g.V_REASON_CODE_R
                  else D.V_CLAIM_STATUS_REASON_CODE_R
                  end
                  )   >= '30'
                  AND (CASE WHEN a.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP')
                       THEN g.V_REASON_CODE_R
                       else D.V_CLAIM_STATUS_REASON_CODE_R
                       end
                  )   <  '40'
                 THEN 'ACTIVE'
            when (CASE WHEN a.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP')
                  THEN g.V_REASON_CODE_R
                  else D.V_CLAIM_STATUS_REASON_CODE_R
                  end
                  )   < '30'
                 THEN  'OPEN INCOMPLETE'
         ELSE
            NULL
         END)                                                                            V_CLAIM_STATUS_CATEGORY_R
        --26-Jan-2024 changes ends
        ,(CASE WHEN a.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP')
        THEN g.V_REASON_CODE_R
        else D.V_CLAIM_STATUS_REASON_CODE_R
        end
        )                                                                                  V_CLAIM_STATUS_CODE_R	                     --On-priority
        ,
		-- 04/09/24 Changes start
        /*(
        case when a.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP')
        then
        CASE WHEN g.V_REASON_CODE_R  >= '60'
          THEN  'CLOSED'
          WHEN g.V_REASON_CODE_R >= '50'
            AND g.V_REASON_CODE_R <  '60'
          THEN  'RESISTING'
          WHEN g.V_REASON_CODE_R >= '40'
            AND g.V_REASON_CODE_R <  '50'
          THEN  'OPEN, NO LIABILITIES'
          WHEN g.V_REASON_CODE_R >= '30'
            AND g.V_REASON_CODE_R <  '40'
          THEN 'ACTIVE'
          WHEN g.V_REASON_CODE_R < '30'
          THEN  'OPEN INCOMPLETE'
          end
        else
        CASE WHEN d.V_CLAIM_STATUS_REASON_CODE_R >= '60'
          THEN  'CLOSED'
          WHEN d.V_CLAIM_STATUS_REASON_CODE_R >= '50'
            AND d.V_CLAIM_STATUS_REASON_CODE_R <  '60'
          THEN  'RESISTING'
          WHEN d.V_CLAIM_STATUS_REASON_CODE_R >= '40'
            AND d.V_CLAIM_STATUS_REASON_CODE_R <  '50'
          THEN  'OPEN, NO LIABILITIES'
          WHEN d.V_CLAIM_STATUS_REASON_CODE_R >= '30'
            AND d.V_CLAIM_STATUS_REASON_CODE_R <  '40'
          THEN 'ACTIVE'
          WHEN d.V_CLAIM_STATUS_REASON_CODE_R < '30'
          THEN  'OPEN INCOMPLETE'
          ELSE
           NULL
         END
         end)                                                             V_CLAIM_STATUS_DESC_R	                     --On-priority
         */
        case when a.v_lob_type_r in ('LIFE', 'NONS', 'WOP')
        then nvl(claim_status_life.V_CLAIM_STATUS_DESC_R, sales_status_life.V_ORIG_CLAIM_STATUS_DESC_R)
        else COALESCE(claim_status_disability.V_CLAIM_STATUS_DESC_R,sales_status_disability.V_ORIG_CLAIM_STATUS_DESC_R,D.V_CLAIM_STATUS_REASON_DESC_R)  end V_CLAIM_STATUS_DESC_R
-- 04/09/24 Changes End
        ,CAST(p.D_CLAIM_STATUS_CODE_EFF_DATE_R AS DATE)                                                D_CLAIM_STATUS_EFF_DATE_R	                 --On-priority
        ,CAST(p.D_LAST_IN_STATUS_46_DATE_R      AS DATE)                                              D_LAST_IN_STATUS_46_DATE_R	                 --On-priority
        ,p.V_PRIOR_CLAIM_CLOSURE_CODE_R                                                  V_PRIOR_CLAIM_STATUS_CLOSURE_CODE_R
        ,P.V_PRIOR_CLAIM_STATUS_CODE_R                                                   V_PRIOR_CLAIM_STATUS_CODE_R	             --On-priority
        ,/*case when a.v_lob_type_r in ('LIFE', 'NONS', 'WOP')
         then sales_status_life.V_NEW_CLAIM_STATUS_DESC_R
         else sales_status_disability.V_NEW_CLAIM_STATUS_DESC_R  end                             V_SALES_CLAIM_STATUS_DESC_R	             --On-priority*/
        case when a.v_lob_type_r in ('LIFE', 'NONS', 'WOP')
        then nvl(sales_status_life.V_NEW_CLAIM_STATUS_DESC_R, sales_status_life.V_ORIG_CLAIM_STATUS_DESC_R)
        --else nvl(sales_status_disability.V_NEW_CLAIM_STATUS_DESC_R,sales_status_disability.V_ORIG_CLAIM_STATUS_DESC_R)  end                             V_SALES_CLAIM_STATUS_DESC_R	             --On-priority --03-May-2024 changes
        else COALESCE(sales_status_disability.V_NEW_CLAIM_STATUS_DESC_R,sales_status_disability.V_ORIG_CLAIM_STATUS_DESC_R,D.V_CLAIM_STATUS_REASON_DESC_R)  end                             V_SALES_CLAIM_STATUS_DESC_R	             --On-priority --03-May-2024 changes
        ,p.V_CURR_CLAIM_STATUS_CODE_R                                                    V_CURR_CLAIM_STATUS_CODE_R	                 --On-priority
        ,CAST(NULL AS VARCHAR2(100))                                                    V_CLAIM_TYPE_R	                             --On-priority - tbd
        ,CLAIM_TIER_WFAM_MV_TBL.D_CREATED_DATE_R_TIER                                  D_TIER_CREATED_DATE_R	                     --On-priority
        ,CLAIM_TIER_WFAM_MV_TBL.D_CREATED_DATE_R_WFAM                                    D_WFAM_CODE_CREATED_DATE_R	                 --On-priority
        ,CLAIM_TIER_WFAM_MV_TBL.V_TIER_R                                                 V_TIER_R	                                 --On-priority
        ,CLAIM_TIER_WFAM_MV_TBL.V_WFAM_R                                                 V_WFAM_R	                                 --On-priority
        ,CLAIM_TIER_WFAM_MV_TBL.D_PRD_R                                                      D_PRD_R
        --26-Jan-2024 changes starts
        --,CLAIM_TIER_WFAM_MV_TBL.D_PRD_R                                                      D_PRD_DAYS_REMAINING_R
        ,(CLAIM_TIER_WFAM_MV_TBL.D_PRD_R -gd_pacs_as_of_date_r)                                D_PRD_DAYS_REMAINING_R
        --26-Jan-2024 changes ends
        ,case when a.v_lob_type_r in ('LIFE', 'NONS', 'WOP')
        then DIM_GRP_REF_TIER_R_life.V_ACCOMMODATIONS_NEEDED_R
        else        DIM_GRP_REF_TIER_R_disability.V_ACCOMMODATIONS_NEEDED_R    end                      V_ACCOMMODATIONS_NEEDED_R
        ,case when a.v_lob_type_r in ('LIFE', 'NONS', 'WOP')
        then DIM_GRP_REF_TIER_R_life.V_CLINICAL_VOC_ENGAGEMENT_R
        else        DIM_GRP_REF_TIER_R_disability.V_CLINICAL_VOC_ENGAGEMENT_R  end                        V_CLINICAL_VOC_ENGAGEMENT_R
        ,
        case when a.v_lob_type_r in ('LIFE', 'NONS', 'WOP')
        then DIM_GRP_REF_TIER_R_life.V_TIER_DESCRIPTION_R
        else        DIM_GRP_REF_TIER_R_disability.V_TIER_DESCRIPTION_R  end
        																				V_TIER_DESCRIPTION_R	                     --On-priority
        ,case when a.v_lob_type_r in ('LIFE', 'NONS', 'WOP')
        then DIM_GRP_REF_TIER_R_life.N_TIER_NUM_R
        else        DIM_GRP_REF_TIER_R_disability.N_TIER_NUM_R  end     				N_TIER_NUM_R
        --26-Jan-2024 changes starts
        --,CAST(NULL AS VARCHAR2(100))                                                     V_RECOVERY_EXPECTATIONS_R
        ,(case when a.v_lob_type_r in ('LIFE', 'NONS', 'WOP')
          then DIM_GRP_REF_TIER_R_life.V_RECOVERY_EXPECTATIONS_r
          else        DIM_GRP_REF_TIER_R_disability. V_RECOVERY_EXPECTATIONS_r
          end)                                                                             V_RECOVERY_EXPECTATIONS_R
        --26-Jan-2024 changes ends
        ,DIM_GRP_VOCREHAB_R.V_VOC_REHAB_STATUS_R                                         V_VOC_REHAB_STATUS_R	        --26-Jan-2024 changes
        ,DIM_GRP_VOCREHAB_R.V_VOC_CASE_LASTNAME_R                                        V_VOC_REHAB_MGR_NAME_R	        --26-Jan-2024 changes
        ,DIM_GRP_VOCREHAB_R.V_SPECIALIST_R                                               V_VOC_REHAB_SPECIALIST_R	    --26-Jan-2024 changes
        ,CAST(NULL AS VARCHAR2(100))                                                     V_SERVICE_REQUESTED_OTHER_R
        ,CAST(NULL AS VARCHAR2(100))                                                     V_SERVICE_REQUESTED_R
        ,DIM_GRP_VOCREHAB_R.V_VOC_REHAB_OUTCOME_R                                        V_VOC_REHAB_OUTCOME_R	        --26-Jan-2024 changes
        ,DIM_GRP_VOCREHAB_R.V_REHAB_STATUS_R                                             V_VOC_REHAB_ACTIVE_STATUS_R	--26-Jan-2024 changes
        ,DIM_GRP_VOCREHAB_R.D_TSA_DATE_R                                                 D_TSA_DATE_R	                --26-Jan-2024 changes
        ,C.V_POLICY_NUMBER_R || '-' || q.V_SUBGROUP_ID_R                                 V_LOCATION_NUMBER_R	                      --On-priority
        ,q.V_CORRESPONDENT_NAME_R                                                        V_CORRESPONDENT_NAME_R
        ,q.V_SUBGROUP_ADDRESSLINE1_R                                                     V_SUBGROUP_ADDRESSLINE1_R
        ,q.V_SUBGROUP_ADDRESSLINE2_R                                                     V_SUBGROUP_ADDRESSLINE2_R
        ,q.V_SUBGROUP_CITY_R                                                             V_SUBGROUP_CITY_R
        ,q.V_SUBGROUP_ID_R                                                               V_SUBGROUP_ID_R	                          --On-priority
        ,q.V_SUBGROUP_NAME_R                                                             V_SUBGROUP_NAME_R	                          --On-priority
        ,q.V_SUBGROUP_POSTALZIP_R                                                        V_SUBGROUP_POSTALZIP_R
        ,q.V_SUBGROUP_PROVSTATE_R                                                        V_SUBGROUP_PROVSTATE_R	                       --On-priority
        ,gc_main_loadedby                                            v_last_modified_by_r
        ,gd_sysdate                                                  t_creation_date_r
        ,gc_main_loadedby                                            v_created_by_r
        ,gd_sysdate                                                  t_last_modified_date_r
        ,gn_current_month                                            n_yearmonth_r
        ,'Y'                                                         v_rpt_active_status_r
        ,gn_sysdt_batchid                                            n_batch_id_r
        ,d.V_EXAMINER_LOGIN_ID_R                                     V_EXAMINER_ID_R
        ,d.V_EXAMINER_DESC_R                                         V_EXAMINER_NAME_R
        ,s.D_HIRE_DATE_R                                             D_HIRE_DATE_R
        --26-DEC-2023 CHANGES STARTS
        ,F.d_ss_council_start_date_r
        ,F.d_ss_appeal_end_date_r
        ,F.d_ss_court_start_date_r
        ,F.d_ss_court_appeal_end_date_r
        ,F.d_ss_hearing_start_date_r
        ,F.d_ss_hearing_end_date_r
        ,F.d_ss_init_filing_start_date_r
        ,F.d_ss_init_filing_end_date_r
        ,F.d_ss_reconsider_start_date_r
        ,F.d_ss_reconsider_end_date_r
        ,(case  when F.N_SS_HARDSHIP_IND_R = '0' then 'N' else 'Y' end ) V_SS_HARDSHIP_IND_R
        --26-DEC-2023 CHANGES ENDS
         --,cast(nvl(n.D_START_DATE_R,m.D_START_DATE_R) as date)     D_WORKSHEET_START_DATE_R
        --,cast(nvl(n.D_END_DATE_R,m.D_END_DATE_R)     as date) D_WORKSHEET_END_DATE_R
        ,nvl(TO_DATE(SUBSTR(n.D_START_DATE_R,1,9)),TO_DATE(SUBSTR(m.D_START_DATE_R,1,9)))      D_WORKSHEET_START_DATE_R
        ,nvl(TO_DATE(SUBSTR(n.D_END_DATE_R,1,9))  ,TO_DATE(SUBSTR(m.D_END_DATE_R,1,9))  )      D_WORKSHEET_END_DATE_R
        ,a.v_lob_type_r --19-JAN-2024 CHANGES
        --23-jAN-2024 changes starts
        ,A.V_SOURCE_SYSTEM_NAME_R
        ,CAST(NULL AS NUMBER)                                 N_CURR_BENEFIT_PERIOD_DAYS_R
        ,CAST(NULL AS NUMBER)                                 N_TOTAL_BENEFIT_PERIOD_DAYS_R
        --23-jAN-2024 changes ends
        --26-jAN-2024 changes starts
        ,s.n_basic_insured_salary_r                           N_BASIC_INSURED_SALARY_R
        ,s.v_basic_insured_salary_ind_r                       V_BASIC_INSURED_SALARY_IND_R
        --26-jAN-2024 changes ends
        --31-jAN-2024 changes starts
        ,CAST(NULL AS NUMBER)                                 n_rehab_offset_amt_088_r
        ,CAST(NULL AS NUMBER)                                 v_rehab_offset_ind_088_r
        ,CAST(NULL AS NUMBER)                                 n_workers_comp_offset_amt_083_r
        ,CAST(NULL AS NUMBER)                                 n_other_offset_amt_r
        ,d.v_leave_type_r                                     v_pfl_leave_type_r
        ,d.v_license_num_r                                    v_pfl_license_number_r
        --31-jAN-2024 changes ends
        --20-Feb-2024 changes ends
        ,CAST(NULL AS date) d_closed_month_start_date_r
        ,CAST(NULL AS date) d_closed_month_end_date_r
        --20-Feb-2024 changes ends
        --15-Jun-2024 changes starts
        ,claim_prior_approved_mv.V_APPEAL_IND_R
        ,claim_prior_approved_mv.V_APPEAL_RESULT_STATUS_CODE_R
        ,claim_prior_approved_mv.D_APPEAL_RESULT_STATUS_CODE_EFF_DATE_R,
        --15-Jun-2024 changes ends

         --21/Jun/2024 - Changes start
          T4418483.V_DESCRIPTION_R  AS V_APPEAL_ANALYST_NAME_r         ,
          appeal.V_STATUS_CODE_R    AS V_APPEAL_STATUS_CODE_R          ,
          NVL(m.V_RPT_WORKSHEET_INDICATOR_R,n.V_RPT_WORKSHEET_INDICATOR_R) AS V_RPT_WORKSHEET_INDICATOR_R     ,
          NVL(m.N_VERSION_R,n.N_VERSION_R)          as   N_WORKSHEET_NUMBER_R            ,
          NVL(m.V_WORKSHEET_STATUS_R,n.V_WORKSHEET_STATUS_R)          as  V_WORKSHEET_STATUS_R            ,
          NVL(m.N_WORKSHEET_SEQ_NBR_OBJECTNM_R,n.N_WORKSHEET_SEQ_NBR_OBJECTNM_R)       as     N_WORKSHEET_SEQ_NBR_OBJECTNM_R,
          CASE WHEN a.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP')
          THEN l.v_coverage_type_code_r
          ELSE j.v_coverage_type_code_r
          END v_coverage_type_code_r,
          m.N_MAX_BENEFIT_R AS N_MAX_BENEFIT_R  ,
          m.N_MINIMUM_BENEFIT_R  as N_MINIMUM_BENEFIT_R  ,
        --21/Jun/2024 - Changes end
        --26/08/24 Changes Start
        case when A.V_SOURCE_SYSTEM_NAME_R = 'PACS' and diag.PRIMARY_DIAG_CODE in ('V70', 'V70,.0', 'V70,0','V70.0','V70.7') then 'Wellness'
        when  A.V_SOURCE_SYSTEM_NAME_R = 'PACS' and g.V_CLAIM_COVERAGE_CODE_R = 'VHI' then 'Hospital Indemnity'
        when  A.V_SOURCE_SYSTEM_NAME_R = 'PACS' and  g.V_CLAIM_COVERAGE_CODE_R = 'VAI' then 'Accident'
        when  A.V_SOURCE_SYSTEM_NAME_R = 'PACS' and g.V_CLAIM_COVERAGE_CODE_R = 'VCI' then 'Critical Illness'
        when g.V_CLAIM_COVERAGE_CODE_R in ('VAI', 'VCI', 'VHI') and  A.V_SOURCE_SYSTEM_NAME_R = 'CV' then  d.v_benefittype_r else null end as V_CLAIM_WELLNESS_IND_R   --27/11/24--changed to the d.v_benefittype_r from s.V_CEASED_WORK_REASON_R
        --26/08/24 Changes End
        ,CAST(NULL AS VARCHAR2(1))  V_HAS_ASSOCIATED_WAIVER_IND_R--11/09/24 CHANGES
        ,CAST(NULL AS VARCHAR2(1))  V_HAS_ASSOCIATED_LTD_IND_R   --11/09/24 CHANGES
        --11/09/24 changes start
        ,d.V_CLAIM_STATUS_REASON_DESC_R  AS V_CLAIM_STATUS_REASON_DESC_R
        --11/09/24 changes end
		--23/09/24 Changes Start
		,CAST(NULL AS DATE)          D_CLAIM_DECISION_DATE_R --will be populated in update proc
		,CAST(NULL AS NUMBER)        N_CLAIM_DECISION_DAYS_R --will be populated in update proc
		,CAST(NULL AS VARCHAR2(300)) V_TURNAROUND_RANGE1_R   --will be populated in update proc
		-- 23/09/24 Changes End
         from (select * from dim_grp_claim_dir_r where dim_grp_claim_dir_r.V_ACTIVE_STATUS_R = 'Y') a
        left join dim_grp_claim_coverage_r b
        on a.n_claim_sk_r = b.n_claim_sk_r
        and b.v_active_status_r = 'Y'
        left join dim_grp_claim_coverage_group_r g
        on b.n_claim_coverage_sk_r = g.n_claim_coverage_sk_r
        and g.v_active_status_r = 'Y'
		--15-Jun-2024 changes starts
		left join dim_grp_claim_prior_status_r_approved_mv_ssl claim_prior_approved_mv
		on a.n_claim_sk_r=claim_prior_approved_mv.n_claim_sk_r
		and b.n_claim_coverage_sk_r=claim_prior_approved_mv.n_claim_coverage_sk_r
		and g.n_claim_coverage_group_sk_r=claim_prior_approved_mv.n_claim_coverage_group_sk_r
		--15-Jun-2024 changes ends
        left join DIM_CLAIM_STATUS_DESC_R sales_status_life
        on g.v_reason_code_r = sales_status_life.V_CLAIM_STATUS_CODE_R
        and sales_status_life.v_active_status_r = 'Y'
                left join DIM_CLAIM_STATUS_R claim_status_life
        on g.v_reason_code_r = claim_status_life.V_CLAIM_STATUS_CODE_R
        and claim_status_life.v_active_status_r = 'Y'
        left join dim_grp_policy_dir_r c
        on a.n_policy_sk_r = c.n_policy_sk_r
        and c.v_active_status_r = 'Y'
        left join dim_grp_claim_detail_r d
        on a.n_claim_sk_r = d.n_claim_sk_r
        and d.v_active_status_r = 'Y'
        left join DIM_CLAIM_STATUS_DESC_R sales_status_disability
        on d.v_claim_status_reason_code_r = sales_status_disability.V_CLAIM_STATUS_CODE_R
        and sales_status_disability.v_active_status_r = 'Y'
                left join DIM_CLAIM_STATUS_R claim_status_disability
        on d.v_claim_status_reason_code_r = claim_status_disability.V_CLAIM_STATUS_CODE_R
        and claim_status_disability.v_active_status_r = 'Y'
        left join dim_employee_r e
        on d.V_EXAMINER_LOGIN_ID_R = e.V_EMPLOYEE_LOGIN_ID_R
        and e.V_BUSINESS_UNIT_R = 'Claims'
        --30-May-2024 changes starts
	    Left Join
		(SELECT *
		   FROM
		    dim_grp_appeals_r a
          WHERE a.v_active_status_r = 'Y'
          AND a.n_source_version_seq_number_r
           = (SELECT MAX(N_SOURCE_VERSION_SEQ_NUMBER_R) N_SOURCE_VERSION_SEQ_NUMBER_R
                FROM dim_grp_appeals_r b
          	 WHERE b.n_source_system_key_r = a.n_source_system_key_r
          	  and b.v_active_status_r = 'Y')
          and a.n_claim_sk_r <>-1
          ) appeal
		on d.n_claim_sk_r=appeal.n_claim_sk_r
        --30-May-2024 changes ends
        left join (--SELECT   max(n_cust_party_sk_r)n_cust_party_sk_r, n_policy_sk_r, n_version_number_r
                   --from  fct_grp_policy_r group by n_policy_sk_r,n_version_number_r
        		   --SELECT n_cust_party_sk_r, n_policy_sk_r, n_version_number_r from
        		   FCT_GRP_POLICY_R_MV_SSL
        		   ) f1
        on c.n_policy_sk_r = f1.n_policy_sk_r
        and c.n_policy_version_number_r = f1.n_version_number_r
        left join FCT_CLAIM_SOCIALSECURITY_INC_R f
        on a.n_claim_sk_r = f.n_claim_sk_r
        left join (--SELECT   min(n_product_sk_r)n_product_sk_r, n_claim_sk_r,v_claim_coverage_code_r
                   --from mvw_product_sk_lookup group by n_claim_sk_r,v_claim_coverage_code_r
        		  --SELECT n_product_sk_r, n_claim_sk_r,v_claim_coverage_code_r from
        		  MVW_PRODUCT_SK_LOOKUP_MIN_MV_SSL
        		  ) h
        on h.n_claim_sk_r = a.n_claim_sk_r
        and h.v_claim_coverage_code_r = nvl(b.v_claim_coverage_code_r,g.v_claim_coverage_code_r) -------nvl added on 29/05/24 @Chandra
        left join dim_grp_product_r j
        on h.n_product_sk_r = j.n_product_sk_r
        left join (--SELECT  min(n_product_sk_r)n_product_sk_r, n_claim_sk_r,v_claim_coverage_code_r
                   -- from mvw_product_sk_lookup group by n_claim_sk_r,v_claim_coverage_code_r
        		   --SELECT n_product_sk_r, n_claim_sk_r,v_claim_coverage_code_r from
        		   MVW_PRODUCT_SK_LOOKUP_MIN_MV_SSL
        		  ) i
        on i.n_claim_sk_r = a.n_claim_sk_r
        and i.v_claim_coverage_code_r = g.v_claim_coverage_code_r
        left join dim_grp_product_r l
        on l.n_product_sk_r = i.n_product_sk_r
        left join FCT_GRP_WORKSHEET m
        on m.n_claim_sk_r = a.n_claim_sk_r
        --and m.n_claim_coverage_sk_r = m.n_claim_coverage_sk_r--18-Jan-2024 changes
        and m.n_claim_coverage_sk_r = b.n_claim_coverage_sk_r--18-Jan-2024 changes
        and m.V_RPT_WORKSHEET_INDICATOR_R  = 'Y'
        left join FCT_GRP_WORKSHEET n
        on n.n_claim_sk_r = a.n_claim_sk_r
        --and n.n_claim_coverage_group_sk_r = n.n_claim_coverage_group_sk_r --18-Jan-2024 changes
        and n.n_claim_coverage_group_sk_r = g.n_claim_coverage_group_sk_r --18-Jan-2024 changes
        and n.V_RPT_WORKSHEET_INDICATOR_R  = 'Y'
        left join CLAIM_ACTIVITY_DATE_MV_TBL o
        on o.n_claim_sk_r = a.n_claim_sk_r
        and o.V_CLAIM_NUMBER_R = a.V_CLAIM_NUMBER_R
        left join VW_DIM_GRP_CLAIM_PRIOR_STATUS_R_MV_SSL p
        on p.n_claim_sk_r = a.n_claim_sk_r
        and p.n_claim_coverage_sk_r = b.n_claim_coverage_sk_r
        and p.n_claim_coverage_group_sk_r = g.n_claim_coverage_group_sk_r
        left join DIM_GRP_CLAIM_DETAIL_SUBGROUP_LOOKUP q
        on a.v_claim_number_r = q.v_claim_number_r
        and q.N_SOURCE_SYSTEM_KEY_R is not null--17-May-2024 changes
		--19-AUg-2024 changes starts
        --left outer join DIM_GRP_CLAIM_ELIGIBILITY_R r
        left outer join (SELECT * FROM DIM_GRP_CLAIM_ELIGIBILITY_R a1
        WHERE a1.v_active_status_r = 'Y'
        and a1.v_source_system_name_r = 'PACS'
        and a1.T_EVENT_TIMESTAMP_R = (select max(b1.T_EVENT_TIMESTAMP_R) from DIM_GRP_CLAIM_ELIGIBILITY_R b1
        where a1.n_claim_sk_r = b1.n_claim_sk_r
        and b1.v_source_system_name_r = 'PACS'
        and b1.v_active_status_r = 'Y')
        ) r
		--19-AUg-2024 changes ends
        On r.N_CLAIM_COVERAGE_SK_R = case  when r.N_CLAIM_COVERAGE_SK_R <> -1 then b.N_CLAIM_COVERAGE_SK_R else -1 end
        and r.N_CLAIM_SK_R = a.N_CLAIM_SK_R
        and r.v_active_status_r = 'Y'
        and r.v_source_system_name_r = 'PACS'

          left join dim_grp_claim_event_dir_r t
        on t.n_claim_event_sk_r = d.n_claim_event_sk_r
        and t.v_active_status_r = 'Y'
          left join dim_grp_claim_event_r s
        on s.n_claim_event_sk_r = t.n_claim_event_sk_r
        and s.v_active_status_r = 'Y'
          left outer join DIM_GRP_EEOC_R x /* D_GRP_EEOC_R */ --20-Mar-24 alias name changed from t to x
          On s.V_EEOC_CODE_R = x.V_CODE_R --20-Mar-24 alias name changed from t to x
          and x.v_active_status_r = 'Y' --20-Mar-24 alias name changed from t to x
        left outer join CLAIM_TIER_WFAM_MV_TBL CLAIM_TIER_WFAM_MV_TBL
          on a.n_claim_sk_r = CLAIM_TIER_WFAM_MV_TBL.n_claim_sk_r
          left join DIM_GRP_REF_TIER_R DIM_GRP_REF_TIER_R_disability
          on CLAIM_TIER_WFAM_MV_TBL.v_tier_r = DIM_GRP_REF_TIER_R_disability.V_TIER_TXT_R
          and DIM_GRP_REF_TIER_R_disability.V_COVERAGE_TYPE_CODE_R = j.V_COVERAGE_TYPE_CODE_R
          left join DIM_GRP_REF_TIER_R DIM_GRP_REF_TIER_R_life
          on CLAIM_TIER_WFAM_MV_TBL.v_tier_r = DIM_GRP_REF_TIER_R_life.V_TIER_TXT_R
          and DIM_GRP_REF_TIER_R_life.V_COVERAGE_TYPE_CODE_R = j.V_COVERAGE_TYPE_CODE_R

          left outer join
         (SELECT * FROM DIM_GRP_NURSE_CERT_R_mv_ssl
           /*SELECT   *
                   FROM dim_grp_nurse_cert_r c
                   WHERE v_active_status_r = 'Y'
                   AND N_NURSE_CERT_SEQ_R  =
                     (SELECT   MAX(N_NURSE_CERT_SEQ_R)
                      FROM dim_grp_nurse_cert_r
                      WHERE n_claim_sk_r    = c.n_claim_sk_r
                      AND v_active_status_r = 'Y'
                     )*/
                   ) u
                   on u.n_claim_sk_r = a.n_claim_sk_r

        left join (
        SELECT DIAG_IND.* FROM dim_grp_medical_diagnosis_r_MV_SSL DIAG_IND
        /*SELECT   n_claim_sk_r,
        LISTAGG(case when n_primary_ind_r = 0 then v_diagnosis_desc_r else '' end, '; ') WITHIN GROUP (ORDER BY n_claim_sk_r) as  additional_desc,
        LISTAGG(case when n_primary_ind_r = 1 then v_diagnosis_desc_r else '' end, '; ') WITHIN GROUP (ORDER BY n_claim_sk_r) as  Primary_desc,
        LISTAGG(case when n_primary_ind_r = 0 then V_DIAGNOSIS_CODE_R else '' end, '; ') WITHIN GROUP (ORDER BY n_claim_sk_r) as  additional_diag_code,
        LISTAGG(case when n_primary_ind_r = 1 then V_DIAGNOSIS_CODE_R else '' end, '; ') WITHIN GROUP (ORDER BY n_claim_sk_r) as  primary_diag_code,
        LISTAGG(case when n_primary_ind_r = 1 then DIM_DIAGNOSIS_CODE_R.V_DIAG_CATEGORY_CODE_R else '' end, '; ') WITHIN GROUP (ORDER BY n_claim_sk_r) as  V_PRI_DIAG_CATEGORY_CODE_R,
        LISTAGG(case when n_primary_ind_r = 0 then DIM_DIAGNOSIS_CODE_R.V_DIAG_CATEGORY_CODE_R else '' end, '; ') WITHIN GROUP (ORDER BY n_claim_sk_r) as  add_diag_category_code,
        LISTAGG(case when n_primary_ind_r = 1 then DIM_DIAGNOSIS_CATEGORY_R.V_DIAG_CATEGORY_DESC_R else '' end, '; ') WITHIN GROUP (ORDER BY n_claim_sk_r) as  V_PRI_DIAG_CATEGORY_DESC_R,
        LISTAGG(case when n_primary_ind_r = 0 then DIM_DIAGNOSIS_CATEGORY_R.V_DIAG_CATEGORY_DESC_R else '' end, '; ') WITHIN GROUP (ORDER BY n_claim_sk_r) as  add_diag_category_desc,
        max(case when n_primary_ind_r = 1  then N_DIAGNOSIS_TYPE_CODE_R else 0 end) as  diagnosis_type_code
        FROM
        dim_grp_medical_diagnosis_r dim_grp_medical_diagnosis_r
        left join DIM_DIAGNOSIS_CODE_R DIM_DIAGNOSIS_CODE_R
        on dim_grp_medical_diagnosis_r.V_DIAGNOSIS_CODE_R = DIM_DIAGNOSIS_CODE_R.V_DIAG_CODE_R
        and DIM_DIAGNOSIS_CODE_R.v_active_status_r = 'Y'
        left join DIM_DIAGNOSIS_CATEGORY_R DIM_DIAGNOSIS_CATEGORY_R
        on DIM_DIAGNOSIS_CODE_R.V_DIAG_CATEGORY_CODE_R = DIM_DIAGNOSIS_CATEGORY_R.V_DIAG_CATEGORY_CODE_R
        and DIM_DIAGNOSIS_CATEGORY_R.v_active_status_r = 'Y'
        WHERE
        dim_grp_medical_diagnosis_r.v_active_status_r = 'Y'
        and n_claim_sk_r<>-1
        GROUP BY
        n_claim_sk_r*/
        ) diag
        on diag.n_claim_sk_r = a.n_claim_sk_r
        left join
          (/*SELECT
                                        v_claim_number_r,
                                        MAX(nvl(t374156.d_received_date_r,
                                                TO_DATE(substr(t374156.v_claim_number_r, 1, 10),
                                                        'YYYY-MM-DD'))) AS received_date
                                    FROM
                                        dim_grp_busobj_audit_r t374156
                                    WHERE
                                            v_active_status_r = 'Y'
                                        AND v_claim_number_r NOT IN ( '-LIFE-01', '-LTD-01', '-STD-01', '-VPS-01', '-WOP-01' )
                                    GROUP BY
                                        v_claim_number_r*/
        	SELECT obj.v_claim_number_r,obj.received_date FROM DIM_GRP_BUSOBJ_AUDIT_R_MAX_RCV_MV_SSL	 obj
                                )      received_date
                                on received_date.v_claim_number_r = a.v_claim_number_r

        left join (
        SELECT LTD.CLAIM_SK ,LTD.ltd_policy_ind FROM fct_grp_policy_r_LTDPOLIND_MV_SSL LTD
        /*SELECT    a.N_CLAIM_SK_R as CLAIM_SK,
        (case when a.v_lob_type_r in ('LIFE', 'STD', 'VPS', 'WOP','NONS')
        and c.n_cust_party_sk_r in
        (SELECT   c.n_cust_party_sk_r from
        dim_grp_policy_dir_r b,
        fct_grp_policy_r c
        where
        b.n_policy_version_number_r = c.n_version_number_r
        and b.n_policy_sk_r = c.n_policy_sk_r
        and b.v_active_status_r = 'Y'
        and b.v_orig_lob_r in ('ASL', 'LTD-SMALL', 'LTD', 'VPL', 'LTDVLT'))
        then
        'Y'
        else null
        end) ltd_policy_ind
        from
        dim_grp_claim_dir_r a ,
        dim_grp_policy_dir_r b,
        fct_grp_policy_r c
        where a.v_active_status_r = 'Y'
        and a.n_policy_sk_r = b.n_policy_sk_r
        and b.v_active_status_r = 'Y'
        and b.n_policy_version_number_r = c.n_version_number_r
        and b.n_policy_sk_r = c.n_policy_sk_r
        and v_lob_type_r <> 'ANNUITY'*/) ltd_policy_indicator
        on ltd_policy_indicator.CLAIM_SK = a.N_CLAIM_SK_R
        left join  (
        SELECT  PMNT.v_claim_number_r
           ,  PMNT.N_CLAIM_COVERAGE_GROUP_SK_R,
            PMNT.V_COV_GROUP_ID_R,
            PMNT.Last_Payment_Date, PMNT.earliest_payment_date,
            PMNT.MOST_RECENT_SERVICE_PERIOD_TO_DATE,
            PMNT.MOST_RECENT_SERVICE_PERIOD_FROM_DATE
			,PMNT.EARLIEST_SERVICE_PERIOD_FROM_DATE --14-Mar-2024 changes
			,PMNT.EARLIEST_SERVICE_PERIOD_TO_DATE   --14-Mar-2024 changes
        	FROM FCT_CLAIM_PAYMENT_DETAIL_R_PMNT_MV_SSL PMNT
             where PMNT.N_CLAIM_COVERAGE_GROUP_SK_R <> -1                          ------------------                   /*TEMP FIX APPLIED NEED TO REVISIT*/
        /*SELECT   v_claim_number_r ,  N_CLAIM_COVERAGE_GROUP_SK_R,
            V_COV_GROUP_ID_R,
            MAX(d_paid_date_r) Last_Payment_Date, min(d_paid_date_r)earliest_payment_date,
        max(D_SERVICE_PERIOD_TO_R) MOST_RECENT_SERVICE_PERIOD_TO_DATE,
             max(D_SERVICE_PERIOD_FROM_R) MOST_RECENT_SERVICE_PERIOD_FROM_DATE
          FROM
            (SELECT   v_claim_number_r,
              d_paid_date_r,
              N_SOURCE_VERSION_SEQ_NUMBER_R,
              SUM(N_PAID_AMOUNT_R),
              N_CLAIM_COVERAGE_GROUP_SK_R,
              V_COV_GROUP_ID_R,
             D_SERVICE_PERIOD_FROM_R,
              D_SERVICE_PERIOD_TO_R
            FROM fct_claim_payment_detail_r
            WHERE V_CHECK_TYPE_R      <> 'OE'
            AND V_BENEFIT_GROUP_R NOT IN ('FIC', 'MED')
            GROUP BY v_claim_number_r,
              d_paid_date_r,
              N_SOURCE_VERSION_SEQ_NUMBER_R,
              N_CLAIM_COVERAGE_GROUP_SK_R,
              V_COV_GROUP_ID_R,
              D_SERVICE_PERIOD_FROM_R,
              D_SERVICE_PERIOD_TO_R
            HAVING SUM(N_PAID_AMOUNT_R) >0
            )
          GROUP BY v_claim_number_r,
            N_CLAIM_COVERAGE_GROUP_SK_R,
            V_COV_GROUP_ID_R
        	*/) payment_dates
            --19-Dec-2023 changes starts
        	--on PAYMENT_DATES.N_CLAIM_COVERAGE_GROUP_SK_R = G.N_CLAIM_COVERAGE_GROUP_SK_R
            ON PAYMENT_DATES.v_claim_number_r = A. v_claim_number_r
            And PAYMENT_DATES.N_CLAIM_COVERAGE_GROUP_SK_R  = (case when PAYMENT_DATES.N_CLAIM_COVERAGE_GROUP_SK_R = -1 then -1 else G.N_CLAIM_COVERAGE_GROUP_SK_R end)
            --19-Dec-2023 changes ends
        --where a.V_ACTIVE_STATUS_R = 'Y' --moved to top on 18-Jan-2024
         --21-06-24 changes start
       left outer join DIM_GRP_SYSUSESO_R T4418483 /* D_GRP_SYSUSESO_R_Claims */  On upper(T4418483.V_LOGIN_ID_R) = upper(appeal.V_USER_ID_R)
        --21-06-24 changes start
        --26-Jan-2024 changes starts
        Left join
        (select *   from DIM_GRP_VOCREHAB_R
                      where v_active_status_r = 'Y'
                      and v_source_system_name_r <> 'CV'
                      and n_claim_sk_r <>-1) DIM_GRP_VOCREHAB_R
        on DIM_GRP_VOCREHAB_R.n_claim_sk_r = a.N_CLAIM_SK_R
 		)
        --26-Jan-2024 changes ends
-- 04/09/24 Changes start
--04/09/24 Changes End
       where  rank= 1;
    gc_trcmsg:=gc_trcmsg||'4.2 Exit from prc_get_cur_data'||chr(13);
EXCEPTION
WHEN OTHERS THEN
    gc_errmsg :=SUBSTR(SQLERRM,1,4000);
    gc_trcmsg:=gc_trcmsg||'4.z Error in prc_get_cur_data'||chr(13);
    pkg_grp_log_util.prc_update_log
          (
            gn_out_job_id                   --p_job_id
            ,gc_error_status                --p_job_status
            ,gc_errmsg                      --p_err_msg
            ,gc_trcmsg||chr(13)||gc_errmsg  --p_trc_msg
            ,gc_getcur_loadedby             --p_log_util_called_by_r
          );
    RAISE;
END prc_get_cur_data;

--Procedure to insert dummy record in the table RPT_CLAIM_DTL_R
PROCEDURE prc_insert_dummy_rec
IS
BEGIN
    gc_trcmsg:=gc_trcmsg||'6.1 Entered into from prc_insert_dummy_rec'||chr(13);
     INSERT /*+APPEND*/ INTO RPT_CLAIM_DTL_R-- RPT_CLAIM_DTL_R
		   (
		    v_last_modified_by_r
           ,t_creation_date_r
           ,v_created_by_r
           ,t_last_modified_date_r
           ,n_yearmonth_r
           ,v_rpt_active_status_r
           ,n_batch_id_r
           ,N_CLAIM_COVERAGE_GROUP_SK_R
           ,n_claim_coverage_sk_r
           ,N_CLAIM_SK_R
		   )
    VALUES(gc_main_loadedby
		  ,systimestamp
		  ,gc_main_loadedby
		  ,systimestamp
		  ,gn_current_month
		  ,'Y'
		  ,gn_sysdt_batchid
          ,-1           --N_CLAIM_COVERAGE_GROUP_SK_R
          ,-1           --n_claim_coverage_sk_r
          ,-1           --N_CLAIM_SK_R
		  );
    COMMIT;
    gc_trcmsg:=gc_trcmsg||'6.2 Exit from prc_insert_dummy_rec'||chr(13);
EXCEPTION
WHEN OTHERS THEN
    gc_errmsg :=SUBSTR(SQLERRM,1,4000);
    gc_trcmsg:=gc_trcmsg||'6.z Error in prc_insert_dummy_rec'||chr(13);
    pkg_grp_log_util.prc_update_log
          (
            gn_out_job_id                   --p_job_id
            ,gc_error_status                --p_job_status
            ,gc_errmsg                      --p_err_msg
            ,gc_trcmsg||chr(13)||gc_errmsg  --p_trc_msg
            ,gc_dummyrec_loadedby             --p_log_util_called_by_r
          );
    RAISE;
END prc_insert_dummy_rec;
--11/09/24 commneted changes starts
/*
--Procedure to refresh SSL mvs
PROCEDURE prc_refresh_ssl_mvs
IS
BEGIN
    gc_trcmsg:=gc_trcmsg||'2.1 Entered into from prc_refresh_ssl_mvs'||chr(13);
    gc_trcmsg:=gc_trcmsg||'2.1.a Refresh FCT_GRP_POLICY_R_MV_SSL starts'||chr(13);
	dbms_mview.refresh('FCT_GRP_POLICY_R_MV_SSL', method => 'C', atomic_refresh => FALSE);
    gc_trcmsg:=gc_trcmsg||'2.1.a Refresh FCT_GRP_POLICY_R_MV_SSL ends'||chr(13);
    gc_trcmsg:=gc_trcmsg||'2.1.b Refresh MVW_PRODUCT_SK_LOOKUP_MIN_MV_SSL starts'||chr(13);
	dbms_mview.refresh('MVW_PRODUCT_SK_LOOKUP_MIN_MV_SSL', method => 'C', atomic_refresh => FALSE);
    gc_trcmsg:=gc_trcmsg||'2.1.b Refresh MVW_PRODUCT_SK_LOOKUP_MIN_MV_SSL ends'||chr(13);
    gc_trcmsg:=gc_trcmsg||'2.1.c Refresh DIM_GRP_NURSE_CERT_R_MV_SSL starts'||chr(13);
	dbms_mview.refresh('DIM_GRP_NURSE_CERT_R_MV_SSL', method => 'C', atomic_refresh => FALSE);
    gc_trcmsg:=gc_trcmsg||'2.1.c Refresh DIM_GRP_NURSE_CERT_R_MV_SSL ends'||chr(13);
    gc_trcmsg:=gc_trcmsg||'2.1.d Refresh DIM_GRP_NURSE_CERT_R_MAX_RCV_MV_SSL starts'||chr(13);
	dbms_mview.refresh('DIM_GRP_NURSE_CERT_R_MAX_RCV_MV_SSL', method => 'C', atomic_refresh => FALSE);
    gc_trcmsg:=gc_trcmsg||'2.1.d Refresh DIM_GRP_NURSE_CERT_R_MAX_RCV_MV_SSL ends'||chr(13);
    gc_trcmsg:=gc_trcmsg||'2.1.e Refresh FCT_CLAIM_PAYMENT_DETAIL_R_PMNT_MV_SSL starts'||chr(13);
	dbms_mview.refresh('FCT_CLAIM_PAYMENT_DETAIL_R_PMNT_MV_SSL', method => 'C', atomic_refresh => FALSE);
    gc_trcmsg:=gc_trcmsg||'2.1.e Refresh FCT_CLAIM_PAYMENT_DETAIL_R_PMNT_MV_SSL ends'||chr(13);
    gc_trcmsg:=gc_trcmsg||'2.1.f Refresh MVW_PRODUCT_SK_LOOKUP_MIN_MV_SSL starts'||chr(13);
	dbms_mview.refresh('MVW_PRODUCT_SK_LOOKUP_MIN_MV_SSL', method => 'C', atomic_refresh => FALSE);
    gc_trcmsg:=gc_trcmsg||'2.1.f Refresh MVW_PRODUCT_SK_LOOKUP_MIN_MV_SSL ends'||chr(13);
    gc_trcmsg:=gc_trcmsg||'2.1.g Refresh FCT_GRP_POLICY_R_LTDPOLIND_MV_SSL starts'||chr(13);
	dbms_mview.refresh('FCT_GRP_POLICY_R_LTDPOLIND_MV_SSL', method => 'C', atomic_refresh => FALSE);
    gc_trcmsg:=gc_trcmsg||'2.1.g Refresh FCT_GRP_POLICY_R_LTDPOLIND_MV_SSL ends'||chr(13);
    gc_trcmsg:=gc_trcmsg||'2.1.h Refresh DIM_GRP_MEDICAL_DIAGNOSIS_R_MV_SSL starts'||chr(13);
	dbms_mview.refresh('DIM_GRP_MEDICAL_DIAGNOSIS_R_MV_SSL', method => 'C', atomic_refresh => FALSE);
    gc_trcmsg:=gc_trcmsg||'2.1.h Refresh DIM_GRP_MEDICAL_DIAGNOSIS_R_MV_SSL ends'||chr(13);
    gc_trcmsg:=gc_trcmsg||'2.2 Exit from prc_refresh_ssl_mvs'||chr(13);

EXCEPTION
WHEN OTHERS THEN
    gc_errmsg :=SUBSTR(SQLERRM,1,4000);
    gc_trcmsg:=gc_trcmsg||'2.z Error in prc_refresh_ssl_mvs'||chr(13);
    pkg_grp_log_util.prc_update_log
          (
            gn_out_job_id                   --p_job_id
            ,gc_error_status                --p_job_status
            ,gc_errmsg                      --p_err_msg
            ,gc_trcmsg||chr(13)||gc_errmsg  --p_trc_msg
            ,gc_refreshmvs_loadedby             --p_log_util_called_by_r
          );
    RAISE;
END prc_refresh_ssl_mvs;
--11/09/24 commneted changes ends*/

--26-Jan-2026 changes starts
--Function to get Earliest Service From Period
/*FUNCTION get_d_earliest_service_period_from_r (p_n_claim_sk_r IN NUMBER,p_N_CLAIM_COVERAGE_GROUP_SK_R IN NUMBER
,P_V_LOB_TYPE_R IN VARCHAr2 )
RETURN DATE
IS
ld_date DATE;
ln_claim_cov_grp_sk_r NUMBER:=p_N_CLAIM_COVERAGE_GROUP_SK_R;
BEGIN
--use Earliest_SERVICE_PERIOD_FROM_DATE from below subquery

  IF p_v_lob_type_r IN ('LIFE', 'WOP','NONS') THEN
     NULL;
  ELSE
  --LTD VPL STD VPS
      ln_claim_cov_grp_sk_r:=-1;
  END IF;

 select
    --v_claim_number_r ,  N_CLAIM_COVERAGE_GROUP_SK_R,
    --V_COV_GROUP_ID_R,
    --MAX(d_paid_date_r) Last_Payment_Date, min(d_paid_date_r)earliest_payment_date,
     --max(D_SERVICE_PERIOD_TO_R) MOST_RECENT_SERVICE_PERIOD_TO_DATE,
     --max(D_SERVICE_PERIOD_FROM_R) MOST_RECENT_SERVICE_PERIOD_FROM_DATE,
     --min(D_SERVICE_PERIOD_TO_R) Earliest_SERVICE_PERIOD_TO_DATE,
     min(D_SERVICE_PERIOD_FROM_R) --Earliest_SERVICE_PERIOD_FROM_DATE
	 INTO ld_date
  FROM FCT_CLAIM_PAYMENT_DETAIL_R_SERVPER_DT_MV_SSL WHERE N_CLAIM_SK_R=P_N_CLAIM_SK_R
	AND N_CLAIM_COVERAGE_GROUP_SK_R=ln_claim_cov_grp_sk_r;
--    (
--	SELECT v_claim_number_r,
--      d_paid_date_r,
--      N_SOURCE_VERSION_SEQ_NUMBER_R,
--      SUM(N_PAID_AMOUNT_R),
--      N_CLAIM_COVERAGE_GROUP_SK_R,
--      V_COV_GROUP_ID_R,
--D_SERVICE_PERIOD_FROM_R,
--      D_SERVICE_PERIOD_TO_R
--    FROM fct_claim_payment_detail_r
--    WHERE V_CHECK_TYPE_R      <> 'OE'
--    AND V_BENEFIT_GROUP_R NOT IN ('FIC', 'MED')
--	AND N_CLAIM_SK_R=P_N_CLAIM_SK_R
--	AND N_CLAIM_COVERAGE_GROUP_SK_R=p_N_CLAIM_COVERAGE_GROUP_SK_R
--    GROUP BY v_claim_number_r,
--      d_paid_date_r,
--      N_SOURCE_VERSION_SEQ_NUMBER_R,
--      N_CLAIM_COVERAGE_GROUP_SK_R,
--      V_COV_GROUP_ID_R,
--      D_SERVICE_PERIOD_FROM_R,
--      D_SERVICE_PERIOD_TO_R
--    HAVING SUM(N_PAID_AMOUNT_R) >0
--    )
--  GROUP BY v_claim_number_r,
--    N_CLAIM_COVERAGE_GROUP_SK_R,
--    V_COV_GROUP_ID_R;
	RETURN ld_date;
EXCEPTION
WHEN OTHERS THEN
RETURN NULL;
END get_d_earliest_service_period_from_r
;
--Function to get Earliest Service to Period
FUNCTION get_d_earliest_service_period_to_r (p_n_claim_sk_r IN NUMBER,p_N_CLAIM_COVERAGE_GROUP_SK_R IN NUMBER,p_v_lob_type_r  IN VARCHAR2)
RETURN DATE
IS
ld_date DATE;
ln_claim_cov_grp_sk_r NUMBER:=p_N_CLAIM_COVERAGE_GROUP_SK_R;
BEGIN
--use Earliest_SERVICE_PERIOD_FROM_DATE from below subquery
  IF p_v_lob_type_r IN ('LIFE', 'WOP','NONS') THEN
     NULL;
  ELSE
  --LTD VPL STD VPS
      ln_claim_cov_grp_sk_r:=-1;
  END IF;

 select
    --v_claim_number_r ,  N_CLAIM_COVERAGE_GROUP_SK_R,
    --V_COV_GROUP_ID_R,
    --MAX(d_paid_date_r) Last_Payment_Date, min(d_paid_date_r)earliest_payment_date,
     --max(D_SERVICE_PERIOD_TO_R) MOST_RECENT_SERVICE_PERIOD_TO_DATE,
     --max(D_SERVICE_PERIOD_FROM_R) MOST_RECENT_SERVICE_PERIOD_FROM_DATE,
     min(D_SERVICE_PERIOD_TO_R) Earliest_SERVICE_PERIOD_TO_DATE--,
     --min(D_SERVICE_PERIOD_FROM_R) --Earliest_SERVICE_PERIOD_FROM_DATE
	 INTO ld_date
    FROM FCT_CLAIM_PAYMENT_DETAIL_R_SERVPER_DT_MV_SSL WHERE N_CLAIM_SK_R=P_N_CLAIM_SK_R
	AND N_CLAIM_COVERAGE_GROUP_SK_R=ln_claim_cov_grp_sk_r;
  --  (SELECT v_claim_number_r,
  --  d_paid_date_r,
  --  N_SOURCE_VERSION_SEQ_NUMBER_R,
  --  SUM(N_PAID_AMOUNT_R),
  --  N_CLAIM_COVERAGE_GROUP_SK_R,
  --  V_COV_GROUP_ID_R,
  -- D_SERVICE_PERIOD_FROM_R,
  --  D_SERVICE_PERIOD_TO_R
  --FROM fct_claim_payment_detail_r
  --WHERE V_CHECK_TYPE_R      <> 'OE'
  --AND V_BENEFIT_GROUP_R NOT IN ('FIC', 'MED')
	--AND N_CLAIM_SK_R=P_N_CLAIM_SK_R
	--AND N_CLAIM_COVERAGE_GROUP_SK_R=p_N_CLAIM_COVERAGE_GROUP_SK_R
  --GROUP BY v_claim_number_r,
  --  d_paid_date_r,
  --  N_SOURCE_VERSION_SEQ_NUMBER_R,
  --  N_CLAIM_COVERAGE_GROUP_SK_R,
  --  V_COV_GROUP_ID_R,
  --  D_SERVICE_PERIOD_FROM_R,
  --  D_SERVICE_PERIOD_TO_R
  --HAVING SUM(N_PAID_AMOUNT_R) >0
  --)
  --GROUP BY v_claim_number_r,
  --  N_CLAIM_COVERAGE_GROUP_SK_R,
  --  V_COV_GROUP_ID_R;
	RETURN ld_date;
EXCEPTION
WHEN OTHERS THEN
RETURN NULL;
END get_d_earliest_service_period_to_r
;--26-Jan-2026 changes ends
*/
--Function to get Most Recent Service From Period
/*--Commented on 14-Mar-2024
FUNCTION get_d_mostrecent_service_period_from_r (p_n_claim_sk_r IN NUMBER,p_N_CLAIM_COVERAGE_GROUP_SK_R IN NUMBER,p_v_lob_type_r  IN VARCHAR2
)
RETURN DATE
IS
ld_date DATE;
ln_claim_cov_grp_sk_r NUMBER:=p_N_CLAIM_COVERAGE_GROUP_SK_R;
BEGIN
--use Earliest_SERVICE_PERIOD_FROM_DATE from below subquery
  IF p_v_lob_type_r IN ('LIFE', 'WOP','NONS') THEN
     NULL;
  ELSE
  --LTD VPL STD VPS
      ln_claim_cov_grp_sk_r:=-1;
  END IF;

 select
    --v_claim_number_r ,  N_CLAIM_COVERAGE_GROUP_SK_R,
    --V_COV_GROUP_ID_R,
    --MAX(d_paid_date_r) Last_Payment_Date, min(d_paid_date_r)earliest_payment_date,
     --max(D_SERVICE_PERIOD_TO_R) MOST_RECENT_SERVICE_PERIOD_TO_DATE,
     max(D_SERVICE_PERIOD_FROM_R) MOST_RECENT_SERVICE_PERIOD_FROM_DATE
     --min(D_SERVICE_PERIOD_TO_R) Earliest_SERVICE_PERIOD_TO_DATE,
     --min(D_SERVICE_PERIOD_FROM_R) --Earliest_SERVICE_PERIOD_FROM_DATE
	 INTO ld_date
    FROM FCT_CLAIM_PAYMENT_DETAIL_R_SERVPER_DT_MV_SSL WHERE N_CLAIM_SK_R=P_N_CLAIM_SK_R
	AND N_CLAIM_COVERAGE_GROUP_SK_R=ln_claim_cov_grp_sk_r ;
   --FROM
   -- (SELECT v_claim_number_r,
   --   d_paid_date_r,
   --   N_SOURCE_VERSION_SEQ_NUMBER_R,
   --   SUM(N_PAID_AMOUNT_R),
   --   N_CLAIM_COVERAGE_GROUP_SK_R,
   --   V_COV_GROUP_ID_R,
   --   D_SERVICE_PERIOD_FROM_R,
   --   D_SERVICE_PERIOD_TO_R
   -- FROM fct_claim_payment_detail_r
   -- WHERE V_CHECK_TYPE_R      <> 'OE'
   -- AND V_BENEFIT_GROUP_R NOT IN ('FIC', 'MED')
	--AND N_CLAIM_SK_R=P_N_CLAIM_SK_R
	--AND N_CLAIM_COVERAGE_GROUP_SK_R=p_N_CLAIM_COVERAGE_GROUP_SK_R
   -- GROUP BY v_claim_number_r,
   --   d_paid_date_r,
   --   N_SOURCE_VERSION_SEQ_NUMBER_R,
   --   N_CLAIM_COVERAGE_GROUP_SK_R,
   --   V_COV_GROUP_ID_R,
   --   D_SERVICE_PERIOD_FROM_R,
   --   D_SERVICE_PERIOD_TO_R
   -- HAVING SUM(N_PAID_AMOUNT_R) >0
   -- )
  --GROUP BY v_claim_number_r,
  --  N_CLAIM_COVERAGE_GROUP_SK_R,
  --  V_COV_GROUP_ID_R;
	RETURN ld_date;
EXCEPTION
WHEN OTHERS THEN
RETURN NULL;
END get_d_mostrecent_service_period_from_r
;*/
--Function to get Most Recent Service To Period
/*--Commented on 14-Mar-2024
FUNCTION get_d_mostrecent_service_period_to_r (p_n_claim_sk_r IN NUMBER,p_N_CLAIM_COVERAGE_GROUP_SK_R IN NUMBER,p_v_lob_type_r  IN VARCHAR2
)
RETURN DATE
IS
ld_date DATE;
ln_claim_cov_grp_sk_r NUMBER:=p_N_CLAIM_COVERAGE_GROUP_SK_R;

BEGIN
--use Earliest_SERVICE_PERIOD_FROM_DATE from below subquery
IF p_v_lob_type_r IN ('LIFE', 'WOP','NONS') THEN
     NULL;
  ELSE
  --LTD VPL STD VPS
      ln_claim_cov_grp_sk_r:=-1;
  END IF;

 select
    --v_claim_number_r ,  N_CLAIM_COVERAGE_GROUP_SK_R,
    --V_COV_GROUP_ID_R,
    --MAX(d_paid_date_r) Last_Payment_Date, min(d_paid_date_r)earliest_payment_date,
     max(D_SERVICE_PERIOD_TO_R) MOST_RECENT_SERVICE_PERIOD_TO_DATE
     --max(D_SERVICE_PERIOD_FROM_R) MOST_RECENT_SERVICE_PERIOD_FROM_DATE,
     --min(D_SERVICE_PERIOD_TO_R) Earliest_SERVICE_PERIOD_TO_DATE--,
     --min(D_SERVICE_PERIOD_FROM_R) --Earliest_SERVICE_PERIOD_FROM_DATE
	 INTO ld_date
    FROM FCT_CLAIM_PAYMENT_DETAIL_R_SERVPER_DT_MV_SSL WHERE N_CLAIM_SK_R=P_N_CLAIM_SK_R
	AND N_CLAIM_COVERAGE_GROUP_SK_R=ln_claim_cov_grp_sk_r;
  --(SELECT v_claim_number_r,
  --    d_paid_date_r,
  --    N_SOURCE_VERSION_SEQ_NUMBER_R,
  --    SUM(N_PAID_AMOUNT_R),
  --    N_CLAIM_COVERAGE_GROUP_SK_R,
  --    V_COV_GROUP_ID_R,
  --    D_SERVICE_PERIOD_FROM_R,
  --    D_SERVICE_PERIOD_TO_R
  --  FROM fct_claim_payment_detail_r
  --  WHERE V_CHECK_TYPE_R      <> 'OE'
  --  AND V_BENEFIT_GROUP_R NOT IN ('FIC', 'MED')
	--AND N_CLAIM_SK_R=P_N_CLAIM_SK_R
	--AND N_CLAIM_COVERAGE_GROUP_SK_R=p_N_CLAIM_COVERAGE_GROUP_SK_R
  --  GROUP BY v_claim_number_r,
  --    d_paid_date_r,
  --    N_SOURCE_VERSION_SEQ_NUMBER_R,
  --    N_CLAIM_COVERAGE_GROUP_SK_R,
  --    V_COV_GROUP_ID_R,
  --    D_SERVICE_PERIOD_FROM_R,
  --    D_SERVICE_PERIOD_TO_R
  --  HAVING SUM(N_PAID_AMOUNT_R) >0
  --  )
  --GROUP BY v_claim_number_r,
  --  N_CLAIM_COVERAGE_GROUP_SK_R,
  --  V_COV_GROUP_ID_R;
	RETURN ld_date;
EXCEPTION
WHEN OTHERS THEN
RETURN NULL;
END get_d_mostrecent_service_period_to_r
;*/
--11/09/24 commneted changes starts
/*
--Function to get Nurse Cert End Date
FUNCTION get_d_nurse_cert_end_date_r (p_n_claim_sk_r IN NUMBER)
RETURN DATE
IS
ld_date DATE;
BEGIN

SELECT  d_nurse_cert_end_date_r
  into LD_DATE
from DIM_GRP_NURSE_CERT_R_MV_SSL D1
 where D1.N_CLAIM_SK_R=P_N_CLAIM_SK_R
 group by d_nurse_cert_end_date_r;

--SELECT d_nurse_cert_end_date_r
--  INTO ld_date
--  FROM DIM_GRP_NURSE_CERT_R D1
--  FROM DIM_GRP_NURSE_CERT_R D1
-- WHERE D1.n_claim_sk_r=p_n_claim_sk_r
--   AND D1.V_ACTIVE_STATUS_R='Y'
--   AND D1.N_NURSE_CERT_SEQ_R=(SELECT  MAX(D2.N_NURSE_CERT_SEQ_R)
--                                FROM DIM_GRP_NURSE_CERT_R D2
--							   WHERE D2.n_claim_sk_r=p_n_claim_sk_r
--							     AND D2.V_ACTIVE_STATUS_R='Y'
--						      )
--                             ;
RETURN ld_date;
EXCEPTION
WHEN OTHERS THEN
RETURN NULL;
END get_d_nurse_cert_end_date_r
;*/
--11/09/24 commneted changes ends

--Function to get Pacs as of date
FUNCTION get_pacs_as_of_date_r
RETURN DATE
IS
ld_date DATE;
BEGIN

select to_date(to_char(D_EDS_CYCLEDATE_R,'dd-mon-yyyy')) INTO ld_date
from PRCS_GRP_DATE_PARAM_R
where V_PROCESS_NAME_R ='PACS_BATCH_ID';
RETURN ld_date;
EXCEPTION
WHEN OTHERS THEN
RETURN NULL;
END get_pacs_as_of_date_r
;
--Function to get Medical Note Date
/* Commented on 14-Mar-2024
FUNCTION get_d_most_recent_medical_note_date_r (p_n_claim_sk_r IN NUMBER)
RETURN DATE
IS
ld_date DATE;
BEGIN
select   D_CREATED_DATE_R
INTO LD_DATE
 from FCT_CLAIM_NOTE_R_DUR_MV_SSL MED_NOTE
-- (SELECT  NOTE1.N_CLAIM_SK_R ,
--   NOTE2.D_CREATED_DATE_R,
--   NOTE1.V_NOTE_CONTENT_R,
--   rank() over ( partition BY NOTE1.N_CLAIM_SK_R order by NOTE1.T_LAST_MODIFIED_DATE_R DESC) dupremov ,
--   cast(NOTE1.V_NOTE_DATA_R as VARCHAR(4000)) as V_MED_NOTE_DATA_R
-- FROM FCT_GRP_CLAIM_NOTE_R NOTE1,
--   (SELECT  N_CLAIM_SK_R,
--     MAX(D_CREATED_DATE_R) D_CREATED_DATE_R
--   FROM FCT_GRP_CLAIM_NOTE_R
--   WHERE (V_OBJECT_TYPE_R = 'DURATIONREVIEW'
--   OR upper(V_NOTE_CONTENT_R) LIKE '%MED%')
--AND N_CLAIM_SK_R = P_N_CLAIM_SK_R
--   GROUP BY N_CLAIM_SK_R
--   ) NOTE2
-- WHERE NOTE1.N_CLAIM_SK_R  =NOTE2.N_CLAIM_SK_R
-- AND NOTE1.D_CREATED_DATE_R=NOTE2.D_CREATED_DATE_R
--   --AND NOTE1.T_LAST_MODIFIED_DATE_R=NOTE2.T_LAST_MODIFIED_DATE_R
-- AND (V_OBJECT_TYPE_R = 'DURATIONREVIEW'
-- OR upper(V_NOTE_CONTENT_R) LIKE '%MED%')
-- ) MED_NOTE
where  MED_NOTE.N_CLAIM_SK_R = P_N_CLAIM_SK_R
and MED_NOTE.dupremov    =1;
RETURN ld_date;
EXCEPTION
WHEN OTHERS THEN
RETURN NULL;
END get_d_most_recent_medical_note_date_r
;
--Function to get Recent Medical Note
FUNCTION get_v_most_recent_medical_note_r (p_n_claim_sk_r IN NUMBER)
RETURN VARCHAR2
IS
lv_val FCT_GRP_CLAIM_NOTE_R.V_NOTE_CONTENT_R%type;
BEGIN
 select   V_NOTE_CONTENT_R into LV_VAL
 from FCT_CLAIM_NOTE_R_DUR_MV_SSL MED_NOTE/*
 -- (SELECT  NOTE1.N_CLAIM_SK_R ,
 --   NOTE2.D_CREATED_DATE_R,
 --   NOTE1.V_NOTE_CONTENT_R,
 --   rank() over ( partition BY NOTE1.N_CLAIM_SK_R order by NOTE1.T_LAST_MODIFIED_DATE_R DESC) dupremov ,
 --   cast(NOTE1.V_NOTE_DATA_R as VARCHAR(4000)) as V_MED_NOTE_DATA_R
 -- FROM FCT_GRP_CLAIM_NOTE_R NOTE1,
 --   (SELECT  N_CLAIM_SK_R,
 --     MAX(D_CREATED_DATE_R) D_CREATED_DATE_R
 --   FROM FCT_GRP_CLAIM_NOTE_R
 --   WHERE (V_OBJECT_TYPE_R = 'DURATIONREVIEW'
 --   OR upper(V_NOTE_CONTENT_R) LIKE '%MED%')
--	AND N_CLAIM_SK_R=P_N_CLAIM_SK_R
 --   GROUP BY N_CLAIM_SK_R
 --   ) NOTE2
 -- WHERE NOTE1.N_CLAIM_SK_R  =NOTE2.N_CLAIM_SK_R
 -- AND NOTE1.D_CREATED_DATE_R=NOTE2.D_CREATED_DATE_R
 --   --AND NOTE1.T_LAST_MODIFIED_DATE_R=NOTE2.T_LAST_MODIFIED_DATE_R
 -- AND (V_OBJECT_TYPE_R = 'DURATIONREVIEW'
 -- OR upper(V_NOTE_CONTENT_R) LIKE '%MED%')
 -- ) MED_NOTE
where 	MED_NOTE.N_CLAIM_SK_R = P_N_CLAIM_SK_R
and MED_NOTE.dupremov    =1;
RETURN lv_val;
EXCEPTION
WHEN OTHERS THEN
RETURN NULL;
END get_v_most_recent_medical_note_r
;
--Function to get Recent Mgmnt Note Date
FUNCTION get_d_most_recent_management_note_date_r (p_n_claim_sk_r IN NUMBER)
RETURN DATE
IS
ld_date DATE;
begin
    select   D_CREATED_DATE_R
    into ld_date	from  FCT_CLAIM_NOTE_R_MGMNT_MV_SSL MNGT_NOTE
 --   (SELECT NOTE1.N_CLAIM_SK_R,
 --   NOTE2.D_CREATED_DATE_R,
 --   NOTE1.V_NOTE_CONTENT_R,
 --   rank() over ( partition BY NOTE1.N_CLAIM_SK_R order by NOTE1.T_LAST_MODIFIED_DATE_R DESC) dupremov ,
 --   cast(NOTE1.V_NOTE_DATA_R as VARCHAR(4000)) as  V_MGT_NOTE_DATA_R
 -- FROM FCT_GRP_CLAIM_NOTE_R NOTE1,
 --   (SELECT N_CLAIM_SK_R,
 --     MAX(D_CREATED_DATE_R) D_CREATED_DATE_R
 --   FROM FCT_GRP_CLAIM_NOTE_R
 --   WHERE (upper(V_NOTE_TYPE_R) LIKE '%MANAGE%'
 --   OR upper(V_NOTE_TYPE_R) LIKE '%MG%')
--	and N_CLAIM_SK_R=p_N_CLAIM_SK_R
 --   GROUP BY N_CLAIM_SK_R
 --   ) NOTE2
 -- WHERE NOTE1.N_CLAIM_SK_R  =NOTE2.N_CLAIM_SK_R
 -- AND NOTE1.D_CREATED_DATE_R=NOTE2.D_CREATED_DATE_R
 --   --AND NOTE1.T_LAST_MODIFIED_DATE_R=NOTE2.T_LAST_MODIFIED_DATE_R
 -- AND (upper(NOTE1.V_NOTE_TYPE_R) LIKE '%MANAGE%'
 -- OR upper(NOTE1.V_NOTE_TYPE_R) LIKE '%MG%')
 -- ) MNGT_NOTE
where 	 MNGT_NOTE.N_CLAIM_SK_R=p_N_CLAIM_SK_R
AND MNGT_NOTE.dupremov   =1;
RETURN ld_date;
EXCEPTION
WHEN OTHERS THEN
RETURN NULL;
END get_d_most_recent_management_note_date_r
;
--Function to get Recent Mgmnt Note
FUNCTION get_v_most_recent_mgmt_note_r (p_n_claim_sk_r IN NUMBER)
RETURN VARCHAR2
IS
lv_val FCT_GRP_CLAIM_NOTE_R.V_NOTE_CONTENT_R%type;
BEGIN
 select  V_NOTE_CONTENT_R INTO lv_val
from FCT_CLAIM_NOTE_R_MGMNT_MV_SSL MNGT_NOTE
--  select * from
--    (SELECT NOTE1.N_CLAIM_SK_R,
--    NOTE2.D_CREATED_DATE_R,
--    NOTE1.V_NOTE_CONTENT_R,
--    rank() over ( partition BY NOTE1.N_CLAIM_SK_R order by NOTE1.T_LAST_MODIFIED_DATE_R DESC) dupremov ,
--    cast(NOTE1.V_NOTE_DATA_R as VARCHAR(4000)) as  V_MGT_NOTE_DATA_R
--  FROM FCT_GRP_CLAIM_NOTE_R NOTE1,
--    (SELECT N_CLAIM_SK_R,
--      MAX(D_CREATED_DATE_R) D_CREATED_DATE_R
--    FROM FCT_GRP_CLAIM_NOTE_R
--    WHERE (upper(V_NOTE_TYPE_R) LIKE '%MANAGE%'
--    OR upper(V_NOTE_TYPE_R) LIKE '%MG%')
--    GROUP BY N_CLAIM_SK_R
--    ) NOTE2
--  WHERE NOTE1.N_CLAIM_SK_R  =NOTE2.N_CLAIM_SK_R
--  AND NOTE1.D_CREATED_DATE_R=NOTE2.D_CREATED_DATE_R
--    --AND NOTE1.T_LAST_MODIFIED_DATE_R=NOTE2.T_LAST_MODIFIED_DATE_R
--  AND (upper(NOTE1.V_NOTE_TYPE_R) LIKE '%MANAGE%'
--  OR upper(NOTE1.V_NOTE_TYPE_R) LIKE '%MG%')
--  ) MNGT_NOTE
--where MNGT_NOTE.dupremov   =1;
where 	 MNGT_NOTE.N_CLAIM_SK_R=p_N_CLAIM_SK_R
AND MNGT_NOTE.dupremov    =1;
RETURN lv_val;
EXCEPTION
WHEN OTHERS THEN
RETURN NULL;
END get_v_most_recent_mgmt_note_r
;
*/--COmmented on 14-Mar-2024 changes ends
--11/09/24 commneted changes starts
/*--Function get v_claim_ach_payment_ind_r
FUNCTION get_v_claim_ach_payment_ind_r(p_n_claim_sk_r         IN NUMBER
								      )
return VARCHAR2
IS
LV_ACH_INDICATOR VARCHAR2(100);
BEGIN

    SELECT ACH_INDICATOR
		INTO LV_ACH_INDICATOR
	FROM FCT_BENEFIT_PAYMENT_R_CLAIM_ACHIND_MV_SSL
	WHERE n_claim_sk_r=p_n_claim_sk_r;
    --SELECT   --n_claim_sk_r AS claim_skey,
    --    max(ACH_INDICATOR) ACH_INDICATOR
	--	INTO LV_ACH_INDICATOR
    --        FROM
    --          ( SELECT
    --          --DISTINCT
	--	--cd.n_claim_sk_r n_claim_sk_r,
    --           CASE
    --              WHEN upper(T334051.V_PAY_METHOD_R) = 'ACH'
    --              THEN 'Y'
    --              ELSE 'N'
    --            END AS ACH_indicator
    --          FROM FCT_BENEFIT_PAYMENT_R T334051--,
    --            --dim_grp_claim_dir_r cd
    --          WHERE
    --           --cd.n_claim_sk_r = T334051.n_claim_sk_r
    --           T334051.n_claim_sk_r = p_n_claim_sk_r
    --          --and cd.v_active_status_r = 'Y'
	--	group by --T334051.n_claim_sk_r,
    --           CASE
    --              WHEN upper(T334051.V_PAY_METHOD_R) = 'ACH'
    --              THEN 'Y'
    --              ELSE 'N'
    --            END
    --          );
    --        --GROUP BY n_claim_sk_r
	--
RETURN LV_ACH_INDICATOR;
EXCEPTION
WHEN OTHERS THEN
   RETURN NULL;
end get_v_claim_ach_payment_ind_r;
*/--11/09/24 commneted changes ends

--Procedure to rebuild indexes RPT_CLAIM_DTL_R
PROCEDURE prc_rebuild_indexes
IS
LC_REBUILD_INDEX  VARCHAR2(300);
BEGIN
   gc_trcmsg:=gc_trcmsg||'7.a Entered into prc_rebuild_indexes'||chr(13);
  FOR I IN ( select
    'ALTER INDEX '||INDEX_NAME||' REBUILD  parallel 16 nologging' REBUILD_INDEX
    from ALL_INDEXES  where TABLE_NAME ='RPT_CLAIM_DTL_R'
	AND INDEX_NAME NOT LIKE 'PK_%'
	AND INDEX_NAME NOT LIKE 'FK_%'
	AND STATUS='UNUSABLE'
	)
  LOOP
    LC_REBUILD_INDEX:=I.REBUILD_INDEX;
    EXECUTE IMMEDIATE LC_REBUILD_INDEX;
  END LOOP;
   gc_trcmsg:=gc_trcmsg||'7.z Exit from prc_rebuild_indexes'||chr(13);
EXCEPTION
WHEN OTHERS THEN
    gc_errmsg :=SUBSTR(SQLERRM,1,4000);
    gc_trcmsg:=gc_trcmsg||'7.z Error in prc_rebuild_indexes'||chr(13);
    pkg_grp_log_util.prc_update_log
          (
            gn_out_job_id                   --p_job_id
            ,gc_error_status                --p_job_status
            ,gc_errmsg                      --p_err_msg
            ,gc_trcmsg||chr(13)||gc_errmsg  --p_trc_msg
            ,gc_rebuildindexes             --p_log_util_called_by_r
          );
    RAISE;
END prc_rebuild_indexes;
--11/09/24 commneted changes starts

--Function get n_total_benefit_period_days_r
FUNCTION get_n_total_benefit_period_days_r(p_v_claim_number_r   IN VARCHAR2
                                          ,p_as_of_date_r      IN DATE
								         )
return NUMBER
IS
ln_total_amnt NUMBER;
BEGIN

SELECT
n_total_benefit_period_days_r
INTO ln_total_amnt
FROM RPT_CLAIM_DTL_R_totbenperdys_mv_ssl
WHERE V_CLAIM_NUMBER_R=p_v_claim_number_r
  AND n_total_benefit_period_days_r IS NOT NULL;--31/10/24 changes

RETURN ln_total_amnt;
EXCEPTION
WHEN OTHERS THEN
RETURN NULL;
END;
--Function get n_curr_benefit_period_days_r
FUNCTION get_n_curr_benefit_period_days_r(p_v_claim_number_r   IN VARCHAR2
                                          ,p_as_of_date_r      IN DATE
								         )
return NUMBER
IS
ln_curr_amnt NUMBER;
BEGIN

SELECT
n_curr_benefit_period_days_r
INTO ln_curr_amnt
FROM ATOMIC.RPT_CLAIM_DTL_R_CURBENPERDYS_MV_SSL
WHERE V_CLAIM_NUMBER_R=p_v_claim_number_r
  AND n_curr_benefit_period_days_r IS NOT NULL;--31/10/24 changes

RETURN ln_curr_amnt;
EXCEPTION
WHEN OTHERS THEN
RETURN NULL;
END;
--30-jAN-2024 changes ends
--11/09/24 commneted changes ends

--Procedure updates below wavier_ltd_ind_cols
--	V_HAS_ASSOCIATED_WAIVER_IND_R
--	V_HAS_ASSOCIATED_LTD_IND_R
PROCEDURE prc_upd_wavier_ltd_ind_cols
IS
    CURSOR cur_upd_ltd_ind IS
        SELECT
            n_ltd_claim_sk_r                n_claim_sk_r,
            n_ltd_claim_coverage_sk_r       n_claim_coverage_sk_r,
            n_ltd_claim_coverage_group_sk_r n_claim_coverage_group_sk_r,
            v_ltd_claim_number_r            v_claim_number_r,
            v_ltd_claim_identifier_r        v_claim_identifier_r,
            'Y'                             v_has_associated_waiver_ind_r,
            NULL                            v_has_associated_ltd_ind_r
        FROM
            atomic.rpt_associated_claims_mv_ssl
        GROUP BY n_ltd_claim_sk_r
               , n_ltd_claim_coverage_sk_r
               , n_ltd_claim_coverage_group_sk_r
               , v_ltd_claim_number_r
               , v_ltd_claim_identifier_r;

    TYPE var_upd_tbl_ltd_ind_type IS TABLE OF cur_upd_ltd_ind%ROWTYPE;
    lt_var_upd_tbl_ltd_ind_typ var_upd_tbl_ltd_ind_type;

    CURSOR cur_upd_wavier_ind IS
        SELECT
            n_wop_claim_sk_r                n_claim_sk_r,
            n_wop_claim_coverage_sk_r       n_claim_coverage_sk_r,
            n_wop_claim_coverage_group_sk_r n_claim_coverage_group_sk_r,
            v_wop_claim_number_r            v_claim_number_r,
            v_wop_claim_identifier_r        v_claim_identifier_r,
            NULL                            v_has_associated_waiver_ind_r,
            'Y'                             v_has_associated_ltd_ind_r
        FROM
            atomic.rpt_associated_claims_mv_ssl
        GROUP BY n_wop_claim_sk_r
               , n_wop_claim_coverage_sk_r
               , n_wop_claim_coverage_group_sk_r
               , v_wop_claim_number_r
               , v_wop_claim_identifier_r;

    TYPE var_upd_tbl_wavier_ind_type IS TABLE OF cur_upd_wavier_ind%ROWTYPE;
    lt_var_upd_tbl_wavier_ind_typ var_upd_tbl_wavier_ind_type;
        /* 25/10/24 Commented the below block as it has been moved to the procedure
    CURSOR cur_upd_cib_ind IS
        SELECT
            a.n_claim_sk_r,
            a.n_claim_coverage_sk_r,
            a.n_claim_coverage_group_sk_r,
            d_claim_received_date_r,
            a.d_claim_decision_date_r,
            a.d_claim_decision_date_r - b.d_claim_received_date_r AS N_CLAIM_DECISION_DAYS_R,
            CASE
                WHEN a.d_claim_decision_date_r - b.d_claim_received_date_r BETWEEN 0 AND 3 THEN '0 - 3'
                WHEN a.d_claim_decision_date_r - b.d_claim_received_date_r BETWEEN 4 AND 5 THEN '4 - 5'
                WHEN a.d_claim_decision_date_r - b.d_claim_received_date_r BETWEEN 6 AND 7 THEN '6 - 7'
                WHEN a.d_claim_decision_date_r - b.d_claim_received_date_r BETWEEN 8 AND 10 THEN '8 - 10'
                WHEN a.d_claim_decision_date_r - b.d_claim_received_date_r > 10 THEN '> 10'
                ELSE 'U'
            END AS V_TURNAROUND_RANGE1_R,
            a.d_cycle_date_r,
            a.n_yearmonth_r
        FROM rpt_fct_rpt_claim_summary_r a, RPT_CLAIM_DTL_R b
        WHERE a.n_yearmonth_r = b.n_yearmonth_r
          AND a.n_claim_sk_r = b.n_claim_sk_r
          AND a.n_claim_coverage_sk_r = b.n_claim_coverage_sk_r
          AND a.n_claim_coverage_group_sk_r = b.n_claim_coverage_group_sk_r;

    TYPE var_upd_tbl_cib_ind_type IS TABLE OF cur_upd_cib_ind%ROWTYPE;
    lt_var_upd_tbl_cib_ind_typ var_upd_tbl_cib_ind_type;
    */
--25/10/24 CHANGES STARTS
/*	CURSOR cur_upd_perioddys
IS
SELECT V_CLAIM_NUMBER_R
,PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC.GET_N_CURR_BENEFIT_PERIOD_DAYS_R(V_CLAIM_NUMBER_R,NULL ) N_CURR_BENEFIT_PERIOD_DAYS_R
,PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC.GET_N_total_BENEFIT_PERIOD_DAYS_R(V_CLAIM_NUMBER_R,NULL ) N_totAL_BENEFIT_PERIOD_DAYS_R
FROM RPT_CLAIM_DTL_R
WHERE N_YEARMONTH_R=gn_current_month
GROUP BY v_claim_number_R;
   TYPE var_upd_tbl_perioddys_type IS TABLE OF cur_upd_perioddys%ROWTYPE INDEX BY BINARY_INTEGER;
   lt_var_upd_tbl_perioddys_typ var_upd_tbl_perioddys_type;
*/
   /* --04/11/24 changes starts .. the below cursors moved to procedure PRC_GRP_UPD_RPT_CLAIM_DTL_R_COLS
   CURSOR cur_upd_tot_ben_perioddys
   IS
   SELECT
   n_claim_sk_r
   ,v_claim_number_r
   ,n_total_benefit_period_days_r
   FROM RPT_CLAIM_DTL_R_benperdys_gtt
   WHERE n_total_benefit_period_days_r IS NOT NULL
   GROUP BY
   n_claim_sk_r
   ,v_claim_number_r
   ,n_total_benefit_period_days_r
   ;
   TYPE var_upd_tbl_tot_ben_perioddys_type IS TABLE OF cur_upd_tot_ben_perioddys%ROWTYPE INDEX BY BINARY_INTEGER;
   lt_var_upd_tbl_tot_ben_perioddys_typ var_upd_tbl_tot_ben_perioddys_type;

   CURSOR cur_upd_curr_ben_perioddys
   IS
   SELECT
   n_claim_sk_r
   ,v_claim_number_r
   ,n_curr_benefit_period_days_r
   FROM RPT_CLAIM_DTL_R_benperdys_gtt
   WHERE n_curr_benefit_period_days_r IS NOT NULL
   GROUP BY
   n_claim_sk_r
   ,v_claim_number_r
   ,n_curr_benefit_period_days_r
   ;
   TYPE var_upd_tbl_curr_ben_perioddys_type IS TABLE OF cur_upd_curr_ben_perioddys%ROWTYPE INDEX BY BINARY_INTEGER;
   lt_var_upd_tbl_curr_ben_perioddys_typ var_upd_tbl_curr_ben_perioddys_type;
   --25/10/24 CHANGES ENDS
   --04/11/24 changes ends*/
    ln_start_time NUMBER;
BEGIN
    --05/10/24 changes starts
	--Call Log Util pkg to Insert entry in PRCS_JOB_LOG_R
	pkg_grp_log_util.prc_insert_log
                       ( p_source              => gc_source
					    ,p_job_nm              => gc_job_name||'_PRC_UPD_WAVIER_LTD_IND_COLS'
                        ,p_job_status          => gc_running_status
                        ,p_err_msg             => null
                        ,p_trc_msg             => null
                        ,p_n_batch_id          => gn_sysdt_batchid
                        ,p_log_util_called_by_r=> gc_main_loadedby
						,out_job_id            => gn_out_job_id
						);
    --05/10/24 changes ends
    gn_current_month:=FNC_GRP_GET_SSL_YEARMONTH(SYSDATE);--25/10/24 CHANGES
    --gc_trcmsg := gc_trcmsg || '0.1 Entered into from prc_upd_wavier_ltd_ind_cols' || CHR(13);--25/10/24 CHANGES
    gc_trcmsg := gc_trcmsg || '0.1 Entered into from prc_upd_wavier_ltd_ind_cols:-||gn_current_month:-'||gn_current_month || CHR(13);--25/10/24 CHANGES
    ln_start_time := dbms_utility.get_time;
    gc_trcmsg := gc_trcmsg || '1.2 update Ltd ind from prc_upd_wavier_ltd_ind_cols ' || ln_start_time || CHR(13);
    OPEN cur_upd_ltd_ind;
    LOOP
        FETCH cur_upd_ltd_ind BULK COLLECT INTO lt_var_upd_tbl_ltd_ind_typ LIMIT 2000;
        EXIT WHEN lt_var_upd_tbl_ltd_ind_typ.COUNT = 0;

        FORALL X IN 1 .. lt_var_upd_tbl_ltd_ind_typ.COUNT
            UPDATE RPT_CLAIM_DTL_R
            SET v_has_associated_ltd_ind_r = lt_var_upd_tbl_ltd_ind_typ(X).v_has_associated_waiver_ind_r
            WHERE n_claim_sk_r = lt_var_upd_tbl_ltd_ind_typ(X).n_claim_sk_r
              AND n_claim_coverage_sk_r = lt_var_upd_tbl_ltd_ind_typ(X).n_claim_coverage_sk_r
              AND n_claim_coverage_group_sk_r = lt_var_upd_tbl_ltd_ind_typ(X).n_claim_coverage_group_sk_r
              AND n_yearmonth_r = gn_current_month;

        COMMIT;
    END LOOP;
    CLOSE cur_upd_ltd_ind;

    gc_trcmsg := gc_trcmsg || '1.z Update Ltd completed from prc_upd_wavier_ltd_ind_cols ' || ((dbms_utility.get_time - ln_start_time) / 100) || CHR(13);

    ln_start_time := dbms_utility.get_time;
    gc_trcmsg := gc_trcmsg || '2.1 update Wavier ind from prc_upd_wavier_ltd_ind_cols ' || ln_start_time || CHR(13);

    OPEN cur_upd_wavier_ind;
    LOOP
        FETCH cur_upd_wavier_ind BULK COLLECT INTO lt_var_upd_tbl_wavier_ind_typ LIMIT 2000;
        EXIT WHEN lt_var_upd_tbl_wavier_ind_typ.COUNT = 0;

        FORALL X IN 1 .. lt_var_upd_tbl_wavier_ind_typ.COUNT
            UPDATE RPT_CLAIM_DTL_R
            SET v_has_associated_waiver_ind_r = lt_var_upd_tbl_wavier_ind_typ(X).v_has_associated_ltd_ind_r
            WHERE n_claim_sk_r = lt_var_upd_tbl_wavier_ind_typ(X).n_claim_sk_r
              AND n_claim_coverage_sk_r = lt_var_upd_tbl_wavier_ind_typ(X).n_claim_coverage_sk_r
              AND n_claim_coverage_group_sk_r = lt_var_upd_tbl_wavier_ind_typ(X).n_claim_coverage_group_sk_r
              AND n_yearmonth_r = gn_current_month;

        COMMIT;
    END LOOP;
    CLOSE cur_upd_wavier_ind;

    gc_trcmsg := gc_trcmsg || '2.z Update waiver completed from prc_upd_wavier_ltd_ind_cols ' || ((dbms_utility.get_time - ln_start_time) / 100) || CHR(13);

    /* 25/10/24 Commented the below block as it has been moved to the procedure
	OPEN cur_upd_cib_ind;
    LOOP
        FETCH cur_upd_cib_ind BULK COLLECT INTO lt_var_upd_tbl_cib_ind_typ LIMIT 2000;
        EXIT WHEN lt_var_upd_tbl_cib_ind_typ.COUNT = 0;

        FORALL X IN 1 .. lt_var_upd_tbl_cib_ind_typ.COUNT
            UPDATE RPT_CLAIM_DTL_R
            SET D_CLAIM_DECISION_DATE_R = lt_var_upd_tbl_cib_ind_typ(X).D_CLAIM_DECISION_DATE_R,
                N_CLAIM_DECISION_DAYS_R = lt_var_upd_tbl_cib_ind_typ(X).N_CLAIM_DECISION_DAYS_R,
                V_TURNAROUND_RANGE1_R   = lt_var_upd_tbl_cib_ind_typ(X).V_TURNAROUND_RANGE1_R
            WHERE n_claim_sk_r = lt_var_upd_tbl_cib_ind_typ(X).n_claim_sk_r
              AND n_claim_coverage_sk_r = lt_var_upd_tbl_cib_ind_typ(X).n_claim_coverage_sk_r
              AND n_claim_coverage_group_sk_r = lt_var_upd_tbl_cib_ind_typ(X).n_claim_coverage_group_sk_r
              AND n_yearmonth_r = gn_current_month;

        COMMIT;
    END LOOP;
    CLOSE cur_upd_cib_ind;
    gc_trcmsg := gc_trcmsg || '3.z Update CIB Indicator completed from prc_upd_wavier_ltd_ind_cols ' || ((dbms_utility.get_time - ln_start_time) / 100) || CHR(13);
    */
	/*
	--04/11/24 changes starts the below block has been moved to the procedure PRC_GRP_UPD_RPT_CLAIM_DTL_R_COLS
	--25/10/24 CHANGES STARTS
    ln_start_time := dbms_utility.get_time;
    gc_trcmsg:=gc_trcmsg||'3 Insert into RPT_CLAIM_DTL_R_claimdec_GTT'||chr(13);
	--31/10/24 changes starts
	--INSERT /+APPEND_VALUES/ INTO RPT_CLAIM_DTL_R_BENPERDYS_GTT
    INSERT /+APPEND_VALUES/ INTO RPT_CLAIM_DTL_R_BENPERDYS_GTT
    --/SELECT
    --N_CLAIM_SK_R
    --,V_CLAIM_NUMBER_R
    --,PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC.GET_N_CURR_BENEFIT_PERIOD_DAYS_R(V_CLAIM_NUMBER_R,NULL ) N_CURR_BENEFIT_PERIOD_DAYS_R
    --,PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC.GET_N_total_BENEFIT_PERIOD_DAYS_R(V_CLAIM_NUMBER_R,NULL ) N_totAL_BENEFIT_PERIOD_DAYS_R
    --FROM RPT_CLAIM_DTL_R
    --WHERE N_YEARMONTH_R=gn_current_month
    --GROUP BY N_CLAIM_SK_R,v_claim_number_R;
	--/
	SELECT
     RPT_CLAIM_DTL_R.N_CLAIM_SK_R
    ,RPT_CLAIM_DTL_R.V_CLAIM_NUMBER_R
	,cast(null as number) N_CURR_BENEFIT_PERIOD_DAYS_R
    ,TOTBEN.n_total_benefit_period_days_r N_totAL_BENEFIT_PERIOD_DAYS_R
    FROM RPT_CLAIM_DTL_R,RPT_CLAIM_DTL_R_totbenperdys_mv_ssl TOTBEN
    WHERE RPT_CLAIM_DTL_R.V_CLAIM_NUMBER_R=TOTBEN.V_CLAIM_NUMBER_R
	  AND TOTBEN.n_total_benefit_period_days_r IS NOT NULL
      AND N_YEARMONTH_R=gn_current_month
    group by RPT_CLAIM_DTL_R.N_CLAIM_SK_R,RPT_CLAIM_DTL_R.V_CLAIM_NUMBER_R,TOTBEN.N_TOTAL_BENEFIT_PERIOD_DAYS_R
    UNION
    SELECT
     RPT_CLAIM_DTL_R.N_CLAIM_SK_R
    ,RPT_CLAIM_DTL_R.V_CLAIM_NUMBER_R
	,CURBEN.N_CURR_BENEFIT_PERIOD_DAYS_R N_CURR_BENEFIT_PERIOD_DAYS_R
	,cast(null as number) N_TOTAL_BENEFIT_PERIOD_DAYS_R
    FROM RPT_CLAIM_DTL_R,RPT_CLAIM_DTL_R_curbenperdys_mv_ssl CURBEN
    WHERE RPT_CLAIM_DTL_R.V_CLAIM_NUMBER_R=CURBEN.V_CLAIM_NUMBER_R
	  AND CURBEN.N_CURR_BENEFIT_PERIOD_DAYS_R IS NOT NULL
      AND N_YEARMONTH_R=gn_current_month
    GROUP BY RPT_CLAIM_DTL_R.N_CLAIM_SK_R,RPT_CLAIM_DTL_R.v_claim_number_R,CURBEN.N_CURR_BENEFIT_PERIOD_DAYS_R
    ;
	--31/10/24 changes ends
    COMMIT;

    gc_trcmsg:=gc_trcmsg||'3.Z Insert COMPLETED into RPT_CLAIM_DTL_R_BENPERDYS_GTT'||((dbms_utility.get_time - ln_start_time)/100)||chr(13);

	gc_trcmsg:=gc_trcmsg||'4. Update Total and Current Period Days starts from main '||((dbms_utility.get_time - ln_start_time)/100)||chr(13);
    OPEN  cur_upd_perioddys ;
	LOOP
	lt_var_upd_tbl_perioddys_typ.DELETE;
    FETCH cur_upd_perioddys bulk collect into  lt_var_upd_tbl_perioddys_typ limit GN_BULK_COLL_CNT;
	FORALL X in lt_var_upd_tbl_perioddys_typ.first..lt_var_upd_tbl_perioddys_typ.last
    UPDATE   RPT_CLAIM_DTL_R
      set n_curr_benefit_period_days_r=lt_var_upd_tbl_perioddys_typ(X).n_curr_benefit_period_days_r
      , n_total_benefit_period_days_r=lt_var_upd_tbl_perioddys_typ(X).n_total_benefit_period_days_r
	--25/10/24 CHANGES STARTS
    --where RPT_CLAIM_DTL_R.n_yearmonth_r=gn_current_month
    --and (RPT_CLAIM_DTL_R.V_CLAIM_NUMBER_R)=lt_var_upd_tbl_perioddys_typ(X).V_CLAIM_NUMBER_R;
	where RPT_CLAIM_DTL_R.N_CLAIM_SK_R=lt_var_upd_tbl_perioddys_typ(X).N_CLAIM_SK_R
	AND RPT_CLAIM_DTL_R.n_yearmonth_r=gn_current_month	;
	--25/10/24 CHANGES ENDS
     commit;
     EXIT WHEN cur_upd_perioddys%NOTFOUND;
    END LOOP;
	CLOSE cur_upd_perioddys;
    gc_trcmsg:=gc_trcmsg||'4.z Update Total and Current Period Days completed from main '||((dbms_utility.get_time - ln_start_time)/100)||chr(13);
   */
    --04/11/24 CHANGES STARTS
	/*ln_start_time := dbms_utility.get_time;
    gc_trcmsg:=gc_trcmsg||'4.a Update Total Period Days starts from main '||((dbms_utility.get_time - ln_start_time)/100)||chr(13);
    OPEN  cur_upd_tot_ben_perioddys ;
	LOOP
	lt_var_upd_tbl_tot_ben_perioddys_typ.DELETE;
    --FETCH cur_upd_tot_ben_perioddys bulk collect into  lt_var_upd_tbl_tot_ben_perioddys_typ limit GN_BULK_COLL_CNT;--31/10/24 changes
    FETCH cur_upd_tot_ben_perioddys bulk collect into  lt_var_upd_tbl_tot_ben_perioddys_typ limit 2000;              --31/10/24 changes
	FORALL X in lt_var_upd_tbl_tot_ben_perioddys_typ.first..lt_var_upd_tbl_tot_ben_perioddys_typ.last
    UPDATE   RPT_CLAIM_DTL_R
      set n_total_benefit_period_days_r=lt_var_upd_tbl_tot_ben_perioddys_typ(X).n_total_benefit_period_days_r
	where RPT_CLAIM_DTL_R.N_CLAIM_SK_R=lt_var_upd_tbl_tot_ben_perioddys_typ(X).N_CLAIM_SK_R
	AND RPT_CLAIM_DTL_R.n_yearmonth_r=gn_current_month	;
     commit;
     EXIT WHEN cur_upd_tot_ben_perioddys%NOTFOUND;
    END LOOP;
	CLOSE cur_upd_tot_ben_perioddys;
    gc_trcmsg:=gc_trcmsg||'4.a.z Update Total Period Days completed from main '||((dbms_utility.get_time - ln_start_time)/100)||chr(13);
    ln_start_time := dbms_utility.get_time;
	gc_trcmsg:=gc_trcmsg||'4.b Update Curr Period Days starts from main '||((dbms_utility.get_time - ln_start_time)/100)||chr(13);
    OPEN  cur_upd_curr_ben_perioddys ;
	LOOP
	lt_var_upd_tbl_curr_ben_perioddys_typ.DELETE;
    --FETCH cur_upd_curr_ben_perioddys bulk collect into  lt_var_upd_tbl_curr_ben_perioddys_typ limit GN_BULK_COLL_CNT;--31/10/24 changes
    FETCH cur_upd_curr_ben_perioddys bulk collect into  lt_var_upd_tbl_curr_ben_perioddys_typ limit 2000;              --31/10/24 changes
	FORALL X in lt_var_upd_tbl_curr_ben_perioddys_typ.first..lt_var_upd_tbl_curr_ben_perioddys_typ.last
    UPDATE   RPT_CLAIM_DTL_R
      set n_curr_benefit_period_days_r=lt_var_upd_tbl_curr_ben_perioddys_typ(X).n_curr_benefit_period_days_r
	where RPT_CLAIM_DTL_R.N_CLAIM_SK_R=lt_var_upd_tbl_curr_ben_perioddys_typ(X).N_CLAIM_SK_R
	AND RPT_CLAIM_DTL_R.n_yearmonth_r=gn_current_month;
     commit;
     EXIT WHEN cur_upd_curr_ben_perioddys%NOTFOUND;
    END LOOP;
	CLOSE cur_upd_curr_ben_perioddys;
    gc_trcmsg:=gc_trcmsg||'4.b.z Update Curr Period Days completed from main '||((dbms_utility.get_time - ln_start_time)/100)||chr(13);
	--25/10/24 CHANGES ENDS
    */--04/11/24 CHANGES ENDS
    gc_trcmsg := gc_trcmsg || '0.z Exit from prc_upd_wavier_ltd_ind_cols' || CHR(13);
    pkg_grp_log_util.prc_update_log
      (
        gn_out_job_id                   --p_job_id
        ,gc_success_status              --p_job_status
        ,gc_errmsg                      --p_err_msg
        ,gc_trcmsg                      --p_trc_msg
        ,gc_upd_ind_cols_by             --p_log_util_called_by_r
      );

EXCEPTION
    WHEN OTHERS THEN
        gc_errmsg := SUBSTR(SQLERRM, 1, 4000);
        gc_trcmsg := gc_trcmsg || '0.z Error in prc_upd_wavier_ltd_ind_cols' || CHR(13);

        pkg_grp_log_util.prc_update_log
        (
            gn_out_job_id,                   -- p_job_id
            gc_error_status,                 -- p_job_status
            gc_errmsg,                       -- p_err_msg
            gc_trcmsg || CHR(13) || gc_errmsg, -- p_trc_msg
            gc_upd_ind_cols_by               -- p_log_util_called_by_r
        );
        RAISE;
END prc_upd_wavier_ltd_ind_cols;

--05/10/24 changes starts
--procedure updates below columns
--D_CLAIM_DECISION_DATE_R
--N_CLAIM_DECISION_DAYS_R
--V_TURNAROUND_RANGE1_R
PROCEDURE prc_upd_decision_cols
IS
CURSOR cur_upd_dec_cols
IS
SELECT * FROM atomic.RPT_CLAIM_DTL_R_claimdec_GTT;
TYPE var_upd_tbl_dec_type IS TABLE OF cur_upd_dec_cols%ROWTYPE;
lt_var_upd_tbl_dec_typ var_upd_tbl_dec_type;

ln_start_time NUMBER;
LN_YEARMONTH_R NUMBER:= FNC_GRP_GET_SSL_YEARMONTH(SYSDATE);--25/10/24 CHANGES
BEGIN
    --Call Log Util pkg to Insert entry in PRCS_JOB_LOG_R
	pkg_grp_log_util.prc_insert_log
                       ( p_source              => gc_source
					    ,p_job_nm              => gc_job_name||'_PRC_UPD_DECISION_COLS'
                        ,p_job_status          => gc_running_status
                        ,p_err_msg             => null
                        ,p_trc_msg             => null
                        ,p_n_batch_id          => gn_sysdt_batchid
                        ,p_log_util_called_by_r=> gc_upd_decision_cols
						,out_job_id            => gn_out_job_id
						);
    gc_trcmsg:=gc_trcmsg||'1. Entered into PRC_UPD_DECISION_COLS'||chr(13);
    gc_trcmsg:=gc_trcmsg||'1.1 Insert into RPT_CLAIM_DTL_R_claimdec_GTT'||chr(13);
    INSERT /*+APPEND_VALUES*/ INTO RPT_CLAIM_DTL_R_claimdec_GTT
    SELECT  n_claim_sk_r,
            n_claim_coverage_sk_r,
            n_claim_coverage_group_sk_r,
    		d_claim_decision_date_r,
    		d_claim_received_date_r,
    		N_CLAIM_DECISION_DAYS_R,
            CASE
                WHEN d_claim_decision_date_r - d_claim_received_date_r BETWEEN 0 AND 3 THEN '0 - 3'
                WHEN d_claim_decision_date_r - d_claim_received_date_r BETWEEN 4 AND 5 THEN '4 - 5'
                WHEN d_claim_decision_date_r - d_claim_received_date_r BETWEEN 6 AND 7 THEN '6 - 7'
                WHEN d_claim_decision_date_r - d_claim_received_date_r BETWEEN 8 AND 10 THEN '8 - 10'
                WHEN d_claim_decision_date_r - d_claim_received_date_r > 10 THEN '> 10'
                ELSE 'U'
            END AS V_TURNAROUND_RANGE1_R
    FROM (
    SELECT  a.n_claim_sk_r,
            a.n_claim_coverage_sk_r,
            a.n_claim_coverage_group_sk_r,
            b.d_claim_received_date_r,
            MAX(a.d_claim_decision_date_r) d_claim_decision_date_r,
            MAX(a.d_claim_decision_date_r - b.d_claim_received_date_r) AS N_CLAIM_DECISION_DAYS_R--,
            --CASE
            --    WHEN a.d_claim_decision_date_r - b.d_claim_received_date_r BETWEEN 0 AND 3 THEN '0 - 3'
            --    WHEN a.d_claim_decision_date_r - b.d_claim_received_date_r BETWEEN 4 AND 5 THEN '4 - 5'
            --    WHEN a.d_claim_decision_date_r - b.d_claim_received_date_r BETWEEN 6 AND 7 THEN '6 - 7'
            --    WHEN a.d_claim_decision_date_r - b.d_claim_received_date_r BETWEEN 8 AND 10 THEN '8 - 10'
            --    WHEN a.d_claim_decision_date_r - b.d_claim_received_date_r > 10 THEN '> 10'
            --    ELSE 'U'
            --END AS V_TURNAROUND_RANGE1_R
                                 --,
            --a.d_cycle_date_r,
            --a.n_yearmonth_r
        FROM rpt_fct_rpt_claim_summary_r a,RPT_CLAIM_DTL_R b
        WHERE   b.n_claim_sk_r                = a.n_claim_sk_r
            AND b.n_claim_coverage_sk_r       = a.n_claim_coverage_sk_r
            AND b.n_claim_coverage_group_sk_r = a.n_claim_coverage_group_sk_r
            --AND b.n_yearmonth_r               = FNC_GRP_GET_SSL_YEARMONTH(SYSDATE)--25/10/24 CHANGES
            AND b.n_yearmonth_r               = LN_YEARMONTH_R                      --25/10/24 CHANGES
        group by a.n_claim_sk_r,
            a.n_claim_coverage_sk_r,
            a.n_claim_coverage_group_sk_r,
            b.d_claim_received_date_r
    )
    GROUP BY n_claim_sk_r,
            n_claim_coverage_sk_r,
            n_claim_coverage_group_sk_r,
    		d_claim_decision_date_r,
    		d_claim_received_date_r,
    		N_CLAIM_DECISION_DAYS_R,
            CASE
                WHEN d_claim_decision_date_r - d_claim_received_date_r BETWEEN 0 AND 3 THEN '0 - 3'
                WHEN d_claim_decision_date_r - d_claim_received_date_r BETWEEN 4 AND 5 THEN '4 - 5'
                WHEN d_claim_decision_date_r - d_claim_received_date_r BETWEEN 6 AND 7 THEN '6 - 7'
                WHEN d_claim_decision_date_r - d_claim_received_date_r BETWEEN 8 AND 10 THEN '8 - 10'
                WHEN d_claim_decision_date_r - d_claim_received_date_r > 10 THEN '> 10'
                ELSE 'U'
            END;
    COMMIT;
    gc_trcmsg:=gc_trcmsg||'1.z Insert completed RPT_CLAIM_DTL_R_claimdec_GTT'||chr(13);
    ln_start_time := dbms_utility.get_time;

    gc_trcmsg := gc_trcmsg || '2. update Decision Cols from prc_upd_wavier_ltd_ind_cols ' || ln_start_time || CHR(13);
    OPEN cur_upd_dec_cols;
    LOOP
        FETCH cur_upd_dec_cols BULK COLLECT INTO lt_var_upd_tbl_dec_typ LIMIT 2000;
        EXIT WHEN lt_var_upd_tbl_dec_typ.COUNT = 0;

        FORALL X IN 1 .. lt_var_upd_tbl_dec_typ.COUNT
            UPDATE RPT_CLAIM_DTL_R
            SET
			d_claim_decision_date_r = lt_var_upd_tbl_dec_typ(X).d_claim_decision_date_r,
			n_claim_decision_days_r = lt_var_upd_tbl_dec_typ(X).n_claim_decision_days_r,
			v_turnaround_range1_r   = lt_var_upd_tbl_dec_typ(X).v_turnaround_range1_r
            WHERE n_claim_sk_r = lt_var_upd_tbl_dec_typ(X).n_claim_sk_r
              AND n_claim_coverage_sk_r = lt_var_upd_tbl_dec_typ(X).n_claim_coverage_sk_r
              AND n_claim_coverage_group_sk_r = lt_var_upd_tbl_dec_typ(X).n_claim_coverage_group_sk_r
              AND n_yearmonth_r = gn_current_month;

        COMMIT;
    END LOOP;
    CLOSE cur_upd_dec_cols;

    gc_trcmsg := gc_trcmsg || '2.z Decision Cols completed from PRC_UPD_DECISION_COLS ' || ((dbms_utility.get_time - ln_start_time) / 100) || CHR(13);

    gc_trcmsg := gc_trcmsg || '0.z Exit from PRC_UPD_DECISION_COLS' || CHR(13);
    pkg_grp_log_util.prc_update_log
      (
        gn_out_job_id                   --p_job_id
        ,gc_success_status              --p_job_status
        ,gc_errmsg                      --p_err_msg
        ,gc_trcmsg                      --p_trc_msg
        ,gc_upd_decision_cols               --p_log_util_called_by_r
      );

EXCEPTION
    WHEN OTHERS THEN
        gc_errmsg := SUBSTR(SQLERRM, 1, 4000);
        gc_trcmsg := gc_trcmsg || '0.z Error in PRC_UPD_DECISION_COLS' || CHR(13);

        pkg_grp_log_util.prc_update_log
        (
            gn_out_job_id,                   -- p_job_id
            gc_error_status,                 -- p_job_status
            gc_errmsg,                       -- p_err_msg
            gc_trcmsg || CHR(13) || gc_errmsg, -- p_trc_msg
            gc_upd_decision_cols               -- p_log_util_called_by_r
        );

        DBMS_OUTPUT.PUT_LINE(gc_errmsg);
            --  DBMS_OUTPUT.PUT_LINE('LINE_EROR' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE());


        RAISE;
END PRC_UPD_DECISION_COLS;
--05/10/24 changes ends

end PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC;

