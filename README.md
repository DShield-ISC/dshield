# DShield

## DShield Raspberry Pi Sensor

This is a set of scripts to setup a Raspberry Pi as a DShield Sensor.

Current design goals and prerequisites for using the automated installation procedure:
- use of a __dedicated__ device (Raspberry Pi, any model as [per] (https://isc.sans.edu/diary/22680/))
- current Raspberry Pi OS ("Lite" version will suffice)
- easy installation / configuration (and therefore not that much configurable)
- disposable (when something breaks (e.g. during upgrade): re-install from scratch)
- minimize complexity and overhead (e.g. no virtualization like docker)
- support for IPv4 only (for the internal net)
- one interface only (e.g. eth0)

The current version is only tested on Raspberry Pi OS and Ubuntu 22.04 LTS Server, not on other distros, sorry.
If there is the need for other distros, "someone" has to check and maintain the installation script.

## Installation

Reference the following files for OS-specific installation instructions:
[Raspbian](docs/install-instructions/Raspbian.md) (Recommended)
[Ubuntu](docs/install-instructions/Ubuntu.md)
[openSUSE](docs/install-instructions/openSUSE.md)
[AWS](docs/install-instructions/AWS.md)

## Background: `install.sh`

This script will:

- disable IPv6 on the Pi
- enable firewall logging and submitting of logs to DShield
- change your ssh server to listen on port 12222
- install the ssh honeypot cowrie (for ssh)
- install needed environment (e.g. MySQL server, Python packages, ...)

## Troubleshooting

- logs are sent twice an hour to the [dshield portal](https://www.dshield.org) by the cron job `/etc/cron.d/dshield`, this can be verified by ['My Account' -> 'My Reports'](https://www.dshield.org/myreports.html)
- have a look at the output from the status script: `/home/pi/install/dshield/bin/status.sh`
- if you get strange python / pip errors during installation / updates you may try the following commands as root:
`pip freeze --local | grep -v '^\-e' | cut -d = -f 1  | xargs -n1 pip install -U`

## Updates

### Normal Updates

Inside your "dshield" directory (the directory created above when you run `git clone`), run
```
cd install/dshield
sudo git pull
sudo bin/install.sh --update
```
The "--update" parameter will automatically use the existing configuration and not prompt the user for any configuration options.

Configuration parameters like your API Key will be retained. To edit the configuration, edit `/etc/dshield.ini`, to configure the firewall edit `/etc/network/iptables` (note: nat table is also used).

A new feature has been introduced, especially for automatic updates. At the end of the installation the install.sh script will search for the file /root/bin/postinstall.sh and execute its content, if it exists. If you need some extra changes in the newly installed files, this is the location to put them. This file NEEDS execute rights.

Please make sure to keep special port and network configuration up to date (e.g. manually configure recently added telnet / web ports in firewall config), e.g. no-log config, no-honey config, ... unfortunately this can't be done automagically as of now. If unsure delete respective lines in `/etc/dshield.ini` and re-run the installation script.

Testing of update procedure is normally done (between two releases) as follows:
- update on Pi 3 from the last version to current
- install on a current clean image of raspbian lite on a Pi 3

### Special Update Note: Versions < 0.4 to >= 0.4

The handling of Python packages had to be changed from distro package manager to pip. This means the update is pain. Sorry for that.

You have three alternatives:

#### Easy

The easiest, preferred and warmly recommended way: backup old installation (if you can't stand a complete loss), reinstall from scratch using current Raspbian image.

#### Manual

The manual procedure: uninstall all below mentioned packages and then autoremove and cross fingers:
```
sudo su -
/etc/init.d/cowrie stop
dpkg --remove python-crypto
dpkg --remove python-gmpy
dpkg --remove python-gmpy2
dpkg --remove python-mysqldb
dpkg --remove python-pip
dpkg --remove python-pyasn1
dpkg --remove python-twisted
dpkg --remove python-virtualenv
dpkg --remove python-zope.interface
apt-get autoremove
apt-get update
apt-get dist-upgrade
```

#### Automatic

The "automatic" **brutal** procedure (chances to break your system are **VERY** high, but hey, it's a disposable honeypot anyway ...): backup (if needed), uninstall all Python distro packages (and hope that's it):
```
sudo su -
/etc/init.d/cowrie stop
for PKG in `dpkg --list | grep python- | cut -d " " -f 3 | grep "^python"` ; do echo "uninstalling ${PKG}"; dpkg --force-depends --purge ${PKG}; done
apt-get update
apt-get -f install
apt-get dist-upgrade
apt-get autoremove
apt-get update
apt-get dist-upgrade
```

## Hints

### How to place the DShield sensor / honeypot

This DShield sensor and honeypot is meant to only analyze Internet related traffic, i.e. traffic which is issued from public IP addresses:
- this is due to how the DShield project works (collection of information about the current state of the Internet)
- only in this way information which is interesting for the Internet security community can be gathered
- only in this way it can be ensured that no internal, non-public information is leaked from your Pi to DShield

So you must place the Pi on a network where it can be exposed to the Internet (and won't be connected to from the inner networks, except for administrative tasks). For a maximum sensor benefit it is desirable that the Pi is exposed to the whole traffic the Internet routes to a public IP (and not only selected ports).

For SoHo users there is normally an option in the DSL or cable router to direct all traffic from the public IP the router is using (i.e. has been assigned by the ISP) to an internal IP. This has to be the Pi. This feature is named e.g. "exposed host", "DMZ" (here you may have to enable further configuration to ensure ___all___ traffic is being routed to the Pi's internal IP address and not only e.g. port 80).

For enterprises a protected DMZ would be a suitable place (protected: if the sensor / honeypot is hacked this incident is contained and doesn't affect other hosts in the DMZ). Please be aware that - if using static IPs - you're exposing attacks / scans to your IP to the DShield project and the community which can be tracked via whois to your company.

To test your set up you may use a public port scanner and point it to the router's public IP (which is then internally forwarded to the Pi). This port scan should be directly visible in `/var/log/dshield.log` and later in your online report accessible via your DShield account. Use only for quick and limited testing purposes, please, so that DShield data isn't falsified.

### Navigating in Forms
- RETURN: submit the form (OK)
- ESC: exit the form (Cancel)
- cursor up / down: navigate through form / between input fields
- cursor left / right: navigate within an input field
- TAB: switch between input field and "buttons"
- don't use Pos 1 / End

## Todos

- see comments in `install.sh`
- provide a script to update all Python packages to most recent version using pip
- configure a default web server and submit logs to DShield
- enable other honeypot ports than ssh
- do all the user input stuff at the beginning of the script so it will run the long lasting stuff afterwards
- create update script
- move tools (e.g. `status.sh`) into `/srv` directory structure
- many other stuff :)

## Changelog

- see comments in install.sh
- see GIT commit comments


## DEV Instance - web.py and sitecopy.py

sitecopy.py will copy any site serve up the site in using the web.py script just use:

```
python sitecopy.py http://www.yoursite.com
```

- It will not change the links at this time - to do
- Any data posted or user request strings will be logged to DB\webserver.sqlite

web.py - do not need to run sitecopy however it will serve up a very basic page that can accept input and files. 
Todo:
- Need to figure out how to serve up vulnerable pages - probably from the path
- SQL Injection - will likely use separate dorked database
- Would like to integrate with cowrie for shell attacks - (BHAG)

Any input appreciated - Please file a bug report / issue via github - thanks!

Slack group invite link: https://www.dshield.org/slack/

