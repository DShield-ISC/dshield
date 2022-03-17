from unittest.mock import patch, call, MagicMock

from twisted.internet import reactor
from twisted.web.http import Request
from twisted.web.test.test_web import DummyRequest

from plugins.tcp.http.main import HTTP, get_winning_signature, handler


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


class TestHandler:
    @patch('plugins.tcp.http.main.ssl')
    def test_handler_does_not_start_https_if_no_certs(self, ssl_mock):
        handler()
        assert not ssl_mock.DefaultOpenSSLContextFactory.called

    @patch('plugins.tcp.http.main.ssl')
    @patch('plugins.tcp.http.main.os')
    def test_handler_does_start_https_if_certs_found(self, os_mock, ssl_mock):
        os_mock.path.exists.return_value = True
        handler()
        assert ssl_mock.DefaultOpenSSLContextFactory.called

    @patch('plugins.tcp.http.main.endpoints')
    @patch('plugins.tcp.http.main.ssl')
    @patch('plugins.tcp.http.main.os')
    def test_ports_passed_are_respected(self, os_mock, ssl_mock, endpoints_mock):
        http_ports = [1, 2, 3]
        https_ports = [3, 4, 5]
        os_mock.path.exists.return_value = True
        ssl_context_mock = MagicMock()
        ssl_mock.DefaultOpenSSLContextFactory.return_value = ssl_context_mock
        handler(http_ports=http_ports, https_ports=https_ports)
        http_calls = [call(reactor, port) for port in http_ports]
        https_calls = [call(reactor, port, ssl_context_mock) for port in https_ports]
        endpoints_mock.TCP4ServerEndpoint.assert_has_calls(http_calls, any_order=True)
        endpoints_mock.SSL4ServerEndpoint.assert_has_calls(https_calls, any_order=True)
