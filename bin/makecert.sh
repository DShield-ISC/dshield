#!/bin/sh
f=$0
f=`echo $f | sed 's/^\.//'`
f=`pwd`$f
d=`echo $f | sed -E 's/[^\/]+$//'`

hostname=`hostname`;




exec 3>&1
dialog --title 'Creating SSL Certificate' --separate-widget $'\n' --form\
		"Enter the details for your SSL Certificate" 15 50 6 \
	 "Country:"  1 4 "US" 1 13 30 50 \
	 "State:" 2 6 "Florida" 2 13 30 50 \
	 "City:" 3 7 "Jacksonville" 3 13 30 50 \
	 "Company:"  4 4 "DShield" 4 13 30 50 \
	 "Depart.:"  5 4 "Decoy" 5 13 30 50 \
	 "Hostname :" 6 2 "$hostname" 6 13 30 50 \
2>&1 1>&3 | {
    read -r country
    read -r state
    read -r city
    read -r company
    read -r department
    read -r hostname

clear
echo $country
# openssl req -sha256 -new -newkey rsa:2048 -keyout $d/../etc/$hostname.key -out $d/../etc/$hostname.csr -nodes -subj "/C=$country/ST=$state/L=$city/O=$company/OU=$department/CN=$hostname"
# openssl req -in $d/../etc/$hostname.csr -pubkey -noout | openssl rsa -pubin -outform der | openssl dgst -sha256 -binary | base64 > $d/../etc/$hostname.keypin
# openssl req -sha256 -new -newkey rsa:2048 -keyout $d/../etc/$hostname-spare.key -out $d/../etc/$hostname-spare.csr -nodes -subj "/C=$country/ST=$state/L=$city/O=$company/OU=$department/CN=$hostname"
# openssl req -in $d/../etc/$hostname-spare.csr -pubkey -noout | openssl rsa -pubin -outform der | openssl dgst -sha256 -binary | base64 > $d/../etc/$hostname-spare.keypin

dialog --title "Signing Certificate" --yesno "Would you like me to create a CA to sign the certificate? If you select \"No\", then you will be able to send the certificate to another certificate authority for signing" 10 50
if [ "$?" != "0" ]; then
    openssl genrsa -aes256 -out $d/../etc/dshieldca.key -passout pass:raspi 4096
    openssl req -new -x509 -days 3650 -key $d/../etc/dshieldca.key -out $d/../etc/dshieldca.crt -subj "/C=US/ST=Florida/L=Jacksonville/O=DShield/OU=Decoy/CN=ROOT CA"
    
fi



    }

    
exec 3>&-
