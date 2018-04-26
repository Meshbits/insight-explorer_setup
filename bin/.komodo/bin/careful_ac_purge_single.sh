#!/usr/bin/env bash
set -e

while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -assetchain)
      ASSETCHAIN="${2}"
      shift
    ;;
    *)
    cat >&2 <<HELP
Usage: \${HOME}/.komodo/bin/$(basename $0)
Purge a single assetchain

-h | --help                           Show this help
HELP
      exit 0
    ;;
  esac
  shift
done

read -p "## Warning: You are about to purge ${ASSETCHAIN}. \
\nPlease enter [y]es or [y] ##" userinput

case ${userinput} in
  ( YES | yes | Yes | Y | y )
    echo -e '## Purging assetchain folder now ##'
  ;;
  (*)
    echo -e "You didn't enter a valid option, existing.."
    exit 1
  ;;
esac

# source profile
source /etc/profile
[[ -f ${HOME}/.common/config ]] && source ${HOME}/.common/config

rm -f ${HOME}/gen${ASSETCHAIN}
rm -rf ${HOME}/.komodo/${ASSETCHAIN}
