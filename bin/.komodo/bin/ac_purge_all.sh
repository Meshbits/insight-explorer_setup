#!/usr/bin/env bash
set -e

rm -f ${HOME}/genTXSCL
rm -rf ${HOME}/.komodo/TXSCL

# start jobs in parallel
for (( i=<AC_START>; i<=<AC_END>; i++ )); do
  mod_i=$(printf "%03d " $i)

  rm -f ${HOME}/genTXSCL${mod_i}
  rm -rf ${HOME}/.komodo/TXSCL${mod_i}
done

# Wait for all parallel jobs to finish
while [ 1 ]; do fg >& /dev/null; [ $? == 1 ] && break; done
