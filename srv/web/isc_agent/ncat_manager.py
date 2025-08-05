import configparser
import subprocess
import threading
import time
import logging
from pathlib import Path
from typing import List, Optional, Dict

class HttpProxyManager:
    """Manages ncat processes for both HTTP and HTTPS port forwarding with TLS termination."""

    def __init__(self, config: configparser.ConfigParser) -> None:
        """Initialize HttpProxyManager with a ConfigParser object.

        Args:
            config: ConfigParser object loaded with dshield.ini configuration
        """
        self._logger = logging.getLogger(f"main.{self.__class__.__name__}.{__name__}")
        self._logger.debug("Initializing HttpProxyManager")
        
        self.config = config
        # Dictionary to store process:pid pairs for multiple ncat instances
        self.processes: Dict[subprocess.Popen, int] = {}
        self.conf_file = Path("ncat.conf")
        
        # Read ports from config
        self.http_ports = self._parse_ports(
            config.get('plugin:tcp:http', 'http_ports', fallback='[]')
        )
        self.https_ports = self._parse_ports(
            config.get('plugin:tcp:http', 'https_ports', fallback='[]')
        )
        
        # Get TLS certificate paths
        self.tls_cert = Path(config.get('iscagent', 'tlscert', 
                                      fallback='/etc/stunnel/stunnel.pem'))
        self.tls_key = Path(config.get('iscagent', 'tlskey', 
                                     fallback='/etc/stunnel/stunnel.key'))
        self._logger.debug(f"Initialized with HTTP ports: {self.http_ports}, "
                         f"HTTPS ports: {self.https_ports}")

    def _parse_ports(self, ports_str: str) -> List[int]:
        """Parse port string into a list of integers.

        Args:
            ports_str: String representation of ports (e.g., '[8080, 9090]')

        Returns:
            List of integer port numbers
        """
        self._logger.debug(f"Parsing ports string: {ports_str}")
        ports = ports_str.strip('[]').replace(',', ' ').split()
        parsed_ports = [int(port) for port in ports if port.isdigit()]
        self._logger.debug(f"Parsed ports: {parsed_ports}")
        return parsed_ports


    def _start_ncat(self, delay: int, port: int) -> None:
        """Start ncat processes for each port after specified delay.

        Args:
            delay: Number of seconds to wait before starting ncat
            port: Target port to forward connections to
        """
        self._logger.debug(f"Preparing to start ncat with {delay} second delay")
        time.sleep(delay)
        
        # Start HTTP (unencrypted) listeners
        for listen_port in self.http_ports:
            try:
                process = subprocess.Popen(
                    ['ncat', '-l', str(listen_port), '--sh-exec', 
                     f'ncat 127.0.0.1 {port}'],
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE
                )
                self.processes[process] = process.pid
                self._logger.debug(f"Started HTTP ncat process with PID {process.pid} "
                                 f"for port {listen_port}")
            except subprocess.SubprocessError as e:
                self._logger.debug(f"Failed to start HTTP ncat for port {listen_port}: {e}")

        # Start HTTPS (TLS-terminated) listeners
        for listen_port in self.https_ports:
            try:
                # Use shell=True to handle the pipe between ncat instances
                cmd = (f"ncat --ssl -l {listen_port} --ssl-cert {self.tls_cert} "
                      f"--ssl-key {self.tls_key} | ncat 127.0.0.1 {port}")
                process = subprocess.Popen(
                    cmd,
                    shell=True,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE
                )
                self.processes[process] = process.pid
                self._logger.debug(f"Started HTTPS ncat process with PID {process.pid} "
                                 f"for port {listen_port}")
            except subprocess.SubprocessError as e:
                self._logger.debug(f"Failed to start HTTPS ncat for port {listen_port}: {e}")

    def start(self, delay: int, port: int) -> threading.Thread:
        """Start ncat processes in a thread with specified delay.

        Args:
            delay: Number of seconds to wait before starting
            port: Target port to forward connections to

        Returns:
            Thread object running the ncat processes
        """
        self._logger.debug(f"Starting ncat with delay {delay} and target port {port}")
        thread = threading.Thread(target=self._start_ncat, args=(delay, port))
        thread.start()
        self._logger.debug("Started ncat thread")
        return thread

    def shutdown(self) -> None:
        """Shutdown all ncat processes and clean up."""
        self._logger.debug("Shutting down ncat processes")
        for process in list(self.processes.keys()):
            try:
                process.terminate()
                process.wait(timeout=5)
                self._logger.debug(f"ncat process {self.processes[process]} "
                                 "terminated normally")
            except subprocess.TimeoutExpired:
                process.kill()
                self._logger.debug(f"ncat process {self.processes[process]} "
                                 "killed after timeout")
            except subprocess.SubprocessError as e:
                self._logger.debug(f"Error shutting down ncat: {e}")
            finally:
                del self.processes[process]
        

    def __del__(self) -> None:
        """Ensure cleanup when object is destroyed."""
        self._logger.debug("Destroying HttpProxyManager instance")
        self.shutdown()

# Example usage:
if __name__ == "__main__":
    # Configure logging
    logging.basicConfig(level=logging.DEBUG)
    
    # Load config
    config = configparser.ConfigParser()
    config.read('dshield.ini')
    
    # Create and start manager
    manager = HttpProxyManager(config)
    thread = manager.start(delay=2, port=9000)
    
    # Wait for thread to complete
    thread.join()
    
    # Simulate some work
    time.sleep(10)
    
    # Shutdown
    manager.shutdown()