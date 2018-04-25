#!/usr/bin/env bash
set -e

# source profile
source /etc/profile
[[ -f ${HOME}/.common/config ]] && source ${HOME}/.common/config

echo -e "Press ctrl + c to break out of this"
find ${HOME}/.komodo/ -type f -iname debug.log | xargs tail -f
