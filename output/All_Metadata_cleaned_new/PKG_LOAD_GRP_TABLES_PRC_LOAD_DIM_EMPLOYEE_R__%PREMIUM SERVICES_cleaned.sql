-- Cleaned for lineage: %PREMIUM SERVICES

insert into DIM_EMPLOYEE_R_TEMP';

INSERT    INTO ATOMIC.DIM_EMPLOYEE_R_TEMP
			(N_EMPLOYEE_SK_R                       
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
			,( nvl(LN_MAX_SEQ_NUMER_R,0)+rownum)                                 N_SEQUENCE_NUMBER_R
			,N_CLAIM_SK_R
			FROM (SELECT   DISTINCT
			 'Premium Services'                       V_BUSINESS_UNIT_R
			,replace(TRIM(SUBSTR(STG_PBC_RSO_TEAM_R.V_ANALYST_NAME_R,1,INSTR(STG_PBC_RSO_TEAM_R.V_ANALYST_NAME_R,'.')))
		,'.' ) V_EMPLOYEE_FIRST_NAME_R 
			,NULL                                   V_EMPLOYEE_MIDDLE_NAME_R
			,trim(substr(STG_PBC_RSO_TEAM_R.V_ANALYST_NAME_R,instr(STG_PBC_RSO_TEAM_R.V_ANALYST_NAME_R,'.')+1)) V_EMPLOYEE_LAST_NAME_R
			,NULL                                  V_EMPLOYEE_EMAIL_R
			,NULL                                  V_EMPLOYEE_LOGIN_ID_R
			,NULL                                  V_EMPLOYEE_STATUS_R
			,NULL                                  V_SUPERVISOR_FULL_NAME_R
			,NULL                                  V_MANAGER_FULL_NAME_R
			,STG_PBC_RSO_TEAM_R.V_MANAGER_NAME_R   V_DIRECTOR_FULL_NAME_R                
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
			,LT_systimestamp                                                     T_CREATION_DATE_R
			,LT_systimestamp                                                     T_EVENT_TIMESTAMP_R
			,LT_systimestamp                                                     T_LAST_MODIFIED_DATE_R
			,'ODI'                                                               V_CREATED_BY_R
			,'ODI'                                                               V_LAST_MODIFIED_BY_R
			,TRUNC(SYSDATE)                                                      FIC_MIS_DATE_R
			,LN_N_BATCH_ID_R                     								 N_BATCH_ID_R
			,-1 																 N_SALES_REPRESENTATIVE_SK_R
			,NULL                                                                N_CLAIM_SK_R
			FROM ATOMIC.STG_PBC_RSO_TEAM_R
			);

insert into DIM_EMPLOYEE_R_TEMP';