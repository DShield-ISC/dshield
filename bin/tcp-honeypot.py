#!/usr/bin/env python

__description__ = 'TCP honeypot'
__author__ = 'Didier Stevens'
__version__ = '0.0.7'
__date__ = '2019/11/09'

"""
Source code put in public domain by Didier Stevens, no Copyright
https://DidierStevens.com
Use at your own risk

History:
  2018/03/08: start
  2018/03/09: continue
  2018/03/17: continue, added ssl
  2018/03/22: 0.0.2 added ssh
  2018/08/26: 0.0.3 added randomness when selecting a matching regular expression
  2018/09/09: added support for listeners via arguments
  2018/12/23: 0.0.4 added THP_SPLIT
  2019/03/12: added error handling
  2019/04/10: THP_STARTSWITH and THP_ELSE
  2019/05/30: 0.0.5 added File2String
  2019/07/11: 0.0.6 added error handling for oSocket.listen(5)
  2019/11/06: 0.0.7 added THP_ECHO
  2019/11/07: added option -f
  2019/11/09: updated man with TCP_ECHO details

Todo:
  Update manual with all listener configuration options
  Add support for PyDivert
"""

THP_REFERENCE = 'reference'
THP_SSL = 'ssl'
THP_CERTFILE = 'certfile'
THP_KEYFILE = 'keyfile'
THP_SSLCONTEXT = 'sslcontext'
THP_SSH = 'ssh'
THP_BANNER = 'banner'
THP_REPLY = 'reply'
THP_MATCH = 'match'
THP_LOOP = 'loop'
THP_REGEX = 'regex'
THP_STARTSWITH = 'startswith'
THP_ELSE = 'else'
THP_ACTION = 'action'
THP_DISCONNECT = 'disconnect'
THP_SPLIT = 'split'
THP_ECHO = 'echo'

dumplinelength = 16

#Terminate With CR LF
def TW_CRLF(data):
    if isinstance(data, str):
        data = [data]
    return '\r\n'.join(data + [''])

dListeners = {
    22:    {THP_BANNER: TW_CRLF('SSH-2.0-OpenSSH_6.6.1p1 Ubuntu-2ubuntu2')},
    2222:  {THP_REFERENCE: 22},
    2200:  {THP_SSH: {THP_KEYFILE: 'test_rsa.key', THP_BANNER: 'SSH-2.0-OpenSSH_6.6.1p1 Ubuntu-2ubuntu2'},
            THP_BANNER: TW_CRLF('Last login: Thu Mar 22 18:10:31 2018 from 192.168.1.1') + 'root@vps:~# ',
            THP_REPLY: '\r\nroot@vps:~# ',
            THP_LOOP: 10
           },
    443:   {THP_SSL: {THP_CERTFILE: 'cert-20180317-161753.crt', THP_KEYFILE: 'key-20180317-161753.pem'},
            THP_REPLY: TW_CRLF(['HTTP/1.1 200 OK', 'Date: %TIME_GMT_RFC2822%', 'Server: Apache', 'Last-Modified: Wed, 06 Jul 2016 17:51:03 GMT', 'ETag: "59652-cfd-edc33a50bfec6"', 'Accept-Ranges: bytes', 'Content-Length: 285', 'Connection: close', 'Content-Type: text/html; charset=UTF-8', '', '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">', '<link rel="icon" type="image/png" href="favicon.png"/>', '<html>', ' <head>', '    <title>Home</title>', '   <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">', '  </head>', ' <body>Welcome home!</body>', '</html>'])
           },
    8443:  {THP_REFERENCE: 443},
    80:    {THP_REPLY: TW_CRLF(['HTTP/1.1 200 OK', 'Date: %TIME_GMT_RFC2822%', 'Server: Apache', 'Last-Modified: Wed, 06 Jul 2016 17:51:03 GMT', 'ETag: "59652-cfd-edc33a50bfec6"', 'Accept-Ranges: bytes', 'Content-Length: 285', 'Connection: close', 'Content-Type: text/html; charset=UTF-8', '', '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">', '<link rel="icon" type="image/png" href="favicon.png"/>', '<html>', ' <head>', '    <title>Home</title>', '   <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">', '  </head>', ' <body>Welcome home!</body>', '</html>'])},
    591:   {THP_REFERENCE: 80},
    8008:  {THP_REFERENCE: 80},
    8080:  {THP_REFERENCE: 80},
    25:    {THP_LOOP: 10,
            THP_BANNER: TW_CRLF('220 HP1EUR02TC012.mail.protection.outlook.com Microsoft ESMTP MAIL Service ready at %TIME_GMT_RFC2822%'),
            THP_MATCH: {
                      'EHLO':    {THP_REGEX: '^[Ee][Hh][Ll][Oo]',   THP_REPLY: TW_CRLF(['250-HP1EUR02TC012.mail.protection.outlook.com', '250-PIPELINING', '250-SIZE 20971520', '250-ETRN', '250-ENHANCEDSTATUSCODES', '250 8BITMIME'])},
                      'default': {THP_REGEX: '^.',     THP_REPLY: TW_CRLF('500 5.5.2 Error: bad syntax')},
                     }
           },
    11211: {THP_LOOP: 10,
            THP_MATCH: {
                      'stats':   {THP_REGEX: '^stats',   THP_REPLY: TW_CRLF(['STAT pid 14868', 'STAT uptime 175931', 'STAT time %TIME_GMT_EPOCH%', 'STAT version 1.5.4', 'STAT id C3B806AA71F0887773210E75DD12BDAD', 'STAT pointer_size 32', 'STAT rusage_user 620.299700', 'STAT rusage_system 1545.703017', 'STAT curr_items 228', 'STAT total_items 779', 'STAT bytes 15525', 'STAT curr_connections 92', 'STAT total_connections 1740', 'STAT connection_structures 165', 'STAT cmd_get 7411', 'STAT cmd_set 28445156', 'STAT get_hits 5183', 'STAT get_misses 2228', 'STAT evictions 0', 'STAT bytes_read 2112768087', 'STAT bytes_written 1000038245', 'STAT limit_maxbytes 52428800', 'STAT threads 1', 'END'])},
                      'version': {THP_REGEX: '^version', THP_REPLY: TW_CRLF('VERSION 1.5.4')},
                      'get':     {THP_REGEX: '^get ',    THP_REPLY: TW_CRLF(['VALUE a 0 2', 'AA', 'END'])},
                      'set':     {THP_REGEX: '^set ',    THP_REPLY: TW_CRLF('STORED')},
                      'quit':    {THP_REGEX: '^quit',    THP_ACTION: THP_DISCONNECT},
                     }
           },
    21:    {THP_LOOP: 10,
            THP_BANNER: TW_CRLF('220 FTP server ready. All transfers are logged. (FTP) [no EPSV]'),
            THP_MATCH: {
                        'user':   {THP_REGEX: '^USER ',    THP_REPLY: TW_CRLF('331 Please specify the password.')},
                        'pass':   {THP_REGEX: '^PASS ',    THP_REPLY: TW_CRLF('230 Login successful.')},
                        'typea':  {THP_REGEX: '^TYPE A',   THP_REPLY: TW_CRLF('200 Switching to ASCII mode.')},
                        'auth':   {THP_REGEX: '^AUTH',     THP_REPLY: TW_CRLF('530 Please login with USER and PASS.')},
                        'pasv':   {THP_REGEX: '^PASV',     THP_REPLY: TW_CRLF('227 Entering Passive Mode (121)')},
                        'help':   {THP_REGEX: '^HELP',     THP_REPLY: TW_CRLF(['220 FTP server ready. All transfers are logged. (FTP) [no EPSV]', '530 Please login with USER and PASS.'])},
                       }
           },
    121:   {},
}

import optparse
import socket
import select
import threading
import time
import re
import ssl
import textwrap
import sys
import random
import traceback
import binascii
import struct
import inspect
if sys.version_info[0] >= 3:
    from io import StringIO
else:
    from cStringIO import StringIO
try:
    import paramiko
except:
    pass

def PrintManual():
    manual = r'''
Manual:

TCP listeners are configured with Python dictionary dListeners. The key is the port number (integer) and the value is another dictionary (listener dictionary).

When this listener dictionary is empty, the honeypot will accept TCP connections on the configured port, perform a single read and then close the connection.
The listener can be configured to perform more than one read: add key THP_LOOP to the dictionary with an integer as value. The integer specifies the maximum number of reads.
A banner can be transmitted before the first read, this is done by adding key THP_BANNER to the dictionary with a string as the value (the banner).
The listener can be configured to send a reply after each read, this is done by adding key THP_REPLY to the dictionary with a string as the value (the reply).
To increase the interactivity of the honeypot, keywords can be defined with replies. This is done by adding a new dictionary to the dictionary with key THP_MATCH.
Entries in this match dictionary are regular expressions (THP_REGEX): when a regular expression matches read data, the corresponding reply is send or action performed (e.g. disconnect).
If more than one regular expression matches, then the longest matching is selected. If there is more than one longest match (e.g. equal length), then one is selected at random.

TCP_ECHO can be used to send back any incoming data (echo). Like this:

dListeners = {
    4444:   {THP_LOOP: 10,
             THP_ECHO: None,
            },
}

TCP_ECHO also takes a function, which's goal is to transform the incoming data and return it. Here is an example with a lambda function that converts all lowercase letters to uppercase:

dListeners = {
    4444:   {THP_LOOP: 10,
             THP_ECHO: lambda x: x.upper(),
            },
}

If persistence is required across function calls, a custom class can also be provide. This class has to implement a method with name Process (input: incoming data, output: transformed data).

For example:

class MyEcho():
    def __init__(self):
        self.counter = 0
        
    def Process(self, data):
        self.counter += 1
        return 'Counter %d: %s\n' % (self.counter, repr(data))

dListeners = {
    4444:   {THP_LOOP: 10,
             THP_ECHO: MyEcho,
            },
}

A listener can be configured to accept SSL/TLS connections by adding key THP_SSL to the listener dictionary with a dictionary as value specifying the certificate (THP_CERTFILE) and key (THP_KEYFILE) to use. If an SSL context can not be created (for example because of missing certificate file), the listener will fallback to TCP.

A listener can be configured to accept SSH connections by adding key THP_SSH to the listener dictionary with a dictionary as value specifying the key (THP_KEYFILE) to use. This requires Python module paramiko, the listener will fallback to TCP if this module is missing.

When several ports need to behave the same, the dictionary can just contain a reference (THP_REFERENCE) to the port which contains the detailed description.

Helper function TW_CRLF (Terminate With CR/LF) can be used to format replies and banners.
Replies and banners can contain aliases: %TIME_GMT_RFC2822% and %TIME_GMT_EPOCH%, they will be instantiated when a reply is transmitted.

Output is written to stdout and a log file.

This tool has several command-line options, and can take listeners as arguments. These arguments are filenames of Python programs that define listeners.

Option -f (format) can be used to change the output format of data.
Possible values are: repr, x, X, a, A, b, B
The default value (repr) output's data on a single line using Python's repr function.
a is an ASCII/HEX dump over several lines, A is an ASCII/HEX dump too, but with duplicate lines removed.
x is an HEX dump over several lines, X is an HEX dump without whitespace.
b is a BASE64 dump over several lines, B is a BASE64 without whitespace.

It is written for Python 2 & 3 and was tested on Windows 10, Ubuntu 16 and CentOS 6.
'''
    for line in manual.split('\n'):
        print(textwrap.fill(line, 79))

#Convert 2 Bytes If Python 3
def C2BIP3(string):
    if sys.version_info[0] > 2:
        return bytes([ord(x) for x in string])
    else:
        return string

#Convert 2 Integer If Python 2
def C2IIP2(data):
    if sys.version_info[0] > 2:
        return data
    else:
        return ord(data)

# CIC: Call If Callable
def CIC(expression):
    if callable(expression):
        return expression()
    else:
        return expression

# IFF: IF Function
def IFF(expression, valueTrue, valueFalse):
    if expression:
        return CIC(valueTrue)
    else:
        return CIC(valueFalse)

class cDump():
    def __init__(self, data, prefix='', offset=0, dumplinelength=16):
        self.data = data
        self.prefix = prefix
        self.offset = offset
        self.dumplinelength = dumplinelength

    def HexDump(self):
        oDumpStream = self.cDumpStream(self.prefix)
        hexDump = ''
        for i, b in enumerate(self.data):
            if i % self.dumplinelength == 0 and hexDump != '':
                oDumpStream.Addline(hexDump)
                hexDump = ''
            hexDump += IFF(hexDump == '', '', ' ') + '%02X' % self.C2IIP2(b)
        oDumpStream.Addline(hexDump)
        return oDumpStream.Content()

    def CombineHexAscii(self, hexDump, asciiDump):
        if hexDump == '':
            return ''
        countSpaces = 3 * (self.dumplinelength - len(asciiDump))
        if len(asciiDump) <= self.dumplinelength / 2:
            countSpaces += 1
        return hexDump + '  ' + (' ' * countSpaces) + asciiDump

    def HexAsciiDump(self, rle=False):
        oDumpStream = self.cDumpStream(self.prefix)
        position = ''
        hexDump = ''
        asciiDump = ''
        previousLine = None
        countRLE = 0
        for i, b in enumerate(self.data):
            b = self.C2IIP2(b)
            if i % self.dumplinelength == 0:
                if hexDump != '':
                    line = self.CombineHexAscii(hexDump, asciiDump)
                    if not rle or line != previousLine:
                        if countRLE > 0:
                            oDumpStream.Addline('* %d 0x%02x' % (countRLE, countRLE * self.dumplinelength))
                        oDumpStream.Addline(position + line)
                        countRLE = 0
                    else:
                        countRLE += 1
                    previousLine = line
                position = '%08X:' % (i + self.offset)
                hexDump = ''
                asciiDump = ''
            if i % self.dumplinelength == self.dumplinelength / 2:
                hexDump += ' '
            hexDump += ' %02X' % b
            asciiDump += IFF(b >= 32 and b < 128, chr(b), '.')
        if countRLE > 0:
            oDumpStream.Addline('* %d 0x%02x' % (countRLE, countRLE * self.dumplinelength))
        oDumpStream.Addline(self.CombineHexAscii(position + hexDump, asciiDump))
        return oDumpStream.Content()

    def Base64Dump(self, nowhitespace=False):
        encoded = binascii.b2a_base64(self.data)
        if nowhitespace:
            return encoded
        oDumpStream = self.cDumpStream(self.prefix)
        length = 64
        for i in range(0, len(encoded), length):
            oDumpStream.Addline(encoded[0+i:length+i])
        return oDumpStream.Content()

    class cDumpStream():
        def __init__(self, prefix=''):
            self.oStringIO = StringIO()
            self.prefix = prefix

        def Addline(self, line):
            if line != '':
                self.oStringIO.write(self.prefix + line + '\n')

        def Content(self):
            return self.oStringIO.getvalue()

    @staticmethod
    def C2IIP2(data):
        if sys.version_info[0] > 2:
            return data
        else:
            return ord(data)

def HexDump(data):
    return cDump(data, dumplinelength=dumplinelength).HexDump()

def HexAsciiDump(data, rle=False):
    return cDump(data, dumplinelength=dumplinelength).HexAsciiDump(rle=rle)

def Base64Dump(data, nowhitespace=False):
    return cDump(data, dumplinelength=dumplinelength).Base64Dump(nowhitespace=nowhitespace)

def File2String(filename):
    try:
        f = open(filename, 'rb')
    except:
        return None
    try:
        return f.read()
    except:
        return None
    finally:
        f.close()

def FormatTime(epoch=None):
    if epoch == None:
        epoch = time.time()
    return '%04d%02d%02d-%02d%02d%02d' % time.localtime(epoch)[0:6]

class cOutput():
    def __init__(self, filename=None, bothoutputs=False):
        self.filename = filename
        self.bothoutputs = bothoutputs
        if self.filename and self.filename != '':
            self.f = open(self.filename, 'w')
        else:
            self.f = None

    def Line(self, line):
        if not self.f or self.bothoutputs:
            print(line)
        if self.f:
            try:
                self.f.write(line + '\n')
                self.f.flush()
            except:
                pass

    def LineTimestamped(self, line):
        self.Line('%s: %s' % (FormatTime(), line))

    def Exception(self):
        self.LineTimestamped('Exception occured:')
        if not self.f or self.bothoutputs:
            traceback.print_exc()
        if self.f:
            try:
                traceback.print_exc(file=self.f)
                self.f.flush()
            except:
                pass

    def Close(self):
        if self.f:
            self.f.close()
            self.f = None

def ReplaceAliases(data):
    data = data.replace('%TIME_GMT_RFC2822%', time.strftime("%a, %d %b %Y %H:%M:%S +0000", time.gmtime()))
    data = data.replace('%TIME_GMT_EPOCH%', str(int(time.time())))
    return data

def ParseNumber(number):
    if number.startswith('0x'):
        return int(number[2:], 16)
    else:
        return int(number)

def MyRange(begin, end):
    if begin < end:
        return range(begin, end + 1)
    elif begin == end:
        return [begin]
    else:
        return range(begin, end - 1, -1)

def ParsePorts(expression):
    ports = []
    for portrange in expression.split(','):
        result = portrange.split('-')
        if len(result) == 1:
            ports.append(ParseNumber(result[0]))
        else:
            ports.extend(MyRange(ParseNumber(result[0]), ParseNumber(result[1])))
    return ports

def ModuleLoaded(name):
    return name in sys.modules

if ModuleLoaded('paramiko'):
    class cSSHServer(paramiko.ServerInterface):
        def __init__(self, oOutput, connectionID):
            self.oEvent = threading.Event()
            self.oOutput = oOutput
            self.connectionID = connectionID

        def check_channel_request(self, kind, chanid):
            if kind == 'session':
                return paramiko.OPEN_SUCCEEDED
            return paramiko.OPEN_FAILED_ADMINISTRATIVELY_PROHIBITED

        def check_auth_password(self, username, password):
            self.oOutput.LineTimestamped('%s SSH username: %s' % (self.connectionID, username))
            self.oOutput.LineTimestamped('%s SSH password: %s' % (self.connectionID, password))
            return paramiko.AUTH_SUCCESSFUL

        def get_allowed_auths(self, username):
            return 'password'

        def check_channel_shell_request(self, channel):
            self.oEvent.set()
            return True

        def check_channel_pty_request(self, channel, term, width, height, pixelwidth, pixelheight, modes):
            return True

def SplitIfRequested(dListener, data):
    if THP_SPLIT in dListener:
        return [part for part in data.split(dListener[THP_SPLIT]) if part != '']
    else:
        return [data]

class ConnectionThread(threading.Thread):
    global dListeners

    def __init__(self, oSocket, oOutput, options):
        threading.Thread.__init__(self)
        self.oSocket = oSocket
        self.oOutput = oOutput
        self.options = options
        self.connection = None
        self.connectionID = None

    def run(self):
        oSocketConnection, address = self.oSocket.accept()
        self.connectionID = '%s:%d-%s:%d' % (self.oSocket.getsockname() + address)
        oSocketConnection.settimeout(self.options.timeout)
        self.oOutput.LineTimestamped('%s connection' % self.connectionID)
        dListener = dListeners[self.oSocket.getsockname()[1]]
        if THP_REFERENCE in dListener:
            dListener = dListeners[dListener[THP_REFERENCE]]
        try:
            oSSLConnection = None
            oSSLContext = dListener.get(THP_SSLCONTEXT, None)
            oSSHConnection = None
            oSSHFile = None
            if oSSLContext != None:
                oSSLConnection = oSSLContext.wrap_socket(oSocketConnection, server_side=True)
                self.connection = oSSLConnection
            elif dListener.get(THP_SSH, None) != None:
                if ModuleLoaded('paramiko'):
                    if THP_KEYFILE in dListener[THP_SSH]:
                        oRSAKey = paramiko.RSAKey(filename=dListener[THP_SSH][THP_KEYFILE])
                    else:
                        oRSAKey = paramiko.RSAKey.generate(1024)
                        self.oOutput.LineTimestamped('%s SSH generated RSA key' % self.connectionID)
                    oTransport = paramiko.Transport(oSocketConnection)
                    if THP_BANNER in dListener[THP_SSH]:
                        oTransport.local_version = dListener[THP_SSH][THP_BANNER]
                    oTransport.load_server_moduli()
                    oTransport.add_server_key(oRSAKey)
                    oSSHServer = cSSHServer(self.oOutput, self.connectionID)
                    try:
                        oTransport.start_server(server=oSSHServer)
                    except paramiko.SSHException:
                        self.oOutput.LineTimestamped('%s SSH negotiation failed' % self.connectionID)
                        raise
                    self.oOutput.LineTimestamped('%s SSH banner %s' % (self.connectionID, oTransport.remote_version))
                    oSSHConnection = oTransport.accept(20)
                    if oSSHConnection is None:
                        self.oOutput.LineTimestamped('%s SSH no channel' % self.connectionID)
                        raise
                    self.oOutput.LineTimestamped('%s SSH authenticated' % self.connectionID)
                    oSSHServer.oEvent.wait(10)
                    if not oSSHServer.oEvent.is_set():
                        self.oOutput.LineTimestamped('%s SSH no shell' % self.connectionID)
                        raise
                    self.connection = oSSHConnection
                    oSSHFile = oSSHConnection.makefile('rU')
                else:
                    self.oOutput.LineTimestamped('%s can not create SSH server, Python module paramiko missing' % self.connectionID)
                    self.connection = oSocketConnection
            else:
                self.connection = oSocketConnection
            if THP_ECHO in dListener and inspect.isclass(dListener[THP_ECHO]):
                echoObject = dListener[THP_ECHO]()
            else:
                echoObject = None
            if THP_BANNER in dListener:
                self.connection.send(ReplaceAliases(dListener[THP_BANNER]))
                self.oOutput.LineTimestamped('%s send banner' % self.connectionID)
            for i in range(0, dListener.get(THP_LOOP, 1)):
                if oSSHFile == None:
                    data = self.connection.recv(self.options.readbuffer)
                else:
                    data = oSSHFile.readline()
                self.LogData('data', data)
                for splitdata in SplitIfRequested(dListener, data):
                    if splitdata != data:
                        self.LogData('splitdata', splitdata)
                    if THP_ECHO in dListener:
                        if echoObject != None:
                            echodata = echoObject.Process(splitdata)
                        elif callable(dListener[THP_ECHO]):
                            echodata = dListener[THP_ECHO](splitdata)
                        else:
                            echodata = splitdata
                        self.connection.send(echodata)
                        self.LogData('send echo', echodata)
                    if THP_REPLY in dListener:
                        self.connection.send(ReplaceAliases(dListener[THP_REPLY]))
                        self.oOutput.LineTimestamped('%s send reply' % self.connectionID)
                    if THP_MATCH in dListener:
                        dKeys = {}
                        for item in dListener[THP_MATCH].items():
                            for key in item[1].keys():
                                dKeys[key] = 1 + dKeys.get(key, 0)
                        if THP_REGEX in dKeys and THP_STARTSWITH in dKeys:
                            self.oOutput.LineTimestamped('THP_MATCH cannot contain both THP_REGEX and THP_STARTSWITH!')
                        elif THP_REGEX in dKeys:
                            matches = []
                            for matchname, dMatch in dListener[THP_MATCH].items():
                                if THP_REGEX in dMatch:
                                    oMatch = re.search(dMatch[THP_REGEX], splitdata)
                                    if oMatch != None:
                                        matches.append([len(oMatch.group()), dMatch, matchname])
                            if self.ProcessMatches(matches, dListener):
                                break
                        elif THP_STARTSWITH in dKeys:
                            matches = []
                            for matchname, dMatch in dListener[THP_MATCH].items():
                                if THP_STARTSWITH in dMatch and splitdata.startswith(dMatch[THP_STARTSWITH]):
                                    matches.append([len(dMatch[THP_STARTSWITH]), dMatch, matchname])
                            if self.ProcessMatches(matches, dListener):
                                break
            #a# is it necessary to close both oSSLConnection and oSocketConnection?
            if oSSLConnection != None:
                oSSLConnection.shutdown(socket.SHUT_RDWR)
                oSSLConnection.close()
            oSocketConnection.shutdown(socket.SHUT_RDWR)
            oSocketConnection.close()
            self.oOutput.LineTimestamped('%s closed' % self.connectionID)
        except socket.timeout:
            self.oOutput.LineTimestamped('%s timeout' % self.connectionID)
        except Exception as e:
            self.oOutput.LineTimestamped("%s exception '%s'" % (self.connectionID, str(e)))

    def ProcessMatches(self, matches, dListener):
        result = False
        if matches == []:
            for matchname, dMatch in dListener[THP_MATCH].items():
                if THP_ELSE in dMatch:
                    matches.append([0, dMatch, THP_ELSE])
        if matches != []:
            matches = sorted(matches, reverse=True)
            longestmatches = [match for match in matches if match[0] == matches[0][0]]
            longestmatch = random.choice(longestmatches)
            dMatchLongest = longestmatch[1]
            if THP_REPLY in dMatchLongest:
                self.connection.send(ReplaceAliases(dMatchLongest[THP_REPLY]))
                self.oOutput.LineTimestamped('%s send %s reply' % (self.connectionID, longestmatch[2]))
            if dMatchLongest.get(THP_ACTION, '') == THP_DISCONNECT:
                self.oOutput.LineTimestamped('%s disconnecting' % self.connectionID)
                result = True
        return result

    def LogData(self, name, data):
        if self.options.format == 'repr':
            self.oOutput.LineTimestamped('%s %s %s' % (self.connectionID, name, repr(data)))
        else:
            self.oOutput.LineTimestamped('%s %s' % (self.connectionID, name))
            if self.options.format == 'a':
                self.oOutput.Line(HexAsciiDump(data))
            elif self.options.format == 'A':
                self.oOutput.Line(HexAsciiDump(data, True))
            elif self.options.format == 'x':
                self.oOutput.Line(HexDump(data))
            elif self.options.format == 'X':
                self.oOutput.Line(binascii.b2a_hex(data))
            elif self.options.format == 'b':
                self.oOutput.Line(Base64Dump(data))
            elif self.options.format == 'B':
                self.oOutput.Line(Base64Dump(data, True))

def TCPHoneypot(filenames, options):
    global dListeners

    oOutput = cOutput('tcp-honeypot-%s.log' % FormatTime(), True)

    for filename in filenames:
        oOutput.LineTimestamped('Exec: %s' % filename)
        execfile(filename, globals())

    if ModuleLoaded('paramiko'):
        paramiko.util.log_to_file('tcp-honeypot-ssh-%s.log' % FormatTime())

    if options.ports != '':
        oOutput.LineTimestamped('Ports specified via command-line option: %s' % options.ports)
        dListeners = {}
        for port in ParsePorts(options.ports):
            dListeners[port] = {}

    if options.extraports != '':
        oOutput.LineTimestamped('Extra ports: %s' % options.extraports)
        for port in ParsePorts(options.extraports):
            dListeners[port] = {}

    sockets = []

    for port in dListeners.keys():
        if THP_SSL in dListeners[port]:
            context = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH)
            try:
                context.load_cert_chain(certfile=dListeners[port][THP_SSL][THP_CERTFILE], keyfile=dListeners[port][THP_SSL][THP_KEYFILE])
                dListeners[port][THP_SSLCONTEXT] = context
                oOutput.LineTimestamped('Created SSL context for %d' % port)
            except IOError as e:
                if '[Errno 2]' in str(e):
                    oOutput.LineTimestamped('Error reading certificate and/or key file: %s %s' % (dListeners[port][THP_SSL][THP_CERTFILE], dListeners[port][THP_SSL][THP_KEYFILE]))
                else:
                    oOutput.LineTimestamped('Error creating SSL context: %s' % e)
                oOutput.LineTimestamped('SSL not enabled for %d' % port)

        oSocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        oSocket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        try:
            oSocket.bind((options.address, port))
        except socket.error as e:
            if '[Errno 98] Address already in use' in str(e):
                oOutput.LineTimestamped('Port %d can not be used, it is already open' % port)
                continue
            elif '[Errno 99] Cannot assign requested address' in str(e) or '[Errno 10049] The requested address is not valid in its context' in str(e):
                oOutput.LineTimestamped('Address %s can not be used (port %d)' % (options.address, port))
                continue
            elif '[Errno 10013] An attempt was made to access a socket in a way forbidden by its access permissions' in str(e):
                oOutput.LineTimestamped('Port %d can not be used, access is forbidden' % port)
                continue
            else:
                raise e
        try:
            oSocket.listen(5)
        except socket.error as e:
            if '[Errno 98] Address already in use' in str(e):
                oOutput.LineTimestamped('Port %d can not be used, it is already open' % port)
                continue
            elif '[Errno 99] Cannot assign requested address' in str(e) or '[Errno 10049] The requested address is not valid in its context' in str(e):
                oOutput.LineTimestamped('Address %s can not be used (port %d)' % (options.address, port))
                continue
            elif '[Errno 10013] An attempt was made to access a socket in a way forbidden by its access permissions' in str(e):
                oOutput.LineTimestamped('Port %d can not be used, access is forbidden' % port)
                continue
            else:
                raise e
        oOutput.LineTimestamped('Listening on %s %d' % oSocket.getsockname())
        sockets.append(oSocket)

    if sockets == []:
        return

    while True:
        readables, writables, exceptionals = select.select(sockets, [], [])
        for oSocket in readables:
            try:
                ConnectionThread(oSocket, oOutput, options).start()
            except:
                oOutput.Exception()

def Main():
    moredesc = '''

Source code put in the public domain by Didier Stevens, no Copyright
Use at your own risk
https://DidierStevens.com'''

    oParser = optparse.OptionParser(usage='usage: %prog [options]\n' + __description__ + moredesc, version='%prog ' + __version__)
    oParser.add_option('-m', '--man', action='store_true', default=False, help='Print manual')
    oParser.add_option('-t', '--timeout', type=int, default=10, help='Timeout value for sockets in seconds (default 10s)')
    oParser.add_option('-r', '--readbuffer', type=int, default=10240, help='Size read buffer in bytes (default 10240)')
    oParser.add_option('-a', '--address', default='0.0.0.0', help='Address to listen on (default 0.0.0.0)')
    oParser.add_option('-P', '--ports', default='', help='Ports to listen on (overrides ports configured in the program)')
    oParser.add_option('-p', '--extraports', default='', help='Extra ports to listen on (default none)')
    oParser.add_option('-f', '--format', default='repr', help='Output format (default repr)')
    (options, args) = oParser.parse_args()

    if options.man:
        oParser.print_help()
        PrintManual()
        return

    TCPHoneypot(args, options)

if __name__ == '__main__':
    Main()
