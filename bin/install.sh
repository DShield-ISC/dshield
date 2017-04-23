#!/bin/bash

####
#
#  Install Script. run to configure various components
#
#  exit codes:
#  9 - install error
#  5 - user cancel
#
####

###########################################################
## CONFIG SECTION
###########################################################


readonly version=0.4

# target directory for server components
TARGETDIR="/srv"
DSHIELDDIR="${TARGETDIR}/dshield"
# COWRIEDIR="${TARGETDIR}/cowrie"
LOGDIR="${TARGETDIR}/log"
LOGFILE="${LOGDIR}/install_`date +'%Y-%m-%d_%H%M%S'`.log"

# which ports will be handled e.g. by cowrie (separated by blanks)
# used e.g. for setting up block rules for trusted nets
# use the ports after PREROUTING has been excecuted, i.e. the redirected (not native) ports
HONEYPORTS="2222"

# Debug Flag
# 1 = debug logging, debug commands
# 0 = normal logginf, no extra commands
DEBUG=1

# delimiter
LINE="##########################################################################################################"

# dialog stuff
: ${DIALOG_OK=0}
: ${DIALOG_CANCEL=1}
: ${DIALOG_HELP=2}
: ${DIALOG_EXTRA=3}
: ${DIALOG_ITEM_HELP=4}
: ${DIALOG_ESC=255}

export NCURSES_NO_UTF8_ACS=1


###########################################################
## FUNCTION SECTION
###########################################################

# echo and log
outlog () {
   echo "${*}"
   do_log "${*}"
}

# write log
do_log () {
   if [ ! -d ${LOGDIR} ] ; then
       mkdir -p ${LOGDIR}
       chmod 700 ${LOGDIR}
   fi
   if [ ! -f ${LOGFILE} ] ; then
       touch ${LOGFILE}
       chmod 600 ${LOGFILE}
       outlog "Log ${LOGFILE} started."
       outlog "ATTENTION: the log file contains sensitive information (e.g. passwords, API keys, ...)"
       outlog "           Handle with care. Sanitize before submitting."
   fi
   echo "`date +'%Y-%m-%d_%H%M%S'` ### ${*}" >> ${LOGFILE}
}

# execute and log
# make sure, to be run command is passed within '' or ""
#    if redirects etc. are used
run () {
   do_log "Running: ${*}"
   eval ${*} >> ${LOGFILE} 2>&1
   RET=${?}
   if [ ${RET} -ne 0 ] ; then
      dlog "EXIT CODE NOT ZERO (${RET})!"
   fi
   return ${RET}
}

# run if debug is set
# make sure, to be run command is passed within '' or ""
#    if redirects etc. are used
drun () {
   if [ ${DEBUG} -eq 1 ] ; then
      do_log "DEBUG COMMAND FOLLOWS:"
      do_log "${LINE}"
      run ${*}
      RET=${?}
      do_log "${LINE}"
      return ${RET}
   fi
}

# log if debug is set
dlog () {
   if [ ${DEBUG} -eq 1 ] ; then
      do_log "DEBUG OUTPUT: ${*}"
   fi
}

###########################################################
## MAIN
###########################################################

###########################################################
## basic checks
###########################################################


echo ${LINE}

dlog "parent process: $(ps -o comm= $PPID)"

userid=`id -u`
if [ ! "$userid" = "0" ]; then
   echo "You have to run this script as root. eg."
   echo "  sudo bin/install.sh"
   echo "Exiting."
   exit 9
else
   do_log "Check OK: User-ID is ${userid}."
fi

dlog "This is ${0} V${version}"

if [ ${DEBUG} -eq 1 ] ; then
   do_log "DEBUG flag is set."
else
   do_log "DEBUG flag NOT set."
fi

drun env
drun 'df -h'

outlog "Checking Pre-Requisits"

progname=$0;
progdir=`dirname $0`;
progdir=$PWD/$progdir;

dlog "progname: ${progname}"
dlog "progdir: ${progdir}"

cd $progdir

if [ ! -f /etc/os-release ] ; then
  outlog "I can not fine the /etc/os-release file. You are likely not running a supported operating systems"
  outlog "please email info@dshield.org for help."
  exit 9
fi

drun "cat /etc/os-release"
drun "uname -a"

dlog "sourcing /etc/os-release"
. /etc/os-release


dist=invalid


if [ "$ID" == "ubuntu" ] ; then
   dist='apt';
fi

if [ "$ID" == "raspbian" ] && [ "$VERSION_ID" == "8" ] ; then
   dist='apt';
fi

if [ "$ID" == "amzn" ] && [ "$VERSION_ID" == "2016.09" ] ; then 
   dist='yum';
fi

dlog "dist: ${dist}"

if [ "$dist" == "invalid" ] ; then
   outlog "You are not running a supported operating systems. Right now, this script only works for Raspbian and Amazon Linux AMI."
   outlog "Please ask info@dshield.org for help to add support for your OS. Include the /etc/os-release file."
   exit 9
fi

if [ "$ID" != "raspbian" ] ; then
   outlog "ATTENTION: the latest versions of this script have been tested on Raspbian only."
   outlog "It may or may not work with your distro. Feel free to test and contribute."
   outlog "Press ENTER to continue, CTRL+C to abort."
   read lala
fi

exit 99

outlog "using apt to install packages"

dlog "creating a temporary directory"

TMPDIR=`mktemp -d -q /tmp/dshieldinstXXXXXXX`
dlog "TMPDIR: ${TMPDIR}"

dlog "setting trap"
# trap "rm -r $TMPDIR" 0 1 2 5 15
run 'trap "echo Log: ${LOGFILE} && rm -r $TMPDIR" 0 1 2 5 15'

outlog "Basic security checks"

dlog "making sure default password was changed"

if [ "$dist" == "apt" ]; then

   dlog "we are on pi and should check if password for user pi has been changed"
   if $progdir/passwordtest.pl | grep -q 1; then
      outlog "You have not yet changed the default password for the 'pi' user"
      outlog "Change it NOW ..."
      exit 9
   fi
   outlog "Updating your Installation (this can take a LOOONG time)"

   drun 'dpkg --list'

   run 'apt-get update'
   run 'apt-get -y -q upgrade'

   outlog "Installing additional packages"
   # apt-get -y -qq install build-essential dialog git libffi-dev libmpc-dev libmpfr-dev libpython-dev libswitch-perl libwww-perl mini-httpd mysql-client python2.7-minimal python-crypto python-gmpy python-gmpy2 python-mysqldb python-pip python-pyasn1 python-twisted python-virtualenv python-zope.interface randomsound rng-tools unzip libssl-dev > /dev/null

   # OS packages: no python modules
   run 'apt-get -y -q install build-essential dialog git libffi-dev libmpc-dev libmpfr-dev libpython-dev libswitch-perl libwww-perl mini-httpd mysql-client python2.7-minimal randomsound rng-tools unzip libssl-dev libmysqlclient-dev'
   # pip install python-dateutil > /dev/null

fi

if [ "$ID" == "amzn" ]; then
   outlog "Updating your Operating System"
   run 'yum -q update -y'
   outlog "Installing additional packages"
   # run yum -q install -y dialog perl-libwww-perl perl-Switch python27-twisted python27-crypto python27-pyasn1 python27-zope-interface python27-pip mysql rng-tools boost-random MySQL-python27 python27-dateutil 
   run 'yum -q install -y dialog perl-libwww-perl perl-Switch mysql rng-tools boost-random MySQL-python27'
fi


###########################################################
## last chance to escape before hurting the system ...
###########################################################


dialog --title 'WARNING' --yesno "You are about to turn this Raspberry Pi into a honeypot. This software assumes that the device is DEDICATED to this task. There is no simple uninstall. If something breakes you may need to reinstall from scratch. Do you want to proceed?" 10 50
response=$?
case $response in
   ${DIALOG_CANCEL}) 
      outlog "Terminating installation by your command. The system shouldn't have been hurt too much yet ..."
      outlog "See ${LOGFILE} for details."
      exit 5
      ;;
esac


###########################################################
## Stoppgin Cowrie if already installed
###########################################################

if [ -x /etc/init.d/cowrie ] ; then
   outlog "Existing cowrie startup file found, stopping cowrie."
   run '/etc/init.d/cowrie stop'
fi


###########################################################
## PIP
###########################################################

outlog "check if pip is already installed"

run 'pip > /dev/null'

if [ ${?} -gt 0 ] ; then
   # nice, no pip found

   dlog "no pip found, Installing pip"

   run 'wget -qO $TMPDIR/get-pip.py https://bootstrap.pypa.io/get-pip.py'
   run 'python $TMPDIR/get-pip.py'

else
   # hmmmm ...
   # todo: automatic check if pip is OS managed or not
   # check ... already done :)

   outlog "pip found .... Checking which pip is installed...."

   drun 'pip -V'
   drun 'pip  -V | cut -d " " -f 4 | cut -d "/" -f 3'
   drun 'find /usr -name pip'
   drun 'find /usr -name pip | grep -v local'

   # if local is in the path then it's normally not a distro package, so if we only find local, then it's OK
   # - no local in pip -V output 
   #   OR
   # - pip below /usr without local
   # -> potential distro pip found
   if [ `pip  -V | cut -d " " -f 4 | cut -d "/" -f 3` != "local" -o `find /usr -name pip | grep -v local | wc -l` -gt 0 ] ; then
      # pip may be distro pip

      outlog "Potential distro pip found"

      dialog --title 'NOTE (pip)' --yesno "pip is already installed on the system... and it looks like as being installed as a distro package. If this is true, it can be problematic in the future and cause esoteric errors. You may consider uninstalling all OS packages of Python modules (something like python-*). Proceed nevertheless?" 12 50
      response=$?
      case $response in
         ${DIALOG_CANCEL}) 
            do_log "Terminated by user in pip dialogue."
            exit 5
            ;;
      esac

   else
      outlog "pip found which doesn't seem to be installed as a distro package. Looks ok to me."
   fi

fi

drun 'pip list'


###########################################################
## Random number generator
###########################################################

#
# yes. this will make the random number generator less secure. but remember this is for a honeypot
#

dlog "Changing random number generator settings."
run 'echo "HRNGDEVICE=/dev/urandom" > /etc/default/rnd-tools'


###########################################################
## Handling existing config
###########################################################

if [ -f /etc/dshield.conf ] ; then
   dlog "dshield.conf found, content follows"
   drun 'cat /etc/dshield.conf'
   dlog "securing dshield.conf"
   run 'chmod 600 /etc/dshield.conf'
   run 'chown root:root /etc/dshield.conf'
   outlog "reading old configuration"
   if grep -q 'uid=<authkey>' /etc/dshield.conf; then
      dlog "erasing <.*> pattern from dshield.conf"
      run "sed -i.bak 's/<.*>//' /etc/dshield.conf"
      dlog "modified content of dshield.conf follows"
      drun 'cat /etc/dshield.conf'
   fi
   dlog "sourcing current dshield.conf but making sure don't overwrite progdir in script ..."
   progdirold=$progdir
   dlog "... progdir in script: ${progdir}"
   . /etc/dshield.conf
   dlog "... progdir in dshield.conf: ${progdir}"
   progdir=$progdirold
   dlog "hanlding of dshield.conf finished"
fi

###########################################################
## MySQL
###########################################################

nomysql=0

if [ -d /var/lib/mysql ]; then
   dlog "MySQL dir found (/var/lib/mysql), asking what to do"
   dialog --title 'Installing MySQL' --yesno "You may already have MySQL installed. Do you want me to re-install MySQL and erase all existing data?" 10 50
   response=$?
   case $response in 
      ${DIALOG_OK}) 
         dlog "being told by user to (re-) install MySQL"
         outlog "removing MySQL packages"
         run 'apt-get -y -q purge mysql-server mysql-server-5.5 mysql-server-core-5.5'
         ;;
      ${DIALOG_CANCEL}) 
         dlog "being told by user not to touch MySQL"
         nomysql=1
         ;;
      ${DIALOG_ESC}) 
         dlog "User pressed ESC"
         outlog "Exiting at your request, no MySQL stuff done."
         exit 5
         ;;
   esac
fi

if [ $nomysql -eq 0 ] ; then
   # we are allowed to play with MySQL
   outlog "Installing and configuring MySQL (this can take a LOOONG time)"

   # MySQL root pw
   mysqlpassword=`head -c10 /dev/random | xxd -p`
   dlog "MySQL root password: ${mysqlpassword}"

   dlog "setting MySQL server parameters for package manager"
   echo "mysql-server-5.5 mysql-server/root_password password $mysqlpassword" | debconf-set-selections
   echo "mysql-server-5.5 mysql-server/root_password_again password $mysqlpassword" | debconf-set-selections
   echo "mysql-server mysql-server/root_password password $mysqlpassword" | debconf-set-selections
   echo "mysql-server mysql-server/root_password_again password $mysqlpassword" | debconf-set-selections

   outlog "Installing MySQL server package"
   run 'apt-get -q -y install mysql-server'

   outlog "Creating  ~/.my.cnf"
   cat > ~/.my.cnf <<EOF
[mysql]
user=root
password=$mysqlpassword
EOF
   drun 'cat  ~/.my.cnf'
fi

outlog "Checking, if the MySQL root account can connect."
run 'mysql -u root -p$mysqlpassword  -e ";"'
if [ ${?} -ne 0 ] ; then
   outlog "The root user can't connect to MySQL server using password $mysqlpassword ."
   outlog "Perhaps obsolete password in /etc/dshield.conf?"
   exit 9
else
   dlog "OK, MySQL root user can connect using password $mysqlpassword ."
fi


# hmmm - this SHOULD NOT happen
if ! [ -d $TMPDIR ]; then
   outlog "${TMPDIR} not found, aborting."
   exit 9
fi


###########################################################
## DShield Account
###########################################################

# TODO: let the user create a dhield account instead of using an existing one

# dialog --title 'DShield Installer' --menu "DShield Account" 10 40 2 1 "Use Existing Account" 2 "Create New Account" 2> $TMPDIR/dialog
# return_value=$?
# return=`cat $TMPDIR/dialog`

return_value=$DIALOG_OK
return=1

if [ $return_value -eq  $DIALOG_OK ]; then
   if [ $return = "1" ] ; then
      dlog "use existing dhield account"
      apikeyok=0
      while [ "$apikeyok" = 0 ] ; do
         dlog "Asking user for dshield account information"
         exec 3>&1
         VALUES=$(dialog --ok-label "Verify" --title "DShield Account Information" --form "Authentication Information. Copy/Past from dshield.org/myaccount.html. Use CTRL-V / SHIFT + INS to paste." 12 60 0 \
            "E-Mail Address:" 1 2 "$email"   1 17 35 100 \
            "       API Key:" 2 2 "$apikey" 2 17 35 100 \
            2>&1 1>&3)

         response=$?
         exec 3>&-

         case $response in 
            ${DIALOG_OK})
               email=`echo $VALUES | cut -f1 -d' '`
               apikey=`echo $VALUES | cut -f2 -d' '`
               dlog "Got email ${email} and apikey ${apikey}"
               dlog "Calculating nonce."
               nonce=`openssl rand -hex 10`
               dlog "Calculating hash."
	       hash=`echo -n $email:$apikey | openssl dgst -hmac $nonce -sha512 -hex | cut -f2 -d'=' | tr -d ' '`
               dlog "Calculated nonce (${nonce}) and hash (${hash})."
   
	       user=`echo $email | sed 's/@/%40/'`
               dlog "Checking API key ...."
	       run 'curl -s https://isc.sans.edu/api/checkapikey/$user/$nonce/$hash > $TMPDIR/checkapi'
   
               dlog "Curl return code is ${?}"
   
               if ! [ -d "$TMPDIR" ]; then
                  # this SHOULD NOT happpen
                  outlog "Can not find TMPDIR ${TMPDIR}"
                  exit 9
               fi
   
               drun "cat ${TMPDIR}/checkapi"
   
               dlog "Excamining result of API key check ..."
   
               if grep -q '<result>ok</result>' $TMPDIR/checkapi ; then
                  apikeyok=1;
                  uid=`grep  '<id>.*<\/id>' $TMPDIR/checkapi | sed -E 's/.*<id>([0-9]+)<\/id>.*/\1/'`
                  dlog "API key OK, uid is ${uid}"
               else
                  dlog "API key not OK, informing user"
                  dialog --title 'API Key Failed' --msgbox 'Your API Key Verification Failed.' 7 40
	       fi
               ;;
            ${DIALOG_CANCEL}) 
               dlog "User canceled API key dialogue."
               exit 5
               ;;
            ${DIALOG_ESC}) 
               dlog "User pressed ESC in API key dialogue."
               exit 5
               ;;
         esac;
      done # while API not OK

   fi # use existing account or create new one
fi # dialogue not aborted

# echo $uid

dialog --title 'API Key Verified' --msgbox 'Your API Key is valid. The firewall will be configured next. ' 7 40


###########################################################
## Firewall Configuration
###########################################################

#
# Default Interface
#

dlog "firewall config: figuring out default interface"

# if we don't have one configured, try to figure it out
dlog "interface: ${interface}"
drun 'ip link show'
if [ "$interface" = "" ] ; then
   dlog "Trying to figure out interface"
   # we don't expect a honeypot connected by WLAN ... but the user can change this of course
   drun "ip link show | egrep '^[0-9]+: ' | cut -f 2 -d':' | tr -d ' ' | grep -v lo | grep -v wlan"
   interface=`ip link show | egrep '^[0-9]+: ' | cut -f 2 -d':' | tr -d ' ' | grep -v lo | grep -v wlan`
fi

# list of valid interfaces
drun "ip link show | grep '^[0-9]' | cut -f2 -d':' | tr -d '\n' | sed 's/^ //'"
validifs=`ip link show | grep '^[0-9]' | cut -f2 -d':' | tr -d '\n' | sed 's/^ //'`

dlog "validifs: ${validifs}"

localnetok=0

while [ $localnetok -eq  0 ] ; do
   dlog "asking user for default interface"
   exec 3>&1
   interface=$(dialog --title 'Default Interface' --form 'Default Interface' 10 40 0 \
      "Honeypot Interface:" 1 2 "$interface" 1 25 10 10 2>&1 1>&3)
   exec 3>&-
   dlog "User input for interface: ${interface}"
   dlog "check if input is valid"
   for b in $validifs; do
      if [ "$b" = "$interface" ] ; then
         localnetok=1
      fi
   done
   if [ $localnetok -eq 0 ] ; then
      dlog "User provided interface ${interface} isn't valid"
      dialog --title 'Default Interface Error' --msgbox "You did not specify a valid interface. Valid interfaces are $validifs" 10 40
   fi
done # while interface not OK

dlog "Interface: $interface"

#
# figuring out local network.
#

dlog "firewall config: figuring out local network"

drun "ip addr show  eth0"
drun "ip addr show  eth0 | grep 'inet ' |  awk '{print $2}' | cut -f1 -d'/'"
ipaddr=`ip addr show  eth0 | grep 'inet ' |  awk '{print $2}' | cut -f1 -d'/'`
dlog "ipaddr: ${ipaddr}"

drun "ip route show"
drun "ip route show | grep eth0 | grep 'scope link' | cut -f1 -d' '"
localnet=`ip route show | grep eth0 | grep 'scope link' | cut -f1 -d' '`
dlog "localnet: ${localnet}"


localnetok=0

dlog "Getting local network from user ..."
while [ $localnetok -eq  0 ] ; do
   exec 3>&1
   localnet=$(dialog --title 'Local Network' --form 'Admin access will be restricted to this network, and logs originating from this network will not be reported.' 10 50 0 \
      "Local Network:" 1 2 "$localnet" 1 25 20 20 2>&1 1>&3)

   exec 3>&-
   dlog "user input localnet: ${localnet}"
   if echo "$localnet" | egrep -q '^([0-9]{1,3}\.){3}[0-9]{1,3}\/[0-9]{1,2}$'; then
      localnetok=1
   fi

   if [ $localnetok -eq 0 ] ; then
      dlog "user provided localnet ${localnet} is not ok"
      dialog --title 'Local Network Error' --msgbox 'The format of the local network is wrong. It has to be in Network/CIDR format. For example 192.168.0.0/16' 40 10
   fi
done

#
# further IPs: no iptables logging
#

dlog "firewall config: IPs / nets for which firewall logging should NOT be done"

if [ "${nofwlogging}" == "" ] ; then
   # default: local net
   nofwlogging="${localnet}"
fi

dlog "nofwlogging: ${nofwlogging}"

dlog "getting IPs from user ..."

exec 3>&1
NOFWLOGGING=$(dialog --title 'IPs to ignore for FW Log'  --cr-wrap --form "WARNING - USE WITH CARE!
IPs and nets the firewall should do no logging for (in notation iptables likes, separated by spaces).
Attention: entries will be added to use default policy for INPUT chain (ACCEPT) and the 'real' sshd will be exposed.
If unsure don't change anything here or blank the input! Trusted IPs only. You have been warned.
" \
14 70 0 "Ignore FW Log:" 1 1 "${nofwlogging}" 1 17 47 100 2>&1 1>&3)
exec 3>&-

# for saving in dshield.conf
nofwlogging="'${NOFWLOGGING}'"

dlog "user provided nofwlogging: ${nofwlogging}"

if [ "${NOFWLOGGING}" == "" ] ; then
   # echo "No firewall log exceptions will be done."
   dialog --title 'No Firewall Log Exceptions' --msgbox 'No firewall logging exceptions will be installed.' 10 40
else
   dialog --title 'Firewall Logging Exceptions' --cr-wrap --msgbox "The firewall logging exceptions will be installed for IPs
${NOFWLOGGING}." 0 0
fi

#
# further IPs and ports: disable honeypot
#

dlog "firewall config: IPs and ports to disable honeypot for"

if [ "${nohoneyips}" == "" ] ; then
   # default: local net
   nohoneyips="${localnet}"
fi
dlog "nohoneyips: ${nohoneyips}"

if [ "${nohoneyports}" == "" ] ; then
   # default: cowrie ports
   nohoneyports="${HONEYPORTS}"
fi
dlog "nohoneyports: ${nohoneyports}"

dlog "getting IPs and ports from user"

exec 3>&1
NOHONEY=$(dialog --title 'IPs / Ports to disable Honeypot for'  --cr-wrap --form "WARNING - USE WITH CARE!
IPs and nets to disable honeypot for to prevent reporting internal legitimate failed access attempts (IPs / nets in notation iptables likes, separated by spaces / ports (not real but after PREROUTING) separated by spaces).
Attention: entries will be added to reject access to honeypot ports.
If unsure don't change anything here!
" \
16 70 0 \
"IPs / Networks:" 1 1 "${nohoneyips}" 1 17 47 100  \
"Ports:" 2 1 "${nohoneyports}" 2 17 47 100 2>&1 1>&3)
exec 3>&-

dlog "user provided NOHONEY: ${NOHONEY}"

NOHONEYIPS=`echo "${NOHONEY}"  | cut -d "
" -f 1`
NOHONEYPORTS=`echo "${NOHONEY}"  | cut -d "
" -f 2`

# echo "###${NOHONEYIPS}###"
# echo "###${NOHONEYPORTS}###"

dlog "NOHONEYIPS: ${NOHONEYIPS}"
dlog "NOHONEYPORTS: ${NOHONEYPORTS}"

if [ "${NOHONEYIPS}" == "" -o "${NOHONEYPORTS}" == "" ] ; then
   dlog "at least one of the lines were empty, so can't do anything with the rest and will ignore it"
   NOHONEYIPS=""
   NOHONEYPORTS=""
   # echo "No honeyport exceptions will be done."
   dialog --title 'No Honeypot Exceptions' --msgbox 'No honeypot exceptions will be installed.' 10 40
else
   dialog --title 'Honeypot Exceptions' --cr-wrap --msgbox "The honeypot exceptions will be installed for IPs
${NOHONEYIPS}
for ports ${NOHONEYPORTS}." 0 0
fi

# for saving in dshield.conf
nohoneyips="'${NOHONEYIPS}'"
nohoneyports="'${NOHONEYPORTS}'"

dlog "final values: "
dlog "NOHONEYIPS: ${NOHONEYIPS} / NOHONEYPORTS: ${NOHONEYPORTS}"
dlog "nohoneyips: ${nohoneyips} / nohoneyports: ${nohoneyports}"

#
# create default firewall rule set
#

outlog "Doing further configuration"

dlog "creating /etc/network/iptables"

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
EOF

# insert IPs and ports for which honeypot has to be disabled
# as soon as possible
if [ "${NOHONEYIPS}" != "" -a "${NOHONEYIPS}" != " " ] ; then
   echo "# START: IPs / Ports honeypot should be disabled for"  >> /etc/network/iptables
   # echo "###${NOFWLOGGING}###"
   for NOHONEYIP in ${NOHONEYIPS} ; do
      for NOHONEYPORT in ${NOHONEYPORTS} ; do
         echo "-A INPUT -i $interface -s ${NOHONEYIP} -p tcp --dport ${NOHONEYPORT} -j REJECT" >> /etc/network/iptables
      done
   done
   echo "# END: IPs / Ports honeypot should be disabled for"  >> /etc/network/iptables
fi


cat >> /etc/network/iptables <<EOF
-A INPUT -i $interface -s $localnet -j ACCEPT
-A INPUT -i $interface -p tcp --dport 12222 -s 10.0.0.0/8 -j ACCEPT
-A INPUT -i $interface -p tcp --dport 12222 -s 192.168.0.0/8 -j ACCEPT
EOF

# insert to-be-ignored IPs just before the LOGging stuff so that traffic will be handled by default policy for chain
if [ "${NOFWLOGGING}" != "" -a "${NOFWLOGGING}" != " " ] ; then
   echo "# START: IPs firewall logging should be disabled for"  >> /etc/network/iptables
   # echo "###${NOFWLOGGING}###"
   for NOFWLOG in ${NOFWLOGGING} ; do
      echo "-A INPUT -i $interface -s ${NOFWLOG} -j RETURN" >> /etc/network/iptables
   done
   echo "# END: IPs firewall logging should be disabled for"  >> /etc/network/iptables
fi


cat >> /etc/network/iptables <<EOF
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

run 'chmod 700 /etc/network/iptables'

dlog "/etc/network/iptables follows"
drun 'cat /etc/network/iptables'

dlog "Copying /etc/network/if-pre-up.d"

run "cp $progdir/../etc/network/if-pre-up.d/dshield /etc/network/if-pre-up.d"
run "chmod 700 /etc/network/if-pre-up.d/dshield"


###########################################################
## Change SSHD port
###########################################################


dlog "changing port for sshd"

run "sed -i.bak 's/^Port 22$/Port 12222/' /etc/ssh/sshd_config"

dlog "checking if modification was successful"
if [ `grep "^Port 12222\$" /etc/ssh/sshd_config | wc -l` -ne 1 ] ; then
   dialog --title 'sshd port' --ok-label 'Yep, understood.' --cr-wrap --msgbox 'Congrats, you had already changed your sshd port to something other than 22.

Please clean up and either
  - change the port manually to 12222
     in  /etc/ssh/sshd_config    OR
  - clean up the firewall rules and
     other stuff reflecting YOUR PORT' 13 50

   dlog "check unsuccessful, port 12222 not found in sshd_config"
   drun 'cat /etc/ssh/sshd_config'
else
   dlog "check successful, port change to 12222 in sshd_config"
fi

###########################################################
## Modifying syslog config
###########################################################


dlog "setting interface in syslog config"
run 'sed "s/%%interface%%/$interface/" < $progdir/../etc/rsyslog.d/dshield.conf > /etc/rsyslog.d/dshield.conf'

drun 'cat /etc/rsyslog.d/dshield.conf'

###########################################################
## Further copying / configuration
###########################################################


#
# moving dshield stuff to target directory
# (don't like to have root run scripty which are not owned by root)
#

dlog "copying dshield.pl to ${DSHIELDDIR}"
run "mkdir -p ${DSHIELDDIR}"
run "cp $progdir/dshield.pl ${DSHIELDDIR}"
run "chmod 700 ${DSHIELDDIR}/dshield.pl"

#
# "random" offset for cron job so not everybody is reporting at once
#

dlog "creating /etc/cron.d/dshield"
offset1=`shuf -i0-29 -n1`
offset2=$((offset1+30));
cat > /etc/cron.d/dshield <<EOF
$offset1,$offset2 * * * * root ${DSHIELDDIR}/dshield.pl
EOF

drun 'cat /etc/cron.d/dshield'


#
# Update dshield Configuration
#
dlog "creating new /etc/dshield.conf"
if [ -f /etc/dshield.conf ]; then
   dlog "old dshield.conf follows"
   drun 'cat /etc/dshield.conf'
   run 'rm /etc/dshield.conf'
fi

run 'touch /etc/dshield.conf'
run 'chmod 600 /etc/dshield.conf'

run 'echo "uid=$uid" >> /etc/dshield.conf'
run 'echo "apikey=$apikey" >> /etc/dshield.conf'
run 'echo "email=$email" >> /etc/dshield.conf'
run 'echo "interface=$interface" >> /etc/dshield.conf'
run 'echo "localnet=$localnet" >> /etc/dshield.conf'
run 'echo "mysqlpassword=$mysqlpassword" >> /etc/dshield.conf'
run 'echo "mysqluser=root" >> /etc/dshield.conf'
run 'echo "version=$version" >> /etc/dshield.conf'
run 'echo "progdir=${DSHIELDDIR}" >> /etc/dshield.conf'
run 'echo "nofwlogging=$nofwlogging" >> /etc/dshield.conf'
run 'echo "nohoneyips=$nohoneyips" >> /etc/dshield.conf'
run 'echo "nohoneyports=$nohoneyports" >> /etc/dshield.conf'

dlog "new /etc/dshield.conf follows"
drun 'cat /etc/dshield.conf'

#
# creating srv directories
#

dlog "creating further srv directories"
run 'mkdir -p /srv/www/html'
run 'mkdir -p /var/log/mini-httpd'
run 'chmod 1777 /var/log/mini-httpd'

###########################################################
## Installation of cwrie
###########################################################


#
# installing cowrie
# TODO: don't use a static path but a configurable one
#

dlog "installing cowrie"
dlog "downloading and unzipping cowrie"
run 'wget -qO $TMPDIR/cowrie.zip https://github.com/micheloosterhof/cowrie/archive/master.zip'
run 'unzip -qq -d $TMPDIR $TMPDIR/cowrie.zip '

if [ ${?} -ne 0 ] ; then
   outlog "Something went wrong downloading cowrie, ZIP corrupt."
   exit 9
fi

if [ -d /srv/cowrie ]; then
   dlog "old cowrie installatin found, removing"
   # TODO: warn user, backup dl etc.
   run 'rm -rf /srv/cowrie'
fi
dlog "moving extracted cowrie to /srv/cowrie"
run "mv $TMPDIR/cowrie-master /srv/cowrie"

dlog "generating cowrie SSH hostkey"
run "ssh-keygen -t dsa -b 1024 -N '' -f /srv/cowrie/data/ssh_host_dsa_key "

dlog "checking if cowrie OS user already exists"
if ! grep '^cowrie:' -q /etc/passwd; then
   dlog "... no, creating"
   run 'adduser --gecos "Honeypot,A113,555-1212,555-1212" --disabled-password --quiet --home /srv/cowrie --no-create-home cowrie'
   outlog "Added user 'cowrie'"
else
   outlog "User 'cowrie' already exists in OS. Making no changes."
fi    

# check if cowrie db schema exists
dlog "check if cowrie db schema exists"
dlog running:  mysql -uroot -p$mysqlpassword -e 'select count(*) "" from information_Schema.schemata where schema_name="cowrie"'
x=`mysql -uroot -p$mysqlpassword -e 'select count(*) "" from information_Schema.schemata where schema_name="cowrie"'`
if [ $x -eq 1 ]; then
   outlog "cowrie mysql database already exists. not touching it."
else
   outlog "we create the cowrie database and call the creation script"
   run "mysql -uroot -p$mysqlpassword -e 'create schema cowrie'"
   run "mysql -uroot -p$mysqlpassword -e 'source /srv/cowrie/doc/sql/mysql.sql' cowrie"
fi
if [ "$cowriepassword" = "" ]; then
   dlog "no cowrie MySQL password yet, generating"
   cowriepassword=`head -c10 /dev/random | xxd -p`
   dlog "cowriepassword: ${cowriepassword}"
fi

dlog "saving cowriepassword in /etc/dshield.conf"
run 'echo cowriepassword=$cowriepassword >> /etc/dshield.conf'

outlog "Adding / updating cowrie user in MySQL."
dlog "running MySQL commands: 
   mysql -uroot -p$mysqlpassword
   GRANT USAGE ON *.* TO 'cowrie'@'%' IDENTIFIED BY 'slfdjdsljfkjkjaibvjhabu76r3irbk';
   GRANT USAGE ON *.* TO 'cowrie'@'localhost' IDENTIFIED BY 'slfdjdsljfkjkjaibvjhabu76r3irbk';
   DROP USER 'cowrie'@'%';
   DROP USER 'cowrie'@'localhost';
   FLUSH PRIVILEGES;
   CREATE USER 'cowrie'@'localhost' IDENTIFIED BY '${cowriepassword}';
   GRANT ALL ON cowrie.* TO 'cowrie'@'localhost';
"

cat <<EOF | mysql -uroot -p$mysqlpassword
   GRANT USAGE ON *.* TO 'cowrie'@'%' IDENTIFIED BY 'slfdjdsljfkjkjaibvjhabu76r3irbk';
   GRANT USAGE ON *.* TO 'cowrie'@'localhost' IDENTIFIED BY 'slfdjdsljfkjkjaibvjhabu76r3irbk';
   DROP USER 'cowrie'@'%';
   DROP USER 'cowrie'@'localhost';
   FLUSH PRIVILEGES;
   CREATE USER 'cowrie'@'localhost' IDENTIFIED BY '${cowriepassword}';
   GRANT ALL ON cowrie.* TO 'cowrie'@'localhost';
EOF


outlog "Checking, if the MySQL cowrie account can connect."
run 'mysql -u cowrie -p$cowriepassword  -e ";"'
if [ ${?} -ne 0 ] ; then
   outlog "The cowrie user can't connect to MySQL server using password $cowriepassword ."
   exit 9
else
   dlog "OK, MySQL cowrie user can connect using password $cowriepassword ."
fi


dlog "copying cowrie.cfg and adding entries"
run 'cp /srv/cowrie/cowrie.cfg.dist /srv/cowrie/cowrie.cfg'
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

drun 'cat /srv/cowrie/cowrie.cfg | grep -v "^#" | grep -v "^\$"'

dlog "modyfing /srv/cowrie/cowrie.cfg"
run "sed -i.bak 's/svr04/raspberrypi/' /srv/cowrie/cowrie.cfg"
run "sed -i.bak 's/^ssh_version_string = .*$/ssh_version_string = SSH-2.0-OpenSSH_6.7p1 Raspbian-5+deb8u1/' /srv/cowrie/cowrie.cfg"

drun 'cat /srv/cowrie/cowrie.cfg | grep -v "^#" | grep -v "^\$"'

# make output of simple text commands more real

dlog "creating output for text commands"
run 'df > /srv/cowrie/txtcmds/bin/df'
run 'dmesg > /srv/cowrie/txtcmds/bin/dmesg'
run 'mount > /srv/cowrie/txtcmds/bin/mount'
run 'ulimit > /srv/cowrie/txtcmds/bin/ulimit'
run 'lscpu > /srv/cowrie/txtcmds/usr/bin/lscpu'
run "echo '-bash: emacs: command not found' > /srv/cowrie/txtcmds/usr/bin/emacs"
run "echo '-bash: locate: command not found' > /srv/cowrie/txtcmds/usr/bin/locate"

run 'chown -R cowrie:cowrie /srv/cowrie'

# echo "###########  $progdir  ###########"

dlog "copying system files"

run "cp $progdir/../etc/init.d/cowrie /etc/init.d/cowrie"
run "cp $progdir/../etc/logrotate.d/cowrie /etc/logrotate.d"
run "cp $progdir/../etc/cron.hourly/cowrie /etc/cron.hourly"
run "cp $progdir/../etc/cron.hourly/dshield /etc/cron.hourly"
run "cp $progdir/../etc/mini-httpd.conf /etc/mini-httpd.conf"
run "cp $progdir/../etc/default/mini-httpd /etc/default/mini-httpd"

#
# Checking cowrie Dependencies
# see: https://github.com/micheloosterhof/cowrie/blob/master/requirements.txt
# ... and local requirements-output.txt
# ... and twisted dependencies: https://twistedmatrix.com/documents/current/installation/howto/optional.html
#

# format: <PKGNAME1>,<MINVERSION1>  <PKGNAME2>,<MINVERSION2>  <PKGNAMEn>,<MINVERSIONn>
#         meaning: <PGKNAME> must be installes in version >=<MINVERSION>
# if no MINVERSION: 0
# replace _ with -

# 2017-04-17: twisted v15.2.1 isn't working (problems with SSH key), neither is 17.1.0, so we use the latest version of 16 (16.6.0)
# 2017-04-23: seems to be working fine is all most current versions are installed using pip (w/o ANY distro package)
#             so if pkg not found it is OK (as of now) to install the most recent version

dlog "checking and installing Python packages for cowrie"
dlog "current requirements can be found here:"
dlog "cowrie: https://github.com/micheloosterhof/cowrie/blob/master/requirements.txt"
dlog "        and requirements-output.txt"
dlog "twisted: https://twistedmatrix.com/documents/current/installation/howto/optional.html"

for PKGVER in twisted,16.6.0 cryptography,1.8.1 configparser,0 pyopenssl,16.2.0 gmpy2,0 pyparsing,0 packaging,0 appdirs,0 pyasn1-modules,0.0.8 attrs,0 service-identity,0 pycrypto,2.6.1 python-dateutil,0 tftpy,0 idna,0 pyasn1,0.2.3 requests,0 MySQL-python,0 ; do

   # echo "PKGVER: ${PKGVER}"

   PKG=`echo "${PKGVER}" | cut -d "," -f 1`
   VERREQ=`echo "${PKGVER}" | cut -d "," -f 2`
   VERREQLIST=`echo "${VERREQ}" | tr "." " "`

   VERINST=`pip show ${PKG} | grep "^Version: " | cut -d " " -f 2`

   if [ "${VERINST}" == "" ] ; then
      VERINST="0"
   fi

   VERINSTLIST=`echo "${VERINST}" | tr "." " "`

   # echo "PKG: ${PKG}"
   # echo "VERREQ: ${VERREQ}"
   # echo "VERREQLIST: ${VERREQLIST}"
   # echo "VERINST: ${VERINST}"
   # echo "VERINSTLIST: ${VERINSTLIST}"
   dlog "checking package ${PKG}: installed: v${VERINST}, required: v${VERREQ}"

   MUSTINST=0

   outlog "+ checking cowrie dependency: module '${PKG}' ..."

   if [ "${VERINST}" == "0" ] ; then
      outlog "  WARN: not found at all, will be installed"
      MUSTINST=1
      # as of now: install the most recent version if not installed yet
      run "pip install ${PKG}"
      if [ ${?} -ne 0 ] ; then
         # TODO: give the user a chance to continue w/o cowrie
         outlog "Error installing '${PKG}'. Aborting."
         exit 9
      fi
   else
      FIELD=1
      # check if version number of installed module is sufficient
      for VERNO in ${VERREQLIST} ; do
         # echo "FIELD: ${FIELD}"
         FIELDINST=`echo "${VERINSTLIST}" | cut -d " " -f "${FIELD}" `
         if [ "${FIELDINST}" == "" ] ; then
            FIELDINST=0
         fi
         FIELDREQ=`echo "${VERREQLIST}" | cut -d " " -f "${FIELD}" `
         if [ "${FIELDREQ}" == "" ] ; then
            FIELDREQ=0
         fi
         if [ ${FIELDINST} -lt ${FIELDREQ} ] ; then
            # first version string from left with lower number installed -> update
            MUSTINST=1
            break
         elif [ ${FIELDINST} -gt ${FIELDREQ} ] ; then
            # first version string from left with hight number installed -> done
            break
         fi
         FIELD=`echo "$((${FIELD} + 1))"`
      done
      if [ ${MUSTINST} -eq 1 ] ; then
         outlog "  WARN: is installed in v${VERINST} but must at least be v${VERREQ}, will be updated"
         run "pip install ${PKG}==${VERREQ}"
         if [ ${?} -ne 0 ] ; then
            # TODO: give the user a chance to continue w/o cowrie
            outlog "Error upgrading '${PKG}'. Aborting."
            exit 9
         fi
      fi
   fi

   # echo "MUSTINST: ${MUSTINST}"

   if [ ${MUSTINST} -eq 0 ] ; then
      outlog "  OK: is installed in a sufficient version, nothing to do"
   fi


done

###########################################################
## Setting up Services
###########################################################


# setting up services
dlog "setting up services: cowrie, mini-httpd"
run 'update-rc.d cowrie defaults'
run 'update-rc.d mini-httpd defaults'


###########################################################
## Setting up postfix
###########################################################

#
# installing postfix as an MTA
#
outlog "Installing and configuring postfix."
dlog "uninstalling postfix"
run 'apt-get -y -q purge postfix'
dlog "preparing installation of postfix"
echo "postfix postfix/mailname string raspberrypi" | debconf-set-selections
echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections
echo "postfix postfix/mynetwork string '127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128'" | debconf-set-selections
echo "postfix postfix/destinations string raspberrypi, localhost.localdomain, localhost" | debconf-set-selections

outlog "package configuration for postfix"
run 'debconf-get-selections | grep postfix'
dlog "installing postfix"
run 'apt-get -y -q install postfix'


###########################################################
## Configuring MOTD
###########################################################

#
# modifying motd
#

dlog "installing /etc/motd"
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

run "mv $TMPDIR/motd /etc/motd"
run "chmod 644 /etc/motd"
run "chown root:root /etc/motd"

drun "cat /etc/motd"


###########################################################
## Handling of CERTs
###########################################################


#
# checking / generating certs
# if already there: ask if generate new
#

dlog "checking / generating certs"

GENCERT=1

drun "ls ../etc/CA/certs/*.crt 2>/dev/null"

if [ `ls ../etc/CA/certs/*.crt 2>/dev/null | wc -l ` -gt 0 ]; then
   dlog "CERTs may already be there, asking user"
   dialog --title 'Generating CERTs' --yesno "You may already have CERTs generated. Do you want me to re-generate CERTs and erase all existing ones?" 10 50
   response=$?
   case $response in
      ${DIALOG_OK}) 
         dlog "user said OK to generate new CERTs, so removing old CERTs"
         # cleaning up old certs
         run 'rm ../etc/CA/certs/*'
         run 'rm ../etc/CA/keys/*'
         run 'rm ../etc/CA/requests/*'
         run 'rm ../etc/CA/index.*'
         GENCERT=1
         ;;
      ${DIALOG_CANCEL}) 
         dlog "user said no, so no new CERTs will be created, using existing ones"
         GENCERT=0
         ;;
      ${DIALOG_ESC}) 
         dlog "user pressed ESC, aborting"
         exit 5
         ;;
   esac
fi

if [ ${GENCERT} -eq 1 ] ; then
   dlog "generating new CERTs using ./makecert.sh"
   ./makecert.sh
fi


###########################################################
## Done :)
###########################################################

outlog
outlog
outlog Done. 
outlog
outlog "Please reboot your Pi now."
outlog
outlog "For feedback, please e-mail jullrich@sans.edu or file a bug report on github"
outlog "Please include a sanitized version of /etc/dshield.conf in bug reports."
outlog "To support logging to MySQL, a MySQL server was installed. The root password is $mysqlpassword"
outlog
outlog "IMPORTANT: after rebooting, the Pi's ssh server will listen on port 12222"
outlog "           connect using ssh -p 12222 $SUDO_USER@$ipaddr"
outlog


