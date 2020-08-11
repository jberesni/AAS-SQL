------------------------------------------------------
-- queries to chart AAS and avg wait latency estimates
-- from v$active_session_history
-- for Grafana plug-in
------------------------------------------------------
WITH ash_1min_summary AS
(select
    trunc(sample_time,'MI')     as minit
    ,session_state||':'||wait_class  as cpuwait_class
    ,SUM(usecs_per_row)         as usecs
    ,SUM(CASE WHEN (session_state = 'WAITING' AND time_waited > 0)
                THEN GREATEST(usecs_per_row/time_waited,1)
              WHEN (session_state = 'WAITING' AND time_waited = 0)
                THEN 0    -- un-fixed-up waits
              ELSE 1      -- CPU
              END)               as  cpuwait_count
from
    v$active_session_history
group by
    trunc(sample_time,'MI')
    ,session_state||':'||wait_class
)
select --*
    cpuwait_class
    ,minit
    ,SUM(usecs/1000000/60)                                  as avg_active_sessions
    ,CASE WHEN SUM(cpuwait_count) = 0 
           THEN 0
          ELSE SUM(usecs/1000)/SUM(cpuwait_count)
          END                                              as avg_latency_msecs
from
    ash_1min_summary
group by
    cpuwait_class
    ,minit
order by
    cpuwait_class
    ,minit ASC
;