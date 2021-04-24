#! /bin/sh
#
#This 'replay' script is just a shortcut essentially to useing the built-in playlog.py (python script) from cowrie
#
#    usage "$HOME/install/dshield/bin/replay.sh [file name of reply file]"
#    ...it is not necessary to supply the full path of the replay file name
#
#
#TODO:  check first for python versions
#
#TODO: add content for doing --usage / help also as error correction
#
#    replay:
python3 /srv/cowrie/bin/playlog /srv/cowrie/var/lib/cowrie/tty/"$1"