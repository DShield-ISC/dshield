#!/bin/sh

####
#
#  Quick script to check Pi status
#
####

userid=`id -u`
if [ ! "$userid" = "0" ]; then
   echo "you have to run this script as root. eg."
   echo "  sudo status.sh"
   exit
fi

if [ -f /etc/dshield.conf ] ; then
    . /etc/dshield.conf
else
    echo "Bad Installation: No Configuration File Found
    exit
fi

if [ ! -d /var/lib/mysql ]; then
    echo "Incomplete Installation: MySQL not installed
fi

nonce=`openssl rand -hex 10`
hash=`echo -n $email:$apikey | openssl dgst -hmac $nonce -sha512 -hex | cut -f2 -d'=' | tr -d ' '`
user=`echo $email | sed 's/@/%40/'`
status=`curl -s https://isc.sans.edu/api/checkapikey/$user/$nonce/$hash`
if [ "$status" = "" ] ; then
   echo "Error connecting to DShield. Try again in 5 minutes. For details, run:"
   echo "curl -s https://isc.sans.edu/api/checkapikey/$user/$nonce/$hash"
fi
if echo $status | grep -q '<result>ok<\/result>'; then
    echo "API Key configuration ok"
else
    echo "API Key may not be configured right. Check /etc/dshield.conf or re-run the install.sh script"
fi
echo E-mail : $email
echo API Key: $apikey
echo User-ID: $uid
echo -n "Last Web Log Received: "
echo $status | sed 's/.*<lastweblog>//' | sed 's/<\/lastweblog>.*//'
echo -n "Last 404 Log Received: "
echo $status | sed 's/.*<last404>//' | sed 's/<\/last404>.*//'
echo -n "Last ssh Log Received: "
echo $status | sed 's/.*<lastssh>//' | sed 's/<\/lastssh>.*//'
echo -n "Last ssh Firewall Log Received: "
echo $status | sed 's/.*<lastreport>//' | sed 's/<\/lastreport>.*//'
echo -n "Current Time/Date: "
date +"%F %T"
