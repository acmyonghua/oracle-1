echo 'Status of all Exalytics components'

echo
echo
echo
echo 'TimesTen...'
$HOME/scripts/1-TimesTen.sh 

echo
echo
echo 'FMW NodeManager...'
$HOME/scripts/2-fmw_NodeManager.sh 

echo
echo
echo 'FMW Weblogic...'
$HOME/scripts/3-fmw_WLS.sh 

echo
echo
echo 'BI Server...'
$HOME/scripts/4-bi_server.sh 

echo
echo
echo 'BI Components...'
$HOME/scripts/5-bi_components.sh 

