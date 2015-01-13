/**********************************************************************
 * File:        sp_evtrends.sql
 * Type:        SQL*Plus script
 * Author:      Tim Gorman (SageLogix, Inc.)
 * Date:        15-Jul-2003
 *
 * Description:
 *      Query to display "trends" for specific statistics captured by
 *	the STATSPACK package, and display summarized totals daily and
 *	hourly as a ratio using the RATIO_FOR_REPORT analytic function.
 *
 *	The intent is to find the readings with the greatest deviation
 *	from the average value, as these are likely to be "periods of
 *	interest" for further, more detailed research...
 *
 *	This version of the script is intended for Oracle9i, which
 *	records TIME_WAITED_MICRO in micro-seconds (1/100,000ths of
 *	a second).
 *
 * Modifications:
 *	TGorman 02may04	corrected bug in LAG() OVER () clauses
 *	TGorman	10aug04	changed "deviation" column from some kind of
 *			weird "deviation from average" calculation to
 *			a more straight-forward percentage ratio
 *	TGorman	25aug04	use "ratio_to_report()" function instead
 *********************************************************************/
set echo off feedback off timing off pagesize 200 linesize 500
set trimout on trimspool on verify off recsep off
col sort0 noprint
col day format a6 heading "Day"
col hr format a6 heading "Hour"
col total_waits format 999,990 heading "Total|Waits (m)"
col time_waited format 999,990.00 heading "Secs|Waited"
col tot_wts format 990.00 heading "% Total|Waits"
col tot_pct format 990.00 heading "% Secs|Waited"
col avg_wait format 990.00 heading "Avg|hSecs|Per|Wait"
col avg_pct format 990.00 heading "% Avg|hSecs|Per|Wait"
col wt_graph format a18 heading "Graphical view|of % total|waits overall"
col tot_graph format a18 heading "Graphical view|of % total|secs waited overall"
col avg_graph format a18 heading "Graphical view|of % avg hSecs|per wait overall"

accept V_NBR_DAYS prompt "How many days of data to examine? "
prompt
prompt
prompt Some useful database statistics to search upon:
col name format a60 heading "Name"
select  chr(9)||name name
from	v$event_name
order by 1;
accept V_EVENTNAME prompt "What wait-event do you want to analyze? "

col spoolname new_value V_SPOOLNAME noprint
col instance_name new_value V_INSTAnCE noprint
select  replace(replace(replace(lower('&&V_EVENTNAME'),' ','_'),'(',''),')','') spoolname,
	instance_name
from    v$instance;

spool sp_evtrends_&&V_INSTANCE._&&V_SPOOLNAME
clear breaks computes
break on day skip 1 on report
compute avg of total_waits on report
compute avg of time_waited on report
compute avg of avg_wait on report
col ratio format a60 heading "Percentage of total over all days"
col name format a30 heading "Statistic Name"
prompt
prompt Daily trends for "&&V_EVENTNAME" in database instance "&&V_INSTANCE"...
select  sort0,
	day,
	total_waits/1000000 total_waits,
	(ratio_to_report(total_waits) over ()*100) tot_wts,
	rpad('*', round((ratio_to_report(total_waits) over ()*100)/6, 0), '*') wt_graph,
	time_waited,
	(ratio_to_report(time_waited) over ()*100) tot_pct,
	rpad('*', round((ratio_to_report(time_waited) over ()*100)/6, 0), '*') tot_graph,
	avg_wait*100 avg_wait,
	(ratio_to_report(avg_wait) over ()*100) avg_pct,
	rpad('*', round((ratio_to_report(avg_wait) over ()*100)/6, 0), '*') avg_graph
from	(select	sort0,
		day,
		name,
		sum(total_waits) total_waits,
		sum(time_waited) time_waited,
		decode(sum(total_waits),0,0,(sum(time_waited)/sum(total_waits))) avg_wait
	 from	(select	to_char(ss.snap_time, 'YYYYMMDD') sort0,
			to_char(ss.snap_time, 'DD-MON') day,
			s.snap_id,
			s.event name,
			nvl(decode(greatest(s.time_waited_micro,
					    lag(s.time_waited_micro,1,0) over
							(partition by	s.dbid,
									s.instance_number,
									s.event
							 order by s.snap_id)),
				   s.time_waited_micro,
					s.time_waited_micro -
					lag(s.time_waited_micro,1,0) over
						(partition by	s.dbid,
								s.instance_number,
								s.event
						 order by s.snap_id),
					s.time_waited_micro), 0)/1000000 time_waited,
			nvl(decode(greatest(s.total_waits,
					    lag(s.total_waits,1,0) over
							(partition by	s.dbid,
									s.instance_number,
									s.event
							 order by s.snap_id)),
				   s.total_waits,
					s.total_waits -
					lag(s.total_waits,1,0) over
						(partition by	s.dbid,
								s.instance_number,
								s.event
						 order by s.snap_id),
					s.total_waits), 0) total_waits
		 from	stats$system_event			s,
			stats$snapshot				ss,
			(select distinct
				dbid,
				instance_number
			 from	stats$database_instance
			 where	instance_name = '&&V_INSTANCE')	i
		 where	ss.dbid = i.dbid
		 and	ss.instance_number = i.instance_number
		 and	ss.snap_time between (sysdate - &&V_NBR_DAYS) and sysdate
		 and	s.snap_id = ss.snap_id
		 and	s.dbid = ss.dbid
		 and	s.instance_number = ss.instance_number
		 and	s.event like '%'||'&&V_EVENTNAME'||'%')
	 group by sort0,
		  day,
		  name)
order by sort0, name;

clear breaks computes
break on day skip 1 on hr on report
compute avg of total_waits on report
compute avg of time_waited on report
compute avg of avg_wait on report
col ratio format a60 heading "Percentage of total over all hours for each day"
prompt
prompt Daily/hourly trends for "&&V_EVENTNAME" in database instance "&&V_INSTANCE"...
select  sort0,
	day,
	hr,
	total_waits/1000000 total_waits,
	(ratio_to_report(total_waits) over (partition by day)*100) tot_wts,
	rpad('*', round((ratio_to_report(total_waits) over (partition by day)*100)/4, 0), '*') wt_graph,
	time_waited,
	(ratio_to_report(time_waited) over (partition by day)*100) tot_pct,
	rpad('*', round((ratio_to_report(time_waited) over (partition by day)*100)/4, 0), '*') tot_graph,
	avg_wait*100 avg_wait,
	(ratio_to_report(avg_wait) over (partition by day)*100) avg_pct,
	rpad('*', round((ratio_to_report(avg_wait) over (partition by day)*100)/4, 0), '*') avg_graph
from	(select	sort0,
		day,
		hr,
		name,
		sum(total_waits) total_waits,
		sum(time_waited) time_waited,
		decode(sum(total_waits),0,0,(sum(time_waited)/sum(total_waits))) avg_wait
	 from	(select	to_char(ss.snap_time, 'YYYYMMDDHH24') sort0,
			to_char(ss.snap_time, 'DD-MON') day,
			to_char(ss.snap_time, 'HH24')||':00' hr,
			s.snap_id,
			s.event name,
			nvl(decode(greatest(s.time_waited_micro,
					    lag(s.time_waited_micro,1,0) over
							(partition by	s.dbid,
									s.instance_number,
									s.event
							 order by s.snap_id)),
				   s.time_waited_micro,
					s.time_waited_micro -
					lag(s.time_waited_micro,1,0) over
						(partition by	s.dbid,
								s.instance_number,
								s.event
						 order by s.snap_id),
					s.time_waited_micro), 0)/1000000 time_waited,
			nvl(decode(greatest(s.total_waits,
					    lag(s.total_waits,1,0) over
							(partition by	s.dbid,
									s.instance_number,
									s.event
							 order by s.snap_id)),
				   s.total_waits,
					s.total_waits -
					lag(s.total_waits,1,0) over
						(partition by	s.dbid,
								s.instance_number,
								s.event
						 order by s.snap_id),
					s.total_waits), 0) total_waits
		 from	stats$system_event			s,
			stats$snapshot				ss,
			(select distinct
				dbid,
				instance_number
			 from	stats$database_instance
			 where	instance_name = '&&V_INSTANCE')	i
		 where	ss.dbid = i.dbid
		 and	ss.instance_number = i.instance_number
		 and	ss.snap_time between (sysdate - &&V_NBR_DAYS) and sysdate
		 and	s.snap_id = ss.snap_id
		 and	s.dbid = ss.dbid
		 and	s.instance_number = ss.instance_number
		 and	s.event like '%'||'&&V_EVENTNAME'||'%')
	 group by sort0,
		  day,
		  hr,
		  name)
order by sort0, name;
spool off
set verify on recsep wrap