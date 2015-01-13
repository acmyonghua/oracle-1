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
    rotate_log  > /dev/null
    $ORACLE_HOME/wlserver_10.3/server/bin/startNodeManager.sh >> $LOG   &
    sleep 30
}

stop() {
    ps -ef | grep NodeManager         | grep -v grep | grep $USER | gawk -F' ' '{ print $2 }' | xargs -r kill -9
}

status() {
    ps -ef | grep startNodeManager.sh | grep -v grep | grep $USER | gawk -F' ' '{ print $2 }' | xargs -r pstree -Aal | head -4
}

case $1 in
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


