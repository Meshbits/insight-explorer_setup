#!/usr/bin/env bash
set -e

# Enable Job Control
set -m

function komodod_run () {
  while [[ $# -gt 0 ]]; do
  	key="$1"
  	case $key in
      -pubkey)
        export komodod_run_PUBKEY="-pubkey=${2}"
        shift
      ;;
      -seq)
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

  if ! $(ps aux | grep -w "ac_name=TXSCL${komodod_run_SEQUENCE}" | grep -v grep >& /dev/null ); then
    <KOMODO_SRC_DIR>/src/komodod -ac_name=TXSCL${komodod_run_SEQUENCE} -ac_supply=100000000 -addnode=54.36.176.84 \
      $komodod_run_DAEMON $komodod_run_GEN $komodod_run_PUBKEY
  else
    echo -e "ac_name=TXSCL${komodod_run_SEQUENCE} already running"
  fi
}

# Check if komodod was created and then run
if [[ ! -f <KOMODO_SRC_DIR>/src/komodod ]]; then
  echo -e "Couldn't find komodod binary. Exiting.."
  exit 1
fi

# Run it for `TXSCL` first and then the rest
komodod_run -daemon

# start jobs in parallel
for (( i=<AC_START>; i<=<AC_END>; i++ )); do
  mod_i=$(printf "%03d " $i)
  komodod_run -seq $mod_i -daemon &
  # This will create ${HOME}/.komodo/TXSCL${i}/TXSCL${i}.conf

  DAEMONCONF="${HOME}/.komodo/TXSCL${mod_i}/TXSCL${mod_i}.conf"
  RPCUSER=$(grep 'rpcuser' $DAEMONCONF | cut -d'=' -f2)
  RPCPASSWORD=$(grep 'rpcpassword' $DAEMONCONF | cut -d'=' -f2)
  RPCPORT=$(grep 'rpcport' $DAEMONCONF | cut -d'=' -f2)
done

# Wait for all parallel jobs to finish
while [ 1 ]; do fg 2> /dev/null; [ $? == 1 ] && break; done
