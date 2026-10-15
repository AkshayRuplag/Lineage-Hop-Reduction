-- Cleaned for lineage: PKG_GRP_LOAD_RPT_CLIENT_DTL_R_PRC_UPD_DEL_DATA

UPDATE rpt_client_dtl_r
	   SET v_rpt_active_status_r='N'
	      ,v_last_modified_by_r=gc_updby
	      ,t_last_modified_date_r=gd_sysdate
	WHERE n_yearmonth_r = ln_fisc_prior_month;