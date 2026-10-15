-- Cleaned for lineage: PKG_GRP_LOAD_RPT_GRP_PRODUCT_R_PRC_GET_CUR_DATA

INSERT  INTO RPT_GRP_PRODUCT_R_EXG stg
	SELECT 
		 N_PRODUCT_SK_R
		,V_PRODUCT_LINE_R
		,V_PRODUCT_LINE_DESC_R
		,V_PRODUCT_SUB_LINE_CODE_R
		,V_PRODUCT_SUB_LINE_DESC_R
		,V_BASIC_PRODUCT_LINE_CODE_R
		,V_BASIC_PRODUCT_LINE_DESC_R
		,V_COVERAGE_TYPE_CODE_R
		,V_COVERAGE_TYPE_DESC_R
		,V_COVERAGE_CATEGORY_R
		,V_COVERAGE_CODE_R
		,V_COVERAGE_DESC_R
        ,gd_sysdate                           FIC_MIS_DATE_R
        ,gn_sysdt_batchid                     N_BATCH_ID_R
		,N_SEQUENCE_NUMBER_R
        ,gd_sysdate                           T_CREATION_DATE_R
        ,gd_sysdate                           T_EVENT_TIMESTAMP_R
        ,gd_sysdate                           T_LAST_MODIFIED_DATE_R
        ,gc_main_loadedby                     V_CREATED_BY_R
        ,gc_main_loadedby                     V_LAST_MODIFIED_BY_R
		,V_SOURCE_SYSTEM_NAME_R
		,V_SUBJECT_AREA_TYPE_R
		,N_VERSION_NUMBER_R
		,D_RECORD_START_DATE_R
		,D_RECORD_END_DATE_R
		,F_PHYSICAL_DELETE_R
		,V_CHANGE_REASON_R
		,V_ACTIVE_STATUS_R
		,N_CLAIM_SK_R
		,N_POLICY_SK_R
		,N_PARTY_SK_R
		,N_QUOTE_SK_R
		,V_PRIVACY_INDICATOR_R
        ,gn_current_month                     N_YEARMONTH_R
        ,'Y'                                 V_RPT_ACTIVE_STATUS_R
        ,cast(null as varchar2(100)) V_COVERAGE_TYPE_IND_R
		,(CASE
        WHEN V_COVERAGE_TYPE_CODE_R = '1' THEN
            'LTD'
        WHEN V_COVERAGE_TYPE_CODE_R = '2' THEN
            'STD'
        WHEN V_COVERAGE_TYPE_CODE_R  = '3' THEN
            'Life'
        end) V_COVERAGE_TYPE_R
        from atomic.DIM_GRP_PRODUCT_R;