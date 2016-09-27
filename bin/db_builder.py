#!/usr/bin/evn python
# not linked to schema for web.py at this time - future schema builder

from xml.etree import ElementTree
import os
import sqlite3

requests = '..' + os.path.sep + "signatures.xml"
config = '..' + os.path.sep + 'DB' + os.path.sep + 'webserver-DEV.sqlite'

def build_DB():
    # This is not necessary by connecting to the db it creates the file.
    #db_is_new = not os.path.exists(config)
    #if db_is_new:
    #        print 'configuration database is not initialized'
    #        sys.exit(0)

    # check if log directory exists

    #if not os.path.isdir(logdir):
    #        print 'log directory does not exist. '+logdir
    #        sys.exit(0)

    # each time we start, we start a new log file by appending to timestamp to access.log
    #logfile = logdir+os.path.sep+'access.log.'+str(time.time())
    # not using above using dB for logging now.

    conn = sqlite3.connect(config)
    c = conn.cursor()

    #Creates table for signatures will reference responses table below - imports xml from glastopf
    # https://github.com/mushorg/glastopf/blob/master/glastopf/requests.xml
    c.execute('''CREATE TABLE IF NOT EXISTS Sigs
                (
                    ID integer primary key,
                    patternDescription text,
                    patternString text,
                    module text
                )
            ''')

    #Create's main table to reference all tables based on signatures.
    c.execute('''CREATE TABLE IF NOT EXISTS responses
                (
                    ID integer primary key,
                    SigID integer,
                    HdrID integer,
                    PageID integer,
                    SQLID integer,
                    XSS integer,
                    FileInject integer
                )
            ''')



    #Creates table for responses based on useragents.RefID will be IndexID
    c.execute('''CREATE TABLE IF NOT EXISTS HdrResponses
                (
                    ID integer,
                    HeaderField text ,
                    dataField text primary key
                )
            ''')

    #Creates table for response pages, don't actually want to serve up pages based on www
    # hopefully all these requests don't get jacked with sql injection
    c.execute('''CREATE TABLE IF NOT EXISTS paths
        (
            ID integer,
            path text primary key,
            OSPath text
        )
    ''')

    # hopefully all these requests don't get jacked with sql injection
    c.execute('''CREATE TABLE IF NOT EXISTS SQLResp
        (
            ID integer,
            SQLInput text primary key,
            SQLOutput text
        )
    ''')

    # Create table to respond to SQL Injection
    c.execute('''CREATE TABLE IF NOT EXISTS SQLResp
        (
            ID integer,
            SQLInput text primary key,
            SQLOutput text
        )
    ''')

    # Create table to respond to XSS
    c.execute('''CREATE TABLE IF NOT EXISTS XSSResp
        (
            ID integer,
            ScriptReq text primary key,
            ScriptResp text,
            JSResp blob
        )
    ''')
    # Create table to respond to file inclusion attack (metasploit and what not) - lofty but would be cool
    c.execute('''CREATE TABLE IF NOT EXISTS FileResp
        (
            ID integer,
            FileNamePost text,
            FileDataPost blob,
            FileTextPost text,
            OSPath text,
            FileResp blob,
            CowrieRef text
        )
    ''')

    #post logging database
    c.execute('''CREATE TABLE IF NOT EXISTS postslogs
                (
                    ID integer primary key,
                    date text,
                    address text,
                    cmd text,
                    path text,
                    useragent text,
                    vers text,
                    formkey text,
                    formvalue text
                )
            ''')
    c.execute('''CREATE TABLE IF NOT EXISTS logfilesuploaded
                (
                    ID integer primary key,
                    RID integer,
                    filename text,
                    DATA blob
                )
            ''')

    # Create some standard header data for vulnerable servers
    try:
        server_headers = [
            ("1", "Server", "Apache/2.0.1"),
            ("1", "Content-Type", "text/html"),
            ("1", "Connection", "keep-alive")
        ]
        c.executemany("""INSERT INTO HdrResponses VALUES (?,?,?)""", server_headers)
    except sqlite3.IntegrityError:
        pass
    finally:
        conn.commit()
    #ok let's load up the sigs
    try:
        with open(requests, 'rt') as f:
            tree = ElementTree.parse(f)
        Signature = ()
        id = 'null'
        desc = 'null'
        str = 'null'
        mod = 'null'
        for node in tree.iter():
            if node.tag == 'id':
                id = node.text
            if node.tag == 'patternDescription':
                desc = node.text
            if node.tag == 'patternString':
                str = node.text
            if node.tag == 'module':
                mod = node.text
            if id != 'null' and desc != 'null' and str != 'null' and mod != 'null':
                try:
                    Signature = [
                        (id,desc,str,mod)
                    ]
                    print node.tag, node.text
                    c.executemany("""INSERT INTO Sigs VALUES (?,?,?,?)""", Signature)
                    id = 'null'
                    desc = 'null'
                    str = 'null'
                    mod = 'null'
                except sqlite3.IntegrityError:
                    pass
                finally:
                    conn.commit()
    except sqlite3.IntegrityError:
        pass
    finally:
        conn.commit()

    #close out the DB
    conn.close()

try:
    #Create a web server and define the handler to manage the
    #incoming request
    build_DB()

except KeyboardInterrupt:
    print '^C received, shutting down the web server'
    #conn.close()