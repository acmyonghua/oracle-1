#!/bin/bash

ORACLE_HOME=/u01/obiee/EXALYTICS_MWHOME

PROG=`basename $0`
DIR=`dirname $0`
cd $DIR


LOGDIR=$DIR/logs
LOG=$LOGDIR/${PROG%.sh}.log

dt=`date +"%Y_%m_%d"`

rotate_log() {
       mv $LOG ${LOG}_$dt.bak
       touch $LOG 
       gzip ${LOG}_$dt.bak &
}

start() {
    rotate_log
    $ORACLE_HOME/user_projects/domains/bifoundation_domain/bin/startManagedWebLogic.sh bi_server1 http://HLT439A006.had.sa.gov.au:7001 > $LOG &
}

stop() {
    $ORACLE_HOME/user_projects/domains/bifoundation_domain/bin/stopManagedWebLogic.sh bi_server1 t3://HLT439A006.had.sa.gov.au:7001 > $LOG
}

status() {
    ps -ef | grep startManagedWebLogic.sh |  grep $USER | grep -v grep | gawk -F' ' '{ print $2 }' | xargs -r pstree -Aal 2>/dev/null | head -4 
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

