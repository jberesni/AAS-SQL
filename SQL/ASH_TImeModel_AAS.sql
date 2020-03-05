WITH time_model
AS
(select  
     A.begin_time, A.end_time
    ,A.value as TimeModel_AAS
    ,B.value/100 as TimeModel_AACPU
from
      v$con_sysmetric_history A
     ,v$con_sysmetric_history B
where
      A.metric_name = 'Average Active Sessions'
and   B.metric_name = 'CPU Usage Per Sec'
and   A.begin_time  = B.begin_time
and   A.end_time    = B.end_time
and   A.con_id      = B.con_id -- just in case
),
TM_ASH as
(select
     TM.begin_time, TM.end_time
    ,ROUND(SUM(ASH.usecs_per_row)/(60*1000000),1) as ASH_AAS
    ,ROUND(SUM(CASE ASH.session_state WHEN 'ON CPU' then ASH.usecs_per_row else 0 END)/(60*1000000),1) as ASH_AACPU
    ,ROUND(AVG(TM.TimeModel_AAS),1)   as TimeModel_AAS
    ,ROUND(AVG(TM.TimeModel_AACPU),1) as TimeModel_AACPU
from
     time_model TM
    ,v$active_session_history ASH
where
    ASH.sample_time BETWEEN TM.begin_time and TM.end_time
and ASH.session_type = 'FOREGROUND'
group by
    TM.begin_time, TM.end_time
)
select end_time
      ,ROUND(100*(TimeModel_AAS - ASH_AAS)/TimeModel_AAS,1) as DBtime_PctDiff
      ,ROUND(100*(TimeModel_AACPU - ASH_AACPU)/TimeModel_AACPU,1) as DBCPU_PctDiff
      ,ASH_AAS, TimeModel_AAS
      ,ASH_AACPU, TimeModel_AACPU
from
     TM_ASH
order by
    end_time ASC;
