#!/bin/bash

TT_HOME=/u01/obiee/TimesTen/tt1122

PROG=`basename $0`
DIR=`dirname $0`
cd $DIR

LOGDIR=$DIR/logs
LOG=$LOGDIR/${PROG%.sh}.log

dt=`date +"%Y_%m_%d"`

rotate_log() {
       mv $LOG ${LOG}_$dt.bak
       touch $LOG 
       nohup gzip ${LOG}_$dt.bak &
}

start() {
      daemon=`$TT_HOME/bin/ttStatus 2>/dev/null | /bin/grep -w 'Daemon pid [0-9]*.*tt1122'`
      if [ "x$daemon" = "x" ]
      then
          echo nohup $TT_HOME/startup/tt_tt1122 start ## $LOG
      else 
          echo  Already running $daemon
      fi
}

stop() {
    nohup $TT_HOME/startup/tt_tt1122 stop >> $LOG
}

status() {
    echo ' '
    $TT_HOME/bin/ttStatus
    echo ' '
}

case $1  in
[Ss][Tt][Aa][Rr][Tt])
    start
;;

[Ss][Tt][Oo][Pp])
    stop
;;

*)
    status
;;

esac
