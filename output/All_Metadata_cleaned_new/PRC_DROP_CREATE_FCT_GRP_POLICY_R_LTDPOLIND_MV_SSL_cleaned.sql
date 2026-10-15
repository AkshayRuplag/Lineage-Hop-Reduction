-- Cleaned for lineage: PRC_DROP_CREATE_FCT_GRP_POLICY_R_LTDPOLIND_MV_SSL

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
			ELSE NULL 
			END
		) ltd_policy_ind
FROM
	atomic.dim_grp_claim_dir_r a,
	atomic.dim_grp_policy_dir_r b,
	atomic.fct_grp_policy_r c,
	atomic.dim_grp_party_r e 
WHERE a.v_active_status_r = ''Y''
	AND a.n_policy_sk_r = b.n_policy_sk_r
	AND b.v_active_status_r = ''Y''
	AND e.v_active_status_r = ''Y''
	AND b.n_policy_version_number_r = c.n_version_number_r
	AND b.n_source_system_key_r = c.n_source_system_key_r 
	AND e.n_party_sk_r = c.n_cust_party_sk_r
	AND b.n_policy_sk_r = c.n_policy_sk_r
	AND v_lob_type_r <> ''ANNUITY''' );