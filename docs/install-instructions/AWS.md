Overview
========
Use the following guide to deploy DShield honeypot using the [free compute tier](https://aws.amazon.com/free/).

This guide uses the Ubuntu 22.04 LTS Server AMI (Amazon Machine Image).

This guide assumes you already have an AWS account and some basic knowledge of the platform. If you need help getting started, see [this link](https://docs.aws.amazon.com/SetUp/latest/UserGuide/setup-AWSsignup.html).

Select a Region
----------------  
1. On the top right corner of the AWS console, select the region button. Using this dropdown, you can change the region that your honeypot will deploy into.  
![Image of AWS location selection for launching the honeypot](https://github.com/MHeezy/images/blob/main/aws_region_selection.png)

Create the EC2 Instance
------------------------
1. Navigate to EC2 service & select "Launch instance":  
![Launch new instance](https://github.com/MHeezy/images/blob/main/ec2_launch_instance.png)

2. Under "Names and tags", enter a name for the instance.  

3. Under "Application and OS Images", there are a number of "Quick Start" images, including Ubuntu. Select "Ubuntu" from this menu. In the dropdown below that, select "Ubuntu Server 22.04 LTS (HVM), SSD Volume Type". This is the current, tested version for dshield.
![OS Selection](https://github.com/MHeezy/images/blob/main/ubuntu_ami_selection.png)

4. Under "Instance type", the default "t2.micro" will suffice for dshield, and is free-tier eligible. For certain use cases, feel free to adjust this setting, at the risk of incurring increased costs.
![Select Instance Type](https://github.com/MHeezy/images/blob/main/aws_instance_type.png)

5. Under "Key pair (login)", it is recommended to use a key pair for secure access to your EC2 instance.
    - Select "Create new key pair"
    - In the pop-up, enter a name for the key pair
    - Select "Create key pair"  
![Key pair creation](https://github.com/MHeezy/images/blob/main/key_pair_creation.png)  
Save this key in a handy, secure location.

6. Under "Network settings", the default settings for "Network" and "Subnet" will suffice. These default settings deploy the instance in your default VPC; [read more here](https://docs.aws.amazon.com/vpc/latest/userguide/default-vpc.html). In this section, you will also see an option to "Create security group". Select this, then select the box beside "Allow SSH traffic from", and choose either "Anywhere" or your own public IP. Please note, however, that your public IP may change, requiring you to reconfigure this security group. For the time being, it will suffice to allow you to access the instance and install dshield. Once installed, dshield sets up security on Ubuntu itself, and you will need to adjust the security group to allow internet traffic to hit the instance.  
![Network settings](https://github.com/MHeezy/images/blob/main/ec2_network_settings.png)

7. Under "Configure storage", the default setting "1x 8 GiB gp2 Root volume" suffices for this use case and is free-tier eligible. Per AWS, "Free tier eligible customers can get up to 30 GB of EBS General Purpose (SSD) or Magnetic storage".

8. At the bottom of the summary window on the right side, select "Launch instance".  
![EC2 Summary](https://github.com/MHeezy/images/blob/main/ews_creation_summary.png)

9. Your EC2 instance will be launched. View completion progress by navigating to the EC2 dashboard, select "Instances", and select the Instance ID of the created instance.  
![EC2 Instances List](https://github.com/MHeezy/images/blob/main/ec2_instance_list.png)


Install dshield
----------------
1. Check your instance's public IP by navigating to the instance summary (see step 9 above).  

2. Open a terminal on a machine with SSH installed, or using a program such as PuTTY, connect to your instance's public IP address using the key pair created previously. Note that the default user created for the Ubuntu 22.04 Server is "ubuntu".  
```
ssh -i dshield.pem ubuntu@1.2.3.4
```   
   - When I tried doing this on Windows 11 Pro, I got an error: Load key "dshield.pem": bad permissions
   - Use [this guide](https://www.thewindowsclub.com/change-files-and-folders-permissions-in-windows-10) if you run into the issue on Windows 10/11.
   - On a \*nix system, doing "chmod 700" to the file should fix this error.
    

3. Optional: If you're going to directly ingest logs for analysis set hostname for your honeypot using:
```
sudo hostnamectl set-hostname "hostname"
```

4. Make sure the OS is updated
```
sudo apt update && sudo apt full-upgrade -y
```

5. You will have to install Python2, Python-pip, git [may be installed by default] manually.
You may refer: https://linuxize.com/post/how-to-install-pip-on-ubuntu-22.04/ or use the following commands:

It is advisable to be in the home directory when carrying out the following commands. (cd ~)
```
cd ~ && sudo apt update && sudo apt full-upgrade -y && sudo apt install python-pip -y && sudo apt install python3-pip -y && sudo apt update && sudo apt install python2.7 -y  && sudo apt install git -y && curl https://bootstrap.pypa.io/get-pip.py --output get-pip.py && sudo python2 get-pip.py && sudo python3 get-pip.py
```

6. Follow installation steps from Readme.md
```
mkdir install
cd install
git clone https://github.com/DShield-ISC/dshield.git
cd dshield/bin
sudo ./install.sh
```

Post-Install Notes
-------------------
Once dshield is installed, adjust security group settings to allow internet traffic to hit it.
1. Navigate to the instance's summary page
2. Select the "Security" tab
3. Select the security group name  
![Navigate to instance security group](https://github.com/MHeezy/images/blob/main/ec2_securitygroup_navigate.png)
4. On the security group page, with "Inbound rules" tab selected, select "Edit inbound rules"  
![Edit inbound rules](https://github.com/MHeezy/images/blob/main/securitygroup_edit_inbound.png)
5. For enhanced security, change the existing inbound SSH rule to "Type" -> "Custom TCP", "Port range" -> 12222, "Source" -> "My IP"
  - Recall that dshield adjusts the true SSH service to port 12222; restrict this port to only your management IP
6. To allow all internet traffic to hit the honeypot, select "Add rule", with the settings "Type" -> "All traffic", "Source" -> "Anywhere"
