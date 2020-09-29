#!/usr/bin/env python3
# submit logs to DShield 404 project

# version 2019-11-17-01

import os
import sys
import sqlite3
from DShield import DshieldSubmit
from datetime import datetime
import json

# We need to collect the local IP to scrub it from any logs being submitted for anonymity, and to reduce noise/dirty data.

ipaddr = os.popen('/bin/hostname -I').read().replace(" \n", "")

pidfile = "/var/run/weblogparser.pid"
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

config = '..' + os.path.sep + 'www'+os.path.sep+'DB' + os.path.sep + 'webserver.sqlite'
try :
    conn = sqlite3.connect(config)
    c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS submissions
            (
              timestamp integer primary key,
              linessent integer 
            )
          ''')

    maxid = c.execute("""SELECT max(timestamp) from submissions""").fetchone()
except sqlite3.Error as e:
    print("Error %s:" % e.args[0])
    os.remove(pidfile)
    sys.exit(1)

starttime=0

if str(maxid[0]) != "None" :
    starttime=float(maxid[0])
rsx=c.execute("""SELECT date, headers, address, cmd, path, useragent, targetip from requests where date>?""",[starttime]).fetchall()
logs = []
lasttime = starttime
linecount = 0
for r in rsx:
    logdata = {}
    headerdata = {}
    logdata['time']=float(r[0])
    for each in r[1].split('\r\n'): # Header data was stored as a string with extra characters, so some clean-up needed.
        if (each and ipaddr in each): # scrubbing local IP from data before submission
            try:
                headerdata['header_'+str(each.split(': ')[0])] = each.split(': ')[1]
            except IndexError:
                headerdata['header_' + str(each.split(':')[0])] = each.split(':')[1]
    logdata['headers']=headerdata # Adding header data as a sub-dictionary
    logdata['sip']=r[2]
    logdata['dip']=r[6]
    logdata['method']=str(r[3])
    logdata['url']=str(r[4])
    logdata['useragent']=str(r[5])
    lasttime = int(float(r[0]))+1
    linecount = linecount+1
    logs.append(logdata)
if starttime == lasttime:
    conn.close()
    os.remove(pidfile)
    sys.exit(1)
try:
    c.execute("INSERT INTO submissions (timestamp,linessent) VALUES (?,?)",(lasttime,linecount))
    conn.commit()
    conn.close()
except sqlite3.Error as e:
    print("Error %s:" % e.args[0])
    os.remove(pidfile)
    sys.exit(1)

l = {'type': 'webhoneypot', 'logs': logs} # Changed type from 404report to reflect addition of new header data
d.post(l)
os.remove(pidfile)

try:
    os.popen("systemctl restart webpy")  # Web.py seems to hang periodically, so to bandaid this situation, we restart web.py twice an hour
except:
    pass

