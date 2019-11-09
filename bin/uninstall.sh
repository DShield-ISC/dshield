#!/bin/sh
systemctl stop cowrie

rm -rf /srv/*
rm -rf /etc/dshield.ini.*
mv /etc/dshield.ini /etc/dshield.ini.backup
rm -rf /etc/cron.d/dshield
rm -rf /etc/rsyslog.d/dshield.conf
rm -rf /var/run/dshield
deluser cowrie
