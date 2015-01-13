/**********************************************************************
 * File:	sp_systime_9i.sql
 * Type:	SQL*Plus script
 * Author:	Tim Gorman (Evergreen Database Technologies, Inc)
 * Date:	28-Aug-04
 *
 * Description:
 *	SQL*Plus script to display a breakdown of where the database
 *	is spending it's time.  The first part of the report shows a
 *	breakdown by day and the second part of the report shows a
 *	breakdown by hour.
 *
 *	This report utilizes information from the STATSPACK repository
 *	tables, specifically wait-event information from the table
 *	STATS$SYSTEM_EVENT and CPU statistics from the table
 *	STATS$SYSSTAT.  The script will prompt for the number of days
 *	to report upon...
 *      
 *	This version of the script is intended for Oracle9i, which
 *	records timing information in V$SYSTEM_EVENT in micro-seconds
 *	(1/1000000ths of a second), and V$SYSSTAT info in centi-seconds
 *	(1/100ths of a second) like 8i.
 *
 * Modifications:
 * TGorman 19feb2006	modified to remove bug in calculating "SQL
 *			execution" figures...
 *********************************************************************/
break on report on username on sid skip 1
set pagesize 100 lines 130 trimspool on trimout on verify off recsep off

col sort0 noprint
col sort1 noprint   
col day heading "Day"
col hr heading "Hour"
col type format a8 heading "Service|or Wait"
col name format a35 heading "Name" truncate
col secs format 999,999,999,990.00 heading "Total|Seconds|Spent"
col pct_total format 990.00 heading "% of|Total"
col cum_pct_total format 990.00 heading "Cum|% of|Total"

accept V_INSTANCE prompt "Please enter the ORACLE_SID value: "
accept V_NBR_DAYS prompt "Please enter the number of days to report upon: "

spool sp_systime_&&V_INSTANCE
clear breaks computes
break on day skip 1 on report
select  yyyymmdd sort0,
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
order by sort0, sort1;

clear breaks computes
break on day skip 1 on hr on report
select  yyyymmddhh24 sort0,
        hourly_ranking sort1,
        day,
	hr,
	type,
	name,
	secs,
	pct_total*100 pct_total,
	sum(pct_total*100) over (partition by yyyymmddhh24
				 order by hourly_ranking
				 rows unbounded preceding) cum_pct_total
from	(select	to_char(ss.snap_time, 'YYYYMMDDHH24') yyyymmddhh24,
		to_char(ss.snap_time, 'DD-MON') day,
		to_char(ss.snap_time, 'HH24')||':00' hr,
		s.type,
		s.name,
		sum(s.secs) secs,
		ratio_to_report(sum(s.secs))
			over (partition by to_char(ss.snap_time, 'YYYYMMDDHH24')) pct_total,
		rank () over (partition by to_char(ss.snap_time, 'YYYYMMDDHH24')
				order by sum(s.secs) desc) hourly_ranking
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
	 group by to_char(ss.snap_time, 'YYYYMMDDHH24'),
		  to_char(ss.snap_time, 'DD-MON'),
		  to_char(ss.snap_time, 'HH24')||':00',
		  s.type,
		  s.name
	 having sum(s.secs) > 0
	 order by yyyymmddhh24, secs)
where   hourly_ranking <= 6
order by sort0, sort1;
spool off

set pagesize 0
clear breaks computes
break on day skip 1 on report
spool sp_systime_&&V_INSTANCE..csv
select  yyyymmdd sort0,
        daily_ranking sort1,
        day||','||type||','||name||','||round(secs,2)||','||round(pct_total*100,2) txt
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
order by sort0, sort1;
spool off
set pagesize 100