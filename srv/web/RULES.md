# Honeypot Rules Documentation (RULES.md)

This document explains the structure and syntax for defining signatures, rules, and responses within the `honeypotrules` file used by the ISC Agent honeypot.

## Overall Structure

The `honeypotrules` file is a JSON object containing two main top-level keys:

1.  `signatures`: An array of signature objects. Each signature defines a set of rules to identify specific types of requests.
2.  `responses`: An array of response objects. Each response defines the HTTP response to be sent back when a signature triggers it.

```json
{
  "signatures": [ ... ],
  "responses": [ ... ]
}
```

## Signatures

Each signature object in the `signatures` array defines a pattern to match against incoming HTTP requests.

**Signature Components:**

*   `id` (integer, required): A unique identifier for the signature.
*   `min_score` (integer, required): The minimum total score required from the rules within this signature for it to be considered a match. If the sum of scores from matching rules is less than `min_score`, the signature does not match.
*   `max_score` (integer, optional): The maximum possible score for this signature. If the calculated score exceeds this value, it will be capped at `max_score`. Defaults to infinity if not specified.
*   `responses` (array of integers, required): A list of `id`s corresponding to the response objects in the `responses` array. When a signature matches, one of these responses will be chosen (currently, the system seems to pick the first one listed if multiple signatures match, but the exact selection logic might depend on the agent's implementation).
*   `rules` (array of objects, required): A list of rule objects that define the conditions for matching the signature.
*   `comment` (string, optional): A description of the signature's purpose.

**Example Signature:**

```json
{
  "id": 1,
  "max_score": 10,
  "min_score": 5,
  "responses": [
    2
  ],
  "rules": [
    {
      "condition": "regex",
      "attribute": "headers",
      "value": "user-agent:^python.*",
      "score": 2
    },
    {
      "condition": "contains",
      "attribute": "headers",
      "value": "accept-encoding",
      "score": 3
    }
  ]
}
```
*This signature (ID 1) requires a minimum score of 5. It looks for requests with a User-Agent header starting with "python" (case-insensitive regex, score 2) AND the presence of an "Accept-Encoding" header (score 3). If both match, the total score is 5, meeting the `min_score`, and response ID 2 is triggered.*

## Rules

Each rule object within a signature's `rules` array specifies a single condition to check against the incoming request.

**Rule Components:**

*   `condition` (string, required): The type of comparison to perform. Defaults to `contains` if omitted.
*   `attribute` (string, required): The part of the HTTP request to examine. Defaults to `path` if omitted.
*   `value` (string, required): The value to compare against the specified attribute, using the specified condition. The format depends on the `attribute` and `condition`.
*   `score` (integer, required): The points added to the signature's total score if this rule matches. Defaults to 1 if omitted.

**Rule Attributes (`attribute`):**

*   `path`: The request path (e.g., `/index.html`, `/api/users`).
    *   Example: `{"condition": "equals", "attribute": "path", "value": "/.git/", "score": 10}` (from signature 10)
*   `method`: The HTTP method (e.g., `GET`, `POST`, `HEAD`).
    *   Example: `{"condition": "equals", "attribute": "method", "value": "GET", "score": 1}` (used in multiple signatures)
*   `headers`: Checks against request headers. The `value` format determines the check:
    *   `"header_name"`: Checks if the header `header_name` exists (used with `contains` or `absent`). Case-insensitive.
        *   Example (`contains`): `{"condition": "contains", "attribute": "headers", "value": "accept-encoding", "score": 3}` (from signature 1) - Matches if `Accept-Encoding` header is present.
        *   Example (`absent`): `{"condition": "absent", "attribute": "headers", "value": "user-agent", "score": 70}` (from signature 5) - Matches if `User-Agent` header is *not* present.
    *   `"header_name:pattern"`: Checks the value of the specified `header_name` against the `pattern` using the rule's `condition`. Case-insensitive matching for both header name and value comparison.
        *   Example (`equals`): `{"condition": "equals", "attribute": "headers", "value": "user-agent:PostmanRuntime/7.29.0", "score": 2}` (from signature 2) - Matches if `User-Agent` header value is exactly `PostmanRuntime/7.29.0`.
        *   Example (`regex`): `{"condition": "regex", "attribute": "headers", "value": "user-agent:^python.*", "score": 2}` (from signature 1) - Matches if `User-Agent` header value starts with `python`.
    *   `"pattern"` (without colon): Checks if the `pattern` exists within the combined string of *all* header names and values (e.g., `"Host=example.com User-Agent=curl/7.68.0"`). This is less common and typically used with `contains`.
*   `cookies`: Checks against request cookies (extracted from the `Cookie` header). Similar logic to `headers`:
    *   `"cookie_name"`: Checks if the cookie `cookie_name` exists (used with `contains` or `absent`). Case-insensitive.
    *   `"cookie_name=pattern"`: Checks the value of the specified `cookie_name` against the `pattern`. Case-insensitive.
        *   Example (`contains`): `{"condition": "contains", "attribute": "cookies", "value": "Cookie_1", "score": 9}` (from signature 3) - Matches if a cookie named `Cookie_1` exists. *Note: This example seems to check for the presence of the name, not a specific value.* To match a value, it would likely be `"Cookie_1=somevalue"`.
    *   `"pattern"` (without equals): Checks if the `pattern` exists within the raw `Cookie` header string.

**Rule Conditions (`condition`):**

*All comparisons are performed case-insensitively.*

*   `equals`: The attribute's value must exactly match the rule's `value`.
    *   Example: `{"condition": "equals", "attribute": "method", "value": "GET", "score": 1}`
*   `contains`: The attribute's value must contain the rule's `value` as a substring.
    *   For `headers` and `cookies`, if `value` is just a name (no `:` or `=`), it checks for the *presence* of that header/cookie name.
    *   Example: `{"condition": "contains", "attribute": "path", "value": "api/v1/configuration", "score": 100}` (adapted from signature 6)
    *   Example (Header Presence): `{"condition": "contains", "attribute": "headers", "value": "accept-encoding", "score": 3}`
*   `regex`: The attribute's value must match the regular expression provided in the rule's `value`. Uses Python's `re.search` with `re.IGNORECASE`.
    *   Example: `{"condition": "regex", "attribute": "headers", "value": "user-agent:^python.*", "score": 2}`
*   `absent`: The rule matches if the specified header or cookie name in `value` is *not* present in the request. Only applicable when `attribute` is `headers` or `cookies`.
    *   Example: `{"condition": "absent", "attribute": "headers", "value": "user-agent", "score": 70}`

## Responses

Each response object in the `responses` array defines a complete HTTP response.

**Response Components:**

*   `id` (integer, required): A unique identifier for the response, referenced by signatures.
*   `status_code` (integer, required): The HTTP status code to return (e.g., 200, 404, 403).
*   `headers` (object, required): A dictionary of HTTP headers to include in the response (e.g., `{"Content-Type": "text/html", "Server": "Apache"}`).
*   `body` (string, required): The content of the response body. Can be HTML, JSON, plain text, etc.
*   `comment` (string, optional): A description of the response.

**Example Response:**

```json
{
  "id": 4,
  "comment": "SonicWall SSL-VPN Appliance index page",
  "status_code": 200,
  "headers": {
    "Server": "SonicWALL SSL-VPN Web Server",
    "Content-Security-Policy": "script-src 'self' 'unsafe-eval';object-src 'self';style-src 'self' 'unsafe-inline';img-src 'self' data:;frame-src 'self';frame-ancestors 'self';default-src 'self'",
    "X-FRAME-OPTIONS": "SAMEORIGIN",
    "X-XSS-Protection": "1; mode=block",
    "Referrer-Policy": "strict-origin",
    "X-Permitted-Cross-Domain-Policies": "master-only",
    "Feature-Policy": "accelerometer 'none'; ambient-light-sensor 'none'; autoplay 'none'; camera 'none'; encrypted-media 'none'; fullscreen 'self'; geolocation 'self'; gyroscope 'none'; magnetometer 'none'; microphone 'self'; midi 'none'; payment 'none'; picture-in-picture 'none'; speaker 'none'; sync-xhr 'self'; usb 'none'; vr 'none'; xr-spatial-tracking 'none';",
    "Permissions-Policy": "accelerometer=(), geolocation=(), gyroscope=(), magnetometer=(), payment=()",
    "X-Content-Type-Options": "nosniff",
    "Cache-Control": "private, no-cache, no-store, no-transform, proxy-revalidate",
    "Pragma": "no-cache",
    "Content-Type": "text/html; charset=UTF-8"
  },
  "body": "<HTML>\n<HEAD>\n<meta http-equiv=\"Content-Type\" content=\"text/html;charset=UTF-8\">\n<meta http-equiv=\"refresh\" content=\"0; URL=/cgi-bin/login\">\n</HEAD>\n<BODY> </BODY>\n</HTML>"
}
```
*This response (ID 4) simulates a SonicWall index page, returning a 200 OK status with specific headers and a simple HTML body that redirects the client.*

## Scoring Logic

When a request comes in, it's evaluated against each signature:

1.  The `score_request` function iterates through the `rules` of a signature.
2.  For each rule, it checks if the `condition` is met for the specified `attribute` and `value`.
3.  If a rule matches, its `score` is added to a running `total_score` for that signature.
4.  After checking all rules, the `total_score` is compared against the signature's `min_score` and optional `max_score`.
5.  If `total_score >= min_score`, the signature is considered a match.
6.  If `total_score > max_score` (and `max_score` is defined), the score is capped at `max_score`.
7.  If the signature matches, its associated `responses` are potential candidates to be sent back to the client.

## Creating a New Signature and Response

1.  **Define the Response:** Create a new response object in the `responses` array. Give it a unique `id`, define the `status_code`, `headers`, and `body` you want to send back. Add an optional `comment`.
2.  **Define the Signature:** Create a new signature object in the `signatures` array.
    *   Assign a unique `id`.
    *   Set the `responses` array to include the `id` of the response you just created.
    *   Determine the `min_score` required to trigger this signature.
    *   Optionally set a `max_score`.
    *   Add `rules` to identify the target requests:
        *   Choose the `attribute` (path, method, headers, cookies).
        *   Choose the `condition` (equals, contains, regex, absent).
        *   Specify the `value` to match against.
        *   Assign a `score` to the rule. Add multiple rules to create more specific matching criteria.
3.  **Test:** Send requests that should match (and not match) your new signature to verify it works as expected and triggers the correct response.
