# dshield

## Troubleshooting

Your first step should be the status.sh script in the dshield/bin directory (same directory you ran the install script from). A typical good output should look the sample report at the end of this page.

Couple common issues:

- "webserver exposed": This is the most common failure. The reason, almost always is that the firewall/router is not exposing the honeypot to internet traffic.
- "firewall rules": First, reboot the honeypot and see if this fixes the problem. If not, run the install script again.
- "dshield.log" failed: re-run the script 10 minutes later. Maybe you just didn't get any reports yet. Also check for other errors (in particular if the web server is exposed or the firewall rules are ok)

If any of these trouble shooting steps do not work, or if you have other issues, contact us (handlers@sans.edu or isc.sans.edu/slack ).

You may also find the install log in /srv/log interesting. Please send it along when asking for help, with the output of status.sh

```


#########
###
### DShield Sensor Configuration and Status Summary
###
#########

Current Time/Date: 2020-07-31 00:18:40
API Key configuration ok
Your software is up to date.
Honeypot Version: 72

###### Configuration Summary ######

E-mail : [your email address]
API Key: [your api key]
User-ID: [your userid]
My Internal IP: [honeypot interal ip]
My External IP: [honeypot external (public) ip]

###### Are My Reports Received? ######

Last 404/Web Logs Received: 2020-07-31 00:12:10
Last SSH/Telnet Log Received: 2020-07-30 23:52:11
Last Firewall Log Received: 2020-07-31 00:12:09

###### Are the submit scripts running?

Last Firewall Log Processed: 2020-07-31 00:00:17
All Logs are processed. You are not sending too many logs

###### Checking various files

OK: /var/log/dshield.log
OK: /etc/cron.d/dshield
OK: /etc/dshield.ini
OK: /srv/cowrie/cowrie.cfg
OK: /etc/cron.d/dshield
OK: /etc/rsyslog.d/dshield.conf
OK: firewall rules
OK: webserver exposed

also check https://isc.sans.edu/myreports.html (after logging in)
to see that your reports arrive.
It may take an hour for new reports to show up.
```