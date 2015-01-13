#!/bin/bash
#
# Script: run_backup.sh
#
#
# Purpose: Backup an Oracle database using rman
#
# Usage:  run_backup.sh sid
#         where sid is the sid of the database to be backed up
#         Logfiles created in /backup/backup_scripts/logs
#

# number of days to keep files
#   used in find +mtime
#

DIR=`dirname $0`
PROG=`basename $0`


case $# in
1) export SID=$1
   ;;
*) echo "Usage:    $PROG  ORACLE_SID "
   echo ' '
   exit 1;
   ;;
esac

NDAYS=14
REMOTEDAYS=1


SID=$1
DATE=`date +%Y%m%d`; export DATE
DT=`date '+%Y%m%d_%H%M'` ; export DT

DEST=/mnt/orabackup/$SID


export PATH=/usr/local/bin:$PATH

. $HOME/.bash_profile
LOG_DIR=$HOME/logs
export logfile=$LOG_DIR/backup_archlogs_${SID}_${DT}.log
export errfile=$LOG_DIR/backup_archlogs_${SID}_${DT}.err

touch $logfile
{
echo "Backup of archive logs $SID started at `date` "
echo " "

if [ `egrep "^${SID}:" /etc/oratab|wc -l` -lt 1 ]; then
  echo "Invalid SID entered $SID"
  exit
fi
export ORAENV_ASK=NO
export ORACLE_SID=$SID
. oraenv > /dev/null 2> /dev/null

export NLS_DATE_FORMAT="dd-mon-yyyy hh24:mi:ss"
export TAG=Archlogs_${DT}
export TAGCF=Ctrl_File_${DT}

echo " "

rman target / <<EOF
run {
alter system switch logfile;

backup archivelog all tag $TAG;
backup current controlfile tag $TAGCF;
}
EOF


rman target / <<EOF
run {
 backup backupset completed after 'SYSDATE-$REMOTEDAYS' to destination '$DEST' tag='REMOTE';
}
EOF


}  >> $logfile

exit 0

{
if [ `grep -i "ora-" $logfile| wc -l` -gt 0 -o `grep -i "rman-" $logfile| wc -l` -gt 0 ]; then
  echo " "
  echo "Errors in backup "
  echo " "
  grep -i "ora-" $logfile
  grep -i "rman-" $logfile
  echo " "
  echo "LOGILE = " $logfile >> $errfile
  echo "Errors in backup " >> $errfile
  echo " ">> $errfile
  grep -i "ora-" $logfile >> $errfile
  grep -i "rman-" $logfile >> $errfile
  echo " " >> $errfile
#  ./send_email.sh "$ORACLE_SID Backup errors" $errfile email_list.txt
  chmod 664 $errfile
fi
} >>  $logfile

exit 0


echo " "
echo "Backup of archive logs $SID completed at `date` "

} >> $logfile

# Set permissions on logfile and backups to 775 so that anyone in the DBA gorup
# can purge them.
#
chmod 664 $logfile


#end of script

