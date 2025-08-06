# shellcheck shell=bash
#!/usr/bin/env bash

# healthcheck.sh script for Unifi running within a container
# License: MIT
SCRIPT_VERSION="1.1"
# Last updated date: 2025-08-06

set -Eeuo pipefail

if [ "${DEBUG}" == 'true' ]; then
    set -x
fi

BASEDIR="/usr/lib/unifi"
DATADIR="${BASEDIR}/data"

if [[ -f "${DATADIR}/system.properties" ]]; then
    api_port=$(grep -E '^\s*unifi\.http\.port=' "${DATADIR}/system.properties" | sed -n 's/.*=//p')
fi
api_port="${api_port:-8080}"

max_wait=10
for i in $(seq 1 "${max_wait}"); do
    http_code=$(curl -s --connect-timeout 1 -o /dev/null -w "%{http_code}" "http://localhost:${api_port}/status")
    if [[ "${http_code}" == "200" ]]; then
        echo "Unifi API http status code ${http_code}: OK"
        exit 0
    fi
    sleep 1
done

echo "Error: Unifi API http status code ${http_code}, expecting 200" >&2
exit 1