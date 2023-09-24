#!/bin/bash
find /srv/db/ -name 'webhoneypot*json' -ctime +0 -exec jq .url {} \; | grep -F -f commonurls.txt -v | sort -u > /tmp/oldurls
find /srv/db/ -name 'webhoneypot*json' -ctime 0 -exec jq .url {} \; | grep -F -f commonurls.txt -v | sort -u > /tmp/newurls
comm -13 /tmp/oldurls /tmp/newurls > /tmp/diffurls
find /srv/db/ -name 'webhoneypot*json' -ctime 0 -exec jq '.url' {} \; | grep -F -f /tmp/diffurls | sort | uniq -c | sort -n > /tmp/newurlcount
rm /tmp/oldurls /tmp/newurls /tmp/diffurls
echo "see /tmp/newurlcount for results"

