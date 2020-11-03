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

# version 2020/09/21 01

readonly myversion=75

#
# Major Changes (for details see Github):
#
#
# - V75 (Johannes)
#   - fixes for Pythong3 (web.py)
#   - added a piid
#   - updated cowrie
#
# - V74 (Freek)
#   - webpy port to Python3 and bug fix
#
# - V73 (Johannes)
#   - misc improvements to installer and documentation
#
# - V72 (Johannes)
#   - version incremented for tech tuesday
#
# - V71 (Johannes)
#   - upgraded cowrie version
#   - moved to smaller cowrie zip file
#   - updated prep.sh to match new cowrie version
#
# - V70 (Johannes)
#   - added prep.sh
#   - Ubuntu 20.04 support
#
# - V65 (Johannes)
#   - bug fixes, in particular in fwlogparser
#   - enabled debug logging in install.sh
#
# - V64 (Johannes)
#   - cleanup / typos
#
# - V63 (Johannes)
#   - changed to integer versions for easier handling
#   - added "update" mode for non-interactive updates
#
# - V0.62 (Johannes)
#   - modified fwlogparser.py to work better with large logs
#     it will now only submit logs up to one day old, and not
#     submit more than 100,000 lines per run (it should run
#     twice an house). If there are more log, than it will skip
#     logs on future runs.
#
# - V0.61 (Johannes)
#   - redoing multiline dialogs to be more robust
#   - adding external honeypot IP to dshield.ini
#
# - V0.60 (Johannes)
#   - fixed a bug that prevented SSH logins to cowrie
#   - upgraded to cowrie 2.0.2 (latest)
#   - improved compatiblity with Ubuntu 18.04
#
# - V0.50 (Johannes)
#   - adding support for Raspbian 10 (buster)
#
# - V0.49 (Johannes)
#   - new cowrie configuration from scratch vs. using the template
#     that is included with cowrie
#
# - V0.48 (Johannes)
#   - fixed dshield logging in cowrie
#   - remove MySQL
#   - made local IP exclusion "wider"
#   - added email to configuration file for convinience
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

INTERACTIVE=1
FAST=0
BETA=0

# parse command line arguments

for arg in "$@"; do
    case $arg in
	"--update" | "--upgrade")
	    if [ -f /etc/dshield.ini ]; then
		echo "Non Interactive Update Mode"
		INTERACTIVE=0
	    else
		echo "Update mode requires a /etc/dshield.ini file"
		exit 9
	    fi
	    ;;
	"--fast")
	    FAST=1
	    echo "Fast mode enabled. This will skip some dependency checks and OS updates"
	    ;;
    esac
done    

# target directory for server components
TARGETDIR="/srv"
DSHIELDDIR="${TARGETDIR}/dshield"
COWRIEDIR="${TARGETDIR}/cowrie" # remember to also change the init.d script!
TXTCMDS=${COWRIEDIR}/share/cowrie/txtcmds
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
LINE="#############################################################################"

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

quotespace() {
    local line="${*}"
    if echo $line | egrep -q ' '; then
	if ! echo $line | egrep -q "'"; then
	    line="'${line}'"
	fi
    fi
    echo "$line"
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
   echo ${LINE}
   exit 9
else
   do_log "Check OK: User-ID is ${userid}."
fi

dlog "This is ${0} V${myversion}"

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


if [ "$ID" == "debian" ] && [ "$VERSION_ID" == "8" ] ; then
   dist='apt'
   distversion=r8
fi

if [ "$ID" == "debian" ] && [ "$VERSION_ID" == "9" ] ; then
   dist='apt'
   distversion=r9
fi

if [ "$ID" == "raspbian" ] && [ "$VERSION_ID" == "8" ] ; then
   dist='apt'
   distversion=r8
fi

if [ "$ID" == "raspbian" ] && [ "$VERSION_ID" == "9" ] ; then
   dist='apt'
   distversion=r9
fi

if [ "$ID" == "raspbian" ] && [ "$VERSION_ID" == "10" ] ; then
   dist='apt'
   distversion=r10
fi

if [ "$ID" == "ubuntu" ] && [ "$VERSION_ID" == "18.04" ] ; then 
   dist='apt'
   distversion='u18'
fi

if [ "$ID" == "ubuntu" ] && [ "$VERSION_ID" == "20.04" ] ; then
   dist='apt'
   distversion='u20'
fi


if [ "$ID" == "amzn" ] && [ "$VERSION_ID" == "2" ] ; then 
   dist='yum'
   distversion=2
fi

dlog "dist: ${dist}, distversion: ${distversion}"

if [ "$dist" == "invalid" ] ; then
   outlog "You are not running a supported operating systems. Right now, this script only works for Raspbian and Ubuntu 18.04/20.04 with experimental support for Amazon AMI Linux."
   outlog "Please ask info@dshield.org for help to add support for your flavor of Linux. Include the /etc/os-release file."
   exit 9
fi

if [ "$ID" != "raspbian" ] && [ "$VERSION_ID" != "20.04" ] && [ "$VERSION_ID" != "18.04" ] ; then
   outlog "ATTENTION: the latest versions of this script have been tested on Raspbian and Ubuntu 18.04/20.04 only."
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
if [ "$FAST" == 0 ]; then
outlog "Basic security checks"

dlog "making sure default password was changed"

if [ "$dist" == "apt" ]; then
    dlog "repair any package issues just in case"
    run 'dpkg --configure -a' 
   dlog "we are on pi and should check if password for user pi has been changed"
   if $progdir/passwordtest.pl | grep -q 1; then
      outlog "You have not yet changed the default password for the 'pi' user"
      outlog "Change it NOW ..."
      exit 9
   fi


   outlog "Updating your Installation (this can take a LOOONG time)"
   drun 'dpkg --list'
   run 'apt update'
   run 'apt -y -q dist-upgrade'

   outlog "Installing additional packages"
   # OS packages: no python modules
   # 2017-05-17: added python-virtualenv authbind for cowrie
   # 2020-07-03: turned this into a loop to make it more reliable
   # 2020-08-03: Added python install outside the loop for Ubuntu 18 vs 20
   #             these two installs may fail depending on ubuntu flavor
   # 2020-09-21: remove python2
   run 'apt -y -q remove python2'
   run 'apt -y -q remove python'
   run 'apt -y -q remove python-pip'
   run 'apt -y -q install python3-pip'      
   run 'apt -y -q install python3-requests'
   run 'apt -y -q remove python-requests'   
   

   for b in authbind build-essential curl dialog gcc git jq libffi-dev libmariadb-dev-compat libmpc-dev libmpfr-dev libpython3-dev libssl-dev libswitch-perl libwww-perl net-tools python3-dev python3-minimal python3-requests python3-urllib3 python3-virtualenv randomsound rng-tools sqlite3 unzip wamerican zip libsnappy-dev; do
       run "apt -y -q install $b"
       if ! dpkg -l $b >/dev/null 2>/dev/null; then
	   outlog "I was unable to install the $b package via apt"
	   outlog "This may be a temporary network issue. You may"
	   outlog "try and run this installer again. Or run this"
	   outlog "command as root to see if it works/returns errors"
	   outlog "apt -y install $b"
	   exit 9
       fi
   done
fi

if [ "$ID" == "amzn" ]; then
   outlog "Updating your Operating System"
   run 'yum -q update -y'
   outlog "Installing additional packages"
   run 'yum -q install -y dialog perl-libwww-perl perl-Switch rng-tools boost-random jq MySQL-python mariadb mariadb-devel iptables-services'
fi

else
    outlog "Skipping OS Update / Package install and security check in FAST mode"
fi



###########################################################
## last chance to escape before hurting the system ...
###########################################################
if [ "$INTERACTIVE" == 1 ] ; then
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
## automatic updates OK?
###########################################################

dlog "Offering user choice if automatic updates are OK."

exec 3>&1
VALUES=$(dialog --title 'Automatic Updates' --radiolist "In future versions automatic updates of this distribution may be conducted. Please choose if you want them or if you want to keep up your dshield stuff up-to-date manually." 0 0 2 \
   manual "" off \
   automatic "" on \
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


clear

fi

###########################################################
## Stopping Cowrie if already installed
###########################################################

if [ -x /etc/init.d/cowrie ] ; then
   outlog "Existing cowrie startup file found, stopping cowrie."
   run '/etc/init.d/cowrie stop'
   outlog "... giving cowrie time to stop ..."
   run 'sleep 10'
   outlog "... OK."
fi
# in case systemd is used
systemctl stop cowrie

if [ "$FAST" == "0" ] ; then

###########################################################
## PIP
###########################################################

outlog "check if pip3 is already installed"

run 'pip3 > /dev/null'

if [ ${?} -gt 0 ] ; then
   outlog "no pip3 found, installing pip3"
   run 'curl -s https://bootstrap.pypa.io/get-pip.py > $TMPDIR/get-pip.py'
   if [ ${?} -ne 0 ] ; then
      outlog "Error downloading get-pip, aborting."
      exit 9
   fi


   run 'python3 $TMPDIR/get-pip.py'
   if [ ${?} -ne 0 ] ; then
      outlog "Error running get-pip3, aborting."
      exit 9
   fi   
else
   # hmmmm ...
   # todo: automatic check if pip3 is OS managed or not
   # check ... already done :)

   outlog "pip3 found .... Checking which pip3 is installed...."

   drun 'pip3 -V'
   drun 'pip3  -V | cut -d " " -f 4 | cut -d "/" -f 3'
   drun 'find /usr -name pip3'
   drun 'find /usr -name pip3 | grep -v local'

   # if local is in the path then it's normally not a distro package, so if we only find local, then it's OK
   # - no local in pip3 -V output 
   #   OR
   # - pip3 below /usr without local
   # -> potential distro pip3 found
   if [ `pip3  -V | cut -d " " -f 4 | cut -d "/" -f 3` != "local" -o `find /usr -name pip3 | grep -v local | wc -l` -gt 0 ] ; then
      # pip3 may be distro pip3
      outlog "Potential distro pip3 found"
   else
      outlog "pip3 found which doesn't seem to be installed as a distro package. Looks ok to me."
   fi

fi

else
    outlog "Skipping PIP check in FAST mode"
fi

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

if [ -f /etc/dshield.ini ] ; then
   dlog "dshield.ini found, content follows"
   drun 'cat /etc/dshield.ini'
   dlog "securing dshield.ini"
   run 'chmod 600 /etc/dshield.ini'
   run 'chown root:root /etc/dshield.ini'
   outlog "reading old configuration"
   if grep -q 'uid=<authkey>' /etc/dshield.ini; then
      dlog "erasing <.*> pattern from dshield.ini"
      run "sed -i.bak 's/<.*>//' /etc/dshield.ini"
      dlog "modified content of dshield.ini follows"
      drun 'cat /etc/dshield.ini'
   fi
   # believe it or not, bash has a built in .ini parser. Just need to remove spaces around "="
   source <(grep = /etc/dshield.ini | sed 's/ *= */=/g')
   dlog "dshield.ini found, content follows"
   drun 'cat /etc/dshield.ini'
   dlog "securing dshield.ini"
   run 'chmod 600 /etc/dshield.ini'
   run 'chown root:root /etc/dshield.ini'
fi

# hmmm - this SHOULD NOT happen
if ! [ -d $TMPDIR ]; then
   outlog "${TMPDIR} not found, aborting."
   exit 9
fi
if [ "$INTERACTIVE" == "0" ]; then
    MANUPDATES=$manualupdates
    uid=$userid
    echo "check $userid $apikey"
    if [ "$userid" == "" ]; then
	echo "For interactive mode, dshield.ini has to contain a userid."
	exit 9
    fi
    if [ "$apikey" == "" ]; then
	echo "For interactive mode, dshield.ini has to contain an apikey."
	exit 9
    fi
fi
if [ "$piid" == "" ]; then
    piid=$(openssl rand -hex 10)
    dlog "new piid ${piid}"
else    
    dlog "old piid ${piid}"
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
if [ "$INTERACTIVE" == 1 ] ; then
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
	       run 'curl -s https://isc.sans.edu/api/checkapikey/$user/$nonce/$hash/$myversion > $TMPDIR/checkapi'
   
               dlog "Curl return code is ${?}"
   
               if ! [ -d "$TMPDIR" ]; then
                  # this SHOULD NOT happpen
                  outlog "Can not find TMPDIR ${TMPDIR}"
                  exit 9
               fi
   
               drun "cat ${TMPDIR}/checkapi"
   
               dlog "Examining result of API key check ..."
   
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
fi # interactive mode

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
   drun "ip -4 route show| grep '^default ' | cut -f5 -d' '"
   interface=`ip -4 route show| grep '^default ' | cut -f5 -d' '`
fi

# list of valid interfaces
drun "ip link show | grep '^[0-9]' | cut -f2 -d':' | tr -d '\n' | sed 's/^ //'"
validifs=`ip link show | grep '^[0-9]' | cut -f2 -d':' | tr -d '\n' | sed 's/^ //'`

# get honeypot external IPv4 address
honeypotip=$(curl -s https://www4.dshield.org/api/myip?json  | jq .ip | tr -d '"')

dlog "validifs: ${validifs}"

localnetok=0
if [ "$INTERACTIVE" == 1 ] ; then
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
fi # interactive mode
dlog "Interface: $interface"

##---------------------------------------------------------
## figuring out local network
##---------------------------------------------------------

dlog "firewall config: figuring out local network"

drun "ip addr show $interface"
drun "ip addr show $interface | grep 'inet ' |  awk '{print \$2}' | cut -f1 -d'/'"
ipaddr=`ip addr show $interface | grep 'inet ' |  awk '{print $2}' | cut -f1 -d'/'`
dlog "ipaddr: ${ipaddr}"

drun "ip route show"
drun "ip route show | grep $interface | grep 'scope link' | grep '/' | cut -f1 -d' '"
localnet=`ip route show | grep $interface | grep 'scope link' | cut -f1 -d' '`
# added most common private subnets. This will help if the Pi is in its
# own subnet (e.g. 192.168.1.0/24) which is part of a larger network.
# either way, hits from private IPs are hardly ever log worthy.
if echo $localnet | grep -q '^10\.'; then localnet='10.0.0.0/8'; fi
if echo $localnet | grep -q '^192\.168\.'; then localnet='192.168.0.0/16'; fi
if echo $localnet | grep -q '^172\.1[6-9]\.'; then localnet='172.16.0.0/12'; fi
if echo $localnet | grep -q '^172\.2[0-9]\.'; then localnet='172.16.0.0/12'; fi
if echo $localnet | grep -q '^172\.3[0-1]\.'; then localnet='172.16.0.0/12'; fi
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
CONIPS="$localips ${CONIPS}"
dlog "CONIPS with config values before removing duplicates: ${CONIPS}"
CONIPS=`echo ${CONIPS} | tr ' ' '\n' | egrep '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | sort -u | tr '\n' ' ' | sed 's/ $//'`
dlog "CONIPS with removed duplicates: ${CONIPS}"

if [ "$INTERACTIVE" == 1 ] ; then
dlog "Getting local network, further IPs and admin ports from user ..."
while [ $localnetok -eq  0 ] ; do
   dialog --title 'Local Network and Access' --form "Configure admin access: which ports should be opened (separated by blank, at least sshd (${SSHDPORT})) for the local network, and further trused IPs / networks. All other access from these IPs and nets / to the ports will be blocked. Handle with care, use only trusted IPs / networks." 15 60 0 \
      "Local Network:" 1 2 "$localnet" 1 18 37 20 \
      "Further IPs:" 2 2 "${CONIPS}" 2 18 37 60 \
      "Admin Ports:" 3 2 "${ADMINPORTS}" 3 18 37 20 \
   2> $TMPDIR/dialog.txt
   response=${?}

   case ${response} in
      ${DIALOG_OK})
         dlog "User input for local network & IPs:"
         localnet=`head -1 $TMPDIR/dialog.txt`
         CONIPS=`head -2 $TMPDIR/dialog.txt | tail -1`
         ADMINPORTS=`tail -1 $TMPDIR/dialog.txt`
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
fi # interactive mode

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
if [ "$INTERACTIVE" == 1 ] ; then
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

# for saving in dshield.ini
nofwlogging="'${NOFWLOGGING}'"

dlog "user provided nofwlogging: ${nofwlogging}"

if [ "${NOFWLOGGING}" == "" ] ; then
   # echo "No firewall log exceptions will be done."
   dialog --title 'No Firewall Log Exceptions' --msgbox 'No firewall logging exceptions will be installed.' 10 40
else
   dialog --title 'Firewall Logging Exceptions' --cr-wrap --msgbox "The firewall logging exceptions will be installed for IPs
${NOFWLOGGING}" 0 0
fi
fi # interactive mode
##---------------------------------------------------------
## disable honeypot for nets / IPs
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

if [ "$INTERACTIVE" == 1 ] ; then
dialog --title 'IPs / Ports to disable Honeypot for'  --form "IPs and nets to disable honeypot for to prevent reporting internal legitimate access attempts (IPs / nets in notation iptables likes, separated by spaces / ports (not real but after PREROUTING, so as configured in honeypot) separated by spaces)." \
12 70 0 \
"IPs / Networks:" 1 1 "${nohoneyips}" 1 17 47 100  \
"Honeypot Ports:" 2 1 "${nohoneyports}" 2 17 47 100 2>$TMPDIR/dialog.txt
response=${?}


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

dlog "user provided NOHONEY:"

NOHONEYIPS=`head -1 $TMPDIR/dialog.txt`
NOHONEYPORTS=`tail -1 $TMPDIR/dialog.txt`

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

fi # interactive mode
##---------------------------------------------------------
## create actual firewall rule set
##---------------------------------------------------------
#
# Firewall Layout: see beginning of firewall section
#
if [ "$INTERACTIVE" == 1 ] ; then
    clear
fi

outlog "Doing further configuration"

dlog "creating /etc/network/iptables"

# create stuff for INPUT chain:
# - allow localhost
# - allow related, established
# - disable access to honeypot ports for internal nets (5.)
# - allow access to daemon / admin ports only for internal nets (2., 3.)
# - allow access to honeypot ports (2., 7.)
# - default policy: DROP (8.)

if [ ! -d /etc/network ]; then
    run 'mkdir /etc/network'
fi

if [ -f /etc/network/iptables ]; then
    run "mv /etc/network/iptables /etc/network/iptables.${INSTDATE}"
fi

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
# log all traffic with original ports, but exclude traffic from unused/prive IPs.
-N DSHIELDLOG
-A DSHIELDLOG -s 10.0.0.0/8 -j RETURN
-A DSHIELDLOG -s 100.64.0.0/10 -j RETURN
-A DSHIELDLOG -s 127.0.0.0/8 -j RETURN
-A DSHIELDLOG -s 169.254.0.0/16 -j RETURN
-A DSHIELDLOG -s 172.16.0.0/12 -j RETURN
-A DSHIELDLOG -s 192.0.0.0/24 -j RETURN
-A DSHIELDLOG -s 192.0.2.0/24 -j RETURN
-A DSHIELDLOG -s 192.168.0.0/16 -j RETURN
-A DSHIELDLOG -s 224.0.0.0/4 -j RETURN
-A DSHIELDLOG -s 240.0.0.0/4 -j RETURN
-A DSHIELDLOG -s 255.255.255.255/32 -j RETURN
-A DSHIELDLOG -j LOG --log-prefix " DSHIELDINPUT "
-A DSHIELDLOG -j RETURN
-A PREROUTING -i $interface -m state --state NEW,INVALID -j DSHIELDLOG
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

do_copy $progdir/../etc/network/if-pre-up.d/dshield /etc/network/if-pre-up.d 775
# for ubuntu, we need to use netpland
if [ -d /etc/networkd-dispatcher/routable.d ] ; then
    do_copy $progdir/../etc/network/if-pre-up.d/dshield /etc/networkd-dispatcher/routable.d/10-dshield-iptables 775
fi
# for Ubuntu, we turn off UFW so it doesn't mess with our firewall rules
if systemctl | grep ufw ; then
    run 'systemctl disable ufw'
fi
# for Amazon's CentOS version, we use the iptables service
if [ "$ID" == "amzn" ] ; then
    run 'rm -f /etc/sysconfig/iptables'
    run 'ln -s /etc/network/iptables /etc/sysconfig/iptables'
    run 'systemctl enable iptables.service'
fi


###########################################################
## Change real SSHD port
###########################################################

if [ "$INTERACTIVE" == 1 ] ; then
dlog "changing port for sshd"

run "sed -i.bak 's/^[#\s]*Port 22\s*$/Port "${SSHDPORT}"/' /etc/ssh/sshd_config"

dlog "checking if modification was successful"
if [ `grep "^Port ${SSHDPORT}\$" /etc/ssh/sshd_config | wc -l` -ne 1 ] ; then
   dialog --title 'sshd port' --ok-label 'Understood.' --cr-wrap --msgbox "Congrats, you had already changed your sshd port to something other than 22.

Please clean up and either
  - change the port manually to ${SSHDPORT}
     in  /etc/ssh/sshd_config    OR
  - clean up the firewall rules and
     other stuff reflecting YOUR PORT" 13 50

   dlog "check unsuccessful, port ${SSHDPORT} not found in sshd_config"
   drun 'cat /etc/ssh/sshd_config  | grep -v "^\$" | grep -v "^#"'
else
   dlog "check successful, port change to ${SSHDPORT} in sshd_config"
fi
fi # interactive
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
do_copy $progdir/../srv/dshield/fwlogparser.py ${DSHIELDDIR} 700
do_copy $progdir/../srv/dshield/weblogsubmit.py ${DSHIELDDIR} 700
do_copy $progdir/../srv/dshield/DShield.py ${DSHIELDDIR} 700

# check: automatic updates allowed?

if [ "$MANUPDATES" -eq  "0" ]; then
   dlog "automatic updates OK, configuring"
   run 'touch ${DSHIELDDIR}/auto-update-ok'
fi


#
# "random" offset for cron job so not everybody is reporting at once
#

dlog "creating /etc/cron.d/dshield"
offset1=`shuf -i0-29 -n1`
offset2=$((offset1+30));
echo "${offset1},${offset2} * * * * root cd ${DSHIELDDIR}; ./weblogsubmit.py" > /etc/cron.d/dshield 
echo "${offset1},${offset2} * * * * root ${DSHIELDDIR}/fwlogparser.py" >> /etc/cron.d/dshield
offset1=`shuf -i0-59 -n1`
offset2=`shuf -i0-23 -n1`
echo "${offset1} ${offset2} * * * root cd ${progdir}; ./update.sh --cron >/dev/null " >> /etc/cron.d/dshield
offset1=`shuf -i0-59 -n1`
offset2=`shuf -i0-23 -n1`
echo "${offset1} ${offset2} * * * root /sbin/reboot" >> /etc/cron.d/dshield


drun 'cat /etc/cron.d/dshield'


#
# Update dshield Configuration
#
dlog "creating new /etc/dshield.ini"
if [ -f /etc/dshield.ini ]; then
   dlog "old dshield.ini follows"
   drun 'cat /etc/dshield.ini'
   run 'mv /etc/dshield.ini /etc/dshield.ini.${INSTDATE}'
fi

# new shiny config file
run 'touch /etc/dshield.ini'
run 'chmod 600 /etc/dshield.ini'
run 'echo "[DShield]" >> /etc/dshield.ini'
run 'echo "interface=$interface" >> /etc/dshield.ini'
run 'echo "version=$myversion" >> /etc/dshield.ini'
run 'echo "email=$email" >> /etc/dshield.ini'
run 'echo "userid=$uid" >> /etc/dshield.ini'
run 'echo "apikey=$apikey" >> /etc/dshield.ini'
run 'echo "piid=$piid" >> /etc/dshield.ini'
run 'echo "# the following lines will be used by a new feature of the submit code: "  >> /etc/dshield.ini'
run 'echo "# replace IP with other value and / or anonymize parts of the IP"  >> /etc/dshield.ini'
run 'echo "honeypotip=$honeypotip" >> /etc/dshield.ini'
run 'echo "replacehoneypotip=" >> /etc/dshield.ini'
run 'echo "anonymizeip=" >> /etc/dshield.ini'
run 'echo "anonymizemask=" >> /etc/dshield.ini'
run 'echo "fwlogfile=/var/log/dshield.log" >> /etc/dshield.ini'
nofwlogging=$(quotespace $nofwlogging)
run 'echo "nofwlogging=$nofwlogging" >> //etc/dshield.ini'
CONIPS="$(quotespace $CONIPS)"
run 'echo "localips=$CONIPS" >> /etc/dshield.ini'
ADMINPORTS=$(quotespace $ADMINPORTS)
run 'echo "adminports=$ADMINPORTS" >> /etc/dshield.ini'
nohoneyips=$(quotespace $nohoneyips)
run 'echo "nohoneyips=$nohoneyips" >> /etc/dshield.ini'
nohoneyports=$(quotespace $nohoneyports)
run 'echo "nohoneyports=$nohoneyports" >> /etc/dshield.ini'
run 'echo "logretention=7" >> /etc/dshield.ini'
run 'echo "minimumcowriesize=1000" >> /etc/dshield.ini'
run 'echo "manualupdates=$MANUPDATES" >> /etc/dshield.ini'
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
   run "adduser --gecos 'Honeypot,A113,555-1212,555-1212' --disabled-password --quiet --home ${COWRIEDIR} --no-create-home cowrie"
   outlog "Added user 'cowrie'"
else
   outlog "User 'cowrie' already exists in OS. Making no changes to OS user."
fi

# step 3 (Checkout the code)
# (we will stay with zip instead of using GIT for the time being)
dlog "downloading and unzipping cowrie"
if [ "$BETA" == 1 ] ; then    
    run "curl -s https://www.dshield.org/cowrie-beta.zip > $TMPDIR/cowrie.zip"
else
    run "curl -s https://www.dshield.org/cowrie.zip > $TMPDIR/cowrie.zip"
fi


if [ ${?} -ne 0 ] ; then
   outlog "Something went wrong downloading cowrie, ZIP corrupt."
   exit 9
fi
if [ -f $TMPDIR/cowrie.zip ]; then
  run "unzip -qq -d $TMPDIR $TMPDIR/cowrie.zip "
else 
  outlog "Can not find cowrie.zip in $TMPDIR"
  exit 9
fi
if [ -d ${COWRIEDIR} ]; then
   dlog "old cowrie installation found, moving"
   run "mv ${COWRIEDIR} ${COWRIEDIR}.${INSTDATE}"
fi
dlog "moving extracted cowrie to ${COWRIEDIR}"
if [ -d $TMPDIR/cowrie-master ]; then
 run "mv $TMPDIR/cowrie-master ${COWRIEDIR}"
else
 outlog "$TMPDIR/cowrie not found"
 exit 9
fi

# step 4 (Setup Virtual Environment)
outlog "Installing Python packages with PIP. This will take a LOOONG time."
OLDDIR=`pwd`
cd ${COWRIEDIR}
dlog "setting up virtual environment"
run 'virtualenv cowrie-env'
dlog "activating virtual environment"
run 'source cowrie-env/bin/activate'
dlog "installing dependencies: requirements.txt"
run 'pip3 install --upgrade pip3'
run 'pip3 install --upgrade -r requirements.txt'
run 'pip3 install --upgrade -r requirements-output.txt'
run 'pip3 install --upgrade bcrypt'
run 'pip3 install --upgrade pip3'
run 'pip3 install --upgrade -r requirements.txt'
run 'pip3 install --upgrade -r requirements-output.txt'
run 'pip3 install --upgrade bcrypt'
run 'pip3 install --upgrade requests'
if [ ${?} -ne 0 ] ; then
   outlog "Error installing dependencies from requirements.txt. See ${LOGFILE} for details.

   This part often fails due to timeouts from the servers hosting python packages. Best to try to rerun the install script again. It should remember your settings.
"
   exit 9
fi

# installing python dependencies. Most of these are for cowrie.
run 'pip3 install -r requirements.txt'
cd ${OLDDIR}

outlog "Doing further cowrie configuration."


# step 6 (Generate a DSA key)
dlog "generating cowrie SSH hostkey"
run "ssh-keygen -t dsa -b 1024 -N '' -f ${COWRIEDIR}/var/lib/cowrie/ssh_host_dsa_key "


# step 5 (Install configuration file)
dlog "copying cowrie.cfg and adding entries"
# adjust cowrie.cfg
export uid
export apikey
export hostname=`shuf /usr/share/dict/american-english | head -1 | sed 's/[^a-z]//g'`
export sensor_name=dshield-$uid-$version
fake1=`shuf -i 1-255 -n 1`
fake2=`shuf -i 1-255 -n 1`
fake3=`shuf -i 1-255 -n 1`
export fake_addr=`printf "10.%d.%d.%d" $fake1 $fake2 $fake3`
export arch=`arch`
export kernel_version=`uname -r`
export kernel_build_string=`uname -v | sed 's/SMP.*/SMP/'`
export ssh_version=`ssh -V 2>&1 | cut -f1 -d','`
export ttylog='false'
drun "cat ..${COWRIEDIR}/cowrie.cfg | envsubst > ${COWRIEDIR}/cowrie.cfg"

# make output of simple text commands more real

dlog "creating output for text commands"

run "mkdir -p ${TXTCMDS}/bin"
run "mkdir -p ${TXTCMDS}/usr/bin"
run "df > ${TXTCMDS}/bin/df"
run "dmesg > ${TXTCMDS}/bin/dmesg"
run "mount > ${TXTCMDS}/bin/mount"
run "ulimit > ${TXTCMDS}/bin/ulimit"
run "lscpu > ${TXTCMDS}/usr/bin/lscpu"
run "echo '-bash: emacs: command not found' > ${TXTCMDS}/usr/bin/emacs"
run "echo '-bash: locate: command not found' > ${TXTCMDS}/usr/bin/locate"

run 'chown -R cowrie:cowrie ${COWRIEDIR}'

# echo "###########  $progdir  ###########"

dlog "copying cowrie system files"

do_copy $progdir/../lib/systemd/system/cowrie.service /lib/systemd/system/cowrie.service 644
do_copy $progdir/../etc/cron.hourly/cowrie /etc/cron.hourly 755

# make sure to remove old cowrie start if they exist
if [ -f /etc/init.d/cowrie ] ; then
    rm -f /etc/init.d/cowrie
fi
run 'mkdir ${COWRIEDIR}/log'
run 'chmod 755 ${COWRIEDIR}/log'
run 'chown cowrie:cowrie ${COWRIEDIR}/log'
run 'mkdir ${COWRIEDIR}/log/tty'
run 'chmod 755 ${COWRIEDIR}/log/tty'
run 'chown cowrie:cowrie ${COWRIEDIR}/log/tty'
find /etc/rc?.d -name '*cowrie*' -delete
run 'systemctl daemon-reload'
run 'systemctl enable cowrie.service'



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
run "systemctl enable systemd-networkd.service systemd-networkd-wait-online.service"
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
# no longer needed. now done bu /etc/cron.d/dshield
# do_copy $progdir/../etc/cron.hourly/dshield /etc/cron.hourly 755
if [ -f /etc/cron.hourly/dshield ]; then
    run "rm /etc/cron.hourly/dshield"
fi
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
# dlog "setting up services: cowrie"
# run 'update-rc.d cowrie defaults'
# run 'update-rc.d mini-httpd defaults'


###########################################################
## Setting up postfix
###########################################################

#
# installing postfix as an MTA
# TODO: AWS/Yum based install
#


if [ "$dist" == "apt" ]; then
    outlog "Installing and configuring postfix."
    dlog "uninstalling postfix"
    run 'apt -y -q purge postfix'
    dlog "preparing installation of postfix"
    echo "postfix postfix/mailname string raspberrypi" | debconf-set-selections
    echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections
    echo "postfix postfix/mynetwork string '127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128'" | debconf-set-selections
    echo "postfix postfix/destinations string raspberrypi, localhost.localdomain, localhost" | debconf-set-selections
    outlog "package configuration for postfix"
    run 'debconf-get-selections | grep postfix'
    dlog "installing postfix"
    run 'apt -y -q install postfix'
fi
if grep -q 'inet_protocols = all' /etc/postfix/main.cf ; then
    sed -i 's/inet_protocols = all/inet_protocols = ipv4/' /etc/postfix/main.cf
fi
###########################################################
## Apt Cleanup
###########################################################

if [ "$dist" == "apt" ]; then
    run 'apt autoremove -y'
fi

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
if [ ! -f ../etc/CA/ca.serial ]; then
    echo 01 > ../etc/CA/ca.serial
fi
drun "ls ../etc/CA/certs/*.crt 2>/dev/null"
if [ `ls ../etc/CA/certs/*.crt 2>/dev/null | wc -l ` -gt 0 ]; then
    if [ "$INTERACTIVE" == 1 ] ; then
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
    else
        GENCERT=0
   fi #interactive
fi

if [ ${GENCERT} -eq 1 ] ; then
   dlog "generating new CERTs using ./makecert.sh"
   ./makecert.sh
fi

#
# creating PID directory
#

run 'mkdir /var/run/dshield'

# rotate dshield firewall logs
do_copy $progdir/../etc/logrotate.d/dshield /etc/logrotate.d 644
if [ -f "/etc/cron.daily/logrotate" ]; then
  run "mv /etc/cron.daily/logrotate /etc/cron.hourly"
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
outlog "Please include a sanitized version of /etc/dshield.ini in bug reports"
outlog "as well as a very carefully sanitized version of the installation log "
outlog "  (${LOGFILE})."
outlog
outlog "IMPORTANT: after rebooting, the Pi's ssh server will listen on port ${SSHDPORT}"
outlog "           connect using ssh -p ${SSHDPORT} $SUDO_USER@$ipaddr"
outlog
outlog "### Thank you for supporting the ISC and dshield! ###"
outlog
outlog "To check if all is working right:"
outlog "   Run the script 'status.sh' (but reboot first!)"
outlog "   or check https://isc.sans.edu/myreports.sh (after logging in)"
outlog
outlog " for help, check our slack channel: https://isc.sans.edu/slack "



