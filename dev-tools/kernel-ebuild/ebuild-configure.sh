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

# Error handling function
die() {
    echo "$*" 1>&2
    exit 1
}

# Read exec flags
while [ $# -gt 0 ]; do
    case "$1" in
    --default)
        FORCE_DEFAULT=true
        ;;
    --edit)
        CONFIGURE=true
        ;;
    --pretent)
        PRETENT=true
        ;;
    --savedefault)
        SAVE_DEFAULT=true
        ;;
    --*)
        die "Unknown option: $1"
        ;;
    *)
        PACKAGE_VERSION="$1"
        ;;
    esac
    shift
done

readonly PATH_START=$(dirname "$(realpath "$0")") || die "Failed to determine script directory."
readonly PATH_VERSION_SCRIPT="${PATH_START}/ebuild-find-version.sh"
[ ! -z "${PACKAGE_VERSION}" ] || PACKAGE_VERSION=$($PATH_VERSION_SCRIPT) || die "Failed to get default version of package"

readonly PATH_ROOT=$(realpath -m "${PATH_START}/../..") || die "Failed to determine root directory."
readonly PATH_LOCAL="${PATH_ROOT}/local/kernel/${PACKAGE_VERSION}/src"
readonly PATH_CONFIGS="${PATH_START}/data/configs"
readonly PATH_SCRIPT_APPLY_DIFFCONFIG="${PATH_START}/data/scripts/apply-diffconfig.rb"

readonly PATH_VERSION_CONFIG="${PATH_CONFIGS}/${PACKAGE_VERSION}"
readonly PATH_DEFAULT_CONFIG="${PATH_CONFIGS}/default"

readonly NAME_PS3_DEFCONFIG="ps3_defconfig"
readonly NAME_PACKAGE="sys-kernel/gentoo-kernel"

readonly PATH_SOURCES_WORK="${PATH_LOCAL}/portage/${NAME_PACKAGE}-${PACKAGE_VERSION}/work/"
readonly PATH_SOURCES_SRC="$(find ${PATH_SOURCES_WORK} -maxdepth 1 -name linux-* -type d -print -quit)"
[ ! $PATH_SOURCES_SRC ] && die "Failed to find PATH_SOURCES_SRC"
readonly PATH_SCRIPT_MERGE_CONFIG="${PATH_SOURCES_SRC}/scripts/kconfig/merge_config.sh"
readonly PATH_SCRIPT_DIFFCONFIG="${PATH_SOURCES_SRC}/scripts/diffconfig"

# Determine used local config file - version or default.
PATH_USED_CONFIG="${PATH_VERSION_CONFIG}"
[ -f "${PATH_VERSION_CONFIG}" ] || PATH_USED_CONFIG="${PATH_DEFAULT_CONFIG}"
[ ! ${FORCE_DEFAULT} ] || PATH_USED_CONFIG="${PATH_DEFAULT_CONFIG}"

echo "Config used: ${PATH_USED_CONFIG}"

[[ "${PACKAGE_VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+([0-9]+)?$ ]] || die "Please provide valid version number, ie. $0 6.6.30"
[ -d "${PATH_LOCAL}" ] || die "${PATH_LOCAL} not found. Please run ebuild-emerge-gentoo-sources.sh <version> first."

[ ! ${PRETENT} ] || [ ! ${SAVE_DEFAULT} ] || die "Cannot use --pretent and --savedefault at the same time"

cd "${PATH_SOURCES_SRC}" || die "Failed to open diretory ${PATH_SOURCES_SRC}"

# Generate default PS3_Defconfig.
ARCH=powerpc make ${NAME_PS3_DEFCONFIG} || die "Failed to generate PS3 Defconfig"
${PATH_SCRIPT_APPLY_DIFFCONFIG} $PATH_USED_CONFIG ./.config > .config_modified || die "Failed to apply difconfig"
ARCH=powerpc ${PATH_SCRIPT_MERGE_CONFIG} .config_modified || die "Failed to merge config"
rm .config_modified || die "Failed to remove .config_modified"

# Menuconfig.
[ ! ${CONFIGURE} ] || ARCH=powerpc make menuconfig || die "Failed to run menuconfig"

# Generate and store new config.
ARCH=powerpc make savedefconfig || die "Failed so make new defconfig"
PATH_NEW_CONFIG="${PATH_VERSION_CONFIG}"
PATH_NEW_DEFCONFIG="${PATH_VERSION_CONFIG}.defconfig"
[ ! ${PRETENT} ] || PATH_NEW_CONFIG_TMP=$(mktemp) || die "Failed to generate tmp file for PRETENT"
[ ! ${PATH_NEW_CONFIG_TMP} ] || PATH_NEW_CONFIG="${PATH_NEW_CONFIG_TMP}" || die "Failed to set tmp config location ad new config path"
${PATH_SCRIPT_DIFFCONFIG} "arch/powerpc/configs/${NAME_PS3_DEFCONFIG}" defconfig > "${PATH_NEW_CONFIG}" || die "Failed to save new difconfig diffs"
cp defconfig "${PATH_NEW_DEFCONFIG}" || die "Failed to save new defconfig file"
rm -f defconfig .config || die "Failed to delete config files in ${PATH_SOURCES_SRC}"

# Update default config if specified.
[ ! ${SAVE_DEFAULT} ] || cp "${PATH_NEW_CONFIG}" "${PATH_DEFAULT_CONFIG}" || die "Failed to update default config"

# Cleaning.
[ ! ${PATH_NEW_CONFIG_TMP} ] || rm -f "${PATH_NEW_CONFIG_TMP}" || die "Failed to clean temp file ${PATH_NEW_CONFIG_TMP}"

echo "Configuration generated successfully."
exit 0
