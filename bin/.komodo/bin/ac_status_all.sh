#!/usr/bin/env bash
set -e -m

export KOMODO_CLI="<KOMODO_SRC_DIR>/src/komodo-cli"

# start jobs in parallel
for (( i=<AC_START>; i<=<AC_END>; i++ )); do

  count=0
  while [[ count -lt 120 ]]; do
    if $($KOMODO_CLI -ac_name=TXSCL$i getinfo >& /dev/null); then
      getinfo=$($KOMODO_CLI -ac_name=TXSCL$i getinfo)
      if [[ $(echo $getinfo | jq -r .longestchain) -eq $(echo $getinfo | jq -r .blocks) ]]; then
        echo -e "## ac_name=TXSCL$i in sync with the network ##"
        break
      fi
    fi
    count=${count}+1
    sleep 1
  done &

done

# Wait for all parallel jobs to finish
while [ 1 ]; do fg >& /dev/null; [ $? == 1 ] && break; done
