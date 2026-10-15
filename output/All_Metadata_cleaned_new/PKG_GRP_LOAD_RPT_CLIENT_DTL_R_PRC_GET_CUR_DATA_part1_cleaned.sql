-- Cleaned for lineage: PKG_GRP_LOAD_RPT_CLIENT_DTL_R_PRC_GET_CUR_DATA (part 1/1)

INSERT /*+ APPEND PARALLEL(stg, 8) */ INTO RPT_CLIENT_DTL_R_EXG stg
		SELECT
		DISTINCT
		dim_grp_carrier_r.v_short_name_r                                              v_short_name_r
		,dim_grp_carrier_r.v_carrier_name_r                                           v_carrier_name_r
		,dim_grp_carrier_r.v_source_system_name_r                                     v_carrier_source_system_name_r
		,dim_grp_carrier_r.v_company_code_r                                           v_company_code_r
		,dim_grp_customer_r.v_active_status_r                                         v_active_status_r
		,dim_grp_customer_r.v_customer_number_r                                       v_customer_number_r
		,Case when dim_grp_customer_r.n_national_account_indicator_r = 1
		  THEN 1 else 0 end                                                           n_national_account_indicator_r
		,dim_grp_field_office_r.v_field_office_name_r                                 v_field_office_name_r
		,dim_grp_party_dir_r.v_party_type_r                                           v_party_dir_party_type_r
		,dim_grp_party_dir_r.v_source_system_name_r                                   v_party_dir_source_system_name_r
		,dim_grp_party_dir_r.v_rso_abbrev_r                                           v_rso_abbrev_r
		,dim_grp_party_r.v_primary_email_address_r                                    v_primary_email_address_r
		,/*select distinct case  when upper(T1655484.V_POSITION_TYPE_R) not in ('TERMINATE') and upper(T1655577.V_DESCRIPTION_R) = 'CORRESPONDENT' then concat(concat(T1656493.V_INDIVIDUAL_FIRST_NAME_R, ' '), T1656493.V_INDIVIDUAL_LAST_NAME_R) end  as c1
          from
               (
                    DIM_GRP_PARTY_R T1656493 
					On T1655577.N_CUST_PARTY_SK_R = T1656493.N_PARTY_SK_R and T1655577.N_VERSION_NUMBER_R = T1656493.N_SOURCE_VERSION_NUMBER_R
          T1656493 =  DIM_GRP_PARTY_R
                    T1655577 = DIM_GRP_CORRESPONDENT_R
          T1655484 =  DIM_GRP_ENTITYPOSITIONS_R
          */
        CAST(NULL AS VARCHAR2(100))                                            v_client_correspondent_name_r
		  ,dim_grp_party_r.v_individual_or_org_ind_r                                  v_individual_or_org_ind_r
		  /*
		  CASE WHEN dim_grp_party_r.v_individual_or_org_ind_r = 'O'
		  THEN dim_grp_party_r.v_individual_last_name_r
		  WHEN dim_grp_party_r.v_individual_or_org_ind_r = 'I'
		  THEN dim_grp_party_r.v_individual_first_name_r || ' ' || dim_grp_party_r.v_individual_last_name_r
		  ELSE  NULL
		  END                                                                        v_individual_last_name_r
		  */ 
		,CASE
         WHEN dim_grp_party_r.v_individual_or_org_ind_r = 'O'
         THEN TRIM(dim_grp_party_r.v_individual_last_name_r)
         WHEN dim_grp_party_r.v_individual_or_org_ind_r = 'I'
         THEN TRIM(dim_grp_party_r.v_individual_first_name_r || ' ' || dim_grp_party_r.v_individual_last_name_r)
         ELSE NULL
         END AS v_individual_last_name_r
		 ,CASE  WHEN dim_grp_party_r.v_individual_or_org_ind_r = 'O'
		 THEN dim_grp_party_r.v_master_customer_name_r
         ELSE NULL
		 END                                                                         v_master_customer_name_r
		,dim_grp_party_r.v_master_customer_num_r                                     v_master_customer_num_r
		,dim_grp_party_r.v_party_type_r                                              v_party_type_r
		,dim_grp_party_r.v_source_system_name_r                                      v_source_system_name_r
		,dim_grp_party_r.v_sic_codes_r                                               v_sic_codes_r
		,dim_grp_party_dir_r.n_party_sk_r                                            n_cust_party_sk_r
		,fct_grp_party_address_r_main.v_address_type_r                               v_address_type_r
		,fct_grp_party_address_r_main.v_party_type_r                                 v_party_address_party_type_r
		,fct_grp_party_address_r_main.v_addressline1_r                               v_addressline1_r
		,fct_grp_party_address_r_main.v_addressline2_r                               v_addressline2_r
		,fct_grp_party_address_r_main.v_city_r                                       v_city_r
		,fct_grp_party_address_r_main.v_country_r                                    v_country_r
		,fct_grp_party_address_r_main.v_state_name_r                                 v_client_state_main_r
		,fct_grp_party_address_r_main.v_postal_zip_r                                 v_client_zip_code_r
		,fct_grp_party_address_r_situs.v_state_name_r                                v_situs_state_r
		,fct_grp_party_address_r_main.v_location_id_r                                v_location_id_r
		,fct_grp_party_address_r_main.n_primary_location_r                           n_primary_location_r
		,dim_grp_party_r.v_sic_category_r                                            v_sic_category_r
		,dim_grp_party_r.v_sic_desc_r                                                v_sic_desc_r
		,dim_grp_customer_r.v_id_code_r                                              v_client_id_r
		,CAST(NULL AS VARCHAR2(100))                                                      v_master_customer_state_r 
		,OV_NSOCONTACT_R.V_NSO_DESCRIPTION_R                                       V_NSO_CONTACT_NAME_R
		,fct_grp_party_address_r_situs.v_addressline1_r                              v_situs_address_line1_r
		,fct_grp_party_address_r_situs.v_addressline2_r                              v_situs_address_line2_r
        ,fct_grp_party_address_r_situs.v_city_r                                      v_situs_city_r
		,fct_grp_party_address_r_situs.v_postal_zip_r                                v_situs_zip_code_r
		,dim_grp_party_r.v_ieb_ind_r                                                 v_ieb_type_r
		,gc_main_loadedby                                                            v_last_modified_by_r
		,gd_sysdate                                                                  t_creation_date_r
		,gc_main_loadedby                                                            v_created_by_r
		,gd_sysdate                                                                  t_last_modified_date_r
		,gn_current_month                                                            n_yearmonth_r
		,dim_grp_party_dir_r.v_active_status_r                                       v_rpt_active_status_r
		,gn_sysdt_batchid                                                            n_batch_id_r
		,stg_rso_to_region_r.v_regional_avp_name_r                                   v_regional_avp_name_r        
		,stg_rso_to_region_r.v_regional_vp_group_r                                   v_regional_vp_group_r        
		,stg_rso_to_region_r.v_regional_vp_name_r                                    v_regional_vp_name_r         
		,stg_rso_to_region_r.v_regional_vp_title_r                                   v_regional_vp_title_r        
		,dim_grp_field_office_r.v_code_r                                             v_rso_code_r                 
		,dim_grp_field_office_r.v_rsl_location_code_r                                v_rso_location_code_r        
		,dim_grp_field_office_r.v_field_office_name_r                                v_rso_name_r                 
		,dim_grp_field_office_r.v_regional_office_number_r                           v_rso_number_r               
		,stg_rso_to_region_r.v_region_name_r                                         v_rso_region_name_r          
		,stg_rso_to_region_r.v_region_short_name_r                                   v_rso_region_short_name_r    
		,(case  when dim_grp_customer_r.V_SSN_FEIN_INDICATOR_R = 'FEIN'
		  then LPAD(dim_grp_customer_r.N_FEDERAL_EMPLOYER_NO_R, 9, '0')
		  else null
		  end
		  )                                                                          V_EMPLOYER_TAX_ID_R 
		  ,T1011891.V_MSA_R                                           v_customer_msa_code_r
		  ,T1011891.V_MSA_NAME_R                                        v_customer_msa_name_r
		FROM
		atomic.dim_grp_party_dir_r  dim_grp_party_dir_r
		INNER JOIN atomic.dim_grp_party_r  dim_grp_party_r
		ON dim_grp_party_dir_r.n_party_sk_r = dim_grp_party_r.n_party_sk_r
		AND dim_grp_party_dir_r.n_source_version_number_r = dim_grp_party_r.n_source_version_number_r
		INNER JOIN atomic.dim_grp_customer_r  dim_grp_customer_r
		ON dim_grp_customer_r.n_cust_party_sk_r = dim_grp_party_dir_r.n_party_sk_r
		LEFT JOIN atomic.dim_grp_carrier_r  dim_grp_carrier_r
		ON dim_grp_carrier_r.n_carrier_sk_r = dim_grp_customer_r.n_carrier_sk_r
		AND dim_grp_carrier_r.v_active_status_r = 'Y'
		LEFT JOIN atomic.dim_grp_field_office_r  dim_grp_field_office_r
		ON dim_grp_field_office_r.v_code_r = dim_grp_party_dir_r.v_rso_abbrev_r
		AND dim_grp_field_office_r.v_active_status_r = 'Y'
		LEFT JOIN (SELECT *
					 FROM atomic.fct_grp_party_address_r
					WHERE v_location_id_r = 'MAIN'
					  AND v_party_type_r = 'CUSTOMER'
				  ) fct_grp_party_address_r_main
		ON fct_grp_party_address_r_main.n_party_sk_r = dim_grp_party_dir_r.n_party_sk_r
		AND fct_grp_party_address_r_main.n_source_version_number_r = dim_grp_party_dir_r.n_source_version_number_r
		left join atomic.stg_rso_to_region_r
        on stg_rso_to_region_r.v_rsl_loc_code_r = dim_grp_field_office_r.v_rsl_location_code_r
        and  dim_grp_field_office_r.v_active_status_r = 'Y'
		LEFT JOIN (SELECT *
					 FROM atomic.fct_grp_party_address_r  z
					WHERE z.v_location_id_r = 'Situs'
					  AND z.v_party_type_r = 'CUSTOMER'
					  AND z.n_source_version_seq_number_r = (SELECT MAX(N_SOURCE_VERSION_SEQ_NUMBER_R)
															   FROM atomic.fct_grp_party_address_r  y
															  WHERE z.n_party_sk_r = y.n_party_sk_r
																AND y.V_LOCATION_ID_R = 'Situs'
																AND y.V_PARTY_TYPE_R = 'CUSTOMER'
																AND z.N_SOURCE_VERSION_NUMBER_R = y.N_SOURCE_VERSION_NUMBER_R)
															) fct_grp_party_address_r_situs
		ON fct_grp_party_address_r_situs.n_party_sk_r = dim_grp_party_dir_r.n_party_sk_r
		AND fct_grp_party_address_r_situs.n_source_version_number_r = dim_grp_party_dir_r.n_source_version_number_r
		left outer join atomic.STG_CMSA_R  T1011891 /* D_CMSA_INSURED */  On T1011891.v_zip_code_r = substr(fct_grp_party_address_r_situs.V_POSTAL_ZIP_R , 1 , 5)
		LEFT JOIN (Select * from ATOMIC.DIM_GRP_NSOCONTACT_R  A where  A.V_ACTIVE_STATUS_R = 'Y'
		and n_source_version_seq_number_r = (select max(n_source_version_seq_number_r)
		from ATOMIC.DIM_GRP_NSOCONTACT_R  B where B.V_ACTIVE_STATUS_R = 'Y'
		and  A.N_CUST_PARTY_SK_R = B.N_CUST_PARTY_SK_R and A.N_VERSION_NUMBER_R = B.N_VERSION_NUMBER_R )) OV_NSOCONTACT_R
        ON dim_grp_party_dir_r.n_party_sk_r = OV_NSOCONTACT_R.N_CUST_PARTY_SK_R
        AND dim_grp_party_dir_r.n_source_version_number_r = OV_NSOCONTACT_R.N_VERSION_NUMBER_R
		and OV_NSOCONTACT_R.V_ACTIVE_STATUS_R = 'Y'
		WHERE dim_grp_party_dir_r.v_active_status_r = 'Y'
		AND dim_grp_party_r.v_active_status_r = 'Y'
		AND dim_grp_customer_r.v_active_status_r = 'Y'
		AND dim_grp_party_dir_r.v_party_type_r = 'CUSTOMER'
		AND dim_grp_party_dir_r.v_source_system_name_r = 'PACS'
		;
	gn_run_cnt := SQL%ROWCOUNT;
	COMMIT;
    EXECUTE IMMEDIATE 'ALTER SESSION DISABLE PARALLEL DML';
	gv_trcmsg       := '5.2 - Exit from prc_get_cur_data - Rows Loaded :->'||gn_run_cnt;
	gt_end_time_r 	:= SYSTIMESTAMP;
	/*START: NEW LOGGING MECHANISM CHANGES*/
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
				( p_job_id_r                    => gn_out_job_id
				 ,p_batch_id_r                  => gn_sysdt_batchid
				 ,p_message_type_r              => gv_message_type
				 ,p_code_location_r             => gc_main_loadedby
				 ,p_message_r                   => gv_trcmsg
				 ,p_count_type_r                => 'AUDIT_TARGET_COUNT'
				 ,p_count_r                     => gn_run_cnt
				 ,p_duration_r                  => FNC_GRP_TIME_DURATION(gt_start_time_r,gt_end_time_r)
				 ,p_created_by_r                => gc_job_name
				 ,out_prcs_job_log_message_id_r => gn_job_log_message_id
				);
END prc_get_cur_data;