#!/usr/bin/env bash
set -e

# Enable Job Control
set -m

export KOMODO_CLI="<KOMODO_SRC_DIR>/src/komodo-cli"

function komodod_status () {
  while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
      -seq)
        SEQUENCE="${2}"
        shift
      ;;
      *)
        echo "WARNING: Unknown option $key" >&2
        exit 1
      ;;
    esac
    shift
  done

  # stop the assetchain in 10 seconds or fail
  count=0
  while [[ count -lt 120 ]]; do
    if ! $(ps aux | grep -w "ac_name=TXSCL${SEQUENCE}" | grep -v grep) >& /dev/null; then
      if $($KOMODO_CLI -ac_name=TXSCL${SEQUENCE} getinfo >& /dev/null); then
        getinfo=$($KOMODO_CLI -ac_name=TXSCL${SEQUENCE} getinfo 2> /dev/null)
        if [[ $(echo $getinfo | jq -r .longestchain) -eq $(echo $getinfo | jq -r .blocks) ]]; then
          echo -e "## TXSCL${SEQUENCE} in-sync with the network ##"
          break
        else
          echo -e "## TXSCL${SEQUENCE} not in-sync with the network ##"
        fi
      fi
    fi
    count=${count}+1
    sleep 1
  done
}

komodod_status &

# start jobs in parallel
for (( i=<AC_START>; i<=<AC_END>; i++ )); do
  mod_i=$(printf "%03d " $i)

  komodod_status -seq $mod_i  &
done

# Wait for all parallel jobs to finish
while [ 1 ]; do fg >& /dev/null; [ $? == 1 ] && break; done
