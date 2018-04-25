#!/usr/bin/env bash
set -e

# Enable Job Control
set -m

export KOMODO_CLI="<KOMODO_SRC_DIR>/src/komodo-cli"

function komodod_stop () {
  while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
      -seq)
        export komodod_run_SEQUENCE="${2}"
        shift
      ;;
      *)
        echo "WARNING: Unknown option $key" >&2
        exit 1
      ;;
    esac
    shift
  done

  # stop the assetchain in 120 seconds or fail
  count=0
  while [[ count -lt 20 ]]; do
    if ! $(ps aux | grep -w "ac_name=TXSCL${komodod_run_SEQUENCE}" | grep -v grep) >& /dev/null; then
      if $($KOMODO_CLI -ac_name=TXSCL${komodod_run_SEQUENCE} getinfo >& /dev/null); then
        echo -e "## Stopping ac_name=TXSCL${komodod_run_SEQUENCE} ##"
        $KOMODO_CLI -ac_name=TXSCL${komodod_run_SEQUENCE} stop
        break
      fi
    fi
    count=${count}+1
    sleep 1
  done
}

komodod_stop &

# start jobs in parallel
for (( i=<AC_START>; i<=<AC_END>; i++ )); do
  mod_i=$(printf "%03d " $i)

  komodod_stop -seq $mod_i  &
done

# Wait for all parallel jobs to finish
while [ 1 ]; do fg >& /dev/null; [ $? == 1 ] && break; done
