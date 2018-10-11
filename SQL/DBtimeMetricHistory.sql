--------------------------------------------------------------------
-- DBtimeMetricHistory.sql
--
-- AWR data extractor for load, response and avg active sessions data
-- output into comma-delimited format for spreadsheet import
--
-- Copyright(c) 2007 John Beresniewicz, Oracle USA
--------------------------------------------------------------------
set pagesize 0 linesize 128
set trimspool on

WITH BASEMETRICS
AS
(select  
        SM.instance_number                                     as inst_id
       ,D.dbid                                                 as dbid
       ,SM.snap_id                                             as snap_id
       ,CAST(SM.end_time AS DATE)                              as end_date
       ,SUM(CASE metric_id WHEN 2123 THEN SM.average ELSE 0 END) as DBTimePerSec
       ,SUM(CASE metric_id WHEN 2106 THEN SM.average ELSE 0 END) as SQLResponsePerCall
       ,SUM(CASE metric_id WHEN 2026 THEN SM.average ELSE 0 END) as UserCallPerSec
       ,SUM(CASE metric_id WHEN 2028 THEN SM.average ELSE 0 END) as RecursiveCallPerSec
       ,SUM(CASE metric_id WHEN 2109 THEN SM.average ELSE 0 END) as ResponsePerTxn
       ,SUM(CASE metric_id WHEN 2003 THEN SM.average ELSE 0 END) as TxnPerSec
       ,SUM(CASE metric_id WHEN 2057 THEN SM.average ELSE 0 END) as HostCPUutil
       ,SUM(CASE metric_id WHEN 2108 THEN SM.average ELSE 0 END) as DBCpuRatio
       ,SUM(CASE metric_id WHEN 2107 THEN SM.average ELSE 0 END) as DBWaitRatio
       ,SUM(CASE metric_id WHEN 2076 THEN SM.average ELSE 0 END) as CpuPerTxn
   from
        dba_hist_sysmetric_summary   SM
       ,v$database                   D
  where
        SM.group_id = 2
    and SM.metric_id IN (2123   -- DB Time per Sec
                        ,2109   -- Response per Txn
                        ,2106   -- SQL Service Response time
                        ,2003   -- User Txn per Sec
                        ,2026   -- User Calls Per Sec
                        ,2028   -- Recursive Calls Per Sec
                        ,2057   -- Host CPU Utilization (%)
                        ,2108   -- Database CPU Time Ratio
                        ,2107   -- Database Wait Time Ratio
                        ,2076   -- CPU Per Txn
                        )
  group by SM.instance_number, D.dbid, SM.end_time, SM.snap_id
)
,IOWAIT
AS
(select SN.instance_number   as inst_id
       ,SN.dbid              as dbid
       ,SN.snap_id           as snap_id
       ,NVL(WC.average_waiter_count,0) as AvgIoSess
   from
        dba_hist_snapshot              SN
       ,dba_hist_waitclassmet_history  WC
 where
        'User I/O' = WC.wait_class(+)
   and  SN.snap_id = WC.snap_id(+)
   and  SN.instance_number = WC.instance_number(+)
)
,NEWMETRICS 
AS
(select BM.inst_id, BM.dbid, BM.end_date
       ,DBTimePerSec / 100                             as AvgActiveSess
       ,(DBTimePerSec / 100) * (DBCpuRatio / 100)      as AvgCpuSess
       ,(DBTimePerSec / 100) * (DBWaitRatio / 100)     as AvgWaitSess
       ,IO.AvgIoSess                                   as AvgIoSess
       ,TxnPerSec                                      as TxnPerSec
       ,ResponsePerTxn / 100                           as SecPerTxn
       ,CpuPerTxn / 100                                as CpuSecPerTxn
       ,UserCallPerSec                                 as CallPerSec
       ,SQLResponsePerCall / 100                       as SecPerCall
  from 
        BASEMETRICS                    BM
       ,IOWAIT                         IO
 where
        BM.snap_id = IO.snap_id
   and  BM.dbid    = IO.dbid
   and  BM.inst_id = IO.inst_id
order by 1,2,3
)
select 
         inst_id               ||','
       ||dbid                  ||','
       ||to_char(end_date,'yy-mon-dd hh24:mi:ss')||','
       ||ROUND(AvgActiveSess,5)||','
       ||ROUND(AvgCpuSess,5)   ||','
       ||ROUND(AvgWaitSess,5)  ||','
       ||ROUND(AvgIoSess,5)    ||','
       ||ROUND(TxnPerSec,5)    ||','
       ||ROUND(SecPerTxn,9)    ||','
       ||ROUND(CpuSecPerTxn,9) ||','
       ||ROUND(CallPerSec,5)   ||','
       ||ROUND(SecPerCall,9)
                                      as data
  from
      NEWMETRICS
/

