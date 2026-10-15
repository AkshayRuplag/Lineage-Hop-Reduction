-- Cleaned for lineage: PKG_GRP_LOAD_RPT_CLAIM_DTL_R_PRC_UPD_DECISION_COLS

Insert into rpt_claim_dtl_r_claimdec_GTT'||chr(13);

INSERT  INTO rpt_claim_dtl_r_claimdec_GTT
    SELECT  n_claim_sk_r,
            n_claim_coverage_sk_r,
            n_claim_coverage_group_sk_r,
    		d_claim_decision_date_r,
    		d_claim_received_date_r,
    		N_CLAIM_DECISION_DAYS_R,
            CASE
                WHEN d_claim_decision_date_r - d_claim_received_date_r BETWEEN 0 AND 3 THEN '0 - 3'
                WHEN d_claim_decision_date_r - d_claim_received_date_r BETWEEN 4 AND 5 THEN '4 - 5'
                WHEN d_claim_decision_date_r - d_claim_received_date_r BETWEEN 6 AND 7 THEN '6 - 7'
                WHEN d_claim_decision_date_r - d_claim_received_date_r BETWEEN 8 AND 10 THEN '8 - 10'
                WHEN d_claim_decision_date_r - d_claim_received_date_r > 10 THEN '> 10'
                ELSE 'U'
            END AS V_TURNAROUND_RANGE1_R
    FROM (
    SELECT  a.n_claim_sk_r,
            a.n_claim_coverage_sk_r,
            a.n_claim_coverage_group_sk_r,
            b.d_claim_received_date_r,
            MAX(a.d_claim_decision_date_r) d_claim_decision_date_r,
            MAX(a.d_claim_decision_date_r - b.d_claim_received_date_r) AS N_CLAIM_DECISION_DAYS_R
        FROM rpt_fct_rpt_claim_summary_r a,rpt_claim_dtl_r b
        WHERE   b.n_claim_sk_r                = a.n_claim_sk_r
            AND b.n_claim_coverage_sk_r       = a.n_claim_coverage_sk_r
            AND b.n_claim_coverage_group_sk_r = a.n_claim_coverage_group_sk_r
            AND b.n_yearmonth_r               = LN_YEARMONTH_R                      
        group by a.n_claim_sk_r,
            a.n_claim_coverage_sk_r,
            a.n_claim_coverage_group_sk_r,
            b.d_claim_received_date_r
    )
    GROUP BY n_claim_sk_r,
            n_claim_coverage_sk_r,
            n_claim_coverage_group_sk_r,
    		d_claim_decision_date_r,
    		d_claim_received_date_r,
    		N_CLAIM_DECISION_DAYS_R,
            CASE
                WHEN d_claim_decision_date_r - d_claim_received_date_r BETWEEN 0 AND 3 THEN '0 - 3'
                WHEN d_claim_decision_date_r - d_claim_received_date_r BETWEEN 4 AND 5 THEN '4 - 5'
                WHEN d_claim_decision_date_r - d_claim_received_date_r BETWEEN 6 AND 7 THEN '6 - 7'
                WHEN d_claim_decision_date_r - d_claim_received_date_r BETWEEN 8 AND 10 THEN '8 - 10'
                WHEN d_claim_decision_date_r - d_claim_received_date_r > 10 THEN '> 10'
                ELSE 'U'
            END;

-- Lineage: Cursor CUR_UPD_DEC_COLS (target inferred from procedure)
SELECT * FROM rpt_claim_dtl_r_claimdec_GTT;