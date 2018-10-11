--------------------------------------------------------------------
-- ASHmetricsAAS.sql
--
-- Tests the equivalence of ASH estimated DB time against sysmetric 
-- counted DB time.
--
-- Copyright(c) 2007 John Beresniewicz, Oracle USA
--------------------------------------------------------------------

select 
       M.end_time
      ,(M.value / 100) as Mdbtime
      ,SUM(DECODE(A.session_type,'FOREGROUND',1,0)) / ((M.end_time - M.begin_time) * 86400 )
                       as ASHdbtime
      ,COUNT(1)        as ASHcount
  from
       v$active_session_history  A
      ,v$sysmetric_history       M
 where
       A.sample_time between M.begin_time and M.end_time
   and M.metric_name = 'Database Time Per Sec'
   and M.group_id = 2
 group by
       M.end_time,M.begin_time, M.value
 order by 
       M.end_time
/


