-- Cleaned for lineage: PKG_GRP_LOAD_RPT_QUOTES_R_PRC_INSERT_DUMMY_REC

INSERT  INTO atomic.rpt_quotes_r(
      v_last_modified_by_r,
      t_creation_date_r,
      v_created_by_r,
      t_last_modified_date_r,
      n_yearmonth_r,
      v_rpt_active_status_r,
      n_batch_id_r,
      n_quote_sk_r)
    VALUES(
      gc_main_loadedby,
      gd_sysdate,
      gc_main_loadedby,
      gd_sysdate,
      gn_current_month,
      'Y',
      gn_sysdt_batchid,
      - 1
    );