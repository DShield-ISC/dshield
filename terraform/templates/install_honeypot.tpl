#! /bin/bash
cd ~/
mkdir install
cd install
git clone https://github.com/DShield-ISC/dshield.git
cd dshield/bin
mv /tmp/makecert2.sh makecert.sh
chmod +x makecert.sh
sudo ./install.sh --upgrade
if [ ${output_logging} = true ]; then
  chmod +x /tmp/enable_logging.sh
  sudo /tmp/enable_logging.sh
fi
sudo reboot
