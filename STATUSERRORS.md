# Help with errors from status.sh

The honeypot includes a script, /srv/dshield/status.sh, which will assist
in debugging errors. You will need to run it as root. A typical output
should look like:

```
OK: /var/log/dshield.log
OK: /etc/cron.d/dshield
OK: /etc/dshield.ini
OK: /srv/cowrie/cowrie.cfg
OK: /etc/rsyslog.d/dshield.conf
OK: ip-firewall rules
OK: isc-agent running
OK: webserver exposed
OK: webserver configuration
OK: diskspace ok
OK: correct interface
```

Here are some tips to fix any errors:

## /var/log/dshield.log

This file contains the firewall logs. It will be created as soon as your
honeypot receives traffic. It may be missing right after the honeypot is
started, but should be created within a few minutes if your honeypot is
exposed. Check if the later test, "webserver exposed", passed.

If "webserver exposed" passed, but there is still no dshield.log, start
by rebooting the honeypot. If there is still no dshield.log after 10
minutes, check if the firewall rules are configured correctly.

Run: ```iptables -L -n -t nat | grep DSHIELDLOG```. The output should look
like:

```
# iptables -L -n -t nat | grep DSHIELDLOG
DSHIELDLOG  all  --  0.0.0.0/0            0.0.0.0/0            state INVALID,NEW
Chain DSHIELDLOG (1 references)
```

(for some operating systems, nft is used instead of iptables.
Please ask for additional help if your system uses nft)

## /etc/cron.d/dshield

missing this file usally indicates a failed install. Reinstall the honeypot.

## /etc/dshield.ini

missing this file usally indicates a failed install. Reinstall the honeypot.

## /etc/cowrie/cowrie.cfg

missing this file usally indicates a failed install. Reinstall the honeypot.

## /etc/cowrie/cowrie.cfg

missing this file usally indicates a failed install. Reinstall the honeypot.

## ip-firewall rules

see /var/log/dshield.log

## isc-agent running

[more debugging steps needed here]

## webserver exposed

The honeypot is not reachable from the internet. This is almost always
a problem with your router configuration. Make sure the router is configured
to expose the honeypot. The honeypot will not work if your ISP uses NAT and
does not assign you a routable IP address

## webserver configuration

most errors here are fixed with a reboot

## diskspace

if the disk is more than 80% full, this will display an error. You can
either ignore it, or delete old logs.

## correct interface

[more debugging needed here]



