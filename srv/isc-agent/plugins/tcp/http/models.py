from sqlalchemy import create_engine
from sqlalchemy import Column, Integer, Text, BLOB, JSON
from sqlalchemy.orm import registry

mapper_registry = registry()

Base = mapper_registry.generate_base()


class Signature(Base):
    __tablename__ = 'signature'

    id = Column(Integer, primary_key=True)
    # Should this be Text vs String?
    pattern_description = Column(Text)
    pattern_string = Column(Text)
    db_ref = Column(Text)
    module = Column(Text)

    def __repr__(self):
        return f"{self.__class__.__name__}({self.id}: {self})"

    def __str__(self):
        return self.pattern_string


class HeaderResponse(Base):
    __tablename__ = 'header_responses'

    id = Column(Integer, primary_key=True)
    sig_id = Column(Integer)
    header_field = Column(Text)
    data_field = Column(Text)

    def __repr__(self):
        return f"{self.__class__.__name__}({self.id}:{self})"

    def __str__(self):
        return self.header_field


class SQLResponse(Base):
    __tablename__ = 'sql_response'

    id = Column(Integer, primary_key=True)
    #we want to use a foreign key reference
    signature_id = Column(Integer, primary_key=True)
    sql_input = Column(Text)
    sql_output = Column(Text)

    def __repr__(self):
        return f"{self.__class__.__name__}({self.SigID}: {self})"

    def __str__(self):
        return self.sql_output


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
    metadata = Column(JSON)
    summary = Column(Text)
    target = Column(Text)

    def __repr__(self):
        return f"{self.__class__.__name__}({self.ID}: {self})"

    def __str__(self):
        return self.headers


class Response(Base):
    __tablename__ = 'response'

    id = Column(Integer, primary_key=True)
    #Will need to be foreign key connecting to request_log_id
    request_id = Column(Integer)
    header_field = Column(Text)
    data_field = Column(Text)

    def __repr__(self):
        return f'''{self.__class__.__name__}({self.ID}: {self})'''

    def __str__(self):
        return self.header_field


def build_models():
    # create temporary engine in memory
    # Establish connectivity with SQLalchemy engine
    engine = create_engine("sqlite+pysqlite:///:memory:", echo=True, future=True)

    mapper_registry.metadata.create_all(engine)
    return engine


if __name__ == "__main__":
    build_models()
