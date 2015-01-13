#!/bin/bash

ORACLE_HOME=/u01/obiee/EXALYTICS_MWHOME

PROG=`basename $0`
DIR=`dirname $0`
cd $DIR


LOGDIR=$DIR/logs
LOG=$LOGDIR/${PROG%.sh}.log

dt=`date +"%Y_%m_%d"`

OPBIN=$ORACLE_HOME/instances/instance1/bin

rotate_log() {
       mv $LOG ${LOG}_$dt.bak
       touch $LOG 
       nohup gzip ${LOG}_$dt.bak &
}

start() {
    rotate_log
     mkdir /mnt/ramdisk_test/cache 2>/dev/null 
    $OPBIN/opmnctl startall >>$LOG 
}

stop() {
    $OPBIN/opmnctl stopall >>$LOG 
}

status() {
    $OPBIN/opmnctl status -l
}



case $1  in
[Ss][Tt][Aa][Rr][Tt])
    start ; (date ; status ) >>$LOG
;;

[Ss][Tt][Oo][Pp])
    date >>$LOG ; stop
;;

*)
    status
;;
esac


