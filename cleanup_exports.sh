#!/bin/bash

usage () {
   echo
  echo "  Usage:  $0 "
  echo "     Cleans out /oradata2/EXPORTS/OBIPRD directories"
  echo
  exit 1
}
if [ $#  != 0 ]
then
 usage 
fi

# Directory to check
export DIR_CHK=/oradata2/EXPORTS/OBIPRD
# No of sub-directories to keep
export limit=2



PROG=`basename $0`
DIR=`dirname $0`
cd $DIR

# Purge logs older than this (days)
export PURGE_AGE=32
# in this directory
export LOG_DIR=$DIR/logs

export datestamp=`date +"%Y_%m_%d"`

{
echo  Starting $0   at  `date`
echo
if [ `ls -1 ${DIR_CHK} | wc -l`  -gt ${limit} ]
 then
   cd  ${DIR_CHK}
   dirs_to_delete=`ls -dtr *  |  tail +\`expr ${limit} + 1\` `
   echo
   echo  Directories to delete :
   echo rm -rf ${DIR_CHK}/$dirs_to_delete
   rm -rf $dirs_to_delete
  else
   echo No files to clean up in ${DIR_CHK}
fi


echo
echo  Logfiles to delete :
find $LOG_DIR -name "*.log" -mtime +${PURGE_AGE} -print
find $LOG_DIR -name "*.log" -mtime +${PURGE_AGE}  -exec rm {} \;
echo
echo  Finished $0   at  `date`

}   >  $DIR/logs/${PROG}_$datestamp.log
