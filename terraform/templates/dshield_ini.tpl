[DShield]
interface=eth0
version=93
email=${dshield_email}
userid=${dshield_userid}
apikey=${dshield_apikey}
piid=
# the following lines will be used by a new feature of the submit code:
# replace IP with other value and / or anonymize parts of the IP
honeypotip=${public_ip}
replacehoneypotip=
anonymizeip=
anonymizemask=
fwlogfile=/var/log/dshield.log
nofwlogging=${private_ip} ${deploy_ip}
localips=${deploy_ip}
adminports=${public_ssh}
nohoneyips=${deploy_ip}
nohoneyports='2222 2223 8000'
manualupdates=0
telnet=true
