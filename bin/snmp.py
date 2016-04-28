#!/usr/bin/python

from twisted.internet.task import react
from pysnmp.hlapi.twisted import *

def success((errorStatus, errorIndex, varBinds), hostname):
    if errorStatus:
           print('%s: %s at %s' % (
              hostname,
              errorStatus.prettyPrint(),
              errorIndex and varBinds[int(errorIndex)-1][0] or '?'
             )
           )
    else:
        for varBind in varBinds:
            print(' = '.join([ x.prettyPrint() for x in varBind ]))

def failure(errorIndication, hostname):
    print('%s failure: %s' % (hostname, errorIndication))

def getSysDescr(reactor, hostname):
    d = getCmd(SnmpEngine(),
    CommunityData('public', mpModel=0),
    UdpTransportTarget((hostname, 161)),
    ContextData(),
    ObjectType(ObjectIdentity('SNMPv2-MIB', 'sysDescr', 0)))
    d.addCallback(success, hostname).addErrback(failure, hostname)

    return d

react(getSysDescr, ['demo.snmplabs.com'])
