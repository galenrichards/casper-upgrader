#!/bin/bash

########## Functions ##########

abort () {
    abort_message="[ABORTING] $*"
    echo "$abort_message" 1>&2
    exit 1
}

########## Tests/checks ##########

logger -p local7.info -t update_casper.sh "starting: $0 $*"
test "$( whoami )" == "root" || \
    abort "Must run script as 'root'"

if test `find /tmp/ROOT.war -mmin -1440`
then
    logger -p local7.info -t update_casper.sh "Up to date ROOT.war found"
    echo "Up to date ROOT.war found"
else
    abort "ROOT.war file missing or too old"
fi

########## Main ##########

#/etc/init.d/tomcat7 stop

tomcat_alive=`ps -ef|grep tomcat |grep -v grep|wc -l`
#test "$tomcat_alive" == 0 || \
#    abort "Tomcat is still running"

logger -p local7.info -t update_casper.sh "Backing up current database settings"
cp /var/lib/tomcat7/webapps/ROOT/WEB-INF/xml/DataBase.xml /tmp

logger -p local7.info -t update_casper.sh "Backing up current webapp files"
version=`grep -m1 \<version /var/lib/tomcat7/webapps/ROOT/WEB-INF/xml/version.xml| awk -F '[<|>]' '/version/{v=$3}{printf v}'`

DIRECTORY=/var/lib/tomcat7/jss-$version
if [ ! -d "$DIRECTORY" ]; then
    mkdir $DIRECTORY
else
    abort "Backup directory already exists"
fi
