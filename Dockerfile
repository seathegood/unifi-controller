# base image
FROM debian:bullseye

# Local Arguements
ARG UNIFI_CONTROLLER_VERSION

# image labels using OPI spec
LABEL \
	org.opencontainers.image.vendor="Sea the Good, LLC" \
	org.opencontainers.image.url="https://github.com/seathegood/unifi" \
	org.opencontainers.image.title="Unifi Controller" \
	org.opencontainers.image.description="Unifi Controller without a local MongoDB instance" \
	org.opencontainers.image.version=${UNIFI_CONTROLLER_VERSION} \
	org.opencontainers.image.source="https://github.com/seathegood/unifi-controller" \
	org.opencontainers.image.licenses="MIT"

# build environment variables
ENV \
	BIND_PRIV=false \
	DEBIAN_FRONTEND=noninteractive \
	DEBUG=false \
	JVM_EXTRA_OPTS= \
	JVM_INIT_HEAP_SIZE= \
	JVM_MAX_HEAP_SIZE=1024M \
	PGID=999 \
	PUID=999 \
	RUN_CHOWN=true \
	RUNAS_UID0=false

# copy in logical defaults for unifi
COPY entrypoint.sh entrypoint-functions.sh healthcheck.sh /usr/local/bin/
COPY system.properties.default /usr/lib/unifi/

# setup security context for the unifi user
RUN set -x \
	&& groupadd -r unifi -g $PGID \
	&& useradd --no-log-init -r -u $PUID -g $PGID unifi

# install unifi dependencies
RUN set -x \
    && fetchDeps=' \
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
    ' \
    && apt-get update \
    && apt-get install -y --no-install-recommends $fetchDeps \
    && apt-get autoremove --purge \
    && apt-get clean autoclean 

# download and install the unifi controller
WORKDIR /usr/lib/unifi
RUN curl --show-error --silent --location https://dl.ui.com/unifi/${UNIFI_CONTROLLER_VERSION}/unifi_sysvinit_all.deb -o /tmp/unifi-${UNIFI_CONTROLLER_VERSION}.deb \
    && dpkg --force-all -i /tmp/unifi-${UNIFI_CONTROLLER_VERSION}.deb \
    && mkdir -p /usr/lib/unifi/data /usr/lib/unifi/logs /usr/lib/unifi/run /usr/lib/unifi/cert \
    && chown -R unifi:unifi /usr/lib/unifi \
    && ls -ld /usr/lib/unifi/* \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/log/*


EXPOSE 3478/udp 5514/udp 8080/tcp 8443/tcp 8880/tcp 8843/tcp 6789/tcp 27117/tcp 10001/udp 1900/udp 123/udp 

VOLUME ["/usr/lib/unifi/cert", "/usr/lib/unifi/data", "/usr/lib/unifi/logs"]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["unifi"]
