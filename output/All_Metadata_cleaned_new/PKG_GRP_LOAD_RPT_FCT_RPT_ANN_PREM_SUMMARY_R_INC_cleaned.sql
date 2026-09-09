-- Cleaned for lineage: PKG_GRP_LOAD_RPT_FCT_RPT_ANN_PREM_SUMMARY_R_INC

INSERT INTO ATOMIC.SSL_PACKAGE_LOG_TABLE(job_name,process_name, start_date, end_date) 
	VALUES (&apos;PKG_GRP_LOAD_RPT_FCT_RPT_ANN_PREM_SUMMARY_R_INC&apos;,&apos;START:SET PREV FIN MONTH STATUS = N&apos;, SYSDATE, NULL);

UPDATE ATOMIC.RPT_FCT_RPT_ANN_PREM_SUMMARY_R
	   SET v_rpt_active_status_r=&apos;

INSERT INTO ATOMIC.SSL_PACKAGE_LOG_TABLE(job_name,process_name, start_date, end_date) 
	VALUES (&apos;PKG_GRP_LOAD_RPT_FCT_RPT_ANN_PREM_SUMMARY_R_INC&apos;,&apos;END:SET PREV FIN MONTH STATUS = N&apos;, NULL, SYSDATE);

INSERT INTO ATOMIC.SSL_PACKAGE_LOG_TABLE(job_name,process_name, start_date, end_date) 
	VALUES (&apos;PKG_GRP_LOAD_RPT_FCT_RPT_ANN_PREM_SUMMARY_R_INC&apos;,&apos;START:TRUNCATE-&apos;||gn_current_month ||&apos;-PARTITION DATA&apos;, SYSDATE, NULL);

INSERT INTO ATOMIC.SSL_PACKAGE_LOG_TABLE(job_name,process_name, start_date, end_date) 
	VALUES (&apos;PKG_GRP_LOAD_RPT_FCT_RPT_ANN_PREM_SUMMARY_R_INC&apos;,&apos;END:TRUNCATE-&apos;||gn_current_month ||&apos;-PARTITION DATA&apos;, NULL, SYSDATE);

INSERT INTO ATOMIC.SSL_PACKAGE_LOG_TABLE(job_name,process_name, start_date, end_date,SOURCE_TABLE_COUNT) 
	VALUES (&apos;PKG_GRP_LOAD_RPT_FCT_RPT_ANN_PREM_SUMMARY_R_INC&apos;,&apos;START: DATA LOAD TO RPT_FCT_RPT_ANN_PREM_SUMMARY_R&apos;, SYSDATE, NULL,ln_rec_cnt);