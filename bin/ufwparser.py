#!/usr/bin/env python

import sys
import os
import re
import json
from time import strptime
from time import mktime
from datetime import datetime
from DShield import DshieldSubmit

logfile = "/var/log/ufw.log"
pidfile = "/var/run/ufwparser.pid"
lastcount = ".lastufw"
config = "/etc/dshield.ini"
startdate = 0
now = datetime.utcnow()
fieldmap = {'SRC': 'sip', 'DST': 'dip', 'PROTO': 'proto', 'TYPE': 'sport',
            'CODE': 'dport', 'SPT': 'sport', 'DPT': 'dport'}
protomap = {'UDP': 17, 'TCP': 6, 'ICMP': 1, 'ICMPv6': 58}
tcpflagmap = {'CWR': '1', 'ECE': '2', 'URG': 'U', 'ACK': 'A', 'PSH': 'P', 'RST': 'R', 'SYN': 'S', 'FIN': 'F'}
d = DshieldSubmit('')


def parse(logline):
    linere = re.compile('^([A-Z][a-z]{2}'') ([0-9 ]{2}) ([0-9:]{8}) \S+ kernel: \[[^\]]+\] \[([^\]]+)\] (.*)')
    logdata = {}
    m = linere.match(logline)
    if m: 
        month = strptime(m.group(1), '%b').tm_mon
        if month == 12 and now.month == 1:
            year = now.year-1
        else:
            year = now.year
        day = m.group(2)
        ltime = m.group(3)
        date = "%s-%s-%s" % (year, month, day)
        logtime = datetime.strptime(date+" "+ltime, '%Y-%m-%d %H:%M:%S')
        logdata['time'] = logtime
        if mktime(logtime.timetuple()) > startdate:
            parts = m.group(5).split()
            logdata['flags'] = ''
            for part in parts:
                keyval = part.split('=')
                if keyval[0] in fieldmap:
                    logdata[fieldmap[keyval[0]]] = keyval[1]
            if logdata['sip'].find(':') > 0:
                logdata['version'] = 6
            else:
                logdata['version'] = 4
            if logdata['proto'] in protomap:
                logdata['proto'] = protomap[logdata['proto']]
            if logdata['proto'] == 6:
                for fcount in tcpflagmap:
                    if fcount in parts:
                        logdata['flags'] += tcpflagmap[fcount]
            logdata['dip'] = d.anontranslateip4(logdata['dip'])
            logdata['sip'] = d.anontranslateip4(logdata['sip'])

            if isinstance(logdata['proto'], int):
                return logdata
                
            
if os.path.isfile(logfile) is None:
    sys.exit('Can not find logfile %s ' % logfile)

if os.path.isfile(pidfile):
    sys.exit('PID file found. Am I already running?')

    
f = open(pidfile, 'w')
f.write(str(os.getpid()))
f.close()

if os.path.isfile(lastcount):
    f = open(lastcount, 'r')
    startdate = float(f.readline())
    f.close()
logs = []
i = 0
j = 0
data = []
lastdate = ''
if startdate == '':
    startdate = 0
print "opening %s and starting with %d" % (logfile, startdate)
with open(logfile, 'r') as f:
    lines = f.readlines()
    for line in lines:
        i += 1
        data = (parse(line))
        if data is not None:
            j += 1
            lastdate = str(mktime(data['time'].timetuple()))
            data['time'] = data['time'].strftime('%Y-%m-%d %H:%M:%S')
            logs.append(data)
    print json.dumps(logs)
print "processed %d lines total and %d new lines and ended at %s" % (i, j, data['time'])
f = open(lastcount, 'w')
f.write(lastdate)
f.close()
l = {'type': 'firewall', 'logs': logs}
d.post(l)
os.remove(pidfile)
