#!/bin/bash

####
#
#  Quick script to check Pi status
#
####

RED=`tput setaf 1`
GREEN=`tput setaf 2`
NC=`tput sgr0`

myip=$(netstat -nt  | grep ESTABLISHED | awk '{print $4}' | cut -f1 -d':' | head -1)

echo "

#########
###
### DShield Sensor Configuration and Status Summary
###
#########
"
echo -n "Current Time/Date: "
date +"%F %T"
uid=`id -u`
if [ ! "$uid" = "0" ]; then
   echo "you have to run this script as root. eg."
   echo "  sudo status.sh"
   exit
fi

if [ -f /etc/dshield.ini ] ; then
   source <(grep = /etc/dshield.ini | sed 's/ *= */=/g')
else
    echo "Bad Installation: No Configuration File Found"
    exit
fi
if [ "$email" == "" ]; then
   echo "The configuration file '/etc/dshield.ini' does not include your e-mail address"
   echo "This is likely due to you installing an older version of this software."
   echo "Please edit the file, and add a line like:"
   echo "email=myemail@example.com"
   echo "to the DShield section. "
   echo
   echo
   exit
fi
nonce=`openssl rand -hex 10`
hash=`echo -n $email:$apikey | openssl dgst -hmac $nonce -sha512 -hex | cut -f2 -d'=' | tr -d ' '`
# TODO: urlencode($user)
user=`echo $email | sed 's/+/%2b/' | sed 's/@/%40/'`
status=`curl -s https://isc.sans.edu/api/checkapikey/$user/$nonce/$hash/$version`
if [ "$status" = "" ] ; then
   echo "Error connecting to DShield. Try again in 5 minutes. For details, run:"
   echo "curl -s https://isc.sans.edu/api/checkapikey/$user/$nonce/$hash"
fi

if echo $status | grep -q '<result>ok<\/result>'; then
    echo "${GREEN}API Key configuration ok${NC}"
    if [ "$version" != "" ]; then
    currentversion=`echo $status | egrep -o '<version>([0-9\.]+)</version>'  | egrep -o '[0-9\.]+'`
    if [ "$currentversion" != "$version" ]; then
	echo "
${RED}Software Version Mismatch
Current Version: $currentversion
Your Version: $version
Details: https://dshield.org/updatehoneypot.html${NC}
"
    else
	echo "${GREEN}Your software is up to date.${NC}"
    fi
    fi
else
    echo "{$RED}API Key may not be configured right. Check /etc/dshield.ini or re-run the install.sh script{$NC}"
fi

echo "Honeypot Version: $version"
echo "
###### Configuration Summary ######
"
echo E-mail : $email
echo API Key: $apikey
echo User-ID: $userid
echo My Internal IP: $myip
echo My External IP: $honeypotip

echo "
###### Are My Reports Received? ######
"
echo -n "Last 404/Web Logs Received: "
echo $status | sed 's/.*<last404>//' | sed 's/<\/last404>.*//'
echo -n "Last SSH/Telnet Log Received: "
echo $status | sed 's/.*<lastssh>//' | sed 's/<\/lastssh>.*//'
echo -n "Last Firewall Log Received: "
echo $status | sed 's/.*<lastreport>//' | sed 's/<\/lastreport>.*//'

echo "
###### Are the submit scripts running?
"
if [ -f /var/run/dshield/lastfwlog ]; then
    lastlog=`cat /var/run/dshield/lastfwlog`
    echo -n "Last Firewall Log Processed: "
    date +"%F %T" -d @$lastlog
else
    echo "Looks like you have not run the firewall log submit script yet."
fi

if [ -f /var/run/dshield/skipvalue ]; then
    skip=`cat /var/run/dshield/skipvalue`;
    if [ "$skip" -eq "1" ]; then
	echo "${GREEN}All Logs are processed. You are not sending too many logs${NC}"
    fi
    if [ "$skip" -eq "2" ]; then
	echo "Only every 2nd firewall log line is sent due to the large log size"
    fi
    if [ "$skip" -eq "3" ]; then
	echo "Only every 3rd firewall log line is sent due to the large log size"
    fi
    if [ "$skip" -gt "3" ]; then
	echo "Only every $skip th firewall log line is sent due to the large log size"
    fi
fi

echo "
###### Checking various files
"




checkfile() {
    local file="${1}"
    if [ -f $file ]; then
	echo "${GREEN}OK${NC}: $file"
    else
	echo "${RED}MISSING${NC}: $file"
    fi
}

checkfile "/var/log/dshield.log"
checkfile "/etc/cron.d/dshield"
checkfile "/etc/dshield.ini"
checkfile "/srv/cowrie/cowrie.cfg"
checkfile "/etc/cron.d/dshield"
checkfile "/etc/rsyslog.d/dshield.conf"
if iptables -L -n -t nat  | grep -q DSHIELDINPUT; then
    echo "${GREEN}OK${NC}: firewall rules"
else
    echo "${RED}MISSING${NC}: firewall rules"
fi
port=$(curl -s 'https://isc.sans.edu/api/portcheck?json' | jq .port80|tr -d '"')
if [[ "$port" == "open" ]]; then
    echo "${GREEN}OK${NC}: webserver exposed"
else
    echo "${RED}ERROR${ND}: webserver not exposed. check network fireall"
fi
echo
echo "also check https://isc.sans.edu/myreports.html (after logging in)"
echo "to see that your reports arrive."
echo "It may take an hour for new reports to show up."
