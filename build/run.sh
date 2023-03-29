#!/bin/bash

CUR_DIR=$( dirname "$(readlink -f "$0")" )

function _check() {
  if [ -z "${TARGET}" ]; then
	echo "Error: target not found: ${TARGET}" 1>&2
	echo
	USAGE
	exit 1
  fi
  if [ ! -r ${CUR_DIR}/.env ]; then
	echo "Error: env file not found: ${CUR_DIR}/.env" 1>&2
	echo
	USAGE
	exit 1
  fi
}
function build() {
  _check
  pushd ${TARGET}
    mkdir -p output
    docker build -t ${TARGET}-builder .
  popd
  docker run -v $(pwd)/output:/output --rm \
    --env="DEBIAN_FRONTEND=noninteractive" \
    --env-file=${CUR_DIR}/.env \
    ${TARGET}-builder
}
function run() {
  _check
  pushd ${TARGET}
    mkdir -p output
    docker build -t ${TARGET}-builder .
  popd
  docker run -it -v $(pwd)/output:/output --rm \
    --env="DEBIAN_FRONTEND=noninteractive" \
    --env-file=${CUR_DIR}/.env \
    --entrypoint=/bin/bash \
    ${TARGET}-builder
}
function USAGE() {
  echo "USAGE: $0 [-h|-b|-r] <target>" 1>&2
  echo
  echo " -h --help                  Display this help message."
  echo " -b --build <target>        Build the target."
  echo " -r --run <target>          Run and go into the container"
  echo
  echo "Target"
  echo "------"
  echo " drbd                   build drbd packages."
  echo " linstor                build linstor packages."
  echo 
  echo "ex) $0 --build drbd"
  echo
}
if [ $# -lt 1 ]; then
  USAGE
  exit 1
fi

OPT=$1
shift
TARGET=$1
while true
do
  case "$OPT" in
    -h | --help)
      USAGE
      exit 0
      ;;
    -b | --build)
      build
      break
      ;;
    -r | --run)
      run
      break
      ;;
    *)
      echo Error: unknown option: "$OPT" 1>&2
      echo 
      USAGE
  esac
done
