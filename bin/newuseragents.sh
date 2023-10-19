#!/bin/bash
find /srv/db/ -name 'webhoneypot*json' -ctime +0 -exec jq '.useragent' {} \; | sort -u > /tmp/olduas
find /srv/db/ -name 'webhoneypot*json' -ctime 0 -exec jq '.useragent' {} \; | sort -u > /tmp/newuas
comm -13 /tmp/olduas /tmp/newuas > /tmp/diffuas
find /srv/db/ -name 'webhoneypot*json' -ctime 0 -exec jq '.useragent' {} \; | grep -F -f /tmp/diffuas | sort | uniq -c | sort -n > /tmp/newuacount
rm /tmp/olduas /tmp/newuas /tmp/diffuas
echo "see /tmp/newuacount for results" 
