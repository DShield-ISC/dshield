#!/usr/bin/perl

use Switch;

#rename('/var/log/dshield.log','/var/log/dshield.log.old');
# `/etc/init.d/rsyslog restart`
open(F,'/var/log/dshield.log');

##
#  TCP
# 1455032630 raspberrypi kernel:[ 1159.158107] INPUT IN=eth0 OUT= MAC=b8:27:eb:99:8b:40:00:50:b6:7e:14:50:08:00:45:10:00:34:01:62:40:00:40:06:22:50 SRC=10.5.1.17 DST=10.5.1.232 LEN=52 TOS=0x10 PREC=0x00 TTL=64 ID=354 DF PROTO=TCP SPT=57982 DPT=12222 WINDOW=4094 RES=0x00 ACK URGP=0
#  UDP
#                                              INPUT IN=eth0 OUT= MAC=ff:ff:ff:ff:ff:ff:68:a8:6d:0b:7f:80:08:00:45:00:01:48:c5:5c:00:00:ff:11:f5:48 SRC=0.0.0.0 DST=255.255.255.255 LEN=328 TOS=0x00 PREC=0x00 TTL=255 ID=50524 PROTO=UDP SPT=68 DPT=67 LEN=308
#
##

while (<F>) {
    $line=$_;
    switch ($line) {
	case /^([0-9]+) .* SRC=([0-9\.]+) DST=([0-9\.]+) .* PROTO=TCP SPT=([0-9]+) DPT=([0-9]+)/  {
	    $time=$1;
	    $src=$2;
	    $dst=$3;
	    $proto=6;
	    $spt=$4;
	    $dpt=$5;
	    if ( $line=~ / ACK / ) {
		$flags='A';
	    }
	    if ( $line=~ / SYN / ) {
		$flags.='S';
	    }
	    if ( $line=~ / RES/ && ! $line=~/ RES=0x00/ ) {
		$flags.='R';
	    }
	    if ( $line=~ / RES=0x00 / ) {
		$flags.='R';
	    }
	}
	case /^([0-9]+) .* SRC=([0-9\.]+) DST=([0-9\.]+) .* PROTO=UDP SPT=([0-9]+) DPT=([0-9]+)/  {
	    $time=$1;
	    $src=$2;
	    $dst=$3;
	    $proto=17;
	    $spt=$4;
	    $dpt=$5;
	}
	else {
	    print "ERROR $line\n";
	    
	}
    }
    print "$time $src $dst $proto $spt $dpt\n";

}


