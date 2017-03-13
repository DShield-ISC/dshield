#!/usr/bin/perl

use strict;
use Switch;
use LWP::UserAgent;
use Digest::SHA;
use Digest::MD5;
use MIME::Base64 qw( encode_base64 decode_base64);
use Sys::Syslog;

if ( ! -f "/var/log/dshield.log" ) {
    die("No new log\n");
}

if ( $< != 0 ) {
    die("This script needs to run as root\n");
}

my ($line,$valid,$flags,$time,$src,$dst,$proto,$spt,$dpt,$linecnt,$log,$apikey,$userid,$email);

readconfig();
if ( ($apikey eq "") or ($userid eq "") or ($email eq "" )) {
    die("Incomplete configuration\n");
}


rename('/var/log/dshield.log','/var/log/dshield.log.old');
`/etc/init.d/rsyslog restart`;
open(F,'/var/log/dshield.log.old');





my $tz=`date +%z`;
chomp($tz);
while (<F>) {
    $line=$_;
    $valid=1;
    $flags='';
    switch ($line) {
	case /^([0-9]+) .* SRC=([0-9\.]+) DST=([0-9\.]+) .* PROTO=TCP SPT=([0-9]+) DPT=([0-9]+)/  {
	    $line=~/^([0-9]+) .* SRC=([0-9\.]+) DST=([0-9\.]+) .* PROTO=TCP SPT=([0-9]+) DPT=([0-9]+)/;
	    $time=$1;
	    $src=$2;
	    $dst=$3;
	    $proto=6;
	    $spt=$4;
	    $dpt=$5;
	    if ( $line=~ / FIN / ) {
		$flags.='F';
	    }
	    if ( $line=~ / SYN / ) {
		$flags.='S';
	    }
	    if ( $line=~ / RST / ) {
		$flags.='R';
	    }
	    if ( $line=~ / PSH / ) {
		$flags.='P';
	    }
	    if ( $line=~ / ACK / ) {
		$flags.='A';
	    }
	    if ( $line=~ / URG / ) {
		$flags.='U';
	    }
	    if ( $line=~ / ECE / ) {
		$flags.='1';
	    }
	    if ( $line=~ / CWR / ) {
		$flags.='2';
	    }
	}
	case /^([0-9]+) .* SRC=([0-9\.]+) DST=([0-9\.]+) .* PROTO=UDP SPT=([0-9]+) DPT=([0-9]+)/  {
	    $line=~/^([0-9]+) .* SRC=([0-9\.]+) DST=([0-9\.]+) .* PROTO=UDP SPT=([0-9]+) DPT=([0-9]+)/;
	    $time=$1;
	    $src=$2;
	    $dst=$3;
	    $proto=17;
	    $spt=$4;
	    $dpt=$5;
	}
	case /^([0-9]+) .* SRC=([0-9\.]+) DST=([0-9\.]+) .* PROTO=(\d+) /  {
	    $line=~/^([0-9]+) .* SRC=([0-9\.]+) DST=([0-9\.]+) .* PROTO=(\d+) /;
	    $time=$1;
	    $src=$2;
	    $dst=$3;
	    $proto=$4;
	    $spt=0;
	    $dpt=0;
	}
	else {
	    $valid=0;
	    print "ERROR $line\n";
	}

    }
    if ( $valid==1 ) {
	my @time=localtime($time);
	$time[5]+=1900;
	$time[4]++;
	
	$linecnt++;
	$time=sprintf('%04d-%02d-%02d %02d:%02d:%02d',$time[5],$time[4],$time[3],$time[2],$time[1],$time[0]);
    	$log.="$time $tz\t$userid\t1\t$src\t$spt\t$dst\t$dpt\t$proto\t$flags\n";
    }
}
submit();

sub submit() {
    my $ua=LWP::UserAgent->new;
    my $nonce=Digest::SHA::hmac_sha256(rand(99999999),$$);
    my $hash=Digest::SHA::hmac_sha256_base64(decode_base64($apikey),$nonce.$userid);
    $nonce=encode_base64($nonce);
    my $header= "credentials=$hash nonce=$nonce userid=$userid";
    $ua->timeout(10);
    $ua->ssl_opts(verify_hostname=>1);
    $ua->ssl_opts(SSL_ca_path=>'/etc/ssl/certs');
    $log="From: $email
Subject: FORMAT DSHIELD USERID $userid AUTHKEY $apikey TZ $tz CLIENTNAME RASPI Version 0.2

".$log;
    print "Submitting Log\nLines: $linecnt Bytes: ".length($log)."\n";
    openlog('dshield.pl','cons,pid','user');
    syslog('info',"submitting dshield logs $linecnt line ".length($log)." bytes");
    my $req=new HTTP::Request('PUT','https://secure.dshield.org/api/file/dshieldlog');
    $req->header('X-ISC-Authorization',$header);
    print $header."\n";
    $req->header('Content-Type','text/plain');
    $req->header('Content-Length',length($log));
    $req->content($log);
    open(LOG,"> /tmp/debug.log");
    print LOG $log;
    close LOG;
    print "Sending Request\n";
    my $result=$ua->request($req);
    print "Done\n";
    if ($result->is_success) {
	my $return=$result->decoded_content;
	print $return."\n";
	$return=~/<bytes>(\d+)<\/bytes>/;
	my $receivedbytes=$1;
	if ( $receivedbytes !=length($log) ) {
	    print "\nERROR: Size Mismatch\n";
            syslog('error',"submitting dshield logs size mismatch");
	} else {
	    print "Size OK ";
	}
	$return=~/<sha1checksum>([^<]+)<\/sha1checksum>/;
	my $receivedsha1=$1;
	if ( $receivedsha1 ne Digest::SHA::sha1_hex($log) ) {
            syslog('error',"submitting dshield logs SHA1 mismatch");
	    print "\nERROR: SHA1 Mismatch $receivedsha1 ".Digest::SHA::sha1_hex($log)."\n";
	} else {
            syslog('info',"submitting dshield logs SHA1 ok");
    	    print "SHA1 OK ";
	}
	$return=~/<md5checksum>([^<]+)<\/md5checksum>/;
	my $receivedmd5=$1;
	if ( $receivedmd5 ne Digest::MD5::md5_hex($log) ) {
	    print "\nERROR: MD5 Mismatch $receivedmd5 ".Digest::MD5::md5_hex($log)."\n";
	} else {
	    print "MD5 OK\n";
	}
    }
    else {
	syslog('LOG_ERR','dshield log submission http error'.$result->status_line);
	die $result->status_line;
    }
    print "---\n";
}

sub readconfig() {
    my ($key,$value);
    open(C,'/etc/dshield.conf');
    while ( <C> ) {
	($key,$value)=split(/=/,$_,2);
	chomp($value);
	switch($key) {
	    case 'uid' { $userid=$value;}
	    case 'email' {$email=$value;}
	case 'apikey' {$apikey=$value;}
	}
    }
}
unlink('/var/log/dshield.log.old');
