-- Cleaned for lineage: PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC_PRC_UPD_DEL_DATA

INSERT INTO ATOMIC.SSL_PACKAGE_LOG_TABLE(job_name,process_name, start_date, end_date)
    VALUES ('PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC','START: INSERT NEXT PARTITION RECORDS:', SYSDATE, NULL);

INSERT INTO ATOMIC.SSL_PACKAGE_LOG_TABLE(job_name,process_name, start_date, end_date,SOURCE_TABLE_COUNT)
    VALUES ('PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC','END: INSERT NEXT PARTITION RECORDS:',  NULL,SYSDATE,ln_sqlrowcnt);

INSERT INTO ATOMIC.SSL_PACKAGE_LOG_TABLE(job_name,process_name, start_date, end_date)
    VALUES ('PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC','START: UPDATE PREV MONTH RECORDS TO N ',  NULL,SYSDATE);

INSERT INTO ATOMIC.SSL_PACKAGE_LOG_TABLE(job_name,process_name, start_date, end_date,SOURCE_TABLE_COUNT)
    VALUES ('PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC','END: UPDATE PREV MONTH RECORDS TO N :',  NULL,SYSDATE,ln_sqlrowcnt);

INSERT INTO ATOMIC.SSL_PACKAGE_LOG_TABLE(job_name,process_name, start_date, end_date)
		VALUES ('PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC','START: DELETE EXSISTING AND INACTIVE RECORDS', SYSDATE, NULL);

gc_trcmsg:='2.4 - START: DELETE EXSISTING AND INACTIVE RECORDS '||chr(13);

DELETE FROM ATOMIC.RPT_CLAIM_DTL_R T
		WHERE EXISTS
		(
			SELECT 1 FROM
			(   SELECT
					 A.n_claim_sk_r
					,B.n_claim_coverage_sk_r
					,G.n_claim_coverage_group_sk_r
				FROM
				(
					SELECT * FROM ATOMIC.dim_grp_claim_dir_r
					WHERE
					 t_last_modified_date_r > 
							(   SELECT max(END_DATE)
								FROM ATOMIC.SSL_PACKAGE_MILESTONE_TABLE
								WHERE JOB_NAME='PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC'
							)
				) a
				LEFT JOIN ATOMIC.dim_grp_claim_coverage_r b ON a.n_claim_sk_r = b.n_claim_sk_r 
				LEFT JOIN ATOMIC.dim_grp_claim_coverage_group_r g on b.n_claim_coverage_sk_r = g.n_claim_coverage_sk_r 
			) S
			WHERE 
			S.n_claim_sk_r          = T.n_claim_sk_r
			AND S.n_claim_coverage_sk_r = T.n_claim_coverage_sk_r
			AND S.n_claim_coverage_group_sk_r = T.n_claim_coverage_group_sk_r
			AND T.N_YEARMONTH_R         = gn_current_month
		);

gc_trcmsg:='2.5 - END: DELETE EXSISTING AND INACTIVE RECORDS '||chr(13);

INSERT INTO ATOMIC.SSL_PACKAGE_LOG_TABLE(job_name,process_name, start_date, end_date,SOURCE_TABLE_COUNT)
			VALUES ('PKG_GRP_LOAD_RPT_CLAIM_DTL_R_INC','END: DELETE EXSISTING AND INACTIVE RECORDS:',  NULL,SYSDATE,ln_sqlrowcnt);