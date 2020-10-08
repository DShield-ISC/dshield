#!/usr/bin/env python

from http.server import BaseHTTPRequestHandler,HTTPServer
import ssl
import socket
from urllib.parse import urlparse
import db_builder
import sigmatch
import os
import sqlite3
import time
import cgi
import re
import requests


# Default port - feel free to change
PORT_NUMBER = 8000
PRODSTRING = 'Apache/3.2.3'


# got a webserver DB and will prolly have honeypot DB for dorks if we have sqlinjection
config = '..' + os.path.sep + 'DB' + os.path.sep + 'webserver.sqlite'
honeydb = '..' + os.path.sep + 'DB' + os.path.sep + 'config.sqlite'
# will be if user sets up SSL cert and key
certpath = '..' + os.path.sep + 'domain.crt'
keypath = '..' + os.path.sep + 'domain.key'

# Query to DShield API to determine local public IP address

local_pub_IP = requests.get('https://www4.dshield.org/api/myip?json')


# have to build Certificates to get this to work with https requests - recommend to do so, better data -
# name them the same as the ../server.cert and ../server.key or change above.
# openssl req \
#       -newkey rsa:2048 -nodes -keyout domain.key \
#       -x509 -days 365 -out domain.crt
if not os.path.exists(certpath) and not os.path.exists(keypath):
    _USE_SSL = False
else:
    _USE_SSL = True

    
def build_db():
    dbpath = '..' + os.path.sep + 'DB'
    if not os.path.exists(dbpath):
        print('DB directory not found creating directory.')
        os.makedirs(dbpath)
    db_builder.build_DB()

class SecureHTTPServer(HTTPServer):
    def __init__(self, server_address, handlerclass):
        HTTPServer.__init__(self, server_address, myhandler)
        ctx = ssl.Context(ssl.SSLv23_METHOD)
        # server.pem's location (containing the server private key and
        # the server certificate).
        ctx.use_privatekey_file('server.key')
        ctx.use_certificate_file('server.crt')
        self.socket = ssl.Connection(ctx, socket.socket(self.address_family,
                                                        self.socket_type))
        self.server_bind()
        self.server_activate()

# This class will handles any incoming request from
# the browser
class myhandler(BaseHTTPRequestHandler):
    ''' #not using this but will
    log_file = open(logfile, 'w')
    def log_message(self, format, *args):
        self.log_file.write("%s - - [%s] %s\n" %
                            (self.client_address[0],
                             self.log_date_time_string(),
                             format % args))
    '''
    server_version="GoAhead-Webs"
    sys_version=""
    def do_GET(self):
        webpath = '..' + os.path.sep + 'srv' + os.path.sep + 'www' + os.path.sep
        webpath_exists = os.path.exists(webpath)
        if webpath_exists:
            webdirlst = os.listdir(webpath)
            file_path = ''
            for i in webdirlst:
                site = i
                file_path = os.path.join(webpath, i)
        dte = time.time()
        targetip = local_pub_IP.json()['ip']
        # Each self.<module> item specified here as a variable needs to be specified in db_builder.py as well so that the db has a column to store it.
        address = self.client_address[0]
        cmd = '%s' % self.command  # same as ubelow
        path = '%s' % self.path  # see below comment
        headers = '%s' % self.headers
        # content_len = int(self.headers.getheader('content-length', 0))
        # body = self.rfile.read(content_len)

        try:
            if str(self.headers['user-agent']) is not None:
                useragentstring = str(self.headers['user-agent'])
        except:
            useragentstring = ""
        #self.send_response(200)
        rvers = '%s' % self.request_version
        c.execute("""INSERT INTO requests (date, headers, address, cmd, path, useragent, vers, summary,targetip) VALUES(?, ?, ?, ?, ?, ?, ?, ?,?)""",
                  (dte, headers, address, cmd, path, useragentstring, rvers, '- Standard Request.',targetip))
        try:
            c.execute("""INSERT INTO useragents (useragent) VALUES (?)""", [useragentstring])
        except sqlite3.IntegrityError:
            refid = c.execute("""SELECT refid FROM useragents WHERE useragent=?""", [useragentstring]).fetchone()
            if str(refid[0]) != "None":
                resp = c.execute("""SELECT * FROM responses WHERE RID=?""", (str(refid[0]))).fetchall()
                for i in resp:
                    self.send_header(i[2], i[3])
                #self.send_header('Date', self.date_time_string(time.time()))
                #self.end_headers()
            else:
                print(self.client_address[
                          0
                      ] + " - - [" + self.date_time_string() + "] - - Useragent: '" + useragentstring + "' needs a custom response.")
                self.send_response(200)  # OK
                self.send_header('Content-type', 'text/html')
                self.end_headers()
        except:
            self.send_response(200)
            self.send_header('Access-Control-Allow-Origin','*')
            self.send_header('Content-type', 'text/html')
            self.server_version=PRODSTRING
            self.end_headers()
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Content-type', 'text/html')
        self.server_version=PRODSTRING
        self.end_headers()
        # going to use xml or DB for this -
        # glastopf sigs https://github.com/mushorg/glastopf/tree/master/glastopf
        # or matches xml page see -  https://github.com/mushorg/glastopf/blob/master/glastopf/requests.xml
        #match = 0
        #sigmatch(self, path, 'robots')
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
        conn.commit()
        if sigmatch.sigmatch(self, path, 'robots') == 1:
            pass
        elif sigmatch.sigmatch(self, path, 'lfi') == 1:
            pass
        elif sigmatch.sigmatch(self, path, 'rfi') == 1:
            pass
        elif sigmatch.sigmatch(self, path, 'phpmyadmin') == 1:
            pass
        else:  # default
            message_parts = [
                '<title>Upload</title>\
                <form action=/ method=POST ENCTYPE=multipart/form-data>\
                <input type=file name=upfile> <input type=submit value=Upload>\
                <fieldset>\
                <legend>Form Using GET</legend>\
                <form method="get">\
                <p>Username: <input type="text" name="get_arg1"></p>\
                <p>Password: <input type="text" name="get_arg2"></p>\
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

    def do_HEAD(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Content-type', 'text/html')
        self.server_version=PRODSTRING
        self.end_headers()
        print(self.client_address[
                  0] + " - - [" + self.date_time_string() + "] - - Malicious pattern detected: HEAD request - looking for open proxy.")

    def do_CONNECT(self):
        if not _USE_SSL:
            self.send_response(200)
            self.send_header('Access-Control-Allow-Origin', '*')
            self.send_header('Content-type', 'text/html')
            self.send_header('Server', PRODSTRING)
            self.server_version=PRODSTRING
            self.end_headers()
            print(self.client_address[
                      0] + " - - [" + self.date_time_string() + "] - - Malicious pattern detected: CONNECT request - looking for open proxy.")

    def do_POST(self):
        # Parse the form data posted
        # try:
        dte = self.date_time_string()
        address = '%s' % self.client_address[0]
        cmd = '%s' % self.command
        path = '%s' % self.path
        headers = '%s' % self.headers

        try:
            if str(self.headers['user-agent']) is not None:
                useragentstring = str(self.headers['user-agent'])
        except:
            useragentstring = ""

        rvers = '%s' % self.request_version
        c.execute('''INSERT INTO postlogs (date, headers, address, cmd, path, useragent, vers, summary) VALUES(?, ?, ?, ?, ?, ?, ?, ?)''',
                  (dte, headers, address, cmd, path, useragentstring, rvers, "- standard post"))
        try:
            c.execute('''INSERT INTO useragents (useragent) VALUES (?)''', [useragentstring])
        except sqlite3.IntegrityError:
            refid = c.execute("""SELECT refid FROM useragents WHERE useragent=?""", [useragentstring]).fetchone()
            if str(refid[0]) != "None":
                resp = c.execute("""SELECT * FROM responses WHERE RID=?""", (str(refid[0]))).fetchall()
                for i in resp:
                    self.send_header(i[2], i[3])
                self.send_header('Date', self.date_time_string(time.time()))
                self.end_headers()
            else:
                print(self.client_address[
                          0] + " - - [" + self.date_time_string() + "] - - Useragent: '" + useragentstring + "' needs a custom response.")
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
        match = 0
        conn.commit()
        sigmatch.sigmatch(self, path, 'lfi')
        sigmatch.sigmatch(self, path, 'robots')
        sigmatch.sigmatch(self, path, 'rfi')

        for key in sorted(postvars):
            val = postvars[key]
            conn.commit()
            sigmatch.sigmatch(self, val[0], 'sqli')
            sigmatch.sigmatch(self, val[0], 'xss')

        if match != 1:
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
                                  (dte, address, cmd, path, useragentstring, rvers, key, val[0]))
                    self.wfile.write('        <tr>')
                    self.wfile.write('          <td align="right">%d</td>' % i)
                    self.wfile.write('          <td align="right">%s</td>' % key)
                    self.wfile.write('          <td align="left">%s</td>' % val[0])
                    self.wfile.write('        </tr>')
                self.wfile.write('      </tbody>')
                self.wfile.write('    </table>')

            self.wfile.write('    <p><a href="%s">Back</a></p>' % back)
            self.wfile.write('  </body>')
            self.wfile.write('</html>')
        conn.commit()
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
        dfn=dir(fn)
        if not dfn:
            return False, "Can't find our file name..."
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

if __name__ == "__main__":
    try:
        # Create a web server, DB and define the handler to manage the
        # incoming request
        build_db()
        conn = sqlite3.connect(config)
        c = conn.cursor()
        server = HTTPServer(('', PORT_NUMBER), myhandler)
        server.serve_forever()
        if _USE_SSL:
            server.socket = ssl.wrap_socket(server.socket, keyfile=keypath,
                                            certfile=certpath, server_side=True)
            print("using SSL")

        print('Started httpserver on port ', PORT_NUMBER)
        # Wait forever for incoming http requests
        server.serve_forever()

    except KeyboardInterrupt:
        print('^C received, shutting down the web server')
