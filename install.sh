#!/bin/sh
set -e

# Usage:
#   curl ... | ENV_VAR=... sh -
#       or
#   ENV_VAR=... ./install.sh
#
# Example:
#   Installing a server without traefik:
#     curl ... | INSTALL_IEDGE_EXEC="--disable=traefik" sh -
#   Installing an agent to point at a server:
#     curl ... | IEDGE_TOKEN=xxx IEDGE_URL=https://server-url:6443 sh -
#
# Environment variables:
#   - IEDGE_*
#     Environment variables which begin with IEDGE_ will be preserved for the
#     systemd service to use. Setting IEDGE_URL without explicitly setting
#     a systemd exec command will default the command to "agent", and we
#     enforce that IEDGE_TOKEN or IEDGE_CLUSTER_SECRET is also set.
#
#   - INSTALL_IEDGE_SKIP_DOWNLOAD
#     If set to true will not download iedge hash or binary.
#
#   - INSTALL_IEDGE_SYMLINK
#     If set to 'skip' will not create symlinks, 'force' will overwrite,
#     default will symlink if command does not exist in path.
#
#   - INSTALL_IEDGE_SKIP_ENABLE
#     If set to true will not enable or start iedge service.
#
#   - INSTALL_IEDGE_SKIP_START
#     If set to true will not start iedge service.
#
#   - INSTALL_IEDGE_VERSION
#     Version of iedge to download from github. Will attempt to download from the
#     stable channel if not specified.
#
#   - INSTALL_IEDGE_COMMIT
#     Commit of iedge to download from temporary cloud storage.
#     * (for developer & QA use)
#
#   - INSTALL_IEDGE_BIN_DIR
#     Directory to install iedge binary, links, and uninstall script to, or use
#     /usr/local/bin as the default
#
#   - INSTALL_IEDGE_BIN_DIR_READ_ONLY
#     If set to true will not write files to INSTALL_IEDGE_BIN_DIR, forces
#     setting INSTALL_IEDGE_SKIP_DOWNLOAD=true
#
#   - INSTALL_IEDGE_SYSTEMD_DIR
#     Directory to install systemd service and environment files to, or use
#     /etc/systemd/system as the default
#
#   - INSTALL_IEDGE_EXEC or script arguments
#     Command with flags to use for launching iedge in the systemd service, if
#     the command is not specified will default to "agent" if IEDGE_URL is set
#     or "server" if not. The final systemd command resolves to a combination
#     of EXEC and script args ($@).
#
#     The following commands result in the same behavior:
#       curl ... | INSTALL_IEDGE_EXEC="--disable=traefik" sh -s -
#       curl ... | INSTALL_IEDGE_EXEC="server --disable=traefik" sh -s -
#       curl ... | INSTALL_IEDGE_EXEC="server" sh -s - --disable=traefik
#       curl ... | sh -s - server --disable=traefik
#       curl ... | sh -s - --disable=traefik
#
#   - INSTALL_IEDGE_NAME
#     Name of systemd service to create, will default from the iedge exec command
#     if not specified. If specified the name will be prefixed with 'iedge-'.
#
#   - INSTALL_IEDGE_TYPE
#     Type of systemd service to create, will default from the iedge exec command
#     if not specified.
#
#   - INSTALL_IEDGE_SELINUX_WARN
#     If set to true will continue if iedge-selinux policy is not found.
#
#   - INSTALL_IEDGE_SKIP_SELINUX_RPM
#     If set to true will skip automatic installation of the iedge RPM.
#
#   - INSTALL_IEDGE_CHANNEL_URL
#     Channel URL for fetching iedge download URL.
#     Defaults to 'https://update.iedge.io/v1-release/channels'.
#
#   - INSTALL_IEDGE_CHANNEL
#     Channel to use for fetching iedge download URL.
#     Defaults to 'stable'.

GITHUB_URL=https://github.com/Edge-IVIEW/iEdge/releases/
DOWNLOADER=

# --- helper functions for logs ---
info()
{
    echo '[INFO] ' "$@"
}
warn()
{
    echo '[WARN] ' "$@" >&2
}
fatal()
{
    echo '[ERROR] ' "$@" >&2
    exit 1
}

# --- fatal if no systemd or openrc ---
verify_system() {
    # if [ -x /sbin/openrc-run ]; then
    #     HAS_OPENRC=true
    #     return
    # fi
    if [ -d /run/systemd ]; then
        HAS_SYSTEMD=true
        return
    fi
    fatal 'Can not find systemd  to use as a process supervisor for iedge'
}

# --- add quotes to command arguments ---
quote() {
    for arg in "$@"; do
        printf '%s\n' "$arg" | sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/'/"
    done
}

# --- add indentation and trailing slash to quoted args ---
quote_indent() {
    printf ' \\\n'
    for arg in "$@"; do
        printf '\t%s \\\n' "$(quote "$arg")"
    done
}

# --- escape most punctuation characters, except quotes, forward slash, and space ---
escape() {
    printf '%s' "$@" | sed -e 's/\([][!#$%&()*;<=>?\_`{|}]\)/\\\1/g;'
}

# --- escape double quotes ---
escape_dq() {
    printf '%s' "$@" | sed -e 's/"/\\"/g'
}

# --- ensures $IEDGE_URL is empty or begins with https://, exiting fatally otherwise ---
verify_IEDGE_url() {
    case "${IEDGE_URL}" in
        "")
            ;;
        https://*)
            ;;
        *)
            fatal "Only https:// URLs are supported for IEDGE_URL (have ${IEDGE_URL})"
            ;;
    esac
}

# --- define needed environment variables ---
setup_env() {
    # --- use command args if passed or create default ---
    CMD_IEDGE=agent
    
    verify_IEDGE_url

    CMD_IEDGE_EXEC="${CMD_IEDGE}$(quote_indent "$@")"

    # --- use systemd name if defined or create default ---
    SYSTEM_NAME=iedge-${CMD_IEDGE}

    # --- check for invalid characters in system name ---
    valid_chars=$(printf '%s' "${SYSTEM_NAME}" | sed -e 's/[][!#$%&()*;<=>?\_`{|}/[:space:]]/^/g;' )
    if [ "${SYSTEM_NAME}" != "${valid_chars}"  ]; then
        invalid_chars=$(printf '%s' "${valid_chars}" | sed -e 's/[^^]/ /g')
        fatal "Invalid characters for system name:
            ${SYSTEM_NAME}
            ${invalid_chars}"
    fi

    # --- use sudo if we are not already root ---
    SUDO=sudo
    if [ $(id -u) -eq 0 ]; then
        SUDO=
    fi

    # --- use systemd type if defined or create default ---
    if [ -n "${INSTALL_IEDGE_TYPE}" ]; then
        SYSTEMD_TYPE=${INSTALL_IEDGE_TYPE}
    else
        if [ "${CMD_IEDGE}" = server ]; then
            SYSTEMD_TYPE=notify
        else
            SYSTEMD_TYPE=exec
        fi
    fi

    # --- use binary install directory if defined or create default ---
    if [ -n "${INSTALL_IEDGE_BIN_DIR}" ]; then
        BIN_DIR=${INSTALL_IEDGE_BIN_DIR}
    else
        # --- use /usr/local/bin if root can write to it, otherwise use /opt/bin if it exists
        BIN_DIR=/usr/local/bin
        if ! $SUDO sh -c "touch ${BIN_DIR}/iedge-ro-test && rm -rf ${BIN_DIR}/iedge-ro-test"; then
            if [ -d /opt/bin ]; then
                BIN_DIR=/opt/bin
            fi
        fi
    fi

    # --- use systemd directory if defined or create default ---
    if [ -n "${INSTALL_IEDGE_SYSTEMD_DIR}" ]; then
        SYSTEMD_DIR="${INSTALL_IEDGE_SYSTEMD_DIR}"
    else
        SYSTEMD_DIR=/etc/systemd/system
    fi

    # --- set related files from system name ---
    SERVICE_IEDGE=${SYSTEM_NAME}.service
    UNINSTALL_IEDGE_SH=${UNINSTALL_IEDGE_SH:-${BIN_DIR}/${SYSTEM_NAME}-uninstall.sh}
    KILLALL_IEDGE_SH=${KILLALL_IEDGE_SH:-${BIN_DIR}/${SYSTEM_NAME}-killall.sh}

    # --- use service or environment location depending on systemd/openrc ---
    if [ "${HAS_SYSTEMD}" = true ]; then
        FILE_IEDGE_SERVICE=${SYSTEMD_DIR}/${SERVICE_IEDGE}
        FILE_IEDGE_ENV=${SYSTEMD_DIR}/${SERVICE_IEDGE}.env
    fi
    # --- if bin directory is read only skip download ---
    if [ "${INSTALL_IEDGE_BIN_DIR_READ_ONLY}" = true ]; then
        INSTALL_IEDGE_SKIP_DOWNLOAD=true
    fi


}

# --- check if skip download environment variable set ---
can_skip_download() {
    if [ "${INSTALL_IEDGE_SKIP_DOWNLOAD}" != true ]; then
        return 1
    fi
}

# --- verify an executable iedge binary is installed ---
verify_IEDGE_is_executable() {
    if [ ! -x ${BIN_DIR}/iedge ]; then
        fatal "Executable iedge binary not found at ${BIN_DIR}/iedge"
    fi
}

# --- set arch and suffix, fatal if architecture not supported ---
setup_verify_arch() {
    if [ -z "$ARCH" ]; then
        ARCH=$(uname -m)
    fi
    case $ARCH in
        amd64)
            ARCH=amd64
            SUFFIX=
            ;;
        x86_64)
            ARCH=amd64
            SUFFIX=
            ;;
        arm64)
            ARCH=arm64
            SUFFIX=-${ARCH}
            ;;
        aarch64)
            ARCH=arm64
            SUFFIX=-${ARCH}
            ;;
        arm*)
            ARCH=arm
            SUFFIX=-${ARCH}hf
            ;;
        *)
            fatal "Unsupported architecture $ARCH"
    esac
}

# --- verify existence of network downloader executable ---
verify_downloader() {
    # Return failure if it doesn't exist or is no executable
    [ -x "$(which $1)" ] || return 1

    # Set verified executable as our downloader program and return success
    DOWNLOADER=$1
    return 0
}

# --- create temporary directory and cleanup when done ---
setup_tmp() {
    TMP_DIR=$(mktemp -d -t iedge-install.XXXXXXXXXX)
    TMP_HASH=${TMP_DIR}/iedge.hash
    TMP_BIN=${TMP_DIR}/iedge.bin
    cleanup() {
        code=$?
        set +e
        trap - EXIT
        rm -rf ${TMP_DIR}
        exit $code
    }
    trap cleanup INT EXIT
}

# # # --- use desired iedge version if defined or find version from channel ---
# # get_release_version() {
# #     if [ -n "${INSTALL_IEDGE_COMMIT}" ]; then
# #         VERSION_iedge="commit ${INSTALL_IEDGE_COMMIT}"
# #     elif [ -n "${INSTALL_IEDGE_VERSION}" ]; then
# #         VERSION_iedge=${INSTALL_IEDGE_VERSION}
# #     else
# #         info "Finding release for channel ${INSTALL_IEDGE_CHANNEL}"
# #         version_url="${INSTALL_IEDGE_CHANNEL_URL}/${INSTALL_IEDGE_CHANNEL}"
# #         case $DOWNLOADER in
# #             curl)
# #                 VERSION_iedge=$(curl -w '%{url_effective}' -L -s -S ${version_url} -o /dev/null | sed -e 's|.*/||')
# #                 ;;
# #             wget)
# #                 VERSION_iedge=$(wget -SqO /dev/null ${version_url} 2>&1 | grep -i Location | sed -e 's|.*/||')
# #                 ;;
# #             *)
# #                 fatal "Incorrect downloader executable '$DOWNLOADER'"
# #                 ;;
# #         esac
# #     fi
# #     info "Using ${VERSION_iedge} as release"
# # }

# # --- download from github url ---
download() {
    [ $# -eq 2 ] || fatal 'download needs exactly 2 arguments'

    case $DOWNLOADER in
        curl)
            curl -o $1 -sfL $2
            ;;
        wget)
            wget -qO $1 $2
            ;;
        *)
            fatal "Incorrect executable '$DOWNLOADER'"
            ;;
    esac

    # Abort if download command failed
    [ $? -eq 0 ] || fatal 'Download failed'
}



# --- download binary from github url ---
download_binary() {
    VERSION_iedge="stable"
    BIN_URL=${GITHUB_URL}/download/${VERSION_iedge}/iedge${SUFFIX}

    info "Downloading binary ${BIN_URL}"
    download ${TMP_BIN} ${BIN_URL}
}



# --- setup permissions and move binary to system directory ---
setup_binary() {
    chmod 755 ${TMP_BIN}
    info "Installing iedge to ${BIN_DIR}/iedge"
    $SUDO chown root:root ${TMP_BIN}
    $SUDO mv -f ${TMP_BIN} ${BIN_DIR}/iedge
}


# --- add additional utility links ---
create_symlinks() {
    [ "${INSTALL_IEDGE_BIN_DIR_READ_ONLY}" = true ] && return
    [ "${INSTALL_IEDGE_SYMLINK}" = skip ] && return

    for cmd in kubectl crictl ctr; do
        if [ ! -e ${BIN_DIR}/${cmd} ] || [ "${INSTALL_IEDGE_SYMLINK}" = force ]; then
            which_cmd=$(which ${cmd} 2>/dev/null || true)
            if [ -z "${which_cmd}" ] || [ "${INSTALL_IEDGE_SYMLINK}" = force ]; then
                info "Creating ${BIN_DIR}/${cmd} symlink to iedge"
                $SUDO ln -sf iedge ${BIN_DIR}/${cmd}
            else
                info "Skipping ${BIN_DIR}/${cmd} symlink to iedge, command exists in PATH at ${which_cmd}"
            fi
        else
            info "Skipping ${BIN_DIR}/${cmd} symlink to iedge, already exists"
        fi
    done
}

# --- download and verify iedge ---
download_and_verify() {
    if can_skip_download; then
       info 'Skipping miedge download and verify'
       verify_IEDGE_is_executable
       return
    fi

    setup_verify_arch
    verify_downloader curl || verify_downloader wget || fatal 'Can not find curl or wget for downloading files'
    setup_tmp
    download_binary
    verify_binary
    setup_binary
}


# --- create killall script ---
create_killall() {
    [ "${INSTALL_IEDGE_BIN_DIR_READ_ONLY}" = true ] && return
    info "Creating killall script ${KILLALL_IEDGE_SH}"
    $SUDO tee ${KILLALL_IEDGE_SH} >/dev/null << \EOF
#!/bin/sh
[ $(id -u) -eq 0 ] || exec sudo $0 $@
for bin in /var/lib/rancher/iedge/data/**/bin/; do
    [ -d $bin ] && export PATH=$PATH:$bin:$bin/aux
done
set -x
for service in /etc/systemd/system/iedge*.service; do
    [ -s $service ] && systemctl stop $(basename $service)
done
for service in /etc/init.d/iedge*; do
    [ -x $service ] && $service stop
done
pschildren() {
    ps -e -o ppid= -o pid= | \
    sed -e 's/^\s*//g; s/\s\s*/\t/g;' | \
    grep -w "^$1" | \
    cut -f2
}
pstree() {
    for pid in $@; do
        echo $pid
        for child in $(pschildren $pid); do
            pstree $child
        done
    done
}
killtree() {
    kill -9 $(
        { set +x; } 2>/dev/null;
        pstree $@;
        set -x;
    ) 2>/dev/null
}
getshims() {
    ps -e -o pid= -o args= | sed -e 's/^ *//; s/\s\s*/\t/;' | grep -w 'iedge/data/[^/]*/bin/containerd-shim' | cut -f1
}
killtree $({ set +x; } 2>/dev/null; getshims; set -x)
do_unmount_and_remove() {
    awk -v path="$1" '$2 ~ ("^" path) { print $2 }' /proc/self/mounts | sort -r | xargs -r -t -n 1 sh -c 'umount "$0" && rm -rf "$0"'
}
do_unmount_and_remove '/run/iedge'
do_unmount_and_remove '/var/lib/rancher/iedge'
do_unmount_and_remove '/var/lib/kubelet/pods'
do_unmount_and_remove '/run/netns/cni-'
# Remove CNI namespaces
ip netns show 2>/dev/null | grep cni- | xargs -r -t -n 1 ip netns delete
# Delete network interface(s) that match 'master cni0'
ip link show 2>/dev/null | grep 'master cni0' | while read ignore iface ignore; do
    iface=${iface%%@*}
    [ -z "$iface" ] || ip link delete $iface
done
ip link delete cni0
ip link delete flannel.1
rm -rf /var/lib/cni/
iptables-save | grep -v KUBE- | grep -v CNI- | iptables-restore
EOF
    $SUDO chmod 755 ${KILLALL_IEDGE_SH}
    $SUDO chown root:root ${KILLALL_IEDGE_SH}
}

# --- create uninstall script ---
create_uninstall() {
    [ "${INSTALL_IEDGE_BIN_DIR_READ_ONLY}" = true ] && return
    info "Creating uninstall script ${UNINSTALL_IEDGE_SH}"
    $SUDO tee ${UNINSTALL_IEDGE_SH} >/dev/null << EOF
#!/bin/sh
set -x
[ \$(id -u) -eq 0 ] || exec sudo \$0 \$@
${KILLALL_IEDGE_SH}
if which systemctl; then
    systemctl disable ${SYSTEM_NAME}
    systemctl reset-failed ${SYSTEM_NAME}
    systemctl daemon-reload
fi
if which rc-update; then
    rc-update delete ${SYSTEM_NAME} default
fi
rm -f ${FILE_IEDGE_SERVICE}
rm -f ${FILE_IEDGE_ENV}
remove_uninstall() {
    rm -f ${UNINSTALL_IEDGE_SH}
}
trap remove_uninstall EXIT
if (ls ${SYSTEMD_DIR}/iedge*.service || ls /etc/init.d/iedge*) >/dev/null 2>&1; then
    set +x; echo 'Additional iedge services installed, skipping uninstall of iedge'; set -x
    exit
fi
for cmd in kubectl crictl ctr; do
    if [ -L ${BIN_DIR}/\$cmd ]; then
        rm -f ${BIN_DIR}/\$cmd
    fi
done
rm -rf /etc/rancher/iedge
rm -rf /run/iedge
rm -rf /run/flannel
rm -rf /var/lib/rancher/iedge
rm -rf /var/lib/kubelet
rm -f ${BIN_DIR}/iedge
rm -f ${KILLALL_IEDGE_SH}

EOF
    $SUDO chmod 755 ${UNINSTALL_IEDGE_SH}
    $SUDO chown root:root ${UNINSTALL_IEDGE_SH}
}

# --- disable current service if loaded --
systemd_disable() {
    $SUDO rm -f /etc/systemd/system/${SERVICE_IEDGE} || true
    $SUDO rm -f /etc/systemd/system/${SERVICE_IEDGE}.env || true
    $SUDO systemctl disable ${SYSTEM_NAME} >/dev/null 2>&1 || true
}

# --- capture current env and create file containing IEDGE_ variables ---
create_env_file() {
    info "env: Creating environment file ${FILE_IEDGE_ENV}"
    UMASK=$(umask)
    umask 0377
    env | grep '^IEDGE_' | $SUDO tee ${FILE_IEDGE_ENV} >/dev/null
    env | egrep -i '^(NO|HTTP|HTTPS)_PROXY' | $SUDO tee -a ${FILE_IEDGE_ENV} >/dev/null
    umask $UMASK
}

# --- write systemd service file ---
create_systemd_service_file() {
    info "systemd: Creating service file ${FILE_IEDGE_SERVICE}"
    $SUDO tee ${FILE_IEDGE_SERVICE} >/dev/null << EOF
[Unit]
Description=Lightweight Iedge Agent
Documentation=https://iview.vn
Wants=network-online.target
After=network-online.target
[Install]
WantedBy=multi-user.target
[Service]
Type=${SYSTEMD_TYPE}
EnvironmentFile=${FILE_IEDGE_ENV}
KillMode=process
Delegate=yes
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
TimeoutStartSec=0
Restart=always
RestartSec=5s
ExecStartPre=-/sbin/modprobe br_netfilter
ExecStartPre=-/sbin/modprobe overlay
ExecStart=${BIN_DIR}/iedge \\
    ${CMD_IEDGE_EXEC}
EOF
}

# --- write openrc service file ---
create_openrc_service_file() {
    LOG_FILE=/var/log/${SYSTEM_NAME}.log

    info "openrc: Creating service file ${FILE_IEDGE_SERVICE}"
    $SUDO tee ${FILE_IEDGE_SERVICE} >/dev/null << EOF
#!/sbin/openrc-run
depend() {
    after network-online
    want cgroups
}
start_pre() {
    rm -f /tmp/iedge.*
}
supervisor=supervise-daemon
name=${SYSTEM_NAME}
command="${BIN_DIR}/iedge"
command_args="$(escape_dq "${CMD_IEDGE_EXEC}")
    >>${LOG_FILE} 2>&1"
output_log=${LOG_FILE}
error_log=${LOG_FILE}
pidfile="/var/run/${SYSTEM_NAME}.pid"
respawn_delay=5
respawn_max=0
set -o allexport
if [ -f /etc/environment ]; then source /etc/environment; fi
if [ -f ${FILE_IEDGE_ENV} ]; then source ${FILE_IEDGE_ENV}; fi
set +o allexport
EOF
    $SUDO chmod 0755 ${FILE_IEDGE_SERVICE}

    $SUDO tee /etc/logrotate.d/${SYSTEM_NAME} >/dev/null << EOF
${LOG_FILE} {
	missingok
	notifempty
	copytruncate
}
EOF
}

# --- write systemd or openrc service file ---
create_service_file() {
    [ "${HAS_SYSTEMD}" = true ] && create_systemd_service_file
    [ "${HAS_OPENRC}" = true ] && create_openrc_service_file
    return 0
}



# --- enable and start systemd service ---
systemd_enable() {
    info "systemd: Enabling ${SYSTEM_NAME} unit"
    $SUDO systemctl enable ${FILE_IEDGE_SERVICE} >/dev/null
    $SUDO systemctl daemon-reload >/dev/null
}

systemd_start() {
    info "systemd: Starting ${SYSTEM_NAME}"
    $SUDO systemctl restart ${SYSTEM_NAME}
}

# --- enable and start openrc service ---
openrc_enable() {
    info "openrc: Enabling ${SYSTEM_NAME} service for default runlevel"
    $SUDO rc-update add ${SYSTEM_NAME} default >/dev/null
}

openrc_start() {
    info "openrc: Starting ${SYSTEM_NAME}"
    $SUDO ${FILE_IEDGE_SERVICE} restart
}

# --- startup systemd or openrc service ---
service_enable_and_start() {
    [ "${INSTALL_IEDGE_SKIP_ENABLE}" = true ] && return

    [ "${HAS_SYSTEMD}" = true ] && systemd_enable
    [ "${HAS_OPENRC}" = true ] && openrc_enable

    [ "${INSTALL_IEDGE_SKIP_START}" = true ] && return

    [ "${HAS_SYSTEMD}" = true ] && systemd_start
    [ "${HAS_OPENRC}" = true ] && openrc_start
    return 0
}

# --- re-evaluate args to include env command ---
eval set -- $(escape "${INSTALL_IEDGE_EXEC}") $(quote "$@")

# --- run the install process --
{
    verify_system
    setup_env "$@"
    download_and_verify
    create_symlinks
    create_killall
    create_uninstall
    systemd_disable
    create_env_file
    create_service_file
    service_enable_and_start
}
