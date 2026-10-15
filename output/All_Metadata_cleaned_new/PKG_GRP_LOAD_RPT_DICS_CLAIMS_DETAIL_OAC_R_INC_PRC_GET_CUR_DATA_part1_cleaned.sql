-- Cleaned for lineage: PKG_GRP_LOAD_RPT_DICS_CLAIMS_DETAIL_OAC_R_INC_PRC_GET_CUR_DATA (part 1/1)

-- REF CURSOR lineage (OPEN ... FOR SELECT -> INSERT INTO RPT_DICS_CLAIMS_DETAIL_OAC_R_INC)
INSERT INTO RPT_DICS_CLAIMS_DETAIL_OAC_R_INC
SELECT 
        'Claim Department'                                                          AS claims_dept,
        'P. O. Box 8330'                                                            AS claims_dept_addr1,
        'Philadelphia, Pennsylvania  19101-8330'                                    AS claims_dept_addr2,
        t3332256.v_policy_number_r                                                  AS policy_number,
        t3332256.v_policy_number_r
        || '-'
        || t3332275.v_subgroup_id_r                                                  AS policy_subid,
        CASE
            WHEN upper(t3332275.v_correspondent_name_r) LIKE 'ATTN:%' THEN
                t3332275.v_correspondent_name_r
            ELSE
                'Attn:' || t3332275.v_correspondent_name_r
        END                                                                         AS correspondent_name,
        t3332177.v_field_office_name_r                                              AS rso,
        t3332177.v_rso_number_r                                                     AS rso_num,
        t3332275.v_subgroup_name_r                                                  AS group_name,
        t3332177.v_situs_address_line1_r                                            AS v_subgroup_addressline1_r,
        t3332177.v_situs_address_line2_r                                            AS v_subgroup_addressline2_r,
        t3332177.v_situs_city_r                                                     AS v_subgroup_city_r,
        t3332177.v_situs_state_r                                                    AS v_subgroup_provstate_r,
        t3332177.v_situs_zip_code_r                                                 AS v_subgroup_postalzip_r,
        t3332155.v_benefit_code_r                                                   AS v_benefit_code_r,
        
         CASE WHEN t3332155.v_benefit_code_r='FIT' THEN 'FEDERAL INCOME TAX' ELSE
        t3332155.v_benefit_description_r  end                                       AS v_benefit_description_r,
        
		(case when t3332155.V_ACH_PAYMENT_IND_R='Y'
			    THEN 'AC'||t3332155.V_CHECK_NUMBER_R
               else t3332155.V_CHECK_NUMBER_R end
		)	                                                                        AS check_number,
        ( t3332239.n_paid_amount_r )                                                  AS paid_amount,
        t3332275.v_claim_number_r,
        t3332275.n_claim_sk_r,
        t3332155.d_service_period_from_r,
        t3332155.d_service_period_to_r,
        t3332155.d_paid_date_r                                                      AS paid_date,

t3332239.n_taxable_benefit_amount_r * (t3332275.N_CLAIM_TAXABLE_BENEFIT_PCT_R / 100) as TAXABLE_BENEFITS_,

SUM (CASE WHEN t3332239.V_BENEFIT_CODE_R NOT IN ('098', '097', '099', '200', '297', '298', 'FIC', 'MED')
		THEN  t3332239.n_taxable_benefit_amount_r * ( 1 - ( (case when t3332275.v_source_system_name_r = 'CV' then t3332275.N_CLAIM_TAXABLE_BENEFIT_PCT_R ELSE t3332239.n_taxable_benefit_percentage_r END)/ 100 )) ELSE 0 END )  non_taxable_benefits,
       
       case when t3332275.v_source_system_name_r = 'CV' and  t3332239.V_BENEFIT_CODE_R = 'FIT' then  nvl(t3332239.n_paid_amount_r,0) else  t3332239.n_federal_income_tax_amount_r    end AS fit,   
        t3332239.n_state_income_tax_amount_r                                        AS sit,
        t3332239.n_social_security_tax_amount_r                                     AS ss_tax,
        t3332239.n_medicare_tax_amount_r                                            AS medicare_tax,
        t3332239.N_STATE_UNEMPLOYMENT_TAX_AMOUNT_R                                        AS suta_pa_only,
        t3332239.N_SOCIAL_SECURITY_WAGE_BASE_AMOUNT_R                                    AS ss_wage_base,
        t3332239.N_MEDICARE_WAGE_BASE_AMOUNT_R                                            AS medicare_wage_base,
        t3332254.v_claimant_address_line1_r                                         AS v_addressline1_r,
        t3332254.v_claimant_address_line2_r                                         AS v_addressline2_r,
        t3332254.v_claimant_address_line3_r                                         AS v_addressline3_r,
        t3332254.v_claimant_city_r                                                  AS v_city_r,
        t3332254.v_individual_first_name_r
        || ' '
        || t3332254.v_individual_last_name_r                                         AS insured_name,
        
         CASE WHEN t3332254.V_SOURCE_SYSTEM_NAME_R='CV' then v_claimant_ssn_r
         ELSE
         
        substr(t3332254.v_claimant_ssn_r, 1, 3)
        || '-'
        || substr(t3332254.v_claimant_ssn_r, 4, 2)
        || '-'
        || substr(t3332254.v_claimant_ssn_r, 6, 4) end                                    AS ssn,
        t3332254.v_claimant_state_r                                                 AS v_state_name_r,
        t3332254.v_claimant_zip_code_r                                              AS v_postal_zip_r,
		 
		CASE WHEN t3332275.V_CLAIM_STATUS_CODE_R >= '60' THEN 'CLOSED' ELSE 'OPEN' END v_claim_status_reason_code_r,

t3332275.n_claim_taxable_benefit_pct_r AS cs_2,
        t3332275.d_loss_date_r                                                      AS d_date_of_loss_r,
        t3332177.n_yearmonth_r                                                      AS client_yearmonth,
        t3332275.n_yearmonth_r                                                      AS claim_detail_yearmonth,
        t3332256.n_yearmonth_r                                                      AS policy_detail_yearmonth,
        t3332155.n_yearmonth_r                                                      AS claim_payment_yearmonth,
        t3332239.n_yearmonth_r                                                      AS payment_detail_yearmonth,
		to_number(to_char(t3332155.d_paid_date_r, 'YYYYMM'))                        AS paid_date_r_yearmonth,
		to_number(to_char(t3332155.d_paid_date_r, 'YYYY'))                          AS paid_date_r_year,
		to_number(to_char(t3332155.d_paid_date_r, 'MM'))                            AS paid_date_r_month

,DIM_TIME_R.N_DATE_SK_R PAID_DATE_SK
		,DIM_TIME_R.N_QUARTER_R PAID_DATE_QTR
		,DECODE(t3332275.v_claim_company_r,'RSL','001','RSLT','003','FRSLIC','005',t3332275.v_claim_company_r)||' - '||
         case when t3332275.v_claim_company_r='RSL' then 'Reliance Standard Life Insurance Company'
         when t3332275.v_claim_company_r='FRSLIC' then 'First Reliance Standard Life Insurance Company'
         when t3332275.v_claim_company_r='RSLT' then 'Reliance Standard Life Insurance Company of Texas'
         else t3332275.v_claim_company_r end as Company_Name
		 ,t3332275.v_coverage_type_code_r  COVERAGE_TYPE
		 ,gc_getcur_loadedby               V_LAST_MODIFIED_BY_R
		 ,gd_sysdate                       T_CREATION_DATE_R
		 ,gc_getcur_loadedby               V_CREATED_BY_R
		 ,gd_sysdate                       T_LAST_MODIFIED_DATE_R
		 ,gn_current_month                 N_YEARMONTH_R
		 ,'Y'                              V_RPT_ACTIVE_STATUS_R
		 ,gn_sysdt_batchid                 N_BATCH_ID_R
		 
		 ,CASE WHEN t3332256.V_RSL_EIN_IND_R = 'X' THEN 'X'
        WHEN t3332256.V_RSL_EIN_IND_R = 'Y' THEN 'Y'
        ELSE 'N'
        END     AS  V_RSL_EIN_IND_R
		,t3332275.v_privacy_indicator_r AS V_PRIVACY_INDICATOR_R

, CASE WHEN NVL(t3332275.V_CLAIM_COVERAGE_CODE_R,'-')  = 'PFL' THEN 'Y'
          ELSE 'N'
          END AS V_PFL_INDICATOR
        
		,t3332254.V_EMPLOYEE_NUM_R AS V_CLAIMANT_EMPLOYEE_NUMBER_R 
    FROM
        rpt_client_dtl_r         t3332177 ,
        rpt_claimant_dtl_r       t3332254 ,
        rpt_claim_dtl_r          t3332275 ,
        rpt_policy_dtl_r         t3332256 ,
        rpt_claim_payment_r      t3332155 ,
        rpt_claim_payment_dtl_r  t3332239 
        ,DIM_TIME_R

WHERE
          t3332177.n_cust_party_sk_r = t3332239.n_cust_party_sk_r
          AND t3332177.n_yearmonth_r = t3332239.n_yearmonth_r
          AND t3332239.n_policy_sk_r = t3332256.n_policy_sk_r
          AND t3332239.n_insrd_party_sk_r = t3332254.n_insrd_party_sk_r
          AND t3332239.n_yearmonth_r = t3332254.n_yearmonth_r
          AND t3332155.n_payment_sk_r = t3332239.n_payment_sk_r
          AND t3332155.n_yearmonth_r = t3332239.n_yearmonth_r
          AND t3332239.n_claim_coverage_group_sk_r = t3332275.n_claim_coverage_group_sk_r
          AND t3332239.n_claim_coverage_sk_r = t3332275.n_claim_coverage_sk_r
          AND t3332239.n_claim_sk_r = t3332275.n_claim_sk_r
          AND t3332239.n_yearmonth_r = t3332256.n_yearmonth_r
          AND t3332239.n_yearmonth_r = t3332275.n_yearmonth_r
		  and t3332155.d_paid_date_r = DIM_TIME_R.D_CALENDAR_DATE_R

AND (
NVL(t3332275.V_COVERAGE_TYPE_CODE_R,'X') IN ('LTD','STD')

OR

NVL(T3332256.V_ORIG_LOB_R,'X') IN (SELECT V_COVERAGE_CODE_R FROM ATOMIC.DIM_GRP_PRODUCT_R WHERE NVL(V_COVERAGE_TYPE_CODE_R,'X') IN ('1','2'))
)
		  AND t3332155.V_CHECK_TYPE_R <> 'OE'
          AND to_number(to_char(t3332155.d_paid_date_r, 'YYYY')) >= to_number(to_char(add_months(trunc(sysdate, 'YYYY'), - 12 * 6),'YYYY'))
		  AND t3332275.n_yearmonth_r = gn_current_month
		  
		  and not  (t3332275.V_SOURCE_SYSTEM_NAME_R='CV' and T3332155.V_RECORD_TYPE_R = 'Gross Benefit')
		  
	GROUP BY
		'Claim Department'                                                          ,
        'P. O. Box 8330'                                                            ,
        'Philadelphia, Pennsylvania  19101-8330'                                    ,
        t3332256.v_policy_number_r                                                  ,
        t3332256.v_policy_number_r
        || '-'
        || t3332275.v_subgroup_id_r                                                 ,
        CASE
            WHEN upper(t3332275.v_correspondent_name_r) LIKE 'ATTN:%' THEN
                t3332275.v_correspondent_name_r
            ELSE
                'Attn:' || t3332275.v_correspondent_name_r
        END                                                                         ,
        t3332177.v_field_office_name_r                                              ,
        t3332177.v_rso_number_r                                                     ,
        t3332275.v_subgroup_name_r                                                  ,
        t3332177.v_situs_address_line1_r                                            ,
        t3332177.v_situs_address_line2_r                                            ,
        t3332177.v_situs_city_r                                                     ,
        t3332177.v_situs_state_r                                                    ,
        t3332177.v_situs_zip_code_r                                                 ,
        t3332155.v_benefit_code_r                                                   ,
        
         CASE WHEN t3332155.v_benefit_code_r='FIT' THEN 'FEDERAL INCOME TAX' ELSE
        t3332155.v_benefit_description_r  end                                        ,
        
		(case when t3332155.V_ACH_PAYMENT_IND_R='Y'
			    THEN 'AC'||t3332155.V_CHECK_NUMBER_R
               else t3332155.V_CHECK_NUMBER_R end
		)	                                                                       ,
        ( t3332239.n_paid_amount_r )                                                 ,
        t3332275.v_claim_number_r,
        t3332275.n_claim_sk_r,
        t3332155.d_service_period_from_r,
        t3332155.d_service_period_to_r,
        t3332155.d_paid_date_r                                                      ,

case when t3332275.v_source_system_name_r = 'CV' and  t3332239.V_BENEFIT_CODE_R = 'FIT' then  nvl(t3332239.n_paid_amount_r,0) else  t3332239.n_federal_income_tax_amount_r end,
        t3332239.n_state_income_tax_amount_r                                        ,
        t3332239.n_social_security_tax_amount_r                                     ,
        t3332239.n_medicare_tax_amount_r                                            ,
        t3332239.N_STATE_UNEMPLOYMENT_TAX_AMOUNT_R                                        ,
        t3332239.N_SOCIAL_SECURITY_WAGE_BASE_AMOUNT_R                                   ,
        t3332239.N_MEDICARE_WAGE_BASE_AMOUNT_R                                            ,
        t3332254.v_claimant_address_line1_r                                          ,
        t3332254.v_claimant_address_line2_r                                          ,
        t3332254.v_claimant_address_line3_r                                          ,
        t3332254.v_claimant_city_r                                                   ,
        t3332254.v_individual_first_name_r
        || ' '
        || t3332254.v_individual_last_name_r                                         ,
        
         CASE WHEN t3332254.V_SOURCE_SYSTEM_NAME_R='CV' then v_claimant_ssn_r
         ELSE
         
        substr(t3332254.v_claimant_ssn_r, 1, 3)
        || '-'
        || substr(t3332254.v_claimant_ssn_r, 4, 2)
        || '-'
        || substr(t3332254.v_claimant_ssn_r, 6, 4)  end                             ,
        t3332254.v_claimant_state_r                                                 ,
        t3332254.v_claimant_zip_code_r                                              ,
        t3332275.v_claim_status_desc_r                                               ,

t3332275.n_claim_taxable_benefit_pct_r,
        t3332275.d_loss_date_r                                                       ,
        t3332177.n_yearmonth_r                                                       ,
        t3332275.n_yearmonth_r                                                       ,
        t3332256.n_yearmonth_r                                                       ,
        t3332155.n_yearmonth_r                                                       ,
        t3332239.n_yearmonth_r                                                       ,
		to_number(to_char(t3332155.d_paid_date_r, 'YYYYMM'))                         ,
		to_number(to_char(t3332155.d_paid_date_r, 'YYYY'))                           ,
		to_number(to_char(t3332155.d_paid_date_r, 'MM'))

,DIM_TIME_R.N_DATE_SK_R
		,DIM_TIME_R.N_QUARTER_R
		,DECODE(t3332275.v_claim_company_r,'RSL','001','RSLT','003','FRSLIC','005',t3332275.v_claim_company_r)||' - '||
         case when t3332275.v_claim_company_r='RSL' then 'Reliance Standard Life Insurance Company'
         when t3332275.v_claim_company_r='FRSLIC' then 'First Reliance Standard Life Insurance Company'
         when t3332275.v_claim_company_r='RSLT' then 'Reliance Standard Life Insurance Company of Texas'
         else t3332275.v_claim_company_r end
		 ,t3332275.v_coverage_type_code_r
		 ,gc_getcur_loadedby
		 ,gd_sysdate
		 ,gc_getcur_loadedby
		 ,gd_sysdate
		 ,gn_current_month
		 ,'Y'
		 ,gn_sysdt_batchid
		 
		 ,CASE WHEN t3332256.V_RSL_EIN_IND_R = 'X' THEN 'X'
        WHEN t3332256.V_RSL_EIN_IND_R = 'Y' THEN 'Y'
        ELSE 'N'
        END
		,t3332275.v_privacy_indicator_r

,t3332239.n_taxable_benefit_amount_r * (t3332275.N_CLAIM_TAXABLE_BENEFIT_PCT_R / 100)
        ,t3332275.V_CLAIM_STATUS_CODE_R
        , 
         CASE WHEN NVL(t3332275.V_CLAIM_COVERAGE_CODE_R,'-')  = 'PFL' THEN 'Y'
          ELSE 'N'
          END
        
        ,t3332254.V_EMPLOYEE_NUM_R;