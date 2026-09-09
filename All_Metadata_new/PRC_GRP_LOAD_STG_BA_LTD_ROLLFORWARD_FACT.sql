"PROCEDURE PRC_GRP_LOAD_STG_BA_LTD_ROLLFORWARD_FACT (
    P_BATCH_ID_R IN NUMBER
) AS
    V_SYS_DATE          VARCHAR2(15) := TO_CHAR(SYSDATE, &apos;YYYYMMDDHHMISS&apos;);
    N_MAX_SERIAL_NUM_R  NUMBER;
    V_SQLCODE           VARCHAR2(100);
    V_SQLERRM           VARCHAR2(500);
    CURR_CYCLE_DATE       DATE;
	LD_MIS_DATE_OG_PREV_R  DATE;
    LN_REP_MON_R        VARCHAR2(8);
    LC_BKP_TBL_STR      VARCHAR2(10) := TO_CHAR(SYSDATE, &apos;MMDDSS&apos;);
    LC_SQLCODE          VARCHAR2(300);
    LC_SQLERRM          VARCHAR2(4000);
    LD_SYSDATE          DATE;
    LC_TRCMSG           VARCHAR2(4000) := &apos;TRACE MESSAGE:-&gt;&apos;;
    LN_START_TIME       NUMBER;
    LN_N_BATCH_ID_R     NUMBER := TO_NUMBER(TO_CHAR(SYSDATE, &apos;YYYYMMDD&apos;)
                                        || &apos;0000&apos;);
    LT_SYSTIMESTAMP     TIMESTAMP := SYSDATE;
    --LN_BATCH_ID_R       NUMBER := TO_NUMBER(TO_CHAR(P_BATCH_ID_R,&apos;YYYYMMDD&apos;));
    LN_BATCH_ID_R       NUMBER := P_BATCH_ID_R;
    --LN_BATCH_ID_R_1      NUMBER := P_BATCH_ID_R;
--	LD_BE_CYCLE_DATE    DATE;
	LC_DAY          VARCHAR2(30);
  ld_fic_mis_date DATE;



BEGIN


  SELECT TRUNC(D_START_DATE_R)+1 INTO ld_sysdate 
  FROM ATOMIC.PRCS_GRP_MONTH_END_CONFIG_R
  WHERE V_TABLE_NAME_R = &apos;RPT_BATCH_ID&apos;;


lc_trcmsg:=lc_trcmsg||chr(13)||&apos;Get Day&apos;;
  SELECT  TO_CHAR(LD_SYSDATE,&apos;DAY&apos;) --TO_CHAR(TO_DATE(&apos;01-MAR-25&apos;, &apos;DD-MON-RR&apos;), &apos;DAY&apos;) as LC_DAY 
     INTO LC_DAY
     FROM DUAL;
lc_trcmsg:=lc_trcmsg||chr(13)||&apos;Day is:-&gt;&apos;||LC_DAY;

  lc_trcmsg:=lc_trcmsg||chr(13)||&apos;Get Fiscal Month End Date +1 &apos;;
     SELECT D_CALENDAR_DATE_R +1 INTO ld_fic_mis_date
     FROM DIM_TIME_R D
     WHERE  V_END_OF_FISCAL_MONTH_IND_R = &apos;Y&apos;
     and to_char(d_calendar_date_r,&apos;YYYYMM&apos;)=to_char(LD_SYSDATE,&apos;YYYYMM&apos;);
  LC_TRCMSG:=LC_TRCMSG||CHR(13)||&apos;Fiscal Month End Date +1 is :-&gt;&apos;||LD_FIC_MIS_DATE;

   lc_trcmsg:=lc_trcmsg||chr(13)||&apos;Get Fiscal Month End Date +1 &apos;;
     SELECT D_CALENDAR_DATE_R +1 INTO ld_fic_mis_date
     FROM DIM_TIME_R D
     WHERE  V_END_OF_FISCAL_MONTH_IND_R = &apos;Y&apos;
     AND TO_CHAR(D_CALENDAR_DATE_R,&apos;YYYYMM&apos;)=TO_CHAR(LD_SYSDATE,&apos;YYYYMM&apos;);
  LC_TRCMSG:=LC_TRCMSG||CHR(13)||&apos;Fiscal Month End Date +1 is :-&gt;&apos;||LD_FIC_MIS_DATE;

  SELECT D_CALENDAR_DATE_R    INTO CURR_CYCLE_DATE/*,TO_CHAR(D_CALENDAR_DATE_R, &apos;YYYYMM&apos;) INTO LN_REP_MON_R*/
   FROM DIM_TIME_R
   WHERE --N_MONTH_R=8 AND N_YEAR_R=2024 AND
         V_END_OF_FISCAL_MONTH_IND_R=&apos;Y&apos;
        AND EXTRACT(MONTH FROM D_CALENDAR_DATE_R) = EXTRACT(MONTH FROM TO_DATE(LD_SYSDATE, &apos;DD-MON-YYYY&apos;))
        AND EXTRACT(YEAR FROM D_CALENDAR_DATE_R) = EXTRACT(YEAR FROM TO_DATE(LD_SYSDATE, &apos;DD-MON-YYYY&apos;));---FOR ACTUAL RUN

LC_TRCMSG:= LC_TRCMSG||&apos;Getting the Current Cycle date from DIM_TIME_R&apos;||CHR(13);


	SELECT TO_CHAR(D_CALENDAR_DATE_R, &apos;YYYYMM&apos;) INTO LN_REP_MON_R
	FROM DIM_TIME_R
	WHERE
			--N_MONTH_R=10 AND N_YEAR_R=2024 AND
         --V_END_OF_FISCAL_MONTH_IND_R=&apos;Y&apos;
			--TO_CHAR(D_CALENDAR_DATE_R,&apos;YYYYMM&apos;)=TO_CHAR(LN_BATCH_ID_R,&apos;YYYYMM&apos;);---- FOR TESTING
			--D_CALENDAR_DATE_R = TO_DATE(LN_BATCH_ID_R,&apos;YYYYMMDD&apos;)
	V_END_OF_FISCAL_MONTH_IND_R = &apos;Y&apos; AND
			EXTRACT(MONTH FROM D_CALENDAR_DATE_R) = EXTRACT(MONTH FROM TO_DATE(LD_SYSDATE, &apos;DD-MON-YYYY&apos;))
			AND EXTRACT(YEAR FROM D_CALENDAR_DATE_R) = EXTRACT(YEAR FROM TO_DATE(LD_SYSDATE, &apos;DD-MON-YYYY&apos;));---FOR ACTUAL RUN

LC_TRCMSG:= LC_TRCMSG||&apos;Yearmonth LN_REP_MON_R --&gt;  &apos;|| LN_REP_MON_R ||CHR(13);
LC_TRCMSG:= LC_TRCMSG||&apos;Getting the Previous Cycle date from DIM_TIME_R &apos;||CHR(13);

 /*    SELECT  D_CALENDAR_DATE_R INTO LD_MIS_DATE_OG_PREV_R 
	 FROM
		( SELECT D_CALENDAR_DATE_R,RANK() OVER ( ORDER BY D_CALENDAR_DATE_R DESC) DATE_RANK
		  FROM		ATOMIC.DIM_TIME_R
		  WHERE		V_END_OF_FISCAL_MONTH_IND_R = &apos;Y&apos; AND D_CALENDAR_DATE_R &lt; LD_MIS_DATE_R
		) WHERE DATE_RANK =1; */

--LC_TRCMSG:= LC_TRCMSG||&apos;Previous Cycle date LD_MIS_DATE_OG_PREV_R --&gt;  &apos;|| LD_MIS_DATE_OG_PREV_R ||CHR(13);
/*LC_TRCMSG:= LC_TRCMSG||&apos;Getting the max Cycle date from STG_BEST_ESTIMATE_RESERVES_R&apos;||CHR(13);
--		SELECT MAX(TO_DATE(D_VALUATION_DATE_R,&apos;MM-DD-YY&apos;)) INTO LD_BE_CYCLE_DATE
--		FROM STG_BEST_ESTIMATE_RESERVES_R_OCTOBER;

--LC_TRCMSG:= LC_TRCMSG||&apos;Max Cycle date LD_BE_CYCLE_DATE --&gt;  &apos;|| LD_BE_CYCLE_DATE ||CHR(13);*/

IF TO_DATE(ld_fic_mis_date) = TO_DATE(ld_sysdate)  --to load data on next day of Fiscal Month (Ex:the fiscal month end for May 2023 is 26-MAY-23 so we should load this on 27-MAY-23)
   OR TRIM(LC_DAY)=&apos;SATURDAY&apos;-- or to load data on Saturday
   THEN		

  LN_START_TIME := DBMS_UTILITY.GET_TIME;
  LC_TRCMSG := LC_TRCMSG
                 || CHR(13)
                 || &apos;1. INSERT INTO THE TABLE STG_BA_LTD_ROLLFORWARD_FACT:-&gt;&apos;
                 || LN_START_TIME
                 || &apos; SECONDS&apos;;


	LC_TRCMSG := LC_TRCMSG||&apos;Deleting the data from STG_BA_LTD_ROLLFORWARD_FACT for REPORT_MONTH = (:LN_REP_MON_R)&apos;||CHR(13);			
    delete from stg_ba_ltd_rollforward_fact where D_CURRENT_VALUATION_DATE_R = CURR_CYCLE_DATE;
    commit;
	LC_TRCMSG := LC_TRCMSG||&apos;Deleted the data for STG_BA_LTD_ROLLFORWARD_FACT&apos;||CHR(13);	
	LC_TRCMSG := LC_TRCMSG||&apos;Starting the load for Current Cycle Date to STG_BA_LTD_ROLLFORWARD_FACT &apos;||CHR(13);	

insert into stg_ba_ltd_rollforward_fact(
V_CURRENT_CLAIM_IDENTIFIER_R,
V_PRIOR_CLAIM_IDENTIFIER_R,
D_CURRENT_VALUATION_DATE_R,
D_PRIOR_VALUATION_DATE_R,
N_REPORTMONTH_R,
V_LIST_STATUS_R,
V_CLAIM_STATUS_CHANGE_R,
V_CLAIM_ACTIVITY_IND_R,
V_CLAIM_DETAIL_STATUS_R,
V_CLAIM_IDENTIFIER_R,
V_CURRENT_CLAIM_STATUS_CODE_R,
V_PRIOR_CLAIM_STATUS_CODE_R,
V_CURRENT_PRIOR_STATUS_CODE_R,
V_PRIOR_PRIOR_STATUS_CODE_R,
V_CURRENT_PRIOR_OPEN_STATUS_CODE_R,
V_PRIOR_PRIOR_OPEN_STATUS_CODE_R,
V_CURRENT_PRIOR_CLOSED_STATUS_R,
V_PRIOR_PRIOR_CLOSED_STATUS_R,
V_FIRST_OPEN_STATUS_CODE_R,
D_FIRST_OPEN_STATUS_EFF_DATE_R,
V_FIRST_CLOSED_STATUS_CODE_R,
D_FIRST_CLOSED_STATUS_EFF_DATE_R,
V_INSURED_LAST_NAME_R,
V_EXAMINER_NAME_R,
V_POLICY_NUMBER_R,
V_ADMINISTERED_BY_R,
N_STARTING_CLAIM_COUNT_R,
N_CHG_CLAIM_COUNT_R,
N_ENDING_CLAIM_COUNT_R,
N_STARTING_GP_RESERVE_DIRECT_AMT_R,
N_CHG_GAAP_RESERVE_DIRECT_AMT_R,
N_ENDING_GAAP_RESERVE_DIRECT_AMT_R,
N_STARTING_GAAP_RESERVE_NET_AMT_R,
N_CHG_GAAP_RESERVE_NET_AMT_R,
N_ENDING_GAAP_RESERVE_NET_AMT_R,
N_STARTING_ST_RESERVE_DIRECT_AMT_R,
N_CHG_STAT_RESERVE_DIRECT_AMT_R,
N_ENDING_STAT_RESERVE_DIRECT_AMT_R,
N_STARTING_STAT_RESERVE_NET_AMT_R,
N_CHG_STAT_RESERVE_NET_AMT_R,
N_ENDING_STAT_RESERVE_NET_AMT_R,
N_STARTING_NET_BENEFIT_AMT_R,
N_ENDING_NET_BENEFIT_AMT_R,
N_STARTING_DURATION_IN_MONTHS_R,
N_ENDING_DURATION_IN_MONTHS_R,
D_RECEIVED_DATE_R,
D_CLOSED_DATE_R,
D_DECISION_MADE_DATE_R,
D_DECISION_MADE_DATE_MONTH_END_R,
N_CLAIM_DECISION_DAYS_R,
N_CLAIM_DECISION_DAYS_MONTH_END_R,
D_PLAN_DURATION_DATE_R,
D_PLAN_DURATION_DATE_MONTH_END_R,
D_ANY_OCC_START_DATE_R,
D_ANY_OCC_START_DATE__MONTH_END_R,
D_CLAIM_DECISION_DATE_R  ,      
D_CLAIM_DECISION_DATE_MONTH_END_R  ,       
D_LOSS_DATE_R,
D_LOSS_DATE_MONTH_END_R,
V_PRI_DIAG_CATEGORY_DESC_R,
V_PRI_DIAG_CATEGORY_DESC_MONTH_END_R,
V_ANY_OCC_GROUP_R,
V_ANY_OCC_GROUP_MONTH_END_R,
V_IEB_INDICATOR_R,
V_IEB_INDICATOR_MONTH_END_R,
V_CLIENT_NAME_R,
V_CLIENT_NAME_MONTH_END_R,
V_DIRECTOR_FULL_NAME_R,
V_DIRECTOR_FULL_NAME_MONTH_END_R,
V_SUPERVISOR_FULL_NAME_R,
V_SUPERVISOR_FULL_NAME_MONTH_END_R,
V_CARRIER_NAME_R,
V_CARRIER_NAME_MONTH_END_R
,N_POLICY_SK_R
,N_CLAIM_SK_R
,D_RECORD_START_DATE_R
,D_RECORD_END_DATE_R
,V_SOURCE_SYSTEM_NAME_R
,T_EVENT_TIMESTAMP_R
,FIC_MIS_DATE_R
,N_BATCH_ID_R
,N_SEQUENCE_NUMBER_R
,T_CREATION_DATE_R
,T_LAST_MODIFIED_DATE_R
,V_CREATED_BY_R
,V_LAST_MODIFIED_BY_R
	)
WITH LD_MIS_DATE_R AS (
    SELECT
        D_CALENDAR_DATE_R AS LD_MIS_DATE_R
    FROM DIM_TIME_R
    WHERE
        V_END_OF_FISCAL_MONTH_IND_R = &apos;Y&apos; 
        AND EXTRACT(MONTH FROM D_CALENDAR_DATE_R) = EXTRACT(MONTH FROM SYSDATE)
        AND EXTRACT(YEAR FROM D_CALENDAR_DATE_R) = EXTRACT(YEAR FROM SYSDATE) 
),
LD_MIS_DATE_OG_PREV_R AS (
    SELECT
        D_CALENDAR_DATE_R AS LD_MIS_DATE_OG_PREV_R
    FROM (
        SELECT
            D_CALENDAR_DATE_R,
            RANK() OVER (ORDER BY D_CALENDAR_DATE_R DESC) AS DATE_RANK
        FROM ATOMIC.DIM_TIME_R
        WHERE
            V_END_OF_FISCAL_MONTH_IND_R = &apos;Y&apos;
            AND D_CALENDAR_DATE_R &lt; (SELECT MAX(LD_MIS_DATE_R) FROM LD_MIS_DATE_R)-- &apos;29-JAN-25&apos;
    )
    WHERE DATE_RANK = 1
)
SELECT CURRENT_DAY.&quot;Claim Identifier&quot; as &quot;Curr Claim Identifier&quot;, 
MONTH_END.&quot;Claim Identifier&quot; AS &quot;Month Claim Identifier&quot;,
NVL(CURRENT_DAY.&quot;Valuation Date&quot; ,(SELECT LDMR.LD_MIS_DATE_R AS &quot;Current Valuation Date&quot; FROM LD_MIS_DATE_R LDMR)) &quot;Current Valuation Date&quot;,
NVL(MONTH_END.&quot;Valuation Date&quot;  ,(SELECT LDMOPR.LD_MIS_DATE_OG_PREV_R AS &quot;Current Valuation Date&quot; FROM LD_MIS_DATE_OG_PREV_R LDMOPR)) &quot;Prior Valuation Date&quot;,
NVL(CURRENT_DAY.&quot;Report Month&quot;, MONTH_END.&quot;Report Month&quot;) &quot;Report Month&quot;,
case when CURRENT_DAY.&quot;Claim Identifier&quot; is null then &apos;3. Closed&apos;
            when MONTH_END.&quot;Claim Identifier&quot; is null and ( CURRENT_DAY.&quot;Prior Status&quot; &gt; &apos;60&apos; or CURRENT_DAY.&quot;Prior Status&quot; = &apos;51&apos; )  then &apos;2. Re-Open&apos;
            when MONTH_END.&quot;Claim Identifier&quot; is null then &apos;1. New (Approved)&apos;
            when ( nvl(CURRENT_DAY.&quot;Reserve Net Benefit&quot;,0)  -  nvl(MONTH_END.&quot;Reserve Net Benefit&quot;,0) ) &gt; 1.0  then &apos;4. Existing - Net Benefit Increase&apos;
            when ( nvl(CURRENT_DAY.&quot;Reserve Net Benefit&quot;,0)  -  nvl(MONTH_END.&quot;Reserve Net Benefit&quot;,0) ) &lt; -1.0  then &apos;4. Existing - Net Benefit Decrease&apos;          
            when nvl(CURRENT_DAY.&quot;Duration&quot;,0)  &lt;  nvl(MONTH_END.&quot;Duration&quot;,0)  then &apos;5. Existing - Duration Decrease&apos;        
            when nvl(CURRENT_DAY.&quot;Duration&quot;,0)  &gt;  nvl(MONTH_END.&quot;Duration&quot;,0)  then &apos;5. Existing - Duration Increase&apos;                                    
            when nvl(CURRENT_DAY.&quot;Primary Diagnosis Code&quot;,&apos;zzz&apos;)  &lt;&gt;  nvl(MONTH_END.&quot;Primary Diagnosis Code&quot;,&apos;zzz&apos;)  then &apos;6. Existing - Other Change&apos;
            when nvl(CURRENT_DAY.&quot;Loss Date&quot;,&apos;01-JAN-1900&apos;)  &lt;&gt;  nvl(MONTH_END.&quot;Loss Date&quot;,&apos;01-JAN-1900&apos;)  then &apos;6. Existing - Other Change&apos;
            when nvl(CURRENT_DAY.&quot;Elimination Period&quot;,0)  &lt;&gt;  nvl(MONTH_END.&quot;Elimination Period&quot;,0)  then &apos;6. Existing - Other Change&apos;
            when nvl(CURRENT_DAY.&quot;Gross Benefit&quot;,0)  &lt;&gt;  nvl(MONTH_END.&quot;Gross Benefit&quot;,0)  then &apos;6. Existing - Other Change&apos;
            when nvl(CURRENT_DAY.&quot;Insured Gender&quot;,&apos;zzz&apos;)  &lt;&gt;  nvl(MONTH_END.&quot;Insured Gender&quot;,&apos;zzz&apos;)  then &apos;6. Existing - Other Change&apos;
            when nvl(CURRENT_DAY.&quot;Insured Birth Date&quot;,&apos;01-JAN-1900&apos;)  &lt;&gt;  nvl(MONTH_END.&quot;Insured Birth Date&quot;,&apos;01-JAN-1900&apos;)  then &apos;6. Existing - Other Change&apos;
            else &apos;7. Existing - No Change&apos;
        end &quot;List Status&quot;,
     case when nvl(CURRENT_DAY.&quot;Claim Status Code&quot;,&apos;ZZZ&apos;) &lt;&gt; nvl(MONTH_END.&quot;Claim Status Code&quot;,&apos;ZZZ&apos;) then &apos;Y&apos; else &apos;N&apos; end  &quot;Claim Status Change&quot;,
     case when MONTH_END.&quot;Claim Identifier&quot; is null then &apos;New&apos;
            when CURRENT_DAY.&quot;Claim Identifier&quot; is null then &apos;Closed&apos;
            when nvl(CURRENT_DAY.&quot;Claim Status Code&quot;,&apos;ZZZ&apos;)  &lt;&gt;  nvl(MONTH_END.&quot;Claim Status Code&quot;,&apos;ZZZ&apos;) then &apos;Existing - Change&apos;
            when nvl(CURRENT_DAY.&quot;Claim Status Code&quot;,&apos;ZZZ&apos;)  =  nvl(MONTH_END.&quot;Claim Status Code&quot;,&apos;ZZZ&apos;) then &apos;Existing - No Change&apos;  
            else &apos;Unknown&apos;
        end &quot;Claim Activity Indicator&quot;,
        case when nvl(CURRENT_DAY.&quot;Claim Status Code&quot;, MONTH_END.&quot;Current Status&quot;) = &apos;51&apos; then &apos;Resisting&apos;
            when nvl(CURRENT_DAY.&quot;Claim Status Code&quot;, MONTH_END.&quot;Current Status&quot;) = &apos;70&apos; then &apos;Settlement&apos;
	    when nvl(CURRENT_DAY.&quot;Claim Status Code&quot;, MONTH_END.&quot;Current Status&quot;) = &apos;72&apos; then &apos;Deceased&apos;
            when nvl(CURRENT_DAY.&quot;Claim Status Code&quot;, MONTH_END.&quot;Current Status&quot;) = &apos;63&apos; then &apos;Any Occ&apos;
            when nvl(CURRENT_DAY.&quot;Claim Status Code&quot;, MONTH_END.&quot;Current Status&quot;) in ( &apos;66&apos;, &apos;67&apos; ) then &apos;No Reply&apos;
            when nvl(CURRENT_DAY.&quot;Claim Status Code&quot;, MONTH_END.&quot;Current Status&quot;) like &apos;3%&apos; and nvl(CURRENT_DAY.&quot;Prior Open Status&quot;, MONTH_END.&quot;Prior Open Status&quot;) is not null then &apos;Reopened&apos;
            when nvl(CURRENT_DAY.&quot;Claim Status Code&quot;, MONTH_END.&quot;Current Status&quot;) in ( &apos;35&apos; ) then &apos;Approved (PAS)&apos;
            when nvl(CURRENT_DAY.&quot;Claim Status Code&quot;, MONTH_END.&quot;Current Status&quot;) like &apos;3%&apos; then &apos;Approved&apos;
            when nvl(CURRENT_DAY.&quot;Claim Status Code&quot;, MONTH_END.&quot;Current Status&quot;) = &apos;46&apos; then &apos;Pending&apos;
            when nvl(CURRENT_DAY.&quot;Claim Status Code&quot;, MONTH_END.&quot;Current Status&quot;) in ( &apos;91&apos;, &apos;92&apos; ) then &apos;Data Entry Error&apos; 
            else &apos;Other&apos;
        end &quot;Claim Detail Status&quot;,
       nvl(CURRENT_DAY.&quot;Claim Identifier&quot;, MONTH_END.&quot;Claim Identifier&quot; ) &quot;Claim Identifier&quot;,
       nvl(CURRENT_DAY.&quot;Claim Status Code&quot;,MONTH_END.&quot;Current Status&quot;) &quot;Current Claim Status Code&quot;
     , nvl(MONTH_END.&quot;Claim Status Code&quot;,&apos;&apos;) &quot;Prior Claim Status Code&quot;
     --
     , nvl(CURRENT_DAY.&quot;Prior Status&quot;,&apos;&apos;) &quot;Current Prior Status Code&quot;
     , nvl(MONTH_END.&quot;Prior Status&quot;,&apos;&apos;) &quot;Prior Prior Status Code&quot;
     --
     , nvl(CURRENT_DAY.&quot;Prior Open Status&quot;, &apos;&apos;)  &quot;Current Prior Open Status&quot;
     , nvl(MONTH_END.&quot;Prior Open Status&quot;, &apos;&apos;)  &quot;Prior Prior Open Status&quot;
     --
     , nvl(CURRENT_DAY.&quot;Prior Closed Status&quot;, &apos;&apos;)  &quot;Current Prior Closed Status&quot;
     , nvl(MONTH_END.&quot;Prior Closed Status&quot;, &apos;&apos;)  &quot;Prior Prior Closed Status&quot;
     , nvl(CURRENT_DAY.&quot;First Open Status&quot;, MONTH_END.&quot;First Open Status&quot;)  &quot;First Open Status&quot;
     , nvl(CURRENT_DAY.&quot;First Open Status Eff Date&quot;, MONTH_END.&quot;First Open Status Eff Date&quot;)  &quot;First Open Status Eff Date&quot;  
     --
     , nvl(CURRENT_DAY.&quot;First Closed Status&quot;, MONTH_END.&quot;First Closed Status&quot;)  &quot;First Closed Status&quot;
     , nvl(CURRENT_DAY.&quot;First Closed Status Eff Date&quot;, MONTH_END.&quot;First Closed Status Eff Date&quot;)  &quot;First Closed Status Eff Date&quot;  
    --
     , nvl(CURRENT_DAY.&quot;Insured Last Name&quot;, MONTH_END.&quot;Insured Last Name&quot;) &quot;Insured Last Name&quot;
     , nvl(CURRENT_DAY.&quot;Examiner Name&quot;, MONTH_END.&quot;Examiner Name&quot;) &quot;Examiner Name&quot;
     , nvl(CURRENT_DAY.&quot;Policy Number&quot;, MONTH_END.&quot;Policy Number&quot;) &quot;Policy Number&quot;     
     , nvl(CURRENT_DAY.&quot;Administered By&quot;, MONTH_END.&quot;Administered By&quot;) &quot;Administered By&quot;               
     , nvl(MONTH_END.&quot;Claim Count&quot;,0) &quot;Starting Claim Count&quot; 
     , nvl(CURRENT_DAY.&quot;Claim Count&quot;,0) - nvl(MONTH_END.&quot;Claim Count&quot;,0)  &quot;Chg Claim Count&quot;     
     , nvl(CURRENT_DAY.&quot;Claim Count&quot;,0) &quot;Ending Claim Count&quot;
     , MONTH_END.&quot;GAAP Reserve Direct Amt&quot; &quot;Starting GAAP Reserve Direct&quot;
     , nvl(CURRENT_DAY.&quot;GAAP Reserve Direct Amt&quot;,0) - nvl(MONTH_END.&quot;GAAP Reserve Direct Amt&quot;,0) &quot;Chg GAAP Reserve Direct&quot;
     , CURRENT_DAY.&quot;GAAP Reserve Direct Amt&quot; &quot;Ending GAAP Reserve Direct&quot;
     , MONTH_END.&quot;GAAP Reserve Net Amt&quot; &quot;Starting GAAP Reserve Net&quot;
     , nvl(CURRENT_DAY.&quot;GAAP Reserve Net Amt&quot;,0) - nvl(MONTH_END.&quot;GAAP Reserve Net Amt&quot;,0) &quot;Chg GAAP Reserve Net&quot;
     , CURRENT_DAY.&quot;GAAP Reserve Net Amt&quot; &quot;Ending GAAP Reserve Net&quot;
     --     
     , MONTH_END.&quot;Stat Reserve Direct Amt&quot; &quot;Starting Stat Reserve Direct&quot;
     , nvl(CURRENT_DAY.&quot;Stat Reserve Direct Amt&quot;,0) - nvl(MONTH_END.&quot;Stat Reserve Direct Amt&quot;,0) &quot;Chg Stat Reserve Direct&quot;
     , CURRENT_DAY.&quot;Stat Reserve Direct Amt&quot; &quot;Ending Stat Reserve Direct&quot;  
     , MONTH_END.&quot;Stat Reserve Net Amt&quot; &quot;Starting Stat Reserve Net&quot;
     , nvl(CURRENT_DAY.&quot;Stat Reserve Net Amt&quot;,0) - nvl(MONTH_END.&quot;Stat Reserve Net Amt&quot;,0) &quot;Chg Stat Reserve Net&quot;
     , CURRENT_DAY.&quot;Stat Reserve Net Amt&quot; &quot;Ending Stat Reserve Net&quot;  
     , nvl(MONTH_END.&quot;Reserve Net Benefit&quot;,0) &quot;Starting Net Ben&quot;    
    , nvl(CURRENT_DAY.&quot;Reserve Net Benefit&quot;,0)  &quot;Ending Net Ben&quot;
    , (MONTH_END.&quot;Duration&quot;) &quot;Starting Duration in Months&quot;
    , (CURRENT_DAY.&quot;Duration&quot;) &quot;Ending Duration in Months&quot;  
    , NVL(CURRENT_DAY.&quot;Received Date&quot;, MONTH_END.&quot;Received Date&quot;) RECEIVED_DATE
    , NVL(CURRENT_DAY.&quot;Closed Date&quot;, MONTH_END.&quot;Closed Date&quot;) CLOSED_DATE
	,CURRENT_DAY.&quot;Decision Made Date&quot;
    ,MONTH_END.&quot;Decision Made Date&quot; &quot;Decision Made Date Month End&quot;
	,CURRENT_DAY.&quot;Claim Decision Days&quot;
    ,MONTH_END.&quot;Claim Decision Days&quot; &quot;Claim Decision Days Month End&quot;
	,CURRENT_DAY.&quot;Plan Duration Date&quot;
    ,MONTH_END.&quot;Plan Duration Date&quot; &quot;Plan Duration Date Month End&quot;
    ,CURRENT_DAY.&quot;Any Occ Start Date&quot;
    ,MONTH_END.&quot;Any Occ Start Date&quot; &quot;Any Occ Start Date Month End&quot;
	,CURRENT_DAY.claim_decision_date
    ,MONTH_END.claim_decision_date claim_decision_date_month_end
    ,CURRENT_DAY.&quot;Loss Date&quot; 
    ,MONTH_END.&quot;Loss Date&quot; &quot;Loss Date Month End&quot;
    ,CURRENT_DAY.&quot;Primary Diagnosis Category&quot; 
    ,MONTH_END.&quot;Primary Diagnosis Category&quot; &quot;Primary Diagnosis Category Month End&quot; 
    ,CURRENT_DAY.&quot;Any Occ Group&quot;
    ,MONTH_END.&quot;Any Occ Group&quot; &quot;Any Occ Group Month End&quot; 
	,CURRENT_DAY.&quot;IEB Indicator&quot; 
	,MONTH_END.&quot;IEB Indicator&quot; &quot;IEB Indicator Month End&quot;
	,CURRENT_DAY.&quot;Client Name NEW&quot;
	,MONTH_END.&quot;Client Name NEW&quot; &quot;Client Name NEW Month End&quot;
	,CURRENT_DAY.&quot;Director Name&quot; 
	,MONTH_END.&quot;Director Name&quot; &quot;Director Name Month End&quot;
	,CURRENT_DAY.&quot;Supervisor Name&quot; 
	,MONTH_END.&quot;Supervisor Name&quot; &quot;Supervisor Name Month End&quot;
	,CASE 
    WHEN CURRENT_DAY.&quot;CARRIER NAME&quot; = &apos;Reliance Standard Life Insurance Company&apos; THEN &apos;RSLI&apos;
    WHEN CURRENT_DAY.&quot;CARRIER NAME&quot; = &apos;Reliance Standard Life Insurance Company of Texas&apos; THEN &apos;RSL TX&apos;
    WHEN CURRENT_DAY.&quot;CARRIER NAME&quot; = &apos;First Reliance Standard Life Insurance Company&apos; THEN &apos;FRSLIC&apos;
    WHEN CURRENT_DAY.&quot;CARRIER NAME&quot; = &apos;Matrix Company&apos; THEN &apos;Matrix Company&apos;
    ELSE CURRENT_DAY.&quot;CARRIER NAME&quot;
  END AS &quot;CURRENT DAY CARRIER NAME&quot; 
  ,CASE 
    WHEN MONTH_END.&quot;CARRIER NAME&quot; = &apos;Reliance Standard Life Insurance Company&apos; THEN &apos;RSLI&apos;
    WHEN MONTH_END.&quot;CARRIER NAME&quot; = &apos;Reliance Standard Life Insurance Company of Texas&apos; THEN &apos;RSL TX&apos;
    WHEN MONTH_END.&quot;CARRIER NAME&quot; = &apos;First Reliance Standard Life Insurance Company&apos; THEN &apos;FRSLIC&apos;
    WHEN MONTH_END.&quot;CARRIER NAME&quot; = &apos;Matrix Company&apos; THEN &apos;Matrix Company&apos;
    ELSE MONTH_END.&quot;CARRIER NAME&quot;
  END AS &quot;MONTH END CARRIER NAME&quot; 
  ,NVL(NVL(CURRENT_DAY.N_POLICY_SK_R, MONTH_END.N_POLICY_SK_R),-1) AS N_POLICY_SK_R
  ,NVL(NVL(CURRENT_DAY.N_CLAIM_SK_R, MONTH_END.N_CLAIM_SK_R), -1) AS N_CLAIM_SK_R
  ,CAST(NULL AS TIMESTAMP) D_RECORD_START_DATE_R																			
  ,CAST(NULL AS TIMESTAMP) D_RECORD_END_DATE_R																			
  ,CAST(NULL AS VARCHAR(100)) V_SOURCE_SYSTEM_NAME_R																			
  ,SYSTIMESTAMP T_EVENT_TIMESTAMP_R																			
  ,SYSTIMESTAMP FIC_MIS_DATE_R																			
  ,LN_BATCH_ID_R  N_BATCH_ID_R																			
  ,ROWNUM N_SEQUENCE_NUMBER_R																			
  ,SYSTIMESTAMP T_CREATION_DATE_R																			
  ,SYSTIMESTAMP T_LAST_MODIFIED_DATE_R																			
  ,&apos;PRC_GRP_LOAD_STG_BA_LTD_ROLLFORWARD_FACT&apos; V_CREATED_BY_R																			
  ,&apos;PRC_GRP_LOAD_STG_BA_LTD_ROLLFORWARD_FACT&apos; V_LAST_MODIFIED_BY_R																			
from
(
                select v_policy_number_r &quot;Policy Number&quot;
                     , V_CLAIM_NUMBER_R &quot;Claim Identifier&quot;    
                     , lob &quot;LOB&quot;
                     , V_CLAIM_STATUS_CODE_R &quot;Claim Status Code&quot;
                     , D_CLAIM_STATUS_EFF_DATE_R &quot;Claim Status Effective Date&quot;
                     , last_day(D_LOSS_DATE_R) &quot;Loss Date&quot; 
                     , V_CLAIMANT_STATE_R &quot;Insured State&quot;     
                     , V_PRI_DIAGNOSIS_CODE_R &quot;Primary Diagnosis Code&quot;
                     , N_TOTAL_REINSURANCE_PCT_R &quot;Total Reins Loss Pct&quot; 
                     , V_ELIMINATION_PERIOD_R &quot;Elimination Period&quot;
                     , N_GROSS_BENEFIT_R &quot;Gross Benefit&quot;
                     ,  duration &quot;Duration&quot;
                     ,  duration_date &quot;Duration Date&quot;
                     , insured_last_name &quot;Insured Last Name&quot;
                     , insured_first_name &quot;Insured First Name&quot;
                     , D_BIRTH_DATE_R &quot;Insured Birth Date&quot;
                     , V_GENDER_R &quot;Insured Gender&quot;
                     , N_FINANCIAL_NET_BENEFIT_R &quot;Reserve Net Benefit&quot;  
                     , LD_MIS_DATE_R &quot;Reserve Valuation Date&quot;  
                    , report_month &quot;Report Month&quot;
                     , V_ANY_OCC_PERIOD_R &quot;Own Occ Period&quot;
                     , nvl(N_TOTAL_REINSURANCE_PCT_R,0) &quot;Total Resinsurance Pct&quot;
                     , &quot;GAAP Reserve Direct Amt&quot; &quot;GAAP Reserve Direct Amt&quot;
                     , &quot;GAAP Reserve Net Amt&quot; &quot;GAAP Reserve Net Amt&quot;
                     , &quot;Stat Reserve Direct Amt&quot; &quot;Stat Reserve Direct Amt&quot;
                     , &quot;Stat Reserve Net Amt&quot; &quot;Stat Reserve Net Amt&quot;
                     , to_number(1.000) &quot;Claim Count&quot;
                     , LD_MIS_DATE_R &quot;Valuation Date&quot;
                     , V_ADMINISTERED_BY_R &quot;Administered By&quot;
                     , V_EXAMINER_NAME_R &quot;Examiner Name&quot;
                     , &quot;Received Date&quot; &quot;Received Date&quot;
                     , &quot;Closed Date&quot; &quot;Closed Date&quot;
                     , substr(&quot;Prior Status&quot;,  instr(&quot;Prior Status&quot;,&apos;;&apos;)+1,2) &quot;Prior Status&quot;  
                     ,V_PRIOR_CLAIM_STATUS_CODE_R					 
                     , to_date(substr(&quot;Prior Status&quot;, 0, instr(&quot;Prior Status&quot;,&apos;;&apos;)-1), &apos;YYYYMMDD&apos;) &quot;Prior Status Eff Date&quot;                     
                     , substr(&quot;Prior Open Status&quot;,  instr(&quot;Prior Open Status&quot;,&apos;;&apos;)+1,2) &quot;Prior Open Status&quot;      
                     , to_date(substr(&quot;Prior Open Status&quot;, 0, instr(&quot;Prior Open Status&quot;,&apos;;&apos;)-1), &apos;YYYYMMDD&apos;) &quot;Prior Open Status Eff Date&quot;                     
                     , substr(&quot;Prior Closed Status&quot;,  instr(&quot;Prior Closed Status&quot;,&apos;;&apos;)+1,2) &quot;Prior Closed Status&quot;      
                     , to_date(substr(&quot;Prior Closed Status&quot;, 0, instr(&quot;Prior Closed Status&quot;,&apos;;&apos;)-1), &apos;YYYYMMDD&apos;) &quot;Prior Closed Status Eff Date&quot;
                     , substr(&quot;First Open Status&quot;,  instr(&quot;First Open Status&quot;,&apos;;&apos;)+1,2) &quot;First Open Status&quot;    
                     , to_date(substr(&quot;First Open Status&quot;, 0, instr(&quot;First Open Status&quot;,&apos;;&apos;)-1), &apos;YYYYMMDD&apos;) &quot;First Open Status Eff Date&quot;                      
                     , substr(&quot;First Closed Status&quot;,  instr(&quot;First Closed Status&quot;,&apos;;&apos;)+1,2) &quot;First Closed Status&quot;    
                     , to_date(substr(&quot;First Closed Status&quot;, 0, instr(&quot;First Closed Status&quot;,&apos;;&apos;)-1), &apos;YYYYMMDD&apos;) &quot;First Closed Status Eff Date&quot;  
                     ,LD_MIS_DATE_OG_PREV_R
                     ,LD_MIS_DATE_R
					 ,&quot;Decision Made Date&quot; &quot;Decision Made Date&quot;
					 ,&quot;Claim Decision Days&quot; &quot;Claim Decision Days&quot;
					 ,&quot;Plan Duration Date&quot; &quot;Plan Duration Date&quot;
					 , &quot;Any Occ Start Date&quot; &quot;Any Occ Start Date&quot;
					 , claim_decision_date  claim_decision_date
                     ,&quot;Primary Diagnosis Category&quot; &quot;Primary Diagnosis Category&quot;
                     ,&quot;Any Occ Group&quot; &quot;Any Occ Group&quot;
					 ,&quot;IEB Indicator&quot; &quot;IEB Indicator&quot;
					 ,&quot;RSL Entity&quot; &quot;RSL Entity&quot;
					 ,&quot;Client Name&quot; &quot;Client Name&quot;
					 ,&quot;Client Name NEW&quot; &quot;Client Name NEW&quot;
					 ,&quot;Director Name&quot; &quot;Director Name&quot;
					 ,&quot;Supervisor Name&quot; &quot;Supervisor Name&quot;
					 ,&quot;CARRIER NAME&quot; &quot;CARRIER NAME&quot; 
					 ,V_claim_status_category_r
					 ,N_POLICY_SK_R
					 ,N_CLAIM_SK_R
               FROM (                     
              select replace(case when v_policy_prefix_r in ( &apos;zzz&apos;, &apos;VIP&apos; ) then CD.V_CLAIM_NUMBER_R || &apos;-&apos; || CD.V_CLAIM_COVERAGE_CODE_R else CD.V_CLAIM_NUMBER_R end, &apos;-&apos;,&apos;&apos;) claim_num_no_dash
                     , case when v_policy_prefix_r in ( &apos;zzz&apos;, &apos;VIP&apos; ) then CD.V_CLAIM_IDENTIFIER_R else CD.V_CLAIM_NUMBER_R end V_CLAIM_NUMBER_R
                     , (CD.V_CLAIM_NUMBER_R) claim_num_raw
                     ,rpad(v_policy_prefix_r,3,&apos; &apos;) || v_policy_suffix_r v_policy_number_r   
                     , case when V_SMALL_GROUP_IND_R = &apos;Y&apos; then v_policy_prefix_r || &apos;-&apos; || &apos;SMALL&apos; 
                            when v_policy_prefix_r = &apos;VIP&apos; and V_COVERAGE_CATEGORY_R = &apos;LTD&apos; then &apos;LVP&apos;
                            when v_policy_prefix_r = &apos;VLT&apos; and V_COVERAGE_CATEGORY_R = &apos;LTD&apos; then &apos;VTD&apos;
                            when v_policy_prefix_r = &apos;zzz&apos; and CD.V_CLAIM_COVERAGE_CODE_R = &apos;CTD&apos; then &apos;CTD&apos;    
                          else v_policy_prefix_r end lob
                     , v_policy_prefix_r
                     , v_policy_suffix_r            
                     , V_CLAIM_STATUS_CODE_R
                     , trunc(D_CLAIM_STATUS_EFF_DATE_R, &apos;DD&apos;) D_CLAIM_STATUS_EFF_DATE_R
                     , D_LOSS_DATE_R  
                     , V_CLAIMANT_STATE_R 
                     , V_PRI_DIAGNOSIS_CODE_R
                     , N_TOTAL_REINSURANCE_PCT_R 
                     , V_ELIMINATION_PERIOD_R
                     , N_GROSS_BENEFIT_R
					 ,nvl(case when CD.V_DURATION_PERIOD_R &lt;&gt; &apos;0&apos; and CD.V_DURATION_INDICATOR_R = &apos;A&apos; then (CD.V_DURATION_PERIOD_R - trunc( months_between(CNTD.D_BIRTH_DATE_R, CD.D_LOSS_DATE_R) /12) ) * 12
                      when CD.V_DURATION_PERIOD_R &lt;&gt; &apos;0&apos; and CD.V_DURATION_INDICATOR_R = &apos;M&apos; then to_number(CD.V_DURATION_PERIOD_R)
                      when CD.V_DURATION_PERIOD_R &lt;&gt; &apos;0&apos; and CD.V_DURATION_INDICATOR_R in (&apos;E&apos;, &apos;W&apos; ) then to_number(CD.V_DURATION_PERIOD_R) * 7 / 30.45 end, 0)  duration                 
					, D_PLAN_DUR_DATE_R duration_date
					 ,&apos; &apos; insured_last_name
					 ,V_INDIVIDUAL_FIRST_NAME_R insured_first_name
                     , D_BIRTH_DATE_R  
                     , V_GENDER_R
                   , RD.N_FINANCIAL_NET_BENEFIT_R     
                     , V_ANY_OCC_PERIOD_R
                     , V_ADMINISTERED_BY_R
                     , V_EXAMINER_NAME_R
                     , D_CLAIM_RECEIVED_DATE_R &quot;Received Date&quot; 
                     , D_CLAIM_CLOSED_DATE_R &quot;Closed Date&quot; 
					,( select max(to_char(csd3.D_CLAIM_STATUS_EFF_DATE_R, &apos;YYYYMMDD&apos;) || &apos;;&apos; || csd3.V_CLAIM_STATUS_CODE_R ) 
                                       from RPT_CLAIM_DTL_R csd3 

                                      where CD.V_CLAIM_NUMBER_R = csd3.V_CLAIM_NUMBER_R 
                                       -- and CD.V_CLAIM_COVERAGE_CODE_R = csd3.V_CLAIM_COVERAGE_CODE_R  
                                       -- and CD.N_CLAIM_COVERAGE_GROUP_SK_R  = csd3.N_CLAIM_COVERAGE_GROUP_SK_R
									      and CD.v_claim_identifier_r = csd3.v_claim_identifier_r 
                                        and trunc(csd3.D_CLAIM_STATUS_EFF_DATE_R,&apos;DD&apos;) &lt; trunc(CD.D_CLAIM_STATUS_EFF_DATE_R, &apos;DD&apos;) 
										and trunc(csd3.D_CLAIM_STATUS_EFF_DATE_R, &apos;DD&apos;) &lt;= LD_MIS_DATE_OG_PREV_R.LD_MIS_DATE_OG_PREV_R
                                    ) &quot;Prior Status&quot; 
                     ,V_PRIOR_CLAIM_STATUS_CODE_R									
			        , ( select max(to_char(csd3.D_CLAIM_STATUS_EFF_DATE_R, &apos;YYYYMMDD&apos;) || &apos;;&apos; || csd3.V_CLAIM_STATUS_CODE_R ) 
                                       from RPT_CLAIM_DTL_R csd3 
                                      where CD.V_CLAIM_NUMBER_R = csd3.V_CLAIM_NUMBER_R 
                                        and CD.V_CLAIM_COVERAGE_CODE_R = csd3.V_CLAIM_COVERAGE_CODE_R
                                        and CD.N_CLAIM_COVERAGE_GROUP_SK_R  = csd3.N_CLAIM_COVERAGE_GROUP_SK_R
                                        and csd3.V_CLAIM_STATUS_CODE_R like &apos;3%&apos;
                                        and trunc(csd3.D_CLAIM_STATUS_EFF_DATE_R,&apos;DD&apos;) &lt; trunc(CD.D_CLAIM_STATUS_EFF_DATE_R, &apos;DD&apos;) 
										and trunc(csd3.D_CLAIM_STATUS_EFF_DATE_R, &apos;DD&apos;) &lt;= LD_MIS_DATE_OG_PREV_R.LD_MIS_DATE_OG_PREV_R
                                    ) &quot;Prior Open Status&quot;						
					,( select max(to_char(csd3.D_CLAIM_STATUS_EFF_DATE_R, &apos;YYYYMMDD&apos;) || &apos;;&apos; || csd3.V_CLAIM_STATUS_CODE_R ) 
                                       from RPT_CLAIM_DTL_R csd3 
                                      where CD.V_CLAIM_NUMBER_R = csd3.V_CLAIM_NUMBER_R 
                                        and CD.V_CLAIM_COVERAGE_CODE_R = csd3.V_CLAIM_COVERAGE_CODE_R
                                        and CD.N_CLAIM_COVERAGE_GROUP_SK_R  = csd3.N_CLAIM_COVERAGE_GROUP_SK_R
                                        and  ( csd3.V_CLAIM_STATUS_CODE_R &gt; &apos;59&apos; or csd3.V_CLAIM_STATUS_CODE_R = &apos;51&apos; )
                                        and trunc(csd3.D_CLAIM_STATUS_EFF_DATE_R,&apos;DD&apos;) &lt; trunc(CD.D_CLAIM_STATUS_EFF_DATE_R, &apos;DD&apos;) 
										and trunc(csd3.D_CLAIM_STATUS_EFF_DATE_R, &apos;DD&apos;) &lt;= LD_MIS_DATE_OG_PREV_R.LD_MIS_DATE_OG_PREV_R
                                    ) &quot;Prior Closed Status&quot;				
					,( select min(to_char(csd3.D_CLAIM_STATUS_EFF_DATE_R, &apos;YYYYMMDD&apos;) || &apos;;&apos; || csd3.V_CLAIM_STATUS_CODE_R ) 
                                       from RPT_CLAIM_DTL_R csd3 
                                      where CD.V_CLAIM_NUMBER_R = csd3.V_CLAIM_NUMBER_R 
                                        and CD.V_CLAIM_COVERAGE_CODE_R = csd3.V_CLAIM_COVERAGE_CODE_R
                                        and CD.N_CLAIM_COVERAGE_GROUP_SK_R  = csd3.N_CLAIM_COVERAGE_GROUP_SK_R
                                        and csd3.V_CLAIM_STATUS_CODE_R like &apos;3%&apos;
                                        and trunc(csd3.D_CLAIM_STATUS_EFF_DATE_R,&apos;DD&apos;) &lt; trunc(CD.D_CLAIM_STATUS_EFF_DATE_R, &apos;DD&apos;) 
										and trunc(csd3.D_CLAIM_STATUS_EFF_DATE_R, &apos;DD&apos;) &lt;= LD_MIS_DATE_OG_PREV_R.LD_MIS_DATE_OG_PREV_R
                                    ) &quot;First Open Status&quot;				
			         ,( select min(to_char(csd3.D_CLAIM_STATUS_EFF_DATE_R, &apos;YYYYMMDD&apos;) || &apos;;&apos; || csd3.V_CLAIM_STATUS_CODE_R ) 
                                       from RPT_CLAIM_DTL_R csd3 
                                      where CD.V_CLAIM_NUMBER_R = csd3.V_CLAIM_NUMBER_R 
                                        and CD.V_CLAIM_COVERAGE_CODE_R = csd3.V_CLAIM_COVERAGE_CODE_R
                                        and CD.N_CLAIM_COVERAGE_GROUP_SK_R  = csd3.N_CLAIM_COVERAGE_GROUP_SK_R
                                        and ( csd3.V_CLAIM_STATUS_CODE_R &gt; &apos;59&apos; or csd3.V_CLAIM_STATUS_CODE_R = &apos;51&apos; )
                                        and not  ( CSD3.V_CLAIM_STATUS_CODE_R  in ( &apos;91&apos;, &apos;92&apos; )
														or (CSD3.V_CLAIM_STATUS_CODE_R = &apos;95&apos; and csd3.D_CLAIM_STATUS_EFF_DATE_R &gt; CD.D_BENEFIT_START_R														
										and trunc(csd3.D_CLAIM_STATUS_EFF_DATE_R, &apos;DD&apos;) &lt;= LD_MIS_DATE_R.LD_MIS_DATE_R)
                                    ) 
                                    )&quot;First Closed Status&quot;						
                      ,N_RESERVE_DIRECT_GAAP_R &quot;GAAP Reserve Direct Amt&quot;
                     , N_RESERVE_DIRECT_GAAP_NET_R &quot;GAAP Reserve Net Amt&quot;
                     , N_RESERVE_DIRECT_STAT_R &quot;Stat Reserve Direct Amt&quot;
					 , N_RESERVE_DIRECT_STAT_NET_R &quot;Stat Reserve Net Amt&quot;
                     ,D_RESERVE_VALUATION_DATE_R
                     ,LD_MIS_DATE_OG_PREV_R.LD_MIS_DATE_OG_PREV_R
                     ,LD_MIS_DATE_R.LD_MIS_DATE_R
                     ,LD_MIS_DATE_R.LD_MIS_DATE_R as report_month
					,DD.Min_d_claim_decision_date_r &quot;Decision Made Date&quot;
					 ,DD.Min_n_claim_decision_days_r &quot;Claim Decision Days&quot;
					 ,D_PLAN_DUR_DATE_R &quot;Plan Duration Date&quot;
					 ,D_ANY_OCC_START_DATE_R &quot;Any Occ Start Date&quot;
                     ,Min_d_claim_decision_date_r as claim_decision_date 

                     ,V_PRI_DIAG_CATEGORY_DESC_R &quot;Primary Diagnosis Category&quot;
                     ,V_ANY_OCC_OWN_OCC_IND_R &quot;Any Occ Group&quot;
                     ,V_IEB_TYPE_R &quot;IEB Indicator&quot;
					 ,V_SHORT_NAME_R &quot;RSL Entity&quot;
					 ,V_MASTER_CUSTOMER_NAME_R &quot;Client Name&quot;
					 ,RCD.v_individual_last_name_r &quot;Client Name NEW&quot;
					 ,V_DIRECTOR_FULL_NAME_R &quot;Director Name&quot;
					 ,V_SUPERVISOR_FULL_NAME_R &quot;Supervisor Name&quot;
					 ,PD.V_CARRIER_NAME_R &quot;CARRIER NAME&quot;
					 ,V_claim_status_category_r
					 ,PD.N_POLICY_SK_R AS N_POLICY_SK_R
					 ,CD.N_CLAIM_SK_R AS N_CLAIM_SK_R
                FROM  RPT_RESERVE_DETAILS_R RD ,
			   RPT_CLAIM_DTL_R CD,
               RPT_CLAIMANT_DTL_R CNTD,               
               RPT_POLICY_DTL_R PD,
			   RPT_GRP_PRODUCT_R PRODUCT,
			   RPT_CLIENT_DTL_R RCD,
			   RPT_EMPLOYEE_R RE,
               LD_MIS_DATE_R,
               LD_MIS_DATE_OG_PREV_R,
			   (SELECT
                        min(a.d_claim_decision_date_r)                             Min_d_claim_decision_date_r,
                        min(a.d_claim_decision_date_r - b.d_claim_received_date_r) AS Min_n_claim_decision_days_r,
                        a.n_claim_sk_r,
                        a.n_claim_coverage_sk_r,
                        a.n_claim_coverage_group_sk_r
                    FROM
                        rpt_fct_rpt_claim_summary_r a,
                        rpt_claim_dtl_r             b
                    WHERE
                        b.n_claim_sk_r = a.n_claim_sk_r
                        AND b.n_claim_coverage_sk_r = a.n_claim_coverage_sk_r
                        AND b.n_claim_coverage_group_sk_r = a.n_claim_coverage_group_sk_r
                    GROUP BY
                        a.n_claim_sk_r,
                        a.n_claim_coverage_sk_r,
                        a.n_claim_coverage_group_sk_r) DD
where  ( RD.N_INSRD_PARTY_SK_R = CNTD.N_INSRD_PARTY_SK_R and RD.N_POLICY_SK_R = PD.N_POLICY_SK_R 
and RD.N_REPORTMONTH_R = CNTD.N_YEARMONTH_R and RD.N_REPORTMONTH_R = PD.N_YEARMONTH_R 
and RD.N_CLAIM_COVERAGE_GROUP_SK_R = CD.N_CLAIM_COVERAGE_GROUP_SK_R and RD.N_CLAIM_COVERAGE_SK_R = CD.N_CLAIM_COVERAGE_SK_R 
and RD.N_CLAIM_SK_R = CD.N_CLAIM_SK_R and RD.N_REPORTMONTH_R = CD.N_YEARMONTH_R AND RD.N_PRODUCT_SK_R = PRODUCT.N_PRODUCT_SK_R
and RD.N_REPORTMONTH_R = PRODUCT.N_YEARMONTH_R and RCD.N_YEARMONTH_R = RD.N_REPORTMONTH_R and RCD.N_CUST_PARTY_SK_R = RD.N_CUST_PARTY_SK_R
AND RD.N_EMPLOYEE_SK_R = RE.N_EMPLOYEE_SK_R  and RE.N_YEARMONTH_R=  (SELECT distinct MAX( N_YEARMONTH_R) FROM 
RPT_EMPLOYEE_R)
AND DD.n_claim_sk_r=CD.n_claim_sk_r AND DD.N_CLAIM_COVERAGE_SK_R = CD.N_CLAIM_COVERAGE_SK_R 
AND DD.N_CLAIM_COVERAGE_GROUP_SK_R = CD.N_CLAIM_COVERAGE_GROUP_SK_R
				  and RD.D_RESERVE_VALUATION_DATE_R = LD_MIS_DATE_R.LD_MIS_DATE_R
                  AND (V_CLAIM_STATUS_CODE_R  like &apos;3%&apos;
				  )
                  and PRODUCT.V_COVERAGE_TYPE_CODE_R = &apos;1&apos; 
                  and v_policy_prefix_r not in (  &apos;ASL&apos; ) 
                  and V_RESERVE_TYPE_IND_R = &apos;L&apos; 
                  and not (  V_CLAIM_COVERAGE_CODE_R = &apos;DF&apos; and v_policy_prefix_r in ( &apos;VIP&apos;, &apos;zzz&apos; )  ) 
                  and N_RESERVE_DIRECT_GAAP_NET_R &gt; 0 
                  )
)) Current_Day
FULL OUTER JOIN
(
                select v_policy_number_r &quot;Policy Number&quot;
                     , V_CLAIM_NUMBER_R &quot;Claim Identifier&quot;    
                     , lob &quot;LOB&quot;
                     , V_CLAIM_STATUS_CODE_R &quot;Claim Status Code&quot;
                     , D_CLAIM_STATUS_EFF_DATE_R &quot;Claim Status Effective Date&quot;
                     , last_day(D_LOSS_DATE_R) &quot;Loss Date&quot; 
                     , V_CLAIMANT_STATE_R &quot;Insured State&quot;     
                     , V_PRI_DIAGNOSIS_CODE_R &quot;Primary Diagnosis Code&quot;
                     , N_TOTAL_REINSURANCE_PCT_R &quot;Total Reins Loss Pct&quot;
                     , V_ELIMINATION_PERIOD_R &quot;Elimination Period&quot;
                     , N_GROSS_BENEFIT_R &quot;Gross Benefit&quot;
                     , duration &quot;Duration&quot;
                     , duration_date &quot;Duration Date&quot;
                     , insured_last_name &quot;Insured Last Name&quot;
                     , insured_first_name &quot;Insured First Name&quot;
                     , D_BIRTH_DATE_R &quot;Insured Birth Date&quot;
                     , V_GENDER_R &quot;Insured Gender&quot;
                     , N_FINANCIAL_NET_BENEFIT_R &quot;Reserve Net Benefit&quot;  
                     , D_RESERVE_VALUATION_DATE_R &quot;Reserve Valuation Date&quot;  
                     , report_month &quot;Report Month&quot;
                     , V_ANY_OCC_PERIOD_R &quot;Own Occ Period&quot;
                     , nvl(N_TOTAL_REINSURANCE_PCT_R,0) &quot;Total Resinsurance Pct&quot;
                     , &quot;GAAP Reserve Direct Amt&quot; &quot;GAAP Reserve Direct Amt&quot;
                     , &quot;GAAP Reserve Net Amt&quot; &quot;GAAP Reserve Net Amt&quot;
                     , &quot;Stat Reserve Direct Amt&quot; &quot;Stat Reserve Direct Amt&quot;
                     , &quot;Stat Reserve Net Amt&quot; &quot;Stat Reserve Net Amt&quot;
                     , to_number(1.000) &quot;Claim Count&quot;
                     ,D_RESERVE_VALUATION_DATE_R &quot;Valuation Date&quot;
                     , V_ADMINISTERED_BY_R &quot;Administered By&quot;
                     , V_EXAMINER_NAME_R &quot;Examiner Name&quot;
                     , &quot;Received Date&quot; &quot;Received Date&quot;
                     , &quot;Closed Date&quot; &quot;Closed Date&quot;
                     , substr(&quot;Prior Status&quot;,  instr(&quot;Prior Status&quot;,&apos;;&apos;)+1,2) &quot;Prior Status&quot;
					 ,V_PRIOR_CLAIM_STATUS_CODE_R
                     , to_date(substr(&quot;Prior Status&quot;, 0, instr(&quot;Prior Status&quot;,&apos;;&apos;)-1), &apos;YYYYMMDD&apos;) &quot;Prior Status Eff Date&quot;
                     , substr(&quot;Prior Open Status&quot;,  instr(&quot;Prior Open Status&quot;,&apos;;&apos;)+1,2) &quot;Prior Open Status&quot;
                     , to_date(substr(&quot;Prior Open Status&quot;, 0, instr(&quot;Prior Open Status&quot;,&apos;;&apos;)-1), &apos;YYYYMMDD&apos;) &quot;Prior Open Status Eff Date&quot;                     
                     , substr(&quot;Prior Closed Status&quot;,  instr(&quot;Prior Closed Status&quot;,&apos;;&apos;)+1,2) &quot;Prior Closed Status&quot;
                     , to_date(substr(&quot;Prior Closed Status&quot;, 0, instr(&quot;Prior Closed Status&quot;,&apos;;&apos;)-1), &apos;YYYYMMDD&apos;) &quot;Prior Closed Status Eff Date&quot;
                     , substr(&quot;Current Status&quot;,  instr(&quot;Current Status&quot;,&apos;;&apos;)+1,2) &quot;Current Status&quot;
                     , to_date(substr(&quot;Current Status&quot;, 0, instr(&quot;Current Status&quot;,&apos;;&apos;)-1), &apos;YYYYMMDD&apos;) &quot;Current Status Eff Date&quot;
		     , substr(&quot;First Open Status&quot;,  instr(&quot;First Open Status&quot;,&apos;;&apos;)+1,2) &quot;First Open Status&quot;    
                     , to_date(substr(&quot;First Open Status&quot;, 0, instr(&quot;First Open Status&quot;,&apos;;&apos;)-1), &apos;YYYYMMDD&apos;) &quot;First Open Status Eff Date&quot;                      
                     , substr(&quot;First Closed Status&quot;,  instr(&quot;First Closed Status&quot;,&apos;;&apos;)+1,2) &quot;First Closed Status&quot;    
                     , to_date(substr(&quot;First Closed Status&quot;, 0, instr(&quot;First Closed Status&quot;,&apos;;&apos;)-1), &apos;YYYYMMDD&apos;) &quot;First Closed Status Eff Date&quot;
					 ,&quot;Decision Made Date&quot; &quot;Decision Made Date&quot;
					 ,&quot;Claim Decision Days&quot; &quot;Claim Decision Days&quot;
					 ,&quot;Plan Duration Date&quot; &quot;Plan Duration Date&quot;
					 ,&quot;Any Occ Start Date&quot; &quot;Any Occ Start Date&quot;
					 , claim_decision_date claim_decision_date
                     ,&quot;Primary Diagnosis Category&quot; &quot;Primary Diagnosis Category&quot;
                     ,&quot;Any Occ Group&quot; &quot;Any Occ Group&quot;
					  ,&quot;IEB Indicator&quot; &quot;IEB Indicator&quot;
					 ,&quot;RSL Entity&quot; &quot;RSL Entity&quot;
					 ,&quot;Client Name&quot; &quot;Client Name&quot;
					 ,&quot;Client Name NEW&quot; &quot;Client Name NEW&quot;
					 ,&quot;Director Name&quot; &quot;Director Name&quot;
					 ,&quot;Supervisor Name&quot; &quot;Supervisor Name&quot;
					 ,&quot;CARRIER NAME&quot; &quot;CARRIER NAME&quot; 
					 ,V_claim_status_category_r
					 ,N_POLICY_SK_R
					 ,N_CLAIM_SK_R

               FROM (                     
              select replace(case when v_policy_prefix_r in ( &apos;zzz&apos;, &apos;VIP&apos; ) then CD.V_CLAIM_NUMBER_R || &apos;-&apos; || CD.V_CLAIM_COVERAGE_CODE_R else CD.V_CLAIM_NUMBER_R end, &apos;-&apos;,&apos;&apos;) claim_num_no_dash
			  ,case when v_policy_prefix_r in ( &apos;zzz&apos;, &apos;VIP&apos; ) then CD.V_CLAIM_IDENTIFIER_R else CD.V_CLAIM_NUMBER_R end V_CLAIM_NUMBER_R
                     , (CD.V_CLAIM_NUMBER_R) claim_num_raw
                     , rpad(v_policy_prefix_r,3,&apos; &apos;) || v_policy_suffix_r v_policy_number_r 
					 , case when V_SMALL_GROUP_IND_R = &apos;Y&apos; then v_policy_prefix_r || &apos;-&apos; || &apos;SMALL&apos; 
                            when v_policy_prefix_r = &apos;VIP&apos; and V_COVERAGE_CATEGORY_R = &apos;LTD&apos; then &apos;LVP&apos;
                            when v_policy_prefix_r = &apos;VLT&apos; and V_COVERAGE_CATEGORY_R = &apos;LTD&apos; then &apos;VTD&apos;
                            when v_policy_prefix_r = &apos;zzz&apos; and CD.V_CLAIM_COVERAGE_CODE_R = &apos;CTD&apos; then &apos;CTD&apos;    
                          else v_policy_prefix_r end lob
                     , v_policy_prefix_r
                     , v_policy_suffix_r         
                     , V_CLAIM_STATUS_CODE_R
                     , trunc(D_CLAIM_STATUS_EFF_DATE_R, &apos;DD&apos;) D_CLAIM_STATUS_EFF_DATE_R
                     , D_LOSS_DATE_R
                     , V_CLAIMANT_STATE_R
                     , V_PRI_DIAGNOSIS_CODE_R
                     , N_TOTAL_REINSURANCE_PCT_R 
                     , V_ELIMINATION_PERIOD_R
                     , N_GROSS_BENEFIT_R
					 ,nvl(case when CD.V_DURATION_PERIOD_R &lt;&gt; &apos;0&apos; and CD.V_DURATION_INDICATOR_R = &apos;A&apos; then (CD.V_DURATION_PERIOD_R - trunc(months_between(CNTD.D_BIRTH_DATE_R, CD.D_LOSS_DATE_R) /12) ) * 12
					 when CD.V_DURATION_PERIOD_R &lt;&gt; &apos;0&apos; and CD.V_DURATION_INDICATOR_R = &apos;M&apos; then to_number(CD.V_DURATION_PERIOD_R)
					 when CD.V_DURATION_PERIOD_R &lt;&gt; &apos;0&apos; and CD.V_DURATION_INDICATOR_R in (&apos;E&apos;, &apos;W&apos; ) then to_number(CD.V_DURATION_PERIOD_R) * 7 / 30.45
					 end, 0)  duration                 
					 ,D_PLAN_DUR_DATE_R duration_date
                     ,&apos; &apos; insured_last_name
					 ,V_INDIVIDUAL_FIRST_NAME_R insured_first_name
                     , D_BIRTH_DATE_R  
                     , V_GENDER_R
                     , RD.N_FINANCIAL_NET_BENEFIT_R     
                     , V_ANY_OCC_PERIOD_R
                     , V_ADMINISTERED_BY_R
                     , V_EXAMINER_NAME_R
                     , D_CLAIM_RECEIVED_DATE_R &quot;Received Date&quot;
                     , D_CLAIM_CLOSED_DATE_R &quot;Closed Date&quot;
				    ,( select max(to_char(csd3.D_CLAIM_STATUS_EFF_DATE_R, &apos;YYYYMMDD&apos;) || &apos;;&apos; || csd3.V_CLAIM_STATUS_CODE_R ) 
                                       from RPT_CLAIM_DTL_R csd3 
                                      where CD.V_CLAIM_NUMBER_R = csd3.V_CLAIM_NUMBER_R 
                                        and CD.V_CLAIM_COVERAGE_CODE_R = csd3.V_CLAIM_COVERAGE_CODE_R  ---V_COVERAGE_TYPE_CODE_R
                                        and CD.N_CLAIM_COVERAGE_GROUP_SK_R  = csd3.N_CLAIM_COVERAGE_GROUP_SK_R
                                        and trunc(csd3.D_CLAIM_STATUS_EFF_DATE_R,&apos;DD&apos;) &lt; trunc(CD.D_CLAIM_STATUS_EFF_DATE_R, &apos;DD&apos;) 
                                    ) &quot;Prior Status&quot; 
                      , V_PRIOR_CLAIM_STATUS_CODE_R									
					,( select max(to_char(csd3.D_CLAIM_STATUS_EFF_DATE_R, &apos;YYYYMMDD&apos;) || &apos;;&apos; || csd3.V_CLAIM_STATUS_CODE_R ) 
                                       from RPT_CLAIM_DTL_R csd3 
                                      where CD.V_CLAIM_NUMBER_R = csd3.V_CLAIM_NUMBER_R 
                                        and CD.V_CLAIM_COVERAGE_CODE_R = csd3.V_CLAIM_COVERAGE_CODE_R
                                        and CD.N_CLAIM_COVERAGE_GROUP_SK_R  = csd3.N_CLAIM_COVERAGE_GROUP_SK_R
                                        and csd3.V_CLAIM_STATUS_CODE_R like &apos;3%&apos;
                                        and trunc(csd3.D_CLAIM_STATUS_EFF_DATE_R,&apos;DD&apos;) &lt; trunc(CD.D_CLAIM_STATUS_EFF_DATE_R, &apos;DD&apos;) 
                                    ) &quot;Prior Open Status&quot;				
					,( select max(to_char(csd3.D_CLAIM_STATUS_EFF_DATE_R, &apos;YYYYMMDD&apos;) || &apos;;&apos; || csd3.V_CLAIM_STATUS_CODE_R ) 
                                       from RPT_CLAIM_DTL_R csd3 
                                      where CD.V_CLAIM_NUMBER_R = csd3.V_CLAIM_NUMBER_R 
                                        and CD.V_CLAIM_COVERAGE_CODE_R = csd3.V_CLAIM_COVERAGE_CODE_R
                                        and CD.N_CLAIM_COVERAGE_GROUP_SK_R  = csd3.N_CLAIM_COVERAGE_GROUP_SK_R
                                        and  ( csd3.V_CLAIM_STATUS_CODE_R &gt; &apos;59&apos; or csd3.V_CLAIM_STATUS_CODE_R = &apos;51&apos; )
                                        and trunc(csd3.D_CLAIM_STATUS_EFF_DATE_R,&apos;DD&apos;) &lt; trunc(CD.D_CLAIM_STATUS_EFF_DATE_R, &apos;DD&apos;) 
                                    ) &quot;Prior Closed Status&quot;				
	             , ( select max(to_char(csd3.D_CLAIM_STATUS_EFF_DATE_R, &apos;YYYYMMDD&apos;) || &apos;;&apos; || csd3.V_CLAIM_STATUS_CODE_R ) 
                                       from RPT_CLAIM_DTL_R csd3 
                                      where CD.V_CLAIM_NUMBER_R = csd3.V_CLAIM_NUMBER_R 
                                        and CD.V_CLAIM_COVERAGE_CODE_R = csd3.V_CLAIM_COVERAGE_CODE_R
                                        and CD.N_CLAIM_COVERAGE_GROUP_SK_R  = csd3.N_CLAIM_COVERAGE_GROUP_SK_R
                                        and trunc(csd3.D_CLAIM_STATUS_EFF_DATE_R,&apos;DD&apos;) &lt;=  LD_MIS_DATE_R.LD_MIS_DATE_R
                                    ) &quot;Current Status&quot;
                    ,( select min(to_char(csd3.D_CLAIM_STATUS_EFF_DATE_R, &apos;YYYYMMDD&apos;) || &apos;;&apos; || csd3.V_CLAIM_STATUS_CODE_R ) 
                                       from RPT_CLAIM_DTL_R csd3 
                                      where CD.V_CLAIM_NUMBER_R = csd3.V_CLAIM_NUMBER_R 
                                        and CD.V_CLAIM_COVERAGE_CODE_R = csd3.V_CLAIM_COVERAGE_CODE_R
                                        and CD.N_CLAIM_COVERAGE_GROUP_SK_R  = csd3.N_CLAIM_COVERAGE_GROUP_SK_R
                                        and csd3.V_CLAIM_STATUS_CODE_R like &apos;3%&apos;
                                        and trunc(csd3.D_CLAIM_STATUS_EFF_DATE_R,&apos;DD&apos;) &lt; trunc(CD.D_CLAIM_STATUS_EFF_DATE_R, &apos;DD&apos;) 
										and trunc(csd3.D_CLAIM_STATUS_EFF_DATE_R, &apos;DD&apos;) &lt;= LD_MIS_DATE_OG_PREV_R.LD_MIS_DATE_OG_PREV_R
                                    ) &quot;First Open Status&quot;
					,( select min(to_char(csd3.D_CLAIM_STATUS_EFF_DATE_R, &apos;YYYYMMDD&apos;) || &apos;;&apos; || csd3.V_CLAIM_STATUS_CODE_R ) 
                                       from RPT_CLAIM_DTL_R csd3 
                                      where CD.V_CLAIM_NUMBER_R = csd3.V_CLAIM_NUMBER_R 
                                        and CD.V_CLAIM_COVERAGE_CODE_R = csd3.V_CLAIM_COVERAGE_CODE_R
                                        and CD.N_CLAIM_COVERAGE_GROUP_SK_R  = csd3.N_CLAIM_COVERAGE_GROUP_SK_R
                                        and ( csd3.V_CLAIM_STATUS_CODE_R &gt; &apos;59&apos; or csd3.V_CLAIM_STATUS_CODE_R = &apos;51&apos; )
                                        and not  ( CSD3.V_CLAIM_STATUS_CODE_R  in ( &apos;91&apos;, &apos;92&apos; )
														or (CSD3.V_CLAIM_STATUS_CODE_R = &apos;95&apos; and csd3.D_CLAIM_STATUS_EFF_DATE_R &gt; CD.D_BENEFIT_START_R														
										and trunc(csd3.D_CLAIM_STATUS_EFF_DATE_R, &apos;DD&apos;) &lt;= LD_MIS_DATE_R.LD_MIS_DATE_R)
                                    ) 
                                    )&quot;First Closed Status&quot;				
                     ,N_RESERVE_DIRECT_GAAP_R &quot;GAAP Reserve Direct Amt&quot;
                     , N_RESERVE_DIRECT_GAAP_NET_R &quot;GAAP Reserve Net Amt&quot;
                     , N_RESERVE_DIRECT_STAT_R &quot;Stat Reserve Direct Amt&quot;
					 , N_RESERVE_DIRECT_STAT_NET_R &quot;Stat Reserve Net Amt&quot;
					 ,D_RESERVE_VALUATION_DATE_R,
                     LD_MIS_DATE_OG_PREV_R.LD_MIS_DATE_OG_PREV_R as report_month
					 ,DD.Min_d_claim_decision_date_r &quot;Decision Made Date&quot;
					 ,DD.Min_n_claim_decision_days_r &quot;Claim Decision Days&quot;
					 ,D_PLAN_DUR_DATE_R &quot;Plan Duration Date&quot;
					 ,D_ANY_OCC_START_DATE_R &quot;Any Occ Start Date&quot;
					 ,DD.Min_d_claim_decision_date_r as claim_decision_date 
                     ,V_PRI_DIAG_CATEGORY_DESC_R &quot;Primary Diagnosis Category&quot;
                     ,V_ANY_OCC_OWN_OCC_IND_R &quot;Any Occ Group&quot;
					 ,V_IEB_TYPE_R &quot;IEB Indicator&quot;
					 ,V_SHORT_NAME_R &quot;RSL Entity&quot;
					 ,V_MASTER_CUSTOMER_NAME_R &quot;Client Name&quot;
					 ,RCD.v_individual_last_name_r &quot;Client Name NEW&quot;
					 ,V_DIRECTOR_FULL_NAME_R &quot;Director Name&quot;
					 ,V_SUPERVISOR_FULL_NAME_R &quot;Supervisor Name&quot;
					 ,PD.V_CARRIER_NAME_R  &quot;CARRIER NAME&quot;
					 ,V_claim_status_category_r
					 ,PD.N_POLICY_SK_R AS N_POLICY_SK_R
					 ,CD.N_CLAIM_SK_R AS N_CLAIM_SK_R
               FROM  RPT_RESERVE_DETAILS_R RD,
			   RPT_CLAIM_DTL_R CD,
               RPT_CLAIMANT_DTL_R CNTD,               
               RPT_POLICY_DTL_R PD,
			   RPT_GRP_PRODUCT_R PRODUCT,
			   RPT_CLIENT_DTL_R RCD,
			   RPT_EMPLOYEE_R  RE,
               LD_MIS_DATE_R,
               LD_MIS_DATE_OG_PREV_R,
			   (SELECT
                        min(a.d_claim_decision_date_r)                             Min_d_claim_decision_date_r,
                        min(a.d_claim_decision_date_r - b.d_claim_received_date_r) AS Min_n_claim_decision_days_r,
                        a.n_claim_sk_r,
                        a.n_claim_coverage_sk_r,
                        a.n_claim_coverage_group_sk_r
                    FROM
                        rpt_fct_rpt_claim_summary_r a,
                        rpt_claim_dtl_r            b
                    WHERE
                        b.n_claim_sk_r = a.n_claim_sk_r
                        AND b.n_claim_coverage_sk_r = a.n_claim_coverage_sk_r
                        AND b.n_claim_coverage_group_sk_r = a.n_claim_coverage_group_sk_r

                    GROUP BY
                        a.n_claim_sk_r,
                        a.n_claim_coverage_sk_r,
                        a.n_claim_coverage_group_sk_r) DD

where  ( RD.N_INSRD_PARTY_SK_R = CNTD.N_INSRD_PARTY_SK_R and RD.N_POLICY_SK_R = PD.N_POLICY_SK_R
 and RD.N_REPORTMONTH_R = CNTD.N_YEARMONTH_R and RD.N_REPORTMONTH_R = PD.N_YEARMONTH_R 
 and RD.N_CLAIM_COVERAGE_GROUP_SK_R = CD.N_CLAIM_COVERAGE_GROUP_SK_R and RD.N_CLAIM_COVERAGE_SK_R = CD.N_CLAIM_COVERAGE_SK_R 
 and RD.N_CLAIM_SK_R = CD.N_CLAIM_SK_R and RD.N_REPORTMONTH_R = CD.N_YEARMONTH_R AND RD.N_PRODUCT_SK_R = PRODUCT.N_PRODUCT_SK_R
 and RD.N_REPORTMONTH_R = PRODUCT.N_YEARMONTH_R and RCD.N_YEARMONTH_R = RD.N_REPORTMONTH_R and RCD.N_CUST_PARTY_SK_R = RD.N_CUST_PARTY_SK_R
 AND RD.N_EMPLOYEE_SK_R = RE.N_EMPLOYEE_SK_R  and RE.N_YEARMONTH_R=  (SELECT distinct MAX( N_YEARMONTH_R) FROM 
RPT_EMPLOYEE_R)
 AND DD.n_claim_sk_r=CD.n_claim_sk_r AND DD.N_CLAIM_COVERAGE_SK_R = CD.N_CLAIM_COVERAGE_SK_R 
 AND DD.N_CLAIM_COVERAGE_GROUP_SK_R = CD.N_CLAIM_COVERAGE_GROUP_SK_R
                  and RD.D_RESERVE_VALUATION_DATE_R = LD_MIS_DATE_OG_PREV_R.LD_MIS_DATE_OG_PREV_R
                  AND PRODUCT.V_COVERAGE_TYPE_CODE_R = &apos;1&apos;
                  and (V_CLAIM_STATUS_CODE_R like &apos;3%&apos; 
				  ) 
                  and v_policy_prefix_r not in (  &apos;ASL&apos; ) 
                  and V_RESERVE_TYPE_IND_R = &apos;L&apos; 
                  and not (  V_CLAIM_COVERAGE_CODE_R = &apos;DF&apos; and v_policy_prefix_r in ( &apos;VIP&apos;, &apos;zzz&apos; )  ) 
                  and N_RESERVE_DIRECT_GAAP_NET_R &gt; 0 
                  )
)) MONTH_END
on ( month_end.&quot;Claim Identifier&quot; = current_day.&quot;Claim Identifier&quot; );
COMMIT;
 LC_TRCMSG := LC_TRCMSG || CHR(13) || &apos; INSERTED DATA INTO THE TABLE STG_BA_LTD_ROLLFORWARD_FACT:-&gt;&apos;|| ( DBMS_UTILITY.GET_TIME - LN_START_TIME )|| &apos; SECONDS&apos;;

 ELSE
	  lc_trcmsg:=lc_trcmsg||chr(13)||&apos;The current date/day is neither Fiscal Month End Date +1 nor Saturday , So data will not be loaded&apos;;
    END IF;


        INSERT INTO ATOMIC.PRCS_GRP_TBL_LOAD_DEBUG_TRC (
            V_JOB_NAME_R,
            V_PKG_PRC_NAME_R,
            N_SK_R,
            V_NUMBER_R,
            V_TRC_MSG_R,
            N_BATCH_ID_R,
            V_CREATED_BY_R,
            V_LAST_MODIFIED_BY_R
        ) VALUES (
            &apos;PRC_GRP_LOAD_STG_BA_LTD_ROLLFORWARD_FACT&apos;,
            &apos;PRC_GRP_LOAD_STG_BA_LTD_ROLLFORWARD_FACT&apos;,
            NULL,
            NULL,
            &apos;WHEN OTHERS RAISED IN PRC_GRP_LOAD_STG_BA_LTD_ROLLFORWARD_FACT :-&gt;&apos;
            || LC_TRCMSG
            || LC_SQLCODE
            || &apos;-&gt;&apos;
            || LC_SQLERRM,
            LN_N_BATCH_ID_R,
            &apos;PRC_GRP_LOAD_STG_BA_LTD_ROLLFORWARD_FACT&apos;,
            &apos;PRC_GRP_LOAD_STG_BA_LTD_ROLLFORWARD_FACT&apos;
        );

        COMMIT;
       /* RAISE_APPLICATION_ERROR(-20001, &apos;OTHERS-ERROR IN PRC_GRP_LOAD_STG_BA_LTD_ROLLFORWARD_FACT:-&gt;&apos; || LC_SQLERRM);*/

END;"