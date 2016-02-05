#!/bin/sh

####
#
#  Install Script. run to configure various components
#
####

echo "Checking Pre-Requisits"

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
# trap "rm -r $TMPDIR" 0 1 2 5 15

echo "Basic security checks"

# making sure default password was changed

hashline=`sudo grep '^pi:' /etc/shadow`
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

# sudo apt-get update > /dev/null
# sudo apt-get upgrade > /dev/null

echo "Installing additional packages"

sudo apt-get install dialog > /dev/null

: ${DIALOG_OK=0}
: ${DIALOG_CANCEL=1}
: ${DIALOG_HELP=2}
: ${DIALOG_EXTRA=3}
: ${DIALOG_ITEM_HELP=4}
: ${DIALOG_ESC=255}

export NCURSES_NO_UTF8_ACS=1

dialog --title 'DShield Installer' --menu "DShield Account" 10 40 2 1 "Use Existing Account" 2 "Create New Account" 2> $TMPDIR/dialog
return_value=$?
return=`cat $TMPDIR/dialog`
user=''
apikey=''
echo return $return $return_value
if [ $return_value -eq  $DIALOG_OK ]; then
    if [ $return = "1" ] ; then
	apikeyok=0
	while [ "$apikeyok" = 0 ] ; do
       exec 3>&1
       VALUES=$(dialog --ok-label "Verify" --title "DShield Account Information" --form "Authentication Information" 10 60 0 \
		       "E-Mail Address:" 1 2 "$user"   1 17 35 100 \
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
       if curl -s https://isc.sans.edu/api/checkapikey/$user/$nonce/$hash | grep -q '<result>ok</result>' ; then
	   apikeyok=1;
       fi	   

	done
   fi
fi

cls
echo "api key verified"



