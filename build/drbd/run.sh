#!/bin/bash

CUR_DIR=$( dirname "$(readlink -f "$0")" )
. ${CUR_DIR}/../.env

mkdir -p output
docker build -t drbd-builder .
docker run -v $(pwd)/output:/output --rm \
  --env="DEBIAN_FRONTEND=noninteractive" \
  --env="DRBD_VER=${DRBD_VER}" \
  --env="DRBD_UTILS_VER=${DRBD_UTILS_VER}" \
  drbd-builder
