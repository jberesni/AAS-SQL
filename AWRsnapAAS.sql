--------------------------------------------------------------------
-- AWRsnapAAS.sql
--
-- Compute average active sessions by AWR snapshot and instance.

-- Copyright(c) 2007 John Beresniewicz, Oracle USA
--------------------------------------------------------------------

WITH snapDBtime
as
(select
       SN.snap_id                         as snap_id
      ,SN.instance_number                 as inst_num
      ,ROUND(SN.startup_time,'MI')        as startup_time
      ,ROUND(SN.begin_interval_time,'MI') as begin_time
      ,ROUND(SN.end_interval_time,'MI')   as end_time
      ,TM.value / 1000000                 as DBtime_secs
  from
       dba_hist_snapshot        SN
      ,dba_hist_sys_time_model  TM
 where
       SN.dbid            = TM.dbid
   and SN.instance_number = TM.instance_number
   and SN.snap_id         = TM.snap_id
   and TM.stat_name       = 'DB time'
),
DeltaDBtime
as
(select
       inst_num
      ,snap_id
      ,startup_time
      ,end_time
      ,DBtime_secs
      ,LAG(DBtime_secs,1) OVER (PARTITION BY inst_num, startup_time 
                                    ORDER BY snap_id ASC) 
               as begin_DBtime
      ,CASE WHEN begin_time = startup_time
            THEN DBtime_secs
            ELSE
            DBtime_secs - LAG(DBtime_secs,1) OVER (PARTITION BY inst_num, startup_time 
                                                       ORDER BY snap_id ASC)
            END
               as DBtime_secs_delta
      ,(end_time - begin_time)*24*60*60  as elapsed_secs
  from
       snapDBtime
 order by
       inst_num, snap_id ASC
)
select
       inst_num
      ,snap_id
      ,ROUND(DBtime_secs,1)                      as DBtime_secs
      ,ROUND(DBtime_secs_delta / elapsed_secs,3) as AvgActive_sess
  from 
       DeltaDBtime
/
