-- Cleaned for lineage: CLAIM_TIER_WFAM_MV

INSERT
				INTO FCT_PROC_EXEC_STATUS_LOG_R
					(
					N_BATCH_ID_R,
					N_MIS_DATE_SKEY_R,
					N_LOAD_RUN_ID_R,
					V_STATUS_R,
					T_EXECUTION_TIMESTAMP_R,
					V_USER_R,
					V_PLSQL_BLOCK_NAME_R,
					N_SERIAL_NUM_R
					)
					VALUES
					(
					LN_BATCH_ID_R,
					TO_CHAR(sysdate,'yyyymmdd'),
					1,
					'Started',
					SYSTIMESTAMP,
					USER,
					P_MV_TBL_NAME||'.PROC_REFRESH_GRP_M_VIEW_TBLS.CLAIM_TIER_WFAM_MV_TBL',
					N_MAX_SERIAL_NUM_R
					);

INSERT  INTO  CLAIM_TIER_WFAM_MV_TBL
	(v_tier_r,
	 v_wfam_r,
	 d_prd_r,
     n_claim_sk_r,
     v_claim_number_r,
     d_created_date_r_tier,
     d_created_date_r_wfam,
	 d_created_date_r_prd,
     rank_tier,
     rank_wfam,
	 rank_prd
	)
	WITH claim_note_tier_v AS (
        SELECT DISTINCT
            *
        FROM
            (
                SELECT
                    f.v_tier_r,
                    f.n_claim_sk_r,
                    f.d_created_date_r,
                    RANK()
                    OVER(PARTITION BY f.n_claim_sk_r
                         ORDER BY f.d_created_date_r DESC,
                                  f.v_created_time_r DESC,
                                  f.n_claim_subsequence_number_r DESC
                    ) rank
                FROM
                    fct_grp_claim_note_r f
                WHERE
                        f.n_claim_sk_r > - 1
                    AND f.v_tier_r IS NOT NULL
            )
        WHERE
            rank = 1
    ), claim_note_wfam_v AS (
        SELECT DISTINCT
            *
        FROM
            (
                SELECT
                    f.v_wfam_r,
                    f.n_claim_sk_r,
                    f.d_created_date_r,
                    RANK()
                    OVER(PARTITION BY f.n_claim_sk_r
                         ORDER BY f.d_created_date_r DESC,
                                  f.v_created_time_r DESC,
                                  f.n_claim_subsequence_number_r DESC
								  ,f.T_EVENT_TIMESTAMP_R desc
                    ) rank
                FROM
                    fct_grp_claim_note_r f
                WHERE
                        f.n_claim_sk_r > - 1
                    AND f.v_wfam_r IS NOT NULL
            )
        WHERE
            rank = 1
    ),CLAIM_NOTE_PRD_V as
(select distinct * from(
select f.D_PRD_R,f.n_claim_sk_r,f.D_CREATED_DATE_R,RANK() OVER (PARTITION BY f.N_CLAIM_SK_R
                                                          ORDER BY f.D_CREATED_DATE_R DESC,f.V_CREATED_TIME_R DESC, f.N_CLAIM_SUBSEQUENCE_NUMBER_R DESC ,
														  f.N_CREATED_ITIME_R DESC)
														  rank from FCT_GRP_CLAIM_NOTE_R F where F.N_CLAIM_SK_R >-1
                                                          and f.d_prd_r is not null
														   )
                                                          where RANK = 1
)
    SELECT
        a.v_tier_r,
        b.v_wfam_r,
		c.d_prd_r,
        dim.n_claim_sk_r,
        dim.v_claim_number_r,
        a.d_created_date_r    AS d_created_date_r_tier,
        b.d_created_date_r    AS d_created_date_r_wfam,
		c.d_created_date_r    as d_created_date_r_prd,
        a.rank                AS rank_tier,
        b.rank                AS rank_wfam,
		c.rank                as rank_prd
    FROM
        dim_grp_claim_dir_r  dim
        LEFT OUTER JOIN claim_note_tier_v    a ON dim.n_claim_sk_r = a.n_claim_sk_r
        LEFT OUTER JOIN claim_note_wfam_v    b ON dim.n_claim_sk_r = b.n_claim_sk_r
		LEFT OUTER JOIN claim_note_prd_v     c on dim.n_claim_sk_r = c.n_claim_sk_r	
    WHERE
            dim.v_active_status_r = 'Y'
        AND ( v_tier_r IS NOT NULL
              OR v_wfam_r IS NOT NULL or d_prd_r is not null );

UPDATE FCT_PROC_EXEC_STATUS_LOG_R
							SET V_STATUS_R                = 'Successful',
							T_EXECUTION_END_TIMESTAMP_R = systimestamp
							WHERE N_SERIAL_NUM_R          = N_MAX_SERIAL_NUM_R;