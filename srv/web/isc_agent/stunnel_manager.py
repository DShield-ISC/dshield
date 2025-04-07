import configparser
import subprocess
import threading
import time
import logging
import shutil
import platform
import socket

from pathlib import Path
from typing import List, Optional

class StunnelManager:
    """Manages an stunnel process with HTTP/HTTPS listeners based on configuration."""

    def __init__(self, config: configparser.ConfigParser, watchdog_interval: int = 600, stunnel_path: Path = 'stunnel') -> None:
        """Initialize StunnelManager with a ConfigParser object and watchdog interval.

        Args:
            config: ConfigParser object loaded with dshield.ini configuration
            watchdog_interval: Seconds between watchdog checks (default: 600)
        """
        self._logger = logging.getLogger(f"main.{self.__class__.__name__}.{__name__}")
        self._logger.debug("Initializing StunnelManager")
        
        self.stunnel_path = stunnel_path  #Default assumes it is path
        self.config = config
        self.pid: Optional[int] = None
        self.process: Optional[subprocess.Popen] = None
        self.conf_file = Path("stunnel.conf")
        self.dport = None
        self.watchdog_interval = watchdog_interval
        self._watchdog_running = False
        self._watchdog_thread: Optional[threading.Thread] = None
        
        # Read ports from config
        # self.https_ports = self._parse_ports(
        #     config.get('plugin:tcp:http', 'https_ports', fallback='[]')
        # )
        self.https_ports = [8443] 
        
        # Get TLS certificate pathsd
        self.tls_cert = "stunnel.pem"
        #openssl req -x509 -newkey rsa:2048 -keyout stunnel.key -out stunnel.pem -days 365 -nodes
        #cat stunnel.pem stunnel.key > combined_stunnel.pem
        if not Path(self.tls_cert).is_file:
            self._logger.error(f"Unable to open stunnel certificate {self.tls_cert}")     

        # self.tls_cert = Path(config.get('iscagent', 'tlscert', 
        #                               fallback='/etc/stunnel/stunnel.pem'))
        # self.tls_key = Path(config.get('iscagent', 'tlskey', 
        #                              fallback='/etc/stunnel/stunnel.key'))

        self.find_stunnel_binary()
        self._logger.debug(f"Stunnel Binary location is '{self.stunnel_path}'")
        
        self._logger.debug(f"Initialized with HTTPS ports: {self.https_ports} and watchdog interval: {self.watchdog_interval}")

    def find_stunnel_binary(self):
        # Determine the name of the executable based on the platform
        stunnel_executable = "stunnel.exe" if platform.system() == "Windows" else "stunnel"
        
        # Use shutil.which to search in PATH
        path_str = shutil.which(stunnel_executable)
        if path_str:
            path = Path(path_str)
            if path.is_file():
                self.stunnel_path = path.resolve()
                return

        # Check common installation paths if it was not in the paths
        if platform.system() == "Windows":
            potential_paths = [
                Path(r"C:\Program Files\stunnel\bin\stunnel.exe"),
                Path(r"C:\Program Files (x86)\stunnel\bin\stunnel.exe"),
                Path(r"C:\stunnel\bin\stunnel.exe"),
            ]
        else:
            potential_paths = [
                Path("/usr/bin/stunnel"),
                Path("/usr/local/bin/stunnel"),
                Path("/opt/stunnel/bin/stunnel"),
            ]

        for path in potential_paths:
            if path.is_file():
                self.stunnel_path = path.resolve()
                return

        # If not found
        self.stunnel_path = None

 
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

    def _generate_config(self, target_port: int) -> None:
        """Generate stunnel configuration file.

        Args:
            target_port: Port number to forward connections to
        """
        self._logger.debug(f"Generating config file for target port {target_port}")
        with self.conf_file.open('w') as f:
            f.write(";to start: stunnel stunnel.conf\n")
            f.write(";to create test stunnel keys...\n")
            f.write(";openssl req -x509 -newkey rsa:2048 -keyout stunnel.key "
                   "-out stunnel.pem -days 365 -nodes\n")
            f.write(";cat stunnel.pem stunnel.key > combined_stunnel.pem\n\n")
               
            # HTTPS (encrypted) listeners
            for port in self.https_ports:
                #f.write("setuid = nobody\n")
                #f.write("setgid = nogroup\n")
                #f.write("pid = /var/run/stunnel.pid\n")
                f.write("foreground = yes\n")
                f.write(f"output = {Path().cwd().joinpath('stunnel.log')}\n")
                f.write("; HTTPS Proxy (With SSL/TLS Encryption)\n")
                f.write(f"[https_{port}]\n")
                f.write(f"accept = {port}\n")
                f.write(f"connect = 127.0.0.1:{target_port}\n")
                f.write("cert = combined_stunnel.pem\n")
                # f.write(f"cert = {self.tls_cert}\n")
                # f.write(f"key = {self.tls_key}\n\n")
        self._logger.debug(f"Config file {self.conf_file} generated")

    def _start_stunnel(self, delay: int) -> None:
        """Start stunnel process after specified delay.

        Args:
            delay: Number of seconds to wait before starting stunnel
        """
        self._logger.debug(f"Preparing to start stunnel with {delay} second delay")
        time.sleep(delay)
        try:
            self.process = subprocess.Popen([self.stunnel_path, str(self.conf_file)],
                                          stdout=subprocess.PIPE,
                                          stderr=subprocess.PIPE)
            self.pid = self.process.pid
            self._logger.debug(f"Started stunnel process with PID {self.pid}")
        except subprocess.SubprocessError as e:
            self._logger.debug(f"Failed to start stunnel: {str(e)}")

    def _check_service(self) -> bool:
        """Check if HTTPS service is listening on configured ports.

        Returns:
            bool: True if service is available, False otherwise
        """
        self._logger.debug("Checking STUNNEL service availability")
        for port in self.https_ports:
            try:
                with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                    s.settimeout(1)
                    result = s.connect_ex(('127.0.0.1', port))
                    if result == 0:
                        self._logger.debug(f"STUNNEL Service is listening on port {port}")
                        return True
            except socket.error as e:
                self._logger.debug(f"Socket error checking port {port}: {str(e)}")
        self._logger.debug("No STUNNEL service detected on configured ports")
        return False

    def _watchdog(self) -> None:
        """Watchdog thread to monitor and restart stunnel if necessary."""
        self._logger.debug("Starting watchdog thread")
        while self._watchdog_running:
            time.sleep(self.watchdog_interval)
            if not self._check_service():
                self._logger.warning("STUNNEL service not detected, restarting stunnel")
                # Terminate existing process if it exists
                if self.process and self.pid:
                    try:
                        self.process.terminate()
                        self.process.wait(timeout=5)
                        self._logger.debug("Stunnel process terminated by watchdog")
                    except subprocess.TimeoutExpired:
                        self.process.kill()
                        self._logger.debug("Stunnel process killed by watchdog after timeout")
                    except subprocess.SubprocessError as e:
                        self._logger.debug(f"Error terminating stunnel in watchdog: {str(e)}")
                    finally:
                        self.process = None
                        self.pid = None
                # Restart stunnel
                self._start_stunnel(0)  # Restart immediately
            else:
                self._logger.debug("HTTPS service is running normally")

    def start(self, delay: int, port: int) -> threading.Thread:
        """Start stunnel process in a thread with specified delay and watchdog.

        Args:
            delay: Number of seconds to wait before starting
            port: Target port to forward connections to

        Returns:
            Thread object running the stunnel process
        """
        if self.stunnel_path == None:
            self._logger.warning(f"STUNNEL not found on host. Therefore no HTTPS port redirection will be provided.")
            return
        
        # HTTP (non-encrypted) listeners
        self.dport = port

        self._logger.debug(f"Starting stunnel with delay {delay} and target port {port}")
        self._generate_config(self.dport)
        thread = threading.Thread(target=self._start_stunnel, args=(delay,))
        thread.start()
        
        # Start watchdog
        self._watchdog_running = True
        self._watchdog_thread = threading.Thread(target=self._watchdog)
        self._watchdog_thread.name = "stunnel_watchdog"
        self._watchdog_thread.daemon = True
        self._watchdog_thread.start()
        
        self._logger.debug("Started stunnel and watchdog threads")
        return thread

    def add_http_iptables(self,source_port: int, destination_port: int):
        """This seemed like a good idea at one time, but the setup utililty does this and """
        """doing it here would require root for this process."""
        """So its not used but I kept the code if we change our minds"""
        try:
            subprocess.run([
                'iptables', '-t', 'nat', '-A', 'PREROUTING',
                '-p', 'tcp', '--dport', str(source_port),
                '-j', 'REDIRECT', '--to-port', str(destination_port)
            ], check=True)
            print(f"Forwarding added: TCP {source_port} → {destination_port}")
        except subprocess.CalledProcessError as e:
            print(f"Failed to add forwarding rule: {e}")

    def del_http_iptables(self, source_port: int, destination_port: int):
        """This seemed like a good idea at one time, but the setup utililty does this and """
        """doing it here would require root for this process."""
        """So its not used but I kept the code if we change our minds"""
        try:
            subprocess.run([
                'iptables', '-t', 'nat', '-D', 'PREROUTING',
                '-p', 'tcp', '--dport', str(source_port),
                '-j', 'REDIRECT', '--to-port', str(destination_port)
            ], check=True)
            print(f"Forwarding removed: TCP {source_port} → {destination_port}")
        except subprocess.CalledProcessError as e:
            print(f"Failed to remove forwarding rule: {e}")

    def shutdown(self) -> None:
        """Shutdown the stunnel process and clean up."""
        self._logger.debug("Shutting down stunnel")
        
        # Stop watchdog
        self._watchdog_running = False

        if self.process and self.pid:
            try:
                self.process.terminate()
                self.process.wait(timeout=5)
                self._logger.debug("Stunnel process terminated normally")
            except subprocess.TimeoutExpired:
                self.process.kill()
                self._logger.debug("Stunnel process killed after timeout")
            except subprocess.SubprocessError as e:
                self._logger.debug(f"Error shutting down stunnel: {str(e)}")
            finally:
                self.process = None
                self.pid = None
                if self.conf_file.exists():
                    self.conf_file.unlink()
                    self._logger.debug(f"Removed config file {self.conf_file}")

    def __del__(self) -> None:
        """Ensure cleanup when object is destroyed."""
        self._logger.debug("Destroying StunnelManager instance")
        self.shutdown()

# Example usage:
if __name__ == "__main__":
    # Configure logging
    logging.basicConfig(level=logging.DEBUG)
    
    # Load config
    config = configparser.ConfigParser()
    config.read('dshield.ini')
    
    # Create and start manager with 15-second watchdog interval
    manager = StunnelManager(config, watchdog_interval=15)
    thread = manager.start(delay=2, port=9000)
    
    # Wait for thread to complete
    thread.join()
    
    # Simulate some work
    time.sleep(1000)
    
    # Shutdown
    manager.shutdown()