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
- ${HOME}/.komodo/${AC}/$AC.conf - eg: [ ${HOME}/.komodo/TXSCL/$TXSCL.conf ]

-h | --help                           Show this help
--username                            Username to run daemons
--ac-start                            Assetchain start counter; eg: 001
--ac-end                              Assetchain end counter; eg: 100
--insight-repository                  Insight repository; defaults to
                                      https://github.com/KomodoPlatform/insight-ui-komodo for now
-ev | --example-variable              Set an EXAMPLE_VARIABLE variable to be use with the script
HELP
    exit 0
    ;;
    -ev|--example-variable)
      export EXAMPLE_VARIABLE=0
    ;;
    --ac-start)
      export AC_START="$2"
      shift
    ;;
    --ac-end)
      export AC_END="$2"
      shift
    ;;
    --username)
      export SCRIPTUSER="$2"
      shift
    ;;
    *)
    echo "WARNING: Unknown option $key" >&2
    exit 1
    ;;
  esac
  shift
done

# Variables
export SCRIPTNAME=$(realpath $0)
export SCRIPTPATH=$(dirname $SCRIPTNAME)
export KOMODO_SRC_DIR="${HOME}/komodo/src"
export KOMODO_CONF_DIR="${HOME}/.komodo"
export VAR_PROC $(cat /proc/cpuinfo | grep processor | wc -l)

[[ -z ${SCRIPTUSER+x} ]] && export SCRIPTUSER=meshbits
[[ -z ${KOMODO_SRC_DIR+x} ]] && export KOMODO_SRC_DIR="/home/${SCRIPTUSER}/komodo"
[[ -z ${KOMODO_REPOSITORY+x} ]] && export KOMODO_REPOSITORY='https://github.com/jl777/komodo.git'
[[ -z ${KOMODO_BRANCH+x} ]] && export KOMODO_BRANCH=jl777

# Functions
function komodod_run () {
  while [[ $# -gt 0 ]]; do
  	key="$1"
  	case $key in
      -pubkey)
        export komodod_run_PUBKEY="-pubkey=${2}"
        shift
      ;;
      -SEQ)
        export komodod_run_SEQUENCE="${2}"
        shift
      ;;
      -daemon)
        export komodod_run_DAEMON="-daemon"
      ;;
      -gen)
        export komodod_run_GEN="-gen"
      ;;
      *)
        echo "WARNING: Unknown option $key" >&2
        exit 1
      ;;
    esac
    shift
  done
  ${KOMODO_SRC_DIR}/komodod -ac_name=TXSCL${komodod_run_SEQUENCE} -ac_supply=100000000 -addnode=54.36.176.84 \
    $komodod_run_DAEMON $komodod_run_GEN $komodod_run_PUBKEY
}

# Add ${SCRIPTUSER} as the user if doesn't already exist
id -u ${SCRIPTUSER} &>/dev/null || adduser --disabled-password --gecos "" ${SCRIPTUSER}

# Enforce creation of sudoers entry for the ${SCRIPTUSER} user
echo "${SCRIPTUSER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${SCRIPTUSER}
chmod 0400 /etc/sudoers.d/${SCRIPTUSER}

#To disable the above systemd service/timer else it can cause conflict with the following apt-get commands:
echo "==> Disabling the release upgrader"
sed -i.bak 's/^Prompt=.*$/Prompt=never/' /etc/update-manager/release-upgrades

for item in 'apt-daily.service' 'apt-daily.timer'; do
  systemctl stop $item
  systemctl disable $item
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
  git sudo jq dnsutils wget tree inotify-tools pigz

# Setup komodod
sudo -H -E -u ${SCRIPTUSER} bash ${SCRIPTPATH}/setup_komodod.sh 2>&1 | tee -a ${userdatasetup_log}
