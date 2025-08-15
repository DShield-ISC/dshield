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
started but should be created within a few minutes if your honeypot is
exposed. Check if the later test, "webserver exposed," passed.

If "webserver exposed" passed, but there is still no dshield.log, reboot the honeypot. If there is still no dshield.log after 10
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

Missing this file usually indicates a failed install. Reinstall the honeypot.

## /etc/dshield.ini

Missing this file usually indicates a failed install. Reinstall the honeypot.

## /srv/cowrie/cowrie.cfg

Missing this file usually indicates a failed install. Reinstall the honeypot.

## ip-firewall rules

see /var/log/dshield.log

## isc-agent running error

### Quick Fix ###

If the last line of /srv/log/isc-agent.err is ```ModuleNotFoundError: No module named 'twisted'``` try:

```
cd /srv/isc-agent
source virtenv/bin/activate
virtualenv virtenv --no-setuptools
pip install -r requirements.txt
reboot
```

if the last line of /srv/log/isc-agent.err is ```TypeError: conlist() got an unexpected keyword argument 'min_items'``` try:

```
sudo su -
cd /srv/isc-agent/
source virtenv/bin/activate
pip uninstall pydantic
pip install pydantic==1.10
reboot
```

If that doesn't work, see below or send the content of /srv/log/isc-agent.err to handlers@isc.sans.edu.

### Details ###

Check the file ```/srv/log/isc-agent.err```. It should display any startup errors. Often, the issue is caused by a missing Python module. For example:

```
Traceback (most recent call last):
  File "/srv/isc-agent/./isc-agent.py", line 5, in <module>
    from twisted.internet import reactor
ModuleNotFoundError: No module named 'twisted'
```
In this case, the module "twisted" is missing or can not be loaded for some reason.

isc-agent is using a virtual environment. For additional debugging (or fixing), activate the environment
```
cd /srv/isc-agent
source virtenv/bin/activate
```
The prompt should now change to ```(virtenv) root@honeypot:/srv/isc-agent``` (instead of "honeypot", you will see your hostname)

Try to install the missing module. For example:

```
pip install twisted
```

If yout get the error ```ModuleNotFoundError: No module named 'pip'```, run:

```
virtualenv virtenv --no-setuptools
```

(careful. Run this in the /srv/isc-agent directory, not anywhere else)

Next, try again:

```
pip install twisted
```

Now try to start isc-agent again while still in the activated virtual environments:

```
./isc-agent.py
```

If you see an additional missing module, try first to reinstall the entire requirements.txt file:

```
pip install -r requirements.txt
```

If successful, you should see this line:

```
DEBUG :: 2023-10-19 13:57:52,064 :: <PID 1180:MainProcess> :: __main__ :: L:19 :: http options: {'protocol': 'tcp', 'name': 'http', 'http_ports': [8000], 'https_ports': [8443], 'submit_logs_rate': 300}
```

Exit with CTRL-C and reboot the honeypot to check if it works again.


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



