# Overview of Honeypot Setup

The DShield honeypot implements a medium interaction honeypot with the ability to report data to DShield.

Currently, two different servers are used to respond to requests:
* Cowrie is used to respond to telnet and ssh requests
* web.py is used to respond to HTTP requests

We use iptables firewall rules to redirect traffic to the honeypot, and to log all incoming new connections.

A quick summary of iptables rules:
1. Do not log or modify traffic from the internal network or the administrative IPs. This is configured during setup.
2. Log everything (we do this in the "PREROUTING" chain, before NAT to log the actual destination port)
3. redirect port 22 to port 2222 (cowrie listens on port 2222 for ssh)
4. redirect port 23 and 2323 to port 2223 (cowrie listens on port 2223 for telnet)
5. redirect ports 80,8080,7547,5555,9000 to port 8000 (web.py listens on port 8000)
6. block connections to port 2222, 2223 and 8000 directly.
7. allow access to port 12222 from the internal network / management IP only. The actual ssh server for remote administration listens on port 12222.

These rules are subject to change. We add/remove redirected ports as needed.

Firewall logs end up in /var/log/dshield.log

Logs are reported to Dshield once an hour. This is done by a cron job in /etc/cron.d/dshield. It launches two scripts:
- weblogsubmit.py . This script reports web logs. 
- fwlogparser.py . This script parses logs from /var/log/dshield.log and submits them to Dshield.

The amount of bandwidth consumed by the honeypot varies widely with the traffic it receives. But as a rough guess,
the honeypot will use a couple of megabytes or less per day if it receives traffic for a single IP address.