#!/bin/sh
userid=`id -u`
if [ ! "$userid" = "0" ]; then
   echo "You have to run this script as root. eg."
   echo "  sudo ./uninstall.sh"
   echo "Exiting."
   echo ${LINE}
   exit 9
fi

systemctl stop cowrie

rm -rf /srv/*
rm -rf /etc/dshield.ini.*
mv /etc/dshield.ini /etc/dshield.ini.backup
rm -rf /etc/cron.d/dshield
rm -rf /etc/rsyslog.d/dshield.conf
rm -rf /var/run/dshield
deluser cowrie
echo "Done. Please reboot. The SSH daemon is still listening on port 12222"
