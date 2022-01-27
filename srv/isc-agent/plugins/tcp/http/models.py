from sqlalchemy import create_engine, MetaData, ForeignKey
from sqlalchemy import Table, Column, Integer, String, Text, BLOB
from sqlalchemy.orm import declarative_base, registry

mapper_registry = registry()

Base = mapper_registry.generate_base()


# Sigs model
class Sigs(Base):
    __tablename__ = 'sigs'

    id = Column(Integer, primary_key=True)
    # Should this be Text vs String?
    patternDescription = Column(Text)
    patternString = Column(Text)
    db_ref = Column(Text)
    module = Column(Text)

    def __repr__(self):
        return f'''Sigs(id={self.id!r}, patternDescription={self.patternDescription!r}, 
        patternString={self.patternString!r}, db_ref={self.db_ref!r}, module={self.module!r} )'''


class HdrResponses(Base):
    __tablename__ = 'hdr_responses'

    id = Column(Integer, primary_key=True)
    SigID = Column(Integer)
    HeaderField = Column(Text)
    dataField = Column(Text)

    def __repr__(self):
        return f'''HdrResponses(id={self.id!r}, SigID={self.SigID!r}, 
        HeaderField={self.HeaderField}, dataField={self.dataField!r})'''


class Paths(Base):
    __tablename__ = 'paths'

    SigID = Column(Integer, primary_key=True)
    path = Column(Text)
    OSPath = Column(Text)

    def __repr__(self):
        return f"Paths(SigID={self.SigID!r}, path={self.path!r}, OSPath={self.OSPath!r})"


class SQLResp(Base):
    __tablename__ = 'sql_resp'

    SigID = Column(Integer, primary_key=True)
    SQLInput = Column(Text)
    SQLOutput = Column(Text)

    def __repr__(self):
        return f"SQLResp(SigID={self.SigID!r}, SQLInput={self.SQLInput!r}, SQLOutput={self.SQLOutput!r})"


class XssResp(Base):
    __tablename__ = 'xss_resp'

    SigID = Column(Integer)
    ScriptReq = Column(Text, primary_key=True)
    ScriptResp = Column(Text)

    def __repr__(self):
        return f"XssResp(SigID={self.SigID!r}, ScriptReq={self.ScriptReq!r}, ScriptResp={self.ScriptResp!r})"


class RFIResp(Base):
    __tablename__ = 'rfi_resp'

    SigID = Column(Integer)
    protocol = Column(Text, primary_key=True)
    remoteuri = Column(Text)

    def __repr__(self):
        return f"RFIResp(SigID={self.SigID!r}, protocol={self.protocol!r}, remoteuri={self.remoteuri!r})"


class FileResp(Base):
    __tablename__ = 'file_resp'

    ID = Column(Integer, primary_key=True)
    SigID = Column(Integer)
    FileNamePost = Column(Text)
    FileDataPost = Column(BLOB)
    FileTextPost = Column(Text)
    OSPath = Column(Text)
    FileResp = Column(BLOB)
    CowrieRef = Column(Text)

    def __repr__(self):
        return f'''FileResp(ID={self.ID!r}, SigID={self.SigID!r}, FileNamePost={self.FileNamePost!r},
        FileDataPost={self.FileDataPost!r}, FileTextPost={self.FileTextPost!r}, OSPath={self.OSPath!r},
        FileResp={self.FileResp!r}, CowrieRef={self.CowrieRef!r})'''


class Postlogs(Base):
    __tablename__ = 'post_logs'

    ID = Column(Integer, primary_key=True)
    data = Column(Text)
    headers = Column(Text)
    address = Column(Text)
    cmd = Column(Text)
    path = Column(Text)
    useragent = Column(Text)
    vers = Column(Text)
    formkey = Column(Text)
    formvalue = Column(Text)
    summary = Column(Text)

    def __repr__(self):
        return f'''Postlogs(ID={self.ID!r}, data={self.data!r}, headers={self.headers!r}, address={self.address!r}
        cmd={self.cmd!r}, path={self.path!r}, useragent={self.useragent!r}, vers={self.vers!r}, 
        formkey={self.formkey!r}, fomrvalue={self.formvalue!r}, summary={self.summary!r})'''


class Files(Base):
    __tablename__ = 'files'

    ID = Column(Integer, primary_key=True)
    RID = Column(Integer)
    filename = Column(Text)
    DATA = Column(BLOB)

    def __repr__(self):
        return f"Files(ID={self.ID!r}, RID={self.RID!r}, filename={self.filename!r}, DATA={self.DATA!r})"


class Requests(Base):
    __tablename__ = 'requests'

    data = Column(Text, primary_key=True)
    headers = Column(Text)
    address = Column(Text)
    cmd = Column(Text)
    path = Column(Text)
    useragent = Column(Text)
    vers = Column(Text)
    summery = Column(Text)
    target = Column(Text)

    def __repr__(self):
        return f'''Requests(data={self.data!r}, headers={self.headers!r}, address={self.address!r}, 
        cmd={self.cmd!r}, path={self.path!r}, useragent={self.useragent!r}, vers={self.vers!r},
        summary={self.summery!r}, target={self.target!r})'''


class Useragents(Base):
    __tablename__ = 'user_agents'

    ID = Column(Integer, primary_key=True)
    refid = Column(Integer)
    useragent = Column(Text, unique=True)

    def __repr__(self):
        return f"Useragents(ID={self.ID!r}, refid={self.refid!r}, useragent={self.useragent!r})"


class Responses(Base):
    __tablename__ = 'responses'

    ID = Column(Integer, primary_key=True)
    RID = Column(Integer)
    HeaderField = Column(Text)
    dataField = Column(Text)

    def __repr__(self):
        return f'''Responses(ID={self.ID!r}, RID={self.RID!r}, 
        HeaderField={self.HeaderField!r}, dataField={self.dataField!r})'''


def build_models():
    # create temporary engine in memory
    # Establish connectivity with SQLalchemy engine
    engine = create_engine("sqlite+pysqlite:///:memory:", echo=True, future=True)

    # Front facing interface around python dictonary that stores table objects
    metadata_obj = MetaData()

    mapper_registry.metadata.create_all(engine)


if __name__ == "__main__":
    build_models()


