import importlib
import logging
from twisted.internet import reactor
import settings


logger = logging.getLogger(__name__)





if __name__ == '__main__':
    logger.debug('ISC Agent starting')
    for plugin in settings.PLUGINS:
        try:
            module = importlib.import_module(f'plugins.{plugin["protocol"]}.{plugin["name"]}')
            module.handler(**plugin)
            logger.info('Plugin %s activated', plugin['name'])
            logger.debug('%s options: %s', plugin['name'], plugin)
        except ModuleNotFoundError as e:
            logger.info('Plugin %s:%s not found', plugin['protocol'], plugin['name'])
            logger.info(e)
    reactor.run()
