import pytest

from plugins.tcp.http import models

from tests.plugins.tcp.http.model_factories import *


@pytest.fixture(scope='package', autouse=True)
def create_tables():
    models.create_tables()
