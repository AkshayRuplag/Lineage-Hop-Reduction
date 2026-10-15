-- Cleaned for lineage: PKG_GRP_LOAD_RPT_CLAIMANT_DTL_R_INC_PRC_DEL_EXT_DATA

gv_trcmsg:='4.1 START: DELETE EXSISTING RECORDS ';

DELETE FROM RPT_CLAIMANT_DTL_R T 
         WHERE EXISTS 
                   (SELECT 1 
                      FROM ( SELECT DISTINCT n_insrd_party_sk_r 
                               FROM DIM_GRP_CLAIM_DETAIL_R_MV_SSL_INC 
                              WHERE  t_last_modified_date_r >= (SELECT max(END_DATE) 
                                                                FROM SSL_PACKAGE_MILESTONE_TABLE 
                                                                WHERE JOB_NAME='PKG_GRP_LOAD_RPT_CLAIMANT_DTL_R_INC'
                                                                )
                                AND n_insrd_party_sk_r>-1
                     UNION
                     SELECT n_party_sk_r 
                       FROM DIM_GRP_PARTY_R 
                      WHERE  n_party_sk_r IN ( SELECT n_party_sk_r 
                                                 FROM (SELECT n_party_sk_r,v_active_status_r,COUNT(1) CNT
                                                         FROM  DIM_GRP_PARTY_R A 
                                                        WHERE n_party_sk_r>-1
                                                     GROUP BY n_party_sk_r,v_active_status_r 
                                                      ) T 
                                                GROUP BY n_party_sk_r HAVING COUNT(1)=1    
                                              ) 
                         AND (v_active_status_r='N' 
                             )
                         AND  t_last_modified_date_r>= ( SELECT max(END_DATE) 
                                                           FROM SSL_PACKAGE_MILESTONE_TABLE 
                                                          WHERE JOB_NAME='PKG_GRP_LOAD_RPT_CLAIMANT_DTL_R_INC'
                                                       )
                         GROUP BY n_party_sk_r
                               ) S 
          WHERE S.n_insrd_party_sk_r=T.n_insrd_party_sk_r
            AND T.N_YEARMONTH_R = gn_current_month
        );

gv_trcmsg:='4.2 END: DELETE EXSISTING RECORDS .Total records deleted : '||ln_rec_cnt;