#!/usr/bin/env python3

# version 2019-11-17-01

import sys
from sys import argv
import os
import re
import json
import syslog
from time import strptime
from time import mktime
from time import time
from datetime import datetime
from DShield import DshieldSubmit

maxlines=100000;
# main log parsers function
def parse(logline,logformat,linere):
    logdata = {}
    fwdata = ''
    logline=logline.strip("\000")
    m = linere.match(logline)
    if m:
        if logformat == 'pi':
            logdata['time'] = int(m.group(1))
            fwdata=m.group(2)
        elif logformat == 'aws':
            logdata['time'] = int(m.group(1))
            fwdata=m.group(2)            
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
            d.log("Bad format specified: {}".format(logformat))
            
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
            d.log("bad line %s" % logline)


# checking if PID in lock file is valid
def checklock(lockfile):
    # deepcode ignore MissingClose: Resultant code deletes the file or kills the process.
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
piddir="/var/run/dshield/"
lastdir="/var/tmp/dshield/"
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
    piddir = args['-p']
if '-d' in args:  # debug mode
    debug = 1
if '-c' in args:  # alternate config file
    print("Alternate config file: %s" % args['-c'])
    config = args['-c']

try:
    os.stat(piddir)
except:
    os.mkdir(piddir)

try:
    os.stat(lastdir)
except:
    os.mkdir(lastdir)

pidfile = piddir+"fwparser.pid"
lastcount = lastdir+"lastfwlog"
skipvalue = lastdir+"skipvalue"
    
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
    try: 
        startdate = float(f.readline())
    except:
        d.log("New Startdate")
        startdate = 0
    f.close()
if debug > 0:
    d.log("Startdate %d file %s" % (startdate,lastcount))
skip=1
currenttime=round(time())
d.log("Current Time %s" % (currenttime))
if ( startdate<currenttime-86400):
    startdate=currenttime-86400;
    d.log("Correcting Startdate to %d" % (startdate) )
    

if os.path.isfile(skipvalue):
    f = open(skipvalue, 'r')
    try:
        skip = float(f.readline())
    except:
        skip = 1
    f.close()
if skip<1:
    skip=1
if debug > 0:
    d.log("Skip value is %d file %s" % (skip,skipvalue))    
    
logs = []
i = 0
j = 0
data = {"time": 0}
if startdate == '':
    startdate = 0
lastdate = startdate
d.log("opening %s and starting with %d" % (logfile, startdate))
i=0
j=0
with open(logfile, 'r') as f:
    line = f.readline()
    logformat=d.identifylog(line)
    if logformat == '':
        d.log("Can not identify log format")
        sys.exit('Unable to identify log format')
    if debug > 0:
        d.log("logformat  %s" % logformat)
    linere=re.compile(d.logtypesregex[logformat])
    while line and j<maxlines:
        i += 1
        data = (parse(line,logformat,linere))
        if data is not None:
            j += 1
            lastdate = data['time']
            if (j % skip) == 0:
                logs.append(data)
        line = f.readline()
    if debug > 1:
        d.log(json.dumps(logs))
if j == 0:
    d.log("processed %d lines total and no new lines. Last date: %d" % (i, lastdate) )
else:
    d.log("processed %d lines total and %d new lines and ended at %s" % (i, j, lastdate))

f = open(lastcount, 'w')
f.write(str(lastdate))
f.close()
if ( j == maxlines ):
    d.log("incrementing skip value from %d" % (skip))
    skip=skip+1
else:
    skip=1
d.log("new skip value is %d" % (skip))
f = open(skipvalue, 'w')
f.write(str(skip))
f.close()    
logobject = {'type': 'firewall', 'logs': logs}
if debug == 0:
    if j>0:
        d.post(logobject)
    else:
        d.log("nothing to post")
else:
    d.log("skipping posting logs in debug mode.")
os.remove(pidfile)
