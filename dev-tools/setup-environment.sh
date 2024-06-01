#!/bin/bash

# CONF_ - Constant values, not dependent on anything.
# VAL_  - Constant values calculated from other values or extracted from the system.
# URL_  - URLs.
# PATH_ - Paths to directories and files.

# These variables are used only by this script itself, others will have patchs loaded from .env-shared.sh.
readonly PATH_ROOT_INITIAL="$(realpath -m '..')"
readonly PATH_ENV_FILE="${PATH_ROOT_INITIAL}/.env-shared.sh"

# Clear old environment file if exists.
rm -f "${PATH_ENV_FILE}" || exit 1

# Below code is for creating shared environment configuration.

cat <<EOF > "${PATH_ENV_FILE}"
# Prevent multiple imports ---------------------------------------------------------------------------------------------------------
[ \${VAL_PS3_ENV_SHARED_LOADED} ] && return 0; readonly VAL_PS3_ENV_SHARED_LOADED=true
# ----------------------------------------------------------------------------------------------------------------------------------

# Project configuration ------------------------------------------------------------------------------------------------------------
readonly CONF_PROJECT_NAME="PS3_Gentoo"
readonly CONF_PROJECT_DEPENDENCIES=(gentoolkit ruby pkgdev)
readonly CONF_TARGET_ARCHITECTURE="ppc64"
readonly CONF_TARGET_ARCHITECTURE_LONG="powerpc64"
readonly CONF_TARGET_SUBARCHITECTURE="cell"
readonly CONF_TARGET_KERNEL_TYPE="linux"
readonly CONF_TARGET_TOOLCHAIN="gnu"
readonly CONF_TARGET_COMMON_FLAGS="-O2 -pipe -mcpu=cell -mtune=cell -mabi=altivec -mno-string -mno-update -mno-multiple"
readonly CONF_GIT_FILE_SIZE_LIMIT="100M"
readonly CONF_GIT_USER="Damian Dudycz"
readonly CONF_GIT_EMAIL="damiandudycz@yahoo.com"
readonly CONF_GIT_EDITOR="nano"
readonly CONF_RELEASE_TYPES=(default) # Supported release configurations, eq. default, lto, clang, etc.
readonly CONF_RELEASE_TYPE_DFAULT="default"
readonly CONF_QEMU_CONFIG=":ppc64:M::\x7fELF\x02\x02\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x15:\xff\xff\xff\xff\xff\xff\xff\xfc\xff\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff:"
readonly CONF_PORTAGE_FEATURES="getbinpkg"
readonly CONF_QEMU_SECTION_START="# FOR CATALYST QEMU ---------- START"
readonly CONF_QEMU_SECTION_END="# FOR CATALYST QEMU ---------- END"
readonly CONF_CATALYST_JOBS="8"
readonly CONF_CATALYST_LOAD="12.0"
readonly CONF_RELENG_USE_FLAGS='"altivec", "ibm", "ps3"'
readonly CONF_CROSSDEV_ABI="altivec"
readonly CONF_CROSSDEV_L="2.37-r7"
readonly CONF_CROSSDEV_K="6.9"
readonly CONF_CROSSDEV_G="13.2.1_p20240113-r1"
readonly CONF_CROSSDEV_B="2.41-r3"
readonly CONF_KERNEL_PACKAGE_GROUP="sys-kernel"
readonly CONF_KERNEL_PACKAGE_NAME_BASE="gentoo-kernel" # Name of raw gentoo kernel package
readonly CONF_KERNEL_PACKAGE_NAME_SPECIAL="gentoo-kernel-ps3" # Name of gentoo kernel PS3 package
readonly CONF_KERNEL_PACKAGE_AUTOUNMASK=false # Should use ~ppc64 version of kernel by default
# URLs.
readonly URL_GIRHUB_RAW_BASE="https://raw.githubusercontent.com/damiandudycz"
readonly URL_GITHUB_RAW_PS3="\${URL_GIRHUB_RAW_BASE}/ps3"
readonly URL_GITHUB_RAW_AUTOBUILDS="\${URL_GIRHUB_RAW_BASE}/ps3-gentoo-autobuilds"
readonly URL_GITHUB_RAW_BINHOSTS="\${URL_GIRHUB_RAW_BASE}/ps3-gentoo-binhosts"
readonly URL_GITHUB_RAW_OVERLAY="\${URL_GIRHUB_RAW_BASE}/ps3-gentoo-overlay"
# ----------------------------------------------------------------------------------------------------------------------------------

# Host machine details and various variables ---------------------------------------------------------------------------------------
readonly VAL_HOST_ARCHITECTURE="$(uname -m)"
readonly VAL_HOST_ARCHITECTURE_PORTAGE="$(portageq envvar ARCH)"
readonly VAL_SCRIPT_NAME_CALLED="$(basename $0)" # Name of script that was called by the user.
# ----------------------------------------------------------------------------------------------------------------------------------

# Paths and variables --------------------------------------------------------------------------------------------------------------
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
#readonly PATH_DEV_TOOLS_RELENG="\${PATH_DEV_TOOLS}/releng" # ??

# External modules.
readonly PATH_AUTOBUILDS_PS3_GENTOO="\${PATH_AUTOBUILDS}/ps3-gentoo-autobuilds"              # Autobuilds.
readonly PATH_BINHOSTS_PS3_GENTOO="\${PATH_BINHOSTS}/ps3-gentoo-binhosts"                    # Binhosts.
readonly PATH_OVERLAYS_PS3_GENTOO="\${PATH_OVERLAYS}/ps3-gentoo-overlay"                     # Overlays.
readonly PATH_OVERLAYS_PS3_GENTOO_DISTFILES="\${PATH_OVERLAYS}/ps3-gentoo-overlay.distfiles" # Distfiles.

# Main system directories elements.
readonly PATH_ETC="/etc"
readonly PATH_USR="/usr"
readonly PATH_VAR="/var"
readonly PATH_BOOT="/boot"

# System components directories.
readonly PATH_VAR_TMP="\${PATH_VAR}/tmp"
readonly PATH_USR_SHARE="\${PATH_USR}/share"
readonly PATH_USR_BIN="\${PATH_USR}/bin"
readonly PATH_VAR_DB_REPOS="\${PATH_VAR}/db/repos"
readonly PATH_VAR_DB_REPOS_GENTOO="\${PATH_VAR_DB_REPOS}/gentoo"
readonly PATH_VAR_DB_REPOS_CROSSDEV="\${PATH_VAR_DB_REPOS}/crossdev"
readonly PATH_VAR_CACHE="\${PATH_VAR}/cache"
readonly PATH_VAR_CACHE_DISTFILES="\${PATH_VAR_CACHE}/distfiles"

# Portage paths.
readonly PATH_ETC_PORTAGE="\${PATH_ETC}/portage"
readonly PATH_ETC_PORTAGE_MAKE_CONF="\${PATH_ETC_PORTAGE}/make.conf"
readonly PATH_ETC_PORTAGE_PACKAGE_USE="\${PATH_ETC_PORTAGE}/package.use"
readonly PATH_ETC_PORTAGE_PACKAGE_ACCEPT_KEYWORDS="\${PATH_ETC_PORTAGE}/package.accept_keywords"
readonly PATH_ETC_PORTAGE_REPOS_CONF="\${PATH_ETC_PORTAGE}/repos.conf"

# DEV Tools work directories.
readonly PATH_WORK="\${PATH_VAR_TMP}/\${CONF_PROJECT_NAME}"
readonly PATH_WORK_BINHOST="\${PATH_WORK}/binhost"
readonly PATH_WORK_DISTCC_DOCKER="\${PATH_WORK}/distcc_docker"
readonly PATH_WORK_ENVIRONMENT="\${PATH_WORK}/environment"
readonly PATH_WORK_KERNEL_EBUILD="\${PATH_WORK}/kernel_ebuild"
readonly PATH_WORK_PS3_INSTALLER="\${PATH_WORK}/ps3_installer"
readonly PATH_WORK_RELEASE="\${PATH_WORK}/release"

# DEV Tools additional environments.
readonly PATH_EXTRA_ENV_KERNEL_EBUILD="\${PATH_DEV_TOOLS_KERNEL_EBUILD}/env.sh"

# Catalyst related paths.
readonly PATH_CATALYST_USR="\${PATH_USR_SHARE}/catalyst"
readonly PATH_CATALYST_TMP="\${PATH_VAR_TMP}/catalyst"
readonly PATH_CATALYST_ETC="\${PATH_ETC}/catalyst"
readonly PATH_CATALYST_BUILDS="\${PATH_CATALYST_TMP}/builds"
readonly PATH_CATALYST_STAGES="\${PATH_CATALYST_TMP}/config/stages"
readonly PATH_CATALYST_PACKAGES="\${PATH_CATALYST_TMP}/packages"
readonly PATH_CATALYST_CONF="\${PATH_CATALYST_ETC}/catalyst.conf"
readonly PATH_CATALYST_PPC_TOML="\${PATH_CATALYST_USR}/arch/ppc.toml"
readonly PATH_CATALYST_PATCHES_SRC="\${PATH_DEV_TOOLS_ENVIRONMENT}/data/catalyst-patches"
readonly PATH_CATALYST_PATCHES_DST="\${PATH_ETC_PORTAGE}/patches/dev-util/catalyst"

# Binhost.
readonly PATH_BINHOST_OVERLAY_DEFAULT="\${PATH_BINHOSTS_PS3_GENTOO}/\${CONF_RELEASE_TYPE_DFAULT}"
readonly PATH_BINHOST_CATALYST_DEFAULT="\${PATH_CATALYST_PACKAGES}/\${CONF_RELEASE_TYPE_DFAULT}"
readonly PATH_BINHOST_OVERLAY_DEFAULT_METADATA="\${PATH_BINHOST_OVERLAY_DEFAULT}/Packages"
readonly PATH_BINHOST_SCRIPT_DELETE="\${PATH_DEV_TOOLS_BINHOST}/binhost-01-delete-packages.sh"

# Releng.
readonly PATH_RELENG="\${PATH_USR_SHARE}/releng"

# QEMU.
readonly VAL_QEMU_IS_NEEDED=$(expr "\${VAL_HOST_ARCHITECTURE}" != "\${CONF_TARGET_ARCHITECTURE}") # Is host architecture different than target architecture.
readonly VAL_QEMU_RELENG_POSTFIX=\$([[ \${VAL_QEMU_IS_NEEDED} ]] && echo "-qemu")
readonly VAL_QEMU_REGISTRATION_EXPR="\${CONF_QEMU_CONFIG}\${PATH_QEMU_INTERPRETER}:"
readonly PATH_QEMU_BINFMT="/proc/sys/fs/binfmt_misc"
readonly PATH_QEMU_BINFMT_REGISTER="\${PATH_QEMU_BINFMT}/register"
readonly PATH_QEMU_INTERPRETER="\${PATH_USR_BIN}/qemu-\${CONF_TARGET_ARCHITECTURE}"

# Crossdev.
readonly VAL_CROSSDEV_TARGET="\${CONF_TARGET_ARCHITECTURE_LONG}-\${CONF_TARGET_SUBARCHITECTURE}-\${CONF_TARGET_KERNEL_TYPE}-\${CONF_TARGET_TOOLCHAIN}"
readonly PATH_CROSSDEV_USR="\${PATH_USR_SHARE}/crossdev"
readonly PATH_CROSSDEV_INSTALLATION="\${PATH_USR}/\${VAL_CROSSDEV_TARGET}"
readonly PATH_CROSSDEV_BINPKGS="\${PATH_CROSSDEV_INSTALLATION}/\${PATH_VAR_CACHE}/binpkgs"

# Other.
readonly PATH_ENV_HELPER_FUNCTIONS="\${PATH_DEV_TOOLS_ENVIRONMENT}/env-helper-functions.sh"
readonly PATH_GIT_HOOK_AUTOBUILDS="\${PATH_ROOT}/.git/modules/autobuilds/ps3-gentoo-autobuilds/pre-commit" # TODO: Use variables for patch
readonly PATH_PORTAGE_TIMESTAMP_CHK="\${PATH_VAR_DB_REPOS_GENTOO}/metadata/timestamp.chk"

# Kernel.
readonly VAL_KERNEL_PACKAGE_BASE="\${CONF_KERNEL_PACKAGE_GROUP}/\${CONF_KERNEL_PACKAGE_NAME_BASE}"
readonly VAL_KERNEL_PACKAGE_SPECIAL="\${CONF_KERNEL_PACKAGE_GROUP}/\${CONF_KERNEL_PACKAGE_NAME_SPECIAL}"

# Releng.
readonly PATH_RELENG_PORTAGE_CONFDIR_STAGES="\${PATH_RELENG}/releases/portage/stages${VAL_QEMU_RELENG_POSTFIX}"
readonly PATH_RELENG_PORTAGE_CONFDIR_ISOS="\${PATH_RELENG}/releases/portage/isos${VAL_QEMU_RELENG_POSTFIX}"
# ----------------------------------------------------------------------------------------------------------------------------------

# Shared functionality.
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_TURQUOISE='\033[0;36m'
readonly COLOR_TURQUOISE_BOLD='\033[1;36m'
readonly COLOR_NC='\033[0m' # No Color

source "\${PATH_ENV_HELPER_FUNCTIONS}"

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
