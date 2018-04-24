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
Setup and configure insight-explorer.
Current focus is on Komodo AssetChains for Transaction tests; hence TXSCL[x] onwards.
Currently assumes that you have Komodo setup as:
- ${HOME}/komodo/src/komodo/komodod
- ${HOME}/komodo/src/komodo/komodo-cli
- ${HOME}/.komodo/${AC}/$AC.conf - eg: [ ${HOME}/.komodo/TXSCL/$TXSCL.conf ]

-h | --help                           Show this help
--username                            Username to run daemons
--ac-start                            Assetchain start counter
--ac-end                              Assetchain end counter
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

if [[ -e ${KOMODO_SRC_DIR}/komodod ]]; then

  # Run it for `TXSCL` first and then for the rest
  komodod_run -daemon

  for ((i=${AC_START}; i<${AC_END}; i++)); do
    komodod_run -daemon
    # This will create ${HOME}/.komodo/TXSCL${i}/TXSCL${i}.conf
  done

fi
