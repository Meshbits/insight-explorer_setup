#!/usr/bin/env bash
# Script[s] to setup insight-explorer on a Ubuntu 16.04 LTS
set -e

# Check if being run as a non-root user
if [[ $EUID -ne 0 ]]; then
   echo -e "This script must be run as root\n"
   exit 1
fi

# Present the options
while [[ $# -gt 0 ]]; do
	key="$1"
	case $key in
		-h|--help)
		cat >&2 <<HELP
Usage: userdata.sh [OPTIONS]
Setup and configure komodod, insight-explorer.
- ${HOME}/komodo/src/komodo/komodod
- ${HOME}/komodo/src/komodo/komodo-cli
- ${HOME}/.komodo/${AC}/${AC}.conf - eg: [ ${HOME}/.komodo/TXSCL/TXSCL.conf ]

Note:
For now, we assume that you have a `/home/bitcore_insight_explorer.tar.bz2` archive

-h | --help                           Show this help
--username                            Username to run daemons
--ac-coinlist                         Assetchain coinlist containing coin NAME and SUPPLY
--insight-repository                  Insight repository; defaults to
                                      https://github.com/KomodoPlatform/insight-ui-komodo for now

# Don't use unless you know what you doing:
--dont-build                          Allows the setup script to be run multiple times without rebuilding komodo
-ev | --example-variable              Set an EXAMPLE_VARIABLE variable to be use with the script
HELP
    exit 0
    ;;
    --username)
      export SCRIPTUSER="$2"
      shift
    ;;
    --ac-coinlist)
      export AC_COINLIST="$2"
      shift
    ;;
    --dont-build)
      export DONT_BUILD=false
    ;;
    -ev|--example-variable)
      export EXAMPLE_VARIABLE=0
    ;;
    *)
    echo "WARNING: Unknown option ${key}" >&2
    exit 1
    ;;
  esac
  shift
done

# Variables
export SCRIPTNAME=$(realpath $0)
export SCRIPTPATH=$(dirname ${SCRIPTNAME})

[[ -z ${SCRIPTUSER+x} ]] && export SCRIPTUSER=meshbits

#==================================================#
# These are probably going to not be needed on a physical hardware #

echo "==> Starting the setup <=="

# Disable unnecessary services
for list in iscsid lvm2-lvmetad mdadm
do
  systemctl stop ${list} >& /dev/null
  systemctl disable ${list} >& /dev/null
done

# Create a swapfile for Cloud Instances
if [[ ! -f /swapfile ]]; then
  dd if=/dev/zero of=/swapfile count=2048 bs=1M
  chmod 0600 /swapfile
  mkswap -v1 /swapfile
  swapon /swapfile

  # A better way is to put this in fstab
  grep -q "swapon /swapfile" /etc/rc.local || \
  sed -i "\$iswapon /swapfile" /etc/rc.local
fi

#==================================================#

# Add ${SCRIPTUSER} as the user if doesn't already exist
id -u ${SCRIPTUSER} &>/dev/null || adduser --disabled-password --gecos "" ${SCRIPTUSER}

# Enforce creation of sudoers entry for the ${SCRIPTUSER} user
echo "${SCRIPTUSER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${SCRIPTUSER}
chmod 0400 /etc/sudoers.d/${SCRIPTUSER}

#To disable the above systemd service/timer else it can cause conflict with the following apt-get commands:
sed -i.bak 's/^Prompt=.*$/Prompt=never/' /etc/update-manager/release-upgrades

for item in 'apt-daily.service' 'apt-daily.timer'; do
  systemctl stop ${item} >& /dev/null
  systemctl disable ${item} >& /dev/null
done

# wait until `apt-get updated` has been killed
while ! (systemctl list-units --all apt-daily.service | fgrep -q dead)
do
  sleep 1;
done

# Just in case, any process is left running
systemctl kill --kill-who=all apt-daily.service
systemctl mask apt-daily.service
systemctl daemon-reload

# This is needed in case packages or database is corrupted
dpkg --configure -a

# Run update and install basic stuff
apt-get -qq update
export DEBIAN_FRONTEND=noninteractive
apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -qq \
  upgrade
apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -qq \
  install \
  git sudo jq dnsutils wget tree inotify-tools htop


userdatasetup_log="/home/${SCRIPTUSER}/userdatasetup_log"
# Run other scripts
sudo -H -E -u ${SCRIPTUSER} bash ${SCRIPTPATH}/common_config.sh 2>&1 | tee -a ${userdatasetup_log}
sudo -H -E -u ${SCRIPTUSER} bash ${SCRIPTPATH}/setup_komodod.sh 2>&1 | tee -a ${userdatasetup_log}
