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

### From zipapp
1. **Download and run the zipapp**
    - Download from releases [Here](https://github.com/DShield-ISC/dshield/releases)

    `python3 ./isc_agent.pyz`

### From Source
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

### Running the Honeypot

- **As a zipapp**:
  After downloading the zipapp .pyz launch it and pass any desired command line argument:
  ```bash
  python ./isc_agent.pyz -h
  ```
  The server will start on port `8000` and (if stunnel is installed) will start a stunnel instance to terminate TLS traffic on `8443` and forward it to port 8000.

- **As source code**:
  To run from source point the python interpreter at the isc_agent directory (not at a python program):
  ```bash
  cd ./srv/web
  python3 ./isc_agent
    ```

- **Custom Configuration**:
  Specify a different config file using the `-c` flag. If no option is specified it will look for the file /etc/dshield.ini:
  ```bash
  python ./isc_agent.pyz -c dshield.ini
    ```

The specified init file must contain a valid APIKEY and UserID. 

The specified init file can have the following optional values specified:

```
[plugin:tcp:http]
dshield_url=https://www.dshield.com/submitapi   #Override the default submit url.
enable_local_logs=true                          #When true local logs will be recorded 
local_logs_file=/home/student/locallog.json     #Specify the path for the local logs
submit_logs_rate=300                            #Frequency that local logs are submitted to ISC (seconds)
queue_size_submit_trigger=100                   #When local log size reaches this submit to ISC is auto triggered
web_log_limit=1000                              #If local queue reaches this size items are dropped                
web_log_purge_rate=2                            #Number of items to drop from queue when web_log_limit is exceeded 2 means every other, 3 every third, etc
```

  You can also provide a local file that provides customizations that are specific to your instance using the `--response customizations.json` command line argument.  For full details on this see [Customizations](./CUSTOMIZATIONS.md)

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


## Configuration

The honeypot reads settings from a config file (default: `/etc/dshield.ini`):
- The tool listens for http on port `8000`.
- It uses `stunnel` listing on `8443` to forward https to 8000 

This tool really only works if you have a dshield API key. Those are free.  Contact us for a key.


---
*Maintained by [Mark Baggett](https://github.com/markbaggett). Last updated: April 2025.*
