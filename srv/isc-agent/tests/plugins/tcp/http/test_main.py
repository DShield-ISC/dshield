from unittest.mock import patch

from twisted.internet.defer import succeed, inlineCallbacks
from twisted.web import server
from twisted.web.http import Request
from twisted.web.test.test_web import DummyRequest
from twisted.trial import unittest

from plugins.tcp.http.main import HTTP, get_winning_signature


class EnhancedDummyRequest(DummyRequest, Request):
    def __init__(self, *args, **kwargs):
        self.received_cookies = kwargs.pop('received_cookies', {})
        super().__init__(*args, **kwargs)
        self.path = self.postpath


class TestHTTP:
    http = HTTP()

    def test_successful_render(self, signature_factory):
        signature_factory(
            responses__batch_size=1,
            rules=[
                {
                    'attribute': 'method',
                    'value': 'POST',
                    'required': True,
                    'condition': 'contains',
                    'score': 1
                }
            ]
        )
        request = EnhancedDummyRequest(b'/')
        request.method = b'POST'
        self.http.render(request)
        assert request.responseCode == 200

    def test_when_no_signature_matches(self):
        request = EnhancedDummyRequest(b'/')
        self.http.render(request)
        assert request.responseCode == 400

    def test_failing_required_rule_excludes_signature(self, signature_factory):
        signature_factory(
            responses__batch_size=1,
            rules=[
                {
                    'attribute': 'method',
                    'value': 'POST',
                    'required': True,
                    'condition': 'contains',
                    'score': 100
                },
                {
                    'attribute': 'user',
                    'value': 'somebody',
                    'required': False,
                    'condition': 'contains',
                    'score': 1
                },
                {
                    'attribute': 'path',
                    'value': 'something',
                    'required': True,
                    'condition': 'contains',
                    'score': 1
                }
            ]
        )
        body = 'I should win'
        signature_factory(
            responses__batch_size=1,
            responses__body=body,
            rules=[
                {
                    'attribute': 'method',
                    'value': 'POST',
                    'required': True,
                    'condition': 'contains',
                    'score': 1
                }
            ]
        )
        request = EnhancedDummyRequest(b'/')
        request.method = b'POST'
        self.http.render(request)
        assert request.responseCode == 200
        assert request.written[0].decode() == body

    @patch('plugins.tcp.http.main.get_signature_score')
    def test_loop_breaks_when_top_score_found(self, get_signature_score_mock, signature_factory):
        signature_factory.create_batch(size=4, max_score=50)
        get_signature_score_mock.side_effect = [10, 9, 51, 5]
        get_winning_signature({})
        assert get_signature_score_mock.call_count == 3

    def test_invalid_attribute_in_rule(self, signature_factory):
        signature_factory(
            responses__batch_size=1,
            rules=[
                {
                    'attribute': 'body',
                    'value': 'post',
                    'required': True,
                    'condition': 'contains',
                    'score': 1
                }
            ]
        )
        request = EnhancedDummyRequest(b'/')
        request.method = b'POST'
        self.http.render(request)
        assert request.responseCode == 400

    def test_invalid_condition_in_rule(self, signature_factory):
        signature_factory(
            responses__batch_size=1,
            rules=[
                {
                    'attribute': 'method',
                    'value': 'POST',
                    'required': True,
                    'condition': 'closetoit',
                    'score': 1
                }
            ]
        )
        request = EnhancedDummyRequest(b'/')
        request.method = b'POST'
        self.http.render(request)
        assert request.responseCode == 400

    def test_nested_rule_values(self, signature_factory):
        signature_factory(
            responses__batch_size=1,
            rules=[
                {
                    'attribute': 'cookies',
                    'value': 'Server:Apache',
                    'required': False,
                    'condition': 'equals',
                    'score': 1
                }
            ]
        )
        request = EnhancedDummyRequest(b'/', received_cookies={b'Server': b'Apache'})
        request.method = b'POST'
        self.http.render(request)
        assert request.responseCode == 200