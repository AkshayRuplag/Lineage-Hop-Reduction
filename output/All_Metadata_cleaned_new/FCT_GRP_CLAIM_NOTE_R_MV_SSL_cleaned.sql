-- Cleaned for lineage: FCT_GRP_CLAIM_NOTE_R_MV_SSL

CREATE MATERIALIZED VIEW FCT_GRP_CLAIM_NOTE_R_MV_SSL AS
select max(b.D_CREATED_DATE_R||b.N_CREATED_ITIME_R) note_date ,n_claim_sk_r
  from fct_grp_claim_note_r b
group by n_claim_sk_r;