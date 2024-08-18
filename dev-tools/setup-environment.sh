#!/bin/bash

# CONF_ - Configuration variables.
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
readonly CONF_PROJECT_DEPENDENCIES=(app-portage/gentoolkit dev-lang/ruby dev-util/pkgdev sys-process/time net-dns/bind net-dns/bind-tools)

readonly CONF_TARGET_ARCH="ppc64"
readonly CONF_TARGET_ARCH_FAMILY="ppc"
readonly CONF_TARGET_ARCH_SUBARCH="cell"
readonly CONF_TARGET_CHOST_ARCH="powerpc64"
readonly CONF_TARGET_CHOST_VENDOR="unknown"
readonly CONF_TARGET_CHOST_OS="linux"
readonly CONF_TARGET_CHOST_LIBC="gnu"
readonly CONF_TARGET_CHOST="\${CONF_TARGET_CHOST_ARCH}-\${CONF_TARGET_CHOST_VENDOR}-\${CONF_TARGET_CHOST_OS}-\${CONF_TARGET_CHOST_LIBC}" # powerpc64-unknown-linux-gnu
readonly CONF_TARGET_COMMON_FLAGS="-O2 -pipe -mcpu=cell -mtune=cell -mabi=altivec -mno-string -mno-update -mno-multiple"

readonly CONF_HOST_ARCH="$(uname -m)"
readonly CONF_HOST_ARCH_PORTAGE="$(portageq envvar ARCH)"

readonly CONF_GIT_FILE_SIZE_LIMIT="100M"
readonly CONF_GIT_USER="Damian Dudycz"
readonly CONF_GIT_EMAIL="damiandudycz@yahoo.com"
readonly CONF_GIT_EDITOR="nano"

readonly CONF_CATALYST_JOBS="8"
readonly CONF_CATALYST_LOAD="12.0"
readonly CONF_CATALYST_TMPFS="6" # GBs of TMPFS partition

readonly CONF_QEMU_CONFIG=":\${CONF_TARGET_ARCH}:M::\x7fELF\x02\x02\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x15:\xff\xff\xff\xff\xff\xff\xff\xfc\xff\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff:" # Srttings for PPC64.
readonly CONF_QEMU_INTERPRETER="/usr/bin/qemu-\${CONF_TARGET_ARCH}"
readonly CONF_QEMU_IS_NEEDED=$(expr "\${CONF_HOST_ARCH}" != "\${CONF_TARGET_ARCH}")
readonly CONF_QEMU_REGISTRATION_EXPR="\${CONF_QEMU_CONFIG}\${CONF_QEMU_INTERPRETER}:"
readonly CONF_QEMU_RELENG_POSTFIX=\$([[ \${CONF_QEMU_IS_NEEDED} ]] && echo "-qemu") # TODO: Move to releng

readonly CONF_RELEASE_PROFILE="23.0"
readonly CONF_RELEASE_TYPES=("\${CONF_RELEASE_PROFILE}-default")     # Supported release configurations, eq. default, lto, clang, etc.
readonly CONF_RELEASE_TYPE_DFAULT="\${CONF_RELEASE_PROFILE}-default" # 23.0-default
readonly CONF_RELEASE_EMAIL_TO="damiandudycz@yahoo.com"
readonly CONF_RELEASE_EMAIL_FROM="damiandudycz@yahoo.com"
readonly CONF_RELEASE_EMAIL_PREPEND="[cell-auto]"
readonly CONF_RELEASE_USE_FLAGS='"altivec", "ibm", "ps3"'

readonly CONF_CROSSDEV_ABI="altivec"
readonly CONF_CROSSDEV_L="2.40-r9"
readonly CONF_CROSSDEV_K="6.6"
readonly CONF_CROSSDEV_G="13.3.1_p20240614"
readonly CONF_CROSSDEV_B="2.42-r1"

readonly CONF_KERNEL_PACKAGE_GROUP="sys-kernel"
readonly CONF_KERNEL_PACKAGE_NAME_BASE="gentoo-kernel" # Name of raw gentoo kernel package
readonly CONF_KERNEL_PACKAGE_NAME_SPECIAL="gentoo-kernel-ps3" # Name of gentoo kernel PS3 package
readonly CONF_KERNEL_PACKAGE_BASE="\${CONF_KERNEL_PACKAGE_GROUP}/\${CONF_KERNEL_PACKAGE_NAME_BASE}"
readonly CONF_KERNEL_PACKAGE_SPECIAL="\${CONF_KERNEL_PACKAGE_GROUP}/\${CONF_KERNEL_PACKAGE_NAME_SPECIAL}"
readonly CONF_KERNEL_PACKAGE_AUTOUNMASK=false # Should use ~ppc64 version of kernel by default

# URLs.
readonly URL_GIRHUB_RAW_BASE="https://raw.githubusercontent.com/damiandudycz"
readonly URL_GITHUB_RAW_PS3="\${URL_GIRHUB_RAW_BASE}/ps3"
readonly URL_GITHUB_RAW_RELEASES="\${URL_GIRHUB_RAW_BASE}/ps3-gentoo-releases"
readonly URL_GITHUB_RAW_OVERLAY="\${URL_GIRHUB_RAW_BASE}/ps3-gentoo-overlay"
readonly URL_GITHUB_RAW_OVERLAY_DISTFILES="\${URL_GIRHUB_RAW_BASE}/ps3-gentoo-overlay.distfiles"
readonly URL_RELEASE_GENTOO="https://gentoo.osuosl.org/releases/\${CONF_TARGET_ARCH_FAMILY}/autobuilds"
readonly URL_STAGE3_INFO="\${URL_RELEASE_GENTOO}/latest-stage3-\${CONF_TARGET_ARCH}-openrc.txt"

# Paths and variables --------------------------------------------------------------------------------------------------------------
readonly PATH_ROOT="${PATH_ROOT_INITIAL}"

# Main patches at the root of repository.
readonly PATH_DEV_TOOLS="\${PATH_ROOT}/dev-tools"
readonly PATH_OVERLAYS="\${PATH_ROOT}/overlays"
readonly PATH_RELEASES="\${PATH_ROOT}/releases"

# Dev tools patchs.
readonly PATH_DEV_TOOLS_ENVIRONMENT="\${PATH_DEV_TOOLS}/environment"
readonly PATH_DEV_TOOLS_PS3_INSTALLER="\${PATH_DEV_TOOLS}/ps3-installer"
readonly PATH_DEV_TOOLS_KERNEL_EBUILD="\${PATH_DEV_TOOLS}/kernel-ebuild"
readonly PATH_DEV_TOOLS_KERNEL_PATCHES="\${PATH_DEV_TOOLS}/kernel-patches"
readonly PATH_DEV_TOOLS_DISTCC_DOCKER="\${PATH_DEV_TOOLS}/distcc-docker"
readonly PATH_DEV_TOOLS_RELENG="\${PATH_DEV_TOOLS}/releng"
readonly PATH_DEV_TOOLS_OVERLAY="\${PATH_DEV_TOOLS}/overlay"
readonly PATH_DEV_TOOLS_BINHOST="\${PATH_DEV_TOOLS}/binhost"

# External modules.
readonly PATH_OVERLAYS_PS3_GENTOO="\${PATH_OVERLAYS}/ps3-gentoo-overlay"                     # Overlays.
readonly PATH_OVERLAYS_PS3_GENTOO_DISTFILES="\${PATH_OVERLAYS}/ps3-gentoo-overlay.distfiles" # Distfiles.
readonly PATH_RELEASES_PS3_GENTOO="\${PATH_RELEASES}"                                        # Releases module.

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
readonly PATH_WORK_DISTCC_DOCKER="\${PATH_WORK}/distcc_docker"
readonly PATH_WORK_ENVIRONMENT="\${PATH_WORK}/environment"
readonly PATH_WORK_KERNEL_EBUILD="\${PATH_WORK}/kernel_ebuild"
readonly PATH_WORK_PS3_INSTALLER="\${PATH_WORK}/ps3_installer"
readonly PATH_WORK_RELENG="\${PATH_WORK}/releng"
readonly PATH_WORK_OVERLAY="\${PATH_WORK}/overlay"
readonly PATH_WORK_BINHOST="\${PATH_WORK}/binhost"

# DEV Tools additional environments.
readonly PATH_EXTRA_ENV_PS3_INSTALLER="\${PATH_DEV_TOOLS_PS3_INSTALLER}/env.sh"
readonly PATH_EXTRA_ENV_KERNEL_EBUILD="\${PATH_DEV_TOOLS_KERNEL_EBUILD}/env.sh"
readonly PATH_EXTRA_ENV_KERNEL_PATCHES="\${PATH_DEV_TOOLS_KERNEL_PATCHES}/env.sh"
readonly PATH_EXTRA_ENV_RELENG="\${PATH_DEV_TOOLS_RELENG}/env.sh"

# Catalyst.
readonly PATH_CATALYST_USR="\${PATH_USR_SHARE}/catalyst"
readonly PATH_CATALYST_TMP="\${PATH_VAR_TMP}/catalyst"
readonly PATH_CATALYST_ETC="\${PATH_ETC}/catalyst"
readonly PATH_CATALYST_BUILDS="\${PATH_CATALYST_TMP}/builds"
readonly PATH_CATALYST_BUILDS_DEFAULT="\${PATH_CATALYST_BUILDS}/\${CONF_RELEASE_TYPE_DFAULT}"
readonly PATH_CATALYST_STAGES="\${PATH_CATALYST_TMP}/config/stages"
readonly PATH_CATALYST_STAGES_DEFAULT="\${PATH_CATALYST_STAGES}/\${CONF_RELEASE_TYPE_DFAULT}"
readonly PATH_CATALYST_PACKAGES="\${PATH_CATALYST_TMP}/packages"
readonly PATH_CATALYST_CONF="\${PATH_CATALYST_ETC}/catalyst.conf"
readonly PATH_CATALYST_PPC_TOML="\${PATH_CATALYST_USR}/arch/ppc.toml"
readonly PATH_CATALYST_PATCHES_SRC="\${PATH_DEV_TOOLS_ENVIRONMENT}/data/catalyst-patches"
readonly PATH_CATALYST_PATCHES_DST="\${PATH_ETC_PORTAGE}/patches/dev-util/catalyst"
readonly CONF_CATALYST_CHOST="\${CONF_TARGET_CHOST}"

# QEMU.
readonly PATH_QEMU_BINFMT="/proc/sys/fs/binfmt_misc"
readonly PATH_QEMU_BINFMT_REGISTER="\${PATH_QEMU_BINFMT}/register"

# Crossdev.
readonly CONF_CROSSDEV_TARGET="\${CONF_TARGET_CHOST}"
readonly PATH_CROSSDEV_USR="\${PATH_USR_SHARE}/crossdev"
readonly PATH_CROSSDEV_INSTALLATION="\${PATH_USR}/\${CONF_CROSSDEV_TARGET}"
readonly PATH_CROSSDEV_BINPKGS="\${PATH_CROSSDEV_INSTALLATION}/\${PATH_VAR_CACHE}/binpkgs"

# Releases paths.
readonly PATH_RELEASES_PS3_GENTOO_DEFAULT="\${PATH_RELEASES_PS3_GENTOO}/\${CONF_RELEASE_TYPES}"
readonly PATH_RELEASES_PS3_GENTOO_ARCH="\${PATH_RELEASES_PS3_GENTOO}/\${CONF_TARGET_ARCH_FAMILY}"                                                       # releases/ppc
readonly PATH_RELEASES_PS3_GENTOO_ARCH_BINPACKAGES="\${PATH_RELEASES_PS3_GENTOO_ARCH}/binpackages"                                                      # releases/ppc/binpackages
readonly PATH_RELEASES_PS3_GENTOO_ARCH_BINPACKAGES_PROFILE="\${PATH_RELEASES_PS3_GENTOO_ARCH_BINPACKAGES}/\${CONF_RELEASE_PROFILE}"                     # releases/ppc/binpackages/23.0
readonly PATH_RELEASES_PS3_GENTOO_ARCH_BINPACKAGES_PROFILE_SUBARCH="\${PATH_RELEASES_PS3_GENTOO_ARCH_BINPACKAGES_PROFILE}/\${CONF_TARGET_ARCH_SUBARCH}" # releases/ppc/binpackages/23.0/cell

# Other.
readonly PATH_ENV_HELPER_FUNCTIONS="\${PATH_DEV_TOOLS_ENVIRONMENT}/env-helper-functions.sh"
readonly PATH_GIT_HOOK_RELEASES="\${PATH_ROOT}/.git/modules/releases/hooks/pre-commit"
readonly PATH_PORTAGE_TIMESTAMP_CHK="\${PATH_VAR_DB_REPOS_GENTOO}/metadata/timestamp.chk"

# Releng.
readonly PATH_RELENG="\${PATH_USR_SHARE}/releng"
readonly PATH_RELENG_PORTAGE_CONFDIR="\${PATH_RELENG}/releases/portage"
readonly PATH_RELENG_PORTAGE_CONFDIR_STAGES="\${PATH_RELENG}/releases/portage/stages\${CONF_QEMU_RELENG_POSTFIX}"
readonly PATH_RELENG_PORTAGE_CONFDIR_ISOS="\${PATH_RELENG}/releases/portage/isos\${CONF_QEMU_RELENG_POSTFIX}"
readonly PATH_RELENG_DATA="\${PATH_DEV_TOOLS_RELENG}/data"
readonly PATH_RELENG_TEMPLATES="\${PATH_RELENG_DATA}/templates"
readonly PATH_RELENG_RELEASES="\${PATH_RELEASES}/\${CONF_TARGET_ARCH_FAMILY}"
readonly PATH_RELENG_RELEASES_BINPACKAGES="\${PATH_RELENG_RELEASES}/binpackages/\${CONF_RELEASE_PROFILE}"
readonly PATH_RELENG_RELEASES_AUTOBUILDS="\${PATH_RELENG_RELEASES}/autobuilds/"
readonly PATH_RELENG_CATALYST_AUTO="\${PATH_RELENG}/tools/catalyst-auto"

# Paths to scripts.
# Kernel ebuild:
readonly PATH_SCRIPT_KERNEL_EBUILD_FIND_VERSION="\${PATH_DEV_TOOLS_KERNEL_EBUILD}/ebuild-00-find-version.sh"
readonly PATH_SCRIPT_KERNEL_EBUILD_DOWNLOAD_PATCHES="\${PATH_DEV_TOOLS_KERNEL_EBUILD}/ebuild-01-download-patches.sh"
readonly PATH_SCRIPT_KERNEL_EBUILD_DOWNLOAD_GENTOO_KERNEL="\${PATH_DEV_TOOLS_KERNEL_EBUILD}/ebuild-02-download-gentoo-kernel.sh"
readonly PATH_SCRIPT_KERNEL_EBUILD_APPLY_PS3_PATCHES="\${PATH_DEV_TOOLS_KERNEL_EBUILD}/ebuild-03-apply-ps3-patches.sh"
readonly PATH_SCRIPT_KERNEL_EBUILD_CONFIGURE="\${PATH_DEV_TOOLS_KERNEL_EBUILD}/ebuild-04-configure.sh"
readonly PATH_SCRIPT_KERNEL_EBUILD_CREATE_PS3_EBUILD="\${PATH_DEV_TOOLS_KERNEL_EBUILD}/ebuild-05-create-ps3-ebuild.sh"
readonly PATH_SCRIPT_KERNEL_EBUILD_BUILD_MANIFEST="\${PATH_DEV_TOOLS_KERNEL_EBUILD}/ebuild-06-build-manifest.sh"
readonly PATH_SCRIPT_KERNEL_EBUILD_SAVE_TO_OVERLAY="\${PATH_DEV_TOOLS_KERNEL_EBUILD}/ebuild-07-save-to-overlay.sh"
readonly PATH_SCRIPT_KERNEL_EBUILD_BUILD_PKG="\${PATH_DEV_TOOLS_KERNEL_EBUILD}/ebuild-08-build-pkg.sh"
# PS3 Installer
readonly PATH_SCRIPT_PS3_INSTALLER_UPDATE="\${PATH_DEV_TOOLS_PS3_INSTALLER}/installer-00-update.sh"
readonly PATH_SCRIPT_PS3_INSTALLER_INSTALLER="\${PATH_DEV_TOOLS_PS3_INSTALLER}/ps3-gentoo-installer"
# Binhost
readonly PATH_BINHOST_SCRIPT_DELETE="\${PATH_DEV_TOOLS_BINHOST}/binhost-01-delete-packages.sh"
readonly PATH_BINHOST_SCRIPT_SANITIZE="\${PATH_DEV_TOOLS_BINHOST}/binhost-02-sanitize.sh"
# Overlay
readonly PATH_OVERLAY_SCRIPT_CREATE_PACKAGE="\${PATH_DEV_TOOLS_OVERLAY}/create-package.sh"
readonly PATH_OVERLAY_SCRIPT_COPY_PS3_FILES="\${PATH_DEV_TOOLS_OVERLAY}/copy-ps3-distfiles.sh"
# TODO: Add paths to other scripts.

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
set -o pipefail

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
