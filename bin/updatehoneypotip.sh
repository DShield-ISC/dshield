#!/bin/bash

# this script will update the honeypot's public IPv4 IP address
# it will also do some cleanup:
# - check if /etc/dshield.ini is a symlink
# - add a unique "Pi ID" to the dshield.ini file if it is not already present
# - fix permissions for dshield.ini

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

if [ ! -L /etc/dshield.ini ]; then
    ln -s /srv/dshield/etc/dshield.ini /etc/dshield.ini
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

# TODO eventually the permissions should be 600, but to support legacy installs,
# leaving them at 644 for now
chown webhpot:webhpot /srv/dshield/etc/dshield.ini
chmod 644 /srv/dshield/etc/dshield.ini
