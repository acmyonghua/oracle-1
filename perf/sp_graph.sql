set pages 200


spool graph
Prompt   Daily Summary
select   to_date(s.sort0,'YYYYMMDD') Day,
         round(sum(case when type = 'Service' then s.secs else null end) ) service,
         round(sum(case when type = 'Wait'    then s.secs else null end) ) wait
from     sp_graph s
group by  to_date(s.sort0,'YYYYMMDD')
/

Prompt   Weekly Summary
select   to_char(to_date(s.sort0,'YYYYMMDD'), 'ww') Week,
         round(sum(case when type = 'Service' then s.secs else null end) ) service,
         round(sum(case when type = 'Wait'    then s.secs else null end) ) wait
from     sp_graph s
group by to_char(to_date(s.sort0,'YYYYMMDD'), 'ww')
/

