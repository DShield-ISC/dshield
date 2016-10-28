#!/usr/env/python

import smtpd
import asyncore

class CustomSMTPServer(smtpd.SMTPServer):
    def process_message(self, peer, mailfrom, rcpttos, data):
        print 'Receiving message from:', peer
        print 'Message addressed from:', mailfrom
        print 'Message addressed to  :', rcpttos
        print 'Message length        :', len(data)
        return
def mailserv(port):
    server = CustomSMTPServer(('', port), None)
    asyncore.loop()

if __name__ == '__main__':
    #Create a web server and define the handler to manage the
    #incoming request
    try:
        mailserv()
    except:
        print "Requires basehttpserver response, match, and module."

