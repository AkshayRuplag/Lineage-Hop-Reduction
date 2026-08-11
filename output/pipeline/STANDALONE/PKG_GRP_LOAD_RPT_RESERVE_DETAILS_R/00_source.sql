

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ATOMIC"."PKG_GRP_LOAD_RPT_RESERVE_DETAILS_R"
IS
/***********************************************************************
  Purpose:  This package body contains procedures which loads data into RPT_RESERVE_DETAILS_R
  Dependent SSL tables : RPT_RESERVE_DETAILS_R
   Used DB Objects:FCT_LG_RESERVE_DETAILS_R

  Author     Date     Description
  ---------- -------- -------------------------------------------------
  VGireesh   12-Feb-2024 Initial Creation
  VGireesh   26-Feb-2024 for month end  that the tables start loading data in the next month partition
                      Ex: March data on February 29th (as of 2.28).
                          27th is Feb Fisc Month End    202402  should be truncate and load in 202402 partition
                          28th is feb Fisc Month End +1 202402  should be truncate and load in 202402 partition
                          29th is Feb Fisc Month End +2 202403  should inactive records against the partition 202402 and load data in 202403 partition
  VGireesh   03/04/24 Added Parallel to rebuild index fast  parallel 16 nologging
  Chandra    21/06/24 Added V_PRIMARY_REINSURER_R, V_SECONDARY_REINSURER_R, V_TERNARY_REINSURER_R, N_PRIMARY_REINSURER_REINS_SHARE_PCT_R, N_SECONDARY_REINSURER_REINS_SHARE_PCT_R,
                            N_TERNARY_REINSURER_REINS_SHARE_PCT_R, N_PRIMARY_REINSURER_REINSURANCE_PCT_R, N_SECONDARY_REINSURER_REINSURANCE_PCT_R, N_TERNARY_REINSURER_REINSURANCE_PCT_R, N_TOTAL_REINSURANCE_PCT_R
  VGireesh   13/08/24 Added Added columns
							N_RESERVE_DIRECT_BEST_ESTMT_CEDED_R
							N_CHG_RSRV_DIRECT_BEST_ESTMT_CEDED_R
							N_CHG_RESERVE_DIRECT_FIELD_CEDED_R
							N_CHG_RESERVE_DIRECT_GAAP_CEDED_R
							N_CHG_RESERVE_DIRECT_STAT_CEDED_R
							N_CURRENT_RESERVE_CEDED_R
							N_RESERVE_DIRECT_FIELD_CEDED_R
							N_RESERVE_DIRECT_GAAP_CEDED_R
							N_ORIGINAL_RESERVE_CEDED_R
							N_PRIOR_RESERVE_DIRECT_BEST_ESTMT_CEDED_R
							N_PRIOR_RESERVE_DIRECT_FIELD_CEDED_R
							N_PRIOR_RESERVE_DIRECT_GAAP_CEDED_R
							N_PRIOR_RESERVE_DIRECT_STAT_CEDED_R
							N_RESERVE_DIRECT_STAT_CEDED_R
							N_RESERVE_DIRECT_BEST_ESTMT_NET_R
							N_CHG_RSRV_DIRECT_BEST_ESTMT_NET_R
							N_CHG_RESERVE_DIRECT_FIELD_NET_R
							N_CHG_RESERVE_DIRECT_GAAP_NET_R
							N_CHG_RESERVE_DIRECT_STAT_NET_R
							N_CURRENT_RESERVE_NET_R
							N_RESERVE_DIRECT_FIELD_NET_R
							N_RESERVE_DIRECT_GAAP_NET_R
							N_ORIGINAL_RESERVE_NET_R
							N_PRIOR_RESERVE_DIRECT_BEST_ESTMT_NET_R
							N_PRIOR_RESERVE_DIRECT_FIELD_NET_R
							N_PRIOR_RESERVE_DIRECT_GAAP_NET_R
							N_PRIOR_RESERVE_DIRECT_STAT_NET_R
							N_RESERVE_DIRECT_STAT_NET_R
   VGireesh   13/08/24 Added  below join to fetch N_INSRD_PARTY_SK_R
	                        left join dim_grp_claim_detail_r dim_grp_claim_detail_r
                               on b.N_claim_sk_r = dim_grp_claim_detail_r.n_claim_sk_r
                               and dim_grp_claim_detail_r.v_active_status_r = 'Y'
                            --03/oct/24 changes ends
  -- Suresh   24-01-2025  Added one column N_EMPLOYEE_SK_R
	 Beneshya    18-06-2025  Added columns N_RESERVE_CEDED_STAT_R and N_RESERVE_CEDED_GAAP_R
     Rose		 06/03/26   Commenting prc_upd_del_data and adding PKG_GRP_COMMON_UTIL.
  ***********************************************************************/

--Global Constants
gc_rpt_table_name      	VARCHAR2(50)      	:='RPT_RESERVE_DETAILS_R';
gd_fic_mis_date          DATE;
gc_rebuild_idx_degree	PLS_INTEGER      	:=8;

--Procedure to update prior month active flag and current month partition
PROCEDURE prc_upd_del_data
IS
LN_SQLROWCNT      NUMBER;
LN_CNT            NUMBER;
ld_first_day_date DATE;
--26-Feb-2024 changes starts
ln_fisc_current_month NUMBER;
ln_fisc_prior_month   NUMBER;
ld_fic_mis_date_2     DATE;
--26-Feb-2024 changes ends
BEGIN
    gc_trcmsg:=gc_trcmsg||'3.1 Entered into in prc_upd_del_data'||chr(13);
    /*gc_trcmsg:=gc_trcmsg||'3.2 Get First Day Date of the current month'||chr(13);
	--Get First Day Date of the current month
    SELECT TRUNC(gd_sysdate, 'MONTH') INTO ld_first_day_date
    FROM dual;
    gc_trcmsg:=gc_trcmsg||'3.3 First Day Date of the current month is:->'||ld_first_day_date||chr(13);
	--If First Day date of current month is sysdate then delete all the data as reload is going to happen for Current , Prior and past 6 history months data
    IF TRUNC(ld_first_day_date) =TRUNC(gd_sysdate) THEN
	    --Today is first day of the current month hence Updating v_rpt_active_status_r=N against the records loaded in prior month
   	    gc_trcmsg:=gc_trcmsg||'3.4 Today is first day of the current month hence Updating v_rpt_active_status_r=N against the records loaded in prior month'||CHR(13);
        UPDATE RPT_RESERVE_DETAILS_R
	       SET v_rpt_active_status_r='N'
		      ,v_last_modified_by_r=gc_updby
			  ,t_last_modified_date_r=gd_sysdate
	    --WHERE n_yearmonth_r = gn_prior_month;
	    WHERE n_reportmonth_r = gn_prior_month;
	    ln_sqlrowcnt:=SQL%ROWCOUNT;
	    COMMIT;
   	    gc_trcmsg:=gc_trcmsg||'3.5  Updated v_rpt_active_status_r=N against the records loaded in prior month :->'||ln_sqlrowcnt||chr(13);
	ELSE
	    --Since sysdate is not first day of the current month hence data loaded in Current Month needs to be deleted but prior months data should not be touched
	    gc_trcmsg:=gc_trcmsg||'3.6 Today is not first day of the current month hence Calling procedure prc_trunc_partition to truncate current month partition from main'||chr(13);
        prc_trunc_partition;
	    gc_trcmsg:=gc_trcmsg||'3.7 Completed procedure prc_trunc_partition call from main'||chr(13);
	END IF;*/
  --26-Feb-2024 changes starts
  --Fetch Fisc Month End +2 and Fisc Current Month
  SELECT --D_CALENDAR_DATE_R,D_CALENDAR_DATE_R +1
    D_CALENDAR_DATE_R                  +2 ,
    to_number(TO_CHAR(last_day(sysdate)+1,'YYYYMM'))
  INTO ld_fic_mis_date_2 ,
    ln_fisc_current_month
  FROM DIM_TIME_R D
  WHERE V_END_OF_FISCAL_MONTH_IND_R      = 'Y'
  AND TO_CHAR(D_CALENDAR_DATE_R,'YYYYMM')=TO_CHAR(sysdate,'YYYYMM');
  gc_trcmsg                             :=gc_trcmsg||'3.2 Fisc Month End +2 Day Date of the current month is:->'||ld_fic_mis_date_2||chr(13);
  gc_trcmsg                             :=gc_trcmsg||'3.3 Fisc Current Month of the current month is:->'||ln_fisc_current_month||chr(13);
  IF TRUNC(ld_fic_mis_date_2)            =TRUNC(sysdate) THEN
    ln_fisc_prior_month                 :=to_number(TO_CHAR(ld_fic_mis_date_2,'YYYYMM'));
    gc_trcmsg                           :=gc_trcmsg||'3.3.1 Fisc Prior Month of the current month is:->'||ln_fisc_prior_month||chr(13);
    gc_trcmsg                           :=gc_trcmsg||'3.4 Today Fisc Month End +2 '||ld_fic_mis_date_2||' hence Updating v_rpt_active_status_r=N against the records loaded in prior fisc month which is :->'||ln_fisc_prior_month||CHR(13);
    UPDATE RPT_RESERVE_DETAILS_R
	   SET v_rpt_active_status_r='N'
	      ,v_last_modified_by_r=gc_updby
	      ,t_last_modified_date_r=gd_sysdate
	WHERE n_reportmonth_r = ln_fisc_prior_month;
    ln_sqlrowcnt            :=SQL%ROWCOUNT;
    COMMIT;
    gc_trcmsg       :=gc_trcmsg||'3.5  Updated v_rpt_active_status_r=N against the records loaded in Fisc prior month :->'||ln_fisc_prior_month||' records '||ln_sqlrowcnt||chr(13);
    gc_trcmsg       :=gc_trcmsg||'3.6 Set gn_current_month to  ln_fisc_current_month ';
    gn_current_month:=ln_fisc_current_month;
    gc_trcmsg       :=gc_trcmsg||'3.7 now current month is :->'|| gn_current_month ;
  ELSE
    --If Sysdate is greater than to Fisc Month End +2 and less than last day of the present month then Current Month is next fisc month
	--Ex: if sysdate is  28-MAR-24 which is also Fisc Month end +2 and leass than current month end date 31-MAR-24 then current month 202403 becomes next fisc month which is 202404
	--partition 202404 should be truncated and reloaded
	IF TRUNC(sysdate)>trunc(ld_fic_mis_date_2) and  TRUNC(sysdate)<= trunc(last_day(sysdate)) then
       gc_trcmsg       :=gc_trcmsg||'3.8 Set gn_current_month to  ln_fisc_current_month ';
       gn_current_month:=ln_fisc_current_month;
       gc_trcmsg       :=gc_trcmsg||'3.9 now current month is :->'|| gn_current_month ;
	ELSE
       gc_trcmsg       :=gc_trcmsg||'3.9.1 now current month is :->'|| gn_current_month ;
	END IF;
	--Since sysdate is not fisc month end +2 hence data loaded in Current Month needs to be deleted but prior months data should not be touched
    gc_trcmsg:=gc_trcmsg||'3.10 Today is not fisc month end +2 of the current month hence Calling procedure prc_trunc_partition to truncate current month partition from main'||chr(13);
    prc_trunc_partition;
    gc_trcmsg:=gc_trcmsg||'3.11 Completed procedure prc_trunc_partition call from main'||chr(13);
  END IF;
  --26-Feb-2024 changes ends
	gc_trcmsg:=gc_trcmsg||'3.12 Exit from in prc_upd_del_data'||chr(13);
EXCEPTION
WHEN OTHERS THEN
    gc_errmsg:=SUBSTR(SQLERRM,1,4000);
	gc_trcmsg:=gc_trcmsg||'3.z Error in prc_upd_del_data'||chr(13)||gc_errmsg;
    pkg_grp_log_util.prc_update_log
      (
        gn_out_job_id                 --p_job_id
        ,gc_error_status              --p_job_status
        ,gc_errmsg                    --p_err_msg
        ,gc_trcmsg||chr(13)||gc_errmsg--p_trc_msg
        ,gc_updby                     --p_log_util_called_by_r
      );
    RAISE;

END prc_upd_del_data;
--Procedure to truncate the YEARMONTH partition
PROCEDURE prc_trunc_partition
AS
lc_tbl VARCHAR2(30):='RPT_RESERVE_DETAILS_R';
LC_REBUILD_INDEX varchar2(300);--29-Mar-2024 changes
BEGIN
   GC_TRCMSG:=GC_TRCMSG||'3.7.1 Entered into prc_trunc_partition :->'||'ALTER TABLE '||LC_TBL||' TRUNCATE PARTITION '||'PART_'||LC_TBL||'_'||GN_CURRENT_MONTH||CHR(13);
   execute immediate 'ALTER TABLE '||lc_tbl||' TRUNCATE PARTITION '||'PART_'||lc_tbl||'_'||gn_current_month;
--29-Mar-2024 changes starts
   gc_trcmsg:=gc_trcmsg||'3.7.2 Truncate Partition completed'||chr(13);
  gc_trcmsg:=gc_trcmsg||'3.7.3 Rebuild Unusable PK Index starts'||chr(13);
  FOR I IN
  (SELECT 'ALTER INDEX '
    ||INDEX_NAME
    ||' REBUILD   parallel 16 nologging' REBUILD_INDEX
  FROM ALL_INDEXES
  WHERE TABLE_NAME ='RPT_RESERVE_DETAILS_R'
  AND INDEX_NAME LIKE 'PK_%'
  AND STATUS='UNUSABLE'
  )
  LOOP
    LC_REBUILD_INDEX:=I.REBUILD_INDEX;
    EXECUTE IMMEDIATE LC_REBUILD_INDEX;
  END LOOP;
  GC_TRCMSG:=GC_TRCMSG||'3.7.4 Rebuild Unusable PK Index ends'||CHR(13);
  GC_TRCMSG:=GC_TRCMSG||'3.7.z Exit from prc_trunc_partition'||CHR(13);
--29-Mar-2024 changes ends
EXCEPTION
WHEN OTHERS THEN
    gc_errmsg :=SUBSTR(SQLERRM,1,4000);
    gc_trcmsg:=gc_trcmsg||'2.z Error in prc_trunc_partition'||chr(13);
    pkg_grp_log_util.prc_update_log
      (
        gn_out_job_id                 --p_job_id
        ,gc_error_status              --p_job_status
        ,gc_errmsg                    --p_err_msg
        ,gc_trcmsg||chr(13)||gc_errmsg--p_trc_msg
        ,gc_truncpartby               --p_log_util_called_by_r
      );
    RAISE;
END prc_trunc_partition;
--Main procedures calls other procedure to load data in RPT_CLEINT_DTL_R
PROCEDURE main
IS
VAR_REF_CUR SYS_REFCURSOR;
TYPE var_tbl_type IS TABLE OF RPT_RESERVE_DETAILS_R%ROWTYPE INDEX BY BINARY_INTEGER;
lt_var_tbl_typ var_tbl_type;
ln_rec_cnt NUMBER:=0;
ld_fic_mis_date_2 DATE;
ln_fisc_current_month NUMBER;
BEGIN
    --Call Log Util pkg to Insert entry in PRCS_JOB_LOG_R
	pkg_grp_log_util.prc_insert_log
                       ( p_source              => gc_source
					    ,p_job_nm              => gc_job_name
                        ,p_job_status          => gc_running_status
                        ,p_err_msg             => null
                        ,p_trc_msg             => null
                        ,p_n_batch_id          => gn_sysdt_batchid
                        ,p_log_util_called_by_r=> gc_main_loadedby
						,out_job_id            => gn_out_job_id
						);
    gc_trcmsg:=gc_trcmsg||'1. Entered into main'||chr(13);
    gc_trcmsg:=gc_trcmsg||'gn_current_month     :->'||gn_current_month||chr(13);
    gc_trcmsg:=gc_trcmsg||'gn_prior_month       :->'||gn_prior_month||chr(13);
    --gc_trcmsg:=gc_trcmsg||'1.c gn_prior2prior_month :->'||gn_prior2prior_month||chr(13);
	/*gc_trcmsg:=gc_trcmsg||'3. Call procedure prc_upd_del_data from main'||chr(13);
    PKG_GRP_LOAD_RPT_RESERVE_DETAILS_R.prc_upd_del_data;
    gc_trcmsg:=gc_trcmsg||'3.z Completed Procedure prc_upd_del_data call from main'||chr(13);*/

	/*Common Utility Proc to get month end+2 date and month. Ex: If month end is 29-Aug-2025 then ln_fisc_current_month will be 202509*/
		PKG_GRP_COMMON_UTIL.prc_fisc_month_calc
		(
			p_out_job_id            =>	gn_out_job_id,
			p_Log_seq_num           =>	2,
			ld_fic_mis_date_2       =>	ld_fic_mis_date_2,
			ln_fisc_current_month   =>	ln_fisc_current_month

		);


		gd_fic_mis_date := ld_fic_mis_date_2;--29-Aug-2024 changes

		/*Common Utility Proc to determine current and prior month ; Checks for month end logic and daily load logic as well */
		PKG_GRP_COMMON_UTIL.PRC_GET_CURRENT_PRIOR_MONTH
		(
			p_out_job_id            =>	gn_out_job_id,
			p_Log_seq_num           =>	3,
			P_fic_mis_date       	=>	ld_fic_mis_date_2,
			P_fisc_current_month    =>	ln_fisc_current_month,
			p_current_month         =>	gn_current_month,
			p_prior_month           =>	gn_prior_month
		);

		PKG_GRP_COMMON_UTIL.prc_trunc_partition
		(
			p_out_job_id    	=>	gn_out_job_id,
			p_Log_seq_num   	=>	4,
			p_rpt_table     	=>	gc_rpt_table_name,
			p_idx_num       	=>	gc_rebuild_idx_degree,
			p_current_month     =>	gn_current_month
		);

    gc_trcmsg:=gc_trcmsg||'4. Call prc_get_cur_data to get ref_cursor '||chr(13);
    PKG_GRP_LOAD_RPT_RESERVE_DETAILS_R.prc_get_cur_data (var_ref_cur);
    gc_trcmsg:=gc_trcmsg||'4.z Completed Call Procedure prc_get_cur_data to get ref_cursor'||chr(13);
    gc_trcmsg:=gc_trcmsg||'5 data load starts '||chr(13);
	ln_rec_cnt:=0;
    LOOP
	lt_var_tbl_typ.DELETE;
    FETCH var_ref_cur BULK COLLECT INTO  lt_var_tbl_typ LIMIT gn_bulk_coll_cnt;
     FORALL X in LT_VAR_TBL_TYP.first..LT_VAR_TBL_TYP.last
     INSERT /*+APPEND_VALUES*/ INTO RPT_RESERVE_DETAILS_R VALUES lt_var_tbl_typ(x) ;
	 LN_REC_CNT:=LN_REC_CNT+LT_VAR_TBL_TYP.COUNT;
    commit;
     EXIT WHEN var_ref_cur%NOTFOUND;
    END LOOP;
    gc_trcmsg:=gc_trcmsg||'5.z Data Loaded '||ln_rec_cnt||' records '||chr(13);
 	gc_trcmsg:=gc_trcmsg||'7. Call procedure unusable prc_rebuild_indexes from main'||chr(13);
    PKG_GRP_LOAD_RPT_RESERVE_DETAILS_R.prc_rebuild_indexes;
    gc_trcmsg:=gc_trcmsg||'7.z Completed Procedure unusable prc_rebuild_indexes call from main'||chr(13);
 	--gc_trcmsg:=gc_trcmsg||'8. Gather RPT_RESERVE_DETAILS_R table stats from main'||chr(13);
    --DBMS_STATS.GATHER_TABLE_STATS('ATOMIC','RPT_RESERVE_DETAILS_R');
    --gc_trcmsg:=gc_trcmsg||'8.z Completed Gather RPT_RESERVE_DETAILS_R table stats from main'||chr(13);
    gc_trcmsg:=gc_trcmsg||'1.z Exit from main'||chr(13);
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
    gc_trcmsg:=gc_trcmsg||'1. Error in main'||chr(13);
    pkg_grp_log_util.prc_update_log
      (
        gn_out_job_id                   --p_job_id
        ,gc_error_status                --p_job_status
        ,gc_errmsg                       --p_err_msg
        ,gc_trcmsg||chr(13)||gc_errmsg  --p_trc_msg
        ,gc_main_loadedby               --p_log_util_called_by_r
      );
    RAISE;
END main;

--Procedure to perform ref cursor assignment
PROCEDURE prc_get_cur_data(
    p_out_cursor OUT SYS_REFCURSOR
	)
AS
BEGIN
       gc_trcmsg:=gc_trcmsg||'4.1 Entered into prc_get_cur_data '||chr(13);
	   --Open/Assign SELECT stmnt

        open p_out_cursor for
    SELECT  distinct
      A.N_BEST_ESTIMATE_NET_BENEFIT_R
     ,A.N_RESERVE_DIRECT_BEST_ESTMT_R
     ,A.V_BEST_ESTMT_RESERVE_MODEL_R
     ,A.N_CHG_RSRV_DIRECT_BEST_ESTMT_R
     ,A.N_CHG_RESERVE_DIRECT__FIELD__R
     ,A.N_CHG_RESERVE_DIRECT__GAAP__R
     ,A.N_CHG_RESERVE_DIRECT__STAT__R
     ,A.N_CHECK_NET_BENEFIT_R
     ,A.N_CURRENT_RESERVE_R
     ,A.N_RESERVE_DIRECT__FIELD__R
     ,A.N_FINANCIAL_NET_BENEFIT_R
     ,A.N_RESERVE_DIRECT__GAAP__R
     ,A.N_GROSS_BENEFIT_R
     ,A.N_NET_BENEFIT_R
     ,A.N_ORIGINAL_RESERVE_R
     ,(A.N_RESERVE_DIRECT_BEST_ESTMT_R - A.N_CHG_RSRV_DIRECT_BEST_ESTMT_R) N_PRIOR_RESERVE_DIRECT_BEST_ESTMT_R
     ,(A.N_RESERVE_DIRECT__FIELD__R    - A.N_CHG_RESERVE_DIRECT__FIELD__R)    N_PRIOR_RESERVE_DIRECT_FIELD_R
     ,(A.N_RESERVE_DIRECT__GAAP__R     - A.N_CHG_RESERVE_DIRECT__GAAP__R)      N_PRIOR_RESERVE_DIRECT_GAAP_R
     ,(A.N_RESERVE_DIRECT__STAT__R     - A.N_CHG_RESERVE_DIRECT__STAT__R)      N_PRIOR_RESERVE_DIRECT_STAT_R
     ,A.V_RESERVE_TYPE_IND_R
     ,A.D_RESERVE_VALUATION_DATE_R
     ,A.N_RESERVE_DIRECT__STAT__R
     ,a.n_unadjustd_rsrv_direct_gaap_r
     ,A.N_UNADJUSTD_RSRV_DIRECT_STAT_R
     ,a.n_claim_sk_r
     ,nvl(e.N_CUST_PARTY_SK_R,-1) N_CUST_PARTY_SK_R--TEMP
     ,a.n_policy_sk_r
     ,nvl(b.n_claim_coverage_sk_r,-1) n_claim_coverage_sk_r
     ,nvl(B.N_CLAIM_COVERAGE_GROUP_Sk_R,-1) N_CLAIM_COVERAGE_GROUP_Sk_R
     ,c.N_PRODUCT_SK_R
     ,gc_getcur_loadedby V_LAST_MODIFIED_BY_R
     ,gd_sysdate T_CREATION_DATE_R
     ,gc_getcur_loadedby V_CREATED_BY_R
     ,gd_sysdate T_LAST_MODIFIED_DATE_R
     ,'Y' V_RPT_ACTIVE_STATUS_R
     ,to_number(TO_CHAR(gd_sysdate,'YYYYMMDD')) N_BATCH_ID_R
     --,to_number(TO_CHAR(D_RESERVE_VALUATION_DATE_R,'YYYYMM'))                       N_REPORTMONTH_R --26-Feb-2024 changes
     ,gn_current_month                                                                N_REPORTMONTH_R --26-Feb-2024 changes
     --21-06-2024 Changes Start
     ,A.V_PRIMARY_REINSURER_R
     ,A.V_SECONDARY_REINSURER_R
     ,A.V_TERNARY_REINSURER_R
     ,A.N_PRIMARY_REINSURER_REINS_SHARE_PCT_R
     ,A.N_SECONDARY_REINSURER_REINS_SHARE_PCT_R
     ,A.N_TERNARY_REINSURER_REINS_SHARE_PCT_R
     ,A.N_PRIMARY_REINSURER_REINSURANCE_PCT_R
     ,A.N_SECONDARY_REINSURER_REINSURANCE_PCT_R
     ,A.N_TERNARY_REINSURER_REINSURANCE_PCT_R
     ,A.N_TOTAL_REINSURANCE_PCT_R
     --21-06-2024 Changes End
     --13/8/24 CHANGES STARTS
     ,(A.N_RESERVE_DIRECT_BEST_ESTMT_R  * A.N_TOTAL_REINSURANCE_PCT_R                                   )     N_RESERVE_DIRECT_BEST_ESTMT_CEDED_R
     ,(A.N_CHG_RSRV_DIRECT_BEST_ESTMT_R * A.N_TOTAL_REINSURANCE_PCT_R                                   )     N_CHG_RSRV_DIRECT_BEST_ESTMT_CEDED_R
     ,(A.N_CHG_RESERVE_DIRECT__FIELD__R * A.N_TOTAL_REINSURANCE_PCT_R                                   )     N_CHG_RESERVE_DIRECT_FIELD_CEDED_R
     ,(A.N_CHG_RESERVE_DIRECT__GAAP__R  * A.N_TOTAL_REINSURANCE_PCT_R                                   )     N_CHG_RESERVE_DIRECT_GAAP_CEDED_R
     ,(A.N_CHG_RESERVE_DIRECT__STAT__R  * A.N_TOTAL_REINSURANCE_PCT_R                                   )     N_CHG_RESERVE_DIRECT_STAT_CEDED_R
     ,(A.N_CURRENT_RESERVE_R            * A.N_TOTAL_REINSURANCE_PCT_R                                   )     N_CURRENT_RESERVE_CEDED_R
     ,(A.N_RESERVE_DIRECT__FIELD__R     * A.N_TOTAL_REINSURANCE_PCT_R                                   )     N_RESERVE_DIRECT_FIELD_CEDED_R
     ,(A.N_RESERVE_DIRECT__GAAP__R      * A.N_TOTAL_REINSURANCE_PCT_R                                   )     N_RESERVE_DIRECT_GAAP_CEDED_R
     ,(A.N_ORIGINAL_RESERVE_R           * A.N_TOTAL_REINSURANCE_PCT_R                                   )     N_ORIGINAL_RESERVE_CEDED_R
     ,((A.N_RESERVE_DIRECT_BEST_ESTMT_R - A.N_CHG_RSRV_DIRECT_BEST_ESTMT_R) * A.N_TOTAL_REINSURANCE_PCT_R )     N_PRIOR_RESERVE_DIRECT_BEST_ESTMT_CEDED_R
     ,((A.N_RESERVE_DIRECT__FIELD__R - A.N_CHG_RESERVE_DIRECT__FIELD__R) * A.N_TOTAL_REINSURANCE_PCT_R    )     N_PRIOR_RESERVE_DIRECT_FIELD_CEDED_R
     ,((A.N_RESERVE_DIRECT__GAAP__R - A.N_CHG_RESERVE_DIRECT__GAAP__R) * A.N_TOTAL_REINSURANCE_PCT_R      )     N_PRIOR_RESERVE_DIRECT_GAAP_CEDED_R
     ,((A.N_RESERVE_DIRECT__STAT__R - A.N_CHG_RESERVE_DIRECT__STAT__R) * A.N_TOTAL_REINSURANCE_PCT_R      )     N_PRIOR_RESERVE_DIRECT_STAT_CEDED_R
     ,(A.N_RESERVE_DIRECT__STAT__R * A.N_TOTAL_REINSURANCE_PCT_R                                        )     N_RESERVE_DIRECT_STAT_CEDED_R
     ,(A.N_RESERVE_DIRECT_BEST_ESTMT_R - (A.N_RESERVE_DIRECT_BEST_ESTMT_R * A.N_TOTAL_REINSURANCE_PCT_R)  )     N_RESERVE_DIRECT_BEST_ESTMT_NET_R
     ,(A.N_CHG_RSRV_DIRECT_BEST_ESTMT_R - (A.N_CHG_RSRV_DIRECT_BEST_ESTMT_R * A.N_TOTAL_REINSURANCE_PCT_R))     N_CHG_RSRV_DIRECT_BEST_ESTMT_NET_R
     ,(A.N_CHG_RESERVE_DIRECT__FIELD__R - (A.N_CHG_RESERVE_DIRECT__FIELD__R * A.N_TOTAL_REINSURANCE_PCT_R))     N_CHG_RESERVE_DIRECT_FIELD_NET_R
     ,(A.N_CHG_RESERVE_DIRECT__GAAP__R - (A.N_CHG_RESERVE_DIRECT__GAAP__R * A.N_TOTAL_REINSURANCE_PCT_R)  )     N_CHG_RESERVE_DIRECT_GAAP_NET_R
     ,(A.N_CHG_RESERVE_DIRECT__STAT__R - (A.N_CHG_RESERVE_DIRECT__STAT__R * A.N_TOTAL_REINSURANCE_PCT_R)  )     N_CHG_RESERVE_DIRECT_STAT_NET_R
     ,(A.N_CURRENT_RESERVE_R - (A.N_CURRENT_RESERVE_R * A.N_TOTAL_REINSURANCE_PCT_R)                      )     N_CURRENT_RESERVE_NET_R
     ,(A.N_RESERVE_DIRECT__FIELD__R - (A.N_RESERVE_DIRECT__FIELD__R * A.N_TOTAL_REINSURANCE_PCT_R)        )     N_RESERVE_DIRECT_FIELD_NET_R
     ,(A.N_RESERVE_DIRECT__GAAP__R - (A.N_RESERVE_DIRECT__GAAP__R * (NVL(A.N_TOTAL_REINSURANCE_PCT_R,0)/100))          )     N_RESERVE_DIRECT_GAAP_NET_R -- 24-01-2025 Replace A.N_TOTAL_REINSURANCE_PCT_R to A.N_TOTAL_REINSURANCE_PCT_R/100
     ,(A.N_ORIGINAL_RESERVE_R - (A.N_ORIGINAL_RESERVE_R * A.N_TOTAL_REINSURANCE_PCT_R)                    )     N_ORIGINAL_RESERVE_NET_R
     ,((A.N_RESERVE_DIRECT_BEST_ESTMT_R - A.N_CHG_RSRV_DIRECT_BEST_ESTMT_R) - ((A.N_RESERVE_DIRECT_BEST_ESTMT_R - A.N_CHG_RSRV_DIRECT_BEST_ESTMT_R) * A.N_TOTAL_REINSURANCE_PCT_R))
      N_PRIOR_RESERVE_DIRECT_BEST_ESTMT_NET_R
     ,((A.N_RESERVE_DIRECT__FIELD__R - A.N_CHG_RESERVE_DIRECT__FIELD__R) - ((A.N_RESERVE_DIRECT__FIELD__R - A.N_CHG_RESERVE_DIRECT__FIELD__R) * A.N_TOTAL_REINSURANCE_PCT_R))
      N_PRIOR_RESERVE_DIRECT_FIELD_NET_R
     ,((A.N_RESERVE_DIRECT__GAAP__R - A.N_CHG_RESERVE_DIRECT__GAAP__R) - ((A.N_RESERVE_DIRECT__GAAP__R - A.N_CHG_RESERVE_DIRECT__GAAP__R) * A.N_TOTAL_REINSURANCE_PCT_R))
      N_PRIOR_RESERVE_DIRECT_GAAP_NET_R
     ,((A.N_RESERVE_DIRECT__STAT__R - A.N_CHG_RESERVE_DIRECT__STAT__R) - ((A.N_RESERVE_DIRECT__STAT__R - A.N_CHG_RESERVE_DIRECT__STAT__R) * A.N_TOTAL_REINSURANCE_PCT_R))
      N_PRIOR_RESERVE_DIRECT_STAT_NET_R
     ,(A.N_RESERVE_DIRECT__STAT__R - (A.N_RESERVE_DIRECT__STAT__R * (NVL(A.N_TOTAL_REINSURANCE_PCT_R,0) /100))                   )
      N_RESERVE_DIRECT_STAT_NET_R  -- 24-01-2025 -- Replace (A.N_TOTAL_REINSURANCE_PCT_R ) to (A.N_TOTAL_REINSURANCE_PCT_R /100)
     --13/8/24 CHANGES ENDS
	 ,NVL(DIM_GRP_CLAIM_DETAIL_R.N_INSRD_PARTY_SK_R,-1)     N_INSRD_PARTY_SK_R--03/10/24 changes
     ,dim_employee_r.N_EMPLOYEE_SK_R  N_EMPLOYEE_SK_R -- 24-01-2025  AdDED ONE COLUMN
	 ,A.N_RESERVE_CEDED__GAAP__R N_RESERVE_CEDED_GAAP_R
     ,A.N_RESERVE_CEDED__STAT__R N_RESERVE_CEDED_STAT_R
	 FROM FCT_LG_RESERVE_DETAILS_R  A
     left join rpt_claim_dtl_r b
     on a.v_claim_identifier_r = b.v_claim_identifier_r
     --and b.V_RPT_ACTIVE_STATUS_R = 'Y'
     and B.N_YEARMONTH_R = gn_current_month/*(select max(N_YEARMONTH_R) N_YEARMONTH_R from rpt_claim_dtl_r c where c.v_claim_identifier_r = b.v_claim_identifier_r)*/
     left join mvw_product_sk_lookup c --31230, 31222
     on c.n_claim_sk_r = b.n_claim_sk_r
     and c.v_claim_coverage_code_r = b.v_claim_coverage_code_r
     left join dim_grp_policy_dir_r d
     on a.n_policy_Sk_r = d.n_policy_sk_r
     and d.v_active_status_r = 'Y'
     left join fct_grp_policy_r e
     on d.n_policy_sk_r = e.n_policy_sk_r
     and d.n_policy_version_number_r = e.n_version_number_r
     --03/10/24 changes starts
	 left join dim_grp_claim_detail_r dim_grp_claim_detail_r
        on b.N_claim_sk_r = dim_grp_claim_detail_r.n_claim_sk_r
        and dim_grp_claim_detail_r.v_active_status_r = 'Y'
     --03/10/24 changes ends
      -- 24-01-25 change start
     left join dim_employee_r dim_employee_r
      on dim_grp_claim_detail_r.V_EXAMINER_LOGIN_ID_R = dim_employee_r.V_EMPLOYEE_LOGIN_ID_R
      AND dim_employee_r.V_BUSINESS_UNIT_R = 'Claims'
     -- 24-01-25 change end
     where a.V_RESERVE_TYPE_IND_R not in ( 'I', 'P')
     and a.n_claim_sk_r <> -1
     and to_number(TO_CHAR(D_RESERVE_VALUATION_DATE_R,'YYYYMM'))=gn_current_month
	 ;

    gc_trcmsg:=gc_trcmsg||'4.2 Exit from prc_get_cur_data'||chr(13);
EXCEPTION
WHEN OTHERS THEN
    gc_errmsg :=SUBSTR(SQLERRM,1,4000);
    gc_trcmsg:=gc_trcmsg||'4.z Error in prc_get_cur_data'||chr(13);
    pkg_grp_log_util.prc_update_log
          (
            gn_out_job_id                   --p_job_id
            ,gc_error_status                --p_job_status
            ,gc_errmsg                      --p_err_msg
            ,gc_trcmsg||chr(13)||gc_errmsg  --p_trc_msg
            ,gc_getcur_loadedby             --p_log_util_called_by_r
          );
    RAISE;
END prc_get_cur_data;

--Procedure to rebuild indexes RPT_RESERVE_DETAILS_R
PROCEDURE prc_rebuild_indexes
IS
LC_REBUILD_INDEX  VARCHAR2(300);
BEGIN
   gc_trcmsg:=gc_trcmsg||'7.a Entered into prc_rebuild_indexes'||chr(13);
  FOR I IN ( select
    'ALTER INDEX '||INDEX_NAME||' REBUILD   parallel 16 nologging' REBUILD_INDEX
    from ALL_INDEXES  where TABLE_NAME ='RPT_RESERVE_DETAILS_R'
	AND INDEX_NAME NOT LIKE 'PK_%'
	AND INDEX_NAME NOT LIKE 'FK_%'
	AND STATUS='UNUSABLE'
	)
  LOOP
    LC_REBUILD_INDEX:=I.REBUILD_INDEX;
    EXECUTE IMMEDIATE LC_REBUILD_INDEX;
  END LOOP;
   gc_trcmsg:=gc_trcmsg||'7.z Exit from prc_rebuild_indexes'||chr(13);
EXCEPTION
WHEN OTHERS THEN
    gc_errmsg :=SUBSTR(SQLERRM,1,4000);
    gc_trcmsg:=gc_trcmsg||'7.z Error in prc_rebuild_indexes'||chr(13);
    pkg_grp_log_util.prc_update_log
          (
            gn_out_job_id                   --p_job_id
            ,gc_error_status                --p_job_status
            ,gc_errmsg                      --p_err_msg
            ,gc_trcmsg||chr(13)||gc_errmsg  --p_trc_msg
            ,gc_rebuildindexes             --p_log_util_called_by_r
          );
    RAISE;
end PRC_REBUILD_INDEXES;
END PKG_GRP_LOAD_RPT_RESERVE_DETAILS_R;

