PS1="[\u@\h \$ORACLE_SID \W]\\$ "


alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias l.='ls -d .*'
alias ll='ls -lh '
alias ls='ls -F'
alias l='ls -Fac'
alias lt='ls -lhtr'

alias cro='crontab -l'
 
alias h=history
alias hg='history | grep '
alias g=grep


alias psg='ps -ef|grep -v grep|grep '
alias pso='ps -ef|grep -v grep|grep _pmon_| sort -k8'

alias envo='env|grep ORA'
alias dba='sqlplus / as sysdba'
alias aa=alias
alias b=bash
alias x='chmod +x *sh'


function _ss {
  export ORACLE_SID=$1;
}
alias s='_ss'
alias o='export ORAENV_ASK=NO; . oraenv -s; export ORAENV_ASK=YES'

ORATAB=/etc/oratab
DBLIST=`ps -ef|grep -v grep|grep ora_pmon | cut -d_ -f3`
DBLIST=`awk -F: '$1 !~ "#" {print $1}' $ORATAB | sort`
LISTENERS=`ps -ef  | grep tns | grep -v grep | awk '{print $9}' | sort`
 
 
alias rcat='rman target / '
 
  
alias ora='cat ~/.ssh/pd; sudo su - oracle'

alias rc='. ~/.bashrc'
alias pd='cat ~/.ssh/pd'
 

