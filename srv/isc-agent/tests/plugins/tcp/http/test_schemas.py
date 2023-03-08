import json

import pytest
from pydantic import ValidationError

from plugins.tcp.http import schemas
from plugins.tcp.http.models import Signature, Response


class TestResponse:
    def test_valid_payload(self, response_factory):
        response = response_factory.build()
        response_schema = schemas.Response(**response.to_dict())
        assert response_schema.dict()['body'] == response.body

    def test_invalid_payload(self, response_factory):
        response = response_factory.build()
        with pytest.raises(ValidationError) as e:
            payload = response.to_dict()
            del payload['id']
            schemas.Response(**payload)
        validation_errors = json.loads(e.value.json())
        assert len(validation_errors) == 1
        assert 'id' in validation_errors[0]['loc']


class TestRule:
    def test_valid_payload(self, rule_factory):
        rule = rule_factory()
        rule_schema = schemas.Rule(**rule)
        assert rule_schema.dict()['score'] == rule['score']

    def test_invalid_payload(self, rule_factory):
        rule = rule_factory()
        with pytest.raises(ValidationError) as e:
            del rule['attribute']
            schemas.Rule(**rule)
        validation_errors = json.loads(e.value.json())
        assert len(validation_errors) == 1
        assert 'attribute' in validation_errors[0]['loc']


class TestSignature:
    def test_valid_payload(self, database_session, signature_factory):
        signature = signature_factory(responses__batch_size=2)
        payload = signature.to_dict()
        payload['responses'] = [r.id for r in signature.responses]
        signature_schema = schemas.Signature(**payload)
        assert signature_schema.dict()['max_score'] == 2

    def test_invalid_payload(self, database_session, signature_factory):
        signature = signature_factory()
        with pytest.raises(ValidationError) as e:
            schemas.Signature(**signature.to_dict())
        validation_errors = json.loads(e.value.json())
        assert len(validation_errors) == 1
        assert 'responses' in validation_errors[0]['loc']
