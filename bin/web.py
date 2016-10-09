#!/usr/env python

from BaseHTTPServer import BaseHTTPRequestHandler,HTTPServer
import ssl
import socket
import urlparse
import db_builder
import os
import sqlite3
import time
import cgi
import re

# Default port - feel free to change
PORT_NUMBER = 8080

# Global Variables - bummer need to fix :(
# configure config SQLLite DB and log directory
# hpconfig = '..'+os.path.sep+'etc'+os.path.sep+'hpotconfig.db'
logdir = '..' + os.path.sep + 'log'  # not using at this time - but will
# got a webserver DB and will prolly have honeypot DB for dorks if we have sqlinjection
config = '..' + os.path.sep + 'DB' + os.path.sep + 'webserver.sqlite'
# webpath = '..' + os.path.sep + 'srv' + os.path.sep + 'www' + os.path.sep
# will be if user sets up SSL cert and key
certpath = '..' + os.path.sep + 'domain.crt'
keypath = '..' + os.path.sep + 'domain.key'

# have to build Certificates to get this to work with https requests - recommend to do so, better data -
# name them the same as the ../server.cert and ../server.key or change above.
# openssl req \
#       -newkey rsa:2048 -nodes -keyout domain.key \
#       -x509 -days 365 -out domain.crt
if not os.path.exists(certpath) and not os.path.exists(keypath):
    _USE_SSL = False
else:
    _USE_SSL = True

# check if config database exists
def build_db():
    DBPath = '..' + os.path.sep + 'DB'
    if not os.path.exists(DBPath):
        print 'DB directory not found creating directory.'
        os.makedirs(DBPath)
    db_builder.build_DB()

# This class will handles any incoming request from
# the browser
class MyHandler(BaseHTTPRequestHandler):
    def do_head(self):
        # vars
        dte = self.date_time_string()
        cladd = '%s' % self.address_string()
        cmd = '%s' % self.command
        path = '%s' % self.path
        useragentstring = '%s' % str(self.headers['user-agent'])
        rvers = '%s' % self.request_version
        c.execute("""INSERT INTO requests (date, address, cmd, path, useragent, vers, summary) VALUES (?,?,?,?,?,?,?)""",
                  (dte, cladd, cmd, path, useragentstring, rvers, "Header info - not firing"))  # logging
        try:
            # trying to find all the new useragentstrings
            c.execute("""INSERT INTO useragents (useragent) VALUES (?)""", useragentstring)
        except sqlite3.IntegrityError:
            # get refid if there is one - should be set in Backend
            refid = c.execute("""SELECT refid FROM useragents WHERE useragent=?""", useragentstring).fetchone()
            if str(refid[0]) != "None":
                resp = c.execute("""SELECT * FROM responses WHERE RID=?""", (refid[0])).fetchall()
                for i in resp:
                    self.send_header(i[2], i[3])
                # can potentially have multiple if not careful
                self.send_header('Date', self.date_time_string(time.time()))
                self.end_headers()  # iterates through DB - need to make sure vuln pages and this are synced.
            else:
                # get refid if there is one - should be set in Backend
                print("Useragent: '"+useragentstring+"' needs a custom response.")
        except:
            self.send_response(200)
            self.end_headers()
        finally:
            conn.commit()

    def do_GET(self):
        webpath = '..' + os.path.sep + 'srv' + os.path.sep + 'www' + os.path.sep
        webpath_exists = os.path.exists(webpath)
        if webpath_exists:
            webdirlst = os.listdir(webpath)
            file_path = ''
            for i in webdirlst:
                site = i
                file_path = os.path.join(webpath, i)
        dte = self.date_time_string()   # date for logs
        cladd = '%s' % self.client_address[0]  #
        cmd = '%s' % self.command  # same as ubelow
        path = '%s' % self.path  # see below comment
        try:
            # maybe define other source? such as path like below - /etc/shadow needs apache headers
            useragentstring = '%s' % str(self.headers['user-agent'])
        except:
            useragentstring = "NULL"
        rvers = '%s' % self.request_version
        c.execute("""INSERT INTO requests (date, address, cmd, path, useragent, vers, summary) VALUES(?, ?, ?, ?, ?, ?, ?)""",
                  (dte, cladd, cmd, path, useragentstring, rvers, '- Standard Request.'))

        try:
            c.execute("""INSERT INTO useragents (useragent) VALUES (?)""", useragentstring)
        except sqlite3.IntegrityError:
            refid = c.execute("""SELECT refid FROM useragents WHERE useragent=?""", useragentstring).fetchone()
            if str(refid[0]) != "None":
                resp = c.execute("""SELECT * FROM responses WHERE RID=?""", (str(refid[0]))).fetchall()
                for i in resp:
                    self.send_header(i[2], i[3])
                self.send_header('Date', self.date_time_string(time.time()))
                self.end_headers()
                print(self.headers)
            else:
                print("Useragent: '"+useragentstring+"' needs a custom response.")
                self.send_response(200)  # OK
                self.send_header('Content-type', 'text/html')
                self.end_headers()
        except:
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
        # going to use xml or DB for this -
        # glastopf sigs https://github.com/mushorg/glastopf/tree/master/glastopf

        # or matches xml page see -  https://github.com/mushorg/glastopf/blob/master/glastopf/requests.xml
        pathmatch = c.execute("""SELECT patternString FROM Sigs""").fetchall()
        for i in pathmatch:
            if re.match(i[0], path)is not None:
                sigDescription = c.execute("""SELECT patternDescription FROM Sigs WHERE patternString=?""", [str(i[0])]).fetchone()
                print cladd + " - - " + dte + " - - Malicious pattern detected: " + sigDescription[0] + " - - " + path
                c.execute(
                    """INSERT INTO requests (date, address, cmd, path, useragent, vers, summary) VALUES(?, ?, ?, ?, ?, ?, ?)""",
                    (dte, cladd, cmd, path, useragentstring, rvers, "Malicious pattern" + str(sigDescription)))
                SigID = c.execute("""SELECT id FROM Sigs WHERE patternDescription=?""", [sigDescription[0]]).fetchone()
                # display vuln page based on sigdescription - and set headers based on OSTarget
                #response = c.execute("""SELECT * FROM responses WHERE SigID=?""", SigID[0]).fetchall()
                #for r in response:
                #hdrResponse = c.execute("""SELECT * FROM HdrResponses WHERE SigID=?""", (str(SigID[0]))).fetchall()
                #if hdrResponse is not None:
                #    for i in hdrResponse:
                #        self.send_header(i[2],i[3])
                pathreq = c.execute("""SELECT path FROM paths WHERE SigID=?""", [str(SigID[0],)]).fetchone()
                pathresp = c.execute("""SELECT OSPath FROM paths WHERE SigID=?""", [str(SigID[0],)]).fetchone()
                #responsepath = '..'+ os.path.sep + 'html' + os.path.sep + 'etc' + os.path.sep + 'passwd'
                responsepath = eval(str(pathresp[0]))
                print responsepath
                if re.match(pathreq[0], path) is not None:
                    f = open(responsepath)
                    self.wfile.write(f.read())
                    f.close


        if webpath_exists:  # os.path.isfile(file_path):
            try:
                refid = c.execute("""SELECT ID FROM sites WHERE site=?""", (site,)).fetchone()
                siteheaders = c.execute("""SELECT * FROM responses WHERE RID=?""", (str(refid[0]))).fetchall()
                for i in siteheaders:
                    self.send_header(i[1], i[2])
            except:
                pass

            #os.listdir(file_path)
            f = open(file_path)
            self.wfile.write(f.read())
            f.close()
        else:  # default
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
            message = '\r\n'.join(message_parts)
            self.wfile.write(message)

        conn.commit()
        return

    def do_POST(self):
        # Parse the form data posted
        # try:
        dte = self.date_time_string()
        cladd = '%s' % self.client_address[0]
        cmd = '%s' % self.command
        path = '%s' % self.path
        useragentstring = '%s' % str(self.headers['user-agent'])
        rvers = '%s' % self.request_version
        c.execute('''INSERT INTO postlogs (date, address, cmd, path, useragent, vers, summary) VALUES(?, ?, ?, ?, ?, ?, ?)''',
                  (dte, cladd, cmd, path, useragentstring, rvers, "- standard post"))
        try:
            print useragentstring
            c.execute('''INSERT INTO useragents (useragent) VALUES (?)''', [useragentstring])
        except sqlite3.IntegrityError:
            refid = c.execute("""SELECT refid FROM useragents WHERE useragent=?""", [useragentstring]).fetchone()
            if str(refid[0]) != "None":
                resp = c.execute("""SELECT * FROM responses WHERE RID=?""", (str(refid[0]))).fetchall()
                for i in resp:
                    self.send_header(i[2], i[3])
                self.send_header('Date', self.date_time_string(time.time()))
                self.end_headers()
                print(self.headers)
            else:
                print("Useragent: '"+useragentstring+"' needs a custom response.")
                self.send_response(200)  # OK
                self.send_header('Content-type', 'text/html')
                self.end_headers()

        # Manage post variables code set
        # CITATION: http://stackoverflow.com/questions/4233218/python-basehttprequesthandler-post-variables
        ctype, pdict = cgi.parse_header(self.headers['content-type'])
        if ctype == 'multipart/form-data':
            postvars = cgi.parse_multipart(self.rfile, pdict)
        elif ctype == 'application/x-www-form-urlencoded':
            length = int(self.headers['content-length'])
            postvars = urlparse.parse_qs(self.rfile.read(length), keep_blank_values=1)
        else:
            postvars = {}

        # Signatures identification section - will eventually
        # or matches xml page see -  https://github.com/mushorg/glastopf/blob/master/glastopf/requests.xml
        pathmatch = c.execute("""SELECT patternString FROM Sigs""").fetchall()
        for i in pathmatch:
            if re.match(i[0], path)is not None:
                sigDescription = c.execute("""SELECT patternDescription FROM Sigs WHERE patternString=?""", [str(i[0])]).fetchone()
                print cladd + " - - " + dte + " - - Malicious pattern detected: " + sigDescription[0] + " - - " + path
                c.execute(
                    '''INSERT INTO postlogs (date, address, cmd, path, useragent, vers, summary) VALUES(?, ?, ?, ?, ?, ?, ?)''',
                    (dte, cladd, cmd, path, useragentstring, rvers, "Malicious pattern - " + str(sigDescription)))

        #Signatures for  description code - set to detect and log at this time
        argsigs = c.execute("""SELECT patternString FROM Sigs WHERE module='xss'""").fetchall()
        for i in argsigs:
            for key in sorted(postvars):
                val = postvars[key]
                if re.match(i[0], val[0]) is not None:
                    sigDescription = c.execute("""SELECT patternDescription FROM Sigs WHERE patternString=?""",
                                               [str(i[0])]).fetchone()
                    print cladd + " - - " + dte + " - - Malicious pattern detected: " + sigDescription[0] + " - - " + val[0]
                    c.execute(
                        '''INSERT INTO postlogs (date, address, cmd, path, useragent, vers, summary) VALUES(?, ?, ?, ?, ?, ?, ?)''',
                        (dte, cladd, cmd, path, useragentstring, rvers, "Malicious pattern - " + str(sigDescription)))

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
            for key in sorted(postvars):
                i += 1
                val = postvars[key]
                if key == "upfile":
                    refid = c.execute("""SELECT ID FROM postlogs WHERE ID=(SELECT MAX(ID) FROM postlogs)""").fetchone()
                    try:
                        c.execute("""INSERT INTO files (rid, filename, data) VALUES(?, ?, ?)""",
                                                    (str(refid[0]), key, val[0]))
                    except:
                        print("Need to handle binaries.")
                else:
                    c.execute("""INSERT INTO postlogs (date, address, cmd, path, useragent, vers, formkey, formvalue)"""
                              """VALUES (?, ?, ?, ?, ?, ?, ?, ?)""",
                              (dte, cladd, cmd, path, useragentstring, rvers, key, val[0]))
                self.wfile.write('        <tr>')
                self.wfile.write('          <td align="right">%d</td>' % i)
                self.wfile.write('          <td align="right">%s</td>' % key)
                self.wfile.write('          <td align="left">%s</td>' % val[0])
                self.wfile.write('        </tr>')
                conn.commit()
            self.wfile.write('      </tbody>')
            self.wfile.write('    </table>')

        self.wfile.write('    <p><a href="%s">Back</a></p>' % back)
        self.wfile.write('  </body>')
        self.wfile.write('</html>')
        return

    def deal_post_data(self):
        boundary = self.headers.plisttext.split("=")[1]
        remainbytes = int(self.headers['content-length'])
        line = self.rfile.readline()
        remainbytes -= len(line)
        if boundary not in line:
            return False, "Content NOT begin with boundary"
        line = self.rfile.readline()
        remainbytes -= len(line)
        fn = re.findall(r'Content-Disposition.*name="file"; filename="(.*)"', line)
        dir(fn)
        if not fn:
            return False, "Can't find out file name..."
        # TODO: is translate path ever defined?
        path = self.translate_path(self.path)
        fn = os.path.join(path, fn[0])
        line = self.rfile.readline()
        remainbytes -= len(line)
        line = self.rfile.readline()
        remainbytes -= len(line)
        try:
            out = open(fn, 'wb')
            #magic.from_file(out)
        except IOError:
            return False, "Can't create file to write, do you have permission to write?"

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
                return True, "File '%s' upload success!" % fn
            else:
                out.write(preline)
                preline = line
        return False, "Unexpected End of data."

class SecureHTTPServer(HTTPServer):
    def __init__(self, server_address, HandlerClass):
        HTTPServer.__init__(self, server_address, MyHandler)
        ctx = ssl.Context(ssl.SSLv23_METHOD)
        # server.pem's location (containing the server private key and
        # the server certificate).
        ctx.use_privatekey_file('server.key')
        ctx.use_certificate_file('server.crt')
        self.socket = ssl.Connection(ctx, socket.socket(self.address_family,
                                                        self.socket_type))
        self.server_bind()
        self.server_activate()

if __name__ == "__main__":
    try:
        # Create a web server, DB and define the handler to manage the
        # incoming request
        build_db()
        conn = sqlite3.connect(config)
        c = conn.cursor()
        server = HTTPServer(('', PORT_NUMBER), MyHandler)
        if _USE_SSL:
            server.socket = ssl.wrap_socket(server.socket, keyfile=keypath,
                                            certfile=certpath, server_side=True)
            print "using SSL"

        print 'Started httpserver on port ', PORT_NUMBER
        # Wait forever for incoming http requests
        server.serve_forever()

    except KeyboardInterrupt:
        print '^C received, shutting down the web server'