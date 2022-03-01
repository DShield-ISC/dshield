import importlib
import logging

from twisted.internet import task, reactor
from plugins.tcp.http import iscagentsubmit

import settings

logger = logging.getLogger(__name__)

if __name__ == '__main__':
    logger.debug('ISC Agent starting')
    for plugin in settings.PLUGINS:
        logger.info('Plugin %s activated', plugin['name'])
        logger.debug('%s options: %s', plugin['name'], plugin)
        module = importlib.import_module(f'plugins.{plugin["protocol"]}.{plugin["name"]}')
        module.handler(**plugin)

    # l = task.LoopingCall(iscagentsubmit.post)
    # l.start(2.0)
    reactor.run()
