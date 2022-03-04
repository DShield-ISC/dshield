import logging
import settings

from twisted.internet import defer, reactor, protocol
from twisted.web.client import Agent
from twisted.web.http_headers import Headers
from plugins.tcp.http import models

logger = logging.getLogger(__name__)
# body = FileBodyProducer(logs)
send_to_dshield = True

logs = []


def http_request(url, data):
    logger.warning('HTTP Request')
    agent = Agent(reactor)

    d = agent.request(
        b"POST",
        url,
        Headers({'content-type': 'application/json', 'User-Agent': 'DShield PyLib 0.1'}),
        None,
    )

    def handle_response(response):
        logger.warning("handle_response")

    def cbShutdown(ignored):
        pass

    d.addCallback(handle_response)
    d.addBoth(cbShutdown)
    return d

def post():
    if bool(models.logs) is False or len(models.logs) == len(logs):
        logger.warning('No new data')
    else:
        for i in models.logs:
            logger.warning('Print only one')
            logger.warning(i['time'])
            logs.append(i)
        if send_to_dshield is True:
            logger.warning('ISC-AGENT SUBMIT TO DSHIELD')
        else:
            logger.warning('Send elsewhere')
        l = {'type': 'webhoneypot', 'logs': logs}
        logger.warning(l)
        http_request(settings.DSHIELD_URL, l)
        logger.warning('Data was submitted')
        models.logs.clear()
        logs.clear()
        l.clear()
        logger.warning(models.logs)
        logger.warning('Data cleared')
