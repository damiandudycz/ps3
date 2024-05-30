#!/bin/bash

# This script prepares current machine for working with development tools for the PS3 Gentoo project.
# Please run this script after cloning the repository.
# It also generates a bash file that contains all the shared functionality and configuration of other scripts.

# These variables are used only by this script itself, others will have patchs loaded from .env-shared.sh.
readonly PATH_ROOT_INITIAL="$(realpath -m '..')"
readonly PATH_ENV_FILE="${PATH_ROOT_INITIAL}/.env-shared.sh"

# Clear old environment file if exists.
[ ! -f "${PATH_ENV_FILE}" ] || rm "${PATH_ENV_FILE}" || exit 1

# Below code is for creating shared environment configuration.
# -----------------------------------------------------------------------------------------
cat <<EOF > "${PATH_ENV_FILE}"
# Prevent multiple imports.
[ ! \${PS3_ENV_SHARED_LOADED} ] || return 0
readonly PS3_ENV_SHARED_LOADED=true

readonly HOST_ARCHITECTURE="$(uname -m)"
readonly HOST_ARCHITECTURE_PORTAGE="$(portageq envvar ARCH)"
readonly TARGET_ARCHITECTURE="ppc64"
readonly TARGET_ARCHITECTURE_LONG="powerpc64"
readonly TARGET_SUBARCHITECTURE="cell"
readonly PROJECT_NAME="PS3_Gentoo"
readonly CONF_CATALYST_RELEASE_NAMES=(default) # Supported release configurations, eq. LTO, CLANG, etc.
readonly CONF_CATALYST_RELEASE_NAME_DFAULT="default"
readonly CONF_GITHUB_SIZE_LIMIT="100M"

readonly CROSSDEV_TARGET="\${TARGET_ARCHITECTURE_LONG}-\${TARGET_SUBARCHITECTURE}-linux-gnu"

declare -A USAGE_DESCRIPTIONS
declare -A FAILURE_HANDLERS

# Shared environment configuration and functionality for PS3-Gentoo project dev tools.
readonly PATH_ROOT="${PATH_ROOT_INITIAL}"

# Main patches at the root of repository.
readonly PATH_AUTOBUILDS="\${PATH_ROOT}/autobuilds"
readonly PATH_BINHOSTS="\${PATH_ROOT}/binhosts"
readonly PATH_DEV_TOOLS="\${PATH_ROOT}/dev-tools"
readonly PATH_OVERLAYS="\${PATH_ROOT}/overlays"

# Dev tools patchs.
readonly PATH_DEV_TOOLS_BINHOST="\${PATH_DEV_TOOLS}/binhost"
readonly PATH_DEV_TOOLS_DISTCC_DOCKER="\${PATH_DEV_TOOLS}/distcc-docker"
readonly PATH_DEV_TOOLS_ENVIRONMENT="\${PATH_DEV_TOOLS}/environment"
readonly PATH_DEV_TOOLS_KERNEL_EBUILD="\${PATH_DEV_TOOLS}/kernel-ebuild"
readonly PATH_DEV_TOOLS_PS3_INSTALLER="\${PATH_DEV_TOOLS}/ps3-installer"
readonly PATH_DEV_TOOLS_RELEASE="\${PATH_DEV_TOOLS}/release"
readonly PATH_DEV_TOOLS_RELENG="\${PATH_DEV_TOOLS}/releng"

# External modules.
readonly PATH_AUTOBUILDS_PS3_GENTOO="\${PATH_AUTOBUILDS}/ps3-gentoo-autobuilds"              # Autobuilds.
readonly PATH_BINHOSTS_PS3_GENTOO="\${PATH_BINHOSTS}/ps3-gentoo-binhosts"                    # Binhosts.
readonly PATH_OVERLAYS_PS3_GENTOO="\${PATH_OVERLAYS}/ps3-gentoo-overlay"                     # Overlays.
readonly PATH_OVERLAYS_PS3_GENTOO_DISTFILES="\${PATH_OVERLAYS}/ps3-gentoo-overlay.distfiles" # Distfiles.

# Various system elements.
readonly PATH_ETC="/etc"
readonly PATH_USR="/usr"
readonly PATH_VAR="/var"
readonly PATH_BOOT="/boot"
readonly PATH_ETC_PORTAGE="\${PATH_ETC}/portage"
readonly PATH_ETC_PORTAGE_MAKE_CONF="\${PATH_ETC_PORTAGE}/make.conf"
readonly PATH_ETC_PORTAGE_PACKAGE_USE="\${PATH_ETC_PORTAGE}/package.use"
readonly PATH_ETC_PORTAGE_PACKAGE_ACCEPT_KEYWORDS="\${PATH_ETC_PORTAGE}/package.accept_keywords"
readonly PATH_VAR_TMP="\${PATH_VAR}/tmp"
readonly PATH_USR_SHARE="\${PATH_USR}/share"
readonly PATH_USR_BIN="\${PATH_USR}/bin"
readonly PATH_VAR_DB_REPOS="\${PATH_VAR}/db/repos"
readonly PATH_VAR_DB_REPOS_GENTOO="\${PATH_VAR_DB_REPOS}/gentoo"
readonly PATH_VAR_CACHE="\${PATH_VAR}/cache"
readonly PATH_VAR_CACHE_DISTFILES="\${PATH_VAR_CACHE}/distfiles"

# DEV Tools work directories.
readonly PATH_WORK="\${PATH_VAR_TMP}/\${PROJECT_NAME}"
readonly PATH_WORK_BINHOST="\${PATH_WORK}/binhost"
readonly PATH_WORK_DISTCC_DOCKER="\${PATH_WORK}/distcc_docker"
readonly PATH_WORK_ENVIRONMENT="\${PATH_WORK}/environment"
readonly PATH_WORK_KERNEL_EBUILD="\${PATH_WORK}/kernel_ebuild"
readonly PATH_WORK_PS3_INSTALLER="\${PATH_WORK}/ps3_installer"
readonly PATH_WORK_RELEASE="\${PATH_WORK}/release"
readonly PATH_WORK_RELENG="\${PATH_WORK}/releng"

# DEV Tools additional environments.
readonly PATH_EXTRA_ENV_BINHOST="\${PATH_DEV_TOOLS_BINHOST}/env.sh"
readonly PATH_EXTRA_ENV_DISTCC_DOCKER="\${PATH_DEV_TOOLS_DISTCC_DOCKER}/env.sh"
readonly PATH_EXTRA_ENV_ENVIRONMENT="\${PATH_DEV_TOOLS_ENVIRONMENT}/env.sh"
readonly PATH_EXTRA_ENV_KERNEL_EBUILD="\${PATH_DEV_TOOLS_KERNEL_EBUILD}/env.sh"
readonly PATH_EXTRA_ENV_PS3_INSTALLER="\${PATH_DEV_TOOLS_PS3_INSTALLER}/env.sh"
readonly PATH_EXTRA_ENV_RELEASE="\${PATH_DEV_TOOLS_RELEASE}/env.sh"
readonly PATH_EXTRA_ENV_RELENG="\${PATH_DEV_TOOLS_RELENG}/env.sh"

# Various
readonly PATH_RELENG="\${PATH_USR_SHARE}/releng"

# URLs
readonly URL_GIRHUB_RAW_MAIN="https://raw.githubusercontent.com/damiandudycz"
readonly URL_GITHUB_RAW_PS3="\${URL_GIRHUB_RAW_MAIN}/ps3"
readonly URL_GITHUB_RAW_AUTOBUILDS="\${URL_GIRHUB_RAW_MAIN}/ps3-gentoo-autobuilds"
readonly URL_GITHUB_RAW_BINHOSTS="\${URL_GIRHUB_RAW_MAIN}/ps3-gentoo-binhosts"
readonly URL_GITHUB_RAW_OVERLAY="\${URL_GIRHUB_RAW_MAIN}/ps3-gentoo-overlay"

# Shared functionality.
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_TURQUOISE='\033[0;36m'
readonly COLOR_TURQUOISE_BOLD='\033[1;36m'
readonly COLOR_NC='\033[0m' # No Color

echo_color() { # Usage: echo_color COLOR MESSAGE
    echo -e "\${1}\${2}\${COLOR_NC}"
}

# Handling errors.
failure() {
    local line="\${BASH_LINENO[0]}"
    local cmd="\${BASH_COMMAND}"
    local file="\${BASH_SOURCE[1]}"
    local custom_message="\$1"
    echo_color \${COLOR_RED} "[ Error at line \$line in file '\$file' ]"
    if [[ -n "\$custom_message" ]]; then
        echo_color \${COLOR_RED} "\$custom_message"
    else
        echo_color \${COLOR_RED} "Failed command: '\$cmd'"
    fi

    # Execute failure handler if added
    local failure_handler_name="\$(basename \"\${BASH_SOURCE[1]}\")"
    local failure_handler=\${FAILURE_HANDLERS[\$failure_handler_name]}
    [[ -n "\${failure_handler}" ]] && eval "\${failure_handler}"

    exit 1
}

register_failure_handler() {
    local file="\$(basename \"\${BASH_SOURCE[1]}\")"
    FAILURE_HANDLERS["\$file"]="\$1"
}

register_usage() {
    local file="\$(basename \"\${BASH_SOURCE[1]}\")"
    USAGE_DESCRIPTIONS["\$file"]="\$1"
}

show_usage() {
    local file="\$(basename \"\${BASH_SOURCE[1]}\")"
    echo "Usage: \${USAGE_DESCRIPTIONS[\$file]}"
    exit 1
}

upload_repository() {
    # Upload repository at given location with commit message
    cd "\${1}"
    git add -A
    git commit -m "\$2"
    git push
}

empty_directory() {
    # Remove directory if exists and create empty one
    rm -rf "\${1}"
    mkdir -p "\${1}"
}

# For KEY="VALUE" format.
update_config_assign() {
    local KEY="\$1"
    local VALUE="\$2"
    local FILE="\$3"

    if grep -q "^\${KEY}=\".*\"" "\${FILE}"; then
        sed -i "/^\${KEY}=\"/c\${KEY}=\"\${VALUE}\"" "\${FILE}"
    else
        echo "\${KEY}=\\"\${VALUE}\\"" >> "\${FILE}"
    fi
}

# For KEY = VALUE format.
update_config_assign_space() {
    local KEY="\$1"
    local VALUE="\$2"
    local FILE="\$3"

    if grep -q "^\${KEY}\s*=" "\${FILE}"; then
        sed -i "/^\${KEY}\s*=/c\${KEY} = \${VALUE}" "\${FILE}"
    else
        echo "\${KEY} = \${VALUE}" >> "\${FILE}"
    fi
}

unmask_package() {
    local PACKAGE="\$1"
    local KEYWORDS="\$2"
    local UNMASK_PATH="\${PATH_ETC_PORTAGE_PACKAGE_ACCEPT_KEYWORDS}/\${PROJECT_NAME}"
    echo "\${PACKAGE} \${KEYWORDS}" >> "\${UNMASK_PATH}"
}

use_set_package() {
    local PACKAGE="\$1"
    local USE_FLAGS="\$2"
    local USE_FLAGS_PATH="\${PATH_ETC_PORTAGE_PACKAGE_USE}/\${PROJECT_NAME}"
    echo "\${PACKAGE} \${USE_FLAGS}" >> "\${USE_FLAGS_PATH}"
}

# Print environment details.
[ "\$1" == "--silent" ] || echo_color \${COLOR_TURQUOISE_BOLD} "[ PS3-Gentoo development environment - \${PATH_ROOT} ]"

trap failure ERR

EOF
# -----------------------------------------------------------------------------------------

# Import generated environment file.
source "${PATH_ENV_FILE}"

setup_environment_failure() {
    # Clean env data file generated:
    rm -f "${PATH_ENV_FILE}"
    failure
}
trap setup_environment_failure ERR

# Find all environment setup scripts.
readonly SETUP_SCRIPTS="$(find ${PATH_DEV_TOOLS_ENVIRONMENT} -maxdepth 1 -type f -name 'setup*.sh' | sort)"

# Run setup scripts
for SCRIPT in ${SETUP_SCRIPTS[@]}; do
    echo_color ${COLOR_TURQUOISE} "[ ${SCRIPT} ]"
    cd $(dirname "${SCRIPT}")
    SCRIPT_NAME=$(basename "${SCRIPT}")
    source "${SCRIPT_NAME}"
done
