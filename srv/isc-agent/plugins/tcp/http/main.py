import datetime
import json
import logging
import os
import random
import re
from http import HTTPStatus
from typing import Dict, Optional

import requests
from jinja2 import Environment, BaseLoader
from twisted.web import server, resource
from twisted.internet import endpoints, reactor, ssl, task
from twisted.web.http import Request

import settings
from plugins.tcp.http.models import Signature, prepare_database, RequestLog, read_db_and_log, hydrate_tables
from plugins.tcp.http.schemas import Condition
from utils import get_auth

condition_translator = {
    Condition.absent: lambda x, y: x not in y,
    Condition.contains: lambda x, y: x in y,
    Condition.equal: lambda x, y: x == y,
    Condition.regex: re.match,
}
default_http_ports = [8000, 8080]
default_https_ports = [8443]
default_submit_logs_rate = 300
logger = logging.getLogger(__name__)
template_environment = Environment(loader=BaseLoader(), autoescape=True)


def extract_request_attributes(request: Request) -> Dict:
    return {
        'args': request.args,
        'client_ip': request.getClientIP(),
        'cookies': {k.decode(): v.decode() for k, v in request.received_cookies.items()},
        'headers': {k.decode(): v.decode() for k, v in request.getAllHeaders().items()},
        'method': request.method.decode(),
        'password': request.getPassword().decode(),
        'path': request.path.decode(),
        'target_ip': settings.LOCAL_IP,
        'user': request.getUser().decode(),
        'version': request.clientproto,
    }


def get_winning_signature(request_attributes: Dict) -> Optional[Signature]:
    top_score = 0
    winning_signature = None
    signatures = settings.DATABASE_SESSION.query(Signature).order_by(Signature.max_score.desc()).all()
    for signature in signatures:
        if top_score >= signature.max_score:
            break
        score = get_signature_score(signature.rules, request_attributes)
        if score and score >= top_score:
            top_score = score
            winning_signature = signature
    return winning_signature


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


def log_request(request_attributes: Dict, signature_id: Optional[int] = None, response_id: Optional[int] = None):
    request_log = RequestLog(
        client_ip=request_attributes['client_ip'],
        # data={'post_data': request_attributes['args']},  TODO - convert keys from bytes to strings
        headers=str(request_attributes['headers']),
        method=request_attributes['method'],
        path=request_attributes['path'],
        response_id=response_id,
        signature_id=signature_id,
        target_ip=request_attributes['target_ip'],
        version=request_attributes['version'],
    )
    settings.DATABASE_SESSION.add(request_log)
    settings.DATABASE_SESSION.flush()
    read_db_and_log()


def submit_logs():
    # Submit logs
    request_logs = settings.DATABASE_SESSION.query(RequestLog).all()
    logger.debug(request_logs)
    if request_logs:
        auth = get_auth()
        resp = requests.post(
            f"{settings.DSHIELD_URL}/submitapi/",
            json={
                "type": "webhoneypot",
                "logs": [rl.format_log_for_submission() for rl in request_logs],
                "authheader": auth
            },
            headers={
                'content-type': 'application/json',
                'User-Agent': 'DShield PyLib 0.1',
                'X-ISC-Authorization': auth,
                'X-ISC-LogType': "httprequest"
            }
        )
        if not resp.ok:
            logger.error(
                f"Failed to submit logs: (status code: %s) %s",
                resp.status_code,
                resp.text
            )
        else:
            logger.info(f"succesfully submitted logs {request_logs}")
            
    hydrate_tables()


class HTTP(resource.Resource):
    isLeaf = True

    def render(self, request: Request):
        request_attributes = extract_request_attributes(request)
        signature = get_winning_signature(request_attributes)

        if signature:
            response = random.choice(signature.responses)  # nosec
            request.setResponseCode(response.status_code)

            template_variables = {
                **request_attributes,
                'datetime': datetime.datetime.now()
            }
            body = template_environment.from_string(response.body).render(template_variables).encode()
            headers = json.loads(
                template_environment.from_string(
                    json.dumps(response.headers)
                ).render(template_variables)
            )
            for name, value in headers.items():
                request.responseHeaders.setRawHeaders(name, [value])
            request.responseHeaders.setRawHeaders('Content-Length', [str(len(body))])
            request.write(body)
            log_request(request_attributes, signature.id, response.id)
        else:
            request.setResponseCode(HTTPStatus.BAD_REQUEST)
            body = HTTPStatus.BAD_REQUEST.description.encode()
            request.responseHeaders.setRawHeaders('Content-Length', [str(len(body))])
            request.write(body)
            log_request(request_attributes)
        return b''


def handler(**kwargs):
    prepare_database()

    submit_logs_task = task.LoopingCall(submit_logs)
    submit_logs_task.start(kwargs.get('submit_logs_rate', default_submit_logs_rate), now=True)

    http_ports = kwargs.get('http_ports', default_http_ports)
    https_ports = kwargs.get('https_ports', default_https_ports)

    for port in http_ports:
        logger.info(port)
        endpoints.TCP4ServerEndpoint(reactor, port).listen(server.Site(HTTP()))

    if os.path.exists(settings.PRIVATE_KEY) and os.path.exists(settings.CERT_KEY):
        ssl_context = ssl.DefaultOpenSSLContextFactory(settings.PRIVATE_KEY, settings.CERT_KEY)
        for port in https_ports:
            endpoints.SSL4ServerEndpoint(reactor, port, ssl_context).listen(server.Site(HTTP()))
    else:
        logger.warning(f'Will not start https because cert or key file not found at {settings.CERT_KEY}')
