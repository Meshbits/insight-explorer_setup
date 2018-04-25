#!/usr/bin/env bash
# Setup global configuration for notary node setup
# Should only be called from userdata.sh
set -e

# Variables
[[ -z ${KOMODO_SRC_DIR+x} ]] && export KOMODO_SRC_DIR="/home/${SCRIPTUSER}/komodo"
[[ -z ${KOMODO_CONF_DIR+x} ]] && export KOMODO_CONF_DIR="/home/${SCRIPTUSER}/.komodo"
[[ -z ${KOMODO_REPOSITORY+x} ]] && export KOMODO_REPOSITORY='https://github.com/jl777/komodo.git'
[[ -z ${KOMODO_BRANCH+x} ]] && export KOMODO_BRANCH=jl777
[[ -z ${AC_COINLIST+x} ]] && export AC_COINLIST="$(dirname $0)../conf/coinlist"

# More variables
COMMON_ROOT="${HOME}/.common"
COMMON_CONFIG="${COMMON_ROOT}/config"

[[ -d ${COMMON_ROOT} ]] || mkdir ${COMMON_ROOT}
[[ -f ${COMMON_CONFIG} ]] || touch ${COMMON_CONFIG}

# Sync coinlist
rsync -q ${AC_COINLIST} ${COMMON_ROOT}/

function verifyvalue() {
  VARNAME=$1
  VARVALUE=$2
  if [[ ! -z ${VARVALUE+x} ]]; then
    grep -q "${VARVALUE}" ${COMMON_CONFIG} || \
      echo "${VARNAME}=${VARVALUE}" >> ${COMMON_CONFIG}
  fi
}

verifyvalue USERNAME ${SCRIPTUSER}
verifyvalue KOMODO_BRANCH ${KOMODO_BRANCH}
verifyvalue KOMODO_REPOSITORY ${KOMODO_REPOSITORY}
verifyvalue KOMODO_SRC_DIR ${KOMODO_SRC_DIR}
verifyvalue KOMODO_CONF_DIR ${KOMODO_CONF_DIR}

verifyvalue VAR_PROC $(cat /proc/cpuinfo | grep processor | wc -l)
