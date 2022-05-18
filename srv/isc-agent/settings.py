import configparser
import json
import logging.config
import os

import requests
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, registry
from DShield import DshieldSubmit
__all_ = [
    # DATABASE SETTINGS
    'DATABASE_DEBUG_LOGGING',
    'DATABASE_ENGINE',
    'DATABASE_SESSION',
    'DATABASE_URL',

    # PLUGINS
    'PLUGINS',
]
d = DshieldSubmit('')
config = d.config

# APPLICATION
BASE_DIR = os.path.join(os.path.dirname(__file__))
LOCAL_IP = d.getmyip()
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '{levelname} :: {asctime} :: <PID {process}:{processName}> :: {name} :: L:{lineno} :: {message}',
            'style': '{',
        },
        'simple': {
            'format': '{levelname} {message}',
            'style': '{',
        },
    },
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
            'formatter': 'verbose'
        },
    },
    'loggers': {
        '': {
            'handlers': ['console'],
            'level': os.getenv('LOG_LEVEL', 'INFO'),
            'propagate': False,
        },
    },
}
logging.config.dictConfig(LOGGING)


# DATABASE SETTINGS
DATABASE_MAPPER_REGISTRY = registry()
DATABASE_BASE = DATABASE_MAPPER_REGISTRY.generate_base()
DATABASE_DEBUG_LOGGING = os.getenv('DATABASE_DEBUG_LOGGING', False)
DATABASE_URL = os.getenv('DATABASE_URL', 'sqlite+pysqlite:///:memory:')
DATABASE_ENGINE = create_engine(
    DATABASE_URL,
    echo=DATABASE_DEBUG_LOGGING,
    echo_pool=DATABASE_DEBUG_LOGGING,
    future=True
)
DATABASE_SESSION = Session(DATABASE_ENGINE)

# SSL certification key and certificate
PRIVATE_KEY = os.getenv('ISC_AGENT_PRIVATE_KEY_PATH', '/srv/dshield/CA/keys/honeypot.key')
CERT_KEY = os.getenv('ISC_AGENT_CERT_KEY_PATH', '/srv/dshield/CA/certs/honeypot.crt')

# PLUGINS
# Read from settings.ini file
PLUGINS = []
for k, v in config.items():
    protocol_dict = {}
    if not k.startswith('plugin'):
        continue
    _, protocol, name = k.split(":")
    protocol_dict['protocol'] = protocol
    protocol_dict['name'] = name
    for k1, v1 in v.items():
        v1 = json.loads(v1)
        protocol_dict[k1] = v1
    PLUGINS.append(protocol_dict)



