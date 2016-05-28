#!/usr/bin/python

from BaseHTTPServer import BaseHTTPRequestHandler,HTTPServer
from datetime import datetime
import os
import sqlite3
import sys
import time
import urlparse
import cgi

PORT_NUMBER = 8080

# configure config SQLLite DB and log directory

#config = '..'+os.path.sep+'etc'+os.path.sep+'hpotconfig.db'
logdir = '..'+os.path.sep+'log'
config = './webserver.sqlite'
# check if config database exists

db_is_new = not os.path.exists(config)
if db_is_new:
        print 'configuration database is not initialized'
        sys.exit(0)

# check if log directory exists
        
if not os.path.isdir(logdir):
        print 'log directory does not exist. '+logdir
        sys.exit(0)

# each time we start, we start a new log file by appending to timestamp to access.log

logfile = logdir+os.path.sep+'access.log.'+str(time.time())

conn = sqlite3.connect(config)

c = conn.cursor()

c.execute('''CREATE TABLE IF NOT EXISTS requests
            (date text, address text, cmd text, path text, vers text)''')
conn.commit()

#This class will handles any incoming request from
#the browser
class myHandler(BaseHTTPRequestHandler):

    def do_GET(self):
        #this will get the request headers - will use for querying database
        #req_path = self.path
        #headers = self.headers
        #ip = self.client_address
        #self.requests       
        #this will be where response will be figured out based on database query        
        c = conn.cursor()
        #try:
        dte = self.date_time_string()
        cladd = '%s' % self.address_string()
        cmd = '%s' % self.command
        path = '%s' % self.path
        #ppath = parsed_path.path
        rvers = '%s' % self.request_version
        c.execute("INSERT INTO requests values('"+dte+"','"+cladd+"','"+cmd+"','"+path+"','"+rvers+"')")

        conn.commit()
        #except:
        #    print('Fail')

        message_parts = [
                'Client Values:',
                'client_address=%s (%s)' % (self.client_address, self.address_string()),
                'command=%s' % self.command,
                'path %s' % self.path,
                #'real path=%s' % parsed_path.path,
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
        self.send_header('Date', self.date_time_string(time.time()))
        self.send_header('Content-type','text/html')
        self.end_headers()
        self.wfile.write(message)
        return

#placeholder for when need to build post handling - not served at this time
class PostHandler(BaseHTTPRequestHandler):
    
    def do_POST(self):
        # Parse the form data posted
        form = cgi.FieldStorage(
            fp=self.rfile, 
            headers=self.headers,
            environ={'REQUEST_METHOD':'POST',
                     'CONTENT_TYPE':self.headers['Content-Type'],
                     })

        # Begin the response
        self.send_response(200)
        self.end_headers()
        self.wfile.write('Client: %s\n' % str(self.client_address))
        self.wfile.write('User-agent: %s\n' % str(self.headers['user-agent']))
        self.wfile.write('Path: %s\n' % self.path)
        self.wfile.write('Form data:\n')

        # Echo back information about what was posted in the form
        for field in form.keys():
            field_item = form[field]
            if field_item.filename:
                # The field contains an uploaded file
                file_data = field_item.file.read()
                file_len = len(file_data)
                del file_data
                self.wfile.write('\tUploaded %s as "%s" (%d bytes)\n' % \
                        (field, field_item.filename, file_len))
            else:
                # Regular form value
                self.wfile.write('\t%s=%s\n' % (field, form[field].value))
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
    conn.close()


    
