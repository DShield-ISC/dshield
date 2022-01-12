Use the following guide to deploy DShield honeypot using the free compute tier (https://aws.amazon.com/ec2/?did=ft_card&trk=ft_card). This guide uses Ubuntu as Amazon has deprecated AWS Linux AMI (https://aws.amazon.com/amazon-linux-ami/#:~:text=The%20Amazon%20Linux%20AMI%20will,long%20term%20support%20through%202023.)



1. **Be sure to select the region you want to launch the honeypot.**
![Image of AWS location selection for launching the honeypot](https://github.com/parthdmaniar/images/blob/master/1_selecting_location.png)

2. **Navigate to EC2 service & click launch instance:**
![Launch new instance](https://github.com/parthdmaniar/images/blob/master/3_launch_instance.png)


3. **Select "free tier eligible" and search for Ubuntu images, select version 18.04. *Please be advised that current installer build does not work on Ubuntu 20.04:**
![OS Selection](https://github.com/dlee35/images/blob/main/dshield/2_OS_Selection.png)

4. **Choose a general-purpose t2.micro instance along with storage size of your preference:**
![instance_selection](https://github.com/parthdmaniar/images/blob/master/4_ec2_instance_selection.png)
![disk_selection](https://github.com/parthdmaniar/images/blob/master/5_ec2_disk_selection.png)


5. **Create a new network security group and give your home public IP (in case you have a static IP address from your ISP.) full access. If you do not have static IP address and want higher security add your renewed IP address when accessing the honeypot.**
![Initial_network_configuraiton](https://github.com/parthdmaniar/images/blob/master/6_ec2_network_security_rules.png)
![full_AWS_network_security_configuraiton](https://github.com/parthdmaniar/images/blob/master/7_ec2_network_security_rules_detailed.png)


6. **Launch the instance and login via SSH**


7. **Optional: If you're going to directly ingest logs for analysis set hostname for your honeypot using:**

```
sudo hostnamectl set-hostname "hostname"
```

8. **Make sure the OS is updated**
```
sudo apt update && sudo apt full-upgrade -y
```

9. **You will have to install Python2, Python-pip, git [may be installed by default] manually.**
You may refer: https://linuxize.com/post/how-to-install-pip-on-ubuntu-20.04/ or use the following commands:

It is advisable to be in the home directory when carrying out the following commands. (cd ~)
```
cd ~ && sudo apt update && sudo apt full-upgrade -y && sudo apt install python-pip -y && sudo apt install python3-pip -y && sudo apt update && sudo apt install python2.7 -y  && sudo apt install git -y && curl https://bootstrap.pypa.io/get-pip.py --output get-pip.py && sudo python2 get-pip.py && sudo python3 get-pip.py
```

9. **Follow installation steps from Readme.md**
```
mkdir install
cd install
git clone https://github.com/DShield-ISC/dshield.git
cd dshield/bin
sudo ./install.sh
```
