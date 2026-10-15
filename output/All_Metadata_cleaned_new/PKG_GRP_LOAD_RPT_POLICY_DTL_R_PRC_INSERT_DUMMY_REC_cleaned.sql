-- Cleaned for lineage: PKG_GRP_LOAD_RPT_POLICY_DTL_R_PRC_INSERT_DUMMY_REC

INSERT  INTO  RPT_POLICY_DTL_R
               (
                v_last_modified_by_r
               ,t_creation_date_r
               ,v_created_by_r
               ,t_last_modified_date_r
               ,n_yearmonth_r
               ,v_rpt_active_status_r
               ,n_batch_id_r
               ,n_policy_sk_r
               ,N_CUST_PARTY_SK_R
               ,N_QUOTE_SK_R
               )
        VALUES(GV_MAIN_LOADEDBY
              ,systimestamp
              ,GV_MAIN_LOADEDBY
              ,systimestamp
              ,gn_current_month
              ,'Y'
              ,gn_sysdt_batchid
              ,-1           
              ,-1   
              ,-1  
              );