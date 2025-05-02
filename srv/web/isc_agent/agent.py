import json
import logging
import time
import hmac
import hashlib
import base64
import os
import sys
import socket
import struct
import http
import requests
import pathlib
import threading

from threading import Lock, Timer, Event
from concurrent.futures import ThreadPoolExecutor, Future
from typing import Dict, Any
from datetime import datetime, timedelta

logger = logging.getLogger(f"main.{__name__}")


class Agent:
    """
    A thread-safe agent that manages a queue of web-related JSON messages and submits them to a DShield backend server,
    with IP translation and anonymization capabilities.
    """

    def __init__(self, config_file):

        self.logger = logging.getLogger(f"main.{self.__class__.__name__}")
        self.logger.setLevel(logging.DEBUG)
        self.config = config_file

        self.queue = list()      #To be submitted to dshield
        self.queue_lock = Lock()   #Locked while queue is updated
        self.submit_lock = Lock()   #Locked while entries are being submitted to queue
        self.rules_lock = Lock()   #Locked when rules are updating

        self.scheduler_timers = {}   #keeps track of scheduled timed jobs
        self.scheduler_reschedule = Event()   #Used to stop the scheduler
        self.scheduler_reschedule.set()  # By default scheduler is running

        self.RULES_RESPONSES = {}
        self.RULES_SIGNATURES = {}

        #Keep some statistics
        self.submission_errors = 0
        self.submission_timestamps = list()
        
        #Used to submit entries in queue to dshield
        self.executor = ThreadPoolExecutor(max_workers=2) #2 shoud be good
        
        #self.url = 'https://www.dshield.org/submitapi/'  #production   These are set in the read_config
        #self.url = 'https://isc.sans.edu/devsubmitapi'  #Development

        #Flags control what is anonymized
        self.honeypotmask = -1
        self.honeypotnet = -1
        self.replacehoneypotip = -1
        self.anonymizenet = -1
        self.anonymizenetmask = -1
        self.anonymizemask = -1
        

    @property
    def responses(self):
        #Make sure we don't read rules in the middle of an update
        # Return a copy to prevent modification while iterating after the lock is released.
        with self.rules_lock:
            rules = self.RULES_RESPONSES.copy()
        return rules

    @property
    def signatures(self):
        #Make sure we don't read rules in the middle of an update
        # Return a copy to prevent modification while iterating after the lock is released.
        with self.rules_lock:
            rules = self.RULES_SIGNATURES.copy()
        return rules
    
    def start(self):
        self.logger.debug("Agent start-up initiated.")
        self.my_ip = self.getmyip()

        self.read_config()  #Sets additional attributes in self (overrides defaults above)

        self._scheduler(self.hydrate_interval, self._scheduled_hydrate_rules) #interval defined in config
        self._scheduler(self.submission_interval, self._scheduled_submissions)  #interval defined in config

        self.logger.debug(
            f"Agent initialized: trigger_size={self.queue_trigger_size}, "
            f"submit_interval={self.submission_interval}, "
            f"rule_hydration_interval={self.hydrate_interval}"
        )

    def read_config(self) -> None:
        """
        Reads configuration settings and setups agent.

        Populates agent attributes like userid, apikey, and IP translation/anonymization settings.
        Exits the program if the config file is not found or essential settings are missing/invalid.

        Args:
            config is an instance of ConfigManager that was loaded and passed to Agent during initialization

        Depends on:
            - os.path.isfile
            - configparser.ConfigParser
            - self.cidr2long
            - self.getmyip
            - self.ip42long
            - sys.exit
        """
        self.logger.debug(f"Processing Config for API and dshield parameters")

        self.id = self.config.getint('DShield', 'userid')
        if self.id == 0:
            self.logger.error(" - No userid configured.  Expected 'userid' to be defined in the 'Dshield' section of dshield.ini. (default location is /etc/dshield.ini)")
            sys.exit(1)

        key = self.config.get('DShield', 'apikey')
        if not key or not all(c in 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789=+' for c in key):
            self.logger.error(" - No valid API key configured. Expected 'apikey' to be defined in the 'Dshield' section of dshield.ini. (default location is /etc/dshield.ini)")
            sys.exit(1)
        self.key = key

        url = self.config.get("plugin:tcp:http","dshield_url",fallback="https://www.dshield.org/submitapi/")
        try:
            response = requests.head(url, timeout=10)  # Added timeout
            response.raise_for_status()  # Raise an exception for bad status codes (4xx or 5xx)
        except Exception as e:
            self.logger.exception(f"Invalid URL specified in configuration file. {url} {str(e)}")
            sys.exit(1)
        self.logger.debug(f" - Using this url for submissions: {url}.")
        self.url = url


        log_rate = self.config.get('plugin:tcp:http', 'submit_logs_rate', fallback="300")
        if not log_rate or not log_rate.isnumeric() or int(log_rate) < 60:
            self.logger.warning(f" - submit_log_rates can not be less than 60.  Using 300")
            self.submission_interval = 300
        else:
            self.submission_interval = int(log_rate)
        self.logger.debug(f" - Submission log rate set to {self.submission_interval} seconds.")

        hydrate_interval = self.config.get('plugin:tcp:http', 'refresh_rules_interval', fallback="3600")
        if not hydrate_interval or not hydrate_interval.isnumeric() or int(hydrate_interval) > 86500:
            self.logger.warning(f" - refresh_rules_interval can not be > 86500.  Using 3600.")
            self.hydrate_interval = 3600
        else:
            self.hydrate_interval = int(hydrate_interval)
        self.logger.debug(f" - Rule refresh rate set to {self.hydrate_interval} seconds.")

        msg_trigger = self.config.get('plugin:tcp:http', 'queue_size_submit_trigger', fallback='100')
        if not msg_trigger or not msg_trigger.isnumeric() or (int(msg_trigger) > 1000) or (int(msg_trigger) < 10):
            self.logger.warning(f" - queue_size_submit_trigger must be between 10 and 1000. Defaulting to 100.")
            self.queue_trigger_size = 100
        else:
            self.queue_trigger_size = int(msg_trigger)
        self.logger.debug(f" - Submission are automatically triggered if there are more than {self.queue_trigger_size} in queue.")

        web_log_purge_rate = self.config.get('plugin:tcp:http', 'web_log_purge_rate', fallback='2')
        if not web_log_purge_rate or not web_log_purge_rate.isnumeric() or int(web_log_purge_rate) < 2 or int(web_log_purge_rate) > 10 :
            self.logger.warning(f" - web_log_purge_rate value must be between 2 and 10. Defaulting to 2")
            self.web_log_purge_rate = 2
        else:
            self.web_log_purge_rate = int(web_log_purge_rate)
        self.logger.debug(f" - When purging logs every {self.web_log_purge_rate} will be dropped.")

        web_log_limit = self.config.get('plugin:tcp:http', 'web_log_limit', fallback='1000')
        minimum_log_limit = self.queue_trigger_size *2
        if not web_log_limit or not web_log_limit.isnumeric() or (int(web_log_limit) < minimum_log_limit):
            self.logger.warning(f" - web_log_limit must be at least double queue_size_submit_trigger. Setting it to {minimum_log_limit}")
            self.web_log_limit = minimum_log_limit
        else:
            self.web_log_limit = int(web_log_limit)
        self.logger.debug(f" - When the agent queue size exceeds {self.web_log_limit} messages will be purged.")

        translate = self.config.get('DShield', 'honeypotip')
        translate_result = self.cidr2long(translate)
        self.honeypotnet = translate_result[0]
        self.honeypotmask = translate_result[1]
        self.logger.debug(f" - cidr2long({translate}) returned net={self.honeypotnet}, mask={self.honeypotmask}")

        replacehoneypotip = self.config.get('DShield', 'replacehoneypotip')
        if replacehoneypotip == 'auto':
            replacehoneypotip = self.my_ip
        self.replacehoneypotip = self.ip42long(replacehoneypotip)
        self.logger.debug(f" - ip42long({replacehoneypotip}) returned {self.replacehoneypotip}")

        anonymize = self.config.get('DShield', 'anonymizeip')
        anonymize_result = self.cidr2long(anonymize)
        self.anonymizenet = anonymize_result[0]
        self.anonymizenetmask = anonymize_result[1]
        self.logger.debug(f" - cidr2long({anonymize}) returned net={self.anonymizenet}, mask={self.anonymizenetmask}")

        self.anonymizemask = self.ip42long(self.config.get('DShield', 'anonymizemask'))
        self.logger.debug(f" - ip42long({self.config.get('DShield', 'anonymizemask')}) returned {self.anonymizemask}")

        self.logger.debug(f"read_config completed: user_id={self.id}, honeypot_net={self.honeypotnet}, anonymize_net={self.anonymizenet}")


    def getmyip(self) -> str:
        """
        Retrieves the public IP address of the agent from the DShield API.

        Returns:
            The public IP address as a string, or '127.0.0.1' if the request fails.

        Depends on:
            - requests.get
        """
        self.logger.debug("getmyip called")
        header = {'User-Agent': 'DShield PyLib 0.1'}
        try:
            r = requests.get('https://www.dshield.org/api/myip?json', headers=header, timeout=5)
            #r = custom_get('https://www.dshield.org/api/myip?json', headers=header, timeout=5)
            if r.status_code != 200:
                self.logger.error(f" - Received status code {r.status_code} in response to getmyip request")
                return_value = '127.0.0.1'
            else:
                return_value = r.json()['ip']
            self.logger.debug(f"getmyip returned {return_value}")
            return return_value
        except Exception as e:
            self.logger.exception(f" - Failed to get my IP: {e}")
            raise Exception(e)

    def make_auth_header(self) -> str:
        """
        Generates the DShield API authentication header using HMAC-SHA256.

        Uses the agent's userid, apikey, and a random nonce to create the
        'X-ISC-Authorization' header value.

        Returns:
            The formatted authentication header string.

        Depends on:
            - os.urandom
            - base64.b64encode
            - hmac.new
            - hashlib.sha256
            - self.id
            - self.key
        """
        self.logger.debug("make_auth_header called")
        nonce = base64.b64encode(os.urandom(8)).decode()
        myhash = hmac.new(
            (nonce + str(self.id)).encode('utf-8'),
            msg=self.key.encode('utf-8'),
            digestmod=hashlib.sha256
        ).digest()
        hash64 = base64.b64encode(myhash).decode()
        header = f'ISC-HMAC-SHA256 Credentials={hash64} Userid={self.id} Nonce={nonce.rstrip()}'
        self.logger.debug(f"make_auth_header returned {header}")
        return header


    def ip42long(self, ip: str) -> int:
        """
        Converts an IPv4 address string to its integer representation.

        Args:
            ip: The IPv4 address string (e.g., "192.168.1.1").

        Returns:
            The integer representation of the IP address, or -1 if the input is invalid.

        Depends on:
            - socket.inet_pton
            - struct.unpack
        """
        self.logger.debug(f"ip42long called with ip='{ip}'")
        try:
            ipstr = socket.inet_pton(socket.AF_INET, ip)
            result = struct.unpack('!I', ipstr)[0]
            self.logger.debug(f"ip42long({ip}) returned {result}")
            return result
        except socket.error:
            self.logger.debug(f"ip42long({ip}) returned -1 due to invalid IP")
            return -1


    def long2ip4(self, ip: int) -> str:
        """
        Converts an integer representation of an IPv4 address back to its string format.

        Args:
            ip: The integer representation of the IPv4 address.

        Returns:
            The IPv4 address string (e.g., "192.168.1.1"), or "127.0.0.1" on error.

        Depends on:
            - struct.pack
            - socket.inet_ntoa
        """
        self.logger.debug(f"long2ip4 called with ip={ip}")
        try:
            result = socket.inet_ntoa(struct.pack('!I', ip))
            self.logger.debug(f"long2ip4({ip}) returned {result}")
            return result
        except Exception as e:
            self.logger.error(f" - Error converting long to IP: {ip}, {e}")
            self.logger.debug(f"long2ip4({ip}) returned '127.0.0.1' due to exception")
            return '127.0.0.1'


    def cidr2long(self, ip: str) -> tuple[int, int]:
        """
        Converts a CIDR notation string (IP/mask) or a single IP address
        into its integer network address and integer netmask representation.

        Args:
            ip: The CIDR string (e.g., "192.168.1.0/24") or a single IP
                (e.g., "192.168.1.1", treated as /32).

        Returns:
            A tuple containing (network_address_int, netmask_int).

        Depends on:
            - self.ip42long
            - self.mask42long
        """
        self.logger.debug(f"cidr2long called with ip={ip}")
        parts = [-1, -1]
        if ip.count('/') == 1:
            parts = ip.split('/')
        else:
            parts[0] = ip
            parts[1] = '32'
        net = self.ip42long(parts[0])
        mask = self.mask42long(int(parts[1]))
        result = (net, mask)
        self.logger.debug(f"cidr2long({ip}) returned {result}")
        return result


    def mask42long(self, mask: int) -> int:
        """
        Converts a CIDR mask length (e.g., 24) into its integer netmask representation.

        Args:
            mask: The CIDR mask length (0-32).

        Returns:
            The integer representation of the netmask.
        """
        self.logger.debug(f"mask42long called with mask={mask}")
        result = 2**32 - (2**(32 - mask))
        self.logger.debug(f"mask42long({mask}) returned {result}")
        return result


    def translateip4(self, ip: str) -> str:
        """
        Translates an IP address if it falls within the configured 'honeypotip' range.

        If the input IP matches the honeypot network defined in the config,
        it's replaced with the 'replacehoneypotip' value from the config.
        Otherwise, the original IP is returned.

        Args:
            ip: The IPv4 address string to potentially translate.

        Returns:
            The translated IP address string or the original IP address string.

        Depends on:
            - self.ip42long
            - self.long2ip4
            - self.honeypotmask
            - self.honeypotnet
            - self.replacehoneypotip
        """
        self.logger.debug(f"translateip4 called with ip={ip}")
        if self.replacehoneypotip == -1:
            self.logger.debug(f"translateip4({ip}) returned {ip} (no replacement configured)")
            return ip
        ip_long = self.ip42long(ip)
        if ip_long == -1:
            self.logger.debug(f"translateip4({ip}) returned {ip} (invalid IP)")
            return ip
        if self.honeypotmask != -1 and self.honeypotnet != -1 and self.replacehoneypotip != -1:
            if (ip_long & self.honeypotmask) == self.honeypotnet:
                result = self.long2ip4(self.replacehoneypotip)
                self.logger.debug(f"translateip4({ip}) translated to {result}")
                return result
        self.logger.debug(f"translateip4({ip}) returned {ip} (no translation needed)")
        return ip


    def anonymizeip4(self, ip: str) -> str:
        """
        Anonymizes an IP address if it falls within the configured 'anonymizeip' range.

        If the input IP matches the anonymization network defined in the config,
        it applies the 'anonymizemask' to zero out parts of the address.
        Otherwise, the original IP is returned.

        Args:
            ip: The IPv4 address string to potentially anonymize.

        Returns:
            The anonymized IP address string or the original IP address string.

        Depends on:
            - self.ip42long
            - self.long2ip4
            - self.anonymizenet
            - self.anonymizemask
            - self.anonymizenetmask
        """
        self.logger.debug(f"anonymizeip4 called with ip={ip}")
        ip_long = self.ip42long(ip)
        if ip_long == -1:
            self.logger.debug(f"anonymizeip4({ip}) returned {ip} (invalid IP)")
            return ip
        if self.anonymizenet != -1 and self.anonymizemask != -1 and self.anonymizenetmask != -1:
            if (ip_long & self.anonymizenetmask) == self.anonymizenet:
                ip_long &= self.anonymizemask
                result = self.long2ip4(ip_long)
                self.logger.debug(f"anonymizeip4({ip}) anonymized to {result}")
                return result
        self.logger.debug(f"anonymizeip4({ip}) returned {ip} (no anonymization needed)")
        return ip


    def anontranslateip4(self, ip: str) -> str:
        """
        Applies both translation and anonymization to an IP address.

        First translates the IP using `translateip4`, then anonymizes the result
        using `anonymizeip4`.

        Args:
            ip: The IPv4 address string to process.

        Returns:
            The translated and anonymized IP address string.

        Depends on:
            - self.translateip4
            - self.anonymizeip4
        """
        self.logger.debug(f"anontranslateip4 called with ip={ip}")
        translated_ip = self.translateip4(ip)
        result = self.anonymizeip4(translated_ip)
        self.logger.debug(f"anontranslateip4({ip}) returned {result}")
        return result


    def add_to_queue(self, msg: Dict[str, Any]) -> None:
        """
        Adds a log message dictionary to the agent's submission queue.

        Before adding, it processes the message by applying translation and
        anonymization to 'dip' fields if they exist.
        If the queue size reaches the `queue_trigger_size` after adding,
        it triggers an immediate submission attempt via `_submit`.

        Args:
            msg: A dictionary representing the log message. Expected to potentially
                 contain 'sip' and 'dip' keys with IP address strings.

        Depends on:
            - self.anontranslateip4
            - self.queue_lock
            - self.queue
            - self._submit
        """
        self.logger.debug(f"add_to_queue called with msg={msg}")

        processed_msg = msg.copy()
        if 'dip' in processed_msg:
            processed_msg['dip'] = self.anontranslateip4(processed_msg['dip'])

        self.logger.info(f" - Adding Anonymized message to queue: {processed_msg}")

        with self.queue_lock:
            self.queue.append(processed_msg)

        queue_size = len(self.queue)

        #Prevent ISC queue from being backlocked by purging every X records when web_log_limit reached
        if queue_size >= self.web_log_limit:
            self.logger.warning(f" - ISC Submit queue size exceeded max web_log_limit from ini {self.web_log_limit}. Purging every {self.web_log_purge_rate} records.")
            with self.queue_lock:
                self.queue = self.queue[::self.web_log_purge_rate]
            queue_size = len(self.queue)
        
        #If this submit make the length exceed the trigger size then start submitting. (otherwise done by scheduled job)
        if queue_size >= self.queue_trigger_size:
            self.logger.info(f" - ISC Submit queue is getting large. ({queue_size} items) Submitting data to isc.")
            self._submit()   
        else:
            self.logger.debug(f" - Not triggering submit because (Queue size: {queue_size} < Trigger size {self.queue_trigger_size})")

        self.logger.debug(f"add_to_queue completed, queue size = {len(self.queue)}")


    def shutdown(self) -> None:
        """
        Initiates a graceful shutdown of the agent.

        Cancels the scheduled maintenance timer, attempts a final submission
        of any remaining items in the queue, and cleans up resources like the
        thread pool. Allows interruption via Ctrl+C.

        Depends on:
            - core.InterruptHandler
            - signal.signal
            - self.scheduler_timers.cancel
            - self._submit
            - self._cleanup
        """
        #try:
        self.logger.debug("Agent shutdown called")
        print(" - Waiting for agent to submit final items... Please wait!")

        self.logger.debug(" - Preventing scheduling of future jobs.")
        self.scheduler_reschedule.clear()  # Stop future scheduling

        if self.scheduler_timers:               #Stop currently scheduled timers
            for each_name, each_timer in self.scheduler_timers.items():
                self.logger.info(f" - Canceling scheduled timers for {each_name}.")
                each_timer.cancel()

        self.logger.info(" - Submitting remaining items in queue")
        self._submit()  #Submit remaining items.
        
        #Shutdown executor which is submitting items to dshield
        self.logger.debug(" - Shutting down Executor (dshield submission agent) ")            
        self.executor.shutdown(wait=True)

        self.logger.debug("Agent shutdown completed")
        # except KeyboardInterrupt:
        #     print("Canceling Submission and exiting ungracefully")
        #     for each_name, each_timer in self.scheduler_timers.items():
        #         self.logger.debug(f" - Canceling scheduled timers for {each_name}.")
        #         each_timer.cancel()
        #     self.executor.shutdown(wait=False)


    def _scheduler(self, interval:int, task ) -> None:
        """
        Schedules the next execution of the 'task' on the specified interval.

        Uses a `threading.Timer` to call `task` after `interval` seconds.
        

        Depends on:
            - threading.Timer
        """
        task_name = task.__name__   #Get function name
        self.logger.info(f"_scheduler asked to run {task_name}")
        if self.scheduler_reschedule.is_set():
            self.logger.debug(f" - Scheduling another _scheduler for {task_name} in {self.submission_interval} seconds")
            self.scheduler_timers[task_name] = Timer(interval, self._scheduler, (interval,task))  #Reschedule scheduler it on interval
            self.scheduler_timers[task_name].name = f"scheduler-{task_name}"   #Helps debugging and logging
            self.scheduler_timers[task_name].start()  #Reschedule scheduler to do this again
            task() #Run the task
            self.logger.info(f"_scheduler completed running {task_name}")
        else:
            self.logger.debug("_scheduler is no longer scheduling tasks.")

    def update_honeypot_rules(self):
        """
        Retrieves honeypot rules from dshield.org.

        Returns:
            dict: A dictionary containing the honeypot rules, or None if the request fails.
        """


        self.logger.debug("get_rules() called")
        self.logger.debug("Connecting to dshield.org")
        # Establish a connection to dshield.org
        conn = http.client.HTTPSConnection("dshield.org")
        self.logger.debug("Requesting honeypot rules")
        # Request the honeypot rules
        try:
            conn.request("GET", "/api/honeypotrules")
        except Exception as e:
            self.logger.exception(f"Failed to retrieve honeypotrules.")
            return
        
        # Get the response from the server
        response = conn.getresponse()

        # Check if the request was successful
        honeypot_data = None
        if response.status == 200:
            # Load the JSON data from the response
            honeypot_data = json.loads(response.read().decode("utf-8"))
            self.logger.debug(f"Successfully retrieved honeypot rules. Status code: {response.status}")
        else:
            self.logger.warning(f"Failed to retrieve honeypot rules. Status code: {response.status}")

        # Close the connection
        conn.close()
        self.logger.debug("Connection to dshield.org closed")

        if honeypot_data:
            with self.rules_lock:
                self.RULES_SIGNATURES = honeypot_data.get("signatures", honeypot_data) if "signatures" in honeypot_data else honeypot_data
                self.RULES_RESPONSES = {r["id"]: r for r in honeypot_data.get("responses", [])} if "responses" in honeypot_data else {}
                self.logger.info("Agent Honeypot rules updated")

    def _scheduled_hydrate_rules(self) -> None:
        """
        Periodic updating of honeypot rules task run by the scheduler.

        Depends on:

            - self._scheduler
        """
        self.logger.debug("_scheduled_hydrate_rules called by scheduler - Updating honeypot rules and signatures")

        self.update_honeypot_rules()

        self.logger.info("_scheduled_hydrate_rules completed")


    def _scheduled_submissions(self) -> None:
        """
        Periodic maintenance task run by the timer.

        Performs a health check (`_health`), attempts to submit any queued items
        (`_submit`), and then reschedules itself using `_scheduled_submissions`.

        Depends on:
            - self._health
            - self._submit
            - self._scheduler
        """
        self.logger.info("scheduled_submissions called by scheduler - Running _health() and _submit()")

        self._health()
        self._submit()

        self.logger.info("scheduled_submissions completed")


    def _submit(self) -> None:
        """
        Attempts to submit all currently queued messages to the DShield backend.

        Iterates through the queue, dequeuing messages one by one and submitting
        each to `_send_to_backend` using a thread pool executor. Uses a lock
        (`submit_lock`) to prevent concurrent submission attempts. Results are
        handled asynchronously by `callback_result_handler`.

        Depends on:
            - self.submit_lock
            - self.queue_lock
            - self.queue
            - self.executor.submit
            - self._send_to_backend
            - self.callback_result_handler
        """
        self.logger.debug(f"_submit called with {len(self.queue)} in queue.")
        with self.submit_lock:
            self.logger.debug(" - Starting submission process")

            while True:
                with self.queue_lock:
                    if not self.queue:
                        break
                    msg = self.queue.pop()
                    self.logger.debug(f" - Dequeued message: {msg}")

                future = self.executor.submit(self._send_to_backend, msg)
                future.add_done_callback(lambda f, m=msg: self.callback_result_handler(f, m))

        self.logger.debug(f"_submit completed with {len(self.queue)} in queue")


    def _send_to_backend(self, msg: Dict[str, Any]) -> bool:
        """
        Sends a single processed message to the DShield backend API.

        Formats the message into the required DShield structure (including 'type'
        and 'timestamp'), generates the authentication header, and makes a POST
        request.

        Args:
            msg: The processed log message dictionary to send.

        Returns:
            True if the submission was successful (HTTP 200 OK), False otherwise.

        Depends on:
            - json.dumps
            - datetime.now
            - self.make_auth_header
            - requests.post
            - sys.getsizeof
            - self.url
        """
        self.logger.debug(f"_send_to_backend called to submit msg={msg}")

        # Hardcode type as 'webhoneypot' since all messages are web logs
        dshield_msg = {
            'type': 'webhoneypot',
            'logs': json.dumps(msg),
            'timestamp': msg.get('time', datetime.now().isoformat())
        }
        self.logger.debug(f" - Reformatted message for DShield: {dshield_msg}")

        auth_header = self.make_auth_header()
        headers = {
            'content-type': 'application/json',
            'User-Agent': f'DShield WebHoneypot-{self.config.get("DShield","version",fallback="XX")}-{self.config.get("DShield","userid",fallback="blank")}',
            'X-ISC-Authorization': auth_header,
            'X-ISC-LogType': 'webhoneypot'
        }

        try:
            response = requests.post(self.url, json=dshield_msg, headers=headers, timeout=10)
            #response = custom_post(self.url, msg=dshield_msg, headers=headers, timeout=10)
            
            if response.status_code != 200:
                self.logger.error(f" - Received status code {response.status_code} {response.reason} in response")
                self.logger.debug("_send_to_backend returned False (non-200 status)")
                return False

            self.logger.debug(f" - Sent {sys.getsizeof(dshield_msg)} bytes to {self.url}")
            self.logger.debug("_send_to_backend returned True")
            return True

        except Exception as e:
            self.logger.error(f" - Submission failed: {e}")
            self.logger.debug(f"_send_to_backend returned False due to exception: {e}")
            return False


    def callback_result_handler(self, future: Future, msg: Dict[str, Any]) -> None:
        """
        Callback function executed when a submission future completes.

        Checks the result of the submission (`future.result()`). If successful,
        increments the 24-hour submission count and records the timestamp.
        If unsuccessful (returned False or raised an exception), increments the
        error count and requeues the message at the front of the queue.

        Args:
            future: The `concurrent.futures.Future` object representing the
                    submission task.
            msg: The original message dictionary associated with this submission.

        Depends on:
            - future.result
            - datetime.now
            - self.submission_timestamps
            - self.queue_lock
            - self.queue
        """
        self.logger.debug(f"callback_result_handler is checking the ISC response.")
        try:
            success = future.result()
            self.logger.debug(f" - ISC Submission was accepted: {success}")
            if success:
                self.submission_timestamps.append(datetime.now())
                self.logger.info(f" - Submission successful for msg: {msg}, submissions in last 24 hours={len(self.submission_timestamps)}")
            else:
                raise Exception(" - Submission returned False")

        except Exception as e:
            self.submission_errors += 1
            self.logger.error(f" - Submission failed for msg {msg}: {e}")
            with self.queue_lock:
                self.queue.appendleft(msg)
            self.logger.debug(f" - Message requeued: {msg}, errors_24h={self.submission_errors}")

        self.logger.debug("callback_result_handler completed")


    def _health(self) -> None:
        """
        Performs periodic health checks and logging.

        Removes submission timestamps older than 24 hours from the
        `submission_timestamps` deque. Logs the current 24-hour submission count,
        error count, and queue size.

        Depends on:
            - datetime.now
            - timedelta
            - self.submission_timestamps
            - self.queue_lock
            - self.queue
        """
        self.logger.debug("_health called")
        cutoff = datetime.now() - timedelta(hours=24)
        while self.submission_timestamps and self.submission_timestamps[0] < cutoff:
            self.submission_timestamps.popleft()
            self.logger.debug(f"Removed old timestamp, remaining={len(self.submission_timestamps)}")

        with self.queue_lock:
            queue_size = len(self.queue)

        health_report = {
            "submissions_in_24h": len(self.submission_timestamps),
            "submission_errors": self.submission_errors,
            "queue_size": queue_size,
            "timestamp": datetime.now().isoformat(),
            "threads": [t.name for t in threading.enumerate()]
        }

        self.logger.debug(f"Health report generated: {health_report}")
        self.logger.debug("_health completed")



# Example usage
if __name__ == "__main__":
    # Configure logging to write to isc-agent.log
    log_formatter = logging.Formatter('%(asctime)s - %(threadName)s - %(name)s - %(levelname)s - %(message)s')
    log_handler = logging.FileHandler('isc-agent.log')
    log_handler.setFormatter(log_formatter)
    log_handler.setLevel(logging.INFO)

    sh_handler = logging.StreamHandler(stream=sys.stdout)
    sh_handler.setFormatter(logging.Formatter("%(message)s"))
    sh_handler.setLevel(logging.INFO)
    
    root_logger = logging.getLogger()
    root_logger.setLevel(logging.INFO) # Set root logger level
    root_logger.addHandler(log_handler) # Add the file handler
    root_logger.addHandler(sh_handler)

    from configparser import ConfigParser
    config = ConfigParser()
    config.read("dshield.ini")
    agent = Agent(config)
    
    sample_logs = [
        {"time": "2025-03-24T17:05:06.176492", "headers": {"host": "70.91.145.13", "accept-encoding": "identity"}, "sip": "139.59.170.85", "dip": "70.91.145.14", "method": "GET", "url": "/robots.txt", "data": None, "useragent": "", "version": "HTTP/1.1", "response_id": {"comment": None, "headers": {"Server": "Apache/3.2.3", "Access-Control-Allow-Origin": "*", "Content-Type": "text/html"}, "status_code": 200}, "signature_id": {"max_score": 72, "rules": [{"attribute": "method", "condition": "equals", "value": "GET", "score": 2, "required": False}, {"attribute": "headers", "condition": "absent", "value": "user-agents", "score": 70, "required": False}]}},
        {"time": "2025-03-24T17:05:06.177676", "headers": {"host": "70.91.145.13", "accept-encoding": "identity"}, "sip": "139.59.170.85", "dip": "70.91.145.14", "method": "GET", "url": "/sitemap.xml", "data": None, "useragent": "", "version": "HTTP/1.1", "response_id": {"comment": None, "headers": {"Server": "Apache/3.2.3", "Access-Control-Allow-Origin": "*", "Content-Type": "text/html"}, "status_code": 200}, "signature_id": {"max_score": 72, "rules": [{"attribute": "method", "condition": "equals", "value": "GET", "score": 2, "required": False}, {"attribute": "headers", "condition": "absent", "value": "user-agents", "score": 70, "required": False}]}},
        {"time": "2025-03-24T00:01:47.161231", "headers": {"host": "70.91.145.13", "user-agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.131 Safari/537.36", "accept": "*/*", "accept-encoding": "gzip"}, "sip": "71.6.232.25", "dip": "70.91.145.14", "method": "GET", "url": "/", "data": None, "useragent": ["Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.131 Safari/537.36"], "version": "HTTP/1.1", "response_id": {"comment": None, "headers": {"Server": "Apache/3.2.3", "Access-Control-Allow-Origin": "*", "Content-Type": "text/html"}, "status_code": 200}, "signature_id": {"max_score": 72, "rules": [{"attribute": "method", "condition": "equals", "value": "GET", "score": 2, "required": False}, {"attribute": "headers", "condition": "absent", "value": "user-agents", "score": 70, "required": False}]}},
        {"time": "2025-03-24T00:03:40.390958", "headers": {"host": "70.91.145.13", "user-agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.131 Safari/537.36", "accept": "*/*", "accept-encoding": "gzip"}, "sip": "71.6.232.25", "dip": "70.91.145.14", "method": "GET", "url": "/", "data": None, "useragent": ["Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.131 Safari/537.36"], "version": "HTTP/1.1", "response_id": {"comment": None, "headers": {"Server": "Apache/3.2.3", "Access-Control-Allow-Origin": "*", "Content-Type": "text/html"}, "status_code": 200}, "signature_id": {"max_score": 72, "rules": [{"attribute": "method", "condition": "equals", "value": "GET", "score": 2, "required": False}, {"attribute": "headers", "condition": "absent", "value": "user-agents", "score": 70, "required": False}]}},
        {"time": "2025-03-24T00:03:40.392047", "headers": {"host": "example.com:80", "connection": "keep-alive"}, "sip": "185.224.128.17", "dip": "70.91.145.14", "method": "CONNECT", "url": "example.com:80", "data": None, "useragent": "", "version": "HTTP/1.1", "response_id": {"comment": None, "headers": {"Server": "Apache/3.2.3", "Access-Control-Allow-Origin": "*", "Content-Type": "text/html"}, "status_code": 200}, "signature_id": {"max_score": 72, "rules": [{"attribute": "method", "condition": "equals", "value": "GET", "score": 2, "required": False}, {"attribute": "headers", "condition": "absent", "value": "user-agents", "score": 70, "required": False}]}},
        {"time": "2025-03-24T00:03:40.523689", "headers": {"host": "70.91.145.13", "user-agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.131 Safari/537.36", "accept": "*/*", "accept-encoding": "gzip"}, "sip": "71.6.232.25", "dip": "70.91.145.14", "method": "GET", "url": "/", "data": None, "useragent": ["Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.131 Safari/537.36"], "version": "HTTP/1.1", "response_id": {"comment": None, "headers": {"Server": "Apache/3.2.3", "Access-Control-Allow-Origin": "*", "Content-Type": "text/html"}, "status_code": 200}, "signature_id": {"max_score": 72, "rules": [{"attribute": "method", "condition": "equals", "value": "GET", "score": 2, "required": False}, {"attribute": "headers", "condition": "absent", "value": "user-agents", "score": 70, "required": False}]}},
        {"time": "2025-03-24T00:03:40.524956", "headers": {"host": "example.com:80", "connection": "keep-alive"}, "sip": "185.224.128.17", "dip": "70.91.145.14", "method": "CONNECT", "url": "example.com:80", "data": None, "useragent": "", "version": "HTTP/1.1", "response_id": {"comment": None, "headers": {"Server": "Apache/3.2.3", "Access-Control-Allow-Origin": "*", "Content-Type": "text/html"}, "status_code": 200}, "signature_id": {"max_score": 72, "rules": [{"attribute": "method", "condition": "equals", "value": "GET", "score": 2, "required": False}, {"attribute": "headers", "condition": "absent", "value": "user-agents", "score": 70, "required": False}]}},
        {"time": "2025-03-24T00:03:40.526089", "headers": {"host": "example.com"}, "sip": "185.224.128.17", "dip": "70.91.145.14", "method": "\u0000GET", "url": "/", "data": None, "useragent": "", "version": "HTTP/1.1", "response_id": {"comment": None, "headers": {"Server": "Apache/3.2.3", "Access-Control-Allow-Origin": "*", "Content-Type": "text/html"}, "status_code": 200}, "signature_id": {"max_score": 72, "rules": [{"attribute": "method", "condition": "equals", "value": "GET", "score": 2, "required": False}, {"attribute": "headers", "condition": "absent", "value": "user-agents", "score": 70, "required": False}]}},
        {"time": "2025-03-24T00:04:54.343830", "headers": {"host": "70.91.145.13:8080", "user-agent": "Expanse, a Palo Alto Networks company, searches across the global IPv4 space multiple times per day to identify customers&#39; presences on the Internet. If you would like to be excluded from our scans, please send IP addresses/domains to: scaninfo@paloaltonetworks.com"}, "sip": "147.185.132.75", "dip": "70.91.145.14", "method": "GET", "url": "/wp-login.php", "data": None, "useragent": ["Expanse, a Palo Alto Networks company, searches across the global IPv4 space multiple times per day to identify customers&#39; presences on the Internet. If you would like to be excluded from our scans, please send IP addresses/domains to: scaninfo@paloaltonetworks.com"], "version": "HTTP/1.1", "response_id": {"comment": None, "headers": {"Server": "Apache/3.2.3", "Access-Control-Allow-Origin": "*", "Content-Type": "text/html"}, "status_code": 200}, "signature_id": {"max_score": 72, "rules": [{"attribute": "method", "condition": "equals", "value": "GET", "score": 2, "required": False}, {"attribute": "headers", "condition": "absent", "value": "user-agents", "score": 70, "required": False}]}},
        {"time": "2025-03-24T00:04:54.349662", "headers": {"host": "70.91.145.13:8080", "user-agent": "Expanse, a Palo Alto Networks company, searches across the global IPv4 space multiple times per day to identify customers&#39; presences on the Internet. If you would like to be excluded from our scans, please send IP addresses/domains to: scaninfo@paloaltonetworks.com"}, "sip": "147.185.132.75", "dip": "70.91.145.14", "method": "GET", "url": "/wp-login.php", "data": None, "useragent": ["Expanse, a Palo Alto Networks company, searches across the global IPv4 space multiple times per day to identify customers&#39; presences on the Internet. If you would like to be excluded from our scans, please send IP addresses/domains to: scaninfo@paloaltonetworks.com"], "version": "HTTP/1.1", "response_id": {"comment": None, "headers": {"Server": "Apache/3.2.3", "Access-Control-Allow-Origin": "*", "Content-Type": "text/html"}, "status_code": 200}, "signature_id": {"max_score": 72, "rules": [{"attribute": "method", "condition": "equals", "value": "GET", "score": 2, "required": False}, {"attribute": "headers", "condition": "absent", "value": "user-agents", "score": 70, "required": False}]}},
        {"time": "2025-03-24T00:04:54.350693", "headers": {"host": "70.91.145.11:8000", "user-agent": "Expanse, a Palo Alto Networks company, searches across the global IPv4 space multiple times per day to identify customers&#39; presences on the Internet. If you would like to be excluded from our scans, please send IP addresses/domains to: scaninfo@paloaltonetworks.com"}, "sip": "147.185.132.75", "dip": "70.91.145.14", "method": "GET", "url": "/wp-login.php", "data": None, "useragent": ["Expanse, a Palo Alto Networks company, searches across the global IPv4 space multiple times per day to identify customers&#39; presences on the Internet. If you would like to be excluded from our scans, please send IP addresses/domains to: scaninfo@paloaltonetworks.com"], "version": "HTTP/1.1", "response_id": {"comment": None, "headers": {"Server": "Apache/3.2.3", "Access-Control-Allow-Origin": "*", "Content-Type": "text/html"}, "status_code": 200}, "signature_id": {"max_score": 72, "rules": [{"attribute": "method", "condition": "equals", "value": "GET", "score": 2, "required": False}, {"attribute": "headers", "condition": "absent", "value": "user-agents", "score": 70, "required": False}]}},
        {"time": "2025-03-24T00:04:54.358228", "headers": {"host": "70.91.145.13:8080", "user-agent": "Expanse, a Palo Alto Networks company, searches across the global IPv4 space multiple times per day to identify customers&#39; presences on the Internet. If you would like to be excluded from our scans, please send IP addresses/domains to: scaninfo@paloaltonetworks.com"}, "sip": "147.185.132.75", "dip": "70.91.145.14", "method": "GET", "url": "/wp-login.php", "data": None, "useragent": ["Expanse, a Palo Alto Networks company, searches across the global IPv4 space multiple times per day to identify customers&#39; presences on the Internet. If you would like to be excluded from our scans, please send IP addresses/domains to: scaninfo@paloaltonetworks.com"], "version": "HTTP/1.1", "response_id": {"comment": None, "headers": {"Server": "Apache/3.2.3", "Access-Control-Allow-Origin": "*", "Content-Type": "text/html"}, "status_code": 200}, "signature_id": {"max_score": 72, "rules": [{"attribute": "method", "condition": "equals", "value": "GET", "score": 2, "required": False}, {"attribute": "headers", "condition": "absent", "value": "user-agents", "score": 70, "required": False}]}},
        {"time": "2025-03-24T00:04:54.359358", "headers": {"host": "70.91.145.11:8000", "user-agent": "Expanse, a Palo Alto Networks company, searches across the global IPv4 space multiple times per day to identify customers&#39; presences on the Internet. If you would like to be excluded from our scans, please send IP addresses/domains to: scaninfo@paloaltonetworks.com"}, "sip": "147.185.132.75", "dip": "70.91.145.14", "method": "GET", "url": "/wp-login.php", "data": None, "useragent": ["Expanse, a Palo Alto Networks company, searches across the global IPv4 space multiple times per day to identify customers&#39; presences on the Internet. If you would like to be excluded from our scans, please send IP addresses/domains to: scaninfo@paloaltonetworks.com"], "version": "HTTP/1.1", "response_id": {"comment": None, "headers": {"Server": "Apache/3.2.3", "Access-Control-Allow-Origin": "*", "Content-Type": "text/html"}, "status_code": 200}, "signature_id": {"max_score": 72, "rules": [{"attribute": "method", "condition": "equals", "value": "GET", "score": 2, "required": False}, {"attribute": "headers", "condition": "absent", "value": "user-agents", "score": 70, "required": False}]}},
        {"time": "2025-03-24T00:04:54.360667", "headers": {"host": "70.91.145.12:8000", "user-agent": "Expanse, a Palo Alto Networks company, searches across the global IPv4 space multiple times per day to identify customers&#39; presences on the Internet. If you would like to be excluded from our scans, please send IP addresses/domains to: scaninfo@paloaltonetworks.com"}, "sip": "147.185.132.75", "dip": "70.91.145.14", "method": "GET", "url": "/wp-login.php", "data": None, "useragent": ["Expanse, a Palo Alto Networks company, searches across the global IPv4 space multiple times per day to identify customers&#39; presences on the Internet. If you would like to be excluded from our scans, please send IP addresses/domains to: scaninfo@paloaltonetworks.com"], "version": "HTTP/1.1", "response_id": {"comment": None, "headers": {"Server": "Apache/3.2.3", "Access-Control-Allow-Origin": "*", "Content-Type": "text/html"}, "status_code": 200}, "signature_id": {"max_score": 72, "rules": [{"attribute": "method", "condition": "equals", "value": "GET", "score": 2, "required": False}, {"attribute": "headers", "condition": "absent", "value": "user-agents", "score": 70, "required": False}]}},
        {"time": "2025-03-24T00:04:54.413396", "headers": {"host": "70.91.145.13:8080", "user-agent": "Expanse, a Palo Alto Networks company, searches across the global IPv4 space multiple times per day to identify customers&#39; presences on the Internet. If you would like to be excluded from our scans, please send IP addresses/domains to: scaninfo@paloaltonetworks.com"}, "sip": "147.185.132.75", "dip": "70.91.145.14", "method": "GET", "url": "/wp-login.php", "data": None, "useragent": ["Expanse, a Palo Alto Networks company, searches across the global IPv4 space multiple times per day to identify customers&#39; presences on the Internet. If you would like to be excluded from our scans, please send IP addresses/domains to: scaninfo@paloaltonetworks.com"], "version": "HTTP/1.1", "response_id": {"comment": None, "headers": {"Server": "Apache/3.2.3", "Access-Control-Allow-Origin": "*", "Content-Type": "text/html"}, "status_code": 200}, "signature_id": {"max_score": 72, "rules": [{"attribute": "method", "condition": "equals", "value": "GET", "score": 2, "required": False}, {"attribute": "headers", "condition": "absent", "value": "user-agents", "score": 70, "required": False}]}}
    ]
    
    try:
        for _ in range(1):
            for log in sample_logs[:5]:
                agent.add_to_queue(log)

        time.sleep(305)

        for _ in range(10):
            for log in sample_logs:
                agent.add_to_queue(log)

        for _ in range(999999999999):
            time.sleep(5)
    except KeyboardInterrupt:
        agent.shutdown()
