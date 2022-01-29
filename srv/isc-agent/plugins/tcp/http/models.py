from sqlalchemy import create_engine, Column, Integer, Text, JSON, ForeignKey
from sqlalchemy.orm import registry

mapper_registry = registry()

Base = mapper_registry.generate_base()


class HeaderResponse(Base):
    __tablename__ = 'header_response'

    id = Column(Integer, primary_key=True)
    signature_id = Column(Integer)
    header = Column(Text)
    data = Column(Text)

    def __repr__(self):
        return f"{self.__class__.__name__}({self.id}: {self})"

    def __str__(self):
        return self.header_field


class RequestLog(Base):
    __tablename__ = 'request_log'

    id = Column(Integer, primary_key=True)
    data = Column(Text)
    headers = Column(Text)
    address = Column(Text)
    command = Column(Text)
    path = Column(Text)
    user_agent = Column(Text)
    version = Column(Text)
    data = Column(JSON)
    summary = Column(Text)
    target = Column(Text)

    def __repr__(self):
        return f"{self.__class__.__name__}({self.ID}: {self})"

    def __str__(self):
        return self.headers


class Response(Base):
    __tablename__ = 'response'

    id = Column(Integer, primary_key=True)
    request_id = Column(Integer, ForeignKey('request_log.id'))
    header = Column(Text)
    data = Column(Text)

    def __repr__(self):
        return f'''{self.__class__.__name__}({self.ID}: {self})'''

    def __str__(self):
        return self.header_field


class Signature(Base):
    __tablename__ = 'signature'

    id = Column(Integer, primary_key=True)
    pattern_description = Column(Text)
    pattern_string = Column(Text)
    db_ref = Column(Text)
    module = Column(Text)

    def __repr__(self):
        return f"{self.__class__.__name__}({self.id}: {self})"

    def __str__(self):
        return self.pattern_string


class SQLResponse(Base):
    __tablename__ = 'sql_response'

    id = Column(Integer, primary_key=True)
    signature_id = Column(Integer, ForeignKey('signature.id'))
    sql_input = Column(Text)
    sql_output = Column(Text)

    def __repr__(self):
        return f"{self.__class__.__name__}({self.SigID}: {self})"

    def __str__(self):
        return self.sql_output





def build_models():
    # create temporary engine in memory
    # Establish connectivity with SQLalchemy engine
    engine = create_engine("sqlite+pysqlite:///:memory:", echo=True, future=True)

    mapper_registry.metadata.create_all(engine)
    return engine


if __name__ == "__main__":
    build_models()
