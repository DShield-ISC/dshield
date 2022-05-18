import logging

import settings

from twisted.internet import reactor
from twisted.web.client import Agent
from twisted.web.http_headers import Headers
from plugins.tcp.http import models
from DShield import DshieldSubmit

logger = logging.getLogger(__name__)
logs = []


def isc_agent_submit(data):
    logger.warning('HTTP Request')
    d = DshieldSubmit('')
    d.post(data)

    def handle_response(response):
        logger.warning("handle_response")

    def cb_shutdown(ignored):
        pass

    return 0


def isc_agent_log():
    if bool(models.logs) is False or len(models.logs) == len(logs):
        logger.warning('No new data')
    else:
        for i in models.logs:
            i['time']=int(i['time'].timestamp())
            logs.append(i)
        l = {'type': 'webhoneypot', 'logs': logs}
        logger.warning(l)
        isc_agent_submit(l)
        logger.warning('Data was submitted')
        models.logs.clear()
        logs.clear()
        l.clear()
        logger.warning(models.logs)
        logger.warning('Data cleared')
