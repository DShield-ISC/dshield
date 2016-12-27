#!/usr/bin/env python

import email
import json
from sys import stdin
from DShield import DshieldSubmit
import hashlib

Message = "".join(stdin.readlines())
msg = email.message_from_string(Message)
data = {'files': [], 
        'subject': msg['subject'], 
        'from': msg['from'], 
        'message-id': msg['message-id']}
if msg.is_multipart():
    for part in msg.get_payload():
        filename = part.get_filename()
        payload=part.get_payload(decode=True)
        shahash=hashlib.sha256(payload).hexdigest()
        filesize=len(payload)
        filetype=part.get_content_type()
        if filename:
            data['files'].append({'filename': filename, 
                                  'sha256hash': shahash, 
                                  'filesize': filesize,
                                  'filetype': filetype})
        if filetype == 'text/html'




d = DshieldSubmit('')
data['type'] = 'email'
d.post(data)
