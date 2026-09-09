"procedure prc_grp_gather_table_idx_stats(p_table_name IN VARCHAR2,
p_degree IN NUMBER)
IS
BEGIN
for i in (select * from all_tables where table_name =p_table_name)
loop
    DBMS_STATS.GATHER_TABLE_STATS(&apos;ATOMIC&apos;, I.TABLE_NAME,degree =&gt; p_degree);
   for j in (sElect index_name from all_indexes where table_name=i.table_name)
   LOOP
     dbms_stats.gather_index_stats(ownname =&gt; &apos;ATOMIC&apos;, indname =&gt; J.index_name,
     degree =&gt; p_degree);
   end loOp;
end loop;
EXCEPTION
WHEN OTHERS THEN
RAISE;
END;"