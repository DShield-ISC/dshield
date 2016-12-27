"""
A class to interact with DShield

   Methods defined:
   - submit_firewall
   - submit_404
   - submit_sshpassword
   - submit_telnetpassword
   - submit_email


"""

import re
import os
import hmac
import hashlib
import base64
import requests
import json
import ConfigParser
import sys
reload(sys)
sys.setdefaultencoding('utf8')

class DshieldSubmit:
    id = 0
    key = ''
    url = 'https://isc.sans.edu/submitapi/'
    types = ['email', 'firewall', 'sshlogin', 'telnetlogin', '404report', 'httprequest']
    authheader=''

    def __init__(self,filename):
        self.readconfig(filename)

    def testurl(self,string):
        urlre=re.compile('(?i)\b((?:https?:(?:/{1,3}|[a-z0-9%])|[a-z0-9.\-]+[.](?:[a-z]{2,13})/)(?:[^\s()<>{}\[\]]+|\([^\s()]*?\([^\s()]+\)[^\s()]*?\)|\([^\s]+?\))+(?:\([^\s()]*?\([^\s()]+\)[^\s()]*?\)|\([^\s]+?\)|[^\s`!()\[\]{};:\'".,<>?«»“”‘’])|(?:(?<!@)[a-z0-9]+(?:[.\-][a-z0-9]+)*[.](?:[a-z]{2,13})\b/?(?!@)))')
        if urlre.match(string):
            return 1
        return 0

    def post(self, mydata):
        if mydata['type'] in self.types:
            self.authheader=self.makeauthheader()
            header = {'content-type': 'application/json', 'User-Agent': 'DShield PyLib 0.1',
                      'X-ISC-Authorization': self.authheader, 'X-ISC-LogType': mydata['type']}
            mydata['authheader']=self.authheader
            r = requests.post(self.url, json=mydata, headers=header)
            print(json.dumps(mydata))
            if r.status_code != 200:
                print 'received status code %d in response' % r.status_code
            print r.status_code
            print r.content
        else:
            print 'no valid type defined in post'

    def makeauthheader(self):
        nonce = os.urandom(8)
        myhash = hmac.new(nonce + str(self.id), msg=self.key.decode('base-64'), digestmod=hashlib.sha256).digest()
        hash64 = base64.b64encode(myhash).decode()
        nonce = base64.b64encode(nonce).decode()
        header = 'ISC-HMAC-SHA256 Credentials=%s Userid=%s Nonce=%s' % (hash64, self.id, nonce.rstrip())
        return header


    def readconfig(self,filename):
        home=os.getenv("HOME")
        if filename == '':
            filename=home+'/etc/dshield.ini'
        if  os.path.isfile(filename):
            config=ConfigParser.ConfigParser()
            config.read(filename)
            self.id=config.getint('DShield','userid')
            if self.id==0:
                print "no userid configured"
                sys.exit()
            key=config.get('DShield','apikey')
            apikeyre = re.compile('^[a-zA-Z0-9=+/]+$')
            if apikeyre.match(key):
                self.key = key
            else:
                print "no api key configured"
                sys.exit()
        else:
            print "file %s not found" % filename
            sys.exit()

        return 1
    
