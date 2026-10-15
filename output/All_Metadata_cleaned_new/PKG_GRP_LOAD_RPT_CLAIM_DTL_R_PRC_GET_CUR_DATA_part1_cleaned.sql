-- Cleaned for lineage: PKG_GRP_LOAD_RPT_CLAIM_DTL_R_PRC_GET_CUR_DATA (part 1/1)

-- REF CURSOR lineage (OPEN ... FOR SELECT -> INSERT INTO RPT_CLAIM_DTL_R)
INSERT INTO RPT_CLAIM_DTL_R
select 
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
        
        ,D_WORKSHEET_START_DATE_R
        ,D_WORKSHEET_END_DATE_R
        ,v_lob_type_r 
        
        ,V_SOURCE_SYSTEM_NAME_R
        ,N_CURR_BENEFIT_PERIOD_DAYS_R
        ,N_TOTAL_BENEFIT_PERIOD_DAYS_R

,N_BASIC_INSURED_SALARY_R
        ,V_BASIC_INSURED_SALARY_IND_R

,n_rehab_offset_amt_088_r
        ,v_rehab_offset_ind_088_r
        ,n_workers_comp_offset_amt_083_r
        ,n_other_offset_amt_r
        ,v_pfl_leave_type_r
        ,v_pfl_license_number_r

,d_closed_month_start_date_r
        ,d_closed_month_end_date_r

,V_APPEAL_IND_R
        ,V_APPEAL_RESULT_STATUS_CODE_R
        ,D_APPEAL_RESULT_STATUS_CODE_EFF_DATE_R		,

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

V_CLAIM_WELLNESS_IND_R
        
       ,V_HAS_ASSOCIATED_WAIVER_IND_R
       ,V_HAS_ASSOCIATED_LTD_IND_R   
        
       , V_CLAIM_STATUS_REASON_DESC_R

,D_CLAIM_DECISION_DATE_R
		,N_CLAIM_DECISION_DAYS_R
		,V_TURNAROUND_RANGE1_R
        ,V_OVERRIDE_NAME_R
		,D_RECORD_START_DATE_R
		,D_RECORD_END_DATE_R
        
         from (
        select

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
		
         diag.additional_diag_code                                                       V_ADD_DIAG_CATEGORY_CODE_R
        ,diag.add_diag_category_desc                                                     V_ADD_DIAG_CATEGORY_DESC_R
        ,diag.additional_diag_code                                                       V_ADD_DIAGNOSIS_CODE_R	                    
        ,diag.V_PRI_DIAG_CATEGORY_CODE_R                                                 V_PRI_DIAG_CATEGORY_CODE_R	                
        ,diag.V_PRI_DIAG_CATEGORY_DESC_R                                                 V_PRI_DIAG_CATEGORY_DESC_R	                
        ,diag.primary_diag_code                                                          V_PRI_DIAGNOSIS_CODE_R	                    
        ,diag.diagnosis_type_code                                                        N_DIAGNOSIS_TYPE_CODE_R	                
        ,diag.additional_desc                                                            V_ADD_DIAG_CODE_DESC_R	                    
        ,DIAG.Primary_desc                                                               V_PRI_DIAG_CODE_DESC_R	                    
        ,PAYMENT_DATES.Last_Payment_Date                                                 D_LAST_PAYMENT_DATE_R	                    
        ,G.D_AGE_REDUCTION_DATE_R                                                        D_AGE_REDUCTION_DATE_R

,CAST(NULL AS VARCHAR2(100))                                                      V_CLAIM_ACH_PAYMENT_IND_R	
        ,case when v_lob_type_r in ('LTD', 'STD', 'VPL', 'VPS')
        then m.D_BENEFIT_START_R else n.D_BENEFIT_START_R     end                        D_BENEFIT_START_R
        ,t.v_event_cause_r                                                               V_CAUSE_OF_EVENT_CODE_R
        
        ,cast(null as varchar2(100))                                                     V_CAUSE_OF_EVENT_DESC_R
        ,(CASE WHEN a.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP')
          THEN g.V_CLASS_ID_R
          ELSE b.V_CLASS_ID_R
          END
          )                                                                  			 V_CLAIM_CLASS_ID_R

,(CASE WHEN a.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP') and A.V_SOURCE_SYSTEM_NAME_R = 'PACS'
              THEN g.D_DATE_CLOSED_R
              else D.d_closure_date_r
          end
                                              )                                          D_CLAIM_CLOSED_DATE_R	           
        
        ,r.V_ELIGIBILITY_OUTCOME_R                                                       V_ELIGIBILITY_DECISION_R	                
        ,r.V_DISABILITY_DATE_STATUS_R                                                    V_ELIGIBILITY_REASON_R
        ,g.N_CLAIM_COVERAGE_GROUP_SK_R                                                   N_CLAIM_COVERAGE_GROUP_SK_R	            
        ,b.n_claim_coverage_sk_r                                                         N_CLAIM_COVERAGE_SK_R	                    
        ,a.N_CLAIM_SK_R                                                                  N_CLAIM_SK_R	                            
        ,s.V_CLAIM_EVENT_NUMBER_R                                                        V_CLAIM_EVENT_NUMBER_R
        ,a.V_CLAIM_NUMBER_R                                                              V_CLAIM_NUMBER_R	                         
        ,(CASE WHEN d.V_CLAIM_STATUS_REASON_CODE_R IN ('22','46') THEN
           (SYSDATE - RECEIVED_DATE.RECEIVED_DATE)
           ELSE NULL
           END
          )                                                                              N_CLAIM_PENDING_AGE_R	                     
        ,m.n_taxable_override_pct_r                                                      N_CLAIM_TAXABLE_BENEFIT_PCT_R
        ,cast(null as number)                                                            N_DAYS_OPEN_R
        ,

(case
                when
                     nvl(r.n_elim_period_r,0) <> 0 THEN
                    r.n_elim_period_r
                WHEN
                    
                    CASE UPPER(t.v_event_cause_r) 
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
        	)               + D.d_date_of_loss_r                                         D_DISABILITY_START_DATE_R	                 
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
          END)                                                                           V_DURATION_INDICATOR_R	                     
        ,
           CAST(p.V_CURR_DURATION_R	 AS VARCHAR2(100))														V_DURATION_PERIOD_R
         ,payment_dates.earliest_payment_date                                             D_EARLIEST_BENEFIT_PAYMENT_DATE_R

,PAYMENT_DATES.EARLIEST_SERVICE_PERIOD_FROM_DATE D_EARLIEST_SERVICE_PERIOD_FROM_R
        ,PAYMENT_DATES.EARLIEST_SERVICE_PERIOD_TO_DATE   D_EARLIEST_SERVICE_PERIOD_TO_R	
        ,CAST((CASE
                WHEN r.n_elim_period_r <> ''
                     OR r.n_elim_period_r <> 0 THEN
                    r.n_elim_period_r
                WHEN
                    
                    CASE UPPER(t.v_event_cause_r) 
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
        	) AS VARCHAR2(100))                                                                           V_ELIMINATION_PERIOD_R	                     
        ,R.D_DATE_QP_ENDS_R                                                              D_EST_QUALIFYING_PERIOD_EXP_DATE_R
        
        ,CAST(NULL AS VARCHAR2(100))                                                      V_EST_SS_IND_R

,(Case when a.v_lob_type_r IN ( 'LTD', 'VPL' )
          and p.V_CURR_DURATION_R >= '024'   
          and p.V_CURR_DURATION_R <= '036'
          then 'Y' else 'N' end)                                                          V_EXTENDED_DURATION_IND_R
        
        ,(CASE
            WHEN C.v_policy_prefix_r = 'VAI' THEN
                D.d_date_of_event_r
            ELSE
                D.d_date_of_loss_r
         END)                                                                            D_LOSS_DATE_R	                             
        ,d.D_RETURN_TO_MOD_WKDT_R                                                        D_MODIFIED_RTW_DATE_R

,payment_dates.most_recent_service_period_from_date                              D_MOST_RECENT_SERVICE_PERIOD_FROM_R
        ,payment_dates.most_recent_service_period_to_date                                D_MOST_RECENT_SERVICE_PERIOD_TO_R
        ,CAST(NULL AS DATE)                                                              D_NURSE_CERT_END_DATE_R
        ,u.N_NURSE_CERT_SEQ_R                                                            N_NURSE_CERT_SEQ_R
        ,x.V_CODE_R                                                                      V_OCCUPATION_CODE_R 						 
        ,x.V_DESCRIPTION_R                                                               V_OCCUPATION_DESC_R	                     
        ,d.V_CHILD_GENDER_R                                                              V_PFL_CHILD_GENDER_R	                     
        ,d.D_PFL_DOB_R                                                                   D_PFL_DOB_R	                             
        ,d.V_MANDATED_FAMILY_MEMBER_R                                                    V_MANDATED_FAMILY_MEMBER_R	                 
        ,d.V_LEAVE_REASON_R                                                              V_LEAVE_REASON_R	                         
        ,d.D_PFL_DOP_R                                                                   D_PFL_DOP_R	                             
        ,CAST(NULL AS DATE)                                                              D_PHYS_CERT_END_DATE_R	
        ,r.D_PLAN_DUR_DATE_R                                                             D_PLAN_DUR_DATE_R	                         
        ,g.D_RETIREMENT_TERMINATION_DAT_R                                                D_RETIREMENT_TERMINATION_DATE_R
        ,d.D_RETURN_TO_WORK_DATE_R                                                       D_RETURN_TO_WORK_DATE_R
        ,CAST(NULL AS VARCHAR2(100))                                                     V_SOCIAL_SECURITY_IND_R
        ,(CASE WHEN d.d_closure_date_r - received_date.Received_date BETWEEN 0 AND 3 THEN '0 - 3'
         WHEN d.d_closure_date_r - received_date.Received_date BETWEEN 4 AND 5 THEN '4 - 5'
         WHEN d.d_closure_date_r - received_date.Received_date BETWEEN 6 AND 7 THEN '6 - 7'
         WHEN d.d_closure_date_r - received_date.Received_date BETWEEN 8 AND 10 THEN  '8 - 10'
         WHEN d.d_closure_date_r - received_date.Received_date > 10 THEN '>10' ELSE 'U' END)   V_TURNAROUND_RANGE_R
        ,(CASE WHEN g.V_CLAIM_COVERAGE_CODE_R like '%WP%' then 'Waiver' else 'Non-Waiver' END) V_WAIVER_IND_R	                             
        ,(CASE WHEN A.v_lob_type_r = 'WOP' then g.d_date_closed_r else NULL END)              D_WAIVER_STATUS_DATE_R
        ,r.N_WAIVER_TERMINATION_AGE_R                                                    N_WAIVER_TERMINATION_AGE_R
        ,R.D_WAIVER_TERMINATION_DATE_R                                                   D_WAIVER_TERMINATION_DATE_R
        
        ,CAST(NULL AS DATE)                                                              D_CLAIM_AS_OF_DATE_R	                     
        
        ,CAST(NULL AS VARCHAR2(100))                                                     V_METHOD_R
        
        ,CAST(NULL AS VARCHAR2(100))                                                     V_METHOD_STYLE_R
        ,NVL(G.V_CLAIM_IDENTIFIER_R, a.v_claim_number_r)                                 V_CLAIM_IDENTIFIER_R

,CAST(NVL(o.MOST_RECENT_ACTIVITY_DATE, d.T_EVENT_TIMESTAMP_R) AS DATE) AS D_MOST_RECENT_ACTIVITY_DATE_R

,received_date.Received_date                                                     D_CLAIM_RECEIVED_DATE_R
		
        ,a.FIC_MIS_DATE_R                                                                FIC_MIS_DATE_R
        ,ltd_policy_indicator.ltd_policy_ind                                             V_LTD_POLICY_IND_R	                         
        ,a.V_COMPANY_R                                                                   V_CLAIM_COMPANY_R	                         
        
        ,NVL(UPPER(a.V_PRIVACY_INDICATOR_R),'EXTERNAL')                                                         V_PRIVACY_INDICATOR_R

,CAST(NULL AS NUMBER)                                                            N_ANY_OCC_DAYS_REMAINING_R   
        ,r.D_ANYOCC_DATE_R                                                               D_ANY_OCC_DECISION_DATE_R

,(Case when r.v_own_occ_period_r like '%MOS' then substr(r.v_own_occ_period_R,1,2)
          When r.v_own_occ_period_r like '@%' then substr(r.v_own_occ_period_R,2,2)
          End)                                                                             V_ANY_OCC_PERIOD_R
        
        ,(Case when r.v_own_occ_period_r like '%MOS' then 'M'
         When r.v_own_occ_period_r like '@%' then 'A'
         End)                                                                              V_ANY_OCC_PERIOD_IND_R
        
        ,r.D_ANYOCC_START_DATE_R                                                           D_ANY_OCC_START_DATE_R

,(case when r.v_own_occ_period_r like '@%'  then 'Own Occ Only'
                 when gd_pacs_as_of_date_r <= r.D_ANYOCC_START_DATE_R  then 'Own Occ'
                 when gd_pacs_as_of_date_r > r.D_ANYOCC_START_DATE_R    then 'Any Occ'
                 else 'Unknown'
         end )                                                                            V_ANY_OCC_OWN_OCC_IND_R
        
        ,(Case when r.v_own_occ_period_r like '%MOS' then substr(r.v_own_occ_period_R,1,2)
          When r.v_own_occ_period_r like '@%' then substr(r.v_own_occ_period_R,2,2)
          End
          )                                                                               V_OWN_OCC_PERIOD_R
        
        ,(Case when r.v_own_occ_period_r like '%MOS' then 'M'
          When r.v_own_occ_period_r like '@%' then 'A'
          End)                                                                            V_OWN_OCC_PERIOD_IND_R
        
        ,(CASE WHEN a.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP')
          THEN g.V_CLAIM_COVERAGE_CODE_R
          ELSE b.V_CLAIM_COVERAGE_CODE_R
          END
          )                                                                               V_CLAIM_COVERAGE_CODE_R	                 
        ,(CASE WHEN a.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP')
          THEN l.V_PRODUCT_LINE_DESC_R
          ELSE j.V_PRODUCT_LINE_DESC_R
          END
          )                                                          					 V_PRODUCT_LINE_DESC_R	                     
        ,g.N_COV_GRP_ID_R                                                                N_COV_GRP_ID_R	                             
        ,(CASE WHEN a.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP')
          THEN l.v_basic_product_line_desc_r
          ELSE j.v_basic_product_line_desc_r
          END
          )                                                  								V_CLAIM_COVERAGE_DESC_R

,appeal.d_received_date_r                                                          D_APPEAL_RECEIVED_DATE_R
		,appeal.v_denial_overturn_type_r                                                   V_APPEAL_DENIAL_OVERTURN_TYPE_R
		,appeal.v_user_id_r                                                                V_APPEALS_ANALYST_R
		,appeal.d_reaffirmed_date_r                                                        D_APPEAL_COMPLETED_DATE_R
		,appeal.n_source_version_seq_number_r                                              N_APPEAL_SOURCE_VERSION_SEQ_NUMBER_R

,CAST(NULL AS DATE)                                                                      D_MOST_RECENT_MEDICAL_NOTE_DATE_R	                      
        ,CAST(NULL AS VARCHAR2(4000))                                                            V_MOST_RECENT_MEDICAL_NOTE_R	                          
        ,CAST(NULL AS DATE)                                                                      D_MOST_RECENT_MANAGEMENT_NOTE_DATE_R	                  
        ,CAST(NULL AS VARCHAR2(4000))                                                            V_MOST_RECENT_MGMT_NOTE_R
        ,f.D_SS_DEP_AWARD_EFF_DATE_R                                                     D_SS_DEP_AWARD_EFF_DATE_R
        ,f.V_SS_DEPENDENT_STATUS_R                                                       V_SS_DEPENDENT_STATUS_R
        ,f.D_SS_DEP_TERM_DATE_R                                                          D_SS_DEP_TERM_DATE_R
        ,f.V_SS_DEP_AWARD_TYPE_R                                                         V_SS_DEP_AWARD_TYPE_R
        ,f.v_ss_dep_pursue_flag_r                                                        V_SS_DEP_PURSUE_IND_R	                     
        ,f.D_CHANGE_DATE_R                                                               D_SS_MOST_RECENT_UPDATE_DATE_R	             
        ,f.D_SS_PRIMARY_EFF_DATE_R                                                       D_SS_PRIMARY_EFF_DATE_R
        ,f.V_SS_STATUS_DESCRIPTION_R                                                     V_SS_STATUS_DESCRIPTION_R
        ,f.D_SS_CLOSED_TERM_DATE_R                                                       D_SS_CLOSED_TERM_DATE_R
        ,f.V_SS_PRIMARY_AWARD_TYPE_R                                                     V_SS_PRIMARY_AWARD_TYPE_R
        
        ,(case  when upper(F.V_SS_PURSUE_FLAG_R) in ('INSURED PURSUING', 'YES') then 'Y' else case  when upper(F.V_SS_PURSUE_FLAG_R) = 'NO' then 'N' else NULL end  end  ) V_SS_PRIMARY_PURSUE_IND_R 
        
        ,substr(V_SS_REJECT_REASON_R , 1 , instr(V_SS_REJECT_REASON_R , '-') - 1)        V_SS_REJECT_REASON_CODE_R                   
        ,f.V_SS_REJECT_REASON_R                                                          V_SS_REJECT_REASON_R

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
        
        ,(CASE WHEN a.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP')
        THEN g.V_REASON_CODE_R
        else D.V_CLAIM_STATUS_REASON_CODE_R
        end
        )                                                                                  V_CLAIM_STATUS_CODE_R	                     
        ,

case when a.v_lob_type_r in ('LIFE', 'NONS', 'WOP')
        then nvl(claim_status_life.V_CLAIM_STATUS_DESC_R, sales_status_life.V_ORIG_CLAIM_STATUS_DESC_R)
        else COALESCE(claim_status_disability.V_CLAIM_STATUS_DESC_R,sales_status_disability.V_ORIG_CLAIM_STATUS_DESC_R,D.V_CLAIM_STATUS_REASON_DESC_R)  end V_CLAIM_STATUS_DESC_R

,CAST(p.D_CLAIM_STATUS_CODE_EFF_DATE_R AS DATE)                                                D_CLAIM_STATUS_EFF_DATE_R	                 
        ,CAST(p.D_LAST_IN_STATUS_46_DATE_R      AS DATE)                                              D_LAST_IN_STATUS_46_DATE_R	                 
        ,p.V_PRIOR_CLAIM_CLOSURE_CODE_R                                                  V_PRIOR_CLAIM_STATUS_CLOSURE_CODE_R
        ,P.V_PRIOR_CLAIM_STATUS_CODE_R                                                   V_PRIOR_CLAIM_STATUS_CODE_R	             
        ,
        case when a.v_lob_type_r in ('LIFE', 'NONS', 'WOP')
        then nvl(sales_status_life.V_NEW_CLAIM_STATUS_DESC_R, sales_status_life.V_ORIG_CLAIM_STATUS_DESC_R)
        
        else COALESCE(sales_status_disability.V_NEW_CLAIM_STATUS_DESC_R,sales_status_disability.V_ORIG_CLAIM_STATUS_DESC_R,D.V_CLAIM_STATUS_REASON_DESC_R)  end                             V_SALES_CLAIM_STATUS_DESC_R	             
        ,p.V_CURR_CLAIM_STATUS_CODE_R                                                    V_CURR_CLAIM_STATUS_CODE_R	                 
        ,CAST(NULL AS VARCHAR2(100))                                                    V_CLAIM_TYPE_R	                             
        ,CLAIM_TIER_WFAM_MV_TBL.D_CREATED_DATE_R_TIER                                  D_TIER_CREATED_DATE_R	                     
        ,CLAIM_TIER_WFAM_MV_TBL.D_CREATED_DATE_R_WFAM                                    D_WFAM_CODE_CREATED_DATE_R	                 
        ,CLAIM_TIER_WFAM_MV_TBL.V_TIER_R                                                 V_TIER_R	                                 
        ,CLAIM_TIER_WFAM_MV_TBL.V_WFAM_R                                                 V_WFAM_R	                                 
        ,CLAIM_TIER_WFAM_MV_TBL.D_PRD_R                                                      D_PRD_R

,(CLAIM_TIER_WFAM_MV_TBL.D_PRD_R -gd_pacs_as_of_date_r)                                D_PRD_DAYS_REMAINING_R
        
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
        																				V_TIER_DESCRIPTION_R	                     
        ,case when a.v_lob_type_r in ('LIFE', 'NONS', 'WOP')
        then DIM_GRP_REF_TIER_R_life.N_TIER_NUM_R
        else        DIM_GRP_REF_TIER_R_disability.N_TIER_NUM_R  end     				N_TIER_NUM_R

,(case when a.v_lob_type_r in ('LIFE', 'NONS', 'WOP')
          then DIM_GRP_REF_TIER_R_life.V_RECOVERY_EXPECTATIONS_r
          else        DIM_GRP_REF_TIER_R_disability. V_RECOVERY_EXPECTATIONS_r
          end)                                                                             V_RECOVERY_EXPECTATIONS_R
        
        ,DIM_GRP_VOCREHAB_R.V_VOC_REHAB_STATUS_R                                         V_VOC_REHAB_STATUS_R	        
        ,DIM_GRP_VOCREHAB_R.V_VOC_CASE_LASTNAME_R                                        V_VOC_REHAB_MGR_NAME_R	        
        ,DIM_GRP_VOCREHAB_R.V_SPECIALIST_R                                               V_VOC_REHAB_SPECIALIST_R	    
        ,CAST(NULL AS VARCHAR2(100))                                                     V_SERVICE_REQUESTED_OTHER_R
        ,CAST(NULL AS VARCHAR2(100))                                                     V_SERVICE_REQUESTED_R
        ,DIM_GRP_VOCREHAB_R.V_VOC_REHAB_OUTCOME_R                                        V_VOC_REHAB_OUTCOME_R	        
        ,DIM_GRP_VOCREHAB_R.V_REHAB_STATUS_R                                             V_VOC_REHAB_ACTIVE_STATUS_R	
        ,DIM_GRP_VOCREHAB_R.D_TSA_DATE_R                                                 D_TSA_DATE_R	                
        ,C.V_POLICY_NUMBER_R || '-' || q.V_SUBGROUP_ID_R                                 V_LOCATION_NUMBER_R	                      
        ,q.V_CORRESPONDENT_NAME_R                                                        V_CORRESPONDENT_NAME_R
        ,q.V_SUBGROUP_ADDRESSLINE1_R                                                     V_SUBGROUP_ADDRESSLINE1_R
        ,q.V_SUBGROUP_ADDRESSLINE2_R                                                     V_SUBGROUP_ADDRESSLINE2_R
        ,q.V_SUBGROUP_CITY_R                                                             V_SUBGROUP_CITY_R
        ,q.V_SUBGROUP_ID_R                                                               V_SUBGROUP_ID_R	                          
        ,q.V_SUBGROUP_NAME_R                                                             V_SUBGROUP_NAME_R	                          
        ,q.V_SUBGROUP_POSTALZIP_R                                                        V_SUBGROUP_POSTALZIP_R
        ,q.V_SUBGROUP_PROVSTATE_R                                                        V_SUBGROUP_PROVSTATE_R	                       
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

,nvl(TO_DATE(SUBSTR(n.D_START_DATE_R,1,9)),TO_DATE(SUBSTR(m.D_START_DATE_R,1,9)))      D_WORKSHEET_START_DATE_R
        ,nvl(TO_DATE(SUBSTR(n.D_END_DATE_R,1,9))  ,TO_DATE(SUBSTR(m.D_END_DATE_R,1,9))  )      D_WORKSHEET_END_DATE_R
        ,a.v_lob_type_r 
        
        ,A.V_SOURCE_SYSTEM_NAME_R
        ,CAST(NULL AS NUMBER)                                 N_CURR_BENEFIT_PERIOD_DAYS_R
        ,CAST(NULL AS NUMBER)                                 N_TOTAL_BENEFIT_PERIOD_DAYS_R

,s.n_basic_insured_salary_r                           N_BASIC_INSURED_SALARY_R
        ,s.v_basic_insured_salary_ind_r                       V_BASIC_INSURED_SALARY_IND_R

,CAST(NULL AS NUMBER)                                 n_rehab_offset_amt_088_r
        ,CAST(NULL AS NUMBER)                                 v_rehab_offset_ind_088_r
        ,CAST(NULL AS NUMBER)                                 n_workers_comp_offset_amt_083_r
        ,CAST(NULL AS NUMBER)                                 n_other_offset_amt_r
        ,d.v_leave_type_r                                     v_pfl_leave_type_r
        ,d.v_license_num_r                                    v_pfl_license_number_r

,CAST(NULL AS date) d_closed_month_start_date_r
        ,CAST(NULL AS date) d_closed_month_end_date_r

,claim_prior_approved_mv.V_APPEAL_IND_R
        ,claim_prior_approved_mv.V_APPEAL_RESULT_STATUS_CODE_R
        ,claim_prior_approved_mv.D_APPEAL_RESULT_STATUS_CODE_EFF_DATE_R,

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

case when A.V_SOURCE_SYSTEM_NAME_R = 'PACS' and diag.PRIMARY_DIAG_CODE in ('V70', 'V70,.0', 'V70,0','V70.0','V70.7') then 'Wellness'
        when  A.V_SOURCE_SYSTEM_NAME_R = 'PACS' and g.V_CLAIM_COVERAGE_CODE_R = 'VHI' then 'Hospital Indemnity'
        when  A.V_SOURCE_SYSTEM_NAME_R = 'PACS' and  g.V_CLAIM_COVERAGE_CODE_R = 'VAI' then 'Accident'
        when  A.V_SOURCE_SYSTEM_NAME_R = 'PACS' and g.V_CLAIM_COVERAGE_CODE_R = 'VCI' then 'Critical Illness'
        when g.V_CLAIM_COVERAGE_CODE_R in ('VAI', 'VCI', 'VHI') and  A.V_SOURCE_SYSTEM_NAME_R = 'CV' then  d.v_benefittype_r else null end as V_CLAIM_WELLNESS_IND_R   
        
        ,CAST(NULL AS VARCHAR2(1))  V_HAS_ASSOCIATED_WAIVER_IND_R
        ,CAST(NULL AS VARCHAR2(1))  V_HAS_ASSOCIATED_LTD_IND_R   
        
        ,d.V_CLAIM_STATUS_REASON_DESC_R  AS V_CLAIM_STATUS_REASON_DESC_R

,CAST(NULL AS DATE)          D_CLAIM_DECISION_DATE_R 
		,CAST(NULL AS NUMBER)        N_CLAIM_DECISION_DAYS_R 
		,CAST(NULL AS VARCHAR2(300)) V_TURNAROUND_RANGE1_R   
        ,d.V_OVERRIDE_NAME_R
		,d.D_RECORD_START_DATE_R
		,d.D_RECORD_END_DATE_R
		
         from (select * from dim_grp_claim_dir_r where dim_grp_claim_dir_r.V_ACTIVE_STATUS_R = 'Y') a
        left join dim_grp_claim_coverage_r b
        on a.n_claim_sk_r = b.n_claim_sk_r
        and b.v_active_status_r = 'Y'
        left join dim_grp_claim_coverage_group_r g
        on b.n_claim_coverage_sk_r = g.n_claim_coverage_sk_r
        and g.v_active_status_r = 'Y'
		
		left join dim_grp_claim_prior_status_r_approved_mv_ssl claim_prior_approved_mv
		on a.n_claim_sk_r=claim_prior_approved_mv.n_claim_sk_r
		and b.n_claim_coverage_sk_r=claim_prior_approved_mv.n_claim_coverage_sk_r
		and g.n_claim_coverage_group_sk_r=claim_prior_approved_mv.n_claim_coverage_group_sk_r
		
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
        
        left join (

FCT_GRP_POLICY_R_MV_SSL
        		   ) f1
        on c.n_policy_sk_r = f1.n_policy_sk_r
        and c.n_policy_version_number_r = f1.n_version_number_r
        left join FCT_CLAIM_SOCIALSECURITY_INC_R f
        on a.n_claim_sk_r = f.n_claim_sk_r
        left join (

MVW_PRODUCT_SK_LOOKUP_MIN_MV_SSL
        		  ) h
        on h.n_claim_sk_r = a.n_claim_sk_r
        and h.v_claim_coverage_code_r = nvl(b.v_claim_coverage_code_r,g.v_claim_coverage_code_r) 
        left join dim_grp_product_r j
        on h.n_product_sk_r = j.n_product_sk_r
        left join (

MVW_PRODUCT_SK_LOOKUP_MIN_MV_SSL
        		  ) i
        on i.n_claim_sk_r = a.n_claim_sk_r
        and i.v_claim_coverage_code_r = g.v_claim_coverage_code_r
        left join dim_grp_product_r l
        on l.n_product_sk_r = i.n_product_sk_r
        left join FCT_GRP_WORKSHEET m
        on m.n_claim_sk_r = a.n_claim_sk_r
        
        and m.n_claim_coverage_sk_r = b.n_claim_coverage_sk_r
        and m.V_RPT_WORKSHEET_INDICATOR_R  = 'Y'
        left join FCT_GRP_WORKSHEET n
        on n.n_claim_sk_r = a.n_claim_sk_r
        
        and n.n_claim_coverage_group_sk_r = g.n_claim_coverage_group_sk_r 
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
        and q.N_SOURCE_SYSTEM_KEY_R is not null

left outer join (SELECT * FROM DIM_GRP_CLAIM_ELIGIBILITY_R a1
        WHERE a1.v_active_status_r = 'Y'
        and a1.v_source_system_name_r = 'PACS'
        and a1.T_EVENT_TIMESTAMP_R = (select max(b1.T_EVENT_TIMESTAMP_R) from DIM_GRP_CLAIM_ELIGIBILITY_R b1
        where a1.n_claim_sk_r = b1.n_claim_sk_r
        and b1.v_source_system_name_r = 'PACS'
        and b1.v_active_status_r = 'Y')
        ) r
		
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
          left outer join DIM_GRP_EEOC_R x  
          On s.V_EEOC_CODE_R = x.V_CODE_R 
          and x.v_active_status_r = 'Y' 
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
           
                   ) u
                   on u.n_claim_sk_r = a.n_claim_sk_r

left join (
        SELECT DIAG_IND.* FROM dim_grp_medical_diagnosis_r_MV_SSL DIAG_IND
        
        ) diag
        on diag.n_claim_sk_r = a.n_claim_sk_r
        left join
          (
        	SELECT obj.v_claim_number_r,obj.received_date FROM DIM_GRP_BUSOBJ_AUDIT_R_MAX_RCV_MV_SSL	 obj
                                )      received_date
                                on received_date.v_claim_number_r = a.v_claim_number_r

left join (
        SELECT LTD.CLAIM_SK ,LTD.ltd_policy_ind FROM fct_grp_policy_r_LTDPOLIND_MV_SSL LTD
        ) ltd_policy_indicator
        on ltd_policy_indicator.CLAIM_SK = a.N_CLAIM_SK_R
        left join  (
        SELECT  PMNT.v_claim_number_r
           ,  PMNT.N_CLAIM_COVERAGE_GROUP_SK_R,
            PMNT.V_COV_GROUP_ID_R,
            PMNT.Last_Payment_Date, PMNT.earliest_payment_date,
            PMNT.MOST_RECENT_SERVICE_PERIOD_TO_DATE,
            PMNT.MOST_RECENT_SERVICE_PERIOD_FROM_DATE
			,PMNT.EARLIEST_SERVICE_PERIOD_FROM_DATE 
			,PMNT.EARLIEST_SERVICE_PERIOD_TO_DATE   
        	FROM FCT_CLAIM_PAYMENT_DETAIL_R_PMNT_MV_SSL PMNT
             where PMNT.N_CLAIM_COVERAGE_GROUP_SK_R <> -1                          
        ) payment_dates

ON PAYMENT_DATES.v_claim_number_r = A. v_claim_number_r
            And PAYMENT_DATES.N_CLAIM_COVERAGE_GROUP_SK_R  = (case when PAYMENT_DATES.N_CLAIM_COVERAGE_GROUP_SK_R = -1 then -1 else G.N_CLAIM_COVERAGE_GROUP_SK_R end)

left outer join DIM_GRP_SYSUSESO_R T4418483   On upper(T4418483.V_LOGIN_ID_R) = upper(appeal.V_USER_ID_R)

Left join
        (select *   from DIM_GRP_VOCREHAB_R
                      where v_active_status_r = 'Y'
                      and v_source_system_name_r <> 'CV'
                      and n_claim_sk_r <>-1) DIM_GRP_VOCREHAB_R
        on DIM_GRP_VOCREHAB_R.n_claim_sk_r = a.N_CLAIM_SK_R
 		)

where  rank= 1;