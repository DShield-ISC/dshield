Use the following guide to deploy DShield honeypot onto the free compute tier (https://aws.amazon.com/ec2/?did=ft_card&trk=ft_card). This guide uses Ubuntu as Amazon has deprecated AWS Linux AMI (https://aws.amazon.com/amazon-linux-ami/#:~:text=The%20Amazon%20Linux%20AMI%20will,long%20term%20support%20through%202023.)



1. Be sure to select the region you want to launch the honeypot.




2. Navigate to EC2 service & click launch instance:



3. Select "free tier eligable" and search for Ubuntu images, select version 18.04. *Please be advised that current installer build does not work on Ubuntu 20.04:




4. Select general purpose t2.micro instance:


5. Create a new network security group and give your home public IP (in case you have static IP address from your ISP.) If you do not have statis IP address and want higher security 



6. Launch the instance and login via SSH:


7. Optional: If you're going to directly ingest logs for analysis set hostname for your honeypot using:

sudo hostnamectl set-hostname "hostname"

8. Make sure the OS is updated
sudo apt update && sudo apt full-upgrade -y


9. You will have to install Python2, Python-pip, git [may be installed by default] manually.
You may refer to: https://linuxize.com/post/how-to-install-pip-on-ubuntu-20.04/ or use the following commands:

It is advisable to be in the home directory when carrying out the following commands. (cd ~)

sudo apt update && sudo apt install python2 && sudo apt install git
curl https://bootstrap.pypa.io/get-pip.py --output get-pip.py
sudo python2 get-pip.py





9. Follow installation steps from Readme.md

mkdir install
cd install
git clone https://github.com/DShield-ISC/dshield.git
cd dshield/bin
sudo ./install.sh

