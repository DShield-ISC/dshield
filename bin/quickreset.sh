#!/bin/sh

/etc/init.d/cowrie stop
/etc/init.d/mini-httpd stop
rm /etc/dshield.ini
deluser cowrie
rm -rf /srv/www
rm -rf /srv/cowrie
rm -rf /var/log/mini-httpd
rm -f /etc/network/iptables
rm -f /etc/network/if-pre-up.d/dshield
rm -rf /srv/isc-agent
