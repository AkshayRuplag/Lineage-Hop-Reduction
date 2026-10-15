-- Cleaned for lineage: PKG_GRP_LOAD_RPT_POLICY_DTL_R_PRC_LOAD_DATA_DIM_GTT

INSERT 
      INTO DIM_PLAN_DESIGN_DIRECTORY_R_GTT TGT
        SELECT T4804933.N_PLAN_DESIGN_SK_R
             , T4804933.V_COVERAGE_CODE_R
             , T4804933.N_POLICY_SK_R
          FROM DIM_PLAN_DESIGN_DIRECTORY_R T4804933
         WHERE T4804933.v_active_status_r = 'Y'
           AND T4804933.v_coverage_code_r IN ('IDTHEFT','IDTHEFTEFFDATE','PSINDICATOR','ELIMPERIOD','EAIND', 'EAP'
    			                             ,'BEREAVE','EAP_EFF_DATE','BEREAVEDATE','BENEPERIOD', 'BENEFITDURATION'  
    		                                  )
    		AND EXISTS (SELECT 1
                          FROM DIM_GRP_POLICY_DIR_R T4817886
                         WHERE T4817886.N_POLICY_SK_R = T4804933.N_POLICY_SK_R
                           AND T4804933.N_PLAN_DESIGN_SRC_VERSION_NO_R = T4817886.N_POLICY_VERSION_NUMBER_R
                           AND T4817886.v_active_status_r = 'Y'
                           AND EXISTS (SELECT 1
                                         FROM RPT_POLICY_DTL_R RPT
                                        WHERE RPT.N_POLICY_SK_R = T4817886.N_POLICY_SK_R
                                          AND RPT.N_YEARMONTH_R = gn_current_month
                                    )
    				    );