-- Cleaned for lineage: PKG_GRP_LOAD_RPT_PREMIUM_DTL_R_PRC_GET_CUR_DATA

INSERT  INTO RPT_PREMIUM_DTL_R_EXG stg  
    SELECT 
        GN_CURRENT_MONTH                         	AS N_REPORTMONTH_R
       ,n_Inforce_Number_of_Lives_R                	AS N_INFORCE_NUMBER_OF_LIVES_R            
       ,n_Most_Recent_Posted_Number_of_Lives_R     	AS N_MOST_RECENT_POSTED_NUMBER_OF_LIVES_R 
       ,N_Most_Recent_Premium_Posted_Amount_R      	AS N_MOST_RECENT_PREMIUM_POSTED_AMOUNT_R
       ,N_Policy_Billgroup_ID_R                    	AS N_POLICY_BILLGROUP_ID_R
       ,n_Premium_Due_Amount_R                     	AS N_PREMIUM_DUE_AMOUNT_R
       ,n_Premium_Number_of_Lives_R                	AS N_PREMIUM_NUMBER_OF_LIVES_R
       ,n_Premium_Paid_Amount_R                    	AS N_PREMIUM_PAID_AMOUNT_R
       ,n_Premium_Policy_Invoice_ID_R              	AS N_PREMIUM_POLICY_INVOICE_ID_R
       ,n_Premium_Volume_R                         	AS N_PREMIUM_VOLUME_R
       ,n_Premium_Class_ID_R                       	AS N_PREMIUM_CLASS_ID_R
       ,n_Premium_Coverage_ID_R                    	AS N_PREMIUM_COVERAGE_ID_R
       ,n_Net_Premium_ID_R                         	AS N_NET_PREMIUM_ID_R
       ,N_BILLGROUP_SK_R                           	AS N_BILLGROUP_SK_R
       ,N_POLICY_SK_R                              	AS N_POLICY_SK_R
       ,n_cust_party_sk_r                          	AS N_CUST_PARTY_SK_R
       ,N_PRODUCT_SK_R                             	AS N_PRODUCT_SK_R
       ,N_PREMIUM_PAYMENT_ID_R                     	AS N_PREMIUM_PAYMENT_ID_R
       ,gc_getcur_loadedby                          AS V_LAST_MODIFIED_BY_R
       ,systimestamp                                AS T_CREATION_DATE_R
       ,gc_getcur_loadedby                          AS V_CREATED_BY_R
       ,systimestamp                                AS T_LAST_MODIFIED_DATE_R
       ,'Y'                                         AS V_RPT_ACTIVE_STATUS_R
       ,GN_SYSDT_BATCHID                         	AS N_BATCH_ID_R
       ,V_SOURCE_SYSTEM_NAME_R						AS V_SOURCE_SYSTEM_NAME_R
    FROM ATOMIC.RPT_PREMIUM_DTL_R_DRQ_MV_SSL src;