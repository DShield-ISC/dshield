#!/bin/bash

URL="http://127.0.0.1:8080"

# Array of curl commands
declare -a CURL_COMMANDS=(
    "curl -i -X GET -H \"User-Agent:\" \"${URL}/\" "
    "curl -i -X GET \"${URL}/\" -H \"User-Agent: Mozilla/5.0\" -H \"Accept-Encoding: gzip\""
    "curl -i -X GET \"${URL}/something-with-cookie_1\" -H \"User-Agent: Mozilla/5.0\" -b \"Cookie_1=cookie value\""
    "curl -i -X GET \"${URL}/favicon.ico\" -H \"User-Agent: Mozilla/5.0\""
    "curl -i -X GET \"${URL}/robots.txt\" -H \"User-Agent: Googlebot\""
    "curl -i -X GET \"${URL}/sitemap.xml\" -H \"User-Agent: Bingbot\""
    "curl -i -X GET \"${URL}/about\" -H \"User-Agent: Mozilla/5.0\""
    "curl -i -X GET \"${URL}/contact\" -H \"User-Agent: Mozilla/5.0\""
    "curl -i -X GET \"${URL}/products\" -H \"User-Agent: Mozilla/5.0\""
    "curl -i -X GET \"${URL}/blog\" -H \"User-Agent: Mozilla/5.0\""
    "curl -i -X GET \"${URL}/api/v1/users\" -H \"User-Agent: PostmanRuntime/7.29.0\""
    "curl -i -X POST \"${URL}/api/v1/login\" -H \"User-Agent: python-requests/2.25.1\" -d \"{\\\"username\\\": \\\"user\\\", \\\"password\\\": \\\"pass\\\"}\""
    "curl -i -X GET \"${URL}/cart\" -H \"User-Agent: Mozilla/5.0\""
    "curl -i -X POST \"${URL}/checkout\" -H \"User-Agent: Mozilla/5.0\" -d \"{\\\"order_id\\\": 1234, \\\"payment\\\": \\\"card\\\"}\""
    "curl -i -X GET \"${URL}/page/1\" -H \"User-Agent: Googlebot\""
    "curl -i -X GET \"${URL}/page/2\" -H \"User-Agent: Bingbot\""
    "curl -i -X GET \"${URL}/static/js/main.js\" -H \"User-Agent: Mozilla/5.0\""
    "curl -i -X GET \"${URL}/static/css/styles.css\" -H \"User-Agent: Mozilla/5.0\""
    "curl -i -X POST \"${URL}/login\" -H \"User-Agent: Mozilla/5.0\" -d \"{\\\"username\\\": \\\"admin\\\", \\\"password\\\": \\\"1234\\\"}\""
    "curl -i -X POST \"${URL}/logout\" -H \"User-Agent: Mozilla/5.0\""
    "curl -i -X POST \"${URL}/contact-form\" -H \"User-Agent: Mozilla/5.0\" -d \"{\\\"name\\\": \\\"John\\\", \\\"email\\\": \\\"john@example.com\\\"}\""
    "curl -i -X GET \"${URL}/downloads/manual.pdf\" -H \"User-Agent: Mozilla/5.0\""
    "curl -i -X GET \"${URL}/ws\" -H \"User-Agent: Mozilla/5.0\" -H \"Connection: Upgrade\" -H \"Upgrade: websocket\""
    "curl -i -X GET \"${URL}/admin\" -H \"User-Agent: Mozilla/5.0\""
    "curl -i -X GET \"${URL}/health\" -H \"User-Agent: PingdomBot\""
    "curl -i -X OPTIONS \"${URL}/*\" -H \"User-Agent: Mozilla/5.0\""
    "curl -i -X GET \"${URL}/.git/config\" -H \"User-Agent: curl/7.68.0\""
    "curl -i -X GET \"${URL}/wp-config.php\" -H \"User-Agent: curl/7.68.0\""
    "curl -i -X GET \"${URL}/.env\" -H \"User-Agent: python-requests/2.25.1\""
    "curl -i -X GET \"${URL}/../../etc/passwd\" -H \"User-Agent: Mozilla/5.0\""
    "curl -i -X GET \"${URL}/%2e%2e/%2e%2e/%2e%2e/etc/passwd\" -H \"User-Agent: Mozilla/5.0\""
    "curl -i -X GET \"${URL}/search?query=' OR 1=1--\" -H \"User-Agent: Mozilla/5.0\""
    "curl -i -X GET \"${URL}/search?query=\\\" OR \\\"\\\"=\\\"\" -H \"User-Agent: Mozilla/5.0\""
    "curl -i -X GET \"${URL}/ping?cmd=whoami\" -H \"User-Agent: Mozilla/5.0\""
    "curl -i -X GET \"${URL}/api?cmd=id\" -H \"User-Agent: curl/7.68.0\""
    "curl -i -X GET \"${URL}/admin/login.php\" -H \"User-Agent: Mozilla/5.0\""
    "curl -i -X GET \"${URL}/admin/index.html\" -H \"User-Agent: Mozilla/5.0\""
    "curl -i -X GET \"${URL}/wp-admin\" -H \"User-Agent: Mozilla/5.0\""
    "curl -i -X GET \"${URL}/joomla/administrator\" -H \"User-Agent: Mozilla/5.0\""
    "curl -i -X GET \"${URL}/shell.php\" -H \"User-Agent: Mozilla/5.0\""
    "curl -i -X GET \"${URL}/cmd.php?cmd=ls\" -H \"User-Agent: Mozilla/5.0\""
    "curl -i -X GET \"${URL}/index.php?page=../../../../etc/passwd\" -H \"User-Agent: Mozilla/5.0\""
    "curl -i -X GET \"${URL}/cgi-bin/login\" -H \"User-Agent: Mozilla/5.0\""
    "curl -i -X GET \"${URL}/api/v1/configuration/users/user-roles\" -H \"User-Agent: Mozilla/5.0\""
    "curl -i -X GET \"${URL}/anything_without_user-agent\""
    "curl -i -X GET \"${URL}/remote/login\" -H \"User-Agent: Mozilla/5.0\""
    "curl -i -X GET \"${URL}/blablablbasmtp_keys.json\" -H \"User-Agent: Mozilla/5.0\""
    "curl -i -X GET \"${URL}/.git/smtp_keys.json\" -H \"User-Agent: Mozilla/5.0\""
    "curl -i -X GET \"${URL}/.git/\" -H \"User-Agent: Mozilla/5.0\""
    "curl -i -X GET \"${URL}/api/v1/login\" -H \"User-Agent: python-requests/2.25.1\" -H \"Accept-Encoding: gzip\""
)

# Iterate through each curl command with a loop
for cmd in "${CURL_COMMANDS[@]}"; do
    while true; do
        echo -e "\n\nExecuting: $cmd"
        eval "$cmd | head -n 40 -"
        echo -e "\n\nPress Enter to continue or ANY other key to repeat this request again: "
        read -n 1 -r key
        if [[ -z "$key" ]]; then  # Enter key pressed (empty input)
            break
        fi
        echo -e "\nRepeating request..."
    done
done

echo -e "\n\nAll requests completed!"