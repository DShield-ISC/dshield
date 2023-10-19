#!/usr/bin/env python3

#
# Quick script to parse apache access logs and submit them to DShield
#

from DShield import DshieldSubmit
import os
import re
import socket
from dateutil import parser
import sys

myip = socket.gethostbyname(socket.gethostname())
maxlines = 5000
pidfile = "accesslogparser.pid"
linecount=0
d = DshieldSubmit('')
if os.path.isfile(pidfile):
    if d.check_pid(pidfile):
        sys.exit('PID file found. Am I already running?')
    else:
        print("stale lock file.")
        os.remove(pidfile)

f = open(pidfile, 'w')
f.write(str(os.getpid()))
f.close()

parseline = re.compile('^(\S+)\s(\S+) \S+ \S+ \[([^\]]+)\]\s"([^"]+)" ([0-9]{3}) [0-9]+ "[^"]+" "([^"]+)"$')
isip = re.compile('^([0-9\.]+)')
logs = []
starttime = 0
try:
    with open("lastweblogtime.txt") as file:
        starttime = file.read().strip()
        starttime = int(starttime)
except:
    pass
if not starttime:
    starttime=0
lasttime = starttime
print("Starttime: %d" % (starttime,))
with open("/Users/jullrich/access.log") as file:
    line = file.readline()
    while line:
        line = file.readline()
        match = parseline.match(line)
        if match is not None:
            logdata = {}
            logdata['time']=int(parser.parse(match[3].replace(':', ' ', 1)).timestamp())
            if logdata['time'] > starttime:
                logdata['sip']=match[1]
                ipmatch = isip.match(match[2])
                if ipmatch is None:
                    logdata['dip'] = myip
                else:
                    logdata['dip'] = ipmatch[1]
                lasttime = logdata['time']
                request = match[4].split(' ')
                if len(request) == 3:
                    logdata['method']=request[0]
                    logdata['url']=request[1]
                else:
                    logdata['url']=match[4]
                    logdata['method']=''
                if match[6]=='-':
                    logdata['useragent']=''
                else:
                    logdata['useragent']=match[6]
                linecount = linecount + 1
                logs.append(logdata)
                if linecount > maxlines:
                    break
                
with open("lastweblogtime.txt","w") as file:
    file.write(str(lasttime))

if linecount>0:
    print("Sending")
    l = {'type': 'webhoneypot', 'logs': logs}
    d.post(l)
    os.remove(pidfile)
    
print("Linecount: %d" % (linecount))
