#!/bin/bash

####
#
# Cleanup script to safe disk space
#
#  the script will ask for confirmation, unless you
# add the optional 'cron' commandline parameter.
# If run with 'cron', only files older than 14 days are
# deleted.
#
#  in addition, logs from journald older than 7 days are
# deleted.
#
####

uid=$(id -u)
if [ ! "$uid" = "0" ]; then
  echo "you have to run this script as root. eg."
  echo "  sudo cleanup.sh"
  exit
fi

if [[ $1 != cron ]]; then
  echo
  echo "  This script will delete backups and log files."
  echo "  Do you want to proceed? (Y/N)"
  echo
  while : ; do
      read -s -p "Press Y/N key: " -n 1 k <&1
      k=${k^}
      echo $k
      if [[ $k = N ]]; then
  	echo
	echo "abort"
	exit
      fi
      if [[ $k = Y ]]; then
	echo
	echo "removing logs and backups"
	break
      fi
  done
  rm -rf /srv/www.2*
  rm -rf /srv/dshield.2*
  rm -rf /srv/cowrie.2*
  rm -rf /srv/log/*
  rm -rf /srv/cowrie/var/log/cowrie/*
  /usr/bin/journalctl --vacuum-time=7d  
else
  find /srv -name 'www.2*' -ctime +14  -delete
  find /srv -name 'dshield.2*' -ctime +14  -delete
  find /srv -name 'cowrie.2*' -ctime +14  -delete
  find /srv/log -ctime +14  -delete
  find /srv/cowrie/var/log/cowrie/*  -ctime +14  -delete
  /usr/bin/journalctl --vacuum-time=7d  
fi
