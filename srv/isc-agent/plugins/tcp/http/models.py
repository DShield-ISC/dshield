import logging
import json
import os

from sqlalchemy import Column, ForeignKey, Integer, JSON, Text
from sqlalchemy.orm import registry, relationship

import settings

logger = logging.getLogger(__name__)
mapper_registry = registry()

Base = mapper_registry.generate_base()


class RequestLog(Base):
    __tablename__ = 'request_log'

    id = Column(Integer, primary_key=True)
    headers = Column(Text)
    address = Column(Text)
    command = Column(Text)
    path = Column(Text)
    user_agent = Column(Text)
    version = Column(Text)
    data = Column(JSON)
    summary = Column(Text)
    target = Column(Text)
    response = relationship(
        'Response',
        order_by='Response.request_log_id',
        back_populates='request',
        cascade='all, delete, delete-orphan',
        uselist=False
    )

    def __repr__(self):
        return f"{self.__class__.__name__}({self.ID}: {self})"

    def __str__(self):
        return self.headers


class Response(Base):
    __tablename__ = 'response'

    request_log_id = Column(Integer, ForeignKey('request_log.id'), primary_key=True)
    header = Column(Text)
    data = Column(Text)
    request = relationship(
        'RequestLog',
        order_by='RequestLog.id',
        back_populates='response',
        cascade='all, delete, delete-orphan',
        single_parent=True,
        uselist=False
    )

    def __repr__(self):
        return f'''{self.__class__.__name__}({self.ID}: {self})'''

    def __str__(self):
        return self.header_field


class Signature(Base):
    __tablename__ = 'signature'

    id = Column(Integer, primary_key=True)
    pattern_description = Column(Text)
    pattern_string = Column(Text)
    headers = Column(JSON)
    responses = Column(JSON)
    module = Column(Text)

    def __repr__(self):
        return f"{self.__class__.__name__}({self.id}: {self})"

    def __str__(self):
        return self.pattern_string


def prepare_database():
    # Establish connectivity with SQLAlchemy engine
    mapper_registry.metadata.create_all(settings.DATABASE_ENGINE)

    # Hydrate tables
    with open(os.path.join(os.path.dirname(__file__), 'artifacts/signatures.json'), 'rb') as fp:
        signatures = []
        for signature in json.load(fp):
            signatures.append(Signature(**signature))
        settings.DATABASE_SESSION.add_all(signatures)
        settings.DATABASE_SESSION.commit()
