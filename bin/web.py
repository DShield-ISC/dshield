#!/usr/bin/python
from BaseHTTPServer import BaseHTTPRequestHandler,HTTPServer
import os
import sqlite3
import sys

PORT_NUMBER = 8080

db_filename = '\opt\dshield\db\webserver.sqlite'

db_is_new = not os.path.exists(db_filename)

conn = sqlite3.connect(db_filename)

if db_is_new:
        print 'Need to create schema'
        sys.exit(0)

#This class will handles any incoming request from
#the browser
class myHandler(BaseHTTPRequestHandler):
    #Handler for the GET requests
    def do_GET(self):
        #this will get the request headers - will use for querying database
        req_path = self.path
        host = self.headers('host')
        UsrAgent = self.headers('User-Agent')
        Accept = self.headers('Accept')
        AcceptLang = self.headers('Accept-Language')
        Connection = self.headers('Connection')
    
        #SqlQuery stuff - set response headers as global

        
        #this will be where response will be figured out based on database query        
        print(host)
        print(req_path)
        self.send_response(200)
        self.send_header('Content-type','text/html')
        self.end_headers()
        # Send the html message
        self.wfile.write("Hello World !")
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


    
