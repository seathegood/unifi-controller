#!/usr/bin/env bash
#================================================================
# TITLE: Entrypoint Functions
# AUTHOR: Michael Ross
# LICENSE: MIT
#
# DESCRIPTION:
#   Functions used in entrypoint.sh
#
#  HISTORY
#   2015/03/01 : Initial version copied from
#   2024/01/27 : Added -L flag to chown command so that symbolic
#                symbolic links are properly traversed into the
#                data, logs, and run directories
# 
#================================================================
ENTRYPOINT_FUNCTIONS_VERSION="1.1"

f_bindpriv() {
    JAVABIN=$(readlink -f /usr/bin/java)
    if [ "${BIND_PRIV}" == 'true' ] && [ "${RUNAS_UID0}" == 'false' ]; then
        f_log "INFO - Support binding ports <1024 'setcap 'cap_net_bind_service=+ep' ${JAVABIN}'"
        if setcap 'cap_net_bind_service=+ep' ${JAVABIN}; then
            sleep 1
        else
            f_log "ERROR - BIND_PRIV=true and 'setcap' command failed on this host"
            f_log "ERROR - If binding ports <1024 required on this host, use RUNAS_UID0=true instead"
            f_log "ERROR - Container run state is invalid, exiting..."
            exit 1;
        fi
    fi
}

f_chown() {
    if [ "${RUN_CHOWN}" == 'false' ] && [ "${RUNAS_UID0}" == 'false' ]; then
        if [ ! "$(stat -c %u ${BASEDIR})" = "${PUID}" ] || [ ! "$(stat -c %u ${CERTDIR})" = "${PUID}" ] \
        || [ ! "$(stat -c %u ${DATADIR})" = "${PUID}" ] || [ ! "$(stat -c %u ${LOGDIR})" = "${PUID}" ] \
        || [ ! "$(stat -c %u ${RUNDIR})" = "${PUID}" ]; then
            f_log "WARN - Configured PUID doesn't match owner of a required directory. Ignoring RUN_CHOWN=false"
            f_log "INFO - Ensuring permissions are correct before continuing - 'chown -R -L unifi:unifi ${BASEDIR}'"
            f_log "INFO - Running recursive 'chown' can be slow. Be patient."
            chown -R -L unifi:unifi ${BASEDIR}
        else
            f_log "INFO - Explicitly setting owner on '${LOGDIR}/*.log' and '${DATADIR}/system.properties'"
            chown unifi:unifi ${DATADIR}/system.properties
            chown unifi:unifi ${LOGDIR}/*.log
            f_log "INFO - RUN_CHOWN=false - Not running 'chown -R -L unifi:unifi ${BASEDIR}', assume subdir/file permissions OK"
        fi
    elif [ "${RUNAS_UID0}" == 'true' ]; then
        f_log "INFO - RUNAS_UID0=true - Not running 'chown -R -L unifi:unifi ${BASEDIR}', no need to worry about permissions."
    else
        f_log "INFO - Ensuring permissions are correct before continuing - 'chown -R unifi:unifi ${BASEDIR}'"
        f_log "INFO - Running recursive 'chown' can be slow. Be patient."
        chown -R -L unifi:unifi ${BASEDIR}
    fi
}

f_giduid() {
    UNIFI_GID=${UNIFI_GID:-}
    UNIFI_UID=${UNIFI_UID:-}
    if [ ! -z "${UNIFI_GID}" ]; then
        f_log "INFO - UNIFI_GID is set. Please use the updated PGID variable. Automatically converting to PGID."
        PGID=${UNIFI_GID}
    fi
    if [ ! -z "${UNIFI_UID}" ]; then
        f_log "INFO - UNIFI_UID is set. Please use the updated PUID variable. Automatically converting to PUID."
        PUID=${UNIFI_UID}
    fi
    if [ "$(id unifi -g)" != "${PGID}" ] || [ "$(id unifi -u)" != "${PUID}" ]; then
        f_log "INFO - Setting custom unifi GID/UID: GID=${PGID}, UID=${PUID}"
        groupmod -o -g ${PGID} unifi
        usermod -o -u ${PUID} unifi
    else
        f_log "INFO - GID/UID for unifi are unchanged: GID=${PGID}, UID=${PUID}"
    fi
}

f_log() {
    echo "$(date +"[%Y-%m-%d %T,%3N]") <entrypoint> $*" | tee -a ${BASEDIR}/logs/server.log
}

f_mongo() {
    DB_MONGO_LOCAL=${DB_MONGO_LOCAL:-}
    DB_MONGO_URI=${DB_MONGO_URI:-}
    STATDB_MONGO_URI=${STATDB_MONGO_URI:-}
    UNIFI_DB_NAME=${UNIFI_DB_NAME:-}
    if [ -z "${DB_MONGO_LOCAL}" ] || [ -z "${DB_MONGO_URI}" ] || [ -z "${STATDB_MONGO_URI}" ] \
    || [ -z "${UNIFI_DB_NAME}" ]; then
        f_log "ERROR - ======================================================================"
        f_log "ERROR - One or more of: 'DB_MONGO_LOCAL', 'DB_MONGO_URI', 'STATDB_MONGO_URI', or 'UNIFI_DB_NAME' is unset."
        f_log "ERROR - This container cannot run without a properly configured mongo environment."
        f_log "ERROR - ======================================================================"
        f_log "ERROR - Container run environment is invalid, exiting..."
        exit 1;
    fi
}

f_ssl() {
    if [ -e ${CERTDIR}/privkey.pem ] && [ -e ${CERTDIR}/fullchain.pem ]; then
        if `/usr/bin/sha256sum -c ${CERTDIR}/unificert.sha256 &> /dev/null`; then
            f_log "INFO - SSL: certificate files unchanged, continuing with unifi startup"
            f_log "INFO - SSL: To force rerun import process: delete '${CERTDIR}/unificert.sha256' and restart the container"
        else
            if [ ! -e ${DATADIR}/keystore ]; then
                f_log "WARN - SSL: keystore does not exist, generating it with Java keytool"
                keytool -genkey -keyalg RSA -alias unifi -keystore ${DATADIR}/keystore \
                -storepass aircontrolenterprise -keypass aircontrolenterprise -validity 1825 \
                -keysize 4096 -dname "cn=unifi"
            else
                f_log "INFO - SSL: backup existing '${DATADIR}/keystore' to '${DATADIR}/keystore-$(date +%s)'"
                cp ${DATADIR}/keystore ${DATADIR}/keystore-$(date +%s)
            fi
            f_log "INFO - SSL: custom certificate keystore update"
            f_log "INFO - SSL: openssl combine custom private key and certificate chain into temporary PKCS12 file"
            openssl pkcs12 -export \
                -inkey ${CERTDIR}/privkey.pem \
                -in ${CERTDIR}/fullchain.pem \
                -out ${CERTDIR}/certtemp.p12 \
                -name unifi -password pass:temppass
            f_log "INFO - SSL: Java keytool import PKCS12 '${CERTDIR}/certtemp.p12' file into '${DATADIR}/keystore'"
            keytool -importkeystore -deststorepass aircontrolenterprise \
             -destkeypass aircontrolenterprise -destkeystore ${DATADIR}/keystore \
             -srckeystore ${CERTDIR}/certtemp.p12 -srcstoretype PKCS12 \
             -srcstorepass temppass -alias unifi -noprompt
            f_log "INFO - SSL: Removing temporary PKCS12 file"
            rm ${CERTDIR}/certtemp.p12
            f_log "INFO - SSL: Store SHA256 hash of private key and certificate file"
            /usr/bin/sha256sum ${CERTDIR}/privkey.pem > ${CERTDIR}/unificert.sha256
            /usr/bin/sha256sum ${CERTDIR}/fullchain.pem >> ${CERTDIR}/unificert.sha256
            f_log "INFO - SSL: completed update of custom certificate in '${DATADIR}/keystore'"
            f_log "INFO - SSL: Check above ***here*** for errors if your custom certificate import isn't working"
            f_log "INFO - SSL: To force rerun import process: delete '${CERTDIR}/unificert.sha256' and restart the container"
        fi
    else
        [ -f ${CERTDIR}/privkey.pem ] || f_log "WARN - Custom SSL: missing '${CERTDIR}/privkey.pem'"
        [ -f ${CERTDIR}/fullchain.pem ] || f_log "WARN - Custom SSL: missing '${CERTDIR}/fullchain.pem'"
        f_log "WARN - Custom SSL: certificate import was NOT performed"
    fi
}

f_sysprop() {
    # Unifi system.properties container mode setup (echo logs to STDOUT, support ENV read)
    f_log "INFO - Checking system.properties setup for container"
    if [ ! -e ${DATADIR}/system.properties ]; then
        f_log "INFO - '${DATADIR}/system.properties' doesn't exist, copying from '${BASEDIR}/system.properties.default'"
        cp ${BASEDIR}/system.properties.default ${DATADIR}/system.properties
    else
        f_log "INFO - Existing '${DATADIR}/system.properties' found, ensuring container mode options are enabled"
        if ! grep -q "unifi.logStdout" "${DATADIR}/system.properties"; then
            echo "unifi.logStdout=true" >> ${DATADIR}/system.properties
        else
            sed -i '/unifi.logStdout/c\unifi.logStdout=true' ${DATADIR}/system.properties
        fi

        if ! grep -q "unifi.config.readEnv" "${DATADIR}/system.properties"; then
            echo "unifi.config.readEnv=true" >> ${DATADIR}/system.properties
        else
            sed -i '/unifi.config.readEnv/c\unifi.config.readEnv=true' ${DATADIR}/system.properties
        fi
    fi
}