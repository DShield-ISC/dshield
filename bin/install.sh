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

# version 2025/08/05

readonly myversion=98


# Major Changes (for details, see Github):
#
# - V99 (Freek)
#   - fixed some missing sudos
#   - adapted to support newest openSUSE
#   - added the https port 8443
#
# - V98 (Johannes)
#   - new web hpot (Mark Baggett)
#   - installer no longer requires root / better priv separation 
#
# - V97 (Johannes)
#   - swap in Mark's web honeypot to replace isc-agent
#   - remove dependency to run as root
#   - remove postfix
#
# - V96 (Johannes)
#   - added 20.04 back again
#
# - V95 (Johannes)
#   - removed support for Ubuntu 20.04 and 18.04
#   - added support for Ubuntu 24.04
#
# - V94 (Johannes)
#   - major, major switch to isc-agent
#   - better status.sh reporting
#
# - V93 (Johannes)
#   - cowrie update
#
# - V92 (Johannes)
#   - changing firewall install to accommodate ufw/Ubuntu
#   - merging AWS changes
#   - updating twistd
#
# - V91 (Johannes)
#   - upgraded cowrie
#   - added pid file for web.py for simpler restart /fixing webpy.sh
#
# - V90 (Freek)
#   - repair definition of TERM
#   - improve coding in status.sh
#   - insert sleep 10 in cron.d/dshield before call of /srv/dshield/webpy.sh
#   - do not copy file to /etc/cron.hourly/dshield (done in /etc/cron.d/dshield with ./update.sh --cron)
#
# - V89 (Freek)
#   - removed progdir from dshield.ini (not really needed there)
#   - added support for raspios bullseye (both armhf and arm64) which also use nftables
#
# - V88 (Freek)
#   - use of iptables replaced by nftables (at least for openSUSE)
#     iptables has been indicated as obsolete; left to be implemented by others in other OSes
#   - remove of systemd-logger in Tumbleweed not needed anymore
#   - Tumbleweed added a kernel source to the firewall log; patch in DShield.py
#
# - V87 (Johannes)
#   - quick update to delete all old backups. Only keep latest one
#
# - V86 (Johannes)
#   - added cleanup script
#
# - V85
#   - increased kippo batch size
#
# - V84 (Freek)
#   - fixed bug in IPv6 disabling in openSUSE
#
# - V83 (Johannes)
#   - added ini option to disable telnet for ISPs that don't allow telnet servers
#
# - V82 (Freek)
#   - fix in update.sh to call ./install.sh in proper folder
#   - fix in fwlogparser.py to save lastcount in persistent folder
#     /var/run/ may not survive a reboot; /var/tmp used instead
#   - auto update may be used on openSUSE also
#
# - V81 (Freek)
#   - fixes in status.sh when run in cron
#   - removed folder install for openSUSE in README
#   - added support for openSUSE in uninstall.sh
#   - fixes for typos
#   - added post-install option
#
# - V80 (Freek)
#   - Consistent use of manualupdate, also saved in dshield.ini
#   - value of progdir saved in dshield.ini
#
# - V80 (Johannes)
#   - cleaning up dshield cron job
#
# - V79 (Johannes)
#   - minor fixes to properly report version during status check and update check
#
# - V78 (Johannes)
#   - improvements to status reporting
#   - fixed dependency issue for older pis
#
# - V77 (Johannes)
#   - fixing status.sh
#
# - V76 (Johannes)
#   - fixing Ubuntu 20.04 issues (regression from V75 Suse additions)
#   - improved status checks
#
# - V75 (Freek)
#   - added support for openSUSE
#   - added dshield.sslca to save ca parameters
#   - some cleanup

# - V75 (Johannes)
#   - fixes for Python3 (web.py)
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
#   - improved compatibility with Ubuntu 18.04
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
#   - added email to configuration file for convenience
#
# - V0.47
#   - many small changes, see GitHub
#
# - V0.46 (Gebhard)
#   - removed obsolete stuff (already commented out)
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

TERM=vt100

INTERACTIVE=1
FAST=0
BETA=0

DSHIELDINI=/srv/dshield/etc/dshield.ini
# userid and uid are used by the dshield.ini configuration and script building it
SYSUSERID=$(id -u) 
GROUPID=$(id -g)
SYSUSERNAME=$(id -ng)

# parse command line arguments
ETCDIR=$(dirname $DSHIELDINI)
if [ ! -f "${DSHIELDINI}" ]; then
    if [ -f /etc/dshield.ini ]; then
	sudo mkdir -p "${ETCDIR}"
	sudo mv /etc/dshield.ini "${DSHIELDINI}"
	sudo chown -R "${SYSUSERID}":"${GROUPID}" "${ETCDIR}"
	sudo ln -s "${ETCDIR}/dshield.ini" "/etc/dshield.ini"
    fi
fi

for arg in "$@"; do
  case $arg in
  "--update" | "--upgrade")
    if [ -f ${DSHIELDINI} ]; then
      echo "Non Interactive Update Mode"
      INTERACTIVE=0
    else
      echo "Update mode requires a ${DSHIELDINI} file"
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
WEBHPOTDIR=${TARGETDIR}/web
TXTCMDS=${COWRIEDIR}/share/cowrie/txtcmds
LOGDIR="${TARGETDIR}/log"


SCRIPTDIR=$( cd -- "$(dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)
INSTDATE="$(date +'%Y-%m-%d_%H%M%S')"
LOGFILE="${LOGDIR}/install_${INSTDATE}.log"

# which ports will be handled e.g. by cowrie (separated by blanks)
# used e.g. for setting up block rules for trusted nets
# use the ports after PREROUTING has been executed, i.e. the redirected (not native) ports
# note: doesn't make sense to ask the user because cowrie is configured statically
#
# <SVC>HONEYPORT: target ports for requests, i.e. where the honey pot daemon listens on
# <SVC>REDIRECT: source ports for requests, i.e. which ports should be redirected to the honey pot daemon
# HONEYPORTS: all ports a honey pot is listening on so that the firewall can be configured accordingly
SSHHONEYPORT=2222
TELNETHONEYPORT=2223
WEBHONEYPORT=8000
HTTPSHONEYPORT=8443
SSHREDIRECT="22"
TELNETREDIRECT="23 2323"
WEBREDIRECT="80 8080 7547 5555 9000"
HONEYPORTS="${SSHHONEYPORT} ${TELNETHONEYPORT} ${WEBHONEYPORT} ${HTTPSHONYPORT}"

# create and setup log directory
if [ ! -d ${LOGDIR} ]; then
    sudo mkdir -m 1777 -p ${LOGDIR}
fi
# for legacy systems that used to run as root
sudo chown -R "${SYSUSERID}":"${GROUPID}" "${LOGDIR}"
sudo chmod 1777 "${LOGDIR}"
# and the local etc dir may need cleaning up from legacy files as root
sudo chown -R "${SYSUSERID}":"${GROUPID}" "$progdir"
# which port the real sshd should listen to
SSHDPORT="12222"

# Debug Flag
# 1 = debug logging, debug commands
# 0 = normal logging, no extra commands
DEBUG=1

# delimiter
LINE="#############################################################################"

# dialog stuff
: "${DIALOG_OK=0}"
: "${DIALOG_CANCEL=1}"
: "${DIALOG_HELP=2}"
: "${DIALOG_EXTRA=3}"
: "${DIALOG_ITEM_HELP=4}"
: "${DIALOG_ESC=255}"

export NCURSES_NO_UTF8_ACS=1
export CURL="curl -s"
###########################################################
## FUNCTION SECTION
###########################################################

# echo and log
outlog() {
  echo "${*}"
  do_log "${*}"
}

quotespace() {
  local line="${*}"
  if echo "$line" | grep -Eq ' '; then
    if ! echo "$line" | grep -Fq '"'; then
      line="\"${line}\""
    fi
  fi
  echo "$line"
}

# write log
do_log() {
    

    if [ ! -f "${LOGFILE}" ]; then
       touch "${LOGFILE}"
       chmod 600 "${LOGFILE}"
       outlog "Log ${LOGFILE} started."
       outlog "ATTENTION: the log file contains sensitive information (e.g. passwords, "
       outlog "           API keys, ...). Handle with care and sanitize before sharing."
    fi
    echo "$(date +'%Y-%m-%d_%H%M%S') ### ${*}" >>"${LOGFILE}"
}

# execute and log
# make sure to be run command is passed within '' or ""
#    if redirects etc. are used
run() {
  do_log "Running: ${*}"
  eval "${*}" >>"${LOGFILE}" 2>&1
  RET=${?}
  if [ ${RET} -ne 0 ]; then
    dlog "EXIT CODE NOT ZERO (${RET})!"
  fi
  return ${RET}
}

# Execute and log with sudo
sudorun() {
    do_log "Running: sudo ${*}"
  eval "sudo ${*}" >>"${LOGFILE}" 2>&1
  RET=${?}
  if [ ${RET} -ne 0 ]; then
    dlog "EXIT CODE NOT ZERO (${RET})!"
  fi
  return ${RET}
}

# run if debug is set
# make sure to be run command is passed within '' or ""
#    if redirects etc. are used
drun() {
  if [ ${DEBUG} -eq 1 ]; then
    do_log "DEBUG COMMAND FOLLOWS:"
    do_log "${LINE}"
    run "${*}"
    RET=${?}
    do_log "${LINE}"
    return ${RET}
  fi
}

# run with sudo if debug is set
# make sure, to be run command is passed within '' or ""
#    if redirects etc. are used
dsudorun() {
  if [ ${DEBUG} -eq 1 ]; then
    do_log "DEBUG COMMAND FOLLOWS:"
    do_log "${LINE}"
    sudorun "${*}"
    RET=${?}
    do_log "${LINE}"
    return ${RET}
  fi
}

# log if debug is set
dlog() {
  if [ ${DEBUG} -eq 1 ]; then
    do_log "DEBUG OUTPUT: ${*}"
  fi
}

# copy file(s) and chmod
# $1: file (opt. incl. directory / absolute path)
#     can also be a directory, but then chmod can't be done
# $2: dest dir
# optional: $3: chmod bitmask (only if $1 isn't a directory)
do_copy() {
  dlog "copying ${1} to ${2} and chmod to ${3}"
  if [ -d "${1}" ]; then
    if [ "${3}" != "" ]; then
      # source is a directory, but chmod bitmask given nevertheless, issue a warning
      dlog "WARNING: do_copy: $1 is a directory, but chmod bitmask given, ignored!"
    fi
    run "cp -r ${1} ${2}"
  else
    run "cp ${1} ${2}"
  fi
  # shellcheck disable=SC2181
  if [ ${?} -ne 0 ]; then
    outlog "Error copying ${1} to ${2}. Aborting."
    exit 9
  fi
  if [ "${3}" != "" ] && [ ! -d "${1}" ]; then
    # only if $1 isn't a directory!
    if [ -f "${2}" ]; then
      # target is a file, chmod directly
      run "chmod ${3} ${2}"
    else
      # target is a directory, so use basename
      # shellcheck disable=SC2086
      run "chmod ${3} ${2}/$(basename ${1})"
    fi
    # shellcheck disable=SC2181
    if [ ${?} -ne 0 ]; then
      outlog "Error executing chmod ${3} ${2}/${1}. Aborting."
      exit 9
    fi
  fi

}

# copy files as root using sudo
sudo_copy() {
  dlog "sudo copying ${1} to ${2} and chmod to ${3}"
  if [ -d "${1}" ]; then
    if [ "${3}" != "" ]; then
      # source is a directory, but chmod bitmask given nevertheless, issue a warning
      dlog "WARNING: do_copy: $1 is a directory, but chmod bitmask given, ignored!"
    fi
    sudorun "cp -r ${1} ${2}"
  else
    sudorun "cp ${1} ${2}"
  fi
  # shellcheck disable=SC2181
  if [ ${?} -ne 0 ]; then
    outlog "Error copying ${1} ${2}. Aborting."
    exit 9
  fi
  if [ "${3}" != "" ] && [ ! -d "${1}" ]; then
    # only if $1 isn't a directory!
    if [ -f "${2}" ]; then
      # target is a file, chmod directly
      sudorun "chmod ${3} ${2}"
    else
      # target is a directory, so use basename
      # shellcheck disable=SC2086
      sudorun "chmod ${3} ${2}/$(basename ${1})"
    fi
    # shellcheck disable=SC2181
    if [ ${?} -ne 0 ]; then
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



if [ "${SYSUSERID}" = "0" ]; then
  echo "You must not run this script as root"
  echo "Exiting."
  echo ${LINE}
  exit 9
else
  do_log "Check OK: User-ID is ${SYSUSERID}."
fi

if sudo -n true; then
    do_log "check OK: sudo"
else
    echo "you must have password less access to sudo"
    echo "Or run a command using 'sudo' to enter the"
    echo "password before starting this script."
    echo ${LINE}
    exit 9
fi

dlog "This is ${0} V${myversion}"

dlog "parent process: $(ps -o comm= $PPID)"

if [ ${DEBUG} -eq 1 ]; then
  do_log "DEBUG flag is set."
else
  do_log "DEBUG flag NOT set."
fi

drun env
drun 'df -h'
outlog "Checking Pre-Requisites"

progname=$0
progdir=$(dirname "$0")
progdir=$PWD/$progdir

dlog "progname: ${progname}"
dlog "progdir: ${progdir}"

cd "$progdir" || exit

if [ ! -f /etc/os-release ]; then
  outlog "I can not find the /etc/os-release file. You are likely not running a supported operating system"
  outlog "please email info@dshield.org for help."
  exit 9
fi

drun "cat /etc/os-release"
drun "uname -a"

dlog "sourcing /etc/os-release"
. /etc/os-release

dist=invalid

if [ "$ID" == "debian" ] && [ "$VERSION_ID" == "8" ]; then
  dist='apt'
  distversion=r8
fi

if [ "$ID" == "debian" ] && [ "$VERSION_ID" == "9" ]; then
  dist='apt'
  distversion=r9
fi

if [ "$ID" == "debian" ] && [ "$VERSION_ID" == "10" ]; then
  dist='apt'
  distversion=r10
fi

if [ "$ID" == "debian" ] && [ "$VERSION_ID" == "11" ]; then
  dist='apt'
  distversion=r11
fi

if [ "$ID" == "debian" ] && [ "$VERSION_ID" == "12" ]; then
  dist='apt'
  distversion=r12
fi

if [ "$ID" == "debian" ] && [ "$VERSION_ID" == "13" ]; then
  dist='apt'
  distversion=r13
fi

if [ "$ID" == "raspbian" ] && [ "$VERSION_ID" == "8" ]; then
  dist='apt'
  distversion=r8
fi

if [ "$ID" == "raspbian" ] && [ "$VERSION_ID" == "9" ]; then
  dist='apt'
  distversion=r9
fi

if [ "$ID" == "raspbian" ] && [ "$VERSION_ID" == "10" ]; then
  dist='apt'
  distversion=r10
fi

if [ "$ID" == "raspbian" ] && [ "$VERSION_ID" == "11" ]; then
  dist='apt'
  distversion=r11
fi

if [ "$ID" == "raspbian" ] && [ "$VERSION_ID" == "12" ]; then
  dist='apt'
  distversion=r12
fi

if [ "$ID" == "debian" ]  && [ "$VERSION_ID" == "13" ]; then
    dist='apt'
    distversion=r13
fi


if [ "$ID" == "ubuntu" ] && [ "$VERSION_ID" == "20.04" ]; then
  dist='apt'
  distversion='u20'
fi

if [ "$ID" == "ubuntu" ] && [ "$VERSION_ID" == "22.04" ]; then
  dist='apt'
  distversion='u22'
fi

if [ "$ID" == "ubuntu" ] && [ "$VERSION_ID" == "24.04" ]; then
  dist='apt'
  distversion='u24'
fi

if [ "$ID" == "amzn" ] && [ "$VERSION_ID" == "2" ]; then
  dist='yum'
  distversion=2
fi

if [ "$ID" == "opensuse-tumbleweed" ]; then
  ID="opensuse"
  dist='yum'
  distversion=Tumbleweed
fi

if [ "$ID" == "opensuse-leap" ]; then
  ID="opensuse"
  dist='yum'
  distversion=Leap
fi

dlog "dist: ${dist}, distversion: ${distversion}"

if [ "$dist" == "invalid" ]; then
  outlog "You are not running a supported operating system. Right now, this script only works for Raspbian, Ubuntu 20.04/22.04/24.04, "
  outlog "openSUSE Tumbleweed and Amazon Linux AMI."
  outlog "Please ask info@dshield.org for help to add support for your OS. Include the /etc/os-release file."
  exit 9
fi

if [ "$ID" != "raspbian" ] && [ "$ID" != "opensuse" ] && [ "$ID" != "raspbian" ] && [ "$VERSION_ID" != "24.04" ] && [ "$VERSION_ID" != "22.04" ] && [ "$VERSION_ID" != "20.04" ] && [ "$VERSION_ID" != "13" ] ; then
  outlog "ATTENTION: the latest versions of this script have been tested on:"
  outlog " - Raspbian OS (up to trixie, release October 1st 2025)"
  outlog " - Ubuntu 20.04"  
  outlog " - Ubuntu 22.04"
  outlog " - Ubuntu 24.04"  
  outlog " - openSUSE Tumbleweed."
  outlog "It may or may not work with your distro. Feel free to test and contribute."
  outlog "Press ENTER to continue, CTRL+C to abort."
  read
fi

if [ "$ID" == "opensuse" ]; then
  outlog "using zypper to install packages."
else
  outlog "using apt to install packages."
fi

dlog "creating a temporary directory."

TMPDIR=$(mktemp -udq /tmp/dshieldinstXXXXXXX)
dlog "TMPDIR: ${TMPDIR}"

dlog "setting trap"
# trap "rm -r ${TMPDIR}" 0 1 2 5 15
mkdir "${TMPDIR}"
# shellcheck disable=SC2016
run 'trap "echo Log: ${LOGFILE} && rm -r ${TMPDIR}" 0 1 2 5 15'
if [ "$FAST" == "0" ]; then
  outlog "Basic security checks"

  dlog "making sure default password was changed."

  if [ "$ID" == "opensuse" ]; then
    if "$progdir"/passwordtest-opensuse.pl | grep -q 1; then
      outlog "You have not yet changed the default password for the 'root' user"
      outlog "Change it NOW ..."
      exit 9
    fi
  fi

  if [ "$dist" == "apt" ]; then
    dlog "repair any package issues just in case."
    sudorun 'dpkg --configure -a'
    dlog "we are on pi and should check if password for user pi has been changed"
    if "$progdir"/passwordtest.pl | grep -q 1; then
      outlog "You have not yet changed the default password for the 'pi' user"
      outlog "Change it NOW ..."
      exit 9
    fi

    outlog "Updating your Installation (this can take a LONG time)"
    dsudorun 'dpkg --list'
    sudorun 'apt update'
    sudorun 'apt -y -q dist-upgrade'

    outlog "Installing additional packages (may also take a LONG time)"
    # OS packages: no python modules
    # 2017-05-17: added python-virtualenv authbind for cowrie
    # 2020-07-03: turned this into a loop to make it more reliable
    # 2020-08-03: Added python install outside the loop for Ubuntu 18 vs 20
    #             these two installs may fail depending on ubuntu flavor
    # 2020-09-21: remove python2
    # 2024-08-23: pip will no longer install systemwide packages on apt managed systems. Added most packages here in "experimental" section.
    sudorun 'apt -y -q remove python2'
    sudorun 'apt -y -q remove python'
    sudorun 'apt -y -q remove python-pip'
    sudorun 'apt -y -q remove python-requests'
    sudorun 'apt -y -q remove pyasn1-modules'
    sudorun 'apt -y -q install python3-automat'
    sudorun 'apt -y -q install python3-cffi-backend'
    sudorun 'apt -y -q install python3-bcrypt'
    sudorun 'apt -y -q install python3-cffi'
    sudorun 'apt -y -q install python3-ply'
    sudorun 'apt -y -q install python3-pycparser'
    sudorun 'apt -y -q install python3-constantly'
    sudorun 'apt -y -q install python3-cryptography'
    sudorun 'apt -y -q install python3-constantly'
    sudorun 'apt -y -q install python3-defusedxml'
    sudorun 'apt -y -q install python-babel-localedata python3-babel python3-markupsafe python3-tz'
    
    for b in cron python3 python3-pip python3-requests python3-attr python3-certifi authbind build-essential curl dialog gcc git jq libffi-dev libmariadb-dev-compat libmpc-dev libmpfr-dev libpython3-dev libssl-dev libswitch-perl libwww-perl net-tools python3-dev python3-minimal python3-requests python3-urllib3 python3-virtualenv rng-tools sqlite3 unzip wamerican zip libsnappy-dev virtualenv lsof iptables rsyslog stunnel python3-openssl python3-hamcrest python3-priority; do
      run "sudo apt -y -q install $b"
      if ! sudo dpkg -l $b >/dev/null 2>/dev/null; then
        outlog "ERROR I was unable to install the $b package via apt"
        outlog "This may be a temporary network issue. You may"
        outlog "try and run this installer again. Or run this"
        outlog "command as root to see if it works/returns errors"
        outlog "apt -y install $b"
        exit 9
      fi
    done
  fi

  sudorun "systemctl start cron"
  sudorun "systemctl enable cron"

  if [ "$ID" == "amzn" ]; then
    outlog "Updating your Operating System"
    sudorun 'yum -q update -y'
    outlog "Installing additional packages"
    sudorun 'yum -q install -y dialog perl-libwww-perl perl-Switch rng-tools boost-random jq MySQL-python mariadb mariadb-devel iptables-services'
  fi

  if [ "$ID" == "opensuse" ]; then
    outlog "Updating your openSUSE Operating System will now be done."
    case $distversion in
    esac
    sudorun 'zypper --non-interactive dup --no-recommends'
    outlog "Installing additional packages"
    sudorun 'zypper --non-interactive install --no-recommends cron gcc libffi-devel python3-devel libopenssl-devel rsyslog dialog'
    sudorun 'zypper --non-interactive install --no-recommends perl-libwww-perl perl-Switch perl-LWP-Protocol-https python3-requests'
    sudorun 'zypper --non-interactive install --no-recommends python3-pycryptodome python3-virtualenv'
    sudorun 'zypper --non-interactive install --no-recommends python3-pip rng-tools curl openssh unzip'
    sudorun 'zypper --non-interactive install --no-recommends net-tools-deprecated patch logrotate'
    sudorun 'zypper --non-interactive install --no-recommends system-user-mail mariadb libmariadb-devel python3-PyMySQL jq'
    sudorun 'zypper --non-interactive install --no-recommends python3-python-snappy snappy-devel gcc-c++'
    sudorun 'zypper --non-interactive install --no-recommends stunnel'
    # opensuse does not have packet wamerican so copy it
    sudo mkdir -p /usr/share/dict
    sudo cp "$progdir"/../dict/american-english /usr/share/dict/
  fi
else
  outlog "Skipping OS Update / Package install and security check in FAST mode"
fi

###########################################################
## last chance to escape before hurting the system ...
###########################################################
if [ "$INTERACTIVE" == 1 ]; then
  dlog "Offering user last chance to quit with a nearly untouched system."
  dialog --title '### WARNING ###' --colors --yesno "You are about to turn this system into a honeypot. This software assumes that the device is \ZbDEDICATED\Zn to this task. There is no simple uninstall (e.g. IPv6 will be disabled). If something breaks you may need to reinstall from scratch. This script will try to do some magic in installing and configuring your to-be honeypot. But in the end \Zb\Z1YOU\Zn are responsible to configure it in a safe way and make sure it is kept up to date. An orphaned or non-monitored honeypot will become insecure! Do you want to proceed?" 0 0
  response=$?
  case $response in
  "${DIALOG_CANCEL}")
    clear
    dlog "User clicked CANCEL on honeypot warning"
    outlog "Terminating installation by your command. The system shouldn't have been hurt too much yet ..."
    outlog "See ${LOGFILE} for details."
    exit 5
    ;;
  "${DIALOG_ESC}")
    clear
    dlog "User pressed ESC on honeypot warning"
    outlog "Terminating installation by your command. The system shouldn't have been hurt too much yet ..."
    outlog "See ${LOGFILE} for details."
    exit 5
    ;;
  esac

  ###########################################################
  ## Privacy Statement
  ###########################################################

  dlog "Privacy Notice"
  dialog --title '### PRIVACY NOTICE ###' --colors --yesno "By running this honeypot, you agree to participate in our research project. This honeypot will report firewall logs, connections to various services (e.g. ssh, telnet, web) to DShield. The honeypot will also report errors and the status of its configuration to DShield. Your ability to remove this data is limited after it has been submitted. For details, see privacy.md ." 0 0
  response=$?
  case $response in
  "${DIALOG_CANCEL}")
    clear
    dlog "User clicked CANCEL on privacy policy"
    outlog "Terminating installation after not accepting privacy warning."
    exit 5
    ;;
  "${DIALOG_ESC}")
    clear
    dlog "User pressed ESC on privacy policy"
    outlog "Terminating installation after not accepting privacy warning."
    exit 5
    ;;
  esac

  ###########################################################
  ## let the user decide:
  ## automatic updates OK?
  ###########################################################

  dlog "Offering user choice if automatic updates are OK."

  exec 3>&1
  VALUES=$(dialog --title 'Automatic Updates' --radiolist "We do release updates periodically, and recommend you apply them automatically. Please choose if you want them or if you want to keep up your dshield stuff up-to-date manually." 0 0 2 \
    manual "" off \
    automatic "" on \
    2>&1 1>&3)

  response=$?
  exec 3>&-

  case $response in
  "${DIALOG_CANCEL}")
    dlog "User clicked CANCEL."
    outlog "Terminating installation by your command. The system shouldn't have been hurt too much yet ..."
    outlog "See ${LOGFILE} for details."
    exit 5
    ;;
  "${DIALOG_ESC}")
    dlog "User pressed ESC"
    outlog "Terminating installation by your command. The system shouldn't have been hurt too much yet ..."
    outlog "See ${LOGFILE} for details."
    exit 5
    ;;
  esac

  if [ "${VALUES}" == "manual" ]; then
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

if [ -x /etc/init.d/cowrie ]; then
  outlog "Existing cowrie startup file found, stopping cowrie."
  sudorun '/etc/init.d/cowrie stop'
  outlog "... giving cowrie time to stop ..."
  run 'sleep 10'
  outlog "... OK."
fi
# in case systemd is used
outlog "Stopping cowrie via systemd"
[ "$(sudo systemcl is-active cowrie.service)" = "active" ] && sudo systemctl stop cowrie

if [ "$FAST" == "0" ]; then

  ###########################################################
  ## PIP
  ###########################################################

  outlog "check if pip3 is already installed"

  run 'pip3 > /dev/null'

  # shellcheck disable=SC2181
  if [ ${?} -gt 0 ]; then
    outlog "no pip3 found, installing pip3"
    run "$CURL https://bootstrap.pypa.io/get-pip.py > ${TMPDIR}/get-pip.py"
    if [ ${?} -ne 0 ]; then
      outlog "Error downloading get-pip, aborting."
      exit 9
    fi
    run "python3 ${TMPDIR}/get-pip.py"
    if [ ${?} -ne 0 ]; then
      outlog "Error running get-pip3, aborting."
      exit 9
    fi
  else
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
    if [ "$(pip3 -V | cut -d " " -f 4 | cut -d "/" -f 3)" != "local" ] || [ "$(find /usr -name pip3 | grep -cv local)" -gt 0 ]; then
      # pip3 may be distro pip3
      outlog "Potential distro pip3 found."
    else
      outlog "pip found, which doesn't seem to be installed as a distro package. Looks ok to me."
    fi
  fi

  drun 'pip3 list --format=columns'
  
else
  outlog "Skipping PIP check in FAST mode"
fi

###########################################################
## Random number generator
###########################################################

#
# yes. this will make the random number generator less secure.
# But remember this is for a honeypot, and we want speed on minimal hardware
#

dlog "Changing random number generator settings."

run "echo '# Modified by DShield Honeypot Installer' > ${TMPDIR}/rng-tools"
run "echo 'HRNGDEVICE=/dev/urandom' >> ${TMPDIR}/rng-tools"
if [ -f /etc/default/rng-tools-debian ]; then
    sudorun "mv ${TMPDIR}/rng-tools /etc/default/rng-tools-debian"
    sudorun 'chown root:root /etc/default/rng-tools-debian'
else
    sudorun "mv ${TMPDIR}/rng-tools /etc/default/rng-tools"
    sudorun 'chown root:root /etc/default/rng-tools'
fi

###########################################################
## Disable IPv6
###########################################################

if [ "$ID" != "opensuse" ]; then
  dlog "Disabling IPv6 in /etc/modprobe.d/ipv6.conf"
  sudorun "mv /etc/modprobe.d/ipv6.conf /etc/modprobe.d/ipv6.conf.bak"
  cat > "${TMPDIR}"/ipv6.conf <<EOF
# Don't load ipv6 by default
alias net-pf-10 off
# uncommented
alias ipv6 off
# added
options ipv6 disable_ipv6=1
# this is needed for not loading ipv6 driver
blacklist ipv6
EOF
  sudo_copy "${TMPDIR}/ipv6.conf" /etc/modprobe.d/ipv6.conf
  sudorun "chmod 644 /etc/modprobe.d/ipv6.conf"
  drun "cat /etc/modprobe.d/ipv6.conf.bak"
  drun "cat /etc/modprobe.d/ipv6.conf"
else # in openSUSE
  iface=$(ip -4 route show | grep '^default ' | head -1 | cut -f5 -d' ')
  dsudorun "nmcli device modify $iface  ipv6.method 'disabled'"
fi

###########################################################
## Handling existing config
###########################################################

if ! grep -qE '^webhpot' /etc/passwd; then
    dlog "creating webhpot user"
    if [ "$ID" != "opensuse" ]; then
	sudorun 'adduser --gecos "Honeypot,A113,555-1212,555-1212" --disabled-password --quiet --home /srv/web --no-create-home webhpot'	
    else
	sudorun 'useradd -c "Honeypot,A113,555-1212,555-1212" -M -U -d /srv/web webhpot'
        sudorun 'passwd -d webhpot' #disable password
    fi
    outlog "Added user 'webhpot'"
else
    outlog "User 'webhpot' already exists"
fi

if [ ! -d /srv/dshield/etc ]; then
    sudorun "mkdir -m 0770 -p /srv/dshield/etc"
    
    sudorun "chown -R ${SYSUSERID}:webhpot /srv/dshield"
fi




if [ -f /etc/dshield.ini ]; then
    if [ ! -f ${DSHIELDINI} ]; then
	sudorun "mv /etc/dshield.ini ${DSHIELDINI}"
    else
	sudorun 'rm /etc/dshield.ini'
    fi
    sudorun "ln -s ${DSHIELDINI} /etc/dshield.ini"
fi


if [ -f ${DSHIELDINI} ]; then
  dlog "dshield.ini found, content follows"
  drun "cat ${DSHIELDINI}"
  dlog "securing dshield.ini"
  run "chmod 600 ${DSHIELDINI}"
  sudorun "chown ${SYSUSERID}:${GROUPID} ${DSHIELDINI}"
  outlog "reading old configuration"
  if grep -q 'uid=<authkey>' /etc/dshield.ini; then
    dlog "erasing <.*> pattern from dshield.ini"
    run "sed -i.bak 's/<.*>//' /etc/dshield.ini"
    dlog "modified content of dshield.ini follows"
    drun 'cat /etc/dshield.ini'
  fi

  manualupdates=0
  userid=0
  # believe it or not, bash has a built in .ini parser. Just need to remove spaces around "="
  # shellcheck disable=SC1090
  # shellcheck disable=SC2036
  # shellcheck disable=SC2034
  source <(grep = ${DSHIELDINI} | sed 's/ *= */=/g')
  dlog "dshield.ini found, content follows."
  drun "cat ${DSHIELDINI}"
  dlog "securing dshield.ini"
  run "chmod 600 ${DSHIELDINI}"
fi

#
# defaulting to enable telnet
#

if [ "$telnet" == "" ]; then
    telnet="true"
fi
if [ "$telnet" == "no" ]; then
    telnet="false"
fi
if [ "$telnet" != "false" ]; then
    telnet="true"
fi


# hmmm - this SHOULD NOT happen
if ! [ -d "${TMPDIR}" ]; then
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
if [ "$enable_local_logs" == "" ]; then
    enable_local_logs='false'
fi
if [ "$local_logs_file" == "" ]; then
    local_logs_file='/srv/log/webhoneypot_{date}.json'
fi

if [ "$submit_log_rate" == "" ]; then
    submit_log_rate=900
fi

if [ "$queue_trigger" == "" ]; then
    queue_trigger=100
fi

if [ "$web_log_limit" == "" ]; then
    web_log_limit=1000
fi

if [ "$web_log_purge_factor" == "" ]; then
    web_log_purge_factor=2
fi

###########################################################
## DShield Account
###########################################################


return_value=$DIALOG_OK
return=1
if [ "${INTERACTIVE}" == 1 ]; then
  if [ "${return_value}" -eq "${DIALOG_OK}" ]; then
    if [ $return = "1" ]; then
      dlog "use existing dshield account"
      apikeyok=0
      while [ "$apikeyok" = 0 ]; do
        dlog "Asking user for dshield account information"
        exec 3>&1
        VALUES=$(dialog --ok-label "Verify" --title "DShield Account Information" --form "Authentication Information. Copy/Past from dshield.org/myaccount.html. Use CTRL-V / SHIFT + INS to paste." 12 60 0 \
          "E-Mail Address:" 1 2 "$email" 1 17 35 100 \
          "       API Key:" 2 2 "$apikey" 2 17 35 100 \
          2>&1 1>&3)

        response=$?
        exec 3>&-

        case $response in
        "${DIALOG_OK}")
          email=$(echo ${VALUES} | cut -f1 -d' ')
          apikey=$(echo ${VALUES} | cut -f2 -d' ')
          dlog "Got email ${email} and apikey ${apikey}"
          dlog "Calculating nonce."
          nonce=$(openssl rand -hex 10)
          dlog "Calculating hash."
          hash=$(echo -n "$email":"$apikey" | openssl dgst -hmac "$nonce" -sha512 -hex | cut -f2 -d'=' | tr -d ' ')
          dlog "Calculated nonce (${nonce}) and hash (${hash})."
          user=$(echo "$email" | sed 's/+/%2b/' | sed 's/@/%40/')
          dlog "Checking API key ..."
          run "$CURL https://isc.sans.edu/api/checkapikey/$user/$nonce/$hash/$myversion/$piid > ${TMPDIR}/checkapi"
          dlog "Curl return code is ${?}"
          if ! [ -d "${TMPDIR}" ]; then
            # this SHOULD NOT happen
            outlog "Can not find TMPDIR ${TMPDIR}"
            exit 9
          fi
          drun "cat ${TMPDIR}/checkapi"
          dlog "Examining result of API key check ..."
          if grep -q '<result>ok</result>' "${TMPDIR}"/checkapi; then
            apikeyok=1
            uid=$(grep '<id>.*<\/id>' "${TMPDIR}"/checkapi | sed -E 's/.*<id>([0-9]+)<\/id>.*/\1/')
            dlog "API key OK, uid is ${uid}"
          else
            dlog "API key not OK, informing user"
            dialog --title 'API Key Failed' --msgbox 'Your API Key Verification Failed.' 7 40
          fi
          ;;
        "${DIALOG_CANCEL}")
          dlog "User canceled API key dialogue."
          exit 5
          ;;
        "${DIALOG_ESC}")
          dlog "User pressed ESC in API key dialogue."
          exit 5
          ;;
        esac
        clear
      done # while API not OK

    fi # use existing account or create new one
  fi # dialogue not aborted


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
# 9. allow pings from local network
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
# - allow pings from local network (9.)
# - default policy: DROP (8.)

##---------------------------------------------------------
## default interface
##---------------------------------------------------------

dlog "firewall config: figuring out default interface"

# if we don't have one configured, try to figure it out
dlog "interface: ${interface}"
drun 'ip link show'
if [ "$interface" == "" ]; then
  dlog "Trying to figure out interface"
  # we don't expect a honeypot connected by WLAN ... but the user can change this of course
  drun "ip -4 route show | grep '^default ' | head -1 | cut -f5 -d' '"
  interface=$(ip -4 route show | grep '^default ' | head -1 | cut -f5 -d' ')
fi

# list of valid interfaces
drun "ip link show | grep '^[0-9]' | cut -f2 -d':' | cut -f1 -d'@' | tr -d '\n' | sed 's/^ //'"
validifs=$(ip link show | grep '^[0-9]' | cut -f2 -d':' | cut -f1 -d'@' | tr -d '\n' | sed 's/^ //')

# get honeypot external IPv4 address
honeypotip=$($CURL https://www4.dshield.org/api/myip?json | jq .ip | tr -d '"')

dlog "validifs: ${validifs}"

localnetok=0
if [ "$INTERACTIVE" == 1 ]; then
  while [ $localnetok -eq 0 ]; do
    dlog "asking user for default interface"
    exec 3>&1
    interface=$(dialog --title 'Default Interface' --form 'Default Interface' 10 40 0 \
      "Honeypot Interface:" 1 2 "$interface" 1 25 15 15 2>&1 1>&3)
    response=${?}
    exec 3>&-
    case ${response} in
    "${DIALOG_OK}")
      dlog "User input for interface: ${interface}"
      dlog "check if input is valid"
      for b in $validifs; do
        if [ "$b" = "$interface" ]; then
          localnetok=1
        fi
      done
      if [ $localnetok -eq 0 ]; then
        dlog "User provided interface ${interface} isn't valid"
        dialog --title 'Default Interface Error' --msgbox "You did not specify a valid interface. Valid interfaces are $validifs" 10 40
      fi
      ;;
    "${DIALOG_CANCEL}")
      dlog "User canceled default interface dialogue."
      exit 5
      ;;
    "${DIALOG_ESC}")
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
ipaddr=$(ip addr show "$interface" | grep 'inet ' | awk '{print $2}' | cut -f1 -d'/')
dlog "ipaddr: ${ipaddr}"

drun "ip route show"
drun "ip route show | grep $interface | grep 'scope link' | grep '/' | cut -f1 -d' '"
localnet=$(ip route show | grep "$interface" | grep 'scope link' | grep '/' | cut -f1 -d' ')
# added most common private subnets. This will help if the Pi is in its
# own subnet (e.g. 192.168.1.0/24) which is part of a larger network.
# either way, hits from private IPs are hardly ever log worthy.
if echo "$localnet" | grep -q '^10\.'; then localnet='10.0.0.0/8'; fi
if echo "$localnet" | grep -q '^192\.168\.'; then localnet='192.168.0.0/16'; fi
if echo "$localnet" | grep -q '^172\.1[6-9]\.'; then localnet='172.16.0.0/12'; fi
if echo "$localnet" | grep -q '^172\.2[0-9]\.'; then localnet='172.16.0.0/12'; fi
if echo "$localnet" | grep -q '^172\.3[0-1]\.'; then localnet='172.16.0.0/12'; fi
dlog "localnet: ${localnet}"

# additionally we will use any connection to current sshd
# (ignoring config and using real connections)
# as trusted / local IP (just to make sure we include routed networks)
dsudorun "grep '^Port' /etc/ssh/sshd_config | awk '{print \$2}'"
CURSSHDPORT=$(sudo grep '^Port' /etc/ssh/sshd_config | awk '{print $2}')
# current ssh port already known
adminports=$CURSSHDPORT

#
# figure out if netstat is installed, or if we have to use ss
#

netstatexists=0
ssexists=0

if netstat 2>/dev/null >/dev/null  ; then
    netstatexists=1
else
    netstatexists=0
fi

if [ ${netstatexists} -eq 0 ]; then
    if ss 2>/dev/null >/dev/null; then
	ssexists=1
    else
	ssexists=0
    fi
else
    ssexists=0
fi

if [ ${ssexists} -eq 0 ] && [ ${netstatexists} -eq 0 ]; then
    dlog "Neither netstat nor ss exists. Need at least one of them."
    exit 5
fi


drun "netstat -an | grep ':${CURSSHDPORT}' | grep ESTABLISHED | awk '{print \$5}' | cut -d ':' -f 1 | sort -u | tr '\n' ' ' | sed 's/ $//'"
CONIPS=$(netstat -an | grep ":${CURSSHDPORT}" | grep ESTABLISHED | awk '{print $5}' | cut -d ':' -f 1 | sort -u | tr '\n' ' ' | sed 's/ $//')

localnetok=0
ADMINPORTS=$adminports
if [ "${ADMINPORTS}" == "" ]; then
  # default: sshd (after reboot)
  ADMINPORTS="${SSHDPORT}"
else
  SSHDPORT=${ADMINPORTS}
fi
# we present the localnet and the connected IPs to the user
# so we are sure connection to the device will work after
# reboot at least for the current remote device
CONIPS="$localips ${CONIPS}"
dlog "CONIPS with config values before removing duplicates: ${CONIPS}"
CONIPS=$(echo "${CONIPS}" | tr ' ' '\n' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | sort -u | tr '\n' ' ' | sed 's/ $//')
dlog "CONIPS with removed duplicates: ${CONIPS}"

if [ "$INTERACTIVE" == 1 ]; then
  dlog "Getting local network, further IPs and admin ports from user ..."
  while [ $localnetok -eq 0 ]; do
    dialog --title 'Local Network and Access' --form "Configure admin access: which ports should be opened (separated by blank, at least sshd (${SSHDPORT})) for the local network, and further trusted IPs / networks. All other access from these IPs and nets / to the ports will be blocked. Handle with care, use only trusted IPs / networks." 15 60 0 \
      "Local Network:" 1 2 "${localnet}" 1 18 37 20 \
      "Additional IPs:" 2 2 "${CONIPS}" 2 18 37 60 \
      "Admin Ports:" 3 2 "${ADMINPORTS}" 3 18 37 20 \
      2>"${TMPDIR}"/dialog.txt
    response=${?}

    case ${response} in
    "${DIALOG_OK}")
      dlog "User input for local network & IPs:"
      localnet=$(head -1 "${TMPDIR}"/dialog.txt)
      CONIPS=$(head -2 "${TMPDIR}"/dialog.txt | tail -1)
      ADMINPORTS=$(tail -1 "${TMPDIR}"/dialog.txt)
      dlog "user input localnet: ${localnet}"
      dlog "user input further IPs: ${CONIPS}"
      dlog "user input further admin ports: ${ADMINPORTS}"

      # OK (exit loop) if local network OK _AND_ admin ports not empty
      # shellcheck disable=SC2046
      if [ $(echo "$localnet" | grep -cE '^([0-9]{1,3}\.){3}[0-9]{1,3}\/[0-9]{1,2}$') -eq 1 ] && [ -n "${ADMINPORTS// /}" ]; then
        localnetok=1
      fi

      if [ $localnetok -eq 0 ]; then
        dlog "user provided localnet ${localnet} is not ok or adminports empty (${ADMINPORTS})"
        dialog --title 'Local Network Error' --msgbox "The format of the local network is wrong (it has to be in Network/CIDR format, for example 192.168.0.0/16) or the admin portlist is empty (should contain at least the SSHD port (${ADMINPORTS}))." 10 40
      fi
      ;;
    "${DIALOG_CANCEL}")
      dlog "User canceled local network access dialogue."
      clear
      exit 5
      ;;
    "${DIALOG_ESC}")
      dlog "User pressed ESC in local network access dialogue."
      clear
      exit 5
      ;;
    esac
    clear
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

if [ "${database}" == "" ]; then
    database='sqlite+pysqlite:////srv/db/isc-agent.sqlite'
fi
if [ "${archivedatabase}" == "" ]; then
    archivedatabase='none'
fi    

if [ "${nofwlogging}" == "" ]; then
  # default: local net & connected IPs (as the user confirmed)
  nofwlogging="${localnet} ${CONIPS}"
  # remove duplicates
  nofwlogging=$(echo "${nofwlogging}" | tr ' ' '\n' | sort -u | tr '\n' ' ' | sed 's/ $//')
fi

dlog "nofwlogging: ${nofwlogging}"
if [ "$INTERACTIVE" == 1 ]; then
  dlog "getting IPs from user ..."

  exec 3>&1
  NOFWLOGGING=$(dialog --title 'IPs to ignore for FW Log' --form "IPs and nets the firewall should do no logging for (in notation iptables likes, separated by spaces).
Note: Traffic from these devices will also not be redirected to the honeypot ports.
" \
    12 70 0 "Ignore FW Log:" 1 1 "${nofwlogging}" 1 17 47 100 2>&1 1>&3)
  response=${?}
  exec 3>&-

  case ${response} in
  "${DIALOG_OK}") ;;

  "${DIALOG_CANCEL}")
    dlog "User canceled IP to ignore in FW log dialogue."
    exit 5
    ;;
  "${DIALOG_ESC}")
    dlog "User pressed ESC in IP to ignore in FW log dialogue."
    exit 5
    ;;
  esac

  # for saving in dshield.ini
  nofwlogging="'${NOFWLOGGING}'"

  dlog "user provided nofwlogging: ${nofwlogging}"

  if [ "${NOFWLOGGING}" == "" ]; then
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

if [ "${nohoneyips}" == "" ]; then
  # default: admin IPs and nets
  nohoneyips="${NOFWLOGGING}"
fi
dlog "nohoneyips: ${nohoneyips}"

if [ "${nohoneyports}" == "" ]; then
  # default: cowrie ports
  nohoneyports="${HONEYPORTS}"
fi
dlog "nohoneyports: ${nohoneyports}"

dlog "getting IPs and ports from user"

if [ "$INTERACTIVE" == 1 ]; then
  dialog --title 'IPs / Ports to disable Honeypot for' --form "IPs and nets to disable honeypot for to prevent reporting internal legitimate access attempts (IPs / nets in notation iptables likes, separated by spaces / ports (not real but after PREROUTING, so as configured in honeypot) separated by spaces)." \
    12 70 0 \
    "IPs / Networks:" 1 1 "${nohoneyips}" 1 17 47 100 \
    "Honeypot Ports:" 2 1 "${nohoneyports}" 2 17 47 100 2>"${TMPDIR}"/dialog.txt
  response=${?}
  case ${response} in
  "${DIALOG_OK}") ;;

  "${DIALOG_CANCEL}")
    dlog "User canceled honeypot disable dialogue."
    exit 5
    ;;
  "${DIALOG_ESC}")
    dlog "User pressed ESC in honeypot disable dialogue."
    exit 5
    ;;
  esac

  dlog "user provided NOHONEY:"

  NOHONEYIPS=$(head -1 "${TMPDIR}"/dialog.txt)
  NOHONEYPORTS=$(tail -1 "${TMPDIR}"/dialog.txt)

  dlog "NOHONEYIPS: ${NOHONEYIPS}"
  dlog "NOHONEYPORTS: ${NOHONEYPORTS}"

  if [ "${NOHONEYIPS}" == "" ] || [ "${NOHONEYPORTS}" == "" ]; then
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

fi
# interactive mode

##---------------------------------------------------------
## create actual firewall rule set
##---------------------------------------------------------
#
# Firewall Layout: see beginning of firewall section
#
if [ "$INTERACTIVE" == 1 ]; then
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
  sudorun 'mkdir /etc/network'
fi
# cleanup iptables/nftables backups older than 60 days
sudorun "find /etc/network -name 'iptables.????-??-??_*' -ctime +60 -delete"
sudorun "find /etc/network -name 'iptables.nft.????-??-??_*' -ctime +60 -delete"

# backup old iptables rules
if [ -f /etc/network/iptables ]; then
  sudorun "mv /etc/network/iptables /etc/network/iptables.${INSTDATE}"
fi

# backup old nftables rules
if [ -f /etc/network/ruleset.nft ]; then
  sudorun "mv /etc/network/ruleset.nft /etc/network/ruleset.nft.${INSTDATE}"
fi



# Further conditions can be inserted below whether iptables of nftables should be used

use_iptables=True
case $ID in
  "opensuse" ) use_iptables=False;;
  "raspbian" ) [ "$VERSION_ID" = "11" ] && use_iptables=False;;
  "debian"   ) [ "$VERSION_ID" = "11" ] && use_iptables=False;;
  *          ) ;;
esac

if [ "$use_iptables" = "True" ] ; then
    dlog "using iptables not nftables"
    # do not overwrite existing local file
    if [ ! -f /etc/network/iptables.local ]; then
        cat >"${TMPDIR}"/iptables.local <<EOF
#
# use this for local iptables rules not to be overwritten
# by the honeypot configuration. Use "-I" to insert rules
# for example, to allow all traffic from a wireguard VPN
# interface, use:
#
# *filter
# -I INPUT 1 -i wg0 -j ACCEPT
# COMMIT
#
# first line must be "*filter"
# last line must be "COMMIT"
# to test, run
# iptables -n iptables.local
#
EOF
        sudo cp "${TMPDIR}"/iptables.local /etc/network/iptables.local
    fi
  cat >"${TMPDIR}"/iptables <<EOF

#
# 
#

*filter
:LOCALINPUT - [0:0]
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]

# allow all on loopback
-A INPUT -i lo -j ACCEPT
# allow all for established connections
-A INPUT -i $interface -m state --state ESTABLISHED,RELATED -j ACCEPT
# add rule to allow for custom rules
-A INPUT -j LOCALINPUT
-A LOCALINPUT -j RETURN
EOF

  # allow pings from localnet
  echo "# allow ping from local network" >>"${TMPDIR}"/iptables
  echo "-A INPUT -i $interface -s ${localnet} -p icmp -m icmp --icmp-type 8 -j ACCEPT" >>"${TMPDIR}"/iptables

  # insert IPs and ports for which honeypot has to be disabled
  # as soon as possible
  if [ "${NOHONEYIPS}" != "" ] && [ "${NOHONEYIPS}" != " " ]; then
    echo "# START: IPs / Ports honeypot should be disabled for" >>"${TMPDIR}"/iptables
    for NOHONEYIP in ${NOHONEYIPS}; do
      for NOHONEYPORT in ${NOHONEYPORTS}; do
        echo "-A INPUT -i $interface -s ${NOHONEYIP} -p tcp --dport ${NOHONEYPORT} -j REJECT" >>"${TMPDIR}"/iptables
      done
    done
    echo "# END: IPs / Ports honeypot should be disabled for" >>"${TMPDIR}"/iptables
  fi

  # allow access to admin ports for local nets / IPs
  echo "# START: allow access to admin ports for local IPs" >>"${TMPDIR}"/iptables
  for PORT in ${ADMINPORTS}; do
    # first: local network
    echo "-A INPUT -i $interface -s ${localnet} -p tcp --dport ${PORT} -j ACCEPT" >>"${TMPDIR}"/iptables
    # second: other IPs
    for IP in ${CONIPS}; do
      echo "-A INPUT -i $interface -s ${IP} -p tcp --dport ${PORT} -j ACCEPT" >>"${TMPDIR}"/iptables
    done
  done
  echo "# END: allow access to admin ports for local IPs" >>"${TMPDIR}"/iptables

  # allow access to honeypot ports
  if [ "${HONEYPORTS}" != "" ]; then
    echo "# START: Ports honeypot should be enabled for" >>"${TMPDIR}"/iptables
    for HONEYPORT in ${HONEYPORTS}; do
      echo "-A INPUT -i $interface -p tcp --dport ${HONEYPORT} -j ACCEPT" >>"${TMPDIR}"/iptables
    done
    echo "# END: Ports honeypot should be enabled for" >>"${TMPDIR}"/iptables
  fi

  # create stuff for PREROUTING chain:
  # - no logging for trusted nets -> skip rest of chain (4.)
  #   (this means for trusted nets the redirects for
  #    honeypot ports don't happen, but this shouldn't matter)
  # - logging of all access attempts (1.)
  # - redirect for honeypot ports (6.)

  cat >>"${TMPDIR}"/iptables <<EOF
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

  # insert to-be-ignored IPs just before the logging stuff so that traffic will be handled by default policy for chain
  if [ "${NOFWLOGGING}" != "" ] && [ "${NOFWLOGGING}" != " " ]; then
    echo "# START: IPs firewall logging should be disabled for" >>"${TMPDIR}"/iptables
    for NOFWLOG in ${NOFWLOGGING}; do
      echo "-A PREROUTING -i $interface -s ${NOFWLOG} -j RETURN" >>"${TMPDIR}"/iptables
    done
    echo "# END: IPs firewall logging should be disabled for" >>"${TMPDIR}"/iptables
  fi

  cat >>"${TMPDIR}"/iptables <<EOF
# log all traffic with original ports, but exclude traffic from unused/private IPs.
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

  echo "# - ssh ports" >>"${TMPDIR}"/iptables
  for PORT in ${SSHREDIRECT}; do
    echo "-A PREROUTING -p tcp -m tcp --dport ${PORT} -j REDIRECT --to-ports ${SSHHONEYPORT}" >>"${TMPDIR}"/iptables
  done

  echo "# - telnet ports" >> "${TMPDIR}"/iptables
  if [ "$telnet" != "no" ]; then   
      for PORT in ${TELNETREDIRECT}; do
	  echo "-A PREROUTING -p tcp -m tcp --dport ${PORT} -j REDIRECT --to-ports ${TELNETHONEYPORT}" >>"${TMPDIR}"/iptables
      done
  fi

  echo "# - web ports" >>"${TMPDIR}"/iptables
  for PORT in ${WEBREDIRECT}; do
    echo "-A PREROUTING -p tcp -m tcp --dport ${PORT} -j REDIRECT --to-ports ${WEBHONEYPORT}" >>"${TMPDIR}"/iptables
  done

  echo "COMMIT" >>"${TMPDIR}"/iptables
  sudorun "cp ${TMPDIR}/iptables /etc/network/iptables"
  sudorun 'chown root:root /etc/network/iptables'
  sudorun 'chmod 700 /etc/network/iptables'

  dlog "/etc/network/iptables follows"
  drun 'sudo cat /etc/network/iptables'

  if [ -d /etc/ufw ]; then
      dlog "dealing with ufw"
      sudorun "systemctl disable ufw"
      sudorun "ufw disable"
      # purge may be a bit harsh, but better safe ..
      sudorun "apt -y purge ufw"
      sudo_copy "$progdir"/../etc/dshieldfw.service /etc/systemd/system/dshieldfw.service 640
      sudorun "systemctl daemon-reload"
      sudorun "systemctl enable dshieldfw.service"
  fi
  
else # use_iptables = False -> use nftables
  dlog "using nftables, not iptables"
  cat > ${TMPDIR}/ruleset.nft <<EOF
# NFT ruleset generated on $(date)
add table ip filter
add chain ip filter INPUT { type filter hook input priority 0; policy drop; }
add chain ip filter FORWARD { type filter hook forward priority 0; policy drop; }
add chain ip filter OUTPUT { type filter hook output priority 0; policy accept; }
add rule ip filter INPUT iifname "lo" counter accept
add rule ip filter INPUT iifname "${interface}" ct state related,established  counter accept
EOF

  # allow pings from localnet
  echo "# allow ping from local network" >>${TMPDIR}/ruleset.nft
  echo "add rule ip filter INPUT iifname \"$interface\" ip saddr ${localnet} icmp type echo-request counter accept" >>"${TMPDIR}"/ruleset.nft

  # insert IPs and ports for which honeypot has to be disabled
  # as soon as possible
  if [ "${NOHONEYIPS}" != "" ] && [ "${NOHONEYIPS}" != " " ]; then
    echo "# START: IPs / Ports honeypot should be disabled for" >>"${TMPDIR}"/ruleset.nft
    for NOHONEYIP in ${NOHONEYIPS}; do
      for NOHONEYPORT in ${NOHONEYPORTS}; do
        echo "add rule ip filter INPUT iifname \"${interface}\" ip saddr ${NOHONEYIP} tcp dport ${NOHONEYPORT} counter reject" >>"${TMPDIR}"/ruleset.nft
      done
    done
    echo "# END: IPs / Ports honeypot should be disabled for" >>"${TMPDIR}"/ruleset.nft
  fi

  # allow access to admin ports for local nets / IPs
  echo "# START: allow access to admin ports for local IPs" >>"${TMPDIR}"/ruleset.nft
  for PORT in ${ADMINPORTS}; do
    # first: local network
    echo "add rule ip filter INPUT iifname \"${interface}\" ip saddr ${localnet} tcp dport ${PORT} counter accept" >>"${TMPDIR}"/ruleset.nft
    # second: other IPs
    for IP in ${CONIPS}; do
      echo "add rule ip filter INPUT iifname \"${interface}\" ip saddr ${IP} tcp dport ${PORT} counter accept" >>"${TMPDIR}"/ruleset.nft
    done
  done
  echo "# END: allow access to admin ports for local IPs" >>"${TMPDIR}"/ruleset.nft

  # allow access to honeypot ports
  if [ "${HONEYPORTS}" != "" ]; then
    echo "# START: Ports honeypot should be enabled for" >>"${TMPDIR}"/ruleset.nft
    for HONEYPORT in ${HONEYPORTS}; do
      echo "add rule ip filter INPUT iifname \"$interface\" tcp dport ${HONEYPORT} counter accept" >>"${TMPDIR}"/ruleset.nft
    done
    echo "# END: Ports honeypot should be enabled for" >>"${TMPDIR}"/ruleset.nft
  fi

  cat >> "${TMPDIR}"/ruleset.nft <<EOF
add table ip nat
add chain ip nat PREROUTING { type nat hook prerouting priority -100; policy accept; }
add chain ip nat INPUT { type nat hook input priority 100; policy accept; }
add chain ip nat OUTPUT { type nat hook output priority -100; policy accept; }
add chain ip nat POSTROUTING { type nat hook postrouting priority 100; policy accept; }
add rule ip nat PREROUTING iifname "${interface}" pkttype multicast counter return
add rule ip nat PREROUTING iifname "${interface}" ip daddr 255.255.255.255 counter return
EOF

  # insert to-be-ignored IPs just before the logging stuff so that traffic will be handled by default policy for chain

  if [ "${NOFWLOGGING}" != "" ] && [ "${NOFWLOGGING}" != " " ]; then
    echo "# START: IPs firewall logging should be disabled for" >>"${TMPDIR}"/ruleset.nft
    for NOFWLOG in ${NOFWLOGGING}; do
        echo "add rule ip nat PREROUTING iifname \"${interface}\" ip saddr ${NOFWLOG} counter return" >>"${TMPDIR}"/ruleset.nft
    done
    echo "# END: IPs firewall logging should be disabled for" >>"${TMPDIR}"/ruleset.nft
  fi

  cat >> "${TMPDIR}"/ruleset.nft <<EOF
add chain ip nat DSHIELDLOG
add rule ip nat DSHIELDLOG ip saddr 10.0.0.0/8 counter return
add rule ip nat DSHIELDLOG ip saddr 100.64.0.0/10 counter return
add rule ip nat DSHIELDLOG ip saddr 127.0.0.0/8 counter return
add rule ip nat DSHIELDLOG ip saddr 169.254.0.0/16 counter return
add rule ip nat DSHIELDLOG ip saddr 172.16.0.0/12 counter return
add rule ip nat DSHIELDLOG ip saddr 192.0.0.0/24 counter return
add rule ip nat DSHIELDLOG ip saddr 192.0.2.0/24 counter return
add rule ip nat DSHIELDLOG ip saddr 192.168.0.0/16 counter return
add rule ip nat DSHIELDLOG ip saddr 224.0.0.0/4 counter return
add rule ip nat DSHIELDLOG ip saddr 240.0.0.0/4 counter return
add rule ip nat DSHIELDLOG ip saddr 255.255.255.255 counter return
add rule ip nat DSHIELDLOG counter log prefix " DSHIELDINPUT "
add rule ip nat DSHIELDLOG counter return
add rule ip nat PREROUTING iifname "$interface" ct state invalid,new  counter jump DSHIELDLOG
EOF

  echo "# - ssh ports" >>"${TMPDIR}"/ruleset.nft
  for PORT in ${SSHREDIRECT}; do
    echo "add rule ip nat PREROUTING tcp dport ${PORT} counter redirect to :${SSHHONEYPORT}" >>"${TMPDIR}"/ruleset.nft
  done

  echo "# - telnet ports" >>"${TMPDIR}"/ruleset.nft
  if [ "$telnet" != "no" ]; then   
      for PORT in ${TELNETREDIRECT}; do
	        echo "add rule ip nat PREROUTING tcp dport ${PORT} counter redirect to :${TELNETHONEYPORT}" >>"${TMPDIR}"/ruleset.nft
      done
  fi

  echo "# - web ports" >>"${TMPDIR}"/ruleset.nft
  for PORT in ${WEBREDIRECT}; do
    echo "add rule ip nat PREROUTING tcp dport ${PORT} counter redirect to :${WEBHONEYPORT}" >>"${TMPDIR}"/ruleset.nft
  done

  run "chmod 700 ${TMPDIR}/ruleset.nft"

  dlog "${TMPDIR}/ruleset.nft follows"
  drun "cat ${TMPDIR}/ruleset.nft"
  sudo_copy "${TMPDIR}"/ruleset.nft /etc/network/ruleset.nft 600
fi

if [ "$use_iptables" = "True" ]; then
  dlog "Copying /etc/network/if-pre-up.d"

  sudo_copy "${progdir}"/../etc/network/if-pre-up.d/dshield /etc/network/if-pre-up.d 775
  # for ubuntu, we need to use netpland
  if [ -d /etc/networkd-dispatcher/routable.d ]; then
    sudo_copy "$progdir"/../etc/network/if-pre-up.d/dshield /etc/networkd-dispatcher/routable.d/10-dshield-iptables 775
  fi
  # for Ubuntu, we turn off UFW so it doesn't mess with our firewall rules
  if systemctl | grep ufw; then
    sudorun 'systemctl disable ufw'
  fi
  # for Amazon's CentOS version, we use the iptables service
  if [ "$ID" == "amzn" ]; then
    sudorun 'rm -f /etc/sysconfig/iptables'
    sudorun 'ln -s /etc/network/iptables /etc/sysconfig/iptables'
    sudorun 'systemctl enable iptables.service'
  fi
else #  use nftables
  if [ -e /etc/network/iptables ] ; then
    # when (automatic) upgrading this system, a previous version may use iptables, which should be disabled and removed
    [ "$(systemctl is-enabled dshieldiptables 2>/dev/null)" == "enabled" ] && sudo systemctl disable dshieldiptables.services
    sudo rm /etc/network/iptables*
    sudo rm /usr/lib/systemd/system/dshieldiptables*
  fi
  dlog "Copying /etc/network/ruleset-init.nft, /etc/network/ruleset-stop.nft, /usr/lib/systemd/system/dshieldnft*.service"
  sudo_copy "$progdir"/../etc/network/ruleset-init.nft /etc/network/ruleset-init.nft 600
  sudo_copy "$progdir"/../etc/network/ruleset-stop.nft /etc/network/ruleset-stop.nft 600
  sudo_copy "$progdir"/../lib/systemd/system/dshieldnft_init.service /usr/lib/systemd/system/dshieldnft_init.service 644
  sudo_copy "$progdir"/../lib/systemd/system/dshieldnft.service /usr/lib/systemd/system/dshieldnft.service 644
  sudorun 'systemctl enable dshieldnft.service'
  sudorun "systemctl daemon-reload"
fi

###########################################################
## Change real SSHD port
###########################################################

if [ "$INTERACTIVE" == 1 ]; then
  dlog "changing port for sshd"

  if [ -f /etc/ssh/sshd_config ] ; then
    run "sed \"s/^[#\s]*Port 22\s*$/Port ${SSHDPORT}/\" < /etc/ssh/sshd_config > ${TMPDIR}/sshd_config"
    sudorun "mv ${TMPDIR}/sshd_config /etc/ssh/sshd_config"
    dlog "checking if modification was successful"
    if [ "$(grep -c "^Port ${SSHDPORT}$" /etc/ssh/sshd_config)" -ne 1 ]; then
      dialog --title 'sshd port' --ok-label 'Understood.' --cr-wrap --msgbox "Congrats, you had already changed your sshd port to something other than 22.
Please clean up and either
  - change the port manually to ${SSHDPORT}
     in  /etc/ssh/sshd_config    OR
  - clean up the firewall rules and
     other stuff reflecting YOUR PORT" 13 50
      clear

      dlog "check unsuccessful, port ${SSHDPORT} not found in sshd_config"
      drun 'cat /etc/ssh/sshd_config  | grep -v "^\$" | grep -v "^#"'
    else
      dlog "check successful, port change to ${SSHDPORT} in sshd_config"
    fi
  else # when /etc/ssh/sshd_config does not exist
    if [ "$(cat /etc/ssh/sshd_config.d/*.conf | grep -c "^Port ${SSHDPORT}\$")" -ne 0 ] ; then
      dlog "check succesfull, port changed to ${SSHDPORT} in a file in /etc/ssh/sshd.config.d/"
    else
      if [ -n "$(cat /etc/ssh/sshd_config.d/*.conf)" ] && [ "$(cat /etc/ssh/sshd_config.d/*.conf | grep -c "^Port ")" -ge 1 ] ; then
        dialog --title 'sshd port' --ok-label 'Understood.' --cr-wrap --msgbox "Congrats, you had already changed your sshd port to something other than 22.
Please clean up and either
  - change the port manually to ${SSHDPORT}
     in a file in /etc/ssh/sshd_config.d/*.conf    OR
  - clean up the firewall rules and
     other stuff reflecting YOUR PORT" 13 50
        clear
      else # a file Port*.conf does not exist
        echo "Port ${SSHDPORT}" > "${TMPDIR}"/Port_${SSHDPORT}.conf
        sudorun "mv ${TMPDIR}/Port_${SSHDPORT}.conf /etc/ssh/sshd_config.d/"
        sudorun "chown root:root /etc/ssh/sshd_config.d/Port_${SSHDPORT}.conf"
        if [ -x /usr/sbin/getenforce ] ; then
          if [ "$(sudo /usr/sbin/getenforce)" = "Enforcing" ] ; then
            if [ ! -x /usr/sbin/semanage ] ; then
              sudorun "zypper --non-interactive in --no-recommends policycoreutils-python-utils"
            else
              echo "ERROR utility semanage needs to be installed, exiting!!"
              exit 9
            fi
          fi
          sudorun "semanage port -a -t ssh_port_t -p tcp ${SSHDPORT}"
        fi
      fi
    fi
  fi
fi # interactive
###########################################################
## Modifying syslog config
###########################################################

dlog "setting interface in syslog config"
# no %%interface%% in dshield.conf template anymore, so only copying file
# run 'sed "s/%%interface%%/$interface/" < $progdir/../etc/rsyslog.d/dshield.conf > /etc/rsyslog.d/10-dshield.conf'
sudo_copy "$progdir"/../etc/rsyslog.d/dshield.conf /etc/rsyslog.d/10-dshield.conf 600
# cleanup legacy
if [ -f /etc/rsyslog.d/dshield.conf ]; then
    sudorun "rm /etc/rsyslog.d/dshield.conf"
fi




dsudorun 'cat /etc/rsyslog.d/10-dshield.conf'

###########################################################
## Further copying / configuration
###########################################################

#
# moving dshield stuff to target directory
# (don't like to have root run scripty which are not owned by root)
#

sudorun "mkdir -m 0750 -p ${DSHIELDDIR}"
if [ ! -d "${DSHIELDDIR}"/etc ]; then
    run "mkdir -m 0750 ${DSHIELDDIR}/etc"
else
    run "chmod 0750 ${DSHIELDDIR}/etc"
fi

if ! grep -qE '^webhpot' /etc/passwd; then
    dlog "creating webhpot user"
    if [ "$ID" != "opensuse" ]; then
	sudorun 'adduser --gecos "Honeypot,A113,555-1212,555-1212" --disabled-password --quiet --home /srv/web --no-create-home webhpot'	
    else
	sudorun 'useradd -c "Honeypot,A113,555-1212,555-1212" -M -U -d /srv/web webhpot'
        sudorun 'passwd -d webhpot' # disable password	
    fi
    outlog "Added user 'webhpot'"
else
    outlog "User 'webhpot' already exists"
fi


# using -R for legacy systems that may still have root owned files in this directory
sudorun "chown -R ${SYSUSERID}:webhpot ${DSHIELDDIR}"

if [ -f ${DSHIELDDIR}/fwlogparser.py ]; then
    run "rm ${DSHIELDDIR}/fwlogparser.py"
fi
do_copy "$progdir"/../srv/dshield/fwlogparser.py ${DSHIELDDIR} 700
if [ -f ${DSHIELDDIR}/status.sh ]; then
    run "rm ${DSHIELDDIR}/status.sh"
fi
do_copy "$progdir"/status.sh ${DSHIELDDIR} 700
if [ -f ${DSHIELDDIR}/cleanup.sh ]; then
    run "rm ${DSHIELDDIR}/cleanup.sh"
fi
do_copy "$progdir"/cleanup.sh ${DSHIELDDIR} 700
if [ -f ${DSHIELDDIR}/update.sh ]; then
    run "rm ${DSHIELDDIR}/update.sh"
fi
do_copy "$progdir"/update.sh ${DSHIELDDIR} 700
if [ -f ${DSHIELDDIR}/DShield.py ]; then
    run "rm ${DSHIELDDIR}/DShield.py"
fi
do_copy "$progdir"/../srv/dshield/DShield.py ${DSHIELDDIR} 700
if [ -f ${DSHIELDDIR}/updatehoneypotip.sh ]; then
    run "rm ${DSHIELDDIR}/updatehoneypotip.sh"
fi
do_copy "$progdir"/updatehoneypotip.sh ${DSHIELDDIR} 700
if [ "$ID" = "opensuse" ]; then
  run "patch ${DSHIELDDIR}/DShield.py $progdir/../srv/dshield/DShield.patch"
fi

# check: automatic updates allowed?

# first initialize if not defined
if [ "$MANUPDATES" == "" ]; then
  MANUPDATES=0
fi

#
# "random" offset for cron job so not everybody is reporting at once
#

dlog "creating /etc/cron.d/dshield"
offset1=$(shuf -i0-29 -n1)
offset2=$((offset1 + 30))
# important: first line overwrites old file to avoid duplication
echo "${offset1},${offset2} * * * * root ${DSHIELDDIR}/fwlogparser.py" >"${TMPDIR}"/cron.dshield
offset1=$(shuf -i0-59 -n1)
offset2=$(shuf -i0-23 -n1)
echo "${offset1} ${offset2} * * * root ${DSHIELDDIR}/update.sh --cron >/dev/null " >>"${TMPDIR}"/cron.dshield
offset1=$(shuf -i0-59 -n1)
offset2=$(shuf -i0-23 -n1)
echo "${offset1} ${offset2} * * * root /sbin/reboot" >>"${TMPDIR}"/cron.dshield
offset1=$(shuf -i0-59 -n1)
offset2=$(shuf -i0-23 -n1)
echo "${offset1} ${offset2} * * * root ${DSHIELDDIR}/updatehoneypotip.sh" >>"${TMPDIR}"/cron.dshield
offset1=$(shuf -i0-59 -n1)
offset2=$(shuf -i0-23 -n1)
echo "${offset1} ${offset2} * * * root /usr/bin/journalctl --vacuum-time=7d --quiet" >>"${TMPDIR}"/cron.dshield


# run status check 5 minutes before reboot
if [ "$offset1" -gt 5 ]; then
  offset1=$((offset1 - 5))
else
  offset1=$((offset1 + 54))
  if [ "$offset2" -gt 0 ]; then
    offset2=$((offset2 - 1))
  else
    offset2=23
  fi
fi
# shellcheck disable=SC2129
echo "${offset1} ${offset2} * * * root cd ${DSHIELDDIR}; ./status.sh >/dev/null " >> "${TMPDIR}"/cron.dshield
echo "0 10 * * * root find /srv/cowrie/var/log/cowrie -name 'cowrie.*' -ctime +7 -delete" >> "${TMPDIR}"/cron.dshield
sudorun "cp ${TMPDIR}/cron.dshield /etc/cron.d/dshield"
sudorun "chmod 755 /etc/cron.d/dshield"
dsudorun 'cat /etc/cron.d/dshield'

#
# Update dshield Configuration
#
dlog "creating new /src/dshield/etc/dshield.ini"
if [ -f ${DSHIELDINI} ]; then
  dlog "old dshield.ini follows"
  drun "cat ${DSHIELDINI}"
  run "mv ${DSHIELDINI} ${DSHIELDINI}.${INSTDATE}"
fi

if [ -f /etc/dshield.ini ]; then
    sudorun 'rm /etc/dshield.ini'
    sudorun "ln -s ${DSHIELDINI} /etc/dshield.ini"
fi


# new shiny config file
run "touch ${DSHIELDINI}"
run "chmod 600 ${DSHIELDINI}"
run "echo '[DShield]' >> ${DSHIELDINI}"
run "echo 'interface=$interface' >> ${DSHIELDINI}"
run "echo 'version=$myversion' >> ${DSHIELDINI}"
run "echo 'email=$email' >> ${DSHIELDINI}"
run "echo 'userid=$uid' >> ${DSHIELDINI}"
run "echo 'apikey=$apikey' >> ${DSHIELDINI}"
run "echo 'piid=$piid' >> ${DSHIELDINI}"
run "echo '# the following lines will be used by a new feature of the submit code: '  >> ${DSHIELDINI}"
run "echo '# replace IP with other value and / or anonymize parts of the IP'  >> ${DSHIELDINI}"
run "echo 'honeypotip=$honeypotip' >> ${DSHIELDINI}"
run "echo 'replacehoneypotip=' >> ${DSHIELDINI}"
run "echo 'anonymizeip=' >> ${DSHIELDINI}"
run "echo 'anonymizemask=' >> ${DSHIELDINI}"
run "echo 'fwlogfile=/var/log/dshield.log' >> ${DSHIELDINI}"
nofwlogging=$(quotespace "$nofwlogging")
run "echo 'nofwlogging=$nofwlogging' >> ${DSHIELDINI}"
CONIPS="$(quotespace "$CONIPS")"
run "echo 'localips=$CONIPS' >> ${DSHIELDINI}"
ADMINPORTS=$(quotespace "$ADMINPORTS")
run "echo 'adminports=$ADMINPORTS ' >> ${DSHIELDINI}"
nohoneyips=$(quotespace "$nohoneyips")
run "echo 'nohoneyips=$nohoneyips' >> ${DSHIELDINI}"
nohoneyports=$(quotespace "$nohoneyports")
run "echo 'nohoneyports=$nohoneyports' >> ${DSHIELDINI}"
run "echo 'manualupdates=$MANUPDATES' >> ${DSHIELDINI}"
run "echo 'telnet=$telnet' >> ${DSHIELDINI} "
run "echo '[plugin:tcp:http]' >> ${DSHIELDINI}"
run "echo 'http_ports=[8000]' >> ${DSHIELDINI}"
run "echo 'https_ports=[8443]' >> ${DSHIELDINI}"
run "echo 'submit_log_rate=$submit_log_rate' >> ${DSHIELDINI}"
run "echo 'queue_trigger=$queue_trigger' >> ${DSHIELDINI}"
run "echo 'web_log_limit=$web_log_limit' >> ${DSHIELDINI}"
run "echo 'web_log_purgefactor=$web_log_purgefactor' >> ${DSHIELDINI}"
run "echo 'debug=false' >> ${DSHIELDINI}"
run "echo 'local_logs_file=$local_logs_file' >> ${DSHIELDINI}"
run "echo 'enable_local_logs=$enable_local_logs' >> ${DSHIELDINI}"
run "echo '# this section may disappear in future versions' >> ${DSHIELDINI}"
run "echo '[iscagent]' >> ${DSHIELDINI}"
database=$(quotespace "$database")
run "echo 'database=$database' >> ${DSHIELDINI}"
archivedatabase=$(quotespace "$archivedatabase")
run "echo 'archivedatabase=$archivedatabase' >> ${DSHIELDINI}"
run "echo 'debug=false' >> ${DSHIELDINI}"
dlog "new ${DSHIELDINI} follows"
drun "cat ${DSHIELDINI}"
# making sure permissions are right for the ini file
sudorun "chown -R ${SYSUSERID}:webhpot ${DSHIELDDIR}"
sudorun "chmod 0640 ${DSHIELDINI}"
if [ -f /etc/dshield.ini ]; then
    sudorun "rm /etc/dshield.ini"
fi
sudorun "ln -s ${DSHIELDINI} /etc/dshield.ini"


###########################################################
## Installation of cowrie
###########################################################

dlog "installing cowrie"

# step 1 (Install OS dependencies): done



# step 2 (Create a user account)
dlog "checking if cowrie OS user already exists"
if ! grep '^cowrie:' -q /etc/passwd; then
  dlog "... no, creating"
  if [ "$ID" != "opensuse" ]; then
    sudorun 'adduser --gecos "Honeypot,A113,555-1212,555-1212" --disabled-password --quiet --home /srv/cowrie --no-create-home cowrie'
  else
    sudorun 'useradd -c "Honeypot,A113,555-1212,555-1212" -M -U -d /srv/cowrie cowrie'
    sudorun 'passwd -d cowrie' # disable password
  fi
  outlog "Added user 'cowrie'"
else
  outlog "User 'cowrie' already exists in OS. Making no changes to OS user."
fi

# add current user to cowrie group to help with permissions for install later
sudorun "usermod -a -G cowrie ${SYSUSERNAME}"

# step 3 (Checkout the code)
# (we will stay with zip instead of using GIT for the time being)
dlog "downloading and unzipping cowrie"
if [ "$ID" != "opensuse" ] ; then
  if [ "$BETA" == 1 ]; then
    run "$CURL https://www.dshield.org/cowrie-beta.zip > ${TMPDIR}/cowrie.zip"
  else
    run "$CURL -m 60 --connect-timeout 5 https://www.dshield.org/cowrie.zip > ${TMPDIR}/cowrie.zip"
  fi
else
    # the version of cowrie on dshield.org is too old for openSUSE
    run "git clone https://github.com/cowrie/cowrie.git" ${TMPDIR}/cowrie
fi

# shellcheck disable=SC2181
if [ ${?} -ne 0 ]; then
  outlog "Something went wrong downloading cowrie, ZIP corrupt."
  exit 9
fi
if [ "$ID" != "opensuse" ] ; then
  if [ -f "${TMPDIR}"/cowrie.zip ]; then
    run "unzip -qq -d ${TMPDIR} ${TMPDIR}/cowrie.zip "
  else
    outlog "Can not find cowrie.zip in ${TMPDIR}"
    exit 9
  fi
else
  if [ ! -d "${TMPDIR}"/cowrie ] ; then
    outlog "Can not find directory cowrie in ${TMPDIR}"
    exit 9
  fi
fi

#
# deleting old backups
#

sudorun "rm -rf /srv/cowrie.2*"
sudorun "rm -rf /srv/www.2*"

#
# pruning logs prior to backup
#

sudorun "rm -f /srv/cowrie/var/log/cowrie/cowrie.log.2*"
sudorun "rm -f /srv/cowrie/var/log/cowrie/cowrie.json.2*"


if [ -d ${COWRIEDIR} ]; then
  dlog "old cowrie installation found, moving"
  sudorun "mv ${COWRIEDIR} ${COWRIEDIR}.${INSTDATE}"
  sudorun "chown -R ${SYSUSERID}:${GROUPID} ${COWRIEDIR}.${INSTDATE}"
fi


dlog "moving extracted cowrie to ${COWRIEDIR}"
if [ -d "${TMPDIR}"/cowrie ]; then
  sudorun "mv ${TMPDIR}/cowrie ${COWRIEDIR}"
else
    if [ -d "${TMPDIR}"/cowrie-master ]; then
	sudorun "mv ${TMPDIR}/cowrie-master ${COWRIEDIR}"
    else
	outlog "${TMPDIR}/cowrie / cowrie-master not found"
	exit 9
    fi
fi



# step 4 (Setup Virtual Environment)
outlog "Installing Python packages with PIP. This will take a LONG time."
OLDDIR=$(pwd)

if [ ! -d ${COWRIEDIR} ]; then
    sudorun "mkdir ${COWRIEDIR}"

fi
sudorun "chown ${SYSUSERID}:cowrie ${COWRIEDIR}"
sudorun "chmod 0770 $COWRIEDIR"
cd ${COWRIEDIR} || exit
dlog "setting up virtual environment"
run 'sudo -u cowrie virtualenv --python=python3 cowrie-env'
run 'sudo chgrp -R cowrie /srv/cowrie'
run 'sudo chmod -R g+w /srv/cowrie/cowrie-env/'
dlog "activating virtual environment"
run 'source cowrie-env/bin/activate'

if [ "$FAST" == "0" ]; then
    dlog "installing cowrie dependencies: requirements.txt"
    run 'sg cowrie -c "pip3 install --require-virtualenv --upgrade pip"'
    run 'sg cowrie -c "pip3 install --require-virtualenv --upgrade bcrypt"'
    run 'sg cowrie -c "pip3 install --require-virtualenv --upgrade requests"'
    run 'sg cowrie -c "pip3 install --require-virtualenv -r requirements.txt"'
    run 'sg cowrie -c "pip3 install --require-virtualenv dateutils"'
    run 'sg cowrie -c "pip3 install --require-virtualenv -e ."'
    # shellcheck disable=SC2181
    if [ ${?} -ne 0 ]; then
       outlog "Error installing dependencies from requirements.txt. See ${LOGFILE} for details."
       exit 9
    fi
else
    dlog "skipping requirements in fast mode"
fi


# older Pis have issues with the slack dependency.
# we only need 'requests'
# dlog "installing dependencies requirements-output.txt"
# run 'pip3 install --upgrade -r requirements-output.txt'
if [ "$ID" != "opensuse" ] ; then
    run 'sg cowrie -c "pip3 install --require-virtualenv --upgrade requests"'
    # shellcheck disable=SC2181
    if [ ${?} -ne 0 ]; then
	outlog "Error installing dependencies from requirements-output.txt. See ${LOGFILE} for details."
	exit 9
    fi
fi
cd "${OLDDIR}" || exit

outlog "Doing further cowrie configuration."

# step 6 (Generate a DSA key)
dlog "generating cowrie SSH host key"
# dsa is too insecure and possibly not supported anymore in ssh-keygen; so use rsa
sudorun "ssh-keygen -t rsa -b 1024 -N '' -f ${COWRIEDIR}/var/lib/cowrie/ssh_host_rsa_key "

# step 5 (Install configuration file)
dlog "copying cowrie.cfg and adding entries"
# adjust cowrie.cfg
export uid
export apikey
hostname=$(shuf /usr/share/dict/american-english | head -1 | sed 's/[^a-z]//g')
export hostname
export sensor_name=dshield-$uid-$myversion
fake1=$(shuf -i 1-255 -n 1)
fake2=$(shuf -i 1-255 -n 1)
fake3=$(shuf -i 1-255 -n 1)
fake_addr=$(printf "10.%d.%d.%d" "$fake1" "$fake2" "$fake3")
export fake_addr
arch=$(arch)
export arch
kernel_version=$(uname -r)
export kernel_version
kernel_build_string=$(uname -v | sed 's/SMP.*/SMP/')
export kernel_build_string
ssh_version=$(ssh -V 2>&1 | cut -f1 -d',')
export ssh_version
export ttylog='false'
export telnet
dsudorun "cat ..${COWRIEDIR}/cowrie.cfg | envsubst > ${COWRIEDIR}/cowrie.cfg"

# make output of simple text commands more real

dlog "creating output for text commands"

sudorun "mkdir -p ${TXTCMDS}/bin"
sudorun "mkdir -p ${TXTCMDS}/usr/bin"
sudorun "df > ${TMPDIR}/df"
sudorun "mv ${TMPDIR}/df ${TXTCMDS}/bin/df"
sudorun "dmesg > ${TMPDIR}/dmesg"
sudorun "mv ${TMPDIR}/dmesg ${TXTCMDS}/bin/dmesg"
sudorun "mount > ${TMPDIR}/mount"
sudorun "mv ${TMPDIR}/mount ${TXTCMDS}/bin/mount"
run "ulimit > ${TMPDIR}/ulimit"
sudorun "mv ${TMPDIR}/ulimit ${TXTCMDS}/bin/ulimit"
sudorun "lscpu > ${TMPDIR}/lscpu"
sudorun "mv ${TMPDIR}/lscpu ${TXTCMDS}/usr/bin/lscpu"
sudorun "echo '-bash: emacs: command not found' > ${TMPDIR}/emacs"
sudorun "mv ${TMPDIR}/emacs ${TXTCMDS}/usr/bin/emacs"
sudorun "echo '-bash: locate: command not found' > ${TMPDIR}/locate"
sudorun "mv ${TMPDIR}/locate ${TXTCMDS}/usr/bin/locate"

sudorun "chown -R cowrie:cowrie ${COWRIEDIR}"

# echo "###########  $progdir  ###########"

dlog "copying cowrie system files"

sudo_copy "$progdir"/../lib/systemd/system/cowrie.service /lib/systemd/system/cowrie.service 644
# file copied/added from previous version of cowrie
sudo_copy "$progdir"/../srv/cowrie/bin/cowrie /srv/cowrie/bin/cowrie
sudorun chmod cowrie:cowrie /srv/cowrie/bin/cowrie
sudo_copy "$progdir"/../etc/cron.hourly/cowrie /etc/cron.hourly 755
if [ "$ID" = opensuse ] ; then
  # add some selinux policy rules to let cowrie.service succeed
  #sudo_copy "$progdir"/../etc/cowrie.pp /etc/ 644
  #sudo_copy "$progdir"/../etc/cowrie1.pp /etc/ 644
  #sudorun semodule -i /etc/cowrie.pp  
  #sudorun semodule -i /etc/cowrie1.pp
  sudorun semanage fcontext -a -t bin_t /srv/cowrie/bin/cowrie
  sudorun restorecon -vR /srv/cowrie/bin/cowrie
fi

# make sure to remove old cowrie start if they exist
if [ -f /etc/init.d/cowrie ]; then
  rm -f /etc/init.d/cowrie
fi
sudorun "mkdir -p ${COWRIEDIR}/log"
sudorun "chmod 755 ${COWRIEDIR}/log"
sudorun "chown cowrie:cowrie ${COWRIEDIR}/log"
sudorun "mkdir -p ${COWRIEDIR}/log/tty"
sudorun "chmod 755 ${COWRIEDIR}/log/tty"
sudorun "chown cowrie:cowrie ${COWRIEDIR}/log/tty"
sudo find /etc/rc?.d -name '*cowrie*' -delete
sudorun 'systemctl daemon-reload'
sudorun 'systemctl enable cowrie.service'

dlog 'deactivate cowrie venv'
#sudorun 'deactivate'
run deactivate


###########################################################
## Installing web honeypot
###########################################################

outlog "Installing Web Honeypot"
dlog "Installing Web Honeypot"


sudorun "mkdir -p ${WEBHPOTDIR}"
sudo_copy "${progdir}"/../srv/web  "${WEBHPOTDIR}"/../
if [ ! -d "${WEBHPOTDIR}"/run ]; then
    sudorun "mkdir -m 0700 ${WEBHPOTDIR}/run"
fi
sudorun "chown -R webhpot:webhpot ${WEBHPOTDIR}"
sudo -u webhpot pip install --upgrade --target "${WEBHPOTDIR}"/isc_agent requests
OLDPWD=$PWD
cd "${WEBHPOTDIR}" || exit
sudo -u webhpot python3 -m zipapp ./isc_agent
sudo -u webhpot find ./isc_agent -mindepth 1 -type d -exec rm -rf {} +
sudo_copy "${progdir}"/../srv/web/web-honeypot.service /etc/systemd/system/web-honeypot.service 644
cd "${WEBHPOTDIR}" || exit
# disable old service in case it is still enabled
if [ "$(sudo systemctl is-enabled isc-agent.service)" = "enabled" ] ; then
  sudorun "systemctl disable isc-agent.service"
fi
# enable new service
sudorun "systemctl daemon-reload"
sudorun "systemctl enable web-honeypot.service"

[ "$ID" != "opensuse" ] && run "sudo systemctl enable systemd-networkd.service systemd-networkd-wait-online.service"
cd "${OLDPWD}" || exit

###########################################################
## Copying further system files
###########################################################

dlog "copying further system files"


###########################################################
## Apt Cleanup
###########################################################
if [ "$dist" == "apt" ]; then
  sudorun 'apt autoremove -y'
fi

###########################################################
## Configuring MOTD
###########################################################

#
# modifying motd
#

dlog "installing /etc/motd"
if [ "$ID" != "opensuse" ]; then
  cat >"${TMPDIR}"/motd <<EOF

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.

***
***    DShield Honeypot
***

EOF
else # openSUSE
  hostname="$(cat /etc/hostname)"
  cat >"${TMPDIR}"/motd <<EOF

The programs included with the openSUSE GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

openSUSE GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.

***
***    DShield Honeypot $hostname
***

EOF
fi

sudorun "mv ${TMPDIR}/motd /etc/motd"
sudorun "chmod 644 /etc/motd"
sudorun "chown root:root /etc/motd"

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
  echo 01 >../etc/CA/ca.serial
fi
drun "ls ../etc/CA/certs/*.pem 2>/dev/null"
dlog "Exit code not zero is possible, is expected in first run"
if [ "$(find ../etc/CA/certs -name '*.pem' 2>/dev/null | wc -l)" -gt 0 ]; then
  if [ "$INTERACTIVE" == 1 ]; then
    dlog "CERTs may already be there, asking user"
    dialog --title 'Generating CERTs' --yesno "You may already have CERTs generated. Do you want me to re-generate CERTs and erase all existing ones?" 10 50
    response=$?
    case $response in
    "${DIALOG_OK}")
      dlog "user said OK to generate new CERTs, so removing old CERTs"
      # cleaning up old certs
      run 'sudo rm ../etc/CA/certs/*'
      run 'sudo rm ../etc/CA/keys/*'
      run 'sudo rm ../etc/CA/requests/*'
      run 'sudo rm ../etc/CA/index.*'
      GENCERT=1
      ;;
    "${DIALOG_CANCEL}")
      dlog "user said no, so no new CERTs will be created, using existing ones"
      GENCERT=0
      ;;
    "${DIALOG_ESC}")
      dlog "user pressed ESC, aborting"
      clear
      exit 5
      ;;
    esac
  else
    GENCERT=0
  fi #interactive
fi
clear

if [ ! $SCRIPTDIR/../etc/CA/keys/honeypot.key ]; then
    GENCERT=1
fi
if [ ! $SCRIPTDIR/../etc/CA/certs/honeypot.crt ]; then
    GENCERT=1
fi
if [ ! -f $SCRIPTDIR/../etc/CA/keys/combined_stunnel.pem ]; then
    GENCERT=1
else
    if ! sudo grep -q 'BEGIN PRIVATE KEY' /srv/web/combined_stunnel.pem; then
	GENCERT=1
    fi
    if ! sudo grep -q 'BEGIN CERTIFICATE' /srv/web/combined_stunnel.pem; then
       GENCERT=1
    fi
	

fi

###
# fixing legacy permissions
###

sudo find ${SCRIPTDIR}/../etc/CA -uid 0 -exec chown ${SYSUSERID} {} \;



if [ ${GENCERT} -eq 1 ]; then
  dlog "generating new CERTs using ./makecert.sh"
  "${SCRIPTDIR}"/makecert.sh $INTERACTIVE 
  dlog "moving certs to /srv/web honeypot"
  run "cat $SCRIPTDIR/../etc/CA/certs/honeypot.crt $SCRIPTDIR/../etc/CA/keys/honeypot.key > $SCRIPTDIR/../etc/CA/keys/combined_stunnel.pem"
  sudorun "cp $SCRIPTDIR/../etc/CA/keys/combined_stunnel.pem ${WEBHPOTDIR}/combined_stunnel.pem"
  sudorun "cp $SCRIPTDIR/../etc/CA/keys/honeypot.key ${WEBHPOTDIR}/honeypot.key"
  sudorun "cp $SCRIPTDIR/../etc/CA/certs/honeypot.crt ${WEBHPOTDIR}/honeypot.crt"
  sudorun "chown webhpot:webhpot ${WEBHPOTDIR}/honeypot.*"
  sudorun "chown webhpot:webhpot ${WEBHPOTDIR}/combined_stunnel.pem"
  sudorun "chmod 600 ${WEBHPOTDIR}/honeypot.key"
  sudorun "chmod 600 ${WEBHPOTDIR}/combined_stunnel.pem"
  dlog "updating ${DSHIELDINI}"
  run "sudo echo \"tlskey=${WEBHPOTDIR}/honeypot.key\" >> ${DSHIELDINI}"
  run "sudo echo \"tlscert=${WEBHPOTDIR}/honeypot.crt\" >> ${DSHIELDINI}"
fi

#
# creating PID directory
#

run 'mkdir -p /var/tmp/dshield'

# rotate dshield firewall logs
sudo_copy "$progdir"/../etc/logrotate.d/dshield /etc/logrotate.d 644
[ "$ID" = "opensuse" ] && sudo sed -e 's/\/usr\/lib.*$/systemctl reload rsyslog/' -i /etc/logrotate.d/dshield
if [ -f "/etc/cron.daily/logrotate" ]; then
  sudorun "mv /etc/cron.daily/logrotate /etc/cron.hourly"
fi


###########################################################
## LEGACY CLEANUP
###########################################################

if [ -d "/srv/webhpot" ]; then
    sudorun "rm -rf /srv/webhpot"
fi
if [ -d "/srv/isc-agent" ]; then
    sudorun "rm -rf /srv/isc-agent"
fi
if [ -d "/srv/db" ]; then
    sudorun "rm -rf /srv/db"
fi


###########################################################
## POSTINSTALL OPTION
###########################################################

if [ -f /root/bin/postinstall.sh ]; then
  sudorun "/root/bin/postinstall.sh"
else
  outlog
  outlog
  outlog "POSTINSTALL OPTION"
  outlog
  outlog "In case you need to do something extra after an installation, especially when you do an automatic"
  outlog "update, in which case you may loose changes made after the initial installation."
  outlog "For this situation you can have a post-installation script in /root/bin/postinstall.sh, which"
  outlog "will be called at the end of processing the install.sh script, also called in the automatic update."
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
outlog "Please include a sanitized version of ${DSHIELDINI} in bug reports"
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
outlog "   or check https://isc.sans.edu/myreports.html (after logging in)"
outlog
outlog " for help, check our slack channel: https://isc.sans.edu/slack "
outlog
outlog " In case you are low in disk space, run /srv/dshield/cleanup.sh "
outlog " This will delete some backups and logs "
