-- Source-concept branch: %SALES (part 2/3)

INSERT  INTO ATOMIC.DIM_EMPLOYEE_R_TEMP
			(
			N_EMPLOYEE_SK_R                       
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
			,NULL                                                                N_CLAIM_SK_R
			FROM ATOMIC.DIM_GRP_SALES_REPRESENTATIVE_R,ATOMIC.DIM_GRP_SALES_REP_LEVEL_R
			,ATOMIC.DIM_GRP_FIELD_OFFICE_R,atomic.STG_RSO_TO_REGION_R
			WHERE Dim_Grp_Sales_Representative_R.n_sales_rep_level_sk_r=Dim_Grp_Sales_Rep_Level_R.n_sales_rep_level_sk_r
			AND Dim_Grp_Sales_Representative_R.n_field_office_sk_r = Dim_Grp_Field_Office_R.n_field_office_sk_r
			AND STG_RSO_TO_REGION_R.V_RSL_LOC_CODE_R =Dim_Grp_Field_Office_R.v_rsl_location_code_r
			AND UPPER(TRIM(DIM_GRP_FIELD_OFFICE_R.V_FIELD_OFFICE_NAME_R)) <> 'INDIANAPOLIS'  
			);