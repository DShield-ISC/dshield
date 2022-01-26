from sqlalchemy import create_engine, MetaData, ForeignKey
from sqlalchemy import Table, Column, Integer, String, Text
from sqlalchemy.orm import declarative_base


def build_Models():
    # create temporary engine in memory
    # Establish connectivity with SQLalchemy engine
    engine = create_engine("sqlite+pysqlite:///:memory:", echo=True, future=True)

    # Front facing interface around python dictonary that stores table objects
    metadata_obj = MetaData()

    Base = declarative_base()
    # Sigs model
    class Sigs(Base):
        __tablename__ = 'Sigs'

        id = Column(Integer, primary_key=True)
        #Should this be Text vs String?
        patternDescription = Column(Text)
        patternString = Column(Text)
        db_ref = Column(Text)
        module = Column(Text)

        def __repr__(self):
            return f'''Sigs(id={self.id!r}, patternDescription={self.patternDescription!r}, 
            patternString={self.patternString!r}, db_ref={self.db_ref!r}, module={self.module!r} )'''

    class HdrResponses(Base):
        __tablename__ = 'HdrResponses'

        id = Column(Integer)
        SigID = Column(Integer)
        HeaderField = Column(Text)
        dataField = Column(Text)

        def __repr__(self):
            return f'''HdrResponses(id={self.id!r}, SigID={self.SigID!r}, 
            HeaderField={self.HeaderField}, dataField={self.dataField!r}'''

    class paths(Base):
        __tablename__ = 'paths'

        SigID = Column(Integer)
        SQLInput = Column(Text)
        SQLOutput = Column(Text)

        def __repr__(self):
            return f"paths(SigID={self.SigID!r}, SQLInput={self.SQLInput!r}, SQLOutput={self.SQLOutput!r}"



