#!/bin/sh

userid=$(id -u)
if [ ! "$userid" = "0" ]; then
    echo "you need to run this script as root"
    exit
fi
python3 /srv/isc-agent/main.py
