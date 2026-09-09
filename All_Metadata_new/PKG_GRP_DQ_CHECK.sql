"PACKAGE PKG_GRP_DQ_CHECK
/***********************************************************************
  Purpose:  This package body contains procedures which are used for Data Quality Checks

Author      Date     Description
--------    -------  -------------------------------------------------
Samba	    08/05/25 First drafted version
Samba	    10/23/25 Implementing
		     NULL Check
		     Length Check
		     CUstom Query Check for PROD Support
***********************************************************************/
IS

-- Used as DQ check Main procedure
PROCEDURE PRC_RUN_DQ_CHECKS(
					p_rule_check  IN VARCHAR2, 
					p_order_id    IN VARCHAR2
					);

--To determine PARTITION Yes or NO, If Yes, what is PARTITION COlumn 
PROCEDURE PRC_PARTITION_TABLE_CHECK (
					p_owner                 IN  VARCHAR2,
					p_table_name            IN  VARCHAR2,
					p_is_partitioned        OUT VARCHAR2,
					p_partition_col         OUT VARCHAR2
					);

-- Individual DQ check procedure - Zeo Record check
PROCEDURE PRC_ZERO_RECORD_CHECK(
					p_tbl_nm 	  	 IN  VARCHAR2, 
					p_total_count   OUT  NUMBER,
					p_detail_msg  	OUT  VARCHAR2 
					);

-- Individual DQ check procedure - Null value check
PROCEDURE PRC_NULL_RECORD_CHECK(
					p_tbl_nm 	  	IN   VARCHAR2, 
					p_column_nm     IN   VARCHAR2, 
					p_affect_count  OUT  NUMBER,
					p_total_count  	OUT  NUMBER, 
					p_detail_msg  	OUT  VARCHAR2
					);

-- Individual DQ check procedure - Length check				   
PROCEDURE prc_length_record_check(
					p_tbl_nm 	  	IN  VARCHAR2, 
					p_column_nm     IN  VARCHAR2, 
					p_rule_value	IN  VARCHAR2,
					p_affect_count 	OUT NUMBER, 
					p_total_count 	OUT NUMBER,
					p_detail_msg  	OUT VARCHAR2
					);

-- Individual DQ check procedure - Custom DQ check	
PROCEDURE prc_DQ_custom_check(
					p_tbl_nm 	  	 IN  VARCHAR2, 
					p_column_nm	  	 IN  VARCHAR2,
					p_custom_query 	 IN  VARCHAR2,
					p_dq_rule_val_r	 IN	 VARCHAR2,				
					p_custom_count 	OUT  NUMBER,
					p_detail_msg  	OUT  VARCHAR2 
					);

END PKG_GRP_DQ_CHECK;PACKAGE BODY PKG_GRP_DQ_CHECK 
/***********************************************************************
  Purpose:  This package body contains procedures which are used for Data Quality Checks

Author      Date     Description
--------    -------  -------------------------------------------------
Samba	    08/05/25 First drafted version (Zero Record Check only)
Samba	    10/23/25 Implementing
		     NULL Check
		     Length Check
		     CUstom Query Check for PROD Support
***********************************************************************/
IS

		gd_sysdate               CONSTANT DATE           											 := TRUNC(SYSDATE);
		gn_prior_month           CONSTANT PRCS_JOB_LOG_MESSAGE_R.N_COUNT_R%TYPE 					 := TO_NUMBER(TO_CHAR(ADD_MONTHS(TRUNC(gd_sysdate,&apos;MM&apos;),-1),&apos;YYYYMM&apos;)); 
		gn_current_month         CONSTANT PRCS_JOB_LOG_MESSAGE_R.N_COUNT_R%TYPE 					 := TO_NUMBER(TO_CHAR(gd_sysdate,&apos;YYYYMM&apos;));							
		gn_sysdt_batchid         CONSTANT PRCS_JOB_LOG_MESSAGE_R.N_COUNT_R%TYPE 					 := TO_NUMBER(TO_CHAR(gd_sysdate,&apos;YYYYMMDD&apos;));							
		gv_dq_check		         CONSTANT PRCS_JOB_LOG_MESSAGE_R.V_CODE_LOCATION_R%TYPE				 := &apos;DATA_QUALITY_CHECK&apos;;								
		gv_job_name              CONSTANT PRCS_JOB_LOG_R.V_JOB_NAME_R%TYPE							 := &apos;PKG_GRP_DQ_CHECK&apos;;									
		gv_running_status        CONSTANT PRCS_JOB_LOG_R.V_JOB_STATUS_R%TYPE  						 := &apos;Running&apos;;															
		gv_error_status          CONSTANT PRCS_JOB_LOG_R.V_JOB_STATUS_R%TYPE    					 := &apos;Error&apos;;															
		gv_success_status        CONSTANT PRCS_JOB_LOG_R.V_JOB_STATUS_R%TYPE  						 := &apos;Success&apos;;															
		gv_source                CONSTANT PRCS_JOB_LOG_R.V_JOB_STATUS_R%TYPE 						 := &apos;EDW&apos;;	
		gv_message_type 	     CONSTANT PRCS_JOB_LOG_MESSAGE_R.v_message_type_r%TYPE  			 := &apos;Data Quality Check&apos;;
		gv_trcmsg                PRCS_JOB_LOG_MESSAGE_R.V_MESSAGE_R%TYPE;			
		gt_start_time   	     PRCS_JOB_LOG_MESSAGE_R.D_CREATION_DATE_R %TYPE;					 																		
		gt_end_time 		     PRCS_JOB_LOG_MESSAGE_R.D_CREATION_DATE_R %TYPE;					 																		
		gn_job_log_message_id    PRCS_JOB_LOG_MESSAGE_R.N_COUNT_R%TYPE;								 																		
		gn_error_line            PRCS_JOB_LOG_MESSAGE_R.v_message_type_r%TYPE;						 																					
		gn_out_job_id            PRCS_JOB_LOG_MESSAGE_R.N_JOB_ID_R%TYPE;					 																				
		gv_err_msg               PRCS_JOB_LOG_MESSAGE_R.V_MESSAGE_R%TYPE;
        gv_owner                 PRCS_JOB_LOG_MESSAGE_R.V_MESSAGE_R%TYPE                             := UPPER(SYS_CONTEXT(&apos;USERENV&apos;, &apos;CURRENT_SCHEMA&apos;));


 PROCEDURE prc_partition_table_check (
			p_owner                 IN  VARCHAR2,
			p_table_name            IN  VARCHAR2,
			p_is_partitioned        OUT VARCHAR2,
			p_partition_col         OUT VARCHAR2
)
IS
    v_cnt              NUMBER := 0;
    v_col              VARCHAR2(200);
    v_sql              VARCHAR2(1000);
BEGIN
    -- 1. Check if the table is partitioned
    SELECT COUNT(*)
    INTO v_cnt
    FROM all_part_tables
    WHERE owner = UPPER(p_owner)
      AND table_name = UPPER(p_table_name);

    IF v_cnt = 0 THEN
        -- Not a partitioned table
        p_is_partitioned := &apos;FALSE&apos;;
        p_partition_col  := NULL;
    ELSE
        -- 2. Get partition column name
        SELECT column_name
        INTO v_col
        FROM all_part_key_columns
        WHERE owner = UPPER(p_owner)
          AND name = UPPER(p_table_name)
          AND object_type = &apos;TABLE&apos;
          AND ROWNUM = 1; -- In case of multiple partition keys

        p_is_partitioned := &apos;TRUE&apos;;
        p_partition_col  := v_col;

    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_is_partitioned := &apos;FALSE&apos;;
        p_partition_col  := NULL;
    WHEN OTHERS THEN
        p_is_partitioned := &apos;ERROR&apos;;
        p_partition_col  := NULL;
END prc_partition_table_check;

----**************************************************************
 -- Master Procedure to Run All Active Rules for Given Batch
 ----**************************************************************

PROCEDURE PRC_RUN_DQ_CHECKS(
					p_rule_check  IN VARCHAR2, 
					p_order_id    IN VARCHAR2
				) 

 IS

	lv_order_id           VARCHAR2(100);
	lv_dq_rule_check      VARCHAR2(1000);

	CURSOR c_rules 
	 IS
      SELECT p.V_TBL_NM_R, p.V_COLUMN_NM_R, r.N_DQ_RULE_ID_R, r.V_DQ_RULE_NM_R, p.V_DQ_RULE_VAL_R, p.V_DQ_CUSTOM_QUERY,p.V_DQ_CUSTOM_TYPE_R
        FROM PRC_DQ_RULE_PARAM_R p
        JOIN PRC_DQ_RULE_MASTER_R r 
		  ON p.N_DQ_RULE_ID_R = r.N_DQ_RULE_ID_R
       WHERE --p.batch_id = p_batch_id
		     p.V_ACTIVE_IND_R = &apos;Y&apos;
         AND r.V_ACTIVE_IND_R = &apos;Y&apos;
		 AND p.N_ORDER_ID_R IN (SELECT TRIM(REGEXP_SUBSTR(lv_order_id, &apos;[^,]+&apos;, 1, LEVEL))
                                              FROM dual
                                            CONNECT BY LEVEL &lt;= REGEXP_COUNT(lv_order_id, &apos;,&apos;) + 1)
		 AND r.V_DQ_RULE_NM_R IN ( SELECT TRIM(REGEXP_SUBSTR(lv_dq_rule_check, &apos;[^,]+&apos;, 1, LEVEL))
                                              FROM dual
                                            CONNECT BY LEVEL &lt;= REGEXP_COUNT(lv_dq_rule_check, &apos;,&apos;) + 1)
		order by p.N_ORDER_ID_R, V_DQ_RULE_NM_R;								

	lv_total_count 			NUMBER;
    lv_sql         			VARCHAR2(4000);
	lv_detail_msg  			VARCHAR2(1000);
	lv_check_result			VARCHAR2(50);		
	lv_severity				VARCHAR2(50);
    lv_total_rows  			NUMBER;
	lv_custom_count			NUMBER;
	lv_failed_rows			NUMBER;
    lv_start_time  			TIMESTAMP;
    lv_end_time    			TIMESTAMP;
	ln_failed_percentage	NUMBER:=0;
	lv_cnt					NUMBER  :=2;
	lv_fail_row_count   	NUMBER := 0;
	lv_audit_id 			NUMBER := 0;


  BEGIN

	pkg_grp_log_util.prc_insert_log
                   ( 
					 p_source              			=&gt; gv_source
					,p_job_nm              			=&gt; gv_job_name
					,p_job_status          			=&gt; gv_running_status
					,p_err_msg             			=&gt; NULL
					,p_trc_msg             			=&gt; NULL
					,p_n_batch_id          			=&gt; gn_sysdt_batchid
					,p_log_util_called_by_r			=&gt; gv_dq_check
					,out_job_id            			=&gt; gn_out_job_id
				);

	gv_trcmsg:=&apos;1. Entered into Data Quality Check Procedure&apos;;
    PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
				(
					 p_job_id_r                    	=&gt; gn_out_job_id
					,p_batch_id_r                  	=&gt; gn_sysdt_batchid
					,p_message_type_r              	=&gt; gv_message_type
					,p_code_location_r             	=&gt; gv_dq_check
					,p_message_r                   	=&gt; gv_trcmsg
					,p_count_type_r                	=&gt; NULL
					,p_count_r                     	=&gt; NULL
					,p_duration_r                  	=&gt; NULL
					,p_created_by_r                	=&gt; gv_job_name
					,out_prcs_job_log_message_id_r 	=&gt; gn_job_log_message_id
				);	

	-- Capture Order IDs Dynamically when p_order_id=&apos;ALL&apos;	from PRC_DQ_RULE_PARAM_R
	IF UPPER(p_order_id) = &apos;ALL&apos; 
		THEN
		 SELECT 
				LISTAGG(DISTINCT N_ORDER_ID_R, &apos;,&apos;) WITHIN GROUP (ORDER BY N_ORDER_ID_R) 
		   INTO 
		        lv_order_id 
			 FROM ATOMIC.PRC_DQ_RULE_PARAM_R ;
		ELSE
		 lv_order_id:=p_order_id;
	END IF;

	-- Capture Rule Checks Dynamically when p_rule_check=&apos;ALL&apos;	from PRC_DQ_RULE_MASTER_R
	IF UPPER(p_rule_check) = &apos;ALL&apos; 
		THEN
		 SELECT 
				LISTAGG(DISTINCT V_DQ_RULE_NM_R, &apos;,&apos;) WITHIN GROUP (ORDER BY V_DQ_RULE_NM_R) 
		   INTO 
		        lv_dq_rule_check 
			 FROM ATOMIC.PRC_DQ_RULE_MASTER_R ;
		ELSE
		 lv_dq_rule_check:=upper(p_rule_check);
	END IF;


	gt_start_time := SYSTIMESTAMP;
    FOR r_rule IN c_rules 
		LOOP

			IF r_rule.V_DQ_RULE_NM_R=&apos;ZERO_RECORD&apos; THEN
				lv_start_time:= SYSTIMESTAMP;
				PKG_GRP_DQ_CHECK.prc_zero_record_check(r_rule.V_TBL_NM_R, lv_total_count,lv_detail_msg);

				gv_trcmsg:=lv_cnt||&apos;. ZERO_RECORD Check: &apos;|| lv_detail_msg||&apos; for &apos;||r_rule.V_TBL_NM_R;	

				IF lv_total_count &gt; 0 THEN
					lv_check_result:= &apos;PASS&apos;;
						lv_severity:= &apos;LOW&apos;	;				
					ELSE 
					lv_check_result:= &apos;FAIL&apos;;
					    lv_severity:= &apos;HIGH&apos;;						
				 END IF;
						lv_failed_rows:=Null;

				lv_end_time:= SYSTIMESTAMP;				
				PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
						(
							 p_job_id_r                    	=&gt; gn_out_job_id
							,p_batch_id_r                  	=&gt; gn_sysdt_batchid
							,p_message_type_r              	=&gt; gv_message_type
							,p_code_location_r             	=&gt; gv_dq_check
							,p_message_r                   	=&gt; gv_trcmsg
							,p_count_type_r                	=&gt; NULL
							,p_count_r                     	=&gt; NULL
							,p_duration_r                  	=&gt; FNC_GRP_TIME_DURATION(lv_start_time,lv_end_time)
							,p_created_by_r                	=&gt; gv_job_name
							,out_prcs_job_log_message_id_r 	=&gt; gn_job_log_message_id
						);	
			END IF;

			IF r_rule.V_DQ_RULE_NM_R=&apos;NULL_CHECK&apos; THEN
				lv_start_time:= SYSTIMESTAMP;
				PKG_GRP_DQ_CHECK.prc_null_record_check(r_rule.V_TBL_NM_R, r_rule.V_COLUMN_NM_R, lv_failed_rows,lv_total_count,lv_detail_msg);

				gv_trcmsg:=lv_cnt||&apos;. NULL_CHECK : &apos;|| lv_detail_msg||&apos; for &apos;||r_rule.V_TBL_NM_R;	

				IF lv_failed_rows &gt; 0 THEN
					lv_check_result:= &apos;FAIL&apos;;
						lv_severity:= &apos;HIGH&apos;;				
					ELSE 
					lv_check_result:= &apos;PASS&apos;;
					    lv_severity:= &apos;LOW&apos;	;					
				 END IF;

				ln_failed_percentage:=ROUND((lv_failed_rows / lv_total_count) * 100, 2) ;	

				lv_end_time:= SYSTIMESTAMP;				
				PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
						(
							 p_job_id_r                    	=&gt; gn_out_job_id
							,p_batch_id_r                  	=&gt; gn_sysdt_batchid
							,p_message_type_r              	=&gt; gv_message_type
							,p_code_location_r             	=&gt; gv_dq_check
							,p_message_r                   	=&gt; gv_trcmsg
							,p_count_type_r                	=&gt; NULL
							,p_count_r                     	=&gt; NULL
							,p_duration_r                  	=&gt; FNC_GRP_TIME_DURATION(lv_start_time,lv_end_time)
							,p_created_by_r                	=&gt; gv_job_name
							,out_prcs_job_log_message_id_r 	=&gt; gn_job_log_message_id
						);	
			END IF;

			IF r_rule.V_DQ_RULE_NM_R=&apos;LENGTH_CHECK&apos; THEN
				lv_start_time:= SYSTIMESTAMP;
				PKG_GRP_DQ_CHECK.prc_length_record_check(r_rule.V_TBL_NM_R, r_rule.V_COLUMN_NM_R, r_rule.V_DQ_RULE_VAL_R, lv_failed_rows,lv_total_count,lv_detail_msg);

				gv_trcmsg:=lv_cnt||&apos;. LENGTH_CHECK : &apos;|| lv_detail_msg||&apos; for &apos;||r_rule.V_TBL_NM_R;	

				IF lv_failed_rows &gt; 0 THEN
					lv_check_result:= &apos;FAIL&apos;;
						lv_severity:= &apos;HIGH&apos;;					
					ELSE 
					lv_check_result:= &apos;PASS&apos;;
					    lv_severity:= &apos;LOW&apos;	;					
				 END IF;

					ln_failed_percentage:=ROUND((lv_failed_rows / lv_total_count) * 100, 2) ;

				lv_end_time:= SYSTIMESTAMP;				
				PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
						(
							 p_job_id_r                    	=&gt; gn_out_job_id
							,p_batch_id_r                  	=&gt; gn_sysdt_batchid
							,p_message_type_r              	=&gt; gv_message_type
							,p_code_location_r             	=&gt; gv_dq_check
							,p_message_r                   	=&gt; gv_trcmsg
							,p_count_type_r                	=&gt; NULL
							,p_count_r                     	=&gt; NULL
							,p_duration_r                  	=&gt; FNC_GRP_TIME_DURATION(lv_start_time,lv_end_time)
							,p_created_by_r                	=&gt; gv_job_name
							,out_prcs_job_log_message_id_r 	=&gt; gn_job_log_message_id
						);	
			END IF;

			IF r_rule.V_DQ_RULE_NM_R=&apos;CUSTOM_CHECK&apos; THEN
				lv_start_time:= SYSTIMESTAMP;
				PKG_GRP_DQ_CHECK.prc_DQ_custom_check(r_rule.V_TBL_NM_R, r_rule.V_COLUMN_NM_R, r_rule.V_DQ_CUSTOM_QUERY,r_rule.V_DQ_RULE_VAL_R, lv_custom_count,lv_detail_msg);

				gv_trcmsg:=lv_cnt||&apos;. CUSTOM_CHECK : &apos;|| lv_detail_msg||&apos; for &apos;||r_rule.V_TBL_NM_R;	

				IF lv_custom_count &gt; r_rule.V_DQ_RULE_VAL_R THEN
					lv_check_result:= &apos;FAIL&apos;;
						lv_severity:= &apos;HIGH&apos;;					
					ELSE 
					lv_check_result:= &apos;PASS&apos;;
					    lv_severity:= &apos;LOW&apos;;				
				 END IF;
				lv_failed_rows:=lv_custom_count;
				lv_total_count:=r_rule.V_DQ_RULE_VAL_R;

				lv_end_time:= SYSTIMESTAMP;				
				PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
						(	 p_job_id_r                    	=&gt; gn_out_job_id
							,p_batch_id_r                  	=&gt; gn_sysdt_batchid
							,p_message_type_r              	=&gt; gv_message_type
							,p_code_location_r             	=&gt; gv_dq_check
							,p_message_r                   	=&gt; gv_trcmsg
							,p_count_type_r                	=&gt; NULL
							,p_count_r                     	=&gt; NULL
							,p_duration_r                  	=&gt; FNC_GRP_TIME_DURATION(lv_start_time,lv_end_time)
							,p_created_by_r                	=&gt; gv_job_name
							,out_prcs_job_log_message_id_r 	=&gt; gn_job_log_message_id);	
			END IF;

			lv_cnt:=lv_cnt+1;
			lv_audit_id  := seq_audit_id.NEXTVAL||to_char(sysdate,&apos;YYYYMMDD&apos;);

			INSERT INTO PRC_DQ_CHECK_AUDIT_R (
                 N_AUDIT_ID_R
				,N_BATCH_ID_R
				,V_RUN_ID_R
				,T_CHECK_TIMESTAMP_R
				,V_TBL_NM_R 
				,V_COLUMN_NM_R 
				,N_DQ_RULE_ID_R 
				,V_DQ_RULE_NM_R
				,V_CHECK_RESULT_R 
				,V_SEVERITY_R
				,N_AFFECTED_ROWS_R 
				,N_TOTAL_ROWS_R 
				,N_FAILURE_PCT_R
				,V_EXECUTION_TIME_R
				,V_DETAIL_MSG_R 
				,V_EXECUTED_BY_R
				,V_DQ_CUSTOM_TYPE_R
			)
			VALUES (
				lv_audit_id
				,gn_sysdt_batchid
				,gn_out_job_id
				,SYSTIMESTAMP
                ,r_rule.V_TBL_NM_R
				,r_rule.V_COLUMN_NM_R
				,r_rule.N_DQ_RULE_ID_R
				,r_rule.V_DQ_RULE_NM_R
				,lv_check_result
				,lv_severity	
				,lv_failed_rows
				,lv_total_count
				,ln_failed_percentage	
				,FNC_GRP_TIME_DURATION(lv_start_time,lv_end_time)
				,lv_detail_msg
				,USER
				,r_rule.V_DQ_CUSTOM_TYPE_R
			);


		END LOOP;
	COMMIT;
		gt_end_time := SYSTIMESTAMP;
		gv_trcmsg:=lv_cnt||&apos;. Completed with Data Quality Check Procedure&apos;;			
			PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
						(
							 p_job_id_r                    	=&gt; gn_out_job_id
							,p_batch_id_r                  	=&gt; gn_sysdt_batchid
							,p_message_type_r              	=&gt; gv_message_type
							,p_code_location_r             	=&gt; gv_dq_check
							,p_message_r                   	=&gt; gv_trcmsg
							,p_count_type_r                	=&gt; NULL
							,p_count_r                     	=&gt; NULL
							,p_duration_r                  	=&gt; FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time)
							,p_created_by_r                	=&gt; gv_job_name
							,out_prcs_job_log_message_id_r 	=&gt; gn_job_log_message_id
						);	


			pkg_grp_log_util.prc_update_log( 
								 gn_out_job_id                 
								,gv_success_status             
								,gv_err_msg                    
								,gv_trcmsg                     
								,gv_dq_check              
								);
EXCEPTION
WHEN OTHERS THEN
		gv_err_msg :=SUBSTR(SQLERRM,1,4000);
	    gv_trcmsg :=&apos;1.z Error in DQ Check Procedure - &apos;||gv_err_msg;

   /*START: NEW LOGGING MECHANISM CHANGES*/    
    pkg_grp_log_util.prc_update_log_message_r
			( 
			n_prcs_job_log_message_id_r =&gt; gn_job_log_message_id,
			p_err_msg 					=&gt; gv_trcmsg 
				);

	pkg_grp_log_util.prc_update_log
      (
         gn_out_job_id                   	
        ,gv_error_status                	
        ,gv_err_msg                       	
        ,gv_trcmsg					     	
        ,gv_dq_check               	
      );
    RAISE;
 END PRC_RUN_DQ_CHECKS;

----**************************************************************
 -- Child Procedure to get Zero record count check
 ----**************************************************************
PROCEDURE prc_zero_record_check(
				p_tbl_nm 	  	IN  VARCHAR2,
				p_total_count   OUT NUMBER,
				p_detail_msg  	OUT  VARCHAR2 
				) 

 IS
    lv_sql 					VARCHAR2(4000);
    ln_total_count          NUMBER;
    lv_is_partitioned       VARCHAR2(10);
    lv_partition_col        VARCHAR2(200);
    ln_max_yearmonth_value  NUMBER;
BEGIN
	--To determine Partioned-YES and Partitioned column 
	PKG_GRP_DQ_CHECK.prc_partition_table_check
    (
        p_owner                 =&gt; gv_owner, 
        p_table_name            =&gt; p_tbl_nm, 
        p_is_partitioned        =&gt; lv_is_partitioned,
        p_partition_col         =&gt; lv_partition_col
    );

    --Get current month
    ln_max_yearmonth_value := FNC_GRP_GET_CURRENT_MONTH();

    IF lv_is_partitioned = &apos;TRUE&apos; 
    THEN 
        lv_sql := &apos;SELECT COUNT(*) FROM &apos; || gv_owner ||&apos;.&apos; || p_tbl_nm || &apos; WHERE ROWNUM=1 AND &apos;|| lv_partition_col ||&apos; = &apos;||ln_max_yearmonth_value;
    ELSE
        lv_sql := &apos;SELECT COUNT(*) FROM &apos; || gv_owner ||&apos;.&apos; || p_tbl_nm || &apos; WHERE ROWNUM=1&apos;;
    END IF;

    EXECUTE IMMEDIATE lv_sql INTO ln_total_count;

    IF ln_total_count &gt; 0 THEN 
        p_detail_msg:=&apos;Records exist&apos;; 
    ELSE 
        p_detail_msg:=&apos;Zero records present&apos;; 
    END IF;
    p_total_count:= ln_total_count;

EXCEPTION
WHEN OTHERS THEN
		gv_err_msg :=SUBSTR(SQLERRM,1,4000);
	    gv_trcmsg :=&apos;1.z Error in DQ Check Procedure (prc_zero_record_check) - &apos;||gv_err_msg;
		RAISE_APPLICATION_ERROR(-20001, gv_trcmsg);
END prc_zero_record_check;


PROCEDURE prc_null_record_check(
				p_tbl_nm 	  	IN  VARCHAR2, 
                p_column_nm     IN  VARCHAR2, 
                p_affect_count  OUT  NUMBER,
				p_total_count  	OUT  NUMBER, 
				p_detail_msg  	OUT  VARCHAR2
				) 

 IS
    lv_sql 					VARCHAR2(4000);
	lv_sql_count			VARCHAR2(4000);
    ln_affect_count         NUMBER;
    lv_is_partitioned       VARCHAR2(10);
    lv_partition_col        VARCHAR2(200);
    ln_max_yearmonth_value  NUMBER;
BEGIN
	--To determine Partioned-YES and Partitioned column 
	PKG_GRP_DQ_CHECK.prc_partition_table_check
    (
        p_owner                 =&gt; gv_owner, 
        p_table_name            =&gt; p_tbl_nm, 
        p_is_partitioned        =&gt; lv_is_partitioned,
        p_partition_col         =&gt; lv_partition_col
    );
    --Get current month
    ln_max_yearmonth_value := FNC_GRP_GET_CURRENT_MONTH();

    IF lv_is_partitioned = &apos;TRUE&apos; 
    THEN 
        lv_sql := &apos;SELECT COUNT(*) FROM &apos; || gv_owner ||&apos;.&apos; || p_tbl_nm || &apos; WHERE &apos;|| p_column_nm || &apos; IS NULL AND &apos;|| lv_partition_col ||&apos; = &apos;||ln_max_yearmonth_value;
  lv_sql_count := &apos;SELECT COUNT(*) FROM &apos; || gv_owner ||&apos;.&apos; || p_tbl_nm || &apos; WHERE &apos;|| lv_partition_col ||&apos; = &apos;||ln_max_yearmonth_value;
    ELSE
        lv_sql := &apos;SELECT COUNT(*) FROM &apos; || gv_owner ||&apos;.&apos; || p_tbl_nm || &apos; WHERE &apos;|| p_column_nm || &apos; IS NULL&apos;;
  lv_sql_count := &apos;SELECT COUNT(*) FROM &apos; || gv_owner ||&apos;.&apos; || p_tbl_nm ;
    END IF;

    EXECUTE IMMEDIATE lv_sql INTO ln_affect_count;
	EXECUTE IMMEDIATE lv_sql_count INTO p_total_count;

    IF ln_affect_count &gt; 0 THEN 
        p_detail_msg:=&apos;Null Records exist&apos;; 
    ELSE 
        p_detail_msg:=&apos;No Null records present&apos;; 
    END IF;
   -- DBMS_OUTPUT.PUT_LINE(p_detail_msg);
    p_affect_count := ln_affect_count;

EXCEPTION
WHEN OTHERS THEN
		gv_err_msg :=SUBSTR(SQLERRM,1,4000);
	    gv_trcmsg :=&apos;1.z Error in DQ Check Procedure (prc_null_record_check) - &apos;||gv_err_msg;
		RAISE_APPLICATION_ERROR(-20001, gv_trcmsg);
END prc_null_record_check;

PROCEDURE prc_length_record_check(
				p_tbl_nm 	  	IN  VARCHAR2, 
                p_column_nm     IN  VARCHAR2, 
				p_rule_value	IN  VARCHAR2, 
                p_affect_count 	OUT NUMBER, 
				p_total_count 	OUT NUMBER,
				p_detail_msg  	OUT VARCHAR2
				) 

 IS
    lv_sql 					VARCHAR2(4000);
	lv_sql_count			VARCHAR2(4000);
    ln_total_count          NUMBER;
    lv_is_partitioned       VARCHAR2(10);
    lv_partition_col        VARCHAR2(200);
    ln_max_yearmonth_value  NUMBER;
	lv_length_rule_detail   VARCHAR2(200);
BEGIN
	--To determine Partioned-YES and Partitioned column 
	PKG_GRP_DQ_CHECK.prc_partition_table_check
    (
        p_owner                 =&gt; gv_owner, 
        p_table_name            =&gt; p_tbl_nm, 
        p_is_partitioned        =&gt; lv_is_partitioned,
        p_partition_col         =&gt; lv_partition_col
    );

    --Get current month
    ln_max_yearmonth_value := FNC_GRP_GET_CURRENT_MONTH();

    IF lv_is_partitioned = &apos;TRUE&apos; 
    THEN 
        lv_sql := &apos;SELECT COUNT(*) FROM &apos; || gv_owner ||&apos;.&apos; || p_tbl_nm || &apos; WHERE LENGTH(&apos;|| p_column_nm || &apos;) &apos; || p_rule_value  ||&apos; AND &apos;|| lv_partition_col ||&apos; = &apos;||ln_max_yearmonth_value;
		lv_sql_count := &apos;SELECT COUNT(*) FROM &apos; || gv_owner ||&apos;.&apos; || p_tbl_nm || &apos; WHERE &apos;||lv_partition_col ||&apos; = &apos;||ln_max_yearmonth_value;
    ELSE
        lv_sql := &apos;SELECT COUNT(*) FROM &apos; || gv_owner ||&apos;.&apos; || p_tbl_nm || &apos; WHERE LENGTH(&apos;|| p_column_nm || &apos;) &apos; || p_rule_value;
		lv_sql_count := &apos;SELECT COUNT(*) FROM &apos; || gv_owner ||&apos;.&apos; || p_tbl_nm;
    END IF;

    --DBMS_OUTPUT.PUT_LINE(lv_sql);
    EXECUTE IMMEDIATE lv_sql INTO ln_total_count;
	EXECUTE IMMEDIATE lv_sql_count INTO p_total_count;

	ln_total_count:=p_total_count-ln_total_count;

	IF ln_total_count &gt; 0 THEN 
        p_detail_msg:=&apos;The expected length issue exists for the column &apos;||p_column_nm; 
    ELSE 
        p_detail_msg:=&apos;No length issue exists for the column &apos;||p_column_nm;
    END IF;

    p_affect_count := ln_total_count;

EXCEPTION
WHEN OTHERS THEN
		gv_err_msg :=SUBSTR(SQLERRM,1,4000);
	    gv_trcmsg :=&apos;1.z Error in DQ Check Procedure (prc_length_record_check) - &apos;||gv_err_msg;
		RAISE_APPLICATION_ERROR(-20001, gv_trcmsg);
END prc_length_record_check;

PROCEDURE prc_DQ_custom_check(
				p_tbl_nm 	  	 IN  VARCHAR2, 
				p_column_nm	  	 IN  VARCHAR2,
				p_custom_query 	 IN  VARCHAR2,
				p_dq_rule_val_r	 IN	 VARCHAR2,				
				p_custom_count 	OUT  NUMBER,
				p_detail_msg  	OUT  VARCHAR2 
				)
IS

    lv_sql 					VARCHAR2(1000);
	lv_is_partitioned       VARCHAR2(10);
    lv_partition_col        VARCHAR2(200);
	lv_yearmonth 			VARCHAR2(800) ;
	ln_yearmonth			NUMBER;
BEGIN

	--To determine Partioned-YES and Partitioned column 
	PKG_GRP_DQ_CHECK.prc_partition_table_check
    (
        p_owner                 =&gt; gv_owner, 
        p_table_name            =&gt; p_tbl_nm, 
        p_is_partitioned        =&gt; lv_is_partitioned,
        p_partition_col         =&gt; lv_partition_col
    );

	--Get current month
	ln_yearmonth:=FNC_GRP_GET_CURRENT_MONTH();

	--DBMS_OUTPUT.PUT_LINE(lv_yearmonth);
	lv_sql := p_custom_query;

	--DBMS_OUTPUT.PUT_LINE(lv_sql);
    EXECUTE IMMEDIATE lv_sql INTO p_custom_count;

		IF p_custom_count &gt; p_dq_rule_val_r THEN 
			p_detail_msg:=&apos;The Custom Query Total count &apos;||p_custom_count||&apos; doesnt match and more than expected count&apos;||p_dq_rule_val_r; 
		ELSE 
			p_detail_msg:=&apos;The Custom Query Total count &apos;||p_custom_count||&apos; matches with the expected count - &apos;||p_dq_rule_val_r; 
		END IF;

EXCEPTION
WHEN OTHERS THEN
		gv_err_msg :=SUBSTR(SQLERRM,1,4000);
	    gv_trcmsg :=&apos;1.z Error in DQ Check Procedure (prc_custom_dq_check) - &apos;||gv_err_msg;
		RAISE_APPLICATION_ERROR(-20001, gv_trcmsg);
END prc_DQ_custom_check;

END PKG_GRP_DQ_CHECK;"