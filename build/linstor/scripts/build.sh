#!/bin/bash

set -ex

. var.sh

# install prerequisite debian packages
$(dirname $0)/install_packages.sh

# Clone source
git clone -b v${LINSTOR_VER} https://github.com/LINBIT/linstor-server \
	${WORKSPACE}/linstor-server
pushd ${WORKSPACE}/linstor-server
    make debrelease
	mv linstor-server-${LINSTOR_VER}.tar.gz \
		/linstor-server_${LINSTOR_VER}.orig.tar.gz
	tar -C / -xvf /linstor-server_${LINSTOR_VER}.orig.tar.gz
popd 

pushd /linstor-server-${LINSTOR_VER}
	debuild -us -uc
popd
mv /*.deb /output/
