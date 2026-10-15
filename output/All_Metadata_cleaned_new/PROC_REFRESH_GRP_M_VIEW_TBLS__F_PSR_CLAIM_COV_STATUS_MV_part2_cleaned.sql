-- Cleaned for lineage: PROC_REFRESH_GRP_M_VIEW_TBLS__F_PSR_CLAIM_COV_STATUS_MV (part 2/3)

INSERT
			INTO F_PSR_CLAIM_COV_STATUS_MV_TBL
			  (
				POLICY_SKEY                                   ,
                CLAIM_SKEY                                    ,
                AS_OF_DATE                                    ,
                COVERAGE_TYPE                                 ,
                PRODUCT_COVERAGE_CODE                         ,
                COVERAGE_TYPE_CODE                            ,
                COVERAGE_TYPE_DESCRIPTION                     ,
                EXAMINER_DEPARTMENT_CODE                      ,
                EXAMINER_LOGIN_ID                             ,
                EXAMINER_NAME                                 ,
                VOCATIONAL_REHAB_ACTIVE_STATUS                ,
                VOCATIONAL_REHAB_OUTCOME                      ,
                VOCATIONAL_REHAB_SERVICE_REQUESTED_OTHER      ,
                VOCATIONAL_REHAB_SERVICE_REQUESTED            ,
                CLAIM_IDENTIFER                               ,
                DISABILITY_START_DATE                         ,
                ANY_OCC_DECISION_MADE_DATE                    ,
                ANY_OCC_PERIOD_INDICATOR                      ,
                OWN_OCC_PERIOD                                ,
                ANY_OCC_START_DATE                            ,
                CLAIM_COVERAGE_DESCRIPTION                    ,
                COVERAGE_GROUP_CODE                           ,
                CLAIM_STATUS_CATEGORY                         ,
                CLAIM_STATUS_DESCRIPTION                      ,
                CLAIM_STATUS_EFFECTIVE_DATE                   ,
                CLAIM_TYPE                                    ,
                CLAIM_STATUS_CODE                             ,
                PRIOR_STATUS_CODE                             ,
                D_LAST_IN_STATUS_46_DATE_R
				,DIRECTOR_FULL_NAME 
				,SUPERVISOR_FULL_NAME
                ,DIRECTOR_LOGIN_ID
                ,SUPERVISOR_LOGIN_ID 
				,NURSE_CERT_OWN_OCC
				,NURSE_CERT_END_DATE
				,NURSE_CERT_FLAG
				,N_PRODUCT_SK_R              
				,V_BASIC_PRODUCT_LINE_CODE_R 
				,V_BASIC_PRODUCT_LINE_DESC_R 
			  )
		    SELECT
              DISTINCT T333136.n_policy_sk_r                    AS Policy_skey,
              T333511.n_claim_sk_r                              AS Claim_skey,
              (
                  SELECT
                      MAX(fic_mis_date_r)
                  FROM
                      dim_grp_policy_dir_r
                  WHERE
                      v_source_system_name_r = 'PACS'
              )      AS As_Of_Date,
              max(CASE
                WHEN T393779.V_COVERAGE_TYPE_CODE_R = '1'
                THEN 'LTD'
                WHEN T393779.V_COVERAGE_TYPE_CODE_R = '2'
                THEN 'STD'
                WHEN T393779.V_COVERAGE_TYPE_CODE_R IN ('1', '2')
                THEN 'Disability (LTD )'
                WHEN T438103.V_COVERAGE_TYPE_CODE_R = '3'
                THEN 'Life'
                WHEN T438103.V_COVERAGE_CATEGORY_R = 'Life - Annuity'
                AND T438103.V_COVERAGE_TYPE_CODE_R = '3'
                THEN 'Life - Annuity'
                WHEN T438103.V_COVERAGE_CATEGORY_R = 'Life - Non-Annuity'
                AND T438103.V_COVERAGE_TYPE_CODE_R = '3'
                THEN 'Life - Non-Annuity'
                WHEN T438103.V_COVERAGE_TYPE_CODE_R = '3'
                AND NOT (T438103.V_COVERAGE_CODE_R LIKE '%WP%'
                OR T438103.V_COVERAGE_CODE_R LIKE 'GAN%'
                OR T438103.V_COVERAGE_CODE_R LIKE 'CD%')
                THEN 'Group Life'
              END             )               AS Coverage_type,
             max( NVL(T393779.V_COVERAGE_CODE_R,T438103.V_COVERAGE_CODE_R)  )    AS Product_Coverage_code,
             max(NVL(T393779.V_COVERAGE_TYPE_CODE_R,T438103.V_COVERAGE_TYPE_CODE_R)) AS Coverage_Type_Code,
             max( NVL(T393779.V_COVERAGE_TYPE_DESC_R,T438103.V_COVERAGE_TYPE_DESC_R) ) AS Coverage_Type_Description,
              CASE
                WHEN SUBSTR(T333447.V_EXAMINER_LOGIN_ID_R , 1 , 1) = 'T'
                THEN SUBSTR(T333447.V_EXAMINER_LOGIN_ID_R , 2 , 3)
                ELSE SUBSTR(T333447.V_EXAMINER_LOGIN_ID_R , 1 , 3)
              END                           AS Examiner_Department_code,
              T333447.V_EXAMINER_LOGIN_ID_R AS Examiner_Login_Id,
              T333447.v_examiner_desc_r                              AS Examiner_Name,
              T394101.V_REHAB_STATUS_R            AS Vocational_Rehab_Active_Status,
              T394101.V_VOC_REHAB_OUTCOME_R       AS Vocational_Rehab_Outcome,
              T394101.V_SERVICE_REQUESTED_OTHER_R AS Vocational_Rehab_Service_Requested_Other,
              T394101.V_SERVICE_REQUESTED_R       AS Vocational_Rehab_Service_Requested,
              nvl(T357774.v_claiM_identifier_r,T333511.v_claim_number_r) AS Claim_Identifer,
              CASE
                WHEN T333136.V_ORIG_LOB_R = 'VAI'
                THEN T333526.D_DATE_OF_EVENT_R +
                  CASE
                    WHEN T357771.N_ELIM_PERIOD_R <> ''
                    OR T357771.N_ELIM_PERIOD_R   <> 0
                    THEN T357771.N_ELIM_PERIOD_R
                    ELSE 0
                  END
              END                     AS Disability_Start_Date,
              T357771.D_ANYOCC_DATE_R AS Any_Occ_Decision_Made_Date,
              CASE
                WHEN T357771.V_OWN_OCC_PERIOD_R LIKE '%MOS'
                THEN 'M'
                ELSE
                  CASE
                    WHEN T357771.V_OWN_OCC_PERIOD_R LIKE '@%'
                    THEN 'A'
                  END
              END AS Any_Occ_Period_Indicator,
              CASE
                WHEN upper(T357771.V_OWN_OCC_PERIOD_R) LIKE '%MOS'
                THEN SUBSTR(T357771.V_OWN_OCC_PERIOD_R , 1 , 2)
                ELSE
                  CASE
                    WHEN T357771.V_OWN_OCC_PERIOD_R LIKE '@%'
                    THEN SUBSTR(T357771.V_OWN_OCC_PERIOD_R , 2 , 2)
                  END
              END                           AS Own_Occ_Period,
              T357771.D_ANYOCC_START_DATE_R AS Any_Occ_Start_Date,
	    	  max(NVL(T393779.V_COVERAGE_DESC_R,T438103.V_COVERAGE_DESC_R)) AS Claim_Coverage_Description,
              T357774.N_COV_GRP_ID_R        AS Coverage_Group_Code,
              max(CASE
                WHEN T333511.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP')
                THEN
                  CASE
                    WHEN T357774.V_REASON_CODE_R >= '60'
                    THEN 'CLOSED'
                    WHEN T357774.V_REASON_CODE_R < '60'
                    AND T357774.V_REASON_CODE_R >= '50'
                    THEN 'RESISTING'
                    WHEN T357774.V_REASON_CODE_R < '50'
                    AND T357774.V_REASON_CODE_R >= '40'
                    THEN 'OPEN, NO LIABILITIES'
                    WHEN T357774.V_REASON_CODE_R < '40'
                    AND T357774.V_REASON_CODE_R >= '30'
                    THEN 'ACTIVE'
                    WHEN T357774.V_REASON_CODE_R < '30'
                    THEN 'OPEN INCOMPLETE'
                    ELSE NULL
                  END
                WHEN T333511.V_LOB_TYPE_R IN ('LTD', 'STD', 'VPL', 'VPS')
                THEN
                  CASE
                    WHEN T333447.V_CLAIM_STATUS_REASON_CODE_R >= '60'
                    THEN 'CLOSED'
                    WHEN T333447.V_CLAIM_STATUS_REASON_CODE_R < '60'
                    AND T333447.V_CLAIM_STATUS_REASON_CODE_R >= '50'
                    THEN 'RESISTING'
                    WHEN T333447.V_CLAIM_STATUS_REASON_CODE_R < '50'
                    AND T333447.V_CLAIM_STATUS_REASON_CODE_R >= '40'
                    THEN 'OPEN, NO LIABILITIES'
                    WHEN T333447.V_CLAIM_STATUS_REASON_CODE_R < '40'
                    AND T333447.V_CLAIM_STATUS_REASON_CODE_R >= '30'
                    THEN 'ACTIVE'
                    WHEN T333447.V_CLAIM_STATUS_REASON_CODE_R < '30'
                    THEN 'OPEN INCOMPLETE'
                    ELSE NULL
                  END
                ELSE NULL
              END ) AS Claim_Status_Category,
              max(CASE
                WHEN T333511.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP')
                THEN T390719.V_CLAIM_STATUS_DESC_R
                WHEN T333511.V_LOB_TYPE_R IN ('LTD', 'STD', 'VPL', 'VPS')
                THEN T389767.V_CLAIM_STATUS_DESC_R
                ELSE NULL
              END) AS Claim_Status_Description,
              max(CASE
                WHEN T333511.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP')
                THEN trunc(T426281.D_CLAIM_STATUS_CODE_EFF_DATE_R)
                WHEN T333511.V_LOB_TYPE_R IN ('LTD', 'STD', 'VPL', 'VPS')
                THEN trunc(T424641.D_CLAIM_STATUS_CODE_EFF_DATE_R)
                ELSE NULL
              END ) AS Claim_Status_Effective_Date,
             max( CASE
                WHEN T333511.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP')
                THEN
                  CASE
                    WHEN T426281.V_CURR_CLAIM_STATUS_CODE_R >= '60'
                    THEN 'Closed (60 or greater)'
                    WHEN T426281.V_CURR_CLAIM_STATUS_CODE_R BETWEEN '50' AND '59'
                    THEN 'Resisting (51)'
                    WHEN T426281.V_CURR_CLAIM_STATUS_CODE_R BETWEEN '30' AND '49'
                    THEN 'Open, excl. Incomplete (30-49)'
                    WHEN T426281.V_CURR_CLAIM_STATUS_CODE_R BETWEEN '20' AND '29'
                    THEN 'Open, Incomplete (e.g., 22)'
                    WHEN T426281.V_CURR_CLAIM_STATUS_CODE_R < '60'
                    THEN 'All Open (<60)'
                    WHEN T426281.V_CURR_CLAIM_STATUS_CODE_R = '32'
                    AND T438103.V_COVERAGE_TYPE_CODE_R      = '3'
                    OR T426281.V_CURR_CLAIM_STATUS_CODE_R   = '46'
                    AND T438103.V_COVERAGE_TYPE_CODE_R     IN ('1', '2')
                    THEN 'Pending (32 for Life, 46 for Disability)'
                    WHEN T426281.V_CURR_CLAIM_STATUS_CODE_R BETWEEN '20' AND '32'
                    OR T426281.V_CURR_CLAIM_STATUS_CODE_R BETWEEN '35' AND '50'
                    THEN 'Open, excl. 33, 34, 51'
                  END
                WHEN T333511.V_LOB_TYPE_R IN ('LTD', 'STD', 'VPL', 'VPS')
                THEN
                  CASE
                    WHEN T424641.V_CURR_CLAIM_STATUS_CODE_R >= '60'
                    THEN 'Closed (60 or greater)'
                    WHEN T424641.V_CURR_CLAIM_STATUS_CODE_R BETWEEN '50' AND '59'
                    THEN 'Resisting (51)'
                    WHEN T424641.V_CURR_CLAIM_STATUS_CODE_R BETWEEN '30' AND '49'
                    THEN 'Open, excl. Incomplete (30-49)'
                    WHEN T424641.V_CURR_CLAIM_STATUS_CODE_R BETWEEN '20' AND '29'
                    THEN 'Open, Incomplete (e.g., 22)'
                    WHEN T424641.V_CURR_CLAIM_STATUS_CODE_R < '60'
                    THEN 'All Open (<60)'
                    WHEN T424641.V_CURR_CLAIM_STATUS_CODE_R = '32'
                    AND T393779.V_COVERAGE_TYPE_CODE_R      = '3'
                    OR T424641.V_CURR_CLAIM_STATUS_CODE_R   = '46'
                    AND (T393779.V_COVERAGE_TYPE_CODE_R    IN ('1', '2'))
                    THEN 'Pending (32 for Life, 46 for Disability)'
                    WHEN T424641.V_CURR_CLAIM_STATUS_CODE_R BETWEEN '20' AND '32'
                    OR T424641.V_CURR_CLAIM_STATUS_CODE_R BETWEEN '35' AND '50'
                    THEN 'Open, excl. 33, 34, 51'
                  END
                ELSE NULL
              END ) AS Claim_Type,
             max( CASE
                WHEN T333511.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP')
				 AND T333511.v_source_system_name_r = 'PACS'
                THEN T426281.V_CURR_CLAIM_STATUS_CODE_R
                WHEN T333511.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP') and T333511.v_source_system_name_r = 'CV'
                THEN T357774.V_REASON_CODE_R
                WHEN T333511.V_LOB_TYPE_R IN ('LTD', 'STD', 'VPL', 'VPS')
                THEN T424641.V_CURR_CLAIM_STATUS_CODE_R
                ELSE NULL
              END ) AS Claim_Status_Code,
            max(  CASE
                WHEN T333511.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP')
                THEN T426281.V_PRIOR_CLAIM_STATUS_CODE_R
                WHEN T333511.V_LOB_TYPE_R IN ('LTD', 'STD', 'VPL', 'VPS')
                THEN T424641.V_PRIOR_CLAIM_STATUS_CODE_R
                ELSE NULL
              END )AS Prior_status_Code
            ,
             max(  CASE
                WHEN T333511.V_LOB_TYPE_R IN ('LIFE', 'NONS', 'WOP')
                THEN T426281.D_LAST_IN_STATUS_46_DATE_R
                WHEN T333511.V_LOB_TYPE_R IN ('LTD', 'STD', 'VPL', 'VPS')
                THEN T424641.D_LAST_IN_STATUS_46_DATE_R
                ELSE NULL
              END )AS D_LAST_IN_STATUS_46_DATE_R
	    	,T391089.V_DIRECTOR_FULL_NAME_R
	    	,T391089.V_SUPERVISOR_FULL_NAME_R
	    	,T391089.V_DIRECTOR_LOGIN_ID_R
	    	,T391089.V_SUPERVISOR_LOGIN_ID_R
          	,CASE
               WHEN T527283.D_NURSE_CERT_END_DATE_R > T357771.D_ANYOCC_START_DATE_R
               THEN 'Y'
               ELSE 'N'
             END AS NURSE_CERT_OWN_OCC
	    	,T527283.D_NURSE_CERT_END_DATE_R
	    	,CASE
               WHEN NVL(T527283.D_NURSE_CERT_END_DATE_R,sysdate) <= sysdate
               THEN 'x'
               ELSE NULL
             END AS NURSE_CERT_FLAG
			,MAX(NVL(T393779.N_PRODUCT_SK_R,T438103.N_PRODUCT_SK_R))                           N_PRODUCT_SK_R              
			,MAX(NVL(T393779.V_BASIC_PRODUCT_LINE_CODE_R,T438103.V_BASIC_PRODUCT_LINE_CODE_R)) V_BASIC_PRODUCT_LINE_CODE_R 
			,MAX(NVL(T393779.V_BASIC_PRODUCT_LINE_DESC_R,T438103.V_BASIC_PRODUCT_LINE_DESC_R)) V_BASIC_PRODUCT_LINE_DESC_R 
        FROM DIM_GRP_POLICY_DIR_R T333136
        INNER JOIN DIM_GRP_CLAIM_DIR_R T333511
        ON T333136.N_POLICY_SK_R      = T333511.N_POLICY_SK_R
        AND T333511.V_ACTIVE_STATUS_R = 'Y'
        inner JOIN DIM_GRP_CLAIM_DETAIL_R T333447
        ON T333447.N_CLAIM_SK_R       = T333511.N_CLAIM_SK_R
        AND T333447.V_ACTIVE_STATUS_R = 'Y'
         LEFT OUTER JOIN
           (SELECT *
           FROM dim_grp_nurse_cert_r c
           WHERE v_active_status_r = 'Y'
           AND N_NURSE_CERT_SEQ_R  =
             (SELECT MAX(N_NURSE_CERT_SEQ_R)
             FROM dim_grp_nurse_cert_r
             WHERE n_claim_sk_r    = c.n_claim_sk_r
             AND v_active_status_r = 'Y'
             )
           ) T527283
         ON T527283.N_CLAIM_SK_R = T333511.N_CLAIM_SK_R
        LEFT OUTER JOIN DIM_CLAIM_STATUS_R T389767
        ON T333447.V_CLAIM_STATUS_REASON_CODE_R = T389767.V_CLAIM_STATUS_CODE_R
        AND T389767.V_ACTIVE_STATUS_R           = 'Y'
        LEFT OUTER JOIN DIM_GRP_CLAIM_EVENT_R T333541
        ON T333447.N_CLAIM_EVENT_SK_R = T333541.N_CLAIM_EVENT_SK_R
        AND T333541.V_ACTIVE_STATUS_R = 'Y'
        LEFT OUTER JOIN DIM_GRP_CLAIM_EVENT_DIR_R T333526
        ON T333526.N_CLAIM_EVENT_SK_R = T333541.N_CLAIM_EVENT_SK_R
        AND T333526.V_ACTIVE_STATUS_R = 'Y'
        LEFT OUTER JOIN DIM_GRP_CLAIM_COVERAGE_R T357788
        ON T333447.N_CLAIM_SK_R       = T357788.N_CLAIM_SK_R
        AND T357788.V_ACTIVE_STATUS_R='Y'
                LEFT OUTER JOIN DIM_GRP_CLAIM_ELIGIBILITY_R T357771
        oN T357771.n_claim_coverage_sk_r = CASE
                                                WHEN
                                                T357771.n_claim_coverage_sk_r <> - 1
                                                THEN
                                                   T357788.n_claim_coverage_sk_r
                                                      ELSE
                                                      - 1
                                                    END
        AND T357771.n_claim_sk_r = T357788.n_claim_sk_r
        and T357771.v_active_status_r = 'Y'
        LEFT OUTER JOIN MVW_PRODUCT_SK_LOOKUP_TBL T439745
        ON T357788.N_CLAIM_SK_R             = T439745.N_CLAIM_SK_R
        AND T357788.V_CLAIM_COVERAGE_CODE_R = T439745.V_CLAIM_COVERAGE_CODE_R
        LEFT OUTER JOIN DIM_GRP_PRODUCT_R T393779
        ON T393779.N_PRODUCT_SK_R     = T439745.N_PRODUCT_SK_R
        AND T393779.V_ACTIVE_STATUS_R = 'Y'
       LEFT OUTER JOIN VW_DIM_GRP_CLAIM_PRIOR_STATUS_R_max T424641
        ON T357788.V_CLAIM_COVERAGE_CODE_R = T424641.V_COVERAGE_CODE_R
        AND T357788.V_CLAIM_NUMBER_R       = T424641.V_CLAIM_NUMBER_R
        and T357788.N_CLAIM_COVERAGE_SK_R = T424641.N_CLAIM_COVERAGE_SK_R
        LEFT OUTER JOIN DIM_GRP_CLAIM_COVERAGE_GROUP_R T357774
        ON T357774.N_CLAIM_COVERAGE_SK_R = T357788.N_CLAIM_COVERAGE_SK_R
        AND T357774.V_ACTIVE_STATUS_R    = 'Y'
        LEFT OUTER JOIN DIM_CLAIM_STATUS_R T390719
        ON T357774.V_REASON_CODE_R    = T390719.V_CLAIM_STATUS_CODE_R
        AND T390719.V_ACTIVE_STATUS_R = 'Y'
        LEFT OUTER JOIN VW_DIM_GRP_CLAIM_PRIOR_STATUS_R T426281  
        ON 
        T357774.N_CLAIM_SK_R = T426281.N_CLAIM_SK_R
        AND T357774.N_CLAIM_COVERAGE_SK_R = T426281.N_CLAIM_COVERAGE_SK_R
        AND T357774.N_CLAIM_COVERAGE_GROUP_SK_R = T426281.N_CLAIM_COVERAGE_GROUP_SK_R
        LEFT OUTER JOIN MVW_PRODUCT_SK_LOOKUP_TBL T439747
        ON T357774.N_CLAIM_SK_R             = T439747.N_CLAIM_SK_R
        AND T357774.V_CLAIM_COVERAGE_CODE_R = T439747.V_CLAIM_COVERAGE_CODE_R
        LEFT OUTER JOIN DIM_GRP_PRODUCT_R T438103
        ON T438103.N_PRODUCT_SK_R     = T439747.N_PRODUCT_SK_R
        AND T438103.V_ACTIVE_STATUS_R = 'Y'
        LEFT OUTER JOIN DIM_EMPLOYEE_R T391089
        ON T333447.V_EXAMINER_LOGIN_ID_R     = T391089.V_EMPLOYEE_LOGIN_ID_R
        AND upper(T391089.V_BUSINESS_UNIT_R) = 'CLAIMS'
        LEFT OUTER JOIN DIM_GRP_VOCREHAB_R T394101
        ON T333447.N_CLAIM_SK_R       = T394101.N_CLAIM_SK_R
        AND T394101.V_ACTIVE_STATUS_R = 'Y'
        WHERE (
          T333136.V_ACTIVE_STATUS_R = 'Y'
          )
        group by
        T333136.n_policy_sk_r                    ,
          T333511.n_claim_sk_r                ,
        CASE
            WHEN SUBSTR(T333447.V_EXAMINER_LOGIN_ID_R , 1 , 1) = 'T'
            THEN SUBSTR(T333447.V_EXAMINER_LOGIN_ID_R , 2 , 3)
            ELSE SUBSTR(T333447.V_EXAMINER_LOGIN_ID_R , 1 , 3)
          END                           ,
          T333447.V_EXAMINER_LOGIN_ID_R ,
          T333447.v_examiner_desc_r                             ,
          T394101.V_REHAB_STATUS_R           ,
          T394101.V_VOC_REHAB_OUTCOME_R       ,
          T394101.V_SERVICE_REQUESTED_OTHER_R ,
          T394101.V_SERVICE_REQUESTED_R       ,
          nvl(T357774.v_claiM_identifier_r,T333511.v_claim_number_r) ,
          CASE
            WHEN T333136.V_ORIG_LOB_R = 'VAI'
            THEN T333526.D_DATE_OF_EVENT_R +
              CASE
                WHEN T357771.N_ELIM_PERIOD_R <> ''
                OR T357771.N_ELIM_PERIOD_R   <> 0
                THEN T357771.N_ELIM_PERIOD_R
                ELSE 0
              END
          END                    ,
          T357771.D_ANYOCC_DATE_R ,
          CASE
            WHEN T357771.V_OWN_OCC_PERIOD_R LIKE '%MOS'
            THEN 'M'
            ELSE
              CASE
                WHEN T357771.V_OWN_OCC_PERIOD_R LIKE '@%'
                THEN 'A'
              END
          END ,
          CASE
            WHEN upper(T357771.V_OWN_OCC_PERIOD_R) LIKE '%MOS'
            THEN SUBSTR(T357771.V_OWN_OCC_PERIOD_R , 1 , 2)
            ELSE
              CASE
                WHEN T357771.V_OWN_OCC_PERIOD_R LIKE '@%'
                THEN SUBSTR(T357771.V_OWN_OCC_PERIOD_R , 2 , 2)
              END
          END                       ,
          T357771.D_ANYOCC_START_DATE_R ,
          T357774.N_COV_GRP_ID_R
		,T391089.V_DIRECTOR_FULL_NAME_R
		,T391089.V_SUPERVISOR_FULL_NAME_R
		,T391089.V_DIRECTOR_LOGIN_ID_R
		,T391089.V_SUPERVISOR_LOGIN_ID_R
      	,CASE
           WHEN T527283.D_NURSE_CERT_END_DATE_R > T357771.D_ANYOCC_START_DATE_R
           THEN 'Y'
           ELSE 'N'
         END
		,T527283.D_NURSE_CERT_END_DATE_R
		,CASE
           WHEN NVL(T527283.D_NURSE_CERT_END_DATE_R,sysdate) <= sysdate
           THEN 'x'
           ELSE NULL
         END;