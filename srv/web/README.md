# Web Honeypot

A lightweight, configurable HTTP honeypot written in Python to detect and respond to malicious web requests. This project simulates a web server to attract and log potential attackers, using customizable rules and responses loaded from a local file or the DShield API.

## Overview

This web honeypot listens for HTTP requests (GET, POST, HEAD, PUT, DELETE) and matches them against predefined signatures to determine the appropriate response. It can operate in single-threaded mode for debugging or multi-threaded mode for production, making it versatile for both development and deployment scenarios. The project is designed to be simple yet extensible, with support for custom response headers, bodies, and cookies.

## Features

- **HTTP Request Handling**: Supports multiple HTTP methods (GET, POST, HEAD, PUT, DELETE).
- **Configurable Rules**: Loads honeypot signatures and responses from a local JSON file (`honeypotrules`) or the DShield API (`https://dshield.org/api/honeypotrules`).
- **Scoring System**: Uses a scoring mechanism (via `score_request` from `core`) to match requests to signatures.
- **Dual Modes**:
  - **Debug Mode**: Single-threaded server for easy troubleshooting.
  - **Production Mode**: Multi-threaded server for handling concurrent requests.
- **HTTP/1.1 Compliance**: Properly formatted responses with `Content-Length` headers to ensure compatibility with modern clients.
- **Customizable Responses**: Supports dynamic response generation with placeholders for headers, bodies, and cookies.
- **IP Anonymization**: IP addresses configured in dshield.ini are optionally anonymized
- **Dshield Integration**: Responses are automatically collected and uploaded to dshield.org and shared with the community
- **stunnel https proxy**: If stunnel is installed it is automatically configured and used for https proxing to the http port.
- **syslog integration**: Data is logged through the syslog service.
- **zipapp distribution**: Distributed as a zipapp so no installation is required
- **cross platform compatibility**: Linux (of course), Mac (check), Windows (ok, but why, I mean yes!)

## Prerequisites

- Python 3.6+
- No additional requirement if you use the zipapp

To run as source you will also need to install:
  - `requests` (for interactions DShield API)
  
## Installation

### From zipapp (One of the following 2 options)
1. **Download or build and run the zipapp**
    - Download from releases [Here](https://github.com/DShield-ISC/dshield/releases)

2. **Build the zipapp**
   - If the a release is unavailable or you want the latest changes you can build the zipapp from the repository. As a zipapp the web honeypot can easily be moved to any system with python along with your `dshield.ini` and run without an installation process. To build a zipapp do the following:

    ```
    git clone http://github.com/Dshield-isc/dshield
    cd dshield/srv/web
    ./build_zipapp.sh
    ```

    This will create a portable zipapp file name `./isc_agent.pyz`.

### From Source (Follow these steps)
1. **Clone the Repository**:
   ```bash
   git clone https://github.com/Dshield-ISC/dshield.git
   cd dshield/srv/web
   ```

2. **Install Dependencies**:
   Install the required Python package:
   ```bash
   pip install requests
   ```


## Usage

### Running the Honeypot as a zipapp:

  As a zipapp absent the normal installation process you will have to specify the path to the dshield.ini.

  ```bash
  python ./isc_agent.pyz -h
  python ./isc_agent.pyz -c ./dshield.ini
  ```
  

### Running the Honeypot as source code:
  To run from source point the python interpreter at the isc_agent directory (not at a python program):
  ```bash
  cd /srv/web
  python3 ./isc_agent -h
  ```

### Configuration
  The honeypot reads settings from a config file. By default the tool will prefer `/srv/dshield/etc/dshield.ini` if it exists. If it does not exist it uses `/etc/dshield.ini`.  A location can be forced with the `-c` command line argument.

  ```bash
  python3 ./isc_agent.pyz -c dshield.ini
  ```

  - The specified init file must contain a valid APIKEY and UserID. These are free.  See isc.sans.edu.
  - The tool listens for http on port `8000`. This is not configurable. It uses `stunnel` listing on `8443` to forward https to 8000. This is also not configurable. All public listening ports are handled by port forward IPTABLES rules are configured by `install.sh` based on ports in the `dshield.ini`. 

  The specified init file can have the following optional values specified:

  ```
  [plugin:tcp:http]
  dshield_url=https://www.dshield.com/submitapi   
  enable_local_logs=true                         
  local_logs_file=/home/student/locallog.json     
  submit_logs_rate=300                            
  queue_size_submit_trigger=100                   
  web_log_limit=1000                                           
  web_log_purge_rate=2                           
  ```

  - dshield_url   - Override the default submit url.
  - enable_local_logs - When true local logs will be recorded 
  - local_logs_file - Specify the path for the local logs (default /srv/log/isc-agent.out)
  - submit_logs_rate - Frequency that local logs are submitted to ISC (seconds)
  - queue_size_submit_trigger - When local log size reaches this submit to ISC is auto triggered
  - web_log_limit - If local queue reaches this size items are dropped                
  - web_log_purge_rate - Number of items to drop from queue when web_log_limit is exceeded. 2 means every other, 3 every third, etc

  You can also provide a local file that provides customizations that are specific to your instance using the `--response customizations.json` command line argument. For full details on this see [Customizations](./CUSTOMIZATIONS.md)

### Testing

- Access the server via a browser or `curl`:
  ```bash
  curl -v http://localhost:8000
    ```
- Observe the debug output in the terminal to see request details and scores.
- For live testing of your honeypot with the current rule test see `test_web.py` in the [Rules Testing Document](./RULES_TESTING.md)

### Customizing Rules

- Contribute your rules and suggestions to ISC! Create a `honeypotrules` JSON file in the same directory to override the default DShield API rules. Example format:
  ```json
  {
    "signatures": [
      {
        "id": 1,
        "pattern": "/admin",
        "responses": [1]
      }
    ],
    "responses": [
      {
        "id": 1,
        "status_code": 200,
        "body": "Welcome to the fake admin page!",
        "headers": {"Server": "FakeServer/1.0"}
      }
    ]
  }
    ```

  - For a full explaination of the rules see [RULES](./RULES.md). 
  
  - After creating your rules be sure to check them using the rules checker as described in [RULES TESTING Document](./RULES_TESTING.md)


---
