-- Cleaned for lineage: PKG_GRP_LOAD_RPT_BILLGROUP_R_PRC_GET_CUR_DATA (part 1/2)

PROCEDURE prc_upd_del_data IS
/***********************************************************************
    Purpose:  Procedure to update prior month active flag and current month partition
    Author     Date     Description
    VGireesh   10/11/23 Initial Creation
*******************************************************************************/
        ln_sqlrowcnt          NUMBER;

UPDATE rpt_billgroup_r
            SET
                v_rpt_active_status_r = 'N',
                v_last_modified_by_r = gc_updby,
                t_last_modified_date_r = gd_sysdate
            WHERE
                n_reportmonth_r = ln_fisc_prior_month;