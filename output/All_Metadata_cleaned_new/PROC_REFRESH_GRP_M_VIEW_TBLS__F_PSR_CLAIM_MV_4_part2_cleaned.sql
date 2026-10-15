-- Cleaned for lineage: PROC_REFRESH_GRP_M_VIEW_TBLS__F_PSR_CLAIM_MV_4 (part 2/3)

INSERT
			INTO F_PSR_CLAIM_MV_4_TBL
			  (
				N_POLICY_SK_R                              ,
                N_CLAIM_SK_R                               ,
                V_CLAIM_NUMBER_R                           ,
                N_CLAIM_COVERAGE_GROUP_SK_R                ,
                V_CLAIM_IDENTIFIER_R                       ,
                CLAIM_TOTAL_PAID_NET_AMOUNT                ,
                CLAIM_TOTAL_PAID_TAXABLE_AMOUNT            ,
                REHABILITATION_OFFSET_AMOUNT_088           ,
                WORKERS_COMPENSATION_OFFSET_AMOUNT_083     ,
                OTHER_OFFSET_AMOUNTS                       ,
                REHABILITATION_OFFSET_INDICATOR_088        ,
                ACH_INDICATOR                              ,
                LAST_BENEFIT_PAYMENT_DATE                  ,
                V_COV_GROUP_ID_R                           ,
                EARLIEST_BENEFIT_PAYMENT_DATE              ,
                MOST_RECENT_SERVICE_PERIOD_TO_DATE         ,
                MOST_RECENT_SERVICE_PERIOD_FROM_DATE       ,
                WORK_INCENTIVE_EXCESS_OFFSET_INDICATOR_188 ,
                CLAIM_TOTAL_PAID_LOSS_AMOUNT               ,
                CLAIM_MODAL_AMOUNT
			  )
				SELECT
            *
            FROM
              (
              WITH F_BENEFIT_PAYMENT_R AS
              (SELECT
              n_claim_sk_r AS claim_skey,
                max(ACH_INDICATOR) ACH_INDICATOR
              FROM
                ( SELECT
                DISTINCT cd.n_claim_sk_r n_claim_sk_r,
                  CASE
                    WHEN upper(T334051.V_PAY_METHOD_R) = 'ACH'
                    THEN 'Y'
                    ELSE 'N'
                  END AS ACH_indicator
                FROM FCT_BENEFIT_PAYMENT_R T334051,
                  DIM_GRP_POLICY_DIR_R T333136,
                  dim_grp_claim_dir_r cd
                WHERE T333136.N_POLICY_SK_R           = T334051.N_POLICY_SK_R
                AND T333136.V_ACTIVE_STATUS_R         ='Y'
                and cd.n_claim_sk_r = T334051.n_claim_sk_r
                and cd.n_policy_sk_r = T333136.N_policy_sk_r
                and cd.v_active_status_r = 'Y'
                and cd.v_lob_type_r in ('LTD', 'STD', 'VPS', 'VPL')
                )
              GROUP BY n_claim_sk_r
              )
          ,
              F_CLAIM_PAYMENT_DETAIL_R AS
              (SELECT
              N_POLICY_SK_R AS POLICY_SKEY,
                V_CLAIM_NUMBER_R CLAIM_NUMBER,
                n_claim_sk_r claim_skey,
                CLAIM_TOTAL_PAID_NET_AMOUNT,
                  CLAIM_TOTAL_PAID_TAXABLE_AMOUNT,
                     CLAIM_TOTAL_PAID_LOSS_AMOUNT,
                rehabilitation_offset_amount_088,
                workers_compensation_offset_amount_083,
                other_offset_amounts,
                rehabilitation_offset_indicator_088,
                work_incentive_excess_offset_indicator_188
              FROM
                (SELECT
                T333136.N_POLICY_SK_R,
                  T333511.V_CLAIM_NUMBER_R,
                  T333511.N_CLAIM_SK_R,
                           sum(case  when upper(T425786.V_RECORD_TYPE_R) = 'REDIRECT'
                           then nvl(T425786.N_PAID_AMOUNT_R , 0) when T425786.V_CHECK_TYPE_R not in ('OE') and upper(T425786.V_RECORD_TYPE_R) = 'BENEFIT PAYMENT'
                           and T425786.V_BENEFIT_GROUP_R in ('FIC', 'MED') then nvl(T425786.N_PAID_CLAIM_BENEFITS_R , 0) * -1 when T425786.V_CHECK_TYPE_R not in ('OE')
                           and upper(T425786.V_RECORD_TYPE_R) = 'ADJUSTMENT' and T425786.V_BENEFIT_GROUP_R in ('FIC', 'MED') then nvl(T425786.N_PAID_CLAIM_BENEFITS_R , 0)
                           when T425786.V_CHECK_TYPE_R not in ('OE') and not T425786.V_BENEFIT_GROUP_R in ('FIC', 'MED') then nvl(T425786.N_PAID_CLAIM_BENEFITS_R , 0) else 0 end )
                           AS Claim_total_paid_loss_amount ,
                    sum(case  when T425786.V_CHECK_TYPE_R not in ('OE') and not T425786.V_BENEFIT_GROUP_R in ('FIC', 'MED') then T425786.N_PAID_AMOUNT_R else 0 end )
                    AS CLAIM_TOTAL_PAID_NET_AMOUNT,
                   sum(case  when T425786.V_CHECK_TYPE_R not in ('OE') and not T425786.V_BENEFIT_GROUP_R in ('FIC', 'MED') then T425786.N_PAID_AMOUNT_R else 0 end ) AS CLAIM_TOTAL_PAID_TAXABLE_AMOUNT,
                     max(  case  WHEN T425786.v_benefit_code_r = '188' THEN
               'Y'
            ELSE
                NULL
        END)as work_incentive_excess_offset_indicator_188,
    SUM(
       CASE
            WHEN T425786.v_benefit_code_r = '088' THEN
                T425786.n_paid_amount_r
                else 0
        END
    )                                                                                                       AS rehabilitation_offset_amount_088
    ,
    SUM(
        CASE
            WHEN T425786.v_benefit_code_r = '083' THEN
                T425786.n_paid_amount_r
                else 0
        END
   )                                                                                                       AS workers_compensation_offset_amount_083
  ,
    SUM(
        CASE
          WHEN T425786.v_benefit_code_r IN('087', '08B', '090', '091', '186',
                                                                '188') THEN
                T425786.n_paid_amount_r
                else 0
        END
    )                                                                                                       AS other_offset_amounts,
    MAX(
        CASE
            WHEN T425786.v_benefit_code_r = '088' THEN
               'Y'
            ELSE
                null
        END
    )                                                                                                       AS rehabilitation_offset_indicator_088
                FROM (SELECT * FROM FCT_CLAIM_PAYMENT_DETAIL_R WHERE n_claim_coverage_group_sk_r = -1) T425786,
                  DIM_GRP_POLICY_DIR_R T333136
                  ,
                  DIM_GRP_CLAIM_DIR_R T333511
                WHERE T333136.N_POLICY_SK_R   = T333511.N_POLICY_SK_R
                AND T333511.V_CLAIM_NUMBER_R  = T425786.V_CLAIM_NUMBER_R
                AND T333136.V_ACTIVE_STATUS_R ='Y'
                AND T333511.V_ACTIVE_STATUS_R ='Y'
                and T333511.v_lob_type_r in  ('LTD', 'STD', 'VPS', 'VPL')
                GROUP BY T333136.N_POLICY_SK_R,
                  T333511.V_CLAIM_NUMBER_R,
                  T333511.n_claim_sk_r
                )
              ),
              F_GRP_WORKSHEET AS
              (SELECT
              T333511.V_CLAIM_NUMBER_R,
                SUM(T357789.N_GROSS_BENEFIT_R) AS CLAIM_TOTAL_PAID_GROSS_AMT,
                SUM(T357789.N_MODAL_AMOUNT_R)  AS Claim_modal_amount
              FROM DIM_GRP_CLAIM_DIR_R T333511,
                DIM_GRP_CLAIM_COVERAGE_R T357788
                ,
                FCT_GRP_WORKSHEET T357789
              WHERE T333511.N_CLAIM_SK_R        = T357788.N_CLAIM_SK_R
              AND T357788.N_CLAIM_COVERAGE_SK_R = T357789.N_CLAIM_COVERAGE_SK_R
              AND T333511.V_ACTIVE_STATUS_R     ='Y'
              AND T357788.V_ACTIVE_STATUS_R     ='Y'
              and T333511.v_lob_type_r in ('LTD', 'STD', 'VPL', 'VPS')
              GROUP BY T333511.V_CLAIM_NUMBER_R
              )
              ,
              payment_dates as   (
    SELECT v_claim_number_r,
    V_COV_GROUP_ID_R,
    MAX(d_paid_date_r) last_benefit_payment_date,
     min(d_paid_date_r) Earliest_benefit_payment_date,
     max(D_SERVICE_PERIOD_TO_R) MOST_RECENT_SERVICE_PERIOD_TO_DATE,
     max(D_SERVICE_PERIOD_FROM_R) MOST_RECENT_SERVICE_PERIOD_FROM_DATE
  FROM
    (SELECT a.v_claim_number_r,
      d_paid_date_r,
      N_SOURCE_VERSION_SEQ_NUMBER_R,
      SUM(N_PAID_AMOUNT_R),
      V_COV_GROUP_ID_R,
      D_SERVICE_PERIOD_FROM_R,
      D_SERVICE_PERIOD_TO_R
    FROM fct_claim_payment_detail_r a, dim_grp_claim_dir_r b
    WHERE V_CHECK_TYPE_R      <> 'OE'
    AND V_BENEFIT_GROUP_R NOT IN ('FIC', 'MED')
    and a.n_claim_sk_r = b.n_claim_sk_r
    and b.v_active_status_r = 'Y'
    and b.v_lob_type_r in ('LTD', 'STD', 'VPL', 'VPS')
    GROUP BY a.v_claim_number_r,
      d_paid_date_r,
      N_SOURCE_VERSION_SEQ_NUMBER_R,
      V_COV_GROUP_ID_R,
            D_SERVICE_PERIOD_FROM_R,
      D_SERVICE_PERIOD_TO_R
    HAVING SUM(N_PAID_AMOUNT_R) >0
    )
  GROUP BY v_claim_number_r,
    V_COV_GROUP_ID_R)
            SELECT
            DIM_GRP_POLICY_DIR_R.N_POLICY_SK_R,
              DIM_GRP_CLAIM_DIR_R.n_claim_sk_r,
              DIM_GRP_CLAIM_DIR_R.v_claim_number_r,
             -1 N_CLAIM_COVERAGE_GROUP_SK_R,
             DIM_GRP_CLAIM_DIR_R.v_claim_number_r V_CLAIM_IDENTIFIER_R,
              CLAIM_TOTAL_PAID_NET_AMOUNT,
              CLAIM_TOTAL_PAID_TAXABLE_AMOUNT,
              REHABILITATION_OFFSET_AMOUNT_088,
              WORKERS_COMPENSATION_OFFSET_AMOUNT_083,
              OTHER_OFFSET_AMOUNTS,
              REHABILITATION_OFFSET_INDICATOR_088,
              ACH_INDICATOR,
              LAST_BENEFIT_PAYMENT_DATE,
              V_COV_GROUP_ID_R,
              EARLIEST_BENEFIT_PAYMENT_DATE,
              MOST_RECENT_SERVICE_PERIOD_TO_DATE,
              MOST_RECENT_SERVICE_PERIOD_FROM_DATE,
              work_incentive_excess_offset_indicator_188,
              CLAIM_TOTAL_PAID_LOSS_AMOUNT,
              Claim_modal_amount
            FROM
             F_CLAIM_PAYMENT_DETAIL_R F_CLAIM_PAYMENT_DETAIL_R
             inner  JOIN DIM_GRP_CLAIM_DIR_R DIM_GRP_CLAIM_DIR_R
 ON DIM_GRP_CLAIM_DIR_R.N_CLAIM_SK_R = F_CLAIM_PAYMENT_DETAIL_R.CLAIM_SKEY
           inner join  DIM_GRP_POLICY_DIR_R DIM_GRP_POLICY_DIR_R
                       ON DIM_GRP_POLICY_DIR_R.N_POLICY_SK_R = DIM_GRP_CLAIM_DIR_R.N_POLICY_SK_r
            inner JOIN FCT_GRP_POLICY_R FCT_GRP_POLICY_R
            ON DIM_GRP_POLICY_DIR_R.N_POLICY_SK_R              = FCT_GRP_POLICY_R.N_POLICY_SK_R
            AND DIM_GRP_POLICY_DIR_R.N_POLICY_VERSION_NUMBER_R = FCT_GRP_POLICY_R.N_VERSION_NUMBER_R
            LEFT OUTER JOIN F_BENEFIT_PAYMENT_R F_BENEFIT_PAYMENT_R
            ON DIM_GRP_CLAIM_DIR_R.n_claim_sk_r = F_BENEFIT_PAYMENT_R.claim_skey
            LEFT OUTER JOIN F_GRP_WORKSHEET F_GRP_WORKSHEET
            ON DIM_GRP_CLAIM_DIR_R.v_claim_number_r     = F_GRP_WORKSHEET.v_claim_number_r
            left outer join payment_dates
            on payment_dates.v_claim_number_r =F_CLAIM_PAYMENT_DETAIL_R.CLAIM_NUMBER
            WHERE DIM_GRP_CLAIM_DIR_R.V_ACTIVE_STATUS_R ='Y'
            AND DIM_GRP_POLICY_DIR_R.V_ACTIVE_STATUS_R  ='Y'
            and DIM_GRP_CLAIM_DIR_R.v_lob_type_r in ('LTD', 'STD', 'VPL', 'VPS'))
         UNION
         SELECT
            *
            FROM
              (
              WITH F_BENEFIT_PAYMENT_R AS
              (SELECT
              n_claim_sk_r AS claim_skey,
                max(ACH_INDICATOR) ACH_INDICATOR
              FROM
                ( SELECT
                DISTINCT cd.n_claim_sk_r n_claim_sk_r,
                  CASE
                    WHEN upper(T334051.V_PAY_METHOD_R) = 'ACH'
                    THEN 'Y'
                    ELSE 'N'
                  END AS ACH_indicator
                FROM FCT_BENEFIT_PAYMENT_R T334051,
                  DIM_GRP_POLICY_DIR_R T333136,
                  dim_grp_claim_dir_r cd
                WHERE T333136.N_POLICY_SK_R           = T334051.N_POLICY_SK_R
                AND T333136.V_ACTIVE_STATUS_R         ='Y'
                and cd.n_claim_sk_r = T334051.n_claim_sk_r
                and cd.n_policy_sk_r = T333136.N_policy_sk_r
                and cd.v_active_status_r = 'Y'
                and cd.v_lob_type_r in ('LIFE', 'NONS', 'LTD')
                )
              GROUP BY n_claim_sk_r
              )
          ,
              F_CLAIM_PAYMENT_DETAIL_R AS
              (SELECT
              N_POLICY_SK_R AS POLICY_SKEY,
                V_CLAIM_NUMBER_R CLAIM_NUMBER,
                n_claim_sk_r claim_skey,
                n_claim_coverage_group_sk_r,
                CLAIM_TOTAL_PAID_NET_AMOUNT,
                  CLAIM_TOTAL_PAID_TAXABLE_AMOUNT,
                     CLAIM_TOTAL_PAID_LOSS_AMOUNT,
                rehabilitation_offset_amount_088,
                workers_compensation_offset_amount_083,
                other_offset_amounts,
                rehabilitation_offset_indicator_088,
                V_CLAIM_IDENTIFIER_R,
                work_incentive_excess_offset_indicator_188
              FROM
                (SELECT
                T333136.N_POLICY_SK_R,
                  T333511.V_CLAIM_NUMBER_R,
                  T333511.N_CLAIM_SK_R,
                  T425786.n_claim_coverage_group_sk_r,
                           sum(case  when upper(T425786.V_RECORD_TYPE_R) = 'REDIRECT'
                           then nvl(T425786.N_PAID_AMOUNT_R , 0) when T425786.V_CHECK_TYPE_R not in ('OE') and upper(T425786.V_RECORD_TYPE_R) = 'BENEFIT PAYMENT'
                           and T425786.V_BENEFIT_GROUP_R in ('FIC', 'MED') then nvl(T425786.N_PAID_CLAIM_BENEFITS_R , 0) * -1 when T425786.V_CHECK_TYPE_R not in ('OE')
                           and upper(T425786.V_RECORD_TYPE_R) = 'ADJUSTMENT' and T425786.V_BENEFIT_GROUP_R in ('FIC', 'MED') then nvl(T425786.N_PAID_CLAIM_BENEFITS_R , 0)
                           when T425786.V_CHECK_TYPE_R not in ('OE') and not T425786.V_BENEFIT_GROUP_R in ('FIC', 'MED') then nvl(T425786.N_PAID_CLAIM_BENEFITS_R , 0) else 0 end )
                           AS Claim_total_paid_loss_amount ,
                    sum(case  when T425786.V_CHECK_TYPE_R not in ('OE') and not T425786.V_BENEFIT_GROUP_R in ('FIC', 'MED') then T425786.N_PAID_AMOUNT_R else 0 end )
                    AS CLAIM_TOTAL_PAID_NET_AMOUNT,
                   sum(case  when T425786.V_CHECK_TYPE_R not in ('OE') and not T425786.V_BENEFIT_GROUP_R in ('FIC', 'MED') then T425786.N_PAID_AMOUNT_R else 0 end ) AS CLAIM_TOTAL_PAID_TAXABLE_AMOUNT,
                     max(  case  WHEN T425786.v_benefit_code_r = '188' THEN
               'Y'
            ELSE
                NULL
        END)as work_incentive_excess_offset_indicator_188,
    SUM(
       CASE
            WHEN T425786.v_benefit_code_r = '088' THEN
                T425786.n_paid_amount_r
                else 0
        END
    )                                                                                                       AS rehabilitation_offset_amount_088
    ,
    SUM(
        CASE
            WHEN T425786.v_benefit_code_r = '083' THEN
                T425786.n_paid_amount_r
                else 0
        END
   )                                                                                                       AS workers_compensation_offset_amount_083
  ,
    SUM(
        CASE
          WHEN T425786.v_benefit_code_r IN('087', '08B', '090', '091', '186',
                                                                '188') THEN
                T425786.n_paid_amount_r
                else 0
        END
    )                                                                                                       AS other_offset_amounts,
    MAX(
        CASE
            WHEN T425786.v_benefit_code_r = '088' THEN
               'Y'
            ELSE
                null
        END
    )                                                                                                       AS rehabilitation_offset_indicator_088,
                                    CG.V_CLAIM_IDENTIFIER_R AS V_CLAIM_IDENTIFIER_R
                FROM FCT_CLAIM_PAYMENT_DETAIL_R T425786,
                  DIM_GRP_POLICY_DIR_R T333136
                  ,
                  DIM_GRP_CLAIM_DIR_R T333511
                  ,
                  DIM_GRP_CLAIM_COVERAGE_GROUP_R CG
                WHERE T333136.N_POLICY_SK_R   = T333511.N_POLICY_SK_R
                AND T333511.V_CLAIM_NUMBER_R  = T425786.V_CLAIM_NUMBER_R
                AND T333136.V_ACTIVE_STATUS_R ='Y'
                AND T333511.V_ACTIVE_STATUS_R ='Y'
                and T333511.v_lob_type_r in ('WOP', 'NONS', 'LIFE')
                AND CG.N_CLAIM_COVERAGE_GROUP_SK_R = T425786.N_CLAIM_COVERAGE_GROUP_SK_R
                AND CG.N_CLAIM_SK_R = T425786.N_CLAIM_SK_R
                AND CG.V_ACTIVE_STATUS_R = 'Y'
                GROUP BY T333136.N_POLICY_SK_R,
                  T333511.V_CLAIM_NUMBER_R,
                  T425786.n_claim_coverage_group_sk_r,
                  CG.V_CLAIM_IDENTIFIER_R,
                  T333511.n_claim_sk_r
                )
              ),
              F_GRP_WORKSHEET AS
              (SELECT
              T333511.V_CLAIM_NUMBER_R,
                SUM(T357789.N_GROSS_BENEFIT_R) AS CLAIM_TOTAL_PAID_GROSS_AMT,
                SUM(T357789.N_MODAL_AMOUNT_R)  AS Claim_modal_amount,
                T357774.n_claim_coverage_group_sk_r
              FROM DIM_GRP_CLAIM_DIR_R T333511,
                DIM_GRP_CLAIM_COVERAGE_R T357788
                ,
                DIM_GRP_CLAIM_COVERAGE_GROUP_R T357774
                ,
                FCT_GRP_WORKSHEET T357789
              WHERE T333511.N_CLAIM_SK_R        = T357788.N_CLAIM_SK_R
              AND T357774.N_CLAIM_COVERAGE_SK_R = T357788.N_CLAIM_COVERAGE_SK_R
              AND T357788.N_CLAIM_COVERAGE_SK_R = T357789.N_CLAIM_COVERAGE_SK_R
              and T357789.n_claim_coverage_group_sk_r = T357774.n_claim_coverage_group_sk_r
              AND T333511.V_ACTIVE_STATUS_R     ='Y'
              AND T357788.V_ACTIVE_STATUS_R     ='Y'
              AND T357774.V_ACTIVE_STATUS_R     ='Y'
              and T333511.v_lob_type_r in ('NONS', 'WOP', 'LIFE')
              GROUP BY T333511.V_CLAIM_NUMBER_R,T357774.n_claim_coverage_group_sk_r
              )
              ,
              payment_dates as   (
    SELECT v_claim_number_r,
    N_CLAIM_COVERAGE_GROUP_SK_R,
    V_COV_GROUP_ID_R,
    MAX(d_paid_date_r) last_benefit_payment_date,
     min(d_paid_date_r) Earliest_benefit_payment_date,
     max(D_SERVICE_PERIOD_TO_R) MOST_RECENT_SERVICE_PERIOD_TO_DATE,
     max(D_SERVICE_PERIOD_FROM_R) MOST_RECENT_SERVICE_PERIOD_FROM_DATE
  FROM
    (SELECT a.v_claim_number_r,
      d_paid_date_r,
      N_SOURCE_VERSION_SEQ_NUMBER_R,
      SUM(N_PAID_AMOUNT_R),
      N_CLAIM_COVERAGE_GROUP_SK_R,
      V_COV_GROUP_ID_R,
      D_SERVICE_PERIOD_FROM_R,
      D_SERVICE_PERIOD_TO_R
    FROM fct_claim_payment_detail_r a, dim_grp_claim_dir_r b
    WHERE V_CHECK_TYPE_R      <> 'OE'
    AND V_BENEFIT_GROUP_R NOT IN ('FIC', 'MED')
    and a.v_lob_type_r in ('LIFE', 'NONS', 'WOP')
    and a.n_claim_sk_r = b.n_claim_sk_r
    and b.v_active_status_r = 'Y'
    and b.v_lob_type_r in ('LIFE', 'NONS', 'WOP')
    GROUP BY a.v_claim_number_r,
      d_paid_date_r,
      N_SOURCE_VERSION_SEQ_NUMBER_R,
      N_CLAIM_COVERAGE_GROUP_SK_R,
      V_COV_GROUP_ID_R,
            D_SERVICE_PERIOD_FROM_R,
      D_SERVICE_PERIOD_TO_R
    HAVING SUM(N_PAID_AMOUNT_R) >0
    )
  GROUP BY v_claim_number_r,
    N_CLAIM_COVERAGE_GROUP_SK_R,
    V_COV_GROUP_ID_R)
            SELECT
            DIM_GRP_POLICY_DIR_R.N_POLICY_SK_R,
              DIM_GRP_CLAIM_DIR_R.n_claim_sk_r,
              DIM_GRP_CLAIM_DIR_R.v_claim_number_r,
              F_CLAIM_PAYMENT_DETAIL_R.N_CLAIM_COVERAGE_GROUP_SK_R,
              V_CLAIM_IDENTIFIER_R,
              CLAIM_TOTAL_PAID_NET_AMOUNT,
              CLAIM_TOTAL_PAID_TAXABLE_AMOUNT,
              REHABILITATION_OFFSET_AMOUNT_088,
              WORKERS_COMPENSATION_OFFSET_AMOUNT_083,
              OTHER_OFFSET_AMOUNTS,
              REHABILITATION_OFFSET_INDICATOR_088,
              ACH_INDICATOR,
              LAST_BENEFIT_PAYMENT_DATE,
              V_COV_GROUP_ID_R,
              EARLIEST_BENEFIT_PAYMENT_DATE,
              MOST_RECENT_SERVICE_PERIOD_TO_DATE,
              MOST_RECENT_SERVICE_PERIOD_FROM_DATE,
              work_incentive_excess_offset_indicator_188,
              CLAIM_TOTAL_PAID_LOSS_AMOUNT,
              Claim_modal_amount
            FROM
             F_CLAIM_PAYMENT_DETAIL_R F_CLAIM_PAYMENT_DETAIL_R
             inner  JOIN DIM_GRP_CLAIM_DIR_R DIM_GRP_CLAIM_DIR_R
 ON DIM_GRP_CLAIM_DIR_R.N_CLAIM_SK_R = F_CLAIM_PAYMENT_DETAIL_R.CLAIM_SKEY
           inner join  DIM_GRP_POLICY_DIR_R DIM_GRP_POLICY_DIR_R
                       ON DIM_GRP_POLICY_DIR_R.N_POLICY_SK_R = DIM_GRP_CLAIM_DIR_R.N_POLICY_SK_r
            inner JOIN FCT_GRP_POLICY_R FCT_GRP_POLICY_R
            ON DIM_GRP_POLICY_DIR_R.N_POLICY_SK_R              = FCT_GRP_POLICY_R.N_POLICY_SK_R
            AND DIM_GRP_POLICY_DIR_R.N_POLICY_VERSION_NUMBER_R = FCT_GRP_POLICY_R.N_VERSION_NUMBER_R
            LEFT OUTER JOIN F_BENEFIT_PAYMENT_R F_BENEFIT_PAYMENT_R
            ON DIM_GRP_CLAIM_DIR_R.n_claim_sk_r = F_BENEFIT_PAYMENT_R.claim_skey
            LEFT OUTER JOIN F_GRP_WORKSHEET F_GRP_WORKSHEET
            ON DIM_GRP_CLAIM_DIR_R.v_claim_number_r     = F_GRP_WORKSHEET.v_claim_number_r
            and F_GRP_WORKSHEET.n_claim_coverage_group_sk_r = F_CLAIM_PAYMENT_DETAIL_R.n_claim_coverage_group_sk_r
            left outer join payment_dates
            on payment_dates.N_CLAIM_COVERAGE_GROUP_SK_R =F_CLAIM_PAYMENT_DETAIL_R.n_claim_coverage_group_sk_r
            WHERE DIM_GRP_CLAIM_DIR_R.V_ACTIVE_STATUS_R ='Y'
            AND DIM_GRP_POLICY_DIR_R.V_ACTIVE_STATUS_R  ='Y'
            and DIM_GRP_CLAIM_DIR_R.v_lob_type_r in ('LIFE', 'NONS', 'WOP'));