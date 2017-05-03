# DShield Raspberry Pi Honeypot

This is a set of scripts to setup a Raspberry Pi as a DShield Sensor.

The current version is only tested on Raspbian, not on other distros, sorry. If other distros are wanted, someone has to check and update the installation script. For support, try our Slack channel (see link at the end of this file) . Please file an "Issue" here to report bugs.

In order to use the Raspberry Pi, you will need to first prepare it:

- CHANGE THE DEFAULT SSH PASSWORD (better: use keys to authenticate)
- make sure the Pi can reach out to the Internet using http(s)
- make sure the root file system of the Pi is properly expanded
- expose the Pi to inbound traffic. For example, in many firewalls
  you will be able to configure it as a "DMZ Hosts"
- update your Pi. The install script will do this as well, but it can take **hours**, so you are better off doing it first. To update:

```
sudo apt-get update
sudo apt-get upgrade
sudo reboot
```

only on "Jessie Lite":
- install GIT: 
```
sudo apt-get install git
```

on all versions of Raspbian (including Jessie Light):
- get the dshield files from the GIT repo
- run the installation script
```
git clone https://github.com/DShield-ISC/dshield.git
sudo dshield/bin/install.sh
```

  This script will:

- enable firewall logging and submitting of logs to DShield
- change your ssh server to listen on port 12222
- install the ssh honeypot cowrie 
- configure a default web server and submit logs to DShield (TODO)

# Updates:

Special note for updating from versions <0.4 to 0.4 (and potentially above):

The handling of Python packages changed from distro package manager to pip. This means the update is pain. Sorry for that.

You have three alternatives:

- easiest, preferred and warmly recommended way: backup old installation (if you can't stand a complete loss), reinstall from scratch using current Raspbian image
- manual procedure: uninstall all below mentioned packages and then autoremove:
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
- "automatic" brutal procedure (chances to break your system are VERY high, but hey, it's a disposable honeypot anyway ...): backup, uninstall all Python distro packages (and hope that's it):
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

Normal update: inside your "dshield" directory (the directory created above when you run "git clone"), run

```
git pull
sudo bin/install.sh
```

Configuration parameters like your API Key will be retained. To edit the configuration, edit /etc/dshield.conf.

# Todos

- see comments in install.sh
- provide a script to update all Python packages to most recent version using pip
- do all the user input stuff at the beginning of the script so it will run the long lasting stuff afterwards
- tighten the firewall 
- the PREROUTING chain contains redirects for ports, these redirects falsify dshield iptable reports because the redirect target port is reported in the logs instead of the originally probed port
- many other stuff :)

# DEV Instance - web.py and sitecopy.py

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

Any input appreciated - mweeks9989@gmail.com - thanks!

Slack group invite link: https://join.slack.com/dshieldusers/shared_invite/MTc4MTE4NzA1MTg5LTE0OTM4MTQyNzctNDQ4YTVhY2RiYQ

