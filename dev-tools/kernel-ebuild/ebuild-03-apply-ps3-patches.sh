#!/bin/bash

# This script applies PS3 patches required for Gentoo-Sources and Gentoo-Kernel.
# If the set of patches is available for selected version in data/patches folder,
# these patches will be used.
# Otherwise standard set of patches from data/patches/default will be used.
#
# If you need to update default patches or patches for selected version, use
# ebuild-fetch-patches.sh [version] first.

die() {
    echo "$*" 1>&2
    exit 1
}

PACKAGE_VERSION="$1"
readonly NAME_PACKAGE="sys-kernel/gentoo-kernel"

readonly PATH_START=$(dirname "$(realpath "$0")") || die "Failed to determine script directory."
readonly PATH_ROOT=$(realpath -m "${PATH_START}/../..") || die "Failed to determine root directory."
readonly PATH_VERSION_STORAGE="${PATH_START}/data/version-storage"
readonly PATH_DEFAULT_PATCHES="${PATH_VERSION_STORAGE}/default/patches"
readonly PATH_VERSION_SCRIPT="${PATH_START}/ebuild-00-find-version.sh"
[ ! -z "${PACKAGE_VERSION}" ] || PACKAGE_VERSION=$($PATH_VERSION_SCRIPT) || die "Failed to get default version of package"
readonly PATH_WORK="${PATH_ROOT}/local/gentoo-kernel-ps3/${PACKAGE_VERSION}/src"
readonly PATH_PATCHES="${PATH_VERSION_STORAGE}/${PACKAGE_VERSION}/patches"
readonly PATH_SOURCES_SRC="$(find ${PATH_WORK}/portage/${NAME_PACKAGE}-${PACKAGE_VERSION}/work/ -maxdepth 1 -name linux-* -type d -print -quit)"
PATH_USED_PATCHES="${PATH_PATCHES}"
[ -d "${PATH_PATCHES}" ] || PATH_USED_PATCHES="${PATH_DEFAULT_PATCHES}"

# Validate data.
[[ "${PACKAGE_VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+([0-9]+)?$ ]] || die "Please provide valid version number, ie. $0 6.6.30"
[ $PATH_SOURCES_SRC ] || die "Failed to find PATH_SOURCES_SRC"
[ -d "${PATH_WORK}" ] || die "${PATH_WORK} not found. Please run ebuild-emerge-gentoo-sources.sh <version> first."

# Apply patches
for PATCH in "${PATH_USED_PATCHES}"/*.patch; do
    echo "Apply patch ${PATCH}:"
    patch --batch --force -p1 -i "${PATCH}" -d "${PATH_SOURCES_SRC}" || die "Failed to apply patch ${PATCH}"
done

# If patches were applied successfully from default folder, store them for this version, so that there is a working backup.
if [ "${PATH_USED_PATCHES}" = "${PATH_DEFAULT_PATCHES}" ]; then
    echo "Saving used default patches for ${PATH_PATCHES}"
    mkdir -p "${PATH_PATCHES}"
    cp -rf "${PATH_DEFAULT_PATCHES}"/* "${PATH_PATCHES}" || die "Failed to store copy of patches for ${PATH_PATCHES}"
fi

echo "Patches applied successfully"
exit 0
