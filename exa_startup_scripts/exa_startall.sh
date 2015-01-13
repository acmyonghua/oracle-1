echo 'Starting up all Exalytics components'

echo 'TimesTen...'
$HOME/scripts/1-TimesTen.sh start

echo 'FMW NodeManager...'
$HOME/scripts/2-fmw_NodeManager.sh start

echo 'FMW Weblogic...'
$HOME/scripts/3-fmw_WLS.sh start

echo 'BI Server...'
$HOME/scripts/4-bi_server.sh start

echo 'BI Components...'
$HOME/scripts/5-bi_components.sh start

echo 'Exalytics components started'
