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

jss_zip=`find /tmp -name JSSInstallation*`
filecount=`wc -l <<< "$jss_zip"`
if [[ "$filecount" -lt 1 ]]; then
    abort "JSS installation zip file not found"
elif [[ "$filecount" -gt 1 ]]; then
    abort "More than one JSS installation zip file found"
fi

if test `find "$jss_zip" -mmin -30`
then
    logger -p local7.info -t update_casper.sh "Up to date JSS installation zip file found"
    echo "Up to date JSS installation zip file found"
else
    abort "JSS installation zip file older than 1 hour. Please download a new copy."
fi

########## Main ##########

# get the version of the existing JSS
version=`grep -m1 \<version /var/lib/tomcat7/webapps/ROOT/WEB-INF/xml/version.xml| awk -F '[<|>]' '/version/{v=$3}{printf v}'`

# create the backup directory or replace it if it exists
directory=/var/lib/tomcat7/jss-$version
if [ ! -d "$directory" ]; then
    mkdir $directory
else
    echo "Backup directory exists. Replacing with new backup..."
    rm -rf $directory
    mkdir $directory
fi

# backup the database
logger -p local7.info -t update_casper.sh "Backing up current database settings"
cp /var/lib/tomcat7/webapps/ROOT/WEB-INF/xml/DataBase.xml $directory

# backup the ROOT.war file
logger -p local7.info -t update_casper.sh "Backing up current ROOT.war file"
cp /var/lib/tomcat7/webapps/ROOT.war $directory

# unzip the new jss installer
#unzip "$jss_zip" -d "/tmp"

# stop tomcat on both servers
/etc/init.d/tomcat7 stop
ssh galen@casperfe001 "sudo /etc/init.d/tomcat7 stop"

# confirm tomcat is stopped, abort otherwise
tomcat_alive=`ps -ef|grep tomcat |grep -v grep|wc -l`
test "$tomcat_alive" == 0 || \
    abort "Tomcat is still running on primary server"

tomcat_alive2=`ssh galen@casperfe001 "ps -ef|grep tomcat |grep -v grep|wc -l"`
test "$tomcat_alive2" == 0 || \
    abort "Tomcat is still running on secondary server"

# replace existing ROOT.war file

