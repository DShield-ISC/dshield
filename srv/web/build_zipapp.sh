#!/bin/bash

#Install requests in isc_agent folder
pip install --target ./isc_agent requests


#make the zipapp
python3 -m zipapp ./isc_agent

#Remove all the subdirectories (installed modules) after zipapp is built.
find ./isc_agent -mindepth 1 -type d -exec rm -rf {} +

