-- Cleaned for lineage: PKG_GRP_ANN_PREM_SUMMARY_R_INC_PRC_GRP_FCT_RPT_ANN_PREM_SUMMARY_R_INC (part 2/4)

Delete from Fct_RPT_ANN_PREM_SUMMARY_R where d_cycle_date_r = (select max(d_cycle_date_r) from Fct_RPT_ANN_PREM_SUMMARY_R_inc);