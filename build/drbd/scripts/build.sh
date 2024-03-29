#!/bin/bash

set -ex

# install prerequisite debian packages
$(dirname $0)/install_packages.sh

mkdir -p ${OUTPUT_DIR}/drbd{-${DRBD_VER},-utils-${DRBD_UTILS_VER}}

# Clone drbd source
git clone -b drbd-${DRBD_VER} https://github.com/LINBIT/drbd.git \
  ${WORKSPACE}/drbd
pushd ${WORKSPACE}/drbd
  make km-deb
popd 
mv ${WORKSPACE}/*.deb ${OUTPUT_DIR}/drbd-${DRBD_VER}/

# Clone drbd-utils source
git clone -b v${DRBD_UTILS_VER} https://github.com/LINBIT/drbd-utils.git \
  ${WORKSPACE}/drbd-utils
pushd ${WORKSPACE}/drbd-utils
  sed -i "s/--with-xen/--without-manual/" debian/rules
  ./autogen.sh
  debuild --no-tgz-check -us -uc
popd
mv ${WORKSPACE}/drbd*.deb ${OUTPUT_DIR}/drbd-utils-${DRBD_UTILS_VER}/

pushd ${OUTPUT_DIR}
  tar czf drbd-${DRBD_VER}-debs.tar.gz drbd-${DRBD_VER}
  tar czf drbd-utils-${DRBD_UTILS_VER}-debs.tar.gz drbd-utils-${DRBD_UTILS_VER}
popd
