#!/usr/bin/env bash
set -e

# source profile
source /etc/profile
[[ -f ${HOME}/.common/config ]] && source ${HOME}/.common/config

# Enable Job Control
set -m

function komodod_run () {
  while [[ $# -gt 0 ]]; do
  	key="$1"
  	case $key in
      -pubkey)
        PUBKEY="-pubkey=${2}"
        shift
      ;;
      -coinname)
        COINNAME="${2}"
        shift
      ;;
      -supply)
        SUPPLY="${2}"
        shift
      ;;
      -daemon)
        DAEMON="-daemon"
      ;;
      -gen)
        GEN="-gen"
      ;;
      *)
        echo "WARNING: Unknown option $key" >&2
        exit 1
      ;;
    esac
    shift
  done

  if ! $(ps aux | grep -w "ac_name=${COINNAME}" | grep -v grep >& /dev/null); then
    <KOMODO_SRC_DIR>/src/komodod -ac_name="${COINNAME}" -ac_supply="${SUPPLY}" \
      -addnode=54.36.176.84 $DAEMON $GEN $PUBKEY
  else
    echo -e "ac_name=${COINNAME} already running"
  fi
}

# Check if komodod was created and then run
if [[ ! -f <KOMODO_SRC_DIR>/src/komodod ]]; then
  echo -e "Couldn't find komodod binary. Exiting.."
  exit 1
fi

# Get the coinlist; store name and value in variables
if [[ -f ${HOME}/.common/coinlist ]]; then
  source ${HOME}/.common/coinlist
else
  echo -e "Coinlist not found. Exiting.."
  exit 1
fi

# start jobs in parallel
for item in "${coinlist[@]}"; do
  coin_name=$(echo "${item}" | cut -d' ' -f1)
  coin_supply=$(echo "${item}" | cut -d' ' -f2)

  komodod_run -coinname ${coin_name} -supply ${coin_supply} -daemon &

  DAEMONCONF="${HOME}/.komodo/${coin_name}/${coin_name}.conf"
  if [[ -f ${DAEMONCONF} ]]; then
    RPCUSER=$(grep 'rpcuser' ${DAEMONCONF} | cut -d'=' -f2)
    RPCPASSWORD=$(grep 'rpcpassword' ${DAEMONCONF} | cut -d'=' -f2)
    RPCPORT=$(grep 'rpcport' ${DAEMONCONF} | cut -d'=' -f2)
  fi
done

# Wait for all parallel jobs to finish
while [ 1 ]; do fg >& /dev/null; [ $? == 1 ] && break; done
