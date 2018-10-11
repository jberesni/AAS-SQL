--------------------------------------------------------------------
-- LittlesLawAAS.sql
--
-- Demonstrates/tests that Little's Law works for call or transaction
-- black box views of database:
-- N = X * R 
-- where:
--       N is Average active sessions
--       X is throughput (txn per sec or calls per sec)
--       R is response time (per txn or per call)
--
-- Copyright(c) 2007 John Beresniewicz, Oracle USA
--------------------------------------------------------------------

WITH BASEMETRICS
AS
(select  
        SM.inst_id                                             as inst_id
       ,D.dbid                                                 as dbid
       ,CAST(SM.end_time AS DATE)                              as end_date
       ,SUM(CASE metric_id WHEN 2123 THEN SM.value ELSE 0 END) as DBTimePerSec
       ,SUM(CASE metric_id WHEN 2106 THEN SM.value ELSE 0 END) as SQLResponsePerCall
       ,SUM(CASE metric_id WHEN 2026 THEN SM.value ELSE 0 END) as UserCallPerSec
       ,SUM(CASE metric_id WHEN 2028 THEN SM.value ELSE 0 END) as RecursiveCallPerSec
       ,SUM(CASE metric_id WHEN 2109 THEN SM.value ELSE 0 END) as ResponsePerTxn
       ,SUM(CASE metric_id WHEN 2003 THEN SM.value ELSE 0 END) as TxnPerSec
   from
        gv$database           D
       ,gv$sysmetric_history  SM
  where
        SM.group_id = 2
    and SM.metric_id IN (2123   -- DB Time per Sec
                        ,2109   -- Response per Txn
                        ,2106   -- SQL Service Response time
                        ,2003   -- User Txn per Sec
                        ,2026   -- User Calls Per Sec
                        ,2028   -- Recursive Calls Per Sec
                        )
    and D.inst_id = SM.inst_id
  group by SM.inst_id, D.dbid,SM.end_time
)
select  inst_id
       ,dbid
       ,TO_CHAR(end_date,'yy-mon-dd hh24:mi:ss')       as end_date
       ,DBTimePerSec / 100                             as AvgActiveSessions
       ,(SQLResponsePerCall * (UserCallPerSec+RecursiveCallPerSec) ) / 100   as AvgActiveCalls
       ,(ResponsePerTxn * TxnPerSec) / 100             as AvgActiveTxns
from 
     BASEMETRICS
order by 1,2,3
/
