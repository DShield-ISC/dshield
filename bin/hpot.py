#!/usr/bin/python

import logging
import threading
import time
import SocketServer
import sqlite3
import urllib2

logging.basicConfig(level=logging.DEBUG,
                    format='%(name)s: %(message)s',
                    )



class ThreadedTCPRequestHandler(SocketServer.BaseRequestHandler):
    def __init__(self, request, client_address, server):
        self.patterns=patterns
        self.responses=responses
        self.logger = logging.getLogger('ThreadedTCPRequestHandler')
        self.logger.debug('__init__ ThreadedTCPRequestHandler')
        SocketServer.BaseRequestHandler.__init__(self, request, client_address, server)
        return

    def handle(self):
        self.logger.debug('handle ThreadedTCPRequestHandler')
        self.received = ''
        self.data = ' '
        cur_threat = threading.current_thread()
        while (self.data != ''):
            try:
                self.data = self.request.recv(1)
            except SocketError as e:
                if e.errno != errno.ECONNRESET:
                    raise
                self.logger.debug('connection reset')
                return
            self.received = self.received + self.data
            if self.received.upper() in ['GET', 'POST', 'PUT', 'DELETE', 'HEAD', 'OPTIONS']:
                self.httphandler();
            if self.received.upper() in ['CONNECT']:
                self.proxyhandler();
            self.logger.debug("%s wrote:\n%s",self.client_address[0],self.received)

    def httphandler(self):
        self.logger.debug("HTTP HANDLER %s",self.received)
        self.data = ' '
        while (self.data != ''):
            self.data = self.request.recv(1)
            self.received = self.received + self.data
            # allow for buggy new line implementations
            if (self.received[-4:] == "\n\r\n\r" or self.received[-2:]=="\n\n"):
                print "END OF REQUEST"
                self.httpresponse()
                self.received = ''
                return
        self.logger.debug("HTTP DISCONNECT")

    def proxyhandler(self):
        self.logger.debug("PROXY HANDLER %s", self.received)
        self.data=' '
        while (self.data != ''):
            self.data = self.request.recv(1)
            self.received = self.received + self.data
            # allow for buggy new line implementations
            if (self.received[-4:] == "\n\r\n\r" or self.received[-2:]=="\n\n"):
                print "END OF REQUEST"
                self.proxyresponse()
                self.received = ''
                return
        self.logger.debug("PROXY DISCONNECT")

    def proxyresponse(self):
        # need to pull out url and retrieve it
        lines=self.received.split("\n")
        url=lines[0].split(' ')[1]
        self.logger.debug("PROXY RESPONSE %s",url)
        response=urllib2.urlopen(url)
        html=response.read()
        self.request.sendall(html)
        pass

    def httpresponse(self):
        self.logger.debug("HTTP RESPONSE")
        responseid=0
        rq=self.received
        rq.decode('utf-8')
        for pattern in self.patterns:

            if pattern[0] in rq:
                responseid=pattern[2]
                break

        print type(responses[responseid])
        print responses[responseid]
        print responseid
        self.request.sendall(str(responses[responseid][0]))




class ThreadedTCPServer(SocketServer.ThreadingMixIn, SocketServer.TCPServer):
    pass

def end():
    logger.debug("ending")
    server.shutdown()
    server.server_close()
    quit()

def loadconfig():
    patterns=[]
    responses=[]
    conn=sqlite3.connect('../etc/hpotconfig.db')
    for row in conn.execute('SELECT pattern, priority, responseid from patterns order by priority asc'):
        patterns.append(row);
    for row in conn.execute('SELECT response from responses'):
        responses.append(row);
    return (patterns,responses);

if __name__ == "__main__":

    HOST, PORT = "0.0.0.0", 8080
    logger = logging.getLogger('main')
    config=loadconfig()
    patterns=config[0]
    responses=config[1]
    SocketServer.TCPServer.allow_reuse_address = True
    server = ThreadedTCPServer((HOST, PORT), ThreadedTCPRequestHandler)
    server_thread=threading.Thread(target=server.serve_forever)
    server_thread.daemon = True
    server_thread.start()
    logger.debug("Server loop running in thread: %s",server_thread.name)
    while True:
        time.sleep(1)
    server.shutdown()
    server.server_close()


