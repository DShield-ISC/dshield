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
#logfile = logdir+os.path.sep+'access.log.'+str(time.time())
# not using above using dB for logging now.

conn = sqlite3.connect(config)
c = conn.cursor()

#Create's table for request logging.
c.execute('''CREATE TABLE IF NOT EXISTS requests
            (date text, address text, cmd text, path text, useragent text, vers text)''')

#Creates table for useragent unique values - RefID will be response RefID
c.execute('''CREATE TABLE IF NOT EXISTS useragents
            (
                ID integer primary key, RefID integer, useragent text,
                CONSTRAINT useragent_unique UNIQUE (useragent)
            )
        ''')

#Creates table for responses based on useragents.RefID will be IndexID
c.execute('''CREATE TABLE IF NOT EXISTS responses
            (
                ID integer primary key,
                RID integer,
                HeaderField text,
                dataField text
            )''')

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
        UserAgentString = '%s' % str(self.headers['user-agent'])
        rvers = '%s' % self.request_version
        c.execute("INSERT INTO requests VALUES('"+dte+"','"+cladd+"','"+cmd+"','"+path+"','"+UserAgentString+"','"+rvers+"')")
        try:
            c.execute("INSERT INTO useragents VALUES(NULL,NULL,'"+UserAgentString+"')")
        except sqlite3.IntegrityError:
            RefID = c.execute("SELECT RefID FROM useragents WHERE useragent='"+UserAgentString+"'").fetchone()
            #print(str(RefID[0]))
            if str(RefID[0]) != "None":
                Resp = c.execute("SELECT * FROM responses WHERE RID="+str(RefID[0])+"").fetchall()
                #self.send_response(200)
                #print(Resp[1][3])
                for i in Resp:
                    self.send_header(i[2], i[3])
                #self.send_header(Resp[1][2], Resp[1][3])
                self.send_header('Date', self.date_time_string(time.time()))
                self.end_headers()
            else:
                print("Useragent: '"+UserAgentString+"' needs a custom response.")

        finally:
            message_parts = [
                'Client Values:',
                'client_address=%s (%s)' % (self.client_address, self.address_string()),
                'command=%s' % self.command,
                'path %s' % self.path,
                #'real path=%s' % parsed_path.path,
                'request_version=%s' % self.request_version,
                'User-agent: %s\n' % str(self.headers['user-agent']),
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

        conn.commit()
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
    #server.sys_version = 'test'

    print 'Started httpserver on port ' , PORT_NUMBER

    #Wait forever for incoming http requests
    server.serve_forever()

except KeyboardInterrupt:
    print '^C received, shutting down the web server'
    server.socket.close()
    conn.close()
