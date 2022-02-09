import logging
import random
import re

from twisted.web import server, resource
from twisted.internet import reactor, endpoints, ssl
from twisted.web.http import Request

import settings
from plugins.tcp.http.models import Response, Signature, prepare_database


default_ports = [80, 8000, 8080]
condition_translator = {
    'absent': lambda x, y: x not in y,
    'contains': lambda x, y: x in y,
    'regex': re.match,
    'equal': lambda x, y: x == y
}
logger = logging.getLogger(__name__)
key = settings.PRIVATE_KEY
cert = settings.CERT_KEY

sslContext = ssl.DefaultOpenSSLContextFactory(key, cert)

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
        return content.encode()


def handler(**kwargs):
    prepare_database()
    ports = kwargs.get('ports', default_ports)
    for port in ports:
        endpoints.serverFromString(reactor, f'tcp:{port}').listen(server.Site(HTTP()))

    endpoints.SSL4ServerEndpoint(reactor, 8001, sslContext).listen(server.Site(HTTP()))


