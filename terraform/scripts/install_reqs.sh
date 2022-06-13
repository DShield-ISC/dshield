#! /bin/bash
sudo tee /etc/apt/apt.conf.d/00-local << EOF 
Dpkg::Options {
   "--force-confdef";
   "--force-confold";
}
EOF
export DEBIAN_FRONTEND=noninteractive && \
sudo -E apt update && \
sudo -E apt full-upgrade -y && \
sudo systemctl restart sshd
