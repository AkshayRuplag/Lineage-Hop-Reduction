-- Cleaned for lineage: DIM_GRP_CLAIM_DETAIL_R_VW

CREATE VIEW DIM_GRP_CLAIM_DETAIL_R_VW (N_CLAIM_SK_R, V_CLAIM_STATUS_REASON_CODE_R, V_REASON_CODE_R, T_EVENT_TIMESTAMP_R_1, T_EVENT_TIMESTAMP_R_2, V_REASON_FLAG_R, V_CLAIM_NUMBER_R, N_CLAIM_COVERAGE_SK_R, N_CLAIM_COVERAGE_GROUP_SK_R, V_CLAIM_IDENTIFIER_R, V_CLAIM_COVERAGE_CODE_R, N_POLICY_SK_R) AS
SELECT
		
        a.n_claim_sk_r,
		
        
		(CASE WHEN (C.V_LOB_TYPE_R IN ('VPS', 'STD', 'VPL', 'LTD') OR C.V_SOURCE_SYSTEM_NAME_R = 'CV') THEN
		 a.v_claim_status_reason_code_r
		ELSE ''
		END) v_claim_status_reason_code_r,
		
        b.v_reason_code_r, 
        b.t_event_timestamp_r             t_event_timestamp_r_1,
        a.t_event_timestamp_r             t_event_timestamp_r_2,
        CAST(NULL AS VARCHAR2(20))        v_reason_flag_r,
        a.v_claim_number_r,
        b.n_claim_coverage_sk_r,
        b.n_claim_coverage_group_sk_r,
        b.v_claim_identifier_r,
        b.v_claim_coverage_code_r 
        ,
        (
            SELECT
                n_policy_sk_r
            FROM
                dim_grp_claim_dir_r a2
            WHERE
                    a2.n_claim_sk_r = a.n_claim_sk_r
                AND a2.v_active_status_r = 'Y'
            GROUP BY
                a2.n_policy_sk_r
        )                                 n_policy_sk_r
    
    
    
    
    
    
    
    
    
    
    
    FROM
        ATOMIC.dim_grp_claim_dir_r c 
		join (select * from ATOMIC.dim_grp_claim_detail_r where 
        (v_policy_prefix_r NOT IN ('ASL') or v_policy_prefix_r is null) and n_claim_sk_r > -1 and v_active_status_r = 'Y') a
        on a.n_claim_sk_r = c.n_claim_sk_r
		and a.n_claim_sk_r > -1
		AND c.v_active_status_r = 'Y'
		and a.v_active_status_r = 'Y'
		and c.v_active_status_r = 'Y'
        LEFT JOIN ATOMIC.dim_grp_claim_coverage_group_r  b ON a.n_claim_sk_r = b.n_claim_sk_r
													AND b.v_claim_number_r = c.v_claim_number_r
                                                    AND b.v_active_status_r = 'Y'
													
													AND NOT (a.v_claim_status_reason_code_r in ('91', '92') and b.v_reason_code_r = '22')

    WHERE
        b.t_event_timestamp_r = (
            SELECT
                MAX(c.t_event_timestamp_r)
            FROM
                ATOMIC.dim_grp_claim_coverage_group_r c
            WHERE
                b.v_claim_identifier_r = c.v_claim_identifier_r
        )
		
        
		AND  EXISTS (SELECT 1
		                  FROM ATOMIC.dim_grp_claim_dir_r d
						  WHERE d.v_active_status_r = 'Y'
                            AND d.v_lob_type_r <> 'ANNUITY'
						    AND d.n_claim_sk_r=a.n_claim_sk_r
						)
		
		
		
    GROUP BY
        A.N_CLAIM_SK_R,
        
       
       (CASE WHEN (C.V_LOB_TYPE_R IN ('VPS', 'STD', 'VPL', 'LTD') OR C.V_SOURCE_SYSTEM_NAME_R = 'CV') THEN
		 a.v_claim_status_reason_code_r
		ELSE ''
		END),
    
        b.v_reason_code_r,
        b.t_event_timestamp_r,
        a.t_event_timestamp_r,
        a.v_claim_number_r,
        b.n_claim_coverage_sk_r,
        b.n_claim_coverage_group_sk_r,
        B.V_CLAIM_IDENTIFIER_R,
        b.v_claim_coverage_code_r;