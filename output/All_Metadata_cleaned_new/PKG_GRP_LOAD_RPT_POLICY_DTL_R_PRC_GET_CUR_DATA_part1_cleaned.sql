-- Cleaned for lineage: PKG_GRP_LOAD_RPT_POLICY_DTL_R_PRC_GET_CUR_DATA (part 1/1)

INSERT  INTO RPT_POLICY_DTL_R_EXG stg
     SELECT 
	   fct_grp_policy_r.v_administered_by_r                                            AS v_administered_by_r
	 , CASE
	      WHEN UPPER(fct_grp_policy_r.v_brand_name_r) = 'ALEAVEIATE'
		  THEN 'YES'
		  ELSE  NULL
	    END                                                                                 AS v_aleaveiate_ind_r
	 , fct_grp_billing_policy_dtl_r.d_installation_date_r                                   AS d_billing_installation_date_r
	 , fct_grp_policy_r.v_memblock_r                                                        AS v_block_name_r
	 , CASE
	      WHEN nvl(fct_grp_billing_policy_dtl_r.N_CREATE_BILL_R, 0) <> 0
		  THEN 'Yes'
		END                                                                                 AS v_create_bill_ind_r
	 , fct_grp_policy_r.n_num_lives_r                                                       AS n_eligible_num_lives_r
	 , FCT_GRP_POLICY_R.V_MEMEXCHANGE_R                                                     AS V_EXCHANGE_NAME_R
	 , to_date(dim_grp_policy_dir_r.fic_mis_date_r)                                         AS FIC_MIS_DATE_R
	 , dim_grp_policy_dir_r.v_policy_suffix_r v_line_of_business_r
     , CASE
	       WHEN v_policy_prefix_r IN ('STD','TDB','TDI','DBL', 'VPS', 'ASW', 'MAL', 'CTL', 'ORL', 'COL')
		   THEN 'Weekly Income'
           WHEN dim_grp_policy_dir_r.v_policy_prefix_r IN ('VLT', 'LTD', 'VPL', 'VIP', 'ASL', 'FML', 'MSF')
		   THEN 'LTD'
           WHEN dim_grp_policy_dir_r.v_policy_prefix_r IN ('VG')
		   THEN 'VGTL'
           WHEN dim_grp_policy_dir_r.v_policy_prefix_r IN ('GL', 'GGL', 'SPG')
		   THEN 'Group Life'
           WHEN dim_grp_policy_dir_r.v_policy_prefix_r IN ('SR', 'VAR', 'VAI', 'VCI', 'VHI')
		   THEN 'Personal Accident'
           WHEN dim_grp_policy_dir_r.v_policy_prefix_r IN ('DEN', 'VIS')
		   THEN 'Dental/Vision'
           WHEN dim_grp_policy_dir_r.v_policy_prefix_r IN ('BCD', 'BCL', 'BCM', 'BCS', 'BSC')
		   THEN 'Basic Care'
	    END                                                                                  AS v_line_of_business_group_r
	  , CASE
	       WHEN fct_grp_policy_r.V_SOURCE_SYSTEM_NAME_R = 'EIS'
		   THEN fct_grp_policy_r.d_renewal_date_r
           ELSE FCT_GRP_POLICY_R.D_CALCULATED_EXPIRY_DATE_R
          END 																				 AS d_next_renewal_date_r
	  , CASE
	       WHEN dim_grp_udfield_r.v_field2_r = 1
		   THEN 'Y'
		   ELSE 'N'
		 END     																			 AS v_nsc_indicator_r
	  , dim_grp_policy_dir_r.v_orig_lob_r                                    		         AS v_orig_lob_r
	  , FCT_GRP_POLICY_R.N_PARTICIPATING_NUM_LIVES_R                                         AS N_PARTICIPATING_NUM_LIVES_R
      , CASE
	        WHEN fct_grp_policy_r.n_participating_num_lives_r IS NULL
			THEN 'Blank'
		    WHEN fct_grp_policy_r.n_participating_num_lives_r < 100
			THEN '<100'
            WHEN fct_grp_policy_r.n_participating_num_lives_r < 500
			THEN '100-500'
			WHEN fct_grp_policy_r.n_participating_num_lives_r < 2000
			THEN '500-2000'
			ELSE '>=2000'
		  END                                                                                 AS v_participating_num_lives_bucket_r
		, fct_grp_transactions_r.v_visualid_r                                                 AS v_policy_visual_id_r
		, fct_grp_policy_r.v_anniversary_date_and_month_r                                     AS v_policy_anniversary_date_r
		, FCT_GRP_BILLING_POLICY_DTL_R.V_BILL_CATEGORY_R                                      AS V_BILL_CATEGORY_R
		, TO_CHAR(fct_grp_billing_policy_dtl_r.n_billing_option_value_r)                      AS v_bill_option_r
        , CASE
		     WHEN fct_grp_policy_r.v_smartchoice_ind_r = 'Y'
			 THEN 'Smart Choice'
             WHEN fct_grp_policy_r.n_policy_lives_r < 100
			 THEN '<100'
             WHEN fct_grp_policy_r.n_policy_lives_r BETWEEN 100 AND 299
			 THEN '100-299'
             WHEN fct_grp_policy_r.n_policy_lives_r BETWEEN 300 AND 499
			 THEN '300-499'
             WHEN fct_grp_policy_r.n_policy_lives_r BETWEEN 500 AND 999
			 THEN '500-999'
             WHEN fct_grp_policy_r.n_policy_lives_r BETWEEN 1000 AND 1999
			 THEN '1,000-1,999'
             WHEN fct_grp_policy_r.n_policy_lives_r BETWEEN 2000 AND 2999
			 THEN '2,000-2,999'
             WHEN fct_grp_policy_r.n_policy_lives_r BETWEEN 3000 AND 4999
			 THEN '3,000-4,999'
             WHEN fct_grp_policy_r.n_policy_lives_r >= 5000
             THEN '5,000+'
             ELSE 'Blank'
		   END                                                                                 AS v_policy_case_size_r
		 , CASE
		      WHEN fct_grp_policy_r.n_policy_lives_r < 500
			  THEN '<500'
		      WHEN fct_grp_policy_r.n_policy_lives_r BETWEEN 500 AND 1999
			  THEN '500-1,999'
		      WHEN fct_grp_policy_r.n_policy_lives_r >= 2000
			  THEN '2,000+'
		    END                                                                                AS v_policy_case_size_group_r
		, dim_grp_policy_dir_r.n_policy_sk_r                                                   AS n_policy_count_r
		, CASE  WHEN DIM_GRP_POLICY_DIR_R.V_SOURCE_SYSTEM_NAME_R ='EIS'
				THEN NVL(CAST(POLICY_DIR_EFF_DATE.T_POLICY_EFFECTIVE_DATE_R_1 AS DATE),
						CAST(POLICY_DIR_EFF_DATE.T_POLICY_EFFECTIVE_DATE_R_0 AS DATE))
				ELSE
				CAST(DIM_GRP_POLICY_DIR_R.T_POLICY_EFFECTIVE_DATE_R AS DATE)
		  END
          AS D_POLICY_EFFECTIVE_DATE_R
        , EXTRACT( YEAR  FROM dim_grp_policy_dir_r.t_policy_effective_date_r)                  AS v_policy_effective_year_r
		, fct_grp_policy_r.d_installation_date_r                                               AS d_policy_installation_date_r
		, dim_grp_policy_dir_r.v_policy_prefix_r                                               AS v_policy_prefix_r
        , CASE
		     WHEN UPPER(fct_grp_transactions_r.v_bus_obj_status_r) LIKE '%TERMINATED%'
		 	 THEN 'Cancelled'
		 	 ELSE 'Active'
		   END                                                                                 AS v_policy_status_r
		, DIM_GRP_POLICY_DIR_R.V_POLICY_SUFFIX_R                                               AS V_POLICY_SUFFIX_R
        , CASE
      		WHEN LENGTH(CASE
							WHEN FCT_GRP_TRANSACTIONS_R.V_BUS_OBJ_STATUS_R IN('BOUNDTERMINATE', 'TERMINATED', 'CANCELREINSTATE')
							THEN FCT_GRP_TRANSACTIONS_R.D_EFFECTIVE_R
							ELSE  NULL
		                END
					   ) > 0
	        THEN 'T'
            ELSE ' '
          END                                                                                  AS v_policy_terminated_ind_r
        , CASE
		      WHEN fct_grp_transactions_r.v_bus_obj_status_r IN ('BOUNDTERMINATE', 'TERMINATED', 'CANCELREINSTATE')
		      THEN fct_grp_transactions_r.d_effective_r
			  ELSE  NULL
		   END 		                                                                           AS d_policy_termination_date_r
        , CASE
		      WHEN fct_grp_transactions_r.v_bus_obj_status_r IN ('BOUNDTERMINATE', 'TERMINATED', 'CANCELREINSTATE')
		      THEN fct_grp_policy_r.v_version_reason_code_r
			  ELSE  NULL
		   END 		                                                                           AS v_policy_termination_reason_r
        , CASE
		      WHEN dim_grp_policy_dir_r.v_policy_prefix_r = 'SC'
		      THEN 'IND'
			  ELSE 'GRP'
		   END                                                                                 AS v_policy_type_r
		, dim_grp_policy_dir_r.n_policy_sk_r                                                   AS n_policy_sk_r
		, fct_grp_billing_policy_dtl_r.n_policy_id_r                                           AS n_policy_id_r
		, dim_grp_policy_dir_r.v_policy_number_r                                               AS v_policy_number_r
		, fct_grp_billing_policy_dtl_r.v_policy_status_r                                       AS v_prem_policy_status_r
		, fct_grp_policy_r.n_claims_tax_indicator_r                                            AS n_claims_tax_indicator_r
		, fct_grp_policy_r.v_ratebook_desc_r                                                   AS v_ratebook_desc_r
		, fct_grp_policy_r.v_ratebook_id_r                                                     AS v_ratebook_id_r
		, fct_grp_policy_r.n_renewal_notification_days_r                                       AS n_renewal_notification_days_r
		, fct_grp_policy_r.v_rewrite_indicator_r                                               AS v_rewrite_indicator_r
        , CASE
		     WHEN UPPER(fct_grp_policy_r.v_line_of_business_r) LIKE '%SMALL%'
		     THEN 'Y'
			 ELSE 'N'
		   END 		                                                                           AS v_small_group_ind_r
		, fct_grp_policy_r.v_smartchoice_ind_r                                                 AS v_smartchoice_ind_r
		, dim_grp_policy_dir_r.v_source_system_name_r                                          AS v_source_system_name_r
		, fct_grp_transactions_r.v_originated_from_r                                           AS v_source_version_r
		, fct_grp_policy_r.t_effective_start_date_r                                            AS d_version_effective_date_r
		, fct_grp_policy_r.n_version_number_r                                                  AS n_version_number_r
		, fct_grp_transactions_r.v_bus_obj_status_r                                            AS v_version_status_r
		, fct_grp_transactions_r.v_version_type_r                                              AS v_version_type_r
		, fct_grp_policy_r.n_w2_exclude_fica_match_r                                           AS n_w2_exclude_fica_match_r
		, dim_grp_policy_dir_r.n_batch_id_r                                                    AS n_batch_id_r
		, fct_grp_policy_r.n_cust_party_sk_r                                                   AS n_cust_party_sk_r
		, dim_grp_udfield_r.n_entity_type_id_r                                                 AS n_ud_entity_type_id_r
		, dim_grp_policy_dir_r.d_delete_date_r                                                 AS d_policy_delete_date_r
		, fct_grp_transactions_r.t_event_timestamp_r                                           AS t_transaction_event_timestamp_r
		, fct_grp_policy_r.v_policy_coverage_code_r                                            AS v_policy_coverage_code_r
		, dim_grp_policy_dir_r.n_quote_sk_r                                                    AS n_quote_sk_r
		, fct_grp_billing_policy_dtl_r.d_delete_date_r                                         AS d_billing_policy_delete_date_r
		, fct_grp_policy_r.n_policy_lives_r                                                    AS v_policy_case_size_2_r
        , GV_MAIN_LOADEDBY                                                                     AS v_last_modified_by_r
        , systimestamp                                                                         AS t_creation_date_r
        , GV_MAIN_LOADEDBY                                                                     AS v_created_by_r
        , systimestamp                                                                         AS t_last_modified_date_r
        , gn_current_month                                                                     AS n_yearmonth_r
	    , dim_grp_policy_dir_r.v_active_status_r                                               AS v_rpt_active_status_r
	    , fct_grp_policy_r.v_class_of_business_r                                               AS v_class_of_business_r
	    , fct_grp_policy_r.n_policy_lives_r                                                    AS n_policy_lives_r
        , nvl( fct_grp_policy_r.v_carrier_name_r  ,
		        (case
				    when fct_grp_policy_r.v_administered_by_r = 'RSL'
				    then 'Reliance Standard Life Insurance Company'
					when fct_grp_policy_r.v_administered_by_r = 'FRSLIC'
					then 'First Reliance Standard Life Insurance Company'
                    else null
					end
			     )
			  )	                                                                               AS v_carrier_name_r
		, CAST(NULL AS DATE)                                                                   AS D_UW_NEXT_RENEWAL_DATE_R
        , CAST(NULL AS VARCHAR2(300 CHAR))                                                     AS V_UW_NEEDED_UNDERWRITER_NAME_R
        , CAST(NULL AS VARCHAR2(300 CHAR))                                                     AS V_UW_NEEDED_COMMENTS_R
        , CAST(NULL AS NUMBER)                                                                 AS N_UW_NEEDED_PERCENT_R
        , CAST(NULL AS VARCHAR2(300 CHAR))                                                     AS V_UW_NEEDED_RENEWAL_STATUS_R
        , CAST(NULL AS NUMBER)                                                                 AS N_UW_REQUESTED_PERCENT_R
        , fct_grp_policy_r.d_renewal_date_r                                                    AS D_RENEWAL_DATE_R
        , CAST(NULL AS VARCHAR2(300 CHAR))                                                     AS V_UW_TRK_NEEDED_UW_NAME_R
        , CAST(NULL AS VARCHAR2(300 CHAR))                                                     AS V_UW_TRK_NEEDED_COMMENTS_R
        , CAST(NULL AS NUMBER)                                                                 AS N_UW_TRK_NEEDED_PERCENT_R
        , CAST(NULL AS VARCHAR2(300 CHAR))                                                     AS V_UW_TRK_NEEDED_RENEW_STATUS_R
        , CAST(NULL AS NUMBER)                                                                 AS N_UW_TRK_REQUESTED_PERCENT_R
		, CAST(NULL AS VARCHAR2(300))                                                          AS V_CLIENT_NAME_R
		, CAST(NULL AS VARCHAR2(50))                                                           AS v_prs_strs_ind_r
		, CAST(NULL AS DATE)													               AS D_UW_CYCLE_DATE_R
		, CAST(NULL AS DATE)													               AS D_UW_LAST_UPDATE_DATE_R
		, cast(null as DATE)                                                                   AS D_ID_THEFT_DATE_R
		, cast(null as VARCHAR2(30))                                                           AS V_ID_THEFT_IND_R
		, fct_grp_policy_r.N_ASO_FEE_AMT_R				                                       AS N_ASO_FEE_AMT_R
		, CAST(NULL AS VARCHAR2(300))                                                          AS V_ELIM_PERIOD_R
		, CAST(NULL AS VARCHAR2(10))                                                           AS V_CROSS_SELL_INDICATOR_R
		, CAST(NULL AS VARCHAR2(10))                                                           AS V_6MNTH_CROSS_SELL_INDICATOR_R
		, CAST(NULL AS VARCHAR2(300))                                                          AS V_ANY_LOB_CROSS_SELL_R
		, CAST(NULL AS VARCHAR2(300))                                                          AS V_LTD_CROSS_SELL_R
		, CAST(NULL AS VARCHAR2(300))                                                          AS V_STD_CROSS_SELL_R
		, CAST(NULL AS VARCHAR2(300))                                                          AS V_LIFE_CROSS_SELL_R
		, CAST(NULL AS VARCHAR2(300))                                                          AS V_BASIC_LIFE_CROSS_SELL_R
		, CAST(NULL AS VARCHAR2(300))                                                          AS V_SUPP_LIFE_CROSS_SELL_R
		, CAST(NULL AS VARCHAR2(300))                                                          AS V_DEP_LIFE_CROSS_SELL_R
		, CAST(NULL AS VARCHAR2(300))                                                          AS V_ADD_CROSS_SELL_R
		, CAST(NULL AS VARCHAR2(300))                                                          AS V_SR_CROSS_SELL_R
		, CAST(NULL AS VARCHAR2(300))                                                          AS V_VAR_CROSS_SELL_R
		, CAST(NULL AS VARCHAR2(300))                                                          AS V_VAI_CROSS_SELL_R
		, CAST(NULL AS VARCHAR2(300))                                                          AS V_VCI_CROSS_SELL_R
		, CAST(NULL AS NUMBER)                                                                 AS N_TOTAL_PRODUCT_LINES_R
		, CAST(NULL AS VARCHAR2(3000))                                                         AS V_EAP_DESC_R
		, CAST(NULL AS VARCHAR2(3000))                                                         AS V_BEREAVE_DESC_R
		, CAST(NULL AS VARCHAR2(300))                                                          AS V_EAP_EFF_DATE_R
		, CAST(NULL AS VARCHAR2(300))                                                          AS V_BEREAVEDATE_R
		, CASE
			WHEN fct_grp_policy_r.V_SOURCE_SYSTEM_NAME_R = 'EIS'
			THEN
			CASE WHEN fct_grp_policy_r.N_CLAIMS_TAX_INDICATOR_R = 0 THEN 'N'
				 WHEN fct_grp_policy_r.N_CLAIMS_TAX_INDICATOR_R = 1 THEN 'Y'
				 WHEN fct_grp_policy_r.N_CLAIMS_TAX_INDICATOR_R = 2 THEN 'X'
			END
			WHEN fct_grp_policy_r.N_W2_EXCLUDE_FICA_MATCH_R = 1
		 	 THEN 'X'
            WHEN fct_grp_policy_r.N_CLAIMS_TAX_INDICATOR_R = 1 AND dim_grp_policy_dir_r.V_POLICY_PREFIX_R IN ('ASL', 'ASW')
		 	 THEN 'Y'
            WHEN fct_grp_policy_r.N_CLAIMS_TAX_INDICATOR_R = 1
              AND fct_grp_policy_r.V_CARRIER_NAME_R IN ('First Reliance Standard Life Insurance Company'
			                                          , 'Reliance Standard Life Insurance Company')
             THEN 'Y'
			ELSE 'N' END 																	   AS V_RSL_EIN_IND_R
		, fct_grp_policy_r.N_ASO_SETUP_FEE_AMT_R                                               AS N_ASO_SETUP_FEE_AMT_R
		, CAST(NULL AS VARCHAR2(300))                                                          AS V_COVERAGE_CODE_R
		, CAST(NULL AS DATE)          										                   AS d_rate_guar_r
        , CAST(NULL AS VARCHAR2(100)) 										                   AS d_option_eff_date_r
        , CAST(NULL AS VARCHAR2(100)) 										                   AS v_option_r
        , CAST(NULL AS NUMBER)                   							                   AS n_new_option_rate_r
		, fct_grp_policy_r.N_RATE_GUARANTEE_R                                                  AS N_RATE_GUARANTEE_R
        , CAST(NULL AS DATE)                                                                   AS D_NEXT_RENEWAL_EFFECTIVE_DATE_R
		, CAST(NULL AS VARCHAR2(1000))                                                         AS V_AGENCY_CODE_r
        , CAST (NULL AS DATE)                                                                  AS D_SUBMISSION_DATE_R
		, CAST(NULL AS VARCHAR2(100))                                                          AS V_POLICY_INFORCE_INDICATOR_R
        , CAST(NULL AS NUMBER)                                                                 AS N_ANNUALIZED_PREMIUM_R
        , fct_grp_policy_r.V_DISTRIBUTION_CHANNEL_R                                            AS V_DISTRIBUTION_CHANNEL_R 
		,(
			CASE
			WHEN  	dim_grp_policy_dir_r.v_policy_prefix_r LIKE '%ASW%'
					AND
					nvl ( fct_grp_policy_r.v_carrier_name_r  ,
							(case 	when fct_grp_policy_r.v_administered_by_r = 'RSL'
									then 'Reliance Standard Life Insurance Company'
									when fct_grp_policy_r.v_administered_by_r = 'FRSLIC'
									then 'First Reliance Standard Life Insurance Company'
									else
									null
								 end
							)
						)= 'First Reliance Standard Life Insurance Company'
				THEN  nvl( fct_grp_policy_r.v_carrier_name_r  ,
								(case 	when fct_grp_policy_r.v_administered_by_r = 'RSL'
										then 'Reliance Standard Life Insurance Company'
										when fct_grp_policy_r.v_administered_by_r = 'FRSLIC'
										then 'First Reliance Standard Life Insurance Company'
										else
										null
								end
								)
						 )
			WHEN 	dim_grp_policy_dir_r.v_policy_prefix_r LIKE '%ASL%'
					AND
					nvl( fct_grp_policy_r.v_carrier_name_r  ,
							(case 	when fct_grp_policy_r.v_administered_by_r = 'RSL'
									then 'Reliance Standard Life Insurance Company'
									when fct_grp_policy_r.v_administered_by_r = 'FRSLIC'
									then 'First Reliance Standard Life Insurance Company'
									else
									null
							end
							)
						)= 'First Reliance Standard Life Insurance Company'
				THEN  nvl( fct_grp_policy_r.v_carrier_name_r  ,
								(case 	when fct_grp_policy_r.v_administered_by_r = 'RSL'
										then 'Reliance Standard Life Insurance Company'
										when fct_grp_policy_r.v_administered_by_r = 'FRSLIC'
										then 'First Reliance Standard Life Insurance Company'
										else
										null
								end
								)
						 )
            WHEN dim_grp_policy_dir_r.v_policy_prefix_r LIKE '%ASW%'
				THEN 'RSL ADMINISTRATIVE SERVICES'
			WHEN dim_grp_policy_dir_r.v_policy_prefix_r LIKE '%ASL%'
				THEN 'RSL ADMINISTRATIVE SERVICES'
			ELSE nvl( fct_grp_policy_r.v_carrier_name_r  ,
							(case 	when fct_grp_policy_r.v_administered_by_r = 'RSL'
									then 'Reliance Standard Life Insurance Company'
									when fct_grp_policy_r.v_administered_by_r = 'FRSLIC'
									then 'First Reliance Standard Life Insurance Company'
									else
									null
							end
							)
					)
			END
		) 						AS V_CARRIER_NAME_TAX_R
		 FROM ATOMIC.DIM_GRP_POLICY_DIR_R DIM_GRP_POLICY_DIR_R
	        , ATOMIC.FCT_GRP_POLICY_R FCT_GRP_POLICY_R
			,(
				SELECT  DISTINCT N_POLICY_SK_R,
				  V_POLICY_NUMBER_R,
				  MIN(case when N_POLICY_VERSION_NUMBER_R = 1 THEN T_POLICY_EFFECTIVE_DATE_R END) AS T_POLICY_EFFECTIVE_DATE_R_1,
                  MIN(case when N_POLICY_VERSION_NUMBER_R = 0 THEN T_POLICY_EFFECTIVE_DATE_R END) AS T_POLICY_EFFECTIVE_DATE_R_0
				FROM ATOMIC.DIM_GRP_POLICY_DIR_R
				group by N_POLICY_SK_R,
				V_POLICY_NUMBER_R
			) POLICY_DIR_EFF_DATE
	    ,(SELECT *
		    FROM ATOMIC.FCT_GRP_BILLING_POLICY_DTL_R a
	       WHERE a.T_EVENT_TIMESTAMP_R = (SELECT MAX(T_EVENT_TIMESTAMP_R)
		                                    FROM ATOMIC.FCT_GRP_BILLING_POLICY_DTL_R B
                                           WHERE A.N_POLICY_SK_R = B.N_POLICY_SK_R
											 AND B.D_DELETE_DATE_R IS  NULL
	                                     )
             AND A.D_DELETE_DATE_R IS  NULL
		     AND A.N_POLICY_ID_R NOT IN (68215,64819)
          ) FCT_GRP_BILLING_POLICY_DTL_R
         ,(SELECT *
		    FROM (SELECT RANK() OVER ( PARTITION BY NVL(N_SOURCE_SYSTEM_KEY_R, -1)
												      , N_VERSION_NUMBER_R
												      , N_POLICY_SKEY_R
											ORDER BY N_BATCH_ID_R DESC
												   , T_EVENT_TIMESTAMP_R DESC
												   , N_TXN_VERSION_NUMBER_R DESC
                                     ) RNK,
                  A.*
            FROM ATOMIC.FCT_GRP_TRANSACTIONS_R A
           WHERE N_POLICY_SKEY_R <> -1
             AND V_SOURCE_SYSTEM_NAME_R IN ('EIS', 'PACS')) X WHERE RNK = 1
			) FCT_GRP_TRANSACTIONS_R
	    , atomic.dim_grp_udfield_r  dim_grp_udfield_r
	WHERE dim_grp_policy_dir_r.v_active_status_r ='Y'
	  AND fct_grp_policy_r.n_policy_sk_r=dim_grp_policy_dir_r.n_policy_sk_r
	  AND fct_grp_billing_policy_dtl_r.n_policy_sk_r(+)=dim_grp_policy_dir_r.n_policy_sk_r
	  and FCT_GRP_POLICY_R.N_VERSION_NUMBER_R=DIM_GRP_POLICY_DIR_R.N_POLICY_VERSION_NUMBER_R
      and nvl(FCT_GRP_POLICY_R.N_SOURCE_SYSTEM_KEY_R,999999) = nvl(DIM_GRP_POLICY_DIR_R.N_SOURCE_SYSTEM_KEY_R,999999)
      AND FCT_GRP_POLICY_R.N_POLICY_SK_R = DIM_GRP_POLICY_DIR_R.N_POLICY_SK_R
      AND fct_grp_transactions_r.n_policy_skey_r=dim_grp_policy_dir_r.n_policy_sk_r
	  and FCT_GRP_TRANSACTIONS_R.N_VERSION_NUMBER_R=DIM_GRP_POLICY_DIR_R.N_POLICY_VERSION_NUMBER_R
      and nvl(fct_grp_transactions_r.N_SOURCE_SYSTEM_KEY_R,-1)=nvl(DIM_GRP_POLICY_DIR_R.N_SOURCE_SYSTEM_KEY_R,-1) 
      and DIM_GRP_UDFIELD_R.N_ENTITY_ID_R(+) = FCT_GRP_BILLING_POLICY_DTL_R.N_POLICY_ID_R
      and DIM_GRP_UDFIELD_R.N_ENTITY_TYPE_ID_R(+) = 200
      and DIM_GRP_POLICY_DIR_R.n_policy_sk_r = POLICY_DIR_EFF_DATE.n_policy_sk_r(+);