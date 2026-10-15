-- Cleaned for lineage: PKG_GRP_LOAD_FCT_RPT_CROSS_SELL_SUMMARY_R_MAIN

gv_trcmsg:='5.0 Validatating cycle date if date is available then Delete Cycle Date data from FCT_RPT_CROSS_SELL_SUMMARY_R'||ld_cycle_date_r_2;

ELSE
      gv_trcmsg:='5.2 Delete Cycle Date data from FCT_RPT_CROSS_SELL_SUMMARY_R';

DELETE  FROM ATOMIC.FCT_RPT_CROSS_SELL_SUMMARY_R WHERE TRUNC(TO_DATE(D_CYCLE_DATE_R))=TRUNC(TO_DATE(gd_cycle_date));

INSERT  INTO  FCT_RPT_CROSS_SELL_SUMMARY_R VALUES LT_VAR_CROSS_SELL_TBL_TYP(X);