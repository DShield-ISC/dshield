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


readonly version=0.47

#
# Major Changes (for details see Github):
#
# - V0.47
#   - many small changes, see GitHub
#
# - V0.46 (Gebhard)
#   - removed obsolete suff (already commented out)
#   - added comments
#   - some cleanup
#   - removed mini http
#   - added multicast disable rule to ignore multicasts for dshield logs
#   - dito broadcasts to 255.255.255.255
#   - ask if automatic updates are OK
#
# - V0.45 (Johannes)
#    - enabled web honeypot
#
# - V0.44 (Johannes)
#   - enabled telnet in cowrie
#
# - V0.43 (Gebhard)
#   - revised cowrie installation to reflect current instructions
#
# - V0.42
#   - quick fix for Johannes' experiments with new Python code
#     (create dshield.ini with default values)
#   - let user choose between old, working and experimental stuff
#     (idea: copy all stuff but only activate that stuff the user chose
#      so the user can experiment even if he chose mature)
#
# - V0.41
#   - corrected firewall logging to dshield: in prior versions
#     the redirected ports would be logged and reported, not
#     the ports from the original requests (so ssh connection
#     attempts were logged as attempts to connect to 2222)
#   - changed firewall rules: access only allowed to honeypot ports
#   - some configuration stuff
#   - some bugfixes
#
# - V0.4
#   - major additions and rewrites (e.g. added logging)
#
#
# TODOs:
# - ask for additional / new values in dshield.ini

# target directory for server components
TARGETDIR="/srv"
DSHIELDDIR="${TARGETDIR}/dshield"
COWRIEDIR="${TARGETDIR}/cowrie" # remember to also change the init.d script!
LOGDIR="${TARGETDIR}/log"
WEBDIR="${TARGETDIR}/www"
INSTDATE="`date +'%Y-%m-%d_%H%M%S'`"
LOGFILE="${LOGDIR}/install_${INSTDATE}.log"

# which ports will be handled e.g. by cowrie (separated by blanks)
# used e.g. for setting up block rules for trusted nets
# use the ports after PREROUTING has been excecuted, i.e. the redirected (not native) ports
# note: doesn't make sense to ask the user because cowrie is configured statically
#
# <SVC>HONEYPORT: target ports for requests, i.e. where the honey pot daemon listens on
# <SVC>REDIRECT: source ports for requests, i.e. which ports should be redirected to the honey pot daemon
# HONEYPORTS: all ports a honey pot is listening on so that the firewall can be configured accordingly
SSHHONEYPORT=2222
TELNETHONEYPORT=2223
WEBHONEYPORT=8000
SSHREDIRECT="22"
TELNETREDIRECT="23 2323"
WEBREDIRECT="80 8080 7547 5555 9000"
HONEYPORTS="${SSHHONEYPORT} ${TELNETHONEYPORT} ${WEBHONEYPORT}"


# which port the real sshd should listen to
SSHDPORT="12222"

# Debug Flag
# 1 = debug logging, debug commands
# 0 = normal logging, no extra commands
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

# copy file(s) and chmod
# $1: file (opt. incl. direcorty / absolute path)
#     can also be a directory, but then chmod can't be done
# $2: dest dir
# optional: $3: chmod bitmask (only if $1 isn't a directory)
do_copy () { 
   dlog "copying ${1} to ${2} and chmod to ${3}"
   if [ -d ${1} ] ; then
      if [ "${3}" != "" ] ; then
         # source is a directory, but chmod bitmask given nevertheless, issue a warning
         dlog "WARNING: do_copy: $1 is a directory, but chmod bitmask given, ignored!"
      fi
      run "cp -r ${1} ${2}"
   else
      run "cp ${1} ${2}"
   fi
   if [ ${?} -ne 0 ] ; then
      outlog "Error copying ${1} to ${2}. Aborting."
      exit 9
   fi
   if [ "${3}" != "" -a ! -d ${1} ] ; then
      # only if $1 isn't a directory!
      if [ -f ${2} ] ; then
         # target is a file, chmod directly
         run "chmod ${3} ${2}"
      else
         # target is a directory, so use basename
         run "chmod ${3} ${2}/`basename ${1}`"
      fi
      if [ ${?} -ne 0 ] ; then
         outlog "Error executing chmod ${3} ${2}/${1}. Aborting."
         exit 9
      fi
   fi

}

###########################################################
## MAIN
###########################################################

clear

###########################################################
## basic checks
###########################################################


echo ${LINE}

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

dlog "parent process: $(ps -o comm= $PPID)"

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
   dist='apt'
   distversion=""
fi

if [ "$ID" == "raspbian" ] && [ "$VERSION_ID" == "8" ] ; then
   dist='apt'
   distversion=r8
fi

if [ "$ID" == "raspbian" ] && [ "$VERSION_ID" == "9" ] ; then
   dist='apt'
   distversion=r9
   
fi

if [ "$ID" == "amzn" ] && [ "$VERSION_ID" == "2016.09" ] ; then 
   dist='yum';
   distversion=a201909
fi

dlog "dist: ${dist}, distversion: ${distversion}"

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
   # OS packages: no python modules
   # 2017-05-17: added python-virtualenv authbind for cowrie

# distinguishing between rpi versions 
   if [ "$distversion" == "r9" ]; then
       run 'apt-get -y -q install build-essential dialog git libffi-dev libmpc-dev libmpfr-dev libpython-dev libswitch-perl libwww-perl mysql-client python2.7-minimal randomsound rng-tools unzip libssl-dev default-libmysqlclient-dev python-virtualenv authbind python-requests python-urllib3'
   else
       run 'apt-get -y -q install build-essential dialog git libffi-dev libmpc-dev libmpfr-dev libpython-dev libswitch-perl libwww-perl mysql-client python2.7-minimal randomsound rng-tools unzip libssl-dev libmysqlclient-dev python-virtualenv authbind python-requests python-urllib3'
   fi
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

dlog "Offering user last chance to quit with a nearly untouched system."
dialog --title '### WARNING ###' --colors --yesno "You are about to turn this Raspberry Pi into a honeypot. This software assumes that the device is \ZbDEDICATED\Zn to this task. There is no simple uninstall (e.g. IPv6 will be disabled). If something breaks you may need to reinstall from scratch. This script will try to do some magic in installing and configuring your to-be honeypot. But in the end \Zb\Z1YOU\Zn are responsible to configure it in a safe way and make sure it is kept up to date. An orphaned or non-monitored honeypot will become insecure! Do you want to proceed?" 0 0
response=$?
case $response in
   ${DIALOG_CANCEL}) 
      dlog "User clicked CANCEL"
      outlog "Terminating installation by your command. The system shouldn't have been hurt too much yet ..."
      outlog "See ${LOGFILE} for details."
      exit 5
      ;;
   ${DIALOG_ESC})
      dlog "User pressed ESC"
      outlog "Terminating installation by your command. The system shouldn't have been hurt too much yet ..."
      outlog "See ${LOGFILE} for details."
      exit 5
      ;;
esac

###########################################################
## let the user decide:
## working stuff vs. experimental
###########################################################

dlog "Offering user choice of maturity."

exec 3>&1
VALUES=$(dialog --title 'Installaion Flavour' --radiolist "We offer two different installation flavours: mature (this is known to be working in general) and experimental (new stuff currently in development, don't expect things to work at all). Choose your taste." 0 0 2 \
   mature "" on \
   experimental "" off \
   2>&1 1>&3)

response=$?
exec 3>&-

case $response in
   ${DIALOG_CANCEL})
      dlog "User clicked CANCEL."
      outlog "Terminating installation by your command. The system shouldn't have been hurt too much yet ..."
      outlog "See ${LOGFILE} for details."
      exit 5
      ;;
   ${DIALOG_ESC})
      dlog "User pressed ESC"
      outlog "Terminating installation by your command. The system shouldn't have been hurt too much yet ..."
      outlog "See ${LOGFILE} for details."
      exit 5
      ;;
esac

if [ ${VALUES} == "mature" ] ; then
   MATURE=1
else
   MATURE=0
fi

dlog "MATURE: ${MATURE}"


###########################################################
## let the user decide:
## automatic updates OK?
###########################################################

dlog "Offering user choice if automatic updates are OK."

exec 3>&1
VALUES=$(dialog --title 'Automatic Updates' --radiolist "In future versions automatic updates of this distribution may be conducted. Please choose if you want them or if you want to keep up your dshield stuff up-to-date manually." 0 0 2 \
   manual "" on \
   automatic "" off \
   2>&1 1>&3)

response=$?
exec 3>&-

case $response in
   ${DIALOG_CANCEL})
      dlog "User clicked CANCEL."
      outlog "Terminating installation by your command. The system shouldn't have been hurt too much yet ..."
      outlog "See ${LOGFILE} for details."
      exit 5
      ;;
   ${DIALOG_ESC})
      dlog "User pressed ESC"
      outlog "Terminating installation by your command. The system shouldn't have been hurt too much yet ..."
      outlog "See ${LOGFILE} for details."
      exit 5
      ;;
esac

if [ ${VALUES} == "manual" ] ; then
   MANUPDATES=1
else
   MANUPDATES=0
fi

dlog "MANUPDATES: ${MANUPDATES}"


###########################################################
## Stopping Cowrie if already installed
###########################################################
clear
if [ -x /etc/init.d/cowrie ] ; then
   outlog "Existing cowrie startup file found, stopping cowrie."
   run '/etc/init.d/cowrie stop'
   outlog "... giving cowrie time to stop ..."
   run 'sleep 10'
   outlog "... OK."
fi


###########################################################
## PIP
###########################################################

outlog "check if pip is already installed"

run 'pip > /dev/null'

if [ ${?} -gt 0 ] ; then
   # nice, no pip found

   outlog "no pip found, installing pip"

   run 'wget -qO $TMPDIR/get-pip.py https://bootstrap.pypa.io/get-pip.py'
   if [ ${?} -ne 0 ] ; then
      outlog "Error downloading get-pip, aborting."
      exit 9
   fi
   run 'python $TMPDIR/get-pip.py'
   if [ ${?} -ne 0 ] ; then
      outlog "Error running get-pip, aborting."
      exit 9
   fi

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

drun 'pip list --format=legacy'


###########################################################
## Random number generator
###########################################################

#
# yes. this will make the random number generator less secure. but remember this is for a honeypot
#

dlog "Changing random number generator settings."
run 'echo "HRNGDEVICE=/dev/urandom" > /etc/default/rnd-tools'


###########################################################
## Disable IPv6
###########################################################

dlog "Disabling IPv6 in /etc/modprobe.d/ipv6.conf"
run "mv /etc/modprobe.d/ipv6.conf /etc/modprobe.d/ipv6.conf.bak"
cat > /etc/modprobe.d/ipv6.conf <<EOF
# Don't load ipv6 by default
alias net-pf-10 off
# uncommented
alias ipv6 off
# added
options ipv6 disable_ipv6=1
# this is needed for not loading ipv6 driver
blacklist ipv6
EOF
run "chmod 644 /etc/modprobe.d/ipv6.conf"
drun "cat /etc/modprobe.d/ipv6.conf.bak"
drun "cat /etc/modprobe.d/ipv6.conf"


###########################################################
## Handling existing config
###########################################################

# legacy config file, still used for most stuff
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

# fancy new config file, only used for experimental stuff as of now
if [ -f /etc/dshield.ini ] ; then
   dlog "dshield.ini found, content follows"
   drun 'cat /etc/dshield.ini'
   dlog "securing dshield.ini"
   run 'chmod 600 /etc/dshield.ini'
   run 'chown root:root /etc/dshield.ini'
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

if [ "${mysqlpassword}" == "" ] ; then
   outlog "MySQL root password is empty, this won't work"
   outlog "(perhaps no dshield.conf and not allowed to install MySQL on my own)"
   dlog "nomysql: ${nomysql}"
   drun "ls -la /etc/dshield.conf"
   if [ -f  /root/.my.cnf ] ; then
      outlog "Trying to get password from /root/.my.cnf"
      if [ `grep "user=root"  /root/.my.cnf | wc -l ` -eq 1 ] ; then
         if [ `grep "password="  /root/.my.cnf | wc -l  ` -eq 1 ] ; then
            drun 'grep "password="  /root/.my.cnf | cut -d "=" -f2' 
            mysqlpassword=`grep "password="  /root/.my.cnf | cut -d "=" -f2`
         else
            # more than one password found
            dlog "No or multiple lines with 'password=' found in /root/.my.cnf"
         fi 
      else
         dlog "No or multiple lines with 'user=root' found in /root/.my.cnf"
      fi
   else 
      dlog "No /root/.my.cnf found."
   fi
fi

if [ "${mysqlpassword}" == "" ] ; then
   dlog "OK, still no MySQL password for root, aksing user"
   exec 3>&1
   mysqlpassword=$(dialog --title 'No MySQL root password found' --form "I wasn't able to find any MySQL root password. If you know it: please provide it here. If not: cancel, restart installation and choose to re-install MySQL." 12 50 0 \
      "MySQL root password:" 1 2 "$mysqlpassword" 1 24 20 60 2>&1 1>&3)
   response=${?}
   exec 3>&-
   case ${response} in
      ${DIALOG_OK})
         ;;
      ${DIALOG_CANCEL})
         dlog "User canceled MySQL root pw dialogue."
         exit 5
         ;;
      ${DIALOG_ESC})
         dlog "User pressed ESC in MySQL root pw dialogue."
         exit 5
         ;;
   esac
fi

if [ "${mysqlpassword}" == "" ] ; then
   outlog "Still no MySQL root password. Giving up."
   exit 5
fi

outlog "Checking, if the MySQL root account can connect."
run 'mysql -u root -p$mysqlpassword  -e ";"'
if [ ${?} -ne 0 ] ; then
   outlog "The root user can't connect to MySQL server using password $mysqlpassword ."
   outlog "Perhaps obsolete password in /etc/dshield.conf?"
   outlog "Perhaps no password at all, even not in /root/.my.cnf?"
   outlog "Please see logfile for details."
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

	       # TODO: urlencode($user)
	       user=`echo $email | sed 's/+/%2b/' | sed 's/@/%40/'`
               dlog "Checking API key ..."
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
# changes starting V0.41:
# - logging for dshield done in PREROUTING
# - only access to honeypot ports allowed for untrusted nets
#

# 
# requirements:
#
# 1. every access from untrusted networks is logged for dshield with the correct port
#    (up to V0.4 of this script there was a bug so that the logging for dshield took place
#     for the redirected honeypot ports and not the original ones)
# 2. for untrusted nets only honeypot ports (redirected ports) are accessible
# 3. access to "official" services like ssh is only allowed for trusted IPs
# 4. for trusted IPs the firewall logging can be disabled 
#    (to eliminate reporting irrelevant / false / internal packets)
# 5. for listed IPs the honeypot can be disabled 
#    (to eliminate reporting of legitimate credentials)
# 6. honeyport services don't run on official ports 
#    (redirect official ports to honeypot ports)
# 7. redirected honeypot ports can be accessed from untrusted nets
# 8. secure default 
#
# Firewall Layout:
#
# PREROUTING:
# - no logging for trusted nets -> skip rest of chain (4.)
#   (this means for trusted nets the redirects for
#    honeypot ports don't happen, but this shouldn't matter)
# - logging of all access attempts (1.)
# - redirect for honeypot ports (6.)
#
# INPUT:
# - allow localhost
# - allow related, established
# - disable access to honeypot ports for internal nets (5.)
# - allow access to daemon / admin ports only for internal nets (2., 3.)
# - allow access to honeypot ports (2., 7.)
# - default policy: DROP (8.)

##---------------------------------------------------------
## default interface 
##---------------------------------------------------------

dlog "firewall config: figuring out default interface"

# if we don't have one configured, try to figure it out
dlog "interface: ${interface}"
drun 'ip link show'
if [ "$interface" == "" ] ; then
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
      "Honeypot Interface:" 1 2 "$interface" 1 25 15 15 2>&1 1>&3)
   response=${?}
   exec 3>&-
      case ${response} in
         ${DIALOG_OK})
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
         ;;
      ${DIALOG_CANCEL})
         dlog "User canceled default interface dialogue."
         exit 5
         ;;
      ${DIALOG_ESC})
         dlog "User pressed ESC in default interface dialogue."
         exit 5
         ;;
   esac
done # while interface not OK

dlog "Interface: $interface"

##---------------------------------------------------------
## figuring out local network
##---------------------------------------------------------

dlog "firewall config: figuring out local network"

drun "ip addr show  eth0"
drun "ip addr show  eth0 | grep 'inet ' |  awk '{print \$2}' | cut -f1 -d'/'"
ipaddr=`ip addr show  eth0 | grep 'inet ' |  awk '{print $2}' | cut -f1 -d'/'`
dlog "ipaddr: ${ipaddr}"

drun "ip route show"
drun "ip route show | grep eth0 | grep 'scope link' | cut -f1 -d' '"
localnet=`ip route show | grep eth0 | grep 'scope link' | cut -f1 -d' '`
dlog "localnet: ${localnet}"

# additionally we will use any connection to current sshd 
# (ignroing config and using real connections)
# as trusted / local IP (just to make sure we include routed networks)
drun "grep '^Port' /etc/ssh/sshd_config | awk '{print \$2}'"
CURSSHDPORT=`grep '^Port' /etc/ssh/sshd_config | awk '{print $2}'`
drun "netstat -an | grep ':${CURSSHDPORT}' | grep ESTABLISHED | awk '{print \$5}' | cut -d ':' -f 1 | sort -u | tr '\n' ' ' | sed 's/ $//'"
CONIPS=`netstat -an | grep ":${CURSSHDPORT}" | grep ESTABLISHED | awk '{print $5}' | cut -d ':' -f 1 | sort -u | tr '\n' ' ' | sed 's/ $//'`

localnetok=0
ADMINPORTS=$adminports
if [ "${ADMINPORTS}" == "" ] ; then
   # default: sshd (after reboot)
   ADMINPORTS="${SSHDPORT}"
fi
# we present the localnet and the connected IPs to the user
# so we are sure connection to the device will work after
# reboot at least for the current remote device
# (localips is from dshield.conf)
CONIPS="$localips ${CONIPS}"
dlog "CONIPS with config values before removing duplicates: ${CONIPS}"
CONIPS=`echo ${CONIPS} | tr ' ' '\n' | sort -u | tr '\n' ' ' | sed 's/ $//'`
dlog "CONIPS with removed duplicates: ${CONIPS}"

dlog "Getting local network, further IPs and admin ports from user ..."
while [ $localnetok -eq  0 ] ; do

   exec 3>&1
   RETVALUES=$(dialog --title 'Local Network and Access' --form "Configure admin access: which ports should be opened (separated by blank, at least sshd (${SSHDPORT})) for the local network, and further trused IPs / networks. All other access from these IPs and nets / to the ports will be blocked. Handle with care, use only trusted IPs / networks." 15 60 0 \
      "Local Network:" 1 2 "$localnet" 1 18 37 20 \
      "Further IPs:" 2 2 "${CONIPS}" 2 18 37 60 \
      "Admin Ports:" 3 2 "${ADMINPORTS}" 3 18 37 20 \
      2>&1 1>&3)
   response=${?}
   exec 3>&-

   case ${response} in
      ${DIALOG_OK})
         dlog "User input for local network & IPs: ${RETVALUES}"

         localnet=`echo "${RETVALUES}" | cut -d "
" -f 1`
         CONIPS=`echo "${RETVALUES}" | cut -d "
" -f 2`
         ADMINPORTS=`echo "${RETVALUES}" | cut -d "
" -f 3`

         dlog "user input localnet: ${localnet}"
         dlog "user input further IPs: ${CONIPS}"
         dlog "user input further admin ports: ${ADMINPORTS}"

         # OK (exit loop) if local network OK _AND_ admin ports not empty
         if [ `echo "$localnet" | egrep '^([0-9]{1,3}\.){3}[0-9]{1,3}\/[0-9]{1,2}$' | wc -l` -eq 1  -a -n "${ADMINPORTS// }" ] ; then
            localnetok=1
         fi

         if [ $localnetok -eq 0 ] ; then
            dlog "user provided localnet ${localnet} is not ok or adminports empty (${ADMINPORTS})"
            dialog --title 'Local Network Error' --msgbox 'The format of the local network is wrong (it has to be in Network/CIDR format, for example 192.168.0.0/16) or the admin portlist is empty (should contain at least the SSHD port (${ADMINPORTS})).' 10 40
         fi
      ;;
      ${DIALOG_CANCEL})
         dlog "User canceled local network access dialogue."
         exit 5
         ;;
      ${DIALOG_ESC})
         dlog "User pressed ESC in local network access dialogue."
         exit 5
         ;;
   esac
done

dialog --title 'Admin Access' --cr-wrap --msgbox "Admin access to ports:
${ADMINPORTS}
will be allowed for IPs / nets:
${localnet} and
${CONIPS}" 0 0

# save values for dshield.conf
# (localnet will be saved directly)
localips="'${CONIPS}'"
adminports="'${ADMINPORTS}'"


##---------------------------------------------------------
## IPs for which logging should be disabled
##---------------------------------------------------------

dlog "firewall config: IPs / nets for which firewall logging should NOT be done"

if [ "${nofwlogging}" == "" ] ; then
   # default: local net & connected IPs (as the user confirmed)
   nofwlogging="${localnet} ${CONIPS}"
   # remove duplicates
   nofwlogging=`echo ${nofwlogging} | tr ' ' '\n' | sort -u | tr '\n' ' ' | sed 's/ $//'`
fi

dlog "nofwlogging: ${nofwlogging}"

dlog "getting IPs from user ..."

exec 3>&1
NOFWLOGGING=$(dialog --title 'IPs to ignore for FW Log'  --form "IPs and nets the firewall should do no logging for (in notation iptables likes, separated by spaces).
Note: Traffic from these devices will also not be redirected to the honeypot ports.
" \
12 70 0 "Ignore FW Log:" 1 1 "${nofwlogging}" 1 17 47 100 2>&1 1>&3)
response=${?}
exec 3>&-

case ${response} in
   ${DIALOG_OK})
      ;;
   ${DIALOG_CANCEL})
      dlog "User canceled IP to ignore in FW log dialogue."
      exit 5
      ;;
   ${DIALOG_ESC})
      dlog "User pressed ESC in IP to ignore in FW log dialogue."
      exit 5
      ;;
esac

# for saving in dshield.conf
nofwlogging="'${NOFWLOGGING}'"

dlog "user provided nofwlogging: ${nofwlogging}"

if [ "${NOFWLOGGING}" == "" ] ; then
   # echo "No firewall log exceptions will be done."
   dialog --title 'No Firewall Log Exceptions' --msgbox 'No firewall logging exceptions will be installed.' 10 40
else
   dialog --title 'Firewall Logging Exceptions' --cr-wrap --msgbox "The firewall logging exceptions will be installed for IPs
${NOFWLOGGING}" 0 0
fi

##---------------------------------------------------------
## disable honepot for nets / IPs
##---------------------------------------------------------

dlog "firewall config: IPs and ports to disable honeypot for"

if [ "${nohoneyips}" == "" ] ; then
   # default: admin IPs and nets
   nohoneyips="${NOFWLOGGING}"
fi
dlog "nohoneyips: ${nohoneyips}"

if [ "${nohoneyports}" == "" ] ; then
   # default: cowrie ports
   nohoneyports="${HONEYPORTS}"
fi
dlog "nohoneyports: ${nohoneyports}"

dlog "getting IPs and ports from user"

exec 3>&1
NOHONEY=$(dialog --title 'IPs / Ports to disable Honeypot for'  --form "IPs and nets to disable honeypot for to prevent reporting internal legitimate access attempts (IPs / nets in notation iptables likes, separated by spaces / ports (not real but after PREROUTING, so as configured in honeypot) separated by spaces)." \
12 70 0 \
"IPs / Networks:" 1 1 "${nohoneyips}" 1 17 47 100  \
"Honeypot Ports:" 2 1 "${nohoneyports}" 2 17 47 100 2>&1 1>&3)
response=${?}
exec 3>&-

case ${response} in
   ${DIALOG_OK})
      ;;
   ${DIALOG_CANCEL})
      dlog "User canceled honeypot disable dialogue."
      exit 5
      ;;
   ${DIALOG_ESC})
      dlog "User pressed ESC in honeypot disable dialogue."
      exit 5
      ;;
esac

dlog "user provided NOHONEY: ${NOHONEY}"

NOHONEYIPS=`echo "${NOHONEY}"  | cut -d "
" -f 1`
NOHONEYPORTS=`echo "${NOHONEY}"  | cut -d "
" -f 2`

dlog "NOHONEYIPS: ${NOHONEYIPS}"
dlog "NOHONEYPORTS: ${NOHONEYPORTS}"

if [ "${NOHONEYIPS}" == "" -o "${NOHONEYPORTS}" == "" ] ; then
   dlog "at least one of the lines were empty, so can't do anything with the rest and will ignore it"
   NOHONEYIPS=""
   NOHONEYPORTS=""
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


##---------------------------------------------------------
## create actual firewall rule set
##---------------------------------------------------------
#
# Firewall Layout: see beginning of firewall section
#

clear

outlog "Doing further configuration"

dlog "creating /etc/network/iptables"

# create stuff for INPUT chain:
# - allow localhost
# - allow related, established
# - disable access to honeypot ports for internal nets (5.)
# - allow access to daemon / admin ports only for internal nets (2., 3.)
# - allow access to honeypot ports (2., 7.)
# - default policy: DROP (8.)

cat > /etc/network/iptables <<EOF

#
# 
#

*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]
# allow all on loopback
-A INPUT -i lo -j ACCEPT
# allow all for established connections
-A INPUT -i $interface -m state --state ESTABLISHED,RELATED -j ACCEPT
EOF

# insert IPs and ports for which honeypot has to be disabled
# as soon as possible
if [ "${NOHONEYIPS}" != "" -a "${NOHONEYIPS}" != " " ] ; then
   echo "# START: IPs / Ports honeypot should be disabled for"  >> /etc/network/iptables
   for NOHONEYIP in ${NOHONEYIPS} ; do
      for NOHONEYPORT in ${NOHONEYPORTS} ; do
         echo "-A INPUT -i $interface -s ${NOHONEYIP} -p tcp --dport ${NOHONEYPORT} -j REJECT" >> /etc/network/iptables
      done
   done
   echo "# END: IPs / Ports honeypot should be disabled for"  >> /etc/network/iptables
fi

# allow access to admin ports for local nets / IPs
echo "# START: allow access to admin ports for local IPs"  >> /etc/network/iptables
for PORT in ${ADMINPORTS} ; do
   # first: local network
   echo "-A INPUT -i $interface -s ${localnet} -p tcp --dport ${PORT} -j ACCEPT" >> /etc/network/iptables
   # second: other IPs
   for IP in ${CONIPS} ; do
      echo "-A INPUT -i $interface -s ${IP} -p tcp --dport ${PORT} -j ACCEPT" >> /etc/network/iptables
   done
done
echo "# END: allow access to admin ports for local IPs"  >> /etc/network/iptables

# allow access to noneypot ports
if [ "${HONEYPORTS}" != "" ] ; then
   echo "# START: Ports honeypot should be enabled for"  >> /etc/network/iptables
   for HONEYPORT in ${HONEYPORTS} ; do
      echo "-A INPUT -i $interface -p tcp --dport ${HONEYPORT} -j ACCEPT" >> /etc/network/iptables
   done
   echo "# END: Ports honeypot should be enabled for"  >> /etc/network/iptables
fi



# create stuff for PREROUTING chain:
# - no logging for trusted nets -> skip rest of chain (4.)
#   (this means for trusted nets the redirects for
#    honeypot ports don't happen, but this shouldn't matter)
# - logging of all access attempts (1.)
# - redirect for honeypot ports (6.)

cat >> /etc/network/iptables <<EOF
COMMIT
*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
# ignore multicasts, no logging
-A PREROUTING -i $interface -m pkttype --pkt-type multicast -j RETURN
# ignore broadcast, no logging
-A PREROUTING -i $interface -d 255.255.255.255 -j RETURN
EOF

# insert to-be-ignored IPs just before the LOGging stuff so that traffic will be handled by default policy for chain
if [ "${NOFWLOGGING}" != "" -a "${NOFWLOGGING}" != " " ] ; then
   echo "# START: IPs firewall logging should be disabled for"  >> /etc/network/iptables
   for NOFWLOG in ${NOFWLOGGING} ; do
      echo "-A PREROUTING -i $interface -s ${NOFWLOG} -j RETURN" >> /etc/network/iptables
   done
   echo "# END: IPs firewall logging should be disabled for"  >> /etc/network/iptables
fi

cat >> /etc/network/iptables <<EOF
# log all traffic with original ports
-A PREROUTING -i $interface -m state --state NEW,INVALID -j LOG --log-prefix " DSHIELDINPUT "
# redirect honeypot ports
EOF

echo "# - ssh ports" >> /etc/network/iptables
for PORT in ${SSHREDIRECT}; do
   echo "-A PREROUTING -p tcp -m tcp --dport ${PORT} -j REDIRECT --to-ports ${SSHHONEYPORT}" >> /etc/network/iptables
done

echo "# - telnet ports" >> /etc/network/iptables
for PORT in ${TELNETREDIRECT}; do
   echo "-A PREROUTING -p tcp -m tcp --dport ${PORT} -j REDIRECT --to-ports ${TELNETHONEYPORT}" >> /etc/network/iptables
done

echo "# - web ports" >> /etc/network/iptables
for PORT in ${WEBREDIRECT}; do
   echo "-A PREROUTING -p tcp -m tcp --dport ${PORT} -j REDIRECT --to-ports ${WEBHONEYPORT}" >> /etc/network/iptables
done

echo "COMMIT" >> /etc/network/iptables

run 'chmod 700 /etc/network/iptables'

dlog "/etc/network/iptables follows"
drun 'cat /etc/network/iptables'

dlog "Copying /etc/network/if-pre-up.d"

do_copy $progdir/../etc/network/if-pre-up.d/dshield /etc/network/if-pre-up.d 700


###########################################################
## Change real SSHD port
###########################################################


dlog "changing port for sshd"

run "sed -i.bak 's/^Port 22$/Port "${SSHDPORT}"/' /etc/ssh/sshd_config"

dlog "checking if modification was successful"
if [ `grep "^Port ${SSHDPORT}\$" /etc/ssh/sshd_config | wc -l` -ne 1 ] ; then
   dialog --title 'sshd port' --ok-label 'Yep, understood.' --cr-wrap --msgbox 'Congrats, you had already changed your sshd port to something other than 22.

Please clean up and either
  - change the port manually to ${SSHDPORT}
     in  /etc/ssh/sshd_config    OR
  - clean up the firewall rules and
     other stuff reflecting YOUR PORT' 13 50

   dlog "check unsuccessful, port ${SSHDPORT} not found in sshd_config"
   drun 'cat /etc/ssh/sshd_config  | grep -v "^\$" | grep -v "^#"'
else
   dlog "check successful, port change to ${SSHDPORT} in sshd_config"
fi

###########################################################
## Modifying syslog config
###########################################################


dlog "setting interface in syslog config"
# no %%interface%% in dshield.conf template anymore, so only copying file
# run 'sed "s/%%interface%%/$interface/" < $progdir/../etc/rsyslog.d/dshield.conf > /etc/rsyslog.d/dshield.conf'
do_copy $progdir/../etc/rsyslog.d/dshield.conf /etc/rsyslog.d 600

drun 'cat /etc/rsyslog.d/dshield.conf'

###########################################################
## Further copying / configuration
###########################################################


#
# moving dshield stuff to target directory
# (don't like to have root run scripty which are not owned by root)
#

run "mkdir -p ${DSHIELDDIR}"
do_copy $progdir/../srv/dshield/dshield.pl ${DSHIELDDIR} 700
do_copy $progdir/../srv/dshield/pifwparser.py ${DSHIELDDIR} 700
do_copy $progdir/../srv/dshield/weblogsubmit.py ${DSHIELDDIR} 700
do_copy $progdir/../srv/dshield/DShield.py ${DSHIELDDIR} 700

# check: automatic updates allowed?
if [ ${MANUPDATES} -eq 0 ]; then
   dlog "automatic updates OK, configuring"
   run 'touch ${DSHIELDDIR}/auto-update-ok'
fi


#
# "random" offset for cron job so not everybody is reporting at once
#

dlog "creating /etc/cron.d/dshield"
offset1=`shuf -i0-29 -n1`
offset2=$((offset1+30));

# legacy stuff
if [ ${MATURE} -eq 1 ] ; then
   echo "${offset1},${offset2} * * * * root ${DSHIELDDIR}/dshield.pl" > /etc/cron.d/dshield
   echo "${offset1},${offset2} * * * * root cd ${DSHIELDDIR}; ./weblogsubmit.py" >> /etc/cron.d/dshield 
else # Johannes' experiments ;-)
   cat > /etc/cron.d/dshield <<EOF
$offset1,$offset2 * * * * root ${DSHIELDDIR}/pifwparser.py
EOF
fi

drun 'cat /etc/cron.d/dshield'


#
# Update dshield Configuration
#
dlog "creating new /etc/dshield.conf"
if [ -f /etc/dshield.conf ]; then
   dlog "old dshield.conf follows"
   drun 'cat /etc/dshield.conf'
   run 'mv /etc/dshield.conf /etc/dshield.conf.${INSTDATE}'
fi
dlog "creating new /etc/dshield.ini"
if [ -f /etc/dshield.ini ]; then
   dlog "old dshield.ini follows"
   drun 'cat /etc/dshield.ini'
   run 'mv /etc/dshield.ini /etc/dshield.ini.${INSTDATE}'
fi

# legacy config file
run 'touch /etc/dshield.conf'
run 'chmod 600 /etc/dshield.conf'

run 'echo "uid=$uid" >> /etc/dshield.conf'
run 'echo "apikey=$apikey" >> /etc/dshield.conf'
run 'echo "email=$email" >> /etc/dshield.conf'
run 'echo "interface=$interface" >> /etc/dshield.conf'
run 'echo "localnet=$localnet" >> /etc/dshield.conf'
run 'echo "localips=$localips" >> /etc/dshield.conf'
run 'echo "adminports=$adminports" >> /etc/dshield.conf'
run 'echo "mysqlpassword=$mysqlpassword" >> /etc/dshield.conf'
run 'echo "mysqluser=root" >> /etc/dshield.conf'
run 'echo "version=$version" >> /etc/dshield.conf'
run 'echo "progdir=${DSHIELDDIR}" >> /etc/dshield.conf'
run 'echo "nofwlogging=$nofwlogging" >> /etc/dshield.conf'
run 'echo "nohoneyips=$nohoneyips" >> /etc/dshield.conf'
run 'echo "nohoneyports=$nohoneyports" >> /etc/dshield.conf'

dlog "new /etc/dshield.conf follows"
drun 'cat /etc/dshield.conf'

# new shiny config file
run 'touch /etc/dshield.ini'
run 'chmod 600 /etc/dshield.ini'

run 'echo "[DShield]" >> /etc/dshield.ini'
run 'echo "userid=$uid" >> /etc/dshield.ini'
run 'echo "apikey=$apikey" >> /etc/dshield.ini'
run 'echo "# the following lines will be used by a new feature of the submit code: "  >> /etc/dshield.ini'
run 'echo "# replace IP with other value and / or anonymize parts of the IP"  >> /etc/dshield.ini'
run 'echo "honeypotip=" >> /etc/dshield.ini'
run 'echo "replacehoneypotip=" >> /etc/dshield.ini'
run 'echo "anonymizeip=" >> /etc/dshield.ini'
run 'echo "anonymizemask=" >> /etc/dshield.ini'

dlog "new /etc/dshield.ini follows"
drun 'cat /etc/dshield.ini'


###########################################################
## Installation of cowrie
###########################################################


#
# installing cowrie
# TODO: don't use a static path but a configurable one
#
# 2017-05-17: revised section to reflect current installation instructions
#             https://github.com/micheloosterhof/cowrie/blob/master/INSTALL.md
#

dlog "installing cowrie"

# step 1 (Install OS dependencies): done

# step 2 (Create a user account)
dlog "checking if cowrie OS user already exists"
if ! grep '^cowrie:' -q /etc/passwd; then
   dlog "... no, creating"
   run 'adduser --gecos "Honeypot,A113,555-1212,555-1212" --disabled-password --quiet --home /srv/cowrie --no-create-home cowrie'
   outlog "Added user 'cowrie'"
else
   outlog "User 'cowrie' already exists in OS. Making no changes to OS user."
fi

# step 3 (Checkout the code)
# (we will stay with zip instead of using GIT for the time being)
dlog "downloading and unzipping cowrie"
run "wget -qO $TMPDIR/cowrie.zip https://github.com/micheloosterhof/cowrie/archive/master.zip"
run "unzip -qq -d $TMPDIR $TMPDIR/cowrie.zip "

if [ ${?} -ne 0 ] ; then
   outlog "Something went wrong downloading cowrie, ZIP corrupt."
   exit 9
fi

if [ -d ${COWRIEDIR} ]; then
   dlog "old cowrie installation found, moving"
   # TODO: warn user, backup dl etc.
   run "mv ${COWRIEDIR} ${COWRIEDIR}.${INSTDATE}"
fi
dlog "moving extracted cowrie to ${COWRIEDIR}"
run "mv $TMPDIR/cowrie-master ${COWRIEDIR}"

# step 4 (Setup Virtual Environment)
outlog "Installing Python packages with PIP. This will take a LOOONG time."
OLDDIR=`pwd`
cd ${COWRIEDIR}
dlog "setting up virtual environment"
run 'virtualenv cowrie-env'
dlog "activating virtual environment"
run 'source cowrie-env/bin/activate'
dlog "installing dependencies: requirements.txt"
run 'pip install -r requirements.txt'
if [ ${?} -ne 0 ] ; then
   outlog "Error installing dependencies from requirements.txt. See ${LOGFILE} for details."
   exit 9
fi
dlog "installing dependencies requirements-output.txt"
run 'pip install -r requirements-output.txt'
if [ ${?} -ne 0 ] ; then
   outlog "Error installing dependencies from requirements-output.txt. See ${LOGFILE} for details."
   exit 9
fi
cd ${OLDDIR}

outlog "Doing further cowrie configuration."


# step 6 (Generate a DSA key)
dlog "generating cowrie SSH hostkey"
run "ssh-keygen -t dsa -b 1024 -N '' -f ${COWRIEDIR}/data/ssh_host_dsa_key "


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

# step 5 (Install configuration file)
dlog "copying cowrie.cfg and adding entries"
do_copy /srv/cowrie/cowrie.cfg.dist /srv/cowrie/cowrie.cfg 644
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
run "sed -i.back 's/^enabled = false/enabled = true/' /srv/cowrie/cowrie.cfg"
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

dlog "copying cowrie system files"

do_copy $progdir/../etc/init.d/cowrie /etc/init.d/cowrie 755
do_copy $progdir/../etc/logrotate.d/cowrie /etc/logrotate.d 644
do_copy $progdir/../etc/cron.hourly/cowrie /etc/cron.hourly 755


###########################################################
## Installation of web honeypot
###########################################################

dlog "installing web honeypot"

if [ -d ${WEBDIR} ]; then
   dlog "old web honeypot installation found, moving"
   # TODO: warn user, backup dl etc.
   run "mv ${WEBDIR} ${WEBDIR}.${INSTDATE}"
fi

run "mkdir -p ${WEBDIR}"

do_copy $progdir/../srv/www ${WEBDIR}/../
do_copy $progdir/../lib/systemd/system/webpy.service /lib/systemd/system/ 644
run "systemctl enable webpy.service"
run "systemctl daemon-reload"

# change ownership for web databases to cowrie as we will run the
# web honeypot as cowrie
touch ${WEBDIR}/DB/webserver.sqlite
run "chown cowrie ${WEBDIR}/DB"
run "chown cowrie ${WEBDIR}/DB/*"


###########################################################
## Copying further system files
###########################################################

dlog "copying further system files"

do_copy $progdir/../etc/cron.hourly/dshield /etc/cron.hourly 755
# do_copy $progdir/../etc/mini-httpd.conf /etc/mini-httpd.conf 644
# do_copy $progdir/../etc/default/mini-httpd /etc/default/mini-httpd 644


###########################################################
## Remove old mini-httpd stuff (if run as an update)
###########################################################

dlog "removing old mini-httpd stuff"
if [ -f /etc/mini-httpd.conf ] ; then
   mv /etc/mini-httpd.conf /etc/mini-httpd.conf.${INSTDATE}
fi
if [ -f /etc/default/mini-httpd ] ; then
   run 'update-rc.d mini-httpd disable'
   run 'update-rc.d -f mini-httpd remove'
   mv /etc/default/mini-httpd /etc/default/.mini-httpd.${INSTDATE}
fi



###########################################################
## Setting up Services
###########################################################


# setting up services
dlog "setting up services: cowrie"
run 'update-rc.d cowrie defaults'
# run 'update-rc.d mini-httpd defaults'


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
***    DShield Honeypot
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
outlog "Please include a sanitized version of /etc/dshield.conf in bug reports"
outlog "as well as a very carefully sanitized version of the installation log "
outlog "  (${LOGFILE})."
outlog "To support logging to MySQL, a MySQL server was installed. The root password is $mysqlpassword"
outlog
outlog "IMPORTANT: after rebooting, the Pi's ssh server will listen on port ${SSHDPORT}"
outlog "           connect using ssh -p ${SSHDPORT} $SUDO_USER@$ipaddr"
outlog
outlog "### Thank you for supporting the ISC and dshield! ###"
outlog


