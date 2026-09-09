-- Cleaned for lineage: PKG_GRP_LOAD_RPT_AGENT_R_PRC_INSERT_DUMMY_REC

INSERT  INTO  RPT_AGENT_R
		   ( 
		    v_last_modified_by_r  
           ,t_creation_date_r     
           ,v_created_by_r        
           ,t_last_modified_date_r
           ,N_REPORTMONTH_R
           ,v_rpt_active_status_r
           ,n_batch_id_r
		   ,N_AGENT_SK_R
		   ,N_AGENT_PARTY_SK_R
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
		 );