#!/bin/sh

####
#
#  Install Script. run to configure various components
#
####

echo "Checking Pre-Requisits"
progname=$0;
progdir=`dirname $0`;
progdir=$PWD/$progdir;
cd $progdir
uid=`id -u`
if [ ! "$uid" = "0" ]; then
   echo "you have to run this script as root. eg."
   echo "  sudo install.sh"
   exit
fi

if [ ! -f /etc/os-release ] ; then
  echo "I can not fine the /etc/os-release file. You are likely not running a supported operating systems"
  echo "please email info@dshield.org for help."
  exit
fi

. /etc/os-release

if [ "$ID" != "raspbian" ] ; then
  echo "You are not running Raspbian. Your operating system identifies itself as $ID. Please ask info@dshield.org for help."
fi

if [ "$VERSION_ID" != "8" ] ; then
  echo "Your version of Raspbian is currently not supported. Please ask info@dshield.org for help (include the content of /etc/os-release)"
fi

# creating a temporary directory

TMPDIR=`mktemp -d -q /tmp/dshieldinstXXXXXXX`
trap "rm -r $TMPDIR" 0 1 2 5 15

echo "Basic security checks"

# making sure default password was changed

hashline=`grep '^pi:' /etc/shadow`
salt=`echo $x | cut -d '$' -f2-3`
shadowhash=`echo $hashline | cut -f2 -d':' | md5sum | cut -f1 -d' '`
perl -e "print crypt('raspberry','\$$salt\$')" | md5sum | cut -f1 -d ' '> $TMPDIR/passcheck
testhash=`cat $TMPDIR/passcheck`
if [ $shadowhash =  $testhash ]; then
  echo "You have not yet changed the default password for the 'pi' user"
  echo "Change it NOW ..."
  exit
fi
echo "Updating your Raspbian Installation (this can take a LOOONG time)"

apt-get update > /dev/null
apt-get upgrade > /dev/null

echo "Installing additional packages"

apt-get -y install dialog libswitch-perl libwww-perl python-twisted python-crypto python-pyasn1 python-gmpy2 python-zope.interface python-pip python-gmpy python-gmpy2 > /dev/null
pip install python-dateutil > /dev/null

: ${DIALOG_OK=0}
: ${DIALOG_CANCEL=1}
: ${DIALOG_HELP=2}
: ${DIALOG_EXTRA=3}
: ${DIALOG_ITEM_HELP=4}
: ${DIALOG_ESC=255}

export NCURSES_NO_UTF8_ACS=1



if [ -f /etc/dshield.conf ] ; then
    echo reading old configuration
    . /etc/dshield.conf
fi

# dialog --title 'DShield Installer' --menu "DShield Account" 10 40 2 1 "Use Existing Account" 2 "Create New Account" 2> $TMPDIR/dialog
# return_value=$?
# return=`cat $TMPDIR/dialog`

return_value=$DIALOG_OK
return=1

if [ $return_value -eq  $DIALOG_OK ]; then
    if [ $return = "1" ] ; then
	apikeyok=0
	while [ "$apikeyok" = 0 ] ; do
	    exec 3>&1
	    VALUES=$(dialog --ok-label "Verify" --title "DShield Account Information" --form "Authentication Information" 10 60 0 \
		       "E-Mail Address:" 1 2 "$email"   1 17 35 100 \
		       "       API Key:" 2 2 "$apikey" 2 17 35 100 \
		       2>&1 1>&3)
	    exec 3>&-
	    email=`echo $VALUES | cut -f1 -d' '`
	    apikey=`echo $VALUES | cut -f2 -d' '`
	    nonce=`openssl rand -hex 10`
	    hash=`echo -n $email:$apikey | openssl dgst -hmac $nonce -sha512 -hex | cut -f2 -d'=' | tr -d ' '`

	    user=`echo $email | sed 's/@/%40/'`
	    curl -s https://isc.sans.edu/api/checkapikey/$user/$nonce/$hash > $TMPDIR/checkapi
	    if grep -q '<result>ok</result>' $TMPDIR/checkapi ; then
		apikeyok=1;
		uid=`grep  '<id>.*<\/id>' $TMPDIR/checkapi | sed -E 's/.*<id>([0-9]+)<\/id>.*/\1/'`
	    fi	   
	done

    fi
fi
echo $uid
dialog --title 'API Key Verified' --msgbox 'Your API Key is valid. The firewall will be configured next. ' 7 40
if [ "$interface" = "" ] ; then
interface=`ip link show | egrep '^[0-9]+: ' | cut -f 2 -d':' | tr -d ' ' | grep -v lo`
fi
exec 3>&1
interface=$(dialog --title 'Default Interface' --form 'Default Interface' 10 40 0 \
		   "Honeypot Interface:" 1 2 "$interface" 1 25 10 10 2>&1 1>&3)
exec 3>&-
echo "Interface: $interface"
ipaddr=`ip addr show  eth0 | grep 'inet ' |  awk '{print $2}' | cut -f1 -d'/'`
localnet=`ip route show | grep eth0 | grep 'scope link' | cut -f1 -d' '`
exec 3>&1
localnet=$(dialog --title 'Default Interface' --form 'Default Interface' 10 50 0 \
		   "Trusted Admin Network:" 1 2 "$localnet" 1 25 20 20 2>&1 1>&3)
exec 3>&-
bash -c 'iptables-save > /etc/network/iptables'
if ! grep -q iptables-restore /etc/network/interfaces ; then
    echo "add iptables support"
    echo 'pre-up iptables-restore < /etc/network/iptables' >> /etc/network/interfaces
fi
cat > /etc/network/iptables <<EOF

*filter
:INPUT ACCEPT [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -i lo -j ACCEPT
-A INPUT -i $interface -m state --state ESTABLISHED,RELATED -j ACCEPT
-A INPUT -i $interface -s $localnet -j ACCEPT
-A INPUT -i $interface -j LOG --log-prefix " INPUT "
COMMIT
*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
-A PREROUTING -p tcp -m tcp --dport 22 -j REDIRECT --to-ports 2222
COMMIT
EOF

sed -i.bak 's/^Port 22$/Port 12222/' /etc/ssh/sshd_config

sed "s/%%interface%%/$interface/" < $progdir/../etc/rsyslog.d/dshield.conf > /etc/rsyslog.d/dshield.conf

#
# "random" offset for cron job so not everybody is reporting at once
#

offset1=`shuf -i0-29 -n1`
offset2=$((offset1+30));
cat > /etc/cron.d/dshield <<EOF
$offset1,$offset2 * * * * $progdir/dshield.pl
EOF
chmod 700 $progdir/dshield.pl


#
# Update Configuration
#

echo "uid=$uid" > /etc/dshield.conf
echo "apikey=$apikey" >> /etc/dshield.conf
echo "email=$email" >> /etc/dshield.conf
echo "interface=$interface" >> /etc/dshield.conf
echo "localnet=$localnet" >> /etc/dshield.conf

#
# installing cowrie
#

wget -qO $TMPDIR/cowrie.zip https://github.com/micheloosterhof/cowrie/archive/master.zip
unzip -qq -d $TMPDIR $TMPDIR/cowrie.zip 
if [ -d /srv/cowrie ]; then
    rm -rf /srv/cowrie
fi
mv $TMPDIR/cowrie-master /srv/cowrie

if ! grep '^cowrie:' -q /etc/passwd; then
sudo adduser --disabled-password --quiet --home /srv/cowrie --no-create-home cowrie <<EOF
Cowrie Honeypot
none
none
none
none
Y
EOF
echo Added user 'cowrie'
else
echo User 'cowrie' already exists. Making no changes
fi    


cp /srv/cowrie/cowrie.cfg.dist /srv/cowrie/cowrie.cfg
cat >> /srv/cowrie/cowrie.cfg <<EOF
[output_dshield]
userid = $uid
auth_key = $apikey
batch_size = 10
EOF

sed -i.bak 's/svr04/raspberrypi/' /srv/cowrie/cowrie.cfg
sed -i.bak 's/^ssh_version_string = .*$/ssh_version_string = SSH-2.0-OpenSSH_6.7p1 Raspbian-5+deb8u1/' /srv/cowrie/cowrie.cfg

# make output of simple text commands more real

df > /srv/cowrie/txtcmds/bin/df
dmesg > /srv/cowrie/txtcmds/bin/dmesg
mount > /srv/cowrie/txtcmds/bin/mount
ulimit > /srv/cowrie/txtcmds/bin/ulimit
lscpu > /srv/cowrie/txtcmds/usr/bin/lscpu
echo '-bash: emacs: command not found' > /srv/cowrie/txtcmds/usr/bin/emacs
echo '-bash: locate: command not found' > /srv/cowrie/txtcmds/usr/bin/locate
chown -R cowrie:cowrie /srv/cowrie

cp $progdir/../etc/init.d/cowrie /etc/init.d/cowrie
cp $progdir/../etc/logrotate.d/cowrie /etc/logrotate.d
cp $progdir/../etc/cron.hourly/cowrie /etc/cron.hourly


echo "Done. Please reboot your Pi now. For feedback, please e-mail jullrich@sans.edu or file a bug report on github"
echo
echo "IMPORTANT: after rebooting, the Pi's ssh server will listen on port 12222"
echo "           connect using ssh -p 12222 $SUDO_USER@$ipaddr"
