--------------------------------------------------------
--  DDL for Procedure PRC_GRP_LOAD_FCT_RPT_ANN_PREM_SUMMARY_R_MGIS
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "ATOMIC"."PRC_GRP_LOAD_FCT_RPT_ANN_PREM_SUMMARY_R_MGIS" 
-- Suresh 08-Apr-2025 Column added N_YTD_CURR_POLICY_COUNT_R
AS
BEGIN
    --Delete data if exists for MGIS
DELETE FROM ATOMIC.FCT_RPT_ANN_PREM_SUMMARY_R WHERE V_SOURCE_SYSTEM_NAME_R = 'MGIS' AND D_CYCLE_DATE_R = (SELECT
        D_CALENDAR_DATE_R as D_CYCLE_DATE_R

    FROM
        DIM_TIME_R
    WHERE
            V_END_OF_FISCAL_MONTH_IND_R = 'Y'
        AND EXTRACT(MONTH FROM D_CALENDAR_DATE_R) = EXTRACT(MONTH FROM SYSDATE)
        AND EXTRACT(YEAR FROM D_CALENDAR_DATE_R) = EXTRACT(YEAR FROM SYSDATE)) ;
commit;
 INSERT INTO ATOMIC.FCT_RPT_ANN_PREM_SUMMARY_R
(
D_CYCLE_DATE_R ,                                           
V_POLICY_NUMBER_R ,                           
V_CUSTOMER_BILL_GROUP_R ,             
V_SHORT_NAME_R ,                               
V_COVERAGE_CODE_R ,                            
V_CLASS_ID_R ,                                 
D_TRANSACTION_DATE_R ,                                    
D_DUE_DATE_R  ,                                           
V_PREMIUM_MODE_R     , 
N_PREMIUM_MODE_FACTOR_R,                        
N_ANNUALIZED_PREMIUM_R  ,                                 
N_GROSS_LIVES_R ,                                         
N_VOLUME_R  ,
D_YTD_PRIOR_CYCLE_DATE_R ,                                                                   
N_YTD_PRIOR_PREMIUM_R ,                                                                    
N_YTD_PRIOR_LIVES_R ,                                                                      
N_YTD_PRIOR_VOLUME_R ,                                                                     
N_YTD_CHG_PREMIUM_R ,                                                                      
N_YTD_CHG_LIVES_R ,                                                                        
N_YTD_CHG_VOLUME_R ,                                                                       
D_QTD_PRIOR_CYCLE_DATE_R ,                                                                   
N_QTD_PRIOR_PREMIUM_R ,                                                                    
N_QTD_PRIOR_LIVES_R ,                                                                      
N_QTD_PRIOR_VOLUME_R ,                                                                     
N_QTD_CHG_PREMIUM_R ,                                                                      
N_QTD_CHG_LIVES_R ,                                                                        
N_QTD_CHG_VOLUME_R ,                                                                       
D_MTD_PRIOR_CYCLE_DATE_R ,                                                                  
N_MTD_PRIOR_PREMIUM_R ,                                                                    
N_MTD_PRIOR_LIVES_R ,                                                                      
N_MTD_PRIOR_VOLUME_R ,                                                                     
N_MTD_CHG_PREMIUM_R ,                                                                      
N_MTD_CHG_LIVES_R ,                                                                        
N_MTD_CHG_VOLUME_R ,                                                                       
N_YTD_CURR_PREMIUM_R ,                                                                     
N_YTD_CURR_LIVES_R ,                                                                       
N_YTD_CURR_VOLUME_R ,                                                                      
N_QTD_CURR_PREMIUM_R ,                                                                     
N_QTD_CURR_LIVES_R ,                                                                       
N_QTD_CURR_VOLUME_R ,                                                                      
N_MTD_CURR_PREMIUM_R ,                                                                     
N_MTD_CURR_LIVES_R ,                                                                       
N_MTD_CURR_VOLUME_R,                                             
N_BATCH_ID_R  ,                                  
N_LOAD_RUN_ID_R ,                            
N_SEQUENCE_NUMBER_R ,                            
T_CREATION_DATE_R ,                        
T_EVENT_TIMESTAMP_R ,                      
T_LAST_MODIFIED_DATE_R ,                   
V_CREATED_BY_R ,                    
V_LAST_MODIFIED_BY_R ,                                                 
FIC_MIS_DATE_R ,                           
V_SOURCE_SYSTEM_NAME_R  ,                     
V_SUBJECT_AREA_TYPE_R ,                                                           
F_PHYSICAL_DELETE_R ,                              
V_CHANGE_REASON_R ,                          
N_POLICY_SK_R   ,                        
N_QUOTE_SK_R,
N_PARTY_SK_R ,
N_YTD_CURR_POLICY_COUNT_R,
N_POLICY_COUNT_R,
N_POLICY_LIVES_R,
N_YTD_CURR_POLICY_LIVES_R

)
with stagedata as 
(
Select
(SELECT
        D_CALENDAR_DATE_R as D_CYCLE_DATE_R

    FROM
        DIM_TIME_R
    WHERE
            V_END_OF_FISCAL_MONTH_IND_R = 'Y'
        AND EXTRACT(MONTH FROM D_CALENDAR_DATE_R) = EXTRACT(MONTH FROM SYSDATE)
        AND EXTRACT(YEAR FROM D_CALENDAR_DATE_R) = EXTRACT(YEAR FROM SYSDATE)) as D_CYCLE_DATE_R ,                                           
A.V_PREFIX_R || A.N_SUFFIX_R AS V_POLICY_NUMBER_R ,                           
'0000'||A.N_BILL_GROUP_R AS V_CUSTOMER_BILL_GROUP_R ,             
A.V_COMPANY_R AS V_SHORT_NAME_R ,                               
B.N_RSL_COVERAGE_CODE_R AS V_COVERAGE_CODE_R ,                            
A.N_CLASS_R AS V_CLASS_ID_R ,                                 
(SELECT
        D_CALENDAR_DATE_R as D_CYCLE_DATE_R

    FROM
        DIM_TIME_R
    WHERE
            V_END_OF_FISCAL_MONTH_IND_R = 'Y'
        AND EXTRACT(MONTH FROM D_CALENDAR_DATE_R) = EXTRACT(MONTH FROM SYSDATE)
        AND EXTRACT(YEAR FROM D_CALENDAR_DATE_R) = EXTRACT(YEAR FROM SYSDATE)) as D_TRANSACTION_DATE_R ,                                    
TO_DATE(A.D_DUE_DATE_R, 'yyyy-MM-dd') AS D_DUE_DATE_R  ,                                           
CASE WHEN A.N_BILLING_MODE_R = 01 then 'Monthly'
WHEN A.N_BILLING_MODE_R =03 then 'Quarterly'
WHEN A.N_BILLING_MODE_R =06 then 'Semiannually'
WHEN A.N_BILLING_MODE_R = 12 then 'Annually'
WHEN A.N_BILLING_MODE_R = 36 then '3 Years pre-paid'
WHEN A.N_BILLING_MODE_R = 60 then '5 Years pre-paid' END AS V_PREMIUM_MODE_R    ,                      
A.N_PREMIUM_AMT_R AS N_ANNUALIZED_PREMIUM_R  ,                                 
A.N_LIVES_R AS N_GROSS_LIVES_R ,                                         
A.N_VOLUME_R AS N_VOLUME_R  ,                                             
A.N_BATCH_ID_R ,                                                                                  
A.FIC_MIS_DATE_R AS FIC_MIS_DATE_R ,                                                    
NVL(c.N_POLICY_SK_R,-1) AS N_POLICY_SK_R                        

FROM 
(Select
 V_PREFIX_R,N_SUFFIX_R,
 V_COMPANY_R,
 D_DUE_DATE_R,
 N_CLASS_R, 
 N_LIVES_R ,                                     
 N_VOLUME_R ,
 N_PREMIUM_AMT_R,
 N_BILL_GROUP_R,
 V_COVERAGE_CODE_R,
 N_BILLING_MODE_R,
 N_BATCH_ID_R,
 FIC_MIS_DATE_R,
  MAX(D_DUE_DATE_R) OVER (PARTITION BY V_PREFIX_R,N_SUFFIX_R) as MAX_DUE_DATE_R

FROM STG_MGIS_RM_PREMIUM_R 
where D_FILE_DATE_R<=(Select max(D_FILE_DATE_R) from ATOMIC.STG_MGIS_RM_PREMIUM_R) --history policies need to be included for current cycledate
) A
LEFT JOIN
STG_LKP_MGIS_COVG_CD_R B
ON A.V_COVERAGE_CODE_R = B.V_COVERAGE_CODE_R
LEFT JOIN
dim_grp_policy_dir_r C
ON 
--A.V_PREFIX_R||A.N_SUFFIX_R = C.V_ORIG_POLICY_NUMBER_R
A.V_PREFIX_R = C.V_POLICY_PREFIX_R
AND LTRIM(A.N_SUFFIX_R,'0') = LTRIM(C.V_POLICY_SUFFIX_R,'0')
AND C.V_ACTIVE_STATUS_R='Y'
WHERE A.D_DUE_DATE_R = A.MAX_DUE_DATE_R
),
FinalData as
(
SELECT
D_CYCLE_DATE_R ,                                           
V_POLICY_NUMBER_R ,                           
V_CUSTOMER_BILL_GROUP_R ,             
V_SHORT_NAME_R ,                               
V_COVERAGE_CODE_R ,                            
V_CLASS_ID_R ,                                 
D_TRANSACTION_DATE_R ,                                    
MAX(D_DUE_DATE_R) AS D_DUE_DATE_R  ,                                           
V_PREMIUM_MODE_R     ,   
CASE
WHEN UPPER(V_PREMIUM_MODE_R) = 'MONTHLY' THEN 12.0
WHEN UPPER(V_PREMIUM_MODE_R) = 'QUARTERLY' THEN 4.0
WHEN UPPER(V_PREMIUM_MODE_R) = 'SEMIANNUALLY' THEN 2.0
WHEN UPPER(V_PREMIUM_MODE_R) = 'NINTHLY' THEN 12 / 9
WHEN UPPER(V_PREMIUM_MODE_R) = 'TENTHLY' THEN 12 / 10
WHEN UPPER(V_PREMIUM_MODE_R) = 'ELEVENTH' THEN 12 / 11
WHEN UPPER(V_PREMIUM_MODE_R) = 'ANNUALLY' THEN 1
WHEN UPPER(V_PREMIUM_MODE_R) = '3 YEARS PRE-PAID' THEN 1.0 / 3
WHEN UPPER(V_PREMIUM_MODE_R) = '3 YEARS WITH INSTALLMENT' THEN 1.0
WHEN UPPER(V_PREMIUM_MODE_R) = '5 YEARS PRE-PAID' THEN 0.2
WHEN UPPER(V_PREMIUM_MODE_R) = '5 YEARS WITH INSATLLMENT' THEN 1.0
END AS N_PREMIUM_MODE_FACTOR_R,                       
SUM(N_ANNUALIZED_PREMIUM_R) AS N_ANNUALIZED_PREMIUM_R  ,                                 
SUM(N_GROSS_LIVES_R) AS N_GROSS_LIVES_R ,                                         
SUM(N_VOLUME_R) AS N_VOLUME_R   ,                                             
N_BATCH_ID_R  ,                                                                                   
FIC_MIS_DATE_R ,                                                    
N_POLICY_SK_R                           

from stagedata
Group by
D_CYCLE_DATE_R ,                                           
V_POLICY_NUMBER_R ,                           
V_CUSTOMER_BILL_GROUP_R ,             
V_SHORT_NAME_R ,                               
V_COVERAGE_CODE_R ,                            
V_CLASS_ID_R ,                                 
D_TRANSACTION_DATE_R ,                                                                              
V_PREMIUM_MODE_R     ,                                                                  
N_BATCH_ID_R  ,                                                                                   
FIC_MIS_DATE_R ,                                                    
N_POLICY_SK_R 
),
BATCH_DATE AS (
        SELECT * FROM
            ( SELECT D_CALENDAR_DATE_R as D_CALENDAR_DATE_R,
                    RANK() OVER (  ORDER BY D_CALENDAR_DATE_R DESC) DATE_RANK
                from
                    Atomic.DIM_TIME_R
                where
                    V_END_OF_FISCAL_MONTH_IND_R = 'Y' AND D_CALENDAR_DATE_R < (SELECT D_CALENDAR_DATE_R +1 
    FROM DIM_TIME_R D
    WHERE  V_END_OF_FISCAL_MONTH_IND_R = 'Y'
    and to_char(d_calendar_date_r,'YYYYMM')=to_char(sysdate,'YYYYMM'))
            ) WHERE DATE_RANK < 3
    ),
    BATCH_DATE_QTR AS (
        SELECT * FROM
            ( SELECT D_CALENDAR_DATE_R as D_CALENDAR_DATE_R,
                    RANK() OVER (  ORDER BY D_CALENDAR_DATE_R DESC) DATE_RANK
                from
                    Atomic.DIM_TIME_R
                where
                    V_END_OF_FISCAL_QUARTER_IND_R = 'Y' AND D_CALENDAR_DATE_R < (Select sysdate from dual)
            ) WHERE DATE_RANK < 2
    ),
    BATCH_DATE_YTD AS (
        SELECT * FROM
            ( SELECT D_CALENDAR_DATE_R as D_CALENDAR_DATE_R,
                    RANK() OVER (  ORDER BY D_CALENDAR_DATE_R DESC) DATE_RANK
                from
                    Atomic.DIM_TIME_R
                where
                    V_END_OF_FISCAL_YEAR_IND_R = 'Y' AND D_CALENDAR_DATE_R < (Select sysdate from dual)
            ) WHERE DATE_RANK < 2
    ),
YTD_Final as 
(
SELECT
D_CYCLE_DATE_R ,                                          
V_POLICY_NUMBER_R ,                           
V_CUSTOMER_BILL_GROUP_R ,             
V_SHORT_NAME_R ,                               
V_COVERAGE_CODE_R ,                            
V_CLASS_ID_R ,                                 
D_TRANSACTION_DATE_R ,                                    
D_DUE_DATE_R  ,                                           
V_PREMIUM_MODE_R     ,                       
SUM(N_ANNUALIZED_PREMIUM_R) AS N_YTD_PRIOR_PREMIUM_R   ,                                 
SUM(N_GROSS_LIVES_R) AS N_YTD_PRIOR_LIVES_R ,                                         
SUM(N_VOLUME_R) AS N_YTD_PRIOR_VOLUME_R ,                                                                                                             
--N_BATCH_ID_R  ,                                                                                   
--FIC_MIS_DATE_R ,                                                    
N_POLICY_SK_R                           

from FCT_RPT_ANN_PREM_SUMMARY_R
where V_SOURCE_SYSTEM_NAME_R = 'MGIS' and D_CYCLE_DATE_R = (SELECT BATCH_DATE_YTD.D_CALENDAR_DATE_R FROM BATCH_DATE_YTD WHERE DATE_RANK = 1)
Group by
D_CYCLE_DATE_R ,                                           
V_POLICY_NUMBER_R ,                           
V_CUSTOMER_BILL_GROUP_R ,             
V_SHORT_NAME_R ,                               
V_COVERAGE_CODE_R ,                            
V_CLASS_ID_R ,                                 
D_TRANSACTION_DATE_R ,                                    
D_DUE_DATE_R  ,                                           
V_PREMIUM_MODE_R     ,                                                                    
--N_BATCH_ID_R  ,                                                                                   
--FIC_MIS_DATE_R ,                                                    
N_POLICY_SK_R 
),
QTD_Final as
(
SELECT
D_CYCLE_DATE_R ,                                           
V_POLICY_NUMBER_R ,                           
V_CUSTOMER_BILL_GROUP_R ,             
V_SHORT_NAME_R ,                               
V_COVERAGE_CODE_R ,                            
V_CLASS_ID_R ,                                 
D_TRANSACTION_DATE_R ,                                    
D_DUE_DATE_R  ,                                           
V_PREMIUM_MODE_R     ,                       
SUM(N_ANNUALIZED_PREMIUM_R) AS N_QTD_PRIOR_PREMIUM_R   ,                                 
SUM(N_GROSS_LIVES_R) AS N_QTD_PRIOR_LIVES_R ,                                         
SUM(N_VOLUME_R) AS N_QTD_PRIOR_VOLUME_R ,                                               
--N_BATCH_ID_R  ,                                                                                   
--FIC_MIS_DATE_R ,                                                    
N_POLICY_SK_R                           

from FCT_RPT_ANN_PREM_SUMMARY_R
where V_SOURCE_SYSTEM_NAME_R = 'MGIS' and D_CYCLE_DATE_R = (SELECT BATCH_DATE_QTR.D_CALENDAR_DATE_R FROM BATCH_DATE_QTR WHERE DATE_RANK = 1)
Group by
D_CYCLE_DATE_R ,                                           
V_POLICY_NUMBER_R ,                           
V_CUSTOMER_BILL_GROUP_R ,             
V_SHORT_NAME_R ,                               
V_COVERAGE_CODE_R ,                            
V_CLASS_ID_R ,                                 
D_TRANSACTION_DATE_R ,                                    
D_DUE_DATE_R  ,                                           
V_PREMIUM_MODE_R     ,                                                                    
--N_BATCH_ID_R  ,                                                                                   
--FIC_MIS_DATE_R ,                                                    
N_POLICY_SK_R 
),
MTD_Final as 
(
SELECT
D_CYCLE_DATE_R ,                                           
V_POLICY_NUMBER_R ,                           
V_CUSTOMER_BILL_GROUP_R ,             
V_SHORT_NAME_R ,                               
V_COVERAGE_CODE_R ,                            
V_CLASS_ID_R ,                                 
D_TRANSACTION_DATE_R ,                                    
D_DUE_DATE_R  ,                                           
V_PREMIUM_MODE_R     ,                       
SUM(N_ANNUALIZED_PREMIUM_R) AS N_MTD_PRIOR_PREMIUM_R   ,                                 
SUM(N_GROSS_LIVES_R) AS N_MTD_PRIOR_LIVES_R ,                                         
SUM(N_VOLUME_R) AS N_MTD_PRIOR_VOLUME_R ,                                             
--N_BATCH_ID_R  ,                                                                                   
--FIC_MIS_DATE_R ,                                                    
N_POLICY_SK_R                           

from FCT_RPT_ANN_PREM_SUMMARY_R
where V_SOURCE_SYSTEM_NAME_R = 'MGIS' and D_CYCLE_DATE_R = (SELECT BATCH_DATE.D_CALENDAR_DATE_R FROM BATCH_DATE WHERE DATE_RANK = 2)
Group by
D_CYCLE_DATE_R ,                                           
V_POLICY_NUMBER_R ,                           
V_CUSTOMER_BILL_GROUP_R ,             
V_SHORT_NAME_R ,                               
V_COVERAGE_CODE_R ,                            
V_CLASS_ID_R ,                                 
D_TRANSACTION_DATE_R ,                                    
D_DUE_DATE_R  ,                                           
V_PREMIUM_MODE_R     ,                                                                
--N_BATCH_ID_R  ,                                                                                   
--FIC_MIS_DATE_R ,                                                    
N_POLICY_SK_R 
)	,
Premium_calc as (
SELECT
FD.D_CYCLE_DATE_R ,                                           
FD.V_POLICY_NUMBER_R ,                           
FD.V_CUSTOMER_BILL_GROUP_R ,             
FD.V_SHORT_NAME_R ,                               
FD.V_COVERAGE_CODE_R ,                            
FD.V_CLASS_ID_R ,                                 
FD.D_TRANSACTION_DATE_R ,                                    
FD.D_DUE_DATE_R  ,                                           
FD.V_PREMIUM_MODE_R     ,   
FD.N_PREMIUM_MODE_FACTOR_R,                     
(FD.N_ANNUALIZED_PREMIUM_R*FD.N_PREMIUM_MODE_FACTOR_R) AS N_ANNUALIZED_PREMIUM_R  ,                                 
FD.N_GROSS_LIVES_R ,                                         
FD.N_VOLUME_R  ,
(SELECT BATCH_DATE_YTD.D_CALENDAR_DATE_R FROM BATCH_DATE_YTD WHERE DATE_RANK = 1) AS D_YTD_PRIOR_CYCLE_DATE_R ,                                                                   
YTD.N_YTD_PRIOR_PREMIUM_R ,                                                                    
YTD.N_YTD_PRIOR_LIVES_R ,                                                                      
YTD.N_YTD_PRIOR_VOLUME_R ,                                                                     

(SELECT BATCH_DATE_QTR.D_CALENDAR_DATE_R FROM BATCH_DATE_QTR WHERE DATE_RANK = 1) AS D_QTD_PRIOR_CYCLE_DATE_R ,                                                                   
QTD.N_QTD_PRIOR_PREMIUM_R ,                                                                    
QTD.N_QTD_PRIOR_LIVES_R ,                                                                      
QTD.N_QTD_PRIOR_VOLUME_R ,                                                                     

(SELECT BATCH_DATE.D_CALENDAR_DATE_R FROM BATCH_DATE WHERE DATE_RANK = 2) AS D_MTD_PRIOR_CYCLE_DATE_R ,                                                                  
MTD.N_MTD_PRIOR_PREMIUM_R ,                                                                    
MTD.N_MTD_PRIOR_LIVES_R ,                                                                      
MTD.N_MTD_PRIOR_VOLUME_R ,                                                                     

(FD.N_ANNUALIZED_PREMIUM_R*FD.N_PREMIUM_MODE_FACTOR_R) AS N_YTD_CURR_PREMIUM_R ,                                                                     
FD.N_GROSS_LIVES_R AS N_YTD_CURR_LIVES_R ,                                                                       
FD.N_VOLUME_R AS N_YTD_CURR_VOLUME_R ,                                                                      
(FD.N_ANNUALIZED_PREMIUM_R*FD.N_PREMIUM_MODE_FACTOR_R) AS N_QTD_CURR_PREMIUM_R ,                                                                     
FD.N_GROSS_LIVES_R AS N_QTD_CURR_LIVES_R ,                                                                       
FD.N_VOLUME_R AS N_QTD_CURR_VOLUME_R ,                                                                      
(FD.N_ANNUALIZED_PREMIUM_R*FD.N_PREMIUM_MODE_FACTOR_R) AS N_MTD_CURR_PREMIUM_R ,                                                                     
FD.N_GROSS_LIVES_R AS N_MTD_CURR_LIVES_R ,                                                                       
FD.N_VOLUME_R AS N_MTD_CURR_VOLUME_R ,                                             
FD.N_BATCH_ID_R  ,                                  
(select NVL(MAX(N_LOAD_RUN_ID_R),0)+1 from ATOMIC.FCT_RPT_ANN_PREM_SUMMARY_R where V_SOURCE_SYSTEM_NAME_R ='MGIS' AND
N_BATCH_ID_R=(Select max(n_batch_id_r) from ATOMIC.STG_MGIS_RM_PREMIUM_R)) AS N_LOAD_RUN_ID_R ,                            
(select NVL(MAX(N_SEQUENCE_NUMBER_R),0) from ATOMIC.FCT_RPT_ANN_PREM_SUMMARY_R) + rownum as N_SEQUENCE_NUMBER_R ,                            
sysdate as T_CREATION_DATE_R ,                        
sysdate as T_EVENT_TIMESTAMP_R ,                      
sysdate as T_LAST_MODIFIED_DATE_R ,                   
'Data Lake' as V_CREATED_BY_R ,                    
'Data Lake' as V_LAST_MODIFIED_BY_R ,                                                  
FD.FIC_MIS_DATE_R ,                           
'MGIS' AS V_SOURCE_SYSTEM_NAME_R  ,                     
NULL AS V_SUBJECT_AREA_TYPE_R ,                                                            
NULL as F_PHYSICAL_DELETE_R ,                              
NULL as V_CHANGE_REASON_R ,                          
FD.N_POLICY_SK_R   ,                        
-1 as N_QUOTE_SK_R ,
-1 as N_PARTY_SK_R   
from FinalData FD
LEFT JOIN
YTD_Final YTD
ON

FD.V_POLICY_NUMBER_R = YTD.V_POLICY_NUMBER_R AND                           
FD.V_CUSTOMER_BILL_GROUP_R = YTD.V_CUSTOMER_BILL_GROUP_R AND             
FD.V_SHORT_NAME_R = YTD.V_SHORT_NAME_R AND                              
FD.V_COVERAGE_CODE_R =  YTD.V_COVERAGE_CODE_R AND                          
FD.V_CLASS_ID_R = YTD.V_CLASS_ID_R  AND                               
--FD.D_TRANSACTION_DATE_R = YTD.D_TRANSACTION_DATE_R   AND                                 
--FD.D_DUE_DATE_R = YTD.D_DUE_DATE_R AND                                           
FD.V_PREMIUM_MODE_R  = YTD.V_PREMIUM_MODE_R  AND                                                                                                                
FD.N_POLICY_SK_R = YTD.N_POLICY_SK_R
LEFT JOIN
QTD_FINAL QTD 
on

FD.V_POLICY_NUMBER_R = QTD.V_POLICY_NUMBER_R AND                           
FD.V_CUSTOMER_BILL_GROUP_R = QTD.V_CUSTOMER_BILL_GROUP_R AND             
FD.V_SHORT_NAME_R = QTD.V_SHORT_NAME_R AND                              
FD.V_COVERAGE_CODE_R =  QTD.V_COVERAGE_CODE_R AND                          
FD.V_CLASS_ID_R = QTD.V_CLASS_ID_R  AND                               
--FD.D_TRANSACTION_DATE_R = QTD.D_TRANSACTION_DATE_R   AND                                 
--FD.D_DUE_DATE_R = QTD.D_DUE_DATE_R AND                                           
FD.V_PREMIUM_MODE_R  = QTD.V_PREMIUM_MODE_R  AND  FD.N_POLICY_SK_R = QTD.N_POLICY_SK_R                                                                                                                
LEFT JOIN
MTD_Final MTD
ON

FD.V_POLICY_NUMBER_R = MTD.V_POLICY_NUMBER_R AND                           
FD.V_CUSTOMER_BILL_GROUP_R = MTD.V_CUSTOMER_BILL_GROUP_R AND             
FD.V_SHORT_NAME_R = MTD.V_SHORT_NAME_R AND                              
FD.V_COVERAGE_CODE_R =  MTD.V_COVERAGE_CODE_R AND                          
FD.V_CLASS_ID_R = MTD.V_CLASS_ID_R  AND                               
--FD.D_TRANSACTION_DATE_R = MTD.D_TRANSACTION_DATE_R   AND                                 
--FD.D_DUE_DATE_R = MTD.D_DUE_DATE_R AND                                           
FD.V_PREMIUM_MODE_R  = MTD.V_PREMIUM_MODE_R  AND                                                                                                                  
FD.N_POLICY_SK_R = MTD.N_POLICY_SK_R)
SELECT
D_CYCLE_DATE_R ,                                           
V_POLICY_NUMBER_R ,                           
V_CUSTOMER_BILL_GROUP_R ,             
V_SHORT_NAME_R ,                               
V_COVERAGE_CODE_R ,                            
V_CLASS_ID_R ,                                 
D_TRANSACTION_DATE_R ,                                    
D_DUE_DATE_R  ,                                           
V_PREMIUM_MODE_R     , 
N_PREMIUM_MODE_FACTOR_R ,                       
N_ANNUALIZED_PREMIUM_R  ,                                 
N_GROSS_LIVES_R ,                                         
N_VOLUME_R  , 
D_YTD_PRIOR_CYCLE_DATE_R ,                                                                   
N_YTD_PRIOR_PREMIUM_R ,                                                                    
N_YTD_PRIOR_LIVES_R ,                                                                      
N_YTD_PRIOR_VOLUME_R ,                                                                     
NVL(N_ANNUALIZED_PREMIUM_R, 0) - NVL(N_YTD_PRIOR_PREMIUM_R, 0) AS  N_YTD_CHG_PREMIUM_R ,                                                                      
NVL(N_GROSS_LIVES_R , 0) - NVL(N_YTD_PRIOR_LIVES_R, 0) AS N_YTD_CHG_LIVES_R ,                                                                        
NVL(N_VOLUME_R, 0) - NVL(N_YTD_PRIOR_VOLUME_R, 0) AS N_YTD_CHG_VOLUME_R ,                                                                       
D_QTD_PRIOR_CYCLE_DATE_R ,                                                                   
N_QTD_PRIOR_PREMIUM_R ,                                                                    
N_QTD_PRIOR_LIVES_R ,                                                                      
N_QTD_PRIOR_VOLUME_R ,                                                                     
NVL(N_ANNUALIZED_PREMIUM_R, 0) - NVL(N_QTD_PRIOR_PREMIUM_R, 0) AS N_QTD_CHG_PREMIUM_R ,                                                                      
NVL(N_GROSS_LIVES_R , 0) - NVL(N_QTD_PRIOR_LIVES_R, 0) AS N_QTD_CHG_LIVES_R ,                                                                        
NVL(N_VOLUME_R, 0) - NVL(N_QTD_PRIOR_VOLUME_R, 0) AS N_QTD_CHG_VOLUME_R ,                                                                      
D_MTD_PRIOR_CYCLE_DATE_R ,                                                                  
N_MTD_PRIOR_PREMIUM_R ,                                                                    
N_MTD_PRIOR_LIVES_R ,                                                                      
N_MTD_PRIOR_VOLUME_R ,                                                                     
NVL(N_ANNUALIZED_PREMIUM_R, 0) - NVL(N_MTD_PRIOR_PREMIUM_R, 0) AS N_MTD_CHG_PREMIUM_R ,                                                                      
NVL(N_GROSS_LIVES_R , 0) - NVL(N_MTD_PRIOR_LIVES_R, 0) AS N_MTD_CHG_LIVES_R ,                                                                        
NVL(N_VOLUME_R, 0) - NVL(N_MTD_PRIOR_VOLUME_R, 0) AS N_MTD_CHG_VOLUME_R ,                                                                       
N_YTD_CURR_PREMIUM_R ,                                                                     
N_YTD_CURR_LIVES_R ,                                                                       
N_YTD_CURR_VOLUME_R ,                                                                      
N_QTD_CURR_PREMIUM_R ,                                                                     
N_QTD_CURR_LIVES_R ,                                                                       
N_QTD_CURR_VOLUME_R ,                                                                      
N_MTD_CURR_PREMIUM_R ,                                                                     
N_MTD_CURR_LIVES_R ,                                                                       
N_MTD_CURR_VOLUME_R,                                            
N_BATCH_ID_R  ,                                  
N_LOAD_RUN_ID_R ,                            
N_SEQUENCE_NUMBER_R ,                            
T_CREATION_DATE_R ,                        
T_EVENT_TIMESTAMP_R ,                      
T_LAST_MODIFIED_DATE_R ,                   
V_CREATED_BY_R ,                    
V_LAST_MODIFIED_BY_R ,                                                 
FIC_MIS_DATE_R ,                           
V_SOURCE_SYSTEM_NAME_R  ,                     
V_SUBJECT_AREA_TYPE_R ,                                                           
F_PHYSICAL_DELETE_R ,                              
V_CHANGE_REASON_R ,                          
N_POLICY_SK_R   ,                        
N_QUOTE_SK_R,
N_PARTY_SK_R,
CASE WHEN V_POLICY_NUMBER_R IS NOT NULL AND D_CYCLE_DATE_R IS NOT NULL THEN
(1/COUNT(V_POLICY_NUMBER_R) OVER (PARTITION BY V_POLICY_NUMBER_R, D_CYCLE_DATE_R))   -- 08-04-2025 added colunm as gisha said
ELSE
  NULL
END  N_YTD_CURR_POLICY_COUNT_R,  -- 04-04-2025 added colunm as gisha said
CASE WHEN V_POLICY_NUMBER_R IS NOT NULL AND D_CYCLE_DATE_R IS NOT NULL THEN
(1/COUNT(V_POLICY_NUMBER_R) OVER (PARTITION BY V_POLICY_NUMBER_R, D_CYCLE_DATE_R))   -- 08-04-2025 added colunm as gisha said
ELSE
  NULL
END  N_POLICY_COUNT_R,
N_GROSS_LIVES_R as N_POLICY_LIVES_R,
N_GROSS_LIVES_R as N_YTD_CURR_POLICY_LIVES_R
from
Premium_calc;
commit;
END;

/

  GRANT EXECUTE ON "ATOMIC"."PRC_GRP_LOAD_FCT_RPT_ANN_PREM_SUMMARY_R_MGIS" TO "ATOMIC_ALL_RO";
