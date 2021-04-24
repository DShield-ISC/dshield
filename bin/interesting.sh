#! /bin/sh
#
#
#interesting
#
#    #this command shows a preview of the latest downloaded files (note the file names as sha256 hashes,inode values, and timestamps) as well as the replay logs from attacks on the ssh and telnet fake-services, whcih were allowed by cowrie to be successful (replay logs):
#    #note also that the replay logs are grepable (UML compatible, user-mode-linux) even though they are not completely human-readable
#
#
#    #mroe cowrie files of interest are listed at https://github.com/cowrie/cowrie
#
#
#    interesting files... (newest 10 of each)
ls -lahit /srv/cowrie/var/lib/cowrie/tty | head -n 15
echo "\n \n"; echo " ^above are the latest 10 recorded shell replay files......^    _below are the latest 10 files downloaded into the honeypot (probablly malware), names a
re the files' sha256 sums"; echo "\n"
ls -lahit /srv/cowrie/var/lib/cowrie/downloads | head -n 15