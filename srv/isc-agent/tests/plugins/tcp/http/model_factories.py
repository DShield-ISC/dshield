import random
from functools import reduce
from http import HTTPStatus

import factory
import pytest

from plugins.tcp.http import models

__all__ = [
    'response_factory',
    'request_log_factory',
    'rule_factory',
    'signature_factory',
    'signature_response_factory',
]


@pytest.fixture
def response_factory(database_session):
    class ResponseFactory(factory.alchemy.SQLAlchemyModelFactory):
        class Meta:
            model = models.Response
            sqlalchemy_session = database_session
            sqlalchemy_session_persistence = 'flush'

        id = factory.Sequence(lambda n: n)
        body = "<b>Hello World</b>"
        headers = {'Server': 'Apache'}
        status_code = HTTPStatus.OK

    return ResponseFactory


@pytest.fixture
def request_log_factory(database_session, response_factory, signature_factory):
    class RequestLogFactory(factory.alchemy.SQLAlchemyModelFactory):
        class Meta:
            model = models.RequestLog
            sqlalchemy_session = database_session
            sqlalchemy_session_persistence = 'flush'

        id = factory.Sequence(lambda n: n)
        client_ip = '127.0.0.1'
        data = {}
        headers = ''
        method = 'GET'
        path = '/'
        target_ip = '127.0.0.1'
        version = '1.1'
        response = factory.SubFactory(response_factory)
        signature = factory.SubFactory(signature_factory)

    return RequestLogFactory


@pytest.fixture
def rule_factory(**kwargs):
    return lambda: {
        'attribute': kwargs.get(
            'attribute',
            random.choice(['client_ip', 'cookies', 'body', 'header', 'path', 'method', 'user', 'password'])
        ),
        'condition': kwargs.get(
            'condition',
            random.choice(['absent', 'contains', 'equals', 'regex'])
        ),
        'value': kwargs.get('value', ''),
        'score': kwargs.get('score', random.randint(1, 10)),
        'required': kwargs.get('required', False)
    }


@pytest.fixture
def signature_factory(database_session, response_factory):
    class SignatureFactory(factory.alchemy.SQLAlchemyModelFactory):
        class Meta:
            model = models.Signature
            sqlalchemy_session = database_session
            sqlalchemy_session_persistence = 'flush'

        id = factory.Sequence(lambda n: n)
        rules = [
            {
                'attribute': 'method',
                'value': 'post',
                'required': True,
                'condition': 'contains',
                'score': 1
            },
            {
                'attribute': 'body',
                'value': 'contain',
                'required': False,
                'condition': 'contains',
                'score': 1
            }
        ]
        max_score = factory.LazyAttribute(lambda o: reduce(lambda x, y: x + y, [rule.get('score', 1) for rule in o.rules], 0))

        @factory.post_generation
        def responses(obj, create, extracted, **kwargs):
            if not create:
                return
            obj.responses.extend(extracted or [])
            obj.responses.extend(response_factory.create_batch(size=kwargs.get('batch_size', 0), **kwargs))
            database_session.flush()
    return SignatureFactory


@pytest.fixture
def signature_response_factory(database_session, response_factory, signature_factory):
    class SignatureResponseFactory(factory.alchemy.SQLAlchemyModelFactory):
        class Meta:
            model = models.SignatureResponse
            sqlalchemy_session = database_session
            sqlalchemy_session_persistence = 'flush'

        response = factory.SubFactory(response_factory)
        signature = factory.SubFactory(signature_factory)

    return SignatureResponseFactory
