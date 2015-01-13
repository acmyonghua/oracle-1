#!/bin/bash

PROG=`basename $0`

COLS='*'
WHERE='where rownum<9'

case $# in
1) export SCHEMA=SYS
   export OWNER=`echo $1 | tr '[a-z]' '[A-Z]'`
   export  TABLE=DBA_TABLES
   export  SEP=\,
   export COLS='owner schema, table_name '
   WHERE=`echo "$WHERE and owner='$OWNER' " ` 
   ;;
2) export SCHEMA=`echo $1 | tr '[a-z]' '[A-Z]'`
   export  TABLE=`echo $2 | tr '[a-z]' '[A-Z]'` 
   export  SEP=\, 
   ;;
3) export SCHEMA=`echo $1 | tr '[a-z]' '[A-Z]'`
   export  TABLE=`echo $2 | tr '[a-z]' '[A-Z]'`  
   export  SEP=$3
   ;;
*) echo "Usage:   $PROG SCHEMA  TABLE  Separator[,]"
   echo '  '
   exit 1;
   ;;
esac



sqlplus -s / as sysdba <<EOF | tr '\t' ' ' | sed 's/, */,/g' | sed 's/ *,/,/g' | tr -d '\f' | tee  ${SCHEMA}.${TABLE}.csv
set term off
set echo off
set underline off
set colsep '$SEP'
set linesize 100
set pagesize 0
set sqlprompt ''
set lines 1000 pages 10000
set trimspool on
set feedback off
set heading on
set newpage 0
set headsep off
select $COLS from ${SCHEMA}.${TABLE}
$WHERE;
exit;
/
EOF
