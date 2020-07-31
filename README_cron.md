# dshield

## cron configuration for honeypot

During the install of the honeypot, a ```/etc/cron.d/dshield``` is created with a number of cron jobs. These cron jobs will submit logs, update the honeypot and reboot it daily.

### weblog submit

The weblogsubmit.py script is run twice an hour (the times are randomly set during install, but 30 minutes from each other). This script will read logs from the sqlite database (/srv/www/DB/webserver.sqlite) and submit them to DShield via HTTPs

### firewall logs parser

/srv/dshield/fwlogparser.py is reading /var/log/dshield.log and submitting logs to dshield via https. This script runs twice an hour at the same time the weblogsubmit script runs.

### update

If the user selected automatic updates, the update.sh script runs once a day at a random time (set during install)

### reboot

The honeypot reboots once a day (again: at a random time set during install). This is a hopefully temporary fix to solve some stability issues in web.py the hard way

