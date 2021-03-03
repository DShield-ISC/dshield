#!/bin/bash

####
#
#  Quick script to check Pi status
#
####

if [ "$TERM" != "" -a "$TERM" != "dumb" ]; then
   RED=$(tput setaf 1)
   GREEN=$(tput setaf 2)
   NC=$(tput sgr0)
else
   RED=
   GREEN=
   NC=
fi

email=''
apikey=''
version=''
userid=''
honeypotip=''
piid=''
user=''

declare -A TESTS

myip=$(netstat -nt | grep ESTABLISHED | awk '{print $4}' | cut -f1 -d':' | head -1)

echo "

#########
###
### DShield Sensor Configuration and Status Summary
###
#########
"

# Helper Functions

#
# simple native bash urlencode from
# https://gist.github.com/cdown/1163649
#

urlencode() {
  # urlencode <string>
  old_lc_collate=$LC_COLLATE
  LC_COLLATE=C
  local length="${#1}"
  for ((i = 0; i < length; i++)); do
    local c="${1:$i:1}"
    case $c in
    [a-zA-Z0-9.~_-]) printf '%s' "$c" ;;
    *) printf '%%%02X' "'$c" ;;
    esac
  done
  LC_COLLATE=$old_lc_collate
}

#
# Check if a file exists
#

checkfile() {
  local file="${1}"
  if [ -f $file ]; then
    echo "${GREEN}OK${NC}: $file"
    return 1
  else
    echo "${RED}MISSING${NC}: $file"
    return 0
  fi
}

echo -n "Current Time/Date: "
date +"%F %T"
uid=$(id -u)
if [ ! "$uid" = "0" ]; then
  echo "you have to run this script as root. eg."
  echo "  sudo status.sh"
  exit
fi

# Parsing configuration file
if [ -f /etc/dshield.ini ]; then
  source <(grep '=' /etc/dshield.ini | sed 's/ *= */=/g')
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
nonce=$(openssl rand -hex 10)
hash=$(echo -n $email:$apikey | openssl dgst -hmac $nonce -sha512 -hex | cut -f2 -d'=' | tr -d ' ')
user=$(urlencode "${email}")
url="https://isc.sans.edu/api/checkapikey/$user/$nonce/$hash/$version/$piid"
status=$(curl -s $url)
if [ "$status" = "" ]; then
  echo "Error connecting to DShield. Try again in 5 minutes. For details, run:"
  echo "curl -s https://isc.sans.edu/api/checkapikey/$user/$nonce/$hash/$version/$piid"
fi

if echo $status | grep -q '<result>ok<\/result>'; then
  echo "${GREEN}API Key configuration ok${NC}"
  if [ "$version" != "" ]; then
    currentversion=$(echo $status | egrep -o '<version>([0-9\.]+)</version>' | egrep -o '[0-9\.]+')
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
if [ -f /var/tmp/dshield/lastfwlog ]; then
  lastlog=$(cat /var/tmp/dshield/lastfwlog)
  echo -n "Last Firewall Log Processed: "
  date +"%F %T" -d @$lastlog
  TESTS['lastfwlog']=1
else
  echo "Looks like you have not run the firewall log submit script yet."
  TESTS['lastfwlog']=0
fi

if [ -f /var/tmp/dshield/skipvalue ]; then
  skip=$(cat /var/tmp/dshield/skipvalue)
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



checkfile "/var/log/dshield.log"
TESTS['dshieldlog']=$?
checkfile "/etc/cron.d/dshield"
TESTS['cron']=$?
checkfile "/etc/dshield.ini"
TESTS['ini']=$?
checkfile "/srv/cowrie/cowrie.cfg"
TESTS['cowriecfg']=$?
checkfile "/etc/rsyslog.d/dshield.conf"
TESTS['dshieldconf']=$?
IPTABLES=/usr/sbin/iptables
if [ -f /sbin/iptables ]; then
    IPTABLES=/sbin/iptables
fi

if $IPTABLES -L -n -t nat | grep -q DSHIELDINPUT; then
  echo "${GREEN}OK${NC}: firewall rules"
  TESTS['fw']=1
else
  echo "${RED}MISSING${NC}: firewall rules"
  TESTS['fw']=0
fi
port=$(curl -s 'https://isc.sans.edu/api/portcheck?json' | jq .port80 | tr -d '"')
if [[ "$port" == "open" ]]; then
  echo "${GREEN}OK${NC}: webserver exposed"
  TESTS['exposed']=1
else
  echo "${RED}ERROR${NC}: webserver not exposed. check network firewall"
  TESTS['exposed']=0
fi
nonce=$(openssl rand -hex 10)
hash=$(echo -n $email:$apikey | openssl dgst -hmac $nonce -sha512 -hex | cut -f2 -d'=' | tr -d ' ')
data="[ {\"version\": $version }"
for key in "${!TESTS[@]}"; do
  data="$data, { '${key}': '${TESTS[$key]}' }"
done
data="$data ]"
curl -s https://isc.sans.edu/api/hpstatusreport/$user/$nonce/$hash/$verison/$piid -d "$data" > /dev/null
echo
echo "also check https://isc.sans.edu/myreports.html (after logging in)"
echo "to see that your reports arrive."
echo "It may take an hour for new reports to show up."


