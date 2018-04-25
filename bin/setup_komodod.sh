#!/usr/bin/env bash
# Installing Komodo on Ubuntu 16.x LTS
set -e

echo -e "## Komodod Daemon setup starting ##\n"

# source profile
source /etc/profile
[[ -f ${HOME}/.common/config ]] && source ${HOME}/.common/config

#### Install pre-requisites:
sudo -s bash <<EOF
export DEBIAN_FRONTEND=noninteractive;
apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -qq \
  install build-essential pkg-config libc6-dev m4 g++-multilib \
  autoconf libtool ncurses-dev unzip git python zlib1g-dev wget bsdmainutils \
  automake libboost-all-dev libssl-dev libprotobuf-dev protobuf-compiler \
  libqt4-dev libqrencode-dev libdb++-dev ntp ntpdate vim \
  software-properties-common curl libcurl4-gnutls-dev cmake clang \
  libgmp3-dev
EOF

[[ -d ${HOME}/.komodo/bin ]] || mkdir -p ${HOME}/.komodo/bin


if [[ ! $DONT_BUILD ]]; then

  #### Install nanomsg
  sudo chown `whoami`. /usr/local/src
  cd /usr/local/src
  [[ -d nanomsg ]] || git clone https://github.com/nanomsg/nanomsg
  cd nanomsg
  cmake .
  time make
  time sudo make install
  time sudo ldconfig

  ### Installing
  cd ${HOME}
  if [[ -d ${HOME}/komodo ]]; then
    cd ${HOME}/komodo
    git checkout ${KOMODO_BRANCH}; git reset --hard; git pull --rebase
  else
    git clone ${KOMODO_REPOSITORY} -b ${KOMODO_BRANCH}
    cd ${HOME}/komodo
  fi

  echo -e "===> Build Komodo Daemon"
  [[ -d "${HOME}/.zcash-params" ]] || mkdir "${HOME}/.zcash-params"
  time wget -c https://gitlab.com/zcashcommunity/params/raw/master/sprout-proving.key \
    -O ${HOME}/.zcash-params/sprout-proving.key
  time ./zcutil/fetch-params.sh
  time ./zcutil/build.sh -j${VAR_PROC}
  echo -e "===> Finished building Komodo Daemon"

fi

# Symlink binaries
sudo ln -sf ${HOME}/komodo/src/komodo-cli /usr/local/bin/
sudo ln -sf ${HOME}/komodo/src/komodod /usr/local/bin/
sudo chmod +x /usr/local/bin/komodo-cli
sudo chmod +x /usr/local/bin/komodod

echo -e "## Komodod Daemon has been configured ##\n"

# Create files to stop, start and check status
sed -e "s|<KOMODO_SRC_DIR>|${KOMODO_SRC_DIR}|g" \
  -e "s|<AC_COINLIST>|${AC_COINLIST}|g" \
  $(dirname $0)/.komodo/bin/ac_start_all.sh > ${HOME}/.komodo/bin/ac_start_all.sh

sed -e "s|<KOMODO_SRC_DIR>|${KOMODO_SRC_DIR}|g" \
  -e "s|<AC_COINLIST>|${AC_COINLIST}|g" \
  $(dirname $0)/.komodo/bin/ac_stop_all.sh > ${HOME}/.komodo/bin/ac_stop_all.sh

sed -e "s|<KOMODO_SRC_DIR>|${KOMODO_SRC_DIR}|g" \
  -e "s|<AC_COINLIST>|${AC_COINLIST}|g" \
  $(dirname $0)/.komodo/bin/ac_status_all.sh > ${HOME}/.komodo/bin/ac_status_all.sh

sed -e "s|<AC_COINLIST>|${AC_COINLIST}|g" \
  $(dirname $0)/.komodo/bin/ac_purge_all.sh > ${HOME}/.komodo/bin/ac_purge_all.sh

# Permissions and ownership
chmod +x ${HOME}/.komodo/bin/*
