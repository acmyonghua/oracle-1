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


# also sends a second backup to $DEST
#
#

# number of days to keep files
#   used in find +mtime
#

case $# in
1) export SID=$1
   ;;
*) echo 'Usage:    run_backup.sh ORACLE_SID '
   echo ' '
   exit 1;
   ;;
esac

# Days to keep log files
NDAYS=14
fra_top=/orafra

SID=$1
#Remote backup info 

DEST=/mnt/orabackup/$SID
export PASSWD=ic3mann4#

MOUNTCMD="mount /mnt/orabackup"
#MOUNTCMD="echo   mount ..    $DEST"
REMOTEDAYS=1

DATE=`date +%Y%m%d`; export DATE
DT=`date '+%Y%m%d_%H%M'` ; export DT

export PATH=/usr/local/bin:$PATH

. $HOME/.bash_profile
LOG_DIR=$HOME/logs
export logfile=$LOG_DIR/backup_${SID}_${DT}.log
export errfile=$LOG_DIR/backup_${SID}_${DT}.err

touch $logfile
{
echo "Backup of database $SID started at `date` "
echo " "

if [ `egrep "^${SID}:" /etc/oratab|wc -l` -lt 1 ]; then
  echo "Invalid SID entered $SID"
  exit
fi
export ORAENV_ASK=NO
export ORACLE_SID=$SID
. oraenv > /dev/null 2> /dev/null



# FOR COLD BACKUPS ONLY:
#sqlplus -S / as sysdba <<EOF
#shutdown immediate
#startup mount
#EOF


export NLS_DATE_FORMAT="dd-mon-yyyy hh24:mi:ss"
export TAG=Daily_${DT}
export TAGCF=Ctrl_File_${DT}

echo " "

rman target / <<EOF
run {
backup database plus archivelog  tag $TAG;
backup current controlfile tag $TAGCF;
#delete noprompt obsolete;
}
EOF

rman target / <<EOF
report unrecoverable ;
EOF

# FOR COLD BACKUPS ONLY:
#sqlplus -S / as sysdba <<EOF
#alter database open;
#EOF

# Now try to backup to $DEST

if [ ! -d $DEST ]; then
  # mount if directory is not available
  $MOUNTCMD 
  if [ ! -d $DEST ]; then
          echo "ERROR: Backup destination $DEST does not exist!"
  fi
fi

if [ -d $DEST ]; then
# Starting remote BACKUP TO $DEST
rman target=/ <<EOF
run {
 # remove references to files removed manually  
  delete noprompt expired backupset;

  # copy backups (last 1 days) from FRA to $DEST (will be copied to tape)
  backup backupset completed after 'SYSDATE-$REMOTEDAYS' to destination '$DEST' tag='REMOTE';

  # delete old backups from $DEST
  delete backupset tag='REMOTE' completed before 'SYSDATE-$REMOTEDAYS';
}
exit
EOF
	 else
      echo "ERROR: Skipping remote backup to $DEST "
  fi
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
}  >> $logfile

exit 0

echo " "
echo "Ensure no old files remain unpurged in the FRA"
cd $fra_top/$ORACLE_SID/archivelog
echo "Archive logs to be purged"
find . -name "*.arc" -mtime +$NDAYS -ls
find . -name "*.arc" -mtime +$NDAYS -exec rm {} \;

echo " "
echo "Backupsets in the FRA to be purged"
cd $fra_top/$ORACLE_SID/backupset
find . -name "*.bkp" -mtime +$NDAYS -ls
find . -name "*.bkp" -mtime +$NDAYS -exec rm {} \;

echo " "
echo "Autobackups in the FRA to be purged"
cd $fra_top/$ORACLE_SID/autobackup
find . -name "*.bkp" -mtime +$NDAYS -ls
find . -name "*.bkp" -mtime +$NDAYS -exec rm {} \;

echo " "
echo "Cross check archivelogs and backupsets in rman"
echo " "

rman target / <<eof
run {
crosscheck archivelog all;
delete noprompt expired archivelog all;

crosscheck backup;
delete noprompt expired backup;
}
eof

echo " "
echo "Backup of database $SID completed at `date` "

} >> $logfile

# Set permissions on logfile and backups to 775 so that anyone in the DBA gorup
# can purge them.
#
chmod 664 $logfile


#end of script

