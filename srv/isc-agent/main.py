import importlib
import logging

from twisted.internet import reactor

import settings

logger = logging.getLogger(__name__)

if __name__ == '__main__':
    logger.debug('ISC Agent starting')
    for plugin in settings.PLUGINS:
        logger.info(f'Plugin {plugin["name"]} activated')
        logger.debug(f'{plugin["name"]} options: {plugin}')
        module = importlib.import_module(f'plugins.{plugin["protocol"]}.{plugin["name"]}')
        module.handler(**plugin)

    reactor.run()
