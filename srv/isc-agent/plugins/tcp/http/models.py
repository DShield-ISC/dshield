import ast
import datetime
import logging
import json
import os

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
        return str(self.id)


class Response(BaseModel):
    __tablename__ = 'response'

    id = Column(Integer, primary_key=True)
    comment = Column(String)
    body = Column(Text)
    headers = Column(JSON)
    status_code = Column(Integer)

    request_logs = relationship('RequestLog', back_populates='response')
    signatures = relationship('Signature', back_populates='responses', secondary='signature_response')
    signature_responses = relationship('SignatureResponse', back_populates='response', viewonly=True)

    def __str__(self):
        return str(self.id)


class Signature(BaseModel):
    __tablename__ = 'signature'

    id = Column(Integer, primary_key=True)
    max_score = Column(Integer, nullable=False)
    rules = Column(JSON, nullable=False)

    responses = relationship('Response', back_populates='signatures', secondary='signature_response')
    request_logs = relationship('RequestLog', back_populates='signature')
    signature_responses = relationship('SignatureResponse', back_populates='signature', viewonly=True)

    def __str__(self):
        return str(self.id)


class SignatureResponse(BaseModel):
    __tablename__ = 'signature_response'

    response_id = Column(Integer, ForeignKey('response.id'), primary_key=True)
    signature_id = Column(Integer, ForeignKey('signature.id'), primary_key=True)

    response = relationship('Response', back_populates='signature_responses', viewonly=True)
    signature = relationship('Signature', back_populates='signature_responses', viewonly=True)

    def __str__(self):
        return f'{repr(self.signature)} : {repr(self.response)}'


def create_tables():
    settings.DATABASE_MAPPER_REGISTRY.metadata.create_all(settings.DATABASE_ENGINE)


def prepare_database():
    create_tables()

    # Hydrate tables
    with open(os.path.join(os.path.dirname(__file__), 'artifacts/responses.json'), 'rb') as fp:
        responses = []
        for response in json.load(fp):
            try:
                response_schema = schemas.Response(**response)
            except ValidationError as e:
                logger.warning('Response failed: %s', response)
                logger.warning(e, exc_info=True)
                continue
            responses.append(Response(**response_schema.dict()))
        settings.DATABASE_SESSION.add_all(responses)

    with open(os.path.join(os.path.dirname(__file__), 'artifacts/signatures.json'), 'rb') as fp:
        signatures = []
        for signature in json.load(fp):
            try:
                signature_schema = schemas.Signature(**signature)
            except ValidationError as e:
                logger.warning('Signature failed: %s', signature)
                logger.warning(e, exc_info=True)
                continue
            signature_schema_dict = signature_schema.dict()
            response_ids = signature_schema_dict.pop('responses')
            associated_responses = settings.DATABASE_SESSION.query(Response).filter(Response.id.in_(response_ids))
            signature_schema_dict['responses'] = list(associated_responses)
            signatures.append(Signature(**signature_schema_dict))
        settings.DATABASE_SESSION.add_all(signatures)
    settings.DATABASE_SESSION.flush()


def read_db_and_log():
    for instance in settings.DATABASE_SESSION.query(RequestLog).order_by(RequestLog.id):
        log_data = {
            'time': instance.time,
            'headers': ast.literal_eval(instance.headers),
            'sip': instance.client_ip,
            'dip': instance.target_ip,
            'method': instance.method,
            'url': instance.path,
            'data': instance.data,
            'useragent': ast.literal_eval(instance.headers)['user-agent'],
        }
        logs.append(log_data)
    return logs
