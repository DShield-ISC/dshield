# Signatures

Signatures are defined as JSON documents. Each document may contain one or more signatures. Each signature will contain at least a "sigid" and one or more conditions. Each condition, if it matches, is assigned a point value and the points are added up for each signature. The signature with the most points is the one that is used.

The default score for each condition is 1. Negative scores are possible to deduct points.

## signatureid

An integer > 0. ("0" is the "default" signature if no signature matches). This number has to be unique.

## port

The port the request is received on. A web server may listen on multiple ports, and return different content on different ports.

## method

This item has two properties:
value: which method (GET, POST, PUT, TRACE...)
score: the score assigned if it matches

## version

used to match the HTTP version
value: 1, 1,*, 1.1, 2 (a "string")
score: score to assign if value matches

## url

type: what type of match. Possible are "exact", "contains" and "regex"
value: the string to look for (or regex)
score: the score to assign if the url matches the condition

## header

A list of one or more headers to match
For each header name, there is a type, a value and a score. , just like for the url above.

headers also have the "present" and "absent" type to check if a header exists or does not exist.

Example:

```
[
  {
    "ruleid": "1",
    "port": {
      "value": "80",
      "score": 1
    },
    "method": {
      "value": "GET",
      "score": 5
    },
    "url": {
      "type": "contains",
      "value": "wp-admin",
      "score": 10
    },
    "header": {
      "user-agent": {
        "type": "regex",
        "value": "^python.*",
        "score": 1
      },
      "accept-encoding": {
        "type": "present",
        "score": 2
      }
    }
  },
  {
    "ruleid": "2",
    "url": {
      "type": "contains",
      "value": "$jndi",
      "score": 10
    }
  },
  {
    "ruleid": "3",
    "header": {
      "user-agent": {
        "type": "contains",
        "value": "$jndi"
      }
    }
  }
]
```
