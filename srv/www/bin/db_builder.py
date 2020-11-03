#!/usr/bin/env python
# linked to schema for web.py

import xml.etree.ElementTree as ElementTree
import os
import sqlite3

requests = '..' + os.path.sep + "/etc/signatures.xml"
config = '..' + os.path.sep + 'DB' + os.path.sep + 'webserver.sqlite'

# honeydb builder - can get database name - so be careful what you name it
honeydb = '..' + os.path.sep + 'DB' + os.path.sep + 'config.sqlite'

def build_DB():
    # type: () -> object
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
                    db_ref text,
                    module text
                )
            ''')
    #Create's main table to reference all tables based on signatures.
    #c.execute('''CREATE TABLE IF NOT EXISTS responses
    #            (
    #                ID integer primary key,
    #                SigID integer,
    #                HdrID integer,
    #                PageID integer,
    #                SQLID integer,
    #                XSS integer,
    #                FileInject integer,
    #                module text
    #            )
    #        ''')



    #Creates table for responses based on useragents.RefID will be IndexID
    c.execute('''CREATE TABLE IF NOT EXISTS HdrResponses
                (
                    ID integer,
                    SigID integer,
                    HeaderField text,
                    dataField text
                )
            ''')
    #Creates table for response pages, don't actually want to serve up pages based on www
    # hopefully all these requests don't get jacked with sql injection
    c.execute('''CREATE TABLE IF NOT EXISTS paths
        (
            SigID integer,
            path text,
            OSPath text
        )
    ''')
    # hopefully all these requests don't get jacked with sql injection
    c.execute('''CREATE TABLE IF NOT EXISTS SQLResp
        (
            SigID integer,
            SQLInput text,
            SQLOutput text
        )
    ''')
    # Create table to respond to XSS
    c.execute('''CREATE TABLE IF NOT EXISTS XSSResp
        (
            SigID integer,
            ScriptReq text primary key,
            ScriptResp text
        )
    ''')
    # Create table to respond to rfi
    c.execute('''CREATE TABLE IF NOT EXISTS RFIResp
        (
            SigID integer,
            protocol text primary key,
            remoteuri text
        )
    ''')
    # Create table to respond to file inclusion attack (metasploit and what not) - lofty but would be cool
    c.execute('''CREATE TABLE IF NOT EXISTS FileResp
        (
            ID integer,
            SigID integer,
            FileNamePost text,
            FileDataPost blob,
            FileTextPost text,
            OSPath text,
            FileResp blob,
            CowrieRef text
        )
    ''')
    #post logging database
    c.execute('''CREATE TABLE IF NOT EXISTS postlogs
                (
                    ID integer primary key,
                    date text,
                    headers text,
                    address text,
                    cmd text,
                    path text,
                    useragent text,
                    vers text,
                    formkey text,
                    formvalue text,
                    summary text
                )
            ''')
    #where the files go when someone uploads something
    c.execute('''CREATE TABLE IF NOT EXISTS files
                (
                    ID integer primary key,
                    RID integer,
                    filename text,
                    DATA blob
                )
            ''')
    # gotta log the request somewhere.
    c.execute('''CREATE TABLE IF NOT EXISTS requests
                (
                    date text,
                    headers text,
                    address text,
                    cmd text,
                    path text,
                    useragent text,
                    vers text,
                    summary text,
                    targetip text
                )
            ''')
    # Creates table for useragent unique values - refid will be response refid
    c.execute('''CREATE TABLE IF NOT EXISTS useragents
                (
                    ID integer primary key,
                    refid integer,
                    useragent text,
                    CONSTRAINT useragent_unique UNIQUE (useragent)
                )
            ''')
    # Creates table for responses based on useragents.refid will be IndexID
    c.execute('''CREATE TABLE IF NOT EXISTS responses
                (
                    ID integer primary key,
                    RID integer,
                    HeaderField text,
                    dataField text
                )
            ''')

    # Create some standard header data for vulnerable servers
    try:
        server_headers = [
            ("1","1", "Server", "Apache/2.0.1"),
            ("1","1", "Content-Type", "text/html"),
            ("1","1", "Connection", "keep-alive")
        ]
        c.executemany("""INSERT INTO HdrResponses VALUES (?,?,?,?)""", server_headers)
    except sqlite3.IntegrityError:
        pass
    finally:
        conn.commit()
    #ok let's load up the sigs
    try:
        with open(requests, 'rt') as f:
            tree = ElementTree.parse(f)
        signature = ()
        id = 'null'
        desc = 'null'
        str = 'null'
        db_ref = 'null'
        mod = 'null'
        sigid = 'null'
        table = 'null'
        ptrnrqst = 'null'
        rspnsetorqst = 'null'
        for node in tree.iter():
            if node.tag == 'id':
                id = node.text
            if node.tag == 'patternDescription':
                desc = node.text
            if node.tag == 'patternString':
                str = node.text
            if node.tag == 'db_ref':
                db_ref = node.text
            if node.tag == 'module':
                mod = node.text
            if node.tag == 'sigID':
                sigid = node.text
            if node.tag == 'table':
                table = node.text
            if node.tag == 'patternRequest':
                ptrnrqst = node.text
            if node.tag == 'responseToRequest':
                rspnsetorqst = node.text
            if sigid != 'null' and table != 'null' and ptrnrqst != 'null' and rspnsetorqst != 'null':
                try:
                    responses = [
                        (table, sigid, ptrnrqst, rspnsetorqst)
                    ]
                    c.execute("""INSERT INTO """ + table + """ VALUES (?,?,?)""", [sigid, ptrnrqst, rspnsetorqst])
                    table = 'null'
                    sigid = 'null'
                    ptrnrqst = 'null'
                    rspnsetorqst = 'null'
                    id = 'null'
                    desc = 'null'
                    str = 'null'
                    db_ref = 'null'
                    mod = 'null'
                except sqlite3.IntegrityError:
                    pass
                finally:
                    conn.commit()
            if id != 'null' and desc != 'null' and str != 'null'  and db_ref != 'null' and mod != 'null':
                try:
                    signature = [
                        (id, desc, str, db_ref, mod)
                    ]
                    c.executemany("""INSERT INTO Sigs VALUES (?,?,?,?,?)""", signature)
                    table = 'null'
                    sigid = 'null'
                    ptrnrqst = 'null'
                    rspnsetorqst = 'null'
                    id = 'null'
                    desc = 'null'
                    str = 'null'
                    db_ref = 'null'
                    mod = 'null'
                except sqlite3.IntegrityError:
                    pass
                finally:
                    conn.commit()
    except sqlite3.IntegrityError:
        pass
    finally:
        conn.commit()

    conn.close()

    #build honeydb
    conn = sqlite3.connect(honeydb)
    c = conn.cursor()
    #build DB


    conn.close()


if __name__ == '__main__':
    #Create a web server and define the handler to manage the
    #incoming request
    build_DB()

