--------------------------------------------------------------------
-- ASHdumpAAS.sql
--
-- Uses an imported ASH dump to separate foreground and background
-- average active sessions for comparison.
--
-- Copyright(c) 2007 John Beresniewicz, Oracle USA
--------------------------------------------------------------------

WITH FB_SESS as
(select
       D.instance_number              as instance_number
      ,ROUND(D.sample_time,'MI')      as sample_minute
      ,CASE WHEN session_type='2' AND D.wait_time<>0 THEN 1 ELSE 0 END
                                      as BG_cpusess
      ,CASE WHEN session_type='1' AND D.wait_time<>0 THEN 1 ELSE 0 END
                                      as FG_cpusess
      ,CASE WHEN session_type='2' THEN 1 ELSE 0 END
                                      as BG_sess
      ,CASE WHEN session_type='1' THEN 1 ELSE 0 END
                                      as FG_sess
  from
       ash.gmamocs_ashdata  D   -- this is an imported ash dump
      ,v$event_name         E
 where 
       D.event_id = E.event_id
)
select 
       instance_number
      ,sample_minute
      ,ROUND(SUM(FG_sess)/60,2)  as FGAAS
      ,ROUND(SUM(BG_sess)/60,2)  as BGAAS
      ,ROUND(SUM(FG_cpusess)/60,2)  as FGcpuAAS
      ,ROUND(SUM(BG_cpusess)/60,2)  as BGcpuAAS
  from FB_SESS
 group by instance_number,sample_minute
 order by 1,2
/

