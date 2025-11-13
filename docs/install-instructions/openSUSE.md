
# dshield

## DShield Raspberry Pi Sensor for openSUSE Tumbleweed system

This is a set of scripts to setup a Raspberry Pi as a DShield Sensor.

Current design goals and prerequisites for using the automated installation procedure:
- use of a __dedicated__ device (Raspberry Pi, any model as [per](https://isc.sans.edu/forums/diary/Using+a+Raspberry+Pi+honeypot+to+contribute+data+to+DShieldISC/22680/))
- current openSUSE system for Raspberry Pi (JeOS version will suffice)
- easy installation / configuration (and therefor not that much configurable)
- disposable (when something breaks (e.g. during upgrade): re-install from scratch)
- minimize complexity and overhead (e.g. no virtualization like docker)
- support for IPv4 only (for the internal net)
- one interface only (e.g. eth0)

The current version is tested on openSUSE Tumbleweed.

## Installation

In order to use the installation script on the Raspberry Pi, you will need to first prepare it. For openSUSE it is assumed that you are using openSUSE for this preparation.

- get the openSUSE image for your Raspberry Pi for Tumbleweed [RPi3 and RPi4 from](https://download.opensuse.org/ports/aarch64/tumbleweed/appliances/openSUSE-Tumbleweed-ARM-JeOS-raspberrypi.aarch64.raw.xz)
  
- put it onto a micro-SD card (e.g. using procedures described [here for RPi3](https://en.opensuse.org/HCL:Raspberry_Pi3) or [here for RPi4](https://en.opensuse.org/HCL:Raspberry_Pi4)
- insert the micro-SD card in the Pi and power it on, to boot the Pi from the micro-SD card.
    - the system will use DHCP to get network parameters o.a. the IP address.
- if you do not have a monitor connected you will be able to use ssh to connect.
- connect to the device using a ssh client (port 22), log in with user *root*, password *linux*
- __CHANGE THE DEFAULT PASSWORD__ for the *root* user (better: use keys to authenticate and change yes for *PermitRootLogin* to *prohibit-password* in */etc/ssh/sshd_config.d/PermitRootLogin.conf*)  

    *passwd*  
    *new pw*  
    *new pw*  

- make sure the Pi can reach out to the Internet using http(s), can resolve DNS, ... (DHCP)
- you may use the command *yast language* to set your language as the default language, the layout of the keyboard and the timezone.

- give your system a proper name with:

    echo *"dshonypot" > /etc/hostname*

- the DSield system needs to be installed from a normal user, on the **Raspberry Pi OS** there is already the account pi, but on openSUSE you need to create such an account with:

    *useradd -c 'DShield maintenace' -m -U dsmaint*

- set the password for this account with:

    *passwd dsmaint*

- this account needs a lot of sudo to generate the DShield honypot. This is best served with a sudoers definition:
    *echo "dsmaint ALL=NOPASSWD: ALL" > /etc/sudoers.d/dsmaint*
    *chmod 600 /etc/sudoers.d/dsmaint*
    
- if GIT isn't already installed (it is not installed in the JeOS images): install GIT  

    *zypper in --no-recommends git*
    
- git will download the DShield system and contains an install script to install that system. 
  - the first thing the install script will do is update the system.  
    - It is recommended to do this before running the install script.
    - For Tumbleweed the next command line will do that, after that restart the system with:  

        *zypper --non-interactive dup --no-recommends*  
        *reboot*
        or
        *shutdown -r now*
  
After this restart, you need to login as user dsmaint or as root, and become the user dsmain with:

    *su - dsmaint*

- get GIT repository  

    **git clone https://github.com/Dshield-ISC/dshield.git**

– in case you do a reinstall of a previous system, you should have saved the files `/etc/dshield.ini` and `/etc/dshield.sslca`, copy these files in the same locations; when you run the installation script answers are filled in and you only need to acknowledge the questions.


- run the installation script as user dsmaint:

    *cd dshield/bin*  
    *./install.sh*  

- if curious watch the debug log file in parallel to the installation: connect with an additional ssh session to the system and run (name of the log file will be printed out by the installation script):

    *tail -f LOGFILE*
    
- answer the questions of the installation routine
- during the execution of the installation script you will be asked for the passwords of cowrie and webhpot. You can set the passwords as root with *passwd cowrie*, or, when in dsmaint as *sudo passwd cowrie*.
- both accounts, cowrie and webhpot will be generated during the script, so you need to interrupt the viewing of the LOGFILE and set a password for both accounts, which you can enter again in the other screen, when asked for.
- if everything goes fine and the script finishes OK: reboot the device  

    *shutdown -r now*  

- from now on you have to use port 12222 to connect to the device by SSH
- WARNING: Tumbleweed runs with selinux in enforcing mode. This prevents cowrie to start using *systenctl start cowrie.service*. Use the tools of selinux, audit2iallow, to solve this issue.
- expose the Pi to inbound traffic. For example, in many firewalls and home routers
  you will be able to configure it as a "DMZ Host", "exposed devices", ... see [hints below](#how-to-place-the-dshield-sensor--honeypot) for - well - hints ...

## Background: `install.sh`

This script will:

- disable IPv6 on the Pi
- enable firewall logging and submitting of logs to Dshield
– openSUSE, from version 88 on, will use nftables instead of the depricated iptables
- change your ssh server to listen on port 12222 for you as administator (access only from configurable IP addresses)
- install the ssh honeypot cowrie (for ssh and telnet)
- install honeypot web server (isc-agent)
- install needed environment (Perl and Python3 packages, bash scripts...)

## Troubleshooting

- logs are sent twice an hour to the [dshield portal](https://www.dshield.org) by the cron job `/etc/cron.d/dshield`, this can be verified by ['My Account' -> 'My Reports'](https://www.dshield.org/myreports.html)
- have a look at the output from the status script: `/root/install/dshield/bin/status.sh`or /srv/dshield/status.sh

## Updates

### Normal Updates

Inside your "dshield" directory (the directory created above when you run `git clone`), run

*cd ~/dshield*  
*git pull*  
*bin/install.sh --update*  

The "--update" parameter will automatically use the existing configuration and not prompt the user for any configuration options.

Configuration parameters like your API Key will be retained. To edit the configuration, edit `/etc/dshield.ini`, rerun the install.sh script to configure the firewall. Editing `/etc/network/iptables` or `/etc/network/ruleset.nft` is not recommended (note: nat table is also used).

Also certificate information is saved in `/etc/dshield.sslca`.
Save these two `/etc/dshield.*` files on another system, and put these back in `/etc/` before you run the installation script, when you start allover again.

A feature is available, especially for automatic updates. At the end of the installation the install.sh script will search for the file `/root/bin/postinstall.sh` and execute its content, if it exists. If you need some extra changes in the newly installed files, this is the location to put them. This file NEEDS execute rights

Please make sure to keep special port and network configuration up to date (e.g. manually configure recently added telnet / web ports in firewall config), e.g. no-log config, no-honey config, ... unfortunately this can't be done automagically as of now. If unsure delete respective lines in `/etc/dshield.ini` and re-run the installation script.

Testing of update procedure is normally done (between two releases) as follows:
- update on Pi 3 from the last version to current
- install on a current clean image of openSUSE Tumbleweed on a Pi 4

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
- don't use Home / End

## Todos

- see README.md

## Changelog

- see comments in install.sh
- see GIT commit comments
- An earlier version did support openSUSE Leap 15.3, which is end of life. The version 15.5 has Python 3.6, which is too old to support the current version of this software, so support for openSUSE Leap has been withdrawn.

Any input appreciated - Please file a bug report / issue via github - thanks!

Slack group invite link: https://www.dshield.org/slack/

