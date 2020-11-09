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
systemctl stop webpy
for b in `ps -ef | grep '^cowrie' | awk '{print $2}'`; do kill -9 $b; done
rm -rf /srv/*
rm -rf /etc/dshield.ini.*
mv /etc/dshield.ini /etc/dshield.ini.backup
rm -rf /etc/cron.d/dshield
rm -rf /etc/rsyslog.d/dshield.conf
rm -rf /var/run/dshield
rm -rf /lib/systemd/system/cowrie.service
rm -rf /lib/systemd/system/webpy.service
rm -rf /etc/network/iptables
systemctl enable ufw
deluser cowrie
echo "Done. Please reboot. The SSH daemon is still listening on port 12222"





