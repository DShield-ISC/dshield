#!/usr/bin/env python
# linked to schema for web.py

import re
import os
import sqlite3


def sigmatch(self, pattern, module):
    config = '..' + os.path.sep + 'DB' + os.path.sep + 'webserver.sqlite'
    honeydb = '..' + os.path.sep + 'DB' + os.path.sep + 'config.sqlite'
    conn = sqlite3.connect(config)
    c = conn.cursor()
    match = 0
    pathmatch = c.execute("""SELECT patternString FROM Sigs""").fetchall()
    for i in pathmatch:
        if re.match(i[0], pattern) is not None:
            sigDescription = c.execute("""SELECT patternDescription FROM Sigs WHERE patternString=?""",
                                       [str(i[0])]).fetchone()
            try:
                if str(self.headers['user-agent']) is not None:
                    useragentstring = '%s' & str(self.headers['user-agent'])
            except:
                useragentstring = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/53.0.2785.143 Safari/537.36"
            SigID = c.execute("""SELECT id FROM Sigs WHERE module=?""", [str(module)]).fetchone()
            #self.send_header('Content-type', 'text/html')
            #self.send_header('Server', 'Apache/2.0.1')
            #self.send_response(200)  # OK
            #self.end_headers()
            # display vuln page based on sigdescription - and set headers based on OSTarget
            #response = c.execute("""SELECT * FROM HdrResponses WHERE SigID=?""", (str(SigID[0]))).fetchall()
            #for r in response:
            #    hdrResponse = c.execute("""SELECT * FROM HdrResponses WHERE SigID=?""", (str(SigID[0]))).fetchall()
            #    if hdrResponse is not None:
            #        for i in hdrResponse:
            #           self.send_header(i[2], i[3])
            try:
                db_ref = c.execute("""SELECT db_ref FROM Sigs WHERE ID=?""", [str(SigID[0])]).fetchone()
                response = c.execute(
                    """SELECT * FROM """ + str(db_ref[0]) + """ WHERE SigID=?""", [str(SigID[0])]).fetchall()
            except:
                print ('Error detecting response DB.')
                print ('SigID[0]')
                print ('db_ref[0]')
            if module == 'lfi':
                for i in response:
                    if re.match(i[1], pattern) is not None:
                        match = 1
                        responsepath = eval(str(i[2]))
                        f = open(responsepath)
                        self.wfile.write(f.read())
                        f.close
                        print(self.client_address[
                                  0] + " - - [" + self.date_time_string() + "] - - Malicious pattern detected: " + \
                              sigDescription[0] + " - - " + pattern)
                        print(self.client_address[
                                  0
                              ] + " - - [" + self.date_time_string() + "] - - Responded with " + str(
                            module
                        ) + " response page.")
                        c.execute(
                            """INSERT INTO requests (date, address, cmd, path, useragent, vers, summary) VALUES(?, ?, ?, ?, ?, ?, ?)""",
                            (
                                self.date_time_string(),
                                self.client_address[0],
                                self.command, self.path,
                                useragentstring,
                                self.request_version,
                                "Malicious pattern" + str(sigDescription)
                            )
                        )
                        conn.commit()
                        return match
                        break
            if module == 'xss':
                for i in response:
                    if re.match(i[1], pattern) is not None:
                        match = 1
                        script = re.sub(r'\<|\/|\>|script', r'', pattern)
                        responsepath = eval(str(i[2]))
                        f = open(responsepath)
                        message = f.read().replace('Hello world', script,1)
                        self.wfile.write(message)
                        f.close
                        print(self.client_address[
                                  0] + " - - [" + self.date_time_string() + "] - - Malicious pattern detected: " + \
                              sigDescription[0] + " - - " + pattern)
                        print(self.client_address[
                                  0
                              ] + " - - [" + self.date_time_string() + "] - - Responded with " + str(
                            module
                        ) + " response page.")
                        c.execute(
                            """INSERT INTO requests (date, address, cmd, path, useragent, vers, summary) VALUES(?, ?, ?, ?, ?, ?, ?)""",
                            (
                                self.date_time_string(),
                                self.client_address[0],
                                self.command, self.path,
                                useragentstring,
                                self.request_version,
                                "Malicious pattern" + str(sigDescription)
                            )
                        )
                        conn.commit()
                        return match
                        break
            if module == 'phpmyadmin':
                for i in response:
                    if re.match(i[1], pattern) is not None:
                        match = 1
                        responsepath = eval(str(i[2]))
                        f = open(responsepath)
                        self.wfile.write(f.read())
                        f.close
                        print(self.client_address[
                                  0] + " - - [" + self.date_time_string() + "] - - Malicious pattern detected: " + \
                              sigDescription[0] + " - - " + pattern)
                        print(self.client_address[
                                  0
                              ] + " - - [" + self.date_time_string() + "] - - Responded with " + str(
                            module
                        ) + " response page.")
                        c.execute(
                            """INSERT INTO requests (date, address, cmd, path, useragent, vers, summary) VALUES(?, ?, ?, ?, ?, ?, ?)""",
                            (
                                self.date_time_string(),
                                self.client_address[0],
                                self.command, self.path,
                                useragentstring,
                                self.request_version,
                                "Malicious pattern" + str(sigDescription)
                            )
                        )
                        conn.commit()
                        return match
                        break
            if module == 'robots':
                for i in response:
                    if re.match(i[1], pattern) is not None:
                        match = 1
                        responsepath = eval(str(i[2]))
                        f = open(responsepath, 'rb')
                        self.wfile.write(f.read())
                        f.close
                        print(self.client_address[
                                  0] + " - - [" + self.date_time_string() + "] - - Malicious pattern detected: " + \
                              sigDescription[0] + " - - " + pattern)
                        print(self.client_address[
                                  0
                              ] + " - - [" + self.date_time_string() + "] - - Responded with " + str(
                            module
                        ) + " response page.")
                        c.execute(
                            """INSERT INTO requests (date, address, cmd, path, useragent, vers, summary) VALUES(?, ?, ?, ?, ?, ?, ?)""",
                            (
                                self.date_time_string(),
                                self.client_address[0],
                                self.command, self.path,
                                useragentstring,
                                self.request_version,
                                "Malicious pattern" + str(sigDescription)
                            )
                        )
                        conn.commit()
                        return match
                        break
            if module == 'rfi':
                for i in response:
                    if re.match(i[1], pattern) is not None:
                        match = 1
                        uri = re.findall(i[2], pattern)
                        remotefiledir = '..' + os.path.sep + 'html' + os.path.sep + 'www'
                        domain = sitecopy.sitecopy(uri[0], remotefiledir)
                        webdirlst = os.listdir(remotefiledir)
                        remote_file_path = ''
                        print(self.client_address[
                                  0] + " - - [" + self.date_time_string() + "] - - Malicious pattern detected: " + \
                              sigDescription[0] + " - - " + pattern)
                        # Only downloads domain from site - to prevent being an open proxy - also has sleep to prevent DDOS.
                        for site in webdirlst:
                            remote_file_path = os.path.join(remotefiledir, domain)
                        if os.path.isfile(remote_file_path):  # os.path.isfile(file_path):
                            # os.listdir(file_path)
                            f = open(remote_file_path)
                            self.wfile.write(f.read())
                            time.sleep(1)
                            f.close()
                        c.execute(
                            """INSERT INTO requests (date, address, cmd, path, useragent, vers, summary) VALUES(?, ?, ?, ?, ?, ?, ?)""",
                            (
                                self.date_time_string(),
                                self.client_address[0],
                                self.command, self.path,
                                useragentstring,
                                self.request_version,
                                "Malicious pattern" + str(sigDescription)
                            )
                        )
                        conn.commit()
                        return match
                        break
            if module == 'sqli':
                for i in response:
                    if re.match(i[1], pattern) is not None:
                        match = 1
                        if "insert" in pattern:
                            script = re.sub(r'^.+insert', r'', pattern)
                            message = (i[2]).replace('replace', script, 1)
                            self.wfile.write(message)
                        else:
                            self.wfile.write(str(i[2]))
                        print(self.client_address[
                                  0] + " - - [" + self.date_time_string() + "] - - Malicious pattern detected: " + \
                              sigDescription[0] + " - - " + pattern)
                        print(self.client_address[
                                  0
                              ] + " - - [" + self.date_time_string() + "] - - Responded with " + str(
                            module
                        ) + "response page.")
                        c.execute(
                            """INSERT INTO requests (date, address, cmd, path, useragent, vers, summary) VALUES(?, ?, ?, ?, ?, ?, ?)""",
                            (
                                self.date_time_string(),
                                self.client_address[0],
                                self.command, self.path,
                                useragentstring,
                                self.request_version,
                                "Malicious pattern" + str(sigDescription)
                            )
                        )
                        conn.commit()
                        return match
                        break

if __name__ == '__main__':
    #Create a web server and define the handler to manage the
    #incoming request
    try:
        sigmatch()
    except:
        print("Requires basehttpserver response, match, and module.")
