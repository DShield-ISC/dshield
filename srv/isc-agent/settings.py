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
