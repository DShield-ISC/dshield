#!/usr/bin/env python
# submit logs to DShield 404 project

import os
import sys
import sqlite3
from DShield import DshieldSubmit
from datetime import datetime
import json

pidfile = "/var/run/weblogparser.pid"
if os.path.isfile(pidfile):
    sys.exit('PID file found. Am I already running?')


f = open(pidfile, 'w')
f.write(str(os.getpid()))
f.close()
d = DshieldSubmit('')
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
except sqlite3.Error, e:
    print "Error %s:" % e.args[0]
    os.remove(pidfile)
    sys.exit(1)

    
starttime=0

if str(maxid[0]) != "None" :
    starttime=float(maxid[0])
rsx=c.execute("""SELECT date, address, cmd, path, useragent,targetip from requests where date>?""",[starttime]).fetchall()
logs = []
logdata = {}
lasttime = starttime
linecount = 0
for r in rsx:
     logdata['time']=float(r[0])
     logdata['sip']=d.anontranslateip4((r[1]))
     logdata['dip']=d.anontranslateip4((r[5]))
     logdata['method']=str(r[2])
     logdata['url']=str(r[3])
     logdata['useragent']=str(r[4])
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
except sqlite3.Error, e:
    print "Error %s:" % e.args[0]
    os.remove(pidfile)
    sys.exit(1)

l = {'type': '404report', 'logs': logs}
d.post(l)
os.remove(pidfile)

