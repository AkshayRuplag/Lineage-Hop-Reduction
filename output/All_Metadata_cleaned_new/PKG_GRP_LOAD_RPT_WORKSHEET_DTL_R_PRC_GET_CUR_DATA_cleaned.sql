-- Cleaned for lineage: PKG_GRP_LOAD_RPT_WORKSHEET_DTL_R_PRC_GET_CUR_DATA

-- REF CURSOR lineage (OPEN ... FOR SELECT -> INSERT INTO RPT_WORKSHEET_DTL_R)
INSERT INTO RPT_WORKSHEET_DTL_R
select
          SEQ_RPT_WORKSHEET_DTL_R.NEXTVAL                            N_WORKSHEET_SK_R  
         ,FCT_GRP_WORKSHEET.N_GROSS_BENEFIT_R                        N_GROSS_BENEFIT_R
         ,FCT_GRP_WORKSHEET.N_RPT_NET_BENEFIT_R                      N_WS_NET_BENEFIT_R
         ,FCT_GRP_WORKSHEET.V_RPT_WORKSHEET_INDICATOR_R              V_WORKSHEET_INDICATOR_R
         ,FCT_GRP_WORKSHEET.N_VERSION_R                              N_WORKSHEET_NUMBER_R
         ,TO_DATE(SUBSTR(FCT_GRP_WORKSHEET.D_START_DATE_R,1,9))      D_WORKSHEET_START_DATE_R
         ,FCT_GRP_WORKSHEET.V_WORKSHEET_STATUS_R                     V_WORKSHEET_STATUS_R
         ,FCT_GRP_WORKSHEET.N_WORKSHEET_SEQ_NBR_OBJECTNM_R           N_WORKSHEET_SEQ_NBR_OBJECTNM_R
         ,TO_DATE(SUBSTR(FCT_GRP_WORKSHEET.D_END_DATE_R,1,9))        D_WORKSHEET_END_DATE_R
 		,gc_main_loadedby                                            v_last_modified_by_r
		
		,gd_sysdate                                                  t_creation_date_r
		,gc_main_loadedby                                            v_created_by_r
		,gd_sysdate                                                  t_last_modified_date_r
		,gn_current_month                                            n_yearmonth_r
		,'Y'                                                         v_rpt_active_status_r
		,gn_sysdt_batchid                                            n_batch_id_r
		,n_worksheet_src_sys_key_r                                   n_worksheet_src_sys_key_r
       from FCT_GRP_WORKSHEET FCT_GRP_WORKSHEET
        where FCT_GRP_WORKSHEET.V_RPT_WORKSHEET_INDICATOR_R = 'Y';