import logging
import settings

from twisted.internet import reactor
from twisted.web.client import Agent, FileBodyProducer
from twisted.web.http_headers import Headers
from plugins.tcp.http import models

agent = Agent(reactor)
logger = logging.getLogger(__name__)
# body = FileBodyProducer(logs)
send_to_dshield = True
l = []
d = agent.request(
    b"POST",
    b"127.0.0.1:8000",
    Headers({'content-type': 'application/json', 'User-Agent': 'DShield PyLib 0.1'}),
    None,
)


def post():
    if bool(models.logs) is False or len(models.logs) == len(l):
        logger.warning('No new data')
    else:
        for i in models.logs:
            logger.warning(i['time'])
            l.append(i)
        if send_to_dshield == True:
            logger.warning('ISC-AGENT SUBMIT TO DSHIELD')
        else:
            logger.warning('Send elsewhere')
        logger.warning(l)
        logger.warning('Data was submitted')
        models.logs.clear()
        logger.warning(models.logs)
        logger.warning('Data cleared')



def clear_db():
    logger.warning('Other timer')
