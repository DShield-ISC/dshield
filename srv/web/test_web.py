import requests
import argparse

# Parse command-line args for config file
parser = argparse.ArgumentParser(description="Honeypot Tester")
parser.add_argument("URL", help="Honeybot URL")
args = parser.parse_args()

BASE_URL = args.URL

def compare_bodies(expected_body, actual_body, compare_length=60):
    """
    Compare two strings and return a percentage match based on the longest common subsequence.

    Args:
        expected_body (str): The expected body string.
        actual_body (str): The actual body string.
        compare_length (int, optional): The maximum length to compare. Defaults to 60.

    Returns:
        float: The percentage match between the two strings.
    """
    expected_body = expected_body[:compare_length]
    actual_body = actual_body[:compare_length]

    if not expected_body and not actual_body:
        return 100.0  # Both empty, perfect match
    if not expected_body or not actual_body:
        return 0.0  # One is empty, no match
    
    # Convert to lowercase and strip whitespace for fair comparison
    expected_body = expected_body.lower().strip()
    actual_body = actual_body.lower().strip()
    
    # Use longest common subsequence to estimate similarity
    len_exp, len_act = len(expected_body), len(actual_body)
    if len_exp == 0 and len_act == 0:
        return 100.0
    if len_exp == 0 or len_act == 0:
        return 0.0
    
    # Simple LCS table for percentage calculation
    dp = [[0] * (len_act + 1) for _ in range(len_exp + 1)]
    for i in range(1, len_exp + 1):
        for j in range(1, len_act + 1):
            if expected_body[i-1] == actual_body[j-1]:
                dp[i][j] = dp[i-1][j-1] + 1
            else:
                dp[i][j] = max(dp[i-1][j], dp[i][j-1])
    
    lcs_length = dp[len_exp][len_act]
    # Percentage based on the longer string
    max_length = max(len_exp, len_act)
    return (lcs_length / max_length) * 100

def compare_headers(expected_headers, actual_headers):
    """
    Compare two header dictionaries and return differences.

    Args:
        expected_headers (dict): The expected headers dictionary.
        actual_headers (dict): The actual headers dictionary.

    Returns:
        dict: A dictionary containing the differences between the two header dictionaries.
    """
    differences = {
        "missing_in_actual": [],
        "missing_in_expected": [],
        "differing_values": []
    }

    # Remove headers that are automatically added so we dont check them.
    expected_headers.pop("Content-Length",'')
    expected_headers.pop("Date",'')
    actual_headers.pop("Content-Length",'')
    actual_headers.pop("Date",'')
    
    # Check keys in expected but not in actual
    for key in expected_headers:
        if key not in actual_headers:
            differences["missing_in_actual"].append(key)
        elif expected_headers[key] != actual_headers[key]:
            differences["differing_values"].append((key, expected_headers[key], actual_headers[key]))
    
    # Check keys in actual but not in expected
    for key in actual_headers:
        if key not in expected_headers:
            differences["missing_in_expected"].append(key)
    
    return differences

# Fetch real honeypotrules and handle potential errors
try:
    response = requests.get("https://dshield.org/api/honeypotrules", timeout=10)
    response.raise_for_status()  # Raise HTTPError for bad responses (4xx or 5xx)
    honeypot_data = response.json()
    signatures = honeypot_data.get("signatures", honeypot_data) if "signatures" in honeypot_data else honeypot_data
    responses = {r["id"]: r for r in honeypot_data.get("responses", [])} if "responses" in honeypot_data else {}
    if not responses:
        responses = {r["id"]: r for r in honeypot_data if "id" in r and "status" in r}
except Exception as e:
    print(f"Failed to fetch honeypotrules: {str(e)}")
    exit(1)

# Check if signatures and responses are valid
if not signatures or not responses:
    print("No valid signatures or responses in honeypotrules")
    exit(1)

# Verify the target server is reachable
try:
    requests.get(BASE_URL, timeout=1, verify=False)
except requests.ConnectionError:
    print(f"Target server {BASE_URL} is not reachable")
    exit(1)

# Test all signatures
__doc__ = (
    "This program will attempt to send a HTTP request that matches each of the signatures in the honeypotrules to "
    "the honeypot. It will compare the response to the one receive from the honeypot and confirm it matches what is in the "
    "defined response in the rules."
)

print(__doc__)

print("\nTesting all signatures from honeypotrules:")
testable_signatures = [sig for sig in signatures if "rules" in sig and "responses" in sig]

# Exit if no testable signatures are found
if not testable_signatures:
    print("No testable signatures found in honeypotrules")
    sys.exit(1)

# Iterate through testable signatures and test them
for i, test_signature in enumerate(testable_signatures, 1):
    done = False
    while not done:
        print(f"\n\n\nSignature ID: {test_signature.get('id', 'unknown')}:")

        # Default values for request parameters
        headers = {}
        cookies = {}
        path = "/test"
        method = "GET"

        # Process rules for the current signature
        for rule in test_signature["rules"]:
            attribute = rule.get("attribute")
            value = rule.get("value", "")
            condition = rule.get("condition")

            # Handle absent User-Agent header condition
            if condition == "absent" and attribute == "headers" and value == "user-agent":
                print("*" * 100)
                print("WARNING:")
                print(f'Unable to do requests without User-Agents. Use `curl -v -i -H "User-Agent:" {BASE_URL}\\???` to do it.')
                print(f"Signature: {test_signature}")
                print("*" * 100)
                path = None
                break

            # Handle contains condition
            if condition == "contains":
                value = f"/something{value}somethingelse"

            # Handle regex condition
            if condition == "regex":  # Make best effort to remove regex from value
                print(f"*** Regex rules are hard.. Ill send the following and hope it matches this regex {value}")
                value = value.replace("^", "").replace(".*", "test")
                print(f"*** Sending this value: {value}")

            # Set request parameters based on the rule
            if attribute == "path":
                path = value
            if attribute == "method":
                method = value
            if attribute == "headers":
                if ":" in value:
                    header_name, header_value = value.split(":", 1)
                    headers[header_name] = header_value if condition != "regex" else header_value.replace("^", "").replace(".*", "test")
                else:
                    headers[value] = "test-value" if condition != "regex" else value.replace("^", "").replace(".*", "test")
            elif attribute == "cookies":
                if ":" in value:
                    cookie_name, cookie_value = value.split(":", 1)
                    cookies[cookie_name] = cookie_value if condition != "regex" else cookie_value.replace("^", "").replace(".*", "test")
                else:
                    cookies[value] = "test-value" if condition != "regex" else value.replace("^", "").replace(".*", "test")

        #How that we finished each rule we are ready to send the request for the entire signature
        # If we set path to None that means we can't send the request so skip it
        if path == None:
            break

        # Send the request with headers and cookies
        print(f"Sending {method} {BASE_URL}{path} with headers: {headers} and cookies: {cookies}")
        try:
            response = requests.request(method, f"{BASE_URL}{path}", headers=headers, cookies=cookies, timeout=300, verify=False)
        except requests.RequestException as e:
            print("*"*100)
            print(f"Unable to send request or process the response as defined: {str(e)}")
            print(f"Check rules: {test_signature}")
            for eachresp in test_signature.get("responses",[]):
                print(f"Check response: {eachresp} - {responses.get(eachresp)}")
            print("*"*100)

        print(f"Resposne received {response.status_code}. Comparing resposne to expected response...")

        # Get expected responses from the signature
        expected_response_ids = test_signature.get("responses", [1])
        expected_responses = [responses.get(rid, responses.get(1)) for rid in expected_response_ids]

        # Get actual response details
        actual_status = response.status_code
        actual_body = response.text.strip()
        actual_headers = dict(response.headers)

        # Check if response matches one of the expected ones
        matched = False
        for exp_resp in expected_responses:
            exp_status = exp_resp.get("status", 200)
            exp_body = exp_resp.get("body", "").strip()
            exp_headers = exp_resp.get("headers", {})

            body_match_percentage = compare_bodies(exp_body, actual_body)
            header_differences = compare_headers(exp_headers, actual_headers)

            headers_match = ((not header_differences.get("missing_in_actual")) and
                            (not header_differences.get("differing_values")))

            if (((not exp_status) or (actual_status == exp_status)) and
                    body_match_percentage == 100.0 and
                    headers_match):
                matched = True
                break

        # Print results
        if matched:
            print("SUCCESSFUL MATCH:")
            print(f"  Actual Status: {actual_status} vs {exp_status}")
            print(f"  Body Match: {body_match_percentage:.2f}%")
            # print(f"  Actual Headers: {actual_headers}")
        else:
            print("*" * 100)
            print("FAILED TO MATCH")
            print("*" * 100)
            print(f"  Actual Status: {actual_status} (Expected: {exp_status})")
            print(f"  Body Match: {body_match_percentage:.2f}%)")
            print(f"  Actual Body: {actual_body[:200]}")
            print(f"  Expected: {exp_body[:200]}")
            print(f"  Actual Headers: {actual_headers}")
            print(f"  Expected Headers {exp_headers}")
            print(f"  Header differences: {header_differences}")
        # print(f"  Expected responses: {expected_responses}")
        done = input("PRESS ENTER to move on. Anything else to repeat") == ""
