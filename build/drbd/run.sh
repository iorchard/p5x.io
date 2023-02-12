#!/bin/bash
DRBD_VER=${1:-9.2.2}
DRBD_UTILS_VER=${2:-9.23.0}

mkdir -p output
docker build -t drbd-builder .
docker run -v $(pwd)/output:/output --rm \
  --env="DEBIAN_FRONTEND=noninteractive" \
  --env="DRBD_VER=${DRBD_VER}" \
  --env="DRBD_UTILS_VER=${DRBD_UTILS_VER}" \
  drbd-builder
