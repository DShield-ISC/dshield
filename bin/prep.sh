#!/bin/bash

####
#
# Pre-Install Script. Not needed but makes the install go quicker
# use for demos
#
####

userid=`id -u`
if [ ! "$userid" = "0" ]; then
   echo "You have to run this script as root. eg."
   echo "  sudo ./prep.sh"
   echo "Exiting."
   echo ${LINE}
   exit 9
fi

apt update
apt -y -q dist-upgrade
apt install -y -q python3-pip build-essential curl dialog gcc git libffi-dev libmpc-dev libmpfr-dev libswitch-perl libwww-perl python-dev python2.7-minimal python3-minimal randomsound rng-tools unzip libssl-dev python3-virtualenv authbind python3-requests python3-urllib3 zip wamerican jq libmariadb-dev-compat python3-virtualenv sqlite3 dialog rng-tools jq 

pip install --upgrade pip
pip install --upgrade bcrypt
pip install --upgrade requests
pip install --upgrade -r requirements.txt
pip install --upgrade -r requirements-output.txt
