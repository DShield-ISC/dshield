#!/bin/sh

####
#
#  Quick script to check Pi status
#
####


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
if echo $status | grep -q '<result>ok<\/result>'; then
    echo "API Key configuration ok"
else
    echo "API Key may not be configured right. Check /etc/dshield.conf or re-run the install.sh script"
fi

