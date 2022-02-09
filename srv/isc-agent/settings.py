import logging.config
import os

from sqlalchemy import create_engine
from sqlalchemy.orm import Session

__all_ = [
    # DATABASE SETTINGS
    'DATABASE_DEBUG_LOGGING',
    'DATABASE_ENGINE',
    'DATABASE_SESSION',
    'DATABASE_URL',

    # PLUGINS
    'PLUGINS',
]

# APPLICATION
BASE_DIR = os.path.join(os.path.dirname(__file__))
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
DATABASE_DEBUG_LOGGING = os.getenv('DATABASE_DEBUG_LOGGING', False)
DATABASE_URL = os.getenv('DATABASE_URL', 'sqlite+pysqlite:///:memory:')
DATABASE_ENGINE = create_engine(
    DATABASE_URL,
    echo=DATABASE_DEBUG_LOGGING,
    echo_pool=DATABASE_DEBUG_LOGGING,
    future=True
)
DATABASE_SESSION = Session(DATABASE_ENGINE)

# CSS certification key and certificate
PRIVATE_KEY = os.path.join('key.pem')
CERT_KEY = os.path.join('cert.pem')

# PLUGINS
# Eventually this value will be inferred from a settings file of some sort
PLUGINS = [
    {
        'protocol': 'tcp',
        'name': 'http',
        'ports': [
            80,
            8000,
            8080,
        ]
    }
]

