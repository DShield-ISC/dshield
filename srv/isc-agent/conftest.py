import pytest
from sqlalchemy.orm import Session

import settings


@pytest.fixture(scope='function', autouse=True)
def database_session():
    transaction = settings.DATABASE_ENGINE.connect().begin()
    settings.DATABASE_SESSION = Session(settings.DATABASE_ENGINE)
    yield settings.DATABASE_SESSION
    transaction.rollback()
