import json
from unittest.mock import patch, mock_open

from plugins.tcp.http.models import prepare_database, Response, Signature


def test_request_log_printing(request_log_factory):
    request_log = request_log_factory.build()
    assert str(request_log) == str(request_log.id)


def test_response_printing(response_factory):
    response = response_factory.build()
    assert str(response) == str(response.id)


def test_signature_printing(signature_factory):
    signature = signature_factory.build()
    assert str(signature) == str(signature.id)


def test_signature_response_printing(signature_response_factory):
    signature_response = signature_response_factory.build()
    assert str(signature_response) == f'{repr(signature_response.signature)} : {repr(signature_response.response)}'


def test_database_hydration(database_session):
    responses = [
        {
            "id": 1,
            "headers": {
              "Date": "%%date%%",
              "Server": "Apache",
              "Link": "<http://10.5.1.224/index.php?rest_route=/>; rel=\"https://api.w.org/\"",
              "Keep-Alive": "timeout=5, max=100",
              "Connection": "Keep-Alive",
              "Content-Type": "text/html; charset=UTF-8"
            },
            "comment": "HEAD request response",
            "status_code": 200,
            "body": ""
        },
        {
            "headers": {
              "Date": "%%date%%",
              "Server": "Apache",
              "Link": "<http://10.5.1.224/index.php?rest_route=/>; rel=\"https://api.w.org/\"",
              "Keep-Alive": "timeout=5, max=100",
              "Connection": "Keep-Alive",
              "Content-Type": "text/html; charset=UTF-8"
            },
            "comment": "HEAD request resposne",
            "status_code": 200,
            "body": ""
        }
    ]
    signatures = [
        {
            "id": 2,
            "responses": [
              1
            ],
            "rules": [
              {
                "condition": "equals",
                "attribute": "headers",
                "value": "user-agent:PostmanRuntime/7.29.0",
                "score": 2
              },
              {
                "condition": "equals",
                "attribute": "method",
                "value": "GET",
                "score": 2
              }
            ]
        },
        {
            "responses": [
              1
            ],
            "rules": [
              {
                "condition": "equals",
                "attribute": "headers",
                "value": "user-agent:PostmanRuntime/7.29.0",
                "score": 2
              },
              {
                "condition": "equals",
                "attribute": "method",
                "value": "GET",
                "score": 2
              }
            ]
        }
    ]
    mock_responses_file = mock_open(read_data=json.dumps(responses))
    mock_signatures_file = mock_open(read_data=json.dumps(signatures))
    mock_file = mock_open()
    mock_file.side_effect = [mock_responses_file.return_value, mock_signatures_file.return_value]

    with patch('builtins.open', mock_file):
        prepare_database()
    assert database_session.query(Response).count() == 1
    assert database_session.query(Signature).count() == 1
