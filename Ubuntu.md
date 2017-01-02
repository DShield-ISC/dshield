Installing on Ubuntu Server 16.04 LTS
=====================================

Install default Ubuntu Serve 16.04 LTS. Do not select any packages other then default. During install, create a user called "dshield".

After install, upgrade the base system, and install git and openssh-server (git should already be installed, but just in case we run apt install for it again):

```
sudo apt update
sudo apt upgrade
sudo apt install git
sudo apt install openssh-server
sudo reboot
```

After the reboot, clone this git repository, and run the install script:

```
git clone https://github.com/DShield-ISC/dshield.git
sudo dshield/bin/install.sh
```



