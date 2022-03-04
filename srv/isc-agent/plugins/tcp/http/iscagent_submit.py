import logging

import settings

from twisted.internet import reactor
from twisted.web.client import Agent
from twisted.web.http_headers import Headers

from plugins.tcp.http import models

logger = logging.getLogger(__name__)
logs = []


def isc_agent_submit(data, url=settings.DSHIELD_URL):
    logger.warning('HTTP Request')
    agent = Agent(reactor)
    d = agent.request(
        b"POST",
        url,
        Headers({'content-type': 'application/json', 'User-Agent': 'DShield PyLib 0.1'}),
        data,
    )

    def handle_response(response):
        logger.warning("handle_response")

    def cb_shutdown(ignored):
        pass

    d.addCallback(handle_response)
    d.addBoth(cb_shutdown)
    return d


def isc_agent_log():
    if bool(models.logs) is False or len(models.logs) == len(logs):
        logger.warning('No new data')
    else:
        for i in models.logs:
            logs.append(i)
        if settings.DSHIELD_URL_SEND is True:
            logger.warning('ISC-AGENT SUBMIT TO DSHIELD')
        else:
            logger.warning('Send elsewhere')
        l = {'type': 'webhoneypot', 'logs': logs}
        logger.warning(l)
        isc_agent_submit(l)
        logger.warning('Data was submitted')
        models.logs.clear()
        logs.clear()
        l.clear()
        logger.warning(models.logs)
        logger.warning('Data cleared')
