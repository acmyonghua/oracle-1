define V_INSTANCE=EB2PROD
define V_NBR_DAYS=366
set pages 200
with v as 
 (select  yyyymmdd sort0,
        daily_ranking sort1,
        day,
	type,
	name,
	secs,
	pct_total*100 pct_total,
	sum(pct_total*100) over (partition by yyyymmdd
				 order by daily_ranking
				 rows unbounded preceding) cum_pct_total
from	(select	to_char(ss.snap_time, 'YYYYMMDD') yyyymmdd,
		to_char(ss.snap_time, 'DD-MON') day,
		s.type,
		s.name,
		sum(s.secs) secs,
		ratio_to_report(sum(s.secs))
			over (partition by to_char(ss.snap_time, 'YYYYMMDD')) pct_total,
		rank () over (partition by to_char(ss.snap_time, 'YYYYMMDD')
				order by sum(s.secs) desc) daily_ranking
	 from   (select dbid,
			instance_number,
			snap_id,
			'Wait' type,
			event name,
			nvl(decode(greatest(time_waited_micro,
					    nvl(lag(time_waited_micro,1,0)
						over (partition by dbid,
								   instance_number,
								   event
							order by snap_id),time_waited_micro)),
				   time_waited_micro,
				   time_waited_micro - lag(time_waited_micro,1,0)
						over (partition by dbid,
								   instance_number,
								   event
						order by snap_id),
					time_waited_micro), time_waited_micro)/1000000 secs
		 from	stats$system_event
		 where	time_waited_micro > 0
		 and	event not in (select event from stats$idle_event)
		 union all
	 	 select t.dbid,
			t.instance_number,
			t.snap_id,
			'Service' type,
	                'SQL execution' name,
			nvl(decode(greatest(t.value,
					    nvl(lag(t.value,1,0)
						over (partition by t.dbid,
								   t.instance_number
							order by t.snap_id),t.value)),
				   t.value,
				   (t.value - (p.value + r.value)) - lag((t.value - (p.value + r.value)),1,0)
						over (partition by t.dbid,
								   t.instance_number
						order by t.snap_id),
					(t.value - (p.value + r.value))),
			    (t.value - (p.value + r.value)))/100 secs
	         from   stats$sysstat t,
	                stats$sysstat p,
	                stats$sysstat r
	         where	t.dbid = p.dbid
	         and	r.dbid = t.dbid
	         and	t.instance_number = p.instance_number
	         and	r.instance_number = t.instance_number
	         and	t.snap_id = p.snap_id
	         and	r.snap_id = t.snap_id
		 and	t.name = 'CPU used by this session'
	         and	p.name = 'recursive cpu usage'
	         and	r.name = 'parse time cpu'
		 union all
		 select dbid,
			instance_number,
			snap_id,
			'Service' type,
			'Recursive SQL execution' name,
			nvl(decode(greatest(value,
					    nvl(lag(value,1,0)
						over (partition by dbid,
								   instance_number
							order by snap_id),value)),
				   value,
				   value - lag(value,1,0)
						over (partition by dbid,
								   instance_number
						order by snap_id),
					value), value)/100 secs
		 from   stats$sysstat
		 where  name = 'recursive cpu usage'
		 and    value > 0
		 union all
		 select dbid,
			instance_number,
			snap_id,
		 	'Service' type,
			'Parsing SQL' name,
			nvl(decode(greatest(value,
					    nvl(lag(value,1,0)
						over (partition by dbid,
								   instance_number
							order by snap_id),value)),
				   value,
				   value - lag(value,1,0)
						over (partition by dbid,
								   instance_number
						order by snap_id),
					value), value)/100 secs
		 from   stats$sysstat
		 where  name = 'parse time cpu'
		 and    value > 0)			s,
		stats$snapshot				ss,
		(select distinct dbid,
				 instance_number,
				 instance_name
		 from	stats$database_instance)        i
	 where	i.instance_name = '&&V_INSTANCE'
	 and	s.dbid = i.dbid
	 and	s.instance_number = i.instance_number
	 and	ss.snap_id = s.snap_id
	 and    ss.dbid = s.dbid
	 and    ss.instance_number = s.instance_number
	 and    ss.snap_time between trunc(sysdate - &&V_NBR_DAYS) and sysdate
	 group by to_char(ss.snap_time, 'YYYYMMDD'),
		  to_char(ss.snap_time, 'DD-MON'),
		  s.type,
		  s.name
	 having sum(s.secs) > 0
	 order by yyyymmdd, secs)
where   daily_ranking <= 12
order by sort0, sort1
)
select   to_char(to_date(s.sort0,'YYYYMMDD'), 'ww') Week, sum(s.secs) service, sum(w.secs) wait
from     v s, v w
where    s.sort0 = w.sort0
group by to_char(to_date(s.sort0,'YYYYMMDD'), 'ww')
/
