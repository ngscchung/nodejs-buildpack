#!/usr/bin/env bash


echo "=====> Inside pre_compile!!!"

# fail fast
set -e

LP_DIR=`cd $(dirname $0); cd ..; pwd`

function error() {
  echo " !     $*" >&2
  exit 1
}

function topic() {
  echo "-----> $*"
}

function indent() {
  c='s/^/       /'
  case $(uname) in
    Darwin) sed -l "$c";;
    *)      sed -u "$c";;
  esac
}

BUILD_DIR=$1
CACHE_DIR=$2
DEPS_DIR=$3
DEPS_IDX=$4

install_oracle_libraries(){
  echo $HOME
  echo $BUILD_DIR
  #local build_dir=${1:-}
  echo "Installing oracle libraries"
  #mkdir -p $build_dir/oracle
  local oracle_home=$DEPS_DIR/$DEPS_IDX/oracle
  #local oracle_home=$BUILD_DIR/.oracle
  mkdir -p $oracle_home
  #cd $build_dir/oracle
  cd $oracle_home
  # local basic_download_url="http://files.cargosmart.org/python/instantclient-basic-linux.x64-11.2.0.4.0.tar.gz"
  # local sdk_download_url="http://files.cargosmart.org/python/instantclient-sdk-linux.x64-11.2.0.4.0.tar.gz"

  local basic_download_url="http://artifact:8081/artifactory/thirdparty_tools/thirdparty_lib/instantclient-basic-linux.x64-11.2.0.4.0/instantclient-basic-linux.x64-11.2.0.4.0/instantclient-basic-linux.x64-11.2.0.4.0-instantclient-basic-linux.x64-11.2.0.4.0.jar"
  local sdk_download_url="http://artifact:8081/artifactory/thirdparty_tools/thirdparty_lib/instantclient-sdk-linux.x64-11.2.0.4.0/instantclient-sdk-linux.x64-11.2.0.4.0/instantclient-sdk-linux.x64-11.2.0.4.0-instantclient-sdk-linux.x64-11.2.0.4.0.jar"

  curl -k "$basic_download_url" --silent --fail --retry 5 --retry-max-time 15 -o instantclient-basic.tar.gz
  echo "Downloaded [$basic_download_url]"
  curl -k "$sdk_download_url" --silent --fail --retry 5 --retry-max-time 15 -o instantclient-sdk.tar.gz
  echo "Downloaded [$sdk_download_url]"
  
  echo "unzipping libraries"
  tar -xvzf instantclient-basic.tar.gz
  tar -xvzf instantclient-sdk.tar.gz
  
  rm instantclient-basic.tar.gz
  rm instantclient-sdk.tar.gz
  
  mv instantclient_11_2 instantclient
  cd instantclient
  ln -s libclntsh.so.11.1 libclntsh.so
  ln -s libocci.so.11.1 libocci.so
  
  mkdir -p "$DEPS_DIR/$DEPS_IDX/env"
  # prepare env variables for "pip install" use during staging
  # append_profile_d ORACLE_HOME "\$DEPS_DIR/$DEPS_IDX/oracle/instantclient"
  echo $DEPS_DIR/$DEPS_IDX/oracle/instantclient > $DEPS_DIR/$DEPS_IDX/env/ORACLE_HOME
  # append_profile_d LD_RUN_PATH "\$DEPS_DIR/$DEPS_IDX/oracle/instantclient"
  echo $DEPS_DIR/$DEPS_IDX/oracle/instantclient > $DEPS_DIR/$DEPS_IDX/env/LD_RUN_PATH
  echo $DEPS_DIR/$DEPS_IDX/oracle/instantclient > $DEPS_DIR/$DEPS_IDX/env/OCI_LIB_DIR
  echo $DEPS_DIR/$DEPS_IDX/oracle/instantclient/sdk/include > $DEPS_DIR/$DEPS_IDX/env/OCI_INC_DIR

export LD_LIBRARY_PATH="$DEPS_DIR/$DEPS_IDX/oracle/instantclient:$LD_LIBRARY_PATH"
export LD_RUN_PATH="$DEPS_DIR/$DEPS_IDX/oracle/instantclient:$LD_RUN_PATH"
export OCI_LIB_DIR="$DEPS_DIR/$DEPS_IDX/oracle/instantclient"
export OCI_INC_DIR="$DEPS_DIR/$DEPS_IDX/oracle/instantclient/sdk/include"
export ORACLE_HOME="$DEPS_DIR/$DEPS_IDX/oracle/instantclient"

ls -al $OCI_LIB_DIR/libclntsh.so

  # prepare env variables for python runtime use
  # Shell scripts in .profile.d folder are triggered at the start of cf start app
cat <<EOF >$BUILD_DIR/.profile.d/001_oracleclient.sh
export LD_LIBRARY_PATH="\$DEPS_DIR/$DEPS_IDX/oracle/instantclient:\$LD_LIBRARY_PATH"
export LD_RUN_PATH="\$DEPS_DIR/$DEPS_IDX/oracle/instantclient:\$LD_RUN_PATH"
export OCI_LIB_DIR="\$DEPS_DIR/$DEPS_IDX/oracle/instantclient"
export OCI_INC_DIR="\$DEPS_DIR/$DEPS_IDX/oracle/instantclient/sdk/include"
export ORACLE_HOME="\$DEPS_DIR/$DEPS_IDX/oracle/instantclient:\$ORACLE_HOME"
export PATH="\$DEPS_DIR/$DEPS_IDX/oracle/instantclient:\$PATH"
EOF
  echo "Back to $BUILD_DIR.."
  cd $BUILD_DIR 
}

install_oracle_libraries 