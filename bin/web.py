#!/usr/bin/python

from BaseHTTPServer import BaseHTTPRequestHandler,HTTPServer
from datetime import datetime
import os
import sqlite3
import sys
import time
import urlparse

PORT_NUMBER = 8080

# configure config SQLLite DB and log directory

config = '..'+os.path.sep+'etc'+os.path.sep+'hpotconfig.db'
logdir = '..'+os.path.sep+'log'

# check if config database exists

db_is_new = not os.path.exists(config)
if db_is_new:
        print 'configuration database is not initicalized'
        sys.exit(0)

# check if log directory exists
        
if not os.path.isdir(logdir):
        print 'log directory does not exist. '+logdir
        sys.exit(0)

# each time we start, we start a new log file by appending to timestamp to access.log

logfile = logdir+os.path.sep+'access.log.'+str(time.time())


conn = sqlite3.connect(config)

#This class will handles any incoming request from
#the browser
class myHandler(BaseHTTPRequestHandler):

    def do_GET(self):
        #this will get the request headers - will use for querying database
        parsed_path = urlparse.urlparse(self.path)
        #req_path = self.path
        #headers = self.headers
        #ip = self.client_address
        #self.requests       
        #this will be where response will be figured out based on database query        
        message_parts = [
                'Client Values:',
                'client_address=%s (%s)' % (self.client_address, self.address_string()),
                'command=%s' % self.command,
                'path %s' % self.path,
                'real path=%s' % parsed_path.path,
                'request_version=%s' % self.request_version,
                '',
                'Server Values:',
                'server_version=%s' % self.server_version,
                'protocol_version=%s' % self.sys_version,
                'protocol_version=%s' % self.protocol_version,
                '',
                'Headers Received:',
                ]
        for name, value in sorted(self.headers.items()):
            message_parts.append('%s=%s' % (name, value.rstrip()))
        message_parts.append('')
        message = '\r\n'.join(message_parts)
                
        #print(headers)
        #print(req_path)
        #print(ip)
        self.send_response(200)
        self.send_header('Date','Thu, 28 Apr 2016 11:10:00 GMT')
        self.send_header('Content-type','text/html')
        self.end_headers()
        self.wfile.write(message)
        return
    
try:
    #Create a web server and define the handler to manage the
    #incoming request
    server = HTTPServer(('', PORT_NUMBER), myHandler)
    server.sys_version='test'

    print 'Started httpserver on port ' , PORT_NUMBER

    #Wait forever for incoming http requests
    server.serve_forever()

except KeyboardInterrupt:
    print '^C received, shutting down the web server'
    server.socket.close()


    
