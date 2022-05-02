#!/usr/bin/env python3

"""
Test script to retrieve API data for the dashboard
"""

import configparser
import requests
import sys
import base64
import os
import hmac
import hashlib

config = configparser.ConfigParser()
configfile = sys.argv[1]

try:
    config.read(configfile)
    key = config.get('DShield', 'apikey')
    email = config.get('DShield', 'email')
    piid = config.get('DShield','piid')
except configparser.NoSectionError as e:
    print("Error parsing config file. Can't find DShield section")
    sys.exit
nonce = base64.b64encode(os.urandom(8)).decode()
value = email+':'+key
hash = hmac.new(nonce.encode('utf-8'), value.encode('utf-8'), digestmod=hashlib.sha512).hexdigest()
x = requests.get(f"https://isc.sans.edu/api/hpotsummary/{email}/{nonce}/{hash}?json")
print(x.text)
print(f"https://isc.sans.edu/api/hpotsummary/{email}/{nonce}/{hash}?json")
