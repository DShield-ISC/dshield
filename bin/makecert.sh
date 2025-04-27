#!/bin/sh

#
# Create certificates for stunnel/web honeypot
#

interactive=$1
if [ "$interactive" = '' ]; then
    interactive=1
fi
d=$(dirname $(realpath $0))
if [ ! -f ${d}/../etc/CA/ca.serial ]; then
    serial=$(openssl rand -hex 2)
    echo -n $serial > "${d}/../etc/CA/ca.serial"
fi

if [ -f $d/../etc/dshield.sslca ] ; then
	. $d/../etc/dshield.sslca
else
	country="US"
	state="Florida"
	city="Jacksonville"
	company="DShield"
	depart="Decoy"
fi
hostname=$(hostname);
if [ "$interactive" -eq "1" ]; then
    exec 3>&1
    dialog --title 'Creating SSL Certificate' --separate-widget $'\n' --form\
		"Enter the details for your SSL Certificate" 15 50 6 \
	 "Country:"  1 4 "$country" 1 13 30 50 \
	 "State:" 2 6 "$state" 2 13 30 50 \
	 "City:" 3 7 "$city" 3 13 30 50 \
	 "Company:"  4 4 "$company" 4 13 30 50 \
	 "Depart.:"  5 4 "$depart" 5 13 30 50 \
	 "Hostname :" 6 2 "$hostname" 6 13 30 50 \
	 2>&1 1>&3 | {
	read -r country
	read -r state
	read -r city
	read -r company
	read -r department
	read -r hostname

	echo "country=\"$country\"" > $d/../etc/dshield.sslca
	echo "state=\"$state\"" >> $d/../etc/dshield.sslca
	echo "city=\"$city\"" >> $d/../etc/dshield.sslca
	echo "company=\"$company\"" >> $d/../etc/dshield.sslca
	echo "depart=\"$department\"" >> $d/../etc/dshield.sslca
	}
fi
if [ ! -f $d/../etc/CA/keys/honeypot.csr ]; then
    echo "make key and csr"
    echo "$country $state $city $company $department $hostname"
    openssl req -sha256 -new -newkey rsa:2048 -keyout $d/../etc/CA/keys/honeypot.key -out $d/../etc/CA/requests/honeypot.csr -nodes -subj "/C=$country/ST=${state}/L=${city}/O=${company}/OU=${depart}/CN=${hostname}"  2>/dev/null
fi
if [ ! -f $d/../etc/CA/keys/honeypot.key ]; then
    echo "make keypin"
    openssl req -in $d/../etc/CA/requests/honeypot.csr -pubkey -noout | openssl rsa -pubin -outform der | openssl dgst -sha256 -binary | base64 > $d/../etc/CA/requests/honeypot.keypin
fi

cadir=$d/../etc/CA


# creating key without passphrase since this is just a simple self signed certificate.
# if you want more security, then please use a "real" certificate authority or
# a proper internal CA.
if [ ! -f "${cadir}"/keys/dshieldca.key ] ; then
    openssl genrsa -aes256 -out ${cadir}/keys/dshieldca.key -passout pass:raspi 4096
    openssl rsa -in ${cadir}/keys/dshieldca.key -out ${cadir}/keys/dshieldcanp.key -passin pass:raspi
    mv "${cadir}"/keys/dshieldcanp.key "${cadir}"/keys/dshieldca.key
fi
if [ ! -f "${cadir}"/certs/dshieldca.crt ]; then
    echo "make ca cert"
    openssl req -new -x509 -days 3652 -key "${cadir}"/keys/dshieldca.key -out "${cadir}"/certs/dshieldca.crt -subj "/C=$country/ST=$state/L=$city/O=$company/OU=$depart/CN=ROOT-CA"
fi
    # we will only sign the primary CSR, not the spare one for now.
touch "${cadir}"/index.txt
echo "unique_subject = no" > "${cadir}"/index.txt.attr
sed -r "s|^dir\s=.*$|dir = $cadir|" "${d}"/../etc/openssl.template > "${d}/../etc/openssl.cnf
echo "sign cert"
openssl ca -batch -config "${d}"/../etc/openssl.cnf -policy signing_policy -extensions signing_req -out "${cadir}"/certs/honeypot.crt -infiles "${cadir}"/requests/honeypot.csr    
exec 3>&-

