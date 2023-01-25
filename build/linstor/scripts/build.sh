#!/bin/bash

set -ex

. var.sh

# strip v off of LINSTOR_VER
STRIP_VER="${LINSTOR_VER//v}"

# install prerequisite debian packages
$(dirname $0)/install_packages.sh

# Clone source
git clone -b ${LINSTOR_VER} https://github.com/LINBIT/linstor-server \
	${WORKSPACE}/linstor-server
pushd ${WORKSPACE}/linstor-server
    make debrelease
	mv linstor-server-${STRIP_VER}.tar.gz \
		/linstor-server_${STRIP_VER}.orig.tar.gz
	tar -C / -xvf /linstor-server_${STRIP_VER}.orig.tar.gz
popd 

pushd /linstor-server-${STRIP_VER}
	debuild -us -uc
popd
mv /*.deb /output/
