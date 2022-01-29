import importlib
import logging

import settings

logger = logging.getLogger(__name__)

if __name__ == '__main__':
    for plugin in settings.PLUGINS:
        module = importlib.import_module(f'plugins.{plugin["protocol"]}.{plugin["name"]}')
        module.handler()
