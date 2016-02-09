#!/usr/bin/perl

rename('/var/log/dshield.log','/var/log/dshield.log.old');
`/etc/init.d/rsyslog restart`
open(F,'/var/log/dshield.log.old');

