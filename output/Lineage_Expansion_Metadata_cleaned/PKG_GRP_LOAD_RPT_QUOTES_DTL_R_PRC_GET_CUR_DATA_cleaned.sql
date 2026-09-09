-- Cleaned for lineage: PKG_GRP_LOAD_RPT_QUOTES_DTL_R_PRC_GET_CUR_DATA

INSERT  INTO rpt_quotes_dtl_r_exg stg (
      n_quote_amount_r, 
      n_num_lives_r, 
      n_quote_share_r, 
      n_sold_ann_prem_amount_r, 
      n_agent_sk_r, 
      n_version_number_r, 
      n_cust_party_sk_r, 
      n_agent_party_sk_r, 
      n_quote_sk_r, 
      v_last_modified_by_r, 
      t_creation_date_r, 
      v_created_by_r, 
      t_last_modified_date_r, 
      n_yearmonth_r, 
      v_rpt_active_status_r, 
      n_batch_id_r)
    SELECT  
      n_quote_amount_r,
      n_num_lives_r,
      n_quote_share_r,
      n_sold_ann_prem_amount_r,
      n_agent_sk_r,
      n_version_number_r,
      n_cust_party_sk_r,
      n_agent_party_sk_r,
      n_quote_sk_r,
      gc_main_loadedby v_last_modified_by_r,
      systimestamp       t_creation_date_r,
      gc_main_loadedby v_created_by_r,
      systimestamp       t_last_modified_date_r,
      gn_current_month n_yearmonth_r,
      'Y'              v_rpt_active_status_r,
      gn_sysdt_batchid n_batch_id_r
    FROM atomic.rpt_quotes_dtl_r_mv_ssl;