import logging

from twisted.internet import reactor
from twisted.web.client import Agent, FileBodyProducer
from twisted.web.http_headers import Headers

from plugins.tcp.http import models

agent = Agent(reactor)
logger = logging.getLogger(__name__)
logs = models.logs
body = FileBodyProducer(logs)

d = agent.request(
    b"POST",
    b"127.0.0.1:8000",
    Headers({'content-type': 'application/json', 'User-Agent': 'DShield PyLib 0.1'}),
    body,
)

def post_response(ignored):
    logger.warning('Data posted')

def test_post():
    d.addCallback(post_response)
    reactor.run
    logger.warning('ISC-AGENT SUBMIT TO DSHIELD')
    logger.warning('Print Logs')
    logger.warning(logs)
    l = {'type': 'webhoneypot', 'logs': logs}  # Changed type from 404report to reflect addition of new header data
    # d.post(l)
