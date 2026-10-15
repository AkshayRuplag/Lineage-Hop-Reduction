-- Cleaned for lineage: PRC_GRP_LOAD_FCT_LG_RESERVE_DETAILS_R (part 1/3)

IF TO_DATE(ld_fic_mis_date) = TO_DATE(ld_sysdate)  
   OR TRIM(LC_DAY)='SATURDAY'
   THEN
      lc_trcmsg:=lc_trcmsg||chr(13)||'5. Delete the records from the table FCT_LG_RESERVE_DETAILS_R where n_report_month_r = '||ln_curr_month;

delete  from  FCT_LG_RESERVE_DETAILS_R_INCR where TO_CHAR(D_RESERVE_VALUATION_DATE_R,'YYYYMM')=to_char(ln_curr_month);

Insert into the table FCT_LG_RESERVE_DETAILS_R_INCR:->'||ln_start_time||' Seconds';