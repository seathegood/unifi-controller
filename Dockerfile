ARG UNIFI_CONTROLLER_VERSION=9.4.19

FROM debian:bookworm-slim AS downloader
ARG UNIFI_CONTROLLER_VERSION
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

RUN curl --fail --silent --show-error --location "https://dl.ui.com/unifi/${UNIFI_CONTROLLER_VERSION}/unifi_sysvinit_all.deb" \
      -o "/tmp/unifi-${UNIFI_CONTROLLER_VERSION}.deb"

FROM debian:bookworm-slim
ARG UNIFI_CONTROLLER_VERSION
ARG BUILD_DATE
ARG VCS_REF
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV DEBIAN_FRONTEND=noninteractive

LABEL \
    org.opencontainers.image.title="Unifi Controller" \
    org.opencontainers.image.description="Unifi Controller without a local MongoDB instance" \
    org.opencontainers.image.url="https://github.com/seathegood/unifi-controller" \
    org.opencontainers.image.source="https://github.com/seathegood/unifi-controller" \
    org.opencontainers.image.version="${UNIFI_CONTROLLER_VERSION}" \
    org.opencontainers.image.created="${BUILD_DATE}" \
    org.opencontainers.image.revision="${VCS_REF}" \
    org.opencontainers.image.vendor="Sea the Good, LLC" \
    org.opencontainers.image.licenses="MIT"

ENV \
    BIND_PRIV=false \
    DEBUG=false \
    JVM_EXTRA_OPTS= \
    JVM_INIT_HEAP_SIZE= \
    JVM_MAX_HEAP_SIZE=1024M \
    PGID=999 \
    PUID=999 \
    RUN_CHOWN=true \
    RUNAS_UID0=false

COPY entrypoint.sh entrypoint-functions.sh healthcheck.sh /usr/local/bin/
COPY system.properties.default /usr/lib/unifi/

RUN set -x \
    && groupadd -r unifi -g $PGID \
    && useradd --no-log-init -r -u $PUID -g $PGID unifi

RUN mkdir -p /usr/lib/unifi/data /usr/lib/unifi/logs /usr/lib/unifi/run /usr/lib/unifi/cert \
    && chown -R unifi:unifi /usr/lib/unifi

COPY --from=downloader "/tmp/unifi-${UNIFI_CONTROLLER_VERSION}.deb" /tmp/unifi.deb

RUN set -x \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        binutils \
        ca-certificates \
        curl \
        gosu \
        libcap2 \
        libcap2-bin \
        libpsl5 \
        logrotate \
        openjdk-17-jre-headless \
        openssl \
        procps \
        publicsuffix \
        wget \
    && dpkg-deb --info /tmp/unifi.deb > /dev/null \
    && test -n "$(dpkg-deb --field /tmp/unifi.deb Package)" \
    && dpkg --force-all -i /tmp/unifi.deb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/log/*

WORKDIR /usr/lib/unifi

EXPOSE 3478/udp 5514/udp 8080/tcp 8443/tcp 8880/tcp 8843/tcp 6789/tcp 27117/tcp 10001/udp 1900/udp 123/udp

VOLUME ["/usr/lib/unifi/cert", "/usr/lib/unifi/data", "/usr/lib/unifi/logs"]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["unifi"]
