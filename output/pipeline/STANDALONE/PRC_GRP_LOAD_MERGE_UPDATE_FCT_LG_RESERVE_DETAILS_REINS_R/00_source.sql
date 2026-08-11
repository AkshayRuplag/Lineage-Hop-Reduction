

  CREATE OR REPLACE EDITIONABLE PROCEDURE "ATOMIC"."PRC_GRP_LOAD_MERGE_UPDATE_FCT_LG_RESERVE_DETAILS_REINS_R" (
	P_BATCH_ID_R IN NUMBER
)  AS
	V_SYS_DATE                  VARCHAR2(15) := TO_CHAR(SYSDATE,'YYYYMMDDHHMISS');
	N_MAX_SERIAL_NUM_R          NUMBER;
	V_SQLCODE                   VARCHAR2(100);
	V_SQLERRM                   VARCHAR2(500);
	LN_BATCH_ID_R               NUMBER       := P_BATCH_ID_R;
    LN_CURR_FISCAL_DATE         DATE;
	LC_TRCMSG           VARCHAR2(4000) := 'TRACE MESSAGE:->';
	lc_source                       VARCHAR2(30)       :='EDW';
	lc_job_name              	    VARCHAR2(100 CHAR) :='PRC_GRP_LOAD_FCT_LG_RESERVE_DETAILS_R_INCR_LIFE_MERGE_REINS_ADHOC';
	lc_running_status               VARCHAR2(30)       :='Running';
	lc_error_status          		VARCHAR2(30)       :='Error';
	lc_success_status        		VARCHAR2(30)       :='Success';
	ln_sysdt_batchid                NUMBER             := TO_NUMBER(TO_CHAR(sysdate,'YYYYMMDD'));
	--gc_main_loadedby              VARCHAR2(100 CHAR) :='PKG_GRP_MONTH_END_LOAD.MAIN';
	lc_main_loadedby                VARCHAR2(100 CHAR) :=NULL;
	ln_out_job_id                   NUMBER;
	--lc_trcmsg                       CLOB               :='Trace Message:->';
	lv_message_type_r             	PRCS_JOB_LOG_MESSAGE_R.v_message_type_r%TYPE    := PKG_GRP_LOG_UTIL.gc_message_type_info;
	ln_job_log_message_id_r         NUMBER;
	ld_sysdate DATE := SYSDATE;
	lc_errmsg                		VARCHAR2(4000 CHAR);
	lt_start_time_r 				TIMESTAMP;
	lt_end_time_r 					TIMESTAMP;
	lc_run_cnt          			PRCS_JOB_LOG_MESSAGE_R.N_COUNT_R%TYPE 	 		:=0;
	lc_count_type_r 				PRCS_JOB_LOG_MESSAGE_R.v_count_type_r%TYPE      := PKG_GRP_LOG_UTIL.gc_count_type_merge;
	lc_duration_r       			PRCS_JOB_LOG_MESSAGE_R.T_DURATION_R%TYPE 		:=0;
	LD_LIFE_VALUATION_DATE 	 	DATE;
	LD_LIFE_MIS_DATE_R			DATE;

	BEGIN
	/* MAX RESERVE VALUATION DATE */
   /* SELECT
        MAX(DTR.D_CALENDAR_DATE_R)
    INTO
        LN_CURR_FISCAL_DATE
    FROM
    (
        SELECT
            N_FISCAL_MONTH_R,
            N_FISCAL_YEAR_R
        FROM
            DIM_TIME_R
        WHERE
            D_CALENDAR_DATE_R = TO_DATE(SUBSTR(P_BATCH_ID_R, 1, 8), 'YYYYMMDD')
    ) DTR_CURR
    JOIN DIM_TIME_R DTR
    ON
    DTR.V_END_OF_FISCAL_MONTH_IND_R = 'Y'
    AND DTR.N_FISCAL_MONTH_R = DTR_CURR.N_FISCAL_MONTH_R
    AND DTR.N_FISCAL_YEAR_R = DTR_CURR.N_FISCAL_YEAR_R;
*/

pkg_grp_log_util.prc_insert_log
                       ( p_source              => lc_source
					    ,p_job_nm              => lc_job_name
                        ,p_job_status          => lc_running_status
                        ,p_err_msg             => null
                        ,p_trc_msg             => null
                        ,p_n_batch_id          => ln_sysdt_batchid
                        ,p_log_util_called_by_r=> lc_main_loadedby
						,out_job_id            => ln_out_job_id
						);

	SELECT MAX(TO_DATE(D_VALUATION_DATE_R , 'DD-MON-YY')) INTO LD_LIFE_VALUATION_DATE
	 FROM Atomic.STG_LIFE_RESERVES_R;

		lc_trcmsg:='1. LD_LIFE_VALUATION_DATE is :->'||LD_LIFE_VALUATION_DATE;

		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
						p_job_id_r                    	=> ln_out_job_id,
						p_batch_id_r                  	=> ln_sysdt_batchid,
						p_message_type_r              	=> lv_message_type_r,
						p_code_location_r             	=> lc_main_loadedby,
						p_message_r                   	=> lc_trcmsg,
						p_count_type_r                	=> NULL,
						p_count_r                     	=> NULL,
						p_duration_r                  	=> NULL,
						p_created_by_r                	=> lc_job_name,
						out_prcs_job_log_message_id_r 	=> ln_job_log_message_id_r
						);

	SELECT
        D_CALENDAR_DATE_R    INTO LD_LIFE_MIS_DATE_R
    FROM
        ATOMIC.DIM_TIME_R
    WHERE
         V_END_OF_FISCAL_MONTH_IND_R='Y'
        AND EXTRACT(MONTH FROM D_CALENDAR_DATE_R) = EXTRACT(MONTH FROM LD_LIFE_VALUATION_DATE)
        AND EXTRACT(YEAR FROM D_CALENDAR_DATE_R) = EXTRACT(YEAR FROM LD_LIFE_VALUATION_DATE);


		lc_trcmsg:='1.1 CYCLE_DATE LD_LIFE_MIS_DATE_R is :->'||LD_LIFE_MIS_DATE_R;

		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r(
						p_job_id_r                    	=> ln_out_job_id,
						p_batch_id_r                  	=> ln_sysdt_batchid,
						p_message_type_r              	=> lv_message_type_r,
						p_code_location_r             	=> lc_main_loadedby,
						p_message_r                   	=> lc_trcmsg,
						p_count_type_r                	=> NULL,
						p_count_r                     	=> NULL,
						p_duration_r                  	=> NULL,
						p_created_by_r                	=> lc_job_name,
						out_prcs_job_log_message_id_r 	=> ln_job_log_message_id_r
						);




    /*Update added for defaulting pct to 1 for all CIB coverages
    UPDATE
        FCT_LG_RESERVE_DETAILS_R
    SET
        N_PRIMARY_REINSURER_REINSURANCE_PCT_R = 1,
        N_TOTAL_REINSURANCE_PCT_R = 0
    WHERE
        V_COVERAGE_CODE_R = 'CIB'
    AND
        D_RESERVE_VALUATION_DATE_R=LD_LIFE_MIS_DATE_R;
	lc_run_cnt:= SQL%ROWCOUNT;
    COMMIT;

	LC_TRCMSG:= '2 Updated N_PRIMARY_REINSURER_REINSURANCE_PCT_R,N_TOTAL_REINSURANCE_PCT_R for V_COVERAGE_CODE_R-CIB for LD_LIFE_MIS_DATE_R-'||LD_LIFE_MIS_DATE_R||' and record count-'||lc_run_cnt;


		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
	 (
		p_job_id_r                    => ln_out_job_id,
		p_batch_id_r                  => ln_sysdt_batchid,
		p_message_type_r              => lv_message_type_r,
		p_code_location_r             => lc_main_loadedby,
		p_message_r                   => lc_trcmsg,
		p_count_type_r                => lc_count_type_r,
		p_count_r                     => lc_run_cnt,
		p_duration_r                  => NULL,
		p_created_by_r                => lc_job_name,
		out_prcs_job_log_message_id_r => ln_job_log_message_id_r
	);
	*/

    /* LTD claims */
	MERGE INTO FCT_LG_RESERVE_DETAILS_R FLRDR
	USING (
			  SELECT
				  N_CLAIM_SK_R,
				  V_CLAIM_NUMBER_R,
				  V_PRIMARY_REINSURER_R,
				  CASE WHEN nvl(N_SECONDARY_REINSURER_REINS_PCT_R, 0) <= 0 THEN NULL ELSE V_SECONDARY_REINSURER_R END AS V_SECONDARY_REINSURER_R,
				  CASE WHEN nvl(N_TERNARY_REINSURER_REINS_PCT_R, 0) <= 0 THEN NULL ELSE V_TERNARY_REINSURER_R END AS V_TERNARY_REINSURER_R,
				  CASE
					WHEN nvl(N_TOTAL_REINSURER_REINS_PCT, 0) <= 0 THEN NULL
					ELSE N_TOTAL_REINSURER_REINS_PCT
				  END AS N_TOTAL_REINSURER_REINS_PCT,
				  N_PRIMARY_REINSURER_REINS_PCT_R,
				  CASE WHEN nvl(N_SECONDARY_REINSURER_REINS_PCT_R, 0) <= 0 THEN NULL ELSE N_SECONDARY_REINSURER_REINS_PCT_R END AS N_SECONDARY_REINSURER_REINS_PCT_R,
				  CASE WHEN nvl(N_TERNARY_REINSURER_REINS_PCT_R, 0) <= 0 THEN NULL ELSE N_TERNARY_REINSURER_REINS_PCT_R END AS N_TERNARY_REINSURER_REINS_PCT_R,
				  N_PRIMARY_REINSURER_REINS_SHARE_PCT_R,
				  CASE WHEN nvl(N_SECONDARY_REINSURER_REINS_PCT_R, 0) <= 0 THEN NULL ELSE N_SECONDARY_REINSURER_REINS_SHARE_PCT_R END AS N_SECONDARY_REINSURER_REINS_SHARE_PCT_R,
				  CASE WHEN nvl(N_TERNARY_REINSURER_REINS_PCT_R, 0) <= 0 THEN NULL ELSE N_TERNARY_REINSURER_REINS_SHARE_PCT_R END AS N_TERNARY_REINSURER_REINS_SHARE_PCT_R
			  FROM
				  ATOMIC.STG_GRP_REINSURER_CLAIM_PCT_R
              WHERE (V_CLAIM_NUMBER_R LIKE '%LTD%' OR V_CLAIM_NUMBER_R LIKE '%VPL%' OR V_CLAIM_NUMBER_R LIKE '%VLT%')
              AND N_PRIMARY_REINSURER_REINS_PCT_R > 0
              AND V_PRIMARY_REINSURER_R IS NOT NULL
              AND N_TOTAL_REINSURER_REINS_PCT > 0
		  )
	sgrcpr ON ( FLRDR.v_claim_number_r = sgrcpr.v_claim_number_r
		   AND FLRDR.N_CLAIM_SK_R = sgrcpr.N_CLAIM_SK_R
		   AND FLRDR.D_RESERVE_VALUATION_DATE_R=LD_LIFE_MIS_DATE_R
           )
	WHEN MATCHED THEN UPDATE
	SET FLRDR.v_primary_reinsurer_r = sgrcpr.v_primary_reinsurer_r,
		FLRDR.v_secondary_reinsurer_r = sgrcpr.v_secondary_reinsurer_r,
		FLRDR.v_ternary_reinsurer_r = sgrcpr.v_ternary_reinsurer_r,
		FLRDR.N_TOTAL_REINSURANCE_PCT_R = sgrcpr.N_TOTAL_REINSURER_REINS_PCT,
		FLRDR.N_PRIMARY_REINSURER_REINSURANCE_PCT_R = sgrcpr.n_primary_reinsurer_reins_pct_r,
		FLRDR.n_secondary_reinsurer_reinsurance_pct_r = sgrcpr.n_secondary_reinsurer_reins_pct_r,
		FLRDR.n_ternary_reinsurer_reinsurance_pct_r = sgrcpr.n_ternary_reinsurer_reins_pct_r,
		FLRDR.N_PRIMARY_REINSURER_REINS_SHARE_PCT_R = sgrcpr.N_PRIMARY_REINSURER_REINS_SHARE_PCT_R,
		FLRDR.N_SECONDARY_REINSURER_REINS_SHARE_PCT_R = sgrcpr.N_SECONDARY_REINSURER_REINS_SHARE_PCT_R,
		FLRDR.N_TERNARY_REINSURER_REINS_SHARE_PCT_R = sgrcpr.N_TERNARY_REINSURER_REINS_SHARE_PCT_R;
	lc_run_cnt:= SQL%ROWCOUNT;
    COMMIT;

	    lc_trcmsg:='2 Merged LTD Claims Reins columns into FCT_LG_RESERVE_DETAILS_R for valuationdate :->'||LD_LIFE_MIS_DATE_R||' and Record count-'||lc_run_cnt;




		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
	 (
		p_job_id_r                    => ln_out_job_id,
		p_batch_id_r                  => ln_sysdt_batchid,
		p_message_type_r              => lv_message_type_r,
		p_code_location_r             => lc_main_loadedby,
		p_message_r                   => lc_trcmsg,
		p_count_type_r                => lc_count_type_r,
		p_count_r                     => lc_run_cnt,
		p_duration_r                  => NULL,
		p_created_by_r                => lc_job_name,
		out_prcs_job_log_message_id_r => ln_job_log_message_id_r
	);

    /* Waiver Claims */
    MERGE INTO FCT_LG_RESERVE_DETAILS_R FLRDR
	USING (
			  SELECT DISTINCT
				  N_CLAIM_SK_R,
				  V_CLAIM_IDENTIFIER_R,
				  V_PRIMARY_REINSURER_R,
				  CASE WHEN N_SECONDARY_REINSURER_REINS_PCT_R < 0 THEN NULL ELSE V_SECONDARY_REINSURER_R END AS V_SECONDARY_REINSURER_R,
				  CASE WHEN N_TERNARY_REINSURER_REINS_PCT_R < 0 THEN NULL ELSE V_TERNARY_REINSURER_R END AS V_TERNARY_REINSURER_R,
				  CASE
					WHEN N_TOTAL_REINSURER_REINS_PCT < 0 THEN NULL
					ELSE N_TOTAL_REINSURER_REINS_PCT
				  END AS N_TOTAL_REINSURER_REINS_PCT,
				  N_PRIMARY_REINSURER_REINS_PCT_R,
				  CASE WHEN N_SECONDARY_REINSURER_REINS_PCT_R < 0 THEN NULL ELSE N_SECONDARY_REINSURER_REINS_PCT_R END AS N_SECONDARY_REINSURER_REINS_PCT_R,
				  CASE WHEN N_TERNARY_REINSURER_REINS_PCT_R < 0 THEN NULL ELSE N_TERNARY_REINSURER_REINS_PCT_R END AS N_TERNARY_REINSURER_REINS_PCT_R,
				  N_PRIMARY_REINSURER_REINS_SHARE_PCT_R,
				  CASE WHEN N_SECONDARY_REINSURER_REINS_PCT_R < 0 THEN NULL ELSE N_SECONDARY_REINSURER_REINS_SHARE_PCT_R END AS N_SECONDARY_REINSURER_REINS_SHARE_PCT_R,
				  CASE WHEN N_TERNARY_REINSURER_REINS_PCT_R < 0 THEN NULL ELSE N_TERNARY_REINSURER_REINS_SHARE_PCT_R END AS N_TERNARY_REINSURER_REINS_SHARE_PCT_R
			  FROM
				  ATOMIC.STG_GRP_REINSURER_CLAIM_PCT_R
              WHERE (V_CLAIM_IDENTIFIER_R LIKE '%WOP%' OR V_CLAIM_IDENTIFIER_R LIKE '%NONS%')
              AND N_PRIMARY_REINSURER_REINS_PCT_R > 0
              AND V_PRIMARY_REINSURER_R IS NOT NULL
              AND N_TOTAL_REINSURER_REINS_PCT > 0
		  )
	sgrcpr ON ( FLRDR.V_CLAIM_IDENTIFIER_R = sgrcpr.V_CLAIM_IDENTIFIER_R
		   AND FLRDR.n_claim_sk_r = sgrcpr.n_claim_sk_r
           --AND FLRDR.V_COVERAGE_CODE_R = SGRCPR.V_CLAIM_COVERAGE_CODE_R
		   AND FLRDR.D_RESERVE_VALUATION_DATE_R=LD_LIFE_MIS_DATE_R
           )
	WHEN MATCHED THEN UPDATE
	SET FLRDR.v_primary_reinsurer_r = sgrcpr.v_primary_reinsurer_r,
		FLRDR.v_secondary_reinsurer_r = sgrcpr.v_secondary_reinsurer_r,
		FLRDR.v_ternary_reinsurer_r = sgrcpr.v_ternary_reinsurer_r,
		FLRDR.N_TOTAL_REINSURANCE_PCT_R = sgrcpr.N_TOTAL_REINSURER_REINS_PCT,
		FLRDR.N_PRIMARY_REINSURER_REINSURANCE_PCT_R = sgrcpr.n_primary_reinsurer_reins_pct_r,
		FLRDR.n_secondary_reinsurer_reinsurance_pct_r = sgrcpr.n_secondary_reinsurer_reins_pct_r,
		FLRDR.n_ternary_reinsurer_reinsurance_pct_r = sgrcpr.n_ternary_reinsurer_reins_pct_r,
		FLRDR.N_PRIMARY_REINSURER_REINS_SHARE_PCT_R = sgrcpr.N_PRIMARY_REINSURER_REINS_SHARE_PCT_R,
		FLRDR.N_SECONDARY_REINSURER_REINS_SHARE_PCT_R = sgrcpr.N_SECONDARY_REINSURER_REINS_SHARE_PCT_R,
		FLRDR.N_TERNARY_REINSURER_REINS_SHARE_PCT_R = sgrcpr.N_TERNARY_REINSURER_REINS_SHARE_PCT_R;
	lc_run_cnt:= SQL%ROWCOUNT;
    COMMIT;

	lc_trcmsg:='3 Merged Other Waiver claims  Reins columns into FCT_LG_RESERVE_DETAILS_R For Valuation_date :->'||LD_LIFE_MIS_DATE_R||' and Record Count-'||lc_run_cnt;



	 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
	 (
		p_job_id_r                    => ln_out_job_id,
		p_batch_id_r                  => ln_sysdt_batchid,
		p_message_type_r              => lv_message_type_r,
		p_code_location_r             => lc_main_loadedby,
		p_message_r                   => lc_trcmsg,
		p_count_type_r                => lc_count_type_r,
		p_count_r                     => lc_run_cnt,
		p_duration_r                  => NULL,
		p_created_by_r                => lc_job_name,
		out_prcs_job_log_message_id_r => ln_job_log_message_id_r
	);


    /*Other (Life included) claims */
    MERGE INTO FCT_LG_RESERVE_DETAILS_R FLRDR
	USING (
			  SELECT DISTINCT
				  N_CLAIM_SK_R,
				  V_CLAIM_IDENTIFIER_R,
				  V_PRIMARY_REINSURER_R,
				  CASE WHEN N_SECONDARY_REINSURER_REINS_PCT_R < 0 THEN NULL ELSE V_SECONDARY_REINSURER_R END AS V_SECONDARY_REINSURER_R,
				  CASE WHEN N_TERNARY_REINSURER_REINS_PCT_R < 0 THEN NULL ELSE V_TERNARY_REINSURER_R END AS V_TERNARY_REINSURER_R,
				  CASE
					WHEN N_TOTAL_REINSURER_REINS_PCT < 0 THEN NULL
					ELSE N_TOTAL_REINSURER_REINS_PCT
				  END AS N_TOTAL_REINSURER_REINS_PCT,
				  N_PRIMARY_REINSURER_REINS_PCT_R,
				  CASE WHEN N_SECONDARY_REINSURER_REINS_PCT_R < 0 THEN NULL ELSE N_SECONDARY_REINSURER_REINS_PCT_R END AS N_SECONDARY_REINSURER_REINS_PCT_R,
				  CASE WHEN N_TERNARY_REINSURER_REINS_PCT_R < 0 THEN NULL ELSE N_TERNARY_REINSURER_REINS_PCT_R END AS N_TERNARY_REINSURER_REINS_PCT_R,
				  N_PRIMARY_REINSURER_REINS_SHARE_PCT_R,
				  CASE WHEN N_SECONDARY_REINSURER_REINS_PCT_R < 0 THEN NULL ELSE N_SECONDARY_REINSURER_REINS_SHARE_PCT_R END AS N_SECONDARY_REINSURER_REINS_SHARE_PCT_R,
				  CASE WHEN N_TERNARY_REINSURER_REINS_PCT_R < 0 THEN NULL ELSE N_TERNARY_REINSURER_REINS_SHARE_PCT_R END AS N_TERNARY_REINSURER_REINS_SHARE_PCT_R
			  FROM
				  ATOMIC.STG_GRP_REINSURER_CLAIM_PCT_R
              WHERE (
                    V_CLAIM_NUMBER_R NOT LIKE '%WOP%' AND V_CLAIM_NUMBER_R NOT LIKE '%NONS%' AND
                    V_CLAIM_NUMBER_R NOT LIKE '%LTD%' AND V_CLAIM_NUMBER_R NOT LIKE '%VPL%' AND V_CLAIM_NUMBER_R NOT LIKE '%VLT%'
              )
              AND N_PRIMARY_REINSURER_REINS_PCT_R > 0
              AND V_PRIMARY_REINSURER_R IS NOT NULL
              AND N_TOTAL_REINSURER_REINS_PCT > 0
		  )
	sgrcpr ON ( FLRDR.V_CLAIM_IDENTIFIER_R = sgrcpr.V_CLAIM_IDENTIFIER_R
		   AND FLRDR.n_claim_sk_r = sgrcpr.n_claim_sk_r
           --AND FLRDR.V_COVERAGE_CODE_R = SGRCPR.V_CLAIM_COVERAGE_CODE_R
		   AND FLRDR.D_RESERVE_VALUATION_DATE_R=LD_LIFE_MIS_DATE_R
           )
	WHEN MATCHED THEN UPDATE
	SET FLRDR.v_primary_reinsurer_r = sgrcpr.v_primary_reinsurer_r,
		FLRDR.v_secondary_reinsurer_r = sgrcpr.v_secondary_reinsurer_r,
		FLRDR.v_ternary_reinsurer_r = sgrcpr.v_ternary_reinsurer_r,
		FLRDR.N_TOTAL_REINSURANCE_PCT_R = sgrcpr.N_TOTAL_REINSURER_REINS_PCT,
		FLRDR.N_PRIMARY_REINSURER_REINSURANCE_PCT_R = sgrcpr.n_primary_reinsurer_reins_pct_r,
		FLRDR.n_secondary_reinsurer_reinsurance_pct_r = sgrcpr.n_secondary_reinsurer_reins_pct_r,
		FLRDR.n_ternary_reinsurer_reinsurance_pct_r = sgrcpr.n_ternary_reinsurer_reins_pct_r,
		FLRDR.N_PRIMARY_REINSURER_REINS_SHARE_PCT_R = sgrcpr.N_PRIMARY_REINSURER_REINS_SHARE_PCT_R,
		FLRDR.N_SECONDARY_REINSURER_REINS_SHARE_PCT_R = sgrcpr.N_SECONDARY_REINSURER_REINS_SHARE_PCT_R,
		FLRDR.N_TERNARY_REINSURER_REINS_SHARE_PCT_R = sgrcpr.N_TERNARY_REINSURER_REINS_SHARE_PCT_R;
	lc_run_cnt:= SQL%ROWCOUNT;
    COMMIT;

	 lc_trcmsg:='4 Merged Other (Life included) claims  Reins columns into FCT_LG_RESERVE_DETAILS_R for Valuation_date :->'||LD_LIFE_MIS_DATE_R||' and record count-'||lc_run_cnt;


	 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
	 (
		p_job_id_r                    => ln_out_job_id,
		p_batch_id_r                  => ln_sysdt_batchid,
		p_message_type_r              => lv_message_type_r,
		p_code_location_r             => lc_main_loadedby,
		p_message_r                   => lc_trcmsg,
		p_count_type_r                => lc_count_type_r,
		p_count_r                     => lc_run_cnt,
		p_duration_r                  => NULL,
		p_created_by_r                => lc_job_name,
		out_prcs_job_log_message_id_r => ln_job_log_message_id_r
	);

		pkg_grp_log_util.prc_update_log(
      						ln_out_job_id                   --p_job_id
							,lc_success_status              --p_job_status
							,lc_errmsg                      --p_err_msg
							,lc_trcmsg                      --p_trc_msg
							,lc_main_loadedby               --p_log_util_called_by_r
							);


EXCEPTION
WHEN OTHERS THEN

	IF lc_errmsg IS NULL THEN
		lc_errmsg :=SUBSTR(SQLERRM,1,4000);
	    lc_trcmsg :='1.z Error in main - '||lc_errmsg;
	END IF;


   /*START: NEW LOGGING MECHANISM CHANGES*/
    pkg_grp_log_util.prc_update_log_message_r
			(
			n_prcs_job_log_message_id_r => ln_job_log_message_id_r,
			p_err_msg 					=> lc_trcmsg
				);
    /*END: NEW LOGGING MECHANISM CHANGES*/

	pkg_grp_log_util.prc_update_log
      (
        ln_out_job_id                   	--p_job_id
        ,lc_error_status                	--p_job_status
        ,lc_errmsg                       	--p_err_msg
        ,lc_trcmsg					     	--p_trc_msg
        ,lc_main_loadedby               	--p_log_util_called_by_r
      );
    RAISE;

END ;
/

