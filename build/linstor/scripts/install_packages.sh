#!/bin/bash

set -ex

COMMON_DEPS=(devscripts debhelper build-essential git)
LINSTOR_DEPS=(default-jdk-headless gradle python3-all)

apt update
apt -y --no-install-recommends install \
	${COMMON_DEPS[@]} ${LINSTOR_DEPS[@]}

# set python in PATH
update-alternatives --install /usr/bin/python python /usr/bin/python3.9 1
