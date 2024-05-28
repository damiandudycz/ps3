#!/bin/bash

# This script generates PS3 kernel configuration.
# First it executes make ps3_defconfig to generate default PS3 configuration for current kernel.
# Next it applies changes stored in data/configs/<version> or /data/configs/default if configuration for
# selected version doesn't exists.
# If you add flag --default it will also use default configuration instead.
# If you select --edit flag, system will display menuconfig, allowing you to customize configuration.
# Finally it stores selected configuration differences from default PS3_Defconfig in data/configs/<version>.
#
# To store new configuration as the default, use --savedefault flag.
#
# If you just want to test generating configs, without storing <version> config, use --pretent flag.

# --- Shared environment
source ../../.env-shared.sh || exit 1
source "${PATH_EXTRA_ENV_KERNEL_EBUILD}" || failure "Failed to load env ${PATH_EXTRA_ENV_KERNEL_EBUILD}"
register_failure_handler cleanup_gentoo_kernel_configure_on_failure
register_usage "$0 [package_version] [--edit] [--default] [--pretend] [--savedefault]"

cleanup_gentoo_kernel_configure_on_failure() {
    [ ! ${PATH_NEW_CONFIG_TMP} ] || [ ! -d ${PATH_NEW_CONFIG_TMP} ] || rm -f "${PATH_NEW_CONFIG_TMP}" || echo "Failed to clean temp file ${PATH_NEW_CONFIG_TMP}"
}

readonly NAME_PS3_DEFCONFIG="ps3_defconfig"
readonly NAME_PACKAGE="sys-kernel/gentoo-kernel"

readonly PATH_SCRIPT_APPLY_DIFFCONFIG="${PATH_DEV_TOOLS_KERNEL_EBUILD}/data/scripts/apply-diffconfig.rb"
readonly PATH_VERSION_STORAGE="${PATH_DEV_TOOLS_KERNEL_EBUILD}/data/version-storage"
readonly PATH_DEFAULT_CONFIG="${PATH_VERSION_STORAGE}/default/config"
readonly PATH_VERSION_SCRIPT="${PATH_DEV_TOOLS_KERNEL_EBUILD}/ebuild-00-find-version.sh"
[ ! -z "${PACKAGE_VERSION}" ] || PACKAGE_VERSION=$($PATH_VERSION_SCRIPT)
readonly PATH_WORK_GENTOO_KERNEL="${PATH_WORK_KERNEL_EBUILD}/${PACKAGE_VERSION}/src"
readonly PATH_VERSION_CONFIG="${PATH_VERSION_STORAGE}/${PACKAGE_VERSION}/config"
PATH_USED_CONFIG="${PATH_VERSION_CONFIG}"
[ -f "${PATH_VERSION_CONFIG}"/diffs ] || PATH_USED_CONFIG="${PATH_DEFAULT_CONFIG}"
[ ! ${FORCE_DEFAULT} ] || PATH_USED_CONFIG="${PATH_DEFAULT_CONFIG}"
readonly PATH_SOURCES_SRC="$(find ${PATH_WORK_GENTOO_KERNEL}/portage/${NAME_PACKAGE}-${PACKAGE_VERSION}/work/ -maxdepth 1 -name linux-* -type d -print -quit)"
readonly PATH_SCRIPT_MERGE_CONFIG="${PATH_SOURCES_SRC}/scripts/kconfig/merge_config.sh"
readonly PATH_SCRIPT_DIFFCONFIG="${PATH_SOURCES_SRC}/scripts/diffconfig"

[ -d "${KE_PATH_WORK_SRC}" ] || failure "${KE_PATH_WORK_SRC} not found. Please run ebuild-emerge-gentoo-sources.sh <version> first."

echo "Config used: ${PATH_USED_CONFIG}"
cd "${KE_PATH_WORK_SRC}"

# Generate default PS3_Defconfig.
ARCH=powerpc make ${NAME_PS3_DEFCONFIG}
${PATH_SCRIPT_APPLY_DIFFCONFIG} ${PATH_USED_CONFIG}/diffs ./.config > .config_modified
ARCH=powerpc ${PATH_SCRIPT_MERGE_CONFIG} .config_modified
rm .config_modified

# Menuconfig.
[ ! ${KE_FLAG_CONFIG} ] || ARCH=powerpc make menuconfig

# Prepare new config storage directory.
[ ! -d "${PATH_VERSION_CONFIG}" ] || rm -rf "${PATH_VERSION_CONFIG}"
mkdir -p "${PATH_VERSION_CONFIG}"

# Generate new config.
ARCH=powerpc make savedefconfig
PATH_NEW_CONFIG="${PATH_VERSION_CONFIG}/diffs"
PATH_NEW_DEFCONFIG="${PATH_VERSION_CONFIG}/defconfig"
[ ! ${PRETENT} ] || PATH_NEW_CONFIG_TMP=$(mktemp)
[ ! ${PATH_NEW_CONFIG_TMP} ] || PATH_NEW_CONFIG="${PATH_NEW_CONFIG_TMP}"
${PATH_SCRIPT_DIFFCONFIG} "arch/powerpc/configs/${NAME_PS3_DEFCONFIG}" defconfig > "${PATH_NEW_CONFIG}"
cp defconfig "${PATH_NEW_DEFCONFIG}"
rm -f defconfig .config

# Update default config if used --savedefault.
[ ${KE_FLAG_SAVE_DEFAULT} ] && cp "${PATH_NEW_CONFIG}" "${PATH_DEFAULT_CONFIG}"

# Cleaning.
rm -f "${PATH_NEW_CONFIG_TMP}"
