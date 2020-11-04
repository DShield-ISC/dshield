#!/bin/sh
f=$0
f=`echo $f | sed 's/^\.//'`
f=`pwd`$f
d=`echo $f | sed -E 's/[^\/]+$//'`

if [ -f /etc/dshield.sslca ] ; then
	. /etc/dshield.sslca
else
	Country="US"
	State="Florida"
	City="Jacksonville"
	Company="DShield"
	Depart="Decoy"
fi
hostname=`hostname`;

exec 3>&1
dialog --title 'Creating SSL Certificate' --separate-widget $'\n' --form\
		"Enter the details for your SSL Certificate" 15 50 6 \
	 "Country:"  1 4 "$Country" 1 13 30 50 \
	 "State:" 2 6 "$State" 2 13 30 50 \
	 "City:" 3 7 "$City" 3 13 30 50 \
	 "Company:"  4 4 "$Company" 4 13 30 50 \
	 "Depart.:"  5 4 "$Depart" 5 13 30 50 \
	 "Hostname :" 6 2 "$hostname" 6 13 30 50 \
2>&1 1>&3 | {
    read -r country
    read -r state
    read -r city
    read -r company
    read -r department
    read -r hostname

if [ ! -f /etc/dshield.sslca ] ; then
	echo "Country=\"$country\"" > /etc/dshield.sslca
	echo "State=\"$state\"" >> /etc/dshield.sslca
	echo "City=\"$city\"" >> /etc/dshield.sslca
	echo "Company=\"$company\"" >> /etc/dshield.sslca
	echo "Depart=\"$department\"" >> /etc/dshield.sslca
fi
echo $country
if [ ! -f $d/../etc/CA/keys/$hostname.key ]; then
    openssl req -sha256 -new -newkey rsa:2048 -keyout $d/../etc/CA/keys/$hostname.key -out $d/../etc/CA/requests/$hostname.csr -nodes -subj "/C=$country/ST=$state/L=$city/O=$company/OU=$department/CN=$hostname"
    openssl req -in $d/../etc/CA/requests/$hostname.csr -pubkey -noout | openssl rsa -pubin -outform der | openssl dgst -sha256 -binary | base64 > $d/../etc/CA/requests/$hostname.keypin
fi
if [ ! -f $d/../etc/CA/keys/$hostname-spare.key ]; then
    openssl req -sha256 -new -newkey rsa:2048 -keyout $d/../etc/CA/keys/$hostname-spare.key -out $d/../etc/CA/requests/$hostname-spare.csr -nodes -subj "/C=$country/ST=$state/L=$city/O=$company/OU=$department/CN=$hostname"
    openssl req -in $d/../etc/CA/requests/$hostname-spare.csr -pubkey -noout | openssl rsa -pubin -outform der | openssl dgst -sha256 -binary | base64 > $d/../etc/CA/requests/$hostname-spare.keypin
fi

cadir=$d/../etc/CA


dialog --title "Signing Certificate" --yesno "Would you like me to create a CA to sign the certificate? If you select \"No\", then you will be able to send the certificate to another certificate authority for signing" 10 50




if [ $? -eq 0  ]; then

    
    # creating key without passphrase since this is just a simple self signed certificate.
    # if you want more security, then please use a "real" certificate authority or
    # a proper internal CA.
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
    
fi



    }

    
exec 3>&-
clear
