#!/usr/bin/python
from BaseHTTPServer import BaseHTTPRequestHandler,HTTPServer
from datetime import datetime

PORT_NUMBER = 8080

#This class will handles any incoming request from
#the browser
class myHandler(BaseHTTPRequestHandler):

    #Handler for the GET requests
    def do_GET(self):
        print (self.path)
        print (self.request_version)
        print (self.headers)
        self.protocol_version='HTTP/1.1'
        self.server_version='mini_httpd/1.19'
        self.sys_version='19dec2003'
        self.send_response(200)
        self.send_header('Content-type','text/html; charset=%s')
        self.send_header('Content-Length','440');
        self.send_header('Last-Modified',datetime.today().strftime('%a, %d %b %Y %H:%M:%S GMT'))
        self.send_header('Connection','close');
        self.end_headers()
        # Send the html message
        self.wfile.write('''<HTML>
<HEAD><TITLE>Index of ./</TITLE></HEAD>
<BODY BGCOLOR="#99cc99" TEXT="#000000" LINK="#2020ff" VLINK="#4040cc">
                         <H4>Index of ./</H4>
                         <PRE>
                         <A HREF=".">.                               </A>    16Feb2016 21:37           4096
                         <A HREF="..">..                              </A>    16Feb2016 21:08           4096
                         </PRE>
                         <HR>
                         <ADDRESS><A HREF="http://www.acme.com/software/mini_httpd/">mini_httpd/1.19 19dec2003</A></ADDRESS>
                         </BODY>
                         </HTML>
''')
        return

try:
    #Create a web server and define the handler to manage the
    #incoming request
    server = HTTPServer(('', PORT_NUMBER), myHandler)
    print 'Started httpserver on port ' , PORT_NUMBER

    #Wait forever for incoming htto requests
    server.serve_forever()

except KeyboardInterrupt:
    print '^C received, shutting down the web server'
    server.socket.close()


    
