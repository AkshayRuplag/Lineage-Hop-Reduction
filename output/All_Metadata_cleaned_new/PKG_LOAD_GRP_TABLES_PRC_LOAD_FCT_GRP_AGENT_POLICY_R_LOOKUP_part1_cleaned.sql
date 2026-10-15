-- Cleaned for lineage: PKG_LOAD_GRP_TABLES_PRC_LOAD_FCT_GRP_AGENT_POLICY_R_LOOKUP (part 1/1)

INSERT  INTO ATOMIC.FCT_GRP_AGENT_POLICY_R_LOOKUP_STG
	(
		n_agent_sk_r ,
		n_policy_billgroup_sk_r,
		n_policy_sk_r ,
		n_is_split_agent_r ,
		n_split_percentage_r ,
		n_arrangement_code_r ,
		d_start_date_r ,
		d_end_date_r ,
		n_split_with_r ,
		d_insert_date_r ,
		d_delete_date_r ,
		v_commission_type_r ,
		n_dc_arrangement_code_r ,
		v_subject_area_type_r ,
		t_event_timestamp_r ,
		v_source_system_name_r ,
		FIC_MIS_DATE_R ,
		N_BATCH_ID_R ,
		N_SEQUENCE_NUMBER_R ,
		T_CREATION_DATE_R ,
		T_LAST_MODIFIED_DATE_R ,
		V_CREATED_BY_R ,
		V_LAST_MODIFIED_BY_R,
		D_RPT_START_DATE_R ,
		D_RPT_END_DATE_R ,
		N_RPT_PRIMARY_INDICATOR_R ,
		V_SPECIAL_HANDLING_5500_IND_R ,
		 N_RPT_TOTAL_AGENTS_R ,
		N_RPT_SORT_ORDER_R,
		F_PHYSICAL_DELETE_R ,
		V_CHANGE_REASON_R ,
		N_RPT_SPLIT_PERCENTAGE_R,
		final_result_1,
		final_result_2,
		n_agent_policy_id_r,
		v_delete_by_r,
		V_TEMPLATE_NAME_R ,
		N_LAST_RATE_R ,
		V_TEMPLATE_NAME_R_1
	)
	with RPT_SPLIT_PERCENTAGE_FIRST as
	(
	select
		cte1.n_policy_sk_r as n_policy_sk_r  ,
		cte1.n_agent_sk_r as n_agent_sk_r ,
		cte1.V_COMMISSION_TYPE_R,
		CTE1.N_AGENT_POLICY_ID_R,
		n_rpt_split_percentage_r_1,
		n_rpt_split_percentage_r ,
		(n_rpt_split_percentage_r_1/nullif(n_rpt_split_percentage_r,0)) as final_result_1
	from
	(
		select
			a.N_POLICY_SK_R,
			A.n_agent_sk_r,
			A.V_COMMISSION_TYPE_R,
			A.N_AGENT_POLICY_ID_R,
			SUM(NVL(N_SPLIT_PERCENTAGE_R,100)) as N_RPT_SPLIT_PERCENTAGE_R_1
		from atomic.fct_grp_agent_policy_r  a
		join
		(
			select
				N_POLICY_SK_R,
				N_AGENT_SK_R,
				n_contract_template_id_r
			from atomic.dim_grp_agent_contract_tmplt_r
			where  UPPER(V_TEMPLATE_NAME_R) <> 'PCW00' and v_active_status_r = 'Y'
			group by N_POLICY_SK_R, N_AGENT_SK_R, n_contract_template_id_r
		) b
		on 	a.N_POLICY_SK_R=b.N_POLICY_SK_R
		and a.N_AGENT_SK_R=b.N_AGENT_SK_R
		join atomic.dim_grp_arrangement_r c
			on a.N_ARRANGEMENT_CODE_R =c.N_ARRANGEMENT_ID_R and b.n_contract_template_id_r =c.N_TEMPLATE_ID_R
		join atomic.dim_grp_agent_directory_r ad
			on b.n_agent_sk_r = ad.n_agent_sk_r and ad.v_active_status_r = 'Y'
		where
			sysdate between a.d_start_date_r and NVL(a.d_end_date_r,sysdate)
		and a.d_delete_date_r is null
		and ad.v_agent_number_r <> '273286-0001' and ad.v_agent_number_r like '%-0000'
		and  
		UPPER(trim(a.V_COMMISSION_TYPE_R)) = 'COMMISSION'  
		group by a.N_POLICY_SK_R,
		a.N_AGENT_SK_R,
		a.V_COMMISSION_TYPE_R,
		a.N_AGENT_POLICY_ID_R
	) cte1
	join
	(
		select a.n_policy_sk_r,
		NVL(sum(a.n_split_percentage_r), 100) as n_rpt_split_percentage_r
		from atomic.fct_grp_agent_policy_r a
		join
		(
			select n_policy_sk_r,
			n_agent_sk_r,
			n_contract_template_id_r
			from atomic.dim_grp_agent_contract_tmplt_r
			where  UPPER(V_TEMPLATE_NAME_R) <> 'PCW00' and v_active_status_r = 'Y'
			group by n_policy_sk_r,
			n_agent_sk_r,
			n_contract_template_id_r
		) b
		on a.n_policy_sk_r=b.n_policy_sk_r
		and a.n_agent_sk_r=b.n_agent_sk_r
		join atomic.dim_grp_arrangement_r c
			on a.N_ARRANGEMENT_CODE_R =c.N_ARRANGEMENT_ID_R and b.n_contract_template_id_r =c.N_TEMPLATE_ID_R
		join atomic.dim_grp_agent_directory_r ad
			on b.n_agent_sk_r = ad.n_agent_sk_r and ad.v_active_status_r = 'Y'
		where sysdate between a.d_start_date_r and NVL(a.d_end_date_r,sysdate)
		 and a.d_delete_date_r is null
		and
		UPPER(trim(a.V_COMMISSION_TYPE_R)) = 'COMMISSION'  
		 and
		ad.v_agent_number_r <> '273286-0001' and ad.v_agent_number_r like '%-0000' and
		UPPER(trim(a.V_COMMISSION_TYPE_R)) = 'COMMISSION'  
		group by a.n_policy_sk_r
	)cte2
		on cte1.n_policy_sk_r=cte2.n_policy_sk_r
		where n_rpt_split_percentage_r_1<>0
		order by cte1.n_policy_sk_r, cte1.n_agent_sk_r
	)
	,
	RPT_SPLIT_PERCENTAGE_SECOND as
	(
		select cte1.n_policy_sk_r as n_policy_sk_r,
		cte1.n_agent_sk_r as n_agent_sk_r,
		cte1.V_COMMISSION_TYPE_R,
		cte1.n_agent_policy_id_r,
		n_rpt_split_percentage_r_2,
		n_rpt_split_percentage_r ,
		(n_rpt_split_percentage_r_2/nullif(n_rpt_split_percentage_r,0)) as final_result_2
		from
		(
			select a.n_policy_sk_r,
				a.n_agent_sk_r,
				a.V_COMMISSION_TYPE_R,
				a.n_agent_policy_id_r,
				sum(NVL(n_split_percentage_r, 100)) as n_rpt_split_percentage_r_2
			from atomic.fct_grp_agent_policy_r a
			join
			(
				select n_policy_sk_r,
				n_agent_sk_r,
				n_contract_template_id_r from atomic.dim_grp_agent_contract_tmplt_r
				where  UPPER(V_TEMPLATE_NAME_R) <> 'PCW00' and v_active_status_r = 'Y'
				group by n_policy_sk_r,
				n_agent_sk_r,
				n_contract_template_id_r
			) b on a.n_policy_sk_r=b.n_policy_sk_r and a.n_agent_sk_r=b.n_agent_sk_r 
			join atomic.dim_grp_arrangement_r c on a.N_ARRANGEMENT_CODE_R =c.N_ARRANGEMENT_ID_R
			join atomic.dim_grp_agent_directory_r ad
				on 	b.n_agent_sk_r = ad.n_agent_sk_r
				and ad.v_active_status_r = 'Y'
				and b.n_contract_template_id_r =c.N_TEMPLATE_ID_R
			where
				sysdate between a.d_start_date_r and NVL(a.d_end_date_r,sysdate)
				and 	 a.d_delete_date_r is null
				and 	ad.v_agent_number_r <> '273286-0001'
				and 	ad.v_agent_number_r like '%-0000'
				and 	UPPER(a.V_COMMISSION_TYPE_R)  in ('ADMIN')
			group by a.n_policy_sk_r, a.n_agent_sk_r, a.V_COMMISSION_TYPE_R, a.n_agent_policy_id_r
		)cte1
		join
		(
			select a.n_policy_sk_r,
			NVL(sum(a.n_split_percentage_r),100) as n_rpt_split_percentage_r
			from atomic.fct_grp_agent_policy_r a
			join
			(
				select n_policy_sk_r, n_agent_sk_r, n_contract_template_id_r
				from atomic.dim_grp_agent_contract_tmplt_r
				where  UPPER(V_TEMPLATE_NAME_R) <> 'PCW00' and v_active_status_r = 'Y'
				group by n_policy_sk_r, n_agent_sk_r, n_contract_template_id_r
			) b
			on a.n_policy_sk_r=b.n_policy_sk_r
			and a.n_agent_sk_r=b.n_agent_sk_r
			join atomic.dim_grp_arrangement_r c
			on 	a.N_ARRANGEMENT_CODE_R =	c.N_ARRANGEMENT_ID_R
			and b.n_contract_template_id_r =c.N_TEMPLATE_ID_R
		 where
			sysdate between a.d_start_date_r and NVL(a.d_end_date_r,sysdate)
			and  a.d_delete_date_r is null
			and
			UPPER(trim(a.V_COMMISSION_TYPE_R)) = 'COMMISSION'  
			group by a.n_policy_sk_r
		 )cte2
		 on 		cte1.n_policy_sk_r=cte2.n_policy_sk_r
		 where 		n_rpt_split_percentage_r_2<>0
		 order by 	cte1.n_policy_sk_r, cte1.n_agent_sk_r
	)
	, RPT_PRIMARY_INDICATOR as
	(
		select
		(
			case when rank() over( partition by a.n_policy_sk_r order by a.n_policy_sk_r,a.n_is_split_agent_r, RPT_SPLIT_PERCENTAGE_FIRST.final_result_1 ,RPT_SPLIT_PERCENTAGE_SECOND.final_result_2, a.V_COMMISSION_TYPE_R,a.n_agent_sk_r) =1
			then 'P'
			else 'S' end
		) as n_rpt_primary_indicator_r,
		rank() over( partition by a.n_policy_sk_r order by a.n_policy_sk_r,a.n_is_split_agent_r, RPT_SPLIT_PERCENTAGE_FIRST.final_result_1 ,RPT_SPLIT_PERCENTAGE_SECOND.final_result_2, a.V_COMMISSION_TYPE_R,a.n_agent_sk_r) rank_primary,
		a.n_policy_sk_r ,
		a.n_agent_sk_r,
		a.V_COMMISSION_TYPE_R,
		a.n_agent_policy_id_r,
		b.V_TEMPLATE_NAME_R ,
		b.N_LAST_RATE_R
		from atomic.fct_grp_agent_policy_r a
		join
		(
			select n_policy_sk_r,
				n_agent_sk_r,
				n_contract_template_id_r,V_TEMPLATE_NAME_R ,
				CASE
				WHEN SUBSTR(V_TEMPLATE_NAME_R, 1, 3) = 'PCH'
				THEN 0
				ELSE
				  TO_NUMBER(nvl(SUBSTR(V_TEMPLATE_NAME_R, INSTR(V_TEMPLATE_NAME_R, '-') + 1, INSTR(V_TEMPLATE_NAME_R, '%') - INSTR(V_TEMPLATE_NAME_R, '-') - 1),0)) / 100  
				END AS N_LAST_RATE_R
			from atomic.dim_grp_agent_contract_tmplt_r
			where  UPPER(V_TEMPLATE_NAME_R) <> 'PCW00' and v_active_status_r = 'Y'
			group by n_policy_sk_r, n_agent_sk_r, n_contract_template_id_r, V_TEMPLATE_NAME_R
		) b
		on 			a.n_policy_sk_r=b.n_policy_sk_r
			and 	a.n_agent_sk_r=b.n_agent_sk_r
		join atomic.dim_grp_arrangement_r c
			on 	a.N_ARRANGEMENT_CODE_R =c.N_ARRANGEMENT_ID_R
			and b.n_contract_template_id_r =c.N_TEMPLATE_ID_R
		join atomic.dim_grp_agent_directory_r ad
			on 	b.n_agent_sk_r = ad.n_agent_sk_r
			and ad.v_active_status_r = 'Y'
		left join RPT_SPLIT_PERCENTAGE_FIRST
			on a.n_agent_policy_id_r = RPT_SPLIT_PERCENTAGE_FIRST.n_agent_policy_id_r
		left join RPT_SPLIT_PERCENTAGE_SECOND
			on a.n_agent_policy_id_r = RPT_SPLIT_PERCENTAGE_SECOND.n_agent_policy_id_r
		where
		sysdate between a.d_start_date_r and NVL(a.d_end_date_r,sysdate)
		and ad.v_agent_number_r <> '273286-0001'
		and ad.v_agent_number_r like '%-0000'
		and a.d_delete_date_r is null
		and
		UPPER(trim(a.V_COMMISSION_TYPE_R)) = 'COMMISSION'  
	)   
	, RPT_TOTAL_AGENTS as
	(
		select count(a.n_agent_sk_r) as N_RPT_TOTAL_AGENTS_R,
		a.n_policy_sk_r
		from atomic.fct_grp_agent_policy_r a
		join
		(
			select n_policy_sk_r,
			n_agent_sk_r
			from atomic.dim_grp_agent_contract_tmplt_r
			where  UPPER(V_TEMPLATE_NAME_R) <> 'PCW00' and v_active_status_r = 'Y'
			group by n_policy_sk_r, n_agent_sk_r
		) b
		on a.n_policy_sk_r=b.n_policy_sk_r
			and a.n_agent_sk_r=b.n_agent_sk_r
		join
		(
			select n_policy_sk_r,
			n_agent_sk_r,
			n_contract_template_id_r
			from atomic.dim_grp_agent_contract_tmplt_r
			where  UPPER(V_TEMPLATE_NAME_R) <> 'PCW00' and v_active_status_r = 'Y'
			group by n_policy_sk_r, N_AGENT_SK_R, n_contract_template_id_r
		) b1 
		on 	a.n_policy_sk_r=b.n_policy_sk_r
			and a.n_agent_sk_r=b.n_agent_sk_r
		join atomic.dim_grp_arrangement_r c
			on a.N_ARRANGEMENT_CODE_R =c.N_ARRANGEMENT_ID_R
			and b1.n_contract_template_id_r =c.N_TEMPLATE_ID_R
		join atomic.dim_grp_agent_directory_r ad
			on b.n_agent_sk_r = ad.n_agent_sk_r
			and ad.v_active_status_r = 'Y'
		where
		sysdate between a.d_start_date_r and NVL(a.d_end_date_r,sysdate)
		and  a.d_delete_date_r is null
		and
		ad.v_agent_number_r <> '273286-0001'
		and ad.v_agent_number_r like '%-0000'
		and
		UPPER(trim(a.V_COMMISSION_TYPE_R)) = 'COMMISSION'  
		group by a.n_policy_sk_r
	)
	select
	z.n_agent_sk_r ,
	z.n_policy_billgroup_sk_r,
	z.n_policy_sk_r ,
	z.n_is_split_agent_r ,
	z.n_split_percentage_r ,
	z.n_arrangement_code_r ,
	z.d_start_date_r ,
	z.d_end_date_r ,
	z.n_split_with_r ,
	z.d_insert_date_r ,
	z.d_delete_date_r ,
	z.v_commission_type_r ,
	z.n_dc_arrangement_code_r ,
	z.v_subject_area_type_r ,
	z.t_event_timestamp_r ,
	z.v_source_system_name_r ,
	z.FIC_MIS_DATE_R ,
	IN_BATCH_ID_R,
	NVL(LN_SEQUENCE_NUMBER_R,0)+ROWNUM,
	LD_SYSDATE,
	LD_SYSDATE,
	'ODI',
	'ODI',
	z.D_RPT_START_DATE_R ,
	z.D_RPT_END_DATE_R ,
	p.N_RPT_PRIMARY_INDICATOR_R ,
	z.V_SPECIAL_HANDLING_5500_IND_R ,
	NVL(t.N_RPT_TOTAL_AGENTS_R,0) as N_RPT_TOTAL_AGENTS_R ,
	z.N_RPT_SORT_ORDER_R,
	z.F_PHYSICAL_DELETE_R ,
	z.V_CHANGE_REASON_R ,
	 CASE WHEN UPPER(z.V_COMMISSION_TYPE_R)='ADMIN'
	 then 0 ELSE NVL((case when y.final_result_1 is null then x.final_result_2 else y.final_result_1 end ),
	0) END as N_RPT_SPLIT_PERCENTAGE_R,
	y.final_result_1,
	x.final_result_2,
	z.n_agent_policy_id_r,
	' ' as v_delete_by_r,
	CASE
		WHEN substr(p.V_TEMPLATE_NAME_R,1,4) ='PCHI' THEN 'PCHI'
		WHEN  substr(p.V_TEMPLATE_NAME_R,1,3) ='PCH' THEN 'PCH'
		WHEN  substr(p.V_TEMPLATE_NAME_R,1,3) ='PCO' THEN '63'
		WHEN  SUBSTR(v_template_name_r, -1) ='%' THEN SUBSTR(p.V_TEMPLATE_NAME_R,3,2)
		WHEN  LENGTH(p.V_TEMPLATE_NAME_R) =4 THEN SUBSTR(p.V_TEMPLATE_NAME_R,3,2)
	ELSE p.V_TEMPLATE_NAME_R
	END as V_TEMPLATE_NAME_R,
	CASE
    WHEN SUBSTR(p.V_TEMPLATE_NAME_R, 1, 3) = 'PCH' THEN
      0
    ELSE
       TO_NUMBER(nvl(SUBSTR(p.V_TEMPLATE_NAME_R, INSTR(p.V_TEMPLATE_NAME_R, '-') + 1, INSTR(p.V_TEMPLATE_NAME_R, '%') - INSTR(p.V_TEMPLATE_NAME_R, '-') - 1),0)  / 100)  
    END AS N_LAST_RATE_R ,
    p.V_TEMPLATE_NAME_R  V_TEMPLATE_NAME_R_1
	from atomic.fct_grp_agent_policy_r z
	left join RPT_SPLIT_PERCENTAGE_FIRST y
		on z.n_policy_sk_r=y.n_policy_sk_r
		and z.n_agent_sk_r=y.n_agent_sk_r
		and z.V_COMMISSION_TYPE_R = y.V_COMMISSION_TYPE_R
		and z.n_agent_policy_id_r=y.n_agent_policy_id_r
	left join RPT_SPLIT_PERCENTAGE_SECOND x
		on z.n_policy_sk_r=x.n_policy_sk_r
		and z.n_agent_sk_r=x.n_agent_sk_r
		and z.V_COMMISSION_TYPE_R = x.V_COMMISSION_TYPE_R
		and z.n_agent_policy_id_r=x.n_agent_policy_id_r
	left join RPT_PRIMARY_INDICATOR p
		on z.n_policy_sk_r=p.n_policy_sk_r
		and z.n_agent_sk_r=p.n_agent_sk_r
		and z.V_COMMISSION_TYPE_R = p.V_COMMISSION_TYPE_R
		and z.n_agent_policy_id_r=p.n_agent_policy_id_r
	left join RPT_TOTAL_AGENTS t
		on z.n_policy_sk_r=t.n_policy_sk_r
	left join atomic.dim_grp_policy_dir_r p
		on z.n_policy_sk_r = p.n_policy_sk_r
		and p.v_active_status_r = 'Y'
	where z.d_delete_date_r  is null
	and sysdate between z.d_start_date_r and NVL(z.d_end_date_r,sysdate)
	and
	 CASE
		WHEN UPPER(z.V_COMMISSION_TYPE_R)='ADMIN'
		then 0
		ELSE NVL((case when y.final_result_1 is null then x.final_result_2 else y.final_result_1 end ),0)
		END <> 0;