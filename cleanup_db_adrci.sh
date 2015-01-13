#!/bin/bash

usage () {
   echo
  echo "  Usage:  $0 "
  echo "     Cleans out database log files and directories"
  echo
  exit 1
}
if [ $#  != 0 ]
then
 usage
fi


PROG=`basename $0`
DIR=`dirname $0`
cd $DIR
dt=`date "+%Y_%m_%d"`

{
echo  Starting $0   at  `date`
echo

### REMOVE LISTENER LOGS ###

#cd /apps/oracle/diag/tnslsnr/hlt797obi001/listener/alert
#rm -rf log_*xml

cd /apps/oracle/diag/tnslsnr/hlt797obi001/listener/trace
mv  listener.log listener_${dt}.log
gzip listener_${dt}.log
 ls -l $PWD/*gz

. $HOME/.profile
cd $DIR


# Purge ADR contents (adr_purge.sh)
echo "INFO: adrci purge started at `date`"
adrci exec="show homes"|grep -v : | while read file_line
do
echo "INFO: adrci purging diagnostic destination " $file_line
echo "INFO: purging ALERT older than 90 days"
adrci exec="set homepath $file_line;purge -age 129600 -type ALERT"
echo "INFO: purging INCIDENT older than 30 days"
adrci exec="set homepath $file_line;purge -age 43200 -type INCIDENT"
echo "INFO: purging TRACE older than 30 days"
adrci exec="set homepath $file_line;purge -age 43200 -type TRACE"
echo "INFO: purging CDUMP older than 30 days"
adrci exec="set homepath $file_line;purge -age 43200 -type CDUMP"
echo "INFO: purging HM older than 30 days"
adrci exec="set homepath $file_line;purge -age 43200 -type HM"
echo ""
echo ""
done
echo
echo "INFO: adrci purge finished at `date`"

echo
echo  Finished $0   at  `date`

}   >  $DIR/logs/${PROG}_$datestamp.log



