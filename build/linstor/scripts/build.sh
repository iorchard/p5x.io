#!/bin/bash

set -ex
mkdir -p ${OUTPUT_DIR}/linstor-${LINSTOR_VER} \
         ${OUTPUT_DIR}/linstor-client-${LINSTOR_CLIENT_VER}

# install prerequisite debian packages
$(dirname $0)/install_packages.sh

# build linstor-server
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
mv /*.deb ${OUTPUT_DIR}/linstor-${LINSTOR_VER}/
pushd ${OUTPUT_DIR}
  tar cvzf linstor-${LINSTOR_VER}-debs.tar.gz linstor-${LINSTOR_VER}
popd

# build linstor-client
git clone --recurse-submodules -b v${LINSTOR_CLIENT_VER} \
  https://github.com/LINBIT/linstor-api-py \
  ${WORKSPACE}/linstor-api-py
pushd ${WORKSPACE}/linstor-api-py
  make debrelease
  mv ./dist/python-linstor-${LINSTOR_CLIENT_VER}.tar.gz \
    /python-linstor_${LINSTOR_CLIENT_VER}.orig.tar.gz
popd
tar -C / -xzf /python-linstor_${LINSTOR_CLIENT_VER}.orig.tar.gz
pushd /python-linstor-${LINSTOR_CLIENT_VER}
  debuild -us -uc
popd
rm -fr ${WORKSPACE}/linstor-api-py
mv /python-linstor-${LINSTOR_CLIENT_VER} ${WORKSPACE}/linstor-api-py
git clone -b v${LINSTOR_CLIENT_VER} https://github.com/LINBIT/linstor-client \
  ${WORKSPACE}/linstor-client
pushd ${WORKSPACE}/linstor-client
  make debrelease
  mv ./dist/linstor-client-${LINSTOR_CLIENT_VER}.tar.gz /linstor-client_${LINSTOR_CLIENT_VER}.orig.tar.gz
popd
tar -C / -xzf /linstor-client_${LINSTOR_CLIENT_VER}.orig.tar.gz
pushd /linstor-client-${LINSTOR_CLIENT_VER}
  debuild -us -uc
popd
mv /*.deb ${OUTPUT_DIR}/linstor-client-${LINSTOR_CLIENT_VER}/
pushd ${OUTPUT_DIR}
  tar cvzf linstor-client-${LINSTOR_CLIENT_VER}-debs.tar.gz \
    linstor-client-${LINSTOR_CLIENT_VER}
popd
