ARG	FROM=debian:bullseye
FROM ${FROM}

ENV WORKSPACE="/opt/linstor-build"
ENV OUTPUT_DIR="/output"
WORKDIR ${WORKSPACE}/scripts

COPY scripts ${WORKSPACE}/scripts
VOLUME ["${OUTPUT_DIR}"]

ENTRYPOINT ["/opt/linstor-build/scripts/build.sh"]
