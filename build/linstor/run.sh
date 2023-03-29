#!/bin/bash

CUR_DIR=$( dirname "$(readlink -f "$0")" )
. ${CUR_DIR}/../.env

mkdir -p output

docker build -t linstor-builder .
docker run -v $(pwd)/output:/output --rm \
  --env="DEBIAN_FRONTEND=noninteractive" \
  --env="LINSTOR_VER=${LINSTOR_VER}" \
  linstor-builder
