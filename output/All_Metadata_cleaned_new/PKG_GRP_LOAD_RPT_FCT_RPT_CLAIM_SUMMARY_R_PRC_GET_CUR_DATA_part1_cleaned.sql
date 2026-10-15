-- Cleaned for lineage: PKG_GRP_LOAD_RPT_FCT_RPT_CLAIM_SUMMARY_R_PRC_GET_CUR_DATA (part 1/3)

INSERT  INTO RPT_FCT_RPT_CLAIM_SUMMARY_R VALUES lt_var_tbl_typ(x);

Merge into RPT_FCT_RPT_CLAIM_SUMMARY_R table from main '||chr(13);

MERGE  INTO rpt_fct_rpt_claim_summary_r TAB1
			USING (SELECT  V_CLAIM_IDENTIFIER_R, max(a.n_claim_sk_r) n_claim_sk_r , max(B.N_PRODUCT_SK_R) N_PRODUCT_SK_R, MAX(B.N_cuST_PARTY_SK_R) N_PARTY_SK_R, MAX(B.N_POLICY_SK_R) N_POLICY_SK_R,
			MAX(B.N_INSRD_PARTY_SK_R)N_INSRD_PARTY_SK_R, MAX(B.N_EMPLOYEE_SK_R) N_EMPLOYEE_SK_R,MAX(B.N_ORIGINAL_FACE_AMOUNT_R) N_ORIGINAL_FACE_AMOUNT_R
			from rpt_claim_dtl_r a, rpt_claim_sum_r b
		where a.n_claim_sk_r = b.n_claim_sk_r
		and a.n_claim_coverage_sk_r = b.n_claim_coverage_sk_r
		and a.n_claim_coverage_group_sk_r = b.n_claim_coverage_group_sk_r
		and a.n_yearmonth_r=gn_current_month
		and b.n_yearmonth_r=gn_current_month
		group by V_CLAIM_IDENTIFIER_R) TAB2
			ON (TAB1.V_CLAIM_IDENTIFIER_R = TAB2.V_CLAIM_IDENTIFIER_R)
		  WHEN MATCHED THEN
			UPDATE SET TAB1.n_claim_sk_r = TAB2.n_claim_sk_r,
			TAB1.N_PRODUCT_SK_R = TAB2.N_PRODUCT_SK_R,
			TAB1.N_PARTY_SK_R = TAB2.N_PARTY_SK_R,
			TAB1.N_POLICY_SK_R = TAB2.N_POLICY_SK_R,
			TAB1.N_INSRD_PARTY_SK_R = TAB2.N_INSRD_PARTY_SK_R,
			TAB1.N_EMPLOYEE_SK_R = TAB2.N_EMPLOYEE_SK_R,
			TAB1.N_ORIGINAL_FACE_AMOUNT_R = TAB2.N_ORIGINAL_FACE_AMOUNT_R
			 WHERE
				 TO_CHAR(TAB1.D_CYCLE_DATE_R,'YYYYMM')=GN_CURRENT_MONTH;

Merge into RPT_FCT_RPT_CLAIM_SUMMARY_R table from main completed';

gc_trcmsg:='6.5 Update Claim Attributes from main ';

UPDATE RPT_FCT_RPT_CLAIM_SUMMARY_R
				  set n_avg_claim_decision_days_r     =lt_upd_claim_attr_tbl_typ(X).n_avg_claim_decision_days_r
				  , n_claim_approach_dur_r           =lt_upd_claim_attr_tbl_typ(X).n_claim_approach_dur_r
				  , n_claim_approach_exp_resolution_r=lt_upd_claim_attr_tbl_typ(X).n_claim_approach_exp_resolution_r
				  , n_duration_remaining_r           =lt_upd_claim_attr_tbl_typ(X).n_duration_remaining_r
				where rowid=lt_upd_claim_attr_tbl_typ(X).row_id;

gc_trcmsg:='7. Update Claim Attributes completed from main ';

MERGE  INTO rpt_fct_rpt_claim_summary_r TAB1
			USING (SELECT  V_CLAIM_IDENTIFIER_R, max(a.n_claim_sk_r) n_claim_sk_r , max(B.N_PRODUCT_SK_R) N_PRODUCT_SK_R, MAX(B.N_cuST_PARTY_SK_R) N_PARTY_SK_R, MAX(B.N_POLICY_SK_R) N_POLICY_SK_R,
			MAX(B.N_INSRD_PARTY_SK_R)N_INSRD_PARTY_SK_R, MAX(B.N_EMPLOYEE_SK_R) N_EMPLOYEE_SK_R, max(a.n_claim_coverage_sk_r)n_claim_coverage_sk_r,max(a.n_claim_coverage_group_sk_r)n_claim_coverage_group_sk_r
			from rpt_claim_dtl_r a, rpt_claim_sum_r b
		where
			a.n_yearmonth_r=gn_current_month
		and b.n_yearmonth_r=gn_current_month
		and a.n_claim_coverage_group_sk_r = b.n_claim_coverage_group_sk_r
		and a.n_claim_coverage_sk_r = b.n_claim_coverage_sk_r
		and a.n_claim_sk_r = b.n_claim_sk_r
		group by V_CLAIM_IDENTIFIER_R) TAB2
			ON (substr(TAB1.V_CLAIM_IDENTIFIER_R,0,length(TAB1.V_CLAIM_IDENTIFIER_R)-3) = TAB2.V_CLAIM_IDENTIFIER_R)
		  WHEN MATCHED THEN
			UPDATE SET TAB1.n_claim_sk_r = TAB2.n_claim_sk_r,
			TAB1.N_PRODUCT_SK_R = TAB2.N_PRODUCT_SK_R,
			TAB1.N_PARTY_SK_R = TAB2.N_PARTY_SK_R,
			TAB1.N_POLICY_SK_R = TAB2.N_POLICY_SK_R,
			TAB1.N_INSRD_PARTY_SK_R = TAB2.N_INSRD_PARTY_SK_R,
			TAB1.N_EMPLOYEE_SK_R = TAB2.N_EMPLOYEE_SK_R,
			TAB1.n_claim_coverage_sk_r = TAB2.n_claim_coverage_sk_r,
			TAB1.n_claim_coverage_group_sk_r =TAB2.n_claim_coverage_group_sk_r
			where tab1.n_yearmonth_r=gn_current_month
			and tab1.V_COVERAGE_GROUP_ID_R = 'DF';

MERGE  INTO rpt_fct_rpt_claim_summary_r TAB1
		USING (select n_claim_coverage_group_sk_r from (select
			   case when N_CLAIM_CVRG_GRP_SRC_SYS_KEY_R is null
			   then
			   case when
			   rank() over(partition by n_claim_sk_r order by nvl(N_CLAIM_CVRG_GRP_SRC_SYS_KEY_R,0) desc) = 1
			   then 1
			   else 0 end
			   else 1 end DF_CVG, c.v_claim_number_r, c.v_claim_identifier_r, c.N_CLAIM_CVRG_GRP_SRC_SYS_KEY_R, c.n_claim_coverage_group_sk_r
			   from  atomic.DIM_GRP_CLAIM_COVERAGE_GROUP_R c
			   where V_ACTIVE_STATUS_R = 'Y') where DF_CVG = 0) TAB2
		ON (TAB1.n_claim_coverage_group_sk_r = TAB2.n_claim_coverage_group_sk_r)
		WHEN MATCHED THEN
		UPDATE SET TAB1.n_claim_sk_r = -1,
				  TAB1.n_claim_coverage_sk_r = -1
		where tab1.n_yearmonth_r=gn_current_month
		and tab1.V_COVERAGE_GROUP_ID_R = 'DF';

-- REF CURSOR lineage (OPEN ... FOR SELECT -> INSERT INTO RPT_FCT_RPT_CLAIM_SUMMARY_R)
INSERT INTO RPT_FCT_RPT_CLAIM_SUMMARY_R
select
			 a.N_CLAIM_SK_R
			,a.N_PRODUCT_SK_R
			,a.N_PARTY_SK_R