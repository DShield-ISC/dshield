"""
version 2019-11-17-01

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
import configparser
import sys
import socket
import struct
import syslog


class DshieldSubmit:
    id = 0
    key = ''
    url = 'https://www.dshield.org/submitapi/'

    types = ['email', 'firewall', 'sshlogin', 'telnetlogin', '404report', 'httprequest', 'webhoneypot']
    logtypesregex={'generic': '^([A-Z][a-z]{2})\s+([0-9]+)\s([0-9:]+).*(IN=.*)',
                   'pi': '(^\d+) \S+ kernel:\[[0-9\. ]+\]\s+DSHIELDINPUT IN=\S+ .* (SRC=.*)',
                   'aws': '(^\d+) \S+ kernel: DSHIELDINPUT IN=\S+ .* (SRC=.*)'}
    authheader = ''

    def __init__(self, filename):
        self.honeypotmask = -1
        self.honeypotnet = -1
        self.replacehoneypotip = -1
        self.anonymizenet = -1
        self.anonymizenetmask = -1
        self.anonymizemask = -1
        self.fwlogfile = "/var/log/dshield.log"
        self.readconfig(filename)

    @staticmethod
    def testurl(string):
        urlre = re.compile('(?i)\b((?:https?:(?:/{1,3}|[a-z0-9%])|[a-z0-9.\-]+[.](?:[a-z]{2,13})/)'
                           '(?:[^\s()<>{}\[\]]+|\([^\s()]*?\([^\s()]+\)[^\s()]*?\)|\([^\s]+?\))+'
                           '(?:\([^\s()]*?\([^\s()]+\)[^\s()]*?\)|\([^\s]+?\)|[^\s`!()\[\]{};:\'".,<>?])'
                           '|(?:(?<!@)[a-z0-9]+(?:[.\-][a-z0-9]+)*[.](?:[a-z]{2,13})\b/?(?!@)))')
        if urlre.match(string):
            return 1
        return 0

    def post(self, mydata):
        if mydata['type'] in self.types:
            self.authheader = self.makeauthheader()
            header = {'content-type': 'application/json', 'User-Agent': 'DShield PyLib 0.1',
                      'X-ISC-Authorization': self.authheader, 'X-ISC-LogType': mydata['type']}
            mydata['authheader'] = self.authheader
            r = requests.post(self.url, json=mydata, headers=header)
            if r.status_code != 200:
                self.log('received status code %d in response' % r.status_code)
        else:
            self.log('no valid type defined in post')

    def getmyip(self):
        header = {'User-Agent': 'DShield PyLib 0.1'}
        r = requests.get('https://www.dshield.org/api/myip?json', headers=header)
        if r.status_code != 200:
            self.log('received status code %d in response to getmyiprequest' % r.status_code)
            return -1
        return r.json()['ip']

    def makeauthheader(self):
        nonce = base64.b64encode(os.urandom(8)).decode()
        myhash = hmac.new((nonce + str(self.id)).encode('utf-8'), msg=self.key.encode('utf-8'), digestmod=hashlib.sha256).digest()
        hash64 = base64.b64encode(myhash).decode()
        header = 'ISC-HMAC-SHA256 Credentials=%s Userid=%s Nonce=%s' % (hash64, self.id, nonce.rstrip())
        return header

    def translateip4(self, ip):
        if self.replacehoneypotip == -1:
            return ip
        ip = self.ip42long(ip)
        if self.honeypotmask and self.honeypotnet and self.replacehoneypotip:
            if (ip & self.honeypotmask) == self.honeypotnet:
                ip = self.replacehoneypotip
        return self.long2ip4(ip)

    def anonymizeip4(self, ip):
        ip = self.ip42long(ip)
        # only run if all the variables we need are set
        if self.anonymizenet and self.anonymizemask and self.anonymizenetmask:
            # find out if the IP is in the right network
            if ip & self.anonymizenetmask == self.anonymizenet:
                # mask of the bit we don't want to show
                ip &= self.anonymizemask
        return self.long2ip4(ip)

    def anontranslateip4(self,ip):
        ip=self.translateip4(ip)
        return self.anonymizeip4(ip)

    # convert an IPv4 address from a string to its long integer representation
    @staticmethod
    def ip42long(ip):
        try:
            ipstr = socket.inet_pton(socket.AF_INET, ip)
        except socket.error:
            return -1
        return struct.unpack('!I', ipstr)[0]

    # convert an IPv6 address from a string to its 128bit INT representation
    @staticmethod
    def ip62long(ip):
        try:
            ipstr = socket.inet_pton(socket.AF_INET6, ip)
        except socket.error:
            return -1
        a, b = struct.unpack('!2Q', ipstr)
        return (a << 64) | b

    # convert a long integer back to an IP address string
    @staticmethod
    def long2ip4(ip):
        asciiip='127.0.0.1'
        try:
            asciiip=socket.inet_ntoa(struct.pack('!I', ip))
        except:
            print ("Error. %s not in range" % (ip) )
        return asciiip

    # convert a network from CIDR notification into two integers for the network IP and the network mask
    def cidr2long(self, ip):
        parts = [-1, -1]
        # split the string by '/' or just make it a /32 if there is no /
        if ip.count('/') == 1:
            parts = ip.split('/')
        else:
            parts[0] = ip
            parts[1] = 32
        # convert the network part into a long integer
        parts[0] = self.ip42long(parts[0])
        # convert the mask into a long integer mask.
        parts[1] = self.mask42long(int(parts[1]))
        return parts

    # convert a bitmask like /24 into a long integer
    def mask42long(self,mask):
        return 2**32-(2**(32-mask))

    def readconfig(self, filename):
        home = os.getenv("HOME", "")
        if filename == '':
            if os.path.isfile(home+'/etc/dshield.ini'):
                filename = home+'/etc/dshield.ini'
            elif os.path.isfile('/etc/dshield.ini'):
                filename = '/etc/dshield.ini'
            elif os.path.isfile('/etc/dshield/dshield.ini'):
                filename = '/etc/dshield/dshield.ini'
            else:
                filename = home+'/.dshield.ini'

        if os.path.isfile(filename):
            config = configparser.ConfigParser()
            config.read(filename)
            self.id = config.getint('DShield', 'userid')
            if self.id == 0:
                self.log("no userid configured")
                sys.exit()
            key = config.get('DShield', 'apikey')
            apikeyre = re.compile('^[a-zA-Z0-9=+/]+$')
            if apikeyre.match(key):
                self.key = key
            else:
                self.log("no api key configured")
                sys.exit()

            # extract translate internal IP settings

            translate = config.get('DShield', 'honeypotip')
            translate = self.cidr2long(translate)
            self.honeypotnet = translate[0]
            self.honeypotmask = translate[1]
            replacehoneypotip = config.get('DShield', 'replacehoneypotip')
            if replacehoneypotip == 'auto':
                replacehoneypotip = self.getmyip()
            self.replacehoneypotip = self.ip42long(replacehoneypotip)

            # extract anonymization settings.

            anonymize = config.get('DShield', 'anonymizeip')
            anonymize = self.cidr2long(anonymize)
            self.anonymizenet = anonymize[0]
            self.anonymizenetmask = anonymize[1]
            self.anonymizemask = self.ip42long(config.get('DShield', 'anonymizemask'))
            self.fwlogfile = config.get('DShield','fwlogfile')
        else:
            self.log("config file %s not found" % filename)
            sys.exit()
        return 1

    def getopts(self,argv):
        opts = {}  # Empty dictionary to store key-value pairs.
        while argv:  # While there are arguments left to parse...
            if argv[0][0] == '-':  # Found a "-name value" pair.
                opts[argv[0]] = argv[1]  # Add key and value to the dictionary.
            argv = argv[1:]  # Reduce the argument list by copying it starting from index 1.
        return opts

    def check_pid(self,pidfile):        
        """ Check For the existence of a unix pid. """
        with open(pidfile, 'r') as file:
            pid = file.readline()
            pid = pid.rstrip('\n')
        try:
            os.kill(int(pid), 0)
        except OSError:
            return False
        else:
            return True

    def identifylog(self,line):
        for type in self.logtypesregex:
            m=re.match(self.logtypesregex[type],line)
            if m:
                return type
        return ''
            
    def log(self,line):
        line=line.strip("\000")        
        if os.isatty(sys.stdout.fileno()):
            print(line)
        syslog.syslog(syslog.LOG_INFO,line)
