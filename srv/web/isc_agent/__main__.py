
import json
import pathlib
import random
import argparse
import re
import datetime
import socketserver
import socket
import sys
import threading
import signal
import time
import platform

import logging
import logging.handlers
logger = logging.getLogger("main")
logger.setLevel(logging.DEBUG)

from configparser import ConfigParser
from urllib.parse import unquote
from http.server import BaseHTTPRequestHandler
from http.client import IncompleteRead
from stunnel_manager import StunnelManager

from core import score_request
from agent import Agent


class HoneypotRequestHandler(BaseHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        self.customized_server_string = None
        self.logger = logging.getLogger(self.__class__.__name__)
        super().__init__(*args,**kwargs)
    
    def send_response(self, code, message=None):
        """ This overrides the normal send_response which always includes a Server and Date Header."""
        """ Now it will send customized_server_string if it is set by .responder()"""
        self.log_request(code)
        self.send_response_only(code, message)
        if self.customized_server_string:
            self.send_header('Server', self.customized_server_string)

    def log_message(self, format, *args):
        #prevents log messages from being generated.
        pass

    def apply_customizations(self, text_element:str) -> str:
        """
        Customize tags in responses with updated values.

        Args:
            text_element (str): The text element to customize.

        Returns:
            str: The customized text element.
        """
        #The timestamp needs to be update for every request
        response_customizations["date"] = self.date_time_string()
        #And update the values defined in the response_customizations.json file
        custom_tags = re.findall(r"\*{\*(\w+)\*}\*", text_element)
        for eachtag in set(custom_tags):
            tag = f"\\*{{\\*{eachtag}\\*}}\\*"
            markup = response_customizations.get(eachtag,"")
            text_element = re.sub(tag, markup, text_element)
        return text_element

    def responder(self, response_id):
        """
        Sends a response based on the given response ID.

        Args:
            response_id (str): The ID of the response to send.
        """
        resp = dict(isc_agent.responses.get(response_id))

        if not resp:
            logger.error(f"responder({response_id}) called and that response_id does not exist.")

        #Before we call send_response we must set the new server string.
        headers = resp.get("headers", {})
        self.customized_server_string = headers.get("Server")  #None of not defined (will be ignored)

        # Apply Customizations to body first so Content-length is calculated correctly
        body = self.apply_customizations(resp.get("body", "Not Found"))
        body_bytes = body.encode('utf-8')

        #Determine how we will handle rules with no status_code defined
        if len(body_bytes) > len("PAGE NOT FOUND."):
            default_status_code = 200
        else:
            default_status_code = 404
        status_code = resp.get("status_code", default_status_code)

        #Begin response and send status code
        self.send_response(status_code)
    
        # Make sure required headers are in headers
        headers = resp.get("headers", {})
        headers["Content-Type"] = headers.get("Content-Type", "text/html")  # Default to text/html
        headers["Content-Length"] = str(len(body_bytes))

        # Apply customizations to headers and send them
        for key, value in headers.items():
            if key == "Server":  #We already sent the server header in 
                continue
            formatted_value = self.apply_customizations(value)
            self.send_header(key, formatted_value)

        #Send blank line between headers and body
        self.end_headers()
    
        #send body
        self.wfile.write(body_bytes)
        pass

 
    def handle_request(self):
        """
        Handles incoming HTTP requests.
        """
        self.logger.debug(f"handle_request() called. Path: {self.path}, Method: {self.command}, Remote address: {self.client_address[0]}")
        path = unquote(self.path)
        method = self.command
        remote_addr = self.client_address[0]
        headers = self.headers

        # Simulate Flask request object for score_request compatibility
        class RequestShim:
            def __init__(self, path, method, remote_addr, headers):
                self.path = path
                self.method = method
                self.remote_addr = remote_addr
                self.headers = {k.replace("_", "-").title(): v for k, v in headers.items()}
                self.args = {}
                self.form = {}
                self.cookies = {}
            def __str__(self):
                return f"{self.method} {self.path} headers={self.headers}"

        request = RequestShim(path, method, remote_addr, headers)
        content_length = int(request.headers.get('Content-Length',0))
        post_data = self.rfile.read(content_length).decode()

        best_score = -1
        best_signature = None

        for signature in isc_agent.signatures:
            score = score_request(request, signature)
            if score > best_score:
                best_score = score
                best_signature = signature

        self.logger.debug(f"Request: {method} {path} from {remote_addr} - Score: {best_score}")

        if best_signature and best_score > 0:
            response_id = random.choice(best_signature.get("responses", [1]))
        else:
            response_id = 1   #Use response_id #1 as the default.

        logger.info(f"Sending Response {response_id} matching signature {best_signature} for Request: {method} {path}")


        #Respond to web requests
        try:
            self.responder(response_id)
        except Exception as e:
            self.logger.exception(f"Error Responding to client: {str(e)}")

        #Record response for ISC
        log_data = {
            'time': datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S.%f"),
            'headers': request.headers,
            'sip': remote_addr,
            'dip': isc_agent.my_ip,
            'method': method,
            'url': path,
            'data': post_data,
            'useragent': headers.get("User-Agent",""),
            'version': self.request_version,
            'response_id': response_id,
            'signature_id': best_signature
        }

        try:
            isc_agent.add_to_queue(log_data)
        except Exception as e:
            logging.exception(f"Error sending to ISC: {str(e)}")

        if record_local_responses:
            try:
                fh = open(local_response_path, "a")
                fh.write(f"{json.dumps(log_data)}\n")
                fh.close()
            except Exception as e:
                self.logger.error(f"Error writing to local response file {local_response_path} - {e}")

    def do_GET(self):
        """Handles GET requests."""
        self.logger.debug("do_GET() called")
        self.handle_request()

    def do_POST(self):
        """Handles POST requests."""
        self.logger.debug("do_POST() called")
        self.handle_request()

    def do_HEAD(self):
        """Handles HEAD requests."""
        self.logger.debug("do_HEAD() called")
        self.handle_request()

    def do_PUT(self):
        """Handles PUT requests."""
        self.logger.debug("do_PUT() called")
        self.handle_request()

    def do_DELETE(self):
        """Handles DELETE requests."""
        self.logger.debug("do_DELETE() called")
        self.handle_request()


def shutdown_handler(signum, frame):
    """ Systemctl shutdown handler or CTRL-C """
    logger.info(f"Shutting down isc-agent & stunnel gracefully")
    logger.debug(f"Active threads before ISC-AGENT shutdown: {[t.name for t in threading.enumerate()]}")
    isc_agent.shutdown()
    logger.debug(f"Active threads before STUNNEL shutdown: {[t.name for t in threading.enumerate()]}")
    stun_mgr.shutdown()
    logger.debug(f"Active threads before exit: {[t.name for t in threading.enumerate()]}")
    logger.info(f"Exiting honeypot web service")
    sys.exit(0)


def reload_handler(signum, frame):
    """ systemctl reload handler  or kill -HUP PID"""
    logger.info("Service SIGHUP received.  Refreshing honeypot rules")
    isc_agent.update_honeypot_rules()


#Main body of program
if __name__ == "__main__":
    formatter = logging.Formatter('%(asctime)s - %(threadName)s - %(name)s - %(levelname)s - %(message)s')

    if platform.system() == "Windows":
        # File handler
        fh = logging.handlers.WatchedFileHandler("honeypot.log")
        fh.setLevel(logging.INFO)
        fh.setFormatter(formatter)  
        logger.addHandler(fh)
    else:
        # Syslog handler
        fh = logging.handlers.SysLogHandler(address='/dev/log', facility=logging.handlers.SysLogHandler.LOG_USER)
        fh.setLevel(logging.INFO)  # Set the desired level for syslog
        fh.setFormatter(logging.Formatter('HONEYPOT - %(threadName)s - %(name)s - %(levelname)s - %(message)s'))
        logger.addHandler(fh)

    # Stream handler
    sh = logging.StreamHandler()
    sh.setLevel(logging.ERROR)
    sh.setFormatter(logging.Formatter('%(message)s'))
    logger.addHandler(sh)

    # Parse command-line arguments for config file
    parser = argparse.ArgumentParser(description="Web Honeypot")
    parser.add_argument("-c", "--config", default="/etc/dshield.ini", help="Configuration file")
    parser.add_argument("-r", "--response", default="response_customizations.json", help="Response Customizations")
    parser.add_argument('-l', '--loglevel',  choices=['DEBUG', 'INFO', 'WARNING'], default='WARNING', help='Set the logging level (default: WARNING)')
    #parser.add_argument('--local_responses', default='/srv/log/isc-agent.out', help='Path to record local response records  when "debug" is set to true in dshield.ini. (default: /srv/log/isc-agent.out)')  

    args = parser.parse_args()

    # Load configuration from file
    config = ConfigParser()
    if not config.read(args.config):
        logger.error(f"Could not read config file {args.config}.")
        sys.exit(1)

    #Set the logging level based on the command line.
    numeric_level = getattr(logging, args.loglevel.upper())
    fh.setLevel(level=numeric_level)
    sh.setLevel(level=numeric_level)

    #Set log level to debug if its in the config
    record_local_responses = config.get('plugin:tcp:http','enable_local_logs') == 'true'   #Its lowercase.

    #Set local logfile path 
    local_response_path = config.get('plugin:tcp:http','local_logs_file', fallback='/srv/log/isc-agent.out')

    #Start the ISC Agent threats for queueing and submission   
    isc_agent = Agent(config)

    #Detect no internet connection and repeat until agent starts.
    while True:
        try:
            isc_agent.start()
        except Exception as e:
            logger.exception("Error starting ISC-AGENT. Retrying in 10 seconds.")
            time.sleep(10)
        else:
            break

    
    # Load response customizations from file
    response_config = pathlib.Path(args.response)
    if response_config.is_file():
        try:
            response_customizations = json.load(response_config.open("r"))
        except:
            response_customizations = {}
    else:
        response_customizations = {}

    #Note: http_ports, https_ports in dshield.ini are used by setup process to create port forwards.
    #This process just needs to listen on port 8000 (HTTP) and 8443 (HTTPS)

    port = 8000

    logger.debug(f"start_production() called with port={port}")
    done = False
    while True:
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.bind(('0.0.0.0', port))
            sock.close()
        except socket.error as e:
            logger.error(f"Port {port} is already in use. Waiting on port to become available...")
            time.sleep(10)
        else:
            break

    production = False  #False=Single threaded for debugging vs True = production (multithreaded)

    if production:
        server_class = socketserver.ThreadingTCPServer  #Multithreaded
    else: 
        server_class = socketserver.TCPServer   #Single thread to make debugging easier
    
    mode = "multi-threaded production" if production else "single-threaded debug"
    logger.info(f"Starting {mode} server at port {port}")

    #Capture systemctl signals (and ctrl-c) to do a clean shutdown
    signal.signal(signal.SIGTERM, shutdown_handler)

    # Only set SIGHUP handler on Unix-like systems
    if platform.system() != "Windows":
        signal.signal(signal.SIGHUP, reload_handler)
    signal.signal(signal.SIGINT, shutdown_handler)

    class CustomServer(server_class):
        def handle_error(self, request, client_address):
            exc_type, exc_value, _ = sys.exc_info()
            # Expected errors: log as INFO to track without clutter
            if exc_type == ConnectionResetError:
                logger.info(f"Connection reset by {client_address[0]}:{client_address[1]}")
            elif exc_type == BrokenPipeError:
                logger.info(f"Broken pipe to {client_address[0]}:{client_address[1]}")
            elif exc_type in (TimeoutError, socket.timeout):
                logger.info(f"Timeout from {client_address[0]}:{client_address[1]}")
            elif exc_type == OSError and exc_value.errno in (113, 111):
                logger.info(f"Network error (errno {exc_value.errno}) from {client_address[0]}:{client_address[1]}")
            elif exc_type == IncompleteRead:
                logger.info(f"Incomplete read from {client_address[0]}:{client_address[1]}")
            elif exc_type == OSError and exc_value.errno == 24:
                # Critical resource issue: log as ERROR
                logger.error(f"Too many open files from {client_address[0]}:{client_address[1]}", exc_info=True)
            else:
                # Unexpected errors: log as ERROR with traceback
                logger.error(f"Unexpected error from {client_address[0]}:{client_address[1]}", exc_info=True)

    # Run serve_forever 
    httpd = CustomServer(("", port), HoneypotRequestHandler)
    if production:
        httpd.daemon_threads = True

    #Start the Stunnel port forwarding
    stun_mgr = StunnelManager(config)
    stun_mgr_start_thread = stun_mgr.start(delay=2, port=8000)
    if stun_mgr_start_thread:
        stun_mgr_start_thread.join()

    #Start the httpd server
    httpd.serve_forever()

