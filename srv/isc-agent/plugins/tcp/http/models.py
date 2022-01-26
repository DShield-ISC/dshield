from sqlalchemy import create_engine, MetaData, ForeignKey
from sqlalchemy import Table, Column, Integer, String
from sqlalchemy.orm import declarative_base


def build_Models():
    # create temporary engine in memory
    # Establish connectivity with SQLalchemy engine
    engine = create_engine("sqlite+pysqlite:///:memory:", echo=True, future=True)

    # Front facing interface around python dictonary that stores table objects
    metadata_obj = MetaData()

    Base = declarative_base()

    class Sigs(Base):
        __tablename__ = 'Sigs'

        id = Column(Integer, primary_key=True)


