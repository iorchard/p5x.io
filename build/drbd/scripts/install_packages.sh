#!/bin/bash

set -ex

COMMON_DEPS=(devscripts dkms debhelper build-essential git)
DRBD_DEPS=(linux-headers-cloud-amd64 coccinelle python3-dev)
DRBD_UTILS_DEPS=(bash-completion docbook-xsl flex xsltproc udev)

apt update
apt -y --no-install-recommends install \
	${COMMON_DEPS[@]} ${DRBD_DEPS[@]} ${DRBD_UTILS_DEPS[@]}

# set python in PATH
update-alternatives --install /usr/bin/python python /usr/bin/python3.9 1
