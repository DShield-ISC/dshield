# dshield

DShield Raspberry Pi Sensor

  This is a set of scripts to setup a Raspberry Pi as a DShield Sensor.
In order to use the Raspberry Pi, you will need to first prepare it:

- CHANGE THE DEFAULT SSH PASSWORD (better: use keys to authenticate)
- expose the Pi to inbound traffic. For example, in many firewalls
  you will be able to configure it as a "DMZ Hosts"
- update your Pi. The install script will do this as well, but it can take **hours**, so you are better off doing it first. To update:

```bash
sudo apt-get update
sudo apt-get upgrade
reboot
```

only on "Jessie Lite": 
```bash
sudo apt-get install git
```

on all versions of Raspbian (including Jessie Light):

```bash
git clone https://github.com/DShield-ISC/dshield.git
sudo dshield/bin/install.sh
```

  This script will:

- enable firewall logging and submitting of logs to DShield
- change your ssh server to listen on port 12222
- install the ssh honeypot cowrie (TODO)
- configure a default web server and submit logs to DShield (TODO)

Updates:

inside your "dshield" directory (the directory created above when you run "git clone"), run

```bash
git pull
sudo bin/install.sh
```

Configuration parameters like your API Key will be retained. To edit the configuration, edit /etc/dshield.conf




DEV Instance - web.py and sitecopy.py

sitecopy.py will copy any site serve up the site in using the web.py script just use:

# python sitecopy.py http://www.yoursite.com

- It will not change the links at this time - to do
- Any data posted or user request strings will be logged to DB\webserver.sqlite

web.py - do not need to run sitecopy however it will serve up a very basic page that can accept input and files. 
Todo:
- Need to figure out how to serve up vulnerable pages - probably from the path
- SQL Injection - will likely use separate dorked database
- Would like to integrate with cowrie for shell attacks - (BHAG)

Any input appreciated - mweeks9989@gmail.com - thanks!


