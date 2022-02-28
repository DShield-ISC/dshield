import logging
import json
import os

from pydantic import ValidationError
from sqlalchemy import Column, ForeignKey, Integer, String, Text
from sqlalchemy.dialects.sqlite import JSON
from sqlalchemy.orm import registry

import settings
from plugins.tcp.http import schemas


logger = logging.getLogger(__name__)
mapper_registry = registry()
Base = mapper_registry.generate_base()
logs = []


class RequestLog(Base):
    __tablename__ = 'request_log'

    id = Column(Integer, primary_key=True)
    client_ip = Column(Text)
    data = Column(JSON)
    headers = Column(Text)
    method = Column(Text)
    path = Column(Text)
    target_ip = Column(Text)
    version = Column(Text)
    response_id = Column(Integer, ForeignKey('response.id'))
    signature_id = Column(Integer, ForeignKey('signature.id'))

    def __repr__(self):
        return f'{self.__class__.__name__}({self.id})'

    def __str__(self):
        return str(self.id)


class Response(Base):
    __tablename__ = 'response'

    id = Column(Integer, primary_key=True)
    comment = Column(String)
    body = Column(Text)
    headers = Column(JSON)
    status_code = Column(Integer)

    def __repr__(self):
        return f'{self.__class__.__name__}({self})'

    def __str__(self):
        return str(self.id)


class Signature(Base):
    __tablename__ = 'signature'

    id = Column(Integer, primary_key=True)
    max_score = Column(Integer, nullable=False)
    responses = Column(JSON, nullable=False)
    rules = Column(JSON, nullable=False)

    def __repr__(self):
        return f"{self.__class__.__name__}({self})"

    def __str__(self):
        return str(self.id)


def prepare_database():
    # Establish connectivity with SQLAlchemy engine
    mapper_registry.metadata.create_all(settings.DATABASE_ENGINE)
    settings.DATABASE_SESSION.query(Signature).delete()
    settings.DATABASE_SESSION.query(Response).delete()

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
        settings.DATABASE_SESSION.commit()

    with open(os.path.join(os.path.dirname(__file__), 'artifacts/signatures.json'), 'rb') as fp:
        signatures = []
        for signature in json.load(fp):
            try:
                signature_schema = schemas.Signature(**signature)
            except ValidationError as e:
                logger.warning('Signature failed: %s', signature)
                logger.warning(e, exc_info=True)
                continue
            signatures.append(Signature(**signature_schema.dict()))
        settings.DATABASE_SESSION.add_all(signatures)
        settings.DATABASE_SESSION.commit()


def read_db_and_send_to_dshield():
    for instance in settings.DATABASE_SESSION.query(RequestLog).order_by(RequestLog.id):
        logdata = {}
        logdata['client_ip'] = instance.client_ip
        logdata['data'] = instance.data
        logdata['headers'] = instance.headers
        logdata['method'] = instance.method
        logdata['path'] = instance.path
        logdata['response_id'] = instance.response_id
        logdata['signature_id'] = instance.signature_id
        logdata['target_ip'] = instance.target_ip
        logdata['version'] = instance.version
        logs.append(logdata)
        logger.warning('READ DB AND SEND TO DSHIELD')
        logger.warning('ID: %s \n  Client IP: %s \n Headers: %s', instance.id, instance.client_ip, instance.headers)
    logger.warning('Print Logs')
    logger.warning(logs)

    return logs

