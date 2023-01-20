ARG	FROM=debian:bullseye
FROM ${FROM}

ENV WORKSPACE="/opt/drbd-build"
ENV OUTPUT_DIR="/output"
WORKDIR ${WORKSPACE}/scripts

COPY scripts ${WORKSPACE}/scripts
VOLUME ["${OUTPUT_DIR}"]

ENTRYPOINT ["/opt/drbd-build/scripts/build.sh"]
