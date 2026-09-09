-- Cleaned for lineage: PKG_GRP_LOAD_RPT_PAYEE_DTL_R_PRC_GET_CUR_DATA

-- REF CURSOR lineage (OPEN ... FOR SELECT -> INSERT INTO RPT_PAYEE_DTL_R)
INSERT INTO RPT_PAYEE_DTL_R
SELECT
         SEQ_RPT_PAYEE_DTL_R.NEXTVAL N_PAYEE_PARTY_SK_R
        ,V_ADDRESSLINE1_R
        ,V_ADDRESSLINE2_R
        ,V_ADDRESSLINE3_R
        ,V_CITY_R
        ,V_COUNTRY_R
        ,D_BIRTH_DATE_R
        ,V_INDIVIDUAL_FIRST_NAME_R
        ,V_GENDER_R
        ,V_INDIVIDUAL_LAST_NAME_R
        ,(case  when DIM_GRP_PARTY_R.V_TAX_NUMBER_TYPE_R = 'SS#' then DIM_GRP_PARTY_R.V_TAX_NUMBER_R end) V_CLAIM_PAYEE_SSN_R
        ,V_STATE_NAME_R
        ,(case  when DIM_GRP_PARTY_R.V_TAX_NUMBER_TYPE_R = 'TAXID#' then DIM_GRP_PARTY_R.V_TAX_NUMBER_R end) V_CLAIM_PAYEE_TAX_ID_R
        ,V_POSTAL_ZIP_R
        ,V_STATE_CODE_R
        ,gd_sysdate                           V_LAST_MODIFIED_BY_R
        ,gd_sysdate                     T_CREATION_DATE_R
        ,gc_main_loadedby                           V_CREATED_BY_R
        ,gd_sysdate                           T_LAST_MODIFIED_DATE_R
        ,GN_CURRENT_MONTH                     N_YEARMONTH_R
        ,'Y'                                  V_RPT_ACTIVE_STATUS_R
        ,gn_sysdt_batchid                     N_BATCH_ID_R
        ,cast(null as varchar2(20))                                                                v_privacy_indicator_r
        from DIM_GRP_ADDRESS_DIR_R DIM_GRP_ADDRESS_DIR_R
           ,DIM_GRP_PARTY_R DIM_GRP_PARTY_R
		   ,REF_STATE REF_STATE
		WHERE 1=2;