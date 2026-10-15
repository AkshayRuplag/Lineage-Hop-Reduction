-- Cleaned for lineage: FCT_BENEFIT_PAYMENT_R_CLAIM_ACHIND_MV_SSL

CREATE MATERIALIZED VIEW FCT_BENEFIT_PAYMENT_R_CLAIM_ACHIND_MV_SSL AS
SELECT  
        n_claim_sk_r 
        ,max(ACH_INDICATOR) ACH_INDICATOR
		
            FROM
              ( SELECT
              
		     T334051.n_claim_sk_r
             ,  CASE
                  WHEN upper(T334051.V_PAY_METHOD_R) = 'ACH'
                  THEN 'Y'
                  ELSE 'N'
                END AS ACH_indicator
              FROM FCT_BENEFIT_PAYMENT_R T334051
                
              
               
              
              
		group by 
		     T334051.n_claim_sk_r
             ,CASE
                  WHEN upper(T334051.V_PAY_METHOD_R) = 'ACH'
                  THEN 'Y'
                  ELSE 'N'
                END
              )
	GROUP BY N_CLAIM_SK_R;