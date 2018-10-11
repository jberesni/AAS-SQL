--------------------------------------------------------------------
-- ASHcpuiowaitAS.sql
--
-- Aggregates ASH samples into single-row per sample with separate
-- active session counts for CPU, IO, WAIT and IDLE categories over 
-- the previous hour.
--
-- Copyright(c) 2007 John Beresniewicz, Oracle USA
--------------------------------------------------------------------

WITH CPUIOWAIT as
(select
       sample_id
      ,sample_time
      ,SUM(CASE session_state WHEN 'ON CPU' THEN 1 ELSE 0 END)
       as cpu_sess
      ,SUM(CASE WHEN session_state = 'WAITING' 
                 AND wait_class IN ('System I/O','User I/O') 
                THEN 1 ELSE 0 END) 
       as io_sess
      ,SUM(CASE WHEN session_state = 'WAITING' 
                 AND wait_class = 'Idle' 
                THEN 1 ELSE 0 END) 
       as idle_sess
      ,SUM(CASE WHEN session_state = 'WAITING' 
                 AND wait_class NOT IN ('Idle'
                                       ,'System I/O', 'User I/O') 
                THEN 1 ELSE 0 END) 
       as wait_sess
      ,COUNT(1) as all_sess
  from
       v$active_session_history
 where 
       session_type = 'FOREGROUND'
 group by
       sample_id,sample_time
 order by
       sample_id desc
)
select sample_id, cpu_sess, io_sess, wait_sess 
  from CPUIOWAIT
 where sample_time < SYSDATE - 1/24
/

