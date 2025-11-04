#!/bin/bash
userid=$(id -u)
if [ ! "$userid" = "0" ]; then
  echo "You have to run this script as root. eg."
  echo "  sudo bin/updatehoneypotip.sh"
  echo "Exiting."
  echo ${LINE}
  exit 9
fi

if [ ! -f /srv/dshield/etc/dshield.ini ]; then
    echo "missing /srv/dshield/etc/dshield.ini file"
    exit 9
fi
honeypotip=$(curl -s https://www4.dshield.org/api/myip?json | jq .ip | tr -d '"')
if echo -n $honeypotip | egrep -q '^[0-9\.]+$'; then
    sed -i "s/^honeypotip=.*/honeypotip=$honeypotip/" /srv/dshield/etc/dshield.ini
    if ! grep -q '^piid=' dshield.ini; then
	piid=$(openssl rand -hex 10)
	sed -i "^apikey/a piid=$piid"  /srv/dshield/etc/dshield.ini
    fi
else
    echo "Bad IP address"
    exit 9
fi
