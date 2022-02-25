import logging
import os
import random
import re

from twisted.web import server, resource
from twisted.internet import endpoints, reactor, ssl
from twisted.web.http import Request

import settings
from plugins.tcp.http.models import Response, Signature, prepare_database, store_request_log

default_http_ports = [80, 8000, 8080]
default_https_ports = [443]
condition_translator = {
    'absent': lambda x, y: x not in y,
    'contains': lambda x, y: x in y,
    'regex': re.match,
    'equal': lambda x, y: x == y
}
logger = logging.getLogger(__name__)




def get_signature_score(rules, attributes):
    score = 0
    for rule in rules:
        if rule['attribute'] not in attributes or rule['condition'] not in condition_translator:
            continue

        if ":" in rule['value']:
            key, value = rule['value'].split(':')
            attribute = attributes[rule['attribute']][key]
        else:
            value = rule['value']
            attribute = attributes[rule['attribute']]

        condition_function = condition_translator[rule['condition']]
        if condition_function(value, attribute):
            score += rule['score']
        elif rule['required']:
            score = 0
            break

    return score


class HTTP(resource.Resource):
    isLeaf = True

    def render(self, request: Request):
        request_attributes = {
            'client_ip': request.getClientIP(),
            'cookies': {k.decode(): v.decode() for k, v in request.received_cookies.items()},
            'headers': {k.decode(): v.decode() for k, v in request.getAllHeaders().items()},
            'path': request.path.decode(),
            'method': request.method.decode(),
            'user': request.getUser().decode(),
            'password': request.getPassword().decode()
        }

        top_score = 0
        winning_signature = None
        signatures = settings.DATABASE_SESSION.query(Signature).order_by(Signature.max_score.desc()).all()
        for signature in signatures:
            if top_score >= signature.max_score:
                break
            score = get_signature_score(signature.rules, request_attributes)
            if score >= top_score:
                top_score = score
                winning_signature = signature

        response = settings.DATABASE_SESSION.query(Response).get(random.choice(winning_signature.responses))  # nosec
        request.setResponseCode(response.status_code)
        for name, value in response.headers.items():
            request.setHeader(name, value)
        content = f'Winning Signature: {winning_signature}\n'
        content += f'Winning Score: {top_score}\n'
        content += f'Winning Response: {response}\n'
        content += f'Response Body: {response.body}'
        store_request_log(request_attributes)
        return content.encode()


def handler(**kwargs):
    prepare_database()
    http_ports = kwargs.get('http_ports', default_http_ports)
    https_ports = kwargs.get('https_ports', default_https_ports)
    for port in http_ports:
        endpoints.TCP4ServerEndpoint(reactor, port).listen(server.Site(HTTP()))
    if os.path.exists(settings.PRIVATE_KEY) and os.path.exists(settings.CERT_KEY):
        ssl_context = ssl.DefaultOpenSSLContextFactory(settings.PRIVATE_KEY, settings.CERT_KEY)
        for port in https_ports:
            endpoints.SSL4ServerEndpoint(reactor, port, ssl_context).listen(server.Site(HTTP()))
    else:
        logger.warning('Will not start https because cert or key file not found')


