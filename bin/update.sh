#!/usr/bin/env bash

# make sure we are root

userid=`id -u`
if [ ! "$userid" = "0" ]; then
   echo "You have to run this script as root. eg."
   echo "  sudo $0"
   echo "Exiting."
   exit 9
fi

# find ini file

if [ -f /usr/local/etc/dshield.ini ]; then
    inifile="/usr/local/etc/dshield.ini"
fi
if [ -f /etc/dshield.ini ]; then
    inifile="/etc/dshield.ini"
fi
if [ -f ~/etc/dshield.ini ]; then
    inifile="~/etc/dshield.ini"
fi
if [ -f ~/.dshield.ini ]; then
    inifile="~/.dshield.ini"
fi

source <(grep = $inifile)

if [ "$version" == "" ]; then
    version=0;
fi

echo Currently configured for $email userid $userid
echo Version installed: $version
hash=`echo -n $email:$apikey | openssl dgst -hmac $nonce -sha512 -hex | cut -f2 -d'=' | tr -d ' '`
wget -q -O - https://isc.sans.edu/api/checkapikey/$user/$nonce/$hash
newversion=`wget -q -O - https://isc.sans.edu/api/checkapikey/$user/$nonce/$hash | grep '<result>ok</result>' | grep '\<version\>' | sed 's/.*<version>//' | sed 's/<\/version>.*//'`
echo Current Version: $newversion

