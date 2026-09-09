-- Cleaned for lineage: PRC_GRP_LOAD_RPT_PREMIUM_DTL_R_MGIS

CREATE OR REPLACE EDITIONABLE PROCEDURE "ATOMIC"."PRC_GRP_LOAD_RPT_PREMIUM_DTL_R_MGIS" 
AS
BEGIN
DELETE FROM ATOMIC.RPT_PREMIUM_DTL_R WHERE V_SOURCE_SYSTEM_NAME_R = 'MGIS' AND N_REPORTMONTH_R = CAST(TO_CHAR(TRUNC(sysdate, 'MM'), 'YYYYMM') AS INTEGER);

INSERT INTO ATOMIC.RPT_PREMIUM_DTL_R
(
n_Inforce_Number_of_Lives_R,
n_Most_Recent_Posted_Number_of_Lives_R,
N_Most_Recent_Premium_Posted_Amount_R,
N_Policy_Billgroup_ID_R,
n_Premium_Due_Amount_R,
n_Premium_Number_of_Lives_R,
n_Premium_Paid_Amount_R,
n_Premium_Policy_Invoice_ID_R,
n_Premium_Volume_R,
n_Premium_Class_ID_R,
n_Premium_Coverage_ID_R,
n_Net_Premium_ID_R,
N_POLICY_SK_R,
n_Premium_Payment_Id_R,
V_SOURCE_SYSTEM_NAME_R,
N_BATCH_ID_R  ,
N_REPORTMONTH_R ,
N_BILLGROUP_SK_R,
N_CUST_PARTY_SK_R,
N_PRODUCT_SK_R
)
Select
n_Inforce_Number_of_Lives_R,
n_Most_Recent_Posted_Number_of_Lives_R,
N_Most_Recent_Premium_Posted_Amount_R,
N_Policy_Billgroup_ID_R,
n_Premium_Due_Amount_R,
n_Premium_Number_of_Lives_R,
n_Premium_Paid_Amount_R,
n_Premium_Policy_Invoice_ID_R,
n_Premium_Volume_R,
n_Premium_Class_ID_R,
n_Premium_Coverage_ID_R,
n_Net_Premium_ID_R,
N_POLICY_SK_R,
n_Premium_Payment_Id_R,
V_SOURCE_SYSTEM_NAME_R,
N_BATCH_ID_R  ,
N_REPORTMONTH_R ,
N_BILLGROUP_SK_R,
N_CUST_PARTY_SK_R,
N_PRODUCT_SK_R
from (
Select
A.N_LIVES_R AS n_Inforce_Number_of_Lives_R,
A.N_LIVES_R AS n_Most_Recent_Posted_Number_of_Lives_R,
A.N_AMOUNT_PAID_R AS N_Most_Recent_Premium_Posted_Amount_R,
A.N_SRC_POLICY_BILLGROUP_ID_R AS N_Policy_Billgroup_ID_R,
A.N_AMOUNT_DUE_R AS n_Premium_Due_Amount_R,
A.N_LIVES_R AS n_Premium_Number_of_Lives_R,
A.N_AMOUNT_PAID_R AS n_Premium_Paid_Amount_R,
A.N_SRC_POLICY_INVOICE_ID_R AS n_Premium_Policy_Invoice_ID_R,
A.N_VOLUME_R AS n_Premium_Volume_R,
A.N_SRC_CLASS_ID_R as n_Premium_Class_ID_R,
A.N_SRC_COVERAGE_ID_R as n_Premium_Coverage_ID_R,
A.N_SRC_NET_PREMIUM_ID_R as n_Net_Premium_ID_R,
A.N_POLICY_SK_R,
A.N_SRC_PREMIUM_PAYMENT_ID_R as n_Premium_Payment_Id_R,
A.V_SOURCE_SYSTEM_NAME_R,
A.N_BATCH_ID_R  ,
CAST(TO_CHAR(TRUNC(sysdate, 'MM'), 'YYYYMM') AS INTEGER) AS N_REPORTMONTH_R ,
NVL(D.N_POLICY_BILLGROUP_SK_R,-1) as N_BILLGROUP_SK_R, 
NVL(B.N_CUST_PARTY_SK_R,-1) as N_CUST_PARTY_SK_R, 
NVL(E.N_PRODUCT_SK_R,-1) as N_PRODUCT_SK_R
FROM FCT_BILLING_POLICY_PREMIUM_R  A
LEFT JOIN (select distinct N_POLICY_SK_R ,N_POLICY_BILLGROUP_ID_R,N_POLICY_BILLGROUP_SK_R from DIM_GRP_BILLING_POL_BILLGRP_R where V_SOURCE_SYSTEM_NAME_R   ='MGIS' AND v_active_status_r = 'Y') D 
ON  A.N_SRC_POLICY_BILLGROUP_ID_R = D.N_POLICY_BILLGROUP_ID_R
            AND A.N_POLICY_SK_R = D.N_POLICY_SK_R
LEFT JOIN (select distinct N_POLICY_SK_R,N_CUST_PARTY_SK_R  from fct_grp_policy_r where V_DISTRIBUTION_CHANNEL_R like '%MGIS%' ) B
ON A.N_POLICY_SK_R= B.N_POLICY_SK_R
LEFT JOIN DIM_GRP_PRODUCT_R E 
ON A.V_COVERAGECODE_R = E.V_COVERAGE_CODE_R				   
        where A.V_SOURCE_SYSTEM_NAME_R   ='MGIS' ) 
group BY
n_Inforce_Number_of_Lives_R,
n_Most_Recent_Posted_Number_of_Lives_R,
N_Most_Recent_Premium_Posted_Amount_R,
N_Policy_Billgroup_ID_R,
n_Premium_Due_Amount_R,
n_Premium_Number_of_Lives_R,
n_Premium_Paid_Amount_R,
n_Premium_Policy_Invoice_ID_R,
n_Premium_Volume_R,
n_Premium_Class_ID_R,
n_Premium_Coverage_ID_R,
n_Net_Premium_ID_R,
N_POLICY_SK_R,
n_Premium_Payment_Id_R,
V_SOURCE_SYSTEM_NAME_R,
N_BATCH_ID_R  ,
N_REPORTMONTH_R ,
N_BILLGROUP_SK_R,
N_CUST_PARTY_SK_R,
N_PRODUCT_SK_R;