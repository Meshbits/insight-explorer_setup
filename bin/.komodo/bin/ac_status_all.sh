#!/usr/bin/env bash
set -e -m

# source profile
source /etc/profile
[[ -f ${HOME}/.common/config ]] && source ${HOME}/.common/config

KOMODO_CLI="<KOMODO_SRC_DIR>/src/komodo-cli"

function komodod_status () {
  while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
      -coinname)
        COINNAME="${2}"
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
    if ! $(ps aux | grep -w "ac_name=${COINNAME}" | grep -v grep >& /dev/null); then
      if $($KOMODO_CLI -ac_name=${COINNAME} getinfo >& /dev/null); then
        getinfo=$($KOMODO_CLI -ac_name=${COINNAME} getinfo 2> /dev/null)
        if [[ $(echo $getinfo | jq -r .longestchain) -eq $(echo $getinfo | jq -r .blocks) ]]; then
          echo -e "## ${COINNAME} in-sync with the network ##"
          break
        else
          echo -e "## ${COINNAME} not in-sync with the network ##"
        fi
      fi
    fi
    count=${count}+1
    sleep 1
  done
}

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
  komodod_status -coinname ${coin_name}  &
done

# Wait for all parallel jobs to finish
while [ 1 ]; do fg >& /dev/null; [ $? == 1 ] && break; done
