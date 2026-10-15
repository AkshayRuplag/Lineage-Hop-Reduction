-- Cleaned for lineage: MVW_PRODUCT_SK_LOOKUP

INSERT
			INTO FCT_PROC_EXEC_STATUS_LOG_R
				(
				N_BATCH_ID_R,
				N_MIS_DATE_SKEY_R,
				N_LOAD_RUN_ID_R,
				V_STATUS_R,
				T_EXECUTION_TIMESTAMP_R,
				V_USER_R,
				V_PLSQL_BLOCK_NAME_R,
				N_SERIAL_NUM_R
				)
				VALUES
				(
				LN_BATCH_ID_R,
				TO_CHAR(sysdate,'yyyymmdd'),
				1,
				'Started',
				SYSTIMESTAMP,
				USER,
				P_MV_TBL_NAME||'.PROC_REFRESH_GRP_M_VIEW_TBLS.MVW_PRODUCT_SK_LOOKUP_TBL',
				N_MAX_SERIAL_NUM_R
				);

INSERT  INTO MVW_PRODUCT_SK_LOOKUP_TBL (N_CLAIM_SK_R, V_CLAIM_NUMBER_R, V_CLAIM_COVERAGE_CODE_R, N_PRODUCT_SK_R)
			   SELECT 
				c.n_claim_sk_r,
				p.v_claim_number_r,
				p.v_claim_coverage_code_r,
				nvl(p.n_product_sk_r,-1) as n_product_sk_r
			FROM
				(
					( SELECT
						*
					FROM
							 (
							SELECT
								v_claim_number_r,
								v_line_of_business_r,
								v_class_of_business_r,
								v_claim_coverage_code_r,
								CASE
									WHEN v_claim_coverage_code_r IN ( 'A/R', 'A/V', 'GAD', 'GCM', 'ORL',
																	  'PTD', 'SAD', 'VAD', 'VGT', 'SC' ) THEN
											CASE
												WHEN v_line_of_business_r IN ( 'GL', 'VGTL' ) THEN
													'Group Life'
												WHEN v_line_of_business_r = 'SC'    THEN
													'SCNILC'
												WHEN v_line_of_business_r IN ( 'SR', 'VAR' ) THEN
													v_line_of_business_r
												WHEN v_class_of_business_r IN ( 'ASG', 'SPG' ) THEN
													'Group Life'
												WHEN v_class_of_business_r = 'ORL'  THEN
													'John Alden I'
												ELSE
													'Unknown'
											END
									WHEN v_claim_coverage_code_r = 'GWI'
										 AND v_line_of_business_r NOT IN ( 'ASW', 'STD', 'VPS' ) THEN
										'Unknown'
									WHEN v_claim_coverage_code_r = 'GWI'
										 AND v_line_of_business_r IN ( 'ASW', 'STD', 'VPS' ) THEN
										'STD'
									WHEN v_claim_coverage_code_r = 'JAL'
										 AND v_line_of_business_r NOT IN ( 'SC' ) THEN
										'Unknown'
									WHEN v_claim_coverage_code_r = 'GPL' THEN
										'Group Life'
									WHEN v_claim_coverage_code_r = 'STD'
										 AND v_line_of_business_r IN ( 'STD' ) THEN
										'STD'			   
									WHEN v_claim_coverage_code_r = 'NYPL'
										 AND v_line_of_business_r IN ( 'DBL' ) THEN
										'STD'			   
                                    WHEN v_claim_coverage_code_r = 'ASW'
										 AND v_line_of_business_r IN ( 'ASW' ) THEN
										'STD'			    
									WHEN v_claim_coverage_code_r = 'FLI'
										 AND v_line_of_business_r IN ( 'TDB' ) THEN
										'STD'			    
							        WHEN v_claim_coverage_code_r = 'FMLA'
										 AND v_line_of_business_r IN ( 'FML' ) THEN
										'STD'
									ELSE
										NULL
								END productsubline1
							FROM
								(
									SELECT
										d.v_claim_number_r,
										a.v_claim_coverage_code_r                                          cov_code,
										b.v_claim_coverage_code_r                                          cov_grp_cov_code,
										c.v_line_of_business_r,
										c.v_class_of_business_r,
										nvl(a.v_claim_coverage_code_r, b.v_claim_coverage_code_r)          v_claim_coverage_code_r
									FROM
										dim_grp_claim_coverage_r          a
										left outer join dim_grp_claim_coverage_group_r    b
										on a.n_claim_coverage_sk_r = b.n_claim_coverage_sk_r,
										fct_grp_policy_r                  c,
										(select * from dim_grp_claim_dir_r  where v_active_status_r = 'Y')   d,
										(select * from dim_grp_policy_dir_r where v_active_status_r = 'Y')   e
									WHERE
											a.n_claim_sk_r = d.n_claim_sk_r
										AND d.n_policy_sk_r = c.n_policy_sk_r
										AND e.n_policy_sk_r = c.n_policy_sk_r
										AND e.n_policy_version_number_r = c.n_version_number_r
								) 
								WHERE
									v_claim_coverage_code_r IN ( 'A/R', 'A/V', 'GAD', 'GCM', 'ORL',
													   'PTD', 'SAD', 'VAD', 'VGT', 'GWI',
													   'JAL', 'GPL',
													   'SC', 'STD', 'NYPL', 'ASW', 'FLI', 'FMLA' )   
									or v_claim_coverage_code_r is null
						) a
						LEFT JOIN DIM_GRP_PRODUCT_R b ON a.v_claim_coverage_code_r = b.v_coverage_code_r
																 AND a.productsubline1 = b.v_product_sub_line_code_r
					)
				) p ,
				dim_grp_claim_dir_r c
				where p.v_claim_number_r = c.v_claim_number_r
				and c.v_active_status_r = 'Y'
			GROUP BY
				c.n_claim_sk_r,
				p.v_claim_number_r,
				p.v_claim_coverage_code_r,
				p.n_product_sk_r;

INSERT  INTO MVW_PRODUCT_SK_LOOKUP_TBL (N_CLAIM_SK_R, V_CLAIM_NUMBER_R, V_CLAIM_COVERAGE_CODE_R, N_PRODUCT_SK_R)
		SELECT 
				a.n_claim_sk_r,
				a.v_claim_number_r,
				a.v_claim_coverage_code_r,
				nvl(a.n_product_sk_r,-1) as n_product_sk_r
		from (
		SELECT 
				c.n_claim_sk_r,
				p.v_claim_number_r,
				p.v_claim_coverage_code_r,
				nvl(p.n_product_sk_r,-1) as n_product_sk_r
			FROM
				(
					( SELECT
						*
					FROM
							 (
							SELECT
								v_claim_number_r,
								v_line_of_business_r,
								v_class_of_business_r,
								v_claim_coverage_code_r,
								CASE
									WHEN v_claim_coverage_code_r IN ( 'A/R', 'A/V', 'GAD', 'GCM', 'ORL',
																	  'PTD', 'SAD', 'VAD', 'VGT', 'SC' ) THEN
											CASE
												WHEN v_line_of_business_r IN ( 'GL', 'VGTL' ) THEN
													'Group Life'
												WHEN v_line_of_business_r = 'SC'    THEN
													'SCNILC'
												WHEN v_line_of_business_r IN ( 'SR', 'VAR' ) THEN
													v_line_of_business_r
												WHEN v_class_of_business_r IN ( 'ASG', 'SPG' ) THEN
													'Group Life'
												WHEN v_class_of_business_r = 'ORL'  THEN
													'John Alden I'
												ELSE
													'Unknown'
											END
									WHEN v_claim_coverage_code_r = 'GWI'
										 AND v_line_of_business_r NOT IN ( 'ASW', 'STD', 'VPS' ) THEN
										'Unknown'
									WHEN v_claim_coverage_code_r = 'GWI'
										 AND v_line_of_business_r IN ( 'ASW', 'STD', 'VPS' ) THEN
										'STD'
									WHEN v_claim_coverage_code_r = 'JAL'
										 AND v_line_of_business_r NOT IN ( 'SC' ) THEN
										'Unknown'
									WHEN v_claim_coverage_code_r = 'JAL'
										 AND v_line_of_business_r NOT IN ( 'SC' ) THEN
										'SCNILC'
									WHEN v_claim_coverage_code_r = 'GPL' THEN
										'Group Life'
									WHEN v_claim_coverage_code_r = 'STD'
										 AND v_line_of_business_r IN ( 'STD' ) THEN
										'STD'	  
									WHEN v_claim_coverage_code_r = 'NYPL'
										 AND v_line_of_business_r IN ( 'DBL' ) THEN
										'STD'			   
                                    WHEN v_claim_coverage_code_r = 'ASW'
										 AND v_line_of_business_r IN ( 'ASW' ) THEN
										'STD'			    
                                    WHEN v_claim_coverage_code_r = 'FLI'
										 AND v_line_of_business_r IN ( 'TDB' ) THEN
										'STD'			    
							        WHEN v_claim_coverage_code_r = 'FMLA'
										 AND v_line_of_business_r IN ( 'FML' ) THEN
										'STD'			 
									ELSE
										NULL
								END productsubline1
							FROM
								(
									SELECT
										d.v_claim_number_r,
										a.v_claim_coverage_code_r                                          cov_code,
										b.v_claim_coverage_code_r                                          cov_grp_cov_code,
										c.v_line_of_business_r,
										c.v_class_of_business_r,
										nvl(a.v_claim_coverage_code_r, b.v_claim_coverage_code_r)          v_claim_coverage_code_r
									FROM
										dim_grp_claim_coverage_r          a
										left outer join dim_grp_claim_coverage_group_r    b
										on a.n_claim_coverage_sk_r = b.n_claim_coverage_sk_r,
										fct_grp_policy_r                  c,
										(select * from dim_grp_claim_dir_r  where v_active_status_r = 'Y')        d,
										(select * from dim_grp_policy_dir_r where v_active_status_r = 'Y')        e
									WHERE
										 a.n_claim_sk_r = d.n_claim_sk_r
										AND d.n_policy_sk_r = c.n_policy_sk_r							
										AND e.n_policy_sk_r = c.n_policy_sk_r
										AND e.n_policy_version_number_r = c.n_version_number_r
								)
						) a
						LEFT JOIN dim_grp_product_r b ON a.v_claim_coverage_code_r = b.v_coverage_code_r
					WHERE
						b.v_coverage_code_r NOT IN ( 'A/R', 'A/V', 'GAD', 'GCM', 'ORL',
													 'PTD', 'SAD', 'VAD', 'VGT', 'GWI',
													 'JAL', 'GPL',
													 'SC', 'STD', 'NYPL', 'ASW', 'FLI', 'FMLA')  
					)
				) p ,
				dim_grp_claim_dir_r c
				where p.v_claim_number_r = c.v_claim_number_r
				and c.v_active_status_r = 'Y'
			GROUP BY
				c.n_claim_sk_r,
				p.v_claim_number_r,
				p.v_claim_coverage_code_r,
				p.n_product_sk_r
			) a	
			WHERE NOT EXISTS
			(
			SELECT 1
			FROM MVW_PRODUCT_SK_LOOKUP_TBL b
			WHERE a.n_claim_sk_r = b.n_claim_sk_r
				and a.v_claim_number_r =b.v_claim_number_r
				and a.v_claim_coverage_code_r=b.v_claim_coverage_code_r
				and a.n_product_sk_r=b.n_product_sk_r
			);

UPDATE FCT_PROC_EXEC_STATUS_LOG_R
						SET V_STATUS_R                = 'Successful',
						T_EXECUTION_END_TIMESTAMP_R = systimestamp
						WHERE N_SERIAL_NUM_R          = N_MAX_SERIAL_NUM_R;