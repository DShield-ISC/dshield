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

echo "Updating your Raspbian Installation"

apt-get update > /dev/null
apt-get upgrade > /dev/null
apt-get install dialog > /dev/null


