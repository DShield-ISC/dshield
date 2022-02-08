#!/usr/bin/env python3

""" quick script to collect responses from web servers.

    this script will be used to better impersonate different
    devices

"""

import sys
import re
import requests
import json

def parsemacros(headervalue, macrodata):
    """ expand macros """
    for macro in re.findall(r'%%([^%]+)%%', headervalue):
        headervalue = headervalue.replace('%%' + macro + '%%', macrodata[macro])
    return headervalue


method = "GET"
headers = {"User-Agent": "collect response v 0.1",
           "host": "%%target%%"
           }
target = sys.argv[1]
match = re.search(r'(https?)://([^/]+)(.*)', target)
urldata = {'protocol': match.group(1), 'target': match.group(2), 'url': match.group(3)}
for k in headers:
    headers[k] = parsemacros(headers[k], urldata)
if method=='HEAD':    
    response = requests.head(target, headers=headers)
if method=='GET':
    response = requests.get(target, headers=headers)    
r = {}
r['headers'] = dict(response.headers)
r['responseid'] = 1
r['comment'] = 'comment'
r['headers']['Date'] = '%%date%%'
r['status_code'] = response.status_code
r['body'] = response.text.replace(target, '%%target%%')
print(json.dumps([r,]))
