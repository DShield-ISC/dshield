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
trap "rm -rf $TMPDIR" 0 1 2 5 15

echo "Basic security checks"

# making sure default password was changed

hashline=`sudo grep '^pi:' /etc/shadow`
salt=`echo $x | cut -d '$' -f2-3`
shadowhash=`echo $hashline | cut -f2 -d':'`
perl -e "print crypt('raspberry','\$$salt\$')" > $TMPDIR/passcheck
testhash=`cat $TMPDIR/passcheck`
if [ "$shadowhash" == "$testhash" ]; then
  echo "You have not yet changed the default password for the 'pi' user"
  echo "Change it NOW ..."
  exit
fi

echo "Updating your Raspbian Installation (this can take a LOOONG time)"

sudo apt-get update > /dev/null
sudo apt-get upgrade > /dev/null

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
case $return_value in 
    $DIALOG_OK)
       echo pressed $return and ok
    $DIALOG_CANCEL)
       echo cancel
       exit
    $DIALOG_ESC)
       echo escape
       exit
    ;;
esac




