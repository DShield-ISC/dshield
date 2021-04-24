#! /bin/sh
#
#
#    #This command updates every 2 seconds and diplays including the inode entry, sorted by time, downloaded files from the fake cowrie filesystem, for example that were downloaded over connections masqueraded as "successful" on the ssh or telnet fake-services (by default the 15 latest)
#    #Then it displays a preview of the firewall log file (sent to the DShield chains in iptables)
#
#    other files which may be of similar interest to you include the logs at /srv/cowrie/var/log/cowrie and the terminal "replay logs" themselves at /srv/cowrie/var/lib/cowrie/tty
#
#    #further watch options that are usful, like change highlighting -e or -n [time spec] see 'man watch'
#
#    #command:
watch  'ls -lahit /srv/cowrie/var/lib/cowrie/downloads | head -n 17; echo "\n"; tail -n 10  /var/log/dshield.log'