#!/usr/bin/env bash
# Installing Komodo on Ubuntu 16.x LTS
set -e

echo -e "## Komodod Daemon setup starting ##\n"

# source profile
source /etc/profile

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
  -O ${HOME}/.zcash-params/sprout-proving.key.dl
time ./zcutil/fetch-params.sh
time ./zcutil/build.sh -j${VAR_PROC}
echo -e "===> Finished building Komodo Daemon"

# Symlink binaries
sudo ln -sf ${HOME}/komodo/src/komodo-cli /usr/local/bin/
sudo ln -sf ${HOME}/komodo/src/komodod /usr/local/bin/
sudo chmod +x /usr/local/bin/komodo-cli
sudo chmod +x /usr/local/bin/komodod

echo -e "## Komodod Daemon has been configured ##\n"

# Functions
function komodod_run () {
  while [[ $# -gt 0 ]]; do
  	key="$1"
  	case $key in
      -pubkey)
        export komodod_run_PUBKEY="-pubkey=${2}"
        shift
      ;;
      -seq)
        export komodod_run_SEQUENCE="${2}"
        shift
      ;;
      -daemon)
        export komodod_run_DAEMON="-daemon"
      ;;
      -gen)
        export komodod_run_GEN="-gen"
      ;;
      *)
        echo "WARNING: Unknown option $key" >&2
        exit 1
      ;;
    esac
    shift
  done
  ${KOMODO_SRC_DIR}/src/komodod -ac_name=TXSCL${komodod_run_SEQUENCE} -ac_supply=100000000 -addnode=54.36.176.84 \
    $komodod_run_DAEMON $komodod_run_GEN $komodod_run_PUBKEY
}


if [[ -f ${KOMODO_SRC_DIR}/src/komodod ]]; then

  # Run it for `TXSCL` first and then for the rest
  #komodod_run -daemon

  for (( i==${AC_START}; i<${AC_END}; i++ )); do
    komodod_run -seq $i -daemon
    # This will create ${HOME}/.komodo/TXSCL${i}/TXSCL${i}.conf

    DAEMONCONF="${HOME}/.komodo/TXSCL${i}/TXSCL${i}.conf"
    RPCUSER=$(grep 'rpcuser' $DAEMONCONF | cut -d'=' -f2)
    RPCPASSWORD=$(grep 'rpcpassword' $DAEMONCONF | cut -d'=' -f2)
    RPCPORT=$(grep 'rpcport' $DAEMONCONF | cut -d'=' -f2)

  done
fi
