#!/usr/bin/bash
#
# Database export script
#

. $HOME/.profile

DIR=`dirname $0`
PROG=`basename $0`
dt=`date "+%Y_%m_%d_%H%M"`
dest=`date "+%Y_%m_%d"`

EXP_DIR=/oradata2/EXPORTS/OBIPRD
LOGFILE=${DIR}/logs/${PROG}_$dt.log

{
echo "Starting $PROG at `date`"
echo
echo

export PATH=$PATH:/usr/local/bin/
export ORAENV_ASK=NO
export ORACLE_SID=OBIPRD

. oraenv -s

sqlplus -S / as sysdba <<EOF
set echo on
 ALTER DATABASE BACKUP CONTROLFILE TO TRACE;
EOF

echo
echo

  expdp "'/as sysdba'" DIRECTORY=EXPORTS DUMPFILE=$ORACLE_SID.$dt.%u.dmp LOGFILE=$ORACLE_SID.$dt.log full=y parallel=8 compression=all flashback_time=sysdate  2>&1

echo
echo "Backup Completed at: `date`"
echo

if [ -f $EXP_DIR/$ORACLE_SID*01.dmp ]
then
    echo "  Moving Backups to $EXP_DIR/$dest"
    mkdir -p  $EXP_DIR/$dest 2>/dev/null
    mv $EXP_DIR/*dmp $EXP_DIR/*log $EXP_DIR/$dest
else
    echo "  No .dmp files in $EXP_DIR"
fi

echo
echo "Finished $PROG at `date`"
}   > $LOGFILE


