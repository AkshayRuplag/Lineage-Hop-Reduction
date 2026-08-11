create or replace PROCEDURE PROC_REFRESH_GRP_M_VIEW_TBLS (P_BATCH_ID_R IN NUMBER,
	P_MV_TBL_NAME IN VARCHAR2
	)as
   --17-Jun-2022: params changed
   --24-Jan-2023: MV's has been changed to physical tables
   --22-Mar-2023: Changes in Policy Specifiac MV tbl SELECT query
   --29 March add changes for claim_note_tier_mv_tbl--
   --30 March add Changes for FCT_BENEFIT_PAYMENT_DETAIL_OFFSET_MV_TBL
   --19-Apr-2023: Incorporated Gneansan Requested changes in F_PSR_CLAIM_COV_STATUS_MV
   --04-May-2023: As per Erica's request Changed Record Type to Benefit Payment in FCT_BENEFIT_PAYMENT_DETAIL_OFFSET_MV_TBL and also added new column V_OFFSET_TYPE_R
   --16-Jun2023: Added CLAIM_TIER_WFAM_MV_TBL MV as per Mereen's request
   --30 Jun 2023 : Added CLAIM_COVERAGE_MV_TBL as per Erica requested--
   --18 july 2023 : additional columns added in CLAIM_COVERAGE_MV_TBL given by erica----
/* --23-July-2023: Below are the enhancements requested by Erica for Policy Specific MV tbl
    For legacy sunset, there are some fields that need to be added to the policy specific MVs. For several of these, we already have the joins and only need to add columns in the select, but there are a few other join additions needed as well.

    1.	DIRECTOR_FULL_NAME
    a.	Add T391089. V_DIRECTOR_FULL_NAME_R in the select for F_PSR_CLAIM_COV_STATUS_MV_TBL, and add in final select for F_POLICY_SPECIFIC_MV_TBL
    b.	source is DIM_EMPLOYEE_R ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦ÃƒÂ¢Ã¢â€šÂ¬Ã…â€œ joins are already available in F_PSR_CLAIM_COV_STATUS_MV_TBL
    2.	SUPERVISOR_FULL_NAME
    a.	Add T391089. V_SUPERVISOR_FULL_NAME_R in the select for F_PSR_CLAIM_COV_STATUS_MV_TBL, and add in final select for F_POLICY_SPECIFIC_MV_TBL
    3.	DIRECTOR_LOGIN_ID
    a.	Add T391089. V_DIRECTOR_LOGIN_ID_R in the select for F_PSR_CLAIM_COV_STATUS_MV_TBL, and add in final select for F_POLICY_SPECIFIC_MV_TBL
    4.	SUPERVISOR_LOGIN_ID
    a.	Add T391089.V_SUPERVISOR_LOGIN_ID_Rin the select for F_PSR_CLAIM_COV_STATUS_MV_TBL, and add in final select for F_POLICY_SPECIFIC_MV_TBL
    5.	NURSE_CERT_OWN_OCC
    a.	Need to add additional join to F_PSR_CLAIM_COV_STATUS_MV_TBL
    b.	LEFT OUTER JOIN
      (SELECT *
      FROM dim_grp_nurse_cert_r c
      WHERE v_active_status_r = 'Y'
      AND N_NURSE_CERT_SEQ_R  =
        (SELECT MAX(N_NURSE_CERT_SEQ_R)
        FROM dim_grp_nurse_cert_r
        WHERE n_claim_sk_r    = c.n_claim_sk_r
        AND v_active_status_r = 'Y'
        )
      ) T527283
      -- D_GRP_NURSE_CERT_R_Claims
    ON T527283.N_CLAIM_SK_R = T333511. N_CLAIM_SK_R
    c.	Left outer join this sub query on claim directory based on claim sk
    d.	Select logic:
    i.	CASE
        WHEN T527283.D_NURSE_CERT_END_DATE_R > T357771.D_ANYOCC_START_DATE_R
        THEN 'Y'
        ELSE 'N'
      END                             AS NURSE_CERT_OWN_OCC

    6.	NURSE_CERT_END_DATE
    a.	Same joins as above, add   T527283.D_NURSE_CERT_END_DATE_R AS NURSE_CERT_END_DATE in the select for F_PSR_CLAIM_COV_STATUS_MV_TBL, and add in final select for F_POLICY_SPECIFIC_MV_TBL

    7.	NURSE_CERT_FLAG
    a.	Same joins as above, add below logic in the select for F_PSR_CLAIM_COV_STATUS_MV_TBL, and add in final select for F_POLICY_SPECIFIC_MV_TBL
    b.	CASE
        WHEN NVL(T527283.D_NURSE_CERT_END_DATE_R,sysdate) <= sysdate
        THEN 'x'
        ELSE NULL
      END AS NURSE_CERT_FLAG

    8.	TIER_CREATED_DATE
    a.	We already have a separate MV that we are using: CLAIM_NOTE_TIER_MV
    b.	Is it possible to add this directly in policy specific? We would need to make sure CLAIM_NOTE_TIER_MV is refreshed prior to F_POLICY_SPECIFIC_MV_TBL
    i.	LEFT OUTER JOIN CLAIM_NOTE_TIER_MV TIER_MV
    ON TIER_MV.N_CLAIM_SK_R = F_PSR_CLAIM_MV_1.Claim_Skey
    Select TIER_MV.D_CREATED_DATE_R as TIER_CREATED_DATE

    9.	TIER
    a.	Same join as above, select TIER_MV.V_TIER_R as TIER
    */
   --26 July 2023 : Added FCT_RPT_EOI_HISTORY_R_MV_TBL as per Mereen's request
   --22-aUG-2023 : in MV_1 block added gather table stats which increases  the performance of the load
   --12-Sep-2023 : As requested by Erica added below condition in the F_PSR_CLAIM_COV_STATUS_MV_TBL SELECT block
                  --Since the below join is giving error while compiling procedure hence created another view VW_DIM_GRP_CLAIM_PRIOR_STATUS_R_max on top of VW_DIM_GRP_CLAIM_PRIOR_STATUS_R and included below condition

                   /*and T424641.D_CLAIM_STATUS_CODE_EFF_DATE_R = (select max(max_cs.D_CLAIM_STATUS_CODE_EFF_DATE_R)
                   from VW_DIM_GRP_CLAIM_PRIOR_STATUS_R max_cs
                   where T424641.V_CLAIM_NUMBER_R= max_cs.V_CLAIM_NUMBER_R
                   and T424641.N_CLAIM_COVERAGE_SK_R= max_cs.N_CLAIM_COVERAGE_SK_R
                   and T424641.V_COVERAGE_CODE_R= max_cs.V_COVERAGE_CODE_R)*/
	--19-Sep-2023:Added FCT_CLAIM_PAYMENT_SUMMARY_MV_TBL and FCT_RPT_EOI_HISTORY_SUMM_MV_TBL as per Mereen's request.
	--16-Oct-2023:update the logic for F_PSR_CLAIMANT_MV certificate_number to remove the masking. We donÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢t need the substring, we can just show the results of the case statement as is.
	--18-Oct-2023:claim_mv_1 - the condition to only filter out null records for PACS claims
	--            F_PSR_CLAIM_COV_STATUS_MV_TBL, modified claim status code logic for CV
    /*
	--26-Oct-2023: below changes requested by Erica
	1.	In F_PSR_CLAIM_MV_1_TBL / F_PSR_CLAIM_MV_1, add column CURRENT_RESERVE NUMBER data type
    a.	Populate column:
    i.	In first part of query (before the union), populate the column as d_grp_claim_coverage_group_r_claims.N_RESERVE_AMOUNT_R - d_grp_claim_coverage_group_r_claims.N_WS_RELEASED_AMOUNT_R
    ii.	Add to group by as well
    iii.	In second part of query (after the union), populate null
    2.	In F_POLICY_SPECIFIC_MV/ F_POLICY_SPECIFIC_MV_TBL Add column CURRENT_RESERVE NUMBER data type
    a.	In the insert script, populate from F_PSR_CLAIM_MV_1_TBL CURRENT_RESERVE
    */
	--04-Dec-2023 : Added CLAIM_TIER_WFAM_MV_TBL changes
	--06-Dec-2023 : Added F_PSR_CLAIM_COV_STATUS_MV_TBL SELECT Claim Prior join changes
	--31-JAN-2024 : Added V_PAYEE_FIRST_NAME_R,V_PAYEE_MIDDLE_NAME_R,V_PAYEE_LAST_NAME_R,V_PAYEE_TYPE_R in FCT_BENEFIT_PAYMENT_DETAIL_OFFSET_MV_TBL
    --13-Feb-2024 : Modified logic in LG_RESERVES_MAX_RESERVE_VAL_DATE_MV_TBL
	--12-MAR-2024 : Added N_PARTY_SK_R in FCT_BENEFIT_PAYMENT_DETAIL_OFFSET_MV_TBL
	--26-Mar-2024 : Added column Policy_effective_date to F_POLICY_SPECIFIC_MV_TBL and mapped to ,F_PSR_CLAIM_MV_1.Policy_effective_date
	              -- Added column Policy_effective_date to F_PSR_CLAIM_MV_1_TBL and mapped to ,d_grp_policy_dir_r_policy.T_POLICY_EFFECTIVE_DATE_R 
	--27-Mar-2024 : Added column N_PRODUCT_SK_R,V_BASIC_PRODUCT_LINE_CODE_R,V_BASIC_PRODUCT_LINE_DESC_R to F_PSR_CLAIM_COV_STATUS_MV_TBL,F_POLICY_SPECIFIC_MV_TBL and mapped
    --07-May-2024 : Added column Cleint_Name in the tables F_POLICY_SPECIFIC_MV_tbl and F_PSR_CLAIMANT_MV_TBL 
    --13-May-2024 : Changed hint APPEND to APPEND_VALUES AND CLAIM_MV1 AND MVW_PRODUCT_SK_LOOKUP ADDED parallel(4) HINT
    --              Added INSERT APPEND_VALUES INTO where INSERT INTO is there
	--              added ,f.T_EVENT_TIMESTAMP_R desc in the select query of CLAIM_TIER_WFAM_MV_TBL 
    /*29-May-2024 Added below columns to FCT_BENEFIT_PAYMENT_DETAIL_OFFSET_MV_TBL
                  V_AMOUNT_TYPE_SUB_NAME_R
                  V_AMOUNT_TYPE_CATEGORY_R
                  V_AMOUNT_TYPE_CATEGORY_DESC_R
                  V_AMOUNT_TYPE_SUB_CATEGORY_R
                  V_AMT_TYPE_SUB_CATEGORY_DESC_R
                  V_AMOUNT_TYPE_CODE_R
                  V_AMOUNT_TYPE_NAME_R
                  V_AMOUNT_TYPE_SUB_CODE_R*/

    --10-Jul-2024 : In FCT_RPT_EOI_HISTORY_R_MV_TBL instead of A.* provided the actual column names
	--23-09-2024  : Added f.N_CREATED_ITIME_R in CLAIM_TIER_WFAM_MV_TBL
	--03-04-2025 Added distribution channel column to Policy Specific MV tbl
	--18-07-2025 Added STD Condition under MVW_PRODUCT_SK_LOOKUP_TBL Trunc-Load by Shashi
	--23-07-2025 : Updated the logic for N_TAXABLE_PERCENT_R in FCT_BENEFIT_PAYMENT_DETAIL_OFFSET_MV_TBL.


	V_SYS_DATE         VARCHAR2(15) := TO_CHAR(SYSDATE,'YYYYMMDDHHMISS');
	N_MAX_SERIAL_NUM_R NUMBER;
	V_SQLCODE          VARCHAR2(100);
	V_SQLERRM          VARCHAR2(500);
    gn_out_job_id number;
	--V_PLSQL_BLOCK_NAME_R VARCHAR2(500);
	LN_MV_REFRESH_CHK_CNT number:=0;
	LN_BATCH_ID_R         NUMBER :=NVL(P_BATCH_ID_R, TO_NUMBER(TO_CHAR(SYSDATE,'YYYYMMDD')));

	V_PAID_START_DATE date:=TO_DATE((extract(year from sysdate)-6)*10000+101,'yyyymmdd');  --added on 21/04/2022
	V_PAID_END_DATE date:=TO_DATE((extract(year from sysdate)-1)*10000+1231,'yyyymmdd'); --added on 21/04/2022

	/*CURSOR cur_mv_refresh_chk(CP_V_PLSQL_BLOCK_NAME_R IN VARCHAR2)
	IS
	SELECT COUNT(1)
	  FROM FCT_PROC_EXEC_STATUS_LOG_R
	WHERE  V_PLSQL_BLOCK_NAME_R= P_MV_TBL_NAME||'.'||CP_V_PLSQL_BLOCK_NAME_R
	  AND  N_BATCH_ID_R = LN_BATCH_ID_R
	  AND  V_STATUS_R                = 'Successful';
	  */
	begin
	-- Error logging 'Started'
	   /*--17-Jun-2022 changes
	   ln_mv_refresh_chk_cnt:=0;
	   OPEN cur_mv_refresh_chk('PROC_REFRESH_GRP_M_VIEW_TBLS.LG_RESERVES_MAX_RESERVE_VAL_DATE_MV');
	   FETCH cur_mv_refresh_chk INTO ln_mv_refresh_chk_cnt;
	   CLOSE cur_mv_refresh_chk;
	  */
	   --IF NVL(ln_mv_refresh_chk_cnt,0) =0 THEN --17-Jun-2022 changes
	   IF UPPER(TRIM(P_MV_TBL_NAME)) like  '%LG_RESERVES_MAX_RESERVE_VAL_DATE%' THEN --17-Jun-2022 changes

			Begin
			SELECT SEQ_FCT_PROC_EXEC_STATUS_LOG_R.NEXTVAL INTO N_MAX_SERIAL_NUM_R FROM DUAL;

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
				LN_BATCH_ID_R,--99999999,
				TO_CHAR(sysdate,'yyyymmdd'),
				1,
				'Started',
				SYSTIMESTAMP,
				USER,
				P_MV_TBL_NAME||'.PROC_REFRESH_GRP_M_VIEW_TBLS.LG_RESERVES_MAX_RESERVE_VAL_DATE_MV_TBL',
				N_MAX_SERIAL_NUM_R
				);
			COMMIT;
			--24-Jan-2023 changes starts
			--dbms_mview.refresh('LG_RESERVES_MAX_RESERVE_VAL_DATE_MV', method => 'C', atomic_refresh => FALSE);--24-Jan-2023 changes
			execute immediate 'truncate table LG_RESERVES_MAX_RESERVE_VAL_DATE_MV_TBL purge snapshot log';
			INSERT
			  /*+APPEND_VALUES*/
			INTO LG_RESERVES_MAX_RESERVE_VAL_DATE_MV_TBL
			  (
				CLAIM_IDENTIFIER,
				CLAIM_ID_RESERVE_VALUATION_DATE,
				RESERVE_VALUATION_DATE
			  )
			SELECT
			  DISTINCT d1.c5                                                     AS CLAIM_IDENTIFIER,
			  concat(D1.c5, NVL(CAST(D1.c2 AS VARCHAR ( 20 ) ) , '01-JAN-1900')) AS CLAIM_ID_RESERVE_VALUATION_DATE,
			  NVL(CAST(D1.c2 AS VARCHAR ( 20 ) ) , '01/JAN/1900')                AS RESERVE_VALUATION_DATE
			FROM
			--13-Feb-2024 changes starts
						  (SELECT
				MAX(1)                                  AS c1,
				MAX(T424800.D_RESERVE_VALUATION_DATE_R) AS c2,
				t357774.v_claim_identifier_r                AS c5
			  FROM dim_grp_claim_coverage_group_r  t357774 /* D_GRP_CLAIM_COVERAGE_GROUP_R_Claims */ 

			  LEFT OUTER JOIN fct_lg_reserve_details_r        t424800 /* F_LG_RESERVE_DETAILS_R_Legacy */ 
			  ON t357774.v_claim_identifier_r = t424800.v_claim_identifier_r

			WHERE
			t357774.v_active_status_r='Y'			 
			  GROUP BY t357774.v_claim_identifier_r
			  )d1;
			  /*
			  (SELECT
				MAX(1)                                  AS c1,
				MAX(T424800.D_RESERVE_VALUATION_DATE_R) AS c2,
				T333136.V_POLICY_PREFIX_R               AS c3,
				CASE
				  WHEN T333136.V_POLICY_PREFIX_R = 'SC'
				  THEN NULL
				  ELSE T333136.V_POLICY_SUFFIX_R
				END AS c4,
				CASE
				  WHEN NOT CAST(T357774.N_COV_GRP_ID_R AS VARCHAR ( 10 ) ) IS NULL
				  THEN
					CASE
					  WHEN CAST(T357774.N_COV_GRP_ID_R AS VARCHAR ( 10 ) ) BETWEEN 1 AND 9
					  THEN concat(concat(T333511.V_CLAIM_NUMBER_R, '-0'), CAST(T357774.N_COV_GRP_ID_R AS VARCHAR ( 10 ) ))
					  ELSE concat(concat(T333511.V_CLAIM_NUMBER_R, '-'), CAST(T357774.N_COV_GRP_ID_R AS  VARCHAR ( 10 ) ))
					END
				  ELSE T333511.V_CLAIM_NUMBER_R
				END AS c5
			  FROM (DIM_GRP_POLICY_DIR_R T333136
				-- D_GRP_POLICY_DIR_R_Policy 
			  LEFT OUTER JOIN DIM_GRP_CLAIM_DIR_R T333511
				-- D_GRP_CLAIM_DIR_R_Claim 
			  ON T333136.N_POLICY_SK_R = t333511.n_policy_sk_r)
			 -- LEFT OUTER JOIN fct_lg_reserve_details_r t424800
			 -- F_LG_RESERVE_DETAILS_R_Legacy 
			 --  ON t333511.v_claim_number_r = t424800.v_claim_number_r,
			--dim_grp_claim_detail_r t333447
			 -- D_GRP_CLAIM_DETAIL_R_Claim 
			 -- ,
			--dim_grp_claim_coverage_r t357788
			 -- D_GRP_CLAIM_COVERAGE_R_Claims 
			 -- ,
			 --dim_grp_claim_coverage_group_r t357774 
			 -- D_GRP_CLAIM_COVERAGE_GROUP_R_Claims 
			 -- WHERE ( t333447.n_claim_sk_r      = t333511.n_claim_sk_r
			 -- AND t333447.n_claim_sk_r          = t357788.n_claim_sk_r
			 -- AND t333136.v_active_status_r     = 'Y'
			 -- AND t333447.v_active_status_r     = 'Y'
			 -- AND t333511.v_active_status_r     = 'Y'
			 -- AND t357774.n_claim_coverage_sk_r = t357788.n_claim_coverage_sk_r
			 -- AND t357774.v_active_status_r     = 'Y'
			 -- AND t357788.v_active_status_r     = 'Y' )
	--Converted inner joins to Left outer joins requesting by Ganesan 
			  LEFT OUTER JOIN fct_lg_reserve_details_r        t424800   ON t333511.v_claim_number_r = t424800.v_claim_number_r
				LEFT OUTER JOIN dim_grp_claim_detail_r          t333447 ON t333447.n_claim_sk_r = t333511.n_claim_sk_r
				LEFT OUTER JOIN dim_grp_claim_coverage_r        t357788 ON t333447.n_claim_sk_r = t357788.n_claim_sk_r
				LEFT OUTER JOIN dim_grp_claim_coverage_group_r  t357774  ON t357774.n_claim_coverage_sk_r = t357788.n_claim_coverage_sk_r
			WHERE
				( t333136.v_active_status_r = 'Y'
				  AND nvl(t333447.v_active_status_r,'Y') = 'Y'
				  AND nvl(t333511.v_active_status_r,'Y') = 'Y'
				  AND nvl(t357774.v_active_status_r,'Y') = 'Y'
				  AND nvl(t357788.v_active_status_r,'Y') = 'Y' )
			  GROUP BY t333136.v_policy_prefix_r,
				CASE
				  WHEN t333136.v_policy_prefix_r = 'SC'
				  THEN NULL
				  ELSE t333136.v_policy_suffix_r
				END,
				CASE
				  WHEN NOT CAST(t357774.n_cov_grp_id_r AS VARCHAR(10)) IS NULL
				  THEN
					CASE
					  WHEN CAST(t357774.n_cov_grp_id_r AS VARCHAR(10)) BETWEEN 1 AND 9
					  THEN concat(concat(t333511.v_claim_number_r, '-0'), CAST(t357774.n_cov_grp_id_r AS VARCHAR(10)))
					  ELSE concat(concat(t333511.v_claim_number_r, '-'), CAST(t357774.n_cov_grp_id_r AS  VARCHAR(10)))
					END
				  ELSE t333511.v_claim_number_r
				END
			  ) d1;*/--13-Feb-2024 changes ends
			UPDATE FCT_PROC_EXEC_STATUS_LOG_R
						SET V_STATUS_R                = 'Successful',
						T_EXECUTION_END_TIMESTAMP_R = systimestamp
						WHERE N_SERIAL_NUM_R          = N_MAX_SERIAL_NUM_R;
						COMMIT;
			EXCEPTION
			WHEN OTHERS THEN
				V_SQLCODE                    := SQLCODE;
						V_SQLERRM                    := SUBSTR(SYS.STANDARD.SQLERRM,1,500);
						UPDATE FCT_PROC_EXEC_STATUS_LOG_R
						SET V_STATUS_R                = 'Failed',
						T_EXECUTION_END_TIMESTAMP_R = systimestamp,
						V_ERROR_CODE_R				= V_SQLCODE,
						V_ERROR_DESC_R				= V_SQLERRM
						WHERE N_SERIAL_NUM_R          = N_MAX_SERIAL_NUM_R;
					COMMIT;
						RAISE;
			END;

		END IF;
		/*--17-Jun-2022 changes
		ln_mv_refresh_chk_cnt:=0;
		OPEN cur_mv_refresh_chk('PROC_REFRESH_GRP_M_VIEW_TBLS.CLAIM_ACTIVITY_DATE_MV');
		FETCH cur_mv_refresh_chk INTO ln_mv_refresh_chk_cnt;
		CLOSE cur_mv_refresh_chk;

		IF NVL(ln_mv_refresh_chk_cnt,0) =0 THEN */
	   IF UPPER(TRIM(P_MV_TBL_NAME)) like  '%CLAIM_ACTIVITY_DATE_MV%' THEN --17-Jun-2022 changes

			Begin
				SELECT SEQ_FCT_PROC_EXEC_STATUS_LOG_R.NEXTVAL INTO N_MAX_SERIAL_NUM_R FROM DUAL;

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
					LN_BATCH_ID_R,--99999999,
					TO_CHAR(sysdate,'yyyymmdd'),
					1,
					'Started',
					SYSTIMESTAMP,
					USER,
					P_MV_TBL_NAME||'.PROC_REFRESH_GRP_M_VIEW_TBLS.CLAIM_ACTIVITY_DATE_MV_TBL',
					N_MAX_SERIAL_NUM_R
					);
				COMMIT;
				--24-Jan-2023 changes start
				--dbms_mview.refresh('CLAIM_ACTIVITY_DATE_MV', method => 'C', atomic_refresh => FALSE);
				EXECUTE IMMEDIATE 'TRUNCATE TABLE CLAIM_ACTIVITY_DATE_MV_TBL PURGE SNAPSHOT LOG';
				 INSERT /*+APPEND_VALUES*/ INTO CLAIM_ACTIVITY_DATE_MV_TBL (MOST_RECENT_ACTIVITY_DATE, V_CLAIM_NUMBER_R, N_CLAIM_SK_R)
				SELECT MAX( CAST(TO_DATE(SUBSTR(A.V_DC_TIMESTAMP_R , 1 , 8),'YYYYMMDD') AS DATE )) AS MOST_RECENT_ACTIVITY_DATE ,
				b.v_claim_number_r as v_claim_number_r, b.n_claim_sk_r as n_claim_sk_r
				from fct_grp_transactions_r a ,
				dim_grp_claim_dir_r b
				where a.n_claim_sk_r = b.n_claim_sk_r
				GROUP BY B.V_CLAIM_NUMBER_R, B.N_CLAIM_SK_R
				;
				--24-Jan-2023 changes end
				UPDATE FCT_PROC_EXEC_STATUS_LOG_R
							SET V_STATUS_R                = 'Successful',
							T_EXECUTION_END_TIMESTAMP_R = systimestamp
							WHERE N_SERIAL_NUM_R          = N_MAX_SERIAL_NUM_R;
							COMMIT;
			EXCEPTION
			WHEN OTHERS THEN
				V_SQLCODE                    := SQLCODE;
						V_SQLERRM                    := SUBSTR(SYS.STANDARD.SQLERRM,1,500);
						UPDATE FCT_PROC_EXEC_STATUS_LOG_R
						SET V_STATUS_R                = 'Failed',
						T_EXECUTION_END_TIMESTAMP_R = systimestamp,
						V_ERROR_CODE_R				= V_SQLCODE,
						V_ERROR_DESC_R				= V_SQLERRM
						WHERE N_SERIAL_NUM_R          = N_MAX_SERIAL_NUM_R;
					COMMIT;
						RAISE;
			END;
		END IF;
		/*--17-Jun-2022 changes
		ln_mv_refresh_chk_cnt:=0;
		OPEN cur_mv_refresh_chk('PROC_REFRESH_GRP_M_VIEW_TBLS.MVW_PRODUCT_SK_LOOKUP');
		FETCH cur_mv_refresh_chk INTO ln_mv_refresh_chk_cnt;
		CLOSE cur_mv_refresh_chk;

		IF NVL(ln_mv_refresh_chk_cnt,0) =0 THEN */
	   IF UPPER(TRIM(P_MV_TBL_NAME)) like  '%MVW_PRODUCT_SK_LOOKUP%' THEN --17-Jun-2022 changes

			Begin
			SELECT SEQ_FCT_PROC_EXEC_STATUS_LOG_R.NEXTVAL INTO N_MAX_SERIAL_NUM_R FROM DUAL;

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
				LN_BATCH_ID_R,--99999999,
				TO_CHAR(sysdate,'yyyymmdd'),
				1,
				'Started',
				SYSTIMESTAMP,
				USER,
				P_MV_TBL_NAME||'.PROC_REFRESH_GRP_M_VIEW_TBLS.MVW_PRODUCT_SK_LOOKUP_TBL',
				N_MAX_SERIAL_NUM_R
				);
			COMMIT;
			--24-Jan-2023 changes start
			--dbms_mview.refresh('MVW_PRODUCT_SK_LOOKUP', method => 'C', atomic_refresh => FALSE);

			EXECUTE IMMEDIATE 'TRUNCATE TABLE MVW_PRODUCT_SK_LOOKUP_TBL PURGE SNAPSHOT LOG';
			INSERT /*+APPEND_VALUES*/ INTO MVW_PRODUCT_SK_LOOKUP_TBL (N_CLAIM_SK_R, V_CLAIM_NUMBER_R, V_CLAIM_COVERAGE_CODE_R, N_PRODUCT_SK_R)
			   SELECT 
			   /*+PARALLEL(4)*/ --13-May-2024 changes
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
										'STD'			   ---Added this condition for bug 424884 by Shashi	
									WHEN v_claim_coverage_code_r = 'NYPL'
										 AND v_line_of_business_r IN ( 'DBL' ) THEN
										'STD'			   ---Added this condition for bug 437947 by Shashi	
                                    WHEN v_claim_coverage_code_r = 'ASW'
										 AND v_line_of_business_r IN ( 'ASW' ) THEN
										'STD'			    ---Added this condition for bug 437947 by Shashi							
									WHEN v_claim_coverage_code_r = 'FLI'
										 AND v_line_of_business_r IN ( 'TDB' ) THEN
										'STD'			    ---Added this condition for bug 437947 by Shashi	
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
									  --  dim_grp_claim_coverage_group_r    b,
										fct_grp_policy_r                  c,
										(select * from dim_grp_claim_dir_r  where v_active_status_r = 'Y')   d,
										(select * from dim_grp_policy_dir_r where v_active_status_r = 'Y')   e
									WHERE
										   -- a.n_claim_coverage_sk_r = b.n_claim_coverage_sk_r
											a.n_claim_sk_r = d.n_claim_sk_r
										AND d.n_policy_sk_r = c.n_policy_sk_r
										AND e.n_policy_sk_r = c.n_policy_sk_r
										AND e.n_policy_version_number_r = c.n_version_number_r
								) 
								WHERE
									v_claim_coverage_code_r IN ( 'A/R', 'A/V', 'GAD', 'GCM', 'ORL',
													   'PTD', 'SAD', 'VAD', 'VGT', 'GWI',
													   'JAL', 'GPL',
													   'SC', 'STD', 'NYPL', 'ASW', 'FLI', 'FMLA' )   -----Added STD value for bug 424884 by Shashi	
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
			--24-Jan-2023 changes ends

			Commit;
		INSERT /*+APPEND_VALUES*/ INTO MVW_PRODUCT_SK_LOOKUP_TBL (N_CLAIM_SK_R, V_CLAIM_NUMBER_R, V_CLAIM_COVERAGE_CODE_R, N_PRODUCT_SK_R)
			-- Added a new block to split the above union block into 2 for performance improvement 12-DEC-2025																						 
		SELECT 
		/*+PARALLEL(4)*/ --13-May-2024 changes
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
										'STD'	  ---Added this condition for bug 424884 by Shashi
									WHEN v_claim_coverage_code_r = 'NYPL'
										 AND v_line_of_business_r IN ( 'DBL' ) THEN
										'STD'			   ---Added this condition for bug 437947 by Shashi	
                                    WHEN v_claim_coverage_code_r = 'ASW'
										 AND v_line_of_business_r IN ( 'ASW' ) THEN
										'STD'			    ---Added this condition for bug 437947 by Shashi
                                    WHEN v_claim_coverage_code_r = 'FLI'
										 AND v_line_of_business_r IN ( 'TDB' ) THEN
										'STD'			    ---Added this condition for bug 437947 by Shashi	
							        WHEN v_claim_coverage_code_r = 'FMLA'
										 AND v_line_of_business_r IN ( 'FML' ) THEN
										'STD'			 ---Added this condition for bug 437947 by Shashi								
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
									  --      a.n_claim_coverage_sk_r = b.n_claim_coverage_sk_r
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
													 'SC', 'STD', 'NYPL', 'ASW', 'FLI', 'FMLA')  -----Added STD vale for bug 42488 by Shashi	

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
			COMMIT;

			UPDATE FCT_PROC_EXEC_STATUS_LOG_R
						SET V_STATUS_R                = 'Successful',
						T_EXECUTION_END_TIMESTAMP_R = systimestamp
						WHERE N_SERIAL_NUM_R          = N_MAX_SERIAL_NUM_R;
						COMMIT;
			EXCEPTION
			WHEN OTHERS THEN
				V_SQLCODE                    := SQLCODE;
						V_SQLERRM                    := SUBSTR(SYS.STANDARD.SQLERRM,1,500);
						UPDATE FCT_PROC_EXEC_STATUS_LOG_R
						SET V_STATUS_R                = 'Failed',
						T_EXECUTION_END_TIMESTAMP_R = systimestamp,
						V_ERROR_CODE_R				= V_SQLCODE,
						V_ERROR_DESC_R				= V_SQLERRM
						WHERE N_SERIAL_NUM_R          = N_MAX_SERIAL_NUM_R;
					COMMIT;
						RAISE;
			END;
		END IF;
		/*--17-Jun-2022 changes
		ln_mv_refresh_chk_cnt:=0;
		OPEN cur_mv_refresh_chk('PROC_REFRESH_GRP_M_VIEW_TBLS.F_PSR_CLAIM_MV_1');
		FETCH cur_mv_refresh_chk INTO ln_mv_refresh_chk_cnt;
		CLOSE cur_mv_refresh_chk;

		IF NVL(ln_mv_refresh_chk_cnt,0) =0 THEN */
		IF UPPER(TRIM(P_MV_TBL_NAME)) like  '%F_PSR_CLAIM_MV_1%' THEN --17-Jun-2022 changes

		    --22-Aug-2023 changes starts
			begin
               FOR I IN (SELECT TABLE_NAME FROM ALL_TABLES WHERE TABLE_NAME IN  (
               'MVW_PRODUCT_SK_LOOKUP_TBL'
               ,'DIM_GRP_CLAIM_DETAIL_R'
               ,'DIM_GRP_CLAIM_COVERAGE_R'
               ,'DIM_GRP_CLAIM_COVERAGE_GROUP_R'
               ,'DIM_GRP_POLICY_DIR_R'
               ,'DIM_GRP_CLAIM_DIR_R'
               ,'DIM_GRP_CLAIM_ELIGIBILITY_R'
               ,'DIM_GRP_CLAIM_EVENT_R'
               ,'DIM_GRP_CLAIM_EVENT_DIR_R'
               ,'DIM_GRP_EEOC_R'
               ,'DIM_GRP_BUSOBJ_AUDIT_R'
               ,'DIM_GRP_PARTY_R'
               ,'FCT_GRP_TRANSACTIONS_r'
               ,'DIM_GRP_CLAIM_PRIOR_STATUS_R'
               ,'FCT_GRP_WORKSHEET_PD')
			   AND OWNER='ATOMIC'
			   )
               LOOP
               DBMS_STATS.GATHER_TABLE_STATS('ATOMIC',I.TABLE_NAME);
               end LOOP;
            exception
            when others then
            null;
            END;
		    --22-Aug-2023 changes ends
			Begin
			SELECT SEQ_FCT_PROC_EXEC_STATUS_LOG_R.NEXTVAL INTO N_MAX_SERIAL_NUM_R FROM DUAL;
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
				LN_BATCH_ID_R,--99999999,
				TO_CHAR(sysdate,'yyyymmdd'),
				1,
				'Started',
				SYSTIMESTAMP,
				USER,
				P_MV_TBL_NAME||'.PROC_REFRESH_GRP_M_VIEW_TBLS.F_PSR_CLAIM_MV_1_TBL',
				N_MAX_SERIAL_NUM_R
				);
			COMMIT;
			--dbms_mview.refresh('F_PSR_CLAIM_MV_1', method => 'C', atomic_refresh => FALSE);
			EXECUTE IMMEDIATE 'TRUNCATE TABLE F_PSR_CLAIM_MV_1_TBL PURGE SNAPSHOT LOG';

			PKG_GRP_COMMON_UTIL.prc_force_indexes_unusable
			(
			p_out_job_id   		  		  => gn_out_job_id,
			p_rpt_table			   		  => 'FCT_BILLING_POLICY_PREMIUM_R_TABLE',
			p_Log_seq_num             	  => 1
			);

			INSERT
			  /*+APPEND_VALUES*/
			INTO F_PSR_CLAIM_MV_1_TBL
			  (
				POLICY_SKEY                       ,
              CLAIM_SKEY                        ,
              ADMINISTERED_BY                   ,
              AS_OF_DATE                        ,
              CLAIM_IDENTIFIER                  ,
              POLICY_PREFIX                     ,
              POLICY_SUFFIX                     ,
              WORKSHEET_END_DATE                ,
              WORKSHEET_START_DATE              ,
              CLAIM_CLOSED_DATE                 ,
              CLAIM_GROSS_BENEFIT_AMOUNT        ,
              CLAIM_MOST_RECENT_ACTIVITY_DATE   ,
              CLAIM_NET_BENEFIT_AMOUNT          ,
              CLAIM_NUMBER                      ,
              CLAIM_RECEIVED_DATE               ,
              CLAIM_TAXABLE_BENEFIT_PERCENTAGE  ,
              DURATION_INDICATOR                ,
              DURATION_PERIOD                   ,
              ELLIMINATION_PERIOD               ,
              LOSS_DATE                         ,
              OCCUPATION_CODE                   ,
              OCCUPATION_DECRIPTION             ,
              PLAN_DURATION_DATE                ,
              MODIFIED_RTW_DATE                 ,
              RETURN_TO_WORK_DATE               ,
              COVERAGE_TYPE                     ,
              CLAIM_CLASS_ID                    ,
              DISABILITY_START_DATE             ,
              PRIVACY_INDICATOR
			  ,CURRENT_RESERVE --16-Oct-2023 changes
			  ,Policy_effective_date --26-Mar-2024 changes
			  )SELECT
			  /*+PARALLEL(4)*/ --13-mAY-2024 CHANGES
            d_grp_policy_dir_r_policy.n_policy_sk_r                  AS policy_skey,
            d_grp_claim_dir_r_claim.n_claim_sk_r                     AS claim_skey,
                  --CAST(TRUNC(d_grp_policy_dir_r_policy.t_event_timestamp_r) AS DATE)
                  f_grp_policy_r_policy.V_ADMINISTERED_BY_R as administered_by  ,


            (
                SELECT
                    MAX(fic_mis_date_r)
                FROM
                    dim_grp_policy_dir_r
                WHERE
                    v_source_system_name_r = 'PACS'
            )                                                        AS as_of_date,
                  /* 10 March-2023 As per Suhasini's request commeting the CLAIM_IDENTIFIER old logic and adding an new one*/
                 -- NVL(d_grp_claim_coverage_group_r_claims.V_CLAIM_IDENTIFIER_R,d_grp_claim_dir_r_claim.v_claim_number_r ) CLAIM_IDENTIFIER,
           d_grp_claim_coverage_group_r_claims.v_claim_identifier_r  AS claim_identifier,
            d_grp_policy_dir_r_policy.v_policy_prefix_r              AS policy_prefix,
            d_grp_policy_dir_r_policy.v_policy_suffix_r              AS policy_suffix,
                  /*  CASE
                  WHEN f_grp_transactions_r_claims.v_business_object_id_r IN ( 'LIFECLAIM', 'NONSTDCLAIM', 'WOPCLAIM' ) THEN
                  NULL--F_GRP_WORKSHEET_Claims_CoverageGroup.D_WORKSHEET_END_DATE_R
                  ELSE
                  f_grp_worksheet_claims_coverage.d_worksheet_end_date_r
                  END                                                                                         */
            MAX(
                CASE
                    WHEN nvl(f_grp_worksheet_claims_coveragegroup.v_rpt_worksheet_indicator_r, 'Y') = 'Y'
                         AND d_grp_claim_dir_r_claim.v_lob_type_r IN('LIFE', 'NONS', 'WOP') THEN
                        f_grp_worksheet_claims_coveragegroup.d_worksheet_end_date_r
                END
            )                                                        AS worksheet_end_date,
                  /*  CASE
                  WHEN f_grp_transactions_r_claims.v_business_object_id_r IN ( 'LIFECLAIM', 'NONSTDCLAIM', 'WOPCLAIM' ) THEN
                  NULL--F_GRP_WORKSHEET_Claims_CoverageGroup.D_WORKSHEET_START_DATE_R
                  ELSE
                  f_grp_worksheet_claims_coverage.d_worksheet_start_date_r
                  END                                                                                           AS worksheet_start_date,*/
            MAX(
                CASE
                    WHEN nvl(f_grp_worksheet_claims_coveragegroup.v_rpt_worksheet_indicator_r, 'Y') = 'Y'
                         AND d_grp_claim_dir_r_claim.v_lob_type_r IN('LIFE', 'NONS', 'WOP') THEN
                        f_grp_worksheet_claims_coveragegroup.d_worksheet_start_date_r
                END
            )                                                        AS worksheet_start_date,
            CASE
                WHEN d_grp_claim_dir_r_claim.v_lob_type_r IN ( 'LIFE', 'NONS', 'WOP' ) THEN
                    d_grp_claim_coverage_group_r_claims.d_date_closed_r
            END                                                      AS claim_closed_date,
            SUM(
                CASE
                    WHEN f_grp_worksheet_claims_coveragegroup.v_rpt_worksheet_indicator_r = 'Y' THEN
                        f_grp_worksheet_claims_coveragegroup.n_gross_benefit_r
                    ELSE
                        0
                END
            )                                                        AS claim_gross_benefit_amount,
            CAST(TO_DATE(substr(f_grp_transactions_r_claims.v_dc_timestamp_r, 1, 8),
                'YYYYMMDD') AS DATE)                                 AS claim_most_recent_activity_date,
            SUM(
                CASE
                    WHEN f_grp_worksheet_claims_coveragegroup.v_rpt_worksheet_indicator_r = 'Y' THEN
                        f_grp_worksheet_claims_coveragegroup.n_rpt_net_benefit_r
                    ELSE
                        0
                END
            )                                                        AS claim_net_benefit_amount,
            d_grp_claim_dir_r_claim.v_claim_number_r                 AS claim_number,
            d_grp_busobj_audit_r.received_date                       AS claim_received_date,
            MAX(
                CASE
                    WHEN f_grp_worksheet_claims_coveragegroup.v_rpt_worksheet_indicator_r = 'Y' THEN
                        f_grp_worksheet_claims_coveragegroup.n_taxable_override_pct_r
                    ELSE
                        NULL
                END
            )                                                        AS claim_taxable_benefit_percentage,
            CASE
                WHEN d_grp_claim_dir_r_claim.v_lob_type_r IN ( 'LTD', 'LTD-Small', 'VLT', 'VPL' ) THEN
                    'M'
                WHEN d_grp_claim_dir_r_claim.v_lob_type_r IN ( 'DBL', 'STD', 'STD-Small', 'VPS' ) THEN
                    'W'
                WHEN NOT d_grp_claim_eligibility_r_claims.n_waiver_termination_age_r IS NULL THEN
                    'A'
                ELSE
                    NULL
            END                                                      AS duration_indicator,

                  /*CASE
                    WHEN d_grp_claim_dir_r_claim.v_lob_type_r                     IN ( 'LTD', 'STD', 'VPL', 'VPS' )
                    THEN ROUND((d_grp_claim_eligibility_r_claims.d_plan_dur_date_r - f_grp_worksheet_claims_coverage.d_benefit_start_r + 1) / 30.45, 0)
                    WHEN f_grp_worksheet_claims_coverage.d_benefit_start_r IS NULL
                    THEN ROUND((d_grp_claim_eligibility_r_claims.d_plan_dur_date_r - d_grp_party_r_claims.d_birth_date_r) / 365.25 * 12, 0)
                    WHEN d_grp_claim_dir_r_claim.v_lob_type_r                     IN ( 'WOP' )
                    THEN d_grp_claim_eligibility_r_claims.n_waiver_termination_age_r
                    ELSE NULL
                  END AS duration_period,*/-- 13 March,2023, Commented the existing logic and added new logic as requested by Suhasini
            max(CASE
                    WHEN d_grp_claim_dir_r_claim.v_lob_type_r                     IN ('STD','VPS' )
                    THEN case when d_grp_claim_eligibility_r_claims.v_benefit_duration_r is not null
                    then d_grp_claim_eligibility_r_claims.v_benefit_duration_r
                    ELSE To_Char(ROUND(((d_grp_claim_eligibility_r_claims.d_plan_dur_date_r - d_grp_party_r_claims.D_BIRTH_DATE_R + 1) /365.25)*12,0 ))
                    END
                    WHEN d_grp_claim_dir_r_claim.v_lob_type_r                     IN ('LTD','VPL' )
                    THEN CASE when  f_grp_worksheet_claims_coveragegroup.D_BENEFIT_START_R is not null
                    THEN to_char(ROUND((d_grp_claim_eligibility_r_claims.d_plan_dur_date_r - f_grp_worksheet_claims_coveragegroup.d_benefit_start_r + 1) / 30.45, 0))
                    ELSE to_char(ROUND(((d_grp_claim_eligibility_r_claims.d_plan_dur_date_r - d_grp_party_r_claims.D_BIRTH_DATE_R ) /365.25)*12,0 ))
                    END
                    WHEN d_grp_claim_dir_r_claim.v_lob_type_r                     IN ( 'WOP' )
                                THEN to_char(d_grp_claim_eligibility_r_claims.n_waiver_termination_age_r)
                    WHEN d_grp_claim_dir_r_claim.v_lob_type_r                     IN ( 'NONS' )
                    THEN case when d_grp_claim_eligibility_r_claims.n_elim_period_r is null then
                    To_char(lpad(ROUND(((d_grp_claim_eligibility_r_claims.d_plan_dur_date_r - d_grp_claim_detail_r_claim.d_date_of_loss_r) / 365.25) * 12), 3, '0'))
                    else To_char(lpad(ROUND(((d_grp_claim_eligibility_r_claims.d_plan_dur_date_r- (d_grp_claim_detail_r_claim.d_date_of_loss_r+d_grp_claim_eligibility_r_claims.n_elim_period_r))         / 365.25) * 12), 3, '0'))
                    end
              --ELSE  lpad(ROUND(((d_grp_claim_eligibility_r_claims.d_plan_dur_date_r - d_grp_party_r_claims.d_birth_date_r)         / 365.25) * 12), 3, '0')
              --END
              ELSE NULL END        )                            AS duration_period,
            CASE
                WHEN d_grp_claim_eligibility_r_claims.n_elim_period_r <> ''
                     OR d_grp_claim_eligibility_r_claims.n_elim_period_r <> 0 THEN
                    d_grp_claim_eligibility_r_claims.n_elim_period_r
                WHEN
                    CASE d_grp_claim_event_dir_r_claim.v_event_cause_r
                        WHEN 'ACCIDENT'                        THEN
                            'A6'
                        WHEN 'ACCIDENT - AVIATION'             THEN
                            'A3'
                        WHEN 'ACCIDENT- AVIATION'              THEN
                            'A3'
                        WHEN 'ACCIDENT - OCCUPATIONAL'         THEN
                            'A1'
                        WHEN 'ACCIDENT- OCCUPATIONAL'          THEN
                            'A1'
                        WHEN 'ACCIDENT- OTHER'                 THEN
                            'A6'
                        WHEN 'ACCIDENT - OTHER'                THEN
                            'A6'
                        WHEN 'ACCIDENT - SPORTS'               THEN
                            'A4'
                        WHEN 'ACCIDENT- SPORTS'                THEN
                            'A4'
                        WHEN 'ADOPTION'                        THEN
                            'AE'
                        WHEN 'ALCOHOL'                         THEN
                            'AC'
                        WHEN 'ASSAULT'                         THEN
                            'A5'
                        WHEN 'BONDING'                         THEN
                            'AE'
                        WHEN 'COMMONDISASTER'                  THEN
                            '31'
                        WHEN 'COMMON DISASTER'                 THEN
                            '31'
                        WHEN 'DRUGS'                           THEN
                            'AD'
                        WHEN 'FOSTER'                          THEN
                            'AE'
                        WHEN 'MATERNITY'                       THEN
                            'AE'
                        WHEN 'MENTAL'                          THEN
                            'AA'
                        WHEN 'MISSING INSURED / DISAPPEARANCE' THEN
                            '33'
                        WHEN 'MOTOR VEHICLE'                   THEN
                            'A2'
                        WHEN 'MOTORCYCLE'                      THEN
                            'A2'
                        WHEN 'NERVOUS'                         THEN
                            'AB'
                        WHEN 'SICKNESS'                        THEN
                            'AE'
                        WHEN 'SUICIDE'                         THEN
                            'SU'
                        WHEN 'UNKNOWN / UNDETERMINED'          THEN
                            'UN'
                        WHEN 'UNKNOWN / UNDETER '              THEN
                            'UN'
                        WHEN 'WAR / TERRORISM'                 THEN
                            '40'
                        WHEN 'WELLNESS'                        THEN
                            'WL'
                        ELSE
                            'UN'
                    END
                IN ( 'A1', 'A2', 'A3', 'A4', 'A5',
                     'A6' ) THEN
                    d_grp_claim_eligibility_r_claims.n_elim_period_acc_r
                ELSE
                    d_grp_claim_eligibility_r_claims.n_elim_period_sick_r
            END                                                      AS ellimination_period,
            CASE
                WHEN d_grp_policy_dir_r_policy.v_policy_prefix_r = 'VAI' THEN
                    d_grp_claim_detail_r_claim.d_date_of_event_r
                ELSE
                    d_grp_claim_detail_r_claim.d_date_of_loss_r
            END                                                      AS loss_date,
            d_grp_eeoc_r.v_code_r                                    AS occupation_code,
            d_grp_eeoc_r.v_description_r                             AS occupation_decription,
            d_grp_claim_eligibility_r_claims.d_plan_dur_date_r       AS plan_duration_date,
            d_grp_claim_detail_r_claim.d_return_to_mod_wkdt_r        AS modified_rtw_date,
            d_grp_claim_detail_r_claim.d_return_to_work_date_r       AS return_to_work_date,
            CASE
                WHEN d_grp_product_r_claims_disability.v_coverage_type_code_r = '1' THEN
                    'LTD'
                WHEN d_grp_product_r_claims_disability.v_coverage_type_code_r = '2' THEN
                    'STD'
                WHEN d_grp_product_r_claims_disability.v_coverage_type_code_r IN ( '1', '2' ) THEN
                    'Disability (LTD )'
                WHEN d_grp_product_r_claims_life.v_coverage_type_code_r = '3'       THEN
                    'Life'
                WHEN d_grp_product_r_claims_life.v_coverage_category_r = 'Life - Annuity'
                     AND d_grp_product_r_claims_life.v_coverage_type_code_r = '3' THEN
                    'Life - Annuity'
                WHEN d_grp_product_r_claims_life.v_coverage_category_r = 'Life - Non-Annuity'
                     AND d_grp_product_r_claims_life.v_coverage_type_code_r = '3' THEN
                    'Life - Non-Annuity'
                WHEN d_grp_product_r_claims_life.v_coverage_type_code_r = '3'
                     AND NOT ( d_grp_product_r_claims_life.v_coverage_code_r LIKE '%WP%'
                               OR d_grp_product_r_claims_life.v_coverage_code_r LIKE 'GAN%'
                               OR d_grp_product_r_claims_life.v_coverage_code_r LIKE 'CD%' ) THEN
                    'Group Life'
            END                                                      AS coverage_type,
            Max(CASE
                WHEN d_grp_claim_dir_r_claim.v_lob_type_r IN ( 'LIFE', 'NONS', 'WOP' ) THEN
                    d_grp_claim_coverage_group_r_claims.v_class_id_r
                ELSE
                    d_grp_claim_coverage_r_claims.v_class_id_r
            END    )                                                  AS claim_class_id,
            CASE
                WHEN d_grp_policy_dir_r_policy.v_orig_lob_r = 'VAI' THEN
                    d_grp_claim_event_dir_r_claim.d_date_of_event_r +
                    CASE
                        WHEN d_grp_claim_eligibility_r_claims.n_elim_period_r <> ''
                             OR d_grp_claim_eligibility_r_claims.n_elim_period_r <> 0 THEN
                                d_grp_claim_eligibility_r_claims.n_elim_period_r
                        ELSE
                            0
                    END
                ELSE
                    d_grp_claim_event_dir_r_claim.d_date_of_event_r
            END                                                      AS disability_start_date,
            d_grp_claim_dir_r_claim.V_PRIVACY_INDICATOR_R as PRIVACY_INDICATOR
			,(d_grp_claim_coverage_group_r_claims.N_RESERVE_AMOUNT_R - d_grp_claim_coverage_group_r_claims.N_WS_RELEASED_AMOUNT_R) CURRENT_RESERVE--26-Oct-2023 changes
			,d_grp_policy_dir_r_policy.T_POLICY_EFFECTIVE_DATE_R --26-Mar-2024 changes
        FROM
            (
                (
                    (
                             dim_grp_policy_dir_r d_grp_policy_dir_r_policy

                        INNER JOIN dim_grp_claim_dir_r            d_grp_claim_dir_r_claim ON d_grp_policy_dir_r_policy.n_policy_sk_r = d_grp_claim_dir_r_claim.n_policy_sk_r
                                 left outer join     (
                SELECT
                    *
                FROM
                    fct_grp_transactions_r
                WHERE
                    n_claim_sk_r <> - 1
            )                              f_grp_transactions_r_claims
                  /* F_GRP_TRANSACTIONS_R_Claims */
                  on f_grp_transactions_r_claims.n_claim_sk_r = d_grp_claim_dir_r_claim.n_claim_sk_r
                        LEFT OUTER JOIN (
                            SELECT
                                v_claim_number_r,
                                MAX(nvl(t374156.d_received_date_r,
                                        TO_DATE(substr(t374156.v_claim_number_r, 1, 10),
                                                'YYYY-MM-DD'))) AS received_date
                            FROM
                                dim_grp_busobj_audit_r t374156
                            WHERE
                                    v_active_status_r = 'Y'
                                AND v_claim_number_r NOT IN ( '-LIFE-01', '-LTD-01', '-STD-01', '-VPS-01', '-WOP-01' )
                            GROUP BY
                                v_claim_number_r
                        )                              d_grp_busobj_audit_r ON d_grp_claim_dir_r_claim.v_claim_number_r = d_grp_busobj_audit_r.v_claim_number_r
                        LEFT OUTER JOIN (
                            SELECT
                                *
                            FROM
                                fct_grp_worksheet
                            WHERE
                                v_rpt_worksheet_indicator_r = 'Y'
                        )                              f_grp_worksheet_claims_coveragegroup


                  /* F_GRP_WORKSHEET_Claims_CoverageGroup */ ON d_grp_claim_dir_r_claim.n_claim_sk_r = f_grp_worksheet_claims_coveragegroup.n_claim_sk_r
                    )
                    INNER JOIN dim_grp_claim_detail_r         d_grp_claim_detail_r_claim
                  /* D_GRP_CLAIM_DETAIL_R_Claim */ ON d_grp_claim_detail_r_claim.n_claim_sk_r = d_grp_claim_dir_r_claim.n_claim_sk_r


                )
                LEFT OUTER JOIN dim_grp_party_r                d_grp_party_r_claims
                  /* D_GRP_PARTY_R_Claims */ ON d_grp_claim_detail_r_claim.n_insrd_party_sk_r = d_grp_party_r_claims.n_party_sk_r
            ),
               -- LEFT OUTER JOIN dim_grp_busobj_audit_r d_grp_busobj_audit_r
                  /* D_GRP_BUSOBJ_AUDIT_R */
              --  ON d_grp_claim_dir_r_claim.v_claim_number_r = d_grp_busobj_audit_r.v_claim_number_r,
            fct_grp_policy_r               f_grp_policy_r_policy


                  /* F_GRP_POLICY_R_Policy */,
        ( (
                (
                    (
                        (
                            (
                                dim_grp_claim_coverage_r       d_grp_claim_coverage_r_claims



                  /* D_GRP_CLAIM_COVERAGE_R_Claims */
                                LEFT OUTER JOIN (
                                    dim_grp_claim_coverage_group_r d_grp_claim_coverage_group_r_claims
                  /* D_GRP_CLAIM_COVERAGE_GROUP_R_Claims */
                                    LEFT OUTER JOIN mvw_product_sk_lookup_tbl      vw_product_sk_lookup_for_life
                  /* VW_PRODUCT_SK_LOOKUP_For_Life */ ON d_grp_claim_coverage_group_r_claims.n_claim_sk_r = vw_product_sk_lookup_for_life.n_claim_sk_r
                                                                                                               AND d_grp_claim_coverage_group_r_claims.v_claim_coverage_code_r = vw_product_sk_lookup_for_life.v_claim_coverage_code_r
                                ) ON d_grp_claim_coverage_group_r_claims.n_claim_coverage_sk_r = d_grp_claim_coverage_r_claims.n_claim_coverage_sk_r
                            )
                            LEFT OUTER JOIN dim_grp_product_r              d_grp_product_r_claims_life
                  /* D_GRP_PRODUCT_R_Claims_Life */ ON d_grp_product_r_claims_life.n_product_sk_r = vw_product_sk_lookup_for_life.n_product_sk_r
                        )
                        LEFT OUTER JOIN mvw_product_sk_lookup_tbl      vw_product_sk_lookup_for_disablity
                  /* VW_PRODUCT_SK_LOOKUP_For_Disablity */ ON d_grp_claim_coverage_r_claims.n_claim_sk_r = vw_product_sk_lookup_for_disablity.n_claim_sk_r
                                                                                                        AND d_grp_claim_coverage_r_claims.v_claim_coverage_code_r = vw_product_sk_lookup_for_disablity.v_claim_coverage_code_r
                    )
                    LEFT OUTER JOIN dim_grp_product_r              d_grp_product_r_claims_disability
                  /* D_GRP_PRODUCT_R_Claims_Disability */ ON vw_product_sk_lookup_for_disablity.n_product_sk_r = d_grp_product_r_claims_disability.n_product_sk_r
                )
                LEFT OUTER JOIN dim_grp_claim_eligibility_r    d_grp_claim_eligibility_r_claims
                  /* D_GRP_CLAIM_ELIGIBILITY_R_Claims */ ON d_grp_claim_eligibility_r_claims.n_claim_coverage_sk_r = CASE
                                                                                                                      WHEN
                                                                                                                      d_grp_claim_eligibility_r_claims.n_claim_coverage_sk_r <> - 1
                                                                                                                      THEN
                                                                                                                         d_grp_claim_coverage_r_claims.n_claim_coverage_sk_r
                                                                                                                            ELSE
                                                                                                                            - 1
                                                                                                                          END
                                                                                                AND d_grp_claim_eligibility_r_claims.n_claim_sk_r = d_grp_claim_coverage_r_claims.n_claim_sk_r
            ) )
               -- LEFT OUTER JOIN fct_grp_worksheet f_grp_worksheet_claims_coverage
                  /* F_GRP_WORKSHEET_Claims_Coverage */
              --  ON d_grp_claim_coverage_r_claims. n_claim_coverage_sk_r = f_grp_worksheet_claims_coverage.n_claim_coverage_sk_r
          --      AND d_grp_claim_coverage_r_claims.n_claim_sk_r          = f_grp_worksheet_claims_coverage. n_claim_sk_r
            , dim_grp_claim_event_r          d_grp_claim_event_r_claim


                  /* D_GRP_CLAIM_EVENT_R_Claim */
            LEFT OUTER JOIN dim_grp_eeoc_r                 d_grp_eeoc_r ON d_grp_claim_event_r_claim.v_eeoc_code_r = d_grp_eeoc_r.v_code_r,
            dim_grp_claim_event_dir_r      d_grp_claim_event_dir_r_claim
                  /* D_GRP_CLAIM_EVENT_DIR_R_Claim */
        WHERE
            ( d_grp_claim_coverage_r_claims.n_claim_sk_r = d_grp_claim_detail_r_claim.n_claim_sk_r )
            AND ( d_grp_policy_dir_r_policy.n_policy_sk_r = f_grp_policy_r_policy.n_policy_sk_r
                  AND d_grp_policy_dir_r_policy.n_policy_version_number_r = f_grp_policy_r_policy.n_version_number_r
                  AND d_grp_claim_detail_r_claim.n_claim_event_sk_r = d_grp_claim_event_r_claim.n_claim_event_sk_r
              --   AND d_grp_claim_dir_r_claim.n_claim_sk_r = f_grp_transactions_r_claims.n_claim_sk_r
                  AND d_grp_claim_detail_r_claim.n_claim_event_sk_r = d_grp_claim_event_r_claim.n_claim_event_sk_r
                  AND d_grp_claim_event_r_claim.n_claim_event_sk_r = d_grp_claim_event_dir_r_claim.n_claim_event_sk_r
                  AND d_grp_policy_dir_r_policy.v_active_status_r = 'Y'
                  AND nvl(d_grp_claim_eligibility_r_claims.v_active_status_r, 'Y') = 'Y'
                  AND nvl(d_grp_claim_coverage_group_r_claims.v_active_status_r, 'Y') = 'Y'
                  AND d_grp_claim_coverage_r_claims.v_active_status_r = 'Y'
                  AND d_grp_claim_detail_r_claim.v_active_status_r = 'Y'
                  AND d_grp_claim_dir_r_claim.v_active_status_r = 'Y'
                  AND d_grp_claim_event_r_claim.v_active_status_r = 'Y'
                  AND d_grp_claim_event_dir_r_claim.v_active_status_r = 'Y'
                  AND nvl(d_grp_eeoc_r.v_active_status_r, 'Y') = 'Y'
                  AND d_grp_claim_dir_r_claim.v_lob_type_r IN ( 'LIFE', 'NONS', 'WOP' )
				  --18-Oct-2023 changes starts
                  --and  d_grp_claim_coverage_group_r_claims.n_cov_grp_id_r is not null
				  and  case when d_grp_claim_dir_r_claim.v_source_system_name_r = 'PACS'
                  then d_grp_claim_coverage_group_r_claims.n_cov_grp_id_r else 1 end is not null
                  --18-Oct-2023 changes ends

                --  and d_grp_policy_dir_r_policy.v_policy_number_r = 'VHI851254'
                  --  AND ( d_grp_claim_dir_r_claim.v_claim_number_r IN ( '2021-10-08-0164-GL-01') )
                  -- and d_grp_claim_coverage_group_r_claims.v_claim_identifier_r ='2021-10-08-0164-GL-01-02'
                   )
        GROUP BY
            d_grp_policy_dir_r_policy.n_policy_sk_r,
            d_grp_claim_dir_r_claim.n_claim_sk_r,
            f_grp_policy_r_policy.V_ADMINISTERED_BY_R ,
                  --CAST(TRUNC(d_grp_policy_dir_r_policy.t_event_timestamp_r) AS DATE)



                  /* 10 March-2023 As per Suhasini's request commeting the CLAIM_IDENTIFIER old logic and adding an new one*/
                 -- NVL(d_grp_claim_coverage_group_r_claims.V_CLAIM_IDENTIFIER_R,d_grp_claim_dir_r_claim.v_claim_number_r ) CLAIM_IDENTIFIER,
            d_grp_claim_coverage_group_r_claims.v_claim_identifier_r,
            d_grp_policy_dir_r_policy.v_policy_prefix_r,
            d_grp_policy_dir_r_policy.v_policy_suffix_r,
                  /*  CASE
                  WHEN f_grp_transactions_r_claims.v_business_object_id_r IN ( 'LIFECLAIM', 'NONSTDCLAIM', 'WOPCLAIM' ) THEN
                  NULL--F_GRP_WORKSHEET_Claims_CoverageGroup.D_WORKSHEET_END_DATE_R
                  ELSE
                  f_grp_worksheet_claims_coverage.d_worksheet_end_date_r
                  END                                                                                         */

                  /*  CASE
                  WHEN f_grp_transactions_r_claims.v_business_object_id_r IN ( 'LIFECLAIM', 'NONSTDCLAIM', 'WOPCLAIM' ) THEN
                  NULL--F_GRP_WORKSHEET_Claims_CoverageGroup.D_WORKSHEET_START_DATE_R
                  ELSE
                  f_grp_worksheet_claims_coverage.d_worksheet_start_date_r
                  END                                                                                           AS worksheet_start_date,*/

            CASE
                WHEN d_grp_claim_dir_r_claim.v_lob_type_r IN ( 'LIFE', 'NONS', 'WOP' ) THEN
                        d_grp_claim_coverage_group_r_claims.d_date_closed_r
            END,
            CAST(TO_DATE(substr(f_grp_transactions_r_claims.v_dc_timestamp_r, 1, 8),
                'YYYYMMDD') AS DATE),
            d_grp_claim_dir_r_claim.v_claim_number_r,
            d_grp_busobj_audit_r.received_date,
            CASE
                    WHEN d_grp_claim_dir_r_claim.v_lob_type_r IN ( 'LTD', 'LTD-Small', 'VLT', 'VPL' ) THEN
                        'M'
                    WHEN d_grp_claim_dir_r_claim.v_lob_type_r IN ( 'DBL', 'STD', 'STD-Small', 'VPS' ) THEN
                        'W'
                    WHEN NOT d_grp_claim_eligibility_r_claims.n_waiver_termination_age_r IS NULL THEN
                        'A'
                    ELSE
                        NULL
            END,

                  /*CASE
                    WHEN d_grp_claim_dir_r_claim.v_lob_type_r                     IN ( 'LTD', 'STD', 'VPL', 'VPS' )
                    THEN ROUND((d_grp_claim_eligibility_r_claims.d_plan_dur_date_r - f_grp_worksheet_claims_coverage.d_benefit_start_r + 1) / 30.45, 0)
                    WHEN f_grp_worksheet_claims_coverage.d_benefit_start_r IS NULL
                    THEN ROUND((d_grp_claim_eligibility_r_claims.d_plan_dur_date_r - d_grp_party_r_claims.d_birth_date_r) / 365.25 * 12, 0)
                    WHEN d_grp_claim_dir_r_claim.v_lob_type_r                     IN ( 'WOP' )
                    THEN d_grp_claim_eligibility_r_claims.n_waiver_termination_age_r
                    ELSE NULL
                  END AS duration_period,*/-- 13 March,2023, Commented the existing logic and added new logic as requested by Suhasini
                   /* CASE
                              WHEN d_grp_claim_dir_r_claim.v_lob_type_r                     IN ('STD','VPS' )
                              THEN case when d_grp_claim_eligibility_r_claims.v_benefit_duration_r is not null
                  then d_grp_claim_eligibility_r_claims.v_benefit_duration_r
                  ELSE To_Char(ROUND(((d_grp_claim_eligibility_r_claims.d_plan_dur_date_r - d_grp_party_r_claims.D_BIRTH_DATE_R + 1) /365.25)*12,0 ))
                  END
                  WHEN d_grp_claim_dir_r_claim.v_lob_type_r                     IN ('LTD','VPL' )
                  THEN CASE when  f_grp_worksheet_claims_coveragegroup.D_BENEFIT_START_R is not null
                  THEN to_char(ROUND((d_grp_claim_eligibility_r_claims.d_plan_dur_date_r - f_grp_worksheet_claims_coveragegroup.d_benefit_start_r + 1) / 30.45, 0))
                  ELSE to_char(ROUND(((d_grp_claim_eligibility_r_claims.d_plan_dur_date_r - d_grp_party_r_claims.D_BIRTH_DATE_R ) /365.25)*12,0 ))
                  END
                  WHEN d_grp_claim_dir_r_claim.v_lob_type_r                     IN ( 'WOP' )
                              THEN to_char(d_grp_claim_eligibility_r_claims.n_waiver_termination_age_r)
                  WHEN d_grp_claim_dir_r_claim.v_lob_type_r                     IN ( 'NONS' )
                  THEN case when d_grp_claim_eligibility_r_claims.n_elim_period_r is null then
                  To_char(lpad(ROUND(((d_grp_claim_eligibility_r_claims.d_plan_dur_date_r - d_grp_claim_detail_r_claim.d_date_of_loss_r) / 365.25) * 12), 3, '0'))
                  else To_char(lpad(ROUND(((d_grp_claim_eligibility_r_claims.d_plan_dur_date_r- (d_grp_claim_detail_r_claim.d_date_of_loss_r+d_grp_claim_eligibility_r_claims.n_elim_period_r))         / 365.25) * 12), 3, '0'))
                  end
              --ELSE  lpad(ROUND(((d_grp_claim_eligibility_r_claims.d_plan_dur_date_r - d_grp_party_r_claims.d_birth_date_r)         / 365.25) * 12), 3, '0')
              --END
              ELSE NULL END,*/
            CASE
                    WHEN d_grp_claim_eligibility_r_claims.n_elim_period_r <> ''
                         OR d_grp_claim_eligibility_r_claims.n_elim_period_r <> 0 THEN
                        d_grp_claim_eligibility_r_claims.n_elim_period_r
                    WHEN
                        CASE d_grp_claim_event_dir_r_claim.v_event_cause_r
                            WHEN 'ACCIDENT'                        THEN
                                'A6'
                            WHEN 'ACCIDENT - AVIATION'             THEN
                                'A3'
                            WHEN 'ACCIDENT- AVIATION'              THEN
                                'A3'
                            WHEN 'ACCIDENT - OCCUPATIONAL'         THEN
                                'A1'
                            WHEN 'ACCIDENT- OCCUPATIONAL'          THEN
                                'A1'
                            WHEN 'ACCIDENT- OTHER'                 THEN
                                'A6'
                            WHEN 'ACCIDENT - OTHER'                THEN
                                'A6'
                            WHEN 'ACCIDENT - SPORTS'               THEN
                                'A4'
                            WHEN 'ACCIDENT- SPORTS'                THEN
                                'A4'
                            WHEN 'ADOPTION'                        THEN
                                'AE'
                            WHEN 'ALCOHOL'                         THEN
                                'AC'
                            WHEN 'ASSAULT'                         THEN
                                'A5'
                            WHEN 'BONDING'                         THEN
                                'AE'
                            WHEN 'COMMONDISASTER'                  THEN
                                '31'
                            WHEN 'COMMON DISASTER'                 THEN
                                '31'
                            WHEN 'DRUGS'                           THEN
                                'AD'
                            WHEN 'FOSTER'                          THEN
                                'AE'
                            WHEN 'MATERNITY'                       THEN
                                'AE'
                            WHEN 'MENTAL'                          THEN
                                'AA'
                            WHEN 'MISSING INSURED / DISAPPEARANCE' THEN
                                '33'
                            WHEN 'MOTOR VEHICLE'                   THEN
                                'A2'
                            WHEN 'MOTORCYCLE'                      THEN
                                'A2'
                            WHEN 'NERVOUS'                         THEN
                                'AB'
                            WHEN 'SICKNESS'                        THEN
                                'AE'
                            WHEN 'SUICIDE'                         THEN
                                'SU'
                            WHEN 'UNKNOWN / UNDETERMINED'          THEN
                                'UN'
                            WHEN 'UNKNOWN / UNDETER '              THEN
                                'UN'
                            WHEN 'WAR / TERRORISM'                 THEN
                                '40'
                            WHEN 'WELLNESS'                        THEN
                                'WL'
                            ELSE
                                'UN'
                        END
                    IN ( 'A1', 'A2', 'A3', 'A4', 'A5',
                         'A6' ) THEN
                        d_grp_claim_eligibility_r_claims.n_elim_period_acc_r
                    ELSE
                        d_grp_claim_eligibility_r_claims.n_elim_period_sick_r
            END,
            CASE
                WHEN d_grp_policy_dir_r_policy.v_policy_prefix_r = 'VAI' THEN
                        d_grp_claim_detail_r_claim.d_date_of_event_r
                ELSE
                    d_grp_claim_detail_r_claim.d_date_of_loss_r
            END,
            d_grp_eeoc_r.v_code_r,
            d_grp_eeoc_r.v_description_r,
            d_grp_claim_eligibility_r_claims.d_plan_dur_date_r,
            d_grp_claim_detail_r_claim.d_return_to_mod_wkdt_r,
            d_grp_claim_detail_r_claim.d_return_to_work_date_r,
            d_grp_claim_dir_r_claim.V_PRIVACY_INDICATOR_R,
            CASE
                    WHEN d_grp_product_r_claims_disability.v_coverage_type_code_r = '1' THEN
                        'LTD'
                    WHEN d_grp_product_r_claims_disability.v_coverage_type_code_r = '2' THEN
                        'STD'
                    WHEN d_grp_product_r_claims_disability.v_coverage_type_code_r IN ( '1', '2' ) THEN
                        'Disability (LTD )'
                    WHEN d_grp_product_r_claims_life.v_coverage_type_code_r = '3'       THEN
                        'Life'
                    WHEN d_grp_product_r_claims_life.v_coverage_category_r = 'Life - Annuity'
                         AND d_grp_product_r_claims_life.v_coverage_type_code_r = '3' THEN
                        'Life - Annuity'
                    WHEN d_grp_product_r_claims_life.v_coverage_category_r = 'Life - Non-Annuity'
                         AND d_grp_product_r_claims_life.v_coverage_type_code_r = '3' THEN
                        'Life - Non-Annuity'
                    WHEN d_grp_product_r_claims_life.v_coverage_type_code_r = '3'
                         AND NOT ( d_grp_product_r_claims_life.v_coverage_code_r LIKE '%WP%'
                                   OR d_grp_product_r_claims_life.v_coverage_code_r LIKE 'GAN%'
                                   OR d_grp_product_r_claims_life.v_coverage_code_r LIKE 'CD%' ) THEN
                        'Group Life'
            END,
          --  CASE
             --   WHEN d_grp_claim_dir_r_claim.v_lob_type_r IN ( 'LIFE', 'NONS', 'WOP' ) THEN
                --        d_grp_claim_coverage_group_r_claims.v_class_id_r
              --  ELSE
                --    d_grp_claim_coverage_r_claims.v_class_id_r
           -- END,
            CASE
                WHEN d_grp_policy_dir_r_policy.v_orig_lob_r = 'VAI' THEN
                        d_grp_claim_event_dir_r_claim.d_date_of_event_r +
                        CASE
                            WHEN d_grp_claim_eligibility_r_claims.n_elim_period_r <> ''
                                 OR d_grp_claim_eligibility_r_claims.n_elim_period_r <> 0 THEN
                                    d_grp_claim_eligibility_r_claims.n_elim_period_r
                            ELSE
                                0
                        END
                ELSE
                    d_grp_claim_event_dir_r_claim.d_date_of_event_r
            END
            ,(d_grp_claim_coverage_group_r_claims.N_RESERVE_AMOUNT_R - d_grp_claim_coverage_group_r_claims.N_WS_RELEASED_AMOUNT_R)--26-Oct-2023 changes
			,d_grp_policy_dir_r_policy.T_POLICY_EFFECTIVE_DATE_R --26-Mar-2024 changes
        union

        SELECT

            d_grp_policy_dir_r_policy.n_policy_sk_r                  AS policy_skey,
            d_grp_claim_dir_r_claim.n_claim_sk_r                     AS claim_skey,
                  --CAST(TRUNC(d_grp_policy_dir_r_policy.t_event_timestamp_r) AS DATE)
                  f_grp_policy_r_policy.V_ADMINISTERED_BY_R as administered_by ,


            (
                SELECT
                    MAX(fic_mis_date_r)
                FROM
                    dim_grp_policy_dir_r
                WHERE
                    v_source_system_name_r = 'PACS'
            )                                                        AS as_of_date,
                  /* 10 March-2023 As per Suhasini's request commeting the CLAIM_IDENTIFIER old logic and adding an new one*/
                 -- NVL(d_grp_claim_coverage_group_r_claims.V_CLAIM_IDENTIFIER_R,d_grp_claim_dir_r_claim.v_claim_number_r ) CLAIM_IDENTIFIER,
            d_grp_claim_dir_r_claim.v_claim_number_r AS claim_identifier,
            d_grp_policy_dir_r_policy.v_policy_prefix_r              AS policy_prefix,
            d_grp_policy_dir_r_policy.v_policy_suffix_r              AS policy_suffix,
                  /*  CASE
                  WHEN f_grp_transactions_r_claims.v_business_object_id_r IN ( 'LIFECLAIM', 'NONSTDCLAIM', 'WOPCLAIM' ) THEN
                  NULL--F_GRP_WORKSHEET_Claims_CoverageGroup.D_WORKSHEET_END_DATE_R
                  ELSE
                  f_grp_worksheet_claims_coverage.d_worksheet_end_date_r
                  END                                                                                         */
            MAX(
                CASE
                    WHEN nvl(f_grp_worksheet_claims_coveragegroup.v_rpt_worksheet_indicator_r, 'Y') = 'Y'
                         AND d_grp_claim_dir_r_claim.v_lob_type_r IN('LTD', 'STD', 'VPL', 'VPS') THEN
                        f_grp_worksheet_claims_coveragegroup.d_worksheet_end_date_r
                END
            )                                                        AS worksheet_end_date,
                  /*  CASE
                  WHEN f_grp_transactions_r_claims.v_business_object_id_r IN ( 'LIFECLAIM', 'NONSTDCLAIM', 'WOPCLAIM' ) THEN
                  NULL--F_GRP_WORKSHEET_Claims_CoverageGroup.D_WORKSHEET_START_DATE_R
                  ELSE
                  f_grp_worksheet_claims_coverage.d_worksheet_start_date_r
                  END                                                                                           AS worksheet_start_date,*/
            MAX(
                CASE
                    WHEN nvl(f_grp_worksheet_claims_coveragegroup.v_rpt_worksheet_indicator_r, 'Y') = 'Y'
                         AND d_grp_claim_dir_r_claim.v_lob_type_r IN('LTD', 'STD', 'VPL', 'VPS') THEN
                        f_grp_worksheet_claims_coveragegroup.d_worksheet_start_date_r
                END
            )                                                        AS worksheet_start_date,
            CASE
                WHEN d_grp_claim_dir_r_claim.v_lob_type_r IN ( 'LTD', 'STD', 'VPL', 'VPS' ) THEN
                    d_grp_claim_detail_r_claim.d_closure_date_r
            END                                                      AS claim_closed_date,
            MAX(
                CASE
                    WHEN f_grp_worksheet_claims_coveragegroup.v_rpt_worksheet_indicator_r = 'Y' THEN
                        f_grp_worksheet_claims_coveragegroup.n_gross_benefit_r
                    ELSE
                        0
                END
            )                                                        AS claim_gross_benefit_amount,/*Changed to MAX*/
            CAST(TO_DATE(substr(f_grp_transactions_r_claims.v_dc_timestamp_r, 1, 8),
                'YYYYMMDD') AS DATE)                                 AS claim_most_recent_activity_date,
            MAX(
                CASE
                    WHEN f_grp_worksheet_claims_coveragegroup.v_rpt_worksheet_indicator_r = 'Y' THEN
                        f_grp_worksheet_claims_coveragegroup.n_rpt_net_benefit_r
                    ELSE
                        0
                END
            )                                                        AS claim_net_benefit_amount,/*Changed to MAX*/
            d_grp_claim_dir_r_claim.v_claim_number_r                 AS claim_number,
            d_grp_busobj_audit_r.received_date                       AS claim_received_date,
            MAX(
                CASE
                    WHEN f_grp_worksheet_claims_coveragegroup.v_rpt_worksheet_indicator_r = 'Y' THEN
                        f_grp_worksheet_claims_coveragegroup.n_taxable_override_pct_r
                    ELSE
                        NULL
                END
            )                                                        AS claim_taxable_benefit_percentage,
            CASE
                WHEN d_grp_claim_dir_r_claim.v_lob_type_r IN ( 'LTD', 'LTD-Small', 'VLT', 'VPL' ) THEN
                    'M'
                WHEN d_grp_claim_dir_r_claim.v_lob_type_r IN ( 'DBL', 'STD', 'STD-Small', 'VPS' ) THEN
                    'W'
                WHEN NOT d_grp_claim_eligibility_r_claims.n_waiver_termination_age_r IS NULL THEN
                    'A'
                ELSE
                    NULL
            END                                                      AS duration_indicator,

                  /*CASE
                    WHEN d_grp_claim_dir_r_claim.v_lob_type_r                     IN ( 'LTD', 'STD', 'VPL', 'VPS' )
                    THEN ROUND((d_grp_claim_eligibility_r_claims.d_plan_dur_date_r - f_grp_worksheet_claims_coverage.d_benefit_start_r + 1) / 30.45, 0)
                    WHEN f_grp_worksheet_claims_coverage.d_benefit_start_r IS NULL
                    THEN ROUND((d_grp_claim_eligibility_r_claims.d_plan_dur_date_r - d_grp_party_r_claims.d_birth_date_r) / 365.25 * 12, 0)
                    WHEN d_grp_claim_dir_r_claim.v_lob_type_r                     IN ( 'WOP' )
                    THEN d_grp_claim_eligibility_r_claims.n_waiver_termination_age_r
                    ELSE NULL
                  END AS duration_period,*/-- 13 March,2023, Commented the existing logic and added new logic as requested by Suhasini
        /*    CASE
                WHEN d_grp_claim_dir_r_claim.v_lob_type_r IN ( 'LTD', 'STD', 'VPL', 'VPS' ) THEN
                    round((d_grp_claim_eligibility_r_claims.d_plan_dur_date_r - f_grp_worksheet_claims_coveragegroup.d_benefit_start_r + 1) / 30.45
                    , 0)
                WHEN d_grp_claim_dir_r_claim.v_lob_type_r IN ( 'WOP' ) THEN
                    d_grp_claim_eligibility_r_claims.n_waiver_termination_age_r
                WHEN f_grp_worksheet_claims_coveragegroup.d_benefit_start_r IS NULL THEN
                    round((d_grp_claim_eligibility_r_claims.d_plan_dur_date_r - d_grp_party_r_claims.d_birth_date_r) / 365.25 * 12, 0)
                ELSE
                    NULL
            END       */

            CASE
                WHEN d_grp_claim_dir_r_claim.v_lob_type_r                     IN ('STD','VPS' )
                THEN case when d_grp_claim_eligibility_r_claims.v_benefit_duration_r is not null
                then d_grp_claim_eligibility_r_claims.v_benefit_duration_r
                ELSE To_Char(ROUND(((d_grp_claim_eligibility_r_claims.d_plan_dur_date_r - d_grp_party_r_claims.D_BIRTH_DATE_R + 1) /365.25)*12,0 ))
                END
                WHEN d_grp_claim_dir_r_claim.v_lob_type_r                     IN ('LTD','VPL' )
                THEN CASE when  f_grp_worksheet_claims_coveragegroup.D_BENEFIT_START_R is not null
                THEN to_char(ROUND((d_grp_claim_eligibility_r_claims.d_plan_dur_date_r - f_grp_worksheet_claims_coveragegroup.d_benefit_start_r + 1) / 30.45, 0))
                ELSE to_char(ROUND(((d_grp_claim_eligibility_r_claims.d_plan_dur_date_r - d_grp_party_r_claims.D_BIRTH_DATE_R ) /365.25)*12,0 ))
                END
                WHEN d_grp_claim_dir_r_claim.v_lob_type_r                     IN ( 'WOP' )
                            THEN to_char(d_grp_claim_eligibility_r_claims.n_waiver_termination_age_r)
                WHEN d_grp_claim_dir_r_claim.v_lob_type_r                     IN ( 'NONS' )
                THEN case when d_grp_claim_eligibility_r_claims.n_elim_period_r is null then
                To_char(lpad(ROUND(((d_grp_claim_eligibility_r_claims.d_plan_dur_date_r - d_grp_claim_detail_r_claim.d_date_of_loss_r) / 365.25) * 12), 3, '0'))
                else To_char(lpad(ROUND(((d_grp_claim_eligibility_r_claims.d_plan_dur_date_r- (d_grp_claim_detail_r_claim.d_date_of_loss_r+d_grp_claim_eligibility_r_claims.n_elim_period_r))         / 365.25) * 12), 3, '0'))
                end
              --ELSE  lpad(ROUND(((d_grp_claim_eligibility_r_claims.d_plan_dur_date_r - d_grp_party_r_claims.d_birth_date_r)         / 365.25) * 12), 3, '0')
              --END
            ELSE NULL END AS duration_period,
            CASE
                WHEN d_grp_claim_eligibility_r_claims.n_elim_period_r <> ''
                     OR d_grp_claim_eligibility_r_claims.n_elim_period_r <> 0 THEN
                    d_grp_claim_eligibility_r_claims.n_elim_period_r
                WHEN
                    CASE d_grp_claim_event_dir_r_claim.v_event_cause_r
                        WHEN 'ACCIDENT'                        THEN
                            'A6'
                        WHEN 'ACCIDENT - AVIATION'             THEN
                            'A3'
                        WHEN 'ACCIDENT- AVIATION'              THEN
                            'A3'
                        WHEN 'ACCIDENT - OCCUPATIONAL'         THEN
                            'A1'
                        WHEN 'ACCIDENT- OCCUPATIONAL'          THEN
                            'A1'
                        WHEN 'ACCIDENT- OTHER'                 THEN
                            'A6'
                        WHEN 'ACCIDENT - OTHER'                THEN
                            'A6'
                        WHEN 'ACCIDENT - SPORTS'               THEN
                            'A4'
                        WHEN 'ACCIDENT- SPORTS'                THEN
                            'A4'
                        WHEN 'ADOPTION'                        THEN
                            'AE'
                        WHEN 'ALCOHOL'                         THEN
                            'AC'
                        WHEN 'ASSAULT'                         THEN
                            'A5'
                        WHEN 'BONDING'                         THEN
                            'AE'
                        WHEN 'COMMONDISASTER'                  THEN
                            '31'
                        WHEN 'COMMON DISASTER'                 THEN
                            '31'
                        WHEN 'DRUGS'                           THEN
                            'AD'
                        WHEN 'FOSTER'                          THEN
                            'AE'
                        WHEN 'MATERNITY'                       THEN
                            'AE'
                        WHEN 'MENTAL'                          THEN
                            'AA'
                        WHEN 'MISSING INSURED / DISAPPEARANCE' THEN
                            '33'
                        WHEN 'MOTOR VEHICLE'                   THEN
                            'A2'
                        WHEN 'MOTORCYCLE'                      THEN
                            'A2'
                        WHEN 'NERVOUS'                         THEN
                            'AB'
                        WHEN 'SICKNESS'                        THEN
                            'AE'
                        WHEN 'SUICIDE'                         THEN
                            'SU'
                        WHEN 'UNKNOWN / UNDETERMINED'          THEN
                            'UN'
                        WHEN 'UNKNOWN / UNDETER '              THEN
                            'UN'
                        WHEN 'WAR / TERRORISM'                 THEN
                            '40'
                        WHEN 'WELLNESS'                        THEN
                            'WL'
                        ELSE
                            'UN'
                    END
                IN ( 'A1', 'A2', 'A3', 'A4', 'A5',
                     'A6' ) THEN
                    d_grp_claim_eligibility_r_claims.n_elim_period_acc_r
                ELSE
                    d_grp_claim_eligibility_r_claims.n_elim_period_sick_r
            END                                                      AS ellimination_period,
            CASE
                WHEN d_grp_policy_dir_r_policy.v_policy_prefix_r = 'VAI' THEN
                    d_grp_claim_detail_r_claim.d_date_of_event_r
                ELSE
                    d_grp_claim_detail_r_claim.d_date_of_loss_r
            END                                                      AS loss_date,
            d_grp_eeoc_r.v_code_r                                    AS occupation_code,
            d_grp_eeoc_r.v_description_r                             AS occupation_decription,
            d_grp_claim_eligibility_r_claims.d_plan_dur_date_r       AS plan_duration_date,
            d_grp_claim_detail_r_claim.d_return_to_mod_wkdt_r        AS modified_rtw_date,
            d_grp_claim_detail_r_claim.d_return_to_work_date_r       AS return_to_work_date,
           max( CASE
                WHEN d_grp_product_r_claims_disability.v_coverage_type_code_r = '1' THEN
                    'LTD'
                WHEN d_grp_product_r_claims_disability.v_coverage_type_code_r = '2' THEN
                    'STD'
                WHEN d_grp_product_r_claims_disability.v_coverage_type_code_r IN ( '1', '2' ) THEN
                    'Disability (LTD )'
                WHEN d_grp_product_r_claims_life.v_coverage_type_code_r = '3'       THEN
                    'Life'
                WHEN d_grp_product_r_claims_life.v_coverage_category_r = 'Life - Annuity'
                     AND d_grp_product_r_claims_life.v_coverage_type_code_r = '3' THEN
                    'Life - Annuity'
                WHEN d_grp_product_r_claims_life.v_coverage_category_r = 'Life - Non-Annuity'
                     AND d_grp_product_r_claims_life.v_coverage_type_code_r = '3' THEN
                    'Life - Non-Annuity'
                WHEN d_grp_product_r_claims_life.v_coverage_type_code_r = '3'
                     AND NOT ( d_grp_product_r_claims_life.v_coverage_code_r LIKE '%WP%'
                               OR d_grp_product_r_claims_life.v_coverage_code_r LIKE 'GAN%'
                               OR d_grp_product_r_claims_life.v_coverage_code_r LIKE 'CD%' ) THEN
                    'Group Life'
            END       )                                               AS coverage_type,
          max(  CASE
                WHEN d_grp_claim_dir_r_claim.v_lob_type_r IN ( 'LIFE', 'NONS', 'WOP' ) THEN
                    d_grp_claim_coverage_group_r_claims.v_class_id_r
                ELSE
                    d_grp_claim_coverage_r_claims.v_class_id_r
            END             )                                         AS claim_class_id,
            /*CASE
                WHEN d_grp_policy_dir_r_policy.v_orig_lob_r = 'VAI' THEN
                    d_grp_claim_event_dir_r_claim.d_date_of_event_r +
                    CASE
                        WHEN d_grp_claim_eligibility_r_claims.n_elim_period_r <> ''
                             OR d_grp_claim_eligibility_r_claims.n_elim_period_r <> 0 THEN
                                d_grp_claim_eligibility_r_claims.n_elim_period_r
                        ELSE
                            0
                    END
                ELSE
                    d_grp_claim_event_dir_r_claim.d_date_of_event_r*/

                    d_grp_claim_detail_r_claim.d_date_of_loss_r + CASE
                WHEN d_grp_claim_eligibility_r_claims.n_elim_period_r <> ''
                     OR d_grp_claim_eligibility_r_claims.n_elim_period_r <> 0 THEN
                    d_grp_claim_eligibility_r_claims.n_elim_period_r
                WHEN
                    CASE d_grp_claim_event_dir_r_claim.v_event_cause_r
                        WHEN 'ACCIDENT'                        THEN
                            'A6'
                        WHEN 'ACCIDENT - AVIATION'             THEN
                            'A3'
                        WHEN 'ACCIDENT- AVIATION'              THEN
                            'A3'
                        WHEN 'ACCIDENT - OCCUPATIONAL'         THEN
                            'A1'
                        WHEN 'ACCIDENT- OCCUPATIONAL'          THEN
                            'A1'
                        WHEN 'ACCIDENT- OTHER'                 THEN
                            'A6'
                        WHEN 'ACCIDENT - OTHER'                THEN
                            'A6'
                        WHEN 'ACCIDENT - SPORTS'               THEN
                            'A4'
                        WHEN 'ACCIDENT- SPORTS'                THEN
                            'A4'
                        WHEN 'ADOPTION'                        THEN
                            'AE'
                        WHEN 'ALCOHOL'                         THEN
                            'AC'
                        WHEN 'ASSAULT'                         THEN
                            'A5'
                        WHEN 'BONDING'                         THEN
                            'AE'
                        WHEN 'COMMONDISASTER'                  THEN
                            '31'
                        WHEN 'COMMON DISASTER'                 THEN
                            '31'
                        WHEN 'DRUGS'                           THEN
                            'AD'
                        WHEN 'FOSTER'                          THEN
                            'AE'
                        WHEN 'MATERNITY'                       THEN
                            'AE'
                        WHEN 'MENTAL'                          THEN
                            'AA'
                        WHEN 'MISSING INSURED / DISAPPEARANCE' THEN
                            '33'
                        WHEN 'MOTOR VEHICLE'                   THEN
                            'A2'
                        WHEN 'MOTORCYCLE'                      THEN
                            'A2'
                        WHEN 'NERVOUS'                         THEN
                            'AB'
                        WHEN 'SICKNESS'                        THEN
                            'AE'
                        WHEN 'SUICIDE'                         THEN
                            'SU'
                        WHEN 'UNKNOWN / UNDETERMINED'          THEN
                            'UN'
                        WHEN 'UNKNOWN / UNDETER '              THEN
                            'UN'
                        WHEN 'WAR / TERRORISM'                 THEN
                            '40'
                        WHEN 'WELLNESS'                        THEN
                            'WL'
                        ELSE
                            'UN'
                    END
                IN ( 'A1', 'A2', 'A3', 'A4', 'A5',
                     'A6' ) THEN
                    d_grp_claim_eligibility_r_claims.n_elim_period_acc_r
                ELSE
                    d_grp_claim_eligibility_r_claims.n_elim_period_sick_r
            END
               AS disability_start_date,
            d_grp_claim_dir_r_claim.V_PRIVACY_INDICATOR_R as PRIVACY_INDICATOR
            ,NULL CURRENT_RESERVE--26-Oct-2023 changes
			,d_grp_policy_dir_r_policy.T_POLICY_EFFECTIVE_DATE_R --26-Mar-2024 changes			
		FROM
            (
                (
                    (
                             dim_grp_policy_dir_r d_grp_policy_dir_r_policy
                        INNER JOIN dim_grp_claim_dir_r            d_grp_claim_dir_r_claim ON d_grp_policy_dir_r_policy.n_policy_sk_r = d_grp_claim_dir_r_claim.n_policy_sk_r
                        LEFT OUTER JOIN (
                            SELECT
                                v_claim_number_r,
                                MAX(nvl(t374156.d_received_date_r,
                                        TO_DATE(substr(t374156.v_claim_number_r, 1, 10),
                                                'YYYY-MM-DD'))) AS received_date
                            FROM
                                dim_grp_busobj_audit_r t374156
                            WHERE
                                    v_active_status_r = 'Y'
                                AND v_claim_number_r NOT IN ( '-LIFE-01', '-LTD-01', '-STD-01', '-VPS-01', '-WOP-01' )
                            GROUP BY
                                v_claim_number_r
                        )                              d_grp_busobj_audit_r ON d_grp_claim_dir_r_claim.v_claim_number_r = d_grp_busobj_audit_r.v_claim_number_r
                        LEFT OUTER JOIN (
                            SELECT
                                *
                            FROM
                                fct_grp_worksheet
                            WHERE
                                v_rpt_worksheet_indicator_r = 'Y'
                        )                              f_grp_worksheet_claims_coveragegroup


                  /* F_GRP_WORKSHEET_Claims_CoverageGroup */ ON d_grp_claim_dir_r_claim.n_claim_sk_r = f_grp_worksheet_claims_coveragegroup.n_claim_sk_r
                    )
                    INNER JOIN dim_grp_claim_detail_r         d_grp_claim_detail_r_claim
                  /* D_GRP_CLAIM_DETAIL_R_Claim */ ON d_grp_claim_detail_r_claim.n_claim_sk_r = d_grp_claim_dir_r_claim.n_claim_sk_r
                )
                LEFT OUTER JOIN dim_grp_party_r                d_grp_party_r_claims
                  /* D_GRP_PARTY_R_Claims */ ON d_grp_claim_detail_r_claim.n_insrd_party_sk_r = d_grp_party_r_claims.n_party_sk_r
            ),
               -- LEFT OUTER JOIN dim_grp_busobj_audit_r d_grp_busobj_audit_r
                  /* D_GRP_BUSOBJ_AUDIT_R */
              --  ON d_grp_claim_dir_r_claim.v_claim_number_r = d_grp_busobj_audit_r.v_claim_number_r,
            fct_grp_policy_r               f_grp_policy_r_policy
                  /* F_GRP_POLICY_R_Policy */,
            (
                SELECT
                    *
                FROM
                    fct_grp_transactions_r
                WHERE
                    n_claim_sk_r <> - 1
            )                              f_grp_transactions_r_claims
                  /* F_GRP_TRANSACTIONS_R_Claims */, ( (
                (
                    (
                        (
                            (
                                dim_grp_claim_coverage_r       d_grp_claim_coverage_r_claims
                  /* D_GRP_CLAIM_COVERAGE_R_Claims */
                                LEFT OUTER JOIN (
                                    dim_grp_claim_coverage_group_r d_grp_claim_coverage_group_r_claims
                  /* D_GRP_CLAIM_COVERAGE_GROUP_R_Claims */
                                    LEFT OUTER JOIN mvw_product_sk_lookup_tbl      vw_product_sk_lookup_for_life
                  /* VW_PRODUCT_SK_LOOKUP_For_Life */ ON d_grp_claim_coverage_group_r_claims.n_claim_sk_r = vw_product_sk_lookup_for_life.n_claim_sk_r
                                                                                                               AND d_grp_claim_coverage_group_r_claims.v_claim_coverage_code_r = vw_product_sk_lookup_for_life.v_claim_coverage_code_r
                                ) ON d_grp_claim_coverage_group_r_claims.n_claim_coverage_sk_r = d_grp_claim_coverage_r_claims.n_claim_coverage_sk_r
                            )
                            LEFT OUTER JOIN dim_grp_product_r              d_grp_product_r_claims_life
                  /* D_GRP_PRODUCT_R_Claims_Life */ ON d_grp_product_r_claims_life.n_product_sk_r = vw_product_sk_lookup_for_life.n_product_sk_r
                        )
                        LEFT OUTER JOIN mvw_product_sk_lookup_tbl      vw_product_sk_lookup_for_disablity
                  /* VW_PRODUCT_SK_LOOKUP_For_Disablity */ ON d_grp_claim_coverage_r_claims.n_claim_sk_r = vw_product_sk_lookup_for_disablity.n_claim_sk_r
                                                                                                        AND d_grp_claim_coverage_r_claims.v_claim_coverage_code_r = vw_product_sk_lookup_for_disablity.v_claim_coverage_code_r
                    )
                    LEFT OUTER JOIN dim_grp_product_r              d_grp_product_r_claims_disability
                  /* D_GRP_PRODUCT_R_Claims_Disability */ ON vw_product_sk_lookup_for_disablity.n_product_sk_r = d_grp_product_r_claims_disability.n_product_sk_r
                )
                LEFT OUTER JOIN dim_grp_claim_eligibility_r    d_grp_claim_eligibility_r_claims
                  /* D_GRP_CLAIM_ELIGIBILITY_R_Claims */ ON d_grp_claim_eligibility_r_claims.n_claim_coverage_sk_r = CASE
                                                                                                                                                               WHEN
                                                                                                                                                               d_grp_claim_eligibility_r_claims.n_claim_coverage_sk_r <> - 1
                                                                                                                                                               THEN
                                                                                                                                                                   d_grp_claim_coverage_r_claims.n_claim_coverage_sk_r
                                                                                                                                                               ELSE
                                                                                                                                                                   - 1
                                                                                                                                                           END
                                                                                                AND d_grp_claim_eligibility_r_claims.n_claim_sk_r = d_grp_claim_coverage_r_claims.n_claim_sk_r
            ) )
               -- LEFT OUTER JOIN fct_grp_worksheet f_grp_worksheet_claims_coverage
                  /* F_GRP_WORKSHEET_Claims_Coverage */
              --  ON d_grp_claim_coverage_r_claims. n_claim_coverage_sk_r = f_grp_worksheet_claims_coverage.n_claim_coverage_sk_r
          --      AND d_grp_claim_coverage_r_claims.n_claim_sk_r          = f_grp_worksheet_claims_coverage. n_claim_sk_r
            , dim_grp_claim_event_r          d_grp_claim_event_r_claim
                  /* D_GRP_CLAIM_EVENT_R_Claim */
            LEFT OUTER JOIN dim_grp_eeoc_r                 d_grp_eeoc_r ON d_grp_claim_event_r_claim.v_eeoc_code_r = d_grp_eeoc_r.v_code_r,
            dim_grp_claim_event_dir_r      d_grp_claim_event_dir_r_claim
                  /* D_GRP_CLAIM_EVENT_DIR_R_Claim */
        WHERE
            ( d_grp_claim_coverage_r_claims.n_claim_sk_r = d_grp_claim_detail_r_claim.n_claim_sk_r )
            AND ( d_grp_policy_dir_r_policy.n_policy_sk_r = f_grp_policy_r_policy.n_policy_sk_r
                  AND d_grp_policy_dir_r_policy.n_policy_version_number_r = f_grp_policy_r_policy.n_version_number_r
                  AND d_grp_claim_detail_r_claim.n_claim_event_sk_r = d_grp_claim_event_r_claim.n_claim_event_sk_r
                  AND d_grp_claim_dir_r_claim.n_claim_sk_r = f_grp_transactions_r_claims.n_claim_sk_r
                  AND d_grp_claim_detail_r_claim.n_claim_event_sk_r = d_grp_claim_event_r_claim.n_claim_event_sk_r
                  AND d_grp_claim_event_r_claim.n_claim_event_sk_r = d_grp_claim_event_dir_r_claim.n_claim_event_sk_r
                  AND d_grp_policy_dir_r_policy.v_active_status_r = 'Y'
                  AND nvl(d_grp_claim_eligibility_r_claims.v_active_status_r, 'Y') = 'Y'
                  AND nvl(d_grp_claim_coverage_group_r_claims.v_active_status_r, 'Y') = 'Y'
                  AND d_grp_claim_coverage_r_claims.v_active_status_r = 'Y'
                  AND d_grp_claim_detail_r_claim.v_active_status_r = 'Y'
                  AND d_grp_claim_dir_r_claim.v_active_status_r = 'Y'
                  AND d_grp_claim_event_r_claim.v_active_status_r = 'Y'
                  AND d_grp_claim_event_dir_r_claim.v_active_status_r = 'Y'
                  AND nvl(d_grp_eeoc_r.v_active_status_r, 'Y') = 'Y'
                  AND d_grp_claim_dir_r_claim.v_lob_type_r IN ( 'LTD', 'STD', 'VPL', 'VPS' )
                  --  AND ( d_grp_claim_dir_r_claim.v_claim_number_r IN ( '2021-10-08-0164-GL-01') )
                  -- and d_grp_claim_coverage_group_r_claims.v_claim_identifier_r ='2021-10-08-0164-GL-01-02'
                   )
        GROUP BY
            d_grp_policy_dir_r_policy.n_policy_sk_r,
            d_grp_claim_dir_r_claim.n_claim_sk_r,
                  --CAST(TRUNC(d_grp_policy_dir_r_policy.t_event_timestamp_r) AS DATE)



                  /* 10 March-2023 As per Suhasini's request commeting the CLAIM_IDENTIFIER old logic and adding an new one*/
                 -- NVL(d_grp_claim_coverage_group_r_claims.V_CLAIM_IDENTIFIER_R,d_grp_claim_dir_r_claim.v_claim_number_r ) CLAIM_IDENTIFIER,
            --d_grp_claim_coverage_group_r_claims.v_claim_identifier_r,
            d_grp_claim_dir_r_claim.v_claim_number_r , /* Updated 3/20/2023 to fix duplicate issue */
            d_grp_policy_dir_r_policy.v_policy_prefix_r,
            d_grp_policy_dir_r_policy.v_policy_suffix_r,
            f_grp_policy_r_policy.V_ADMINISTERED_BY_R ,
                  /*  CASE
                  WHEN f_grp_transactions_r_claims.v_business_object_id_r IN ( 'LIFECLAIM', 'NONSTDCLAIM', 'WOPCLAIM' ) THEN
                  NULL--F_GRP_WORKSHEET_Claims_CoverageGroup.D_WORKSHEET_END_DATE_R
                  ELSE
                  f_grp_worksheet_claims_coverage.d_worksheet_end_date_r
                  END                                                                                         */

                  /*  CASE
                  WHEN f_grp_transactions_r_claims.v_business_object_id_r IN ( 'LIFECLAIM', 'NONSTDCLAIM', 'WOPCLAIM' ) THEN
                  NULL--F_GRP_WORKSHEET_Claims_CoverageGroup.D_WORKSHEET_START_DATE_R
                  ELSE
                  f_grp_worksheet_claims_coverage.d_worksheet_start_date_r
                  END                                                                                           AS worksheet_start_date,*/

            CASE
                WHEN d_grp_claim_dir_r_claim.v_lob_type_r IN ( 'LTD', 'STD', 'VPL', 'VPS' ) THEN
                        d_grp_claim_detail_r_claim.d_closure_date_r
            END,
            CAST(TO_DATE(substr(f_grp_transactions_r_claims.v_dc_timestamp_r, 1, 8),
                'YYYYMMDD') AS DATE),
            d_grp_claim_dir_r_claim.v_claim_number_r,
            d_grp_busobj_audit_r.received_date,
            CASE
                    WHEN d_grp_claim_dir_r_claim.v_lob_type_r IN ( 'LTD', 'LTD-Small', 'VLT', 'VPL' ) THEN
                        'M'
                    WHEN d_grp_claim_dir_r_claim.v_lob_type_r IN ( 'DBL', 'STD', 'STD-Small', 'VPS' ) THEN
                        'W'
                    WHEN NOT d_grp_claim_eligibility_r_claims.n_waiver_termination_age_r IS NULL THEN
                        'A'
                    ELSE
                        NULL
            END,

                  /*CASE
                    WHEN d_grp_claim_dir_r_claim.v_lob_type_r                     IN ( 'LTD', 'STD', 'VPL', 'VPS' )
                    THEN ROUND((d_grp_claim_eligibility_r_claims.d_plan_dur_date_r - f_grp_worksheet_claims_coverage.d_benefit_start_r + 1) / 30.45, 0)
                    WHEN f_grp_worksheet_claims_coverage.d_benefit_start_r IS NULL
                    THEN ROUND((d_grp_claim_eligibility_r_claims.d_plan_dur_date_r - d_grp_party_r_claims.d_birth_date_r) / 365.25 * 12, 0)
                    WHEN d_grp_claim_dir_r_claim.v_lob_type_r                     IN ( 'WOP' )
                    THEN d_grp_claim_eligibility_r_claims.n_waiver_termination_age_r
                    ELSE NULL
                  END AS duration_period,*/-- 13 March,2023, Commented the existing logic and added new logic as requested by Suhasini
            CASE
                WHEN d_grp_claim_dir_r_claim.v_lob_type_r                     IN ('STD','VPS' )
                THEN case when d_grp_claim_eligibility_r_claims.v_benefit_duration_r is not null
                then d_grp_claim_eligibility_r_claims.v_benefit_duration_r
                ELSE To_Char(ROUND(((d_grp_claim_eligibility_r_claims.d_plan_dur_date_r - d_grp_party_r_claims.D_BIRTH_DATE_R + 1) /365.25)*12,0 ))
                END
                WHEN d_grp_claim_dir_r_claim.v_lob_type_r                     IN ('LTD','VPL' )
                THEN CASE when  f_grp_worksheet_claims_coveragegroup.D_BENEFIT_START_R is not null
                THEN to_char(ROUND((d_grp_claim_eligibility_r_claims.d_plan_dur_date_r - f_grp_worksheet_claims_coveragegroup.d_benefit_start_r + 1) / 30.45, 0))
                ELSE to_char(ROUND(((d_grp_claim_eligibility_r_claims.d_plan_dur_date_r - d_grp_party_r_claims.D_BIRTH_DATE_R ) /365.25)*12,0 ))
                END
                WHEN d_grp_claim_dir_r_claim.v_lob_type_r                     IN ( 'WOP' )
                            THEN to_char(d_grp_claim_eligibility_r_claims.n_waiver_termination_age_r)
                WHEN d_grp_claim_dir_r_claim.v_lob_type_r                     IN ( 'NONS' )
                THEN case when d_grp_claim_eligibility_r_claims.n_elim_period_r is null then
                To_char(lpad(ROUND(((d_grp_claim_eligibility_r_claims.d_plan_dur_date_r - d_grp_claim_detail_r_claim.d_date_of_loss_r) / 365.25) * 12), 3, '0'))
                else To_char(lpad(ROUND(((d_grp_claim_eligibility_r_claims.d_plan_dur_date_r- (d_grp_claim_detail_r_claim.d_date_of_loss_r+d_grp_claim_eligibility_r_claims.n_elim_period_r))         / 365.25) * 12), 3, '0'))
                end
              --ELSE  lpad(ROUND(((d_grp_claim_eligibility_r_claims.d_plan_dur_date_r - d_grp_party_r_claims.d_birth_date_r)         / 365.25) * 12), 3, '0')
              --END
              ELSE NULL END,
            CASE
                    WHEN d_grp_claim_eligibility_r_claims.n_elim_period_r <> ''
                         OR d_grp_claim_eligibility_r_claims.n_elim_period_r <> 0 THEN
                        d_grp_claim_eligibility_r_claims.n_elim_period_r
                    WHEN
                        CASE d_grp_claim_event_dir_r_claim.v_event_cause_r
                            WHEN 'ACCIDENT'                        THEN
                                'A6'
                            WHEN 'ACCIDENT - AVIATION'             THEN
                                'A3'
                            WHEN 'ACCIDENT- AVIATION'              THEN
                                'A3'
                            WHEN 'ACCIDENT - OCCUPATIONAL'         THEN
                                'A1'
                            WHEN 'ACCIDENT- OCCUPATIONAL'          THEN
                                'A1'
                            WHEN 'ACCIDENT- OTHER'                 THEN
                                'A6'
                            WHEN 'ACCIDENT - OTHER'                THEN
                                'A6'
                            WHEN 'ACCIDENT - SPORTS'               THEN
                                'A4'
                            WHEN 'ACCIDENT- SPORTS'                THEN
                                'A4'
                            WHEN 'ADOPTION'                        THEN
                                'AE'
                            WHEN 'ALCOHOL'                         THEN
                                'AC'
                            WHEN 'ASSAULT'                         THEN
                                'A5'
                            WHEN 'BONDING'                         THEN
                                'AE'
                            WHEN 'COMMONDISASTER'                  THEN
                                '31'
                            WHEN 'COMMON DISASTER'                 THEN
                                '31'
                            WHEN 'DRUGS'                           THEN
                                'AD'
                            WHEN 'FOSTER'                          THEN
                                'AE'
                            WHEN 'MATERNITY'                       THEN
                                'AE'
                            WHEN 'MENTAL'                          THEN
                                'AA'
                            WHEN 'MISSING INSURED / DISAPPEARANCE' THEN
                                '33'
                            WHEN 'MOTOR VEHICLE'                   THEN
                                'A2'
                            WHEN 'MOTORCYCLE'                      THEN
                                'A2'
                            WHEN 'NERVOUS'                         THEN
                                'AB'
                            WHEN 'SICKNESS'                        THEN
                                'AE'
                            WHEN 'SUICIDE'                         THEN
                                'SU'
                            WHEN 'UNKNOWN / UNDETERMINED'          THEN
                                'UN'
                            WHEN 'UNKNOWN / UNDETER '              THEN
                                'UN'
                            WHEN 'WAR / TERRORISM'                 THEN
                                '40'
                            WHEN 'WELLNESS'                        THEN
                                'WL'
                            ELSE
                                'UN'
                        END
                    IN ( 'A1', 'A2', 'A3', 'A4', 'A5',
                         'A6' ) THEN
                        d_grp_claim_eligibility_r_claims.n_elim_period_acc_r
                    ELSE
                        d_grp_claim_eligibility_r_claims.n_elim_period_sick_r
            END,
            CASE
                WHEN d_grp_policy_dir_r_policy.v_policy_prefix_r = 'VAI' THEN
                        d_grp_claim_detail_r_claim.d_date_of_event_r
                ELSE
                    d_grp_claim_detail_r_claim.d_date_of_loss_r
            END,
            d_grp_eeoc_r.v_code_r,
            d_grp_eeoc_r.v_description_r,
            d_grp_claim_eligibility_r_claims.d_plan_dur_date_r,
            d_grp_claim_detail_r_claim.d_return_to_mod_wkdt_r,
            d_grp_claim_detail_r_claim.d_return_to_work_date_r,
            d_grp_claim_dir_r_claim.V_PRIVACY_INDICATOR_R,
            /*CASE
                    WHEN d_grp_product_r_claims_disability.v_coverage_type_code_r = '1' THEN
                        'LTD'
                    WHEN d_grp_product_r_claims_disability.v_coverage_type_code_r = '2' THEN
                        'STD'
                    WHEN d_grp_product_r_claims_disability.v_coverage_type_code_r IN ( '1', '2' ) THEN
                        'Disability (LTD )'
                    WHEN d_grp_product_r_claims_life.v_coverage_type_code_r = '3'       THEN
                        'Life'
                    WHEN d_grp_product_r_claims_life.v_coverage_category_r = 'Life - Annuity'
                         AND d_grp_product_r_claims_life.v_coverage_type_code_r = '3' THEN
                        'Life - Annuity'
                    WHEN d_grp_product_r_claims_life.v_coverage_category_r = 'Life - Non-Annuity'
                         AND d_grp_product_r_claims_life.v_coverage_type_code_r = '3' THEN
                        'Life - Non-Annuity'
                    WHEN d_grp_product_r_claims_life.v_coverage_type_code_r = '3'
                         AND NOT ( d_grp_product_r_claims_life.v_coverage_code_r LIKE '%WP%'
                                   OR d_grp_product_r_claims_life.v_coverage_code_r LIKE 'GAN%'
                                   OR d_grp_product_r_claims_life.v_coverage_code_r LIKE 'CD%' ) THEN
                        'Group Life'
            END,*/
           /* CASE
                WHEN d_grp_claim_dir_r_claim.v_lob_type_r IN ( 'LIFE', 'NONS', 'WOP' ) THEN
                        d_grp_claim_coverage_group_r_claims.v_class_id_r
                ELSE
                    d_grp_claim_coverage_r_claims.v_class_id_r
            END,*/
          /*  CASE
                WHEN d_grp_policy_dir_r_policy.v_orig_lob_r = 'VAI' THEN
                        d_grp_claim_event_dir_r_claim.d_date_of_event_r +
                        CASE
                            WHEN d_grp_claim_eligibility_r_claims.n_elim_period_r <> ''
                                 OR d_grp_claim_eligibility_r_claims.n_elim_period_r <> 0 THEN
                                    d_grp_claim_eligibility_r_claims.n_elim_period_r
                            ELSE
                                0
                        END
                ELSE
                    d_grp_claim_event_dir_r_claim.d_date_of_event_r
            END*/
                d_grp_claim_detail_r_claim.d_date_of_loss_r + CASE
                WHEN d_grp_claim_eligibility_r_claims.n_elim_period_r <> ''
                     OR d_grp_claim_eligibility_r_claims.n_elim_period_r <> 0 THEN
                    d_grp_claim_eligibility_r_claims.n_elim_period_r
                WHEN
                    CASE d_grp_claim_event_dir_r_claim.v_event_cause_r
                        WHEN 'ACCIDENT'                        THEN
                            'A6'
                        WHEN 'ACCIDENT - AVIATION'             THEN
                            'A3'
                        WHEN 'ACCIDENT- AVIATION'              THEN
                            'A3'
                        WHEN 'ACCIDENT - OCCUPATIONAL'         THEN
                            'A1'
                        WHEN 'ACCIDENT- OCCUPATIONAL'          THEN
                            'A1'
                        WHEN 'ACCIDENT- OTHER'                 THEN
                            'A6'
                        WHEN 'ACCIDENT - OTHER'                THEN
                            'A6'
                        WHEN 'ACCIDENT - SPORTS'               THEN
                            'A4'
                        WHEN 'ACCIDENT- SPORTS'                THEN
                            'A4'
                        WHEN 'ADOPTION'                        THEN
                            'AE'
                        WHEN 'ALCOHOL'                         THEN
                            'AC'
                        WHEN 'ASSAULT'                         THEN
                            'A5'
                        WHEN 'BONDING'                         THEN
                            'AE'
                        WHEN 'COMMONDISASTER'                  THEN
                            '31'
                        WHEN 'COMMON DISASTER'                 THEN
                            '31'
                        WHEN 'DRUGS'                           THEN
                            'AD'
                        WHEN 'FOSTER'                          THEN
                            'AE'
                        WHEN 'MATERNITY'                       THEN
                            'AE'
                        WHEN 'MENTAL'                          THEN
                            'AA'
                        WHEN 'MISSING INSURED / DISAPPEARANCE' THEN
                            '33'
                        WHEN 'MOTOR VEHICLE'                   THEN
                            'A2'
                        WHEN 'MOTORCYCLE'                      THEN
                            'A2'
                        WHEN 'NERVOUS'                         THEN
                            'AB'
                        WHEN 'SICKNESS'                        THEN
                            'AE'
                        WHEN 'SUICIDE'                         THEN
                            'SU'
                        WHEN 'UNKNOWN / UNDETERMINED'          THEN
                            'UN'
                        WHEN 'UNKNOWN / UNDETER '              THEN
                            'UN'
                        WHEN 'WAR / TERRORISM'                 THEN
                            '40'
                        WHEN 'WELLNESS'                        THEN
                            'WL'
                        ELSE
                            'UN'
                    END
                IN ( 'A1', 'A2', 'A3', 'A4', 'A5',
                     'A6' ) THEN
                    d_grp_claim_eligibility_r_claims.n_elim_period_acc_r
                ELSE
                    d_grp_claim_eligibility_r_claims.n_elim_period_sick_r
            END
			,d_grp_policy_dir_r_policy.T_POLICY_EFFECTIVE_DATE_R --26-Mar-2024 changes
            ;
		UPDATE FCT_PROC_EXEC_STATUS_LOG_R
						SET V_STATUS_R                = 'Successful',
						T_EXECUTION_END_TIMESTAMP_R = systimestamp
						WHERE N_SERIAL_NUM_R          = N_MAX_SERIAL_NUM_R;
						COMMIT;
			EXCEPTION
			WHEN OTHERS THEN
				V_SQLCODE                    := SQLCODE;
						V_SQLERRM                    := SUBSTR(SYS.STANDARD.SQLERRM,1,500);
						UPDATE FCT_PROC_EXEC_STATUS_LOG_R
						SET V_STATUS_R                = 'Failed',
						T_EXECUTION_END_TIMESTAMP_R = systimestamp,
						V_ERROR_CODE_R				= V_SQLCODE,
						V_ERROR_DESC_R				= V_SQLERRM
						WHERE N_SERIAL_NUM_R          = N_MAX_SERIAL_NUM_R;
					COMMIT;
						RAISE;
			END;
		END IF;

		PKG_GRP_COMMON_UTIL.prc_rebuild_indexes
		(
		p_out_job_id   		  		  => gn_out_job_id,
		p_rpt_table			   		  => 'FCT_BILLING_POLICY_PREMIUM_R_TABLE',
		p_idx_num		  		  	  => 8,
		p_Log_seq_num             	  => 1
		);

		PKG_GRP_COMMON_UTIL.prc_set_global_idx_to_no_parallel
		(
		p_table_name   		  		  => 'FCT_BILLING_POLICY_PREMIUM_R_TABLE',
		p_degree			   		  => 1,
		p_out_job_id             	  => gn_out_job_id,
		p_Log_seq_num				  => 1
		);

		/*
		ln_mv_refresh_chk_cnt:=0;
		OPEN cur_mv_refresh_chk('PROC_REFRESH_GRP_M_VIEW_TBLS.F_PSR_CLAIM_MV_3');
		FETCH cur_mv_refresh_chk INTO ln_mv_refresh_chk_cnt;
		CLOSE cur_mv_refresh_chk;

		IF NVL(ln_mv_refresh_chk_cnt,0) =0 THEN */
		/*Added FCT_BENEFIT_PAYMENT_DETAIL_R_MV code to tune the MV_3 code */
		IF UPPER(TRIM(P_MV_TBL_NAME)) like  '%FCT_BENEFIT_PAYMENT_DETAIL_R_MV%' THEN

			Begin
				SELECT SEQ_FCT_PROC_EXEC_STATUS_LOG_R.NEXTVAL INTO N_MAX_SERIAL_NUM_R FROM DUAL;

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
					LN_BATCH_ID_R,--99999999,
					TO_CHAR(sysdate,'yyyymmdd'),
					1,
					'Started',
					SYSTIMESTAMP,
					USER,
					P_MV_TBL_NAME||'.PROC_REFRESH_GRP_M_VIEW_TBLS.FCT_BENEFIT_PAYMENT_DETAIL_R_MV_TBL',
					N_MAX_SERIAL_NUM_R
					);
				COMMIT;
				--dbms_mview.refresh('FCT_BENEFIT_PAYMENT_DETAIL_R_MV', method => 'C', atomic_refresh => FALSE);
				 EXECUTE IMMEDIATE 'TRUNCATE TABLE FCT_BENEFIT_PAYMENT_DETAIL_R_MV_TBL PURGE SNAPSHOT LOG';
	INSERT /*+APPEND_VALUES*/ INTO FCT_BENEFIT_PAYMENT_DETAIL_R_MV_TBL (n_claim_sk_r,
	n_policy_sk_r,
	v_benefit_code_r,
	n_amount_r)
				SELECT fbpd.n_claim_sk_r,fbpd.n_policy_sk_r,fbpd.v_benefit_code_r,fbpd.n_amount_r
				FROM fct_benefit_payment_detail_r FBPD
				JOIN dim_grp_claim_dir_r DGCD
				ON DGCD.n_claim_sk_r  = FBPD.n_claim_sk_r
				JOIN dim_grp_policy_dir_r DGPD
				ON DGPD.n_policy_sk_r = DGCD.n_policy_sk_r
				GROUP BY fbpd.n_claim_sk_r,fbpd.n_policy_sk_r,fbpd.v_benefit_code_r,fbpd.n_amount_r
				;
				UPDATE FCT_PROC_EXEC_STATUS_LOG_R
							SET V_STATUS_R                = 'Successful',
							T_EXECUTION_END_TIMESTAMP_R = systimestamp
							WHERE N_SERIAL_NUM_R          = N_MAX_SERIAL_NUM_R;
							COMMIT;
			EXCEPTION
			WHEN OTHERS THEN
				V_SQLCODE                    := SQLCODE;
						V_SQLERRM                    := SUBSTR(SYS.STANDARD.SQLERRM,1,500);
						UPDATE FCT_PROC_EXEC_STATUS_LOG_R
						SET V_STATUS_R                = 'Failed',
						T_EXECUTION_END_TIMESTAMP_R = systimestamp,
						V_ERROR_CODE_R				= V_SQLCODE,
						V_ERROR_DESC_R				= V_SQLERRM
						WHERE N_SERIAL_NUM_R          = N_MAX_SERIAL_NUM_R;
					COMMIT;
						RAISE;
			END;
		END IF;

		IF UPPER(TRIM(P_MV_TBL_NAME)) like  '%F_PSR_CLAIM_MV_3%' THEN

			Begin
			SELECT SEQ_FCT_PROC_EXEC_STATUS_LOG_R.NEXTVAL INTO N_MAX_SERIAL_NUM_R FROM DUAL;

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
				LN_BATCH_ID_R,--99999999,
				TO_CHAR(sysdate,'yyyymmdd'),
				1,
				'Started',
				SYSTIMESTAMP,
				USER,
				P_MV_TBL_NAME||'.PROC_REFRESH_GRP_M_VIEW_TBLS.F_PSR_CLAIM_MV_3_TBL',
				N_MAX_SERIAL_NUM_R
				);
			COMMIT;
			--dbms_mview.refresh('F_PSR_CLAIM_MV_3', method => 'C', atomic_refresh => FALSE);
			EXECUTE IMMEDIATE 'TRUNCATE TABLE F_PSR_CLAIM_MV_3_TBL PURGE SNAPSHOT LOG';
			INSERT
			/*+APPEND_VALUES*/
			INTO F_PSR_CLAIM_MV_3_TBL
			(
				POLICY_SKEY                                      ,
	CLAIM_SKEY                                       ,
	AS_OF_DATE                                       ,
	CLAIM_IDENTIFIER                                 ,
	ANN_PREMIUM_CYCLE_DATE                           ,
	PRIMARY_DIAGNOSIS_CODE                           ,
	PRIMARY_DIAGNOSIS_CODE_DESCRIPTION               ,
	PRIMARY_DIAGNOSIS_CATEGORY_DESCRIPTION           ,
	PRIMARY_DIAGNOSIS_CATEGORY                       ,
	ADDITIONAL_DIAGNOSIS_CODE_DESCRIPTION            ,
	ADDITIONAL_DIAGNOSIS_CODE                        ,
	ADDITIONAL_DIAGNOSIS_CATEGORY_DESCRIPTION        ,
	ADDITIONAL_DIAGNOSIS_CATEGORY                    ,
	CLAIM_AGE                                        ,
	CLAIM_COUNT                                      ,
	SOCIAL_SECURITY_PRIMARY_AWARD_AMOUNT             ,
	SOCIAL_SECURITY_PRIMARY_AWARD_STATUS             ,
	SOCIAL_SECURITY_PRIMARY_AWARD_TYPE               ,
	SOCIAL_SECURITY_PRIMARY_AWARD_EFFECTIVE_DATE     ,
	SOCIAL_SECURITY_PRIMARY_AWARD_TERMINATION_DATE   ,
	SOCIAL_SECURITY_DEPENDENT_AWARD_AMOUNT           ,
	SOCIAL_SECURITY_DEPENDENT_AWARD_STATUS           ,
	SOCIAL_SECURITY_DEPENDENT_AWARD_TYPE             ,
	SOCIAL_SECURITY_DEPENDENT_AWARD_EFFECTIVE_DATE   ,
	SOCIAL_SECURITY_DEPENDENT_AWARD_TERMINATION_DATE
				)
	SELECT
    d_grp_policy_dir_r_policy.n_policy_sk_r                                                                 AS policy_skey,
    d_grp_claim_dir_r_claim.n_claim_sk_r                                                                    AS claim_skey,
    (
        SELECT
            MAX(fic_mis_date_r)
        FROM
            dim_grp_policy_dir_r
        WHERE
            v_source_system_name_r = 'PACS'
    )                                                                                                       AS as_of_date,
    D_GRP_CLAIM_DIR_R_Claim.v_claim_number_r AS claim_identifier,
   -- MAX(f_rpt_claim_summary_r.d_cycle_date_r)
   cast (null  AS date) as ann_premium_cycle_date
    ,
			  ---Medical Diagnosis attributes start----
    d_grp_medical_diagnosis_r_claims.v_diagnosis_code_r                                                     AS primary_diagnosis_code
    ,
    d_grp_medical_diagnosis_r_claims.v_diagnosis_desc_r                                                     AS primary_diagnosis_code_description
    ,
    d_diagnosis_category_r.v_diag_category_desc_r                                                           AS primary_diagnosis_category_description
    ,
    d_diagnosis_code_r.v_diag_category_code_r                                                               AS primary_diagnosis_category
    ,
			-- MAX( D_GRP_MEDICAL_DIAGNOSIS_R_Claims_Additional.V_DIAGNOSIS_DESC_R)
    LISTAGG(DISTINCT D_GRP_MEDICAL_DIAGNOSIS_R_Claims_Additional.v_diagnosis_desc_r, '; ')                            AS additional_diagnosis_code_description
    ,
			-- MAX( D_GRP_MEDICAL_DIAGNOSIS_R_Claims_Additional.V_DIAGNOSIS_CODE_R)
    LISTAGG(DISTINCT D_GRP_MEDICAL_DIAGNOSIS_R_Claims_Additional.v_diagnosis_code_r, '; ')                            AS additional_diagnosis_code
    ,
			/* MAX( D_DIAGNOSIS_CATEGORY_R_Additional.V_DIAG_CATEGORY_DESC_R    )   AS Additional_Diagnosis_Category_Description,
			  MAX(D_DIAGNOSIS_CATEGORY_R_Additional.V_DIAG_CATEGORY_CODE_R     )  AS Additional_Diagnosis_Category */
			  -- 13 March,2023, Commented the existing logic and added new logic as requested by Suhasini

    LISTAGG(DISTINCT d_diagnosis_category_r_additional.v_diag_category_desc_r, '; ')                        AS additional_diagnosis_category_description

    ,
    LISTAGG(DISTINCT d_diagnosis_category_r_additional.v_diag_category_code_r, '; ')                        AS additional_diagnosis_category

			  ---Medical Diagnosis attributes End----
			  ---Benifit Payment Attributes Start---
  --  ,
   -- SUM(
   --     CASE
  --          WHEN fct_claim_payment_detail_r.v_benefit_code_r = '088' THEN
      --          fct_claim_payment_detail_r.n_paid_amount_r
 --       END
--    )                                                                                                       AS rehabilitation_offset_amount_088
  --  ,
  --  SUM(
    --    CASE
   --         WHEN fct_claim_payment_detail_r.v_benefit_code_r = '088' THEN
  --              fct_claim_payment_detail_r.n_paid_amount_r
  --      END
 --   )                                                                                                       AS workers_compensation_offset_amount_083
  --  ,
 --   SUM(
  --      CASE
  --          WHEN fct_claim_payment_detail_r.v_benefit_code_r IN('087', '08B', '090', '091', '186',
  --                                                              '188') THEN
  --              fct_claim_payment_detail_r.n_paid_amount_r
  ---      END
  --  )                                                                                                       AS other_offset_amounts,
  --  MAX(
   --     CASE
   --         WHEN fct_claim_payment_detail_r.v_benefit_code_r = '088' THEN
   --             'Y'
  --          ELSE
  --              NULL
  --      END
  --  )                                                                                                       AS rehabilitation_offset_indicator_088
    ,
    --MAX(
   --     CASE
   --         WHEN fct_claim_payment_detail_r.v_benefit_code_r = '188' THEN
   --             'Y'
   --         ELSE
   --             NULL
  --      END
  --  )                                                                                                       AS work_incentive_excess_offset_indicator_188
			  ---Benifit Payment Attributes Ends---
	--		 ,

            case when
         -- CASE WHEN d_grp_claim_dir_r_claim.v_lob_type_r IN ( 'LIFE', 'NONS', 'WOP' ) THEN
           -- D_GRP_CLAIM_COVERAGE_GROUP_R_Claims.d_date_closed_r
           -- WHEN d_grp_claim_dir_r_claim.v_lob_type_r IN ( 'LTD', 'STD', 'VPL', 'VPS' ) THEN
            d_grp_claim_detail_r_claim.d_closure_date_r
  --  END
    is null then null else trunc(         --   CASE
       -- WHEN d_grp_claim_dir_r_claim.v_lob_type_r IN ( 'LIFE', 'NONS', 'WOP' ) THEN
          -- D_GRP_CLAIM_COVERAGE_GROUP_R_Claims.d_date_closed_r
           -- WHEN d_grp_claim_dir_r_claim.v_lob_type_r IN ( 'LTD', 'STD', 'VPL', 'VPS' ) THEN
            d_grp_claim_detail_r_claim.d_closure_date_r
  --  END
    -     d_grp_busobj_audit_r.received_date          ) end    AS Claim_Age,
			1 -- max(F_RPT_CLAIM_SUMMARY_R.N_TOTAL_CLAIM_COUNT_R)
              AS Claim_Count,
			  ---FCT_CLAIM_SOCIALSECURITY_INC_R attributes start--
			  F_CLAIM_SOCIALSECURITY_INC_R_Claims.N_SS_PRIMARY_AWARD_AMOUNT_R AS Social_Security_Primary_Award_Amount,
			  F_CLAIM_SOCIALSECURITY_INC_R_Claims.V_SS_STATUS_DESCRIPTION_R   AS Social_Security_Primary_Award_Status,
			  F_CLAIM_SOCIALSECURITY_INC_R_Claims.V_SS_PRIMARY_AWARD_TYPE_R   AS Social_Security_Primary_Award_Type,
			  F_CLAIM_SOCIALSECURITY_INC_R_Claims.D_SS_PRIMARY_EFF_DATE_R     AS Social_Security_Primary_Award_Effective_Date,
			  F_CLAIM_SOCIALSECURITY_INC_R_Claims.D_SS_CLOSED_TERM_DATE_R     AS Social_Security_Primary_Award_Termination_Date,
			  F_CLAIM_SOCIALSECURITY_INC_R_Claims.N_SS_DEP_AWARD_AMOUNT_R     AS Social_Security_Dependent_Award_Amount,
			  F_CLAIM_SOCIALSECURITY_INC_R_Claims.V_SS_DEPENDENT_STATUS_R     AS Social_Security_Dependent_Award_Status,
			  F_CLAIM_SOCIALSECURITY_INC_R_Claims.V_SS_DEP_AWARD_TYPE_R       AS Social_Security_Dependent_Award_Type,
			  F_CLAIM_SOCIALSECURITY_INC_R_Claims.D_SS_DEP_AWARD_EFF_DATE_R   AS Social_Security_Dependent_Award_Effective_Date,
			  F_CLAIM_SOCIALSECURITY_INC_R_Claims.D_SS_DEP_TERM_DATE_R        AS Social_Security_Dependent_Award_Termination_Date

--			   CASE
--				WHEN D_GRP_POLICY_DIR_R_Policy.V_ORIG_LOB_R = 'VAI'
--				THEN D_GRP_CLAIM_EVENT_DIR_R_Claim.D_DATE_OF_EVENT_R +
--					  CASE
--						WHEN D_GRP_CLAIM_ELIGIBILITY_R_Claims.N_ELIM_PERIOD_R <> ''
--						OR D_GRP_CLAIM_ELIGIBILITY_R_Claims.N_ELIM_PERIOD_R   <> 0
--						THEN D_GRP_CLAIM_ELIGIBILITY_R_Claims.N_ELIM_PERIOD_R
--						else 0 end
--				else D_GRP_CLAIM_EVENT_DIR_R_Claim.D_DATE_OF_EVENT_R	end	as Disability_Start_Date


		FROM

			  DIM_GRP_POLICY_DIR_R D_GRP_POLICY_DIR_R_Policy /* D_GRP_POLICY_DIR_R_Policy */
			  inner join DIM_GRP_CLAIM_DIR_R D_GRP_CLAIM_DIR_R_Claim   /* D_GRP_CLAIM_DIR_R_Claim */
              on D_GRP_POLICY_DIR_R_Policy.N_POLICY_SK_R = D_GRP_CLAIM_DIR_R_Claim.N_POLICY_SK_R
              AND D_GRP_CLAIM_DIR_R_Claim.V_ACTIVE_STATUS_R         = 'Y'
               LEFT OUTER JOIN (
                    SELECT
                        v_claim_number_r,
                        MAX(nvl(t374156.d_received_date_r,
                                TO_DATE(substr(t374156.v_claim_number_r, 1, 10),
                                        'YYYY-MM-DD'))) AS received_date
                    FROM
                        dim_grp_busobj_audit_r t374156
                    WHERE
                            v_active_status_r = 'Y'
                        AND v_claim_number_r NOT IN ( '-LIFE-01', '-LTD-01', '-STD-01', '-VPS-01', '-WOP-01' )
                    GROUP BY
                        v_claim_number_r
                )                              d_grp_busobj_audit_r ON d_grp_claim_dir_r_claim.v_claim_number_r = d_grp_busobj_audit_r.v_claim_number_r
			  inner join DIM_GRP_CLAIM_DETAIL_R D_GRP_CLAIM_DETAIL_R_Claim /* D_GRP_CLAIM_DETAIL_R_Claim */
              on D_GRP_CLAIM_DETAIL_R_Claim.N_CLAIM_SK_R = D_GRP_CLAIM_DIR_R_Claim.N_CLAIM_SK_R and D_GRP_CLAIM_DETAIL_R_Claim.V_ACTIVE_STATUS_R = 'Y'
			  inner join DIM_GRP_CLAIM_COVERAGE_R D_GRP_CLAIM_COVERAGE_R_Claims  /* D_GRP_CLAIM_COVERAGE_R_Claims */
              on D_GRP_CLAIM_DIR_R_Claim.N_CLAIM_SK_R = D_GRP_CLAIM_COVERAGE_R_Claims.N_CLAIM_SK_R and D_GRP_CLAIM_COVERAGE_R_Claims.V_ACTIVE_STATUS_R = 'Y'
			  left outer join MVW_PRODUCT_SK_LOOKUP T439745 /* VW_PRODUCT_SK_LOOKUP_For_Disablity */
              On D_GRP_CLAIM_COVERAGE_R_Claims.N_CLAIM_SK_R = T439745.N_CLAIM_SK_R and D_GRP_CLAIM_COVERAGE_R_Claims.V_CLAIM_COVERAGE_CODE_R = T439745.V_CLAIM_COVERAGE_CODE_R
			  LEFT OUTER JOIN DIM_GRP_PRODUCT_R D_GRP_PRODUCT_R_Claims_Disability  /* D_GRP_PRODUCT_R_Claims_Disability */
              On D_GRP_PRODUCT_R_Claims_Disability.N_PRODUCT_SK_R = T439745.N_PRODUCT_SK_R and D_GRP_PRODUCT_R_Claims_Disability.V_ACTIVE_STATUS_R = 'Y'
			  inner join DIM_GRP_CLAIM_COVERAGE_GROUP_R D_GRP_CLAIM_COVERAGE_GROUP_R_Claims /* D_GRP_CLAIM_COVERAGE_GROUP_R_Claims */
              on D_GRP_CLAIM_COVERAGE_GROUP_R_Claims.N_CLAIM_COVERAGE_SK_R = D_GRP_CLAIM_COVERAGE_R_Claims.N_CLAIM_COVERAGE_SK_R
              and D_GRP_CLAIM_COVERAGE_GROUP_R_Claims.V_ACTIVE_STATUS_R = 'Y'
			--  left outer join MVW_PRODUCT_SK_LOOKUP T439747 /* VW_PRODUCT_SK_LOOKUP_For_Life */
          --    On D_GRP_CLAIM_COVERAGE_GROUP_R_Claims.N_CLAIM_SK_R = T439747.N_CLAIM_SK_R and D_GRP_CLAIM_COVERAGE_GROUP_R_Claims.V_CLAIM_COVERAGE_CODE_R = T439747.V_CLAIM_COVERAGE_CODE_R
			--  LEFT OUTER JOIN DIM_GRP_PRODUCT_R D_GRP_PRODUCT_R_Claims_Life  /* D_GRP_PRODUCT_R_Claims_Life */
          --    On D_GRP_PRODUCT_R_Claims_Life.N_PRODUCT_SK_R = T439747.N_PRODUCT_SK_R and D_GRP_PRODUCT_R_Claims_Life.V_ACTIVE_STATUS_R = 'Y'

		--	left outer join FCT_RPT_CLAIM_SUMMARY_R F_RPT_CLAIM_SUMMARY_R  /* F_RPT_CLAIM_SUMMARY_R */
         --   on D_GRP_CLAIM_DIR_R_Claim.V_CLAIM_NUMBER_R          = F_RPT_CLAIM_SUMMARY_R.V_CLAIM_NUMBER_R

--			LEFT OUTER JOIN DIM_GRP_CLAIM_ELIGIBILITY_R D_GRP_CLAIM_ELIGIBILITY_R_Claims  /* D_GRP_CLAIM_ELIGIBILITY_R_Claims */ ON D_GRP_CLAIM_DETAIL_R_Claim.N_CLAIM_SK_R = D_GRP_CLAIM_ELIGIBILITY_R_Claims.N_CLAIM_SK_R and D_GRP_CLAIM_ELIGIBILITY_R_Claims.V_ACTIVE_STATUS_R         = 'Y'

--			left outer join DIM_GRP_CLAIM_EVENT_R D_GRP_CLAIM_EVENT_R_Claim  /* D_GRP_CLAIM_EVENT_R_Claim */ on D_GRP_CLAIM_DETAIL_R_Claim.N_CLAIM_EVENT_SK_R  = D_GRP_CLAIM_EVENT_R_Claim.N_CLAIM_EVENT_SK_R and  D_GRP_CLAIM_EVENT_R_Claim.V_ACTIVE_STATUS_R         = 'Y'
--			left outer join DIM_GRP_CLAIM_EVENT_DIR_R D_GRP_CLAIM_EVENT_DIR_R_Claim  /* D_GRP_CLAIM_EVENT_DIR_R_Claim */ on D_GRP_CLAIM_EVENT_DIR_R_Claim.N_CLAIM_EVENT_SK_R        = D_GRP_CLAIM_EVENT_R_Claim.N_CLAIM_EVENT_SK_R  and D_GRP_CLAIM_EVENT_DIR_R_Claim.V_ACTIVE_STATUS_R         = 'Y'

			left outer join DIM_GRP_MEDICAL_DIAGNOSIS_R D_GRP_MEDICAL_DIAGNOSIS_R_Claims  /* D_GRP_MEDICAL_DIAGNOSIS_R_Claims */
            on  D_GRP_CLAIM_DIR_R_Claim.N_CLAIM_SK_R              = D_GRP_MEDICAL_DIAGNOSIS_R_Claims.N_CLAIM_SK_R
            AND D_GRP_MEDICAL_DIAGNOSIS_R_Claims.N_PRIMARY_IND_R           = 1
            AND D_GRP_MEDICAL_DIAGNOSIS_R_Claims.V_ACTIVE_STATUS_R         = 'Y'
			left outer join DIM_DIAGNOSIS_CODE_R D_DIAGNOSIS_CODE_R  /* D_DIAGNOSIS_CODE_R */
            on D_GRP_MEDICAL_DIAGNOSIS_R_Claims.V_DIAGNOSIS_CODE_R        = D_DIAGNOSIS_CODE_R.V_DIAG_CODE_R
			left outer join DIM_DIAGNOSIS_CATEGORY_R D_DIAGNOSIS_CATEGORY_R  /* D_DIAGNOSIS_CATEGORY_R */
            on D_DIAGNOSIS_CODE_R.V_DIAG_CATEGORY_CODE_R    = D_DIAGNOSIS_CATEGORY_R.V_DIAG_CATEGORY_CODE_R

			left outer join DIM_GRP_MEDICAL_DIAGNOSIS_R D_GRP_MEDICAL_DIAGNOSIS_R_Claims_Additional  /* D_GRP_MEDICAL_DIAGNOSIS_R_Claims_Additional */
            on D_GRP_CLAIM_DIR_R_Claim.N_CLAIM_SK_R = D_GRP_MEDICAL_DIAGNOSIS_R_Claims_Additional.N_CLAIM_SK_R
            AND D_GRP_MEDICAL_DIAGNOSIS_R_Claims_Additional.N_PRIMARY_IND_R = 0 AND D_GRP_MEDICAL_DIAGNOSIS_R_Claims_Additional.V_ACTIVE_STATUS_R ='Y'
			left outer join DIM_DIAGNOSIS_CODE_R D_DIAGNOSIS_CODE_R_Additional  /* D_DIAGNOSIS_CODE_R_Additional */
            on D_DIAGNOSIS_CODE_R_Additional.V_DIAG_CODE_R = D_GRP_MEDICAL_DIAGNOSIS_R_Claims_Additional.V_DIAGNOSIS_CODE_R
			left outer join DIM_DIAGNOSIS_CATEGORY_R D_DIAGNOSIS_CATEGORY_R_Additional  /* D_DIAGNOSIS_CATEGORY_R_Additional */
            on D_DIAGNOSIS_CATEGORY_R_Additional.V_DIAG_CATEGORY_CODE_R    = D_DIAGNOSIS_CODE_R_Additional.V_DIAG_CATEGORY_CODE_R

			left outer join FCT_CLAIM_SOCIALSECURITY_INC_R F_CLAIM_SOCIALSECURITY_INC_R_Claims  /* F_BENEFIT_PAYMENT_DETAIL_R_Payments_Detail */
            on D_GRP_CLAIM_DIR_R_Claim.N_CLAIM_SK_R = F_CLAIM_SOCIALSECURITY_INC_R_Claims.N_CLAIM_SK_R
            and F_CLAIM_SOCIALSECURITY_INC_R_Claims.n_claim_sk_r <> -1
			--left outer join (select * from fct_claim_payment_detail_r where n_claim_coverage_group_sk_r = -1) fct_claim_payment_detail_r
			-- FCT_BENEFIT_PAYMENT_DETAIL_R  F_BENEFIT_PAYMENT_DETAIL_R_Payments_Detail
						--on D_GRP_CLAIM_DIR_R_Claim.N_CLAIM_SK_R = fct_claim_payment_detail_r.N_CLAIM_SK_R
                       -- and case when fct_claim_payment_detail_r.n_claim_coverage_group_sk_r = -1 then D_GRP_CLAIM_COVERAGE_GROUP_R_Claims.n_claim_coverage_group_sk_r
                       -- else
                    --   and  fct_claim_payment_detail_r.n_claim_coverage_group_sk_r  = D_GRP_CLAIM_COVERAGE_GROUP_R_Claims.n_claim_coverage_group_sk_r

			 /* INNER JOIN
			  (SELECT DIM_TIME_r.*,
				N_DATE_SK_R*10000 N_DATE_SK_R_BATCH_ID
			  FROM DIM_TIME_r
			  ) DIM_TIME
			ON CAST(TRUNC(D_GRP_POLICY_DIR_R_Policy.T_EVENT_TIMESTAMP_R) AS DATE ) = CAST(TRUNC(DIM_TIME.D_CALENDAR_DATE_R) AS DATE )*/
WHERE
        1 = 1
    AND d_grp_policy_dir_r_policy.v_active_status_r = 'Y'
   -- and D_GRP_CLAIM_DIR_R_Claim.v_claim_number_r = '2023-01-19-0265-LTD-01'
			--AND  F_RPT_CLAIM_SUMMARY_R.d_cycle_date_r BETWEEN '01-JAN-2020' AND '31-JAN-2020'
			--and cast(D_GRP_POLICY_DIR_R_Policy.T_EVENT_TIMESTAMP_R as date) between '01-jan-2020' and '31-DEC-2020'
and D_GRP_CLAIM_DIR_R_Claim.v_lob_type_r in ('LTD', 'STD', 'VPL', 'VPS')
--and D_GRP_CLAIM_DIR_R_Claim.n_claim_sk_r = 285503;
GROUP BY
    d_grp_policy_dir_r_policy.n_policy_sk_r,
    d_grp_claim_dir_r_claim.n_claim_sk_r,

   D_GRP_CLAIM_DIR_R_Claim.v_claim_number_r,
				--  F_RPT_CLAIM_SUMMARY_R.d_cycle_date_r ,
			  ---Medical Diagnosis attributes start----
    d_grp_medical_diagnosis_r_claims.v_diagnosis_code_r,
    d_grp_medical_diagnosis_r_claims.v_diagnosis_desc_r,
    d_diagnosis_category_r.v_diag_category_desc_r,
    d_diagnosis_code_r.v_diag_category_code_r,
       case when
         -- CASE WHEN d_grp_claim_dir_r_claim.v_lob_type_r IN ( 'LIFE', 'NONS', 'WOP' ) THEN
            --D_GRP_CLAIM_COVERAGE_GROUP_R_Claims.d_date_closed_r
           -- WHEN d_grp_claim_dir_r_claim.v_lob_type_r IN ( 'LTD', 'STD', 'VPL', 'VPS' ) THEN
            d_grp_claim_detail_r_claim.d_closure_date_r
  --  END
    is null then null else trunc(         --   CASE
       -- WHEN d_grp_claim_dir_r_claim.v_lob_type_r IN ( 'LIFE', 'NONS', 'WOP' ) THEN
           -- D_GRP_CLAIM_COVERAGE_GROUP_R_Claims.d_date_closed_r
           -- WHEN d_grp_claim_dir_r_claim.v_lob_type_r IN ( 'LTD', 'STD', 'VPL', 'VPS' ) THEN
            d_grp_claim_detail_r_claim.d_closure_date_r
  --  END
    -     d_grp_busobj_audit_r.received_date          ) end ,
			--  D_GRP_MEDICAL_DIAGNOSIS_R_Claims_Additional.V_DIAGNOSIS_DESC_R ,
			--  D_GRP_MEDICAL_DIAGNOSIS_R_Claims_Additional.V_DIAGNOSIS_CODE_R ,
			--  D_DIAGNOSIS_CATEGORY_R_Additional.V_DIAG_CATEGORY_DESC_R       ,
			--  D_DIAGNOSIS_CATEGORY_R_Additional.V_DIAG_CATEGORY_CODE_R      ,

			  ---FCT_CLAIM_SOCIALSECURITY_INC_R attributes start--

    f_claim_socialsecurity_inc_r_claims.n_ss_primary_award_amount_r,
    f_claim_socialsecurity_inc_r_claims.v_ss_status_description_r,
    f_claim_socialsecurity_inc_r_claims.v_ss_primary_award_type_r,
    f_claim_socialsecurity_inc_r_claims.d_ss_primary_eff_date_r,
    f_claim_socialsecurity_inc_r_claims.d_ss_closed_term_date_r,
    f_claim_socialsecurity_inc_r_claims.n_ss_dep_award_amount_r,
    f_claim_socialsecurity_inc_r_claims.v_ss_dependent_status_r,
    f_claim_socialsecurity_inc_r_claims.v_ss_dep_award_type_r,
    f_claim_socialsecurity_inc_r_claims.d_ss_dep_award_eff_date_r,
    f_claim_socialsecurity_inc_r_claims.d_ss_dep_term_date_r

    union

    SELECT
    d_grp_policy_dir_r_policy.n_policy_sk_r                                                                 AS policy_skey,
    d_grp_claim_dir_r_claim.n_claim_sk_r                                                                    AS claim_skey,
    (
        SELECT
            MAX(fic_mis_date_r)
        FROM
            dim_grp_policy_dir_r
        WHERE
            v_source_system_name_r = 'PACS'
    )                                                                                                       AS as_of_date,
    d_grp_claim_coverage_group_r_claims.v_claim_identifier_r AS claim_identifier,
   -- MAX(f_rpt_claim_summary_r.d_cycle_date_r)
   cast (null  AS date)  AS ann_premium_cycle_date
    ,
              ---Medical Diagnosis attributes start----
    d_grp_medical_diagnosis_r_claims.v_diagnosis_code_r                                                     AS primary_diagnosis_code
    ,
    d_grp_medical_diagnosis_r_claims.v_diagnosis_desc_r                                                     AS primary_diagnosis_code_description
    ,
    d_diagnosis_category_r.v_diag_category_desc_r                                                           AS primary_diagnosis_category_description
    ,
    d_diagnosis_code_r.v_diag_category_code_r                                                               AS primary_diagnosis_category
    ,
            -- MAX( D_GRP_MEDICAL_DIAGNOSIS_R_Claims_Additional.V_DIAGNOSIS_DESC_R)
    LISTAGG(DISTINCT D_GRP_MEDICAL_DIAGNOSIS_R_Claims_Additional.v_diagnosis_desc_r, '; ')                            AS additional_diagnosis_code_description
    ,
            -- MAX( D_GRP_MEDICAL_DIAGNOSIS_R_Claims_Additional.V_DIAGNOSIS_CODE_R)
    LISTAGG(DISTINCT D_GRP_MEDICAL_DIAGNOSIS_R_Claims_Additional.v_diagnosis_code_r, '; ')                            AS additional_diagnosis_code
    ,
            /* MAX( D_DIAGNOSIS_CATEGORY_R_Additional.V_DIAG_CATEGORY_DESC_R    )   AS Additional_Diagnosis_Category_Description,
              MAX(D_DIAGNOSIS_CATEGORY_R_Additional.V_DIAG_CATEGORY_CODE_R     )  AS Additional_Diagnosis_Category */
              -- 13 March,2023, Commented the existing logic and added new logic as requested by Suhasini

    LISTAGG(DISTINCT d_diagnosis_category_r_additional.v_diag_category_desc_r, '; ')                        AS additional_diagnosis_category_description

    ,
    LISTAGG(DISTINCT d_diagnosis_category_r_additional.v_diag_category_code_r, '; ')                        AS additional_diagnosis_category

              ---Medical Diagnosis attributes End----
              ---Benifit Payment Attributes Start---
    ,
   /* SUM(
        CASE
            WHEN fct_claim_payment_detail_r.v_benefit_code_r = '088' THEN
                fct_claim_payment_detail_r.n_paid_amount_r
        END
    )                                                                                                       AS rehabilitation_offset_amount_088
    ,
    SUM(
        CASE
            WHEN fct_claim_payment_detail_r.v_benefit_code_r = '088' THEN
                fct_claim_payment_detail_r.n_paid_amount_r
        END
    )                                                                                                       AS workers_compensation_offset_amount_083
    ,
    SUM(
        CASE
            WHEN fct_claim_payment_detail_r.v_benefit_code_r IN('087', '08B', '090', '091', '186',
                                                                '188') THEN
                fct_claim_payment_detail_r.n_paid_amount_r
        END
    )                                                                                                       AS other_offset_amounts,
    MAX(
        CASE
            WHEN fct_claim_payment_detail_r.v_benefit_code_r = '088' THEN
                'Y'
            ELSE
                NULL
        END
    )                                                                                                       AS rehabilitation_offset_indicator_088
    ,
    MAX(
        CASE
            WHEN fct_claim_payment_detail_r.v_benefit_code_r = '188' THEN
                'Y'
            ELSE
                NULL
        END
    )                                                                                                       AS work_incentive_excess_offset_indicator_188*/
              ---Benifit Payment Attributes Ends---
           --  ,

            case when
         -- CASE WHEN d_grp_claim_dir_r_claim.v_lob_type_r IN ( 'LIFE', 'NONS', 'WOP' ) THEN
            D_GRP_CLAIM_COVERAGE_GROUP_R_Claims.d_date_closed_r
           -- WHEN d_grp_claim_dir_r_claim.v_lob_type_r IN ( 'LTD', 'STD', 'VPL', 'VPS' ) THEN
         --   d_grp_claim_detail_r_claim.d_closure_date_r
  --  END
    is null then null else trunc(         --   CASE
       -- WHEN d_grp_claim_dir_r_claim.v_lob_type_r IN ( 'LIFE', 'NONS', 'WOP' ) THEN
            D_GRP_CLAIM_COVERAGE_GROUP_R_Claims.d_date_closed_r
           -- WHEN d_grp_claim_dir_r_claim.v_lob_type_r IN ( 'LTD', 'STD', 'VPL', 'VPS' ) THEN
          --  d_grp_claim_detail_r_claim.d_closure_date_r
  --  END
    -     d_grp_busobj_audit_r.received_date          ) end    AS Claim_Age,
            1 -- max(F_RPT_CLAIM_SUMMARY_R.N_TOTAL_CLAIM_COUNT_R)
              AS Claim_Count,
              ---FCT_CLAIM_SOCIALSECURITY_INC_R attributes start--
              F_CLAIM_SOCIALSECURITY_INC_R_Claims.N_SS_PRIMARY_AWARD_AMOUNT_R AS Social_Security_Primary_Award_Amount,
              F_CLAIM_SOCIALSECURITY_INC_R_Claims.V_SS_STATUS_DESCRIPTION_R   AS Social_Security_Primary_Award_Status,
              F_CLAIM_SOCIALSECURITY_INC_R_Claims.V_SS_PRIMARY_AWARD_TYPE_R   AS Social_Security_Primary_Award_Type,
              F_CLAIM_SOCIALSECURITY_INC_R_Claims.D_SS_PRIMARY_EFF_DATE_R     AS Social_Security_Primary_Award_Effective_Date,
              F_CLAIM_SOCIALSECURITY_INC_R_Claims.D_SS_CLOSED_TERM_DATE_R     AS Social_Security_Primary_Award_Termination_Date,
              F_CLAIM_SOCIALSECURITY_INC_R_Claims.N_SS_DEP_AWARD_AMOUNT_R     AS Social_Security_Dependent_Award_Amount,
              F_CLAIM_SOCIALSECURITY_INC_R_Claims.V_SS_DEPENDENT_STATUS_R     AS Social_Security_Dependent_Award_Status,
              F_CLAIM_SOCIALSECURITY_INC_R_Claims.V_SS_DEP_AWARD_TYPE_R       AS Social_Security_Dependent_Award_Type,
              F_CLAIM_SOCIALSECURITY_INC_R_Claims.D_SS_DEP_AWARD_EFF_DATE_R   AS Social_Security_Dependent_Award_Effective_Date,
              F_CLAIM_SOCIALSECURITY_INC_R_Claims.D_SS_DEP_TERM_DATE_R        AS Social_Security_Dependent_Award_Termination_Date

--             CASE
--              WHEN D_GRP_POLICY_DIR_R_Policy.V_ORIG_LOB_R = 'VAI'
--              THEN D_GRP_CLAIM_EVENT_DIR_R_Claim.D_DATE_OF_EVENT_R +
--                    CASE
--                      WHEN D_GRP_CLAIM_ELIGIBILITY_R_Claims.N_ELIM_PERIOD_R <> ''
--                      OR D_GRP_CLAIM_ELIGIBILITY_R_Claims.N_ELIM_PERIOD_R   <> 0
--                      THEN D_GRP_CLAIM_ELIGIBILITY_R_Claims.N_ELIM_PERIOD_R
--                      else 0 end
--              else D_GRP_CLAIM_EVENT_DIR_R_Claim.D_DATE_OF_EVENT_R    end as Disability_Start_Date


        FROM

              DIM_GRP_POLICY_DIR_R D_GRP_POLICY_DIR_R_Policy /* D_GRP_POLICY_DIR_R_Policy */
              inner join DIM_GRP_CLAIM_DIR_R D_GRP_CLAIM_DIR_R_Claim   /* D_GRP_CLAIM_DIR_R_Claim */
              on D_GRP_POLICY_DIR_R_Policy.N_POLICY_SK_R = D_GRP_CLAIM_DIR_R_Claim.N_POLICY_SK_R
              AND D_GRP_CLAIM_DIR_R_Claim.V_ACTIVE_STATUS_R         = 'Y'
               LEFT OUTER JOIN (
                    SELECT
                        v_claim_number_r,
                        MAX(nvl(t374156.d_received_date_r,
                                TO_DATE(substr(t374156.v_claim_number_r, 1, 10),
                                        'YYYY-MM-DD'))) AS received_date
                    FROM
                        dim_grp_busobj_audit_r t374156
                    WHERE
                            v_active_status_r = 'Y'
                        AND v_claim_number_r NOT IN ( '-LIFE-01', '-LTD-01', '-STD-01', '-VPS-01', '-WOP-01' )
                    GROUP BY
                        v_claim_number_r
                )                              d_grp_busobj_audit_r ON d_grp_claim_dir_r_claim.v_claim_number_r = d_grp_busobj_audit_r.v_claim_number_r
              inner join DIM_GRP_CLAIM_DETAIL_R D_GRP_CLAIM_DETAIL_R_Claim /* D_GRP_CLAIM_DETAIL_R_Claim */
              on D_GRP_CLAIM_DETAIL_R_Claim.N_CLAIM_SK_R = D_GRP_CLAIM_DIR_R_Claim.N_CLAIM_SK_R and D_GRP_CLAIM_DETAIL_R_Claim.V_ACTIVE_STATUS_R = 'Y'
              inner join DIM_GRP_CLAIM_COVERAGE_R D_GRP_CLAIM_COVERAGE_R_Claims  /* D_GRP_CLAIM_COVERAGE_R_Claims */
              on D_GRP_CLAIM_DIR_R_Claim.N_CLAIM_SK_R = D_GRP_CLAIM_COVERAGE_R_Claims.N_CLAIM_SK_R and D_GRP_CLAIM_COVERAGE_R_Claims.V_ACTIVE_STATUS_R = 'Y'
              left outer join MVW_PRODUCT_SK_LOOKUP T439745 /* VW_PRODUCT_SK_LOOKUP_For_Disablity */
              On D_GRP_CLAIM_COVERAGE_R_Claims.N_CLAIM_SK_R = T439745.N_CLAIM_SK_R and D_GRP_CLAIM_COVERAGE_R_Claims.V_CLAIM_COVERAGE_CODE_R = T439745.V_CLAIM_COVERAGE_CODE_R
              LEFT OUTER JOIN DIM_GRP_PRODUCT_R D_GRP_PRODUCT_R_Claims_Disability  /* D_GRP_PRODUCT_R_Claims_Disability */
              On D_GRP_PRODUCT_R_Claims_Disability.N_PRODUCT_SK_R = T439745.N_PRODUCT_SK_R and D_GRP_PRODUCT_R_Claims_Disability.V_ACTIVE_STATUS_R = 'Y'
              inner join DIM_GRP_CLAIM_COVERAGE_GROUP_R D_GRP_CLAIM_COVERAGE_GROUP_R_Claims /* D_GRP_CLAIM_COVERAGE_GROUP_R_Claims */
              on D_GRP_CLAIM_COVERAGE_GROUP_R_Claims.N_CLAIM_COVERAGE_SK_R = D_GRP_CLAIM_COVERAGE_R_Claims.N_CLAIM_COVERAGE_SK_R
              and D_GRP_CLAIM_COVERAGE_GROUP_R_Claims.V_ACTIVE_STATUS_R = 'Y'
              left outer join MVW_PRODUCT_SK_LOOKUP T439747 /* VW_PRODUCT_SK_LOOKUP_For_Life */
              On D_GRP_CLAIM_COVERAGE_GROUP_R_Claims.N_CLAIM_SK_R = T439747.N_CLAIM_SK_R and D_GRP_CLAIM_COVERAGE_GROUP_R_Claims.V_CLAIM_COVERAGE_CODE_R = T439747.V_CLAIM_COVERAGE_CODE_R
              LEFT OUTER JOIN DIM_GRP_PRODUCT_R D_GRP_PRODUCT_R_Claims_Life  /* D_GRP_PRODUCT_R_Claims_Life */
              On D_GRP_PRODUCT_R_Claims_Life.N_PRODUCT_SK_R = T439747.N_PRODUCT_SK_R and D_GRP_PRODUCT_R_Claims_Life.V_ACTIVE_STATUS_R = 'Y'

        --  left outer join FCT_RPT_CLAIM_SUMMARY_R F_RPT_CLAIM_SUMMARY_R  /* F_RPT_CLAIM_SUMMARY_R */
         --   on D_GRP_CLAIM_DIR_R_Claim.V_CLAIM_NUMBER_R          = F_RPT_CLAIM_SUMMARY_R.V_CLAIM_NUMBER_R

--          LEFT OUTER JOIN DIM_GRP_CLAIM_ELIGIBILITY_R D_GRP_CLAIM_ELIGIBILITY_R_Claims  /* D_GRP_CLAIM_ELIGIBILITY_R_Claims */ ON D_GRP_CLAIM_DETAIL_R_Claim.N_CLAIM_SK_R = D_GRP_CLAIM_ELIGIBILITY_R_Claims.N_CLAIM_SK_R and D_GRP_CLAIM_ELIGIBILITY_R_Claims.V_ACTIVE_STATUS_R         = 'Y'

--          left outer join DIM_GRP_CLAIM_EVENT_R D_GRP_CLAIM_EVENT_R_Claim  /* D_GRP_CLAIM_EVENT_R_Claim */ on D_GRP_CLAIM_DETAIL_R_Claim.N_CLAIM_EVENT_SK_R  = D_GRP_CLAIM_EVENT_R_Claim.N_CLAIM_EVENT_SK_R and  D_GRP_CLAIM_EVENT_R_Claim.V_ACTIVE_STATUS_R         = 'Y'
--          left outer join DIM_GRP_CLAIM_EVENT_DIR_R D_GRP_CLAIM_EVENT_DIR_R_Claim  /* D_GRP_CLAIM_EVENT_DIR_R_Claim */ on D_GRP_CLAIM_EVENT_DIR_R_Claim.N_CLAIM_EVENT_SK_R        = D_GRP_CLAIM_EVENT_R_Claim.N_CLAIM_EVENT_SK_R  and D_GRP_CLAIM_EVENT_DIR_R_Claim.V_ACTIVE_STATUS_R         = 'Y'

            left outer join DIM_GRP_MEDICAL_DIAGNOSIS_R D_GRP_MEDICAL_DIAGNOSIS_R_Claims  /* D_GRP_MEDICAL_DIAGNOSIS_R_Claims */
            on  D_GRP_CLAIM_DIR_R_Claim.N_CLAIM_SK_R              = D_GRP_MEDICAL_DIAGNOSIS_R_Claims.N_CLAIM_SK_R
            AND D_GRP_MEDICAL_DIAGNOSIS_R_Claims.N_PRIMARY_IND_R           = 1
            AND D_GRP_MEDICAL_DIAGNOSIS_R_Claims.V_ACTIVE_STATUS_R         = 'Y'
            left outer join DIM_DIAGNOSIS_CODE_R D_DIAGNOSIS_CODE_R  /* D_DIAGNOSIS_CODE_R */
            on D_GRP_MEDICAL_DIAGNOSIS_R_Claims.V_DIAGNOSIS_CODE_R        = D_DIAGNOSIS_CODE_R.V_DIAG_CODE_R
            left outer join DIM_DIAGNOSIS_CATEGORY_R D_DIAGNOSIS_CATEGORY_R  /* D_DIAGNOSIS_CATEGORY_R */
            on D_DIAGNOSIS_CODE_R.V_DIAG_CATEGORY_CODE_R    = D_DIAGNOSIS_CATEGORY_R.V_DIAG_CATEGORY_CODE_R

            left outer join DIM_GRP_MEDICAL_DIAGNOSIS_R D_GRP_MEDICAL_DIAGNOSIS_R_Claims_Additional  /* D_GRP_MEDICAL_DIAGNOSIS_R_Claims_Additional */
            on D_GRP_CLAIM_DIR_R_Claim.N_CLAIM_SK_R = D_GRP_MEDICAL_DIAGNOSIS_R_Claims_Additional.N_CLAIM_SK_R
            AND D_GRP_MEDICAL_DIAGNOSIS_R_Claims_Additional.N_PRIMARY_IND_R = 0 AND D_GRP_MEDICAL_DIAGNOSIS_R_Claims_Additional.V_ACTIVE_STATUS_R ='Y'
            left outer join DIM_DIAGNOSIS_CODE_R D_DIAGNOSIS_CODE_R_Additional  /* D_DIAGNOSIS_CODE_R_Additional */
            on D_DIAGNOSIS_CODE_R_Additional.V_DIAG_CODE_R = D_GRP_MEDICAL_DIAGNOSIS_R_Claims_Additional.V_DIAGNOSIS_CODE_R
            left outer join DIM_DIAGNOSIS_CATEGORY_R D_DIAGNOSIS_CATEGORY_R_Additional  /* D_DIAGNOSIS_CATEGORY_R_Additional */
            on D_DIAGNOSIS_CATEGORY_R_Additional.V_DIAG_CATEGORY_CODE_R    = D_DIAGNOSIS_CODE_R_Additional.V_DIAG_CATEGORY_CODE_R

            left outer join FCT_CLAIM_SOCIALSECURITY_INC_R F_CLAIM_SOCIALSECURITY_INC_R_Claims  /* F_BENEFIT_PAYMENT_DETAIL_R_Payments_Detail */
            on D_GRP_CLAIM_DIR_R_Claim.N_CLAIM_SK_R = F_CLAIM_SOCIALSECURITY_INC_R_Claims.N_CLAIM_SK_R
          --  left outer join fct_claim_payment_detail_r fct_claim_payment_detail_r
            -- FCT_BENEFIT_PAYMENT_DETAIL_R  F_BENEFIT_PAYMENT_DETAIL_R_Payments_Detail
                  --      on D_GRP_CLAIM_DIR_R_Claim.N_CLAIM_SK_R = fct_claim_payment_detail_r.N_CLAIM_SK_R
                       -- and case when fct_claim_payment_detail_r.n_claim_coverage_group_sk_r = -1 then D_GRP_CLAIM_COVERAGE_GROUP_R_Claims.n_claim_coverage_group_sk_r
                       -- else
                    --   and  fct_claim_payment_detail_r.n_claim_coverage_group_sk_r  = D_GRP_CLAIM_COVERAGE_GROUP_R_Claims.n_claim_coverage_group_sk_r

             /* INNER JOIN
              (SELECT DIM_TIME_r.*,
                N_DATE_SK_R*10000 N_DATE_SK_R_BATCH_ID
              FROM DIM_TIME_r
              ) DIM_TIME
            ON CAST(TRUNC(D_GRP_POLICY_DIR_R_Policy.T_EVENT_TIMESTAMP_R) AS DATE ) = CAST(TRUNC(DIM_TIME.D_CALENDAR_DATE_R) AS DATE )*/
WHERE
        1 = 1
    AND d_grp_policy_dir_r_policy.v_active_status_r = 'Y'
 --   and D_GRP_CLAIM_DIR_R_Claim.v_claim_number_r = '2023-01-19-0265-LTD-01'
            --AND  F_RPT_CLAIM_SUMMARY_R.d_cycle_date_r BETWEEN '01-JAN-2020' AND '31-JAN-2020'
            --and cast(D_GRP_POLICY_DIR_R_Policy.T_EVENT_TIMESTAMP_R as date) between '01-jan-2020' and '31-DEC-2020'
and D_GRP_CLAIM_DIR_R_Claim.v_lob_type_r in ('LIFE', 'NONS', 'WOP')
--and D_GRP_CLAIM_DIR_R_Claim.n_claim_sk_r = 285503;
GROUP BY
    d_grp_policy_dir_r_policy.n_policy_sk_r,
    d_grp_claim_dir_r_claim.n_claim_sk_r,

   d_grp_claim_coverage_group_r_claims.v_claim_identifier_r,
                --  F_RPT_CLAIM_SUMMARY_R.d_cycle_date_r ,
              ---Medical Diagnosis attributes start----
    d_grp_medical_diagnosis_r_claims.v_diagnosis_code_r,
    d_grp_medical_diagnosis_r_claims.v_diagnosis_desc_r,
    d_diagnosis_category_r.v_diag_category_desc_r,
    d_diagnosis_code_r.v_diag_category_code_r,
       case when
         -- CASE WHEN d_grp_claim_dir_r_claim.v_lob_type_r IN ( 'LIFE', 'NONS', 'WOP' ) THEN
            D_GRP_CLAIM_COVERAGE_GROUP_R_Claims.d_date_closed_r
           -- WHEN d_grp_claim_dir_r_claim.v_lob_type_r IN ( 'LTD', 'STD', 'VPL', 'VPS' ) THEN
         --   d_grp_claim_detail_r_claim.d_closure_date_r
  --  END
    is null then null else trunc(         --   CASE
       -- WHEN d_grp_claim_dir_r_claim.v_lob_type_r IN ( 'LIFE', 'NONS', 'WOP' ) THEN
            D_GRP_CLAIM_COVERAGE_GROUP_R_Claims.d_date_closed_r
           -- WHEN d_grp_claim_dir_r_claim.v_lob_type_r IN ( 'LTD', 'STD', 'VPL', 'VPS' ) THEN
          --  d_grp_claim_detail_r_claim.d_closure_date_r
  --  END
    -     d_grp_busobj_audit_r.received_date          ) end ,
            --  D_GRP_MEDICAL_DIAGNOSIS_R_Claims_Additional.V_DIAGNOSIS_DESC_R ,
            --  D_GRP_MEDICAL_DIAGNOSIS_R_Claims_Additional.V_DIAGNOSIS_CODE_R ,
            --  D_DIAGNOSIS_CATEGORY_R_Additional.V_DIAG_CATEGORY_DESC_R       ,
            --  D_DIAGNOSIS_CATEGORY_R_Additional.V_DIAG_CATEGORY_CODE_R      ,

              ---FCT_CLAIM_SOCIALSECURITY_INC_R attributes start--

    f_claim_socialsecurity_inc_r_claims.n_ss_primary_award_amount_r,
    f_claim_socialsecurity_inc_r_claims.v_ss_status_description_r,
    f_claim_socialsecurity_inc_r_claims.v_ss_primary_award_type_r,
    f_claim_socialsecurity_inc_r_claims.d_ss_primary_eff_date_r,
    f_claim_socialsecurity_inc_r_claims.d_ss_closed_term_date_r,
    f_claim_socialsecurity_inc_r_claims.n_ss_dep_award_amount_r,
    f_claim_socialsecurity_inc_r_claims.v_ss_dependent_status_r,
    f_claim_socialsecurity_inc_r_claims.v_ss_dep_award_type_r,
    f_claim_socialsecurity_inc_r_claims.d_ss_dep_award_eff_date_r,
    f_claim_socialsecurity_inc_r_claims.d_ss_dep_term_date_r
	;
	UPDATE FCT_PROC_EXEC_STATUS_LOG_R
						SET V_STATUS_R                = 'Successful',
						T_EXECUTION_END_TIMESTAMP_R = systimestamp
						WHERE N_SERIAL_NUM_R          = N_MAX_SERIAL_NUM_R;
						COMMIT;
			EXCEPTION
			WHEN OTHERS THEN
				V_SQLCODE                    := SQLCODE;
						V_SQLERRM                    := SUBSTR(SYS.STANDARD.SQLERRM,1,500);
						UPDATE FCT_PROC_EXEC_STATUS_LOG_R
						SET V_STATUS_R                = 'Failed',
						T_EXECUTION_END_TIMESTAMP_R = systimestamp,
						V_ERROR_CODE_R				= V_SQLCODE,
						V_ERROR_DESC_R				= V_SQLERRM
						WHERE N_SERIAL_NUM_R          = N_MAX_SERIAL_NUM_R;
					COMMIT;
						RAISE;
			END;
		END IF;
		/*--17-Jun-2022 changes
		ln_mv_refresh_chk_cnt:=0;
		OPEN cur_mv_refresh_chk('PROC_REFRESH_GRP_M_VIEW_TBLS.F_PSR_CLAIM_MV_4');
		FETCH cur_mv_refresh_chk INTO ln_mv_refresh_chk_cnt;
		CLOSE cur_mv_refresh_chk;

		IF NVL(ln_mv_refresh_chk_cnt,0) =0 THEN */
		IF UPPER(TRIM(P_MV_TBL_NAME)) like  '%F_PSR_CLAIM_MV_4%' THEN --17-Jun-2022 changes

			Begin
			SELECT SEQ_FCT_PROC_EXEC_STATUS_LOG_R.NEXTVAL INTO N_MAX_SERIAL_NUM_R FROM DUAL;

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
				LN_BATCH_ID_R,--99999999,
				TO_CHAR(sysdate,'yyyymmdd'),
				1,
				'Started',
				SYSTIMESTAMP,
				USER,
				P_MV_TBL_NAME||'.PROC_REFRESH_GRP_M_VIEW_TBLS.F_PSR_CLAIM_MV_4_TBL',
				N_MAX_SERIAL_NUM_R
				);
			commit;
			 --24-Jan-2023 changes start
			 -- commented and added on 21/04/2022
			 --dbms_mview.refresh('F_PSR_CLAIM_MV_4', method => 'C', atomic_refresh => FALSE);
			 EXECUTE IMMEDIATE 'TRUNCATE TABLE F_PSR_CLAIM_MV_4_TBL PURGE SNAPSHOT LOG';
			INSERT
			  /*+APPEND_VALUES*/
			INTO F_PSR_CLAIM_MV_4_TBL
			  (
				N_POLICY_SK_R                              ,
                N_CLAIM_SK_R                               ,
                V_CLAIM_NUMBER_R                           ,
                N_CLAIM_COVERAGE_GROUP_SK_R                ,
                V_CLAIM_IDENTIFIER_R                       ,
                CLAIM_TOTAL_PAID_NET_AMOUNT                ,
                CLAIM_TOTAL_PAID_TAXABLE_AMOUNT            ,
                REHABILITATION_OFFSET_AMOUNT_088           ,
                WORKERS_COMPENSATION_OFFSET_AMOUNT_083     ,
                OTHER_OFFSET_AMOUNTS                       ,
                REHABILITATION_OFFSET_INDICATOR_088        ,
                ACH_INDICATOR                              ,
                LAST_BENEFIT_PAYMENT_DATE                  ,
                V_COV_GROUP_ID_R                           ,
                EARLIEST_BENEFIT_PAYMENT_DATE              ,
                MOST_RECENT_SERVICE_PERIOD_TO_DATE         ,
                MOST_RECENT_SERVICE_PERIOD_FROM_DATE       ,
                WORK_INCENTIVE_EXCESS_OFFSET_INDICATOR_188 ,
                CLAIM_TOTAL_PAID_LOSS_AMOUNT               ,
                CLAIM_MODAL_AMOUNT
			  )
				SELECT
            *
            FROM
              (
              WITH F_BENEFIT_PAYMENT_R AS
              (SELECT
              n_claim_sk_r AS claim_skey,
                max(ACH_INDICATOR) ACH_INDICATOR
             --   MAX(MOST_RECENT_SERVICE_PERIOD_FROM_DATE) AS MOST_RECENT_SERVICE_PERIOD_FROM_DATE,
           --     MAX(MOST_RECENT_SERVICE_PERIOD_TO_DATE)   AS MOST_RECENT_SERVICE_PERIOD_TO_DATE,
             --   MIN(D_DISB_DATE_R)                        AS Earliest_benefit_payment_date
              FROM
                ( SELECT
                DISTINCT cd.n_claim_sk_r n_claim_sk_r,
                  CASE
                    WHEN upper(T334051.V_PAY_METHOD_R) = 'ACH'
                    THEN 'Y'
                    ELSE 'N'
                  END AS ACH_indicator

                FROM FCT_BENEFIT_PAYMENT_R T334051,
                  DIM_GRP_POLICY_DIR_R T333136,
                  dim_grp_claim_dir_r cd
                WHERE T333136.N_POLICY_SK_R           = T334051.N_POLICY_SK_R
              --  AND T333136.N_POLICY_VERSION_NUMBER_R = T334051.N_VERSION_NUMBER_R
                AND T333136.V_ACTIVE_STATUS_R         ='Y'
                and cd.n_claim_sk_r = T334051.n_claim_sk_r
                and cd.n_policy_sk_r = T333136.N_policy_sk_r
                and cd.v_active_status_r = 'Y'
                and cd.v_lob_type_r in ('LTD', 'STD', 'VPS', 'VPL')
                  /*and  T334051.d_payment_date_r between '01-jan-2016' and '31-dec-2021'*/
                  --Commented by Gireesh
                )
              GROUP BY n_claim_sk_r
              --  ACH_INDICATOR
              )
       --   select * from F_BENEFIT_PAYMENT_R    );
          ,
              F_CLAIM_PAYMENT_DETAIL_R AS
              (SELECT
              N_POLICY_SK_R AS POLICY_SKEY,
                V_CLAIM_NUMBER_R CLAIM_NUMBER,
                n_claim_sk_r claim_skey,
             --   n_claim_coverage_group_sk_r,
                CLAIM_TOTAL_PAID_NET_AMOUNT,
                  CLAIM_TOTAL_PAID_TAXABLE_AMOUNT,
                     CLAIM_TOTAL_PAID_LOSS_AMOUNT,
                rehabilitation_offset_amount_088,
                workers_compensation_offset_amount_083,
                other_offset_amounts,
                rehabilitation_offset_indicator_088,
                work_incentive_excess_offset_indicator_188

              FROM
                (SELECT
                T333136.N_POLICY_SK_R,
                  T333511.V_CLAIM_NUMBER_R,
                  T333511.N_CLAIM_SK_R,
               --   T425786.n_claim_coverage_group_sk_r,
                           sum(case  when upper(T425786.V_RECORD_TYPE_R) = 'REDIRECT'
                           then nvl(T425786.N_PAID_AMOUNT_R , 0) when T425786.V_CHECK_TYPE_R not in ('OE') and upper(T425786.V_RECORD_TYPE_R) = 'BENEFIT PAYMENT'
                           and T425786.V_BENEFIT_GROUP_R in ('FIC', 'MED') then nvl(T425786.N_PAID_CLAIM_BENEFITS_R , 0) * -1 when T425786.V_CHECK_TYPE_R not in ('OE')
                           and upper(T425786.V_RECORD_TYPE_R) = 'ADJUSTMENT' and T425786.V_BENEFIT_GROUP_R in ('FIC', 'MED') then nvl(T425786.N_PAID_CLAIM_BENEFITS_R , 0)
                           when T425786.V_CHECK_TYPE_R not in ('OE') and not T425786.V_BENEFIT_GROUP_R in ('FIC', 'MED') then nvl(T425786.N_PAID_CLAIM_BENEFITS_R , 0) else 0 end )
                           AS Claim_total_paid_loss_amount ,
                    sum(case  when T425786.V_CHECK_TYPE_R not in ('OE') and not T425786.V_BENEFIT_GROUP_R in ('FIC', 'MED') then T425786.N_PAID_AMOUNT_R else 0 end )
                    AS CLAIM_TOTAL_PAID_NET_AMOUNT,
                   sum(case  when T425786.V_CHECK_TYPE_R not in ('OE') and not T425786.V_BENEFIT_GROUP_R in ('FIC', 'MED') then T425786.N_PAID_AMOUNT_R else 0 end ) AS CLAIM_TOTAL_PAID_TAXABLE_AMOUNT,
                     max(  case  WHEN T425786.v_benefit_code_r = '188' THEN
               'Y'
            ELSE
                NULL
        END)as work_incentive_excess_offset_indicator_188,

    SUM(
       CASE
            WHEN T425786.v_benefit_code_r = '088' THEN
                T425786.n_paid_amount_r
                else 0
        END
    )                                                                                                       AS rehabilitation_offset_amount_088
    ,
    SUM(
        CASE
            WHEN T425786.v_benefit_code_r = '083' THEN
                T425786.n_paid_amount_r
                else 0
        END
   )                                                                                                       AS workers_compensation_offset_amount_083
  ,
    SUM(
        CASE
          WHEN T425786.v_benefit_code_r IN('087', '08B', '090', '091', '186',
                                                                '188') THEN
                T425786.n_paid_amount_r
                else 0
        END
    )                                                                                                       AS other_offset_amounts,
    MAX(
        CASE
            WHEN T425786.v_benefit_code_r = '088' THEN
               'Y'
            ELSE
                null
        END
    )                                                                                                       AS rehabilitation_offset_indicator_088
                  -- SUM(T425786.N_PAID_AMOUNT_R) AS CLAIM_TOTAL_PAID_AMOUNT
                FROM (SELECT * FROM FCT_CLAIM_PAYMENT_DETAIL_R WHERE n_claim_coverage_group_sk_r = -1) T425786,
                  DIM_GRP_POLICY_DIR_R T333136
                  /* D_GRP_POLICY_DIR_R_Policy */
                  ,
                  DIM_GRP_CLAIM_DIR_R T333511
                WHERE T333136.N_POLICY_SK_R   = T333511.N_POLICY_SK_R
                AND T333511.V_CLAIM_NUMBER_R  = T425786.V_CLAIM_NUMBER_R
                AND T333136.V_ACTIVE_STATUS_R ='Y'
                AND T333511.V_ACTIVE_STATUS_R ='Y'
                and T333511.v_lob_type_r in  ('LTD', 'STD', 'VPS', 'VPL')
                  /*and T425786.d_paid_date_r between '01-jan-2016' and '31-dec-2021'*/
                  --Commented by Gireesh
                  --and T425786.FIC_MIS_DATE_R ='11-AUG-21'
                GROUP BY T333136.N_POLICY_SK_R,
                  T333511.V_CLAIM_NUMBER_R,
        --   T425786.n_claim_coverage_group_sk_r,
                  --T425786.V_CHECK_TYPE_R ,
                  --T425786.V_BENEFIT_GROUP_R,
                  T333511.n_claim_sk_r
                )
             -- GROUP BY N_POLICY_SK_R,
              --  V_CLAIM_NUMBER_R ,
              --  n_claim_sk_r,
              --  n_claim_coverage_group_sk_r
              ),

                --   select * from F_CLAIM_PAYMENT_DETAIL_R    );,
              F_GRP_WORKSHEET AS
              (SELECT
              T333511.V_CLAIM_NUMBER_R,
                SUM(T357789.N_GROSS_BENEFIT_R) AS CLAIM_TOTAL_PAID_GROSS_AMT,
                SUM(T357789.N_MODAL_AMOUNT_R)  AS Claim_modal_amount--,
              --  T357774.n_claim_coverage_group_sk_r

              FROM DIM_GRP_CLAIM_DIR_R T333511,
                DIM_GRP_CLAIM_COVERAGE_R T357788
                /* D_GRP_CLAIM_COVERAGE_R_Claims */
             --   ,
             --   DIM_GRP_CLAIM_COVERAGE_GROUP_R T357774
                /* D_GRP_CLAIM_COVERAGE_GROUP_R_Claims */
                ,
                FCT_GRP_WORKSHEET T357789
              WHERE T333511.N_CLAIM_SK_R        = T357788.N_CLAIM_SK_R
          --    AND T357774.N_CLAIM_COVERAGE_SK_R = T357788.N_CLAIM_COVERAGE_SK_R
              AND T357788.N_CLAIM_COVERAGE_SK_R = T357789.N_CLAIM_COVERAGE_SK_R
           --   and T357789.n_claim_coverage_group_sk_r = T357774.n_claim_coverage_group_sk_r
              AND T333511.V_ACTIVE_STATUS_R     ='Y'
              AND T357788.V_ACTIVE_STATUS_R     ='Y'
            --  AND T357774.V_ACTIVE_STATUS_R     ='Y'
              and T333511.v_lob_type_r in ('LTD', 'STD', 'VPL', 'VPS')
              GROUP BY T333511.V_CLAIM_NUMBER_R--,
              --T357774.n_claim_coverage_group_sk_r
              )--select * from F_GRP_WORKSHEET);

              ,
              payment_dates as   (
    SELECT v_claim_number_r,
   -- N_CLAIM_COVERAGE_GROUP_SK_R,
    V_COV_GROUP_ID_R,
    MAX(d_paid_date_r) last_benefit_payment_date,
     min(d_paid_date_r) Earliest_benefit_payment_date,
     max(D_SERVICE_PERIOD_TO_R) MOST_RECENT_SERVICE_PERIOD_TO_DATE,
     max(D_SERVICE_PERIOD_FROM_R) MOST_RECENT_SERVICE_PERIOD_FROM_DATE
  FROM
    (SELECT a.v_claim_number_r,
      d_paid_date_r,
      N_SOURCE_VERSION_SEQ_NUMBER_R,
      SUM(N_PAID_AMOUNT_R),
     -- N_CLAIM_COVERAGE_GROUP_SK_R,
      V_COV_GROUP_ID_R,
      D_SERVICE_PERIOD_FROM_R,
      D_SERVICE_PERIOD_TO_R
    FROM fct_claim_payment_detail_r a, dim_grp_claim_dir_r b
    WHERE V_CHECK_TYPE_R      <> 'OE'
    AND V_BENEFIT_GROUP_R NOT IN ('FIC', 'MED')
 --   and a.v_lob_type_r in ('LTD', 'STD', 'VPL', 'VPS')
    and a.n_claim_sk_r = b.n_claim_sk_r
    and b.v_active_status_r = 'Y'
    and b.v_lob_type_r in ('LTD', 'STD', 'VPL', 'VPS')
    GROUP BY a.v_claim_number_r,
      d_paid_date_r,
      N_SOURCE_VERSION_SEQ_NUMBER_R,
    --  N_CLAIM_COVERAGE_GROUP_SK_R,
      V_COV_GROUP_ID_R,
            D_SERVICE_PERIOD_FROM_R,
      D_SERVICE_PERIOD_TO_R
    HAVING SUM(N_PAID_AMOUNT_R) >0
    )
  GROUP BY v_claim_number_r,
  --  N_CLAIM_COVERAGE_GROUP_SK_R,
    V_COV_GROUP_ID_R)-- select * from payment_dates);
   -- select * from F_CLAIM_PAYMENT_DETAIL_R    );
   -- select * from CLAIM_TOTAL_PAID_LOSS_AMOUNT);
            SELECT
            DIM_GRP_POLICY_DIR_R.N_POLICY_SK_R,
              DIM_GRP_CLAIM_DIR_R.n_claim_sk_r,
              DIM_GRP_CLAIM_DIR_R.v_claim_number_r,
             -- F_CLAIM_PAYMENT_DETAIL_R.N_CLAIM_COVERAGE_GROUP_SK_R,
             -1 N_CLAIM_COVERAGE_GROUP_SK_R,
             DIM_GRP_CLAIM_DIR_R.v_claim_number_r V_CLAIM_IDENTIFIER_R,
              CLAIM_TOTAL_PAID_NET_AMOUNT,
              CLAIM_TOTAL_PAID_TAXABLE_AMOUNT,
              REHABILITATION_OFFSET_AMOUNT_088,
              WORKERS_COMPENSATION_OFFSET_AMOUNT_083,
              OTHER_OFFSET_AMOUNTS,
              REHABILITATION_OFFSET_INDICATOR_088,
              ACH_INDICATOR,
              LAST_BENEFIT_PAYMENT_DATE,
              V_COV_GROUP_ID_R,

              EARLIEST_BENEFIT_PAYMENT_DATE,
              MOST_RECENT_SERVICE_PERIOD_TO_DATE,
              MOST_RECENT_SERVICE_PERIOD_FROM_DATE,
              work_incentive_excess_offset_indicator_188,
              CLAIM_TOTAL_PAID_LOSS_AMOUNT,
              Claim_modal_amount

            FROM
             F_CLAIM_PAYMENT_DETAIL_R F_CLAIM_PAYMENT_DETAIL_R
        --    ON DIM_GRP_CLAIM_DIR_R.N_CLAIM_SK_R = F_CLAIM_PAYMENT_DETAIL_R.CLAIM_SKEY
             inner  JOIN DIM_GRP_CLAIM_DIR_R DIM_GRP_CLAIM_DIR_R
 ON DIM_GRP_CLAIM_DIR_R.N_CLAIM_SK_R = F_CLAIM_PAYMENT_DETAIL_R.CLAIM_SKEY
           inner join  DIM_GRP_POLICY_DIR_R DIM_GRP_POLICY_DIR_R
                       ON DIM_GRP_POLICY_DIR_R.N_POLICY_SK_R = DIM_GRP_CLAIM_DIR_R.N_POLICY_SK_r
            inner JOIN FCT_GRP_POLICY_R FCT_GRP_POLICY_R
            ON DIM_GRP_POLICY_DIR_R.N_POLICY_SK_R              = FCT_GRP_POLICY_R.N_POLICY_SK_R
            AND DIM_GRP_POLICY_DIR_R.N_POLICY_VERSION_NUMBER_R = FCT_GRP_POLICY_R.N_VERSION_NUMBER_R
            LEFT OUTER JOIN F_BENEFIT_PAYMENT_R F_BENEFIT_PAYMENT_R
            ON DIM_GRP_CLAIM_DIR_R.n_claim_sk_r = F_BENEFIT_PAYMENT_R.claim_skey

            LEFT OUTER JOIN F_GRP_WORKSHEET F_GRP_WORKSHEET
            ON DIM_GRP_CLAIM_DIR_R.v_claim_number_r     = F_GRP_WORKSHEET.v_claim_number_r
        --    and F_GRP_WORKSHEET.n_claim_coverage_group_sk_r = F_CLAIM_PAYMENT_DETAIL_R.n_claim_coverage_group_sk_r
            left outer join payment_dates
            on payment_dates.v_claim_number_r =F_CLAIM_PAYMENT_DETAIL_R.CLAIM_NUMBER
            WHERE DIM_GRP_CLAIM_DIR_R.V_ACTIVE_STATUS_R ='Y'
            AND DIM_GRP_POLICY_DIR_R.V_ACTIVE_STATUS_R  ='Y'
            and DIM_GRP_CLAIM_DIR_R.v_lob_type_r in ('LTD', 'STD', 'VPL', 'VPS'))
       --     and DIM_GRP_CLAIM_DIR_R.v_claim_number_r = '2021-10-08-0164-GL-01')
         UNION

         SELECT
            *
            FROM
              (
              WITH F_BENEFIT_PAYMENT_R AS
              (SELECT
              n_claim_sk_r AS claim_skey,
                max(ACH_INDICATOR) ACH_INDICATOR
             --   MAX(MOST_RECENT_SERVICE_PERIOD_FROM_DATE) AS MOST_RECENT_SERVICE_PERIOD_FROM_DATE,
           --     MAX(MOST_RECENT_SERVICE_PERIOD_TO_DATE)   AS MOST_RECENT_SERVICE_PERIOD_TO_DATE,
             --   MIN(D_DISB_DATE_R)                        AS Earliest_benefit_payment_date
              FROM
                ( SELECT
                DISTINCT cd.n_claim_sk_r n_claim_sk_r,
                  CASE
                    WHEN upper(T334051.V_PAY_METHOD_R) = 'ACH'
                    THEN 'Y'
                    ELSE 'N'
                  END AS ACH_indicator

                FROM FCT_BENEFIT_PAYMENT_R T334051,
                  DIM_GRP_POLICY_DIR_R T333136,
                  dim_grp_claim_dir_r cd
                WHERE T333136.N_POLICY_SK_R           = T334051.N_POLICY_SK_R
           --     AND T333136.N_POLICY_VERSION_NUMBER_R = T334051.N_VERSION_NUMBER_R
                AND T333136.V_ACTIVE_STATUS_R         ='Y'
                and cd.n_claim_sk_r = T334051.n_claim_sk_r
                and cd.n_policy_sk_r = T333136.N_policy_sk_r
                and cd.v_active_status_r = 'Y'
                and cd.v_lob_type_r in ('LIFE', 'NONS', 'LTD')
                  /*and  T334051.d_payment_date_r between '01-jan-2016' and '31-dec-2021'*/
                  --Commented by Gireesh
                )
              GROUP BY n_claim_sk_r
              --  ACH_INDICATOR
              )
       --   select * from F_BENEFIT_PAYMENT_R    );
          ,
              F_CLAIM_PAYMENT_DETAIL_R AS
              (SELECT
              N_POLICY_SK_R AS POLICY_SKEY,
                V_CLAIM_NUMBER_R CLAIM_NUMBER,
                n_claim_sk_r claim_skey,
                n_claim_coverage_group_sk_r,
                CLAIM_TOTAL_PAID_NET_AMOUNT,
                  CLAIM_TOTAL_PAID_TAXABLE_AMOUNT,
                     CLAIM_TOTAL_PAID_LOSS_AMOUNT,
                rehabilitation_offset_amount_088,
                workers_compensation_offset_amount_083,
                other_offset_amounts,
                rehabilitation_offset_indicator_088,
                V_CLAIM_IDENTIFIER_R,
                work_incentive_excess_offset_indicator_188

              FROM
                (SELECT
                T333136.N_POLICY_SK_R,
                  T333511.V_CLAIM_NUMBER_R,
                  T333511.N_CLAIM_SK_R,
                  T425786.n_claim_coverage_group_sk_r,
                           sum(case  when upper(T425786.V_RECORD_TYPE_R) = 'REDIRECT'
                           then nvl(T425786.N_PAID_AMOUNT_R , 0) when T425786.V_CHECK_TYPE_R not in ('OE') and upper(T425786.V_RECORD_TYPE_R) = 'BENEFIT PAYMENT'
                           and T425786.V_BENEFIT_GROUP_R in ('FIC', 'MED') then nvl(T425786.N_PAID_CLAIM_BENEFITS_R , 0) * -1 when T425786.V_CHECK_TYPE_R not in ('OE')
                           and upper(T425786.V_RECORD_TYPE_R) = 'ADJUSTMENT' and T425786.V_BENEFIT_GROUP_R in ('FIC', 'MED') then nvl(T425786.N_PAID_CLAIM_BENEFITS_R , 0)
                           when T425786.V_CHECK_TYPE_R not in ('OE') and not T425786.V_BENEFIT_GROUP_R in ('FIC', 'MED') then nvl(T425786.N_PAID_CLAIM_BENEFITS_R , 0) else 0 end )
                           AS Claim_total_paid_loss_amount ,
                    sum(case  when T425786.V_CHECK_TYPE_R not in ('OE') and not T425786.V_BENEFIT_GROUP_R in ('FIC', 'MED') then T425786.N_PAID_AMOUNT_R else 0 end )
                    AS CLAIM_TOTAL_PAID_NET_AMOUNT,
                   sum(case  when T425786.V_CHECK_TYPE_R not in ('OE') and not T425786.V_BENEFIT_GROUP_R in ('FIC', 'MED') then T425786.N_PAID_AMOUNT_R else 0 end ) AS CLAIM_TOTAL_PAID_TAXABLE_AMOUNT,
                     max(  case  WHEN T425786.v_benefit_code_r = '188' THEN
               'Y'
            ELSE
                NULL
        END)as work_incentive_excess_offset_indicator_188,

    SUM(
       CASE
            WHEN T425786.v_benefit_code_r = '088' THEN
                T425786.n_paid_amount_r
                else 0
        END
    )                                                                                                       AS rehabilitation_offset_amount_088
    ,
    SUM(
        CASE
            WHEN T425786.v_benefit_code_r = '083' THEN
                T425786.n_paid_amount_r
                else 0
        END
   )                                                                                                       AS workers_compensation_offset_amount_083
  ,
    SUM(
        CASE
          WHEN T425786.v_benefit_code_r IN('087', '08B', '090', '091', '186',
                                                                '188') THEN
                T425786.n_paid_amount_r
                else 0
        END
    )                                                                                                       AS other_offset_amounts,
    MAX(
        CASE
            WHEN T425786.v_benefit_code_r = '088' THEN
               'Y'
            ELSE
                null
        END
    )                                                                                                       AS rehabilitation_offset_indicator_088,
                  -- SUM(T425786.N_PAID_AMOUNT_R) AS CLAIM_TOTAL_PAID_AMOUNT

                                    CG.V_CLAIM_IDENTIFIER_R AS V_CLAIM_IDENTIFIER_R
                FROM FCT_CLAIM_PAYMENT_DETAIL_R T425786,
                  DIM_GRP_POLICY_DIR_R T333136
                  /* D_GRP_POLICY_DIR_R_Policy */
                  ,
                  DIM_GRP_CLAIM_DIR_R T333511
                  ,
                  DIM_GRP_CLAIM_COVERAGE_GROUP_R CG
                WHERE T333136.N_POLICY_SK_R   = T333511.N_POLICY_SK_R
                AND T333511.V_CLAIM_NUMBER_R  = T425786.V_CLAIM_NUMBER_R
                AND T333136.V_ACTIVE_STATUS_R ='Y'
                AND T333511.V_ACTIVE_STATUS_R ='Y'
                and T333511.v_lob_type_r in ('WOP', 'NONS', 'LIFE')
                AND CG.N_CLAIM_COVERAGE_GROUP_SK_R = T425786.N_CLAIM_COVERAGE_GROUP_SK_R
                AND CG.N_CLAIM_SK_R = T425786.N_CLAIM_SK_R
                AND CG.V_ACTIVE_STATUS_R = 'Y'
                  /*and T425786.d_paid_date_r between '01-jan-2016' and '31-dec-2021'*/
                  --Commented by Gireesh
                  --and T425786.FIC_MIS_DATE_R ='11-AUG-21'
                GROUP BY T333136.N_POLICY_SK_R,
                  T333511.V_CLAIM_NUMBER_R,
                  T425786.n_claim_coverage_group_sk_r,
                  --T425786.V_CHECK_TYPE_R ,
                  --T425786.V_BENEFIT_GROUP_R,
                  CG.V_CLAIM_IDENTIFIER_R,
                  T333511.n_claim_sk_r
                )
             -- GROUP BY N_POLICY_SK_R,
              --  V_CLAIM_NUMBER_R ,
              --  n_claim_sk_r,
              --  n_claim_coverage_group_sk_r
              ),

                --   select * from F_CLAIM_PAYMENT_DETAIL_R    );,
              F_GRP_WORKSHEET AS
              (SELECT
              T333511.V_CLAIM_NUMBER_R,
                SUM(T357789.N_GROSS_BENEFIT_R) AS CLAIM_TOTAL_PAID_GROSS_AMT,
                SUM(T357789.N_MODAL_AMOUNT_R)  AS Claim_modal_amount,
                T357774.n_claim_coverage_group_sk_r

              FROM DIM_GRP_CLAIM_DIR_R T333511,
                DIM_GRP_CLAIM_COVERAGE_R T357788
                /* D_GRP_CLAIM_COVERAGE_R_Claims */
                ,
                DIM_GRP_CLAIM_COVERAGE_GROUP_R T357774
                /* D_GRP_CLAIM_COVERAGE_GROUP_R_Claims */
                ,
                FCT_GRP_WORKSHEET T357789
              WHERE T333511.N_CLAIM_SK_R        = T357788.N_CLAIM_SK_R
              AND T357774.N_CLAIM_COVERAGE_SK_R = T357788.N_CLAIM_COVERAGE_SK_R
              AND T357788.N_CLAIM_COVERAGE_SK_R = T357789.N_CLAIM_COVERAGE_SK_R
              and T357789.n_claim_coverage_group_sk_r = T357774.n_claim_coverage_group_sk_r
              AND T333511.V_ACTIVE_STATUS_R     ='Y'
              AND T357788.V_ACTIVE_STATUS_R     ='Y'
              AND T357774.V_ACTIVE_STATUS_R     ='Y'
              and T333511.v_lob_type_r in ('NONS', 'WOP', 'LIFE')
              GROUP BY T333511.V_CLAIM_NUMBER_R,T357774.n_claim_coverage_group_sk_r
              )--select * from F_GRP_WORKSHEET);

              ,
              payment_dates as   (
    SELECT v_claim_number_r,
    N_CLAIM_COVERAGE_GROUP_SK_R,
    V_COV_GROUP_ID_R,
    MAX(d_paid_date_r) last_benefit_payment_date,
     min(d_paid_date_r) Earliest_benefit_payment_date,
     max(D_SERVICE_PERIOD_TO_R) MOST_RECENT_SERVICE_PERIOD_TO_DATE,
     max(D_SERVICE_PERIOD_FROM_R) MOST_RECENT_SERVICE_PERIOD_FROM_DATE
  FROM
    (SELECT a.v_claim_number_r,
      d_paid_date_r,
      N_SOURCE_VERSION_SEQ_NUMBER_R,
      SUM(N_PAID_AMOUNT_R),
      N_CLAIM_COVERAGE_GROUP_SK_R,
      V_COV_GROUP_ID_R,
      D_SERVICE_PERIOD_FROM_R,
      D_SERVICE_PERIOD_TO_R
    FROM fct_claim_payment_detail_r a, dim_grp_claim_dir_r b
    WHERE V_CHECK_TYPE_R      <> 'OE'
    AND V_BENEFIT_GROUP_R NOT IN ('FIC', 'MED')
    and a.v_lob_type_r in ('LIFE', 'NONS', 'WOP')
    and a.n_claim_sk_r = b.n_claim_sk_r
    and b.v_active_status_r = 'Y'
    and b.v_lob_type_r in ('LIFE', 'NONS', 'WOP')
    GROUP BY a.v_claim_number_r,
      d_paid_date_r,
      N_SOURCE_VERSION_SEQ_NUMBER_R,
      N_CLAIM_COVERAGE_GROUP_SK_R,
      V_COV_GROUP_ID_R,
            D_SERVICE_PERIOD_FROM_R,
      D_SERVICE_PERIOD_TO_R
    HAVING SUM(N_PAID_AMOUNT_R) >0
    )
  GROUP BY v_claim_number_r,
    N_CLAIM_COVERAGE_GROUP_SK_R,
    V_COV_GROUP_ID_R)-- select * from payment_dates);
   -- select * from F_CLAIM_PAYMENT_DETAIL_R    );
   -- select * from CLAIM_TOTAL_PAID_LOSS_AMOUNT);
            SELECT
            DIM_GRP_POLICY_DIR_R.N_POLICY_SK_R,
              DIM_GRP_CLAIM_DIR_R.n_claim_sk_r,
              DIM_GRP_CLAIM_DIR_R.v_claim_number_r,
              F_CLAIM_PAYMENT_DETAIL_R.N_CLAIM_COVERAGE_GROUP_SK_R,
              V_CLAIM_IDENTIFIER_R,
              CLAIM_TOTAL_PAID_NET_AMOUNT,
              CLAIM_TOTAL_PAID_TAXABLE_AMOUNT,
              REHABILITATION_OFFSET_AMOUNT_088,
              WORKERS_COMPENSATION_OFFSET_AMOUNT_083,
              OTHER_OFFSET_AMOUNTS,
              REHABILITATION_OFFSET_INDICATOR_088,
              ACH_INDICATOR,
              LAST_BENEFIT_PAYMENT_DATE,
              V_COV_GROUP_ID_R,

              EARLIEST_BENEFIT_PAYMENT_DATE,
              MOST_RECENT_SERVICE_PERIOD_TO_DATE,
              MOST_RECENT_SERVICE_PERIOD_FROM_DATE,
              work_incentive_excess_offset_indicator_188,
              CLAIM_TOTAL_PAID_LOSS_AMOUNT,
              Claim_modal_amount


            FROM
             F_CLAIM_PAYMENT_DETAIL_R F_CLAIM_PAYMENT_DETAIL_R
        --    ON DIM_GRP_CLAIM_DIR_R.N_CLAIM_SK_R = F_CLAIM_PAYMENT_DETAIL_R.CLAIM_SKEY
             inner  JOIN DIM_GRP_CLAIM_DIR_R DIM_GRP_CLAIM_DIR_R
 ON DIM_GRP_CLAIM_DIR_R.N_CLAIM_SK_R = F_CLAIM_PAYMENT_DETAIL_R.CLAIM_SKEY
           inner join  DIM_GRP_POLICY_DIR_R DIM_GRP_POLICY_DIR_R
                       ON DIM_GRP_POLICY_DIR_R.N_POLICY_SK_R = DIM_GRP_CLAIM_DIR_R.N_POLICY_SK_r
            inner JOIN FCT_GRP_POLICY_R FCT_GRP_POLICY_R
            ON DIM_GRP_POLICY_DIR_R.N_POLICY_SK_R              = FCT_GRP_POLICY_R.N_POLICY_SK_R
            AND DIM_GRP_POLICY_DIR_R.N_POLICY_VERSION_NUMBER_R = FCT_GRP_POLICY_R.N_VERSION_NUMBER_R
            LEFT OUTER JOIN F_BENEFIT_PAYMENT_R F_BENEFIT_PAYMENT_R
            ON DIM_GRP_CLAIM_DIR_R.n_claim_sk_r = F_BENEFIT_PAYMENT_R.claim_skey

            LEFT OUTER JOIN F_GRP_WORKSHEET F_GRP_WORKSHEET
            ON DIM_GRP_CLAIM_DIR_R.v_claim_number_r     = F_GRP_WORKSHEET.v_claim_number_r
            and F_GRP_WORKSHEET.n_claim_coverage_group_sk_r = F_CLAIM_PAYMENT_DETAIL_R.n_claim_coverage_group_sk_r
            left outer join payment_dates
            on payment_dates.N_CLAIM_COVERAGE_GROUP_SK_R =F_CLAIM_PAYMENT_DETAIL_R.n_claim_coverage_group_sk_r
            WHERE DIM_GRP_CLAIM_DIR_R.V_ACTIVE_STATUS_R ='Y'
            AND DIM_GRP_POLICY_DIR_R.V_ACTIVE_STATUS_R  ='Y'
            and DIM_GRP_CLAIM_DIR_R.v_lob_type_r in ('LIFE', 'NONS', 'WOP'));
			 --24-Jan-2023 changes end
			-- PRCS_F_PSR_CLAIM_MV_4(V_PAID_START_DATE,V_PAID_END_DATE);
			UPDATE FCT_PROC_EXEC_STATUS_LOG_R
						SET V_STATUS_R                = 'Successful',
						T_EXECUTION_END_TIMESTAMP_R = systimestamp
						WHERE N_SERIAL_NUM_R          = N_MAX_SERIAL_NUM_R;
						COMMIT;
			EXCEPTION
			WHEN OTHERS THEN
				V_SQLCODE                    := SQLCODE;
						V_SQLERRM                    := SUBSTR(SYS.STANDARD.SQLERRM,1,500);
						UPDATE FCT_PROC_EXEC_STATUS_LOG_R
						SET V_STATUS_R                = 'Failed',
						T_EXECUTION_END_TIMESTAMP_R = systimestamp,
						V_ERROR_CODE_R				= V_SQLCODE,
						V_ERROR_DESC_R				= V_SQLERRM
						WHERE N_SERIAL_NUM_R          = N_MAX_SERIAL_NUM_R;
					COMMIT;
						RAISE;
			END;
		END IF;
		/*--17-Jun-2022 changes
		ln_mv_refresh_chk_cnt:=0;
		OPEN cur_mv_refresh_chk('PROC_REFRESH_GRP_M_VIEW_TBLS.F_PSR_CLAIM_COV_STATUS_MV');
		FETCH cur_mv_refresh_chk INTO ln_mv_refresh_chk_cnt;
		CLOSE cur_mv_refresh_chk;

		IF NVL(ln_mv_refresh_chk_cnt,0) =0 THEN */--17-Jun-2022 changes
		IF UPPER(TRIM(P_MV_TBL_NAME)) like  '%F_PSR_CLAIM_COV_STATUS_MV%' THEN --17-Jun-2022 changes

			Begin
			SELECT SEQ_FCT_PROC_EXEC_STATUS_LOG_R.NEXTVAL INTO N_MAX_SERIAL_NUM_R FROM DUAL;

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
				LN_BATCH_ID_R,--99999999,
				TO_CHAR(sysdate,'yyyymmdd'),
				1,
				'Started',
				SYSTIMESTAMP,
				USER,
				P_MV_TBL_NAME||'.PROC_REFRESH_GRP_M_VIEW_TBLS.F_PSR_CLAIM_COV_STATUS_MV_TBL',
				N_MAX_SERIAL_NUM_R
				);
			COMMIT;
			--24-Jan-2023 changes starts
			--dbms_mview.refresh('F_PSR_CLAIM_COV_STATUS_MV', method => 'C', atomic_refresh => FALSE);
			EXECUTE IMMEDIATE 'TRUNCATE TABLE F_PSR_CLAIM_COV_STATUS_MV_TBL PURGE SNAPSHOT LOG';
			INSERT
			  /*+APPEND_VALUES*/
			INTO F_PSR_CLAIM_COV_STATUS_MV_TBL
			  (
				POLICY_SKEY                                   ,
                CLAIM_SKEY                                    ,
                AS_OF_DATE                                    ,
                COVERAGE_TYPE                                 ,
                PRODUCT_COVERAGE_CODE                         ,
                COVERAGE_TYPE_CODE                            ,
                COVERAGE_TYPE_DESCRIPTION                     ,
                EXAMINER_DEPARTMENT_CODE                      ,
                EXAMINER_LOGIN_ID                             ,
                EXAMINER_NAME                                 ,
                VOCATIONAL_REHAB_ACTIVE_STATUS                ,
                VOCATIONAL_REHAB_OUTCOME                      ,
                VOCATIONAL_REHAB_SERVICE_REQUESTED_OTHER      ,
                VOCATIONAL_REHAB_SERVICE_REQUESTED            ,
                CLAIM_IDENTIFER                               ,
                DISABILITY_START_DATE                         ,
                ANY_OCC_DECISION_MADE_DATE                    ,
                ANY_OCC_PERIOD_INDICATOR                      ,
                OWN_OCC_PERIOD                                ,
                ANY_OCC_START_DATE                            ,
                CLAIM_COVERAGE_DESCRIPTION                    ,
                COVERAGE_GROUP_CODE                           ,
                CLAIM_STATUS_CATEGORY                         ,
                CLAIM_STATUS_DESCRIPTION                      ,
                CLAIM_STATUS_EFFECTIVE_DATE                   ,
                CLAIM_TYPE                                    ,
                CLAIM_STATUS_CODE                             ,
                PRIOR_STATUS_CODE                             ,
                D_LAST_IN_STATUS_46_DATE_R
				--23-Jul-2023 changes starts
				,DIRECTOR_FULL_NAME --V_DIRECTOR_FULL_NAME_R
				,SUPERVISOR_FULL_NAME--V_SUPERVISOR_FULL_NAME_R
                ,DIRECTOR_LOGIN_ID--V_DIRECTOR_LOGIN_ID_R
                ,SUPERVISOR_LOGIN_ID --V_SUPERVISOR_LOGIN_ID_R
				,NURSE_CERT_OWN_OCC
				,NURSE_CERT_END_DATE--D_NURSE_CERT_END_DATE_R
				,NURSE_CERT_FLAG
				--23-Jul-2023 changes ends
				--27-Mar-2024 changes starts
				,N_PRODUCT_SK_R              
				,V_BASIC_PRODUCT_LINE_CODE_R 
				,V_BASIC_PRODUCT_LINE_DESC_R 
				--27-Mar-2024 changes ends
			  )
		    SELECT
              DISTINCT T333136.n_policy_sk_r                    AS Policy_skey,
              T333511.n_claim_sk_r                              AS Claim_skey,

              (
                  SELECT
                      MAX(fic_mis_date_r)
                  FROM
                      dim_grp_policy_dir_r
                  WHERE
                      v_source_system_name_r = 'PACS'
              )      AS As_Of_Date,
              max(CASE
                WHEN T393779.V_COVERAGE_TYPE_CODE_R = '1'
                THEN 'LTD'
                WHEN T393779.V_COVERAGE_TYPE_CODE_R = '2'
                THEN 'STD'
                WHEN T393779.V_COVERAGE_TYPE_CODE_R IN ('1', '2')
                THEN 'Disability (LTD )'
                WHEN T438103.V_COVERAGE_TYPE_CODE_R = '3'
                THEN 'Life'
                WHEN T438103.V_COVERAGE_CATEGORY_R = 'Life - Annuity'
                AND T438103.V_COVERAGE_TYPE_CODE_R = '3'
                THEN 'Life - Annuity'
                WHEN T438103.V_COVERAGE_CATEGORY_R = 'Life - Non-Annuity'
                AND T438103.V_COVERAGE_TYPE_CODE_R = '3'
                THEN 'Life - Non-Annuity'
                WHEN T438103.V_COVERAGE_TYPE_CODE_R = '3'
                AND NOT (T438103.V_COVERAGE_CODE_R LIKE '%WP%'
                OR T438103.V_COVERAGE_CODE_R LIKE 'GAN%'
                OR T438103.V_COVERAGE_CODE_R LIKE 'CD%')
                THEN 'Group Life'
              END             )               AS Coverage_type,
             max( NVL(T393779.V_COVERAGE_CODE_R,T438103.V_COVERAGE_CODE_R)  )    AS Product_Coverage_code,
             max(NVL(T393779.V_COVERAGE_TYPE_CODE_R,T438103.V_COVERAGE_TYPE_CODE_R)) AS Coverage_Type_Code,
             max( NVL(T393779.V_COVERAGE_TYPE_DESC_R,T438103.V_COVERAGE_TYPE_DESC_R) ) AS Coverage_Type_Description,
              CASE
                WHEN SUBSTR(T333447.V_EXAMINER_LOGIN_ID_R , 1 , 1) = 'T'
                THEN SUBSTR(T333447.V_EXAMINER_LOGIN_ID_R , 2 , 3)
                ELSE SUBSTR(T333447.V_EXAMINER_LOGIN_ID_R , 1 , 3)
              END                           AS Examiner_Department_code,
              T333447.V_EXAMINER_LOGIN_ID_R AS Examiner_Login_Id,
              T333447.v_examiner_desc_r                              AS Examiner_Name,
              T394101.V_REHAB_STATUS_R            AS Vocational_Rehab_Active_Status,
              T394101.V_VOC_REHAB_OUTCOME_R       AS Vocational_Rehab_Outcome,
              T394101.V_SERVICE_REQUESTED_OTHER_R AS Vocational_Rehab_Service_Requested_Other,
              T394101.V_SERVICE_REQUESTED_R       AS Vocational_Rehab_Service_Requested,
              nvl(T357774.v_claiM_identifier_r,T333511.v_claim_number_r) AS Claim_Identifer,

              CASE
                WHEN T333136.V_ORIG_LOB_R = 'VAI'
                THEN T333526.D_DATE_OF_EVENT_R +
                  CASE
                    WHEN T357771.N_ELIM_PERIOD_R <> ''
                    OR T357771.N_ELIM_PERIOD_R   <> 0
                    THEN T357771.N_ELIM_PERIOD_R
                    ELSE 0
                  END
              END                     AS Disability_Start_Date,
              T357771.D_ANYOCC_DATE_R AS Any_Occ_Decision_Made_Date,
              CASE
                WHEN T357771.V_OWN_OCC_PERIOD_R LIKE '%MOS'
                THEN 'M'
                ELSE
                  CASE
                    WHEN T357771.V_OWN_OCC_PERIOD_R LIKE '@%'
                    THEN 'A'
                  END
              END AS Any_Occ_Period_Indicator,
              CASE
                WHEN upper(T357771.V_OWN_OCC_PERIOD_R) LIKE '%MOS'
                THEN SUBSTR(T357771.V_OWN_OCC_PERIOD_R , 1 , 2)
                ELSE
                  CASE
                    WHEN T357771.V_OWN_OCC_PERIOD_R LIKE '@%'
                    THEN SUBSTR(T357771.V_OWN_OCC_PERIOD_R , 2 , 2)
                  END
              END                           AS Own_Occ_Period,
              T357771.D_ANYOCC_START_DATE_R AS Any_Occ_Start_Date,
	    	  --19-Apr-2023 Changes starts
              --max(NVL(T393779.V_PRODUCT_LINE_DESC_R,T438103.V_PRODUCT_LINE_DESC_R)) AS Claim_Coverage_Description,
	    	  max(NVL(T393779.V_COVERAGE_DESC_R,T438103.V_COVERAGE_DESC_R)) AS Claim_Coverage_Description,
	    	  --19-Apr-2023 Changes ends
              T357774.N_COV_GRP_ID_R        AS Coverage_Group_Code,
              max(CASE
                WHEN T333511.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP')
                THEN
                  CASE
                    WHEN T357774.V_REASON_CODE_R >= '60'
                    THEN 'CLOSED'
                    WHEN T357774.V_REASON_CODE_R < '60'
                    AND T357774.V_REASON_CODE_R >= '50'
                    THEN 'RESISTING'
                    WHEN T357774.V_REASON_CODE_R < '50'
                    AND T357774.V_REASON_CODE_R >= '40'
                    THEN 'OPEN, NO LIABILITIES'
                    WHEN T357774.V_REASON_CODE_R < '40'
                    AND T357774.V_REASON_CODE_R >= '30'
                    THEN 'ACTIVE'
                    WHEN T357774.V_REASON_CODE_R < '30'
                    THEN 'OPEN INCOMPLETE'
                    ELSE NULL
                  END
                WHEN T333511.V_LOB_TYPE_R IN ('LTD', 'STD', 'VPL', 'VPS')
                THEN
                  CASE
                    WHEN T333447.V_CLAIM_STATUS_REASON_CODE_R >= '60'
                    THEN 'CLOSED'
                    WHEN T333447.V_CLAIM_STATUS_REASON_CODE_R < '60'
                    AND T333447.V_CLAIM_STATUS_REASON_CODE_R >= '50'
                    THEN 'RESISTING'
                    WHEN T333447.V_CLAIM_STATUS_REASON_CODE_R < '50'
                    AND T333447.V_CLAIM_STATUS_REASON_CODE_R >= '40'
                    THEN 'OPEN, NO LIABILITIES'
                    WHEN T333447.V_CLAIM_STATUS_REASON_CODE_R < '40'
                    AND T333447.V_CLAIM_STATUS_REASON_CODE_R >= '30'
                    THEN 'ACTIVE'
                    WHEN T333447.V_CLAIM_STATUS_REASON_CODE_R < '30'
                    THEN 'OPEN INCOMPLETE'
                    ELSE NULL
                  END
                ELSE NULL
              END ) AS Claim_Status_Category,
              max(CASE
                WHEN T333511.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP')
                THEN T390719.V_CLAIM_STATUS_DESC_R
                WHEN T333511.V_LOB_TYPE_R IN ('LTD', 'STD', 'VPL', 'VPS')
                THEN T389767.V_CLAIM_STATUS_DESC_R
                ELSE NULL
              END) AS Claim_Status_Description,
              max(CASE
                WHEN T333511.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP')
                THEN trunc(T426281.D_CLAIM_STATUS_CODE_EFF_DATE_R)
                WHEN T333511.V_LOB_TYPE_R IN ('LTD', 'STD', 'VPL', 'VPS')
                THEN trunc(T424641.D_CLAIM_STATUS_CODE_EFF_DATE_R)
                ELSE NULL
              END ) AS Claim_Status_Effective_Date,
             max( CASE
                WHEN T333511.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP')
                THEN
                  CASE
                    WHEN T426281.V_CURR_CLAIM_STATUS_CODE_R >= '60'
                    THEN 'Closed (60 or greater)'
                    WHEN T426281.V_CURR_CLAIM_STATUS_CODE_R BETWEEN '50' AND '59'
                    THEN 'Resisting (51)'
                    WHEN T426281.V_CURR_CLAIM_STATUS_CODE_R BETWEEN '30' AND '49'
                    THEN 'Open, excl. Incomplete (30-49)'
                    WHEN T426281.V_CURR_CLAIM_STATUS_CODE_R BETWEEN '20' AND '29'
                    THEN 'Open, Incomplete (e.g., 22)'
                    WHEN T426281.V_CURR_CLAIM_STATUS_CODE_R < '60'
                    THEN 'All Open (<60)'
                    WHEN T426281.V_CURR_CLAIM_STATUS_CODE_R = '32'
                    AND T438103.V_COVERAGE_TYPE_CODE_R      = '3'
                    OR T426281.V_CURR_CLAIM_STATUS_CODE_R   = '46'
                    AND T438103.V_COVERAGE_TYPE_CODE_R     IN ('1', '2')
                    THEN 'Pending (32 for Life, 46 for Disability)'
                    WHEN T426281.V_CURR_CLAIM_STATUS_CODE_R BETWEEN '20' AND '32'
                    OR T426281.V_CURR_CLAIM_STATUS_CODE_R BETWEEN '35' AND '50'
                    THEN 'Open, excl. 33, 34, 51'
                  END
                WHEN T333511.V_LOB_TYPE_R IN ('LTD', 'STD', 'VPL', 'VPS')
                THEN
                  CASE
                    WHEN T424641.V_CURR_CLAIM_STATUS_CODE_R >= '60'
                    THEN 'Closed (60 or greater)'
                    WHEN T424641.V_CURR_CLAIM_STATUS_CODE_R BETWEEN '50' AND '59'
                    THEN 'Resisting (51)'
                    WHEN T424641.V_CURR_CLAIM_STATUS_CODE_R BETWEEN '30' AND '49'
                    THEN 'Open, excl. Incomplete (30-49)'
                    WHEN T424641.V_CURR_CLAIM_STATUS_CODE_R BETWEEN '20' AND '29'
                    THEN 'Open, Incomplete (e.g., 22)'
                    WHEN T424641.V_CURR_CLAIM_STATUS_CODE_R < '60'
                    THEN 'All Open (<60)'
                    WHEN T424641.V_CURR_CLAIM_STATUS_CODE_R = '32'
                    AND T393779.V_COVERAGE_TYPE_CODE_R      = '3'
                    OR T424641.V_CURR_CLAIM_STATUS_CODE_R   = '46'
                    AND (T393779.V_COVERAGE_TYPE_CODE_R    IN ('1', '2'))
                    THEN 'Pending (32 for Life, 46 for Disability)'
                    WHEN T424641.V_CURR_CLAIM_STATUS_CODE_R BETWEEN '20' AND '32'
                    OR T424641.V_CURR_CLAIM_STATUS_CODE_R BETWEEN '35' AND '50'
                    THEN 'Open, excl. 33, 34, 51'
                  END
                ELSE NULL
              END ) AS Claim_Type,
             max( CASE
                WHEN T333511.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP')
				 AND T333511.v_source_system_name_r = 'PACS'--18-Oct-2023 changes
                THEN T426281.V_CURR_CLAIM_STATUS_CODE_R
				--18-Oct-2023 changes starts
                WHEN T333511.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP') and T333511.v_source_system_name_r = 'CV'
                THEN T357774.V_REASON_CODE_R
				--18-Oct-2023 ends
                WHEN T333511.V_LOB_TYPE_R IN ('LTD', 'STD', 'VPL', 'VPS')
                THEN T424641.V_CURR_CLAIM_STATUS_CODE_R
                ELSE NULL
              END ) AS Claim_Status_Code,
            max(  CASE
                WHEN T333511.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP')
                THEN T426281.V_PRIOR_CLAIM_STATUS_CODE_R
                WHEN T333511.V_LOB_TYPE_R IN ('LTD', 'STD', 'VPL', 'VPS')
                THEN T424641.V_PRIOR_CLAIM_STATUS_CODE_R
                ELSE NULL
              END )AS Prior_status_Code
            ,
             max(  CASE
                WHEN T333511.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP')
                THEN T426281.D_LAST_IN_STATUS_46_DATE_R
                WHEN T333511.V_LOB_TYPE_R IN ('LTD', 'STD', 'VPL', 'VPS')
                THEN T424641.D_LAST_IN_STATUS_46_DATE_R
                ELSE NULL
              END )AS D_LAST_IN_STATUS_46_DATE_R
	    	--23-Jul-2023 changes starts
	    	,T391089.V_DIRECTOR_FULL_NAME_R
	    	,T391089.V_SUPERVISOR_FULL_NAME_R
	    	,T391089.V_DIRECTOR_LOGIN_ID_R
	    	,T391089.V_SUPERVISOR_LOGIN_ID_R
          	,CASE
               WHEN T527283.D_NURSE_CERT_END_DATE_R > T357771.D_ANYOCC_START_DATE_R
               THEN 'Y'
               ELSE 'N'
             END AS NURSE_CERT_OWN_OCC
	    	,T527283.D_NURSE_CERT_END_DATE_R
	    	,CASE
               WHEN NVL(T527283.D_NURSE_CERT_END_DATE_R,sysdate) <= sysdate
               THEN 'x'
               ELSE NULL
             END AS NURSE_CERT_FLAG
	    	--23-Jul-2023 changes ends
			--27-Mar-2024 changes starts
			,MAX(NVL(T393779.N_PRODUCT_SK_R,T438103.N_PRODUCT_SK_R))                           N_PRODUCT_SK_R              
			,MAX(NVL(T393779.V_BASIC_PRODUCT_LINE_CODE_R,T438103.V_BASIC_PRODUCT_LINE_CODE_R)) V_BASIC_PRODUCT_LINE_CODE_R 
			,MAX(NVL(T393779.V_BASIC_PRODUCT_LINE_DESC_R,T438103.V_BASIC_PRODUCT_LINE_DESC_R)) V_BASIC_PRODUCT_LINE_DESC_R 
			--27-Mar-2024 changes ends
        FROM DIM_GRP_POLICY_DIR_R T333136
          /* D_GRP_POLICY_DIR_R_Policy */
        INNER JOIN DIM_GRP_CLAIM_DIR_R T333511
          /* D_GRP_CLAIM_DIR_R_Claim */
        ON T333136.N_POLICY_SK_R      = T333511.N_POLICY_SK_R
        AND T333511.V_ACTIVE_STATUS_R = 'Y'
        inner JOIN DIM_GRP_CLAIM_DETAIL_R T333447
          /* D_GRP_CLAIM_DETAIL_R_Claim */
        ON T333447.N_CLAIM_SK_R       = T333511.N_CLAIM_SK_R
        AND T333447.V_ACTIVE_STATUS_R = 'Y'
		 --23-Jul-2023 changes 5.b starts
         LEFT OUTER JOIN
           (SELECT *
           FROM dim_grp_nurse_cert_r c
           WHERE v_active_status_r = 'Y'
           AND N_NURSE_CERT_SEQ_R  =
             (SELECT MAX(N_NURSE_CERT_SEQ_R)
             FROM dim_grp_nurse_cert_r
             WHERE n_claim_sk_r    = c.n_claim_sk_r
             AND v_active_status_r = 'Y'
             )
           ) T527283
           /* D_GRP_NURSE_CERT_R_Claims */
         ON T527283.N_CLAIM_SK_R = T333511.N_CLAIM_SK_R
		 --23-Jul-2023 changes 5.b ends
        LEFT OUTER JOIN DIM_CLAIM_STATUS_R T389767
          /* D_CLAIM_STATUS_R_Claim_Disability */
        ON T333447.V_CLAIM_STATUS_REASON_CODE_R = T389767.V_CLAIM_STATUS_CODE_R
        AND T389767.V_ACTIVE_STATUS_R           = 'Y'
        LEFT OUTER JOIN DIM_GRP_CLAIM_EVENT_R T333541
          /* D_GRP_CLAIM_EVENT_R_Claim */
        ON T333447.N_CLAIM_EVENT_SK_R = T333541.N_CLAIM_EVENT_SK_R
        AND T333541.V_ACTIVE_STATUS_R = 'Y'
        LEFT OUTER JOIN DIM_GRP_CLAIM_EVENT_DIR_R T333526
          /* D_GRP_CLAIM_EVENT_DIR_R_Claim */
        ON T333526.N_CLAIM_EVENT_SK_R = T333541.N_CLAIM_EVENT_SK_R
        AND T333526.V_ACTIVE_STATUS_R = 'Y'
        LEFT OUTER JOIN DIM_GRP_CLAIM_COVERAGE_R T357788
          /* D_GRP_CLAIM_COVERAGE_R_Claims */
        ON T333447.N_CLAIM_SK_R       = T357788.N_CLAIM_SK_R
        AND T357788.V_ACTIVE_STATUS_R='Y'
                LEFT OUTER JOIN DIM_GRP_CLAIM_ELIGIBILITY_R T357771
          /* D_GRP_CLAIM_ELIGIBILITY_R_Claims */

        oN T357771.n_claim_coverage_sk_r = CASE
                                                WHEN
                                                T357771.n_claim_coverage_sk_r <> - 1
                                                THEN
                                                   T357788.n_claim_coverage_sk_r
                                                      ELSE
                                                      - 1
                                                    END
        AND T357771.n_claim_sk_r = T357788.n_claim_sk_r
        and T357771.v_active_status_r = 'Y'
        LEFT OUTER JOIN MVW_PRODUCT_SK_LOOKUP_TBL T439745
          /* VW_PRODUCT_SK_LOOKUP_For_Disablity */
        ON T357788.N_CLAIM_SK_R             = T439745.N_CLAIM_SK_R
        AND T357788.V_CLAIM_COVERAGE_CODE_R = T439745.V_CLAIM_COVERAGE_CODE_R
        LEFT OUTER JOIN DIM_GRP_PRODUCT_R T393779
          /* D_GRP_PRODUCT_R_Claims_Disability */
        ON T393779.N_PRODUCT_SK_R     = T439745.N_PRODUCT_SK_R
        AND T393779.V_ACTIVE_STATUS_R = 'Y'
        --12-Sep-2023 changes starts
        --LEFT OUTER JOIN VW_DIM_GRP_CLAIM_PRIOR_STATUS_R T424641  -- as requested by suhasini 27 Feb 2023--
       LEFT OUTER JOIN VW_DIM_GRP_CLAIM_PRIOR_STATUS_R_max T424641
        --12-Sep-2023 changes ends
          /* D_GRP_CLAIM_PRIOR_STATUS_R_Claim_Disability */
        ON T357788.V_CLAIM_COVERAGE_CODE_R = T424641.V_COVERAGE_CODE_R
        AND T357788.V_CLAIM_NUMBER_R       = T424641.V_CLAIM_NUMBER_R
        and T357788.N_CLAIM_COVERAGE_SK_R = T424641.N_CLAIM_COVERAGE_SK_R
        LEFT OUTER JOIN DIM_GRP_CLAIM_COVERAGE_GROUP_R T357774
          /* D_GRP_CLAIM_COVERAGE_GROUP_R_Claims */
        ON T357774.N_CLAIM_COVERAGE_SK_R = T357788.N_CLAIM_COVERAGE_SK_R
        AND T357774.V_ACTIVE_STATUS_R    = 'Y'
        LEFT OUTER JOIN DIM_CLAIM_STATUS_R T390719
          /* D_CLAIM_STATUS_R_Claim_LifeNonStan */
        ON T357774.V_REASON_CODE_R    = T390719.V_CLAIM_STATUS_CODE_R
        AND T390719.V_ACTIVE_STATUS_R = 'Y'
        LEFT OUTER JOIN VW_DIM_GRP_CLAIM_PRIOR_STATUS_R T426281  --as requested by suhasini 27 Feb 2023--
          /* D_GRP_CLAIM_PRIOR_STATUS_R_Claim_LifeNonStan */
        ON /*06-Dec-2023 changes starts
		T357774.V_COVERAGE_CODE_R = T426281.V_COVERAGE_GROUP_CODE_R
        AND T357774.N_COV_GRP_ID_R   = T426281.N_COV_GRP_ID_R
        AND T357774.V_CLAIM_NUMBER_R = T426281.V_CLAIM_NUMBER_R*/
        T357774.N_CLAIM_SK_R = T426281.N_CLAIM_SK_R
        AND T357774.N_CLAIM_COVERAGE_SK_R = T426281.N_CLAIM_COVERAGE_SK_R
        AND T357774.N_CLAIM_COVERAGE_GROUP_SK_R = T426281.N_CLAIM_COVERAGE_GROUP_SK_R
		--06-Dec-2023 changes ends
        LEFT OUTER JOIN MVW_PRODUCT_SK_LOOKUP_TBL T439747
          /* VW_PRODUCT_SK_LOOKUP_For_Life */
        ON T357774.N_CLAIM_SK_R             = T439747.N_CLAIM_SK_R
        AND T357774.V_CLAIM_COVERAGE_CODE_R = T439747.V_CLAIM_COVERAGE_CODE_R
        LEFT OUTER JOIN DIM_GRP_PRODUCT_R T438103
          /* D_GRP_PRODUCT_R_Claims_Life */
        ON T438103.N_PRODUCT_SK_R     = T439747.N_PRODUCT_SK_R
        AND T438103.V_ACTIVE_STATUS_R = 'Y'
        LEFT OUTER JOIN DIM_EMPLOYEE_R T391089
          /* D_EMPLOYEE_R_Claims */
        ON T333447.V_EXAMINER_LOGIN_ID_R     = T391089.V_EMPLOYEE_LOGIN_ID_R
        AND upper(T391089.V_BUSINESS_UNIT_R) = 'CLAIMS'
        LEFT OUTER JOIN DIM_GRP_VOCREHAB_R T394101
          /* D_GRP_VOCREHAB_R */
        ON T333447.N_CLAIM_SK_R       = T394101.N_CLAIM_SK_R
        AND T394101.V_ACTIVE_STATUS_R = 'Y'
        WHERE (
          /*AND T333136.V_POLICY_NUMBER_R ='LTD112150'*/
          T333136.V_ACTIVE_STATUS_R = 'Y'
          --and cast(T333136.T_EVENT_TIMESTAMP_R as date) between '01-jan-2020' and '31-dec-2020'
        --  and T333511.v_claim_number_r = '2023-01-19-0265-LTD-01'
          )
        group by
        T333136.n_policy_sk_r                    ,
          T333511.n_claim_sk_r                ,

        CASE
            WHEN SUBSTR(T333447.V_EXAMINER_LOGIN_ID_R , 1 , 1) = 'T'
            THEN SUBSTR(T333447.V_EXAMINER_LOGIN_ID_R , 2 , 3)
            ELSE SUBSTR(T333447.V_EXAMINER_LOGIN_ID_R , 1 , 3)
          END                           ,
          T333447.V_EXAMINER_LOGIN_ID_R ,
          T333447.v_examiner_desc_r                             ,
          T394101.V_REHAB_STATUS_R           ,
          T394101.V_VOC_REHAB_OUTCOME_R       ,
          T394101.V_SERVICE_REQUESTED_OTHER_R ,
          T394101.V_SERVICE_REQUESTED_R       ,
          nvl(T357774.v_claiM_identifier_r,T333511.v_claim_number_r) ,

          CASE
            WHEN T333136.V_ORIG_LOB_R = 'VAI'
            THEN T333526.D_DATE_OF_EVENT_R +
              CASE
                WHEN T357771.N_ELIM_PERIOD_R <> ''
                OR T357771.N_ELIM_PERIOD_R   <> 0
                THEN T357771.N_ELIM_PERIOD_R
                ELSE 0
              END
          END                    ,
          T357771.D_ANYOCC_DATE_R ,
          CASE
            WHEN T357771.V_OWN_OCC_PERIOD_R LIKE '%MOS'
            THEN 'M'
            ELSE
              CASE
                WHEN T357771.V_OWN_OCC_PERIOD_R LIKE '@%'
                THEN 'A'
              END
          END ,
          CASE
            WHEN upper(T357771.V_OWN_OCC_PERIOD_R) LIKE '%MOS'
            THEN SUBSTR(T357771.V_OWN_OCC_PERIOD_R , 1 , 2)
            ELSE
              CASE
                WHEN T357771.V_OWN_OCC_PERIOD_R LIKE '@%'
                THEN SUBSTR(T357771.V_OWN_OCC_PERIOD_R , 2 , 2)
              END
          END                       ,
          T357771.D_ANYOCC_START_DATE_R ,

          T357774.N_COV_GRP_ID_R
		  --23-Jul-2023 changes starts
		,T391089.V_DIRECTOR_FULL_NAME_R
		,T391089.V_SUPERVISOR_FULL_NAME_R
		,T391089.V_DIRECTOR_LOGIN_ID_R
		,T391089.V_SUPERVISOR_LOGIN_ID_R
      	,CASE
           WHEN T527283.D_NURSE_CERT_END_DATE_R > T357771.D_ANYOCC_START_DATE_R
           THEN 'Y'
           ELSE 'N'
         END
		,T527283.D_NURSE_CERT_END_DATE_R
		,CASE
           WHEN NVL(T527283.D_NURSE_CERT_END_DATE_R,sysdate) <= sysdate
           THEN 'x'
           ELSE NULL
         END
		--23-Jul-2023 changes ends
         ;

			UPDATE FCT_PROC_EXEC_STATUS_LOG_R
						SET V_STATUS_R                = 'Successful',
						T_EXECUTION_END_TIMESTAMP_R = systimestamp
						WHERE N_SERIAL_NUM_R          = N_MAX_SERIAL_NUM_R;
						COMMIT;
			EXCEPTION
			WHEN OTHERS THEN
				V_SQLCODE                    := SQLCODE;
						V_SQLERRM                    := SUBSTR(SYS.STANDARD.SQLERRM,1,500);
						UPDATE FCT_PROC_EXEC_STATUS_LOG_R
						SET V_STATUS_R                = 'Failed',
						T_EXECUTION_END_TIMESTAMP_R = systimestamp,
						V_ERROR_CODE_R				= V_SQLCODE,
						V_ERROR_DESC_R				= V_SQLERRM
						WHERE N_SERIAL_NUM_R          = N_MAX_SERIAL_NUM_R;
					COMMIT;
						RAISE;
			END;
		END IF;
		/*--17-Jun-2022 changes
		ln_mv_refresh_chk_cnt:=0;
		OPEN cur_mv_refresh_chk('PROC_REFRESH_GRP_M_VIEW_TBLS.F_PSR_CLAIMANT_MV');
		FETCH cur_mv_refresh_chk INTO ln_mv_refresh_chk_cnt;
		CLOSE cur_mv_refresh_chk;

		IF NVL(ln_mv_refresh_chk_cnt,0) =0 THEN */
		IF UPPER(TRIM(P_MV_TBL_NAME)) like  '%F_PSR_CLAIMANT_MV%' THEN --17-Jun-2022 changes

			Begin
			SELECT SEQ_FCT_PROC_EXEC_STATUS_LOG_R.NEXTVAL INTO N_MAX_SERIAL_NUM_R FROM DUAL;

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
				LN_BATCH_ID_R,--99999999,
				TO_CHAR(sysdate,'yyyymmdd'),
				1,
				'Started',
				SYSTIMESTAMP,
				USER,
				P_MV_TBL_NAME||'.PROC_REFRESH_GRP_M_VIEW_TBLS.F_PSR_CLAIMANT_MV_TBL',
				N_MAX_SERIAL_NUM_R
				);
			COMMIT;
			--24-Jan-2023 changes starts
			--dbms_mview.refresh('F_PSR_CLAIMANT_MV', method => 'C', atomic_refresh => FALSE);
			EXECUTE IMMEDIATE 'TRUNCATE TABLE F_PSR_CLAIMANT_MV_TBL PURGE SNAPSHOT LOG';

			PKG_GRP_COMMON_UTIL.prc_force_indexes_unusable
			(
			p_out_job_id   		  		  => gn_out_job_id,
			p_rpt_table			   		  => 'FCT_BILLING_POLICY_PREMIUM_R_TABLE',
			p_Log_seq_num             	  => 1
			);

			INSERT
			  /*+APPEND_VALUES*/
			INTO F_PSR_CLAIMANT_MV_TBL
			  (
				POLICY_SKEY,
				CLAIM_SKEY,
				AS_OF_DATE,
				POLICY_PREFIX,
				POLICY_SUFFIX,
				CLAIM_IDENTIFER,
				CLAIM_NUMBER,
				CLAIMANT_NAME,
				CLAIMANT_GENDER,
				CLAIMANT_DOB,
				CLAIMANT_AGE,
				CLAIMANT_HIERDATE,
				CLAIM_COMPANY_NAME,
				CLAIM_COMPANY_CODE,
				LOCATION_NAME,
				LOCATION_NUMBER,
				LOCATION_ID,
				SITUS_STATE,
				INSURED_STATE,
				CLAIMANT_ADDRESS1,
				CLAIMANT_ADDRESS2,
				CLAIMANT_ADDRESS3,
				CLAIMANT_CITY,
				CLAIMANT_ZIPCODE,
				CERTIFICATE_NUMBER,
				CLAIMANT_SALARY,
				CLAIMANT_SALARY_INDICATOR
				,CLIENT_NAME --07-May-2024 changes
			  )
			  SELECT
distinct
    d_grp_policy_dir_r_policy.n_policy_sk_r                                                                 AS policy_skey,
    d_grp_claim_dir_r_claim.n_claim_sk_r                                                                    AS claim_skey,
    (
        SELECT
            MAX(fic_mis_date_r)
        FROM
            dim_grp_policy_dir_r
        WHERE
            v_source_system_name_r = 'PACS'
    )                                                                                                       AS as_of_date,
            --Entity Attributes Start---
    d_grp_policy_dir_r_policy.v_policy_prefix_r                                                             AS policy_prefix,
    d_grp_policy_dir_r_policy.v_policy_suffix_r                                                             AS policy_suffix,
    nvl(d_grp_claim_coverage_group_r_claims.v_claim_identifier_r, d_grp_claim_dir_r_claim.v_claim_number_r) AS claim_identifer,
    d_grp_claim_dir_r_claim.v_claim_number_r                                                                AS claim_number,
    concat(concat(d_grp_party_r_claims.v_individual_last_name_r, ', '),
           d_grp_party_r_claims.v_individual_first_name_r)                                                  AS claimant_name,
    d_grp_party_r_claims.v_gender_r                                                                         AS claimant_gender,
    d_grp_party_r_claims.d_birth_date_r                                                                     AS claimant_dob,
    floor(months_between((
        SELECT
            MAX(fic_mis_date_r)
        FROM
            dim_grp_policy_dir_r
        WHERE
            v_source_system_name_r = 'PACS'
    ),
                         d_grp_party_r_claims.d_birth_date_r) / 12)                                                   AS claimant_age
                         ,
    d_grp_claim_event_r_claim.d_hire_date_r                                                                 AS claimant_hierdate,
            /*CASE
            WHEN upper(D_GRP_PARTY_R_Claims.V_PARTY_TYPE_R) = 'VENDOR'
            THEN concat(concat(D_GRP_PARTY_R_Claims.V_INDIVIDUAL_LAST_NAME_R, ' '), D_GRP_PARTY_R_Claims.V_INDIVIDUAL_FIRST_NAME_R)
            END                                    AS Vendor_Name,*/
    d_grp_carrier_r_party.v_carrier_name_r                                                                  AS claim_company_name,
    d_grp_claim_dir_r_claim.V_COMPANY_R                                                                    AS claim_company_code,
    dim_grp_claim_detail_subgroup_lookup.v_subgroup_name_r                                                  AS location_name,
    concat(concat(concat(d_grp_policy_dir_r_policy.v_policy_prefix_r, d_grp_policy_dir_r_policy.v_policy_suffix_r),
                  '-'),
           d_grp_claim_detail_r_claim.v_subgroup_id_r)                                                      AS location_number,
    dim_grp_claim_detail_subgroup_lookup.v_subgroup_id_r                                                    AS location_id,
           /* CASE
              WHEN upper(F_GRP_PARTY_ADDRESS_R_Claimant.V_LOCATION_ID_R) = 'SITUS'
              AND upper(F_GRP_PARTY_ADDRESS_R_Claimant.V_ADDRESS_TYPE_R) = 'MAIN'
              AND upper(F_GRP_PARTY_ADDRESS_R_Claimant.V_PARTY_TYPE_R)   = 'CUSTOMER'
              THEN F_GRP_PARTY_ADDRESS_R_Claimant.V_STATE_NAME_R
              ELSE NULL
            END AS Situs_State,*/-- Commenting Situs_State logic as per Suhasini's request and adding new logic
    fct_grp_party_address_r_customer.v_state_name_r                                                                  AS situs_state,
    CASE
        WHEN upper(f_grp_party_address_r_claimant.v_party_type_r) = 'INSURED'
             AND upper(f_grp_party_address_r_claimant.v_address_type_r) = 'MAIN' THEN
            case when d_ref_state_claimant.v_state_name_r = 'BRITISH COLUMBIA' then 'British Columbia'
            else d_ref_state_claimant.v_state_name_r
            end

        ELSE
            NULL
    END                                                                                                     AS insured_state,
    CASE
        WHEN upper(f_grp_party_address_r_claimant.v_party_type_r) = 'INSURED'
             AND upper(f_grp_party_address_r_claimant.v_address_type_r) = 'MAIN' THEN
            d_grp_address_dir_r_claimant.v_addressline1_r
        ELSE
            NULL
    END                                                                                                     AS claimant_address1,
    CASE
        WHEN upper(f_grp_party_address_r_claimant.v_party_type_r) = 'INSURED'
             AND upper(f_grp_party_address_r_claimant.v_address_type_r) = 'MAIN' THEN
            d_grp_address_dir_r_claimant.v_addressline2_r
        ELSE
            NULL
    END                                                                                                     AS claimant_address2,
    CASE
        WHEN upper(f_grp_party_address_r_claimant.v_party_type_r) = 'INSURED'
             AND upper(f_grp_party_address_r_claimant.v_address_type_r) = 'MAIN' THEN
            d_grp_address_dir_r_claimant.v_addressline3_r
        ELSE
            NULL
    END                                                                                                     AS claimant_address3,
    CASE
        WHEN upper(f_grp_party_address_r_claimant.v_party_type_r) = 'INSURED'
             AND upper(f_grp_party_address_r_claimant.v_address_type_r) = 'MAIN' THEN
            d_grp_address_dir_r_claimant.v_city_r
        ELSE
            NULL
    END                                                                                                     AS claimant_city,
    CASE
        WHEN upper(f_grp_party_address_r_claimant.v_party_type_r) = 'INSURED'
             AND upper(f_grp_party_address_r_claimant.v_address_type_r) = 'MAIN' THEN
            f_grp_party_address_r_claimant.v_postal_zip_r
        ELSE
            NULL
    END                                                                                                     AS claimant_zipcode,
    /*	--16-Oct-2023 changes starts
	concat('XXX-XX-',
           substr(
        CASE
            WHEN f_grp_policy_r_policy.v_line_of_business_r IN('SC')
                 OR f_grp_policy_r_policy.v_class_of_business_r IN('PVG', 'PGL', 'IWP', 'ORL', 'ORDINARY LIFE',
                                                                   'MML', 'LTY', 'IDL', 'END', 'CVD')
                 OR f_grp_policy_r_policy.v_class_of_business_r LIKE '%GROUP LTD CONV%'
                 OR f_grp_policy_r_policy.v_class_of_business_r LIKE '%CTD%'
                 OR f_grp_policy_r_policy.v_class_of_business_r LIKE '%VOLUNTARY LTD CONV%'
                 OR f_grp_policy_r_policy.v_class_of_business_r LIKE '%DUAL ENDOW%'
                 OR f_grp_policy_r_policy.v_class_of_business_r LIKE '%DUAL INDUS%'
                 OR f_grp_policy_r_policy.v_class_of_business_r LIKE '%LOTTER%'
                 OR f_grp_policy_r_policy.v_class_of_business_r LIKE 'MASS MARKET%' THEN
                TRIM(BOTH ' ' FROM substr(d_grp_claim_detail_r_claim.v_policy_number_r, 1, 10))
            WHEN d_grp_party_r_claims.v_individual_or_org_ind_r = 'I' THEN
                enc_dec.decrypt(d_grp_party_r_claims.v_tax_number_r)
            ELSE
                NULL
        END,
        length(TRIM(trailing FROM(
        CASE
            WHEN f_grp_policy_r_policy.v_line_of_business_r IN('SC')
                 OR f_grp_policy_r_policy.v_class_of_business_r IN('PVG', 'PGL', 'IWP', 'ORL', 'ORDINARY LIFE',
                                                                   'MML', 'LTY', 'IDL', 'END', 'CVD')
                 OR f_grp_policy_r_policy.v_class_of_business_r LIKE '%GROUP LTD CONV%'
                 OR f_grp_policy_r_policy.v_class_of_business_r LIKE '%CTD%'
                 OR f_grp_policy_r_policy.v_class_of_business_r LIKE '%VOLUNTARY LTD CONV%'
                 OR f_grp_policy_r_policy.v_class_of_business_r LIKE '%DUAL ENDOW%'
                 OR f_grp_policy_r_policy.v_class_of_business_r LIKE '%DUAL INDUS%'
                 OR f_grp_policy_r_policy.v_class_of_business_r LIKE '%LOTTER%'
                 OR f_grp_policy_r_policy.v_class_of_business_r LIKE 'MASS MARKET%' THEN
                TRIM(BOTH ' ' FROM substr(d_grp_claim_detail_r_claim.v_policy_number_r, 1, 10))
            WHEN d_grp_party_r_claims.v_individual_or_org_ind_r = 'I' THEN
                enc_dec.decrypt(d_grp_party_r_claims.v_tax_number_r)
            ELSE
                NULL
        END
    ))) - 3,
        4))                                                                                       AS certificate_number,*/
        CASE
        WHEN f_grp_policy_r_policy.v_line_of_business_r IN('SC')
             OR f_grp_policy_r_policy.v_class_of_business_r IN('PVG', 'PGL', 'IWP', 'ORL', 'ORDINARY LIFE',
                                                               'MML', 'LTY', 'IDL', 'END', 'CVD')
             OR f_grp_policy_r_policy.v_class_of_business_r LIKE '%GROUP LTD CONV%'
             OR f_grp_policy_r_policy.v_class_of_business_r LIKE '%CTD%'
             OR f_grp_policy_r_policy.v_class_of_business_r LIKE '%VOLUNTARY LTD CONV%'
             OR f_grp_policy_r_policy.v_class_of_business_r LIKE '%DUAL ENDOW%'
             OR f_grp_policy_r_policy.v_class_of_business_r LIKE '%DUAL INDUS%'
             OR f_grp_policy_r_policy.v_class_of_business_r LIKE '%LOTTER%'
             OR f_grp_policy_r_policy.v_class_of_business_r LIKE 'MASS MARKET%' THEN
            TRIM(BOTH ' ' FROM substr(d_grp_claim_detail_r_claim.v_policy_number_r, 1, 10))
        WHEN d_grp_party_r_claims.v_individual_or_org_ind_r = 'I' THEN
            enc_dec.decrypt(d_grp_party_r_claims.v_tax_number_r)
        ELSE
                NULL
        END                        AS certificate_number,
	--16-Oct-2023 changes ends
    d_grp_claim_event_r_claim.n_basic_insured_salary_r                                                      AS claimant_salary,
    d_grp_claim_event_r_claim.v_basic_insured_salary_ind_r                                                  AS claimant_salary_indicator
	--07-May-2024 changes starts
    , case  when d_grp_party_r_party.V_PARTY_TYPE_R = 'CUSTOMER' then case  when d_grp_party_r_party.V_INDIVIDUAL_OR_ORG_IND_R = 'O' then d_grp_party_r_party.V_INDIVIDUAL_LAST_NAME_R when d_grp_party_r_party.V_INDIVIDUAL_OR_ORG_IND_R = 'I' then concat(concat(d_grp_party_r_party.V_INDIVIDUAL_FIRST_NAME_R, ' '), d_grp_party_r_party.V_INDIVIDUAL_LAST_NAME_R) else NULL end  else NULL end  as Client_Name
	--07-May-2024 changes ends
FROM
         dim_grp_policy_dir_r d_grp_policy_dir_r_policy
            /* D_GRP_POLICY_DIR_R_Policy */
    INNER JOIN fct_grp_policy_r                     f_grp_policy_r_policy
            /* F_GRP_POLICY_R_Policy */ ON d_grp_policy_dir_r_policy.n_policy_sk_r = f_grp_policy_r_policy.n_policy_sk_r
                                                         AND d_grp_policy_dir_r_policy.n_policy_version_number_r = f_grp_policy_r_policy.n_version_number_r
    LEFT OUTER JOIN dim_grp_party_dir_r                  d_grp_party_dir_r_party
            /* D_GRP_PARTY_DIR_R_Party */ ON f_grp_policy_r_policy.n_cust_party_sk_r = d_grp_party_dir_r_party.n_party_sk_r
                                                                   AND d_grp_party_dir_r_party.v_active_status_r = 'Y'
            /*INNER JOIN
            (SELECT DIM_TIME_r.*,
            N_DATE_SK_R*10000 N_DATE_SK_R_BATCH_ID
            FROM DIM_TIME_r
            ) DIM_TIME
            ON CAST(TRUNC(D_GRP_POLICY_DIR_R_Policy.T_EVENT_TIMESTAMP_R) AS DATE ) = CAST(TRUNC(DIM_TIME.D_CALENDAR_DATE_R) AS DATE )*/
    LEFT OUTER JOIN dim_grp_claim_dir_r                  d_grp_claim_dir_r_claim
            /* D_GRP_CLAIM_DIR_R_Claim */ ON d_grp_policy_dir_r_policy.n_policy_sk_r = d_grp_claim_dir_r_claim.n_policy_sk_r
                                                                   AND d_grp_claim_dir_r_claim.v_active_status_r = 'Y'
    LEFT OUTER JOIN dim_grp_claim_detail_r               d_grp_claim_detail_r_claim
            /* D_GRP_CLAIM_DETAIL_R_Claim */ ON d_grp_claim_detail_r_claim.n_claim_sk_r = d_grp_claim_dir_r_claim.n_claim_sk_r
                                                                         AND d_grp_claim_detail_r_claim.v_active_status_r = 'Y'
    LEFT OUTER JOIN dim_grp_claim_detail_subgroup_lookup dim_grp_claim_detail_subgroup_lookup ON d_grp_claim_detail_r_claim.v_claim_number_r = dim_grp_claim_detail_subgroup_lookup.v_claim_number_r
    LEFT OUTER JOIN dim_grp_claim_coverage_max_vw        d_grp_claim_coverage_r_claims
            /* D_GRP_CLAIM_COVERAGE_R_Claims */ ON d_grp_claim_detail_r_claim.n_claim_sk_r = d_grp_claim_coverage_r_claims.n_claim_sk_r
                                                                                   AND d_grp_claim_coverage_r_claims.v_active_status_r = 'Y'
    LEFT OUTER JOIN dim_grp_claim_coverage_group_r       d_grp_claim_coverage_group_r_claims
            /* D_GRP_CLAIM_COVERAGE_GROUP_R_Claims */ ON d_grp_claim_coverage_group_r_claims.n_claim_coverage_sk_r = d_grp_claim_coverage_r_claims.n_claim_coverage_sk_r
                                                                                          AND d_grp_claim_coverage_group_r_claims.v_active_status_r = 'Y'
    LEFT OUTER JOIN dim_grp_claim_event_r                d_grp_claim_event_r_claim
            /* D_GRP_CLAIM_EVENT_R_Claim */ ON d_grp_claim_detail_r_claim.n_claim_event_sk_r = d_grp_claim_event_r_claim.n_claim_event_sk_r
                                                                       AND d_grp_claim_event_r_claim.v_active_status_r = 'Y'
    LEFT OUTER JOIN dim_grp_party_r                      d_grp_party_r_claims
            /* D_GRP_PARTY_R_Claims */ ON d_grp_claim_detail_r_claim.n_insrd_party_sk_r = d_grp_party_r_claims.n_party_sk_r
                                                            AND d_grp_party_r_claims.v_active_status_r = 'Y'
    LEFT OUTER JOIN fct_grp_party_main_address_vw        f_grp_party_address_r_claimant
            /* F_GRP_PARTY_ADDRESS_R_Claimant */ ON d_grp_party_r_claims.n_party_sk_r = f_grp_party_address_r_claimant.n_party_sk_r
                                                                                    AND d_grp_party_r_claims.n_source_version_number_r = f_grp_party_address_r_claimant.n_source_version_number_r
    LEFT OUTER JOIN dim_grp_address_dir_r                d_grp_address_dir_r_claimant
            /* D_GRP_ADDRESS_DIR_R_Claimant */ ON d_grp_address_dir_r_claimant.n_address_sk_r = f_grp_party_address_r_claimant.n_address_sk_r
                                                                          AND d_grp_address_dir_r_claimant.v_active_status_r = 'Y'
    LEFT OUTER JOIN ref_state                            d_ref_state_claimant
            /* D_REF_STATE_Claimant */ ON d_ref_state_claimant.n_state_sk_r = d_grp_address_dir_r_claimant.n_state_sk_r
                                                      AND d_ref_state_claimant.v_active_status_r = 'Y'
    LEFT OUTER JOIN dim_grp_party_r                      d_grp_party_r_party
            /* D_GRP_PARTY_R_Party */ ON d_grp_party_dir_r_party.n_party_sk_r = d_grp_party_r_party.n_party_sk_r
                                                           AND d_grp_party_dir_r_party.n_source_version_number_r = d_grp_party_r_party.n_source_version_number_r
                                                           AND d_grp_party_r_party.v_active_status_r = 'Y'
    LEFT OUTER JOIN fct_grp_party_address_r              fct_grp_party_address_r_customer ON d_grp_party_dir_r_party.n_party_sk_r = fct_grp_party_address_r_customer.n_party_sk_r
                                                                       AND d_grp_party_dir_r_party.n_source_version_number_r = fct_grp_party_address_r_customer.n_source_version_number_r
                                                                       AND upper(fct_grp_party_address_r_customer.v_location_id_r) = 'SITUS'
                                                                       AND upper(fct_grp_party_address_r_customer.v_address_type_r) = 'MAIN'
            --FCT_GRP_PARTY_ADDRESS_R F_GRP_PARTY_ADDRESS_R
            /* F_GRP_PARTY_ADDRESS_R ,*/
    LEFT OUTER JOIN dim_grp_customer_r                   d_grp_customer_r_party
            /* D_GRP_CUSTOMER_R_Party */ ON d_grp_party_dir_r_party.n_party_sk_r = d_grp_customer_r_party.n_cust_party_sk_r
                                                                 AND d_grp_party_dir_r_party.n_source_version_number_r = d_grp_customer_r_party.n_party_version_number_r
                                                                 and d_grp_customer_r_party.v_active_status_r = 'Y'
    LEFT OUTER JOIN dim_grp_carrier_r                    d_grp_carrier_r_party
            /* D_GRP_CARRIER_R_Party */ ON d_grp_customer_r_party.n_carrier_sk_r = d_grp_carrier_r_party.n_carrier_sk_r
                                                               AND d_grp_carrier_r_party.v_active_status_r = 'Y'
WHERE   --AND D_GRP_PARTY_R_PARTY.N_PARTY_SK_R                        = F_GRP_PARTY_ADDRESS_R.N_PARTY_SK_R
    d_grp_policy_dir_r_policy.v_active_status_r = 'Y'
            -- and cast(D_GRP_POLICY_DIR_R_Policy.T_EVENT_TIMESTAMP_R as date) between '01-jan-2020' and '31-dec-2020'
            --and  d_grp_claim_dir_r_claim.v_claim_number_r = '2023-01-19-0265-LTD-01'
    ;

			--24-Jan-2023 changes ends
			UPDATE FCT_PROC_EXEC_STATUS_LOG_R
						SET V_STATUS_R                = 'Successful',
						T_EXECUTION_END_TIMESTAMP_R = systimestamp
						WHERE N_SERIAL_NUM_R          = N_MAX_SERIAL_NUM_R;
						COMMIT;
			EXCEPTION
			WHEN OTHERS THEN
				V_SQLCODE                    := SQLCODE;
						V_SQLERRM                    := SUBSTR(SYS.STANDARD.SQLERRM,1,500);
						UPDATE FCT_PROC_EXEC_STATUS_LOG_R
						SET V_STATUS_R                = 'Failed',
						T_EXECUTION_END_TIMESTAMP_R = systimestamp,
						V_ERROR_CODE_R				= V_SQLCODE,
						V_ERROR_DESC_R				= V_SQLERRM
						WHERE N_SERIAL_NUM_R          = N_MAX_SERIAL_NUM_R;
					COMMIT;
						RAISE;
			END;
		END IF;

		PKG_GRP_COMMON_UTIL.prc_rebuild_indexes
		(
		p_out_job_id   		  		  => gn_out_job_id,
		p_rpt_table			   		  => 'FCT_BILLING_POLICY_PREMIUM_R_TABLE',
		p_idx_num		  		  	  => 8,
		p_Log_seq_num             	  => 1
		);

		PKG_GRP_COMMON_UTIL.prc_set_global_idx_to_no_parallel
		(
		p_table_name   		  		  => 'FCT_BILLING_POLICY_PREMIUM_R_TABLE',
		p_degree			   		  => 1,
		p_out_job_id             	  => gn_out_job_id,
		p_Log_seq_num				  => 1
		);
		/*--17-Jun-2022 changes
		ln_mv_refresh_chk_cnt:=0;
		OPEN cur_mv_refresh_chk('PROC_REFRESH_GRP_M_VIEW_TBLS.F_POLICY_SPECIFIC_MV');
		FETCH cur_mv_refresh_chk INTO ln_mv_refresh_chk_cnt;
		CLOSE cur_mv_refresh_chk;

		IF NVL(ln_mv_refresh_chk_cnt,0) =0 THEN */
		IF UPPER(TRIM(P_MV_TBL_NAME)) like  '%F_POLICY_SPECIFIC_MV%' THEN --17-Jun-2022 changes

			Begin
			SELECT SEQ_FCT_PROC_EXEC_STATUS_LOG_R.NEXTVAL INTO N_MAX_SERIAL_NUM_R FROM DUAL;

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
				LN_BATCH_ID_R,--99999999,
				TO_CHAR(sysdate,'yyyymmdd'),
				1,
				'Started',
				SYSTIMESTAMP,
				USER,
				P_MV_TBL_NAME||'.PROC_REFRESH_GRP_M_VIEW_TBLS.F_POLICY_SPECIFIC_MV',
				N_MAX_SERIAL_NUM_R
				);
			COMMIT;
			--24-Jan-2022 changes starts
			--dbms_mview.refresh('F_POLICY_SPECIFIC_MV', method => 'C', atomic_refresh => FALSE);
			EXECUTE IMMEDIATE 'TRUNCATE TABLE F_POLICY_SPECIFIC_MV_TBL PURGE SNAPSHOT LOG';
			INSERT /*+APPEND_VALUES*/
			INTO F_POLICY_SPECIFIC_MV_TBL
			  (
				POLICY_SKEY                                                   ,
              CLAIM_SKEY                                                    ,
              ADMINISTERED_BY                                               ,
              AS_OF_DATE                                                    ,
              POLICY_PREFIX                                                 ,
              POLICY_SUFFIX                                                 ,
              WORKSHEET_END_DATE                                            ,
              WORKSHEET_START_DATE                                          ,
              CLAIM_CLOSED_DATE                                             ,
              CLAIM_GROSS_BENEFIT_AMOUNT                                    ,
              CLAIM_MOST_RECENT_ACTIVITY_DATE                               ,
              CLAIM_NET_BENEFIT_AMOUNT                                      ,
              CLAIM_NUMBER                                                  ,
              CLAIM_RECEIVED_DATE                                           ,
              CLAIM_TAXABLE_BENEFIT_PERCENTAGE                              ,
              DURATION_INDICATOR                                            ,
              DURATION_PERIOD                                               ,
              ELLIMINATION_PERIOD                                           ,
              LOSS_DATE                                                     ,
              OCCUPATION_CODE                                               ,
              OCCUPATION_DECRIPTION                                         ,
              PLAN_DURATION_DATE                                            ,
              MODIFIED_RTW_DATE                                             ,
              RETURN_TO_WORK_DATE                                           ,
              CLAIM_CLASS_ID                                                ,
              DISABILITY_START_DATE                                         ,
              COVERAGE_TYPE                                                 ,
              PRODUCT_COVERAGE_CODE                                         ,
              COVERAGE_TYPE_CODE                                            ,
              COVERAGE_TYPE_DESCRIPTION                                     ,
              EXAMINER_DEPARTMENT_CODE                                      ,
              EXAMINER_LOGIN_ID                                             ,
              EXAMINER_NAME                                                 ,
              VOCATIONAL_REHAB_ACTIVE_STATUS                                ,
              VOCATIONAL_REHAB_OUTCOME                                      ,
              VOCATIONAL_REHAB_SERVICE_REQUESTED_OTHER                      ,
              VOCATIONAL_REHAB_SERVICE_REQUESTED                            ,
              CLAIM_IDENTIFER                                               ,
              ANY_OCC_DECISION_MADE_DATE                                    ,
              ANY_OCC_PERIOD_INDICATOR                                      ,
              OWN_OCC_PERIOD                                                ,
              ANY_OCC_START_DATE                                            ,
              CLAIM_COVERAGE_DESCRIPTION                                    ,
              COVERAGE_GROUP_CODE                                           ,
              CLAIM_STATUS_CATEGORY                                         ,
              CLAIM_STATUS_DESCRIPTION                                      ,
              CLAIM_STATUS_EFFECTIVE_DATE                                   ,
              CLAIM_TYPE                                                    ,
              CLAIM_STATUS_CODE                                             ,
              PRIOR_STATUS_CODE                                             ,
              CLAIMANT_NAME                                                 ,
              CLAIMANT_GENDER                                               ,
              CLAIMANT_DOB                                                  ,
              CLAIMANT_AGE                                                  ,
              CLAIMANT_HIERDATE                                             ,
              CLAIM_COMPANY_NAME                                            ,
              CLAIM_COMPANY_CODE                                            ,
              LOCATION_NAME                                                 ,
              LOCATION_NUMBER                                               ,
              LOCATION_ID                                                   ,
              SITUS_STATE                                                   ,
              INSURED_STATE                                                 ,
              CLAIMANT_ADDRESS1                                             ,
              CLAIMANT_ADDRESS2                                             ,
              CLAIMANT_ADDRESS3                                             ,
              CLAIMANT_CITY                                                 ,
              CLAIMANT_ZIPCODE                                              ,
              CERTIFICATE_NUMBER                                            ,
              CLAIMANT_SALARY                                               ,
              CLAIMANT_SALARY_INDICATOR                                     ,
              ANN_PREMIUM_CYCLE_DATE                                        ,
              PRIMARY_DIAGNOSIS_CODE                                        ,
              PRIMARY_DIAGNOSIS_CODE_DESCRIPTION                            ,
              PRIMARY_DIAGNOSIS_CATEGORY_DESCRIPTION                        ,
              PRIMARY_DIAGNOSIS_CATEGORY                                    ,
              ADDITIONAL_DIAGNOSIS_CODE_DESCRIPTION                         ,
              ADDITIONAL_DIAGNOSIS_CODE                                     ,
              ADDITIONAL_DIAGNOSIS_CATEGORY_DESCRIPTION                     ,
              ADDITIONAL_DIAGNOSIS_CATEGORY                                 ,
              REHABILITATION_OFFSET_AMOUNT_088                              ,
              WORKERS_COMPENSATION_OFFSET_AMOUNT_083                        ,
              OTHER_OFFSET_AMOUNTS                                          ,
              REHABILITATION_OFFSET_INDICATOR_088                           ,
              WORK_INCENTIVE_EXCESS_OFFSET_INDICATOR_188                    ,
              CLAIM_AGE                                                     ,
              CLAIM_COUNT                                                   ,
              SOCIAL_SECURITY_PRIMARY_AWARD_AMOUNT                          ,
              SOCIAL_SECURITY_PRIMARY_AWARD_STATUS                          ,
              SOCIAL_SECURITY_PRIMARY_AWARD_TYPE                            ,
              SOCIAL_SECURITY_PRIMARY_AWARD_EFFECTIVE_DATE                  ,
              SOCIAL_SECURITY_PRIMARY_AWARD_TERMINATION_DATE                ,
              SOCIAL_SECURITY_DEPENDENT_AWARD_AMOUNT                        ,
              SOCIAL_SECURITY_DEPENDENT_AWARD_STATUS                        ,
              SOCIAL_SECURITY_DEPENDENT_AWARD_TYPE                          ,
              SOCIAL_SECURITY_DEPENDENT_AWARD_EFFECTIVE_DATE                ,
              SOCIAL_SECURITY_DEPENDENT_AWARD_TERMINATION_DATE              ,
              ACH_INDICATOR                                                 ,
              MOST_RECENT_SERVICE_PERIOD_FROM_DATE                          ,
              MOST_RECENT_SERVICE_PERIOD_TO_DATE                            ,
              EARLIEST_BENEFIT_PAYMENT_DATE                                 ,
              LAST_BENEFIT_PAYMENT_DATE                                     ,
              CLAIM_TOTAL_PAID_NET_AMOUNT                                   ,
              CLAIM_TOTAL_PAID_TAXABLE_AMOUNT                               ,
              CLAIM_TOTAL_PAID_LOSS_AMOUNT                                  ,
              CLAIM_TOTAL_PAID_GROSS_AMT                                    ,
              CLAIM_MODAL_AMOUNT                                            ,
              D_LAST_IN_STATUS_46_DATE_R                                    ,
              PRIVACY_INDICATOR
              --23-Jul-2023 changes starts
			  ,DIRECTOR_FULL_NAME
			  ,SUPERVISOR_FULL_NAME
			  ,DIRECTOR_LOGIN_ID
			  ,SUPERVISOR_LOGIN_ID
			  --,NURSE_CERT_OWN_OCC
			  ,NURSE_CERT_END_DATE
			  ,NURSE_CERT_FLAG
			  ,TIER_CREATED_DATE
			  ,TIER
              --23-Jul-2023 changes ends
			  ,CURRENT_RESERVE --26-Oct-2023 changes
			  ,Policy_effective_date --26-Mar-2024 changes
              --27-Mar-2024 changes starts
			  ,N_PRODUCT_SK_R             
              ,V_BASIC_PRODUCT_LINE_CODE_R
              ,V_BASIC_PRODUCT_LINE_DESC_R
              --27-Mar-2024 changes ends
			  ,CLIENT_NAME --07-May-2024 changes
			  ,v_distribution_channel_r --03/04/25 mgis changes
			  )
			SELECT
          DISTINCT F_PSR_CLAIM_MV_1.POLICY_SKEY POLICY_SKEY,
          F_PSR_CLAIM_MV_1.Claim_Skey AS Claim_Skey,
          F_PSR_CLAIM_MV_1.Administered_By,

          F_PSR_CLAIM_MV_1.AS_OF_DATE,
          F_PSR_CLAIM_MV_1.POLICY_PREFIX,
          F_PSR_CLAIM_MV_1.POLICY_SUFFIX,
          F_PSR_CLAIM_MV_1.WORKSHEET_END_DATE WORKSHEET_END_DATE,
          F_PSR_CLAIM_MV_1.WORKSHEET_START_DATE WORKSHEET_START_DATE,
          F_PSR_CLAIM_MV_1.CLAIM_CLOSED_DATE,
          F_PSR_CLAIM_MV_1.CLAIM_GROSS_BENEFIT_AMOUNT,
          F_PSR_CLAIM_MV_1.CLAIM_MOST_RECENT_ACTIVITY_DATE ,
          F_PSR_CLAIM_MV_1.CLAIM_NET_BENEFIT_AMOUNT,
          F_PSR_CLAIM_MV_1.CLAIM_NUMBER,
          F_PSR_CLAIM_MV_1.CLAIM_RECEIVED_DATE,
          F_PSR_CLAIM_MV_1.CLAIM_TAXABLE_BENEFIT_PERCENTAGE ,
          F_PSR_CLAIM_MV_1.DURATION_INDICATOR,
          F_PSR_CLAIM_MV_1.DURATION_PERIOD,
          F_PSR_CLAIM_MV_1.ELLIMINATION_PERIOD,
          F_PSR_CLAIM_MV_1.LOSS_DATE,
          F_PSR_CLAIM_MV_1.OCCUPATION_CODE,
          F_PSR_CLAIM_MV_1.OCCUPATION_DECRIPTION,
          F_PSR_CLAIM_MV_1.PLAN_DURATION_DATE,
          F_PSR_CLAIM_MV_1.MODIFIED_RTW_DATE,
          F_PSR_CLAIM_MV_1.RETURN_TO_WORK_DATE,
          F_PSR_CLAIM_MV_1.CLAIM_CLASS_ID ,
          F_PSR_CLAIM_MV_1.DISABILITY_START_DATE ,
          F_PSR_CLAIM_MV_2.COVERAGE_TYPE ,
          F_PSR_CLAIM_MV_2.PRODUCT_COVERAGE_CODE ,
          F_PSR_CLAIM_MV_2.COVERAGE_TYPE_CODE ,
          F_PSR_CLAIM_MV_2.COVERAGE_TYPE_DESCRIPTION ,
          F_PSR_CLAIM_MV_2.EXAMINER_DEPARTMENT_CODE ,
          F_PSR_CLAIM_MV_2.EXAMINER_LOGIN_ID ,
          F_PSR_CLAIM_MV_2.EXAMINER_NAME ,
          F_PSR_CLAIM_MV_2.VOCATIONAL_REHAB_ACTIVE_STATUS ,
          F_PSR_CLAIM_MV_2.VOCATIONAL_REHAB_OUTCOME ,
          F_PSR_CLAIM_MV_2.VOCATIONAL_REHAB_SERVICE_REQUESTED_OTHER ,
          F_PSR_CLAIM_MV_2.VOCATIONAL_REHAB_SERVICE_REQUESTED ,
          F_PSR_CLAIM_MV_2.CLAIM_IDENTIFER ,
          --F_PSR_CLAIM_MV_2.DISABILITY_START_DATE                             ,
          F_PSR_CLAIM_MV_2.ANY_OCC_DECISION_MADE_DATE ,
          F_PSR_CLAIM_MV_2.ANY_OCC_PERIOD_INDICATOR ,
          F_PSR_CLAIM_MV_2.OWN_OCC_PERIOD ,
          F_PSR_CLAIM_MV_2.ANY_OCC_START_DATE ,
          F_PSR_CLAIM_MV_2.CLAIM_COVERAGE_DESCRIPTION ,
          F_PSR_CLAIM_MV_2.COVERAGE_GROUP_CODE ,
          F_PSR_CLAIM_MV_2.CLAIM_STATUS_CATEGORY ,
          F_PSR_CLAIM_MV_2.CLAIM_STATUS_DESCRIPTION ,
          F_PSR_CLAIM_MV_2.CLAIM_STATUS_EFFECTIVE_DATE ,
          F_PSR_CLAIM_MV_2.CLAIM_TYPE ,
          F_PSR_CLAIM_MV_2.CLAIM_STATUS_CODE ,
          F_PSR_CLAIM_MV_2.PRIOR_STATUS_CODE ,
          F_PSR_CLAIM_MV_2.CLAIMANT_NAME ,
          F_PSR_CLAIM_MV_2.CLAIMANT_GENDER ,
          F_PSR_CLAIM_MV_2.CLAIMANT_DOB ,
          F_PSR_CLAIM_MV_2.CLAIMANT_AGE ,
          F_PSR_CLAIM_MV_2.CLAIMANT_HIERDATE ,
          F_PSR_CLAIM_MV_2.CLAIM_COMPANY_NAME ,
          F_PSR_CLAIM_MV_2.CLAIM_COMPANY_CODE ,
          F_PSR_CLAIM_MV_2.LOCATION_NAME ,
          F_PSR_CLAIM_MV_2.LOCATION_NUMBER ,
          F_PSR_CLAIM_MV_2.LOCATION_ID ,
          F_PSR_CLAIM_MV_2.SITUS_STATE ,
          F_PSR_CLAIM_MV_2.INSURED_STATE ,
          F_PSR_CLAIM_MV_2.CLAIMANT_ADDRESS1 ,
          F_PSR_CLAIM_MV_2.CLAIMANT_ADDRESS2 ,
          F_PSR_CLAIM_MV_2.CLAIMANT_ADDRESS3 ,
          F_PSR_CLAIM_MV_2.CLAIMANT_CITY ,
          F_PSR_CLAIM_MV_2.CLAIMANT_ZIPCODE ,
          F_PSR_CLAIM_MV_2.CERTIFICATE_NUMBER ,
          F_PSR_CLAIM_MV_2.CLAIMANT_SALARY ,
          F_PSR_CLAIM_MV_2.CLAIMANT_SALARY_INDICATOR ,
          F_PSR_CLAIM_MV_3.ANN_PREMIUM_CYCLE_DATE ,
          F_PSR_CLAIM_MV_3.PRIMARY_DIAGNOSIS_CODE             AS PRIMARY_DIAGNOSIS_CODE ,
          F_PSR_CLAIM_MV_3.PRIMARY_DIAGNOSIS_CODE_DESCRIPTION AS PRIMARY_DIAGNOSIS_CODE_DESCRIPTION ,
          F_PSR_CLAIM_MV_3.PRIMARY_DIAGNOSIS_CATEGORY_DESCRIPTION ,
          F_PSR_CLAIM_MV_3.PRIMARY_DIAGNOSIS_CATEGORY ,
          F_PSR_CLAIM_MV_3.ADDITIONAL_DIAGNOSIS_CODE_DESCRIPTION ,
          F_PSR_CLAIM_MV_3.ADDITIONAL_DIAGNOSIS_CODE ,
          F_PSR_CLAIM_MV_3.ADDITIONAL_DIAGNOSIS_CATEGORY_DESCRIPTION ,
          F_PSR_CLAIM_MV_3.ADDITIONAL_DIAGNOSIS_CATEGORY ,
          F_PSR_CLAIM_MV_4.REHABILITATION_OFFSET_AMOUNT_088 ,
          F_PSR_CLAIM_MV_4.WORKERS_COMPENSATION_OFFSET_AMOUNT_083 ,
          F_PSR_CLAIM_MV_4.OTHER_OFFSET_AMOUNTS ,
          F_PSR_CLAIM_MV_4.REHABILITATION_OFFSET_INDICATOR_088 ,
          F_PSR_CLAIM_MV_4.WORK_INCENTIVE_EXCESS_OFFSET_INDICATOR_188 ,
          --22-Mar-2023 changes starts
          --F_PSR_CLAIM_MV_3.CLAIM_AGE ,
           case when F_PSR_CLAIM_MV_3.CLAIM_AGE is null
           then F_PSR_CLAIM_MV_1.AS_OF_DATE - F_PSR_CLAIM_MV_1.CLAIM_RECEIVED_DATE
           else F_PSR_CLAIM_MV_3.CLAIM_AGE
           end CLAIM_AGE,
          --22-Mar-2023 changes ends
          F_PSR_CLAIM_MV_3.CLAIM_COUNT ,
          F_PSR_CLAIM_MV_3.SOCIAL_SECURITY_PRIMARY_AWARD_AMOUNT ,
          F_PSR_CLAIM_MV_3.SOCIAL_SECURITY_PRIMARY_AWARD_STATUS ,
          F_PSR_CLAIM_MV_3.SOCIAL_SECURITY_PRIMARY_AWARD_TYPE ,
          F_PSR_CLAIM_MV_3.SOCIAL_SECURITY_PRIMARY_AWARD_EFFECTIVE_DATE ,
          F_PSR_CLAIM_MV_3.SOCIAL_SECURITY_PRIMARY_AWARD_TERMINATION_DATE ,
          F_PSR_CLAIM_MV_3.SOCIAL_SECURITY_DEPENDENT_AWARD_AMOUNT ,
          F_PSR_CLAIM_MV_3.SOCIAL_SECURITY_DEPENDENT_AWARD_STATUS ,
          F_PSR_CLAIM_MV_3.SOCIAL_SECURITY_DEPENDENT_AWARD_TYPE ,
          F_PSR_CLAIM_MV_3.SOCIAL_SECURITY_DEPENDENT_AWARD_EFFECTIVE_DATE ,
          F_PSR_CLAIM_MV_3.SOCIAL_SECURITY_DEPENDENT_AWARD_TERMINATION_DATE ,
          F_PSR_CLAIM_MV_4.ACH_INDICATOR ,
          F_PSR_CLAIM_MV_4.MOST_RECENT_SERVICE_PERIOD_FROM_DATE ,
          F_PSR_CLAIM_MV_4.MOST_RECENT_SERVICE_PERIOD_TO_DATE ,
          F_PSR_CLAIM_MV_4.EARLIEST_BENEFIT_PAYMENT_DATE ,
          F_PSR_CLAIM_MV_4.LAST_BENEFIT_PAYMENT_DATE ,
          F_PSR_CLAIM_MV_4.CLAIM_TOTAL_PAID_NET_AMOUNT ,
          F_PSR_CLAIM_MV_4.CLAIM_TOTAL_PAID_TAXABLE_AMOUNT ,
          F_PSR_CLAIM_MV_4.CLAIM_TOTAL_PAID_LOSS_AMOUNT ,
          F_PSR_CLAIM_MV_4.CLAIM_TOTAL_PAID_GROSS_AMT ,
          F_PSR_CLAIM_MV_4.CLAIM_MODAL_AMOUNT,
		  F_PSR_CLAIM_MV_2.D_LAST_IN_STATUS_46_DATE_R,
		  F_PSR_CLAIM_MV_1.PRIVACY_INDICATOR
          --23-Jul-2023 changes starts
		 ,F_PSR_CLAIM_MV_2.DIRECTOR_FULL_NAME
		 ,F_PSR_CLAIM_MV_2.SUPERVISOR_FULL_NAME
		 ,F_PSR_CLAIM_MV_2.DIRECTOR_LOGIN_ID
		 ,F_PSR_CLAIM_MV_2.SUPERVISOR_LOGIN_ID
		 --,F_PSR_CLAIM_MV_2.NURSE_CERT_OWN_OCC
		 ,F_PSR_CLAIM_MV_2.NURSE_CERT_END_DATE
		 ,F_PSR_CLAIM_MV_2.NURSE_CERT_FLAG
		 ,TIER_MV.D_CREATED_DATE_R  TIER_CREATED_DATE
		 ,TIER_MV.V_TIER_R TIER
          --23-Jul-2023 changes ends
		 ,F_PSR_CLAIM_MV_1.CURRENT_RESERVE --26-Oct-2023 changes
		 ,F_PSR_CLAIM_MV_1.Policy_effective_date--26-Mar-2024 changes
         --27-Mar-2024 changes starts
		 ,F_PSR_CLAIM_MV_2.N_PRODUCT_SK_R             
         ,F_PSR_CLAIM_MV_2.V_BASIC_PRODUCT_LINE_CODE_R
         ,F_PSR_CLAIM_MV_2.V_BASIC_PRODUCT_LINE_DESC_R
         --27-Mar-2024 changes ends
	     ,F_PSR_CLAIM_MV_2.CLIENT_NAME --07-May-2024 changes
		 ,s.v_distribution_channel_r --03/04/25 mgis changes
        FROM F_PSR_CLAIM_MV_1_TBL F_PSR_CLAIM_MV_1
        LEFT OUTER JOIN
          (SELECT DISTINCT F_PSR_CLAIM_COV_STATUS_MV.POLICY_SKEY POLICY_SKEY ,
            F_PSR_CLAIM_COV_STATUS_MV.CLAIM_SKEY CLAIM_SKEY ,
            F_PSR_CLAIM_COV_STATUS_MV.AS_OF_DATE AS_OF_DATE ,
            F_PSR_CLAIM_COV_STATUS_MV.COVERAGE_TYPE COVERAGE_TYPE ,
            F_PSR_CLAIM_COV_STATUS_MV.PRODUCT_COVERAGE_CODE PRODUCT_COVERAGE_CODE ,
            F_PSR_CLAIM_COV_STATUS_MV.COVERAGE_TYPE_CODE COVERAGE_TYPE_CODE ,
            F_PSR_CLAIM_COV_STATUS_MV.COVERAGE_TYPE_DESCRIPTION COVERAGE_TYPE_DESCRIPTION ,
            F_PSR_CLAIM_COV_STATUS_MV.EXAMINER_DEPARTMENT_CODE EXAMINER_DEPARTMENT_CODE ,
            F_PSR_CLAIM_COV_STATUS_MV.EXAMINER_LOGIN_ID EXAMINER_LOGIN_ID ,
            F_PSR_CLAIM_COV_STATUS_MV.EXAMINER_NAME EXAMINER_NAME ,
            F_PSR_CLAIM_COV_STATUS_MV.VOCATIONAL_REHAB_ACTIVE_STATUS VOCATIONAL_REHAB_ACTIVE_STATUS ,
            F_PSR_CLAIM_COV_STATUS_MV.VOCATIONAL_REHAB_OUTCOME VOCATIONAL_REHAB_OUTCOME ,
            F_PSR_CLAIM_COV_STATUS_MV.VOCATIONAL_REHAB_SERVICE_REQUESTED_OTHER VOCATIONAL_REHAB_SERVICE_REQUESTED_OTHER ,
            F_PSR_CLAIM_COV_STATUS_MV.VOCATIONAL_REHAB_SERVICE_REQUESTED VOCATIONAL_REHAB_SERVICE_REQUESTED ,
            F_PSR_CLAIM_COV_STATUS_MV.CLAIM_IDENTIFER CLAIM_IDENTIFER ,
             F_PSR_CLAIM_COV_STATUS_MV.D_LAST_IN_STATUS_46_DATE_R,
            --F_PSR_CLAIM_COV_STATUS_MV.DISABILITY_START_DATE  DISABILITY_START_DATE                           ,
            F_PSR_CLAIM_COV_STATUS_MV.ANY_OCC_DECISION_MADE_DATE ANY_OCC_DECISION_MADE_DATE ,
            F_PSR_CLAIM_COV_STATUS_MV.ANY_OCC_PERIOD_INDICATOR ANY_OCC_PERIOD_INDICATOR ,
            F_PSR_CLAIM_COV_STATUS_MV.OWN_OCC_PERIOD OWN_OCC_PERIOD ,
            F_PSR_CLAIM_COV_STATUS_MV.ANY_OCC_START_DATE ANY_OCC_START_DATE ,
            F_PSR_CLAIM_COV_STATUS_MV.CLAIM_COVERAGE_DESCRIPTION CLAIM_COVERAGE_DESCRIPTION ,
            F_PSR_CLAIM_COV_STATUS_MV.COVERAGE_GROUP_CODE COVERAGE_GROUP_CODE ,
            F_PSR_CLAIM_COV_STATUS_MV.CLAIM_STATUS_CATEGORY CLAIM_STATUS_CATEGORY ,
            F_PSR_CLAIM_COV_STATUS_MV.CLAIM_STATUS_DESCRIPTION CLAIM_STATUS_DESCRIPTION ,
            F_PSR_CLAIM_COV_STATUS_MV.CLAIM_STATUS_EFFECTIVE_DATE CLAIM_STATUS_EFFECTIVE_DATE ,
            F_PSR_CLAIM_COV_STATUS_MV.CLAIM_TYPE CLAIM_TYPE ,
            F_PSR_CLAIM_COV_STATUS_MV.CLAIM_STATUS_CODE CLAIM_STATUS_CODE ,
            F_PSR_CLAIM_COV_STATUS_MV.PRIOR_STATUS_CODE PRIOR_STATUS_CODE ,
            --F_PSR_CLAIMANT_MV.Claim_Identifer  Claim_Identifer,
            F_PSR_CLAIMANT_MV.CLAIMANT_NAME CLAIMANT_NAME ,
            F_PSR_CLAIMANT_MV.CLAIMANT_GENDER CLAIMANT_GENDER ,
            F_PSR_CLAIMANT_MV.CLAIMANT_DOB CLAIMANT_DOB ,
            F_PSR_CLAIMANT_MV.CLAIMANT_AGE CLAIMANT_AGE ,
            F_PSR_CLAIMANT_MV.CLAIMANT_HIERDATE CLAIMANT_HIERDATE ,
            F_PSR_CLAIMANT_MV.CLAIM_COMPANY_NAME CLAIM_COMPANY_NAME ,
            F_PSR_CLAIMANT_MV.CLAIM_COMPANY_CODE CLAIM_COMPANY_CODE ,
            F_PSR_CLAIMANT_MV.LOCATION_NAME LOCATION_NAME ,
            F_PSR_CLAIMANT_MV.LOCATION_NUMBER LOCATION_NUMBER ,
            F_PSR_CLAIMANT_MV.LOCATION_ID LOCATION_ID ,
            F_PSR_CLAIMANT_MV.SITUS_STATE SITUS_STATE ,
            F_PSR_CLAIMANT_MV.INSURED_STATE INSURED_STATE ,
            F_PSR_CLAIMANT_MV.CLAIMANT_ADDRESS1 CLAIMANT_ADDRESS1 ,
            F_PSR_CLAIMANT_MV.CLAIMANT_ADDRESS2 CLAIMANT_ADDRESS2 ,
            F_PSR_CLAIMANT_MV.CLAIMANT_ADDRESS3 CLAIMANT_ADDRESS3 ,
            F_PSR_CLAIMANT_MV.CLAIMANT_CITY CLAIMANT_CITY ,
            F_PSR_CLAIMANT_MV.CLAIMANT_ZIPCODE CLAIMANT_ZIPCODE ,
            F_PSR_CLAIMANT_MV.CERTIFICATE_NUMBER CERTIFICATE_NUMBER ,
            F_PSR_CLAIMANT_MV.CLAIMANT_SALARY CLAIMANT_SALARY ,
            F_PSR_CLAIMANT_MV.CLAIMANT_SALARY_INDICATOR CLAIMANT_SALARY_INDICATOR
            --23-Jul-2023 changes starts
			,F_PSR_CLAIM_COV_STATUS_MV.DIRECTOR_FULL_NAME
			,F_PSR_CLAIM_COV_STATUS_MV.SUPERVISOR_FULL_NAME
			,F_PSR_CLAIM_COV_STATUS_MV.DIRECTOR_LOGIN_ID
			,F_PSR_CLAIM_COV_STATUS_MV.SUPERVISOR_LOGIN_ID
			--,F_PSR_CLAIM_COV_STATUS_MV.NURSE_CERT_OWN_OCC NURSE_CERT_OWN_OCC
			,F_PSR_CLAIM_COV_STATUS_MV.NURSE_CERT_END_DATE
			,F_PSR_CLAIM_COV_STATUS_MV.NURSE_CERT_FLAG
            --23-Jul-2023 changes ends
            --27-Mar-2024 changes starts
		    ,F_PSR_CLAIM_COV_STATUS_MV.N_PRODUCT_SK_R             
            ,F_PSR_CLAIM_COV_STATUS_MV.V_BASIC_PRODUCT_LINE_CODE_R
            ,F_PSR_CLAIM_COV_STATUS_MV.V_BASIC_PRODUCT_LINE_DESC_R
            --27-Mar-2024 changes ends
			,F_PSR_CLAIMANT_MV.CLIENT_NAME --07-May-2024 changes
          from F_PSR_CLAIM_COV_STATUS_MV_TBL F_PSR_CLAIM_COV_STATUS_MV
          INNER JOIN F_PSR_CLAIMANT_MV_TBL F_PSR_CLAIMANT_MV
          ON F_PSR_CLAIM_COV_STATUS_MV.POLICY_SKEY               = F_PSR_CLAIMANT_MV.POLICY_SKEY
          AND F_PSR_CLAIM_COV_STATUS_MV.CLAIM_SKEY               = F_PSR_CLAIMANT_MV.CLAIM_SKEY
          AND F_PSR_CLAIM_COV_STATUS_MV.AS_OF_DATE               =F_PSR_CLAIMANT_MV.AS_OF_DATE
          AND NVL(F_PSR_CLAIM_COV_STATUS_MV.CLAIM_IDENTIFER,' ') = NVL(F_PSR_CLAIMANT_MV.CLAIM_IDENTIFER,' ')
          )F_PSR_CLAIM_MV_2 ON F_PSR_CLAIM_MV_1.Policy_skey      = F_PSR_CLAIM_MV_2.Policy_skey
        AND F_PSR_CLAIM_MV_1.claim_skey                          =F_PSR_CLAIM_MV_2.claim_skey
        AND F_PSR_CLAIM_MV_1.AS_OF_DATE                          =F_PSR_CLAIM_MV_2.AS_OF_DATE
        AND NVL(F_PSR_CLAIM_MV_1.CLAIM_IDENTIFIER,' ')           = NVL(F_PSR_CLAIM_MV_2.CLAIM_IDENTIFER,' ')
        LEFT OUTER JOIN F_PSR_CLAIM_MV_3_TBL F_PSR_CLAIM_MV_3
        ON F_PSR_CLAIM_MV_2.Policy_skey               =F_PSR_CLAIM_MV_3.Policy_skey
        AND F_PSR_CLAIM_MV_2.claim_skey               =F_PSR_CLAIM_MV_3.claim_skey
        AND F_PSR_CLAIM_MV_2.AS_OF_DATE               =F_PSR_CLAIM_MV_3.AS_OF_DATE
        AND NVL(F_PSR_CLAIM_MV_2.CLAIM_IDENTIFER,' ') = NVL(F_PSR_CLAIM_MV_3.CLAIM_IDENTIFIER,' ')
        LEFT OUTER JOIN F_PSR_CLAIM_MV_4_TBL F_PSR_CLAIM_MV_4
        ON F_PSR_CLAIM_MV_1.POLICY_SKEY =F_PSR_CLAIM_MV_4.N_POLICY_SK_R
        AND F_PSR_CLAIM_MV_1.CLAIM_SKEY =F_PSR_CLAIM_MV_4.N_CLAIM_SK_R
         AND NVL(F_PSR_CLAIM_MV_1.CLAIM_IDENTIFIER,' ') = NVL(F_PSR_CLAIM_MV_4.v_claim_identifier_r,' ')
		 --23-Jul-2023 changes 8.b starts
		LEFT OUTER JOIN CLAIM_NOTE_TIER_MV TIER_MV
         ON TIER_MV.N_CLAIM_SK_R = F_PSR_CLAIM_MV_1.Claim_Skey
		 --23-Jul-2023 changes 8.b ends
         LEFT JOIN
		  (SELECT  distinct N_POLICY_SK_R, v_distribution_channel_r FROM ATOMIC.fct_grp_policy_r where v_distribution_channel_r like '%MGIS%'  ) s
ON        F_PSR_CLAIM_MV_1.POLICY_SKEY=s.N_POLICY_SK_R
		 ;

			--24-Jan-2022 changes ends
			UPDATE FCT_PROC_EXEC_STATUS_LOG_R
						SET V_STATUS_R                = 'Successful',
						T_EXECUTION_END_TIMESTAMP_R = systimestamp
						WHERE N_SERIAL_NUM_R          = N_MAX_SERIAL_NUM_R;
						COMMIT;
			EXCEPTION
			WHEN OTHERS THEN
				V_SQLCODE                    := SQLCODE;
						V_SQLERRM                    := SUBSTR(SYS.STANDARD.SQLERRM,1,500);
						UPDATE FCT_PROC_EXEC_STATUS_LOG_R
						SET V_STATUS_R                = 'Failed',
						T_EXECUTION_END_TIMESTAMP_R = systimestamp,
						V_ERROR_CODE_R				= V_SQLCODE,
						V_ERROR_DESC_R				= V_SQLERRM
						WHERE N_SERIAL_NUM_R          = N_MAX_SERIAL_NUM_R;
					COMMIT;
						RAISE;
			END;
		end if;
        --29 March changes starts--
		IF UPPER(TRIM(P_MV_TBL_NAME)) like  '%CLAIM_NOTE_TIER_MV%' THEN

			Begin
				SELECT SEQ_FCT_PROC_EXEC_STATUS_LOG_R.NEXTVAL INTO N_MAX_SERIAL_NUM_R FROM DUAL;

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
					LN_BATCH_ID_R,--99999999,
					TO_CHAR(sysdate,'yyyymmdd'),
					1,
					'Started',
					SYSTIMESTAMP,
					USER,
					P_MV_TBL_NAME||'.PROC_REFRESH_GRP_M_VIEW_TBLS.CLAIM_NOTE_TIER_MV_TBL',
					N_MAX_SERIAL_NUM_R
					);
				COMMIT;


				EXECUTE IMMEDIATE 'TRUNCATE TABLE CLAIM_NOTE_TIER_MV_TBL PURGE SNAPSHOT LOG';

				 INSERT /*+APPEND_VALUES*/ INTO CLAIM_NOTE_TIER_MV_TBL (
				 V_TIER_R           ,
				 N_CLAIM_SK_R       ,
				 V_CLAIM_NUMBER_R   ,
				 D_CREATED_DATE_R   ,
				 RANK
				)
				select distinct * from
				(select a.v_tier_r,  a.n_claim_sk_r ,b.v_claim_number_r,D_CREATED_DATE_R,   RANK() OVER (PARTITION BY a.N_CLAIM_SK_R
				ORDER BY a.D_CREATED_DATE_R DESC,a.V_CREATED_TIME_R DESC, N_CLAIM_SUBSEQUENCE_NUMBER_R DESC) rank
				from
				(select * from FCT_GRP_CLAIM_NOTE_R F where F.N_CLAIM_SK_R >-1
				and f.V_TIER_R is not null
				) a,
				dim_grp_claim_dir_r b
				where
				a.n_claim_sk_r = b.n_claim_sk_r
				and b.v_active_status_r = 'Y'
				--and v_lob_type_r = 'VPL'
				)
				where RANK = 1;

				UPDATE FCT_PROC_EXEC_STATUS_LOG_R
							SET V_STATUS_R                = 'Successful',
							T_EXECUTION_END_TIMESTAMP_R = systimestamp
							WHERE N_SERIAL_NUM_R          = N_MAX_SERIAL_NUM_R;
							COMMIT;
			EXCEPTION
			WHEN OTHERS THEN
				V_SQLCODE                    := SQLCODE;
						V_SQLERRM                    := SUBSTR(SYS.STANDARD.SQLERRM,1,500);
						UPDATE FCT_PROC_EXEC_STATUS_LOG_R
						SET V_STATUS_R                = 'Failed',
						T_EXECUTION_END_TIMESTAMP_R = systimestamp,
						V_ERROR_CODE_R				= V_SQLCODE,
						V_ERROR_DESC_R				= V_SQLERRM
						WHERE N_SERIAL_NUM_R          = N_MAX_SERIAL_NUM_R;
					COMMIT;
						RAISE;
			END;
		END IF;
		--29 March changes ends--
		--16 June changes Starts--
		IF UPPER(TRIM(P_MV_TBL_NAME)) like  '%CLAIM_TIER_WFAM_MV%' THEN

			Begin
				SELECT SEQ_FCT_PROC_EXEC_STATUS_LOG_R.NEXTVAL INTO N_MAX_SERIAL_NUM_R FROM DUAL;
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
					LN_BATCH_ID_R,--99999999,
					TO_CHAR(sysdate,'yyyymmdd'),
					1,
					'Started',
					SYSTIMESTAMP,
					USER,
					P_MV_TBL_NAME||'.PROC_REFRESH_GRP_M_VIEW_TBLS.CLAIM_TIER_WFAM_MV_TBL',
					N_MAX_SERIAL_NUM_R
					);
				COMMIT;


				EXECUTE IMMEDIATE 'TRUNCATE TABLE CLAIM_TIER_WFAM_MV_TBL PURGE SNAPSHOT LOG';



	INSERT /*+APPEND_VALUES*/ INTO  CLAIM_TIER_WFAM_MV_TBL
	(v_tier_r,
	 v_wfam_r,
	 d_prd_r,--04-DEC-2023 Changes
     n_claim_sk_r,
     v_claim_number_r,
     d_created_date_r_tier,
     d_created_date_r_wfam,
	 d_created_date_r_prd,--04-DEC-2023 Changes
     rank_tier,
     rank_wfam,
	 rank_prd--04-DEC-2023 Changes
	)
	WITH claim_note_tier_v AS (
        SELECT DISTINCT
            *
        FROM
            (
                SELECT
                    f.v_tier_r,
                    f.n_claim_sk_r,
                    f.d_created_date_r,
                    RANK()
                    OVER(PARTITION BY f.n_claim_sk_r
                         ORDER BY f.d_created_date_r DESC,
                                  f.v_created_time_r DESC,
                                  f.n_claim_subsequence_number_r DESC
                    ) rank
                FROM
                    fct_grp_claim_note_r f
                WHERE
                        f.n_claim_sk_r > - 1
                    AND f.v_tier_r IS NOT NULL
            )
        WHERE
            rank = 1
    ), claim_note_wfam_v AS (
        SELECT DISTINCT
            *
        FROM
            (
                SELECT
                    f.v_wfam_r,
                    f.n_claim_sk_r,
                    f.d_created_date_r,
                    RANK()
                    OVER(PARTITION BY f.n_claim_sk_r
                         ORDER BY f.d_created_date_r DESC,
                                  f.v_created_time_r DESC,
                                  f.n_claim_subsequence_number_r DESC
								  ,f.T_EVENT_TIMESTAMP_R desc--13-May-2024 changes
                    ) rank
                FROM
                    fct_grp_claim_note_r f
                WHERE
                        f.n_claim_sk_r > - 1
                    AND f.v_wfam_r IS NOT NULL
            )
        WHERE
            rank = 1
    ),CLAIM_NOTE_PRD_V as--04-DEC-2023 Changes Starts
(select distinct * from(
select f.D_PRD_R,f.n_claim_sk_r,f.D_CREATED_DATE_R,RANK() OVER (PARTITION BY f.N_CLAIM_SK_R
                                                          ORDER BY f.D_CREATED_DATE_R DESC,f.V_CREATED_TIME_R DESC, f.N_CLAIM_SUBSEQUENCE_NUMBER_R DESC ,
														  --23/09/24 Changes start
														  f.N_CREATED_ITIME_R DESC)
														  --2309-24 Changes End
														  rank from FCT_GRP_CLAIM_NOTE_R F where F.N_CLAIM_SK_R >-1
                                                          and f.d_prd_r is not null
														   )
                                                          where RANK = 1
)--04-DEC-2023 Changes Ends
    SELECT
        a.v_tier_r,
        b.v_wfam_r,
		c.d_prd_r,--04-DEC-2023 Changes
        dim.n_claim_sk_r,
        dim.v_claim_number_r,
        a.d_created_date_r    AS d_created_date_r_tier,
        b.d_created_date_r    AS d_created_date_r_wfam,
		c.d_created_date_r    as d_created_date_r_prd,--04-DEC-2023 Changes
        a.rank                AS rank_tier,
        b.rank                AS rank_wfam,
		c.rank                as rank_prd--04-DEC-2023 Changes
    FROM
        dim_grp_claim_dir_r  dim
        LEFT OUTER JOIN claim_note_tier_v    a ON dim.n_claim_sk_r = a.n_claim_sk_r
        LEFT OUTER JOIN claim_note_wfam_v    b ON dim.n_claim_sk_r = b.n_claim_sk_r
		LEFT OUTER JOIN claim_note_prd_v     c on dim.n_claim_sk_r = c.n_claim_sk_r	--04-DEC-2023 Changes
    WHERE
            dim.v_active_status_r = 'Y'
        AND ( v_tier_r IS NOT NULL
              OR v_wfam_r IS NOT NULL or d_prd_r is not null );--04-DEC-2023 Changes
    UPDATE FCT_PROC_EXEC_STATUS_LOG_R
							SET V_STATUS_R                = 'Successful',
							T_EXECUTION_END_TIMESTAMP_R = systimestamp
							WHERE N_SERIAL_NUM_R          = N_MAX_SERIAL_NUM_R;
							COMMIT;
			EXCEPTION
			WHEN OTHERS THEN
				V_SQLCODE                    := SQLCODE;
						V_SQLERRM                    := SUBSTR(SYS.STANDARD.SQLERRM,1,500);
						UPDATE FCT_PROC_EXEC_STATUS_LOG_R
						SET V_STATUS_R                = 'Failed',
						T_EXECUTION_END_TIMESTAMP_R = systimestamp,
						V_ERROR_CODE_R				= V_SQLCODE,
						V_ERROR_DESC_R				= V_SQLERRM
						WHERE N_SERIAL_NUM_R          = N_MAX_SERIAL_NUM_R;
					COMMIT;
						RAISE;
			END;
		END IF;


		 --16 June changes ends--
		 --30 March Changes Starts--
		 --18 july 2023 additional columns added given by erica changes starts----
		 IF UPPER(TRIM(P_MV_TBL_NAME)) like  '%FCT_BENEFIT_PAYMENT_DETAIL_OFFSET_MV%' THEN

			Begin
				SELECT SEQ_FCT_PROC_EXEC_STATUS_LOG_R.NEXTVAL INTO N_MAX_SERIAL_NUM_R FROM DUAL;

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
					LN_BATCH_ID_R,--99999999,
					TO_CHAR(sysdate,'yyyymmdd'),
					1,
					'Started',
					SYSTIMESTAMP,
					USER,
					P_MV_TBL_NAME||'.PROC_REFRESH_GRP_M_VIEW_TBLS.FCT_BENEFIT_PAYMENT_DETAIL_OFFSET_MV_TBL',
					N_MAX_SERIAL_NUM_R
					);
				COMMIT;


				EXECUTE IMMEDIATE 'TRUNCATE TABLE FCT_BENEFIT_PAYMENT_DETAIL_OFFSET_MV_TBL PURGE SNAPSHOT LOG';

				 INSERT /*+APPEND_VALUES*/ INTO FCT_BENEFIT_PAYMENT_DETAIL_OFFSET_MV_TBL (
							V_CLAIM_NUMBER_R                       ,
							V_COVERAGE_CODE_R                      ,
							V_COV_GROUP_ID_R                       ,
							V_CHECK_NUMBER_R                       ,
							V_PAY_METHOD_R                         ,
							V_BENEFIT_CODE_R                       ,
							V_BENEFIT_DESCRIPTION_R                ,
							V_BENEFIT_GROUP_R                      ,
							N_GROSS_WAGE_BASE_R                    ,
							N_TAXABLE_PERCENT_R                    ,
							V_PAYMENT_STATUS_R                     ,
							N_PAID_AMOUNT_R                        ,
							V_PAYMENT_TYPE_R                       ,
							D_CHECK_DATE_R                         ,
							V_CHECK_TYPE_R                         ,
							D_PAID_DATE_R                          ,
							N_GROSS_AMOUNT_R                       ,
							D_SERVICE_PERIOD_FROM_R                ,
							D_SERVICE_PERIOD_TO_R                  ,
							V_OFFSET_TYPE_R                        ,--04-May-2023 changes
							V_RECORD_TYPE_R                        ,
							N_WORKSHEET_OBJECT_NUM_R               ,
							N_SOURCE_SYSTEM_KEY_R                  ,
							N_SOURCE_VERSION_SEQ_NUMBER_R          ,
							N_SEQ_R                                ,
							N_GROUP_SEQ_R                          ,
							N_PARENT_OBJECTNUM_R                   ,
							T_CREATION_DATE_R                      ,
							T_EVENT_TIMESTAMP_R                    ,
							T_LAST_MODIFIED_DATE_R                 ,
							V_CREATED_BY_R                         ,
							V_LAST_MODIFIED_BY_R                   ,
							FIC_MIS_DATE_R                         ,
							N_BATCH_ID_R                           ,
							N_LOAD_RUN_ID_R                        ,
							N_SEQUENCE_NUMBER_R                    ,
							V_BENEFIT_CATEGORY_R                   ,
							N_PAID_CLAIM_BENEFITS_R                ,
							N_TAXABLE_BENEFIT_AMT_R                ,
							N_FEDERAL_TAX_WITHHELD_AMT_R           ,
							N_STATE_TAX_WITHHELD_AMT_R             ,
							N_EMPLOYEE_SS_WITHHELD_AMT_R           ,
							N_EMPLOYEE_MED_WITHHELD_AMT_R          ,
							N_EMPLOYER_SS_WITHHELD_AMT_R           ,
							N_EMPLOYER_MED_WITHHELD_AMT_R          ,
							N_LEGAL_EXPENSE_DIRECT_AMT_R           ,
							N_OTHER_EXPENSE_DIRECT_AMT_R           ,
							V_LOB_TYPE_R                           ,
							N_MODAL_AMOUNT_R                       ,
							N_PRIMARY_PAYEE_R                      ,
							N_ADJ_GROSS_BENEFIT_R                  ,
							N_PAY_AMOUNT_R                         ,
							N_CLAIM_SK_R                           ,
							V_GROSS_BENEFIT_CODE_R                 ,
							N_CLAIM_COVERAGE_SK_R                  ,
							N_CLAIM_COVERAGE_GROUP_SK_R            ,
							N_FBPR_N_SEQ_R                         ,
							V_PRIVACY_INDICATOR_R				   ,
							V_PAYEE_FIRST_NAME_R                   ,	--31-JAN-2024 Changes
							V_PAYEE_MIDDLE_NAME_R                  ,	--31-JAN-2024 Changes
							V_PAYEE_LAST_NAME_R					   ,	--31-JAN-2024 Changes
							V_PAYEE_TYPE_R						   ,	--31-JAN-2024 Changes
							N_PARTY_SK_R								--12-MAR-2024 Changes
	                        --29-May-2024 changes starts
                            ,V_AMOUNT_TYPE_SUB_NAME_R
                            ,V_AMOUNT_TYPE_CATEGORY_R
                            ,V_AMOUNT_TYPE_CATEGORY_DESC_R
                            ,V_AMOUNT_TYPE_SUB_CATEGORY_R
                            ,V_AMT_TYPE_SUB_CATEGORY_DESC_R
                            ,V_AMOUNT_TYPE_CODE_R
                            ,V_AMOUNT_TYPE_NAME_R
                            ,V_AMOUNT_TYPE_SUB_CODE_R
	                        --29-May-2024 changes ends
				)
				SELECT
		DGCDR.v_claim_number_r                                                                                       V_CLAIM_NUMBER_R
		,NVL(DGCCGR.V_CLAIM_COVERAGE_CODE_R,DGCCR.V_CLAIM_COVERAGE_CODE_R)                                           V_COVERAGE_CODE_R--11-aUG-2021 As per Erica's request mapping has been changed from DGCCR.V_COVERAGE_CODE_R
		,DGCCGR.N_COV_GRP_ID_R                                                                                       V_COV_GROUP_ID_R --11-aUG-2021 As per Erica's request mapping has been changed from V_COV_GRP_CODE_R to N_COV_GRP_ID_R
		,FBPR.V_CHECK_NUM_R                                                                                          V_CHECK_NUMBER_R
		,FBPR.V_PAY_METHOD_R                                                                                         V_PAY_METHOD_R
		,FBPDR.V_AMOUNT_TYPE_SUB_CODE_R                                                                              V_BENEFIT_CODE_R
		,FBPDR.V_AMOUNT_TYPE_NAME_R                                                                                  V_BENEFIT_DESCRIPTION_R
		,FBPDR.V_AMOUNT_TYPE_CODE_R                                                                                  V_BENEFIT_GROUP_R
		,( CASE WHEN FBPDR.V_BENEFIT_CODE_R IN ('098','FIC','298','MED')
		THEN NVL(FBPR.N_MED_WAGE_BASE_R,0) + NVL(FBPR.N_SS_WAGE_BASE_R,0)
		ELSE 0
		END
		)                                                                                                            N_GROSS_WAGE_BASE_R
		/*,FGW.N_TAXABLE_OVERRIDE_PCT_R                                                                                N_TAXABLE_PERCENT_R*/ --23-JUL-2025 Commented as per new request.  
		,CASE WHEN DGCDR.V_CLAIM_NUMBER_R LIKE '%SC%' 
			THEN (100-FGW.N_EXCLUSION_RATIO_R)
		ELSE FGW.N_TAXABLE_OVERRIDE_PCT_R    --23-JUL-2025 Adding as per new mapping logic.
		END AS N_TAXABLE_PERCENT_R 
		,DECODE(UPPER(TRIM(FBPR.V_PAY_STATUS_R)),'REVERSAL','VOID','PAID')                                           V_PAYMENT_STATUS_R
		,FBPDR.N_AMOUNT_R                                                                                            N_PAID_AMOUNT_R
		,(CASE WHEN (UPPER(TRIM(DGCDR.V_LOB_TYPE_R)) IN ('LIFE','WOP') AND UPPER(TRIM(FBPR.V_PAY_METHOD_R)) = 'RAA')
		THEN 'FIN'
		ELSE 'PAY'
		END)                                                                                                         V_PAYMENT_TYPE_R
		,FBPR.D_DISB_DATE_R                                                                                          D_CHECK_DATE_R
		,DECODE(UPPER(TRIM(FBPR.V_PAY_METHOD_R)),'ACH','ACH','BP')                                                   V_CHECK_TYPE_R
		--,(CASE WHEN UPPER(TRIM(FBPR.V_PAY_STATUS_R)) NOT IN ('RELEASED','REVERSED')
    /*,(CASE WHEN UPPER(TRIM(FBPR.V_PAY_STATUS_R))  IN ('RELEASED','REVERSED')--19-Jul-2021 Eric'as new logic
		THEN FBPR.D_DISB_DATE_R
		ELSE FBPR.D_REVERSE_DATE_R
		END)                                  D_PAID_DATE_R  */--as per Erica's request on 28-Jul-2021 , code  commented
		,FBPR.D_TRANS_DATE_R                                                                                         D_PAID_DATE_R   --as per Erica's request on 28-Jul-2021 , code  added
		,cast(NULL   as Number)                                                                                                     N_GROSS_AMOUNT_R
		,FBPR.D_SERVICE_PERIOD_START_R                                                                               D_SERVICE_PERIOD_FROM_R
		,FBPR.D_SERVICE_PERIOD_END_R                                                                                 D_SERVICE_PERIOD_TO_R
		,FBPDR.V_OFFSET_TYPE_R
        ,'Benefit Payment'--04-May-2023 changes
		,FBPR.N_WORKSHEET_SEQ_NBR_OBJECTNM_R                                                                         N_WORKSHEET_OBJECT_NUM_R
		,FBPR.N_PAY_SCHD_SOURCE_SYSTEM_KEY_R                                                                         N_SOURCE_SYSTEM_KEY_R
		,FBPR.N_SOURCE_VERSION_SEQ_NUMBER_R                                                                          N_SOURCE_VERSION_SEQ_NUMBER_R
		,FBPR.N_SEQ_R                                                                                                N_SEQ_R
		,FBPR.N_GROUP_SEQ_R                                                                                          N_GROUP_SEQ_R
		,FBPR.N_PARENT_OBJECTNUM_R                                                                                   N_PARENT_OBJECTNUM_R
        ,systimestamp                                                                                             T_CREATION_DATE_R
        ,systimestamp                                                                                             T_EVENT_TIMESTAMP_R
        ,systimestamp                                                                                             T_LAST_MODIFIED_DATE_R
        ,'ODI'                                                                                                       V_CREATED_BY_R
        ,'ODI'                                                                                                       V_LAST_MODIFIED_BY_R
		,FBPR.FIC_MIS_DATE_R--26-Apr-2022 Full Load Changes
		,FBPR.N_BATCH_ID_R--26-Apr-2022 Full Load Changes
        ,1                     N_LOAD_RUN_ID_R
        ,(NVL(FBPDR.N_SEQUENCE_NUMBER_R,0)+ROWNUM)     N_SEQUENCE_NUMBER_R
		,FBPDR.V_AMOUNT_TYPE_CATEGORY_DESC_R                                                                         V_BENEFIT_CATEGORY_R
		--On 15-Jul-2021 Erica requested to add below columns
		,FBPDR.N_PAID_CLAIM_BENEFITS_R
		,FBPDR.N_TAXABLE_BENEFIT_AMT_R
		,FBPDR.N_FEDERAL_TAX_WITHHELD_AMT_R
		,FBPDR.N_STATE_TAX_WITHHELD_AMT_R
		,FBPDR.N_EMPLOYEE_SS_WITHHELD_AMT_R
		,FBPDR.N_EMPLOYEE_MED_WITHHELD_AMT_R
		,FBPDR.N_EMPLOYER_SS_WITHHELD_AMT_R
		,FBPDR.N_EMPLOYER_MED_WITHHELD_AMT_R
		,FBPDR.N_LEGAL_EXPENSE_DIRECT_AMT_R
		,FBPDR.N_OTHER_EXPENSE_DIRECT_AMT_R
		--On 15-Jul-2021 Erica request ends
		,DGCDR.V_LOB_TYPE_R         -- to achieve On Erica's requirement 28-Jul-2021
		,  FGW.N_MODAL_AMOUNT_R       -- to achieve On Erica's requirement 28-Jul-2021
		, FBPR.N_PRIMARY_PAYEE_R     -- to achieve On Erica's requirement 28-Jul-2021
		, FBPR.N_ADJ_GROSS_BENEFIT_R -- to achieve On Erica's requirement 28-Jul-2021
		, FBPR.N_PAY_AMOUNT_R        -- to achieve On Erica's requirement 28-Jul-2021
		, FBPR.N_CLAIM_SK_R          -- to achieve On Erica's requirement 28-Jul-2021
        --as requested by Erica on 16-Nov-2021
        ,(CASE WHEN DGCDR.V_LOB_TYPE_R =  'NONS' THEN
        CASE WHEN DGCCGR.V_CLAIM_COVERAGE_CODE_R = 'END' then '025'
        WHEN DGCCGR.V_CLAIM_COVERAGE_CODE_R = 'GCM' then '128'
        WHEN DGCCGR.V_CLAIM_COVERAGE_CODE_R = 'LTY' then '028'
        WHEN DGCCGR.V_CLAIM_COVERAGE_CODE_R IN ('IDL', 'MML', 'ORL', 'PGL', 'PVG') then '010'
        WHEN DGCCGR.V_CLAIM_COVERAGE_CODE_R IN ('ASG', 'SPG', 'VAI') then '051'
        WHEN DGCCGR.V_CLAIM_COVERAGE_CODE_R = 'VCI' then '079'
        WHEN DGCCGR.V_CLAIM_COVERAGE_CODE_R IN ('IWP', 'WP') then '013'
        ELSE '081'
        END
        WHEN DGCDR.V_LOB_TYPE_R =  'ANNUITY' THEN
        CASE WHEN DGCCR.V_CLAIM_COVERAGE_CODE_R = 'GAN' THEN '085'
        ELSE
            --CASE WHEN DGCCR.V_CLAIM_COVERAGE_CODE_R = 'SC' AND upper(DGCCR.V_COVERAGE_CODE_R) in ('J'||CHR(38)||'S',  'LIFE',  'LIFE w/PC') THEN '031'--05-JAN-2022 commented changes
            CASE WHEN DGCCR.V_CLAIM_COVERAGE_CODE_R = 'SC' AND upper(DGCCR.V_COVERAGE_CODE_R) in ('J'||CHR(38)||'S',  'LIFE',  'LIFE W/PC') THEN '031'--05-JAN-2022 changes
            ELSE '032'
            END
        END
        WHEN DGCDR.V_LOB_TYPE_R IN ( 'WOP', 'LIFE') THEN DGCCGR.V_BENEFIT_CODE_R
        WHEN DGCDR.V_LOB_TYPE_R IN ( 'LTD', 'STD', 'VPL', 'VPS' ) THEN '081'
        END
        ) V_GROSS_BENEFIT_CODE_R
		,FBPR.N_CLAIM_COVERAGE_SK_R                  --08-Apr-2022 Erica changes
		,FBPR.N_CLAIM_COVERAGE_GROUP_SK_R            --08-Apr-2022 Erica changes
    ,fbpdr.n_seq_r                         N_FBPR_N_SEQ_R --10-Nov-2022 changes for Merge
    ,FBPDR.v_privacy_indicator_r
	,FBPDR.V_PAYEE_FIRST_NAME_R	--31-JAN-2024 Changes
	,FBPDR.V_PAYEE_MIDDLE_NAME_R	--31-JAN-2024 Changes
	,FBPDR.V_PAYEE_LAST_NAME_R	--31-JAN-2024 Changes
	,FBPDR.V_PAYEE_TYPE_R	--31-JAN-2024 Changes
	,FBPDR.N_PARTY_SK_R  --12-MAR-2024 Changes
	--29-May-2024 changes starts
    ,FBPDR.V_AMOUNT_TYPE_SUB_NAME_R
    ,FBPDR.V_AMOUNT_TYPE_CATEGORY_R
    ,FBPDR.V_AMOUNT_TYPE_CATEGORY_DESC_R
    ,FBPDR.V_AMOUNT_TYPE_SUB_CATEGORY_R
    ,FBPDR.V_AMT_TYPE_SUB_CATEGORY_DESC_R
    ,FBPDR.V_AMOUNT_TYPE_CODE_R
    ,FBPDR.V_AMOUNT_TYPE_NAME_R
    ,FBPDR.V_AMOUNT_TYPE_SUB_CODE_R
	--29-May-2024 changes ends
		FROM FCT_BENEFIT_PAYMENT_R FBPR
			,DIM_GRP_CLAIM_DIR_R DGCDR
			,FCT_GRP_WORKSHEET FGW
			,FCT_CLAIM_PAYMENT_DETAIL_OFFSETS_R FBPDR
			,DIM_GRP_CLAIM_COVERAGE_GROUP_R DGCCGR
			,DIM_GRP_CLAIM_COVERAGE_R DGCCR
		WHERE  UPPER(TRIM(FBPR.V_PAY_STATUS_R)) IN ('RELEASED','REVERSAL','REVERSED')
		AND FBPR.N_CLAIM_SK_R = DGCDR.N_CLAIM_SK_R
        and FBPR.N_CLAIM_COVERAGE_SK_R = DGCCR.N_CLAIM_COVERAGE_SK_R(+)
        and FBPR.N_CLAIM_COVERAGE_GROUP_SK_R = DGCCGR.N_CLAIM_COVERAGE_GROUP_SK_R(+)
		AND FGW.N_WORKSHEET_SEQ_NBR_OBJECTNM_R = FBPR.N_PARENT_OBJECTNUM_R
		AND FGW.N_SOURCE_SYSTEM_KEY_R = FBPR.N_PAY_SCHD_SOURCE_SYSTEM_KEY_R
		AND FBPR.N_SOURCE_VERSION_SEQ_NUMBER_R = FBPDR.N_SOURCE_VERSION_SEQ_NUMBER_R(+)  --22-Jul-2021 Erica outer join request
		AND FBPR.N_SEQ_R = FBPDR.N_GROUP_SEQ_R(+)--22-Jul-2021 Erica outer join request
		AND FBPR.N_PAY_SCHD_SOURCE_SYSTEM_KEY_R = FBPDR.N_PAY_DTL_SOURCE_SYSTEM_KEY_R(+)--22-Jul-2021 Erica outer join request
		AND DGCDR.V_ACTIVE_STATUS_R         = 'Y'
        and nvl(DGCCGR.V_ACTIVE_STATUS_R,'Y') = 'Y'
        AND NVL(DGCCR.V_ACTIVE_STATUS_R, 'Y')  = 'Y'
		AND UPPER(TRIM(FBPDR.V_BENEFIT_DESC_R)) <> 'PAYMENT TO SECONDARY PAYEE' --11-May-2022 Mohan Changes
        --and NVL(DGCCGR.V_CLAIM_COVERAGE_CODE_R,DGCCR.V_CLAIM_COVERAGE_CODE_R)  is null Erica asked to remove this condition 14-Apr-2022
		--AND FBPR.N_BATCH_ID_R = LN_N_BATCH_ID_R --26-Apr-2022 Full Load Changes
      AND NVL(FBPR.V_SOURCE_SYSTEM_NAME_R,'X@')='PACS';
				--23-March-23 Changes end -----
				UPDATE FCT_PROC_EXEC_STATUS_LOG_R
							SET V_STATUS_R                = 'Successful',
							T_EXECUTION_END_TIMESTAMP_R = systimestamp
							WHERE N_SERIAL_NUM_R          = N_MAX_SERIAL_NUM_R;
							COMMIT;
			EXCEPTION
			WHEN OTHERS THEN
				V_SQLCODE                    := SQLCODE;
						V_SQLERRM                    := SUBSTR(SYS.STANDARD.SQLERRM,1,500);
						UPDATE FCT_PROC_EXEC_STATUS_LOG_R
						SET V_STATUS_R                = 'Failed',
						T_EXECUTION_END_TIMESTAMP_R = systimestamp,
						V_ERROR_CODE_R				= V_SQLCODE,
						V_ERROR_DESC_R				= V_SQLERRM
						WHERE N_SERIAL_NUM_R          = N_MAX_SERIAL_NUM_R;
					COMMIT;
						RAISE;
			END;
		END IF;
		 --30 March Changes ends--
		 --30 June 2023 changes starts--

		 IF UPPER(TRIM(P_MV_TBL_NAME)) like  '%CLAIM_DETAIL_MV%' THEN

			Begin
				SELECT SEQ_FCT_PROC_EXEC_STATUS_LOG_R.NEXTVAL INTO N_MAX_SERIAL_NUM_R FROM DUAL;

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
					LN_BATCH_ID_R,--99999999,
					TO_CHAR(sysdate,'yyyymmdd'),
					1,
					'Started',
					SYSTIMESTAMP,
					USER,
					P_MV_TBL_NAME||'.PROC_REFRESH_GRP_M_VIEW_TBLS.CLAIM_DETAIL_MV_TBL',
					N_MAX_SERIAL_NUM_R
					);
				COMMIT;


				EXECUTE IMMEDIATE 'TRUNCATE TABLE CLAIM_DETAIL_MV_TBL PURGE SNAPSHOT LOG';

				 INSERT /*+APPEND_VALUES*/ INTO CLAIM_DETAIL_MV_TBL (
		 V_CLAIM_NUMBER_R
		,N_CLAIM_SK_R
		,V_SOURCE_SYSTEM_NAME_R
		,N_POLICY_SK_R
		,V_LOB_TYPE_R
		,D_DATE_OF_CONTRACT_R
		,V_COMPANY_R
		,N_SOURCE_SYSTEM_KEY_R
		,V_PRIVACY_INDICATOR_R
		,V_CLAIM_IDENTIFIER_R
		,V_CLAIM_STATUS_CODE_R
		,V_REASON_CODE_R
		,V_COV_GRP_CODE_R
		,V_ACTIVE_STATUS_R_COVGRP
		,D_AGE_REDUCTION_DATE_R
		,V_CLASS_ID_R_COVGRP
		,D_DATE_CLOSED_R
		,V_CLAIM_COVERAGE_CODE_R_COVGRP
		,V_CLAIM_COVERAGE_CODE_R
		,N_RESERVE_AMOUNT_R
		,N_WS_RELEASED_AMOUNT_R
		,N_COV_GRP_ID_R
		,N_BATCH_ID_R
		,N_CLAIM_COVERAGE_GROUP_SK_R
		,V_ACTIVE_STATUS_R_COV
		,V_CLASS_ID_R_COV_R
		,V_COVERAGE_STATUS_R
		,N_REINSURANCE_AMOUNT_R
		,N_REINSURANCE_PCT_R
		,V_CLAIM_COVERAGE_CODE_R_COV
		,N_CLAIM_COVERAGE_SK_R
		,V_EXAMINER_LOGIN_ID_R
		,V_EXAMINER_DESC_R
		,D_CLOSURE_DATE_R
		,V_CLAIM_STATUS_REASON_CODE_R
		,V_EXERTION_LEVEL_R
		,D_DATE_OF_EVENT_R
		,D_DATE_OF_LOSS_R
		,D_RETURN_TO_MOD_WKDT_R
		,V_CHILD_GENDER_R
		,D_PFL_DOB_R
		,V_MANDATED_FAMILY_MEMBER_R
		,V_LEAVE_REASON_R
		,D_PFL_DOP_R
		,D_RETURN_TO_WORK_DATE_R
		,N_INSRD_PARTY_SK_R
		,N_PRODUCT_SK_R
		,RANK
		,N_CLAIM_CVRG_SEQUENCE_NUMBER_R
		,D_DIAGNOSIS_DURATION_DATE_R
		,N_DIAGNOSIS_DURATION_PERIOD_R
		,V_DIAGNOSIS_CODE_R
		,V_DIAGNOSIS_DESC_R
		,N_PRIMARY_IND_R
		,N_DIAGNOSIS_TYPE_CODE_R
		,V_ORIGINAL_DIAG_LOOKUP_R
		,V_NEW_DIAG_LOOKUP_R
		,D_ANYOCC_DATE_R
		,D_ANYOCC_START_DATE_R
		,V_BENEFIT_DURATION_R
		,V_BENEFIT_DURATION_OTHER_R
		,V_DISABILITY_DATE_STATUS_R
		,N_ELIM_PERIOD_R
		,N_ELIM_PERIOD_ACC_R
		,V_ELIM_PERIOD_IND_R
		,N_ELIM_PERIOD_SICK_R
		,D_PLAN_DUR_DATE_R
		,D_WAIVER_TERMINATION_DATE_R
		,N_WAIVER_TERMINATION_AGE_R
		,N_BENEFIT_AMOUNT_R
		,V_BENEFIT_FREQUENCY_R
		,N_BENEFIT_PERCENT_R
		,D_BENEFIT_START_R
		,N_COLA_ACCUM_VALUE_R
		,N_COLA_BENEFIT_R
		,N_GROSS_BENEFIT_R
		,N_MINIMUM_BENEFIT_R
		,N_MAX_BENEFIT_R
		,N_SPEC_BENEFIT_ADJUST_R
		,N_RPT_NET_BENEFIT_R
		,V_DC_TIMESTAMP_R
		,V_BUSINESS_OBJECT_ID_R
		,V_SUBGROUP_ID_R
		,V_CORRESPONDENT_NAME_R
		,V_SUBGROUP_NAME_R
		,V_SUBGROUP_ADDRESSLINE1_R
		,V_SUBGROUP_ADDRESSLINE2_R
		,V_SUBGROUP_POSTALZIP_R
		,V_SUBGROUP_PROVSTATE_R
		,V_SUBGROUP_CITY_R
		,D_RECEIVED_DATE_R
		,D_HIRE_DATE_R
		,V_EEOC_CODE_R
		,N_BASIC_INSURED_SALARY_R
		,V_BASIC_INSURED_SALARY_IND_R
		,V_DESCRIPTION_R
		,N_SS_DEP_AWARD_AMOUNT_R
		,D_SS_DEP_AWARD_EFF_DATE_R
		,D_SS_DEP_TERM_DATE_R
		,V_SS_DEP_AWARD_TYPE_R
		,V_SS_DEP_PURSUE_FLAG_R
		,V_SS_DEPENDENT_STATUS_R
		,D_CHANGE_DATE_R
		,D_SS_CLOSED_TERM_DATE_R
		,D_SS_PRIMARY_EFF_DATE_R
		,N_SS_PRIMARY_AWARD_AMOUNT_R
		,V_SS_PRIMARY_AWARD_TYPE_R
		,N_SS_EST_MONTHLY_BENEFIT_R
		,V_SS_PURSUE_FLAG_R
		,V_SS_REJECT_REASON_R
		,V_SS_STATUS_DESCRIPTION_R
		,V_CURR_PRIMARY_DIAG_CODE_R
		,V_CURR_PRIMARY_DIAG_CAT_DESC_R
		,V_CURR_PRIMARY_DIAG_DESC_R
		,V_PRIOR_PRIMARY_DIAG_CODE_R
		,V_PRIOR_PRIMARY_DIAG_DESC_R
		,D_PRIMARY_DIAG_EFF_DATE_R
		,V_PRIMARY_DIAG_ACTIVE_STATUS_R
		,N_CURR_ELIMINATION_PERIOD_R
		,N_PRIOR_ELIMINATION_PERIOD_R
		,D_ELIMINATION_EFF_DATE_R
		,V_CURR_CLAIM_CAUSE_OF_EVENT_R
		,V_PRIOR_CLAIM_CAUSE_OF_EVENT_R
		,V_CURR_DURATION_R
		,V_CURR_DURATION_IND_R
		,V_PRIOR_DURATION_R
		,V_PRIOR_DURATION_IND_R
		,D_DURATION_EFF_DATE_R
		,D_CURR_LOSS_DATE_R
		,D_PRIOR_LOSS_DATE_R
		,D_LOSS_DATE_EFF_DATE_R
		,N_CURR_GROSS_BEN_AMT_R
		,N_PRIOR_GROSS_BEN_AMT_R
		,D_GROSS_BEN_EFF_DATE_R
		,N_CURR_CHECK_NET_BEN_AMT_R
		,N_PRIOR_CHECK_NET_BEN_AMT_R
		,D_CHECK_NET_BEN_EFF_DATE_R
		,V_CURR_CLAIM_STATUS_CODE_R
		,V_PRIOR_CLAIM_STATUS_CODE_R
		,D_CLAIM_STATUS_CODE_EFF_DATE_R
		,V_CURR_CLAIM_CLOSURE_CODE_R
		,V_PRIOR_CLAIM_CLOSURE_CODE_R
		,D_LAST_IN_STATUS_46_DATE_R
		,N_PRIOR_STATUS_BATCH_R
		,N_CLAIM_EVENT_SK_R
		,N_MODAL_AMOUNT_R
		,N_SS_HARDSHIP_IND_R
		)
        SELECT DISTINCT
            *
        FROM
            (
                SELECT
                    a.v_claim_number_r,
                    a.n_claim_sk_r,
                    a.v_source_system_name_r,
                    a.n_policy_sk_r,
                    a.v_lob_type_r,
                    a.d_date_of_contract_r,
                    a.v_company_r,
                    a.n_source_system_key_r,
                    a.v_privacy_indicator_r,
                    nvl(c.v_claim_identifier_r, a.v_claim_number_r) v_claim_identifier_r,
                    c.v_reason_code_r                               claim_status_code,
                    c.v_reason_code_r,
                    c.v_cov_grp_code_r,
                    c.v_active_status_r                             v_active_status_r_covgrp,
                    c.d_age_reduction_date_r,
                    c.v_class_id_r                                  v_class_id_r_covgrp,
                    c.d_date_closed_r,
                    c.v_claim_coverage_code_r                       v_claim_coverage_code_r_covgrp,
                    c.v_claim_coverage_code_r                       v_claim_coverage_code_r,
                    c.n_reserve_amount_r,
                    c.n_ws_released_amount_r,
                    c.n_cov_grp_id_r,
                    c.n_batch_id_r,
                    c.n_claim_coverage_group_sk_r,
                    b.v_active_status_r                             v_active_status_r_cov,
                    b.v_class_id_r                                  v_class_id_r_cov,
                    b.v_coverage_status_r,
                    b.n_reinsurance_amount_r,
                    b.n_reinsurance_pct_r,
                    b.v_claim_coverage_code_r                       v_claim_coverage_code_r_cov,
                    b.n_claim_coverage_sk_r,
                    d.v_examiner_login_id_r,
                    d.v_examiner_desc_r,
                    d.d_closure_date_r,
                    d.v_claim_status_reason_code_r,
                    d.v_exertion_level_r,
                    d.d_date_of_event_r,
                    d.d_date_of_loss_r,
                    d.d_return_to_mod_wkdt_r,
                    d.v_child_gender_r,
                    d.d_pfl_dob_r,
                    d.v_mandated_family_member_r,
                    d.v_leave_reason_r,
                    d.d_pfl_dop_r,
                    d.d_return_to_work_date_r,
                    d.n_insrd_party_sk_r,
                    e.n_product_sk_r,
                    RANK()
                    OVER(PARTITION BY b.n_claim_sk_r
                         ORDER BY
                             nvl(b.n_claim_cvrg_sequence_number_r, 0) DESC
                    )                                               rank,
                    b.n_claim_cvrg_sequence_number_r,
                    f.d_diagnosis_duration_date_r,
                    f.n_diagnosis_duration_period_r,
                    f.v_diagnosis_code_r,
                    f.v_diagnosis_desc_r,
                    f.n_primary_ind_r,
                    f.n_diagnosis_type_code_r,
                    f.original_diag_lookup,
                    f.new_diag_lookup,
                    g.d_anyocc_date_r,
                    g.d_anyocc_start_date_r,
                    g.v_benefit_duration_r,
                    g.v_benefit_duration_other_r,
                    g.v_disability_date_status_r,
                    g.n_elim_period_r,
                    g.n_elim_period_acc_r,
                    g.v_elim_period_ind_r,
                    g.n_elim_period_sick_r,
                    g.d_plan_dur_date_r,
                    g.d_waiver_termination_date_r,
                    g.n_waiver_termination_age_r,
                    h.n_benefit_amount_r,
                    h.v_benefit_frequency_r,
                    h.n_benefit_percent_r,
                    h.d_benefit_start_r,
                    h.n_cola_accum_value_r,
                    h.n_cola_benefit_r,
                    h.n_gross_benefit_r,
                    h.n_minimum_benefit_r,
                    h.n_max_benefit_r,
                    h.n_spec_benefit_adjust_r,

                    h.n_rpt_net_benefit_r,
--h.V_RPT_WORKSHEET_INDICATOR_R
                    j.v_dc_timestamp_r,
                    j.v_business_object_id_r,
                    k.v_subgroup_id_r,
                    k.v_correspondent_name_r,
                    k.v_subgroup_name_r,
                    k.v_subgroup_addressline1_r,
                    k.v_subgroup_addressline2_r,
                    k.v_subgroup_postalzip_r,
                    k.v_subgroup_provstate_r,
                    k.v_subgroup_city_r,
                    l.received_date,
                    m.d_hire_date_r,
                    m.v_eeoc_code_r,
                    m.n_basic_insured_salary_r,
                    m.v_basic_insured_salary_ind_r,

                    n.v_description_r,
                    o.n_ss_dep_award_amount_r,
                    o.d_ss_dep_award_eff_date_r,
                    o.d_ss_dep_term_date_r,
                    o.v_ss_dep_award_type_r,
                    o.v_ss_dep_pursue_flag_r,
                    o.v_ss_dependent_status_r,
                    o.d_change_date_r,
                    o.d_ss_closed_term_date_r,
                    o.d_ss_primary_eff_date_r,
                    o.n_ss_primary_award_amount_r,
                    o.v_ss_primary_award_type_r,
                    o.n_ss_est_monthly_benefit_r,
                    o.v_ss_pursue_flag_r,
                    o.v_ss_reject_reason_r,
                    o.v_ss_status_description_r,
                    p.v_curr_primary_diag_code_r,
                    p.v_curr_primary_diag_cat_desc_r,
                    p.v_curr_primary_diag_desc_r,
                    p.v_prior_primary_diag_code_r,
                    p.v_prior_primary_diag_desc_r,
                    p.d_primary_diag_eff_date_r,
                    p.v_primary_diag_active_status_r,
                    p.n_curr_elimination_period_r,
                    p.n_prior_elimination_period_r,
                    p.d_elimination_eff_date_r,
                    p.v_curr_claim_cause_of_event_r,
                    p.v_prior_claim_cause_of_event_r,
                    p.v_curr_duration_r,
                    p.v_curr_duration_ind_r,
                    p.v_prior_duration_r,
                    p.v_prior_duration_ind_r,
                    p.d_duration_eff_date_r,
                    p.d_curr_loss_date_r,
                    p.d_prior_loss_date_r,
                    p.d_loss_date_eff_date_r,
                    p.n_curr_gross_ben_amt_r,
                    p.n_prior_gross_ben_amt_r,
                    p.d_gross_ben_eff_date_r,
                    p.n_curr_check_net_ben_amt_r,
                    p.n_prior_check_net_ben_amt_r,
                    p.d_check_net_ben_eff_date_r,
                    p.v_curr_claim_status_code_r,
                    p.v_prior_claim_status_code_r,
                    p.d_claim_status_code_eff_date_r,
                    p.v_curr_claim_closure_code_r,
                    p.v_prior_claim_closure_code_r,
                    p.d_last_in_status_46_date_r,
                    p.n_batch_id_r                                  prior_status_batch,
                    m.n_claim_event_sk_r,
                    h.n_modal_amount_r,
					    o.N_SS_HARDSHIP_IND_R
                FROM
                         dim_grp_claim_dir_r a
                    INNER JOIN dim_grp_claim_detail_r               d ON a.n_claim_sk_r = d.n_claim_sk_r
                    INNER JOIN dim_grp_claim_coverage_r             b ON a.n_claim_sk_r = b.n_claim_sk_r
                    LEFT JOIN dim_grp_claim_coverage_group_r       c ON b.n_claim_coverage_sk_r = c.n_claim_coverage_sk_r
                                                                  AND c.v_active_status_r = 'Y'
                    LEFT OUTER JOIN mvw_product_sk_lookup                e ON a.n_claim_sk_r = e.n_claim_sk_r
                                                               AND c.v_claim_coverage_code_r = e.v_claim_coverage_code_r
                    LEFT JOIN dim_grp_medical_diagnosis_r          f ON f.n_claim_sk_r = a.n_claim_sk_r
                                                               AND TRIM(f.v_active_status_r) = 'Y'
                                                               AND TRIM(f.n_primary_ind_r) = '1'
                    LEFT JOIN dim_grp_claim_eligibility_r          g ON g.n_claim_coverage_sk_r = CASE
                                                                                                 WHEN g.n_claim_coverage_sk_r <> - 1 THEN
                                                                                                     b.n_claim_coverage_sk_r
                                                                                                 ELSE
                                                                                                     - 1
                                                                                             END
                                                               AND g.n_claim_sk_r = a.n_claim_sk_r
                                                               AND g.v_active_status_r = 'Y'
                    LEFT JOIN fct_grp_worksheet                    h ON c.n_claim_coverage_group_sk_r = h.n_claim_coverage_group_sk_r
                                                     AND h.n_claim_sk_r = a.n_claim_sk_r
                                                     AND h.v_rpt_worksheet_indicator_r = 'Y' -- might use cov grp rpt ind
                    LEFT JOIN (
                        SELECT
                            *
                        FROM
                            fct_grp_transactions_r
                        WHERE
                            n_claim_sk_r <> - 1
                    )                                    j ON j.n_claim_sk_r = a.n_claim_sk_r
                    LEFT JOIN dim_grp_claim_detail_subgroup_lookup k ON k.v_claim_number_r = a.v_claim_number_r
                    LEFT OUTER JOIN (
                        SELECT
                            ba.v_claim_number_r,
                            MAX(nvl(ba.d_received_date_r,
                                    TO_DATE(substr(ba.v_claim_number_r, 1, 10),
                                            'YYYY-MM-DD'))) AS received_date
                        FROM
                            dim_grp_busobj_audit_r ba
                        WHERE
                                ba.v_active_status_r = 'Y'
                            AND ba.v_claim_number_r NOT IN ( '-LIFE-01', '-LTD-01', '-STD-01', '-VPS-01', '-WOP-01' )
                        GROUP BY
                            ba.v_claim_number_r
                    )                                    l ON a.v_claim_number_r = l.v_claim_number_r
                    LEFT JOIN dim_grp_claim_event_r                m ON m.n_claim_event_sk_r = d.n_claim_event_sk_r
                                                         AND m.v_active_status_r = 'Y'
                    LEFT JOIN dim_grp_eeoc_r                       n ON n.v_code_r = m.v_eeoc_code_r
                    LEFT JOIN fct_claim_socialsecurity_inc_r       o ON o.n_claim_sk_r = a.n_claim_sk_r
                    LEFT JOIN vw_dim_grp_claim_prior_status_r      p ON p.v_coverage_group_code_r = c.v_coverage_code_r
                                                                   AND p.n_cov_grp_id_r = c.n_cov_grp_id_r
                                                                   AND p.n_claim_sk_r = a.n_claim_sk_r
                WHERE
                        a.v_active_status_r = 'Y'
                    AND a.v_lob_type_r IN ( 'LIFE', 'NONS', 'WOP' )
                    AND b.v_active_status_r = 'Y'
                    AND d.v_active_status_r = 'Y'
                UNION
                SELECT
                    a.v_claim_number_r,
                    a.n_claim_sk_r,
                    a.v_source_system_name_r,
                    a.n_policy_sk_r,
                    a.v_lob_type_r,
                    a.d_date_of_contract_r,
                    a.v_company_r,
                    a.n_source_system_key_r,
                    a.v_privacy_indicator_r,
                    nvl(c.v_claim_identifier_r, a.v_claim_number_r) v_claim_identifier_r,
                    CASE
                        WHEN d.v_claim_status_reason_code_r IS NULL THEN
                                CASE
                                    WHEN upper(b.v_coverage_status_r) = 'PENDING'  THEN
                                        '22'
                                    WHEN upper(b.v_coverage_status_r) = 'APPROVED' THEN
                                        '32'
                                    WHEN upper(b.v_coverage_status_r) = 'CLOSED'   THEN
                                        '60'
                                    ELSE
                                        d.v_claim_status_reason_code_r
                                END
                        ELSE
                            d.v_claim_status_reason_code_r
                    END                                             AS claim_status_code,
--d.V_CLAIM_STATUS_REASON_CODE_R CLAIM_STATUS_CODE,
                    c.v_reason_code_r,
                    c.v_cov_grp_code_r,
                    c.v_active_status_r                             v_active_status_r_covgrp,
                    c.d_age_reduction_date_r,
                    c.v_class_id_r                                  v_class_id_r_covgrp,
                    c.d_date_closed_r,
                    c.v_claim_coverage_code_r                       v_claim_coverage_code_r_covgrp,
                    b.v_claim_coverage_code_r                       v_claim_coverage_code_r,
                    c.n_reserve_amount_r,
                    c.n_ws_released_amount_r,
                    c.n_cov_grp_id_r,
                    c.n_batch_id_r,
                    c.n_claim_coverage_group_sk_r,
                    b.v_active_status_r                             v_active_status_r_cov,
                    b.v_class_id_r                                  v_class_id_r_cov,
                    b.v_coverage_status_r,
                    b.n_reinsurance_amount_r,
                    b.n_reinsurance_pct_r,
                    b.v_claim_coverage_code_r                       v_claim_coverage_code_r_cov,
                    b.n_claim_coverage_sk_r,
                    d.v_examiner_login_id_r,
                    d.v_examiner_desc_r,
                    d.d_closure_date_r,
                    d.v_claim_status_reason_code_r,
                    d.v_exertion_level_r,
                    d.d_date_of_event_r,
                    d.d_date_of_loss_r,
                    d.d_return_to_mod_wkdt_r,
                    d.v_child_gender_r,
                    d.d_pfl_dob_r,
                    d.v_mandated_family_member_r,
                    d.v_leave_reason_r,
                    d.d_pfl_dop_r,
                    d.d_return_to_work_date_r,
                    d.n_insrd_party_sk_r,
                    e.n_product_sk_r,
                    RANK()
                    OVER(PARTITION BY b.n_claim_sk_r
                         ORDER BY
                             nvl(b.n_claim_cvrg_sequence_number_r, 0) DESC
                    )                                               rank,
                    b.n_claim_cvrg_sequence_number_r,
                    f.d_diagnosis_duration_date_r,
                    f.n_diagnosis_duration_period_r,
                    f.v_diagnosis_code_r,
                    f.v_diagnosis_desc_r,
                    f.n_primary_ind_r,
                    f.n_diagnosis_type_code_r,
                    f.original_diag_lookup,
                    f.new_diag_lookup,
                    g.d_anyocc_date_r,
                    g.d_anyocc_start_date_r,
                    g.v_benefit_duration_r,
                    g.v_benefit_duration_other_r,
                    g.v_disability_date_status_r,
                    g.n_elim_period_r,
                    g.n_elim_period_acc_r,
                    g.v_elim_period_ind_r,
                    g.n_elim_period_sick_r,
                    g.d_plan_dur_date_r,
                    g.d_waiver_termination_date_r,
                    g.n_waiver_termination_age_r,
                    i.n_benefit_amount_r,
                    i.v_benefit_frequency_r,
                    i.n_benefit_percent_r,
                    i.d_benefit_start_r,
                    i.n_cola_accum_value_r,
                    i.n_cola_benefit_r,
                    i.n_gross_benefit_r,
                    i.n_minimum_benefit_r,
                    i.n_max_benefit_r,
                    i.n_spec_benefit_adjust_r,


                    i.n_rpt_net_benefit_r,
                    j.v_dc_timestamp_r,
                    j.v_business_object_id_r,
                    k.v_subgroup_id_r,
                    k.v_correspondent_name_r,
                    k.v_subgroup_name_r,
                    k.v_subgroup_addressline1_r,
                    k.v_subgroup_addressline2_r,
                    k.v_subgroup_postalzip_r,
                    k.v_subgroup_provstate_r,
                    k.v_subgroup_city_r,
                    l.received_date,
                    m.d_hire_date_r,
                    m.v_eeoc_code_r,
                    m.n_basic_insured_salary_r,
                    m.v_basic_insured_salary_ind_r,

                    n.v_description_r,
--i.V_RPT_WORKSHEET_INDICATOR_R,
                    o.n_ss_dep_award_amount_r,
                    o.d_ss_dep_award_eff_date_r,
                    o.d_ss_dep_term_date_r,
                    o.v_ss_dep_award_type_r,
                    o.v_ss_dep_pursue_flag_r,
                    o.v_ss_dependent_status_r,
                    o.d_change_date_r,
                    o.d_ss_closed_term_date_r,
                    o.d_ss_primary_eff_date_r,
                    o.n_ss_primary_award_amount_r,
                    o.v_ss_primary_award_type_r,
                    o.n_ss_est_monthly_benefit_r,
                    o.v_ss_pursue_flag_r,
                    o.v_ss_reject_reason_r,
                    o.v_ss_status_description_r,
                    p.v_curr_primary_diag_code_r,
                    p.v_curr_primary_diag_cat_desc_r,
                    p.v_curr_primary_diag_desc_r,
                    p.v_prior_primary_diag_code_r,
                    p.v_prior_primary_diag_desc_r,
                    p.d_primary_diag_eff_date_r,
                    p.v_primary_diag_active_status_r,
                    p.n_curr_elimination_period_r,
                    p.n_prior_elimination_period_r,
                    p.d_elimination_eff_date_r,
                    p.v_curr_claim_cause_of_event_r,
                    p.v_prior_claim_cause_of_event_r,
                    p.v_curr_duration_r,
                    p.v_curr_duration_ind_r,
                    p.v_prior_duration_r,
                    p.v_prior_duration_ind_r,
                    p.d_duration_eff_date_r,
                    p.d_curr_loss_date_r,
                    p.d_prior_loss_date_r,
                    p.d_loss_date_eff_date_r,
                    p.n_curr_gross_ben_amt_r,
                    p.n_prior_gross_ben_amt_r,
                    p.d_gross_ben_eff_date_r,
                    p.n_curr_check_net_ben_amt_r,
                    p.n_prior_check_net_ben_amt_r,
                    p.d_check_net_ben_eff_date_r,
                    p.v_curr_claim_status_code_r,
                    p.v_prior_claim_status_code_r,
                    p.d_claim_status_code_eff_date_r,
                    p.v_curr_claim_closure_code_r,
                    p.v_prior_claim_closure_code_r,
                    p.d_last_in_status_46_date_r,
                    p.n_batch_id_r                                  prior_status_batch,
                     m.n_claim_event_sk_r,
                      i.n_modal_amount_r,
					    o.N_SS_HARDSHIP_IND_R

                FROM
                         dim_grp_claim_dir_r a
                    INNER JOIN dim_grp_claim_detail_r               d ON a.n_claim_sk_r = d.n_claim_sk_r
                    INNER JOIN dim_grp_claim_coverage_r             b ON a.n_claim_sk_r = b.n_claim_sk_r
                    LEFT JOIN dim_grp_claim_coverage_group_r       c ON b.n_claim_coverage_sk_r = c.n_claim_coverage_sk_r
                                                                  AND c.v_active_status_r = 'Y'
                    LEFT OUTER JOIN (
                        SELECT
                            MIN(n_product_sk_r) n_product_sk_r,
                            n_claim_sk_r,
                            v_claim_coverage_code_r
                        FROM
                            mvw_product_sk_lookup
                        GROUP BY
                            n_claim_sk_r,
                            v_claim_coverage_code_r
                    )                                    e ON a.n_claim_sk_r = e.n_claim_sk_r
                           AND b.v_claim_coverage_code_r = e.v_claim_coverage_code_r
                    LEFT JOIN dim_grp_medical_diagnosis_r          f ON f.n_claim_sk_r = a.n_claim_sk_r
                                                               AND TRIM(f.v_active_status_r) = 'Y'
                                                               AND TRIM(f.n_primary_ind_r) = '1'
                    LEFT JOIN dim_grp_claim_eligibility_r          g ON g.n_claim_coverage_sk_r = CASE
                                                                                                 WHEN g.n_claim_coverage_sk_r <> - 1 THEN
                                                                                                     b.n_claim_coverage_sk_r
                                                                                                 ELSE
                                                                                                     - 1
                                                                                             END
                                                               AND g.n_claim_sk_r = a.n_claim_sk_r
                                                               AND g.v_active_status_r = 'Y'
                    LEFT JOIN fct_grp_worksheet                    i ON i.n_claim_coverage_sk_r = b.n_claim_coverage_sk_r
                                                     AND i.n_claim_sk_r = a.n_claim_sk_r
                                                     AND i.v_rpt_worksheet_indicator_r = 'Y'
                    LEFT JOIN (
                        SELECT
                            *
                        FROM
                            fct_grp_transactions_r
                        WHERE
                            n_claim_sk_r <> - 1
                    )                                    j ON j.n_claim_sk_r = a.n_claim_sk_r
                    LEFT JOIN dim_grp_claim_detail_subgroup_lookup k ON k.v_claim_number_r = a.v_claim_number_r
                    LEFT OUTER JOIN (
                        SELECT
                            ba.v_claim_number_r,
                            MAX(nvl(ba.d_received_date_r,
                                    TO_DATE(substr(ba.v_claim_number_r, 1, 10),
                                            'YYYY-MM-DD'))) AS received_date
                        FROM
                            dim_grp_busobj_audit_r ba
                        WHERE
                                ba.v_active_status_r = 'Y'
                            AND ba.v_claim_number_r NOT IN ( '-LIFE-01', '-LTD-01', '-STD-01', '-VPS-01', '-WOP-01' )
                        GROUP BY
                            ba.v_claim_number_r
                    )                                    l ON a.v_claim_number_r = l.v_claim_number_r
                    LEFT JOIN dim_grp_claim_event_r                m ON m.n_claim_event_sk_r = d.n_claim_event_sk_r
                                                         AND m.v_active_status_r = 'Y'
                    LEFT JOIN dim_grp_eeoc_r                       n ON n.v_code_r = m.v_eeoc_code_r
                    LEFT JOIN fct_claim_socialsecurity_inc_r       o ON o.n_claim_sk_r = a.n_claim_sk_r
                    LEFT JOIN vw_dim_grp_claim_prior_status_r      p ON p.n_claim_sk_r = a.n_claim_sk_r
                                                                   AND p.v_coverage_code_r = b.v_claim_coverage_code_r
                                                                   AND p.n_claim_coverage_sk_r = b.n_claim_coverage_sk_r
                WHERE
                        a.v_active_status_r = 'Y'
                    AND a.v_lob_type_r IN ( 'LTD', 'STD', 'VPL', 'VPS' )
                    AND b.v_active_status_r = 'Y'
                    AND d.v_active_status_r = 'Y'
            )
        WHERE
                CASE
                    WHEN rank <> 1 THEN
                        n_claim_cvrg_sequence_number_r
                    ELSE
                        1
                END
            IS NOT NULL


-- and N_batch_id_r = (select max(q.n_batch_id_r) from DIM_GRP_CLAIM_PRIOR_STATUS_R q where n_claim_sk_r = q.n_claim_sk_r and n_claim_coverage_sk_r = q.n_claim_coverage_sk_r and n_claim_coverage_group_sk_r= q.n_claim_coverage_group_sk_r)
            ;
				UPDATE FCT_PROC_EXEC_STATUS_LOG_R
							SET V_STATUS_R                = 'Successful',
							T_EXECUTION_END_TIMESTAMP_R = systimestamp
							WHERE N_SERIAL_NUM_R          = N_MAX_SERIAL_NUM_R;
							COMMIT;
			EXCEPTION
			WHEN OTHERS THEN
				V_SQLCODE                    := SQLCODE;
						V_SQLERRM                    := SUBSTR(SYS.STANDARD.SQLERRM,1,500);
						UPDATE FCT_PROC_EXEC_STATUS_LOG_R
						SET V_STATUS_R                = 'Failed',
						T_EXECUTION_END_TIMESTAMP_R = systimestamp,
						V_ERROR_CODE_R				= V_SQLCODE,
						V_ERROR_DESC_R				= V_SQLERRM
						WHERE N_SERIAL_NUM_R          = N_MAX_SERIAL_NUM_R;
					COMMIT;
						RAISE;
			END;
		END IF;
		--30 June 2023 changes ends--
		--18 july 2023 additional columns added given by erica changes ends----

		--26 July changes Starts--
		IF UPPER(TRIM(P_MV_TBL_NAME)) like  '%FCT_RPT_EOI_HISTORY_R_MV_TBL%' THEN

			Begin
				SELECT SEQ_FCT_PROC_EXEC_STATUS_LOG_R.NEXTVAL INTO N_MAX_SERIAL_NUM_R FROM DUAL;
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
					LN_BATCH_ID_R,--99999999,
					TO_CHAR(sysdate,'yyyymmdd'),
					1,
					'Started',
					SYSTIMESTAMP,
					USER,
					P_MV_TBL_NAME||'.PROC_REFRESH_GRP_M_VIEW_TBLS.FCT_RPT_EOI_HISTORY_R_MV_TBL',
					N_MAX_SERIAL_NUM_R
					);
				COMMIT;


				EXECUTE IMMEDIATE 'TRUNCATE TABLE FCT_RPT_EOI_HISTORY_R_MV_TBL PURGE SNAPSHOT LOG';

                INSERT /*+APPEND_VALUES*/ INTO  FCT_RPT_EOI_HISTORY_R_MV_TBL
	            (N_BATCH_ID_R
                 ,V_POLICY_PREFIX_R
                 ,V_RSO_R
                 ,V_CLIENT_NAME_R
                 ,D_APPLICATION_ENTRY_DATE_R
                 ,N_APPLICATION_ID_R
                 ,V_EOI_LOGIN_ID_R
                 ,N_APPROVED_APP_COUNT_R
                 ,N_DECLINED_APP_COUNT_R
                 ,N_INCOMPLETE_APP_COUNT_R
                 ,N_DECLINED_INCOMPLETE_APPCNT_R
                 ,N_PENDING_APP_COUNT_R
                 ,N_EMPLOYEE_APP_COUNT_R
                 ,N_SPOUSE_APP_COUNT_R
                 ,N_CHILD_APP_COUNT_R
                 ,N_APP_COUNT_R
                 ,N_AUTO_APPROVAL_COUNT_R
                 ,D_EMPLOYEE_GI_EFFECTIVE_DATE_R
                 ,N_EMPLOYEE_GI_APPROVED_R
                 ,N_EMPLOYEE_GI_DECLINED_R
                 ,N_EMPLOYEE_GI_PENDING_R
                 ,D_SPOUSE_GI_EFFECTIVE_DATE_R
                 ,N_SPOUSE_GI_APPROVED_R
                 ,N_SPOUSE_GI_DECLINED_R
                 ,N_SPOUSE_GI_PENDING_R
                 ,D_CHILD_GI_EFFECTIVE_DATE_R
                 ,N_CHILD_GI_APPROVED_R
                 ,N_CHILD_GI_DECLINED_R
                 ,N_CHILD_GI_PENDING_R
                 ,D_EMPLOYEE_EXCESS_EFF_DATE_R
                 ,N_EMPLOYEE_EXCESS_APPRVD_AMT_R
                 ,N_EMPLOYEE_EXCESSDECLINEDAMT_R
                 ,N_EMPLOYEE_EXCESSINCOMPLTAMT_R
                 ,N_EMPLOYEE_EXCESS_PENDINGAMT_R
                 ,D_SPOUSE_EXCESS_EFF_DATE_R
                 ,N_SPOUSE_EXCESS_APPROVED_AMT_R
                 ,N_SPOUSE_EXCESS_DECLINED_AMT_R
                 ,N_SPOUSE_EXCESS_INCOMPLTEAMT_R
                 ,N_SPOUSE_EXCESS_PENDING_AMT_R
                 ,N_LOAD_RUN_ID_R
                 ,N_SEQUENCE_NUMBER_R
                 ,T_CREATION_DATE_R
                 ,T_EVENT_TIMESTAMP_R
                 ,T_LAST_MODIFIED_DATE_R
                 ,V_CREATED_BY_R
                 ,V_LAST_MODIFIED_BY_R
                 ,D_CYCLE_DATE_R
                 ,FIC_MIS_DATE_R
                 ,V_SOURCE_SYSTEM_NAME_R
                 ,V_SUBJECT_AREA_TYPE_R
                 ,N_VERSION_NUMBER_R
                 ,F_PHYSICAL_DELETE_R
                 ,V_CHANGE_REASON_R
                 ,V_POLICY_SUFFIX_R
                 ,N_POLICY_SK_R
                 ,N_CLAIM_SK_R
                 ,N_PARTY_SK_R
                 ,N_QUOTE_SK_R
                 ,V_POLICY_SFX_R
                 ,N_APPLICATION_HISTORY_SK_R
                 ,V_ENTITY_TYPE_R
                 ,V_CODE_R
                 ,V_PRIVACY_INDICATOR_R
                 ,N_LOB_APP_COUNT_R
                 ,D_APP_ENTRY_DATE_R
                 ,APP_BUCKET
                 ,N_APP_PENDING_COUNT_R)
	             WITH APP_MAX AS
                    (SELECT MAX(D_APPLICATION_ENTRY_DATE_R) AS MAX_D_APPLICATION_ENTRY_DATE_R,
                    N_APPLICATION_ID_R FROM FCT_RPT_EOI_HISTORY_R WHERE V_CODE_R='APP' GROUP BY N_APPLICATION_ID_R
                    ),
                    APP_PENDING_COUNT_R AS(
                    SELECT N_APPLICATION_ID_R,
                    CASE WHEN (sum(N_APPROVED_APP_COUNT_R+ N_DECLINED_APP_COUNT_R + N_INCOMPLETE_APP_COUNT_R+ N_DECLINED_INCOMPLETE_APPCNT_R)>=1
                                 AND SUM(N_PENDING_APP_COUNT_R)>=1)
                                 THEN 0
                                 ELSE 1
                                 END AS N_APP_PENDING_COUNT_R
                    FROM FCT_RPT_EOI_HISTORY_R GROUP BY N_APPLICATION_ID_R
                    )
                    select                   
					--10-Jul-2024 chnages starts
					--A.*
					A.N_BATCH_ID_R
                    ,A.V_POLICY_PREFIX_R
                    ,A.V_RSO_R
                    ,A.V_CLIENT_NAME_R
                    ,A.D_APPLICATION_ENTRY_DATE_R
                    ,A.N_APPLICATION_ID_R
                    ,A.V_EOI_LOGIN_ID_R
                    ,A.N_APPROVED_APP_COUNT_R
                    ,A.N_DECLINED_APP_COUNT_R
                    ,A.N_INCOMPLETE_APP_COUNT_R
                    ,A.N_DECLINED_INCOMPLETE_APPCNT_R
                    ,A.N_PENDING_APP_COUNT_R
                    ,A.N_EMPLOYEE_APP_COUNT_R
                    ,A.N_SPOUSE_APP_COUNT_R
                    ,A.N_CHILD_APP_COUNT_R
                    ,A.N_APP_COUNT_R
                    ,A.N_AUTO_APPROVAL_COUNT_R
                    ,A.D_EMPLOYEE_GI_EFFECTIVE_DATE_R
                    ,A.N_EMPLOYEE_GI_APPROVED_R
                    ,A.N_EMPLOYEE_GI_DECLINED_R
                    ,A.N_EMPLOYEE_GI_PENDING_R
                    ,A.D_SPOUSE_GI_EFFECTIVE_DATE_R
                    ,A.N_SPOUSE_GI_APPROVED_R
                    ,A.N_SPOUSE_GI_DECLINED_R
                    ,A.N_SPOUSE_GI_PENDING_R
                    ,A.D_CHILD_GI_EFFECTIVE_DATE_R
                    ,A.N_CHILD_GI_APPROVED_R
                    ,A.N_CHILD_GI_DECLINED_R
                    ,A.N_CHILD_GI_PENDING_R
                    ,A.D_EMPLOYEE_EXCESS_EFF_DATE_R
                    ,A.N_EMPLOYEE_EXCESS_APPRVD_AMT_R
                    ,A.N_EMPLOYEE_EXCESSDECLINEDAMT_R
                    ,A.N_EMPLOYEE_EXCESSINCOMPLTAMT_R
                    ,A.N_EMPLOYEE_EXCESS_PENDINGAMT_R
                    ,A.D_SPOUSE_EXCESS_EFF_DATE_R
                    ,A.N_SPOUSE_EXCESS_APPROVED_AMT_R
                    ,A.N_SPOUSE_EXCESS_DECLINED_AMT_R
                    ,A.N_SPOUSE_EXCESS_INCOMPLTEAMT_R
                    ,A.N_SPOUSE_EXCESS_PENDING_AMT_R
                    ,A.N_LOAD_RUN_ID_R
                    ,A.N_SEQUENCE_NUMBER_R
                    ,A.T_CREATION_DATE_R
                    ,A.T_EVENT_TIMESTAMP_R
                    ,A.T_LAST_MODIFIED_DATE_R
                    ,A.V_CREATED_BY_R
                    ,A.V_LAST_MODIFIED_BY_R
                    ,A.D_CYCLE_DATE_R
                    ,A.FIC_MIS_DATE_R
                    ,A.V_SOURCE_SYSTEM_NAME_R
                    ,A.V_SUBJECT_AREA_TYPE_R
                    ,A.N_VERSION_NUMBER_R
                    ,A.F_PHYSICAL_DELETE_R
                    ,A.V_CHANGE_REASON_R
                    ,A.V_POLICY_SUFFIX_R
                    ,A.N_POLICY_SK_R
                    ,A.N_CLAIM_SK_R
                    ,A.N_PARTY_SK_R
                    ,A.N_QUOTE_SK_R
                    ,A.V_POLICY_SFX_R
                    ,A.N_APPLICATION_HISTORY_SK_R
                    ,A.V_ENTITY_TYPE_R
                    ,A.V_CODE_R
                    ,A.V_PRIVACY_INDICATOR_R
                    ,A.N_LOB_APP_COUNT_R
				    --10-Jul-2024 changes ends	
				    ,B.MAX_D_APPLICATION_ENTRY_DATE_R AS D_APP_ENTRY_DATE_R
                    ,CASE WHEN (A.D_APPLICATION_ENTRY_DATE_R-B.MAX_D_APPLICATION_ENTRY_DATE_R) BETWEEN 0 AND 30 THEN '1-30'
                    WHEN (A.D_APPLICATION_ENTRY_DATE_R-B.MAX_D_APPLICATION_ENTRY_DATE_R) BETWEEN 31 AND 60 THEN '31-60'
                    WHEN (A.D_APPLICATION_ENTRY_DATE_R-B.MAX_D_APPLICATION_ENTRY_DATE_R) BETWEEN 61 AND 90 THEN '61-90'
                    ELSE NULL
                    END
                    AS APP_BUCKET
                    ,C.N_APP_PENDING_COUNT_R
                    from FCT_RPT_EOI_HISTORY_R A
                    LEFT OUTER JOIN APP_MAX B
                    ON A.N_APPLICATION_ID_R=B.N_APPLICATION_ID_R
                    LEFT OUTER JOIN APP_PENDING_COUNT_R C
                    ON A.N_APPLICATION_ID_R=C.N_APPLICATION_ID_R;

                        UPDATE FCT_PROC_EXEC_STATUS_LOG_R
                    							SET V_STATUS_R                = 'Successful',
                    							T_EXECUTION_END_TIMESTAMP_R = systimestamp
                    							WHERE N_SERIAL_NUM_R          = N_MAX_SERIAL_NUM_R;
                    							COMMIT;



                EXCEPTION
                WHEN OTHERS THEN
                	V_SQLCODE                    := SQLCODE;
                	V_SQLERRM                    := SUBSTR(SYS.STANDARD.SQLERRM,1,500);
                	UPDATE FCT_PROC_EXEC_STATUS_LOG_R
                	SET V_STATUS_R                = 'Failed',
                	T_EXECUTION_END_TIMESTAMP_R = systimestamp,
                	V_ERROR_CODE_R				= V_SQLCODE,
                	V_ERROR_DESC_R				= V_SQLERRM
                	WHERE N_SERIAL_NUM_R          = N_MAX_SERIAL_NUM_R;
                	COMMIT;
                	RAISE;
                END;
            END IF;--IF UPPER(TRIM(P_MV_TBL_NAME)) like  '%FCT_RPT_EOI_HISTORY_R_MV_TBL%' THEN
    --26 July changes ends--
			--19 Sep 2023 changes Starts--
		IF UPPER(TRIM(P_MV_TBL_NAME)) like  '%FCT_CLAIM_PAYMENT_SUMMARY_MV_TBL%' THEN

			Begin
				SELECT SEQ_FCT_PROC_EXEC_STATUS_LOG_R.NEXTVAL INTO N_MAX_SERIAL_NUM_R FROM DUAL;
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
					LN_BATCH_ID_R,--99999999,
					TO_CHAR(sysdate,'yyyymmdd'),
					1,
					'Started',
					SYSTIMESTAMP,
					USER,
					P_MV_TBL_NAME||'.PROC_REFRESH_GRP_M_VIEW_TBLS.FCT_CLAIM_PAYMENT_SUMMARY_MV_TBL',
					N_MAX_SERIAL_NUM_R
					);
				COMMIT;


				EXECUTE IMMEDIATE 'TRUNCATE TABLE FCT_CLAIM_PAYMENT_SUMMARY_MV_TBL PURGE SNAPSHOT LOG';

                INSERT /*+APPEND_VALUES*/ INTO  FCT_CLAIM_PAYMENT_SUMMARY_MV_TBL
                        (V_CLAIM_NUMBER_R
                        ,N_CLAIM_COVERAGE_GROUP_SK_R
                        ,V_COVERAGE_CODE_R
                        ,N_FISCAL_YEAR_R
                        ,N_QUARTER_R
                        ,QTD_GROSS_AMNT
                        ,QTD_TAXABLE_BENEFITS
                        ,QTD_NON_TAXABLE_BENEFITS
                        ,QTD_FIT
                        ,QTD_SIT
                        ,QTD_FICA
                        ,QTD_MEDICARE_TAX
                        ,QTD_FICA_WAGE_BASE
                        ,QTD_MEDICARE_WAGE_BASE
                        ,QTD_FUTA
                        ,QTD_NET_AMT
                        ,YTD_GROSS_AMNT
                        ,YTD_TAXABLE_BENEFITS
                        ,YTD_NON_TAXABLE_BENEFITS
                        ,YTD_FIT
                        ,YTD_SIT
                        ,YTD_FICA
                        ,YTD_MEDICARE_TAX
                        ,YTD_FICA_WAGE_BASE
                        ,YTD_MEDICARE_WAGE_BASE
                        ,YTD_FUTA
                        ,YTD_NET_AMT
                        )
                        WITH FCT_CLAIM_PAYMENT_DETAIL_QTD AS
                        (SELECT
                        F.V_CLAIM_NUMBER_R
                        ,F.N_CLAIM_COVERAGE_GROUP_SK_R
                        ,F.V_COVERAGE_CODE_R
                        ,D.N_FISCAL_YEAR_R
                        ,D.N_QUARTER_R
                        ,SUM(F.N_PAID_AMOUNT_R) QTD_GROSS_AMNT
                        ,SUM(F.N_TAXABLE_BENEFIT_AMT_R) as QTD_TAXABLE_BENEFITS
                        ,SUM(F.N_PAID_AMOUNT_R)-SUM(F.N_TAXABLE_BENEFIT_AMT_R) as QTD_NON_TAXABLE_BENEFITS
                        ,SUM(case when F.V_BENEFIT_CODE_R in ( '099' ) then F.N_PAID_AMOUNT_R else 0 end) QTD_FIT
                        ,SUM(CASE WHEN F.V_BENEFIT_CODE_R IN ( '297' ) THEN F.N_PAID_AMOUNT_R ELSE 0 END) QTD_SIT
                        ,SUM(CASE WHEN F.V_BENEFIT_CODE_R IN ( '098') THEN F.N_PAID_AMOUNT_R ELSE 0 END)  QTD_FICA
                        ,SUM(CASE WHEN F.V_BENEFIT_CODE_R IN ( '298') THEN F.N_PAID_AMOUNT_R ELSE 0 END)  QTD_MEDICARE_TAX
                        ,SUM(CASE WHEN F.V_BENEFIT_CODE_R IN ( '098') THEN F.N_SS_WAGE_BASE_R ELSE 0 END) QTD_FICA_WAGE_BASE
                        ,SUM(CASE WHEN F.V_BENEFIT_CODE_R IN ( '298') THEN F.N_MED_WAGE_BASE_R ELSE 0 END) QTD_MEDICARE_WAGE_BASE
                        ,SUM(case when F.V_BENEFIT_CODE_R in ( '097') then F.N_PAID_AMOUNT_R else 0 end)  QTD_FUTA
                        ,SUM(CASE WHEN F.V_BENEFIT_CODE_R NOT IN ( 'FIC', 'MED') THEN F.N_PAID_AMOUNT_R ELSE 0 END ) QTD_NET_AMT
                        FROM FCT_CLAIM_PAYMENT_DETAIL_R F
                        inner join DIM_TIME_R D on F.D_PAID_DATE_R=D.D_CALENDAR_DATE_R
                        WHERE F.V_CHECK_TYPE_R <> 'OE'
                        and F.V_PAYMENT_TYPE_R <> 'RED'
                        AND D.D_CALENDAR_DATE_R <= SYSDATE
                        GROUP BY
                        F.V_CLAIM_NUMBER_R
                        ,F.N_CLAIM_COVERAGE_GROUP_SK_R
                        ,F.V_COVERAGE_CODE_R
                        ,D.N_FISCAL_YEAR_R
                        ,D.N_QUARTER_R
                        )
                        ,FCT_CLAIM_PAYMENT_DETAIL_YTD as
                        (SELECT
                        F.V_CLAIM_NUMBER_R
                        ,F.N_CLAIM_COVERAGE_GROUP_SK_R
                        ,F.V_COVERAGE_CODE_R
                        ,D.N_FISCAL_YEAR_R
                        ,SUM(F.N_PAID_AMOUNT_R) YTD_GROSS_AMNT
                        ,SUM(F.N_TAXABLE_BENEFIT_AMT_R) as YTD_TAXABLE_BENEFITS
                        ,SUM(F.N_PAID_AMOUNT_R)-SUM(F.N_TAXABLE_BENEFIT_AMT_R) as YTD_NON_TAXABLE_BENEFITS
                        ,SUM(case when F.V_BENEFIT_CODE_R in ( '099' ) then F.N_PAID_AMOUNT_R else 0 end) YTD_FIT
                        ,SUM(CASE WHEN F.V_BENEFIT_CODE_R IN ( '297' ) THEN F.N_PAID_AMOUNT_R ELSE 0 END) YTD_SIT
                        ,SUM(CASE WHEN F.V_BENEFIT_CODE_R IN ( '098') THEN F.N_PAID_AMOUNT_R ELSE 0 END)  YTD_FICA
                        ,SUM(CASE WHEN F.V_BENEFIT_CODE_R IN ( '298') THEN F.N_PAID_AMOUNT_R ELSE 0 END)  YTD_MEDICARE_TAX
                        ,SUM(CASE WHEN F.V_BENEFIT_CODE_R IN ( '098') THEN F.N_SS_WAGE_BASE_R ELSE 0 END) YTD_FICA_WAGE_BASE
                        ,SUM(CASE WHEN F.V_BENEFIT_CODE_R IN ( '298') THEN F.N_MED_WAGE_BASE_R ELSE 0 END) YTD_MEDICARE_WAGE_BASE
                        ,SUM(case when F.V_BENEFIT_CODE_R in ( '097') then F.N_PAID_AMOUNT_R else 0 end)  YTD_FUTA
                        ,SUM(CASE WHEN F.V_BENEFIT_CODE_R NOT IN ( 'FIC', 'MED') THEN F.N_PAID_AMOUNT_R ELSE 0 END ) YTD_NET_AMT
                        FROM FCT_CLAIM_PAYMENT_DETAIL_R F
                        inner join DIM_TIME_R D on F.D_PAID_DATE_R=D.D_CALENDAR_DATE_R
                        WHERE F.V_CHECK_TYPE_R <> 'OE'
                        and F.V_PAYMENT_TYPE_R <> 'RED'
                        AND D.D_CALENDAR_DATE_R <= SYSDATE
                        GROUP BY
                        F.V_CLAIM_NUMBER_R
                        ,F.N_CLAIM_COVERAGE_GROUP_SK_R
                        ,F.V_COVERAGE_CODE_R
                        ,D.N_FISCAL_YEAR_R
                        )
                        SELECT
                        A.V_CLAIM_NUMBER_R
                        ,A.N_CLAIM_COVERAGE_GROUP_SK_R
                        ,A.V_COVERAGE_CODE_R
                        ,A.N_FISCAL_YEAR_R
                        ,A.N_QUARTER_R
                        ,QTD_GROSS_AMNT
                        ,QTD_TAXABLE_BENEFITS
                        ,QTD_NON_TAXABLE_BENEFITS
                        ,QTD_FIT
                        ,QTD_SIT
                        ,QTD_FICA
                        ,QTD_MEDICARE_TAX
                        ,QTD_FICA_WAGE_BASE
                        ,QTD_MEDICARE_WAGE_BASE
                        ,QTD_FUTA
                        ,QTD_NET_AMT
                        ,YTD_GROSS_AMNT
                        ,YTD_TAXABLE_BENEFITS
                        ,YTD_NON_TAXABLE_BENEFITS
                        ,YTD_FIT
                        ,YTD_SIT
                        ,YTD_FICA
                        ,YTD_MEDICARE_TAX
                        ,YTD_FICA_WAGE_BASE
                        ,YTD_MEDICARE_WAGE_BASE
                        ,YTD_FUTA
                        ,YTD_NET_AMT
                        FROM FCT_CLAIM_PAYMENT_DETAIL_QTD A join FCT_CLAIM_PAYMENT_DETAIL_YTD B
                        ON A.V_CLAIM_NUMBER_R=B.V_CLAIM_NUMBER_R AND
                        A.N_FISCAL_YEAR_R=B.N_FISCAL_YEAR_R;

                        UPDATE FCT_PROC_EXEC_STATUS_LOG_R
                    							SET V_STATUS_R                = 'Successful',
                    							T_EXECUTION_END_TIMESTAMP_R = systimestamp
                    							WHERE N_SERIAL_NUM_R          = N_MAX_SERIAL_NUM_R;
                    							COMMIT;



                EXCEPTION
                WHEN OTHERS THEN
                	V_SQLCODE                    := SQLCODE;
                	V_SQLERRM                    := SUBSTR(SYS.STANDARD.SQLERRM,1,500);
                	UPDATE FCT_PROC_EXEC_STATUS_LOG_R
                	SET V_STATUS_R                = 'Failed',
                	T_EXECUTION_END_TIMESTAMP_R = systimestamp,
                	V_ERROR_CODE_R				= V_SQLCODE,
                	V_ERROR_DESC_R				= V_SQLERRM
                	WHERE N_SERIAL_NUM_R          = N_MAX_SERIAL_NUM_R;
                	COMMIT;
                	RAISE;
                END;
            END IF;
		IF UPPER(TRIM(P_MV_TBL_NAME)) like  '%FCT_RPT_EOI_HISTORY_SUMM_MV_TBL%' THEN

			Begin
				SELECT SEQ_FCT_PROC_EXEC_STATUS_LOG_R.NEXTVAL INTO N_MAX_SERIAL_NUM_R FROM DUAL;
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
					LN_BATCH_ID_R,--99999999,
					TO_CHAR(sysdate,'yyyymmdd'),
					1,
					'Started',
					SYSTIMESTAMP,
					USER,
					P_MV_TBL_NAME||'.PROC_REFRESH_GRP_M_VIEW_TBLS.FCT_RPT_EOI_HISTORY_SUMM_MV_TBL',
					N_MAX_SERIAL_NUM_R
					);
				COMMIT;


                 EXECUTE IMMEDIATE 'TRUNCATE TABLE FCT_RPT_EOI_HISTORY_SUMM_MV_TBL PURGE SNAPSHOT LOG';

                 INSERT /*+APPEND_VALUES*/ INTO  FCT_RPT_EOI_HISTORY_SUMM_MV_TBL
                 (N_APPLICATION_ID_R
                 ,V_POLICY_PREFIX_R
                 ,V_POLICY_SFX_R
                 ,D_APPLICATION_ENTRY_DATE_R
                 ,V_CLIENT_NAME_R
                 ,D_APP_ENTRY_DATE_R
                 ,APP_BUCKET
                 ,N_APPROVED_APP_COUNT_R
                 ,N_DECLINED_APP_COUNT_R
                 ,N_INCOMPLETE_APP_COUNT_R
                 ,N_DECLINED_INCOMPLETE_APPCNT_R
                 ,N_PENDING_APP_COUNT_R
                 ,N_POLICY_SK_R
                 ,N_PARTY_SK_R
                 ,APP_DT_MAX_IND
                 )
                 WITH MAX_APP_DT AS
                 (SELECT MAX(D_APPLICATION_ENTRY_DATE_R) AS MAX_APP_ENTRY_DATE_R,
                 N_APPLICATION_ID_R FROM FCT_RPT_EOI_HISTORY_R GROUP BY N_APPLICATION_ID_R)
                 select FCT.N_APPLICATION_ID_R,V_POLICY_PREFIX_R,V_POLICY_SFX_R,D_APPLICATION_ENTRY_DATE_R,V_CLIENT_NAME_R,
                 D_APP_ENTRY_DATE_R,APP_BUCKET,
                 SUM(N_APPROVED_APP_COUNT_R) N_APPROVED_APP_COUNT_R,SUM(N_DECLINED_APP_COUNT_R) N_DECLINED_APP_COUNT_R,
                 SUM(N_INCOMPLETE_APP_COUNT_R) N_INCOMPLETE_APP_COUNT_R,SUM(N_DECLINED_INCOMPLETE_APPCNT_R) N_DECLINED_INCOMPLETE_APPCNT_R,
                 sum(N_PENDING_APP_COUNT_R) N_PENDING_APP_COUNT_R,N_POLICY_SK_R,N_PARTY_SK_R
                 ,CASE WHEN FCT.D_APPLICATION_ENTRY_DATE_R=DT.MAX_APP_ENTRY_DATE_R THEN 'Y' ELSE 'N' END AS APP_DT_MAX_IND
                 from FCT_RPT_EOI_HISTORY_R_MV_TBL FCT
                 LEFT OUTER JOIN MAX_APP_DT DT
                 ON DT.N_APPLICATION_ID_R=FCT.N_APPLICATION_ID_R
                 GROUP BY FCT.N_APPLICATION_ID_R,V_POLICY_PREFIX_R,V_POLICY_SFX_R,D_APPLICATION_ENTRY_DATE_R,V_CLIENT_NAME_R,D_APP_ENTRY_DATE_R,APP_BUCKET,MAX_APP_ENTRY_DATE_R,
                 N_POLICY_SK_R,N_PARTY_SK_R;


                 UPDATE FCT_PROC_EXEC_STATUS_LOG_R
                    							SET V_STATUS_R                = 'Successful',
                    							T_EXECUTION_END_TIMESTAMP_R = systimestamp
                    							WHERE N_SERIAL_NUM_R          = N_MAX_SERIAL_NUM_R;
                    							COMMIT;



                EXCEPTION
                WHEN OTHERS THEN
                	V_SQLCODE                    := SQLCODE;
                	V_SQLERRM                    := SUBSTR(SYS.STANDARD.SQLERRM,1,500);
                	UPDATE FCT_PROC_EXEC_STATUS_LOG_R
                	SET V_STATUS_R                = 'Failed',
                	T_EXECUTION_END_TIMESTAMP_R = systimestamp,
                	V_ERROR_CODE_R				= V_SQLCODE,
                	V_ERROR_DESC_R				= V_SQLERRM
                	WHERE N_SERIAL_NUM_R          = N_MAX_SERIAL_NUM_R;
                	COMMIT;
                	RAISE;
                END;
            END IF;--IF UPPER(TRIM(P_MV_TBL_NAME)) like  '%FCT_RPT_EOI_HISTORY_SUMM_MV_TBL%' THEN
    --19 Sep 2023 changes ends--

	EXCEPTION
	when others then
	V_SQLERRM :=SUBSTR(SQLERRM,1,4000);
		   RAISE_APPLICATION_ERROR(-20111,'Raise Application Error in PROC_REFRESH_GRP_M_VIEW_TBLS :->'||V_SQLERRM);
	End;