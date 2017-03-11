#!/bin/sh

####
#
#  Install Script. run to configure various components
#
####

version=0.2

echo "Checking Pre-Requisites"
progname=$0;
progdir=`dirname $0`;
progdir=$PWD/$progdir;
cd $progdir
userid=`id -u`
if [ ! "$userid" = "0" ]; then
   echo "You have to run this script as root. eg."
   echo "  sudo install.sh"
   exit
fi

if [ ! -f /etc/os-release ] ; then
  echo "I can not find the /etc/os-release file. You are likely not running a supported operating systems"
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


if $progdir/passwordtest.pl | grep -q 1; then
  echo "You have not yet changed the default password for the 'pi' user"
  echo "Change it NOW ..."
  exit
fi
echo "Updating your Raspbian Installation (this can take a LOOONG time)"

# apt-get update > /dev/null
# apt-get upgrade > /dev/null

echo "Installing additional packages"


apt-get -y -qq install mini-httpd dialog libswitch-perl libwww-perl python-twisted python-crypto python-pyasn1 python-gmpy2 python-zope.interface python-pip python-gmpy python-gmpy2 mysql-client randomsound rng-tools python-mysqldb > /dev/null

#
# yes. this will make the random number generator less secure. but remember this is for a honeypot
#

echo HRNGDEVICE=/dev/urandom > /etc/default/rnd-tools

pip install python-dateutil > /dev/null

: ${DIALOG_OK=0}
: ${DIALOG_CANCEL=1}
: ${DIALOG_HELP=2}
: ${DIALOG_EXTRA=3}
: ${DIALOG_ITEM_HELP=4}
: ${DIALOG_ESC=255}

export NCURSES_NO_UTF8_ACS=1

if [ -f /etc/dshield.conf ] ; then
    chmod 600 /etc/dshield.conf
    echo reading old configuration
    if grep -q 'uid=<authkey>' /etc/dshield.conf; then
	sed -i.bak 's/<.*>//' /etc/dshield.conf
    fi
    . /etc/dshield.conf
fi
nomysql=0

dialog --title 'WARNING' --yesno "You are about to turn this Raspberry Pi into a honeypot. This software assumes that the device is dedicated to this task. There is no simple uninstall. Do you want to proceed?" 10 50
response=$?
case $response in
    ${DIALOG_CANCEL}) exit;;
esac


if [ -d /var/lib/mysql ]; then
  dialog --title 'Installing MySQL' --yesno "You may already have MySQL installed. Do you want me to re-install MySQL and erase all existing data?" 10 50
  response=$?
  case $response in 
      ${DIALOG_OK}) apt-get -y -qq purge mysql-server mysql-server-5.5 mysql-server-core-5.5;;
      ${DIALOG_CANCEL}) nomysql=1;;
      ${DIALOG_ESC}) exit;;
  esac
fi

if [ "$nomysql" -eq "0" ] ; then
mysqlpassword=`head -c10 /dev/random | xxd -p`
echo "mysql-server-5.5 mysql-server/root_password password $mysqlpassword" | debconf-set-selections
echo "mysql-server-5.5 mysql-server/root_password_again password $mysqlpassword" | debconf-set-selections
echo "mysql-server mysql-server/root_password password $mysqlpassword" | debconf-set-selections
echo "mysql-server mysql-server/root_password_again password $mysqlpassword" | debconf-set-selections
apt-get -qq -y install mysql-server
cat > ~/.my.cnf <<EOF
[mysql]
user=root
password=$mysqlpassword
EOF
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
	    VALUES=$(dialog --ok-label "Verify" --title "DShield Account Information" --form "Authentication Information. Copy/Past from dshield.org/myaccount.html. Use CTRL-V to paste." 12 60 0 \
		       "E-Mail Address:" 1 2 "$email"   1 17 35 100 \
		       "       API Key:" 2 2 "$apikey" 2 17 35 100 \
		       2>&1 1>&3)

	      response=$?
	    exec 3>&-

	    case $response in 
		${DIALOG_OK}) 	    email=`echo $VALUES | cut -f1 -d' '`
	    apikey=`echo $VALUES | cut -f2 -d' '`
	    nonce=`openssl rand -hex 10`
	    hash=`echo -n $email:$apikey | openssl dgst -hmac $nonce -sha512 -hex | cut -f2 -d'=' | tr -d ' '`

	    user=`echo $email | sed 's/@/%40/'`
	    curl -s https://isc.sans.edu/api/checkapikey/$user/$nonce/$hash > $TMPDIR/checkapi
	    if grep -q '<result>ok</result>' $TMPDIR/checkapi ; then
		apikeyok=1;
		uid=`grep  '<id>.*<\/id>' $TMPDIR/checkapi | sed -E 's/.*<id>([0-9]+)<\/id>.*/\1/'`
            else
		dialog --title 'API Key Failed' --msgbox 'Your API Key Verification Failed.' 7 40
	    fi;;
		${DIALOG_CANCEL}) exit;;
		${DIALOG_ESC}) exit;;
esac;
	done

    fi
fi
echo $uid
dialog --title 'API Key Verified' --msgbox 'Your API Key is valid. The firewall will be configured next. ' 7 40


#
# Default Interface
#

# if we don't have one configured, try to figure it out
if [ "$interface" = "" ] ; then
interface=`ip link show | egrep '^[0-9]+: ' | cut -f 2 -d':' | tr -d ' ' | grep -v lo`
fi

# list of valid interfaces
validifs=`ip link show | grep '^[0-9]' | cut -f2 -d':' | tr -d '\n' | sed 's/^ //'`
localnetok=0

while [ $localnetok -eq  0 ] ; do
    exec 3>&1
    interface=$(dialog --title 'Default Interface' --form 'Default Interface' 10 40 0 \
		       "Honeypot Interface:" 1 2 "$interface" 1 25 10 10 2>&1 1>&3)
    exec 3>&-
    for b in $validifs; do
	if [ "$b" = "$interface" ] ; then
	    localnetok=1
	fi
    done
    if [ $localnetok -eq 0 ] ; then
	dialog --title 'Default Interface Error' --msgbox "You did not specify a valid interface. Valid interfaces are $validifs" 10 40
    fi
done
echo "Interface: $interface"

# figuring out local network.

ipaddr=`ip addr show  eth0 | grep 'inet ' |  awk '{print $2}' | cut -f1 -d'/'`
localnet=`ip route show | grep eth0 | grep 'scope link' | cut -f1 -d' '`
localnetok=0

while [ $localnetok -eq  0 ] ; do
    exec 3>&1
    localnet=$(dialog --title 'Local Network' --form 'Admin access will be restricted to this network, and logs originating from this network will not be reported.' 10 50 0 \
		      "Local Network:" 1 2 "$localnet" 1 25 20 20 2>&1 1>&3)

    exec 3>&-
    if echo "$localnet" | egrep -q '^([0-9]{1,3}\.){3}[0-9]{1,3}\/[0-9]{1,2}$'; then
	localnetok=1
    fi
    if [ $localnetok -eq 0 ] ; then
	dialog --title 'Local Network Error' --msgbox 'The format of the local network is wrong. It has to be in Network/CIDR format. For example 192.168.0.0/16' 40 10
    fi
done
cat > /etc/network/iptables <<EOF

#
# 
#

*filter
:INPUT ACCEPT [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -i lo -j ACCEPT
-A INPUT -i $interface -m state --state ESTABLISHED,RELATED -j ACCEPT
-A INPUT -i $interface -s $localnet -j ACCEPT
-A INPUT -i $interface -p tcp --dport 12222 -s 10.0.0.0/8 -j ACCEPT
-A INPUT -i $interface -p tcp --dport 12222 -s 192.168.0.0/8 -j ACCEPT
-A INPUT -i $interface -j LOG --log-prefix " INPUT "
-A INPUT -i $interface -p tcp --dport 12222 -j DROP
COMMIT
*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
-A PREROUTING -p tcp -m tcp --dport 22 -j REDIRECT --to-ports 2222
-A PREROUTING -p tcp -m tcp --dport 25 -j REDIRECT --to-ports 2525
-A PREROUTING -p tcp -m tcp --dport 80 -j REDIRECT --to-ports 8000

COMMIT
EOF
cp $progdir/../etc/network/if-pre-up.d/dshield /etc/network/if-pre-up.d
chmod 700 /etc/network/if-pre-up.d/dshield
sed -i.bak 's/^Port 22$/Port 12222/' /etc/ssh/sshd_config

sed "s/%%interface%%/$interface/" < $progdir/../etc/rsyslog.d/dshield.conf > /etc/rsyslog.d/dshield.conf

#
# "random" offset for cron job so not everybody is reporting at once
#

offset1=`shuf -i0-29 -n1`
offset2=$((offset1+30));
cat > /etc/cron.d/dshield <<EOF
$offset1,$offset2 * * * * root $progdir/dshield.pl
EOF
chmod 700 $progdir/dshield.pl


#
# Update Configuration
#
if [ -f /etc/dshield.conf ]; then
    rm /etc/dshield.conf
fi

touch /etc/dshield.conf
chmod 600 /etc/dshield.conf
echo "uid=$uid" >> /etc/dshield.conf
echo "apikey=$apikey" >> /etc/dshield.conf
echo "email=$email" >> /etc/dshield.conf
echo "interface=$interface" >> /etc/dshield.conf
echo "localnet=$localnet" >> /etc/dshield.conf
echo "mysqlpassword=$mysqlpassword" >> /etc/dshield.conf
echo "mysqluser=root" >> /etc/dshield.conf
echo "version=$version" >> /etc/dshield.conf
echo "progdir=$progdir" >> /etc/dshield.conf

#
# creating srv directories
#

mkdir -p /srv/www/html
mkdir -p /var/log/mini-httpd
chmod 1777 /var/log/mini-httpd

#
# installing cowrie
#

wget -qO $TMPDIR/cowrie.zip https://github.com/micheloosterhof/cowrie/archive/master.zip
unzip -qq -d $TMPDIR $TMPDIR/cowrie.zip 
if [ -d /srv/cowrie ]; then
    rm -rf /srv/cowrie
fi
mv $TMPDIR/cowrie-master /srv/cowrie

ssh-keygen -t dsa -b 1024 -N '' -f /srv/cowrie/data/ssh_host_dsa_key > /dev/null

if ! grep '^cowrie:' -q /etc/passwd; then
    adduser --gecos "Honeypot,A113,555-1212,555-1212" --disabled-password --quiet --home /srv/cowrie --no-create-home cowrie
    echo Added user 'cowrie'
else
    echo User 'cowrie' already exists. Making no changes
fi    

# check if cowrie db schema exists
x=`mysql -uroot -p$mysqlpassword -e 'select count(*) "" from information_Schema.schemata where schema_name="cowrie"'`
if [ $x -eq 1 ]; then
    echo "cowrie mysql database already exists. not touching it."
else
    # we create the database and call the creation script
    mysql -uroot -p$mysqlpassword -e 'create schema cowrie'
    mysql -uroot -p$mysqlpassword -e 'source /srv/cowrie/doc/sql/mysql.sql' cowrie
fi
if [ "$cowriepassword" = "" ]; then
    cowriepassword=`head -c10 /dev/random | xxd -p`
fi
echo cowriepassword=$cowriepassword >> /etc/dshield.conf
mysql -uroot -p$mysqlpassword -e "create user \`cowrie\`.\`*\` identified by '$cowriepassword'"
mysql -uroot -p$mysqlpassword -e "grant all on cowrie.* to \`cowrie\`@\`localhost\`"



cp /srv/cowrie/cowrie.cfg.dist /srv/cowrie/cowrie.cfg
cat >> /srv/cowrie/cowrie.cfg <<EOF
[output_dshield]
userid = $uid
auth_key = $apikey
batch_size = 1
[output_mysql]
host=localhost
database=cowrie
username=cowrie
password=$cowriepassword
port=3306
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
cp $progdir/../etc/cron.hourly/dshield /etc/cron.hourly
cp $progdir/../etc/mini-httpd.conf /etc/mini-httpd.conf
cp $progdir/../etc/default/mini-httpd /etc/default/mini-httpd

update-rc.d cowrie defaults
update-rc.d mini-httpd defaults

#
# installing postfix as an MTA
#

apt-get -y -qq purge postfix
echo "postfix postfix/mailname string raspberrypi" | debconf-set-selections
echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections
echo "postfix postfix/mynetwork string '127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128'" | debconf-set-selections
echo "postfix postfix/destinations string raspberrypi, localhost.localdomain, localhost" | debconf-set-selections
debconf-get-selections | grep postfix
apt-get -y -qq install postfix

#
# modifying motd
#

cat > $TMPDIR/motd <<EOF

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.

***
***    DShield Honeypot - Web Admin on port 8080
***

EOF

mv $TMPDIR/motd /etc/motd

./makecert.sh

echo
echo
echo Done. 
echo
echo "Please reboot your Pi now."
echo
echo "For feedback, please e-mail jullrich@sans.edu or file a bug report on github"
echo "Please include a sanitized version of /etc/dshield.conf in bug reports."
echo "To support logging to MySQL, a MySQL server was installed. The root password is $mysqlpassword"
echo
echo "IMPORTANT: after rebooting, the Pi's ssh server will listen on port 12222"
echo "           connect using ssh -p 12222 $SUDO_USER@$ipaddr"


