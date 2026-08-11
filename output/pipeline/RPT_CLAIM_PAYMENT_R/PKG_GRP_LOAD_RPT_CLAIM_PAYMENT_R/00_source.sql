

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ATOMIC"."PKG_GRP_LOAD_RPT_CLAIM_PAYMENT_R"
IS
/***********************************************************************
  Purpose:  This package body contains procedures which loads data into RPT_CLAIM_PAYMENT_R
  Used DB Objects : vw_fct_claim_payment_detail_r_MV_ssl,dim_grp_party_dir_r,dim_grp_party_r,fct_grp_party_address_r
  Author     Date     Description
  ---------- -------- -------------------------------------------------
  VGireesh   10/11/23 Initial Creation
  VGireesh   04/01/24 Gather table stats added
  VGireesh   05/01/24 Added Privacy Indicator
  VGireesh   17/01/24 Converted normal View to vw_fct_claim_payment_detail_r_MV_ssl MV aNd N_PAYMENT_SK_R derived from MV
  VGireesh   18/01/24 Added procedure prc_rebuild_indexes
  VGireesh   23/01/24 Closed REF Cursor
  VGireesh   26/02/24 for month end  that the tables start loading data in the next month partition
                      Ex: March data on February 29th (as of 2.28).
                          27th is Feb Fisc Month End    202402  should be truncate and load in 202402 partition
                          28th is feb Fisc Month End +1 202402  should be truncate and load in 202402 partition
                          29th is Feb Fisc Month End +2 202403  should inactive records against the partition 202402 and load data in 202403 partition
  VGireesh   13/03/24 Added below columns
						          ,V_PAYEE_FIRST_NAME_R
                                  ,V_PAYEE_MIDDLE_NAME_R
                                  ,V_PAYEE_LAST_NAME_R
                                  ,V_PRIMARY_REINSURER_R
                                  ,V_SECONDARY_REINSURER_R
                                  ,V_TERNARY_REINSURER_R
                                  ,V_PAYMENT_RECORD_TYPE_R
                                  ,V_TAX_STATE_R
                                  ,CAST(NULL AS NUMBER) N_PAYEE_PARTY_SK_R
                                  ,CAST(NULL AS VARCHAR2(400)) V_PAYEE_ADDRESS_1_R
                                  ,CAST(NULL AS VARCHAR2(400)) V_PAYEE_ADDRESS_2_R
                                  ,CAST(NULL AS VARCHAR2(400)) V_PAYEE_ADDRESS_3_R
                                  ,CAST(NULL AS VARCHAR2(100)) V_PAYEE_CITY
                                  ,CAST(NULL AS VARCHAR2(100)) V_PAYEE_COUNTRY_R
                                  ,CAST(NULL AS DATE)          D_PAYEE_BIRTH_DATE_R
                                  ,CAST(NULL AS VARCHAR2(100)) V_PAYEE_GENDER_R
                                  ,CAST(NULL AS VARCHAR2(100)) V_CLAIM_PAYEE_SSN_R
                                  ,CAST(NULL AS VARCHAR2(100)) V_PAYEE_STATE_R
                                  ,CAST(NULL AS VARCHAR2(100)) V_CLAIM_PAYEE_TAX_ID_R
                                  ,CAST(NULL AS VARCHAR2(100)) V_PAYEE_ZIP_R
  VGireesh   19/03/24 increased bulk limit in spec and added logic to alter unusable PK index
  VGireesh   20/03/24  Commented Gather table stats to see the job completion time without gather table stats
  VGireesh   26/03/24  Payee columns remapping changes
  VGireesh   03/04/24 Added Parallel to rebuild index fast  parallel 16 nologging
  VGireesh   24/04/24 Added Max Source Seq Number while fetching data from fct_grp_party_address_r
  VGireesh   29/05/24 Below columns has been added to the RPT_CLAIM_PAYMENT_R
                     ,V_AMOUNT_TYPE_SUB_NAME_R,
                      V_AMOUNT_TYPE_CATEGORY_R,
                      V_AMOUNT_TYPE_CATEGORY_DESC_R,
                      V_AMOUNT_TYPE_SUB_CATEGORY_R,
                      V_AMT_TYPE_SUB_CATEGORY_DESC_R,
                      V_AMOUNT_TYPE_CODE_R,
                      V_AMOUNT_TYPE_NAME_R,
                      V_AMOUNT_TYPE_SUB_CODE_R
  Jagan 	 24/07/24 Added the column V_PAY_METHOD_R from Karthick
  Chandra    06/09/24 Logic change for V_TAX_STATE_R column
  Chnadra    09/09/24 Added New Col V_PAYEE_NAME_R
  Chnadra    17/09/24 Commented the procedure call PKG_GRP_LOAD_RPT_CLAIM_PAYMENT_R.prc_rebuild_indexes as this has been moved to another job
                      and below changes has been applied
					  --,SUBSTR(fct_claim_payment_detail_r.D_PAID_DATE_R,8)V_PAID_YEAR_R                                                                                          -- V_PAID_YEAR_R
                      ,TO_CHAR(fct_claim_payment_detail_r.D_PAID_DATE_R,'YYYY') V_PAID_YEAR_R

  Gireesh    04/11/24 Added wagebase related columns and in place of driving MV VW_FCT_CLAIM_PAYMENT_DETAIL_R_MV_SSL used new MV VW_RPT_CLAIM_PAYMENT_R_DRQ_MV_SSL
                      N_CHECK_WAGE_BASE_R                       NUMBER
                      N_CHECK_TAXABLE_BENEFIT_R                 number

  Shashi  13/03/2025 Added N_CLAIM_COVERAGE_SK_R Column in RPT_CLAIM_PAYMENT_R Table
  Samba		 21/05/25  Commented update flag = 'N' for Month End+2 Load.
 				   Added Truncate for Month End+2 Load
  Samba		 26/05/25  Added new logging Mechanism
  Suresh  24/06/2025 Added  V_DAY_PHONE_R , V_PAYMENT_STATUS_TYPE_R ,V_EMPLOYER_FICA_WAGE_BASE_R,
                            V_EMPLOYER_MEDICARE_WAGE_BASE_R Columns in RPT_CLAIM_PAYMENT_R Table.
  Samba   08/09/2025  Standardization of code
						1. Package with proper block comment,
						2. Procedure Naming Convention
						3. Moved all the global objects to Body
  Samba   09/09/2025 Global2Local Index conversion
  Samba	  12/05/2026 Kill/Fill Changes: User Story - 514604
					 	- All code changes are marked with Kill/Fill start and end comment blocks.
					 	- Code changes ensure continuous data availability in reports, replacing the current truncate-and-load approach, which is not partition-exchange based.
					 	- Retaining old code base of bulk collect load; which can be used when this Package to be converted to incremental processing
***********************************************************************/

--Global Constants
		gd_sysdate               DATE              								:= TRUNC(SYSDATE);
		gn_prior_month           NUMBER            								:= TO_NUMBER(TO_CHAR(ADD_MONTHS(TRUNC(gd_sysdate, 'MM'), -1),'YYYYMM'));
		gn_current_month         NUMBER            								:= TO_NUMBER(TO_CHAR(gd_sysdate,'YYYYMM'));
		gn_sysdt_batchid         NUMBER            								:= TO_NUMBER(TO_CHAR(gd_sysdate,'YYYYMMDD'));
		gc_main_loadedby         VARCHAR2(100 CHAR)								:='PKG_GRP_LOAD_RPT_CLAIM_PAYMENT_R.MAIN'      ;
		gc_updby                 VARCHAR2(100 CHAR)								:='PKG_GRP_LOAD_RPT_CLAIM_PAYMENT_R.PRC_UPD_DEL_DATA';
		gc_getcur_loadedby       VARCHAR2(100 CHAR)								:='PKG_GRP_LOAD_RPT_CLAIM_PAYMENT_R.PRC_GET_CUR_DATA';
		gc_truncpartby           VARCHAR2(100 CHAR)								:='PKG_GRP_LOAD_RPT_CLAIM_PAYMENT_R.PRC_TRUNC_PARTITION';
		gc_rebuildindexes        VARCHAR2(100 CHAR)								:='PKG_GRP_LOAD_RPT_CLAIM_PAYMENT_R.PRC_REBUILD_INDEXES';
		gc_trcmsg                CLOB              								:='Trace Message:->';
		GC_JOB_NAME              VARCHAR2(50 CHAR) 								:='GRP_LOAD_RPT_CLAIM_PAYMENT_R';
		gn_bulk_coll_cnt         NUMBER            								:=100000;
		gc_running_status        VARCHAR2(30)      								:='Running';
		gc_error_status          VARCHAR2(30)      								:='Error';
		gc_success_status        VARCHAR2(30)      								:='Success';
		gc_source                VARCHAR2(30)      								:='EDW';
		gc_rebuild_idx_degree	 NUMBER      									:=8;
		gn_out_job_id            NUMBER;
		gc_errmsg                VARCHAR2(4000 CHAR);
		gc_message_type_r 		 PRCS_JOB_LOG_MESSAGE_R.v_message_type_r%TYPE   := PKG_GRP_LOG_UTIL.gc_message_type_info;
		gc_count_type_r			 PRCS_JOB_LOG_MESSAGE_R.v_count_type_r%TYPE     := PKG_GRP_LOG_UTIL.gc_count_type_insert;
		gn_run_cnt          	 PRCS_JOB_LOG_MESSAGE_R.N_COUNT_R%TYPE 	 		:=0;
		gn_loop_counter_r  		 PRCS_JOB_LOG_MESSAGE_R.N_COUNT_R%TYPE 			:=0;
		gt_start_time_r			 TIMESTAMP;
		gt_end_time_r			 TIMESTAMP;
		gn_job_log_message_id_r	 NUMBER;
		gn_error_line 			 VARCHAR2(20);
		--Start: kill/fill additions
		gv_rpt_table_name        CONSTANT PRCS_JOB_LOG_R.V_JOB_NAME_R%TYPE	 := 'RPT_CLAIM_PAYMENT_R';
		gv_exg_table_name        CONSTANT PRCS_JOB_LOG_R.V_JOB_NAME_R%TYPE	 := gv_rpt_table_name||'_EXG';
		gv_schema_owner        	 CONSTANT PRCS_JOB_LOG_R.V_JOB_NAME_R%TYPE	 := 'ATOMIC';
		--End: kill/fill additions

--Main procedures calls other procedure to load data in RPT_CLEINT_DTL_R
PROCEDURE main
IS
	--Start: Commenting for kill/fill
	/*VAR_REF_CUR SYS_REFCURSOR;
	TYPE var_tbl_type IS TABLE OF RPT_CLAIM_PAYMENT_R%ROWTYPE INDEX BY BINARY_INTEGER;
	lt_var_tbl_typ var_tbl_type;*/

	ln_rec_cnt 			   NUMBER:=0;
	ld_fic_mis_date_2 	   DATE;
	ln_fisc_current_month  NUMBER;
	lv_main_table_name	   VARCHAR2(30)	:=	'RPT_CLAIM_PAYMENT_R';
	lv_exchange_table_name VARCHAR2(90)	:=	lv_main_table_name ||'_EXG';
	lv_partition_name	   VARCHAR2(200);

BEGIN

    --Call Log Util pkg to Insert entry in PRCS_JOB_LOG_R
			pkg_grp_log_util.prc_insert_log
					(
						 p_source               => gc_source
						,p_job_nm               => gc_job_name
						,p_job_status           => gc_running_status
						,p_err_msg              => null
						,p_trc_msg              => null
						,p_n_batch_id           => gn_sysdt_batchid
						,p_log_util_called_by_r => gc_main_loadedby
						,out_job_id             => gn_out_job_id
					);

    gc_trcmsg:='1. Entered into main. '||'gn_current_month:->'||gn_current_month|| ' - gn_prior_month:->'||gn_prior_month||'. SET PLSQL_OPTIMIZE_LEVEL=3';
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
			 (
				p_job_id_r                      => gn_out_job_id,
				p_batch_id_r                    => gn_sysdt_batchid,
				p_message_type_r                => gc_message_type_r,
				p_code_location_r               => gc_main_loadedby,
				p_message_r                     => gc_trcmsg,
				p_count_type_r                  => NULL,
				p_count_r                       => NULL,
				p_duration_r                    => NULL,
				p_created_by_r                  => GC_JOB_NAME,
				out_prcs_job_log_message_id_r   => gn_job_log_message_id_r
			);


	execute immediate 'ALTER SESSION SET PLSQL_OPTIMIZE_LEVEL=3';

    --PKG_GRP_LOAD_RPT_CLAIM_PAYMENT_R.prc_upd_del_data;

	---- Fetch month end+2 date and ln_fisc_current_month
			PKG_GRP_COMMON_UTIL.prc_fisc_month_calc
					(
						p_out_job_id           =>	gn_out_job_id,
						p_Log_seq_num          =>	2,
						ld_fic_mis_date_2      =>	ld_fic_mis_date_2,
						ln_fisc_current_month  =>	ln_fisc_current_month

					);


	---- Fetch Current and Prior Month values YYYYMM
			PKG_GRP_COMMON_UTIL.PRC_GET_CURRENT_PRIOR_MONTH
					(
						p_out_job_id           =>	gn_out_job_id,
						p_Log_seq_num          =>	3,
						P_fic_mis_date         =>	ld_fic_mis_date_2,
						P_fisc_current_month   =>	ln_fisc_current_month,
						p_current_month        =>	gn_current_month,
						p_prior_month          =>	gn_prior_month
					);

	--gn_current_month:= 202602;
	--gn_prior_month := 202601;

	lv_partition_name 	:=  'PART_' || lv_main_table_name || '_'|| gn_current_month;

	-- Start : Kill/Fill Changes 12th May 2026 	: Added New
	PKG_GRP_COMMON_UTIL.PRC_CREATE_EXCHANGE_TABLE_DDL
		(
			p_job_id            	=> gn_out_job_id,
			p_log_seq_num           => 4,
			p_main_table_name       => gv_rpt_table_name,
			p_exg_table_name        => gv_exg_table_name,
			p_schema_name           => gv_schema_owner
		);

	PKG_GRP_LOAD_RPT_CLAIM_PAYMENT_R.prc_get_cur_data;


	-- Start : commenting as part of Kill/Fill Changes 12th May 2026
	/*---- Truncate the current month partition
				PKG_GRP_COMMON_UTIL.prc_trunc_partition
						(
							p_out_job_id       =>	gn_out_job_id,
							p_Log_seq_num      =>	4,
							p_rpt_table        =>	lv_main_table_name,
							p_idx_num          =>	gc_rebuild_idx_degree,
							p_current_month    =>	gn_current_month
						);

    EXECUTE IMMEDIATE 'ALTER TABLE '||lv_main_table_name||' MODIFY PARTITION '||lv_partition_name||' UNUSABLE LOCAL INDEXES';

    gc_trcmsg:='5. Disable Local indexes for partition: ' || lv_partition_name;
    		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
			(
				p_job_id_r                    => gn_out_job_id,
				p_batch_id_r                  => gn_sysdt_batchid,
				p_message_type_r              => gc_message_type_r,
				p_code_location_r             => gc_main_loadedby,
				p_message_r                   => gc_trcmsg,
				p_count_type_r                => NULL,
				p_count_r                     => NULL,
				p_duration_r                  => NULL,
				p_created_by_r                => GC_JOB_NAME,
				out_prcs_job_log_message_id_r => gn_job_log_message_id_r
			);

	-- Loads the data into Exchange table which using source queries
    PKG_GRP_LOAD_RPT_CLAIM_PAYMENT_R.prc_get_cur_data (var_ref_cur);


    gc_trcmsg:='6. Data Load starts ';
    gt_start_time_r:= SYSTIMESTAMP;

	/*START: NEW LOGGING MECHANISM CHANGES*/
		/*PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
			(
				p_job_id_r                    => gn_out_job_id,
				p_batch_id_r                  => gn_sysdt_batchid,
				p_message_type_r              => gc_message_type_r,
				p_code_location_r             => gc_main_loadedby,
				p_message_r                   => gc_trcmsg,
				p_count_type_r                => NULL,
				p_count_r                     => NULL,
				p_duration_r                  => NULL,
				p_created_by_r                => GC_JOB_NAME,
				out_prcs_job_log_message_id_r => gn_job_log_message_id_r
			);

    gn_loop_counter_r := 1; -- Initialize loop counter
    gc_count_type_r:=PKG_GRP_LOG_UTIL.gc_count_type_insert;

    LOOP
		lt_var_tbl_typ.DELETE;
		FETCH var_ref_cur BULK COLLECT INTO  lt_var_tbl_typ LIMIT gn_bulk_coll_cnt;
		gt_start_time_r := SYSTIMESTAMP; -- Start timing before the insert

		FORALL x in lt_var_tbl_typ.First..lt_var_tbl_typ.Last
		INSERT /*+APPEND_VALUES*//*INTO RPT_CLAIM_PAYMENT_R VALUES lt_var_tbl_typ(x) ;
		COMMIT;

		gt_end_time_r := SYSTIMESTAMP; -- End timing after the insert

        LN_REC_CNT:=LN_REC_CNT+LT_VAR_TBL_TYP.COUNT;

		gc_trcmsg := '6.1 data load: Bulk Set-'|| gn_loop_counter_r ||': '||LN_REC_CNT||' records loaded' ;
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
			(
				p_job_id_r 					  => gn_out_job_id,
				p_batch_id_r 				  => gn_sysdt_batchid,
				p_message_type_r 			  => gc_message_type_r,
				p_code_location_r 			  => gc_main_loadedby,
				p_message_r 				  => gc_trcmsg,
				p_count_type_r 				  => gc_count_type_r,
				p_count_r 					  => gn_bulk_coll_cnt,
				p_duration_r 				  => FNC_GRP_TIME_DURATION(gt_start_time_r,gt_end_time_r),
				p_created_by_r 				  => GC_JOB_NAME,
				out_prcs_job_log_message_id_r => gn_job_log_message_id_r
			);

        gn_loop_counter_r:= gn_loop_counter_r + 1;

        EXIT WHEN var_ref_cur%NOTFOUND;
    END LOOP;

    CLOSE var_ref_cur;--23-Jan-2024 Changes

    gc_trcmsg:='6.z Data Loaded '||ln_rec_cnt||' records ';

	/*START: NEW LOGGING MECHANISM CHANGES*/
		/*gt_end_time_r:= SYSTIMESTAMP;

		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
			 (
				p_job_id_r                    => gn_out_job_id,
				p_batch_id_r                  => gn_sysdt_batchid,
				p_message_type_r              => gc_message_type_r,
				p_code_location_r             => gc_main_loadedby,
				p_message_r                   => gc_trcmsg,
				p_count_type_r                => gc_count_type_r,
				p_count_r                     => ln_rec_cnt,
				p_duration_r                  => FNC_GRP_TIME_DURATION(gt_start_time_r,gt_end_time_r),
				p_created_by_r                => GC_JOB_NAME,
				out_prcs_job_log_message_id_r => gn_job_log_message_id_r
			);

 	gc_trcmsg:='7.1 Call procedure prc_insert_dummy_rec from main';
	/*START: NEW LOGGING MECHANISM CHANGES*/
	/*	gt_start_time_r:= SYSTIMESTAMP;

		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
			 (
				p_job_id_r                    => gn_out_job_id,
				p_batch_id_r                  => gn_sysdt_batchid,
				p_message_type_r              => gc_message_type_r,
				p_code_location_r             => gc_main_loadedby,
				p_message_r                   => gc_trcmsg,
				p_count_type_r                => NULL,
				p_count_r                     => NULL,
				p_duration_r                  => NULL,
				p_created_by_r                => GC_JOB_NAME,
				out_prcs_job_log_message_id_r => gn_job_log_message_id_r
			);

    PKG_GRP_LOAD_RPT_CLAIM_PAYMENT_R.prc_insert_dummy_rec;

    gc_trcmsg:='7.2 Completed Procedure prc_insert_dummy_rec call from main';

	gt_end_time_r:= SYSTIMESTAMP;
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
			 (
				p_job_id_r                    => gn_out_job_id,
				p_batch_id_r                  => gn_sysdt_batchid,
				p_message_type_r              => gc_message_type_r,
				p_code_location_r             => gc_main_loadedby,
				p_message_r                   => gc_trcmsg,
				p_count_type_r                => gc_count_type_r,
				p_count_r                     => 1,
				p_duration_r                  => FNC_GRP_TIME_DURATION(gt_start_time_r,gt_end_time_r),
				p_created_by_r                => GC_JOB_NAME,
				out_prcs_job_log_message_id_r => gn_job_log_message_id_r
			);	*/
	-- End : commenting as part of Kill/Fill Changes 12th May 2026

	-- Start : Kill/Fill Changes 12th May 2026 	: Added New
	-- Partition Exchange Common Utility Called to Move data from Exg table to the Main table Current month Partition
	PKG_GRP_COMMON_UTIL.PRC_PARTITION_EXCHANGE
	(
		p_job_id            	=> gn_out_job_id,
		p_log_seq_num           => 6,
		p_main_table_name       => gv_rpt_table_name,
		p_exg_table_name        => gv_exg_table_name,
		p_partition_name        => 'PART_'|| gv_rpt_table_name ||'_'||gn_current_month,
		p_schema_name           => gv_schema_owner
	);

	-- Rebuild Index for a partition whcih has been truncate and loaded

	PKG_GRP_COMMON_UTIL.prc_rebuild_index_partitions
			(
				p_table_name   		  		  => lv_main_table_name,
				p_parallel_degree   		  => 7,
				p_partition_name  		  	  => lv_partition_name,
				p_out_job_id              	  => gn_out_job_id,
				p_Log_seq_num             	  => 8

			);

	gc_trcmsg:='1.z Exit from main';
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
			 (
				p_job_id_r                    => gn_out_job_id,
				p_batch_id_r                  => gn_sysdt_batchid,
				p_message_type_r              => gc_message_type_r,
				p_code_location_r             => gc_main_loadedby,
				p_message_r                   => gc_trcmsg,
				p_count_type_r                => NULL,
				p_count_r                     => NULL,
				p_duration_r                  => NULL,
				p_created_by_r                => GC_JOB_NAME,
				out_prcs_job_log_message_id_r => gn_job_log_message_id_r
			);

    pkg_grp_log_util.prc_update_log
		  (
			 gn_out_job_id                   --p_job_id
			,gc_success_status              --p_job_status
			,gc_errmsg                      --p_err_msg
			,gc_trcmsg                      --p_trc_msg
			,gc_main_loadedby               --p_log_util_called_by_r
		  );

EXCEPTION
WHEN OTHERS THEN
    gc_errmsg :=SUBSTR(SQLERRM,1,4000);
    gc_trcmsg:='1. Error in main - '||gc_errmsg;

	/*START: NEW LOGGING MECHANISM CHANGES*/
    pkg_grp_log_util.prc_update_log_message_r
			(
				n_prcs_job_log_message_id_r => gn_job_log_message_id_r,
				p_err_msg => gc_trcmsg
			);

    pkg_grp_log_util.prc_update_log
      (
         gn_out_job_id                   --p_job_id
        ,gc_error_status                 --p_job_status
        ,gc_errmsg                       --p_err_msg
        ,gc_trcmsg					     --p_trc_msg
        ,gc_main_loadedby                --p_log_util_called_by_r
      );
    RAISE;
END main;

--Procedure to perform ref cursor assignment
PROCEDURE prc_get_cur_data
		--(p_out_cursor OUT SYS_REFCURSOR) -- commented as part of Kill Fill process
AS
BEGIN
    gc_trcmsg:='5.1 Entered into prc_get_cur_data ';

	/*START: NEW LOGGING MECHANISM CHANGES*/
    gt_start_time_r:= SYSTIMESTAMP;

		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
			 (
				p_job_id_r                    => gn_out_job_id,
				p_batch_id_r                  => gn_sysdt_batchid,
				p_message_type_r              => gc_message_type_r,
				p_code_location_r             => gc_main_loadedby,
				p_message_r                   => gc_trcmsg,
				p_count_type_r                => NULL,
				p_count_r                     => NULL,
				p_duration_r                  => NULL,
				p_created_by_r                => GC_JOB_NAME,
				out_prcs_job_log_message_id_r => gn_job_log_message_id_r
			);

	-- Start : Kill/Fill Changes 12th May 2026
		EXECUTE IMMEDIATE 'ALTER SESSION ENABLE PARALLEL DML';
	-- End : Kill/Fill Changes 12th May 2026

	-- Start : Kill/Fill Changes 12th May 2026: Commented following

	--Open/Assign SELECT stmnt
    --OPEN p_out_cursor FOR
	-- End : Kill/Fill Changes 12th May 2026 : Commented following

	gc_trcmsg := '5.2 - Data load starts for _EXG table for Partition Exchange';
		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
				( p_job_id_r                    => gn_out_job_id
				 ,p_batch_id_r                  => gn_sysdt_batchid
				 ,p_message_type_r              => gc_message_type_r
				 ,p_code_location_r             => gc_main_loadedby
				 ,p_message_r                   => gc_trcmsg
				 ,p_count_type_r                => NULL
				 ,p_count_r                     => NULL
				 ,p_duration_r                  => NULL
				 ,p_created_by_r                => gc_job_name
				 ,out_prcs_job_log_message_id_r => gn_job_log_message_id_r
				);

    -- Start : Kill/Fill Changes 12th May 2026: Added following

	INSERT /*+ APPEND PARALLEL(stg, 8) */ INTO RPT_CLAIM_PAYMENT_R_EXG stg
	SELECT /*+ PARALLEL(8) */
         CASE
			WHEN FCPD.V_PAY_METHOD_R = 'ACH'
			THEN 'Y'
			ELSE 'N'
		 END  																		AS V_ACH_PAYMENT_IND_R
        ,FCPD.D_CHECK_DATE_R														AS D_CHECK_DATE_R
        ,FCPD.V_CHECK_NUMBER_R														AS V_CHECK_NUMBER_R
        ,SUBSTR(FCPD.V_PAYMENT_STATUS_R,1,1) 										AS V_CHECK_STATUS_R
        ,FCPD.V_PAYMENT_STATUS_R 													AS V_CHECK_STATUS_DESC_R
        ,FCPD.V_CHECK_TYPE_R 														AS V_CHECK_TYPE_R
        ,CAST(NULL AS VARCHAR2(140))  												AS V_CLAIM_PAYMENT_ADDRESS_LINE_1_R
		,CAST(NULL AS VARCHAR2(140))  												AS V_CLAIM_PAYMENT_ADDRESS_LINE_2_R
		,CAST(NULL AS VARCHAR2(140))  												AS V_CLAIM_PAYMENT_ADDRESS_LINE_3_R
		,CAST(NULL AS VARCHAR2(60))   												AS V_CLAIM_PAYMENT_CITY_R
		,FCPD.D_PAID_DATE_R  														AS D_PAID_DATE_R
		,TO_CHAR(FCPD.D_PAID_DATE_R,'YYYY') 										AS V_PAID_YEAR_R
		,FCPD.D_SERVICE_PERIOD_FROM_R												AS D_SERVICE_PERIOD_FROM_R
		,FCPD.D_SERVICE_PERIOD_TO_R													AS D_SERVICE_PERIOD_TO_R
        ,FCPD.V_PAYMENT_TYPE_R														AS V_PAYMENT_TYPE_R
		,CAST(NULL AS VARCHAR2(30)) 												AS V_POSTAL_ZIP_R
		,CAST(NULL AS DATE) 														AS D_PAYMENT_DATE_R
		,CAST(NULL AS VARCHAR2(40))   												AS V_CUSTOMER_PAYEE_MAIL_COUNTRY_R
		,CAST(NULL AS VARCHAR2(30))  												AS V_CUSTOMER_PAYEE_MAIL_STATE_R
		,CAST(NULL AS VARCHAR2(100)) 												AS V_PAYMENT_EXAMINER_LOGIN_ID_R
		,CAST(NULL AS VARCHAR2(100)) 												AS V_PAYMENT_EXAMINER_NAME_R
		,FCPD.V_PAYMENT_STATUS_R  													AS V_PAYMENT_STATUS_R
		,CAST(NULL AS VARCHAR2(20))  												AS V_CLAIM_PAYMENT_STATE_R
		,CAST(NULL AS date)  														AS D_BENEFIT_DTL_PAYMENT_DATE_R
		,(
			select DIM_TIME_R.N_FISCAL_MONTH_R
			from DIM_TIME_R
			where D_CALENDAR_DATE_R= FCPD.D_PAID_DATE_R
		) 																			AS N_CLAIM_PAID_FISCAL_MONTH_R
        ,(
			select DIM_TIME_R.N_FISCAL_YEAR_R
			from DIM_TIME_R
			where D_CALENDAR_DATE_R= FCPD.D_PAID_DATE_R
		) 																			AS N_CLAIM_PAID_FISCAL_YEAR_R
        ,FCPD.V_PAYEE_TYPE_R
		,FCPD.V_BENEFIT_CATEGORY_R  												AS V_BENEFIT_CATEGORY_R
		,FCPD.V_BENEFIT_CODE_R 														AS V_BENEFIT_CODE_R
		,FCPD.V_RECORD_TYPE_R   													AS V_RECORD_TYPE_R
		,FCPD.V_BENEFIT_DESCRIPTION_R  												AS V_BENEFIT_DESCRIPTION_R
		,FCPD.V_BENEFIT_GROUP_R  													AS V_BENEFIT_GROUP_R
		,FCPD.N_SEQUENCE_NUMBER_R  													AS N_SEQUENCE_NUMBER_R
		,FCPD.N_SOURCE_VERSION_SEQ_NUMBER_R  										AS N_SOURCE_VERSION_SEQ_NUMBER_R
		,FCPD.N_PAYMENT_SK_R 														AS N_PAYMENT_SK_R
		,gc_main_loadedby                                                   		AS v_last_modified_by_r
		,systimestamp                                                       		AS t_creation_date_r
		,gc_main_loadedby                                                   		AS v_created_by_r
		,systimestamp                                                       		AS t_last_modified_date_r
		,GN_CURRENT_MONTH                                                   		AS N_YEARMONTH_R
		,'Y' 																		AS v_rpt_active_status_r
        ,gn_sysdt_batchid  															AS n_batch_id_r
		,CAST(FCPD.N_CLAIM_SK_R AS NUMBER) 											AS N_CLAIM_SK_R
		,CAST(FCPD.N_SOURCE_SYSTEM_KEY_R AS NUMBER) 								AS N_SOURCE_SYSTEM_KEY_R
		,FCPD.v_privacy_indicator_r  												AS v_privacy_indicator_r
		,CAST(NULL AS VARCHAR2(100)) 												AS V_PAYMENT_EXAMINER_LOGIN_NAME_R
		,FCPD.V_PAYEE_FIRST_NAME_R		                                            AS V_PAYEE_FIRST_NAME_R
		,FCPD.V_PAYEE_MIDDLE_NAME_R		                                            AS V_PAYEE_MIDDLE_NAME_R
		,FCPD.V_PAYEE_LAST_NAME_R		                                            AS V_PAYEE_LAST_NAME_R
		,FCPD.V_PRIMARY_REINSURER_R		                                            AS V_PRIMARY_REINSURER_R
		,FCPD.V_SECONDARY_REINSURER_R		                                        AS V_SECONDARY_REINSURER_R
		,FCPD.V_TERNARY_REINSURER_R		                                            AS V_TERNARY_REINSURER_R
		,FCPD.V_PAYMENT_RECORD_TYPE_R		                                        AS V_PAYMENT_RECORD_TYPE_R

		,	case
				when FCPD.v_lob_type_r = 'ANNUITY'
				then c.V_STATE_NAME_R
				else FCPD.V_TAX_STATE_R
			end 																	AS V_TAX_STATE_R

        ,FCPD.N_PAYEE_PARTY_SK_R
		,c.V_ADDRESSLINE1_R                                              			AS V_PAYEE_ADDRESS_1_R
        ,c.V_ADDRESSLINE2_R                                              			AS V_PAYEE_ADDRESS_2_R
        ,c.V_ADDRESSLINE3_R                                              			AS V_PAYEE_ADDRESS_3_R
        ,c.V_CITY_R                                                     			AS V_PAYEE_CITY
        ,c.V_COUNTRY_R                                                 				AS V_PAYEE_COUNTRY_R
        ,d.D_BIRTH_DATE_R                                                   		AS D_PAYEE_BIRTH_DATE_R
        ,d.V_GENDER_R                                                       		AS V_PAYEE_GENDER_R
        ,d.V_TAX_NUMBER_R                                                   		AS V_CLAIM_PAYEE_SSN_R
        ,c.V_STATE_NAME_R                                                   		AS V_PAYEE_STATE_R
        ,d.V_TAX_NUMBER_R                                                   		AS V_CLAIM_PAYEE_TAX_ID_R
        ,c.V_POSTAL_ZIP_R                                                   		AS V_PAYEE_ZIP_R
        --29-May-2024 changes starts
		,FCPD.V_AMOUNT_TYPE_SUB_NAME_R                                              AS V_AMOUNT_TYPE_SUB_NAME_R
        ,FCPD.V_AMOUNT_TYPE_CATEGORY_R                                              AS V_AMOUNT_TYPE_CATEGORY_R
        ,FCPD.V_AMOUNT_TYPE_CATEGORY_DESC_R                                         AS V_AMOUNT_TYPE_CATEGORY_DESC_R
        ,FCPD.V_AMOUNT_TYPE_SUB_CATEGORY_R                                          AS V_AMOUNT_TYPE_SUB_CATEGORY_R
        ,FCPD.V_AMT_TYPE_SUB_CATEGORY_DESC_R                                        AS V_AMT_TYPE_SUB_CATEGORY_DESC_R
        ,FCPD.V_AMOUNT_TYPE_CODE_R                                                  AS V_AMOUNT_TYPE_CODE_R
        ,FCPD.V_AMOUNT_TYPE_NAME_R                                                  AS V_AMOUNT_TYPE_NAME_R
        ,FCPD.V_AMOUNT_TYPE_SUB_CODE_R                                              AS V_AMOUNT_TYPE_SUB_CODE_R
		,FCPD.V_PAY_METHOD_R 														AS V_PAY_METHOD_R
          --09-09-24 changes start
		 ,	CASE
				WHEN 	FCPD.V_PAYEE_LAST_NAME_R IS NULL
					AND FCPD.V_PAYEE_FIRST_NAME_R IS NULL
					AND FCPD.V_PAYEE_MIDDLE_NAME_R  IS NULL
				THEN NULL
				WHEN 	FCPD.V_PAYEE_FIRST_NAME_R  IS NULL
					AND FCPD.V_PAYEE_LAST_NAME_R IS NOT NULL
					AND FCPD.V_PAYEE_MIDDLE_NAME_R IS NOT NULL
				THEN  FCPD.V_PAYEE_LAST_NAME_R ||',' || FCPD.V_PAYEE_LAST_NAME_R
				WHEN  FCPD.V_PAYEE_LAST_NAME_R   IS NULL
					AND FCPD.V_PAYEE_FIRST_NAME_R   IS NOT NULL
					AND FCPD.V_PAYEE_MIDDLE_NAME_R IS NOT NULL
				THEN FCPD.V_PAYEE_MIDDLE_NAME_R ||','|| FCPD.V_PAYEE_FIRST_NAME_R
				WHEN FCPD.V_PAYEE_MIDDLE_NAME_R IS NULL
					AND FCPD.V_PAYEE_FIRST_NAME_R IS NOT NULL
					AND FCPD.V_PAYEE_LAST_NAME_R   IS NOT NULL
				THEN FCPD.V_PAYEE_LAST_NAME_R||','|| FCPD.V_PAYEE_FIRST_NAME_R
				WHEN FCPD.V_PAYEE_FIRST_NAME_R IS NULL
					AND   FCPD.V_PAYEE_LAST_NAME_R  IS NULL
					AND   FCPD.V_PAYEE_MIDDLE_NAME_R IS NOT NULL
				THEN   FCPD.V_PAYEE_MIDDLE_NAME_R
				WHEN FCPD.V_PAYEE_LAST_NAME_R IS NULL
					AND FCPD.V_PAYEE_MIDDLE_NAME_R IS NULL
					AND FCPD.V_PAYEE_FIRST_NAME_R IS NOT NULL
				THEN FCPD.V_PAYEE_FIRST_NAME_R
				WHEN FCPD.V_PAYEE_MIDDLE_NAME_R IS NULL
					AND  FCPD.V_PAYEE_FIRST_NAME_R  IS NULL
					AND  FCPD.V_PAYEE_LAST_NAME_R IS NOT NULL
				THEN FCPD.V_PAYEE_LAST_NAME_R
			ELSE
					FCPD.V_PAYEE_LAST_NAME_R ||','||
					FCPD.V_PAYEE_MIDDLE_NAME_R  ||',' ||
					FCPD.V_PAYEE_FIRST_NAME_R
			END 																AS V_PAYEE_NAME_R

		---09-09-24 changes ends
		,N_CHECK_WAGE_BASE_R 													AS N_CHECK_WAGE_BASE_R
        ,N_CHECK_TAXABLE_BENEFIT_R												AS N_CHECK_TAXABLE_BENEFIT_R
        ,FCPD.V_HASH_KEY_R														AS V_HASH_KEY_R
        ,FCPD.n_claim_coverage_sk_r												AS n_claim_coverage_sk_r
         --24-06-2025 addition start as per FDM reqt
        , D.V_DAY_PHONE_R 														AS V_DAY_PHONE_R

        , CASE
			WHEN FCPD.V_PAYMENT_STATUS_R = 'PAID'
			then 'PAID'
			WHEN FCPD.V_PAYMENT_STATUS_R = 'VOID'
			then  'VOIDED'
			WHEN FCPD.V_PAYMENT_STATUS_R = 'R'
			then 'REIMBURSEMENT'
          ELSE NULL
          END  																	AS V_PAYMENT_STATUS_TYPE_R

        , '0' 																	AS V_EMPLOYER_FICA_WAGE_BASE_R
        , '0' 																	AS V_EMPLOYER_MEDICARE_WAGE_BASE_R
        --24-06-2025 addition start as per FDM reqt
    from
       --VW_RPT_CLAIM_PAYMENT_R_DRQ_MV_SSL FCPD   --04/11/24 changes
		(
			SELECT
				MV.N_CLAIM_SK_R, MV.N_CLAIM_COVERAGE_SK_R, MV.N_CLAIM_COVERAGE_GROUP_SK_R, MV.V_CLAIM_NUMBER_R, MV.V_COVERAGE_CODE_R
				, MV.V_COV_GROUP_ID_R, MV.V_CHECK_NUMBER_R, MV.V_PAY_METHOD_R, MV.V_BENEFIT_CODE_R, MV.V_BENEFIT_DESCRIPTION_R
				, MV.V_BENEFIT_GROUP_R, MV.N_GROSS_WAGE_BASE_R, MV.N_TAXABLE_PERCENT_R, MV.V_PAYMENT_STATUS_R, MV.N_PAID_AMOUNT_R
				, MV.V_PAYMENT_TYPE_R, MV.D_CHECK_DATE_R, MV.V_CHECK_TYPE_R, MV.D_PAID_DATE_R, MV.N_GROSS_AMOUNT_R
				, MV.D_SERVICE_PERIOD_FROM_R, MV.D_SERVICE_PERIOD_TO_R, MV.V_RECORD_TYPE_R, MV.N_WORKSHEET_OBJECT_NUM_R
				, MV.N_SOURCE_SYSTEM_KEY_R, MV.N_SOURCE_VERSION_SEQ_NUMBER_R, MV.N_SEQ_R, MV.N_GROUP_SEQ_R, MV.N_PARENT_OBJECTNUM_R
				, MV.N_LOAD_RUN_ID_R, MV.T_EVENT_TIMESTAMP_R, MV.FIC_MIS_DATE_R, MV.N_BATCH_ID_R, MV.N_SEQUENCE_NUMBER_R
				, MV.T_CREATION_DATE_R, MV.T_LAST_MODIFIED_DATE_R, MV.V_CREATED_BY_R, MV.V_LAST_MODIFIED_BY_R, MV.V_BENEFIT_CATEGORY_R
				, MV.N_PAID_CLAIM_BENEFITS_R, MV.N_TAXABLE_BENEFIT_AMT_R, MV.N_FEDERAL_TAX_WITHHELD_AMT_R, MV.N_STATE_TAX_WITHHELD_AMT_R
				, MV.N_EMPLOYEE_SS_WITHHELD_AMT_R, MV.N_EMPLOYEE_MED_WITHHELD_AMT_R, MV.N_EMPLOYER_SS_WITHHELD_AMT_R
				, MV.N_EMPLOYER_MED_WITHHELD_AMT_R, MV.N_LEGAL_EXPENSE_DIRECT_AMT_R, MV.N_OTHER_EXPENSE_DIRECT_AMT_R
				, MV.V_LOB_TYPE_R, MV.N_MODAL_AMOUNT_R, MV.N_PRIMARY_PAYEE_R, MV.N_ADJ_GROSS_BENEFIT_R, MV.N_PAY_AMOUNT_R
				, MV.V_PRIVACY_INDICATOR_R, MV.V_GROSS_BENEFIT_CODE_R, MV.N_SS_WAGE_BASE_R, MV.N_MED_WAGE_BASE_R, MV.N_PAYMENT_SK_R
				, MV.V_PAYEE_FIRST_NAME_R, MV.V_PAYEE_MIDDLE_NAME_R, MV.V_PAYEE_LAST_NAME_R, MV.V_PAYEE_TYPE_R
				, MV.V_PRIMARY_REINSURER_R, MV.V_SECONDARY_REINSURER_R, MV.V_TERNARY_REINSURER_R, MV.N_PRIMARY_REINSURER_REINS_SHARE_PCT_R
				, MV.N_SECONDARY_REINSURER_REINS_SHARE_PCT_R, MV.N_TERNARY_REINSURER_REINS_SHARE_PCT_R
				, MV.N_PRIMARY_REINSURER_REINSURANCE_PCT_R, MV.N_SECONDARY_REINSURER_REINSURANCE_PCT_R
				, MV.N_TERNARY_REINSURER_REINSURANCE_PCT_R, MV.N_TOTAL_REINSURANCE_PCT_R, MV.V_PAYMENT_RECORD_TYPE_R
				, MV.V_TAX_STATE_R, MV.N_PAYEE_PARTY_SK_R, MV.V_SOURCE_SYSTEM_NAME_R, MV.V_AMOUNT_TYPE_SUB_NAME_R
				, MV.V_AMOUNT_TYPE_CATEGORY_R, MV.V_AMOUNT_TYPE_CATEGORY_DESC_R, MV.V_AMOUNT_TYPE_SUB_CATEGORY_R
				, MV.V_AMT_TYPE_SUB_CATEGORY_DESC_R, MV.V_AMOUNT_TYPE_CODE_R, MV.V_AMOUNT_TYPE_NAME_R
				, MV.V_AMOUNT_TYPE_SUB_CODE_R, MV.N_CLAIM_PAID_LOSS_AMOUNT_R
				,(SELECT SUM(WAGEBASE.N_CHECK_TAXABLE_BENEFIT_R)
				   FROM VW_FCT_CLAIM_PAYMENT_DETAIL_R_MV_SSL_WAGEBASE_INC WAGEBASE
				   WHERE
					   WAGEBASE.D_SERVICE_PERIOD_FROM_R = MV.D_SERVICE_PERIOD_FROM_R
					AND WAGEBASE.D_SERVICE_PERIOD_TO_R   = MV.D_SERVICE_PERIOD_TO_R
					AND WAGEBASE.V_BENEFIT_CODE_R        = MV.V_BENEFIT_CODE_R
					AND WAGEBASE.V_CHECK_NUMBER_R        = MV.V_CHECK_NUMBER_R
					AND WAGEBASE.V_CLAIM_NUMBER_R        = MV.V_CLAIM_NUMBER_R
					AND WAGEBASE.N_CLAIM_SK_R            = MV.N_CLAIM_SK_R
					AND WAGEBASE.D_CHECK_DATE_R          = MV.D_CHECK_DATE_R
					AND WAGEBASE.D_PAID_DATE_R           = MV.D_PAID_DATE_R
				  ) N_CHECK_TAXABLE_BENEFIT_R
				,(SELECT SUM(WAGEBASE.N_CHECK_WAGE_BASE_R)
				   FROM VW_FCT_CLAIM_PAYMENT_DETAIL_R_MV_SSL_WAGEBASE_INC WAGEBASE
				   WHERE
					   WAGEBASE.D_SERVICE_PERIOD_FROM_R = MV.D_SERVICE_PERIOD_FROM_R
					AND   WAGEBASE.D_SERVICE_PERIOD_TO_R   = MV.D_SERVICE_PERIOD_TO_R
					AND   WAGEBASE.V_BENEFIT_CODE_R        = MV.V_BENEFIT_CODE_R
					AND   WAGEBASE.V_CHECK_NUMBER_R        = MV.V_CHECK_NUMBER_R
					AND   WAGEBASE.V_CLAIM_NUMBER_R        = MV.V_CLAIM_NUMBER_R
					AND   WAGEBASE.N_CLAIM_SK_R            = MV.N_CLAIM_SK_R
					AND   WAGEBASE.D_CHECK_DATE_R          = MV.D_CHECK_DATE_R
					AND   WAGEBASE.D_PAID_DATE_R           = MV.D_PAID_DATE_R
				  ) N_CHECK_WAGE_BASE_R
				,MV.V_HASH_KEY_R
			FROM VW_FCT_CLAIM_PAYMENT_DETAIL_R_MV_SSL_INC MV
		) FCPD

	--26-Mar-2024 changes starts
	left join dim_grp_party_dir_r b
		on FCPD.n_payee_party_sk_r = b.n_party_sk_r
		and b.v_active_status_r = 'Y'
	left join dim_grp_party_r d
		on b.n_party_sk_r = d.n_party_sk_r
		and b.n_source_version_number_r = d.n_source_version_number_r
		and d.v_active_status_r = 'Y'
	left join
	(
		select * from fct_grp_party_address_r c
		where
				c.v_location_id_r = 'MAIN'
			and c.n_party_sk_r <> -1
			and c.v_source_system_name_r = 'PACS'
			and
			c.N_SOURCE_VERSION_SEQ_NUMBER_R
			in (
				select max(C1.N_SOURCE_VERSION_SEQ_NUMBER_R)
				from FCT_GRP_PARTY_ADDRESS_R C1
				where C1.V_LOCATION_ID_R = 'MAIN'
				and C1.N_PARTY_SK_R <> -1
				and C1.V_SOURCE_SYSTEM_NAME_R = 'PACS'
				and c1.N_PARTY_SK_R=c.N_PARTY_SK_R
				and C1.N_SOURCE_VERSION_NUMBER_R=C.N_SOURCE_VERSION_NUMBER_R
				)
	) c
	on b.n_party_sk_r = c.n_party_sk_r
	and b.n_source_version_number_r = c.n_source_version_number_r
	--fetch first 101 rows only
    ;

	gn_run_cnt:= SQL%ROWCOUNT;
  COMMIT;

	-- Start : Kill/Fill Changes 12th May 2026: Commented following

	EXECUTE IMMEDIATE 'ALTER SESSION DISABLE PARALLEL DML';
	-- End : Kill/Fill Changes 12th May 2026

	gc_trcmsg:='5.3 Exit from prc_get_cur_data';

	gc_count_type_r:=PKG_GRP_LOG_UTIL.gc_count_type_insert;

	/*START: NEW LOGGING MECHANISM CHANGES*/
	gt_end_time_r:= SYSTIMESTAMP;

	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
			 (
				p_job_id_r                    => gn_out_job_id,
				p_batch_id_r                  => gn_sysdt_batchid,
				p_message_type_r              => gc_message_type_r,
				p_code_location_r             => gc_getcur_loadedby,
				p_message_r                   => gc_trcmsg,
				p_count_type_r                => gc_count_type_r,
				p_count_r                     => gn_run_cnt,
				p_duration_r                  => FNC_GRP_TIME_DURATION(gt_start_time_r,gt_end_time_r),
				p_created_by_r                => GC_JOB_NAME,
				out_prcs_job_log_message_id_r => gn_job_log_message_id_r
			);


EXCEPTION
WHEN OTHERS THEN
    gc_errmsg :=SUBSTR(SQLERRM,1,4000);
    gc_trcmsg:='5.z Error in prc_get_cur_data - '||gc_errmsg;

	/*START: NEW LOGGING MECHANISM CHANGES*/
        pkg_grp_log_util.prc_update_log_message_r
			(
				n_prcs_job_log_message_id_r => gn_job_log_message_id_r,
				p_err_msg 					=> gc_trcmsg
			);

		pkg_grp_log_util.prc_update_log
          (
             gn_out_job_id                   --p_job_id
            ,gc_error_status                 --p_job_status
            ,gc_errmsg                       --p_err_msg
            ,gc_trcmsg 						 --p_trc_msg
            ,gc_getcur_loadedby              --p_log_util_called_by_r
          );
    RAISE;
END prc_get_cur_data;

--Procedure to insert dummy record in the table RPT_CLAIM_PAYMENT_R
PROCEDURE prc_insert_dummy_rec
IS
BEGIN

	INSERT /*+APPEND*/ INTO  RPT_CLAIM_PAYMENT_R
		   (
		    v_last_modified_by_r
           ,t_creation_date_r
           ,v_created_by_r
           ,t_last_modified_date_r
           ,n_yearmonth_r
           ,v_rpt_active_status_r
           ,n_batch_id_r
		   --,N_PAYMENT_SK_R
		   ,N_PAYMENT_SK_R
		      )
		VALUES(gc_main_loadedby
		  ,systimestamp
		  ,gc_main_loadedby
		  ,systimestamp
		  ,gn_current_month
		  ,'Y'
		  ,gn_sysdt_batchid
          ,-1			--N_PAYMENT_SK_R

		  );
    COMMIT;

EXCEPTION
WHEN OTHERS THEN
    gc_errmsg :=SUBSTR(SQLERRM,1,4000);
    gc_trcmsg:='6.z Error in prc_insert_dummy_rec - '||gc_errmsg;

	/*START: NEW LOGGING MECHANISM CHANGES*/
        pkg_grp_log_util.prc_update_log_message_r
			(
				n_prcs_job_log_message_id_r => gn_job_log_message_id_r,
				p_err_msg 					=> gc_trcmsg
			);

    pkg_grp_log_util.prc_update_log
          (
             gn_out_job_id                  --p_job_id
            ,gc_error_status                --p_job_status
            ,gc_errmsg                      --p_err_msg
            ,gc_trcmsg 					    --p_trc_msg
            ,gc_getcur_loadedby             --p_log_util_called_by_r
          );
    RAISE;
END prc_insert_dummy_rec;

end PKG_GRP_LOAD_RPT_CLAIM_PAYMENT_R;

