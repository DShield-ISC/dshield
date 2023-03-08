# dshield


** For more detailed instructions with screen shots, see https://isc.sans.edu/honeypotinstall.pdf . **

In order to use the installation script on the Raspberry Pi, you will need to first prepare it.

- Download and install the [Raspberry Pi Imager] (https://www.raspberrypi.com/software/)
- Select "Raspberry Pi OS Lite (32-bit)" as your operating system. The default selection will work too if you prefer a GUI.
- Customize the installation by clicking on the "gear" icon in the lower right hand corner of the image.
- select "Enable SSH"
- set a username and password (use this username instead of the "pi" user)
- Optional (but recommended): Set up public-key authentication
- Select the micro SD Card as "Storage". Be careful to select the right disk.
- click "WRITE"

![Screen Shot 2022-05-02 at 10 40 51 AM](https://user-images.githubusercontent.com/1626447/166254332-0dd2be8a-0ef6-42a2-8f6d-9610b2664323.png)

- connect to the device using an ssh client (port 22), log in with user user and password you configured above.
- make sure the Pi can reach out to the Internet using http(s), can resolve DNS, ... (DHCP)
- make sure Pi's system time is somewhat reasonable, e.g.
```
date
```
if the time is "off" run (replace date with current date)
```
sudo date --set='2017-04-21 21:46:00' +'%Y-%m-%d %H:%M:%S'
```
- update your Pi. The install script will do this as well, but it can take **hours**, so you are better off doing it first. 
```
sudo apt update
sudo apt -uy dist-upgrade
```
- reboot
```
sudo reboot
```
- if GIT isn't already installed (will be the case e.g. when using the lite distro): install GIT
```
sudo apt -y install git
```
- clone the GIT repository (which will create the "dshield" directory)
```
git clone https://github.com/DShield-ISC/dshield.git
```
- run the installation script, in case you do have an earlier system, copy the files `/etc/dshield.ini` and `/etc/dshield.sslca` from that system to `/etc`; you will be able to reuse the data entered for that system.
```
cd dshield/bin
sudo ./install.sh
```
- if curious watch the debug log file in parallel to the installation: connect with an additional ssh session to the system and run (name of the log file will be printed out by the installation script):
```
sudo tail -f LOGFILE
```
- answer the questions of the installation routine
- if everything goes fine and the script finishes OK: reboot the device 
```
sudo reboot
```
- from now on you have to use port 12222 to connect to the device by SSH
- expose the Pi to inbound traffic. For example, in many firewalls and home routers
  you will be able to configure it as a "DMZ Hosts", "exposed devices", ... see [hints below](#how-to-place-the-dshield-sensor--honeypot) for - well - hints ...
