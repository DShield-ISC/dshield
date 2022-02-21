#!/bin/bash


TERM=vt100

INTERACTIVE=1
FAST=0
BETA=0

outlog() {
  echo "${*}"
  do_log "${*}"
}

outlog "postinstall script"

run() {
  do_log "Running: ${*}"
  eval ${*} >>${LOGFILE} 2>&1
  RET=${?}
  if [ ${RET} -ne 0 ]; then
    dlog "EXIT CODE NOT ZERO (${RET})!"
  fi
  return ${RET}
}


###########################################################
## Installation of isc-agent
###########################################################

outlog"Installing web Honeypot"
dlog "installing web honeypot"

do_copy $progdir/../srv/isc-agent ${ISC_AGENT_DIR}
do_copy $progdir/../lib/systemd/system/iscagent.service ${systemdpref}/lib/systemd/system/ 644
outlog "CD to ISC-agent"
cd ${ISC_AGENT_DIR}
outlog "Pip upgrade"
run "pip3 install --upgrade pip"
outlog "Pip installation"
run "pip3 install pipenv"
#run "pip3 install twisted"
#run "pipenv lock"
outlog "Pip install requirements"
run "pipenv install --deploy"
outlog "Daemon reload"
run "systemctl daemon-reload"
outlog "Enable ISC-agent"
run "systemctl enable iscagent.service"
[ "$ID" != "opensuse" ] && run "systemctl enable systemd-networkd.service systemd-networkd-wait-online.service"
