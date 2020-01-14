Support for AWS AMI Linux is still work in progress. Please report issues.
As of the last testing, you may lose ssh access.
Please note that you need to open port 12222 using an appropriate security policy. 

```
sudo yum update
sudo yum install git
git clone https://github.com/DShield-ISC/dshield.git
sudo dshield/bin/install.sh
sudo reboot
```

To update the honeypot software, run 
```
cd ~/dshield/bin
git pull
sudo ./install.sh --udpate
```

If you very recently installed or updated the honeypot (within a few days):
```
cd ~/dshield/bin
git pull
sudo ./install.sh --update --fast
```

The "--fast" mode will skip some of the updates, package installation and security checks. If you get errors, try it without the --fast switch