# Honeypot Rule Testing Utilities

This document explains the purpose and usage of the Python scripts `test_web.py` and `rule_checker.py`, which are designed to help test and validate honeypot rule configurations.

## `test_web.py` - Live Honeypot Testing

### Purpose

`test_web.py` is used to perform **live testing** against a running honeypot instance. It fetches the official DShield honeypot rules (`honeypotrules`) and systematically sends HTTP requests to the target honeypot URL, attempting to trigger each signature defined in the rules.

For each signature, it constructs a request based on the signature's rules (path, method, headers, cookies) and sends it to the honeypot. It then compares the honeypot's actual response (status code, headers, body) against the expected response(s) defined for that signature in the `honeypotrules`.

This script helps verify:

*   If the honeypot correctly identifies traffic matching specific signatures.
*   If the honeypot returns the appropriate response for triggered signatures.
*   The end-to-end functionality of the honeypot based on the official rule set.

### Usage

```bash
python test_web.py <HONEYPOT_URL>
```

Replace `<HONEYPOT_URL>` with the base URL of the honeypot you want to test (e.g., `http://localhost:8080` or `https://your-honeypot.com`).

The script will output the results of each signature test, indicating whether the actual response matched the expected response. It highlights mismatches in status codes, headers, or body content.

**Note:** Some complex rules (like those involving absent User-Agent headers or complex regex) might not be perfectly testable with this script and may require manual testing (e.g., using `curl`). The script will print warnings for such cases. The file `curl_test.sh` includes examples of how to perform some of these manual `curl` tests.

## `rule_checker.py` - Rule File Analysis and Simulation

### Purpose

`rule_checker.py` is used for **static analysis and simulation** of a honeypot rule file (like `honeypotrules` or a custom version). It does *not* require a running honeypot. Instead, it analyzes the rules themselves and simulates how they would behave against a predefined set of traffic patterns.

This script helps identify:

*   **Potential rule issues:** It checks for common problems like missing attributes, unusual headers being inspected, low scores for specific path rules, overly broad 'contains' conditions, or high scores for common methods (GET/POST).
*   **Response definition completeness:** It verifies if required fields (like `id`, `status_code`, `body`, `headers`) are present in the response definitions and warns if a 'default' response is missing.
*   **Rule ambiguity:** By simulating traffic defined in a configuration file, it scores each request against all signatures and identifies which signature would "win" (get the highest score). It specifically warns if multiple signatures achieve the same highest score for a given request, indicating potential ambiguity in the rules.
*   **Rule coverage:** It shows how frequently each signature is the highest-scoring match for the simulated traffic, helping to identify rules that might be too broad (matching too often) or too narrow (never matching).

### Usage

```bash
python rule_checker.py <RULE_FILE_PATH> <TRAFFIC_CONFIG_PATH> [-d]
```

*   `<RULE_FILE_PATH>`: Path to the JSON rule file to analyze (e.g., `honeypotrules`). If the file doesn't exist, it attempts to download the latest rules from dshield.org.
*   `<TRAFFIC_CONFIG_PATH>`: Path to a JSON file containing an array of simulated requests.
*   `-d` or `--debug` (optional): Enables verbose output, showing the scores for individual signatures for each simulated request.

The script outputs warnings about potential rule issues, analyzes response definitions, and provides statistics on maximum possible scores, rule hit counts based on simulation, and the frequency of each signature being the best match.

### Creating Traffic Configuration Entries

The `<TRAFFIC_CONFIG_PATH>` file (e.g., `simulated_traffic_config.json`) is a JSON file containing a list of objects, where each object represents a simulated HTTP request. To add new test cases, simply add more objects to this list.

Each request object should have the following structure:

```json
[
  {
    "uri": "/path/to/resource",
    "method": "GET", // Optional, defaults to "GET" if omitted
    "headers": { // Optional, defaults to {}
      "User-Agent": "TestAgent/1.0",
      "Accept": "application/json",
      "X-Custom-Header": "SomeValue"
    },
    "cookies": { // Optional, defaults to {}
      "session_id": "abc123xyz",
      "user_pref": "dark_mode"
    },
    "body": { // Optional, defaults to {}
      "param1": "value1",
      "param2": "value2"
    }
  },
  {
    "uri": "/login",
    "method": "POST",
    "headers": {
        "Content-Type": "application/x-www-form-urlencoded"
    },
    "body": "username=test&password=password" // Body can also be a string
  }
  // ... more request objects
]
```

**Fields:**

*   `uri` (string, required): The request path (e.g., `/index.html`, `/api/v1/users`).
*   `method` (string, optional): The HTTP method (e.g., "GET", "POST", "PUT", "DELETE"). Defaults to "GET".
*   `headers` (object, optional): A dictionary of request headers (key-value pairs).
*   `cookies` (object, optional): A dictionary of request cookies (key-value pairs).
*   `body` (object or string, optional): The request body. Can be a JSON object or a raw string.

Create entries that specifically target the rules you want to test or simulate different types of legitimate and malicious traffic patterns.

## Complementary Roles

*   Use `rule_checker.py` **during rule development or modification** to statically analyze rules for potential issues and simulate their behavior *before* deploying them. It helps catch logical errors and ambiguities early.
*   Use `test_web.py` **after deploying rules** to a live honeypot instance to perform end-to-end testing and confirm the honeypot behaves as expected in a real-world scenario against the official DShield ruleset.
