#!/usr/bin/env python

import sys
from sys import argv
import os
import re
import json
from time import strptime
from time import mktime
from datetime import datetime
from DShield import DshieldSubmit


# main log parsers function
def parse(logline,logformat,linere):
    logdata = {}
    fwdata = ''
    m = linere.match(logline)
    if m:
        if logformat == 'pi':
            logdata['time'] = int(m.group(1))
        elif logformat == 'generic':
            month = strptime(m.group(1), '%b').tm_mon
            if month == 12 and now.month == 1:
                year = now.year-1
            else:
                year = now.year
            day = m.group(2)
            ltime = m.group(3)
            date = "%s-%s-%s" % (year, month, day)
            # parsedate
            logtime = datetime.strptime(date+" "+ltime, '%Y-%m-%d %H:%M:%S')
            # get UTC datetime
            logdata['time'] = int(logtime.strftime('%s'))
            fwdata=m.group(4)

        else:
            print "Bad format specified: {}".format(logformat)
        if logdata['time'] > startdate:
            parts = fwdata.split()
            logdata['flags'] = ''
            for part in parts:
                keyval = part.split('=')
                if keyval[0] in fieldmap:
                    logdata[fieldmap[keyval[0]]] = keyval[1]
            if logdata['dip'] == '255.255.255.255':
                return
            if logdata['dip'].find('224.0.0.') == 1:
                return
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
    else:
        if debug > 0:
            print "bad line %s" % logline


# checking if PID in lock file is valid
def checklock(lockfile):
    fileh = open(lockfile, 'r')
    pid = int(fileh.read())
    try:
        os.kill(pid, 0)
    except OSError:
        os.remove(lockfile)
        return True
    else:
        sys.exit('PID file found. Am I already running?')


# define paramters
logfile = "/var/log/dshield.log"
pidfile = "/var/run/dshield/fwparser.pid"
lastcount = "/var/run/dshield/lastfwlog"
config = "/etc/dshield.ini"
startdate = 0
now = datetime.utcnow()
fieldmap = {'SRC': 'sip', 'DST': 'dip', 'PROTO': 'proto', 'TYPE': 'sport',
            'CODE': 'dport', 'SPT': 'sport', 'DPT': 'dport'}
protomap = {'ICMP': 1, 'IGMP': 2, 'TCP': 6, 'UDP': 17, 'ESP': 50, 'AH': 51, 'ICMPv6': 58}
tcpflagmap = {'CWR': '1', 'ECE': '2', 'URG': 'U', 'ACK': 'A', 'PSH': 'P', 'RST': 'R', 'SYN': 'S', 'FIN': 'F'}

# instantiate DShield Submit object (used to submit logs to DShield
d = DshieldSubmit('')

# check if we run in debug mode
args = d.getopts(argv)
debug = 0
if '-l' in args:  # overwrite log file
    logfile = args['-l']
if '-p' in args:  # overwrite log file
    pidfile = args['-p']
if '-d' in args:  # debug mode
    debug = 1
if os.path.isfile(logfile) is None:
    sys.exit('Can not find logfile %s ' % logfile)
if os.path.isfile(pidfile):
    checklock(pidfile)

# creating lock file
f = open(pidfile, 'w')
f.write(str(os.getpid()))
f.close()

if os.path.isfile(lastcount):
    f = open(lastcount, 'r')
    startdate = float(f.readline())
    f.close()
if debug > 0:
    print "Startdate %d file %s" % (startdate,lastcount)
    
logs = []
i = 0
j = 0
data = {}
lastdate = ''
logformat = ''
if startdate == '':
    startdate = 0
print "opening %s and starting with %d" % (logfile, startdate)
with open(logfile, 'r') as f:
    lines = f.readlines()
    logformat=d.identifylog(lines[0])
    if logformat == '':
        print "Can not identify log format"
        sys.exit('Unable to identify log format')
    if debug > 0:
        print "logformat  %s" % logformat
    linere=re.compile(d.logtypesregex[logformat])
    for line in lines:
        i += 1
        data = (parse(line,logformat,linere))
        if data is not None:
            j += 1
            lastdate = data['time']
            logs.append(data)
    if debug > 1:
        print json.dumps(logs)
print "processed %d lines total and %d new lines and ended at %s" % (i, j, data['time'])
f = open(lastcount, 'w')
f.write(str(lastdate))
f.close()
logobject = {'type': 'firewall', 'logs': logs}
if debug == 0:
    d.post(logobject)
os.remove(pidfile)
