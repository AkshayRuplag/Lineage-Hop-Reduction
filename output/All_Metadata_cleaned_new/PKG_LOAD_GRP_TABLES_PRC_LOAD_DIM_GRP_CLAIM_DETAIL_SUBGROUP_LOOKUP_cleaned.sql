-- Cleaned for lineage: PKG_LOAD_GRP_TABLES_PRC_LOAD_DIM_GRP_CLAIM_DETAIL_SUBGROUP_LOOKUP

DELETE FROM DIM_GRP_CLAIM_DETAIL_SUBGROUP_LOOKUP WHERE V_SOURCE_SYSTEM_NAME_R ='PACS';

INSERT  INTO ATOMIC.DIM_GRP_CLAIM_DETAIL_SUBGROUP_LOOKUP
	(V_CLAIM_NUMBER_R,
	N_POLICY_SK_R,
	N_SOURCE_SYSTEM_KEY_R,
	N_PARTY_SK_R,
	N_SOURCE_VERSION_NUMBER_R,
	V_SUBGROUP_ID_R,
	V_CORRESPONDENT_NAME_R,
	V_SUBGROUP_NAME_R,
	V_SUBGROUP_ADDRESSLINE1_R,
	V_SUBGROUP_ADDRESSLINE2_R,
	V_SUBGROUP_POSTALZIP_R,
	V_SUBGROUP_PROVSTATE_R,
	V_SUBGROUP_CITY_R,
	N_BATCH_ID_R          ,
	N_SEQUENCE_NUMBER_R   ,
	T_CREATION_DATE_R     ,
	T_LAST_MODIFIED_DATE_R,
	V_CREATED_BY_R        ,
	V_LAST_MODIFIED_BY_R,
	V_SOURCE_SYSTEM_NAME_R
	)
	SELECT
	DISTINCT 
	CLAIM_DIR.V_CLAIM_NUMBER_R,
	CLAIM_DIR.N_POLICY_SK_R,
	PARTY_DIR.N_SOURCE_SYSTEM_KEY_R,
	PARTY_DIR.N_PARTY_SK_R,
	PARTY_DIR.N_SOURCE_VERSION_NUMBER_R,
	NVL(NVL(NVL(NVL(NVL(subs_test.v_subgroup_id_r,'00000'),ENTITYLOCATION_MAIN.v_subgroup_id_r),ENTITYLOCATION_SITUS.v_subgroup_id_r),
	ENTITYLOCATION_SUBGROUP.v_subgroup_id_r) ,'00000')AS v_subgroup_id_r,
	NVL(NVL(NVL(NVL(SUBGROUP1.v_correspondent_name_r,SUBGROUP.v_correspondent_name_r),ENTITYLOCATION_MAIN.v_subgroup_name_r),
	ENTITYLOCATION_SITUS.v_subgroup_name_r),
	ENTITYLOCATION_SUBGROUP.v_subgroup_name_r) AS v_correspondent_name_r,
	NVL(NVL(NVL(NVL(NVL(NVL(subs_test.V_OVERRIDE_NAME_R,SUBGROUP1.v_subgroup_name_r),SUBGROUP.v_subgroup_name_r),ENTITYLOCATION_MAIN.v_subgroup_name_r),
	ENTITYLOCATION_SITUS.v_subgroup_name_r),
	ENTITYLOCATION_SUBGROUP.v_subgroup_name_r),PARTY.V_INDIVIDUAL_LAST_NAME_R) AS v_subgroup_name_r,
	NVL(NVL(SUBGROUP.v_subgroup_addressline1_r,ENTITYLOCATION_MAIN.v_subgroup_addressline1_r),ENTITYLOCATION_SITUS.v_subgroup_addressline1_r) AS v_subgroup_addressline1_r ,
	NVL(NVL(SUBGROUP.v_subgroup_addressline2_r,ENTITYLOCATION_MAIN.v_subgroup_addressline2_r),ENTITYLOCATION_SITUS.v_subgroup_addressline2_r) AS v_subgroup_addressline2_r,
	NVL(NVL(SUBGROUP.v_subgroup_postalzip_r,ENTITYLOCATION_MAIN.v_subgroup_postalzip_r),ENTITYLOCATION_SITUS.v_subgroup_postalzip_r) AS v_subgroup_postalzip_r ,
	NVL(NVL(SUBGROUP.v_subgroup_provstate_r,ENTITYLOCATION_MAIN.v_subgroup_provstate_r),ENTITYLOCATION_SITUS.v_subgroup_provstate_r) AS v_subgroup_provstate_r,
	NVL(NVL(SUBGROUP.v_subgroup_city_r,ENTITYLOCATION_MAIN.v_subgroup_city_r),ENTITYLOCATION_SITUS.v_subgroup_city_r) AS v_subgroup_city_r,
	IN_BATCH_ID_R          ,
	NVL(LN_SEQUENCE_NUMBER_R,0)+ROWNUM   ,
	LD_SYSDATE,
	LD_SYSDATE,
	'ODI' V_CREATED_BY_R        ,
	'ODI' V_LAST_MODIFIED_BY_R,
	V_SOURCE_SYSTEM_NAME_R
	FROM (SELECT V_CLAIM_NUMBER_R,N_POLICY_SK_R,N_POLICY_SOURCE_SYSTEM_KEY_R,V_SOURCE_SYSTEM_NAME_R FROM DIM_GRP_CLAIM_DIR_R WHERE V_ACTIVE_STATUS_R='Y' and V_SOURCE_SYSTEM_NAME_R='PACS'
	GROUP BY V_CLAIM_NUMBER_R,N_POLICY_SK_R,N_POLICY_SOURCE_SYSTEM_KEY_R,V_SOURCE_SYSTEM_NAME_R) CLAIM_DIR
	LEFT JOIN (SELECT N_CUST_PARTY_SK_R,N_POLICY_SK_R,N_SOURCE_SYSTEM_KEY_R FROM FCT_GRP_POLICY_R
	GROUP BY N_CUST_PARTY_SK_R,N_POLICY_SK_R,N_SOURCE_SYSTEM_KEY_R ) FCT_GRP_POLICY
	ON TRIM(CLAIM_DIR.N_POLICY_SK_R)=TRIM(FCT_GRP_POLICY.N_POLICY_SK_R)
	AND  TRIM(CLAIM_DIR.N_POLICY_SOURCE_SYSTEM_KEY_R)=TRIM(FCT_GRP_POLICY.N_SOURCE_SYSTEM_KEY_R)
	LEFT JOIN (SELECT N_PARTY_SK_R,N_SOURCE_SYSTEM_KEY_R,N_SOURCE_VERSION_NUMBER_R FROM DIM_GRP_PARTY_DIR_R
	WHERE V_ACTIVE_STATUS_R='Y'
	GROUP BY N_PARTY_SK_R,N_SOURCE_SYSTEM_KEY_R,N_SOURCE_VERSION_NUMBER_R) PARTY_DIR
	ON TRIM(PARTY_DIR.N_PARTY_SK_R)=TRIM(FCT_GRP_POLICY.N_CUST_PARTY_SK_R)
	LEFT JOIN (SELECT A.n_cust_subgrp_src_sys_key_r,A.n_cust_subgrp_src_version_nbr_r,A.v_correspondent_name_r,A.v_subgroup_name_r,A.v_subgroup_id_r
	FROM DIM_GRP_CUST_ENTITYSUBGROUP_R A
	JOIN
	(SELECT n_cust_subgrp_src_sys_key_r,n_cust_subgrp_src_version_nbr_r,MAX(cust_subgrp_seq_nbr_r) AS MAX_SEQ_NBR
	FROM DIM_GRP_CUST_ENTITYSUBGROUP_R WHERE V_ACTIVE_STATUS_R='Y'
	GROUP BY n_cust_subgrp_src_sys_key_r,n_cust_subgrp_src_version_nbr_r)MAX_SEQ
	ON TRIM(A.n_cust_subgrp_src_sys_key_r)=TRIM(MAX_SEQ.n_cust_subgrp_src_sys_key_r)
	AND TRIM(A.n_cust_subgrp_src_version_nbr_r)=TRIM(MAX_SEQ.n_cust_subgrp_src_version_nbr_r)
	AND TRIM(A.cust_subgrp_seq_nbr_r)=TRIM(MAX_SEQ.MAX_SEQ_NBR)
	WHERE V_ACTIVE_STATUS_R='Y'  AND A.v_subgroup_id_r='00000'  and cust_subgrp_add_seq_nbr_r is  null
	GROUP BY A.n_cust_subgrp_src_sys_key_r,A.n_cust_subgrp_src_version_nbr_r,A.v_correspondent_name_r,A.v_subgroup_name_r,A.v_subgroup_id_r)SUBGROUP1
	ON TRIM(PARTY_DIR.N_SOURCE_SYSTEM_KEY_R)=TRIM(SUBGROUP1.n_cust_subgrp_src_sys_key_r)
	AND TRIM(PARTY_DIR.N_SOURCE_VERSION_NUMBER_R)=TRIM(SUBGROUP1.n_cust_subgrp_src_version_nbr_r)
	LEFT JOIN (SELECT A.n_cust_subgrp_src_sys_key_r,A.n_cust_subgrp_src_version_nbr_r,v_subgroup_id_r,
	v_correspondent_name_r,v_subgroup_name_r,v_subgroup_addressline1_r,v_subgroup_addressline2_r,v_subgroup_postalzip_r,
	v_subgroup_provstate_r,v_subgroup_city_r
	FROM DIM_GRP_CUST_ENTITYSUBGROUP_R A
	JOIN
	(SELECT n_cust_subgrp_src_sys_key_r,n_cust_subgrp_src_version_nbr_r,MAX(cust_subgrp_seq_nbr_r) AS MAX_SEQ_NBR
	FROM DIM_GRP_CUST_ENTITYSUBGROUP_R WHERE V_ACTIVE_STATUS_R='Y'
	GROUP BY n_cust_subgrp_src_sys_key_r,n_cust_subgrp_src_version_nbr_r)MAX_SEQ
	ON TRIM(A.n_cust_subgrp_src_sys_key_r)=TRIM(MAX_SEQ.n_cust_subgrp_src_sys_key_r)
	AND TRIM(A.n_cust_subgrp_src_version_nbr_r)=TRIM(MAX_SEQ.n_cust_subgrp_src_version_nbr_r)
	AND TRIM(A.cust_subgrp_seq_nbr_r)=TRIM(MAX_SEQ.MAX_SEQ_NBR)
	WHERE V_ACTIVE_STATUS_R='Y'  and cust_subgrp_add_seq_nbr_r is not null
	GROUP BY A.n_cust_subgrp_src_sys_key_r,A.n_cust_subgrp_src_version_nbr_r,v_subgroup_id_r,
	v_correspondent_name_r,v_subgroup_name_r,v_subgroup_addressline1_r,v_subgroup_addressline2_r,v_subgroup_postalzip_r,
	v_subgroup_provstate_r,v_subgroup_city_r)SUBGROUP
	ON TRIM(PARTY_DIR.N_SOURCE_SYSTEM_KEY_R)=TRIM(SUBGROUP.n_cust_subgrp_src_sys_key_r)
	AND TRIM(PARTY_DIR.N_SOURCE_VERSION_NUMBER_R)=TRIM(SUBGROUP.n_cust_subgrp_src_version_nbr_r)
	LEFT JOIN (SELECT C.N_SOURCE_SYSTEM_KEY_R,C.N_ADDRESS_VERSION_NUMBER_R,C.V_SUBGROUP_ID_R,
	C.V_SUBGROUP_NAME_R,C.V_SUBGROUP_ADDRESSLINE1_R,C.V_SUBGROUP_ADDRESSLINE2_R,C.V_SUBGROUP_POSTALZIP_R,
	c.V_SUBGROUP_PROVSTATE_R,c.V_SUBGROUP_CITY_R
	FROM DIM_GRP_ENTITYLOCATION_R c 
	WHERE V_ACTIVE_STATUS_R='Y'  AND  UPPER(V_LOCATION_ID_R)='MAIN'
	and C.T_EVENT_TIMESTAMP_R =
	(select max(b.T_EVENT_TIMESTAMP_R)T_EVENT_TIMESTAMP_R from
	DIM_GRP_ENTITYLOCATION_R b
	where b.V_ACTIVE_STATUS_R='Y'
	AND  UPPER(b.V_LOCATION_ID_R)='MAIN'
	and b.N_ADDRESS_VERSION_NUMBER_R = C.N_ADDRESS_VERSION_NUMBER_R
	and b.N_SOURCE_SYSTEM_KEY_R = C.N_SOURCE_SYSTEM_KEY_R)
	GROUP BY N_SOURCE_SYSTEM_KEY_R,N_ADDRESS_VERSION_NUMBER_R,v_subgroup_id_r,
	v_subgroup_name_r,v_subgroup_addressline1_r,v_subgroup_addressline2_r,v_subgroup_postalzip_r,
	v_subgroup_provstate_r,v_subgroup_city_r)ENTITYLOCATION_MAIN
	ON TRIM(PARTY_DIR.N_SOURCE_SYSTEM_KEY_R)=TRIM(ENTITYLOCATION_MAIN.N_SOURCE_SYSTEM_KEY_R)
	AND TRIM(PARTY_DIR.N_SOURCE_VERSION_NUMBER_R)=TRIM(ENTITYLOCATION_MAIN.N_ADDRESS_VERSION_NUMBER_R)
	LEFT JOIN (SELECT N_SOURCE_SYSTEM_KEY_R,N_ADDRESS_VERSION_NUMBER_R,v_subgroup_id_r,
	v_subgroup_name_r,v_subgroup_addressline1_r,v_subgroup_addressline2_r,v_subgroup_postalzip_r,
	v_subgroup_provstate_r,v_subgroup_city_r
	FROM DIM_GRP_ENTITYLOCATION_R
	WHERE V_ACTIVE_STATUS_R='Y'  AND   UPPER(V_LOCATION_ID_R)='SITUS' AND UPPER(V_DESCRIPTION_R)='SITUS ADDRESS'
	GROUP BY N_SOURCE_SYSTEM_KEY_R,N_ADDRESS_VERSION_NUMBER_R,v_subgroup_id_r,
	v_subgroup_name_r,v_subgroup_addressline1_r,v_subgroup_addressline2_r,v_subgroup_postalzip_r,
	v_subgroup_provstate_r,v_subgroup_city_r)ENTITYLOCATION_SITUS
	ON TRIM(PARTY_DIR.N_SOURCE_SYSTEM_KEY_R)=TRIM(ENTITYLOCATION_SITUS.N_SOURCE_SYSTEM_KEY_R)
	AND TRIM(PARTY_DIR.N_SOURCE_VERSION_NUMBER_R)=TRIM(ENTITYLOCATION_SITUS.N_ADDRESS_VERSION_NUMBER_R)
	LEFT JOIN (SELECT N_SOURCE_SYSTEM_KEY_R,N_ADDRESS_VERSION_NUMBER_R,V_SUBGROUP_ID_R,
	V_SUBGROUP_NAME_R
	FROM DIM_GRP_ENTITYLOCATION_R
	WHERE V_ACTIVE_STATUS_R='Y'
	GROUP BY N_SOURCE_SYSTEM_KEY_R,N_ADDRESS_VERSION_NUMBER_R,V_SUBGROUP_ID_R,
	V_SUBGROUP_NAME_R)ENTITYLOCATION_SUBGROUP
	ON TRIM(PARTY_DIR.N_SOURCE_SYSTEM_KEY_R)=TRIM(ENTITYLOCATION_SUBGROUP.N_SOURCE_SYSTEM_KEY_R)
	AND TRIM(PARTY_DIR.N_SOURCE_VERSION_NUMBER_R)=TRIM(ENTITYLOCATION_SUBGROUP.N_ADDRESS_VERSION_NUMBER_R)
	left join (select a.v_claim_number_r,a.V_SUBGROUP_NAME_R,a.V_OVERRIDE_NAME_R , b.V_SUBGROUP_ID_R
	from (SELECT v_claim_number_r, V_SUBGROUP_NAME_R, V_OVERRIDE_NAME_R, N_CLAIM_SUBS_LINK_VERSION_NBR_R,N_CLAIM_SUBS_LINK_SEQ_NBR_R, N_CLAIM_SUBS_LINK_SRC_SYS_KEY_R, V_ACTIVE_STATUS_R, rank FROM (
			select v_claim_number_r,V_SUBGROUP_NAME_R,V_OVERRIDE_NAME_R, N_CLAIM_SUBS_LINK_SEQ_NBR_R, N_CLAIM_SUBS_LINK_SRC_SYS_KEY_R,N_CLAIM_SUBS_LINK_VERSION_NBR_R, V_ACTIVE_STATUS_R,
			RANK() OVER (PARTITION BY v_claim_number_r ORDER BY N_BATCH_ID_R DESC) AS rank
			FROM atomic.dim_GRP_CLAIM_SUBSIDIARY_R  ) WHERE rank = 1)  a
	left join DIM_GRP_CUST_ENTITYSUBGROUP_R b
	on a.N_CLAIM_SUBS_LINK_SEQ_NBR_R=b.CUST_SUBGRP_SEQ_NBR_R
	and a.N_CLAIM_SUBS_LINK_SRC_SYS_KEY_R= b.N_CUST_SUBGRP_SRC_SYS_KEY_R
	and a.N_CLAIM_SUBS_LINK_VERSION_NBR_R = b.N_CUST_SUBGRP_SRC_VERSION_NBR_R
	and b.v_active_status_r = 'Y'
	where a.v_active_Status_R='Y'
	GROUP BY a.v_claim_number_r,a.V_SUBGROUP_NAME_R,a.V_OVERRIDE_NAME_R , b.V_SUBGROUP_ID_R 
	)subs_test on
	trim( CLAIM_DIR.v_claim_number_r)=trim(subs_test.v_claim_number_r)
	left join (select V_INDIVIDUAL_LAST_NAME_R,n_party_sk_R from dim_grp_party_r where v_active_Status_R='Y')PARTY
	on PARTY_DIR.n_party_sk_R=PARTY.n_party_sk_r;