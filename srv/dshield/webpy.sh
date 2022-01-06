#!/bin/bash
# check webpy errors
lastline=$(journalctl -e -u webpy | tail -1)
lastline=${lastline#*]: }
if [ "${lastline:0:10}" = "ValueError" ] ; then
  systemctl restart webpy.service
  # echo "webpy restarted"
  exit 0
elif [ "${lastline:0:5}" = "error" ] ; then
  systemctl restart webpy.service
  # echo "webpy restarted"
  exit 0
elif [ "${lastline:8:16}" = "OperationalError" ] ; then
  systemctl restart webpy.service
  # echo "webpy restarted"
  exit 0
fi
if [ -f /tmp/wwwpy.pid ]; then
    pid=$(head -1 /tmp/wwwpy.pid)
    lsof -p $pid | grep 5u | grep -q ESTABLISHED
    [ $? -eq 0 ] && systemctl restart webpy && echo "webpy restarted; 5u ESTAB "
else
    systemctl start webpy
fi
