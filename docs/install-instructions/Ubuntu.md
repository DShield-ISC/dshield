Installing on Ubuntu Server 24.04 LTS and 26.04 LTS
===================================================

Note: Ubuntu server versions 22.04 LTS and older are no longer supported.

**Via ISO Image**
Install the default version Ubuntu Server 24.04 LTS. Don't select any additional packages when prompted. During installation, create a user called "dshield."


**Deploying As VPS**
Select the appropriate Ubuntu Server 24.04 package from your provider. You won't be prompted to install additional packages or add users when using this method. You'll need to manually add a user named "dshield" here as well (optionally):

```
sudo adduser --disabled-password --gecos "DShield Honeypot" dshield
sudo adduser dshield sudo
```

If you installed the "minimum server": Make sure to install the editor of your choice. (for example, "sudo apt install emacs-nox").

**Optional: sudo without passwords
The "adduser" command does not configure a password for the dshield user. However, the user must have the abilitiy to use sudo. Either add a password for the "dshield" account, or modify the /etc/sudoers file:

```

```

**After Completing Installation**
Upgrade the base system and ensure git and openssh-server are already installed:

```
sudo apt update && sudo apt upgrade -y
sudo apt install -y git openssh-server
sudo reboot
```

Finally, clone the following Git repository and run the install script. Make sure to retrieve your API key from either dshield.org or isc.sans.edu.

```
sudo su - dshield
git clone https://github.com/DShield-ISC/dshield.git
dshield/bin/install.sh
sudo reboot
```

For additional details, see the global README.md file.    

Older versions required the "install.sh" script to run as "root". As of August 2025, only specific commands inside install.sh are run as root as needed. The script will prompt you for your password to use sudo as needed.
