import ast
import datetime
import logging
import json
import os
import sys

import requests
from pydantic import ValidationError
from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.dialects.sqlite import JSON
from sqlalchemy.orm import relationship

import settings
from plugins.tcp.http import schemas
from utils import BaseModel

logger = logging.getLogger(__name__)
logs = []


class RequestLog(BaseModel):
    """
    Request Log class (for web logs
    """
    __tablename__ = 'request_log'

    id = Column(Integer, primary_key=True)
    time = Column(DateTime, default=datetime.datetime.now())
    client_ip = Column(Text)
    data = Column(JSON)
    headers = Column(Text)
    method = Column(Text)
    path = Column(Text)
    target_ip = Column(Text)
    version = Column(Text)
    response_id = Column(Integer, ForeignKey('response.id'))
    signature_id = Column(Integer, ForeignKey('signature.id'))

    response = relationship('Response', back_populates='request_logs')
    signature = relationship('Signature', back_populates='request_logs')

    def __str__(self):
        """
        represent log as a string
        """
        return str(self.id)

    def format_log_for_submission(self):
        """
        format logs in the json format needed to submit them
        """
        headers = json.loads(self.headers.replace("'", '"'))
        return {
            "time": self.time.timestamp(),
            "headers": headers,
            "sip": self.client_ip,
            "dip": self.target_ip,
            "method": self.method,
            "url": self.path,
            "useragent": headers.get("user-agent")
        }


class Response(BaseModel):
    """
    pre-defined responses sent back to clients
    """
    __tablename__ = 'response'

    id = Column(Integer, primary_key=True)
    comment = Column(String)
    body = Column(Text)
    headers = Column(JSON)
    status_code = Column(Integer)

    request_logs = relationship('RequestLog', back_populates='response')
    signatures = relationship('Signature', back_populates='responses',
                              secondary='signature_response')
    signature_responses = relationship('SignatureResponse',
                                       back_populates='response', viewonly=True)

    def __str__(self):
        """
        represent response as a string by returning the ID
        """
        return str(self.id)


class Signature(BaseModel):
    """
    Signatures matching requests to responses
    """
    __tablename__ = 'signature'

    id = Column(Integer, primary_key=True)
    max_score = Column(Integer, nullable=False)
    rules = Column(JSON, nullable=False)

    responses = relationship('Response', back_populates='signatures',
                             secondary='signature_response')
    request_logs = relationship('RequestLog', back_populates='signature')
    signature_responses = relationship('SignatureResponse',
                                       back_populates='signature', viewonly=True)

    def __str__(self):
        """
        represent as a string by returning id
        """
        return str(self.id)


class SignatureResponse(BaseModel):
    """
    response to send back
    """
    __tablename__ = 'signature_response'

    response_id = Column(Integer, ForeignKey('response.id'), primary_key=True)
    signature_id = Column(Integer, ForeignKey('signature.id'), primary_key=True)

    response = relationship('Response', back_populates='signature_responses', viewonly=True)
    signature = relationship('Signature', back_populates='signature_responses', viewonly=True)

    def __str__(self):
        """
        string is signature and response
        """
        return f'{repr(self.signature)} : {repr(self.response)}'


def create_tables():
    """
    create database tables
    """
    settings.DATABASE_MAPPER_REGISTRY.metadata.create_all(settings.DATABASE_ENGINE)


def hydrate_tables():
    """
    potentially insert data into the tables we just created
    """
    # Empty tables
    settings.DATABASE_SESSION.query(RequestLog).delete()
    settings.DATABASE_SESSION.query(SignatureResponse).delete()
    settings.DATABASE_SESSION.query(Signature).delete()
    settings.DATABASE_SESSION.query(Response).delete()

    resp = requests.get(
        f'{settings.DSHIELD_URL}/api/honeypotrules/',
        verify=True
    )

    if not resp.ok:
        logger.exception("HTTP plugin failed to download artifacts.")
        return

    # Hydrate
    responses = []
    for response in resp.json()["responses"]:
        try:
            response_schema = schemas.Response(**response)
        except ValidationError as err:
            logger.warning('Response failed: %s', response)
            logger.warning(err, exc_info=True)
            continue
        responses.append(Response(**response_schema.dict()))
    settings.DATABASE_SESSION.add_all(responses)

    signatures = []
    for signature in resp.json()["signatures"]:
        try:
            signature_schema = schemas.Signature(**signature)
        except ValidationError as err:
            logger.warning('Signature failed: %s', signature)
            logger.warning(err, exc_info=True)
            continue
        signature_schema_dict = signature_schema.dict()
        response_ids = signature_schema_dict.pop('responses')
        associated_responses = settings.DATABASE_SESSION.query(Response).filter(
            Response.id.in_(response_ids))
        signature_schema_dict['responses'] = list(associated_responses)
        signatures.append(Signature(**signature_schema_dict))
    settings.DATABASE_SESSION.add_all(signatures)
    settings.DATABASE_SESSION.flush()


def prepare_database():
    create_tables()
    hydrate_tables()

def read_db_and_log(file_name=""):
    if file_name == '':
        todaydate = datetime.datetime.today().strftime('%Y-%m-%d')
        file_name = f"/srv/db/webhoneypot-{todaydate}.json";
    logs = []
    for instance in settings.DATABASE_SESSION.query(RequestLog).order_by(RequestLog.id):
        signature = settings.DATABASE_SESSION.query(Signature).filter(Signature.id == instance.signature_id).first()
        signature_rules = {"max_score": signature.max_score, "rules": signature.rules} if signature else None

        resp = settings.DATABASE_SESSION.query(Response).filter(Response.id == instance.response_id).first()
        resp_details = {"comment": resp.comment, "headers": resp.headers, "status_code": resp.status_code} if resp else None

        try:
            useragent = ast.literal_eval(instance.headers)['user-agent'],
        except KeyError:
            useragent = ''
        log_data = {
            'time': datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S.%f"),
            'headers': ast.literal_eval(instance.headers),
            'sip': instance.client_ip,
            'dip': instance.target_ip,
            'method': instance.method,
            'url': instance.path,
            'data': instance.data,
            'useragent': useragent,
            'version': (instance.version).decode("utf-8"),
            'response_id': resp_details,
            'signature_id': signature_rules
        }
        with open(file_name, "a") as file:
            json.dump(log_data, file)
    return logs
