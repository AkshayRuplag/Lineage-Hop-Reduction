-- Cleaned for lineage: PKG_GRP_LOAD_RPT_EMPLOYEE_R_PRC_GET_CUR_DATA

-- REF CURSOR lineage (OPEN ... FOR SELECT -> INSERT INTO RPT_EMPLOYEE_R)
INSERT INTO RPT_EMPLOYEE_R
SELECT
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
        ,gd_sysdate                           FIC_MIS_DATE_R
        ,gn_sysdt_batchid                     N_BATCH_ID_R
        ,N_SEQUENCE_NUMBER_R
        ,gd_sysdate                           T_CREATION_DATE_R
        ,gd_sysdate                           T_EVENT_TIMESTAMP_R
        ,gd_sysdate                           T_LAST_MODIFIED_DATE_R
        ,gc_main_loadedby                     V_CREATED_BY_R
        ,gc_main_loadedby                     V_LAST_MODIFIED_BY_R
        ,N_SALES_REPRESENTATIVE_SK_R
        ,N_CLAIM_SK_R
        ,V_PRIVACY_INDICATOR_R
        ,V_EMPLOYEE_FULL_NAME_R
        ,GN_CURRENT_MONTH                     N_YEARMONTH_R
        ,'Y'                                  V_RPT_ACTIVE_STATUS_R
        from ATOMIC.DIM_EMPLOYEE_R;