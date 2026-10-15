-- Cleaned for lineage: PKG_GRP_LOAD_RPT_EMPLOYEE_R_PRC_INSERT_DUMMY_REC

INSERT  INTO  RPT_EMPLOYEE_R
		   (
		    v_last_modified_by_r
           ,t_creation_date_r
           ,v_created_by_r
           ,t_last_modified_date_r
           ,n_yearmonth_r
           ,v_rpt_active_status_r
           ,n_batch_id_r
		   ,N_EMPLOYEE_SK_R
		   ,N_SALES_REPRESENTATIVE_SK_R
		   ,FIC_MIS_DATE_R
		   ,T_EVENT_TIMESTAMP_R
		   ,n_sequence_number_r
		   )
    VALUES(gc_main_loadedby
		  ,gd_sysdate
		  ,gc_main_loadedby
		  ,gd_sysdate
		  ,gn_current_month
		  ,'Y'
		  ,gn_sysdt_batchid
          ,-1
          ,-1
         ,gd_sysdate
         ,gd_sysdate
		 ,-1
		 );