for f in ~/scripts/logs/[1-5]*.log ; do echo ; echo $f; echo '==================================='; tail -9 $f; done
