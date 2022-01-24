#!/bin/bash
# this is simply a low budget, non-dialogue version of the original makecert.sh script
f=$0
f=`echo $f | sed 's/^\.//'`
f=`pwd`$f
d=`echo $f | sed -E 's/[^\/]+$//'`

if [ -f /etc/dshield.sslca ] ; then
    . /etc/dshield.sslca
    country=$Country
    state=$State
    city=$City
    company=$Company
    department=$Depart
else
    country="US"
    state="Florida"
    city="Jacksonville"
    company="DShield"
    department="Decoy"
fi
hostname=`hostname`


if [ ! -f $d/../etc/CA/keys/$hostname.key ]; then
  openssl req -sha256 -new -newkey rsa:2048 -keyout $d/../etc/CA/keys/$hostname.key -out $d/../etc/CA/requests/$hostname.csr -nodes -subj "/C=$country/ST=$state/L=$city/O=$company/OU=$department/CN=$hostname"
openssl req -in $d/../etc/CA/requests/$hostname.csr -pubkey -noout | openssl rsa -pubin -outform der | openssl dgst -sha256 -binary | base64 > $d/../etc/CA/requests/$hostname.keypin
fi

if [ ! -f $d/../etc/CA/keys/$hostname-spare.key ]; then
  openssl req -sha256 -new -newkey rsa:2048 -keyout $d/../etc/CA/keys/$hostname-spare.key -out $d/../etc/CA/requests/$hostname-spare.csr -nodes -subj "/C=$country/ST=$state/L=$city/O=$company/OU=$department/CN=$hostname"
openssl req -in $d/../etc/CA/requests/$hostname-spare.csr -pubkey -noout | openssl rsa -pubin -outform der | openssl dgst -sha256 -binary | base64 > $d/../etc/CA/requests/$hostname-spare.keypin
fi

if [ ! -f $d/../etc/CA/keys/dshieldca.key ] ; then
    openssl genrsa -aes256 -out $d/../etc/CA/keys/dshieldca.key -passout pass:raspi 4096
    openssl rsa -in $d/../etc/CA/keys/dshieldca.key -out $d/../etc/CA/keys/dshieldcanp.key -passin pass:raspi
    mv $d/../etc/CA/keys/dshieldcanp.key $d/../etc/CA/keys/dshieldca.key
fi
if [ ! -f $d/../etc/CA/certs/dshieldca.crt ]; then
    openssl req -new -x509 -days 3652 -key $d/../etc/CA/keys/dshieldca.key -out $d/../etc/CA/certs/dshieldca.crt -subj "/C=$country/ST=$state/L=$city/O=$company/OU=$department/CN=ROOT CA"
fi

# we will only sign the primary CSR, not the spare one for now.
touch ../etc/CA/index.txt

sed -r --in-place=.bak "s|^dir\s=.*$|dir = $cadir|" ../etc/openssl.cnf

openssl ca -batch -config ../etc/openssl.cnf -policy signing_policy -extensions signing_req -out ../etc/CA/certs/$hostname.crt -infiles ../etc/CA/requests/$hostname.csr    
