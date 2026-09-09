-- Cleaned for lineage: PRC_GRP_LOAD_FCT_BILLING_POLICY_SUSPENSE_R_POSTED

INSERT 
  INTO fct_billing_policy_suspense_r_posted
  SELECT *
  FROM fct_billing_policy_suspense_r ps
  WHERE ps.d_delete_date_r IS NOT NULL
  AND NOT EXISTS
    (SELECT 1
    FROM fct_billing_policy_suspense_r_posted b
    WHERE b.N_SRC_SUSPENSE_PREMIUM_ID_R = ps.N_SRC_SUSPENSE_PREMIUM_ID_R
    )
  AND ps.n_amount_r        <> 0
  AND ps.N_SRC_POLICY_ID_R <> 0;