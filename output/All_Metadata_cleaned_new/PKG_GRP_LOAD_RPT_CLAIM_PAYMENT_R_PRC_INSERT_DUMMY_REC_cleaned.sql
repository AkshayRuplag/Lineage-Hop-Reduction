-- Cleaned for lineage: PKG_GRP_LOAD_RPT_CLAIM_PAYMENT_R_PRC_INSERT_DUMMY_REC

INSERT  INTO  RPT_CLAIM_PAYMENT_R
		   (
		    v_last_modified_by_r
           ,t_creation_date_r
           ,v_created_by_r
           ,t_last_modified_date_r
           ,n_yearmonth_r
           ,v_rpt_active_status_r
           ,n_batch_id_r
		   ,N_PAYMENT_SK_R
		      )
		VALUES(gc_main_loadedby
		  ,systimestamp
		  ,gc_main_loadedby
		  ,systimestamp
		  ,gn_current_month
		  ,'Y'
		  ,gn_sysdt_batchid
          ,-1			
		  );