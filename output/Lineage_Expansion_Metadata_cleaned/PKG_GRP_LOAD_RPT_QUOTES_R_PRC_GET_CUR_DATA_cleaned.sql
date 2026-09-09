-- Cleaned for lineage: PKG_GRP_LOAD_RPT_QUOTES_R_PRC_GET_CUR_DATA

INSERT  INTO rpt_quotes_r_exg stg (
      v_assigned_policy_number_r, 
      v_curr_quote_status_r, 
      v_line_of_business_r, 
      d_next_renewal_date_r, 
      d_quote_date_r, 
      v_quote_declined_ind_r, 
      d_quote_effective_date_r, 
      v_quote_number_r, 
      v_exchange_name_r, 
      v_version_status_r,
      d_rated_date_t, 
      v_num_lives_bucket_r, 
      n_version_number_r, 
      n_quote_sk_r, 
      v_last_modified_by_r, 
      t_creation_date_r, 
      v_created_by_r, 
      t_last_modified_date_r, 
      n_yearmonth_r, 
      v_rpt_active_status_r, 
      n_batch_id_r, 
      d_quote_creation_date)
    SELECT  
      ins_quotes.v_policy_number_r          AS v_assigned_policy_number_r,
      ins_quotes.v_current_status_r         AS v_curr_quote_status_r,
      quote_dir.v_line_of_business_r        AS v_line_of_business_r,
      ins_quotes.d_calculated_expiry_date_r AS d_next_renewal_date_r,
      ins_quotes.d_rated_date_r             AS d_quote_date_r,
      CASE
        WHEN upper(ins_quotes.v_current_status_r)= 'DECLINEDQUOTE' 
        THEN 'Y'
        ELSE 'N'
      END AS v_current_status_r,
      quote_dir.t_original_quote_eff_date_r AS d_quote_effective_date_r,
      quote_dir.v_quote_number_r            AS v_quote_number_r,
      ins_quotes.v_memexchange_r            AS v_exchange_name_r,
      ins_quotes.v_current_status_r         AS v_version_status_r,
      ins_quotes.d_rated_date_r             AS d_rated_date_t,
      CASE
        WHEN ins_quotes.n_num_lives_r <= 50   
        THEN '<=50'
        WHEN ins_quotes.n_num_lives_r > 50 AND ins_quotes.n_num_lives_r < 100 
        THEN '50-99'
        WHEN ins_quotes.n_num_lives_r >= 100 AND ins_quotes.n_num_lives_r < 200 
        THEN '100-199'
        WHEN ins_quotes.n_num_lives_r >= 200 AND ins_quotes.n_num_lives_r < 300 
        THEN '200-299'
        WHEN ins_quotes.n_num_lives_r >= 300 AND ins_quotes.n_num_lives_r < 400 
        THEN '300-399'
        WHEN ins_quotes.n_num_lives_r >= 400 AND ins_quotes.n_num_lives_r < 500 
        THEN '400-499'
        WHEN ins_quotes.n_num_lives_r >= 500 AND ins_quotes.n_num_lives_r < 1000 
        THEN '500-999'
        WHEN ins_quotes.n_num_lives_r >= 1000 AND ins_quotes.n_num_lives_r < 2000 
        THEN '1,000-1,999'
        WHEN ins_quotes.n_num_lives_r >= 2000 AND ins_quotes.n_num_lives_r < 5000 
        THEN '2,000-4,999'
        WHEN ins_quotes.n_num_lives_r >= 5000 
        THEN '5,000=>' 
        ELSE 'Unknown'
      END AS v_num_lives_bucket_r,
      quote_dir.n_quote_version_number_r    AS n_version_number_r,
      quote_dir.n_quote_sk_r                AS n_quote_sk_r,
      gc_main_loadedby                      v_last_modified_by_r,
      systimestamp                          t_creation_date_r,
      gc_main_loadedby                      v_created_by_r,
      systimestamp                          t_last_modified_date_r,
      gn_current_month                      n_yearmonth_r,
      quote_dir.v_active_status_r           v_rpt_active_status_r,
      gn_sysdt_batchid                      n_batch_id_r,
      ins_quotes.d_quote_creation_date      AS d_quote_creation_date
    FROM atomic.dim_grp_quote_dir_r quote_dir
    INNER JOIN atomic.fct_insurance_quotes ins_quotes
    ON quote_dir.n_quote_sk_r = ins_quotes.n_quote_sk_r
    AND ins_quotes.n_version_number_r = quote_dir.n_quote_version_number_r
    WHERE quote_dir.v_active_status_r = 'Y';