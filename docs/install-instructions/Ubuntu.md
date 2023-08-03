Installing on Ubuntu Server 22.04 LTS
=====================================

**Via ISO Image**
Install the default version Ubuntu Server 22.04 LTS. Don't select any additional packages when prompted. During installation, create a user called "dshield."


**Deploying As VPS**
Select the appropriate Ubuntu Server 22.04 package from your provider. You won't be prompted to install additional packages or add users when using this method. You'll need to manually add a user named "dshield" here as well:

```sudo adduser dshield```

**After Completing Installation**
Upgrade the base system and ensure git and openssh-server are already installed:

```
sudo apt update && sudo apt upgrade
sudo apt install -y git openssh-server
sudo reboot
```

Finally, clone the following Git repository and run the install script. Make sure to retrieve your API key from either dshield.org or isc.sans.edu.

```
git clone https://github.com/DShield-ISC/dshield.git
sudo dshield/bin/install.sh
sudo reboot
```

For additional details, see the global README.md file.    
