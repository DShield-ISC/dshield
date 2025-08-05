# Response Customizations

This document explains how to use the response customization feature to tailor honeypot responses to your specific environment. This allows you to insert dynamic values like your server's hostname, specific file paths, or other environment-specific details into the responses served by the honeypot.

## How it Works

The honeypot uses a JSON file to define key-value pairs for customization. When constructing a response (both headers and body), it searches for special tags formatted as `*{*tag_name*}*`. If a tag matches a key in the customization JSON file, the tag is replaced with the corresponding value from the file.

## Configuration

1.  **Create a Customization File:** Create a JSON file containing your desired key-value pairs. For example, you could name it `my_customizations.json`:

    ```json
    {
      "hostname": "webserver01.mydomain.local",
      "admin_email": "admin@mydomain.local",
      "internal_path": "/var/www/html/prod",
      "version": "2.1.5"
    }
    ```

2.  **Specify the File:** When running the honeypot (`isc-agent`), use the `--response` command-line argument to point to your customization file:

    ```bash
    python -m isc_agent --response my_customizations.json
    ```

    If you omit the `--response` argument, the honeypot will look for a file named `response_customizations.json` in the current working directory by default.

## Using Tags in Honeypot Rules

You can embed the tags (`*{*tag_name*}*`) directly within the `responses` defined in your honeypot rules file (e.g., `honeypotrules`). These tags can be used in both the `headers` and the `body` of a response definition.

**Example Rule Snippet:**

```json
{
  "signatures": [
    // ... other signatures ...
  ],
  "responses": {
    "1": {
      "status_code": 404,
      "headers": {
        "Server": "Apache/2.4.6 (*{*hostname*}*)",
        "Content-Type": "text/html; charset=iso-8859-1"
      },
      "body": "<!DOCTYPE HTML PUBLIC \"-//IETF//DTD HTML 2.0//EN\">\n<html><head>\n<title>404 Not Found</title>\n</head><body>\n<h1>Not Found</h1>\n<p>The requested URL was not found on this server.</p>\n<hr>\n<address>Apache/2.4.6 Server at *{*hostname*}* Port 80</address>\n</body></html>\n"
    },
    "5": {
        "status_code": 200,
        "headers": {
            "Server": "nginx/*{*version*}*",
            "X-Admin-Contact": "*{*admin_email*}*"
        },
        "body": "Welcome to *{*hostname*}*! Running version *{*version*}*."
    }
    // ... other responses ...
  }
}
```

In the example above:
*   In response `1`, `*{*hostname*}*` will be replaced with `webserver01.mydomain.local` (based on our example `my_customizations.json`) in both the `Server` header and the HTML body.
*   In response `5`, `*{*version*}*` and `*{*admin_email*}*` will be replaced accordingly.

## Special Tags

*   `*{*date*}*`: This tag is automatically handled by the honeypot and will be replaced with the current date and time of the request in the standard HTTP date format (e.g., `Sat, 06 Apr 2025 21:30:00 GMT`). You don't need to define `date` in your customization file.

By using a customization file and these tags, you can make your honeypot responses appear more realistic and specific to the environment you are simulating.
