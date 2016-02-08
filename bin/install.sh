#!/bin/sh

####
#
#  Install Script. run to configure various components
#
####

echo "Checking Pre-Requisits"

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

# apt-get update > /dev/null
# apt-get upgrade > /dev/null

echo "Installing additional packages"

apt-get install dialog > /dev/null

: ${DIALOG_OK=0}
: ${DIALOG_CANCEL=1}
: ${DIALOG_HELP=2}
: ${DIALOG_EXTRA=3}
: ${DIALOG_ITEM_HELP=4}
: ${DIALOG_ESC=255}

export NCURSES_NO_UTF8_ACS=1



if [ -f /etc/dshield.ini ] ; then
    echo reading old configuration
    . /etc/dshield.ini
fi

dialog --title 'DShield Installer' --menu "DShield Account" 10 40 2 1 "Use Existing Account" 2 "Create New Account" 2> $TMPDIR/dialog
return_value=$?
return=`cat $TMPDIR/dialog`
echo return $return $return_value
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
       user=`echo $VALUES | cut -f1 -d' '`
       apikey=`echo $VALUES | cut -f2 -d' '`
       nonce=`openssl rand -hex 10`
       hash=`echo -n $user:$apikey | openssl dgst -hmac $nonce -sha512 -hex | cut -f2 -d'=' | tr -d ' '`
       user=`echo $user | sed 's/@/%40/'`
       echo $user;
       echo https://isc.sans.edu/api/checkapikey/$user/$nonce/$hash
       curl -s https://isc.sans.edu/api/checkapikey/$user/$nonce/$hash > $TMPDIR/checkapi
       if grep -q '<result>ok</result>' $TMPDIR/checkapi ; then
	   apikeyok=1;
	   $uid=`grep  '<id>.*<\/id>' /tmp/x | sed -E 's/.*<id>([0-9]+)<\/id>.*/\1/`
       fi	   

	done
   fi
fi
dialog --title 'API Key Verified' --msgbox 'Your API Key is valid. The firewall will be configured next.' 7 40
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
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -i lo -j ACCEPT
-A INPUT -i $interface -s $localnet -j ACCEPT
-A INPUT -i $interface -p tcp -m tcp --dport 22 -j ACCEPT
-A INPUT -i $interface -p tcp -m tcp --dport 12222 -j ACCEPT
-A INPUT -i $interface -j LOG --log-prefix " INPUT "
*nat
-A PREROUTING -p tcp --dport 22 -j REDIRECT --to-port 2222
COMMIT
EOF

sed -i.bak 's/^Port 22$/Port 12222/' /etc/ssh/sshd_config

sed "s/%%interface%%/$interface/" < ../etc/rsyslog.d/dshield.conf > /etc/rsyslog.d/dshield.conf
sed "s/%%dshieldparser%%/$parser/" < ../etc/logrotate.d/dshield > /etc/logrotate.d/dshield

disk=`ls -l /dev | grep '^brw-rw---- 1 root disk  179,' | awk '{print $10}' | head -1`
disksize=`sfdisk -s /dev/$disk`
bootpart=${disk}p1
rootpart=${disk}p2
bootsize=`sfdisk -s /dev/$bootpart`
rootsize=`sfdisk -s /dev/$rootpart`
diff=$((disksize-bootsize-rootsize))
if [ "$diff" -gt "10000" ]; then
 dialog --title 'Claiming Unused Disk Space' --yesno 'Your SD Card has significant unused disk space. Should I extend the root partition?' 7 40 
 response=$?
 if [ $response -eq 0 ] ; then

     dialog --title 'Partition Expanded' --msgbox 'Root Expansion Complete' 7 40
 fi      
fi


