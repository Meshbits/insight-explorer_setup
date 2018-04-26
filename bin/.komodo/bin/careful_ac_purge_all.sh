#!/usr/bin/env bash
set -e

while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    *)
    cat >&2 <<HELP
Usage: \${HOME}/.komodo/bin/$(basename $0)
Purge all assetchains list in *coinlist*

-h | --help                           Show this help
HELP
      exit 0
    ;;
  esac
  shift
done

read -p "## Warning: You are about to purge all your assetchains listed in coinlist file. \
\nPlease enter [y]es or [y] \n ##" userinput

case ${userinput} in
  ( YES | yes | Yes | Y | y )
    echo -e '## Purging assetchain folders ##'
  ;;
  (*)
    echo -e "You didn't enter a valid option, existing.."
    exit 1
  ;;
esac

# source profile
source /etc/profile
[[ -f ${HOME}/.common/config ]] && source ${HOME}/.common/config

# Get the coinlist; store name and value in variables
if [[ -f ${HOME}/.common/coinlist ]]; then
  source ${HOME}/.common/coinlist
else
  echo -e "Coinlist not found. Exiting.."
  exit 1
fi

# Stop all assetchains
${dirname $0}/ac_stop_all.sh

# start jobs in parallel
for item in "${coinlist[@]}"; do
  coin_name=$(echo "${item}" | cut -d' ' -f1)

  rm -f ${HOME}/gen${coin_name}
  rm -rf ${HOME}/.komodo/${coin_name}
done

# Wait for all parallel jobs to finish
while [ 1 ]; do fg >& /dev/null; [ $? == 1 ] && break; done
