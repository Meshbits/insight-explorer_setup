#!/usr/bin/env bash
set -e

echo -e "Press ctrl + c to break out of this"
find ${HOME}/.komodo/ -type f -iname debug.log | xargs tail -f
