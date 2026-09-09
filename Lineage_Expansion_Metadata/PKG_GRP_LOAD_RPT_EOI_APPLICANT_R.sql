--------------------------------------------------------
--  DDL for Package Body PKG_GRP_LOAD_RPT_EOI_APPLICANT_R
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "ATOMIC"."PKG_GRP_LOAD_RPT_EOI_APPLICANT_R" IS 
/***********************************************************************
  Purpose:  This package body contains procedures which loads data into RPT_EOI_APPLICANT_R

  Author     Date     Description
  ---------- -------- -------------------------------------------------
  VGireesh   10/11/23 Initial Creation
  Chandra    20/06/24 Added New Column V_WEB_DESCRIPTION_R
  Chandra    24/06/24 Added Columns V_INSERT_BY_R
  Chandra    02/07/24 Added columns V_SOURCE_SYSTEM_NAME_R,T_EVENT_TIMESTAMP_R,T_EVENT_TIMESTAMP_R_APP_HIS;
  Chandra    11/07/24 Logic change of column V_EXCESS_STATUS_R,v_gi_status_r
  Chandra    16/07/24 Added filter in where clause  AND t3832599.v_queue_r NOT IN ( 'Trashcan' )
                                                    AND t3831701.v_queue_name_r NOT IN ( 'Trashcan' ) requested by Gisha
  Gireesh    16/07/24 Logic change T_EVENT_TIMESTAMP_R_APP_HIS requested by Ganesan
  Gireesh    21/07/24 v_policy_suffix_r column added - requested by Ganesan
  Gireesh    29/07/24 Moved active status flag condtion into the tables and filters of queue Trashcan
                      Added Cust Party SK , Carrier Name and Client Name
  Gireesh    03/08/24 Added column V_HIGHLIGHT_IND_R
  Gireesh    23/08/24 Added column V_APPLICANT_CHILD_LAST_NAME_R for now populated null
  Chandra    13/09/24 Changed the logic to pull v_applicant_ssn_r t3832586 from to t3836064 alias
  Chandra    01/10/24 Added columns N_GI_REQUESTED_R,N_EXCESS_REQUESTED_R,N_EXCESS_AMOUNT_R and remapped d_gi_effective_date_r
  JCorrenti  11/02/25 Added comments and changed to bulk insert
  AnanthaJothi08/04/25 Added Parentheses () between OR Condition in dim_eoi_applicant_detail_r join condition-404201 task
  Rose		13/03/26 Commenting prc_upd_del_data and adding PKG_GRP_COMMON_UTIL.
  awatkins   Jun-15-26 (workitem 524637)
                       Modifying to load data via partition exchange versus kill and fill.
                       Changed joins to ansi standard and cleaned up the code in general to comply with standards.
                       Removed unused local procs and replaced with standard utilities. 
                       Implemented audit controls.
  awatkins   AUG-12-26 (workitem HOTFIX - dummy record restoration)
                       after implementation it was discovered that the dummy record was necessary
  ***********************************************************************/
 --Global Constants
  gd_sysdate              DATE := trunc(sysdate);
  gn_prior_month          NUMBER := to_number(to_char(add_months(trunc(gd_sysdate,'MM'),-1),'YYYYMM'));
  gn_current_month        NUMBER := to_number(to_char(gd_sysdate,'YYYYMM'));
  gn_sysdt_batchid        NUMBER := to_number(to_char(gd_sysdate,'YYYYMMDD'));
  gc_main_loadedby        VARCHAR2(200 CHAR):= 'pkg_grp_load_rpt_eoi_applicant_r.MAIN';
  gc_getcur_loadedby      VARCHAR2(200 CHAR):= 'pkg_grp_load_rpt_eoi_applicant_r.PRC_GET_CUR_DATA';
  gc_job_name             VARCHAR2(50 CHAR):= 'GRP_LOAD_RPT_EOI_APPLICANT_R';
  gc_running_status       VARCHAR2(30):= 'Running';
  gc_error_status         VARCHAR2(30):= 'Error';
  gc_success_status       VARCHAR2(30):= 'Success';
  gc_source               VARCHAR2(30):= 'EDW';
  gc_target               VARCHAR2(30):= 'RPT';
  gc_main_entity          VARCHAR2(30):= 'RPT_EOI_APPLICANT_R';

	--Global Variables
  gv_trcmsg               CLOB := 'Trace Message:->';
  gn_out_job_id           NUMBER;
  gv_errmsg               VARCHAR2(4000 CHAR);

	--START: 04-JUN-2025: NEW LOGGING MECHANISM CHANGES
  gc_message_type_r       prcs_job_log_message_r.v_message_type_r%TYPE := pkg_grp_log_util.gc_message_type_info;
  gc_count_type_r         prcs_job_log_message_r.v_count_type_r%TYPE := pkg_grp_log_util.gc_count_type_insert;
  gc_count_type_merge_r   prcs_job_log_message_r.v_count_type_r%TYPE := pkg_grp_log_util.gc_count_type_merge;  
  gn_run_cnt              prcs_job_log_message_r.n_count_r%TYPE := 0;

  gt_start_time_r         TIMESTAMP;
  gt_end_time_r           TIMESTAMP;
  gn_job_log_message_id_r NUMBER;

  gd_fic_mis_date         DATE;

  --END: 04-JUN-2025: NEW LOGGING MECHANISM CHANGES 

    --start 15-JUN-26: partition swap additions
  gv_rpt_table_name       CONSTANT prcs_job_log_r.v_job_name_r%TYPE := 'RPT_EOI_APPLICANT_R';
  gv_exg_table_name       CONSTANT prcs_job_log_r.v_job_name_r%TYPE := gv_rpt_table_name|| '_EXG';
  gv_schema_owner         CONSTANT prcs_job_log_r.v_job_name_r%TYPE := 'ATOMIC'; 
    --end 15-JUN-26: partition swap additions

/***********************************************************************
  Purpose:  dummy record creation

  Author     Date     Description
  ---------- -------- -------------------------------------------------
  awatkins   AUG-12-26 (workitem HOTFIX - dummy record restoration)
                       after implementation it was discovered that the dummy
                       record was necessary    

  ***********************************************************************/
  PROCEDURE prc_insert_dummy_rec IS
  BEGIN
    gv_trcmsg := '10.1 Entered into from prc_insert_dummy_rec';

  --START: NEW LOGGING MECHANISM CHANGES
    pkg_grp_log_util.prc_ins_prcs_job_log_message_r(
      p_job_id_r                    => gn_out_job_id,
      p_batch_id_r                  => gn_sysdt_batchid,
      p_message_type_r              => gc_message_type_r,
      p_code_location_r             => gc_main_loadedby,
      p_message_r                   => gv_trcmsg,
      p_count_type_r                => NULL,
      p_count_r                     => NULL,
      p_duration_r                  => NULL,
      p_created_by_r                => gc_job_name,
      out_prcs_job_log_message_id_r => gn_job_log_message_id_r
    );
    --END: NEW LOGGING MECHANISM CHANGES
    INSERT /*+ APPEND */ INTO atomic.rpt_eoi_applicant_r(
      v_last_modified_by_r,
      t_creation_date_r,
      v_created_by_r,
      t_last_modified_date_r,
      n_yearmonth_r,
      v_rpt_active_status_r,
      n_batch_id_r,
      n_application_history_sk_r,
      n_policy_sk_r
      )
    VALUES(
      gc_main_loadedby,
      gd_sysdate,
      gc_main_loadedby,
      gd_sysdate,
      gn_current_month,
      'Y',
      gn_sysdt_batchid,
      - 1,
      - 1);

    COMMIT;

    gv_trcmsg := '10.2 Exit from prc_insert_dummy_rec';

    pkg_grp_log_util.prc_ins_prcs_job_log_message_r(
      p_job_id_r                    => gn_out_job_id,
      p_batch_id_r                  => gn_sysdt_batchid,
      p_message_type_r              => gc_message_type_r,
      p_code_location_r             => gc_main_loadedby,
      p_message_r                   => gv_trcmsg,
      p_count_type_r                => NULL,
      p_count_r                     => NULL,
      p_duration_r                  => NULL,
      p_created_by_r                => gc_job_name,
      out_prcs_job_log_message_id_r => gn_job_log_message_id_r
    );

  EXCEPTION
    WHEN OTHERS THEN
      gv_errmsg := substr(sqlerrm,1,4000);

		--START: 04-JUN-2025: NEW LOGGING MECHANISM CHANGES
      gv_trcmsg := '10.z Error in prc_insert_dummy_rec'|| gv_errmsg;

      pkg_grp_log_util.prc_update_log_message_r(
        n_prcs_job_log_message_id_r => gn_job_log_message_id_r,
        p_err_msg                   => gv_trcmsg
      );
		--END: 04-JUN-2025: NEW LOGGING MECHANISM CHANGES

      pkg_grp_log_util.prc_update_log(
        p_job_id                 => gn_out_job_id,
        p_job_status             => gc_error_status,
        p_err_msg                => gv_errmsg,
        p_trc_msg                => gv_trcmsg,
        p_log_util_called_by_r   => gc_main_loadedby
      );

      RAISE;  
      END prc_insert_dummy_rec;

/***********************************************************************
  Purpose:  Main procedure ultimately loads RPT_EOI_APPLICANT_R thru partition exchange

  Author     Date     Description
  ---------- -------- -------------------------------------------------
  VGireesh   10/11/23 Initial Creation
  Rose		13/03/26 Commenting prc_upd_del_data and adding PKG_GRP_COMMON_UTIL.
  awatkins   Jun-15-26 (workitem 524637)
                       Modifying to load data via partition exchange versus kill and fill.
                       Cleaned up the code in general to comply with standards.
                       added audit controls.

  ***********************************************************************/
  PROCEDURE main IS

    --start 15-JUN-26: partition swap additions
    /*
        TYPE var_tbl_type IS
            TABLE OF rpt_eoi_applicant_r%rowtype INDEX BY BINARY_INTEGER;
        lt_var_tbl_typ               var_tbl_type;

        ln_start_time                NUMBER;
        */
    --end 15-JUN-26: partition swap additions        

    ln_rec_cnt            NUMBER := 0;
    ld_fic_mis_date_2     DATE;
    ln_fisc_current_month NUMBER;
    lv_partition_name     VARCHAR2(200);
  BEGIN
    --Call Log Util pkg to Insert entry in PRCS_JOB_LOG_R
    pkg_grp_log_util.prc_insert_log(
      p_source               => gc_source,
      p_job_nm               => gc_job_name,
      p_job_status           => gc_running_status,
      p_err_msg              => NULL,
      p_trc_msg              => NULL,
      p_n_batch_id           => gn_sysdt_batchid,
      p_log_util_called_by_r => gc_main_loadedby,
      out_job_id             => gn_out_job_id
    );

    gv_trcmsg := '1. Entered into main.';

      --START: NEW LOGGING MECHANISM CHANGES
    pkg_grp_log_util.prc_ins_prcs_job_log_message_r(
      p_job_id_r                    => gn_out_job_id,
      p_batch_id_r                  => gn_sysdt_batchid,
      p_message_type_r              => gc_message_type_r,
      p_code_location_r             => gc_main_loadedby,
      p_message_r                   => gv_trcmsg,
      p_count_type_r                => NULL,
      p_count_r                     => NULL,
      p_duration_r                  => NULL,
      p_created_by_r                => gc_job_name,
      out_prcs_job_log_message_id_r => gn_job_log_message_id_r
    );            
    --END: NEW LOGGING MECHANISM CHANGES

	--Common Utility Proc to get month end+2 date and month. Ex: If month end is 29-Aug-2025 then ln_fisc_current_month will be 202509
    pkg_grp_common_util.prc_fisc_month_calc(
      p_out_job_id          => gn_out_job_id,
      p_log_seq_num         => 2,
      ld_fic_mis_date_2     => ld_fic_mis_date_2,
      ln_fisc_current_month => ln_fisc_current_month
    );

    gd_fic_mis_date := ld_fic_mis_date_2;
    --29-Aug-2024 changes

		--Common Utility Proc to determine current and prior month ; Checks for month end logic and daily load logic as well 
    pkg_grp_common_util.prc_get_current_prior_month(
      p_out_job_id         => gn_out_job_id,
      p_log_seq_num        => 3,
      p_fic_mis_date       => ld_fic_mis_date_2,
      p_fisc_current_month => ln_fisc_current_month,
      p_current_month      => gn_current_month,
      p_prior_month        => gn_prior_month
    );

    --start 08-JUN-26: partition swap additions
    lv_partition_name := 'PART_'|| gv_rpt_table_name|| '_'|| gn_current_month;

    pkg_grp_common_util.prc_create_exchange_table_ddl(
      p_job_id          => gn_out_job_id,
      p_log_seq_num     => 4,
      p_main_table_name => gv_rpt_table_name,
      p_exg_table_name  => gv_exg_table_name,
      p_schema_name     => gv_schema_owner
    );

    pkg_grp_load_rpt_eoi_applicant_r.prc_get_cur_data;   

    --start 15-JUN-26: adding code for partition swapping and commenting old
    --no longer kill and fill logic 

      /*
      pkg_grp_common_util.prc_trunc_partition(
                                             p_out_job_id => gn_out_job_id,
                                             p_log_seq_num => 4,
                                             p_rpt_table => gc_rpt_table_name,
                                             p_idx_num => gc_rebuild_idx_degree,
                                             p_current_month => gn_current_month
      );

      gv_trcmsg := '4. Call prc_get_cur_data to get ref_cursor ';
      */


      /*
              --START: NEW LOGGING MECHANISM CHANGES
      pkg_grp_log_util.prc_ins_prcs_job_log_message_r(
                                                     p_job_id_r => gn_out_job_id,
                                                     p_batch_id_r => gn_sysdt_batchid,
                                                     p_message_type_r => gc_message_type_r,
                                                     p_code_location_r => gc_main_loadedby,
                                                     p_message_r => gv_trcmsg,
                                                     p_count_type_r => NULL,
                                                     p_count_r => NULL,
                                                     p_duration_r => NULL,
                                                     p_created_by_r => gc_job_name,
                                                     out_prcs_job_log_message_id_r => gn_job_log_message_id_r
      );            
    --END: NEW LOGGING MECHANISM CHANGES
       -- pkg_grp_load_rpt_eoi_applicant_r.prc_get_cur_data(var_ref_cur); --20250211 Bulk insert JC:  commented out
      gv_trcmsg := '4.z Completed Call Procedure prc_get_cur_data to get ref_cursor';
      */


      /*
              --START: NEW LOGGING MECHANISM CHANGES
      pkg_grp_log_util.prc_ins_prcs_job_log_message_r(
                                                     p_job_id_r => gn_out_job_id,
                                                     p_batch_id_r => gn_sysdt_batchid,
                                                     p_message_type_r => gc_message_type_r,
                                                     p_code_location_r => gc_main_loadedby,
                                                     p_message_r => gv_trcmsg,
                                                     p_count_type_r => NULL,
                                                     p_count_r => NULL,
                                                     p_duration_r => NULL,
                                                     p_created_by_r => gc_job_name,
                                                     out_prcs_job_log_message_id_r => gn_job_log_message_id_r
      );            
    --END: NEW LOGGING MECHANISM CHANGES
      gv_trcmsg := '5 data load starts';
      */



      /*
              --START: NEW LOGGING MECHANISM CHANGES
      pkg_grp_log_util.prc_ins_prcs_job_log_message_r(
                                                     p_job_id_r => gn_out_job_id,
                                                     p_batch_id_r => gn_sysdt_batchid,
                                                     p_message_type_r => gc_message_type_r,
                                                     p_code_location_r => gc_main_loadedby,
                                                     p_message_r => gv_trcmsg,
                                                     p_count_type_r => NULL,
                                                     p_count_r => NULL,
                                                     p_duration_r => NULL,
                                                     p_created_by_r => gc_job_name,
                                                     out_prcs_job_log_message_id_r => gn_job_log_message_id_r
      );            
    --END: NEW LOGGING MECHANISM CHANGES
      ln_rec_cnt := 0;
      */
  /*      LOOP
            lt_var_tbl_typ.DELETE;
            FETCH var_ref_cur
            BULK COLLECT INTO lt_var_tbl_typ LIMIT gn_bulk_coll_cnt;
            FORALL x IN lt_var_tbl_typ.first..lt_var_tbl_typ.last
                INSERT /*+APPEND_VALUES* / INTO rpt_eoi_applicant_r VALUES lt_var_tbl_typ ( x );

            ln_rec_cnt := ln_rec_cnt + lt_var_tbl_typ.count;
   -- commit;
            IF MOD(
                  ln_rec_cnt,
                  1000
               ) = 0 THEN
                COMMIT;
                pkg_log_error_utility.log_messages_insert(
                                                         p_batch_key          => gn_sysdt_batchid,
                                                         p_location           => 'PKG_GRP_LOAD_RPT_EOI_APPLICANT_R.main.6',
                                                         p_message            => ln_rec_cnt || ' records committed',
                                                         p_additional_message => ln_rec_cnt,
                                                         p_insert_by          => 'PKG_GRP_LOAD_RPT_EOI_APPLICANT_R.main'
                ); --20250211 Logging JC:  Added logging
            END IF;

            EXIT WHEN var_ref_cur%notfound;
        END LOOP;

        CLOSE var_ref_cur;
        COMMIT;*/
     --20250211 Bulk insert JC:  commented out

      /*INSERT
     --+APPEND_VALUES INTO rpt_eoi_applicant_r
         SELECT
     --+PARALLE(8) CAST(NULL AS VARCHAR2(300 CHAR))           AS v_applicant_child_first_name_r,
                t3836064.d_dob_r                          d_applicant_date_of_birth_r,
                t3836064.v_first_name_r                   v_applicant_first_name_r,
                t3836064.v_last_name_r                    v_applicant_last_name_r,
                MAX(t3832586.v_member_number_r)            v_applicant_member_number_r,
                sysdate - spouse_applicant_detail.d_dob_r v_applicant_spouse_age_r,
                spouse_applicant_detail.d_dob_r           d_applicant_spouse_date_of_birth_r,
                spouse_applicant_detail.v_first_name_r    v_applicant_spouse_first_name_r,
                spouse_applicant_detail.v_last_name_r     v_applicant_spouse_last_name_r,
                MAX('XXX-XX-' || substr(
                   t3836064.v_ssn_r,
                   length(
                           t3836064.v_ssn_r
                        )- 3,
                   4
                ))                                         v_applicant_ssn_r,
                t3843396.v_entity_type_r                  AS v_application_entity_type_r,
                t3831701.d_insert_date_r                  d_application_entry_date_r,
                t3832599.n_application_id_r               n_application_id_r,
                t3832599.v_queue_r                        v_application_queue_name_r,
                t3832599.d_received_date_r                d_application_received_date_r,
                t3832599.v_source_r                       v_application_source_r,
                t3844173.v_transaction_description_r      v_application_status_r,
                t3832599.n_s_status_id_r                  n_application_status_id_r,
                t3831701.v_code_r                         v_application_transaction_code_r,
                nvl(
                   t3842035.auto_approval_ind,
                   'Y'
                )                                          v_auto_approved_indicator_r,
                MAX(
                   CASE
                      WHEN t3843396.v_entity_type_r = 'CHILD' THEN
                         t3843396.d_gi_effective_date_r
                   END
                )                                          d_child_gi_effective_date_r,
                MAX(
                   CASE
                      WHEN t3843396.v_entity_type_r = 'INSURED' THEN
                         t3843396.d_excess_effective_date_r
                   END
                )                                          d_employee_excess_effective_date_r,
                MAX(
                   CASE
                      WHEN t3843396.v_entity_type_r = 'INSURED' THEN
                         t3843396.d_gi_effective_date_r
                   END
                )                                          d_employee_gi_effective_date_r,
                t3831701.v_insert_by_r                    v_eoi_processor_id_r,
                CAST(NULL AS DATE)                         d_excess_effective_date_r,
                MAX(
                   CASE
                      WHEN t3843396.v_entity_type_r = 'SPOUSE' THEN
                         t3843396.v_excess_status_r
                   END
                )                                          v_spouse_excess_status_r,
                MAX(
                   CASE
                      WHEN t3843396.v_entity_type_r = 'INSURED' THEN
                         t3843396.v_excess_status_r
                   END
                )                                          v_employee_excess_status_r,
                MAX(
                   CASE
                      WHEN t3843396.v_entity_type_r = 'CHILD' THEN
                         t3843396.v_excess_status_r
                   END
                )                                          v_child_excess_status_r,
                CASE
                   WHEN NOT t3843396.v_excess_status_r IS NULL THEN
                      concat(
                         'Excess ',
                         t3843396.v_excess_status_r
                      )
                   ELSE
                      t3843396.v_excess_status_r
                END                                       AS v_excess_status_r,
                t3843396.d_gi_effective_date_r            AS d_gi_effective_date_r,
                MAX(
                   CASE
                      WHEN t3843396.v_entity_type_r = 'INSURED' THEN
                         t3843396.v_gi_status_r
                   END
                )                                          v_employee_gi_status_r,
                MAX(
                   CASE
                      WHEN t3843396.v_entity_type_r = 'SPOUSE' THEN
                         t3843396.v_gi_status_r
                   END
                )                                          v_spouse_gi_status_r,
                MAX(
                   CASE
                      WHEN t3843396.v_entity_type_r = 'CHILD' THEN
                         t3843396.v_gi_status_r
                   END
                )                                          v_child_gi_status_r,
                t3843396.v_gi_status_r                    AS v_gi_status_r,
                t3844173.v_hidden_ind_r                   v_hidden_indicator_r,
                t3832599.n_s_insured_id_r                 n_insured_id_r,
                t3832586.v_member_number_r                AS v_insured_member_number_r,
                t3843396.f_is_waived_r                    v_is_waived_flag_r,
                t3831701.d_update_date_r                  d_most_recent_action_date_r,
                t3831701.v_description_r                  v_most_recent_action_description_r,
                t3831701.n_application_history_sk_r,
                t3844717.v_policy_number_r,
                t3844717.v_policy_prefix_r                AS v_policy_prefix_r,
                t3831701.v_queue_name_r                   v_queue_name_r,
                MAX(
                   CASE
                      WHEN t3843396.v_entity_type_r = 'CHILD' THEN
                         t3843396.d_excess_effective_date_r
                   END
                )                                          d_child_excess_effective_date_r,
                MAX(
                   CASE
                      WHEN t3843396.v_entity_type_r = 'SPOUSE' THEN
                         t3843396.d_excess_effective_date_r
                   END
                )                                          d_spouse_excess_effective_date_r,
                MAX(
                   CASE
                      WHEN t3843396.v_entity_type_r = 'SPOUSE' THEN
                         t3843396.d_gi_effective_date_r
                   END
                )                                          d_spouse_gi_effective_date_r,
                t3844717.n_policy_sk_r,
                t3832599.v_is_wet_signature_required_r    v_wet_signature_required_indicator_r,
                gc_main_loadedby                          v_last_modified_by_r,
                gd_sysdate                                t_creation_date_r,
                gc_main_loadedby                          v_created_by_r,
                gd_sysdate                                t_last_modified_date_r,
                gn_current_month                          n_yearmonth_r,
                'Y'                                       v_rpt_active_status_r,
                gn_sysdt_batchid                          n_batch_id_r,
                t3844173.v_web_description_r              v_web_description_r,
                t3832599.v_insert_by_r,
                t3831701.v_source_system_name_r,
                t3831701.t_event_timestamp_r,
                CASE
                   WHEN t3831701.d_insert_date_r IS NULL THEN
                      t3831701.t_event_timestamp_r
                   ELSE
                      to_timestamp(trunc(
                         t3831701.d_insert_date_r
                      )|| substr(
                         to_char(
                            t3831701.t_event_timestamp_r
                         ),
                         10
                      ))
                END                                       t_event_timestamp_r_app_his,
                t3844717.v_policy_suffix_r,
                t3833694.n_cust_party_sk_r,
                t3833694.v_carrier_name_r,
                (SELECT v_client_name_r
                 FROM(SELECT v_client_name_r,
                             rnk
                      FROM(SELECT
     --+parallel(4) d.v_individual_first_name_r || ' ' || d.v_individual_last_name_r AS v_client_name_r,
                                  RANK()
                                  OVER(PARTITION BY d.n_party_sk_r
                                       ORDER BY d.t_event_timestamp_r DESC
                                  )                                                                 rnk
                           FROM dim_grp_party_r d
                           WHERE d.n_party_sk_r = t3833694.n_cust_party_sk_r
                          )
                      WHERE rnk = 1
                            AND ROWNUM < 2
                     )
                )                                          v_client_name_r,
                t3844173.v_highlight_ind_r,
                CAST(NULL AS VARCHAR2(300))                v_applicant_child_last_name_r,
                CAST(NULL AS DATE)                         d_most_recent_action_date1_r,
                CAST(NULL AS VARCHAR2(300))                v_most_recent_action_description1_r,
                t3843396.n_gi_requested_r                 AS n_gi_requested_r,
                t3843396.n_approved_gi_r                  AS n_approved_gi_r,
                t3843396.n_excess_requested_r             AS n_excess_requested_r,
                t3843396.n_excess_amount_r                AS n_excess_amount_r,
                t3836064.d_doh_r                          d_applicant_date_of_hire_r
         FROM(SELECT *
              FROM dim_eoi_application_history_r
              WHERE v_active_status_r = 'Y'
                    AND v_queue_name_r <> 'Trashcan'
             )                 t3831701
     -- D_EOI_APPLICATION_HISTORY_R_Application ,(SELECT *
                    FROM dim_grp_applicationpolicies_r
                    WHERE v_active_status_r = 'Y'
                       )                 t3843865
     -- D_GRP_APPLICATIONPOLICIES_R_Application 
         LEFT OUTER JOIN(
            (
               (SELECT *
                FROM dim_grp_policy_dir_r
                WHERE v_active_status_r = 'Y'
               )                 t3844717
     -- D_GRP_POLICY_DIR_R_Policy 
               LEFT OUTER JOIN(
                  fct_grp_policy_r t3833694
     -- F_GRP_POLICY_R_Policy 
                  LEFT OUTER JOIN(SELECT *
                                  FROM dim_grp_party_dir_r
                                  WHERE v_active_status_r = 'Y'
                                 )                 t3842469
     -- D_GRP_PARTY_DIR_R_Party 
                  ON t3833694.n_cust_party_sk_r = t3842469.n_party_sk_r
               )
               ON t3833694.n_policy_sk_r = t3844717.n_policy_sk_r
                  AND t3833694.n_source_system_key_r = t3844717.n_source_system_key_r
                  AND t3833694.n_version_number_r = t3844717.n_policy_version_number_r
            )
            LEFT OUTER JOIN(SELECT *
                            FROM dim_grp_field_office_r
                            WHERE v_active_status_r = 'Y'
                           )                 t3842212
     -- D_GRP_FIELD_OFFICE_R_Agent 
            ON t3842212.v_code_r = t3842469.v_rso_abbrev_r
         )
         ON t3843865.n_policy_sk_r = t3844717.n_policy_sk_r
         LEFT OUTER JOIN(SELECT *
                         FROM dim_eoi_app_coverag_decision_r
                         WHERE v_active_status_r = 'Y'
                               AND nvl(
                            f_is_waived_r,
                            0
                         )NOT IN('1')
                        )                 t3843396
         ON t3843396.n_s_application_policy_id_r = t3843865.n_application_policy_id_r,
             (SELECT *
              FROM dim_eoi_transaction_r
              WHERE v_active_status_r = 'Y'
             )                 t3844173
     -- D_EOI_TRANSACTION_R_GroupReporting#1 ,(SELECT *
                    FROM dim_eoi_application_r
                    WHERE v_active_status_r = 'Y'
                       )                 t3832599
     -- D_EOI_APPLICATION_R_Application 
         LEFT OUTER JOIN(SELECT *
                         FROM dim_eoi_applicant_detail_r
                         WHERE v_entity_type_r = 'SPOUSE'
                               AND v_active_status_r = 'Y'
                               AND d_delete_date_r IS NULL
                        )                 spouse_applicant_detail
         ON spouse_applicant_detail.n_application_sk_r = t3832599.n_application_sk_r
         LEFT OUTER JOIN(SELECT DISTINCT 'N' auto_approval_ind,
                                         n_application_id_r
                         FROM dim_eoi_application_history_r
                         WHERE v_code_r <> 'APP'
                               AND v_insert_by_r NOT IN('VGEOI Automation Process',
                                                        'NIGHT JOB')
                               AND v_active_status_r = 'Y'
                        )                 t3842035
         ON t3832599.n_application_id_r = t3842035.n_application_id_r,
             (SELECT *
              FROM dim_insured_r
              WHERE v_active_status_r = 'Y'
             )                 t3832586
     -- D_INSURED_R_Insured ,
             (SELECT *
              FROM dim_eoi_applicant_detail_r
              WHERE(v_entity_type_r = 'INSURED'
                    OR v_source_system_name_r = 'STACS')
     --Added parentheses()
                   AND v_active_status_r     = 'Y'
                   AND d_delete_date_r IS NULL
             )                 t3836064
     -- D_EOI_APPLICANT_DETAIL_R_Application ,
             (SELECT *
              FROM dim_grp_party_r
              WHERE v_active_status_r = 'Y'
             )                 t3842217
     -- D_DIM_GRP_PARTY_R_Applicant 

         WHERE(t3831701.v_code_r = t3844173.v_transaction_code_r
               AND t3831701.n_application_id_r = t3843865.n_application_id_r
               AND t3832586.n_s_insured_id_r   = t3832599.n_s_insured_id_r
               AND t3832599.n_application_sk_r = t3836064.n_application_sk_r
               AND t3832599.n_application_sk_r = t3831701.n_application_sk_r
               AND t3836064.n_party_sk_r       = t3842217.n_party_sk_r
                  --AND t3843396.n_s_application_policy_id_r = t3843865.n_application_policy_id_r
               AND t3843865.n_policy_sk_r      = t3844717.n_policy_sk_r)
         GROUP BY t3836064.d_dob_r,
                  t3836064.v_first_name_r,
                  t3836064.v_last_name_r,
                  sysdate - spouse_applicant_detail.d_dob_r,
                  spouse_applicant_detail.d_dob_r,
                  spouse_applicant_detail.v_first_name_r,
                  spouse_applicant_detail.v_last_name_r,
                  t3843396.v_entity_type_r,
                  t3831701.d_insert_date_r,
                  t3832599.n_application_id_r,
                  t3832599.v_queue_r,
                  t3832599.d_received_date_r,
                  t3832599.v_source_r,
                  t3844173.v_transaction_description_r,
                  t3832599.n_s_status_id_r,
                  t3831701.v_code_r,
                  nvl(
                     t3842035.auto_approval_ind,
                     'Y'
                  ),
                  t3831701.v_insert_by_r,
                  t3844173.v_hidden_ind_r,
                  t3832599.n_s_insured_id_r,
                  t3843396.f_is_waived_r,
                  t3831701.d_update_date_r,
                  t3831701.v_description_r,
                  t3831701.v_queue_name_r,
                  t3832599.v_is_wet_signature_required_r,
                  t3844717.v_policy_number_r,
                  t3844717.n_policy_sk_r,
                  t3831701.n_application_history_sk_r,
                  t3832586.v_member_number_r,
                  t3844717.v_policy_prefix_r,
                  t3844173.v_web_description_r,
                  t3832599.v_insert_by_r,
                  t3831701.v_source_system_name_r,
                  t3831701.t_event_timestamp_r,
                  t3832599.t_event_timestamp_r,
                  t3843396.v_excess_status_r,
                  t3843396.d_gi_effective_date_r,
                  t3843396.v_gi_status_r,
                  t3844717.v_policy_suffix_r,
                  t3833694.n_cust_party_sk_r,
                  t3833694.v_carrier_name_r,
                  t3844173.v_highlight_ind_r,
                  t3843396.n_gi_requested_r,
                  t3843396.n_approved_gi_r,
                  t3843396.n_excess_requested_r,
                  t3843396.n_excess_amount_r,
                  t3836064.d_doh_r;

     --           20250211 Bulk insert JC: Added from cursor code
     --                                    Removed previous changes.  They are still available in curser def. 




      ln_rec_cnt := SQL%rowcount;
      COMMIT;
      gv_trcmsg := '5.z Data Loaded ';
      gt_end_time_r := systimestamp;
     */      


      /*
              --START: NEW LOGGING MECHANISM CHANGES
      pkg_grp_log_util.prc_ins_prcs_job_log_message_r(
                                                     p_job_id_r => gn_out_job_id,
                                                     p_batch_id_r => gn_sysdt_batchid,
                                                     p_message_type_r => gc_message_type_r,
                                                     p_code_location_r => gc_main_loadedby,
                                                     p_message_r => gv_trcmsg,
                                                     p_count_type_r => gc_count_type_r,
                                                     p_count_r => ln_rec_cnt,
                                                     p_duration_r => fnc_grp_time_duration(
            gt_start_time_r,
            gt_end_time_r
         ),
                                                     p_created_by_r => gc_job_name,
                                                     out_prcs_job_log_message_id_r => gn_job_log_message_id_r
      );            
    --END: NEW LOGGING MECHANISM CHANGES


      gv_trcmsg := '6. Rebuild Local Index prc_rebuild_index_partitions from Common Util for Partition: '
                   || gn_current_month;
      gt_start_time_r := systimestamp;
      pkg_grp_log_util.prc_ins_prcs_job_log_message_r(
                                                     p_job_id_r => gn_out_job_id,
                                                     p_batch_id_r => gn_sysdt_batchid,
                                                     p_message_type_r => gc_message_type_r,
                                                     p_code_location_r => gc_main_loadedby,
                                                     p_message_r => gv_trcmsg,
                                                     p_count_type_r => NULL,
                                                     p_count_r => NULL,
                                                     p_duration_r => NULL,
                                                     p_created_by_r => gc_job_name,
                                                     out_prcs_job_log_message_id_r => gn_job_log_message_id_r
      );
		--END: 04-JUN-2025: NEW LOGGING MECHANISM CHANGES
      */
      --end commenting out of old code/method of insertion

    pkg_grp_common_util.prc_partition_exchange(
      p_job_id          => gn_out_job_id,
      p_log_seq_num     => 6,
      p_main_table_name => gv_rpt_table_name,
      p_exg_table_name  => gv_exg_table_name,
      p_partition_name  => lv_partition_name,
      p_schema_name     => gv_schema_owner
    );        
    --end 08-JUN-26: partition swap additions

    gv_trcmsg := '7. Rebuild Local Index prc_rebuild_index_partitions from Common Util for Partition: '|| gn_current_month;
    gt_start_time_r := systimestamp;

    pkg_grp_log_util.prc_ins_prcs_job_log_message_r(
      p_job_id_r                    => gn_out_job_id,
      p_batch_id_r                  => gn_sysdt_batchid,
      p_message_type_r              => gc_message_type_r,
      p_code_location_r             => gc_main_loadedby,
      p_message_r                   => gv_trcmsg,
      p_count_type_r                => NULL,
      p_count_r                     => NULL,
      p_duration_r                  => NULL,
      p_created_by_r                => gc_job_name,
      out_prcs_job_log_message_id_r => gn_job_log_message_id_r
    );            

    pkg_grp_common_util.prc_rebuild_index_partitions(
      p_table_name      => gv_rpt_table_name,
      p_parallel_degree => 8,
      p_partition_name  => lv_partition_name,
      p_out_job_id      => gn_out_job_id,
      p_log_seq_num     => 7
    );

    gv_trcmsg := '7.z Completed Procedure prc_rebuild_indexes call from main';

    --START: NEW LOGGING MECHANISM CHANGES
    pkg_grp_log_util.prc_ins_prcs_job_log_message_r(
      p_job_id_r                    => gn_out_job_id,
      p_batch_id_r                  => gn_sysdt_batchid,
      p_message_type_r              => gc_message_type_r,
      p_code_location_r             => gc_main_loadedby,
      p_message_r                   => gv_trcmsg,
      p_count_type_r                => NULL,
      p_count_r                     => NULL,
      p_duration_r                  => NULL,
      p_created_by_r                => gc_job_name,
      out_prcs_job_log_message_id_r => gn_job_log_message_id_r
    );        
    --END: NEW LOGGING MECHANISM CHANGES

		gv_trcmsg:='9.0 Calling Audit control Process';
    gt_start_time_r := systimestamp;    

		SELECT count(1)
      INTO ln_rec_cnt
      FROM rpt_eoi_applicant_r
      WHERE n_yearmonth_r = GN_CURRENT_MONTH;

    PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
     (
      p_job_id_r                    => gn_out_job_id,
      p_batch_id_r                  => gn_sysdt_batchid,
      p_message_type_r              => gc_message_type_r,
      p_code_location_r             => gc_main_loadedby,
      p_message_r                   => gv_trcmsg,
      p_count_type_r                => 'AUDIT_TARGET_COUNT',
      p_count_r                     => ln_rec_cnt,
      p_duration_r                  => NULL,
      p_created_by_r                => GC_JOB_NAME,
      out_prcs_job_log_message_id_r => gn_job_log_message_id_r
    );	

		PRC_GRP_AUDIT_CONTROL_PROCESS (
      p_source_system     => gc_source,
      p_main_entity       => gc_main_entity,
      p_source_layer_name => gc_source,
      p_target_layer_name => gc_target);

		gv_trcmsg:='9.1 Post Audit Control Procedure';
    gt_end_time_r := systimestamp;

		PKG_GRP_LOG_UTIL.prc_ins_prcs_job_log_message_r
		 (
			p_job_id_r                    => gn_out_job_id,
			p_batch_id_r                  => gn_sysdt_batchid,
			p_message_type_r              => gc_message_type_r,
			p_code_location_r             => gc_main_loadedby,
			p_message_r                   => gv_trcmsg,
			p_count_type_r                => NULL,
			p_count_r                     => NULL,
			p_duration_r                  => fnc_grp_time_duration(gt_start_time_r,gt_end_time_r),
			p_created_by_r                => GC_JOB_NAME,
			out_prcs_job_log_message_id_r => gn_job_log_message_id_r
		);

    --adding dummy record back because other objects need it
    --hotfix 8/12/2026
    prc_insert_dummy_rec;    

    gv_trcmsg := '1.z Exit from main';
    pkg_grp_log_util.prc_ins_prcs_job_log_message_r(
      p_job_id_r                    => gn_out_job_id,
      p_batch_id_r                  => gn_sysdt_batchid,
      p_message_type_r              => gc_message_type_r,
      p_code_location_r             => gc_main_loadedby,
      p_message_r                   => gv_trcmsg,
      p_count_type_r                => NULL,
      p_count_r                     => NULL,
      p_duration_r                  => NULL,
      p_created_by_r                => gc_job_name,
      out_prcs_job_log_message_id_r => gn_job_log_message_id_r
    );            

    pkg_grp_log_util.prc_update_log(
      p_job_id               => gn_out_job_id,
      p_job_status           => gc_success_status,
      p_err_msg              => gv_errmsg,
      p_trc_msg              => gv_trcmsg,
      p_log_util_called_by_r => gc_main_loadedby
    );

  EXCEPTION
    WHEN OTHERS THEN
      gv_errmsg := substr(sqlerrm,1,4000);
      gv_trcmsg := '1. Error in main'|| gv_errmsg;

		--START: 04-JUN-2025: NEW LOGGING MECHANISM CHANGES
      pkg_grp_log_util.prc_update_log_message_r(
        n_prcs_job_log_message_id_r => gn_job_log_message_id_r,
        p_err_msg                   => gv_trcmsg
      );
		--END: 04-JUN-2025: NEW LOGGING MECHANISM CHANGES

      pkg_grp_log_util.prc_update_log(
        p_job_id                => gn_out_job_id,
        p_job_status            => gc_error_status,
        p_err_msg               => gv_errmsg,
        p_trc_msg               => gv_trcmsg,
        p_log_util_called_by_r  => gc_main_loadedby
      );

      RAISE;
  END main;

/*************************************************************************************************************************************
  Purpose:   prc_get_cur_data procedures inserts data to reporting exchange table
  Author     Date     	Description
  ---------- -------- 	-------------------------------------------------
  VGireesh   10/11/23 	Initial Creation

  A Watkins  Jun-15-26 	(workitem 524637)
						Modifying from a cursor load to a straight insert into an exchange table for
            performance optimization.
						Changed joins to ansi standard and made table aliases more meaningful.
*************************************************************************************************************************************/     
  PROCEDURE prc_get_cur_data AS
  BEGIN
    gv_trcmsg := '5.1 Entered into prc_get_cur_data ';

         --START: NEW LOGGING MECHANISM CHANGES
    pkg_grp_log_util.prc_ins_prcs_job_log_message_r(
      p_job_id_r                    => gn_out_job_id,
      p_batch_id_r                  => gn_sysdt_batchid,
      p_message_type_r              => gc_message_type_r,
      p_code_location_r             => gc_getcur_loadedby,
      p_message_r                   => gv_trcmsg,
      p_count_type_r                => NULL,
      p_count_r                     => NULL,
      p_duration_r                  => NULL,
      p_created_by_r                => gc_job_name,
      out_prcs_job_log_message_id_r => gn_job_log_message_id_r
    );               
    --END: NEW LOGGING MECHANISM CHANGES

    --start 15-JUN-26: partition swap additions
    EXECUTE IMMEDIATE 'ALTER SESSION ENABLE PARALLEL DML';
    gv_trcmsg := '5.2 - Data load starts for _EXG table for Partition Exchange';
    gt_start_time_r := systimestamp; 

    pkg_grp_log_util.prc_ins_prcs_job_log_message_r(
      p_job_id_r                    => gn_out_job_id,
      p_batch_id_r                  => gn_sysdt_batchid,
      p_message_type_r              => gc_message_type_r,
      p_code_location_r             => gc_getcur_loadedby,
      p_message_r                   => gv_trcmsg,
      p_count_type_r                => NULL,
      p_count_r                     => NULL,
      p_duration_r                  => NULL,
      p_created_by_r                => gc_job_name,
      out_prcs_job_log_message_id_r => gn_job_log_message_id_r
    );               

    --20260615 part of partition swap change
    --removed the old open select into ref cursor and replaced with
    --insert into exchange table;
    --the ref cursor load was already deprecated in 2025 anyway
    --along with the update columes proc
    --also renamed the aliases from numbers to add meaning 

                 --Open/Assign SELECT stmnt
    INSERT /*+ APPEND PARALLEL(stg, 4) */ INTO rpt_eoi_applicant_r_exg stg
      SELECT /*+ PARALLEL(4) */  
        CAST(NULL AS VARCHAR2(300))       v_applicant_child_first_name_r,
        appl_dtl_insured.d_dob_r              d_applicant_date_of_birth_r,
        appl_dtl_insured.v_first_name_r       v_applicant_first_name_r,
        appl_dtl_insured.v_last_name_r        v_applicant_last_name_r,
        insured.v_member_number_r             v_applicant_member_number_r,
        --there was a max on member number but it was also in the group by
        sysdate - appl_dtl_spouse.d_dob_r     v_applicant_spouse_age_r,
        appl_dtl_spouse.d_dob_r               d_applicant_spouse_date_of_birth_r,
        appl_dtl_spouse.v_first_name_r        v_applicant_spouse_first_name_r,
        appl_dtl_spouse.v_last_name_r         v_applicant_spouse_last_name_r,
        MAX('XXX-XX-' || substr(appl_dtl_insured.v_ssn_r,length(appl_dtl_insured.v_ssn_r)- 3,4))
          AS v_applicant_ssn_r,
        app_cov_dcsn.v_entity_type_r          v_application_entity_type_r,
        eoi_app_hist.d_insert_date_r          d_application_entry_date_r,
        eoi_app.n_application_id_r            n_application_id_r,
        eoi_app.v_queue_r                     v_application_queue_name_r,
        eoi_app.d_received_date_r             d_application_received_date_r,
        eoi_app.v_source_r                    v_application_source_r,
        eoi_trans.v_transaction_description_r v_application_status_r,
        eoi_app.n_s_status_id_r               n_application_status_id_r,
        eoi_app_hist.v_code_r                 v_application_transaction_code_r,
        CASE
          WHEN deah.n_application_id_r IS NULL 
          THEN 'Y'
          ELSE 'N'
        END v_auto_approved_indicator_r,
        MAX(
          CASE
            WHEN app_cov_dcsn.v_entity_type_r = 'CHILD' 
            THEN app_cov_dcsn.d_gi_effective_date_r
          END
          ) d_child_gi_effective_date_r,
        MAX(
          CASE
            WHEN app_cov_dcsn.v_entity_type_r = 'INSURED' 
            THEN app_cov_dcsn.d_excess_effective_date_r
          END
          ) d_employee_excess_effective_date_r,
        MAX(
          CASE
            WHEN app_cov_dcsn.v_entity_type_r = 'INSURED' 
            THEN app_cov_dcsn.d_gi_effective_date_r
          END
          ) d_employee_gi_effective_date_r,
        eoi_app_hist.v_insert_by_r            v_eoi_processor_id_r,
        CAST(NULL AS DATE)                     d_excess_effective_date_r,
        MAX(
          CASE
            WHEN app_cov_dcsn.v_entity_type_r = 'SPOUSE' 
            THEN app_cov_dcsn.v_excess_status_r
          END
          ) v_spouse_excess_status_r,
        MAX(
          CASE
            WHEN app_cov_dcsn.v_entity_type_r = 'INSURED' 
            THEN app_cov_dcsn.v_excess_status_r
          END
          ) v_employee_excess_status_r,
        MAX(
          CASE
            WHEN app_cov_dcsn.v_entity_type_r = 'CHILD' 
            THEN app_cov_dcsn.v_excess_status_r
          END
          ) v_child_excess_status_r,
        CASE
          WHEN NOT app_cov_dcsn.v_excess_status_r IS NULL 
          THEN concat('Excess ',app_cov_dcsn.v_excess_status_r)
          ELSE app_cov_dcsn.v_excess_status_r
        END AS v_excess_status_r,
        app_cov_dcsn.d_gi_effective_date_r    AS d_gi_effective_date_r,
        MAX(
          CASE
            WHEN app_cov_dcsn.v_entity_type_r = 'INSURED' 
            THEN app_cov_dcsn.v_gi_status_r
          END
          ) v_employee_gi_status_r,
        MAX(
          CASE
            WHEN app_cov_dcsn.v_entity_type_r = 'SPOUSE' 
            THEN app_cov_dcsn.v_gi_status_r
          END
          ) v_spouse_gi_status_r,
        MAX(
          CASE
            WHEN app_cov_dcsn.v_entity_type_r = 'CHILD' 
            THEN app_cov_dcsn.v_gi_status_r
          END
          ) v_child_gi_status_r,
          app_cov_dcsn.v_gi_status_r            v_gi_status_r,
          eoi_trans.v_hidden_ind_r              v_hidden_indicator_r,
          eoi_app.n_s_insured_id_r              n_insured_id_r,
          insured.v_member_number_r             v_insured_member_number_r,
          app_cov_dcsn.f_is_waived_r            v_is_waived_flag_r,
          eoi_app_hist.d_update_date_r          d_most_recent_action_date_r,
          eoi_app_hist.v_description_r          v_most_recent_action_description_r,
          eoi_app_hist.n_application_history_sk_r,
          plcy_dir.v_policy_number_r,
          plcy_dir.v_policy_prefix_r            v_policy_prefix_r,
          eoi_app_hist.v_queue_name_r           v_queue_name_r,
          MAX(
            CASE
              WHEN app_cov_dcsn.v_entity_type_r = 'CHILD' 
              THEN app_cov_dcsn.d_excess_effective_date_r
            END
            ) d_child_excess_effective_date_r,
          MAX(
            CASE
              WHEN app_cov_dcsn.v_entity_type_r = 'SPOUSE' 
              THEN app_cov_dcsn.d_excess_effective_date_r
            END
            ) d_spouse_excess_effective_date_r,
          MAX(
            CASE
              WHEN app_cov_dcsn.v_entity_type_r = 'SPOUSE' 
              THEN app_cov_dcsn.d_gi_effective_date_r
            END
            ) d_spouse_gi_effective_date_r,
          plcy_dir.n_policy_sk_r,
          eoi_app.v_is_wet_signature_required_r v_wet_signature_required_indicator_r,
          gc_main_loadedby                     v_last_modified_by_r,
          gd_sysdate                           t_creation_date_r,
          gc_main_loadedby                     v_created_by_r,
          gd_sysdate                           t_last_modified_date_r,
          gn_current_month                     n_yearmonth_r,
          'Y'                                   v_rpt_active_status_r,
          gn_sysdt_batchid                     n_batch_id_r,
          eoi_trans.v_web_description_r         v_web_description_r,
          eoi_app.v_insert_by_r,
          eoi_app_hist.v_source_system_name_r,
          eoi_app_hist.t_event_timestamp_r,
          CASE
            WHEN eoi_app_hist.d_insert_date_r IS NULL 
            THEN eoi_app_hist.t_event_timestamp_r
            ELSE to_timestamp(trunc(eoi_app_hist.d_insert_date_r)|| 
              substr(to_char(eoi_app_hist.t_event_timestamp_r),10))
          END t_event_timestamp_r_app_his,
          plcy_dir.v_policy_suffix_r,
          plcy.n_cust_party_sk_r,
          plcy.v_carrier_name_r,
          (
            SELECT /* +PARALLEL(4) */ 
              v_client_name_r
            FROM(
              SELECT d.v_individual_first_name_r || ' ' || d.v_individual_last_name_r AS v_client_name_r,
               d.n_party_sk_r,
               ROW_NUMBER() OVER(PARTITION BY d.n_party_sk_r
                            ORDER BY d.t_event_timestamp_r DESC,
                                     n_sequence_number_r DESC) rnk
              FROM dim_grp_party_r d
              WHERE d.n_party_sk_r = plcy.n_cust_party_sk_r
               )
            WHERE rnk = 1) v_client_name_r,
          eoi_trans.v_highlight_ind_r,
          CAST(NULL AS VARCHAR2(300))            v_applicant_child_last_name_r,
          CAST(NULL AS DATE)                     d_most_recent_action_date1_r,
          CAST(NULL AS VARCHAR2(300))            v_most_recent_action_description1_r,
          app_cov_dcsn.n_gi_requested_r         n_gi_requested_r,
          app_cov_dcsn.n_approved_gi_r          n_approved_gi_r,
          app_cov_dcsn.n_excess_requested_r     n_excess_requested_r,
          app_cov_dcsn.n_excess_amount_r        n_excess_amount_r,
          appl_dtl_insured.d_doh_r              d_applicant_date_of_hire_r
      FROM atomic.dim_eoi_application_history_r eoi_app_hist
      INNER JOIN atomic.dim_grp_applicationpolicies_r  app_policies
      ON app_policies.n_application_id_r = eoi_app_hist.n_application_id_r
      AND app_policies.v_active_status_r = 'Y'
      INNER JOIN atomic.dim_eoi_application_r eoi_app
      ON eoi_app.n_application_sk_r = eoi_app_hist.n_application_sk_r
      AND eoi_app.v_active_status_r = 'Y'
      INNER JOIN atomic.dim_eoi_transaction_r eoi_trans
      ON eoi_trans.v_transaction_code_r = eoi_app_hist.v_code_r
      AND eoi_trans.v_active_status_r = 'Y'
      INNER JOIN atomic.dim_eoi_applicant_detail_r appl_dtl_insured
      ON appl_dtl_insured.n_application_sk_r = eoi_app.n_application_sk_r
      AND appl_dtl_insured.v_active_status_r = 'Y'
      AND appl_dtl_insured.d_delete_date_r IS NULL
      AND(appl_dtl_insured.v_entity_type_r = 'INSURED'
        OR appl_dtl_insured.v_source_system_name_r = 'STACS')
      INNER JOIN atomic.dim_insured_r insured
      ON insured.n_s_insured_id_r = eoi_app.n_s_insured_id_r
      AND insured.v_active_status_r = 'Y'
    --code note 524637
    --moved to an in clause
    --inner join atomic.dim_grp_party_r party
    --on party.n_party_sk_r = appl_dtl_insured.n_party_sk_r
      LEFT OUTER JOIN atomic.dim_eoi_applicant_detail_r appl_dtl_spouse
      ON appl_dtl_spouse.n_application_sk_r = eoi_app.n_application_sk_r
      AND appl_dtl_spouse.v_active_status_r = 'Y'
      AND appl_dtl_spouse.d_delete_date_r IS NULL
      AND appl_dtl_spouse.v_entity_type_r = 'SPOUSE'
      OUTER APPLY(
        SELECT deah.n_application_id_r
        FROM atomic.dim_eoi_application_history_r deah
        WHERE deah.n_application_id_r = eoi_app.n_application_id_r
        AND deah.v_code_r <> 'APP'
        AND deah.v_insert_by_r NOT IN('VGEOI Automation Process','NIGHT JOB')
        AND deah.v_active_status_r = 'Y'
        GROUP BY deah.n_application_id_r
        ) deah
      INNER JOIN atomic.dim_grp_policy_dir_r plcy_dir
      ON plcy_dir.n_policy_sk_r = app_policies.n_policy_sk_r
      AND plcy_dir.v_active_status_r = 'Y'
      --old code STATED that plcy_dir was a left join but it was really
      --an inner join because the policy_sk_r clause was also in the
      --where clause, thus it's really an inner join
      LEFT OUTER JOIN atomic.dim_eoi_app_coverag_decision_r app_cov_dcsn
      ON app_cov_dcsn.n_s_application_policy_id_r = app_policies.n_application_policy_id_r
      AND app_cov_dcsn.v_active_status_r = 'Y'
      AND nvl(app_cov_dcsn.f_is_waived_r,'0')<> '1'
      LEFT OUTER JOIN atomic.fct_grp_policy_r plcy
      ON plcy.n_policy_sk_r = plcy_dir.n_policy_sk_r
      AND plcy.n_source_system_key_r = plcy_dir.n_source_system_key_r
      AND plcy.n_version_number_r = plcy_dir.n_policy_version_number_r
    --code note 524637
    --these do not contribute to the query outcome at all
    --and exaserbate the performance plan
    --so kicking them out
    --left outer join atomic.dim_grp_party_dir_r party_dir
    --on party_dir.n_party_sk_r = plcy.n_cust_party_sk_r
    --and party_dir.v_active_status_r = 'Y'
    --left outer join atomic.dim_grp_field_office_r field_office
    --on field_office.v_code_r = party_dir.v_rso_abbrev_r
      WHERE eoi_app_hist.v_active_status_r = 'Y'
      AND eoi_app_hist.v_queue_name_r <> 'Trashcan'
      AND appl_dtl_insured.n_party_sk_r IN (
        SELECT party.n_party_sk_r 
        FROM atomic.dim_grp_party_r party
        WHERE v_active_status_r = 'Y')
      GROUP BY 
        CAST(NULL AS VARCHAR2(300)),
        appl_dtl_insured.d_dob_r,
        appl_dtl_insured.v_first_name_r,
        appl_dtl_insured.v_last_name_r,
        sysdate - appl_dtl_spouse.d_dob_r,
        appl_dtl_spouse.d_dob_r,
        appl_dtl_spouse.v_first_name_r,
        appl_dtl_spouse.v_last_name_r,
        app_cov_dcsn.v_entity_type_r,
        eoi_app_hist.d_insert_date_r,
        eoi_app.n_application_id_r,
        eoi_app.v_queue_r,
        eoi_app.d_received_date_r,
        eoi_app.v_source_r,
        eoi_trans.v_transaction_description_r,
        eoi_app.n_s_status_id_r,
        eoi_app_hist.v_code_r,
        CASE
          WHEN deah.n_application_id_r IS NULL 
          THEN 'Y'
          ELSE 'N'
        END,
        eoi_app_hist.v_insert_by_r,
        eoi_trans.v_hidden_ind_r,
        eoi_app.n_s_insured_id_r,
        app_cov_dcsn.f_is_waived_r,
        eoi_app_hist.d_update_date_r,
        eoi_app_hist.v_description_r,
        eoi_app_hist.v_queue_name_r,
        eoi_app.v_is_wet_signature_required_r,
        gc_main_loadedby,
        gd_sysdate,
        gc_main_loadedby,
        gd_sysdate,
        gn_current_month,
        'Y',
        gn_sysdt_batchid,
        plcy_dir.v_policy_number_r,
        plcy_dir.n_policy_sk_r,
        eoi_app_hist.n_application_history_sk_r,
        insured.v_member_number_r,
        plcy_dir.v_policy_prefix_r,
        eoi_trans.v_web_description_r,
        eoi_app.v_insert_by_r,
        eoi_app_hist.v_source_system_name_r,
        eoi_app_hist.t_event_timestamp_r,
        eoi_app.t_event_timestamp_r,
        app_cov_dcsn.v_excess_status_r,
        app_cov_dcsn.d_gi_effective_date_r,
        app_cov_dcsn.v_gi_status_r,
        plcy_dir.v_policy_suffix_r,
        plcy.n_cust_party_sk_r,
        plcy.v_carrier_name_r,
        eoi_trans.v_highlight_ind_r,
        app_cov_dcsn.n_gi_requested_r,
        app_cov_dcsn.n_approved_gi_r,
        app_cov_dcsn.n_excess_requested_r,
        app_cov_dcsn.n_excess_amount_r,
        appl_dtl_insured.d_doh_r
    ;

    gn_run_cnt := SQL%rowcount;
    COMMIT;

        --end 15-JUN-26: partition swap additions

    gv_trcmsg := '5.2 Completion of insertion';
    gt_end_time_r := systimestamp;

    pkg_grp_log_util.prc_ins_prcs_job_log_message_r(
      p_job_id_r                    => gn_out_job_id,
      p_batch_id_r                  => gn_sysdt_batchid,
      p_message_type_r              => gc_message_type_r,
      p_code_location_r             => gc_getcur_loadedby,
      p_message_r                   => gv_trcmsg,
      p_count_type_r                => gc_count_type_r,
      p_count_r                     => gn_run_cnt,
      p_duration_r                  => fnc_grp_time_duration(gt_start_time_r,gt_end_time_r),
      p_created_by_r                => gc_job_name,
      out_prcs_job_log_message_id_r => gn_job_log_message_id_r
    );	       
    --END: NEW LOGGING MECHANISM CHANGES

    EXECUTE IMMEDIATE 'ALTER SESSION DISABLE PARALLEL DML';
    gv_trcmsg := '5.3 exit from prc_get_cur_data';

    pkg_grp_log_util.prc_ins_prcs_job_log_message_r(
      p_job_id_r                    => gn_out_job_id,
      p_batch_id_r                  => gn_sysdt_batchid,
      p_message_type_r              => gc_message_type_r,
      p_code_location_r             => gc_getcur_loadedby,
      p_message_r                   => gv_trcmsg,
      p_count_type_r                => NULL,
      p_count_r                     => NULL,
      p_duration_r                  => NULL,
      p_created_by_r                => gc_job_name,
      out_prcs_job_log_message_id_r => gn_job_log_message_id_r
    );            	  

        --end 15-JUN-26: partition swap additions

  EXCEPTION
    WHEN OTHERS THEN
      gv_errmsg := substr(sqlerrm,1,4000);

		--START: 04-JUN-2025: NEW LOGGING MECHANISM CHANGES
      gv_trcmsg := '5.z Error in prc_get_cur_data'|| gv_errmsg;

      pkg_grp_log_util.prc_update_log_message_r(
        n_prcs_job_log_message_id_r => gn_job_log_message_id_r,
        p_err_msg                   => gv_trcmsg
      );
		--END: 04-JUN-2025: NEW LOGGING MECHANISM CHANGES

      pkg_grp_log_util.prc_update_log(
        p_job_id                 => gn_out_job_id,
        p_job_status             => gc_error_status,
        p_err_msg                => gv_errmsg,
        p_trc_msg                => gv_trcmsg,
        p_log_util_called_by_r   => gc_getcur_loadedby
      );

      RAISE;
  END prc_get_cur_data;

END pkg_grp_load_rpt_eoi_applicant_r;

/

  GRANT EXECUTE ON "ATOMIC"."PKG_GRP_LOAD_RPT_EOI_APPLICANT_R" TO "ATOMIC_ALL_RO";
  GRANT EXECUTE ON "ATOMIC"."PKG_GRP_LOAD_RPT_EOI_APPLICANT_R" TO "EXT_EIS_RO";
  GRANT DEBUG ON "ATOMIC"."PKG_GRP_LOAD_RPT_EOI_APPLICANT_R" TO "205JMX";
  GRANT DEBUG ON "ATOMIC"."PKG_GRP_LOAD_RPT_EOI_APPLICANT_R" TO "ATOMIC_DEBUG";
  GRANT DEBUG ON "ATOMIC"."PKG_GRP_LOAD_RPT_EOI_APPLICANT_R" TO "205CJX";
