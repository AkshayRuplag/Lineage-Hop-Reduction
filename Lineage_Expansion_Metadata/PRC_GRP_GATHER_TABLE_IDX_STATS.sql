--------------------------------------------------------
--  DDL for Procedure PRC_GRP_GATHER_TABLE_IDX_STATS
--------------------------------------------------------
set define off;

  CREATE OR REPLACE EDITIONABLE PROCEDURE "ATOMIC"."PRC_GRP_GATHER_TABLE_IDX_STATS" (p_table_name IN VARCHAR2,
p_degree IN NUMBER)
IS
BEGIN
for i in (select * from all_tables where table_name =p_table_name)
loop
    DBMS_STATS.GATHER_TABLE_STATS('ATOMIC', I.TABLE_NAME,degree => p_degree);
   for j in (sElect index_name from all_indexes where table_name=i.table_name)
   LOOP
     dbms_stats.gather_index_stats(ownname => 'ATOMIC', indname => J.index_name,
     degree => p_degree);
   end loOp;
end loop;
EXCEPTION
WHEN OTHERS THEN
RAISE;
END;

/

  GRANT DEBUG ON "ATOMIC"."PRC_GRP_GATHER_TABLE_IDX_STATS" TO "ATOMIC_DEBUG";
  GRANT EXECUTE ON "ATOMIC"."PRC_GRP_GATHER_TABLE_IDX_STATS" TO "ATOMIC_ALL_RO";
