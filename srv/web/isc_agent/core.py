import re
import logging
import http.client
import urllib.parse
import json as json_module


logger = logging.getLogger("main.core")
logger.setLevel(logging.DEBUG)

class RequestsLikeResponse(object):
    """A simple response object to mimic requests.Response."""
    def __init__(self, response, headers, text):
        self.status_code = response.status  # Match requests.Response attribute
        self.reason = response.reason
        self.headers = headers
        self.text = text
    
    def json(self):
        """Mimic requests.Response.json()"""
        try:
            return json_module.loads(self.text)
        except json_module.JSONDecodeError:
            return None  # Return None if the response isn't valid JSON

#Define replacements for requests.get and requests.post
def custom_get(url, headers=None):
    """Replaces requests.get with an http.client implementation."""
    parsed_url = urllib.parse.urlparse(url)
    conn = http.client.HTTPSConnection(parsed_url.netloc)
    path = parsed_url.path or "/"
    if parsed_url.query:
        path += "?" + parsed_url.query
    
    conn.request("GET", path, headers=headers or {})
    response = conn.getresponse()
    return RequestsLikeResponse(response, dict(response.getheaders()),response.read().decode())

def custom_post(url, msg={}, headers={}, timeout=None):
    """Replaces requests.post with an http.client implementation."""
    parsed_url = urllib.parse.urlparse(url)
    conn = http.client.HTTPSConnection(parsed_url.netloc, timeout=timeout)
    path = parsed_url.path or "/"

    msg = json_module.dumps(msg)
    
    conn.request("POST", path, body=msg, headers=headers or {})
    response = conn.getresponse()
    return RequestsLikeResponse(response,dict(response.getheaders()),response.read().decode())



def score_request(req, signature):
    """
    Score how well a request matches a signature's rules.

    Args:
        req (Request): The request object.
        signature (dict): The signature dictionary.

    Returns:
        int: The total score for the request.
    """
    logger.debug(f"score_request() called with req={req}, signature={signature}")
    total_score = 0
    for rule in signature.get("rules", []):
        condition = rule.get("condition", "contains")  # Default to contains
        attribute = rule.get("attribute", "path")   # Default to path
        value = rule.get("value", "")
        score = rule.get("score", 1)

        # Get the attribute value from the request
        if attribute == "path":
            attr_value = req.path
            value_to_match = value
        elif attribute == "method":
            attr_value = req.method
            value_to_match = value
        elif attribute == "headers":
            # For headers, value can be "header_name" (contains/abesnt) or "header_name:pattern" or "pattern" (contains/absent)
            if ":" in value:
                header_name, value_to_match = value.split(":", 1)
                for k,v in req.headers.items():
                    if k.lower() == header_name:
                        attr_value = v
                        break
                else:
                    attr_value = ""
            else:
                attr_value = " ".join([f"{k}={v}" for k, v in req.headers.items()])
                value_to_match = value
        elif attribute == "cookies":
            # If cookies are in the request they are in the "Cookie" header
            attr_value = req.headers.get("Cookie","")
            value_to_match = value
        else:
            logger.debug(f"Unknown attribute: {attribute}")
            continue

        # Perform case-insensitive matching
        attr_value_lower = attr_value.lower()
        value_lower = value_to_match.lower()

        # Apply the condition
        if condition == "regex":
            if re.search(value_lower, attr_value_lower, re.IGNORECASE):
                total_score += score
        elif condition == "contains":
            #If value_to_match is blank then the header listed in "value" just needs to exist in the request headers ie contain User-Agent
            if attribute == "headers" and (value in [k.lower() for k in req.headers.keys()]) and not attr_value:
                total_score += score
            #Same with cookies
            elif attribute == "cookies" and (value in [k.lower() for k in req.cookies.keys()]) and not attr_value:
                total_score += score
            #Otherwise () we check for a string match of value in all headers/values as a string
            #This only occures when the header specified in the rule did not exist in the request
            #This allows header rules to just specify values  contains User-Agent:python
            elif value_lower in attr_value_lower:
                total_score += score
        elif condition == "equals":
            if attr_value_lower == value_lower:
                total_score += score
        elif condition == "absent":
            if attribute == "headers" and value not in [k.lower() for k in req.headers.keys()]:
                total_score += score
            elif attribute == "cookies" and value not in [k.lower() for k in req.cookies.keys()]:
                total_score += score
        else:
            logger.debug(f"Unknown condition: {condition}")
    signature_max = signature.get("max_score",float("inf"))
    signature_min = signature.get("min_score",float("-inf"))
    if total_score < signature_min:
        total_score = 0
    elif total_score > signature_max:
        total_score = signature_max
    logger.debug(f"score_request() returning {total_score}")
    return total_score
