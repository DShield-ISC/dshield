import json
import requests
import pathlib
import sys
import argparse
import logging
import logging.handlers

from requests import Request
from collections import defaultdict

from isc_agent.core import score_request

logger = logging.getLogger("main")
logger.setLevel(logging.DEBUG)

formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')

# File handler
fh = logging.handlers.WatchedFileHandler("rule_checker.log")
fh.setLevel(logging.DEBUG)
fh.setFormatter(formatter)
logger.addHandler(fh)

# Stream handler
sh = logging.StreamHandler()
sh.setLevel(logging.INFO)
sh.setFormatter(logging.Formatter('%(message)s'))
logger.addHandler(sh)


# Parse command-line arguments
parser = argparse.ArgumentParser(description="Rule File Analyzer")
parser.add_argument("rule_file", help="Rule File to Analyse.")
parser.add_argument("traffic_config", help="JSON file containing the traffic generation signatures for testing rules.")
parser.add_argument("-d", "--debug", action="store_true", help="Pass this to verbosely show the scores of individual signatures.")
args = parser.parse_args()
logger.debug(f"rule_checker.py called with args={args}")


class Fake_Request(object):
    """
    A fake request object for testing rules.
    """
    def __init__(self, uri, method="get", headers={}, cookies={}, body={}):
        """
        Initialize the Fake_Request object.

        Args:
            uri (str): The URI of the request.
            method (str, optional): The HTTP method of the request. Defaults to "get".
            headers (dict, optional): The headers of the request. Defaults to {}.
            cookies (dict, optional): The cookies of the request. Defaults to {}.
            body (dict, optional): The body of the request. Defaults to {}.
        """
        logger.debug(f"Fake_Request() called with uri={uri}, method={method}, headers={headers}, cookies={cookies}, body={body}")
        self.path = uri
        self.method = method
        self.headers = headers
        self.cookies = cookies
        self.headers["Cookie"] = ";".join([f"{k}={v}" for k,v in cookies.items()])
        self.body = str(body)
    def __repr__(self):
        return f"{self.method} {self.path} headers: {self.headers} cookies: {self.cookies} body: {self.body}"

# Load simulated traffic config
fh = pathlib.Path(args.traffic_config)
if fh.is_file():
    simulated_traffic_config = json.loads(fh.read_text())
else:
    logger.error("No simulated traffic config found")
    sys.exit(1)

# Load rules data
fh = pathlib.Path(args.rule_file)
if fh.is_file():
    rules_data = json.loads(fh.read_text())
else:
    logger.debug("Getting honeypot rules from dshield.org")
    response = requests.get("https://dshield.org/api/honeypotrules")
    rules_data = response.json()
    logger.debug(f"Got rules from dshield.org: {rules_data}")

# Extract signatures (a list, not a dict)
signatures = rules_data["signatures"]
responses = rules_data['responses']

# Step 1: Calculate maximum possible score for each signature
max_scores = {}
for sig in signatures:
    sig_id = sig["id"]
    max_score = sum(rule["score"] for rule in sig["rules"])
    max_scores[sig_id] = max_score

# Identify rules with bad header names or missing parts
top_30_http_headers = ['accept', 'accept-encoding', 'accept-language', 'cache-control', 'connection', 'content-length', 'content-type', 'cookie', 'host', 'user-agent', 'authorization', 'referer', 'origin', 'if-modified-since', 'if-none-match', 'dnt', 'upgrade-insecure-requests', 'sec-fetch-dest', 'sec-fetch-mode', 'sec-fetch-site', 'sec-fetch-user', 'date', 'server', 'etag', 'last-modified', 'location', 'set-cookie', 'vary', 'x-forwarded-for', 'x-requested-with']
for sig in signatures:
    sig_id = sig["id"]
    assert "rules" in sig, f"All signatures must have rules.  See signature {sig_id}"
    for rule in sig["rules"]:
        assert "attribute" in rule, f"All rules must have attribute.  See {rule.items()}"
        assert "value" in rule, f"All rules must have value.  See {rule.items()}"
        value = rule.get("value")
        if rule.get("attribute")=="headers":
            if ":" in value:
                value = value.split(":")[0]
            if value not in top_30_http_headers:
                logger.warning("Rule is inspecting an unusual header.  Are you sure this is right?")
                logger.warning(f"  - {str(rule)}")
        assert "condition" in rule, f"All rules must have conditions.  See {rule.items()}"
        # Add more code here to identify conditions and checks that match to much as we figure that out.
        if rule.get("attribute") == "path" and (len(rule.get("value")) > 3) and (rule.get("score") < 10):
            logger.warning(f"Rules base on a full URI (path) should be given 10 points or more.\nSignature {sig}\n")
        if rule.get("condition") not in ['equals','contains','absent','regex']:
            logger.warning(f"Rules has an invalid condition. Must be equals,contains,absent or regex.\nSignature {sig}\n")
        if rule.get("condition") == "contains" and len(value) < 4:
            logger.warning(f"Rule {rule.get('id')} uses 'contains' on a small string <4! \n Signature {sig}\n")
        if (rule.get("attribute") == "method") and rule.get("value").lower() in ["get","post"] and rule.get("score") > 1:
            logger.warning(f"Scoring more than 1 point on a GET or POST is not recommended. \nSignature {sig}\n")

#Check responses
default_response = False
for resp in responses:
    if resp.get("id",'') == 'default':
        default_response = True
    required_response_keys = ['body','headers','id','status_code']
    different = set(required_response_keys).difference(set(resp.keys())) 
    if different:
        if different == {'status_code'}:
            logger.warning(f"Response {resp.get('id',resp)} has no status_code define. Will default to 200.")
        else:
            logger.warning(f"Response {resp.get('id',resp)} is missing a required signature fields: {different}")
    # There are not required headers in the responses... use this code if you change your mind.
    # required_header_keys = ['Server']
    # different = set(required_header_keys).difference(set(resp.get("headers",{}).keys())) 
    # if different:
    #     logger.warning(f"Response {resp.get('id',resp)} is missing a required headers {different}")
if not default_response:
    logger.warning("No 'default' response is defined. Default is a response id 1.")


# Simulate traffic and track highest-scoring signatures
simulated_traffic = []
for traffic_item in simulated_traffic_config:
    simulated_traffic.append(Fake_Request(**traffic_item))

highest_scores = dict( [(sig.get("id") , 0) for sig in signatures] )  #initial score 0 for all signatures
for request in simulated_traffic:
    scores = {}
    for sig in signatures:
        sig_id = sig["id"]
        score = score_request(request, sig)
        scores[sig_id] = score
    best_sig = max(scores, key=scores.get)
    
    #If the best signture has a score of ZERO then it didn't match anything.
    if scores[best_sig] == 0:
        logger.info(f" -- Default signature will be used for non-matching request: {request}")
        continue

    highest_scores[best_sig] += 1
    high_score = highest_scores[best_sig]


    logger.info(f"For simulated traffic : {request}")
    logger.info(f"Scores are: {scores} - Winner: {best_sig}")

    #Check for rule abiguity
    abiguous_scores = {}
    for sig,score in scores.items():
        if score == high_score:
            abiguous_scores[sig] = score
    if len(abiguous_scores) > 1:
        logger.warning(f"Abiguous rules detected.  More than 1 rule ({list(abiguous_scores.keys())}) match {request}")
     


# Output results
logger.info("\n\nMaximum Possible Scores:")
for sig_id, max_score in max_scores.items():
    logger.info(f"  Signature {sig_id}: {max_score}")

#Print rule hit count
logger.info("\nHit counts of rules with simulated traffic")
for k,v in highest_scores.items():
    logger.info(f"  Signature {k}: Matched {v} requests.")

logger.info("\nFrequency of Each Signature Being the Best Match:")
for sig_id, count in highest_scores.items():
    freq = count / len(simulated_traffic) * 100
    analysis = "OK" if (freq != 0) and (freq < 75) else "BAD!!!!"
    logger.info(f"  Signature {sig_id}: {freq:.2f}%  {analysis}")

logger.info("Set signature max_score to 0 to disable the signature.")
logger.info("Use the signatures min_score to enforce 'and' 'or' logic")
logger.info("Finished rule_checker.py")
