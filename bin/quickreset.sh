#!/bin/sh

/etc/init.d/cowrie stop
/etc/init.d/mini-httpd stop
/etc/init.d/mysql stop
rm /root/.my.cnf
rm /etc/dshield.conf
deluser cowrie
rm -rf /srv/www
rm -rf /srv/cowrie
rm -rf /var/log/mini-httpd
apt-get -y purge mysql-server mysql-server-5.5 mysql-server-core-5.5
