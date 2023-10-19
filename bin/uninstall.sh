#!/bin/sh
userid=`id -u`
if [ ! "$userid" = "0" ]; then
   echo "You have to run this script as root. eg."
   echo "  sudo ./uninstall.sh"
   echo "Exiting."
   echo ${LINE}
   exit 9
fi
if [ ! -f /etc/os-release ]; then
  echo "I can not find the /etc/os-release file. You are likely not running a supported operating system"
  echo "please email info@dshield.org for help."
  exit 9
fi
. /etc/os-release
systemctl stop cowrie
systemctl stop webpy
for b in `ps -ef | grep '^cowrie' | awk '{print $2}'`; do kill -9 $b; done
rm -rf /srv/*
rm -rf /etc/dshield.ini.*
rm -rf /etc/dshield.sslca.*
mv /etc/dshield.ini /etc/dshield.ini.backup
mv /etc/dshield.sslca /etc/dshield.sslca.backup
rm -rf /etc/cron.d/dshield
rm -rf /etc/rsyslog.d/dshield.conf
# older versions used /var/run instead of /var/tmp
rm -rf /var/run/dshield
rm -rf /var/tmp/dshield
rm -rf /lib/systemd/system/cowrie.service
rm -rf /lib/systemd/system/webpy.service
rm -rf /etc/network/iptables*
if [ "${ID:0:8}" != "opensuse" ]; then
   systemctl enable ufw
   deluser cowrie
else
   systemctl stop dshieldfirewall.service
   systemctl stop dshieldfirewall_init.service
   systemctl disable dshieldfirewall.service
   systemctl disable dshieldfirewall_init.service
   rm /usr/lib/systemd/system/dshieldfirewall*.service
   userdel -f -r cowrie
fi
echo "Done. Please reboot. The SSH daemon is still listening on port 12222"





