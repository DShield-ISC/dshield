# Troubleshooting

Run "sudo /srv/dshield/status.sh"

## Missing /var/log/dshield.log

First, wait a bit longer (10 minutes) after a reboot for attacks to arrive. But most likely, your system is not exposed to the internet. Check your router/firewall configuration to ensure that the host's IP is properly exposed.

## ERROR: isc-agent not running

first try (as root!):

```
curl https://sh.rustup.rs -sSf | sh
cd /srv/isc-agent
source ./virtenv/bin/activate
pip3 install -r ./requirements.txt
```

and reboot. If you still get the "isc-agent not running" error... proceed.

check the error log:

cat /srv/log/isc-agent.err

if you see "ModuleNotFoundError: No module named 'twisted'": Something is wrong with the installed python modules

Verify the error by running the agent "manual". The output should match the output of isc-agent.err:

```
sudo su -
cd /srv/isc-agent
source ./virtenv/bin/activate
python3 ./isc-agent.py
```

run (and ignore the errors about running it as root.

```python pip3 install twisted``` 

## ModuleNotFoundError: No module named 'requests'

```pip3 install requests```

## ModuleNotFoundError: No module named 'sqlalchemy'

run

```sudo pip3 install sqlalchemy```

and ignore any warnings about running pip as root.

## Plugin tcp:http not found

In this case, the isc-agent is actually running






