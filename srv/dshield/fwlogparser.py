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
def parse(logline):
    logdata = {}
    m = linere.match(logline)
    if m:
        if logformat == 'pi':
            logdata['timestamp'] = datetime.fromtimestamp(int(m.group(1)))
            logdata['time'] = logdata['timestamp'].strftime('%Y-%m-%d %H:%M:%S')
        elif logformat == 'ufw':
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

            logdata['timestamp'] = datetime.utcfromtimestamp(mktime(logtime.timetuple()))
        else:
            print "Bad format specified: {}".format(logformat)

        if logdata['timestamp'] > startdate:
            parts = m.group(2).split()
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
        if debug == 1:
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
pidfile = "/var/run/fwparser.pid"
lastcount = ".lastfwlog"
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

if os.path.isfile(lastcount) and debug == 0:
    f = open(lastcount, 'r')
    startdate = float(f.readline())
    f.close()
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
    linere = re.compile('^([A-Z][a-z]{2}'') ([0-9 ]{2}) ([0-9:]{8}) \S+ kernel: \[[^\]]+\] \[([^\]]+)\] (.*)')
    if linere.match(lines[0]) is None:
        linere = re.compile('^(\d+) \S+ kernel:\[[ 0-9.]+\]\s+DSHIELDINPUT (.*)')
        if linere.match(lines[0]) is None:
            logformat = ''
            print "Can not find a valid log file format"
        else:
            logformat = 'ufw'
    for line in lines:
        i += 1
        data = (parse(line))
        if data is not None:
            j += 1
            data['time'] = data['timestamp'].strftime('%Y-%m-%d %H:%M:%S')
            lastdate = data['timestamp'].strftime('%s')
            del data['timestamp']
            logs.append(data)
    print json.dumps(logs)
print "processed %d lines total and %d new lines and ended at %s" % (i, j, data['time'])
f = open(lastcount, 'w')
f.write(lastdate)
f.close()
logobject = {'type': 'firewall', 'logs': logs}
if debug == 0:
    d.post(logobject)
os.remove(pidfile)
