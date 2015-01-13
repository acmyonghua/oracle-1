echo 'Shutting down all Exalytics components'

echo 'BI Components...'
$HOME/scripts/5-bi_components.sh stop

echo 'BI Server...'
$HOME/scripts/4-bi_server.sh stop

echo 'FMW Weblogic...'
$HOME/scripts/3-fmw_WLS.sh stop

echo 'FMW NodeManager...'
$HOME/scripts/2-fmw_NodeManager.sh stop

echo 'TimesTen...'
$HOME/scripts/1-TimesTen.sh stop

echo 'Exalytics components shutdown'
