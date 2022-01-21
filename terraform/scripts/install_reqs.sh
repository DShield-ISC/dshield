#! /bin/bash
sudo apt update && \
sudo apt full-upgrade -y && \
#sudo apt install python3.7 -y && \
#sudo update-alternatives  --set python /usr/bin/python3.7 && \
#sudo apt update && \
#curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output get-pip2.py && \
#curl https://bootstrap.pypa.io/pip/get-pip.py --output get-pip3.py && \
#sudo python2 get-pip2.py && \
#sudo python3 get-pip3.py && \
sudo systemctl restart sshd
