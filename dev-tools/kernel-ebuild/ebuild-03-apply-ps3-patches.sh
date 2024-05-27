#!/bin/bash

# This script applies PS3 patches required for Gentoo-Sources and Gentoo-Kernel.
# If the set of patches is available for selected version in data/patches folder,
# these patches will be used.
# Otherwise standard set of patches from data/patches/default will be used.
#
# If you need to update default patches or patches for selected version, use
# ebuild-fetch-patches.sh [version] first.

source ../../.env-shared.sh || exit 1
trap failure ERR
register_usage "$0 [package_version]"

PACKAGE_VERSION="$1"
readonly NAME_PACKAGE="sys-kernel/gentoo-kernel"

readonly PATH_VERSION_STORAGE="${PATH_DEV_TOOLS_KERNEL_EBUILD}/data/version-storage"
readonly PATH_DEFAULT_PATCHES="${PATH_VERSION_STORAGE}/default/patches"
readonly PATH_VERSION_SCRIPT="${PATH_DEV_TOOLS_KERNEL_EBUILD}/ebuild-00-find-version.sh"
[ ! -z "${PACKAGE_VERSION}" ] || PACKAGE_VERSION=$($PATH_VERSION_SCRIPT)
readonly PATH_WORK_GENTOO_KERNEL="${PATH_WORK_KERNEL_EBUILD}/${PACKAGE_VERSION}/src"
readonly PATH_PATCHES="${PATH_VERSION_STORAGE}/${PACKAGE_VERSION}/patches"
readonly PATH_SOURCES_SRC="$(find ${PATH_WORK_GENTOO_KERNEL}/portage/${NAME_PACKAGE}-${PACKAGE_VERSION}/work/ -maxdepth 1 -name linux-* -type d -print -quit)"
PATH_USED_PATCHES="${PATH_PATCHES}"
[ -d "${PATH_PATCHES}" ] || PATH_USED_PATCHES="${PATH_DEFAULT_PATCHES}"

# Validate data.
[ ! -z "${PACKAGE_VERSION}" ] || failure "Failed to determine kernel version"
[[ "${PACKAGE_VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+([0-9]+)?$ ]] || show_usage
[ ${PATH_SOURCES_SRC} ] || failure "Failed to find PATH_SOURCES_SRC"
[ -d "${PATH_PATH_GENTOO_KERNEL}" ] || failure "${PATH_PATH_GENTOO_KERNEL} not found. Please run ebuild-emerge-gentoo-sources.sh <version> first."

# Apply patches
for PATCH in "${PATH_USED_PATCHES}"/*.patch; do
    echo "Apply patch ${PATCH}:"
    patch --batch --force -p1 -i "${PATCH}" -d "${PATH_SOURCES_SRC}"
done

# If patches were applied successfully from default folder, store them for this version, so that there is a working backup.
if [ "${PATH_USED_PATCHES}" = "${PATH_DEFAULT_PATCHES}" ]; then
    echo "Saving used default patches for ${PATH_PATCHES}"
    mkdir -p "${PATH_PATCHES}"
    cp -rf "${PATH_DEFAULT_PATCHES}"/* "${PATH_PATCHES}"
fi
