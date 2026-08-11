

  CREATE OR REPLACE EDITIONABLE PROCEDURE "ATOMIC"."PRC_DROP_CREATE_FCT_GRP_POLICY_R_LTDPOLIND_MV_SSL" AS

    gd_sysdate        DATE := trunc(sysdate);
    gn_sysdt_batchid  NUMBER := to_number(to_char(
                                                gd_sysdate,
                                                'YYYYMMDD'
                                         ));
    gc_running_status VARCHAR2(30) := 'Running';
    gc_error_status   VARCHAR2(30) := 'Error';
    gc_success_status VARCHAR2(30) := 'Success';
    gc_source         VARCHAR2(30) := 'EDW';
--Global Variables
    gn_out_job_id     NUMBER;
    gc_errmsg         VARCHAR2(4000 CHAR);

    PROCEDURE execute_immediate_no_raise (
        sql_stmt CLOB
    ) IS
    BEGIN
        EXECUTE IMMEDIATE ( sql_stmt );
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END;

BEGIN
    pkg_grp_log_util.prc_insert_log(
                                   p_source               => gc_source,
                                   p_job_nm               => 'prc_drop_create_fct_grp_policy_r_ltdpolind_mv_ssl',
                                   p_job_status           => gc_running_status,
                                   p_err_msg              => NULL,
                                   p_trc_msg              => NULL,
                                   p_n_batch_id           => gn_sysdt_batchid,
                                   p_log_util_called_by_r => 'prc_drop_create_fct_grp_policy_r_ltdpolind_mv_ssl',
                                   out_job_id             => gn_out_job_id
    );

    pkg_log_error_utility.log_messages_insert(
                                             p_batch_key          => gn_sysdt_batchid,
                                             p_location           => 'prc_drop_create_fct_grp_policy_r_ltdpolind_mv_ssl.1',
                                             p_message            => 'prc_drop_create_fct_grp_policy_r_ltdpolind_mv_ssl started',
                                             p_additional_message => '',
                                             p_insert_by          => 'prc_drop_create_fct_grp_policy_r_ltdpolind_mv_ssl'
    );

    pkg_log_error_utility.log_messages_insert(
                                             p_batch_key          => gn_sysdt_batchid,
                                             p_location           => 'prc_drop_create_fct_grp_policy_r_ltdpolind_mv_ssl.2',
                                             p_message            => 'Drop FCT_GRP_POLICY_R_LTDPOLIND_MV_SSL started',
                                             p_additional_message => '',
                                             p_insert_by          => 'prc_drop_create_fct_grp_policy_r_ltdpolind_mv_ssl'
    );

    execute_immediate_no_raise('DROP MATERIALIZED VIEW "FCT_GRP_POLICY_R_LTDPOLIND_MV_SSL"'); --JC:  added for initial run
    execute_immediate_no_raise('DROP TABLE "FCT_GRP_POLICY_R_LTDPOLIND_MV_SSL"');
    pkg_log_error_utility.log_messages_insert(
                                             p_batch_key          => gn_sysdt_batchid,
                                             p_location           => 'prc_drop_create_fct_grp_policy_r_ltdpolind_mv_ssl.3',
                                             p_message            => 'Drop FCT_GRP_POLICY_R_LTDPOLIND_MV_SSL ended',
                                             p_additional_message => '',
                                             p_insert_by          => 'prc_drop_create_fct_grp_policy_r_ltdpolind_mv_ssl'
    );

    pkg_log_error_utility.log_messages_insert(
                                             p_batch_key          => gn_sysdt_batchid,
                                             p_location           => 'prc_drop_create_fct_grp_policy_r_ltdpolind_mv_ssl.4',
                                             p_message            => 'Create FCT_GRP_POLICY_R_LTDPOLIND_MV_SSL started',
                                             p_additional_message => '',
                                             p_insert_by          => 'prc_drop_create_fct_grp_policy_r_ltdpolind_mv_ssl'
    );

    EXECUTE IMMEDIATE ( '
CREATE TABLE "FCT_GRP_POLICY_R_LTDPOLIND_MV_SSL" ("CLAIM_SK", "LTD_POLICY_IND") PARALLEL  AS
SELECT a.N_CLAIM_SK_R AS CLAIM_SK,
	(
		CASE
			WHEN a.v_lob_type_r IN (
					''LIFE'',
					''STD'',
					''VPS'',
					''WOP'',
					''NONS''
					)
				AND EXISTS (
					SELECT
						c.n_cust_party_sk_r
					FROM
						atomic.dim_grp_policy_dir_r b,
						atomic.fct_grp_policy_r c,
						atomic.dim_grp_party_r f,
						atomic.fct_grp_transactions_r d
					WHERE
						b.n_policy_version_number_r = c.n_version_number_r
						AND b.n_policy_sk_r = c.n_policy_sk_r
						AND b.v_active_status_r = ''Y''
						AND f.v_active_status_r = ''Y''
						and f.v_master_customer_num_r = e.v_master_customer_num_r
						AND c.n_cust_party_sk_r = f.n_party_sk_r
						AND b.v_orig_lob_r IN (
							''ASL'',
							''LTD-SMALL'',
							''LTD'',
							''VPL'',
							''LTDVLT''
							)
						AND a.D_DATE_OF_LOSS_R >= b.T_POLICY_EFFECTIVE_DATE_R
						AND b.n_policy_sk_r = d.n_policy_skey_r
						AND b.n_policy_version_number_r = d.N_TXN_VERSION_NUMBER_R
						AND a.D_DATE_OF_LOSS_R <= CASE
							WHEN d.V_BUS_OBJ_STATUS_R IN (
									''BOUNDTERMINATE'',
									''TERMINATED'',
									''CANCELREINSTATE''
									)
								THEN D_EFFECTIVE_R
							ELSE to_date(''01-DEC-99'', ''dd-mon-yy'')
							END
					)
				THEN ''Y''
			ELSE NULL --Legacy has it as ''No LTD''
			END
		) ltd_policy_ind
FROM
	atomic.dim_grp_claim_dir_r a,
	atomic.dim_grp_policy_dir_r b,
	atomic.fct_grp_policy_r c,
	atomic.dim_grp_party_r e --Added Aug 2024 for Master Customer
WHERE a.v_active_status_r = ''Y''
	AND a.n_policy_sk_r = b.n_policy_sk_r
	AND b.v_active_status_r = ''Y''
	AND e.v_active_status_r = ''Y''
	AND b.n_policy_version_number_r = c.n_version_number_r
	AND b.n_source_system_key_r = c.n_source_system_key_r --24-May-2024 changes
	AND e.n_party_sk_r = c.n_cust_party_sk_r
	AND b.n_policy_sk_r = c.n_policy_sk_r
	AND v_lob_type_r <> ''ANNUITY''' );
    pkg_log_error_utility.log_messages_insert(
                                             p_batch_key          => gn_sysdt_batchid,
                                             p_location           => 'prc_drop_create_fct_grp_policy_r_ltdpolind_mv_ssl.5',
                                             p_message            => 'Create FCT_GRP_POLICY_R_LTDPOLIND_MV_SSL ended',
                                             p_additional_message => '',
                                             p_insert_by          => 'prc_drop_create_fct_grp_policy_r_ltdpolind_mv_ssl'
    );

    pkg_log_error_utility.log_messages_insert(
                                             p_batch_key          => gn_sysdt_batchid,
                                             p_location           => 'prc_drop_create_fct_grp_policy_r_ltdpolind_mv_ssl.6',
                                             p_message            => 'Create indexes for FCT_GRP_POLICY_R_LTDPOLIND_MV_SSL started',
                                             p_additional_message => '',
                                             p_insert_by          => 'prc_drop_create_fct_grp_policy_r_ltdpolind_mv_ssl'
    );

    EXECUTE IMMEDIATE ( 'CREATE INDEX "FCT_GRP_POLICY_R_LTDPOLIND_MV_SSL_IDX1" ON
    "FCT_GRP_POLICY_R_LTDPOLIND_MV_SSL" (
        "CLAIM_SK",
        "LTD_POLICY_IND"
    )
        PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS
            STORAGE ( INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645 PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL
            DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT )
        --TABLESPACE "OFS_OIDF_DATA_3"
        ' );
    pkg_log_error_utility.log_messages_insert(
                                             p_batch_key          => gn_sysdt_batchid,
                                             p_location           => 'prc_drop_create_fct_grp_policy_r_ltdpolind_mv_ssl.7',
                                             p_message            => 'Create indexes for FCT_GRP_POLICY_R_LTDPOLIND_MV_SSL ended',
                                             p_additional_message => '',
                                             p_insert_by          => 'prc_drop_create_fct_grp_policy_r_ltdpolind_mv_ssl'
    );

    pkg_log_error_utility.log_messages_insert(
                                             p_batch_key          => gn_sysdt_batchid,
                                             p_location           => 'prc_drop_create_fct_grp_policy_r_ltdpolind_mv_ssl.8',
                                             p_message            => 'Create snapshots and grants for FCT_GRP_POLICY_R_LTDPOLIND_MV_SSL started',
                                             p_additional_message => '',
                                             p_insert_by          => 'prc_drop_create_fct_grp_policy_r_ltdpolind_mv_ssl'
    );

    execute_immediate_no_raise('COMMENT ON MATERIALIZED VIEW "FCT_GRP_POLICY_R_LTDPOLIND_MV_SSL" IS
    ''snapshot table for snapshot FCT_GRP_POLICY_R_LTDPOLIND_MV_SSL''');
    execute_immediate_no_raise('GRANT SELECT ON "FCT_GRP_POLICY_R_LTDPOLIND_MV_SSL" TO "ODS_CLAIMS_RO"');
    execute_immediate_no_raise('GRANT SELECT ON "FCT_GRP_POLICY_R_LTDPOLIND_MV_SSL" TO "CLAIMS_RO"');
    execute_immediate_no_raise('GRANT SELECT ON "FCT_GRP_POLICY_R_LTDPOLIND_MV_SSL" TO "ATOMIC_ALL_RO"');
    execute_immediate_no_raise('GRANT SELECT ON "FCT_GRP_POLICY_R_LTDPOLIND_MV_SSL" TO "ATOMIC_DEBUG"');
    execute_immediate_no_raise('GRANT SELECT ON "FCT_GRP_POLICY_R_LTDPOLIND_MV_SSL" TO "205CJX"');
    pkg_log_error_utility.log_messages_insert(
                                             p_batch_key          => gn_sysdt_batchid,
                                             p_location           => 'prc_drop_create_fct_grp_policy_r_ltdpolind_mv_ssl.9',
                                             p_message            => 'Create snapshots and grants for FCT_GRP_POLICY_R_LTDPOLIND_MV_SSL ended',
                                             p_additional_message => '',
                                             p_insert_by          => 'prc_drop_create_fct_grp_policy_r_ltdpolind_mv_ssl'
    );

    pkg_log_error_utility.log_messages_insert(
                                             p_batch_key          => gn_sysdt_batchid,
                                             p_location           => 'prc_drop_create_fct_grp_policy_r_ltdpolind_mv_ssl.10',
                                             p_message            => 'prc_drop_create_fct_grp_policy_r_ltdpolind_mv_ssl ended',
                                             p_additional_message => '',
                                             p_insert_by          => 'prc_drop_create_fct_grp_policy_r_ltdpolind_mv_ssl'
    );

    pkg_grp_log_util.prc_update_log(
                                   gn_out_job_id                   --p_job_id
                                   ,
                                   gc_success_status              --p_job_status
                                   ,
                                   gc_errmsg                      --p_err_msg
                                   ,
                                   'prc_drop_create_fct_grp_policy_r_ltdpolind_mv_ssl ended'                      --p_trc_msg
                                   ,
                                   'prc_drop_create_fct_grp_policy_r_ltdpolind_mv_ssl'               --p_log_util_called_by_r
    );
EXCEPTION
    WHEN OTHERS THEN
        pkg_log_error_utility.log_messages_insert(
                                                 p_batch_key          => gn_sysdt_batchid,
                                                 p_type               => pkg_log_error_utility.status_failed,
                                                 p_location           => 'prc_drop_create_fct_grp_policy_r_ltdpolind_mv_ssl.11',
                                                 p_message            => substr(
                                                     'Error in prc_drop_create_fct_grp_policy_r_ltdpolind_mv_ssl:  '
                                                     || CHR(13)
                                                     || sqlerrm, 1, 4000
                                                 ),
                                                 p_additional_message => substr(
                                                     'Error in prc_drop_create_fct_grp_policy_r_ltdpolind_mv_ssl'
                                                     || CHR(13)
                                                     || sqlerrm, 4001, 4000
                                                 ),
                                                 p_insert_by          => 'prc_drop_create_fct_grp_policy_r_ltdpolind_mv_ssl'
        ); --20250211 Logging JC:  Added logging
        pkg_grp_log_util.prc_update_log(
                                       gn_out_job_id                   --p_job_id
                                       ,
                                       gc_error_status                --p_job_status
                                       ,
                                       substr(
                                             'Error in prc_drop_create_fct_grp_policy_r_ltdpolind_mv_ssl:  '
                                             || chr(13)
                                             || sqlerrm,
                                             1,
                                             4000
                                       )                       --p_err_msg
                                       ,
                                       substr(
                                             'Error in prc_drop_create_fct_grp_policy_r_ltdpolind_mv_ssl:  '
                                             || chr(13)
                                             || sqlerrm,
                                             1,
                                             4000
                                       ),
                                       'prc_drop_create_fct_grp_policy_r_ltdpolind_mv_ssl'               --p_log_util_called_by_r
        );

        RAISE;
END prc_drop_create_fct_grp_policy_r_ltdpolind_mv_ssl;
