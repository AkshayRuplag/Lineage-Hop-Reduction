
WITH root_jobs AS (

SELECT 'EDP_GRP_EDW_LOAD_RPT_AGENT_POLICY_R-UW-10' job_name FROM dual UNION ALL
SELECT 'EDP_GRP_EDW_LOAD_RPT_AGENT_R-UW-11' job_name FROM dual UNION ALL
SELECT 'EDP_GRP_EDW_LOAD_RPT_BILLGROUP_R-UW-1' job_name FROM dual UNION ALL
SELECT 'EDP_GRP_EDW_LOAD_RPT_COMMISSIONS_R-UW-10' job_name FROM dual UNION ALL
SELECT 'EDP_GRP_EDW_LOAD_RPT_EOI_APPLICANT_R-UW-8' job_name FROM dual UNION ALL
SELECT 'EDP_GRP_EDW_LOAD_RPT_FCT_INCURRED_SUMMARY_R-UW-8' job_name FROM dual UNION ALL
SELECT 'EDP_GRP_EDW_LOAD_RPT_FCT_RPT_ANN_PREM_SUMMARY_R-UW-6' job_name FROM dual UNION ALL
SELECT 'EDP_GRP_EDW_LOAD_RPT_FCT_RPT_PREMIUM_SUMMARY_R-27' job_name FROM dual UNION ALL
SELECT 'EDP_GRP_EDW_LOAD_RPT_PAYEE_DTL_R' job_name FROM dual UNION ALL
SELECT 'EDP_GRP_EDW_LOAD_RPT_POSTED_SUSPENSE_R-UW-1' job_name FROM dual UNION ALL
SELECT 'EDP_GRP_EDW_LOAD_RPT_PREMIUM_DTL_R-UW-3' job_name FROM dual UNION ALL
SELECT 'EDP_GRP_EDW_LOAD_RPT_PREMIUM_R-UW-2' job_name FROM dual UNION ALL
SELECT 'EDP_GRP_EDW_LOAD_RPT_QUOTES_DTL_R-26' job_name FROM dual UNION ALL
SELECT 'EDP_GRP_EDW_LOAD_RPT_QUOTES_R-25' job_name FROM dual UNION ALL
SELECT 'EDP_GRP_EDW_LOAD_RPT_RATE_R-UW-9' job_name FROM dual UNION ALL
SELECT 'EDP_GRP_EDW_LOAD_RPT_RESERVE_DETAILS_R-UW-4' job_name FROM dual UNION ALL
SELECT 'EDP_GRP_EDW_LOAD_RPT_FCT_RPT_SALES_REP_R-29' job_name FROM dual UNION ALL
SELECT 'EDP_GRP_EDW_LOAD_RPT_SUSPENSE_DTL_R-UW-2' job_name FROM dual UNION ALL
SELECT 'EDP_GRP_EDW_LOAD_RPT_WORKSHEET_DTL_R-15' job_name FROM dual 

),

/*

SELECT 'EDP_GRP_EDW_LOAD_RPT_AGENT_POLICY_R-UW-10' job_name FROM dual UNION ALL
SELECT 'EDP_GRP_EDW_LOAD_RPT_AGENT_R-UW-11' job_name FROM dual UNION ALL
SELECT 'EDP_GRP_EDW_LOAD_RPT_BILLGROUP_R-UW-1' job_name FROM dual UNION ALL
SELECT 'EDP_GRP_EDW_LOAD_RPT_COMMISSIONS_R-UW-10' job_name FROM dual UNION ALL
SELECT 'EDP_GRP_EDW_LOAD_RPT_EOI_APPLICANT_R-UW-8' job_name FROM dual UNION ALL
SELECT 'EDP_GRP_EDW_LOAD_RPT_FCT_INCURRED_SUMMARY_R-UW-8' job_name FROM dual UNION ALL
SELECT 'EDP_GRP_EDW_LOAD_RPT_FCT_RPT_ANN_PREM_SUMMARY_R-UW-6' job_name FROM dual UNION ALL
SELECT 'EDP_GRP_EDW_LOAD_RPT_FCT_RPT_PREMIUM_SUMMARY_R-27' job_name FROM dual UNION ALL
SELECT 'EDP_GRP_EDW_LOAD_RPT_PAYEE_DTL_R' job_name FROM dual UNION ALL
SELECT 'EDP_GRP_EDW_LOAD_RPT_POSTED_SUSPENSE_R-UW-1' job_name FROM dual UNION ALL
SELECT 'EDP_GRP_EDW_LOAD_RPT_PREMIUM_DTL_R-UW-3' job_name FROM dual UNION ALL
SELECT 'EDP_GRP_EDW_LOAD_RPT_PREMIUM_R-UW-2' job_name FROM dual UNION ALL
SELECT 'EDP_GRP_EDW_LOAD_RPT_QUOTES_DTL_R-26' job_name FROM dual UNION ALL
SELECT 'EDP_GRP_EDW_LOAD_RPT_QUOTES_R-25' job_name FROM dual UNION ALL
SELECT 'EDP_GRP_EDW_LOAD_RPT_RATE_R-UW-9' job_name FROM dual UNION ALL
SELECT 'EDP_GRP_EDW_LOAD_RPT_RESERVE_DETAILS_R-UW-4' job_name FROM dual UNION ALL
SELECT 'EDP_GRP_EDW_LOAD_RPT_FCT_RPT_SALES_REP_R-29' job_name FROM dual UNION ALL
SELECT 'EDP_GRP_EDW_LOAD_RPT_SUSPENSE_DTL_R-UW-2' job_name FROM dual UNION ALL
SELECT 'EDP_GRP_EDW_LOAD_RPT_WORKSHEET_DTL_R-15' job_name FROM dual UNION ALL

*/
-- Recursive dependency chain
duplicate_tidal_deps AS (
    SELECT *
    FROM (
        SELECT t.*,
               ROW_NUMBER() OVER (
                   PARTITION BY job_name, dependent_job
                   ORDER BY prod_date DESC
               ) rn
        FROM TIDAL_DEPS t
    )
    WHERE rn = 1
),

DepChain (root_job, job_name, dependent_job, lvl, path) AS
(
    SELECT
        r.job_name AS root_job,
        jd.job_name,
        jd.dependent_job,
        0,
        '/' || jd.job_name || '/' || jd.dependent_job || '/'
    FROM duplicate_tidal_deps jd
    JOIN root_jobs r
      ON jd.job_name = r.job_name

    UNION ALL

    SELECT
        dc.root_job,
        jd.job_name,
        jd.dependent_job,
        dc.lvl + 1,
        dc.path || jd.dependent_job || '/'
    FROM DepChain dc
    JOIN duplicate_tidal_deps jd
        ON jd.job_name = dc.dependent_job
    WHERE dc.path NOT LIKE '%/' || jd.dependent_job || '/%'
)
--select * from DepChain
-- Extract relevant job + params
,job_data AS (
    SELECT DISTINCT 
        dc.root_job,
        dc.dependent_job,
        jde1.job_id AS dependent_job_id,
        jde1.cmd,
        jde1.params
    FROM DepChain dc
    LEFT JOIN duplicate_tidal_deps jde1
        ON jde1.job_name = dc.dependent_job
    WHERE dc.dependent_job NOT LIKE '%_DL_%'
      AND dc.dependent_job NOT LIKE '%MONTH_END%'
)
--select * from job_data order by dependent_job_id
-- Parse params string into components
,parsed_params AS (
    SELECT
        root_job,
        dependent_job,
        cmd,
        case when cmd LIKE '%srcsys%' then REGEXP_SUBSTR(params, '[^ ]+', 1, 2) else null end AS p_job_name,
        case when cmd like '%srcsys%' then REGEXP_SUBSTR(params, '[^ ]+', 1, 3) else null end AS p_source_system,
        case when cmd like '%srcsys%' then REGEXP_SUBSTR(params, '[^ ]+', 1, 4) else null end as p_grp_sourcetype

    FROM job_data
    --WHERE cmd LIKE '%srcsys%'
      --AND params IS NOT NULL
)
--select * from parsed_params
-- Apply job name logic
,job_name_logic AS (
    SELECT 
        root_job,
        dependent_job,cmd,
        CASE 
            WHEN INSTR(p_grp_sourcetype, 'MULTI') > 0 
                THEN p_source_system || '_' || p_job_name
            ELSE p_job_name
        END AS full_job_name
    FROM parsed_params
)
--select * from job_name_logic
-- Get source/target tables
,tbls AS (
    SELECT 
        j.root_job,
        j.dependent_job,cmd,
        REGEXP_SUBSTR(t.V_PARAM_VALUE_R, '[^~ ]+', 1, 1) AS src_table,
        REGEXP_SUBSTR(t.V_PARAM_VALUE_R, '[^~ ]+', 1, 2) AS tgt_table
    FROM job_name_logic j
    left join ATOMIC.PRCS_GRP_DATAINGESTION_PARAM_R t
    ON t.V_PARAM_NAME_R = j.full_job_name
    and t.F_ENABLE_FLAG_R = 'Y'
)
--select * from tbls
 ,params AS (
  SELECT 
    'D.T_CREATION_DATE_R,D.V_CREATED_BY_R,D.T_LAST_MODIFIED_DATE_R,D.V_LAST_MODIFIED_BY_R,D.N_LOAD_RUN_ID_R' AS gc_auditcols_FACT,
    'SYSDATE,''pkg_grp_load_difw_pd'',SYSDATE,''pkg_grp_load_difw_pd'',1' AS gc_auditcol_values_FACT
  FROM dual
)
--select * from params
SELECT 
    tb.root_job,
    tb.dependent_job,
    tb.cmd,
    tb.src_table,
    tb.tgt_table,
    /*
       '('
       || TRIM((XMLAGG(XMLELEMENT(A,'D.' || t.COLUMN_NAME || ',')
           ORDER BY t.COLUMN_ID).EXTRACT('//text()')).getclobval())
       || p.gc_auditcols_FACT
       || ')' AS source_col,*/

    CASE 
      WHEN tb.tgt_table IS NOT NULL THEN
        '('
        || TRIM((XMLAGG(XMLELEMENT(A,t.COLUMN_NAME || ',')
            ORDER BY t.COLUMN_ID).EXTRACT('//text()')).getclobval())
        || p.gc_auditcols_FACT
        || ')'
    END AS source_col,
   /*    
       '('
       || TRIM((XMLAGG(XMLELEMENT(A,'S.' || t.COLUMN_NAME || ',')
           ORDER BY t.COLUMN_ID).EXTRACT('//text()')).getclobval())
       || p.gc_auditcol_values_FACT
       || ')' AS target_col*/

    CASE 
      WHEN tb.tgt_table IS NOT NULL THEN
        '('
        || TRIM((XMLAGG(XMLELEMENT(A,t.COLUMN_NAME || ',')
            ORDER BY t.COLUMN_ID).EXTRACT('//text()')).getclobval())
        || p.gc_auditcol_values_FACT
        || ')'
    END AS target_col
       
FROM tbls tb
left JOIN (select * from ALL_TAB_COLUMNS  where OWNER = 'ATOMIC' AND COLUMN_NAME NOT IN ('T_CREATION_DATE_R','V_CREATED_BY_R','T_LAST_MODIFIED_DATE_R','V_LAST_MODIFIED_BY_R', 'N_LOAD_RUN_ID_R' ))t
ON t.TABLE_NAME = tb.tgt_table
CROSS JOIN params p
 
GROUP BY tb.root_job,tb.dependent_job,tb.src_table,tb.cmd,
  tb.tgt_table,
  p.gc_auditcols_FACT,
  p.gc_auditcol_values_FACT
ORDER BY tb.root_job, tb.dependent_job;