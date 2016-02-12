#!/usr/bin/perl

# quick script to test if the pi account is set to the default raspberry password

$user='pi';
$password='raspberry';
open(F,'/etc/shadow');
while(<F>) {
    next unless (/^$user:/ ) ;
 if ( /^\w+:\$(\d)\$([^\$]+)\$([^:]+)/ ) {
    $calchash=crypt($password,'$'.$1.'$'.$2.'$');
    if ( $calchash eq '$'.$1.'$'.$2.'$'.$3 ) {
	print "1";
	exit();
    }
 }
}
print "0";
