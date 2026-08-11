

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ATOMIC"."PKG_GRP_LOAD_FCT_RPT_CROSS_SELL_SUMMARY_R"
/*
NOTE : This pkg is developed based on the pkg PKG_GRP_LOAD_FCT_RPT_CROSS_SELL_SUMMARY_R
*********************************************************************************************************************************
* Type -            PLSQL Package
* Name -            PKG_GRP_LOAD_FCT_RPT_CROSS_SELL_SUMMARY_R
* Owner -           ATOMIC
* Description -     This package has the PLSLQ procedures,FUNCTIONS used to populate the Finance tables, called by ODI wrappers.
* Created on -      26-jUL-2021
------------------------------------------------------------------------------------------------------------------------------------
* Dependent tables
  ----------------
              FCT_GRP_POLICY_R
              FCT_RPT_ANN_PREM_SUMMARY_R
              dim_grp_party_r
              dim_grp_policy_dir_r
              STG_ANN_PREM_CUSTOMER_LINK_R
              FCT_RPT_CROSS_SELL_SUMMARY_R
* 08-AUg-2024 Introduced MV's and global temporary table for performance issue and replaced the EDW tables with MV's
              FCT_RPT_CROSS_SELL_POLICY_EFFECTIV_DT_DRQ_MV
              FCT_RPT_CROSS_SELL_ANNPREM_CUSTLINK_POL_EFF_DT_DRQ_MV
              FCT_RPT_CROSS_SELL_ANNPREM_CUSTLINK_POL_EFF_DT_DRQ_MV2
              FCT_RPT_CROSS_SELL_SUMMARY_DRQ_MV
			  FCT_RPT_CROSS_SELL_REWRITEIND_DRQ_MV
*********************************************************************************************************************************** */
/*
   Author     Date       Description
  ---------- --------   -------------------------------------------------
  Suresh     17-10-2025 Optimized program and create single cursor to insert data inplace of all local procedure and function.
  Suresh     22-10-2025 Commented the all updates due to performance issue. These columns are not being used in the report so far.
                        --   When we are exposing that in the report ,we need to fix the performance issue of the update and then enable
*/

as

PROCEDURE main
IS
  ln_bulk_limit_r                NUMBER;
  ln_months number;
  ld_cycle_date_r                DATE;
  ld_cycle_date_r_2              DATE;
  ln_step                        number;
  lv_policy_prefix_r             VARCHAR2(50);
  ln_loop_counter       PLS_INTEGER                          		    := 1;
  ln_rec_cnt 			PLS_INTEGER									    := 0;
  ld_sysdate      DATE:=SYSDATE;
  ld_fic_mis_date DATE;

  CURSOR cur_data
  IS
   	WITH MAIN_QRY AS
(SELECT N_POLICY_SK_R                           AS N_POLICY_SK_R
	  , N_VERSION_NUMBER_R                      AS N_VERSION_NUMBER_R
	  , N_TOTAL_PRODUCT_LINES_R                 AS N_TOTAL_PRODUCT_LINES_R
	  , V_REWRITE_INDICATOR_R                   AS V_REWRITE_INDICATOR_R
	  , V_POLICY_NUMBER_R                       AS V_POLICY_NUMBER_R
	  , v_master_customer_num_r                 AS V_MASTER_CUSTOMER_NUMBER_R
      , (SELECT MAX(MV.T_POLICY_EFFECTIVE_DATE_R)
           FROM FCT_RPT_CROSS_SELL_POLICY_EFF_DT_DRQ_MV MV
          WHERE MV.N_POLICY_SK_R= MAIN.N_POLICY_SK_R
         )                                      AS D_POLICY_EFFECTIVE_DATE_R
	  , (SELECT MAX(T_POLICY_EFFECTIVE_DATE_R)
	       FROM FCT_RPT_CROSS_SELL_ANNPREM_CUSTLINK_POL_EFF_DT_DRQ_MV2
	      WHERE N_POLICY_SK_R = MAIN.N_POLICY_SK_R
         )                                      AS T_POLICY_EFFECTIVE_DATE_R
      , (SELECT V_POLICY_PREFIX_R
           FROM ATOMIC.DIM_GRP_POLICY_DIR_R --need to chk
          WHERE N_POLICY_SK_R= MAIN.N_POLICY_SK_R
            AND V_ACTIVE_STATUS_R = 'Y'
       GROUP BY V_POLICY_PREFIX_R
         )                                      AS V_POLICY_PREFIX_R
     , (SELECT NVL(MAX(N_SEQUENCE_NUMBER_R),0)
	    FROM atomic.FCT_RPT_CROSS_SELL_SUMMARY_R) AS N_SEQUENCE_NUMBER_R
      , ROWNUM  AS CUR_RECORD
	FROM (SELECT FGPR.N_POLICY_SK_R
	           , FGPR.V_POLICY_NUMBER_R
			   , FGPR.N_VERSION_NUMBER_R
			   , FGPR.v_master_customer_num_r
			   , (SELECT (CASE WHEN N_REWRITE_INDICATOR_CNT_R > 0 THEN
						    'Y'
						  ELSE
						    'N'
						  END
						  )
		           FROM atomic.FCT_RPT_CROSS_SELL_REWRITEIND_DRQ_MV
		          WHERE N_POLICY_SK_R=FGPR.N_POLICY_SK_R
                  ) V_REWRITE_INDICATOR_R
				 ,(SELECT COUNT(B.N_POLICY_SK_R)
		             FROM FCT_RPT_CROSS_SELL_SUMMARY_DRQ_MV b
		            WHERE EXISTS (SELECT 1
				                    FROM ATOMIC.FCT_RPT_ANN_PREM_SUMMARY_R A
				                   WHERE A.V_POLICY_NUMBER_R= B.V_POLICY_NUMBER_R
		                             AND (A.D_CYCLE_DATE_R) = TRUNC(gd_cycle_date) --('28-MAY-25')
								  )
					  AND B.V_POLICY_NUMBER_R        = FGPR.V_POLICY_NUMBER_R
					  AND B.V_MASTER_CUSTOMER_NUM_R  = FGPR.V_MASTER_CUSTOMER_NUM_R
				  ) N_TOTAL_PRODUCT_LINES_R
                 , NULL V_BASIC_PRODUCT_LINE_CODE_R
    FROM FCT_RPT_CROSS_SELL_SUMMARY_DRQ_MV FGPR
    WHERE EXISTS (SELECT 1
	              FROM ATOMIC.FCT_RPT_ANN_PREM_SUMMARY_R FRAPSR
				 WHERE  FRAPSR.V_POLICY_NUMBER_R= FGPR.V_POLICY_NUMBER_R
				   AND (FRAPSR.D_CYCLE_DATE_R) = TRUNC(gd_cycle_date) --    ('28-MAY-25')
				)
    GROUP BY FGPR.N_POLICY_SK_R,FGPR.V_POLICY_NUMBER_R,FGPR.N_VERSION_NUMBER_R,FGPR.V_MASTER_CUSTOMER_NUM_R--,TRUNC(LD_CYCLE_DATE_R)--TRUNC(FRAPSR.D_CYCLE_DATE_R)
	) MAIN
    ),  --55090  Rows
    CTE_EFF_DT_MC AS
    (SELECT /*+PARALLEL(4)*/
	        MIN(COALESCE(CL.T_POLICY_EFFECTIVE_DATE_R, FGPR.T_POLICY_EFFECTIVE_DATE_R, FGPR.T_DGPDR_POLICY_EFFECTIVE_DATE_R)) D_MIN_POL_EFF_DATE_MC_R
          , FGPR.V_MASTER_CUSTOMER_NUM_R
       FROM FCT_RPT_CROSS_SELL_SUMMARY_DRQ_MV FGPR
		  , (SELECT CUST_LINK_POL_EFF.T_POLICY_EFFECTIVE_DATE_R
		          , CUST_LINK_POL_EFF.V_NEW_POLICY_PREFIX_SUFFIX_R
			   FROM FCT_RPT_CROSS_SELL_ANNPREM_CUSTLINK_POL_EFF_DT_DRQ_MV CUST_LINK_POL_EFF
			  GROUP BY CUST_LINK_POL_EFF.T_POLICY_EFFECTIVE_DATE_R,CUST_LINK_POL_EFF.V_NEW_POLICY_PREFIX_SUFFIX_R
			) CL
      WHERE EXISTS (SELECT 1
					  FROM ATOMIC.FCT_RPT_ANN_PREM_SUMMARY_R FRAPSR
					 WHERE  FRAPSR.V_POLICY_NUMBER_R= FGPR.V_POLICY_NUMBER_R
					   AND TRUNC(FRAPSR.D_CYCLE_DATE_R) = TRUNC(TO_DATE(gd_cycle_date)) -- ('28-MAY-25')
					   AND FRAPSR.N_ANNUALIZED_PREMIUM_R IS NOT NULL
					)
        AND FGPR.V_DGPDR_POLICY_PREFIX_SUFFIX_R = CL.V_NEW_POLICY_PREFIX_SUFFIX_R(+)
   GROUP BY FGPR.V_MASTER_CUSTOMER_NUM_R
    )
   , CTE_PRODUCT_LINE AS
   (SELECT AP.V_POLICY_NUMBER_R
         , CASE
           WHEN COUNT(DISTINCT pd.V_BASIC_PRODUCT_LINE_CODE_R) > 1 THEN
            NULL
           ELSE MAX(pd.V_BASIC_PRODUCT_LINE_CODE_R)
           END AS V_BASIC_PRODUCT_LINE_CODE_R
	  FROM ATOMIC.FCT_RPT_ANN_PREM_SUMMARY_R AP,
	       ATOMIC.DIM_GRP_PRODUCT_R PD
	   WHERE AP.V_COVERAGE_CODE_R = PD.V_COVERAGE_CODE_R
		 AND (AP.D_CYCLE_DATE_R) = TRUNC(TO_DATE(gd_cycle_date))
	GROUP BY AP.V_POLICY_NUMBER_R
	)
   ,CTE_MONTH_CAL AS
     ( SELECT CASE WHEN D_MIN_POL_EFF_DATE_MC_R IS NOT NULL AND D_RPT_POLICY_EFFECTIVE_DATE_R IS NOT NULL THEN
                  NVL(months_between(D_RPT_POLICY_EFFECTIVE_DATE_R,D_MIN_POL_EFF_DATE_MC_R),0)
          END ln_months
        , N_POLICY_SK_R
        , D_RPT_POLICY_EFFECTIVE_DATE_R
         FROM (SELECT (CASE WHEN T_POLICY_EFFECTIVE_DATE_R IS NOT NULL THEN
                              T_POLICY_EFFECTIVE_DATE_R
                           WHEN D_POLICY_EFFECTIVE_DATE_R IS NOT NULL THEN
                              D_POLICY_EFFECTIVE_DATE_R
                           ELSE
                             NULL
                        END
                       ) D_RPT_POLICY_EFFECTIVE_DATE_R
                    , D_MIN_POL_EFF_DATE_MC_R D_MIN_POL_EFF_DATE_MC_R
                    , N_POLICY_SK_R
                 FROM MAIN_QRY
            LEFT JOIN CTE_EFF_DT_MC
                   ON MAIN_QRY.V_MASTER_CUSTOMER_NUMBER_R = CTE_EFF_DT_MC.V_MASTER_CUSTOMER_NUM_R)
     )
	SELECT MAIN_QRY.N_POLICY_SK_R  AS N_POLICY_SK_R
        ,  N_VERSION_NUMBER_R            AS N_VERSION_NUMBER_R
        ,  CASE WHEN ln_months IS NULL THEN
                  'N'--NULL
           WHEN ln_months > 1 THEN
              'Y'
            ELSE
              'N'
            END                         AS V_CROSS_SELL_INDICATOR_R
        ,  CASE WHEN ln_months IS NULL THEN
                'N'--NULL
           WHEN ln_months>=6 THEN
              'Y'
           ELSE
              'N'
           END                          AS V_6MNTH_CROSS_SELL_INDICATOR_R
        ,  CASE WHEN ln_months IS NULL THEN
               NULL
           WHEN ln_months > 1 THEN
              'Y'
           ELSE
              'N'
           END                           AS V_ANY_LOB_CROSS_SELL_R
        ,  CASE WHEN ln_months IS NULL THEN
               NULL
           WHEN ln_months > 1 THEN
            CASE WHEN UPPER(NVL(v_basic_product_line_code_r,'@')) = 'LTD' THEN
             'Y'
            ELSE
             'N'
            END
           ELSE
              'N'
           END                           AS V_LTD_CROSS_SELL_R
        ,  CASE WHEN ln_months IS NULL THEN
               NULL
           WHEN ln_months > 1 THEN
              CASE WHEN UPPER(NVL(v_basic_product_line_code_r,'@')) = 'STD' THEN
               'Y'
              ELSE
               'N'
              END
           ELSE
              'N'
           END    						 AS V_STD_CROSS_SELL_R
        ,  CASE WHEN ln_months IS NULL THEN
               NULL
           WHEN ln_months > 1 THEN
             CASE WHEN UPPER(NVL(v_basic_product_line_code_r,'@')) = 'LIFE' THEN
                CASE WHEN v_policy_prefix_r IN ('GL','VG') THEN
                 'Y'
                ELSE
                 'N'
                END
             ELSE
              'N'
             END
           ELSE
              'N'
           END                           AS V_LIFE_CROSS_SELL_R
        ,  CASE WHEN ln_months IS NULL THEN
               NULL
           WHEN ln_months > 1 THEN
              CASE WHEN UPPER(NVL(v_basic_product_line_code_r,'@')) = 'BASIC LIFE' THEN
               'Y'
              ELSE
               'N'
              END
            ELSE
              'N'
            END                          AS V_BASIC_LIFE_CROSS_SELL_R
        ,  CASE WHEN ln_months IS NULL THEN
               NULL
            WHEN ln_months > 1 THEN
              CASE WHEN UPPER(NVL(v_basic_product_line_code_r,'@')) = 'SUPPLEMENTAL LIFE' THEN
               'Y'
              ELSE
               'N'
              END
            ELSE
              'N'
            END                          AS V_SUPP_LIFE_CROSS_SELL_R
        ,  CASE WHEN ln_months IS NULL THEN
               NULL
           WHEN ln_months > 1 THEN
              CASE WHEN UPPER(NVL(v_basic_product_line_code_r,'@')) = 'DEPENDENT LIFE' THEN
               'Y'
              ELSE
               'N'
              END
           ELSE
              'N'
           END                           AS V_DEP_LIFE_CROSS_SELL_R
        ,  CASE WHEN ln_months IS NULL THEN
               NULL
           WHEN ln_months > 1 THEN
              CASE WHEN UPPER(NVL(v_basic_product_line_code_r,'@')) LIKE '%AD'||CHR(38)||'D' THEN
               'Y'
              ELSE
               'N'
              END
           ELSE
              'N'
           END                           AS V_ADD_CROSS_SELL_R
        ,  CASE WHEN ln_months IS NULL THEN
               NULL
           WHEN ln_months > 1 THEN
              CASE WHEN UPPER(NVL(v_basic_product_line_code_r,'@')) = 'SR' THEN
               'Y'
              ELSE
               'N'
              END
            ELSE
              'N'
            END                          AS V_SR_CROSS_SELL_R
        ,  CASE WHEN ln_months IS NULL THEN
               NULL
           WHEN ln_months > 1 THEN
              CASE WHEN UPPER(NVL(v_basic_product_line_code_r,'@')) = 'VAR' THEN
               'Y'
              ELSE
               'N'
              END
           ELSE
              'N'
           END                           AS V_VAR_CROSS_SELL_R
        ,  CASE WHEN ln_months IS NULL THEN
               NULL
           WHEN ln_months > 1 THEN
              CASE WHEN UPPER(NVL(v_basic_product_line_code_r,'@')) = 'VAI' THEN
               'Y'
              ELSE
               'N'
              END
           ELSE
              'N'
           END                           AS V_VAI_CROSS_SELL_R
        ,  CASE WHEN ln_months IS NULL THEN
               NULL
           WHEN ln_months > 1 THEN
              CASE WHEN UPPER(NVL(v_basic_product_line_code_r,'@')) = 'VCI' THEN
               'Y'
              ELSE
               'N'
              END
           ELSE
              'N'
           END                           AS V_VCI_CROSS_SELL_R
        ,  N_TOTAL_PRODUCT_LINES_R       AS N_TOTAL_PRODUCT_LINES_R
        ,  V_REWRITE_INDICATOR_R         AS V_REWRITE_INDICATOR_R
        ,  D_POLICY_EFFECTIVE_DATE_R     AS D_POLICY_EFFECTIVE_DATE_R
        ,  D_RPT_POLICY_EFFECTIVE_DATE_R AS D_RPT_POLICY_EFFECTIVE_DATE_R
        ,  D_MIN_POL_EFF_DATE_MC_R       AS D_MIN_POL_EFF_DATE_MC_R
        ,  MAIN_QRY.V_POLICY_NUMBER_R    AS V_POLICY_NUMBER_R
        ,  MAIN_QRY.V_MASTER_CUSTOMER_NUMBER_R       AS V_MASTER_CUSTOMER_NUMBER_R
        ,  NULL                          AS V_POLICY_PREFIX_R         -- V_POLICY_PREFIX_R TO NULL -- AS ON 15-10-2025
        ,  gn_batch_id                   AS N_BATCH_ID_R
        ,  1                             AS N_LOAD_RUN_ID_R
        ,  N_SEQUENCE_NUMBER_R+CUR_RECORD AS N_SEQUENCE_NUMBER_R
        ,  gd_sysdate                    AS T_CREATION_DATE_R
        ,  gd_sysdate                    AS T_LAST_MODIFIED_DATE_R
        ,  gc_created_by                 AS V_CREATED_BY_R
        ,  gc_last_modified_by           AS V_LAST_MODIFIED_BY_R
        ,  gd_sysdate                    AS FIC_MIS_DATE_R
        ,  TRUNC(gd_cycle_date)          AS D_CYCLE_DATE_R
        ,  CAST(NULL AS VARCHAR2(20))    AS V_PRIVACY_INDICATOR_R
        ,  gn_yearmonth_r                AS N_YEARMONTH_R
        ,  V_BASIC_PRODUCT_LINE_CODE_R   AS V_BASIC_PRODUCT_LINE_CODE_R
    FROM MAIN_QRY
    JOIN CTE_MONTH_CAL
    ON CTE_MONTH_CAL.N_POLICY_SK_R = MAIN_QRY.N_POLICY_SK_R
    LEFT JOIN CTE_EFF_DT_MC
    ON MAIN_QRY.V_MASTER_CUSTOMER_NUMBER_R = CTE_EFF_DT_MC.V_MASTER_CUSTOMER_NUM_R
    LEFT JOIN CTE_PRODUCT_LINE
    ON MAIN_QRY.V_POLICY_NUMBER_R = CTE_PRODUCT_LINE.V_POLICY_NUMBER_R
  ;
TYPE var_cross_sell_type IS TABLE OF cur_data%ROWTYPE INDEX BY BINARY_INTEGER;
lt_var_cross_sell_tbl_typ var_cross_sell_type;


BEGIN
      --Call Log Util pkg to Insert entry in PRCS_JOB_LOG_R
	--For more details how this procedure is being used, refer the Main Procedure comment block.
	pkg_grp_log_util.PRC_INSERT_LOG
					( p_source              		=> gv_source
					 ,p_job_nm               		=> gv_job_name
					 ,p_job_status           		=> gv_running_status
					 ,p_err_msg              		=> NULL
					 ,p_trc_msg              		=> NULL
					 ,p_n_batch_id           		=> gn_sysdt_batchid
					 ,p_log_util_called_by_r 		=> gv_main_loadedby
					 ,out_job_id             		=> gn_out_job_id
					);

     gv_trcmsg:='1.0 Entered into Main';
    /*START: NEW LOGGING MECHANISM CHANGES*/
	 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
				   ( p_job_id_r                  	=> gn_out_job_id
					,p_batch_id_r               	=> gn_sysdt_batchid
					,p_message_type_r            	=> gv_message_type
					,p_code_location_r            	=> gv_main_loadedby
					,p_message_r                  	=> gv_trcmsg
					,p_count_type_r               	=> NULL
					,p_count_r                    	=> NULL
					,p_duration_r                 	=> NULL
					,p_created_by_r               	=> GV_JOB_NAME
					,out_prcs_job_log_message_id_r	=> gn_job_log_message_id
					);
    /*END: NEW LOGGING MECHANISM CHANGES*/
  /*
    SELECT D_CALENDAR_DATE_R + 1
    INTO ld_fic_mis_date--27-Nov-2023 changes
    FROM atomic.DIM_TIME_R D
   WHERE  V_END_OF_FISCAL_MONTH_IND_R = 'Y'
     AND TO_CHAR(D_CALENDAR_DATE_R,'YYYYMM')=TO_CHAR(LD_SYSDATE,'YYYYMM');

   gv_trcmsg:='1.1 Checking Fiscal Month End Date.'||ld_fic_mis_date;

	 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
				   ( p_job_id_r                  	=> gn_out_job_id
					,p_batch_id_r               	=> gn_sysdt_batchid
					,p_message_type_r            	=> gv_message_type
					,p_code_location_r            	=> gv_main_loadedby
					,p_message_r                  	=> gv_trcmsg
					,p_count_type_r               	=> NULL
					,p_count_r                    	=> NULL
					,p_duration_r                 	=> NULL
					,p_created_by_r               	=> GV_JOB_NAME
					,out_prcs_job_log_message_id_r	=> gn_job_log_message_id
					);

   IF TO_DATE(ld_fic_mis_date) = TO_DATE(ld_sysdate)  --to load data on next day of Fiscal Month (Ex:the fiscal month end for May 2023 is 26-MAY-23 so we should load this on 27-MAY-23)
   --OR TRIM(LC_DAY)='SATURDAY'-- or to load data on Saturday
   THEN
   */

    /*START:NEW LOGGING MECHANISM CHANGES*/
	gv_trcmsg:='2.0 Entered into main and fetch cycle date from param table';
	gt_start_time := SYSTIMESTAMP;
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                     => gn_out_job_id
					,p_batch_id_r                   => gn_sysdt_batchid
					,p_message_type_r               => GV_MESSAGE_TYPE
					,p_code_location_r              => gv_main_loadedby
					,p_message_r                    => gv_trcmsg
					,p_count_type_r                 => NULL
					,p_count_r                      => NULL
					,p_duration_r                   => NULL
					,p_created_by_r                 => gv_job_name
					,out_prcs_job_log_message_id_r  => gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/
	BEGIN
	  SELECT  v_debug_flag_r,d_cycle_date_r,n_bulk_limit_r
	  INTO   gc_debug_flag,ld_cycle_date_r,ln_bulk_limit_r
      FROM   atomic.prcs_grp_dataingestion_param_r
      WHERE  v_job_name_r = 'GRP_LOAD_FCT_RPT_CROSS_SELL_SUMMARY_R';

		--ld_cycle_date_r := '28-MAY-25';
	EXCEPTION
	WHEN OTHERS THEN
	  null;
	END;
    /*START: NEW LOGGING MECHANISM CHANGES*/
	gt_end_time := SYSTIMESTAMP;
	gv_trcmsg:='2.1 fetch cycle date from param table completed:-'||ld_cycle_date_r;
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                    	=> gn_out_job_id
					,p_batch_id_r                  	=> gn_sysdt_batchid
					,p_message_type_r              	=> GV_MESSAGE_TYPE
					,p_code_location_r             	=> gv_main_loadedby
					,p_message_r                   	=> gv_trcmsg
					,p_count_type_r                	=> NULL
					,p_count_r                     	=> null
					,p_duration_r                  	=> FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
					,p_created_by_r                	=> gv_job_name
					,out_prcs_job_log_message_id_r 	=> gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/
    /*START:NEW LOGGING MECHANISM CHANGES*/
	gv_trcmsg:='3.0 fetch MAX(cycle date) from fct_rpt_ann_prem_summary_r table';
	gt_start_time := SYSTIMESTAMP;
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                     => gn_out_job_id
					,p_batch_id_r                   => gn_sysdt_batchid
					,p_message_type_r               => GV_MESSAGE_TYPE
					,p_code_location_r              => gv_main_loadedby
					,p_message_r                    => gv_trcmsg
					,p_count_type_r                 => NULL
					,p_count_r                      => NULL
					,p_duration_r                   => NULL
					,p_created_by_r                 => gv_job_name
					,out_prcs_job_log_message_id_r  => gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/
	--28-Apr-2022 changes starts
	BEGIN
	  SELECT  max(d_cycle_date_r)
	  INTO  ld_cycle_date_r_2
      FROM atomic.fct_rpt_ann_prem_summary_r;
	--  ld_cycle_date_r_2 := '28-MAY-25';
	EXCEPTION
	WHEN OTHERS THEN
	  null;
	END;
    /*START: NEW LOGGING MECHANISM CHANGES*/
	gt_end_time := SYSTIMESTAMP;
	gv_trcmsg:='3.1 fetch MAX(cycle date) from fct_rpt_ann_prem_summary_r table'||ld_cycle_date_r_2;
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                    	=> gn_out_job_id
					,p_batch_id_r                  	=> gn_sysdt_batchid
					,p_message_type_r              	=> GV_MESSAGE_TYPE
					,p_code_location_r             	=> gv_main_loadedby
					,p_message_r                   	=> gv_trcmsg
					,p_count_type_r                	=> NULL
					,p_count_r                     	=> null
					,p_duration_r                  	=> FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
					,p_created_by_r                	=> gv_job_name
					,out_prcs_job_log_message_id_r 	=> gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/

    /*START: NEW LOGGING MECHANISM CHANGES*/
    gv_trcmsg:='5.0 Validatating cycle date if date is available then Delete Cycle Date data from FCT_RPT_CROSS_SELL_SUMMARY_R'||ld_cycle_date_r_2;
	gt_start_time := SYSTIMESTAMP;
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                     => gn_out_job_id
					,p_batch_id_r                   => gn_sysdt_batchid
					,p_message_type_r               => GV_MESSAGE_TYPE
					,p_code_location_r              => gv_main_loadedby
					,p_message_r                    => gv_trcmsg
					,p_count_type_r                 => NULL
					,p_count_r                      => NULL
					,p_duration_r                   => NULL
					,p_created_by_r                 => gv_job_name
					,out_prcs_job_log_message_id_r  => gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/
    --The below IF condtion gives priority to Cycle Date fetched from fct_rpt_ann_prem_summary_r

		IF ld_cycle_date_r IS NOT NULL THEN
		  gd_cycle_date:=ld_cycle_date_r;
		ELSE
           gd_cycle_date:=ld_cycle_date_r_2;
	    END IF;

    gn_yearmonth_r:=to_number(to_char(gd_cycle_date,'YYYYMM'));

    IF gd_cycle_date IS null THEN
      --raise_application_error(-20000,'Error Message->d_cycle_date_r value populated in the table prcs_grp_dataingestion_param_r and fct_rpt_ann_prem_summary_r,So update d_cycle_date_r to null table prcs_grp_dataingestion_param_r and rerun the job');
      gv_trcmsg:='5.1 Final Cycle Date is NULL hence exit from the program';
	gt_start_time := SYSTIMESTAMP;
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                     => gn_out_job_id
					,p_batch_id_r                   => gn_sysdt_batchid
					,p_message_type_r               => GV_MESSAGE_TYPE
					,p_code_location_r              => gv_main_loadedby
					,p_message_r                    => gv_trcmsg
					,p_count_type_r                 => NULL
					,p_count_r                      => NULL
					,p_duration_r                   => NULL
					,p_created_by_r                 => gv_job_name
					,out_prcs_job_log_message_id_r  => gn_job_log_message_id
				);
      --raise_application_error(-20000,'Error Message->NOT ABLE TO DERIVE MAX(d_cycle_date_r) fct_rpt_ann_prem_summary_r ,hence terminating the job');
	--08-Aug-2024 changes starts
	ELSE
      gv_trcmsg:='5.2 Delete Cycle Date data from FCT_RPT_CROSS_SELL_SUMMARY_R';
	gt_start_time := SYSTIMESTAMP;
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                     => gn_out_job_id
					,p_batch_id_r                   => gn_sysdt_batchid
					,p_message_type_r               => GV_MESSAGE_TYPE
					,p_code_location_r              => gv_main_loadedby
					,p_message_r                    => gv_trcmsg
					,p_count_type_r                 => gv_count_type_del
					,p_count_r                      => NULL
					,p_duration_r                   => NULL
					,p_created_by_r                 => gv_job_name
					,out_prcs_job_log_message_id_r  => gn_job_log_message_id
				);
       ln_rec_cnt := 0 ;
       -- Enable parallel DML session.
            EXECUTE IMMEDIATE 'ALTER SESSION ENABLE PARALLEL DML';

           DELETE /*+PARALLEL(4)*/ FROM ATOMIC.FCT_RPT_CROSS_SELL_SUMMARY_R WHERE TRUNC(TO_DATE(D_CYCLE_DATE_R))=TRUNC(TO_DATE(gd_cycle_date));
           ln_rec_cnt := SQL%ROWCOUNT;
           COMMIT;
       -- Disable parallel DML session.
                EXECUTE IMMEDIATE 'ALTER SESSION DISABLE PARALLEL DML';
       /*START: NEW LOGGING MECHANISM CHANGES*/
	    gt_end_time := SYSTIMESTAMP;
           gv_trcmsg:='5.3 Deleted Cycle Date data from FCT_RPT_CROSS_SELL_SUMMARY_R'||ld_cycle_date_r_2||'. Records Deleted '||ln_rec_cnt;
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                    	=> gn_out_job_id
					,p_batch_id_r                  	=> gn_sysdt_batchid
					,p_message_type_r              	=> GV_MESSAGE_TYPE
					,p_code_location_r             	=> gv_main_loadedby
					,p_message_r                   	=> gv_trcmsg
					,p_count_type_r                	=> gv_count_type_del
					,p_count_r                     	=> ln_rec_cnt
					,p_duration_r                  	=> FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
					,p_created_by_r                	=> gv_job_name
					,out_prcs_job_log_message_id_r 	=> gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/
	END IF;

    ln_rec_cnt:=0;
	OPEN  CUR_DATA ;
	LOOP
	   LT_VAR_CROSS_SELL_TBL_TYP.DELETE;
       FETCH CUR_DATA
        BULK COLLECT
        INTO  LT_VAR_CROSS_SELL_TBL_TYP LIMIT GN_BULK_COLL_CNT;  --200 TO 5000
       gt_start_time_inside_lp := SYSTIMESTAMP; -- Start timing before the insert
	   FORALL X IN LT_VAR_CROSS_SELL_TBL_TYP.FIRST..LT_VAR_CROSS_SELL_TBL_TYP.LAST
       INSERT /*+APPEND_VALUE*/ INTO  FCT_RPT_CROSS_SELL_SUMMARY_R VALUES LT_VAR_CROSS_SELL_TBL_TYP(X);
       ln_rec_cnt:=ln_rec_cnt+LT_VAR_CROSS_SELL_TBL_TYP.COUNT;
       COMMIT;

       gt_end_time := SYSTIMESTAMP; -- End timing after the insert
       gv_trcmsg   := '6.1: Data load: Bulk Set - '|| ln_loop_counter || ': ' || ln_rec_cnt || ' records loaded' ;

		/*START: NEW LOGGING MECHANISM CHANGES*/
            PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
                   ( p_job_id_r 					=> gn_out_job_id
                    ,p_batch_id_r					=> gn_sysdt_batchid
                    ,p_message_type_r 				=> gv_message_type
                    ,p_code_location_r 				=> gv_main_loadedby
                    ,p_message_r 					=> gv_trcmsg
                    ,p_count_type_r 				=> gv_count_type
                    ,p_count_r 						=> ln_rec_cnt
                    ,p_duration_r 					=> FNC_GRP_TIME_DURATION(gt_start_time_inside_lp,gt_end_time)
                    ,p_created_by_r 				=> Gv_JOB_NAME
                    ,out_prcs_job_log_message_id_r	=> gn_job_log_message_id
                    );
		/*END: NEW LOGGING MECHANISM CHANGES*/

		ln_loop_counter := ln_loop_counter + 1;

       EXIT WHEN CUR_DATA%NOTFOUND;
    END LOOP;
	CLOSE CUR_DATA;
     /*START: NEW LOGGING MECHANISM CHANGES*/
	    gt_end_time := SYSTIMESTAMP;
           gv_trcmsg:='6.2 Data Loaded '||ln_rec_cnt||' records ';

		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                    	=> gn_out_job_id
					,p_batch_id_r                  	=> gn_sysdt_batchid
					,p_message_type_r              	=> GV_MESSAGE_TYPE
					,p_code_location_r             	=> gv_main_loadedby
					,p_message_r                   	=> gv_trcmsg
					,p_count_type_r                	=> gv_count_type
					,p_count_r                     	=> ln_rec_cnt
					,p_duration_r                  	=> FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
					,p_created_by_r                	=> gv_job_name
					,out_prcs_job_log_message_id_r 	=> gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/
    /* Comment Started the below updates due to performance issue. These columns are not being used in the report so far.
    --   When we are exposing that in the report ,we need to fix the performance issue of the update and then enable...
gv_trcmsg:='7.0 Update V_SUPP_LIFE_CROSS_SELL_R starts';
	gt_start_time := SYSTIMESTAMP;
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                     => gn_out_job_id
					,p_batch_id_r                   => gn_sysdt_batchid
					,p_message_type_r               => GV_MESSAGE_TYPE
					,p_code_location_r              => gv_main_loadedby
					,p_message_r                    => gv_trcmsg
					,p_count_type_r                 => gv_count_type_upd
					,p_count_r                      => NULL
					,p_duration_r                   => NULL
					,p_created_by_r                 => gv_job_name
					,out_prcs_job_log_message_id_r  => gn_job_log_message_id
				);

    -- Updating V_SUPP_LIFE_CROSS_SELL_R
    ln_rec_cnt := 0 ;
    FOR J IN (SELECT COUNT(1) CNT,V_MASTER_CUSTOMER_NUMBER_R
	            FROM ATOMIC.FCT_RPT_CROSS_SELL_SUMMARY_R   B
		       WHERE TRUNC(B.D_CYCLE_DATE_R)= trunc(gd_cycle_date)
		         AND B.V_SUPP_LIFE_CROSS_SELL_R='Y'
			GROUP BY B.V_MASTER_CUSTOMER_NUMBER_R
			)
	LOOP
	    IF J.CNT>0 THEN
	     UPDATE ATOMIC.FCT_RPT_CROSS_SELL_SUMMARY_R  A
	       SET A.V_SUPP_LIFE_CROSS_SELL_R='Y'
	       WHERE  TRUNC(A.D_CYCLE_DATE_R)= trunc(gd_cycle_date)
	       AND A.V_MASTER_CUSTOMER_NUMBER_R=J.V_MASTER_CUSTOMER_NUMBER_R
	      AND A.V_SUPP_LIFE_CROSS_SELL_R='N';
          ln_rec_cnt := ln_rec_cnt + SQL%ROWCOUNT;
	    END IF;
	    COMMIT;
	END LOOP;

	    gt_end_time := SYSTIMESTAMP;
           gv_trcmsg:='7.1 Update V_SUPP_LIFE_CROSS_SELL_R ends.Total records updated : '||ln_rec_cnt;
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                    	=> gn_out_job_id
					,p_batch_id_r                  	=> gn_sysdt_batchid
					,p_message_type_r              	=> GV_MESSAGE_TYPE
					,p_code_location_r             	=> gv_main_loadedby
					,p_message_r                   	=> gv_trcmsg
					,p_count_type_r                	=> gv_count_type_upd
					,p_count_r                     	=> ln_rec_cnt
					,p_duration_r                  	=> FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
					,p_created_by_r                	=> gv_job_name
					,out_prcs_job_log_message_id_r 	=> gn_job_log_message_id
				);
       -- Updating V_STD_CROSS_SELL_R

    gv_trcmsg:='8.0 Update V_STD_CROSS_SELL_R starts';
	gt_start_time := SYSTIMESTAMP;
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                     => gn_out_job_id
					,p_batch_id_r                   => gn_sysdt_batchid
					,p_message_type_r               => GV_MESSAGE_TYPE
					,p_code_location_r              => gv_main_loadedby
					,p_message_r                    => gv_trcmsg
					,p_count_type_r                 => gv_count_type_upd
					,p_count_r                      => NULL
					,p_duration_r                   => NULL
					,p_created_by_r                 => gv_job_name
					,out_prcs_job_log_message_id_r  => gn_job_log_message_id
				);

   ln_rec_cnt := 0 ;
    FOR J IN (SELECT COUNT(1) CNT,V_MASTER_CUSTOMER_NUMBER_R
	            FROM ATOMIC.FCT_RPT_CROSS_SELL_SUMMARY_R   B
			   WHERE TRUNC(B.D_CYCLE_DATE_R)= trunc(gd_cycle_date)
			     AND B.V_STD_CROSS_SELL_R='Y'
			GROUP BY B.V_MASTER_CUSTOMER_NUMBER_R
			)
	LOOP
	    IF J.CNT>0 THEN
	     UPDATE  ATOMIC.FCT_RPT_CROSS_SELL_SUMMARY_R  A
	       SET A.V_STD_CROSS_SELL_R='Y'
	       WHERE  TRUNC(A.D_CYCLE_DATE_R)= trunc(gd_cycle_date)
	       AND A.V_MASTER_CUSTOMER_NUMBER_R=J.V_MASTER_CUSTOMER_NUMBER_R
	      AND A.V_STD_CROSS_SELL_R='N';
          ln_rec_cnt := ln_rec_cnt + SQL%ROWCOUNT;
	    END IF;
	COMMIT;
	END LOOP;

	    gt_end_time := SYSTIMESTAMP;
           gv_trcmsg:='8.1 Update V_STD_CROSS_SELL_R ends.Total records updated : '||ln_rec_cnt;
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                    	=> gn_out_job_id
					,p_batch_id_r                  	=> gn_sysdt_batchid
					,p_message_type_r              	=> GV_MESSAGE_TYPE
					,p_code_location_r             	=> gv_main_loadedby
					,p_message_r                   	=> gv_trcmsg
					,p_count_type_r                	=> gv_count_type_upd
					,p_count_r                     	=> ln_rec_cnt
					,p_duration_r                  	=> FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
					,p_created_by_r                	=> gv_job_name
					,out_prcs_job_log_message_id_r 	=> gn_job_log_message_id
				);

    gv_trcmsg:='9.0 Update V_LTD_CROSS_SELL_R starts';
	gt_start_time := SYSTIMESTAMP;
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                     => gn_out_job_id
					,p_batch_id_r                   => gn_sysdt_batchid
					,p_message_type_r               => GV_MESSAGE_TYPE
					,p_code_location_r              => gv_main_loadedby
					,p_message_r                    => gv_trcmsg
					,p_count_type_r                 => gv_count_type_upd
					,p_count_r                      => NULL
					,p_duration_r                   => NULL
					,p_created_by_r                 => gv_job_name
					,out_prcs_job_log_message_id_r  => gn_job_log_message_id
				);

       -- Updating V_LTD_CROSS_SELL_R
    ln_rec_cnt := 0 ;
    FOR J IN (SELECT COUNT(1) CNT,V_MASTER_CUSTOMER_NUMBER_R
	            FROM ATOMIC.FCT_RPT_CROSS_SELL_SUMMARY_R   B
		       WHERE TRUNC(B.D_CYCLE_DATE_R)= trunc(gd_cycle_date)
		         AND B.V_LTD_CROSS_SELL_R='Y'
			GROUP BY B.V_MASTER_CUSTOMER_NUMBER_R
			)
	LOOP
	    IF J.CNT>0 THEN
	     UPDATE ATOMIC.FCT_RPT_CROSS_SELL_SUMMARY_R  A
	       SET A.V_LTD_CROSS_SELL_R='Y'
	       WHERE  TRUNC(A.D_CYCLE_DATE_R)= trunc(gd_cycle_date)
	       AND A.V_MASTER_CUSTOMER_NUMBER_R=J.V_MASTER_CUSTOMER_NUMBER_R
	      AND A.V_LTD_CROSS_SELL_R='N';
          ln_rec_cnt := ln_rec_cnt + SQL%ROWCOUNT;
	    END IF;
	COMMIT;
	END LOOP;

	    gt_end_time := SYSTIMESTAMP;
           gv_trcmsg:='9.1 Update V_LTD_CROSS_SELL_R ends.Total records updated : '||ln_rec_cnt;
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                    	=> gn_out_job_id
					,p_batch_id_r                  	=> gn_sysdt_batchid
					,p_message_type_r              	=> GV_MESSAGE_TYPE
					,p_code_location_r             	=> gv_main_loadedby
					,p_message_r                   	=> gv_trcmsg
					,p_count_type_r                	=> gv_count_type_upd
					,p_count_r                     	=> ln_rec_cnt
					,p_duration_r                  	=> FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
					,p_created_by_r                	=> gv_job_name
					,out_prcs_job_log_message_id_r 	=> gn_job_log_message_id
				);

    gv_trcmsg:='10.0 Update V_LIFE_CROSS_SELL_R starts';
	gt_start_time := SYSTIMESTAMP;
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                     => gn_out_job_id
					,p_batch_id_r                   => gn_sysdt_batchid
					,p_message_type_r               => GV_MESSAGE_TYPE
					,p_code_location_r              => gv_main_loadedby
					,p_message_r                    => gv_trcmsg
					,p_count_type_r                 => gv_count_type_upd
					,p_count_r                      => NULL
					,p_duration_r                   => NULL
					,p_created_by_r                 => gv_job_name
					,out_prcs_job_log_message_id_r  => gn_job_log_message_id
				);

       -- Updating V_LIFE_CROSS_SELL_R
    ln_rec_cnt := 0 ;
    FOR J IN (SELECT COUNT(1) CNT,V_MASTER_CUSTOMER_NUMBER_R
	            FROM ATOMIC.FCT_RPT_CROSS_SELL_SUMMARY_R   B
		       WHERE TRUNC(B.D_CYCLE_DATE_R)= trunc(gd_cycle_date)
		         AND B.V_LIFE_CROSS_SELL_R='Y'
			GROUP BY B.V_MASTER_CUSTOMER_NUMBER_R
			)
	LOOP
	    IF J.CNT>0 THEN
	     UPDATE ATOMIC.FCT_RPT_CROSS_SELL_SUMMARY_R  A
	       SET A.V_LIFE_CROSS_SELL_R='Y'
	       WHERE  TRUNC(A.D_CYCLE_DATE_R)= trunc(gd_cycle_date)
	       AND A.V_MASTER_CUSTOMER_NUMBER_R=J.V_MASTER_CUSTOMER_NUMBER_R
	      AND A.V_LIFE_CROSS_SELL_R='N';
          ln_rec_cnt := ln_rec_cnt + SQL%ROWCOUNT;
	    END IF;
	COMMIT;
	END LOOP;

	    gt_end_time := SYSTIMESTAMP;
           gv_trcmsg:='10.1 Update V_LIFE_CROSS_SELL_R ends.Total records updated : '||ln_rec_cnt;
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                    	=> gn_out_job_id
					,p_batch_id_r                  	=> gn_sysdt_batchid
					,p_message_type_r              	=> GV_MESSAGE_TYPE
					,p_code_location_r             	=> gv_main_loadedby
					,p_message_r                   	=> gv_trcmsg
					,p_count_type_r                	=> gv_count_type_upd
					,p_count_r                     	=> ln_rec_cnt
					,p_duration_r                  	=> FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
					,p_created_by_r                	=> gv_job_name
					,out_prcs_job_log_message_id_r 	=> gn_job_log_message_id
				);

    gv_trcmsg:='11.0 Update V_BASIC_LIFE_CROSS_SELL_R starts';
	gt_start_time := SYSTIMESTAMP;
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                     => gn_out_job_id
					,p_batch_id_r                   => gn_sysdt_batchid
					,p_message_type_r               => GV_MESSAGE_TYPE
					,p_code_location_r              => gv_main_loadedby
					,p_message_r                    => gv_trcmsg
					,p_count_type_r                 => gv_count_type_upd
					,p_count_r                      => NULL
					,p_duration_r                   => NULL
					,p_created_by_r                 => gv_job_name
					,out_prcs_job_log_message_id_r  => gn_job_log_message_id
				);

       -- Updating V_BASIC_LIFE_CROSS_SELL_R
       ln_rec_cnt := 0 ;
    FOR J IN (SELECT COUNT(1) CNT,V_MASTER_CUSTOMER_NUMBER_R
	            FROM ATOMIC.FCT_RPT_CROSS_SELL_SUMMARY_R   B
		       WHERE TRUNC(B.D_CYCLE_DATE_R)= trunc(gd_cycle_date)
		         AND B.V_BASIC_LIFE_CROSS_SELL_R='Y'
			GROUP BY B.V_MASTER_CUSTOMER_NUMBER_R
			)
	LOOP
	    IF J.CNT>0 THEN
	     UPDATE  ATOMIC.FCT_RPT_CROSS_SELL_SUMMARY_R  A
	       SET A.V_BASIC_LIFE_CROSS_SELL_R='Y'
	       WHERE  TRUNC(A.D_CYCLE_DATE_R)= trunc(gd_cycle_date)
	       AND A.V_MASTER_CUSTOMER_NUMBER_R=J.V_MASTER_CUSTOMER_NUMBER_R
	      AND A.V_BASIC_LIFE_CROSS_SELL_R='N';
          ln_rec_cnt := ln_rec_cnt + SQL%ROWCOUNT;
	    END IF;
	    COMMIT;
	END LOOP;

	    gt_end_time := SYSTIMESTAMP;
           gv_trcmsg:='11.1 Update V_BASIC_LIFE_CROSS_SELL_R ends.Total records updated : '||ln_rec_cnt;
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                    	=> gn_out_job_id
					,p_batch_id_r                  	=> gn_sysdt_batchid
					,p_message_type_r              	=> GV_MESSAGE_TYPE
					,p_code_location_r             	=> gv_main_loadedby
					,p_message_r                   	=> gv_trcmsg
					,p_count_type_r                	=> gv_count_type_upd
					,p_count_r                     	=> ln_rec_cnt
					,p_duration_r                  	=> FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
					,p_created_by_r                	=> gv_job_name
					,out_prcs_job_log_message_id_r 	=> gn_job_log_message_id
				);

    gv_trcmsg:='12.0 Update V_DEP_LIFE_CROSS_SELL_R starts';
	gt_start_time := SYSTIMESTAMP;
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                     => gn_out_job_id
					,p_batch_id_r                   => gn_sysdt_batchid
					,p_message_type_r               => GV_MESSAGE_TYPE
					,p_code_location_r              => gv_main_loadedby
					,p_message_r                    => gv_trcmsg
					,p_count_type_r                 => gv_count_type_upd
					,p_count_r                      => NULL
					,p_duration_r                   => NULL
					,p_created_by_r                 => gv_job_name
					,out_prcs_job_log_message_id_r  => gn_job_log_message_id
				);

      ln_rec_cnt := 0 ;
    FOR J IN (SELECT COUNT(1) CNT,V_MASTER_CUSTOMER_NUMBER_R
	            FROM ATOMIC.FCT_RPT_CROSS_SELL_SUMMARY_R   B
	           WHERE TRUNC(B.D_CYCLE_DATE_R)= trunc(gd_cycle_date)
	             AND B.V_DEP_LIFE_CROSS_SELL_R='Y'
			  GROUP BY B.V_MASTER_CUSTOMER_NUMBER_R
			  )
	LOOP
	    IF J.CNT>0 THEN
	     UPDATE ATOMIC.FCT_RPT_CROSS_SELL_SUMMARY_R  A
	       SET A.V_DEP_LIFE_CROSS_SELL_R='Y'
	       WHERE  TRUNC(A.D_CYCLE_DATE_R)= trunc(gd_cycle_date)
	       AND A.V_MASTER_CUSTOMER_NUMBER_R=J.V_MASTER_CUSTOMER_NUMBER_R
	      AND A.V_DEP_LIFE_CROSS_SELL_R='N';
          ln_rec_cnt := ln_rec_cnt + SQL%ROWCOUNT;
	    END IF;
	 COMMIT;
	 END LOOP;

	    gt_end_time := SYSTIMESTAMP;
           gv_trcmsg:='12.1 Update V_DEP_LIFE_CROSS_SELL_R ends.Total records updated : '||ln_rec_cnt;
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                    	=> gn_out_job_id
					,p_batch_id_r                  	=> gn_sysdt_batchid
					,p_message_type_r              	=> GV_MESSAGE_TYPE
					,p_code_location_r             	=> gv_main_loadedby
					,p_message_r                   	=> gv_trcmsg
					,p_count_type_r                	=> gv_count_type_upd
					,p_count_r                     	=> ln_rec_cnt
					,p_duration_r                  	=> FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
					,p_created_by_r                	=> gv_job_name
					,out_prcs_job_log_message_id_r 	=> gn_job_log_message_id
				);

    gv_trcmsg:='13.0 Update V_ADD_CROSS_SELL_R starts';
	gt_start_time := SYSTIMESTAMP;
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                     => gn_out_job_id
					,p_batch_id_r                   => gn_sysdt_batchid
					,p_message_type_r               => GV_MESSAGE_TYPE
					,p_code_location_r              => gv_main_loadedby
					,p_message_r                    => gv_trcmsg
					,p_count_type_r                 => gv_count_type_upd
					,p_count_r                      => NULL
					,p_duration_r                   => NULL
					,p_created_by_r                 => gv_job_name
					,out_prcs_job_log_message_id_r  => gn_job_log_message_id
				);

       -- Updating V_ADD_CROSS_SELL_R
       ln_rec_cnt := 0 ;
    FOR J IN (SELECT COUNT(1) CNT,V_MASTER_CUSTOMER_NUMBER_R FROM ATOMIC.FCT_RPT_CROSS_SELL_SUMMARY_R   B
		       WHERE TRUNC(B.D_CYCLE_DATE_R)= trunc(gd_cycle_date)
		       AND B.V_ADD_CROSS_SELL_R='Y'
			GROUP BY B.V_MASTER_CUSTOMER_NUMBER_R
			  )
	LOOP
	    IF J.CNT>0 THEN
	     UPDATE ATOMIC.FCT_RPT_CROSS_SELL_SUMMARY_R  A
	       SET A.V_ADD_CROSS_SELL_R='Y'
	       WHERE  TRUNC(A.D_CYCLE_DATE_R)= trunc(gd_cycle_date)
	       AND A.V_MASTER_CUSTOMER_NUMBER_R=J.V_MASTER_CUSTOMER_NUMBER_R
	      AND A.V_ADD_CROSS_SELL_R='N';
          ln_rec_cnt := ln_rec_cnt + SQL%ROWCOUNT;
	    END IF;
	    COMMIT;
	END LOOP;

	    gt_end_time := SYSTIMESTAMP;
           gv_trcmsg:='13.1 Update V_ADD_CROSS_SELL_R ends.Total records updated : '||ln_rec_cnt;
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                    	=> gn_out_job_id
					,p_batch_id_r                  	=> gn_sysdt_batchid
					,p_message_type_r              	=> GV_MESSAGE_TYPE
					,p_code_location_r             	=> gv_main_loadedby
					,p_message_r                   	=> gv_trcmsg
					,p_count_type_r                	=> gv_count_type_upd
					,p_count_r                     	=> ln_rec_cnt
					,p_duration_r                  	=> FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
					,p_created_by_r                	=> gv_job_name
					,out_prcs_job_log_message_id_r 	=> gn_job_log_message_id
				);

    gv_trcmsg:='14.0 Update V_SR_CROSS_SELL_R starts';
	gt_start_time := SYSTIMESTAMP;
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                     => gn_out_job_id
					,p_batch_id_r                   => gn_sysdt_batchid
					,p_message_type_r               => GV_MESSAGE_TYPE
					,p_code_location_r              => gv_main_loadedby
					,p_message_r                    => gv_trcmsg
					,p_count_type_r                 => gv_count_type_upd
					,p_count_r                      => NULL
					,p_duration_r                   => NULL
					,p_created_by_r                 => gv_job_name
					,out_prcs_job_log_message_id_r  => gn_job_log_message_id
				);

       -- Updating V_SR_CROSS_SELL_R
       ln_rec_cnt := 0 ;
    FOR J IN (SELECT COUNT(1) CNT,V_MASTER_CUSTOMER_NUMBER_R FROM ATOMIC.FCT_RPT_CROSS_SELL_SUMMARY_R   B
		       WHERE TRUNC(B.D_CYCLE_DATE_R)= trunc(gd_cycle_date)
		         AND B.V_SR_CROSS_SELL_R='Y'
			GROUP BY B.V_MASTER_CUSTOMER_NUMBER_R
			)
	LOOP
	    IF J.CNT>0 THEN
	     UPDATE  ATOMIC.FCT_RPT_CROSS_SELL_SUMMARY_R  A
	       SET A.V_SR_CROSS_SELL_R='Y'
	       WHERE  TRUNC(A.D_CYCLE_DATE_R)= trunc(gd_cycle_date)
	       AND A.V_MASTER_CUSTOMER_NUMBER_R=J.V_MASTER_CUSTOMER_NUMBER_R

	      AND A.V_SR_CROSS_SELL_R='N';
          ln_rec_cnt := ln_rec_cnt + SQL%ROWCOUNT;
	    END IF;
	    COMMIT;
	END LOOP;

	    gt_end_time := SYSTIMESTAMP;
           gv_trcmsg:='14.1 Update V_SR_CROSS_SELL_R ends.Total records updated : '||ln_rec_cnt;
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                    	=> gn_out_job_id
					,p_batch_id_r                  	=> gn_sysdt_batchid
					,p_message_type_r              	=> GV_MESSAGE_TYPE
					,p_code_location_r             	=> gv_main_loadedby
					,p_message_r                   	=> gv_trcmsg
					,p_count_type_r                	=> gv_count_type_upd
					,p_count_r                     	=> ln_rec_cnt
					,p_duration_r                  	=> FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
					,p_created_by_r                	=> gv_job_name
					,out_prcs_job_log_message_id_r 	=> gn_job_log_message_id
				);

    gv_trcmsg:='15.0 Update V_VAR_CROSS_SELL_R starts';
	gt_start_time := SYSTIMESTAMP;
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                     => gn_out_job_id
					,p_batch_id_r                   => gn_sysdt_batchid
					,p_message_type_r               => GV_MESSAGE_TYPE
					,p_code_location_r              => gv_main_loadedby
					,p_message_r                    => gv_trcmsg
					,p_count_type_r                 => gv_count_type_upd
					,p_count_r                      => NULL
					,p_duration_r                   => NULL
					,p_created_by_r                 => gv_job_name
					,out_prcs_job_log_message_id_r  => gn_job_log_message_id
				);

       -- Updating V_VAR_CROSS_SELL_R
       ln_rec_cnt := 0 ;
    FOR J IN (SELECT COUNT(1) CNT,V_MASTER_CUSTOMER_NUMBER_R
	            FROM ATOMIC.FCT_RPT_CROSS_SELL_SUMMARY_R   B
		       WHERE TRUNC(B.D_CYCLE_DATE_R)= trunc(gd_cycle_date)
		         AND B.V_VAR_CROSS_SELL_R='Y'
		    GROUP BY B.V_MASTER_CUSTOMER_NUMBER_R
			 )
	LOOP
	    IF J.CNT>0 THEN
	     UPDATE  ATOMIC.FCT_RPT_CROSS_SELL_SUMMARY_R  A
	       SET A.V_VAR_CROSS_SELL_R='Y'
	       WHERE  TRUNC(A.D_CYCLE_DATE_R)= trunc(gd_cycle_date)
	       AND A.V_MASTER_CUSTOMER_NUMBER_R=J.V_MASTER_CUSTOMER_NUMBER_R
	      AND A.V_VAR_CROSS_SELL_R='N';
          ln_rec_cnt := ln_rec_cnt + SQL%ROWCOUNT;
	    END IF;
	COMMIT;
	END LOOP;

	    gt_end_time := SYSTIMESTAMP;
           gv_trcmsg:='15.1 Update V_VAR_CROSS_SELL_R ends.Total records updated : '||ln_rec_cnt;
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                    	=> gn_out_job_id
					,p_batch_id_r                  	=> gn_sysdt_batchid
					,p_message_type_r              	=> GV_MESSAGE_TYPE
					,p_code_location_r             	=> gv_main_loadedby
					,p_message_r                   	=> gv_trcmsg
					,p_count_type_r                	=> gv_count_type_upd
					,p_count_r                     	=> ln_rec_cnt
					,p_duration_r                  	=> FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
					,p_created_by_r                	=> gv_job_name
					,out_prcs_job_log_message_id_r 	=> gn_job_log_message_id
				);

    gv_trcmsg:='16.0 Update V_VAI_CROSS_SELL_R starts';
	gt_start_time := SYSTIMESTAMP;
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                     => gn_out_job_id
					,p_batch_id_r                   => gn_sysdt_batchid
					,p_message_type_r               => GV_MESSAGE_TYPE
					,p_code_location_r              => gv_main_loadedby
					,p_message_r                    => gv_trcmsg
					,p_count_type_r                 => gv_count_type_upd
					,p_count_r                      => NULL
					,p_duration_r                   => NULL
					,p_created_by_r                 => gv_job_name
					,out_prcs_job_log_message_id_r  => gn_job_log_message_id
				);

    -- Updating V_VAI_CROSS_SELL_R
    ln_rec_cnt := 0 ;
    FOR J IN (SELECT COUNT(1) CNT,V_MASTER_CUSTOMER_NUMBER_R
	            FROM ATOMIC.FCT_RPT_CROSS_SELL_SUMMARY_R   B
		       WHERE TRUNC(B.D_CYCLE_DATE_R)= trunc(gd_cycle_date)
		         AND B.V_VAI_CROSS_SELL_R='Y'
			 GROUP BY B.V_MASTER_CUSTOMER_NUMBER_R
			  )
	LOOP
	    IF J.CNT>0 THEN
	        UPDATE  ATOMIC.FCT_RPT_CROSS_SELL_SUMMARY_R  A
	          SET A.V_VAI_CROSS_SELL_R='Y'
	          WHERE  TRUNC(A.D_CYCLE_DATE_R)= trunc(gd_cycle_date)
	          AND A.V_MASTER_CUSTOMER_NUMBER_R=J.V_MASTER_CUSTOMER_NUMBER_R
	         AND A.V_VAI_CROSS_SELL_R='N';
             ln_rec_cnt := ln_rec_cnt + SQL%ROWCOUNT;
	    END IF;
	    COMMIT;
	END LOOP;


	    gt_end_time := SYSTIMESTAMP;
           gv_trcmsg:='16.1 Update V_VAI_CROSS_SELL_R ends.Total records updated : '||ln_rec_cnt;
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                    	=> gn_out_job_id
					,p_batch_id_r                  	=> gn_sysdt_batchid
					,p_message_type_r              	=> GV_MESSAGE_TYPE
					,p_code_location_r             	=> gv_main_loadedby
					,p_message_r                   	=> gv_trcmsg
					,p_count_type_r                	=> gv_count_type_upd
					,p_count_r                     	=> ln_rec_cnt
					,p_duration_r                  	=> FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
					,p_created_by_r                	=> gv_job_name
					,out_prcs_job_log_message_id_r 	=> gn_job_log_message_id
				);

    gv_trcmsg:='17.0 Update V_VCI_CROSS_SELL_R starts';
	gt_start_time := SYSTIMESTAMP;
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
					 p_job_id_r                     => gn_out_job_id
					,p_batch_id_r                   => gn_sysdt_batchid
					,p_message_type_r               => GV_MESSAGE_TYPE
					,p_code_location_r              => gv_main_loadedby
					,p_message_r                    => gv_trcmsg
					,p_count_type_r                 => gv_count_type_upd
					,p_count_r                      => NULL
					,p_duration_r                   => NULL
					,p_created_by_r                 => gv_job_name
					,out_prcs_job_log_message_id_r  => gn_job_log_message_id
				);

    -- Updating V_VCI_CROSS_SELL_R
    ln_rec_cnt := 0 ;
    FOR J IN (SELECT COUNT(1) CNT,V_MASTER_CUSTOMER_NUMBER_R
	            FROM ATOMIC.FCT_RPT_CROSS_SELL_SUMMARY_R   B
		       WHERE TRUNC(B.D_CYCLE_DATE_R)= trunc(gd_cycle_date)
		       AND B.V_VCI_CROSS_SELL_R='Y'
			GROUP BY B.V_MASTER_CUSTOMER_NUMBER_R
			)
	LOOP
	    IF J.CNT>0 THEN
	        UPDATE  ATOMIC.FCT_RPT_CROSS_SELL_SUMMARY_R  A
	          SET A.V_VCI_CROSS_SELL_R='Y'
	          WHERE  TRUNC(A.D_CYCLE_DATE_R)= trunc(gd_cycle_date)
	          AND A.V_MASTER_CUSTOMER_NUMBER_R=J.V_MASTER_CUSTOMER_NUMBER_R
	         AND A.V_VCI_CROSS_SELL_R='N';
             ln_rec_cnt := ln_rec_cnt + SQL%ROWCOUNT;
	    END IF;
	    COMMIT;
	END LOOP;

	    gt_end_time := SYSTIMESTAMP;
           gv_trcmsg:='17.1 Update V_VCI_CROSS_SELL_R ends.Total records updated : '||ln_rec_cnt;

		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(

					 p_job_id_r                    	=> gn_out_job_id
					,p_batch_id_r                  	=> gn_sysdt_batchid
					,p_message_type_r              	=> GV_MESSAGE_TYPE
					,p_code_location_r             	=> gv_main_loadedby
					,p_message_r                   	=> gv_trcmsg
					,p_count_type_r                	=> gv_count_type_upd
					,p_count_r                     	=> ln_rec_cnt
					,p_duration_r                  	=> FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
					,p_created_by_r                	=> gv_job_name
					,out_prcs_job_log_message_id_r 	=> gn_job_log_message_id
				);

    -- Comment Started the below updates due to performance issue. These columns are not being used in the report so far.
    --   When we are exposing that in the report ,we need to fix the performance issue of the update and then enable...   */
	/*END: NEW LOGGING MECHANISM CHANGES*/
 /* ELSE
	  gv_trcmsg:='1.2. The current date '||TO_DATE(LD_sysdate) ||' is NOT Fiscal Month End Date '||ld_fic_mis_date ||' , So data will not be loaded.';
      PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
            (	 p_job_id_r                    => gn_out_job_id
				,p_batch_id_r                  => gn_sysdt_batchid
				,p_message_type_r              => gv_message_type
				,p_code_location_r             => gv_main_loadedby
				,p_message_r                   => gv_trcmsg
				,p_count_type_r                => NULL
				,p_count_r                     => NULL
				,p_duration_r                  => NULL
				,p_created_by_r                => Gv_JOB_NAME
				,out_prcs_job_log_message_id_r => gn_job_log_message_id
				);
    END IF;*/
    gv_trcmsg :='9 Exit from main';

	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
            (	 p_job_id_r                    => gn_out_job_id
				,p_batch_id_r                  => gn_sysdt_batchid
				,p_message_type_r              => gv_message_type
				,p_code_location_r             => gv_main_loadedby
				,p_message_r                   => gv_trcmsg
				,p_count_type_r                => NULL
				,p_count_r                     => NULL
				,p_duration_r                  => NULL
				,p_created_by_r                => Gv_JOB_NAME
				,out_prcs_job_log_message_id_r => gn_job_log_message_id
				);
	/*END: NEW LOGGING MECHANISM CHANGES*/
     pkg_grp_log_util.prc_update_log
			  (   p_job_id  					=> gn_out_job_id
				 ,p_job_status					=> gv_success_status
				 ,p_err_msg						=> gv_errmsg
				 ,p_trc_msg						=> gv_trcmsg
				 ,p_log_util_called_by_r		=> gv_main_loadedby
			  );

EXCEPTION
WHEN OTHERS THEN
   gv_errmsg :=SUBSTR(SQLERRM,1,4000);
    gv_trcmsg:='1.Z Since Errir in the MAIN procedure hence deleting partial data loaded in the tbl FCT_RPT_CROSS_SELL_SUMMARY_R against cycle date :-'||gd_cycle_date||'-'||gv_errmsg;

	/*START: NEW LOGGING MECHANISM CHANGES*/
    pkg_grp_log_util.prc_update_log_message_r
			   (   n_prcs_job_log_message_id_r  => gn_job_log_message_id
				  ,p_err_msg                    => gv_trcmsg
					   );
    /*END: NEW LOGGING MECHANISM CHANGES*/
    DELETE FROM ATOMIC.FCT_RPT_CROSS_SELL_SUMMARY_R  WHERE TRUNC(TO_DATE(D_CYCLE_DATE_R))=TRUNC(TO_DATE(gd_cycle_date));
    commit;
    gv_errmsg :=SUBSTR(SQLERRM,1,4000);
    gv_trcmsg:=gc_trcmsg||'1. Error in main'||chr(13);
    pkg_grp_log_util.prc_update_log
			  (   p_job_id  					=> gn_out_job_id
				 ,p_job_status					=> gv_error_status
				 ,p_err_msg						=> gv_errmsg
				 ,p_trc_msg						=> gv_trcmsg
				 ,p_log_util_called_by_r		=> gv_main_loadedby
			  );

    RAISE;
END main;

END PKG_GRP_LOAD_FCT_RPT_CROSS_SELL_SUMMARY_R;

