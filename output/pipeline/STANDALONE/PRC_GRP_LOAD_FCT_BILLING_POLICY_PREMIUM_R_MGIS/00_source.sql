

  CREATE OR REPLACE EDITIONABLE PROCEDURE "ATOMIC"."PRC_GRP_LOAD_FCT_BILLING_POLICY_PREMIUM_R_MGIS"
---- Procedure to load MGIS billing policy premium data into fact table
AS
BEGIN

    --Delete data if exists for MGIS
    DELETE FROM ATOMIC.FCT_BILLING_POLICY_PREMIUM_R
    WHERE V_SOURCE_SYSTEM_NAME_R = 'MGIS';

    COMMIT;

    INSERT INTO ATOMIC.FCT_BILLING_POLICY_PREMIUM_R
    (
        N_SRC_CARRIER_ID_R,
        N_SRC_POLICY_BILLGROUP_ID_R,
        D_DUE_DATE_R,
        N_SRC_CLASS_ID_R,
        D_TRANSACTION_DATE_R,
        N_PREMIUM_TYPE_R,
        N_AMOUNT_PAID_R,
        D_PAID_TO_DATE_R,
        N_LIVES_R,
        N_VOLUME_R,
        N_GROSS_NET_R,
        N_NET_PREMIUM_R,
        N_POLICY_SK_R,
        V_BILLGROUPNUMBER_R,
        V_COVERAGECODE_R,
        N_MONTHS_PAID_R,
        T_EVENT_TIMESTAMP_R,
        V_SOURCE_SYSTEM_NAME_R,
        N_BATCH_ID_R,
        N_LOAD_RUN_ID_R,
        N_SEQUENCE_NUMBER_R,
        T_CREATION_DATE_R,
        T_LAST_MODIFIED_DATE_R,
        V_CREATED_BY_R,
        V_LAST_MODIFIED_BY_R,
        FIC_MIS_DATE_R,
        F_PHYSICAL_DELETE_R,
        V_CHANGE_REASON_R,
        V_PRIVACY_INDICATOR_R,
        N_SRC_PREMIUM_PAYMENT_ID_R,
        D_SRC_TRANSACTION_DATE_R, -- Added New Column for MGIS 5500 Report --2026-04-15
        N_LIVES_ADJ_R  -- Added New Column for MGIS 5500 Report --2026-05-18
    )


    WITH stagedata AS
    (
        SELECT
            (CASE
                WHEN A.V_COMPANY_R = 'RSL' THEN '01'
                WHEN A.V_COMPANY_R = 'FRSL' THEN '02'
                ELSE '00'
             END) AS N_SRC_CARRIER_ID_R,

            '0000' || A.N_BILL_GROUP_R AS N_SRC_POLICY_BILLGROUP_ID_R,
            TO_DATE(A.D_DUE_DATE_R, 'yyyy-MM-dd') AS D_DUE_DATE_R,
            A.N_CLASS_R AS N_SRC_CLASS_ID_R,

            (
                SELECT D_CALENDAR_DATE_R
                FROM DIM_TIME_R
                WHERE V_END_OF_FISCAL_MONTH_IND_R = 'Y'
                  AND EXTRACT(MONTH FROM TO_DATE(A.D_FILE_DATE_R, 'YYYYMMDD HH24:MI:SS')) = EXTRACT(MONTH FROM D_CALENDAR_DATE_R)
                  AND EXTRACT(YEAR FROM TO_DATE(A.D_FILE_DATE_R, 'YYYYMMDD HH24:MI:SS')) = EXTRACT(YEAR FROM D_CALENDAR_DATE_R)
            ) AS D_TRANSACTION_DATE_R,

            (CASE
                WHEN A.V_PREMIUMTYPE_R = 'ADJ' THEN 314
                WHEN A.V_PREMIUMTYPE_R = 'COMM' THEN 313
                WHEN A.V_PREMIUMTYPE_R = 'REV' THEN 344
             END) AS N_PREMIUM_TYPE_R,

            A.N_PREMIUM_AMT_R AS N_AMOUNT_PAID_R,
            TO_DATE(A.D_DUE_DATE_R, 'yyyy-MM-dd') AS D_PAID_TO_DATE_R,
            A.N_LIVES_R AS N_LIVES_R,
            A.N_VOLUME_R AS N_VOLUME_R,
            0 AS N_GROSS_NET_R,
            A.N_PREMIUM_AMT_R AS N_NET_PREMIUM_R,
            NVL(c.N_POLICY_SK_R, -1) AS N_POLICY_SK_R,
            '0000' || A.N_BILL_GROUP_R AS V_BILLGROUPNUMBER_R,
            B.N_RSL_COVERAGE_CODE_R AS V_COVERAGECODE_R,
            A.N_BILLING_MODE_R AS N_MONTHS_PAID_R,
            A.N_BATCH_ID_R,
            A.FIC_MIS_DATE_R,
            A.D_SRC_TRANSACTION_DATE_R, --Added New Column for MGIS 5500 Report --2026-04-15
            A.N_LIVES_ADJ_R AS N_LIVES_ADJ_R  -- Added New Column for MGIS 5500 Report --2026-05-18

        FROM
        (
            SELECT
                D_FILE_DATE_R,
                V_PREFIX_R,
                N_SUFFIX_R,
                MAX(V_COMPANY_R) AS V_COMPANY_R,
                D_DUE_DATE_R,
                N_CLASS_R,
                SUM(N_LIVES_R) AS N_LIVES_R,
                SUM(N_VOLUME_R) AS N_VOLUME_R,
                V_PREMIUMTYPE_R,
                SUM(N_PREMIUM_AMT_R) AS N_PREMIUM_AMT_R,
                N_BILL_GROUP_R,
                V_COVERAGE_CODE_R,
                N_BILLING_MODE_R,
                MAX(N_BATCH_ID_R) AS N_BATCH_ID_R,
                MAX(FIC_MIS_DATE_R) AS FIC_MIS_DATE_R,
                TO_DATE(D_TRANSACTION_DATE_R,'YYYYMMDD') AS D_SRC_TRANSACTION_DATE_R, --Added New Column for MGIS 5500 Report --2026-04-15

                SUM(
                    CASE
                        WHEN N_PREMIUM_AMT_R = 0 THEN 0
                        WHEN N_PREMIUM_AMT_R >= 0 THEN TO_NUMBER(N_LIVES_R)
                        WHEN N_PREMIUM_AMT_R < 0 AND TO_NUMBER(N_LIVES_R) < 0 THEN TO_NUMBER(N_LIVES_R)
                        WHEN N_PREMIUM_AMT_R < 0 AND TO_NUMBER(N_LIVES_R) > 0 THEN TO_NUMBER(N_LIVES_R) * -1
                        ELSE TO_NUMBER(N_LIVES_R)
                    END
                ) AS N_LIVES_ADJ_R  -- Added New Column for MGIS 5500 Report --2026-05-18

            FROM STG_MGIS_RM_PREMIUM_R

            GROUP BY
                D_FILE_DATE_R,
                V_PREFIX_R,
                N_SUFFIX_R,
                N_CLASS_R,
                V_COVERAGE_CODE_R,
                N_BILL_GROUP_R,
                V_PREMIUMTYPE_R,
                N_BILLING_MODE_R,
                D_DUE_DATE_R,
                D_TRANSACTION_DATE_R
        ) A

        LEFT JOIN STG_LKP_MGIS_COVG_CD_R B
            ON A.V_COVERAGE_CODE_R = B.V_COVERAGE_CODE_R

        LEFT JOIN dim_grp_policy_dir_r C
            ON A.V_PREFIX_R = C.V_POLICY_PREFIX_R
           AND LTRIM(A.N_SUFFIX_R,'0') = LTRIM(C.V_POLICY_SUFFIX_R,'0')
           AND C.V_ACTIVE_STATUS_R = 'Y'
    ),

    Finaldata AS
    (
        SELECT
            N_SRC_CARRIER_ID_R,
            N_SRC_POLICY_BILLGROUP_ID_R,
            D_DUE_DATE_R,
            N_SRC_CLASS_ID_R,
            D_TRANSACTION_DATE_R,
            N_PREMIUM_TYPE_R,
            SUM(N_AMOUNT_PAID_R) AS N_AMOUNT_PAID_R,
            D_PAID_TO_DATE_R,
            SUM(N_LIVES_R) AS N_LIVES_R,
            SUM(N_VOLUME_R) AS N_VOLUME_R,
            N_GROSS_NET_R,
            SUM(N_NET_PREMIUM_R) AS N_NET_PREMIUM_R,
            N_POLICY_SK_R,
            V_BILLGROUPNUMBER_R,
            V_COVERAGECODE_R,
            N_MONTHS_PAID_R,
            N_BATCH_ID_R,
            FIC_MIS_DATE_R,
            D_SRC_TRANSACTION_DATE_R,            --Added New Column for MGIS 5500 Report --2026-04-15
            SUM(N_LIVES_ADJ_R) AS N_LIVES_ADJ_R  -- Added New Column for MGIS 5500 Report --2026-05-18

        FROM stagedata

        GROUP BY
            N_SRC_CARRIER_ID_R,
            N_SRC_POLICY_BILLGROUP_ID_R,
            D_DUE_DATE_R,
            N_SRC_CLASS_ID_R,
            D_TRANSACTION_DATE_R,
            N_PREMIUM_TYPE_R,
            D_PAID_TO_DATE_R,
            N_GROSS_NET_R,
            N_POLICY_SK_R,
            V_BILLGROUPNUMBER_R,
            V_COVERAGECODE_R,
            N_MONTHS_PAID_R,
            N_BATCH_ID_R,
            FIC_MIS_DATE_R,
            D_SRC_TRANSACTION_DATE_R
    )

    SELECT
        N_SRC_CARRIER_ID_R,
        N_SRC_POLICY_BILLGROUP_ID_R,
        D_DUE_DATE_R,
        N_SRC_CLASS_ID_R,
        D_TRANSACTION_DATE_R,
        N_PREMIUM_TYPE_R,
        N_AMOUNT_PAID_R,
        D_PAID_TO_DATE_R,
        N_LIVES_R,
        N_VOLUME_R,
        N_GROSS_NET_R,
        N_NET_PREMIUM_R,
        N_POLICY_SK_R,
        V_BILLGROUPNUMBER_R,
        V_COVERAGECODE_R,
        N_MONTHS_PAID_R,
        SYSDATE AS T_EVENT_TIMESTAMP_R,
        'MGIS' AS V_SOURCE_SYSTEM_NAME_R,
        N_BATCH_ID_R,

        (SELECT NVL(MAX(N_LOAD_RUN_ID_R),0)+1
         FROM ATOMIC.FCT_BILLING_POLICY_PREMIUM_R
         WHERE V_SOURCE_SYSTEM_NAME_R ='MGIS'
           AND N_BATCH_ID_R=(SELECT MAX(N_BATCH_ID_R) FROM ATOMIC.STG_MGIS_RM_PREMIUM_R)
        ) AS N_LOAD_RUN_ID_R,

        (SELECT NVL(MAX(N_SEQUENCE_NUMBER_R),0) FROM ATOMIC.FCT_BILLING_POLICY_PREMIUM_R) + ROWNUM AS N_SEQUENCE_NUMBER_R,

        SYSDATE AS T_CREATION_DATE_R,
        SYSDATE AS T_LAST_MODIFIED_DATE_R,
        'Data Lake' AS V_CREATED_BY_R,
        'Data Lake' AS V_LAST_MODIFIED_BY_R,
        FIC_MIS_DATE_R,
        NULL AS F_PHYSICAL_DELETE_R,
        NULL AS V_CHANGE_REASON_R,
        '' AS V_PRIVACY_INDICATOR_R,

        (SELECT NVL(MAX(N_SRC_PREMIUM_PAYMENT_ID_R),0) FROM ATOMIC.FCT_BILLING_POLICY_PREMIUM_R) + ROWNUM AS N_SRC_PREMIUM_PAYMENT_ID_R,

        D_SRC_TRANSACTION_DATE_R,
        N_LIVES_ADJ_R

    FROM Finaldata;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
