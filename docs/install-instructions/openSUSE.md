
# dshield

## DShield Raspberry Pi Sensor for openSUSE Leap 15.3 and Tumbleweed system

This is a set of scripts to setup a Raspberry Pi as a DShield Sensor.

Current design goals and prerequisites for using the automated installation procedure:
- use of a __dedicated__ device (Raspberry Pi, any model as [per](https://isc.sans.edu/forums/diary/Using+a+Raspberry+Pi+honeypot+to+contribute+data+to+DShieldISC/22680/))
- current openSUSE system for Raspberry Pi (JeOS version will suffice)
- easy installation / configuration (and therefor not that much configurable)
- disposable (when something breaks (e.g. during upgrade): re-install from scratch)
- minimize complexity and overhead (e.g. no virtualization like docker)
- support for IPv4 only (for the internal net)
- one interface only (e.g. eth0)

The current version is tested on Raspberry Pi OS, Ubuntu 22.04 LTS Server and on openSUSE Leap 15.3 and Tumbleweed,
not on other distros, sorry.
If there is the need for other distros, "someone" has to check and maintain the installation script.

## Installation

In order to use the installation script on the Raspberry Pi, you will need to first prepare it. For openSUSE it is assumed that you are using openSUSE for this preparation.

- get the openSUSE image for your Raspberry Pi for Leap 15.3 [RPI3 from](http://download.opensuse.org/ports/aarch64/distribution/leap/15.3/appliances/openSUSE-Leap-15.3-ARM-JeOS-raspberrypi3.aarch64.raw.xz) or [RPi4 from](http://download.opensuse.org/ports/aarch64/distribution/leap/15.3/appliances/openSUSE-Leap-15.3-ARM-JeOS-raspberrypi4.aarch64.raw.xz) for Tumbleweed [RPi3 from](http://download.opensuse.org/ports/aarch64/tumbleweed/appliances/openSUSE-Tumbleweed-ARM-JeOS-raspberrypi4.aarch64.raw.xz) or [RPi4 from](http://download.opensuse.org/ports/aarch64/tumbleweed/appliances/openSUSE-Tumbleweed-ARM-JeOS-raspberrypi3.aarch64.raw.xz)
  
- put it onto a micro-SD card (e.g. using procedures described [here for RPi3](https://en.opensuse.org/HCL:Raspberry_Pi3) or [here for RPi4](https://en.opensuse.org/HCL:Raspberry_Pi4)
- insert the micro-SD card in the Pi and power it on, to boot the Pi from the micro-SD card.
    - the system will use DHCP to get network parameters o.a. the IP address.
- if you do not have a monitor connected you will be able to use ssh to connect.
- connect to the device using a ssh client (port 22), log in with user *root*, password *linux*
- __CHANGE THE DEFAULT PASSWORD__ for the *root* user (better: use keys to authenticate and set *PermitRootLogin* to *prohibit-password* in */etc/ssh/sshd_config*)  

    *passwd*  
    *new pw*  
    *new pw*  

- make sure the Pi can reach out to the Internet using http(s), can resolve DNS, ... (DHCP)
- you may use the command *yast language* to set your language as the default language, the layout of the keyboard and the timezone.
- The first thing the install script will do is update the system.  
    - For Leap 15.3 it uses:  

        *zypper up --no-recommends*  

    - For Tumbleweed use:  

        *zypper dup --no-recommends*  

- reboot  

    *shutdown -r now*
    
- if GIT isn't already installed (will be the case with the JeOS images): install GIT  

    *zypper in --no-recommends git*
    
- get GIT repository  

    <em>git clone <span>https</span>://github.com/Dshield-ISC/dshield.git<em>

– in case you do a reinstall of a previous system, you should have saved the files `/etc/dshield.ini` and `/etc/dshield.sslca`, copy these files in the same locations; when you run the installation script answers are filled in and you only need to acknowledge the questions
    
- run the installation script  

    *cd dshield/bin*  
    *./install.sh*  

- if curious watch the debug log file in parallel to the installation: connect with an additional ssh session to the system and run (name of the log file will be printed out by the installation script):

    *tail -f LOGFILE*
    
- answer the questions of the installation routine
- if everything goes fine and the script finishes OK: reboot the device  

    *shutdown -r now*  

- from now on you have to use port 12222 to connect to the device by SSH
- expose the Pi to inbound traffic. For example, in many firewalls and home routers
  you will be able to configure it as a "DMZ Hosts", "exposed devices", ... see [hints below](#how-to-place-the-dshield-sensor--honeypot) for - well - hints ...

## Background: `install.sh`

This script will:

- disable IPv6 on the Pi
- enable firewall logging and submitting of logs to Dshield
– openSUSE, from version 88 on, will use nftables instead of the depricated iptables
- change your ssh server to listen on port 12222 for you as administator (access only from configurable IP addresses)
- install the ssh honeypot cowrie (for ssh and telnet)
- install honeypot web server
- install needed environment (Perl and Python3 packages, bash scripts...)

## Troubleshooting

- logs are sent twice an hour to the [dshield portal](https://www.dshield.org) by the cron job `/etc/cron.d/dshield`, this can be verified by ['My Account' -> 'My Reports'](https://www.dshield.org/myreports.html)
- have a look at the output from the status script: `/root/install/dshield/bin/status.sh`
- if you get strange python / pip errors during installation / updates you may try the following commands as root:  
`pip freeze --local | grep -v '^\-e' | cut -d = -f 1  | xargs -n1 pip install -U`

## Updates

### Normal Updates

Inside your "dshield" directory (the directory created above when you run `git clone`), run

*cd install/dshield*  
*git pull*  
*bin/install.sh*  


Configuration parameters like your API Key will be retained. To edit the configuration, edit `/etc/dshield.ini`, rerun the install.sh script to configure the firewall. Editing `/etc/network/iptables` or `/etc/network/ruleset.nft` is not recommended (note: nat table is also used).
Also certificate information is saved in `/etc/dshield.sslca`.
Save these two `/etc/dshield.*` files on another system, and put these back in `/etc/` before you run the installation script, when you start allover again.

Please make sure to keep special port and network configuration up to date (e.g. manually configure recently added telnet / web ports in firewall config), e.g. no-log config, no-honey config, ... unfortunately this can't be done automagically as of now. If unsure delete respective lines in `/etc/dshield.ini` and re-run the installation script.

Testing of update procedure is normally done (between two releases) as follows:
- update on Pi 3 from the last version to current
- install on a current clean image of raspbian lite on a Pi 3

## Hints

### How to place the dshield sensor / honeypot

This dshield sensor and honeypot is meant to only analyze Internet related traffic, i.e. traffic which is issued from public IP addresses:
- this is due to how the dshield project works (collection of information about the current state of the Internet)
- only in this way information which is interesting for the Internet security community can be gathered
- only in this way it can be ensured that no internal, non-public information is leaked from your Pi to Dshield

So you must place the Pi on a network where it can be exposed to the Internet (and won't be connected to from the inner networks, except for administrative tasks). For a maximum sensor benefit it is desirable that the Pi is exposed to the whole traffic the Internet routes to a public IP (and not only selected ports).

For SoHo users there is normally an option in the DSL or cable router to direct all traffic from the public IP the router is using (i.e. has been assigned by the ISP) to an internal IP. This has to be the Pi. This feature is named e.g. "exposed host", "DMZ" (here you may have to enable further configuration to ensure ___all___ traffic is being routed to the Pi's internal IP address and not only e.g. port 80).

For enterprises a protected DMZ would be a suitable place (protected: if the sensor / honeypot is hacked this incident is contained and doesn't affect other hosts in the DMZ). Please be aware that - if using static IPs - you're exposing attacks / scans to your IP to the dshield project and the community which can be tracked via whois to your company.

To test your set up you may use a public port scanner and point it to the router's public IP (which is then internally forwarded to the Pi). This port scan should be directly visible in `/var/log/dshield.log` and later in your online report accessible via your dshield account. Use only for quick and limited testing purposes, please, so that dshield data isn't falsified.

### Navigating in Forms
- RETURN: submit the form (OK)
- ESC: exit the form (Cancel)
- cursor up / down: navigate through form / between input fields
- cursor left / right: navigate within an input field
- TAB: swich between input field and "buttons"
- don't use Pos 1 / End

## Todos

- see README.md

## Changelog

- see comments in install.sh
- see GIT commit comments


## DEV Instance - web.py

- It will not change the links at this time - to do
- Any data posted or user request strings will be logged to DB\webserver.sqlite

web.py - it will serve up a very basic page that can accept input and files. 
Todo:
- Need to figure out how to serve up vulnerable pages - probably from the path
- SQL Injection - will likely use separate dorked database
- Would like to integrate with cowrie for shell attacks - (BHAG)

Any input appreciated - Please file a bug report / issue via github - thanks!

Slack group invite link: https://www.dshield.org/slack/

