#!/usr/bin/env python3

"""
This script is run by cron. It will check the DShield API for any commands to be
executed on the honeypot. This script, by default, will run every 5 minutes.
Output can be find in /srv/log/wecommand.out . A log of commands executed will
be written to /srv/log/webcommand.log.

To send commands, log into isc.sans.edu / dshield.org and check the 
/myhoneypot.html page.

If you have multiple honeypots, make sure to define a unique name for each in 
/etc/dshield.ini (see the "honeypotname" field). If it is not set, the name will
be "default"

"""
from DShield import DshieldSubmit
import json

config = "/etc/dshield.ini"
piddir="/var/run/dshield/"
pidfile = piddir+"webcommand.pid"

try:
    os.stat(piddir)
except:
    os.mkdir(piddir)
    
url = 'https://www.dshield.org/api/webcommand'
d = DshieldSubmit('')

f = open(pidfile, 'w')
f.write(str(os.getpid()))
f.close()

command = json.loads(d.get(url))
result = subprocess.run(command['cmd']), stdout=subprocess.PIPE)
f = open("/srv/log/webcommand.out","w")
f.write(result.stdout.decode('utf-8'))
f.close()

