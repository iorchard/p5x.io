#!/bin/bash

set -ex

. var.sh

# install prerequisite debian packages
$(dirname $0)/install_packages.sh

# Clone drbd source
git clone -b ${DRBD_VER} https://github.com/LINBIT/drbd.git ${WORKSPACE}/drbd
pushd ${WORKSPACE}/drbd
    make
	cd drbd
    tar cvzf ${OUTPUT_DIR}/drbd_modules.tar.gz *.ko
popd 

# Clone drbd-utils source
git clone -b ${DRBD_UTILS_VER} https://github.com/LINBIT/drbd-utils.git ${WORKSPACE}/drbd-utils
pushd ${WORKSPACE}/drbd-utils
    sed -i "s/--with-xen/--without-manual/" debian/rules
	./autogen.sh
	debuild --no-tgz-check -us -uc
popd
mv ${WORKSPACE}/drbd-utils*.deb /output/
