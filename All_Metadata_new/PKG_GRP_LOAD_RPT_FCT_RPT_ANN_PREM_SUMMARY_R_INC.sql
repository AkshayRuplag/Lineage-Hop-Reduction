"PACKAGE              PKG_GRP_LOAD_RPT_FCT_RPT_ANN_PREM_SUMMARY_R_INC
IS
/***********************************************************************
  Purpose:  This package spec contains procedures which loads data into RPT_FCT_RPT_ANN_PREM_SUMMARY_R

  Author     Date     Description
  ---------- -------- -------------------------------------------------
  VGireesh   19-Feb-2024 Initial Creation
  Samba      13-May-2026 Commented  cursor out parameter in prc_get_cur_data as part of Kill/Fill Process
				User Story - 514609
***********************************************************************/

--Global Constants
gd_sysdate               DATE              := TRUNC(SYSDATE);
gn_prior_month           NUMBER            := TO_NUMBER(TO_CHAR(ADD_MONTHS(TRUNC(gd_sysdate, &apos;MM&apos;), -1),&apos;YYYYMM&apos;));
gn_current_month         NUMBER            := TO_NUMBER(TO_CHAR(gd_sysdate,&apos;YYYYMM&apos;));
gn_sysdt_batchid         NUMBER            := TO_NUMBER(TO_CHAR(gd_sysdate,&apos;YYYYMMDD&apos;));
gc_main_loadedby         VARCHAR2(100 CHAR):=&apos;PKG_GRP_LOAD_RPT_FCT_RPT_ANN_PREM_SUMMARY_R_INC.MAIN&apos;      ;
gc_updby                 VARCHAR2(100 CHAR):=&apos;PKG_GRP_LOAD_RPT_FCT_RPT_ANN_PREM_SUMMARY_R_INC.PRC_UPD_DEL_DATA&apos;;
gc_getcur_loadedby       VARCHAR2(100 CHAR):=&apos;PKG_GRP_LOAD_RPT_FCT_RPT_ANN_PREM_SUMMARY_R_INC.PRC_GET_CUR_DATA&apos;;
gc_truncpartby           VARCHAR2(100 CHAR):=&apos;PKG_GRP_LOAD_RPT_FCT_RPT_ANN_PREM_SUMMARY_R_INC.PRC_TRUNC_PARTITION&apos;;
gc_rebuildindexes           VARCHAR2(100 CHAR):=&apos;PKG_GRP_LOAD_RPT_FCT_RPT_ANN_PREM_SUMMARY_R_INC.PRC_REBUILD_INDEXES&apos;;
gc_trcmsg                CLOB              :=&apos;Trace Message:-&gt;&apos;;
gc_job_name              VARCHAR2(50 CHAR) :=&apos;GRP_LOAD_RPT_FCT_RPT_ANN_PREM_SUMMARY_R&apos;;
gn_bulk_coll_cnt         NUMBER            :=10000;
gc_running_status        VARCHAR2(30)      :=&apos;Running&apos;;
gc_error_status          VARCHAR2(30)      :=&apos;Error&apos;;
gc_success_status        VARCHAR2(30)      :=&apos;Success&apos;;
gc_source                VARCHAR2(30)      :=&apos;EDW&apos;;
gc_message_type		 VARCHAR2(30)      :=&apos;Main Procedure&apos;;
gn_job_log_message_id    NUMBER;
--Global Variables
gn_out_job_id            NUMBER;
gc_errmsg                VARCHAR2(4000 CHAR);
--main procedure
PROCEDURE main;
--Procedure declaration for ref cursor assignment
PROCEDURE prc_get_cur_data;
			--(p_out_cursor OUT SYS_REFCURSOR); -- commented as part of Kill FIll Process
--Procedure declaration for updating prior month active flag and current month partition in the table RPT_FCT_RPT_ANN_PREM_SUMMARY_R
PROCEDURE prc_upd_del_data;
--Procedure declaration for truncating the YEARMONTH partition in the table RPT_FCT_RPT_ANN_PREM_SUMMARY_R
PROCEDURE prc_trunc_partition;
--Procedure to rebuild indexes RPT_FCT_RPT_ANN_PREM_SUMMARY_R
PROCEDURE prc_rebuild_indexes;

END PKG_GRP_LOAD_RPT_FCT_RPT_ANN_PREM_SUMMARY_R_INC;PACKAGE BODY PKG_GRP_LOAD_RPT_FCT_RPT_ANN_PREM_SUMMARY_R_INC
IS
/***********************************************************************
  Purpose:  This package body contains procedures which loads data into RPT_FCT_RPT_ANN_PREM_SUMMARY_R
  Dependent SSL tables : RPT_FCT_RPT_ANN_PREM_SUMMARY_R
   Used MV&apos;s           : FCT_RPT_ANN_PREM_SUMMARY_R_mv_ssl uses below tables
                           (FCT_RPT_ANN_PREM_SUMMARY_R
						    ,FCT_GRP_AGENT_POLICY_R_LOOKUP
							,DIM_GRP_PRODUCT_R
							,DIM_GRP_BILLING_POL_BILLGRP_R
							,DIM_GRP_CUSTOMER_BILL_GROUP_R
							)

   Used DB Objects:FCT_LG_RESERVE_DETAILS_R

  Author     Date     Description
  ---------- -------- -------------------------------------------------
  VGireesh   19-Feb-2024 Initial Creation
  VGireesh   26-Feb-2024 for month end  that the tables start loading data in the next month partition
                      Ex: March data on February 29th (as of 2.28).
                          27th is Feb Fisc Month End    202402  should be truncate and load in 202402 partition
                          28th is feb Fisc Month End +1 202402  should be truncate and load in 202402 partition
                          29th is Feb Fisc Month End +2 202403  should inactive records against the partition 202402 and load data in 202403 partition
  VGireesh   29-Mar-2024 Fisc Month changes
  VGireesh   03/04/24 Added Parallel to rebuild index fast  parallel 16 nologging
  Chandra    12/04/24 Added Additional below columns N_CUST_PARTY_SK_R,
                      V_COVERAGE_R,V_IEB_TYPE_R,V_YTD_RENEWAL_TYPE_R,V_VOLUNTARY_IND_R,V_RSO_CODE_R,V_CLIENT_NAME_R,V_master_customer_name_R,
                      T_POLICY_EFFECTIVE_DATE_R,D_policy_termination_date_r,V_agent_Name_r,N_SALES_REPRESENTATIVE_SK_R,V_SALES_REP_NAME_R

  Chandra    14/05/24 Added Additional below columns N_YTD_PRIOR_POLICY_LIVES_R,N_QTD_PRIOR_POLICY_LIVES_R,N_MTD_PRIOR_POLICY_LIVES_R
  Chandra    05/06/24 N_RPT_SPLIT_PERCENTAGE_R Logic Has Been Changed to NVL(N_RPT_SPLIT_PERCENTAGE_R,1)
  Chandra    19/06/24 Changed Logic of N_YTD_NBOC_POLICY_COUNT_R , N_YTD_NBOC_PREMIUM_R
                      added N_YTD_LAPSE_POLICY_COUNT_BYPOL_R,N_YTD_LAPSE_PREMIUM_BYPOL_R ,N_YTD_NEW_POLICY_COUNT_BYPOL_R  ,N_YTD_NEW_PREMIUM_BYPOL_R
  Chandra    10/07/24 Added column N_TOTAL_REINSURANCE_PREM_PCT_R,N_MTD_CURR_PREMIUM_R,N_MTD_CHG_VOLUME_R
  Vgireesh   17/07/24 Added column V_POLICY_RECORD_EXPERIENCE_TYPE_R
  Vgireesh   24/07/24 Added NVL for agent sk -- 	 ,NVL(N_AGENT_SK_R,-1) N_AGENT_SK_R,
  Vgireesh   17/09/24 Addded column V_RPT_CURRENT_RATE_R
  Vgireesh   02/10/24 Addded column V_RPT_CURRENT_RATE_R
  Chandra    13/11/24 Added column V_PRIOR_CARRIER_NAME_R,V_PRIOR_CARRIER_NAME_OVERRIDE_R &amp; intriduced cursor cur_upd_prior_names to update the field.
  Chandra    14/11/24 Added column V_POLICY_PREFIX_R,V_POLICY_SUFFIX_R,V_EXCHANGE_NAME_R,V_RATEBOOK_DESC_R,V_SIC_CATEGORY_R,V_RSO_NAME_R,V_POLICY_CASE_SIZE_R 
                      and cursor cur_upd_pol_pre to update the field.
  Gireesh    22/11/24 Added new columns V_COVERAGE_DESC_R,V_COVERAGE_DESC_SORT_R
  Shreeja:   02/05/2025 remove comment for V_SOURCE_SYSTEM_NAME_R as part of DDL changes in PROD
  Beneshya   16/05/25 Change in V_POLICY_RECORD_EXPERIENCE_TYPE_R Logic
  Rose		 13/03/26 Commenting prc_upd_del_data and adding PKG_GRP_COMMON_UTIL.
  Samba		 12/05/26 Kill/Fill Changes: User Story - 514609
					 	- All code changes are marked with Kill/Fill start and end comment blocks.
					 	- Code changes ensure continuous data availability in reports, replacing the current truncate-and-load approach, which is not partition-exchange based.	
					 	- Retaining old code base of bulk collect load; which can be used when this Package to be converted to incremental processing
 ***********************************************************************/




--Global Constants
gc_rpt_table_name      	VARCHAR2(50)      	:=&apos;RPT_FCT_RPT_ANN_PREM_SUMMARY_R&apos;;
gd_fic_mis_date          DATE;
gc_rebuild_idx_degree	PLS_INTEGER      	:=8;

--Start: kill/fill additions
gv_rpt_table_name        CONSTANT PRCS_JOB_LOG_R.V_JOB_NAME_R%TYPE	 := &apos;RPT_FCT_RPT_ANN_PREM_SUMMARY_R&apos;;	
gv_exg_table_name        CONSTANT PRCS_JOB_LOG_R.V_JOB_NAME_R%TYPE	 := gv_rpt_table_name||&apos;_EXG&apos;;	
gv_schema_owner        	 CONSTANT PRCS_JOB_LOG_R.V_JOB_NAME_R%TYPE	 := &apos;ATOMIC&apos;;
gt_start_time			 TIMESTAMP;
gt_end_time			 	 TIMESTAMP;
gn_run_cnt				 NUMBER;
--End: kill/fill additions

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
    gc_trcmsg:=gc_trcmsg||&apos;3.1 Entered into in prc_upd_del_data&apos;||chr(13);
    /*gc_trcmsg:=gc_trcmsg||&apos;3.2 Get First Day Date of the current month&apos;||chr(13);
	--Get First Day Date of the current month
    SELECT TRUNC(gd_sysdate, &apos;MONTH&apos;) INTO ld_first_day_date
    FROM dual;
    gc_trcmsg:=gc_trcmsg||&apos;3.3 First Day Date of the current month is:-&gt;&apos;||ld_first_day_date||chr(13);
	--If First Day date of current month is sysdate then delete all the data as reload is going to happen for Current , Prior and past 6 history months data
    IF TRUNC(ld_first_day_date) =TRUNC(gd_sysdate) THEN
	    --Today is first day of the current month hence Updating v_rpt_active_status_r=N against the records loaded in prior month
   	    gc_trcmsg:=gc_trcmsg||&apos;3.4 Today is first day of the current month hence Updating v_rpt_active_status_r=N against the records loaded in prior month&apos;||CHR(13);
        UPDATE RPT_FCT_RPT_ANN_PREM_SUMMARY_R
	       SET v_rpt_active_status_r=&apos;N&apos;
		      ,v_last_modified_by_r=gc_updby
			  ,t_last_modified_date_r=gd_sysdate
	    --WHERE n_yearmonth_r = gn_prior_month;
	    WHERE n_reportmonth_r = gn_prior_month;
	    ln_sqlrowcnt:=SQL%ROWCOUNT;
	    COMMIT;
   	    gc_trcmsg:=gc_trcmsg||&apos;3.5  Updated v_rpt_active_status_r=N against the records loaded in prior month :-&gt;&apos;||ln_sqlrowcnt||chr(13);
	ELSE
	    --Since sysdate is not first day of the current month hence data loaded in Current Month needs to be deleted but prior months data should not be touched
	    gc_trcmsg:=gc_trcmsg||&apos;3.6 Today is not first day of the current month hence Calling procedure prc_trunc_partition to truncate current month partition from main&apos;||chr(13);
        prc_trunc_partition;
	    gc_trcmsg:=gc_trcmsg||&apos;3.7 Completed procedure prc_trunc_partition call from main&apos;||chr(13);
	END IF;*/
  --26-Feb-2024 changes starts
  --Fetch Fisc Month End +2 and Fisc Current Month
  SELECT --D_CALENDAR_DATE_R,D_CALENDAR_DATE_R +1
    D_CALENDAR_DATE_R                  +2 ,
    to_number(TO_CHAR(last_day(sysdate)+1,&apos;YYYYMM&apos;))
  INTO ld_fic_mis_date_2 ,
    ln_fisc_current_month
  FROM ATOMIC.DIM_TIME_R D
  WHERE V_END_OF_FISCAL_MONTH_IND_R      = &apos;Y&apos;
  AND TO_CHAR(D_CALENDAR_DATE_R,&apos;YYYYMM&apos;)=TO_CHAR(sysdate,&apos;YYYYMM&apos;);
  gc_trcmsg                             :=gc_trcmsg||&apos;3.2 Fisc Month End +2 Day Date of the current month is:-&gt;&apos;||ld_fic_mis_date_2||chr(13);
  gc_trcmsg                             :=gc_trcmsg||&apos;3.3 Fisc Current Month of the current month is:-&gt;&apos;||ln_fisc_current_month||chr(13);
  IF TRUNC(ld_fic_mis_date_2)            =TRUNC(sysdate) THEN
    ln_fisc_prior_month                 :=to_number(TO_CHAR(ld_fic_mis_date_2,&apos;YYYYMM&apos;));
    gc_trcmsg                           :=gc_trcmsg||&apos;3.3.1 Fisc Prior Month of the current month is:-&gt;&apos;||ln_fisc_prior_month||chr(13);
    gc_trcmsg                           :=gc_trcmsg||&apos;3.4 Today Fisc Month End +2 &apos;||ld_fic_mis_date_2||&apos; hence Updating v_rpt_active_status_r=N against the records loaded in prior fisc month which is :-&gt;&apos;||ln_fisc_prior_month||CHR(13);

	INSERT INTO ATOMIC.SSL_PACKAGE_LOG_TABLE(job_name,process_name, start_date, end_date) 
	VALUES (&apos;PKG_GRP_LOAD_RPT_FCT_RPT_ANN_PREM_SUMMARY_R_INC&apos;,&apos;START:SET PREV FIN MONTH STATUS = N&apos;, SYSDATE, NULL);
	COMMIT;

    UPDATE ATOMIC.RPT_FCT_RPT_ANN_PREM_SUMMARY_R
	   SET v_rpt_active_status_r=&apos;N&apos;
	      ,v_last_modified_by_r=gc_updby
	      ,t_last_modified_date_r=gd_sysdate
	WHERE n_reportmonth_r = ln_fisc_prior_month;
    ln_sqlrowcnt            :=SQL%ROWCOUNT;
    COMMIT;

	INSERT INTO ATOMIC.SSL_PACKAGE_LOG_TABLE(job_name,process_name, start_date, end_date) 
	VALUES (&apos;PKG_GRP_LOAD_RPT_FCT_RPT_ANN_PREM_SUMMARY_R_INC&apos;,&apos;END:SET PREV FIN MONTH STATUS = N&apos;, NULL, SYSDATE);
	COMMIT;



    gc_trcmsg       :=gc_trcmsg||&apos;3.5  Updated v_rpt_active_status_r=N against the records loaded in Fisc prior month :-&gt;&apos;||ln_fisc_prior_month||&apos; records &apos;||ln_sqlrowcnt||chr(13);
    gc_trcmsg       :=gc_trcmsg||&apos;3.6 Set gn_current_month to  ln_fisc_current_month &apos;;
    gn_current_month:=ln_fisc_current_month;
    gc_trcmsg       :=gc_trcmsg||&apos;3.7 now current month is :-&gt;&apos;|| gn_current_month ;
  ELSE
    --If Sysdate is greater than to Fisc Month End +2 and less than last day of the present month then Current Month is next fisc month
	--Ex: if sysdate is  28-MAR-24 which is also Fisc Month end +2 and leass than current month end date 31-MAR-24 then current month 202403 becomes next fisc month which is 202404
	--partition 202404 should be truncated and reloaded
	IF TRUNC(sysdate)&gt;trunc(ld_fic_mis_date_2) and  TRUNC(sysdate)&lt;= trunc(last_day(sysdate)) then
       gc_trcmsg       :=gc_trcmsg||&apos;3.8 Set gn_current_month to  ln_fisc_current_month &apos;;
       gn_current_month:=ln_fisc_current_month;
       gc_trcmsg       :=gc_trcmsg||&apos;3.9 now current month is :-&gt;&apos;|| gn_current_month ;
	ELSE
       gc_trcmsg       :=gc_trcmsg||&apos;3.9.1 now current month is :-&gt;&apos;|| gn_current_month ;
	END IF;
	--Since sysdate is not fisc month end +2 hence data loaded in Current Month needs to be deleted but prior months data should not be touched
    gc_trcmsg:=gc_trcmsg||&apos;3.10 Today is not fisc month end +2 of the current month hence Calling procedure prc_trunc_partition to truncate current month partition from main&apos;||chr(13);


	INSERT INTO ATOMIC.SSL_PACKAGE_LOG_TABLE(job_name,process_name, start_date, end_date) 
	VALUES (&apos;PKG_GRP_LOAD_RPT_FCT_RPT_ANN_PREM_SUMMARY_R_INC&apos;,&apos;START:TRUNCATE-&apos;||gn_current_month ||&apos;-PARTITION DATA&apos;, SYSDATE, NULL);
	COMMIT;

    prc_trunc_partition;

	INSERT INTO ATOMIC.SSL_PACKAGE_LOG_TABLE(job_name,process_name, start_date, end_date) 
	VALUES (&apos;PKG_GRP_LOAD_RPT_FCT_RPT_ANN_PREM_SUMMARY_R_INC&apos;,&apos;END:TRUNCATE-&apos;||gn_current_month ||&apos;-PARTITION DATA&apos;, NULL, SYSDATE);
	COMMIT;


    gc_trcmsg:=gc_trcmsg||&apos;3.11 Completed procedure prc_trunc_partition call from main&apos;||chr(13);
  END IF;

	gc_trcmsg:=gc_trcmsg||&apos;3.12 Exit from in prc_upd_del_data&apos;||chr(13);
EXCEPTION
WHEN OTHERS THEN
    gc_errmsg:=SUBSTR(SQLERRM,1,4000);
	gc_trcmsg:=gc_trcmsg||&apos;3.z Error in prc_upd_del_data&apos;||chr(13)||gc_errmsg;
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
lc_tbl VARCHAR2(30):=&apos;RPT_FCT_RPT_ANN_PREM_SUMMARY_R&apos;;
LC_REBUILD_INDEX varchar2(300);--29-Mar-2024 changes
BEGIN
   GC_TRCMSG:=GC_TRCMSG||&apos;3.7.1 Entered into prc_trunc_partition :-&gt;&apos;||&apos;ALTER TABLE &apos;||LC_TBL||&apos; TRUNCATE PARTITION &apos;||&apos;PART_&apos;||LC_TBL||&apos;_&apos;||GN_CURRENT_MONTH||CHR(13);
   execute immediate &apos;ALTER TABLE &apos;||lc_tbl||&apos; TRUNCATE PARTITION &apos;||&apos;PART_&apos;||lc_tbl||&apos;_&apos;||gn_current_month;
--29-Mar-2024 changes starts
   gc_trcmsg:=gc_trcmsg||&apos;3.7.2 Truncate Partition completed&apos;||chr(13);
  gc_trcmsg:=gc_trcmsg||&apos;3.7.3 Rebuild Unusable PK Index starts&apos;||chr(13);
  FOR I IN
  (SELECT &apos;ALTER INDEX &apos;
    ||INDEX_NAME
    ||&apos; REBUILD  parallel 16 nologging&apos; REBUILD_INDEX
  FROM ALL_INDEXES
  WHERE TABLE_NAME =&apos;RPT_FCT_RPT_ANN_PREM_SUMMARY_R&apos;
  AND INDEX_NAME LIKE &apos;PK_%&apos;
  AND STATUS=&apos;UNUSABLE&apos;
  )
  LOOP
    LC_REBUILD_INDEX:=I.REBUILD_INDEX;
    EXECUTE IMMEDIATE LC_REBUILD_INDEX;
  END LOOP;
  GC_TRCMSG:=GC_TRCMSG||&apos;3.7.4 Rebuild Unusable PK Index ends&apos;||CHR(13);
  GC_TRCMSG:=GC_TRCMSG||&apos;3.7.z Exit from prc_trunc_partition&apos;||CHR(13);
--29-Mar-2024 changes ends
EXCEPTION
WHEN OTHERS THEN
    gc_errmsg :=SUBSTR(SQLERRM,1,4000);
    gc_trcmsg:=gc_trcmsg||&apos;2.z Error in prc_trunc_partition&apos;||chr(13);
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

--Start: Commenting for kill/fill 
/*VAR_REF_CUR SYS_REFCURSOR;
TYPE var_tbl_type IS TABLE OF RPT_FCT_RPT_ANN_PREM_SUMMARY_R%ROWTYPE INDEX BY BINARY_INTEGER;
lt_var_tbl_typ var_tbl_type;*/
--End: Commenting for kill/fill 

ln_rec_cnt NUMBER:=0;
ld_fic_mis_date_2 DATE;
ln_fisc_current_month NUMBER;

--Perf Improvments : Start : Commenting out as part of Perfromance Improvements
/*
--25-06-2024 CHNGES START
CURSOR cur_upd_policy_attr
IS
select   (case
WHEN Sum(NVL(N_YTD_PRIOR_POLICY_COUNT_R,0)) &lt;&gt; 0  and sum(NVL(N_YTD_CURR_POLICY_COUNT_R,0)) = 0 THEN sum(NVL(N_YTD_PRIOR_POLICY_COUNT_R,0)*nvl(N_RPT_SPLIT_PERCENTAGE_R,1))
else 0
end ) as N_YTD_LAPSE_POLICY_COUNT_BYPOL_R,
(case
WHEN sum(NVL(N_YTD_PRIOR_PREMIUM_R,0)) &lt;&gt; 0  and sum(NVL(N_YTD_CURR_PREMIUM_R,0)) = 0 THEN sum(NVL(N_YTD_PRIOR_PREMIUM_R,0)*nvl(N_RPT_SPLIT_PERCENTAGE_R,1))
else 0
end )
 as N_YTD_LAPSE_PREMIUM_BYPOL_R,
(case when sum(NVL(N_YTD_PRIOR_POLICY_COUNT_R,0)) = 0 then sum(NVL(N_YTD_CURR_POLICY_COUNT_R,0) *nvl(N_RPT_SPLIT_PERCENTAGE_R,1)) else 0 end  )
as N_YTD_NEW_POLICY_COUNT_BYPOL_R
,(case when sum(NVL(N_YTD_PRIOR_PREMIUM_R,0)) = 0 then sum(NVL(N_YTD_CURR_PREMIUM_R,0) *nvl(N_RPT_SPLIT_PERCENTAGE_R,1)) else 0 end
)as N_YTD_NEW_PREMIUM_BYPOL_R,
v_policy_number_R,d_cycle_date_r
from RPT_FCT_RPT_ANN_PREM_SUMMARY_R_mv_ssl
WHERE to_number(TO_CHAR(D_CYCLE_DATE_R,&apos;YYYYMM&apos;))=gn_current_month
group by v_policy_number_R,d_cycle_date_r;
TYPE var_upd_policy_attr_tbl_type IS TABLE OF cur_upd_policy_attr%ROWTYPE INDEX BY BINARY_INTEGER;
lt_upd_policy_attr_tbl_typ var_upd_policy_attr_tbl_type;
--25-06-2024 CHANGES END

--17-Jul-2024 changes starts
CURSOR cur_upd_pol_record_exp_typ
IS
SELECT  v_policy_number_R
,(CASE
		WHEN N_MTD_PRIOR_PREMIUM_R_sum &lt;&gt; 0  and N_MTD_CURR_PREMIUM_R_sum &lt;&gt; 0 THEN &apos;Existing&apos;
        WHEN N_MTD_PRIOR_PREMIUM_R_sum &lt;&gt; 0  and  N_MTD_CURR_PREMIUM_R_sum = 0 THEN &apos;Lapse&apos;
		when N_MTD_PRIOR_PREMIUM_R_sum=0 and N_MTD_CURR_PREMIUM_R_sum&lt;&gt;0       THEN  &apos;New&apos;
		ELSE
        NULL
    END) V_POLICY_RECORD_EXPERIENCE_TYPE_R
FROM 
(
*/--select /*+PARALLEL(4)*/
/*		nvl(sum(N_MTD_PRIOR_PREMIUM_R),0) N_MTD_PRIOR_PREMIUM_R_sum
		,nvl(sum(N_MTD_CURR_PREMIUM_R),0)  N_MTD_CURR_PREMIUM_R_sum
		,v_policy_number_R
from RPT_FCT_RPT_ANN_PREM_SUMMARY_R_mv_ssl
WHERE to_number(TO_CHAR(D_CYCLE_DATE_R,&apos;YYYYMM&apos;))=gn_current_month
group by v_policy_number_R,d_cycle_date_r
);
TYPE var_upd_pol_record_exp_typ IS TABLE OF cur_upd_pol_record_exp_typ%ROWTYPE INDEX BY BINARY_INTEGER;
lt_upd_pol_record_exp_typ var_upd_pol_record_exp_typ;
--17-Jul-2024 changes ends
--13-Nov-2024 changes Start
CURSOR cur_upd_prior_names IS 
        SELECT a.N_POLICY_sK_R,
               MAX(V_COMPETITOR_NAME_R) AS V_prior_carrier_name_r,
               MAX(V_RPT_NAME_R) AS V_PRIOR_CARRIER_NAME_OVERRIDE_R,
               MAX(V_RPT_PRIOR_CARRIER_R) AS V_RPT_PRIOR_CARRIER_R

        FROM Dim_Grp_Priorcarrier_Details_R a
        INNER JOIN dim_grp_policy_dir_r b
            ON a.n_policy_sk_r = b.n_policy_sk_r
            AND a.n_version_number_r = b.n_policy_version_number_r
        LEFT JOIN STG_CARRIER_CLEANUP_R c
            ON c.V_CARRIER_NAME_R = a.v_competitor_name_r
        -- The exists clause ensures only matching records in ANN PREM SUMMARY are included
        WHERE a.n_policy_sk_r &lt;&gt; -1
          AND a.V_ACTIVE_STATUS_R = &apos;Y&apos;
          AND b.v_active_status_r = &apos;Y&apos;
          AND EXISTS (
              SELECT 1 
              FROM RPT_FCT_RPT_ANN_PREM_SUMMARY_R cm
              WHERE cm.n_policy_sk_r = a.n_policy_sk_r
                AND cm.n_reportmonth_r = gn_current_month
          )
        GROUP BY a.N_POLICY_sK_R;

    TYPE var_upd_prior_typ IS TABLE OF cur_upd_prior_names%ROWTYPE INDEX BY BINARY_INTEGER;
    lt_upd_prior_typ var_upd_prior_typ;
--13-Nov-2024 changes End
--14/11/24 Changes Start
CURSOR cur_upd_pol_pre IS 
        SELECT rr.V_POLICY_PREFIX_R, rr.V_POLICY_SUFFIX_R, rr.V_EXCHANGE_NAME_R, rr.V_RATEBOOK_DESC_R, pp.V_SIC_CATEGORY_R, 
               pp.V_RSO_NAME_R, rr.V_POLICY_CASE_SIZE_R,rr.n_cust_party_sk_r
        FROM RPT_POLICY_DTL_R rr
        LEFT JOIN RPT_CLIENT_DTL_R pp ON rr.n_cust_party_sk_r = pp.n_cust_party_sk_r
                                       AND rr.n_yearmonth_r = pp.n_yearmonth_r
        WHERE rr.n_cust_party_sk_r &lt;&gt; -1 
              AND pp.n_cust_party_sk_r &lt;&gt; -1
              AND rr.V_RPT_ACTIVE_STATUS_R = &apos;Y&apos;
              AND pp.V_RPT_ACTIVE_STATUS_R = &apos;Y&apos;
              AND EXISTS (SELECT 1 
                          FROM rpt_fct_rpt_ann_prem_summary_r ann_prem
                          WHERE ann_prem.n_cust_party_sk_r = rr.n_cust_party_sk_r
                            AND ann_prem.n_reportmonth_r = gn_current_month)
              AND rr.N_YEARMONTH_R = gn_current_month
        GROUP BY rr.V_POLICY_PREFIX_R, rr.V_POLICY_SUFFIX_R, rr.V_EXCHANGE_NAME_R, rr.V_RATEBOOK_DESC_R, pp.V_SIC_CATEGORY_R, 
               pp.V_RSO_NAME_R, rr.V_POLICY_CASE_SIZE_R,rr.n_cust_party_sk_r;

    TYPE var_upd_pol_pre IS TABLE OF cur_upd_pol_pre%ROWTYPE INDEX BY BINARY_INTEGER;
    lt_upd_pol_pre var_upd_pol_pre;
--14/11/24 Changes End
--19/09/2024 changes starts
CURSOR cur_upd_rate
IS 
SELECT rr.v_rpt_current_rate_r,rr.n_billgroup_sk_r,rr.n_policy_sk_r,rr.n_product_sk_r, rr.n_reportmonth_r
  FROM rpt_rate_r rr
 WHERE  EXISTS (SELECT 1 
                  FROM rpt_fct_rpt_ann_prem_summary_r ann_prem
				 WHERE ann_prem.n_billgroup_sk_r= rr.n_billgroup_sk_r
				   AND ann_prem.n_policy_sk_r   = rr.n_policy_sk_r
				   AND ann_prem.n_product_sk_r  = rr.n_product_sk_r
				   AND ann_prem.n_reportmonth_r = gn_current_month
			   )   
   AND rr.n_reportmonth_r=gn_current_month
GROUP BY rr.v_rpt_current_rate_r,rr.n_billgroup_sk_r,rr.n_policy_sk_r,rr.n_product_sk_r, rr.n_reportmonth_r;

TYPE var_upd_rate_typ IS TABLE OF cur_upd_rate%ROWTYPE INDEX BY BINARY_INTEGER;
lt_upd_rate_typ var_upd_rate_typ;
--19/09/2024 changes ends
*/
--Perf Improvments : End : Commenting out as part of Perfromance Improvements


BEGIN
    --Call Log Util pkg to Insert entry in PRCS_JOB_LOG_R
	pkg_grp_log_util.prc_insert_log
                       ( p_source              =&gt; gc_source
					    ,p_job_nm              =&gt; gc_job_name
                        ,p_job_status          =&gt; gc_running_status
                        ,p_err_msg             =&gt; null
                        ,p_trc_msg             =&gt; null
                        ,p_n_batch_id          =&gt; gn_sysdt_batchid
                        ,p_log_util_called_by_r=&gt; gc_main_loadedby
						,out_job_id            =&gt; gn_out_job_id
						);
    gc_trcmsg:=gc_trcmsg||&apos;1. Entered into main&apos;||chr(13);

	gc_trcmsg:=&apos;1. Entered into Main&apos;;
    /*START: NEW LOGGING MECHANISM CHANGES*/	    
	 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
				   ( p_job_id_r                  	=&gt; gn_out_job_id			
					,p_batch_id_r               	=&gt; gn_sysdt_batchid			
					,p_message_type_r            	=&gt; gc_message_type			
					,p_code_location_r            	=&gt; gc_main_loadedby			
					,p_message_r                  	=&gt; gc_trcmsg				
					,p_count_type_r               	=&gt; NULL						
					,p_count_r                    	=&gt; NULL						
					,p_duration_r                 	=&gt; NULL						
					,p_created_by_r               	=&gt; gc_job_name				
					,out_prcs_job_log_message_id_r	=&gt; gn_job_log_message_id	
					);	


    --gc_trcmsg:=gc_trcmsg||&apos;gn_current_month     :-&gt;&apos;||gn_current_month||chr(13);
    --gc_trcmsg:=gc_trcmsg||&apos;gn_prior_month       :-&gt;&apos;||gn_prior_month||chr(13);
    --gc_trcmsg:=gc_trcmsg||&apos;1.c gn_prior2prior_month :-&gt;&apos;||gn_prior2prior_month||chr(13);
	/*gc_trcmsg:=gc_trcmsg||&apos;3. Call procedure prc_upd_del_data from main&apos;||chr(13);

	INSERT INTO ATOMIC.SSL_PACKAGE_LOG_TABLE(job_name,process_name, start_date, end_date) 
	VALUES (&apos;PKG_GRP_LOAD_RPT_FCT_RPT_ANN_PREM_SUMMARY_R_INC&apos;,&apos;START: Executing prc_upd_del_data Procedure&apos;, SYSDATE, NULL);
	COMMIT;

    PKG_GRP_LOAD_RPT_FCT_RPT_ANN_PREM_SUMMARY_R_INC.prc_upd_del_data;

	INSERT INTO ATOMIC.SSL_PACKAGE_LOG_TABLE(job_name,process_name, start_date, end_date) 
	VALUES (&apos;PKG_GRP_LOAD_RPT_FCT_RPT_ANN_PREM_SUMMARY_R_INC&apos;,&apos;END: Executing prc_upd_del_data Procedure&apos;, NULL, SYSDATE);
	COMMIT;

    gc_trcmsg:=gc_trcmsg||&apos;3.z Completed Procedure prc_upd_del_data call from main&apos;||chr(13);*/

	/*Common Utility Proc to get month end+2 date and month. Ex: If month end is 29-Aug-2025 then ln_fisc_current_month will be 202509*/
		PKG_GRP_COMMON_UTIL.prc_fisc_month_calc 
		(
			p_out_job_id            =&gt;	gn_out_job_id,
			p_Log_seq_num           =&gt;	2,
			ld_fic_mis_date_2       =&gt;	ld_fic_mis_date_2,
			ln_fisc_current_month   =&gt;	ln_fisc_current_month

		);


		gd_fic_mis_date := ld_fic_mis_date_2;--29-Aug-2024 changes

		/*Common Utility Proc to determine current and prior month ; Checks for month end logic and daily load logic as well */
		PKG_GRP_COMMON_UTIL.PRC_GET_CURRENT_PRIOR_MONTH 
		(
			p_out_job_id            =&gt;	gn_out_job_id,
			p_Log_seq_num           =&gt;	3,
			P_fic_mis_date       	=&gt;	ld_fic_mis_date_2,
			P_fisc_current_month    =&gt;	ln_fisc_current_month,
			p_current_month         =&gt;	gn_current_month,
			p_prior_month           =&gt;	gn_prior_month
		);		

		PKG_GRP_COMMON_UTIL.prc_trunc_partition 
		(
			p_out_job_id    	=&gt;	gn_out_job_id,
			p_Log_seq_num   	=&gt;	4,
			p_rpt_table     	=&gt;	gc_rpt_table_name,  
			p_idx_num       	=&gt;	gc_rebuild_idx_degree,
			p_current_month     =&gt;	gn_current_month
		);	

    --gc_trcmsg:=gc_trcmsg||&apos;4. Call prc_get_cur_data to get ref_cursor &apos;||chr(13);

   -- PKG_GRP_LOAD_RPT_FCT_RPT_ANN_PREM_SUMMARY_R_INC.prc_get_cur_data (var_ref_cur); ----Commenting for kill/fill 

	-- Start : Kill/Fill Changes 13th May 2026 	: Added New 
	PKG_GRP_COMMON_UTIL.PRC_CREATE_EXCHANGE_TABLE_DDL
		(
			p_job_id            	=&gt; gn_out_job_id, 
			p_log_seq_num           =&gt; 5, 
			p_main_table_name       =&gt; gv_rpt_table_name,
			p_exg_table_name        =&gt; gv_exg_table_name,
			p_schema_name           =&gt; gv_schema_owner
		);

	PKG_GRP_LOAD_RPT_FCT_RPT_ANN_PREM_SUMMARY_R_INC.prc_get_cur_data;

	-- End : Kill/Fill Changes 13th May 2026 	: Added New 

    --gc_trcmsg:=gc_trcmsg||&apos;4.z Completed Call Procedure prc_get_cur_data to get ref_cursor&apos;||chr(13);
    --gc_trcmsg:=gc_trcmsg||&apos;5 data load starts &apos;||chr(13);

	ln_rec_cnt:=0;
	SELECT COUNT(1) into ln_rec_cnt FROM ATOMIC.RPT_FCT_RPT_ANN_PREM_SUMMARY_R where n_reportmonth_r=gn_current_month;

	INSERT INTO ATOMIC.SSL_PACKAGE_LOG_TABLE(job_name,process_name, start_date, end_date,SOURCE_TABLE_COUNT) 
	VALUES (&apos;PKG_GRP_LOAD_RPT_FCT_RPT_ANN_PREM_SUMMARY_R_INC&apos;,&apos;START: DATA LOAD TO RPT_FCT_RPT_ANN_PREM_SUMMARY_R&apos;, SYSDATE, NULL,ln_rec_cnt);
	COMMIT;


	/*ln_rec_cnt:=0;


    LOOP
	lt_var_tbl_typ.DELETE;
    FETCH var_ref_cur BULK COLLECT INTO  lt_var_tbl_typ LIMIT gn_bulk_coll_cnt;
     FORALL X in LT_VAR_TBL_TYP.first..LT_VAR_TBL_TYP.last
     INSERT /*+APPEND_VALUES*/ /* INTO ATOMIC.RPT_FCT_RPT_ANN_PREM_SUMMARY_R VALUES lt_var_tbl_typ(x) ;
	 LN_REC_CNT:=LN_REC_CNT+LT_VAR_TBL_TYP.COUNT;
    commit;
     EXIT WHEN var_ref_cur%NOTFOUND;
    END LOOP;
    gc_trcmsg:=gc_trcmsg||&apos;5.z Data Loaded &apos;||ln_rec_cnt||&apos; records &apos;||chr(13);
 	gc_trcmsg:=gc_trcmsg||&apos;7. Call procedure unusable prc_rebuild_indexes from main&apos;||chr(13);
	*/

	-- Start : Kill/Fill Changes 13th May 2026 	: Added New 
	-- Partition Exchange Common Utility Called to Move data from Exg table to the Main table Current month Partition
	PKG_GRP_COMMON_UTIL.PRC_PARTITION_EXCHANGE
	(
		p_job_id            	=&gt; gn_out_job_id, 
		p_log_seq_num           =&gt; 7, 
		p_main_table_name       =&gt; gv_rpt_table_name,
		p_exg_table_name        =&gt; gv_exg_table_name,
		p_partition_name        =&gt; &apos;PART_&apos;|| gv_rpt_table_name ||&apos;_&apos;||gn_current_month, 
		p_schema_name           =&gt; gv_schema_owner
	);
	-- End : Kill/Fill Changes 13th May 2026 	: Added New 

	ln_rec_cnt:=0;
	SELECT COUNT(1) into ln_rec_cnt FROM ATOMIC.RPT_FCT_RPT_ANN_PREM_SUMMARY_R where n_reportmonth_r=gn_current_month;

	INSERT INTO ATOMIC.SSL_PACKAGE_LOG_TABLE(job_name,process_name, start_date, end_date,SOURCE_TABLE_COUNT) 
	VALUES (&apos;PKG_GRP_LOAD_RPT_FCT_RPT_ANN_PREM_SUMMARY_R_INC&apos;,&apos;END: DATA LOAD TO RPT_FCT_RPT_ANN_PREM_SUMMARY_R&apos;, NULL,SYSDATE,ln_rec_cnt);
	COMMIT;

	INSERT INTO ATOMIC.SSL_PACKAGE_LOG_TABLE(job_name,process_name, start_date, end_date) 
	VALUES (&apos;PKG_GRP_LOAD_RPT_FCT_RPT_ANN_PREM_SUMMARY_R_INC&apos;,&apos;START: RE-BUILD INDEX&apos;, SYSDATE, NULL);
	COMMIT;

    PKG_GRP_LOAD_RPT_FCT_RPT_ANN_PREM_SUMMARY_R_INC.prc_rebuild_indexes;

	INSERT INTO ATOMIC.SSL_PACKAGE_LOG_TABLE(job_name,process_name, start_date, end_date) 
	VALUES (&apos;PKG_GRP_LOAD_RPT_FCT_RPT_ANN_PREM_SUMMARY_R_INC&apos;,&apos;END: RE-BUILD INDEX&apos;, NULL, SYSDATE);
	COMMIT;

    gc_trcmsg:=gc_trcmsg||&apos;7.z Completed Procedure unusable prc_rebuild_indexes call from main&apos;||chr(13);
 	--gc_trcmsg:=gc_trcmsg||&apos;8. Gather RPT_FCT_RPT_ANN_PREM_SUMMARY_R table stats from main&apos;||chr(13);
    --DBMS_STATS.GATHER_TABLE_STATS(&apos;ATOMIC&apos;,&apos;RPT_FCT_RPT_ANN_PREM_SUMMARY_R&apos;);
    --gc_trcmsg:=gc_trcmsg||&apos;8.z Completed Gather RPT_FCT_RPT_ANN_PREM_SUMMARY_R table stats from main&apos;||chr(13);
    --25-06-2024 CHANGES START
--Perf Improvments : Start : Commenting out as part of Perfromance Improvements
/*
    gc_trcmsg:=gc_trcmsg||&apos;8. Update Attributes of ANN PREM SUMMARY from main Starts&apos;||chr(13);
    OPEN  cur_upd_policy_attr ;
	LOOP
	lt_upd_policy_attr_tbl_typ.DELETE;
    FETCH cur_upd_policy_attr bulk collect into  lt_upd_policy_attr_tbl_typ limit gn_bulk_coll_cnt;
	FORALL X in lt_upd_policy_attr_tbl_typ.first..lt_upd_policy_attr_tbl_typ.last
    UPDATE RPT_FCT_RPT_ANN_PREM_SUMMARY_R
      set N_YTD_LAPSE_POLICY_COUNT_BYPOL_R     =lt_upd_policy_attr_tbl_typ(X).N_YTD_LAPSE_POLICY_COUNT_BYPOL_R
      , N_YTD_LAPSE_PREMIUM_BYPOL_R           =lt_upd_policy_attr_tbl_typ(X).N_YTD_LAPSE_PREMIUM_BYPOL_R
      , N_YTD_NEW_POLICY_COUNT_BYPOL_R=lt_upd_policy_attr_tbl_typ(X).N_YTD_NEW_POLICY_COUNT_BYPOL_R
      , N_YTD_NEW_PREMIUM_BYPOL_R           =lt_upd_policy_attr_tbl_typ(X).N_YTD_NEW_PREMIUM_BYPOL_R
    where v_policy_number_R=lt_upd_policy_attr_tbl_typ(X).v_policy_number_R
	and d_cycle_date_r=lt_upd_policy_attr_tbl_typ(X).d_cycle_date_r
	 and N_REPORTMONTH_R = gn_current_month;
     commit;
     EXIT WHEN cur_upd_policy_attr%NOTFOUND;
    END LOOP;
	CLOSE cur_upd_policy_attr;
    gc_trcmsg:=gc_trcmsg||&apos;8.z Update Attributes of ANN PREM SUMMARY from main End&apos;||chr(13);
    --25-06-2024 CHANGES END
    gc_trcmsg:=gc_trcmsg||&apos;8. Update V_POLICY_RECORD_EXPERIENCE_TYPE_R in ANN PREM SUMMARY from main Starts&apos;||chr(13);
	--17-Jul-2024 changes starts
    OPEN  cur_upd_pol_record_exp_typ ;
	LOOP
	lt_upd_pol_record_exp_typ.DELETE;
    FETCH cur_upd_pol_record_exp_typ bulk collect into  lt_upd_pol_record_exp_typ limit gn_bulk_coll_cnt;
	FORALL X in lt_upd_pol_record_exp_typ.first..lt_upd_pol_record_exp_typ.last
    UPDATE RPT_FCT_RPT_ANN_PREM_SUMMARY_R
      set V_POLICY_RECORD_EXPERIENCE_TYPE_R     =lt_upd_pol_record_exp_typ(X).V_POLICY_RECORD_EXPERIENCE_TYPE_R
    where v_policy_number_R=lt_upd_pol_record_exp_typ(X).v_policy_number_R
	--and d_cycle_date_r=lt_upd_pol_record_exp_typ(X).d_cycle_date_r
	 and N_REPORTMONTH_R = gn_current_month;
     commit;
     EXIT WHEN cur_upd_pol_record_exp_typ%NOTFOUND;
    END LOOP;
	CLOSE cur_upd_pol_record_exp_typ;
    gc_trcmsg:=gc_trcmsg||&apos;8.z Update V_POLICY_RECORD_EXPERIENCE_TYPE_R in ANN PREM SUMMARY from main End&apos;||chr(13);
	--17-Jul-2024 changes end
   --13-Nov-2024 changes Start
    gc_trcmsg:=gc_trcmsg||&apos;9.aa Update V_PRIOR_CARRIER_NAME_R,V_PRIOR_CARRIER_NAME_OVERRIDE_R in ANN PREM SUMMARY from main Starts&apos;||chr(13);
    OPEN cur_upd_prior_names;
    LOOP
        lt_upd_prior_typ.DELETE;
        FETCH cur_upd_prior_names BULK COLLECT INTO lt_upd_prior_typ LIMIT gn_bulk_coll_cnt;

        FORALL x IN lt_upd_prior_typ.FIRST .. lt_upd_prior_typ.LAST
            UPDATE rpt_fct_rpt_ann_prem_summary_r
            SET V_PRIOR_CARRIER_NAME_R = lt_upd_prior_typ(x).V_prior_carrier_name_r,
                V_PRIOR_CARRIER_NAME_OVERRIDE_R = lt_upd_prior_typ(x).V_PRIOR_CARRIER_NAME_OVERRIDE_R
            WHERE n_policy_sk_r = lt_upd_prior_typ(x).n_policy_sk_r
              AND n_reportmonth_r = gn_current_month;
        COMMIT;
        EXIT WHEN cur_upd_prior_names%NOTFOUND;
    END LOOP;

    CLOSE cur_upd_prior_names;
	gc_trcmsg:=gc_trcmsg||&apos;9.a Update V_PRIOR_CARRIER_NAME_R,V_PRIOR_CARRIER_NAME_OVERRIDE_R in ANN PREM SUMMARY from main End&apos;||chr(13);
   --13-Nov-2024 changes End
   --14/11/24 Changes Start
   gc_trcmsg:=gc_trcmsg||&apos;9.ab Update V_POLICY_PREFIX_R,V_POLICY_SUFFIX_R,V_EXCHANGE_NAME_R,V_RATEBOOK_DESC_R,V_SIC_CATEGORY_R,V_RSO_NAME_R,V_POLICY_CASE_SIZE_R
                          in ANN PREM SUMMARY from main Starts&apos;||chr(13);
   OPEN cur_upd_pol_pre;
    LOOP
        FETCH cur_upd_pol_pre BULK COLLECT INTO lt_upd_pol_pre LIMIT gn_bulk_coll_cnt;
        FORALL x IN lt_upd_pol_pre.FIRST .. lt_upd_pol_pre.LAST
            UPDATE rpt_fct_rpt_ann_prem_summary_r
            SET V_POLICY_PREFIX_R      = lt_upd_pol_pre(x).V_POLICY_PREFIX_R,   
                V_POLICY_SUFFIX_R      = lt_upd_pol_pre(x).V_POLICY_SUFFIX_R,   
                V_EXCHANGE_NAME_R      = lt_upd_pol_pre(x).V_EXCHANGE_NAME_R,   
                V_RATEBOOK_DESC_R      = lt_upd_pol_pre(x).V_RATEBOOK_DESC_R,   
                V_SIC_CATEGORY_R       = lt_upd_pol_pre(x).V_SIC_CATEGORY_R,    
                V_RSO_NAME_R           = lt_upd_pol_pre(x).V_RSO_NAME_R,        
                V_POLICY_CASE_SIZE_R   = lt_upd_pol_pre(x).V_POLICY_CASE_SIZE_R
            WHERE n_cust_party_sk_r    = lt_upd_pol_pre(x).n_cust_party_sk_r
              AND n_reportmonth_r      = gn_current_month;

        COMMIT;
        EXIT WHEN cur_upd_pol_pre%NOTFOUND;
    END LOOP;
    CLOSE cur_upd_pol_pre;
       gc_trcmsg:=gc_trcmsg||&apos;9.ab Update V_POLICY_PREFIX_R,V_POLICY_SUFFIX_R,V_EXCHANGE_NAME_R,V_RATEBOOK_DESC_R,V_SIC_CATEGORY_R,V_RSO_NAME_R,V_POLICY_CASE_SIZE_R
                          in ANN PREM SUMMARY from main End&apos;||chr(13);
   --14/11/24 Changes End
   	--19/09/2024 changes starts
   gc_trcmsg:=gc_trcmsg||&apos;9. Update V_RPT_CURRENT_RATE_R in ANN PREM SUMMARY from main Starts&apos;||chr(13);

    OPEN  cur_upd_rate ;
	LOOP
	lt_upd_rate_typ.DELETE;
    FETCH cur_upd_rate bulk collect into  lt_upd_rate_typ limit gn_bulk_coll_cnt;
	FORALL X in lt_upd_rate_typ.first..lt_upd_rate_typ.last
    UPDATE rpt_fct_rpt_ann_prem_summary_r
      SET v_rpt_current_rate_r     =lt_upd_rate_typ(x).v_rpt_current_rate_r
    WHERE  n_billgroup_sk_r          = lt_upd_rate_typ(X).n_billgroup_sk_r
	 AND n_policy_sk_r             = lt_upd_rate_typ(X).n_policy_sk_r
	 AND n_product_sk_r            = lt_upd_rate_typ(X).n_product_sk_r
	 AND n_reportmonth_r = gn_current_month;
     commit;
     EXIT WHEN cur_upd_rate%NOTFOUND;
    END LOOP;
	CLOSE cur_upd_rate;
    gc_trcmsg:=gc_trcmsg||&apos;9.z Update V_RPT_CURRENT_RATE_R in ANN PREM SUMMARY from main End&apos;||chr(13);
	--19/09/2024 changes end
    gc_trcmsg:=gc_trcmsg||&apos;1.z Exit from main&apos;||chr(13);*/

    gc_trcmsg:=&apos;1.z Exit from main&apos;;
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
            (	 p_job_id_r                    =&gt; gn_out_job_id						
				,p_batch_id_r                  =&gt; gn_sysdt_batchid					
				,p_message_type_r              =&gt; gc_message_type					
				,p_code_location_r             =&gt; gc_main_loadedby					
				,p_message_r                   =&gt; gc_trcmsg							
				,p_count_type_r                =&gt; NULL								
				,p_count_r                     =&gt; NULL								
				,p_duration_r                  =&gt; NULL								
				,p_created_by_r                =&gt; gc_job_name						
				,out_prcs_job_log_message_id_r =&gt; gn_job_log_message_id				
				);

	pkg_grp_log_util.prc_update_log
      (
        gn_out_job_id                   --p_job_id
        ,gc_success_status              --p_job_status
        ,gc_errmsg                      --p_err_msg
        ,gc_trcmsg                      --p_trc_msg
        ,gc_main_loadedby               --p_log_util_called_by_r
      );

--Perf Improvments : End : Commenting out as part of Perfromance Improvements

EXCEPTION
WHEN OTHERS THEN
    gc_errmsg :=SUBSTR(SQLERRM,1,4000);
    gc_trcmsg:=&apos;1.z Error in main: &apos;||gc_errmsg;

    pkg_grp_log_util.prc_update_log_message_r
			   (   n_prcs_job_log_message_id_r  =&gt; gn_job_log_message_id
				  ,p_err_msg                    =&gt; gc_trcmsg
					   );

	pkg_grp_log_util.prc_update_log
      (
        gn_out_job_id                   --p_job_id
        ,gc_error_status                --p_job_status
        ,gc_errmsg                      --p_err_msg
        ,gc_trcmsg 						--p_trc_msg
        ,gc_main_loadedby               --p_log_util_called_by_r
      );
    RAISE;
END main;

--Procedure to perform ref cursor assignment
PROCEDURE prc_get_cur_data
			--(p_out_cursor OUT SYS_REFCURSOR)  -- commented as part of Kill Fill process

AS
BEGIN
       gc_trcmsg:=gc_trcmsg||&apos;4.1 Entered into prc_get_cur_data &apos;||chr(13);

    gc_trcmsg:=&apos;6.1 Entered into prc_get_cur_data &apos;;
	PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
            (	 p_job_id_r                    =&gt; gn_out_job_id						
				,p_batch_id_r                  =&gt; gn_sysdt_batchid					
				,p_message_type_r              =&gt; gc_message_type					
				,p_code_location_r             =&gt; gc_main_loadedby					
				,p_message_r                   =&gt; gc_trcmsg							
				,p_count_type_r                =&gt; NULL								
				,p_count_r                     =&gt; NULL								
				,p_duration_r                  =&gt; NULL								
				,p_created_by_r                =&gt; gc_job_name						
				,out_prcs_job_log_message_id_r =&gt; gn_job_log_message_id				
				);

	gt_start_time := SYSTIMESTAMP;		

	-- Start : Kill/Fill Changes 13th May 2026
		EXECUTE IMMEDIATE &apos;ALTER SESSION ENABLE PARALLEL DML&apos;; 
	-- End : Kill/Fill Changes 12th May 2026

	gc_trcmsg := &apos;6.2 - Data load starts for _EXG table for Partition Exchange&apos;;
  		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
				( p_job_id_r                    =&gt; gn_out_job_id				
				 ,p_batch_id_r                  =&gt; gn_sysdt_batchid				
				 ,p_message_type_r              =&gt; gc_message_type				
				 ,p_code_location_r             =&gt; gc_main_loadedby			
				 ,p_message_r                   =&gt; gc_trcmsg					
				 ,p_count_type_r                =&gt; NULL							
				 ,p_count_r                     =&gt; NULL							
				 ,p_duration_r                  =&gt; NULL							
				 ,p_created_by_r                =&gt; gc_job_name					
				 ,out_prcs_job_log_message_id_r =&gt; gn_job_log_message_id	
				);	

	--Open/Assign SELECT stmnt --Kill/Fill Changes 13th May 2026: Commented following 

    --open P_OUT_CURSOR for		--Kill/Fill Changes 13th May 2026: Commented following 

	--Perf Improvments : Start : Commenting out as part of Perfromance Improvements
	/*	
    SELECT
         distinct
        -- ADDED
        NVL(N_RPT_SPLIT_PERCENTAGE_R,1) AS  N_AGENT_SHARE_R,
        V_SHORT_NAME_R AS V_CARRIER_SHORT_NAME_R,
        N_GROSS_LIVES_R*NVL(N_RPT_SPLIT_PERCENTAGE_R,1) as N_GROSS_LIVES_R,
        N_ANNUALIZED_PREMIUM_R*NVL(N_RPT_SPLIT_PERCENTAGE_R,1) as N_ANNUALIZED_PREMIUM_R,
        D_CYCLE_DATE_R AS D_CYCLE_DATE_R,
        N_POLICY_COUNT_R *NVL(N_RPT_SPLIT_PERCENTAGE_R,1)  as N_POLICY_COUNT_R,
        N_CLIENT_LIVES_R *NVL(N_RPT_SPLIT_PERCENTAGE_R,1)  as N_CLIENT_LIVES_R ,
        N_YTD_CURR_PREMIUM_R *NVL(N_RPT_SPLIT_PERCENTAGE_R,1) as N_YTD_CURR_PREMIUM_R,
        N_YTD_CURR_POLICY_COUNT_R *NVL(N_RPT_SPLIT_PERCENTAGE_R,1)  as N_YTD_CURR_POLICY_COUNT_R,
        N_YTD_CURR_POLICY_LIVES_R *NVL(N_RPT_SPLIT_PERCENTAGE_R,1) as N_YTD_CURR_POLICY_LIVES_R,
        case when NVL(N_YTD_PRIOR_PREMIUM_R,0) = 0 THEN &apos;New&apos;
        WHEN  NVL(N_YTD_PRIOR_PREMIUM_R,0) &lt;&gt; 0  and NVL(N_YTD_CURR_PREMIUM_R,0) &lt;&gt; 0 THEN &apos;Existing&apos;
        WHEN NVL(N_YTD_PRIOR_PREMIUM_R,0) &lt;&gt; 0  and NVL(N_YTD_CURR_PREMIUM_R,0) = 0 THEN &apos;Lapse&apos;
        end V_YTD_EXPERIENCE_RECORD_TYPE_R,
        N_MTD_CHG_POLICY_LIVES_R *NVL(N_RPT_SPLIT_PERCENTAGE_R,1)  as N_MTD_CHG_POLICY_LIVES_R ,
        N_MTD_CHG_PREMIUM_R *NVL(N_RPT_SPLIT_PERCENTAGE_R,1)  as N_MTD_CHG_PREMIUM_R ,
        case
        WHEN NVL(N_MTD_PRIOR_POLICY_COUNT_R,0) &lt;&gt; 0  and NVL(N_MTD_CURR_POLICY_COUNT_R,0) = 0 THEN NVL(N_MTD_PRIOR_POLICY_COUNT_R,0)*NVL(N_RPT_SPLIT_PERCENTAGE_R,1)
        else 0
        end N_MTD_LAPSE_POLICY_COUNT_R,
        case
        WHEN NVL(N_MTD_PRIOR_POLICY_LIVES_R,0) &lt;&gt; 0  and NVL(N_MTD_CURR_POLICY_LIVES_R,0) = 0 THEN NVL(N_MTD_PRIOR_POLICY_LIVES_R,0)*NVL(N_RPT_SPLIT_PERCENTAGE_R,1)
        else 0
        end N_MTD_LAPSE_POLICY_LIVES_R,
        case
        WHEN NVL(N_MTD_PRIOR_PREMIUM_R,0) &lt;&gt; 0  and NVL(N_MTD_CURR_PREMIUM_R,0) = 0 THEN NVL(N_MTD_PRIOR_PREMIUM_R,0)*NVL(N_RPT_SPLIT_PERCENTAGE_R,1)
        else 0
        end N_MTD_LAPSE_PREMIUM_R,
        case
        WHEN  NVL(N_MTD_PRIOR_POLICY_COUNT_R,0) &lt;&gt; 0  and NVL(N_MTD_CURR_POLICY_COUNT_R,0) &lt;&gt; 0 THEN NVL(N_MTD_CURR_POLICY_COUNT_R,0) *NVL(N_RPT_SPLIT_PERCENTAGE_R,1)
        else 0
        end N_MTD_NBOC_POLICY_COUNT_R,
        case
        WHEN  NVL(N_MTD_PRIOR_POLICY_LIVES_R,0) &lt;&gt; 0  and NVL(N_MTD_CURR_POLICY_LIVES_R,0) &lt;&gt; 0 THEN NVL(N_MTD_CURR_POLICY_LIVES_R,0) *NVL(N_RPT_SPLIT_PERCENTAGE_R,1)
        else 0
        end N_MTD_NBOC_POLICY_LIVES_R,
        case
        WHEN  NVL(N_MTD_PRIOR_PREMIUM_R,0) &lt;&gt; 0  and NVL(N_MTD_CURR_PREMIUM_R,0) &lt;&gt; 0 THEN NVL(N_MTD_CURR_PREMIUM_R,0) *NVL(N_RPT_SPLIT_PERCENTAGE_R,1)
        else 0
        end N_MTD_NBOC_PREMIUM_R,
        case when NVL(N_MTD_PRIOR_POLICY_COUNT_R,0) = 0 then NVL(N_MTD_CURR_POLICY_COUNT_R,0) *NVL(N_RPT_SPLIT_PERCENTAGE_R,1) else 0 end  N_MTD_NEW_POLICY_COUNT_R,
        case when NVL(N_MTD_PRIOR_POLICY_LIVES_R,0) = 0 then NVL(N_MTD_CURR_POLICY_LIVES_R,0) *NVL(N_RPT_SPLIT_PERCENTAGE_R,1) else 0 end N_MTD_NEW_POLICY_LIVES_R,
        case when NVL(N_MTD_PRIOR_PREMIUM_R,0) = 0 then NVL(N_MTD_CURR_PREMIUM_R,0) *NVL(N_RPT_SPLIT_PERCENTAGE_R,1) else 0 end N_MTD_NEW_PREMIUM_R,
        N_MTD_PRIOR_PREMIUM_R*NVL(N_RPT_SPLIT_PERCENTAGE_R,1) as N_MTD_PRIOR_PREMIUM_R,
        N_MTD_PRIOR_POLICY_COUNT_R*NVL(N_RPT_SPLIT_PERCENTAGE_R,1) as N_MTD_PRIOR_POLICY_COUNT_R,
        N_MTD_PRIOR_LIVES_R*NVL(N_RPT_SPLIT_PERCENTAGE_R,1) as N_MTD_PRIOR_LIVES_R,
        N_QTD_CHG_POLICY_LIVES_R*NVL(N_RPT_SPLIT_PERCENTAGE_R,1)  as N_QTD_CHG_POLICY_LIVES_R,
        N_QTD_CHG_PREMIUM_R*NVL(N_RPT_SPLIT_PERCENTAGE_R,1) as N_QTD_CHG_PREMIUM_R,
        case
        WHEN NVL(N_QTD_PRIOR_POLICY_COUNT_R,0) &lt;&gt; 0  and NVL(N_QTD_CURR_POLICY_COUNT_R,0) = 0 THEN NVL(N_QTD_PRIOR_POLICY_COUNT_R,0)*NVL(N_RPT_SPLIT_PERCENTAGE_R,1)
        else 0
        end N_QTD_LAPSE_POLICY_COUNT_R,
        case
        WHEN NVL(N_QTD_PRIOR_POLICY_LIVES_R,0) &lt;&gt; 0  and NVL(N_QTD_CURR_POLICY_LIVES_R,0) = 0 THEN NVL(N_QTD_PRIOR_POLICY_LIVES_R,0)*NVL(N_RPT_SPLIT_PERCENTAGE_R,1)
        else 0
        end N_QTD_LAPSE_POLICY_LIVES_R,
        case
        WHEN NVL(N_QTD_PRIOR_PREMIUM_R,0) &lt;&gt; 0  and NVL(N_QTD_CURR_PREMIUM_R,0) = 0 THEN NVL(N_QTD_PRIOR_PREMIUM_R,0)*NVL(N_RPT_SPLIT_PERCENTAGE_R,1)
        else 0
        end N_QTD_LAPSE_PREMIUM_R,
        case
        WHEN  NVL(N_QTD_PRIOR_POLICY_COUNT_R,0) &lt;&gt; 0  and NVL(N_QTD_CURR_POLICY_COUNT_R,0) &lt;&gt; 0 THEN NVL(N_QTD_CURR_POLICY_COUNT_R,0) *NVL(N_RPT_SPLIT_PERCENTAGE_R,1)
        else 0
        end N_QTD_NBOC_POLICY_COUNT_R,
        case
        WHEN  NVL(N_QTD_PRIOR_POLICY_LIVES_R,0) &lt;&gt; 0  and NVL(N_QTD_CURR_POLICY_LIVES_R,0) &lt;&gt; 0 THEN NVL(N_QTD_CURR_POLICY_LIVES_R,0) *NVL(N_RPT_SPLIT_PERCENTAGE_R,1)
        else 0
        end N_QTD_NBOC_POLICY_LIVES_R,
        case
        WHEN  NVL(N_QTD_PRIOR_PREMIUM_R,0) &lt;&gt; 0  and NVL(N_QTD_CURR_PREMIUM_R,0) &lt;&gt; 0 THEN NVL(N_QTD_CURR_PREMIUM_R,0) *NVL(N_RPT_SPLIT_PERCENTAGE_R,1)
        else 0
        end N_QTD_NBOC_PREMIUM_R,
        case when NVL(N_QTD_PRIOR_POLICY_COUNT_R,0) = 0 then NVL(N_QTD_CURR_POLICY_COUNT_R,0) *NVL(N_RPT_SPLIT_PERCENTAGE_R,1) else 0 end  N_QTD_NEW_POLICY_COUNT_R,
        case when NVL(N_QTD_PRIOR_POLICY_LIVES_R,0) = 0 then NVL(N_QTD_CURR_POLICY_LIVES_R,0) *NVL(N_RPT_SPLIT_PERCENTAGE_R,1) else 0 end N_QTD_NEW_POLICY_LIVES_R,
        case when NVL(N_QTD_PRIOR_PREMIUM_R,0) = 0 then NVL(N_QTD_CURR_PREMIUM_R,0) *NVL(N_RPT_SPLIT_PERCENTAGE_R,1) else 0 end N_QTD_NEW_PREMIUM_R,
        N_QTD_PRIOR_PREMIUM_R *NVL(N_RPT_SPLIT_PERCENTAGE_R,1)  as N_QTD_PRIOR_PREMIUM_R,
        N_QTD_PRIOR_POLICY_COUNT_R *NVL(N_RPT_SPLIT_PERCENTAGE_R,1)  as N_QTD_PRIOR_POLICY_COUNT_R,
        N_QTD_PRIOR_LIVES_R *NVL(N_RPT_SPLIT_PERCENTAGE_R,1)  as N_QTD_PRIOR_LIVES_R,
        N_YTD_CHG_POLICY_LIVES_R *NVL(N_RPT_SPLIT_PERCENTAGE_R,1)  as N_YTD_CHG_POLICY_LIVES_R,
        N_YTD_CHG_PREMIUM_R *NVL(N_RPT_SPLIT_PERCENTAGE_R,1) as N_YTD_CHG_PREMIUM_R,
        case
        WHEN NVL(N_YTD_PRIOR_POLICY_COUNT_R,0) &lt;&gt; 0  and NVL(N_YTD_CURR_POLICY_COUNT_R,0) = 0 THEN NVL(N_YTD_PRIOR_POLICY_COUNT_R,0)*NVL(N_RPT_SPLIT_PERCENTAGE_R,1)
        else 0
        end N_YTD_LAPSE_POLICY_COUNT_R,
        case
        WHEN NVL(N_YTD_PRIOR_POLICY_LIVES_R,0) &lt;&gt; 0  and NVL(N_YTD_CURR_POLICY_LIVES_R,0) = 0 THEN NVL(N_YTD_PRIOR_POLICY_LIVES_R,0)*NVL(N_RPT_SPLIT_PERCENTAGE_R,1)
        else 0
        end N_YTD_LAPSE_POLICY_LIVES_R,
        case
        WHEN NVL(N_YTD_PRIOR_PREMIUM_R,0) &lt;&gt; 0  and NVL(N_YTD_CURR_PREMIUM_R,0) = 0 THEN NVL(N_YTD_PRIOR_PREMIUM_R,0)*NVL(N_RPT_SPLIT_PERCENTAGE_R,1)
        else 0
        end N_YTD_LAPSE_PREMIUM_R,
        Case
        WHEN  NVL(N_YTD_PRIOR_POLICY_COUNT_R,0) &lt;&gt; 0  and NVL(N_YTD_CURR_POLICY_COUNT_R,0) &lt;&gt; 0 THEN NVL(N_YTD_CHG_POLICY_COUNT_R,0) *nvl(N_RPT_SPLIT_PERCENTAGE_R,1)
        else 0
        end N_YTD_NBOC_POLICY_COUNT_R,
        case
        WHEN  NVL(N_YTD_PRIOR_POLICY_LIVES_R,0) &lt;&gt; 0  and NVL(N_YTD_CURR_POLICY_LIVES_R,0) &lt;&gt; 0 THEN NVL(N_YTD_CURR_POLICY_LIVES_R,0) *NVL(N_RPT_SPLIT_PERCENTAGE_R,1)
        else 0
        end N_YTD_NBOC_POLICY_LIVES_R,
        case
        WHEN  NVL(N_YTD_PRIOR_PREMIUM_R,0) &lt;&gt; 0  and NVL(N_YTD_CURR_PREMIUM_R,0) &lt;&gt; 0 THEN NVL(N_YTD_CHG_PREMIUM_R,0)*nvl(N_RPT_SPLIT_PERCENTAGE_R,1)
        else 0
        end N_YTD_NBOC_PREMIUM_R,
        case when NVL(N_YTD_PRIOR_POLICY_COUNT_R,0) = 0 then NVL(N_YTD_CURR_POLICY_COUNT_R,0) *NVL(N_RPT_SPLIT_PERCENTAGE_R,1) else 0 end  N_YTD_NEW_POLICY_COUNT_R,
        case when NVL(N_YTD_PRIOR_POLICY_LIVES_R,0) = 0 then NVL(N_YTD_CURR_POLICY_LIVES_R,0) *NVL(N_RPT_SPLIT_PERCENTAGE_R,1) else 0 end N_YTD_NEW_POLICY_LIVES_R,
        case when NVL(N_YTD_PRIOR_PREMIUM_R,0) = 0 then NVL(N_YTD_CURR_PREMIUM_R,0) *NVL(N_RPT_SPLIT_PERCENTAGE_R,1) else 0 end N_YTD_NEW_PREMIUM_R,
        N_YTD_PRIOR_PREMIUM_R *NVL(N_RPT_SPLIT_PERCENTAGE_R,1)  as N_YTD_PRIOR_PREMIUM_R,
        N_YTD_PRIOR_POLICY_COUNT_R *NVL(N_RPT_SPLIT_PERCENTAGE_R,1) as N_YTD_PRIOR_POLICY_COUNT_R,
        N_YTD_PRIOR_LIVES_R *NVL(N_RPT_SPLIT_PERCENTAGE_R,1)  as N_YTD_PRIOR_LIVES_R,
        case when NVL(N_MTD_PRIOR_PREMIUM_R,0) = 0 THEN &apos;New&apos;
        WHEN  NVL(N_MTD_PRIOR_PREMIUM_R,0) &lt;&gt; 0  and NVL(N_MTD_CURR_PREMIUM_R,0) &lt;&gt; 0 THEN &apos;Existing&apos;
        WHEN NVL(N_MTD_PRIOR_PREMIUM_R,0) &lt;&gt; 0  and NVL(N_MTD_CURR_PREMIUM_R,0) = 0 THEN &apos;Lapse&apos;
        end V_MTD_EXPERIENCE_RECORD_TYPE_R,
        N_RPT_PRIMARY_INDICATOR_R AS N_RPT_PRIMARY_INDICATOR_R,
        case when NVL(N_QTD_PRIOR_PREMIUM_R,0) = 0 THEN &apos;New&apos;
        WHEN  NVL(N_QTD_PRIOR_PREMIUM_R,0) &lt;&gt; 0  and NVL(N_QTD_CURR_PREMIUM_R,0) &lt;&gt; 0 THEN &apos;Existing&apos;
        WHEN NVL(N_QTD_PRIOR_PREMIUM_R,0) &lt;&gt; 0  and NVL(N_QTD_CURR_PREMIUM_R,0) = 0 THEN &apos;Lapse&apos;
        end V_QTD_EXPERIENCE_RECORD_TYPE_R,
        nvl(n_policy_billgroup_sk_r,-1) as N_BILLGROUP_SK_R,
        V_CUSTOMER_BILL_GROUP_R as V_CUSTOMER_BILL_GROUP_R,
        N_POLICY_SK_R,
        V_POLICY_NUMBER_R as V_POLICY_NUMBER_R,
        nvl(n_product_sk_r, -1) n_product_sk_r ,
        V_COVERAGE_CODE_R as V_COVERAGE_CODE_R,
        V_PLAN_TYPE_R as V_PLAN_TYPE_R,
        V_CLASS_ID_R as V_CLASS_ID_R,
        D_DUE_DATE_R as D_DUE_DATE_R,
        V_PREMIUM_MODE_R as V_PREMIUM_MODE_R,
        N_COVERAGE_LIVES_R *NVL(N_RPT_SPLIT_PERCENTAGE_R,1) as n_coverage_lives_r
     ,gc_getcur_loadedby V_LAST_MODIFIED_BY_R
     ,gd_sysdate T_CREATION_DATE_R
     ,gc_getcur_loadedby V_CREATED_BY_R
     ,gd_sysdate T_LAST_MODIFIED_DATE_R
     ,&apos;Y&apos; V_RPT_ACTIVE_STATUS_R
     ,to_number(TO_CHAR(gd_sysdate,&apos;YYYYMMDD&apos;)) N_BATCH_ID_R
     --,to_number(TO_CHAR(D_CYCLE_DATE_R,&apos;YYYYMM&apos;))                       N_REPORTMONTH_R --26-Feb-2024 changes
     ,gn_current_month	 N_REPORTMONTH_R --26-Feb-2024 changes
	 --24-Jul-2024 changes starts
	 --,N_AGENT_SK_R,
	 ,NVL(N_AGENT_SK_R,-1) N_AGENT_SK_R,
	 --24-Jul-2024 changes ends
	 --12-APR-24 Changes start
	 N_CUST_PARTY_SK_R,
     V_COVERAGE_R,V_IEB_TYPE_R,V_YTD_RENEWAL_TYPE_R,V_VOLUNTARY_IND_R,V_RSO_CODE_R,V_CLIENT_NAME_R,V_master_customer_name_R,
     T_POLICY_EFFECTIVE_DATE_R,D_policy_termination_date_r,V_agent_Name_r,N_SALES_REPRESENTATIVE_SK_R,V_SALES_REP_NAME_R,
          --19-06-24 Changes start
     N_YTD_PRIOR_POLICY_LIVES_R*NVL(N_RPT_SPLIT_PERCENTAGE_R,1) as N_YTD_PRIOR_POLICY_LIVES_R,
     N_QTD_PRIOR_POLICY_LIVES_R*NVL(N_RPT_SPLIT_PERCENTAGE_R,1) as N_QTD_PRIOR_POLICY_LIVES_R,
     N_MTD_PRIOR_POLICY_LIVES_R*NVL(N_RPT_SPLIT_PERCENTAGE_R,1) as N_MTD_PRIOR_POLICY_LIVES_R,
     CAST(NULL AS Number)        as N_YTD_LAPSE_POLICY_COUNT_BYPOL_R,
     CAST(NULL AS Number)        as N_YTD_LAPSE_PREMIUM_BYPOL_R    ,
     CAST(NULL AS Number)        as N_YTD_NEW_POLICY_COUNT_BYPOL_R  ,
     CAST(NULL AS Number)        as N_YTD_NEW_PREMIUM_BYPOL_R   ,
     CAST(NULL AS VARCHAR2(300)) AS V_SALES_YTD_EXPERIENCE_RECORD_TYPE_R,
     CAST(NULL AS VARCHAR2(300)) as V_SALES_QTD_EXPERIENCE_RECORD_TYPE_R,
     CAST(NULL AS VARCHAR2(300)) AS V_SALES_MTD_EXPERIENCE_RECORD_TYPE_R,
     V_PRIMARY_REINSURER_R       AS V_PRIMARY_REINSURER_R,
     V_SECONDARY_REINSURER_R     AS V_SECONDARY_REINSURER_R,
     V_TERNARY_REINSURER_R       AS V_TERNARY_REINSURER_R,
     CAST(NULL AS Number)        AS N_PRIMARY_REINSURER_REINS_SHARE_PCT_R,
     CAST(NULL AS Number)        AS N_SECONDARY_REINSURER_REINS_SHARE_PCT_R,
     CAST(NULL AS Number)        AS N_TERNARY_REINSURER_REINS_SHARE_PCT_R,
     CAST(NULL AS Number)        AS N_PRIMARY_REINSURER_REINSURANCE_PCT_R,
     CAST(NULL AS Number)        AS N_SECONDARY_REINSURER_REINSURANCE_PCT_R,
     CAST(NULL AS Number)        AS N_TERNARY_REINSURER_REINSURANCE_PCT_R,
     CAST(NULL AS Number)        AS N_TOTAL_REINSURANCE_PCT_R,
     --19-06-24 Changes END
     --10/07/24 Change start
     N_TOTAL_REINSURANCE_PREM_PCT_R,
     N_MTD_CURR_PREMIUM_R,
     N_MTD_CHG_VOLUME_R
     --10/07/24 Change start
	 --17-Jul-2024 changes starts
	 ,cast(null as varchar2(100)) V_POLICY_RECORD_EXPERIENCE_TYPE_R
	 --17-Jul-2024 changes ends
	 --17/09/2024 changes starts
	 ,cast(null as varchar2(300)) V_RPT_CURRENT_RATE_R
	 --17/09/2024 changes ends
	 ,N_VOLUME_R --02/10/24 CHANGES
	 --13/11/24 Changes Start
	 ,CAST(NULL AS VARCHAR2(3000 CHAR)) V_PRIOR_CARRIER_NAME_R
	 ,CAST(NULL AS VARCHAR2(3000 CHAR)) V_PRIOR_CARRIER_NAME_OVERRIDE_R
	 --13/11/24 Changes End
     --14/11/24 Changes Start
     ,CAST(NULL AS VARCHAR2(3000 CHAR)) V_POLICY_PREFIX_R    
     ,CAST(NULL AS VARCHAR2(3000 CHAR)) V_POLICY_SUFFIX_R    
     ,CAST(NULL AS VARCHAR2(3000 CHAR)) V_EXCHANGE_NAME_R    
     ,CAST(NULL AS VARCHAR2(3000 CHAR)) V_RATEBOOK_DESC_R    
     ,CAST(NULL AS VARCHAR2(3000 CHAR)) V_SIC_CATEGORY_R     
     ,CAST(NULL AS VARCHAR2(3000 CHAR)) V_RSO_NAME_R         
     ,CAST(NULL AS VARCHAR2(3000 CHAR)) V_POLICY_CASE_SIZE_R 
     --14/11/24 Changes Ends
     --22/11/24 Changes Start
     ,V_COVERAGE_DESC_R
	 ,V_COVERAGE_DESC_SORT_R
     --22/11/24 Changes ends
	 FROM RPT_FCT_RPT_ANN_PREM_SUMMARY_R_MV_SSL
      WHERE to_number(TO_CHAR(D_CYCLE_DATE_R,&apos;YYYYMM&apos;))=gn_current_month
	 ;
*/
	 --Perf Improvments : End : Commenting out as part of Perfromance Improvements

	--Perf Improvments : Start : Adding New consolidated query which includes exsisting logic and all updates done using cursors.

	INSERT /*+ APPEND PARALLEL(stg, 8) */ INTO RPT_FCT_RPT_ANN_PREM_SUMMARY_R_EXG stg    ----  Added following  for Kill/Fill Changes 13th May 2026
	SELECT /*+ PARALLEL(8) */ 															 ----  Added following  for Kill/Fill Changes 13th May 2026
         distinct
        -- ADDED
        NVL(main.N_RPT_SPLIT_PERCENTAGE_R,1) 			                        AS  N_AGENT_SHARE_R,
        main.V_SHORT_NAME_R                                                     AS V_CARRIER_SHORT_NAME_R,
        main.N_GROSS_LIVES_R 			* NVL(main.N_RPT_SPLIT_PERCENTAGE_R,1)  as N_GROSS_LIVES_R,
        main.N_ANNUALIZED_PREMIUM_R		* NVL(main.N_RPT_SPLIT_PERCENTAGE_R,1)  as N_ANNUALIZED_PREMIUM_R,
        main.D_CYCLE_DATE_R                                                     AS D_CYCLE_DATE_R,
        main.N_POLICY_COUNT_R 			* NVL(main.N_RPT_SPLIT_PERCENTAGE_R,1)  as N_POLICY_COUNT_R,
        main.N_CLIENT_LIVES_R 			* NVL(main.N_RPT_SPLIT_PERCENTAGE_R,1)  as N_CLIENT_LIVES_R ,
        main.N_YTD_CURR_PREMIUM_R 		* NVL(main.N_RPT_SPLIT_PERCENTAGE_R,1)  as N_YTD_CURR_PREMIUM_R,
        main.N_YTD_CURR_POLICY_COUNT_R 	* NVL(main.N_RPT_SPLIT_PERCENTAGE_R,1)  as N_YTD_CURR_POLICY_COUNT_R,
        main.N_YTD_CURR_POLICY_LIVES_R 	* NVL(main.N_RPT_SPLIT_PERCENTAGE_R,1)  as N_YTD_CURR_POLICY_LIVES_R,

        CASE 
			WHEN NVL(main.N_YTD_PRIOR_PREMIUM_R,0) = 0 
			THEN &apos;New&apos;
			WHEN  NVL(main.N_YTD_PRIOR_PREMIUM_R,0) &lt;&gt; 0  and NVL(main.N_YTD_CURR_PREMIUM_R,0) &lt;&gt; 0 THEN &apos;Existing&apos;
			WHEN  NVL(main.N_YTD_PRIOR_PREMIUM_R,0) &lt;&gt; 0  and NVL(main.N_YTD_CURR_PREMIUM_R,0) = 0 THEN &apos;Lapse&apos;
        END as V_YTD_EXPERIENCE_RECORD_TYPE_R,

        main.N_MTD_CHG_POLICY_LIVES_R 	* NVL(main.N_RPT_SPLIT_PERCENTAGE_R,1)  as N_MTD_CHG_POLICY_LIVES_R ,
        main.N_MTD_CHG_PREMIUM_R 		* NVL(main.N_RPT_SPLIT_PERCENTAGE_R,1)  as N_MTD_CHG_PREMIUM_R ,

        CASE
			WHEN NVL(main.N_MTD_PRIOR_POLICY_COUNT_R,0) &lt;&gt; 0  and NVL(main.N_MTD_CURR_POLICY_COUNT_R,0) = 0 
			THEN NVL(main.N_MTD_PRIOR_POLICY_COUNT_R,0)	* 	NVL(main.N_RPT_SPLIT_PERCENTAGE_R,1)
			ELSE 0
        END as N_MTD_LAPSE_POLICY_COUNT_R,

        CASE
			WHEN NVL(main.N_MTD_PRIOR_POLICY_LIVES_R,0) &lt;&gt; 0  and NVL(main.N_MTD_CURR_POLICY_LIVES_R,0) = 0 
			THEN NVL(main.N_MTD_PRIOR_POLICY_LIVES_R,0)		*	  NVL(main.N_RPT_SPLIT_PERCENTAGE_R,1)
			ELSE 0
        END N_MTD_LAPSE_POLICY_LIVES_R,

        case
			WHEN NVL(main.N_MTD_PRIOR_PREMIUM_R,0) &lt;&gt; 0  and NVL(main.N_MTD_CURR_PREMIUM_R,0) = 0 
			THEN NVL(main.N_MTD_PRIOR_PREMIUM_R,0)*NVL(main.N_RPT_SPLIT_PERCENTAGE_R,1)
			else 0
        end N_MTD_LAPSE_PREMIUM_R,

        case
			WHEN  NVL(main.N_MTD_PRIOR_POLICY_COUNT_R,0) &lt;&gt; 0  and NVL(main.N_MTD_CURR_POLICY_COUNT_R,0) &lt;&gt; 0 
			THEN  NVL(main.N_MTD_CURR_POLICY_COUNT_R,0) *NVL(main.N_RPT_SPLIT_PERCENTAGE_R,1)
			else 0
        end N_MTD_NBOC_POLICY_COUNT_R,

        case
			WHEN  NVL(main.N_MTD_PRIOR_POLICY_LIVES_R,0) &lt;&gt; 0  and NVL(main.N_MTD_CURR_POLICY_LIVES_R,0) &lt;&gt; 0 
			THEN NVL(main.N_MTD_CURR_POLICY_LIVES_R,0) *    NVL(main.N_RPT_SPLIT_PERCENTAGE_R,1)
			else 0
        end N_MTD_NBOC_POLICY_LIVES_R,

        case
			WHEN  NVL(main.N_MTD_PRIOR_PREMIUM_R,0) &lt;&gt; 0  and NVL(main.N_MTD_CURR_PREMIUM_R,0) &lt;&gt; 0 
			THEN NVL(main.N_MTD_CURR_PREMIUM_R,0) *     NVL(main.N_RPT_SPLIT_PERCENTAGE_R,1)
			else 0
        end N_MTD_NBOC_PREMIUM_R,

        case 
			when NVL(main.N_MTD_PRIOR_POLICY_COUNT_R,0) = 0 
			then NVL(main.N_MTD_CURR_POLICY_COUNT_R,0) *    NVL(main.N_RPT_SPLIT_PERCENTAGE_R,1) 
			else 0 
		end  N_MTD_NEW_POLICY_COUNT_R,

        case 
			when NVL(main.N_MTD_PRIOR_POLICY_LIVES_R,0) = 0 
			then NVL(main.N_MTD_CURR_POLICY_LIVES_R,0) *    NVL(main.N_RPT_SPLIT_PERCENTAGE_R,1) 
			ELSE 0 
		end N_MTD_NEW_POLICY_LIVES_R,

        case 
			when NVL(main.N_MTD_PRIOR_PREMIUM_R,0) = 0 
			then NVL(main.N_MTD_CURR_PREMIUM_R,0) * NVL(main.N_RPT_SPLIT_PERCENTAGE_R,1) 
			ELSE 0 
		end N_MTD_NEW_PREMIUM_R,

		main.N_MTD_PRIOR_PREMIUM_R		*	NVL(main.N_RPT_SPLIT_PERCENTAGE_R,1) as N_MTD_PRIOR_PREMIUM_R,
        main.N_MTD_PRIOR_POLICY_COUNT_R	*	NVL(main.N_RPT_SPLIT_PERCENTAGE_R,1) as N_MTD_PRIOR_POLICY_COUNT_R,
        main.N_MTD_PRIOR_LIVES_R		*	NVL(main.N_RPT_SPLIT_PERCENTAGE_R,1) as N_MTD_PRIOR_LIVES_R,
        main.N_QTD_CHG_POLICY_LIVES_R	*	NVL(main.N_RPT_SPLIT_PERCENTAGE_R,1) as N_QTD_CHG_POLICY_LIVES_R,
        main.N_QTD_CHG_PREMIUM_R		*	NVL(main.N_RPT_SPLIT_PERCENTAGE_R,1) as N_QTD_CHG_PREMIUM_R,

        case
			WHEN NVL(main.N_QTD_PRIOR_POLICY_COUNT_R,0) &lt;&gt; 0  and NVL(main.N_QTD_CURR_POLICY_COUNT_R,0) = 0 
			THEN NVL(main.N_QTD_PRIOR_POLICY_COUNT_R,0)	*	      NVL(main.N_RPT_SPLIT_PERCENTAGE_R,1)
			ELSE 0
        end N_QTD_LAPSE_POLICY_COUNT_R,

        case
			WHEN NVL(main.N_QTD_PRIOR_POLICY_LIVES_R,0) &lt;&gt; 0  and NVL(main.N_QTD_CURR_POLICY_LIVES_R,0) = 0 
			THEN NVL(main.N_QTD_PRIOR_POLICY_LIVES_R,0)	*	NVL(main.N_RPT_SPLIT_PERCENTAGE_R,1)
			ELSE 0
        end N_QTD_LAPSE_POLICY_LIVES_R,

        case
			WHEN NVL(main.N_QTD_PRIOR_PREMIUM_R,0) &lt;&gt; 0  and NVL(main.N_QTD_CURR_PREMIUM_R,0) = 0 
			THEN NVL(main.N_QTD_PRIOR_PREMIUM_R,0)	*		NVL(main.N_RPT_SPLIT_PERCENTAGE_R,1)
			ELSE 0
        end N_QTD_LAPSE_PREMIUM_R,

        case
			WHEN  NVL(main.N_QTD_PRIOR_POLICY_COUNT_R,0) &lt;&gt; 0  and NVL(main.N_QTD_CURR_POLICY_COUNT_R,0) &lt;&gt; 0 
			THEN  NVL(main.N_QTD_CURR_POLICY_COUNT_R,0) *		   NVL(main.N_RPT_SPLIT_PERCENTAGE_R,1)
			ELSE 0
        end N_QTD_NBOC_POLICY_COUNT_R,

        case
			WHEN  NVL(main.N_QTD_PRIOR_POLICY_LIVES_R,0) &lt;&gt; 0  and 	NVL(main.N_QTD_CURR_POLICY_LIVES_R,0) &lt;&gt; 0 
			THEN  NVL(main.N_QTD_CURR_POLICY_LIVES_R,0) 	*		NVL(main.N_RPT_SPLIT_PERCENTAGE_R,1)
			ELSE 0
        end N_QTD_NBOC_POLICY_LIVES_R,

        case
			WHEN  NVL(main.N_QTD_PRIOR_PREMIUM_R,0) &lt;&gt; 0  and NVL(main.N_QTD_CURR_PREMIUM_R,0) &lt;&gt; 0 
			THEN  NVL(main.N_QTD_CURR_PREMIUM_R,0) *NVL(main.N_RPT_SPLIT_PERCENTAGE_R,1)
			ELSE 0
        end N_QTD_NBOC_PREMIUM_R,

        case 
			when NVL(main.N_QTD_PRIOR_POLICY_COUNT_R,0) = 0 
			then NVL(main.N_QTD_CURR_POLICY_COUNT_R,0) *NVL(main.N_RPT_SPLIT_PERCENTAGE_R,1) 
			ELSE 0 
		end  N_QTD_NEW_POLICY_COUNT_R,

        case 
			when NVL(main.N_QTD_PRIOR_POLICY_LIVES_R,0) = 0 
			then NVL(main.N_QTD_CURR_POLICY_LIVES_R,0) *NVL(main.N_RPT_SPLIT_PERCENTAGE_R,1) 
			ELSE 0 
		end N_QTD_NEW_POLICY_LIVES_R,

        case 
			when NVL(main.N_QTD_PRIOR_PREMIUM_R,0) = 0 
			then NVL(main.N_QTD_CURR_PREMIUM_R,0) *NVL(main.N_RPT_SPLIT_PERCENTAGE_R,1) 
			else 0 
		end N_QTD_NEW_PREMIUM_R,

        main.N_QTD_PRIOR_PREMIUM_R 		*	NVL(main.N_RPT_SPLIT_PERCENTAGE_R,1)  as N_QTD_PRIOR_PREMIUM_R,
        main.N_QTD_PRIOR_POLICY_COUNT_R *	NVL(main.N_RPT_SPLIT_PERCENTAGE_R,1)  as N_QTD_PRIOR_POLICY_COUNT_R,
        main.N_QTD_PRIOR_LIVES_R 		*	NVL(main.N_RPT_SPLIT_PERCENTAGE_R,1)  as N_QTD_PRIOR_LIVES_R,
        main.N_YTD_CHG_POLICY_LIVES_R 	*	NVL(main.N_RPT_SPLIT_PERCENTAGE_R,1)  as N_YTD_CHG_POLICY_LIVES_R,
        main.N_YTD_CHG_PREMIUM_R 		*	NVL(main.N_RPT_SPLIT_PERCENTAGE_R,1)  as N_YTD_CHG_PREMIUM_R,

        case
			WHEN NVL(main.N_YTD_PRIOR_POLICY_COUNT_R,0) &lt;&gt; 0  and NVL(main.N_YTD_CURR_POLICY_COUNT_R,0) = 0 
			THEN NVL(main.N_YTD_PRIOR_POLICY_COUNT_R,0)	*		  NVL(main.N_RPT_SPLIT_PERCENTAGE_R,1)
			else 0
        end N_YTD_LAPSE_POLICY_COUNT_R,

        case
			WHEN NVL(main.N_YTD_PRIOR_POLICY_LIVES_R,0) &lt;&gt; 0  and NVL(main.N_YTD_CURR_POLICY_LIVES_R,0) = 0 
			THEN NVL(main.N_YTD_PRIOR_POLICY_LIVES_R,0)*NVL(main.N_RPT_SPLIT_PERCENTAGE_R,1)
			else 0
        end N_YTD_LAPSE_POLICY_LIVES_R,

        case
			WHEN NVL(main.N_YTD_PRIOR_PREMIUM_R,0) &lt;&gt; 0  and NVL(main.N_YTD_CURR_PREMIUM_R,0) = 0 
			THEN NVL(main.N_YTD_PRIOR_PREMIUM_R,0)*NVL(main.N_RPT_SPLIT_PERCENTAGE_R,1)
			else 0
        end N_YTD_LAPSE_PREMIUM_R,

        Case
			WHEN  NVL(main.N_YTD_PRIOR_POLICY_COUNT_R,0) &lt;&gt; 0  and NVL(main.N_YTD_CURR_POLICY_COUNT_R,0) &lt;&gt; 0 
			THEN  NVL(main.N_YTD_CHG_POLICY_COUNT_R,0) *	nvl(main.N_RPT_SPLIT_PERCENTAGE_R,1)
			else 0
        end N_YTD_NBOC_POLICY_COUNT_R,

        case
			WHEN  NVL(main.N_YTD_PRIOR_POLICY_LIVES_R,0) &lt;&gt; 0  and NVL(main.N_YTD_CURR_POLICY_LIVES_R,0) &lt;&gt; 0 
			THEN NVL(main.N_YTD_CURR_POLICY_LIVES_R,0) *	NVL(main.N_RPT_SPLIT_PERCENTAGE_R,1)
			else 0
        end N_YTD_NBOC_POLICY_LIVES_R,

        case
			WHEN  NVL(main.N_YTD_PRIOR_PREMIUM_R,0) &lt;&gt; 0  and NVL(main.N_YTD_CURR_PREMIUM_R,0) &lt;&gt; 0 
			THEN NVL(main.N_YTD_CHG_PREMIUM_R,0)    *   nvl(main.N_RPT_SPLIT_PERCENTAGE_R,1)
			else 0
        end N_YTD_NBOC_PREMIUM_R,

        case 
			when NVL(main.N_YTD_PRIOR_POLICY_COUNT_R,0) = 0 
			then NVL(main.N_YTD_CURR_POLICY_COUNT_R,0) *NVL(main.N_RPT_SPLIT_PERCENTAGE_R,1) 
			else 0 
		end  N_YTD_NEW_POLICY_COUNT_R,

        case 
			when NVL(main.N_YTD_PRIOR_POLICY_LIVES_R,0) = 0 
			then NVL(main.N_YTD_CURR_POLICY_LIVES_R,0) *NVL(main.N_RPT_SPLIT_PERCENTAGE_R,1) 
			else 0 
		end N_YTD_NEW_POLICY_LIVES_R,

        case 
			when NVL(main.N_YTD_PRIOR_PREMIUM_R,0) = 0 
			then NVL(main.N_YTD_CURR_PREMIUM_R,0) *NVL(main.N_RPT_SPLIT_PERCENTAGE_R,1) 
			else 0 
		end N_YTD_NEW_PREMIUM_R,

       main.N_YTD_PRIOR_PREMIUM_R 		*NVL(main.N_RPT_SPLIT_PERCENTAGE_R,1)  as N_YTD_PRIOR_PREMIUM_R,
       main.N_YTD_PRIOR_POLICY_COUNT_R 	*NVL(main.N_RPT_SPLIT_PERCENTAGE_R,1)  as N_YTD_PRIOR_POLICY_COUNT_R,
       main.N_YTD_PRIOR_LIVES_R 		*NVL(main.N_RPT_SPLIT_PERCENTAGE_R,1)  as N_YTD_PRIOR_LIVES_R,

        case 
			when NVL(main.N_MTD_PRIOR_PREMIUM_R,0) = 0 THEN &apos;New&apos;
			WHEN NVL(main.N_MTD_PRIOR_PREMIUM_R,0) &lt;&gt; 0  and NVL(main.N_MTD_CURR_PREMIUM_R,0) &lt;&gt; 0 THEN &apos;Existing&apos;
			WHEN NVL(main.N_MTD_PRIOR_PREMIUM_R,0) &lt;&gt; 0  and NVL(main.N_MTD_CURR_PREMIUM_R,0) = 0 THEN &apos;Lapse&apos;
        end V_MTD_EXPERIENCE_RECORD_TYPE_R,

        main.N_RPT_PRIMARY_INDICATOR_R AS N_RPT_PRIMARY_INDICATOR_R,

        case when NVL(main.N_QTD_PRIOR_PREMIUM_R,0) = 0 THEN &apos;New&apos;
        WHEN  NVL(main.N_QTD_PRIOR_PREMIUM_R,0) &lt;&gt; 0  and NVL(main.N_QTD_CURR_PREMIUM_R,0) &lt;&gt; 0 THEN &apos;Existing&apos;
        WHEN NVL(main.N_QTD_PRIOR_PREMIUM_R,0) &lt;&gt; 0  and NVL(main.N_QTD_CURR_PREMIUM_R,0) = 0 THEN &apos;Lapse&apos;
        end V_QTD_EXPERIENCE_RECORD_TYPE_R,

        nvl(main.n_policy_billgroup_sk_r,-1) as N_BILLGROUP_SK_R,
        main.V_CUSTOMER_BILL_GROUP_R as V_CUSTOMER_BILL_GROUP_R,
        main.N_POLICY_SK_R,
        main.V_POLICY_NUMBER_R as V_POLICY_NUMBER_R,
        nvl(main.n_product_sk_r, -1) n_product_sk_r ,
       main.V_COVERAGE_CODE_R as V_COVERAGE_CODE_R,
       main.V_PLAN_TYPE_R as V_PLAN_TYPE_R,
       main.V_CLASS_ID_R as V_CLASS_ID_R,
       main.D_DUE_DATE_R as D_DUE_DATE_R,
       main.V_PREMIUM_MODE_R as V_PREMIUM_MODE_R,
       main.N_COVERAGE_LIVES_R 		* NVL(main.N_RPT_SPLIT_PERCENTAGE_R,1) as n_coverage_lives_r

     ,gc_getcur_loadedby as V_LAST_MODIFIED_BY_R
     ,gd_sysdate T_CREATION_DATE_R
     ,gc_getcur_loadedby V_CREATED_BY_R
     ,gd_sysdate T_LAST_MODIFIED_DATE_R
     ,&apos;Y&apos; V_RPT_ACTIVE_STATUS_R
     ,to_number(TO_CHAR(gd_sysdate,&apos;YYYYMMDD&apos;)) as N_BATCH_ID_R
     --,to_number(TO_CHAR(D_CYCLE_DATE_R,&apos;YYYYMM&apos;))                       N_REPORTMONTH_R --26-Feb-2024 changes
     ,gn_current_month	as  N_REPORTMONTH_R --26-Feb-2024 changes
	 --24-Jul-2024 changes starts
	 --,N_AGENT_SK_R,

	 ,NVL(main.N_AGENT_SK_R,-1) N_AGENT_SK_R,
	 --24-Jul-2024 changes ends
	 --12-APR-24 Changes start
	 main.N_CUST_PARTY_SK_R,
     main.V_COVERAGE_R,
	 main.V_IEB_TYPE_R,
	 main.V_YTD_RENEWAL_TYPE_R,
	 main.V_VOLUNTARY_IND_R,
	 main.V_RSO_CODE_R,
	 main.V_CLIENT_NAME_R,
	 main.V_master_customer_name_R,
     main.T_POLICY_EFFECTIVE_DATE_R,
	 main.D_policy_termination_date_r,
	 main.V_agent_Name_r,
	 main.N_SALES_REPRESENTATIVE_SK_R,
	 main.V_SALES_REP_NAME_R,
          --19-06-24 Changes start
     main.N_YTD_PRIOR_POLICY_LIVES_R	* NVL(main.N_RPT_SPLIT_PERCENTAGE_R,1) as N_YTD_PRIOR_POLICY_LIVES_R,
     main.N_QTD_PRIOR_POLICY_LIVES_R	* NVL(main.N_RPT_SPLIT_PERCENTAGE_R,1) as N_QTD_PRIOR_POLICY_LIVES_R,
     main.N_MTD_PRIOR_POLICY_LIVES_R	* NVL(main.N_RPT_SPLIT_PERCENTAGE_R,1) as N_MTD_PRIOR_POLICY_LIVES_R,

/*
     CAST(NULL AS Number)        as N_YTD_LAPSE_POLICY_COUNT_BYPOL_R,
     CAST(NULL AS Number)        as N_YTD_LAPSE_PREMIUM_BYPOL_R    ,
     CAST(NULL AS Number)        as N_YTD_NEW_POLICY_COUNT_BYPOL_R  ,
     CAST(NULL AS Number)        as N_YTD_NEW_PREMIUM_BYPOL_R   ,
*/	 
	 --Start: Perf Improvement Changes

	CASE
        WHEN SUM(NVL(main.N_YTD_PRIOR_POLICY_COUNT_R, 0)) OVER (PARTITION BY main.v_policy_number_R, main.d_cycle_date_r) &lt;&gt; 0 
             AND SUM(NVL(main.N_YTD_CURR_POLICY_COUNT_R, 0)) OVER (PARTITION BY main.v_policy_number_R, main.d_cycle_date_r) = 0 
        THEN SUM(NVL(main.N_YTD_PRIOR_POLICY_COUNT_R, 0) * NVL(main.N_RPT_SPLIT_PERCENTAGE_R, 1)) OVER (PARTITION BY main.v_policy_number_R, main.d_cycle_date_r)
        ELSE 0
    END AS N_YTD_LAPSE_POLICY_COUNT_BYPOL_R,

    CASE
        WHEN SUM(NVL(main.N_YTD_PRIOR_PREMIUM_R, 0)) OVER (PARTITION BY main.v_policy_number_R, main.d_cycle_date_r) &lt;&gt; 0
             AND SUM(NVL(main.N_YTD_CURR_PREMIUM_R, 0)) OVER (PARTITION BY main.v_policy_number_R, main.d_cycle_date_r) = 0
        THEN SUM(NVL(main.N_YTD_PRIOR_PREMIUM_R, 0) * NVL(main.N_RPT_SPLIT_PERCENTAGE_R, 1)) OVER (PARTITION BY main.v_policy_number_R, main.d_cycle_date_r)
        ELSE 0
    END AS N_YTD_LAPSE_PREMIUM_BYPOL_R,

    CASE
        WHEN SUM(NVL(main.N_YTD_PRIOR_POLICY_COUNT_R, 0)) OVER (PARTITION BY main.v_policy_number_R, main.d_cycle_date_r) = 0
        THEN SUM(NVL(main.N_YTD_CURR_POLICY_COUNT_R, 0) * NVL(main.N_RPT_SPLIT_PERCENTAGE_R, 1)) OVER (PARTITION BY main.v_policy_number_R, main.d_cycle_date_r)
        ELSE 0
    END AS N_YTD_NEW_POLICY_COUNT_BYPOL_R,

    CASE
        WHEN SUM(NVL(main.N_YTD_PRIOR_PREMIUM_R, 0)) OVER (PARTITION BY main.v_policy_number_R, main.d_cycle_date_r) = 0
        THEN SUM(NVL(main.N_YTD_CURR_PREMIUM_R, 0) * NVL(N_RPT_SPLIT_PERCENTAGE_R, 1)) OVER (PARTITION BY main.v_policy_number_R, main.d_cycle_date_r)
        ELSE 0
    END AS N_YTD_NEW_PREMIUM_BYPOL_R,

	--End: Perf Improvement Changes	

     CAST(NULL AS VARCHAR2(300)) 		AS V_SALES_YTD_EXPERIENCE_RECORD_TYPE_R,
     CAST(NULL AS VARCHAR2(300)) 		AS V_SALES_QTD_EXPERIENCE_RECORD_TYPE_R,
     CAST(NULL AS VARCHAR2(300)) 		AS V_SALES_MTD_EXPERIENCE_RECORD_TYPE_R,
     main.V_PRIMARY_REINSURER_R       	AS V_PRIMARY_REINSURER_R,
     main.V_SECONDARY_REINSURER_R     	AS V_SECONDARY_REINSURER_R,
     main.V_TERNARY_REINSURER_R       	AS V_TERNARY_REINSURER_R,
     CAST(NULL AS Number)        		AS N_PRIMARY_REINSURER_REINS_SHARE_PCT_R,
     CAST(NULL AS Number)        		AS N_SECONDARY_REINSURER_REINS_SHARE_PCT_R,
     CAST(NULL AS Number)        		AS N_TERNARY_REINSURER_REINS_SHARE_PCT_R,
     CAST(NULL AS Number)        		AS N_PRIMARY_REINSURER_REINSURANCE_PCT_R,
     CAST(NULL AS Number)        		AS N_SECONDARY_REINSURER_REINSURANCE_PCT_R,
     CAST(NULL AS Number)        		AS N_TERNARY_REINSURER_REINSURANCE_PCT_R,
     CAST(NULL AS Number)        		AS N_TOTAL_REINSURANCE_PCT_R,
     --19-06-24 Changes END
     --10/07/24 Change start
     main.N_TOTAL_REINSURANCE_PREM_PCT_R,
     main.N_MTD_CURR_PREMIUM_R,
     main.N_MTD_CHG_VOLUME_R
     --10/07/24 Change start
	 --17-Jul-2024 changes starts
    /*,CASE
        WHEN SUM(NVL(main.N_MTD_PRIOR_PREMIUM_R, 0)) OVER (PARTITION BY main.v_policy_number_R, main.d_cycle_date_r) &lt;&gt; 0
             AND SUM(NVL(main.N_MTD_CURR_PREMIUM_R, 0)) OVER (PARTITION BY main.v_policy_number_R, main.d_cycle_date_r) &lt;&gt; 0
        THEN &apos;Existing&apos;
        WHEN SUM(NVL(main.N_MTD_PRIOR_PREMIUM_R, 0)) OVER (PARTITION BY main.v_policy_number_R, main.d_cycle_date_r) &lt;&gt; 0
             AND SUM(NVL(main.N_MTD_CURR_PREMIUM_R, 0)) OVER (PARTITION BY main.v_policy_number_R, main.d_cycle_date_r) = 0
        THEN &apos;Lapse&apos;
        WHEN SUM(NVL(main.N_MTD_PRIOR_PREMIUM_R, 0)) OVER (PARTITION BY main.v_policy_number_R, main.d_cycle_date_r) = 0
             AND SUM(NVL(main.N_MTD_CURR_PREMIUM_R, 0)) OVER (PARTITION BY main.v_policy_number_R, main.d_cycle_date_r) &lt;&gt; 0
        THEN &apos;New&apos;
        ELSE NULL
    END AS V_POLICY_RECORD_EXPERIENCE_TYPE_R
	 --17-Jul-2024 changes ends*/
	 --16-05-2025 Changes Starts
	 ,CASE
        WHEN SUM(NVL(main.N_YTD_PRIOR_PREMIUM_R, 0)) OVER (PARTITION BY main.v_policy_number_R, main.d_cycle_date_r) &lt;&gt; 0
             AND SUM(NVL(main.n_annualized_premium_r, 0)) OVER (PARTITION BY main.v_policy_number_R, main.d_cycle_date_r) &lt;&gt; 0
        THEN &apos;Existing&apos;
        WHEN SUM(NVL(main.N_YTD_PRIOR_PREMIUM_R, 0)) OVER (PARTITION BY main.v_policy_number_R, main.d_cycle_date_r) &lt;&gt; 0
             AND SUM(NVL(main.n_annualized_premium_r, 0)) OVER (PARTITION BY main.v_policy_number_R, main.d_cycle_date_r) = 0
        THEN &apos;Lapse&apos;
        WHEN SUM(NVL(main.N_YTD_PRIOR_PREMIUM_R, 0)) OVER (PARTITION BY main.v_policy_number_R, main.d_cycle_date_r) = 0
             AND SUM(NVL(main.n_annualized_premium_r, 0)) OVER (PARTITION BY main.v_policy_number_R, main.d_cycle_date_r) &lt;&gt; 0
        THEN &apos;New&apos;
        ELSE &apos;Lapse&apos;
    END AS V_POLICY_RECORD_EXPERIENCE_TYPE_R
	 --16-05-2025 Changes Ends


	 --17/09/2024 changes starts

	 --,cast(null as varchar2(300)) V_RPT_CURRENT_RATE_R
	 -- Start: Perf Improvement Changes 
	 ,cur_upd_rate.v_rpt_current_rate_r
	 -- End: Perf Improvement Changes

	 --17/09/2024 changes ends

	 ,main.N_VOLUME_R --02/10/24 CHANGES
	 --13/11/24 Changes Start
	 --,CAST(NULL AS VARCHAR2(3000 CHAR)) V_PRIOR_CARRIER_NAME_R
	 --,CAST(NULL AS VARCHAR2(3000 CHAR)) V_PRIOR_CARRIER_NAME_OVERRIDE_R

	 --Start: Perf Improvement Changes
	,cur_upd_prior_names.V_prior_carrier_name_r
    ,cur_upd_prior_names.V_PRIOR_CARRIER_NAME_OVERRIDE_R
	--End: Perf Improvement Changes


	 --13/11/24 Changes End
     --14/11/24 Changes Start
	 /*
     ,CAST(NULL AS VARCHAR2(3000 CHAR)) V_POLICY_PREFIX_R    
     ,CAST(NULL AS VARCHAR2(3000 CHAR)) V_POLICY_SUFFIX_R    
     ,CAST(NULL AS VARCHAR2(3000 CHAR)) V_EXCHANGE_NAME_R    
     ,CAST(NULL AS VARCHAR2(3000 CHAR)) V_RATEBOOK_DESC_R    
     ,CAST(NULL AS VARCHAR2(3000 CHAR)) V_SIC_CATEGORY_R     
     ,CAST(NULL AS VARCHAR2(3000 CHAR)) V_RSO_NAME_R         
     ,CAST(NULL AS VARCHAR2(3000 CHAR)) V_POLICY_CASE_SIZE_R 
	 */
     --14/11/24 Changes Ends

	 -- Start : Perf Tuning

    ,cur_upd_pol_pre.V_POLICY_PREFIX_R   
    ,cur_upd_pol_pre.V_POLICY_SUFFIX_R   
    ,cur_upd_pol_pre.V_EXCHANGE_NAME_R   
    ,cur_upd_pol_pre.V_RATEBOOK_DESC_R   
    ,cur_upd_pol_pre.V_SIC_CATEGORY_R    
    ,cur_upd_pol_pre.V_RSO_NAME_R        
    ,cur_upd_pol_pre.V_POLICY_CASE_SIZE_R

	 -- End : Perf Tuning

     --22/11/24 Changes Start
     ,main.V_COVERAGE_DESC_R
	 ,main.V_COVERAGE_DESC_SORT_R
        ,main.V_SOURCE_SYSTEM_NAME_R
     --22/11/24 Changes ends
	 FROM ATOMIC.RPT_FCT_RPT_ANN_PREM_SUMMARY_R_MV_SSL_INC main
		LEFT JOIN
			(
				SELECT 
					a.N_POLICY_sK_R,
					MAX(V_COMPETITOR_NAME_R) AS V_prior_carrier_name_r,
					MAX(V_RPT_NAME_R) AS V_PRIOR_CARRIER_NAME_OVERRIDE_R,
					MAX(V_RPT_PRIOR_CARRIER_R) AS V_RPT_PRIOR_CARRIER_R
				FROM ATOMIC.Dim_Grp_Priorcarrier_Details_R a
				INNER JOIN ATOMIC.dim_grp_policy_dir_r b
					ON a.n_policy_sk_r = b.n_policy_sk_r
					AND a.n_version_number_r = b.n_policy_version_number_r
				LEFT JOIN ATOMIC.STG_CARRIER_CLEANUP_R c
					ON c.V_CARRIER_NAME_R = a.v_competitor_name_r
				-- The exists clause ensures only matching records in ANN PREM SUMMARY are included
				WHERE a.n_policy_sk_r &lt;&gt; -1
				  AND a.V_ACTIVE_STATUS_R = &apos;Y&apos;
				  AND b.v_active_status_r = &apos;Y&apos;
				GROUP BY a.N_POLICY_sK_R
			) cur_upd_prior_names 
			ON cur_upd_prior_names.n_policy_sk_r = main.n_policy_sk_r

		LEFT JOIN
		(
				SELECT 
					 rr.V_POLICY_PREFIX_R
					,rr.V_POLICY_SUFFIX_R
					,rr.V_EXCHANGE_NAME_R
					,rr.V_RATEBOOK_DESC_R
					,pp.V_SIC_CATEGORY_R
					,pp.V_RSO_NAME_R
					,rr.V_POLICY_CASE_SIZE_R
					,rr.n_cust_party_sk_r
					,rr.n_policy_sk_r
				FROM ATOMIC.RPT_POLICY_DTL_R rr
				LEFT JOIN ATOMIC.RPT_CLIENT_DTL_R pp 
					ON rr.n_cust_party_sk_r = pp.n_cust_party_sk_r
					AND rr.n_yearmonth_r = pp.n_yearmonth_r
				WHERE rr.n_cust_party_sk_r &lt;&gt; -1 
					  AND pp.n_cust_party_sk_r &lt;&gt; -1
					  AND rr.V_RPT_ACTIVE_STATUS_R = &apos;Y&apos;
					  AND pp.V_RPT_ACTIVE_STATUS_R = &apos;Y&apos;
					  AND rr.N_YEARMONTH_R = gn_current_month
				GROUP BY 
					 rr.V_POLICY_PREFIX_R
					,rr.V_POLICY_SUFFIX_R
					,rr.V_EXCHANGE_NAME_R
					,rr.V_RATEBOOK_DESC_R
					,pp.V_SIC_CATEGORY_R
					,pp.V_RSO_NAME_R
					,rr.V_POLICY_CASE_SIZE_R
					,rr.n_cust_party_sk_r
					,rr.n_policy_sk_r

		) cur_upd_pol_pre 
		ON  cur_upd_pol_pre.n_cust_party_sk_r    = main.n_cust_party_sk_r
		AND cur_upd_pol_pre.n_policy_sk_r        = main.n_policy_sk_r

		LEFT JOIN
		(
			SELECT 
				 rr.v_rpt_current_rate_r
				,rr.n_billgroup_sk_r
				,rr.n_policy_sk_r
				,rr.n_product_sk_r
				,rr.n_reportmonth_r
			  FROM ATOMIC.rpt_rate_r rr
			 WHERE rr.n_reportmonth_r=gn_current_month
			GROUP BY 
				 rr.v_rpt_current_rate_r
				,rr.n_billgroup_sk_r
				,rr.n_policy_sk_r
				,rr.n_product_sk_r
				,rr.n_reportmonth_r
		) cur_upd_rate ON 
				 main.n_policy_billgroup_sk_r       = cur_upd_rate.n_billgroup_sk_r
			 AND main.n_policy_sk_r                 = cur_upd_rate.n_policy_sk_r
			 AND main.n_product_sk_r                = cur_upd_rate.n_product_sk_r
			 AND main.n_reportmonth_r               = cur_upd_rate.n_reportmonth_r
     WHERE 
				main.n_reportmonth_r = gn_current_month
		--fetch first 98 rows only
		;

--Perf Improvments : End : Adding New consolidated query which includes exsisting logic and all updates done using cursors.
	gn_run_cnt      := SQL%ROWCOUNT;
	COMMIT;


-- Start : Kill/Fill Changes 12th May 2026: Commented following 

	EXECUTE IMMEDIATE &apos;ALTER SESSION DISABLE PARALLEL DML&apos;;
	-- End : Kill/Fill Changes 12th May 2026 

	--EXECUTE IMMEDIATE &apos;insert into atomic.RPT_FCT_RPT_ANN_PREM_SUMMARY_R_EXG select * from atomic.RPT_FCT_RPT_ANN_PREM_SUMMARY_R_EXG_NEW&apos;;

	gt_end_time := SYSTIMESTAMP;
	gc_trcmsg:=&apos;6.3 Data Load Completed for _EXG Table&apos;;

		/*START: 22-MAY-2025: NEW LOGGING MECHANISM CHANGES*/
			 PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
			 (
				p_job_id_r                    =&gt; gn_out_job_id,
				p_batch_id_r                  =&gt; gn_sysdt_batchid,
				p_message_type_r              =&gt; gc_message_type,
				p_code_location_r             =&gt; gc_main_loadedby,
				p_message_r                   =&gt; gc_trcmsg,
				p_count_type_r                =&gt; Null,
				p_count_r                     =&gt; gn_run_cnt,
				p_duration_r                  =&gt; FNC_GRP_TIME_DURATION(gt_start_time,gt_end_time),
				p_created_by_r                =&gt; GC_JOB_NAME,
				out_prcs_job_log_message_id_r =&gt; gn_job_log_message_id
			);	
EXCEPTION
WHEN OTHERS THEN
    gc_errmsg :=SUBSTR(SQLERRM,1,4000);
    gc_trcmsg:=gc_trcmsg||&apos;4.z Error in prc_get_cur_data&apos;||chr(13);
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

--Procedure to rebuild indexes RPT_FCT_RPT_ANN_PREM_SUMMARY_R
PROCEDURE prc_rebuild_indexes
IS
LC_REBUILD_INDEX  VARCHAR2(300);
BEGIN
   gc_trcmsg:=gc_trcmsg||&apos;7.a Entered into prc_rebuild_indexes&apos;||chr(13);
  FOR I IN ( select
    &apos;ALTER INDEX &apos;||INDEX_NAME||&apos; REBUILD  parallel 16 nologging&apos; REBUILD_INDEX
    from ALL_INDEXES  where TABLE_NAME =&apos;RPT_FCT_RPT_ANN_PREM_SUMMARY_R&apos;
	AND INDEX_NAME NOT LIKE &apos;PK_%&apos;
	AND INDEX_NAME NOT LIKE &apos;FK_%&apos;
	AND STATUS=&apos;UNUSABLE&apos;
	)
  LOOP
    LC_REBUILD_INDEX:=I.REBUILD_INDEX;
    EXECUTE IMMEDIATE LC_REBUILD_INDEX;
  END LOOP;
   gc_trcmsg:=gc_trcmsg||&apos;7.z Exit from prc_rebuild_indexes&apos;||chr(13);
EXCEPTION
WHEN OTHERS THEN
    gc_errmsg :=SUBSTR(SQLERRM,1,4000);
    gc_trcmsg:=gc_trcmsg||&apos;7.z Error in prc_rebuild_indexes&apos;||chr(13);
    pkg_grp_log_util.prc_update_log
          (
            gn_out_job_id                   --p_job_id
            ,gc_error_status                --p_job_status
            ,gc_errmsg                      --p_err_msg
            ,gc_trcmsg||chr(13)||gc_errmsg  --p_trc_msg
            ,gc_rebuildindexes             --p_log_util_called_by_r
          );
    RAISE;
END prc_rebuild_indexes;
END PKG_GRP_LOAD_RPT_FCT_RPT_ANN_PREM_SUMMARY_R_INC;"