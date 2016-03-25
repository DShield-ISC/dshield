#/usr/bin/python
#from hpe site: http://community.hpe.com/t5/Protect-Your-Assets/Leveraging-SimpleHTTPServer-as-a-Simple-Web-Honeypot/ba-p/6682905#.VvSO--IrKJB
import sys
import SimpleHTTPServer 
import SocketServer
import cgi
import logging

class HoneypotServer(SimpleHTTPServer.SimpleHTTPRequestHandler):

    def do_GET(self):
        logging.error(self.headers)
        SimpleHTTPServer.SimpleHTTPRequestHandler.do_GET(self)

    def do_POST(self): #handles POST request
        logging.error(self.headers)
        form = cgi.FieldStorage(
            fp=self.rfile,
            headers=self.headers,
            environ={'REQUEST_METHOD':'POST',
                     'CONTENT_TYPE':self.headers['Content-Type'],
                     })
        for item in form.list:
            logging.error(item)
        SimpleHTTPServer.SimpleHTTPRequestHandler.do_GET(self)

def usage():
    print("USAGE: python honeypot.py <port>")

def main(argv):
    if len(argv) < 2:
        return usage()

    RPORT = int(sys.argv[1])
    TheHandler = HoneypotServer
    httpd = SocketServer.TCPServer(("", RPORT), TheHandler)
    print "\n [***] Honeypot Web Server is running at port ", PORT
    httpd.serve_forever()

if __name__ == "__main__":
    try:
        main(sys.argv)
        
    except KeyboardInterrupt:
        print "\n The Honeypot has been stopped :("
        pass
