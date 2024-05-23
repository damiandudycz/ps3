#!/bin/bash

# This script applies PS3 patches required for Gentoo-Sources and Gentoo-Kernel.
# If the set of patches is available for selected version in data/patches folder,
# these patches will be used.
# Otherwise standard set of patches from data/patches/default will be used.
#
# If you need to update default patches or patches for selected version, use
# ebuild-fetch-patches.sh [version] first.

# Error handling function
die() {
    echo "$*" 1>&2
    exit 1
}

readonly PATH_START=$(dirname "$(realpath "$0")") || die "Failed to determine script directory."
readonly PATH_ROOT=$(realpath -m "${PATH_START}/../..") || die "Failed to determine root directory."
readonly PATH_LOCAL="${PATH_ROOT}/local/kernel"
readonly PATH_PATCHES="${PATH_START}/data/patches"
readonly PATH_VERSION_SCRIPT="${PATH_START}/ebuild-find-version.sh"

PACKAGE_VERSION="$1"
[ ! -z "${PACKAGE_VERSION}" ] || PACKAGE_VERSION=$($PATH_VERSION_SCRIPT) || die "Failed to get default version of package"

readonly PATH_VERSION_PATCHES="${PATH_PATCHES}/${PACKAGE_VERSION}"
readonly PATH_DEFAULT_PATCHES="${PATH_PATCHES}/default"
readonly PATH_SOURCES_USRSRC="${PATH_LOCAL}/${PACKAGE_VERSION}/usr/src/linux-${PACKAGE_VERSION}-gentoo"

# Determine used local patches directory - version or default.
PATH_USED_PATCHES="${PATH_VERSION_PATCHES}"
[ -d "${PATH_VERSION_PATCHES}" ] || PATH_USED_PATCHES="${PATH_DEFAULT_PATCHES}"

[[ "${PACKAGE_VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+([0-9]+)?$ ]] || die "Please provide valid version number, ie. $0 6.6.30"
[ -d "${PATH_LOCAL}/${PACKAGE_VERSION}" ] || die "${PATH_LOCAL}/${PACKAGE_VERSION} not found. Please run ebuild-emerge-gentoo-sources.sh <version> first."

# Apply patches
for PATCH in "${PATH_USED_PATCHES}"/*.patch; do
    echo "Apply patch ${PATCH}:"
    patch --batch --force -p1 -i "${PATCH}" -d "${PATH_SOURCES_USRSRC}" || die "Failed to apply patch ${PATCH}"
done

# If patches were applied succesfully from default folder, store them for this version, so that there is a working backup.
if [ "${PATH_USED_PATCHES}" = "${PATH_DEFAULT_PATCHES}" ]; then
    cp -rf "${PATH_DEFAULT_PATCHES}" "${PATH_VERSION_PATCHES}" || die "Failed to store copy of patches for ${PATH_VERSION_PATCHES}"
fi

exit 0
