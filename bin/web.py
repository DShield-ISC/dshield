#!/usr/bin/python

from BaseHTTPServer import BaseHTTPRequestHandler,HTTPServer
from datetime import datetime
import os
import sqlite3
import sys
import time
import urlparse
import cgi
import ssl
import logging
import argparse
import mimetypes
import posixpath
import re

try:
    from cStringIO import StringIO
except ImportError:
    from StringIO import StringIO

PORT_NUMBER = 8080

#bummer need to fix :(
# configure config SQLLite DB and log directory

#config = '..'+os.path.sep+'etc'+os.path.sep+'hpotconfig.db'
logdir = '..'+os.path.sep+'log'
config = './webserver.sqlite'
# check if config database exists

def build_DB():
    db_is_new = not os.path.exists(config)
    if db_is_new:
            print 'configuration database is not initialized'
            sys.exit(0)

    # check if log directory exists

    #if not os.path.isdir(logdir):
    #        print 'log directory does not exist. '+logdir
    #        sys.exit(0)

    # each time we start, we start a new log file by appending to timestamp to access.log
    #logfile = logdir+os.path.sep+'access.log.'+str(time.time())
    # not using above using dB for logging now.

    conn = sqlite3.connect(config)
    c = conn.cursor()

    #Create's table for request logging.
    c.execute('''CREATE TABLE IF NOT EXISTS requests
                (
                    date text,
                    address text,
                    cmd text,
                    path text,
                    useragent text,
                    vers text
                )
            ''')

    #Creates table for useragent unique values - RefID will be response RefID
    c.execute('''CREATE TABLE IF NOT EXISTS useragents
                (
                    ID integer primary key,
                    RefID integer,
                    useragent text,
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
                )
            ''')

    #post logging database
    c.execute('''CREATE TABLE IF NOT EXISTS posts
                (
                    ID integer primary key,
                    date text,
                    address text,
                    cmd text,
                    path text,
                    useragent text,
                    vers text,
                    formkey text,
                    formvalue text
                )
            ''')
    c.execute('''CREATE TABLE IF NOT EXISTS files
                (
                    ID integer primary key,
                    RID integer,
                    filename text,
                    DATA blob
                )
            ''')


    conn.commit()
    conn.close()

#This class will handles any incoming request from
#the browser
class myHandler(BaseHTTPRequestHandler):

    def do_HEAD(self):
        conn = sqlite3.connect(config)
        # this will be where response will be figured out based on database query
        c = conn.cursor()
        # vars
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
            conn.commit()


    def do_GET(self):
        conn = sqlite3.connect(config)
        c = conn.cursor()
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
                print(self.headers)
            else:
                print("Useragent: '"+UserAgentString+"' needs a custom response.")
                self.send_response(200)  # OK
                self.send_header('Content-type', 'text/html')
                self.end_headers()

        message_parts = [
        '<title>Upload</title>\
        <form action=/ method=POST ENCTYPE=multipart/form-data>\
        <input type=file name=upfile> <input type=submit value=Upload>\
        <fieldset>\
        <legend>Form Using GET</legend>\
        <form method="get">\
        <p>Form: <input type="text" name="get_arg1"></p>\
        <p>Enter data: <input type="text" name="get_arg2"></p>\
        <input type="submit" value="GET Submit">\
        </form>\
        </fieldset>\
        <p>&nbsp;</p>\
        <fieldset>'
        ]
        #print sorted(self.headers.items())

        #for name, value in sorted(self.headers.items()):
        #    message_parts.append('%s=%s' % (name, value.rstrip()))
        #message_parts.append('')
        message = '\r\n'.join(message_parts)

        conn.commit()
        self.wfile.write(message)
        return

    def do_POST(self):
        conn = sqlite3.connect(config)
        # Parse the form data posted
        '''
        Handle POST requests.
        '''
        #logging.debug('POST %s' % (self.path))
        c = conn.cursor()
        #try:
        dte = self.date_time_string()
        cladd = '%s' % self.address_string()
        cmd = '%s' % self.command
        path = '%s' % self.path
        UserAgentString = '%s' % str(self.headers['user-agent'])
        rvers = '%s' % self.request_version
        c.execute("INSERT INTO posts VALUES("
                  "NULL,'"+dte+"','"+cladd+"','"+cmd+"','"+path+"','"+UserAgentString+"','"+rvers+"',NULL,NULL)"
                  )

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
                print(self.headers)
            else:
                print("Useragent: '"+UserAgentString+"' needs a custom response.")
                self.send_response(200)  # OK
                self.send_header('Content-type', 'text/html')
                self.end_headers()


        # CITATION: http://stackoverflow.com/questions/4233218/python-basehttprequesthandler-post-variables
        ctype, pdict = cgi.parse_header(self.headers['content-type'])
        if ctype == 'multipart/form-data':
            postvars = cgi.parse_multipart(self.rfile, pdict)
        elif ctype == 'application/x-www-form-urlencoded':
            length = int(self.headers['content-length'])
            postvars = cgi.parse_qs(self.rfile.read(length), keep_blank_values=1)
        else:
            postvars = {}

        # Get the "Back" link.
        back = self.path if self.path.find('?') < 0 else self.path[:self.path.find('?')]

        # Display the POST variables.
        self.wfile.write('<html>')
        self.wfile.write('  <head>')
        self.wfile.write('    <title>Server POST Response</title>')
        self.wfile.write('  </head>')
        self.wfile.write('  <body>')
        self.wfile.write('    <p>POST variables (%d).</p>' % (len(postvars)))

        if len(postvars):
            # Write out the POST variables in 3 columns.
            self.wfile.write('    <table>')
            self.wfile.write('      <tbody>')
            i = 0
            print(postvars)
            for key in sorted(postvars):
                i += 1
                val = postvars[key]
                if key == "upfile":
                    #c.execute("INSERT INTO files VALUES"
                    #          "(""NULL,NULL'" + key + "','" + val[0] + "','" + cmd + "','" + path + "','" +
                    #          UserAgentString + "','" + rvers + "','" + key + "','" +
                    #          val[0] + "')")
                    c.execute(
                        "INSERT INTO files VALUES(NULL,NULL,'" + key + "','" +val[0] + "')")
                else:
                    c.execute("INSERT INTO posts VALUES(NULL,'" + dte + "','" + cladd + "','" + cmd + "','" + path + "','" + UserAgentString + "','" + rvers + "','" + key + "','" +val[0]+"')")
                self.wfile.write('        <tr>')
                self.wfile.write('          <td align="right">%d</td>' % (i))
                self.wfile.write('          <td align="right">%s</td>' % key)
                self.wfile.write('          <td align="left">%s</td>' % val[0])
                self.wfile.write('        </tr>')
                conn.commit()
            self.wfile.write('      </tbody>')
            self.wfile.write('    </table>')

        self.wfile.write('    <p><a href="%s">Back</a></p>' % (back))
        self.wfile.write('  </body>')
        self.wfile.write('</html>')
        return

    def deal_post_data(self):
        boundary = self.headers.plisttext.split("=")[1]
        remainbytes = int(self.headers['content-length'])
        line = self.rfile.readline()
        remainbytes -= len(line)
        if not boundary in line:
            return (False, "Content NOT begin with boundary")
        line = self.rfile.readline()
        remainbytes -= len(line)
        fn = re.findall(r'Content-Disposition.*name="file"; filename="(.*)"', line)
        dir(fn)
        if not fn:
            return (False, "Can't find out file name...")
        path = self.translate_path(self.path)
        fn = os.path.join(path, fn[0])
        line = self.rfile.readline()
        remainbytes -= len(line)
        line = self.rfile.readline()
        remainbytes -= len(line)
        try:
            out = open(fn, 'wb')

        except IOError:
            return (False, "Can't create file to write, do you have permission to write?")

        preline = self.rfile.readline()
        remainbytes -= len(preline)
        while remainbytes > 0:
            line = self.rfile.readline()
            remainbytes -= len(line)
            if boundary in line:
                preline = preline[0:-1]
                if preline.endswith('\r'):
                    preline = preline[0:-1]
                out.write(preline)
                out.close()
                return (True, "File '%s' upload success!" % fn)
            else:
                out.write(preline)
                preline = line
        return (False, "Unexpect Ends of data.")

try:
    #Create a web server and define the handler to manage the
    #incoming request
    conn = sqlite3.connect(config)
    build_DB()
    server = HTTPServer(('', PORT_NUMBER), myHandler)
    #server.sys_version = 'test'

    print 'Started httpserver on port ' , PORT_NUMBER

    #Wait forever for incoming http requests
    server.serve_forever()

except KeyboardInterrupt:
    print '^C received, shutting down the web server'
    server.socket.close()
    conn.close()
