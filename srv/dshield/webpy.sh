#!/bin/bash
# check webpy errors
lastline=$(journalctl -e -u webpy | tail -1)
lastline=${lastline#*]: }
[ "${lastline:0:10}" = "ValueError" -o "${lastline:0:5}" = "error" ] && systemctl restart webpy && echo webpy restarted
